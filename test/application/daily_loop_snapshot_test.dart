import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/daily_loop/daily_loop_snapshot.dart';
import 'package:football_note/application/skill_quiz_resume_summary.dart';
import 'package:football_note/domain/entities/meal_entry.dart';
import 'package:football_note/domain/entities/training_board.dart';
import 'package:football_note/domain/entities/training_entry.dart';

void main() {
  const emptyQuizSummary = SkillQuizResumeSummary(
    hasActiveSession: false,
    reviewMode: false,
    currentIndex: 0,
    totalQuestions: 0,
    pendingWrongCount: 0,
  );

  TrainingEntry trainingEntry(
    DateTime day, {
    DateTime? createdAt,
    String type = 'Passing',
    String program = '',
    Map<String, int> liftingByPart = const <String, int>{},
    int liftingMinutes = 0,
    bool jumpRopeEnabled = false,
    int jumpRopeCount = 0,
    int jumpRopeMinutes = 0,
  }) {
    return TrainingEntry(
      date: day,
      createdAt: createdAt ?? day.add(const Duration(hours: 18)),
      durationMinutes: 60,
      intensity: 4,
      type: type,
      mood: 4,
      injury: false,
      notes: '',
      location: 'Pitch',
      program: program,
      liftingByPart: liftingByPart,
      liftingMinutes: liftingMinutes,
      jumpRopeEnabled: jumpRopeEnabled,
      jumpRopeCount: jumpRopeCount,
      jumpRopeMinutes: jumpRopeMinutes,
    );
  }

  DailyLoopSnapshot buildSnapshot({
    required DateTime now,
    List<TrainingEntry> entries = const <TrainingEntry>[],
    List<MealEntry> mealEntries = const <MealEntry>[],
    List<TrainingBoard> boards = const <TrainingBoard>[],
    DateTime? quizCompletedAt,
    String? viewedDiaryDayToken,
    bool openedNewsToday = false,
  }) {
    return DailyLoopSnapshot.build(
      entries: entries,
      mealEntries: mealEntries,
      boards: boards,
      quizCompletedAt: quizCompletedAt,
      viewedDiaryDayToken: viewedDiaryDayToken,
      quizResumeSummary: emptyQuizSummary,
      openedNewsToday: openedNewsToday,
      now: now,
    );
  }

  test('daily task summary combines training, conditioning, meal, and review',
      () {
    final now = DateTime(2026, 6, 17, 19);
    final today = DateTime(2026, 6, 17);
    final board = TrainingBoard(
      id: 'board-today',
      title: 'Today board',
      layoutJson: '{}',
      createdAt: today,
      updatedAt: now,
    );

    final snapshot = buildSnapshot(
      now: now,
      entries: <TrainingEntry>[
        trainingEntry(
          today,
          liftingMinutes: 12,
          jumpRopeEnabled: true,
          jumpRopeMinutes: 8,
        ),
      ],
      mealEntries: <MealEntry>[
        MealEntry(date: today, breakfastRiceBowls: 1),
      ],
      boards: <TrainingBoard>[board],
      quizCompletedAt: now,
      viewedDiaryDayToken: DailyLoopSnapshot.dayToken(now),
      openedNewsToday: true,
    );

    expect(snapshot.loggedTrainingToday, isTrue);
    expect(snapshot.loggedLiftingToday, isTrue);
    expect(snapshot.loggedJumpRopeToday, isTrue);
    expect(snapshot.loggedMealsToday, isTrue);
    expect(snapshot.quizCompletedToday, isTrue);
    expect(snapshot.reviewedTodayDiary, isTrue);
    expect(snapshot.loggedBoardToday, isTrue);
    expect(snapshot.dailyTaskCompletedCount, 8);
    expect(snapshot.completedDailyTasks, isTrue);
  });

  test('training streak and weekly minutes are calculated from entry days', () {
    final now = DateTime(2026, 6, 17, 8);
    final today = DateTime(2026, 6, 17);

    final snapshot = buildSnapshot(
      now: now,
      entries: <TrainingEntry>[
        trainingEntry(today),
        trainingEntry(today.subtract(const Duration(days: 1))),
        trainingEntry(today.subtract(const Duration(days: 2))),
      ],
    );

    expect(snapshot.weeklyTrainingCount, 3);
    expect(snapshot.weeklyMinutes, 180);
    expect(snapshot.streakDays, 3);
    expect(snapshot.latestTrainingGapDays, 0);
    expect(
      snapshot.recentTrainingMarkers.map((marker) => marker.recorded).toList(),
      <bool>[false, false, true, true, true],
    );
  });
}
