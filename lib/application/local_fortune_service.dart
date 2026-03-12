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
    final message = _pick(isKo ? _messagesKo : _messagesEn, baseSeed + 29);
    final boost = _pick(isKo ? _boostsKo : _boostsEn, baseSeed + 41);
    final luckyTime = _pick(
      isKo ? _luckyTimesKo : _luckyTimesEn,
      baseSeed + 71,
    );
    final luckyColor = _pick(
      isKo ? _luckyColorsKo : _luckyColorsEn,
      baseSeed + 73,
    );
    final luckyNumber = (baseSeed.abs() % 9) + 1;
    final weeklyTrend = _weeklyTrendComment(history: history, isKo: isKo);
    final readiness = _readinessComment(entry: entry, isKo: isKo);
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

  String _readinessComment({required TrainingEntry entry, required bool isKo}) {
    final score = (entry.intensity + entry.mood) / 2;
    if (score >= 4.5) {
      return isKo ? '상급 훈련 도전 가능' : 'Ready for advanced sessions';
    }
    if (score >= 3.5) {
      return isKo ? '기본 루틴 강화 적합' : 'Great for strengthening core routines';
    }
    return isKo ? '기술 정리와 회복 우선' : 'Prioritize technique cleanup and recovery';
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

const List<String> _luckyTimesKo = [
  '오전 7시~9시',
  '오전 10시~11시',
  '오후 1시~3시',
  '오후 5시~6시',
  '저녁 8시~9시',
];

const List<String> _luckyTimesEn = [
  '7:00-9:00 AM',
  '10:00-11:00 AM',
  '1:00-3:00 PM',
  '5:00-6:00 PM',
  '8:00-9:00 PM',
];

const List<String> _luckyColorsKo = ['네이비', '에메랄드', '코랄', '머스타드', '스카이블루'];

const List<String> _luckyColorsEn = [
  'Navy',
  'Emerald',
  'Coral',
  'Mustard',
  'Sky blue',
];
