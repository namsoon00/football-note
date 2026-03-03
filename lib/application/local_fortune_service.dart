import 'dart:math' as math;

import '../domain/entities/player_profile.dart';
import '../domain/entities/training_entry.dart';

class LocalFortuneResult {
  final String fortuneText;
  final String recommendationText;
  final String recommendedProgram;

  const LocalFortuneResult({
    required this.fortuneText,
    required this.recommendationText,
    required this.recommendedProgram,
  });
}

class LocalFortuneService {
  LocalFortuneResult generateResult({
    required TrainingEntry entry,
    required PlayerProfile profile,
    required List<TrainingEntry> history,
    required bool isKo,
  }) {
    final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
    final age = _age(profile.birthDate, date);
    final soccerYears = _age(profile.soccerStartDate, date);
    final recent14 = history
        .where((e) => !e.date.isBefore(date.subtract(const Duration(days: 14))))
        .toList();
    final streak = _streakDays([...history, entry], date);
    final trendScore = _trendScore(recent14);
    final zodiac = _zodiac(profile.birthDate, isKo);
    final weekdayTone = _weekdayTone(date.weekday, isKo);
    final seasonTone = _seasonTone(date.month, isKo);
    final baseSeed = _seed(date, entry, profile, history);

    final energy = _score(
      45 +
          (entry.mood * 10) +
          (entry.intensity * 6) +
          (entry.durationMinutes ~/ 6) +
          (entry.injury ? -18 : 6) +
          (trendScore ~/ 5),
    );
    final focus = _score(
      50 +
          (entry.goal.trim().isNotEmpty ? 12 : -6) +
          (entry.notes.trim().length >= 25 ? 8 : -3) +
          (entry.intensity >= 4 ? 5 : 0),
    );
    final teamwork = _score(
      48 +
          (entry.program.contains('전술') ||
                  entry.program.toLowerCase().contains('tactic')
              ? 16
              : 4) +
          (entry.feedback.trim().isNotEmpty ? 8 : 0),
    );
    final recovery = _score(
      52 +
          (entry.injury ? -15 : 8) +
          ((entry.painLevel ?? 0) >= 4 ? -12 : 5) +
          (entry.durationMinutes >= 90 ? -8 : 6),
    );

    final color = _pick(_luckyColors(isKo), baseSeed + 7);
    final time = _pick(_luckyTimes(isKo), baseSeed + 13);
    final keyword = _pick(_keywords(isKo), baseSeed + 23);
    final caution = _pick(_cautions(isKo), baseSeed + 31);
    final tip = _pick(_tips(isKo), baseSeed + 41);

    final profileLine = _profileBlendLine(
      isKo: isKo,
      age: age,
      soccerYears: soccerYears,
      zodiac: zodiac,
      seed: baseSeed + 59,
    );
    final trainingLine = _trainingBlendLine(
      isKo: isKo,
      entry: entry,
      streak: streak,
      trendScore: trendScore,
      seed: baseSeed + 67,
    );
    final contextLine = isKo
        ? '날짜 흐름: $weekdayTone · 계절 리듬: $seasonTone'
        : 'Date signal: $weekdayTone · Seasonal rhythm: $seasonTone';
    final basisLine = isKo
        ? '분석 근거: 날짜/요일/계절, 프로필(나이·구력·별자리), 최근 14일 추세, 훈련 부하(시간·강도·컨디션), 부상·통증, 목표·메모, 리프팅 분포.'
        : 'Signals used: date/weekday/season, profile (age/experience/zodiac), 14-day trend, load (time/intensity/condition), injury/pain, goal/notes, lifting distribution.';

    final rec = _recommendProgram(
      isKo: isKo,
      entry: entry,
      energy: energy,
      focus: focus,
      recovery: recovery,
      trendScore: trendScore,
    );

    final fortuneText = isKo
        ? '오늘의 축구 운세\n'
            '에너지 $energy · 집중 $focus · 팀워크 $teamwork · 회복 $recovery\n'
            '행운 컬러: $color · 행운 시간: $time · 키워드: $keyword\n'
            '$contextLine\n'
            '$profileLine\n'
            '$trainingLine\n'
            '주의: $caution\n'
            '추천 액션: $tip\n'
            '$basisLine'
        : 'Today\'s Soccer Fortune\n'
            'Energy $energy · Focus $focus · Teamwork $teamwork · Recovery $recovery\n'
            'Lucky color: $color · Lucky time: $time · Keyword: $keyword\n'
            '$contextLine\n'
            '$profileLine\n'
            '$trainingLine\n'
            'Caution: $caution\n'
            'Suggested action: $tip\n'
            '$basisLine';

    return LocalFortuneResult(
      fortuneText: fortuneText,
      recommendationText: rec.$2,
      recommendedProgram: rec.$1,
    );
  }

