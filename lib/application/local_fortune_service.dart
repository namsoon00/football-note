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
  static final BigInt totalFortunePoolCount = _calculateTotalFortunePoolCount();

  LocalFortuneResult generateResult({
    required TrainingEntry entry,
    required PlayerProfile profile,
    required List<TrainingEntry> history,
    required bool isKo,
  }) {
    final baseSeed = _seed(entry, profile, history);
    final luckyObject = _luckyObject(baseSeed + 3, isKo);
    final luckySnack = _luckySnack(baseSeed + 11, isKo);
    final moodKeyword = _conditionKeyword(
      seed: baseSeed + (entry.mood * 7),
      isKo: isKo,
    );
    final message = _flowMessage(seed: baseSeed + 29, isKo: isKo);
    final boost = _luckyBoost(seed: baseSeed + 41, isKo: isKo);
    final luckyTime = _luckyTime(seed: baseSeed + 71, isKo: isKo);
    final luckyColor = _luckyColor(seed: baseSeed + 73, isKo: isKo);
    final luckyNumber = (baseSeed.abs() % 9) + 1;
    final weeklyTrend = _weeklyTrendComment(history: history, isKo: isKo);
    final readiness = _readinessComment(
      entry: entry,
      seed: baseSeed + 101,
      isKo: isKo,
    );
    final recommendedProgram = _recommendedProgram(entry: entry, isKo: isKo);
    final recommendationText = _recommendationText(
      entry: entry,
      recommendedProgram: recommendedProgram,
      isKo: isKo,
    );

    final fortuneText = isKo
        ? '전체 흐름: $message\n'
              '컨디션 키워드: $moodKeyword\n'
              '현재 준비도: $readiness\n'
              '최근 흐름: $weeklyTrend\n'
              '\n'
              '[행운 정보]\n'
              '행운 숫자: $luckyNumber\n'
              '행운 색상: $luckyColor\n'
              '행운 시간대: $luckyTime\n'
              '행운 물건: $luckyObject\n'
              '행운 간식: $luckySnack\n'
              '$boost'
        : 'Overall flow: $message\n'
              'Mood keyword: $moodKeyword\n'
              'Current readiness: $readiness\n'
              'Recent trend: $weeklyTrend\n'
              '\n'
              '[Lucky info]\n'
              'Lucky number: $luckyNumber\n'
              'Lucky color: $luckyColor\n'
              'Lucky time: $luckyTime\n'
              'Lucky item: $luckyObject\n'
              'Lucky snack: $luckySnack\n'
              '$boost';

    return LocalFortuneResult(
      fortuneText: fortuneText,
      recommendationText: recommendationText,
      recommendedProgram: recommendedProgram,
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
    TrainingEntry entry,
    PlayerProfile profile,
    List<TrainingEntry> history,
  ) {
    final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
    final p = profile.name.trim().runes.fold<int>(0, (a, b) => a + b);
    final h = history.length * 17;
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

  String _pick(List<String> values, int seed) {
    if (values.isEmpty) return '';
    return values[seed.abs() % values.length];
  }

  String _weeklyTrendComment({
    required List<TrainingEntry> history,
    required bool isKo,
  }) {
    if (history.isEmpty) {
      return isKo
          ? '첫 기록 주간, 기준을 만들기 좋은 날입니다.'
          : 'First log week, a good day to set your baseline.';
    }
    final recent = [...history]..sort(TrainingEntry.compareByRecentCreated);
    final sample = recent.take(7).toList(growable: false);
    final avgMood =
        sample.fold<int>(0, (sum, e) => sum + e.mood) / sample.length;
    if (avgMood >= 4.2) {
      return isKo
          ? '최근 컨디션 흐름이 좋아 도전 과제를 넣기 좋습니다.'
          : 'Recent condition is strong, good timing for a challenge.';
    }
    if (avgMood >= 3.4) {
      return isKo
          ? '흐름이 안정적이라 루틴 완성도를 높이기 좋습니다.'
          : 'Your trend is stable, great for sharpening routine quality.';
    }
    return isKo
        ? '피로 누적 신호가 보여 강도보다 회복 리듬이 중요합니다.'
        : 'Fatigue signs suggest recovery rhythm should come first today.';
  }

  String _readinessComment({
    required TrainingEntry entry,
    required int seed,
    required bool isKo,
  }) {
    final score = (entry.intensity + entry.mood) / 2;
    final readinessBase = score >= 4.5
        ? (isKo ? _readinessTopKo : _readinessTopEn)
        : score >= 3.5
        ? (isKo ? _readinessMidKo : _readinessMidEn)
        : (isKo ? _readinessLowKo : _readinessLowEn);
    final suffix = isKo ? _readinessSuffixKo : _readinessSuffixEn;
    if (score >= 4.5) {
      return _composeSegments(seed: seed, first: readinessBase, second: suffix);
    }
    if (score >= 3.5) {
      return _composeSegments(seed: seed, first: readinessBase, second: suffix);
    }
    return _composeSegments(seed: seed, first: readinessBase, second: suffix);
  }

  String _recommendedProgram({
    required TrainingEntry entry,
    required bool isKo,
  }) {
    final liftingTotal = entry.liftingByPart.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );
    if (entry.injury || (entry.painLevel ?? 0) >= 4) {
      return isKo ? '회복 볼터치' : 'Recovery ball touch';
    }
    if (liftingTotal >= 80) {
      return isKo ? '가벼운 퍼스트 터치' : 'Light first touch';
    }
    if (entry.mood >= 4 && entry.intensity >= 4) {
      return isKo ? '전진 패스 연계' : 'Forward pass combination';
    }
    return isKo ? '기본기 루틴' : 'Core technique routine';
  }

  String _recommendationText({
    required TrainingEntry entry,
    required String recommendedProgram,
    required bool isKo,
  }) {
    if (entry.injury || (entry.painLevel ?? 0) >= 4) {
      return isKo
          ? '통증 체크를 우선하고, 다음 훈련은 $recommendedProgram 중심으로 강도를 낮춰보세요.'
          : 'Check pain first and lower the next session intensity around $recommendedProgram.';
    }
    if (entry.mood >= 4 && entry.intensity >= 4) {
      return isKo
          ? '흐름이 좋습니다. 다음 훈련은 $recommendedProgram로 속도와 선택 연결을 이어가세요.'
          : 'Your rhythm is good. Keep the next session focused on $recommendedProgram.';
    }
    return isKo
        ? '다음 훈련은 $recommendedProgram로 리듬을 정리하며 정확도를 끌어올려보세요.'
        : 'Use $recommendedProgram next to settle your rhythm and raise accuracy.';
  }

  String _flowMessage({required int seed, required bool isKo}) {
    return _composeSegments(
      seed: seed,
      first: isKo ? _flowOpeningsKo : _flowOpeningsEn,
      second: isKo ? _flowMiddlesKo : _flowMiddlesEn,
      third: isKo ? _flowClosingsKo : _flowClosingsEn,
    );
  }

  String _conditionKeyword({required int seed, required bool isKo}) {
    return _composeSegments(
      seed: seed,
      first: isKo ? _conditionPrefixesKo : _conditionPrefixesEn,
      second: isKo ? _conditionCentersKo : _conditionCentersEn,
      third: isKo ? _conditionSuffixesKo : _conditionSuffixesEn,
      separator: isKo ? ' · ' : ' · ',
    );
  }

  String _luckyColor({required int seed, required bool isKo}) {
    return _composeSegments(
      seed: seed,
      first: isKo ? _luckyColorTonesKo : _luckyColorTonesEn,
      second: isKo ? _luckyColorBasesKo : _luckyColorBasesEn,
    );
  }

  String _luckyTime({required int seed, required bool isKo}) {
    return _composeSegments(
      seed: seed,
      first: isKo ? _luckyTimePeriodsKo : _luckyTimePeriodsEn,
      second: isKo ? _luckyTimeWindowsKo : _luckyTimeWindowsEn,
      separator: isKo ? ' ' : ' ',
    );
  }

  String _luckyObject(int seed, bool isKo) {
    return _composeSegments(
      seed: seed,
      first: isKo ? _luckyObjectModifiersKo : _luckyObjectModifiersEn,
      second: isKo ? _luckyObjectBasesKo : _luckyObjectBasesEn,
      separator: isKo ? ' ' : ' ',
    );
  }

  String _luckySnack(int seed, bool isKo) {
    return _composeSegments(
      seed: seed,
      first: isKo ? _luckySnackModifiersKo : _luckySnackModifiersEn,
      second: isKo ? _luckySnackBasesKo : _luckySnackBasesEn,
      separator: isKo ? ' ' : ' ',
    );
  }

  String _luckyBoost({required int seed, required bool isKo}) {
    return _composeSegments(
      seed: seed,
      first: isKo ? _boostOpeningsKo : _boostOpeningsEn,
      second: isKo ? _boostActionsKo : _boostActionsEn,
      third: isKo ? _boostClosingsKo : _boostClosingsEn,
    );
  }

  String _composeSegments({
    required int seed,
    required List<String> first,
    required List<String> second,
    List<String>? third,
    String separator = ' ',
  }) {
    final parts = <String>[
      _pick(first, seed + 1),
      _pick(second, seed + 17),
      if (third != null) _pick(third, seed + 31),
    ].where((value) => value.trim().isNotEmpty).toList(growable: false);
    return parts.join(separator).replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static BigInt _calculateTotalFortunePoolCount() {
    BigInt count(List<String> values) => BigInt.from(values.length);
    BigInt countSegments(List<String> first, List<String> second, [
      List<String>? third,
    ]) {
      var total = count(first) * count(second);
      if (third != null) {
        total *= count(third);
      }
      return total;
    }

    final flowCount = countSegments(
      _flowOpeningsKo,
      _flowMiddlesKo,
      _flowClosingsKo,
    );
    final conditionCount = countSegments(
      _conditionPrefixesKo,
      _conditionCentersKo,
      _conditionSuffixesKo,
    );
    final readinessCount =
        (count(_readinessTopKo) +
            count(_readinessMidKo) +
            count(_readinessLowKo)) *
        count(_readinessSuffixKo);
    final luckyColorCount = countSegments(
      _luckyColorTonesKo,
      _luckyColorBasesKo,
    );
    final luckyTimeCount = countSegments(
      _luckyTimePeriodsKo,
      _luckyTimeWindowsKo,
    );
    final luckyObjectCount = countSegments(
      _luckyObjectModifiersKo,
      _luckyObjectBasesKo,
    );
    final luckySnackCount = countSegments(
      _luckySnackModifiersKo,
      _luckySnackBasesKo,
    );
    final boostCount = countSegments(
      _boostOpeningsKo,
      _boostActionsKo,
      _boostClosingsKo,
    );
    const weeklyTrendCount = 3;
    const luckyNumberCount = 9;

    return flowCount *
        conditionCount *
        readinessCount *
        luckyColorCount *
        luckyTimeCount *
        luckyObjectCount *
        luckySnackCount *
        boostCount *
        BigInt.from(weeklyTrendCount) *
        BigInt.from(luckyNumberCount);
  }
}

const List<String> _flowOpeningsKo = [
  '리듬을 천천히 올리면',
  '첫 선택을 단단히 잡으면',
  '평소 루틴을 믿고 가면',
  '조급함만 내려놓으면',
  '몸을 먼저 깨우고 나가면',
  '가벼운 한 번의 성공을 만들면',
  '초반 10분 집중을 지키면',
  '익숙한 동작부터 연결하면',
  '주변 호흡을 살피며 움직이면',
  '타이밍을 반 박자만 맞추면',
];

const List<String> _flowMiddlesKo = [
  '작은 흐름이 연속 성공으로 이어지고',
  '오늘은 판단 속도가 자연스럽게 붙고',
  '실수 뒤 회복 속도가 평소보다 빠르고',
  '주변 도움과 본인 선택이 잘 맞물리고',
  '준비한 만큼 결과가 정직하게 따라오고',
  '느긋한 태도가 오히려 효율을 높이고',
  '한 번의 좋은 터치가 자신감을 키우고',
  '익숙한 장면에서 확신이 더 선명해지고',
  '무리하지 않아도 존재감이 살아나고',
  '차분한 판단이 템포를 안정시켜 주고',
];

const List<String> _flowClosingsKo = [
  '마무리 순간에 좋은 장면을 만들 수 있어요.',
  '중반 이후에 기대 이상의 결과가 따라올 수 있어요.',
  '오늘 기록 하나가 다음 흐름까지 끌어올릴 수 있어요.',
  '예상보다 안정적인 하루로 정리될 가능성이 커요.',
];

const List<String> _flowOpeningsEn = [
  'If you raise the rhythm gradually,',
  'If you lock in the first choice well,',
  'If you trust your usual routine,',
  'If you let go of hurry,',
  'If you wake the body up first,',
  'If you create one easy success early,',
  'If you protect your first ten minutes of focus,',
  'If you connect through familiar actions first,',
  'If you move while reading teammate rhythm,',
  'If you match the timing by half a beat,',
];

const List<String> _flowMiddlesEn = [
  'small momentum can roll into repeated wins',
  'your decision speed should come naturally',
  'recovery after mistakes should be faster than usual',
  'support around you should match your choices well',
  'results should follow your preparation honestly',
  'a calmer attitude can lift efficiency',
  'one clean touch can build confidence',
  'certainty should feel sharper in familiar situations',
  'your presence can grow without forcing it',
  'steady judgment can stabilize the tempo',
];

const List<String> _flowClosingsEn = [
  'and set up a strong finish.',
  'and lead to a better-than-expected middle stretch.',
  'and lift the quality of today record.',
  'and leave the day more stable than you expected.',
];

const List<String> _conditionPrefixesKo = [
  '침착한',
  '단단한',
  '맑은',
  '공격적인',
  '부드러운',
  '끈질긴',
  '가벼운',
  '예민하게 깨어 있는',
];

const List<String> _conditionCentersKo = [
  '집중력',
  '첫 터치 감각',
  '호흡 조절',
  '판단 리듬',
  '순간 반응',
  '연결 타이밍',
  '회복 탄력성',
  '공간 감지력',
];

const List<String> _conditionSuffixesKo = [
  '상승 구간',
  '정리 모드',
  '가속 신호',
  '안정 흐름',
  '선명한 감각',
];

const List<String> _conditionPrefixesEn = [
  'Calm',
  'Solid',
  'Clear',
  'Assertive',
  'Smooth',
  'Persistent',
  'Light',
  'Alert',
];

const List<String> _conditionCentersEn = [
  'focus',
  'first-touch feel',
  'breathing control',
  'decision rhythm',
  'reaction speed',
  'connection timing',
  'recovery bounce',
  'space awareness',
];

const List<String> _conditionSuffixesEn = [
  'on the rise',
  'in reset mode',
  'showing acceleration',
  'holding steady',
  'feeling sharp',
];

const List<String> _readinessTopKo = [
  '상급 훈련 도전 가능',
  '강도 높은 메뉴도 소화 가능',
  '경쟁 상황 투입 준비 완료',
  '오늘은 한 단계 위 루틴까지 가능',
  '도전 과제를 넣어도 버틸 준비가 됨',
  '속도와 강도를 함께 올려볼 만함',
  '주도적으로 훈련을 끌 수 있는 상태',
  '고난도 선택을 실험해 볼 여유가 있음',
];

const List<String> _readinessMidKo = [
  '기본 루틴 강화 적합',
  '안정적인 반복 훈련에 적합',
  '정확도 중심 훈련이 잘 맞음',
  '기본기와 속도 연결에 적당함',
  '평소 루틴을 다듬기 좋은 상태',
  '강약 조절하며 완성도를 올리기 좋음',
  '실수 줄이기 훈련에 적합',
  '기술 연결감 회복에 알맞음',
];

const List<String> _readinessLowKo = [
  '기술 정리와 회복 우선',
  '부하보다 감각 회복이 우선',
  '강도 욕심보다 루틴 정비가 먼저',
  '몸 상태 확인부터 차분히 가는 편이 좋음',
  '짧고 정확한 반복이 더 효과적임',
  '속도보다 안정이 필요한 날',
  '회복 루틴과 기본기 비중이 맞는 날',
  '무리한 경쟁보다 감각 재정렬이 우선',
];

const List<String> _readinessSuffixKo = [
  '짧은 워밍업 뒤 바로 흐름을 타기 좋아요.',
  '호흡만 맞추면 퀄리티를 안정적으로 유지할 수 있어요.',
  '처음 세트에서 기준점을 만들면 끝까지 흔들리지 않아요.',
  '강약 조절을 지키면 만족도 높은 기록이 남을 수 있어요.',
  '전반부 리듬만 잡히면 후반 집중도도 따라올 거예요.',
];

const List<String> _readinessTopEn = [
  'Ready for advanced sessions',
  'Capable of handling high-intensity work',
  'Prepared for competitive tasks',
  'Ready for the next-tier routine',
  'Stable enough for a challenge block',
  'Able to raise speed and intensity together',
  'Ready to lead the session',
  'Comfortable trying higher-difficulty choices',
];

const List<String> _readinessMidEn = [
  'Great for strengthening core routines',
  'Well suited for stable repetitions',
  'Best for accuracy-focused work',
  'Good for linking basics with speed',
  'A strong day to refine familiar routines',
  'Good for quality gains with controlled intensity',
  'Well suited to reducing mistakes',
  'Helpful for rebuilding technical connection',
];

const List<String> _readinessLowEn = [
  'Prioritize technique cleanup and recovery',
  'Recovery should come before load today',
  'Routine maintenance matters more than pushing hard',
  'A calm body check should come first',
  'Short accurate repetitions will pay off more',
  'Stability matters more than pace today',
  'Recovery routine and basics are the right mix',
  'Resetting feel matters more than competing hard',
];

const List<String> _readinessSuffixEn = [
  'A short warm-up should help you lock in quickly.',
  'Once breathing settles, quality should stay steady.',
  'A clear first set can anchor the rest of the session.',
  'Controlled intensity can still leave a satisfying record.',
  'If the early rhythm clicks, late focus should follow.',
];

const List<String> _luckyColorTonesKo = [
  '딥',
  '소프트',
  '클린',
  '선셋',
  '쿨',
  '웜',
  '미스트',
  '브라이트',
  '모노',
  '포인트',
];

const List<String> _luckyColorBasesKo = [
  '네이비',
  '에메랄드',
  '코랄',
  '머스타드',
  '스카이블루',
  '카키',
  '아이보리',
  '체리 레드',
  '라임',
  '차콜',
];

const List<String> _luckyColorTonesEn = [
  'Deep',
  'Soft',
  'Clean',
  'Sunset',
  'Cool',
  'Warm',
  'Mist',
  'Bright',
  'Mono',
  'Accent',
];

const List<String> _luckyColorBasesEn = [
  'Navy',
  'Emerald',
  'Coral',
  'Mustard',
  'Sky Blue',
  'Khaki',
  'Ivory',
  'Cherry Red',
  'Lime',
  'Charcoal',
];

const List<String> _luckyTimePeriodsKo = [
  '이른 오전',
  '오전 후반',
  '점심 직후',
  '초반 오후',
  '늦은 오후',
  '해질 무렵',
  '저녁 초반',
  '밤 루틴 시간',
];

const List<String> _luckyTimeWindowsKo = [
  '06:40~07:20',
  '08:10~08:50',
  '09:30~10:10',
  '10:40~11:20',
  '12:20~13:00',
  '14:10~14:50',
  '16:00~16:40',
  '18:20~19:00',
  '20:10~20:50',
  '21:00~21:40',
];

const List<String> _luckyTimePeriodsEn = [
  'Early morning',
  'Late morning',
  'Right after lunch',
  'Early afternoon',
  'Late afternoon',
  'At sunset',
  'Early evening',
  'Night routine window',
];

const List<String> _luckyTimeWindowsEn = [
  '06:40-07:20',
  '08:10-08:50',
  '09:30-10:10',
  '10:40-11:20',
  '12:20-13:00',
  '14:10-14:50',
  '16:00-16:40',
  '18:20-19:00',
  '20:10-20:50',
  '21:00-21:40',
];

const List<String> _luckyObjectModifiersKo = [
  '가벼운',
  '작은',
  '손에 익은',
  '주머니 속',
  '책상 위',
  '운동가방 안',
  '자주 쓰는',
  '정리된',
];

const List<String> _luckyObjectBasesKo = [
  '연필',
  '지우개',
  '작은 공',
  '물통',
  '운동화',
  '손목밴드',
  '훈련 노트',
  '헤어밴드',
  '스포츠 타월',
  '양말 한 켤레',
];

const List<String> _luckyObjectModifiersEn = [
  'light',
  'small',
  'familiar',
  'pocket',
  'desk-side',
  'gym-bag',
  'often-used',
  'neatly placed',
];

const List<String> _luckyObjectBasesEn = [
  'pencil',
  'eraser',
  'mini ball',
  'water bottle',
  'training shoes',
  'wrist band',
  'training note',
  'headband',
  'sports towel',
  'pair of socks',
];

const List<String> _luckySnackModifiersKo = [
  '차갑게 식힌',
  '한입 크기의',
  '부담 없는',
  '훈련 전후에 좋은',
  '가볍게 챙기기 쉬운',
  '집중 전환에 좋은',
  '리듬 회복용',
  '물과 잘 맞는',
];

const List<String> _luckySnackBasesKo = [
  '바나나 한 조각',
  '우유 한 컵',
  '사과 한 조각',
  '물 한 컵',
  '작은 주먹밥',
  '요거트',
  '견과류 한 줌',
  '초코우유 몇 모금',
  '치즈 스틱',
  '토스트 반 조각',
];

const List<String> _luckySnackModifiersEn = [
  'chilled',
  'bite-sized',
  'easy-going',
  'pre/post training friendly',
  'easy-to-pack',
  'focus-reset',
  'rhythm-recovery',
  'water-friendly',
];

const List<String> _luckySnackBasesEn = [
  'banana slice',
  'cup of milk',
  'apple slice',
  'glass of water',
  'mini rice ball',
  'yogurt',
  'handful of nuts',
  'few sips of chocolate milk',
  'cheese stick',
  'half a toast',
];

const List<String> _boostOpeningsKo = [
  '보너스:',
  '행운 팁:',
  '마무리 팁:',
  '리듬 팁:',
  '집중 팁:',
];

const List<String> _boostActionsKo = [
  '숨을 크게 한 번 쉬고 시작해 보세요.',
  '어깨를 가볍게 풀어 주면 흐름이 부드러워져요.',
  '물을 한 모금 마시면 선택 속도가 안정될 수 있어요.',
  '오늘 잘한 장면 하나를 바로 떠올려 보세요.',
  '첫 세트 전에 발목을 한 번 더 깨우면 좋아요.',
  '메모 한 줄을 남기면 하루 정리가 더 선명해져요.',
  '시작 전에 시선을 좌우로 한 번 훑어 보세요.',
  '짧게 기지개를 켜면 몸이 빨리 반응할 수 있어요.',
];

const List<String> _boostClosingsKo = [
  '',
  '그 한 번이 오늘 기준점을 만들어 줄 수 있어요.',
  '작은 루틴이 하루의 안정감을 올려줄 거예요.',
  '사소해 보여도 마무리 만족도가 달라질 수 있어요.',
];

const List<String> _boostOpeningsEn = [
  'Bonus:',
  'Lucky tip:',
  'Finish tip:',
  'Rhythm tip:',
  'Focus tip:',
];

const List<String> _boostActionsEn = [
  'take one deep breath before you start.',
  'loosening your shoulders can smooth the whole session.',
  'one sip of water can steady your choices.',
  'recall one good action from today right away.',
  'wake the ankles up once more before the first set.',
  'leave one short memo to sharpen the day.',
  'sweep your eyes left and right once before starting.',
  'a quick stretch can wake the body faster.',
];

const List<String> _boostClosingsEn = [
  '',
  'That one action can set the tone for the day.',
  'A tiny routine can make the whole day steadier.',
  'It looks small, but it can change the quality of your finish.',
];
