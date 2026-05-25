import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/domain/progression/player_progression_rules.dart';

void main() {
  TrainingEntry entryForDay(
    DateTime day, {
    String type = 'Passing',
    Map<String, int> liftingByPart = const <String, int>{},
    int jumpRopeCount = 0,
    bool breakfastDone = false,
    int breakfastRiceBowls = 0,
    bool lunchDone = false,
    int lunchRiceBowls = 0,
    bool dinnerDone = false,
    int dinnerRiceBowls = 0,
  }) {
    return TrainingEntry(
      date: day,
      createdAt: DateTime(day.year, day.month, day.day, 18),
      durationMinutes: 45,
      intensity: 4,
      type: type,
      mood: 4,
      injury: false,
      notes: '',
      location: 'Pitch',
      liftingByPart: liftingByPart,
      jumpRopeCount: jumpRopeCount,
      jumpRopeEnabled: jumpRopeCount > 0,
      breakfastDone: breakfastDone,
      breakfastRiceBowls: breakfastRiceBowls,
      lunchDone: lunchDone,
      lunchRiceBowls: lunchRiceBowls,
      dinnerDone: dinnerDone,
      dinnerRiceBowls: dinnerRiceBowls,
    );
  }

  test('training log evaluation keeps rule state changes explicit', () {
    final day = DateTime(2026, 3, 25);
    final awardedStreaks = <String>{};
    final awardedRoutineDays = <String>{};

    final result = PlayerProgressionRules.evaluateTrainingLog(
      entry: entryForDay(
        day,
        liftingByPart: const <String, int>{'right': 30},
        jumpRopeCount: 120,
      ),
      existingEntries: <TrainingEntry>[
        entryForDay(day.subtract(const Duration(days: 2)), type: 'Dribble'),
        entryForDay(day.subtract(const Duration(days: 1)), type: 'Shooting'),
      ],
      hasPlanOnDay: true,
      mealXp: 8,
      mealReason: 'meal_full_day',
      awardedStreaks: awardedStreaks,
      awardedRoutineDays: awardedRoutineDays,
    );

    expect(result.requestedXp, 91);
    expect(
      result.reasons,
      containsAll(<String>[
        'log',
        'first_daily_log',
        'plan_completed',
        'lifting_recorded',
        'jump_rope_recorded',
        'meal_full_day',
        'streak_daily_2_3',
        'routine_complete_day',
        'streak_3',
        'weekly_3',
      ]),
    );
    expect(result.streakTokensToAward, <String>['2026-03-25:3']);
    expect(result.routineDayTokensToAward, <String>['2026-03-25']);
    expect(awardedStreaks, isEmpty);
    expect(awardedRoutineDays, isEmpty);
  });

  test('training update evaluation awards only newly completed parts', () {
    final day = DateTime(2026, 4, 2);

    final result = PlayerProgressionRules.evaluateTrainingLogUpdate(
      previousEntry: entryForDay(day),
      updatedEntry: entryForDay(
        day,
        liftingByPart: const <String, int>{'left': 20},
        jumpRopeCount: 80,
      ),
      previousMealXp: 0,
      updatedMealXp: 8,
      updatedMealReason: 'meal_full_day',
      awardedRoutineDays: <String>{},
    );

    expect(result.requestedXp, 26);
    expect(result.reasons, <String>[
      'lifting_added',
      'jump_rope_added',
      'meal_full_day',
      'routine_complete_day',
    ]);
    expect(result.routineDayTokensToAward, <String>['2026-04-02']);
  });

  test('match evaluation separates first save from detail updates', () {
    final day = DateTime(2026, 5, 3);
    final updatedEntry = TrainingEntry(
      date: day,
      createdAt: DateTime(2026, 5, 3, 20),
      durationMinutes: 70,
      intensity: 5,
      type: 'Match',
      mood: 4,
      injury: false,
      notes: '',
      location: 'Pitch',
      opponentTeam: 'Rivals',
      scoredGoals: 2,
      concededGoals: 1,
      playerAssists: 1,
    );

    final result = PlayerProgressionRules.evaluateMatchLog(
      previousEntry: null,
      updatedEntry: updatedEntry,
      isNewMatchToken: true,
    );

    expect(
      result.requestedXp,
      PlayerProgressionRules.matchLogSavedXp +
          (PlayerProgressionRules.matchDetailRecordedXp * 2),
    );
    expect(result.reasons, <String>[
      'match_logged',
      'match_result_recorded',
      'match_contribution_recorded',
    ]);
  });
}
