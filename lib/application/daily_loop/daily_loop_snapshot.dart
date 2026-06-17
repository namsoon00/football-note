import '../../domain/entities/meal_entry.dart';
import '../../domain/entities/training_board.dart';
import '../../domain/entities/training_entry.dart';
import '../skill_quiz_resume_summary.dart';

class DailyLoopSnapshot {
  final int weeklyTrainingCount;
  final int weeklyMinutes;
  final int streakDays;
  final DateTime? latestTrainingDay;
  final int? latestTrainingGapDays;
  final List<DailyLoopTrainingMarker> recentTrainingMarkers;
  final int boardCount;
  final DateTime? latestBoardUpdatedAt;
  final TrainingBoard? latestBoard;
  final int todayPlanCount;
  final List<DailyLoopPlan> todayPlans;
  final TrainingEntry? latestTrainingEntry;
  final TrainingEntry? latestCreatedTrainingEntry;
  final bool loggedTrainingToday;
  final bool loggedLiftingToday;
  final bool loggedJumpRopeToday;
  final bool loggedMealsToday;
  final bool openedNewsToday;
  final bool reviewedTodayDiary;
  final bool quizCompletedToday;
  final bool loggedBoardToday;
  final MealEntry? todayMealEntry;
  final SkillQuizResumeSummary quizResumeSummary;

  const DailyLoopSnapshot({
    required this.weeklyTrainingCount,
    required this.weeklyMinutes,
    required this.streakDays,
    required this.latestTrainingDay,
    required this.latestTrainingGapDays,
    required this.recentTrainingMarkers,
    required this.boardCount,
    required this.latestBoardUpdatedAt,
    required this.latestBoard,
    required this.todayPlanCount,
    required this.todayPlans,
    required this.latestTrainingEntry,
    required this.latestCreatedTrainingEntry,
    required this.loggedTrainingToday,
    required this.loggedLiftingToday,
    required this.loggedJumpRopeToday,
    required this.loggedMealsToday,
    required this.openedNewsToday,
    required this.reviewedTodayDiary,
    required this.quizCompletedToday,
    required this.loggedBoardToday,
    required this.todayMealEntry,
    required this.quizResumeSummary,
  });

  bool get showStreakHighlight =>
      streakDays >= 2 &&
      latestTrainingGapDays != null &&
      latestTrainingGapDays! <= 5;

  bool get streakIsActive =>
      latestTrainingGapDays != null && latestTrainingGapDays! <= 1;

  int get dailyTaskTotalCount => 8;

  int get dailyTaskCompletedCount => <bool>[
        loggedTrainingToday,
        loggedLiftingToday,
        loggedJumpRopeToday,
        loggedMealsToday,
        openedNewsToday,
        quizCompletedToday,
        reviewedTodayDiary,
        loggedBoardToday,
      ].where((done) => done).length;

  bool get completedDailyTasks =>
      dailyTaskCompletedCount >= dailyTaskTotalCount;

