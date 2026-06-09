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
    expect(templates.map((template) => template.rewardXpPerRound), <int>[
      10,
      10,
      10,
    ]);
    expect(templates[2].rounds.first.targetTrainingMinutes, 30);
    expect(templates[2].rounds.last.targetTrainingMinutes, 30);
    expect(templates[2].rounds.first.targetJumpRopeMinutes, 10);
    expect(templates[2].rounds.last.targetLiftingMinutes, 10);
  });

  test('training levels use fixed targets and larger rewards', () {
    final service = ChallengeService(_MemoryOptionRepository());
    final template = service.templateById('starter_3')!;
    final baseRound = template.rounds.first;
    final lastBaseRound = template.rounds.last;

    final rookie = service.roundForLevel(
      baseRound,
      ChallengeTrainingLevel.rookie,
    );
    final lastRookie = service.roundForLevel(
      lastBaseRound,
      ChallengeTrainingLevel.rookie,
    );
    final growth = service.roundForLevel(
      baseRound,
      ChallengeTrainingLevel.growth,
    );
    final ace = service.roundForLevel(baseRound, ChallengeTrainingLevel.ace);

    expect(rookie.targetTrainingMinutes, 30);
    expect(rookie.targetJumpRopeMinutes, 10);
    expect(rookie.targetLiftingMinutes, 10);
    expect(lastRookie.targetTrainingMinutes, rookie.targetTrainingMinutes);
    expect(lastRookie.targetJumpRopeMinutes, rookie.targetJumpRopeMinutes);
    expect(growth.targetJumpRopeMinutes, 20);
    expect(growth.targetLiftingMinutes, 20);
    expect(ace.targetTrainingMinutes, 120);
    expect(ace.targetJumpRopeMinutes, 30);
    expect(ace.targetLiftingMinutes, 30);
    expect(rookie.rewardXp, 10);
    expect(ace.rewardXp, 24);
    expect(
      service.completionBonusXpFor(template, ChallengeTrainingLevel.ace),
      greaterThan(
        service.completionBonusXpFor(template, ChallengeTrainingLevel.rookie),
      ),
    );
  });

  test('consecutive round rewards grow with capped streak bonus', () {
    final service = ChallengeService(_MemoryOptionRepository());
    final template = service.templateById('starter_3')!;

    expect(challengeRoundStreakBonusXpFor(1), 0);
    expect(challengeRoundStreakBonusXpFor(3), 6);
    expect(challengeRoundStreakBonusXpFor(7), 15);
    expect(
      challengeRoundRewardXpFor(baseRewardXp: 10, consecutiveRoundNumber: 7),
      25,
    );
    expect(
      challengeTotalRoundRewardXpFor(template, ChallengeTrainingLevel.rookie),
      39,
    );
    expect(
      service.totalPotentialXpFor(template, ChallengeTrainingLevel.rookie),
      159,
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
          jumpRopeMinutes: 20,
          liftingMinutes: 20,
        ),
        _trainingEntry(
          day: DateTime(2026, 6, 2),
          minutes: 20,
          jumpRopeMinutes: 20,
          liftingMinutes: 20,
        ),
      ],
      mealEntries: <MealEntry>[
        MealEntry(
          date: DateTime(2026, 6, 1),
          breakfastRiceBowls: 1,
          lunchRiceBowls: 1,
          dinnerRiceBowls: 1,
        ),
        MealEntry(date: DateTime(2026, 6, 2), breakfastRiceBowls: 1),
      ],
    )!;

    expect(progress.rounds[0].trainingMinutes, 60);
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

  test(
    'program-based challenge skills count matching training records',
    () async {
      final service = ChallengeService(_MemoryOptionRepository());
      final template = service.templateById('starter_3')!;
      final run = await service.startChallenge(
        template,
        selectedSkillIds: <String>['전술'],
        startedAt: DateTime(2026, 6, 1, 9),
      );

      final progress = service.progressForRun(
        run: run,
        trainingEntries: <TrainingEntry>[
          _trainingEntry(
            day: DateTime(2026, 6, 1),
            minutes: 120,
            program: '기본기',
          ),
          _trainingEntry(
            day: DateTime(2026, 6, 1),
            minutes: 60,
            jumpRopeMinutes: 10,
            liftingMinutes: 10,
            program: '전술',
          ),
        ],
        mealEntries: <MealEntry>[
          MealEntry(
            date: DateTime(2026, 6, 1),
            breakfastRiceBowls: 1,
            lunchRiceBowls: 1,
            dinnerRiceBowls: 1,
          ),
        ],
      )!;

      final round = progress.rounds.first;
      expect(progress.run.selectedSkillIds, <String>['전술']);
      expect(round.trainingPrograms, hasLength(1));
      expect(round.trainingPrograms.single.label, '전술');
      expect(round.trainingPrograms.single.currentMinutes, 60);
      expect(round.trainingPrograms.single.targetMinutes, 30);
      expect(round.trainingPrograms.single.completed, isTrue);
      expect(round.trainingMinutes, 60);
      expect(round.completed, isTrue);
    },
  );

  test('custom mission targets can require only selected missions', () async {
    final service = ChallengeService(_MemoryOptionRepository());
    final template = service.templateById('starter_3')!;
    final run = await service.startChallenge(
      template,
      selectedSkillIds: const <String>[],
      missionTargets: const ChallengeMissionTargets(
        trainingMinutes: 0,
        jumpRopeMinutes: 15,
        liftingMinutes: 0,
        riceBowls: 0,
      ),
      startedAt: DateTime(2026, 6, 1, 9),
    );

    final progress = service.progressForRun(
      run: run,
      trainingEntries: <TrainingEntry>[
        _trainingEntry(
          day: DateTime(2026, 6, 1),
          minutes: 0,
          jumpRopeMinutes: 15,
          liftingMinutes: 0,
          program: '기본기',
        ),
      ],
      mealEntries: const <MealEntry>[],
    )!;

    expect(progress.run.selectedSkillIds, isEmpty);
    expect(progress.rounds.first.round.targetTrainingMinutes, 0);
    expect(progress.rounds.first.round.targetJumpRopeMinutes, 15);
    expect(progress.rounds.first.trainingCompleted, isTrue);
    expect(progress.rounds.first.jumpRopeCompleted, isTrue);
    expect(progress.rounds.first.liftingCompleted, isTrue);
    expect(progress.rounds.first.mealCompleted, isTrue);
    expect(progress.rounds.first.completed, isTrue);
    expect(progress.rounds.first.completedMissionCount, 1);
    expect(progress.rounds.first.missionCount, 1);
  });

  test('program missions use stored per-program target minutes', () async {
    final service = ChallengeService(_MemoryOptionRepository());
    final template = service.templateById('starter_3')!;
    await service.startChallenge(
      template,
      selectedSkillIds: <String>['전술', '패스', '슈팅'],
      missionTargets: const ChallengeMissionTargets(
        trainingMinutes: 90,
        trainingProgramMinutes: <String, int>{'전술': 30, '패스': 45, '슈팅': 15},
        jumpRopeMinutes: 0,
        liftingMinutes: 0,
        riceBowls: 0,
      ),
      startedAt: DateTime(2026, 6, 1, 9),
    );
    final run = service.activeRun()!;

    final progress = service.progressForRun(
      run: run,
      trainingEntries: <TrainingEntry>[
        _trainingEntry(day: DateTime(2026, 6, 1), minutes: 120, program: '기본기'),
        _trainingEntry(day: DateTime(2026, 6, 1), minutes: 30, program: '전술'),
        _trainingEntry(day: DateTime(2026, 6, 1), minutes: 45, program: '패스'),
        _trainingEntry(day: DateTime(2026, 6, 1), minutes: 10, program: '슈팅'),
      ],
      mealEntries: const <MealEntry>[],
    )!;

    final round = progress.rounds.first;
    expect(round.trainingPrograms.map((mission) => mission.label), <String>[
      '전술',
      '패스',
      '슈팅',
    ]);
    expect(
      round.trainingPrograms.map((mission) => mission.targetMinutes),
      <int>[30, 45, 15],
    );
    expect(
      round.trainingPrograms.map((mission) => mission.currentMinutes),
      <int>[30, 45, 10],
    );
    expect(round.trainingMinutes, 85);
    expect(round.trainingCompleted, isFalse);
    expect(round.completedMissionCount, 2);
    expect(round.missionCount, 3);
  });

  test(
    'program missions can be completed from one multi-program note',
    () async {
      final service = ChallengeService(_MemoryOptionRepository());
      final template = service.templateById('starter_3')!;
      final run = await service.startChallenge(
        template,
        selectedSkillIds: <String>['전술', '패스', '슈팅'],
        missionTargets: const ChallengeMissionTargets(
          trainingMinutes: 90,
          trainingProgramMinutes: <String, int>{'전술': 30, '패스': 45, '슈팅': 15},
          jumpRopeMinutes: 0,
          liftingMinutes: 0,
          riceBowls: 0,
        ),
        startedAt: DateTime(2026, 6, 1, 9),
      );

      final progress = service.progressForRun(
        run: run,
        trainingEntries: <TrainingEntry>[
          _trainingEntry(
            day: DateTime(2026, 6, 1),
            minutes: 90,
            program: '전술',
            trainingProgramMinutes: const <String, int>{
              '전술': 30,
              '패스': 45,
              '슈팅': 15,
            },
          ),
        ],
        mealEntries: const <MealEntry>[],
      )!;

      final round = progress.rounds.first;
      expect(
        round.trainingPrograms.map((mission) => mission.currentMinutes),
        <int>[30, 45, 15],
      );
      expect(round.trainingMinutes, 90);
      expect(round.trainingCompleted, isTrue);
      expect(round.completed, isTrue);
    },
  );

  test('finalization waits until the challenge is ready to end', () async {
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
          jumpRopeMinutes: 20,
          liftingMinutes: 20,
        ),
      ],
      mealEntries: <MealEntry>[
        MealEntry(
          date: DateTime(2026, 6, 1),
          breakfastRiceBowls: 1,
          lunchRiceBowls: 1,
          dinnerRiceBowls: 1,
        ),
      ],
    )!;

    final awards = await service.finalizeRun(
      progress: progress,
      playerLevelService: levelService,
      finalizedAt: DateTime(2026, 6, 2, 8),
    );

    expect(awards, isEmpty);
    expect(service.activeRun(), isNotNull);
    expect(levelService.loadState().totalXp, 0);
    expect(levelService.loadXpHistory(), isEmpty);
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
          jumpRopeMinutes: 20,
          liftingMinutes: 20,
        ),
        _trainingEntry(
          day: DateTime(2026, 6, 2),
          minutes: 20,
          jumpRopeMinutes: 20,
          liftingMinutes: 20,
        ),
        _trainingEntry(
          day: DateTime(2026, 6, 3),
          minutes: 20,
          jumpRopeMinutes: 20,
          liftingMinutes: 20,
        ),
      ],
      mealEntries: <MealEntry>[
        MealEntry(
          date: DateTime(2026, 6, 1),
          breakfastRiceBowls: 1,
          lunchRiceBowls: 1,
          dinnerRiceBowls: 1,
        ),
        MealEntry(
          date: DateTime(2026, 6, 2),
          breakfastRiceBowls: 1,
          lunchRiceBowls: 1,
          dinnerRiceBowls: 1,
        ),
        MealEntry(
          date: DateTime(2026, 6, 3),
          breakfastRiceBowls: 1,
          lunchRiceBowls: 1,
          dinnerRiceBowls: 1,
        ),
      ],
    )!;

    await service.finalizeRun(
      progress: progress,
      playerLevelService: levelService,
      finalizedAt: DateTime(2026, 6, 3, 21),
    );

    expect(service.activeRun(), isNull);
    expect(service.latestCompletedRun(), isNotNull);
    expect(levelService.loadState().totalXp, 159);
    expect(
      levelService
          .loadXpHistory()
          .map((entry) => entry.reasons)
          .expand((reasons) => reasons),
      contains('challenge_completed_bonus'),
    );
    expect(
      levelService
          .loadXpHistory()
          .map((entry) => entry.reasons)
          .expand((reasons) => reasons),
      contains('challenge_round_streak_bonus'),
    );
  });

  test(
    'partially completed challenge continues and settles after final day',
    () async {
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
            jumpRopeMinutes: 20,
            liftingMinutes: 20,
          ),
          _trainingEntry(
            day: DateTime(2026, 6, 3),
            minutes: 20,
            jumpRopeMinutes: 20,
            liftingMinutes: 20,
          ),
        ],
        mealEntries: <MealEntry>[
          MealEntry(
            date: DateTime(2026, 6, 1),
            breakfastRiceBowls: 1,
            lunchRiceBowls: 1,
            dinnerRiceBowls: 1,
          ),
          MealEntry(
            date: DateTime(2026, 6, 3),
            breakfastRiceBowls: 1,
            lunchRiceBowls: 1,
            dinnerRiceBowls: 1,
          ),
        ],
      )!;
      final missed = progress.missedExpiredRound(now: DateTime(2026, 6, 3, 8));

      expect(missed?.round.number, 2);
      final earlyAwards = await service.finalizeRun(
        progress: progress,
        playerLevelService: levelService,
        finalizedAt: DateTime(2026, 6, 3, 8),
      );
      expect(earlyAwards, isEmpty);
      expect(service.activeRun(), isNotNull);

      final finalAwards = await service.finalizeRun(
        progress: progress,
        playerLevelService: levelService,
        finalizedAt: DateTime(2026, 6, 4, 8),
      );

      expect(service.activeRun(), isNull);
      final failed = service.loadRuns().single;
      expect(failed.isFailed, isTrue);
      expect(failed.failedRoundNumber, 2);
      expect(
        finalAwards.map((award) => award.gainedXp).where((xp) => xp > 0),
        <int>[10, 10],
      );
      expect(levelService.loadState().totalXp, 20);
    },
  );
}

TrainingEntry _trainingEntry({
  required DateTime day,
  required int minutes,
  int jumpRopeMinutes = 0,
  int liftingMinutes = 0,
  String program = '패스',
  Map<String, int> trainingProgramMinutes = const <String, int>{},
}) {
  return TrainingEntry(
    date: day,
    durationMinutes: minutes,
    intensity: 3,
    type: program,
    mood: 3,
    injury: false,
    notes: '',
    location: '운동장',
    program: program,
    trainingProgramMinutes: trainingProgramMinutes,
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
