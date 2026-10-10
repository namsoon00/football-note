import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart'
    show ScanPassPoint;
import 'package:football_note/domain/scan_pass/scan_pass_possession_lesson.dart';

void main() {
  const engine = ScanPassPossessionLessonEngine();

  test('recommended pressure route solves pressure and reaches a final chance',
      () {
    final scene = engine.scene(variant: ScanPassPossessionVariant.pressure);
    final branch = engine.recommendedBranch(scene);

    expect(
      branch.decisions,
      const <ScanPassPossessionChoice>[
        ScanPassPossessionChoice.touchAway,
        ScanPassPossessionChoice.passTo8,
        ScanPassPossessionChoice.supportInside,
      ],
    );
    expect(branch.outcome, ScanPassPossessionOutcomeKind.chanceCreated);
    expect(
        branch.evidence, contains(ScanPassPossessionEvidence.pressureEscaped));
    expect(branch.evidence,
        contains(ScanPassPossessionEvidence.receiverConnected));
    expect(
        branch.evidence, contains(ScanPassPossessionEvidence.supportConnected));
    expect(
      branch.transitions.any(
        (transition) => transition.action.kind == AttackActionKind.shoot,
      ),
      isTrue,
    );
    expect(
      branch.finalState.end,
      anyOf(AttackEnd.saved, AttackEnd.blocked, AttackEnd.goal),
    );
    _expectContinuity(branch);
    expect(_movedAttackers(branch.transitions), greaterThanOrEqualTo(3));
    expect(_movedDefenders(branch.transitions), greaterThanOrEqualTo(2));
  });

  test('changed cue changes the recommended route instead of repeating layoff',
      () {
    final pressure = engine.recommendedBranch(
      engine.scene(variant: ScanPassPossessionVariant.pressure),
    );
    final cover = engine.recommendedBranch(
      engine.scene(variant: ScanPassPossessionVariant.cover),
    );

    expect(pressure.decisions.first, ScanPassPossessionChoice.touchAway);
    expect(
      cover.decisions,
      const <ScanPassPossessionChoice>[
        ScanPassPossessionChoice.turnForward,
        ScanPassPossessionChoice.passTo9,
        ScanPassPossessionChoice.supportInside,
      ],
    );
    expect(cover.decisions.first, isNot(pressure.decisions.first));
    expect(
      cover.scene.initial.attackers.map((player) => player.position.x),
      pressure.scene.initial.attackers.map((player) => player.position.x),
    );
  });

  test('first-touch effect persists through the possession outcome', () {
    final scene = engine.scene(variant: ScanPassPossessionVariant.pressure);
    final escaped = _play(engine, scene, const <ScanPassPossessionChoice>[
      ScanPassPossessionChoice.touchAway,
      ScanPassPossessionChoice.passTo8,
      ScanPassPossessionChoice.supportInside,
    ]);
    final trapped = _play(engine, scene, const <ScanPassPossessionChoice>[
      ScanPassPossessionChoice.turnForward,
      ScanPassPossessionChoice.passTo8,
      ScanPassPossessionChoice.supportInside,
    ]);

    expect(escaped.outcome, ScanPassPossessionOutcomeKind.chanceCreated);
    expect(trapped.outcome, ScanPassPossessionOutcomeKind.turnover);
    expect(
        trapped.evidence, contains(ScanPassPossessionEvidence.pressureStayed));
    expect(
        _signature(escaped.finalState), isNot(_signature(trapped.finalState)));
    expect(escaped.stateAt(ScanPassPossessionMoment.touch).ball.y,
        greaterThan(trapped.stateAt(ScanPassPossessionMoment.touch).ball.y));
  });

  test('support choice changes the actual return link and final possession',
      () {
    final scene = engine.scene(variant: ScanPassPossessionVariant.pressure);
    final inside = _play(engine, scene, const <ScanPassPossessionChoice>[
      ScanPassPossessionChoice.touchAway,
      ScanPassPossessionChoice.passTo9,
      ScanPassPossessionChoice.supportInside,
    ]);
    final behind = _play(engine, scene, const <ScanPassPossessionChoice>[
      ScanPassPossessionChoice.touchAway,
      ScanPassPossessionChoice.passTo9,
      ScanPassPossessionChoice.supportWide,
    ]);

    expect(inside.outcome, ScanPassPossessionOutcomeKind.chanceCreated);
    expect(behind.outcome, ScanPassPossessionOutcomeKind.recycled);
    expect(
      inside.transitions.map((transition) => transition.action).where(
            (action) =>
                action.kind == AttackActionKind.pass &&
                action.targetNumber == 9,
          ),
      isNotEmpty,
    );
    expect(behind.finalState.carrierNumber, 4);
    expect(
      inside
          .stateAt(ScanPassPossessionMoment.support)
          .attackers
          .firstWhere((player) => player.number == 6)
          .position,
      isNot(
        behind
            .stateAt(ScanPassPossessionMoment.support)
            .attackers
            .firstWhere((player) => player.number == 6)
            .position,
      ),
    );
  });

  test('learner remains number 6 during teammate possession support choice',
      () {
    final scene = engine.scene(variant: ScanPassPossessionVariant.pressure);
    var point = engine.firstPhase(scene);
    var result = engine.choose(point, ScanPassPossessionChoice.touchAway);
    point = result.nextPoint!;
    result = engine.choose(point, ScanPassPossessionChoice.passTo8);
    point = result.nextPoint!;

    expect(point.kind, ScanPassPossessionDecisionKind.support);
    expect(point.activeNumber, 6);
    expect(point.state.carrierNumber, 8);
    expect(point.choices, contains(ScanPassPossessionChoice.supportInside));
  });

  test('replays are deterministic and do not mutate the learner branch', () {
    final scene = engine.scene(variant: ScanPassPossessionVariant.cover);
    const choices = <ScanPassPossessionChoice>[
      ScanPassPossessionChoice.turnForward,
      ScanPassPossessionChoice.passTo9,
      ScanPassPossessionChoice.supportInside,
    ];
    final first = _play(engine, scene, choices);
    final second = _play(engine, scene, choices);
    final coach = engine.recommendedBranch(scene);

    expect(_branchSignature(first), _branchSignature(second));
    expect(first.recommended, isFalse);
    expect(coach.recommended, isTrue);
    expect(first.decisions, choices);
    expect(coach.decisions, choices);
    expect(_branchSignature(first), _branchSignature(coach));
  });
}

