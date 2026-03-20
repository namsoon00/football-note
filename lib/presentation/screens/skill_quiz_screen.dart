import 'package:flutter/material.dart';

import '../../domain/repositories/option_repository.dart';
import '../models/training_method_layout.dart';
import '../widgets/training_board_sketch.dart';

class SkillQuizScreen extends StatefulWidget {
  final OptionRepository optionRepository;

  static const String completionKey = 'skill_quiz_completed_at';
  static const String sessionKey = 'skill_quiz_session_v1';
  static const String pendingWrongQuestionsKey = 'skill_quiz_pending_wrong_v1';
  static const String pendingWrongScheduleKey =
      'skill_quiz_pending_wrong_schedule_v2';
  static const String metricsKey = 'skill_quiz_metrics_v1';
  static const String recentPerformanceKey = 'skill_quiz_recent_performance_v1';
  static const String dailyQuestionsKey = 'skill_quiz_daily_questions_v2';
  static const String dailyQuestionsDayKey =
      'skill_quiz_daily_questions_day_v2';
  static const String clearedSetsKey = 'skill_quiz_cleared_sets_v1';

  const SkillQuizScreen({super.key, required this.optionRepository});

  static SkillQuizResumeSummary loadResumeSummary(
    OptionRepository optionRepository,
  ) {
    final completedAtRaw = optionRepository.getValue<String>(completionKey);
    final completedAt =
        completedAtRaw == null ? null : DateTime.tryParse(completedAtRaw);
    final now = DateTime.now();
    final completedToday = completedAt != null &&
        completedAt.year == now.year &&
        completedAt.month == now.month &&
        completedAt.day == now.day;

    return SkillQuizResumeSummary(
      hasActiveSession: false,
      reviewMode: false,
      currentIndex: 0,
      totalQuestions: 1,
      pendingWrongCount: 0,
      completedToday: completedToday,
    );
  }

  @override
  State<SkillQuizScreen> createState() => _SkillQuizScreenState();
}

class _SkillQuizScreenState extends State<SkillQuizScreen> {
  late final _SimpleQuizQuestion _question;

