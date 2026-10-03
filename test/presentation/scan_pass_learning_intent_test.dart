import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart';
import 'package:football_note/presentation/screens/scan_pass_learning_intent.dart';

void main() {
  const engine = ScanPassMatchEngine();

  test('opening view hides local rear pressure but keeps the wider scene', () {
    final scenario = ScanPassScenarioLibrary.byId('rear-upper-protect');
    final time = scenario.ballTravelTime * 0.3;
    final receiver = scenario.receiver.at(time);
    final hidden = scenario.defendersAt(time).where(
          (defender) => ScanPassLearningSpace.needsRearCheck(
            defender.position,
            receiver,
          ),
        );
    expect(hidden.map((defender) => defender.id), [1]);
    expect(scenario.defenders.length - hidden.length, 2);
  });

  test('front-facing retreat scene does not hide visible front defenders', () {
    final scenario = ScanPassScenarioLibrary.byId('retreat-turn-chase');
    final time = scenario.ballTravelTime * 0.3;
    final receiver = scenario.receiver.at(time);
    expect(
      scenario.defendersAt(time).any(
            (defender) => ScanPassLearningSpace.needsRearCheck(
              defender.position,
              receiver,
            ),
          ),
      isFalse,
    );
  });

  test('a pass preview points to the chosen teammate even if it will be lost',
      () {
    final scenario = ScanPassScenarioLibrary.byId('return-wall-upper');
    final first = engine.applyFirstTouch(
      scenario,
      ScanPassFirstTouch.lowerTouch,
      decisionTime: Duration.zero,
    );
    final outcome = engine.evaluatePlan(
      scenario,
      first.action,
      ScanPassNextAction.passTo8,
      firstDecisionTime: Duration.zero,
      secondDecisionTime: Duration.zero,
    );
    expect(outcome.outcome, ScanPassOutcomeType.intercepted);

    final intent = ScanPassLearningIntent.nextAction(
      first,
      ScanPassNextAction.passTo8,
    ).single;
    final teammate = scenario.support.at(first.completedAt).position;
    expect(intent.to.distanceTo(teammate), lessThan(0.0001));
    expect(intent.to.distanceTo(outcome.interceptionPoint!), greaterThan(0.02));
  });

  test('return preview reaches number four without revealing interception', () {
    final first = ScanPassScenarioLibrary.scenarios
        .map((scenario) => engine.applyFirstTouch(
              scenario,
              ScanPassFirstTouch.returnTo4,
              decisionTime: Duration.zero,
            ))
        .firstWhere((state) => state.returnIntercepted);
    final intent = ScanPassLearningIntent.firstTouch(first);
    final teammate =
        first.scenario.centerBack.at(first.touchStartTime).position;
    expect(intent.to.distanceTo(teammate), lessThan(0.0001));
    expect(intent.to.distanceTo(first.returnInterceptionPoint!),
        greaterThan(0.02));
  });

  test('off-ball preview shows the run, without revealing the following pass',
      () {
    final scenario = ScanPassScenarioLibrary.byId('return-wall-upper');
    final first = engine.applyFirstTouch(
      scenario,
      ScanPassFirstTouch.returnTo4,
      decisionTime: Duration.zero,
    );
    expect(first.ballLost, isFalse);
    final outcome = engine.evaluatePlan(
      scenario,
      first.action,
      ScanPassNextAction.supportForward,
      firstDecisionTime: Duration.zero,
      secondDecisionTime: Duration.zero,
    );
    expect(outcome.outcome, ScanPassOutcomeType.intercepted);
    final intentions = ScanPassLearningIntent.nextAction(
      first,
      ScanPassNextAction.supportForward,
    );
    expect(intentions, hasLength(1));
    expect(intentions.single.type, ScanPassPathType.offBallRun);
    expect(intentions.single.to.x, greaterThan(first.receiverPosition.x));
    expect(intentions.single.to.distanceTo(outcome.interceptionPoint!),
        greaterThan(0.02));
  });
}
