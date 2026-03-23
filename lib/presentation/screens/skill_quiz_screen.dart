import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../application/player_profile_service.dart';
import '../../domain/repositories/option_repository.dart';

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
  static const String categoryStatsKey = 'skill_quiz_category_stats_v1';

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
    final pendingDueCount = pending
        .where((item) => !item.dueAt.isAfter(now))
        .length;

    final rawCompletedAt = optionRepository.getValue<String>(completionKey);
    final completedAt = rawCompletedAt == null
        ? null
        : DateTime.tryParse(rawCompletedAt);
    final completedToday =
        completedAt != null &&
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

class _SkillQuizScreenState extends State<SkillQuizScreen> {
  static const int _dailyCount = 10;
  static const int _reviewCount = 10;
  static const int _challengeCount = 10;
  static const int _focusCount = 8;
  static const int _speedCount = 10;
  static const int _speedLimitSec = 12;

  late final Map<String, _FootballQuizQuestion> _questionMap;
  late final List<_FootballQuizQuestion> _allQuestions;
  late final PlayerProfileService _profileService;
  _QuizSessionSnapshot? _pendingResumeSnapshot;
  late SkillQuizResumeSummary _resumeSummary;

  List<_FootballQuizQuestion> _questions = const <_FootballQuizQuestion>[];
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
  final TextEditingController _shortAnswerController = TextEditingController();

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
    _allQuestions = _buildFootballQuizPool();
    _questionMap = {
      for (final question in _allQuestions) question.id: question,
    };
    _profileService = PlayerProfileService(widget.optionRepository);
    _resumeSummary = SkillQuizScreen.loadResumeSummary(widget.optionRepository);
    _pendingResumeSnapshot = _QuizSessionSnapshot.tryParse(
      widget.optionRepository.getValue<String>(SkillQuizScreen.sessionKey),
    );
  }

  @override
  void dispose() {
    _speedTimer?.cancel();
    _shortAnswerController.dispose();
    super.dispose();
  }

  void _refreshResumeSummary() {
    _resumeSummary = SkillQuizScreen.loadResumeSummary(widget.optionRepository);
  }

  Future<void> _selectEntryMode(_QuizEntryAction action) async {
    switch (action) {
      case _QuizEntryAction.resume:
        final snapshot = _pendingResumeSnapshot;
        if (snapshot != null) {
          _applySnapshot(snapshot);
        }
        return;
      case _QuizEntryAction.daily:
        _startDailySession();
        return;
      case _QuizEntryAction.review:
        _startReviewSessionFromQueue();
        return;
      case _QuizEntryAction.challenge:
        _startChallengeSession();
        return;
      case _QuizEntryAction.focus:
        _startFocusSession();
        return;
      case _QuizEntryAction.speed:
        _startSpeedSession();
        return;
    }
  }

  void _applySnapshot(_QuizSessionSnapshot snapshot) {
    final questions = snapshot.questionIds
        .map((id) => _questionMap[id])
        .whereType<_FootballQuizQuestion>()
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
    _shortAnswerController.clear();
    _pendingResumeSnapshot = snapshot;

    if (!_finished) {
      _startQuestionClock();
    }
  }

  void _startDailySession() {
    final token = _todayToken();
    final savedToken = widget.optionRepository.getValue<String>(
      SkillQuizScreen.dailyQuestionsDayKey,
    );
    if (savedToken == token) {
      final savedIds = _decodeStringList(
        widget.optionRepository.getValue<String>(
          SkillQuizScreen.dailyQuestionsKey,
        ),
      );
      final savedQuestions = savedIds
          .map((id) => _questionMap[id])
          .whereType<_FootballQuizQuestion>()
          .toList(growable: false);
      if (savedQuestions.isNotEmpty) {
        _startSession(questions: savedQuestions, mode: _QuizMode.daily);
        return;
      }
    }

    final random = math.Random(_stableHash(token));
    final picked = _pickDailyQuestions(random);
    unawaited(
      widget.optionRepository.setValue(
        SkillQuizScreen.dailyQuestionsDayKey,
        token,
      ),
    );
    unawaited(
      widget.optionRepository.setValue(
        SkillQuizScreen.dailyQuestionsKey,
        jsonEncode(picked.map((q) => q.id).toList(growable: false)),
      ),
    );
    _startSession(questions: picked, mode: _QuizMode.daily);
  }

  void _startChallengeSession() {
    final random = math.Random(DateTime.now().microsecondsSinceEpoch);
    final picked = _pickAdaptiveQuestions(
      source: _allQuestions,
      count: _challengeCount,
      random: random,
    );
    _startSession(questions: picked, mode: _QuizMode.challenge);
  }

  void _startFocusSession() {
    final personalization = _buildPersonalization();
    final targetCategory =
        personalization.weakestCategory ?? personalization.recommendedCategory;
    final random = math.Random(DateTime.now().microsecondsSinceEpoch);
    final focusedSource = _allQuestions
        .where((question) => question.category == targetCategory)
        .toList(growable: false);
    final picked = _pickAdaptiveQuestions(
      source: focusedSource.isEmpty ? _allQuestions : focusedSource,
      count: _focusCount,
      random: random,
    );
    _startSession(questions: picked, mode: _QuizMode.focus);
  }

  void _startSpeedSession() {
    final random = math.Random(DateTime.now().microsecondsSinceEpoch);
    final source = _allQuestions
        .where((question) => question.style == _QuestionStyle.multipleChoice)
        .toList(growable: false);
    final picked = _pickAdaptiveQuestions(
      source: source.isEmpty ? _allQuestions : source,
      count: _speedCount,
      random: random,
    );
    _startSession(questions: picked, mode: _QuizMode.speed);
  }

  void _startReviewSessionFromQueue() {
    final due = _loadDueReviewQuestions();
    if (due.isEmpty) {
      final isKo = Localizations.localeOf(context).languageCode == 'ko';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isKo
                ? '지금 바로 복습할 오답이 없어요.'
                : 'There are no due wrong answers right now.',
          ),
        ),
      );
      return;
    }
    _startSession(
      questions: due.take(_reviewCount).toList(growable: false),
      mode: _QuizMode.review,
      clearDueReview: true,
    );
  }

  void _startSession({
    required List<_FootballQuizQuestion> questions,
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
    _shortAnswerController.clear();
    _pendingResumeSnapshot = null;

    if (clearDueReview) {
      unawaited(_removeDueReviewQuestions(questions));
    }

    unawaited(_trackMetric('football_quiz_session_started'));
    _startQuestionClock();
    unawaited(_persistSession());
  }

  void _startQuestionClock() {
    _questionStartedAt = DateTime.now();
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
    unawaited(_trackMetric('football_question_timeout'));
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
      unawaited(_trackMetric('football_option_selected'));
      unawaited(_persistSession());
      return;
    }

    _onAnswerResolved(
      choice: choice,
      correct: false,
      wrongQuestionId: question.id,
    );
  }

  void _submitShortAnswer() {
    if (_finished || _answered || _questions.isEmpty) return;
    final question = _questions[_index];
    if (question.style != _QuestionStyle.shortAnswer) return;
    final raw = _shortAnswerController.text.trim();
    if (raw.isEmpty) return;

    final normalizedInput = _normalizeShortAnswer(raw);
    final isCorrect = question.acceptedAnswers.any(
      (answer) => _normalizeShortAnswer(answer) == normalizedInput,
    );

    if (isCorrect) {
      _onAnswerResolved(choice: 0, correct: true);
      return;
    }

    if (!_retryUsed) {
      setState(() {
        _retryUsed = true;
        _retryFeedback = 'incorrect';
      });
      unawaited(_trackMetric('football_option_selected'));
      unawaited(_persistSession());
      return;
    }

    _onAnswerResolved(choice: 0, correct: false, wrongQuestionId: question.id);
  }

  String _normalizeShortAnswer(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^a-z0-9가-힣]'), '');
  }

  void _onAnswerResolved({
    required int choice,
    required bool correct,
    String? wrongQuestionId,
  }) {
    _speedTimer?.cancel();
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

    unawaited(_trackMetric('football_option_selected'));
    unawaited(_trackMetric('football_answer_evaluated'));
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
      unawaited(_trackMetric('football_next_without_second_try'));
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
    _shortAnswerController.clear();

    _startQuestionClock();
    await _persistSession();
  }

  Future<void> _completeSession() async {
    final wrongQuestions = _questions
        .where((question) => _wrongIds.contains(question.id))
        .toList(growable: false);

    await _scheduleReviewQuestions(wrongQuestions);
    await _recordRecentPerformance();
    await _recordCategoryPerformance();
    await _trackMetric('football_quiz_session_completed');

    await widget.optionRepository.setValue(
      SkillQuizScreen.completionKey,
      DateTime.now().toIso8601String(),
    );
    await widget.optionRepository.setValue(SkillQuizScreen.sessionKey, '');
    _refreshResumeSummary();

    if (!mounted) return;
    setState(() {
      _finished = true;
      _speedTimer?.cancel();
      _pendingResumeSnapshot = null;
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
              title: Text(isKo ? '오늘의 축구 퀴즈' : 'Daily football quiz'),
              subtitle: Text(isKo ? '오늘 고정 세트' : 'Fixed set for today'),
              onTap: () => Navigator.of(context).pop(_QuizMode.daily),
            ),
            ListTile(
              leading: const Icon(Icons.sports_soccer_outlined),
              title: Text(isKo ? '챌린지 모드' : 'Challenge mode'),
              subtitle: Text(isKo ? '분야 섞인 10문제' : 'Mixed set of 10 questions'),
              onTap: () => Navigator.of(context).pop(_QuizMode.challenge),
            ),
            ListTile(
              leading: const Icon(Icons.center_focus_strong_outlined),
              title: Text(isKo ? '약점 집중 모드' : 'Focus mode'),
              subtitle: Text(
                isKo
                    ? '약한 카테고리 중심 8문제'
                    : '8 questions around your weak category',
              ),
              onTap: () => Navigator.of(context).pop(_QuizMode.focus),
            ),
            ListTile(
              leading: const Icon(Icons.speed_outlined),
              title: Text(isKo ? '스피드 모드' : 'Speed mode'),
              subtitle: Text(
                isKo
                    ? '문항당 $_speedLimitSec초 제한'
                    : '$_speedLimitSec s per question',
              ),
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
      case _QuizMode.challenge:
        _startChallengeSession();
        return;
      case _QuizMode.focus:
        _startFocusSession();
        return;
      case _QuizMode.speed:
        _startSpeedSession();
        return;
    }
  }

  bool get _showEntryHubBackButton => _questions.isNotEmpty || _finished;

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return PopScope(
      canPop: !_showEntryHubBackButton,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !_showEntryHubBackButton) return;
        unawaited(_openEntryHub());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _showEntryHubBackButton
              ? IconButton(
                  onPressed: _openEntryHub,
                  tooltip: isKo ? '퀴즈 홈으로' : 'Back to quiz home',
                  icon: const Icon(Icons.arrow_back),
                )
              : null,
          title: Text(isKo ? '축구 퀴즈' : 'Football Quiz'),
          actions: [
            IconButton(
              onPressed: _openModeMenu,
              tooltip: isKo ? '퀴즈 모드 선택' : 'Choose quiz mode',
              icon: const Icon(Icons.tune_outlined),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: _questions.isEmpty && !_finished
                ? _buildEntryHub(isKo)
                : (_finished ? _buildResult(isKo) : _buildQuestion(isKo)),
          ),
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
    final canGoNext = _answered || _retryUsed;
    final heroOverlay = _buildHeroOverlay(question, isKo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(label: _mode.label(isKo)),
            _InfoChip(
              label: isKo ? '진행 $progressText' : 'Progress $progressText',
            ),
            _InfoChip(
              label: isKo
                  ? '미션 ${math.min(_score, missionTarget)}/$missionTarget'
                  : 'Mission ${math.min(_score, missionTarget)}/$missionTarget',
            ),
            if (_mode == _QuizMode.speed)
              _InfoChip(
                label: isKo ? '⏱ ${_speedLeft}s' : '⏱ ${_speedLeft}s',
                danger: _speedLeft <= 3,
              ),
          ],
        ),
        if (_answerFx != _AnswerFx.none) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: _AnswerFxBadge(fx: _answerFx, isKo: isKo),
          ),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _QuestionHeroCard(
                  question: question,
                  isKo: isKo,
                  overlay: heroOverlay,
                  explanationText: (_answered || _retryUsed)
                      ? question.explainText(isKo)
                      : (isKo
                            ? '정답을 고르면 여기에서 바로 설명을 볼 수 있어요.'
                            : 'The explanation will appear here right after you answer.'),
                ),
                const SizedBox(height: 12),
                if (question.style == _QuestionStyle.shortAnswer)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _shortAnswerController,
                          enabled: !_answered,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submitShortAnswer(),
                          decoration: InputDecoration(
                            hintText: isKo ? '정답을 입력하세요' : 'Type your answer',
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: _answered ? null : _submitShortAnswer,
                          child: Text(isKo ? '정답 확인' : 'Check answer'),
                        ),
                      ],
                    ),
                  )
                else
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
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color:
                            bgColor ??
                            Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _selectAnswer(optionIndex),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    borderColor ??
                                    Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                width: borderColor == null ? 1.0 : 1.6,
                              ),
                            ),
                            child: Row(
                              children: [
                                _OptionBadge(
                                  label: question.style == _QuestionStyle.ox
                                      ? option.text(isKo)
                                      : _optionLabel(optionIndex),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    option.text(isKo),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
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
                    isKo ? '틀렸어요. 한 번 더 고를 수 있어요.' : 'Incorrect. One more try.',
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
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isKo ? '정답 포인트' : 'Answer insight',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          question.explainText(isKo),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isKo
                              ? '다음에 볼 포인트: ${question.nextPoint(true)}'
                              : 'Next focus: ${question.nextPoint(false)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w800),
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
  }

  Widget _buildResult(bool isKo) {
    final total = _questions.length;
    final accuracy = total == 0 ? 0 : ((_score / total) * 100).round();
    final avgResponse = _answerCount == 0
        ? 0
        : ((_responseMillisSum / _answerCount) / 1000).toStringAsFixed(1);
    final recap = _buildResultRecap();
    final categoryStats = _sessionCategoryStats();

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
                  isKo ? '축구 퀴즈 결과' : 'Football Quiz Result',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
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
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isKo ? '코치 해설' : 'Coach recap',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recap.summary(isKo),
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recap.nextAction(isKo),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categoryStats.entries
                      .map(
                        (entry) => _InfoChip(
                          label: isKo
                              ? '${entry.key.label(true)} ${entry.value.correct}/${entry.value.total}'
                              : '${entry.key.label(false)} ${entry.value.correct}/${entry.value.total}',
                        ),
                      )
                      .toList(growable: false),
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
                  onPressed: _startChallengeSession,
                  icon: const Icon(Icons.sports_soccer_outlined),
                  label: Text(isKo ? '챌린지 모드' : 'Challenge mode'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _startFocusSession,
                  icon: const Icon(Icons.center_focus_strong_outlined),
                  label: Text(isKo ? '약점 집중 모드' : 'Focus mode'),
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

  Future<void> _openEntryHub() async {
    _speedTimer?.cancel();
    if (_questions.isNotEmpty && !_finished) {
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
      _pendingResumeSnapshot = snapshot;
      await widget.optionRepository.setValue(
        SkillQuizScreen.sessionKey,
        snapshot.encode(),
      );
    }
    _refreshResumeSummary();
    if (!mounted) return;
    setState(() {
      _questions = const <_FootballQuizQuestion>[];
      _finished = false;
      _selectedIndex = null;
      _answered = false;
      _retryUsed = false;
      _retryFeedback = null;
      _answerFx = _AnswerFx.none;
      _index = 0;
      _score = 0;
      _streak = 0;
      _combo = 0;
      _momentum = 0;
      _speedLeft = _speedLimitSec;
    });
    _shortAnswerController.clear();
  }

  _QuizHeroOverlayData _buildHeroOverlay(
    _FootballQuizQuestion question,
    bool isKo,
  ) {
    final accent = switch (question.category) {
      _QuizCategory.rules => const Color(0xFF1565C0),
      _QuizCategory.tactics => const Color(0xFF2E7D32),
      _QuizCategory.technique => const Color(0xFF6A1B9A),
      _QuizCategory.positions => const Color(0xFFE65100),
      _QuizCategory.training => const Color(0xFF00838F),
      _QuizCategory.mindset => const Color(0xFFAD1457),
      _QuizCategory.nutrition => const Color(0xFF558B2F),
      _QuizCategory.fun => const Color(0xFF5D4037),
    };

    if (_mode == _QuizMode.speed && !_answered) {
      if (_speedLeft <= 3) {
        return _QuizHeroOverlayData(
          title: isKo ? '지금 판단' : 'Decide now',
          subtitle: isKo ? '$_speedLeft초 남았어요' : '$_speedLeft seconds left',
          accent: const Color(0xFFD9480F),
        );
      }
      return _QuizHeroOverlayData(
        title: isKo ? '순간 판단' : 'Quick read',
        subtitle: isKo ? '스피드 모드 진행 중' : 'Speed mode is active',
        accent: const Color(0xFF0B7285),
      );
    }
    if (_retryFeedback == 'incorrect' && !_answered) {
      return _QuizHeroOverlayData(
        title: isKo ? '한 번 더' : 'One more try',
        subtitle: isKo ? '이번에는 핵심 단어를 보세요' : 'Focus on the key cue this time',
        accent: const Color(0xFFC92A2A),
      );
    }
    if (_mode == _QuizMode.review) {
      return _QuizHeroOverlayData(
        title: isKo ? '복습 집중' : 'Review focus',
        subtitle: isKo ? '24시간 지난 오답을 다시 잡아요' : 'Clean up your delayed misses',
        accent: const Color(0xFF5F3DC4),
      );
    }
    if (_answerFx == _AnswerFx.success && _combo >= 2) {
      return _QuizHeroOverlayData(
        title: isKo ? '콤보 x$_combo' : 'Combo x$_combo',
        subtitle: isKo ? '좋은 흐름을 유지 중이에요' : 'You are holding a good rhythm',
        accent: const Color(0xFF099268),
      );
    }
    if (_momentum >= 60) {
      return _QuizHeroOverlayData(
        title: isKo ? '모멘텀 상승' : 'Momentum up',
        subtitle: isKo
            ? '판단 속도와 정확도가 같이 올라가고 있어요'
            : 'Speed and accuracy are rising together',
        accent: const Color(0xFF1971C2),
      );
    }
    return _QuizHeroOverlayData(
      title: question.category.label(isKo),
      subtitle: question.difficultyLabel(isKo),
      accent: accent,
    );
  }

  Widget _buildEntryHub(bool isKo) {
    final personalization = _buildPersonalization();
    final actions = <_QuizEntryCardData>[
      if (_resumeSummary.hasActiveSession && _pendingResumeSnapshot != null)
        _QuizEntryCardData(
          action: _QuizEntryAction.resume,
          icon: Icons.play_circle_fill_outlined,
          title: isKo ? '이어하기' : 'Resume',
          subtitle: isKo
              ? '${_resumeSummary.currentIndex + 1}/${_resumeSummary.totalQuestions} 진행 중'
              : 'Continue ${_resumeSummary.currentIndex + 1}/${_resumeSummary.totalQuestions}',
          badge: _resumeSummary.reviewMode
              ? (isKo ? '복습 세션' : 'Review session')
              : (isKo ? '진행 중' : 'In progress'),
        ),
      _QuizEntryCardData(
        action: _QuizEntryAction.daily,
        icon: Icons.today_outlined,
        title: isKo ? '오늘의 문제' : 'Today set',
        subtitle: _resumeSummary.completedToday
            ? (isKo ? '오늘 세트를 다시 풀어요' : 'Replay today’s set')
            : (isKo
                  ? '오늘 10문제 세트, 지난 오답도 1~2문제 섞여 나와요'
                  : 'Play today’s 10-question set with 1-2 past wrong answers mixed in'),
        badge: isKo ? '기본 추천' : 'Recommended',
      ),
      _QuizEntryCardData(
        action: _QuizEntryAction.challenge,
        icon: Icons.sports_soccer_outlined,
        title: isKo ? '다른 스타일 풀기' : 'Challenge mix',
        subtitle: isKo ? '분야를 섞은 적응형 10문제' : 'Adaptive mixed set of 10',
        badge: isKo ? '새 문제 흐름' : 'Fresh mix',
      ),
      _QuizEntryCardData(
        action: _QuizEntryAction.focus,
        icon: Icons.center_focus_strong_outlined,
        title: isKo ? '약점 집중' : 'Focus mode',
        subtitle: isKo
            ? '${personalization.recommendedCategory.label(true)} 중심으로 8문제를 풀어요'
            : 'Play 8 questions focused on ${personalization.recommendedCategory.label(false)}',
        badge: isKo ? '개인화 추천' : 'Personalized',
      ),
      _QuizEntryCardData(
        action: _QuizEntryAction.speed,
        icon: Icons.speed_outlined,
        title: isKo ? '스피드 모드' : 'Speed mode',
        subtitle: isKo
            ? '문항당 $_speedLimitSec초 안에 답하기'
            : 'Answer within $_speedLimitSec seconds each',
        badge: isKo ? '빠른 판단' : 'Fast decisions',
      ),
    ];

    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isKo ? '오늘의 퀴즈 시작' : 'Start today’s quiz',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isKo
                    ? '오늘 문제를 다시 풀지, 다른 스타일로 풀지, 약점 분야를 파고들지 고르세요.'
                    : 'Choose whether to replay today, try a different mode, or drill into your weakest area.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              _QuizCoachBanner(
                title: isKo ? '오늘 추천' : 'Today recommendation',
                subtitle: personalization.heroSubtitle(isKo),
                detail: personalization.heroDetail(isKo),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...actions.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _QuizEntryCard(
              data: item,
              onTap: () => _selectEntryMode(item.action),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _persistSession() async {
    if (_finished || _questions.isEmpty) {
      await widget.optionRepository.setValue(SkillQuizScreen.sessionKey, '');
      _refreshResumeSummary();
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
    _pendingResumeSnapshot = snapshot;
    _refreshResumeSummary();
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
    final avgSec = _answerCount == 0
        ? 8.0
        : (_responseMillisSum / _answerCount) / 1000;
    final perf = _RecentPerformance(accuracy: accuracy, avgSeconds: avgSec);
    await widget.optionRepository.setValue(
      SkillQuizScreen.recentPerformanceKey,
      perf.encode(),
    );
  }

  Future<void> _recordCategoryPerformance() async {
    if (_questions.isEmpty) return;
    final current = _QuizCategoryAggregate.decodeMap(
      widget.optionRepository.getValue<String>(
        SkillQuizScreen.categoryStatsKey,
      ),
    );
    final session = _sessionCategoryStats();
    for (final entry in session.entries) {
      final previous = current[entry.key] ?? const _QuizCategoryAggregate();
      current[entry.key] = previous.merge(entry.value);
    }
    await widget.optionRepository.setValue(
      SkillQuizScreen.categoryStatsKey,
      _QuizCategoryAggregate.encodeMap(current),
    );
  }

  Map<_QuizCategory, _QuizCategoryAggregate> _sessionCategoryStats() {
    final stats = <_QuizCategory, _QuizCategoryAggregate>{};
    for (final question in _questions) {
      final previous =
          stats[question.category] ?? const _QuizCategoryAggregate();
      stats[question.category] = previous.addResult(
        correct: !_wrongIds.contains(question.id),
      );
    }
    return stats;
  }

  _QuizResultRecap _buildResultRecap() {
    final stats = _sessionCategoryStats();
    _QuizCategory? strongest;
    _QuizCategory? weakest;
    double strongestScore = -1;
    double weakestScore = 2;
    for (final entry in stats.entries) {
      final accuracy = entry.value.accuracy;
      if (accuracy > strongestScore) {
        strongestScore = accuracy;
        strongest = entry.key;
      }
      if (accuracy < weakestScore) {
        weakestScore = accuracy;
        weakest = entry.key;
      }
    }
    return _QuizResultRecap(
      strongestCategory: strongest,
      weakestCategory: weakest,
      score: _score,
      total: _questions.length,
      bestCombo: _bestComboRun,
      timeouts: _timeouts,
    );
  }

  _QuizPersonalization _buildPersonalization() {
    final profile = _profileService.load();
    final categoryStats = _QuizCategoryAggregate.decodeMap(
      widget.optionRepository.getValue<String>(
        SkillQuizScreen.categoryStatsKey,
      ),
    );
    _QuizCategory? weakest;
    double weakestScore = 2;
    for (final entry in categoryStats.entries) {
      if (entry.value.total < 2) continue;
      final accuracy = entry.value.accuracy;
      if (accuracy < weakestScore) {
        weakestScore = accuracy;
        weakest = entry.key;
      }
    }
    final recommended =
        weakest ?? _recommendedCategoryForPosition(profile.positionTestResult);
    return _QuizPersonalization(
      weakestCategory: weakest,
      recommendedCategory: recommended,
      positionLabel: profile.positionTestResult.trim(),
      dueReviewCount: _resumeSummary.pendingWrongCount,
    );
  }

  _QuizCategory _recommendedCategoryForPosition(String rawPosition) {
    final text = rawPosition.toLowerCase();
    if (text.contains('fw') ||
        text.contains('st') ||
        text.contains('윙') ||
        text.contains('striker') ||
        text.contains('forward')) {
      return _QuizCategory.technique;
    }
    if (text.contains('mf') ||
        text.contains('mid') ||
        text.contains('cm') ||
        text.contains('cam') ||
        text.contains('midfielder')) {
      return _QuizCategory.tactics;
    }
    if (text.contains('df') ||
        text.contains('cb') ||
        text.contains('fb') ||
        text.contains('defender') ||
        text.contains('수비')) {
      return _QuizCategory.positions;
    }
    if (text.contains('gk') || text.contains('goalkeeper')) {
      return _QuizCategory.rules;
    }
    return _QuizCategory.tactics;
  }

  List<_FootballQuizQuestion> _pickAdaptiveQuestions({
    required List<_FootballQuizQuestion> source,
    required int count,
    required math.Random random,
  }) {
    if (source.isEmpty) return const <_FootballQuizQuestion>[];

    final perf = _RecentPerformance.tryParse(
      widget.optionRepository.getValue<String>(
        SkillQuizScreen.recentPerformanceKey,
      ),
    );
    final targetDifficulty = perf?.targetDifficulty ?? 2;

    final easy = source.where((q) => q.difficulty == 1).toList(growable: false);
    final mid = source.where((q) => q.difficulty == 2).toList(growable: false);
    final hard = source.where((q) => q.difficulty == 3).toList(growable: false);

    final easyPool = [...easy]..shuffle(random);
    final midPool = [...mid]..shuffle(random);
    final hardPool = [...hard]..shuffle(random);

    final total = math.min(count, source.length);
    final hardRatio = targetDifficulty >= 3
        ? 0.45
        : (targetDifficulty <= 1 ? 0.15 : 0.30);
    final easyRatio = targetDifficulty <= 1
        ? 0.45
        : (targetDifficulty >= 3 ? 0.18 : 0.25);
    final midRatio = 1 - easyRatio - hardRatio;

    final needEasy = (total * easyRatio).round();
    final needMid = (total * midRatio).round();
    final needHard = total - needEasy - needMid;

    final picked = <_FootballQuizQuestion>[];
    void take(List<_FootballQuizQuestion> from, int need) {
      if (need <= 0) return;
      final takeCount = math.min(need, from.length);
      picked.addAll(from.take(takeCount));
      from.removeRange(0, takeCount);
    }

    take(easyPool, needEasy);
    take(midPool, needMid);
    take(hardPool, needHard);

    final remaining = <_FootballQuizQuestion>[
      ...easyPool,
      ...midPool,
      ...hardPool,
    ]..shuffle(random);
    if (picked.length < total) {
      picked.addAll(remaining.take(total - picked.length));
    }

    return picked..shuffle(random);
  }

  List<_FootballQuizQuestion> _pickDailyQuestions(math.Random random) {
    final mixedReview = _loadDueReviewQuestions().toList(growable: true)
      ..shuffle(random);
    final mixCount = math.min(mixedReview.length, 2);
    final reviewQuestions = <_FootballQuizQuestion>[];
    var reviewShortAnswerCount = 0;
    for (final question in mixedReview) {
      if (reviewQuestions.length >= mixCount) break;
      if (question.style == _QuestionStyle.shortAnswer &&
          reviewShortAnswerCount >= 1) {
        continue;
      }
      reviewQuestions.add(question);
      if (question.style == _QuestionStyle.shortAnswer) {
        reviewShortAnswerCount += 1;
      }
    }
    final excludedIds = reviewQuestions.map((question) => question.id).toSet();
    final remainingCount = math.max(0, _dailyCount - reviewQuestions.length);
    final ox =
        _allQuestions
            .where((q) => q.style == _QuestionStyle.ox)
            .where((q) => !excludedIds.contains(q.id))
            .toList(growable: false)
          ..shuffle(random);
    final mcq =
        _allQuestions
            .where((q) => q.style == _QuestionStyle.multipleChoice)
            .where((q) => !excludedIds.contains(q.id))
            .toList(growable: false)
          ..shuffle(random);
    final shortAnswer =
        _allQuestions
            .where((q) => q.style == _QuestionStyle.shortAnswer)
            .where((q) => !excludedIds.contains(q.id))
            .toList(growable: false)
          ..shuffle(random);
    final shortCount =
        (reviewShortAnswerCount == 0 &&
            remainingCount > 0 &&
            shortAnswer.isNotEmpty)
        ? 1
        : 0;
    final objectiveCount = remainingCount - shortCount;
    final oxCount = objectiveCount ~/ 2;
    final mcqCount = objectiveCount - oxCount;
    final picked = <_FootballQuizQuestion>[
      ...reviewQuestions,
      ...ox.take(oxCount),
      ...mcq.take(mcqCount),
      ...shortAnswer.take(shortCount),
    ];
    if (picked.length < _dailyCount) {
      final rest = <_FootballQuizQuestion>[
        ..._allQuestions.where(
          (q) => !picked.any((pickedQuestion) => pickedQuestion.id == q.id),
        ),
      ]..shuffle(random);
      picked.addAll(rest.take(_dailyCount - picked.length));
    }
    return picked.take(_dailyCount).toList(growable: false);
  }

  List<_FootballQuizQuestion> _loadDueReviewQuestions() {
    final scheduled = _ScheduledWrongItem.decodeList(
      widget.optionRepository.getValue<String>(
        SkillQuizScreen.pendingWrongScheduleKey,
      ),
    );
    final now = DateTime.now();
    final dueIds = scheduled
        .where((item) => !item.dueAt.isAfter(now))
        .map((item) => item.questionId)
        .toList(growable: false);
    return dueIds
        .map((id) => _questionMap[id])
        .whereType<_FootballQuizQuestion>()
        .toList(growable: false);
  }

  Future<void> _removeDueReviewQuestions(
    List<_FootballQuizQuestion> questions,
  ) async {
    if (questions.isEmpty) return;
    final ids = questions.map((q) => q.id).toSet();
    final current = _ScheduledWrongItem.decodeList(
      widget.optionRepository.getValue<String>(
        SkillQuizScreen.pendingWrongScheduleKey,
      ),
    );
    final next = current
        .where((item) => !ids.contains(item.questionId))
        .toList(growable: false);
    await widget.optionRepository.setValue(
      SkillQuizScreen.pendingWrongScheduleKey,
      _ScheduledWrongItem.encodeList(next),
    );
    await widget.optionRepository.setValue(
      SkillQuizScreen.pendingWrongQuestionsKey,
      '',
    );
  }

  Future<void> _scheduleReviewQuestions(
    List<_FootballQuizQuestion> wrongQuestions,
  ) async {
    final current = _ScheduledWrongItem.decodeList(
      widget.optionRepository.getValue<String>(
        SkillQuizScreen.pendingWrongScheduleKey,
      ),
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
    await widget.optionRepository.setValue(
      SkillQuizScreen.pendingWrongQuestionsKey,
      '',
    );
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

enum _QuizEntryAction { resume, daily, review, challenge, focus, speed }

enum _QuizMode { daily, review, challenge, focus, speed }

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
      case _QuizMode.challenge:
        return isKo ? '챌린지' : 'Challenge';
      case _QuizMode.focus:
        return isKo ? '집중' : 'Focus';
      case _QuizMode.speed:
        return isKo ? '스피드' : 'Speed';
    }
  }
}

enum _QuestionStyle { ox, multipleChoice, shortAnswer }

extension _QuestionStyleX on _QuestionStyle {
  String label(bool isKo) {
    switch (this) {
      case _QuestionStyle.ox:
        return isKo ? 'OX' : 'True/False';
      case _QuestionStyle.multipleChoice:
        return isKo ? '4지선다' : 'Multiple choice';
      case _QuestionStyle.shortAnswer:
        return isKo ? '주관식' : 'Short answer';
    }
  }
}

enum _QuizCategory {
  rules,
  tactics,
  technique,
  positions,
  training,
  mindset,
  nutrition,
  fun,
}

extension _QuizCategoryX on _QuizCategory {
  String label(bool isKo) {
    switch (this) {
      case _QuizCategory.rules:
        return isKo ? '규칙' : 'Rules';
      case _QuizCategory.tactics:
        return isKo ? '전술' : 'Tactics';
      case _QuizCategory.technique:
        return isKo ? '기술' : 'Technique';
      case _QuizCategory.positions:
        return isKo ? '포지션' : 'Positions';
      case _QuizCategory.training:
        return isKo ? '훈련' : 'Training';
      case _QuizCategory.mindset:
        return isKo ? '마인드' : 'Mindset';
      case _QuizCategory.nutrition:
        return isKo ? '영양/회복' : 'Nutrition';
      case _QuizCategory.fun:
        return isKo ? '재미 상식' : 'Fun facts';
    }
  }
}

class _FootballQuizQuestion {
  final String id;
  final int difficulty;
  final _QuestionStyle style;
  final _QuizCategory category;
  final String koPrompt;
  final String enPrompt;
  final List<_FootballQuizOption> options;
  final int correctIndex;
  final List<String> acceptedAnswers;
  final String koExplain;
  final String enExplain;
  final String koNextPoint;
  final String enNextPoint;

  const _FootballQuizQuestion({
    required this.id,
    required this.difficulty,
    required this.style,
    required this.category,
    required this.koPrompt,
    required this.enPrompt,
    required this.options,
    required this.correctIndex,
    this.acceptedAnswers = const <String>[],
    required this.koExplain,
    required this.enExplain,
    required this.koNextPoint,
    required this.enNextPoint,
  });

  String prompt(bool isKo) => isKo ? koPrompt : enPrompt;
  String explainText(bool isKo) => isKo ? koExplain : enExplain;
  String nextPoint(bool isKo) => isKo ? koNextPoint : enNextPoint;

  String difficultyLabel(bool isKo) {
    switch (difficulty) {
      case 1:
        return isKo ? '난이도 쉬움' : 'Easy';
      case 2:
        return isKo ? '난이도 보통' : 'Normal';
      default:
        return isKo ? '난이도 도전' : 'Hard';
    }
  }
}

class _FootballQuizOption {
  final String koText;
  final String enText;

  const _FootballQuizOption({required this.koText, required this.enText});

  String text(bool isKo) => isKo ? koText : enText;
}

class _QuizHeroOverlayData {
  final String title;
  final String subtitle;
  final Color accent;

  const _QuizHeroOverlayData({
    required this.title,
    required this.subtitle,
    required this.accent,
  });
}

class _QuestionHeroCard extends StatelessWidget {
  final _FootballQuizQuestion question;
  final bool isKo;
  final _QuizHeroOverlayData overlay;
  final String explanationText;

  const _QuestionHeroCard({
    required this.question,
    required this.isKo,
    required this.overlay,
    required this.explanationText,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = switch (question.category) {
      _QuizCategory.rules => const Color(0xFF1565C0),
      _QuizCategory.tactics => const Color(0xFF2E7D32),
      _QuizCategory.technique => const Color(0xFF6A1B9A),
      _QuizCategory.positions => const Color(0xFFE65100),
      _QuizCategory.training => const Color(0xFF00838F),
      _QuizCategory.mindset => const Color(0xFFAD1457),
      _QuizCategory.nutrition => const Color(0xFF558B2F),
      _QuizCategory.fun => const Color(0xFF5D4037),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.16), scheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isKo
                      ? '${question.category.label(true)} ${question.style.label(true)}'
                      : '${question.category.label(false)} ${question.style.label(false)}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: overlay.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: overlay.accent.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        overlay.title,
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: overlay.accent,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        overlay.subtitle,
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            question.prompt(isKo),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: scheme.surface.withValues(alpha: 0.82),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    explanationText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionBadge extends StatelessWidget {
  final String label;

  const _OptionBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _QuizEntryCardData {
  final _QuizEntryAction action;
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;

  const _QuizEntryCardData({
    required this.action,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
  });
}

class _QuizEntryCard extends StatelessWidget {
  final _QuizEntryCardData data;
  final VoidCallback? onTap;

  const _QuizEntryCard({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(data.icon, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.74),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      data.badge,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizCoachBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String detail;

  const _QuizCoachBanner({
    required this.title,
    required this.subtitle,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

String _optionLabel(int index) {
  switch (index) {
    case 0:
      return 'A';
    case 1:
      return 'B';
    case 2:
      return 'C';
    default:
      return 'D';
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final bool danger;

  const _InfoChip({required this.label, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bgColor = danger
        ? const Color(0x1AEB5757)
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
          color: danger ? const Color(0xFFC62828) : null,
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
      _AnswerFx.success => (Icons.check_circle, '', const Color(0xFF0FA968)),
      _AnswerFx.fail => (
        Icons.cancel,
        isKo ? '다시 보기' : 'Review',
        const Color(0xFFEB5757),
      ),
      _AnswerFx.timeout => (
        Icons.timer_off,
        isKo ? '시간 초과' : 'Time out',
        const Color(0xFFF57C00),
      ),
      _AnswerFx.none => (Icons.circle, '', Colors.transparent),
    };

    return Container(
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
          if (text.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
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
      final ids =
          (decoded['questionIds'] as List?)
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
        wrongIds:
            (decoded['wrongIds'] as List?)
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
            final lastWrongAt = DateTime.tryParse(
              map['lastWrongAt']?.toString() ?? '',
            );
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

class _QuizCategoryAggregate {
  final int total;
  final int correct;

  const _QuizCategoryAggregate({this.total = 0, this.correct = 0});

  double get accuracy => total == 0 ? 0 : correct / total;

  _QuizCategoryAggregate addResult({required bool correct}) {
    return _QuizCategoryAggregate(
      total: total + 1,
      correct: this.correct + (correct ? 1 : 0),
    );
  }

  _QuizCategoryAggregate merge(_QuizCategoryAggregate other) {
    return _QuizCategoryAggregate(
      total: total + other.total,
      correct: correct + other.correct,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'total': total,
    'correct': correct,
  };

  static String encodeMap(Map<_QuizCategory, _QuizCategoryAggregate> map) {
    return jsonEncode({
      for (final entry in map.entries) entry.key.name: entry.value.toMap(),
    });
  }

  static Map<_QuizCategory, _QuizCategoryAggregate> decodeMap(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return <_QuizCategory, _QuizCategoryAggregate>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <_QuizCategory, _QuizCategoryAggregate>{};
      final result = <_QuizCategory, _QuizCategoryAggregate>{};
      for (final category in _QuizCategory.values) {
        final value = decoded[category.name];
        if (value is! Map) continue;
        result[category] = _QuizCategoryAggregate(
          total: (value['total'] as num?)?.toInt() ?? 0,
          correct: (value['correct'] as num?)?.toInt() ?? 0,
        );
      }
      return result;
    } catch (_) {
      return <_QuizCategory, _QuizCategoryAggregate>{};
    }
  }
}

class _QuizPersonalization {
  final _QuizCategory? weakestCategory;
  final _QuizCategory recommendedCategory;
  final String positionLabel;
  final int dueReviewCount;

  const _QuizPersonalization({
    required this.weakestCategory,
    required this.recommendedCategory,
    required this.positionLabel,
    required this.dueReviewCount,
  });

  String heroSubtitle(bool isKo) {
    final category = weakestCategory ?? recommendedCategory;
    if (weakestCategory != null) {
      return isKo
          ? '약점 분야는 ${category.label(true)} 입니다.'
          : 'Your weakest area is ${category.label(false)}.';
    }
    if (positionLabel.trim().isNotEmpty) {
      return isKo
          ? '$positionLabel 기준 추천은 ${category.label(true)} 입니다.'
          : 'For $positionLabel, ${category.label(false)} is recommended.';
    }
    return isKo
        ? '오늘 추천 분야는 ${category.label(true)} 입니다.'
        : 'Today’s recommended area is ${category.label(false)}.';
  }

  String heroDetail(bool isKo) {
    if (dueReviewCount > 0) {
      return isKo
          ? '오답 복습이 $dueReviewCount개 대기 중입니다. 먼저 약점 집중으로 감을 올린 뒤 복습 모드로 이어가세요.'
          : '$dueReviewCount review items are waiting. Warm up in focus mode, then clear the review queue.';
    }
    return isKo
        ? '오늘 세트와 약점 집중 모드를 번갈아 풀면 학습 유지에 유리합니다.'
        : 'Alternating the daily set and focus mode helps learning stick.';
  }
}

class _QuizResultRecap {
  final _QuizCategory? strongestCategory;
  final _QuizCategory? weakestCategory;
  final int score;
  final int total;
  final int bestCombo;
  final int timeouts;

  const _QuizResultRecap({
    required this.strongestCategory,
    required this.weakestCategory,
    required this.score,
    required this.total,
    required this.bestCombo,
    required this.timeouts,
  });

  String summary(bool isKo) {
    final strongest =
        strongestCategory?.label(isKo) ?? (isKo ? '기본기' : 'basics');
    final weakest = weakestCategory?.label(isKo) ?? (isKo ? '기본기' : 'basics');
    if (score >= (total * 0.8).round()) {
      return isKo
          ? '$strongest 판단은 안정적이었습니다. 반면 $weakest 쪽은 한 번 더 정리하면 전체 흐름이 더 좋아집니다.'
          : '$strongest decisions were stable. Tightening up $weakest would improve the overall flow.';
    }
    return isKo
        ? '$weakest 판단에서 흔들림이 있었습니다. 대신 $strongest 쪽은 기준이 잡혀 있어 다음 세트의 중심축으로 쓰기 좋습니다.'
        : '$weakest was shakier today. $strongest is stable enough to anchor your next set.';
  }

  String nextAction(bool isKo) {
    final weakest = weakestCategory?.label(isKo) ?? (isKo ? '기본기' : 'basics');
    if (timeouts > 0) {
      return isKo
          ? '다음 액션: $weakest 중심의 집중 모드로 들어가고, 스피드 모드는 마지막에 다시 시도하세요.'
          : 'Next action: run a focus set on $weakest, then retry speed mode later.';
    }
    if (bestCombo >= 3) {
      return isKo
          ? '다음 액션: 집중 모드로 약점을 보강한 뒤 챌린지 모드로 확장하세요.'
          : 'Next action: sharpen the weak area in focus mode, then expand with challenge mode.';
    }
    return isKo
        ? '다음 액션: 오늘 세트 재도전보다 약점 집중 모드를 먼저 추천합니다.'
        : 'Next action: use focus mode before replaying the daily set.';
  }
}

class _OxFactSeed {
  final String id;
  final int difficulty;
  final _QuizCategory category;
  final String koTrueStatement;
  final String enTrueStatement;
  final String koFalseStatement;
  final String enFalseStatement;
  final String koExplain;
  final String enExplain;
  final String koNextPoint;
  final String enNextPoint;

  const _OxFactSeed({
    required this.id,
    required this.difficulty,
    required this.category,
    required this.koTrueStatement,
    required this.enTrueStatement,
    required this.koFalseStatement,
    required this.enFalseStatement,
    required this.koExplain,
    required this.enExplain,
    required this.koNextPoint,
    required this.enNextPoint,
  });
}

class _McqSeed {
  final String id;
  final int difficulty;
  final _QuizCategory category;
  final String koStem;
  final String enStem;
  final List<_FootballQuizOption> options;
  final int correctIndex;
  final String koExplain;
  final String enExplain;
  final String koNextPoint;
  final String enNextPoint;

  const _McqSeed({
    required this.id,
    required this.difficulty,
    required this.category,
    required this.koStem,
    required this.enStem,
    required this.options,
    required this.correctIndex,
    required this.koExplain,
    required this.enExplain,
    required this.koNextPoint,
    required this.enNextPoint,
  });
}

class _ShortAnswerSeed {
  final String id;
  final int difficulty;
  final _QuizCategory category;
  final String koPrompt;
  final String enPrompt;
  final List<String> acceptedAnswers;
  final String koExplain;
  final String enExplain;
  final String koNextPoint;
  final String enNextPoint;

  const _ShortAnswerSeed({
    required this.id,
    required this.difficulty,
    required this.category,
    required this.koPrompt,
    required this.enPrompt,
    required this.acceptedAnswers,
    required this.koExplain,
    required this.enExplain,
    required this.koNextPoint,
    required this.enNextPoint,
  });
}

List<_FootballQuizQuestion> _buildFootballQuizPool() {
  final oxFacts = _buildOxSeedPool300();
  final mcqSeeds = _buildMcqSeedPool300();
  final shortSeeds = _buildShortAnswerSeedPool300();

  final questions = <_FootballQuizQuestion>[];

  for (var index = 0; index < oxFacts.length; index++) {
    final fact = oxFacts[index];
    final useTrue = index.isEven;
    questions.add(
      _FootballQuizQuestion(
        id: 'ox_${fact.id}',
        difficulty: fact.difficulty,
        style: _QuestionStyle.ox,
        category: fact.category,
        koPrompt: useTrue ? fact.koTrueStatement : fact.koFalseStatement,
        enPrompt: useTrue ? fact.enTrueStatement : fact.enFalseStatement,
        options: const [
          _FootballQuizOption(koText: 'O', enText: 'O'),
          _FootballQuizOption(koText: 'X', enText: 'X'),
        ],
        correctIndex: useTrue ? 0 : 1,
        koExplain: useTrue
            ? '${fact.koExplain} 그래서 정답은 O예요.'
            : '${fact.koExplain} 그래서 정답은 X예요.',
        enExplain: useTrue
            ? '${fact.enExplain} So the correct answer is O.'
            : '${fact.enExplain} So the correct answer is X.',
        koNextPoint: fact.koNextPoint,
        enNextPoint: fact.enNextPoint,
      ),
    );
  }

  for (final seed in mcqSeeds) {
    questions.add(
      _FootballQuizQuestion(
        id: 'mcq_${seed.id}',
        difficulty: seed.difficulty,
        style: _QuestionStyle.multipleChoice,
        category: seed.category,
        koPrompt: seed.koStem,
        enPrompt: seed.enStem,
        options: seed.options,
        correctIndex: seed.correctIndex,
        koExplain: seed.koExplain,
        enExplain: seed.enExplain,
        koNextPoint: seed.koNextPoint,
        enNextPoint: seed.enNextPoint,
      ),
    );
  }

  for (final seed in shortSeeds) {
    questions.add(
      _FootballQuizQuestion(
        id: 'sa_${seed.id}',
        difficulty: seed.difficulty,
        style: _QuestionStyle.shortAnswer,
        category: seed.category,
        koPrompt: seed.koPrompt,
        enPrompt: seed.enPrompt,
        options: const <_FootballQuizOption>[],
        correctIndex: 0,
        acceptedAnswers: seed.acceptedAnswers,
        koExplain: seed.koExplain,
        enExplain: seed.enExplain,
        koNextPoint: seed.koNextPoint,
        enNextPoint: seed.enNextPoint,
      ),
    );
  }

  if (questions.length != 900) {
    throw StateError('Football quiz pool must contain exactly 900 questions.');
  }
  return questions;
}

List<_OxFactSeed> _buildOxSeedPool300() {
  final base = _oxFacts();
  final contextKo = [
    '경기 시작 전 체크',
    '전반 중반 상황',
    '후반 종료 직전 상황',
    '코너킥 직후 상황',
    '역습 전개 상황',
    '수비 전환 상황',
    '압박 상황',
    '빌드업 상황',
    '골킥 연결 상황',
    '세트피스 수비 상황',
  ];
  final contextEn = [
    'pre-kickoff check',
    'mid-first-half scenario',
    'late-second-half scenario',
    'post-corner scenario',
    'counterattack scenario',
    'defensive transition scenario',
    'pressing scenario',
    'build-up scenario',
    'goal-kick sequence',
    'set-piece defense',
  ];
  final out = <_OxFactSeed>[];
  for (var i = 0; i < 300; i++) {
    final seed = base[i % base.length];
    final k = i % contextKo.length;
    out.add(
      _OxFactSeed(
        id: '${seed.id}_$i',
        difficulty: seed.difficulty,
        category: seed.category,
        koTrueStatement: '${seed.koTrueStatement} (${contextKo[k]})',
        enTrueStatement: '${seed.enTrueStatement} (${contextEn[k]})',
        koFalseStatement: '${seed.koFalseStatement} (${contextKo[k]})',
        enFalseStatement: '${seed.enFalseStatement} (${contextEn[k]})',
        koExplain: seed.koExplain,
        enExplain: seed.enExplain,
        koNextPoint: seed.koNextPoint,
        enNextPoint: seed.enNextPoint,
      ),
    );
  }
  return out;
}

List<_McqSeed> _buildMcqSeedPool300() {
  final base = _mcqSeeds();
  final contextKo = [
    '실전 기준',
    '훈련 기준',
    '경기장 기준',
    '코치 지시 기준',
    '기본기 기준',
    '수비 기준',
    '공격 기준',
    '전환 기준',
  ];
  final contextEn = [
    'match context',
    'training context',
    'on-pitch context',
    'coach instruction context',
    'fundamental context',
    'defending context',
    'attacking context',
    'transition context',
  ];
  final out = <_McqSeed>[];
  for (var i = 0; i < 300; i++) {
    final seed = base[i % base.length];
    final k = i % contextKo.length;
    out.add(
      _McqSeed(
        id: '${seed.id}_$i',
        difficulty: seed.difficulty,
        category: seed.category,
        koStem: '${seed.koStem} (${contextKo[k]})',
        enStem: '${seed.enStem} (${contextEn[k]})',
        options: seed.options,
        correctIndex: seed.correctIndex,
        koExplain: seed.koExplain,
        enExplain: seed.enExplain,
        koNextPoint: seed.koNextPoint,
        enNextPoint: seed.enNextPoint,
      ),
    );
  }
  return out;
}

List<_ShortAnswerSeed> _buildShortAnswerSeedPool300() {
  final keywords =
      <
        ({
          _QuizCategory category,
          String koClue,
          String enClue,
          String koAnswer,
          String enAnswer,
        })
      >[
        (
          category: _QuizCategory.rules,
          koClue: '손을 쓰지 못하는 기본 규칙의 이름',
          enClue: 'Basic rule name that forbids hand use',
          koAnswer: '핸들링',
          enAnswer: 'handling',
        ),
        (
          category: _QuizCategory.rules,
          koClue: '상대 진영에서 위치를 보는 반칙',
          enClue: 'Position-based offense in attacking half',
          koAnswer: '오프사이드',
          enAnswer: 'offside',
        ),
        (
          category: _QuizCategory.tactics,
          koClue: '공을 잃은 직후 바로 압박하는 전술',
          enClue: 'Immediate press right after losing the ball',
          koAnswer: '게겐프레싱',
          enAnswer: 'gegenpressing',
        ),
        (
          category: _QuizCategory.tactics,
          koClue: '공격에서 수비로 바뀌는 순간',
          enClue: 'Moment when attack turns into defense',
          koAnswer: '전환',
          enAnswer: 'transition',
        ),
        (
          category: _QuizCategory.technique,
          koClue: '공을 처음 받는 동작',
          enClue: 'First touch when receiving the ball',
          koAnswer: '퍼스트터치',
          enAnswer: 'first touch',
        ),
        (
          category: _QuizCategory.technique,
          koClue: '주변을 먼저 보고 판단하는 기술',
          enClue: 'Skill of checking surroundings before action',
          koAnswer: '스캐닝',
          enAnswer: 'scanning',
        ),
        (
          category: _QuizCategory.positions,
          koClue: '골대 앞 마지막 수비 포지션',
          enClue: 'Final defending position in front of goal',
          koAnswer: '골키퍼',
          enAnswer: 'goalkeeper',
        ),
        (
          category: _QuizCategory.positions,
          koClue: '측면 수비수 포지션',
          enClue: 'Wide defending position',
          koAnswer: '풀백',
          enAnswer: 'fullback',
        ),
        (
          category: _QuizCategory.training,
          koClue: '훈련 전 몸을 데우는 단계',
          enClue: 'Body-prep step before training',
          koAnswer: '워밍업',
          enAnswer: 'warm-up',
        ),
        (
          category: _QuizCategory.training,
          koClue: '훈련 후 몸을 천천히 내리는 단계',
          enClue: 'Step to gradually lower intensity after training',
          koAnswer: '쿨다운',
          enAnswer: 'cool-down',
        ),
        (
          category: _QuizCategory.mindset,
          koClue: '실수 후 바로 집중을 되찾는 태도',
          enClue: 'Attitude to regain focus right after mistakes',
          koAnswer: '리셋',
          enAnswer: 'reset',
        ),
        (
          category: _QuizCategory.nutrition,
          koClue: '경기 전후 가장 기본 회복 요소',
          enClue: 'Most basic recovery factor before/after match',
          koAnswer: '수분',
          enAnswer: 'hydration',
        ),
      ];
  final questionKoTemplates = [
    '빈칸에 들어갈 단어를 쓰세요: "{clue}"',
    '다음 설명에 맞는 용어를 입력하세요: "{clue}"',
    '한 단어로 답하세요: "{clue}"',
    '핵심 개념을 써보세요: "{clue}"',
    '정답 단어를 입력하세요: "{clue}"',
  ];
  final questionEnTemplates = [
    'Type the term that fits: "{clue}"',
    'Enter the key word for: "{clue}"',
    'Answer with one term: "{clue}"',
    'Write the concept term: "{clue}"',
    'Fill in the right word: "{clue}"',
  ];
  final out = <_ShortAnswerSeed>[];
  for (var i = 0; i < 300; i++) {
    final key = keywords[i % keywords.length];
    final t = i % questionKoTemplates.length;
    final koPrompt = questionKoTemplates[t].replaceAll('{clue}', key.koClue);
    final enPrompt = questionEnTemplates[t].replaceAll('{clue}', key.enClue);
    out.add(
      _ShortAnswerSeed(
        id: 'short_$i',
        difficulty: (i % 3) + 1,
        category: key.category,
        koPrompt: koPrompt,
        enPrompt: enPrompt,
        acceptedAnswers: [
          key.koAnswer,
          key.enAnswer,
          key.koAnswer.replaceAll(' ', ''),
          key.enAnswer.replaceAll(' ', ''),
        ],
        koExplain: '정답은 "${key.koAnswer}"입니다.',
        enExplain: 'The answer is "${key.enAnswer}".',
        koNextPoint: '용어를 알고 실제 장면에서 바로 연결해 보세요.',
        enNextPoint: 'Know the term, then connect it to real situations.',
      ),
    );
  }
  return out;
}

List<_OxFactSeed> _oxFacts() {
  return const [
    _OxFactSeed(
      id: 'offside_own_half',
      difficulty: 1,
      category: _QuizCategory.rules,
      koTrueStatement: '자기 진영에 있는 공격수는 오프사이드 반칙 대상이 아니다.',
      enTrueStatement:
          'An attacker in their own half cannot be penalized for offside.',
      koFalseStatement: '자기 진영에 있어도 수비수보다 앞서면 오프사이드다.',
      enFalseStatement:
          'An attacker can be offside even when standing in their own half.',
      koExplain: '오프사이드는 상대 진영에서만 성립합니다.',
      enExplain: 'Offside can only occur in the opponents’ half.',
      koNextPoint: '오프사이드 판단은 위치와 공이 나가는 순간을 함께 본다.',
      enNextPoint:
          'Read offside with both player position and the kick moment.',
    ),
    _OxFactSeed(
      id: 'throw_in_feet',
      difficulty: 1,
      category: _QuizCategory.rules,
      koTrueStatement: '스로인은 두 발이 터치라인 위나 바깥 지면에 닿은 상태에서 던져야 한다.',
      enTrueStatement:
          'A throw-in is taken with both feet on or outside the touchline.',
      koFalseStatement: '스로인은 발 한쪽만 닿아 있어도 되고, 머리 뒤를 거치지 않아도 된다.',
      enFalseStatement:
          'A throw-in is fine with only one foot down and no motion from behind the head.',
      koExplain: '스로인은 정해진 자세를 지켜야 정상 재개로 인정됩니다.',
      enExplain:
          'A legal throw-in requires the proper body position and action.',
      koNextPoint: '재개 규칙은 자세와 시작 위치까지 같이 익힌다.',
      enNextPoint:
          'Study restart laws with both posture and starting position.',
    ),
    _OxFactSeed(
      id: 'goal_kick_move',
      difficulty: 1,
      category: _QuizCategory.rules,
      koTrueStatement: '골킥은 공이 차여서 명확하게 움직이면 인플레이다.',
      enTrueStatement:
          'A goal kick is in play once the ball is kicked and clearly moves.',
      koFalseStatement: '골킥은 공이 페널티 지역을 완전히 벗어나야 인플레이다.',
      enFalseStatement:
          'A goal kick is only in play after the ball fully leaves the penalty area.',
      koExplain: '현재 규칙에서는 공이 차여 명확히 움직이는 시점이 중요합니다.',
      enExplain:
          'Under the current law, the ball is in play once it is kicked and clearly moves.',
      koNextPoint: '예전 규칙과 현재 규칙 차이도 같이 기억한다.',
      enNextPoint: 'Remember the difference between old and current laws.',
    ),
    _OxFactSeed(
      id: 'direct_free_kick',
      difficulty: 1,
      category: _QuizCategory.rules,
      koTrueStatement: '직접 프리킥은 다른 선수 터치 없이 바로 득점할 수 있다.',
      enTrueStatement:
          'A direct free kick can score without another player touching the ball.',
      koFalseStatement: '직접 프리킥은 반드시 누군가 한 번 더 건드려야 득점이다.',
      enFalseStatement:
          'A direct free kick must touch another player before it can count as a goal.',
      koExplain: '직접 프리킥은 이름 그대로 직접 득점이 가능합니다.',
      enExplain:
          'A direct free kick can score directly, exactly as the name suggests.',
      koNextPoint: '직접과 간접 프리킥 차이를 묶어서 외운다.',
      enNextPoint:
          'Learn the difference between direct and indirect free kicks together.',
    ),
    _OxFactSeed(
      id: 'indirect_free_kick',
      difficulty: 1,
      category: _QuizCategory.rules,
      koTrueStatement: '간접 프리킥은 다른 선수의 터치가 있어야 득점이 된다.',
      enTrueStatement:
          'An indirect free kick needs another touch before a goal can count.',
      koFalseStatement: '간접 프리킥도 바로 차 넣으면 그대로 득점이 인정된다.',
      enFalseStatement:
          'An indirect free kick can score directly without any other touch.',
      koExplain: '간접 프리킥은 두 번째 터치가 있어야 골이 됩니다.',
      enExplain:
          'An indirect free kick only becomes a goal after a second touch.',
      koNextPoint: '심판의 손 신호와 함께 간접 프리킥을 기억한다.',
      enNextPoint:
          'Connect indirect free kicks with the referee’s raised-arm signal.',
    ),
    _OxFactSeed(
      id: 'yellow_red',
      difficulty: 1,
      category: _QuizCategory.rules,
      koTrueStatement: '같은 경기에서 경고 두 장을 받으면 퇴장이다.',
      enTrueStatement:
          'Two cautions in the same match result in a sending-off.',
      koFalseStatement: '같은 경기에서 경고 두 장은 단순 누적이고 퇴장은 아니다.',
      enFalseStatement:
          'Two cautions in the same match are only counted, not punished by a sending-off.',
      koExplain: '경고 두 장은 결국 퇴장으로 이어집니다.',
      enExplain: 'Two cautions in one match lead to a red card dismissal.',
      koNextPoint: '카드 규칙은 누적과 즉시 퇴장을 구분해 기억한다.',
      enNextPoint: 'Separate caution accumulation from immediate send-offs.',
    ),
    _OxFactSeed(
      id: 'back_pass_keeper',
      difficulty: 2,
      category: _QuizCategory.rules,
      koTrueStatement: '골키퍼는 팀 동료가 발로 의도적으로 찬 공을 손으로 잡을 수 없다.',
      enTrueStatement:
          'A goalkeeper cannot handle a deliberate kick from a teammate’s foot.',
      koFalseStatement: '골키퍼는 팀 동료가 발로 준 패스도 위험하면 손으로 잡아도 된다.',
      enFalseStatement:
          'A goalkeeper may always pick up a deliberate pass from a teammate’s foot.',
      koExplain: '의도적인 발 패스는 골키퍼 손 사용 제한 대상입니다.',
      enExplain:
          'A deliberate kick from a teammate’s foot triggers the handling restriction.',
      koNextPoint: '골키퍼 예외 규칙은 발 패스와 헤더를 나눠서 본다.',
      enNextPoint:
          'Read goalkeeper exceptions by separating foot passes from headers.',
    ),
    _OxFactSeed(
      id: 'advantage',
      difficulty: 2,
      category: _QuizCategory.rules,
      koTrueStatement: '심판은 반칙이 있어도 공격 이점이 크면 플레이를 이어가게 할 수 있다.',
      enTrueStatement:
          'A referee may allow play to continue if the fouled team keeps a clear advantage.',
      koFalseStatement: '반칙이 발생하면 이점과 상관없이 항상 즉시 경기를 끊어야 한다.',
      enFalseStatement:
          'Every foul must stop play immediately, regardless of any advantage.',
      koExplain: '어드밴티지 규칙은 흐름과 기회를 살리기 위해 존재합니다.',
      enExplain:
          'The advantage law exists to preserve flow and real attacking opportunity.',
      koNextPoint: '심판 판정은 규칙과 경기 맥락을 함께 읽는다.',
      enNextPoint: 'Read officiating through both law and match context.',
    ),
    _OxFactSeed(
      id: 'warmup_readiness',
      difficulty: 1,
      category: _QuizCategory.training,
      koTrueStatement: '경기 전 워밍업은 몸을 깨우고 부상 위험을 낮추는 데 도움을 준다.',
      enTrueStatement:
          'A pre-match warm-up helps readiness and can lower injury risk.',
      koFalseStatement: '경기 전 워밍업은 거의 의미가 없어서 바로 전력 질주로 들어가도 된다.',
      enFalseStatement:
          'Warm-ups are mostly unnecessary, so sprinting full speed right away is fine.',
      koExplain: '워밍업은 체온, 관절 준비, 신경계 활성에 모두 중요합니다.',
      enExplain:
          'Warm-ups matter for temperature, joint preparation, and nervous system activation.',
      koNextPoint: '워밍업 목적을 단순 땀내기가 아니라 준비 과정으로 본다.',
      enNextPoint: 'Treat warm-up as preparation, not just sweating.',
    ),
    _OxFactSeed(
      id: 'sleep_recovery',
      difficulty: 1,
      category: _QuizCategory.nutrition,
      koTrueStatement: '수면은 회복과 학습 정리에 큰 영향을 준다.',
      enTrueStatement:
          'Sleep strongly affects recovery and the consolidation of learning.',
      koFalseStatement: '수면은 축구 실력 향상과 거의 관련이 없다.',
      enFalseStatement:
          'Sleep has little to do with football improvement or recovery.',
      koExplain: '수면은 피로 회복뿐 아니라 판단력과 학습에도 중요합니다.',
      enExplain:
          'Sleep supports both physical recovery and decision-making quality.',
      koNextPoint: '훈련만큼 회복 습관도 루틴으로 관리한다.',
      enNextPoint: 'Build recovery habits into the routine just like training.',
    ),
    _OxFactSeed(
      id: 'hydration',
      difficulty: 1,
      category: _QuizCategory.nutrition,
      koTrueStatement: '수분 보충은 경기력 유지와 회복에 중요하다.',
      enTrueStatement:
          'Hydration is important for maintaining performance and recovery.',
      koFalseStatement: '수분 보충은 땀이 많은 날에만 신경 쓰면 된다.',
      enFalseStatement: 'Hydration only matters on very sweaty days.',
      koExplain: '탈수는 집중력과 움직임 품질을 모두 떨어뜨릴 수 있습니다.',
      enExplain: 'Dehydration can reduce concentration and movement quality.',
      koNextPoint: '훈련 전중후 수분 루틴을 따로 만든다.',
      enNextPoint:
          'Create a hydration routine for before, during, and after training.',
    ),
    _OxFactSeed(
      id: 'carbohydrate_recovery',
      difficulty: 2,
      category: _QuizCategory.nutrition,
      koTrueStatement: '탄수화물은 고강도 운동 후 에너지 저장량 회복에 도움이 된다.',
      enTrueStatement:
          'Carbohydrates help restore energy stores after intense work.',
      koFalseStatement: '축구 선수는 회복기에 탄수화물을 최대한 피하는 것이 좋다.',
      enFalseStatement:
          'Football players should avoid carbohydrates during recovery.',
      koExplain: '탄수화물은 글리코겐 회복에 중요한 역할을 합니다.',
      enExplain: 'Carbohydrates play a key role in glycogen restoration.',
      koNextPoint: '영양은 금지 목록보다 타이밍과 균형으로 본다.',
      enNextPoint:
          'Treat nutrition as timing and balance, not only restriction.',
    ),
    _OxFactSeed(
      id: 'scan_before_receive',
      difficulty: 1,
      category: _QuizCategory.technique,
      koTrueStatement: '공을 받기 전에 주변을 스캔하면 첫 판단이 빨라진다.',
      enTrueStatement:
          'Scanning before receiving helps speed up the first decision.',
      koFalseStatement: '공을 받기 전에는 공만 보면 되고 주변 확인은 필요 없다.',
      enFalseStatement:
          'Before receiving, it is enough to stare at the ball and ignore the surroundings.',
      koExplain: '스캔은 다음 선택지를 미리 만들어 줍니다.',
      enExplain:
          'Scanning gives the player earlier awareness of the next options.',
      koNextPoint: '받기 전, 받는 순간, 받은 직후 스캔을 연결한다.',
      enNextPoint: 'Link scanning before, during, and after the reception.',
    ),
    _OxFactSeed(
      id: 'open_body',
      difficulty: 2,
      category: _QuizCategory.technique,
      koTrueStatement: '반쯤 열린 몸 방향은 시야를 넓히고 다음 플레이를 쉽게 만든다.',
      enTrueStatement:
          'A half-open body shape widens vision and makes the next play easier.',
      koFalseStatement: '항상 등을 진 채 받는 것이 가장 시야가 넓다.',
      enFalseStatement:
          'Receiving with your back fully turned always gives the widest view.',
      koExplain: '열린 몸 방향은 전방과 측면 정보를 함께 보게 합니다.',
      enExplain:
          'An open body shape helps the player see forward and sideways at once.',
      koNextPoint: '받는 자세는 방향 전환 속도와 같이 본다.',
      enNextPoint: 'Connect receiving shape with turning speed.',
    ),
    _OxFactSeed(
      id: 'first_touch_space',
      difficulty: 2,
      category: _QuizCategory.technique,
      koTrueStatement: '첫 터치를 압박 반대 방향 공간으로 두면 탈압박에 유리하다.',
      enTrueStatement:
          'A first touch into space away from pressure helps beat pressure.',
      koFalseStatement: '첫 터치는 항상 발밑에만 두는 것이 가장 안전하다.',
      enFalseStatement:
          'The safest first touch is always directly under your feet.',
      koExplain: '좋은 첫 터치는 시간을 만들고 압박 각도를 바꿉니다.',
      enExplain:
          'A good first touch creates time and changes the pressure angle.',
      koNextPoint: '첫 터치는 방향과 다음 액션을 함께 계획한다.',
      enNextPoint: 'Plan the first touch together with the next action.',
    ),
    _OxFactSeed(
      id: 'support_angle',
      difficulty: 1,
      category: _QuizCategory.tactics,
      koTrueStatement: '볼 소유자 옆이나 대각 뒤에 서는 지원 각도는 안전한 패스 길을 만든다.',
      enTrueStatement:
          'Support angles beside or diagonally behind the ball create safer passing lanes.',
      koFalseStatement: '지원은 항상 볼 소유자와 일직선 앞에만 서야 좋다.',
      enFalseStatement:
          'The best support is always standing directly in front of the ball carrier on one straight line.',
      koExplain: '좋은 지원 각도는 패스 길과 다음 연결을 동시에 열어 줍니다.',
      enExplain:
          'A strong support angle opens both the pass lane and the next connection.',
      koNextPoint: '지원은 거리와 각도를 세트로 본다.',
      enNextPoint: 'Read support as a pair of distance and angle.',
    ),
    _OxFactSeed(
      id: 'switch_play',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koTrueStatement: '한쪽에 상대가 몰리면 반대 전환이 공간을 여는 좋은 방법이 될 수 있다.',
      enTrueStatement:
          'When opponents overload one side, switching play can open space on the far side.',
      koFalseStatement: '상대가 한쪽에 몰릴수록 그쪽만 더 파고드는 것이 항상 정답이다.',
      enFalseStatement:
          'The more opponents crowd one side, the more you should always force play into that same side.',
      koExplain: '전환은 수비 이동을 크게 만들고 반대 공간을 활용하게 합니다.',
      enExplain:
          'A switch stretches the defense and attacks the far-side space.',
      koNextPoint: '전환 타이밍은 반대편 공간 확인과 함께 본다.',
      enNextPoint: 'Read switching timing together with far-side space.',
    ),
    _OxFactSeed(
      id: 'counterpress',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koTrueStatement: '공을 잃은 직후 가까운 압박은 상대 역습 속도를 늦출 수 있다.',
      enTrueStatement:
          'Immediate nearby pressure after losing the ball can slow the opponent’s counterattack.',
      koFalseStatement: '공을 잃은 직후에는 모두 뒤로만 뛰는 것이 항상 최선이다.',
      enFalseStatement:
          'After losing the ball, the best answer is always for everyone to run backward only.',
      koExplain: '즉시 압박과 지연은 상대의 첫 전진 선택을 어렵게 만듭니다.',
      enExplain:
          'Immediate pressure and delay can disrupt the opponent’s first forward choice.',
      koNextPoint: '전환 순간 첫 2초를 따로 의식한다.',
      enNextPoint:
          'Treat the first two seconds of transition as a special moment.',
    ),
    _OxFactSeed(
      id: 'delay_defending',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koTrueStatement: '수비 전환 첫 동작에서 지연은 동료 복귀 시간을 벌어 준다.',
      enTrueStatement:
          'Delaying in the first defensive transition action buys time for teammates to recover.',
      koFalseStatement: '수비 전환에서는 각도와 거리보다 무조건 태클이 우선이다.',
      enFalseStatement:
          'In defensive transition, tackling immediately always matters more than angle and distance.',
      koExplain: '지연은 수비 숫자를 회복하고 위험한 패스길을 닫게 합니다.',
      enExplain:
          'Delay helps recover defensive numbers and close dangerous passing lanes.',
      koNextPoint: '수비는 빼앗기 이전에 늦추는 기술도 중요하다.',
      enNextPoint:
          'Defending is also about delaying, not only winning the ball.',
    ),
    _OxFactSeed(
      id: 'width_attack',
      difficulty: 1,
      category: _QuizCategory.tactics,
      koTrueStatement: '공격 폭을 넓히면 수비 간격을 벌리는 데 도움이 된다.',
      enTrueStatement: 'Attacking width helps stretch the defending team.',
      koFalseStatement: '공격 때는 항상 중앙에만 최대한 모이는 것이 공간 만들기에 좋다.',
      enFalseStatement:
          'Attacking space is always best created by crowding everyone into the center.',
      koExplain: '폭은 상대 라인을 넓히고 중앙 침투 공간도 도와줍니다.',
      enExplain: 'Width stretches the line and can also free central gaps.',
      koNextPoint: '폭과 깊이를 함께 보는 습관을 만든다.',
      enNextPoint: 'Build the habit of reading width together with depth.',
    ),
    _OxFactSeed(
      id: 'compact_defense',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koTrueStatement: '수비 간격이 지나치게 벌어지면 중앙 공간이 위험해질 수 있다.',
      enTrueStatement:
          'If defensive distances become too wide, the central space can become dangerous.',
      koFalseStatement: '수비는 간격이 멀수록 항상 패스 차단이 쉬워진다.',
      enFalseStatement:
          'The farther apart defenders are, the easier it always becomes to block passes.',
      koExplain: '컴팩트함은 중앙 보호와 커버의 기본입니다.',
      enExplain:
          'Compactness is a core principle for protecting the center and covering.',
      koNextPoint: '라인 간격과 선수 간격을 따로 본다.',
      enNextPoint: 'Read line spacing and player spacing separately.',
    ),
    _OxFactSeed(
      id: 'goalkeeper_communication',
      difficulty: 1,
      category: _QuizCategory.positions,
      koTrueStatement: '골키퍼의 소통은 수비 라인 정리와 충돌 방지에 도움을 준다.',
      enTrueStatement:
          'Goalkeeper communication helps organize the back line and prevent collisions.',
      koFalseStatement: '골키퍼는 세이브만 잘하면 되고 소통은 거의 중요하지 않다.',
      enFalseStatement:
          'A goalkeeper only needs to save shots; communication is barely important.',
      koExplain: '골키퍼는 뒤에서 전체 그림을 가장 넓게 보는 포지션입니다.',
      enExplain:
          'The goalkeeper often has the widest view of the whole defensive picture.',
      koNextPoint: '포지션별 역할은 기술과 소통을 함께 익힌다.',
      enNextPoint: 'Learn each position through both skill and communication.',
    ),
    _OxFactSeed(
      id: 'fullback_overlap',
      difficulty: 2,
      category: _QuizCategory.positions,
      koTrueStatement: '풀백의 오버래핑은 측면에서 숫자 우위를 만들 수 있다.',
      enTrueStatement:
          'A fullback overlap can create a numerical advantage on the flank.',
      koFalseStatement: '풀백은 언제나 하프라인 뒤에만 머무는 것이 전술적으로 가장 좋다.',
      enFalseStatement:
          'The best tactical role for a fullback is always to stay behind the halfway line.',
      koExplain: '오버래핑은 타이밍이 맞으면 패스길과 크로스각을 동시에 만듭니다.',
      enExplain:
          'A well-timed overlap can open both a passing lane and a crossing angle.',
      koNextPoint: '포지션 역할은 고정이 아니라 상황에 따라 변한다.',
      enNextPoint:
          'Positional roles change with the situation, not just fixed labels.',
    ),
    _OxFactSeed(
      id: 'striker_pin',
      difficulty: 2,
      category: _QuizCategory.positions,
      koTrueStatement: '스트라이커의 위치 고정 움직임은 센터백 시선을 묶는 데 도움이 된다.',
      enTrueStatement:
          'A striker pinning the center-backs can help occupy their attention.',
      koFalseStatement: '스트라이커는 공이 없을 때 아무 움직임도 하지 않는 편이 낫다.',
      enFalseStatement:
          'When the striker does not have the ball, it is best to stop moving entirely.',
      koExplain: '공이 없는 움직임도 동료 공간 만들기에 큰 역할을 합니다.',
      enExplain:
          'Off-ball movement can be crucial for creating space for teammates.',
      koNextPoint: '공이 없는 선수도 전술의 중심이라는 점을 기억한다.',
      enNextPoint: 'Remember that off-ball players are central to tactics too.',
    ),
    _OxFactSeed(
      id: 'mistake_reset',
      difficulty: 1,
      category: _QuizCategory.mindset,
      koTrueStatement: '실수 직후에는 다음 역할로 빠르게 복귀하는 것이 중요하다.',
      enTrueStatement:
          'After a mistake, it is important to reset quickly into the next role.',
      koFalseStatement: '실수 뒤에는 한 플레이 쉬면서 마음이 돌아오길 기다리는 것이 낫다.',
      enFalseStatement:
          'After a mistake, it is better to take one play off and wait for confidence to return.',
      koExplain: '실수 후 복귀 속도는 다음 장면의 손실을 줄입니다.',
      enExplain:
          'Fast reset after a mistake reduces the damage in the next action.',
      koNextPoint: '실수 대응 루틴을 미리 정해둔다.',
      enNextPoint: 'Prepare a reset routine for mistakes in advance.',
    ),
    _OxFactSeed(
      id: 'communication_help',
      difficulty: 1,
      category: _QuizCategory.mindset,
      koTrueStatement: '짧고 명확한 소통은 팀 판단 속도를 높여 준다.',
      enTrueStatement:
          'Short and clear communication helps speed up team decisions.',
      koFalseStatement: '경기 중 소통은 오히려 집중을 깨니 가능한 한 하지 않는 편이 낫다.',
      enFalseStatement:
          'Communication during the game mostly hurts focus, so it is better to avoid it.',
      koExplain: '좋은 소통은 정보 전달을 빠르게 만들어 팀을 묶어 줍니다.',
      enExplain:
          'Good communication shares information quickly and keeps the team connected.',
      koNextPoint: '소통은 길이보다 명확성이 중요하다.',
      enNextPoint: 'In communication, clarity matters more than length.',
    ),
    _OxFactSeed(
      id: 'repeated_sprint',
      difficulty: 2,
      category: _QuizCategory.training,
      koTrueStatement: '반복 스프린트 훈련은 경기 중 고강도 움직임 대응에 도움을 준다.',
      enTrueStatement:
          'Repeated sprint training helps players handle high-intensity match actions.',
      koFalseStatement: '축구 훈련에는 방향 전환이나 반복 질주가 거의 필요 없다.',
      enFalseStatement:
          'Football training barely needs change-of-direction or repeated sprint work.',
      koExplain: '축구는 짧고 강한 움직임이 반복되는 종목입니다.',
      enExplain: 'Football repeatedly demands short, high-intensity actions.',
      koNextPoint: '체력은 경기 요구와 연결해 본다.',
      enNextPoint: 'Read fitness through match demands.',
    ),
    _OxFactSeed(
      id: 'ball_protection',
      difficulty: 1,
      category: _QuizCategory.technique,
      koTrueStatement: '상대 압박이 가까울 때는 몸으로 공을 보호하는 기술이 중요하다.',
      enTrueStatement:
          'When pressure is close, shielding the ball with the body becomes important.',
      koFalseStatement: '압박이 와도 공 보호보다 큰 스윙만 하면 대부분 해결된다.',
      enFalseStatement:
          'When pressure comes, a big uncontrolled swing solves most situations better than shielding.',
      koExplain: '볼 보호는 시간을 벌고 파울 유도에도 도움을 줍니다.',
      enExplain: 'Ball protection can buy time and sometimes draw a foul.',
      koNextPoint: '기술은 화려함보다 상황 적합성을 본다.',
      enNextPoint: 'Judge technique by fit to the situation, not only flair.',
    ),
    _OxFactSeed(
      id: 'match_starts_11',
      difficulty: 1,
      category: _QuizCategory.fun,
      koTrueStatement: '축구 경기는 보통 팀당 11명으로 시작한다.',
      enTrueStatement:
          'A standard football match normally starts with 11 players per team.',
      koFalseStatement: '축구 경기는 기본적으로 팀당 10명으로 시작한다.',
      enFalseStatement:
          'A standard football match normally starts with 10 players per team.',
      koExplain: '정식 축구의 기본 인원은 팀당 11명입니다.',
      enExplain:
          'The standard player count in association football is 11 per team.',
      koNextPoint: '기본 규칙은 숫자부터 분명히 익힌다.',
      enNextPoint: 'Learn the basic numbers of the game clearly.',
    ),
  ];
}

List<_McqSeed> _mcqSeeds() {
  return const [
    _McqSeed(
      id: 'offside_reference',
      difficulty: 2,
      category: _QuizCategory.rules,
      koStem: '오프사이드 위치를 판단할 때 기준이 되는 수비수는 보통 누구인가?',
      enStem:
          'Which defender is usually the reference point when judging offside position?',
      options: [
        _FootballQuizOption(
          koText: '두 번째로 뒤에 있는 상대 수비수',
          enText: 'The second-last opponent',
        ),
        _FootballQuizOption(koText: '가장 가까운 주심', enText: 'The nearest referee'),
        _FootballQuizOption(
          koText: '터치라인과 가장 가까운 선수',
          enText: 'The player nearest the touchline',
        ),
        _FootballQuizOption(
          koText: '벤치에 앉아 있는 교체 선수',
          enText: 'A substitute on the bench',
        ),
      ],
      correctIndex: 0,
      koExplain: '오프사이드는 일반적으로 두 번째로 뒤에 있는 상대를 기준으로 봅니다.',
      enExplain:
          'Offside position is generally judged against the second-last opponent.',
      koNextPoint: '골키퍼가 항상 마지막 수비수는 아니라는 점도 기억한다.',
      enNextPoint:
          'Remember that the goalkeeper is not always the last defender.',
    ),
    _McqSeed(
      id: 'throw_in_restart',
      difficulty: 1,
      category: _QuizCategory.rules,
      koStem: '공이 터치라인 밖으로 나가면 어떤 재개가 주어지는가?',
      enStem:
          'What restart is awarded when the ball goes out over the touchline?',
      options: [
        _FootballQuizOption(koText: '스로인', enText: 'Throw-in'),
        _FootballQuizOption(koText: '골킥', enText: 'Goal kick'),
        _FootballQuizOption(koText: '코너킥', enText: 'Corner kick'),
        _FootballQuizOption(koText: '드롭볼', enText: 'Dropped ball'),
      ],
      correctIndex: 0,
      koExplain: '터치라인을 넘어 나간 공은 스로인으로 재개합니다.',
      enExplain:
          'When the ball leaves over the touchline, play restarts with a throw-in.',
      koNextPoint: '어떤 라인을 넘었는지부터 확인하는 습관을 들인다.',
      enNextPoint: 'First check which line the ball crossed.',
    ),
    _McqSeed(
      id: 'goal_kick_restart',
      difficulty: 1,
      category: _QuizCategory.rules,
      koStem: '공이 공격자에게 마지막으로 맞고 골라인 밖으로 나가면 보통 어떤 재개인가?',
      enStem:
          'If the ball last touches an attacker and goes over the goal line, what is the usual restart?',
      options: [
        _FootballQuizOption(koText: '골킥', enText: 'Goal kick'),
        _FootballQuizOption(koText: '코너킥', enText: 'Corner kick'),
        _FootballQuizOption(koText: '스로인', enText: 'Throw-in'),
        _FootballQuizOption(koText: '페널티킥', enText: 'Penalty kick'),
      ],
      correctIndex: 0,
      koExplain: '공격자가 마지막으로 건드린 뒤 골라인을 넘으면 골킥입니다.',
      enExplain:
          'If the attacker touched it last before it crossed the goal line, it is a goal kick.',
      koNextPoint: '골라인 재개는 마지막 터치 팀으로 구분한다.',
      enNextPoint: 'Goal-line restarts depend on the last touch.',
    ),
    _McqSeed(
      id: 'corner_restart',
      difficulty: 1,
      category: _QuizCategory.rules,
      koStem: '공이 수비자에게 마지막으로 맞고 골라인 밖으로 나가면 보통 어떤 재개인가?',
      enStem:
          'If the ball last touches a defender and goes over the goal line, what is the usual restart?',
      options: [
        _FootballQuizOption(koText: '코너킥', enText: 'Corner kick'),
        _FootballQuizOption(koText: '골킥', enText: 'Goal kick'),
        _FootballQuizOption(koText: '스로인', enText: 'Throw-in'),
        _FootballQuizOption(koText: '간접 프리킥', enText: 'Indirect free kick'),
      ],
      correctIndex: 0,
      koExplain: '수비자가 마지막 터치 후 골라인을 넘으면 코너킥입니다.',
      enExplain:
          'If the defender touched it last before it crossed the goal line, it is a corner kick.',
      koNextPoint: '골라인 판단은 공격자/수비자 마지막 터치를 나눈다.',
      enNextPoint:
          'For goal-line decisions, separate attacker-last from defender-last.',
    ),
    _McqSeed(
      id: 'yellow_card_meaning',
      difficulty: 1,
      category: _QuizCategory.rules,
      koStem: '경고를 의미하는 카드는 무엇인가?',
      enStem: 'Which card represents a caution?',
      options: [
        _FootballQuizOption(koText: '옐로카드', enText: 'Yellow card'),
        _FootballQuizOption(koText: '레드카드', enText: 'Red card'),
        _FootballQuizOption(koText: '그린카드', enText: 'Green card'),
        _FootballQuizOption(koText: '블루카드', enText: 'Blue card'),
      ],
      correctIndex: 0,
      koExplain: '경고는 옐로카드로 표시합니다.',
      enExplain: 'A caution is shown with a yellow card.',
      koNextPoint: '카드 색과 의미를 연결해서 외운다.',
      enNextPoint: 'Connect each card color with its meaning.',
    ),
    _McqSeed(
      id: 'red_card_meaning',
      difficulty: 1,
      category: _QuizCategory.rules,
      koStem: '퇴장을 의미하는 카드는 무엇인가?',
      enStem: 'Which card represents a sending-off?',
      options: [
        _FootballQuizOption(koText: '레드카드', enText: 'Red card'),
        _FootballQuizOption(koText: '옐로카드', enText: 'Yellow card'),
        _FootballQuizOption(koText: '화이트카드', enText: 'White card'),
        _FootballQuizOption(koText: '주황카드', enText: 'Orange card'),
      ],
      correctIndex: 0,
      koExplain: '퇴장은 레드카드로 표시합니다.',
      enExplain: 'A sending-off is shown with a red card.',
      koNextPoint: '경고와 퇴장을 색으로 빠르게 구분한다.',
      enNextPoint: 'Separate caution and dismissal instantly by color.',
    ),
    _McqSeed(
      id: 'scan_skill',
      difficulty: 1,
      category: _QuizCategory.technique,
      koStem: '공을 받기 전 주변 정보를 미리 확인하는 행동을 보통 무엇이라고 하나?',
      enStem:
          'What do we usually call checking the surroundings before receiving the ball?',
      options: [
        _FootballQuizOption(koText: '스캐닝', enText: 'Scanning'),
        _FootballQuizOption(koText: '슬라이딩', enText: 'Sliding'),
        _FootballQuizOption(koText: '클리어링', enText: 'Clearing'),
        _FootballQuizOption(koText: '드롭핑', enText: 'Dropping'),
      ],
      correctIndex: 0,
      koExplain: '스캐닝은 다음 선택지를 미리 보는 핵심 기술입니다.',
      enExplain: 'Scanning is a key skill for seeing the next options early.',
      koNextPoint: '보기 전에 받지 않는다는 습관을 만든다.',
      enNextPoint: 'Build the habit of seeing before receiving.',
    ),
    _McqSeed(
      id: 'open_body_shape',
      difficulty: 2,
      category: _QuizCategory.technique,
      koStem: '압박을 받기 전에 시야를 넓게 확보하기 가장 좋은 받는 자세는?',
      enStem:
          'Which receiving shape is best for keeping a broad view before pressure arrives?',
      options: [
        _FootballQuizOption(
          koText: '반쯤 열린 자세',
          enText: 'A half-open body shape',
        ),
        _FootballQuizOption(
          koText: '완전히 등을 진 자세',
          enText: 'A fully closed back-to-play shape',
        ),
        _FootballQuizOption(
          koText: '두 발을 멈춘 채 정면만 보는 자세',
          enText: 'A static shape looking only straight ahead',
        ),
        _FootballQuizOption(
          koText: '눈을 감고 받는 자세',
          enText: 'Receiving with eyes closed',
        ),
      ],
      correctIndex: 0,
      koExplain: '반쯤 열린 자세는 전방과 측면을 함께 보기 좋습니다.',
      enExplain:
          'A half-open body shape makes it easier to see both forward and sideways.',
      koNextPoint: '받는 자세와 다음 방향 전환을 연결한다.',
      enNextPoint: 'Link the receiving shape with the next turn.',
    ),
    _McqSeed(
      id: 'first_touch_escape',
      difficulty: 2,
      category: _QuizCategory.technique,
      koStem: '정면 압박을 피하려는 첫 터치의 방향으로 가장 좋은 것은?',
      enStem:
          'Which direction is best for a first touch when escaping frontal pressure?',
      options: [
        _FootballQuizOption(
          koText: '압박 반대 방향의 열린 공간',
          enText: 'Open space away from the pressure',
        ),
        _FootballQuizOption(
          koText: '상대 발 앞으로 그대로',
          enText: 'Directly toward the opponent’s foot',
        ),
        _FootballQuizOption(
          koText: '늘 자기 발밑으로만',
          enText: 'Always straight under your feet',
        ),
        _FootballQuizOption(
          koText: '라인 밖으로 크게',
          enText: 'Big touch out of bounds',
        ),
      ],
      correctIndex: 0,
      koExplain: '압박 반대 공간으로 두는 첫 터치가 시간을 만듭니다.',
      enExplain: 'A first touch away from pressure creates valuable time.',
      koNextPoint: '첫 터치는 공간과 방향을 함께 읽는다.',
      enNextPoint: 'Read the first touch through both space and direction.',
    ),
    _McqSeed(
      id: 'shielding_ball',
      difficulty: 1,
      category: _QuizCategory.technique,
      koStem: '등 뒤 압박이 가까울 때 가장 먼저 떠올릴 기술로 알맞은 것은?',
      enStem:
          'When pressure is tight from behind, which technique should come to mind first?',
      options: [
        _FootballQuizOption(
          koText: '몸으로 공 보호하기',
          enText: 'Shielding the ball with the body',
        ),
        _FootballQuizOption(
          koText: '눈 감고 큰 스윙하기',
          enText: 'Swinging wildly with eyes closed',
        ),
        _FootballQuizOption(
          koText: '공을 멀리 던지기',
          enText: 'Throwing the ball away',
        ),
        _FootballQuizOption(koText: '제자리 점프하기', enText: 'Jumping in place'),
      ],
      correctIndex: 0,
      koExplain: '볼 보호는 시간을 벌고 다음 연결을 준비하게 합니다.',
      enExplain:
          'Shielding buys time and allows the next action to be prepared.',
      koNextPoint: '보호 후 연결까지 세트로 훈련한다.',
      enNextPoint: 'Train shielding together with the next pass or turn.',
    ),
    _McqSeed(
      id: 'support_angle_best',
      difficulty: 1,
      category: _QuizCategory.tactics,
      koStem: '볼 소유자를 돕는 기본 지원 위치로 가장 알맞은 것은?',
      enStem:
          'Which position is the most basic support spot for helping the ball carrier?',
      options: [
        _FootballQuizOption(
          koText: '옆이나 대각 뒤의 패스 각도',
          enText: 'A lane beside or diagonally behind',
        ),
        _FootballQuizOption(
          koText: '항상 같은 일직선 앞',
          enText: 'Always on the same straight line ahead',
        ),
        _FootballQuizOption(
          koText: '심판 뒤쪽',
          enText: 'Directly behind the referee',
        ),
        _FootballQuizOption(
          koText: '코너 플래그 바로 옆',
          enText: 'Right next to the corner flag',
        ),
      ],
      correctIndex: 0,
      koExplain: '옆이나 대각 뒤 지원은 안전한 패스길을 만들기 좋습니다.',
      enExplain:
          'Support beside or diagonally behind is ideal for creating a safe passing lane.',
      koNextPoint: '지원은 볼과 수비 사이의 각도로 본다.',
      enNextPoint: 'Read support through the angle between ball and defenders.',
    ),
    _McqSeed(
      id: 'switch_play_far_side',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koStem: '상대가 한쪽에 몰려 있을 때 자주 좋은 선택이 되는 것은?',
      enStem:
          'When opponents crowd one side, what often becomes a good option?',
      options: [
        _FootballQuizOption(
          koText: '반대편으로 전환하기',
          enText: 'Switching play to the far side',
        ),
        _FootballQuizOption(
          koText: '더 좁은 쪽으로 무조건 밀어넣기',
          enText: 'Forcing the ball into the tighter side',
        ),
        _FootballQuizOption(
          koText: '공을 손으로 들어 올리기',
          enText: 'Picking the ball up by hand',
        ),
        _FootballQuizOption(
          koText: '전원이 골문 앞으로 이동하기',
          enText: 'Moving everyone directly in front of the goal',
        ),
      ],
      correctIndex: 0,
      koExplain: '전환은 밀집된 쪽 반대의 공간을 활용하는 방법입니다.',
      enExplain:
          'A switch is a common way to attack the space opposite the overload.',
      koNextPoint: '반대편 공간과 수비 이동을 함께 본다.',
      enNextPoint: 'Read the far-side space together with defensive movement.',
    ),
    _McqSeed(
      id: 'counterpress_first_action',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koStem: '상대 진영에서 공을 잃은 직후 가장 먼저 생각할 팀 반응으로 좋은 것은?',
      enStem:
          'Right after losing the ball high up the pitch, which team reaction is often best first?',
      options: [
        _FootballQuizOption(
          koText: '가까운 압박으로 역습 속도 늦추기',
          enText: 'Immediate nearby pressure to slow the counter',
        ),
        _FootballQuizOption(
          koText: '모두 제자리 멈추기',
          enText: 'Everyone freezing in place',
        ),
        _FootballQuizOption(
          koText: '전원이 손 들고 항의하기',
          enText: 'Everyone raising hands to protest',
        ),
        _FootballQuizOption(
          koText: '공 없는 쪽으로 뛰기만 하기',
          enText: 'Running only away from the ball',
        ),
      ],
      correctIndex: 0,
      koExplain: '즉시 압박은 상대의 첫 전진 선택을 어렵게 만듭니다.',
      enExplain:
          'Immediate pressure can disrupt the opponent’s first forward action.',
      koNextPoint: '전환 순간 첫 반응 속도를 강조한다.',
      enNextPoint: 'Emphasize the speed of the first transition reaction.',
    ),
    _McqSeed(
      id: 'delay_on_flank_defense',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koStem: '측면 1대1 수비에서 우선순위로 가장 알맞은 것은?',
      enStem: 'In a wide 1v1 defensive situation, what is the best priority?',
      options: [
        _FootballQuizOption(
          koText: '안쪽 길을 닫고 지연하기',
          enText: 'Close the inside lane and delay',
        ),
        _FootballQuizOption(
          koText: '무조건 먼저 태클하기',
          enText: 'Tackle immediately every time',
        ),
        _FootballQuizOption(
          koText: '뒤돌아 달리기만 하기',
          enText: 'Only turn and run away',
        ),
        _FootballQuizOption(
          koText: '선수 시선만 따라가기',
          enText: 'Follow only the attacker’s eyes',
        ),
      ],
      correctIndex: 0,
      koExplain: '측면 수비는 안쪽 차단과 지연이 기본 원리입니다.',
      enExplain:
          'Wide defending is built on protecting the inside and delaying.',
      koNextPoint: '측면 수비는 각도와 속도 조절이 핵심이다.',
      enNextPoint: 'Wide defending is about angle control and speed control.',
    ),
    _McqSeed(
      id: 'compactness_center',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koStem: '수비 라인이 너무 벌어졌을 때 가장 크게 위험해지는 공간은 어디인가?',
      enStem:
          'If the defensive unit spreads too much, which space usually becomes most dangerous?',
      options: [
        _FootballQuizOption(koText: '중앙 공간', enText: 'The central space'),
        _FootballQuizOption(koText: '관중석', enText: 'The stands'),
        _FootballQuizOption(koText: '벤치 뒤', enText: 'Behind the bench'),
        _FootballQuizOption(
          koText: '코너 플래그 바깥',
          enText: 'Outside the corner flag',
        ),
      ],
      correctIndex: 0,
      koExplain: '컴팩트함이 무너지면 중앙 침투와 연결이 쉬워집니다.',
      enExplain:
          'When compactness breaks, central progression and combinations become easier.',
      koNextPoint: '공간 위험도는 중앙과 하프스페이스부터 본다.',
      enNextPoint: 'Start by reading the danger in the center and half-spaces.',
    ),
    _McqSeed(
      id: 'width_attack_reason',
      difficulty: 1,
      category: _QuizCategory.tactics,
      koStem: '공격 시 폭을 넓게 쓰는 가장 큰 이유로 알맞은 것은?',
      enStem: 'What is the main reason for using width in attack?',
      options: [
        _FootballQuizOption(
          koText: '수비 간격을 벌려 공간을 만들기 위해',
          enText: 'To stretch defenders and create space',
        ),
        _FootballQuizOption(
          koText: '공을 경기장 밖으로 보내기 위해',
          enText: 'To send the ball out of the field',
        ),
        _FootballQuizOption(
          koText: '골키퍼와 멀어지기 위해',
          enText: 'To move away from the goalkeeper',
        ),
        _FootballQuizOption(
          koText: '심판 시야를 가리기 위해',
          enText: 'To block the referee’s vision',
        ),
      ],
      correctIndex: 0,
      koExplain: '폭은 수비를 늘려 중앙과 반대편 공간을 열어 줍니다.',
      enExplain:
          'Width stretches the defense and opens central or far-side gaps.',
      koNextPoint: '폭과 깊이를 함께 활용하는 그림을 떠올린다.',
      enNextPoint: 'Picture width and depth working together.',
    ),
    _McqSeed(
      id: 'fullback_role',
      difficulty: 1,
      category: _QuizCategory.positions,
      koStem: '측면에서 오버래핑으로 숫자 우위를 만들 수 있는 포지션으로 대표적인 것은?',
      enStem:
          'Which position is commonly associated with creating an overlap on the flank?',
      options: [
        _FootballQuizOption(koText: '풀백', enText: 'Fullback'),
        _FootballQuizOption(koText: '주심', enText: 'Referee'),
        _FootballQuizOption(koText: '관중', enText: 'Spectator'),
        _FootballQuizOption(koText: '볼보이', enText: 'Ball boy'),
      ],
      correctIndex: 0,
      koExplain: '풀백의 오버래핑은 측면 공격 전개를 돕는 대표 장면입니다.',
      enExplain:
          'The fullback overlap is a classic example of supporting wide attacks.',
      koNextPoint: '포지션 역할은 공수 전환까지 연결해 본다.',
      enNextPoint:
          'Connect positional roles to attacking and defensive transitions.',
    ),
    _McqSeed(
      id: 'goalkeeper_view',
      difficulty: 1,
      category: _QuizCategory.positions,
      koStem: '수비 조직을 뒤에서 가장 넓게 보며 지시하기 좋은 포지션은?',
      enStem:
          'Which position usually has the widest rear view for organizing the defense?',
      options: [
        _FootballQuizOption(koText: '골키퍼', enText: 'Goalkeeper'),
        _FootballQuizOption(koText: '스트라이커', enText: 'Striker'),
        _FootballQuizOption(koText: '윙어', enText: 'Winger'),
        _FootballQuizOption(koText: '코너키커', enText: 'Corner taker'),
      ],
      correctIndex: 0,
      koExplain: '골키퍼는 뒤에서 라인 전체를 보며 소통하기 좋습니다.',
      enExplain:
          'The goalkeeper often sees the defensive line from behind most clearly.',
      koNextPoint: '포지션별 시야 차이를 이해한다.',
      enNextPoint: 'Understand how the view differs by position.',
    ),
    _McqSeed(
      id: 'striker_off_ball',
      difficulty: 2,
      category: _QuizCategory.positions,
      koStem: '스트라이커의 공 없는 움직임이 중요한 이유로 가장 알맞은 것은?',
      enStem: 'Why is off-ball movement important for a striker?',
      options: [
        _FootballQuizOption(
          koText: '수비 시선을 묶고 동료 공간을 만들 수 있어서',
          enText: 'It can occupy defenders and create space for teammates',
        ),
        _FootballQuizOption(
          koText: '경기 시간을 더 빨리 끝내기 위해서',
          enText: 'To make the match finish faster',
        ),
        _FootballQuizOption(
          koText: '볼을 손으로 잡기 위해서',
          enText: 'To handle the ball by hand',
        ),
        _FootballQuizOption(
          koText: '심판을 피하기 위해서',
          enText: 'To avoid the referee',
        ),
      ],
      correctIndex: 0,
      koExplain: '공이 없어도 움직임은 수비를 흔들고 공간을 만듭니다.',
      enExplain:
          'Even without the ball, movement can disorganize defenders and create space.',
      koNextPoint: '오프더볼의 가치를 득점 장면과 연결해 본다.',
      enNextPoint: 'Connect off-ball value with chance creation.',
    ),
    _McqSeed(
      id: 'sleep_best_recovery',
      difficulty: 1,
      category: _QuizCategory.nutrition,
      koStem: '회복과 다음 날 판단력에 가장 기본적으로 중요한 습관은?',
      enStem:
          'Which habit is fundamentally important for recovery and next-day decision-making?',
      options: [
        _FootballQuizOption(koText: '충분한 수면', enText: 'Adequate sleep'),
        _FootballQuizOption(
          koText: '밤새 영상 보기',
          enText: 'Watching videos all night',
        ),
        _FootballQuizOption(
          koText: '훈련 후 물 안 마시기',
          enText: 'Skipping water after training',
        ),
        _FootballQuizOption(koText: '식사 거르기', enText: 'Skipping meals'),
      ],
      correctIndex: 0,
      koExplain: '수면은 회복과 학습 정리에 모두 큰 영향을 줍니다.',
      enExplain:
          'Sleep strongly influences both recovery and the consolidation of learning.',
      koNextPoint: '회복 루틴은 훈련 계획의 일부로 기록한다.',
      enNextPoint: 'Record recovery habits as part of the training plan.',
    ),
    _McqSeed(
      id: 'hydration_best',
      difficulty: 1,
      category: _QuizCategory.nutrition,
      koStem: '훈련 전중후 꾸준히 관리해야 하는 항목으로 가장 알맞은 것은?',
      enStem:
          'Which item is best managed consistently before, during, and after training?',
      options: [
        _FootballQuizOption(koText: '수분 보충', enText: 'Hydration'),
        _FootballQuizOption(koText: '항의 횟수', enText: 'Number of protests'),
        _FootballQuizOption(koText: '유니폼 색상', enText: 'Shirt color'),
        _FootballQuizOption(koText: '관중석 위치', enText: 'Seat location'),
      ],
      correctIndex: 0,
      koExplain: '수분 상태는 경기력과 회복 모두에 영향을 줍니다.',
      enExplain: 'Hydration status affects both performance and recovery.',
      koNextPoint: '수분은 갈증 전에 관리하는 습관이 중요하다.',
      enNextPoint:
          'Build the habit of managing fluids before strong thirst appears.',
    ),
    _McqSeed(
      id: 'carb_role',
      difficulty: 1,
      category: _QuizCategory.nutrition,
      koStem: '고강도 훈련 뒤 에너지 저장량 회복과 가장 연결되는 영양소는?',
      enStem:
          'Which nutrient is most associated with restoring energy stores after hard training?',
      options: [
        _FootballQuizOption(koText: '탄수화물', enText: 'Carbohydrates'),
        _FootballQuizOption(koText: '모래', enText: 'Sand'),
        _FootballQuizOption(koText: '탄산만', enText: 'Only soda'),
        _FootballQuizOption(koText: '향수', enText: 'Perfume'),
      ],
      correctIndex: 0,
      koExplain: '탄수화물은 글리코겐 회복과 연결됩니다.',
      enExplain: 'Carbohydrates are linked to glycogen restoration.',
      koNextPoint: '영양은 경기 요구와 연결해 이해한다.',
      enNextPoint: 'Understand nutrition through match demands.',
    ),
    _McqSeed(
      id: 'warmup_purpose',
      difficulty: 1,
      category: _QuizCategory.training,
      koStem: '워밍업의 주된 목적에 가장 가까운 것은?',
      enStem: 'Which answer is closest to the main purpose of a warm-up?',
      options: [
        _FootballQuizOption(
          koText: '몸과 신경계를 경기 속도에 맞게 준비시키기',
          enText: 'Preparing the body and nervous system for match speed',
        ),
        _FootballQuizOption(
          koText: '최대한 빨리 지치기',
          enText: 'Getting tired as fast as possible',
        ),
        _FootballQuizOption(
          koText: '훈련 시간을 없애기',
          enText: 'Removing the need for training',
        ),
        _FootballQuizOption(
          koText: '유니폼을 더럽히기',
          enText: 'Making the kit dirty',
        ),
      ],
      correctIndex: 0,
      koExplain: '워밍업은 몸과 판단을 경기 강도에 맞게 끌어올립니다.',
      enExplain:
          'Warm-ups raise the body and decision-making system toward match intensity.',
      koNextPoint: '워밍업은 형식이 아니라 기능으로 이해한다.',
      enNextPoint: 'Understand warm-ups by function, not only routine.',
    ),
    _McqSeed(
      id: 'repeated_sprint_value',
      difficulty: 2,
      category: _QuizCategory.training,
      koStem: '반복 스프린트 훈련이 특히 도움이 되는 장면은?',
      enStem:
          'Which match demand is repeated sprint training especially useful for?',
      options: [
        _FootballQuizOption(
          koText: '짧고 강한 움직임이 반복되는 상황',
          enText: 'Situations with repeated short high-intensity actions',
        ),
        _FootballQuizOption(
          koText: '항상 가만히 서 있는 상황',
          enText: 'Situations where players always stand still',
        ),
        _FootballQuizOption(
          koText: '심판 판정 기다리는 상황',
          enText: 'Waiting for a referee decision',
        ),
        _FootballQuizOption(koText: '경기장 청소 상황', enText: 'Cleaning the pitch'),
      ],
      correctIndex: 0,
      koExplain: '축구는 짧고 강한 움직임이 반복되는 스포츠입니다.',
      enExplain: 'Football repeatedly demands short, explosive actions.',
      koNextPoint: '체력 훈련은 실제 경기 움직임과 연결한다.',
      enNextPoint: 'Link fitness work to real match movement patterns.',
    ),
    _McqSeed(
      id: 'mistake_reaction',
      difficulty: 1,
      category: _QuizCategory.mindset,
      koStem: '실수 직후 가장 좋은 반응으로 알맞은 것은?',
      enStem: 'Which reaction is best right after making a mistake?',
      options: [
        _FootballQuizOption(
          koText: '다음 역할로 빠르게 복귀하기',
          enText: 'Reset quickly into the next role',
        ),
        _FootballQuizOption(
          koText: '한 플레이 쉬어 버리기',
          enText: 'Take the next play off',
        ),
        _FootballQuizOption(
          koText: '계속 실수만 떠올리기',
          enText: 'Keep replaying the mistake only',
        ),
        _FootballQuizOption(koText: '동료 탓만 하기', enText: 'Blame teammates only'),
      ],
      correctIndex: 0,
      koExplain: '실수 후 빠른 복귀가 다음 장면 손실을 줄입니다.',
      enExplain:
          'A fast reset after a mistake reduces the damage in the next moment.',
      koNextPoint: '실수 복귀 루틴을 짧은 문장으로 정리해 둔다.',
      enNextPoint: 'Prepare a short reset phrase or routine for mistakes.',
    ),
    _McqSeed(
      id: 'communication_style',
      difficulty: 1,
      category: _QuizCategory.mindset,
      koStem: '경기 중 팀 소통 방식으로 가장 바람직한 것은?',
      enStem: 'Which communication style is most desirable during a match?',
      options: [
        _FootballQuizOption(
          koText: '짧고 명확한 정보 전달',
          enText: 'Short and clear information sharing',
        ),
        _FootballQuizOption(
          koText: '길고 복잡한 설명만 하기',
          enText: 'Giving only long and complex speeches',
        ),
        _FootballQuizOption(koText: '계속 비난하기', enText: 'Constant criticism'),
        _FootballQuizOption(koText: '아예 말하지 않기', enText: 'Not speaking at all'),
      ],
      correctIndex: 0,
      koExplain: '짧고 명확한 소통이 경기 속도에 가장 잘 맞습니다.',
      enExplain:
          'Short and clear communication fits the speed of the game best.',
      koNextPoint: '소통은 길이보다 실행 가능성이 중요하다.',
      enNextPoint: 'In communication, actionability matters more than length.',
    ),
    _McqSeed(
      id: 'team_size',
      difficulty: 1,
      category: _QuizCategory.fun,
      koStem: '정식 축구 경기의 기본 시작 인원은 팀당 몇 명인가?',
      enStem:
          'How many players does each team normally start with in standard football?',
      options: [
        _FootballQuizOption(koText: '11명', enText: '11 players'),
        _FootballQuizOption(koText: '10명', enText: '10 players'),
        _FootballQuizOption(koText: '9명', enText: '9 players'),
        _FootballQuizOption(koText: '12명', enText: '12 players'),
      ],
      correctIndex: 0,
      koExplain: '정식 축구의 기본 시작 인원은 팀당 11명입니다.',
      enExplain:
          'Standard association football starts with 11 players per team.',
      koNextPoint: '기본 규칙 숫자는 먼저 정확히 익힌다.',
      enNextPoint: 'Learn the game’s core numbers accurately first.',
    ),
    _McqSeed(
      id: 'clean_sheet',
      difficulty: 1,
      category: _QuizCategory.fun,
      koStem: '클린시트라는 표현은 보통 무엇을 뜻하는가?',
      enStem: 'What does the phrase “clean sheet” usually mean?',
      options: [
        _FootballQuizOption(
          koText: '실점 없이 경기를 마친 것',
          enText: 'Finishing the match without conceding',
        ),
        _FootballQuizOption(koText: '새 유니폼을 입은 것', enText: 'Wearing a new kit'),
        _FootballQuizOption(
          koText: '전반전만 뛴 것',
          enText: 'Playing only the first half',
        ),
        _FootballQuizOption(
          koText: '경기장을 청소한 것',
          enText: 'Cleaning the stadium',
        ),
      ],
      correctIndex: 0,
      koExplain: '클린시트는 실점 없이 경기를 끝낸 기록을 뜻합니다.',
      enExplain: 'A clean sheet means finishing without conceding a goal.',
      koNextPoint: '축구 용어는 실제 경기 상황과 묶어 기억한다.',
      enNextPoint:
          'Remember football terms by linking them to match situations.',
    ),
    _McqSeed(
      id: 'hat_trick',
      difficulty: 1,
      category: _QuizCategory.fun,
      koStem: '한 선수가 한 경기에서 3골을 넣으면 보통 무엇이라고 하나?',
      enStem:
          'What is it usually called when one player scores three goals in a match?',
      options: [
        _FootballQuizOption(koText: '해트트릭', enText: 'Hat-trick'),
        _FootballQuizOption(koText: '더블세이브', enText: 'Double save'),
        _FootballQuizOption(koText: '스로인', enText: 'Throw-in'),
        _FootballQuizOption(koText: '파울로스', enText: 'Foul loss'),
      ],
      correctIndex: 0,
      koExplain: '한 경기 3골은 해트트릭이라고 부릅니다.',
      enExplain: 'Scoring three times in one match is called a hat-trick.',
      koNextPoint: '자주 쓰는 축구 용어를 기본 상식으로 챙긴다.',
      enNextPoint: 'Keep common football terms as part of your core knowledge.',
    ),
    _McqSeed(
      id: 'half_time_length',
      difficulty: 1,
      category: _QuizCategory.fun,
      koStem: '일반적인 성인 정식 경기에서 한 하프의 기본 시간은 얼마인가?',
      enStem:
          'In a standard adult match, what is the basic length of one half?',
      options: [
        _FootballQuizOption(koText: '45분', enText: '45 minutes'),
        _FootballQuizOption(koText: '30분', enText: '30 minutes'),
        _FootballQuizOption(koText: '60분', enText: '60 minutes'),
        _FootballQuizOption(koText: '20분', enText: '20 minutes'),
      ],
      correctIndex: 0,
      koExplain: '일반적인 정식 경기는 전후반 각 45분이 기본입니다.',
      enExplain:
          'A standard adult match is built around two halves of 45 minutes.',
      koNextPoint: '기본 경기 구조를 숫자로 정리한다.',
      enNextPoint: 'Organize the core match structure through its key numbers.',
    ),
    _McqSeed(
      id: 'penalty_distance',
      difficulty: 2,
      category: _QuizCategory.fun,
      koStem: '페널티킥 지점은 골문 중앙에서 약 몇 m 떨어져 있는가?',
      enStem: 'About how far is the penalty mark from the center of the goal?',
      options: [
        _FootballQuizOption(koText: '11m', enText: '11 meters'),
        _FootballQuizOption(koText: '5m', enText: '5 meters'),
        _FootballQuizOption(koText: '20m', enText: '20 meters'),
        _FootballQuizOption(koText: '2m', enText: '2 meters'),
      ],
      correctIndex: 0,
      koExplain: '페널티 마크는 골문 중앙에서 11m 지점입니다.',
      enExplain: 'The penalty mark is 11 meters from the center of the goal.',
      koNextPoint: '경기장 숫자 정보도 규칙 이해에 포함한다.',
      enNextPoint: 'Include pitch numbers as part of learning the laws.',
    ),
    _McqSeed(
      id: 'body_part_field_player',
      difficulty: 1,
      category: _QuizCategory.rules,
      koStem: '필드 플레이어가 일반적인 경기 상황에서 사용할 수 없는 신체 부위는?',
      enStem:
          'Which body part can a field player not normally use during regular play?',
      options: [
        _FootballQuizOption(koText: '손/팔', enText: 'Hand/arm'),
        _FootballQuizOption(koText: '발', enText: 'Foot'),
        _FootballQuizOption(koText: '머리', enText: 'Head'),
        _FootballQuizOption(koText: '가슴', enText: 'Chest'),
      ],
      correctIndex: 0,
      koExplain: '필드 플레이어는 일반적으로 손과 팔을 사용할 수 없습니다.',
      enExplain:
          'Field players are generally not allowed to use the hand or arm.',
      koNextPoint: '기본 금지 동작을 가장 먼저 분명히 한다.',
      enNextPoint: 'Make the core prohibited actions clear first.',
    ),
    _McqSeed(
      id: 'advantage_reason',
      difficulty: 2,
      category: _QuizCategory.rules,
      koStem: '어드밴티지 규칙을 적용하는 주된 이유로 가장 알맞은 것은?',
      enStem: 'What is the main reason for applying the advantage law?',
      options: [
        _FootballQuizOption(
          koText: '공격팀의 유리한 흐름과 기회를 살리기 위해',
          enText:
              'To preserve a beneficial flow and chance for the fouled team',
        ),
        _FootballQuizOption(
          koText: '심판이 덜 뛰기 위해',
          enText: 'So the referee can run less',
        ),
        _FootballQuizOption(
          koText: '항의를 늘리기 위해',
          enText: 'To increase arguments',
        ),
        _FootballQuizOption(
          koText: '시간을 없애기 위해',
          enText: 'To remove time from the match',
        ),
      ],
      correctIndex: 0,
      koExplain: '어드밴티지는 실제 이득이 이어질 때 경기를 살리기 위한 판정입니다.',
      enExplain:
          'Advantage is used to keep play alive when a real benefit remains.',
      koNextPoint: '심판 규칙도 경기 흐름 관점에서 이해한다.',
      enNextPoint: 'Understand refereeing through the flow of the match.',
    ),
    _McqSeed(
      id: 'late_lead_choice',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koStem: '경기 막판 리드 상황에서 안정적인 선택으로 가장 알맞은 것은?',
      enStem:
          'Late in a match while leading, which choice is generally the most stable?',
      options: [
        _FootballQuizOption(
          koText: '짧은 연결로 템포를 관리하기',
          enText: 'Managing tempo with short connections',
        ),
        _FootballQuizOption(
          koText: '매번 가장 어려운 전진패스 시도하기',
          enText: 'Forcing the hardest forward pass every time',
        ),
        _FootballQuizOption(
          koText: '전원이 한 번에 최전방 침투하기',
          enText: 'Sending everyone on the same forward run',
        ),
        _FootballQuizOption(
          koText: '아무 소통 없이 각자 플레이하기',
          enText: 'Everyone playing individually without communication',
        ),
      ],
      correctIndex: 0,
      koExplain: '리드 상황에서는 짧고 안정적인 연결이 위험 관리에 유리합니다.',
      enExplain:
          'When protecting a lead, shorter stable links usually manage risk better.',
      koNextPoint: '스코어 상황에 따라 위험 기준을 조정한다.',
      enNextPoint: 'Adjust risk level according to the score state.',
    ),
    _McqSeed(
      id: 'pressing_trigger_bad_touch',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koStem: '압박을 강하게 들어갈 신호로 자주 활용되는 것은?',
      enStem: 'Which cue is commonly used as a pressing trigger?',
      options: [
        _FootballQuizOption(
          koText: '상대의 큰 터치나 불안한 컨트롤',
          enText: 'A heavy touch or shaky control by the opponent',
        ),
        _FootballQuizOption(koText: '하프타임 휘슬', enText: 'The halftime whistle'),
        _FootballQuizOption(
          koText: '관중의 박수',
          enText: 'Applause from the crowd',
        ),
        _FootballQuizOption(koText: '벤치 색상', enText: 'The color of the bench'),
      ],
      correctIndex: 0,
      koExplain: '상대의 큰 터치는 압박 타이밍으로 자주 이용됩니다.',
      enExplain: 'A heavy touch is a classic cue for stepping into pressure.',
      koNextPoint: '압박은 무작정이 아니라 신호를 보고 들어간다.',
      enNextPoint: 'Press with triggers, not just emotion.',
    ),
    _McqSeed(
      id: 'half_space_value',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koStem: '하프스페이스가 자주 중요하게 언급되는 이유로 가장 알맞은 것은?',
      enStem: 'Why is the half-space often considered valuable?',
      options: [
        _FootballQuizOption(
          koText: '전진 패스, 슈팅, 연계가 모두 나오기 좋은 구역이라서',
          enText: 'It supports forward passing, shooting, and combinations',
        ),
        _FootballQuizOption(
          koText: '규칙상 득점이 두 배라서',
          enText: 'Goals count double there by rule',
        ),
        _FootballQuizOption(
          koText: '심판이 접근하지 못해서',
          enText: 'Referees cannot enter it',
        ),
        _FootballQuizOption(
          koText: '오프사이드가 사라져서',
          enText: 'Offside does not exist there',
        ),
      ],
      correctIndex: 0,
      koExplain: '하프스페이스는 다양한 다음 액션이 연결되기 쉬운 구역입니다.',
      enExplain:
          'The half-space is valuable because many next actions can flow from it.',
      koNextPoint: '중앙, 측면, 하프스페이스를 비교해서 본다.',
      enNextPoint: 'Compare center, wing, and half-space usage.',
    ),
    _McqSeed(
      id: 'third_man_run',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koStem: '제3자 움직임(third-man run)의 핵심 목적에 가장 가까운 것은?',
      enStem: 'What is the core purpose of a third-man run?',
      options: [
        _FootballQuizOption(
          koText: '직접 공 없는 선수가 다음 공간을 이어 받도록 만들기',
          enText: 'To let a third player receive the next space or lane',
        ),
        _FootballQuizOption(
          koText: '항상 뒤로만 패스하기',
          enText: 'To force play only backward',
        ),
        _FootballQuizOption(
          koText: '공을 멈춰 두기',
          enText: 'To stop the ball completely',
        ),
        _FootballQuizOption(
          koText: '킥오프만 반복하기',
          enText: 'To repeat kick-offs only',
        ),
      ],
      correctIndex: 0,
      koExplain: '제3자 움직임은 패스 한 번 더 앞의 연결을 만드는 개념입니다.',
      enExplain:
          'A third-man run is about building the next connection beyond the immediate pass.',
      koNextPoint: '바로 앞 선택뿐 아니라 다음 선택도 함께 본다.',
      enNextPoint: 'Read not only the next option but the option after that.',
    ),
  ];
}

int _stableHash(String text) {
  var hash = 0;
  for (final code in text.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return hash;
}
