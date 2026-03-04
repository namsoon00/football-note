import 'dart:math' as math;

import '../domain/entities/training_entry.dart';

class LocalRuleCoachingService {
  String generate({
    required TrainingEntry entry,
    required List<TrainingEntry> history,
    required bool isKo,
  }) {
    final timeline = [...history, entry]
      ..sort((a, b) => a.date.compareTo(b.date));
    final now = entry.date;
    final weekStart = _weekStart(now);
    final weekEntries =
        timeline.where((e) => !e.date.isBefore(weekStart)).toList();
    final weekMinutes =
        weekEntries.fold<int>(0, (sum, e) => sum + e.durationMinutes);
    final weekSessions = weekEntries.length;
    final weekAvgIntensity = weekEntries.isEmpty
        ? entry.intensity.toDouble()
        : weekEntries.fold<int>(0, (sum, e) => sum + e.intensity) /
            weekEntries.length;
    final weekAvgMood = weekEntries.isEmpty
        ? entry.mood.toDouble()
        : weekEntries.fold<int>(0, (sum, e) => sum + e.mood) /
            weekEntries.length;

    final liftingTotal =
        entry.liftingByPart.values.fold<int>(0, (a, b) => a + b);
    final liftingVariety =
        entry.liftingByPart.values.where((c) => c > 0).length;
    final notesLen =
        '${entry.improvements} ${entry.goodPoints} ${entry.notes}'.trim().length;
    final goalLen =
        '${entry.nextGoal} ${entry.goalFocuses.join(' ')} ${entry.goal}'
            .trim()
            .length;
    final focusProgram =
        entry.type.trim().isNotEmpty ? entry.type.trim() : entry.program.trim();

    final streak = _streakDays(timeline);
    final loadScore = (entry.durationMinutes / 15).round() +
        (entry.intensity * 2) +
        (entry.mood * 2) +
        (entry.injury ? -5 : 2) +
        (entry.rehab ? -2 : 1);
    final seed =
        (now.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay) + loadScore;

    final lines = <String>[];
    lines.add(_summaryLine(
      isKo: isKo,
      duration: entry.durationMinutes,
      intensity: entry.intensity,
      mood: entry.mood,
      weekSessions: weekSessions,
      weekMinutes: weekMinutes,
    ));

    if (entry.injury || (entry.painLevel ?? 0) >= 4 || entry.rehab) {
      lines.add(_safetyLine(
        isKo: isKo,
        pain: entry.painLevel ?? 0,
        rehab: entry.rehab,
        seed: seed,
      ));
    } else {
      lines.add(_loadAdjustmentLine(
        isKo: isKo,
        duration: entry.durationMinutes,
        intensity: entry.intensity,
        mood: entry.mood,
        weekAvgIntensity: weekAvgIntensity,
        weekAvgMood: weekAvgMood,
        seed: seed,
      ));
    }

    lines.add(_focusLine(
      isKo: isKo,
      focusProgram: focusProgram,
      hasGoal: goalLen > 0,
      notesLen: notesLen,
      liftingTotal: liftingTotal,
      liftingVariety: liftingVariety,
      seed: seed,
    ));

    lines.add(_motivationLine(
      isKo: isKo,
      streak: streak,
      weekSessions: weekSessions,
      weekMinutes: weekMinutes,
      seed: seed,
    ));

    return lines.where((line) => line.trim().isNotEmpty).join('\n');
  }

  DateTime _weekStart(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return normalized
        .subtract(Duration(days: normalized.weekday - DateTime.monday));
  }

  int _streakDays(List<TrainingEntry> entries) {
    if (entries.isEmpty) return 0;
    final days = entries
        .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
        .toSet()
        .toList()
      ..sort();
    var streak = 1;
    for (var i = days.length - 1; i > 0; i--) {
      final diff = days[i].difference(days[i - 1]).inDays;
      if (diff == 1) {
        streak++;
      } else if (diff > 1) {
        break;
      }
    }
    return streak;
  }

