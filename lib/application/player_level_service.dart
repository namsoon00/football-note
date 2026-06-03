import 'dart:convert';

import '../domain/entities/meal_entry.dart';
import 'meal_coaching_service.dart';
import '../domain/entities/training_entry.dart';
import '../domain/progression/player_progression_rules.dart';
import '../domain/repositories/option_repository.dart';

class PlayerLevelService {
  static const String totalXpKey = 'player_total_xp_v1';
  static const String xpHistoryKey = 'player_xp_history_v1';
  static const String quizRewardDayKey = 'player_quiz_reward_day_v1';
  static const String awardedPlanIdsKey = 'player_awarded_plan_ids_v1';
  static const String awardedMatchLogTokensKey =
      'player_awarded_match_log_tokens_v1';
  static const String awardedStreaksKey = 'player_awarded_streaks_v1';
  static const String awardedBoardSaveTokensKey =
      'player_awarded_board_save_tokens_v1';
  static const String awardedRoutineDaysKey = 'player_awarded_routine_days_v1';
  static const String awardedDailyTaskCompletionDaysKey =
      'player_awarded_daily_task_completion_days_v1';
  static const String awardedChallengeRoundsKey =
      'player_awarded_challenge_rounds_v1';
  static const String diaryCreatedDayKey = 'player_diary_created_day_v2';
  static const String claimedRewardLevelsKey =
      'player_claimed_reward_levels_v1';
  static const String customRewardNamesKey = 'player_custom_reward_names_v1';
  static const String rewardClaimMessagesKey =
      'player_reward_claim_messages_v1';
  static const String plansStorageKey = 'training_plans_v1';
  static const int trainingLogSavedXp =
      PlayerProgressionRules.trainingLogSavedXp;
  static const int firstDailyTrainingLogXp =
      PlayerProgressionRules.firstDailyTrainingLogXp;
  static const int plannedTrainingDayXp =
      PlayerProgressionRules.plannedTrainingDayXp;
  static const int matchLogSavedXp = PlayerProgressionRules.matchLogSavedXp;
  static const int matchDetailRecordedXp =
      PlayerProgressionRules.matchDetailRecordedXp;
  static const int conditioningRecordedXp =
      PlayerProgressionRules.conditioningRecordedXp;
  static const int missingConditioningPenaltyXp =
      PlayerProgressionRules.missingConditioningPenaltyXp;
  static const int routineCompleteXp = PlayerProgressionRules.routineCompleteXp;
  static const int streakDaily2To3Xp = PlayerProgressionRules.streakDaily2To3Xp;
  static const int streakDaily4To6Xp = PlayerProgressionRules.streakDaily4To6Xp;
  static const int streakDaily7PlusXp =
      PlayerProgressionRules.streakDaily7PlusXp;
  static const int streak3DaysXp = PlayerProgressionRules.streak3DaysXp;
  static const int streak7DaysXp = PlayerProgressionRules.streak7DaysXp;
  static const int weekly3LogsXp = PlayerProgressionRules.weekly3LogsXp;
  static const int weekly5LogsXp = PlayerProgressionRules.weekly5LogsXp;
  static const int dailyTaskCompletionXp =
      PlayerProgressionRules.dailyTaskCompletionXp;
  static const int dailyPositiveXpCap =
      PlayerProgressionRules.dailyPositiveXpCap;
  static const int maxLevelMasterySpan =
      PlayerProgressionRules.maxLevelMasterySpan;

  static List<int> get levelThresholds =>
      PlayerProgressionRules.levelThresholds;

  static List<PlayerLevelReward> get levelRewards =>
      List<PlayerLevelReward>.generate(
        PlayerProgressionRules.levelThresholds.length,
        (index) => PlayerLevelReward(
          level: index + 1,
          nameKo: '',
          nameEn: '',
          descriptionKo: '',
          descriptionEn: '',
        ),
        growable: false,
      );

  final OptionRepository _options;
  final MealCoachingService _mealCoachingService = const MealCoachingService();

  PlayerLevelService(this._options);

  PlayerLevelState loadState() {
    final totalXp = _options.getValue<int>(totalXpKey) ?? 0;
    return PlayerLevelState.fromXp(totalXp);
  }

