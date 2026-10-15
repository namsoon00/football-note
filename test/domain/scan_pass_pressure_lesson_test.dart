import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart'
    show ScanPassPoint;
import 'package:football_note/domain/scan_pass/scan_pass_pressure_lesson.dart';

void main() {
  const engine = ScanPassPressureEngine();

  group('physical causality', () {
    test('the same inside contact reverses when pressure changes sides', () {
      final base = engine
          .observe(PressureLessonCatalog.build(seed: 2).first)
          .decisionState;
      final carrier = base.carrier!;
      final action = PressureAction(
        label: 'unchanged-spatial-action',
        kind: PressureActionKind.firstTouch,
        target: base.ball.position + const ScanPassPoint(.8, 1.8),
      );
      var isolated = base;
      for (final role in const [
        PressureActorRole.cover,
        PressureActorRole.tracker,
      ]) {
        isolated = _moveRole(
          isolated,
          role,
          ScanPassPoint(84, role == PressureActorRole.cover ? 52 : 58),
          const ScanPassPoint(0, 0),
          reactivity: 0,
        );
      }
      final outside = _moveRole(
        isolated,
        PressureActorRole.presser,
        carrier.position + const ScanPassPoint(-.2, -7.5),
        const ScanPassPoint(0, 0),
        reactivity: 1,
      );
      final inside = _moveRole(
        isolated,
        PressureActorRole.presser,
        carrier.position + const ScanPassPoint(.2, 1.7),
        const ScanPassPoint(0, -1.0),
        reactivity: 1,
      );

      final safer = engine.simulate(outside, action);
      final worse = engine.simulate(inside, action);

      expect(safer.assessment.safety, isNot(PressureSafety.lost));
      expect(worse.assessment.safety, PressureSafety.lost);
      expect(safer.assessment.pressureClearanceMetres,
          greaterThan(worse.assessment.pressureClearanceMetres + 1.5));
    });

    test('cover geometry changes the value of an identical immediate pass', () {
      final base =
          engine.observe(PressureLessonCatalog.build(seed: 7)[3]).decisionState;
      final support = base.actorByRole(PressureActorRole.support);
      final action = PressureAction(
        label: 'same-pass',
        kind: PressureActionKind.pass,
        target: support.position,
      );
      final start = base.ball.position;
      final lane = start.lerp(support.position, .52);
      final open = _moveRole(
        base,
        PressureActorRole.cover,
        lane + const ScanPassPoint(0, 7),
        const ScanPassPoint(0, 0),
        reactivity: 0,
      );
      final clearedOpen = _moveRole(
        _moveRole(open, PressureActorRole.presser,
            lane + const ScanPassPoint(0, -8), const ScanPassPoint(0, 0),
            reactivity: 0),
        PressureActorRole.tracker,
        lane + const ScanPassPoint(5, -8),
        const ScanPassPoint(0, 0),
        reactivity: 0,
      );
      final blocked = _moveRole(
        _moveRole(
            _moveRole(base, PressureActorRole.presser,
                lane + const ScanPassPoint(0, -8), const ScanPassPoint(0, 0),
                reactivity: 0),
            PressureActorRole.tracker,
            lane + const ScanPassPoint(5, -8),
            const ScanPassPoint(0, 0),
            reactivity: 0),
        PressureActorRole.cover,
        lane + const ScanPassPoint(0, .2),
        const ScanPassPoint(0, 0),
        reactivity: 0,
      );

      final safe = engine.simulate(clearedOpen, action);
      final intercepted = engine.simulate(blocked, action);

      expect(safe.after.possession, PressurePossession.attack);
      expect(intercepted.after.possession, PressurePossession.defense);
      expect(intercepted.contact?.defenderNumber, 4);
    });

    test('ids, scenario label and action label cannot change physics', () {
      final scenario = PressureLessonCatalog.build(seed: 11).first;
      final original = engine.observe(scenario).decisionState;
      final renamedActors = <PressureActor>[
        for (var i = 0; i < original.actors.length; i++)
          original.actors[i].copyWith(id: 'renamed-$i'),
      ];
      final carrierRole = original.carrier!.role;
      final renamedCarrier =
          renamedActors.firstWhere((actor) => actor.role == carrierRole).id;
      final renamed = original.copyWith(
        actors: renamedActors,
        ball: PressureBall(
          position: original.ball.position,
          velocity: original.ball.velocity,
          carrierId: renamedCarrier,
        ),
      );
      final target = original.ball.position + const ScanPassPoint(.7, -1.7);
      final a = engine.simulate(
        original,
        PressureAction(
          label: 'previous-choice-inside',
          kind: PressureActionKind.firstTouch,
          target: target,
        ),
      );
      final b = engine.simulate(
        renamed,
        PressureAction(
          label: 'anything-else',
          kind: PressureActionKind.firstTouch,
          target: target,
        ),
      );

      expect(a.assessment.quality, b.assessment.quality);
      expect(a.assessment.result, b.assessment.result);
      expect(a.assessment.pressureClearanceMetres,
          closeTo(b.assessment.pressureClearanceMetres, 1e-8));
      expect(_physicalSignature(a.after), _physicalSignature(b.after));
      expect(scenario.relabeled('cosmetic-only').observationStart,
          same(scenario.observationStart));
    });

    test('catalog has reversals and no universal inside or pass solution', () {
      var insideWins = 0;
      var outsideWins = 0;
      var immediateWins = 0;
      var severalDefensible = 0;
      var insideRetainsOutsideLoses = 0;
      var outsideRetainsInsideLoses = 0;
      for (final scenario in PressureLessonCatalog.build(seed: 19)) {
        final state = engine.observe(scenario).decisionState;
        final results = {
          for (final option
              in engine.optionsFor(state, PressureDecisionStage.firstContact))
            option.kind: engine.simulate(state, option.action),
        };
        final inside = results[PressureOptionKind.touchInside]!;
        final outside = results[PressureOptionKind.touchOutside]!;
        final pass = results[PressureOptionKind.immediatePass]!;
        if (inside.after.possession == PressurePossession.attack &&
            outside.after.possession != PressurePossession.attack) {
          insideRetainsOutsideLoses++;
        }
        if (outside.after.possession == PressurePossession.attack &&
            inside.after.possession != PressurePossession.attack) {
          outsideRetainsInsideLoses++;
        }
        if (_rank(inside) > _rank(outside)) insideWins++;
        if (_rank(outside) > _rank(inside)) outsideWins++;
        if (_rank(pass) >= _rank(inside) && _rank(pass) >= _rank(outside)) {
          immediateWins++;
        }
        if (results.values
                .where((result) =>
                    result.assessment.quality ==
                        PressureDecisionQuality.strong ||
                    result.assessment.quality == PressureDecisionQuality.sound)
                .length >=
            2) {
          severalDefensible++;
        }
      }
      expect(insideWins, greaterThan(0));
      expect(outsideWins, greaterThan(0));
      expect(immediateWins, greaterThan(0));
      expect(severalDefensible, greaterThan(0));
      expect(insideRetainsOutsideLoses, greaterThan(0));
      expect(outsideRetainsInsideLoses, greaterThan(0));
    });

    test('first contact opens blocked lanes while early passing stays useful',
        () {
      for (final seed in [19, 24, 41]) {
        var opensAfterTouch = 0;
        var earlyForward = 0;
        for (final scenario in PressureLessonCatalog.build(seed: seed)
            .where((scenario) => !scenario.heldOut)) {
          final state = engine.observe(scenario).decisionState;
          final options =
              engine.optionsFor(state, PressureDecisionStage.firstContact);
          final forwardPasses = options.where((option) =>
              option.action.kind == PressureActionKind.pass &&
              option.action.target.x > state.ball.position.x + 1);
          if (forwardPasses.any((option) =>
              engine.simulate(state, option.action).after.possession ==
              PressurePossession.attack)) {
            earlyForward += 1;
            continue;
          }
          final contacts = options
              .where((option) =>
                  option.action.kind == PressureActionKind.firstTouch)
              .map((option) => engine.simulate(state, option.action));
          if (contacts.any((result) =>
              result.after.possession == PressurePossession.attack &&
              result.assessment.connections.any(
                  (connection) => connection.safe && connection.forward))) {
            opensAfterTouch += 1;
          }
        }
        expect(opensAfterTouch, greaterThanOrEqualTo(2), reason: 'seed $seed');
        expect(earlyForward, greaterThan(0), reason: 'seed $seed');
      }
    });

    test(
        'a safe backward outlet retains possession without hiding progress cost',
        () {
      var state = engine
          .observe(PressureLessonCatalog.build(seed: 41).first)
          .decisionState;
      final carrier = state.carrier!;
      var offset = 0.0;
      for (final role in const [
        PressureActorRole.presser,
        PressureActorRole.cover,
        PressureActorRole.tracker,
      ]) {
        state = _moveRole(
          state,
          role,
          ScanPassPoint(carrier.position.x + 13 + offset, 52 + offset),
          const ScanPassPoint(0, 0),
          reactivity: 0,
        );
        offset += 3;
      }
      expect(engine.connections(state).any((c) => c.safe && c.forward), isTrue);
      final passer = state.actorByRole(PressureActorRole.passer);
      final flight = state.ball.position.distanceTo(passer.position) /
          ScanPassPressureEngine.passSpeedMetresPerSecond;
      final result = engine.simulate(
        state,
        PressureAction(
          label: 'safe-backward-support',
          kind: PressureActionKind.pass,
          target: passer.position + passer.velocity * flight,
        ),
      );

      expect(result.after.possession, PressurePossession.attack);
      expect(result.assessment.missedForwardOpportunity, isTrue);
      expect(result.assessment.quality, PressureDecisionQuality.sound);
    });
  });

  group('continuous simulation', () {
    test('pass has no carrier in flight and interception is contact-based', () {
      final base = engine
          .observe(PressureLessonCatalog.build(seed: 5).first)
          .decisionState;
      final support = base.actorByRole(PressureActorRole.support);
      final lane = base.ball.position.lerp(support.position, .46);
      final blocked = _moveRole(
        base,
        PressureActorRole.cover,
        lane,
        const ScanPassPoint(0, 0),
        reactivity: 0,
      );
      final result = engine.simulate(
        blocked,
        PressureAction(
          kind: PressureActionKind.pass,
          target: support.position,
        ),
      );

      expect(result.contact, isNotNull);
      expect(result.after.possession, PressurePossession.defense);
      final flight =
          result.trace.frames.where((frame) => frame.ball.inFlight).toList();
      expect(flight, isNotEmpty);
      expect(flight.every((frame) => frame.ball.carrierId == null), isTrue);
      final defender = result.after.actorById(result.contact!.defenderId);
      expect(defender.position.distanceTo(result.after.ball.position),
          lessThanOrEqualTo(ScanPassPressureEngine.contactRadiusMetres));
      expect(result.contact!.point.distanceTo(result.after.ball.position),
          lessThan(1e-8));
    });

    test('bounded steps preserve clocks, endpoints and plausible speeds', () {
      for (final scenario in PressureLessonCatalog.build(seed: 23)) {
        final observation = engine.observe(scenario);
        expect(observation.trace.duration, inInclusiveRange(2.0, 3.0));
        _expectBoundedTrace(observation.trace);
        for (final option in engine.optionsFor(
            observation.decisionState, PressureDecisionStage.firstContact)) {
          final result =
              engine.simulate(observation.decisionState, option.action);
          _expectBoundedTrace(result.trace);
          if (option.action.kind == PressureActionKind.firstTouch) {
            expect(result.trace.duration, lessThan(2.5));
            if (result.after.possession == PressurePossession.attack) {
              final travelled = result.before.ball.position
                  .distanceTo(result.after.ball.position);
              expect(travelled, inInclusiveRange(.95, 2.55));
              expect(
                result.after.ball.position.distanceTo(option.action.target),
                lessThan(.02),
              );
            }
          }
        }
      }
    });

    test('roles react to world movement, never the action label', () {
      final state = engine
          .observe(PressureLessonCatalog.build(seed: 29).first)
          .decisionState;
      final action = engine
          .optionsFor(state, PressureDecisionStage.firstContact)
          .first
          .action;
      final a = engine.simulate(state, action.relabeled('A'));
      final b = engine.simulate(state, action.relabeled('B'));
      expect(a.trace.frames.map(_physicalSignature),
          b.trace.frames.map(_physicalSignature));

      final carrier = state.carrier!;
      final shifted = state.copyWith(
        actors: [
          for (final actor in state.actors)
            actor.role == carrier.role
                ? actor.copyWith(
                    position: actor.position + const ScanPassPoint(0, 5))
                : actor,
        ],
        ball: PressureBall(
          position: state.ball.position + const ScanPassPoint(0, 5),
          carrierId: carrier.id,
        ),
      );
      final moved = engine.simulate(
        shifted,
        PressureAction(
          kind: action.kind,
          target: action.target + const ScanPassPoint(0, 5),
        ),
      );
      final originalPresser =
          a.trace.frames[1].actorByRole(PressureActorRole.presser).velocity;
      final movedPresser =
          moved.trace.frames[1].actorByRole(PressureActorRole.presser).velocity;
      expect(originalPresser.y, isNot(closeTo(movedPresser.y, 1e-4)));
    });

    test('connection evidence is the result of the common pass simulation', () {
      for (final seed in const [19, 24, 41]) {
        for (final scenario in PressureLessonCatalog.build(seed: seed)) {
          final state = engine.observe(scenario).decisionState;
          final snapshots = <PressureWorld>[state];
          for (final option
              in engine.optionsFor(state, PressureDecisionStage.firstContact)) {
            final result = engine.simulate(state, option.action);
            if (result.after.possession == PressurePossession.attack) {
              snapshots.add(result.after);
            }
          }
          for (final snapshot in snapshots) {
            for (final lane in engine.connections(snapshot)) {
              final result = engine.simulate(
                snapshot,
                PressureAction(
                  kind: PressureActionKind.pass,
                  target: lane.target,
                ),
              );
              final physicallyRetained =
                  result.after.possession == PressurePossession.attack &&
                      result.after.carrier?.role == lane.receiverRole;
              expect(lane.safe, physicallyRetained,
                  reason:
                      '$seed/${scenario.id}/${lane.receiverRole.name}@${snapshot.clock}');
            }
          }
        }
      }
    });

    test('zero-clock release frames never move the ball or an actor', () {
      for (final scenario in PressureLessonCatalog.build(seed: 41)) {
        final state = engine.observe(scenario).decisionState;
        for (final option
            in engine.optionsFor(state, PressureDecisionStage.firstContact)) {
          final trace = engine.simulate(state, option.action).trace;
          for (var index = 1; index < trace.frames.length; index++) {
            final before = trace.frames[index - 1];
            final after = trace.frames[index];
            if ((after.clock - before.clock).abs() > 1e-9) continue;
            expect(after.ball.position.distanceTo(before.ball.position),
                lessThan(1e-9));
            for (final actor in before.actors) {
              expect(
                after
                    .actorByRole(actor.role)
                    .position
                    .distanceTo(actor.position),
                lessThan(1e-9),
              );
            }
          }
        }
      }
    });

    test('runner stays neutral and offside is judged only on involvement', () {
      final state = engine
          .observe(PressureLessonCatalog.build(seed: 19).first)
          .decisionState;
      final kinds = engine
          .optionsFor(state, PressureDecisionStage.firstContact)
          .map((option) => option.kind)
          .toSet();
      expect(kinds, contains(PressureOptionKind.immediateRunnerPass));
      expect(kinds, contains(PressureOptionKind.immediateBackPass));

      final shifted = state.copyWith(actors: [
        for (final actor in state.actors)
          if (actor.role == PressureActorRole.runner)
            actor.copyWith(position: const ScanPassPoint(96, 20))
          else if (actor.team == PressureTeam.defense)
            actor.copyWith(
              position: ScanPassPoint(90, 52 + actor.role.index.toDouble()),
              home: ScanPassPoint(90, 52 + actor.role.index.toDouble()),
              velocity: const ScanPassPoint(0, 0),
              intentVelocity: const ScanPassPoint(0, 0),
              reactivity: 0,
            )
          else
            actor,
      ]);
      expect(
        engine
            .optionsFor(shifted, PressureDecisionStage.firstContact)
            .map((option) => option.kind),
        contains(PressureOptionKind.immediateRunnerPass),
      );
      final runnerOption = engine
          .optionsFor(shifted, PressureDecisionStage.firstContact)
          .firstWhere(
            (option) => option.kind == PressureOptionKind.immediateRunnerPass,
          );
      final offside = engine.simulate(shifted, runnerOption.action);
      expect(offside.offside, isTrue);
      expect(offside.intendedReceiverRole, PressureActorRole.runner);
      expect(offside.assessment.result, PressureResultKind.offside);
      expect(offside.contact, isNull);
      expect(offside.after.possession, PressurePossession.defense);

      final lane = shifted.ball.position.lerp(runnerOption.action.target, .48);
      final interceptedState = _moveRole(
        shifted,
        PressureActorRole.cover,
        lane,
        const ScanPassPoint(0, 0),
        reactivity: 0,
      );
      final intercepted = engine.simulate(
        interceptedState,
        engine
            .optionsFor(
              interceptedState,
              PressureDecisionStage.firstContact,
            )
            .firstWhere(
              (option) => option.kind == PressureOptionKind.immediateRunnerPass,
            )
            .action,
      );
      expect(intercepted.offside, isFalse);
      expect(intercepted.contact?.defenderNumber, 4);
      expect(intercepted.assessment.result, PressureResultKind.intercepted);

      final level = shifted.copyWith(actors: [
        for (final actor in shifted.actors)
          actor.role == PressureActorRole.runner
              ? actor.copyWith(position: const ScanPassPoint(92, 20))
              : actor,
      ]);
      final levelPass = engine.simulate(
        level,
        engine
            .optionsFor(level, PressureDecisionStage.firstContact)
            .firstWhere(
              (option) => option.kind == PressureOptionKind.immediateRunnerPass,
            )
            .action,
      );
      expect(levelPass.offside, isFalse);
      expect(levelPass.after.carrier?.role, PressureActorRole.runner);
    });

    test('a moving runner receives an early pass at the sampled contact', () {
      var state = engine
          .observe(PressureLessonCatalog.build(seed: 19).first)
          .decisionState;
      for (final role in const [
        PressureActorRole.presser,
        PressureActorRole.cover,
        PressureActorRole.tracker,
      ]) {
        state = _moveRole(
          state,
          role,
          ScanPassPoint(82, 50 + role.index.toDouble()),
          const ScanPassPoint(0, 0),
          reactivity: 0,
        );
      }
      final option = engine
          .optionsFor(state, PressureDecisionStage.firstContact)
          .firstWhere(
            (value) => value.kind == PressureOptionKind.immediateRunnerPass,
          );
      final result = engine.simulate(state, option.action);

      expect(result.offside, isFalse);
      expect(result.after.carrier?.role, PressureActorRole.runner);
      expect(
        result.after.ball.position.distanceTo(
          result.after.actorByRole(PressureActorRole.runner).position,
        ),
        lessThanOrEqualTo(.55),
      );
    });
  });

  group('decision snapshots and session', () {
    test('a completed forward pass counts even without a further forward lane',
        () {
      final scenarios = PressureLessonCatalog.build(seed: 19);
      final state = engine.observe(scenarios.first).decisionState;
      final pass = engine
          .optionsFor(state, PressureDecisionStage.firstContact)
          .firstWhere((option) =>
              option.kind == PressureOptionKind.immediateRunnerPass);
      final result = engine.simulate(state, pass.action);
      expect(result.after.possession, PressurePossession.attack);
      expect(result.assessment.actionProgressMetres, greaterThan(1.5));
      expect(
          result.assessment.connections
              .any((lane) => lane.safe && lane.forward),
          isFalse);
      final session = PressureLessonSession(situations: scenarios)
          .recordFirstAttempt(PressureLessonAttempt(
        situationIndex: 0,
        firstDecisionState: state,
        firstDecision: result,
        lastDecisionState: state,
      ));
      expect(session.openedConnections, 1);
    });

    test('retry and alternatives start from the identical immutable state', () {
      final snapshot = engine
          .observe(PressureLessonCatalog.build(seed: 31).first)
          .decisionState;
      final options =
          engine.optionsFor(snapshot, PressureDecisionStage.firstContact);
      final first = engine.simulate(snapshot, options.first.action);
      final retry = engine.simulate(snapshot, options.first.action);
      final alternatives = engine.compare(
          snapshot, options.skip(1).map((option) => option.action));

      expect(first.before, same(snapshot));
      expect(retry.before, same(snapshot));
      expect(alternatives.every((result) => identical(result.before, snapshot)),
          isTrue);
      expect(first.trace.frames.map(_physicalSignature),
          retry.trace.frames.map(_physicalSignature));
    });

    test('retries never replace first attempts, including held-out records',
        () {
      final situations = PressureLessonCatalog.build(seed: 37);
      var session = PressureLessonSession(situations: situations);
      final state = engine.observe(situations[7]).decisionState;
      final options =
          engine.optionsFor(state, PressureDecisionStage.firstContact);
      final original = PressureLessonAttempt(
        situationIndex: 7,
        firstDecisionState: state,
        firstDecision: engine.simulate(state, options.first.action),
        lastDecisionState: state,
      );
      final retry = PressureLessonAttempt(
        situationIndex: 7,
        firstDecisionState: state,
        firstDecision: engine.simulate(state, options.last.action),
        lastDecisionState: state,
      );
      session = session.recordFirstAttempt(original);
      session = session.recordFirstAttempt(retry);

      expect(session.firstAttempts[7], same(original));
      expect(
          session.situations.take(6).every((scene) => !scene.heldOut), isTrue);
      expect(
          session.situations.skip(6).every((scene) => scene.heldOut), isTrue);
      final training = session.situations
          .take(6)
          .map((scene) => _physicalSignature(scene.observationStart))
          .toSet();
      expect(
          session.situations.skip(6).every((scene) =>
              !training.contains(_physicalSignature(scene.observationStart))),
          isTrue);
    });
  });
}

