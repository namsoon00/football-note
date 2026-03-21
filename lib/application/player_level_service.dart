import 'dart:convert';

import '../domain/entities/training_entry.dart';
import '../domain/repositories/option_repository.dart';

class PlayerLevelService {
  static const String totalXpKey = 'player_total_xp_v1';
  static const String xpHistoryKey = 'player_xp_history_v1';
  static const String quizRewardDayKey = 'player_quiz_reward_day_v1';
  static const String awardedPlanIdsKey = 'player_awarded_plan_ids_v1';
  static const String awardedStreaksKey = 'player_awarded_streaks_v1';
  static const String awardedBoardSaveTokensKey =
      'player_awarded_board_save_tokens_v1';
  static const String diaryReviewDayKey = 'player_diary_review_day_v1';
  static const String claimedRewardLevelsKey =
      'player_claimed_reward_levels_v1';
  static const String customRewardNamesKey = 'player_custom_reward_names_v1';
  static const String plansStorageKey = 'training_plans_v1';

  static const List<int> _levelThresholds = <int>[
    0,
    20,
    55,
    105,
    175,
    270,
    390,
    540,
    730,
    970,
    1260,
    1610,
    2020,
    2490,
    3020,
    3610,
    4260,
    4970,
    5740,
    6570,
  ];

  static List<int> get levelThresholds =>
      List<int>.unmodifiable(_levelThresholds);

