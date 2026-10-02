import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart';

void main() {
  const scorer = ScanPassScorer();

  group('ScanPassRoundGenerator', () {
    test('generates deterministic 10-round sessions for a seed', () {
      const first = ScanPassRoundGenerator(seed: 42);
      const second = ScanPassRoundGenerator(seed: 42);
      const different = ScanPassRoundGenerator(seed: 43);

      expect(
        _sessionSignature(first.generateSession()),
        _sessionSignature(second.generateSession()),
      );
      expect(
        _sessionSignature(first.generateSession()),
        isNot(_sessionSignature(different.generateSession())),
      );
    });

    test('keeps players in bounds and creates useful route spread', () {
      final rounds = const ScanPassRoundGenerator(seed: 98).generateSession();

      expect(rounds, hasLength(10));
      expect(
        rounds.take(3).map((round) => round.occlusionMode),
        everyElement(ScanPassOcclusionMode.silhouettes),
      );
      expect(
        rounds.skip(3).take(4).map((round) => round.occlusionMode),
        everyElement(ScanPassOcclusionMode.hidden),
      );
      expect(
        rounds.skip(7).map((round) => round.occlusionMode),
        everyElement(ScanPassOcclusionMode.prediction),
      );

      for (final round in rounds) {
        expect(round.teammates, hasLength(3));
        expect(round.defenders, hasLength(2));
        final points = <ScanPassPoint>[
          round.ballCarrier.position,
          ...round.teammates.map((player) => player.position),
          ...round.defenders.map((defender) => defender.position),
          ...round.defenders.map((defender) => defender.predictedPosition()),
        ];
        for (final point in points) {
          expect(point.x, inInclusiveRange(0.07, 0.93));
          expect(point.y, inInclusiveRange(0.08, 0.92));
        }
        final scores = scorer
            .evaluateRound(round)
            .routes
            .map((route) => route.totalScore)
            .toList()
          ..sort();
        expect(scores.last, greaterThanOrEqualTo(58));
        expect(scores.last - scores.first, greaterThanOrEqualTo(12));
      }
    });
  });

  group('ScanPassScorer', () {
    test('lane component rewards clear passing lanes', () {
      final clear = _singleRouteRound(
        defender: const ScanPassPoint(0.52, 0.78),
      );
      final blocked = _singleRouteRound(
        defender: const ScanPassPoint(0.52, 0.50),
      );

      final clearScore = scorer.evaluateRound(clear).routes.single;
      final blockedScore = scorer.evaluateRound(blocked).routes.single;

      expect(clearScore.laneSafety, greaterThan(blockedScore.laneSafety + 45));
      expect(clearScore.totalScore, greaterThan(blockedScore.totalScore));
    });

    test('scores stay clamped and reaction can add at most 10 points', () {
      final safeRound = _singleRouteRound(
        defender: const ScanPassPoint(0.48, 0.82),
      );
      final fast = scorer
          .evaluateRound(
            safeRound,
            responseTime: const Duration(milliseconds: 300),
          )
          .routes
          .single;
      final slow = scorer
          .evaluateRound(
            safeRound,
            responseTime: ScanPassScorer.defaultChoiceWindow,
          )
          .routes
          .single;

      expect(fast.totalScore, inInclusiveRange(0, 100));
      expect(slow.totalScore, inInclusiveRange(0, 100));
      expect(fast.totalScore - slow.totalScore, lessThanOrEqualTo(10));
      expect(fast.reactionBonus, lessThanOrEqualTo(10));

      final blocked = scorer
          .evaluateRound(
            _singleRouteRound(defender: const ScanPassPoint(0.52, 0.50)),
            responseTime: const Duration(milliseconds: 300),
          )
          .routes
          .single;
      expect(blocked.decisionScore, lessThan(50));
      expect(blocked.reactionBonus, 0);
    });

    test('treats close high scores as comparable route choices', () {
      final round = _singleRouteRound();
      final evaluation = ScanPassRoundEvaluation(
        round: round,
        routes: const <ScanPassRouteScore>[
          ScanPassRouteScore(
            targetId: 1,
            targetNumber: 9,
            laneSafety: 88,
            arrivalMargin: 82,
            receiverSpace: 76,
            progression: 70,
            simulatedResult: 84,
            decisionScore: 78,
            reactionBonus: 7,
            totalScore: 85,
            feedbackType: ScanPassRouteFeedbackType.clearLane,
          ),
          ScanPassRouteScore(
            targetId: 2,
            targetNumber: 10,
            laneSafety: 82,
            arrivalMargin: 80,
            receiverSpace: 78,
            progression: 72,
            simulatedResult: 81,
            decisionScore: 75,
            reactionBonus: 5,
            totalScore: 80,
            feedbackType: ScanPassRouteFeedbackType.openSpace,
          ),
          ScanPassRouteScore(
            targetId: 3,
            targetNumber: 11,
            laneSafety: 45,
            arrivalMargin: 46,
            receiverSpace: 60,
            progression: 68,
            simulatedResult: 48,
            decisionScore: 48,
            reactionBonus: 0,
            totalScore: 48,
            feedbackType: ScanPassRouteFeedbackType.pressuredLane,
          ),
        ],
      );

      expect(evaluation.comparableRouteIds, <int>[1, 2]);
      expect(evaluation.isComparableToBest(evaluation.routes[2]), isFalse);
    });

    test('prediction rounds score against defender movement', () {
      final staticRound = _singleRouteRound(
        mode: ScanPassOcclusionMode.hidden,
        defender: const ScanPassPoint(0.52, 0.68),
        velocity: const ScanPassPoint(0, -0.26),
      );
      final predictionRound = _singleRouteRound(
        mode: ScanPassOcclusionMode.prediction,
        defender: const ScanPassPoint(0.52, 0.68),
        velocity: const ScanPassPoint(0, -0.26),
      );

      final staticScore = scorer.evaluateRound(staticRound).routes.single;
      final predictionScore =
          scorer.evaluateRound(predictionRound).routes.single;

      expect(predictionScore.laneSafety, lessThan(staticScore.laneSafety));
      expect(predictionScore.totalScore, lessThan(staticScore.totalScore));
    });
  });

  group('ScanPassChoiceClock and session summaries', () {
    test('choice clock caps remaining and response times', () {
      final startedAt = DateTime(2026, 1, 1, 12);
      const window = Duration(milliseconds: 2800);
      final clock = ScanPassChoiceClock(
        startedAt: startedAt,
        choiceWindow: window,
      );

      expect(
        clock.remainingAt(startedAt.add(const Duration(milliseconds: 900))),
        const Duration(milliseconds: 1900),
      );
      expect(
        clock.responseTimeAt(startedAt.add(const Duration(seconds: 5))),
        window,
      );
      expect(clock.isExpiredAt(startedAt.add(window)), isTrue);
    });

    test('aggregates route score, accuracy, response, and top streak', () {
      final summary = ScanPassSessionSummary.fromResults(
        const <ScanPassRoundResult>[
          ScanPassRoundResult(
            roundNumber: 1,
            targetId: 1,
            chosenScore: 95,
            bestScore: 100,
            responseTime: Duration(milliseconds: 700),
          ),
          ScanPassRoundResult(
            roundNumber: 2,
            targetId: 2,
            chosenScore: 80,
            bestScore: 86,
            responseTime: Duration(milliseconds: 1100),
          ),
          ScanPassRoundResult(
            roundNumber: 3,
            targetId: null,
            chosenScore: 0,
            bestScore: 82,
            responseTime: Duration(milliseconds: 2800),
            timedOut: true,
          ),
        ],
      );

      expect(summary.roundsPlayed, 3);
      expect(summary.averageRouteScore, closeTo(58.3, 0.1));
      expect(summary.decisionAccuracyPercent, closeTo(62.7, 0.1));
      expect(summary.averageResponseMs, 1533);
      expect(summary.topGroupStreak, 2);

      final personal = const ScanPassPersonalSummary.empty()
          .recordSession(summary, updatedAt: DateTime(2026, 1, 1));
      expect(personal.sessionsPlayed, 1);
      expect(personal.bestAverageRouteScore, summary.averageRouteScore);
      expect(personal.bestAverageResponseMs, summary.averageResponseMs);
    });
  });
}