  Future<PlayerLevelAward> awardForTrainingLog({
    required TrainingEntry entry,
    required List<TrainingEntry> existingEntries,
  }) async {
    final before = loadState();
    final mealXp = _mealCoachingService.xpValueForEntry(entry);
    final mealReason = _mealCoachingService.xpReasonForEntry(entry);
    final awardedStreaks = _getStringSet(awardedStreaksKey);
    final awardedRoutineDays = _getStringSet(awardedRoutineDaysKey);
    final progression = PlayerProgressionRules.evaluateTrainingLog(
      entry: entry,
      existingEntries: existingEntries,
      hasPlanOnDay: _hasPlanOnDay(
        PlayerProgressionRules.normalizeDay(entry.date),
      ),
      mealXp: mealXp,
      mealReason: mealReason,
      awardedStreaks: awardedStreaks,
      awardedRoutineDays: awardedRoutineDays,
    );
    final reasons = progression.reasons.toList(growable: true);
    final gainedXp = _applyDailyPositiveXpCap(
      requestedXp: progression.requestedXp,
      awardedAt: entry.createdAt,
      reasons: reasons,
    );

    awardedStreaks.addAll(progression.streakTokensToAward);
    awardedRoutineDays.addAll(progression.routineDayTokensToAward);

    final nextTotal = (before.totalXp + gainedXp).clamp(0, 1000000).toInt();
    await _options.setValue(totalXpKey, nextTotal);
    await _options.setValue(awardedStreaksKey, awardedStreaks.toList()..sort());
    await _options.setValue(
      awardedRoutineDaysKey,
      awardedRoutineDays.toList()..sort(),
    );
    final after = PlayerLevelState.fromXp(nextTotal);
    await _appendXpHistory(
      PlayerXpHistoryEntry(
        awardedAt: entry.createdAt,
        deltaXp: gainedXp,
        totalXp: nextTotal,
        beforeLevel: before.level,
        afterLevel: after.level,
        category: PlayerXpHistoryCategory.training,
        label:
            entry.program.trim().isNotEmpty ? entry.program.trim() : entry.type,
        reasons: reasons,
      ),
    );
    return PlayerLevelAward(
      gainedXp: gainedXp,
      before: before,
      after: after,
      reasons: reasons,
    );
  }

  Future<PlayerLevelAward> awardForTrainingLogUpdate({
    required TrainingEntry previousEntry,
    required TrainingEntry updatedEntry,
  }) async {
    final before = loadState();
    final previousMealXp = _mealCoachingService.xpValueForEntry(previousEntry);
    final updatedMealXp = _mealCoachingService.xpValueForEntry(updatedEntry);
    final updatedMealReason = _mealCoachingService.xpReasonForEntry(
      updatedEntry,
    );
    final awardedRoutineDays = _getStringSet(awardedRoutineDaysKey);
    final progression = PlayerProgressionRules.evaluateTrainingLogUpdate(
      previousEntry: previousEntry,
      updatedEntry: updatedEntry,
      previousMealXp: previousMealXp,
      updatedMealXp: updatedMealXp,
      updatedMealReason: updatedMealReason,
      awardedRoutineDays: awardedRoutineDays,
    );
    final reasons = progression.reasons.toList(growable: true);
    final gainedXp = _applyDailyPositiveXpCap(
      requestedXp: progression.requestedXp,
      awardedAt: updatedEntry.createdAt,
      reasons: reasons,
    );

    awardedRoutineDays.addAll(progression.routineDayTokensToAward);

    if (gainedXp == 0) {
      return PlayerLevelAward(
        gainedXp: 0,
        before: before,
        after: before,
        reasons: const <String>[],
      );
    }

    final nextTotal = before.totalXp + gainedXp;
    await _options.setValue(totalXpKey, nextTotal);
    await _options.setValue(
      awardedRoutineDaysKey,
      awardedRoutineDays.toList()..sort(),
    );
    final after = PlayerLevelState.fromXp(nextTotal);
    await _appendXpHistory(
      PlayerXpHistoryEntry(
        awardedAt: updatedEntry.createdAt,
        deltaXp: gainedXp,
        totalXp: nextTotal,
        beforeLevel: before.level,
        afterLevel: after.level,
        category: PlayerXpHistoryCategory.training,
        label: updatedEntry.program.trim().isNotEmpty
            ? updatedEntry.program.trim()
            : updatedEntry.type,
        reasons: reasons,
      ),
    );
    return PlayerLevelAward(
      gainedXp: gainedXp,
      before: before,
      after: after,
      reasons: reasons,
    );
  }