  static List<PlayerLevelReward> get levelRewards =>
      List<PlayerLevelReward>.generate(
        _levelThresholds.length,
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
    final reasons = <String>[];
    var gainedXp = 0;
    final entryDay = _normalizeDay(entry.date);
    final existingTrainingEntries = existingEntries
        .where((item) => !item.isMatch)
        .toList(growable: false);
    final sameDayEntries = existingTrainingEntries
        .where((item) => _normalizeDay(item.date) == entryDay)
        .toList(growable: false);

    gainedXp += 20;
    reasons.add('log');

    if (sameDayEntries.isEmpty) {
      gainedXp += 10;
      reasons.add('first_daily_log');
    }

    if (_hasPlanOnDay(entryDay) && sameDayEntries.isEmpty) {
      gainedXp += 25;
      reasons.add('plan_completed');
    }

    final liftingDone = entry.liftingByPart.values.any((count) => count > 0);
    if (!liftingDone) {
      gainedXp -= 10;
      reasons.add('lifting_missed');
    }
    final jumpRopeDone =
        entry.jumpRopeCount > 0 ||
        entry.jumpRopeMinutes > 0 ||
        entry.jumpRopeNote.trim().isNotEmpty;
    if (!jumpRopeDone) {
      gainedXp -= 10;
      reasons.add('jump_rope_missed');
    }

    final updatedEntries = <TrainingEntry>[...existingTrainingEntries, entry];
    final streak = _calculateTrainingStreak(updatedEntries);
    final awardedStreaks = _getStringSet(awardedStreaksKey);
    final dayToken = _dayKey(entryDay);
    if (streak >= 3 && awardedStreaks.add('$dayToken:3')) {
      gainedXp += 25;
      reasons.add('streak_3');
    }
    if (streak >= 7 && awardedStreaks.add('$dayToken:7')) {
      gainedXp += 60;
      reasons.add('streak_7');
    }

    final beforeWeeklyCount = existingTrainingEntries
        .where((item) => _isSameWeek(item.date, entryDay))
        .length;
    final afterWeeklyCount = updatedEntries
        .where((item) => _isSameWeek(item.date, entryDay))
        .length;
    if (beforeWeeklyCount < 3 && afterWeeklyCount >= 3) {
      gainedXp += 40;
      reasons.add('weekly_3');
    }
    if (beforeWeeklyCount < 5 && afterWeeklyCount >= 5) {
      gainedXp += 70;
      reasons.add('weekly_5');
    }

    final nextTotal = (before.totalXp + gainedXp).clamp(0, 1000000).toInt();
    await _options.setValue(totalXpKey, nextTotal);
    await _options.setValue(awardedStreaksKey, awardedStreaks.toList()..sort());
    final after = PlayerLevelState.fromXp(nextTotal);
    await _appendXpHistory(
      PlayerXpHistoryEntry(
        awardedAt: entry.createdAt,
        deltaXp: gainedXp,
        totalXp: nextTotal,
        beforeLevel: before.level,
        afterLevel: after.level,
        category: PlayerXpHistoryCategory.training,
        label: entry.program.trim().isNotEmpty
            ? entry.program.trim()
            : entry.type,
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

  Future<PlayerLevelAward> awardForQuizCompletion({
    DateTime? completedAt,
  }) async {
    final before = loadState();
    final day = _normalizeDay(completedAt ?? DateTime.now());
    final token = _dayKey(day);
    if ((_options.getValue<String>(quizRewardDayKey) ?? '') == token) {
      return PlayerLevelAward(
        gainedXp: 0,
        before: before,
        after: before,
        reasons: const <String>[],
      );
    }

    const gainedXp = 15;
    final nextTotal = before.totalXp + gainedXp;
    await _options.setValue(totalXpKey, nextTotal);
    await _options.setValue(quizRewardDayKey, token);
    final after = PlayerLevelState.fromXp(nextTotal);
    await _appendXpHistory(
      PlayerXpHistoryEntry(
        awardedAt: completedAt ?? DateTime.now(),
        deltaXp: gainedXp,
        totalXp: nextTotal,
        beforeLevel: before.level,
        afterLevel: after.level,
        category: PlayerXpHistoryCategory.quiz,
        label: '',
        reasons: const <String>['quiz_complete'],
      ),
    );
    return PlayerLevelAward(
      gainedXp: gainedXp,
      before: before,
      after: after,
      reasons: const <String>['quiz_complete'],
    );
  }

  Future<PlayerLevelAward> awardForPlanCreated({required String planId}) async {
    final before = loadState();
    final awardedPlanIds = _getStringSet(awardedPlanIdsKey);
    if (!awardedPlanIds.add(planId)) {
      return PlayerLevelAward(
        gainedXp: 0,
        before: before,
        after: before,
        reasons: const <String>[],
      );
    }

    const gainedXp = 10;
    final nextTotal = before.totalXp + gainedXp;
    await _options.setValue(totalXpKey, nextTotal);
    await _options.setValue(awardedPlanIdsKey, awardedPlanIds.toList()..sort());
    final after = PlayerLevelState.fromXp(nextTotal);
    await _appendXpHistory(
      PlayerXpHistoryEntry(
        awardedAt: DateTime.now(),
        deltaXp: gainedXp,
        totalXp: nextTotal,
        beforeLevel: before.level,
        afterLevel: after.level,
        category: PlayerXpHistoryCategory.plan,
        label: planId,
        reasons: const <String>['plan_created'],
      ),
    );
    return PlayerLevelAward(
      gainedXp: gainedXp,
      before: before,
      after: after,
      reasons: const <String>['plan_created'],
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
    final token = '$boardId:${_dayKey(now)}';
    if (!awardedTokens.add(token)) {
      return PlayerLevelAward(
        gainedXp: 0,
        before: before,
        after: before,
        reasons: const <String>[],
      );
    }

    final gainedXp = created ? 12 : 8;
    final reasons = <String>[created ? 'board_created' : 'board_saved'];
    final nextTotal = before.totalXp + gainedXp;
    await _options.setValue(totalXpKey, nextTotal);
    await _options.setValue(
      awardedBoardSaveTokensKey,
      awardedTokens.toList()..sort(),
    );
    final after = PlayerLevelState.fromXp(nextTotal);
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
    return PlayerLevelAward(
      gainedXp: gainedXp,
      before: before,
      after: after,
      reasons: reasons,
    );
  }

  Future<PlayerLevelAward> awardForDiaryReview({DateTime? reviewedAt}) async {
    final before = loadState();
    final day = _normalizeDay(reviewedAt ?? DateTime.now());
    final token = _dayKey(day);
    if ((_options.getValue<String>(diaryReviewDayKey) ?? '') == token) {
      return PlayerLevelAward(
        gainedXp: 0,
        before: before,
        after: before,
        reasons: const <String>[],
      );
    }

    const gainedXp = 5;
    final nextTotal = before.totalXp + gainedXp;
    await _options.setValue(totalXpKey, nextTotal);
    await _options.setValue(diaryReviewDayKey, token);
    final after = PlayerLevelState.fromXp(nextTotal);
    await _appendXpHistory(
      PlayerXpHistoryEntry(
        awardedAt: reviewedAt ?? DateTime.now(),
        deltaXp: gainedXp,
        totalXp: nextTotal,
        beforeLevel: before.level,
        afterLevel: after.level,
        category: PlayerXpHistoryCategory.diary,
        label: '',
        reasons: const <String>['diary_reviewed'],
      ),
    );
    return PlayerLevelAward(
      gainedXp: gainedXp,
      before: before,
      after: after,
      reasons: const <String>['diary_reviewed'],
    );
  }

  static String levelName(int level, bool isKo) {
    switch (level) {
      case 1:
        return isKo ? '킥오프' : 'Kickoff';
      case 2:
        return isKo ? '루키' : 'Rookie';
      case 3:
        return isKo ? '스타터' : 'Starter';
      case 4:
        return isKo ? '챌린저' : 'Challenger';
      case 5:
        return isKo ? '플레이메이커' : 'Playmaker';
      case 6:
        return isKo ? '엔진' : 'Engine';
      case 7:
        return isKo ? '캡틴' : 'Captain';
      case 8:
        return isKo ? '엘리트' : 'Elite';
      case 9:
        return isKo ? '매치 리더' : 'Match Leader';
      case 10:
        return isKo ? '하이 퍼포머' : 'High Performer';
      case 11:
        return isKo ? '드라이버' : 'Driver';
      case 12:
        return isKo ? '필드 메이커' : 'Field Maker';
      case 13:
        return isKo ? '컨트롤 타워' : 'Control Tower';
      case 14:
        return isKo ? '아이언 캡틴' : 'Iron Captain';
      case 15:
        return isKo ? '게임 체인저' : 'Game Changer';
      case 16:
        return isKo ? '세션 마스터' : 'Session Master';
      case 17:
        return isKo ? '에이스 코어' : 'Ace Core';
      case 18:
        return isKo ? '피치 아티스트' : 'Pitch Artist';
      case 19:
        return isKo ? '스타디움 아이콘' : 'Stadium Icon';
      case 20:
        return isKo ? '풋볼 선물왕' : 'Football Gift Master';
      default:
        return isKo ? '레전드 트랙' : 'Legend Track';
    }
  }

  static String stageName(int level, bool isKo) {
    if (level <= 2) return isKo ? '입문 선수' : 'New Ground';
    if (level <= 4) return isKo ? '훈련 루키' : 'Training Rookie';
    if (level <= 6) return isKo ? '주전 성장기' : 'First Team Rise';
    if (level <= 8) return isKo ? '경기 리더' : 'Match Leader';
    if (level <= 12) return isKo ? '상위 경쟁자' : 'Upper Tier';
    if (level <= 16) return isKo ? '핵심 에이스' : 'Core Ace';
    return isKo ? '엘리트 트랙' : 'Elite Track';
  }

  static String illustrationLabel(int level, bool isKo) {
    switch (level.clamp(1, 20)) {
      case 1:
        return isKo ? '시작 호루라기' : 'Starter whistle';
      case 2:
        return isKo ? '첫 축구공' : 'First football';
      case 3:
        return isKo ? '훈련 콘' : 'Training cone';
      case 4:
        return isKo ? '스피드 축구화' : 'Speed boots';
      case 5:
        return isKo ? '줄넘기 리듬' : 'Jump-rope rhythm';
      case 6:
        return isKo ? '힘쎈 아령' : 'Power dumbbell';
      case 7:
        return isKo ? '작전 보드' : 'Tactics board';
      case 8:
        return isKo ? '주장 왕관' : 'Captain crown';
      case 9:
        return isKo ? '우승 트로피' : 'Winner trophy';
      case 10:
        return isKo ? '축하 불꽃' : 'Celebration fireworks';
      case 11:
        return isKo ? '수비 방패' : 'Defense shield';
      case 12:
        return isKo ? '골키퍼 장갑' : 'Keeper gloves';
      case 13:
        return isKo ? '전술 레이더' : 'Tactics radar';
      case 14:
        return isKo ? '질주 번개' : 'Sprint lightning';
      case 15:
        return isKo ? '승리 메달' : 'Victory medal';
      case 16:
        return isKo ? '홈 경기장' : 'Home stadium';
      case 17:
        return isKo ? '에이스 로켓' : 'Ace rocket';
      case 18:
        return isKo ? '피치 스타' : 'Pitch star';
      case 19:
        return isKo ? '스타디움 선물상자' : 'Stadium gift box';
      default:
        return isKo ? '레전드 은하' : 'Legend galaxy';
    }
  }

  static PlayerLevelReward? rewardForLevel(int level) {
    if (level < 1 || level > _levelThresholds.length) return null;
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
        return scheduledAt != null && _normalizeDay(scheduledAt) == day;
      });
    } catch (_) {
      return false;
    }
  }

  int _calculateTrainingStreak(List<TrainingEntry> entries) {
    if (entries.isEmpty) return 0;
    final days =
        entries
            .map((entry) => _normalizeDay(entry.date))
            .toSet()
            .toList(growable: false)
          ..sort((a, b) => b.compareTo(a));
    var streak = 0;
    var cursor = days.first;
    for (final day in days) {
      if (day == cursor) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
    }
    return streak;
  }

  bool _isSameWeek(DateTime date, DateTime targetDay) {
    final normalizedDate = _normalizeDay(date);
    final weekStart = targetDay.subtract(Duration(days: targetDay.weekday - 1));
    final weekEndExclusive = weekStart.add(const Duration(days: 7));
    return !normalizedDate.isBefore(weekStart) &&
        normalizedDate.isBefore(weekEndExclusive);
  }

  DateTime _normalizeDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _dayKey(DateTime value) {
    final normalized = _normalizeDay(value);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
  }

  Future<void> _appendXpHistory(PlayerXpHistoryEntry entry) async {
    final history = loadXpHistory().take(199).toList(growable: true);
    history.insert(0, entry);
    await _options.setValue(
      xpHistoryKey,
      history.map((item) => item.toMap()).toList(growable: false),
    );
  }
}

class PlayerLevelState {
  final int totalXp;
  final int level;
  final int currentLevelXp;
  final int xpIntoLevel;
  final int xpToNextLevel;
  final double progress;