  String _summaryLine({
    required bool isKo,
    required int duration,
    required int intensity,
    required int mood,
    required int weekSessions,
    required int weekMinutes,
  }) {
    if (isKo) {
      return '이번 훈련은 ${duration > 0 ? '$duration분' : '시간 미설정'} · 강도 $intensity · 컨디션 $mood 입니다. 이번 주 누적은 $weekSessions회 / $weekMinutes분이에요.';
    }
    return 'This session is ${duration > 0 ? '$duration min' : 'no duration'} · intensity $intensity · condition $mood. Weekly total is $weekSessions sessions / $weekMinutes min.';
  }

  String _safetyLine({
    required bool isKo,
    required int pain,
    required bool rehab,
    required int seed,
  }) {
    if (pain >= 7) {
      return isKo
          ? '통증 지수($pain)가 높습니다. 다음 훈련은 강도를 1~2단계 낮추고 충격이 적은 볼터치/패스 중심으로 전환하세요.'
          : 'Pain level ($pain) is high. Lower intensity by 1-2 levels next session and switch to low-impact touch/pass work.';
    }
    final variantsKo = <String>[
      '부상/회복 상태가 있어 워밍업 12분 + 정리운동 8분을 고정해 주세요.',
      '회복 신호가 감지됩니다. 다음 세션은 볼 감각 유지와 가동성 중심으로 짧게 구성하세요.',
      '무리보다 연속성이 중요합니다. 내일은 저강도 기술 반복으로 연결해 주세요.',
    ];
    final variantsEn = <String>[
      'With injury/rehab status, lock in 12 min warm-up + 8 min cool-down.',
      'Recovery signal detected. Keep the next session short with touch and mobility focus.',
      'Consistency matters more than load now. Follow up with a low-intensity technical session.',
    ];
    return _pick(isKo ? variantsKo : variantsEn, seed + (rehab ? 1 : 2));
  }

  String _loadAdjustmentLine({
    required bool isKo,
    required int duration,
    required int intensity,
    required int mood,
    required double weekAvgIntensity,
    required double weekAvgMood,
    required int seed,
  }) {
    if (duration >= 90 && intensity >= 4 && mood <= 3) {
      return isKo
          ? '훈련 부하가 높은 편입니다. 다음 세션은 60분 이하로 줄이고 첫 20분은 정확도 위주로 가져가세요.'
          : 'Training load is high. Keep the next session under 60 min and use the first 20 min for precision work.';
    }
    if (duration < 40 || intensity <= 2) {
      return isKo
          ? '자극이 다소 약했습니다. 다음 훈련은 핵심 구간(20~30분)의 템포를 올려 훈련 밀도를 높여보세요.'
          : 'Stimulus was a bit low. Increase tempo in the key 20-30 min block next session.';
    }
    final variantsKo = <String>[
      '강도/컨디션 균형이 좋습니다. 다음 세션은 현재 강도를 유지하고 정확도 지표(성공률)를 추가로 기록해 보세요.',
      '이번 주 평균(강도 ${weekAvgIntensity.toStringAsFixed(1)}, 컨디션 ${weekAvgMood.toStringAsFixed(1)})과 비교해 안정적입니다. 리듬을 유지하세요.',
      '훈련 페이스가 안정적입니다. 다음에는 마지막 10분에 의사결정 속도 훈련을 넣어 완성도를 높이세요.',
    ];
    final variantsEn = <String>[
      'Intensity/condition balance is good. Keep this load and track a precision metric next session.',
      'Stable against weekly averages (intensity ${weekAvgIntensity.toStringAsFixed(1)}, condition ${weekAvgMood.toStringAsFixed(1)}). Keep this rhythm.',
      'Session pace is steady. Add a decision-speed block in the last 10 minutes next time.',
    ];
    return _pick(isKo ? variantsKo : variantsEn, seed + intensity + mood);
  }