ScanPassRound _singleRouteRound({
  ScanPassOcclusionMode mode = ScanPassOcclusionMode.hidden,
  ScanPassPoint defender = const ScanPassPoint(0.52, 0.78),
  ScanPassPoint velocity = const ScanPassPoint(0, 0),
}) {
  return ScanPassRound(
    roundNumber: 1,
    ballCarrier: const ScanPassPlayer(
      id: 0,
      number: 8,
      position: ScanPassPoint(0.20, 0.50),
      facingRadians: 0,
    ),
    teammates: const <ScanPassPlayer>[
      ScanPassPlayer(
        id: 1,
        number: 9,
        position: ScanPassPoint(0.78, 0.50),
        facingRadians: 0,
      ),
    ],
    defenders: <ScanPassDefender>[
      ScanPassDefender(id: 1, position: defender, velocity: velocity),
      const ScanPassDefender(
        id: 2,
        position: ScanPassPoint(0.64, 0.18),
      ),
    ],
    occlusionMode: mode,
  );
}

String _sessionSignature(List<ScanPassRound> rounds) {
  return rounds
      .map(
        (round) => [
          round.roundNumber,
          round.occlusionMode.name,
          _point(round.ballCarrier.position),
          ...round.teammates.map((player) => _point(player.position)),
          ...round.defenders.map((defender) => _point(defender.position)),
          ...round.defenders.map((defender) => _point(defender.velocity)),
        ].join('|'),
      )
      .join('\n');
}

String _point(ScanPassPoint point) {
  return '${point.x.toStringAsFixed(3)},${point.y.toStringAsFixed(3)}';
}
