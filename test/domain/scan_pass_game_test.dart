import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart';

void main() {
  const engine = ScanPassMatchEngine();

  group('ScanPassScenarioLibrary', () {
    test('defines purposeful 4v3 scenarios and deterministic sessions', () {
      expect(ScanPassScenarioLibrary.scenarios,
          hasLength(greaterThanOrEqualTo(12)));

      final first = const ScanPassScenarioLibrary(seed: 42).generateSession();
      final second = const ScanPassScenarioLibrary(seed: 42).generateSession();
      final different =
          const ScanPassScenarioLibrary(seed: 43).generateSession();

      expect(_sessionSignature(first), _sessionSignature(second));
      expect(_sessionSignature(first), isNot(_sessionSignature(different)));
      expect(first, hasLength(ScanPassScenarioLibrary.roundCount));
      expect(first.map((scenario) => scenario.id).toSet(), hasLength(10));
      expect(first.map((scenario) => scenario.family).toSet().length,
          greaterThanOrEqualTo(4));

      for (final scenario in first) {
        expect(scenario.attackersAt(0), hasLength(4));
        expect(scenario.defenders, hasLength(3));
        expect(
          scenario.attackersAt(0).map((player) => player.number),
          containsAll(<int>[4, 6, 8, 9]),
        );
        for (final point in <ScanPassPoint>[
          ...scenario.attackersAt(0).map((player) => player.position),
          ...scenario.defenders.map((defender) => defender.position),
          ...scenario.defendersAt(1.4).map((defender) => defender.position),
        ]) {
          expect(point.x, inInclusiveRange(0.07, 0.93));
          expect(point.y, inInclusiveRange(0.08, 0.92));
        }
      }
    });

    test('paired scenario keeps the start shape but changes defender motion',
        () {
      final closing = ScanPassScenarioLibrary.byId('forward-lane-closing');
      final retreating =
          ScanPassScenarioLibrary.byId('forward-lane-retreating');

      expect(_startShape(closing), _startShape(retreating));
      expect(_velocityShape(closing), isNot(_velocityShape(retreating)));

      final closingBest = engine.evaluateAlternatives(closing).bestPlan;
      final retreatingBest = engine.evaluateAlternatives(retreating).bestPlan;

      expect(closingBest.nextAction, isNot(ScanPassNextAction.passTo9));
      expect(retreatingBest.nextAction, ScanPassNextAction.passTo9);
      expect(retreatingBest.totalScore, greaterThan(closingBest.totalScore));
    });
  });

  group('ScanPassMatchEngine', () {
    test('first touch changes position holder orientation and elapsed state',
        () {
      final scenario = ScanPassScenarioLibrary.byId('rear-lower-protect');
      final upper =
          engine.applyFirstTouch(scenario, ScanPassFirstTouch.upperTouch);
      final lower =
          engine.applyFirstTouch(scenario, ScanPassFirstTouch.lowerTouch);
      final turn =
          engine.applyFirstTouch(scenario, ScanPassFirstTouch.turnForward);
      final returned =
          engine.applyFirstTouch(scenario, ScanPassFirstTouch.returnTo4);

      expect(upper.receiverPosition.y, lessThan(upper.startPosition.y));
      expect(lower.receiverPosition.y, greaterThan(lower.startPosition.y));
      expect(turn.receiverFacingRadians, closeTo(0, 0.001));
      expect(turn.completedAt, greaterThan(upper.completedAt));
      expect(returned.ballHolder, ScanPassPlayerRole.centerBack4);
      expect(returned.ballPosition.x, lessThan(returned.receiverPosition.x));
    });

    test('pressure side and retreating pressure change preferred choices', () {
      final lowerPressure = ScanPassScenarioLibrary.byId('rear-lower-protect');
      final upperSupport = engine.evaluatePlan(
        lowerPressure,
        ScanPassFirstTouch.upperTouch,
        ScanPassNextAction.passTo8,
      );
      final lowerSupport = engine.evaluatePlan(
        lowerPressure,
        ScanPassFirstTouch.lowerTouch,
        ScanPassNextAction.passTo8,
      );

      expect(upperSupport.totalScore, greaterThan(lowerSupport.totalScore));

      final retreat = ScanPassScenarioLibrary.byId('retreat-turn-chase');
      final ranked = List<ScanPassPlanResult>.from(
          engine.evaluateAlternatives(retreat).alternatives)
        ..sort((a, b) => b.totalScore.compareTo(a.totalScore));
      final turnForwardPass = ranked.firstWhere(
        (plan) =>
            plan.firstTouch == ScanPassFirstTouch.turnForward &&
            plan.nextAction == ScanPassNextAction.passTo9,
      );

      expect(turnForwardPass.outcome, ScanPassOutcomeType.progressed);
      expect(
        ranked.take(3).map((plan) => plan.planId),
        contains(turnForwardPass.planId),
      );
      expect(
        ranked.first.totalScore - turnForwardPass.totalScore,
        lessThanOrEqualTo(2),
      );

      final closePressure = ScanPassScenarioLibrary.byId('rear-upper-chase');
      final closeTurn = engine.evaluatePlan(
        closePressure,
        ScanPassFirstTouch.turnForward,
        ScanPassNextAction.passTo9,
      );
      expect(closeTurn.totalScore, lessThan(turnForwardPass.totalScore - 12));
    });

    test(
        'interception changes ball path and score compared with a controlled plan',
        () {
      final scenario = ScanPassScenarioLibrary.byId('retreat-turn-chase');
      final intercepted = engine.evaluatePlan(
        scenario,
        ScanPassFirstTouch.upperTouch,
        ScanPassNextAction.passTo9,
      );
      final controlled = engine.evaluatePlan(
        scenario,
        ScanPassFirstTouch.turnForward,
        ScanPassNextAction.passTo9,
      );

      expect(intercepted.outcome, ScanPassOutcomeType.intercepted);
      expect(intercepted.interceptionPoint, isNotNull);
      expect(intercepted.pathSegments.last.contested, isTrue);
      expect(intercepted.finalBallPosition.x,
          lessThan(controlled.finalBallPosition.x));
      expect(controlled.outcome, ScanPassOutcomeType.progressed);
      expect(controlled.totalScore, greaterThan(intercepted.totalScore + 25));
    });

    test('pass timing can make a brief hold outperform immediate release', () {
      final scenario = ScanPassScenarioLibrary.byId('central-hold-window');
      final immediate = engine.evaluatePlan(
        scenario,
        ScanPassFirstTouch.lowerTouch,
        ScanPassNextAction.passTo8,
      );
      final held = engine.evaluatePlan(
        scenario,
        ScanPassFirstTouch.lowerTouch,
        ScanPassNextAction.holdPassTo8,
      );

      expect(held.totalScore, greaterThan(immediate.totalScore));
      expect(held.finalTime, greaterThan(immediate.finalTime));
      expect(
          held.pathSegments
              .any((segment) => segment.type == ScanPassPathType.hold),
          isTrue);
    });

    test('return and move changes the next receiving angle', () {
      final scenario = ScanPassScenarioLibrary.byId('return-wall-upper');
      final upperSupport = engine.evaluatePlan(
        scenario,
        ScanPassFirstTouch.returnTo4,
        ScanPassNextAction.supportUpper,
      );
      final holdPocket = engine.evaluatePlan(
        scenario,
        ScanPassFirstTouch.returnTo4,
        ScanPassNextAction.holdPocket,
      );

      final upperRun = upperSupport.pathSegments.firstWhere(
        (segment) => segment.type == ScanPassPathType.offBallRun,
      );

      expect(upperRun.to.y,
          lessThan(holdPocket.firstTouchState.receiverPosition.y));
      expect(upperSupport.finalReceiverRole, ScanPassPlayerRole.midfielder6);
      expect(upperSupport.finalBallPosition.y,
          lessThan(holdPocket.finalBallPosition.y));
      expect(
        upperSupport.pathSegments.map((segment) => segment.type),
        contains(ScanPassPathType.offBallRun),
      );
      expect(upperSupport.finalBallPosition.x,
          isNot(holdPocket.finalBallPosition.x));
    });

    test('return pass can be intercepted before an off-ball move starts', () {
      final base = ScanPassScenarioLibrary.byId('return-wall-upper');
      final blocked = ScanPassScenario(
        roundNumber: 1,
        id: 'blocked-return-probe',
        family: base.family,
        region: base.region,
        objective: base.objective,
        matchClockLabel: base.matchClockLabel,
        scoreLabel: base.scoreLabel,
        centerBack: base.centerBack,
        receiver: base.receiver,
        support: base.support,
        forward: base.forward,
        defenders: const <ScanPassDefender>[
          ScanPassDefender(id: 1, position: ScanPassPoint(0.31, 0.60)),
          ScanPassDefender(id: 2, position: ScanPassPoint(0.72, 0.22)),
          ScanPassDefender(id: 3, position: ScanPassPoint(0.72, 0.78)),
        ],
      );

      final result = engine.evaluatePlan(
        blocked,
        ScanPassFirstTouch.returnTo4,
        ScanPassNextAction.supportUpper,
        firstDecisionTime: Duration.zero,
        secondDecisionTime: Duration.zero,
      );

      expect(result.outcome, ScanPassOutcomeType.intercepted);
      expect(result.finalReceiverRole, isNull);
      expect(result.interceptionPoint, isNotNull);
      expect(
        result.pathSegments.map((segment) => segment.type),
        isNot(contains(ScanPassPathType.offBallRun)),
      );
    });

    test('timeline snapshots keep ball and actors consistent with paths', () {
      final scenario = ScanPassScenarioLibrary.byId('return-wall-upper');
      final returnPlan = engine.evaluatePlan(
        scenario,
        ScanPassFirstTouch.returnTo4,
        ScanPassNextAction.supportUpper,
        firstDecisionTime: Duration.zero,
        secondDecisionTime: Duration.zero,
      );
      final run = returnPlan.pathSegments.firstWhere(
        (segment) => segment.type == ScanPassPathType.offBallRun,
      );
      final midRun = ScanPassTimeline.snapshot(
        scenario: scenario,
        time: (run.startTime + run.endTime) / 2,
        result: returnPlan,
      );
      expect(
        midRun.ball.distanceTo(scenario.centerBack.at(midRun.time).position),
        lessThan(0.001),
      );

      final finalSnapshot = ScanPassTimeline.snapshot(
        scenario: scenario,
        time: returnPlan.finalTime,
        result: returnPlan,
      );
      expect(
        finalSnapshot.ball.distanceTo(
          finalSnapshot.attacker(ScanPassPlayerRole.midfielder6).position,
        ),
        lessThan(0.001),
      );

      final forwardPlan = engine.evaluatePlan(
        ScanPassScenarioLibrary.byId('retreat-turn-chase'),
        ScanPassFirstTouch.turnForward,
        ScanPassNextAction.passTo9,
      );
      final forwardSnapshot = ScanPassTimeline.snapshot(
        scenario: forwardPlan.scenario,
        time: forwardPlan.finalTime,
        result: forwardPlan,
      );
      expect(
        forwardSnapshot.ball.distanceTo(
          forwardSnapshot.attacker(ScanPassPlayerRole.forward9).position,
        ),
        lessThan(0.001),
      );
    });

    test('score components sum to bounded totals', () {
      final result = engine
          .evaluateAlternatives(
            ScanPassScenarioLibrary.byId('retreat-turn-chase'),
          )
          .bestPlan;

      expect(result.totalScore, inInclusiveRange(0, 100));
      expect(
          result.components
              .map((component) => component.max)
              .fold<int>(0, (a, b) => a + b),
          100);
      expect(
          result.components
              .map((component) => component.earned)
              .fold<int>(0, (a, b) => a + b),
          result.totalScore);
      for (final component in result.components) {
        expect(component.earned, inInclusiveRange(0, component.max));
        expect(component.raw, inInclusiveRange(0, 100));
      }
    });

    test('alternative evaluation uses the same initial state and timings', () {
      const firstTime = Duration(milliseconds: 1200);
      const secondTime = Duration(milliseconds: 700);
      final scenario = ScanPassScenarioLibrary.byId('forward-lane-retreating');
      final evaluation = engine.evaluateAlternatives(
        scenario,
        selectedFirstTouch: ScanPassFirstTouch.lowerTouch,
        selectedNextAction: ScanPassNextAction.passTo9,
        firstDecisionTime: firstTime,
        secondDecisionTime: secondTime,
      );

      expect(evaluation.selected, isNotNull);
      expect(evaluation.alternatives, hasLength(15));
      for (final plan in evaluation.alternatives) {
        expect(plan.scenario.id, scenario.id);
        expect(plan.firstDecisionTime, firstTime);
        expect(plan.secondDecisionTime, secondTime);
      }
      expect(evaluation.strongAlternativeFor(evaluation.selected)?.planId,
          isNot(evaluation.selected!.planId));
    });
  });

  group('ScanPassChoiceClock and history summaries', () {
    test('choice clock caps remaining and response times', () {
      final startedAt = DateTime(2026, 1, 1, 12);
      const window = Duration(milliseconds: 3200);
      final clock = ScanPassChoiceClock(
        startedAt: startedAt,
        choiceWindow: window,
      );

      expect(
        clock.remainingAt(startedAt.add(const Duration(milliseconds: 900))),
        const Duration(milliseconds: 2300),
      );
      expect(
        clock.responseTimeAt(startedAt.add(const Duration(seconds: 5))),
        window,
      );
      expect(clock.isExpiredAt(startedAt.add(window)), isTrue);
    });

    test('aggregates match decision results and records v2 personal bests', () {
      final summary = ScanPassSessionSummary.fromResults(
        const <ScanPassRoundResult>[
          ScanPassRoundResult(
            roundNumber: 1,
            scenarioId: 'a',
            planId: 'turnForward.passTo9',
            chosenScore: 84,
            bestScore: 84,
            decisionTime: Duration(milliseconds: 1700),
            pressureEarned: 12,
            pressureMax: 22,
            continuationEarned: 21,
            continuationMax: 24,
          ),
          ScanPassRoundResult(
            roundNumber: 2,
            scenarioId: 'b',
            planId: 'lowerTouch.passTo4',
            chosenScore: 70,
            bestScore: 82,
            decisionTime: Duration(milliseconds: 2100),
            pressureEarned: 18,
            pressureMax: 22,
            continuationEarned: 12,
            continuationMax: 24,
          ),
          ScanPassRoundResult(
            roundNumber: 3,
            scenarioId: 'c',
            planId: null,
            chosenScore: 0,
            bestScore: 88,
            decisionTime: Duration(milliseconds: 3200),
            pressureEarned: 0,
            pressureMax: 22,
            continuationEarned: 0,
            continuationMax: 24,
            timedOut: true,
            timeoutPhase: ScanPassTimeoutPhase.nextAction,
          ),
        ],
      );

      expect(summary.roundsPlayed, 3);
      expect(summary.completedRounds, 2);
      expect(summary.timeouts, 1);
      expect(summary.averageScore, closeTo(51.3, 0.1));
      expect(summary.decisionAccuracyPercent, closeTo(61.8, 0.1));
      expect(summary.pressureHandlingPercent, closeTo(45.5, 0.1));
      expect(summary.continuationPercent, closeTo(45.8, 0.1));

      final personal = const ScanPassPersonalSummary.empty()
          .recordSession(summary, updatedAt: DateTime(2026, 1, 1));
      expect(personal.sessionsPlayed, 1);
      expect(personal.bestAverageScore, summary.averageScore);
      expect(personal.bestPressureHandlingPercent,
          summary.pressureHandlingPercent);
      expect(ScanPassPersonalSummary.fromJson(personal.toJson()).sessionsPlayed,
          1);
    });
  });
}

String _sessionSignature(List<ScanPassScenario> scenarios) {
  return scenarios
      .map(
        (scenario) => [
          scenario.roundNumber,
          scenario.id,
          scenario.objective.name,
          ...scenario.attackersAt(0).map((player) => _point(player.position)),
          ...scenario.defenders.map((defender) => _point(defender.position)),
          ...scenario.defenders.map((defender) => _point(defender.velocity)),
        ].join('|'),
      )
      .join('\n');
}

String _startShape(ScanPassScenario scenario) {
  return [
    ...scenario.attackersAt(0).map((player) => _point(player.position)),
    ...scenario.defenders.map((defender) => _point(defender.position)),
  ].join('|');
}

String _velocityShape(ScanPassScenario scenario) {
  return scenario.defenders
      .map((defender) => _point(defender.velocity))
      .join('|');
}

String _point(ScanPassPoint point) {
  return '${point.x.toStringAsFixed(3)},${point.y.toStringAsFixed(3)}';
}
