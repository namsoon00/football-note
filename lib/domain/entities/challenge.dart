import 'meal_entry.dart';
import 'training_entry.dart';

enum ChallengeTrainingLevel { rookie, growth, ace }

enum ChallengeRunResult { completed, failed, abandoned }

class ChallengeTemplate {
  final String id;
  final int dayCount;
  final int rewardXpPerRound;
  final List<ChallengeRound> rounds;

  const ChallengeTemplate({
    required this.id,
    required this.dayCount,
    required this.rewardXpPerRound,
    required this.rounds,
  });
}

class ChallengeRound {
  final int number;
  final int targetTrainingMinutes;
  final int targetJumpRopeMinutes;
  final int targetLiftingMinutes;
  final double targetRiceBowls;
  final int rewardXp;

  const ChallengeRound({
    required this.number,
    required this.targetTrainingMinutes,
    required this.targetJumpRopeMinutes,
    required this.targetLiftingMinutes,
    required this.targetRiceBowls,
    required this.rewardXp,
  });
}

class ChallengeRun {
  final String id;
  final String templateId;
  final ChallengeTrainingLevel trainingLevel;
  final DateTime startedAt;
  final DateTime? completedAt;
  final bool abandoned;
  final ChallengeRunResult? result;
  final int? failedRoundNumber;

  const ChallengeRun({
    required this.id,
    required this.templateId,
    this.trainingLevel = ChallengeTrainingLevel.rookie,
    required this.startedAt,
    this.completedAt,
    this.abandoned = false,
    this.result,
    this.failedRoundNumber,
  });

  bool get isEnded => completedAt != null || result != null;

  bool get isCompleted =>
      result == ChallengeRunResult.completed ||
      (result == null && completedAt != null && !abandoned);

  bool get isFailed => result == ChallengeRunResult.failed;

  bool get isAbandoned =>
      result == ChallengeRunResult.abandoned ||
      (result == null && completedAt != null && abandoned);

  DateTime get startDay => normalizeDay(startedAt);

  DateTime dayForRound(int roundNumber) {
    return startDay.add(Duration(days: roundNumber - 1));
  }

  ChallengeRun copyWith({
    String? id,
    String? templateId,
    ChallengeTrainingLevel? trainingLevel,
    DateTime? startedAt,
    DateTime? completedAt,
    bool? abandoned,
    ChallengeRunResult? result,
    int? failedRoundNumber,
  }) {
    return ChallengeRun(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      trainingLevel: trainingLevel ?? this.trainingLevel,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      abandoned: abandoned ?? this.abandoned,
      result: result ?? this.result,
      failedRoundNumber: failedRoundNumber ?? this.failedRoundNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'templateId': templateId,
      'trainingLevel': trainingLevel.name,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'abandoned': abandoned,
      'result': result?.name,
      'failedRoundNumber': failedRoundNumber,
    };
  }

  factory ChallengeRun.fromMap(Map<String, dynamic> map) {
    final completedAt = DateTime.tryParse(
      map['completedAt']?.toString() ?? '',
    );
    final abandoned = map['abandoned'] == true;
    final parsedResult = _challengeRunResultFromName(
      map['result']?.toString(),
    );
    return ChallengeRun(
      id: map['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      templateId: map['templateId']?.toString() ?? '',
      trainingLevel: _challengeTrainingLevelFromName(
        map['trainingLevel']?.toString(),
        templateId: map['templateId']?.toString() ?? '',
      ),
      startedAt: DateTime.tryParse(map['startedAt']?.toString() ?? '') ??
          DateTime.now(),
      completedAt: completedAt,
      abandoned: abandoned,
      result: parsedResult ??
          (completedAt == null
              ? null
              : abandoned
                  ? ChallengeRunResult.abandoned
                  : ChallengeRunResult.completed),
      failedRoundNumber: (map['failedRoundNumber'] as num?)?.toInt(),
    );
  }
}

class ChallengeProgress {
  final ChallengeRun run;
  final ChallengeTemplate template;
  final List<ChallengeRoundProgress> rounds;

  const ChallengeProgress({
    required this.run,
    required this.template,
    required this.rounds,
  });

  int get completedRoundCount =>
      rounds.where((round) => round.completed).length;

  int get totalRoundCount => rounds.length;

