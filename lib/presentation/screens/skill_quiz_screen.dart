import 'dart:math' as math;

import 'package:flutter/material.dart';

class SkillQuizScreen extends StatefulWidget {
  const SkillQuizScreen({super.key});

  @override
  State<SkillQuizScreen> createState() => _SkillQuizScreenState();
}

class _SkillQuizScreenState extends State<SkillQuizScreen> {
  static const int _dailyQuestionCount = 20;

  late final List<_QuizQuestion> _pool;
  late List<_QuizQuestion> _dailyQuestions;
  late List<_QuizQuestion> _questions;
  int _dailySeed = 0;
  bool _reviewMode = false;

  int _index = 0;
  int _score = 0;
  int? _selectedIndex;
  bool _answered = false;
  final Set<String> _wrongIds = <String>{};

  bool get _isFinished => _index >= _questions.length;

  @override
  void initState() {
    super.initState();
    _pool = _buildQuizPool();
    _initDailySession(DateTime.now());
  }

  void _initDailySession(DateTime now) {
    final date = DateTime(now.year, now.month, now.day);
    _dailySeed = (date.year * 10000) + (date.month * 100) + date.day;
    final picked = _buildDailyQuestions(_pool, _dailySeed, _dailyQuestionCount);
    _dailyQuestions = picked;
    _startSession(picked, reviewMode: false);
  }

  void _startSession(
    List<_QuizQuestion> questions, {
    required bool reviewMode,
  }) {
    setState(() {
      _reviewMode = reviewMode;
      _questions = questions;
      _index = 0;
      _score = 0;
      _selectedIndex = null;
      _answered = false;
      _wrongIds.clear();
    });
  }

  void _selectAnswer(int choice) {
    if (_answered || _isFinished) return;
    final question = _questions[_index];
    setState(() {
      _selectedIndex = choice;
      _answered = true;
      if (choice == question.correctIndex) {
        _score++;
      } else {
        _wrongIds.add(question.id);
      }
    });
  }

  void _next() {
    if (!_answered) return;
    setState(() {
      _index++;
      _selectedIndex = null;
      _answered = false;
    });
  }

  void _restartDaily() {
    _startSession(_dailyQuestions, reviewMode: false);
  }

  void _startWrongOnlySession() {
    final wrongQuestions = _questions
        .where((q) => _wrongIds.contains(q.id))
        .toList(growable: false);
    if (wrongQuestions.isEmpty) return;
    final shuffled = [...wrongQuestions]
      ..shuffle(math.Random(DateTime.now().millisecondsSinceEpoch));
    _startSession(shuffled, reviewMode: true);
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return Scaffold(
      appBar: AppBar(
        title: Text(isKo ? '스킬 퀴즈' : 'Skill Quiz'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: _isFinished ? _buildResult(isKo) : _buildQuestion(isKo),
        ),
      ),
    );
  }

  Widget _buildQuestion(bool isKo) {
    final question = _questions[_index];
    final progress = '${_index + 1} / ${_questions.length}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _reviewMode
              ? (isKo ? '오답 복습 · 진행 $progress' : 'Wrong review · $progress')
              : (isKo ? '오늘의 퀴즈 · 진행 $progress' : 'Daily quiz · $progress'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          isKo
              ? '문제 풀: ${_pool.length}개 · 오늘 세트: ${_dailyQuestions.length}개'
              : 'Pool: ${_pool.length} · Today set: ${_dailyQuestions.length}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              isKo ? question.koQuestion : question.enQuestion,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...question.options.asMap().entries.map((entry) {
          final optionIndex = entry.key;
          final option = entry.value;
          final selected = _selectedIndex == optionIndex;
          final isCorrect = optionIndex == question.correctIndex;
          Color? borderColor;
          Color? bgColor;
          if (_answered) {
            if (isCorrect) {
              borderColor = const Color(0xFF0FA968);
              bgColor = const Color(0x1A0FA968);
            } else if (selected) {
              borderColor = const Color(0xFFEB5757);
              bgColor = const Color(0x1AEB5757);
            }
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: () => _selectAnswer(optionIndex),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                side: BorderSide(
                  color: borderColor ??
                      Theme.of(context).colorScheme.outlineVariant,
                  width: borderColor == null ? 1.0 : 1.6,
                ),
                backgroundColor: bgColor,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(isKo ? option.koText : option.enText),
                  ),
                  if (_answered && isCorrect)
                    const Icon(Icons.check_circle, color: Color(0xFF0FA968)),
                  if (_answered && selected && !isCorrect)
                    const Icon(Icons.cancel, color: Color(0xFFEB5757)),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        if (_answered)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Text(
              isKo ? question.koExplain : question.enExplain,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        const Spacer(),
        FilledButton.icon(
          onPressed: _answered ? _next : null,
          icon: const Icon(Icons.navigate_next),
          label: Text(isKo ? '다음' : 'Next'),
        ),
      ],
    );
  }

