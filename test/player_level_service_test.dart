import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/player_level_service.dart';
import 'package:football_note/domain/entities/training_entry.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations_ko.dart';
import 'package:football_note/presentation/localization/player_progression_localizations.dart';

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 18);

  test('reward becomes available and can be claimed once', () async {
    final repository = _MemoryOptionRepository()
      ..seed(PlayerLevelService.totalXpKey, 40);
    final service = PlayerLevelService(repository);
    await service.setCustomRewardName(2, '새 축구 양말');

    final statuses = service.loadRewardStatuses();
    final level2Reward = statuses.firstWhere((item) => item.reward.level == 2);
    final level4Reward = statuses.firstWhere((item) => item.reward.level == 4);
    final level1Reward = statuses.firstWhere((item) => item.reward.level == 1);

    expect(level2Reward.isAvailable, isTrue);
    expect(level2Reward.isClaimed, isFalse);
    expect(level4Reward.isAvailable, isFalse);
    expect(level1Reward.customRewardName, isEmpty);

    final claim = await service.claimRewardForLevel(2);
    final secondClaim = await service.claimRewardForLevel(2);

    expect(claim, isNotNull);
    expect(claim!.reward.level, 2);
    expect(secondClaim, isNull);
    expect(
      repository.getValue<List>(PlayerLevelService.claimedRewardLevelsKey),
      contains(2),
    );
    final claimMessages = repository.getValue<List>(
      PlayerLevelService.rewardClaimMessagesKey,
    );
    expect(claimMessages, isNotNull);
    expect(claimMessages, hasLength(1));
    expect((claimMessages!.single as Map)['level'], 2);
    expect((claimMessages.single as Map)['rewardName'], '새 축구 양말');
  });

  test('custom reward name is stored and returned on claim', () async {
    final repository = _MemoryOptionRepository()
      ..seed(PlayerLevelService.totalXpKey, 40);
    final service = PlayerLevelService(repository);

    await service.setCustomRewardName(2, '새 축구 양말');
    final statuses = service.loadRewardStatuses();
    final level2Reward = statuses.firstWhere((item) => item.reward.level == 2);
    final claim = await service.claimRewardForLevel(2);

    expect(level2Reward.customRewardName, '새 축구 양말');
    expect(service.customRewardNameForLevel(2), '새 축구 양말');
    expect(claim, isNotNull);
    expect(claim!.customRewardName, '새 축구 양말');
  });

  test('claim is blocked when reward name is empty', () async {
    final repository = _MemoryOptionRepository()
      ..seed(PlayerLevelService.totalXpKey, 40);
    final service = PlayerLevelService(repository);

    final claim = await service.claimRewardForLevel(2);

    expect(claim, isNull);
  });

  test('level thresholds now support up to level 20', () {
    expect(PlayerLevelService.levelThresholds, hasLength(20));
    expect(PlayerLevelState.fromXp(9600).level, 20);
    expect(PlayerLevelState.fromXp(15000).level, 20);
  });

  test('max level continues with mastery stars', () {
    final state = PlayerLevelState.fromXp(10650);

    expect(state.level, 20);
    expect(state.isMaxLevel, isTrue);
    expect(state.maxLevelExtraXp, 1050);
    expect(state.masteryStars, 2);
    expect(state.xpToNextMasteryStar, 450);
    expect(state.xpToNextLevel, 450);
  });

  test('illustration labels are unique through level 20', () {
    final l10n = AppLocalizationsKo();
    final labels = <String>{
      for (var level = 1; level <= 20; level++)
        l10n.playerLevelIllustrationLabel(level),
    };

    expect(labels, hasLength(20));
  });

  test(
    'training log deducts xp when lifting and jump rope are skipped',
    () async {
      final repository = _MemoryOptionRepository()
        ..seed(PlayerLevelService.totalXpKey, 100);
      final service = PlayerLevelService(repository);

      final award = await service.awardForTrainingLog(
        entry: TrainingEntry(
          date: today,
          durationMinutes: 40,
          intensity: 3,
          type: '패스',
          mood: 3,
          injury: false,
          notes: '',
          location: '운동장',
        ),
        existingEntries: const [],
      );

      expect(award.gainedXp, 10);
      expect(
        award.reasons,
        containsAll(<String>['lifting_missed', 'jump_rope_missed']),
      );
      expect(service.loadState().totalXp, 110);
    },
  );

  test('xp history is appended for training rewards', () async {
    final repository = _MemoryOptionRepository()
      ..seed(PlayerLevelService.totalXpKey, 100);
    final service = PlayerLevelService(repository);

    await service.awardForTrainingLog(
      entry: TrainingEntry(
        date: today,
        createdAt: DateTime(today.year, today.month, today.day, 18, 30),
        durationMinutes: 55,
        intensity: 4,
        type: '패스',
        program: '원터치 패스',
        mood: 4,
        injury: false,
        notes: '',
        location: '운동장',
        liftingByPart: const {'inside': 40},
        jumpRopeCount: 120,
        jumpRopeEnabled: true,
      ),
      existingEntries: const [],
    );

    final history = service.loadXpHistory();

    expect(history, hasLength(1));
    expect(history.first.category, PlayerXpHistoryCategory.training);
    expect(history.first.label, '원터치 패스');
    expect(history.first.totalXp, 132);
    expect(
      history.first.reasons,
      containsAll(<String>['log', 'lifting_recorded', 'jump_rope_recorded']),
    );
  });

  test(
    'older training entry does not inherit streak from later records',
    () async {
      final repository = _MemoryOptionRepository()
        ..seed(PlayerLevelService.totalXpKey, 100);
      final service = PlayerLevelService(repository);
      final oldDay = today.subtract(const Duration(days: 2));
      final existingEntries = <TrainingEntry>[
        TrainingEntry(
          date: today,
          durationMinutes: 45,
          intensity: 4,
          type: '패스',
          mood: 4,
          injury: false,
          notes: '',
          location: '운동장',
        ),
        TrainingEntry(
          date: today.subtract(const Duration(days: 1)),
          durationMinutes: 45,
          intensity: 4,
          type: '드리블',
          mood: 4,
          injury: false,
          notes: '',
          location: '운동장',
        ),
      ];

      final award = await service.awardForTrainingLog(
        entry: TrainingEntry(
          date: oldDay,
          durationMinutes: 45,
          intensity: 4,
          type: '슈팅',
          mood: 4,
          injury: false,
          notes: '',
          location: '운동장',
        ),
        existingEntries: existingEntries,
      );

      expect(
        award.reasons.where((reason) => reason.startsWith('streak')),
        isEmpty,
      );
    },
  );

  test('meal logging adds training xp bonus', () async {
    final repository = _MemoryOptionRepository()
      ..seed(PlayerLevelService.totalXpKey, 100);
    final service = PlayerLevelService(repository);

    final award = await service.awardForTrainingLog(
      entry: TrainingEntry(
        date: today,
        durationMinutes: 55,
        intensity: 4,
        type: '패스',
        mood: 4,
        injury: false,
        notes: '',
        location: '운동장',
        liftingByPart: const {'inside': 20},
        jumpRopeCount: 120,
        jumpRopeEnabled: true,
        breakfastDone: true,
        breakfastRiceBowls: 1,
        lunchDone: true,
        lunchRiceBowls: 1,
        dinnerDone: true,
        dinnerRiceBowls: 2,
      ),
      existingEntries: const [],
    );

    expect(award.gainedXp, 46);
    expect(award.reasons, contains('meal_full_day'));
    expect(service.loadState().totalXp, 146);
  });

  test(
    'training log update restores xp for newly added lifting and jump rope',
    () async {
      final repository = _MemoryOptionRepository()
        ..seed(PlayerLevelService.totalXpKey, 100);
      final service = PlayerLevelService(repository);

      final award = await service.awardForTrainingLogUpdate(
        previousEntry: TrainingEntry(
          date: today,
          durationMinutes: 55,
          intensity: 4,
          type: '패스',
          mood: 4,
          injury: false,
          notes: '',
          location: '운동장',
        ),
        updatedEntry: TrainingEntry(
          date: today,
          createdAt: DateTime(today.year, today.month, today.day, 19),
          durationMinutes: 55,
          intensity: 4,
          type: '패스',
          program: '원터치 패스',
          mood: 4,
          injury: false,
          notes: '',
          location: '운동장',
          liftingByPart: const {'inside': 40},
          jumpRopeCount: 120,
          jumpRopeEnabled: true,
        ),
      );

      expect(award.gainedXp, 12);
      expect(
        award.reasons,
        containsAll(<String>['lifting_added', 'jump_rope_added']),
      );
      expect(service.loadState().totalXp, 112);

      final history = service.loadXpHistory();
      expect(history, hasLength(1));
      expect(history.first.label, '원터치 패스');
      expect(history.first.reasons, contains('lifting_added'));
    },
  );

  test(
    'training log update awards meal bonus when meal records are added',
    () async {
      final repository = _MemoryOptionRepository()
        ..seed(PlayerLevelService.totalXpKey, 100);
      final service = PlayerLevelService(repository);

      final award = await service.awardForTrainingLogUpdate(
        previousEntry: TrainingEntry(
          date: today,
          durationMinutes: 55,
          intensity: 4,
          type: '패스',
          mood: 4,
          injury: false,
          notes: '',
          location: '운동장',
        ),
        updatedEntry: TrainingEntry(
          date: today,
          createdAt: DateTime(today.year, today.month, today.day, 19),
          durationMinutes: 55,
          intensity: 4,
          type: '패스',
          mood: 4,
          injury: false,
          notes: '',
          location: '운동장',
          breakfastDone: true,
          breakfastRiceBowls: 1,
          lunchDone: true,
          lunchRiceBowls: 1,
        ),
      );

      expect(award.gainedXp, 3);
      expect(award.reasons, contains('meal_two_plus'));
      expect(service.loadState().totalXp, 103);
    },
  );

  test(
    'board save and diary creation awards are tracked once per day',
    () async {
      final repository = _MemoryOptionRepository();
      final service = PlayerLevelService(repository);

      final boardAward = await service.awardForBoardSaved(
        boardId: 'board-1',
        boardTitle: '측면 전개',
        savedAt: DateTime(2026, 3, 22, 10),
        created: true,
      );
      final boardAwardDuplicate = await service.awardForBoardSaved(
        boardId: 'board-1',
        boardTitle: '측면 전개',
        savedAt: DateTime(2026, 3, 22, 18),
      );
      final diaryAward = await service.awardForDiaryCreated(
        createdAt: DateTime(today.year, today.month, today.day, 21),
      );
      final diaryAwardDuplicate = await service.awardForDiaryCreated(
        createdAt: DateTime(today.year, today.month, today.day, 22),
      );

      expect(boardAward.gainedXp, 5);
      expect(boardAwardDuplicate.gainedXp, 0);
      expect(diaryAward.gainedXp, 3);
      expect(diaryAwardDuplicate.gainedXp, 0);
      expect(service.loadState().totalXp, 8);

      final history = service.loadXpHistory();
      expect(history, hasLength(2));
      expect(history.first.category, PlayerXpHistoryCategory.diary);
      expect(history.last.category, PlayerXpHistoryCategory.board);
    },
  );

  test('quiz completion awards xp on the completed day token', () async {
    final repository = _MemoryOptionRepository();
    final service = PlayerLevelService(repository);

    final award = await service.awardForQuizCompletion(
      completedAt: DateTime(2026, 3, 24, 23, 55),
    );
    final duplicate = await service.awardForQuizCompletion(
      completedAt: DateTime(2026, 3, 24, 23, 59),
    );
    final nextDay = await service.awardForQuizCompletion(
      completedAt: DateTime(2026, 3, 25, 0, 5),
    );

    expect(award.gainedXp, 8);
    expect(duplicate.gainedXp, 0);
    expect(nextDay.gainedXp, 8);
    expect(service.loadState().totalXp, 16);

    final history = service.loadXpHistory();
    expect(history, hasLength(2));
    expect(history.first.category, PlayerXpHistoryCategory.quiz);
    expect(history.first.awardedAt.day, 25);
    expect(history.last.awardedAt.day, 24);
  });

  test('daily task completion awards xp once per day', () async {
    final repository = _MemoryOptionRepository();
    final service = PlayerLevelService(repository);

    final award = await service.awardForDailyTasksCompleted(
      completedAt: DateTime(2026, 3, 24, 20),
    );
    final duplicate = await service.awardForDailyTasksCompleted(
      completedAt: DateTime(2026, 3, 24, 21),
    );
    final nextDay = await service.awardForDailyTasksCompleted(
      completedAt: DateTime(2026, 3, 25, 8),
    );

    expect(award.gainedXp, PlayerLevelService.dailyTaskCompletionXp);
    expect(duplicate.gainedXp, 0);
    expect(nextDay.gainedXp, PlayerLevelService.dailyTaskCompletionXp);
    expect(service.loadState().totalXp, 20);

    final history = service.loadXpHistory();
    expect(history, hasLength(2));
    expect(history.first.category, PlayerXpHistoryCategory.dailyTasks);
    expect(history.first.reasons, contains('daily_tasks_completed'));
    expect(history.last.awardedAt.day, 24);
  });

  test('grouped training plan creation awards bonus xp once', () async {
    final repository = _MemoryOptionRepository();
    final service = PlayerLevelService(repository);

    final award = await service.awardForPlanCreated(
      planId: 'plan-1',
      planIds: const ['plan-1', 'plan-2', 'plan-3'],
    );
    final duplicateAward = await service.awardForPlanCreated(
      planId: 'plan-1',
      planIds: const ['plan-1', 'plan-2', 'plan-3'],
    );

    expect(award.gainedXp, 12);
    expect(award.reasons, contains('plan_created'));
    expect(award.reasons, contains('plan_group_created:3'));
    expect(duplicateAward.gainedXp, 0);

    final history = service.loadXpHistory();
    expect(history, hasLength(1));
    expect(history.first.category, PlayerXpHistoryCategory.plan);
    expect(history.first.reasons, contains('plan_group_created:3'));
  });

  test('challenge round awards xp once per run and round', () async {
    final repository = _MemoryOptionRepository();
    final service = PlayerLevelService(repository);

    final award = await service.awardForChallengeRound(
      challengeRunId: 'starter_3-1',
      roundNumber: 1,
      challengeLabel: 'starter_3',
      completedAt: DateTime(2026, 6, 1, 20),
      rewardXp: 8,
    );
    final duplicateAward = await service.awardForChallengeRound(
      challengeRunId: 'starter_3-1',
      roundNumber: 1,
      challengeLabel: 'starter_3',
      completedAt: DateTime(2026, 6, 1, 21),
      rewardXp: 8,
    );

    expect(award.gainedXp, 8);
    expect(duplicateAward.gainedXp, 0);
    expect(service.loadState().totalXp, 8);
    final history = service.loadXpHistory();
    expect(history, hasLength(1));
    expect(history.single.category, PlayerXpHistoryCategory.challenge);
    expect(history.single.reasons, contains('challenge_round_completed'));
    expect(
      repository.getValue<List>(PlayerLevelService.awardedChallengeRoundsKey),
      contains('starter_3-1:1'),
    );
  });

  test('daily positive xp is capped to keep level-ups slower', () async {
    final repository = _MemoryOptionRepository()
      ..seed(PlayerLevelService.totalXpKey, 64)
      ..seed(PlayerLevelService.xpHistoryKey, <Map<String, dynamic>>[
        PlayerXpHistoryEntry(
          awardedAt: DateTime(2026, 3, 22, 9),
          deltaXp: 64,
          totalXp: 64,
          beforeLevel: 1,
          afterLevel: 2,
          category: PlayerXpHistoryCategory.training,
          label: '드리블',
          reasons: const <String>['log'],
        ).toMap(),
      ]);
    final service = PlayerLevelService(repository);

    final award = await service.awardForQuizCompletion(
      completedAt: DateTime(2026, 3, 22, 20),
    );

    expect(award.gainedXp, 1);
    expect(award.reasons, contains('daily_xp_cap'));
    expect(service.loadState().totalXp, 65);
  });

  test(
    'xp history entries can be deleted individually and all at once',
    () async {
      final repository = _MemoryOptionRepository();
      final service = PlayerLevelService(repository);

      await service.awardForBoardSaved(
        boardId: 'board-1',
        boardTitle: '측면 전개',
        savedAt: DateTime(2026, 3, 22, 10),
        created: true,
      );
      await service.awardForDiaryCreated(
        createdAt: DateTime(today.year, today.month, today.day, 21),
      );

      final history = service.loadXpHistory();
      expect(history, hasLength(2));

      await service.deleteXpHistoryEntry(history.first);
      expect(service.loadXpHistory(), hasLength(1));

      await service.clearXpHistory();
      expect(service.loadXpHistory(), isEmpty);
    },
  );
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  void seed(String key, dynamic value) {
    _values[key] = value;
  }

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