  String _focusLine({
    required bool isKo,
    required String focusProgram,
    required bool hasGoal,
    required int notesLen,
    required int liftingTotal,
    required int liftingVariety,
    required int seed,
  }) {
    final program = focusProgram.isEmpty
        ? (isKo ? '기술/패스' : 'technical/pass')
        : focusProgram;
    final goalPart = hasGoal
        ? (isKo
            ? '목표 설정이 명확해 집중력이 좋습니다.'
            : 'Goal setting is clear and focused.')
        : (isKo
            ? '다음 훈련은 목표를 숫자로 적어 주세요(예: 성공 패스 40회).'
            : 'Set a numeric goal next time (e.g., 40 successful passes).');

    if (liftingTotal > 0) {
      final liftLine = isKo
          ? '리프팅은 총 $liftingTotal회, 부위 $liftingVariety개를 사용했습니다.'
          : 'Lifting total is $liftingTotal reps across $liftingVariety parts.';
      return '$goalPart ${isKo ? '오늘의 중심 프로그램은' : 'Today\'s focus program is'} $program. $liftLine';
    }

    final noteFeedback = notesLen >= 30
        ? (isKo
            ? '메모가 구체적이라 다음 피드백 품질이 높아집니다.'
            : 'Notes are detailed, which improves next-session feedback quality.')
        : (isKo
            ? '다음에는 성공/실패 장면을 한 줄씩 남겨 주세요.'
            : 'Next time, add one line each for success and failure moments.');
    final variants = isKo
        ? <String>[
            '$goalPart 오늘의 중심 프로그램은 $program 입니다. $noteFeedback',
            '$goalPart $program 훈련에서는 첫 터치 방향과 다음 선택(패스/운반) 연결을 우선으로 보세요. $noteFeedback',
            '$goalPart $program 파트는 반복 횟수보다 성공 패턴 고정이 먼저입니다. $noteFeedback',
          ]
        : <String>[
            '$goalPart Focus program today is $program. $noteFeedback',
            '$goalPart In $program work, prioritize first-touch direction and next action linking (pass/carry). $noteFeedback',
            '$goalPart In $program, lock in successful patterns before chasing volume. $noteFeedback',
          ];
    return _pick(variants, seed + notesLen);
  }

  String _motivationLine({
    required bool isKo,
    required int streak,
    required int weekSessions,
    required int weekMinutes,
    required int seed,
  }) {
    const targetSessions = 3;
    final remaining = math.max(0, targetSessions - weekSessions);
    if (remaining == 0) {
      return isKo
          ? '이번 주 3회 목표를 달성했습니다. 다음 목표는 주간 총 20~30분 추가입니다.'
          : 'You hit the 3-session weekly goal. Next target is +20-30 weekly minutes.';
    }
    final streakLine = streak >= 3
        ? (isKo ? '연속 $streak일 기록이 좋습니다.' : '$streak-day streak looks great.')
        : (isKo ? '리듬을 만들기 시작했습니다.' : 'You are building rhythm.');
    final variantsKo = <String>[
      '$streakLine 이번 주 목표까지 $remaining회 남았습니다. 다음 세션은 시작 시간을 고정해 꾸준함을 만드세요.',
      '$streakLine 현재 주간 $weekMinutes분입니다. 다음 1회는 45~60분으로 맞추면 주간 균형이 좋아집니다.',
      '$streakLine 목표까지 $remaining회 남았습니다. 일정표에 다음 훈련 날짜를 지금 확정해 보세요.',
    ];
    final variantsEn = <String>[
      '$streakLine $remaining session(s) left for this week\'s goal. Fix the next start time for consistency.',
      '$streakLine You are at $weekMinutes weekly minutes. One more 45-60 min session will balance the week.',
      '$streakLine $remaining session(s) left. Lock in the next training date now.',
    ];
    return _pick(isKo ? variantsKo : variantsEn, seed + weekSessions + streak);
  }

  String _pick(List<String> options, int seed) {
    if (options.isEmpty) return '';
    final index = seed.abs() % options.length;
    return options[index];
  }
}
