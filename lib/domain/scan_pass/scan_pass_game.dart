import 'dart:convert';
import 'dart:math' as math;

enum ScanPassOcclusionMode {
  silhouettes,
  hidden,
  prediction,
}

enum ScanPassRouteFeedbackType {
  clearLane,
  timedRun,
  openSpace,
  forwardThreat,
  pressuredLane,
  lateArrival,
  tightReceiver,
  lowProgression,
}

class ScanPassPoint {
  final double x;
  final double y;

  const ScanPassPoint(this.x, this.y);

  ScanPassPoint operator +(ScanPassPoint other) =>
      ScanPassPoint(x + other.x, y + other.y);

  ScanPassPoint operator -(ScanPassPoint other) =>
      ScanPassPoint(x - other.x, y - other.y);

  ScanPassPoint operator *(double scale) => ScanPassPoint(x * scale, y * scale);

  double dot(ScanPassPoint other) => x * other.x + y * other.y;

  double get distance => math.sqrt((x * x) + (y * y));

  double distanceTo(ScanPassPoint other) => (this - other).distance;

  ScanPassPoint lerp(ScanPassPoint other, double t) {
    final clamped = t.clamp(0.0, 1.0).toDouble();
    return ScanPassPoint(
      x + ((other.x - x) * clamped),
      y + ((other.y - y) * clamped),
    );
  }

  ScanPassPoint clampToField({
    double minX = ScanPassRoundGenerator.fieldMinX,
    double maxX = ScanPassRoundGenerator.fieldMaxX,
    double minY = ScanPassRoundGenerator.fieldMinY,
    double maxY = ScanPassRoundGenerator.fieldMaxY,
  }) {
    return ScanPassPoint(
      x.clamp(minX, maxX).toDouble(),
      y.clamp(minY, maxY).toDouble(),
    );
  }

  Map<String, double> toMap() => <String, double>{'x': x, 'y': y};
}

class ScanPassPlayer {
  final int id;
  final int number;
  final ScanPassPoint position;
  final double facingRadians;

  const ScanPassPlayer({
    required this.id,
    required this.number,
    required this.position,
    required this.facingRadians,
  });
}

class ScanPassDefender {
  final int id;
  final ScanPassPoint position;
  final ScanPassPoint velocity;

  const ScanPassDefender({
    required this.id,
    required this.position,
    this.velocity = const ScanPassPoint(0, 0),
  });

  ScanPassPoint predictedPosition({double seconds = 0.7}) {
    return (position + (velocity * seconds)).clampToField();
  }
}

class ScanPassRound {
  final int roundNumber;
  final ScanPassPlayer ballCarrier;
  final List<ScanPassPlayer> teammates;
  final List<ScanPassDefender> defenders;
  final ScanPassOcclusionMode occlusionMode;

  const ScanPassRound({
    required this.roundNumber,
    required this.ballCarrier,
    required this.teammates,
    required this.defenders,
    required this.occlusionMode,
  });

  List<ScanPassPoint> defenderScoringPositions() {
    return defenders
        .map(
          (defender) => occlusionMode == ScanPassOcclusionMode.prediction
              ? defender.predictedPosition()
              : defender.position,
        )
        .toList(growable: false);
  }
}

class ScanPassRouteScore {
  final int targetId;
  final int targetNumber;
  final double laneSafety;
  final double arrivalMargin;
  final double receiverSpace;
  final double progression;
  final double simulatedResult;
  final double decisionScore;
  final double reactionBonus;
  final int totalScore;
  final ScanPassRouteFeedbackType feedbackType;

  const ScanPassRouteScore({
    required this.targetId,
    required this.targetNumber,
    required this.laneSafety,
    required this.arrivalMargin,
    required this.receiverSpace,
    required this.progression,
    required this.simulatedResult,
    required this.decisionScore,
    required this.reactionBonus,
    required this.totalScore,
    required this.feedbackType,
  });
}

class ScanPassRoundEvaluation {
  static const int comparableScoreWindow = 7;

  final ScanPassRound round;
  final List<ScanPassRouteScore> routes;

  const ScanPassRoundEvaluation({
    required this.round,
    required this.routes,
  });

  int get bestScore => routes
      .map((route) => route.totalScore)
      .fold<int>(0, (best, score) => math.max(best, score));

