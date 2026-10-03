import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/domain/scan_pass/scan_pass_decision.dart';

void main() {
  const engine = DecisionEngine();

  group('paired situation recognition', () {
    test('each pair starts identically and changes only its cue actor', () {
      for (final lesson in DecisionLesson.values) {
        for (var variation = 0; variation < 6; variation++) {
          final original = engine.scenario(lesson, variation: variation);
          final changed =
              engine.scenario(lesson, changed: true, variation: variation);
          expect(_signature(original.initial), _signature(changed.initial));
          expect(original.cueFrom.distanceTo(changed.cueFrom), 0);
          expect(original.cueTo.distanceTo(changed.cueTo), greaterThan(.05));
          for (final opponents in [false, true]) {
            final first = opponents
                ? original.reception.defenders
                : original.reception.attackers;
            final second = opponents
                ? changed.reception.defenders
                : changed.reception.attackers;
            for (var index = 0; index < first.length; index++) {
              if (opponents == original.cueIsOpponent &&
                  first[index].number == original.cueNumber) {
                continue;
              }
              expect(_player(first[index]), _player(second[index]),
                  reason: 'Unrelated actors cannot reveal a different scene.');
            }
          }
        }
      }
    });

    test('rear pressure changes whether turning with the ball is viable', () {
      final pressure = engine.assess(
          engine.scenario(DecisionLesson.rearPressure), DecisionAction.carry);
      final space = engine.assess(
          engine.scenario(DecisionLesson.rearPressure, changed: true),
          DecisionAction.carry);
      expect(pressure.quality, DecisionQuality.lost);
      expect(pressure.reason, DecisionReason.pressureArriving);
      expect(space.quality, DecisionQuality.advantage);
      expect(space.passCompleted, isFalse,
          reason: 'A successful carry is not a completed pass.');
      expect(space.progressed, isTrue);
    });

    test('a visible unmarked player can still be behind a blocked lane', () {
      final covered = engine.assess(
          engine.scenario(DecisionLesson.passingLane), DecisionAction.forward);
      final open = engine.assess(
          engine.scenario(DecisionLesson.passingLane, changed: true),
          DecisionAction.forward);
      expect(covered.quality, DecisionQuality.lost);
      expect(covered.laneOpen, isFalse);
      expect(covered.reason, DecisionReason.laneBlocked);
      expect(covered.received.end, AttackEnd.intercepted);
      expect(open.passCompleted, isTrue);
      expect(open.quality, DecisionQuality.advantage);
    });

    test('identical completed passes have different next-action value', () {
      final supported = engine.assess(
          engine.scenario(DecisionLesson.receiverSupport),
          DecisionAction.forward);
      final isolated = engine.assess(
          engine.scenario(DecisionLesson.receiverSupport, changed: true),
          DecisionAction.forward);
      expect(supported.passCompleted, isTrue);
      expect(isolated.passCompleted, isTrue);
      expect(supported.receiverHasTime, isFalse);
      expect(isolated.receiverHasTime, isFalse);
      expect(supported.availableOutlets, contains(10));
      expect(isolated.availableOutlets, isEmpty);
      expect(supported.quality, DecisionQuality.advantage);
      expect(supported.reason, DecisionReason.thirdPlayerAvailable);
      expect(isolated.quality, DecisionQuality.difficult);
      expect(isolated.reason, DecisionReason.receiverTrapped);
      expect(supported.after.carrierNumber, 10);
      expect(isolated.after.carrierNumber, 8);
      expect(isolated.after.end, isNull,
          reason: 'Isolation is not a fabricated interception.');
    });

    test('several useful options coexist across mirrored and shifted sets', () {
      for (final lesson in DecisionLesson.values) {
        for (final changed in [false, true]) {
          final baseline =
              engine.alternatives(engine.scenario(lesson, changed: changed));
          for (var variation = 0; variation < 12; variation++) {
            final outcomes = engine.alternatives(engine.scenario(lesson,
                changed: changed, variation: variation));
            expect(
                outcomes.where((a) =>
                    a.quality == DecisionQuality.advantage ||
                    a.quality == DecisionQuality.secure),
                hasLength(greaterThanOrEqualTo(2)));
            expect(
                outcomes.map((a) => a.quality), baseline.map((a) => a.quality),
                reason: '$lesson $changed variation $variation');
            expect(
                outcomes.map((a) => a.reason), baseline.map((a) => a.reason));
          }
        }
      }
    });
  });

  group('time, continuation and fair comparison', () {
    test('opponent motion changes the value of a delayed action', () {
      final scene = engine.scenario(DecisionLesson.passingLane, changed: true);
      final early = engine.assess(scene, DecisionAction.carry);
      final late = engine.assess(scene, DecisionAction.carry, delaySeconds: .8);
      expect(early.quality, DecisionQuality.advantage);
      expect(late.quality, DecisionQuality.lost);
      expect(early.before.ball.distanceTo(late.before.ball), 0);
      expect(
          early.before.defenders.first.position
              .distanceTo(late.before.defenders.first.position),
          greaterThan(.025));
      final later =
          engine.assess(scene, DecisionAction.carry, delaySeconds: 2.8);
      expect(later.quality, DecisionQuality.lost,
          reason: 'The presser must not run through and away from the ball.');
    });

    test('observation joins the actual decision state without teleporting', () {
      for (final lesson in DecisionLesson.values) {
        for (final changed in [false, true]) {
          final scene = engine.scenario(lesson, changed: changed);
          expect(
              _signature(scene.observationFrame(0)), _signature(scene.initial));
          expect(_signature(scene.observationFrame(1)),
              _signature(scene.decisionState(0)));
          expect(scene.observationFrame(.5).ball.distanceTo(scene.initial.ball),
              greaterThan(0));
          expect(scene.observationFrame(.5).carrierNumber, 4);
          expect(scene.reception.carrierNumber, 6);
        }
      }
    });

    test('replay and alternatives preserve the choice and use the same time',
        () {
      final scene = engine.scenario(DecisionLesson.receiverSupport);
      final chosen =
          engine.assess(scene, DecisionAction.forward, delaySeconds: .3);
      final original = _signature(chosen.after);
      final sceneBefore = _signature(scene.reception);
      for (final comparison in engine.alternatives(scene, delaySeconds: .3)) {
        expect(_signature(comparison.before), _signature(chosen.before));
        for (var i = 0; i <= 10; i++) {
          comparison.frame(i / 10);
        }
      }
      expect(_signature(chosen.after), original);
      expect(_signature(scene.reception), sceneBefore);
      expect(() => chosen.transitions.clear(), throwsUnsupportedError);
      expect(() => chosen.availableOutlets.add(99), throwsUnsupportedError);
      expect(_signature(chosen.frame(0)), _signature(chosen.before));
      expect(_signature(chosen.frame(1)), original);
    });

    test('every illustrated follow-up starts where the prior action ended', () {
      for (final lesson in DecisionLesson.values) {
        for (final changed in [false, true]) {
          for (final result in engine
              .alternatives(engine.scenario(lesson, changed: changed))) {
            expect(result.transitions.first.before, same(result.before));
            expect(result.transitions.first.after, same(result.received));
            expect(result.transitions.last.after, same(result.after));
            for (var i = 1; i < result.transitions.length; i++) {
              expect(result.transitions[i].before,
                  same(result.transitions[i - 1].after));
            }
            if (result.quality == DecisionQuality.advantage ||
                result.quality == DecisionQuality.secure) {
              expect(result.after.finished, isFalse,
                  reason: 'The illustrated continuation cannot contradict '
                      'the teaching assessment.');
            }
            expect(result.after.end, isNot(AttackEnd.goal));
          }
        }
      }
    });

    test('assessment follows geometry rather than the scenario variant label',
        () {
      final covered = engine.scenario(DecisionLesson.passingLane);
      final open = engine.scenario(DecisionLesson.passingLane, changed: true);
      final relabeled = DecisionScenario(
          lesson: covered.lesson,
          changed: false,
          variation: covered.variation,
          initial: covered.initial,
          reception: open.reception,
          cueNumber: covered.cueNumber,
          cueIsOpponent: covered.cueIsOpponent);
      expect(engine.assess(relabeled, DecisionAction.forward).quality,
          DecisionQuality.advantage);
    });

    test('negative or non-finite delay cannot corrupt positions', () {
      final scene = engine.scenario(DecisionLesson.rearPressure);
      for (final delay in [-5.0, double.nan, double.infinity]) {
        expect(_signature(scene.decisionState(delay)),
            _signature(scene.decisionState(0)));
      }
    });
  });
}

List<Object> _player(AttackPlayer player) => [
      player.number,
      player.position.x,
      player.position.y,
      player.facingRadians,
      player.velocity.x,
      player.velocity.y,
    ];

List<Object?> _signature(AttackState state) => [
      state.ball.x,
      state.ball.y,
      state.carrierNumber,
      state.elapsed,
      state.end,
      for (final player in state.attackers) _player(player),
      for (final player in state.defenders) _player(player),
    ];
