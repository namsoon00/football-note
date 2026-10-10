import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/domain/scan_pass/scan_pass_judgment.dart';

void main() {
  const engine = JudgmentEngine();

  group('judgment episode catalog', () {
    test('contains eight families with three authored configurations each', () {
      final catalog = engine.catalog();
      expect(catalog, hasLength(24));
      for (final family in JudgmentFamily.values) {
        expect(
          catalog.where((spec) => spec.family == family).map(
                (spec) => spec.configuration,
              ),
          unorderedEquals([0, 1, 2]),
        );
      }
    });

    test('all 24 base scenes have distinct football geometry', () {
      final signatures = <String>{};
      for (final spec in engine.catalog()) {
        final scene = engine.scene(spec);
        final players = [
          ...scene.reception.attackers,
          ...scene.reception.defenders
        ]..sort((a, b) => a.number.compareTo(b.number));
        signatures.add(players
            .map((p) =>
                '${p.number}:${p.position.x},${p.position.y}:${p.velocity.x},${p.velocity.y}')
            .join('/'));
      }
      expect(signatures, hasLength(24));
    });

    test('ten-scene sessions mix families and configurations', () {
      final session = engine.session(seed: 5);
      expect(session, hasLength(10));
      expect(session.map((spec) => spec.family).toSet().length,
          greaterThanOrEqualTo(8));
      expect(session.map((spec) => spec.configuration).toSet().length,
          greaterThanOrEqualTo(2));
    });
  });

  test(
      'all branches agree with possession, preserve snapshots and stop within three decisions',
      () {
    var checked = 0;
    void walk(JudgmentPhase phase) {
      final before = _signature(phase.state);
      for (final choice in phase.choices) {
        final result = engine.choose(phase, choice);
        checked++;
        expect(result.quality == JudgmentQuality.lost, result.after.finished,
            reason: '${phase.scene.spec.id}/${choice.action}');
        expect(_signature(result.before), before);
        expect(_signature(result.frame(1)), _signature(result.after));
        expect(result.duration, greaterThan(0));
        expect(phase.step, lessThanOrEqualTo(3));
        for (var i = 1; i < result.transitions.length; i++) {
          expect(result.transitions[i].before,
              same(result.transitions[i - 1].after));
        }
        if (result.nextPhase != null) {
          expect(result.nextPhase!.state, same(result.after));
          walk(result.nextPhase!);
        }
      }
      expect(_signature(phase.state), before);
    }

    for (final spec in engine.catalog()) {
      walk(engine.firstPhase(engine.scene(spec)));
    }
    expect(checked, greaterThan(400));
  });

  test('mirrored pressure reverses directions without reversing evaluation',
      () {
    JudgmentAction mirror(JudgmentAction action) => switch (action) {
          JudgmentAction.touchLeft => JudgmentAction.touchRight,
          JudgmentAction.touchRight => JudgmentAction.touchLeft,
          _ => action,
        };
    void compare(JudgmentPhase a, JudgmentPhase b) {
      for (final choice in a.choices) {
        final left = engine.choose(a, choice);
        final right = _choose(engine, b, mirror(choice.action));
        expect(left.quality, right.quality,
            reason: '${a.scene.spec.id}/${choice.action}');
        expect(left.after.ball.x, closeTo(right.after.ball.x, 1e-7));
        expect(left.after.ball.y, closeTo(1 - right.after.ball.y, 1e-7));
        if (left.nextPhase != null) compare(left.nextPhase!, right.nextPhase!);
      }
    }

    for (final spec in engine.catalog()) {
      compare(
          engine.firstPhase(engine.scene(spec)),
          engine.firstPhase(engine.scene(JudgmentSceneSpec(
              family: spec.family,
              configuration: spec.configuration,
              variation: 1))));
    }
  });

  test(
      'scene labels cannot manufacture a better outcome for identical geometry',
      () {
    final scene = engine.scene(const JudgmentSceneSpec(
        family: JudgmentFamily.rearPressure, configuration: 0));
    final renamed = JudgmentScene(
      spec: const JudgmentSceneSpec(
          family: JudgmentFamily.numericalAdvantage, configuration: 1),
      initial: scene.initial,
      reception: scene.reception,
      cueFrom: scene.cueFrom,
      cueTo: scene.cueTo,
      cueIsOpponent: scene.cueIsOpponent,
      firstActions: scene.firstActions,
    );
    final original = engine.firstPhase(scene);
    final other = engine.firstPhase(renamed);
    for (final choice in original.choices) {
      final a = engine.choose(original, choice);
      final b = _choose(engine, other, choice.action);
      expect(a.quality, b.quality);
      expect(a.reason, b.reason);
      expect(_signature(a.after), _signature(b.after));
    }
  });

  test(
      'protect executes the displayed destination and one-touch return offers support',
      () {
    final phase = _firstPhase(engine, JudgmentFamily.sidePressure, 0);
    final choice =
        phase.choices.firstWhere((c) => c.action == JudgmentAction.shield);
    final shield = engine.choose(phase, choice);
    expect(shield.after.finished, isFalse);
    expect(shield.after.ball.distanceTo(choice.target), lessThan(1e-8));
    final rear = _firstPhase(engine, JudgmentFamily.rearPressure, 0);
    final returned = _choose(engine, rear, JudgmentAction.oneTouchReturn);
    expect(returned.after.carrierNumber, 4);
    expect(returned.nextPhase!.kind, JudgmentDecisionKind.support);
  });

  group('causal decisions', () {
    test('side-pressure lookalikes reverse the useful first touch', () {
      final upper = _firstPhase(engine, JudgmentFamily.sidePressure, 0);
      final lower = _firstPhase(engine, JudgmentFamily.sidePressure, 1);

      expect(
          _rank(_choose(engine, upper, JudgmentAction.touchRight).quality),
          greaterThan(
              _rank(_choose(engine, upper, JudgmentAction.touchLeft).quality)));
      expect(
          _rank(_choose(engine, lower, JudgmentAction.touchLeft).quality),
          greaterThan(_rank(
              _choose(engine, lower, JudgmentAction.touchRight).quality)));
    });

    test('rear pressure changes the next state instead of normalizing success',
        () {
      final phase = _firstPhase(engine, JudgmentFamily.rearPressure, 0);
      final escape = _choose(engine, phase, JudgmentAction.touchLeft);
      final trapped = _choose(engine, phase, JudgmentAction.touchForward);

      expect(escape.nextPhase, isNotNull);
      expect(
          escape.after.ball.distanceTo(trapped.after.ball), greaterThan(.04));
      expect(_rank(escape.quality), greaterThan(_rank(trapped.quality)));
    });

    test('open-front scenes account for the second defender', () {
      final open =
          _firstPhase(engine, JudgmentFamily.openFrontSecondDefender, 0);
      final stepped =
          _firstPhase(engine, JudgmentFamily.openFrontSecondDefender, 1);

      final openNext =
          _choose(engine, open, JudgmentAction.touchLeft).nextPhase!;
      expect(_choose(engine, openNext, JudgmentAction.carryForward).quality,
          JudgmentQuality.spaceGained);
      expect(
        _rank(_choose(engine, stepped, JudgmentAction.touchForward).quality),
        lessThan(
            _rank(_choose(engine, stepped, JudgmentAction.touchLeft).quality)),
      );
    });

    test('passing lane pressure changes the value of the same forward pass',
        () {
      final open = _afterFirst(
        engine,
        JudgmentFamily.passingLane,
        0,
        JudgmentAction.touchForward,
      );
      final screened = _afterFirst(
        engine,
        JudgmentFamily.passingLane,
        1,
        JudgmentAction.touchForward,
      );

      expect(
          _rank(_choose(engine, open, JudgmentAction.passForward).quality),
          greaterThan(_rank(
              _choose(engine, screened, JudgmentAction.passForward).quality)));
    });

    test('receiver support affects the continuation after an identical pass',
        () {
      final supported = _afterNext(
        engine,
        JudgmentFamily.receiverSupport,
        0,
        JudgmentAction.touchForward,
        JudgmentAction.passForward,
      );
      final isolated = _afterNext(
        engine,
        JudgmentFamily.receiverSupport,
        1,
        JudgmentAction.touchForward,
        JudgmentAction.passForward,
      );

      expect(supported, isNotNull);
      expect(isolated, isNotNull);
      final supportedWide =
          _choose(engine, supported!, JudgmentAction.supportWide);
      final isolatedWide =
          _choose(engine, isolated!, JudgmentAction.supportWide);
      expect(_rank(supportedWide.quality),
          greaterThan(_rank(isolatedWide.quality)));
    });

    test('numerical advantage rewards using the spare player', () {
      final phase = _afterFirst(
        engine,
        JudgmentFamily.numericalAdvantage,
        1,
        JudgmentAction.touchRight,
      );

      expect(_choose(engine, phase, JudgmentAction.passWide).quality,
          JudgmentQuality.spaceGained);
      expect(
          _rank(_choose(engine, phase, JudgmentAction.protect).quality),
          lessThan(
              _rank(_choose(engine, phase, JudgmentAction.passWide).quality)));
    });

    test('support angle determines whether the actual return reaches 6', () {
      final phase = _afterNext(engine, JudgmentFamily.postPassSupportAngle, 2,
          JudgmentAction.touchForward, JudgmentAction.passForward)!;
      final inside = _choose(engine, phase, JudgmentAction.supportInside);
      final behind = _choose(engine, phase, JudgmentAction.supportBehind);
      expect(inside.after.carrierNumber, 6);
      expect(inside.after.completedPasses, phase.state.completedPasses + 1);
      expect(inside.quality, JudgmentQuality.optionsPreserved);
      expect(behind.after.end, AttackEnd.intercepted);
      expect(behind.quality, JudgmentQuality.lost);
      expect(inside.transitions, hasLength(2));
      expect(
          inside.transitions.last.before, same(inside.transitions.first.after));
    });

    test('transition back-space can make a visible forward pass invalid', () {
      final phase = _afterFirst(
        engine,
        JudgmentFamily.transitionBackSpace,
        2,
        JudgmentAction.touchForward,
      );
      final forward = _choose(engine, phase, JudgmentAction.passForward);
      final back = _choose(engine, phase, JudgmentAction.passBack);

      expect(forward.quality, JudgmentQuality.lost);
      expect(forward.after.end, AttackEnd.offside);
      expect(_rank(back.quality), greaterThan(_rank(forward.quality)));
    });

    test('alternatives compare the identical decision state without mutation',
        () {
      final phase = _afterFirst(
        engine,
        JudgmentFamily.passingLane,
        0,
        JudgmentAction.touchForward,
      );
      final before = _signature(phase.state);
      final alternatives = engine.alternatives(phase);

      expect(alternatives, hasLength(4));
      for (final result in alternatives) {
        expect(_signature(result.before), before);
        result.frame(.5);
      }
      expect(_signature(phase.state), before);
      expect(
          () => alternatives.first.transitions.clear(), throwsUnsupportedError);
    });
  });
}