  Future<PlayerLevelAward> awardForMealLog({
    MealEntry? previousEntry,
    required MealEntry updatedEntry,
  }) async {
    final before = loadState();
    final previousMealXp = previousEntry == null
        ? 0
        : _mealCoachingService.xpValueForMealEntry(previousEntry);
    final updatedMealXp = _mealCoachingService.xpValueForMealEntry(
      updatedEntry,
    );
    final gainedXp = updatedMealXp - previousMealXp;
    if (gainedXp <= 0) {
      return PlayerLevelAward(
        gainedXp: 0,
        before: before,
        after: before,
        reasons: const <String>[],
      );
    }
    final reason = _mealCoachingService.xpReasonForMealEntry(updatedEntry);
    final reasons = reason.isEmpty ? <String>[] : <String>[reason];
    final appliedXp = _applyDailyPositiveXpCap(
      requestedXp: gainedXp,
      awardedAt: updatedEntry.createdAt,
      reasons: reasons,
    );
    if (appliedXp <= 0) {
      return PlayerLevelAward(
        gainedXp: 0,
        before: before,
        after: before,
        reasons: reasons,
      );
    }
    final nextTotal = before.totalXp + appliedXp;
    await _options.setValue(totalXpKey, nextTotal);
    final after = PlayerLevelState.fromXp(nextTotal);
    await _appendXpHistory(
      PlayerXpHistoryEntry(
        awardedAt: updatedEntry.createdAt,
        deltaXp: appliedXp,
        totalXp: nextTotal,
        beforeLevel: before.level,
        afterLevel: after.level,
        category: PlayerXpHistoryCategory.meal,
        label: '',
        reasons: reasons,
      ),
    );
    return PlayerLevelAward(
      gainedXp: appliedXp,
      before: before,
      after: after,
      reasons: reasons,
    );
  }

  Future<PlayerLevelAward> awardForQuizCompletion({
    DateTime? completedAt,
  }) async {
    final before = loadState();
    final day = PlayerProgressionRules.normalizeDay(
      completedAt ?? DateTime.now(),
    );
    final token = PlayerProgressionRules.dayKey(day);
    if ((_options.getValue<String>(quizRewardDayKey) ?? '') == token) {
      return PlayerLevelAward(
        gainedXp: 0,
        before: before,
        after: before,
        reasons: const <String>[],
      );
    }

    final reasons = <String>['quiz_complete'];
    final gainedXp = _applyDailyPositiveXpCap(
      requestedXp: 8,
      awardedAt: completedAt ?? DateTime.now(),
      reasons: reasons,
    );
    final nextTotal = before.totalXp + gainedXp;
    await _options.setValue(totalXpKey, nextTotal);
    await _options.setValue(quizRewardDayKey, token);
    final after = PlayerLevelState.fromXp(nextTotal);
    if (gainedXp > 0) {
      await _appendXpHistory(
        PlayerXpHistoryEntry(
          awardedAt: completedAt ?? DateTime.now(),
          deltaXp: gainedXp,
          totalXp: nextTotal,
          beforeLevel: before.level,
          afterLevel: after.level,
          category: PlayerXpHistoryCategory.quiz,
          label: '',
          reasons: reasons,
        ),
      );
    }
    return PlayerLevelAward(
      gainedXp: gainedXp,
      before: before,
      after: after,
      reasons: reasons,
    );
  }

  Future<PlayerLevelAward> awardForPlanCreated({
    required String planId,
    List<String> planIds = const <String>[],
  }) async {
    final before = loadState();
    final awardedPlanIds = _getStringSet(awardedPlanIdsKey);
    final normalizedPlanIds = (planIds.isEmpty ? <String>[planId] : planIds)
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalizedPlanIds.isEmpty) {
      return PlayerLevelAward(
        gainedXp: 0,
        before: before,
        after: before,
        reasons: const <String>[],
      );
    }
    final newPlanIds = normalizedPlanIds
        .where((id) => !awardedPlanIds.contains(id))
        .toList(growable: false);
    if (newPlanIds.isEmpty) {
      return PlayerLevelAward(
        gainedXp: 0,
        before: before,
        after: before,
        reasons: const <String>[],
      );
    }
    awardedPlanIds.addAll(newPlanIds);

