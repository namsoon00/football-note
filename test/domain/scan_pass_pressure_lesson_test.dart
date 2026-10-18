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

    test('catalog has touch reversals and retained first-time passes', () {
      var insideWins = 0;
      var outsideWins = 0;
      var immediateRetains = 0;
      var severalDefensible = 0;
      var insideRetainsOutsideLoses = 0;
      var outsideRetainsInsideLoses = 0;
      for (final scenario in PressureLessonCatalog.build(seed: 19).where(
        (scenario) =>
            scenario.family == PressureLearningFamily.pressureReception &&
            scenario.variant != PressureLessonVariant.unseen,
      )) {
        final state = engine.observe(scenario).decisionState;
        final results = {
          for (final option
              in engine.optionsFor(state, PressureDecisionStage.firstContact))
            option.kind: engine.simulate(state, option.action),
        };
        final inside = results[PressureOptionKind.touchInside]!;
        final outside = results[PressureOptionKind.touchOutside]!;
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
        if (results.entries.any((entry) =>
            entry.key == PressureOptionKind.immediatePass ||
                    entry.key == PressureOptionKind.immediateRunnerPass ||
                    entry.key == PressureOptionKind.immediateBackPass
                ? entry.value.after.possession == PressurePossession.attack
                : false)) {
          immediateRetains++;
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
      expect(immediateRetains, greaterThan(0));
      expect(severalDefensible, greaterThan(0));
      expect(insideRetainsOutsideLoses, greaterThan(0));
      expect(outsideRetainsInsideLoses, greaterThan(0));
    });

    test('pressure receptions retain several physically defensible choices',
        () {
      for (final seed in [19, 24, 41]) {
        for (final scenario in PressureLessonCatalog.build(seed: seed).where(
            (scenario) =>
                scenario.family == PressureLearningFamily.pressureReception)) {
          final state = engine.observe(scenario).decisionState;
          final options =
              engine.optionsFor(state, PressureDecisionStage.firstContact);
          final retained = options
              .map((option) => engine.simulate(state, option.action))
              .where((result) =>
                  result.after.possession == PressurePossession.attack)
              .length;
          expect(retained, greaterThanOrEqualTo(2), reason: scenario.id);
          expect(
              options.any((option) =>
                  option.action.kind == PressureActionKind.firstTouch),
              isTrue);
          expect(
              options.any(
                  (option) => option.action.kind == PressureActionKind.pass),
              isTrue);
        }
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
        expect(
          observation.trace.duration,
          scenario.initialDecisionKind == PressureEpisodeDecisionKind.receive
              ? inInclusiveRange(2.0, 3.0)
              : closeTo(.65, .001),
        );
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
        lessThanOrEqualTo(.551),
      );
    });
  });

  group('decision snapshots and session', () {
    test('context is derived from each exact decision snapshot', () {
      final first = engine
          .observe(PressureLessonCatalog.build(seed: 19).first)
          .decisionState;
      final touch = engine
          .optionsFor(first, PressureDecisionStage.firstContact)
          .where(
              (option) => option.action.kind == PressureActionKind.firstTouch)
          .map((option) => engine.simulate(first, option.action))
          .firstWhere(
              (result) => result.after.possession == PressurePossession.attack);

      final firstContext =
          engine.situationContext(first, PressureDecisionStage.firstContact);
      final nextContext = engine.situationContext(
          touch.after, PressureDecisionStage.nextConnection);
      final retryContext = engine.situationContext(
          touch.after, PressureDecisionStage.nextConnection);

      expect(firstContext.stage, PressureDecisionStage.firstContact);
      expect(nextContext.stage, PressureDecisionStage.nextConnection);
      expect(nextContext.carrierNumber, touch.after.carrier!.number);
      expect(nextContext.pressureDistanceMetres,
          isNot(closeTo(firstContext.pressureDistanceMetres, 1e-6)));
      expect(retryContext.pressureDistanceMetres,
          nextContext.pressureDistanceMetres);
      expect(retryContext.coverLaneDistanceMetres,
          nextContext.coverLaneDistanceMetres);
    });

    test('action evidence keeps a good touch separate from a lost next pass',
        () {
      PressureActionEvidence? touchEvidence;
      PressureActionEvidence? lostPassEvidence;
      for (final scenario in PressureLessonCatalog.build(seed: 19)) {
        final first = engine.observe(scenario).decisionState;
        for (final touchOption in engine
            .optionsFor(first, PressureDecisionStage.firstContact)
            .where((option) =>
                option.action.kind == PressureActionKind.firstTouch)) {
          final touch = engine.simulate(first, touchOption.action);
          if (touch.after.possession != PressurePossession.attack) continue;
          final touchFacts = engine.actionEvidence(touch);
          if (touchFacts.benefit == PressureActionBenefit.none) continue;
          for (final passOption in engine
              .optionsFor(touch.after, PressureDecisionStage.nextConnection)
              .where(
                  (option) => option.action.kind == PressureActionKind.pass)) {
            final pass = engine.simulate(touch.after, passOption.action);
            if (pass.after.possession == PressurePossession.attack) continue;
            touchEvidence = touchFacts;
            lostPassEvidence = engine.actionEvidence(pass);
            break;
          }
          if (lostPassEvidence != null) break;
        }
        if (lostPassEvidence != null) break;
      }

      expect(touchEvidence, isNotNull);
      expect(touchEvidence!.benefit, isNot(PressureActionBenefit.none));
      expect(lostPassEvidence, isNotNull);
      expect(lostPassEvidence!.benefit, PressureActionBenefit.none);
      expect(
        lostPassEvidence.limitation,
        anyOf(
          PressureActionLimitation.interception,
          PressureActionLimitation.looseBall,
          PressureActionLimitation.offside,
        ),
      );
      if (lostPassEvidence.limitation ==
          PressureActionLimitation.interception) {
        expect(lostPassEvidence.contactPoint, isNotNull);
        expect(lostPassEvidence.freezeFrame.ball.position,
            lostPassEvidence.contactPoint);
      }
    });

    test('only an actually controlled pass is credited as received', () {
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
              (value) => value.kind == PressureOptionKind.immediateRunnerPass);
      final received = engine.simulate(state, option.action);
      final receivedEvidence = engine.actionEvidence(received);
      expect(
          receivedEvidence.benefit, PressureActionBenefit.forwardPassReceived);
      expect(receivedEvidence.benefitReceiverNumber,
          received.after.carrier!.number);

      final lane = state.ball.position.lerp(option.action.target, .5);
      final blocked = _moveRole(
        state,
        PressureActorRole.cover,
        lane,
        const ScanPassPoint(0, 0),
        reactivity: 0,
      );
      final lost = engine.simulate(blocked, option.action);
      final lostEvidence = engine.actionEvidence(lost);
      expect(lost.after.possession, isNot(PressurePossession.attack));
      expect(lostEvidence.benefit, PressureActionBenefit.none);
      expect(lostEvidence.benefitReceiverNumber, isNull);
    });

    test('a completed forward pass counts even without a further forward lane',
        () {
      final scenarios = PressureLessonCatalog.build(seed: 19);
      var state = engine.observe(scenarios.first).decisionState;
      var offset = 0.0;
      for (final role in const [
        PressureActorRole.presser,
        PressureActorRole.cover,
        PressureActorRole.tracker,
      ]) {
        state = _moveRole(
          state,
          role,
          ScanPassPoint(88 + offset, 58 - offset),
          const ScanPassPoint(0, 0),
          reactivity: 0,
        );
        offset += 2;
      }
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
      final state = engine.observe(situations[17]).decisionState;
      final options =
          engine.optionsFor(state, PressureDecisionStage.firstContact);
      final original = PressureLessonAttempt(
        situationIndex: 17,
        firstDecisionState: state,
        firstDecision: engine.simulate(state, options.first.action),
        lastDecisionState: state,
      );
      final retry = PressureLessonAttempt(
        situationIndex: 17,
        firstDecisionState: state,
        firstDecision: engine.simulate(state, options.last.action),
        lastDecisionState: state,
      );
      session = session.recordFirstAttempt(original);
      session = session.recordFirstAttempt(retry);

      expect(session.firstAttempts[17], same(original));
      expect(
          session.situations.take(12).every((scene) => !scene.heldOut), isTrue);
      expect(
          session.situations.skip(12).every((scene) => scene.heldOut), isTrue);
      final training = session.situations
          .take(12)
          .map((scene) => _physicalSignature(scene.observationStart))
          .toSet();
      expect(
          session.situations.skip(12).every((scene) =>
              !training.contains(_physicalSignature(scene.observationStart))),
          isTrue);
    });
  });

  group('continuous connected episodes', () {
    test('catalog has six families and guided contrast unseen variants', () {
      final catalog = PressureLessonCatalog.build(seed: 19);
      expect(catalog, hasLength(18));
      expect(catalog.take(12).every((scenario) => !scenario.heldOut), isTrue);
      expect(catalog.skip(12).every((scenario) => scenario.heldOut), isTrue);
      for (final family in PressureLearningFamily.values) {
        final cases = catalog.where((scenario) => scenario.family == family);
        expect(cases, hasLength(3), reason: family.name);
        expect(cases.map((scenario) => scenario.variant).toSet(),
            PressureLessonVariant.values.toSet());
        expect(cases.every((scenario) => scenario.observationFacts.isNotEmpty),
            isTrue);
        expect(cases.first.showMovementGuidance, isTrue);
        expect(
            cases.skip(1).every((scenario) => !scenario.showMovementGuidance),
            isTrue);
        final guided = cases.first;
        final contrast = cases.elementAt(1);
        final changedRole = switch (guided.contrastFeature) {
          PressureContrastFeature.approachSide ||
          PressureContrastFeature.presserCommitment =>
            PressureActorRole.presser,
          PressureContrastFeature.coverPosition ||
          PressureContrastFeature.farSideClosure =>
            PressureActorRole.cover,
          PressureContrastFeature.runnerStart => PressureActorRole.runner,
          PressureContrastFeature.trackerReaction => PressureActorRole.tracker,
        };
        for (final role in PressureActorRole.values) {
          final a = guided.observationStart.actorByRole(role);
          final b = contrast.observationStart.actorByRole(role);
          if (role == changedRole) {
            expect(_actorConfiguration(a), isNot(_actorConfiguration(b)),
                reason: '${family.name} must change ${role.name}.');
          } else {
            expect(_actorConfiguration(a), _actorConfiguration(b),
                reason:
                    '${family.name} contrast confounds ${role.name} nuisance state.');
          }
        }
      }
    });

    test('scene recipes are typed, distinct and capped at three judgments', () {
      final catalog = PressureLessonCatalog.build(seed: 19);
      final signatures = <PressureLearningFamily, String>{};
      for (final scenario in catalog) {
        expect(scenario.sceneJudgments, isNotEmpty);
        expect(scenario.sceneJudgments.length, lessThanOrEqualTo(3));
        expect(
            scenario.sceneJudgments.first.kind, scenario.initialDecisionKind);
        signatures[scenario.family] = scenario.sceneJudgments
            .map((beat) => '${beat.kind.name}:${beat.actorRule.name}:'
                '${beat.actorRole?.name}')
            .join('|');
      }
      expect(signatures.values.toSet(), hasLength(6));
      expect(
        catalog
            .where((scenario) =>
                scenario.family == PressureLearningFamily.pressureReception)
            .every((scenario) => scenario.sceneJudgments.every(
                (beat) => beat.kind != PressureEpisodeDecisionKind.support)),
        isTrue,
      );
    });

    test('a retained pass hands the next judgment to the actual carrier', () {
      var episode =
          engine.startEpisode(PressureLessonCatalog.build(seed: 19).first);
      final passes = engine
          .episodeOptions(episode)
          .where((option) => option.action.kind == PressureActionKind.pass);
      final retained = passes.firstWhere((option) =>
          engine.simulate(episode.world, option.action).after.possession ==
          PressurePossession.attack);
      episode = engine.chooseEpisodeOption(episode, retained);

      expect(episode.isComplete, isFalse);
      expect(episode.timeline, hasLength(1));
      expect(episode.pendingDecision, PressureEpisodeDecisionKind.onBall);
      expect(episode.pendingActorId, episode.world.ball.carrierId);
      expect(episode.pendingActorId, isNot(episode.timeline.single.actorId));
      expect(episode.timeline.single.actorNumber, 19);
      expect(episode.world, same(episode.timeline.single.after));
    });

    test('third-player scene follows actual #19 to #10 to #17 ownership', () {
      var episode =
          engine.startEpisode(PressureLessonCatalog.build(seed: 0)[8]);
      expect(episode.world.carrier?.number, 19);
      expect(episode.pendingActorId, episode.world.carrier?.id);
      episode = engine.chooseEpisodeOption(
        episode,
        engine.episodeOptions(episode).firstWhere(
            (option) => option.targetRole == PressureActorRole.support),
      );
      expect(episode.world.carrier?.number, 10);
      expect(episode.pendingActorId, episode.world.carrier?.id);
      episode = engine.chooseEpisodeOption(
        episode,
        engine.episodeOptions(episode).firstWhere(
            (option) => option.targetRole == PressureActorRole.runner),
      );
      expect(episode.timeline.last.after.carrier?.number, 17);
      expect(
          episode.timeline.map((decision) => decision.actorNumber), [19, 10]);
    });

    test('complete scenes use at most three key judgments and a separate tail',
        () {
      var episode =
          engine.startEpisode(PressureLessonCatalog.build(seed: 19).first);
      while (!episode.isComplete) {
        if (episode.pendingDecision == PressureEpisodeDecisionKind.support) {
          final focus = episode.world.actorById(episode.pendingActorId!);
          episode = engine.chooseSupportTarget(
            episode,
            focus.position + const ScanPassPoint(4.5, 4),
          );
        } else {
          episode = _bestRetainedEpisodeChoice(engine, episode);
        }
      }

      expect(episode.timeline.length, inInclusiveRange(1, 3));
      expect(episode.timeline.first.before,
          same(episode.observation.decisionState));
      for (var index = 1; index < episode.timeline.length; index++) {
        expect(episode.timeline[index].before,
            same(episode.timeline[index - 1].after));
      }
      final replay = PressureTrace.join([
        episode.observation.trace,
        for (final item in episode.timeline) item.fullTrace,
        if (episode.tail != null) episode.tail!.trace,
      ]);
      expect(replay.last, same(episode.world));
      if (episode.tail != null) {
        expect(episode.tail!.before, same(episode.timeline.last.after));
        expect(episode.tail!.trace.first, same(episode.tail!.before));
        expect(episode.tail!.actions.length, lessThanOrEqualTo(1));
      }
    });

    test('one-tap movement stops before the carrier decision', () {
      final scenario = PressureLessonCatalog.build(seed: 0)[4];
      final episode = engine.startEpisode(scenario);
      expect(episode.pendingDecision, PressureEpisodeDecisionKind.support);
      final carrierId = episode.world.ball.carrierId;
      final mover = episode.world.actorById(episode.pendingActorId!);
      final moved = engine.chooseSupportTarget(
        episode,
        mover.position + const ScanPassPoint(5, -5),
      );
      final support = moved.timeline.single.supportResult!;

      expect(support.continuation, isNull);
      expect(moved.isComplete, isFalse);
      expect(moved.pendingDecision, PressureEpisodeDecisionKind.onBall);
      expect(moved.pendingActorId, carrierId);
      expect(moved.world.ball.carrierId, carrierId);
      expect(moved.runPlan?.actorId, mover.id);
      expect(moved.runPlan?.isActive, isTrue);
      expect(moved.world, same(support.afterMovement));
    });

    test('two support destinations produce genuinely different lane evidence',
        () {
      final scenario = PressureLessonCatalog.build(seed: 0)[4];
      final episode = engine.startEpisode(scenario);
      final mover = episode.world.actorById(episode.pendingActorId!);
      final left = engine.simulateSupport(
        episode.world,
        mover.position + const ScanPassPoint(0, 7),
        actorId: mover.id,
      );
      final right = engine.simulateSupport(
        episode.world,
        mover.position + const ScanPassPoint(0, -7),
        actorId: mover.id,
      );
      final leftLanes = left.laneChanges
          .where((lane) => lane.usableAfter)
          .map((lane) => lane.receiverRole)
          .toSet();
      final rightLanes = right.laneChanges
          .where((lane) => lane.usableAfter)
          .map((lane) => lane.receiverRole)
          .toSet();

      expect(_physicalSignature(left.afterMovement),
          isNot(_physicalSignature(right.afterMovement)));
      expect(
        leftLanes != rightLanes ||
            left.laneChanges.any((lane) => right.laneChanges.every((other) =>
                other.receiverRole != lane.receiverRole ||
                (other.clearanceChangeMetres - lane.clearanceChangeMetres)
                        .abs() >
                    .05)),
        isTrue,
      );
      expect(right.movementDistanceMetres, greaterThan(0));
      _expectBoundedTrace(left.movementTrace);
      _expectBoundedTrace(right.movementTrace);
    });

    test('tracker closes and challenges when its runner owns the ball', () {
      final scenario = PressureLessonCatalog.build(seed: 19)[6];
      var world = engine.startEpisode(scenario).world;
      final runner = world.actorByRole(PressureActorRole.runner);
      world = _moveRole(
        world,
        PressureActorRole.runner,
        runner.position,
        const ScanPassPoint(0, 0),
      );
      world = _moveRole(
        world,
        PressureActorRole.tracker,
        runner.position - const ScanPassPoint(1.05, 0),
        const ScanPassPoint(0, 0),
        reactivity: .05,
      );
      world = _moveRole(
        world,
        PressureActorRole.presser,
        runner.position - const ScanPassPoint(14, 8),
        const ScanPassPoint(0, 0),
      );
      world = _moveRole(
        world,
        PressureActorRole.cover,
        runner.position - const ScanPassPoint(12, -8),
        const ScanPassPoint(0, 0),
      );
      final controlledRunner = world.actorByRole(PressureActorRole.runner);
      world = world.copyWith(
        ball: PressureBall(
          position: controlledRunner.position + const ScanPassPoint(.32, 0),
          velocity: const ScanPassPoint(0, 0),
          carrierId: controlledRunner.id,
        ),
        possession: PressurePossession.attack,
      );
      final beforeGap = world
          .actorByRole(PressureActorRole.tracker)
          .position
          .distanceTo(controlledRunner.position);
      final result = engine.simulate(
        world,
        PressureAction(
          kind: PressureActionKind.carry,
          target: world.ball.position + const ScanPassPoint(.5, 0),
        ),
      );

      expect(result.contact?.defenderNumber, 5);
      expect(result.after.possession, PressurePossession.defense);
      expect(
        result.after.actorByRole(PressureActorRole.tracker).position.distanceTo(
            result.after.actorByRole(PressureActorRole.runner).position),
        lessThan(beforeGap),
      );
      _expectBoundedTrace(result.trace);
    });

    test('selected route persists through a user pass to a different attacker',
        () {
      var episode =
          engine.startEpisode(PressureLessonCatalog.build(seed: 0)[4]);
      final mover = episode.world.actorById(episode.pendingActorId!);
      episode = engine.chooseSupportTarget(
        episode,
        mover.position + const ScanPassPoint(5, -5),
      );
      final atPause = episode.world.actorById(mover.id);
      final pass = engine.episodeOptions(episode).firstWhere((option) =>
          option.action.kind == PressureActionKind.pass &&
          option.targetRole != mover.role &&
          engine.simulate(episode.world, option.action).after.possession ==
              PressurePossession.attack);
      episode = engine.chooseEpisodeOption(episode, pass);
      final onBall = episode.timeline.last;
      final afterPass = onBall.after.actorById(mover.id);

      expect(onBall.actorId, onBall.before.ball.carrierId);
      expect(onBall.actionResult!.after.carrier?.id, isNot(mover.id));
      expect(
          afterPass.position
              .distanceTo(episode.timeline.first.supportResult!.boundedTarget),
          lessThan(atPause.position.distanceTo(
              episode.timeline.first.supportResult!.boundedTarget)));
      expect(onBall.runPlanBefore?.actorId, mover.id);
      expect(onBall.runPlanAfter, isNotNull);
    });

    test('a useful non-reception run opens a lane used by another attacker',
        () {
      var episode =
          engine.startEpisode(PressureLessonCatalog.build(seed: 0)[2]);
      episode = engine.chooseEpisodeOption(
        episode,
        engine
            .episodeOptions(episode)
            .firstWhere((option) => option.key == 'pass-support'),
      );
      final mover = episode.world.actorById(episode.pendingActorId!);
      expect(mover.number, 19);
      episode = engine.chooseSupportTarget(
        episode,
        mover.position + const ScanPassPoint(0, 8),
      );
      final support = episode.timeline.last.supportResult!;
      final lane = support.demonstratedPositiveLaneChange;
      expect(lane, isNotNull);
      expect(lane!.receiverRole, PressureActorRole.passer);
      expect(lane.usableBefore, isFalse);
      expect(lane.usableAfter, isTrue);
      final pass = engine
          .episodeOptions(episode)
          .firstWhere((option) => option.key == 'pass-recycle');
      episode = engine.chooseEpisodeOption(episode, pass);
      final later = episode.timeline.last.actionResult!;
      expect(later.before.carrier?.number, 10);
      expect(later.after.carrier?.number, 2);
      expect(later.after.carrier?.id, isNot(mover.id));
      expect(support.movementDistanceMetres, greaterThan(1.6));
      expect(support.continuation, isNull);
    });

    test(
        'standing still advances pressure time and earns no causal lane praise',
        () {
      final scenario = PressureLessonCatalog.build(seed: 19)[4];
      final episode = engine.startEpisode(scenario);
      final focus = episode.world.actorById(episode.pendingActorId!);
      final result = engine.simulateSupport(
        episode.world,
        focus.position,
        actorId: focus.id,
      );

      expect(result.afterMovement.clock - result.before.clock,
          greaterThanOrEqualTo(.24));
      expect(result.movementDistanceMetres, lessThan(.08));
      expect(result.continuation, isNull);
      expect(result.demonstratedPositiveLaneChange, isNull);
      expect(result.demonstratedNegativeLaneChange, isNull);
      expect(result.separationChangeMetres.abs(), lessThan(.01));
      expect(
          result.afterMovement.clock - result.before.clock,
          closeTo(result.stationaryCounterfactual.clock - result.before.clock,
              1e-8));
    });

    test('support separation credit uses the same-duration stationary mover',
        () {
      final episode =
          engine.startEpisode(PressureLessonCatalog.build(seed: 19)[4]);
      final mover = episode.world.actorById(episode.pendingActorId!);
      final moved = engine.simulateSupport(
        episode.world,
        mover.position + const ScanPassPoint(-4.5, -4.5),
        actorId: mover.id,
      );
      final stationary = engine.simulateSupport(
        episode.world,
        mover.position,
        actorId: mover.id,
      );

      expect(moved.afterMovement.clock, stationary.afterMovement.clock);
      expect(moved.separationChangeMetres, greaterThan(.35));
      expect(stationary.separationChangeMetres.abs(), lessThan(.01));
      expect(
        moved.stationaryCounterfactual.actorById(mover.id).position,
        mover.position,
      );
    });

    test('support target is physically bounded and can still lose to contact',
        () {
      final scenario = PressureLessonCatalog.build(seed: 19)[4];
      final episode = engine.startEpisode(scenario);
      final focus = episode.world.actorByRole(scenario.focusRole);
      final bounded = engine.simulateSupport(
        episode.world,
        focus.position + const ScanPassPoint(40, 30),
      );
      expect(focus.position.distanceTo(bounded.boundedTarget),
          lessThanOrEqualTo(8.01));
      expect(focus.position.distanceTo(bounded.boundedTarget),
          greaterThanOrEqualTo(7.99));
      expect(bounded.requestedTarget, isNot(bounded.boundedTarget));

      final carrier = episode.world.carrier!;
      final pressured = _moveRole(
        episode.world,
        PressureActorRole.presser,
        carrier.position + const ScanPassPoint(.3, .2),
        const ScanPassPoint(0, 0),
        reactivity: 1,
      );
      final lost = engine.simulateSupport(
        pressured,
        focus.position + const ScanPassPoint(-7, 0),
      );
      expect(lost.after.possession, PressurePossession.defense);
      expect(lost.contact, isNotNull);
    });

    test('nearest pressure follows the current ball owner after a recycle', () {
      final scenario = PressureLessonCatalog.build(seed: 19)[10];
      final episode = engine.startEpisode(scenario);
      final carrier = episode.world.carrier!;
      final changed = _moveRole(
        episode.world,
        PressureActorRole.tracker,
        carrier.position + const ScanPassPoint(.9, .2),
        const ScanPassPoint(-1, 0),
      );
      final context =
          engine.situationContext(changed, PressureDecisionStage.reRead);

      expect(context.carrierNumber, carrier.number);
      expect(context.presserNumber, 5);
      expect(context.pressureDistanceMetres, closeTo(.922, .01));
    });

    test('support context names the actual return-lane target', () {
      final scenario = PressureLessonCatalog.build(seed: 19)[4];
      final episode = engine.startEpisode(scenario);
      expect(episode.world.carrier?.role, PressureActorRole.support);
      final receiver = episode.world.actorByRole(PressureActorRole.receiver);
      final context =
          engine.situationContext(episode.world, PressureDecisionStage.support);

      expect(context.supportNumber, receiver.number);
      expect(context.supportNumber, isNot(episode.world.carrier!.number));
    });

    test('first-touch direction follows flank and is spatial on centre', () {
      final unseen = PressureLessonCatalog.build(seed: 19)[12];
      final central = engine.startEpisode(unseen);
      final centralKinds =
          engine.episodeOptions(central).map((option) => option.kind).toSet();
      expect(centralKinds, contains(PressureOptionKind.touchLeft));
      expect(centralKinds, contains(PressureOptionKind.touchRight));
      expect(centralKinds, isNot(contains(PressureOptionKind.touchInside)));

      var leftWorld = central.world;
      final receiver = leftWorld.actorByRole(PressureActorRole.receiver);
      leftWorld = _moveRole(
        leftWorld,
        PressureActorRole.receiver,
        ScanPassPoint(receiver.position.x, 52),
        receiver.velocity,
      ).copyWith(
        ball: PressureBall(
          position: ScanPassPoint(leftWorld.ball.position.x, 52),
          velocity: leftWorld.ball.velocity,
          carrierId: leftWorld.ball.carrierId,
        ),
      );
      final flank = engine.optionsFor(
        leftWorld,
        PressureDecisionStage.firstContact,
      );
      final inside = flank.firstWhere(
        (option) => option.kind == PressureOptionKind.touchInside,
      );
      final outside = flank.firstWhere(
        (option) => option.kind == PressureOptionKind.touchOutside,
      );
      expect(inside.action.target.y, lessThan(leftWorld.ball.position.y));
      expect(outside.action.target.y, greaterThan(leftWorld.ball.position.y));
    });

    test('suffix retry is exact and first-attempt metrics do not change', () {
      var episode =
          engine.startEpisode(PressureLessonCatalog.build(seed: 19).first);
      while (!episode.isComplete) {
        if (episode.pendingDecision == PressureEpisodeDecisionKind.support) {
          final focus = episode.world.actorByRole(episode.scenario.focusRole);
          episode = engine.chooseSupportTarget(
            episode,
            focus.position + const ScanPassPoint(4.5, 4),
          );
        } else {
          episode = _bestRetainedEpisodeChoice(engine, episode);
        }
      }
      final selected = episode.timeline[1];
      final retry = engine.retryFrom(episode, 1);
      expect(retry.world, same(selected.before));
      expect(retry.pendingDecision, selected.kind);
      expect(retry.timeline, hasLength(1));
      expect(retry.timeline.single, same(episode.timeline.first));

      final attempt = PressureEpisodeAttempt(
        situationIndex: 0,
        scenario: episode.scenario,
        timeline: episode.timeline,
        outcome: episode.outcome!,
      );
      var session = PressureEpisodeSession(
          situations: PressureLessonCatalog.build(seed: 19));
      session = session.recordFirstAttempt(attempt);
      session = session.recordFirstAttempt(PressureEpisodeAttempt(
        situationIndex: 0,
        scenario: episode.scenario,
        timeline: episode.timeline.reversed.toList(),
        outcome: PressureEpisodeOutcome.intercepted,
      ));
      expect(session.firstAttempts[0], same(attempt));
    });

    test('retry, alternatives and teaching example retain explicit actors', () {
      final scenario = PressureLessonCatalog.build(seed: 0)[8];
      var episode = engine.startEpisode(scenario);
      episode = engine.chooseEpisodeOption(
        episode,
        engine.episodeOptions(episode).firstWhere(
            (option) => option.targetRole == PressureActorRole.support),
      );
      final second = episode;
      final original = engine
          .chooseEpisodeOption(
            second,
            engine.episodeOptions(second).firstWhere(
                (option) => option.targetRole == PressureActorRole.runner),
          )
          .timeline
          .last;
      final alternative = engine.alternativeOption(
        original,
        original.availableOptions
            .firstWhere((option) => option.key != original.selectedOption!.key),
      );
      expect(alternative.before, same(original.before));
      expect(alternative.actorId, original.actorId);
      expect(alternative.actorNumber, 10);

      final completed = _completeEpisode(engine, second);
      final retry = engine.retryFrom(completed, 1);
      expect(retry.pendingActorId, completed.timeline[1].actorId);
      expect(retry.world, same(completed.timeline[1].before));
      expect(retry.runPlan, same(completed.timeline[1].runPlanBefore));

      final example = engine.teachingExample(scenario);
      expect(example.observation.decisionState.clock,
          engine.startEpisode(scenario).observation.decisionState.clock);
      expect(example.timeline.length, lessThanOrEqualTo(3));
      expect(example.timeline.first.actorNumber, 19);
      expect(example.trace.last, same(example.terminal));
      expect(example.outcome, isNotNull);
    });

    test('each guided teaching example is physical, bounded and defensible',
        () {
      for (final scenario in PressureLessonCatalog.build(seed: 19)
          .where((item) => item.variant == PressureLessonVariant.guided)) {
        final example = engine.teachingExample(scenario);
        expect(example.timeline, isNotEmpty, reason: scenario.id);
        expect(example.timeline.length, lessThanOrEqualTo(3),
            reason: scenario.id);
        expect(example.terminal.possession, PressurePossession.attack,
            reason: '${scenario.id} must not present an avoidable loss.');
        var replay = engine.startEpisode(scenario);
        for (final decision in example.timeline) {
          expect(replay.pendingActorId, decision.actorId, reason: scenario.id);
          replay = decision.supportResult == null
              ? engine.chooseEpisodeOption(replay, decision.selectedOption!)
              : engine.chooseSupportTarget(replay, decision.requestedTarget);
          expect(_physicalSignature(replay.timeline.last.after),
              _physicalSignature(decision.after),
              reason: scenario.id);
        }
        expect(_physicalSignature(replay.world),
            _physicalSignature(example.terminal),
            reason: scenario.id);

        final support = example.timeline
            .map((decision) => decision.supportResult)
            .whereType<PressureSupportResult>()
            .firstOrNull;
        if (support != null) {
          final supportIndex = example.timeline
              .indexWhere((decision) => decision.supportResult != null);
          final later = example.timeline
              .skip(supportIndex + 1)
              .map((decision) => decision.actionResult)
              .whereType<PressureSimulationResult>()
              .firstOrNull;
          final moverReceived =
              later?.after.possession == PressurePossession.attack &&
                  later?.after.carrier?.id == support.actorId;
          expect(
            support.demonstratedPositiveLaneChange != null ||
                support.separationChangeMetres >= .35 ||
                moverReceived,
            isTrue,
            reason: '${scenario.id} needs observable goal evidence.',
          );
        }
      }
    });

    test('catalog starts stay actionable across several seeds', () {
      for (final seed in [0, 1, 2, 3, 4, 5, 6, 7, 19, 41]) {
        for (final scenario in PressureLessonCatalog.build(seed: seed)) {
          final episode = engine.startEpisode(scenario);
          expect(episode.world.possession, PressurePossession.attack,
              reason: '$seed/${scenario.id}');
          if (episode.pendingDecision == PressureEpisodeDecisionKind.support) {
            final focus = episode.world.actorByRole(scenario.focusRole);
            final retained = [
              focus.position + const ScanPassPoint(4, -5),
              focus.position + const ScanPassPoint(4, 5),
              focus.position + const ScanPassPoint(-4, 4),
            ].any((target) =>
                engine
                    .simulateSupport(episode.world, target)
                    .after
                    .possession ==
                PressurePossession.attack);
            expect(retained, isTrue, reason: '$seed/${scenario.id}');
          } else {
            final retained = engine.episodeOptions(episode).any((option) =>
                engine
                    .simulate(episode.world, option.action)
                    .after
                    .possession ==
                PressurePossession.attack);
            expect(retained, isTrue, reason: '$seed/${scenario.id}');
          }
        }
      }
    });
  });
}