JudgmentPhase _firstPhase(
  JudgmentEngine engine,
  JudgmentFamily family,
  int configuration,
) =>
    engine.firstPhase(
      engine.scene(
        JudgmentSceneSpec(family: family, configuration: configuration),
      ),
    );

JudgmentResult _choose(
  JudgmentEngine engine,
  JudgmentPhase phase,
  JudgmentAction action,
) =>
    engine.choose(
      phase,
      phase.choices.firstWhere((choice) => choice.action == action),
    );

JudgmentPhase _afterFirst(
  JudgmentEngine engine,
  JudgmentFamily family,
  int configuration,
  JudgmentAction action,
) {
  final result =
      _choose(engine, _firstPhase(engine, family, configuration), action);
  expect(result.nextPhase, isNotNull);
  return result.nextPhase!;
}

JudgmentPhase? _afterNext(
  JudgmentEngine engine,
  JudgmentFamily family,
  int configuration,
  JudgmentAction first,
  JudgmentAction next,
) {
  final phase = _afterFirst(engine, family, configuration, first);
  return _choose(engine, phase, next).nextPhase;
}

int _rank(JudgmentQuality quality) => switch (quality) {
      JudgmentQuality.lost => 0,
      JudgmentQuality.possessionRetained => 1,
      JudgmentQuality.spaceGained => 2,
      JudgmentQuality.optionsPreserved => 3,
    };

List<Object?> _signature(AttackState state) => [
      state.ball.x,
      state.ball.y,
      state.carrierNumber,
      state.end,
      for (final player in state.attackers)
        [player.number, player.position.x, player.position.y],
      for (final player in state.defenders)
        [player.number, player.position.x, player.position.y],
    ];
