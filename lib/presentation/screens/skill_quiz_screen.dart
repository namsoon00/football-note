import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

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
    final session = _QuizSessionSnapshot.tryParse(
      optionRepository.getValue<String>(sessionKey),
    );
    final pending = _ScheduledWrongItem.decodeList(
      optionRepository.getValue<String>(pendingWrongScheduleKey),
    );
    final now = DateTime.now();
    final pendingDueCount =
        pending.where((item) => !item.dueAt.isAfter(now)).length;

    final rawCompletedAt = optionRepository.getValue<String>(completionKey);
    final completedAt =
        rawCompletedAt == null ? null : DateTime.tryParse(rawCompletedAt);
    final completedToday = completedAt != null &&
        completedAt.year == now.year &&
        completedAt.month == now.month &&
        completedAt.day == now.day;

    return SkillQuizResumeSummary(
      hasActiveSession: session != null,
      reviewMode: session?.mode == _QuizMode.review.name,
      currentIndex: session?.index ?? 0,
      totalQuestions: session?.questionIds.length ?? 0,
      pendingWrongCount: pendingDueCount,
      completedToday: completedToday,
    );
  }

  @override
  State<SkillQuizScreen> createState() => _SkillQuizScreenState();
}

class _SkillQuizScreenState extends State<SkillQuizScreen>
    with SingleTickerProviderStateMixin {
  static const int _dailyCount = 8;
  static const int _reviewCount = 8;
  static const int _practicalCount = 8;
  static const int _speedCount = 8;
  static const int _speedLimitSec = 12;

  late final AnimationController _pulseController;
  late final AnimationController _sceneMotionController;
  late final Map<String, _BoardQuizQuestion> _questionMap;
  late final List<_BoardQuizQuestion> _allQuestions;

  List<_BoardQuizQuestion> _questions = const <_BoardQuizQuestion>[];
  _QuizMode _mode = _QuizMode.daily;

  int _index = 0;
  int _score = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _timeouts = 0;
  int _answerCount = 0;
  int _responseMillisSum = 0;
  int _combo = 0;
  int _bestComboRun = 0;
  int _momentum = 0;

  int? _selectedIndex;
  bool _answered = false;
  bool _retryUsed = false;
  String? _retryFeedback;
  bool _finished = false;
  final Set<String> _wrongIds = <String>{};

  DateTime? _questionStartedAt;
  Timer? _speedTimer;
  int _speedLeft = _speedLimitSec;
  _AnswerFx _answerFx = _AnswerFx.none;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _sceneMotionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _allQuestions = _buildBoardQuizPool();
    _questionMap = {
      for (final question in _allQuestions) question.id: question
    };
    _restoreOrStart();
  }

  @override
  void dispose() {
    _speedTimer?.cancel();
    _sceneMotionController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _restoreOrStart() {
    final restored = _QuizSessionSnapshot.tryParse(
      widget.optionRepository.getValue<String>(SkillQuizScreen.sessionKey),
    );
    if (restored != null) {
      _applySnapshot(restored);
      return;
    }

    final dueReviewQuestions = _loadDueReviewQuestions();
    if (dueReviewQuestions.isNotEmpty) {
      _startSession(
        questions:
            dueReviewQuestions.take(_reviewCount).toList(growable: false),
        mode: _QuizMode.review,
        clearDueReview: true,
      );
      return;
    }

    _startDailySession();
  }

  void _applySnapshot(_QuizSessionSnapshot snapshot) {
    final questions = snapshot.questionIds
        .map((id) => _questionMap[id])
        .whereType<_BoardQuizQuestion>()
        .toList(growable: false);
    if (questions.isEmpty) {
      _startDailySession();
      return;
    }

    setState(() {
      _questions = questions;
      _mode = _QuizModeX.tryParse(snapshot.mode) ?? _QuizMode.daily;
      _index = snapshot.index.clamp(0, questions.length);
      _score = snapshot.score;
      _streak = snapshot.streak;
      _bestStreak = snapshot.bestStreak;
      _timeouts = snapshot.timeouts;
      _answerCount = snapshot.answerCount;
      _responseMillisSum = snapshot.responseMillisSum;
      _combo = 0;
      _bestComboRun = 0;
      _momentum = 0;
      _selectedIndex = snapshot.selectedIndex;
      _answered = snapshot.answered;
      _retryUsed = snapshot.retryUsed;
      _retryFeedback = snapshot.retryFeedback;
      _finished = snapshot.finished || _index >= questions.length;
      _wrongIds
        ..clear()
        ..addAll(snapshot.wrongIds);
      _speedLeft = snapshot.speedLeft.clamp(0, _speedLimitSec);
      _answerFx = _AnswerFx.none;
    });

    if (!_finished) {
      _startQuestionClock();
    }
  }

  void _startDailySession() {
    final token = _todayToken();
    final savedToken = widget.optionRepository
        .getValue<String>(SkillQuizScreen.dailyQuestionsDayKey);
    if (savedToken == token) {
      final savedIds = _decodeStringList(
        widget.optionRepository
            .getValue<String>(SkillQuizScreen.dailyQuestionsKey),
      );
      final savedQuestions = savedIds
          .map((id) => _questionMap[id])
          .whereType<_BoardQuizQuestion>()
          .toList(growable: false);
      if (savedQuestions.isNotEmpty) {
        _startSession(questions: savedQuestions, mode: _QuizMode.daily);
        return;
      }
    }

    final random = math.Random(_stableHash(token));
    final picked = _pickDailyTemplateQuestions(random);
    unawaited(widget.optionRepository
        .setValue(SkillQuizScreen.dailyQuestionsDayKey, token));
    unawaited(widget.optionRepository.setValue(
      SkillQuizScreen.dailyQuestionsKey,
      jsonEncode(picked.map((q) => q.id).toList(growable: false)),
    ));
    _startSession(questions: picked, mode: _QuizMode.daily);
  }

  void _startPracticalSession() {
    final source = _allQuestions
        .where((question) =>
            question.template != _BoardQuizTemplate.findTarget &&
            question.type == _BoardQuestionType.practical)
        .toList(growable: false);
    final random = math.Random(DateTime.now().microsecondsSinceEpoch);
    final picked = _pickAdaptiveQuestions(
      source: source,
      count: _practicalCount,
      random: random,
    );
    _startSession(questions: picked, mode: _QuizMode.practical);
  }

  void _startSpeedSession() {
    final random = math.Random(DateTime.now().microsecondsSinceEpoch);
    final picked = _pickAdaptiveQuestions(
      source: _allQuestions,
      count: _speedCount,
      random: random,
    );
    _startSession(questions: picked, mode: _QuizMode.speed);
  }

  void _startReviewSessionFromQueue() {
    final due = _loadDueReviewQuestions();
    if (due.isEmpty) return;
    _startSession(
      questions: due.take(_reviewCount).toList(growable: false),
      mode: _QuizMode.review,
      clearDueReview: true,
    );
  }

  void _startSession({
    required List<_BoardQuizQuestion> questions,
    required _QuizMode mode,
    bool clearDueReview = false,
  }) {
    if (questions.isEmpty) return;
    setState(() {
      _questions = questions;
      _mode = mode;
      _index = 0;
      _score = 0;
      _streak = 0;
      _bestStreak = 0;
      _timeouts = 0;
      _answerCount = 0;
      _responseMillisSum = 0;
      _combo = 0;
      _bestComboRun = 0;
      _momentum = 0;
      _selectedIndex = null;
      _answered = false;
      _retryUsed = false;
      _retryFeedback = null;
      _finished = false;
      _wrongIds.clear();
      _speedLeft = _speedLimitSec;
      _answerFx = _AnswerFx.none;
    });

    if (clearDueReview) {
      unawaited(_removeDueReviewQuestions(questions));
    }

    unawaited(_trackMetric('board_quiz_session_started'));
    _startQuestionClock();
    unawaited(_persistSession());
  }

  void _startQuestionClock() {
    _questionStartedAt = DateTime.now();
    if (_answered || _finished) {
      _sceneMotionController.stop();
    } else {
      _startSceneMotion();
    }
    _speedTimer?.cancel();
    if (_mode != _QuizMode.speed || _finished || _answered) {
      _speedLeft = _speedLimitSec;
      return;
    }

    _speedLeft = _speedLimitSec;
    _speedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _answered || _finished) {
        timer.cancel();
        return;
      }
      setState(() {
        _speedLeft -= 1;
        if (_speedLeft <= 0) {
          timer.cancel();
          _timeoutCurrentQuestion();
        }
      });
    });
  }

  void _startSceneMotion() {
    final duration = _mode == _QuizMode.speed
        ? const Duration(milliseconds: 1300)
        : const Duration(milliseconds: 2100);
    _sceneMotionController
      ..stop()
      ..duration = duration
      ..value = 0
      ..repeat();
  }

  void _timeoutCurrentQuestion() {
    if (_answered || _finished) return;
    final question = _questions[_index];
    setState(() {
      _selectedIndex = null;
      _answered = true;
      _retryUsed = true;
      _retryFeedback = 'timeout';
      _wrongIds.add(question.id);
      _timeouts += 1;
      _streak = 0;
      _combo = 0;
      _momentum = (_momentum - 20).clamp(0, 100);
      _answerCount += 1;
      _responseMillisSum += (_speedLimitSec * 1000);
      _answerFx = _AnswerFx.timeout;
    });
    _sceneMotionController.stop();
    unawaited(_trackMetric('board_question_timeout'));
    unawaited(_persistSession());
  }

  void _selectAnswer(int choice) {
    if (_finished || _answered) return;
    final question = _questions[_index];
    final isCorrect = choice == question.correctIndex;

    if (isCorrect) {
      _onAnswerResolved(choice: choice, correct: true);
      return;
    }

    if (!_retryUsed) {
      setState(() {
        _selectedIndex = choice;
        _retryUsed = true;
        _retryFeedback = 'incorrect';
      });
      unawaited(_trackMetric('board_option_selected'));
      unawaited(_persistSession());
      return;
    }

    _onAnswerResolved(
        choice: choice, correct: false, wrongQuestionId: question.id);
  }

  void _onAnswerResolved({
    required int choice,
    required bool correct,
    String? wrongQuestionId,
  }) {
    _speedTimer?.cancel();
    _sceneMotionController.stop();
    final responseMs = DateTime.now()
        .difference(_questionStartedAt ?? DateTime.now())
        .inMilliseconds;

    setState(() {
      _selectedIndex = choice;
      _answered = true;
      _retryFeedback = null;
      _answerCount += 1;
      _responseMillisSum += math.max(0, responseMs);
      if (correct) {
        _score += 1;
        _streak += 1;
        _combo += 1;
        if (_combo > _bestComboRun) {
          _bestComboRun = _combo;
        }
        _momentum = (_momentum + 12).clamp(0, 100);
        _answerFx = _AnswerFx.success;
        if (_streak > _bestStreak) {
          _bestStreak = _streak;
        }
      } else {
        _streak = 0;
        _combo = 0;
        _momentum = (_momentum - 18).clamp(0, 100);
        _answerFx = _AnswerFx.fail;
        if (wrongQuestionId != null) {
          _wrongIds.add(wrongQuestionId);
        }
      }
    });

    unawaited(_trackMetric('board_option_selected'));
    unawaited(_trackMetric('board_answer_evaluated'));
    unawaited(_persistSession());
  }

  Future<void> _goNext() async {
    if (_finished) return;

    if (!_answered) {
      if (!_retryUsed || _questions.isEmpty) return;
      final question = _questions[_index];
      final responseMs = DateTime.now()
          .difference(_questionStartedAt ?? DateTime.now())
          .inMilliseconds;
      setState(() {
        _answered = true;
        _retryFeedback = null;
        _streak = 0;
        _combo = 0;
        _momentum = (_momentum - 12).clamp(0, 100);
        _wrongIds.add(question.id);
        _answerCount += 1;
        _responseMillisSum += math.max(0, responseMs);
        _answerFx = _AnswerFx.fail;
      });
      unawaited(_trackMetric('board_next_without_second_try'));
    }

    final nextIndex = _index + 1;
    if (nextIndex >= _questions.length) {
      await _completeSession();
      return;
    }

    setState(() {
      _index = nextIndex;
      _selectedIndex = null;
      _answered = false;
      _retryUsed = false;
      _retryFeedback = null;
      _answerFx = _AnswerFx.none;
    });

    _startQuestionClock();
    await _persistSession();
  }

  Future<void> _completeSession() async {
    final wrongQuestions = _questions
        .where((question) => _wrongIds.contains(question.id))
        .toList(growable: false);

    await _scheduleReviewQuestions(wrongQuestions);
    await _recordRecentPerformance();
    await _trackMetric('board_quiz_session_completed');

    await widget.optionRepository.setValue(
      SkillQuizScreen.completionKey,
      DateTime.now().toIso8601String(),
    );
    await widget.optionRepository.setValue(SkillQuizScreen.sessionKey, '');

    if (!mounted) return;
    setState(() {
      _finished = true;
      _speedTimer?.cancel();
    });
  }

  Future<void> _openModeMenu() async {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final selected = await showModalBottomSheet<_QuizMode>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.today_outlined),
              title: Text(isKo ? '오늘의 보드 퀴즈' : 'Daily board quiz'),
              subtitle: Text(isKo ? '오늘 고정 세트' : 'Fixed set for today'),
              onTap: () => Navigator.of(context).pop(_QuizMode.daily),
            ),
            ListTile(
              leading: const Icon(Icons.rule_folder_outlined),
              title: Text(isKo ? '복습 모드' : 'Review mode'),
              subtitle:
                  Text(isKo ? '24시간 지난 오답 복습' : 'Review due wrong answers'),
              onTap: () => Navigator.of(context).pop(_QuizMode.review),
            ),
            ListTile(
              leading: const Icon(Icons.stadium_outlined),
              title: Text(isKo ? '실전 모드' : 'Practical mode'),
              subtitle: Text(isKo ? '상황 판단 중심' : 'Decision-heavy scenarios'),
              onTap: () => Navigator.of(context).pop(_QuizMode.practical),
            ),
            ListTile(
              leading: const Icon(Icons.speed_outlined),
              title: Text(isKo ? '스피드 모드' : 'Speed mode'),
              subtitle: Text(isKo
                  ? '문항당 $_speedLimitSec초 제한'
                  : '$_speedLimitSec s per question'),
              onTap: () => Navigator.of(context).pop(_QuizMode.speed),
            ),
          ],
        ),
      ),
    );

    if (!mounted || selected == null) return;

    switch (selected) {
      case _QuizMode.daily:
        _startDailySession();
        return;
      case _QuizMode.review:
        _startReviewSessionFromQueue();
        return;
      case _QuizMode.practical:
        _startPracticalSession();
        return;
      case _QuizMode.speed:
        _startSpeedSession();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return Scaffold(
      appBar: AppBar(
        title: Text(isKo ? '보드 퀴즈' : 'Board Quiz'),
        actions: [
          IconButton(
            onPressed: _openModeMenu,
            tooltip: isKo ? '모드 선택' : 'Choose mode',
            icon: const Icon(Icons.tune_outlined),
          ),
        ],
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
    if (_questions.isEmpty) {
      return Center(
        child: Text(
          isKo ? '문제가 준비되지 않았어요.' : 'No questions are ready.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    final question = _questions[_index];
    final progressText = '${_index + 1}/${_questions.length}';
    final missionTarget = _mode == _QuizMode.review ? 4 : 6;
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardHeight =
            (constraints.maxHeight * 0.48).clamp(320.0, 560.0).toDouble();
        final canGoNext = _answered || _retryUsed;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(label: _mode.label(isKo)),
                        _InfoChip(label: question.templateLabel(isKo)),
                        _InfoChip(label: isKo
                            ? '진행 $progressText'
                            : 'Progress $progressText'),
                        _InfoChip(
                          label: isKo
                              ? '미션 ${math.min(_score, missionTarget)}/$missionTarget'
                              : 'Mission ${math.min(_score, missionTarget)}/$missionTarget',
                        ),
                        _InfoChip(
                          label: isKo ? '콤보 x$_combo' : 'Combo x$_combo',
                          success: _combo >= 2,
                        ),
                        _InfoChip(
                          label: isKo ? '모멘텀 $_momentum' : 'Momentum $_momentum',
                          success: _momentum >= 60,
                        ),
                        if (_mode == _QuizMode.speed)
                          _InfoChip(
                            label: isKo ? '⏱ ${_speedLeft}s' : '⏱ ${_speedLeft}s',
                            danger: _speedLeft <= 3,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _ScenarioPromptCard(question: question, isKo: isKo),
                    const SizedBox(height: 10),
                    Stack(
                      children: [
                        _BoardSceneCard(
                          question: question,
                          pulse: _pulseController,
                          motion: _sceneMotionController,
                          isKo: isKo,
                          height: boardHeight * 0.58,
                        ),
                        if (_answerFx != _AnswerFx.none)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: _AnswerFxBadge(fx: _answerFx, isKo: isKo),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...question.options.asMap().entries.map((entry) {
                      final optionIndex = entry.key;
                      final option = entry.value;
                      final selected = _selectedIndex == optionIndex;
                      final isCorrect = optionIndex == question.correctIndex;

                      Color? borderColor;
                      Color? bgColor;
                      if (_answered || (_retryUsed && selected)) {
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
                        child: Material(
                          color: bgColor ??
                              Theme.of(context).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _selectAnswer(optionIndex),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: borderColor ??
                                      Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                                  width: borderColor == null ? 1.0 : 1.6,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 13,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.12),
                                    child: Icon(
                                      _optionIconForIndex(optionIndex),
                                      size: 15,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      option.text(isKo),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  if (_answered && isCorrect)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF0FA968),
                                    ),
                                  if ((_answered || _retryUsed) &&
                                      selected &&
                                      !isCorrect)
                                    const Icon(
                                      Icons.cancel,
                                      color: Color(0xFFEB5757),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    if (!_answered && _retryFeedback == 'incorrect')
                      Text(
                        isKo
                            ? '틀렸어요. 한 번 더 고를 수 있어요.'
                            : 'Incorrect. One more try.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFEB5757),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    if (!_answered && _retryFeedback == 'timeout')
                      Text(
                        isKo
                            ? '시간 초과! 다음엔 더 빨리 판단해보세요.'
                            : 'Time out! Try a faster decision.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFEB5757),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    if (_answered) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              question.explainText(isKo),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isKo
                                  ? '다음에 볼 포인트: ${question.nextPoint(true)}'
                                  : 'Next focus: ${question.nextPoint(false)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: canGoNext ? _goNext : null,
              icon: const Icon(Icons.navigate_next),
              label: Text(isKo ? '다음' : 'Next'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResult(bool isKo) {
    final total = _questions.length;
    final accuracy = total == 0 ? 0 : ((_score / total) * 100).round();
    final avgResponse = _answerCount == 0
        ? 0
        : ((_responseMillisSum / _answerCount) / 1000).toStringAsFixed(1);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isKo ? '보드 퀴즈 결과' : 'Board Quiz Result',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  isKo
                      ? '$_score / $total 정답 ($accuracy%)'
                      : '$_score / $total correct ($accuracy%)',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  isKo
                      ? '최고 연속 $_bestStreak회 · 최고 콤보 $_bestComboRun · 평균 ${avgResponse}s · 타임아웃 $_timeouts회'
                      : 'Best streak $_bestStreak · Best combo $_bestComboRun · Avg ${avgResponse}s · Timeouts $_timeouts',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _startDailySession,
                  icon: const Icon(Icons.today_outlined),
                  label: Text(isKo ? '오늘 세트 다시' : 'Replay daily set'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _startReviewSessionFromQueue,
                  icon: const Icon(Icons.rule_folder_outlined),
                  label: Text(isKo ? '복습 모드' : 'Review mode'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _startPracticalSession,
                  icon: const Icon(Icons.stadium_outlined),
                  label: Text(isKo ? '실전 모드' : 'Practical mode'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _startSpeedSession,
                  icon: const Icon(Icons.speed_outlined),
                  label: Text(isKo ? '스피드 모드' : 'Speed mode'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _persistSession() async {
    if (_finished || _questions.isEmpty) {
      await widget.optionRepository.setValue(SkillQuizScreen.sessionKey, '');
      return;
    }
    final snapshot = _QuizSessionSnapshot(
      mode: _mode.name,
      questionIds: _questions.map((q) => q.id).toList(growable: false),
      index: _index,
      score: _score,
      streak: _streak,
      bestStreak: _bestStreak,
      timeouts: _timeouts,
      answerCount: _answerCount,
      responseMillisSum: _responseMillisSum,
      selectedIndex: _selectedIndex,
      answered: _answered,
      retryUsed: _retryUsed,
      retryFeedback: _retryFeedback,
      wrongIds: _wrongIds.toList(growable: false),
      finished: _finished,
      speedLeft: _speedLeft,
    );
    await widget.optionRepository.setValue(
      SkillQuizScreen.sessionKey,
      snapshot.encode(),
    );
  }

  Future<void> _trackMetric(String key) async {
    final current = _QuizMetrics.parse(
      widget.optionRepository.getValue<String>(SkillQuizScreen.metricsKey),
    );
    current[key] = (current[key] ?? 0) + 1;
    await widget.optionRepository.setValue(
      SkillQuizScreen.metricsKey,
      jsonEncode(current),
    );
  }

  Future<void> _recordRecentPerformance() async {
    if (_questions.isEmpty) return;
    final accuracy = _score / _questions.length;
    final avgSec =
        _answerCount == 0 ? 8.0 : (_responseMillisSum / _answerCount) / 1000;
    final perf = _RecentPerformance(accuracy: accuracy, avgSeconds: avgSec);
    await widget.optionRepository.setValue(
      SkillQuizScreen.recentPerformanceKey,
      perf.encode(),
    );
  }

  List<_BoardQuizQuestion> _pickAdaptiveQuestions({
    required List<_BoardQuizQuestion> source,
    required int count,
    required math.Random random,
  }) {
    if (source.isEmpty) return const <_BoardQuizQuestion>[];

    final perf = _RecentPerformance.tryParse(
      widget.optionRepository
          .getValue<String>(SkillQuizScreen.recentPerformanceKey),
    );
    final targetDifficulty = perf?.targetDifficulty ?? 2;

    final easy = source.where((q) => q.difficulty == 1).toList(growable: false);
    final mid = source.where((q) => q.difficulty == 2).toList(growable: false);
    final hard = source.where((q) => q.difficulty == 3).toList(growable: false);

    final easyPool = [...easy]..shuffle(random);
    final midPool = [...mid]..shuffle(random);
    final hardPool = [...hard]..shuffle(random);

    final total = math.min(count, source.length);
    final hardRatio =
        targetDifficulty >= 3 ? 0.45 : (targetDifficulty <= 1 ? 0.15 : 0.30);
    final easyRatio =
        targetDifficulty <= 1 ? 0.45 : (targetDifficulty >= 3 ? 0.18 : 0.25);
    final midRatio = 1 - easyRatio - hardRatio;

    var needEasy = (total * easyRatio).round();
    var needMid = (total * midRatio).round();
    var needHard = total - needEasy - needMid;

    final picked = <_BoardQuizQuestion>[];
    void take(List<_BoardQuizQuestion> from, int need) {
      if (need <= 0) return;
      final takeCount = math.min(need, from.length);
      picked.addAll(from.take(takeCount));
      from.removeRange(0, takeCount);
    }

    take(easyPool, needEasy);
    take(midPool, needMid);
    take(hardPool, needHard);

    final remaining = <_BoardQuizQuestion>[...easyPool, ...midPool, ...hardPool]
      ..shuffle(random);
    if (picked.length < total) {
      picked.addAll(remaining.take(total - picked.length));
    }

    // keep deterministic but slightly mixed ordering
    return picked..shuffle(random);
  }

  List<_BoardQuizQuestion> _pickDailyTemplateQuestions(math.Random random) {
    final findTarget = _allQuestions
        .where((q) => q.template == _BoardQuizTemplate.findTarget)
        .toList(growable: false)
      ..shuffle(random);
    final oneStep = _allQuestions
        .where((q) => q.template == _BoardQuizTemplate.oneStep)
        .toList(growable: false)
      ..shuffle(random);
    final twoStep = _allQuestions
        .where((q) => q.template == _BoardQuizTemplate.twoStep)
        .toList(growable: false)
      ..shuffle(random);

    final picked = <_BoardQuizQuestion>[
      ...findTarget.take(3),
      ...oneStep.take(3),
      ...twoStep.take(2),
    ];
    if (picked.length < _dailyCount) {
      final rest = <_BoardQuizQuestion>[
        ..._allQuestions.where((q) => !picked.contains(q)),
      ]..shuffle(random);
      picked.addAll(rest.take(_dailyCount - picked.length));
    }
    return picked.take(_dailyCount).toList(growable: false);
  }

  List<_BoardQuizQuestion> _loadDueReviewQuestions() {
    final scheduled = _ScheduledWrongItem.decodeList(
      widget.optionRepository
          .getValue<String>(SkillQuizScreen.pendingWrongScheduleKey),
    );
    final now = DateTime.now();
    final dueIds = scheduled
        .where((item) => !item.dueAt.isAfter(now))
        .map((item) => item.questionId)
        .toList(growable: false);
    return dueIds
        .map((id) => _questionMap[id])
        .whereType<_BoardQuizQuestion>()
        .toList(growable: false);
  }

  Future<void> _removeDueReviewQuestions(
      List<_BoardQuizQuestion> questions) async {
    if (questions.isEmpty) return;
    final ids = questions.map((q) => q.id).toSet();
    final current = _ScheduledWrongItem.decodeList(
      widget.optionRepository
          .getValue<String>(SkillQuizScreen.pendingWrongScheduleKey),
    );
    final next = current
        .where((item) => !ids.contains(item.questionId))
        .toList(growable: false);
    await widget.optionRepository.setValue(
      SkillQuizScreen.pendingWrongScheduleKey,
      _ScheduledWrongItem.encodeList(next),
    );
    await widget.optionRepository
        .setValue(SkillQuizScreen.pendingWrongQuestionsKey, '');
  }

  Future<void> _scheduleReviewQuestions(
      List<_BoardQuizQuestion> wrongQuestions) async {
    final current = _ScheduledWrongItem.decodeList(
      widget.optionRepository
          .getValue<String>(SkillQuizScreen.pendingWrongScheduleKey),
    );
    final map = <String, _ScheduledWrongItem>{
      for (final item in current) item.questionId: item,
    };

    final now = DateTime.now();
    for (final question in wrongQuestions) {
      final prev = map[question.id];
      map[question.id] = _ScheduledWrongItem(
        questionId: question.id,
        dueAt: now.add(const Duration(hours: 24)),
        wrongCount: (prev?.wrongCount ?? 0) + 1,
        lastWrongAt: now,
      );
    }

    await widget.optionRepository.setValue(
      SkillQuizScreen.pendingWrongScheduleKey,
      _ScheduledWrongItem.encodeList(map.values.toList(growable: false)),
    );
    await widget.optionRepository
        .setValue(SkillQuizScreen.pendingWrongQuestionsKey, '');
  }

  String _todayToken() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static List<String> _decodeStringList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <String>[];
      return decoded.map((e) => e.toString()).toList(growable: false);
    } catch (_) {
      return const <String>[];
    }
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

enum _QuizMode { daily, review, practical, speed }

extension _QuizModeX on _QuizMode {
  static _QuizMode? tryParse(String? raw) {
    for (final mode in _QuizMode.values) {
      if (mode.name == raw) return mode;
    }
    return null;
  }

  String label(bool isKo) {
    switch (this) {
      case _QuizMode.daily:
        return isKo ? '오늘 세트' : 'Daily set';
      case _QuizMode.review:
        return isKo ? '복습' : 'Review';
      case _QuizMode.practical:
        return isKo ? '실전' : 'Practical';
      case _QuizMode.speed:
        return isKo ? '스피드' : 'Speed';
    }
  }
}

class _BoardQuizQuestion {
  final String id;
  final int difficulty;
  final _BoardQuestionType type;
  final _BoardQuizTemplate template;
  final TrainingMethodPage page;
  final String koCaption;
  final String enCaption;
  final String koQuestion;
  final String enQuestion;
  final List<_BoardQuizOption> options;
  final int correctIndex;
  final String koExplain;
  final String enExplain;
  final String koNextPoint;
  final String enNextPoint;

  const _BoardQuizQuestion({
    required this.id,
    required this.difficulty,
    required this.type,
    required this.template,
    required this.page,
    required this.koCaption,
    required this.enCaption,
    required this.koQuestion,
    required this.enQuestion,
    required this.options,
    required this.correctIndex,
    required this.koExplain,
    required this.enExplain,
    required this.koNextPoint,
    required this.enNextPoint,
  });

  String caption(bool isKo) => isKo ? koCaption : enCaption;
  String questionText(bool isKo) => isKo ? koQuestion : enQuestion;
  String explainText(bool isKo) => isKo ? koExplain : enExplain;
  String nextPoint(bool isKo) => isKo ? koNextPoint : enNextPoint;
  String templateLabel(bool isKo) => template.label(isKo);
}

enum _BoardQuestionType { basic, practical }

enum _BoardQuizTemplate { findTarget, oneStep, twoStep }

extension _BoardQuizTemplateX on _BoardQuizTemplate {
  String label(bool isKo) {
    switch (this) {
      case _BoardQuizTemplate.findTarget:
        return isKo ? '대상 찾기' : 'Find target';
      case _BoardQuizTemplate.oneStep:
        return isKo ? '1수 판단' : '1-step choice';
      case _BoardQuizTemplate.twoStep:
        return isKo ? '2수 판단' : '2-step plan';
    }
  }
}

class _BoardQuizOption {
  final String koText;
  final String enText;

  const _BoardQuizOption({required this.koText, required this.enText});

  String text(bool isKo) => isKo ? koText : enText;
}

class _BoardSceneCard extends StatelessWidget {
  final _BoardQuizQuestion question;
  final Animation<double> pulse;
  final Animation<double> motion;
  final bool isKo;
  final double height;

  const _BoardSceneCard({
    required this.question,
    required this.pulse,
    required this.motion,
    required this.isKo,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final focus = _resolveFocus(question.page);
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
            question.caption(isKo),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: Listenable.merge([pulse, motion]),
                builder: (context, child) => Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 2.6,
                        boundaryMargin: const EdgeInsets.all(28),
                        child: child!,
                      ),
                    ),
                    CustomPaint(
                      painter: _TacticalDetailPainter(
                        page: question.page,
                        isKo: isKo,
                      ),
                    ),
                    CustomPaint(
                      painter: _PlayMotionPainter(
                        page: question.page,
                        t: motion.value,
                      ),
                    ),
                    if (focus != null)
                      CustomPaint(
                        painter: _PulseFocusPainter(
                          point: focus,
                          t: pulse.value,
                        ),
                      ),
                  ],
                ),
                child: TrainingBoardSketch(
                  page: question.page,
                  borderRadius: 14,
                  showStrokes: true,
                  showPlayerPath: true,
                  showBallPath: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(
                color: const Color(0xFFB3E5FC),
                label: isKo ? '우리 팀' : 'Our team',
              ),
              const SizedBox(width: 10),
              _LegendDot(
                color: const Color(0xFFFFCCBC),
                label: isKo ? '상대' : 'Opponent',
              ),
              const SizedBox(width: 10),
              _LegendDot(
                color: const Color(0xFFFFF8E1),
                label: isKo ? '볼' : 'Ball',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _sceneReadText(question.page, isKo),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  TrainingMethodPoint? _resolveFocus(TrainingMethodPage page) {
    if (page.ballPath.isNotEmpty) return page.ballPath.last;
    if (page.playerPath.isNotEmpty) return page.playerPath.last;
    return null;
  }

  String _sceneReadText(TrainingMethodPage page, bool isKo) {
    final ball = page.items.where((item) => item.type == 'ball').toList();
    final players = page.items.where((item) => item.type == 'player').toList();
    final ourTeam = players.where((item) => item.colorValue == 0xFFB3E5FC);
    final oppTeam = players.where((item) => item.colorValue == 0xFFFFCCBC);
    final ownerLabel = _nearestPlayerLabel(
      ball: ball.isEmpty ? null : ball.first,
      players: players,
      isKo: isKo,
    );

    final ballPos = ball.isEmpty ? null : _zoneLabel(ball.first.x, ball.first.y);
    final passTo = page.ballPath.isEmpty ? null : page.ballPath.last;
    final supportPos = passTo == null ? null : _zoneLabel(passTo.x, passTo.y);
    final runTo = page.playerPath.isEmpty ? null : page.playerPath.last;
    final runPos = runTo == null ? null : _zoneLabel(runTo.x, runTo.y);
    if (isKo) {
      return '장면 읽기: 볼소유 ${ownerLabel ?? '미확인'} · 볼 ${ballPos ?? '중앙'} · 패스 목표 ${supportPos ?? '없음'} · '
          '러너 방향 ${runPos ?? '없음'} · 우리 ${ourTeam.length}명 / 상대 ${oppTeam.length}명';
    }
    return 'Scene read: Owner ${ownerLabel ?? 'unknown'} · Ball ${ballPos ?? 'center'} · Pass target ${supportPos ?? 'none'} · '
        'Runner path ${runPos ?? 'none'} · Us ${ourTeam.length} / Opp ${oppTeam.length}';
  }

  String _zoneLabel(double x, double y) {
    final h = x < 0.33 ? 'left' : x > 0.67 ? 'right' : 'center';
    final v = y < 0.33 ? 'top' : y > 0.67 ? 'bottom' : 'middle';
    return '$v-$h';
  }

  String? _nearestPlayerLabel({
    required TrainingMethodItem? ball,
    required Iterable<TrainingMethodItem> players,
    required bool isKo,
  }) {
    if (ball == null) return null;
    final list = players.toList(growable: false);
    if (list.isEmpty) return null;
    var bestIndex = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      final dx = item.x - ball.x;
      final dy = item.y - ball.y;
      final dist = (dx * dx) + (dy * dy);
      if (dist < bestDistance) {
        bestDistance = dist;
        bestIndex = i;
      }
    }
    final owner = list[bestIndex];
    final sameTeamIndex = list
            .take(bestIndex + 1)
            .where((item) => item.colorValue == owner.colorValue)
            .length;
    final isOur = owner.colorValue == 0xFFB3E5FC;
    if (isKo) {
      return isOur ? '우리$sameTeamIndex' : '상대$sameTeamIndex';
    }
    return isOur ? 'A$sameTeamIndex' : 'D$sameTeamIndex';
  }
}

IconData _optionIconForIndex(int index) {
  switch (index) {
    case 0:
      return Icons.looks_one_rounded;
    case 1:
      return Icons.looks_two_rounded;
    default:
      return Icons.looks_3_rounded;
  }
}

class _ScenarioPromptCard extends StatelessWidget {
  final _BoardQuizQuestion question;
  final bool isKo;

  const _ScenarioPromptCard({required this.question, required this.isKo});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.caption(isKo),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              question.questionText(isKo),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              isKo
                  ? '아래 행동 카드 1개를 골라요.'
                  : 'Pick one action card below.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black12),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _TacticalDetailPainter extends CustomPainter {
  final TrainingMethodPage page;
  final bool isKo;

  const _TacticalDetailPainter({required this.page, required this.isKo});

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = const Color(0x558FA0C6)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * 0.33, 0),
      Offset(size.width * 0.33, size.height),
      guidePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.67, 0),
      Offset(size.width * 0.67, size.height),
      guidePaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.33),
      Offset(size.width, size.height * 0.33),
      guidePaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.67),
      Offset(size.width, size.height * 0.67),
      guidePaint,
    );

    final ballPath = page.ballPath;
    if (ballPath.length >= 2) {
      final start = Offset(
        ballPath.first.x * size.width,
        ballPath.first.y * size.height,
      );
      final end = Offset(
        ballPath.last.x * size.width,
        ballPath.last.y * size.height,
      );
      final lanePaint = Paint()
        ..color = const Color(0x4D1E88E5)
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, lanePaint);
    }

    final players = page.items.where((item) => item.type == 'player').toList();
    var ourIndex = 1;
    var oppIndex = 1;
    for (final player in players) {
      final center = Offset(player.x * size.width, player.y * size.height);
      final ours = player.colorValue == 0xFFB3E5FC;
      final label = ours
          ? (isKo ? '우리$ourIndex' : 'A$ourIndex')
          : (isKo ? '상대$oppIndex' : 'D$oppIndex');
      if (ours) {
        ourIndex += 1;
      } else {
        oppIndex += 1;
      }
      _drawLabel(
        canvas,
        center.translate(0, -18),
        label,
        ours ? const Color(0xFF0D47A1) : const Color(0xFFBF360C),
      );
    }

    final ball = page.items.where((item) => item.type == 'ball').toList();
    if (ball.isNotEmpty) {
      final center = Offset(ball.first.x * size.width, ball.first.y * size.height);
      _drawLabel(
        canvas,
        center.translate(0, -18),
        isKo ? '볼' : 'Ball',
        const Color(0xFF5D4037),
      );
    }
  }

  void _drawLabel(Canvas canvas, Offset center, String text, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          backgroundColor: Colors.white70,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - (textPainter.width / 2), center.dy - textPainter.height),
    );
  }

  @override
  bool shouldRepaint(covariant _TacticalDetailPainter oldDelegate) {
    return oldDelegate.page != page || oldDelegate.isKo != isKo;
  }
}

class _PlayMotionPainter extends CustomPainter {
  final TrainingMethodPage page;
  final double t;

  const _PlayMotionPainter({required this.page, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final pulseAlpha = (0.25 + (0.55 * (0.5 + 0.5 * math.sin(t * math.pi * 2))))
        .clamp(0.0, 1.0);
    final lanePath = _lanePath(page.ballPath, size);
    if (lanePath != null) {
      final lanePaint = Paint()
        ..color = const Color(0xFF4FC3F7).withValues(alpha: pulseAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(lanePath, lanePaint);
    }

    final ball = _samplePoint(page.ballPath, t);
    final runner = _samplePoint(page.playerPath, (t + 0.18) % 1.0);

    if (ball != null) {
      for (var i = 1; i <= 4; i++) {
        final trailPoint = _samplePoint(page.ballPath, _wrap01(t - (i * 0.07)));
        if (trailPoint == null) continue;
        final trail = Offset(trailPoint.x * size.width, trailPoint.y * size.height);
        final a = (0.12 * (5 - i)).clamp(0.0, 0.45);
        final trailPaint = Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: a)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(trail, 5.5 - i, trailPaint);
      }
      final c = Offset(ball.x * size.width, ball.y * size.height);
      final glow = Paint()
        ..color = const Color(0x80FFD54F)
        ..style = PaintingStyle.fill;
      final dot = Paint()
        ..color = const Color(0xFFFFC107)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(c, 17, glow);
      canvas.drawCircle(c, 8, dot);
    }

    if (runner != null) {
      final c = Offset(runner.x * size.width, runner.y * size.height);
      final glow = Paint()
        ..color = const Color(0x8042A5F5)
        ..style = PaintingStyle.fill;
      final dot = Paint()
        ..color = const Color(0xFF1E88E5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(c, 15, glow);
      canvas.drawCircle(c, 7, dot);
    }
  }

  Path? _lanePath(List<TrainingMethodPoint> path, Size size) {
    if (path.length < 2) return null;
    final lane = Path()
      ..moveTo(path.first.x * size.width, path.first.y * size.height);
    for (var i = 1; i < path.length; i++) {
      lane.lineTo(path[i].x * size.width, path[i].y * size.height);
    }
    return lane;
  }

  TrainingMethodPoint? _samplePoint(List<TrainingMethodPoint> path, double t) {
    if (path.isEmpty) return null;
    if (path.length == 1) return path.first;
    final segments = path.length - 1;
    final scaled = (t.clamp(0.0, 0.999999)) * segments;
    final index = scaled.floor().clamp(0, segments - 1);
    final local = scaled - index;
    final start = path[index];
    final end = path[index + 1];
    return TrainingMethodPoint(
      x: start.x + (end.x - start.x) * local,
      y: start.y + (end.y - start.y) * local,
    );
  }

  double _wrap01(double value) {
    var v = value;
    while (v < 0) {
      v += 1;
    }
    while (v >= 1) {
      v -= 1;
    }
    return v;
  }

  @override
  bool shouldRepaint(covariant _PlayMotionPainter oldDelegate) {
    return oldDelegate.page != page || oldDelegate.t != t;
  }
}

class _PulseFocusPainter extends CustomPainter {
  final TrainingMethodPoint point;
  final double t;

  const _PulseFocusPainter({required this.point, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(point.x * size.width, point.y * size.height);
    final outerRadius = 18 + (16 * t);
    final innerRadius = 10 + (7 * t);

    final outerPaint = Paint()
      ..color = const Color(0x55FFD54F)
      ..style = PaintingStyle.fill;
    final innerPaint = Paint()
      ..color = const Color(0xCCFFE082)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawCircle(center, outerRadius, outerPaint);
    canvas.drawCircle(center, innerRadius, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _PulseFocusPainter oldDelegate) {
    return oldDelegate.point != point || oldDelegate.t != t;
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final bool danger;
  final bool success;

  const _InfoChip({
    required this.label,
    this.danger = false,
    this.success = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bgColor = danger
        ? const Color(0x1AEB5757)
        : success
            ? const Color(0x1A0FA968)
            : scheme.surfaceContainerHighest;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: danger
                  ? const Color(0xFFC62828)
                  : success
                      ? const Color(0xFF1B5E20)
                      : null,
            ),
      ),
    );
  }
}

enum _AnswerFx { none, success, fail, timeout }

class _AnswerFxBadge extends StatelessWidget {
  final _AnswerFx fx;
  final bool isKo;

  const _AnswerFxBadge({required this.fx, required this.isKo});

  @override
  Widget build(BuildContext context) {
    final (icon, text, color) = switch (fx) {
      _AnswerFx.success => (
          Icons.check_circle,
          isKo ? '성공 패스!' : 'Perfect pass!',
          const Color(0xFF0FA968),
        ),
      _AnswerFx.fail => (
          Icons.cancel,
          isKo ? '실패! 다시 읽어보자' : 'Miss! Re-read board',
          const Color(0xFFEB5757),
        ),
      _AnswerFx.timeout => (
          Icons.timer_off,
          isKo ? '시간 초과' : 'Time out',
          const Color(0xFFF57C00),
        ),
      _AnswerFx.none => (Icons.circle, '', Colors.transparent),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuizSessionSnapshot {
  final String mode;
  final List<String> questionIds;
  final int index;
  final int score;
  final int streak;
  final int bestStreak;
  final int timeouts;
  final int answerCount;
  final int responseMillisSum;
  final int? selectedIndex;
  final bool answered;
  final bool retryUsed;
  final String? retryFeedback;
  final List<String> wrongIds;
  final bool finished;
  final int speedLeft;

  const _QuizSessionSnapshot({
    required this.mode,
    required this.questionIds,
    required this.index,
    required this.score,
    required this.streak,
    required this.bestStreak,
    required this.timeouts,
    required this.answerCount,
    required this.responseMillisSum,
    required this.selectedIndex,
    required this.answered,
    required this.retryUsed,
    required this.retryFeedback,
    required this.wrongIds,
    required this.finished,
    required this.speedLeft,
  });

  String encode() => jsonEncode(<String, dynamic>{
        'mode': mode,
        'questionIds': questionIds,
        'index': index,
        'score': score,
        'streak': streak,
        'bestStreak': bestStreak,
        'timeouts': timeouts,
        'answerCount': answerCount,
        'responseMillisSum': responseMillisSum,
        'selectedIndex': selectedIndex,
        'answered': answered,
        'retryUsed': retryUsed,
        'retryFeedback': retryFeedback,
        'wrongIds': wrongIds,
        'finished': finished,
        'speedLeft': speedLeft,
      });

  static _QuizSessionSnapshot? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final ids = (decoded['questionIds'] as List?)
              ?.map((item) => item.toString())
              .toList(growable: false) ??
          const <String>[];
      if (ids.isEmpty) return null;
      return _QuizSessionSnapshot(
        mode: decoded['mode']?.toString() ?? _QuizMode.daily.name,
        questionIds: ids,
        index: (decoded['index'] as num?)?.toInt() ?? 0,
        score: (decoded['score'] as num?)?.toInt() ?? 0,
        streak: (decoded['streak'] as num?)?.toInt() ?? 0,
        bestStreak: (decoded['bestStreak'] as num?)?.toInt() ?? 0,
        timeouts: (decoded['timeouts'] as num?)?.toInt() ?? 0,
        answerCount: (decoded['answerCount'] as num?)?.toInt() ?? 0,
        responseMillisSum: (decoded['responseMillisSum'] as num?)?.toInt() ?? 0,
        selectedIndex: (decoded['selectedIndex'] as num?)?.toInt(),
        answered: decoded['answered'] == true,
        retryUsed: decoded['retryUsed'] == true,
        retryFeedback: decoded['retryFeedback']?.toString(),
        wrongIds: (decoded['wrongIds'] as List?)
                ?.map((item) => item.toString())
                .toList(growable: false) ??
            const <String>[],
        finished: decoded['finished'] == true,
        speedLeft: (decoded['speedLeft'] as num?)?.toInt() ?? 12,
      );
    } catch (_) {
      return null;
    }
  }
}

class _ScheduledWrongItem {
  final String questionId;
  final DateTime dueAt;
  final int wrongCount;
  final DateTime lastWrongAt;

  const _ScheduledWrongItem({
    required this.questionId,
    required this.dueAt,
    required this.wrongCount,
    required this.lastWrongAt,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
        'questionId': questionId,
        'dueAt': dueAt.toIso8601String(),
        'wrongCount': wrongCount,
        'lastWrongAt': lastWrongAt.toIso8601String(),
      };

  static String encodeList(List<_ScheduledWrongItem> list) =>
      jsonEncode(list.map((item) => item.toMap()).toList(growable: false));

  static List<_ScheduledWrongItem> decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <_ScheduledWrongItem>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <_ScheduledWrongItem>[];
      return decoded
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .map((map) {
            final dueAt = DateTime.tryParse(map['dueAt']?.toString() ?? '');
            final lastWrongAt =
                DateTime.tryParse(map['lastWrongAt']?.toString() ?? '');
            if (dueAt == null || lastWrongAt == null) return null;
            return _ScheduledWrongItem(
              questionId: map['questionId']?.toString() ?? '',
              dueAt: dueAt,
              wrongCount: (map['wrongCount'] as num?)?.toInt() ?? 1,
              lastWrongAt: lastWrongAt,
            );
          })
          .whereType<_ScheduledWrongItem>()
          .toList(growable: false);
    } catch (_) {
      return const <_ScheduledWrongItem>[];
    }
  }
}

class _RecentPerformance {
  final double accuracy;
  final double avgSeconds;

  const _RecentPerformance({required this.accuracy, required this.avgSeconds});

  int get targetDifficulty {
    if (accuracy >= 0.82 && avgSeconds <= 4.6) return 3;
    if (accuracy <= 0.58 || avgSeconds >= 7.6) return 1;
    return 2;
  }

  String encode() => jsonEncode(<String, dynamic>{
        'accuracy': accuracy,
        'avgSeconds': avgSeconds,
      });

  static _RecentPerformance? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return _RecentPerformance(
        accuracy: (decoded['accuracy'] as num?)?.toDouble() ?? 0,
        avgSeconds: (decoded['avgSeconds'] as num?)?.toDouble() ?? 8,
      );
    } catch (_) {
      return null;
    }
  }
}

class _QuizMetrics {
  static Map<String, int> parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return <String, int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, int>{};
      return decoded.map(
        (key, value) => MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
      );
    } catch (_) {
      return <String, int>{};
    }
  }
}

List<_BoardQuizQuestion> _buildBoardQuizPool() {
  final scenes = _sceneTemplates();
  return <_BoardQuizQuestion>[
    _question(
      id: 'bq_01',
      difficulty: 1,
      type: _BoardQuestionType.basic,
      template: _BoardQuizTemplate.findTarget,
      scene: scenes[0],
      koCaption: '좌하단 볼 소유자가 중앙 지원에게 연결할 수 있는 장면',
      enCaption: 'Bottom-left ball holder can connect to central support',
      koQuestion: '화면에서 우리1(볼) 기준, 가장 짧고 안전한 패스 대상은?',
      enQuestion: 'From A1 (ball), which visible target is the shortest safe pass?',
      options: const [
        _BoardQuizOption(
          koText: '우리2(중앙)로 짧게 연결',
          enText: 'Short pass to A2 (center)',
        ),
        _BoardQuizOption(
          koText: '수비 사이로 우리3(우상단) 롱패스',
          enText: 'Long pass to A3 through defenders',
        ),
        _BoardQuizOption(
          koText: '패스 없이 멈춰서 대기',
          enText: 'No pass, just hold the ball',
        ),
      ],
      correctIndex: 0,
      koExplain: '보드에서 우리2가 우리1과 가장 가깝고 패스 라인도 짧아 첫 선택으로 가장 안전합니다.',
      enExplain:
          'A2 is the nearest visible support from A1 with the shortest passing lane.',
      koNextPoint: '볼소유자에서 가장 가까운 우리 팀 1명을 먼저 찾기',
      enNextPoint: 'Find the nearest teammate from ball owner first',
    ),
    _question(
      id: 'bq_02',
      difficulty: 2,
      type: _BoardQuestionType.basic,
      template: _BoardQuizTemplate.findTarget,
      scene: scenes[1],
      koCaption: '중앙 보유, 오른쪽 하단 지원이 비어 있는 장면',
      enCaption: 'Central possession with open right-lower support lane',
      koQuestion: '우리2(볼) 기준, 화면에서 가장 열린 다음 연결 지점은?',
      enQuestion: 'From A2 (ball), which visible next lane is most open?',
      options: const [
        _BoardQuizOption(
          koText: '우리3(우하단) 쪽 열린 라인',
          enText: 'Open lane toward A3 (right-lower)',
        ),
        _BoardQuizOption(
          koText: '공만 보고 전진 드리블',
          enText: 'Dribble forward staring at ball',
        ),
        _BoardQuizOption(
          koText: '항상 중앙으로만 강제 패스',
          enText: 'Force center-only pass every time',
        ),
      ],
      correctIndex: 0,
      koExplain: '장면에서 우리3 방향이 수비 간격이 넓어 가장 열려 있습니다.',
      enExplain:
          'The lane to A3 is visibly wider than central forced options in this frame.',
      koNextPoint: '패스 전에 수비 사이 간격이 넓은 쪽 찾기',
      enNextPoint: 'Before passing, find the widest defender gap',
    ),
    _question(
      id: 'bq_03',
      difficulty: 2,
      type: _BoardQuestionType.basic,
      template: _BoardQuizTemplate.oneStep,
      scene: scenes[2],
      koCaption: '중앙에서 우측 전방 러너가 침투하는 전환 장면',
      enCaption: 'Transition scene with right-front runner making a run',
      koQuestion: '우리2(볼)에서 찬스를 만들려면 누구 앞공간으로 넣어야 하나?',
      enQuestion: 'From A2 (ball), whose front-space pass creates a chance?',
      options: const [
        _BoardQuizOption(
          koText: '우리3(우측 러너) 전방 공간',
          enText: 'Into A3 (right runner) front space',
        ),
        _BoardQuizOption(
          koText: '멈춰서 전원 올라올 때까지 대기',
          enText: 'Stop and wait for full team push-up',
        ),
        _BoardQuizOption(
          koText: '뒤로만 안전 패스 반복',
          enText: 'Repeat only backward safe passes',
        ),
      ],
      correctIndex: 0,
      koExplain: '보드에서 우리3의 진행 방향 앞이 비어 있어 타이밍 패스가 가장 위협적입니다.',
      enExplain:
          'A3 has open front-space in this frame, making the timing pass most dangerous.',
      koNextPoint: '러너의 앞공간이 비었는지 먼저 보기',
      enNextPoint: 'Check if runner front-space is open first',
    ),
    _question(
      id: 'bq_04',
      difficulty: 3,
      type: _BoardQuestionType.practical,
      template: _BoardQuizTemplate.oneStep,
      scene: scenes[3],
      koCaption: '좌하단 볼 소유, 근거리 패스 옵션 2개가 보이는 리드 상황',
      enCaption: 'Lead situation with two short passing options from bottom-left',
      koQuestion: '우리1(볼), 1점 리드 상황에서 화면 기준 가장 안정적인 운영은?',
      enQuestion: 'A1 on the ball, one-goal lead: which visible choice is most stable?',
      options: const [
        _BoardQuizOption(
          koText: '우리2로 짧게 연결하며 템포 조절',
          enText: 'Short link to A2 to control tempo',
        ),
        _BoardQuizOption(
          koText: '가장 먼 전방으로 즉시 전진 패스',
          enText: 'Force the longest immediate forward pass',
        ),
        _BoardQuizOption(
          koText: '볼만 보호하고 움직임 정지',
          enText: 'Freeze movement and shield only',
        ),
      ],
      correctIndex: 0,
      koExplain: '이 장면은 근거리 지원(우리2)이 보여 짧은 연결이 실수 위험을 가장 낮춥니다.',
      enExplain:
          'A2 is the clear close outlet here, minimizing turnover risk while leading.',
      koNextPoint: '리드 상황일수록 짧은 연결 우선',
      enNextPoint: 'When leading, prioritize short stable links',
    ),
    _question(
      id: 'bq_05',
      difficulty: 3,
      type: _BoardQuestionType.practical,
      template: _BoardQuizTemplate.oneStep,
      scene: scenes[4],
      koCaption: '우상단 볼 보유 상대를 향해 수비 전환이 시작되는 장면',
      enCaption: 'Defensive transition starts against top-right ball holder',
      koQuestion: '수비 전환 직후, 화면에서 상대 볼(우상단) 대응의 첫 행동은?',
      enQuestion: 'Right after transition, what is the first action vs top-right ball?',
      options: const [
        _BoardQuizOption(
          koText: '가까운 패스길(중앙) 차단하며 지연',
          enText: 'Block nearest central lane and delay',
        ),
        _BoardQuizOption(
          koText: '전원 공 쪽으로 동시 돌진',
          enText: 'All players rush ball at once',
        ),
        _BoardQuizOption(
          koText: '무조건 깊게 물러서기만',
          enText: 'Only retreat deep immediately',
        ),
      ],
      correctIndex: 0,
      koExplain: '보드에서 중앙 연결길이 가장 위험하므로 먼저 차단하고 시간(지연)을 벌어야 합니다.',
      enExplain:
          'The central outlet is the key danger lane in this frame, so delay + lane block comes first.',
      koNextPoint: '수비 전환 첫 동작은 지연 + 중앙 라인 차단',
      enNextPoint: 'First defensive action: delay + block central lane',
    ),
    _question(
      id: 'bq_06',
      difficulty: 1,
      type: _BoardQuestionType.basic,
      template: _BoardQuizTemplate.twoStep,
      scene: scenes[5],
      koCaption: '좌상단에서 중앙 지원으로 연결될 수 있는 빌드업 장면',
      enCaption: 'Build-up scene from top-left into central support',
      koQuestion: '우리1(좌상단)이 받을 때, 화면 기반 프리스캔 목표는?',
      enQuestion: 'When A1 receives (top-left), what is the pre-scan goal here?',
      options: const [
        _BoardQuizOption(
          koText: '우리2/우리3 다음 선택 2개 미리 확인',
          enText: 'Pre-check two next options: A2/A3',
        ),
        _BoardQuizOption(
          koText: '공만 오래 보며 터치 준비',
          enText: 'Stare only at ball before touch',
        ),
        _BoardQuizOption(
          koText: '터치를 늘려 시간 벌기',
          enText: 'Increase touches to buy time',
        ),
      ],
      correctIndex: 0,
      koExplain: '이 장면처럼 지원 옵션이 2개일 때, 받기 전에 다음 선택을 정해두면 판단 속도가 빨라집니다.',
      enExplain:
          'With two visible supports, pre-checking options enables immediate decisions.',
      koNextPoint: '받기 전에 다음 2개 선택을 미리 정하기',
      enNextPoint: 'Set next two options before first touch',
    ),
    _question(
      id: 'bq_07',
      difficulty: 2,
      type: _BoardQuestionType.basic,
      template: _BoardQuizTemplate.twoStep,
      scene: scenes[6],
      koCaption: '좌측 측면에서 크로스가 가능한 압박 장면',
      enCaption: 'Left-flank pressure scene where cross is possible',
      koQuestion: '좌측 측면 볼 상황에서, 화면상 크로스 억제 1순위는?',
      enQuestion: 'Left-flank ball situation: what is priority #1 to stop cross?',
      options: const [
        _BoardQuizOption(
          koText: '크로스 발(오른발) 각도 먼저 차단',
          enText: 'Block crossing-foot angle first',
        ),
        _BoardQuizOption(
          koText: '거리만 유지하고 대기',
          enText: 'Keep distance and wait only',
        ),
        _BoardQuizOption(
          koText: '무조건 태클 먼저 시도',
          enText: 'Always tackle first',
        ),
      ],
      correctIndex: 0,
      koExplain: '보드에서 측면 각이 살아 있으므로 발 각도를 먼저 닫아야 크로스 확률이 줄어듭니다.',
      enExplain:
          'The flank angle is open here, so closing crossing-foot angle is the first priority.',
      koNextPoint: '측면 수비는 각도 차단 후 거리 조절',
      enNextPoint: 'On flank defense: close angle, then control distance',
    ),
    _question(
      id: 'bq_08',
      difficulty: 3,
      type: _BoardQuestionType.practical,
      template: _BoardQuizTemplate.twoStep,
      scene: scenes[7],
      koCaption: '좌하단에서 실수 후 다시 중앙으로 복귀해야 하는 장면',
      enCaption: 'After-mistake scene requiring quick recovery to central shape',
      koQuestion: '실수 직후 형태가 흔들린 이 장면에서, 즉시 해야 할 반응은?',
      enQuestion: 'After a mistake in this broken-shape frame, what is best reset action?',
      options: const [
        _BoardQuizOption(
          koText: '즉시 본인 다음 역할(수비/지원)로 복귀',
          enText: 'Return immediately to next role (defend/support)',
        ),
        _BoardQuizOption(
          koText: '이전 실수 장면을 계속 떠올리기',
          enText: 'Keep replaying the mistake mentally',
        ),
        _BoardQuizOption(
          koText: '한 플레이 쉬면서 멈추기',
          enText: 'Take one play off and pause',
        ),
      ],
      correctIndex: 0,
      koExplain: '이 화면은 전환 속도가 중요해 즉시 역할 복귀가 가장 큰 회복 효과를 냅니다.',
      enExplain:
          'In this transition frame, immediate role recovery gives the highest reset value.',
      koNextPoint: '실수 직후에는 다음 역할 복귀를 2초 안에 실행',
      enNextPoint: 'After mistakes, execute next-role recovery within 2 seconds',
    ),
  ];
}

_BoardQuizQuestion _question({
  required String id,
  required int difficulty,
  required _BoardQuestionType type,
  _BoardQuizTemplate template = _BoardQuizTemplate.oneStep,
  required TrainingMethodPage scene,
  required String koCaption,
  required String enCaption,
  required String koQuestion,
  required String enQuestion,
  required List<_BoardQuizOption> options,
  required int correctIndex,
  required String koExplain,
  required String enExplain,
  String koNextPoint = '',
  String enNextPoint = '',
}) {
  return _BoardQuizQuestion(
    id: id,
    difficulty: difficulty,
    type: type,
    template: template,
    page: scene,
    koCaption: koCaption,
    enCaption: enCaption,
    koQuestion: koQuestion,
    enQuestion: enQuestion,
    options: options,
    correctIndex: correctIndex,
    koExplain: koExplain,
    enExplain: enExplain,
    koNextPoint: koNextPoint,
    enNextPoint: enNextPoint,
  );
}

List<TrainingMethodPage> _sceneTemplates() {
  return <TrainingMethodPage>[
    _scene(
      name: 's1',
      attackers: const [
        Offset(0.18, 0.74),
        Offset(0.40, 0.62),
        Offset(0.66, 0.45),
      ],
      defenders: const [
        Offset(0.34, 0.56),
        Offset(0.56, 0.50),
      ],
      ball: const Offset(0.18, 0.74),
      playerPath: const [
        Offset(0.40, 0.62),
        Offset(0.56, 0.50),
        Offset(0.66, 0.45)
      ],
      ballPath: const [Offset(0.18, 0.74), Offset(0.40, 0.62)],
    ),
    _scene(
      name: 's2',
      attackers: const [
        Offset(0.16, 0.24),
        Offset(0.30, 0.46),
        Offset(0.60, 0.62),
      ],
      defenders: const [
        Offset(0.28, 0.30),
        Offset(0.46, 0.54),
      ],
      ball: const Offset(0.30, 0.46),
      playerPath: const [
        Offset(0.30, 0.46),
        Offset(0.46, 0.40),
        Offset(0.60, 0.62)
      ],
      ballPath: const [Offset(0.30, 0.46), Offset(0.60, 0.62)],
    ),
    _scene(
      name: 's3',
      attackers: const [
        Offset(0.20, 0.70),
        Offset(0.42, 0.58),
        Offset(0.74, 0.44),
      ],
      defenders: const [
        Offset(0.38, 0.62),
        Offset(0.58, 0.50),
      ],
      ball: const Offset(0.42, 0.58),
      playerPath: const [
        Offset(0.42, 0.58),
        Offset(0.58, 0.52),
        Offset(0.74, 0.44)
      ],
      ballPath: const [Offset(0.42, 0.58), Offset(0.74, 0.44)],
    ),
    _scene(
      name: 's4',
      attackers: const [
        Offset(0.22, 0.68),
        Offset(0.40, 0.64),
        Offset(0.58, 0.56),
      ],
      defenders: const [
        Offset(0.46, 0.64),
        Offset(0.64, 0.58),
      ],
      ball: const Offset(0.22, 0.68),
      playerPath: const [Offset(0.40, 0.64), Offset(0.58, 0.56)],
      ballPath: const [Offset(0.22, 0.68), Offset(0.40, 0.64)],
    ),
    _scene(
      name: 's5',
      attackers: const [
        Offset(0.72, 0.42),
        Offset(0.54, 0.52),
        Offset(0.30, 0.64),
      ],
      defenders: const [
        Offset(0.62, 0.44),
        Offset(0.44, 0.56),
      ],
      ball: const Offset(0.72, 0.42),
      playerPath: const [Offset(0.54, 0.52), Offset(0.38, 0.62)],
      ballPath: const [Offset(0.72, 0.42), Offset(0.54, 0.52)],
    ),
    _scene(
      name: 's6',
      attackers: const [
        Offset(0.18, 0.30),
        Offset(0.38, 0.44),
        Offset(0.64, 0.56),
      ],
      defenders: const [
        Offset(0.34, 0.36),
        Offset(0.52, 0.50),
      ],
      ball: const Offset(0.18, 0.30),
      playerPath: const [
        Offset(0.38, 0.44),
        Offset(0.52, 0.50),
        Offset(0.64, 0.56)
      ],
      ballPath: const [Offset(0.18, 0.30), Offset(0.38, 0.44)],
    ),
    _scene(
      name: 's7',
      attackers: const [
        Offset(0.14, 0.64),
        Offset(0.28, 0.50),
        Offset(0.52, 0.38),
      ],
      defenders: const [
        Offset(0.34, 0.50),
        Offset(0.48, 0.42),
      ],
      ball: const Offset(0.14, 0.64),
      playerPath: const [Offset(0.28, 0.50), Offset(0.52, 0.38)],
      ballPath: const [Offset(0.14, 0.64), Offset(0.28, 0.50)],
    ),
    _scene(
      name: 's8',
      attackers: const [
        Offset(0.24, 0.72),
        Offset(0.40, 0.62),
        Offset(0.60, 0.48),
      ],
      defenders: const [
        Offset(0.46, 0.58),
        Offset(0.64, 0.50),
      ],
      ball: const Offset(0.24, 0.72),
      playerPath: const [
        Offset(0.40, 0.62),
        Offset(0.52, 0.56),
        Offset(0.60, 0.48)
      ],
      ballPath: const [Offset(0.24, 0.72), Offset(0.40, 0.62)],
    ),
  ];
}

TrainingMethodPage _scene({
  required String name,
  required List<Offset> attackers,
  required List<Offset> defenders,
  required Offset ball,
  required List<Offset> playerPath,
  required List<Offset> ballPath,
}) {
  final items = <TrainingMethodItem>[
    ...attackers.map(
      (point) => TrainingMethodItem(
        type: 'player',
        x: point.dx,
        y: point.dy,
        size: 34,
        colorValue: 0xFFB3E5FC,
      ),
    ),
    ...defenders.map(
      (point) => TrainingMethodItem(
        type: 'player',
        x: point.dx,
        y: point.dy,
        size: 34,
        colorValue: 0xFFFFCCBC,
      ),
    ),
    TrainingMethodItem(
      type: 'ball',
      x: ball.dx,
      y: ball.dy,
      size: 28,
      colorValue: 0xFFFFF8E1,
    ),
  ];

  final strokes = <TrainingMethodStroke>[
    TrainingMethodStroke(
      points: [
        ...playerPath
            .map((point) => TrainingMethodPoint(x: point.dx, y: point.dy)),
      ],
      colorValue: 0xFF43A047,
      width: 3.4,
    ),
    TrainingMethodStroke(
      points: [
        ...ballPath
            .map((point) => TrainingMethodPoint(x: point.dx, y: point.dy)),
      ],
      colorValue: 0xFF1E88E5,
      width: 3.0,
    ),
  ];

  return TrainingMethodPage(
    name: name,
    items: items,
    strokes: strokes,
    playerPath: playerPath
        .map((point) => TrainingMethodPoint(x: point.dx, y: point.dy))
        .toList(growable: false),
    ballPath: ballPath
        .map((point) => TrainingMethodPoint(x: point.dx, y: point.dy))
        .toList(growable: false),
  );
}

int _stableHash(String text) {
  var hash = 0;
  for (final code in text.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return hash;
}
