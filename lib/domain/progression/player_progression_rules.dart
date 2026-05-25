import '../entities/training_entry.dart';

class PlayerProgressionRules {
  static const int trainingLogSavedXp = 15;
  static const int firstDailyTrainingLogXp = 5;
  static const int plannedTrainingDayXp = 12;
  static const int matchLogSavedXp = 10;
  static const int matchDetailRecordedXp = 4;
  static const int conditioningRecordedXp = 6;
  static const int missingConditioningPenaltyXp = 5;
  static const int routineCompleteXp = 6;
  static const int streakDaily2To3Xp = 3;
  static const int streakDaily4To6Xp = 6;
  static const int streakDaily7PlusXp = 10;
  static const int streak3DaysXp = 12;
  static const int streak7DaysXp = 25;
  static const int weekly3LogsXp = 18;
  static const int weekly5LogsXp = 30;
  static const int dailyTaskCompletionXp = 10;
  static const int dailyPositiveXpCap = 65;
  static const int maxLevelMasterySpan = 500;

  static const List<int> _levelThresholds = <int>[
    0,
    25,
    70,
    140,
    240,
    380,
    560,
    790,
    1080,
    1430,
    1850,
    2340,
    2910,
    3560,
    4300,
    5140,
    6080,
    7130,
    8300,
    9600,
  ];

  static List<int> get levelThresholds =>
      List<int>.unmodifiable(_levelThresholds);

  const PlayerProgressionRules._();

  static PlayerTrainingLogProgression evaluateTrainingLog({
    required TrainingEntry entry,
    required List<TrainingEntry> existingEntries,
    required bool hasPlanOnDay,
    required int mealXp,
    required String mealReason,
    required Set<String> awardedStreaks,
    required Set<String> awardedRoutineDays,
  }) {
    final reasons = <String>[];
    final streakTokensToAward = <String>[];
    final routineDayTokensToAward = <String>[];
    var gainedXp = 0;
    final entryDay = normalizeDay(entry.date);
    final existingTrainingEntries = existingEntries
        .where((item) => !item.isMatch)
        .toList(growable: false);
    final sameDayEntries = existingTrainingEntries
        .where((item) => normalizeDay(item.date) == entryDay)
        .toList(growable: false);

    gainedXp += trainingLogSavedXp;
    reasons.add('log');

    if (sameDayEntries.isEmpty) {
      gainedXp += firstDailyTrainingLogXp;
      reasons.add('first_daily_log');
    }

    if (hasPlanOnDay && sameDayEntries.isEmpty) {
      gainedXp += plannedTrainingDayXp;
      reasons.add('plan_completed');
    }

    if (hasLiftingRecord(entry)) {
      gainedXp += conditioningRecordedXp;
      reasons.add('lifting_recorded');
    } else {
      gainedXp -= missingConditioningPenaltyXp;
      reasons.add('lifting_missed');
    }

    if (hasJumpRopeRecord(entry)) {
      gainedXp += conditioningRecordedXp;
      reasons.add('jump_rope_recorded');
    } else {
      gainedXp -= missingConditioningPenaltyXp;
      reasons.add('jump_rope_missed');
    }

    if (mealXp != 0 && mealReason.isNotEmpty) {
      gainedXp += mealXp;
      reasons.add(mealReason);
    }

    final updatedEntries = <TrainingEntry>[...existingTrainingEntries, entry];
    final streak = calculateTrainingStreakEndingAt(updatedEntries, entryDay);
    final dayToken = dayKey(entryDay);

    if (sameDayEntries.isEmpty) {
      if (streak >= 7) {
        gainedXp += streakDaily7PlusXp;
        reasons.add('streak_daily_7_plus');
      } else if (streak >= 4) {
        gainedXp += streakDaily4To6Xp;
        reasons.add('streak_daily_4_6');
      } else if (streak >= 2) {
        gainedXp += streakDaily2To3Xp;
        reasons.add('streak_daily_2_3');
      }
    }

    if (isRoutineComplete(entry, mealXp) &&
        !awardedRoutineDays.contains(dayToken)) {
      routineDayTokensToAward.add(dayToken);
      gainedXp += routineCompleteXp;
      reasons.add('routine_complete_day');
    }

    final streak3Token = '$dayToken:3';
    if (streak >= 3 && !awardedStreaks.contains(streak3Token)) {
      streakTokensToAward.add(streak3Token);
      gainedXp += streak3DaysXp;
      reasons.add('streak_3');
    }
    final streak7Token = '$dayToken:7';
    if (streak >= 7 && !awardedStreaks.contains(streak7Token)) {
      streakTokensToAward.add(streak7Token);
      gainedXp += streak7DaysXp;
      reasons.add('streak_7');
    }

    final beforeWeeklyCount = existingTrainingEntries
        .where((item) => isSameWeek(item.date, entryDay))
        .length;
    final afterWeeklyCount = updatedEntries
        .where((item) => isSameWeek(item.date, entryDay))
        .length;
    if (beforeWeeklyCount < 3 && afterWeeklyCount >= 3) {
      gainedXp += weekly3LogsXp;
      reasons.add('weekly_3');
    }
    if (beforeWeeklyCount < 5 && afterWeeklyCount >= 5) {
      gainedXp += weekly5LogsXp;
      reasons.add('weekly_5');
    }

    return PlayerTrainingLogProgression(
      requestedXp: gainedXp,
      reasons: reasons,
      streakTokensToAward: streakTokensToAward,
      routineDayTokensToAward: routineDayTokensToAward,
    );
  }

