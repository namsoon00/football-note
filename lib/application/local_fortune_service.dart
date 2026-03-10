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
    final trainingFocus = _pick(
      isKo ? _trainingFocusKo : _trainingFocusEn,
      baseSeed + 47,
    );
    final recoveryTip = _pick(
      isKo ? _recoveryTipsKo : _recoveryTipsEn,
      baseSeed + 53,
    );
    final caution = _pick(isKo ? _cautionsKo : _cautionsEn, baseSeed + 59);
    final communicationTip = _pick(
      isKo ? _communicationTipsKo : _communicationTipsEn,
      baseSeed + 61,
    );
    final nutritionTip = _pick(
      isKo ? _nutritionTipsKo : _nutritionTipsEn,
      baseSeed + 67,
    );
    final luckyTime = _pick(
      isKo ? _luckyTimesKo : _luckyTimesEn,
      baseSeed + 71,
    );
    final luckyColor = _pick(
      isKo ? _luckyColorsKo : _luckyColorsEn,
      baseSeed + 73,
    );
    final luckyNumber = (baseSeed.abs() % 9) + 1;
    final weeklyTrend = _weeklyTrendComment(
      history: history,
      isKo: isKo,
    );
    final readiness = _readinessComment(entry: entry, isKo: isKo);

    final fortuneText = isKo
        ? '오늘의 운세\n'
              '전체 흐름: $message\n'
              '컨디션 키워드: $moodKeyword\n'
              '현재 준비도: $readiness\n'
              '최근 흐름: $weeklyTrend\n'
              '\n'
              '[훈련 가이드]\n'
              '집중 포인트: $trainingFocus\n'
              '오늘 미션: $mission\n'
              '주의 포인트: $caution\n'
              '\n'
              '[회복/생활]\n'
              '회복 팁: $recoveryTip\n'
              '영양 팁: $nutritionTip\n'
              '대인운 팁: $communicationTip\n'
              '\n'
              '[행운 정보]\n'
              '행운 숫자: $luckyNumber\n'
              '행운 색상: $luckyColor\n'
              '행운 시간대: $luckyTime\n'
              '행운 물건: $luckyObject\n'
              '행운 간식: $luckySnack\n'
              '$boost'
        : 'Today fortune\n'
              'Overall flow: $message\n'
              'Mood keyword: $moodKeyword\n'
              'Current readiness: $readiness\n'
              'Recent trend: $weeklyTrend\n'
              '\n'
              '[Training guide]\n'
              'Focus point: $trainingFocus\n'
              'Today mission: $mission\n'
              'Caution: $caution\n'
              '\n'
              '[Recovery & life]\n'
              'Recovery tip: $recoveryTip\n'
              'Nutrition tip: $nutritionTip\n'
              'Communication tip: $communicationTip\n'
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

  String _weeklyTrendComment({
    required List<TrainingEntry> history,
    required bool isKo,
  }) {
    if (history.isEmpty) {
      return isKo ? '첫 기록 주간, 기준을 만들기 좋은 날입니다.' : 'First log week, a good day to set your baseline.';
    }
    final recent = [...history]..sort(TrainingEntry.compareByRecentCreated);
    final sample = recent.take(7).toList(growable: false);
    final avgMood =
        sample.fold<int>(0, (sum, e) => sum + e.mood) / sample.length;
    if (avgMood >= 4.2) {
      return isKo ? '최근 컨디션 흐름이 좋아 도전 과제를 넣기 좋습니다.' : 'Recent condition is strong, good timing for a challenge.';
    }
    if (avgMood >= 3.4) {
      return isKo ? '흐름이 안정적이라 루틴 완성도를 높이기 좋습니다.' : 'Your trend is stable, great for sharpening routine quality.';
    }
    return isKo ? '피로 누적 신호가 보여 강도보다 회복 리듬이 중요합니다.' : 'Fatigue signs suggest recovery rhythm should come first today.';
  }

  String _readinessComment({
    required TrainingEntry entry,
    required bool isKo,
  }) {
    final score = (entry.intensity + entry.mood) / 2;
    if (score >= 4.5) {
      return isKo ? '상급 훈련 도전 가능' : 'Ready for advanced sessions';
    }
    if (score >= 3.5) {
      return isKo ? '기본 루틴 강화 적합' : 'Great for strengthening core routines';
    }
    return isKo ? '기술 정리와 회복 우선' : 'Prioritize technique cleanup and recovery';
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

const List<String> _trainingFocusKo = [
  '첫 터치 방향을 미리 정하고 받기',
  '패스 전 시야 스캔 횟수 늘리기',
  '양발 번갈아 사용해 템포 유지하기',
  '짧은 거리 정확도 90% 이상 유지하기',
  '턴 동작 후 다음 선택을 1초 안에 결정하기',
];

const List<String> _trainingFocusEn = [
  'Set first-touch direction before receiving',
  'Increase pre-pass scanning frequency',
  'Maintain tempo with both feet alternation',
  'Keep short-pass accuracy above 90%',
  'Decide next action within one second after turns',
];

const List<String> _recoveryTipsKo = [
  '훈련 후 5분 가벼운 걷기로 심박을 내리세요.',
  '수분 보충은 나눠서 2~3회 마시는 편이 좋습니다.',
  '하체 스트레칭 3분만 해도 피로가 줄어듭니다.',
  '샤워 전 호흡 10회로 긴장을 먼저 푸세요.',
  '취침 1시간 전 화면 밝기를 낮춰 회복을 돕세요.',
];

const List<String> _recoveryTipsEn = [
  'Lower heart rate with a 5-minute cool-down walk.',
  'Hydrate in 2-3 small rounds after training.',
  'Three minutes of lower-body stretching reduces fatigue.',
  'Take ten calm breaths before showering to release tension.',
  'Dim screens one hour before sleep for better recovery.',
];

const List<String> _cautionsKo = [
  '초반 과속은 후반 정확도를 떨어뜨릴 수 있어요.',
  '피로한 쪽 다리로 무리한 점프를 피하세요.',
  '기록 숫자보다 자세 완성도를 우선하세요.',
  '통증 신호가 있으면 즉시 강도를 낮추세요.',
  '집중이 흐려지면 세트 사이 휴식을 늘리세요.',
];

const List<String> _cautionsEn = [
  'Over-pacing early may hurt late-session accuracy.',
  'Avoid aggressive jumps on the fatigued side.',
  'Prioritize form quality over record numbers.',
  'Lower intensity immediately if pain signals appear.',
  'Extend rest between sets when focus drops.',
];

const List<String> _communicationTipsKo = [
  '짧고 명확한 한마디가 팀 호흡을 살립니다.',
  '칭찬 한 번이 다음 플레이의 자신감을 올립니다.',
  '질문형 대화가 협업 집중도를 높여줍니다.',
  '지적보다 제안형 표현이 반응이 좋습니다.',
  '마무리 인사가 하루 인상을 좋게 만듭니다.',
];

const List<String> _communicationTipsEn = [
  'One short clear cue can improve team rhythm.',
  'A single compliment boosts confidence for the next play.',
  'Question-style dialogue improves collaboration focus.',
  'Suggestion-style wording works better than blunt criticism.',
  'A clean closing greeting improves the day’s finish.',
];

const List<String> _nutritionTipsKo = [
  '훈련 전엔 소화 쉬운 탄수화물을 소량 섭취하세요.',
  '훈련 후 단백질+수분을 빠르게 보충하세요.',
  '짠 간식은 수분과 함께 균형 있게 드세요.',
  '당분 섭취는 소량, 천천히 나눠서 섭취하세요.',
  '공복 시간이 길면 집중력이 떨어질 수 있어요.',
];

const List<String> _nutritionTipsEn = [
  'Before training, take a small amount of easy carbs.',
  'After training, replenish protein and fluids quickly.',
  'Balance salty snacks with enough water.',
  'Take sugar in small split portions rather than all at once.',
  'Long fasting windows can reduce concentration.',
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

const List<String> _luckyColorsKo = [
  '네이비',
  '에메랄드',
  '코랄',
  '머스타드',
  '스카이블루',
];

const List<String> _luckyColorsEn = [
  'Navy',
  'Emerald',
  'Coral',
  'Mustard',
  'Sky blue',
];