  ScanPassRouteScore routeForTarget(int targetId) {
    return routes.firstWhere((route) => route.targetId == targetId);
  }

  bool isComparableToBest(ScanPassRouteScore route) {
    return bestScore - route.totalScore <= comparableScoreWindow;
  }

  List<int> get comparableRouteIds => routes
      .where(isComparableToBest)
      .map((route) => route.targetId)
      .toList(growable: false);
}

class ScanPassScorer {
  static const Duration defaultChoiceWindow = Duration(milliseconds: 2800);
  static const double _ballSpeed = 0.82;
  static const double _defenderSpeed = 0.45;

  const ScanPassScorer();

  ScanPassRoundEvaluation evaluateRound(
    ScanPassRound round, {
    Duration responseTime = const Duration(milliseconds: 1200),
    Duration choiceWindow = defaultChoiceWindow,
  }) {
    return ScanPassRoundEvaluation(
      round: round,
      routes: round.teammates
          .map(
            (teammate) => scoreRoute(
              round,
              teammate,
              responseTime: responseTime,
              choiceWindow: choiceWindow,
            ),
          )
          .toList(growable: false),
    );
  }

  ScanPassRouteScore scoreRoute(
    ScanPassRound round,
    ScanPassPlayer target, {
    Duration responseTime = const Duration(milliseconds: 1200),
    Duration choiceWindow = defaultChoiceWindow,
  }) {
    final from = round.ballCarrier.position;
    final to = target.position;
    final defenders = round.defenderScoringPositions();
    final laneSafety = _laneSafety(from, to, defenders);
    final arrivalMargin = _arrivalMargin(from, to, defenders);
    final receiverSpace = _receiverSpace(to, defenders);
    final progression = _progression(from, to);
    final simulatedResult = _simulatedResult(
      laneSafety: laneSafety,
      arrivalMargin: arrivalMargin,
      receiverSpace: receiverSpace,
    );
    final decisionScore = _clampScore(
      (laneSafety * 0.26) +
          (arrivalMargin * 0.22) +
          (receiverSpace * 0.16) +
          (progression * 0.12) +
          (simulatedResult * 0.14),
    );
    final reactionBonus =
        decisionScore >= 50 ? _reactionBonus(responseTime, choiceWindow) : 0.0;
    final totalScore = _clampScore(decisionScore + reactionBonus).round();
    return ScanPassRouteScore(
      targetId: target.id,
      targetNumber: target.number,
      laneSafety: laneSafety,
      arrivalMargin: arrivalMargin,
      receiverSpace: receiverSpace,
      progression: progression,
      simulatedResult: simulatedResult,
      decisionScore: decisionScore,
      reactionBonus: reactionBonus,
      totalScore: totalScore,
      feedbackType: _feedbackType(
        laneSafety: laneSafety,
        arrivalMargin: arrivalMargin,
        receiverSpace: receiverSpace,
        progression: progression,
      ),
    );
  }

  static double _laneSafety(
    ScanPassPoint from,
    ScanPassPoint to,
    List<ScanPassPoint> defenders,
  ) {
    final minDistance = defenders
        .map((defender) => _distanceToSegment(defender, from, to))
        .fold<double>(1, math.min);
    return _normalize(minDistance, low: 0.055, high: 0.245);
  }

  static double _arrivalMargin(
    ScanPassPoint from,
    ScanPassPoint to,
    List<ScanPassPoint> defenders,
  ) {
    final ballArrival = from.distanceTo(to) / _ballSpeed;
    final defenderArrival = defenders
        .map((defender) => defender.distanceTo(to) / _defenderSpeed)
        .fold<double>(10, math.min);
    return _normalize(defenderArrival - ballArrival, low: -0.15, high: 0.80);
  }

  static double _receiverSpace(
    ScanPassPoint receiver,
    List<ScanPassPoint> defenders,
  ) {
    final defenderSpace =
        defenders.map(receiver.distanceTo).fold<double>(1, math.min);
    final sidelineSpace = math.min(
      math.min(receiver.x, 1 - receiver.x),
      math.min(receiver.y, 1 - receiver.y),
    );
    final spaceScore = _normalize(defenderSpace, low: 0.10, high: 0.36);
    final sidelinePenalty =
        sidelineSpace < 0.08 ? (0.08 - sidelineSpace) * 320 : 0;
    return _clampScore(spaceScore - sidelinePenalty);
  }

