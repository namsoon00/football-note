// ignore_for_file: unused_element

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
  static const String historyKey = 'skill_quiz_history_v1';

  const SkillQuizScreen({super.key, required this.optionRepository});

  static SkillQuizResumeSummary loadResumeSummary(
    OptionRepository optionRepository,
  ) {
    final session = _QuizSessionSnapshot.tryParse(
      optionRepository.getValue<String>(sessionKey),
    );
    final now = DateTime.now();
    final pendingDueCount = _countDueScheduledWrongItemsLight(
      optionRepository.getValue<String>(pendingWrongScheduleKey),
      now,
    ).length;

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

Set<String> _countDueScheduledWrongItemsLight(String? raw, DateTime now) {
  if (raw == null || raw.trim().isEmpty) return const <String>{};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <String>{};
    final dueConcepts = <String>{};
    for (final item in decoded.whereType<Map>()) {
      final map = item.cast<String, dynamic>();
      final dueAt = DateTime.tryParse(map['dueAt']?.toString() ?? '');
      if (dueAt == null || dueAt.isAfter(now)) {
        continue;
      }
      final questionId = map['questionId']?.toString() ?? '';
      final rawConcept = map['conceptKey']?.toString() ?? questionId;
      final concept = _lightQuizConceptKey(rawConcept);
      if (concept.isEmpty) {
        continue;
      }
      dueConcepts.add(concept);
    }
    return dueConcepts;
  } catch (_) {
    return const <String>{};
  }
}