  Widget _buildResult(bool isKo) {
    final total = _questions.length;
    final ratio = total == 0 ? 0 : ((_score / total) * 100).round();
    final wrongCount = _wrongIds.length;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _reviewMode
                      ? (isKo ? '오답 복습 결과' : 'Wrong Review Result')
                      : (isKo ? '오늘의 퀴즈 결과' : 'Daily Quiz Result'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  isKo
                      ? '$_score / $total 정답 ($ratio%)'
                      : '$_score / $total correct ($ratio%)',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  isKo ? '오답 $wrongCount개' : '$wrongCount wrong question(s)',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (wrongCount > 0)
                  FilledButton.icon(
                    onPressed: _startWrongOnlySession,
                    icon: const Icon(Icons.restart_alt),
                    label: Text(isKo ? '오답 다시 풀기' : 'Retry wrong answers'),
                  ),
                if (wrongCount > 0) const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _restartDaily,
                  icon: const Icon(Icons.replay),
                  label: Text(isKo ? '오늘 문제 다시 풀기' : 'Retry today set'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizQuestion {
  final String id;
  final String koQuestion;
  final String enQuestion;
  final List<_QuizOption> options;
  final int correctIndex;
  final String koExplain;
  final String enExplain;

  const _QuizQuestion({
    required this.id,
    required this.koQuestion,
    required this.enQuestion,
    required this.options,
    required this.correctIndex,
    required this.koExplain,
    required this.enExplain,
  });
}

class _QuizOption {
  final String koText;
  final String enText;

  const _QuizOption({required this.koText, required this.enText});
}

class _SituationTemplate {
  final String id;
  final String koPrefix;
  final String enPrefix;

  const _SituationTemplate({
    required this.id,
    required this.koPrefix,
    required this.enPrefix,
  });
}

class _DecisionTemplate {
  final String id;
  final String koFocus;
  final String enFocus;
  final _QuizOption correct;
  final _QuizOption wrongA;
  final _QuizOption wrongB;
  final String koExplain;
  final String enExplain;

  const _DecisionTemplate({
    required this.id,
    required this.koFocus,
    required this.enFocus,
    required this.correct,
    required this.wrongA,
    required this.wrongB,
    required this.koExplain,
    required this.enExplain,
  });
}

class _OptionPack {
  final List<_QuizOption> options;
  final int correctIndex;

  const _OptionPack({required this.options, required this.correctIndex});
}

List<_QuizQuestion> _buildQuizPool() {
  final generated = <_QuizQuestion>[];

  for (final situation in _situations) {
    for (final decision in _decisions) {
      final id = 'gen_${situation.id}_${decision.id}';
      final packed = _buildOptionPack(
        seed: id,
        correct: decision.correct,
        wrongA: decision.wrongA,
        wrongB: decision.wrongB,
      );
      generated.add(
        _QuizQuestion(
          id: id,
          koQuestion: '${situation.koPrefix} ${decision.koFocus} 가장 적절한 선택은?',
          enQuestion:
              '${situation.enPrefix} what is the best choice for ${decision.enFocus}?',
          options: packed.options,
          correctIndex: packed.correctIndex,
          koExplain: decision.koExplain,
          enExplain: decision.enExplain,
        ),
      );
    }
  }

  return <_QuizQuestion>[
    ..._fundamentalQuestions,
    ...generated,
  ];
}

_OptionPack _buildOptionPack({
  required String seed,
  required _QuizOption correct,
  required _QuizOption wrongA,
  required _QuizOption wrongB,
}) {
  final order = <_QuizOption>[correct, wrongA, wrongB];
  final shift = _stableHash(seed) % order.length;
  final rotated = [...order.skip(shift), ...order.take(shift)];
  return _OptionPack(
    options: rotated,
    correctIndex: rotated.indexOf(correct),
  );
}

List<_QuizQuestion> _buildDailyQuestions(
  List<_QuizQuestion> pool,
  int seed,
  int count,
) {
  if (pool.isEmpty) return const <_QuizQuestion>[];
  final list = [...pool]..shuffle(math.Random(seed));
  final takeCount = math.min(count, list.length);
  return list.take(takeCount).toList(growable: false);
}

int _stableHash(String text) {
  var hash = 0;
  for (final code in text.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return hash;
}

const List<_SituationTemplate> _situations = <_SituationTemplate>[
  _SituationTemplate(
    id: 's1',
    koPrefix: '하프라인 근처에서 등지고 패스를 받을 때,',
    enPrefix: 'When receiving with your back near midfield,',
  ),
  _SituationTemplate(
    id: 's2',
    koPrefix: '상대 압박이 빠르게 다가오는 측면에서,',
    enPrefix: 'On the wing with fast pressure coming,',
  ),
  _SituationTemplate(
    id: 's3',
    koPrefix: '페널티 박스 앞 좁은 공간에서,',
    enPrefix: 'In tight space in front of the box,',
  ),
  _SituationTemplate(
    id: 's4',
    koPrefix: '역습 전환 순간 첫 터치를 해야 할 때,',
    enPrefix: 'At transition when making the first touch,',
  ),
  _SituationTemplate(
    id: 's5',
    koPrefix: '수비수 1:1 상황에서 돌파를 시도할 때,',
    enPrefix: 'In a 1v1 trying to beat a defender,',
  ),
  _SituationTemplate(
    id: 's6',
    koPrefix: '3인 패스 훈련에서 템포를 유지하려면,',
    enPrefix: 'To keep tempo in a 3-player passing drill,',
  ),
  _SituationTemplate(
    id: 's7',
    koPrefix: '중앙에서 압박을 벗겨야 하는 순간,',
    enPrefix: 'At a central moment where you must escape pressure,',
  ),
  _SituationTemplate(
    id: 's8',
    koPrefix: '패스 후 다시 공간으로 움직여야 할 때,',
    enPrefix: 'After passing and moving into space again,',
  ),
];

const List<_DecisionTemplate> _decisions = <_DecisionTemplate>[
  _DecisionTemplate(
    id: 'scan',
    koFocus: '스캔 타이밍에서',
    enFocus: 'scanning timing',
    correct: _QuizOption(
        koText: '받기 전-받는 순간-받은 직후 3번 확인',
        enText: 'Scan before, during, and right after receive'),
    wrongA: _QuizOption(
        koText: '볼이 오면 고개를 숙인다', enText: 'Drop your head as ball arrives'),
    wrongB: _QuizOption(
        koText: '트래핑 후에만 주변을 본다', enText: 'Only scan after trapping'),
    koExplain: '3회 스캔은 압박과 다음 패스 각도를 더 빠르게 파악하게 합니다.',
    enExplain: 'Three scans help read pressure and passing lanes faster.',
  ),
  _DecisionTemplate(
    id: 'body_open',
    koFocus: '몸 방향 설정에서',
    enFocus: 'body orientation',
    correct: _QuizOption(
        koText: '열린 몸으로 반턴 자세를 만든다',
        enText: 'Stay half-open and ready to turn'),
    wrongA:
        _QuizOption(koText: '완전히 등지고 선다', enText: 'Stand fully back to play'),
    wrongB: _QuizOption(
        koText: '두 발을 일자로 고정한다', enText: 'Lock both feet in a straight line'),
    koExplain: '열린 자세는 전진과 후진 선택을 동시에 확보합니다.',
    enExplain: 'An open body shape keeps both forward and safe options alive.',
  ),
  _DecisionTemplate(
    id: 'first_touch',
    koFocus: '퍼스트 터치 목적에서',
    enFocus: 'first-touch purpose',
    correct: _QuizOption(
        koText: '다음 동작이 가능한 위치로 터치',
        enText: 'Touch into space for the next action'),
    wrongA: _QuizOption(
        koText: '항상 발밑으로만 멈춤', enText: 'Always stop dead under your feet'),
    wrongB:
        _QuizOption(koText: '강하게 멀리 튕겨냄', enText: 'Push it too far with force'),
    koExplain: '좋은 퍼스트 터치는 다음 패스/드리블/슛을 미리 준비합니다.',
    enExplain: 'A good first touch prepares your next pass, dribble, or shot.',
  ),
  _DecisionTemplate(
    id: 'short_pass',
    koFocus: '짧은 패스 정확도에서',
    enFocus: 'short-pass accuracy',
    correct: _QuizOption(
        koText: '발 안쪽 중심으로 밀어준다', enText: 'Use inside foot with guided push'),
    wrongA: _QuizOption(koText: '발끝으로 찍어 찬다', enText: 'Poke with toe'),
    wrongB:
        _QuizOption(koText: '상체를 뒤로 젖힌다', enText: 'Lean back while passing'),
    koExplain: '발 안쪽은 접지면이 넓어 방향 제어가 쉽습니다.',
    enExplain: 'Inside foot gives wider contact and better direction control.',
  ),
  _DecisionTemplate(
    id: 'weight_control',
    koFocus: '패스 세기 조절에서',
    enFocus: 'pass weight control',
    correct: _QuizOption(
        koText: '상대 발 앞 공간에 맞춰 강도 조절',
        enText: 'Adjust pace into receiver path'),
    wrongA: _QuizOption(
        koText: '항상 최대 힘으로 찬다', enText: 'Hit every pass at max power'),
    wrongB: _QuizOption(
        koText: '힘 없이 굴리기만 한다', enText: 'Roll every pass too softly'),
    koExplain: '패스 강도는 수비 거리와 동료 움직임에 따라 달라져야 합니다.',
    enExplain:
        'Pass weight should match defender distance and teammate movement.',
  ),
  _DecisionTemplate(
    id: 'dribble_tempo',
    koFocus: '드리블 돌파 타이밍에서',
    enFocus: 'dribble tempo',
    correct:
        _QuizOption(koText: '느리게 유도 후 순간 가속', enText: 'Decelerate then burst'),
    wrongA: _QuizOption(
        koText: '처음부터 끝까지 같은 속도', enText: 'Stay same speed throughout'),
    wrongB: _QuizOption(
        koText: '볼을 멀리 두고 질주', enText: 'Sprint with distant touches'),
    koExplain: '템포 변화는 수비의 중심을 무너뜨리는 핵심입니다.',
    enExplain: 'Tempo changes are key to unbalancing defenders.',
  ),
  _DecisionTemplate(
    id: 'support_move',
    koFocus: '패스 후 움직임에서',
    enFocus: 'movement after pass',
    correct: _QuizOption(
        koText: '삼각형을 만들 수 있는 지원 위치 이동',
        enText: 'Move to create a support triangle'),
    wrongA:
        _QuizOption(koText: '패스 후 제자리에 멈춤', enText: 'Stay still after pass'),
    wrongB: _QuizOption(
        koText: '볼 쪽으로만 일직선 이동', enText: 'Run straight only toward ball'),
    koExplain: '지원 각도를 만들면 다음 연결이 쉬워집니다.',
    enExplain: 'Creating support angles makes the next link easier.',
  ),
  _DecisionTemplate(
    id: 'pressure_escape',
    koFocus: '압박 탈출 선택에서',
    enFocus: 'escaping pressure',
    correct: _QuizOption(
        koText: '원터치 리턴 혹은 제3자 패스 활용',
        enText: 'Use one-touch return or third-man pass'),
    wrongA: _QuizOption(
        koText: '2명 사이로 무리한 턴', enText: 'Force turn between two defenders'),
    wrongB:
        _QuizOption(koText: '볼을 오래 끌며 기다림', enText: 'Hold the ball too long'),
    koExplain: '간결한 연결이 압박 강도를 빠르게 낮춥니다.',
    enExplain: 'Simple combinations quickly reduce pressure intensity.',
  ),
  _DecisionTemplate(
    id: 'receive_far_foot',
    koFocus: '받는 발 선택에서',
    enFocus: 'receiving foot choice',
    correct: _QuizOption(
        koText: '상대와 먼 발로 받아 몸 보호', enText: 'Receive with far foot to shield'),
    wrongA: _QuizOption(
        koText: '상대 쪽 가까운 발만 사용', enText: 'Use only near foot toward defender'),
    wrongB: _QuizOption(
        koText: '두 발을 붙인 채 트래핑', enText: 'Trap with feet stuck together'),
    koExplain: '먼 발 컨트롤은 몸 사이에 공을 두어 안전합니다.',
    enExplain: 'Far-foot control keeps your body between defender and ball.',
  ),
  _DecisionTemplate(
    id: 'scan_after_pass',
    koFocus: '패스 직후 스캔에서',
    enFocus: 'scan after pass',
    correct: _QuizOption(
        koText: '다음 수비/공간 위치를 즉시 재확인',
        enText: 'Immediately rescan defenders and space'),
    wrongA: _QuizOption(
        koText: '방금 패스한 볼만 계속 본다',
        enText: 'Keep watching only the passed ball'),
    wrongB: _QuizOption(
        koText: '멈춰서 지시만 한다', enText: 'Stop and only call instructions'),
    koExplain: '패스 직후 재스캔은 다음 지원 위치 선택을 빠르게 합니다.',
    enExplain: 'Post-pass rescan speeds up your next support decision.',
  ),
];

const List<_QuizQuestion> _fundamentalQuestions = <_QuizQuestion>[
  _QuizQuestion(
    id: 'f_01',
    koQuestion: '패스 받기 전 어깨 너비 스탠스의 주된 목적은?',
    enQuestion: 'Main purpose of shoulder-width stance before receiving?',
    options: [
      _QuizOption(koText: '균형과 방향 전환 준비', enText: 'Balance and turn readiness'),
      _QuizOption(koText: '속도를 완전히 멈추기', enText: 'Completely stop speed'),
      _QuizOption(koText: '점프 준비', enText: 'Prepare to jump'),
    ],
    correctIndex: 0,
    koExplain: '균형이 안정되면 압박 상황에서 첫 터치가 좋아집니다.',
    enExplain: 'Stable balance improves first touch under pressure.',
  ),
  _QuizQuestion(
    id: 'f_02',
    koQuestion: '컨트롤 후 즉시 볼을 숨기는 기본 방법은?',
    enQuestion: 'Basic way to protect the ball right after control?',
    options: [
      _QuizOption(
          koText: '몸과 팔로 수비를 차단', enText: 'Use body/arm to block defender'),
      _QuizOption(koText: '볼을 멀리 떼기', enText: 'Knock ball far away'),
      _QuizOption(koText: '시선 고정', enText: 'Freeze your gaze'),
    ],
    correctIndex: 0,
    koExplain: '몸으로 수비 라인을 끊으면 공 소유 유지 확률이 높습니다.',
    enExplain: 'Body shielding increases ball retention probability.',
  ),
  _QuizQuestion(
    id: 'f_03',
    koQuestion: '압박이 오기 전 가장 먼저 확인할 정보는?',
    enQuestion: 'What to check first before pressure arrives?',
    options: [
      _QuizOption(koText: '수비수 접근 방향', enText: 'Defender approach direction'),
      _QuizOption(koText: '잔디 상태만 확인', enText: 'Only check grass condition'),
      _QuizOption(koText: '관중석 보기', enText: 'Look at stands'),
    ],
    correctIndex: 0,
    koExplain: '접근 방향을 알아야 탈압박 터치 방향을 정할 수 있습니다.',
    enExplain: 'Approach direction defines your escape touch direction.',
  ),
  _QuizQuestion(
    id: 'f_04',
    koQuestion: '원터치 패스의 가장 큰 장점은?',
    enQuestion: 'Biggest advantage of one-touch passing?',
    options: [
      _QuizOption(
          koText: '템포 유지와 압박 회피', enText: 'Maintain tempo and avoid pressure'),
      _QuizOption(
          koText: '항상 강한 패스 가능', enText: 'Always produce powerful pass'),
      _QuizOption(koText: '개인기 과시', enText: 'Show off dribbling tricks'),
    ],
    correctIndex: 0,
    koExplain: '볼 소유 시간을 줄여 압박 타이밍을 무력화합니다.',
    enExplain: 'Shorter ball time neutralizes pressing timing.',
  ),
  _QuizQuestion(
    id: 'f_05',
    koQuestion: '드리블 시 볼 터치 간격의 기본 원칙은?',
    enQuestion: 'Basic rule for touch spacing while dribbling?',
    options: [
      _QuizOption(
          koText: '상황에 맞게 짧고 길게 조절', enText: 'Adjust short/long by situation'),
      _QuizOption(koText: '항상 동일 간격', enText: 'Always keep equal spacing'),
      _QuizOption(koText: '항상 크게만', enText: 'Always take big touches'),
    ],
    correctIndex: 0,
    koExplain: '수비 거리와 공간에 따라 터치 길이를 바꿔야 합니다.',
    enExplain: 'Touch length must change with space and defender distance.',
  ),
  _QuizQuestion(
    id: 'f_06',
    koQuestion: '패스 라인이 막혔을 때 우선 선택은?',
    enQuestion: 'First option when passing lane is blocked?',
    options: [
      _QuizOption(
          koText: '각도 재조정 후 안전한 연결', enText: 'Re-angle and connect safely'),
      _QuizOption(koText: '무리한 직선 패스', enText: 'Force straight pass'),
      _QuizOption(koText: '멈춰서 드리블만', enText: 'Stop and dribble only'),
    ],
    correctIndex: 0,
    koExplain: '작은 각도 수정만으로 새로운 라인이 열립니다.',
    enExplain: 'Small angle changes can open new passing lanes.',
  ),
  _QuizQuestion(
    id: 'f_07',
    koQuestion: '컨트롤 훈련에서 약발을 포함해야 하는 이유는?',
    enQuestion: 'Why include weak foot in control training?',
    options: [
      _QuizOption(
          koText: '압박 상황 선택지를 늘리기 위해',
          enText: 'Increase options under pressure'),
      _QuizOption(koText: '훈련 시간을 줄이기 위해', enText: 'Shorten training time'),
      _QuizOption(koText: '폼만 보기 위해', enText: 'Only for form appearance'),
    ],
    correctIndex: 0,
    koExplain: '양발 사용은 전개 속도와 탈압박 성공률을 높입니다.',
    enExplain: 'Two-foot usage improves buildup speed and escape success.',
  ),
  _QuizQuestion(
    id: 'f_08',
    koQuestion: '첫 터치가 길어졌을 때 즉시 해야 할 행동은?',
    enQuestion: 'What to do immediately after a heavy first touch?',
    options: [
      _QuizOption(
          koText: '몸을 먼저 넣어 공을 보호',
          enText: 'Get body in first to protect ball'),
      _QuizOption(koText: '서서 기다린다', enText: 'Stand and wait'),
      _QuizOption(koText: '시선을 돌린다', enText: 'Look away'),
    ],
    correctIndex: 0,
    koExplain: '몸을 먼저 쓰면 공을 되찾을 시간을 벌 수 있습니다.',
    enExplain: 'Body-first reaction buys time to recover possession.',
  ),
  _QuizQuestion(
    id: 'f_09',
    koQuestion: '스캔 품질을 높이는 가장 쉬운 루틴은?',
    enQuestion: 'Easiest routine to improve scan quality?',
    options: [
      _QuizOption(
          koText: '볼 도착 전 양쪽 확인 습관', enText: 'Check both sides before arrival'),
      _QuizOption(koText: '한쪽만 반복 확인', enText: 'Repeat checking one side only'),
      _QuizOption(koText: '트래핑 후만 확인', enText: 'Check only after trap'),
    ],
    correctIndex: 0,
    koExplain: '좌우 확인 습관은 블라인드 압박을 줄여줍니다.',
    enExplain: 'Two-side scanning reduces blind-side pressure.',
  ),
  _QuizQuestion(
    id: 'f_10',
    koQuestion: '드리블로 수비를 끌어낸 뒤 좋은 선택은?',
    enQuestion: 'After drawing a defender by dribbling, best next action?',
    options: [
      _QuizOption(
          koText: '빈 동료에게 빠른 패스', enText: 'Quick pass to free teammate'),
      _QuizOption(koText: '계속 혼자 돌파', enText: 'Keep forcing solo dribble'),
      _QuizOption(koText: '뒤로만 이동', enText: 'Move backward only'),
    ],
    correctIndex: 0,
    koExplain: '수비를 끌었다면 빈 공간 활용이 효율적입니다.',
    enExplain:
        'Once defender is attracted, exploiting free space is efficient.',
  ),
  _QuizQuestion(
    id: 'f_11',
    koQuestion: '컨트롤 시 시선 처리의 기본은?',
    enQuestion: 'Basic eye behavior during control?',
    options: [
      _QuizOption(
          koText: '볼-상황을 짧게 번갈아 보기',
          enText: 'Alternate brief looks ball-context'),
      _QuizOption(koText: '계속 볼만 보기', enText: 'Keep eyes only on ball'),
      _QuizOption(koText: '눈 감고 트래핑', enText: 'Trap with eyes closed'),
    ],
    correctIndex: 0,
    koExplain: '시선 전환이 다음 판단 속도를 높입니다.',
    enExplain: 'Eye switching speeds up next decision making.',
  ),
  _QuizQuestion(
    id: 'f_12',
    koQuestion: '패스 전에 딛는 발의 역할은?',
    enQuestion: 'Role of the plant foot before passing?',
    options: [
      _QuizOption(koText: '방향과 균형을 고정', enText: 'Fix direction and balance'),
      _QuizOption(koText: '무작정 점프', enText: 'Jump randomly'),
      _QuizOption(koText: '공을 건드림', enText: 'Touch the ball with it'),
    ],
    correctIndex: 0,
    koExplain: '딛는 발이 안정되면 패스 정확도가 올라갑니다.',
    enExplain: 'Stable plant foot raises passing precision.',
  ),
  _QuizQuestion(
    id: 'f_13',
    koQuestion: '원터치가 어려운 상황에서 차선책은?',
    enQuestion: 'Best fallback when one-touch is not possible?',
    options: [
      _QuizOption(
          koText: '짧은 컨트롤 후 2터치 연결', enText: 'Short control then 2-touch link'),
      _QuizOption(koText: '볼을 멈추고 정지', enText: 'Stop ball and freeze'),
      _QuizOption(koText: '공을 멀리 차냄', enText: 'Kick ball far away'),
    ],
    correctIndex: 0,
    koExplain: '2터치는 리듬을 크게 잃지 않으면서 안정성을 확보합니다.',
    enExplain: 'Two-touch keeps rhythm while adding control.',
  ),
  _QuizQuestion(
    id: 'f_14',
    koQuestion: '패스 받을 때 발 소음이 큰 경우 주로 의미하는 것은?',
    enQuestion: 'Loud touch sound while receiving usually means?',
    options: [
      _QuizOption(koText: '충격 흡수가 부족함', enText: 'Insufficient cushioning'),
      _QuizOption(koText: '기술이 완벽함', enText: 'Perfect technique'),
      _QuizOption(koText: '볼이 가벼움', enText: 'Ball is too light'),
    ],
    correctIndex: 0,
    koExplain: '완충이 되면 볼의 반동이 줄어 다음 동작이 쉬워집니다.',
    enExplain: 'Good cushioning reduces rebound and eases next action.',
  ),
  _QuizQuestion(
    id: 'f_15',
    koQuestion: '압박 상황 패스에서 가장 흔한 실수는?',
    enQuestion: 'Most common passing mistake under pressure?',
    options: [
      _QuizOption(koText: '준비 없이 급하게 발만 뻗기', enText: 'Rushing without setup'),
      _QuizOption(koText: '스캔 후 패스하기', enText: 'Passing after scanning'),
      _QuizOption(koText: '열린 몸 유지', enText: 'Keeping open body shape'),
    ],
    correctIndex: 0,
    koExplain: '준비 없는 패스는 방향/강도 실수로 이어지기 쉽습니다.',
    enExplain: 'Unprepared passes often fail in direction and weight.',
  ),
  _QuizQuestion(
    id: 'f_16',
    koQuestion: '드리블 중 시야 확보를 위해 필요한 습관은?',
    enQuestion: 'Habit needed to keep vision while dribbling?',
    options: [
      _QuizOption(
          koText: '짧은 터치와 고개 들기 반복',
          enText: 'Repeat short touches and head-up checks'),
      _QuizOption(koText: '볼만 계속 응시', enText: 'Stare only at the ball'),
      _QuizOption(koText: '긴 터치만 사용', enText: 'Use only long touches'),
    ],
    correctIndex: 0,
    koExplain: '짧은 터치가 시선 전환 시간을 확보해 줍니다.',
    enExplain: 'Short touches buy time for visual scanning.',
  ),
  _QuizQuestion(
    id: 'f_17',
    koQuestion: '트래핑 이후 이상적인 첫 시선은?',
    enQuestion: 'Ideal first look after trapping?',
    options: [
      _QuizOption(
          koText: '가장 가까운 압박과 탈출 방향',
          enText: 'Nearest pressure and escape lane'),
      _QuizOption(koText: '벤치 쪽', enText: 'Toward the bench'),
      _QuizOption(koText: '골대 위 전광판', enText: 'Stadium scoreboard'),
    ],
    correctIndex: 0,
    koExplain: '압박-탈출 축을 먼저 보면 의사결정이 빨라집니다.',
    enExplain: 'Checking pressure-escape axis first speeds decisions.',
  ),
  _QuizQuestion(
    id: 'f_18',
    koQuestion: '패스 받을 때 한 발이 고정되어 있으면 생기는 문제는?',
    enQuestion: 'Problem when one foot stays fixed while receiving?',
    options: [
      _QuizOption(koText: '회전 반응이 느려짐', enText: 'Slower turning reaction'),
      _QuizOption(koText: '패스 속도 증가', enText: 'Faster passing speed'),
      _QuizOption(koText: '시야 확대', enText: 'Wider vision'),
    ],
    correctIndex: 0,
    koExplain: '유연한 스텝이 있어야 방향 전환이 즉각 가능합니다.',
    enExplain: 'Flexible footwork enables instant directional turns.',
  ),
  _QuizQuestion(
    id: 'f_19',
    koQuestion: '공간이 좁을수록 패스 전 필요한 것은?',
    enQuestion: 'What is more necessary before passing in tight space?',
    options: [
      _QuizOption(
          koText: '터치 수 최소화와 미리 보기', enText: 'Minimize touches and pre-scan'),
      _QuizOption(koText: '큰 백스윙', enText: 'Large backswing'),
      _QuizOption(koText: '긴 드리블', enText: 'Long carry dribble'),
    ],
    correctIndex: 0,
    koExplain: '좁은 공간일수록 준비 시간이 짧아 선행 스캔이 중요합니다.',
    enExplain: 'Tight spaces need pre-scan because prep time is short.',
  ),
  _QuizQuestion(
    id: 'f_20',
    koQuestion: '훈련에서 오답/실수를 다시 푸는 목적은?',
    enQuestion: 'Purpose of retrying wrong answers/mistakes in training?',
    options: [
      _QuizOption(
          koText: '약점을 반복 교정해 자동화', enText: 'Correct weaknesses into habits'),
      _QuizOption(koText: '정답 개수만 늘리기', enText: 'Only increase score count'),
      _QuizOption(koText: '훈련 시간을 채우기', enText: 'Just fill training time'),
    ],
    correctIndex: 0,
    koExplain: '오답 반복은 실제 경기 판단의 정확도를 높입니다.',
    enExplain: 'Retrying mistakes improves real-match decision accuracy.',
  ),
];