  static double _progression(ScanPassPoint from, ScanPassPoint to) {
    final forwardGain = to.x - from.x;
    final centralValue = (1 - ((to.y - 0.5).abs() * 1.15)).clamp(0.0, 1.0);
    return _clampScore(
      (_normalize(forwardGain, low: 0.06, high: 0.58) * 0.82) +
          (centralValue * 18),
    );
  }

  static double _simulatedResult({
    required double laneSafety,
    required double arrivalMargin,
    required double receiverSpace,
  }) {
    final base =
        (laneSafety * 0.46) + (arrivalMargin * 0.34) + (receiverSpace * 0.20);
    final hardPressurePenalty =
        math.max(0, 42 - math.min(laneSafety, arrivalMargin)) * 0.55;
    return _clampScore(base - hardPressurePenalty);
  }

  static double _reactionBonus(Duration responseTime, Duration choiceWindow) {
    final responseMs = responseTime.inMilliseconds.clamp(0, 1 << 30);
    final windowMs = math.max(1, choiceWindow.inMilliseconds);
    if (responseMs <= 450) return 10;
    if (responseMs >= windowMs) return 0;
    return _clampScore(
          ((windowMs - responseMs) / math.max(1, windowMs - 450)) * 100,
        ) /
        10;
  }

  static ScanPassRouteFeedbackType _feedbackType({
    required double laneSafety,
    required double arrivalMargin,
    required double receiverSpace,
    required double progression,
  }) {
    final weakPoints = <ScanPassRouteFeedbackType, double>{
      ScanPassRouteFeedbackType.pressuredLane: laneSafety,
      ScanPassRouteFeedbackType.lateArrival: arrivalMargin,
      ScanPassRouteFeedbackType.tightReceiver: receiverSpace,
      ScanPassRouteFeedbackType.lowProgression: progression,
    };
    final weakest = weakPoints.entries.reduce(
      (a, b) => a.value <= b.value ? a : b,
    );
    if (weakest.value < 48) return weakest.key;
    final strengths = <ScanPassRouteFeedbackType, double>{
      ScanPassRouteFeedbackType.clearLane: laneSafety,
      ScanPassRouteFeedbackType.timedRun: arrivalMargin,
      ScanPassRouteFeedbackType.openSpace: receiverSpace,
      ScanPassRouteFeedbackType.forwardThreat: progression,
    };
    return strengths.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static double _distanceToSegment(
    ScanPassPoint point,
    ScanPassPoint a,
    ScanPassPoint b,
  ) {
    final ab = b - a;
    final lengthSquared = ab.dot(ab);
    if (lengthSquared == 0) return point.distanceTo(a);
    final t = ((point - a).dot(ab) / lengthSquared).clamp(0.0, 1.0).toDouble();
    final projected = a + (ab * t);
    return point.distanceTo(projected);
  }

  static double _normalize(
    double value, {
    required double low,
    required double high,
  }) {
    if (high <= low) return 0;
    return _clampScore(((value - low) / (high - low)) * 100);
  }

  static double _clampScore(double value) => value.clamp(0.0, 100.0).toDouble();
}

class ScanPassRoundGenerator {
  static const double fieldMinX = 0.07;
  static const double fieldMaxX = 0.93;
  static const double fieldMinY = 0.08;
  static const double fieldMaxY = 0.92;
  static const int roundCount = 10;

  final int seed;
  final ScanPassScorer scorer;

  const ScanPassRoundGenerator({
    required this.seed,
    this.scorer = const ScanPassScorer(),
  });

  List<ScanPassRound> generateSession({int count = roundCount}) {
    return List<ScanPassRound>.generate(
      count,
      (index) => generateRound(index + 1),
      growable: false,
    );
  }

  ScanPassRound generateRound(int roundNumber) {
    final mode = modeForRound(roundNumber);
    final random = math.Random(seed + (roundNumber * 7919));
    for (var attempt = 0; attempt < 80; attempt += 1) {
      final round = _candidateRound(roundNumber, mode, random);
      if (_isUsefulRound(round)) return round;
    }
    return _fallbackRound(roundNumber, mode);
  }