String _lightQuizConceptKey(String raw) {
  if (raw.isEmpty) return raw;
  return _canonicalQuizConceptKey(
    raw
        .replaceFirst(RegExp(r'^(ox|mcq|sa)_'), '')
        .replaceFirst(RegExp(r'_[0-9]+(?:_[0-9]+_[tf])?$'), ''),
  );
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
  bool _answerRevealed = false;
  bool _finished = false;
  final Set<String> _wrongIds = <String>{};

  DateTime? _questionStartedAt;
  Timer? _speedTimer;
  int _speedLeft = _speedLimitSec;
  _AnswerFx _answerFx = _AnswerFx.none;
  int _suggestionRound = 0;
  final Set<String> _seenSuggestionIds = <String>{};

  @override
  void initState() {
    super.initState();
    _allQuestions = _footballQuizPoolCache;
    _questionMap = {
      for (final question in _allQuestions) question.id: question,
      for (final question in _allQuestions) ..._legacyQuestionAliases(question),
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
      case _QuizEntryAction.library:
        return _openQuizLibrary();
      case _QuizEntryAction.history:
        return _openQuizHistory();
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
      _answerRevealed = snapshot.answerRevealed;
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

  Future<void> _openQuizLibrary() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _QuizLibraryScreen(questions: _allQuestions),
      ),
    );
  }

  void _startSession({
    required List<_FootballQuizQuestion> questions,
    required _QuizMode mode,
    bool clearDueReview = false,
  }) {
    final uniqueQuestions = _dedupeSessionQuestions(questions);
    if (uniqueQuestions.isEmpty) return;
    setState(() {
      _questions = uniqueQuestions;
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
      _answerRevealed = false;
      _finished = false;
      _wrongIds.clear();
      _speedLeft = _speedLimitSec;
      _answerFx = _AnswerFx.none;
      _suggestionRound = 0;
      _seenSuggestionIds.clear();
    });
    _shortAnswerController.clear();
    _pendingResumeSnapshot = null;

    if (clearDueReview) {
      unawaited(_removeDueReviewQuestions(uniqueQuestions));
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
      _answerRevealed = false;
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

  void _revealShortAnswer() {
    if (_finished || _answered || _questions.isEmpty) return;
    final question = _questions[_index];
    if (question.style != _QuestionStyle.shortAnswer) return;
    final responseMs = DateTime.now()
        .difference(_questionStartedAt ?? DateTime.now())
        .inMilliseconds;
    setState(() {
      _answered = true;
      _retryUsed = true;
      _retryFeedback = 'revealed';
      _answerRevealed = true;
      _streak = 0;
      _combo = 0;
      _momentum = (_momentum - 14).clamp(0, 100);
      _wrongIds.add(question.id);
      _answerCount += 1;
      _responseMillisSum += math.max(0, responseMs);
      _answerFx = _AnswerFx.fail;
    });
    unawaited(_trackMetric('football_short_answer_revealed'));
    unawaited(_persistSession());
  }

  String _normalizeShortAnswer(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^a-z0-9가-힣]'), '');
  }

  String _primaryAnswerLabel(_FootballQuizQuestion question) {
    if (question.style == _QuestionStyle.shortAnswer &&
        question.acceptedAnswers.isNotEmpty) {
      return question.acceptedAnswers.first;
    }
    if (question.options.isNotEmpty &&
        question.correctIndex >= 0 &&
        question.correctIndex < question.options.length) {
      return question.options[question.correctIndex].text(
        Localizations.localeOf(context).languageCode == 'ko',
      );
    }
    return '';
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
      _answerRevealed = false;
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
        _answerRevealed = false;
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
      _answerRevealed = false;
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
    await _appendQuizHistory();
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
          actions: _showEntryHubBackButton
              ? null
              : [
                  IconButton(
                    onPressed: _openQuizLibrary,
                    tooltip: isKo ? '전체 문제 보기' : 'Browse all questions',
                    icon: const Icon(Icons.library_books_outlined),
                  ),
                  IconButton(
                    onPressed: _openQuizHistory,
                    tooltip: isKo ? '퀴즈 히스토리' : 'Quiz history',
                    icon: const Icon(Icons.history_outlined),
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
        if (_answerFx == _AnswerFx.fail || _answerFx == _AnswerFx.timeout) ...[
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
                        color: bgColor ??
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
                                color: borderColor ??
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
                if (!_answered &&
                    _retryFeedback == 'incorrect' &&
                    question.style == _QuestionStyle.shortAnswer) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _revealShortAnswer,
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(isKo ? '정답 보기' : 'Reveal answer'),
                  ),
                ],
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
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          question.explainText(isKo),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (_answerRevealed ||
                            question.style == _QuestionStyle.shortAnswer) ...[
                          const SizedBox(height: 8),
                          Text(
                            isKo
                                ? '정답: ${_primaryAnswerLabel(question)}'
                                : 'Answer: ${_primaryAnswerLabel(question)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          isKo
                              ? '다음에 볼 포인트: ${question.nextPoint(true)}'
                              : 'Next focus: ${question.nextPoint(false)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
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
    final suggestions = _buildSuggestionItems(
      recap,
      isKo,
      round: _suggestionRound,
      excludedIds: _seenSuggestionIds,
    );
    final wrongQuestions = _questions
        .where((question) => _wrongIds.contains(question.id))
        .toList(growable: false);

    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF1D4ED8), Color(0xFFF97316)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isKo ? '축구 퀴즈 결과' : 'Football Quiz Result',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                isKo
                    ? '$_score / $total 정답, 정확도 $accuracy%'
                    : '$_score / $total correct, accuracy $accuracy%',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ResultMetricChip(
                    label: isKo ? '최고 연속' : 'Best streak',
                    value: isKo ? '$_bestStreak회' : '$_bestStreak',
                  ),
                  _ResultMetricChip(
                    label: isKo ? '최고 콤보' : 'Best combo',
                    value: isKo ? '$_bestComboRun회' : '$_bestComboRun',
                  ),
                  _ResultMetricChip(
                    label: isKo ? '평균 응답' : 'Avg response',
                    value: '${avgResponse}s',
                  ),
                  _ResultMetricChip(
                    label: isKo ? '타임아웃' : 'Timeouts',
                    value: isKo ? '$_timeouts회' : '$_timeouts',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isKo ? '코치 해설' : 'Coach recap',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
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
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          isKo ? '오늘 결과 한눈에' : 'Session snapshot',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
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
        const SizedBox(height: 18),
        Text(
          isKo ? '다음에 이렇게 이어가세요' : 'Suggested next moves',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        ...suggestions.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SuggestionCard(data: item),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                final currentIds = suggestions.map((item) => item.id).toSet();
                if (_seenSuggestionIds.length >= 15) {
                  _seenSuggestionIds
                    ..clear()
                    ..addAll(currentIds);
                } else {
                  _seenSuggestionIds.addAll(currentIds);
                }
                _suggestionRound += 1;
              });
            },
            icon: const Icon(Icons.refresh_outlined),
            label: Text(isKo ? '다른 제안 보기' : 'Show other suggestions'),
          ),
        ),
        const SizedBox(height: 8),
        if (wrongQuestions.isNotEmpty) ...[
          Text(
            isKo ? '이번에 놓친 문제 다시 보기' : 'Review missed questions',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ...wrongQuestions.map(
            (question) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FlipQuizReviewCard(question: question, isKo: isKo),
            ),
          ),
          const SizedBox(height: 8),
        ],
        FilledButton.icon(
          onPressed: _startFocusSession,
          icon: const Icon(Icons.center_focus_strong_outlined),
          label: Text(isKo ? '약점 집중으로 바로 다시' : 'Retry with focus mode'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _startChallengeSession,
          icon: const Icon(Icons.sports_soccer_outlined),
          label: Text(isKo ? '챌린지 모드로 확장' : 'Expand with challenge mode'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _startReviewSessionFromQueue,
          icon: const Icon(Icons.rule_folder_outlined),
          label: Text(isKo ? '오답 복습 모드' : 'Open review mode'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _openQuizHistory,
          icon: const Icon(Icons.history_outlined),
          label: Text(isKo ? '퀴즈 히스토리 보기' : 'View quiz history'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _openEntryHub,
          icon: const Icon(Icons.home_outlined),
          label: Text(isKo ? '퀴즈 홈으로' : 'Back to quiz home'),
        ),
      ],
    );
  }

  List<_QuizSuggestionItem> _buildSuggestionItems(
    _QuizResultRecap recap,
    bool isKo, {
    required int round,
    required Set<String> excludedIds,
  }) {
    final weakest =
        recap.weakestCategory?.label(isKo) ?? (isKo ? '기본기' : 'basics');
    final reviewCount = _resumeSummary.pendingWrongCount;
    final now = DateTime.now();
    final accuracy =
        _questions.isEmpty ? 0.0 : (_score / _questions.length).clamp(0.0, 1.0);
    final avgSeconds =
        _answerCount == 0 ? 8.0 : (_responseMillisSum / _answerCount) / 1000;
    final timeoutRate = _questions.isEmpty
        ? 0.0
        : (_timeouts / _questions.length).clamp(0.0, 1.0);
    final seedBase = (_score * 31) +
        (_timeouts * 17) +
        (_bestStreak * 13) +
        (_bestComboRun * 7) +
        (_wrongIds.length * 5) +
        (_mode.index * 3) +
        (now.month * 37) +
        now.day;

    int pickIndex(int length, int salt) {
      if (length <= 1) return 0;
      return (seedBase + salt).abs() % length;
    }

    _QuizSuggestionItem pickItem(List<_QuizSuggestionItem> items, int salt) {
      final start = pickIndex(items.length, salt + (round * 23));
      for (var i = 0; i < items.length; i++) {
        final candidate = items[(start + i) % items.length];
        if (!excludedIds.contains(candidate.id)) {
          return candidate;
        }
      }
      return items[start];
    }

    final focusPool = <_QuizSuggestionItem>[
      _QuizSuggestionItem(
        id: 'focus_compression',
        icon: Icons.center_focus_strong_outlined,
        title: isKo ? '$weakest 5문제 압축' : '$weakest 5Q compression',
        body: isKo
            ? '지금은 범위를 넓히기보다 $weakest 문제 5개를 연속으로 잡는 게 가장 빠릅니다.'
            : 'Right now, 5 straight questions in $weakest is the fastest gain.',
      ),
      _QuizSuggestionItem(
        id: 'focus_one_more',
        icon: Icons.track_changes_outlined,
        title: isKo ? '$weakest 한 번 더' : 'One more on $weakest',
        body: isKo
            ? '$weakest만 다시 풀고 끝내면, 다음 세션 첫 3문제 정확도가 확실히 올라갑니다.'
            : 'A short $weakest rerun boosts the first 3 questions next session.',
      ),
      _QuizSuggestionItem(
        id: 'focus_baseline',
        icon: Icons.flag_outlined,
        title: isKo ? '$weakest 기준 세우기' : 'Set a $weakest baseline',
        body: isKo
            ? '$weakest 카테고리에서 3연속 정답만 먼저 만들고 난도를 올려보세요.'
            : 'Build a 3-correct streak in $weakest, then raise difficulty.',
      ),
    ];

    final reviewPool = <_QuizSuggestionItem>[
      _QuizSuggestionItem(
        id: 'review_queue_first',
        icon: Icons.rule_folder_outlined,
        title: isKo ? '오답 큐 우선 정리' : 'Clear review queue first',
        body: reviewCount > 0
            ? (isKo
                ? '복습 대기 $reviewCount문제를 먼저 비우면 다음 세트의 체감 난이도가 내려갑니다.'
                : 'Clearing $reviewCount queued misses lowers the felt difficulty next run.')
            : (isKo
                ? '이번 오답은 복습 큐로 저장됐어요. 다음 세션 시작 전에 3개만 확인해보세요.'
                : 'Misses are queued for review. Check just 3 before the next session.'),
      ),
      _QuizSuggestionItem(
        id: 'review_retry_three',
        icon: Icons.replay_circle_filled_outlined,
        title: isKo ? '오답 3개 재도전' : 'Retry 3 missed questions',
        body: isKo
            ? '틀린 문제를 전부 보지 말고, 오늘은 핵심 오답 3개만 정확히 잡아보세요.'
            : 'Skip full review. Lock in the top 3 misses today.',
      ),
      _QuizSuggestionItem(
        id: 'review_explain_aloud',
        icon: Icons.fact_check_outlined,
        title: isKo ? '정답 근거 말하기' : 'Explain the answer out loud',
        body: isKo
            ? '오답 복습할 때 정답만 보지 말고, 왜 맞는지 한 문장으로 말해보세요.'
            : 'During review, speak one sentence on why the answer is right.',
      ),
    ];

    final tempoPool = <_QuizSuggestionItem>[
      _QuizSuggestionItem(
        id: 'tempo_adjust',
        icon: Icons.bolt_outlined,
        title: isKo ? '속도 리듬 조정' : 'Tune your response tempo',
        body: avgSeconds >= 7.0
            ? (isKo
                ? '답을 확신한 뒤 2초 안에 선택하는 루틴으로 평균 응답 시간을 줄여보세요.'
                : 'After confidence, commit within 2 seconds to cut response time.')
            : (isKo
                ? '지금 속도는 좋습니다. 동일 속도에서 오답률만 낮추는 데 집중해보세요.'
                : 'Speed is strong. Keep tempo and target fewer mistakes.'),
      ),
      _QuizSuggestionItem(
        id: 'tempo_timeout_cut',
        icon: Icons.timer_outlined,
        title: isKo ? '타임아웃 줄이기' : 'Cut timeout risk',
        body: timeoutRate >= 0.18
            ? (isKo
                ? '타임아웃이 잦아요. 확신이 낮으면 먼저 소거법으로 2개부터 지워보세요.'
                : 'Timeouts are frequent. Use elimination quickly to remove 2 options first.')
            : (isKo
                ? '타임아웃 관리가 좋아요. 이제 첫 반응의 정확도를 높여보세요.'
                : 'Timeout control is solid. Now improve first-response accuracy.'),
      ),
      _QuizSuggestionItem(
        id: 'tempo_10sec_routine',
        icon: Icons.speed_outlined,
        title: isKo ? '10초 루틴' : '10-second routine',
        body: isKo
            ? '문제 읽기 4초, 판단 4초, 확인 2초 루틴으로 속도와 정확도를 함께 잡아보세요.'
            : 'Use a 4-4-2 routine: read 4s, decide 4s, verify 2s.',
      ),
    ];

    final pathPool = <_QuizSuggestionItem>[
      _QuizSuggestionItem(
        id: 'path_focus_then_challenge',
        icon: Icons.route_outlined,
        title: isKo ? '다음 플레이 순서' : 'Next session path',
        body: isKo
            ? '약점 집중 1세트 후 챌린지 1세트로 이어가면 지루함 없이 성장이 보입니다.'
            : 'One focus set then one challenge set gives cleaner progression.',
      ),
      _QuizSuggestionItem(
        id: 'path_match_transfer',
        icon: Icons.sports_soccer_outlined,
        title: isKo ? '실전 전환 루트' : 'Match-transfer route',
        body: isKo
            ? '오늘 퀴즈에서 틀린 장면을 훈련노트에 1줄로 남기면 실전 연결이 빨라집니다.'
            : 'Write one missed scenario in your note to transfer faster to play.',
      ),
      _QuizSuggestionItem(
        id: 'path_stacked_growth',
        icon: Icons.auto_graph_outlined,
        title: isKo ? '누적 성장 루트' : 'Stacked growth route',
        body: isKo
            ? '오늘은 정확도, 내일은 속도처럼 하루 목표를 나누면 체감 성장폭이 커집니다.'
            : 'Split goals by day (accuracy today, speed tomorrow) for clearer gains.',
      ),
    ];

    final confidencePool = <_QuizSuggestionItem>[
      _QuizSuggestionItem(
        id: 'confidence_form_check',
        icon: Icons.workspace_premium_outlined,
        title: isKo ? '현재 폼 평가' : 'Current form check',
        body: accuracy >= 0.8
            ? (isKo
                ? '지금은 상위 구간입니다. 새 문제를 늘리기보다 실수 1개 줄이기에 집중하세요.'
                : 'You are in a high band. Prioritize reducing one mistake.')
            : accuracy >= 0.6
                ? (isKo
                    ? '중간 구간입니다. 약점 카테고리 집중이 성장을 가장 빠르게 만듭니다.'
                    : 'Mid band now. Weak-category focus gives the fastest lift.')
                : (isKo
                    ? '기초 재정렬 구간입니다. 짧게 자주 풀어 리듬부터 회복하세요.'
                    : 'Rebuild phase. Go short and frequent to recover rhythm.'),
      ),
      _QuizSuggestionItem(
        id: 'confidence_habit_check',
        icon: Icons.psychology_alt_outlined,
        title: isKo ? '판단 습관 점검' : 'Decision habit check',
        body: isKo
            ? '헷갈리는 문제는 답을 바꾸기보다 첫 판단 근거를 먼저 확인해보세요.'
            : 'On tricky items, verify your first rationale before switching answers.',
      ),
      _QuizSuggestionItem(
        id: 'confidence_one_line',
        icon: Icons.lightbulb_outline,
        title: isKo ? '오늘의 핵심 한 줄' : 'One-line takeaway',
        body: isKo
            ? '오늘 가장 자주 헷갈린 포인트를 한 줄로 남기면 재발률이 크게 줄어듭니다.'
            : 'Keep one line on your most repeated confusion to cut repeat errors.',
      ),
    ];

    return [
      pickItem(focusPool, 11),
      pickItem(reviewPool, 29),
      pickItem(tempoPool, 47),
      pickItem(pathPool, 71),
      pickItem(confidencePool, 97),
    ];
  }

  Future<void> _appendQuizHistory() async {
    if (_questions.isEmpty) return;
    final existing = _QuizHistoryEntry.decodeList(
      widget.optionRepository.getValue<String>(SkillQuizScreen.historyKey),
    ).take(19).toList(growable: true);
    final finishedAt = DateTime.now();
    final wrongQuestions = _questions
        .where((question) => _wrongIds.contains(question.id))
        .map(
          (question) => _QuizHistoryQuestion(
            id: question.id,
            promptKo: question.prompt(true),
            promptEn: question.prompt(false),
            answerKo: question.displayAnswer(true),
            answerEn: question.displayAnswer(false),
            explanationKo: question.explainText(true),
            explanationEn: question.explainText(false),
            category: question.category.name,
            style: question.style.name,
          ),
        )
        .toList(growable: false);
    existing.insert(
      0,
      _QuizHistoryEntry(
        id: finishedAt.microsecondsSinceEpoch.toString(),
        mode: _mode.name,
        finishedAt: finishedAt,
        totalQuestions: _questions.length,
        score: _score,
        bestStreak: _bestStreak,
        bestCombo: _bestComboRun,
        timeouts: _timeouts,
        avgResponseMs:
            _answerCount == 0 ? 0 : (_responseMillisSum ~/ _answerCount),
        wrongQuestions: wrongQuestions,
      ),
    );
    await widget.optionRepository.setValue(
      SkillQuizScreen.historyKey,
      _QuizHistoryEntry.encodeList(existing),
    );
  }

  List<_QuizHistoryEntry> _loadQuizHistory() {
    return _QuizHistoryEntry.decodeList(
      widget.optionRepository.getValue<String>(SkillQuizScreen.historyKey),
    );
  }

  Future<void> _openQuizHistory() async {
    final history = _loadQuizHistory();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _QuizHistoryScreen(history: history),
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
        answerRevealed: _answerRevealed,
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
      _answerRevealed = false;
      _answerFx = _AnswerFx.none;
      _index = 0;
      _score = 0;
      _streak = 0;
      _combo = 0;
      _momentum = 0;
      _speedLeft = _speedLimitSec;
      _suggestionRound = 0;
      _seenSuggestionIds.clear();
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
    final history = _loadQuizHistory();
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
        title: isKo ? '챌린지 모드' : 'Challenge mix',
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
      if (_resumeSummary.pendingWrongCount > 0)
        _QuizEntryCardData(
          action: _QuizEntryAction.review,
          icon: Icons.rule_folder_outlined,
          title: isKo ? '오답 복습' : 'Review mode',
          subtitle: isKo
              ? '지금 풀 수 있는 오답 ${_resumeSummary.pendingWrongCount}문제가 대기 중입니다'
              : '${_resumeSummary.pendingWrongCount} review questions are ready now',
          badge: isKo ? '복습 추천' : 'Review',
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
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    label: isKo
                        ? '복습 대기 ${_resumeSummary.pendingWrongCount}개'
                        : 'Review ${_resumeSummary.pendingWrongCount}',
                  ),
                  if (history.isNotEmpty)
                    _InfoChip(
                      label: isKo
                          ? '누적 회차 ${history.length}회'
                          : 'Runs ${history.length}',
                    ),
                  if (_resumeSummary.completedToday)
                    _InfoChip(label: isKo ? '오늘 세트 완료' : 'Today done'),
                ],
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
      answerRevealed: _answerRevealed,
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
    final avgSec =
        _answerCount == 0 ? 8.0 : (_responseMillisSum / _answerCount) / 1000;
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
    final history = _loadQuizHistory();
    final latestHistory = history.isEmpty ? null : history.first;
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
      hasActiveSession: _resumeSummary.hasActiveSession,
      completedToday: _resumeSummary.completedToday,
      historyCount: history.length,
      latestAccuracy: latestHistory?.accuracy ?? 0,
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
    final hardRatio =
        targetDifficulty >= 3 ? 0.45 : (targetDifficulty <= 1 ? 0.15 : 0.30);
    final easyRatio =
        targetDifficulty <= 1 ? 0.45 : (targetDifficulty >= 3 ? 0.18 : 0.25);
    final midRatio = 1 - easyRatio - hardRatio;

    final needEasy = (total * easyRatio).round();
    final needMid = (total * midRatio).round();
    final needHard = total - needEasy - needMid;

    final picked = <_FootballQuizQuestion>[];
    final usedConcepts = <String>{};
    final usedQuestionKeys = <String>{};
    void take(List<_FootballQuizQuestion> from, int need) {
      if (need <= 0) return;
      final takenIndexes = <int>[];
      for (var index = 0; index < from.length; index++) {
        if (takenIndexes.length >= need || picked.length >= total) {
          break;
        }
        final question = from[index];
        final contentKey = _sessionQuestionContentKey(question);
        if (!usedConcepts.add(question.conceptKey)) {
          continue;
        }
        if (!usedQuestionKeys.add(contentKey)) {
          usedConcepts.remove(question.conceptKey);
          continue;
        }
        picked.add(question);
        takenIndexes.add(index);
      }
      for (final index in takenIndexes.reversed) {
        from.removeAt(index);
      }
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
      _appendUniqueQuestions(
        target: picked,
        candidates: remaining,
        count: total - picked.length,
        usedConcepts: usedConcepts,
        usedQuestionKeys: usedQuestionKeys,
      );
    }

    return picked..shuffle(random);
  }

  List<_FootballQuizQuestion> _pickDailyQuestions(math.Random random) {
    final mixedReview = _loadDueReviewQuestions().toList(growable: true)
      ..shuffle(random);
    final mixCount = math.min(mixedReview.length, 2);
    final reviewQuestions = <_FootballQuizQuestion>[];
    final usedConcepts = <String>{};
    final usedQuestionKeys = <String>{};
    var reviewShortAnswerCount = 0;
    for (final question in mixedReview) {
      if (reviewQuestions.length >= mixCount) break;
      final contentKey = _sessionQuestionContentKey(question);
      if (!usedConcepts.add(question.conceptKey)) {
        continue;
      }
      if (!usedQuestionKeys.add(contentKey)) {
        usedConcepts.remove(question.conceptKey);
        continue;
      }
      if (question.style == _QuestionStyle.shortAnswer &&
          reviewShortAnswerCount >= 1) {
        usedConcepts.remove(question.conceptKey);
        usedQuestionKeys.remove(contentKey);
        continue;
      }
      reviewQuestions.add(question);
      if (question.style == _QuestionStyle.shortAnswer) {
        reviewShortAnswerCount += 1;
      }
    }
    final excludedIds = reviewQuestions.map((question) => question.id).toSet();
    final remainingCount = math.max(0, _dailyCount - reviewQuestions.length);
    final ox = _allQuestions
        .where((q) => q.style == _QuestionStyle.ox)
        .where((q) => !excludedIds.contains(q.id))
        .toList(growable: false)
      ..shuffle(random);
    final mcq = _allQuestions
        .where((q) => q.style == _QuestionStyle.multipleChoice)
        .where((q) => !excludedIds.contains(q.id))
        .toList(growable: false)
      ..shuffle(random);
    final shortAnswer = _allQuestions
        .where((q) => q.style == _QuestionStyle.shortAnswer)
        .where((q) => !excludedIds.contains(q.id))
        .toList(growable: false)
      ..shuffle(random);
    final shortCount = (reviewShortAnswerCount == 0 &&
            remainingCount > 0 &&
            shortAnswer.isNotEmpty)
        ? 1
        : 0;
    final objectiveCount = remainingCount - shortCount;
    final oxCount = objectiveCount ~/ 2;
    final mcqCount = objectiveCount - oxCount;
    final picked = <_FootballQuizQuestion>[...reviewQuestions];
    _appendUniqueQuestions(
      target: picked,
      candidates: ox,
      count: oxCount,
      usedConcepts: usedConcepts,
      usedQuestionKeys: usedQuestionKeys,
    );
    _appendUniqueQuestions(
      target: picked,
      candidates: mcq,
      count: mcqCount,
      usedConcepts: usedConcepts,
      usedQuestionKeys: usedQuestionKeys,
    );
    _appendUniqueQuestions(
      target: picked,
      candidates: shortAnswer,
      count: shortCount,
      usedConcepts: usedConcepts,
      usedQuestionKeys: usedQuestionKeys,
    );
    if (picked.length < _dailyCount) {
      final rest = <_FootballQuizQuestion>[
        ..._allQuestions.where(
          (q) =>
              !picked.any((pickedQuestion) => pickedQuestion.id == q.id) &&
              !usedConcepts.contains(q.conceptKey) &&
              !usedQuestionKeys.contains(_sessionQuestionContentKey(q)),
        ),
      ]..shuffle(random);
      _appendUniqueQuestions(
        target: picked,
        candidates: rest,
        count: _dailyCount - picked.length,
        usedConcepts: usedConcepts,
        usedQuestionKeys: usedQuestionKeys,
      );
    }
    return picked.take(_dailyCount).toList(growable: false);
  }

  List<_FootballQuizQuestion> _loadDueReviewQuestions() {
    final scheduled = _normalizeScheduledWrongItems(
      widget.optionRepository.getValue<String>(
        SkillQuizScreen.pendingWrongScheduleKey,
      ),
    );
    final now = DateTime.now();
    return _resolveDueReviewQuestionsFromSchedule(
      scheduled.where((item) => !item.dueAt.isAfter(now)),
      _questionMap,
      {for (final question in _allQuestions) question.conceptKey: question},
    );
  }

  void _appendUniqueQuestions({
    required List<_FootballQuizQuestion> target,
    required Iterable<_FootballQuizQuestion> candidates,
    required int count,
    required Set<String> usedConcepts,
    required Set<String> usedQuestionKeys,
  }) {
    if (count <= 0) return;
    var added = 0;
    for (final question in candidates) {
      if (added >= count) {
        break;
      }
      final contentKey = _sessionQuestionContentKey(question);
      if (!usedConcepts.add(question.conceptKey)) {
        continue;
      }
      if (!usedQuestionKeys.add(contentKey)) {
        usedConcepts.remove(question.conceptKey);
        continue;
      }
      target.add(question);
      added += 1;
    }
  }

  List<_FootballQuizQuestion> _dedupeSessionQuestions(
    List<_FootballQuizQuestion> source,
  ) {
    final seenConcepts = <String>{};
    final seenContentKeys = <String>{};
    final unique = <_FootballQuizQuestion>[];
    for (final question in source) {
      final contentKey = _sessionQuestionContentKey(question);
      if (!seenConcepts.add(question.conceptKey)) continue;
      if (!seenContentKeys.add(contentKey)) continue;
      unique.add(question);
    }
    return unique;
  }

  String _sessionQuestionContentKey(_FootballQuizQuestion question) {
    String normalize(String text) =>
        text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

    final optionKey = question.options
        .map(
          (option) => '${normalize(option.koText)}|${normalize(option.enText)}',
        )
        .join('||');
    final answers = [...question.acceptedAnswers]
      ..sort((a, b) => a.compareTo(b));
    final answerKey = answers.map(normalize).join('|');
    return [
      normalize(question.koPrompt),
      normalize(question.enPrompt),
      optionKey,
      question.correctIndex.toString(),
      answerKey,
    ].join('::');
  }

  Future<void> _removeDueReviewQuestions(
    List<_FootballQuizQuestion> questions,
  ) async {
    if (questions.isEmpty) return;
    final concepts = questions.map((question) => question.conceptKey).toSet();
    final current = _normalizeScheduledWrongItems(
      widget.optionRepository.getValue<String>(
        SkillQuizScreen.pendingWrongScheduleKey,
      ),
    );
    final next = current
        .where((item) => !concepts.contains(item.conceptKey))
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
    final current = _normalizeScheduledWrongItems(
      widget.optionRepository.getValue<String>(
        SkillQuizScreen.pendingWrongScheduleKey,
      ),
    );
    final map = <String, _ScheduledWrongItem>{
      for (final item in current) item.conceptKey: item,
    };

    final now = DateTime.now();
    for (final question in wrongQuestions) {
      final prev = map[question.conceptKey];
      map[question.conceptKey] = _ScheduledWrongItem(
        questionId: question.id,
        conceptKey: question.conceptKey,
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

enum _QuizEntryAction {
  resume,
  daily,
  review,
  challenge,
  focus,
  speed,
  library,
  history,
}

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
  bool get isCoreFocus =>
      this == _QuizCategory.tactics || this == _QuizCategory.technique;

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
  final String conceptKey;
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
    required this.conceptKey,
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
  String displayAnswer(bool isKo) {
    if (style == _QuestionStyle.shortAnswer && acceptedAnswers.isNotEmpty) {
      return acceptedAnswers.first;
    }
    if (correctIndex >= 0 && correctIndex < options.length) {
      return options[correctIndex].text(isKo);
    }
    return '';
  }

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

Color _quizCategoryAccent(_QuizCategory category) {
  return switch (category) {
    _QuizCategory.rules => const Color(0xFF1565C0),
    _QuizCategory.tactics => const Color(0xFF2E7D32),
    _QuizCategory.technique => const Color(0xFF6A1B9A),
    _QuizCategory.positions => const Color(0xFFE65100),
    _QuizCategory.training => const Color(0xFF00838F),
    _QuizCategory.mindset => const Color(0xFFAD1457),
    _QuizCategory.nutrition => const Color(0xFF558B2F),
    _QuizCategory.fun => const Color(0xFF5D4037),
  };
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
    final accent = _quizCategoryAccent(question.category);

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

class _QuizLibraryScreen extends StatefulWidget {
  final List<_FootballQuizQuestion> questions;

  const _QuizLibraryScreen({required this.questions});

  @override
  State<_QuizLibraryScreen> createState() => _QuizLibraryScreenState();
}

class _QuizLibraryScreenState extends State<_QuizLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  _QuizCategory? _category;
  _QuestionStyle? _style;
  int? _difficulty;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_FootballQuizQuestion> get _filteredQuestions {
    final normalized = _query.trim().toLowerCase();
    final filtered = widget.questions.where((question) {
      if (_category != null && question.category != _category) return false;
      if (_style != null && question.style != _style) return false;
      if (_difficulty != null && question.difficulty != _difficulty) {
        return false;
      }
      if (normalized.isEmpty) return true;
      final haystack = [
        question.koPrompt,
        question.enPrompt,
        question.koExplain,
        question.enExplain,
        question.displayAnswer(true),
        question.displayAnswer(false),
      ].join(' ').toLowerCase();
      return haystack.contains(normalized);
    }).toList(growable: false);
    return _deduplicateQuestionsByConcept(filtered);
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final scheme = Theme.of(context).colorScheme;
    final filtered = _filteredQuestions;
    final coreFocusCount = widget.questions
        .where((question) => question.category.isCoreFocus)
        .length;
    final filteredCoreFocus =
        filtered.where((question) => question.category.isCoreFocus).length;
    final uniqueConceptCount = _deduplicateQuestionsByConcept(
      widget.questions,
    ).length;

    return Scaffold(
      appBar: AppBar(title: Text(isKo ? '전체 문제 보기' : 'Question library')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF14532D),
                  Color(0xFF0F766E),
                  Color(0xFF1D4ED8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isKo ? '코치용 퀴즈 라이브러리' : 'Coach quiz library',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  isKo
                      ? '전체 문제를 카테고리, 유형, 난이도, 검색어로 점검하세요. 기본기와 전술 비중이 높고, 규칙·포지션·대회 상식도 섞여 있습니다.'
                      : 'Inspect the full question bank by category, style, difficulty, and search. Fundamentals and tactics are emphasized while rules, positions, and competition knowledge stay mixed in.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      label: isKo
                          ? '전체 ${widget.questions.length}문제'
                          : 'Total ${widget.questions.length}',
                    ),
                    _InfoChip(
                      label: isKo
                          ? '대표 개념 $uniqueConceptCount개'
                          : 'Concepts $uniqueConceptCount',
                    ),
                    _InfoChip(
                      label: isKo
                          ? '기본기/전술 $coreFocusCount문제'
                          : 'Core focus $coreFocusCount',
                    ),
                    _InfoChip(
                      label: isKo
                          ? '현재 필터 ${filtered.length}문제'
                          : 'Filtered ${filtered.length}',
                    ),
                    _InfoChip(
                      label: isKo ? '자동 검증 통과' : 'Auto validation passed',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: isKo ? '검색 지우기' : 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                    labelText: isKo
                        ? '문제/정답/해설 검색'
                        : 'Search prompt/answer/explanation',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _LibraryDropdown<_QuizCategory>(
                      label: isKo ? '카테고리' : 'Category',
                      allLabel: isKo ? '전체 카테고리' : 'All categories',
                      value: _category,
                      entries: _QuizCategory.values
                          .map(
                            (item) => DropdownMenuItem<_QuizCategory?>(
                              value: item,
                              child: Text(item.label(isKo)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) => setState(() => _category = value),
                    ),
                    _LibraryDropdown<_QuestionStyle>(
                      label: isKo ? '문항 유형' : 'Style',
                      allLabel: isKo ? '전체 유형' : 'All styles',
                      value: _style,
                      entries: _QuestionStyle.values
                          .map(
                            (item) => DropdownMenuItem<_QuestionStyle?>(
                              value: item,
                              child: Text(item.label(isKo)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) => setState(() => _style = value),
                    ),
                    _LibraryDropdown<int>(
                      label: isKo ? '난이도' : 'Difficulty',
                      allLabel: isKo ? '전체 난이도' : 'All difficulties',
                      value: _difficulty,
                      entries: [1, 2, 3]
                          .map(
                            (item) => DropdownMenuItem<int?>(
                              value: item,
                              child: Text(switch (item) {
                                1 => isKo ? '쉬움' : 'Easy',
                                2 => isKo ? '보통' : 'Normal',
                                _ => isKo ? '도전' : 'Hard',
                              }),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) => setState(() => _difficulty = value),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isKo
                      ? '필터 안에서도 기본기/전술 $filteredCoreFocus문제가 유지됩니다.'
                      : '$filteredCoreFocus core-focus questions remain in the current filter.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  isKo
                      ? '조건에 맞는 문제가 없습니다.'
                      : 'No questions match the current filters.',
                ),
              ),
            )
          else
            ...filtered.map(
              (question) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _QuizLibraryCard(question: question, isKo: isKo),
              ),
            ),
        ],
      ),
    );
  }
}

class _LibraryDropdown<T> extends StatelessWidget {
  final String label;
  final String allLabel;
  final T? value;
  final List<DropdownMenuItem<T?>> entries;
  final ValueChanged<T?> onChanged;

  const _LibraryDropdown({
    required this.label,
    required this.allLabel,
    required this.value,
    required this.entries,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<T?>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        items: [
          DropdownMenuItem<T?>(value: null, child: Text(allLabel)),
          ...entries,
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _QuizLibraryCard extends StatelessWidget {
  final _FootballQuizQuestion question;
  final bool isKo;

  const _QuizLibraryCard({required this.question, required this.isKo});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _quizCategoryAccent(question.category);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: question.category.label(isKo)),
              _InfoChip(label: question.style.label(isKo)),
              _InfoChip(label: question.difficultyLabel(isKo)),
              if (question.category.isCoreFocus)
                _InfoChip(label: isKo ? '핵심 집중' : 'Core focus'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.prompt(isKo),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            isKo
                ? '정답: ${question.displayAnswer(true)}'
                : 'Answer: ${question.displayAnswer(false)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            question.explainText(isKo),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.78),
                  height: 1.45,
                ),
          ),
        ],
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

class _ResultMetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _ResultMetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuizSuggestionItem {
  final String id;
  final IconData icon;
  final String title;
  final String body;

  const _QuizSuggestionItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.body,
  });
}

class _SuggestionCard extends StatelessWidget {
  final _QuizSuggestionItem data;

  const _SuggestionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  data.body,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlipQuizReviewCard extends StatefulWidget {
  final dynamic question;
  final bool isKo;

  const _FlipQuizReviewCard({required this.question, required this.isKo});

  @override
  State<_FlipQuizReviewCard> createState() => _FlipQuizReviewCardState();
}

class _FlipQuizReviewCardState extends State<_FlipQuizReviewCard> {
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final prompt = widget.question is _FootballQuizQuestion
        ? (widget.question as _FootballQuizQuestion).prompt(widget.isKo)
        : (widget.question as _QuizHistoryQuestion).prompt(widget.isKo);
    final answer = widget.question is _FootballQuizQuestion
        ? (widget.question as _FootballQuizQuestion).displayAnswer(widget.isKo)
        : (widget.question as _QuizHistoryQuestion).answer(widget.isKo);
    final explanation = widget.question is _FootballQuizQuestion
        ? (widget.question as _FootballQuizQuestion).explainText(widget.isKo)
        : (widget.question as _QuizHistoryQuestion).explanation(widget.isKo);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _showBack = !_showBack),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _showBack
              ? scheme.primary.withValues(alpha: 0.08)
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _showBack ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _showBack
              ? Column(
                  key: const ValueKey('back'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isKo ? '정답 / 해설' : 'Answer / explanation',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      answer,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      explanation,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                  ],
                )
              : Column(
                  key: const ValueKey('front'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isKo ? '문제' : 'Question',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      prompt,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.isKo ? '탭해서 뒤집기' : 'Tap to flip',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _QuizHistoryScreen extends StatelessWidget {
  final List<_QuizHistoryEntry> history;

  const _QuizHistoryScreen({required this.history});

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return Scaffold(
      appBar: AppBar(title: Text(isKo ? '퀴즈 히스토리' : 'Quiz history')),
      body: SafeArea(
        child: history.isEmpty
            ? Center(
                child: Text(
                  isKo
                      ? '아직 저장된 퀴즈 기록이 없습니다.'
                      : 'No quiz history has been saved yet.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  final accuracy = (item.accuracy * 100).round();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      title: Text(
                        item.title(isKo),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        isKo
                            ? '${item.score}/${item.totalQuestions} 정답 · 정확도 $accuracy% · 오답 ${item.wrongQuestions.length}개'
                            : '${item.score}/${item.totalQuestions} correct · $accuracy% · ${item.wrongQuestions.length} misses',
                      ),
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(
                              label: isKo
                                  ? '최고 연속 ${item.bestStreak}회'
                                  : 'Best streak ${item.bestStreak}',
                            ),
                            _InfoChip(
                              label: isKo
                                  ? '최고 콤보 ${item.bestCombo}회'
                                  : 'Best combo ${item.bestCombo}',
                            ),
                            _InfoChip(
                              label: isKo
                                  ? '평균 ${(item.avgResponseMs / 1000).toStringAsFixed(1)}초'
                                  : 'Avg ${(item.avgResponseMs / 1000).toStringAsFixed(1)}s',
                            ),
                            _InfoChip(
                              label: isKo
                                  ? '타임아웃 ${item.timeouts}회'
                                  : 'Timeouts ${item.timeouts}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (item.wrongQuestions.isEmpty)
                          Text(
                            isKo
                                ? '이 회차는 오답 없이 마무리했습니다.'
                                : 'This run finished with no missed questions.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          )
                        else
                          ...item.wrongQuestions.asMap().entries.map(
                                (entry) => Padding(
                                  key: ValueKey(
                                    'quiz-history-wrong-${item.finishedAt.toIso8601String()}-${entry.value.id}-${entry.key}',
                                  ),
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _FlipQuizReviewCard(
                                    question: entry.value,
                                    isKo: isKo,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  );
                },
              ),
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
    final bgColor =
        danger ? const Color(0x1AEB5757) : scheme.surfaceContainerHighest;
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
  final bool answerRevealed;
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
    required this.answerRevealed,
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
        'answerRevealed': answerRevealed,
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
        answerRevealed: decoded['answerRevealed'] == true,
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

class _QuizHistoryQuestion {
  final String id;
  final String promptKo;
  final String promptEn;
  final String answerKo;
  final String answerEn;
  final String explanationKo;
  final String explanationEn;
  final String category;
  final String style;

  const _QuizHistoryQuestion({
    required this.id,
    required this.promptKo,
    required this.promptEn,
    required this.answerKo,
    required this.answerEn,
    required this.explanationKo,
    required this.explanationEn,
    required this.category,
    required this.style,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'promptKo': promptKo,
        'promptEn': promptEn,
        'answerKo': answerKo,
        'answerEn': answerEn,
        'explanationKo': explanationKo,
        'explanationEn': explanationEn,
        'category': category,
        'style': style,
      };

  String prompt(bool isKo) => isKo ? promptKo : promptEn;
  String answer(bool isKo) => isKo ? answerKo : answerEn;
  String explanation(bool isKo) => isKo ? explanationKo : explanationEn;

  static _QuizHistoryQuestion? fromMap(Map<String, dynamic> map) {
    final id = map['id']?.toString() ?? '';
    if (id.isEmpty) return null;
    return _QuizHistoryQuestion(
      id: id,
      promptKo: map['promptKo']?.toString() ?? '',
      promptEn: map['promptEn']?.toString() ?? '',
      answerKo: map['answerKo']?.toString() ?? '',
      answerEn: map['answerEn']?.toString() ?? '',
      explanationKo: map['explanationKo']?.toString() ?? '',
      explanationEn: map['explanationEn']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      style: map['style']?.toString() ?? '',
    );
  }
}

class _QuizHistoryEntry {
  final String id;
  final String mode;
  final DateTime finishedAt;
  final int totalQuestions;
  final int score;
  final int bestStreak;
  final int bestCombo;
  final int timeouts;
  final int avgResponseMs;
  final List<_QuizHistoryQuestion> wrongQuestions;

  const _QuizHistoryEntry({
    required this.id,
    required this.mode,
    required this.finishedAt,
    required this.totalQuestions,
    required this.score,
    required this.bestStreak,
    required this.bestCombo,
    required this.timeouts,
    required this.avgResponseMs,
    required this.wrongQuestions,
  });

  double get accuracy => totalQuestions == 0 ? 0 : score / totalQuestions;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'mode': mode,
        'finishedAt': finishedAt.toIso8601String(),
        'totalQuestions': totalQuestions,
        'score': score,
        'bestStreak': bestStreak,
        'bestCombo': bestCombo,
        'timeouts': timeouts,
        'avgResponseMs': avgResponseMs,
        'wrongQuestions': wrongQuestions.map((item) => item.toMap()).toList(),
      };

  String title(bool isKo) {
    final modeLabel =
        _QuizModeX.tryParse(mode)?.label(isKo) ?? (isKo ? '퀴즈' : 'Quiz');
    final date = '${finishedAt.year.toString().padLeft(4, '0')}.'
        '${finishedAt.month.toString().padLeft(2, '0')}.'
        '${finishedAt.day.toString().padLeft(2, '0')} '
        '${finishedAt.hour.toString().padLeft(2, '0')}:'
        '${finishedAt.minute.toString().padLeft(2, '0')}';
    return '$date · $modeLabel';
  }

  static String encodeList(List<_QuizHistoryEntry> entries) =>
      jsonEncode(entries.map((item) => item.toMap()).toList(growable: false));

  static List<_QuizHistoryEntry> decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <_QuizHistoryEntry>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <_QuizHistoryEntry>[];
      return decoded
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .map((map) {
            final id = map['id']?.toString() ?? '';
            final finishedAt = DateTime.tryParse(
              map['finishedAt']?.toString() ?? '',
            );
            if (id.isEmpty || finishedAt == null) return null;
            final wrongQuestions = (map['wrongQuestions'] as List?)
                    ?.whereType<Map>()
                    .map(
                      (item) => _QuizHistoryQuestion.fromMap(
                        item.cast<String, dynamic>(),
                      ),
                    )
                    .whereType<_QuizHistoryQuestion>()
                    .toList(growable: false) ??
                const <_QuizHistoryQuestion>[];
            return _QuizHistoryEntry(
              id: id,
              mode: map['mode']?.toString() ?? _QuizMode.daily.name,
              finishedAt: finishedAt,
              totalQuestions: (map['totalQuestions'] as num?)?.toInt() ?? 0,
              score: (map['score'] as num?)?.toInt() ?? 0,
              bestStreak: (map['bestStreak'] as num?)?.toInt() ?? 0,
              bestCombo: (map['bestCombo'] as num?)?.toInt() ?? 0,
              timeouts: (map['timeouts'] as num?)?.toInt() ?? 0,
              avgResponseMs: (map['avgResponseMs'] as num?)?.toInt() ?? 0,
              wrongQuestions: wrongQuestions,
            );
          })
          .whereType<_QuizHistoryEntry>()
          .toList(growable: false);
    } catch (_) {
      return const <_QuizHistoryEntry>[];
    }
  }
}

class _ScheduledWrongItem {
  final String questionId;
  final String conceptKey;
  final DateTime dueAt;
  final int wrongCount;
  final DateTime lastWrongAt;

  const _ScheduledWrongItem({
    required this.questionId,
    required this.conceptKey,
    required this.dueAt,
    required this.wrongCount,
    required this.lastWrongAt,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
        'questionId': questionId,
        'conceptKey': conceptKey,
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
            final questionId = map['questionId']?.toString() ?? '';
            return _ScheduledWrongItem(
              questionId: questionId,
              conceptKey: _quizConceptKeyForQuestionId(
                map['conceptKey']?.toString() ?? questionId,
              ),
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
  final bool hasActiveSession;
  final bool completedToday;
  final int historyCount;
  final double latestAccuracy;

  const _QuizPersonalization({
    required this.weakestCategory,
    required this.recommendedCategory,
    required this.positionLabel,
    required this.dueReviewCount,
    required this.hasActiveSession,
    required this.completedToday,
    required this.historyCount,
    required this.latestAccuracy,
  });

  String heroSubtitle(bool isKo) {
    if (hasActiveSession) {
      return isKo
          ? '진행 중인 세션이 있습니다. 이어서 마무리하는 것이 오늘 추천입니다.'
          : 'You already have a live session. Finishing it is today’s best move.';
    }
    if (completedToday) {
      return isKo
          ? '오늘 세트는 완료했습니다. 이제 변형 모드로 감을 넓혀보세요.'
          : 'Today’s set is done. Expand the rhythm with a different mode now.';
    }
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
    if (historyCount > 0) {
      final percent = (latestAccuracy * 100).round();
      return isKo
          ? '최근 정확도는 $percent%입니다. 오늘은 집중 모드로 약점 한 번 정리한 뒤 챌린지 모드로 넘어가세요.'
          : 'Your latest accuracy was $percent%. Use focus mode first, then move into challenge mode.';
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
  final String conceptKey;
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
    required this.conceptKey,
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

class _ShortAnswerKnowledgeSeed {
  final String id;
  final int difficulty;
  final _QuizCategory category;
  final String koClue;
  final String enClue;
  final List<String> acceptedAnswers;
  final String koExplain;
  final String enExplain;
  final String koNextPoint;
  final String enNextPoint;

  const _ShortAnswerKnowledgeSeed({
    required this.id,
    required this.difficulty,
    required this.category,
    required this.koClue,
    required this.enClue,
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
        conceptKey: _canonicalQuizConceptKey(
          fact.id.replaceFirst(RegExp(r'_[0-9]+$'), ''),
        ),
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
        conceptKey: _canonicalQuizConceptKey(
          seed.id.replaceFirst(RegExp(r'_[0-9]+$'), ''),
        ),
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
        conceptKey: _canonicalQuizConceptKey(seed.conceptKey),
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

  final expectedSourceCount =
      oxFacts.length + mcqSeeds.length + shortSeeds.length;
  if (questions.length != expectedSourceCount) {
    throw StateError(
      'Football quiz pool size mismatch. expected=$expectedSourceCount actual=${questions.length}',
    );
  }
  final deduplicated = _deduplicateQuizQuestions(questions);
  _runQuizPoolQualityChecks(deduplicated);
  return deduplicated;
}

List<_FootballQuizQuestion> _deduplicateQuizQuestions(
  List<_FootballQuizQuestion> source,
) {
  String normalize(String text) =>
      text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  final seen = <String>{};
  final unique = <_FootballQuizQuestion>[];
  for (final question in source) {
    final optionKey = question.options
        .map(
          (option) => '${normalize(option.koText)}|${normalize(option.enText)}',
        )
        .join('||');
    final answers = [...question.acceptedAnswers]
      ..sort((a, b) => a.compareTo(b));
    final answerKey = answers.map(normalize).join('|');
    final key = [
      question.style.name,
      question.category.name,
      normalize(question.koPrompt),
      normalize(question.enPrompt),
      optionKey,
      question.correctIndex.toString(),
      answerKey,
    ].join('::');
    if (seen.add(key)) {
      unique.add(question);
    }
  }
  return unique;
}

List<_FootballQuizQuestion> _deduplicateQuestionsByConcept(
  Iterable<_FootballQuizQuestion> questions,
) {
  final seenConcepts = <String>{};
  final unique = <_FootballQuizQuestion>[];
  for (final question in questions) {
    if (!seenConcepts.add(question.conceptKey)) {
      continue;
    }
    unique.add(question);
  }
  return unique;
}

List<_OxFactSeed> _buildOxSeedPool300() {
  return _oxFacts();
}

List<_McqSeed> _buildMcqSeedPool300() {
  return <_McqSeed>[..._mcqSeeds(), ..._generatedGlobalFootballMcqSeeds()];
}

List<_ShortAnswerSeed> _buildShortAnswerSeedPool300() {
  final keywords = _shortAnswerKnowledgeSeeds();
  final seeded = keywords.asMap().entries.map((entry) {
    final i = entry.key;
    final key = entry.value;
    return _ShortAnswerSeed(
      id: 'short_$i',
      conceptKey: key.id,
      difficulty: key.difficulty,
      category: key.category,
      koPrompt: '다음 설명의 용어를 입력하세요: "${key.koClue}"',
      enPrompt: 'Write the term for: "${key.enClue}"',
      acceptedAnswers: key.acceptedAnswers,
      koExplain: key.koExplain,
      enExplain: key.enExplain,
      koNextPoint: key.koNextPoint,
      enNextPoint: key.enNextPoint,
    );
  }).toList(growable: false);
  return <_ShortAnswerSeed>[
    ...seeded,
    ..._generatedGlobalFootballShortAnswerSeeds(),
  ];
}

class _KoEnPair {
  final String ko;
  final String en;

  const _KoEnPair({required this.ko, required this.en});
}

List<_McqSeed> _generatedGlobalFootballMcqSeeds() {
  final generated = <_McqSeed>[];

  const positionPool = <_KoEnPair>[
    _KoEnPair(ko: '골키퍼', en: 'Goalkeeper'),
    _KoEnPair(ko: '센터백', en: 'Center Back'),
    _KoEnPair(ko: '풀백', en: 'Full Back'),
    _KoEnPair(ko: '수비형 미드필더', en: 'Defensive Midfielder'),
    _KoEnPair(ko: '중앙 미드필더', en: 'Central Midfielder'),
    _KoEnPair(ko: '공격형 미드필더', en: 'Attacking Midfielder'),
    _KoEnPair(ko: '윙어', en: 'Winger'),
    _KoEnPair(ko: '스트라이커', en: 'Striker'),
  ];

  final playerFacts = _playerKnowledgeBank();
  for (var i = 0; i < playerFacts.length; i++) {
    final player = playerFacts[i];
    final correct = _KoEnPair(ko: player.koPosition, en: player.enPosition);
    generated.add(
      _McqSeed(
        id: 'gen_player_pos_${player.id}',
        difficulty: 2,
        category: _QuizCategory.positions,
        koStem: '${player.koName}의 주 포지션은 무엇일까요?',
        enStem: 'What is ${player.enName}\'s primary position?',
        options: _buildOptionsFromPool(
          pool: positionPool,
          correct: correct,
          seed: i * 17 + 11,
        ),
        correctIndex: _correctIndexFromOptions(
          options: _buildOptionsFromPool(
            pool: positionPool,
            correct: correct,
            seed: i * 17 + 11,
          ),
          correct: correct,
        ),
        koExplain: '${player.koName}는 주로 ${player.koPosition} 역할로 알려져 있습니다.',
        enExplain:
            '${player.enName} is primarily known for the ${player.enPosition} role.',
        koNextPoint: '포지션별 기본 임무를 함께 기억해두세요.',
        enNextPoint: 'Also remember the basic tasks of that position.',
      ),
    );
  }

  const leaguePool = <_KoEnPair>[
    _KoEnPair(ko: '프리미어리그', en: 'Premier League'),
    _KoEnPair(ko: '라리가', en: 'LaLiga'),
    _KoEnPair(ko: '분데스리가', en: 'Bundesliga'),
    _KoEnPair(ko: '세리에 A', en: 'Serie A'),
    _KoEnPair(ko: '리그 1', en: 'Ligue 1'),
    _KoEnPair(ko: '에레디비시', en: 'Eredivisie'),
    _KoEnPair(ko: '프리메이라 리가', en: 'Primeira Liga'),
    _KoEnPair(ko: '스코티시 프리미어십', en: 'Scottish Premiership'),
    _KoEnPair(ko: '쉬페르리그', en: 'Super Lig'),
    _KoEnPair(ko: '사우디 프로리그', en: 'Saudi Pro League'),
  ];
  final clubFacts = _clubKnowledgeBank();
  for (var i = 0; i < clubFacts.length; i++) {
    final club = clubFacts[i];
    final correct = _KoEnPair(ko: club.koLeague, en: club.enLeague);
    generated.add(
      _McqSeed(
        id: 'gen_club_league_${club.id}',
        difficulty: 2,
        category: _QuizCategory.fun,
        koStem: '${club.koName}가 주로 뛰는 리그는?',
        enStem: 'Which league does ${club.enName} play in?',
        options: _buildOptionsFromPool(
          pool: leaguePool,
          correct: correct,
          seed: i * 13 + 7,
        ),
        correctIndex: _correctIndexFromOptions(
          options: _buildOptionsFromPool(
            pool: leaguePool,
            correct: correct,
            seed: i * 13 + 7,
          ),
          correct: correct,
        ),
        koExplain: '${club.koName}는 ${club.koLeague} 소속으로 알려져 있습니다.',
        enExplain: '${club.enName} is known as a ${club.enLeague} club.',
        koNextPoint: '리그별 경기 템포 차이도 함께 관찰해보세요.',
        enNextPoint: 'Observe tempo differences across leagues as well.',
      ),
    );
  }

  const confederationPool = <_KoEnPair>[
    _KoEnPair(ko: 'FIFA', en: 'FIFA'),
    _KoEnPair(ko: 'UEFA', en: 'UEFA'),
    _KoEnPair(ko: 'CONMEBOL', en: 'CONMEBOL'),
    _KoEnPair(ko: 'AFC', en: 'AFC'),
    _KoEnPair(ko: 'CAF', en: 'CAF'),
    _KoEnPair(ko: 'CONCACAF', en: 'CONCACAF'),
    _KoEnPair(ko: 'IOC', en: 'IOC'),
  ];
  final tournamentFacts = _tournamentKnowledgeBank();
  for (var i = 0; i < tournamentFacts.length; i++) {
    final tournament = tournamentFacts[i];
    final correct = _KoEnPair(
      ko: tournament.koOrganizer,
      en: tournament.enOrganizer,
    );
    generated.add(
      _McqSeed(
        id: 'gen_tournament_org_${tournament.id}',
        difficulty: 2,
        category: _QuizCategory.rules,
        koStem: '${tournament.koName}를 주관하는 주된 연맹은?',
        enStem: 'Which body mainly organizes ${tournament.enName}?',
        options: _buildOptionsFromPool(
          pool: confederationPool,
          correct: correct,
          seed: i * 19 + 3,
        ),
        correctIndex: _correctIndexFromOptions(
          options: _buildOptionsFromPool(
            pool: confederationPool,
            correct: correct,
            seed: i * 19 + 3,
          ),
          correct: correct,
        ),
        koExplain:
            '${tournament.koName}는 ${tournament.koOrganizer}가 운영하는 대표 대회입니다.',
        enExplain:
            '${tournament.enName} is mainly run under ${tournament.enOrganizer}.',
        koNextPoint: '대회별 규정과 일정 차이를 함께 확인하세요.',
        enNextPoint: 'Check each competition\'s rule and schedule differences.',
      ),
    );
  }

  // Term-translation quiz type removed by product request.

  return generated;
}

List<_ShortAnswerSeed> _generatedGlobalFootballShortAnswerSeeds() {
  // Term-translation quiz type removed by product request.
  return const <_ShortAnswerSeed>[];
}

List<_FootballQuizOption> _buildOptionsFromPool({
  required List<_KoEnPair> pool,
  required _KoEnPair correct,
  required int seed,
}) {
  final wrong = pool
      .where((item) => item.ko != correct.ko || item.en != correct.en)
      .toList(growable: false);
  final offset = wrong.isEmpty ? 0 : seed.abs() % wrong.length;
  final rotated = wrong.isEmpty
      ? <_KoEnPair>[]
      : <_KoEnPair>[...wrong.sublist(offset), ...wrong.sublist(0, offset)];
  final wrongThree = rotated.take(3).toList(growable: false);
  final slot = seed.abs() % 4;
  final arranged = <_KoEnPair>[];
  var wrongIndex = 0;
  for (var i = 0; i < 4; i++) {
    if (i == slot) {
      arranged.add(correct);
    } else {
      arranged.add(wrongThree[wrongIndex]);
      wrongIndex += 1;
    }
  }
  return arranged
      .map((item) => _FootballQuizOption(koText: item.ko, enText: item.en))
      .toList(growable: false);
}

int _correctIndexFromOptions({
  required List<_FootballQuizOption> options,
  required _KoEnPair correct,
}) {
  for (var i = 0; i < options.length; i++) {
    final option = options[i];
    if (option.koText == correct.ko && option.enText == correct.en) {
      return i;
    }
  }
  return 0;
}

List<
    ({
      String id,
      String koName,
      String enName,
      String koPosition,
      String enPosition,
      String koNation,
      String enNation,
    })> _playerKnowledgeBank() {
  return const [
    (
      id: 'messi',
      koName: '리오넬 메시',
      enName: 'Lionel Messi',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '아르헨티나',
      enNation: 'Argentina',
    ),
    (
      id: 'ronaldo',
      koName: '크리스티아누 호날두',
      enName: 'Cristiano Ronaldo',
      koPosition: '스트라이커',
      enPosition: 'Striker',
      koNation: '포르투갈',
      enNation: 'Portugal',
    ),
    (
      id: 'mbappe',
      koName: '킬리안 음바페',
      enName: 'Kylian Mbappe',
      koPosition: '스트라이커',
      enPosition: 'Striker',
      koNation: '프랑스',
      enNation: 'France',
    ),
    (
      id: 'haaland',
      koName: '엘링 홀란',
      enName: 'Erling Haaland',
      koPosition: '스트라이커',
      enPosition: 'Striker',
      koNation: '노르웨이',
      enNation: 'Norway',
    ),
    (
      id: 'debruyne',
      koName: '케빈 더브라위너',
      enName: 'Kevin De Bruyne',
      koPosition: '중앙 미드필더',
      enPosition: 'Central Midfielder',
      koNation: '벨기에',
      enNation: 'Belgium',
    ),
    (
      id: 'modric',
      koName: '루카 모드리치',
      enName: 'Luka Modric',
      koPosition: '중앙 미드필더',
      enPosition: 'Central Midfielder',
      koNation: '크로아티아',
      enNation: 'Croatia',
    ),
    (
      id: 'kroos',
      koName: '토니 크로스',
      enName: 'Toni Kroos',
      koPosition: '중앙 미드필더',
      enPosition: 'Central Midfielder',
      koNation: '독일',
      enNation: 'Germany',
    ),
    (
      id: 'rodri',
      koName: '로드리',
      enName: 'Rodri',
      koPosition: '수비형 미드필더',
      enPosition: 'Defensive Midfielder',
      koNation: '스페인',
      enNation: 'Spain',
    ),
    (
      id: 'bellingham',
      koName: '주드 벨링엄',
      enName: 'Jude Bellingham',
      koPosition: '중앙 미드필더',
      enPosition: 'Central Midfielder',
      koNation: '잉글랜드',
      enNation: 'England',
    ),
    (
      id: 'salah',
      koName: '모하메드 살라',
      enName: 'Mohamed Salah',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '이집트',
      enNation: 'Egypt',
    ),
    (
      id: 'mane',
      koName: '사디오 마네',
      enName: 'Sadio Mane',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '세네갈',
      enNation: 'Senegal',
    ),
    (
      id: 'son',
      koName: '손흥민',
      enName: 'Son Heung-min',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '대한민국',
      enNation: 'South Korea',
    ),
    (
      id: 'neymar',
      koName: '네이마르',
      enName: 'Neymar',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '브라질',
      enNation: 'Brazil',
    ),
    (
      id: 'vinicius',
      koName: '비니시우스 주니오르',
      enName: 'Vinicius Junior',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '브라질',
      enNation: 'Brazil',
    ),
    (
      id: 'foden',
      koName: '필 포든',
      enName: 'Phil Foden',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '잉글랜드',
      enNation: 'England',
    ),
    (
      id: 'saka',
      koName: '부카요 사카',
      enName: 'Bukayo Saka',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '잉글랜드',
      enNation: 'England',
    ),
    (
      id: 'bruno',
      koName: '브루노 페르난데스',
      enName: 'Bruno Fernandes',
      koPosition: '공격형 미드필더',
      enPosition: 'Attacking Midfielder',
      koNation: '포르투갈',
      enNation: 'Portugal',
    ),
    (
      id: 'odegaard',
      koName: '마르틴 외데고르',
      enName: 'Martin Odegaard',
      koPosition: '공격형 미드필더',
      enPosition: 'Attacking Midfielder',
      koNation: '노르웨이',
      enNation: 'Norway',
    ),
    (
      id: 'pedri',
      koName: '페드리',
      enName: 'Pedri',
      koPosition: '중앙 미드필더',
      enPosition: 'Central Midfielder',
      koNation: '스페인',
      enNation: 'Spain',
    ),
    (
      id: 'gavi',
      koName: '가비',
      enName: 'Gavi',
      koPosition: '중앙 미드필더',
      enPosition: 'Central Midfielder',
      koNation: '스페인',
      enNation: 'Spain',
    ),
    (
      id: 'vandijk',
      koName: '버질 반다이크',
      enName: 'Virgil van Dijk',
      koPosition: '센터백',
      enPosition: 'Center Back',
      koNation: '네덜란드',
      enNation: 'Netherlands',
    ),
    (
      id: 'rubendias',
      koName: '후벵 디아스',
      enName: 'Ruben Dias',
      koPosition: '센터백',
      enPosition: 'Center Back',
      koNation: '포르투갈',
      enNation: 'Portugal',
    ),
    (
      id: 'thiagosilva',
      koName: '티아고 실바',
      enName: 'Thiago Silva',
      koPosition: '센터백',
      enPosition: 'Center Back',
      koNation: '브라질',
      enNation: 'Brazil',
    ),
    (
      id: 'marquinhos',
      koName: '마르키뉴스',
      enName: 'Marquinhos',
      koPosition: '센터백',
      enPosition: 'Center Back',
      koNation: '브라질',
      enNation: 'Brazil',
    ),
    (
      id: 'hakimi',
      koName: '아슈라프 하키미',
      enName: 'Achraf Hakimi',
      koPosition: '풀백',
      enPosition: 'Full Back',
      koNation: '모로코',
      enNation: 'Morocco',
    ),
    (
      id: 'davies',
      koName: '알폰소 데이비스',
      enName: 'Alphonso Davies',
      koPosition: '풀백',
      enPosition: 'Full Back',
      koNation: '캐나다',
      enNation: 'Canada',
    ),
    (
      id: 'robertson',
      koName: '앤디 로버트슨',
      enName: 'Andy Robertson',
      koPosition: '풀백',
      enPosition: 'Full Back',
      koNation: '스코틀랜드',
      enNation: 'Scotland',
    ),
    (
      id: 'taa',
      koName: '트렌트 알렉산더아놀드',
      enName: 'Trent Alexander-Arnold',
      koPosition: '풀백',
      enPosition: 'Full Back',
      koNation: '잉글랜드',
      enNation: 'England',
    ),
    (
      id: 'alisson',
      koName: '알리송',
      enName: 'Alisson',
      koPosition: '골키퍼',
      enPosition: 'Goalkeeper',
      koNation: '브라질',
      enNation: 'Brazil',
    ),
    (
      id: 'ederson',
      koName: '에데르송',
      enName: 'Ederson',
      koPosition: '골키퍼',
      enPosition: 'Goalkeeper',
      koNation: '브라질',
      enNation: 'Brazil',
    ),
    (
      id: 'courtois',
      koName: '티보 쿠르투아',
      enName: 'Thibaut Courtois',
      koPosition: '골키퍼',
      enPosition: 'Goalkeeper',
      koNation: '벨기에',
      enNation: 'Belgium',
    ),
    (
      id: 'terstegen',
      koName: '테어 슈테겐',
      enName: 'Marc-Andre ter Stegen',
      koPosition: '골키퍼',
      enPosition: 'Goalkeeper',
      koNation: '독일',
      enNation: 'Germany',
    ),
    (
      id: 'kane',
      koName: '해리 케인',
      enName: 'Harry Kane',
      koPosition: '스트라이커',
      enPosition: 'Striker',
      koNation: '잉글랜드',
      enNation: 'England',
    ),
    (
      id: 'lewandowski',
      koName: '로베르트 레반도프스키',
      enName: 'Robert Lewandowski',
      koPosition: '스트라이커',
      enPosition: 'Striker',
      koNation: '폴란드',
      enNation: 'Poland',
    ),
    (
      id: 'griezmann',
      koName: '앙투안 그리즈만',
      enName: 'Antoine Griezmann',
      koPosition: '공격형 미드필더',
      enPosition: 'Attacking Midfielder',
      koNation: '프랑스',
      enNation: 'France',
    ),
    (
      id: 'lautaro',
      koName: '라우타로 마르티네스',
      enName: 'Lautaro Martinez',
      koPosition: '스트라이커',
      enPosition: 'Striker',
      koNation: '아르헨티나',
      enNation: 'Argentina',
    ),
    (
      id: 'osimhen',
      koName: '빅터 오시멘',
      enName: 'Victor Osimhen',
      koPosition: '스트라이커',
      enPosition: 'Striker',
      koNation: '나이지리아',
      enNation: 'Nigeria',
    ),
    (
      id: 'kvara',
      koName: '크비차 크바라츠헬리아',
      enName: 'Khvicha Kvaratskhelia',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '조지아',
      enNation: 'Georgia',
    ),
    (
      id: 'palmer',
      koName: '콜 파머',
      enName: 'Cole Palmer',
      koPosition: '공격형 미드필더',
      enPosition: 'Attacking Midfielder',
      koNation: '잉글랜드',
      enNation: 'England',
    ),
    (
      id: 'yamal',
      koName: '라민 야말',
      enName: 'Lamine Yamal',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '스페인',
      enNation: 'Spain',
    ),
    (
      id: 'musiala',
      koName: '자말 무시알라',
      enName: 'Jamal Musiala',
      koPosition: '공격형 미드필더',
      enPosition: 'Attacking Midfielder',
      koNation: '독일',
      enNation: 'Germany',
    ),
    (
      id: 'wirtz',
      koName: '플로리안 비르츠',
      enName: 'Florian Wirtz',
      koPosition: '공격형 미드필더',
      enPosition: 'Attacking Midfielder',
      koNation: '독일',
      enNation: 'Germany',
    ),
    (
      id: 'rice',
      koName: '데클란 라이스',
      enName: 'Declan Rice',
      koPosition: '수비형 미드필더',
      enPosition: 'Defensive Midfielder',
      koNation: '잉글랜드',
      enNation: 'England',
    ),
    (
      id: 'casemiro',
      koName: '카세미루',
      enName: 'Casemiro',
      koPosition: '수비형 미드필더',
      enPosition: 'Defensive Midfielder',
      koNation: '브라질',
      enNation: 'Brazil',
    ),
    (
      id: 'kimmich',
      koName: '요주아 키미히',
      enName: 'Joshua Kimmich',
      koPosition: '수비형 미드필더',
      enPosition: 'Defensive Midfielder',
      koNation: '독일',
      enNation: 'Germany',
    ),
    (
      id: 'enzo',
      koName: '엔소 페르난데스',
      enName: 'Enzo Fernandez',
      koPosition: '중앙 미드필더',
      enPosition: 'Central Midfielder',
      koNation: '아르헨티나',
      enNation: 'Argentina',
    ),
    (
      id: 'valverde',
      koName: '페데리코 발베르데',
      enName: 'Federico Valverde',
      koPosition: '중앙 미드필더',
      enPosition: 'Central Midfielder',
      koNation: '우루과이',
      enNation: 'Uruguay',
    ),
    (
      id: 'dembele',
      koName: '우스만 뎀벨레',
      enName: 'Ousmane Dembele',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '프랑스',
      enNation: 'France',
    ),
    (
      id: 'julianalvarez',
      koName: '훌리안 알바레스',
      enName: 'Julian Alvarez',
      koPosition: '스트라이커',
      enPosition: 'Striker',
      koNation: '아르헨티나',
      enNation: 'Argentina',
    ),
  ];
}

List<
    ({
      String id,
      String koName,
      String enName,
      String koLeague,
      String enLeague
    })> _clubKnowledgeBank() {
  return const [
    (
      id: 'realmadrid',
      koName: '레알 마드리드',
      enName: 'Real Madrid',
      koLeague: '라리가',
      enLeague: 'LaLiga',
    ),
    (
      id: 'barcelona',
      koName: '바르셀로나',
      enName: 'Barcelona',
      koLeague: '라리가',
      enLeague: 'LaLiga',
    ),
    (
      id: 'atleti',
      koName: '아틀레티코 마드리드',
      enName: 'Atletico Madrid',
      koLeague: '라리가',
      enLeague: 'LaLiga',
    ),
    (
      id: 'mancity',
      koName: '맨체스터 시티',
      enName: 'Manchester City',
      koLeague: '프리미어리그',
      enLeague: 'Premier League',
    ),
    (
      id: 'arsenal',
      koName: '아스널',
      enName: 'Arsenal',
      koLeague: '프리미어리그',
      enLeague: 'Premier League',
    ),
    (
      id: 'liverpool',
      koName: '리버풀',
      enName: 'Liverpool',
      koLeague: '프리미어리그',
      enLeague: 'Premier League',
    ),
    (
      id: 'manutd',
      koName: '맨체스터 유나이티드',
      enName: 'Manchester United',
      koLeague: '프리미어리그',
      enLeague: 'Premier League',
    ),
    (
      id: 'chelsea',
      koName: '첼시',
      enName: 'Chelsea',
      koLeague: '프리미어리그',
      enLeague: 'Premier League',
    ),
    (
      id: 'tottenham',
      koName: '토트넘',
      enName: 'Tottenham Hotspur',
      koLeague: '프리미어리그',
      enLeague: 'Premier League',
    ),
    (
      id: 'bayern',
      koName: '바이에른 뮌헨',
      enName: 'Bayern Munich',
      koLeague: '분데스리가',
      enLeague: 'Bundesliga',
    ),
    (
      id: 'dortmund',
      koName: '도르트문트',
      enName: 'Borussia Dortmund',
      koLeague: '분데스리가',
      enLeague: 'Bundesliga',
    ),
    (
      id: 'leverkusen',
      koName: '레버쿠젠',
      enName: 'Bayer Leverkusen',
      koLeague: '분데스리가',
      enLeague: 'Bundesliga',
    ),
    (
      id: 'juventus',
      koName: '유벤투스',
      enName: 'Juventus',
      koLeague: '세리에 A',
      enLeague: 'Serie A',
    ),
    (
      id: 'inter',
      koName: '인터 밀란',
      enName: 'Inter Milan',
      koLeague: '세리에 A',
      enLeague: 'Serie A',
    ),
    (
      id: 'acmilan',
      koName: 'AC 밀란',
      enName: 'AC Milan',
      koLeague: '세리에 A',
      enLeague: 'Serie A',
    ),
    (
      id: 'napoli',
      koName: '나폴리',
      enName: 'Napoli',
      koLeague: '세리에 A',
      enLeague: 'Serie A',
    ),
    (
      id: 'roma',
      koName: '로마',
      enName: 'Roma',
      koLeague: '세리에 A',
      enLeague: 'Serie A',
    ),
    (
      id: 'psg',
      koName: '파리 생제르맹',
      enName: 'Paris Saint-Germain',
      koLeague: '리그 1',
      enLeague: 'Ligue 1',
    ),
    (
      id: 'marseille',
      koName: '마르세유',
      enName: 'Marseille',
      koLeague: '리그 1',
      enLeague: 'Ligue 1',
    ),
    (
      id: 'monaco',
      koName: '모나코',
      enName: 'Monaco',
      koLeague: '리그 1',
      enLeague: 'Ligue 1',
    ),
    (
      id: 'ajax',
      koName: '아약스',
      enName: 'Ajax',
      koLeague: '에레디비시',
      enLeague: 'Eredivisie',
    ),
    (
      id: 'psv',
      koName: 'PSV 아인트호벤',
      enName: 'PSV Eindhoven',
      koLeague: '에레디비시',
      enLeague: 'Eredivisie',
    ),
    (
      id: 'benfica',
      koName: '벤피카',
      enName: 'Benfica',
      koLeague: '프리메이라 리가',
      enLeague: 'Primeira Liga',
    ),
    (
      id: 'sporting',
      koName: '스포르팅 CP',
      enName: 'Sporting CP',
      koLeague: '프리메이라 리가',
      enLeague: 'Primeira Liga',
    ),
    (
      id: 'porto',
      koName: '포르투',
      enName: 'Porto',
      koLeague: '프리메이라 리가',
      enLeague: 'Primeira Liga',
    ),
    (
      id: 'celtic',
      koName: '셀틱',
      enName: 'Celtic',
      koLeague: '스코티시 프리미어십',
      enLeague: 'Scottish Premiership',
    ),
    (
      id: 'galatasaray',
      koName: '갈라타사라이',
      enName: 'Galatasaray',
      koLeague: '쉬페르리그',
      enLeague: 'Super Lig',
    ),
    (
      id: 'fenerbahce',
      koName: '페네르바체',
      enName: 'Fenerbahce',
      koLeague: '쉬페르리그',
      enLeague: 'Super Lig',
    ),
    (
      id: 'alhilal',
      koName: '알 힐랄',
      enName: 'Al Hilal',
      koLeague: '사우디 프로리그',
      enLeague: 'Saudi Pro League',
    ),
    (
      id: 'alnassr',
      koName: '알 나스르',
      enName: 'Al Nassr',
      koLeague: '사우디 프로리그',
      enLeague: 'Saudi Pro League',
    ),
  ];
}

List<
    ({
      String id,
      String koName,
      String enName,
      String koOrganizer,
      String enOrganizer,
    })> _tournamentKnowledgeBank() {
  return const [
    (
      id: 'fifa_world_cup',
      koName: 'FIFA 월드컵',
      enName: 'FIFA World Cup',
      koOrganizer: 'FIFA',
      enOrganizer: 'FIFA',
    ),
    (
      id: 'uefa_euro',
      koName: 'UEFA 유로',
      enName: 'UEFA Euro',
      koOrganizer: 'UEFA',
      enOrganizer: 'UEFA',
    ),
    (
      id: 'copa_america',
      koName: '코파 아메리카',
      enName: 'Copa America',
      koOrganizer: 'CONMEBOL',
      enOrganizer: 'CONMEBOL',
    ),
    (
      id: 'afc_asian_cup',
      koName: 'AFC 아시안컵',
      enName: 'AFC Asian Cup',
      koOrganizer: 'AFC',
      enOrganizer: 'AFC',
    ),
    (
      id: 'afcon',
      koName: '아프리카 네이션스컵',
      enName: 'Africa Cup of Nations',
      koOrganizer: 'CAF',
      enOrganizer: 'CAF',
    ),
    (
      id: 'gold_cup',
      koName: 'CONCACAF 골드컵',
      enName: 'CONCACAF Gold Cup',
      koOrganizer: 'CONCACAF',
      enOrganizer: 'CONCACAF',
    ),
    (
      id: 'ucl',
      koName: 'UEFA 챔피언스리그',
      enName: 'UEFA Champions League',
      koOrganizer: 'UEFA',
      enOrganizer: 'UEFA',
    ),
    (
      id: 'uel',
      koName: 'UEFA 유로파리그',
      enName: 'UEFA Europa League',
      koOrganizer: 'UEFA',
      enOrganizer: 'UEFA',
    ),
    (
      id: 'uecl',
      koName: 'UEFA 컨퍼런스리그',
      enName: 'UEFA Conference League',
      koOrganizer: 'UEFA',
      enOrganizer: 'UEFA',
    ),
    (
      id: 'libertadores',
      koName: '코파 리베르타도레스',
      enName: 'Copa Libertadores',
      koOrganizer: 'CONMEBOL',
      enOrganizer: 'CONMEBOL',
    ),
    (
      id: 'sudamericana',
      koName: '코파 수다메리카나',
      enName: 'Copa Sudamericana',
      koOrganizer: 'CONMEBOL',
      enOrganizer: 'CONMEBOL',
    ),
    (
      id: 'club_world_cup',
      koName: 'FIFA 클럽 월드컵',
      enName: 'FIFA Club World Cup',
      koOrganizer: 'FIFA',
      enOrganizer: 'FIFA',
    ),
    (
      id: 'nations_league',
      koName: 'UEFA 네이션스리그',
      enName: 'UEFA Nations League',
      koOrganizer: 'UEFA',
      enOrganizer: 'UEFA',
    ),
    (
      id: 'olympic_football',
      koName: '올림픽 축구',
      enName: 'Olympic Football Tournament',
      koOrganizer: 'IOC',
      enOrganizer: 'IOC',
    ),
    (
      id: 'u20_world_cup',
      koName: 'FIFA U-20 월드컵',
      enName: 'FIFA U-20 World Cup',
      koOrganizer: 'FIFA',
      enOrganizer: 'FIFA',
    ),
    (
      id: 'u17_world_cup',
      koName: 'FIFA U-17 월드컵',
      enName: 'FIFA U-17 World Cup',
      koOrganizer: 'FIFA',
      enOrganizer: 'FIFA',
    ),
    (
      id: 'afc_champions',
      koName: 'AFC 챔피언스리그',
      enName: 'AFC Champions League Elite',
      koOrganizer: 'AFC',
      enOrganizer: 'AFC',
    ),
    (
      id: 'caf_champions',
      koName: 'CAF 챔피언스리그',
      enName: 'CAF Champions League',
      koOrganizer: 'CAF',
      enOrganizer: 'CAF',
    ),
    (
      id: 'concacaf_champions',
      koName: 'CONCACAF 챔피언스컵',
      enName: 'CONCACAF Champions Cup',
      koOrganizer: 'CONCACAF',
      enOrganizer: 'CONCACAF',
    ),
    (
      id: 'uwcl',
      koName: 'UEFA 여자 챔피언스리그',
      enName: 'UEFA Women Champions League',
      koOrganizer: 'UEFA',
      enOrganizer: 'UEFA',
    ),
  ];
}

List<
    ({
      String id,
      String koTerm,
      String enTerm,
      _QuizCategory category,
      int difficulty,
    })> _footballTermBank() {
  return const [
    (
      id: 'first_touch',
      koTerm: '퍼스트 터치',
      enTerm: 'first touch',
      category: _QuizCategory.technique,
      difficulty: 1,
    ),
    (
      id: 'scanning',
      koTerm: '스캐닝',
      enTerm: 'scanning',
      category: _QuizCategory.tactics,
      difficulty: 2,
    ),
    (
      id: 'body_feint',
      koTerm: '바디 페인트',
      enTerm: 'body feint',
      category: _QuizCategory.technique,
      difficulty: 1,
    ),
    (
      id: 'step_over',
      koTerm: '스텝오버',
      enTerm: 'step-over',
      category: _QuizCategory.technique,
      difficulty: 1,
    ),
    (
      id: 'nutmeg',
      koTerm: '넛메그',
      enTerm: 'nutmeg',
      category: _QuizCategory.technique,
      difficulty: 1,
    ),
    (
      id: 'cutback',
      koTerm: '컷백',
      enTerm: 'cutback',
      category: _QuizCategory.technique,
      difficulty: 1,
    ),
    (
      id: 'overlap',
      koTerm: '오버래핑',
      enTerm: 'overlap',
      category: _QuizCategory.tactics,
      difficulty: 1,
    ),
    (
      id: 'underlap',
      koTerm: '언더래핑',
      enTerm: 'underlap',
      category: _QuizCategory.tactics,
      difficulty: 2,
    ),
    (
      id: 'through_pass',
      koTerm: '스루패스',
      enTerm: 'through pass',
      category: _QuizCategory.technique,
      difficulty: 1,
    ),
    (
      id: 'switch_play',
      koTerm: '전환 패스',
      enTerm: 'switch of play',
      category: _QuizCategory.tactics,
      difficulty: 2,
    ),
    (
      id: 'pressing_trigger',
      koTerm: '압박 트리거',
      enTerm: 'pressing trigger',
      category: _QuizCategory.tactics,
      difficulty: 2,
    ),
    (
      id: 'counter_pressing',
      koTerm: '카운터프레싱',
      enTerm: 'counter-pressing',
      category: _QuizCategory.tactics,
      difficulty: 2,
    ),
    (
      id: 'low_block',
      koTerm: '로우 블록',
      enTerm: 'low block',
      category: _QuizCategory.tactics,
      difficulty: 2,
    ),
    (
      id: 'high_line',
      koTerm: '하이 라인',
      enTerm: 'high line',
      category: _QuizCategory.tactics,
      difficulty: 2,
    ),
    (
      id: 'offside_trap',
      koTerm: '오프사이드 트랩',
      enTerm: 'offside trap',
      category: _QuizCategory.tactics,
      difficulty: 2,
    ),
    (
      id: 'half_space',
      koTerm: '하프스페이스',
      enTerm: 'half-space',
      category: _QuizCategory.tactics,
      difficulty: 2,
    ),
    (
      id: 'third_man_run',
      koTerm: '서드맨 런',
      enTerm: 'third-man run',
      category: _QuizCategory.tactics,
      difficulty: 3,
    ),
    (
      id: 'one_two',
      koTerm: '원투 패스',
      enTerm: 'one-two pass',
      category: _QuizCategory.technique,
      difficulty: 1,
    ),
    (
      id: 'ball_shielding',
      koTerm: '볼 키핑',
      enTerm: 'ball shielding',
      category: _QuizCategory.technique,
      difficulty: 2,
    ),
    (
      id: 'jockeying',
      koTerm: '조키잉',
      enTerm: 'jockeying',
      category: _QuizCategory.technique,
      difficulty: 2,
    ),
    (
      id: 'interception',
      koTerm: '인터셉트',
      enTerm: 'interception',
      category: _QuizCategory.technique,
      difficulty: 1,
    ),
    (
      id: 'man_marking',
      koTerm: '맨마킹',
      enTerm: 'man marking',
      category: _QuizCategory.tactics,
      difficulty: 1,
    ),
    (
      id: 'zonal_marking',
      koTerm: '지역 방어',
      enTerm: 'zonal marking',
      category: _QuizCategory.tactics,
      difficulty: 2,
    ),
    (
      id: 'build_up',
      koTerm: '빌드업',
      enTerm: 'build-up',
      category: _QuizCategory.tactics,
      difficulty: 1,
    ),
    (
      id: 'transition',
      koTerm: '전환',
      enTerm: 'transition',
      category: _QuizCategory.tactics,
      difficulty: 1,
    ),
    (
      id: 'final_third',
      koTerm: '파이널 서드',
      enTerm: 'final third',
      category: _QuizCategory.tactics,
      difficulty: 1,
    ),
    (
      id: 'set_piece',
      koTerm: '세트피스',
      enTerm: 'set piece',
      category: _QuizCategory.tactics,
      difficulty: 1,
    ),
    (
      id: 'near_post_run',
      koTerm: '니어포스트 런',
      enTerm: 'near-post run',
      category: _QuizCategory.tactics,
      difficulty: 2,
    ),
    (
      id: 'far_post_run',
      koTerm: '파포스트 런',
      enTerm: 'far-post run',
      category: _QuizCategory.tactics,
      difficulty: 2,
    ),
    (
      id: 'crossing',
      koTerm: '크로스',
      enTerm: 'crossing',
      category: _QuizCategory.technique,
      difficulty: 1,
    ),
    (
      id: 'volley',
      koTerm: '발리슛',
      enTerm: 'volley',
      category: _QuizCategory.technique,
      difficulty: 1,
    ),
    (
      id: 'half_volley',
      koTerm: '하프 발리',
      enTerm: 'half-volley',
      category: _QuizCategory.technique,
      difficulty: 2,
    ),
    (
      id: 'chest_control',
      koTerm: '가슴 트래핑',
      enTerm: 'chest control',
      category: _QuizCategory.technique,
      difficulty: 1,
    ),
    (
      id: 'instep_pass',
      koTerm: '인사이드 패스',
      enTerm: 'inside-foot pass',
      category: _QuizCategory.technique,
      difficulty: 1,
    ),
    (
      id: 'outside_pass',
      koTerm: '아웃사이드 패스',
      enTerm: 'outside-foot pass',
      category: _QuizCategory.technique,
      difficulty: 2,
    ),
    (
      id: 'weak_foot',
      koTerm: '약발 훈련',
      enTerm: 'weak-foot training',
      category: _QuizCategory.training,
      difficulty: 2,
    ),
    (
      id: 'recovery_run',
      koTerm: '리커버리 런',
      enTerm: 'recovery run',
      category: _QuizCategory.tactics,
      difficulty: 2,
    ),
    (
      id: 'compactness',
      koTerm: '압축성',
      enTerm: 'compactness',
      category: _QuizCategory.tactics,
      difficulty: 2,
    ),
    (
      id: 'line_breaking_pass',
      koTerm: '라인브레이킹 패스',
      enTerm: 'line-breaking pass',
      category: _QuizCategory.tactics,
      difficulty: 3,
    ),
    (
      id: 'progressive_pass',
      koTerm: '전진 패스',
      enTerm: 'progressive pass',
      category: _QuizCategory.tactics,
      difficulty: 2,
    ),
    (
      id: 'diagonal_run',
      koTerm: '대각선 침투',
      enTerm: 'diagonal run',
      category: _QuizCategory.tactics,
      difficulty: 2,
    ),
    (
      id: 'blind_side_run',
      koTerm: '블라인드사이드 런',
      enTerm: 'blind-side run',
      category: _QuizCategory.tactics,
      difficulty: 3,
    ),
    (
      id: 'decoy_run',
      koTerm: '유인 침투',
      enTerm: 'decoy run',
      category: _QuizCategory.tactics,
      difficulty: 2,
    ),
    (
      id: 'hold_up_play',
      koTerm: '포스트 플레이',
      enTerm: 'hold-up play',
      category: _QuizCategory.technique,
      difficulty: 2,
    ),
    (
      id: 'target_man',
      koTerm: '타깃맨',
      enTerm: 'target man',
      category: _QuizCategory.positions,
      difficulty: 1,
    ),
    (
      id: 'false_nine',
      koTerm: '가짜 9번',
      enTerm: 'false nine',
      category: _QuizCategory.positions,
      difficulty: 2,
    ),
    (
      id: 'inverted_winger',
      koTerm: '인버티드 윙어',
      enTerm: 'inverted winger',
      category: _QuizCategory.positions,
      difficulty: 2,
    ),
    (
      id: 'sweeper_keeper',
      koTerm: '스위퍼 키퍼',
      enTerm: 'sweeper-keeper',
      category: _QuizCategory.positions,
      difficulty: 2,
    ),
    (
      id: 'claim_cross',
      koTerm: '크로스 캐치',
      enTerm: 'claim the cross',
      category: _QuizCategory.technique,
      difficulty: 1,
    ),
    (
      id: 'goal_kick_routine',
      koTerm: '골킥 루틴',
      enTerm: 'goal-kick routine',
      category: _QuizCategory.tactics,
      difficulty: 2,
    ),
    (
      id: 'press_resistance',
      koTerm: '압박 저항',
      enTerm: 'press resistance',
      category: _QuizCategory.technique,
      difficulty: 2,
    ),
    (
      id: 'rondo',
      koTerm: '론도',
      enTerm: 'rondo',
      category: _QuizCategory.training,
      difficulty: 1,
    ),
    (
      id: 'small_sided_game',
      koTerm: '소형 게임',
      enTerm: 'small-sided game',
      category: _QuizCategory.training,
      difficulty: 1,
    ),
    (
      id: 'finishing_drill',
      koTerm: '피니시 훈련',
      enTerm: 'finishing drill',
      category: _QuizCategory.training,
      difficulty: 1,
    ),
    (
      id: 'agility_ladder',
      koTerm: '래더 훈련',
      enTerm: 'agility ladder',
      category: _QuizCategory.training,
      difficulty: 1,
    ),
    (
      id: 'plyometric',
      koTerm: '플라이오메트릭',
      enTerm: 'plyometric',
      category: _QuizCategory.training,
      difficulty: 2,
    ),
    (
      id: 'dynamic_stretch',
      koTerm: '동적 스트레칭',
      enTerm: 'dynamic stretching',
      category: _QuizCategory.training,
      difficulty: 1,
    ),
    (
      id: 'cool_down',
      koTerm: '쿨다운',
      enTerm: 'cool-down',
      category: _QuizCategory.training,
      difficulty: 1,
    ),
    (
      id: 'hydration',
      koTerm: '수분 보충',
      enTerm: 'hydration',
      category: _QuizCategory.nutrition,
      difficulty: 1,
    ),
    (
      id: 'glycogen',
      koTerm: '글리코겐 회복',
      enTerm: 'glycogen recovery',
      category: _QuizCategory.nutrition,
      difficulty: 2,
    ),
    (
      id: 'sleep_routine',
      koTerm: '수면 루틴',
      enTerm: 'sleep routine',
      category: _QuizCategory.nutrition,
      difficulty: 1,
    ),
    (
      id: 'mental_reset',
      koTerm: '멘탈 리셋',
      enTerm: 'mental reset',
      category: _QuizCategory.mindset,
      difficulty: 1,
    ),
    (
      id: 'visualization',
      koTerm: '시각화',
      enTerm: 'visualization',
      category: _QuizCategory.mindset,
      difficulty: 2,
    ),
    (
      id: 'communication_cue',
      koTerm: '커뮤니케이션 큐',
      enTerm: 'communication cue',
      category: _QuizCategory.mindset,
      difficulty: 2,
    ),
    (
      id: 'check_shoulder',
      koTerm: '숄더 체크',
      enTerm: 'check shoulder',
      category: _QuizCategory.technique,
      difficulty: 1,
    ),
    (
      id: 'back_foot_receive',
      koTerm: '백풋 리시브',
      enTerm: 'receive on back foot',
      category: _QuizCategory.technique,
      difficulty: 2,
    ),
    (
      id: 'open_body',
      koTerm: '오픈 바디',
      enTerm: 'open body',
      category: _QuizCategory.technique,
      difficulty: 1,
    ),
    (
      id: 'tempo_control',
      koTerm: '템포 조절',
      enTerm: 'tempo control',
      category: _QuizCategory.tactics,
      difficulty: 2,
    ),
    (
      id: 'width',
      koTerm: '폭 활용',
      enTerm: 'width',
      category: _QuizCategory.tactics,
      difficulty: 1,
    ),
    (
      id: 'depth',
      koTerm: '깊이 활용',
      enTerm: 'depth',
      category: _QuizCategory.tactics,
      difficulty: 1,
    ),
    (
      id: 'numerical_superiority',
      koTerm: '수적 우위',
      enTerm: 'numerical superiority',
      category: _QuizCategory.tactics,
      difficulty: 2,
    ),
    (
      id: 'rest_defense',
      koTerm: '레스트 디펜스',
      enTerm: 'rest defense',
      category: _QuizCategory.tactics,
      difficulty: 3,
    ),
    (
      id: 'second_ball',
      koTerm: '세컨드볼',
      enTerm: 'second ball',
      category: _QuizCategory.tactics,
      difficulty: 2,
    ),
    (
      id: 'counter_attack',
      koTerm: '역습',
      enTerm: 'counter-attack',
      category: _QuizCategory.tactics,
      difficulty: 1,
    ),
    (
      id: 'overload_isolate',
      koTerm: '오버로드 투 아이솔레이트',
      enTerm: 'overload to isolate',
      category: _QuizCategory.tactics,
      difficulty: 3,
    ),
    (
      id: 'cover_shadow',
      koTerm: '커버 섀도우',
      enTerm: 'cover shadow',
      category: _QuizCategory.tactics,
      difficulty: 3,
    ),
    (
      id: 'press_backward',
      koTerm: '백패스 압박 트리거',
      enTerm: 'back-pass pressing trigger',
      category: _QuizCategory.tactics,
      difficulty: 3,
    ),
    (
      id: 'dead_ball',
      koTerm: '데드볼 상황',
      enTerm: 'dead-ball situation',
      category: _QuizCategory.rules,
      difficulty: 1,
    ),
    (
      id: 'advantage',
      koTerm: '어드밴티지',
      enTerm: 'advantage rule',
      category: _QuizCategory.rules,
      difficulty: 2,
    ),
    (
      id: 'bookable_offense',
      koTerm: '경고성 파울',
      enTerm: 'bookable offense',
      category: _QuizCategory.rules,
      difficulty: 2,
    ),
    (
      id: 'red_card_offense',
      koTerm: '퇴장성 파울',
      enTerm: 'red-card offense',
      category: _QuizCategory.rules,
      difficulty: 2,
    ),
    (
      id: 'added_time',
      koTerm: '추가시간',
      enTerm: 'added time',
      category: _QuizCategory.rules,
      difficulty: 1,
    ),
  ];
}

void _runQuizPoolQualityChecks(List<_FootballQuizQuestion> questions) {
  if (questions.isEmpty) {
    throw StateError('Quiz pool must not be empty.');
  }
  final styleCounts = <_QuestionStyle, int>{};
  final categoryCounts = <_QuizCategory, int>{};
  for (final question in questions) {
    if (question.style == _QuestionStyle.shortAnswer &&
        !_answerMatchesQuestion(
          question,
          question.acceptedAnswers.isEmpty
              ? ''
              : question.acceptedAnswers.first,
        )) {
      throw StateError('Short-answer validation failed for ${question.id}.');
    }
    if (question.style != _QuestionStyle.shortAnswer &&
        (question.correctIndex < 0 ||
            question.correctIndex >= question.options.length)) {
      throw StateError('Choice answer index is invalid for ${question.id}.');
    }
    styleCounts[question.style] = (styleCounts[question.style] ?? 0) + 1;
    categoryCounts[question.category] =
        (categoryCounts[question.category] ?? 0) + 1;
  }

  for (final style in _QuestionStyle.values) {
    if ((styleCounts[style] ?? 0) < 1) {
      throw StateError('Style ${style.name} has no questions.');
    }
  }

  final coreFocusCount =
      questions.where((question) => question.category.isCoreFocus).length;
  if (coreFocusCount < (questions.length * 0.30).round()) {
    throw StateError('Technique and tactics should dominate the quiz bank.');
  }

  final minimumPerCategory = questions.length >= 300 ? 6 : 1;
  for (final category in _QuizCategory.values) {
    if ((categoryCounts[category] ?? 0) < minimumPerCategory) {
      throw StateError(
        'Category ${category.name} has too few questions. '
        '(minimum=$minimumPerCategory)',
      );
    }
  }

  final selfChecks = <({String prefix, String answer})>[
    (prefix: 'ox_offside_own_half', answer: 'O'),
    (prefix: 'mcq_support_angle_best', answer: '옆이나 대각 뒤의 패스 각도'),
    (prefix: 'sa_short_0', answer: '게겐프레싱'),
    (prefix: 'sa_short_1', answer: '하프스페이스'),
  ];
  for (final item in selfChecks) {
    final question = questions.cast<_FootballQuizQuestion?>().firstWhere(
          (candidate) =>
              candidate != null && candidate.id.startsWith(item.prefix),
          orElse: () => null,
        );
    if (question == null || !_answerMatchesQuestion(question, item.answer)) {
      throw StateError('Quiz self-check failed for ${item.prefix}.');
    }
  }
}

bool _answerMatchesQuestion(_FootballQuizQuestion question, String answer) {
  final normalized = answer.trim().toLowerCase().replaceAll(' ', '');
  if (question.style == _QuestionStyle.shortAnswer) {
    return question.acceptedAnswers.any(
      (candidate) =>
          candidate.trim().toLowerCase().replaceAll(' ', '') == normalized,
    );
  }
  if (question.correctIndex < 0 ||
      question.correctIndex >= question.options.length) {
    return false;
  }
  final correct = question.options[question.correctIndex]
      .text(true)
      .trim()
      .toLowerCase()
      .replaceAll(' ', '');
  return correct == normalized;
}

String _canonicalQuizConceptKey(String raw) {
  const aliases = <String, String>{
    'counterpress_first_action': 'counterpress',
    'support_angle_best': 'support_angle',
    'switch_play_far_side': 'switch_play',
    'compactness_center': 'compact_defense',
    'width_attack_reason': 'width_attack',
    'scan_skill': 'scan_before_receive',
    'open_body_shape': 'open_body',
    'first_touch_escape': 'first_touch_space',
    'shielding_ball': 'ball_protection',
    'fullback_role': 'fullback_overlap',
    'goalkeeper_view': 'goalkeeper_communication',
    'striker_off_ball': 'striker_pin',
    'sleep_best_recovery': 'sleep_recovery',
    'hydration_best': 'hydration',
    'carb_role': 'carbohydrate_recovery',
    'warmup_purpose': 'warmup_readiness',
    'repeated_sprint_value': 'repeated_sprint',
    'mistake_reaction': 'mistake_reset',
    'communication_style': 'communication_help',
    'half_space_value': 'half_space',
    'third_man_run': 'third_man',
    'pressing_trigger_bad_touch': 'pressing_trigger',
  };
  return aliases[raw] ?? raw;
}

final Map<String, String> _quizConceptKeyByQuestionId = () {
  final map = <String, String>{};
  for (final question in _footballQuizPoolCache) {
    map[question.id] = question.conceptKey;
    for (final entry in _legacyQuestionAliases(question).entries) {
      map[entry.key] = entry.value.conceptKey;
    }
  }
  return map;
}();

final Set<String> _quizKnownConceptKeys =
    _quizConceptKeyByQuestionId.values.toSet();

final Map<String, _FootballQuizQuestion> _quizQuestionById = () {
  final map = <String, _FootballQuizQuestion>{};
  for (final question in _footballQuizPoolCache) {
    map[question.id] = question;
    for (final entry in _legacyQuestionAliases(question).entries) {
      map[entry.key] = entry.value;
    }
  }
  return map;
}();

final Map<String, _FootballQuizQuestion> _quizQuestionByConcept = () {
  final map = <String, _FootballQuizQuestion>{};
  for (final question in _footballQuizPoolCache) {
    map.putIfAbsent(question.conceptKey, () => question);
  }
  return map;
}();

final List<_FootballQuizQuestion> _footballQuizPoolCache =
    List<_FootballQuizQuestion>.unmodifiable(_buildFootballQuizPool());

String _quizConceptKeyForQuestionId(String raw) {
  if (raw.isEmpty) return raw;
  return _quizConceptKeyByQuestionId[raw] ??
      _canonicalQuizConceptKey(
        raw
            .replaceFirst(RegExp(r'^(ox|mcq|sa)_'), '')
            .replaceFirst(RegExp(r'_[0-9]+(?:_[0-9]+_[tf])?$'), ''),
      );
}

List<_ScheduledWrongItem> _normalizeScheduledWrongItems(String? raw) {
  final merged = <String, _ScheduledWrongItem>{};
  for (final item in _ScheduledWrongItem.decodeList(raw)) {
    final conceptKey = _quizConceptKeyForQuestionId(item.conceptKey);
    if (conceptKey.isEmpty) {
      continue;
    }
    if (!_quizKnownConceptKeys.contains(conceptKey)) {
      continue;
    }
    final existing = merged[conceptKey];
    if (existing == null ||
        item.lastWrongAt.isAfter(existing.lastWrongAt) ||
        (item.lastWrongAt.isAtSameMomentAs(existing.lastWrongAt) &&
            item.dueAt.isAfter(existing.dueAt))) {
      merged[conceptKey] = _ScheduledWrongItem(
        questionId: item.questionId,
        conceptKey: conceptKey,
        dueAt: item.dueAt,
        wrongCount: math.max(item.wrongCount, existing?.wrongCount ?? 0),
        lastWrongAt: item.lastWrongAt,
      );
      continue;
    }
    merged[conceptKey] = _ScheduledWrongItem(
      questionId: existing.questionId,
      conceptKey: conceptKey,
      dueAt: existing.dueAt.isAfter(item.dueAt) ? existing.dueAt : item.dueAt,
      wrongCount: math.max(existing.wrongCount, item.wrongCount),
      lastWrongAt: existing.lastWrongAt,
    );
  }
  return merged.values.toList(growable: false);
}

List<_FootballQuizQuestion> _resolveDueReviewQuestionsFromSchedule(
  Iterable<_ScheduledWrongItem> scheduled,
  Map<String, _FootballQuizQuestion> questionById,
  Map<String, _FootballQuizQuestion> questionByConcept,
) {
  final picked = <_FootballQuizQuestion>[];
  final seenConcepts = <String>{};
  final seenContentKeys = <String>{};
  for (final item in scheduled) {
    final conceptKey = _quizConceptKeyForQuestionId(item.conceptKey);
    final question =
        questionById[item.questionId] ?? questionByConcept[conceptKey];
    if (question == null) continue;
    if (!seenConcepts.add(question.conceptKey)) continue;
    final contentKey = _quizSessionQuestionContentKey(question);
    if (!seenContentKeys.add(contentKey)) {
      seenConcepts.remove(question.conceptKey);
      continue;
    }
    picked.add(question);
  }
  return picked;
}

String _quizSessionQuestionContentKey(_FootballQuizQuestion question) {
  String normalize(String text) =>
      text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  final optionKey = question.options
      .map(
          (option) => '${normalize(option.koText)}|${normalize(option.enText)}')
      .join('||');
  final answers = [...question.acceptedAnswers]..sort((a, b) => a.compareTo(b));
  final answerKey = answers.map(normalize).join('|');
  return [
    normalize(question.koPrompt),
    normalize(question.enPrompt),
    optionKey,
    question.correctIndex.toString(),
    answerKey,
  ].join('::');
}

Map<String, _FootballQuizQuestion> _legacyQuestionAliases(
  _FootballQuizQuestion question,
) {
  if (question.style == _QuestionStyle.ox) {
    final truthSuffix = question.correctIndex == 0 ? 't' : 'f';
    return {'${question.id}_${question.correctIndex}_$truthSuffix': question};
  }
  return const <String, _FootballQuizQuestion>{};
}

List<_ShortAnswerKnowledgeSeed> _shortAnswerKnowledgeSeeds() {
  return const [
    _ShortAnswerKnowledgeSeed(
      id: 'counterpress',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koClue: '공을 잃은 직후 가장 가까운 선수가 즉시 압박해 역습 속도를 늦추는 전술',
      enClue:
          'Tactic of pressing immediately after losing the ball to slow the counterattack',
      acceptedAnswers: ['게겐프레싱', 'gegenpressing', '카운터프레싱', 'counterpressing'],
      koExplain: '정답은 "게겐프레싱"입니다. 공을 잃은 직후의 즉시 압박으로 상대의 첫 전진 선택을 늦춥니다.',
      enExplain:
          'The answer is "gegenpressing." It delays the opponent’s first forward action right after possession is lost.',
      koNextPoint: '전환 순간 첫 2초를 따로 의식하며 훈련하세요.',
      enNextPoint:
          'Train the first two seconds of transition as a separate moment.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'half_space',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koClue: '중앙과 측면 사이의 세로 공간 이름',
      enClue: 'Name of the vertical lane between the center and the flank',
      acceptedAnswers: ['하프스페이스', 'halfspace', 'half-space'],
      koExplain: '정답은 "하프스페이스"입니다. 패스각과 슈팅각이 함께 열리기 쉬운 중요 공간입니다.',
      enExplain:
          'The answer is "half-space." It is a valuable lane where passing and shooting angles often open together.',
      koNextPoint: '폭과 깊이, 하프스페이스 점유를 함께 보세요.',
      enNextPoint: 'Read width, depth, and half-space occupation together.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'support_angle',
      difficulty: 1,
      category: _QuizCategory.tactics,
      koClue: '볼 소유자 옆이나 대각 뒤에서 안전한 패스 길을 만들어 주는 기본 원리',
      enClue:
          'Basic principle of offering a safe passing lane beside or diagonally behind the ball carrier',
      acceptedAnswers: ['지원각', '지원 각도', 'support angle', 'support angles'],
      koExplain: '정답은 "지원 각도"입니다. 공과 수비 사이에 패스길을 만들며 다음 연결을 돕습니다.',
      enExplain:
          'The answer is "support angle." It creates a passing lane between the ball and the defenders.',
      koNextPoint: '지원은 거리와 각도를 묶어서 보세요.',
      enNextPoint: 'Read support as a combination of distance and angle.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'switch_play',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koClue: '상대가 한쪽에 몰렸을 때 반대편으로 공을 옮겨 공간을 여는 플레이',
      enClue:
          'Play that moves the ball to the far side when the opponent overloads one side',
      acceptedAnswers: ['전환', 'switch', 'switch of play', 'switchplay'],
      koExplain: '정답은 "전환"입니다. 수비 이동을 크게 만들어 반대 공간을 공격합니다.',
      enExplain:
          'The answer is "switch of play." It stretches defensive movement and attacks the far-side space.',
      koNextPoint: '전환 전에는 반대편 공간과 수비 숫자를 먼저 확인하세요.',
      enNextPoint:
          'Before switching, check the far-side space and defensive numbers.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'compactness',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koClue: '수비 라인과 선수 사이 간격을 가깝게 유지해 중앙을 보호하는 원리',
      enClue:
          'Principle of keeping defensive distances tight to protect the center',
      acceptedAnswers: ['컴팩트', '컴팩트함', 'compactness', 'compact'],
      koExplain: '정답은 "컴팩트함"입니다. 간격이 벌어지면 중앙과 하프스페이스가 쉽게 열립니다.',
      enExplain:
          'The answer is "compactness." If distances stretch too much, central and half-space gaps open easily.',
      koNextPoint: '라인 간격과 선수 간격을 따로 체크하세요.',
      enNextPoint: 'Check line spacing and player spacing separately.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'third_man',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koClue: '패스한 선수와 받는 선수 외에 세 번째 선수가 연결해 전진하는 개념',
      enClue:
          'Concept where a third player joins the passing action to progress the attack',
      acceptedAnswers: ['서드맨', 'third man', 'thirdman', 'third-man'],
      koExplain: '정답은 "서드맨"입니다. 압박을 우회하며 전진 패턴을 만들기 좋습니다.',
      enExplain:
          'The answer is "third man." It helps bypass pressure and create progression patterns.',
      koNextPoint: '세 번째 움직임은 첫 패스가 나가기 전부터 준비하세요.',
      enNextPoint:
          'Prepare the third-man movement before the first pass is made.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'overlap',
      difficulty: 1,
      category: _QuizCategory.tactics,
      koClue: '바깥쪽 선수가 앞질러 측면 숫자 우위를 만드는 움직임',
      enClue:
          'Movement where the outside player runs beyond to create a wide overload',
      acceptedAnswers: ['오버래핑', 'overlap', 'overlapping'],
      koExplain: '정답은 "오버래핑"입니다. 측면에서 패스길과 크로스각을 함께 열 수 있습니다.',
      enExplain:
          'The answer is "overlap." It can open both a passing lane and a crossing angle on the flank.',
      koNextPoint: '오버래핑은 타이밍이 전부입니다.',
      enNextPoint: 'With overlaps, timing is everything.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'underlap',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koClue: '바깥이 아니라 안쪽 통로로 파고드는 지원 움직임',
      enClue: 'Support run that attacks the inside lane instead of the outside',
      acceptedAnswers: ['언더래핑', 'underlap', 'underlapping'],
      koExplain: '정답은 "언더래핑"입니다. 안쪽 채널을 공략하며 수비 시선을 흔듭니다.',
      enExplain:
          'The answer is "underlap." It attacks the inside lane and shifts defensive attention.',
      koNextPoint: '언더래핑은 윙어의 폭 유지와 같이 봐야 합니다.',
      enNextPoint: 'Underlaps work best when the winger still holds width.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'rest_defense',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koClue: '공격 중에도 역습 대비를 위해 뒤에 남겨 두는 수비 구조',
      enClue:
          'Defensive structure left in place during attack to guard against counters',
      acceptedAnswers: ['레스트 디펜스', 'rest defense', 'restdefense'],
      koExplain: '정답은 "레스트 디펜스"입니다. 공격 중에도 전환 수비를 준비하는 개념입니다.',
      enExplain:
          'The answer is "rest defense." It is the structure that protects the team during attacking phases.',
      koNextPoint: '공격 숫자만 보지 말고 남는 커버 숫자도 확인하세요.',
      enNextPoint:
          'Do not count only attackers; count the covering defenders too.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'blind_side',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koClue: '수비수의 시야 뒤쪽에서 움직여 마크를 벗어나는 쪽',
      enClue:
          'Side behind a defender’s vision that attackers use to escape marking',
      acceptedAnswers: ['블라인드사이드', 'blind side', 'blindside'],
      koExplain: '정답은 "블라인드사이드"입니다. 수비수 시선 밖에서 움직이면 반응이 늦어집니다.',
      enExplain:
          'The answer is "blind side." Moving outside the defender’s vision often delays their reaction.',
      koNextPoint: '패스 타이밍은 움직임보다 반 박자 빠르게 준비하세요.',
      enNextPoint: 'Prepare the pass timing half a beat ahead of the run.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'pressing_trigger',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koClue: '상대의 불편한 터치나 떠 있는 패스를 보고 압박 시작을 맞추는 기준',
      enClue:
          'Cue used to start pressing after a poor touch or a bouncing pass',
      acceptedAnswers: ['압박 트리거', 'pressing trigger', 'trigger'],
      koExplain: '정답은 "압박 트리거"입니다. 모두가 같은 신호를 봐야 압박이 동시에 걸립니다.',
      enExplain:
          'The answer is "pressing trigger." Everyone must read the same cue to press together.',
      koNextPoint: '팀 공통 신호를 짧은 단어로 정해 두세요.',
      enNextPoint: 'Agree on short shared trigger words as a team.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'transition',
      difficulty: 1,
      category: _QuizCategory.tactics,
      koClue: '공격과 수비 역할이 바뀌는 순간 전체를 가리키는 말',
      enClue:
          'General term for the moment when attack and defense roles switch',
      acceptedAnswers: ['전환', 'transition', '트랜지션'],
      koExplain: '정답은 "전환"입니다. 좋은 팀은 전환 속도에서 차이를 만듭니다.',
      enExplain:
          'The answer is "transition." Strong teams often separate themselves through transition speed.',
      koNextPoint: '공을 따낸 뒤 첫 패스와 공을 잃은 뒤 첫 압박을 묶어서 훈련하세요.',
      enNextPoint:
          'Train the first pass after winning it together with the first pressure after losing it.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'first_touch',
      difficulty: 1,
      category: _QuizCategory.technique,
      koClue: '공을 처음 받는 순간의 터치 기술 이름',
      enClue:
          'Name of the touch used when receiving the ball for the first time',
      acceptedAnswers: ['퍼스트터치', '퍼스트 터치', 'first touch', 'firsttouch'],
      koExplain: '정답은 "퍼스트 터치"입니다. 다음 행동의 질을 가장 크게 바꾸는 기술 중 하나입니다.',
      enExplain:
          'The answer is "first touch." It is one of the biggest factors shaping the next action.',
      koNextPoint: '첫 터치의 방향까지 함께 의도하세요.',
      enNextPoint: 'Plan not only the touch but also its direction.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'scanning',
      difficulty: 1,
      category: _QuizCategory.technique,
      koClue: '받기 전에 주변 정보를 미리 확인하는 기술',
      enClue: 'Skill of checking the surroundings before receiving',
      acceptedAnswers: ['스캐닝', 'scanning', 'scan'],
      koExplain: '정답은 "스캐닝"입니다. 보기 전에 받지 않는 습관이 판단 속도를 바꿉니다.',
      enExplain:
          'The answer is "scanning." Seeing before receiving changes the speed of decision-making.',
      koNextPoint: '받기 전, 받는 순간, 받은 직후를 연속으로 보세요.',
      enNextPoint: 'Scan before, during, and right after receiving.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'open_body',
      difficulty: 2,
      category: _QuizCategory.technique,
      koClue: '전방과 측면을 함께 보기 위해 반쯤 열어 두는 받는 자세',
      enClue: 'Receiving shape kept half open to see both forward and sideways',
      acceptedAnswers: ['오픈바디', '열린 자세', 'open body', 'open body shape'],
      koExplain: '정답은 "오픈 바디"입니다. 시야와 방향 전환 속도를 함께 확보합니다.',
      enExplain:
          'The answer is "open body shape." It supports both vision and turning speed.',
      koNextPoint: '첫 터치와 몸 방향을 따로 생각하지 마세요.',
      enNextPoint: 'Do not separate body shape from the first touch.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'shielding',
      difficulty: 1,
      category: _QuizCategory.technique,
      koClue: '압박이 올 때 몸으로 공과 상대 사이를 가로막는 기술',
      enClue:
          'Technique of placing the body between the defender and the ball under pressure',
      acceptedAnswers: ['볼 보호', 'shielding', 'ball shielding', 'shield'],
      koExplain: '정답은 "볼 보호"입니다. 시간을 벌고 파울도 유도할 수 있습니다.',
      enExplain:
          'The answer is "shielding." It buys time and can also draw fouls.',
      koNextPoint: '보호 후 연결 패스나 턴까지 이어서 연습하세요.',
      enNextPoint: 'Train the next pass or turn right after the shield.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'inside_pass',
      difficulty: 1,
      category: _QuizCategory.technique,
      koClue: '가장 안정적으로 방향과 세기를 조절하기 좋은 발 부위 패스',
      enClue:
          'Pass struck with the most stable foot surface for direction and weight',
      acceptedAnswers: ['인사이드 패스', '인사이드', 'inside pass'],
      koExplain: '정답은 "인사이드 패스"입니다. 정확한 연결의 기본이 됩니다.',
      enExplain:
          'The answer is "inside pass." It is the technical base for accurate combinations.',
      koNextPoint: '서포트 발 방향과 끝 동작까지 같이 보세요.',
      enNextPoint:
          'Check the plant foot direction and follow-through together.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'instep_shot',
      difficulty: 1,
      category: _QuizCategory.technique,
      koClue: '강한 슈팅에서 흔히 쓰는 발등 타격 기술',
      enClue: 'Common striking technique with the laces for powerful shooting',
      acceptedAnswers: ['인스텝', '인스텝 슈팅', 'instep', 'laces shot'],
      koExplain: '정답은 "인스텝"입니다. 발등 중심 타격으로 큰 힘을 전달합니다.',
      enExplain:
          'The answer is "instep." It uses the laces area to generate power.',
      koNextPoint: '상체 고정과 발목 고정을 함께 확인하세요.',
      enNextPoint: 'Check both upper-body control and ankle lock.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'check_shoulder',
      difficulty: 2,
      category: _QuizCategory.technique,
      koClue: '뒤쪽 압박과 공간을 보기 위해 어깨 너머로 확인하는 행동',
      enClue:
          'Action of looking over the shoulder to read pressure and space behind',
      acceptedAnswers: ['어깨 체크', '숄더 체크', 'shoulder check', 'check shoulder'],
      koExplain: '정답은 "숄더 체크"입니다. 몸을 돌리기 전 필요한 정보를 먼저 얻습니다.',
      enExplain:
          'The answer is "shoulder check." It gives the player information before turning.',
      koNextPoint: '패스가 오기 직전 마지막 확인 타이밍을 익히세요.',
      enNextPoint: 'Train the final scan just before the pass arrives.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'receiving_line',
      difficulty: 2,
      category: _QuizCategory.technique,
      koClue: '패스를 받기 전에 상대 마크 사이에서 몸을 열고 서는 위치선',
      enClue:
          'Receiving line taken between markers with the body opened before the pass',
      acceptedAnswers: ['받는 선', '수신선', 'receiving line'],
      koExplain: '정답은 "받는 선"입니다. 좋은 위치선이 첫 터치 부담을 줄입니다.',
      enExplain:
          'The answer is "receiving line." Good positioning reduces the pressure on the first touch.',
      koNextPoint: '패스 전에 한 발 먼저 각도를 만들어 두세요.',
      enNextPoint: 'Make the angle one step before the pass is played.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'offside',
      difficulty: 1,
      category: _QuizCategory.rules,
      koClue: '공이 나가는 순간 상대 두 번째 수비수보다 앞선 위치에서 공격에 관여해 생기는 반칙',
      enClue:
          'Offense for becoming involved from beyond the second-last defender at the kick moment',
      acceptedAnswers: ['오프사이드', 'offside'],
      koExplain: '정답은 "오프사이드"입니다. 위치와 공이 나가는 순간을 함께 봐야 합니다.',
      enExplain:
          'The answer is "offside." It depends on both position and the moment the ball is played.',
      koNextPoint: '출발 타이밍과 마지막 수비수 기준을 묶어서 익히세요.',
      enNextPoint: 'Link the run timing with the reference line of defenders.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'handling',
      difficulty: 1,
      category: _QuizCategory.rules,
      koClue: '필드 플레이어가 고의로 손이나 팔로 공을 다뤄 생기는 반칙',
      enClue:
          'Foul that occurs when a field player deliberately handles the ball with the hand or arm',
      acceptedAnswers: ['핸들링', 'handling', 'handball'],
      koExplain: '정답은 "핸들링"입니다. 손 사용은 축구 기본 규칙의 핵심 금지 사항입니다.',
      enExplain:
          'The answer is "handling." Restricting hand use is one of football’s basic laws.',
      koNextPoint: '의도성과 팔 위치를 함께 설명할 수 있어야 합니다.',
      enNextPoint: 'Be able to explain intent together with arm position.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'goalkeeper',
      difficulty: 1,
      category: _QuizCategory.positions,
      koClue: '골문 앞에서 손을 쓸 수 있고 뒤에서 수비를 지휘하는 포지션',
      enClue:
          'Position that can use the hands in the penalty area and organizes the defense from behind',
      acceptedAnswers: ['골키퍼', 'goalkeeper', 'keeper'],
      koExplain: '정답은 "골키퍼"입니다. 세이브뿐 아니라 소통도 큰 역할입니다.',
      enExplain:
          'The answer is "goalkeeper." Communication matters as much as shot-stopping.',
      koNextPoint: '세이브 기술과 라인 컨트롤을 함께 보세요.',
      enNextPoint: 'Study shot-stopping together with line control.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'fullback',
      difficulty: 1,
      category: _QuizCategory.positions,
      koClue: '측면 수비를 맡으면서 오버래핑도 자주 수행하는 포지션',
      enClue: 'Position that defends wide areas and often overlaps in attack',
      acceptedAnswers: ['풀백', 'fullback'],
      koExplain: '정답은 "풀백"입니다. 현대 축구에서 공격 가담 비중도 큽니다.',
      enExplain:
          'The answer is "fullback." In modern football the role also contributes heavily to attack.',
      koNextPoint: '오버래핑 타이밍과 전환 복귀를 함께 훈련하세요.',
      enNextPoint: 'Train overlap timing together with recovery runs.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'six',
      difficulty: 2,
      category: _QuizCategory.positions,
      koClue: '수비 앞에서 볼 배급과 균형을 맡는 미드필더 역할을 번호로 부르는 표현',
      enClue:
          'Number-based name for the midfielder who protects the defense and distributes the ball',
      acceptedAnswers: ['6번', '6', 'number 6', 'six'],
      koExplain: '정답은 "6번"입니다. 수비 앞 균형과 빌드업 시작을 맡는 경우가 많습니다.',
      enExplain:
          'The answer is "number 6." This role often anchors the build-up and protects the defense.',
      koNextPoint: '6번은 항상 정지해 있지 않고 각도를 계속 조정합니다.',
      enNextPoint:
          'A number 6 keeps adjusting angles instead of standing still.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'warmup',
      difficulty: 1,
      category: _QuizCategory.training,
      koClue: '훈련이나 경기 전에 몸과 신경계를 준비시키는 단계',
      enClue:
          'Phase before training or the match that prepares the body and nervous system',
      acceptedAnswers: ['워밍업', 'warm-up', 'warmup'],
      koExplain: '정답은 "워밍업"입니다. 체온과 관절, 반응 속도를 함께 끌어올립니다.',
      enExplain:
          'The answer is "warm-up." It prepares temperature, joints, and reaction speed together.',
      koNextPoint: '경기 요구 속도에 맞는 워밍업 구성을 생각하세요.',
      enNextPoint: 'Build the warm-up around the real match demands.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'cooldown',
      difficulty: 1,
      category: _QuizCategory.training,
      koClue: '훈련 후 강도를 천천히 낮추며 회복으로 넘어가는 단계',
      enClue:
          'Phase after training where intensity is lowered gradually to move into recovery',
      acceptedAnswers: ['쿨다운', 'cool-down', 'cooldown'],
      koExplain: '정답은 "쿨다운"입니다. 회복 루틴으로 넘어가는 연결 단계입니다.',
      enExplain:
          'The answer is "cool-down." It bridges hard work and recovery.',
      koNextPoint: '쿨다운 뒤에는 수분과 영양, 수면까지 연결하세요.',
      enNextPoint: 'Connect the cool-down to hydration, nutrition, and sleep.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'rondo',
      difficulty: 2,
      category: _QuizCategory.training,
      koClue: '좁은 공간에서 패스와 압박을 동시에 익히는 대표 훈련',
      enClue:
          'Classic drill that trains passing and pressure together in a tight space',
      acceptedAnswers: ['론도', 'rondo'],
      koExplain: '정답은 "론도"입니다. 판단 속도와 패스 품질을 짧은 반복으로 끌어올립니다.',
      enExplain:
          'The answer is "rondo." It sharpens decision speed and passing quality through short repetitions.',
      koNextPoint: '론도에서는 패스보다 스캐닝과 자세도 함께 보세요.',
      enNextPoint:
          'In rondos, watch scanning and body shape along with the pass.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'reset',
      difficulty: 1,
      category: _QuizCategory.mindset,
      koClue: '실수 후 감정을 길게 끌지 않고 다음 플레이에 바로 복귀하는 태도',
      enClue:
          'Attitude of moving on quickly after mistakes and returning to the next play',
      acceptedAnswers: ['리셋', 'reset'],
      koExplain: '정답은 "리셋"입니다. 다음 장면 손실을 최소화하는 정신 기술입니다.',
      enExplain:
          'The answer is "reset." It is a mental skill that reduces damage in the next action.',
      koNextPoint: '자신만의 짧은 리셋 문장을 정해 두세요.',
      enNextPoint: 'Prepare a short personal reset phrase.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'hydration',
      difficulty: 1,
      category: _QuizCategory.nutrition,
      koClue: '훈련 전중후 지속적으로 관리해야 하는 가장 기본 회복 요소',
      enClue:
          'Most basic recovery element to manage before, during, and after training',
      acceptedAnswers: ['수분', '수분 보충', 'hydration', 'water'],
      koExplain: '정답은 "수분"입니다. 탈수는 집중력과 움직임 품질을 모두 낮춥니다.',
      enExplain:
          'The answer is "hydration." Dehydration lowers both concentration and movement quality.',
      koNextPoint: '갈증이 오기 전에 마시는 루틴을 만드세요.',
      enNextPoint: 'Build a routine that starts before strong thirst appears.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'sleep',
      difficulty: 1,
      category: _QuizCategory.nutrition,
      koClue: '회복과 학습 정리에 가장 강하게 연결되는 생활 습관',
      enClue:
          'Lifestyle habit most strongly linked to recovery and learning consolidation',
      acceptedAnswers: ['수면', 'sleep'],
      koExplain: '정답은 "수면"입니다. 회복과 판단력 유지에 모두 중요합니다.',
      enExplain:
          'The answer is "sleep." It is central to both recovery and decision quality.',
      koNextPoint: '취침 시간을 훈련 계획의 일부로 기록하세요.',
      enNextPoint: 'Record sleep timing as part of the training plan.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'carbohydrate',
      difficulty: 1,
      category: _QuizCategory.nutrition,
      koClue: '고강도 운동 후 글리코겐 회복과 가장 직접적으로 연결되는 영양소',
      enClue:
          'Nutrient most directly linked to glycogen restoration after hard exercise',
      acceptedAnswers: ['탄수화물', 'carbohydrate', 'carbohydrates', 'carbs'],
      koExplain: '정답은 "탄수화물"입니다. 에너지 저장량 회복에 핵심 역할을 합니다.',
      enExplain:
          'The answer is "carbohydrates." They play a key role in restoring energy stores.',
      koNextPoint: '회복 영양은 타이밍과 양을 함께 관리하세요.',
      enNextPoint: 'Manage recovery nutrition through both timing and amount.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'world_cup_cycle',
      difficulty: 1,
      category: _QuizCategory.fun,
      koClue: 'FIFA 월드컵이 보통 열리는 주기. 숫자와 단위를 함께 쓰세요',
      enClue:
          'Typical cycle of the FIFA World Cup. Answer with the number and unit',
      acceptedAnswers: ['4년', '4 년', 'four years', '4years', '4 years'],
      koExplain: '정답은 "4년"입니다. 월드컵은 대표팀 축구의 가장 상징적인 주기 대회입니다.',
      enExplain:
          'The answer is "4 years." The World Cup is the signature cyclical tournament of national-team football.',
      koNextPoint: '대회 지식은 경기 주기와 역사까지 같이 익히세요.',
      enNextPoint:
          'Study competition facts together with their historical rhythm.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'champions_league',
      difficulty: 1,
      category: _QuizCategory.fun,
      koClue: '유럽 클럽 최상위 대항전의 대표 약칭 UCL이 가리키는 대회 이름',
      enClue:
          'Competition referred to by the abbreviation UCL, the top European club tournament',
      acceptedAnswers: ['챔피언스리그', 'uefa champions league', 'champions league'],
      koExplain: '정답은 "챔피언스리그"입니다. 유럽 최상위 클럽 대항전으로 알려져 있습니다.',
      enExplain:
          'The answer is "Champions League." It is the best-known top-tier European club competition.',
      koNextPoint: '리그와 컵, 국제 대회를 구분해서 이해하세요.',
      enNextPoint:
          'Separate leagues, cups, and international competitions in your understanding.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'premier_league',
      difficulty: 1,
      category: _QuizCategory.fun,
      koClue: '맨체스터 시티, 리버풀, 아스널이 속한 잉글랜드 대표 1부 리그 이름',
      enClue:
          'Name of the top English league featuring Manchester City, Liverpool, and Arsenal',
      acceptedAnswers: ['프리미어리그', 'premier league', 'epl'],
      koExplain: '정답은 "프리미어리그"입니다. 세계적으로 가장 널리 알려진 리그 중 하나입니다.',
      enExplain:
          'The answer is "Premier League." It is one of the most widely followed leagues in the world.',
      koNextPoint: '리그 이름은 대표 팀과 함께 연결해 기억하세요.',
      enNextPoint: 'Connect league names with representative clubs.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'la_liga',
      difficulty: 1,
      category: _QuizCategory.fun,
      koClue: '레알 마드리드와 바르셀로나가 속한 스페인 1부 리그 이름',
      enClue:
          'Name of the Spanish top division featuring Real Madrid and Barcelona',
      acceptedAnswers: ['라리가', 'la liga', 'laliga'],
      koExplain: '정답은 "라리가"입니다. 기술 중심 축구 이미지로 잘 알려진 리그입니다.',
      enExplain:
          'The answer is "La Liga." It is widely known for its technical football identity.',
      koNextPoint: '팀 이름과 리그 이름을 세트로 기억하세요.',
      enNextPoint: 'Memorize clubs together with their league.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'messi',
      difficulty: 1,
      category: _QuizCategory.fun,
      koClue: '드리블과 왼발 플레이메이킹으로 상징되는 아르헨티나의 유명 선수 성',
      enClue:
          'Surname of the famous Argentine player known for dribbling and left-footed playmaking',
      acceptedAnswers: ['메시', 'messi'],
      koExplain: '정답은 "메시"입니다. 축구 퀴즈에서 가장 자주 등장하는 상징적 선수 중 하나입니다.',
      enExplain:
          'The answer is "Messi." He is one of the most recognizable players in football quiz culture.',
      koNextPoint: '선수 이름은 대표 특징과 함께 기억하세요.',
      enNextPoint: 'Remember player names together with signature traits.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'modric',
      difficulty: 2,
      category: _QuizCategory.fun,
      koClue: '경기 템포 조절과 외발 인사이드/아웃사이드 패스로 유명한 크로아티아 미드필더 성',
      enClue:
          'Surname of the Croatian midfielder famous for controlling tempo and passing variety',
      acceptedAnswers: ['모드리치', 'modric'],
      koExplain: '정답은 "모드리치"입니다. 리듬 조절과 방향 전환의 대표적 예시로 자주 거론됩니다.',
      enExplain:
          'The answer is "Modric." He is often used as an example of tempo control and directional play.',
      koNextPoint: '선수 상식도 플레이 특징과 연결해 이해하세요.',
      enNextPoint: 'Understand player trivia through their playing traits.',
    ),
  ];
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