  const PlayerLevelState({
    required this.totalXp,
    required this.level,
    required this.currentLevelXp,
    required this.xpIntoLevel,
    required this.xpToNextLevel,
    required this.progress,
  });

  factory PlayerLevelState.fromXp(int totalXp) {
    var level = 1;
    for (
      var index = 0;
      index < PlayerLevelService._levelThresholds.length;
      index++
    ) {
      final threshold = PlayerLevelService._levelThresholds[index];
      if (totalXp >= threshold) {
        level = index + 1;
      }
    }
    final currentLevelXp =
        PlayerLevelService._levelThresholds[(level - 1).clamp(
          0,
          PlayerLevelService._levelThresholds.length - 1,
        )];
    final nextLevelXp = level >= PlayerLevelService._levelThresholds.length
        ? currentLevelXp + 260
        : PlayerLevelService._levelThresholds[level];
    final span = (nextLevelXp - currentLevelXp).clamp(1, 1000000);
    final progress = ((totalXp - currentLevelXp) / span).clamp(0.0, 1.0);
    return PlayerLevelState(
      totalXp: totalXp,
      level: level,
      currentLevelXp: currentLevelXp,
      xpIntoLevel: totalXp - currentLevelXp,
      xpToNextLevel: nextLevelXp - totalXp,
      progress: progress,
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

enum PlayerXpHistoryCategory { training, quiz, plan, board, diary }

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
      awardedAt:
          DateTime.tryParse(map['awardedAt']?.toString() ?? '') ??
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
      reasons:
          (map['reasons'] as List?)
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