  static ScanPassOcclusionMode modeForRound(int roundNumber) {
    if (roundNumber <= 3) return ScanPassOcclusionMode.silhouettes;
    if (roundNumber <= 7) return ScanPassOcclusionMode.hidden;
    return ScanPassOcclusionMode.prediction;
  }

  ScanPassRound _candidateRound(
    int roundNumber,
    ScanPassOcclusionMode mode,
    math.Random random,
  ) {
    final carrier = ScanPassPlayer(
      id: 0,
      number: 8,
      position: ScanPassPoint(
        _range(random, 0.16, 0.28),
        _range(random, 0.36, 0.66),
      ),
      facingRadians: -math.pi / 2,
    );
    final teammatePoints = <ScanPassPoint>[
      ScanPassPoint(
        _range(random, 0.48, 0.62),
        (carrier.position.y + _range(random, -0.26, -0.12))
            .clamp(fieldMinY, fieldMaxY)
            .toDouble(),
      ),
      ScanPassPoint(
        _range(random, 0.68, 0.86),
        _range(random, 0.28, 0.72),
      ),
      ScanPassPoint(
        _range(random, 0.42, 0.64),
        random.nextBool()
            ? _range(random, 0.14, 0.28)
            : _range(random, 0.72, 0.86),
      ),
    ]..shuffle(random);
    final teammates = <ScanPassPlayer>[
      for (var i = 0; i < teammatePoints.length; i += 1)
        ScanPassPlayer(
          id: i + 1,
          number: 9 + i,
          position: teammatePoints[i].clampToField(),
          facingRadians: math.atan2(
            teammatePoints[i].y - carrier.position.y,
            teammatePoints[i].x - carrier.position.x,
          ),
        ),
    ];
    final laneTarget = teammates[random.nextInt(teammates.length)].position;
    final secondTarget =
        teammates[(random.nextInt(teammates.length - 1) + 1) % teammates.length]
            .position;
    final defenderOne = carrier.position
        .lerp(laneTarget, _range(random, 0.43, 0.66))
        .lerp(
          ScanPassPoint(
            carrier.position.x,
            laneTarget.y + _range(random, -0.08, 0.08),
          ),
          _range(random, 0.08, 0.22),
        )
        .clampToField();
    final defenderTwo = secondTarget
        .lerp(carrier.position, _range(random, 0.22, 0.44))
        .lerp(
          ScanPassPoint(
            _range(random, 0.46, 0.72),
            _range(random, 0.22, 0.78),
          ),
          _range(random, 0.20, 0.50),
        )
        .clampToField();
    final predictionScale =
        mode == ScanPassOcclusionMode.prediction ? 1.0 : 0.35;
    return ScanPassRound(
      roundNumber: roundNumber,
      ballCarrier: carrier,
      teammates: teammates,
      defenders: <ScanPassDefender>[
        ScanPassDefender(
          id: 1,
          position: defenderOne,
          velocity: ScanPassPoint(
            _range(random, -0.12, 0.12) * predictionScale,
            _range(random, -0.12, 0.12) * predictionScale,
          ),
        ),
        ScanPassDefender(
          id: 2,
          position: defenderTwo,
          velocity: ScanPassPoint(
            _range(random, -0.10, 0.10) * predictionScale,
            _range(random, -0.10, 0.10) * predictionScale,
          ),
        ),
      ],
      occlusionMode: mode,
    );
  }

  bool _isUsefulRound(ScanPassRound round) {
    final allPoints = <ScanPassPoint>[
      round.ballCarrier.position,
      ...round.teammates.map((player) => player.position),
      ...round.defenders.map((defender) => defender.position),
      ...round.defenders.map((defender) => defender.predictedPosition()),
    ];
    if (allPoints.any((point) => !_inBounds(point))) return false;
    for (final teammate in round.teammates) {
      if (teammate.position.distanceTo(round.ballCarrier.position) < 0.24) {
        return false;
      }
    }
    for (var i = 0; i < round.teammates.length; i += 1) {
      for (var j = i + 1; j < round.teammates.length; j += 1) {
        if (round.teammates[i].position.distanceTo(
              round.teammates[j].position,
            ) <
            0.15) {
          return false;
        }
      }
    }
    final evaluation = scorer.evaluateRound(round);
    final scores = evaluation.routes.map((route) => route.totalScore).toList()
      ..sort();
    return scores.last >= 58 && scores.last - scores.first >= 12;
  }