    final additionalPlans = (newPlanIds.length - 1).clamp(0, 4);
    final reasons = <String>[
      'plan_created',
      if (newPlanIds.length > 1) 'plan_group_created:${newPlanIds.length}',
    ];
    final gainedXp = _applyDailyPositiveXpCap(
      requestedXp: 6 + (additionalPlans * 3),
      awardedAt: DateTime.now(),
      reasons: reasons,
    );
    final nextTotal = before.totalXp + gainedXp;
    await _options.setValue(totalXpKey, nextTotal);
    await _options.setValue(awardedPlanIdsKey, awardedPlanIds.toList()..sort());
    final after = PlayerLevelState.fromXp(nextTotal);
    if (gainedXp > 0) {
      await _appendXpHistory(
        PlayerXpHistoryEntry(
          awardedAt: DateTime.now(),
          deltaXp: gainedXp,
          totalXp: nextTotal,
          beforeLevel: before.level,
          afterLevel: after.level,
          category: PlayerXpHistoryCategory.plan,
          label: '',
          reasons: reasons,
        ),
      );
    }
    return PlayerLevelAward(
      gainedXp: gainedXp,
      before: before,
      after: after,
      reasons: reasons,
    );
  }

  Future<PlayerLevelAward> awardForMatchLog({
    TrainingEntry? previousEntry,
    required TrainingEntry updatedEntry,
  }) async {
    final before = loadState();
    if (!updatedEntry.isMatch) {
      return PlayerLevelAward(
        gainedXp: 0,
        before: before,
        after: before,
        reasons: const <String>[],
      );
    }

    final awardedTokens = _getStringSet(awardedMatchLogTokensKey);
    final token = _matchAwardToken(updatedEntry);
    final isNewMatchToken = !awardedTokens.contains(token);

    if (previousEntry == null && !isNewMatchToken) {
      return PlayerLevelAward(
        gainedXp: 0,
        before: before,
        after: before,
        reasons: const <String>[],
      );
    }

    awardedTokens.add(token);
    final progression = PlayerProgressionRules.evaluateMatchLog(
      previousEntry: previousEntry,
      updatedEntry: updatedEntry,
      isNewMatchToken: isNewMatchToken,
    );
    final reasons = progression.reasons.toList(growable: true);
    final gainedXp = _applyDailyPositiveXpCap(
      requestedXp: progression.requestedXp,
      awardedAt: updatedEntry.createdAt,
      reasons: reasons,
    );
    await _options.setValue(
      awardedMatchLogTokensKey,
      awardedTokens.toList()..sort(),
    );
    if (gainedXp <= 0) {
      return PlayerLevelAward(
        gainedXp: 0,
        before: before,
        after: before,
        reasons: reasons,
      );
    }

    final nextTotal = before.totalXp + gainedXp;
    await _options.setValue(totalXpKey, nextTotal);
    final after = PlayerLevelState.fromXp(nextTotal);
    await _appendXpHistory(
      PlayerXpHistoryEntry(
        awardedAt: updatedEntry.createdAt,
        deltaXp: gainedXp,
        totalXp: nextTotal,
        beforeLevel: before.level,
        afterLevel: after.level,
        category: PlayerXpHistoryCategory.match,
        label: updatedEntry.opponentTeam.trim().isNotEmpty
            ? updatedEntry.opponentTeam.trim()
            : updatedEntry.club.trim(),
        reasons: reasons,
      ),
    );
    return PlayerLevelAward(
      gainedXp: gainedXp,
      before: before,
      after: after,
      reasons: reasons,
    );
  }

  Future<PlayerLevelAward> awardForBoardSaved({
    required String boardId,
    required String boardTitle,
    DateTime? savedAt,
    bool created = false,
  }) async {
    final before = loadState();
    final awardedTokens = _getStringSet(awardedBoardSaveTokensKey);
    final now = savedAt ?? DateTime.now();
    final token = '$boardId:${PlayerProgressionRules.dayKey(now)}';
    if (!awardedTokens.add(token)) {
      return PlayerLevelAward(
        gainedXp: 0,
        before: before,
        after: before,
        reasons: const <String>[],
      );
    }

    final reasons = <String>[created ? 'board_created' : 'board_saved'];
    final gainedXp = _applyDailyPositiveXpCap(
      requestedXp: created ? 5 : 2,
      awardedAt: now,
      reasons: reasons,
    );
    final nextTotal = before.totalXp + gainedXp;
    await _options.setValue(totalXpKey, nextTotal);
    await _options.setValue(
      awardedBoardSaveTokensKey,
      awardedTokens.toList()..sort(),
    );
    final after = PlayerLevelState.fromXp(nextTotal);
    if (gainedXp > 0) {
      await _appendXpHistory(
        PlayerXpHistoryEntry(
          awardedAt: now,
          deltaXp: gainedXp,
          totalXp: nextTotal,
          beforeLevel: before.level,
          afterLevel: after.level,
          category: PlayerXpHistoryCategory.board,
          label: boardTitle.trim(),
          reasons: reasons,
        ),
      );
    }
    return PlayerLevelAward(
      gainedXp: gainedXp,
      before: before,
      after: after,
      reasons: reasons,
    );
  }

  Future<PlayerLevelAward> awardForDiaryCreated({DateTime? createdAt}) async {
    final before = loadState();
    final target = createdAt ?? DateTime.now();
    final day = PlayerProgressionRules.normalizeDay(target);
    final token = PlayerProgressionRules.dayKey(day);
    if ((_options.getValue<String>(diaryCreatedDayKey) ?? '') == token) {
      return PlayerLevelAward(
        gainedXp: 0,
        before: before,
        after: before,
        reasons: const <String>[],
      );
    }

    final reasons = <String>['diary_created'];
    final gainedXp = _applyDailyPositiveXpCap(
      requestedXp: 3,
      awardedAt: createdAt ?? DateTime.now(),
      reasons: reasons,
    );
    final nextTotal = before.totalXp + gainedXp;
    await _options.setValue(totalXpKey, nextTotal);
    await _options.setValue(diaryCreatedDayKey, token);
    final after = PlayerLevelState.fromXp(nextTotal);
    if (gainedXp > 0) {
      await _appendXpHistory(
        PlayerXpHistoryEntry(
          awardedAt: createdAt ?? DateTime.now(),
          deltaXp: gainedXp,
          totalXp: nextTotal,
          beforeLevel: before.level,
          afterLevel: after.level,
          category: PlayerXpHistoryCategory.diary,
          label: '',
          reasons: reasons,
        ),
      );
    }
    return PlayerLevelAward(
      gainedXp: gainedXp,
      before: before,
      after: after,
      reasons: reasons,
    );
  }

  Future<PlayerLevelAward> awardForDailyTasksCompleted({
    DateTime? completedAt,
  }) async {
    final before = loadState();
    final awardedAt = completedAt ?? DateTime.now();
    final day = PlayerProgressionRules.normalizeDay(awardedAt);
    final token = PlayerProgressionRules.dayKey(day);
    final awardedDays = _getStringSet(awardedDailyTaskCompletionDaysKey);
    if (!awardedDays.add(token)) {
      return PlayerLevelAward(
        gainedXp: 0,
        before: before,
        after: before,
        reasons: const <String>[],
      );
    }

    final reasons = <String>['daily_tasks_completed'];
    final gainedXp = _applyDailyPositiveXpCap(
      requestedXp: dailyTaskCompletionXp,
      awardedAt: awardedAt,
      reasons: reasons,
    );
    await _options.setValue(
      awardedDailyTaskCompletionDaysKey,
      awardedDays.toList()..sort(),
    );
    if (gainedXp <= 0) {
      return PlayerLevelAward(
        gainedXp: 0,
        before: before,
        after: before,
        reasons: reasons,
      );
    }

    final nextTotal = before.totalXp + gainedXp;
    await _options.setValue(totalXpKey, nextTotal);
    final after = PlayerLevelState.fromXp(nextTotal);
    await _appendXpHistory(
      PlayerXpHistoryEntry(
        awardedAt: awardedAt,
        deltaXp: gainedXp,
        totalXp: nextTotal,
        beforeLevel: before.level,
        afterLevel: after.level,
        category: PlayerXpHistoryCategory.dailyTasks,
        label: '',
        reasons: reasons,
      ),
    );
    return PlayerLevelAward(
      gainedXp: gainedXp,
      before: before,
      after: after,
      reasons: reasons,
    );
  }

  Future<PlayerLevelAward> awardForChallengeRound({
    required String challengeRunId,
    required int roundNumber,
    required String challengeLabel,
    required DateTime completedAt,
    required int rewardXp,
  }) async {
    final before = loadState();
    final normalizedRunId = challengeRunId.trim();
    if (normalizedRunId.isEmpty || roundNumber <= 0 || rewardXp <= 0) {
      return PlayerLevelAward(
        gainedXp: 0,
        before: before,
        after: before,
        reasons: const <String>[],
      );
    }
    final token = '$normalizedRunId:$roundNumber';
    final awardedRounds = _getStringSet(awardedChallengeRoundsKey);
    if (!awardedRounds.add(token)) {
      return PlayerLevelAward(
        gainedXp: 0,
        before: before,
        after: before,
        reasons: const <String>[],
      );
    }

    final reasons = <String>['challenge_round_completed'];
    final gainedXp = _applyDailyPositiveXpCap(
      requestedXp: rewardXp,
      awardedAt: completedAt,
      reasons: reasons,
    );
    await _options.setValue(
      awardedChallengeRoundsKey,
      awardedRounds.toList()..sort(),
    );
    if (gainedXp <= 0) {
      return PlayerLevelAward(
        gainedXp: 0,
        before: before,
        after: before,
        reasons: reasons,
      );
    }

    final nextTotal = before.totalXp + gainedXp;
    await _options.setValue(totalXpKey, nextTotal);
    final after = PlayerLevelState.fromXp(nextTotal);
    await _appendXpHistory(
      PlayerXpHistoryEntry(
        awardedAt: completedAt,
        deltaXp: gainedXp,
        totalXp: nextTotal,
        beforeLevel: before.level,
        afterLevel: after.level,
        category: PlayerXpHistoryCategory.challenge,
        label: '$challengeLabel:$roundNumber',
        reasons: reasons,
      ),
    );
    return PlayerLevelAward(
      gainedXp: gainedXp,
      before: before,
      after: after,
      reasons: reasons,
    );
  }

  static PlayerLevelReward? rewardForLevel(int level) {
    if (level < 1 || level > PlayerProgressionRules.levelThresholds.length) {
      return null;
    }
    return PlayerLevelReward(
      level: level,
      nameKo: '',
      nameEn: '',
      descriptionKo: '',
      descriptionEn: '',
    );
  }

  List<PlayerLevelRewardStatus> loadRewardStatuses() {
    final currentLevel = loadState().level;
    final claimedLevels = _getIntSet(claimedRewardLevelsKey);
    final customRewardNames = loadCustomRewardNames();
    return levelRewards
        .map(
          (reward) => PlayerLevelRewardStatus(
            reward: reward,
            isClaimed: claimedLevels.contains(reward.level),
            isAvailable: currentLevel >= reward.level,
            customRewardName: customRewardNames[reward.level] ?? '',
          ),
        )
        .toList(growable: false);
  }

  Future<PlayerLevelRewardClaim?> claimRewardForLevel(int level) async {
    final reward = rewardForLevel(level);
    if (reward == null) return null;
    final customRewardName = customRewardNameForLevel(level).trim();
    if (customRewardName.isEmpty) return null;
    final state = loadState();
    final claimedLevels = _getIntSet(claimedRewardLevelsKey);
    if (state.level < level || claimedLevels.contains(level)) {
      return null;
    }
    claimedLevels.add(level);
    await _options.setValue(
      claimedRewardLevelsKey,
      claimedLevels.toList()..sort(),
    );
    await _appendRewardClaimMessage(
      level: level,
      rewardName: customRewardName,
      claimedAt: DateTime.now(),
    );
    return PlayerLevelRewardClaim(
      reward: reward,
      state: state,
      customRewardName: customRewardName,
    );
  }

  Map<int, String> loadCustomRewardNames() {
    final raw = _options.getValue<Map>(customRewardNamesKey) ?? const {};
    final map = <int, String>{};
    raw.forEach((key, value) {
      final level = int.tryParse(key.toString());
      final name = value?.toString().trim() ?? '';
      if (level != null && name.isNotEmpty) {
        map[level] = name;
      }
    });
    return map;
  }

  String customRewardNameForLevel(int level) {
    return loadCustomRewardNames()[level] ?? '';
  }

  List<PlayerXpHistoryEntry> loadXpHistory() {
    final raw = _options.getValue<List>(xpHistoryKey) ?? const [];
    return raw
        .whereType<Map>()
        .map(
          (item) => PlayerXpHistoryEntry.fromMap(item.cast<String, dynamic>()),
        )
        .toList(growable: false)
      ..sort((a, b) => b.awardedAt.compareTo(a.awardedAt));
  }

  Future<void> deleteXpHistoryEntry(PlayerXpHistoryEntry target) async {
    final history = loadXpHistory().toList(growable: true);
    final targetIndex = history.indexWhere(
      (item) => _sameXpHistoryEntry(item, target),
    );
    if (targetIndex < 0) return;
    history.removeAt(targetIndex);
    await _saveXpHistory(history);
  }

  Future<void> clearXpHistory() async {
    await _saveXpHistory(const <PlayerXpHistoryEntry>[]);
  }

  PlayerLevelRewardStatus? nextRewardStatus({
    int? fromLevel,
    bool includeClaimable = true,
  }) {
    final currentLevel = fromLevel ?? loadState().level;
    for (final status in loadRewardStatuses()) {
      final rewardName = status.customRewardName.trim();
      if (rewardName.isEmpty) continue;
      if (status.isClaimed) continue;
      if (!includeClaimable && status.reward.level <= currentLevel) continue;
      if (status.reward.level < currentLevel && !status.isAvailable) continue;
      return status;
    }
    return null;
  }

  Future<void> setCustomRewardName(int level, String name) async {
    final current = loadCustomRewardNames();
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      current.remove(level);
    } else {
      current[level] = trimmed;
    }
    final encoded = <String, String>{
      for (final entry in current.entries) '${entry.key}': entry.value,
    };
    await _options.setValue(customRewardNamesKey, encoded);
  }

  Set<String> _getStringSet(String key) {
    final raw = _options.getValue<List>(key) ?? const [];
    return raw.map((item) => item.toString()).toSet();
  }

  Set<int> _getIntSet(String key) {
    final raw = _options.getValue<List>(key) ?? const [];
    return raw
        .map((item) => int.tryParse(item.toString()))
        .whereType<int>()
        .toSet();
  }

  bool _hasPlanOnDay(DateTime day) {
    final raw = _options.getValue<String>(plansStorageKey);
    if (raw == null || raw.trim().isEmpty) return false;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return false;
      return decoded.whereType<Map>().any((item) {
        final map = item.cast<String, dynamic>();
        final scheduledAt = DateTime.tryParse(
          map['scheduledAt']?.toString() ?? '',
        );
        return scheduledAt != null &&
            PlayerProgressionRules.normalizeDay(scheduledAt) == day;
      });
    } catch (_) {
      return false;
    }
  }

  String _matchAwardToken(TrainingEntry entry) {
    final key = entry.key;
    if (key is int) return 'key:$key';
    final opponent = entry.opponentTeam.trim().isNotEmpty
        ? entry.opponentTeam.trim()
        : entry.club.trim();
    return [
      PlayerProgressionRules.dayKey(entry.date),
      entry.createdAt.microsecondsSinceEpoch.toString(),
      opponent,
    ].join(':');
  }

  int _applyDailyPositiveXpCap({
    required int requestedXp,
    required DateTime awardedAt,
    List<String>? reasons,
  }) {
    if (requestedXp <= 0) return requestedXp;
    final awardedToday = _loadAwardedPositiveXpForDay(awardedAt);
    final remaining = (dailyPositiveXpCap - awardedToday).clamp(
      0,
      dailyPositiveXpCap,
    );
    final cappedXp = requestedXp > remaining ? remaining : requestedXp;
    if (cappedXp < requestedXp) {
      reasons?.add('daily_xp_cap');
    }
    return cappedXp;
  }

  int _loadAwardedPositiveXpForDay(DateTime awardedAt) {
    final normalizedDay = PlayerProgressionRules.normalizeDay(awardedAt);
    return loadXpHistory()
        .where(
          (entry) =>
              entry.deltaXp > 0 &&
              PlayerProgressionRules.normalizeDay(entry.awardedAt) ==
                  normalizedDay,
        )
        .fold(0, (sum, entry) => sum + entry.deltaXp);
  }

  Future<void> _appendXpHistory(PlayerXpHistoryEntry entry) async {
    final history = loadXpHistory().take(199).toList(growable: true);
    history.insert(0, entry);
    await _saveXpHistory(history);
  }

  Future<void> _appendRewardClaimMessage({
    required int level,
    required String rewardName,
    required DateTime claimedAt,
  }) async {
    final raw = _options.getValue<List>(rewardClaimMessagesKey) ?? const [];
    final messages = raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: true);
    messages.insert(0, <String, dynamic>{
      'id': 'reward-$level-${claimedAt.toUtc().microsecondsSinceEpoch}',
      'level': level,
      'rewardName': rewardName.trim(),
      'claimedAt': claimedAt.toIso8601String(),
    });
    if (messages.length > 200) {
      messages.removeRange(200, messages.length);
    }
    await _options.setValue(rewardClaimMessagesKey, messages);
  }

  Future<void> _saveXpHistory(List<PlayerXpHistoryEntry> history) async {
    await _options.setValue(
      xpHistoryKey,
      history.map((item) => item.toMap()).toList(growable: false),
    );
  }

  bool _sameXpHistoryEntry(PlayerXpHistoryEntry a, PlayerXpHistoryEntry b) {
    if (a.awardedAt != b.awardedAt ||
        a.deltaXp != b.deltaXp ||
        a.totalXp != b.totalXp ||
        a.beforeLevel != b.beforeLevel ||
        a.afterLevel != b.afterLevel ||
        a.category != b.category ||
        a.label != b.label) {
      return false;
    }
    if (a.reasons.length != b.reasons.length) return false;
    for (var i = 0; i < a.reasons.length; i++) {
      if (a.reasons[i] != b.reasons[i]) return false;
    }
    return true;
  }
}

