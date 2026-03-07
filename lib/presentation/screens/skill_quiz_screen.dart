import 'package:flutter/material.dart';

class SkillQuizScreen extends StatefulWidget {
  const SkillQuizScreen({super.key});

  @override
  State<SkillQuizScreen> createState() => _SkillQuizScreenState();
}

class _SkillQuizScreenState extends State<SkillQuizScreen> {
  final List<_QuizQuestion> _questions = _quizQuestions;
  int _index = 0;
  int _score = 0;
  int? _selectedIndex;
  bool _answered = false;

  bool get _isFinished => _index >= _questions.length;

  void _selectAnswer(int choice) {
    if (_answered || _isFinished) return;
    final question = _questions[_index];
    setState(() {
      _selectedIndex = choice;
      _answered = true;
      if (choice == question.correctIndex) {
        _score++;
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

  void _restart() {
    setState(() {
      _index = 0;
      _score = 0;
      _selectedIndex = null;
      _answered = false;
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
        Text(
          isKo ? '진행 $progress' : 'Progress $progress',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
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
                  isKo ? '퀴즈 결과' : 'Quiz Result',
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
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.replay),
                  label: Text(isKo ? '다시 풀기' : 'Retry'),
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
  final String koQuestion;
  final String enQuestion;
  final List<_QuizOption> options;
  final int correctIndex;
  final String koExplain;
  final String enExplain;

  const _QuizQuestion({
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

const List<_QuizQuestion> _quizQuestions = <_QuizQuestion>[
  _QuizQuestion(
    koQuestion: '패스를 받기 전에 먼저 해야 하는 가장 좋은 습관은?',
    enQuestion: 'What is the best habit before receiving a pass?',
    options: [
      _QuizOption(koText: '발만 본다', enText: 'Look only at the ball'),
      _QuizOption(koText: '주변을 스캔한다', enText: 'Scan surroundings'),
      _QuizOption(koText: '등지고 멈춘다', enText: 'Stop with back turned'),
    ],
    correctIndex: 1,
    koExplain: '스캔을 하면 압박 방향과 다음 선택지를 미리 파악할 수 있습니다.',
    enExplain:
        'Scanning helps you read pressure and identify your next option early.',
  ),
  _QuizQuestion(
    koQuestion: '짧은 패스 정확도를 높이려면 어떤 부위를 쓰는 것이 기본일까?',
    enQuestion: 'Which foot surface is basic for accurate short passing?',
    options: [
      _QuizOption(koText: '발 안쪽', enText: 'Inside of the foot'),
      _QuizOption(koText: '발끝', enText: 'Toe'),
      _QuizOption(koText: '발뒤꿈치', enText: 'Heel'),
    ],
    correctIndex: 0,
    koExplain: '발 안쪽은 접촉 면적이 넓어 방향과 힘 조절이 안정적입니다.',
    enExplain:
        'The inside provides a larger contact surface for stable direction and power.',
  ),
  _QuizQuestion(
    koQuestion: '드리블 중 수비를 이기기 위해 가장 먼저 신경 써야 할 것은?',
    enQuestion:
        'What should you focus on first to beat a defender while dribbling?',
    options: [
      _QuizOption(koText: '시선과 템포 변화', enText: 'Eye and tempo change'),
      _QuizOption(koText: '항상 큰 터치', enText: 'Always big touches'),
      _QuizOption(koText: '고개 숙이고 질주', enText: 'Sprint with head down'),
    ],
    correctIndex: 0,
    koExplain: '시선 유도와 템포 변화가 수비의 중심 이동을 만들어 냅니다.',
    enExplain:
        'Eye deception and tempo shifts force defenders to move off balance.',
  ),
  _QuizQuestion(
    koQuestion: '좋은 퍼스트 터치의 목적은?',
    enQuestion: 'What is the purpose of a good first touch?',
    options: [
      _QuizOption(koText: '공을 멈추기만 한다', enText: 'Only stop the ball'),
      _QuizOption(koText: '다음 동작으로 연결한다', enText: 'Set up the next action'),
      _QuizOption(koText: '강하게 차낸다', enText: 'Kick it hard away'),
    ],
    correctIndex: 1,
    koExplain: '퍼스트 터치는 패스, 슛, 드리블로 자연스럽게 이어져야 합니다.',
    enExplain:
        'Your first touch should prepare a smooth next action: pass, shot, or dribble.',
  ),
  _QuizQuestion(
    koQuestion: '압박이 강할 때 안전한 선택으로 가장 적절한 것은?',
    enQuestion: 'Under strong pressure, what is a safer option?',
    options: [
      _QuizOption(koText: '무리한 턴 시도', enText: 'Force a risky turn'),
      _QuizOption(koText: '원터치 리턴 패스', enText: 'One-touch return pass'),
      _QuizOption(koText: '볼 오래 끈다', enText: 'Hold the ball too long'),
    ],
    correctIndex: 1,
    koExplain: '간결한 리턴 패스는 공 소유를 지키고 팀 템포를 유지해 줍니다.',
    enExplain: 'A quick return pass protects possession and keeps team rhythm.',
  ),
];