PressureEpisodeState _bestRetainedEpisodeChoice(
  ScanPassPressureEngine engine,
  PressureEpisodeState episode,
) {
  PressureEpisodeState? best;
  var bestScore = -double.infinity;
  for (final option in engine.episodeOptions(episode)) {
    final candidate = engine.chooseEpisodeOption(episode, option);
    final result = candidate.timeline.last.actionResult!;
    final score = (result.after.possession == PressurePossession.attack
            ? 1000.0
            : -1000.0) +
        result.assessment.actionProgressMetres * 5 +
        result.assessment.pressureClearanceMetres;
    if (score > bestScore) {
      best = candidate;
      bestScore = score;
    }
  }
  return best!;
}

PressureEpisodeState _completeEpisode(
  ScanPassPressureEngine engine,
  PressureEpisodeState episode,
) {
  var current = episode;
  while (!current.isComplete) {
    if (current.pendingDecision == PressureEpisodeDecisionKind.support) {
      final actor = current.world.actorById(current.pendingActorId!);
      current = engine.chooseSupportTarget(
        current,
        actor.position + const ScanPassPoint(5, 4),
      );
    } else {
      current = _bestRetainedEpisodeChoice(engine, current);
    }
  }
  return current;
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

String _actorConfiguration(PressureActor actor) => [
      actor.position.x.toStringAsFixed(6),
      actor.position.y.toStringAsFixed(6),
      actor.velocity.x.toStringAsFixed(6),
      actor.velocity.y.toStringAsFixed(6),
      actor.intentVelocity.x.toStringAsFixed(6),
      actor.intentVelocity.y.toStringAsFixed(6),
      actor.reactivity.toStringAsFixed(6),
    ].join('|');