  factory DailyLoopSnapshot.build({
    required List<TrainingEntry> entries,
    required List<MealEntry> mealEntries,
    required List<DailyLoopPlan> plans,
    required List<TrainingBoard> boards,
    required DateTime? quizCompletedAt,
    required String? viewedDiaryDayToken,
    required SkillQuizResumeSummary quizResumeSummary,
    required bool openedNewsToday,
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final today = normalizeDay(effectiveNow);
    final sortedEntries = entries.toList(growable: false)
      ..sort(TrainingEntry.compareByRecentCreated);
    final sortedBoards = boards.toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEndExclusive = weekStart.add(const Duration(days: 7));
    final weeklyEntries = entries
        .where(
          (entry) =>
              !entry.date.isBefore(weekStart) &&
              entry.date.isBefore(weekEndExclusive),
        )
        .toList(growable: false);
    final weeklyMinutes = weeklyEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.durationMinutes,
    );
    final latestTrainingEntry =
        sortedEntries.isEmpty ? null : sortedEntries.first;
    final latestCreatedTrainingEntry = entries.where((entry) {
      final createdDay = normalizeDay(entry.createdAt);
      return createdDay == today;
    }).fold<TrainingEntry?>(
      null,
      (latest, entry) =>
          latest == null || entry.createdAt.isAfter(latest.createdAt)
              ? entry
              : latest,
    );
    final todayEntries = entries.where((entry) {
      final day = normalizeDay(entry.date);
      return day == today;
    }).toList(growable: false);
    final loggedTrainingToday = todayEntries.isNotEmpty;
    final loggedLiftingToday = todayEntries.any(
      (entry) =>
          entry.liftingMinutes > 0 ||
          entry.liftingByPart.values.any((value) => value > 0),
    );
    final loggedJumpRopeToday = todayEntries.any(hasCompletedJumpRope);
    final todayMealEntry = mealEntries.where((entry) {
      final day = normalizeDay(entry.date);
      return day == today;
    }).fold<MealEntry?>(
      null,
      (latest, entry) =>
          latest == null || entry.createdAt.isAfter(latest.createdAt)
              ? entry
              : latest,
    );
    final loggedMealsToday =
        todayMealEntry != null && todayMealEntry.hasRecords;

    final entryDays = entries.map((entry) => normalizeDay(entry.date)).toSet();
    final latestTrainingDay = entryDays.isEmpty
        ? null
        : entryDays.reduce((latest, day) => day.isAfter(latest) ? day : latest);
    var streakDays = 0;
    DateTime? cursor = latestTrainingDay;
    while (cursor != null && entryDays.contains(cursor)) {
      streakDays++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    final latestTrainingGapDays = latestTrainingDay == null
        ? null
        : today.difference(latestTrainingDay).inDays;
    final recentTrainingMarkers = List<DailyLoopTrainingMarker>.generate(5, (
      index,
    ) {
      final day = today.subtract(Duration(days: 4 - index));
      return DailyLoopTrainingMarker(
        day: day,
        recorded: entryDays.contains(day),
      );
    });

    final todayPlans = plans.where((plan) {
      final day = normalizeDay(plan.scheduledAt);
      return day == today;
    }).toList(growable: false)
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final remainingTodayPlans = todayPlans
        .where(
          (plan) => !isPlanCoveredByTrainingEntry(
            plan,
            entries,
            now: effectiveNow,
          ),
        )
        .toList(growable: false);
    final todayPlanCount = remainingTodayPlans.length;
    final quizCompletedToday = quizCompletedAt != null &&
        quizCompletedAt.year == effectiveNow.year &&
        quizCompletedAt.month == effectiveNow.month &&
        quizCompletedAt.day == effectiveNow.day;
    final reviewedTodayDiary = viewedDiaryDayToken == dayToken(effectiveNow);
    final loggedBoardToday = sortedBoards.isNotEmpty &&
        sortedBoards.first.updatedAt.year == effectiveNow.year &&
        sortedBoards.first.updatedAt.month == effectiveNow.month &&
        sortedBoards.first.updatedAt.day == effectiveNow.day;

    return DailyLoopSnapshot(
      weeklyTrainingCount: weeklyEntries.length,
      weeklyMinutes: weeklyMinutes,
      streakDays: streakDays,
      latestTrainingDay: latestTrainingDay,
      latestTrainingGapDays: latestTrainingGapDays,
      recentTrainingMarkers: recentTrainingMarkers,
      boardCount: sortedBoards.length,
      latestBoardUpdatedAt:
          sortedBoards.isEmpty ? null : sortedBoards.first.updatedAt,
      latestBoard: sortedBoards.isEmpty ? null : sortedBoards.first,
      todayPlanCount: todayPlanCount,
      todayPlans: remainingTodayPlans,
      latestTrainingEntry: latestTrainingEntry,
      latestCreatedTrainingEntry: latestCreatedTrainingEntry,
      loggedTrainingToday: loggedTrainingToday,
      loggedLiftingToday: loggedLiftingToday,
      loggedJumpRopeToday: loggedJumpRopeToday,
      loggedMealsToday: loggedMealsToday,
      openedNewsToday: openedNewsToday,
      reviewedTodayDiary: reviewedTodayDiary,
      quizCompletedToday: quizCompletedToday,
      loggedBoardToday: loggedBoardToday,
      todayMealEntry: todayMealEntry,
      quizResumeSummary: quizResumeSummary,
    );
  }

  static DateTime normalizeDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String dayToken(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static bool isPlanCoveredByTrainingEntry(
    DailyLoopPlan plan,
    Iterable<TrainingEntry> entries, {
    DateTime? now,
  }) {
    final planDay = normalizeDay(plan.scheduledAt);
    final normalizedCategory = plan.category.trim().toLowerCase();
    var hasTrainingEntryOnPlanDay = false;
    for (final entry in entries) {
      if (entry.isMatch) continue;
      final entryDay = normalizeDay(entry.date);
      if (entryDay != planDay) continue;
      hasTrainingEntryOnPlanDay = true;
      if (normalizedCategory.isEmpty) {
        return true;
      }
      final entryType = entry.type.trim().toLowerCase();
      final entryProgram = entry.program.trim().toLowerCase();
      final entryPrograms = entry.effectiveTrainingProgramMinutes.keys
          .map((program) => program.trim().toLowerCase())
          .where((program) => program.isNotEmpty)
          .toSet();
      final categoryMatches = normalizedCategory.isEmpty ||
          entryType == normalizedCategory ||
          entryProgram == normalizedCategory ||
          entryPrograms.contains(normalizedCategory);
      if (categoryMatches) {
        return true;
      }
    }
    return hasTrainingEntryOnPlanDay &&
        (now ?? DateTime.now()).isAfter(plan.endsAt);
  }

  static bool hasCompletedJumpRope(TrainingEntry entry) {
    if (!entry.jumpRopeEnabled) return false;
    return entry.jumpRopeCount > 0 || entry.jumpRopeMinutes > 0;
  }
}

class DailyLoopPlan {
  final String id;
  final DateTime scheduledAt;
  final String category;
  final int durationMinutes;
  final String location;
  final String note;

  const DailyLoopPlan({
    required this.id,
    required this.scheduledAt,
    required this.category,
    required this.durationMinutes,
    required this.location,
    required this.note,
  });

  DateTime get endsAt => scheduledAt.add(Duration(minutes: durationMinutes));

  factory DailyLoopPlan.fromMap(
    Map<String, dynamic> map, {
    DateTime? fallbackNow,
  }) {
    final now = fallbackNow ?? DateTime.now();
    return DailyLoopPlan(
      id: map['id']?.toString() ?? now.microsecondsSinceEpoch.toString(),
      scheduledAt:
          DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ?? now,
      category: map['category']?.toString() ?? '',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 60,
      location: map['location']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
    );
  }
}

class DailyLoopTrainingMarker {
  final DateTime day;
  final bool recorded;

  const DailyLoopTrainingMarker({required this.day, required this.recorded});
}
