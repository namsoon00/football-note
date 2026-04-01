import '../domain/entities/player_profile.dart';
import '../domain/entities/training_entry.dart';
import 'package:intl/intl.dart';

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

  static String formatFortunePoolCount(String localeName) {
    final groupSeparator = _resolveGroupSeparator(localeName);
    final digits = totalFortunePoolCount.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write(groupSeparator);
      }
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }

  LocalFortuneResult generateResult({
    required TrainingEntry entry,
    required PlayerProfile profile,
    required List<TrainingEntry> history,
    required bool isKo,
  }) {
    final baseSeed = _seed(entry, profile, history);
    final luckyObject = _luckyObject(baseSeed + 3, isKo);
    final luckySnack = _luckySnack(baseSeed + 11, isKo);
    final boost = _luckyBoost(seed: baseSeed + 41, isKo: isKo);
    final luckyTime = _luckyTime(seed: baseSeed + 71, isKo: isKo);
    final luckyColor = _luckyColor(seed: baseSeed + 73, isKo: isKo);
    final luckyZone = _luckyZone(seed: baseSeed + 79, isKo: isKo);
    final luckyCue = _luckyCue(seed: baseSeed + 83, isKo: isKo);
    final luckyNumber = (baseSeed.abs() % 9) + 1;
    final recommendedProgram = _recommendedProgram(entry: entry, isKo: isKo);
    final recommendationText = _recommendationText(
      entry: entry,
      recommendedProgram: recommendedProgram,
      isKo: isKo,
    );

    final fortuneText = isKo
        ? '[행운 정보]\n'
            '행운 숫자: $luckyNumber\n'
            '행운 색상: $luckyColor\n'
            '행운 시간대: $luckyTime\n'
            '행운 구역: $luckyZone\n'
            '행운 물건: $luckyObject\n'
            '행운 간식: $luckySnack\n'
            '행운 루틴 큐: $luckyCue\n'
            '$boost'
        : '[Lucky info]\n'
            'Lucky number: $luckyNumber\n'
            'Lucky color: $luckyColor\n'
            'Lucky time: $luckyTime\n'
            'Lucky zone: $luckyZone\n'
            'Lucky item: $luckyObject\n'
            'Lucky snack: $luckySnack\n'
            'Lucky routine cue: $luckyCue\n'
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

  String _luckyZone({required int seed, required bool isKo}) {
    return _composeSegments(
      seed: seed,
      first: isKo ? _luckyZoneModifiersKo : _luckyZoneModifiersEn,
      second: isKo ? _luckyZoneBasesKo : _luckyZoneBasesEn,
    );
  }

  String _luckyCue({required int seed, required bool isKo}) {
    return _composeSegments(
      seed: seed,
      first: isKo ? _luckyCueOpeningsKo : _luckyCueOpeningsEn,
      second: isKo ? _luckyCueActionsKo : _luckyCueActionsEn,
      third: isKo ? _luckyCueClosingsKo : _luckyCueClosingsEn,
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
    BigInt countSegments(
      List<String> first,
      List<String> second, [
      List<String>? third,
    ]) {
      var total = count(first) * count(second);
      if (third != null) {
        total *= count(third);
      }
      return total;
    }

    final luckyColorCount = countSegments(
      _luckyColorTonesKo,
      _luckyColorBasesKo,
    );
    final luckyTimeCount = countSegments(
      _luckyTimePeriodsKo,
      _luckyTimeWindowsKo,
    );
    final luckyZoneCount = countSegments(
      _luckyZoneModifiersKo,
      _luckyZoneBasesKo,
    );
    final luckyObjectCount = countSegments(
      _luckyObjectModifiersKo,
      _luckyObjectBasesKo,
    );
    final luckySnackCount = countSegments(
      _luckySnackModifiersKo,
      _luckySnackBasesKo,
    );
    final luckyCueCount = countSegments(
      _luckyCueOpeningsKo,
      _luckyCueActionsKo,
      _luckyCueClosingsKo,
    );
    final boostCount = countSegments(
      _boostOpeningsKo,
      _boostActionsKo,
      _boostClosingsKo,
    );
    const luckyNumberCount = 9;

    return luckyColorCount *
        luckyTimeCount *
        luckyZoneCount *
        luckyObjectCount *
        luckySnackCount *
        luckyCueCount *
        boostCount *
        BigInt.from(luckyNumberCount);
  }

  static String _resolveGroupSeparator(String localeName) {
    try {
      return NumberFormat.decimalPattern(localeName).symbols.GROUP_SEP;
    } catch (_) {
      final fallbackLocale = localeName.split(RegExp('[-_]')).first;
      try {
        return NumberFormat.decimalPattern(fallbackLocale).symbols.GROUP_SEP;
      } catch (_) {
        return ',';
      }
    }
  }
}

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

const List<String> _luckyZoneModifiersKo = [
  '왼쪽',
  '오른쪽',
  '중앙',
  '하프라인 근처',
  '박스 바깥',
  '터치라인 쪽',
  '전진 시작',
  '수비 전환',
];

const List<String> _luckyZoneBasesKo = [
  '하프스페이스',
  '터치라인 안쪽',
  '첫 터치 지점',
  '리턴 패스 각도',
  '세컨드볼 반응 구역',
  '압박 탈출 출발점',
  '원투패스 연결선',
  '침투 타이밍 구간',
  '시야 확보 자리',
  '마무리 직전 공간',
];

const List<String> _luckyZoneModifiersEn = [
  'Left-side',
  'Right-side',
  'Central',
  'Half-line',
  'Box-edge',
  'Touchline-side',
  'Forward-start',
  'Transition',
];

const List<String> _luckyZoneBasesEn = [
  'half-space',
  'inside channel',
  'first-touch spot',
  'return-pass angle',
  'second-ball lane',
  'press-break starting point',
  'one-two lane',
  'run timing window',
  'scanning pocket',
  'pre-finish space',
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

const List<String> _luckyCueOpeningsKo = [
  '짧게',
  '첫 세트 전에',
  '호흡 고른 뒤',
  '볼을 받기 전에',
  '발끝을 깨운 다음',
  '고개를 든 직후',
  '턴 동작 직전',
  '리듬이 흔들리면',
];

const List<String> _luckyCueActionsKo = [
  '시선 한 번 더 확인하기',
  '터치 방향 먼저 정하기',
  '왼발과 오른발 간격 맞추기',
  '첫 발 디딤을 가볍게 두기',
  '몸을 열고 다음 선택 보기',
  '짧은 호흡으로 템포 묶기',
  '한 번에 세게보다 정확하게 두기',
  '볼 오기 전에 어깨 방향 정리하기',
];

const List<String> _luckyCueClosingsKo = [
  '가 오늘 감각을 오래 붙잡아 줘요.',
  '가 좋은 장면을 더 빨리 불러올 수 있어요.',
  '가 흔들린 리듬을 다시 모아줄 거예요.',
  '가 하루 전체의 템포를 정리해 줄 수 있어요.',
];

const List<String> _luckyCueOpeningsEn = [
  'Briefly',
  'Before the first set',
  'After settling the breath',
  'Before receiving the ball',
  'Once the feet wake up',
  'Right after lifting the head',
  'Just before the turn',
  'When the rhythm slips',
];

const List<String> _luckyCueActionsEn = [
  'scan one more time',
  'pick the touch direction first',
  'set the gap between both feet',
  'keep the first step light',
  'open the body and see the next option',
  'bind the tempo with a short breath',
  'choose accuracy before force',
  'set the shoulder angle before the ball arrives',
];

const List<String> _luckyCueClosingsEn = [
  'should help the feel last longer today.',
  'can bring the next good moment faster.',
  'should gather the rhythm again when it shakes.',
  'can clean up the tempo of the whole day.',
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
