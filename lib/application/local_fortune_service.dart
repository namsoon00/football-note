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
        ? '오늘의 운세\n'
              '키워드: $moodKeyword\n'
              '행운 아이템: $luckyObject\n'
              '행운 간식: $luckySnack\n'
              '오늘의 미션: $mission\n'
              '$message\n'
              '$boost'
        : 'Today fortune\n'
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
  '주머니 속 동전',
  '네모 메모지',
  '연필 한 자루',
  '검은 볼펜',
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
  '딸기 젤리 두 개',
  '과자 한 줌',
  '바나나 한 조각',
  '시원한 물 한 컵',
];

const List<String> _luckySnacksEn = [
  'one sip of chocolate milk',
  'two strawberry gummies',
  'a handful of crispy chips',
  'one mini fish-shaped bun',
  'a cold iced tea',
];

const List<String> _moodKeywordsKo = [
  '차분한 자신감',
  '좋은 타이밍',
  '밝은 기분',
  '집중력',
  '웃는 에너지',
];

const List<String> _moodKeywordsEn = [
  'quiet confidence',
  'unexpected timing',
  'easy-going humor',
  'detail obsession',
  'casual wit',
];

const List<String> _missionsKo = [
  '인사할 때 먼저 웃어보기',
  '물 한 컵 천천히 마시기',
  '고마워요 한 번 더 말하기',
  '하늘을 3초 바라보기',
  '스트레칭 1분 하기',
];

const List<String> _missionsEn = [
  'add one extra exclamation mark in a reply',
  'do not press the elevator close button first',
  'say someone’s name one extra time today',
  'relax your shoulders for 3 seconds before a sip of water',
  'take one photo of the sky',
];

const List<String> _messagesKo = [
  '천천히 해도 오늘은 잘 풀려요.',
  '작은 선택이 좋은 결과를 만들어요.',
  '친절한 말 한마디가 큰 힘이 돼요.',
  '조금만 집중하면 실수가 줄어요.',
  '급하지 않게 하면 더 잘할 수 있어요.',
];

const List<String> _messagesEn = [
  'If small coincidences stack up, today is on your side.',
  'A tiny choice may lead to a surprisingly good result.',
  'One small kindness can change what comes next.',
  'Today, being half a beat slower may be more accurate.',
  'Moving calmly can make things finish faster.',
];

const List<String> _boostsKo = [
  '보너스: 숨을 크게 한 번 쉬면 마음이 편해져요.',
  '보너스: 어깨를 툭 털고 시작해 보세요.',
  '보너스: 자리 정리 3분이면 집중이 쉬워져요.',
  '보너스: 숫자 7을 보면 소원을 생각해 보세요.',
  '보너스: 기지개를 켜면 몸이 가벼워져요.',
];

const List<String> _boostsEn = [
  'Bonus: open a door with your left hand for a tiny luck boost.',
  'Bonus: one smile in your first conversation smooths the day.',
  'Bonus: 3 minutes of tidying clears your head.',
  'Bonus: when you see the number 7, take one deep breath.',
  'Bonus: a quick stretch when you stand up flips your luck switch.',
];
