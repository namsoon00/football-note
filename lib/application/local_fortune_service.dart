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
              '오늘 기분: $moodKeyword\n'
              '행운 물건: $luckyObject\n'
              '행운 간식: $luckySnack\n'
              '오늘 할 일: $mission\n'
              '$message\n'
              '$boost'
        : 'Today fortune\n'
              'Mood: $moodKeyword\n'
              'Lucky item: $luckyObject\n'
              'Lucky snack: $luckySnack\n'
              'Today mission: $mission\n'
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

const List<String> _luckyObjectsKo = ['연필', '지우개', '작은 공', '물통', '운동화'];

const List<String> _luckyObjectsEn = [
  'the coin in your left pocket',
  'a square sticky note',
  'a slightly crumpled receipt',
  'a black pen',
  'a bottle cap',
];

const List<String> _luckySnacksKo = [
  '바나나 한 조각',
  '우유 한 컵',
  '사과 한 조각',
  '물 한 컵',
  '작은 주먹밥',
];

const List<String> _luckySnacksEn = [
  'one sip of chocolate milk',
  'two strawberry gummies',
  'a handful of crispy chips',
  'one mini fish-shaped bun',
  'a cold iced tea',
];

const List<String> _moodKeywordsKo = [
  '용기 뿜뿜',
  '집중 모드',
  '기분 최고',
  '마음 편안',
  '웃음 가득',
];

const List<String> _moodKeywordsEn = [
  'quiet confidence',
  'unexpected timing',
  'easy-going humor',
  'detail obsession',
  'casual wit',
];

const List<String> _missionsKo = [
  '친구에게 먼저 인사하기',
  '물 한 컵 마시기',
  '스트레칭 1분 하기',
  '좋은 말 한마디 하기',
  '오늘 배운 것 1개 말하기',
];

const List<String> _missionsEn = [
  'add one extra exclamation mark in a reply',
  'do not press the elevator close button first',
  'say someone’s name one extra time today',
  'relax your shoulders for 3 seconds before a sip of water',
  'take one photo of the sky',
];

const List<String> _messagesKo = [
  '천천히 해도 오늘은 잘할 수 있어요.',
  '작은 노력도 큰 힘이 돼요.',
  '친절한 말은 멋진 패스 같아요.',
  '집중하면 실수가 줄어들어요.',
  '웃으면서 하면 더 즐거워요.',
];

const List<String> _messagesEn = [
  'If small coincidences stack up, today is on your side.',
  'A tiny choice may lead to a surprisingly good result.',
  'One small kindness can change what comes next.',
  'Today, being half a beat slower may be more accurate.',
  'Moving calmly can make things finish faster.',
];

const List<String> _boostsKo = [
  '보너스: 숨 크게 한 번 쉬어요.',
  '보너스: 어깨를 가볍게 풀어요.',
  '보너스: 물을 한 모금 마셔요.',
  '보너스: 크게 기지개를 켜요.',
  '보너스: 오늘 한 가지를 칭찬해요.',
];

const List<String> _boostsEn = [
  'Bonus: open a door with your left hand for a tiny luck boost.',
  'Bonus: one smile in your first conversation smooths the day.',
  'Bonus: 3 minutes of tidying clears your head.',
  'Bonus: when you see the number 7, take one deep breath.',
  'Bonus: a quick stretch when you stand up flips your luck switch.',
];