  String generate({
    required TrainingEntry entry,
    required PlayerProfile profile,
    required List<TrainingEntry> history,
    required bool isKo,
  }) {
    return generateResult(
      entry: entry,
      profile: profile,
      history: history,
      isKo: isKo,
    ).fortuneText;
  }

  int _seed(
    DateTime date,
    TrainingEntry entry,
    PlayerProfile profile,
    List<TrainingEntry> history,
  ) {
    final p = profile.name.trim().runes.fold<int>(0, (a, b) => a + b);
    final h = history.length * 11;
    final l = entry.liftingByPart.values.fold<int>(0, (a, b) => a + b);
    return date.year * 37 +
        date.month * 101 +
        date.day * 271 +
        entry.intensity * 17 +
        entry.mood * 13 +
        entry.durationMinutes * 3 +
        l * 5 +
        p +
        h;
  }

  int _score(num raw) => raw.round().clamp(1, 99);

  int _trendScore(List<TrainingEntry> recent) {
    if (recent.isEmpty) return 0;
    final minutes = recent.fold<int>(0, (s, e) => s + e.durationMinutes);
    final intensity = recent.fold<int>(0, (s, e) => s + e.intensity);
    final mood = recent.fold<int>(0, (s, e) => s + e.mood);
    final injuries = recent.where((e) => e.injury).length;
    final quality = (minutes / math.max(1, recent.length)) ~/ 10;
    return quality + intensity + mood - (injuries * 6);
  }

