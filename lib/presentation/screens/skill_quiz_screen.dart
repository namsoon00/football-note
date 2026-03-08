import 'dart:math' as math;

import 'package:flutter/material.dart';

class SkillQuizScreen extends StatefulWidget {
  const SkillQuizScreen({super.key});

  @override
  State<SkillQuizScreen> createState() => _SkillQuizScreenState();
}

class _SkillQuizScreenState extends State<SkillQuizScreen> {
  static const int _dailyQuestionCount = 20;

  late final Map<_QuizType, List<_QuizQuestion>> _poolByType;
  _QuizType _selectedType = _QuizType.mixed;
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
  List<_QuizQuestion> get _selectedPool =>
      _poolByType[_selectedType] ?? const <_QuizQuestion>[];

  @override
  void initState() {
    super.initState();
    final typed = <_QuizType, List<_QuizQuestion>>{
      _QuizType.pass: _buildTypedQuizPool(_QuizType.pass),
      _QuizType.dribble: _buildTypedQuizPool(_QuizType.dribble),
      _QuizType.control: _buildTypedQuizPool(_QuizType.control),
      _QuizType.scan: _buildTypedQuizPool(_QuizType.scan),
    };
    _poolByType = {
      ...typed,
      _QuizType.mixed:
          typed.values.expand((list) => list).toList(growable: false),
    };
    _startDailyForType(_selectedType);
  }

  void _startDailyForType(_QuizType type) {
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day);
    final seed = (date.year * 10000) +
        (date.month * 100) +
        date.day +
        (_stableHash(type.name) * 17);
    final picked = _buildDailyQuestions(
      _poolByType[type] ?? const <_QuizQuestion>[],
      seed,
      _dailyQuestionCount,
    );

