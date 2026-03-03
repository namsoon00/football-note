import '../domain/entities/player_profile.dart';
import '../domain/entities/training_entry.dart';

class LocalFortuneService {
  String generate({
    required TrainingEntry entry,
    required PlayerProfile profile,
    required List<TrainingEntry> history,
    required bool isKo,
  }) {
    final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
    final age = _age(profile.birthDate, date);
    final soccerYears = _age(profile.soccerStartDate, date);
    final baseSeed = _seed(date, entry, profile, history);

    final energy = _score(
      45 +
          (entry.mood * 10) +
          (entry.intensity * 6) +
          (entry.durationMinutes ~/ 6) +
          (entry.injury ? -18 : 6),
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
      seed: baseSeed + 59,
    );
    final trainingLine = _trainingBlendLine(
      isKo: isKo,
      entry: entry,
      seed: baseSeed + 67,
    );

    if (isKo) {
      return '오늘의 축구 운세\n'
          '에너지 $energy · 집중 $focus · 팀워크 $teamwork · 회복 $recovery\n'
          '행운 컬러: $color · 행운 시간: $time · 키워드: $keyword\n'
          '$profileLine\n'
          '$trainingLine\n'
          '주의: $caution\n'
          '추천 액션: $tip';
    }
    return 'Today\'s Soccer Fortune\n'
        'Energy $energy · Focus $focus · Teamwork $teamwork · Recovery $recovery\n'
        'Lucky color: $color · Lucky time: $time · Keyword: $keyword\n'
        '$profileLine\n'
        '$trainingLine\n'
        'Caution: $caution\n'
        'Suggested action: $tip';
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
      return '프로필 반영: ${age != null ? '나이 $age세' : '나이 미입력'} · ${soccerYears != null ? '구력 $soccerYears년' : '구력 미입력'} 기준으로 리듬을 분석했어요.';
    }
    return 'Profile blend: ${age != null ? 'age $age' : 'age n/a'} · ${soccerYears != null ? '$soccerYears years experience' : 'experience n/a'} used for rhythm analysis.';
  }

  String _trainingBlendLine({
    required bool isKo,
    required TrainingEntry entry,
    required int seed,
  }) {
    final kind = entry.program.trim().isNotEmpty
        ? entry.program.trim()
        : entry.type.trim();
    final typeText = kind.isEmpty ? (isKo ? '기본 훈련' : 'base training') : kind;
    final variantsKo = <String>[
      '$typeText 패턴에서 템포 조절 운이 좋습니다. 첫 15분 리듬을 빠르게 잡아보세요.',
      '$typeText 흐름에서 선택 타이밍이 좋게 들어옵니다. 패스/터치 결정을 빠르게 가져가세요.',
      '$typeText 훈련에서 반복 정확도가 상승하는 날입니다. 횟수보다 성공 패턴을 고정하세요.',
    ];
    final variantsEn = <String>[
      'In $typeText, tempo control luck is strong. Set rhythm early in the first 15 min.',
      'In $typeText, decision timing is favorable. Make pass/touch choices quickly.',
      'In $typeText, repetition accuracy is likely to rise. Lock successful patterns over volume.',
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
}