  ScanPassRound _fallbackRound(int roundNumber, ScanPassOcclusionMode mode) {
    final prediction = mode == ScanPassOcclusionMode.prediction;
    return ScanPassRound(
      roundNumber: roundNumber,
      ballCarrier: const ScanPassPlayer(
        id: 0,
        number: 8,
        position: ScanPassPoint(0.20, 0.58),
        facingRadians: -0.6,
      ),
      teammates: const <ScanPassPlayer>[
        ScanPassPlayer(
          id: 1,
          number: 9,
          position: ScanPassPoint(0.56, 0.34),
          facingRadians: -0.6,
        ),
        ScanPassPlayer(
          id: 2,
          number: 10,
          position: ScanPassPoint(0.77, 0.59),
          facingRadians: 0,
        ),
        ScanPassPlayer(
          id: 3,
          number: 11,
          position: ScanPassPoint(0.56, 0.79),
          facingRadians: 0.6,
        ),
      ],
      defenders: <ScanPassDefender>[
        ScanPassDefender(
          id: 1,
          position: const ScanPassPoint(0.45, 0.47),
          velocity: prediction
              ? const ScanPassPoint(0.12, -0.08)
              : const ScanPassPoint(0, 0),
        ),
        ScanPassDefender(
          id: 2,
          position: const ScanPassPoint(0.63, 0.63),
          velocity: prediction
              ? const ScanPassPoint(-0.08, 0.08)
              : const ScanPassPoint(0, 0),
        ),
      ],
      occlusionMode: mode,
    );
  }

  static bool _inBounds(ScanPassPoint point) {
    return point.x >= fieldMinX &&
        point.x <= fieldMaxX &&
        point.y >= fieldMinY &&
        point.y <= fieldMaxY;
  }

  static double _range(math.Random random, double min, double max) {
    return min + (random.nextDouble() * (max - min));
  }
}

class ScanPassChoiceClock {
  final DateTime startedAt;
  final Duration choiceWindow;

  const ScanPassChoiceClock({
    required this.startedAt,
    required this.choiceWindow,
  });