class PlayerLevelState {
  final int totalXp;
  final int level;
  final int currentLevelXp;
  final int xpIntoLevel;
  final int xpToNextLevel;
  final double progress;
  final bool isMaxLevel;
  final int maxLevelExtraXp;
  final int masteryStars;
  final int xpToNextMasteryStar;

  const PlayerLevelState({
    required this.totalXp,
    required this.level,
    required this.currentLevelXp,
    required this.xpIntoLevel,
    required this.xpToNextLevel,
    required this.progress,
    required this.isMaxLevel,
    required this.maxLevelExtraXp,
    required this.masteryStars,
    required this.xpToNextMasteryStar,
  });

  factory PlayerLevelState.fromXp(int totalXp) {
    final thresholds = PlayerProgressionRules.levelThresholds;
    var level = 1;
    for (var index = 0; index < thresholds.length; index++) {
      final threshold = thresholds[index];
      if (totalXp >= threshold) {
        level = index + 1;
      }
    }
    final currentLevelXp =
        thresholds[(level - 1).clamp(0, thresholds.length - 1)];
    final isMaxLevel = level >= thresholds.length;
    if (isMaxLevel) {
      final extraXp = (totalXp - currentLevelXp).clamp(0, 1000000).toInt();
      const masterySpan = PlayerLevelService.maxLevelMasterySpan;
      final masteryStars = extraXp ~/ masterySpan;
      final masteryRemainder = extraXp % masterySpan;
      final xpToNextMasteryStar = masterySpan - masteryRemainder;
      return PlayerLevelState(
        totalXp: totalXp,
        level: level,
        currentLevelXp: currentLevelXp,
        xpIntoLevel: extraXp,
        xpToNextLevel: xpToNextMasteryStar,
        progress: (masteryRemainder / masterySpan).clamp(0.0, 1.0),
        isMaxLevel: true,
        maxLevelExtraXp: extraXp,
        masteryStars: masteryStars,
        xpToNextMasteryStar: xpToNextMasteryStar,
      );
    }
    final nextLevelXp =
        level >= thresholds.length ? currentLevelXp + 2100 : thresholds[level];
    final span = (nextLevelXp - currentLevelXp).clamp(1, 1000000);
    final progress = ((totalXp - currentLevelXp) / span).clamp(0.0, 1.0);
    return PlayerLevelState(
      totalXp: totalXp,
      level: level,
      currentLevelXp: currentLevelXp,
      xpIntoLevel: totalXp - currentLevelXp,
      xpToNextLevel: nextLevelXp - totalXp,
      progress: progress,
      isMaxLevel: false,
      maxLevelExtraXp: 0,
      masteryStars: 0,
      xpToNextMasteryStar: 0,
    );
  }
}

