import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/challenge_service.dart';
import 'package:football_note/application/coach_roster_service.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/application/meal_log_service.dart';
import 'package:football_note/application/player_level_service.dart';
import 'package:football_note/application/training_board_service.dart';
import 'package:football_note/domain/entities/meal_entry.dart';
import 'package:football_note/domain/entities/sport_definition.dart';
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

  test('coach mode scopes reward names and claims by active player', () async {
    final repository = _MemoryOptionRepository()
      ..seed(FamilyAccessService.currentRoleLocalKey, FamilyRole.coach.name);
    final rosterService = CoachRosterService(repository);
    final first = await rosterService.addPlayer(displayName: 'Minjun');
    final second = await rosterService.addPlayer(displayName: 'Jisoo');

    await rosterService.setActivePlayer(first.id);
    repository.seed(
      CoachRosterService.scopedOptionKey(
          PlayerLevelService.totalXpKey, first.id),
      40,
    );
    await PlayerLevelService(repository).setCustomRewardName(2, 'First boots');
    final firstClaim = await PlayerLevelService(repository).claimRewardForLevel(
      2,
    );

    await rosterService.setActivePlayer(second.id);
    expect(PlayerLevelService(repository).loadState().totalXp, 0);
    expect(PlayerLevelService(repository).customRewardNameForLevel(2), '');
    repository.seed(
      CoachRosterService.scopedOptionKey(
        PlayerLevelService.totalXpKey,
        second.id,
      ),
      40,
    );
    await PlayerLevelService(repository).setCustomRewardName(
      2,
      'Second boots',
    );
    final secondClaim =
        await PlayerLevelService(repository).claimRewardForLevel(
      2,
    );

    expect(firstClaim?.customRewardName, 'First boots');
    expect(secondClaim?.customRewardName, 'Second boots');
    expect(
      repository.getValue<Map>(
        CoachRosterService.scopedOptionKey(
          PlayerLevelService.customRewardNamesKey,
          first.id,
        ),
      ),
      <String, String>{'2': 'First boots'},
    );
    expect(
      repository.getValue<List>(
        CoachRosterService.scopedOptionKey(
          PlayerLevelService.claimedRewardLevelsKey,
          first.id,
        ),
      ),
      <int>[2],
    );
    expect(
      repository.getValue<Map>(PlayerLevelService.customRewardNamesKey),
      isNull,
    );
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

  test('sport-specific level labels use sport language', () {
    final l10n = AppLocalizationsKo();

    expect(l10n.playerLevelName(20), '풋볼 선물왕');
    expect(
      l10n.playerLevelName(20, sportId: SportCatalog.baseballId),
      '야구 선물왕',
    );
    expect(
      l10n.playerLevelName(20, sportId: SportCatalog.basketballId),
      '농구 선물왕',
    );
    expect(
      l10n.playerLevelStageName(20, sportId: SportCatalog.tennisId),
      '엘리트 투어',
    );
  });

  test('xp and rewards are scoped by sport', () async {
    final repository = _MemoryOptionRepository();
    final footballService = PlayerLevelService(repository);
    final basketballService = PlayerLevelService(
      repository,
      sportId: SportCatalog.basketballId,
    );

    final footballAward = await footballService.awardForQuizCompletion(
      completedAt: DateTime(2026, 3, 24, 20),
      correctAnswers: 6,
      totalQuestions: 10,
    );
    final basketballAward = await basketballService.awardForQuizCompletion(
      completedAt: DateTime(2026, 3, 24, 20),
      correctAnswers: 10,
      totalQuestions: 10,
    );
    await basketballService.setCustomRewardName(2, '새 농구화');

    expect(footballAward.sportId, SportCatalog.footballId);
    expect(basketballAward.sportId, SportCatalog.basketballId);
    expect(footballService.loadState().totalXp, footballAward.gainedXp);
    expect(basketballService.loadState().totalXp, basketballAward.gainedXp);
    expect(
      repository.getValue<int>('${PlayerLevelService.totalXpKey}_basketball'),
      basketballAward.gainedXp,
    );
    expect(footballService.customRewardNameForLevel(2), isEmpty);
    expect(basketballService.customRewardNameForLevel(2), '새 농구화');
  });

  test(
    'training streaks only consider entries from the same sport',
    () async {
      final entry = TrainingEntry(
        date: today,
        durationMinutes: 45,
        intensity: 4,
        type: '훈련',
        mood: 4,
        injury: false,
        notes: '',
        location: '체육관',
        sportId: SportCatalog.basketballId,
      );
      final existingFootballEntries = <TrainingEntry>[
        TrainingEntry(
          date: today.subtract(const Duration(days: 2)),
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
      final repositoryWithFootballHistory = _MemoryOptionRepository();
      final repositoryWithoutHistory = _MemoryOptionRepository();
      final serviceWithFootballHistory = PlayerLevelService(
        repositoryWithFootballHistory,
        sportId: SportCatalog.basketballId,
      );
      final serviceWithoutHistory = PlayerLevelService(
        repositoryWithoutHistory,
        sportId: SportCatalog.basketballId,
      );

      final awardWithFootballHistory =
          await serviceWithFootballHistory.awardForTrainingLog(
        entry: entry,
        existingEntries: existingFootballEntries,
      );
      final awardWithoutHistory =
          await serviceWithoutHistory.awardForTrainingLog(
        entry: entry,
        existingEntries: const <TrainingEntry>[],
      );

      expect(
        awardWithFootballHistory.gainedXp,
        awardWithoutHistory.gainedXp,
      );
      expect(
        awardWithFootballHistory.reasons
            .where((reason) => reason.startsWith('streak')),
        isEmpty,
      );
    },
  );

  test('record services keep non-football storage separate', () async {
    final repository = _MemoryOptionRepository();
    final baseballMealService = MealLogService(
      repository,
      sportId: SportCatalog.baseballId,
    );
    final tennisBoardService = TrainingBoardService(
      repository,
      sportId: SportCatalog.tennisId,
    );
    final basketballChallengeService = ChallengeService(
      repository,
      sportId: SportCatalog.basketballId,
    );

    await baseballMealService.save(
      MealEntry(
        date: today,
        breakfastRiceBowls: 1,
        createdAt: DateTime(2026, 3, 24, 8),
      ),
    );
    await tennisBoardService.createBoard(
      title: '서브 루틴',
      layoutJson: '{"items":[]}',
    );
    await basketballChallengeService.startChallenge(
      basketballChallengeService.templates().first,
      startedAt: DateTime(2026, 3, 24, 9),
    );

    expect(MealLogService(repository).allEntries(), isEmpty);
    expect(TrainingBoardService(repository).allBoards(), isEmpty);
    expect(ChallengeService(repository).activeRun(), isNull);
    expect(baseballMealService.allEntries(), hasLength(1));
    expect(tennisBoardService.allBoards(), hasLength(1));
    expect(basketballChallengeService.activeRun(), isNotNull);
    expect(repository.getValue<String>('${MealLogService.storageKey}_baseball'),
        isNotNull);
    expect(
        repository
            .getValue<String>('${TrainingBoardService.storageKey}_tennis'),
        isNotNull);
    expect(
      repository.getValue<String>('${ChallengeService.storageKey}_basketball'),
      isNotNull,
    );
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
    'training log update deducts xp when conditioning records are removed',
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
          program: '원터치 패스',
          mood: 4,
          injury: false,
          notes: '',
          location: '운동장',
          liftingByPart: const {'inside': 40},
          jumpRopeCount: 120,
          jumpRopeEnabled: true,
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
        ),
      );

      expect(award.gainedXp, -12);
      expect(
        award.reasons,
        containsAll(<String>['lifting_missed', 'jump_rope_missed']),
      );
      expect(service.loadState().totalXp, 88);
      expect(service.loadXpHistory().single.deltaXp, -12);
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

  test('meal log edits and deletion reconcile source xp', () async {
    final repository = _MemoryOptionRepository()
      ..seed(PlayerLevelService.totalXpKey, 100);
    final service = PlayerLevelService(repository);
    final fullMeal = MealEntry(
      date: today,
      breakfastRiceBowls: 1,
      lunchRiceBowls: 1,
      dinnerRiceBowls: 2,
      createdAt: DateTime(today.year, today.month, today.day, 8),
    );
    final partialMeal = MealEntry(
      date: today,
      breakfastRiceBowls: 1,
      lunchRiceBowls: 1,
      createdAt: DateTime(today.year, today.month, today.day, 20),
    );

    final createAward = await service.awardForMealLog(updatedEntry: fullMeal);
    final editAward = await service.awardForMealLog(
      previousEntry: fullMeal,
      updatedEntry: partialMeal,
    );
    final deleteAward = await service.revokeMealLogAward(partialMeal);

    expect(createAward.gainedXp, 8);
    expect(editAward.gainedXp, -5);
    expect(deleteAward.gainedXp, -3);
    expect(service.loadState().totalXp, 100);
    expect(service.loadXpHistory(), isEmpty);
  });

  test('training log deletion revokes every source delta', () async {
    final repository = _MemoryOptionRepository()
      ..seed(PlayerLevelService.totalXpKey, 100);
    final service = PlayerLevelService(repository);
    final baseEntry = TrainingEntry(
      date: today,
      durationMinutes: 55,
      intensity: 4,
      type: '패스',
      program: '원터치 패스',
      mood: 4,
      injury: false,
      notes: '',
      location: '운동장',
    );
    final updatedEntry = TrainingEntry(
      date: today,
      durationMinutes: 55,
      intensity: 4,
      type: '패스',
      program: '원터치 패스',
      mood: 4,
      injury: false,
      notes: '',
      location: '운동장',
      createdAt: baseEntry.createdAt,
      liftingByPart: const {'inside': 40},
      jumpRopeCount: 120,
      jumpRopeEnabled: true,
    );

    await service.awardForTrainingLog(
      entry: baseEntry,
      existingEntries: const <TrainingEntry>[],
    );
    await service.awardForTrainingLogUpdate(
      previousEntry: baseEntry,
      updatedEntry: updatedEntry,
    );

    expect(service.loadState().totalXp, 122);
    expect(service.loadXpHistory(), hasLength(2));

    final deleteAward = await service.revokeTrainingEntryAward(baseEntry);

    expect(deleteAward.gainedXp, -22);
    expect(service.loadState().totalXp, 100);
    expect(service.loadXpHistory(), isEmpty);
  });

  test('match log edits and deletion reconcile match xp', () async {
    final repository = _MemoryOptionRepository()
      ..seed(PlayerLevelService.totalXpKey, 100);
    final service = PlayerLevelService(repository);
    final match = TrainingEntry(
      date: today,
      durationMinutes: 90,
      intensity: 4,
      type: '경기',
      mood: 4,
      injury: false,
      notes: '',
      location: '운동장',
      club: '상대팀',
      opponentTeam: '상대팀',
      scoredGoals: 2,
      concededGoals: 1,
      playerGoals: 1,
    );
    final editedMatch = TrainingEntry(
      date: today,
      durationMinutes: 90,
      intensity: 4,
      type: '경기',
      mood: 4,
      injury: false,
      notes: '',
      location: '운동장',
      club: '상대팀',
      opponentTeam: '상대팀',
      createdAt: match.createdAt,
    );

    final createAward = await service.awardForMatchLog(updatedEntry: match);
    final editAward = await service.awardForMatchLog(
      previousEntry: match,
      updatedEntry: editedMatch,
    );
    final deleteAward = await service.revokeMatchEntryAward(editedMatch);

    expect(createAward.gainedXp, 18);
    expect(editAward.gainedXp, -8);
    expect(deleteAward.gainedXp, -10);
    expect(service.loadState().totalXp, 100);
    expect(service.loadXpHistory(), isEmpty);
  });

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

      final boardRevoke = await service.revokeBoardAwards(
        boardId: 'board-1',
        boardTitle: '측면 전개',
      );
      final diaryRevoke = await service.revokeDiaryCreated(
        DateTime(today.year, today.month, today.day, 21),
      );
      expect(boardRevoke.gainedXp, -5);
      expect(diaryRevoke.gainedXp, -3);
      expect(service.loadState().totalXp, 0);
    },
  );

  test('quiz completion awards xp on the completed day token', () async {
    final repository = _MemoryOptionRepository();
    final service = PlayerLevelService(repository);

    final award = await service.awardForQuizCompletion(
      completedAt: DateTime(2026, 3, 24, 23, 55),
      correctAnswers: 6,
      totalQuestions: 10,
    );
    final duplicate = await service.awardForQuizCompletion(
      completedAt: DateTime(2026, 3, 24, 23, 59),
      correctAnswers: 10,
      totalQuestions: 10,
    );
    final nextDay = await service.awardForQuizCompletion(
      completedAt: DateTime(2026, 3, 25, 0, 5),
      correctAnswers: 10,
      totalQuestions: 10,
    );

    expect(award.gainedXp, 8);
    expect(duplicate.gainedXp, 0);
    expect(nextDay.gainedXp, 15);
    expect(service.loadState().totalXp, 23);

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

  test('daily task completion can be revoked when tasks become incomplete',
      () async {
    final repository = _MemoryOptionRepository();
    final service = PlayerLevelService(repository);
    final completedAt = DateTime(2026, 3, 24, 20);

    await service.awardForDailyTasksCompleted(completedAt: completedAt);
    final revoked = await service.revokeDailyTasksCompleted(completedAt);
    final reawarded = await service.awardForDailyTasksCompleted(
      completedAt: completedAt.add(const Duration(minutes: 5)),
    );

    expect(revoked.gainedXp, -PlayerLevelService.dailyTaskCompletionXp);
    expect(reawarded.gainedXp, PlayerLevelService.dailyTaskCompletionXp);
    expect(
        service.loadState().totalXp, PlayerLevelService.dailyTaskCompletionXp);
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
    expect(history, hasLength(3));
    expect(
      history.map((entry) => entry.category).toSet(),
      {PlayerXpHistoryCategory.plan},
    );
    expect(history.first.reasons, contains('plan_group_created:3'));

    final revoked = await service.revokePlanAward('plan-2');
    final reawarded = await service.awardForPlanCreated(planId: 'plan-2');

    expect(revoked.gainedXp, -3);
    expect(reawarded.gainedXp, 6);
    expect(service.loadState().totalXp, 15);
  });

  test('challenge round awards xp once per run and round', () async {
    final repository = _MemoryOptionRepository();
    final service = PlayerLevelService(repository);

    final award = await service.awardForChallengeRound(
      challengeRunId: 'starter_3-1',
      roundNumber: 1,
      challengeLabel: 'starter_3',
      completedAt: DateTime(2026, 6, 1, 20),
      rewardXp: 11,
      streakBonusXp: 3,
    );
    final duplicateAward = await service.awardForChallengeRound(
      challengeRunId: 'starter_3-1',
      roundNumber: 1,
      challengeLabel: 'starter_3',
      completedAt: DateTime(2026, 6, 1, 21),
      rewardXp: 11,
      streakBonusXp: 3,
    );

    expect(award.gainedXp, 11);
    expect(duplicateAward.gainedXp, 0);
    expect(service.loadState().totalXp, 11);
    final history = service.loadXpHistory();
    expect(history, hasLength(1));
    expect(history.single.category, PlayerXpHistoryCategory.challenge);
    expect(history.single.reasons, contains('challenge_round_completed'));
    expect(history.single.reasons, contains('challenge_round_streak_bonus'));
    expect(
      repository.getValue<List>(PlayerLevelService.awardedChallengeRoundsKey),
      contains('starter_3-1:1'),
    );

    final revokedAward = await service.revokeChallengeRound(
      challengeRunId: 'starter_3-1',
      roundNumber: 1,
    );

    expect(revokedAward.gainedXp, -11);
    expect(service.loadState().totalXp, 0);
    expect(
      repository.getValue<List>(PlayerLevelService.awardedChallengeRoundsKey),
      isNot(contains('starter_3-1:1')),
    );
  });

  test('challenge completion bonus awards large xp once per run', () async {
    final repository = _MemoryOptionRepository();
    final service = PlayerLevelService(repository);

    final award = await service.awardForChallengeCompletion(
      challengeRunId: 'starter_3-1',
      challengeLabel: 'starter_3',
      completedAt: DateTime(2026, 6, 3, 20),
      rewardXp: 120,
    );
    final duplicateAward = await service.awardForChallengeCompletion(
      challengeRunId: 'starter_3-1',
      challengeLabel: 'starter_3',
      completedAt: DateTime(2026, 6, 3, 21),
      rewardXp: 120,
    );

    expect(award.gainedXp, 120);
    expect(duplicateAward.gainedXp, 0);
    expect(service.loadState().totalXp, 120);
    final history = service.loadXpHistory();
    expect(history, hasLength(1));
    expect(history.single.category, PlayerXpHistoryCategory.challenge);
    expect(history.single.label, 'starter_3:complete');
    expect(history.single.reasons, contains('challenge_completed_bonus'));
    expect(
      repository.getValue<List>(
        PlayerLevelService.awardedChallengeCompletionsKey,
      ),
      contains('starter_3-1'),
    );

    final revokedAward = await service.revokeChallengeCompletion(
      challengeRunId: 'starter_3-1',
    );

    expect(revokedAward.gainedXp, -120);
    expect(service.loadState().totalXp, 0);
    expect(
      repository.getValue<List>(
        PlayerLevelService.awardedChallengeCompletionsKey,
      ),
      isNot(contains('starter_3-1')),
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
      expect(service.loadState().totalXp, 8);

      await service.deleteXpHistoryEntry(history.first);
      expect(service.loadXpHistory(), hasLength(1));
      expect(service.loadState().totalXp, 5);

      await service.clearXpHistory();
      expect(service.loadXpHistory(), isEmpty);
      expect(service.loadState().totalXp, 0);
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