  int _streakDays(List<TrainingEntry> all, DateTime today) {
    final daySet =
        all.map((e) => DateTime(e.date.year, e.date.month, e.date.day)).toSet();
    var streak = 0;
    for (var i = 0; i < 30; i++) {
      final day = today.subtract(Duration(days: i));
      if (daySet.contains(day)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int? _age(DateTime? from, DateTime at) {
    if (from == null) return null;
    var years = at.year - from.year;
    if (at.month < from.month ||
        (at.month == from.month && at.day < from.day)) {
      years--;
    }
    return years < 0 ? null : years;
  }

  String _profileBlendLine({
    required bool isKo,
    required int? age,
    required int? soccerYears,
    required String zodiac,
    required int seed,
  }) {
    if (age == null && soccerYears == null) {
      return isKo
          ? _pick([
              '프로필 정보가 더 입력되면 운세 정확도가 올라가요.',
              '생년월일/축구 시작일을 입력하면 맞춤 운세가 강화됩니다.',
            ], seed)
          : _pick([
              'Add profile details to improve fortune accuracy.',
              'Birth date and soccer start date make this more personalized.',
            ], seed);
    }
    if (isKo) {
      return '프로필 반영: ${age != null ? '나이 $age세' : '나이 미입력'} · ${soccerYears != null ? '구력 $soccerYears년' : '구력 미입력'} · 별자리 $zodiac 기준으로 리듬을 분석했어요.';
    }
    return 'Profile blend: ${age != null ? 'age $age' : 'age n/a'} · ${soccerYears != null ? '$soccerYears years experience' : 'experience n/a'} · zodiac $zodiac used for rhythm analysis.';
  }

  String _trainingBlendLine({
    required bool isKo,
    required TrainingEntry entry,
    required int streak,
    required int trendScore,
    required int seed,
  }) {
    final kind = entry.program.trim().isNotEmpty
        ? entry.program.trim()
        : entry.type.trim();
    final typeText = kind.isEmpty ? (isKo ? '기본 훈련' : 'base training') : kind;
    final variantsKo = <String>[
      '$typeText 패턴에서 템포 조절 운이 좋습니다. 첫 15분 리듬을 빠르게 잡아보세요. (연속 $streak일, 추세 $trendScore)',
      '$typeText 흐름에서 선택 타이밍이 좋게 들어옵니다. 패스/터치 결정을 빠르게 가져가세요. (연속 $streak일, 추세 $trendScore)',
      '$typeText 훈련에서 반복 정확도가 상승하는 날입니다. 횟수보다 성공 패턴을 고정하세요. (연속 $streak일, 추세 $trendScore)',
    ];
    final variantsEn = <String>[
      'In $typeText, tempo control luck is strong. Set rhythm early in the first 15 min. (streak $streak, trend $trendScore)',
      'In $typeText, decision timing is favorable. Make pass/touch choices quickly. (streak $streak, trend $trendScore)',
      'In $typeText, repetition accuracy is likely to rise. Lock successful patterns over volume. (streak $streak, trend $trendScore)',
    ];
    return _pick(isKo ? variantsKo : variantsEn, seed);
  }

  String _pick(List<String> values, int seed) {
    if (values.isEmpty) return '';
    return values[seed.abs() % values.length];
  }

  List<String> _luckyColors(bool isKo) => isKo
      ? const ['민트', '하늘색', '화이트', '코발트', '라임', '오렌지']
      : const ['Mint', 'Sky blue', 'White', 'Cobalt', 'Lime', 'Orange'];

  List<String> _luckyTimes(bool isKo) => isKo
      ? const [
          '06:30-07:10',
          '09:00-09:40',
          '16:30-17:20',
          '18:10-18:50',
          '20:00-20:40'
        ]
      : const [
          '06:30-07:10',
          '09:00-09:40',
          '16:30-17:20',
          '18:10-18:50',
          '20:00-20:40'
        ];

  List<String> _keywords(bool isKo) => isKo
      ? const ['첫 터치', '시야', '밸런스', '타이밍', '연결', '침착함', '리듬']
      : const [
          'First touch',
          'Vision',
          'Balance',
          'Timing',
          'Link-up',
          'Composure',
          'Rhythm'
        ];

  List<String> _cautions(bool isKo) => isKo
      ? const [
          '초반 오버페이스를 피하고 워밍업을 충분히 하세요.',
          '강도는 좋지만 무리한 방향 전환은 줄이세요.',
          '후반 집중 저하 구간에서 실수가 늘 수 있어요.',
          '동작 크기를 키우기보다 정확도를 먼저 지키세요.',
        ]
      : const [
          'Avoid early overpacing and complete a full warm-up.',
          'Load is good, but reduce aggressive direction changes.',
          'Late-session focus dip may increase mistakes.',
          'Prioritize precision before increasing movement size.',
        ];

  List<String> _tips(bool isKo) => isKo
      ? const [
          '첫 10분: 짧은 패스 성공률 목표를 정하고 시작하세요.',
          '중반 20분: 2터치 이내 플레이 비율을 높여보세요.',
          '마무리 10분: 오늘 성공 장면 3가지를 메모로 남기세요.',
          '훈련 직후 수분/스트레칭 루틴을 바로 실행하세요.',
        ]
      : const [
          'First 10 min: start with a short-pass accuracy target.',
          'Middle 20 min: increase the share of 2-touch actions.',
          'Last 10 min: log three successful moments today.',
          'Run hydration/stretching routine immediately after training.',
        ];

  String _zodiac(DateTime? birthDate, bool isKo) {
    if (birthDate == null) return isKo ? '미입력' : 'n/a';
    final m = birthDate.month;
    final d = birthDate.day;
    if ((m == 3 && d >= 21) || (m == 4 && d <= 19)) {
      return isKo ? '양자리' : 'Aries';
    }
    if ((m == 4 && d >= 20) || (m == 5 && d <= 20)) {
      return isKo ? '황소자리' : 'Taurus';
    }
    if ((m == 5 && d >= 21) || (m == 6 && d <= 21)) {
      return isKo ? '쌍둥이자리' : 'Gemini';
    }
    if ((m == 6 && d >= 22) || (m == 7 && d <= 22)) {
      return isKo ? '게자리' : 'Cancer';
    }
    if ((m == 7 && d >= 23) || (m == 8 && d <= 22)) {
      return isKo ? '사자자리' : 'Leo';
    }
    if ((m == 8 && d >= 23) || (m == 9 && d <= 22)) {
      return isKo ? '처녀자리' : 'Virgo';
    }
    if ((m == 9 && d >= 23) || (m == 10 && d <= 22)) {
      return isKo ? '천칭자리' : 'Libra';
    }
    if ((m == 10 && d >= 23) || (m == 11 && d <= 22)) {
      return isKo ? '전갈자리' : 'Scorpio';
    }
    if ((m == 11 && d >= 23) || (m == 12 && d <= 24)) {
      return isKo ? '사수자리' : 'Sagittarius';
    }
    if ((m == 12 && d >= 25) || (m == 1 && d <= 19)) {
      return isKo ? '염소자리' : 'Capricorn';
    }
    if ((m == 1 && d >= 20) || (m == 2 && d <= 18)) {
      return isKo ? '물병자리' : 'Aquarius';
    }
    return isKo ? '물고기자리' : 'Pisces';
  }

  String _weekdayTone(int weekday, bool isKo) {
    const ko = <int, String>{
      DateTime.monday: '월요일 스타트 집중력 상승',
      DateTime.tuesday: '화요일 반복 훈련 적합',
      DateTime.wednesday: '수요일 리듬 안정',
      DateTime.thursday: '목요일 전환 속도 유리',
      DateTime.friday: '금요일 감각 회복 유리',
      DateTime.saturday: '토요일 실전 감각 상승',
      DateTime.sunday: '일요일 회복·정리 적합',
    };
    const en = <int, String>{
      DateTime.monday: 'Monday start-focus boost',
      DateTime.tuesday: 'Tuesday repetition-friendly',
      DateTime.wednesday: 'Wednesday rhythm stability',
      DateTime.thursday: 'Thursday transition speed edge',
      DateTime.friday: 'Friday touch recovery edge',
      DateTime.saturday: 'Saturday match-feel boost',
      DateTime.sunday: 'Sunday recovery/reset fit',
    };
    return (isKo ? ko : en)[weekday]!;
  }

  String _seasonTone(int month, bool isKo) {
    if (month >= 3 && month <= 5) {
      return isKo ? '봄: 기술 흡수력 상승' : 'Spring: skill absorption up';
    }
    if (month >= 6 && month <= 8) {
      return isKo ? '여름: 수분·회복 관리 중요' : 'Summer: hydration/recovery critical';
    }
    if (month >= 9 && month <= 11) {
      return isKo ? '가을: 강도 상승 유리' : 'Autumn: load increase favorable';
    }
    return isKo ? '겨울: 워밍업 품질 최우선' : 'Winter: warm-up quality first';
  }

  (String, String) _recommendProgram({
    required bool isKo,
    required TrainingEntry entry,
    required int energy,
    required int focus,
    required int recovery,
    required int trendScore,
  }) {
    if (entry.injury || (entry.painLevel ?? 0) >= 5 || recovery < 45) {
      return (
        isKo ? '회복' : 'Recovery',
        isKo
            ? '회복 세션을 추천해요: 40~50분, 저강도 볼터치 + 가동성 + 마무리 스트레칭.'
            : 'Recommended recovery session: 40-50 min, low-intensity ball touch + mobility + cooldown stretch.',
      );
    }
    if (energy >= 72 && focus >= 68 && trendScore >= 30) {
      return (
        isKo ? '전술' : 'Tactical',
        isKo
            ? '전술 세션을 추천해요: 패스 선택 속도와 위치 전환 패턴을 중심으로 60~75분.'
            : 'Recommended tactical session: 60-75 min focused on pass decision speed and position transitions.',
      );
    }
    if (focus < 55) {
      return (
        isKo ? '기본기' : 'Fundamentals',
        isKo
            ? '기본기 세션을 추천해요: 첫 터치와 짧은 패스 정확도 루틴을 45~60분.'
            : 'Recommended fundamentals session: 45-60 min on first touch and short-pass accuracy routines.',
      );
    }
    return (
      isKo ? '피지컬' : 'Physical',
      isKo
          ? '피지컬 세션을 추천해요: 인터벌 이동 + 코어 안정 + 마무리 볼컨트롤 55~70분.'
          : 'Recommended physical session: 55-70 min with interval movement + core stability + finishing ball control.',
    );
  }
}