double _rank(PressureSimulationResult result) {
  final quality = switch (result.assessment.quality) {
    PressureDecisionQuality.strong => 3,
    PressureDecisionQuality.sound => 2,
    PressureDecisionQuality.compromised => 1,
    PressureDecisionQuality.lost => 0,
  };
  final safety = switch (result.assessment.safety) {
    PressureSafety.safe => 2,
    PressureSafety.pressured => 1,
    PressureSafety.lost => 0,
  };
  return quality * 100 +
      safety * 10 +
      result.assessment.pressureClearanceMetres.clamp(0, 9).toDouble();
}

PressureWorld _moveRole(
  PressureWorld world,
  PressureActorRole role,
  ScanPassPoint position,
  ScanPassPoint velocity, {
  double? reactivity,
}) {
  return world.copyWith(actors: [
    for (final actor in world.actors)
      actor.role == role
          ? actor.copyWith(
              position: position,
              home: position,
              velocity: velocity,
              intentVelocity: velocity,
              reactivity: reactivity,
            )
          : actor,
  ]);
}

void _expectBoundedTrace(PressureTrace trace) {
  for (var index = 1; index < trace.frames.length; index++) {
    final before = trace.frames[index - 1];
    final after = trace.frames[index];
    final dt = after.clock - before.clock;
    expect(dt, greaterThanOrEqualTo(0));
    expect(dt, lessThanOrEqualTo(.026));
    if (dt <= 1e-9) {
      expect(
          before.ball.position.distanceTo(after.ball.position), lessThan(1e-9));
      for (final actor in before.actors) {
        expect(
            actor.position.distanceTo(after.actorByRole(actor.role).position),
            lessThan(1e-9));
      }
      continue;
    }
    for (final actor in before.actors) {
      final next = after.actorByRole(actor.role);
      expect(actor.position.distanceTo(next.position) / dt,
          lessThanOrEqualTo(ScanPassPressureEngine.maximumPlayerSpeed + .08),
          reason: actor.role.name);
      expect(
        (next.velocity - actor.velocity).distance / dt,
        lessThanOrEqualTo(actor.maxAcceleration + .08),
        reason: '${actor.role.name} acceleration',
      );
    }
    final ballSpeed = before.ball.position.distanceTo(after.ball.position) / dt;
    expect(ballSpeed,
        lessThanOrEqualTo(ScanPassPressureEngine.passSpeedMetresPerSecond + .1),
        reason:
            '${before.clock}->${after.clock} ${before.ball.position.x},${before.ball.position.y} -> ${after.ball.position.x},${after.ball.position.y} carrier ${before.ball.carrierId}->${after.ball.carrierId}');
  }
}

String _physicalSignature(PressureWorld world) => [
      world.clock.toStringAsFixed(6),
      world.ball.position.x.toStringAsFixed(6),
      world.ball.position.y.toStringAsFixed(6),
      world.ball.velocity.x.toStringAsFixed(6),
      world.ball.velocity.y.toStringAsFixed(6),
      world.possession.name,
      world.carrier?.role.name,
      for (final actor in world.actors) ...[
        actor.team.name,
        actor.role.name,
        actor.position.x.toStringAsFixed(6),
        actor.position.y.toStringAsFixed(6),
        actor.velocity.x.toStringAsFixed(6),
        actor.velocity.y.toStringAsFixed(6),
      ],
    ].join('|');