  bool get allRoundsCompleted =>
      rounds.isNotEmpty && completedRoundCount >= rounds.length;

  double get completionRate {
    if (rounds.isEmpty) return 0;
    return completedRoundCount / rounds.length;
  }

  ChallengeRoundProgress? get todayRound {
    final today = normalizeDay(DateTime.now());
    for (final round in rounds) {
      if (round.date == today) return round;
    }
    return null;
  }

  ChallengeRoundProgress? get activeRound {
    final today = normalizeDay(DateTime.now());
    final todayMatch = todayRound;
    if (todayMatch != null) return todayMatch;
    for (final round in rounds) {
      if (!round.completed && !round.date.isBefore(today)) return round;
    }
    for (final round in rounds) {
      if (!round.completed) return round;
    }
    return rounds.isEmpty ? null : rounds.last;
  }

  ChallengeRoundProgress? missedExpiredRound({DateTime? now}) {
    final today = normalizeDay(now ?? DateTime.now());
    for (final round in rounds) {
      if (round.date.isBefore(today) && !round.completed) return round;
    }
    return null;
  }
}

class ChallengeRoundProgress {
  final ChallengeRound round;
  final DateTime date;
  final int trainingMinutes;
  final int jumpRopeMinutes;
  final int liftingMinutes;
  final double riceBowls;

  const ChallengeRoundProgress({
    required this.round,
    required this.date,
    required this.trainingMinutes,
    required this.jumpRopeMinutes,
    required this.liftingMinutes,
    required this.riceBowls,
  });

  bool get trainingCompleted => trainingMinutes >= round.targetTrainingMinutes;

  bool get jumpRopeCompleted => jumpRopeMinutes >= round.targetJumpRopeMinutes;

  bool get liftingCompleted => liftingMinutes >= round.targetLiftingMinutes;

  bool get mealCompleted => riceBowls >= round.targetRiceBowls;

  bool get completed =>
      trainingCompleted &&
      jumpRopeCompleted &&
      liftingCompleted &&
      mealCompleted;

  bool get isToday => date == normalizeDay(DateTime.now());
}

DateTime normalizeDay(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

int trainingMinutesForDay(Iterable<TrainingEntry> entries, DateTime day) {
  final normalizedDay = normalizeDay(day);
  return entries
      .where((entry) =>
          !entry.isMatch && normalizeDay(entry.date) == normalizedDay)
      .fold<int>(0, (sum, entry) => sum + entry.durationMinutes);
}

int jumpRopeMinutesForDay(Iterable<TrainingEntry> entries, DateTime day) {
  final normalizedDay = normalizeDay(day);
  return entries
      .where((entry) =>
          !entry.isMatch && normalizeDay(entry.date) == normalizedDay)
      .fold<int>(0, (sum, entry) => sum + entry.jumpRopeMinutes);
}

int liftingMinutesForDay(Iterable<TrainingEntry> entries, DateTime day) {
  final normalizedDay = normalizeDay(day);
  return entries
      .where((entry) =>
          !entry.isMatch && normalizeDay(entry.date) == normalizedDay)
      .fold<int>(0, (sum, entry) => sum + entry.liftingMinutes);
}

double riceBowlsForDay(Iterable<MealEntry> entries, DateTime day) {
  final normalizedDay = normalizeDay(day);
  MealEntry? latest;
  for (final entry in entries) {
    if (normalizeDay(entry.date) != normalizedDay) continue;
    if (latest == null || entry.createdAt.isAfter(latest.createdAt)) {
      latest = entry;
    }
  }
  return latest?.totalRiceBowls ?? 0;
}

ChallengeTrainingLevel _challengeTrainingLevelFromName(
  String? raw, {
  required String templateId,
}) {
  for (final level in ChallengeTrainingLevel.values) {
    if (level.name == raw) return level;
  }
  return switch (templateId) {
    'weekly_7' => ChallengeTrainingLevel.growth,
    'focus_14' => ChallengeTrainingLevel.ace,
    _ => ChallengeTrainingLevel.rookie,
  };
}

ChallengeRunResult? _challengeRunResultFromName(String? raw) {
  for (final result in ChallengeRunResult.values) {
    if (result.name == raw) return result;
  }
  return null;
}