    setState(() {
      _selectedType = type;
      _dailySeed = seed;
      _dailyQuestions = picked;
      _questions = picked;
      _reviewMode = false;
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
    setState(() {
      _questions = _dailyQuestions;
      _reviewMode = false;
      _index = 0;
      _score = 0;
      _selectedIndex = null;
      _answered = false;
      _wrongIds.clear();
    });
  }

  void _startWrongOnlySession() {
    final wrongQuestions = _questions
        .where((q) => _wrongIds.contains(q.id))
        .toList(growable: false);
    if (wrongQuestions.isEmpty) return;
    final shuffled = [...wrongQuestions]
      ..shuffle(math.Random(DateTime.now().millisecondsSinceEpoch));
    setState(() {
      _questions = shuffled;
      _reviewMode = true;
      _index = 0;
      _score = 0;
      _selectedIndex = null;
      _answered = false;
      _wrongIds.clear();
    });
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
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _QuizType.values.map((type) {
            final selected = _selectedType == type;
            return ChoiceChip(
              label: Text(type.label(isKo)),
              selected: selected,
              onSelected: (_) => _startDailyForType(type),
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: 8),
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
              ? '${_selectedType.label(true)} 유형 문제풀 ${_selectedPool.length}개(유형당 100개) · 오늘 세트 ${_dailyQuestions.length}개'
              : '${_selectedType.label(false)} pool ${_selectedPool.length} (100 per type) · today set ${_dailyQuestions.length}',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                side: BorderSide(
                  color: borderColor ??
                      Theme.of(context).colorScheme.outlineVariant,
                  width: borderColor == null ? 1.0 : 1.6,
                ),
                backgroundColor: bgColor,
              ),
              child: Row(
                children: [
                  Expanded(child: Text(isKo ? option.koText : option.enText)),
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
                const SizedBox(height: 6),
                Text(
                  isKo
                      ? '${_selectedType.label(true)} 유형(시드: $_dailySeed)'
                      : '${_selectedType.label(false)} type (seed: $_dailySeed)',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
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

enum _QuizType { mixed, pass, dribble, control, scan }

extension _QuizTypeLabel on _QuizType {
  String label(bool isKo) {
    return switch (this) {
      _QuizType.pass => isKo ? '패스' : 'Pass',
      _QuizType.dribble => isKo ? '드리블' : 'Dribble',
      _QuizType.control => isKo ? '컨트롤' : 'Control',
      _QuizType.scan => isKo ? '스캔' : 'Scan',
      _QuizType.mixed => isKo ? '혼합' : 'Mixed',
    };
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

class _QuizSituation {
  final String id;
  final String koPrefix;
  final String enPrefix;

  const _QuizSituation(
      {required this.id, required this.koPrefix, required this.enPrefix});
}

class _QuizConcept {
  final String id;
  final String koPrompt;
  final String enPrompt;
  final _QuizOption correct;
  final _QuizOption wrongA;
  final _QuizOption wrongB;
  final String koExplain;
  final String enExplain;

  const _QuizConcept({
    required this.id,
    required this.koPrompt,
    required this.enPrompt,
    required this.correct,
    required this.wrongA,
    required this.wrongB,
    required this.koExplain,
    required this.enExplain,
  });
}

List<_QuizQuestion> _buildTypedQuizPool(_QuizType type) {
  if (type == _QuizType.mixed) {
    return const <_QuizQuestion>[];
  }
  final concepts = _conceptsByType[type] ?? const <_QuizConcept>[];
  final pool = <_QuizQuestion>[];
  for (final s in _situations) {
    for (final c in concepts) {
      final id = '${type.name}_${s.id}_${c.id}';
      final pack = _buildOptionPack(id, c.correct, c.wrongA, c.wrongB);
      pool.add(
        _QuizQuestion(
          id: id,
          koQuestion: '${s.koPrefix} ${c.koPrompt}',
          enQuestion: '${s.enPrefix} ${c.enPrompt}',
          options: pack.options,
          correctIndex: pack.correctIndex,
          koExplain: c.koExplain,
          enExplain: c.enExplain,
        ),
      );
    }
  }
  return pool;
}

_OptionPack _buildOptionPack(
  String seed,
  _QuizOption correct,
  _QuizOption wrongA,
  _QuizOption wrongB,
) {
  final options = <_QuizOption>[correct, wrongA, wrongB];
  final shift = _stableHash(seed) % 3;
  final rotated = [...options.skip(shift), ...options.take(shift)];
  return _OptionPack(rotated, rotated.indexOf(correct));
}

class _OptionPack {
  final List<_QuizOption> options;
  final int correctIndex;

  const _OptionPack(this.options, this.correctIndex);
}

List<_QuizQuestion> _buildDailyQuestions(
    List<_QuizQuestion> pool, int seed, int count) {
  if (pool.isEmpty) return const <_QuizQuestion>[];
  final list = [...pool]..shuffle(math.Random(seed));
  return list.take(math.min(count, list.length)).toList(growable: false);
}

int _stableHash(String text) {
  var hash = 0;
  for (final code in text.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return hash;
}

const List<_QuizSituation> _situations = <_QuizSituation>[
  _QuizSituation(
      id: 's01',
      koPrefix: '하프라인 부근에서 받는 순간,',
      enPrefix: 'Near midfield when receiving,'),
  _QuizSituation(
      id: 's02',
      koPrefix: '측면 압박이 빠르게 올 때,',
      enPrefix: 'When wing pressure comes fast,'),
  _QuizSituation(
      id: 's03', koPrefix: '중앙 좁은 공간에서,', enPrefix: 'In tight central space,'),
  _QuizSituation(
      id: 's04',
      koPrefix: '역습 전환 1~2초 안에,',
      enPrefix: 'Within 1-2 seconds of transition,'),
  _QuizSituation(
      id: 's05',
      koPrefix: '수비수와 1:1 대치 시,',
      enPrefix: 'In a 1v1 against a defender,'),
  _QuizSituation(
      id: 's06',
      koPrefix: '3인 연계 훈련 템포 유지에서,',
      enPrefix: 'To keep tempo in a 3-player combo,'),
  _QuizSituation(
      id: 's07',
      koPrefix: '패스 후 다시 지원할 때,',
      enPrefix: 'After passing and supporting again,'),
  _QuizSituation(
      id: 's08',
      koPrefix: '박스 앞 의사결정에서,',
      enPrefix: 'In decision making near the box,'),
  _QuizSituation(
      id: 's09',
      koPrefix: '압박 탈출 첫 선택에서,',
      enPrefix: 'In your first pressure-escape choice,'),
  _QuizSituation(
      id: 's10',
      koPrefix: '템포를 끊지 않아야 할 때,',
      enPrefix: 'When you must not break tempo,'),
];

const Map<_QuizType, List<_QuizConcept>> _conceptsByType =
    <_QuizType, List<_QuizConcept>>{
  _QuizType.pass: <_QuizConcept>[
    _QuizConcept(
        id: 'p01',
        koPrompt: '패스 각도 선택으로 가장 좋은 것은?',
        enPrompt: 'what is the best passing-angle choice?',
        correct: _QuizOption(
            koText: '열린 발 앞 공간으로 보낸다',
            enText: 'Play into the open front foot space'),
        wrongA: _QuizOption(
            koText: '수비 정면으로 찌른다', enText: 'Force straight at defender'),
        wrongB:
            _QuizOption(koText: '무조건 뒤로만 준다', enText: 'Always pass backward'),
        koExplain: '열린 발 앞 공간 패스가 다음 동작 연결에 유리합니다.',
        enExplain:
            'Passing into open front-foot space improves next-action flow.'),
    _QuizConcept(
        id: 'p02',
        koPrompt: '짧은 패스 접촉 면으로 맞는 것은?',
        enPrompt: 'which contact surface is correct for short pass?',
        correct: _QuizOption(koText: '발 안쪽', enText: 'Inside of foot'),
        wrongA: _QuizOption(koText: '발끝', enText: 'Toe'),
        wrongB: _QuizOption(koText: '뒤꿈치', enText: 'Heel'),
        koExplain: '발 안쪽은 방향과 힘 제어가 안정적입니다.',
        enExplain: 'Inside foot gives stable direction and power control.'),
    _QuizConcept(
        id: 'p03',
        koPrompt: '패스 강도 조절의 기준은?',
        enPrompt: 'what should determine pass weight?',
        correct: _QuizOption(
            koText: '동료 속도와 수비 거리',
            enText: 'Teammate speed and defender distance'),
        wrongA: _QuizOption(koText: '항상 최대 힘', enText: 'Always max power'),
        wrongB: _QuizOption(koText: '항상 약하게', enText: 'Always too soft'),
        koExplain: '패스 세기는 상황 기반으로 바뀌어야 정확도가 올라갑니다.',
        enExplain: 'Context-based weight increases pass accuracy.'),
    _QuizConcept(
        id: 'p04',
        koPrompt: '원터치 패스를 쓰는 주된 이유는?',
        enPrompt: 'why use one-touch passing primarily?',
        correct: _QuizOption(
            koText: '압박 시간을 줄이기 위해', enText: 'To reduce pressure time'),
        wrongA: _QuizOption(koText: '폼을 보여주기 위해', enText: 'To show style only'),
        wrongB: _QuizOption(
            koText: '항상 더 강하게 차기 위해', enText: 'To kick harder always'),
        koExplain: '볼 점유 시간을 줄여 압박을 무력화합니다.',
        enExplain: 'It neutralizes pressure by shortening ball-holding time.'),
    _QuizConcept(
        id: 'p05',
        koPrompt: '패스 전 딛는 발의 역할은?',
        enPrompt: 'what is the role of your plant foot?',
        correct: _QuizOption(
            koText: '몸 균형과 방향 고정', enText: 'Stabilize body and direction'),
        wrongA:
            _QuizOption(koText: '공을 건드리는 용도', enText: 'Touch the ball itself'),
        wrongB: _QuizOption(koText: '점프 준비 용도', enText: 'Prepare a jump'),
        koExplain: '딛는 발이 안정되면 패스 오차가 줄어듭니다.',
        enExplain: 'A stable plant foot reduces passing error.'),
    _QuizConcept(
        id: 'p06',
        koPrompt: '패스 라인이 막히면 우선 무엇을 할까?',
        enPrompt: 'what should you do first if lane is blocked?',
        correct:
            _QuizOption(koText: '각도 재조정 후 연결', enText: 'Re-angle then connect'),
        wrongA: _QuizOption(koText: '무리한 직선 패스', enText: 'Force straight pass'),
        wrongB: _QuizOption(koText: '볼을 멈추고 기다림', enText: 'Stop and wait'),
        koExplain: '작은 위치 조정으로 새 라인을 만들 수 있습니다.',
        enExplain: 'Small repositioning opens new lanes.'),
    _QuizConcept(
        id: 'p07',
        koPrompt: '전진 패스가 좋은 타이밍은?',
        enPrompt: 'when is forward pass timing best?',
        correct: _QuizOption(
            koText: '동료가 몸을 열고 받을 때',
            enText: 'When teammate is open to receive'),
        wrongA: _QuizOption(
            koText: '동료가 등진 상태일 때',
            enText: 'When teammate is fully back-turned'),
        wrongB: _QuizOption(
            koText: '수비 둘 사이 닫혔을 때', enText: 'When two defenders close lane'),
        koExplain: '받는 자세가 열려야 다음 전개가 이어집니다.',
        enExplain: 'Open receiving posture supports next progression.'),
    _QuizConcept(
        id: 'p08',
        koPrompt: '패스 후 가장 좋은 움직임은?',
        enPrompt: 'what is best movement after pass?',
        correct: _QuizOption(
            koText: '삼각형 지원 각도 만들기', enText: 'Create support triangle angle'),
        wrongA: _QuizOption(koText: '제자리 정지', enText: 'Stand still'),
        wrongB: _QuizOption(
            koText: '공 쪽 직선 돌진만', enText: 'Run straight only to ball'),
        koExplain: '지원 각도가 생기면 연계 성공률이 높아집니다.',
        enExplain: 'Support angles increase combination success rate.'),
    _QuizConcept(
        id: 'p09',
        koPrompt: '리턴 패스를 사용할 상황은?',
        enPrompt: 'when should return pass be used?',
        correct: _QuizOption(
            koText: '강한 압박에서 안전 연결이 필요할 때',
            enText: 'When heavy pressure needs safe link'),
        wrongA: _QuizOption(
            koText: '항상 리턴만 고집', enText: 'Always force return pass'),
        wrongB: _QuizOption(
            koText: '압박이 없을 때만 사용', enText: 'Use only without pressure'),
        koExplain: '리턴 패스는 압박 탈출의 기본 옵션입니다.',
        enExplain: 'Return pass is a core pressure-escape option.'),
    _QuizConcept(
        id: 'p10',
        koPrompt: '패스 성공률을 높이는 시선은?',
        enPrompt: 'what vision habit boosts pass success?',
        correct: _QuizOption(
            koText: '수비와 동료를 번갈아 짧게 확인',
            enText: 'Alternate quick checks of defenders and teammates'),
        wrongA: _QuizOption(koText: '공만 끝까지 응시', enText: 'Stare only at ball'),
        wrongB: _QuizOption(
            koText: '고개를 완전히 돌리고 멈춤', enText: 'Turn head away and stop'),
        koExplain: '짧은 스캔 반복이 패스 의사결정을 빠르게 합니다.',
        enExplain: 'Repeated micro-scans accelerate pass decisions.'),
  ],
  _QuizType.dribble: <_QuizConcept>[
    _QuizConcept(
        id: 'd01',
        koPrompt: '돌파 시작 전 핵심은?',
        enPrompt: 'what is key before starting a beat?',
        correct:
            _QuizOption(koText: '템포 변화 준비', enText: 'Prepare tempo change'),
        wrongA: _QuizOption(koText: '처음부터 최고속', enText: 'Max speed from start'),
        wrongB: _QuizOption(koText: '고개 숙이고 전진', enText: 'Head down run'),
        koExplain: '템포 변화가 수비 중심을 흔듭니다.',
        enExplain: 'Tempo change destabilizes defender balance.'),
    _QuizConcept(
        id: 'd02',
        koPrompt: '좁은 공간 드리블 기본은?',
        enPrompt: 'what is basic dribbling in tight space?',
        correct: _QuizOption(
            koText: '짧은 터치와 몸 보호', enText: 'Short touches with body shielding'),
        wrongA: _QuizOption(koText: '큰 터치 반복', enText: 'Repeated long touches'),
        wrongB: _QuizOption(
            koText: '정지 후 출발 반복', enText: 'Stop-start without control'),
        koExplain: '짧은 터치가 볼 소유 안정성을 높입니다.',
        enExplain: 'Short touches improve possession stability.'),
    _QuizConcept(
        id: 'd03',
        koPrompt: '수비를 흔드는 가장 쉬운 방법은?',
        enPrompt: 'what is easiest way to unbalance defender?',
        correct: _QuizOption(
            koText: '시선 페이크 + 방향 전환', enText: 'Eye fake plus direction change'),
        wrongA: _QuizOption(koText: '속도만 올린다', enText: 'Only increase speed'),
        wrongB: _QuizOption(
            koText: '항상 같은 터치 리듬', enText: 'Always same touch rhythm'),
        koExplain: '시선과 템포 조합이 수비 반응을 늦춥니다.',
        enExplain: 'Eye-tempo combo delays defensive reaction.'),
    _QuizConcept(
        id: 'd04',
        koPrompt: '드리블 중 시야 확보 습관은?',
        enPrompt: 'what keeps vision while dribbling?',
        correct: _QuizOption(
            koText: '짧은 터치 후 고개 들기',
            enText: 'Head-up checks after short touches'),
        wrongA: _QuizOption(koText: '볼만 지속 응시', enText: 'Keep staring at ball'),
        wrongB: _QuizOption(
            koText: '시선 고정하고 가속', enText: 'Fixed gaze with acceleration'),
        koExplain: '시야가 열려야 다음 선택이 빨라집니다.',
        enExplain: 'Open vision speeds up next action choice.'),
    _QuizConcept(
        id: 'd05',
        koPrompt: '1:1에서 먼저 해야 할 것은?',
        enPrompt: 'what should come first in 1v1?',
        correct: _QuizOption(
            koText: '수비 발/무게중심 관찰', enText: 'Read defender foot and weight'),
        wrongA: _QuizOption(koText: '바로 큰 터치', enText: 'Immediate big touch'),
        wrongB:
            _QuizOption(koText: '멈춰서 공만 보호', enText: 'Only stop and shield'),
        koExplain: '상대 중심을 읽어야 효율적인 돌파가 가능합니다.',
        enExplain: 'Reading balance enables efficient beating.'),
    _QuizConcept(
        id: 'd06',
        koPrompt: '가속 타이밍은 언제가 좋은가?',
        enPrompt: 'when is acceleration timing best?',
        correct: _QuizOption(
            koText: '수비 발이 멈춘 순간', enText: 'When defender feet get planted'),
        wrongA: _QuizOption(
            koText: '항상 첫 터치 직후', enText: 'Always right after first touch'),
        wrongB: _QuizOption(
            koText: '라인 밖으로 밀린 뒤', enText: 'After being pushed wide'),
        koExplain: '수비가 멈추는 찰나가 가속 창입니다.',
        enExplain: 'Defender planted moment is acceleration window.'),
    _QuizConcept(
        id: 'd07',
        koPrompt: '측면 돌파 후 우선 판단은?',
        enPrompt: 'after wing beat, what is first read?',
        correct:
            _QuizOption(koText: '컷백/크로스 각도', enText: 'Cutback or cross angle'),
        wrongA:
            _QuizOption(koText: '무조건 슛', enText: 'Always shoot immediately'),
        wrongB:
            _QuizOption(koText: '다시 후퇴 드리블', enText: 'Retreat dribble again'),
        koExplain: '돌파 이후는 선택지 판단이 더 중요합니다.',
        enExplain: 'Post-beat choice quality matters most.'),
    _QuizConcept(
        id: 'd08',
        koPrompt: '드리블 접촉 부위 활용으로 맞는 것은?',
        enPrompt: 'which touch-surface usage is right?',
        correct: _QuizOption(
            koText: '안/밖/발등을 상황별 혼합',
            enText: 'Mix inside/outside/laces by context'),
        wrongA: _QuizOption(koText: '한 부위만 고정', enText: 'Use only one surface'),
        wrongB: _QuizOption(koText: '발끝만 사용', enText: 'Use only toe'),
        koExplain: '접촉 부위 다양성이 궤적 선택폭을 넓힙니다.',
        enExplain: 'Surface variety expands trajectory options.'),
    _QuizConcept(
        id: 'd09',
        koPrompt: '압박 2명일 때 현실적인 선택은?',
        enPrompt: 'what is realistic choice vs two pressers?',
        correct: _QuizOption(
            koText: '짧게 벗기고 패스 연결', enText: 'Escape briefly and link pass'),
        wrongA: _QuizOption(
            koText: '두 명 모두 개인기로 돌파', enText: 'Beat both with solo move'),
        wrongB:
            _QuizOption(koText: '멈춰서 반칙 유도만', enText: 'Stop only to draw foul'),
        koExplain: '2인 압박에서는 빠른 연결이 효율적입니다.',
        enExplain: 'Quick link play is efficient against double pressure.'),
    _QuizConcept(
        id: 'd10',
        koPrompt: '드리블 성공률을 높이는 훈련법은?',
        enPrompt: 'what training improves dribble success?',
        correct: _QuizOption(
            koText: '속도 변화 포함 반복', enText: 'Repetition with speed variation'),
        wrongA:
            _QuizOption(koText: '저속만 반복', enText: 'Only low-speed repetition'),
        wrongB: _QuizOption(koText: '폼만 확인', enText: 'Check form only'),
        koExplain: '실전은 속도 변화가 핵심이므로 훈련에도 포함해야 합니다.',
        enExplain: 'Game dribbling needs speed variation in training.'),
  ],
  _QuizType.control: <_QuizConcept>[
    _QuizConcept(
        id: 'c01',
        koPrompt: '퍼스트 터치의 목표는?',
        enPrompt: 'what is goal of first touch?',
        correct: _QuizOption(
            koText: '다음 동작 가능한 위치 만들기', enText: 'Set up the next action'),
        wrongA: _QuizOption(koText: '무조건 정지', enText: 'Always dead stop'),
        wrongB: _QuizOption(koText: '강하게 튕기기', enText: 'Bounce it hard away'),
        koExplain: '퍼스트 터치는 다음 플레이를 위한 준비 동작입니다.',
        enExplain: 'First touch is preparation for next play.'),
    _QuizConcept(
        id: 'c02',
        koPrompt: '압박 속 볼 보호 기본은?',
        enPrompt: 'what is basic ball protection under pressure?',
        correct: _QuizOption(
            koText: '몸-볼-수비 순서 유지', enText: 'Keep body-ball-defender order'),
        wrongA: _QuizOption(koText: '볼을 먼저 멀리 둠', enText: 'Put ball far first'),
        wrongB: _QuizOption(koText: '정면 대치만', enText: 'Face up directly only'),
        koExplain: '몸을 먼저 두면 공 소유를 지키기 쉽습니다.',
        enExplain: 'Body-first positioning protects possession.'),
    _QuizConcept(
        id: 'c03',
        koPrompt: '먼 발 컨트롤 장점은?',
        enPrompt: 'what is advantage of far-foot control?',
        correct: _QuizOption(
            koText: '수비와 공 사이에 몸 배치', enText: 'Body between defender and ball'),
        wrongA: _QuizOption(koText: '더 강한 트래핑', enText: 'Stronger trap only'),
        wrongB: _QuizOption(koText: '무조건 빠른 턴', enText: 'Always faster turn'),
        koExplain: '먼 발 컨트롤은 차단 가능성을 줄입니다.',
        enExplain: 'Far-foot control reduces interception risk.'),
    _QuizConcept(
        id: 'c04',
        koPrompt: '트래핑 소음을 줄여야 하는 이유는?',
        enPrompt: 'why reduce heavy trap sound?',
        correct: _QuizOption(
            koText: '반동 감소로 다음 동작이 쉬움',
            enText: 'Less rebound, easier next move'),
        wrongA: _QuizOption(koText: '속도만 빠르게', enText: 'Only to be faster'),
        wrongB:
            _QuizOption(koText: '폼이 좋아 보여서', enText: 'Only for cleaner form'),
        koExplain: '완충 컨트롤이 곧 다음 플레이 품질입니다.',
        enExplain: 'Cushion control improves next-play quality.'),
    _QuizConcept(
        id: 'c05',
        koPrompt: '열린 자세로 받을 때 좋은 점은?',
        enPrompt: 'benefit of receiving with open body?',
        correct: _QuizOption(
            koText: '전/후/측면 선택지 확보', enText: 'Keep forward/back/side options'),
        wrongA: _QuizOption(
            koText: '턴 없이 보호만 가능', enText: 'Only shielding without turn'),
        wrongB: _QuizOption(koText: '속도 감소', enText: 'Reduce speed only'),
        koExplain: '열린 자세가 의사결정 속도를 높입니다.',
        enExplain: 'Open shape speeds decision making.'),
    _QuizConcept(
        id: 'c06',
        koPrompt: '컨트롤 후 시선 우선순위는?',
        enPrompt: 'what is first visual priority after control?',
        correct: _QuizOption(
            koText: '가장 가까운 압박 위치', enText: 'Nearest pressure location'),
        wrongA: _QuizOption(koText: '볼 궤적만 보기', enText: 'Watch ball path only'),
        wrongB: _QuizOption(koText: '벤치 보기', enText: 'Look at bench'),
        koExplain: '압박 확인이 다음 터치 방향을 결정합니다.',
        enExplain: 'Pressure read defines next touch direction.'),
    _QuizConcept(
        id: 'c07',
        koPrompt: '약발 컨트롤 훈련의 목적은?',
        enPrompt: 'purpose of weak-foot control drills?',
        correct: _QuizOption(
            koText: '압박 상황 선택지 확대', enText: 'Expand options under pressure'),
        wrongA: _QuizOption(koText: '시간 단축', enText: 'Save training time'),
        wrongB: _QuizOption(koText: '강발 휴식', enText: 'Rest strong foot'),
        koExplain: '양발 컨트롤이 전개 속도를 높입니다.',
        enExplain: 'Two-foot control improves buildup speed.'),
    _QuizConcept(
        id: 'c08',
        koPrompt: '컨트롤 실패(긴 터치) 시 대처는?',
        enPrompt: 'response to heavy touch failure?',
        correct: _QuizOption(
            koText: '몸 먼저 넣어 재확보', enText: 'Insert body first and recover'),
        wrongA: _QuizOption(koText: '멈추고 기다림', enText: 'Stop and wait'),
        wrongB: _QuizOption(koText: '시선 회피', enText: 'Look away'),
        koExplain: '즉시 신체 개입이 실점/턴오버를 줄입니다.',
        enExplain: 'Immediate body intervention reduces turnovers.'),
    _QuizConcept(
        id: 'c09',
        koPrompt: '받을 때 발 간격의 기준은?',
        enPrompt: 'what foot spacing is preferred on receive?',
        correct: _QuizOption(
            koText: '어깨 너비 기반 균형 유지', enText: 'Shoulder-width for balance'),
        wrongA: _QuizOption(koText: '두 발 붙임', enText: 'Feet glued together'),
        wrongB: _QuizOption(koText: '과하게 넓힘', enText: 'Overly wide stance'),
        koExplain: '적절한 간격이 회전과 안정성을 동시에 확보합니다.',
        enExplain: 'Proper spacing secures both turnability and balance.'),
    _QuizConcept(
        id: 'c10',
        koPrompt: '컨트롤 후 2터치 연결의 장점은?',
        enPrompt: 'benefit of controlled two-touch link?',
        correct: _QuizOption(
            koText: '안정성과 템포 균형', enText: 'Balance of control and tempo'),
        wrongA: _QuizOption(
            koText: '항상 원터치보다 빠름', enText: 'Always faster than one-touch'),
        wrongB: _QuizOption(koText: '판단 불필요', enText: 'No decision needed'),
        koExplain: '2터치는 안정성을 주면서 템포를 크게 해치지 않습니다.',
        enExplain: 'Two-touch adds control without major tempo loss.'),
  ],
  _QuizType.scan: <_QuizConcept>[
    _QuizConcept(
        id: 's01',
        koPrompt: '기본 스캔 타이밍으로 맞는 것은?',
        enPrompt: 'which is correct basic scan timing?',
        correct: _QuizOption(
            koText: '받기 전-순간-직후 3회', enText: 'Before-during-after receive'),
        wrongA:
            _QuizOption(koText: '받은 후 1회만', enText: 'Only once after receive'),
        wrongB: _QuizOption(koText: '상대 없을 때만', enText: 'Only when unpressed'),
        koExplain: '3단계 스캔이 정보 누락을 줄입니다.',
        enExplain: 'Three-phase scan reduces missed information.'),
    _QuizConcept(
        id: 's02',
        koPrompt: '스캔의 첫 대상은?',
        enPrompt: 'what is first scan target?',
        correct: _QuizOption(koText: '가장 가까운 압박자', enText: 'Nearest presser'),
        wrongA: _QuizOption(koText: '관중석', enText: 'Spectator stand'),
        wrongB: _QuizOption(koText: '볼 표면', enText: 'Ball surface only'),
        koExplain: '압박자 확인이 우선입니다.',
        enExplain: 'Pressing threat check comes first.'),
    _QuizConcept(
        id: 's03',
        koPrompt: '패스 전 스캔 목적은?',
        enPrompt: 'purpose of scan before pass?',
        correct: _QuizOption(
            koText: '패스 각/차단 위험 확인',
            enText: 'Check lane and interception risk'),
        wrongA: _QuizOption(koText: '자세만 확인', enText: 'Only check posture'),
        wrongB: _QuizOption(koText: '속도만 확인', enText: 'Only check speed'),
        koExplain: '각도와 위험 판단이 패스 성공률을 높입니다.',
        enExplain: 'Lane-risk read boosts pass success.'),
    _QuizConcept(
        id: 's04',
        koPrompt: '스캔 시 고개 움직임 원칙은?',
        enPrompt: 'head-movement principle while scanning?',
        correct: _QuizOption(
            koText: '짧고 빠르게 반복', enText: 'Short and frequent checks'),
        wrongA: _QuizOption(koText: '한 번 길게 보기', enText: 'One long look'),
        wrongB: _QuizOption(koText: '고개 고정', enText: 'Keep head fixed'),
        koExplain: '짧은 스캔이 볼 컨트롤과 정보 수집을 동시에 가능하게 합니다.',
        enExplain: 'Short scans balance control and information intake.'),
    _QuizConcept(
        id: 's05',
        koPrompt: '스캔과 첫 터치의 관계는?',
        enPrompt: 'relationship of scan and first touch?',
        correct: _QuizOption(
            koText: '스캔이 첫 터치 방향을 결정',
            enText: 'Scan determines first-touch direction'),
        wrongA: _QuizOption(koText: '무관하다', enText: 'They are unrelated'),
        wrongB: _QuizOption(
            koText: '첫 터치 후 스캔만 중요', enText: 'Only post-touch scan matters'),
        koExplain: '선행 스캔 없이는 좋은 첫 터치가 어렵습니다.',
        enExplain: 'Without pre-scan, quality first touch is difficult.'),
    _QuizConcept(
        id: 's06',
        koPrompt: '패스 후 재스캔 이유는?',
        enPrompt: 'why rescan after passing?',
        correct: _QuizOption(
            koText: '다음 지원 위치 즉시 선택',
            enText: 'Choose next support position quickly'),
        wrongA:
            _QuizOption(koText: '방금 패스만 감상', enText: 'Watch your pass only'),
        wrongB:
            _QuizOption(koText: '멈춰서 지시만', enText: 'Stop and only instruct'),
        koExplain: '패스 후 재스캔이 연계 속도를 높입니다.',
        enExplain: 'Post-pass rescan speeds up combinations.'),
    _QuizConcept(
        id: 's07',
        koPrompt: '역습 상황 스캔 우선순위는?',
        enPrompt: 'scan priority in transition attack?',
        correct: _QuizOption(
            koText: '수비 라인과 전진 런', enText: 'Defensive line and forward runs'),
        wrongA:
            _QuizOption(koText: '가장 먼 동료만', enText: 'Only farthest teammate'),
        wrongB: _QuizOption(koText: '공만 보기', enText: 'Ball only'),
        koExplain: '라인과 런 정보를 동시에 보면 선택이 빨라집니다.',
        enExplain: 'Line+run reading accelerates transition choices.'),
    _QuizConcept(
        id: 's08',
        koPrompt: '좁은 공간에서 스캔 빈도는?',
        enPrompt: 'scan frequency in tight space?',
        correct: _QuizOption(
            koText: '더 짧고 더 자주', enText: 'Shorter and more frequent'),
        wrongA: _QuizOption(koText: '덜 자주', enText: 'Less frequent'),
        wrongB: _QuizOption(koText: '없어도 됨', enText: 'Can skip scanning'),
        koExplain: '공간이 좁을수록 정보 갱신 주기가 짧아야 합니다.',
        enExplain: 'Tighter space needs faster information refresh.'),
    _QuizConcept(
        id: 's09',
        koPrompt: '스캔에서 놓치면 위험한 정보는?',
        enPrompt: 'critical info that must not be missed while scanning?',
        correct:
            _QuizOption(koText: '블라인드 사이드 압박', enText: 'Blind-side pressure'),
        wrongA: _QuizOption(koText: '유니폼 색상', enText: 'Jersey color'),
        wrongB: _QuizOption(koText: '관중 반응', enText: 'Crowd reaction'),
        koExplain: '블라인드 압박을 놓치면 즉시 턴오버 위험이 큽니다.',
        enExplain: 'Missing blind pressure causes immediate turnover risk.'),
    _QuizConcept(
        id: 's10',
        koPrompt: '훈련에서 스캔을 습관화하는 방법은?',
        enPrompt: 'how to build scanning habit in training?',
        correct: _QuizOption(
            koText: '받기 전 양쪽 호출 루틴',
            enText: 'Pre-receive left-right call routine'),
        wrongA: _QuizOption(koText: '정답만 외우기', enText: 'Memorize answers only'),
        wrongB:
            _QuizOption(koText: '컨디션 좋을 때만', enText: 'Only when feeling good'),
        koExplain: '루틴화가 경기 중 자동 스캔을 만듭니다.',
        enExplain: 'Routines create automatic in-game scanning.'),
  ],
};
