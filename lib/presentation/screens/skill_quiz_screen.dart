import 'dart:convert';

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
    final session = _QuizSessionState.load(optionRepository);
    final now = DateTime.now();
    final completedToday = completedAt != null &&
        completedAt.year == now.year &&
        completedAt.month == now.month &&
        completedAt.day == now.day;

    return SkillQuizResumeSummary(
      hasActiveSession: session != null,
      reviewMode: session?.reviewMode ?? false,
      currentIndex: session?.currentIndex ?? 0,
      totalQuestions: session?.questions.length ?? _boardQuizQuestions.length,
      pendingWrongCount: 0,
      completedToday: completedToday,
    );
  }

  @override
  State<SkillQuizScreen> createState() => _SkillQuizScreenState();
}

class _SkillQuizScreenState extends State<SkillQuizScreen> {
  late final List<_SimpleQuizQuestion> _questions;
  int _currentIndex = 0;
  int? _selectedIndex;
  bool _answered = false;
  bool _finished = false;
  int _score = 0;
  bool _selectionOpen = false;

  _SimpleQuizQuestion get _question => _questions[_currentIndex];

  @override
  void initState() {
    super.initState();
    final savedSession = _QuizSessionState.load(widget.optionRepository);
    if (savedSession != null) {
      _questions = savedSession.questions;
      _currentIndex = savedSession.currentIndex.clamp(0, _questions.length - 1);
      _selectedIndex = savedSession.selectedIndex;
      _answered = savedSession.answered;
      _score = savedSession.score.clamp(0, _questions.length);
      _selectionOpen = false;
    } else {
      _questions = _boardQuizQuestions;
      _selectionOpen = true;
    }
  }

  Future<void> _persistSession() {
    return widget.optionRepository.setValue(
      SkillQuizScreen.sessionKey,
      jsonEncode(
        _QuizSessionState(
          reviewMode: false,
          currentIndex: _currentIndex,
          score: _score,
          selectedIndex: _selectedIndex,
          answered: _answered,
          questions: _questions,
        ).toMap(),
      ),
    );
  }

  void _openBoardQuiz() {
    setState(() => _selectionOpen = false);
    _persistSession();
  }

  void _selectAnswer(int index) {
    if (_answered || _finished || _selectionOpen) return;
    final correct = index == _question.correctIndex;
    setState(() {
      _selectedIndex = index;
      _answered = true;
      if (correct) {
        _score += 1;
      }
    });
    _persistSession();
  }

  Future<void> _advance() async {
    if (!_answered || _finished) return;
    if (_currentIndex >= _questions.length - 1) {
      await _finish();
      return;
    }
    setState(() {
      _currentIndex += 1;
      _selectedIndex = null;
      _answered = false;
    });
    await _persistSession();
  }

