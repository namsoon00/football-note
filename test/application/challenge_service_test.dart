import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/challenge_service.dart';
import 'package:football_note/application/player_level_service.dart';
import 'package:football_note/domain/entities/challenge.dart';
import 'package:football_note/domain/entities/meal_entry.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/domain/repositories/option_repository.dart';

void main() {
  test('default templates provide 3, 7, and 14 day challenges', () {
    final service = ChallengeService(_MemoryOptionRepository());

    final templates = service.templates();

    expect(templates.map((template) => template.dayCount), <int>[3, 7, 14]);
    expect(templates[0].rounds, hasLength(3));
    expect(templates[1].rounds, hasLength(7));
    expect(templates[2].rounds, hasLength(14));
    expect(
      templates.map((template) => template.rewardXpPerRound),
      <int>[10, 10, 10],
    );
  });

  test('training levels scale targets and completion rewards', () {
    final service = ChallengeService(_MemoryOptionRepository());
    final template = service.templateById('starter_3')!;
    final baseRound = template.rounds.first;

    final rookie = service.roundForLevel(
      baseRound,
      ChallengeTrainingLevel.rookie,
    );
    final ace = service.roundForLevel(baseRound, ChallengeTrainingLevel.ace);

    expect(rookie.targetTrainingMinutes, 20);
    expect(
        ace.targetTrainingMinutes, greaterThan(rookie.targetTrainingMinutes));
    expect(rookie.rewardXp, 10);
    expect(ace.rewardXp, 24);
    expect(
      service.completionBonusXpFor(template, ChallengeTrainingLevel.ace),
      greaterThan(
        service.completionBonusXpFor(template, ChallengeTrainingLevel.rookie),
      ),
    );
  });

  test('progress is completed only when every mission goal is met', () async {
    final service = ChallengeService(_MemoryOptionRepository());
    final template = service.templateById('starter_3')!;
    final startDay = DateTime(2026, 6, 1, 9);
    final run = await service.startChallenge(template, startedAt: startDay);

    final progress = service.progressForRun(
      run: run,
      trainingEntries: <TrainingEntry>[
        _trainingEntry(
          day: DateTime(2026, 6, 1),
          minutes: 20,
          jumpRopeMinutes: 5,
          liftingMinutes: 5,
        ),
        _trainingEntry(
          day: DateTime(2026, 6, 2),
          minutes: 25,
          jumpRopeMinutes: 6,
          liftingMinutes: 6,
        ),
      ],
      mealEntries: <MealEntry>[
        MealEntry(
          date: DateTime(2026, 6, 1),
          breakfastRiceBowls: 1,
          lunchRiceBowls: 1,
        ),
        MealEntry(
          date: DateTime(2026, 6, 2),
          breakfastRiceBowls: 1,
        ),
      ],
    )!;

    expect(progress.rounds[0].trainingCompleted, isTrue);
    expect(progress.rounds[0].jumpRopeCompleted, isTrue);
    expect(progress.rounds[0].liftingCompleted, isTrue);
    expect(progress.rounds[0].mealCompleted, isTrue);
    expect(progress.rounds[0].completed, isTrue);
    expect(progress.rounds[1].trainingCompleted, isTrue);
    expect(progress.rounds[1].jumpRopeCompleted, isTrue);
    expect(progress.rounds[1].liftingCompleted, isTrue);
    expect(progress.rounds[1].mealCompleted, isFalse);
    expect(progress.rounds[1].completed, isFalse);
    expect(progress.completedRoundCount, 1);
  });

  test('completed round awards xp once', () async {
    final repository = _MemoryOptionRepository();
    final service = ChallengeService(repository);
    final levelService = PlayerLevelService(repository);
    final template = service.templateById('starter_3')!;
    final run = await service.startChallenge(
      template,
      startedAt: DateTime(2026, 6, 1, 9),
    );
    final progress = service.progressForRun(
      run: run,
      trainingEntries: <TrainingEntry>[
        _trainingEntry(
          day: DateTime(2026, 6, 1),
          minutes: 20,
          jumpRopeMinutes: 5,
          liftingMinutes: 5,
        ),
      ],
      mealEntries: <MealEntry>[
        MealEntry(
          date: DateTime(2026, 6, 1),
          breakfastRiceBowls: 1,
          lunchRiceBowls: 1,
        ),
      ],
    )!;

    final firstAwards = await service.awardCompletedRounds(
      progress: progress,
      playerLevelService: levelService,
      awardedAt: DateTime(2026, 6, 1, 21),
    );
    final duplicateAwards = await service.awardCompletedRounds(
      progress: progress,
      playerLevelService: levelService,
      awardedAt: DateTime(2026, 6, 1, 22),
    );

    expect(firstAwards.single.gainedXp, 10);
    expect(duplicateAwards.single.gainedXp, 0);
    expect(levelService.loadState().totalXp, 10);
    expect(levelService.loadXpHistory(), hasLength(1));
    expect(
      levelService.loadXpHistory().single.category,
      PlayerXpHistoryCategory.challenge,
    );
  });

  test('all completed rounds finish the active challenge', () async {
    final repository = _MemoryOptionRepository();
    final service = ChallengeService(repository);
    final levelService = PlayerLevelService(repository);
    final template = service.templateById('starter_3')!;
    final run = await service.startChallenge(
      template,
      startedAt: DateTime(2026, 6, 1, 9),
    );

    final progress = service.progressForRun(
      run: run,
      trainingEntries: <TrainingEntry>[
        _trainingEntry(
          day: DateTime(2026, 6, 1),
          minutes: 20,
          jumpRopeMinutes: 5,
          liftingMinutes: 5,
        ),
        _trainingEntry(
          day: DateTime(2026, 6, 2),
          minutes: 25,
          jumpRopeMinutes: 6,
          liftingMinutes: 6,
        ),
        _trainingEntry(
          day: DateTime(2026, 6, 3),
          minutes: 30,
          jumpRopeMinutes: 8,
          liftingMinutes: 8,
        ),
      ],
      mealEntries: <MealEntry>[
        MealEntry(
          date: DateTime(2026, 6, 1),
          breakfastRiceBowls: 1,
          lunchRiceBowls: 1,
        ),
        MealEntry(
          date: DateTime(2026, 6, 2),
          breakfastRiceBowls: 1,
          lunchRiceBowls: 1,
          dinnerRiceBowls: 0.5,
        ),
        MealEntry(
          date: DateTime(2026, 6, 3),
          breakfastRiceBowls: 1,
          lunchRiceBowls: 1,
          dinnerRiceBowls: 1,
        ),
      ],
    )!;

    await service.awardCompletedRounds(
      progress: progress,
      playerLevelService: levelService,
      awardedAt: DateTime(2026, 6, 3, 21),
    );

    expect(service.activeRun(), isNull);
    expect(service.latestCompletedRun(), isNotNull);
    expect(levelService.loadState().totalXp, 150);
    expect(
      levelService.loadXpHistory().map((entry) => entry.reasons).expand(
            (reasons) => reasons,
          ),
      contains('challenge_completed_bonus'),
    );
  });

  test('missed expired round fails the active challenge', () async {
    final repository = _MemoryOptionRepository();
    final service = ChallengeService(repository);
    final template = service.templateById('starter_3')!;
    final run = await service.startChallenge(
      template,
      startedAt: DateTime(2026, 6, 1, 9),
    );
    final progress = service.progressForRun(
      run: run,
      trainingEntries: const <TrainingEntry>[],
      mealEntries: const <MealEntry>[],
    )!;
    final missed = progress.missedExpiredRound(now: DateTime(2026, 6, 2, 8));

    expect(missed?.round.number, 1);
    await service.failRun(
      run.id,
      roundNumber: missed!.round.number,
      failedAt: DateTime(2026, 6, 2, 8),
    );

    expect(service.activeRun(), isNull);
    final failed = service.loadRuns().single;
    expect(failed.isFailed, isTrue);
    expect(failed.failedRoundNumber, 1);
  });
}

TrainingEntry _trainingEntry({
  required DateTime day,
  required int minutes,
  int jumpRopeMinutes = 0,
  int liftingMinutes = 0,
}) {
  return TrainingEntry(
    date: day,
    durationMinutes: minutes,
    intensity: 3,
    type: '패스',
    mood: 3,
    injury: false,
    notes: '',
    location: '운동장',
    jumpRopeMinutes: jumpRopeMinutes,
    jumpRopeEnabled: jumpRopeMinutes > 0,
    liftingMinutes: liftingMinutes,
  );
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List<String>) return value;
    return defaults;
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List<int>) return value;
    return defaults;
  }

  @override
  T? getValue<T>(String key) => _values[key] as T?;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    _values[key] = options;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    _values[key] = value;
  }
}
