import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart';

void main() {
  const engine = ScanPassMatchEngine();

  test('world keeps advancing while deciding after a completed touch', () {
    final scenario = ScanPassScenarioLibrary.byId('rear-lower-protect');
    final first = engine.applyFirstTouch(
      scenario,
      ScanPassFirstTouch.upperTouch,
      decisionTime: Duration.zero,
    );
    final time = first.completedAt + 0.7;
    final snapshot = ScanPassTimeline.snapshot(
      scenario: scenario,
      firstTouchState: first,
      time: time,
    );

    expect(snapshot.time, closeTo(time, 0.00001));
    for (var i = 0; i < scenario.defenders.length; i++) {
      expect(
        snapshot.defenders[i].position.distanceTo(
          scenario.defenders[i].at(time).position,
        ),
        closeTo(0, 0.00001),
      );
    }
    expect(
      snapshot.attacker(ScanPassPlayerRole.midfielder6).position.distanceTo(
            first.receiverPosition,
          ),
      closeTo(0, 0.00001),
    );
  });

  test('holding the pocket after a return leaves the ball with moving #4', () {
    final scenario = _openReturnScenario();
    final result = engine.evaluatePlan(
      scenario,
      ScanPassFirstTouch.returnTo4,
      ScanPassNextAction.holdPocket,
      firstDecisionTime: Duration.zero,
      secondDecisionTime: const Duration(milliseconds: 300),
    );
    expect(result.firstTouchState.returnIntercepted, isFalse);
    final hold = result.pathSegments.singleWhere(
      (segment) => segment.type == ScanPassPathType.hold,
    );
    final time = (hold.startTime + hold.endTime) / 2;
    final snapshot = ScanPassTimeline.snapshot(
      scenario: scenario,
      result: result,
      time: time,
    );

    expect(snapshot.ballHolder, ScanPassPlayerRole.centerBack4);
    expect(
      snapshot.ball.distanceTo(scenario.centerBack.at(time).position),
      closeTo(0, 0.00001),
    );
    expect(
      snapshot.ball.distanceTo(
        snapshot.attacker(ScanPassPlayerRole.midfielder6).position,
      ),
      greaterThan(0.1),
    );
  });

  test('a return in flight has no teammate holding the ball', () {
    final scenario = _openReturnScenario();
    final first = engine.applyFirstTouch(
      scenario,
      ScanPassFirstTouch.returnTo4,
      decisionTime: Duration.zero,
    );
    final snapshot = ScanPassTimeline.snapshot(
      scenario: scenario,
      firstTouchState: first,
      time: (first.touchStartTime + first.completedAt) / 2,
    );

    expect(snapshot.ballHolder, isNull);
    expect(snapshot.ballLost, isFalse);
  });
}

ScanPassScenario _openReturnScenario() {
  final source = ScanPassScenarioLibrary.byId('return-wall-upper');
  return ScanPassScenario(
    roundNumber: 1,
    id: 'timeline-open-return',
    family: source.family,
    region: source.region,
    objective: source.objective,
    matchClockLabel: source.matchClockLabel,
    scoreLabel: source.scoreLabel,
    centerBack: source.centerBack.copyWith(
      velocity: const ScanPassPoint(0.012, -0.006),
    ),
    receiver: source.receiver,
    support: source.support,
    forward: source.forward,
    defenders: const <ScanPassDefender>[
      ScanPassDefender(id: 1, position: ScanPassPoint(0.86, 0.12)),
      ScanPassDefender(id: 2, position: ScanPassPoint(0.92, 0.83)),
      ScanPassDefender(id: 3, position: ScanPassPoint(0.60, 0.89)),
    ],
  );
}