class PlayerLevelAward {
  final int gainedXp;
  final PlayerLevelState before;
  final PlayerLevelState after;
  final List<String> reasons;

  const PlayerLevelAward({
    required this.gainedXp,
    required this.before,
    required this.after,
    required this.reasons,
  });

  bool get didLevelUp => after.level > before.level;
}

class PlayerLevelReward {
  final int level;
  final String nameKo;
  final String nameEn;
  final String descriptionKo;
  final String descriptionEn;

  const PlayerLevelReward({
    required this.level,
    required this.nameKo,
    required this.nameEn,
    required this.descriptionKo,
    required this.descriptionEn,
  });
}

class PlayerLevelRewardStatus {
  final PlayerLevelReward reward;
  final bool isClaimed;
  final bool isAvailable;
  final String customRewardName;

  const PlayerLevelRewardStatus({
    required this.reward,
    required this.isClaimed,
    required this.isAvailable,
    this.customRewardName = '',
  });
}

class PlayerLevelRewardClaim {
  final PlayerLevelReward reward;
  final PlayerLevelState state;
  final String customRewardName;

  const PlayerLevelRewardClaim({
    required this.reward,
    required this.state,
    this.customRewardName = '',
  });
}

enum PlayerXpHistoryCategory {
  training,
  match,
  meal,
  quiz,
  plan,
  board,
  diary,
  dailyTasks,
  challenge,
}

