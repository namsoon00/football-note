import 'dart:convert';

import '../domain/entities/training_entry.dart';
import '../domain/repositories/option_repository.dart';

class PlayerLevelService {
  static const String totalXpKey = 'player_total_xp_v1';
  static const String quizRewardDayKey = 'player_quiz_reward_day_v1';
  static const String awardedPlanIdsKey = 'player_awarded_plan_ids_v1';
  static const String awardedStreaksKey = 'player_awarded_streaks_v1';
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
  ];

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
    final existingTrainingEntries =
        existingEntries.where((item) => !item.isMatch).toList(growable: false);
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
    final afterWeeklyCount =
        updatedEntries.where((item) => _isSameWeek(item.date, entryDay)).length;
    if (beforeWeeklyCount < 3 && afterWeeklyCount >= 3) {
      gainedXp += 40;
      reasons.add('weekly_3');
    }
    if (beforeWeeklyCount < 5 && afterWeeklyCount >= 5) {
      gainedXp += 70;
      reasons.add('weekly_5');
    }

    final nextTotal = before.totalXp + gainedXp;
    await _options.setValue(totalXpKey, nextTotal);
    await _options.setValue(
      awardedStreaksKey,
      awardedStreaks.toList()..sort(),
    );
    final after = PlayerLevelState.fromXp(nextTotal);
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
    await _options.setValue(
      awardedPlanIdsKey,
      awardedPlanIds.toList()..sort(),
    );
    final after = PlayerLevelState.fromXp(nextTotal);
    return PlayerLevelAward(
      gainedXp: gainedXp,
      before: before,
      after: after,
      reasons: const <String>['plan_created'],
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
      default:
        return isKo ? '레전드 트랙' : 'Legend Track';
    }
  }

  static String stageName(int level, bool isKo) {
    if (level <= 2) return isKo ? '입문 선수' : 'New Ground';
    if (level <= 4) return isKo ? '훈련 루키' : 'Training Rookie';
    if (level <= 6) return isKo ? '주전 성장기' : 'First Team Rise';
    if (level <= 8) return isKo ? '경기 리더' : 'Match Leader';
    return isKo ? '엘리트 트랙' : 'Elite Track';
  }

  static String illustrationLabel(int level, bool isKo) {
    if (level <= 2) return isKo ? '운동장 시작' : 'Field Start';
    if (level <= 4) return isKo ? '훈련 장비 해금' : 'Training Gear';
    if (level <= 6) return isKo ? '전술 보드 해금' : 'Tactics Board';
    if (level <= 8) return isKo ? '주장 완장 해금' : 'Captain Band';
    return isKo ? '스타디움 조명 해금' : 'Stadium Lights';
  }

  Set<String> _getStringSet(String key) {
    final raw = _options.getValue<List>(key) ?? const [];
    return raw.map((item) => item.toString()).toSet();
  }

  bool _hasPlanOnDay(DateTime day) {
    final raw = _options.getValue<String>(plansStorageKey);
    if (raw == null || raw.trim().isEmpty) return false;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return false;
      return decoded.whereType<Map>().any((item) {
        final map = item.cast<String, dynamic>();
        final scheduledAt =
            DateTime.tryParse(map['scheduledAt']?.toString() ?? '');
        return scheduledAt != null && _normalizeDay(scheduledAt) == day;
      });
    } catch (_) {
      return false;
    }
  }

  int _calculateTrainingStreak(List<TrainingEntry> entries) {
    if (entries.isEmpty) return 0;
    final days = entries
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
    for (var index = 0;
        index < PlayerLevelService._levelThresholds.length;
        index++) {
      final threshold = PlayerLevelService._levelThresholds[index];
      if (totalXp >= threshold) {
        level = index + 1;
      }
    }
    final currentLevelXp = PlayerLevelService._levelThresholds[
        (level - 1).clamp(0, PlayerLevelService._levelThresholds.length - 1)];
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