  Duration elapsedAt(DateTime now) {
    final elapsed = now.difference(startedAt);
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  Duration remainingAt(DateTime now) {
    final remaining = choiceWindow - elapsedAt(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool isExpiredAt(DateTime now) => remainingAt(now) == Duration.zero;

  Duration responseTimeAt(DateTime now) {
    final elapsed = elapsedAt(now);
    return elapsed > choiceWindow ? choiceWindow : elapsed;
  }
}

class ScanPassRoundResult {
  final int roundNumber;
  final int? targetId;
  final int chosenScore;
  final int bestScore;
  final Duration responseTime;
  final bool timedOut;

  const ScanPassRoundResult({
    required this.roundNumber,
    required this.targetId,
    required this.chosenScore,
    required this.bestScore,
    required this.responseTime,
    this.timedOut = false,
  });

  double get decisionAccuracyPercent {
    if (bestScore <= 0) return 0;
    return ((chosenScore / bestScore) * 100).clamp(0.0, 100.0).toDouble();
  }
}

class ScanPassSessionSummary {
  final int roundsPlayed;
  final double averageRouteScore;
  final double decisionAccuracyPercent;
  final int averageResponseMs;
  final int topGroupStreak;

  const ScanPassSessionSummary({
    required this.roundsPlayed,
    required this.averageRouteScore,
    required this.decisionAccuracyPercent,
    required this.averageResponseMs,
    required this.topGroupStreak,
  });

  static ScanPassSessionSummary fromResults(List<ScanPassRoundResult> results) {
    if (results.isEmpty) {
      return const ScanPassSessionSummary(
        roundsPlayed: 0,
        averageRouteScore: 0,
        decisionAccuracyPercent: 0,
        averageResponseMs: 0,
        topGroupStreak: 0,
      );
    }
    var scoreTotal = 0;
    var accuracyTotal = 0.0;
    var responseTotal = 0;
    var currentStreak = 0;
    var bestStreak = 0;
    for (final result in results) {
      scoreTotal += result.chosenScore;
      accuracyTotal += result.decisionAccuracyPercent;
      responseTotal += result.responseTime.inMilliseconds;
      if (!result.timedOut && result.bestScore - result.chosenScore <= 7) {
        currentStreak += 1;
        bestStreak = math.max(bestStreak, currentStreak);
      } else {
        currentStreak = 0;
      }
    }
    return ScanPassSessionSummary(
      roundsPlayed: results.length,
      averageRouteScore: scoreTotal / results.length,
      decisionAccuracyPercent: accuracyTotal / results.length,
      averageResponseMs: (responseTotal / results.length).round(),
      topGroupStreak: bestStreak,
    );
  }
}

class ScanPassPersonalSummary {
  final int sessionsPlayed;
  final double lastAverageRouteScore;
  final double bestAverageRouteScore;
  final double lastDecisionAccuracyPercent;
  final double bestDecisionAccuracyPercent;
  final int lastAverageResponseMs;
  final int bestAverageResponseMs;
  final String updatedAtIso;

  const ScanPassPersonalSummary({
    required this.sessionsPlayed,
    required this.lastAverageRouteScore,
    required this.bestAverageRouteScore,
    required this.lastDecisionAccuracyPercent,
    required this.bestDecisionAccuracyPercent,
    required this.lastAverageResponseMs,
    required this.bestAverageResponseMs,
    required this.updatedAtIso,
  });

  const ScanPassPersonalSummary.empty()
      : sessionsPlayed = 0,
        lastAverageRouteScore = 0,
        bestAverageRouteScore = 0,
        lastDecisionAccuracyPercent = 0,
        bestDecisionAccuracyPercent = 0,
        lastAverageResponseMs = 0,
        bestAverageResponseMs = 0,
        updatedAtIso = '';

  factory ScanPassPersonalSummary.fromJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const ScanPassPersonalSummary.empty();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const ScanPassPersonalSummary.empty();
      return ScanPassPersonalSummary(
        sessionsPlayed: _asInt(decoded['sessionsPlayed']),
        lastAverageRouteScore: _asDouble(decoded['lastAverageRouteScore']),
        bestAverageRouteScore: _asDouble(decoded['bestAverageRouteScore']),
        lastDecisionAccuracyPercent:
            _asDouble(decoded['lastDecisionAccuracyPercent']),
        bestDecisionAccuracyPercent:
            _asDouble(decoded['bestDecisionAccuracyPercent']),
        lastAverageResponseMs: _asInt(decoded['lastAverageResponseMs']),
        bestAverageResponseMs: _asInt(decoded['bestAverageResponseMs']),
        updatedAtIso: decoded['updatedAtIso']?.toString() ?? '',
      );
    } catch (_) {
      return const ScanPassPersonalSummary.empty();
    }
  }

  ScanPassPersonalSummary recordSession(
    ScanPassSessionSummary session, {
    required DateTime updatedAt,
  }) {
    final nextSessionCount = sessionsPlayed + 1;
    final nextBestResponse = bestAverageResponseMs == 0
        ? session.averageResponseMs
        : math.min(bestAverageResponseMs, session.averageResponseMs);
    return ScanPassPersonalSummary(
      sessionsPlayed: nextSessionCount,
      lastAverageRouteScore: session.averageRouteScore,
      bestAverageRouteScore: math.max(
        bestAverageRouteScore,
        session.averageRouteScore,
      ),
      lastDecisionAccuracyPercent: session.decisionAccuracyPercent,
      bestDecisionAccuracyPercent: math.max(
        bestDecisionAccuracyPercent,
        session.decisionAccuracyPercent,
      ),
      lastAverageResponseMs: session.averageResponseMs,
      bestAverageResponseMs: nextBestResponse,
      updatedAtIso: updatedAt.toIso8601String(),
    );
  }

  String toJson() => jsonEncode(<String, dynamic>{
        'sessionsPlayed': sessionsPlayed,
        'lastAverageRouteScore': lastAverageRouteScore,
        'bestAverageRouteScore': bestAverageRouteScore,
        'lastDecisionAccuracyPercent': lastDecisionAccuracyPercent,
        'bestDecisionAccuracyPercent': bestDecisionAccuracyPercent,
        'lastAverageResponseMs': lastAverageResponseMs,
        'bestAverageResponseMs': bestAverageResponseMs,
        'updatedAtIso': updatedAtIso,
      });

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