class PlayerXpHistoryEntry {
  final DateTime awardedAt;
  final int deltaXp;
  final int totalXp;
  final int beforeLevel;
  final int afterLevel;
  final PlayerXpHistoryCategory category;
  final String label;
  final List<String> reasons;

  const PlayerXpHistoryEntry({
    required this.awardedAt,
    required this.deltaXp,
    required this.totalXp,
    required this.beforeLevel,
    required this.afterLevel,
    required this.category,
    required this.label,
    required this.reasons,
  });

  factory PlayerXpHistoryEntry.fromMap(Map<String, dynamic> map) {
    return PlayerXpHistoryEntry(
      awardedAt: DateTime.tryParse(map['awardedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      deltaXp: (map['deltaXp'] as num?)?.toInt() ?? 0,
      totalXp: (map['totalXp'] as num?)?.toInt() ?? 0,
      beforeLevel: (map['beforeLevel'] as num?)?.toInt() ?? 1,
      afterLevel: (map['afterLevel'] as num?)?.toInt() ?? 1,
      category: PlayerXpHistoryCategory.values.firstWhere(
        (value) => value.name == map['category']?.toString(),
        orElse: () => PlayerXpHistoryCategory.training,
      ),
      label: map['label']?.toString() ?? '',
      reasons: (map['reasons'] as List?)
              ?.map((item) => item.toString())
              .toList(growable: false) ??
          const <String>[],
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'awardedAt': awardedAt.toIso8601String(),
      'deltaXp': deltaXp,
      'totalXp': totalXp,
      'beforeLevel': beforeLevel,
      'afterLevel': afterLevel,
      'category': category.name,
      'label': label,
      'reasons': reasons,
    };
  }

  bool get leveledUp => afterLevel > beforeLevel;
}