  Future<void> _finish() async {
    if (!_answered || _finished) return;
    setState(() => _finished = true);
    await widget.optionRepository.setValue(
      SkillQuizScreen.completionKey,
      DateTime.now().toIso8601String(),
    );
    await widget.optionRepository.setValue(SkillQuizScreen.sessionKey, null);
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _selectedIndex = null;
      _answered = false;
      _finished = false;
      _score = 0;
      _selectionOpen = true;
    });
    widget.optionRepository.setValue(SkillQuizScreen.sessionKey, null);
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return Scaffold(
      appBar: AppBar(
        title: Text(isKo ? '보드 퀴즈' : 'Board Quiz'),
        actions: [
          PopupMenuButton<String>(
            tooltip: isKo ? '퀴즈 세트 메뉴' : 'Quiz set menu',
            onSelected: (value) {
              if (value == 'types') {
                setState(() => _selectionOpen = true);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'types',
                child: Text(isKo ? '타입별 퀴즈 선택' : 'Choose quiz type'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: _finished
              ? _buildResult(isKo)
              : _selectionOpen
                  ? _buildSelection(isKo)
                  : _buildQuestion(isKo),
        ),
      ),
    );
  }

  Widget _buildSelection(bool isKo) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isKo ? '보드 문제풀기' : 'Board Problem Solving',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  isKo
                      ? '보드 세트 ${_boardQuizQuestions.length}개'
                      : '${_boardQuizQuestions.length} board scenarios ready',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  isKo
                      ? '타입별 퀴즈 선택에서 보드를 고르면 위치와 움직임만 보고 가장 좋은 선택을 고를 수 있어요.'
                      : 'Choose board mode to read positions, movement, and the best next action.',
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: _openBoardQuiz,
                  icon: const Icon(Icons.view_quilt_outlined),
                  label: Text(isKo ? '보드' : 'Board'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(bool isKo) {
    final correct = _selectedIndex == _question.correctIndex;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isKo ? '보드 문제풀기' : 'Board Problem Solving',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  isKo
                      ? '보드 세트 ${_questions.length}개'
                      : '${_questions.length} board scenarios',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  isKo
                      ? '보드 퀴즈 ${_currentIndex + 1}/${_questions.length}'
                      : 'Board Quiz ${_currentIndex + 1}/${_questions.length}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  isKo ? '위치 먼저 보기' : 'Read the picture first',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isKo ? '코치 설명' : 'Coach Hint',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isKo
                              ? '코치가 먼저 말해주는 힌트'
                              : 'Coach gives the first hint',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _question.title(isKo),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(_question.movementCaption(isKo)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _SimpleBoardCard(
                  page: _question.boardPage,
                  caption: isKo ? '코치 보드' : 'Coach Board',
                ),
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
                          Expanded(child: Text(option.label(isKo))),
                          if (_answered && isCorrect)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF0FA968),
                            ),
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
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _answered ? _advance : null,
          icon: Icon(
            _currentIndex == _questions.length - 1
                ? Icons.check_circle_outline
                : Icons.arrow_forward,
          ),
          label: Text(
            _currentIndex == _questions.length - 1
                ? (isKo ? '완료' : 'Finish')
                : (isKo ? '다음 문제' : 'Next'),
          ),
        ),
      ],
    );
  }

  Widget _buildResult(bool isKo) {
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Text(
                  isKo
                      ? '정답 $_score / ${_questions.length}'
                      : 'Score $_score / ${_questions.length}',
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
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 220,
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
  final String id;
  final String koQuestion;
  final String enQuestion;
  final List<_SimpleQuizOption> options;
  final int correctIndex;
  final String koExplain;
  final String enExplain;
  final String koTitle;
  final String enTitle;
  final String koMovementCaption;
  final String enMovementCaption;
  final TrainingMethodPage boardPage;

  const _SimpleQuizQuestion({
    required this.id,
    required this.koQuestion,
    required this.enQuestion,
    required this.options,
    required this.correctIndex,
    required this.koExplain,
    required this.enExplain,
    required this.koTitle,
    required this.enTitle,
    required this.koMovementCaption,
    required this.enMovementCaption,
    required this.boardPage,
  });

  factory _SimpleQuizQuestion.fromMap(Map<String, dynamic> map) {
    final scenario = map['scenario'] is Map<String, dynamic>
        ? map['scenario'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return _SimpleQuizQuestion(
      id: (map['id'] as String?) ?? 'board_quiz',
      koQuestion: (map['koQuestion'] as String?) ?? '',
      enQuestion: (map['enQuestion'] as String?) ?? '',
      options: (map['options'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (option) =>
                _SimpleQuizOption.fromMap(option.cast<String, dynamic>()),
          )
          .toList(growable: false),
      correctIndex: (map['correctIndex'] as num?)?.toInt() ?? 0,
      koExplain: (map['koExplain'] as String?) ?? '',
      enExplain: (map['enExplain'] as String?) ?? '',
      koTitle: (scenario['koTitle'] as String?) ?? '',
      enTitle: (scenario['enTitle'] as String?) ?? '',
      koMovementCaption: (scenario['koMovementCaption'] as String?) ?? '',
      enMovementCaption: (scenario['enMovementCaption'] as String?) ?? '',
      boardPage: TrainingMethodPage.fromMap(
        (scenario['boardPage'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'koQuestion': koQuestion,
        'enQuestion': enQuestion,
        'options':
            options.map((option) => option.toMap()).toList(growable: false),
        'correctIndex': correctIndex,
        'koExplain': koExplain,
        'enExplain': enExplain,
        'scenario': {
          'koTitle': koTitle,
          'enTitle': enTitle,
          'koMovementCaption': koMovementCaption,
          'enMovementCaption': enMovementCaption,
          'boardPage': boardPage.toMap(),
        },
      };

  String question(bool isKo) => isKo ? koQuestion : enQuestion;
  String explain(bool isKo) => isKo ? koExplain : enExplain;
  String title(bool isKo) => isKo ? koTitle : enTitle;
  String movementCaption(bool isKo) =>
      isKo ? koMovementCaption : enMovementCaption;
}

class _SimpleQuizOption {
  final String koText;
  final String enText;

  const _SimpleQuizOption({required this.koText, required this.enText});

  factory _SimpleQuizOption.fromMap(Map<String, dynamic> map) {
    return _SimpleQuizOption(
      koText: (map['koText'] as String?) ?? '',
      enText: (map['enText'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'koText': koText, 'enText': enText};

  String label(bool isKo) => isKo ? koText : enText;
}

class _QuizSessionState {
  final bool reviewMode;
  final int currentIndex;
  final int score;
  final int? selectedIndex;
  final bool answered;
  final List<_SimpleQuizQuestion> questions;

  const _QuizSessionState({
    required this.reviewMode,
    required this.currentIndex,
    required this.score,
    required this.selectedIndex,
    required this.answered,
    required this.questions,
  });

  factory _QuizSessionState.fromMap(Map<String, dynamic> map) {
    final rawQuestions = map['questions'] ?? map['dailyQuestions'];
    final parsedQuestions = rawQuestions is List
        ? rawQuestions
            .whereType<Map>()
            .map(
              (question) => _SimpleQuizQuestion.fromMap(
                question.cast<String, dynamic>(),
              ),
            )
            .where((question) => question.options.isNotEmpty)
            .toList(growable: false)
        : const <_SimpleQuizQuestion>[];
    return _QuizSessionState(
      reviewMode: map['reviewMode'] == true,
      currentIndex: (map['index'] as num?)?.toInt() ?? 0,
      score: (map['score'] as num?)?.toInt() ?? 0,
      selectedIndex: (map['selectedIndex'] as num?)?.toInt(),
      answered: map['answered'] == true,
      questions:
          parsedQuestions.isEmpty ? _boardQuizQuestions : parsedQuestions,
    );
  }

  static _QuizSessionState? load(OptionRepository optionRepository) {
    final raw = optionRepository.getValue<dynamic>(SkillQuizScreen.sessionKey);
    if (raw is! String || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return _QuizSessionState.fromMap(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Map<String, dynamic> toMap() => {
        'reviewMode': reviewMode,
        'index': currentIndex,
        'score': score,
        'selectedIndex': selectedIndex,
        'answered': answered,
        'questions': questions
            .map((question) => question.toMap())
            .toList(growable: false),
        'dailyQuestions': questions
            .map((question) => question.toMap())
            .toList(growable: false),
      };
}

const List<_ScenarioPattern> _scenarioPatterns = [
  _ScenarioPattern(
    id: 'half_space',
    koTitle: '중앙 압박이 오기 전, 오른쪽 앞 빈 공간이 열렸어요.',
    enTitle: 'Central pressure is closing, but the right half-space is open.',
    koMovement: '공을 가진 친구와 앞쪽 친구가 오른쪽 빈 공간으로 함께 움직일 준비를 하고 있어요.',
    enMovement:
        'The ball carrier and next runner are ready to break into the right half-space.',
    koCorrect: '오른쪽 앞 빈 공간으로 빠르게 패스',
    enCorrect: 'Quick forward pass into the right half-space',
    koWrong1: '공을 멈추고 상대가 오길 기다린다',
    enWrong1: 'Stop the ball and wait for central pressure',
    koWrong2: '멀리 있는 측면으로만 크게 보낸다',
    enWrong2: 'Force a long switch to the far wing',
    koExplain: '상대가 모이기 전에 오른쪽 앞 빈 공간을 바로 쓰는 선택이 가장 좋아요.',
    enExplain:
        'Before central pressure arrives, the open half-space is the best route.',
  ),
  _ScenarioPattern(
    id: 'third_man',
    koTitle: '첫 패스를 넣으면 3번째 선수가 전진할 수 있어요.',
    enTitle: 'A quick first pass opens the third-man run.',
    koMovement: '앞선 두 선수가 한 번에 받지 않고 이어주면 더 좋은 전진 각도가 나와요.',
    enMovement:
        'If the first two players connect quickly, the third runner gets the cleanest lane.',
    koCorrect: '가까운 선수에게 짧게 주고 다시 앞으로 받는다',
    enCorrect: 'Play short, then receive forward again',
    koWrong1: '첫 터치부터 혼자 오래 끈다',
    enWrong1: 'Hold the first touch for too long',
    koWrong2: '압박 안쪽으로 바로 드리블한다',
    enWrong2: 'Dribble directly into the pressure',
    koExplain: '짧은 연결로 상대를 끌고, 3번째 선수의 전진 루트를 여는 흐름이 가장 효율적이에요.',
    enExplain:
        'The short connection attracts pressure and creates the best third-man route.',
  ),
  _ScenarioPattern(
    id: 'switch',
    koTitle: '한쪽에 상대가 몰려 반대 전환이 준비됐어요.',
    enTitle: 'The defense has shifted, so the far-side switch is on.',
    koMovement: '가까운 쪽은 막혔지만 반대편 바깥 선수가 넓게 서 있어요.',
    enMovement:
        'The near side is crowded, but the weak-side player is staying wide.',
    koCorrect: '반대쪽 넓은 쪽으로 방향 전환 패스',
    enCorrect: 'Switch play toward the far-side width',
    koWrong1: '막힌 쪽으로 다시 무리하게 찌른다',
    enWrong1: 'Force another pass into the crowded side',
    koWrong2: '뒤로 돌려놓고 가만히 선다',
    enWrong2: 'Reset backward and stop moving',
    koExplain: '상대가 한쪽으로 몰린 순간 반대 전환이 가장 큰 공간을 만들어요.',
    enExplain:
        'When the defense collapses to one side, the switch creates the largest space.',
  ),
  _ScenarioPattern(
    id: 'wall_pass',
    koTitle: '수비 한 명을 등지고 원투패스 길이 생겼어요.',
    enTitle: 'A wall pass is available around the defender.',
    koMovement: '첫 패스를 짧게 넣고 바로 빈 옆으로 빠져나가면 수비를 벗어날 수 있어요.',
    enMovement:
        'A short set pass followed by an outside run breaks past the defender.',
    koCorrect: '짧게 주고 옆으로 빠져 원투패스를 만든다',
    enCorrect: 'Set it short and spin out for a wall pass',
    koWrong1: '수비 정면으로 계속 몰고 간다',
    enWrong1: 'Keep dribbling straight into the defender',
    koWrong2: '공을 발밑에 두고 멈춘다',
    enWrong2: 'Stop with the ball under your feet',
    koExplain: '등진 상황에서는 원투패스로 각도를 바꾸는 것이 가장 빠른 탈압박이에요.',
    enExplain:
        'In a back-to-goal situation, the wall pass changes the angle fastest.',
  ),
  _ScenarioPattern(
    id: 'cutback',
    koTitle: '측면 돌파 뒤 컷백 공간이 비어 있어요.',
    enTitle: 'After the wide break, the cutback zone is open.',
    koMovement: '골문 앞은 막혔지만 뒤따라오는 동료가 페널티 지점 근처로 들어와요.',
    enMovement:
        'The front post is crowded, but the trailing runner is arriving near the penalty spot.',
    koCorrect: '뒤에서 들어오는 동료에게 컷백한다',
    enCorrect: 'Cut the ball back to the trailing teammate',
    koWrong1: '각도 없는 곳에서 바로 슛한다',
    enWrong1: 'Shoot immediately from a poor angle',
    koWrong2: '라인 밖으로 더 끌고 간다',
    enWrong2: 'Carry the ball farther toward the end line',
    koExplain: '골문 앞이 막히면 컷백이 더 높은 확률의 마무리를 만들어줘요.',
    enExplain:
        'When the near goal line is blocked, the cutback gives the cleaner finish.',
  ),
];

final List<_SimpleQuizQuestion> _boardQuizQuestions =
    List<_SimpleQuizQuestion>.generate(
  30,
  _buildBoardQuestion,
  growable: false,
);

_SimpleQuizQuestion _buildBoardQuestion(int index) {
  final pattern = _scenarioPatterns[index % _scenarioPatterns.length];
  final lane = index % 3;
  final baseX = 0.16 + (lane * 0.04);
  final baseY = 0.30 + ((index ~/ 3) % 4) * 0.08;
  final runnerY = (baseY + 0.12).clamp(0.18, 0.74);
  final targetX = (0.68 + lane * 0.04).clamp(0.58, 0.84);
  final targetY = (runnerY - 0.08 + (lane * 0.03)).clamp(0.14, 0.82);
  final defenderX = (baseX + 0.18).clamp(0.28, 0.54);
  final highlightX = (targetX + 0.02).clamp(0.08, 0.92);
  final page = TrainingMethodPage(
    name: 'board_quiz_${index + 1}',
    items: [
      TrainingMethodItem(
        type: 'player',
        x: baseX,
        y: runnerY,
        size: 42,
        colorValue: 0xFFB3E5FC,
      ),
      TrainingMethodItem(
        type: 'player',
        x: (baseX + 0.18).clamp(0.08, 0.92),
        y: baseY,
        size: 42,
        colorValue: 0xFFB3E5FC,
      ),
      TrainingMethodItem(
        type: 'player',
        x: targetX,
        y: targetY,
        size: 42,
        colorValue: 0xFFB3E5FC,
      ),
      TrainingMethodItem(
        type: 'player',
        x: defenderX,
        y: (runnerY - 0.03).clamp(0.12, 0.88),
        size: 40,
        colorValue: 0xFFFFCCBC,
      ),
      TrainingMethodItem(
        type: 'player',
        x: (defenderX + 0.16).clamp(0.08, 0.92),
        y: (runnerY + 0.01).clamp(0.12, 0.88),
        size: 40,
        colorValue: 0xFFFFCCBC,
      ),
      TrainingMethodItem(
        type: 'player',
        x: (targetX - 0.12).clamp(0.08, 0.92),
        y: (targetY + 0.12).clamp(0.12, 0.88),
        size: 40,
        colorValue: 0xFFFFCCBC,
      ),
      TrainingMethodItem(
        type: 'ball',
        x: (baseX - 0.038).clamp(0.06, 0.9),
        y: (runnerY - 0.055).clamp(0.06, 0.9),
        size: 30,
        colorValue: 0xFFFFF8E1,
      ),
    ],
    strokes: [
      TrainingMethodStroke(
        points: [
          TrainingMethodPoint(
            x: highlightX,
            y: (targetY - 0.15).clamp(0.04, 0.9),
          ),
          TrainingMethodPoint(
            x: highlightX,
            y: (targetY + 0.15).clamp(0.1, 0.96),
          ),
        ],
        colorValue: 0x66FFD54F,
        width: 10,
      ),
    ],
    playerPath: [
      TrainingMethodPoint(x: (baseX + 0.18).clamp(0.08, 0.92), y: baseY),
      TrainingMethodPoint(
        x: ((baseX + targetX) / 2).clamp(0.08, 0.92),
        y: (baseY - 0.03).clamp(0.08, 0.92),
      ),
      TrainingMethodPoint(x: targetX, y: targetY),
    ],
    ballPath: [
      TrainingMethodPoint(x: baseX, y: runnerY),
      TrainingMethodPoint(
        x: ((baseX + targetX) / 2).clamp(0.08, 0.92),
        y: ((runnerY + targetY) / 2 - 0.08).clamp(0.06, 0.9),
      ),
      TrainingMethodPoint(x: targetX, y: targetY),
    ],
  );

  return _SimpleQuizQuestion(
    id: '${pattern.id}_${index + 1}',
    koQuestion: '이 장면에서 다음 플레이로 가장 좋은 선택은?',
    enQuestion: 'Looking at the pitch, what is the best next action?',
    options: [
      _SimpleQuizOption(koText: pattern.koCorrect, enText: pattern.enCorrect),
      _SimpleQuizOption(koText: pattern.koWrong1, enText: pattern.enWrong1),
      _SimpleQuizOption(koText: pattern.koWrong2, enText: pattern.enWrong2),
    ],
    correctIndex: 0,
    koExplain: pattern.koExplain,
    enExplain: pattern.enExplain,
    koTitle: pattern.koTitle,
    enTitle: pattern.enTitle,
    koMovementCaption: pattern.koMovement,
    enMovementCaption: pattern.enMovement,
    boardPage: page,
  );
}

class _ScenarioPattern {
  final String id;
  final String koTitle;
  final String enTitle;
  final String koMovement;
  final String enMovement;
  final String koCorrect;
  final String enCorrect;
  final String koWrong1;
  final String enWrong1;
  final String koWrong2;
  final String enWrong2;
  final String koExplain;
  final String enExplain;

  const _ScenarioPattern({
    required this.id,
    required this.koTitle,
    required this.enTitle,
    required this.koMovement,
    required this.enMovement,
    required this.koCorrect,
    required this.enCorrect,
    required this.koWrong1,
    required this.enWrong1,
    required this.koWrong2,
    required this.enWrong2,
    required this.koExplain,
    required this.enExplain,
  });
}
