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
    final baseSeed = _seed(entry, profile, history);
    final luckyObject = _pick(
      isKo ? _luckyObjectsKo : _luckyObjectsEn,
      baseSeed + 3,
    );
    final luckySnack = _pick(
      isKo ? _luckySnacksKo : _luckySnacksEn,
      baseSeed + 11,
    );
    final moodKeyword = _pick(
      isKo ? _moodKeywordsKo : _moodKeywordsEn,
      baseSeed + (entry.mood * 7),
    );
    final mission = _pick(isKo ? _missionsKo : _missionsEn, baseSeed + 19);
    final message = _pick(isKo ? _messagesKo : _messagesEn, baseSeed + 29);
    final boost = _pick(isKo ? _boostsKo : _boostsEn, baseSeed + 41);

    final fortuneText = isKo
        ? '오늘의 랜덤 운세\n'
              '키워드: $moodKeyword\n'
              '행운 아이템: $luckyObject\n'
              '행운 간식: $luckySnack\n'
              '오늘의 미션: $mission\n'
              '$message\n'
              '$boost'
        : 'Today\'s Random Fortune\n'
              'Keyword: $moodKeyword\n'
              'Lucky item: $luckyObject\n'
              'Lucky snack: $luckySnack\n'
              'Mission: $mission\n'
              '$message\n'
              '$boost';

    return LocalFortuneResult(
      fortuneText: fortuneText,
      recommendationText: '',
      recommendedProgram: '',
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
}

const List<String> _luckyObjectsKo = [
  '왼쪽 주머니 동전',
  '네모난 포스트잇',
  '살짝 구겨진 영수증',
  '검은색 볼펜',
  '물병 뚜껑',
];

const List<String> _luckyObjectsEn = [
  'the coin in your left pocket',
  'a square sticky note',
  'a slightly crumpled receipt',
  'a black pen',
  'a bottle cap',
];

const List<String> _luckySnacksKo = [
  '초코 우유 한 모금',
  '딸기맛 젤리 두 개',
  '바삭한 과자 한 줌',
  '미니 붕어빵 하나',
  '시원한 아이스티',
];

const List<String> _luckySnacksEn = [
  'one sip of chocolate milk',
  'two strawberry gummies',
  'a handful of crispy chips',
  'one mini fish-shaped bun',
  'a cold iced tea',
];

const List<String> _moodKeywordsKo = [
  '은근한 자신감',
  '뜻밖의 타이밍',
  '여유 있는 농담',
  '디테일 집착',
  '슬쩍 웃기는 센스',
];

const List<String> _moodKeywordsEn = [
  'quiet confidence',
  'unexpected timing',
  'easy-going humor',
  'detail obsession',
  'casual wit',
];

const List<String> _missionsKo = [
  '메시지 답장에 느낌표 하나 더 붙이기',
  '엘리베이터 문 닫힘 버튼 먼저 누르지 않기',
  '오늘 만난 사람 이름 한 번 더 불러주기',
  '물 마실 때 어깨 힘 빼고 3초 멈추기',
  '하늘 사진 한 장 찍어두기',
];

const List<String> _missionsEn = [
  'add one extra exclamation mark in a reply',
  'do not press the elevator close button first',
  'say someone’s name one extra time today',
  'relax your shoulders for 3 seconds before a sip of water',
  'take one photo of the sky',
];

const List<String> _messagesKo = [
  '작은 우연이 계속 겹치면 오늘은 네 편입니다.',
  '별거 아닌 선택이 의외로 좋은 결과를 데려옵니다.',
  '사소한 친절 하나가 다음 순서를 바꿉니다.',
  '오늘은 타이밍이 반 박자 늦을수록 더 정확합니다.',
  '급하지 않게 움직이면 오히려 일이 빨라집니다.',
];

const List<String> _messagesEn = [
  'If small coincidences stack up, today is on your side.',
  'A tiny choice may lead to a surprisingly good result.',
  'One small kindness can change what comes next.',
  'Today, being half a beat slower may be more accurate.',
  'Moving calmly can make things finish faster.',
];

const List<String> _boostsKo = [
  '보너스: 오른손보다 왼손으로 문 열면 소소한 럭키 확률 상승.',
  '보너스: 첫 대화에서 한 번 웃으면 흐름이 부드러워집니다.',
  '보너스: 정리 정돈 3분만 하면 머리가 맑아집니다.',
  '보너스: 오늘 숫자 7을 보면 잠깐 심호흡.',
  '보너스: 의자에서 일어날 때 기지개 한 번이 행운 스위치입니다.',
];

const List<String> _boostsEn = [
  'Bonus: open a door with your left hand for a tiny luck boost.',
  'Bonus: one smile in your first conversation smooths the day.',
  'Bonus: 3 minutes of tidying clears your head.',
  'Bonus: when you see the number 7, take one deep breath.',
  'Bonus: a quick stretch when you stand up flips your luck switch.',
];