ScanPassPossessionBranch _play(
  ScanPassPossessionLessonEngine engine,
  ScanPassPossessionScene scene,
  List<ScanPassPossessionChoice> choices,
) {
  var point = engine.firstPhase(scene);
  for (final choice in choices) {
    final result = engine.choose(point, choice);
    if (result.branch != null) return result.branch!;
    point = result.nextPoint!;
  }
  throw StateError('Choices did not reach a terminal possession.');
}

void _expectContinuity(ScanPassPossessionBranch branch) {
  final transitions = branch.fullTransitions;
  expect(transitions, isNotEmpty);
  for (var i = 1; i < transitions.length; i += 1) {
    expect(
      _signature(transitions[i].before),
      _signature(transitions[i - 1].after),
      reason: 'transition $i must continue from the previous final state',
    );
    expect(
      transitions[i].after.elapsed,
      greaterThanOrEqualTo(transitions[i].before.elapsed),
    );
    expect(
      transitions[i].after.ball.distanceTo(transitions[i].ballEnd),
      lessThan(1e-9),
    );
  }
  final attackerNumbers =
      transitions.first.before.attackers.map((player) => player.number).toSet();
  final defenderNumbers =
      transitions.first.before.defenders.map((player) => player.number).toSet();
  for (final transition in transitions) {
    expect(transition.after.attackers.map((player) => player.number).toSet(),
        attackerNumbers);
    expect(transition.after.defenders.map((player) => player.number).toSet(),
        defenderNumbers);
  }
}

int _movedAttackers(List<AttackTransition> transitions) =>
    transitions.fold<Set<int>>(<int>{}, (moved, transition) {
      for (final before in transition.before.attackers) {
        final after = transition.after.attackers
            .firstWhere((player) => player.number == before.number);
        if (before.position.distanceTo(after.position) > .002) {
          moved.add(before.number);
        }
      }
      return moved;
    }).length;

int _movedDefenders(List<AttackTransition> transitions) =>
    transitions.fold<Set<int>>(<int>{}, (moved, transition) {
      for (final before in transition.before.defenders) {
        final after = transition.after.defenders
            .firstWhere((player) => player.number == before.number);
        if (before.position.distanceTo(after.position) > .002) {
          moved.add(before.number);
        }
      }
      return moved;
    }).length;

String _branchSignature(ScanPassPossessionBranch branch) => branch.transitions
    .map((transition) => _signature(transition.after))
    .join('|');

String _signature(AttackState state) {
  String point(ScanPassPoint point) =>
      '${point.x.toStringAsFixed(4)},${point.y.toStringAsFixed(4)}';
  final attackers = state.attackers
      .map((player) => '${player.number}:${point(player.position)}')
      .join('/');
  final defenders = state.defenders
      .map((player) => '${player.number}:${point(player.position)}')
      .join('/');
  return [
    attackers,
    defenders,
    point(state.ball),
    state.carrierNumber,
    state.end,
    state.elapsed.toStringAsFixed(3),
  ].join('#');
}