  static PlayerTrainingLogProgression evaluateTrainingLogUpdate({
    required TrainingEntry previousEntry,
    required TrainingEntry updatedEntry,
    required int previousMealXp,
    required int updatedMealXp,
    required String updatedMealReason,
    required Set<String> awardedRoutineDays,
  }) {
    final reasons = <String>[];
    final routineDayTokensToAward = <String>[];
    var gainedXp = 0;

    if (!hasLiftingRecord(previousEntry) && hasLiftingRecord(updatedEntry)) {
      gainedXp += conditioningRecordedXp;
      reasons.add('lifting_added');
    }

    if (!hasJumpRopeRecord(previousEntry) && hasJumpRopeRecord(updatedEntry)) {
      gainedXp += conditioningRecordedXp;
      reasons.add('jump_rope_added');
    }

    if (updatedMealXp > previousMealXp) {
      gainedXp += updatedMealXp - previousMealXp;
      if (updatedMealReason.isNotEmpty) {
        reasons.add(updatedMealReason);
      }
    }

    final dayToken = dayKey(normalizeDay(updatedEntry.date));
    final previousRoutineComplete = isRoutineComplete(
      previousEntry,
      previousMealXp,
    );
    final updatedRoutineComplete = isRoutineComplete(
      updatedEntry,
      updatedMealXp,
    );
    if (!previousRoutineComplete &&
        updatedRoutineComplete &&
        !awardedRoutineDays.contains(dayToken)) {
      routineDayTokensToAward.add(dayToken);
      gainedXp += routineCompleteXp;
      reasons.add('routine_complete_day');
    }

    return PlayerTrainingLogProgression(
      requestedXp: gainedXp,
      reasons: reasons,
      routineDayTokensToAward: routineDayTokensToAward,
    );
  }

  static PlayerXpRuleResult evaluateMatchLog({
    required TrainingEntry? previousEntry,
    required TrainingEntry updatedEntry,
    required bool isNewMatchToken,
  }) {
    final reasons = <String>[];
    var gainedXp = 0;

    if (previousEntry == null && isNewMatchToken) {
      gainedXp += matchLogSavedXp;
      reasons.add('match_logged');
    }

    final previousHasResult =
        previousEntry != null && hasMatchResult(previousEntry);
    final updatedHasResult = hasMatchResult(updatedEntry);
    if (!previousHasResult && updatedHasResult) {
      gainedXp += matchDetailRecordedXp;
      reasons.add('match_result_recorded');
    }

    final previousHasContribution =
        previousEntry != null && hasMatchContribution(previousEntry);
    final updatedHasContribution = hasMatchContribution(updatedEntry);
    if (!previousHasContribution && updatedHasContribution) {
      gainedXp += matchDetailRecordedXp;
      reasons.add('match_contribution_recorded');
    }

    return PlayerXpRuleResult(requestedXp: gainedXp, reasons: reasons);
  }

  static int calculateTrainingStreakEndingAt(
    List<TrainingEntry> entries,
    DateTime targetDay,
  ) {
    if (entries.isEmpty) return 0;
    final days = entries.map((entry) => normalizeDay(entry.date)).toSet();
    var streak = 0;
    var cursor = normalizeDay(targetDay);
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static bool isSameWeek(DateTime date, DateTime targetDay) {
    final normalizedDate = normalizeDay(date);
    final weekStart = targetDay.subtract(Duration(days: targetDay.weekday - 1));
    final weekEndExclusive = weekStart.add(const Duration(days: 7));
    return !normalizedDate.isBefore(weekStart) &&
        normalizedDate.isBefore(weekEndExclusive);
  }

  static DateTime normalizeDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool hasLiftingRecord(TrainingEntry entry) {
    return entry.liftingByPart.values.any((count) => count > 0);
  }

  static bool hasJumpRopeRecord(TrainingEntry entry) {
    return entry.jumpRopeCount > 0 ||
        entry.jumpRopeMinutes > 0 ||
        entry.jumpRopeNote.trim().isNotEmpty;
  }

  static bool hasMatchResult(TrainingEntry entry) {
    return entry.scoredGoals != null || entry.concededGoals != null;
  }

  static bool hasMatchContribution(TrainingEntry entry) {
    return entry.playerGoals != null ||
        entry.playerAssists != null ||
        entry.shotsOnTarget != null ||
        entry.ballsWon != null ||
        entry.minutesPlayed != null;
  }

  static bool isRoutineComplete(TrainingEntry entry, int mealXp) {
    return hasLiftingRecord(entry) && hasJumpRopeRecord(entry) && mealXp >= 5;
  }

  static String dayKey(DateTime value) {
    final normalized = normalizeDay(value);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }
}

class PlayerXpRuleResult {
  final int requestedXp;
  final List<String> reasons;

  const PlayerXpRuleResult({required this.requestedXp, required this.reasons});
}

class PlayerTrainingLogProgression extends PlayerXpRuleResult {
  final List<String> streakTokensToAward;
  final List<String> routineDayTokensToAward;

  const PlayerTrainingLogProgression({
    required super.requestedXp,
    required super.reasons,
    this.streakTokensToAward = const <String>[],
    this.routineDayTokensToAward = const <String>[],
  });
}