  int? _selectedIndex;
  bool _answered = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _question = _sampleBoardQuestion();
  }

  void _selectAnswer(int index) {
    if (_answered || _finished) return;
    setState(() {
      _selectedIndex = index;
      _answered = true;
    });
  }

  Future<void> _finish() async {
    if (!_answered || _finished) return;
    setState(() => _finished = true);
    await widget.optionRepository.setValue(
      SkillQuizScreen.completionKey,
      DateTime.now().toIso8601String(),
    );
  }

  void _restart() {
    setState(() {
      _selectedIndex = null;
      _answered = false;
      _finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return Scaffold(
      appBar: AppBar(
        title: Text(isKo ? '실전 퀴즈' : 'Match Quiz'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: _finished ? _buildResult(isKo) : _buildQuestion(isKo),
        ),
      ),
    );
  }

  Widget _buildQuestion(bool isKo) {
    final correct = _selectedIndex == _question.correctIndex;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isKo ? '샘플 보드 문제 (1/1)' : 'Sample board quiz (1/1)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          isKo
              ? '위치만 보고 가장 좋은 선택 1개를 고르세요.'
              : 'Read positions and pick the best option.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        _SimpleBoardCard(
            page: _question.boardPage, caption: _question.caption(isKo)),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              _question.question(isKo),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ..._question.options.asMap().entries.map((entry) {
          final idx = entry.key;
          final option = entry.value;
          final selected = _selectedIndex == idx;
          final isCorrect = idx == _question.correctIndex;

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
              onPressed: () => _selectAnswer(idx),
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
                  Expanded(child: Text(option.label(isKo))),
                  if (_answered && isCorrect)
                    const Icon(Icons.check_circle, color: Color(0xFF0FA968)),
                  if (_answered && selected && !isCorrect)
                    const Icon(Icons.cancel, color: Color(0xFFEB5757)),
                ],
              ),
            ),
          );
        }),
        if (_answered) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Text(
              correct
                  ? _question.explain(isKo)
                  : (isKo
                      ? '틀렸어요. 정답은 "${_question.options[_question.correctIndex].label(true)}" 입니다.\n\n${_question.explain(true)}'
                      : 'Not quite. Correct answer: "${_question.options[_question.correctIndex].label(false)}".\n\n${_question.explain(false)}'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
        const Spacer(),
        FilledButton.icon(
          onPressed: _answered ? _finish : null,
          icon: const Icon(Icons.check_circle_outline),
          label: Text(isKo ? '완료' : 'Finish'),
        ),
      ],
    );
  }

  Widget _buildResult(bool isKo) {
    final correct = _selectedIndex == _question.correctIndex;
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
                  isKo ? '퀴즈 완료' : 'Quiz Completed',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  correct
                      ? (isKo ? '정답! 1 / 1' : 'Correct! 1 / 1')
                      : (isKo ? '오답. 0 / 1' : 'Wrong. 0 / 1'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.refresh),
                  label: Text(isKo ? '다시 풀기' : 'Retry'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(isKo ? '뒤로가기' : 'Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SkillQuizResumeSummary {
  final bool hasActiveSession;
  final bool reviewMode;
  final int currentIndex;
  final int totalQuestions;
  final int pendingWrongCount;
  final bool completedToday;

  const SkillQuizResumeSummary({
    required this.hasActiveSession,
    required this.reviewMode,
    required this.currentIndex,
    required this.totalQuestions,
    required this.pendingWrongCount,
    this.completedToday = false,
  });
}

class _SimpleBoardCard extends StatelessWidget {
  final TrainingMethodPage page;
  final String caption;

  const _SimpleBoardCard({required this.page, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            caption,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 320,
              width: double.infinity,
              child: TrainingBoardSketch(
                page: page,
                borderRadius: 14,
                showStrokes: true,
                showPlayerPath: true,
                showBallPath: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleQuizQuestion {
  final String koQuestion;
  final String enQuestion;
  final List<_SimpleQuizOption> options;
  final int correctIndex;
  final String koExplain;
  final String enExplain;
  final String koCaption;
  final String enCaption;
  final TrainingMethodPage boardPage;

  const _SimpleQuizQuestion({
    required this.koQuestion,
    required this.enQuestion,
    required this.options,
    required this.correctIndex,
    required this.koExplain,
    required this.enExplain,
    required this.koCaption,
    required this.enCaption,
    required this.boardPage,
  });

  String question(bool isKo) => isKo ? koQuestion : enQuestion;
  String explain(bool isKo) => isKo ? koExplain : enExplain;
  String caption(bool isKo) => isKo ? koCaption : enCaption;
}

class _SimpleQuizOption {
  final String koText;
  final String enText;

  const _SimpleQuizOption({required this.koText, required this.enText});

  String label(bool isKo) => isKo ? koText : enText;
}

_SimpleQuizQuestion _sampleBoardQuestion() {
  const page = TrainingMethodPage(
    name: 'sample_board_quiz',
    items: [
      TrainingMethodItem(
        type: 'player',
        x: 0.20,
        y: 0.72,
        size: 34,
        colorValue: 0xFFB3E5FC,
      ),
      TrainingMethodItem(
        type: 'player',
        x: 0.42,
        y: 0.60,
        size: 34,
        colorValue: 0xFFB3E5FC,
      ),
      TrainingMethodItem(
        type: 'player',
        x: 0.68,
        y: 0.40,
        size: 34,
        colorValue: 0xFFB3E5FC,
      ),
      TrainingMethodItem(
        type: 'player',
        x: 0.35,
        y: 0.52,
        size: 34,
        colorValue: 0xFFFFCCBC,
      ),
      TrainingMethodItem(
        type: 'player',
        x: 0.57,
        y: 0.49,
        size: 34,
        colorValue: 0xFFFFCCBC,
      ),
      TrainingMethodItem(
        type: 'ball',
        x: 0.20,
        y: 0.72,
        size: 28,
        colorValue: 0xFFFFF8E1,
      ),
    ],
    strokes: [
      TrainingMethodStroke(
        points: [
          TrainingMethodPoint(x: 0.20, y: 0.72),
          TrainingMethodPoint(x: 0.42, y: 0.60),
          TrainingMethodPoint(x: 0.68, y: 0.40),
        ],
        colorValue: 0xFF1E88E5,
        width: 3.2,
      ),
    ],
    playerPath: [
      TrainingMethodPoint(x: 0.42, y: 0.60),
      TrainingMethodPoint(x: 0.56, y: 0.50),
      TrainingMethodPoint(x: 0.68, y: 0.40),
    ],
    ballPath: [
      TrainingMethodPoint(x: 0.20, y: 0.72),
      TrainingMethodPoint(x: 0.42, y: 0.60),
    ],
  );

  return const _SimpleQuizQuestion(
    koQuestion: '이 장면에서 가장 좋은 첫 선택은?',
    enQuestion: 'What is the best first choice in this scene?',
    options: [
      _SimpleQuizOption(
        koText: '가까운 선수에게 짧게 연결 후 전진',
        enText: 'Play short to nearest teammate, then progress',
      ),
      _SimpleQuizOption(
        koText: '상대 두 명 사이로 바로 무리한 롱패스',
        enText: 'Force a long pass between two defenders',
      ),
      _SimpleQuizOption(
        koText: '볼을 멈추고 뒤로만 드리블',
        enText: 'Stop the ball and dribble backward only',
      ),
    ],
    correctIndex: 0,
    koExplain: '가장 안전한 첫 선택은 가까운 지원 선수에게 연결해 압박을 벗어나고, 다음 전진 패스를 준비하는 것입니다.',
    enExplain:
        'The safest first action is connecting to nearby support to escape pressure and set up the next forward pass.',
    koCaption: '우리 팀(파랑) 위치와 패스 길',
    enCaption: 'Our team (blue) positions and pass lane',
    boardPage: page,
  );
}
