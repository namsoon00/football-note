// ignore_for_file: unused_element

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../../application/family_access_service.dart';
import '../../application/player_level_service.dart';
import '../../application/player_profile_service.dart';
import '../../application/settings_service.dart';
import '../../application/skill_quiz_resume_summary.dart';
import '../../application/sport_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../domain/entities/sport_definition.dart';
import '../../domain/repositories/option_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';

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
    OptionRepository optionRepository, {
    String? sportId,
  }) {
    final session = _QuizSessionSnapshot.tryParse(
      optionRepository.getValue<String>(
        storageKey(optionRepository, sessionKey, sportId: sportId),
      ),
    );
    final now = DateTime.now();
    final pendingDueCount = _countDueScheduledWrongItemsLight(
      optionRepository.getValue<String>(
        storageKey(optionRepository, pendingWrongScheduleKey, sportId: sportId),
      ),
      now,
    ).length;

    final rawCompletedAt = optionRepository.getValue<String>(
      storageKey(optionRepository, completionKey, sportId: sportId),
    );
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

  static String storageKey(
    OptionRepository optionRepository,
    String baseKey, {
    String? sportId,
  }) {
    final normalizedSportId = SportCatalog.normalizeSportId(
      sportId ?? SportService(optionRepository).currentSportId(),
    );
    if (normalizedSportId == SportCatalog.footballId) {
      return baseKey;
    }
    return '${baseKey}_$normalizedSportId';
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
      if (concept.isEmpty || !_quizKnownConceptKeys.contains(concept)) {
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
  static const int _minimumMixedSetCategories = 4;
  static const int _minimumMixedSetStyles = 3;

  late final Map<String, _FootballQuizQuestion> _questionMap;
  late final List<_FootballQuizQuestion> _allQuestions;
  late final PlayerProfileService _profileService;
  late final String _sportId;
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
  bool _shortAnswerHintShown = false;
  bool _answerRevealed = false;
  bool _finished = false;
  final Set<String> _wrongIds = <String>{};
  final Map<String, _QuizHistoryResponse> _wrongQuestionResponses =
      <String, _QuizHistoryResponse>{};

  DateTime? _questionStartedAt;
  Timer? _speedTimer;
  int _speedLeft = _speedLimitSec;
  _AnswerFx _answerFx = _AnswerFx.none;

  @override
  void initState() {
    super.initState();
    _sportId = SportService(widget.optionRepository).currentSportId();
    _allQuestions = _quizPoolForSport(_sportId);
    _questionMap = {
      for (final question in _allQuestions) question.id: question,
      for (final question in _allQuestions) ..._legacyQuestionAliases(question),
    };
    _profileService = PlayerProfileService(widget.optionRepository);
    _resumeSummary = SkillQuizScreen.loadResumeSummary(
      widget.optionRepository,
      sportId: _sportId,
    );
    _pendingResumeSnapshot = _QuizSessionSnapshot.tryParse(
      widget.optionRepository.getValue<String>(
        _storageKey(SkillQuizScreen.sessionKey),
      ),
    );
  }

  @override
  void dispose() {
    _speedTimer?.cancel();
    _shortAnswerController.dispose();
    super.dispose();
  }

  void _refreshResumeSummary() {
    _resumeSummary = SkillQuizScreen.loadResumeSummary(
      widget.optionRepository,
      sportId: _sportId,
    );
  }

  String _storageKey(String baseKey) {
    return SkillQuizScreen.storageKey(
      widget.optionRepository,
      baseKey,
      sportId: _sportId,
    );
  }

  bool get _isParentMode =>
      FamilyAccessService(widget.optionRepository).loadState().isParentMode;

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
      _shortAnswerHintShown = false;
      _answerRevealed = snapshot.answerRevealed;
      _finished = snapshot.finished || _index >= questions.length;
      _wrongIds
        ..clear()
        ..addAll(snapshot.wrongIds);
      _wrongQuestionResponses.clear();
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
      _storageKey(SkillQuizScreen.dailyQuestionsDayKey),
    );
    if (savedToken == token) {
      final savedIds = _decodeStringList(
        widget.optionRepository.getValue<String>(
          _storageKey(SkillQuizScreen.dailyQuestionsKey),
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
        _storageKey(SkillQuizScreen.dailyQuestionsDayKey),
        token,
      ),
    );
    unawaited(
      widget.optionRepository.setValue(
        _storageKey(SkillQuizScreen.dailyQuestionsKey),
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
      _shortAnswerHintShown = false;
      _answerRevealed = false;
      _finished = false;
      _wrongIds.clear();
      _wrongQuestionResponses.clear();
      _speedLeft = _speedLimitSec;
      _answerFx = _AnswerFx.none;
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
    _recordWrongQuestionResponse(
      question,
      const _QuizHistoryResponse.marker(_QuizWrongAnswerKind.timeout),
    );
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

  void _showShortAnswerHint() {
    if (_finished || _answered || _questions.isEmpty || _shortAnswerHintShown) {
      return;
    }
    final question = _questions[_index];
    if (question.style != _QuestionStyle.shortAnswer) return;
    setState(() {
      _shortAnswerHintShown = true;
    });
    unawaited(_trackMetric('football_short_answer_hint_shown'));
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
    _recordWrongQuestionResponse(
      question,
      const _QuizHistoryResponse.marker(_QuizWrongAnswerKind.revealed),
    );
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
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    if (question.style == _QuestionStyle.shortAnswer &&
        question.acceptedAnswers.isNotEmpty) {
      return _preferredShortAnswerAnswer(question, isKo: isKo);
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

  String _preferredShortAnswerAnswer(
    _FootballQuizQuestion question, {
    required bool isKo,
  }) {
    if (question.acceptedAnswers.isEmpty) return '';
    final hangulPattern = RegExp(r'[가-힣]');
    final latinPattern = RegExp(r'[A-Za-z]');
    final numericPattern = RegExp(r'^[0-9]+$');
    if (isKo) {
      return question.acceptedAnswers.firstWhere(
        (answer) => hangulPattern.hasMatch(answer),
        orElse: () => question.acceptedAnswers.firstWhere(
          (answer) => numericPattern.hasMatch(answer.trim()),
          orElse: () => question.acceptedAnswers.first,
        ),
      );
    }
    return question.acceptedAnswers.firstWhere(
      (answer) => latinPattern.hasMatch(answer),
      orElse: () => question.acceptedAnswers.firstWhere(
        (answer) => numericPattern.hasMatch(answer.trim()),
        orElse: () => question.acceptedAnswers.first,
      ),
    );
  }

  String _shortAnswerHintText(
    _FootballQuizQuestion question,
    AppLocalizations l10n,
    bool isKo,
  ) {
    final answer = _preferredShortAnswerAnswer(question, isKo: isKo).trim();
    final normalized = answer.replaceAll(RegExp(r'[^A-Za-z0-9가-힣]'), '');
    if (normalized.isEmpty) {
      return l10n.quizShortAnswerHintUnavailable;
    }
    final first = String.fromCharCode(normalized.runes.first);
    final length = normalized.runes.length;
    final numericPattern = RegExp(r'^[0-9]+$');
    if (numericPattern.hasMatch(normalized)) {
      return l10n.quizShortAnswerHintNumber(first, length);
    }
    return l10n.quizShortAnswerHintStartsWith(first, length);
  }

  void _recordWrongQuestionResponse(
    _FootballQuizQuestion question,
    _QuizHistoryResponse response,
  ) {
    _wrongQuestionResponses[question.id] = response;
  }

  _QuizHistoryResponse _wrongResponseForCurrentQuestion({
    _QuizWrongAnswerKind fallbackKind = _QuizWrongAnswerKind.empty,
  }) {
    final question = _questions[_index];
    if (question.style == _QuestionStyle.shortAnswer) {
      final raw = _shortAnswerController.text.trim();
      if (raw.isNotEmpty) {
        return _QuizHistoryResponse.text(raw);
      }
      return _QuizHistoryResponse.marker(fallbackKind);
    }
    final selectedIndex = _selectedIndex;
    if (selectedIndex != null &&
        selectedIndex >= 0 &&
        selectedIndex < question.options.length) {
      final option = question.options[selectedIndex];
      return _QuizHistoryResponse.bilingual(
        ko: option.text(true),
        en: option.text(false),
      );
    }
    return _QuizHistoryResponse.marker(fallbackKind);
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
          _recordWrongQuestionResponse(
            _questions[_index],
            _wrongResponseForCurrentQuestion(),
          );
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
        _shortAnswerHintShown = false;
        _answerRevealed = false;
        _streak = 0;
        _combo = 0;
        _momentum = (_momentum - 12).clamp(0, 100);
        _wrongIds.add(question.id);
        _answerCount += 1;
        _responseMillisSum += math.max(0, responseMs);
        _answerFx = _AnswerFx.fail;
      });
      _recordWrongQuestionResponse(
        question,
        _wrongResponseForCurrentQuestion(
          fallbackKind: _QuizWrongAnswerKind.skipped,
        ),
      );
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
      _shortAnswerHintShown = false;
      _answerRevealed = false;
      _answerFx = _AnswerFx.none;
    });
    _shortAnswerController.clear();

    _startQuestionClock();
    await _persistSession();
  }

  Future<void> _completeSession() async {
    final completedAt = DateTime.now();
    final l10n = AppLocalizations.of(context)!;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final wrongQuestions = _questions
        .where((question) => _wrongIds.contains(question.id))
        .toList(growable: false);

    await _scheduleReviewQuestions(wrongQuestions);
    await _recordRecentPerformance();
    await _recordCategoryPerformance();
    await _appendQuizHistory(completedAt);
    await _trackMetric('football_quiz_session_completed');
    final levelAward = await PlayerLevelService(widget.optionRepository)
        .awardForQuizCompletion(
      completedAt: completedAt,
      correctAnswers: _score,
      totalQuestions: _questions.length,
    );
    if (levelAward.gainedXp > 0) {
      final settingsService = SettingsService(widget.optionRepository)..load();
      final reminderService = TrainingPlanReminderService(
        widget.optionRepository,
        settingsService,
      );
      await reminderService.showXpGainAlert(
        gainedXp: levelAward.gainedXp,
        totalXp: levelAward.after.totalXp,
        isKo: isKo,
        sourceLabel: l10n.quizXpSourceLabel,
      );
      if (levelAward.didLevelUp) {
        await reminderService.showLevelUpAlert(
          level: levelAward.after.level,
          isKo: isKo,
        );
      }
      if (mounted) {
        AppFeedback.showSuccess(
          context,
          text: l10n.quizXpSavedFeedback(levelAward.gainedXp),
        );
      }
    }

    if (_mode == _QuizMode.daily) {
      await widget.optionRepository.setValue(
        _storageKey(SkillQuizScreen.completionKey),
        completedAt.toIso8601String(),
      );
    }
    await widget.optionRepository.setValue(
      _storageKey(SkillQuizScreen.sessionKey),
      '',
    );
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
    final l10n = AppLocalizations.of(context)!;
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
                  tooltip: l10n.quizBackHomeTooltip,
                  icon: const Icon(Icons.arrow_back),
                )
              : null,
          title: Text(l10n.quizScreenTitle),
          actions: _showEntryHubBackButton
              ? null
              : [
                  _buildHeaderAction(
                    onPressed: _openQuizLibrary,
                    icon: const Icon(Icons.library_books_outlined),
                    label: l10n.quizLibraryAction,
                  ),
                  _buildHeaderAction(
                    onPressed: _openQuizHistory,
                    icon: const Icon(Icons.history_outlined),
                    label: l10n.quizHistoryAction,
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

  Widget _buildHeaderAction({
    required VoidCallback onPressed,
    required Widget icon,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        icon: icon,
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
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
    final l10n = AppLocalizations.of(context)!;
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
                  answerInsightLabel: (_answered || _retryUsed)
                      ? (isKo ? '정답 포인트' : 'Answer insight')
                      : '',
                  answerLine: (_answered &&
                          (_answerRevealed ||
                              question.style == _QuestionStyle.shortAnswer))
                      ? (isKo
                          ? '정답: ${_primaryAnswerLabel(question)}'
                          : 'Answer: ${_primaryAnswerLabel(question)}')
                      : '',
                  nextFocusLine: (_answered || _retryUsed)
                      ? (isKo
                          ? '다음에 볼 포인트: ${question.nextPoint(true)}'
                          : 'Next focus: ${question.nextPoint(false)}')
                      : '',
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
                          enabled: !_answered && !_isParentMode,
                          textInputAction: TextInputAction.done,
                          onSubmitted: _isParentMode
                              ? null
                              : (_) => _submitShortAnswer(),
                          decoration: InputDecoration(
                            hintText: isKo ? '정답을 입력하세요' : 'Type your answer',
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        if (!_answered && !_isParentMode) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _shortAnswerHintShown
                                    ? null
                                    : _showShortAnswerHint,
                                icon: const Icon(Icons.lightbulb_outline),
                                label: Text(l10n.quizShortAnswerHintAction),
                              ),
                              OutlinedButton.icon(
                                onPressed: _revealShortAnswer,
                                icon: const Icon(Icons.visibility_outlined),
                                label: Text(l10n.quizRevealAnswerAction),
                              ),
                            ],
                          ),
                        ],
                        if (_shortAnswerHintShown) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.tips_and_updates_outlined,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _shortAnswerHintText(question, l10n, isKo),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: (_answered || _isParentMode)
                              ? null
                              : _submitShortAnswer,
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
                          onTap: _isParentMode
                              ? null
                              : () => _selectAnswer(optionIndex),
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: (_isParentMode || !canGoNext) ? null : _goNext,
          icon: const Icon(Icons.navigate_next),
          label: Text(isKo ? '다음' : 'Next'),
        ),
      ],
    );
  }

  Widget _buildResult(bool isKo) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = _questions.length;
    final accuracy = total == 0 ? 0 : ((_score / total) * 100).round();
    final wrongQuestions = _questions
        .where((question) => _wrongIds.contains(question.id))
        .toList(growable: false);

    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: AppSurfaces.heroDecoration(
            scheme,
            theme.brightness,
            accent: scheme.primary,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isKo ? '축구 퀴즈 결과' : 'Football Quiz Result',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isKo
                    ? '$_score / $total 정답, 정확도 $accuracy%'
                    : '$_score / $total correct, accuracy $accuracy%',
                style: theme.textTheme.headlineSmall?.copyWith(
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
                    label: l10n.quizResultMissReviewCountLabel,
                    value: isKo
                        ? '${wrongQuestions.length}개'
                        : '${wrongQuestions.length}',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
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
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppSurfaces.subtleDecoration(scheme, theme.brightness),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: scheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.quizResultNoMissedQuestions,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        FilledButton.icon(
          onPressed: _isParentMode ? null : _startFocusSession,
          icon: const Icon(Icons.center_focus_strong_outlined),
          label: Text(isKo ? '약점 집중으로 바로 다시' : 'Retry with focus mode'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _isParentMode ? null : _startChallengeSession,
          icon: const Icon(Icons.sports_soccer_outlined),
          label: Text(isKo ? '챌린지 모드로 확장' : 'Expand with challenge mode'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _isParentMode ? null : _startReviewSessionFromQueue,
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

  Future<void> _appendQuizHistory(DateTime finishedAt) async {
    if (_questions.isEmpty) return;
    final existing = _QuizHistoryEntry.decodeList(
      widget.optionRepository.getValue<String>(
        _storageKey(SkillQuizScreen.historyKey),
      ),
    ).take(19).toList(growable: true);
    final allQuestions = _questions
        .map(
          (question) => _QuizHistoryQuestion(
            id: question.id,
            promptKo: question.prompt(true),
            promptEn: question.prompt(false),
            answerKo: question.displayAnswer(true),
            answerEn: question.displayAnswer(false),
            wrongAnswerKo: _wrongQuestionResponses[question.id]?.label(
                  AppLocalizations.of(context)!,
                  true,
                ) ??
                '',
            wrongAnswerEn: _wrongQuestionResponses[question.id]?.label(
                  AppLocalizations.of(context)!,
                  false,
                ) ??
                '',
            explanationKo: question.explainText(true),
            explanationEn: question.explainText(false),
            category: question.category.name,
            style: question.style.name,
          ),
        )
        .toList(growable: false);
    final wrongQuestions = allQuestions
        .where((question) => _wrongIds.contains(question.id))
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
        questions: allQuestions,
        wrongQuestions: wrongQuestions,
      ),
    );
    await widget.optionRepository.setValue(
      _storageKey(SkillQuizScreen.historyKey),
      _QuizHistoryEntry.encodeList(existing),
    );
  }

  List<_QuizHistoryEntry> _loadQuizHistory() {
    return _QuizHistoryEntry.decodeList(
      widget.optionRepository.getValue<String>(
        _storageKey(SkillQuizScreen.historyKey),
      ),
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
        _storageKey(SkillQuizScreen.sessionKey),
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
      _shortAnswerHintShown = false;
      _answerRevealed = false;
      _answerFx = _AnswerFx.none;
      _index = 0;
      _score = 0;
      _streak = 0;
      _combo = 0;
      _momentum = 0;
      _speedLeft = _speedLimitSec;
      _wrongQuestionResponses.clear();
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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: AppSurfaces.heroDecoration(
            scheme,
            theme.brightness,
            accent: scheme.primary,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isKo ? '오늘의 퀴즈 시작' : 'Start today’s quiz',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isKo
                    ? '오늘 문제를 다시 풀지, 다른 스타일로 풀지, 약점 분야를 파고들지 고르세요.'
                    : 'Choose whether to replay today, try a different mode, or drill into your weakest area.',
                style: theme.textTheme.bodyMedium?.copyWith(
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
        if (_isParentMode) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              l10n.parentReadOnlyQuiz,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        ...actions.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _QuizEntryCard(
              data: item,
              onTap: _isParentMode ? null : () => _selectEntryMode(item.action),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _persistSession() async {
    if (_finished || _questions.isEmpty) {
      await widget.optionRepository.setValue(
        _storageKey(SkillQuizScreen.sessionKey),
        '',
      );
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
      _storageKey(SkillQuizScreen.sessionKey),
      snapshot.encode(),
    );
    _pendingResumeSnapshot = snapshot;
    _refreshResumeSummary();
  }

  Future<void> _trackMetric(String key) async {
    final current = _QuizMetrics.parse(
      widget.optionRepository.getValue<String>(
        _storageKey(SkillQuizScreen.metricsKey),
      ),
    );
    current[key] = (current[key] ?? 0) + 1;
    await widget.optionRepository.setValue(
      _storageKey(SkillQuizScreen.metricsKey),
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
      _storageKey(SkillQuizScreen.recentPerformanceKey),
      perf.encode(),
    );
  }

  Future<void> _recordCategoryPerformance() async {
    if (_questions.isEmpty) return;
    final current = _QuizCategoryAggregate.decodeMap(
      widget.optionRepository.getValue<String>(
        _storageKey(SkillQuizScreen.categoryStatsKey),
      ),
    );
    final session = _sessionCategoryStats();
    for (final entry in session.entries) {
      final previous = current[entry.key] ?? const _QuizCategoryAggregate();
      current[entry.key] = previous.merge(entry.value);
    }
    await widget.optionRepository.setValue(
      _storageKey(SkillQuizScreen.categoryStatsKey),
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
        _storageKey(SkillQuizScreen.categoryStatsKey),
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
        _storageKey(SkillQuizScreen.recentPerformanceKey),
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

    return _rebalanceSessionVariety(
      picked: picked,
      source: source,
      random: random,
    );
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
    return _rebalanceSessionVariety(
      picked: picked.take(_dailyCount).toList(growable: false),
      source: _allQuestions.where((q) => !excludedIds.contains(q.id)),
      random: random,
      protectedIds: reviewQuestions.map((question) => question.id).toSet(),
    );
  }

  List<_FootballQuizQuestion> _loadDueReviewQuestions() {
    final scheduled = _normalizeScheduledWrongItems(
      widget.optionRepository.getValue<String>(
        _storageKey(SkillQuizScreen.pendingWrongScheduleKey),
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

  List<_FootballQuizQuestion> _rebalanceSessionVariety({
    required List<_FootballQuizQuestion> picked,
    required Iterable<_FootballQuizQuestion> source,
    required math.Random random,
    Set<String> protectedIds = const <String>{},
  }) {
    if (picked.length < 2) {
      return picked;
    }

    final target = picked.toList(growable: true);
    final sourcePool = source.toList(growable: false)..shuffle(random);

    Map<_QuizCategory, int> categoryCounts() {
      final counts = <_QuizCategory, int>{};
      for (final question in target) {
        counts[question.category] = (counts[question.category] ?? 0) + 1;
      }
      return counts;
    }

    Map<_QuestionStyle, int> styleCounts() {
      final counts = <_QuestionStyle, int>{};
      for (final question in target) {
        counts[question.style] = (counts[question.style] ?? 0) + 1;
      }
      return counts;
    }

    bool candidateFitsAt(_FootballQuizQuestion candidate, int replaceIndex) {
      final concepts = <String>{};
      final contentKeys = <String>{};
      for (var index = 0; index < target.length; index++) {
        final question = index == replaceIndex ? candidate : target[index];
        if (!concepts.add(question.conceptKey)) {
          return false;
        }
        if (!contentKeys.add(_sessionQuestionContentKey(question))) {
          return false;
        }
      }
      return true;
    }

    bool tryReplace({
      required bool Function(_FootballQuizQuestion question) candidateMatches,
      required bool Function(_FootballQuizQuestion question) canReplace,
    }) {
      for (final candidate in sourcePool) {
        if (!candidateMatches(candidate)) {
          continue;
        }
        if (target.any((question) => question.id == candidate.id)) {
          continue;
        }
        for (var index = 0; index < target.length; index++) {
          final current = target[index];
          if (protectedIds.contains(current.id) || !canReplace(current)) {
            continue;
          }
          if (!candidateFitsAt(candidate, index)) {
            continue;
          }
          target[index] = candidate;
          return true;
        }
      }
      return false;
    }

    void ensureCategoryCoverage() {
      final availableCategories =
          sourcePool.map((question) => question.category).toSet();
      final desiredCategoryCount = math.min(
        _minimumMixedSetCategories,
        math.min(target.length, availableCategories.length),
      );
      while (target.map((question) => question.category).toSet().length <
          desiredCategoryCount) {
        final selectedCategories =
            target.map((question) => question.category).toSet();
        final missingCategories = availableCategories
            .where((category) => !selectedCategories.contains(category))
            .toList(growable: false)
          ..shuffle(random);
        var changed = false;
        for (final category in missingCategories) {
          final counts = categoryCounts();
          changed = tryReplace(
            candidateMatches: (question) => question.category == category,
            canReplace: (question) => (counts[question.category] ?? 0) > 1,
          );
          if (changed) {
            break;
          }
        }
        if (!changed) {
          break;
        }
      }
    }

    void ensureStyleCoverage() {
      final availableStyles =
          sourcePool.map((question) => question.style).toSet();
      final desiredStyleCount = math.min(
        _minimumMixedSetStyles,
        math.min(target.length, availableStyles.length),
      );
      while (target.map((question) => question.style).toSet().length <
          desiredStyleCount) {
        final selectedStyles = target.map((question) => question.style).toSet();
        final missingStyles = availableStyles
            .where((style) => !selectedStyles.contains(style))
            .toList(growable: false)
          ..shuffle(random);
        var changed = false;
        for (final style in missingStyles) {
          final counts = styleCounts();
          changed = tryReplace(
            candidateMatches: (question) => question.style == style,
            canReplace: (question) => (counts[question.style] ?? 0) > 1,
          );
          if (changed) {
            break;
          }
        }
        if (!changed) {
          break;
        }
      }
    }

    ensureCategoryCoverage();
    ensureStyleCoverage();
    ensureCategoryCoverage();
    return target..shuffle(random);
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
        _storageKey(SkillQuizScreen.pendingWrongScheduleKey),
      ),
    );
    final next = current
        .where((item) => !concepts.contains(item.conceptKey))
        .toList(growable: false);
    await widget.optionRepository.setValue(
      _storageKey(SkillQuizScreen.pendingWrongScheduleKey),
      _ScheduledWrongItem.encodeList(next),
    );
    await widget.optionRepository.setValue(
      _storageKey(SkillQuizScreen.pendingWrongQuestionsKey),
      '',
    );
  }

  Future<void> _scheduleReviewQuestions(
    List<_FootballQuizQuestion> wrongQuestions,
  ) async {
    final current = _normalizeScheduledWrongItems(
      widget.optionRepository.getValue<String>(
        _storageKey(SkillQuizScreen.pendingWrongScheduleKey),
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
      _storageKey(SkillQuizScreen.pendingWrongScheduleKey),
      _ScheduledWrongItem.encodeList(map.values.toList(growable: false)),
    );
    await widget.optionRepository.setValue(
      _storageKey(SkillQuizScreen.pendingWrongQuestionsKey),
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
  final String answerInsightLabel;
  final String answerLine;
  final String nextFocusLine;

  const _QuestionHeroCard({
    required this.question,
    required this.isKo,
    required this.overlay,
    required this.explanationText,
    this.answerInsightLabel = '',
    this.answerLine = '',
    this.nextFocusLine = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _quizCategoryAccent(question.category);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppSurfaces.subtleDecoration(
        scheme,
        theme.brightness,
        accent: accent,
        accentAlpha: 0.12,
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
                  borderRadius: AppRadius.full,
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
                    borderRadius: AppRadius.control,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (answerInsightLabel.isNotEmpty) ...[
                        Text(
                          answerInsightLabel,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        explanationText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (answerLine.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          answerLine,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                      if (nextFocusLine.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          nextFocusLine,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ],
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
    final enabled = onTap != null;
    return Material(
      color:
          enabled ? scheme.surfaceContainerLow : scheme.surfaceContainerLowest,
      borderRadius: AppRadius.surface,
      child: InkWell(
        borderRadius: AppRadius.surface,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: AppRadius.surface,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: enabled
                      ? scheme.primary.withValues(alpha: 0.12)
                      : scheme.outlineVariant.withValues(alpha: 0.18),
                  borderRadius: AppRadius.control,
                ),
                child: Icon(
                  data.icon,
                  color: enabled
                      ? scheme.primary
                      : scheme.onSurfaceVariant.withValues(alpha: 0.58),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: enabled
                                ? null
                                : scheme.onSurface.withValues(alpha: 0.66),
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(
                              alpha: enabled ? 0.74 : 0.52,
                            ),
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
                      color: enabled
                          ? scheme.primary.withValues(alpha: 0.12)
                          : scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      data.badge,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: enabled
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Icon(
                    enabled ? Icons.arrow_forward_ios : Icons.lock_outline,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: AppSurfaces.heroDecoration(
              scheme,
              theme.brightness,
              accent: scheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isKo ? '코치용 퀴즈 라이브러리' : 'Coach quiz library',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isKo
                      ? '전체 문제를 카테고리, 유형, 난이도, 검색어로 점검하세요. 기본기와 전술 비중이 높고, 규칙·포지션·대회 상식도 섞여 있습니다.'
                      : 'Inspect the full question bank by category, style, difficulty, and search. Fundamentals and tactics are emphasized while rules, positions, and competition knowledge stay mixed in.',
                  style: theme.textTheme.bodyMedium?.copyWith(
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
            padding: AppSpacing.card,
            decoration: AppSurfaces.cardDecoration(scheme, theme.brightness),
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
                      borderRadius: AppRadius.control,
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

class _FlipQuizReviewCard extends StatelessWidget {
  final dynamic question;
  final bool isKo;

  const _FlipQuizReviewCard({required this.question, required this.isKo});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final prompt = question is _FootballQuizQuestion
        ? (question as _FootballQuizQuestion).prompt(isKo)
        : (question as _QuizHistoryQuestion).prompt(isKo);
    final answer = question is _FootballQuizQuestion
        ? (question as _FootballQuizQuestion).displayAnswer(isKo)
        : (question as _QuizHistoryQuestion).answer(isKo);
    final explanation = question is _FootballQuizQuestion
        ? (question as _FootballQuizQuestion).explainText(isKo)
        : (question as _QuizHistoryQuestion).explanation(isKo);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isKo ? '문제' : 'Question',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
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
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isKo ? '정답' : 'Answer',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  answer,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
          if (explanation.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              explanation,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
        ],
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
                        borderRadius: AppRadius.surface,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.surface,
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

enum _QuizWrongAnswerKind { timeout, revealed, skipped, empty }

class _QuizHistoryResponse {
  final String? wrongAnswerKo;
  final String? wrongAnswerEn;
  final _QuizWrongAnswerKind? kind;

  const _QuizHistoryResponse._({
    this.wrongAnswerKo,
    this.wrongAnswerEn,
    this.kind,
  });

  const _QuizHistoryResponse.bilingual({required String ko, required String en})
      : this._(wrongAnswerKo: ko, wrongAnswerEn: en);

  const _QuizHistoryResponse.text(String value)
      : this._(wrongAnswerKo: value, wrongAnswerEn: value);

  const _QuizHistoryResponse.marker(_QuizWrongAnswerKind kind)
      : this._(kind: kind);

  String label(AppLocalizations l10n, bool isKo) {
    final text = isKo ? wrongAnswerKo : wrongAnswerEn;
    if (text != null && text.trim().isNotEmpty) {
      return text.trim();
    }
    return switch (kind ?? _QuizWrongAnswerKind.empty) {
      _QuizWrongAnswerKind.timeout => l10n.quizWrongAnswerTimeout,
      _QuizWrongAnswerKind.revealed => l10n.quizWrongAnswerRevealed,
      _QuizWrongAnswerKind.skipped => l10n.quizWrongAnswerSkipped,
      _QuizWrongAnswerKind.empty => l10n.quizWrongAnswerEmpty,
    };
  }
}

class _QuizHistoryQuestion {
  final String id;
  final String promptKo;
  final String promptEn;
  final String answerKo;
  final String answerEn;
  final String wrongAnswerKo;
  final String wrongAnswerEn;
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
    required this.wrongAnswerKo,
    required this.wrongAnswerEn,
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
        'wrongAnswerKo': wrongAnswerKo,
        'wrongAnswerEn': wrongAnswerEn,
        'explanationKo': explanationKo,
        'explanationEn': explanationEn,
        'category': category,
        'style': style,
      };

  String prompt(bool isKo) => isKo ? promptKo : promptEn;
  String answer(bool isKo) => isKo ? answerKo : answerEn;
  String wrongAnswer(bool isKo) => isKo ? wrongAnswerKo : wrongAnswerEn;
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
      wrongAnswerKo: map['wrongAnswerKo']?.toString() ?? '',
      wrongAnswerEn: map['wrongAnswerEn']?.toString() ?? '',
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
  final List<_QuizHistoryQuestion> questions;
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
    required this.questions,
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
        'questions': questions.map((item) => item.toMap()).toList(),
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
            final questions = (map['questions'] as List?)
                    ?.whereType<Map>()
                    .map(
                      (item) => _QuizHistoryQuestion.fromMap(
                        item.cast<String, dynamic>(),
                      ),
                    )
                    .whereType<_QuizHistoryQuestion>()
                    .toList(growable: false) ??
                const <_QuizHistoryQuestion>[];
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
              questions: questions.isEmpty ? wrongQuestions : questions,
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
  final curated = deduplicated
      .where((question) => !_isObviousQuizQuestion(question))
      .toList(growable: false);
  _runQuizPoolQualityChecks(curated);
  return curated;
}

bool _isObviousQuizQuestion(_FootballQuizQuestion question) {
  const obviousConceptKeys = <String>{
    'match_starts_11',
    'team_size',
    'clean_sheet',
    'hat_trick',
    'half_time_length',
    'penalty_distance',
    'yellow_card_meaning',
    'red_card_meaning',
    'throw_in_restart',
    'goal_kick_restart',
    'corner_restart',
    'body_part_field_player',
    'premier_league',
    'laliga',
    'messi',
    'modric',
    'quality_glycogen_window',
    'quality_advantage_rule',
  };
  if (question.id.startsWith('mcq_gen_')) {
    return true;
  }
  return obviousConceptKeys.contains(question.conceptKey);
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
  return <_OxFactSeed>[
    ..._oxFacts(),
    ..._historyAndFifaRecordOxFacts(),
    ..._advancedFootballHistoryOxFacts(),
    ..._athleteNutritionOxFacts(),
    ..._issue276FormationOxFacts(),
    ..._issue279FormationScenarioOxFacts(),
    ..._qualityScenarioOxFacts(),
  ];
}

List<_McqSeed> _buildMcqSeedPool300() {
  return <_McqSeed>[
    ..._mcqSeeds(),
    ..._historyAndFifaRecordMcqSeeds(),
    ..._advancedFootballHistoryMcqSeeds(),
    ..._athleteNutritionMcqSeeds(),
    ..._issue260CategoryBoosterMcqSeeds(),
    ..._issue271CoreCategoryMcqSeeds(),
    ..._issue276FormationMcqSeeds(),
    ..._issue279FormationScenarioMcqSeeds(),
    ..._qualityScenarioMcqSeeds(),
    ..._deepCoreScenarioMcqSeeds(),
  ];
}

List<_ShortAnswerSeed> _buildShortAnswerSeedPool300() {
  final keywords = <_ShortAnswerKnowledgeSeed>[
    ..._shortAnswerKnowledgeSeeds(),
    ..._historyAndFifaRecordShortAnswerSeeds(),
    ..._advancedFootballHistoryShortAnswerSeeds(),
    ..._athleteNutritionShortAnswerSeeds(),
    ..._issue260CategoryBoosterShortAnswerSeeds(),
    ..._issue276FormationShortAnswerSeeds(),
    ..._issue279FormationScenarioShortAnswerSeeds(),
    ..._qualityScenarioShortAnswerSeeds(),
    ..._deepCoreScenarioShortAnswerSeeds(),
  ];
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

List<_McqSeed> _issue260CategoryBoosterMcqSeeds() {
  return const <_McqSeed>[
    _McqSeed(
      id: 'issue260_backpass_restart',
      difficulty: 2,
      category: _QuizCategory.rules,
      koStem: '수비수가 발로 의도적으로 골키퍼에게 보낸 공을 골키퍼가 손으로 잡으면 재개는 무엇일까요?',
      enStem:
          'If a defender deliberately kicks the ball to the goalkeeper and the keeper handles it, what is the restart?',
      options: [
        _FootballQuizOption(koText: '직접 프리킥', enText: 'Direct free kick'),
        _FootballQuizOption(koText: '간접 프리킥', enText: 'Indirect free kick'),
        _FootballQuizOption(koText: '드롭볼', enText: 'Dropped ball'),
        _FootballQuizOption(koText: '페널티킥', enText: 'Penalty kick'),
      ],
      correctIndex: 1,
      koExplain: '발로 의도적으로 돌려준 공을 골키퍼가 손으로 처리하면 상대 팀의 간접 프리킥입니다.',
      enExplain:
          'If the goalkeeper handles a deliberate kick-back from a teammate, the restart is an indirect free kick for the opponents.',
      koNextPoint: '규칙 문제는 반칙 종류와 재개 방법을 한 묶음으로 기억하세요.',
      enNextPoint:
          'For law questions, study the foul together with the restart.',
    ),
    _McqSeed(
      id: 'issue260_weak_side_switch',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koStem: '상대 수비가 볼 쪽으로 몰렸을 때 반대편 공간을 가장 빠르게 여는 선택은 무엇일까요?',
      enStem:
          'When the defense overloads the ball side, which option opens the weak side fastest?',
      options: [
        _FootballQuizOption(koText: '빠른 전환 패스', enText: 'Quick switch of play'),
        _FootballQuizOption(
          koText: '같은 쪽 드리블 반복',
          enText: 'Repeat dribbles on the same side',
        ),
        _FootballQuizOption(
          koText: '중앙으로 더 모이기',
          enText: 'Crowd the center even more',
        ),
        _FootballQuizOption(
          koText: '라인 밖으로 볼 보내기',
          enText: 'Play the ball out of bounds',
        ),
      ],
      correctIndex: 0,
      koExplain: '볼 반대편으로 빠르게 전환하면 수비 이동 거리가 길어져 약한 쪽 공간이 열립니다.',
      enExplain:
          'A fast switch of play stretches the defense and exposes the weak-side space.',
      koNextPoint: '전환 전에는 반대편 폭과 받는 선수의 몸 방향을 먼저 확인하세요.',
      enNextPoint:
          'Before switching, check the far-side width and the receiver’s body shape.',
    ),
    _McqSeed(
      id: 'issue260_receive_across_body',
      difficulty: 2,
      category: _QuizCategory.technique,
      koStem: '압박을 등지고 공을 받을 때 다음 플레이 방향을 가장 열기 쉬운 터치는 무엇일까요?',
      enStem:
          'When receiving with pressure on your back, which touch most easily opens the next action?',
      options: [
        _FootballQuizOption(
          koText: '몸을 가로지르는 퍼스트 터치',
          enText: 'A first touch across the body',
        ),
        _FootballQuizOption(
          koText: '발밑에 멈추는 터치',
          enText: 'A dead stop under the feet',
        ),
        _FootballQuizOption(
          koText: '눈 감고 뒤꿈치 터치',
          enText: 'A blind back-heel touch',
        ),
        _FootballQuizOption(
          koText: '무조건 강한 터치',
          enText: 'A guaranteed heavy touch',
        ),
      ],
      correctIndex: 0,
      koExplain: '몸을 가로지르는 첫 터치는 수비를 떼어내며 방향 전환과 전진 각도를 함께 만듭니다.',
      enExplain:
          'A first touch across the body separates the defender and opens both turning and forward angles.',
      koNextPoint: '받기 전 스캔과 첫 터치 방향을 하나의 기술로 묶어 보세요.',
      enNextPoint:
          'Treat scanning before the pass and touch direction as one linked skill.',
    ),
    _McqSeed(
      id: 'issue260_screening_midfielder',
      difficulty: 1,
      category: _QuizCategory.positions,
      koStem: '센터백 앞 공간을 지키며 패스 길을 끊는 역할에 가장 가까운 포지션은 무엇일까요?',
      enStem:
          'Which position is closest to screening passing lanes in front of the center backs?',
      options: [
        _FootballQuizOption(koText: '수비형 미드필더', enText: 'Defensive midfielder'),
        _FootballQuizOption(koText: '윙어', enText: 'Winger'),
        _FootballQuizOption(koText: '스트라이커', enText: 'Striker'),
        _FootballQuizOption(koText: '오버래핑 풀백', enText: 'Overlapping full back'),
      ],
      correctIndex: 0,
      koExplain: '수비형 미드필더는 센터백 앞 공간을 보호하며 상대 전진 패스를 차단하는 역할을 자주 맡습니다.',
      enExplain:
          'The defensive midfielder often protects the space ahead of the center backs and screens forward passes.',
      koNextPoint: '포지션 문제는 출발 위치보다 맡는 임무를 중심으로 기억하세요.',
      enNextPoint:
          'For position questions, remember the role before the starting spot.',
    ),
    _McqSeed(
      id: 'issue260_matchday_plus_one',
      difficulty: 1,
      category: _QuizCategory.training,
      koStem: '강한 경기 다음 날(MD+1)에 일반적으로 더 어울리는 세션은 무엇일까요?',
      enStem:
          'Which session is usually more suitable on matchday plus one after a hard game?',
      options: [
        _FootballQuizOption(koText: '회복 세션', enText: 'Recovery session'),
        _FootballQuizOption(koText: '최대 스프린트 반복', enText: 'Max sprint repeats'),
        _FootballQuizOption(
          koText: '고중량 하체 웨이트',
          enText: 'Heavy lower-body lifting',
        ),
        _FootballQuizOption(
          koText: '긴 풀사이드 경기',
          enText: 'A long full-pitch scrimmage',
        ),
      ],
      correctIndex: 0,
      koExplain: '경기 직후에는 피로와 조직 손상이 커서 회복 세션이 다음 훈련 질을 지키는 데 도움이 됩니다.',
      enExplain:
          'Right after a hard match, recovery work is usually the best way to protect the quality of the next training block.',
      koNextPoint: '훈련 문제는 세션 강도보다 주간 배치까지 같이 보세요.',
      enNextPoint:
          'Study training sessions together with where they fit in the week.',
    ),
    _McqSeed(
      id: 'issue260_process_goal',
      difficulty: 1,
      category: _QuizCategory.mindset,
      koStem: '경기 전 스스로 가장 통제하기 쉬운 목표는 무엇일까요?',
      enStem:
          'Which goal is the most controllable for a player before kickoff?',
      options: [
        _FootballQuizOption(
          koText: '받기 전 두 번 스캔하기',
          enText: 'Scan twice before receiving',
        ),
        _FootballQuizOption(
          koText: '반드시 2골 넣기',
          enText: 'Score exactly two goals',
        ),
        _FootballQuizOption(
          koText: '상대 실수 강제하기',
          enText: 'Force the opponent to make mistakes',
        ),
        _FootballQuizOption(
          koText: '심판 판정 바꾸기',
          enText: 'Change the referee’s decisions',
        ),
      ],
      correctIndex: 0,
      koExplain: '과정 목표는 내 행동으로 관리할 수 있어 긴장 상황에서도 집중을 유지하기 쉽습니다.',
      enExplain:
          'Process goals are under your control, which makes them easier to follow under pressure.',
      koNextPoint: '결과 목표는 짧게, 과정 목표는 구체적으로 세우세요.',
      enNextPoint: 'Keep outcome goals short, and make process goals specific.',
    ),
    _McqSeed(
      id: 'issue260_recovery_snack',
      difficulty: 1,
      category: _QuizCategory.nutrition,
      koStem: '고강도 훈련 직후 회복을 빠르게 돕는 선택으로 가장 적절한 것은 무엇일까요?',
      enStem:
          'Which choice best supports quick recovery right after a hard training session?',
      options: [
        _FootballQuizOption(
          koText: '탄수화물, 단백질, 수분 보충',
          enText: 'Carbohydrates, protein, and fluids',
        ),
        _FootballQuizOption(koText: '탄산음료만 마시기', enText: 'Drink only soda'),
        _FootballQuizOption(koText: '아무것도 먹지 않기', enText: 'Eat nothing at all'),
        _FootballQuizOption(koText: '튀김만 많이 먹기', enText: 'Eat only fried food'),
      ],
      correctIndex: 0,
      koExplain: '훈련 직후에는 글리코겐 보충과 근육 회복, 수분 보충을 함께 챙기는 것이 가장 기본입니다.',
      enExplain:
          'Right after training, the basics are refilling glycogen, supporting muscle repair, and replacing fluids.',
      koNextPoint: '영양 문제는 타이밍과 조합을 함께 떠올리세요.',
      enNextPoint:
          'For nutrition, think about timing and combination together.',
    ),
    _McqSeed(
      id: 'issue260_world_cup_2002_cohost',
      difficulty: 1,
      category: _QuizCategory.fun,
      koStem: '2002 FIFA 월드컵을 대한민국과 공동 개최한 나라는 어디일까요?',
      enStem:
          'Which country co-hosted the 2002 FIFA World Cup with Korea Republic?',
      options: [
        _FootballQuizOption(koText: '일본', enText: 'Japan'),
        _FootballQuizOption(koText: '브라질', enText: 'Brazil'),
        _FootballQuizOption(koText: '독일', enText: 'Germany'),
        _FootballQuizOption(koText: '카타르', enText: 'Qatar'),
      ],
      correctIndex: 0,
      koExplain: '2002 월드컵은 한국과 일본이 함께 개최한 첫 공동 개최 FIFA 월드컵이었습니다.',
      enExplain:
          'The 2002 tournament was the first FIFA World Cup co-hosted by Korea Republic and Japan.',
      koNextPoint: '재미 상식은 개최국과 대회의 특징을 함께 묶어 기억하세요.',
      enNextPoint:
          'For fun facts, pair the host nations with what made the tournament unique.',
    ),
  ];
}

List<_ShortAnswerKnowledgeSeed> _issue260CategoryBoosterShortAnswerSeeds() {
  return const <_ShortAnswerKnowledgeSeed>[
    _ShortAnswerKnowledgeSeed(
      id: 'advantage',
      difficulty: 2,
      category: _QuizCategory.rules,
      koClue: '반칙이 있었지만 공격 이익이 더 크다고 보고 심판이 즉시 경기를 이어가게 하는 규칙 운용',
      enClue:
          'Law application where the referee lets play continue because the attacking team has the greater benefit',
      acceptedAnswers: ['어드밴티지', 'advantage'],
      koExplain: '정답은 "어드밴티지"입니다. 반칙이 있어도 공격 이익이 남아 있으면 경기를 바로 끊지 않습니다.',
      enExplain:
          'The answer is "advantage." Play can continue when stopping it would remove a better attacking benefit.',
      koNextPoint: '규칙은 선언 이름과 적용 상황을 함께 기억하세요.',
      enNextPoint:
          'Learn the law term together with the match situation where it appears.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'width',
      difficulty: 1,
      category: _QuizCategory.tactics,
      koClue: '상대를 좌우로 벌려 공간을 넓히기 위해 공격 시 유지하는 개념',
      enClue:
          'Attacking concept of stretching the opponent horizontally to create more space',
      acceptedAnswers: ['폭', 'width'],
      koExplain: '정답은 "폭"입니다. 폭이 살아야 하프스페이스와 중앙 침투 길도 더 잘 열립니다.',
      enExplain:
          'The answer is "width." Good width often opens the half-space and central lanes as well.',
      koNextPoint: '폭은 터치라인에 서는 것보다 수비를 얼마나 벌리느냐로 판단하세요.',
      enNextPoint:
          'Judge width by how far it stretches defenders, not just by standing near the touchline.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'cushion_touch',
      difficulty: 2,
      category: _QuizCategory.technique,
      koClue: '강하게 오는 패스의 힘을 죽여 다루기 쉽게 만드는 첫 터치',
      enClue:
          'First touch that softens a firm pass and makes the ball easier to control',
      acceptedAnswers: ['쿠션 터치', 'cushion touch'],
      koExplain: '정답은 "쿠션 터치"입니다. 공의 속도를 흡수해야 다음 플레이가 부드럽게 이어집니다.',
      enExplain:
          'The answer is "cushion touch." Absorbing the speed of the pass makes the next action smoother.',
      koNextPoint: '터치 방향뿐 아니라 힘을 얼마나 죽였는지도 체크하세요.',
      enNextPoint:
          'Check not only the touch direction but also how much speed you absorbed.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'pivot_midfielder',
      difficulty: 2,
      category: _QuizCategory.positions,
      koClue: '후방 빌드업에서 중앙 연결축이 되는 미드필더 역할을 가리키는 말',
      enClue:
          'Word for the midfielder who acts as the central link in build-up play',
      acceptedAnswers: ['피벗', 'pivot'],
      koExplain: '정답은 "피벗"입니다. 후방과 전방을 이어 주며 방향을 정리하는 축 역할을 합니다.',
      enExplain:
          'The answer is "pivot." This player links the back line and the next line while setting direction.',
      koNextPoint: '포지션은 이름보다 연결 역할을 함께 떠올리면 이해가 빨라집니다.',
      enNextPoint:
          'It becomes easier when you connect the position name with its linking role.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'deload_week',
      difficulty: 2,
      category: _QuizCategory.training,
      koClue: '누적 피로를 줄이기 위해 의도적으로 훈련량이나 강도를 낮추는 주간 조절',
      enClue:
          'Planned reduction of training volume or intensity to reduce accumulated fatigue',
      acceptedAnswers: ['디로드', '디로드 주간', 'deload', 'deload week'],
      koExplain: '정답은 "디로드"입니다. 계속 강하게만 가면 적응보다 피로가 앞서기 쉽습니다.',
      enExplain:
          'The answer is "deload." If intensity stays high all the time, fatigue can outrun adaptation.',
      koNextPoint: '훈련 계획은 강한 주간과 낮추는 주간을 함께 설계하세요.',
      enNextPoint:
          'Plan heavy weeks together with lighter ones, not separately.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'reset_routine',
      difficulty: 2,
      category: _QuizCategory.mindset,
      koClue: '실수 직후 호흡과 짧은 자기 대화로 다음 플레이 집중을 되돌리는 절차',
      enClue:
          'Routine that uses breath and short self-talk to refocus right after a mistake',
      acceptedAnswers: ['리셋 루틴', 'reset routine', 'reset'],
      koExplain:
          '정답은 "리셋 루틴"입니다. 실수를 길게 끌지 않고 다음 플레이로 attention을 옮기는 데 도움을 줍니다.',
      enExplain:
          'The answer is "reset routine." It helps move attention forward instead of staying stuck on the mistake.',
      koNextPoint: '호흡, 시선, 짧은 문장을 한 세트로 미리 정해두세요.',
      enNextPoint:
          'Pre-build a small sequence of breath, gaze, and a short phrase.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'glycogen',
      difficulty: 2,
      category: _QuizCategory.nutrition,
      koClue: '고강도 운동에서 근육과 간에 저장되어 빠르게 쓰이는 탄수화물 에너지 형태',
      enClue:
          'Stored carbohydrate form in muscles and the liver that fuels hard exercise quickly',
      acceptedAnswers: ['글리코겐', 'glycogen'],
      koExplain: '정답은 "글리코겐"입니다. 훈련 후 탄수화물 보충이 중요한 이유도 이 저장고를 다시 채우기 위해서입니다.',
      enExplain:
          'The answer is "glycogen." Refilling it is one reason post-training carbohydrate intake matters.',
      koNextPoint: '영양은 음식 이름뿐 아니라 몸 안에서 어떤 저장고를 채우는지도 같이 보세요.',
      enNextPoint:
          'Learn not just the food, but also the energy store it restores.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'treble',
      difficulty: 1,
      category: _QuizCategory.fun,
      koClue: '한 시즌에 리그, 국내 컵, 대륙 대회를 모두 우승하는 것',
      enClue:
          'Winning the league, the main domestic cup, and the continental title in one season',
      acceptedAnswers: ['트레블', 'treble'],
      koExplain: '정답은 "트레블"입니다. 시즌 전체의 꾸준함과 큰 경기 경쟁력을 함께 보여 주는 표현입니다.',
      enExplain:
          'The answer is "treble." It describes a season that combines consistency and big-match success.',
      koNextPoint: '재미 상식은 단어의 뜻과 대표 사례를 함께 외우면 오래 갑니다.',
      enNextPoint:
          'Fun facts stick better when you link the term with a famous example.',
    ),
  ];
}

List<_OxFactSeed> _issue276FormationOxFacts() {
  return const <_OxFactSeed>[
    _OxFactSeed(
      id: 'issue276_formation_numbers_exclude_keeper',
      difficulty: 1,
      category: _QuizCategory.tactics,
      koTrueStatement: '4-3-3 같은 포메이션 숫자는 골키퍼를 제외한 필드 플레이어만 셉니다.',
      enTrueStatement:
          'Formation numbers such as 4-3-3 count only outfield players, not the goalkeeper.',
      koFalseStatement: '4-3-3 같은 포메이션 숫자에는 골키퍼까지 포함됩니다.',
      enFalseStatement:
          'Formation numbers such as 4-3-3 include the goalkeeper.',
      koExplain: '포메이션 숫자는 보통 수비-미드필드-공격 라인의 필드 플레이어 수를 뜻합니다.',
      enExplain:
          'Formation numbers normally describe outfield players across defense, midfield, and attack.',
      koNextPoint: '포메이션을 볼 때 골키퍼 1명은 항상 별도로 생각하세요.',
      enNextPoint: 'When reading formations, keep the goalkeeper separate.',
    ),
    _OxFactSeed(
      id: 'issue276_433_line_count',
      difficulty: 1,
      category: _QuizCategory.tactics,
      koTrueStatement: '4-3-3은 수비 4명, 미드필더 3명, 공격수 3명을 기본으로 봅니다.',
      enTrueStatement:
          'A 4-3-3 is read as four defenders, three midfielders, and three forwards.',
      koFalseStatement: '4-3-3은 수비 4명, 미드필더 4명, 공격수 3명을 기본으로 봅니다.',
      enFalseStatement:
          'A 4-3-3 is read as four defenders, four midfielders, and three forwards.',
      koExplain: '4-3-3의 세 숫자는 뒤에서부터 수비, 미드필드, 공격 라인을 나타냅니다.',
      enExplain:
          'The three numbers in 4-3-3 describe the defensive, midfield, and attacking lines.',
      koNextPoint: '숫자는 항상 뒤에서 앞으로 읽는 습관을 들이세요.',
      enNextPoint: 'Practice reading the numbers from back to front.',
    ),
    _OxFactSeed(
      id: 'issue276_back_three_width',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koTrueStatement: '스리백 전형은 윙백이나 넓게 서는 미드필더가 폭을 책임지는 경우가 많습니다.',
      enTrueStatement:
          'Back-three systems often rely on wing-backs or wide midfielders for width.',
      koFalseStatement: '스리백 전형은 폭을 만들 선수가 필요 없기 때문에 항상 중앙에만 모입니다.',
      enFalseStatement:
          'Back-three systems do not need width and always stay only in the center.',
      koExplain: '스리백은 중앙 수비 숫자가 많아지는 대신 측면 폭을 따로 관리해야 합니다.',
      enExplain:
          'Back-three shapes add central defenders, so the wide lanes still need clear coverage.',
      koNextPoint: '포메이션은 숫자보다 각 라인이 폭을 누가 책임지는지 함께 보세요.',
      enNextPoint:
          'Read formations by checking who owns the wide lanes, not just the numbers.',
    ),
    _OxFactSeed(
      id: 'issue276_442_two_forwards',
      difficulty: 1,
      category: _QuizCategory.tactics,
      koTrueStatement: '4-4-2는 보통 공격수 2명을 앞에 두는 전형입니다.',
      enTrueStatement: 'A 4-4-2 usually places two forwards up front.',
      koFalseStatement: '4-4-2는 보통 공격수 1명만 앞에 두는 전형입니다.',
      enFalseStatement: 'A 4-4-2 usually places only one forward up front.',
      koExplain: '4-4-2의 마지막 숫자 2는 최전방 공격수 두 명을 뜻합니다.',
      enExplain:
          'The final number in 4-4-2 means two players in the forward line.',
      koNextPoint: '마지막 숫자는 전방에 몇 명이 남는지를 먼저 확인하세요.',
      enNextPoint:
          'Use the final number to check how many players stay up front.',
    ),
  ];
}

List<_McqSeed> _issue276FormationMcqSeeds() {
  return const <_McqSeed>[
    _McqSeed(
      id: 'issue276_433_counts',
      difficulty: 1,
      category: _QuizCategory.tactics,
      koStem: '4-3-3 포메이션의 기본 숫자 해석으로 맞는 것은 무엇일까요?',
      enStem: 'Which reading of a 4-3-3 formation is correct?',
      options: [
        _FootballQuizOption(
          koText: '수비 4명, 미드필더 3명, 공격수 3명',
          enText: '4 defenders, 3 midfielders, 3 forwards',
        ),
        _FootballQuizOption(
          koText: '수비 4명, 미드필더 4명, 공격수 3명',
          enText: '4 defenders, 4 midfielders, 3 forwards',
        ),
        _FootballQuizOption(
          koText: '수비 3명, 미드필더 3명, 공격수 4명',
          enText: '3 defenders, 3 midfielders, 4 forwards',
        ),
        _FootballQuizOption(
          koText: '골키퍼 4명, 미드필더 3명, 공격수 3명',
          enText: '4 goalkeepers, 3 midfielders, 3 forwards',
        ),
      ],
      correctIndex: 0,
      koExplain: '4-3-3은 뒤에서부터 수비 4명, 미드필더 3명, 공격수 3명으로 읽습니다.',
      enExplain:
          'A 4-3-3 is read from back to front: 4 defenders, 3 midfielders, 3 forwards.',
      koNextPoint: '포메이션 숫자는 뒤에서 앞으로 읽으세요.',
      enNextPoint: 'Read formation numbers from back to front.',
    ),
    _McqSeed(
      id: 'issue276_352_width',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koStem: '3-5-2에서 측면 폭과 왕복 움직임을 주로 책임지는 역할은 무엇일까요?',
      enStem:
          'In a 3-5-2, which role often owns the wide lane and runs up and down?',
      options: [
        _FootballQuizOption(koText: '윙백', enText: 'Wing-back'),
        _FootballQuizOption(koText: '센터백', enText: 'Center back'),
        _FootballQuizOption(koText: '골키퍼', enText: 'Goalkeeper'),
        _FootballQuizOption(koText: '단일 스트라이커', enText: 'Lone striker'),
      ],
      correctIndex: 0,
      koExplain: '3-5-2에서는 윙백이 측면 폭을 만들고 수비 전환 때도 내려오는 경우가 많습니다.',
      enExplain:
          'In a 3-5-2, wing-backs often create width and recover into the wide defensive lanes.',
      koNextPoint: '스리백 전형은 윙백의 높이와 회복 속도를 함께 보세요.',
      enNextPoint:
          'In back-three systems, watch wing-back height and recovery runs.',
    ),
    _McqSeed(
      id: 'issue276_4231_double_pivot',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koStem: '4-2-3-1에서 수비 라인 앞의 두 중앙 미드필더 조합을 흔히 무엇이라 부를까요?',
      enStem:
          'In a 4-2-3-1, what is the pair of central midfielders in front of the back line often called?',
      options: [
        _FootballQuizOption(koText: '더블 피벗', enText: 'Double pivot'),
        _FootballQuizOption(koText: '스리톱', enText: 'Front three'),
        _FootballQuizOption(koText: '오버래핑 듀오', enText: 'Overlapping duo'),
        _FootballQuizOption(koText: '센터백 라인', enText: 'Center-back line'),
      ],
      correctIndex: 0,
      koExplain: '4-2-3-1의 두 번째 숫자 2는 수비 앞에서 균형을 잡는 더블 피벗으로 해석할 수 있습니다.',
      enExplain:
          'The second number in 4-2-3-1 is often a double pivot that balances the team ahead of the back line.',
      koNextPoint: '피벗은 공 전개와 역습 대비를 동시에 맡는지 살펴보세요.',
      enNextPoint:
          'Check whether the pivot supports build-up and protects against counters.',
    ),
    _McqSeed(
      id: 'issue276_442_banks',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koStem: '4-4-2가 수비할 때 자주 만드는 안정적인 구조는 무엇일까요?',
      enStem: 'What stable defensive structure does a 4-4-2 often create?',
      options: [
        _FootballQuizOption(koText: '두 줄의 4명', enText: 'Two banks of four'),
        _FootballQuizOption(koText: '한 줄의 8명', enText: 'One line of eight'),
        _FootballQuizOption(
          koText: '공격수 4명 압박만',
          enText: 'Only four forwards press',
        ),
        _FootballQuizOption(koText: '골키퍼 두 명', enText: 'Two goalkeepers'),
      ],
      correctIndex: 0,
      koExplain: '4-4-2는 수비와 미드필드가 각각 4명씩 줄을 만들면 간격 관리가 쉬워집니다.',
      enExplain:
          'A 4-4-2 can defend compactly with four defenders and four midfielders in two organized lines.',
      koNextPoint: '수비 전형은 선수 숫자보다 줄 간격과 좌우 폭을 함께 보세요.',
      enNextPoint:
          'For defensive shapes, watch the gaps and width between the lines.',
    ),
    _McqSeed(
      id: 'issue276_4141_anchor',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koStem: '4-1-4-1에서 수비진 앞의 1명이 맡는 핵심 역할은 무엇일까요?',
      enStem:
          'In a 4-1-4-1, what is the key role of the single player ahead of the defense?',
      options: [
        _FootballQuizOption(
          koText: '수비형 미드필더로 중앙을 보호한다',
          enText: 'Protect the center as the holding midfielder',
        ),
        _FootballQuizOption(
          koText: '항상 최전방에서만 뛴다',
          enText: 'Always stay as the highest forward',
        ),
        _FootballQuizOption(koText: '스로인을 전담한다', enText: 'Take every throw-in'),
        _FootballQuizOption(
          koText: '골키퍼와 위치를 바꾼다',
          enText: 'Swap position with the goalkeeper',
        ),
      ],
      correctIndex: 0,
      koExplain: '4-1-4-1의 가운데 1명은 수비 앞 공간을 지키고 전개 방향을 정리하는 축이 됩니다.',
      enExplain:
          'The single midfielder in a 4-1-4-1 protects space in front of the defense and helps organize play.',
      koNextPoint: '홀딩 미드필더가 상대 10번 공간을 어떻게 막는지 관찰하세요.',
      enNextPoint:
          'Watch how the holding midfielder protects the opponent’s No.10 space.',
    ),
    _McqSeed(
      id: 'issue276_numbers_exclude_gk',
      difficulty: 1,
      category: _QuizCategory.tactics,
      koStem: '포메이션 숫자에 대한 설명으로 가장 정확한 것은 무엇일까요?',
      enStem: 'Which statement about formation numbers is most accurate?',
      options: [
        _FootballQuizOption(
          koText: '골키퍼를 제외한 필드 플레이어의 줄 배치를 뜻한다',
          enText: 'They show outfield player lines, excluding the goalkeeper',
        ),
        _FootballQuizOption(
          koText: '골키퍼 숫자만 뜻한다',
          enText: 'They show only the number of goalkeepers',
        ),
        _FootballQuizOption(
          koText: '항상 교체 선수 수를 뜻한다',
          enText: 'They always show the number of substitutes',
        ),
        _FootballQuizOption(
          koText: '득점 수를 미리 정해 둔 것이다',
          enText: 'They pre-set the scoreline',
        ),
      ],
      correctIndex: 0,
      koExplain: '4-3-3, 3-5-2 같은 숫자는 골키퍼를 제외한 필드 플레이어의 줄 배치입니다.',
      enExplain:
          'Numbers such as 4-3-3 or 3-5-2 describe outfield player lines and exclude the goalkeeper.',
      koNextPoint: '포메이션은 숫자와 실제 역할이 어떻게 달라지는지도 같이 보세요.',
      enNextPoint:
          'Compare the formation numbers with the actual roles during play.',
    ),
  ];
}

List<_ShortAnswerKnowledgeSeed> _issue276FormationShortAnswerSeeds() {
  return const <_ShortAnswerKnowledgeSeed>[
    _ShortAnswerKnowledgeSeed(
      id: 'formation_4231',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koClue: '수비 4명, 더블 피벗 2명, 공격형 미드필더 3명, 스트라이커 1명으로 읽는 전형',
      enClue:
          'Formation read as four defenders, two holding midfielders, three attacking midfielders, and one striker',
      acceptedAnswers: ['4-2-3-1', '4231'],
      koExplain: '정답은 "4-2-3-1"입니다. 중앙 균형과 2선 공격 지원을 함께 만들기 좋은 전형입니다.',
      enExplain:
          'The answer is "4-2-3-1." It balances a double pivot with three attacking midfielders behind one striker.',
      koNextPoint: '포메이션 숫자는 각 줄의 역할까지 함께 말해 보세요.',
      enNextPoint: 'Name the formation and the job of each line together.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'formation_wing_back',
      difficulty: 2,
      category: _QuizCategory.positions,
      koClue: '3-5-2 같은 스리백 전형에서 측면 폭과 수비 복귀를 함께 맡는 역할',
      enClue:
          'Role in many back-three systems that provides width and also recovers defensively',
      acceptedAnswers: ['윙백', 'wing-back', 'wingback'],
      koExplain: '정답은 "윙백"입니다. 공격 때는 폭을 만들고 수비 때는 측면을 내려와 막습니다.',
      enExplain:
          'The answer is "wing-back." This role gives width in attack and recovers into the wide defensive lane.',
      koNextPoint: '윙백은 높이, 크로스, 수비 복귀를 한 묶음으로 평가하세요.',
      enNextPoint:
          'Evaluate wing-backs by height, crossing, and recovery defending.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'formation_double_pivot',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koClue: '4-2-3-1에서 수비 라인 앞 두 미드필더 조합을 부르는 말',
      enClue:
          'Term for the pair of midfielders in front of the defense in a 4-2-3-1',
      acceptedAnswers: ['더블 피벗', 'double pivot', 'double-pivot'],
      koExplain: '정답은 "더블 피벗"입니다. 두 명이 전개와 역습 대비를 나눠 맡습니다.',
      enExplain:
          'The answer is "double pivot." The pair shares build-up and counter-protection duties.',
      koNextPoint: '두 피벗 중 누가 전진하고 누가 남는지 보면 전술 의도가 보입니다.',
      enNextPoint: 'Watch which pivot steps forward and which one stays.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'formation_two_banks_four',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koClue: '4-4-2 수비에서 수비 4명과 미드필더 4명이 만드는 두 줄 구조',
      enClue:
          'Two-line defensive structure made by four defenders and four midfielders in a 4-4-2',
      acceptedAnswers: ['두 줄의 4명', 'two banks of four', 'banks of four'],
      koExplain: '정답은 "두 줄의 4명"입니다. 좌우와 앞뒤 간격을 좁히기 쉬운 구조입니다.',
      enExplain:
          'The answer is "two banks of four." It helps a team control horizontal and vertical gaps.',
      koNextPoint: '수비 구조는 숫자보다 간격이 유지되는지 먼저 보세요.',
      enNextPoint:
          'For defensive shapes, check the spacing before the raw numbers.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'formation_433_front',
      difficulty: 1,
      category: _QuizCategory.tactics,
      koClue: '4-3-3의 마지막 숫자가 뜻하는 전방 선수 수',
      enClue: 'Number of front-line players shown by the final digit in 4-3-3',
      acceptedAnswers: ['3', '세 명', '3명', 'three'],
      koExplain: '정답은 "3"입니다. 4-3-3은 보통 전방에 세 명을 둡니다.',
      enExplain:
          'The answer is "3." A 4-3-3 usually has three players in the forward line.',
      koNextPoint: '마지막 숫자는 최전방 라인의 숫자라는 점을 기억하세요.',
      enNextPoint: 'Remember that the final number describes the forward line.',
    ),
  ];
}

List<_OxFactSeed> _issue279FormationScenarioOxFacts() {
  return const <_OxFactSeed>[
    _OxFactSeed(
      id: 'issue279_formation_changes_by_phase',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koTrueStatement: '좋은 포메이션 학습은 공격, 수비, 전환 순간의 모양이 달라질 수 있음을 함께 봅니다.',
      enTrueStatement:
          'Good formation learning checks how the shape can change in attack, defense, and transition.',
      koFalseStatement: '포메이션은 경기 시작 위치만 외우면 되고 공격과 수비 모양은 볼 필요가 없습니다.',
      enFalseStatement:
          'A formation only needs the kickoff positions; attacking and defending shapes do not matter.',
      koExplain: '포메이션은 출발점이고, 실제 경기에서는 공 위치와 압박 방향에 따라 라인 높이와 역할이 바뀝니다.',
      enExplain:
          'A formation is the starting map; line height and roles change with ball location and pressing direction.',
      koNextPoint: '숫자를 외운 뒤에는 "공을 가졌을 때"와 "공을 잃었을 때" 모양을 따로 그려보세요.',
      enNextPoint:
          'After learning the numbers, draw the in-possession and out-of-possession shapes separately.',
    ),
    _OxFactSeed(
      id: 'issue279_formation_spacing_beats_labels',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koTrueStatement: '같은 4-3-3이라도 선수 간격과 풀백 높이가 다르면 완전히 다른 전술처럼 보일 수 있습니다.',
      enTrueStatement:
          'The same 4-3-3 can play very differently when spacing and fullback height change.',
      koFalseStatement: '같은 4-3-3이면 선수 간격이나 풀백 높이와 상관없이 항상 같은 전술입니다.',
      enFalseStatement:
          'Every 4-3-3 is tactically identical regardless of spacing or fullback height.',
      koExplain: '포메이션 이름보다 라인 간격, 측면 폭, 누가 전진하고 누가 남는지가 실제 플레이를 더 많이 결정합니다.',
      enExplain:
          'Spacing, width, and who steps or stays often decide more than the formation label alone.',
      koNextPoint: '포메이션 문제를 풀 때는 숫자 다음에 간격, 폭, 남는 수비를 확인하세요.',
      enNextPoint:
          'When answering formation questions, check spacing, width, and rest defense after the numbers.',
    ),
  ];
}

List<_McqSeed> _issue279FormationScenarioMcqSeeds() {
  return const <_McqSeed>[
    _McqSeed(
      id: 'issue279_433_press_fullback_cover',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koStem:
          '4-3-3으로 전방 압박할 때 우리 윙어가 상대 풀백에게 뛰어나갑니다. 같은 측면 풀백이 동시에 높게 뛰면 가장 먼저 확인해야 할 위험은 무엇일까요?',
      enStem:
          'In a 4-3-3 press, your winger jumps to the opponent fullback. If your same-side fullback also jumps high, what danger should you check first?',
      options: [
        _FootballQuizOption(
          koText: '그 뒤 측면 공간을 누가 커버하는지',
          enText: 'Who covers the wide space behind them',
        ),
        _FootballQuizOption(
          koText: '반대편 윙어가 얼마나 넓게 서 있는지',
          enText: 'How wide the far-side winger is positioned',
        ),
        _FootballQuizOption(
          koText: '공 소유자가 어느 발로 패스할 수 있는지',
          enText: 'Which foot the ball carrier can use to pass',
        ),
        _FootballQuizOption(
          koText: '압박 방향이 중앙을 열어 주는지',
          enText: 'Whether the pressing angle opens the center',
        ),
      ],
      correctIndex: 0,
      koExplain:
          '윙어와 풀백이 동시에 전진하면 뒤 측면 채널이 열릴 수 있어 센터백, 6번, 반대편 라인의 커버 약속이 필요합니다.',
      enExplain:
          'If the winger and fullback both step out, the wide channel behind them can open, so cover from a center back, No.6, or the opposite line matters.',
      koNextPoint: '압박은 "누가 나가나"보다 "나간 자리 뒤를 누가 막나"까지 묶어서 보세요.',
      enNextPoint:
          'Study pressing by pairing who jumps with who protects the space behind.',
    ),
    _McqSeed(
      id: 'issue279_4231_double_pivot_jobs',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koStem:
          '4-2-3-1에서 더블 피벗이 역습을 줄이려면 두 선수가 같은 순간에 모두 전진하기보다 어떤 관계를 만드는 편이 좋을까요?',
      enStem:
          'In a 4-2-3-1, how should a double pivot usually behave to reduce counterattack risk?',
      options: [
        _FootballQuizOption(
          koText: '한 명이 전진하면 한 명은 중앙을 보호한다',
          enText: 'If one steps forward, the other protects the center',
        ),
        _FootballQuizOption(
          koText: '두 명 모두 항상 최전방으로 뛴다',
          enText: 'Both always run to the front line',
        ),
        _FootballQuizOption(
          koText: '두 명 모두 터치라인 밖에 선다',
          enText: 'Both stand outside the touchline',
        ),
        _FootballQuizOption(
          koText: '둘 다 골키퍼 뒤에서 대기한다',
          enText: 'Both wait behind the goalkeeper',
        ),
      ],
      correctIndex: 0,
      koExplain:
          '더블 피벗은 전개 지원과 역습 대비를 나눠 맡아야 합니다. 둘 다 전진하면 센터백 앞 중앙 공간이 비기 쉽습니다.',
      enExplain:
          'A double pivot shares build-up support and counter-protection. If both step forward, the central space ahead of the center backs can open.',
      koNextPoint: '피벗 문제는 "전진하는 선수"와 "남아 균형 잡는 선수"를 동시에 찾으세요.',
      enNextPoint:
          'For pivot questions, identify both the player who steps and the player who balances.',
    ),
    _McqSeed(
      id: 'issue279_343_wingback_space',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koStem:
          '3-4-3에서 윙백이 높게 올라가 폭을 만들었습니다. 공을 잃은 직후 상대가 그 뒤 공간으로 패스하려 할 때 가장 현실적인 커버 원칙은 무엇일까요?',
      enStem:
          'In a 3-4-3, the wingback has pushed high to provide width. Right after losing the ball, the opponent tries to pass behind that wingback. What is the most realistic cover principle?',
      options: [
        _FootballQuizOption(
          koText: '바깥 센터백이 측면으로 밀고, 가까운 미드필더가 중앙을 메운다',
          enText:
              'The outside center back shifts wide while the nearest midfielder protects the center',
        ),
        _FootballQuizOption(
          koText: '전방 세 명이 모두 골문 안으로 들어간다',
          enText: 'All three forwards move into the goal',
        ),
        _FootballQuizOption(
          koText: '윙백 뒤 공간은 아무도 신경 쓰지 않는다',
          enText: 'No one needs to care about the space behind the wingback',
        ),
        _FootballQuizOption(
          koText: '센터백 세 명이 모두 같은 측면으로 몰린다',
          enText: 'All three center backs rush to the same touchline',
        ),
      ],
      correctIndex: 0,
      koExplain:
          '스리백은 바깥 센터백이 측면을 커버할 수 있지만, 동시에 중앙 커버가 비지 않도록 미드필더와 간격을 맞춰야 합니다.',
      enExplain:
          'A back three can let the outside center back cover wide, but the midfield must protect central gaps at the same time.',
      koNextPoint: '스리백 전형은 윙백 높이와 바깥 센터백의 커버 범위를 함께 보세요.',
      enNextPoint:
          'In back-three shapes, connect wingback height with the outside center back cover range.',
    ),
    _McqSeed(
      id: 'issue279_442_vs_midfield_three',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koStem:
          '4-4-2로 수비하는 팀이 상대 4-3-3의 미드필더 3명에게 중앙 숫자 열세를 겪습니다. 교육적으로 가장 좋은 조정은 무엇일까요?',
      enStem:
          'A team defending in 4-4-2 is outnumbered centrally by the opponent 4-3-3 midfield three. Which adjustment is most useful to teach?',
      options: [
        _FootballQuizOption(
          koText: '한 공격수가 내려와 4-4-1-1처럼 중앙 패스길을 막는다',
          enText:
              'One forward drops to block central lanes, making it look like a 4-4-1-1',
        ),
        _FootballQuizOption(
          koText: '두 센터백이 모두 공격수처럼 올라간다',
          enText: 'Both center backs step up like forwards',
        ),
        _FootballQuizOption(
          koText: '측면 미드필더가 계속 터치라인 밖에 선다',
          enText: 'Wide midfielders keep standing outside the touchline',
        ),
        _FootballQuizOption(
          koText: '골키퍼가 미드필더 숫자 싸움에 직접 들어간다',
          enText: 'The goalkeeper joins the midfield duel directly',
        ),
      ],
      correctIndex: 0,
      koExplain:
          '4-4-2는 전방 두 명 중 한 명이 내려와 상대 6번이나 8번을 가리면 중앙 숫자 열세를 줄일 수 있습니다.',
      enExplain:
          'A 4-4-2 can reduce the central underload when one forward drops to screen the opponent No.6 or No.8.',
      koNextPoint: '포메이션 상성은 숫자 싸움과 패스길 차단 위치를 같이 계산하세요.',
      enNextPoint:
          'For formation matchups, count numbers and locate the passing lanes being screened.',
    ),
    _McqSeed(
      id: 'issue279_inverted_fullback_reason',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koStem: '4-3-3에서 한 풀백이 빌드업 때 안쪽 미드필드로 들어오는 이유로 가장 타당한 것은 무엇일까요?',
      enStem:
          'In a 4-3-3, why might one fullback step inside into midfield during build-up?',
      options: [
        _FootballQuizOption(
          koText: '중앙에 패스 선택지와 역습 대비 숫자를 늘리기 위해',
          enText:
              'To add central passing options and counter-protection numbers',
        ),
        _FootballQuizOption(
          koText: '오프사이드 규칙을 없애기 위해',
          enText: 'To remove the offside law',
        ),
        _FootballQuizOption(
          koText: '상대 골키퍼와 위치를 바꾸기 위해',
          enText: 'To swap places with the opponent goalkeeper',
        ),
        _FootballQuizOption(
          koText: '팀을 12명으로 만들기 위해',
          enText: 'To make the team play with 12 players',
        ),
      ],
      correctIndex: 0,
      koExplain: '인버티드 풀백은 중앙 연결을 늘리고 공을 잃었을 때 바로 압박하거나 커버할 수 있는 위치를 만듭니다.',
      enExplain:
          'An inverted fullback can add a central connection and be close enough to press or cover right after possession is lost.',
      koNextPoint: '풀백 위치 변화는 공격 지원과 전환 수비를 함께 설명해야 합니다.',
      enNextPoint:
          'Explain fullback movement through both attacking support and transition defense.',
    ),
  ];
}

List<_ShortAnswerKnowledgeSeed> _issue279FormationScenarioShortAnswerSeeds() {
  return const <_ShortAnswerKnowledgeSeed>[
    _ShortAnswerKnowledgeSeed(
      id: 'formation_phase_shape',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koClue: '같은 팀이 공격할 때와 수비할 때 포메이션 모양을 다르게 가져가는 것을 설명할 때 쓰는 표현',
      enClue:
          'Term used when a team changes its formation shape between attacking and defending phases',
      acceptedAnswers: ['가변 포메이션', '가변 전형', 'fluid formation', 'fluid shape'],
      koExplain:
          '정답은 "가변 포메이션"입니다. 예를 들어 수비 때 4-4-2, 공격 때 3-2-5처럼 단계별 모양이 달라질 수 있습니다.',
      enExplain:
          'The answer is "fluid formation." A team may defend in a 4-4-2 and attack in a 3-2-5, depending on phase.',
      koNextPoint: '포메이션을 볼 때는 시작 배치와 공격 시 배치, 수비 시 배치를 따로 말해 보세요.',
      enNextPoint:
          'Describe the starting shape, attacking shape, and defending shape separately.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'formation_inverted_fullback',
      difficulty: 2,
      category: _QuizCategory.positions,
      koClue: '빌드업 때 터치라인이 아니라 중앙 미드필드 쪽으로 들어오는 풀백 역할',
      enClue:
          'Fullback role that moves into central midfield during build-up instead of staying on the touchline',
      acceptedAnswers: [
        '인버티드 풀백',
        '인버티드 풀백 역할',
        'inverted fullback',
        'inverted full-back',
      ],
      koExplain: '정답은 "인버티드 풀백"입니다. 중앙 패스 길과 전환 수비 위치를 동시에 보강하는 데 쓰입니다.',
      enExplain:
          'The answer is "inverted fullback." It can strengthen central passing options and transition defense at the same time.',
      koNextPoint: '풀백이 안으로 들어올 때 누가 측면 폭을 유지하는지도 함께 확인하세요.',
      enNextPoint:
          'When a fullback moves inside, also check who keeps the wide lane.',
    ),
  ];
}

List<_OxFactSeed> _qualityScenarioOxFacts() {
  return const <_OxFactSeed>[
    _OxFactSeed(
      id: 'quality_pressing_angle_lanes',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koTrueStatement: '좋은 압박은 공 가진 선수만 쫓는 것이 아니라 다음 패스 길을 닫는 각도까지 포함합니다.',
      enTrueStatement:
          'Good pressing includes the angle that closes the next passing lane, not only chasing the ball carrier.',
      koFalseStatement: '좋은 압박은 공 가진 선수만 전력 질주로 따라가면 되고 다음 패스 길은 상관없습니다.',
      enFalseStatement:
          'Good pressing is only a full-speed chase of the ball carrier; the next passing lane does not matter.',
      koExplain: '압박은 속도, 각도, 뒤 공간 커버가 함께 맞아야 탈출 패스를 줄일 수 있습니다.',
      enExplain:
          'Pressing works when speed, angle, and cover behind the press fit together.',
      koNextPoint: '압박 문제는 누가 뛰는지보다 어떤 길을 닫는지 먼저 보세요.',
      enNextPoint:
          'For pressing questions, identify which lane is being closed first.',
    ),
    _OxFactSeed(
      id: 'quality_first_touch_next_action',
      difficulty: 1,
      category: _QuizCategory.technique,
      koTrueStatement: '좋은 퍼스트 터치는 공을 멈추는 것뿐 아니라 다음 플레이 방향을 미리 만듭니다.',
      enTrueStatement:
          'A good first touch does not only stop the ball; it prepares the direction of the next action.',
      koFalseStatement: '퍼스트 터치는 공만 완전히 멈추면 충분하고 다음 플레이 방향은 상관없습니다.',
      enFalseStatement:
          'A first touch is complete if the ball stops dead; the next direction does not matter.',
      koExplain: '첫 터치가 다음 공간으로 이어지면 압박을 받기 전 패스, 드리블, 슈팅 선택지가 살아납니다.',
      enExplain:
          'A first touch into the next space keeps passing, dribbling, and shooting options alive before pressure arrives.',
      koNextPoint: '터치 문제는 접촉 순간과 두 번째 행동을 한 묶음으로 판단하세요.',
      enNextPoint:
          'Judge touch questions by connecting contact with the second action.',
    ),
    _OxFactSeed(
      id: 'quality_recovery_day_load',
      difficulty: 2,
      category: _QuizCategory.training,
      koTrueStatement: '회복일에는 피로 신호에 따라 강도와 양을 낮추는 선택이 다음 훈련 질을 지킬 수 있습니다.',
      enTrueStatement:
          'On recovery days, lowering intensity and volume based on fatigue signs can protect the next session.',
      koFalseStatement: '회복일에는 피로가 있어도 강도와 양을 더 올려야 항상 성장 속도가 빨라집니다.',
      enFalseStatement:
          'On recovery days, increasing intensity and volume always speeds up growth even when fatigue is clear.',
      koExplain: '회복은 쉬기만 하는 뜻이 아니라 다음 고강도 훈련을 준비하도록 부하를 조절하는 과정입니다.',
      enExplain:
          'Recovery is not just rest; it is load control that prepares the next high-quality session.',
      koNextPoint: '훈련 문제는 오늘 강도와 다음 세션의 질을 함께 연결하세요.',
      enNextPoint:
          'In training questions, link today’s load with the next session’s quality.',
    ),
    _OxFactSeed(
      id: 'quality_pregame_routine_repeatable',
      difficulty: 1,
      category: _QuizCategory.mindset,
      koTrueStatement: '경기 전 루틴은 짧고 반복 가능하며 바로 행동으로 이어질수록 실전에서 쓰기 쉽습니다.',
      enTrueStatement:
          'A pregame routine is easier to use in matches when it is short, repeatable, and linked to action.',
      koFalseStatement: '경기 전 루틴은 매번 길고 즉흥적으로 바뀔수록 실전 집중에 가장 안정적입니다.',
      enFalseStatement:
          'A pregame routine is most stable when it is long and improvised differently every time.',
      koExplain: '루틴은 긴 설명보다 호흡, 시선, 첫 행동처럼 바로 실행되는 cue가 중요합니다.',
      enExplain:
          'A routine works best as executable cues such as breath, gaze, and first action.',
      koNextPoint: '마인드 문제는 감정보다 행동으로 돌아오는 절차를 찾으세요.',
      enNextPoint:
          'For mindset questions, look for the procedure that returns attention to action.',
    ),
    _OxFactSeed(
      id: 'quality_hydration_planned',
      difficulty: 2,
      category: _QuizCategory.nutrition,
      koTrueStatement:
          '수분 보충은 갈증만 기다리기보다 훈련 시간, 더위, 땀 양을 함께 보고 미리 계획하는 편이 좋습니다.',
      enTrueStatement:
          'Hydration is better planned from session length, heat, and sweat rate instead of waiting only for thirst.',
      koFalseStatement: '수분 보충은 어떤 환경에서도 갈증이 날 때만 마시면 항상 충분합니다.',
      enFalseStatement:
          'Hydration is always sufficient in every environment if you drink only when thirsty.',
      koExplain: '긴 훈련이나 더운 환경에서는 갈증이 늦게 느껴질 수 있어 미리 마시는 계획이 필요합니다.',
      enExplain:
          'In long or hot sessions, thirst can arrive late, so a simple drinking plan helps.',
      koNextPoint: '영양/회복 문제는 타이밍, 환경, 몸 반응을 같이 보세요.',
      enNextPoint:
          'For nutrition and recovery, connect timing, environment, and body response.',
    ),
    _OxFactSeed(
      id: 'quality_position_role_context',
      difficulty: 1,
      category: _QuizCategory.positions,
      koTrueStatement: '포지션은 시작 위치뿐 아니라 압박, 커버, 연결 같은 역할로 함께 이해해야 합니다.',
      enTrueStatement:
          'Positions should be understood through roles such as pressing, covering, and connecting, not only starting spots.',
      koFalseStatement: '포지션은 경기 시작 위치만 알면 되고 압박, 커버, 연결 역할은 볼 필요가 없습니다.',
      enFalseStatement:
          'Positions only require knowing kickoff spots; pressing, covering, and linking roles do not matter.',
      koExplain: '같은 포지션 이름도 팀 전술과 경기 단계에 따라 맡는 일이 달라질 수 있습니다.',
      enExplain:
          'The same position name can carry different jobs depending on the team plan and game phase.',
      koNextPoint: '포지션 문제는 위치 이름과 실제 임무를 같이 묶어 보세요.',
      enNextPoint:
          'In position questions, pair the position name with the actual job.',
    ),
  ];
}

List<_McqSeed> _qualityScenarioMcqSeeds() {
  return const <_McqSeed>[
    _McqSeed(
      id: 'quality_scan_before_receive',
      difficulty: 2,
      category: _QuizCategory.technique,
      koStem: '중앙에서 공을 받기 직전 가장 먼저 확인하면 좋은 정보는 무엇일까요?',
      enStem:
          'Just before receiving in central midfield, what is the best information to check first?',
      options: [
        _FootballQuizOption(
          koText: '압박 방향과 다음 패스 선택지',
          enText: 'Pressure direction and next passing options',
        ),
        _FootballQuizOption(
          koText: '공을 받은 뒤 첫 터치가 끝나고 나서만 주변을 본다',
          enText: 'Look around only after the first touch is already finished',
        ),
        _FootballQuizOption(
          koText: '가장 먼 공격수 위치만 보고 압박은 무시한다',
          enText: 'Check only the farthest forward and ignore pressure',
        ),
        _FootballQuizOption(
          koText: '패스가 오는 발만 보고 몸 방향은 고정한다',
          enText: 'Watch only the arriving foot and keep the body fixed',
        ),
      ],
      correctIndex: 0,
      koExplain: '받기 전 스캔은 압박이 어느 쪽에서 오는지와 공을 받은 뒤 어디로 연결할지를 미리 정하게 해 줍니다.',
      enExplain:
          'Scanning before receiving helps you pre-read pressure and choose the next connection.',
      koNextPoint: '스캔은 고개 돌리기보다 다음 행동을 정하는 정보 수집입니다.',
      enNextPoint:
          'Scanning is information gathering for the next action, not just head movement.',
    ),
    _McqSeed(
      id: 'quality_cover_shadow_press',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koStem:
          '상대 센터백을 압박하면서 뒤의 수비형 미드필더에게 들어가는 패스도 막고 싶습니다. 가장 알맞은 압박 원칙은 무엇일까요?',
      enStem:
          'You press a center back while also wanting to block the pass into the holding midfielder behind you. Which pressing principle fits best?',
      options: [
        _FootballQuizOption(
          koText: '몸의 그림자로 패스 길을 가리며 접근한다',
          enText: 'Approach while using the body shadow to block the lane',
        ),
        _FootballQuizOption(
          koText: '직선으로 접근해 속도만 높인다',
          enText: 'Approach in a straight line and rely only on speed',
        ),
        _FootballQuizOption(
          koText: '뒤 패스 길을 열어 둔 채 볼 소유자만 본다',
          enText: 'Leave the pass behind open and watch only the ball carrier',
        ),
        _FootballQuizOption(
          koText: '동료 커버가 오기 전에 먼저 발을 뻗는다',
          enText: 'Stab a foot in before teammate cover arrives',
        ),
      ],
      correctIndex: 0,
      koExplain: '커버 섀도를 쓰면 압박하는 선수 한 명이 공 소유자와 뒤 패스 길을 동시에 제한할 수 있습니다.',
      enExplain:
          'Cover shadow lets one presser restrict both the ball carrier and the pass behind them.',
      koNextPoint: '압박 문항에서는 몸 방향이 어떤 패스 길을 지우는지 보세요.',
      enNextPoint:
          'In pressing items, read which passing lane the body shape removes.',
    ),
    _McqSeed(
      id: 'quality_rest_defense_counter',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koStem:
          '우리 팀이 박스 근처까지 공격 숫자를 많이 올렸습니다. 공을 잃었을 때 역습을 줄이려면 무엇을 미리 남겨야 할까요?',
      enStem:
          'Your team has committed many players near the box. What should remain in place to reduce counterattacks if the ball is lost?',
      options: [
        _FootballQuizOption(
          koText: '중앙과 반대편을 보호하는 레스트 디펜스',
          enText: 'Rest defense protecting the center and far side',
        ),
        _FootballQuizOption(
          koText: '박스 안 침투 숫자를 끝까지 늘린다',
          enText: 'Keep adding runners into the box until the end',
        ),
        _FootballQuizOption(
          koText: '센터백 한 명만 넓은 공간에 남긴다',
          enText: 'Leave only one center back in a large space',
        ),
        _FootballQuizOption(
          koText: '가까운 선수 한 명의 즉흥 압박에만 맡긴다',
          enText: 'Rely only on one nearby player improvising pressure',
        ),
      ],
      correctIndex: 0,
      koExplain: '레스트 디펜스는 공격 중에도 역습 첫 패스와 중앙 전진을 막을 수 있도록 남겨 두는 균형입니다.',
      enExplain:
          'Rest defense is the balance left behind during attack to control the first counter pass and central progress.',
      koNextPoint: '공격 전술은 슈팅 장면과 잃었을 때의 첫 수비를 같이 봐야 합니다.',
      enNextPoint:
          'Read attacking tactics together with the first defending moment after loss.',
    ),
    _McqSeed(
      id: 'quality_second_ball_shape',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koStem: '긴 패스 경합 뒤 세컨드 볼을 자주 따내려면 주변 선수들은 어떤 준비가 좋을까요?',
      enStem:
          'After a long-ball duel, what should nearby players do to win more second balls?',
      options: [
        _FootballQuizOption(
          koText: '낙하지점 주변에 삼각형으로 미리 간격을 잡는다',
          enText: 'Set a triangle around the drop zone early',
        ),
        _FootballQuizOption(
          koText: '첫 경합자 바로 뒤에만 일렬로 선다',
          enText: 'Stand in one line only behind the first dueler',
        ),
        _FootballQuizOption(
          koText: '낙하지점에서 멀리 벌려 다음 패스만 기다린다',
          enText: 'Spread far away and wait only for the next pass',
        ),
        _FootballQuizOption(
          koText: '첫 헤더 이후 반응으로만 따라간다',
          enText: 'React only after the first header is already complete',
        ),
      ],
      correctIndex: 0,
      koExplain: '세컨드 볼은 첫 경합자보다 주변 간격과 반응 준비가 결과를 크게 좌우합니다.',
      enExplain:
          'Second balls are often decided by nearby spacing and readiness, not only by the first duel.',
      koNextPoint: '경합 문제는 첫 헤더와 다음 낙하지점 지원을 같이 보세요.',
      enNextPoint:
          'For duel questions, connect the first header with support around the next drop.',
    ),
    _McqSeed(
      id: 'quality_first_defender_delay',
      difficulty: 1,
      category: _QuizCategory.technique,
      koStem: '역습을 맞아 첫 수비수가 홀로 서 있을 때 가장 먼저 해야 할 일은 무엇일까요?',
      enStem:
          'When the first defender is alone against a counterattack, what is the first priority?',
      options: [
        _FootballQuizOption(
          koText: '상대를 지연시키며 동료 복귀 시간을 번다',
          enText: 'Delay the attacker and buy time for teammates',
        ),
        _FootballQuizOption(
          koText: '바로 발을 뻗어 한 번에 뺏으려 한다',
          enText: 'Reach in immediately and try to win it in one action',
        ),
        _FootballQuizOption(
          koText: '뒷걸음만 치며 상대 속도를 그대로 둔다',
          enText: 'Backpedal passively and let the attacker keep full speed',
        ),
        _FootballQuizOption(
          koText: '안쪽 길을 열고 바깥쪽만 막는다',
          enText: 'Open the inside lane and protect only the outside',
        ),
      ],
      correctIndex: 0,
      koExplain: '첫 수비수는 뺏기보다 상대 속도를 늦추고 방향을 제한해 팀이 정렬할 시간을 만들어야 합니다.',
      enExplain:
          'The first defender often needs to slow and guide the attacker so the team can recover shape.',
      koNextPoint: '1대1 수비는 공 탈취보다 시간과 방향 통제가 먼저일 때가 많습니다.',
      enNextPoint:
          'In 1v1 defending, time and direction control often come before winning the ball.',
    ),
    _McqSeed(
      id: 'quality_goalkeeper_buildout',
      difficulty: 2,
      category: _QuizCategory.positions,
      koStem: '빌드업에서 골키퍼가 센터백 사이 또는 옆으로 내려와 패스 옵션이 되는 장점은 무엇일까요?',
      enStem:
          'What is the advantage when a goalkeeper joins build-up between or beside center backs?',
      options: [
        _FootballQuizOption(
          koText: '후방에서 수적 우위를 만들고 압박 탈출 각도를 넓힌다',
          enText: 'Create a back-line overload and widen escape angles',
        ),
        _FootballQuizOption(
          koText: '센터백 사이 간격을 더 좁혀 압박을 모은다',
          enText: 'Narrow the center backs and invite pressure into one lane',
        ),
        _FootballQuizOption(
          koText: '롱킥 선택지만 남겨 두고 짧은 전개는 포기한다',
          enText: 'Keep only the long kick and give up short build-up',
        ),
        _FootballQuizOption(
          koText: '풀백을 모두 낮게 고정해 전진 각도를 없앤다',
          enText: 'Pin both fullbacks deep and remove forward angles',
        ),
      ],
      correctIndex: 0,
      koExplain: '골키퍼가 빌드업에 참여하면 첫 압박을 상대로 여분의 패스 선택지와 각도를 만들 수 있습니다.',
      enExplain:
          'A goalkeeper in build-up can add an extra passing option and change the angle against the first press.',
      koNextPoint: '골키퍼 역할은 선방뿐 아니라 전개 시작점까지 포함합니다.',
      enNextPoint:
          'Goalkeeper roles include the starting point of build-up, not only saves.',
    ),
    _McqSeed(
      id: 'quality_pre_match_meal',
      difficulty: 1,
      category: _QuizCategory.nutrition,
      koStem: '경기 몇 시간 전 식사로 일반적으로 더 적절한 방향은 무엇일까요?',
      enStem:
          'A few hours before a match, which meal direction is generally more suitable?',
      options: [
        _FootballQuizOption(
          koText: '소화가 쉬운 탄수화물 중심에 수분을 함께 챙긴다',
          enText: 'Easy-to-digest carbohydrates with fluids',
        ),
        _FootballQuizOption(
          koText: '소화가 느린 음식을 많이 먹고 새 메뉴를 시험한다',
          enText: 'Eat a large slow-digesting meal and test new foods',
        ),
        _FootballQuizOption(
          koText: '식사는 줄이고 카페인만으로 에너지를 맞춘다',
          enText: 'Reduce food and rely only on caffeine for energy',
        ),
        _FootballQuizOption(
          koText: '경기 직전에 섬유질과 지방을 크게 늘린다',
          enText: 'Greatly increase fiber and fat right before kickoff',
        ),
      ],
      correctIndex: 0,
      koExplain: '경기 전에는 익숙하고 소화가 쉬운 음식으로 에너지와 수분을 안정적으로 준비하는 편이 좋습니다.',
      enExplain:
          'Before a match, familiar and digestible food helps prepare energy and hydration more reliably.',
      koNextPoint: '경기 전 영양은 새로움보다 익숙함과 소화 안정성이 중요합니다.',
      enNextPoint:
          'Prematch nutrition values familiarity and digestive comfort over novelty.',
    ),
    _McqSeed(
      id: 'quality_rpe_adjustment',
      difficulty: 2,
      category: _QuizCategory.training,
      koStem: '오늘 선수의 RPE가 평소보다 훨씬 높고 움직임 질이 떨어졌습니다. 코치가 가장 먼저 고려할 조정은 무엇일까요?',
      enStem:
          'A player’s RPE is much higher than usual today and movement quality has dropped. What adjustment should the coach consider first?',
      options: [
        _FootballQuizOption(
          koText: '볼륨이나 강도를 낮추고 회복 신호를 확인한다',
          enText: 'Reduce volume or intensity and check recovery signs',
        ),
        _FootballQuizOption(
          koText: '계획표의 반복 수를 그대로 밀어붙인다',
          enText: 'Force the planned repetitions exactly as written',
        ),
        _FootballQuizOption(
          koText: '기술이 무너져도 같은 강도로 밀어붙인다',
          enText: 'Keep the same intensity even as technique breaks down',
        ),
        _FootballQuizOption(
          koText: '피로 원인을 기록하지 않고 다음 세션으로 넘긴다',
          enText:
              'Skip recording the fatigue source and move to the next session',
        ),
      ],
      correctIndex: 0,
      koExplain: 'RPE와 움직임 질은 부하 조절 신호입니다. 피로가 큰 날에는 질을 지키는 조정이 필요합니다.',
      enExplain:
          'RPE and movement quality are load-management signals. Heavy fatigue calls for adjustments that protect quality.',
      koNextPoint: '훈련 판단은 계획표와 현장 반응을 함께 읽어야 합니다.',
      enNextPoint:
          'Training decisions should read both the plan and the live response.',
    ),
    _McqSeed(
      id: 'quality_sleep_recovery',
      difficulty: 1,
      category: _QuizCategory.nutrition,
      koStem: '회복을 높이기 위한 수면 습관으로 가장 적절한 것은 무엇일까요?',
      enStem: 'Which sleep habit best supports recovery?',
      options: [
        _FootballQuizOption(
          koText: '비슷한 시간에 자고 일어나며 잠들기 전 화면 자극을 줄인다',
          enText:
              'Keep consistent sleep and wake times while reducing screens before bed',
        ),
        _FootballQuizOption(
          koText: '부족한 잠을 경기 당일 낮잠 하나로만 해결한다',
          enText: 'Try to fix poor sleep only with one match-day nap',
        ),
        _FootballQuizOption(
          koText: '취침 전 전술 영상을 길게 보며 각성을 높인다',
          enText: 'Raise arousal with long tactical video sessions before bed',
        ),
        _FootballQuizOption(
          koText: '기상 시간은 유지하지 않고 취침 전 루틴만 바꾼다',
          enText:
              'Change only the pre-bed routine without keeping wake time stable',
        ),
      ],
      correctIndex: 0,
      koExplain: '수면은 회복의 핵심 요소라 일정성과 잠들기 전 자극 관리가 다음 날 훈련 질에 영향을 줍니다.',
      enExplain:
          'Sleep is central to recovery, so consistency and lower pre-bed stimulation affect next-day training quality.',
      koNextPoint: '회복 문제는 음식뿐 아니라 수면 리듬까지 함께 보세요.',
      enNextPoint: 'Recovery questions include sleep rhythm as well as food.',
    ),
    _McqSeed(
      id: 'quality_if_then_reset',
      difficulty: 2,
      category: _QuizCategory.mindset,
      koStem: '실수 후 바로 다음 플레이로 돌아가기 위한 계획으로 가장 실전적인 것은 무엇일까요?',
      enStem:
          'Which plan is most practical for returning to the next action after a mistake?',
      options: [
        _FootballQuizOption(
          koText: '실수하면 한 번 숨을 내쉬고 다음 압박 위치를 말한다',
          enText:
              'If I make a mistake, exhale once and name my next pressing spot',
        ),
        _FootballQuizOption(
          koText: '실수하면 원인을 길게 분석한 뒤 다음 장면에 늦게 들어간다',
          enText:
              'If I make a mistake, analyze it for a long time and enter the next phase late',
        ),
        _FootballQuizOption(
          koText: '실수하면 바로 만회하려고 포지션을 벗어난다',
          enText:
              'If I make a mistake, leave position immediately to make up for it',
        ),
        _FootballQuizOption(
          koText: '실수하면 동료의 정보보다 감정 표현을 먼저 한다',
          enText:
              'If I make a mistake, express emotion before using teammate information',
        ),
      ],
      correctIndex: 0,
      koExplain: '실행 의도처럼 "만약-그러면" 계획을 정해두면 감정 대신 다음 행동으로 돌아오기 쉽습니다.',
      enExplain:
          'An if-then plan makes it easier to move from emotion back to the next action.',
      koNextPoint: '멘탈 루틴은 상황과 행동을 짧게 연결할수록 경기에서 살아남습니다.',
      enNextPoint:
          'Mental routines survive match speed when situation and action are linked briefly.',
    ),
    _McqSeed(
      id: 'quality_inverted_winger_read',
      difficulty: 2,
      category: _QuizCategory.positions,
      koStem: '오른발잡이 윙어가 왼쪽에서 안쪽으로 들어오며 슈팅 각도를 만드는 역할을 무엇으로 이해하면 좋을까요?',
      enStem:
          'How should you understand a right-footed winger on the left who cuts inside to create a shooting angle?',
      options: [
        _FootballQuizOption(
          koText: '인버티드 윙어',
          enText: 'Inverted winger',
        ),
        _FootballQuizOption(
          koText: '터치라인에 고정된 정발 윙어',
          enText: 'Strong-foot winger fixed on the touchline',
        ),
        _FootballQuizOption(
          koText: '바깥쪽만 도는 오버래핑 풀백',
          enText: 'Overlapping fullback staying only outside',
        ),
        _FootballQuizOption(
          koText: '등지고 버티는 타깃 스트라이커',
          enText: 'Back-to-goal target striker',
        ),
      ],
      correctIndex: 0,
      koExplain: '인버티드 윙어는 반대발 측면에서 안쪽으로 들어오며 슈팅, 패스, 하프스페이스 연결을 만듭니다.',
      enExplain:
          'An inverted winger starts on the opposite flank and moves inside to shoot, pass, or connect in the half-space.',
      koNextPoint: '측면 포지션은 어느 발과 어느 방향으로 들어오는지 함께 보세요.',
      enNextPoint:
          'For wide roles, connect strong foot with the direction of movement.',
    ),
    _McqSeed(
      id: 'quality_transition_foul_choice',
      difficulty: 2,
      category: _QuizCategory.rules,
      koStem: '상대 역습을 막으려고 명백히 유망한 공격을 잡아끌어 끊었습니다. 가장 관련 깊은 판정 기준은 무엇일까요?',
      enStem:
          'A player pulls an opponent to stop a promising counterattack. Which decision concept is most relevant?',
      options: [
        _FootballQuizOption(
          koText: '유망한 공격 저지와 경고 가능성',
          enText: 'Stopping a promising attack and a possible caution',
        ),
        _FootballQuizOption(
          koText: '단순 접촉이라 보고 경고 가능성을 제외한다',
          enText:
              'Treat it as simple contact and exclude any caution possibility',
        ),
        _FootballQuizOption(
          koText: '어드밴티지가 끝난 뒤에는 반칙을 아예 잊는다',
          enText: 'Forget the foul completely after advantage ends',
        ),
        _FootballQuizOption(
          koText: '공 위치만 보고 공격 가능성은 판단하지 않는다',
          enText: 'Judge only ball location and ignore attacking potential',
        ),
      ],
      correctIndex: 0,
      koExplain: '유망한 공격을 반칙으로 끊는 장면은 재개 방법뿐 아니라 경고 여부까지 함께 판단합니다.',
      enExplain:
          'A foul that stops a promising attack is judged by the restart and by whether a caution is needed.',
      koNextPoint: '규칙 문제는 반칙, 재개, 징계 가능성을 한 줄로 연결하세요.',
      enNextPoint:
          'For law items, connect foul, restart, and disciplinary outcome.',
    ),
  ];
}

List<_ShortAnswerKnowledgeSeed> _qualityScenarioShortAnswerSeeds() {
  return const <_ShortAnswerKnowledgeSeed>[
    _ShortAnswerKnowledgeSeed(
      id: 'quality_cover_shadow',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koClue: '압박하는 선수가 자기 몸 뒤쪽의 패스 길을 가리며 상대 선택지를 줄이는 개념',
      enClue:
          'Pressing concept where a player uses the space behind their body to block a passing lane',
      acceptedAnswers: [
        '커버 섀도',
        '커버쉐도',
        '커버 섀도우',
        'cover shadow',
        'covershadow',
      ],
      koExplain: '정답은 "커버 섀도"입니다. 공 소유자와 뒤 패스 길을 동시에 제한하는 압박 디테일입니다.',
      enExplain:
          'The answer is "cover shadow." It restricts the ball carrier and a passing lane behind the presser at once.',
      koNextPoint: '압박은 뛰는 방향과 몸이 가리는 길을 같이 읽어야 합니다.',
      enNextPoint:
          'Read pressing through both run direction and the lane blocked by the body.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'quality_rest_defense_term',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koClue: '공격 중에도 공을 잃었을 때 역습을 막기 위해 뒤에 남겨 두는 균형 구조',
      enClue:
          'Team balance left behind during attack to control counterattacks after losing the ball',
      acceptedAnswers: ['레스트 디펜스', 'rest defense', 'rest defence'],
      koExplain: '정답은 "레스트 디펜스"입니다. 공격 장면에서도 다음 수비를 미리 준비하는 구조입니다.',
      enExplain:
          'The answer is "rest defense." It prepares the next defensive moment while the team attacks.',
      koNextPoint: '공격 문제에서도 잃었을 때 누가 중앙과 뒤 공간을 지키는지 확인하세요.',
      enNextPoint:
          'Even in attacking questions, check who protects the center and space behind.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'quality_second_ball',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koClue: '공중볼이나 경합 뒤 곧바로 떨어지는 다음 공을 가리키는 표현',
      enClue:
          'Term for the loose ball that drops immediately after an aerial duel or contest',
      acceptedAnswers: ['세컨드 볼', 'second ball', 'secondball'],
      koExplain: '정답은 "세컨드 볼"입니다. 주변 간격과 반응 준비가 경합 이후 소유권을 좌우합니다.',
      enExplain:
          'The answer is "second ball." Nearby spacing and readiness often decide who owns it.',
      koNextPoint: '경합 상황은 첫 접촉 다음에 누가 더 빨리 준비됐는지를 보세요.',
      enNextPoint:
          'In duels, look at who is prepared for the moment after first contact.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'quality_rpe',
      difficulty: 2,
      category: _QuizCategory.training,
      koClue: '선수가 주관적으로 느끼는 운동 강도 지표. 영어 약어 세 글자로도 답할 수 있습니다',
      enClue:
          'Rating of perceived exertion. You can answer with the three-letter abbreviation',
      acceptedAnswers: ['RPE', 'rpe', '운동자각도', '자각운동강도'],
      koExplain: '정답은 "RPE"입니다. 계획된 부하와 실제 체감 피로를 비교할 때 유용한 지표입니다.',
      enExplain:
          'The answer is "RPE." It helps compare planned load with how hard the session actually felt.',
      koNextPoint: '훈련 기록은 거리나 시간뿐 아니라 체감 강도도 함께 남기면 좋습니다.',
      enNextPoint:
          'Training logs improve when perceived intensity is tracked with distance and time.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'quality_inverted_winger',
      difficulty: 2,
      category: _QuizCategory.positions,
      koClue: '주발의 반대 측면에서 안쪽으로 들어오며 슈팅과 하프스페이스 연결을 만드는 윙어 역할',
      enClue:
          'Wide role that starts on the opposite side of the strong foot and cuts inside to shoot or connect',
      acceptedAnswers: [
        '인버티드 윙어',
        'inverted winger',
        'invertedwinger',
      ],
      koExplain: '정답은 "인버티드 윙어"입니다. 측면에서 중앙으로 들어오며 직접 슈팅과 안쪽 패스 각도를 만듭니다.',
      enExplain:
          'The answer is "inverted winger." This role cuts inside to shoot or connect through inner lanes.',
      koNextPoint: '윙어 문제는 어느 발로 어느 공간에 들어오는지 함께 판단하세요.',
      enNextPoint:
          'For winger questions, connect strong foot with the space they attack.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'quality_implementation_intention',
      difficulty: 3,
      category: _QuizCategory.mindset,
      koClue: '"실수하면 숨을 한 번 내쉬고 다음 압박 위치를 말한다"처럼 상황과 행동을 미리 연결하는 계획',
      enClue:
          'If-then plan that links a situation with a specific action before it happens',
      acceptedAnswers: [
        '실행 의도',
        '실행의도',
        'implementation intention',
        'if then plan',
        'if-then plan',
      ],
      koExplain: '정답은 "실행 의도"입니다. 상황과 행동을 미리 묶으면 경기 중 감정에서 행동으로 복귀하기 쉽습니다.',
      enExplain:
          'The answer is "implementation intention." Linking situation and action beforehand makes reset behavior easier.',
      koNextPoint: '멘탈 루틴은 좋은 말보다 바로 실행할 문장으로 만들어 보세요.',
      enNextPoint:
          'Build mental routines as executable sentences, not just good ideas.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'quality_glycogen_window',
      difficulty: 2,
      category: _QuizCategory.nutrition,
      koClue: '고강도 운동 후 탄수화물 보충으로 다시 채우려는 근육과 간의 에너지 저장 형태',
      enClue:
          'Stored energy form in muscles and liver that post-training carbohydrate intake helps refill',
      acceptedAnswers: ['글리코겐', 'glycogen'],
      koExplain: '정답은 "글리코겐"입니다. 훈련 후 탄수화물은 다음 고강도 움직임을 위한 저장고를 다시 채웁니다.',
      enExplain:
          'The answer is "glycogen." Post-training carbohydrates help refill the store used for high-intensity work.',
      koNextPoint: '회복 영양은 음식 이름과 몸 안에서 채우는 저장고를 같이 보세요.',
      enNextPoint:
          'For recovery nutrition, connect the food with the body store it refills.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'quality_advantage_rule',
      difficulty: 2,
      category: _QuizCategory.rules,
      koClue: '반칙이 있어도 공격 팀 이익이 더 크면 심판이 바로 끊지 않고 이어가게 하는 규칙 운용',
      enClue:
          'Referee application that allows play to continue when the attacking benefit is greater despite a foul',
      acceptedAnswers: ['어드밴티지', 'advantage'],
      koExplain: '정답은 "어드밴티지"입니다. 단순히 반칙 여부가 아니라 끊는 것이 어느 팀에 유리한지도 봅니다.',
      enExplain:
          'The answer is "advantage." The referee considers not only the foul but also who benefits if play stops.',
      koNextPoint: '규칙 문제는 판정 이름과 경기 이익을 함께 판단하세요.',
      enNextPoint:
          'In law questions, connect the decision name with match benefit.',
    ),
  ];
}

List<_McqSeed> _deepCoreScenarioMcqSeeds() {
  return const <_McqSeed>[
    _McqSeed(
      id: 'deep_man_press_third_man',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koStem: '상대가 미드필더를 강하게 맨마킹해 직접 전진 패스가 막혔습니다. 압박을 벗기는 가장 좋은 전개 원칙은 무엇일까요?',
      enStem:
          'The opponent tightly man-marks midfield and blocks the direct forward pass. Which build-up principle best escapes the pressure?',
      options: [
        _FootballQuizOption(
          koText: '가까운 선수에게 튕긴 뒤 제3자가 전진 공간을 받는다',
          enText:
              'Bounce through a nearby player so a third player receives forward',
        ),
        _FootballQuizOption(
          koText: '등진 선수가 혼자 턴할 때까지 같은 패스를 반복한다',
          enText: 'Repeat the same pass until the marked player turns alone',
        ),
        _FootballQuizOption(
          koText: '센터백 둘이 같은 선상에서만 천천히 주고받는다',
          enText:
              'Keep the center backs flat and circulate slowly only between them',
        ),
        _FootballQuizOption(
          koText: '전방으로 긴 패스만 선택해 중원을 건너뛴다',
          enText: 'Use only long balls forward and skip midfield every time',
        ),
      ],
      correctIndex: 0,
      koExplain: '서드맨 조합은 직접 길이 막혔을 때 압박 시선을 비틀어 전진 받을 선수를 만들어 줍니다.',
      enExplain:
          'A third-man combination shifts the pressure and creates a player who can receive facing forward.',
      koNextPoint: '압박 탈출은 공 받는 선수와 다음에 열릴 선수를 함께 읽으세요.',
      enNextPoint:
          'When escaping pressure, read both the receiver and the next player who can open.',
    ),
    _McqSeed(
      id: 'deep_overload_to_isolation',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koStem: '상대가 볼 쪽으로 크게 좁혀 왔고 반대편 윙어가 넓게 남아 있습니다. 가장 날카로운 공격 연결은 무엇일까요?',
      enStem:
          'The opponent has shifted heavily to the ball side and your far winger stays wide. Which attacking link is sharpest?',
      options: [
        _FootballQuizOption(
          koText: '한쪽 오버로드로 끌어모은 뒤 반대편 1대1로 빠르게 전환한다',
          enText:
              'Use the overload to attract pressure, then switch quickly to the far-side 1v1',
        ),
        _FootballQuizOption(
          koText: '과밀 지역에서 같은 짧은 패스만 반복한다',
          enText: 'Repeat the same short passes inside the crowded zone',
        ),
        _FootballQuizOption(
          koText: '반대편 윙어도 중앙으로 들어와 밀집을 더 만든다',
          enText: 'Bring the far winger inside and make the crowd tighter',
        ),
        _FootballQuizOption(
          koText: '풀백 둘을 같은 높이로 올려 뒤 균형을 비운다',
          enText:
              'Push both fullbacks to the same height and empty the balance behind',
        ),
      ],
      correctIndex: 0,
      koExplain: '오버로드의 목적은 한쪽에 묶어 둔 수비를 반대편 아이솔레이션으로 벌리는 데 있습니다.',
      enExplain:
          'The value of an overload often appears when it creates isolation on the far side.',
      koNextPoint: '오버로드는 몰아넣는 장면과 빠져나가는 장면을 한 세트로 보세요.',
      enNextPoint:
          'Read overloads as a pair: attracting pressure and escaping it.',
    ),
    _McqSeed(
      id: 'deep_counterpress_cover_balance',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koStem: '상대 진영에서 공을 잃었습니다. 가까운 선수들이 압박할 때 뒤 선수들의 핵심 임무는 무엇일까요?',
      enStem:
          'Your team loses the ball high up the pitch. As nearby players press, what is the key job for the players behind them?',
      options: [
        _FootballQuizOption(
          koText: '탈출 패스 길과 중앙 전진 공간을 먼저 막는다',
          enText: 'Block escape passes and central forward space first',
        ),
        _FootballQuizOption(
          koText: '모두 공 주변으로 동시에 돌진한다',
          enText: 'All rush to the ball at the same time',
        ),
        _FootballQuizOption(
          koText: '압박과 무관하게 자기 자리에서 멈춘다',
          enText: 'Freeze in the original position regardless of the press',
        ),
        _FootballQuizOption(
          koText: '가장 먼 윙어만 수비 책임을 진다',
          enText: 'Leave the defending responsibility only to the far winger',
        ),
      ],
      correctIndex: 0,
      koExplain: '카운터프레스는 첫 압박과 뒤 커버가 함께 있어야 상대의 첫 전진 패스를 끊을 수 있습니다.',
      enExplain:
          'Counterpressing needs first pressure and cover behind it to stop the opponent’s first forward pass.',
      koNextPoint: '압박 성공은 뛰는 선수보다 뒤에서 지우는 길까지 같이 판단하세요.',
      enNextPoint:
          'Judge pressing success by the lanes removed behind the runner.',
    ),
    _McqSeed(
      id: 'deep_low_block_halfspace_cutback',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koStem: '상대가 낮은 블록으로 중앙을 단단히 닫았습니다. 더 좋은 공략 순서는 무엇일까요?',
      enStem:
          'The opponent sits in a low block and protects the center tightly. Which attacking sequence is stronger?',
      options: [
        _FootballQuizOption(
          koText: '폭으로 블록을 흔든 뒤 하프스페이스 침투와 컷백을 노린다',
          enText:
              'Move the block with width, then attack the half-space and cutback',
        ),
        _FootballQuizOption(
          koText: '중앙 수비 숫자가 많은 곳으로만 계속 찔러 넣는다',
          enText: 'Keep forcing passes only into the crowded central defenders',
        ),
        _FootballQuizOption(
          koText: '박스 밖 먼 거리 슈팅만 반복한다',
          enText: 'Repeat only low-quality long shots from outside the box',
        ),
        _FootballQuizOption(
          koText: '모든 공격수가 같은 선에 서서 패스 각도를 없앤다',
          enText:
              'Put every attacker on the same line and remove passing angles',
        ),
      ],
      correctIndex: 0,
      koExplain: '낮은 블록은 좌우 이동과 라인 뒤/옆 공간을 함께 흔들 때 균열이 생깁니다.',
      enExplain:
          'Low blocks crack more often when width moves them and the half-space or cutback lane is attacked.',
      koNextPoint: '낮은 블록 문제는 폭, 하프스페이스, 컷백을 함께 떠올리세요.',
      enNextPoint:
          'Against low blocks, connect width, half-space, and cutback options.',
    ),
    _McqSeed(
      id: 'deep_pressing_trap_curve_run',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koStem: '터치라인 쪽으로 압박 함정을 만들고 싶습니다. 첫 압박자의 뛰는 길로 가장 적절한 것은 무엇일까요?',
      enStem:
          'You want to set a pressing trap toward the touchline. Which path should the first presser usually take?',
      options: [
        _FootballQuizOption(
          koText: '중앙 패스 길을 가리며 곡선으로 접근한다',
          enText: 'Curve the run while blocking the central passing lane',
        ),
        _FootballQuizOption(
          koText: '중앙을 열고 볼만 향해 직선으로 달린다',
          enText: 'Run straight at the ball while opening the center',
        ),
        _FootballQuizOption(
          koText: '상대가 등진 뒤에만 천천히 따라간다',
          enText: 'Follow slowly only after the opponent turns away',
        ),
        _FootballQuizOption(
          koText: '옆 동료와 같은 길로 겹쳐 들어간다',
          enText: 'Overlap the same pressing lane as the nearby teammate',
        ),
      ],
      correctIndex: 0,
      koExplain: '곡선 압박은 중앙 탈출구를 닫고 터치라인을 추가 수비수처럼 쓰게 만듭니다.',
      enExplain:
          'A curved pressing run closes the central exit and turns the touchline into an extra defender.',
      koNextPoint: '압박 각도는 공을 향하는 선이 아니라 상대 선택지를 줄이는 선입니다.',
      enNextPoint:
          'Pressing angle is the path that removes choices, not just the line to the ball.',
    ),
    _McqSeed(
      id: 'deep_rest_defense_pivot_stagger',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koStem: '한 풀백이 높게 올라간 공격 구조에서 역습 대비를 안정시키려면 피벗과 반대 풀백은 어떻게 움직이는 편이 좋을까요?',
      enStem:
          'One fullback pushes high in attack. How should the pivot and opposite fullback usually behave to stabilize rest defense?',
      options: [
        _FootballQuizOption(
          koText: '피벗은 중앙을 지키고 반대 풀백은 안쪽으로 좁혀 균형을 잡는다',
          enText:
              'The pivot protects the center and the opposite fullback narrows inside',
        ),
        _FootballQuizOption(
          koText: '둘 다 동시에 박스 안으로 침투한다',
          enText: 'Both run into the box at the same time',
        ),
        _FootballQuizOption(
          koText: '피벗은 터치라인으로 빠지고 중앙은 비워 둔다',
          enText:
              'The pivot drifts to the touchline and leaves the center empty',
        ),
        _FootballQuizOption(
          koText: '반대 풀백도 같은 높이로 끝까지 올라간다',
          enText:
              'The opposite fullback also pushes all the way to the same height',
        ),
      ],
      correctIndex: 0,
      koExplain: '한쪽이 올라가면 반대쪽과 중앙에 균형을 남겨야 첫 역습 패스와 반대 전환을 제어할 수 있습니다.',
      enExplain:
          'When one side pushes high, far-side and central balance control the first counter pass and switch.',
      koNextPoint: '레스트 디펜스는 남는 선수 숫자보다 어느 공간을 남겨 지키는지가 핵심입니다.',
      enNextPoint:
          'Rest defense is about which spaces remain protected, not only how many players stay.',
    ),
    _McqSeed(
      id: 'deep_oriented_touch_between_lines',
      difficulty: 3,
      category: _QuizCategory.technique,
      koStem: '라인 사이에서 공을 받는 선수가 등 뒤 압박을 느낍니다. 가장 좋은 첫 터치 기준은 무엇일까요?',
      enStem:
          'A player receives between the lines with pressure arriving from behind. Which first-touch criterion is best?',
      options: [
        _FootballQuizOption(
          koText: '압박 반대 대각 공간으로 다음 행동을 열어 둔다',
          enText:
              'Take it diagonally away from pressure to open the next action',
        ),
        _FootballQuizOption(
          koText: '발밑에 세워 수비수가 붙을 시간을 준다',
          enText: 'Stop it under the feet and give the defender time to arrive',
        ),
        _FootballQuizOption(
          koText: '무조건 뒤로만 첫 터치를 둔다',
          enText: 'Always take the first touch backward only',
        ),
        _FootballQuizOption(
          koText: '몸 방향과 상관없이 강하게 멀리 친다',
          enText: 'Hit it far away regardless of body shape',
        ),
      ],
      correctIndex: 0,
      koExplain: '오리엔티드 터치는 공을 받는 순간 다음 패스, 턴, 운반 각도를 동시에 준비합니다.',
      enExplain:
          'An oriented touch prepares the next pass, turn, or carry at the receiving moment.',
      koNextPoint: '첫 터치는 멈춤보다 다음 행동을 만드는 방향으로 평가하세요.',
      enNextPoint: 'Evaluate the first touch by the next action it creates.',
    ),
    _McqSeed(
      id: 'deep_scan_sequence',
      difficulty: 2,
      category: _QuizCategory.technique,
      koStem: '스캔을 한 번만 하는 선수보다 더 안정적인 습관은 무엇일까요?',
      enStem:
          'What habit is more stable than scanning only once before receiving?',
      options: [
        _FootballQuizOption(
          koText: '공 이동 중, 패스 직전, 터치 직전에 정보를 나눠 확인한다',
          enText:
              'Check information across ball travel, just before the pass, and before touch',
        ),
        _FootballQuizOption(
          koText: '고개를 오래 돌린 뒤 공은 보지 않는다',
          enText: 'Turn the head for a long time and stop seeing the ball',
        ),
        _FootballQuizOption(
          koText: '공을 받은 뒤에만 주변을 확인한다',
          enText: 'Check the surroundings only after receiving',
        ),
        _FootballQuizOption(
          koText: '가까운 수비수 한 명만 보고 결정한다',
          enText: 'Look only at one nearby defender before deciding',
        ),
      ],
      correctIndex: 0,
      koExplain: '좋은 스캔은 한 번의 고개 돌림이 아니라 시간대별 정보 업데이트에 가깝습니다.',
      enExplain:
          'Good scanning is closer to repeated information updates than a single head turn.',
      koNextPoint: '스캔은 타이밍별로 무엇이 바뀌는지 확인하는 습관입니다.',
      enNextPoint:
          'Scanning is the habit of checking what changes across timing windows.',
    ),
    _McqSeed(
      id: 'deep_shield_release',
      difficulty: 2,
      category: _QuizCategory.technique,
      koStem: '등진 상태에서 압박을 버틴 뒤 가장 좋은 다음 선택은 무엇일까요?',
      enStem:
          'After holding off pressure with your back to play, what is usually the best next choice?',
      options: [
        _FootballQuizOption(
          koText: '먼 발로 보호하며 가까운 지원각이나 턴 공간으로 연결한다',
          enText:
              'Shield with the far foot and connect to support or turning space',
        ),
        _FootballQuizOption(
          koText: '압박이 붙을수록 공을 몸 앞쪽에 노출한다',
          enText: 'Expose the ball in front of the body as pressure arrives',
        ),
        _FootballQuizOption(
          koText: '지원 선수를 보지 않고 혼자 힘으로만 돌아선다',
          enText: 'Turn alone without checking supporting players',
        ),
        _FootballQuizOption(
          koText: '공을 멈춘 뒤 접촉을 기다린다',
          enText: 'Stop the ball and wait for contact',
        ),
      ],
      correctIndex: 0,
      koExplain: '볼 보호는 버티는 기술에서 끝나지 않고 다음 연결이나 턴으로 이어져야 가치가 큽니다.',
      enExplain:
          'Shielding has more value when it leads into a connection or turn, not just survival.',
      koNextPoint: '보호, 스캔, 연결을 하나의 기술 세트로 보세요.',
      enNextPoint:
          'Treat shielding, scanning, and release as one technical set.',
    ),
    _McqSeed(
      id: 'deep_disguised_pass_timing',
      difficulty: 3,
      category: _QuizCategory.technique,
      koStem: '수비 라인이 패스 방향을 읽고 먼저 움직입니다. 디스가이즈 패스가 효과적인 이유는 무엇일까요?',
      enStem:
          'The defensive line starts reading the pass direction early. Why can a disguised pass be effective?',
      options: [
        _FootballQuizOption(
          koText: '몸과 시선으로 한 길을 보여주고 실제로는 다른 길을 열기 때문',
          enText:
              'It shows one lane with body and eyes while opening another lane',
        ),
        _FootballQuizOption(
          koText: '공 속도를 항상 낮추기 때문',
          enText: 'It always lowers the ball speed',
        ),
        _FootballQuizOption(
          koText: '패스 전 스캔을 하지 않아도 되기 때문',
          enText: 'It removes the need to scan before passing',
        ),
        _FootballQuizOption(
          koText: '수비수가 가까울수록 무조건 성공하기 때문',
          enText: 'It succeeds automatically when defenders are close',
        ),
      ],
      correctIndex: 0,
      koExplain: '위장 동작은 수비의 예측 타이밍을 흔들어 실제 패스 길을 늦게 보이게 만듭니다.',
      enExplain:
          'Disguise disrupts defensive anticipation and hides the real passing lane until later.',
      koNextPoint: '패스 기술은 발뿐 아니라 시선, 골반, 타이밍까지 포함합니다.',
      enNextPoint:
          'Passing technique includes eyes, hips, and timing, not only foot contact.',
    ),
    _McqSeed(
      id: 'deep_defensive_jockey_angle',
      difficulty: 2,
      category: _QuizCategory.technique,
      koStem: '빠른 윙어를 측면에서 막을 때 자키 수비의 핵심은 무엇일까요?',
      enStem:
          'When defending a fast winger wide, what is the key of jockeying?',
      options: [
        _FootballQuizOption(
          koText: '속도를 조절하며 안쪽 길을 닫고 원하는 방향으로 유도한다',
          enText:
              'Control speed, close the inside lane, and guide the attacker',
        ),
        _FootballQuizOption(
          koText: '첫 동작에 무조건 발을 던진다',
          enText: 'Throw a foot at the first movement every time',
        ),
        _FootballQuizOption(
          koText: '상체를 세우고 뒤로만 물러난다',
          enText: 'Stay upright and only keep retreating',
        ),
        _FootballQuizOption(
          koText: '공을 보지 않고 상대 발만 끝까지 따라간다',
          enText: 'Ignore the ball and follow only the opponent’s feet',
        ),
      ],
      correctIndex: 0,
      koExplain: '자키는 탈취보다 지연, 각도, 유도 방향을 관리하는 1대1 수비 기술입니다.',
      enExplain:
          'Jockeying manages delay, angle, and guiding direction before trying to win the ball.',
      koNextPoint: '수비 기술은 뺏는 순간보다 선택지를 줄이는 과정으로 보세요.',
      enNextPoint:
          'See defending as reducing options before the winning moment.',
    ),
    _McqSeed(
      id: 'deep_finish_cutback_read',
      difficulty: 2,
      category: _QuizCategory.technique,
      koStem: '박스 안 컷백을 받을 때 슈팅 질을 높이는 준비는 무엇일까요?',
      enStem:
          'When receiving a cutback in the box, what preparation improves shot quality?',
      options: [
        _FootballQuizOption(
          koText: '수비와 골키퍼 위치를 먼저 확인하고 몸을 열어 마무리 각도를 만든다',
          enText:
              'Check defenders and goalkeeper first, then open the body for the finish',
        ),
        _FootballQuizOption(
          koText: '공이 올 때까지 골대 반대편을 전혀 보지 않는다',
          enText: 'Avoid looking across goal until the ball arrives',
        ),
        _FootballQuizOption(
          koText: '첫 터치를 항상 뒤로 빼서 슈팅 시간을 늘린다',
          enText: 'Always take the first touch backward to add time',
        ),
        _FootballQuizOption(
          koText: '힘만 우선하고 발 표면 선택은 나중에 생각한다',
          enText: 'Prioritize power and think about contact surface later',
        ),
      ],
      correctIndex: 0,
      koExplain: '컷백 마무리는 공이 오기 전 정보 확인과 몸 방향이 슈팅 선택지를 결정합니다.',
      enExplain:
          'Cutback finishing depends on pre-scan and body shape before the ball arrives.',
      koNextPoint: '마무리는 공을 차는 순간보다 받기 전 준비가 먼저입니다.',
      enNextPoint: 'Finishing begins with preparation before the strike.',
    ),
    _McqSeed(
      id: 'deep_pressure_action_cue',
      difficulty: 2,
      category: _QuizCategory.mindset,
      koStem: '중요한 경기에서 긴장이 올라올 때 가장 쓸모 있는 자기 대화는 무엇일까요?',
      enStem:
          'In an important match, which self-talk is most useful when tension rises?',
      options: [
        _FootballQuizOption(
          koText: '결과보다 "첫 압박 각도", "받기 전 스캔" 같은 행동 단서',
          enText:
              'Action cues such as “pressing angle” or “scan before receiving”',
        ),
        _FootballQuizOption(
          koText: '반드시 이겨야 한다는 결과 문장만 반복',
          enText: 'Repeating only that you must win',
        ),
        _FootballQuizOption(
          koText: '실수하지 말라는 금지 문장을 계속 반복',
          enText: 'Repeating only “do not make mistakes”',
        ),
        _FootballQuizOption(
          koText: '관중 반응을 기준으로 자신감을 판단',
          enText: 'Judging confidence by crowd reaction',
        ),
      ],
      correctIndex: 0,
      koExplain: '압박 상황에서는 결과 언어보다 바로 실행할 행동 단서가 주의를 현재 장면으로 돌립니다.',
      enExplain:
          'Under pressure, action cues return attention to the current play better than result language.',
      koNextPoint: '마인드 문항은 감정을 없애는 답보다 행동으로 연결되는 답을 고르세요.',
      enNextPoint:
          'For mindset items, choose the answer that links emotion back to action.',
    ),
    _McqSeed(
      id: 'deep_after_miss_reset_sequence',
      difficulty: 2,
      category: _QuizCategory.mindset,
      koStem: '결정적 찬스를 놓친 직후 다음 수비 전환에 늦지 않으려면 어떤 순서가 좋을까요?',
      enStem:
          'Right after missing a big chance, what sequence helps avoid being late to defensive transition?',
      options: [
        _FootballQuizOption(
          koText: '짧게 숨을 정리하고 주변 정보를 확인한 뒤 다음 역할로 복귀한다',
          enText:
              'Reset breath, check information, then return to the next role',
        ),
        _FootballQuizOption(
          koText: '장면을 오래 분석하며 수비 전환을 늦춘다',
          enText: 'Analyze the miss for a long time and delay transition',
        ),
        _FootballQuizOption(
          koText: '무조건 만회하려고 포지션 밖으로 압박한다',
          enText: 'Press out of position immediately to make up for it',
        ),
        _FootballQuizOption(
          koText: '동료에게 먼저 감정을 표현한 뒤 경기로 돌아온다',
          enText: 'Express emotion to teammates first, then return to play',
        ),
      ],
      correctIndex: 0,
      koExplain: '리셋 루틴은 감정을 무시하는 것이 아니라 다음 장면에 늦지 않도록 순서를 짧게 정하는 기술입니다.',
      enExplain:
          'A reset routine is a short sequence that keeps the player on time for the next phase.',
      koNextPoint: '실수 후 루틴은 호흡, 정보, 다음 역할로 짧게 설계하세요.',
      enNextPoint:
          'After mistakes, build a short breath, information, next-role routine.',
    ),
    _McqSeed(
      id: 'deep_confidence_evidence_log',
      difficulty: 2,
      category: _QuizCategory.mindset,
      koStem: '최근 경기력이 흔들린 선수에게 가장 현실적인 자신감 회복 방식은 무엇일까요?',
      enStem:
          'For a player whose form has dipped recently, which confidence strategy is most realistic?',
      options: [
        _FootballQuizOption(
          koText: '성공했던 행동 증거를 짧게 기록하고 다음 경기 행동 목표로 바꾼다',
          enText:
              'Record evidence of successful actions and turn it into next-match action goals',
        ),
        _FootballQuizOption(
          koText: '좋은 결과만 상상하고 훈련 기준은 바꾸지 않는다',
          enText:
              'Visualize only good outcomes and leave training standards unchanged',
        ),
        _FootballQuizOption(
          koText: '실수 영상을 길게 반복해 불안을 더 세밀하게 만든다',
          enText:
              'Replay mistake clips repeatedly until anxiety becomes more detailed',
        ),
        _FootballQuizOption(
          koText: '한 번의 골이나 도움만 기다린다',
          enText: 'Wait only for one goal or assist to restore confidence',
        ),
      ],
      correctIndex: 0,
      koExplain: '자신감은 막연한 긍정보다 내가 반복할 수 있는 행동 증거를 쌓을 때 안정됩니다.',
      enExplain:
          'Confidence becomes sturdier when it is built from repeatable action evidence.',
      koNextPoint: '마인드는 결과 기대보다 반복 가능한 행동 증거로 관리하세요.',
      enNextPoint:
          'Manage confidence through repeatable action evidence, not only outcome hope.',
    ),
    _McqSeed(
      id: 'deep_substitute_first_actions',
      difficulty: 2,
      category: _QuizCategory.mindset,
      koStem: '교체 투입을 앞둔 선수가 경기 속도에 빨리 들어가기 위해 준비하면 좋은 것은 무엇일까요?',
      enStem: 'What should a substitute prepare to enter match speed quickly?',
      options: [
        _FootballQuizOption(
          koText: '첫 3가지 행동 역할을 구체적으로 정한다',
          enText: 'Set the first three action roles clearly',
        ),
        _FootballQuizOption(
          koText: '투입 직후 결과만 상상하고 위치 정보는 보지 않는다',
          enText: 'Imagine only the result and ignore positional information',
        ),
        _FootballQuizOption(
          koText: '감정이 올라올 때까지 워밍업 강도를 늦춘다',
          enText: 'Keep warm-up low until emotion rises',
        ),
        _FootballQuizOption(
          koText: '상대 구조보다 내 첫 터치 장면만 기다린다',
          enText:
              'Wait only for the first touch instead of reading the opponent shape',
        ),
      ],
      correctIndex: 0,
      koExplain: '교체 선수는 첫 압박 위치, 첫 지원각, 첫 수비 복귀처럼 바로 실행할 기준이 있으면 적응이 빨라집니다.',
      enExplain:
          'A substitute adapts faster with immediate cues such as first press, first support angle, and first recovery run.',
      koNextPoint: '교체 준비는 감정이 아니라 첫 행동 기준을 정하는 일입니다.',
      enNextPoint:
          'Substitution readiness is about first-action standards, not just emotion.',
    ),
    _McqSeed(
      id: 'deep_referee_attention_control',
      difficulty: 2,
      category: _QuizCategory.mindset,
      koStem: '판정에 아쉬움이 남은 직후 경기력을 지키는 가장 좋은 주의 전환은 무엇일까요?',
      enStem:
          'Right after a frustrating decision, which attention shift best protects performance?',
      options: [
        _FootballQuizOption(
          koText: '판정 해석보다 다음 위치, 마크, 패스 길처럼 통제 가능한 정보로 옮긴다',
          enText:
              'Move from judging the call to controllable information such as position, mark, and passing lane',
        ),
        _FootballQuizOption(
          koText: '다음 플레이가 시작돼도 판정 이유를 계속 따진다',
          enText: 'Keep arguing the reason even after the next play begins',
        ),
        _FootballQuizOption(
          koText: '감정이 가라앉을 때까지 첫 압박을 멈춘다',
          enText: 'Stop the first press until emotion settles',
        ),
        _FootballQuizOption(
          koText: '동료에게도 같은 불만을 길게 공유한다',
          enText: 'Share the same complaint with teammates at length',
        ),
      ],
      correctIndex: 0,
      koExplain: '통제 불가능한 판정에서 통제 가능한 다음 정보로 주의를 옮기는 것이 실전 멘탈의 핵심입니다.',
      enExplain:
          'A key mindset skill is shifting from uncontrollable calls to controllable next information.',
      koNextPoint: '통제 가능/불가능을 빠르게 나누는 습관을 들이세요.',
      enNextPoint:
          'Build the habit of separating controllable and uncontrollable information quickly.',
    ),
  ];
}

List<_ShortAnswerKnowledgeSeed> _deepCoreScenarioShortAnswerSeeds() {
  return const <_ShortAnswerKnowledgeSeed>[
    _ShortAnswerKnowledgeSeed(
      id: 'deep_oriented_touch',
      difficulty: 3,
      category: _QuizCategory.technique,
      koClue: '공을 멈추는 대신 다음 플레이 방향으로 잡아 두는 목적 있는 첫 터치',
      enClue:
          'Purposeful first touch that sets the ball toward the next action instead of simply stopping it',
      acceptedAnswers: [
        '오리엔티드 터치',
        '방향성 터치',
        'oriented touch',
        'directional first touch',
      ],
      koExplain: '정답은 "오리엔티드 터치"입니다. 받는 순간 다음 패스, 턴, 운반 각도를 동시에 만듭니다.',
      enExplain:
          'The answer is "oriented touch." It prepares the next pass, turn, or carry at the receiving moment.',
      koNextPoint: '첫 터치는 정지보다 다음 행동을 여는 방향으로 보세요.',
      enNextPoint:
          'View first touch by how it opens the next action, not only by control.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'deep_disguised_pass',
      difficulty: 3,
      category: _QuizCategory.technique,
      koClue: '몸과 시선으로 한 방향을 보여준 뒤 다른 패스 길을 쓰는 기술',
      enClue:
          'Passing skill that shows one direction with body and eyes before using another lane',
      acceptedAnswers: [
        '디스가이즈 패스',
        '위장 패스',
        'disguised pass',
        'disguise pass',
      ],
      koExplain: '정답은 "디스가이즈 패스"입니다. 수비의 예측 타이밍을 흔들어 실제 패스 길을 늦게 보이게 합니다.',
      enExplain:
          'The answer is "disguised pass." It delays the defender’s read of the real passing lane.',
      koNextPoint: '패스는 발 표면뿐 아니라 시선과 골반 방향도 함께 봅니다.',
      enNextPoint:
          'Passing includes eyes and hip direction, not just foot contact.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'deep_decoy_run',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koClue: '직접 공을 받지 않더라도 수비를 끌어내 동료 공간을 만드는 움직임',
      enClue:
          'Run that may not receive the ball but drags a defender away to create space for a teammate',
      acceptedAnswers: [
        '디코이 런',
        '미끼 움직임',
        'decoy run',
        'decoy movement',
      ],
      koExplain: '정답은 "디코이 런"입니다. 공 없는 움직임도 수비 선택을 바꾸며 공간을 만듭니다.',
      enExplain:
          'The answer is "decoy run." Off-ball movement can change defenders’ choices and open space.',
      koNextPoint: '공 없는 움직임이 누구의 공간을 여는지 함께 보세요.',
      enNextPoint: 'Check whose space is opened by the off-ball run.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'deep_counter_movement',
      difficulty: 2,
      category: _QuizCategory.technique,
      koClue: '수비의 중심을 한쪽으로 흔든 뒤 반대 방향으로 빠져나가는 움직임',
      enClue:
          'Movement that shifts a defender’s balance one way before escaping the other way',
      acceptedAnswers: [
        '역동작',
        '역동작 움직임',
        'counter movement',
        'countermovement',
      ],
      koExplain: '정답은 "역동작"입니다. 방향 전환은 수비의 중심 이동을 먼저 만들 때 더 날카로워집니다.',
      enExplain:
          'The answer is "counter movement." Changes of direction are sharper when they first move the defender’s balance.',
      koNextPoint: '드리블과 탈압박은 공 터치와 수비 중심을 함께 보세요.',
      enNextPoint:
          'For dribbling and escape, read both ball contact and defender balance.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'deep_overload',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koClue: '한 구역에 의도적으로 숫자를 더 만들어 패스 선택지와 압박 탈출 가능성을 높이는 전술 개념',
      enClue:
          'Tactical concept of adding numbers in one zone to create passing options and escape pressure',
      acceptedAnswers: ['오버로드', '수적 우위', 'overload'],
      koExplain: '정답은 "오버로드"입니다. 한쪽에 수비를 끌어 모은 뒤 반대편을 열기 위한 준비가 될 수 있습니다.',
      enExplain:
          'The answer is "overload." It can attract defenders on one side before opening the other side.',
      koNextPoint: '오버로드는 어디로 빠져나갈지까지 같이 설계해야 합니다.',
      enNextPoint:
          'An overload needs the escape route planned together with the crowding.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'deep_isolation',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koClue: '강한 드리블러나 윙어를 넓은 공간의 1대1 상황에 남겨 두는 공격 설계',
      enClue:
          'Attacking design that leaves a strong dribbler or winger in a wide 1v1 space',
      acceptedAnswers: [
        '아이솔레이션',
        '고립',
        '1대1 고립',
        'isolation',
        '1v1 isolation',
      ],
      koExplain: '정답은 "아이솔레이션"입니다. 오버로드와 전환 뒤 반대편에서 자주 노리는 장면입니다.',
      enExplain:
          'The answer is "isolation." It often appears on the far side after overload and switch.',
      koNextPoint: '아이솔레이션은 누가 1대1 우위를 갖는지까지 함께 판단하세요.',
      enNextPoint: 'For isolation, identify who has the 1v1 advantage.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'deep_jockey',
      difficulty: 2,
      category: _QuizCategory.technique,
      koClue: '1대1 수비에서 바로 발을 뻗기보다 속도와 각도를 조절하며 상대를 유도하는 기술',
      enClue:
          '1v1 defending skill of controlling speed and angle instead of stabbing for the ball immediately',
      acceptedAnswers: ['자키', '자키 수비', 'jockey', 'jockeying'],
      koExplain: '정답은 "자키"입니다. 지연과 유도 방향을 관리해 상대 선택지를 줄입니다.',
      enExplain:
          'The answer is "jockeying." It manages delay and guiding direction to reduce options.',
      koNextPoint: '수비 기술은 탈취보다 선택지 제한부터 보세요.',
      enNextPoint:
          'For defending skill, read option control before the tackle.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'deep_action_cue',
      difficulty: 2,
      category: _QuizCategory.mindset,
      koClue: '"첫 압박 각도", "받기 전 스캔"처럼 긴장 상황에서 바로 실행할 짧은 행동 문장',
      enClue:
          'Short action phrase used under pressure, such as “pressing angle” or “scan before receiving”',
      acceptedAnswers: ['행동 단서', '액션 큐', 'action cue', 'cue'],
      koExplain: '정답은 "행동 단서"입니다. 결과 생각을 줄이고 지금 할 일로 주의를 돌립니다.',
      enExplain:
          'The answer is "action cue." It shifts attention from outcomes to the task right now.',
      koNextPoint: '마인드 루틴은 바로 실행할 수 있는 짧은 단서로 만드세요.',
      enNextPoint:
          'Build mindset routines from short cues that can be executed immediately.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'deep_process_goal',
      difficulty: 2,
      category: _QuizCategory.mindset,
      koClue: '골 수나 승패보다 스캔, 압박, 복귀처럼 내가 직접 실행할 행동에 둔 목표',
      enClue:
          'Goal focused on controllable actions such as scanning, pressing, or recovery runs instead of score or result',
      acceptedAnswers: [
        '과정 목표',
        '프로세스 목표',
        'process goal',
        'process goals',
      ],
      koExplain: '정답은 "과정 목표"입니다. 압박이 큰 경기에서 통제 가능한 행동을 붙잡게 해 줍니다.',
      enExplain:
          'The answer is "process goal." It anchors attention to controllable action under pressure.',
      koNextPoint: '결과 목표를 경기 중 행동 목표로 번역해 보세요.',
      enNextPoint: 'Translate outcome goals into match-action goals.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'deep_self_talk',
      difficulty: 2,
      category: _QuizCategory.mindset,
      koClue: '경기 중 자신에게 짧게 말해 주의를 정리하고 다음 행동을 연결하는 심리 기술',
      enClue:
          'Mental skill of using short phrases to organize attention and link to the next action during play',
      acceptedAnswers: ['셀프토크', '자기 대화', 'self-talk', 'self talk'],
      koExplain: '정답은 "셀프토크"입니다. 좋은 자기 대화는 감정 설명이 아니라 다음 행동 단서로 작동합니다.',
      enExplain:
          'The answer is "self-talk." Good self-talk works as an action cue, not just emotion description.',
      koNextPoint: '셀프토크는 짧고 구체적인 행동 언어로 만드세요.',
      enNextPoint: 'Make self-talk short, specific, and action based.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'deep_preperformance_routine',
      difficulty: 2,
      category: _QuizCategory.mindset,
      koClue: '킥오프, 페널티킥, 교체 투입 전처럼 수행 직전에 반복하는 짧은 준비 절차',
      enClue:
          'Short preparation sequence repeated right before performance moments such as kickoff, penalties, or substitutions',
      acceptedAnswers: [
        '프리퍼포먼스 루틴',
        '수행 전 루틴',
        'pre-performance routine',
        'preperformance routine',
      ],
      koExplain: '정답은 "프리퍼포먼스 루틴"입니다. 몸, 시선, 첫 행동을 일정하게 연결합니다.',
      enExplain:
          'The answer is "pre-performance routine." It links body, gaze, and first action consistently.',
      koNextPoint: '루틴은 길고 멋진 절차보다 경기 속도에서 반복 가능한지가 중요합니다.',
      enNextPoint:
          'A routine matters because it is repeatable at match speed, not because it is elaborate.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'deep_trigger_word',
      difficulty: 2,
      category: _QuizCategory.mindset,
      koClue: '"스캔", "각도", "복귀"처럼 복잡한 생각을 하나의 행동으로 압축하는 짧은 단어',
      enClue:
          'Short word such as “scan,” “angle,” or “recover” that compresses complex thought into one action',
      acceptedAnswers: [
        '트리거 워드',
        '큐 워드',
        'trigger word',
        'cue word',
      ],
      koExplain: '정답은 "트리거 워드"입니다. 압박 상황에서 생각을 줄이고 행동 전환을 빠르게 합니다.',
      enExplain:
          'The answer is "trigger word." It reduces thinking load and speeds up action under pressure.',
      koNextPoint: '긴 설명은 훈련 때, 경기 중에는 짧은 단어로 압축하세요.',
      enNextPoint:
          'Use longer explanations in training and short words during matches.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'deep_pressing_trigger',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koClue: '상대의 큰 터치, 뒤돌아선 몸 방향, 느린 패스처럼 팀이 압박을 시작하기로 정한 신호',
      enClue:
          'Cue such as a heavy touch, closed body shape, or slow pass that tells a team to start pressing',
      acceptedAnswers: [
        '압박 트리거',
        '프레싱 트리거',
        'pressing trigger',
        'press trigger',
      ],
      koExplain: '정답은 "압박 트리거"입니다. 좋은 압박은 감정이 아니라 공유된 신호에서 시작됩니다.',
      enExplain:
          'The answer is "pressing trigger." Good pressing starts from shared cues, not emotion.',
      koNextPoint: '압박은 언제 들어갈지 정한 신호와 함께 익히세요.',
      enNextPoint: 'Learn pressing together with the cues that start it.',
    ),
  ];
}

List<_McqSeed> _issue271CoreCategoryMcqSeeds() {
  return const <_McqSeed>[
    _McqSeed(
      id: 'issue271_third_man_escape_press',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koStem: '중앙으로 바로 찔러 넣는 패스 길이 막혔을 때 압박을 가장 깔끔하게 벗기는 전개는 무엇일까요?',
      enStem:
          'When the direct central passing lane is blocked, which pattern most cleanly escapes the press?',
      options: [
        _FootballQuizOption(
          koText: '볼 가진 선수가 무리하게 전진 드리블한다',
          enText: 'The ball carrier forces a forward dribble',
        ),
        _FootballQuizOption(
          koText: '서드맨 조합으로 벽패스를 거쳐 전진한다',
          enText: 'Use a third-man combination to bounce and play forward',
        ),
        _FootballQuizOption(
          koText: '모든 선수가 볼 쪽으로 더 붙는다',
          enText: 'Everyone crowds even closer to the ball',
        ),
        _FootballQuizOption(
          koText: '일단 터치라인 밖으로 차낸다',
          enText: 'Kick it out of bounds immediately',
        ),
      ],
      correctIndex: 1,
      koExplain: '직접 패스가 끊길 때는 서드맨을 활용해 압박의 시선을 한 번 비틀고 전진하는 것이 효과적입니다.',
      enExplain:
          'When the direct lane is shut, a third-man pattern shifts the defenders’ attention and opens the forward route.',
      koNextPoint: '전술은 받는 선수뿐 아니라 세 번째 선수의 움직임까지 함께 보세요.',
      enNextPoint:
          'In tactics, read not only the receiver but also the third player’s run.',
    ),
    _McqSeed(
      id: 'issue271_rest_defense_balance',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koStem: '한쪽 풀백이 높게 올라가 공격 숫자를 늘릴 때 가장 안정적인 레스트 디펜스 구조는 무엇일까요?',
      enStem:
          'When one full back pushes high to support the attack, which rest-defense structure is most stable?',
      options: [
        _FootballQuizOption(
          koText: '반대 풀백과 미드필더가 안쪽을 보호한다',
          enText: 'The opposite full back and a midfielder protect the inside',
        ),
        _FootballQuizOption(
          koText: '양쪽 풀백이 동시에 끝까지 올라간다',
          enText: 'Both full backs push to the last line together',
        ),
        _FootballQuizOption(
          koText: '센터백 한 명만 중앙에 남긴다',
          enText: 'Leave only one center back in the middle',
        ),
        _FootballQuizOption(
          koText: '공격수까지 모두 박스 안으로 들어간다',
          enText: 'Send even the forwards into the box',
        ),
      ],
      correctIndex: 0,
      koExplain: '공격 숫자를 늘리더라도 반대쪽과 중앙 보호를 남겨야 역습 첫 장면을 제어할 수 있습니다.',
      enExplain:
          'Even while committing numbers forward, you still need the far side and central cover to control the first counterattack moment.',
      koNextPoint: '공격 전술은 잃었을 때 어디가 비는지도 함께 설계해야 합니다.',
      enNextPoint:
          'When building attacks, also plan what remains protected after the ball is lost.',
    ),
    _McqSeed(
      id: 'issue271_pressing_trap_touchline',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koStem: '상대 빌드업을 터치라인 쪽으로 몰아 압박 함정을 만들 때 가장 중요한 원칙은 무엇일까요?',
      enStem:
          'What is the most important principle when building a pressing trap toward the touchline?',
      options: [
        _FootballQuizOption(
          koText: '중앙 탈출 패스를 먼저 막는다',
          enText: 'Block the central escape pass first',
        ),
        _FootballQuizOption(
          koText: '무조건 태클부터 들어간다',
          enText: 'Dive into a tackle immediately',
        ),
        _FootballQuizOption(
          koText: '마크를 모두 버리고 골문으로 뛴다',
          enText: 'Abandon every mark and sprint to goal',
        ),
        _FootballQuizOption(
          koText: '압박 각도 없이 직선으로만 달려든다',
          enText: 'Press only in a straight line without angle',
        ),
      ],
      correctIndex: 0,
      koExplain: '터치라인은 자연스러운 경계이지만, 중앙 탈출 길을 남기면 함정이 아니라 초대장이 됩니다.',
      enExplain:
          'The touchline is useful only if the central escape route is closed. Leave that lane open and the trap disappears.',
      koNextPoint: '압박은 속도보다 각도와 팀 간격이 먼저입니다.',
      enNextPoint:
          'In pressing, angle and team spacing matter before pure speed.',
    ),
    _McqSeed(
      id: 'issue271_low_block_far_side',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koStem: '상대가 깊게 내려선 수비를 할 때 공간을 여는 데 가장 좋은 접근은 무엇일까요?',
      enStem:
          'Against a deep block, which approach most often helps open space?',
      options: [
        _FootballQuizOption(
          koText: '한쪽으로 끌어낸 뒤 반대편을 빠르게 공략한다',
          enText:
              'Pull the block to one side, then attack the far side quickly',
        ),
        _FootballQuizOption(
          koText: '중앙에만 서서 짧은 패스만 반복한다',
          enText: 'Stay only in the center and repeat short passes',
        ),
        _FootballQuizOption(
          koText: '모든 선수가 공 앞으로만 달려간다',
          enText: 'Have every player run only ahead of the ball',
        ),
        _FootballQuizOption(
          koText: '슈팅 각도 없이 먼 거리에서만 찬다',
          enText: 'Shoot only from poor long-range angles',
        ),
      ],
      correctIndex: 0,
      koExplain: '내려선 블록은 좌우 이동에 부담을 느끼므로, 한쪽으로 흔든 뒤 반대편을 빠르게 쓰는 전개가 유효합니다.',
      enExplain:
          'Deep blocks dislike long side-to-side shifts, so moving them first and then hitting the far side is often effective.',
      koNextPoint: '공간이 없을수록 폭과 타이밍 변화의 가치가 커집니다.',
      enNextPoint:
          'The tighter the space, the more value width and timing changes bring.',
    ),
    _McqSeed(
      id: 'issue271_half_turn_receive',
      difficulty: 2,
      category: _QuizCategory.technique,
      koStem: '중앙 미드필더가 등 뒤 압박을 느끼며 패스를 받을 때 다음 플레이를 가장 살리기 좋은 몸 방향은 무엇일까요?',
      enStem:
          'Which body shape best preserves the next action when a central midfielder receives with pressure from behind?',
      options: [
        _FootballQuizOption(
          koText: '하프턴으로 양쪽 시야를 열어둔다',
          enText: 'Receive on a half-turn with both sides in view',
        ),
        _FootballQuizOption(
          koText: '등을 완전히 돌려 골문을 등진다',
          enText: 'Turn fully and face away from the play',
        ),
        _FootballQuizOption(
          koText: '두 발을 평평하게 두고 멈춘다',
          enText: 'Plant both feet flat and stop still',
        ),
        _FootballQuizOption(
          koText: '무조건 원터치 백패스만 한다',
          enText: 'Always play a one-touch back pass',
        ),
      ],
      correctIndex: 0,
      koExplain: '하프턴은 압박을 느끼면서도 앞뒤 선택지를 모두 남겨 주어 다음 결정의 폭을 넓혀줍니다.',
      enExplain:
          'The half-turn keeps pressure in view while preserving both forward and backward options for the next decision.',
      koNextPoint: '기술은 발동작만이 아니라 몸 방향과 시야 준비까지 포함합니다.',
      enNextPoint:
          'Technique includes body shape and visual preparation, not just foot contact.',
    ),
    _McqSeed(
      id: 'issue271_cushion_touch',
      difficulty: 2,
      category: _QuizCategory.technique,
      koStem: '강한 패스가 발밑으로 들어올 때 볼을 안정적으로 다루는 첫 터치 원칙은 무엇일까요?',
      enStem:
          'When a firm pass arrives into your feet, what is the key first-touch principle for control?',
      options: [
        _FootballQuizOption(
          koText: '공의 힘을 흡수해 다음 공간으로 눌러 놓는다',
          enText: 'Absorb the pace and cushion it into the next space',
        ),
        _FootballQuizOption(
          koText: '같은 힘으로 더 세게 튕겨낸다',
          enText: 'Bounce it back harder with the same force',
        ),
        _FootballQuizOption(
          koText: '눈을 감고 감각만 믿는다',
          enText: 'Close the eyes and trust only feel',
        ),
        _FootballQuizOption(
          koText: '무조건 발바닥으로 밟아 멈춘다',
          enText: 'Always stop it dead under the sole',
        ),
      ],
      correctIndex: 0,
      koExplain: '좋은 퍼스트 터치는 단순히 멈추는 것이 아니라 공의 속도를 죽이며 다음 행동 방향까지 준비합니다.',
      enExplain:
          'A strong first touch does more than stop the ball. It softens the pace and prepares the next action.',
      koNextPoint: '퍼스트 터치는 멈춤보다 연결을 만든다는 관점으로 보세요.',
      enNextPoint:
          'Think of the first touch as creating the next action, not just stopping the ball.',
    ),
    _McqSeed(
      id: 'issue271_jockey_delay',
      difficulty: 1,
      category: _QuizCategory.technique,
      koStem: '1대1 수비에서 첫 수비수가 가장 먼저 지켜야 할 원칙은 무엇일까요?',
      enStem: 'In 1v1 defending, what is the first defender’s top priority?',
      options: [
        _FootballQuizOption(
          koText: '각도를 잡고 시간을 벌며 상대를 지연시킨다',
          enText: 'Set the angle, buy time, and delay the attacker',
        ),
        _FootballQuizOption(
          koText: '바로 발을 뻗어 공만 노린다',
          enText: 'Stab for the ball immediately',
        ),
        _FootballQuizOption(
          koText: '뒤를 보지 않고 등을 돌린다',
          enText: 'Turn away without seeing the play',
        ),
        _FootballQuizOption(
          koText: '라인을 버리고 중앙을 비운다',
          enText: 'Abandon the line and open the center',
        ),
      ],
      correctIndex: 0,
      koExplain:
          '첫 수비수의 핵심은 곧바로 뺏는 것보다 상대를 원하는 방향으로 유도하며 동료가 정렬할 시간을 버는 데 있습니다.',
      enExplain:
          'The first defender’s main job is often to delay and guide the attacker so the team can recover shape, not to steal instantly.',
      koNextPoint: '수비 기술은 공만 보는 것이 아니라 상대의 선택지를 줄이는 과정입니다.',
      enNextPoint:
          'Defensive technique is not only about the ball. It is about reducing the attacker’s options.',
    ),
    _McqSeed(
      id: 'issue271_finish_across_goal',
      difficulty: 2,
      category: _QuizCategory.technique,
      koStem: '골키퍼와 마주한 상황에서 반대 구석으로 정확히 마무리하려면 어떤 슈팅 감각이 보통 더 적합할까요?',
      enStem:
          'When facing the goalkeeper and aiming for the far corner, which finishing feel is usually more suitable?',
      options: [
        _FootballQuizOption(
          koText: '몸을 열고 인사이드로 방향을 정한다',
          enText: 'Open the body and guide it with the inside of the foot',
        ),
        _FootballQuizOption(
          koText: '상체를 젖히고 최대한 힘만 준다',
          enText: 'Lean back and hit only for maximum power',
        ),
        _FootballQuizOption(
          koText: '시선 없이 발등만 강하게 휘두른다',
          enText: 'Swing hard with the laces without visual focus',
        ),
        _FootballQuizOption(
          koText: '수비수를 향해 일부러 맞힌다',
          enText: 'Deliberately hit the defender',
        ),
      ],
      correctIndex: 0,
      koExplain: '정확한 반대 구석 마무리는 몸을 열고 방향을 조절하는 인사이드 감각이 자주 유리합니다.',
      enExplain:
          'For a precise far-corner finish, an opened body and guided inside-foot contact are often more reliable than pure power.',
      koNextPoint: '마무리는 상황에 맞는 표면 선택이 중요합니다.',
      enNextPoint:
          'Finishing depends on choosing the striking surface that fits the moment.',
    ),
    _McqSeed(
      id: 'issue271_speed_when_fresh',
      difficulty: 2,
      category: _QuizCategory.training,
      koStem: '최고 속도 노출이나 질 높은 스프린트 훈련은 보통 세션의 어느 시점에 두는 편이 좋을까요?',
      enStem:
          'At what stage of a session are max-speed exposures or high-quality sprints usually best placed?',
      options: [
        _FootballQuizOption(
          koText: '충분한 준비운동 직후, 아직 신선할 때',
          enText: 'Soon after the warm-up, while the player is still fresh',
        ),
        _FootballQuizOption(
          koText: '완전히 지친 마지막 구간',
          enText: 'At the very end when fatigue is highest',
        ),
        _FootballQuizOption(
          koText: '정리운동이 끝난 뒤',
          enText: 'After the cool-down has finished',
        ),
        _FootballQuizOption(
          koText: '언제든 똑같이 상관없다',
          enText: 'It makes no difference at all',
        ),
      ],
      correctIndex: 0,
      koExplain: '높은 속도 훈련은 신경계 품질이 중요해, 준비가 끝난 뒤 아직 피로가 쌓이기 전이 가장 안정적입니다.',
      enExplain:
          'High-speed work depends on nervous-system quality, so it is usually safest and most effective soon after the warm-up.',
      koNextPoint: '훈련은 내용만이 아니라 배치 순서도 성과를 바꿉니다.',
      enNextPoint:
          'Training quality depends not only on content but also on where it sits in the session.',
    ),
    _McqSeed(
      id: 'issue271_small_sided_constraint',
      difficulty: 2,
      category: _QuizCategory.training,
      koStem: '좁은 공간에서 빠른 판단과 패스 지원 위치를 더 끌어내고 싶다면 어떤 훈련 설계가 가장 적합할까요?',
      enStem:
          'If you want more quick decisions and supporting options in tight space, which practice design fits best?',
      options: [
        _FootballQuizOption(
          koText: '터치 수와 공간을 제한한 소형 게임',
          enText: 'A small-sided game with touch and space constraints',
        ),
        _FootballQuizOption(
          koText: '아무 규칙 없는 긴 조깅',
          enText: 'A long jog with no task constraints',
        ),
        _FootballQuizOption(
          koText: '볼 없이 체력 테스트만 반복',
          enText: 'Repeat only fitness tests without the ball',
        ),
        _FootballQuizOption(
          koText: '매번 같은 정지 패턴만 걷기 속도로 수행',
          enText: 'Repeat the same static pattern at walking pace only',
        ),
      ],
      correctIndex: 0,
      koExplain: '의도한 행동을 끌어내려면 공간, 시간, 터치 같은 제약을 설계해 판단을 압축해야 합니다.',
      enExplain:
          'To pull out the target behaviors, you need constraints on space, time, or touches that compress decision-making.',
      koNextPoint: '훈련 설계는 무엇을 많이 일어나게 만들고 싶은지부터 정해야 합니다.',
      enNextPoint:
          'Start practice design by deciding which game actions you want to happen more often.',
    ),
    _McqSeed(
      id: 'issue271_progressive_load',
      difficulty: 2,
      category: _QuizCategory.training,
      koStem: '훈련 부하를 올릴 때 가장 안전하고 관리하기 쉬운 원칙은 무엇일까요?',
      enStem:
          'What is the safest and most manageable principle when increasing training load?',
      options: [
        _FootballQuizOption(
          koText: '한 번에 한 변수씩 점진적으로 올린다',
          enText: 'Increase one variable at a time progressively',
        ),
        _FootballQuizOption(
          koText: '시간, 강도, 횟수를 한꺼번에 크게 올린다',
          enText: 'Raise time, intensity, and repetitions all at once',
        ),
        _FootballQuizOption(
          koText: '피곤할수록 무조건 강도를 더한다',
          enText: 'Always add more intensity when tired',
        ),
        _FootballQuizOption(
          koText: '몸 반응을 보지 않고 계획만 고수한다',
          enText: 'Ignore body response and follow the plan blindly',
        ),
      ],
      correctIndex: 0,
      koExplain: '부하는 한 요소씩 올려야 무엇이 효과였고 무엇이 부담이었는지 추적하기 쉽습니다.',
      enExplain:
          'Progressing one variable at a time makes it easier to track what helped and what added too much stress.',
      koNextPoint: '훈련 부하는 숫자보다 반응과 맥락까지 함께 읽어야 합니다.',
      enNextPoint:
          'Read training load through both the numbers and the body’s response.',
    ),
    _McqSeed(
      id: 'issue271_repeat_sprint_quality',
      difficulty: 2,
      category: _QuizCategory.training,
      koStem: '반복 스프린트 훈련에서 질을 유지하려면 어떤 운영이 가장 적절할까요?',
      enStem:
          'Which management choice best helps maintain quality in repeated-sprint training?',
      options: [
        _FootballQuizOption(
          koText: '각 반복 사이에 충분한 회복을 준다',
          enText: 'Allow enough recovery between repetitions',
        ),
        _FootballQuizOption(
          koText: '형태가 무너져도 쉬지 않고 이어간다',
          enText: 'Continue without rest even after mechanics collapse',
        ),
        _FootballQuizOption(
          koText: '첫 질주 이후 속도는 신경 쓰지 않는다',
          enText: 'Ignore speed after the first sprint',
        ),
        _FootballQuizOption(
          koText: '볼 없이 무조건 거리만 늘린다',
          enText: 'Increase only distance no matter what',
        ),
      ],
      correctIndex: 0,
      koExplain: '반복 스프린트는 단순히 지치는 훈련이 아니라, 높은 속도 행동을 여러 번 재현하는 질 훈련입니다.',
      enExplain:
          'Repeated-sprint work is not just about getting tired. It is about reproducing high-speed actions with quality multiple times.',
      koNextPoint: '스피드 훈련은 양보다 질이 먼저 무너지지 않게 관리하세요.',
      enNextPoint:
          'In speed work, protect the quality before chasing more volume.',
    ),
    _McqSeed(
      id: 'issue271_reset_after_error',
      difficulty: 1,
      category: _QuizCategory.mindset,
      koStem: '큰 실수 직후 다음 플레이에 가장 빨리 복귀하도록 돕는 루틴은 무엇일까요?',
      enStem:
          'Which routine best helps a player return to the next action right after a major mistake?',
      options: [
        _FootballQuizOption(
          koText: '짧게 호흡하고 다음 임무를 한 문장으로 정리한다',
          enText: 'Take a brief breath and name the next job in one sentence',
        ),
        _FootballQuizOption(
          koText: '방금 장면만 계속 떠올리며 자책한다',
          enText: 'Replay the mistake and keep blaming yourself',
        ),
        _FootballQuizOption(
          koText: '동료 말을 끊고 혼자 흥분한다',
          enText: 'Ignore teammates and stay emotionally heated',
        ),
        _FootballQuizOption(
          koText: '다음 상황을 포기하고 걸어 다닌다',
          enText: 'Give up on the next phase and walk',
        ),
      ],
      correctIndex: 0,
      koExplain: '실수 직후에는 감정을 끌고 가기보다 호흡과 짧은 행동 큐로 다음 장면에 주의를 재배치하는 것이 중요합니다.',
      enExplain:
          'After a mistake, it is more useful to reset attention with breath and a short action cue than to carry the emotion forward.',
      koNextPoint: '마인드는 감정 억누르기보다 다음 행동으로 복귀하는 기술에 가깝습니다.',
      enNextPoint:
          'Mindset work is less about suppressing emotion and more about returning to the next action.',
    ),
    _McqSeed(
      id: 'issue271_process_goal_pressure',
      difficulty: 2,
      category: _QuizCategory.mindset,
      koStem: '중요한 경기에서 긴장이 클수록 어떤 목표 설정이 집중 유지에 더 도움이 될까요?',
      enStem:
          'In an important match, which type of goal setting helps concentration most under pressure?',
      options: [
        _FootballQuizOption(
          koText: '스캔, 첫 압박, 복귀 속도처럼 행동으로 쪼갠 목표',
          enText:
              'Goals broken into actions such as scanning, first press, and recovery speed',
        ),
        _FootballQuizOption(
          koText: '무조건 최고 평점 받기',
          enText: 'Get the top rating no matter what',
        ),
        _FootballQuizOption(
          koText: '관중 반응을 계속 의식하기',
          enText: 'Keep thinking about the crowd reaction',
        ),
        _FootballQuizOption(
          koText: '실수하지 않겠다고만 반복하기',
          enText: 'Repeat only that you must not make mistakes',
        ),
      ],
      correctIndex: 0,
      koExplain: '압박이 클수록 통제 가능한 행동 목표가 현재 장면에 집중을 묶어 주고 경기력을 안정시킵니다.',
      enExplain:
          'The more pressure there is, the more controllable action goals help anchor concentration to the present moment.',
      koNextPoint: '결과 목표를 행동 목표로 번역하는 습관을 들이세요.',
      enNextPoint:
          'Build the habit of translating outcome goals into action goals.',
    ),
    _McqSeed(
      id: 'issue271_preperformance_routine',
      difficulty: 2,
      category: _QuizCategory.mindset,
      koStem: '경기 시작 전 루틴이 잘 작동하려면 어떤 특징을 가져야 할까요?',
      enStem:
          'What makes a pre-performance routine most effective before kickoff?',
      options: [
        _FootballQuizOption(
          koText: '짧고 반복 가능하며 몸과 시선을 행동에 연결한다',
          enText: 'It is short, repeatable, and links body and gaze to action',
        ),
        _FootballQuizOption(
          koText: '매번 길고 즉흥적으로 바뀐다',
          enText: 'It is long and changes randomly every time',
        ),
        _FootballQuizOption(
          koText: '감정이 올라올 때만 가끔 한다',
          enText: 'It is used only occasionally when emotion spikes',
        ),
        _FootballQuizOption(
          koText: '동료와 분리돼 혼자만 이해할 수 있다',
          enText: 'It isolates the player and cannot connect with team cues',
        ),
      ],
      correctIndex: 0,
      koExplain: '좋은 루틴은 짧고 재현 가능해야 실제 경기 속도 안에서도 사용할 수 있고, 몸과 시선을 행동에 맞춰 줍니다.',
      enExplain:
          'A good routine must be short and repeatable so it can survive match speed and connect the body and eyes to action.',
      koNextPoint: '루틴은 멋있어 보이는 것보다 바로 실행 가능한지가 더 중요합니다.',
      enNextPoint:
          'A routine is valuable not because it looks impressive, but because it is executable immediately.',
    ),
    _McqSeed(
      id: 'issue271_halftime_refocus',
      difficulty: 2,
      category: _QuizCategory.mindset,
      koStem: '전반이 뜻대로 풀리지 않았을 때 하프타임에 가장 좋은 리셋 방식은 무엇일까요?',
      enStem:
          'When the first half has gone poorly, what is the best halftime reset approach?',
      options: [
        _FootballQuizOption(
          koText: '바꿀 수 있는 두 가지 행동만 정리한다',
          enText: 'Clarify only two controllable actions to change',
        ),
        _FootballQuizOption(
          koText: '실수 장면을 길게 비난한다',
          enText: 'Spend the break blaming the mistakes in detail',
        ),
        _FootballQuizOption(
          koText: '아무 계획 없이 감정만 끌어올린다',
          enText: 'Raise emotion only, without a plan',
        ),
        _FootballQuizOption(
          koText: '후반 시작 전까지 결과만 계산한다',
          enText: 'Think only about the result before the second half starts',
        ),
      ],
      correctIndex: 0,
      koExplain:
          '하프타임은 반성보다 재정렬의 시간이라, 후반 시작과 동시에 실행할 수 있는 행동 기준을 좁혀 주는 편이 좋습니다.',
      enExplain:
          'Halftime is more for reorganization than replay. Narrowing the focus to a few actionable changes helps immediately after restart.',
      koNextPoint: '마인드 정리는 길게 설명하기보다 짧게 실행되게 해야 합니다.',
      enNextPoint:
          'Mindset adjustments work best when they become short, actionable instructions.',
    ),
  ];
}

List<_OxFactSeed> _historyAndFifaRecordOxFacts() {
  return const [
    _OxFactSeed(
      id: 'fifa_world_cup_1930',
      difficulty: 1,
      category: _QuizCategory.fun,
      koTrueStatement: '첫 FIFA 월드컵은 1930년에 열렸다.',
      enTrueStatement: 'The first FIFA World Cup was held in 1930.',
      koFalseStatement: '첫 FIFA 월드컵은 1950년에 시작됐다.',
      enFalseStatement: 'The first FIFA World Cup began in 1950.',
      koExplain: 'FIFA 월드컵의 첫 대회는 1930년 우루과이에서 열렸습니다.',
      enExplain: 'The inaugural FIFA World Cup took place in Uruguay in 1930.',
      koNextPoint: '역사 문제는 연도와 개최국을 함께 묶어 기억하세요.',
      enNextPoint:
          'Link the year with the host nation when studying history questions.',
    ),
    _OxFactSeed(
      id: 'jules_rimet_current_trophy',
      difficulty: 2,
      category: _QuizCategory.fun,
      koTrueStatement: '지금도 월드컵 우승팀은 쥘 리메 트로피를 받는다.',
      enTrueStatement:
          'World Cup champions still receive the Jules Rimet Trophy today.',
      koFalseStatement: '현재 월드컵 우승 트로피는 1974년부터 쓰인 새 트로피다.',
      enFalseStatement:
          'The current World Cup trophy is the newer design introduced in 1974.',
      koExplain: '쥘 리메 트로피는 1970년까지 사용됐고, 이후에는 현재의 FIFA 월드컵 트로피가 쓰입니다.',
      enExplain:
          'The Jules Rimet Trophy was used through 1970, after which the current FIFA World Cup Trophy took over.',
      koNextPoint: '대회 역사에서는 우승국뿐 아니라 트로피 변화도 함께 보세요.',
      enNextPoint:
          'In tournament history, study trophy changes alongside champions.',
    ),
    _OxFactSeed(
      id: 'premier_league_1992_start',
      difficulty: 1,
      category: _QuizCategory.fun,
      koTrueStatement: '프리미어리그는 1992년에 출범했다.',
      enTrueStatement: 'The Premier League launched in 1992.',
      koFalseStatement: '프리미어리그는 1970년에 출범했다.',
      enFalseStatement: 'The Premier League launched in 1970.',
      koExplain: '잉글랜드 프리미어리그는 1992년에 새 리그 체제로 출범했습니다.',
      enExplain:
          'The Premier League began in 1992 as a new top-flight structure in England.',
      koNextPoint: '리그 역사 문제는 출범 연도와 초대 우승팀을 함께 묶으세요.',
      enNextPoint:
          'For league history, pair founding years with inaugural champions.',
    ),
    _OxFactSeed(
      id: 'maradona_hand_of_god_1986',
      difficulty: 2,
      category: _QuizCategory.fun,
      koTrueStatement: '마라도나의 “신의 손” 골은 1986년 월드컵에서 나왔다.',
      enTrueStatement:
          'Maradona’s “Hand of God” goal came at the 1986 World Cup.',
      koFalseStatement: '마라도나의 “신의 손” 골은 1998년 월드컵에서 나왔다.',
      enFalseStatement:
          'Maradona’s “Hand of God” goal came at the 1998 World Cup.',
      koExplain: '“신의 손”은 1986년 멕시코 월드컵 아르헨티나 대 잉글랜드 경기의 상징적 장면입니다.',
      enExplain:
          'The “Hand of God” is one of the defining moments of Argentina vs England at Mexico 1986.',
      koNextPoint: '역사 장면은 연도와 상대 팀까지 같이 기억하면 오래 남습니다.',
      enNextPoint:
          'Historic moments stick better when paired with year and opponent.',
    ),
    _OxFactSeed(
      id: 'womens_world_cup_1991',
      difficulty: 1,
      category: _QuizCategory.fun,
      koTrueStatement: 'FIFA 여자 월드컵의 첫 대회는 1991년에 열렸다.',
      enTrueStatement: 'The first FIFA Women’s World Cup was held in 1991.',
      koFalseStatement: 'FIFA 여자 월드컵의 첫 대회는 2003년에 열렸다.',
      enFalseStatement: 'The first FIFA Women’s World Cup was held in 2003.',
      koExplain: 'FIFA 여자 월드컵은 1991년에 시작되었고 중국이 첫 개최국이었습니다.',
      enExplain:
          'The FIFA Women’s World Cup began in 1991, with China hosting the first edition.',
      koNextPoint: '남자 대회와 여자 대회의 시작 연도를 함께 비교해 보세요.',
      enNextPoint:
          'Compare the launch years of the men’s and women’s tournaments together.',
    ),
    _OxFactSeed(
      id: 'champions_league_old_name',
      difficulty: 2,
      category: _QuizCategory.fun,
      koTrueStatement: 'UEFA 챔피언스리그의 이전 이름은 유러피언컵이다.',
      enTrueStatement:
          'The former name of the UEFA Champions League was the European Cup.',
      koFalseStatement: 'UEFA 챔피언스리그의 이전 이름은 월드 클럽 챔피언십이다.',
      enFalseStatement:
          'The former name of the UEFA Champions League was the World Club Championship.',
      koExplain: '챔피언스리그는 유러피언컵에서 발전한 대회로, 명칭과 포맷이 바뀌었습니다.',
      enExplain:
          'The Champions League evolved from the European Cup with major naming and format changes.',
      koNextPoint: '대회 역사는 이름 변화와 포맷 변화까지 함께 보세요.',
      enNextPoint:
          'Study competitions through both name changes and format changes.',
    ),
  ];
}

List<_McqSeed> _historyAndFifaRecordMcqSeeds() {
  return const [
    _McqSeed(
      id: 'world_cup_most_titles',
      difficulty: 2,
      category: _QuizCategory.fun,
      koStem: '남자 FIFA 월드컵 최다 우승 국가로 알려진 팀은 어디일까요?',
      enStem:
          'Which team is known for winning the most men’s FIFA World Cup titles?',
      options: [
        _FootballQuizOption(koText: '브라질', enText: 'Brazil'),
        _FootballQuizOption(koText: '독일', enText: 'Germany'),
        _FootballQuizOption(koText: '아르헨티나', enText: 'Argentina'),
        _FootballQuizOption(koText: '이탈리아', enText: 'Italy'),
      ],
      correctIndex: 0,
      koExplain: '브라질은 남자 FIFA 월드컵 최다 우승 기록을 가진 대표팀으로 잘 알려져 있습니다.',
      enExplain:
          'Brazil is widely recognized as the national team with the most men’s FIFA World Cup titles.',
      koNextPoint: '월드컵 기록은 우승 횟수와 우승 연도를 함께 정리하세요.',
      enNextPoint:
          'Track World Cup records by pairing title counts with winning years.',
    ),
    _McqSeed(
      id: 'first_world_cup_host',
      difficulty: 1,
      category: _QuizCategory.fun,
      koStem: '1930년 첫 FIFA 월드컵 개최국은 어디였을까요?',
      enStem: 'Which country hosted the first FIFA World Cup in 1930?',
      options: [
        _FootballQuizOption(koText: '우루과이', enText: 'Uruguay'),
        _FootballQuizOption(koText: '브라질', enText: 'Brazil'),
        _FootballQuizOption(koText: '이탈리아', enText: 'Italy'),
        _FootballQuizOption(koText: '프랑스', enText: 'France'),
      ],
      correctIndex: 0,
      koExplain: '첫 FIFA 월드컵은 1930년 우루과이에서 개최됐습니다.',
      enExplain: 'The first FIFA World Cup was hosted by Uruguay in 1930.',
      koNextPoint: '개최국과 초대 우승국을 연결해 보면 역사 흐름이 더 잘 보입니다.',
      enNextPoint:
          'Connect the host and first champion to understand the historical flow better.',
    ),
    _McqSeed(
      id: 'fifa_world_cup_trophy_name',
      difficulty: 2,
      category: _QuizCategory.fun,
      koStem: '1974년부터 월드컵 우승팀에 수여되는 현재 트로피 이름은 무엇일까요?',
      enStem:
          'What is the name of the current trophy awarded to World Cup champions since 1974?',
      options: [
        _FootballQuizOption(
          koText: 'FIFA 월드컵 트로피',
          enText: 'FIFA World Cup Trophy',
        ),
        _FootballQuizOption(koText: '쥘 리메 트로피', enText: 'Jules Rimet Trophy'),
        _FootballQuizOption(koText: '골든볼', enText: 'Golden Ball'),
        _FootballQuizOption(koText: '인터콘티넨털 컵', enText: 'Intercontinental Cup'),
      ],
      correctIndex: 0,
      koExplain: '1974년부터는 쥘 리메 트로피 대신 현재의 FIFA 월드컵 트로피가 수여됩니다.',
      enExplain:
          'Since 1974, the FIFA World Cup Trophy has been awarded instead of the Jules Rimet Trophy.',
      koNextPoint: '트로피 이름 변화는 대회 역사 흐름을 잡는 데 유용합니다.',
      enNextPoint:
          'Trophy-name changes are useful anchors for learning tournament history.',
    ),
    _McqSeed(
      id: 'first_ballon_dor_winner',
      difficulty: 3,
      category: _QuizCategory.fun,
      koStem: '1956년 첫 발롱도르 수상자는 누구일까요?',
      enStem: 'Who won the first Ballon d’Or in 1956?',
      options: [
        _FootballQuizOption(koText: '스탠리 매튜스', enText: 'Stanley Matthews'),
        _FootballQuizOption(koText: '펠레', enText: 'Pele'),
        _FootballQuizOption(
          koText: '알프레도 디 스테파노',
          enText: 'Alfredo Di Stefano',
        ),
        _FootballQuizOption(koText: '요한 크루이프', enText: 'Johan Cruyff'),
      ],
      correctIndex: 0,
      koExplain: '첫 발롱도르는 1956년 스탠리 매튜스가 수상했습니다.',
      enExplain:
          'The first Ballon d’Or was awarded to Stanley Matthews in 1956.',
      koNextPoint: '개인상 역사는 첫 수상자와 연도를 같이 외우면 좋습니다.',
      enNextPoint:
          'Awards history is easier when you pair first winners with years.',
    ),
    _McqSeed(
      id: 'premier_league_inaugural_champion',
      difficulty: 2,
      category: _QuizCategory.fun,
      koStem: '1992-93 초대 프리미어리그 우승팀은 어디일까요?',
      enStem: 'Who were the inaugural Premier League champions in 1992-93?',
      options: [
        _FootballQuizOption(koText: '맨체스터 유나이티드', enText: 'Manchester United'),
        _FootballQuizOption(koText: '아스널', enText: 'Arsenal'),
        _FootballQuizOption(koText: '블랙번 로버스', enText: 'Blackburn Rovers'),
        _FootballQuizOption(koText: '리버풀', enText: 'Liverpool'),
      ],
      correctIndex: 0,
      koExplain: '프리미어리그 출범 첫 시즌인 1992-93 우승팀은 맨체스터 유나이티드였습니다.',
      enExplain:
          'Manchester United won the inaugural Premier League title in 1992-93.',
      koNextPoint: '새 리그나 대회의 초대 우승팀은 역사 문제의 핵심 포인트입니다.',
      enNextPoint:
          'Inaugural champions are a key anchor point in competition history.',
    ),
    _McqSeed(
      id: 'champions_league_rebrand_year',
      difficulty: 2,
      category: _QuizCategory.fun,
      koStem: '유러피언컵이 UEFA 챔피언스리그로 바뀐 시즌은 언제일까요?',
      enStem:
          'When was the European Cup rebranded as the UEFA Champions League?',
      options: [
        _FootballQuizOption(koText: '1992-93 시즌', enText: '1992-93 season'),
        _FootballQuizOption(koText: '1974-75 시즌', enText: '1974-75 season'),
        _FootballQuizOption(koText: '2000-01 시즌', enText: '2000-01 season'),
        _FootballQuizOption(koText: '1984-85 시즌', enText: '1984-85 season'),
      ],
      correctIndex: 0,
      koExplain: '유러피언컵은 1992-93 시즌부터 UEFA 챔피언스리그라는 이름으로 운영됐습니다.',
      enExplain:
          'The competition began operating as the UEFA Champions League from the 1992-93 season.',
      koNextPoint: '대회 역사에서는 리브랜딩 시점도 중요한 사건입니다.',
      enNextPoint:
          'Rebranding years are important landmarks in competition history.',
    ),
    _McqSeed(
      id: 'invincibles_club',
      difficulty: 2,
      category: _QuizCategory.fun,
      koStem: '프리미어리그 한 시즌 무패 우승 “인빈서블스”로 가장 유명한 팀은 어디일까요?',
      enStem:
          'Which team is most famous for the undefeated “Invincibles” Premier League season?',
      options: [
        _FootballQuizOption(koText: '아스널', enText: 'Arsenal'),
        _FootballQuizOption(koText: '첼시', enText: 'Chelsea'),
        _FootballQuizOption(koText: '맨체스터 시티', enText: 'Manchester City'),
        _FootballQuizOption(koText: '리즈 유나이티드', enText: 'Leeds United'),
      ],
      correctIndex: 0,
      koExplain: '아스널의 2003-04 무패 우승은 프리미어리그 역사에서 가장 상징적인 기록 중 하나입니다.',
      enExplain:
          'Arsenal’s 2003-04 unbeaten title is one of the most iconic records in Premier League history.',
      koNextPoint: '팀 별명과 시즌 기록을 함께 연결하면 기억하기 쉽습니다.',
      enNextPoint:
          'It is easier to remember historic teams by pairing nicknames with seasons.',
    ),
    _McqSeed(
      id: 'zidane_headbutt_tournament',
      difficulty: 2,
      category: _QuizCategory.fun,
      koStem: '지네딘 지단의 결승전 헤더 사건은 어느 대회에서 나왔을까요?',
      enStem:
          'In which tournament final did Zinedine Zidane’s famous headbutt incident occur?',
      options: [
        _FootballQuizOption(
          koText: '2006 FIFA 월드컵',
          enText: '2006 FIFA World Cup',
        ),
        _FootballQuizOption(koText: '2000 유로', enText: 'UEFA Euro 2000'),
        _FootballQuizOption(
          koText: '2002 챔피언스리그',
          enText: '2002 Champions League',
        ),
        _FootballQuizOption(
          koText: '1998 FIFA 월드컵',
          enText: '1998 FIFA World Cup',
        ),
      ],
      correctIndex: 0,
      koExplain: '지단의 헤더 사건은 2006 독일 월드컵 결승전에서 벌어진 역사적 장면입니다.',
      enExplain:
          'Zidane’s headbutt took place in the 2006 World Cup final in Germany.',
      koNextPoint: '상징적 장면은 대회와 상대까지 함께 묶어 보세요.',
      enNextPoint:
          'Pair iconic moments with the tournament and opponent for stronger recall.',
    ),
    _McqSeed(
      id: 'hand_of_god_opponent',
      difficulty: 2,
      category: _QuizCategory.fun,
      koStem: '마라도나의 “신의 손” 장면 상대 팀은 어디였을까요?',
      enStem:
          'Who were Argentina facing when Maradona scored the “Hand of God” goal?',
      options: [
        _FootballQuizOption(koText: '잉글랜드', enText: 'England'),
        _FootballQuizOption(koText: '독일', enText: 'Germany'),
        _FootballQuizOption(koText: '브라질', enText: 'Brazil'),
        _FootballQuizOption(koText: '네덜란드', enText: 'Netherlands'),
      ],
      correctIndex: 0,
      koExplain: '“신의 손”과 이어진 환상적인 60m 드리블 골은 모두 잉글랜드전에서 나왔습니다.',
      enExplain:
          'Both the “Hand of God” and the stunning dribble goal came against England.',
      koNextPoint: '유명한 역사 장면은 상대와 경기 맥락까지 함께 보세요.',
      enNextPoint: 'Study famous moments with the opponent and match context.',
    ),
    _McqSeed(
      id: 'messi_napkin_contract_lesson',
      difficulty: 2,
      category: _QuizCategory.fun,
      koStem: '어린 메시의 바르셀로나 입단 약속이 급히 적힌 것으로 유명한 물건은 무엇일까요?',
      enStem:
          'What object is famously linked to young Messi’s first Barcelona agreement?',
      options: [
        _FootballQuizOption(koText: '냅킨', enText: 'A napkin'),
        _FootballQuizOption(koText: '축구화', enText: 'A boot'),
        _FootballQuizOption(koText: '유니폼 소매', enText: 'A shirt sleeve'),
        _FootballQuizOption(koText: '경기 티켓', enText: 'A match ticket'),
      ],
      correctIndex: 0,
      koExplain: '메시의 바르셀로나 첫 약속은 냅킨에 적힌 일화로 유명합니다. 재능을 알아본 순간 빠르게 붙잡은 결정이었어요.',
      enExplain:
          'Messi’s first Barcelona agreement is famously tied to a napkin, showing how quickly a club moved when it recognized special talent.',
      koNextPoint: '전설의 일화는 재능뿐 아니라 기회를 붙잡는 결정을 함께 보여줍니다.',
      enNextPoint:
          'Legend anecdotes often teach both talent recognition and decisive action.',
    ),
    _McqSeed(
      id: 'klose_fair_play_handball',
      difficulty: 3,
      category: _QuizCategory.fun,
      koStem: '미로슬라프 클로제가 손에 맞은 골을 인정해 취소된 일화에서 배울 점은 무엇일까요?',
      enStem:
          'What lesson is tied to Miroslav Klose admitting a goal came off his hand?',
      options: [
        _FootballQuizOption(koText: '정직한 플레이', enText: 'Honest play'),
        _FootballQuizOption(koText: '시간 지연', enText: 'Delaying play'),
        _FootballQuizOption(koText: '강한 항의', enText: 'Arguing harder'),
        _FootballQuizOption(
          koText: '세리머니 연습',
          enText: 'Practicing celebrations',
        ),
      ],
      correctIndex: 0,
      koExplain: '클로제는 손에 맞고 들어간 골을 심판에게 알린 일화로 페어플레이의 좋은 예가 됐습니다.',
      enExplain:
          'Klose became a strong fair-play example by telling the referee that a goal had gone in off his hand.',
      koNextPoint: '좋은 선수는 기록뿐 아니라 경기 태도로도 기억됩니다.',
      enNextPoint:
          'Great players are remembered for conduct as well as statistics.',
    ),
    _McqSeed(
      id: 'cruyff_turn_1974_lesson',
      difficulty: 2,
      category: _QuizCategory.fun,
      koStem: '요한 크루이프 턴이 세계적으로 각인된 대회는 어디였을까요?',
      enStem: 'Which tournament made the Johan Cruyff Turn famous worldwide?',
      options: [
        _FootballQuizOption(
          koText: '1974 FIFA 월드컵',
          enText: '1974 FIFA World Cup',
        ),
        _FootballQuizOption(
          koText: '1966 FIFA 월드컵',
          enText: '1966 FIFA World Cup',
        ),
        _FootballQuizOption(koText: '유로 1992', enText: 'Euro 1992'),
        _FootballQuizOption(
          koText: '2002 챔피언스리그',
          enText: '2002 Champions League',
        ),
      ],
      correctIndex: 0,
      koExplain:
          '크루이프 턴은 1974년 월드컵에서 전 세계에 강하게 각인됐고, 속임 동작과 방향 전환의 대표 예시가 됐습니다.',
      enExplain:
          'The Cruyff Turn became famous at the 1974 World Cup and remains a classic example of disguise plus direction change.',
      koNextPoint: '기술 일화는 언제 쓰였고 어떤 문제를 해결했는지 함께 보세요.',
      enNextPoint:
          'Study skill anecdotes by asking when the move was used and what problem it solved.',
    ),
    _McqSeed(
      id: 'womens_world_cup_first_host',
      difficulty: 2,
      category: _QuizCategory.fun,
      koStem: '첫 FIFA 여자 월드컵 개최국은 어디였을까요?',
      enStem: 'Which country hosted the first FIFA Women’s World Cup?',
      options: [
        _FootballQuizOption(koText: '중국', enText: 'China'),
        _FootballQuizOption(koText: '미국', enText: 'United States'),
        _FootballQuizOption(koText: '독일', enText: 'Germany'),
        _FootballQuizOption(koText: '스웨덴', enText: 'Sweden'),
      ],
      correctIndex: 0,
      koExplain: '첫 여자 월드컵은 1991년 중국에서 열렸습니다.',
      enExplain: 'The first Women’s World Cup was held in China in 1991.',
      koNextPoint: '여자 축구 역사도 남자 축구와 따로 정리해 두면 좋습니다.',
      enNextPoint:
          'Women’s football history is worth studying as its own timeline.',
    ),
    _McqSeed(
      id: 'most_world_cup_goals_player',
      difficulty: 2,
      category: _QuizCategory.fun,
      koStem: '남자 월드컵 통산 최다 득점 기록자로 잘 알려진 선수는 누구일까요?',
      enStem:
          'Who is widely recognized as the all-time leading scorer in the men’s World Cup?',
      options: [
        _FootballQuizOption(koText: '미로슬라프 클로제', enText: 'Miroslav Klose'),
        _FootballQuizOption(koText: '호나우두', enText: 'Ronaldo'),
        _FootballQuizOption(koText: '게르트 뮐러', enText: 'Gerd Muller'),
        _FootballQuizOption(koText: '리오넬 메시', enText: 'Lionel Messi'),
      ],
      correctIndex: 0,
      koExplain: '미로슬라프 클로제는 남자 월드컵 통산 최다 득점 기록으로 널리 알려져 있습니다.',
      enExplain:
          'Miroslav Klose is widely recognized as the all-time top scorer in the men’s World Cup.',
      koNextPoint: '대회 기록은 선수 이름과 숫자를 세트로 외우면 좋습니다.',
      enNextPoint:
          'For tournament records, memorize the player together with the number.',
    ),
  ];
}

List<_ShortAnswerKnowledgeSeed> _historyAndFifaRecordShortAnswerSeeds() {
  return const [
    _ShortAnswerKnowledgeSeed(
      id: 'first_world_cup_year',
      difficulty: 1,
      category: _QuizCategory.fun,
      koClue: '첫 FIFA 월드컵이 열린 연도. 숫자 네 자리로 쓰세요',
      enClue: 'Year of the first FIFA World Cup. Answer with four digits',
      acceptedAnswers: ['1930'],
      koExplain: '정답은 "1930"입니다. FIFA 월드컵 역사는 우루과이에서 시작됐습니다.',
      enExplain:
          'The answer is "1930." FIFA World Cup history began in Uruguay.',
      koNextPoint: '축구 역사 문제는 연도와 장소를 함께 묶어서 익히세요.',
      enNextPoint:
          'Study football history by pairing landmark years with locations.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'jules_rimet',
      difficulty: 2,
      category: _QuizCategory.fun,
      koClue: '1970년까지 월드컵 우승팀에 수여되던 트로피 이름',
      enClue: 'Name of the trophy awarded to World Cup champions through 1970',
      acceptedAnswers: [
        '쥘 리메 트로피',
        '쥘리메 트로피',
        'jules rimet trophy',
        'julesrimettrophy',
      ],
      koExplain: '정답은 "쥘 리메 트로피"입니다. 이후에는 현재의 FIFA 월드컵 트로피가 사용됩니다.',
      enExplain:
          'The answer is "Jules Rimet Trophy." It was later replaced by the current FIFA World Cup Trophy.',
      koNextPoint: '트로피 이름은 시대 구분 포인트로 활용할 수 있습니다.',
      enNextPoint:
          'Trophy names can act as useful markers for separating eras.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'first_womens_world_cup_year',
      difficulty: 1,
      category: _QuizCategory.fun,
      koClue: '첫 FIFA 여자 월드컵이 열린 연도. 숫자 네 자리로 쓰세요',
      enClue:
          'Year of the first FIFA Women’s World Cup. Answer with four digits',
      acceptedAnswers: ['1991'],
      koExplain: '정답은 "1991"입니다. 첫 FIFA 여자 월드컵은 중국에서 열렸습니다.',
      enExplain:
          'The answer is "1991." The first FIFA Women’s World Cup was held in China.',
      koNextPoint: '축구 역사에서 여자 대회 시작 연도도 중요한 기준점입니다.',
      enNextPoint:
          'The launch year of women’s competitions is a key football-history anchor too.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'european_cup_old_name',
      difficulty: 2,
      category: _QuizCategory.fun,
      koClue: 'UEFA 챔피언스리그의 이전 이름',
      enClue: 'Former name of the UEFA Champions League',
      acceptedAnswers: ['유러피언컵', 'european cup', 'the european cup'],
      koExplain: '정답은 "유러피언컵"입니다. 챔피언스리그는 이 대회를 바탕으로 발전했습니다.',
      enExplain:
          'The answer is "European Cup." The Champions League grew out of that competition.',
      koNextPoint: '대회의 옛 이름과 현재 이름을 함께 묶어 보세요.',
      enNextPoint: 'Link former competition names with their current identity.',
    ),
  ];
}

List<_OxFactSeed> _advancedFootballHistoryOxFacts() {
  return const [
    _OxFactSeed(
      id: 'history_hungary_wembley_1953',
      difficulty: 3,
      category: _QuizCategory.fun,
      koTrueStatement: '1953년 헝가리는 웸블리에서 잉글랜드를 6-3으로 꺾으며 전술 변화의 상징적 장면을 만들었다.',
      enTrueStatement:
          'In 1953, Hungary beat England 6-3 at Wembley and created a landmark tactical moment.',
      koFalseStatement: '1953년 헝가리와 잉글랜드의 웸블리 경기는 0-0으로 끝나 전술적으로 큰 의미가 없었다.',
      enFalseStatement:
          'The 1953 Wembley match between Hungary and England ended 0-0 and carried little tactical meaning.',
      koExplain: '이 경기는 전통적 포지션 이해가 유동적 움직임과 조합 플레이 앞에서 흔들릴 수 있음을 보여줬습니다.',
      enExplain:
          'The match showed how fluid movement and combinations could unsettle traditional positional thinking.',
      koNextPoint: '축구 역사는 결과보다 그 경기가 전술 사고를 어떻게 바꿨는지까지 보세요.',
      enNextPoint:
          'Study football history by asking how a match changed tactical thinking, not only who won.',
    ),
    _OxFactSeed(
      id: 'history_back_pass_law_1992',
      difficulty: 2,
      category: _QuizCategory.rules,
      koTrueStatement:
          '1992년에 도입된 백패스 규정은 골키퍼가 동료의 의도적 발 패스를 손으로 잡는 시간을 줄이려는 변화였다.',
      enTrueStatement:
          'The 1992 back-pass law reduced time-wasting by stopping goalkeepers from handling deliberate passes by foot from teammates.',
      koFalseStatement: '1992년 백패스 규정은 골키퍼가 어떤 동료 패스든 손으로 잡을 수 있게 만든 변화였다.',
      enFalseStatement:
          'The 1992 back-pass law allowed goalkeepers to handle any teammate pass.',
      koExplain: '백패스 규정은 경기 속도와 빌드업 방식을 바꾼 대표적인 규칙 변화입니다.',
      enExplain:
          'The back-pass law is a major rules change that affected tempo and build-up play.',
      koNextPoint: '규칙 변화는 경기 템포와 기술 요구가 어떻게 달라졌는지 함께 보세요.',
      enNextPoint:
          'Link rules changes with their effect on tempo and technical demands.',
    ),
    _OxFactSeed(
      id: 'history_bosman_ruling_1995',
      difficulty: 3,
      category: _QuizCategory.fun,
      koTrueStatement: '1995년 보스만 판결은 유럽 축구 선수 이적과 계약 만료 후 이동 자유에 큰 영향을 줬다.',
      enTrueStatement:
          'The 1995 Bosman ruling had a major impact on European football transfers and freedom of movement after contracts expired.',
      koFalseStatement: '1995년 보스만 판결은 경기 중 오프사이드 해석만 바꾼 규칙 판정이었다.',
      enFalseStatement:
          'The 1995 Bosman ruling changed only in-match offside interpretation.',
      koExplain: '보스만 판결은 경기 규칙이 아니라 선수 노동권과 클럽 운영 구조를 바꾼 사건입니다.',
      enExplain:
          'The Bosman ruling changed player employment rights and squad-building, not match laws.',
      koNextPoint: '축구 역사는 경기장 밖 제도 변화도 함께 봐야 흐름이 보입니다.',
      enNextPoint:
          'Football history includes off-field systems such as contracts and squad rules.',
    ),
    _OxFactSeed(
      id: 'history_total_football_rotation',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koTrueStatement: '토털 풋볼은 선수들이 위치를 바꾸더라도 팀 구조와 공간 점유를 유지하는 원리와 연결된다.',
      enTrueStatement:
          'Total Football is linked to players rotating positions while preserving team structure and space occupation.',
      koFalseStatement: '토털 풋볼은 모든 선수가 자기 자리에서 절대 움직이지 않는 축구를 뜻한다.',
      enFalseStatement:
          'Total Football means every player stays fixed in one position and never rotates.',
      koExplain: '토털 풋볼은 이름보다도 교대, 압박, 공간 점유를 함께 이해해야 합니다.',
      enExplain:
          'Total Football is best understood through rotation, pressing, and space occupation.',
      koNextPoint: '역사적 전술 용어는 이름보다 실제 원리를 설명할 수 있어야 합니다.',
      enNextPoint:
          'For historic tactical terms, learn the principle behind the name.',
    ),
    _OxFactSeed(
      id: 'history_denmark_euro_1992',
      difficulty: 2,
      category: _QuizCategory.fun,
      koTrueStatement: '덴마크는 유로 1992에서 뒤늦게 본선에 합류한 뒤 우승까지 차지했다.',
      enTrueStatement:
          'Denmark entered Euro 1992 late and went on to win the tournament.',
      koFalseStatement: '덴마크는 유로 1992에서 결승 토너먼트에 오르지 못했다.',
      enFalseStatement:
          'Denmark failed to reach the knockout stage at Euro 1992.',
      koExplain: '덴마크의 유로 1992 우승은 준비 기간, 팀 응집력, 토너먼트 흐름을 함께 보여주는 역사적 사례입니다.',
      enExplain:
          'Denmark 1992 is a historic case of preparation, cohesion, and tournament momentum.',
      koNextPoint: '토너먼트 역사는 전력 평가와 실제 흐름이 얼마나 다를 수 있는지 보여줍니다.',
      enNextPoint:
          'Tournament history shows how pre-event expectations and actual runs can diverge.',
    ),
    _OxFactSeed(
      id: 'history_womens_world_cup_1999_final',
      difficulty: 2,
      category: _QuizCategory.fun,
      koTrueStatement: '1999년 FIFA 여자 월드컵 결승은 미국과 중국의 승부차기 승부로 널리 기억된다.',
      enTrueStatement:
          'The 1999 FIFA Women’s World Cup final is widely remembered for the United States and China going to penalties.',
      koFalseStatement: '1999년 FIFA 여자 월드컵 결승은 브라질과 독일의 골든골 경기였다.',
      enFalseStatement:
          'The 1999 FIFA Women’s World Cup final was a golden-goal match between Brazil and Germany.',
      koExplain: '1999년 결승은 여자축구 대중화와 큰 관중 앞 승부의 상징적 장면으로 남았습니다.',
      enExplain:
          'The 1999 final became a landmark for women’s football visibility and big-stage pressure.',
      koNextPoint: '여자축구 역사도 대회 성장과 문화적 영향까지 함께 보세요.',
      enNextPoint:
          'Study women’s football history through tournament growth and cultural impact.',
    ),
  ];
}

List<_McqSeed> _advancedFootballHistoryMcqSeeds() {
  return const [
    _McqSeed(
      id: 'history_wm_formation_context',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koStem: 'WM 포메이션이 축구 역사에서 중요하게 다뤄지는 이유로 가장 적절한 것은 무엇일까요?',
      enStem:
          'Why is the WM formation treated as an important landmark in football history?',
      options: [
        _FootballQuizOption(
          koText: '오프사이드 법 변화 이후 수비와 공격 구조를 새롭게 정리했기 때문',
          enText:
              'It reorganized defensive and attacking structure after offside-law changes',
        ),
        _FootballQuizOption(
          koText: '골키퍼가 필드 플레이어처럼 뛰는 규칙을 처음 만들었기 때문',
          enText:
              'It first created a rule where goalkeepers played as outfielders',
        ),
        _FootballQuizOption(
          koText: '모든 팀이 센터백 없이 경기하도록 강제했기 때문',
          enText: 'It forced every team to play without center backs',
        ),
        _FootballQuizOption(
          koText: '승부차기 규칙을 없앤 포메이션이었기 때문',
          enText: 'It was a formation that removed penalty shootouts',
        ),
      ],
      correctIndex: 0,
      koExplain: 'WM은 오프사이드 법 변화 뒤 수비 라인과 공격 배치를 재해석한 역사적 전술 전환점입니다.',
      enExplain:
          'The WM is a tactical landmark because it responded structurally to changes in the offside law.',
      koNextPoint: '포메이션 역사는 숫자 배열보다 왜 그 배열이 필요했는지를 보세요.',
      enNextPoint:
          'For formation history, ask why the shape was needed rather than only memorizing numbers.',
    ),
    _McqSeed(
      id: 'history_catenaccio_principle',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koStem: '카테나치오를 단순한 수비 축구가 아니라 전술 개념으로 이해할 때 핵심은 무엇일까요?',
      enStem:
          'When reading catenaccio as a tactical concept rather than just defensive football, what is central?',
      options: [
        _FootballQuizOption(
          koText: '스위퍼 보호와 압축된 수비 뒤 빠른 전환',
          enText: 'Sweeper cover, compact defending, and quick transition',
        ),
        _FootballQuizOption(
          koText: '모든 선수가 터치라인에 고정되는 공격',
          enText: 'Every player staying fixed on the touchline in attack',
        ),
        _FootballQuizOption(
          koText: '골키퍼가 항상 중앙 미드필더로 올라가는 구조',
          enText: 'A goalkeeper always stepping into central midfield',
        ),
        _FootballQuizOption(
          koText: '센터백이 없는 초공격 포메이션',
          enText: 'An ultra-attacking system without center backs',
        ),
      ],
      correctIndex: 0,
      koExplain: '카테나치오는 빗장이라는 이미지처럼 뒤 보호와 공간 통제, 전환 공격까지 함께 봐야 합니다.',
      enExplain:
          'Catenaccio is best read through cover, space control, and transition, not just negativity.',
      koNextPoint: '전술사 문항에서는 별명보다 구조와 전환 방식을 설명해 보세요.',
      enNextPoint:
          'For tactical history, explain the structure and transition pattern behind the nickname.',
    ),
    _McqSeed(
      id: 'history_total_football_read',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koStem: '1970년대 네덜란드와 아약스로 대표되는 토털 풋볼을 가장 잘 설명하는 선택지는?',
      enStem:
          'Which option best describes Total Football associated with 1970s Netherlands and Ajax?',
      options: [
        _FootballQuizOption(
          koText: '위치 교대 속에서도 압박과 공간 점유 원칙을 유지한다',
          enText:
              'Players rotate positions while preserving pressing and space-occupation principles',
        ),
        _FootballQuizOption(
          koText: '공을 잡은 선수만 움직이고 나머지는 모두 멈춘다',
          enText: 'Only the ball carrier moves while everyone else stops',
        ),
        _FootballQuizOption(
          koText: '오프사이드 라인을 쓰지 않고 골문 앞에만 선다',
          enText: 'Avoid the offside line and stand only in front of goal',
        ),
        _FootballQuizOption(
          koText: '롱볼만 반복하는 전술을 뜻한다',
          enText: 'It means repeating long balls only',
        ),
      ],
      correctIndex: 0,
      koExplain: '토털 풋볼은 선수의 자유가 아니라 팀 원칙 안에서 이루어지는 유동성과 압박이 핵심입니다.',
      enExplain:
          'Total Football is not random freedom; it is fluidity inside shared team principles.',
      koNextPoint: '역사적 명칭은 대표 팀, 시대, 작동 원리를 함께 정리하세요.',
      enNextPoint: 'Pair historic labels with team, era, and mechanism.',
    ),
    _McqSeed(
      id: 'history_bosman_impact',
      difficulty: 3,
      category: _QuizCategory.fun,
      koStem: '보스만 판결의 축구사적 영향으로 가장 알맞은 것은?',
      enStem:
          'What is the best description of the Bosman ruling’s historical impact?',
      options: [
        _FootballQuizOption(
          koText: '계약 만료 선수의 이동 자유와 유럽 클럽 스쿼드 구성 방식에 영향을 줬다',
          enText:
              'It affected out-of-contract player movement and European squad building',
        ),
        _FootballQuizOption(
          koText: '스로인 위치를 모두 중앙선으로 바꿨다',
          enText: 'It moved all throw-ins to the halfway line',
        ),
        _FootballQuizOption(
          koText: '월드컵 조별리그 승점을 4점으로 바꿨다',
          enText: 'It changed World Cup group-stage wins to four points',
        ),
        _FootballQuizOption(
          koText: '골키퍼 장갑 착용을 금지했다',
          enText: 'It banned goalkeeper gloves',
        ),
      ],
      correctIndex: 0,
      koExplain: '보스만 판결은 경기장 밖의 법적 결정이 이적시장과 선수 권리에 얼마나 큰 영향을 줄 수 있는지 보여줍니다.',
      enExplain:
          'Bosman shows how an off-field legal decision can reshape transfers and player rights.',
      koNextPoint: '축구 산업 문제는 규정, 계약, 클럽 운영을 함께 연결하세요.',
      enNextPoint:
          'For football-industry questions, connect rules, contracts, and club operations.',
    ),
    _McqSeed(
      id: 'history_back_pass_law_goal',
      difficulty: 2,
      category: _QuizCategory.rules,
      koStem: '1992년 백패스 규정 변화가 경기 흐름에 준 대표적 효과는 무엇일까요?',
      enStem: 'What was a key effect of the 1992 back-pass law on match flow?',
      options: [
        _FootballQuizOption(
          koText: '시간 지연을 줄이고 골키퍼의 발기술과 빌드업 역할을 키웠다',
          enText:
              'It reduced time-wasting and increased goalkeeper footwork and build-up demands',
        ),
        _FootballQuizOption(
          koText: '골키퍼가 손으로 득점할 수 있게 했다',
          enText: 'It allowed goalkeepers to score with their hands',
        ),
        _FootballQuizOption(
          koText: '수비수의 패스를 모두 간접 프리킥으로 만들었다',
          enText: 'It made every defender pass an indirect free kick',
        ),
        _FootballQuizOption(
          koText: '하프타임 시간을 없앴다',
          enText: 'It removed halftime',
        ),
      ],
      correctIndex: 0,
      koExplain: '백패스 규정은 골키퍼가 단순히 잡는 역할에서 발로 압박을 푸는 역할까지 요구받게 한 변화입니다.',
      enExplain:
          'The law helped push goalkeepers from pure handlers toward active build-up participants.',
      koNextPoint: '규칙 변화는 새 기술 요구와 연결해서 기억하세요.',
      enNextPoint:
          'Remember rules changes by linking them to new technical demands.',
    ),
    _McqSeed(
      id: 'history_match_of_century',
      difficulty: 3,
      category: _QuizCategory.fun,
      koStem: '1953년 “세기의 경기”로 불리는 잉글랜드 대 헝가리전이 상징하는 역사적 의미는?',
      enStem:
          'What historical meaning is attached to England vs Hungary in 1953, often called the Match of the Century?',
      options: [
        _FootballQuizOption(
          koText: '고정 포지션 중심 사고가 유동적 움직임과 조합 앞에서 흔들린 장면',
          enText:
              'A fixed-position mindset was exposed by fluid movement and combinations',
        ),
        _FootballQuizOption(
          koText: '축구에서 처음 승부차기가 도입된 경기',
          enText: 'The first football match to use a penalty shootout',
        ),
        _FootballQuizOption(
          koText: '월드컵 결승전이 처음 실내에서 열린 경기',
          enText: 'The first World Cup final played indoors',
        ),
        _FootballQuizOption(
          koText: '여자 월드컵의 첫 결승전',
          enText: 'The first Women’s World Cup final',
        ),
      ],
      correctIndex: 0,
      koExplain: '헝가리의 움직임과 공격 조합은 당시 잉글랜드식 전통 이해에 큰 충격을 줬습니다.',
      enExplain:
          'Hungary’s movement and attacking combinations strongly challenged traditional English assumptions.',
      koNextPoint: '역사적 경기의 점수보다 그 경기 이후 무엇을 다시 생각하게 됐는지를 보세요.',
      enNextPoint:
          'For historic matches, ask what the match forced people to rethink.',
    ),
    _McqSeed(
      id: 'history_lisbon_lions',
      difficulty: 3,
      category: _QuizCategory.fun,
      koStem: '1967년 셀틱 “리스본 라이언스”가 유럽컵 역사에서 자주 언급되는 이유는?',
      enStem:
          'Why are Celtic’s 1967 “Lisbon Lions” often mentioned in European Cup history?',
      options: [
        _FootballQuizOption(
          koText: '영국 클럽으로는 처음 유럽컵을 우승한 상징적 팀이기 때문',
          enText:
              'They were the first British club side to win the European Cup',
        ),
        _FootballQuizOption(
          koText: '월드컵을 클럽팀이 우승했기 때문',
          enText: 'They were a club team that won the World Cup',
        ),
        _FootballQuizOption(
          koText: '승부차기 없이 모든 경기가 무승부였기 때문',
          enText: 'Every match was a draw without penalties',
        ),
        _FootballQuizOption(
          koText: '골키퍼 없이 우승했기 때문',
          enText: 'They won without using a goalkeeper',
        ),
      ],
      correctIndex: 0,
      koExplain: '셀틱의 1967년 유럽컵 우승은 영국 클럽 축구와 유럽 대회 역사에서 중요한 기준점입니다.',
      enExplain:
          'Celtic’s 1967 European Cup win is a major landmark for British club football in Europe.',
      koNextPoint: '클럽 역사 문제는 첫 우승과 대륙 대회 맥락을 함께 보세요.',
      enNextPoint:
          'For club history, connect first titles with continental context.',
    ),
    _McqSeed(
      id: 'history_ajax_1995_identity',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koStem: '1995년 아약스 챔피언스리그 우승팀을 전술사적으로 볼 때 핵심 키워드는?',
      enStem:
          'When reading Ajax’s 1995 Champions League-winning side tactically, which keyword fits best?',
      options: [
        _FootballQuizOption(
          koText: '유스 기반, 위치 교대, 강한 압박을 결합한 팀 구조',
          enText:
              'A youth-based team structure combining rotations and strong pressing',
        ),
        _FootballQuizOption(
          koText: '중앙선을 넘지 않는 완전 후퇴 수비',
          enText: 'A permanently deep block that never crossed halfway',
        ),
        _FootballQuizOption(
          koText: '골키퍼의 롱킥만으로 공격하는 방식',
          enText: 'An attack based only on goalkeeper long kicks',
        ),
        _FootballQuizOption(
          koText: '선수 전원이 같은 포지션에서만 뛰는 구조',
          enText: 'Every player staying in one identical position',
        ),
      ],
      correctIndex: 0,
      koExplain: '1995년 아약스는 유스, 팀 원칙, 압박과 점유의 결합으로 현대적 팀 모델의 사례로 자주 언급됩니다.',
      enExplain:
          'Ajax 1995 is often cited as a modern team model built on youth, team principles, pressing, and possession.',
      koNextPoint: '명문 팀 역사는 우승보다 어떤 팀 모델을 보여줬는지를 함께 보세요.',
      enNextPoint:
          'For great teams, study the model they showed as well as the trophy.',
    ),
    _McqSeed(
      id: 'history_denmark_1992_lesson',
      difficulty: 2,
      category: _QuizCategory.mindset,
      koStem: '덴마크의 유로 1992 우승에서 팀 스포츠 관점으로 배울 수 있는 점은?',
      enStem:
          'From a team-sport perspective, what lesson fits Denmark winning Euro 1992?',
      options: [
        _FootballQuizOption(
          koText: '짧은 준비에도 역할 명확성, 응집력, 토너먼트 대응이 큰 힘이 될 수 있다',
          enText:
              'Role clarity, cohesion, and tournament response can matter even with short preparation',
        ),
        _FootballQuizOption(
          koText: '우승팀은 항상 가장 긴 준비 기간을 가진다',
          enText: 'The champion always has the longest preparation period',
        ),
        _FootballQuizOption(
          koText: '토너먼트에서는 조직력이 필요 없다',
          enText: 'Organization does not matter in tournaments',
        ),
        _FootballQuizOption(
          koText: '교체 선수는 경기 흐름에 영향을 줄 수 없다',
          enText: 'Substitutes cannot affect tournament momentum',
        ),
      ],
      correctIndex: 0,
      koExplain: '덴마크의 사례는 스타 이름보다 팀 역할, 수비 조직, 흐름 대응이 얼마나 중요한지 보여줍니다.',
      enExplain:
          'Denmark’s run highlights roles, organization, and response to momentum more than star names alone.',
      koNextPoint: '역사 퀴즈도 선수 이름 암기에서 팀 원리로 확장해 보세요.',
      enNextPoint:
          'Use history questions to move from names toward team principles.',
    ),
    _McqSeed(
      id: 'history_womens_world_cup_1999_impact',
      difficulty: 2,
      category: _QuizCategory.fun,
      koStem: '1999년 FIFA 여자 월드컵 결승이 축구 역사에서 갖는 의미로 가장 알맞은 것은?',
      enStem:
          'What is the best historical meaning of the 1999 FIFA Women’s World Cup final?',
      options: [
        _FootballQuizOption(
          koText: '여자축구의 대중적 가시성과 큰 무대 서사를 크게 키운 경기',
          enText:
              'A match that greatly increased women’s football visibility and big-stage narrative',
        ),
        _FootballQuizOption(
          koText: '남자 월드컵이 처음 시작된 경기',
          enText: 'The match where the men’s World Cup first began',
        ),
        _FootballQuizOption(
          koText: '클럽 월드컵 결승의 첫 경기',
          enText: 'The first Club World Cup final',
        ),
        _FootballQuizOption(
          koText: '오프사이드 규칙이 폐지된 경기',
          enText: 'The match where offside was abolished',
        ),
      ],
      correctIndex: 0,
      koExplain: '미국과 중국의 결승전은 경기장 규모, 승부차기, 문화적 파급력까지 여자축구사의 큰 장면입니다.',
      enExplain:
          'USA vs China in 1999 is remembered for scale, penalties, and cultural reach in women’s football history.',
      koNextPoint: '역사적 결승은 경기 내용과 사회적 파급을 함께 보세요.',
      enNextPoint:
          'For historic finals, study both the match and its wider impact.',
    ),
  ];
}

List<_ShortAnswerKnowledgeSeed> _advancedFootballHistoryShortAnswerSeeds() {
  return const [
    _ShortAnswerKnowledgeSeed(
      id: 'history_bosman_ruling',
      difficulty: 3,
      category: _QuizCategory.fun,
      koClue: '계약 만료 선수의 이동 자유와 유럽 클럽 스쿼드 구성에 큰 영향을 준 1995년 판결',
      enClue:
          '1995 ruling that strongly affected out-of-contract player movement and European squad building',
      acceptedAnswers: ['보스만 판결', 'bosman ruling', 'bosman'],
      koExplain: '정답은 "보스만 판결"입니다. 축구사에서 선수 권리와 이적시장 구조를 바꾼 핵심 사건입니다.',
      enExplain:
          'The answer is "Bosman ruling." It reshaped player rights and the transfer market.',
      koNextPoint: '축구 역사는 경기 규칙뿐 아니라 계약과 노동권의 변화도 포함합니다.',
      enNextPoint:
          'Football history includes contracts and labor rights as well as match laws.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'history_back_pass_law',
      difficulty: 2,
      category: _QuizCategory.rules,
      koClue: '골키퍼가 동료의 의도적 발 패스를 손으로 잡지 못하게 한 1992년 규정 변화',
      enClue:
          '1992 law change stopping goalkeepers from handling a teammate’s deliberate pass by foot',
      acceptedAnswers: ['백패스 규정', '백패스 룰', 'back pass law', 'back-pass law'],
      koExplain: '정답은 "백패스 규정"입니다. 경기 속도와 골키퍼 빌드업 기술을 바꾼 규칙 변화입니다.',
      enExplain:
          'The answer is "back-pass law." It changed match tempo and goalkeeper build-up demands.',
      koNextPoint: '규칙 이름을 외운 뒤 어떤 플레이가 달라졌는지까지 연결하세요.',
      enNextPoint:
          'After learning the rule name, connect it to the play behavior it changed.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'history_total_football_term',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koClue: '1970년대 네덜란드와 아약스로 대표되며 위치 교대와 공간 점유가 핵심인 전술 사조',
      enClue:
          'Tactical idea linked with 1970s Netherlands and Ajax, built on rotations and space occupation',
      acceptedAnswers: ['토털 풋볼', '토탈 풋볼', 'total football'],
      koExplain: '정답은 "토털 풋볼"입니다. 유동적 위치 교대와 팀 원칙이 함께 작동하는 전술 역사 개념입니다.',
      enExplain:
          'The answer is "Total Football." It combines positional rotation with shared team principles.',
      koNextPoint: '전술사 용어는 대표 팀과 작동 원리를 한 문장으로 말해 보세요.',
      enNextPoint:
          'For tactical history terms, state the team and mechanism in one sentence.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'history_catenaccio_term',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koClue: '스위퍼 보호, 압축 수비, 빠른 전환과 연결되는 이탈리아식 빗장 수비 전술 용어',
      enClue:
          'Italian tactical term linked with sweeper cover, compact defending, and transition',
      acceptedAnswers: ['카테나치오', 'catenaccio'],
      koExplain: '정답은 "카테나치오"입니다. 단순히 내려서는 수비가 아니라 보호와 전환 구조로 이해해야 합니다.',
      enExplain:
          'The answer is "catenaccio." It is about cover and transition structure, not only sitting deep.',
      koNextPoint: '수비 전술은 막는 위치와 뺏은 뒤 나가는 길을 함께 보세요.',
      enNextPoint:
          'For defensive tactics, connect the block with the exit after regaining the ball.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'history_wm_formation',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koClue: '오프사이드 법 변화 이후 20세기 초중반 축구 전술사에서 중요하게 다뤄지는 알파벳 이름의 포메이션',
      enClue:
          'Letter-named formation treated as a major early-20th-century tactical landmark after offside-law changes',
      acceptedAnswers: ['WM', 'wm', 'WM 포메이션', 'wm formation'],
      koExplain: '정답은 "WM 포메이션"입니다. 규칙 변화에 대응해 팀 구조를 재배치한 역사적 포메이션입니다.',
      enExplain:
          'The answer is "WM formation." It reorganized team shape in response to a law change.',
      koNextPoint: '포메이션은 숫자보다 그 시대의 문제 해결 방식으로 보세요.',
      enNextPoint:
          'View formations as era-specific solutions, not just shapes.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'history_lisbon_lions_term',
      difficulty: 3,
      category: _QuizCategory.fun,
      koClue: '1967년 유럽컵을 우승한 셀틱 팀을 부르는 별칭',
      enClue: 'Nickname for Celtic’s 1967 European Cup-winning team',
      acceptedAnswers: ['리스본 라이언스', 'lisbon lions'],
      koExplain: '정답은 "리스본 라이언스"입니다. 셀틱의 1967년 우승팀은 유럽 클럽 축구사의 상징적 팀입니다.',
      enExplain:
          'The answer is "Lisbon Lions." Celtic’s 1967 team is a landmark in European club history.',
      koNextPoint: '팀 별칭은 대회, 연도, 왜 기억되는지를 함께 묶어야 합니다.',
      enNextPoint:
          'Pair team nicknames with competition, year, and reason they matter.',
    ),
  ];
}

List<_OxFactSeed> _athleteNutritionOxFacts() {
  return const [
    _OxFactSeed(
      id: 'nutrition_energy_availability',
      difficulty: 3,
      category: _QuizCategory.nutrition,
      koTrueStatement: '운동선수는 체중을 줄이려는 시기에도 훈련량을 버틸 만큼의 에너지 가용성을 먼저 지켜야 한다.',
      enTrueStatement:
          'Even during weight-management phases, athletes need enough energy availability to support training load.',
      koFalseStatement: '운동선수는 컨디션과 회복이 떨어져도 식사량을 계속 줄이는 것이 항상 경기력에 유리하다.',
      enFalseStatement:
          'Athletes always perform better by reducing food intake even when recovery and readiness drop.',
      koExplain:
          '에너지 가용성이 낮아지면 회복, 적응, 건강 신호가 흔들릴 수 있어 식사 제한만으로 경기력을 보려 하면 위험합니다.',
      enExplain:
          'Low energy availability can disrupt recovery, adaptation, and health markers, so restriction alone is a poor performance plan.',
      koNextPoint: '식습관 문제는 체중보다 훈련 지속성과 회복 신호를 먼저 함께 보세요.',
      enNextPoint:
          'In nutrition questions, connect body weight with training continuity and recovery signs.',
    ),
    _OxFactSeed(
      id: 'nutrition_new_food_matchday',
      difficulty: 1,
      category: _QuizCategory.nutrition,
      koTrueStatement: '중요한 경기 당일에는 처음 먹어보는 음식보다 평소 훈련 때 검증한 식사를 고르는 편이 안전하다.',
      enTrueStatement:
          'On an important matchday, familiar foods tested in training are safer than new foods.',
      koFalseStatement: '중요한 경기 당일일수록 몸 반응을 모르는 새 음식으로 식단을 크게 바꾸는 편이 좋다.',
      enFalseStatement:
          'On important matchdays, it is best to make major food changes with unfamiliar foods.',
      koExplain: '경기 전 식사는 에너지뿐 아니라 소화 안정성이 중요하므로 새 메뉴 실험은 훈련일에 먼저 해야 합니다.',
      enExplain:
          'Prematch eating is about energy and gut comfort, so new foods should be tested on training days first.',
      koNextPoint: '경기 전 식사는 새로움보다 익숙함, 소화, 타이밍을 우선하세요.',
      enNextPoint:
          'Prematch meals should prioritize familiarity, digestion, and timing over novelty.',
    ),
    _OxFactSeed(
      id: 'nutrition_supplement_risk',
      difficulty: 3,
      category: _QuizCategory.nutrition,
      koTrueStatement: '보충제는 효과, 안전성, 금지약물 위험을 확인한 뒤 필요한 경우 전문가와 상의해 쓰는 편이 좋다.',
      enTrueStatement:
          'Supplements should be checked for effectiveness, safety, and anti-doping risk, ideally with expert guidance.',
      koFalseStatement: '보충제는 매장이나 온라인에서 팔리고 있으면 운동선수에게 항상 안전하고 경기 규정상 문제도 없다.',
      enFalseStatement:
          'If a supplement is sold in stores or online, it is always safe and permitted for athletes.',
      koExplain:
          '보충제는 표시 성분과 실제 성분이 다르거나 금지 성분 오염 위험이 있을 수 있어 음식 우선 원칙과 검증이 필요합니다.',
      enExplain:
          'Supplement labels may not fully match contents and contamination risk can exist, so food-first thinking and verification matter.',
      koNextPoint: '보충제 문항은 “효과가 있나”뿐 아니라 “안전하고 허용되나”까지 묻습니다.',
      enNextPoint:
          'Supplement questions should ask not only whether it works, but whether it is safe and permitted.',
    ),
  ];
}

List<_McqSeed> _athleteNutritionMcqSeeds() {
  return const [
    _McqSeed(
      id: 'athlete_nutrition_prematch_plate',
      difficulty: 2,
      category: _QuizCategory.nutrition,
      koStem: '경기 3-4시간 전 식사 방향으로 가장 적절한 것은 무엇일까요?',
      enStem:
          'What is the most suitable meal direction around 3-4 hours before a match?',
      options: [
        _FootballQuizOption(
          koText: '익숙하고 소화가 쉬운 탄수화물 중심 식사에 수분을 함께 챙긴다',
          enText:
              'Choose familiar, digestible carbohydrate-focused food with fluids',
        ),
        _FootballQuizOption(
          koText: '기름지고 섬유질 많은 새 음식을 많이 시험한다',
          enText: 'Test a large new meal high in fat and fiber',
        ),
        _FootballQuizOption(
          koText: '물을 끊고 경기 직전 한 번에 많이 마신다',
          enText: 'Avoid fluids and drink a lot only right before kickoff',
        ),
        _FootballQuizOption(
          koText: '식사를 모두 빼고 에너지 음료만 마신다',
          enText: 'Skip food and rely only on an energy drink',
        ),
      ],
      correctIndex: 0,
      koExplain: '경기 전 식사는 위장 부담을 줄이면서 쓸 에너지를 준비해야 하므로 익숙한 탄수화물과 수분 계획이 기본입니다.',
      enExplain:
          'A prematch meal should prepare usable energy while limiting gut stress, so familiar carbohydrates and fluids are the base.',
      koNextPoint: '경기 전 식사는 음식 종류, 양, 시간을 훈련 때 미리 테스트하세요.',
      enNextPoint:
          'Test prematch food type, amount, and timing during training first.',
    ),
    _McqSeed(
      id: 'athlete_nutrition_recovery_window',
      difficulty: 2,
      category: _QuizCategory.nutrition,
      koStem: '강한 훈련 직후 회복식에서 가장 먼저 맞춰야 할 조합은?',
      enStem:
          'After a hard session, which recovery-meal combination should be prioritized first?',
      options: [
        _FootballQuizOption(
          koText: '탄수화물, 단백질, 수분을 함께 보충한다',
          enText: 'Refuel with carbohydrates, protein, and fluids together',
        ),
        _FootballQuizOption(
          koText: '단맛 간식만 먹고 물은 다음 날 마신다',
          enText: 'Eat only sweets and leave fluids until the next day',
        ),
        _FootballQuizOption(
          koText: '단백질만 먹고 탄수화물은 항상 피한다',
          enText: 'Take only protein and always avoid carbohydrates',
        ),
        _FootballQuizOption(
          koText: '배고픔이 사라질 때까지 아무것도 먹지 않는다',
          enText: 'Eat nothing until hunger disappears',
        ),
      ],
      correctIndex: 0,
      koExplain: '회복식은 글리코겐 회복, 근육 회복, 수분 회복을 한 번에 설계해야 다음 세션 질을 지키기 쉽습니다.',
      enExplain:
          'Recovery eating should cover glycogen restoration, muscle repair, and fluid replacement to protect the next session.',
      koNextPoint: '회복식은 한 가지 영양소보다 다음 훈련을 위한 전체 루틴으로 보세요.',
      enNextPoint:
          'View recovery eating as a full routine for the next session, not a single nutrient.',
    ),
    _McqSeed(
      id: 'athlete_nutrition_long_session_fuel',
      difficulty: 3,
      category: _QuizCategory.nutrition,
      koStem: '90분 이상 이어지는 고강도 훈련이나 경기에서 식습관 판단으로 가장 좋은 것은?',
      enStem:
          'For hard training or competition lasting longer than about 90 minutes, what nutrition judgment fits best?',
      options: [
        _FootballQuizOption(
          koText: '수분과 함께 필요한 경우 탄수화물 보충을 미리 계획한다',
          enText:
              'Plan fluids and, when needed, carbohydrate intake before the session',
        ),
        _FootballQuizOption(
          koText: '갈증과 피로가 심해질 때까지 아무 계획 없이 기다린다',
          enText: 'Wait with no plan until thirst and fatigue are severe',
        ),
        _FootballQuizOption(
          koText: '훈련 중에는 어떤 경우에도 탄수화물을 먹지 않는다',
          enText: 'Never take carbohydrate during training under any condition',
        ),
        _FootballQuizOption(
          koText: '운동 전 소금기 있는 음식만 많이 먹으면 충분하다',
          enText: 'A large salty meal before exercise is always enough',
        ),
      ],
      correctIndex: 0,
      koExplain:
          '긴 고강도 운동에서는 에너지와 수분을 동시에 잃기 쉬워 세션 시간, 강도, 환경에 맞춘 연료 계획이 필요합니다.',
      enExplain:
          'Long hard sessions can drain fuel and fluids together, so intake should match duration, intensity, and environment.',
      koNextPoint: '운동 중 영양은 시간, 강도, 더위, 개인 위장 반응을 같이 봅니다.',
      enNextPoint:
          'During-exercise nutrition should combine duration, intensity, heat, and individual gut response.',
    ),
    _McqSeed(
      id: 'athlete_nutrition_iron_red_flags',
      difficulty: 3,
      category: _QuizCategory.nutrition,
      koStem: '피로가 길고 회복이 느리며 식사를 자주 제한하는 선수에게 가장 성숙한 접근은?',
      enStem:
          'If an athlete has persistent fatigue, slow recovery, and frequent food restriction, what is the most mature response?',
      options: [
        _FootballQuizOption(
          koText: '코치, 보호자, 의무/영양 전문가와 에너지 섭취와 건강 신호를 점검한다',
          enText:
              'Review energy intake and health signs with coaches, guardians, and medical or nutrition professionals',
        ),
        _FootballQuizOption(
          koText: '더 강한 훈련으로 피로를 무조건 밀어붙인다',
          enText: 'Push harder training regardless of the fatigue',
        ),
        _FootballQuizOption(
          koText: '회복이 늦으면 식사량을 더 줄인다',
          enText: 'Reduce food intake further when recovery slows',
        ),
        _FootballQuizOption(
          koText: '컨디션 기록 없이 체중 숫자만 본다',
          enText: 'Track only body weight and ignore readiness records',
        ),
      ],
      correctIndex: 0,
      koExplain:
          '지속 피로와 식사 제한은 낮은 에너지 가용성 신호일 수 있어 건강과 경기력을 함께 보호하는 점검이 필요합니다.',
      enExplain:
          'Persistent fatigue plus restriction can signal low energy availability, so health and performance should be reviewed together.',
      koNextPoint: '식습관 학습은 체중 관리보다 건강 신호, 회복, 지속 가능한 훈련을 우선합니다.',
      enNextPoint:
          'Nutrition learning should prioritize health signs, recovery, and sustainable training over weight alone.',
    ),
  ];
}

List<_ShortAnswerKnowledgeSeed> _athleteNutritionShortAnswerSeeds() {
  return const [
    _ShortAnswerKnowledgeSeed(
      id: 'nutrition_energy_availability_term',
      difficulty: 3,
      category: _QuizCategory.nutrition,
      koClue: '운동과 일상 생리 기능을 모두 버틸 만큼 몸에 남는 에너지 상태를 뜻하는 스포츠 영양 개념',
      enClue:
          'Sports nutrition concept describing enough remaining energy to support exercise and normal body functions',
      acceptedAnswers: [
        '에너지 가용성',
        'energy availability',
        'available energy',
      ],
      koExplain: '정답은 "에너지 가용성"입니다. 식사량, 훈련량, 회복 신호를 함께 볼 때 중요한 개념입니다.',
      enExplain:
          'The answer is "energy availability." It links intake, training load, and recovery signs.',
      koNextPoint: '영양 용어는 몸무게보다 훈련을 버틸 에너지가 남는지로 이해하세요.',
      enNextPoint:
          'Understand nutrition terms through whether enough energy remains for training and health.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'nutrition_electrolyte_term',
      difficulty: 2,
      category: _QuizCategory.nutrition,
      koClue: '땀을 많이 흘리는 더운 날 수분과 함께 고려해야 하는 나트륨 등 체액 균형 관련 성분',
      enClue:
          'Fluid-balance minerals such as sodium that may matter with fluids on hot, sweaty days',
      acceptedAnswers: ['전해질', 'electrolyte', 'electrolytes'],
      koExplain: '정답은 "전해질"입니다. 더운 환경이나 긴 운동에서는 물만이 아니라 손실되는 전해질도 고려할 수 있습니다.',
      enExplain:
          'The answer is "electrolytes." In long or hot sessions, fluid planning may also consider electrolyte losses.',
      koNextPoint: '수분 전략은 물, 땀 양, 더위, 운동 시간을 함께 연결하세요.',
      enNextPoint:
          'Hydration strategy links water, sweat rate, heat, and session length.',
    ),
  ];
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
    (
      id: 'martinez_gk',
      koName: '에밀리아노 마르티네스',
      enName: 'Emiliano Martinez',
      koPosition: '골키퍼',
      enPosition: 'Goalkeeper',
      koNation: '아르헨티나',
      enNation: 'Argentina',
    ),
    (
      id: 'onana',
      koName: '안드레 오나나',
      enName: 'Andre Onana',
      koPosition: '골키퍼',
      enPosition: 'Goalkeeper',
      koNation: '카메룬',
      enNation: 'Cameroon',
    ),
    (
      id: 'camavinga',
      koName: '에두아르도 카마빙가',
      enName: 'Eduardo Camavinga',
      koPosition: '중앙 미드필더',
      enPosition: 'Central Midfielder',
      koNation: '프랑스',
      enNation: 'France',
    ),
    (
      id: 'tchouameni',
      koName: '오렐리앙 추아메니',
      enName: 'Aurelien Tchouameni',
      koPosition: '수비형 미드필더',
      enPosition: 'Defensive Midfielder',
      koNation: '프랑스',
      enNation: 'France',
    ),
    (
      id: 'carvajal',
      koName: '다니 카르바할',
      enName: 'Dani Carvajal',
      koPosition: '풀백',
      enPosition: 'Full Back',
      koNation: '스페인',
      enNation: 'Spain',
    ),
    (
      id: 'rudiger',
      koName: '안토니오 뤼디거',
      enName: 'Antonio Rudiger',
      koPosition: '센터백',
      enPosition: 'Center Back',
      koNation: '독일',
      enNation: 'Germany',
    ),
    (
      id: 'araujo',
      koName: '로날드 아라우호',
      enName: 'Ronald Araujo',
      koPosition: '센터백',
      enPosition: 'Center Back',
      koNation: '우루과이',
      enNation: 'Uruguay',
    ),
    (
      id: 'frenkie',
      koName: '프렝키 더용',
      enName: 'Frenkie de Jong',
      koPosition: '중앙 미드필더',
      enPosition: 'Central Midfielder',
      koNation: '네덜란드',
      enNation: 'Netherlands',
    ),
    (
      id: 'raphinha',
      koName: '하피냐',
      enName: 'Raphinha',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '브라질',
      enNation: 'Brazil',
    ),
    (
      id: 'leao',
      koName: '하파엘 레앙',
      enName: 'Rafael Leao',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '포르투갈',
      enNation: 'Portugal',
    ),
    (
      id: 'barella',
      koName: '니콜로 바렐라',
      enName: 'Nicolo Barella',
      koPosition: '중앙 미드필더',
      enPosition: 'Central Midfielder',
      koNation: '이탈리아',
      enNation: 'Italy',
    ),
    (
      id: 'bastoni',
      koName: '알레산드로 바스토니',
      enName: 'Alessandro Bastoni',
      koPosition: '센터백',
      enPosition: 'Center Back',
      koNation: '이탈리아',
      enNation: 'Italy',
    ),
    (
      id: 'dimarco',
      koName: '페데리코 디마르코',
      enName: 'Federico Dimarco',
      koPosition: '풀백',
      enPosition: 'Full Back',
      koNation: '이탈리아',
      enNation: 'Italy',
    ),
    (
      id: 'chiesa',
      koName: '페데리코 키에사',
      enName: 'Federico Chiesa',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '이탈리아',
      enNation: 'Italy',
    ),
    (
      id: 'vlahovic',
      koName: '두산 블라호비치',
      enName: 'Dusan Vlahovic',
      koPosition: '스트라이커',
      enPosition: 'Striker',
      koNation: '세르비아',
      enNation: 'Serbia',
    ),
    (
      id: 'donnarumma',
      koName: '잔루이지 돈나룸마',
      enName: 'Gianluigi Donnarumma',
      koPosition: '골키퍼',
      enPosition: 'Goalkeeper',
      koNation: '이탈리아',
      enNation: 'Italy',
    ),
    (
      id: 'kobbie_mainoo',
      koName: '코비 마이누',
      enName: 'Kobbie Mainoo',
      koPosition: '중앙 미드필더',
      enPosition: 'Central Midfielder',
      koNation: '잉글랜드',
      enNation: 'England',
    ),
    (
      id: 'lisandro',
      koName: '리산드로 마르티네스',
      enName: 'Lisandro Martinez',
      koPosition: '센터백',
      enPosition: 'Center Back',
      koNation: '아르헨티나',
      enNation: 'Argentina',
    ),
    (
      id: 'garnacho',
      koName: '알레한드로 가르나초',
      enName: 'Alejandro Garnacho',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '아르헨티나',
      enNation: 'Argentina',
    ),
    (
      id: 'isak',
      koName: '알렉산데르 이사크',
      enName: 'Alexander Isak',
      koPosition: '스트라이커',
      enPosition: 'Striker',
      koNation: '스웨덴',
      enNation: 'Sweden',
    ),
    (
      id: 'bruno_guimaraes',
      koName: '브루누 기마랑이스',
      enName: 'Bruno Guimaraes',
      koPosition: '중앙 미드필더',
      enPosition: 'Central Midfielder',
      koNation: '브라질',
      enNation: 'Brazil',
    ),
    (
      id: 'trippier',
      koName: '키어런 트리피어',
      enName: 'Kieran Trippier',
      koPosition: '풀백',
      enPosition: 'Full Back',
      koNation: '잉글랜드',
      enNation: 'England',
    ),
    (
      id: 'saliba',
      koName: '윌리엄 살리바',
      enName: 'William Saliba',
      koPosition: '센터백',
      enPosition: 'Center Back',
      koNation: '프랑스',
      enNation: 'France',
    ),
    (
      id: 'gabriel_magalhaes',
      koName: '가브리엘 마갈량이스',
      enName: 'Gabriel Magalhaes',
      koPosition: '센터백',
      enPosition: 'Center Back',
      koNation: '브라질',
      enNation: 'Brazil',
    ),
    (
      id: 'martinelli',
      koName: '가브리에우 마르티넬리',
      enName: 'Gabriel Martinelli',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '브라질',
      enNation: 'Brazil',
    ),
    (
      id: 'kai_havertz',
      koName: '카이 하베르츠',
      enName: 'Kai Havertz',
      koPosition: '공격형 미드필더',
      enPosition: 'Attacking Midfielder',
      koNation: '독일',
      enNation: 'Germany',
    ),
    (
      id: 'szoboszlai',
      koName: '도미니크 소보슬라이',
      enName: 'Dominik Szoboszlai',
      koPosition: '공격형 미드필더',
      enPosition: 'Attacking Midfielder',
      koNation: '헝가리',
      enNation: 'Hungary',
    ),
    (
      id: 'mac_allister',
      koName: '알렉시스 맥 알리스터',
      enName: 'Alexis Mac Allister',
      koPosition: '중앙 미드필더',
      enPosition: 'Central Midfielder',
      koNation: '아르헨티나',
      enNation: 'Argentina',
    ),
    (
      id: 'enzo_millot',
      koName: '엔조 미요',
      enName: 'Enzo Millot',
      koPosition: '공격형 미드필더',
      enPosition: 'Attacking Midfielder',
      koNation: '프랑스',
      enNation: 'France',
    ),
    (
      id: 'hincapie',
      koName: '피에로 인카피에',
      enName: 'Piero Hincapie',
      koPosition: '센터백',
      enPosition: 'Center Back',
      koNation: '에콰도르',
      enNation: 'Ecuador',
    ),
    (
      id: 'frimpong',
      koName: '제레미 프림퐁',
      enName: 'Jeremie Frimpong',
      koPosition: '풀백',
      enPosition: 'Full Back',
      koNation: '네덜란드',
      enNation: 'Netherlands',
    ),
    (
      id: 'boniface',
      koName: '빅터 보니페이스',
      enName: 'Victor Boniface',
      koPosition: '스트라이커',
      enPosition: 'Striker',
      koNation: '나이지리아',
      enNation: 'Nigeria',
    ),
    (
      id: 'joao_neves',
      koName: '주앙 네베스',
      enName: 'Joao Neves',
      koPosition: '중앙 미드필더',
      enPosition: 'Central Midfielder',
      koNation: '포르투갈',
      enNation: 'Portugal',
    ),
    (
      id: 'diogo_costa',
      koName: '디오구 코스타',
      enName: 'Diogo Costa',
      koPosition: '골키퍼',
      enPosition: 'Goalkeeper',
      koNation: '포르투갈',
      enNation: 'Portugal',
    ),
    (
      id: 'mitoma',
      koName: '미토마 카오루',
      enName: 'Kaoru Mitoma',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '일본',
      enNation: 'Japan',
    ),
    (
      id: 'kubotakefusa',
      koName: '구보 다케후사',
      enName: 'Takefusa Kubo',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '일본',
      enNation: 'Japan',
    ),
    (
      id: 'kimminjae',
      koName: '김민재',
      enName: 'Kim Min-jae',
      koPosition: '센터백',
      enPosition: 'Center Back',
      koNation: '대한민국',
      enNation: 'South Korea',
    ),
    (
      id: 'hwangheechan',
      koName: '황희찬',
      enName: 'Hwang Hee-chan',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '대한민국',
      enNation: 'South Korea',
    ),
    (
      id: 'kanginlee',
      koName: '이강인',
      enName: 'Lee Kang-in',
      koPosition: '공격형 미드필더',
      enPosition: 'Attacking Midfielder',
      koNation: '대한민국',
      enNation: 'South Korea',
    ),
    (
      id: 'choiguesung',
      koName: '조규성',
      enName: 'Cho Gue-sung',
      koPosition: '스트라이커',
      enPosition: 'Striker',
      koNation: '대한민국',
      enNation: 'South Korea',
    ),
    (
      id: 'ferland_mendy',
      koName: '페를랑 멘디',
      enName: 'Ferland Mendy',
      koPosition: '풀백',
      enPosition: 'Full Back',
      koNation: '프랑스',
      enNation: 'France',
    ),
    (
      id: 'alphonso_mai',
      koName: '마이클 올리세',
      enName: 'Michael Olise',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '프랑스',
      enNation: 'France',
    ),
    (
      id: 'nico_williams',
      koName: '니코 윌리엄스',
      enName: 'Nico Williams',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '스페인',
      enNation: 'Spain',
    ),
    (
      id: 'morata',
      koName: '알바로 모라타',
      enName: 'Alvaro Morata',
      koPosition: '스트라이커',
      enPosition: 'Striker',
      koNation: '스페인',
      enNation: 'Spain',
    ),
    (
      id: 'olmo',
      koName: '다니 올모',
      enName: 'Dani Olmo',
      koPosition: '공격형 미드필더',
      enPosition: 'Attacking Midfielder',
      koNation: '스페인',
      enNation: 'Spain',
    ),
    (
      id: 'merino',
      koName: '미켈 메리노',
      enName: 'Mikel Merino',
      koPosition: '중앙 미드필더',
      enPosition: 'Central Midfielder',
      koNation: '스페인',
      enNation: 'Spain',
    ),
    (
      id: 'zubimendi',
      koName: '마르틴 수비멘디',
      enName: 'Martin Zubimendi',
      koPosition: '수비형 미드필더',
      enPosition: 'Defensive Midfielder',
      koNation: '스페인',
      enNation: 'Spain',
    ),
    (
      id: 'granit_xhaka',
      koName: '그라니트 자카',
      enName: 'Granit Xhaka',
      koPosition: '중앙 미드필더',
      enPosition: 'Central Midfielder',
      koNation: '스위스',
      enNation: 'Switzerland',
    ),
    (
      id: 'sommer',
      koName: '얀 조머',
      enName: 'Yann Sommer',
      koPosition: '골키퍼',
      enPosition: 'Goalkeeper',
      koNation: '스위스',
      enNation: 'Switzerland',
    ),
    (
      id: 'upamecano',
      koName: '다요 우파메카노',
      enName: 'Dayot Upamecano',
      koPosition: '센터백',
      enPosition: 'Center Back',
      koNation: '프랑스',
      enNation: 'France',
    ),
    (
      id: 'konate',
      koName: '이브라히마 코나테',
      enName: 'Ibrahima Konate',
      koPosition: '센터백',
      enPosition: 'Center Back',
      koNation: '프랑스',
      enNation: 'France',
    ),
    (
      id: 'diaby',
      koName: '무사 디아비',
      enName: 'Moussa Diaby',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '프랑스',
      enNation: 'France',
    ),
    (
      id: 'nkunku',
      koName: '크리스토퍼 은쿤쿠',
      enName: 'Christopher Nkunku',
      koPosition: '공격형 미드필더',
      enPosition: 'Attacking Midfielder',
      koNation: '프랑스',
      enNation: 'France',
    ),
    (
      id: 'kolo_muani',
      koName: '랑달 콜로 무아니',
      enName: 'Randal Kolo Muani',
      koPosition: '스트라이커',
      enPosition: 'Striker',
      koNation: '프랑스',
      enNation: 'France',
    ),
    (
      id: 'coman',
      koName: '킹슬리 코망',
      enName: 'Kingsley Coman',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '프랑스',
      enNation: 'France',
    ),
    (
      id: 'onana_mid',
      koName: '아마두 오나나',
      enName: 'Amadou Onana',
      koPosition: '수비형 미드필더',
      enPosition: 'Defensive Midfielder',
      koNation: '벨기에',
      enNation: 'Belgium',
    ),
    (
      id: 'tielemans',
      koName: '유리 틸레만스',
      enName: 'Youri Tielemans',
      koPosition: '중앙 미드필더',
      enPosition: 'Central Midfielder',
      koNation: '벨기에',
      enNation: 'Belgium',
    ),
    (
      id: 'lukaku',
      koName: '로멜루 루카쿠',
      enName: 'Romelu Lukaku',
      koPosition: '스트라이커',
      enPosition: 'Striker',
      koNation: '벨기에',
      enNation: 'Belgium',
    ),
    (
      id: 'depay',
      koName: '멤피스 데파이',
      enName: 'Memphis Depay',
      koPosition: '스트라이커',
      enPosition: 'Striker',
      koNation: '네덜란드',
      enNation: 'Netherlands',
    ),
    (
      id: 'dumfries',
      koName: '덴젤 둠프리스',
      enName: 'Denzel Dumfries',
      koPosition: '풀백',
      enPosition: 'Full Back',
      koNation: '네덜란드',
      enNation: 'Netherlands',
    ),
    (
      id: 'de_ligt',
      koName: '마타이스 더리흐트',
      enName: 'Matthijs de Ligt',
      koPosition: '센터백',
      enPosition: 'Center Back',
      koNation: '네덜란드',
      enNation: 'Netherlands',
    ),
    (
      id: 'zinschenko',
      koName: '올렉산드르 진첸코',
      enName: 'Oleksandr Zinchenko',
      koPosition: '풀백',
      enPosition: 'Full Back',
      koNation: '우크라이나',
      enNation: 'Ukraine',
    ),
    (
      id: 'mudryk',
      koName: '미하일로 무드리크',
      enName: 'Mykhailo Mudryk',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '우크라이나',
      enNation: 'Ukraine',
    ),
    (
      id: 'brozovic',
      koName: '마르첼로 브로조비치',
      enName: 'Marcelo Brozovic',
      koPosition: '수비형 미드필더',
      enPosition: 'Defensive Midfielder',
      koNation: '크로아티아',
      enNation: 'Croatia',
    ),
    (
      id: 'kovacic',
      koName: '마테오 코바치치',
      enName: 'Mateo Kovacic',
      koPosition: '중앙 미드필더',
      enPosition: 'Central Midfielder',
      koNation: '크로아티아',
      enNation: 'Croatia',
    ),
    (
      id: 'perisic',
      koName: '이반 페리시치',
      enName: 'Ivan Perisic',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '크로아티아',
      enNation: 'Croatia',
    ),
    (
      id: 'jimenez',
      koName: '라울 히메네스',
      enName: 'Raul Jimenez',
      koPosition: '스트라이커',
      enPosition: 'Striker',
      koNation: '멕시코',
      enNation: 'Mexico',
    ),
    (
      id: 'pulisic',
      koName: '크리스천 풀리시치',
      enName: 'Christian Pulisic',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '미국',
      enNation: 'United States',
    ),
    (
      id: 'mckennie',
      koName: '웨스턴 맥케니',
      enName: 'Weston McKennie',
      koPosition: '중앙 미드필더',
      enPosition: 'Central Midfielder',
      koNation: '미국',
      enNation: 'United States',
    ),
    (
      id: 'davinson_sanchez',
      koName: '다빈손 산체스',
      enName: 'Davinson Sanchez',
      koPosition: '센터백',
      enPosition: 'Center Back',
      koNation: '콜롬비아',
      enNation: 'Colombia',
    ),
    (
      id: 'luis_diaz',
      koName: '루이스 디아스',
      enName: 'Luis Diaz',
      koPosition: '윙어',
      enPosition: 'Winger',
      koNation: '콜롬비아',
      enNation: 'Colombia',
    ),
    (
      id: 'james_rodriguez',
      koName: '하메스 로드리게스',
      enName: 'James Rodriguez',
      koPosition: '공격형 미드필더',
      enPosition: 'Attacking Midfielder',
      koNation: '콜롬비아',
      enNation: 'Colombia',
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
    (
      id: 'newcastle',
      koName: '뉴캐슬 유나이티드',
      enName: 'Newcastle United',
      koLeague: '프리미어리그',
      enLeague: 'Premier League',
    ),
    (
      id: 'astonvilla',
      koName: '아스톤 빌라',
      enName: 'Aston Villa',
      koLeague: '프리미어리그',
      enLeague: 'Premier League',
    ),
    (
      id: 'brighton',
      koName: '브라이턴',
      enName: 'Brighton',
      koLeague: '프리미어리그',
      enLeague: 'Premier League',
    ),
    (
      id: 'westham',
      koName: '웨스트햄',
      enName: 'West Ham United',
      koLeague: '프리미어리그',
      enLeague: 'Premier League',
    ),
    (
      id: 'sevilla',
      koName: '세비야',
      enName: 'Sevilla',
      koLeague: '라리가',
      enLeague: 'LaLiga',
    ),
    (
      id: 'real_sociedad',
      koName: '레알 소시에다드',
      enName: 'Real Sociedad',
      koLeague: '라리가',
      enLeague: 'LaLiga',
    ),
    (
      id: 'betis',
      koName: '레알 베티스',
      enName: 'Real Betis',
      koLeague: '라리가',
      enLeague: 'LaLiga',
    ),
    (
      id: 'girona',
      koName: '지로나',
      enName: 'Girona',
      koLeague: '라리가',
      enLeague: 'LaLiga',
    ),
    (
      id: 'rb_leipzig',
      koName: 'RB 라이프치히',
      enName: 'RB Leipzig',
      koLeague: '분데스리가',
      enLeague: 'Bundesliga',
    ),
    (
      id: 'stuttgart',
      koName: '슈투트가르트',
      enName: 'Stuttgart',
      koLeague: '분데스리가',
      enLeague: 'Bundesliga',
    ),
    (
      id: 'frankfurt',
      koName: '프랑크푸르트',
      enName: 'Eintracht Frankfurt',
      koLeague: '분데스리가',
      enLeague: 'Bundesliga',
    ),
    (
      id: 'wolfsburg',
      koName: '볼프스부르크',
      enName: 'Wolfsburg',
      koLeague: '분데스리가',
      enLeague: 'Bundesliga',
    ),
    (
      id: 'atalanta',
      koName: '아탈란타',
      enName: 'Atalanta',
      koLeague: '세리에 A',
      enLeague: 'Serie A',
    ),
    (
      id: 'lazio',
      koName: '라치오',
      enName: 'Lazio',
      koLeague: '세리에 A',
      enLeague: 'Serie A',
    ),
    (
      id: 'fiorentina',
      koName: '피오렌티나',
      enName: 'Fiorentina',
      koLeague: '세리에 A',
      enLeague: 'Serie A',
    ),
    (
      id: 'torino',
      koName: '토리노',
      enName: 'Torino',
      koLeague: '세리에 A',
      enLeague: 'Serie A',
    ),
    (
      id: 'lyon',
      koName: '리옹',
      enName: 'Lyon',
      koLeague: '리그 1',
      enLeague: 'Ligue 1',
    ),
    (
      id: 'lille',
      koName: '릴',
      enName: 'Lille',
      koLeague: '리그 1',
      enLeague: 'Ligue 1',
    ),
    (
      id: 'nice',
      koName: '니스',
      enName: 'Nice',
      koLeague: '리그 1',
      enLeague: 'Ligue 1',
    ),
    (
      id: 'feyenoord',
      koName: '페예노르트',
      enName: 'Feyenoord',
      koLeague: '에레디비시',
      enLeague: 'Eredivisie',
    ),
    (
      id: 'az_alkmaar',
      koName: 'AZ 알크마르',
      enName: 'AZ Alkmaar',
      koLeague: '에레디비시',
      enLeague: 'Eredivisie',
    ),
    (
      id: 'braga',
      koName: '브라가',
      enName: 'Braga',
      koLeague: '프리메이라 리가',
      enLeague: 'Primeira Liga',
    ),
    (
      id: 'rangers',
      koName: '레인저스',
      enName: 'Rangers',
      koLeague: '스코티시 프리미어십',
      enLeague: 'Scottish Premiership',
    ),
    (
      id: 'besiktas',
      koName: '베식타시',
      enName: 'Besiktas',
      koLeague: '쉬페르리그',
      enLeague: 'Super Lig',
    ),
    (
      id: 'trabzonspor',
      koName: '트라브존스포르',
      enName: 'Trabzonspor',
      koLeague: '쉬페르리그',
      enLeague: 'Super Lig',
    ),
    (
      id: 'alittihad',
      koName: '알 이티하드',
      enName: 'Al Ittihad',
      koLeague: '사우디 프로리그',
      enLeague: 'Saudi Pro League',
    ),
    (
      id: 'alahli',
      koName: '알 아흘리',
      enName: 'Al Ahli',
      koLeague: '사우디 프로리그',
      enLeague: 'Saudi Pro League',
    ),
    (
      id: 'alshabab',
      koName: '알 샤밥',
      enName: 'Al Shabab',
      koLeague: '사우디 프로리그',
      enLeague: 'Saudi Pro League',
    ),
    (
      id: 'everton',
      koName: '에버턴',
      enName: 'Everton',
      koLeague: '프리미어리그',
      enLeague: 'Premier League',
    ),
    (
      id: 'wolves',
      koName: '울버햄프턴',
      enName: 'Wolverhampton Wanderers',
      koLeague: '프리미어리그',
      enLeague: 'Premier League',
    ),
    (
      id: 'fulham',
      koName: '풀럼',
      enName: 'Fulham',
      koLeague: '프리미어리그',
      enLeague: 'Premier League',
    ),
    (
      id: 'valencia',
      koName: '발렌시아',
      enName: 'Valencia',
      koLeague: '라리가',
      enLeague: 'LaLiga',
    ),
    (
      id: 'villarreal',
      koName: '비야레알',
      enName: 'Villarreal',
      koLeague: '라리가',
      enLeague: 'LaLiga',
    ),
    (
      id: 'athletic_bilbao',
      koName: '아틀레틱 빌바오',
      enName: 'Athletic Bilbao',
      koLeague: '라리가',
      enLeague: 'LaLiga',
    ),
    (
      id: 'werder',
      koName: '베르더 브레멘',
      enName: 'Werder Bremen',
      koLeague: '분데스리가',
      enLeague: 'Bundesliga',
    ),
    (
      id: 'monchengladbach',
      koName: '묀헨글라트바흐',
      enName: 'Borussia Monchengladbach',
      koLeague: '분데스리가',
      enLeague: 'Bundesliga',
    ),
    (
      id: 'bologna',
      koName: '볼로냐',
      enName: 'Bologna',
      koLeague: '세리에 A',
      enLeague: 'Serie A',
    ),
    (
      id: 'genoa',
      koName: '제노아',
      enName: 'Genoa',
      koLeague: '세리에 A',
      enLeague: 'Serie A',
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
    (
      id: 'fifa_womens_world_cup',
      koName: 'FIFA 여자 월드컵',
      enName: 'FIFA Women World Cup',
      koOrganizer: 'FIFA',
      enOrganizer: 'FIFA',
    ),
    (
      id: 'uefa_womens_euro',
      koName: 'UEFA 여자 유로',
      enName: 'UEFA Women Euro',
      koOrganizer: 'UEFA',
      enOrganizer: 'UEFA',
    ),
    (
      id: 'conmebol_copa_america_femenina',
      koName: '코파 아메리카 페메니나',
      enName: 'Copa America Femenina',
      koOrganizer: 'CONMEBOL',
      enOrganizer: 'CONMEBOL',
    ),
    (
      id: 'afc_womens_asian_cup',
      koName: 'AFC 여자 아시안컵',
      enName: 'AFC Women Asian Cup',
      koOrganizer: 'AFC',
      enOrganizer: 'AFC',
    ),
    (
      id: 'concacaf_w_gold_cup',
      koName: 'CONCACAF 여자 골드컵',
      enName: 'CONCACAF W Gold Cup',
      koOrganizer: 'CONCACAF',
      enOrganizer: 'CONCACAF',
    ),
    (
      id: 'caf_wafcon',
      koName: '아프리카 여자 네이션스컵',
      enName: 'Women Africa Cup of Nations',
      koOrganizer: 'CAF',
      enOrganizer: 'CAF',
    ),
    (
      id: 'uefa_super_cup',
      koName: 'UEFA 슈퍼컵',
      enName: 'UEFA Super Cup',
      koOrganizer: 'UEFA',
      enOrganizer: 'UEFA',
    ),
    (
      id: 'jleague_asia_challenge',
      koName: 'AFC U-23 아시안컵',
      enName: 'AFC U-23 Asian Cup',
      koOrganizer: 'AFC',
      enOrganizer: 'AFC',
    ),
    (
      id: 'afc_u20_asian_cup',
      koName: 'AFC U-20 아시안컵',
      enName: 'AFC U-20 Asian Cup',
      koOrganizer: 'AFC',
      enOrganizer: 'AFC',
    ),
    (
      id: 'afc_u17_asian_cup',
      koName: 'AFC U-17 아시안컵',
      enName: 'AFC U-17 Asian Cup',
      koOrganizer: 'AFC',
      enOrganizer: 'AFC',
    ),
    (
      id: 'fifa_intercontinental_cup',
      koName: 'FIFA 인터컨티넨털컵',
      enName: 'FIFA Intercontinental Cup',
      koOrganizer: 'FIFA',
      enOrganizer: 'FIFA',
    ),
    (
      id: 'fifa_arab_cup',
      koName: 'FIFA 아랍컵',
      enName: 'FIFA Arab Cup',
      koOrganizer: 'FIFA',
      enOrganizer: 'FIFA',
    ),
    (
      id: 'finalissima',
      koName: '피날리시마',
      enName: 'Finalissima',
      koOrganizer: 'UEFA',
      enOrganizer: 'UEFA',
    ),
    (
      id: 'uefa_u21_championship',
      koName: 'UEFA U-21 챔피언십',
      enName: 'UEFA U-21 Championship',
      koOrganizer: 'UEFA',
      enOrganizer: 'UEFA',
    ),
    (
      id: 'uefa_youth_league',
      koName: 'UEFA 유스리그',
      enName: 'UEFA Youth League',
      koOrganizer: 'UEFA',
      enOrganizer: 'UEFA',
    ),
    (
      id: 'afc_cup',
      koName: 'AFC 컵',
      enName: 'AFC Cup',
      koOrganizer: 'AFC',
      enOrganizer: 'AFC',
    ),
    (
      id: 'afc_presidents_cup',
      koName: 'AFC 프레지던츠컵',
      enName: 'AFC Presidents Cup',
      koOrganizer: 'AFC',
      enOrganizer: 'AFC',
    ),
    (
      id: 'caf_confederation_cup',
      koName: 'CAF 컨페더레이션컵',
      enName: 'CAF Confederation Cup',
      koOrganizer: 'CAF',
      enOrganizer: 'CAF',
    ),
    (
      id: 'caf_super_cup',
      koName: 'CAF 슈퍼컵',
      enName: 'CAF Super Cup',
      koOrganizer: 'CAF',
      enOrganizer: 'CAF',
    ),
    (
      id: 'concacaf_nations_league',
      koName: 'CONCACAF 네이션스리그',
      enName: 'CONCACAF Nations League',
      koOrganizer: 'CONCACAF',
      enOrganizer: 'CONCACAF',
    ),
    (
      id: 'concacaf_w_championship',
      koName: 'CONCACAF W 챔피언십',
      enName: 'CONCACAF W Championship',
      koOrganizer: 'CONCACAF',
      enOrganizer: 'CONCACAF',
    ),
    (
      id: 'conmebol_recopa',
      koName: '레코파 수다메리카나',
      enName: 'Recopa Sudamericana',
      koOrganizer: 'CONMEBOL',
      enOrganizer: 'CONMEBOL',
    ),
    (
      id: 'conmebol_preolympic',
      koName: '남미 올림픽 예선',
      enName: 'CONMEBOL Pre-Olympic Tournament',
      koOrganizer: 'CONMEBOL',
      enOrganizer: 'CONMEBOL',
    ),
    (
      id: 'fifa_futsal_world_cup',
      koName: 'FIFA 풋살 월드컵',
      enName: 'FIFA Futsal World Cup',
      koOrganizer: 'FIFA',
      enOrganizer: 'FIFA',
    ),
    (
      id: 'fifa_beach_soccer_world_cup',
      koName: 'FIFA 비치사커 월드컵',
      enName: 'FIFA Beach Soccer World Cup',
      koOrganizer: 'FIFA',
      enOrganizer: 'FIFA',
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
    _reportQuizPoolQualityWarning(
      'Technique and tactics should dominate the quiz bank.',
    );
  }

  final minimumPerCategory = questions.length >= 300 ? 6 : 1;
  for (final category in _QuizCategory.values) {
    if ((categoryCounts[category] ?? 0) < minimumPerCategory) {
      _reportQuizPoolQualityWarning(
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

void _reportQuizPoolQualityWarning(String message) {
  assert(() {
    debugPrint('skill_quiz_screen: $message');
    return true;
  }());
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

_FootballQuizQuestion _sportQuizQuestion({
  required String id,
  required String conceptKey,
  required int difficulty,
  required _QuestionStyle style,
  required _QuizCategory category,
  required String koPrompt,
  required String enPrompt,
  List<_FootballQuizOption> options = const <_FootballQuizOption>[],
  int correctIndex = -1,
  List<String> acceptedAnswers = const <String>[],
  required String koExplain,
  required String enExplain,
  required String koNextPoint,
  required String enNextPoint,
}) {
  return _FootballQuizQuestion(
    id: id,
    conceptKey: conceptKey,
    difficulty: difficulty,
    style: style,
    category: category,
    koPrompt: koPrompt,
    enPrompt: enPrompt,
    options: options,
    correctIndex: correctIndex,
    acceptedAnswers: acceptedAnswers,
    koExplain: koExplain,
    enExplain: enExplain,
    koNextPoint: koNextPoint,
    enNextPoint: enNextPoint,
  );
}

List<_FootballQuizQuestion> _athleteNutritionSportQuizQuestions(
  String sportId,
) {
  final prefix = switch (sportId) {
    SportCatalog.baseballId => 'baseball',
    SportCatalog.basketballId => 'basketball',
    SportCatalog.tennisId => 'tennis',
    _ => 'football',
  };
  final koSport = switch (sportId) {
    SportCatalog.baseballId => '야구',
    SportCatalog.basketballId => '농구',
    SportCatalog.tennisId => '테니스',
    _ => '축구',
  };
  final enSport = switch (sportId) {
    SportCatalog.baseballId => 'baseball',
    SportCatalog.basketballId => 'basketball',
    SportCatalog.tennisId => 'tennis',
    _ => 'football',
  };
  final koLongSession = switch (sportId) {
    SportCatalog.baseballId => '더블헤더나 긴 원정 경기',
    SportCatalog.basketballId => '백투백 경기나 연장전까지 간 경기',
    SportCatalog.tennisId => '긴 3세트 경기나 더운 날 토너먼트',
    _ => '90분 이상 이어지는 경기',
  };
  final enLongSession = switch (sportId) {
    SportCatalog.baseballId => 'a doubleheader or long road game',
    SportCatalog.basketballId => 'a back-to-back game or overtime game',
    SportCatalog.tennisId => 'a long three-set match or hot tournament day',
    _ => 'a match lasting more than 90 minutes',
  };
  final koBreakMoment = switch (sportId) {
    SportCatalog.baseballId => '이닝 사이',
    SportCatalog.basketballId => '쿼터 사이와 타임아웃',
    SportCatalog.tennisId => '체인지오버',
    _ => '하프타임',
  };
  final enBreakMoment = switch (sportId) {
    SportCatalog.baseballId => 'between innings',
    SportCatalog.basketballId => 'between quarters and during timeouts',
    SportCatalog.tennisId => 'during changeovers',
    _ => 'at halftime',
  };

  return <_FootballQuizQuestion>[
    _sportQuizQuestion(
      id: '${prefix}_nutrition_mcq_pregame_familiar_food',
      conceptKey: '${prefix}_nutrition_pregame_familiar_food',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.nutrition,
      koPrompt: '$koSport 경기 전 식사 원칙으로 가장 좋은 것은?',
      enPrompt:
          'What is the best prematch eating principle for $enSport athletes?',
      options: const [
        _FootballQuizOption(
          koText: '훈련 때 검증한 소화 쉬운 탄수화물 식사와 수분을 준비한다',
          enText:
              'Use a familiar digestible carbohydrate meal with planned fluids',
        ),
        _FootballQuizOption(
          koText: '경기 당일 처음 먹는 고지방 메뉴를 크게 늘린다',
          enText: 'Greatly increase a new high-fat food on game day',
        ),
        _FootballQuizOption(
          koText: '식사는 모두 빼고 카페인만으로 버틴다',
          enText: 'Skip all food and rely only on caffeine',
        ),
        _FootballQuizOption(
          koText: '위장 반응을 확인하지 않고 보충제를 여러 개 섞는다',
          enText: 'Mix several supplements without checking gut response',
        ),
      ],
      correctIndex: 0,
      koExplain:
          '경기 전 식사는 에너지 준비와 소화 안정성이 함께 중요합니다. 새 음식 실험은 중요한 경기보다 훈련일에 해야 합니다.',
      enExplain:
          'Prematch eating should prepare energy and protect gut comfort. New foods belong in training trials, not key competitions.',
      koNextPoint: '식사 계획은 음식 종류, 양, 먹는 시간을 평소 훈련에서 먼저 검증하세요.',
      enNextPoint:
          'Test food type, amount, and timing during normal training first.',
    ),
    _sportQuizQuestion(
      id: '${prefix}_nutrition_mcq_long_session_fuel',
      conceptKey: '${prefix}_nutrition_long_session_fuel',
      difficulty: 3,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.nutrition,
      koPrompt: '$koLongSession 전후의 영양 판단으로 가장 알맞은 것은?',
      enPrompt:
          'What nutrition judgment best fits $enLongSession before and after play?',
      options: const [
        _FootballQuizOption(
          koText: '수분, 전해질, 탄수화물 필요성을 시간과 땀 양에 맞춰 계획한다',
          enText:
              'Plan fluid, electrolyte, and carbohydrate needs from duration and sweat loss',
        ),
        _FootballQuizOption(
          koText: '갈증이 심해질 때까지 아무것도 마시지 않는다',
          enText: 'Drink nothing until thirst is severe',
        ),
        _FootballQuizOption(
          koText: '운동 중 탄수화물은 어떤 상황에서도 항상 금지한다',
          enText: 'Ban carbohydrate during play in every situation',
        ),
        _FootballQuizOption(
          koText: '끝난 뒤 회복식은 다음 날 밤까지 미룬다',
          enText: 'Delay recovery eating until the next night',
        ),
      ],
      correctIndex: 0,
      koExplain:
          '긴 경기나 더운 환경에서는 에너지와 수분 손실이 함께 커질 수 있어 시간, 강도, 땀 양에 맞춘 계획이 필요합니다.',
      enExplain:
          'Long or hot competition can increase fuel and fluid losses together, so plans should match duration, intensity, and sweat loss.',
      koNextPoint: '경기 영양은 한 번에 많이 먹는 것보다 미리 검증한 작은 루틴이 강합니다.',
      enNextPoint:
          'Competition nutrition works best as a tested routine rather than one large last-minute intake.',
    ),
    _sportQuizQuestion(
      id: '${prefix}_nutrition_ox_energy_availability',
      conceptKey: '${prefix}_nutrition_energy_availability',
      difficulty: 3,
      style: _QuestionStyle.ox,
      category: _QuizCategory.nutrition,
      koPrompt:
          '훈련량이 많은 선수는 체중만 보지 말고 회복, 피로, 식사 제한 여부까지 함께 보며 에너지 가용성을 관리해야 한다. O/X',
      enPrompt:
          'High-load athletes should manage energy availability by watching recovery, fatigue, and restriction patterns, not body weight alone. True/False',
      options: const [
        _FootballQuizOption(koText: 'O', enText: 'True'),
        _FootballQuizOption(koText: 'X', enText: 'False'),
      ],
      correctIndex: 0,
      koExplain: '낮은 에너지 가용성은 컨디션, 적응, 건강 신호에 영향을 줄 수 있어 훈련을 버틸 충분한 식사가 중요합니다.',
      enExplain:
          'Low energy availability can affect readiness, adaptation, and health signals, so fueling enough for training matters.',
      koNextPoint: '체중 관리 문제는 회복 지표와 훈련 지속 가능성을 함께 묶어 판단하세요.',
      enNextPoint:
          'Judge weight-management questions together with recovery markers and sustainable training.',
    ),
    _sportQuizQuestion(
      id: '${prefix}_nutrition_ox_supplement_check',
      conceptKey: '${prefix}_nutrition_supplement_check',
      difficulty: 3,
      style: _QuestionStyle.ox,
      category: _QuizCategory.nutrition,
      koPrompt:
          '보충제는 판매 중이라는 이유만으로 안전하거나 허용되는 것이 아니므로, 성분과 금지약물 위험을 확인해야 한다. O/X',
      enPrompt:
          'A supplement is not automatically safe or permitted just because it is sold, so ingredient and anti-doping risk checks matter. True/False',
      options: const [
        _FootballQuizOption(koText: 'O', enText: 'True'),
        _FootballQuizOption(koText: 'X', enText: 'False'),
      ],
      correctIndex: 0,
      koExplain:
          '보충제는 오염, 표시 오류, 금지 성분 위험이 있을 수 있습니다. 음식 우선 원칙과 전문가 확인이 더 안전합니다.',
      enExplain:
          'Supplements can carry contamination, label, or prohibited-substance risk. Food-first planning and expert checks are safer.',
      koNextPoint: '보충제는 효과, 안전성, 허용 여부를 한 세트로 판단하세요.',
      enNextPoint:
          'Evaluate supplements through effectiveness, safety, and whether they are permitted.',
    ),
    _sportQuizQuestion(
      id: '${prefix}_nutrition_sa_electrolyte',
      conceptKey: '${prefix}_nutrition_electrolyte_term',
      difficulty: 2,
      style: _QuestionStyle.shortAnswer,
      category: _QuizCategory.nutrition,
      koPrompt: '$koBreakMoment에 땀 손실이 큰 날 수분과 함께 고려할 수 있는 나트륨 등 성분은?',
      enPrompt:
          'On a sweaty day $enBreakMoment, what sodium-related components may be considered with fluids?',
      acceptedAnswers: const ['전해질', 'electrolyte', 'electrolytes'],
      koExplain: '정답은 "전해질"입니다. 땀을 많이 흘리는 환경에서는 물과 함께 전해질 손실도 고려할 수 있습니다.',
      enExplain:
          'The answer is "electrolytes." Heavy sweating can make electrolyte losses relevant alongside fluid intake.',
      koNextPoint: '수분 보충은 물만이 아니라 운동 시간, 더위, 땀 양을 함께 보세요.',
      enNextPoint:
          'Hydration planning should include duration, heat, and sweat rate, not water alone.',
    ),
    _sportQuizQuestion(
      id: '${prefix}_nutrition_sa_energy_availability',
      conceptKey: '${prefix}_nutrition_energy_availability_term',
      difficulty: 3,
      style: _QuestionStyle.shortAnswer,
      category: _QuizCategory.nutrition,
      koPrompt: '훈련과 건강 기능을 버틸 만큼 몸에 남는 에너지 상태를 뜻하는 용어는?',
      enPrompt:
          'What term describes having enough remaining energy to support training and healthy body functions?',
      acceptedAnswers: const [
        '에너지 가용성',
        'energy availability',
        'available energy',
      ],
      koExplain: '정답은 "에너지 가용성"입니다. 먹는 양과 훈련량의 균형을 건강과 경기력 관점에서 보는 핵심 개념입니다.',
      enExplain:
          'The answer is "energy availability." It connects intake and training load through health and performance.',
      koNextPoint: '식습관은 체중 숫자보다 훈련을 버틸 연료와 회복 신호를 먼저 보세요.',
      enNextPoint:
          'Read eating habits through fuel for training and recovery signs before body weight alone.',
    ),
  ];
}

_OxFactSeed _styleFloorOxSeed(
  String id,
  int difficulty,
  _QuizCategory category,
  String koTrueStatement,
  String enTrueStatement,
  String koFalseStatement,
  String enFalseStatement,
  String koExplain,
  String enExplain,
  String koNextPoint,
  String enNextPoint,
) {
  return _OxFactSeed(
    id: id,
    difficulty: difficulty,
    category: category,
    koTrueStatement: koTrueStatement,
    enTrueStatement: enTrueStatement,
    koFalseStatement: koFalseStatement,
    enFalseStatement: enFalseStatement,
    koExplain: koExplain,
    enExplain: enExplain,
    koNextPoint: koNextPoint,
    enNextPoint: enNextPoint,
  );
}

_ShortAnswerKnowledgeSeed _styleFloorShortSeed(
  String id,
  int difficulty,
  _QuizCategory category,
  String koClue,
  String enClue,
  List<String> acceptedAnswers,
  String koExplain,
  String enExplain,
  String koNextPoint,
  String enNextPoint,
) {
  return _ShortAnswerKnowledgeSeed(
    id: id,
    difficulty: difficulty,
    category: category,
    koClue: koClue,
    enClue: enClue,
    acceptedAnswers: acceptedAnswers,
    koExplain: koExplain,
    enExplain: enExplain,
    koNextPoint: koNextPoint,
    enNextPoint: enNextPoint,
  );
}

List<_FootballQuizQuestion> _styleFloorQuestionsFromSeeds({
  required String prefix,
  required List<_OxFactSeed> oxFacts,
  required List<_ShortAnswerKnowledgeSeed> shortSeeds,
  required List<_McqSeed> mcqSeeds,
}) {
  final questions = <_FootballQuizQuestion>[];
  for (var index = 0; index < oxFacts.length; index++) {
    final fact = oxFacts[index];
    final useTrue = index.isEven;
    questions.add(
      _sportQuizQuestion(
        id: '${prefix}_style_floor_ox_${fact.id}',
        conceptKey: '${prefix}_style_floor_ox_${fact.id}',
        difficulty: fact.difficulty,
        style: _QuestionStyle.ox,
        category: fact.category,
        koPrompt: useTrue ? fact.koTrueStatement : fact.koFalseStatement,
        enPrompt: useTrue ? fact.enTrueStatement : fact.enFalseStatement,
        options: const [
          _FootballQuizOption(koText: 'O', enText: 'True'),
          _FootballQuizOption(koText: 'X', enText: 'False'),
        ],
        correctIndex: useTrue ? 0 : 1,
        koExplain: useTrue
            ? '${fact.koExplain} 그래서 정답은 O입니다.'
            : '${fact.koExplain} 그래서 정답은 X입니다.',
        enExplain: useTrue
            ? '${fact.enExplain} So the answer is True.'
            : '${fact.enExplain} So the answer is False.',
        koNextPoint: fact.koNextPoint,
        enNextPoint: fact.enNextPoint,
      ),
    );
  }
  for (final seed in shortSeeds) {
    questions.add(
      _sportQuizQuestion(
        id: '${prefix}_style_floor_sa_${seed.id}',
        conceptKey: '${prefix}_style_floor_sa_${seed.id}',
        difficulty: seed.difficulty,
        style: _QuestionStyle.shortAnswer,
        category: seed.category,
        koPrompt: '다음 설명의 용어를 입력하세요: "${seed.koClue}"',
        enPrompt: 'Write the term for: "${seed.enClue}"',
        acceptedAnswers: seed.acceptedAnswers,
        koExplain: seed.koExplain,
        enExplain: seed.enExplain,
        koNextPoint: seed.koNextPoint,
        enNextPoint: seed.enNextPoint,
      ),
    );
  }
  for (final seed in mcqSeeds) {
    questions.add(
      _sportQuizQuestion(
        id: '${prefix}_style_floor_mcq_${seed.id}',
        conceptKey: '${prefix}_style_floor_mcq_${seed.id}',
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
  return questions;
}

List<_FootballQuizQuestion> _styleFloorSportQuizQuestions(String sportId) {
  return switch (sportId) {
    SportCatalog.baseballId => _styleFloorQuestionsFromSeeds(
        prefix: 'baseball',
        oxFacts: _baseballStyleFloorOxFacts(),
        shortSeeds: _baseballStyleFloorShortSeeds(),
        mcqSeeds: _baseballStyleFloorMcqSeeds(),
      ),
    SportCatalog.basketballId => _styleFloorQuestionsFromSeeds(
        prefix: 'basketball',
        oxFacts: _basketballStyleFloorOxFacts(),
        shortSeeds: _basketballStyleFloorShortSeeds(),
        mcqSeeds: _basketballStyleFloorMcqSeeds(),
      ),
    SportCatalog.tennisId => _styleFloorQuestionsFromSeeds(
        prefix: 'tennis',
        oxFacts: _tennisStyleFloorOxFacts(),
        shortSeeds: _tennisStyleFloorShortSeeds(),
        mcqSeeds: _tennisStyleFloorMcqSeeds(),
      ),
    _ => const <_FootballQuizQuestion>[],
  };
}

List<_OxFactSeed> _baseballStyleFloorOxFacts() {
  return <_OxFactSeed>[
    _styleFloorOxSeed(
      'one_two_chase_plan',
      2,
      _QuizCategory.tactics,
      '투수에게 유리한 1-2 카운트에서는 타자의 직전 반응을 보고 존 경계나 유인구를 설계할 수 있다. O/X',
      'On a pitcher-friendly 1-2 count, pitch choice can use the hitter’s previous reaction to attack an edge or chase area. True/False',
      '투수에게 유리한 1-2 카운트에서는 타자 반응과 상관없이 항상 가운데 직구만 던져야 한다. O/X',
      'On a pitcher-friendly 1-2 count, the pitcher must always throw only a middle fastball regardless of hitter reaction. True/False',
      '유리한 카운트는 가운데 승부만 의미하지 않습니다. 약점, 직전 스윙, 주자 상황을 묶어 다음 공을 설계합니다.',
      'A leverage count is not only about middle strikes. Weakness, last swing, and base state shape the next pitch.',
      '볼카운트 문제는 타자 반응과 다음 유인 공간을 같이 보세요.',
      'Read count questions with hitter reaction and chase space.',
    ),
    _styleFloorOxSeed(
      'infield_in_runner_third',
      2,
      _QuizCategory.tactics,
      '1아웃 3루에서 내야 전진수비는 땅볼 실점을 줄이려는 선택이 될 수 있다. O/X',
      'With one out and a runner on third, bringing the infield in can be a choice to cut off a ground-ball run. True/False',
      '1아웃 3루에서 내야 전진수비는 어떤 점수 상황에서도 절대 쓰면 안 된다. O/X',
      'With one out and a runner on third, bringing the infield in should never be used in any score situation. True/False',
      '전진수비는 타구 반응 시간이 줄어드는 위험을 감수하고 홈 승부 가능성을 높이는 전술입니다.',
      'The infield-in tradeoff accepts less reaction time to improve the chance of a play at the plate.',
      '수비 위치는 아웃카운트, 주자, 점수 차를 함께 놓고 판단하세요.',
      'Judge defensive depth through outs, runners, and score.',
    ),
    _styleFloorOxSeed(
      'two_strike_contact_zone',
      2,
      _QuizCategory.technique,
      '타자는 2스트라이크 이후 콘택트를 위해 자신이 커버할 존을 조금 넓힐 수 있다. O/X',
      'After two strikes, a hitter can slightly widen the zone they protect for contact. True/False',
      '타자는 2스트라이크 이후에도 무조건 완벽한 한가운데 공만 기다려야 한다. O/X',
      'After two strikes, a hitter must always wait only for a perfect middle pitch. True/False',
      '2스트라이크 접근은 완벽한 공만 기다리기보다 삼진 위험을 줄이는 콘택트 계획이 중요합니다.',
      'Two-strike hitting values a contact plan that lowers strikeout risk more than waiting only for a perfect pitch.',
      '좋은 타격 판단은 카운트에 따라 목표가 달라집니다.',
      'Good hitting decisions change with the count.',
    ),
    _styleFloorOxSeed(
      'cutoff_runner_context',
      2,
      _QuizCategory.positions,
      '외야 송구 판단은 강한 팔만이 아니라 컷오프 위치와 주자 속도까지 함께 봐야 한다. O/X',
      'Outfield throw decisions should include cutoff position and runner speed, not arm strength alone. True/False',
      '외야 송구 판단은 주자 속도나 컷오프와 상관없이 항상 가장 먼 베이스로 던지는 것이다. O/X',
      'Outfield throw decisions should always go to the farthest base regardless of runner speed or cutoff. True/False',
      '좋은 송구는 가장 멀리 던지는 것이 아니라 다음 베이스를 통제하는 연결입니다.',
      'A good throw is not only distance; it is a relay that controls the next base.',
      '공을 잡기 전 목표 베이스와 컷오프맨을 먼저 확인하세요.',
      'Identify target base and cutoff before fielding.',
    ),
    _styleFloorOxSeed(
      'changeup_arm_speed',
      2,
      _QuizCategory.technique,
      '체인지업은 직구와 비슷한 팔 스윙에서 속도 차가 나야 타자의 타이밍을 빼앗기 쉽다. O/X',
      'A changeup is easier to sell when arm speed resembles the fastball while velocity changes. True/False',
      '체인지업은 타자를 속이기 위해 팔 스윙을 일부러 눈에 띄게 늦추는 것이 항상 좋다. O/X',
      'A changeup is always better when the pitcher visibly slows the arm swing to fool the hitter. True/False',
      '체인지업은 직구와 비슷한 출발 동작에서 속도 차가 나야 효과가 커집니다.',
      'A changeup works best when arm action resembles the fastball while speed separates.',
      '변화구는 공의 변화뿐 아니라 같은 출발 동작을 함께 보세요.',
      'Evaluate offspeed pitches through both movement and disguise.',
    ),
    _styleFloorOxSeed(
      'catcher_game_calling',
      3,
      _QuizCategory.tactics,
      '포수는 투수 장점, 타자 반응, 카운트를 연결해 다음 공의 의미를 만들 수 있다. O/X',
      'A catcher can connect pitcher strength, hitter reaction, and count to give the next pitch purpose. True/False',
      '포수는 포구 기술만 좋으면 볼 배합과 타자 약점은 신경 쓰지 않아도 된다. O/X',
      'If a catcher receives well, pitch sequencing and hitter weaknesses do not matter. True/False',
      '포수는 포구뿐 아니라 경기 운영과 다음 공 설계에도 관여합니다.',
      'A catcher contributes to game management and next-pitch planning, not only receiving.',
      '포수 문항은 기술과 경기 운영을 분리하지 말고 같이 보세요.',
      'Read catcher questions through both skill and game management.',
    ),
    _styleFloorOxSeed(
      'sac_fly_read',
      2,
      _QuizCategory.tactics,
      '희생플라이 판단은 타구 깊이, 외야수 어깨, 주자의 스타트 능력을 함께 봐야 한다. O/X',
      'Sacrifice-fly decisions should combine ball depth, outfielder arm, and runner jump. True/False',
      '희생플라이는 타구가 외야로 뜨기만 하면 주자 능력과 송구 위치를 보지 않아도 항상 안전하다. O/X',
      'A sacrifice fly is always safe once the ball is hit to the outfield, regardless of runner skill or throw location. True/False',
      '깊은 뜬공이라도 외야수 위치와 송구 능력에 따라 홈 승부 위험이 달라집니다.',
      'Even a deep fly ball changes risk depending on outfielder position and throwing ability.',
      '주루 판단은 공만 보지 말고 수비수의 몸 방향까지 확인하세요.',
      'Base-running reads include defender body direction.',
    ),
    _styleFloorOxSeed(
      'groundball_pitcher_shift',
      2,
      _QuizCategory.tactics,
      '땅볼 유도형 투수에게는 내야 수비 위치와 병살 준비가 경기 결과를 크게 바꿀 수 있다. O/X',
      'For a ground-ball pitcher, infield positioning and double-play readiness can strongly affect outcomes. True/False',
      '땅볼 유도형 투수 뒤의 내야 위치는 경기 결과와 거의 관련이 없다. O/X',
      'For a ground-ball pitcher, infield positioning has almost no relation to game outcomes. True/False',
      '투수 성향과 수비 배치는 연결됩니다. 어떤 타구를 유도하느냐에 따라 뒤의 구조가 달라집니다.',
      'Pitcher profile and defensive alignment connect because expected contact type shapes the structure behind it.',
      '투수 유형을 보면 뒤 수비 위치까지 같이 떠올리세요.',
      'When reading pitcher type, picture the defense behind it.',
    ),
    _styleFloorOxSeed(
      'handedness_alignment',
      2,
      _QuizCategory.positions,
      '좌타자와 우타자에 따라 수비 위치와 견제 각도가 달라질 수 있다. O/X',
      'Defensive alignment and pickoff angles can change by left-handed or right-handed hitter context. True/False',
      '좌타자와 우타자는 수비 위치와 견제 각도 판단에 아무 영향도 주지 않는다. O/X',
      'Left-handed and right-handed hitter context never affects defensive alignment or pickoff angles. True/False',
      '타자의 타구 방향, 주자의 리드, 투수의 시야가 함께 바뀌기 때문에 위치 판단도 달라집니다.',
      'Batted-ball tendency, runner lead, and pitcher vision change together, so positioning can change.',
      '타석 방향은 단순 정보가 아니라 수비 준비의 출발점입니다.',
      'Hitter side is a starting point for defensive preparation.',
    ),
    _styleFloorOxSeed(
      'bunt_defense_roles',
      2,
      _QuizCategory.tactics,
      '번트 수비는 누가 공을 잡고 누가 베이스를 커버할지 역할이 나뉘어야 안정된다. O/X',
      'Bunt defense is more stable when roles are split between fielding the ball and covering bases. True/False',
      '번트 수비에서는 모든 내야수가 공만 향해 동시에 뛰어드는 것이 가장 안정적이다. O/X',
      'On bunt defense, it is most stable for every infielder to charge only the ball at the same time. True/False',
      '번트 수비는 공 처리와 베이스 커버가 동시에 맞아야 합니다.',
      'Bunt defense needs fielding and base coverage to work together.',
      '번트 상황은 공 위치보다 커버 비어 있는 베이스를 먼저 체크하세요.',
      'In bunt situations, check uncovered bases as much as the ball.',
    ),
    _styleFloorOxSeed(
      'double_play_feed',
      2,
      _QuizCategory.technique,
      '더블플레이 연결 송구는 받는 선수의 발 전환을 돕는 정확도까지 중요하다. O/X',
      'A double-play feed needs accuracy that helps the receiver’s footwork into the next throw. True/False',
      '더블플레이 연결 송구는 빠르기만 하면 되고 글러브 쪽 정확도는 크게 중요하지 않다. O/X',
      'On a double-play feed, speed alone matters and glove-side accuracy is not very important. True/False',
      '빠른 송구도 받는 선수의 발 전환을 방해하면 두 번째 아웃이 어려워집니다.',
      'A fast feed that hurts the receiver’s footwork can still kill the second out.',
      '연결 플레이는 받는 사람의 다음 동작까지 포함해서 판단하세요.',
      'Judge feeds by the receiver’s next action.',
    ),
    _styleFloorOxSeed(
      'behind_count_power_only',
      2,
      _QuizCategory.mindset,
      '타자가 불리한 카운트에 몰리면 존 관리, 콘택트, 팀 상황을 먼저 고려할 수 있다. O/X',
      'When behind in the count, a hitter can prioritize zone control, contact, and team context. True/False',
      '타자가 불리한 카운트에 몰리면 장타만 노리는 것이 가장 안정적인 접근이다. O/X',
      'When behind in the count, the most stable hitting approach is to hunt only for extra-base power. True/False',
      '불리한 카운트에서는 존 관리, 콘택트, 팀 상황이 우선될 때가 많습니다.',
      'Behind in the count, zone control, contact, and team context often come first.',
      '마인드 문항은 욕심을 줄이는 기준까지 묻습니다.',
      'Mindset questions include knowing when to lower risk.',
    ),
    _styleFloorOxSeed(
      'relay_throw_chain',
      2,
      _QuizCategory.technique,
      '릴레이 송구는 한 번의 강한 송구보다 각도와 연결 리듬이 더 중요해지는 상황이 있다. O/X',
      'Relay throws can value angle and connection rhythm more than one maximum-effort throw. True/False',
      '릴레이 송구에서는 중계 각도보다 가장 강한 한 번의 송구만 항상 중요하다. O/X',
      'In relay throws, one maximum-effort throw is always more important than relay angle. True/False',
      '긴 거리에서는 정확한 중계와 빠른 전환이 주자의 추가 진루를 더 잘 막을 수 있습니다.',
      'Over distance, accurate relay and quick transfer can stop extra bases better than one forced throw.',
      '강도보다 공이 어느 발과 어느 어깨로 연결되는지 보세요.',
      'Look at how the throw connects to feet and shoulders.',
    ),
    _styleFloorOxSeed(
      'second_time_pattern',
      3,
      _QuizCategory.tactics,
      '타순이 두 번째 돌 때 투수는 이전 타석 반응을 바탕으로 반복과 변화를 섞어야 한다. O/X',
      'The second time through the order, a pitcher should mix repetition and change from prior at-bat reactions. True/False',
      '타순이 두 번째 돌 때도 투수는 첫 타석과 같은 패턴만 반복하는 것이 가장 안전하다. O/X',
      'The second time through the order, the safest pitching plan is to repeat the exact first-at-bat pattern. True/False',
      '타자는 이전 공을 학습합니다. 반복과 변화를 어떻게 섞을지 계획해야 합니다.',
      'Hitters learn from previous pitches, so the pitcher must plan how to mix repetition and change.',
      '같은 상대를 다시 만날 때는 이전 반응을 반드시 재료로 쓰세요.',
      'Use prior reactions when facing the same hitter again.',
    ),
    _styleFloorOxSeed(
      'catcher_target_cue',
      1,
      _QuizCategory.technique,
      '포수의 미트 목표는 투수가 의도와 위치를 반복 확인하는 시각 단서가 될 수 있다. O/X',
      'The catcher’s target can be a visual cue that helps the pitcher repeat intent and location. True/False',
      '포수의 미트 목표는 투수의 제구 루틴과 전혀 관련이 없다. O/X',
      'The catcher’s target has no relation to the pitcher’s location routine. True/False',
      '명확한 목표는 투수의 루틴과 제구 집중을 돕습니다.',
      'A clear target supports pitching routine and location focus.',
      '배터리 호흡은 사인뿐 아니라 목표 제시까지 포함합니다.',
      'Pitcher-catcher rhythm includes the target, not only signs.',
    ),
  ];
}

List<_ShortAnswerKnowledgeSeed> _baseballStyleFloorShortSeeds() {
  return <_ShortAnswerKnowledgeSeed>[
    _styleFloorShortSeed(
        'backup_play',
        2,
        _QuizCategory.positions,
        '송구가 빠졌을 때 뒤에서 커버해 추가 진루를 막는 움직임',
        'movement that covers behind a throw to prevent extra advancement if it gets away',
        const ['백업 플레이', 'backup play', 'backing up'],
        '정답은 "백업 플레이"입니다. 공 뒤의 안전망이 있어야 실수가 큰 실점으로 번지는 것을 줄입니다.',
        'The answer is "backup play." A safety layer behind the ball limits damage from mistakes.',
        '수비는 공을 잡는 선수뿐 아니라 뒤에서 막는 선수까지 포함하세요.',
        'Defense includes the player behind the play.'),
    _styleFloorShortSeed(
        'cutoff_man',
        1,
        _QuizCategory.positions,
        '외야 송구를 중간에서 받아 다음 베이스로 연결하는 선수',
        'player who receives an outfield throw in the middle and relays it to the next base',
        const ['컷오프맨', '컷오프', 'cutoff man', 'cut-off man'],
        '정답은 "컷오프맨"입니다. 긴 송구를 짧은 연결로 바꿔 주자 진루를 통제합니다.',
        'The answer is "cutoff man." The relay turns a long throw into a controlled connection.',
        '컷오프 위치는 공과 목표 베이스가 일직선에 가깝도록 잡습니다.',
        'Cutoff position should connect the ball and target base.'),
    _styleFloorShortSeed(
        'tag_up',
        1,
        _QuizCategory.tactics,
        '플라이볼이 잡힌 뒤 원래 베이스를 다시 밟고 진루하는 플레이',
        'play where a runner retouches the original base after a fly ball is caught before advancing',
        const ['태그업', 'tag up', 'tag-up'],
        '정답은 "태그업"입니다. 포구 이후 출발 타이밍과 외야 송구를 함께 읽어야 합니다.',
        'The answer is "tag up." It depends on timing after the catch and the outfielder throw.',
        '태그업은 타구 깊이와 주자 스타트를 함께 판단하세요.',
        'Pair tag-up reads with ball depth and runner jump.'),
    _styleFloorShortSeed(
        'changeup',
        1,
        _QuizCategory.technique,
        '직구와 비슷한 팔 스윙에서 속도를 낮춰 타이밍을 빼앗는 구종',
        'pitch that uses fastball-like arm speed with lower velocity to disrupt timing',
        const ['체인지업', 'changeup', 'change-up'],
        '정답은 "체인지업"입니다. 속도 차와 같은 출발 동작이 함께 살아야 효과가 큽니다.',
        'The answer is "changeup." It works through speed separation with similar delivery.',
        '구종은 움직임보다 타자의 타이밍이 어떻게 흔들리는지 보세요.',
        'Read pitch type through how it disrupts timing.'),
    _styleFloorShortSeed(
        'sacrifice_fly',
        1,
        _QuizCategory.tactics,
        '외야 플라이 아웃으로 3루 주자가 득점하게 만드는 공격 결과',
        'offensive result that scores a runner from third on an outfield fly out',
        const ['희생플라이', 'sacrifice fly', 'sac fly'],
        '정답은 "희생플라이"입니다. 아웃 하나와 득점 가능성을 교환하는 상황 판단입니다.',
        'The answer is "sacrifice fly." It trades an out for a run-scoring chance.',
        '타격 결과는 개인 기록보다 팀 득점 가치로도 읽어야 합니다.',
        'Read batting outcomes through team run value too.'),
    _styleFloorShortSeed(
        'double_play',
        1,
        _QuizCategory.tactics,
        '하나의 연속 플레이에서 아웃 두 개를 잡는 수비 플레이',
        'defensive play that records two outs in one continuous play',
        const ['병살', '더블플레이', 'double play'],
        '정답은 "더블플레이"입니다. 첫 아웃의 안정성과 다음 송구 각도가 핵심입니다.',
        'The answer is "double play." The secure first out and next throwing angle matter.',
        '병살 상황은 공 받기 전 발 위치부터 준비하세요.',
        'Prepare footwork before the ball arrives in double-play chances.'),
    _styleFloorShortSeed(
        'hit_and_run',
        2,
        _QuizCategory.tactics,
        '주자가 먼저 스타트하고 타자가 콘택트를 노려 수비를 흔드는 작전',
        'play that sends the runner early while the hitter tries to make contact to stress the defense',
        const ['히트 앤 런', '히트앤런', 'hit and run', 'hit-and-run'],
        '정답은 "히트 앤 런"입니다. 주루와 콘택트가 함께 맞아야 위험을 줄일 수 있습니다.',
        'The answer is "hit and run." It depends on both the runner start and hitter contact.',
        '작전 야구는 한 선수의 행동보다 두 행동의 타이밍을 보세요.',
        'Set-play baseball depends on timing between actions.'),
    _styleFloorShortSeed(
        'squeeze_bunt',
        2,
        _QuizCategory.tactics,
        '3루 주자가 홈으로 스타트하고 타자가 번트로 득점을 노리는 작전',
        'bunt play where the runner from third breaks for home while the batter bunts',
        const ['스퀴즈 번트', '스퀴즈', 'squeeze bunt', 'squeeze play'],
        '정답은 "스퀴즈 번트"입니다. 사인, 스타트, 번트 방향이 어긋나면 위험이 큽니다.',
        'The answer is "squeeze bunt." Sign, jump, and bunt direction must align.',
        '스퀴즈는 성공 장면보다 실패 위험까지 같이 학습하세요.',
        'Study squeeze plays with the failure risk included.'),
    _styleFloorShortSeed(
        'pickoff',
        1,
        _QuizCategory.technique,
        '투수가 주자를 묶기 위해 베이스로 던지는 견제 동작',
        'pitcher move that throws to a base to control or catch a runner',
        const ['견제', '견제구', 'pickoff', 'pick-off'],
        '정답은 "견제"입니다. 주자의 리드 폭과 스타트 타이밍을 제한하는 도구입니다.',
        'The answer is "pickoff." It controls lead size and steal timing.',
        '견제는 아웃 목적뿐 아니라 주자의 리듬 차단으로도 보세요.',
        'Pickoffs also disrupt runner rhythm, not only chase outs.'),
    _styleFloorShortSeed(
        'lead',
        1,
        _QuizCategory.technique,
        '주자가 다음 베이스를 노리기 위해 베이스에서 떨어져 잡는 거리',
        'distance a runner takes off the base to prepare for the next base',
        const ['리드', 'lead', 'lead off', 'leadoff'],
        '정답은 "리드"입니다. 크기보다 귀루할 수 있는 균형이 먼저입니다.',
        'The answer is "lead." Balance to return matters before distance.',
        '좋은 리드는 스타트와 귀루를 모두 가능하게 합니다.',
        'A good lead supports both start and return.'),
    _styleFloorShortSeed(
        'framing',
        2,
        _QuizCategory.technique,
        '포수가 경계 공을 안정적으로 받아 스트라이크처럼 보이게 돕는 기술',
        'catching skill that receives borderline pitches cleanly to help them look like strikes',
        const ['프레이밍', 'framing', 'pitch framing'],
        '정답은 "프레이밍"입니다. 과장보다 조용한 손과 안정된 포구가 중요합니다.',
        'The answer is "framing." Quiet hands and stable receiving matter more than exaggeration.',
        '포구 기술은 심판을 속이는 것보다 공을 잃지 않는 안정성으로 보세요.',
        'Receiving skill starts with stability, not theatrics.'),
    _styleFloorShortSeed(
        'whip',
        3,
        _QuizCategory.fun,
        '투수가 이닝당 허용한 볼넷과 안타를 묶어 보는 대표 지표',
        'pitching metric that combines walks and hits allowed per inning pitched',
        const ['WHIP', 'whip', 'walks hits per inning pitched'],
        '정답은 "WHIP"입니다. 주자를 얼마나 적게 내보내는지 보는 기본 투수 지표입니다.',
        'The answer is "WHIP." It shows how often a pitcher allows baserunners.',
        '기록은 이름보다 어떤 위험을 설명하는지까지 연결하세요.',
        'Link statistics to the risk they explain.'),
    _styleFloorShortSeed(
        'force_out',
        1,
        _QuizCategory.rules,
        '주자가 반드시 다음 베이스로 가야 해서 공이 먼저 도착하면 아웃되는 상황',
        'out that occurs when a runner is forced to advance and the ball reaches the base first',
        const ['포스 아웃', 'force out', 'force-out'],
        '정답은 "포스 아웃"입니다. 주자가 밀려 가는 베이스를 먼저 찾는 것이 핵심입니다.',
        'The answer is "force out." Identify the forced base first.',
        '포스 상황은 태그가 필요한지 아닌지를 먼저 구분하세요.',
        'First decide whether a tag is required.'),
    _styleFloorShortSeed(
        'pitch_tunneling_term',
        3,
        _QuizCategory.tactics,
        '여러 구종의 초반 궤적을 비슷하게 보여 타자의 판단을 늦추는 투구 설계',
        'pitching design that makes different pitches look similar early to delay hitter recognition',
        const ['터널링', '피치 터널링', 'pitch tunneling', 'tunneling'],
        '정답은 "터널링"입니다. 타자가 구종을 늦게 구분할수록 좋은 스윙 선택이 어려워집니다.',
        'The answer is "pitch tunneling." Later recognition makes swing choice harder.',
        '투구 퀴즈는 공이 언제까지 같아 보이는지를 물어보세요.',
        'Ask how long pitches look alike in pitching questions.'),
    _styleFloorShortSeed(
        'pitch_sequence',
        2,
        _QuizCategory.tactics,
        '타자 반응을 보고 다음 구종과 코스를 이어 설계하는 볼 배합 계획',
        'plan that sequences pitch type and location from the hitter’s reactions',
        const ['볼 배합', '피치 시퀀스', 'pitch sequence', 'sequencing'],
        '정답은 "볼 배합" 또는 "피치 시퀀스"입니다. 한 공보다 다음 공과의 연결이 중요합니다.',
        'The answer is "pitch sequencing." The link between pitches matters more than one pitch alone.',
        '구종 선택은 이전 공의 결과와 반응을 같이 놓고 보세요.',
        'Pitch choice uses the previous pitch result and reaction.'),
  ];
}

List<_McqSeed> _baseballStyleFloorMcqSeeds() {
  return <_McqSeed>[
    const _McqSeed(
      id: 'runner_third_less_two',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koStem: '1아웃 3루에서 내야 전진수비를 선택할 때 가장 먼저 확인할 기준은?',
      enStem:
          'With one out and a runner on third, what should guide the decision to bring the infield in?',
      options: [
        _FootballQuizOption(
          koText: '점수 차, 타구 성향, 홈 승부 필요성',
          enText: 'Score, batted-ball tendency, and need for a play at home',
        ),
        _FootballQuizOption(
            koText: '수비수의 등번호 순서',
            enText: 'The defenders’ jersey-number order'),
        _FootballQuizOption(
            koText: '무조건 모든 내야수를 뒤로 세운다',
            enText: 'Always keep every infielder deep'),
        _FootballQuizOption(
            koText: '타석 결과와 관계없이 외야만 움직인다',
            enText: 'Move only the outfield regardless of hitter profile'),
      ],
      correctIndex: 0,
      koExplain: '전진수비는 홈 실점을 막는 대신 수비 범위가 줄어드는 선택입니다. 경기 맥락이 먼저입니다.',
      enExplain:
          'Playing in trades range for a better play at home, so game context comes first.',
      koNextPoint: '수비 전술은 “왜 그 위치인가”를 점수 상황과 연결하세요.',
      enNextPoint: 'Connect defensive tactics to the reason for that depth.',
    ),
    const _McqSeed(
      id: 'second_time_order',
      difficulty: 3,
      category: _QuizCategory.tactics,
      koStem: '같은 타자를 두 번째 만났을 때 투수의 더 좋은 접근은?',
      enStem:
          'When facing the same hitter a second time, which pitching approach is better?',
      options: [
        _FootballQuizOption(
          koText: '첫 타석 반응을 바탕으로 반복과 변화를 섞는다',
          enText: 'Mix repetition and change from the first-at-bat reaction',
        ),
        _FootballQuizOption(
            koText: '첫 타석과 완전히 같은 순서만 반복한다',
            enText: 'Repeat the exact same sequence every time'),
        _FootballQuizOption(
            koText: '카운트와 주자를 전혀 보지 않는다', enText: 'Ignore count and runners'),
        _FootballQuizOption(
            koText: '항상 가장 느린 공만 던진다', enText: 'Throw only the slowest pitch'),
      ],
      correctIndex: 0,
      koExplain: '타자는 이전 공을 학습하므로 투수는 같은 출발점에서 다른 끝을 만들거나 반대로 유도해야 합니다.',
      enExplain:
          'Hitters learn from earlier pitches, so pitchers use prior reactions to shape a new ending.',
      koNextPoint: '타순 반복은 데이터와 기억을 함께 쓰는 장면으로 보세요.',
      enNextPoint: 'Second-time-through questions use both data and memory.',
    ),
  ];
}

List<_OxFactSeed> _basketballStyleFloorOxFacts() {
  return <_OxFactSeed>[
    _styleFloorOxSeed(
        'drop_coverage_tradeoff',
        3,
        _QuizCategory.tactics,
        '드롭 커버리지는 림 보호를 우선하지만 볼 핸들러의 풀업 공간을 줄 수도 있다. O/X',
        'Drop coverage prioritizes rim protection but can concede pull-up space to the ball handler. True/False',
        '드롭 커버리지는 림 보호와 풀업 공간 허용이라는 트레이드오프가 전혀 없다. O/X',
        'Drop coverage has no tradeoff between rim protection and pull-up space. True/False',
        '드롭은 빅맨이 뒤에 머물러 림을 지키는 대신 중거리나 플로터 공간 관리가 필요합니다.',
        'Drop keeps the big near the rim, so the defense must manage pull-up and floater space.',
        '픽앤롤 수비는 무엇을 막고 무엇을 허용하는지 같이 보세요.',
        'Read pick-and-roll coverages by their tradeoffs.'),
    _styleFloorOxSeed(
        'switch_mismatch_help',
        3,
        _QuizCategory.tactics,
        '스위치 수비는 매치업 미스매치와 도움 위치를 함께 소통해야 안정된다. O/X',
        'Switch defense is more stable when mismatch and help positions are communicated together. True/False',
        '스위치 수비는 매치업이 바뀐 뒤 도움 위치를 전혀 소통하지 않아도 안정된다. O/X',
        'Switch defense stays stable after matchups change even without help communication. True/False',
        '스위치는 단순 교대가 아니라 이후 포스트업, 리바운드, 도움 위치까지 이어지는 약속입니다.',
        'Switching affects post defense, rebounding, and help spots, not only assignment exchange.',
        '스위치 후 누가 낮은 도움을 맡는지까지 확인하세요.',
        'After a switch, check who becomes the low help.'),
    _styleFloorOxSeed(
        'spain_pick_roll_backscreen',
        3,
        _QuizCategory.tactics,
        '스페인 픽앤롤은 롤맨 뒤에서 백스크린을 걸어 수비 판단을 더 어렵게 만든다. O/X',
        'Spain pick-and-roll adds a back screen behind the roller to complicate the defense. True/False',
        '스페인 픽앤롤은 일반 픽앤롤에서 스크린을 모두 없애는 전술이다. O/X',
        'Spain pick-and-roll removes every screen from a normal pick-and-roll. True/False',
        '볼스크린, 롤, 백스크린이 겹치면 수비는 볼, 림, 슈터를 동시에 처리해야 합니다.',
        'Ball screen, roll, and back screen force the defense to solve ball, rim, and shooter at once.',
        '복합 전술은 두 번째 스크린이 누구를 묶는지 보세요.',
        'In layered actions, identify who the second screen holds.'),
    _styleFloorOxSeed(
        'low_man_tag',
        3,
        _QuizCategory.positions,
        '약측 로우맨은 롤맨이 림으로 들어올 때 태그하거나 시간을 벌어주는 역할을 할 수 있다. O/X',
        'The weak-side low man can tag the roller or buy time when the roller dives to the rim. True/False',
        '약측 로우맨은 공과 멀기 때문에 픽앤롤 수비에 관여하지 않는다. O/X',
        'The weak-side low man is far from the ball, so they never affect pick-and-roll defense. True/False',
        '로우맨 도움은 림 실점을 늦추지만 코너 슈터를 비울 위험도 함께 생깁니다.',
        'Low-man help delays rim pressure but can expose the corner shooter.',
        '도움 수비는 도와준 뒤 회복할 패스 라인까지 함께 보세요.',
        'Help defense includes the recovery pass line.'),
    _styleFloorOxSeed(
        'closeout_balance',
        2,
        _QuizCategory.technique,
        '좋은 클로즈아웃은 슛을 방해하면서도 돌파를 막을 수 있도록 마지막 스텝을 줄인다. O/X',
        'A good closeout chops the last steps to contest the shot while containing the drive. True/False',
        '클로즈아웃은 항상 크게 점프해 슈터를 지나치는 것이 가장 안전하다. O/X',
        'The safest closeout is always to jump hard and fly past the shooter. True/False',
        '좋은 클로즈아웃은 슛 방해와 돌파 억제를 동시에 만족해야 합니다.',
        'A good closeout contests the shot while staying balanced enough to contain the drive.',
        '마지막 두 스텝의 속도 조절이 수비 성공을 좌우합니다.',
        'The last two steps often decide closeout quality.'),
    _styleFloorOxSeed(
        'corner_spacing_help_distance',
        2,
        _QuizCategory.tactics,
        '코너 스페이싱은 도움 수비가 림과 슈터 사이에서 더 먼 결정을 하게 만든다. O/X',
        'Corner spacing can force help defenders into a longer decision between rim help and the shooter. True/False',
        '코너 스페이싱은 도움 수비의 선택 거리에 아무 영향도 주지 않는다. O/X',
        'Corner spacing has no effect on the distance help defenders must cover. True/False',
        '코너가 비어 있지 않으면 도움 수비는 페인트를 막을 때 킥아웃 위험도 감수해야 합니다.',
        'Occupied corners make help defenders balance paint protection against kick-out risk.',
        '스페이싱은 서 있는 위치가 수비 선택지를 어떻게 넓히는지 보세요.',
        'Read spacing by how it stretches defensive choices.'),
    _styleFloorOxSeed(
        'nail_help_area',
        2,
        _QuizCategory.positions,
        '네일 위치의 수비수는 중앙 돌파를 늦추거나 패스 각을 흔드는 도움 수비가 될 수 있다. O/X',
        'A defender at the nail can slow middle drives or disrupt passing angles. True/False',
        '네일 위치는 공격과 수비 판단에서 특별한 의미가 없는 관중석 쪽 지점이다. O/X',
        'The nail is a spectator-side spot with no special meaning for basketball decisions. True/False',
        '네일은 자유투 라인 중앙 근처의 중요한 도움 위치입니다.',
        'The nail is a key help spot near the middle of the free-throw line.',
        '농구 위치 용어는 코트 지점과 수비 역할을 같이 외우세요.',
        'Pair court-location terms with defensive jobs.'),
    _styleFloorOxSeed(
        'transition_stop_ball',
        1,
        _QuizCategory.tactics,
        '턴오버 직후 속공 수비의 첫 우선순위는 공을 늦추고 림으로 가는 길을 막는 것이다. O/X',
        'Right after a turnover, transition defense first slows the ball and protects the path to the rim. True/False',
        '턴오버 직후 속공 수비에서는 공을 늦추는 것보다 모두 공격 리바운드를 계속 노리는 것이 먼저다. O/X',
        'Right after a turnover, transition defense should prioritize chasing offensive rebounds over slowing the ball. True/False',
        '공을 늦추지 못하면 수비 매치업을 정리할 시간이 사라집니다.',
        'If the ball is not slowed, the defense has no time to organize matchups.',
        '속공 수비는 “누가 공, 누가 림”을 바로 말하세요.',
        'Call who stops ball and who protects rim.'),
    _styleFloorOxSeed(
        'zone_offense_gaps',
        2,
        _QuizCategory.tactics,
        '존 공격은 빈 공간 점유, 하이포스트 플래시, 패스 이동으로 수비 간격을 흔드는 것이 중요하다. O/X',
        'Zone offense values occupying gaps, flashing high post, and moving the ball to shift the shell. True/False',
        '존 공격은 탑에서 드리블만 오래 하면 가장 효율적이다. O/X',
        'Against zone defense, holding a long dribble at the top is usually the most efficient attack. True/False',
        '존 공격은 빈 공간을 찌르고 수비 껍질을 움직이는 판단이 핵심입니다.',
        'Zone offense is about attacking gaps and moving the defensive shell.',
        '존 수비를 보면 공보다 빈 공간의 위치를 먼저 찾으세요.',
        'Against zone, identify gaps before watching only the ball.'),
    _styleFloorOxSeed(
        'flare_screen_shot',
        2,
        _QuizCategory.tactics,
        '플레어 스크린은 슈터가 바깥으로 벌어져 캐치앤슛 공간을 만들 때 쓰일 수 있다. O/X',
        'A flare screen can free a shooter moving away from the ball for catch-and-shoot space. True/False',
        '플레어 스크린은 슈터를 항상 림 아래로만 이동시키는 스크린이다. O/X',
        'A flare screen always moves the shooter only under the rim. True/False',
        '플레어는 수비의 시야와 추격 각도를 이용해 외곽 공간을 만듭니다.',
        'A flare screen uses defender vision and chasing angle to create perimeter space.',
        '스크린 이름은 움직이는 방향과 받는 선수의 목표를 함께 보세요.',
        'Screen terms connect direction with the receiver’s goal.'),
    _styleFloorOxSeed(
        'skip_pass_overload',
        2,
        _QuizCategory.tactics,
        '한쪽으로 수비가 과하게 몰리면 반대편 스킵 패스가 좋은 선택지가 될 수 있다. O/X',
        'When the defense overloads one side, a skip pass to the opposite side can become a good option. True/False',
        '수비가 한쪽으로 몰려도 반대편 패스는 항상 나쁜 선택이다. O/X',
        'Even when the defense overloads one side, passing opposite is always a bad choice. True/False',
        '스킵 패스는 도움 수비가 몰린 반대편의 시간과 공간을 활용합니다.',
        'A skip pass uses the time and space left on the weak side after help overloads.',
        '패스 판단은 가까운 거리만이 아니라 수비가 어디에 몰렸는지 보세요.',
        'Passing reads include where the defense has overloaded.'),
    _styleFloorOxSeed(
        'rebound_hit_find_get',
        1,
        _QuizCategory.technique,
        '수비 리바운드는 슛이 올라가면 상대를 찾고 몸으로 길을 막은 뒤 공을 잡는 순서가 중요하다. O/X',
        'On defensive rebounds, finding the opponent, blocking the path, then getting the ball is important. True/False',
        '수비 리바운드는 항상 공만 보고 뛰면 상대 위치는 신경 쓰지 않아도 된다. O/X',
        'On defensive rebounds, watching only the ball always makes opponent position irrelevant. True/False',
        '공만 보면 상대에게 안쪽 길을 내줄 수 있습니다. 먼저 몸으로 위치를 확보해야 합니다.',
        'Watching only the ball can give up inside position. Body position comes first.',
        '리바운드는 점프력보다 위치 싸움부터 훈련하세요.',
        'Train rebounding as position first, jumping second.'),
    _styleFloorOxSeed(
        'shot_fake_balance',
        2,
        _QuizCategory.technique,
        '슛 페이크를 수비할 때는 점프보다 균형 유지와 다음 드리블 차단이 먼저일 수 있다. O/X',
        'When defending a shot fake, staying balanced and containing the next dribble can matter before jumping. True/False',
        '슛 페이크에 속은 수비수는 항상 앞으로 점프해야만 회복할 수 있다. O/X',
        'A defender beaten by a shot fake must always jump forward to recover. True/False',
        '점프하면 돌파와 파울 위험이 커집니다. 균형 유지가 먼저입니다.',
        'Jumping increases drive and foul risk. Staying balanced comes first.',
        '페이크 수비는 공보다 상대의 중심 이동을 읽으세요.',
        'Defending fakes means reading body weight, not only the ball.'),
    _styleFloorOxSeed(
        'pnr_read_coverage',
        2,
        _QuizCategory.tactics,
        '픽앤롤 볼 핸들러는 미리 정한 기술만 쓰기보다 스크린 수비의 커버리지를 먼저 읽어야 한다. O/X',
        'A pick-and-roll ball handler should read the screen coverage before forcing a preselected move. True/False',
        '픽앤롤 볼 핸들러는 수비 커버리지와 상관없이 미리 정한 기술만 쓰면 된다. O/X',
        'A pick-and-roll ball handler should use only the preselected move regardless of coverage. True/False',
        '드롭, 스위치, 헤지에 따라 슛, 돌파, 패스의 우선순위가 달라집니다.',
        'Drop, switch, and hedge change the priority between shot, drive, and pass.',
        '픽앤롤은 기술명이 아니라 수비 반응을 푸는 문제입니다.',
        'Pick-and-roll is about solving coverage, not naming moves.'),
    _styleFloorOxSeed(
        'late_clock_decision',
        2,
        _QuizCategory.mindset,
        '샷클락이 얼마 남지 않으면 림 위협, 파울 유도, 열린 슛을 빠르게 비교해야 한다. O/X',
        'With little shot clock left, the offense should quickly compare rim pressure, foul chance, and open shot. True/False',
        '샷클락이 얼마 남지 않으면 어떤 상황에서도 뒤로 패스하는 것이 가장 안전하다. O/X',
        'With little shot clock left, passing backward is always the safest choice in every situation. True/False',
        '늦은 클락에서는 완벽한 공격보다 기대값 높은 빠른 선택이 중요합니다.',
        'Late clock demands quick comparison between rim pressure, foul chance, and open shot.',
        '시간 압박 문항은 안전함과 득점 가능성을 동시에 평가하세요.',
        'Late-clock reads balance safety and scoring value.'),
    _styleFloorOxSeed(
        'backdoor_overplay',
        2,
        _QuizCategory.tactics,
        '수비수가 패스 라인을 과하게 막으면 백도어 컷이 좋은 벌칙 선택이 될 수 있다. O/X',
        'When a defender overplays the passing lane, a backdoor cut can punish it. True/False',
        '수비수가 패스 라인을 과하게 막아도 등 뒤 공간은 절대 열리지 않는다. O/X',
        'When a defender overplays the passing lane, space behind them never opens. True/False',
        '과한 압박은 앞쪽 패스는 막지만 등 뒤 공간을 열 수 있습니다.',
        'Overplay blocks the front passing lane but can open space behind the defender.',
        '컷 판단은 수비수의 머리 방향과 발 위치를 함께 보세요.',
        'Cut reads include defender head direction and foot position.'),
  ];
}

List<_ShortAnswerKnowledgeSeed> _basketballStyleFloorShortSeeds() {
  return <_ShortAnswerKnowledgeSeed>[
    _styleFloorShortSeed(
        'drop_coverage',
        3,
        _QuizCategory.tactics,
        '픽앤롤에서 빅맨이 뒤로 내려 림을 지키는 수비 커버리지',
        'pick-and-roll coverage where the big defender stays back to protect the rim',
        const ['드롭', '드롭 커버리지', 'drop', 'drop coverage'],
        '정답은 "드롭 커버리지"입니다. 림 보호와 풀업 허용 사이의 균형이 핵심입니다.',
        'The answer is "drop coverage." It trades rim protection against pull-up space.',
        '커버리지 이름은 허용하는 슛까지 함께 외우세요.',
        'Learn coverages with the shots they concede.'),
    _styleFloorShortSeed(
        'switch',
        2,
        _QuizCategory.tactics,
        '스크린 상황에서 수비수가 맡은 공격수를 서로 바꾸는 수비',
        'defense that changes assignments between defenders on a screen',
        const ['스위치', 'switch', 'switching'],
        '정답은 "스위치"입니다. 바꾼 뒤 미스매치와 리바운드 책임까지 이어져야 합니다.',
        'The answer is "switch." The defense must handle mismatch and rebounding after the exchange.',
        '스위치는 콜 이후의 도움 위치까지 확인하세요.',
        'After a switch call, check the help positions.'),
    _styleFloorShortSeed(
        'hedge',
        3,
        _QuizCategory.tactics,
        '스크린 수비수가 잠깐 앞으로 나와 볼 핸들러의 진행을 늦추는 커버리지',
        'coverage where the screen defender steps out briefly to slow the ball handler',
        const ['헤지', 'hedge', 'hedging'],
        '정답은 "헤지"입니다. 볼을 늦춘 뒤 원래 매치업으로 회복하는 타이밍이 중요합니다.',
        'The answer is "hedge." It depends on slowing the ball and recovering on time.',
        '헤지는 강하게 나가는 순간보다 복귀 각도를 함께 보세요.',
        'Judge hedge coverage through recovery angle too.'),
    _styleFloorShortSeed(
        'spain_pick_roll',
        3,
        _QuizCategory.tactics,
        '롤맨 뒤에 백스크린을 더해 수비 판단을 흔드는 픽앤롤 액션',
        'pick-and-roll action that adds a back screen behind the roller',
        const [
          '스페인 픽앤롤',
          '스페인 픽 앤 롤',
          'spain pick and roll',
          'spain pick-and-roll',
          'spain pnr'
        ],
        '정답은 "스페인 픽앤롤"입니다. 볼, 롤맨, 슈터를 동시에 방어하게 만드는 복합 액션입니다.',
        'The answer is "Spain pick-and-roll." It stresses ball, roller, and shooter coverage together.',
        '복합 액션은 첫 스크린 뒤의 두 번째 접촉을 찾으세요.',
        'Find the second contact after the first screen.'),
    _styleFloorShortSeed(
        'nail',
        2,
        _QuizCategory.positions,
        '자유투 라인 중앙 근처에서 도움 수비의 기준점이 되는 위치',
        'spot near the middle of the free-throw line that is a key help-defense reference',
        const ['네일', 'nail', 'the nail'],
        '정답은 "네일"입니다. 중앙 돌파와 패스 각을 동시에 관리하는 위치입니다.',
        'The answer is "the nail." It helps manage middle drives and passing angles.',
        '코트 위치 용어는 실제 수비 역할과 묶어 기억하세요.',
        'Tie court-location terms to their defensive jobs.'),
    _styleFloorShortSeed(
        'low_man',
        3,
        _QuizCategory.positions,
        '약측 아래쪽에서 롤맨을 태그하고 코너 회복을 맡는 도움 수비수',
        'weak-side defender who tags the roller from low position and recovers toward the corner',
        const ['로우맨', 'low man', 'low-man'],
        '정답은 "로우맨"입니다. 림 보호와 코너 슈터 회복 사이의 핵심 역할입니다.',
        'The answer is "low man." It balances rim help and corner recovery.',
        '약측 수비는 공에서 멀어도 가장 중요한 결정을 할 수 있습니다.',
        'Weak-side defenders can make the most important decision.'),
    _styleFloorShortSeed(
        'closeout',
        1,
        _QuizCategory.technique,
        '패스를 받은 슈터에게 달려가 슛은 방해하고 돌파는 막는 수비 동작',
        'defensive action that runs to a shooter to contest while containing the drive',
        const ['클로즈아웃', 'closeout', 'close-out'],
        '정답은 "클로즈아웃"입니다. 마지막 스텝을 줄여 균형을 잡는 것이 중요합니다.',
        'The answer is "closeout." Chopping the last steps keeps balance.',
        '클로즈아웃은 달리는 속도보다 멈추는 질이 중요합니다.',
        'Closeout quality depends on how you stop.'),
    _styleFloorShortSeed(
        'box_out',
        1,
        _QuizCategory.technique,
        '리바운드 전 상대의 진입 경로를 몸으로 막는 기본 기술',
        'basic rebounding skill that uses the body to block an opponent’s path before the ball drops',
        const ['박스아웃', 'box out', 'boxing out', 'box-out'],
        '정답은 "박스아웃"입니다. 공보다 먼저 상대 위치를 잡아야 합니다.',
        'The answer is "box out." Find the opponent before chasing the ball.',
        '슛이 올라가면 공만 보지 말고 먼저 몸을 붙이세요.',
        'On the shot, make body contact before chasing.'),
    _styleFloorShortSeed(
        'short_roll',
        3,
        _QuizCategory.tactics,
        '스크린 후 림까지 깊게 가지 않고 중간 지점에서 받아 패스나 플로터를 읽는 롤',
        'roll that catches in the middle area instead of diving all the way to the rim to read pass or floater',
        const ['숏롤', 'short roll', 'short-roll'],
        '정답은 "숏롤"입니다. 압박을 끌어낸 뒤 4대3 상황을 읽는 핵심 선택입니다.',
        'The answer is "short roll." It often creates a 4-on-3 read after pressure.',
        '숏롤은 득점보다 다음 패스 판단까지 함께 보세요.',
        'Short-roll reads include the next pass, not only scoring.'),
    _styleFloorShortSeed(
        'skip_pass',
        2,
        _QuizCategory.tactics,
        '수비가 한쪽으로 몰렸을 때 반대편으로 길게 넘기는 패스',
        'long pass to the opposite side when the defense overloads one side',
        const ['스킵 패스', 'skip pass'],
        '정답은 "스킵 패스"입니다. 약측의 시간과 공간을 활용하는 패스입니다.',
        'The answer is "skip pass." It uses time and space on the weak side.',
        '좋은 스킵 패스는 패스 힘보다 수비 회전 타이밍이 중요합니다.',
        'A good skip pass attacks defensive rotation timing.'),
    _styleFloorShortSeed(
        'flare_screen',
        2,
        _QuizCategory.tactics,
        '슈터가 공에서 멀어지는 방향으로 벌어지도록 도와주는 스크린',
        'screen that frees a shooter moving away from the ball toward the perimeter',
        const ['플레어 스크린', 'flare screen'],
        '정답은 "플레어 스크린"입니다. 수비 시야 밖으로 벌어지는 슛 공간을 만듭니다.',
        'The answer is "flare screen." It creates shooting space away from the ball.',
        '스크린은 방향과 받는 선수의 다음 슛까지 연결하세요.',
        'Connect screen direction with the receiver’s next shot.'),
    _styleFloorShortSeed(
        'backdoor_cut',
        2,
        _QuizCategory.tactics,
        '수비가 패스 라인을 과하게 막을 때 등 뒤 공간으로 파고드는 컷',
        'cut that attacks behind a defender who overplays the passing lane',
        const ['백도어 컷', 'backdoor cut', 'back cut'],
        '정답은 "백도어 컷"입니다. 과한 압박의 등 뒤 공간을 벌칙으로 사용합니다.',
        'The answer is "backdoor cut." It punishes the space behind overplay.',
        '컷 타이밍은 패서와 눈이 맞는 순간이 중요합니다.',
        'Cut timing often starts with eye contact with the passer.'),
    _styleFloorShortSeed(
        'transition_defense',
        1,
        _QuizCategory.tactics,
        '공격에서 수비로 바뀌는 순간 속공을 막기 위한 수비 전환',
        'defense that handles the moment after offense changes to defense to stop fast breaks',
        const ['트랜지션 수비', '속공 수비', 'transition defense'],
        '정답은 "트랜지션 수비"입니다. 공을 늦추고 림을 지키는 역할 분담이 우선입니다.',
        'The answer is "transition defense." Slowing ball and protecting rim come first.',
        '턴오버 직후 첫 세 걸음의 역할 콜을 훈련하세요.',
        'Train role calls in the first steps after a turnover.'),
    _styleFloorShortSeed(
        'weak_side',
        1,
        _QuizCategory.positions,
        '공이 있는 쪽의 반대편 코트 영역',
        'side of the court opposite the ball',
        const ['약측', '위크사이드', 'weak side', 'weakside'],
        '정답은 "약측"입니다. 도움과 회복, 스킵 패스가 자주 연결되는 영역입니다.',
        'The answer is "weak side." Help, recovery, and skip passes often connect there.',
        '공이 없을 때 약측 위치를 보는 습관을 만드세요.',
        'Build the habit of reading weak-side position off the ball.'),
    _styleFloorShortSeed(
        'pocket_pass',
        2,
        _QuizCategory.technique,
        '픽앤롤에서 수비 사이 좁은 틈으로 롤맨에게 넣는 낮은 패스',
        'low pass that slips through a narrow gap to the roller in pick-and-roll',
        const ['포켓 패스', 'pocket pass'],
        '정답은 "포켓 패스"입니다. 타이밍과 각도가 맞아야 롤맨이 바로 다음 선택을 할 수 있습니다.',
        'The answer is "pocket pass." Timing and angle let the roller make the next read.',
        '패스 기술은 공의 속도보다 받는 순간의 이점으로 평가하세요.',
        'Evaluate passes by the advantage at the catch.'),
  ];
}

List<_McqSeed> _basketballStyleFloorMcqSeeds() {
  return <_McqSeed>[
    const _McqSeed(
        id: 'short_roll_read',
        difficulty: 3,
        category: _QuizCategory.tactics,
        koStem: '숏롤을 받은 빅맨이 가장 먼저 읽어야 할 것은?',
        enStem:
            'After catching on the short roll, what should the big read first?',
        options: [
          _FootballQuizOption(
              koText: '로우맨 도움과 코너/덩커스팟 패스 각도',
              enText:
                  'Low-man help and the corner or dunker-spot passing angle'),
          _FootballQuizOption(
              koText: '벤치에서 누가 일어섰는지', enText: 'Who stood up from the bench'),
          _FootballQuizOption(
              koText: '무조건 뒤로 드리블하기', enText: 'Always dribble backward'),
          _FootballQuizOption(
              koText: '슛클락을 보지 않고 멈추기',
              enText: 'Stop without checking the shot clock')
        ],
        correctIndex: 0,
        koExplain: '숏롤은 4대3 판단을 만드는 액션이라 도움 수비가 어디서 오는지 먼저 봐야 합니다.',
        enExplain:
            'Short roll often creates a 4-on-3, so the first read is where help comes from.',
        koNextPoint: '빅맨 패스 판단은 수비의 첫 도움 발을 보며 시작하세요.',
        enNextPoint: 'Big-man passing reads start with the first help step.'),
    const _McqSeed(
        id: 'zone_middle_flash',
        difficulty: 2,
        category: _QuizCategory.tactics,
        koStem: '존 수비를 흔들기 위해 하이포스트에 선수가 플래시하는 이유는?',
        enStem:
            'Why does an offensive player flash to the high post against zone defense?',
        options: [
          _FootballQuizOption(
              koText: '존의 가운데 틈에서 패스와 슛 선택지를 만들기 위해',
              enText:
                  'To create pass and shot options in the middle gap of the zone'),
          _FootballQuizOption(
              koText: '샷클락을 없애기 위해', enText: 'To remove the shot clock'),
          _FootballQuizOption(
              koText: '모든 선수가 코너에만 서기 위해',
              enText: 'To keep every player only in the corners'),
          _FootballQuizOption(
              koText: '리바운드를 포기하기 위해', enText: 'To give up rebounding')
        ],
        correctIndex: 0,
        koExplain: '존의 가운데를 점유하면 수비가 모이거나 갈라져 킥아웃과 하이로우 선택이 생깁니다.',
        enExplain:
            'Occupying the middle can collapse or split the zone, opening kick-outs and high-low reads.',
        koNextPoint: '존 공격은 공 이동만큼 빈 공간 점유를 함께 보세요.',
        enNextPoint:
            'Zone offense uses space occupation as much as ball movement.'),
    const _McqSeed(
        id: 'late_clock_read',
        difficulty: 2,
        category: _QuizCategory.mindset,
        koStem: '샷클락 5초 이하에서 가장 좋은 판단 기준은?',
        enStem:
            'With five or fewer seconds on the shot clock, what is the best decision standard?',
        options: [
          _FootballQuizOption(
              koText: '림 위협, 오픈 슛, 파울 가능성을 빠르게 비교한다',
              enText:
                  'Quickly compare rim pressure, open shot, and foul chance'),
          _FootballQuizOption(
              koText: '아무도 슛하지 않고 시간을 넘긴다',
              enText: 'Let the clock expire without a shot'),
          _FootballQuizOption(
              koText: '수비가 정렬될 때까지 기다린다',
              enText: 'Wait until the defense is fully set'),
          _FootballQuizOption(
              koText: '항상 센터에게만 패스한다', enText: 'Always pass only to the center')
        ],
        correctIndex: 0,
        koExplain: '늦은 클락은 완벽한 공격보다 가장 기대값이 높은 빠른 선택을 요구합니다.',
        enExplain:
            'Late clock rewards the best available quick decision, not a perfect possession.',
        koNextPoint: '시간 압박에서는 선택지를 줄이고 실행 속도를 높이세요.',
        enNextPoint:
            'Under time pressure, reduce options and execute quickly.'),
  ];
}

List<_OxFactSeed> _tennisStyleFloorOxFacts() {
  return <_OxFactSeed>[
    _styleFloorOxSeed(
        'crosscourt_percentage',
        2,
        _QuizCategory.tactics,
        '크로스코트는 대각선 코트 길이와 낮은 중앙 네트 때문에 안정적인 선택이 될 때가 많다. O/X',
        'Crosscourt is often high percentage because the diagonal court is longer and the middle net is lower. True/False',
        '크로스코트는 코트 길이와 네트 높이 면에서 항상 가장 위험한 코스다. O/X',
        'Crosscourt is always the riskiest direction for court length and net height. True/False',
        '크로스코트는 실수 여유가 크고 랠리 균형을 되찾기 좋습니다.',
        'Crosscourt gives more margin and helps restore rally balance.',
        '위험한 다운더라인 전에 깊은 크로스코트로 균형을 잡아보세요.',
        'Use deep crosscourt before forcing down the line.'),
    _styleFloorOxSeed(
        'down_line_change_direction',
        2,
        _QuizCategory.technique,
        '상대 크로스코트 공을 다운더라인으로 바꾸는 선택은 방향 전환 실수 위험이 커질 수 있다. O/X',
        'Changing an opponent’s crosscourt ball down the line can increase direction-change error risk. True/False',
        '상대 크로스코트 공을 다운더라인으로 바꾸는 선택은 밸런스와 타점과 전혀 관련이 없다. O/X',
        'Changing an opponent’s crosscourt ball down the line has no relation to balance or contact point. True/False',
        '공의 진행 방향을 바꾸려면 타점, 밸런스, 라켓면이 더 정밀해야 합니다.',
        'Changing direction demands cleaner contact point, balance, and racket face.',
        '방향 전환은 공격 기회와 실수 위험을 같이 계산하세요.',
        'Direction changes require both opportunity and risk checks.'),
    _styleFloorOxSeed(
        'second_serve_spin',
        2,
        _QuizCategory.technique,
        '두 번째 서브는 안정성과 깊이를 위해 회전, 높이, 코스가 중요하다. O/X',
        'Second serve needs spin, height, and placement for safety and depth. True/False',
        '두 번째 서브는 속도만 빠르면 회전과 높이는 중요하지 않다. O/X',
        'On second serve, speed alone matters and spin or net clearance is not important. True/False',
        '두 번째 서브는 성공률과 공격당하지 않을 깊이를 함께 확보해야 합니다.',
        'Second serve must balance percentage with depth that avoids easy attack.',
        '서브 퀴즈는 속도보다 성공률과 다음 공을 함께 보세요.',
        'Read serve questions through percentage and the next ball.'),
    _styleFloorOxSeed(
        'split_step_timing',
        1,
        _QuizCategory.technique,
        '스플릿 스텝은 상대가 공을 치는 순간에 맞춰 반응 준비를 하는 동작이다. O/X',
        'A split step prepares reaction timing around the opponent’s contact. True/False',
        '스플릿 스텝은 상대 공이 이미 지나간 뒤 천천히 멈추는 동작이다. O/X',
        'A split step is a slow stop after the opponent’s ball has already passed. True/False',
        '상대 타격 순간에 가볍게 착지하면 어느 방향으로든 첫 발을 내기 쉽습니다.',
        'Landing lightly around contact makes the first step easier in either direction.',
        '풋워크는 빠르게 뛰기보다 출발 타이밍부터 맞추세요.',
        'Footwork starts with timing, not only speed.'),
    _styleFloorOxSeed(
        'approach_follow_net',
        2,
        _QuizCategory.tactics,
        '어프로치 샷을 친 뒤에는 네트 쪽으로 전진해 다음 발리 준비를 하는 것이 일반적인 목적이다. O/X',
        'After an approach shot, the usual purpose is to move forward and prepare for the next volley. True/False',
        '어프로치 샷은 친 뒤 베이스라인 뒤로 더 물러나기 위한 전용 샷이다. O/X',
        'An approach shot is specifically for retreating farther behind the baseline afterward. True/False',
        '어프로치 샷은 상대 시간을 줄이고 네트에서 마무리하기 위해 쓰는 전진 선택입니다.',
        'An approach shot takes time away and sets up a finish near the net.',
        '어프로치 후 멈추지 말고 다음 위치까지 하나의 패턴으로 보세요.',
        'Treat approach and next position as one pattern.'),
    _styleFloorOxSeed(
        'recovery_angle',
        2,
        _QuizCategory.positions,
        '테니스에서 회복 위치는 내가 친 공의 방향과 각도에 따라 달라질 수 있다. O/X',
        'In tennis, recovery position can change based on the direction and angle of the shot you hit. True/False',
        '테니스에서 회복 위치는 어떤 샷을 쳤든 항상 코트 정중앙 하나로 고정된다. O/X',
        'In tennis, recovery position is always one fixed court center regardless of the shot you hit. True/False',
        '상대가 칠 수 있는 각도는 내가 보낸 공의 위치에 따라 달라지므로 중앙 복귀도 상황별입니다.',
        'Opponent angles depend on your shot location, so recovery center is contextual.',
        '회복은 코트 정중앙이 아니라 상대 가능 각도의 중앙으로 생각하세요.',
        'Recover to the center of likely replies, not always the court center.'),
    _styleFloorOxSeed(
        'serve_wide_plus_one',
        2,
        _QuizCategory.tactics,
        '와이드 서브는 상대를 코트 밖으로 끌어내 다음 공 공간을 만들 수 있다. O/X',
        'A wide serve can pull the returner off court and open space for the next shot. True/False',
        '와이드 서브는 다음 공 공간을 만드는 데 절대 도움이 되지 않는다. O/X',
        'A wide serve never helps create space for the next shot. True/False',
        '서브는 한 방이 아니라 다음 공까지 설계하는 출발점입니다.',
        'Serve is often the start of a next-shot pattern, not a single isolated swing.',
        '서브 플러스 원은 서브 방향과 다음 공격 코스를 함께 외우세요.',
        'Serve plus one links serve direction with the next attack.'),
    _styleFloorOxSeed(
        'return_percentage',
        2,
        _QuizCategory.mindset,
        '강한 첫 서브 리턴은 깊이, 블록, 코트 안 성공률을 먼저 확보해야 할 때가 많다. O/X',
        'Against strong first serves, depth, block control, and in-court percentage often come first. True/False',
        '강한 첫 서브를 받을 때는 항상 전력 스윙으로 위너를 노리는 것이 가장 안정적이다. O/X',
        'Against a strong first serve, always swinging full power for a winner is the most stable return plan. True/False',
        '강한 서브 리턴은 포인트를 시작하는 안정성이 먼저일 때가 많습니다.',
        'Against strong serves, beginning the point safely often comes first.',
        '리턴은 공격보다 포인트를 시작하는 안정성을 먼저 볼 때가 많습니다.',
        'Return quality often starts with beginning the point safely.'),
    _styleFloorOxSeed(
        'kick_serve_backhand',
        2,
        _QuizCategory.technique,
        '킥 서브는 높게 튀는 궤적으로 상대 백핸드 쪽을 압박하는 데 쓰일 수 있다. O/X',
        'A kick serve can use a high bounce to pressure the opponent’s backhand side. True/False',
        '킥 서브는 바운드 후 타점을 높이는 효과와 전혀 관련이 없다. O/X',
        'A kick serve has no relation to raising the receiver’s contact point after the bounce. True/False',
        '킥 서브는 회전과 바운스로 타점을 높여 리턴을 어렵게 만들 수 있습니다.',
        'Kick serve uses spin and bounce to raise the contact point and challenge the return.',
        '서브 종류는 바운드 후 상대 타점까지 연결하세요.',
        'Serve type includes the receiver’s contact point after bounce.'),
    _styleFloorOxSeed(
        'drop_shot_deep_opponent',
        2,
        _QuizCategory.tactics,
        '상대가 베이스라인 뒤 깊게 물러나 있을 때 드롭샷은 좋은 선택지가 될 수 있다. O/X',
        'When the opponent is deep behind the baseline, a drop shot can become a good option. True/False',
        '드롭샷은 상대가 네트 바로 앞에 있을 때만 항상 써야 한다. O/X',
        'A drop shot should always be used only when the opponent is already right at the net. True/False',
        '드롭샷은 상대 위치와 균형을 보고 짧은 코트 공간을 쓰는 선택입니다.',
        'Drop shot uses the short court when the opponent’s position and balance allow it.',
        '드롭샷은 기술보다 쓰는 타이밍을 먼저 판단하세요.',
        'Drop-shot quality starts with timing selection.'),
    _styleFloorOxSeed(
        'volley_compact',
        1,
        _QuizCategory.technique,
        '발리는 큰 백스윙보다 짧고 단단한 준비와 앞쪽 타점이 중요하다. O/X',
        'Volleying values compact preparation and contact in front more than a big backswing. True/False',
        '발리는 네트 앞에서도 큰 백스윙을 할수록 항상 안정적이다. O/X',
        'At net, volleying is always more stable with a bigger backswing. True/False',
        '네트 앞에서는 시간이 짧아 라켓면 안정과 짧은 움직임이 중요합니다.',
        'At net, time is short, so racket-face stability and compact movement matter.',
        '발리는 치는 힘보다 준비 위치와 라켓면을 먼저 보세요.',
        'Volley questions start with ready position and racket face.'),
    _styleFloorOxSeed(
        'lob_reset_net_player',
        2,
        _QuizCategory.tactics,
        '상대가 네트에 붙어 있을 때 로브는 시간을 벌거나 뒤 공간을 공격하는 선택이 될 수 있다. O/X',
        'When the opponent is at net, a lob can buy time or attack the space behind. True/False',
        '상대가 네트에 붙어 있으면 로브는 규칙상 사용할 수 없다. O/X',
        'When the opponent is at net, a lob is not allowed by rule. True/False',
        '로브는 수비적 회복과 공격적 패싱을 모두 만들 수 있는 높이 조절 선택입니다.',
        'A lob can be defensive recovery or offensive use of space behind the net player.',
        '로브는 높이, 깊이, 상대 후진 속도를 함께 계산하세요.',
        'Lob decisions combine height, depth, and opponent recovery speed.'),
    _styleFloorOxSeed(
        'tiebreak_routine',
        2,
        _QuizCategory.mindset,
        '타이브레이크처럼 압박이 큰 순간일수록 서브 전 루틴과 목표 코스를 분명히 하는 것이 도움이 된다. O/X',
        'In pressure moments like a tiebreak, keeping routine and clear target selection can help. True/False',
        '타이브레이크에서는 압박이 크기 때문에 루틴을 줄이고 무조건 빨리 쳐야 한다. O/X',
        'In a tiebreak, pressure means the player should drop routines and always rush. True/False',
        '압박이 큰 포인트일수록 반복 가능한 루틴과 선택 기준이 안정에 도움이 됩니다.',
        'Under pressure, repeatable routine and clear target selection support stability.',
        '마인드 문항은 긴장 속에서도 반복할 행동 기준을 묻습니다.',
        'Mindset questions ask what stays repeatable under pressure.'),
    _styleFloorOxSeed(
        'inside_out_forehand',
        2,
        _QuizCategory.tactics,
        '인사이드아웃 포핸드는 백핸드 쪽 공을 돌아서 치며 반대 코트로 각을 만들 수 있다. O/X',
        'An inside-out forehand can run around the backhand side and create angle to the opposite court. True/False',
        '인사이드아웃 포핸드는 발 위치와 코트 회복 위험을 전혀 만들지 않는다. O/X',
        'An inside-out forehand creates no footwork or recovery risk. True/False',
        '인사이드아웃은 발 위치와 코트 회복 리스크까지 같이 고려해야 하는 공격 패턴입니다.',
        'Inside-out forehand is an attacking pattern with footwork and recovery risk.',
        '공격 패턴은 타구 후 비는 공간까지 함께 보세요.',
        'Attacking patterns include the space left after the shot.'),
    _styleFloorOxSeed(
        'baseline_rally_depth',
        1,
        _QuizCategory.mindset,
        '베이스라인 랠리는 깊이와 실수 관리로 상대 압박을 만들며 기회를 기다리는 과정이 될 수 있다. O/X',
        'Baseline rallies can build pressure with depth and error control while waiting for chances. True/False',
        '베이스라인 랠리는 항상 위너만 노려야 하고 깊이와 실수 관리는 중요하지 않다. O/X',
        'Baseline rallies should always chase winners, and depth or error control does not matter. True/False',
        '랠리 운영은 깊이, 높이, 방향 변화를 통해 상대 실수를 만들거나 기회를 기다리는 과정입니다.',
        'Baseline play uses depth, height, and direction to build pressure and wait for chances.',
        '랠리 퀴즈는 한 방보다 다음 공을 쉽게 만드는 선택을 보세요.',
        'Rally questions value setting up the next ball.'),
    _styleFloorOxSeed(
        'body_serve_jam',
        2,
        _QuizCategory.tactics,
        '바디 서브는 상대 몸쪽을 공략해 스윙 공간을 줄이는 전략이 될 수 있다. O/X',
        'A body serve can jam the returner by reducing swing space. True/False',
        '바디 서브는 상대의 스윙 공간에 아무 영향도 주지 않는 코스다. O/X',
        'A body serve has no effect on the returner’s swing space. True/False',
        '바디 서브는 에이스보다 리턴 품질을 낮춰 다음 공 우위를 만드는 목적도 있습니다.',
        'Body serve can lower return quality and set up the next ball, not only chase aces.',
        '서브 코스는 상대가 편하게 휘두를 공간을 기준으로 보세요.',
        'Serve placement should consider the receiver’s swing space.'),
  ];
}

List<_ShortAnswerKnowledgeSeed> _tennisStyleFloorShortSeeds() {
  return <_ShortAnswerKnowledgeSeed>[
    _styleFloorShortSeed(
        'split_step',
        1,
        _QuizCategory.technique,
        '상대 타격 순간에 맞춰 가볍게 뛰어 어느 방향이든 출발 준비를 하는 풋워크',
        'footwork hop that times with opponent contact to prepare movement in either direction',
        const ['스플릿 스텝', 'split step', 'split-step'],
        '정답은 "스플릿 스텝"입니다. 첫 발 반응을 빠르게 만드는 준비 동작입니다.',
        'The answer is "split step." It prepares a quicker first step.',
        '상대가 맞히는 순간에 착지하는 리듬을 훈련하세요.',
        'Train landing rhythm around opponent contact.'),
    _styleFloorShortSeed(
        'kick_serve',
        2,
        _QuizCategory.technique,
        '높게 튀는 회전으로 상대 타점을 올리는 서브',
        'serve that uses spin to bounce high and raise the receiver’s contact point',
        const ['킥 서브', 'kick serve', 'kick'],
        '정답은 "킥 서브"입니다. 회전과 바운스로 리턴을 어렵게 만듭니다.',
        'The answer is "kick serve." Spin and bounce challenge the return.',
        '서브는 네트를 넘는 순간보다 바운드 후 효과까지 보세요.',
        'Evaluate serves by their effect after bounce.'),
    _styleFloorShortSeed(
        'slice',
        1,
        _QuizCategory.technique,
        '공 아래를 깎듯이 맞혀 낮고 미끄러지는 궤적을 만드는 샷',
        'shot that cuts under the ball to create a lower skidding trajectory',
        const ['슬라이스', 'slice'],
        '정답은 "슬라이스"입니다. 낮은 바운드와 리듬 변화로 상대 타점을 흔듭니다.',
        'The answer is "slice." It changes rhythm and keeps the bounce lower.',
        '슬라이스는 수비 회복과 공격 전환을 모두 만들 수 있습니다.',
        'Slice can support both recovery and transition.'),
    _styleFloorShortSeed(
        'approach_shot',
        1,
        _QuizCategory.tactics,
        '네트로 전진하기 위해 깊게 치고 들어가는 준비 샷',
        'shot hit to move forward toward the net and set up a volley',
        const ['어프로치 샷', 'approach shot', 'approach'],
        '정답은 "어프로치 샷"입니다. 상대 시간을 줄이고 다음 발리를 준비하는 샷입니다.',
        'The answer is "approach shot." It takes time away and prepares the volley.',
        '어프로치는 친 뒤의 위치 이동까지 한 동작으로 보세요.',
        'Approach includes the movement after the shot.'),
    _styleFloorShortSeed(
        'drop_shot',
        1,
        _QuizCategory.tactics,
        '상대를 앞으로 끌어내기 위해 네트 근처에 짧게 떨어뜨리는 샷',
        'shot that lands short near the net to pull the opponent forward',
        const ['드롭샷', '드롭 샷', 'drop shot'],
        '정답은 "드롭샷"입니다. 상대가 깊이 물러났거나 균형이 무너졌을 때 효과가 커집니다.',
        'The answer is "drop shot." It is strongest when the opponent is deep or off balance.',
        '드롭샷은 손기술보다 상대 위치 판단이 먼저입니다.',
        'Drop-shot choice starts with opponent position.'),
    _styleFloorShortSeed(
        'lob',
        1,
        _QuizCategory.tactics,
        '네트에 붙은 상대 머리 위로 높고 깊게 넘기는 샷',
        'shot that goes high and deep over an opponent at the net',
        const ['로브', 'lob'],
        '정답은 "로브"입니다. 뒤 공간을 공격하거나 수비 시간을 벌 수 있습니다.',
        'The answer is "lob." It attacks space behind or buys recovery time.',
        '로브는 높이와 깊이가 함께 맞아야 반격을 줄입니다.',
        'A lob needs both height and depth.'),
    _styleFloorShortSeed(
        'volley',
        1,
        _QuizCategory.technique,
        '공이 바운드되기 전에 네트 근처에서 처리하는 샷',
        'shot played near the net before the ball bounces',
        const ['발리', 'volley'],
        '정답은 "발리"입니다. 짧은 준비와 안정된 라켓면이 핵심입니다.',
        'The answer is "volley." Compact preparation and stable racket face matter.',
        '발리는 힘보다 타점과 라켓면을 먼저 훈련하세요.',
        'Train volley contact and racket face before power.'),
    _styleFloorShortSeed(
        'crosscourt',
        1,
        _QuizCategory.tactics,
        '코트 대각선 방향으로 보내는 샷 방향',
        'shot direction that sends the ball diagonally across the court',
        const ['크로스코트', 'crosscourt', 'cross court'],
        '정답은 "크로스코트"입니다. 대각선 길이와 낮은 중앙 네트 덕분에 안정성이 높습니다.',
        'The answer is "crosscourt." It has more diagonal length and a lower middle net.',
        '방향 용어는 실수 여유와 함께 기억하세요.',
        'Direction terms connect to margin.'),
    _styleFloorShortSeed(
        'down_the_line',
        2,
        _QuizCategory.tactics,
        '사이드라인을 따라 직선으로 보내는 공격적인 코스',
        'attacking direction that sends the ball straight along the sideline',
        const ['다운더라인', '다운 더 라인', 'down the line', 'down-the-line'],
        '정답은 "다운더라인"입니다. 공격적이지만 네트 높이와 코트 길이 여유가 줄어듭니다.',
        'The answer is "down the line." It is aggressive but has less margin.',
        '다운더라인은 균형이 좋고 공이 짧을 때 선택하세요.',
        'Use down the line when balanced and given a shorter ball.'),
    _styleFloorShortSeed(
        'inside_out',
        2,
        _QuizCategory.tactics,
        '백핸드 쪽 공을 돌아서 포핸드로 반대 코트 대각 방향에 치는 패턴',
        'pattern that runs around the backhand side to hit a forehand diagonally to the opposite court',
        const ['인사이드아웃', 'inside out', 'inside-out'],
        '정답은 "인사이드아웃"입니다. 강한 포핸드를 쓰지만 회복 위치 위험도 생깁니다.',
        'The answer is "inside-out." It uses a strong forehand while creating recovery risk.',
        '공격 패턴은 친 뒤 비는 공간을 함께 계산하세요.',
        'Attacking patterns include the space left after contact.'),
    _styleFloorShortSeed(
        'hold_serve',
        1,
        _QuizCategory.fun,
        '자신의 서브 게임을 지켜내는 것',
        'winning your own service game',
        const ['홀드', 'hold', 'hold serve', 'service hold'],
        '정답은 "홀드"입니다. 서브 게임을 안정적으로 지키는 경기 운영 지표입니다.',
        'The answer is "hold." It shows the server protected their game.',
        '경기 흐름은 브레이크뿐 아니라 홀드 안정성으로도 보세요.',
        'Match flow includes service holds as well as breaks.'),
    _styleFloorShortSeed(
        'tiebreak',
        1,
        _QuizCategory.rules,
        '게임 스코어가 특정 동률일 때 짧은 포인트제로 세트를 결정하는 방식',
        'short point-scoring format that decides a set at a specified tied game score',
        const ['타이브레이크', '타이브레이커', 'tiebreak', 'tiebreaker'],
        '정답은 "타이브레이크"입니다. 압박 속에서도 루틴과 첫 서브 확률이 중요합니다.',
        'The answer is "tiebreak." Routine and first-serve percentage become especially important.',
        '룰 용어는 그 순간의 멘탈 관리까지 연결하세요.',
        'Rule terms connect to mental management in that moment.'),
    _styleFloorShortSeed(
        'return_depth',
        2,
        _QuizCategory.technique,
        '상대 첫 공격을 줄이기 위해 리턴을 베이스라인 가까이 깊게 보내는 품질',
        'return quality that sends the ball deep near the baseline to reduce the opponent’s first attack',
        const ['리턴 깊이', '깊은 리턴', 'return depth', 'deep return'],
        '정답은 "리턴 깊이"입니다. 강타보다 깊이가 상대의 다음 공격 시간을 줄일 수 있습니다.',
        'The answer is "return depth." Depth can take time away even without maximum power.',
        '리턴은 위너보다 코트 안 깊이를 먼저 목표로 잡으세요.',
        'On return, prioritize in-court depth before winners.'),
    _styleFloorShortSeed(
        'recovery_step',
        2,
        _QuizCategory.positions,
        '타구 후 상대가 칠 수 있는 각도의 중앙으로 다시 움직이는 동작',
        'movement that returns toward the center of the opponent’s likely reply angles after a shot',
        const ['리커버리', '회복 스텝', 'recovery', 'recovery step'],
        '정답은 "리커버리" 또는 "회복 스텝"입니다. 내가 친 공의 위치에 따라 기준점이 달라집니다.',
        'The answer is "recovery step." The target changes based on your shot location.',
        '다음 공 준비는 치고 난 직후 첫 발에서 시작됩니다.',
        'Preparation for the next ball starts with the first step after contact.'),
    _styleFloorShortSeed(
        'body_serve',
        2,
        _QuizCategory.tactics,
        '상대 몸쪽으로 넣어 스윙 공간을 줄이는 서브 코스',
        'serve placement that targets the returner’s body to reduce swing space',
        const ['바디 서브', 'body serve'],
        '정답은 "바디 서브"입니다. 상대를 움직이기보다 몸쪽에서 리턴을 막히게 할 수 있습니다.',
        'The answer is "body serve." It can jam the return rather than move the receiver wide.',
        '서브 코스는 상대가 라켓을 편하게 빼는지까지 보세요.',
        'Serve location includes how freely the receiver can swing.'),
  ];
}

List<_McqSeed> _tennisStyleFloorMcqSeeds() {
  return <_McqSeed>[
    const _McqSeed(
        id: 'serve_plus_one_space',
        difficulty: 2,
        category: _QuizCategory.tactics,
        koStem: '와이드 서브 후 “서브 플러스 원”의 좋은 다음 판단은?',
        enStem: 'After a wide serve, what is a good serve-plus-one read?',
        options: [
          _FootballQuizOption(
              koText: '상대가 코트 밖으로 밀린 뒤 열린 공간을 본다',
              enText:
                  'Read the open space after the returner is pulled off court'),
          _FootballQuizOption(
              koText: '무조건 같은 위치로 천천히 돌려준다',
              enText: 'Always send the next ball slowly to the same spot'),
          _FootballQuizOption(
              koText: '상대 위치와 상관없이 눈을 감고 친다',
              enText: 'Hit without reading the opponent position'),
          _FootballQuizOption(
              koText: '다음 공 준비를 하지 않는다',
              enText: 'Do not prepare for the next ball')
        ],
        correctIndex: 0,
        koExplain: '서브 플러스 원은 서브로 만든 위치 이점을 다음 샷으로 이어가는 패턴입니다.',
        enExplain:
            'Serve plus one connects the positional advantage created by the serve to the next shot.',
        koNextPoint: '서브는 첫 타구가 아니라 다음 공격까지 한 묶음으로 보세요.',
        enNextPoint: 'Treat serve and next attack as one package.'),
    const _McqSeed(
        id: 'return_first_serve',
        difficulty: 2,
        category: _QuizCategory.technique,
        koStem: '강한 첫 서브를 받을 때 리턴의 기본 목표로 가장 좋은 것은?',
        enStem:
            'Against a strong first serve, what is the best basic return goal?',
        options: [
          _FootballQuizOption(
              koText: '짧은 준비로 코트 안 깊게 넣어 포인트를 시작한다',
              enText: 'Use compact preparation to put a deep return in play'),
          _FootballQuizOption(
              koText: '항상 풀스윙 위너만 노린다',
              enText: 'Always swing full for a winner'),
          _FootballQuizOption(
              koText: '공이 지나간 뒤 스플릿 스텝을 한다',
              enText: 'Split step after the ball has passed'),
          _FootballQuizOption(
              koText: '라켓면을 매번 크게 열어 플라이볼을 만든다',
              enText: 'Open the racket face greatly every time')
        ],
        correctIndex: 0,
        koExplain: '강한 서브 리턴은 성공률과 깊이를 먼저 확보해야 상대의 첫 공격을 줄일 수 있습니다.',
        enExplain:
            'Against pace, return percentage and depth reduce the server’s first attack.',
        koNextPoint: '리턴은 강함보다 준비 크기와 타점 안정성을 먼저 점검하세요.',
        enNextPoint:
            'Check preparation size and contact stability before power.'),
  ];
}

List<_FootballQuizQuestion> _buildBaseballQuizPool() {
  return <_FootballQuizQuestion>[
    _sportQuizQuestion(
      id: 'baseball_mcq_strike_zone',
      conceptKey: 'baseball_strike_zone',
      difficulty: 1,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.rules,
      koPrompt: '타자가 치지 않았을 때 스트라이크가 되는 가장 기본 조건은?',
      enPrompt: 'When a batter does not swing, what makes the pitch a strike?',
      options: const [
        _FootballQuizOption(
            koText: '스트라이크존을 통과한다',
            enText: 'It passes through the strike zone'),
        _FootballQuizOption(
            koText: '포수가 크게 외친다', enText: 'The catcher calls loudly'),
        _FootballQuizOption(koText: '공이 빠르게 온다', enText: 'The pitch is fast'),
        _FootballQuizOption(
            koText: '타자가 한 발 움직인다', enText: 'The batter moves one foot'),
      ],
      correctIndex: 0,
      koExplain: '스트라이크존을 통과한 투구는 타자가 치지 않아도 스트라이크입니다.',
      enExplain:
          'A pitch through the strike zone is a strike even if the batter does not swing.',
      koNextPoint: '존을 숫자로 외우기보다 무릎-가슴 사이 높이를 먼저 보세요.',
      enNextPoint:
          'Read the height window first instead of memorizing it mechanically.',
    ),
    _sportQuizQuestion(
      id: 'baseball_mcq_force_out',
      conceptKey: 'baseball_force_out',
      difficulty: 1,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.rules,
      koPrompt: '포스 아웃 상황에서 수비가 가장 먼저 확인할 것은?',
      enPrompt:
          'In a force-out situation, what should the defense confirm first?',
      options: const [
        _FootballQuizOption(
            koText: '주자가 반드시 가야 하는 베이스',
            enText: 'The base the runner is forced to reach'),
        _FootballQuizOption(
            koText: '주자가 리드하고 있는 방향',
            enText: 'The direction of the runner lead'),
        _FootballQuizOption(koText: '투수의 투구 템포', enText: 'The pitcher tempo'),
        _FootballQuizOption(
            koText: '타자가 다음 공을 기다리는 위치',
            enText: 'The hitter setup for the next pitch'),
      ],
      correctIndex: 0,
      koExplain: '포스 아웃은 주자가 밀려서 반드시 가야 하는 베이스를 공보다 늦게 밟으면 아웃입니다.',
      enExplain:
          'A force out happens when the ball reaches the forced base before the runner.',
      koNextPoint: '상황을 보기 전 아웃카운트와 주자 위치를 먼저 말해보세요.',
      enNextPoint: 'Call the outs and runner positions before the pitch.',
    ),
    _sportQuizQuestion(
      id: 'baseball_mcq_tag_up',
      conceptKey: 'baseball_tag_up',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.tactics,
      koPrompt: '플라이볼이 잡혔을 때 태그업을 하려면 주자는 어떻게 해야 할까?',
      enPrompt: 'After a fly ball is caught, what must a runner do to tag up?',
      options: const [
        _FootballQuizOption(
            koText: '원래 베이스를 다시 밟고 출발한다',
            enText: 'Retouch the original base before leaving'),
        _FootballQuizOption(
            koText: '바로 다음 베이스로 뛴다',
            enText: 'Run immediately to the next base'),
        _FootballQuizOption(
            koText: '타석으로 돌아간다', enText: 'Return to home plate'),
        _FootballQuizOption(
            koText: '공이 잡히기 전 먼저 출발한다',
            enText: 'Leave before the ball is caught'),
      ],
      correctIndex: 0,
      koExplain: '잡힌 플라이볼에서는 포구 이후 원래 베이스를 밟은 뒤 진루해야 합니다.',
      enExplain:
          'On a caught fly ball, the runner must retouch the base before advancing.',
      koNextPoint: '외야수의 어깨와 포구 위치를 함께 보고 뛰는 결정을 하세요.',
      enNextPoint:
          'Judge both the outfielder arm and catch location before going.',
    ),
    _sportQuizQuestion(
      id: 'baseball_mcq_infield_fly',
      conceptKey: 'baseball_infield_fly',
      difficulty: 3,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.rules,
      koPrompt: '인필드 플라이 규칙의 핵심 목적은?',
      enPrompt: 'What is the core purpose of the infield fly rule?',
      options: const [
        _FootballQuizOption(
            koText: '고의 낙구로 병살을 노리는 상황을 막는다',
            enText: 'Prevent an intentional drop to create a double play'),
        _FootballQuizOption(
            koText: '모든 뜬공에서 주자 진루를 금지한다',
            enText: 'Ban runner advancement on every fly ball'),
        _FootballQuizOption(
            koText: '외야 뜬공을 항상 자동 아웃으로 만든다',
            enText: 'Make every outfield fly ball an automatic out'),
        _FootballQuizOption(
            koText: '주자가 없는 상황에서도 항상 적용한다',
            enText: 'Apply it every time even with no runners on base'),
      ],
      correctIndex: 0,
      koExplain: '인필드 플라이는 쉬운 내야 뜬공을 일부러 떨어뜨려 주자를 속이는 플레이를 제한합니다.',
      enExplain:
          'The rule limits intentional drops on easy infield popups that could trap runners.',
      koNextPoint: '무사/1사, 1·2루 또는 만루 상황을 함께 확인하세요.',
      enNextPoint: 'Pair the rule with outs and runner configuration.',
    ),
    _sportQuizQuestion(
      id: 'baseball_mcq_cutoff',
      conceptKey: 'baseball_cutoff_throw',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.positions,
      koPrompt: '외야 송구에서 컷오프맨의 가장 중요한 역할은?',
      enPrompt: 'What is the key role of a cutoff player on an outfield throw?',
      options: const [
        _FootballQuizOption(
            koText: '송구 거리를 줄이고 다음 플레이 방향을 결정한다',
            enText: 'Shorten the throw and redirect the next play'),
        _FootballQuizOption(
            koText: '중계 위치보다 공을 더 오래 들고 있는다',
            enText: 'Hold the ball longer than the relay needs'),
        _FootballQuizOption(
            koText: '공을 오래 들고 시간을 끈다', enText: 'Hold the ball to waste time'),
        _FootballQuizOption(koText: '항상 홈으로만 던진다', enText: 'Always throw home'),
      ],
      correctIndex: 0,
      koExplain: '컷오프는 긴 송구를 안전하게 연결하고 주자의 추가 진루를 제어합니다.',
      enExplain:
          'The cutoff connects long throws safely and controls extra bases.',
      koNextPoint: '공을 받기 전 몸 방향을 목표 베이스 쪽으로 열어두세요.',
      enNextPoint: 'Open your body toward the target base before receiving.',
    ),
    _sportQuizQuestion(
      id: 'baseball_mcq_count_3_0',
      conceptKey: 'baseball_count_3_0',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.mindset,
      koPrompt: '볼카운트 3-0에서 어린 타자에게 가장 안전한 기본 선택은?',
      enPrompt:
          'On a 3-0 count, what is the safest default for a young hitter?',
      options: const [
        _FootballQuizOption(
            koText: '좋은 공이 아니면 기다린다',
            enText: 'Take unless it is a very good pitch'),
        _FootballQuizOption(koText: '무조건 번트한다', enText: 'Always bunt'),
        _FootballQuizOption(koText: '아무 공이나 친다', enText: 'Swing at anything'),
        _FootballQuizOption(
            koText: '타석 밖으로 나간다', enText: 'Step out of the box'),
      ],
      correctIndex: 0,
      koExplain: '3-0은 타자에게 유리한 카운트라 존 관리와 선구안이 우선입니다.',
      enExplain: 'A 3-0 count favors the hitter, so discipline comes first.',
      koNextPoint: '코치 사인이 없다면 자기 존 한가운데만 노리세요.',
      enNextPoint: 'Without a coach sign, look only for your best zone.',
    ),
    _sportQuizQuestion(
      id: 'baseball_mcq_bunt_use',
      conceptKey: 'baseball_sacrifice_bunt',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.tactics,
      koPrompt: '희생번트를 쓰기 좋은 대표 상황은?',
      enPrompt: 'What is a common situation for a sacrifice bunt?',
      options: const [
        _FootballQuizOption(
            koText: '주자를 한 베이스 진루시키는 것이 중요한 상황',
            enText: 'When advancing a runner one base is valuable'),
        _FootballQuizOption(
            koText: '무조건 장타가 필요한 상황',
            enText: 'When only an extra-base hit matters'),
        _FootballQuizOption(
            koText: '수비수가 모두 외야에 없을 때',
            enText: 'When all defenders are outside the outfield'),
        _FootballQuizOption(
            koText: '투수가 타석에 없을 때만',
            enText: 'Only when the pitcher is not batting'),
      ],
      correctIndex: 0,
      koExplain: '희생번트는 아웃 하나를 감수하고 주자의 위치 가치를 높이는 선택입니다.',
      enExplain: 'A sacrifice bunt trades an out to improve runner position.',
      koNextPoint: '번트 각도는 공을 죽이는 것보다 1루/3루 방향 선택이 중요합니다.',
      enNextPoint: 'The bunt direction often matters as much as soft contact.',
    ),
    _sportQuizQuestion(
      id: 'baseball_mcq_steal_timing',
      conceptKey: 'baseball_steal_timing',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.technique,
      koPrompt: '도루 스타트에서 가장 먼저 읽어야 할 단서는?',
      enPrompt: 'What cue should a base stealer read first?',
      options: const [
        _FootballQuizOption(
            koText: '투수의 첫 움직임과 견제 습관',
            enText: 'The pitcher first move and pickoff habit'),
        _FootballQuizOption(
            koText: '포수의 미트 위치만 보고 출발한다',
            enText: 'Start only from the catcher glove target'),
        _FootballQuizOption(
            koText: '리드 폭만 크게 잡고 귀루 균형은 보지 않는다',
            enText: 'Take a bigger lead without checking return balance'),
        _FootballQuizOption(
            koText: '타자의 스윙 결과를 본 뒤에야 출발한다',
            enText: 'Start only after seeing the hitter swing result'),
      ],
      correctIndex: 0,
      koExplain: '도루는 투수의 움직임, 포수 송구, 카운트가 함께 맞아야 성공률이 올라갑니다.',
      enExplain:
          'Steals improve when pitcher move, catcher arm, and count all line up.',
      koNextPoint: '리드 폭보다 되돌아갈 수 있는 균형부터 확인하세요.',
      enNextPoint: 'Balance for returning matters before lead size.',
    ),
    _sportQuizQuestion(
      id: 'baseball_mcq_double_play',
      conceptKey: 'baseball_double_play_priority',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.tactics,
      koPrompt: '병살을 노릴 때 내야수가 먼저 생각할 기준은?',
      enPrompt:
          'When turning a double play, what should an infielder decide first?',
      options: const [
        _FootballQuizOption(
            koText: '가장 확실한 첫 아웃 위치', enText: 'The most secure first out'),
        _FootballQuizOption(
            koText: '가장 멋진 송구 자세', enText: 'The most stylish throw'),
        _FootballQuizOption(
            koText: '외야수의 위치만', enText: 'Only the outfielder position'),
        _FootballQuizOption(koText: '타자의 표정', enText: 'The batter expression'),
      ],
      correctIndex: 0,
      koExplain: '첫 아웃을 안정적으로 잡아야 두 번째 아웃 기회가 이어집니다.',
      enExplain: 'A secure first out creates the chance for the second out.',
      koNextPoint: '공을 받기 전 발 위치와 송구 방향을 미리 정하세요.',
      enNextPoint: 'Set feet and throwing lane before the ball arrives.',
    ),
    _sportQuizQuestion(
      id: 'baseball_ox_foul_two_strikes',
      conceptKey: 'baseball_foul_two_strikes',
      difficulty: 1,
      style: _QuestionStyle.ox,
      category: _QuizCategory.rules,
      koPrompt: '일반적으로 2스트라이크 이후 파울은 삼진이 되지 않는다. O/X',
      enPrompt:
          'In general, a foul ball with two strikes is not strike three. True/False',
      options: const [
        _FootballQuizOption(koText: 'O', enText: 'True'),
        _FootballQuizOption(koText: 'X', enText: 'False'),
      ],
      correctIndex: 0,
      koExplain: '일반 파울은 2스트라이크 이후 카운트가 유지됩니다. 단, 번트 파울 등 예외가 있습니다.',
      enExplain:
          'A normal foul keeps the count at two strikes, with exceptions such as foul bunts.',
      koNextPoint: '예외 상황까지 같이 외워두면 경기 이해가 빨라집니다.',
      enNextPoint: 'Learn the exceptions together with the base rule.',
    ),
    _sportQuizQuestion(
      id: 'baseball_sa_sacrifice_bunt',
      conceptKey: 'baseball_sacrifice_bunt_term',
      difficulty: 1,
      style: _QuestionStyle.shortAnswer,
      category: _QuizCategory.fun,
      koPrompt: '아웃을 감수하고 주자를 진루시키는 번트를 무엇이라고 할까?',
      enPrompt: 'What bunt intentionally trades an out to advance a runner?',
      acceptedAnswers: const ['희생번트', 'sacrifice bunt', 'sac bunt'],
      koExplain: '희생번트는 팀 득점 기대를 위해 개인 기록보다 상황을 선택하는 플레이입니다.',
      enExplain:
          'A sacrifice bunt prioritizes the team situation over individual batting results.',
      koNextPoint: '번트 성공 후 다음 타자가 어떤 득점 기회를 갖는지 연결해서 보세요.',
      enNextPoint:
          'Connect the bunt to the scoring chance for the next hitter.',
    ),
    ..._athleteNutritionSportQuizQuestions(SportCatalog.baseballId),
    ..._styleFloorSportQuizQuestions(SportCatalog.baseballId),
    ..._advancedBaseballQuizQuestions(),
  ];
}

List<_FootballQuizQuestion> _buildBasketballQuizPool() {
  return <_FootballQuizQuestion>[
    _sportQuizQuestion(
      id: 'basketball_mcq_shot_clock',
      conceptKey: 'basketball_shot_clock',
      difficulty: 1,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.rules,
      koPrompt: '샷클락의 기본 목적은?',
      enPrompt: 'What is the basic purpose of the shot clock?',
      options: const [
        _FootballQuizOption(
            koText: '공격이 제한 시간 안에 슛하도록 만든다',
            enText: 'Force the offense to shoot within a time limit'),
        _FootballQuizOption(koText: '수비수를 쉬게 한다', enText: 'Let defenders rest'),
        _FootballQuizOption(koText: '자유투를 줄인다', enText: 'Reduce free throws'),
        _FootballQuizOption(koText: '드리블을 금지한다', enText: 'Ban dribbling'),
      ],
      correctIndex: 0,
      koExplain: '샷클락은 공격 시간을 제한해 경기 템포를 유지합니다.',
      enExplain: 'The shot clock limits possession time and keeps tempo.',
      koNextPoint: '남은 시간이 적을수록 빠른 결정과 리바운드 준비가 중요합니다.',
      enNextPoint: 'Low clock means quick decisions and rebound readiness.',
    ),
    _sportQuizQuestion(
      id: 'basketball_mcq_backcourt',
      conceptKey: 'basketball_backcourt_violation',
      difficulty: 1,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.rules,
      koPrompt: '백코트 바이얼레이션은 언제 발생할까?',
      enPrompt: 'When does a backcourt violation occur?',
      options: const [
        _FootballQuizOption(
            koText: '프런트코트로 넘어간 공을 공격팀이 다시 백코트에서 잡을 때',
            enText:
                'The offense regains the ball in backcourt after establishing frontcourt'),
        _FootballQuizOption(
            koText: '수비가 리바운드를 잡을 때', enText: 'The defense gets a rebound'),
        _FootballQuizOption(
            koText: '자유투가 빗나갈 때', enText: 'A free throw misses'),
        _FootballQuizOption(
            koText: '감독이 작전을 부를 때', enText: 'A coach calls a play'),
      ],
      correctIndex: 0,
      koExplain: '공격권을 가진 팀이 프런트코트 확립 후 다시 백코트에서 공을 잡으면 위반입니다.',
      enExplain:
          'After frontcourt is established, the offense cannot be first to control it in backcourt.',
      koNextPoint: '하프라인 근처에서는 패스 각도와 발 위치를 같이 확인하세요.',
      enNextPoint:
          'Near half court, check passing angle and foot position together.',
    ),
    _sportQuizQuestion(
      id: 'basketball_mcq_legal_screen',
      conceptKey: 'basketball_legal_screen',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.rules,
      koPrompt: '합법적인 스크린의 핵심은?',
      enPrompt: 'What is the key to a legal screen?',
      options: const [
        _FootballQuizOption(
            koText: '멈춘 자세로 상대에게 피할 공간을 준다',
            enText:
                'Be stationary and give the defender space to avoid contact'),
        _FootballQuizOption(
            koText: '몸으로 계속 밀어낸다', enText: 'Keep pushing with the body'),
        _FootballQuizOption(
            koText: '팔을 벌려 붙잡는다', enText: 'Use arms to hold the defender'),
        _FootballQuizOption(
            koText: '상대 뒤에서 무조건 부딪힌다',
            enText: 'Hit the defender from behind every time'),
      ],
      correctIndex: 0,
      koExplain: '움직이며 밀거나 팔로 막으면 공격자 파울이 될 수 있습니다.',
      enExplain:
          'Moving into contact or using arms can become an offensive foul.',
      koNextPoint: '스크린 후에는 멈추고, 방향을 열어 롤 또는 팝을 준비하세요.',
      enNextPoint: 'After setting, hold position and prepare to roll or pop.',
    ),
    _sportQuizQuestion(
      id: 'basketball_mcq_pick_roll',
      conceptKey: 'basketball_pick_and_roll_read',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.tactics,
      koPrompt: '픽앤롤에서 볼 핸들러가 먼저 읽어야 할 것은?',
      enPrompt: 'In pick-and-roll, what should the ball handler read first?',
      options: const [
        _FootballQuizOption(
            koText: '스크린 수비의 대응 방식', enText: 'How the screen defender reacts'),
        _FootballQuizOption(
            koText: '코너 수비수가 도움을 얼마나 좁히는지',
            enText: 'How far the corner defender helps inside'),
        _FootballQuizOption(
            koText: '롤맨이 어느 손으로 마무리하는지',
            enText: 'Which hand the roller prefers to finish with'),
        _FootballQuizOption(
            koText: '약측 슈터가 얼마나 높게 올라오는지',
            enText: 'How high the weak-side shooter lifts'),
      ],
      correctIndex: 0,
      koExplain: '드롭, 스위치, 헤지에 따라 슛, 패스, 돌파 선택이 달라집니다.',
      enExplain:
          'Drop, switch, or hedge coverage changes the shot, pass, or drive choice.',
      koNextPoint: '스크린을 받기 전 속도를 줄여 수비 반응을 보세요.',
      enNextPoint: 'Slow slightly before the screen to read coverage.',
    ),
    _sportQuizQuestion(
      id: 'basketball_mcq_box_out',
      conceptKey: 'basketball_box_out',
      difficulty: 1,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.technique,
      koPrompt: '박스아웃의 기본 목적은?',
      enPrompt: 'What is the basic purpose of boxing out?',
      options: const [
        _FootballQuizOption(
            koText: '상대의 리바운드 진입 길을 막는다',
            enText: 'Block the opponent path to the rebound'),
        _FootballQuizOption(koText: '더 멀리 드리블한다', enText: 'Dribble farther'),
        _FootballQuizOption(koText: '슛 폼을 바꾼다', enText: 'Change shooting form'),
        _FootballQuizOption(
            koText: '리바운드가 떨어진 뒤에만 몸을 붙인다',
            enText: 'Make contact only after the rebound drops'),
      ],
      correctIndex: 0,
      koExplain: '박스아웃은 공만 보는 것이 아니라 먼저 몸으로 위치를 잡는 기술입니다.',
      enExplain:
          'Boxing out is about claiming position before watching only the ball.',
      koNextPoint: '슛이 올라가면 먼저 상대를 찾고 그다음 공을 보세요.',
      enNextPoint: 'On the shot, find your opponent first, then the ball.',
    ),
    _sportQuizQuestion(
      id: 'basketball_mcq_closeout',
      conceptKey: 'basketball_closeout',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.training,
      koPrompt: '클로즈아웃 수비에서 좋은 마지막 동작은?',
      enPrompt: 'What is a good final action in a closeout?',
      options: const [
        _FootballQuizOption(
            koText: '짧은 스텝으로 속도를 줄이고 한 손으로 슛을 방해한다',
            enText: 'Chop steps, slow down, and contest with one hand'),
        _FootballQuizOption(
            koText: '무조건 점프해서 지나친다', enText: 'Always jump past the shooter'),
        _FootballQuizOption(
            koText: '등을 보이고 뛴다', enText: 'Turn your back while running'),
        _FootballQuizOption(
            koText: '양팔로 상대를 민다', enText: 'Push with both arms'),
      ],
      correctIndex: 0,
      koExplain: '클로즈아웃은 슛을 방해하면서도 돌파를 허용하지 않는 균형이 핵심입니다.',
      enExplain:
          'A closeout balances contesting the shot and containing the drive.',
      koNextPoint: '마지막 두 걸음은 작게 줄여 방향 전환을 준비하세요.',
      enNextPoint:
          'Shorten the last two steps to prepare for a change of direction.',
    ),
    _sportQuizQuestion(
      id: 'basketball_mcq_spacing_corner',
      conceptKey: 'basketball_corner_spacing',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.tactics,
      koPrompt: '코너 스페이싱이 공격에 주는 가장 큰 효과는?',
      enPrompt: 'What is the biggest offensive value of corner spacing?',
      options: const [
        _FootballQuizOption(
            koText: '수비를 넓혀 돌파와 킥아웃 공간을 만든다',
            enText: 'Stretch the defense and open drive or kick-out space'),
        _FootballQuizOption(koText: '샷클락을 멈춘다', enText: 'Stop the shot clock'),
        _FootballQuizOption(koText: '리바운드를 금지한다', enText: 'Ban rebounds'),
        _FootballQuizOption(
            koText: '센터만 슛하게 한다', enText: 'Make only the center shoot'),
      ],
      correctIndex: 0,
      koExplain: '좋은 스페이싱은 수비 도움 위치를 어렵게 만들어 공격 선택지를 늘립니다.',
      enExplain:
          'Good spacing makes help defense harder and increases options.',
      koNextPoint: '공을 보되 수비수가 도움을 갈 때 패스 라인을 준비하세요.',
      enNextPoint: 'Watch the ball and be ready when your defender helps.',
    ),
    _sportQuizQuestion(
      id: 'basketball_mcq_transition_defense',
      conceptKey: 'basketball_transition_defense',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.positions,
      koPrompt: '속공 수비에서 첫 번째 우선순위는?',
      enPrompt: 'What is the first priority in transition defense?',
      options: const [
        _FootballQuizOption(
            koText: '공을 멈추고 림으로 가는 길을 막는다',
            enText: 'Stop the ball and protect the path to the rim'),
        _FootballQuizOption(
            koText: '공격 리바운드를 계속 노린다',
            enText: 'Keep chasing the offensive rebound'),
        _FootballQuizOption(
            koText: '가장 먼 슈터만 따라가고 공을 늦추지 않는다',
            enText: 'Follow only the far shooter without slowing the ball'),
        _FootballQuizOption(koText: '천천히 걸어간다', enText: 'Walk back slowly'),
      ],
      correctIndex: 0,
      koExplain: '속공은 먼저 공을 늦추고 중앙 레인을 막아 쉬운 득점을 줄여야 합니다.',
      enExplain:
          'Transition defense starts by slowing the ball and protecting the middle lane.',
      koNextPoint: '누가 공을 막고 누가 림을 지킬지 짧게 콜하세요.',
      enNextPoint: 'Call who stops ball and who protects the rim.',
    ),
    _sportQuizQuestion(
      id: 'basketball_ox_line_three',
      conceptKey: 'basketball_three_point_line',
      difficulty: 1,
      style: _QuestionStyle.ox,
      category: _QuizCategory.rules,
      koPrompt: '3점 라인을 밟고 던진 슛은 일반적으로 2점이다. O/X',
      enPrompt:
          'A shot with a foot on the three-point line is generally worth two points. True/False',
      options: const [
        _FootballQuizOption(koText: 'O', enText: 'True'),
        _FootballQuizOption(koText: 'X', enText: 'False'),
      ],
      correctIndex: 0,
      koExplain: '라인을 밟으면 3점 라인 밖에서 던진 것으로 인정되지 않습니다.',
      enExplain:
          'A foot on the line means the shot is not fully behind the three-point line.',
      koNextPoint: '캐치 전 발 위치를 먼저 정하면 슛 판정이 안정됩니다.',
      enNextPoint: 'Set feet before the catch for cleaner shot location.',
    ),
    _sportQuizQuestion(
      id: 'basketball_sa_triple_double',
      conceptKey: 'basketball_triple_double_term',
      difficulty: 1,
      style: _QuestionStyle.shortAnswer,
      category: _QuizCategory.fun,
      koPrompt: '득점, 리바운드, 어시스트 등 세 기록에서 두 자릿수를 달성하는 것을 무엇이라고 할까?',
      enPrompt:
          'What is it called when a player reaches double digits in three stat categories?',
      acceptedAnswers: const ['트리플 더블', 'triple double', 'triple-double'],
      koExplain: '트리플 더블은 한 선수가 여러 영역에서 경기에 크게 기여했다는 지표입니다.',
      enExplain:
          'A triple-double shows broad impact across multiple stat categories.',
      koNextPoint: '기록 이름보다 어떤 플레이가 팀에 도움을 줬는지 함께 보세요.',
      enNextPoint: 'Pair the stat with the plays that helped the team.',
    ),
    ..._athleteNutritionSportQuizQuestions(SportCatalog.basketballId),
    ..._styleFloorSportQuizQuestions(SportCatalog.basketballId),
    ..._advancedBasketballQuizQuestions(),
  ];
}

List<_FootballQuizQuestion> _buildTennisQuizPool() {
  return <_FootballQuizQuestion>[
    _sportQuizQuestion(
      id: 'tennis_mcq_deuce',
      conceptKey: 'tennis_deuce_two_points',
      difficulty: 1,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.rules,
      koPrompt: '듀스 이후 게임을 따려면 기본적으로 어떻게 해야 할까?',
      enPrompt: 'After deuce, what is normally needed to win the game?',
      options: const [
        _FootballQuizOption(
            koText: '연속 두 포인트를 따야 한다', enText: 'Win two points in a row'),
        _FootballQuizOption(
            koText: '한 포인트만 따면 된다', enText: 'Win only one point'),
        _FootballQuizOption(koText: '서브를 바꿔야 한다', enText: 'Change server'),
        _FootballQuizOption(koText: '코트를 떠나야 한다', enText: 'Leave the court'),
      ],
      correctIndex: 0,
      koExplain: '듀스에서는 어드밴티지를 얻고 다음 포인트까지 따야 게임을 가져갑니다.',
      enExplain:
          'From deuce, a player must earn advantage and then win the next point.',
      koNextPoint: '듀스 포인트에서는 첫 서브 확률과 리턴 깊이가 중요합니다.',
      enNextPoint: 'At deuce, first-serve percentage and return depth matter.',
    ),
    _sportQuizQuestion(
      id: 'tennis_mcq_let_serve',
      conceptKey: 'tennis_let_serve',
      difficulty: 1,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.rules,
      koPrompt: '서브가 네트를 맞고 올바른 서비스 박스에 들어가면 일반적으로?',
      enPrompt:
          'If a serve touches the net and lands in the correct service box, what usually happens?',
      options: const [
        _FootballQuizOption(
            koText: '렛으로 다시 서브한다',
            enText: 'It is a let and the serve is replayed'),
        _FootballQuizOption(
            koText: '무조건 실점이다', enText: 'It is always a lost point'),
        _FootballQuizOption(
            koText: '상대가 두 점을 얻는다', enText: 'The opponent gets two points'),
        _FootballQuizOption(koText: '게임이 끝난다', enText: 'The game ends'),
      ],
      correctIndex: 0,
      koExplain: '정상 박스에 들어간 네트 터치 서브는 렛으로 다시 진행합니다.',
      enExplain:
          'A net-touch serve landing in the correct box is replayed as a let.',
      koNextPoint: '렛 뒤에도 루틴을 유지해 다음 서브 리듬을 지키세요.',
      enNextPoint: 'Keep the same routine after a let.',
    ),
    _sportQuizQuestion(
      id: 'tennis_mcq_double_fault',
      conceptKey: 'tennis_double_fault',
      difficulty: 1,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.rules,
      koPrompt: '더블 폴트는 어떤 상황일까?',
      enPrompt: 'What is a double fault?',
      options: const [
        _FootballQuizOption(
            koText: '첫 서브와 두 번째 서브를 모두 실패한다',
            enText: 'Missing both the first and second serve'),
        _FootballQuizOption(
            koText: '한 랠리에서 두 번 친다', enText: 'Hitting twice in one rally'),
        _FootballQuizOption(
            koText: '두 게임을 연속으로 이긴다', enText: 'Winning two games in a row'),
        _FootballQuizOption(
            koText: '복식에서만 생긴다', enText: 'It happens only in doubles'),
      ],
      correctIndex: 0,
      koExplain: '두 번의 서브 기회를 모두 놓치면 상대가 포인트를 얻습니다.',
      enExplain: 'If both serve attempts fail, the opponent wins the point.',
      koNextPoint: '두 번째 서브는 속도보다 회전과 높이를 우선하세요.',
      enNextPoint: 'Prioritize spin and net clearance on second serve.',
    ),
    _sportQuizQuestion(
      id: 'tennis_mcq_break_point',
      conceptKey: 'tennis_break_point',
      difficulty: 1,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.tactics,
      koPrompt: '브레이크 포인트는 어떤 의미일까?',
      enPrompt: 'What does break point mean?',
      options: const [
        _FootballQuizOption(
            koText: '리시버가 다음 포인트를 따면 상대 서브 게임을 가져가는 상황',
            enText: 'The receiver can win the server game with the next point'),
        _FootballQuizOption(
            koText: '라켓이 부러진 상황', enText: 'A broken racket situation'),
        _FootballQuizOption(
            koText: '무조건 타이브레이크 상황', enText: 'Always a tiebreak situation'),
        _FootballQuizOption(
            koText: '서브를 두 번 더 주는 상황',
            enText: 'The server gets two more serves'),
      ],
      correctIndex: 0,
      koExplain: '브레이크 포인트는 리턴 게임에서 흐름을 바꿀 수 있는 중요한 포인트입니다.',
      enExplain:
          'Break point is a key chance for the receiver to take the server game.',
      koNextPoint: '리턴은 강타보다 코트 안 깊게 넣는 선택이 먼저입니다.',
      enNextPoint: 'A deep return in court often beats forcing a winner.',
    ),
    _sportQuizQuestion(
      id: 'tennis_mcq_crosscourt',
      conceptKey: 'tennis_crosscourt_percentage',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.tactics,
      koPrompt: '크로스코트 랠리가 안정적인 선택인 이유는?',
      enPrompt: 'Why is a crosscourt rally often a high-percentage choice?',
      options: const [
        _FootballQuizOption(
            koText: '코트 길이가 길고 네트 중앙이 낮다',
            enText:
                'The court is longer diagonally and the net is lower in the middle'),
        _FootballQuizOption(
            koText: '항상 포인트가 바로 끝난다',
            enText: 'It always ends the point immediately'),
        _FootballQuizOption(
            koText: '상대가 칠 수 없다', enText: 'The opponent cannot hit it'),
        _FootballQuizOption(
            koText: '규칙상 두 점이다', enText: 'It is worth two points by rule'),
      ],
      correctIndex: 0,
      koExplain: '크로스코트는 대각선 길이와 낮은 네트 지점 덕분에 실수 위험이 상대적으로 낮습니다.',
      enExplain:
          'Crosscourt gives more court length and crosses the lower middle of the net.',
      koNextPoint: '무리한 다운더라인보다 깊은 크로스코트로 균형을 잡아보세요.',
      enNextPoint: 'Use deep crosscourt before forcing down-the-line.',
    ),
    _sportQuizQuestion(
      id: 'tennis_mcq_split_step',
      conceptKey: 'tennis_split_step',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.technique,
      koPrompt: '스플릿 스텝의 핵심 목적은?',
      enPrompt: 'What is the main purpose of a split step?',
      options: const [
        _FootballQuizOption(
            koText: '상대 타격 순간에 어느 방향이든 출발할 준비를 한다',
            enText: 'Prepare to move either direction as the opponent hits'),
        _FootballQuizOption(
            koText: '공을 더 세게 만든다', enText: 'Make the ball faster'),
        _FootballQuizOption(
            koText: '상대가 친 뒤 한 박자 늦게 멈춘다',
            enText: 'Stop one beat late after the opponent hits'),
        _FootballQuizOption(
            koText: '다음 공 방향을 예측해 먼저 한쪽으로 뛴다',
            enText: 'Guess early and run one way before contact'),
      ],
      correctIndex: 0,
      koExplain: '스플릿 스텝은 반응 시간을 줄이고 첫 발을 빠르게 만드는 준비 동작입니다.',
      enExplain:
          'The split step reduces reaction time and improves the first step.',
      koNextPoint: '상대가 공을 맞히는 순간 가볍게 착지하는 타이밍을 맞추세요.',
      enNextPoint: 'Land lightly as the opponent contacts the ball.',
    ),
    _sportQuizQuestion(
      id: 'tennis_mcq_topspin',
      conceptKey: 'tennis_topspin',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.technique,
      koPrompt: '탑스핀을 주면 공에 어떤 장점이 생길까?',
      enPrompt: 'What advantage does topspin give the ball?',
      options: const [
        _FootballQuizOption(
            koText: '네트를 넘은 뒤 코트 안으로 떨어질 가능성이 커진다',
            enText:
                'It helps the ball dip into the court after clearing the net'),
        _FootballQuizOption(
            koText: '공이 반드시 멈춘다', enText: 'The ball always stops'),
        _FootballQuizOption(
            koText: '서브권이 바뀐다', enText: 'The serve changes hands'),
        _FootballQuizOption(
            koText: '라인 판정이 사라진다', enText: 'Line calls disappear'),
      ],
      correctIndex: 0,
      koExplain: '탑스핀은 공을 아래로 끌어내려 안정적인 높이와 깊이를 만들기 좋습니다.',
      enExplain: 'Topspin helps the ball dip, giving safer height and depth.',
      koNextPoint: '라켓을 아래에서 위로 통과시키는 감각을 천천히 익히세요.',
      enNextPoint: 'Practice the low-to-high racket path slowly.',
    ),
    _sportQuizQuestion(
      id: 'tennis_mcq_approach_shot',
      conceptKey: 'tennis_approach_shot',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.positions,
      koPrompt: '어프로치 샷 후 좋은 다음 움직임은?',
      enPrompt: 'After an approach shot, what is a good next move?',
      options: const [
        _FootballQuizOption(
            koText: '네트 쪽으로 전진해 발리 준비를 한다',
            enText: 'Move forward and prepare for a volley'),
        _FootballQuizOption(
            koText: '베이스라인 뒤로 더 물러난다',
            enText: 'Retreat farther behind the baseline'),
        _FootballQuizOption(
            koText: '공을 보지 않는다', enText: 'Stop watching the ball'),
        _FootballQuizOption(
            koText: '서브 위치로 돌아간다', enText: 'Return to the service position'),
      ],
      correctIndex: 0,
      koExplain: '어프로치 샷은 상대 시간을 줄이고 네트에서 마무리하기 위한 전진 샷입니다.',
      enExplain:
          'An approach shot is used to take time away and finish near the net.',
      koNextPoint: '상대 백핸드 쪽 깊은 코스로 접근하면 다음 발리가 쉬워집니다.',
      enNextPoint:
          'A deep approach to the weaker side can simplify the volley.',
    ),
    _sportQuizQuestion(
      id: 'tennis_mcq_unforced_error',
      conceptKey: 'tennis_unforced_error',
      difficulty: 1,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.mindset,
      koPrompt: '언포스드 에러에 가장 가까운 설명은?',
      enPrompt: 'Which best describes an unforced error?',
      options: const [
        _FootballQuizOption(
            koText: '상대 압박이 크지 않은데 스스로 한 실수',
            enText: 'A mistake made without heavy opponent pressure'),
        _FootballQuizOption(
            koText: '상대가 친 완벽한 위너', enText: 'A perfect winner by the opponent'),
        _FootballQuizOption(
            koText: '서브 순서 변경', enText: 'A service order change'),
        _FootballQuizOption(
            koText: '비 때문에 중단된 경기', enText: 'A match stopped by rain'),
      ],
      correctIndex: 0,
      koExplain: '언포스드 에러를 줄이는 것은 경기 운영 안정성의 핵심입니다.',
      enExplain: 'Reducing unforced errors is central to stable match play.',
      koNextPoint: '실수 후에는 다음 포인트의 첫 두 타구를 안전하게 가져가세요.',
      enNextPoint: 'After an error, make the next two shots safe.',
    ),
    _sportQuizQuestion(
      id: 'tennis_ox_line_in',
      conceptKey: 'tennis_line_is_in',
      difficulty: 1,
      style: _QuestionStyle.ox,
      category: _QuizCategory.rules,
      koPrompt: '공이 라인에 조금이라도 닿으면 인이다. O/X',
      enPrompt:
          'If the ball touches any part of the line, it is in. True/False',
      options: const [
        _FootballQuizOption(koText: 'O', enText: 'True'),
        _FootballQuizOption(koText: 'X', enText: 'False'),
      ],
      correctIndex: 0,
      koExplain: '테니스에서 라인은 코트 안으로 간주합니다.',
      enExplain: 'In tennis, the line is part of the court.',
      koNextPoint: '라인 근처 공은 끝까지 보고 판정을 서두르지 마세요.',
      enNextPoint: 'Track balls near the line fully before reacting.',
    ),
    _sportQuizQuestion(
      id: 'tennis_sa_break_point',
      conceptKey: 'tennis_break_point_term',
      difficulty: 1,
      style: _QuestionStyle.shortAnswer,
      category: _QuizCategory.fun,
      koPrompt: '리시버가 다음 포인트를 따면 상대 서브 게임을 가져가는 상황을 무엇이라고 할까?',
      enPrompt:
          'What is the situation called when the receiver can win the server game with the next point?',
      acceptedAnswers: const ['브레이크 포인트', 'break point', 'breakpoint'],
      koExplain: '브레이크 포인트는 리턴 게임에서 가장 중요한 승부처 중 하나입니다.',
      enExplain:
          'Break point is one of the most important moments in a return game.',
      koNextPoint: '브레이크 포인트에서는 리턴 성공률을 먼저 높이는 선택을 하세요.',
      enNextPoint: 'On break point, prioritize putting the return in play.',
    ),
    ..._athleteNutritionSportQuizQuestions(SportCatalog.tennisId),
    ..._styleFloorSportQuizQuestions(SportCatalog.tennisId),
    ..._advancedTennisQuizQuestions(),
  ];
}

List<_FootballQuizQuestion> _advancedBaseballQuizQuestions() {
  return <_FootballQuizQuestion>[
    _sportQuizQuestion(
      id: 'baseball_adv_mcq_pitch_tunneling',
      conceptKey: 'baseball_pitch_tunneling',
      difficulty: 3,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.technique,
      koPrompt: '투수가 직구와 변화구를 같은 궤적으로 보이게 하려는 “터널링”의 핵심 목적은?',
      enPrompt:
          'What is the main purpose of pitch tunneling, making a fastball and breaking ball look similar early?',
      options: const [
        _FootballQuizOption(
          koText: '타자의 결정 시간을 늦추고 스윙 판단을 흔든다',
          enText: 'Delay the hitter’s decision and disturb swing judgment',
        ),
        _FootballQuizOption(
          koText: '포수가 공을 잡지 않아도 되게 한다',
          enText: 'Make catching the ball unnecessary',
        ),
        _FootballQuizOption(
          koText: '모든 공을 스트라이크존 밖으로 던진다',
          enText: 'Throw every pitch outside the strike zone',
        ),
        _FootballQuizOption(
          koText: '타자가 투구 종류를 더 빨리 보게 한다',
          enText: 'Help the hitter identify pitch type earlier',
        ),
      ],
      correctIndex: 0,
      koExplain: '터널링은 초반 궤적을 비슷하게 보여 타자가 공종과 위치를 늦게 구분하게 만드는 투구 설계입니다.',
      enExplain:
          'Pitch tunneling uses similar early flight to make pitch type and location harder to identify in time.',
      koNextPoint: '투구 전략은 구속보다 타자가 언제 구분하는지를 함께 보세요.',
      enNextPoint:
          'Read pitching strategy through when the hitter can identify the pitch, not only velocity.',
    ),
    _sportQuizQuestion(
      id: 'baseball_adv_mcq_count_1_2_plan',
      conceptKey: 'baseball_count_leverage_1_2',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.tactics,
      koPrompt: '투수에게 유리한 1-2 카운트에서 더 좋은 투구 계획은?',
      enPrompt:
          'On a pitcher-friendly 1-2 count, which pitching plan is better?',
      options: const [
        _FootballQuizOption(
          koText: '타자의 약점과 직전 반응을 보고 존 경계나 유인구를 설계한다',
          enText:
              'Use the hitter weakness and previous reaction to attack edges or set up a chase pitch',
        ),
        _FootballQuizOption(
          koText: '항상 가운데 직구만 던진다',
          enText: 'Always throw a fastball down the middle',
        ),
        _FootballQuizOption(
          koText: '볼넷이 무서워 무조건 느린 공만 던진다',
          enText: 'Throw only slow pitches because walks are scary',
        ),
        _FootballQuizOption(
          koText: '포수 사인과 관계없이 즉흥으로 던진다',
          enText: 'Ignore the catcher and improvise every time',
        ),
      ],
      correctIndex: 0,
      koExplain: '유리한 카운트에서는 존을 넓게 쓰되 타자의 스윙 경향과 앞선 반응을 연결해야 합니다.',
      enExplain:
          'In leverage counts, use the zone wider while connecting the hitter tendency with the previous reaction.',
      koNextPoint: '카운트 문제는 숫자만 보지 말고 타자 반응과 다음 공의 목적을 같이 보세요.',
      enNextPoint:
          'For count questions, pair the number with hitter reaction and pitch purpose.',
    ),
    _sportQuizQuestion(
      id: 'baseball_adv_mcq_first_third_defense',
      conceptKey: 'baseball_first_third_defense',
      difficulty: 3,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.tactics,
      koPrompt: '1,3루에서 1루 주자가 도루 스타트를 끊었습니다. 수비가 먼저 정해야 할 것은?',
      enPrompt:
          'With runners on first and third, the runner on first breaks for second. What must the defense decide first?',
      options: const [
        _FootballQuizOption(
          koText: '홈 실점을 막을지, 2루 아웃을 노릴지 팀 약속을 따른다',
          enText:
              'Follow the team call on whether to protect home or try for the out at second',
        ),
        _FootballQuizOption(
          koText: '모든 내야수가 동시에 2루로 달린다',
          enText: 'All infielders run to second at once',
        ),
        _FootballQuizOption(
          koText: '포수는 항상 공을 들고 기다린다',
          enText: 'The catcher always holds the ball and waits',
        ),
        _FootballQuizOption(
          koText: '3루 주자는 절대 움직일 수 없다고 가정한다',
          enText: 'Assume the runner on third can never move',
        ),
      ],
      correctIndex: 0,
      koExplain: '1,3루 도루 상황은 2루 아웃보다 홈 실점 위험이 먼저라 팀별 콜과 컷 플레이가 중요합니다.',
      enExplain:
          'First-and-third defense is about balancing the out at second against the risk of conceding home.',
      koNextPoint: '주자 상황은 공 하나보다 각 주자의 위협을 동시에 계산하세요.',
      enNextPoint:
          'In runner situations, calculate every runner’s threat at the same time.',
    ),
    _sportQuizQuestion(
      id: 'baseball_adv_mcq_relay_throw_priority',
      conceptKey: 'baseball_relay_throw_priority',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.positions,
      koPrompt: '장타가 외야 깊숙이 갔을 때 릴레이 플레이의 가장 좋은 기준은?',
      enPrompt:
          'On a deep extra-base hit, what is the best principle for a relay play?',
      options: const [
        _FootballQuizOption(
          koText: '중계수는 몸을 목표 베이스로 열고 가장 위험한 주자를 기준으로 송구한다',
          enText:
              'The relay opens toward the target base and throws based on the most dangerous runner',
        ),
        _FootballQuizOption(
          koText: '공을 오래 들고 모든 주자를 기다린다',
          enText: 'Hold the ball and wait for every runner',
        ),
        _FootballQuizOption(
          koText: '항상 가장 가까운 베이스로만 던진다',
          enText: 'Always throw only to the nearest base',
        ),
        _FootballQuizOption(
          koText: '외야수가 끝까지 혼자 홈으로 던진다',
          enText: 'The outfielder always throws home alone',
        ),
      ],
      correctIndex: 0,
      koExplain: '릴레이는 송구 거리를 줄이는 것뿐 아니라 다음 플레이 방향과 주자 위험도를 정리하는 역할입니다.',
      enExplain:
          'A relay reduces throw distance and organizes the next play around runner threat.',
      koNextPoint: '중계 플레이는 위치, 몸 방향, 목표 베이스를 세트로 보세요.',
      enNextPoint:
          'Read relay plays as a set of position, body shape, and target base.',
    ),
    _sportQuizQuestion(
      id: 'baseball_adv_mcq_shift_counter',
      conceptKey: 'baseball_shift_counter',
      difficulty: 3,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.tactics,
      koPrompt: '상대가 강한 당겨치기 성향을 보고 수비 시프트를 걸었습니다. 타자에게 더 성숙한 대응은?',
      enPrompt:
          'The defense shifts against a strong pull tendency. What is a more mature hitter response?',
      options: const [
        _FootballQuizOption(
          koText: '카운트와 투구 위치를 보며 반대 방향, 라인드라이브, 번트 가능성을 준비한다',
          enText:
              'Use count and pitch location to prepare opposite-field, line-drive, or bunt options',
        ),
        _FootballQuizOption(
          koText: '시프트와 관계없이 모든 공을 더 크게 당겨친다',
          enText: 'Pull every pitch harder regardless of the shift',
        ),
        _FootballQuizOption(
          koText: '타석에서 수비 위치를 보지 않는다',
          enText: 'Never look at defensive positioning',
        ),
        _FootballQuizOption(
          koText: '주자가 있어도 결과만 운에 맡긴다',
          enText: 'Leave the outcome to luck even with runners on',
        ),
      ],
      correctIndex: 0,
      koExplain: '시프트 대응은 무조건 밀어치기가 아니라 카운트, 공 위치, 팀 상황에 맞춘 타격 선택입니다.',
      enExplain:
          'Countering a shift is not automatic opposite-field hitting; it depends on count, pitch, and team context.',
      koNextPoint: '타격 전술은 수비 배치와 내 스윙 강점을 함께 읽어야 합니다.',
      enNextPoint:
          'Hitting tactics require reading defensive shape with your swing strengths.',
    ),
    _sportQuizQuestion(
      id: 'baseball_adv_mcq_quality_at_bat',
      conceptKey: 'baseball_quality_at_bat',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.mindset,
      koPrompt: '안타가 아니어도 “좋은 타석”으로 평가할 수 있는 장면은?',
      enPrompt:
          'Which plate appearance can still be judged as a quality at-bat without a hit?',
      options: const [
        _FootballQuizOption(
          koText: '투수를 오래 던지게 하고 팀 상황에 맞는 강한 타구나 진루타를 만든다',
          enText:
              'Make the pitcher work and create hard contact or a productive out for the team situation',
        ),
        _FootballQuizOption(
          koText: '첫 공을 보지 않고 무조건 큰 스윙을 한다',
          enText: 'Take a huge swing at the first pitch without seeing it',
        ),
        _FootballQuizOption(
          koText: '결과가 아웃이면 과정은 전혀 보지 않는다',
          enText: 'Ignore the process whenever the result is an out',
        ),
        _FootballQuizOption(
          koText: '삼진 뒤 바로 감정을 오래 끌고 간다',
          enText: 'Carry frustration for a long time after a strikeout',
        ),
      ],
      correctIndex: 0,
      koExplain: '좋은 타석은 안타 여부만이 아니라 투구 수, 강한 컨택, 진루 기여, 작전 수행으로도 판단합니다.',
      enExplain:
          'A quality at-bat can include pitch count, hard contact, runner advancement, or executing the plan.',
      koNextPoint: '야구 멘탈은 결과와 별개로 통제 가능한 과정 지표를 남기는 데서 시작합니다.',
      enNextPoint:
          'Baseball mindset improves when controllable process markers are tracked apart from result.',
    ),
    _sportQuizQuestion(
      id: 'baseball_adv_ox_run_expectancy_outs',
      conceptKey: 'baseball_run_expectancy_outs',
      difficulty: 3,
      style: _QuestionStyle.ox,
      category: _QuizCategory.tactics,
      koPrompt: '희생번트의 가치는 아웃카운트, 주자 위치, 점수 차에 따라 달라진다. O/X',
      enPrompt:
          'The value of a sacrifice bunt changes with outs, runner position, and score. True/False',
      options: const [
        _FootballQuizOption(koText: 'O', enText: 'True'),
        _FootballQuizOption(koText: 'X', enText: 'False'),
      ],
      correctIndex: 0,
      koExplain: '번트는 항상 좋은 선택이 아니라 득점 확률, 한 점의 가치, 다음 타순에 따라 달라집니다.',
      enExplain:
          'A bunt is not always good; its value depends on run expectancy, one-run value, and the next hitters.',
      koNextPoint: '작전 선택은 “무조건”보다 상황 기대값으로 판단하세요.',
      enNextPoint:
          'Judge tactics by situation value rather than absolute rules.',
    ),
    _sportQuizQuestion(
      id: 'baseball_adv_ox_double_cut',
      conceptKey: 'baseball_double_cut',
      difficulty: 2,
      style: _QuestionStyle.ox,
      category: _QuizCategory.positions,
      koPrompt: '깊은 외야 타구에서는 두 명의 중계수가 일렬로 서는 더블 컷 구조가 송구 선택을 안정시킬 수 있다. O/X',
      enPrompt:
          'On deep outfield balls, a double-cut alignment can stabilize relay options. True/False',
      options: const [
        _FootballQuizOption(koText: 'O', enText: 'True'),
        _FootballQuizOption(koText: 'X', enText: 'False'),
      ],
      correctIndex: 0,
      koExplain: '더블 컷은 먼 송구에서 홈, 3루, 2루 선택지를 더 안전하게 정리하는 팀 수비 구조입니다.',
      enExplain:
          'A double cut helps the defense organize choices to home, third, or second on long throws.',
      koNextPoint: '외야 수비는 잡는 순간보다 송구 경로와 다음 베이스 커버까지 연결하세요.',
      enNextPoint:
          'Outfield defense continues through relay lane and next-base coverage.',
    ),
    _sportQuizQuestion(
      id: 'baseball_adv_sa_whip',
      conceptKey: 'baseball_whip_stat',
      difficulty: 2,
      style: _QuestionStyle.shortAnswer,
      category: _QuizCategory.fun,
      koPrompt: '투수가 이닝당 허용한 볼넷과 안타를 합쳐 보는 지표의 약어는?',
      enPrompt:
          'What abbreviation measures walks plus hits allowed per inning pitched?',
      acceptedAnswers: const ['WHIP', 'whip'],
      koExplain: '정답은 "WHIP"입니다. 투수가 얼마나 많은 주자를 내보내는지 보는 대표 지표입니다.',
      enExplain:
          'The answer is "WHIP." It shows how many baserunners a pitcher allows per inning.',
      koNextPoint: '투수 기록은 평균자책점뿐 아니라 출루 허용 능력도 함께 보세요.',
      enNextPoint:
          'Evaluate pitchers with baserunner prevention as well as earned runs.',
    ),
    _sportQuizQuestion(
      id: 'baseball_adv_sa_ops',
      conceptKey: 'baseball_ops_stat',
      difficulty: 2,
      style: _QuestionStyle.shortAnswer,
      category: _QuizCategory.fun,
      koPrompt: '출루율과 장타율을 더해 타자의 생산성을 보는 대표 지표 약어는?',
      enPrompt:
          'What abbreviation combines on-base percentage and slugging percentage?',
      acceptedAnswers: const ['OPS', 'ops'],
      koExplain: '정답은 "OPS"입니다. 출루와 장타 생산을 함께 보는 간단한 공격 지표입니다.',
      enExplain:
          'The answer is "OPS." It combines getting on base with power production.',
      koNextPoint: '타격 지표는 안타 수보다 출루와 장타 가치를 함께 보면 더 입체적입니다.',
      enNextPoint:
          'Hitting value is richer when on-base skill and power are read together.',
    ),
    _sportQuizQuestion(
      id: 'baseball_adv_mcq_two_strike_contact_plan',
      conceptKey: 'baseball_two_strike_contact_plan',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.technique,
      koPrompt: '투 스트라이크 이후 타자가 콘택트 확률을 높이기 위한 기술 조정으로 가장 알맞은 것은?',
      enPrompt:
          'With two strikes, what technical adjustment best helps a hitter raise contact probability?',
      options: const [
        _FootballQuizOption(
          koText: '스윙을 조금 짧게 가져가고 존을 넓혀 파울로 버틸 준비를 한다',
          enText:
              'Shorten the swing slightly, widen the zone, and be ready to fight pitches off',
        ),
        _FootballQuizOption(
          koText: '항상 홈런 스윙만 더 크게 한다',
          enText: 'Always make the home-run swing bigger',
        ),
        _FootballQuizOption(
          koText: '스트라이크존을 더 좁게 보고 가운데 공도 버린다',
          enText: 'Shrink the zone and take even middle strikes',
        ),
        _FootballQuizOption(
          koText: '투수 릴리스는 보지 않고 결과만 기다린다',
          enText: 'Ignore pitcher release and wait only for the result',
        ),
      ],
      correctIndex: 0,
      koExplain: '투 스트라이크에서는 장타 욕심보다 배트 컨트롤, 존 조정, 파울로 버티는 기술이 타석을 살립니다.',
      enExplain:
          'With two strikes, bat control, zone adjustment, and fighting pitches off can keep the at-bat alive.',
      koNextPoint: '타격 기술은 카운트에 따라 스윙 크기와 노리는 존이 달라집니다.',
      enNextPoint:
          'Hitting technique changes with the count through swing size and zone selection.',
    ),
  ];
}

List<_FootballQuizQuestion> _advancedBasketballQuizQuestions() {
  return <_FootballQuizQuestion>[
    _sportQuizQuestion(
      id: 'basketball_adv_mcq_drop_coverage',
      conceptKey: 'basketball_drop_coverage',
      difficulty: 3,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.tactics,
      koPrompt: '픽앤롤 수비에서 빅맨이 림 근처로 내려서는 드롭 커버리지의 기본 의도는?',
      enPrompt:
          'In pick-and-roll defense, what is the basic intent of drop coverage by the big?',
      options: const [
        _FootballQuizOption(
          koText: '림 보호를 우선하며 미드레인지나 플로터 판단을 강요한다',
          enText:
              'Prioritize rim protection while forcing midrange or floater decisions',
        ),
        _FootballQuizOption(
          koText: '코너 슈터를 일부러 완전히 비운다',
          enText: 'Intentionally leave the corner shooter completely open',
        ),
        _FootballQuizOption(
          koText: '스크리너를 따라 3점 라인 밖까지 항상 나간다',
          enText: 'Always chase the screener beyond the three-point line',
        ),
        _FootballQuizOption(
          koText: '수비 다섯 명이 모두 볼 핸들러만 본다',
          enText: 'All five defenders watch only the ball handler',
        ),
      ],
      correctIndex: 0,
      koExplain: '드롭은 림과 롤맨을 보호하는 대신 볼 핸들러의 풀업과 플로터를 어떻게 제어할지 정교함이 필요합니다.',
      enExplain:
          'Drop protects the rim and roller, but it must manage pull-ups and floaters carefully.',
      koNextPoint: '픽앤롤 수비는 커버리지 이름보다 어떤 슛을 허용하려는지 보세요.',
      enNextPoint:
          'Read pick-and-roll coverage by the shot it is willing to concede.',
    ),
    _sportQuizQuestion(
      id: 'basketball_adv_mcq_switch_mismatch',
      conceptKey: 'basketball_switch_mismatch_attack',
      difficulty: 3,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.tactics,
      koPrompt: '스위치 수비 뒤 작은 선수가 빅맨을 막게 됐습니다. 공격의 좋은 대응은?',
      enPrompt:
          'After a defensive switch, a small defender is guarding your big. What is a good offensive response?',
      options: const [
        _FootballQuizOption(
          koText: '바로 포스트업만 고집하지 말고 깊은 실링, 하이로우, 재스크린 각도를 만든다',
          enText:
              'Do not force only a post-up; create deep seal, high-low, or rescreen angles',
        ),
        _FootballQuizOption(
          koText: '미스매치를 무시하고 반대편에서만 드리블한다',
          enText: 'Ignore the mismatch and dribble only on the far side',
        ),
        _FootballQuizOption(
          koText: '빅맨을 3점 라인 밖에 계속 세운다',
          enText: 'Keep the big standing outside the arc',
        ),
        _FootballQuizOption(
          koText: '샷클락이 끝날 때까지 패스를 금지한다',
          enText: 'Ban passing until the shot clock expires',
        ),
      ],
      correctIndex: 0,
      koExplain: '스위치 공략은 공을 넣는 각도, 위치 선점, 두 번째 스크린까지 연결해야 안정적입니다.',
      enExplain:
          'Attacking a switch depends on entry angle, early position, and second actions such as rescreens.',
      koNextPoint: '미스매치는 발견보다 전달 각도와 타이밍이 더 중요할 때가 많습니다.',
      enNextPoint:
          'Finding a mismatch matters less than delivering it at the right angle and timing.',
    ),
    _sportQuizQuestion(
      id: 'basketball_adv_mcq_spain_pick_roll',
      conceptKey: 'basketball_spain_pick_and_roll',
      difficulty: 3,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.tactics,
      koPrompt: '스페인 픽앤롤의 핵심 구조는 무엇일까요?',
      enPrompt: 'What is the core structure of Spain pick-and-roll?',
      options: const [
        _FootballQuizOption(
          koText: '볼 스크린 뒤 롤맨에게 백스크린을 걸어 림과 외곽 선택지를 동시에 만든다',
          enText:
              'A back screen on the roller after the ball screen creates rim and perimeter options',
        ),
        _FootballQuizOption(
          koText: '다섯 명이 모두 같은 코너에 선다',
          enText: 'All five players stand in the same corner',
        ),
        _FootballQuizOption(
          koText: '공 없이 24초를 모두 보낸다',
          enText: 'Spend the whole shot clock without the ball',
        ),
        _FootballQuizOption(
          koText: '센터가 하프라인에서 자유투를 던진다',
          enText: 'The center shoots free throws from half court',
        ),
      ],
      correctIndex: 0,
      koExplain: '스페인 픽앤롤은 롤 수비와 백스크린 수비, 외곽 슈터 수비를 동시에 흔드는 세 명 조합입니다.',
      enExplain:
          'Spain pick-and-roll stresses roller defense, back-screen defense, and shooter coverage at once.',
      koNextPoint: '세트 오펜스는 첫 스크린보다 두 번째 충돌 지점을 보세요.',
      enNextPoint:
          'In set offense, read the second collision point as much as the first screen.',
    ),
    _sportQuizQuestion(
      id: 'basketball_adv_mcq_short_roll',
      conceptKey: 'basketball_short_roll_playmaking',
      difficulty: 3,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.technique,
      koPrompt: '상대가 볼 핸들러를 강하게 트랩할 때 쇼트롤러의 가장 좋은 판단은?',
      enPrompt:
          'When the defense traps the ball handler, what is the best short-roll decision?',
      options: const [
        _FootballQuizOption(
          koText: '중간 지점에서 받아 4대3을 읽고 림, 코너, 덩커스팟을 판단한다',
          enText:
              'Catch in the middle, read the 4-on-3, and choose rim, corner, or dunker spot',
        ),
        _FootballQuizOption(
          koText: '공을 받자마자 뒤로 물러나 하프라인으로 간다',
          enText: 'Retreat to half court immediately after catching',
        ),
        _FootballQuizOption(
          koText: '수비가 세 명이어도 무조건 어려운 플로터만 던진다',
          enText: 'Force a hard floater even against three defenders',
        ),
        _FootballQuizOption(
          koText: '코너 슈터 위치를 보지 않는다',
          enText: 'Do not look at the corner shooters',
        ),
      ],
      correctIndex: 0,
      koExplain: '쇼트롤은 트랩을 벌점으로 만드는 중간 연결입니다. 짧은 패스 뒤 4대3 판단이 핵심입니다.',
      enExplain:
          'The short roll punishes traps by turning a short pass into a 4-on-3 read.',
      koNextPoint: '트랩 대응은 빠른 탈출 패스와 중간 플레이메이커의 시야가 중요합니다.',
      enNextPoint:
          'Trap solutions need a quick release pass and a middle playmaker’s vision.',
    ),
    _sportQuizQuestion(
      id: 'basketball_adv_mcq_zone_overload',
      conceptKey: 'basketball_zone_overload',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.tactics,
      koPrompt: '2-3 지역방어를 흔들기 위한 좋은 공격 원칙은?',
      enPrompt: 'What is a good offensive principle against a 2-3 zone?',
      options: const [
        _FootballQuizOption(
          koText: '하이포스트와 코너를 연결해 수비 한 명에게 두 선택지를 맡긴다',
          enText:
              'Connect high post and corner to force one defender to guard two choices',
        ),
        _FootballQuizOption(
          koText: '공을 한쪽 윙에서만 멈춰 둔다',
          enText: 'Freeze the ball on one wing only',
        ),
        _FootballQuizOption(
          koText: '코너와 하이포스트를 모두 비운다',
          enText: 'Empty both the corner and high post',
        ),
        _FootballQuizOption(
          koText: '리바운드를 포기하고 모두 뒤로 선다',
          enText: 'Give up rebounding and have everyone stand back',
        ),
      ],
      correctIndex: 0,
      koExplain: '지역방어 공략은 빈 공간 점유와 오버로드로 수비의 책임 구역을 겹치게 만드는 것이 중요합니다.',
      enExplain:
          'Attacking zone requires occupying gaps and overloading responsibility areas.',
      koNextPoint: '지역방어는 사람보다 구역 사이 빈 공간을 먼저 찾으세요.',
      enNextPoint:
          'Against zone, look for gaps between areas rather than only matchups.',
    ),
    _sportQuizQuestion(
      id: 'basketball_adv_mcq_nail_help',
      conceptKey: 'basketball_nail_help',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.positions,
      koPrompt: '윙에서 돌파가 시작될 때 “네일” 위치 도움수비의 목적은?',
      enPrompt:
          'When a drive starts from the wing, what is the purpose of help at the nail?',
      options: const [
        _FootballQuizOption(
          koText: '중앙 침투 속도를 늦추고 킥아웃 패스를 예측할 시간을 만든다',
          enText:
              'Slow the middle drive and buy time to read the kick-out pass',
        ),
        _FootballQuizOption(
          koText: '림 보호자를 코너로 보내는 것',
          enText: 'Send the rim protector to the corner',
        ),
        _FootballQuizOption(
          koText: '공을 가진 선수를 등지고 서는 것',
          enText: 'Stand with the back turned to the ball handler',
        ),
        _FootballQuizOption(
          koText: '리바운드 위치를 일부러 비우는 것',
          enText: 'Intentionally empty rebounding position',
        ),
      ],
      correctIndex: 0,
      koExplain: '네일 도움은 페인트 중앙으로 바로 찢기는 것을 늦추고 로테이션 시간을 벌어줍니다.',
      enExplain:
          'Nail help delays straight-line drives into the paint and buys rotation time.',
      koNextPoint: '도움수비는 많이 가는 것보다 언제 보여주고 언제 복귀하는지가 핵심입니다.',
      enNextPoint:
          'Help defense is about showing and recovering at the right time, not simply helping more.',
    ),
    _sportQuizQuestion(
      id: 'basketball_adv_mcq_late_clock',
      conceptKey: 'basketball_late_clock_shot_quality',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.mindset,
      koPrompt: '샷클락 6초 이하에서 공격이 정체됐을 때 더 좋은 팀 판단은?',
      enPrompt:
          'When the offense stalls with under six seconds on the shot clock, what is the better team decision?',
      options: const [
        _FootballQuizOption(
          koText: '가장 좋은 매치업이나 드라이브 각도를 빠르게 정하고 리바운드 배치를 준비한다',
          enText:
              'Quickly choose the best matchup or drive angle and prepare rebounding balance',
        ),
        _FootballQuizOption(
          koText: '모든 선수가 공 주변으로 몰린다',
          enText: 'All players crowd around the ball',
        ),
        _FootballQuizOption(
          koText: '샷클락을 보지 않고 평소 세트를 처음부터 다시 시작한다',
          enText:
              'Ignore the clock and restart the normal set from the beginning',
        ),
        _FootballQuizOption(
          koText: '실패를 걱정해 아무도 슛하지 않는다',
          enText: 'Nobody shoots because everyone fears missing',
        ),
      ],
      correctIndex: 0,
      koExplain: '늦은 샷클락에서는 완벽한 세트보다 빠른 우선순위, 공간 유지, 리바운드/전환 균형이 중요합니다.',
      enExplain:
          'Late clock values quick priority, spacing, and rebound or transition balance over perfect execution.',
      koNextPoint: '압박 상황에서는 선택지를 줄여 실행 가능한 첫 행동을 정하세요.',
      enNextPoint:
          'Under time pressure, narrow options into one executable first action.',
    ),
    _sportQuizQuestion(
      id: 'basketball_adv_ox_low_man',
      conceptKey: 'basketball_low_man_rotation',
      difficulty: 3,
      style: _QuestionStyle.ox,
      category: _QuizCategory.tactics,
      koPrompt: '약측 로우맨은 림 컷과 롤맨을 먼저 막고, 이후 코너 패스에 맞춰 로테이션을 이어가야 한다. O/X',
      enPrompt:
          'The weak-side low man often tags the roller or rim cut first, then continues rotation to the corner pass. True/False',
      options: const [
        _FootballQuizOption(koText: 'O', enText: 'True'),
        _FootballQuizOption(koText: 'X', enText: 'False'),
      ],
      correctIndex: 0,
      koExplain: '로우맨은 림을 지키는 첫 도움과 코너 복귀/엑스아웃까지 연결되는 핵심 수비 역할입니다.',
      enExplain:
          'The low man is central to protecting the rim first and then rotating or x-ing out to the corner.',
      koNextPoint: '로테이션 수비는 첫 도움과 다음 패스 대응을 한 줄로 연결하세요.',
      enNextPoint:
          'Connect the first help and the next pass response in rotation defense.',
    ),
    _sportQuizQuestion(
      id: 'basketball_adv_sa_spain_pick_roll',
      conceptKey: 'basketball_spain_pick_and_roll_term',
      difficulty: 3,
      style: _QuestionStyle.shortAnswer,
      category: _QuizCategory.tactics,
      koPrompt: '볼 스크린 뒤 롤맨에게 백스크린을 붙이는 픽앤롤 변형을 무엇이라고 할까?',
      enPrompt:
          'What pick-and-roll variation adds a back screen for the roller after the ball screen?',
      acceptedAnswers: const [
        '스페인 픽앤롤',
        '스페인 픽 앤 롤',
        'spain pick and roll',
        'spain pick-and-roll',
        'spanish pick and roll',
      ],
      koExplain: '정답은 "스페인 픽앤롤"입니다. 롤맨과 슈터 수비를 동시에 흔드는 세 명 조합입니다.',
      enExplain:
          'The answer is "Spain pick-and-roll." It stresses the roller defender and shooter coverage together.',
      koNextPoint: '세트 이름은 참여자와 두 번째 스크린 위치까지 함께 외우세요.',
      enNextPoint:
          'Learn set names with the participants and the location of the second screen.',
    ),
    _sportQuizQuestion(
      id: 'basketball_adv_sa_nail_help',
      conceptKey: 'basketball_nail_help_term',
      difficulty: 2,
      style: _QuestionStyle.shortAnswer,
      category: _QuizCategory.positions,
      koPrompt: '자유투 라인 중앙 근처에서 드라이브를 늦추는 도움수비 위치를 무엇이라고 부를까?',
      enPrompt:
          'What is the help-defense spot near the middle of the free-throw line called?',
      acceptedAnswers: const ['네일', 'nail', 'nail help', '네일 도움'],
      koExplain: '정답은 "네일"입니다. 윙 돌파를 늦추고 수비 로테이션 시간을 만드는 위치입니다.',
      enExplain:
          'The answer is "nail." It slows wing drives and buys time for rotations.',
      koNextPoint: '수비 위치 용어는 코트의 실제 지점과 역할을 함께 기억하세요.',
      enNextPoint:
          'Pair defensive location terms with the actual court spot and role.',
    ),
  ];
}

List<_FootballQuizQuestion> _advancedTennisQuizQuestions() {
  return <_FootballQuizQuestion>[
    _sportQuizQuestion(
      id: 'tennis_adv_mcq_serve_plus_one',
      conceptKey: 'tennis_serve_plus_one',
      difficulty: 3,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.tactics,
      koPrompt: '서브 플러스 원 패턴의 핵심은 무엇일까요?',
      enPrompt: 'What is the core idea of a serve-plus-one pattern?',
      options: const [
        _FootballQuizOption(
          koText: '서브 코스와 다음 첫 공격 샷을 미리 연결한다',
          enText:
              'Link the serve location with the first attacking shot after it',
        ),
        _FootballQuizOption(
          koText: '서브 후 라켓을 내려놓는다',
          enText: 'Put the racket down after serving',
        ),
        _FootballQuizOption(
          koText: '리턴이 오기 전까지 코트를 보지 않는다',
          enText: 'Avoid reading the court until the return arrives',
        ),
        _FootballQuizOption(
          koText: '두 번째 샷을 항상 로브로만 친다',
          enText: 'Always hit the second shot as a lob',
        ),
      ],
      correctIndex: 0,
      koExplain: '서브 플러스 원은 서브 자체보다 리턴이 올 위치와 다음 공격 방향을 미리 설계하는 패턴입니다.',
      enExplain:
          'Serve-plus-one designs the likely return and next attacking shot, not only the serve.',
      koNextPoint: '서브 전에는 코스, 예상 리턴, 다음 발 위치를 한 세트로 준비하세요.',
      enNextPoint:
          'Before serving, pair location, expected return, and next foot position.',
    ),
    _sportQuizQuestion(
      id: 'tennis_adv_mcq_kick_serve',
      conceptKey: 'tennis_kick_serve_second',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.technique,
      koPrompt: '두 번째 서브에서 킥 서브가 유용한 대표 이유는?',
      enPrompt: 'Why is a kick serve useful as a second serve?',
      options: const [
        _FootballQuizOption(
          koText: '높은 네트 클리어런스와 바운드로 안정성과 리턴 압박을 함께 만든다',
          enText:
              'It combines net clearance, bounce, safety, and return pressure',
        ),
        _FootballQuizOption(
          koText: '항상 에이스가 되기 때문',
          enText: 'Because it is always an ace',
        ),
        _FootballQuizOption(
          koText: '공이 바운드하지 않기 때문',
          enText: 'Because the ball does not bounce',
        ),
        _FootballQuizOption(
          koText: '서브 순서를 바꿀 수 있기 때문',
          enText: 'Because it changes the service order',
        ),
      ],
      correctIndex: 0,
      koExplain: '킥 서브는 회전으로 안정적인 높이를 만들고 바운드 후 상대 타점을 흔듭니다.',
      enExplain:
          'A kick serve uses spin for safer height and a bounce that disrupts contact point.',
      koNextPoint: '두 번째 서브는 속도보다 회전, 높이, 목표 지점을 먼저 안정시키세요.',
      enNextPoint:
          'For second serves, stabilize spin, height, and target before speed.',
    ),
    _sportQuizQuestion(
      id: 'tennis_adv_mcq_inside_out_forehand',
      conceptKey: 'tennis_inside_out_forehand',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.tactics,
      koPrompt: '인사이드아웃 포핸드를 선택하기 좋은 상황은?',
      enPrompt: 'When is an inside-out forehand a good choice?',
      options: const [
        _FootballQuizOption(
          koText: '백핸드 쪽 공을 돌아서 상대 백핸드 코너로 주도권을 보낼 수 있을 때',
          enText:
              'When you can run around the backhand and drive to the opponent backhand corner',
        ),
        _FootballQuizOption(
          koText: '몸 균형이 완전히 무너졌을 때마다',
          enText: 'Every time your balance is completely broken',
        ),
        _FootballQuizOption(
          koText: '상대가 네트 앞에 있고 빈 코트가 없을 때만',
          enText: 'Only when the opponent is at net and no court is open',
        ),
        _FootballQuizOption(
          koText: '서브 전에만 사용할 수 있다',
          enText: 'It can only be used before serving',
        ),
      ],
      correctIndex: 0,
      koExplain: '인사이드아웃 포핸드는 발 빠르게 돌아서 강점 샷으로 대각 주도권을 잡는 패턴입니다.',
      enExplain:
          'Inside-out forehand uses footwork to turn a backhand-side ball into a forehand pattern.',
      koNextPoint: '공격 패턴은 샷 이름보다 발 위치와 회복 위치까지 함께 보세요.',
      enNextPoint:
          'For attacking patterns, connect shot name with footwork and recovery position.',
    ),
    _sportQuizQuestion(
      id: 'tennis_adv_mcq_slice_time',
      conceptKey: 'tennis_slice_time_control',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.technique,
      koPrompt: '수비 상황에서 낮은 슬라이스가 유용한 이유는?',
      enPrompt: 'Why can a low slice be useful in a defensive situation?',
      options: const [
        _FootballQuizOption(
          koText: '공을 낮게 깔아 시간을 벌고 상대가 위로 들어올리게 만든다',
          enText:
              'It buys time and keeps the ball low, forcing the opponent to lift',
        ),
        _FootballQuizOption(
          koText: '네트를 없애기 때문',
          enText: 'Because it removes the net',
        ),
        _FootballQuizOption(
          koText: '상대 포인트를 두 점 깎기 때문',
          enText: 'Because it subtracts two opponent points',
        ),
        _FootballQuizOption(
          koText: '공이 코트 밖으로 나가도 인이 되기 때문',
          enText: 'Because an out ball becomes in',
        ),
      ],
      correctIndex: 0,
      koExplain: '슬라이스는 속도를 늦추고 낮은 바운드를 만들어 수비에서 중립으로 돌아갈 시간을 줍니다.',
      enExplain:
          'Slice slows the ball and creates a low bounce, helping defense return toward neutral.',
      koNextPoint: '수비 샷은 위너보다 시간, 높이, 다음 위치 회복으로 평가하세요.',
      enNextPoint:
          'Judge defensive shots by time, height, and recovery, not only winners.',
    ),
    _sportQuizQuestion(
      id: 'tennis_adv_mcq_return_position',
      conceptKey: 'tennis_return_position_big_server',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.positions,
      koPrompt: '강한 서버를 상대할 때 리턴 위치 조정의 좋은 기준은?',
      enPrompt:
          'Against a big server, what is a good principle for adjusting return position?',
      options: const [
        _FootballQuizOption(
          koText: '서브 속도, 바운드 높이, 내가 공을 맞히는 타점을 기준으로 앞뒤를 조정한다',
          enText:
              'Adjust forward or back based on serve speed, bounce height, and your contact point',
        ),
        _FootballQuizOption(
          koText: '항상 베이스라인 안쪽 두 걸음에 선다',
          enText: 'Always stand two steps inside the baseline',
        ),
        _FootballQuizOption(
          koText: '상대 토스와 상관없이 눈을 감고 기다린다',
          enText: 'Ignore the toss and wait with eyes closed',
        ),
        _FootballQuizOption(
          koText: '리턴 때는 스플릿 스텝을 하지 않는다',
          enText: 'Never split step on return',
        ),
      ],
      correctIndex: 0,
      koExplain: '리턴 위치는 자존심이 아니라 실제 타점과 반응 시간을 맞추기 위한 조정입니다.',
      enExplain:
          'Return position is an adjustment for contact point and reaction time, not pride.',
      koNextPoint: '리턴 전략은 위치, 스플릿 스텝 타이밍, 첫 목표를 함께 잡으세요.',
      enNextPoint:
          'Return strategy links position, split-step timing, and first target.',
    ),
    _sportQuizQuestion(
      id: 'tennis_adv_mcq_drop_shot_timing',
      conceptKey: 'tennis_drop_shot_timing',
      difficulty: 3,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.tactics,
      koPrompt: '드롭샷을 쓰기 좋은 전술적 조건은?',
      enPrompt: 'What tactical condition makes a drop shot more suitable?',
      options: const [
        _FootballQuizOption(
          koText: '상대를 뒤로 밀어낸 뒤 균형이 뒤에 있을 때 앞 공간을 찌른다',
          enText:
              'After pushing the opponent back, attack the front space while their balance is deep',
        ),
        _FootballQuizOption(
          koText: '내가 완전히 밀려 공을 겨우 맞힐 때마다',
          enText: 'Whenever I am fully stretched and barely reaching the ball',
        ),
        _FootballQuizOption(
          koText: '상대가 네트 앞에 서 있을 때만',
          enText: 'Only when the opponent is already at the net',
        ),
        _FootballQuizOption(
          koText: '바람이 불면 항상 첫 샷으로',
          enText: 'Always as the first shot whenever there is wind',
        ),
      ],
      correctIndex: 0,
      koExplain: '좋은 드롭샷은 기술보다 먼저 상대 위치와 균형을 뒤로 묶어 둔 전술적 준비에서 나옵니다.',
      enExplain:
          'A good drop shot starts with tactical setup: opponent position and balance are pulled deep first.',
      koNextPoint: '기술 샷은 언제 쓰는지가 어떻게 치는지만큼 중요합니다.',
      enNextPoint:
          'For touch shots, when to use them matters as much as how to hit them.',
    ),
    _sportQuizQuestion(
      id: 'tennis_adv_mcq_tiebreak_process',
      conceptKey: 'tennis_tiebreak_process',
      difficulty: 2,
      style: _QuestionStyle.multipleChoice,
      category: _QuizCategory.mindset,
      koPrompt: '타이브레이크 초반 더 좋은 멘탈/전술 접근은?',
      enPrompt:
          'Early in a tiebreak, what is a better mental and tactical approach?',
      options: const [
        _FootballQuizOption(
          koText: '첫 서브 확률, 깊은 리턴, 다음 한 포인트 루틴에 집중한다',
          enText:
              'Focus on first-serve percentage, deep returns, and the next-point routine',
        ),
        _FootballQuizOption(
          koText: '점수 생각 때문에 루틴을 모두 버린다',
          enText: 'Abandon every routine because of the score',
        ),
        _FootballQuizOption(
          koText: '한 포인트를 잃으면 세트가 끝났다고 판단한다',
          enText: 'Treat the set as over after losing one point',
        ),
        _FootballQuizOption(
          koText: '위험한 위너만 계속 노린다',
          enText: 'Keep going only for risky winners',
        ),
      ],
      correctIndex: 0,
      koExplain: '타이브레이크는 점수 압박이 커질수록 루틴, 첫 서브, 리턴 깊이 같은 반복 가능한 기준이 중요합니다.',
      enExplain:
          'In tiebreaks, repeatable anchors such as routine, first serve, and return depth matter under pressure.',
      koNextPoint: '압박 점수에서는 결과보다 다음 포인트의 첫 행동 단서를 잡으세요.',
      enNextPoint:
          'Under pressure, hold a first-action cue for the next point rather than the outcome.',
    ),
    _sportQuizQuestion(
      id: 'tennis_adv_ox_recovery_position',
      conceptKey: 'tennis_recovery_position',
      difficulty: 2,
      style: _QuestionStyle.ox,
      category: _QuizCategory.positions,
      koPrompt: '좋은 샷 뒤에도 다음 상대 샷 각도에 맞춰 회복 위치를 잡는 것이 중요하다. O/X',
      enPrompt:
          'Even after a good shot, recovering to a position that matches the opponent’s likely angles matters. True/False',
      options: const [
        _FootballQuizOption(koText: 'O', enText: 'True'),
        _FootballQuizOption(koText: 'X', enText: 'False'),
      ],
      correctIndex: 0,
      koExplain: '테니스는 한 번 잘 치는 것보다 다음 공을 받을 위치까지 연결해야 랠리 주도권이 유지됩니다.',
      enExplain:
          'Tennis control depends on connecting a good shot with the recovery position for the next ball.',
      koNextPoint: '샷 평가에는 공의 질과 회복 위치를 같이 넣으세요.',
      enNextPoint:
          'Evaluate shots together with the recovery position they allow.',
    ),
    _sportQuizQuestion(
      id: 'tennis_adv_sa_serve_plus_one',
      conceptKey: 'tennis_serve_plus_one_term',
      difficulty: 3,
      style: _QuestionStyle.shortAnswer,
      category: _QuizCategory.tactics,
      koPrompt: '서브 코스와 그 다음 첫 공격 샷을 한 세트로 설계하는 패턴 이름은?',
      enPrompt:
          'What pattern links serve location with the first attacking shot after it?',
      acceptedAnswers: const [
        '서브 플러스 원',
        'serve plus one',
        'serve-plus-one',
      ],
      koExplain: '정답은 "서브 플러스 원"입니다. 서브 이후 첫 공격까지 미리 연결하는 전술 패턴입니다.',
      enExplain:
          'The answer is "serve-plus-one." It links the serve with the first attacking shot.',
      koNextPoint: '서브 패턴은 넣는 것에서 끝나지 않고 다음 샷까지 설계하세요.',
      enNextPoint:
          'Serve patterns should be designed through the next shot, not just the serve.',
    ),
    _sportQuizQuestion(
      id: 'tennis_adv_sa_kick_serve',
      conceptKey: 'tennis_kick_serve_term',
      difficulty: 2,
      style: _QuestionStyle.shortAnswer,
      category: _QuizCategory.technique,
      koPrompt: '회전으로 높게 튀어 두 번째 서브에서 안정성과 압박을 함께 주는 서브는?',
      enPrompt:
          'What serve uses spin and high bounce to add safety and pressure, often on second serve?',
      acceptedAnswers: const ['킥 서브', 'kick serve', 'kickserve'],
      koExplain: '정답은 "킥 서브"입니다. 높은 궤적과 바운드로 안전성과 리턴 압박을 함께 만듭니다.',
      enExplain:
          'The answer is "kick serve." Its shape and bounce combine safety with return pressure.',
      koNextPoint: '서브 종류는 궤적, 바운드, 다음 코트 위치까지 함께 익히세요.',
      enNextPoint:
          'Learn serve types through flight, bounce, and next-court position.',
    ),
  ];
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
  for (final question in _allSportQuizPoolCache) {
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
  for (final question in _allSportQuizPoolCache) {
    map[question.id] = question;
    for (final entry in _legacyQuestionAliases(question).entries) {
      map[entry.key] = entry.value;
    }
  }
  return map;
}();

final Map<String, _FootballQuizQuestion> _quizQuestionByConcept = () {
  final map = <String, _FootballQuizQuestion>{};
  for (final question in _allSportQuizPoolCache) {
    map.putIfAbsent(question.conceptKey, () => question);
  }
  return map;
}();

final List<_FootballQuizQuestion> _footballQuizPoolCache =
    List<_FootballQuizQuestion>.unmodifiable(_buildFootballQuizPool());

final List<_FootballQuizQuestion> _baseballQuizPoolCache =
    List<_FootballQuizQuestion>.unmodifiable(_buildBaseballQuizPool());

final List<_FootballQuizQuestion> _basketballQuizPoolCache =
    List<_FootballQuizQuestion>.unmodifiable(_buildBasketballQuizPool());

final List<_FootballQuizQuestion> _tennisQuizPoolCache =
    List<_FootballQuizQuestion>.unmodifiable(_buildTennisQuizPool());

final List<_FootballQuizQuestion> _allSportQuizPoolCache =
    List<_FootballQuizQuestion>.unmodifiable([
  ..._footballQuizPoolCache,
  ..._baseballQuizPoolCache,
  ..._basketballQuizPoolCache,
  ..._tennisQuizPoolCache,
]);

List<_FootballQuizQuestion> _quizPoolForSport(String? sportId) {
  return switch (SportCatalog.normalizeSportId(sportId)) {
    SportCatalog.baseballId => _baseballQuizPoolCache,
    SportCatalog.basketballId => _basketballQuizPoolCache,
    SportCatalog.tennisId => _tennisQuizPoolCache,
    _ => _footballQuizPoolCache,
  };
}

class QuizQualityHarnessReport {
  final Map<String, int> questionCountBySport;
  final Map<String, Map<String, int>> styleCountBySport;
  final Map<String, Map<String, int>> categoryCountBySport;
  final List<String> failures;

  const QuizQualityHarnessReport({
    required this.questionCountBySport,
    required this.styleCountBySport,
    required this.categoryCountBySport,
    required this.failures,
  });

  bool get passed => failures.isEmpty;

  String toConsoleString() {
    final buffer = StringBuffer('Quiz quality harness report');
    for (final sportId in questionCountBySport.keys) {
      buffer.writeln();
      buffer.writeln('- $sportId: ${questionCountBySport[sportId]} questions');
      buffer.writeln('  styles: ${styleCountBySport[sportId]}');
      buffer.writeln('  categories: ${categoryCountBySport[sportId]}');
    }
    if (failures.isEmpty) {
      buffer.writeln();
      buffer.writeln('PASS');
    } else {
      buffer.writeln();
      buffer.writeln('FAILURES');
      for (final failure in failures) {
        buffer.writeln('- $failure');
      }
    }
    return buffer.toString();
  }
}

class QuizDraftSeed {
  final String sportId;
  final String idStem;
  final String conceptKey;
  final String category;
  final String style;
  final int difficulty;
  final String subject;
  final String koPrompt;
  final String enPrompt;
  final String koAnswer;
  final String enAnswer;
  final String koExplanationAngle;
  final String enExplanationAngle;
  final String koNextPointAngle;
  final String enNextPointAngle;
  final String koReason;
  final String enReason;

  const QuizDraftSeed({
    required this.sportId,
    required this.idStem,
    required this.conceptKey,
    required this.category,
    required this.style,
    required this.difficulty,
    required this.subject,
    required this.koPrompt,
    required this.enPrompt,
    required this.koAnswer,
    required this.enAnswer,
    required this.koExplanationAngle,
    required this.enExplanationAngle,
    required this.koNextPointAngle,
    required this.enNextPointAngle,
    required this.koReason,
    required this.enReason,
  });

  String toMarkdownString() {
    return [
      '### $idStem',
      '',
      '- sport: `$sportId`',
      '- concept: `$conceptKey`',
      '- category/style/difficulty: `$category` / `$style` / `$difficulty`',
      '- subject: $subject',
      '- prompt(ko): $koPrompt',
      '- prompt(en): $enPrompt',
      '- answer(ko): $koAnswer',
      '- answer(en): $enAnswer',
      '- explanation angle(ko): $koExplanationAngle',
      '- explanation angle(en): $enExplanationAngle',
      '- next-point cue(ko): $koNextPointAngle',
      '- next-point cue(en): $enNextPointAngle',
      '- generation reason(ko): $koReason',
      '- generation reason(en): $enReason',
    ].join('\n');
  }
}

class QuizGenerationHarnessReport {
  final QuizQualityHarnessReport qualityReport;
  final Map<String, List<QuizDraftSeed>> draftSeedsBySport;
  final List<String> failures;

  const QuizGenerationHarnessReport({
    required this.qualityReport,
    required this.draftSeedsBySport,
    required this.failures,
  });

  bool get passed => failures.isEmpty;

  int get totalDraftSeeds => draftSeedsBySport.values.fold<int>(
        0,
        (sum, seeds) => sum + seeds.length,
      );

  String toConsoleString() {
    final buffer = StringBuffer('Quiz generation harness report');
    buffer.writeln();
    buffer.writeln('quality gate: ${qualityReport.passed ? 'PASS' : 'FAIL'}');
    buffer.writeln('draft seeds: $totalDraftSeeds');
    for (final sportId in draftSeedsBySport.keys) {
      final seeds = draftSeedsBySport[sportId] ?? const <QuizDraftSeed>[];
      buffer.writeln('- $sportId: ${seeds.length} draft seeds');
      for (final seed in seeds.take(3)) {
        buffer.writeln(
          '  - ${seed.idStem} (${seed.category}/${seed.style}/d${seed.difficulty})',
        );
      }
    }
    if (failures.isEmpty) {
      buffer.writeln('PASS');
    } else {
      buffer.writeln('FAILURES');
      for (final failure in failures) {
        buffer.writeln('- $failure');
      }
    }
    return buffer.toString();
  }

  String toMarkdownString() {
    final buffer = StringBuffer();
    buffer.writeln('# Quiz Generation Harness Report');
    buffer.writeln();
    buffer.writeln('- quality gate: ${qualityReport.passed ? 'PASS' : 'FAIL'}');
    buffer.writeln('- draft seeds: $totalDraftSeeds');
    buffer.writeln('- generation mode: curated deterministic draft seeds');
    buffer.writeln();
    if (failures.isNotEmpty) {
      buffer.writeln('## Failures');
      buffer.writeln();
      for (final failure in failures) {
        buffer.writeln('- $failure');
      }
      buffer.writeln();
    }
    for (final sportId in draftSeedsBySport.keys) {
      buffer.writeln('## $sportId');
      buffer.writeln();
      for (final seed
          in draftSeedsBySport[sportId] ?? const <QuizDraftSeed>[]) {
        buffer.writeln(seed.toMarkdownString());
        buffer.writeln();
      }
    }
    return buffer.toString();
  }
}

QuizQualityHarnessReport buildQuizQualityHarnessReport({
  Map<String, int> minimumQuestionsBySport = const <String, int>{
    SportCatalog.footballId: 120,
    SportCatalog.baseballId: 20,
    SportCatalog.basketballId: 20,
    SportCatalog.tennisId: 20,
  },
  int minimumQuestionsPerStyle = 20,
}) {
  const sportIds = <String>[
    SportCatalog.footballId,
    SportCatalog.baseballId,
    SportCatalog.basketballId,
    SportCatalog.tennisId,
  ];
  const requiredSearchTermsBySport = <String, List<String>>{
    SportCatalog.footballId: ['보스만 판결', '오리엔티드 터치', '커버 섀도'],
    SportCatalog.baseballId: ['터널링', 'WHIP'],
    SportCatalog.basketballId: ['스페인 픽앤롤', '네일'],
    SportCatalog.tennisId: ['서브 플러스 원', '킥 서브'],
  };
  const lowQualityFragments = <String>[
    '벤치의 물병',
    '심판의 손목시계',
    '관중석 색깔',
    '공격수의 등번호',
    '타자의 등번호',
    '배트 색',
    '잔디 길이',
    '라켓을 바꾼다',
    '점수를 숨긴다',
  ];

  final failures = <String>[];
  final questionCountBySport = <String, int>{};
  final styleCountBySport = <String, Map<String, int>>{};
  final categoryCountBySport = <String, Map<String, int>>{};
  final globalIds = <String>{};
  final globalContentKeys = <String>{};

  for (final sportId in sportIds) {
    final questions = _quizPoolForSport(sportId);
    questionCountBySport[sportId] = questions.length;
    final styleCounts = <String, int>{};
    final categoryCounts = <String, int>{};
    final difficultyCounts = <int, int>{};
    final sportConcepts = <String>{};
    var coreFocusCount = 0;

    final minimum = minimumQuestionsBySport[sportId] ?? 1;
    if (questions.length < minimum) {
      failures.add(
        '$sportId has ${questions.length} questions; minimum is $minimum.',
      );
    }

    for (final question in questions) {
      final scopedId = '$sportId:${question.id}';
      if (!globalIds.add(scopedId)) {
        failures.add('Duplicate question id: $scopedId.');
      }
      if (question.id.trim().isEmpty || question.conceptKey.trim().isEmpty) {
        failures.add('$scopedId has an empty id or concept key.');
      }
      if (question.difficulty < 1 || question.difficulty > 3) {
        failures
            .add('$scopedId has invalid difficulty ${question.difficulty}.');
      }
      if (question.koPrompt.trim().length < 12 ||
          question.enPrompt.trim().length < 12) {
        failures.add('$scopedId prompt is too thin.');
      }
      if (question.koExplain.trim().length < 18 ||
          question.enExplain.trim().length < 18) {
        failures.add('$scopedId explanation is too thin.');
      }
      if (question.koNextPoint.trim().length < 10 ||
          question.enNextPoint.trim().length < 10) {
        failures.add('$scopedId next-point coaching cue is too thin.');
      }

      final contentKey = _quizHarnessContentKey(question);
      if (!globalContentKeys.add('$sportId:$contentKey')) {
        failures.add('Duplicate question content in $sportId: ${question.id}.');
      }

      final haystack = _quizHarnessSearchText(question);
      for (final fragment in lowQualityFragments) {
        if (haystack.contains(fragment.toLowerCase())) {
          failures.add('$scopedId contains low-quality fragment "$fragment".');
        }
      }

      if (question.style == _QuestionStyle.shortAnswer) {
        if (question.acceptedAnswers.isEmpty) {
          failures.add('$scopedId short-answer question has no answers.');
        } else if (!_answerMatchesQuestion(
          question,
          question.acceptedAnswers.first,
        )) {
          failures
              .add('$scopedId short-answer first answer does not validate.');
        }
      } else {
        if (question.options.length < 2) {
          failures.add('$scopedId choice question has too few options.');
        }
        if (question.correctIndex < 0 ||
            question.correctIndex >= question.options.length) {
          failures.add('$scopedId correct index is invalid.');
        }
        final optionKeys = question.options
            .map((option) => option.text(true).trim().toLowerCase())
            .toSet();
        if (optionKeys.length != question.options.length) {
          failures.add('$scopedId has duplicate Korean answer options.');
        }
      }

      styleCounts[question.style.name] =
          (styleCounts[question.style.name] ?? 0) + 1;
      categoryCounts[question.category.name] =
          (categoryCounts[question.category.name] ?? 0) + 1;
      difficultyCounts[question.difficulty] =
          (difficultyCounts[question.difficulty] ?? 0) + 1;
      sportConcepts.add(question.conceptKey);
      if (question.category.isCoreFocus) {
        coreFocusCount += 1;
      }
    }

    for (final style in _QuestionStyle.values) {
      final styleCount = styleCounts[style.name] ?? 0;
      if (styleCount < minimumQuestionsPerStyle) {
        failures.add(
          '$sportId has $styleCount ${style.name} questions; '
          'minimum per question style is $minimumQuestionsPerStyle.',
        );
      }
    }
    for (final difficulty in [1, 2, 3]) {
      if ((difficultyCounts[difficulty] ?? 0) == 0) {
        failures.add('$sportId has no difficulty $difficulty questions.');
      }
    }
    if (categoryCounts.length < 5) {
      failures.add('$sportId has only ${categoryCounts.length} categories.');
    }
    if (sportConcepts.length < (questions.length * 0.75).ceil()) {
      failures.add('$sportId has too many repeated concept keys.');
    }
    if (coreFocusCount < (questions.length * 0.35).ceil()) {
      failures.add('$sportId core focus ratio is too low.');
    }

    for (final term
        in requiredSearchTermsBySport[sportId] ?? const <String>[]) {
      final normalizedTerm = term.toLowerCase();
      final found = questions.any(
        (question) => _quizHarnessSearchText(question).contains(normalizedTerm),
      );
      if (!found) {
        failures.add('$sportId is missing required search anchor "$term".');
      }
    }

    styleCountBySport[sportId] = styleCounts;
    categoryCountBySport[sportId] = categoryCounts;
  }

  return QuizQualityHarnessReport(
    questionCountBySport: Map<String, int>.unmodifiable(questionCountBySport),
    styleCountBySport: Map<String, Map<String, int>>.unmodifiable(
      styleCountBySport.map<String, Map<String, int>>(
        (key, value) => MapEntry(
          key,
          Map<String, int>.unmodifiable(value),
        ),
      ),
    ),
    categoryCountBySport: Map<String, Map<String, int>>.unmodifiable(
      categoryCountBySport.map<String, Map<String, int>>(
        (key, value) => MapEntry(
          key,
          Map<String, int>.unmodifiable(value),
        ),
      ),
    ),
    failures: List.unmodifiable(failures),
  );
}

QuizGenerationHarnessReport buildQuizGenerationHarnessReport({
  int seedsPerSport = 8,
}) {
  const sportIds = <String>[
    SportCatalog.footballId,
    SportCatalog.baseballId,
    SportCatalog.basketballId,
    SportCatalog.tennisId,
  ];

  final targetSeeds = math.max(1, seedsPerSport);
  final qualityReport = buildQuizQualityHarnessReport();
  final failures = <String>[
    for (final failure in qualityReport.failures) 'quality gate: $failure',
  ];
  final draftSeedsBySport = <String, List<QuizDraftSeed>>{};

  for (final sportId in sportIds) {
    final seeds = _buildQuizDraftSeedsForSport(sportId, targetSeeds);
    if (seeds.length < targetSeeds) {
      failures.add(
        '$sportId generated ${seeds.length} draft seeds; target is $targetSeeds.',
      );
    }
    draftSeedsBySport[sportId] = List<QuizDraftSeed>.unmodifiable(seeds);
  }

  return QuizGenerationHarnessReport(
    qualityReport: qualityReport,
    draftSeedsBySport:
        Map<String, List<QuizDraftSeed>>.unmodifiable(draftSeedsBySport),
    failures: List<String>.unmodifiable(failures),
  );
}

String _quizHarnessContentKey(_FootballQuizQuestion question) {
  String normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  final optionKey = question.options
      .map(
          (option) => '${normalize(option.koText)}|${normalize(option.enText)}')
      .join('||');
  final answerKey = [...question.acceptedAnswers]..sort();
  return [
    question.style.name,
    question.category.name,
    normalize(question.koPrompt),
    normalize(question.enPrompt),
    optionKey,
    question.correctIndex.toString(),
    answerKey.map(normalize).join('|'),
  ].join('::');
}

String _quizHarnessSearchText(_FootballQuizQuestion question) {
  return [
    question.id,
    question.conceptKey,
    question.koPrompt,
    question.enPrompt,
    question.koExplain,
    question.enExplain,
    question.koNextPoint,
    question.enNextPoint,
    question.displayAnswer(true),
    question.displayAnswer(false),
    ...question.options.map((option) => option.koText),
    ...question.options.map((option) => option.enText),
  ].join(' ').toLowerCase();
}

List<QuizDraftSeed> _buildQuizDraftSeedsForSport(
  String sportId,
  int targetSeeds,
) {
  final existingQuestions = _quizPoolForSport(sportId);
  final existingIds = existingQuestions.map((question) => question.id).toSet();
  final existingConcepts =
      existingQuestions.map((question) => question.conceptKey).toSet();
  final styleCounts = <_QuestionStyle, int>{};
  final categoryCounts = <_QuizCategory, int>{};
  final difficultyCounts = <int, int>{};
  for (final question in existingQuestions) {
    styleCounts[question.style] = (styleCounts[question.style] ?? 0) + 1;
    categoryCounts[question.category] =
        (categoryCounts[question.category] ?? 0) + 1;
    difficultyCounts[question.difficulty] =
        (difficultyCounts[question.difficulty] ?? 0) + 1;
  }

  final candidates = _quizDraftSeedCandidates
      .where((candidate) => candidate.sportId == sportId)
      .where((candidate) => !existingIds.contains(candidate.idStem))
      .where((candidate) => !existingConcepts.contains(candidate.conceptKey))
      .toList()
    ..sort(
      (a, b) => _quizDraftSeedScore(
        b,
        styleCounts,
        categoryCounts,
        difficultyCounts,
      ).compareTo(
        _quizDraftSeedScore(
          a,
          styleCounts,
          categoryCounts,
          difficultyCounts,
        ),
      ),
    );

  final selected = <_QuizDraftSeedCandidate>[];
  final seenCategories = <_QuizCategory>{};
  final seenStyles = <_QuestionStyle>{};

  for (final candidate in candidates) {
    if (selected.length >= targetSeeds) break;
    final addsNewCategory = !seenCategories.contains(candidate.category);
    final addsNewStyle = !seenStyles.contains(candidate.style);
    if (addsNewCategory || addsNewStyle) {
      selected.add(candidate);
      seenCategories.add(candidate.category);
      seenStyles.add(candidate.style);
    }
  }
  for (final candidate in candidates) {
    if (selected.length >= targetSeeds) break;
    if (!selected.contains(candidate)) {
      selected.add(candidate);
    }
  }

  return selected.map((candidate) => candidate.toSeed()).toList();
}

int _quizDraftSeedScore(
  _QuizDraftSeedCandidate candidate,
  Map<_QuestionStyle, int> styleCounts,
  Map<_QuizCategory, int> categoryCounts,
  Map<int, int> difficultyCounts,
) {
  final maxStyleCount = styleCounts.values.fold<int>(0, math.max);
  final maxCategoryCount = categoryCounts.values.fold<int>(0, math.max);
  final maxDifficultyCount = difficultyCounts.values.fold<int>(0, math.max);
  final styleNeed = maxStyleCount - (styleCounts[candidate.style] ?? 0);
  final categoryNeed =
      maxCategoryCount - (categoryCounts[candidate.category] ?? 0);
  final difficultyNeed =
      maxDifficultyCount - (difficultyCounts[candidate.difficulty] ?? 0);
  return (categoryNeed * 11) +
      (styleNeed * 7) +
      (difficultyNeed * 5) +
      (candidate.category.isCoreFocus ? 3 : 0);
}

class _QuizDraftSeedCandidate {
  final String sportId;
  final String idStem;
  final String conceptKey;
  final _QuizCategory category;
  final _QuestionStyle style;
  final int difficulty;
  final String subject;
  final String koPrompt;
  final String enPrompt;
  final String koAnswer;
  final String enAnswer;
  final String koExplanationAngle;
  final String enExplanationAngle;
  final String koNextPointAngle;
  final String enNextPointAngle;
  final String koReason;
  final String enReason;

  const _QuizDraftSeedCandidate({
    required this.sportId,
    required this.idStem,
    required this.conceptKey,
    required this.category,
    required this.style,
    required this.difficulty,
    required this.subject,
    required this.koPrompt,
    required this.enPrompt,
    required this.koAnswer,
    required this.enAnswer,
    required this.koExplanationAngle,
    required this.enExplanationAngle,
    required this.koNextPointAngle,
    required this.enNextPointAngle,
    required this.koReason,
    required this.enReason,
  });

  QuizDraftSeed toSeed() {
    return QuizDraftSeed(
      sportId: sportId,
      idStem: idStem,
      conceptKey: conceptKey,
      category: category.name,
      style: style.name,
      difficulty: difficulty,
      subject: subject,
      koPrompt: koPrompt,
      enPrompt: enPrompt,
      koAnswer: koAnswer,
      enAnswer: enAnswer,
      koExplanationAngle: koExplanationAngle,
      enExplanationAngle: enExplanationAngle,
      koNextPointAngle: koNextPointAngle,
      enNextPointAngle: enNextPointAngle,
      koReason: koReason,
      enReason: enReason,
    );
  }
}

const List<_QuizDraftSeedCandidate> _quizDraftSeedCandidates =
    <_QuizDraftSeedCandidate>[
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.footballId,
    idStem: 'draft_football_back_pass_rule_history',
    conceptKey: 'draft_football_back_pass_rule_history',
    category: _QuizCategory.rules,
    style: _QuestionStyle.multipleChoice,
    difficulty: 2,
    subject: 'football history/rules',
    koPrompt: '1992년 백패스 룰 변화가 골키퍼와 빌드업 방식에 준 핵심 영향은?',
    enPrompt:
        'What was the key build-up impact of the 1992 back-pass rule change?',
    koAnswer: '골키퍼의 발 기술과 압박 회피 빌드업 가치가 커졌다',
    enAnswer:
        'Goalkeepers needed better foot skill and build-up value under pressure',
    koExplanationAngle: '룰 변화가 단순 규정이 아니라 포지션 기술 요구를 바꿨다는 관점으로 설명한다.',
    enExplanationAngle:
        'Explain the rule as a change in positional skill demands, not trivia.',
    koNextPointAngle: '역사 문항은 현재 전술과 연결되는 행동 변화까지 묻는다.',
    enNextPointAngle:
        'Connect history questions to the behavior that changed modern tactics.',
    koReason: '축구 역사와 현대 빌드업 이해를 동시에 확장한다.',
    enReason: 'Expands football history while tying it to modern build-up.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.footballId,
    idStem: 'draft_football_false_nine_reference',
    conceptKey: 'draft_football_false_nine_reference',
    category: _QuizCategory.tactics,
    style: _QuestionStyle.shortAnswer,
    difficulty: 3,
    subject: 'football tactics',
    koPrompt: '최전방 공격수가 내려와 센터백을 끌어내고 2선 침투 공간을 여는 역할은?',
    enPrompt:
        'What role drops from the front line to pull center backs out and open runner space?',
    koAnswer: '펄스 나인',
    enAnswer: 'false nine',
    koExplanationAngle: '정답명뿐 아니라 수비 라인이 따라 나올 때 생기는 공간을 함께 설명한다.',
    enExplanationAngle:
        'Explain the space created when the defensive line follows the drop.',
    koNextPointAngle: '역할 이름을 외우기보다 움직임이 어느 라인을 흔드는지 보게 한다.',
    enNextPointAngle:
        'Focus on which defensive line the movement disrupts, not only the label.',
    koReason: '고급 전술 용어를 공간 창출 원리와 묶는다.',
    enReason:
        'Links an advanced tactical term to the principle of creating space.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.footballId,
    idStem: 'draft_football_rest_defense_balance',
    conceptKey: 'draft_football_rest_defense_balance',
    category: _QuizCategory.tactics,
    style: _QuestionStyle.multipleChoice,
    difficulty: 3,
    subject: 'football tactics',
    koPrompt: '공격 중에도 역습을 막기 위해 뒤에 남는 구조를 설계하는 개념은?',
    enPrompt:
        'What concept describes the structure kept behind the attack to stop counters?',
    koAnswer: '레스트 디펜스',
    enAnswer: 'rest defense',
    koExplanationAngle: '볼 소유 전술이 공격 숫자만이 아니라 잃었을 때의 첫 수비 구조까지 포함함을 설명한다.',
    enExplanationAngle:
        'Explain possession as including the first defensive structure after loss.',
    koNextPointAngle: '공격 장면에서도 뒤쪽 커버 숫자와 거리 간격을 같이 관찰하게 한다.',
    enNextPointAngle:
        'Train the viewer to inspect cover numbers and spacing during attacks.',
    koReason: '전술 문항을 공격/수비 전환의 연결 구조로 높인다.',
    enReason:
        'Raises tactical quality by connecting attack shape to transition defense.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.footballId,
    idStem: 'draft_football_touchline_pressing_trap',
    conceptKey: 'draft_football_touchline_pressing_trap',
    category: _QuizCategory.tactics,
    style: _QuestionStyle.ox,
    difficulty: 2,
    subject: 'football pressing',
    koPrompt: '터치라인 쪽으로 유도한 압박은 상대 선택지를 줄이는 데 도움이 된다. O/X',
    enPrompt:
        'Pressing toward the touchline can reduce the opponent’s options. True/False',
    koAnswer: 'O',
    enAnswer: 'True',
    koExplanationAngle: '라인이 사실상 추가 수비수처럼 작동해 패스 방향을 줄이는 원리를 설명한다.',
    enExplanationAngle:
        'Explain how the line acts like an extra defender by reducing passing lanes.',
    koNextPointAngle: '압박 성공 여부보다 어디로 몰았는지 먼저 체크하게 한다.',
    enNextPointAngle:
        'Check where pressure sends the ball before judging the tackle outcome.',
    koReason: '압박 퀴즈를 태클 여부가 아니라 유도 방향 중심으로 만든다.',
    enReason:
        'Keeps pressing questions focused on direction, not just tackling.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.footballId,
    idStem: 'draft_football_penalty_shootout_routine',
    conceptKey: 'draft_football_penalty_shootout_routine',
    category: _QuizCategory.mindset,
    style: _QuestionStyle.multipleChoice,
    difficulty: 2,
    subject: 'football mindset',
    koPrompt: '승부차기 전 루틴이 가장 직접적으로 줄여주는 위험은?',
    enPrompt: 'What risk does a pre-penalty routine most directly reduce?',
    koAnswer: '결과 생각으로 동작 단서가 흔들리는 위험',
    enAnswer: 'Losing action cues because attention drifts to the result',
    koExplanationAngle: '멘탈 문항을 추상적 자신감이 아니라 반복 가능한 행동 단서로 설명한다.',
    enExplanationAngle:
        'Frame mentality through repeatable action cues, not vague confidence.',
    koNextPointAngle: '압박 상황은 감정보다 첫 행동 루틴을 묻도록 설계한다.',
    enNextPointAngle:
        'Pressure questions should ask for the first action routine.',
    koReason: '마인드 퀴즈를 실제 수행 루틴으로 구체화한다.',
    enReason: 'Turns mindset content into a concrete performance routine.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.footballId,
    idStem: 'draft_football_var_offside_line',
    conceptKey: 'draft_football_var_offside_line',
    category: _QuizCategory.rules,
    style: _QuestionStyle.ox,
    difficulty: 2,
    subject: 'football history/rules',
    koPrompt: 'VAR 시대의 공격수는 침투 타이밍뿐 아니라 마지막 수비 라인과의 신체 위치도 더 정교하게 관리해야 한다. O/X',
    enPrompt:
        'In the VAR era, attackers must manage body position against the last line more precisely. True/False',
    koAnswer: 'O',
    enAnswer: 'True',
    koExplanationAngle: '기술 도입이 경기 행동과 라인 관리 습관을 바꾼다는 관점으로 설명한다.',
    enExplanationAngle:
        'Explain technology as changing player habits around timing and line control.',
    koNextPointAngle: '규칙/기술 변화는 실제 움직임의 세밀함으로 연결한다.',
    enNextPointAngle:
        'Tie rules and technology changes to more precise movement behavior.',
    koReason: '현대 축구 역사와 오프사이드 판단 스킬을 연결한다.',
    enReason: 'Connects modern football history with offside-line skill.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.footballId,
    idStem: 'draft_football_inverted_fullback_buildout',
    conceptKey: 'draft_football_inverted_fullback_buildout',
    category: _QuizCategory.positions,
    style: _QuestionStyle.shortAnswer,
    difficulty: 3,
    subject: 'football positions',
    koPrompt: '풀백이 중앙 미드필더처럼 안쪽으로 들어와 빌드업 숫자를 만드는 역할은?',
    enPrompt:
        'What role moves a fullback inside like a midfielder to add build-up numbers?',
    koAnswer: '인버티드 풀백',
    enAnswer: 'inverted fullback',
    koExplanationAngle: '풀백 역할을 측면 오버래핑 하나로 제한하지 않고 중앙 점유 구조와 연결한다.',
    enExplanationAngle:
        'Connect fullback play to central possession structure, not only overlaps.',
    koNextPointAngle: '포지션 문항은 이름보다 점유 구조에서 생기는 수적 우위를 묻게 한다.',
    enNextPointAngle:
        'Ask how the role changes possession numbers, not only its name.',
    koReason: '현대 포지션 역할 변화를 고급 퀴즈 소재로 만든다.',
    enReason: 'Adds modern positional-role evolution as a high-quality topic.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.footballId,
    idStem: 'draft_football_oriented_first_touch_scan',
    conceptKey: 'draft_football_oriented_first_touch_scan',
    category: _QuizCategory.technique,
    style: _QuestionStyle.multipleChoice,
    difficulty: 2,
    subject: 'football technique',
    koPrompt: '압박을 받기 전 오리엔티드 터치를 성공시키려면 터치 직전 가장 중요한 준비는?',
    enPrompt:
        'Before using an oriented first touch under pressure, what preparation matters most?',
    koAnswer: '받기 전 스캔으로 다음 공간과 압박 방향을 확인한다',
    enAnswer:
        'Scan before receiving to identify the next space and pressure direction',
    koExplanationAngle: '터치 기술을 발동작만이 아니라 사전 정보 수집과 연결한다.',
    enExplanationAngle:
        'Link the touch technique to information gathered before receiving.',
    koNextPointAngle: '기술 퀴즈는 동작 전 인지 단계를 반드시 포함한다.',
    enNextPointAngle:
        'Technique questions should include the perception step before the action.',
    koReason: '스킬 퀴즈를 실제 경기 의사결정 품질로 끌어올린다.',
    enReason: 'Raises skill questions into match-speed decision quality.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.baseballId,
    idStem: 'draft_baseball_seam_shifted_wake',
    conceptKey: 'draft_baseball_seam_shifted_wake',
    category: _QuizCategory.technique,
    style: _QuestionStyle.shortAnswer,
    difficulty: 3,
    subject: 'baseball pitching',
    koPrompt: '공의 솔기 방향이 예상과 다른 무브먼트를 만드는 투구 물리 개념은?',
    enPrompt:
        'What pitching concept describes seam orientation creating unexpected movement?',
    koAnswer: '심 시프트 웨이크',
    enAnswer: 'seam-shifted wake',
    koExplanationAngle: '구속보다 회전축과 솔기 방향이 움직임 품질을 바꾼다는 점을 설명한다.',
    enExplanationAngle:
        'Explain how axis and seam orientation can change movement quality.',
    koNextPointAngle: '투구 문항은 결과 구종명보다 움직임이 생기는 원리를 묻게 한다.',
    enNextPointAngle:
        'Pitching questions should ask why movement happens, not only pitch names.',
    koReason: '야구 기술 퀴즈에 현대 투구 분석 개념을 추가한다.',
    enReason: 'Adds modern pitch-analysis depth to baseball technique quizzes.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.baseballId,
    idStem: 'draft_baseball_run_expectancy_second_no_out',
    conceptKey: 'draft_baseball_run_expectancy_second_no_out',
    category: _QuizCategory.tactics,
    style: _QuestionStyle.multipleChoice,
    difficulty: 3,
    subject: 'baseball tactics',
    koPrompt: '무사 2루에서 작전 선택을 평가할 때 가장 먼저 봐야 하는 기준은?',
    enPrompt:
        'When evaluating tactics with a runner on second and no outs, what should be checked first?',
    koAnswer: '득점 기대값과 경기 상황의 균형',
    enAnswer: 'The balance between run expectancy and game context',
    koExplanationAngle: '번트/강공을 정답 암기가 아니라 기대값과 점수 상황의 조합으로 판단한다.',
    enExplanationAngle:
        'Evaluate bunting or swinging through expectancy plus score context.',
    koNextPointAngle: '작전 문항은 주자/아웃/점수판을 함께 읽게 한다.',
    enNextPointAngle:
        'Tactical questions should make runners, outs, and score interact.',
    koReason: '야구 전술 퀴즈를 상황 판단형으로 확장한다.',
    enReason: 'Expands baseball tactics into context-based decision making.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.baseballId,
    idStem: 'draft_baseball_catcher_framing_low_zone',
    conceptKey: 'draft_baseball_catcher_framing_low_zone',
    category: _QuizCategory.technique,
    style: _QuestionStyle.multipleChoice,
    difficulty: 2,
    subject: 'baseball catching',
    koPrompt: '낮은 코스 프레이밍에서 포수가 가장 피해야 할 동작은?',
    enPrompt: 'What should a catcher avoid most when framing a low pitch?',
    koAnswer: '글러브를 크게 끌어올려 심판에게 조작처럼 보이게 하는 동작',
    enAnswer: 'Jerking the glove upward so the receive looks manipulated',
    koExplanationAngle: '프레이밍을 속임수가 아니라 조용한 포구와 안정된 제시의 기술로 설명한다.',
    enExplanationAngle:
        'Frame catching as quiet receiving and stable presentation, not tricks.',
    koNextPointAngle: '수비 기술 문항은 손동작의 크기와 몸 안정성을 같이 묻게 한다.',
    enNextPointAngle:
        'Defensive skill questions should pair glove action with body stability.',
    koReason: '포수 수비 스킬을 세밀한 기술 판단으로 만든다.',
    enReason: 'Adds precise catcher-skill judgment to the baseball pool.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.baseballId,
    idStem: 'draft_baseball_two_strike_approach',
    conceptKey: 'draft_baseball_two_strike_approach',
    category: _QuizCategory.mindset,
    style: _QuestionStyle.ox,
    difficulty: 1,
    subject: 'baseball mindset',
    koPrompt: '투 스트라이크에서는 장타만 노리기보다 존을 넓히고 콘택트 기준을 조정하는 접근이 필요하다. O/X',
    enPrompt:
        'With two strikes, hitters often need to widen the zone and adjust contact goals. True/False',
    koAnswer: 'O',
    enAnswer: 'True',
    koExplanationAngle: '멘탈을 막연한 집중이 아니라 카운트별 타격 기준 조정으로 설명한다.',
    enExplanationAngle:
        'Explain mentality through count-specific hitting adjustments.',
    koNextPointAngle: '타격 문항은 카운트가 선택 기준을 어떻게 바꾸는지 묻는다.',
    enNextPointAngle:
        'Ask how the count changes the hitter’s selection standard.',
    koReason: '기본 카운트 상황도 품질 있는 의사결정 문항으로 만든다.',
    enReason: 'Turns a basic count situation into a decision-quality question.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.baseballId,
    idStem: 'draft_baseball_bullpen_leverage_index',
    conceptKey: 'draft_baseball_bullpen_leverage_index',
    category: _QuizCategory.tactics,
    style: _QuestionStyle.shortAnswer,
    difficulty: 3,
    subject: 'baseball tactics',
    koPrompt: '불펜 투입 시점의 압박도와 승부 중요도를 수치화하는 대표 지표는?',
    enPrompt:
        'What metric captures the pressure and importance of a bullpen situation?',
    koAnswer: '레버리지 인덱스',
    enAnswer: 'leverage index',
    koExplanationAngle: '세이브 상황만이 아니라 경기 내 가장 중요한 아웃을 찾는 관점으로 설명한다.',
    enExplanationAngle:
        'Explain it as finding the highest-value outs, not only save situations.',
    koNextPointAngle: '투수 운용 문항은 이닝보다 상황의 중요도를 먼저 보게 한다.',
    enNextPointAngle:
        'Pitching-management questions should weigh situation before inning labels.',
    koReason: '야구 작전 퀴즈에 현대 지표 기반 판단을 넣는다.',
    enReason: 'Adds modern metric-based judgment to baseball strategy quizzes.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.baseballId,
    idStem: 'draft_baseball_shift_ban_adaptation',
    conceptKey: 'draft_baseball_shift_ban_adaptation',
    category: _QuizCategory.rules,
    style: _QuestionStyle.multipleChoice,
    difficulty: 2,
    subject: 'baseball rules/history',
    koPrompt: '수비 시프트 제한 이후 내야 수비 평가에서 더 중요해진 요소는?',
    enPrompt:
        'After restrictions on defensive shifts, what became more important in infield defense?',
    koAnswer: '개별 수비 범위와 첫 스텝 반응',
    enAnswer: 'Individual range and first-step reaction',
    koExplanationAngle: '규칙 변화가 포지셔닝 자동화보다 선수 개인 수비 능력의 가치를 키웠다는 점을 설명한다.',
    enExplanationAngle:
        'Explain how rule change raised the value of individual defensive range.',
    koNextPointAngle: '규칙 문항은 선수 평가 기준 변화까지 연결한다.',
    enNextPointAngle:
        'Rule questions should connect to changed player-evaluation criteria.',
    koReason: '야구 규칙/역사 문항을 현대 경기 분석과 연결한다.',
    enReason: 'Connects baseball rule history to modern game analysis.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.baseballId,
    idStem: 'draft_baseball_secondary_lead_timing',
    conceptKey: 'draft_baseball_secondary_lead_timing',
    category: _QuizCategory.technique,
    style: _QuestionStyle.ox,
    difficulty: 2,
    subject: 'baseball baserunning',
    koPrompt: '세컨더리 리드는 투수가 던진 뒤 다음 플레이 반응 시간을 줄이는 데 목적이 있다. O/X',
    enPrompt:
        'A secondary lead helps reduce reaction time after the pitcher delivers. True/False',
    koAnswer: 'O',
    enAnswer: 'True',
    koExplanationAngle: '주루를 단순 속도가 아니라 투구 타이밍과 다음 베이스 판단으로 설명한다.',
    enExplanationAngle:
        'Explain baserunning through pitch timing and next-base decisions.',
    koNextPointAngle: '주루 문항은 출발 거리보다 다음 반응 준비를 묻게 한다.',
    enNextPointAngle:
        'Baserunning questions should ask what reaction the lead prepares.',
    koReason: '주루 스킬 문항을 상황 반응 품질로 높인다.',
    enReason: 'Raises baserunning content into reaction-quality skill.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.baseballId,
    idStem: 'draft_baseball_changeup_arm_speed',
    conceptKey: 'draft_baseball_changeup_arm_speed',
    category: _QuizCategory.technique,
    style: _QuestionStyle.multipleChoice,
    difficulty: 2,
    subject: 'baseball pitching',
    koPrompt: '좋은 체인지업이 타자의 타이밍을 빼앗는 핵심 조건은?',
    enPrompt: 'What key condition helps a good changeup disrupt hitter timing?',
    koAnswer: '패스트볼과 비슷한 팔 스피드로 더 느리게 도착한다',
    enAnswer: 'It arrives slower while looking like fastball arm speed',
    koExplanationAngle: '구속 차이만이 아니라 같은 동작에서 생기는 시간 착시를 설명한다.',
    enExplanationAngle:
        'Explain the timing illusion created by similar delivery and lower speed.',
    koNextPointAngle: '구종 문항은 속도보다 타자가 보는 단서를 함께 묻는다.',
    enNextPointAngle:
        'Pitch questions should include what cues the hitter reads.',
    koReason: '투구 스킬 퀴즈를 타자 인지와 연결한다.',
    enReason: 'Connects pitching skill to hitter perception.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.basketballId,
    idStem: 'draft_basketball_point_five_decision',
    conceptKey: 'draft_basketball_point_five_decision',
    category: _QuizCategory.tactics,
    style: _QuestionStyle.shortAnswer,
    difficulty: 2,
    subject: 'basketball tactics',
    koPrompt: '공을 받은 뒤 0.5초 안에 슛, 패스, 돌파를 빠르게 결정하는 원칙은?',
    enPrompt:
        'What principle asks a player to shoot, pass, or drive within about 0.5 seconds?',
    koAnswer: '0.5초 결정',
    enAnswer: '0.5 decision',
    koExplanationAngle: '빠른 공격은 속도 자체보다 수비가 회복하기 전 결정을 끝내는 것임을 설명한다.',
    enExplanationAngle:
        'Explain quick offense as deciding before the defense can recover.',
    koNextPointAngle: '공격 문항은 공을 오래 잡는 시간 비용을 드러내게 한다.',
    enNextPointAngle:
        'Offensive questions should reveal the cost of holding the ball.',
    koReason: '농구 전술 퀴즈를 의사결정 속도로 확장한다.',
    enReason: 'Expands basketball tactics through decision speed.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.basketballId,
    idStem: 'draft_basketball_weakside_low_man',
    conceptKey: 'draft_basketball_weakside_low_man',
    category: _QuizCategory.positions,
    style: _QuestionStyle.multipleChoice,
    difficulty: 3,
    subject: 'basketball defense',
    koPrompt: '드라이브가 들어올 때 약한 쪽 코너 수비수가 림 보호를 먼저 책임지는 역할은?',
    enPrompt:
        'On a drive, what weak-side role first protects the rim from the corner side?',
    koAnswer: '로우맨',
    enAnswer: 'low man',
    koExplanationAngle: '도움수비를 아무나 가는 것이 아니라 약한 쪽 최후방 책임으로 설명한다.',
    enExplanationAngle:
        'Explain help defense as a weak-side back-line responsibility.',
    koNextPointAngle: '수비 문항은 볼 수비자뿐 아니라 약한 쪽 책임자를 묻는다.',
    enNextPointAngle:
        'Defensive questions should ask for the weak-side responsibility too.',
    koReason: '농구 수비 퀴즈를 현대 헬프 로테이션 구조로 높인다.',
    enReason: 'Raises basketball defense content into modern help rotation.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.basketballId,
    idStem: 'draft_basketball_drop_coverage_pullup',
    conceptKey: 'draft_basketball_drop_coverage_pullup',
    category: _QuizCategory.tactics,
    style: _QuestionStyle.multipleChoice,
    difficulty: 3,
    subject: 'basketball ball-screen defense',
    koPrompt: '드롭 커버리지가 상대 볼핸들러에게 상대적으로 허용하기 쉬운 공격은?',
    enPrompt:
        'What shot can drop coverage more readily concede to a ball handler?',
    koAnswer: '미드레인지 풀업',
    enAnswer: 'mid-range pull-up',
    koExplanationAngle: '림 보호와 롤맨 제어를 얻는 대신 중간 거리 풀업 공간을 줄 수 있음을 설명한다.',
    enExplanationAngle:
        'Explain the tradeoff: rim and roll coverage can concede pull-up space.',
    koNextPointAngle: '전술 문항은 커버리지의 장점과 내주는 슛을 함께 묻는다.',
    enNextPointAngle:
        'Coverage questions should ask both what it protects and what it concedes.',
    koReason: '픽앤롤 수비를 장단점 비교형으로 만든다.',
    enReason: 'Makes pick-and-roll defense a tradeoff-based topic.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.basketballId,
    idStem: 'draft_basketball_spain_pick_roll_backscreen',
    conceptKey: 'draft_basketball_spain_pick_roll_backscreen',
    category: _QuizCategory.tactics,
    style: _QuestionStyle.ox,
    difficulty: 3,
    subject: 'basketball set play',
    koPrompt: '스페인 픽앤롤은 롤맨에게 백스크린을 더해 수비 로테이션을 흔드는 세트다. O/X',
    enPrompt:
        'Spain pick-and-roll adds a back screen for the roller to stress rotations. True/False',
    koAnswer: 'O',
    enAnswer: 'True',
    koExplanationAngle: '세트 이름보다 왜 헬프와 스위치 타이밍이 꼬이는지 설명한다.',
    enExplanationAngle:
        'Explain why the back screen disrupts help and switch timing.',
    koNextPointAngle: '세트플레이 문항은 첫 스크린 뒤의 두 번째 압박을 보게 한다.',
    enNextPointAngle:
        'Set-play questions should make the second action visible.',
    koReason: '이미 있는 핵심 키워드를 더 응용형 문항으로 확장한다.',
    enReason: 'Expands an existing core keyword into an applied draft.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.basketballId,
    idStem: 'draft_basketball_free_throw_routine_pressure',
    conceptKey: 'draft_basketball_free_throw_routine_pressure',
    category: _QuizCategory.mindset,
    style: _QuestionStyle.multipleChoice,
    difficulty: 1,
    subject: 'basketball mindset',
    koPrompt: '압박 자유투에서 루틴의 가장 큰 목적은?',
    enPrompt:
        'What is the main purpose of a free-throw routine under pressure?',
    koAnswer: '항상 같은 호흡과 시선 단서로 실행을 안정시키는 것',
    enAnswer: 'Stabilizing execution with the same breathing and visual cues',
    koExplanationAngle: '마인드 문항을 감정 억제가 아니라 반복 가능한 수행 단서로 설명한다.',
    enExplanationAngle:
        'Frame pressure management as repeatable execution cues.',
    koNextPointAngle: '루틴 문항은 성공 확률보다 흔들릴 때 돌아갈 기준을 묻는다.',
    enNextPointAngle:
        'Routine questions should ask what anchor the player returns to.',
    koReason: '농구 마인드 퀴즈를 실제 슈팅 루틴으로 구체화한다.',
    enReason:
        'Turns basketball mindset into a concrete shooting routine topic.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.basketballId,
    idStem: 'draft_basketball_transition_wall',
    conceptKey: 'draft_basketball_transition_wall',
    category: _QuizCategory.tactics,
    style: _QuestionStyle.ox,
    difficulty: 2,
    subject: 'basketball transition defense',
    koPrompt: '트랜지션 수비에서는 공만 따라가기보다 먼저 페인트 앞에 벽을 세우는 판단이 중요하다. O/X',
    enPrompt:
        'In transition defense, building a wall near the paint can matter more than chasing only the ball. True/False',
    koAnswer: 'O',
    enAnswer: 'True',
    koExplanationAngle: '속공 수비를 개인 추격이 아니라 림 우선 보호와 매치업 회복으로 설명한다.',
    enExplanationAngle:
        'Explain transition defense through rim protection and matchup recovery.',
    koNextPointAngle: '전환 수비 문항은 첫 세 걸음의 목적지를 묻게 한다.',
    enNextPointAngle:
        'Transition questions should ask where the first three steps go.',
    koReason: '농구 전환 수비를 구체적인 우선순위 문항으로 만든다.',
    enReason: 'Makes transition defense a concrete priority question.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.basketballId,
    idStem: 'draft_basketball_corner_three_shot_diet',
    conceptKey: 'draft_basketball_corner_three_shot_diet',
    category: _QuizCategory.tactics,
    style: _QuestionStyle.multipleChoice,
    difficulty: 2,
    subject: 'basketball analytics',
    koPrompt: '현대 농구에서 코너 3점이 좋은 슛으로 평가되는 주된 이유는?',
    enPrompt:
        'Why is the corner three often valued highly in modern basketball?',
    koAnswer: '거리가 짧고 킥아웃 패스로 높은 기대값을 만들기 쉽다',
    enAnswer:
        'It is shorter and often created by kick-out passes for strong value',
    koExplanationAngle: '좋은 슛을 감각이 아니라 거리, 수비 붕괴, 기대값으로 설명한다.',
    enExplanationAngle:
        'Explain shot quality through distance, defensive collapse, and value.',
    koNextPointAngle: '슛 선택 문항은 위치와 창출 과정까지 함께 묻는다.',
    enNextPointAngle:
        'Shot-selection questions should include both location and creation path.',
    koReason: '농구 퀴즈에 현대 샷 프로파일 판단을 넣는다.',
    enReason: 'Adds modern shot-profile judgment to basketball quizzes.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.basketballId,
    idStem: 'draft_basketball_zone_short_corner',
    conceptKey: 'draft_basketball_zone_short_corner',
    category: _QuizCategory.tactics,
    style: _QuestionStyle.shortAnswer,
    difficulty: 3,
    subject: 'basketball zone offense',
    koPrompt: '지역방어 뒤 공간에서 빅맨이 받아 하이로우 패스나 마무리를 노리는 지점은?',
    enPrompt:
        'What spot behind a zone lets a big catch for high-low passes or finishes?',
    koAnswer: '숏 코너',
    enAnswer: 'short corner',
    koExplanationAngle: '지역공격을 외곽 패스 반복이 아니라 뒤 공간 점유와 하이로우 연결로 설명한다.',
    enExplanationAngle:
        'Explain zone offense through occupying back spaces and high-low links.',
    koNextPointAngle: '지역방어 문항은 수비 사이 빈 지점을 찾게 한다.',
    enNextPointAngle:
        'Zone questions should ask which gap or pocket is being occupied.',
    koReason: '지역방어 공격 퀴즈의 구조적 깊이를 높인다.',
    enReason: 'Adds structural depth to zone-offense quiz drafts.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.basketballId,
    idStem: 'draft_basketball_closeout_choppy_steps',
    conceptKey: 'draft_basketball_closeout_choppy_steps',
    category: _QuizCategory.technique,
    style: _QuestionStyle.multipleChoice,
    difficulty: 2,
    subject: 'basketball closeout technique',
    koPrompt: '좋은 클로즈아웃에서 슈터에게 접근할 때 마지막 발동작의 핵심은?',
    enPrompt:
        'In a good closeout, what should the final footwork do as the defender reaches a shooter?',
    koAnswer: '잔발로 속도를 줄이고 슛과 돌파를 모두 대응할 균형을 만든다',
    enAnswer:
        'Use choppy steps to decelerate and stay balanced for shot or drive',
    koExplanationAngle: '수비 기술을 단순 전력질주가 아니라 감속과 균형 제어로 설명한다.',
    enExplanationAngle:
        'Explain defensive technique through deceleration and balance control.',
    koNextPointAngle: '기술 문항은 접근 속도와 멈추는 능력을 함께 묻게 한다.',
    enNextPointAngle:
        'Technique questions should pair approach speed with stopping ability.',
    koReason: '농구 수비 스킬 후보를 전술 후보와 균형 맞춘다.',
    enReason:
        'Balances basketball tactical drafts with defensive-skill content.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.basketballId,
    idStem: 'draft_basketball_take_foul_transition_rule',
    conceptKey: 'draft_basketball_take_foul_transition_rule',
    category: _QuizCategory.rules,
    style: _QuestionStyle.ox,
    difficulty: 2,
    subject: 'basketball rules/history',
    koPrompt: '전환 공격을 고의 파울로 끊는 행위에 대한 규칙 변화는 속공 가치를 보호하려는 목적과 연결된다. O/X',
    enPrompt:
        'Rule changes around take fouls are linked to protecting transition offense value. True/False',
    koAnswer: 'O',
    enAnswer: 'True',
    koExplanationAngle: '규칙 문항을 벌칙 암기가 아니라 리그가 보호하려는 경기 흐름으로 설명한다.',
    enExplanationAngle:
        'Explain the rule through the game flow the league is trying to protect.',
    koNextPointAngle: '규칙 변화는 어떤 플레이 스타일을 장려하는지 함께 묻게 한다.',
    enNextPointAngle:
        'Rule-change questions should ask which style of play is encouraged.',
    koReason: '농구 규칙/역사 후보를 현대 전환 공격 맥락과 연결한다.',
    enReason: 'Connects basketball rule history to modern transition context.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.basketballId,
    idStem: 'draft_basketball_back_to_back_recovery',
    conceptKey: 'draft_basketball_back_to_back_recovery',
    category: _QuizCategory.training,
    style: _QuestionStyle.multipleChoice,
    difficulty: 1,
    subject: 'basketball recovery',
    koPrompt: '백투백 경기 사이 회복 계획에서 가장 먼저 안정시켜야 할 기본 요소는?',
    enPrompt:
        'Between back-to-back games, what basic recovery element should be stabilized first?',
    koAnswer: '수면, 수분, 가벼운 이동성 회복 루틴',
    enAnswer: 'Sleep, hydration, and a light mobility recovery routine',
    koExplanationAngle: '회복을 특별한 장비보다 반복 가능한 기본 루틴과 다음 경기 준비로 설명한다.',
    enExplanationAngle:
        'Explain recovery through repeatable basics before special equipment.',
    koNextPointAngle: '훈련/회복 문항은 다음 경기 수행을 위한 우선순위를 묻는다.',
    enNextPointAngle:
        'Recovery questions should ask what priority protects the next game.',
    koReason: '농구 퀴즈에 회복/훈련 축을 추가해 종목 구성을 넓힌다.',
    enReason: 'Adds a recovery/training axis to broaden basketball coverage.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.tennisId,
    idStem: 'draft_tennis_return_depth_neutralize',
    conceptKey: 'draft_tennis_return_depth_neutralize',
    category: _QuizCategory.tactics,
    style: _QuestionStyle.multipleChoice,
    difficulty: 2,
    subject: 'tennis return',
    koPrompt: '강한 첫 서브를 받은 뒤 랠리를 중립으로 돌리는 리턴의 핵심 목표는?',
    enPrompt:
        'After a strong first serve, what is the key return goal to neutralize the rally?',
    koAnswer: '깊고 중앙성 있는 리턴으로 서버의 첫 공격 각도를 줄인다',
    enAnswer:
        'Return deep and central enough to reduce the server’s first-strike angle',
    koExplanationAngle: '리턴을 위너가 아니라 상대 첫 공격을 약화시키는 전술로 설명한다.',
    enExplanationAngle:
        'Explain the return as weakening first-strike attack, not hitting winners.',
    koNextPointAngle: '리턴 문항은 득점보다 다음 공의 위험을 줄이는 기준을 묻는다.',
    enNextPointAngle:
        'Return questions should ask how the next-ball danger is reduced.',
    koReason: '테니스 리턴 퀴즈를 전술적 중립화로 확장한다.',
    enReason: 'Expands tennis return quizzes into tactical neutralization.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.tennisId,
    idStem: 'draft_tennis_inside_out_forehand',
    conceptKey: 'draft_tennis_inside_out_forehand',
    category: _QuizCategory.tactics,
    style: _QuestionStyle.shortAnswer,
    difficulty: 2,
    subject: 'tennis pattern',
    koPrompt: '백핸드 코트로 돌아서 상대 백핸드 쪽 대각으로 치는 대표 포핸드 패턴은?',
    enPrompt:
        'What forehand pattern runs around the backhand side to hit crosscourt to the opponent’s backhand?',
    koAnswer: '인사이드 아웃 포핸드',
    enAnswer: 'inside-out forehand',
    koExplanationAngle: '샷 이름과 함께 코트 위치 이동, 주도권, 다음 열린 공간을 설명한다.',
    enExplanationAngle:
        'Explain the movement, control, and next open court created by the shot.',
    koNextPointAngle: '패턴 문항은 한 샷 뒤 열리는 다음 코스를 묻게 한다.',
    enNextPointAngle:
        'Pattern questions should ask what next court the shot opens.',
    koReason: '테니스 전술 패턴을 용어와 공간 설계로 묶는다.',
    enReason: 'Links a tennis pattern term to court-space design.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.tennisId,
    idStem: 'draft_tennis_break_point_routine',
    conceptKey: 'draft_tennis_break_point_routine',
    category: _QuizCategory.mindset,
    style: _QuestionStyle.multipleChoice,
    difficulty: 2,
    subject: 'tennis mindset',
    koPrompt: '브레이크 포인트에서 루틴이 특히 중요한 이유는?',
    enPrompt: 'Why is a routine especially useful on break point?',
    koAnswer: '점수 의미보다 첫 행동 계획에 주의를 돌려준다',
    enAnswer:
        'It shifts attention from score meaning back to the first action plan',
    koExplanationAngle: '압박 점수를 감정 문제가 아니라 주의 초점 전환 문제로 설명한다.',
    enExplanationAngle:
        'Explain pressure points as attention-control problems.',
    koNextPointAngle: '마인드 문항은 점수판보다 다음 첫 행동 단서를 묻게 한다.',
    enNextPointAngle:
        'Mindset questions should ask for the next first-action cue.',
    koReason: '테니스 마인드 퀴즈를 경기 중 루틴으로 구체화한다.',
    enReason: 'Turns tennis mindset content into an in-match routine draft.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.tennisId,
    idStem: 'draft_tennis_kick_serve_target_height',
    conceptKey: 'draft_tennis_kick_serve_target_height',
    category: _QuizCategory.technique,
    style: _QuestionStyle.ox,
    difficulty: 2,
    subject: 'tennis serve',
    koPrompt: '킥 서브는 높은 바운드로 리턴 타점을 어깨 높이까지 밀어 올리는 효과를 노릴 수 있다. O/X',
    enPrompt:
        'A kick serve can use high bounce to push the return contact toward shoulder height. True/False',
    koAnswer: 'O',
    enAnswer: 'True',
    koExplanationAngle: '서브 종류를 회전, 바운드, 리턴 타점의 연결로 설명한다.',
    enExplanationAngle:
        'Explain serve type through spin, bounce, and return contact height.',
    koNextPointAngle: '서브 기술 문항은 공이 튄 뒤 상대 타점을 묻는다.',
    enNextPointAngle:
        'Serve questions should ask what contact point the bounce creates.',
    koReason: '기존 서브 키워드를 실제 효과 중심 응용 문항으로 확장한다.',
    enReason:
        'Expands an existing serve keyword into an applied effect question.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.tennisId,
    idStem: 'draft_tennis_slice_backhand_reset',
    conceptKey: 'draft_tennis_slice_backhand_reset',
    category: _QuizCategory.technique,
    style: _QuestionStyle.multipleChoice,
    difficulty: 2,
    subject: 'tennis technique',
    koPrompt: '수비 상황에서 낮은 슬라이스 백핸드를 쓰는 전술적 목적은?',
    enPrompt:
        'What tactical purpose can a low backhand slice serve from defense?',
    koAnswer: '상대 타점을 낮추고 랠리 템포를 다시 정리한다',
    enAnswer: 'Lower the opponent’s contact point and reset the rally tempo',
    koExplanationAngle: '슬라이스를 약한 샷이 아니라 시간과 높이를 조절하는 기술로 설명한다.',
    enExplanationAngle:
        'Explain slice as controlling time and height, not merely a weak shot.',
    koNextPointAngle: '기술 문항은 샷이 상대 타점과 템포에 주는 영향을 묻는다.',
    enNextPointAngle:
        'Technique questions should ask how the shot changes contact and tempo.',
    koReason: '테니스 스킬 퀴즈를 샷 품질과 랠리 관리로 높인다.',
    enReason:
        'Raises tennis skill drafts through shot quality and rally control.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.tennisId,
    idStem: 'draft_tennis_tiebreak_risk_management',
    conceptKey: 'draft_tennis_tiebreak_risk_management',
    category: _QuizCategory.mindset,
    style: _QuestionStyle.ox,
    difficulty: 3,
    subject: 'tennis pressure',
    koPrompt: '타이브레이크에서는 모든 포인트를 무조건 위너로 끝내려는 전략이 안정적인 선택이다. O/X',
    enPrompt:
        'In a tiebreak, trying to finish every point with a winner is usually the stable choice. True/False',
    koAnswer: 'X',
    enAnswer: 'False',
    koExplanationAngle: '압박 점수에서 위험도와 자신의 확률 높은 패턴을 조절하는 관점으로 설명한다.',
    enExplanationAngle:
        'Explain pressure play through risk control and high-percentage patterns.',
    koNextPointAngle: '압박 문항은 과감함과 무리함의 경계를 묻게 한다.',
    enNextPointAngle:
        'Pressure questions should ask where aggression becomes low-percentage.',
    koReason: '테니스 마인드와 전술 판단을 함께 묻는 문항 초안이다.',
    enReason: 'Combines tennis mindset with tactical risk judgment.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.tennisId,
    idStem: 'draft_tennis_clay_grass_adaptation',
    conceptKey: 'draft_tennis_clay_grass_adaptation',
    category: _QuizCategory.tactics,
    style: _QuestionStyle.multipleChoice,
    difficulty: 3,
    subject: 'tennis history/surface',
    koPrompt: '클레이에서 잔디로 넘어갈 때 전술적으로 가장 크게 달라지는 기준은?',
    enPrompt:
        'When moving from clay to grass, what tactical standard changes most?',
    koAnswer: '바운드 높이와 포인트 길이에 맞춘 포지션과 첫 공격 타이밍',
    enAnswer:
        'Positioning and first-strike timing based on bounce height and point length',
    koExplanationAngle: '코트 역사를 표면 특성과 경기 양식 변화로 연결한다.',
    enExplanationAngle:
        'Connect surface history to bounce traits and style-of-play changes.',
    koNextPointAngle: '역사/상식 문항도 실제 포지션 선택으로 이어지게 한다.',
    enNextPointAngle:
        'Even history-style questions should lead to actual positioning choices.',
    koReason: '테니스 역사와 전술 적응을 짜임새 있게 묶는다.',
    enReason: 'Ties tennis history and tactical adaptation together.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.tennisId,
    idStem: 'draft_tennis_crosscourt_geometry',
    conceptKey: 'draft_tennis_crosscourt_geometry',
    category: _QuizCategory.tactics,
    style: _QuestionStyle.multipleChoice,
    difficulty: 2,
    subject: 'tennis rally geometry',
    koPrompt: '크로스코트 랠리가 비교적 안정적인 기본 선택이 되는 이유는?',
    enPrompt: 'Why is a crosscourt rally often a stable default pattern?',
    koAnswer: '코트 길이가 길고 네트 중앙이 낮아 실수 여지가 줄어든다',
    enAnswer:
        'The court is longer diagonally and the net is lower near the middle',
    koExplanationAngle: '샷 선택을 감각이 아니라 코트 기하와 위험 관리로 설명한다.',
    enExplanationAngle:
        'Explain shot selection through court geometry and risk management.',
    koNextPointAngle: '전술 문항은 왜 그 방향이 확률 높은지 묻는다.',
    enNextPointAngle:
        'Tactical questions should ask why the direction is higher percentage.',
    koReason: '테니스 전술 퀴즈에 코트 지형 이해를 추가한다.',
    enReason: 'Adds court-geometry understanding to tennis tactics.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.tennisId,
    idStem: 'draft_tennis_serve_landing_recovery',
    conceptKey: 'draft_tennis_serve_landing_recovery',
    category: _QuizCategory.positions,
    style: _QuestionStyle.multipleChoice,
    difficulty: 2,
    subject: 'tennis serve recovery',
    koPrompt: '서브 후 착지와 첫 회복 스텝이 중요한 이유는?',
    enPrompt:
        'Why do landing and the first recovery step matter after serving?',
    koAnswer: '다음 리턴 코스에 대응할 코트 위치를 빠르게 회복하기 위해서',
    enAnswer:
        'To recover court position quickly for the likely return direction',
    koExplanationAngle: '서브를 넣는 동작에서 끝내지 않고 다음 공을 받을 위치까지 연결한다.',
    enExplanationAngle:
        'Connect the serve action to the court position needed for the next ball.',
    koNextPointAngle: '서브 문항은 임팩트 뒤 첫 스텝까지 포함하게 한다.',
    enNextPointAngle:
        'Serve questions should include the first step after contact.',
    koReason: '테니스 포지션/회복 축을 생성 후보에 추가한다.',
    enReason:
        'Adds a positioning and recovery axis to tennis draft generation.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.tennisId,
    idStem: 'draft_tennis_changeover_hydration',
    conceptKey: 'draft_tennis_changeover_hydration',
    category: _QuizCategory.nutrition,
    style: _QuestionStyle.ox,
    difficulty: 1,
    subject: 'tennis recovery',
    koPrompt: '체인지오버의 수분 보충은 갈증이 난 뒤에만 해도 경기 후반 집중력에는 큰 영향이 없다. O/X',
    enPrompt:
        'Hydrating only after feeling thirsty on changeovers has little impact on late-match focus. True/False',
    koAnswer: 'X',
    enAnswer: 'False',
    koExplanationAngle: '영양/회복 문항을 경기 중 집중력과 반복 루틴의 관점으로 설명한다.',
    enExplanationAngle:
        'Explain hydration through in-match focus and repeatable routines.',
    koNextPointAngle: '회복 문항은 다음 게임의 집중 유지와 연결한다.',
    enNextPointAngle:
        'Recovery questions should connect to focus in the next game.',
    koReason: '테니스 퀴즈에 회복과 루틴 관리 후보를 추가한다.',
    enReason: 'Adds recovery and routine management to tennis draft coverage.',
  ),
  _QuizDraftSeedCandidate(
    sportId: SportCatalog.tennisId,
    idStem: 'draft_tennis_serve_let_rule',
    conceptKey: 'draft_tennis_serve_let_rule',
    category: _QuizCategory.rules,
    style: _QuestionStyle.multipleChoice,
    difficulty: 1,
    subject: 'tennis rules',
    koPrompt: '일반적인 테니스 경기에서 서브가 네트를 맞고 서비스 박스 안에 들어가면 보통 어떻게 처리하는가?',
    enPrompt:
        'In standard tennis, what usually happens if a serve clips the net and lands in the service box?',
    koAnswer: '렛으로 처리해 그 서브를 다시 한다',
    enAnswer: 'It is a let and the serve is replayed',
    koExplanationAngle: '규칙 문항도 단순 암기보다 다음 플레이가 어떻게 재개되는지 중심으로 설명한다.',
    enExplanationAngle:
        'Explain the rule through how play restarts, not only the term.',
    koNextPointAngle: '규칙 초안은 판정 뒤 실제 진행을 묻게 한다.',
    enNextPointAngle: 'Rule drafts should ask what happens after the call.',
    koReason: '테니스 생성 후보에 기본 규칙 축을 추가한다.',
    enReason: 'Adds a rules axis to tennis draft generation.',
  ),
];

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
        (option) => '${normalize(option.koText)}|${normalize(option.enText)}',
      )
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
    return {
      '${question.id}_${question.correctIndex}_$truthSuffix': question,
      '${question.id}_0_${question.correctIndex}_$truthSuffix': question,
    };
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
      id: 'blindside_run',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koClue: '수비수가 공만 보는 순간 등 뒤 공간으로 빠져 들어가는 움직임',
      enClue:
          'Movement into the space behind a defender when they are focused on the ball',
      acceptedAnswers: ['블라인드사이드', '블라인드 사이드', 'blindside', 'blind-side'],
      koExplain: '정답은 "블라인드사이드"입니다. 수비 시야 밖에서 출발하면 짧은 패스도 큰 찬스가 될 수 있습니다.',
      enExplain:
          'The answer is "blindside." Starting outside the defender’s view can turn a short pass into a big chance.',
      koNextPoint: '침투 전 수비수의 어깨 방향과 시선을 확인하세요.',
      enNextPoint:
          'Before running, check the defender’s shoulder angle and gaze.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'weak_side_attack',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koClue: '상대 수비 숫자가 적은 반대편 공간을 빠르게 노리는 공격',
      enClue:
          'Attack that quickly targets the far side where the defense has fewer players',
      acceptedAnswers: ['약측 공격', '약측', 'weak side', 'weak-side'],
      koExplain: '정답은 "약측 공격"입니다. 한쪽에 수비를 모은 뒤 반대편의 여유 공간을 활용합니다.',
      enExplain:
          'The answer is "weak-side attack." It uses the free space after the defense shifts toward one side.',
      koNextPoint: '볼 반대편 윙과 풀백의 위치를 계속 스캔하세요.',
      enNextPoint: 'Keep scanning the far-side winger and fullback positions.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'late_box_run',
      difficulty: 2,
      category: _QuizCategory.tactics,
      koClue: '크로스나 컷백 타이밍에 뒤에서 늦게 박스로 들어가 마무리를 노리는 움직임',
      enClue:
          'Movement of arriving late into the box for a cross or cutback finish',
      acceptedAnswers: ['늦은 침투', '박스 침투', 'late run', 'late box run'],
      koExplain: '정답은 "늦은 침투"입니다. 너무 일찍 들어가면 잡히기 쉽고, 늦게 들어가면 컷백 공간을 받을 수 있습니다.',
      enExplain:
          'The answer is "late run." Arriving too early is easy to mark; arriving late can open the cutback lane.',
      koNextPoint: '크로스 전에 페널티 스폿 뒤 공간을 한 번 확인하세요.',
      enNextPoint: 'Before the cross, check the space behind the penalty spot.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'layoff_pass',
      difficulty: 1,
      category: _QuizCategory.tactics,
      koClue: '등지고 받은 공을 가까운 동료에게 짧게 내주며 공격 방향을 이어 주는 패스',
      enClue:
          'Short pass laid back to a nearby teammate after receiving with back to goal',
      acceptedAnswers: ['레이오프', '레이오프 패스', 'layoff', 'lay-off', 'layoff pass'],
      koExplain: '정답은 "레이오프 패스"입니다. 등진 선수가 압박을 끌고, 앞을 보는 동료가 다음 전진을 선택합니다.',
      enExplain:
          'The answer is "layoff pass." The receiver draws pressure while a facing teammate chooses the next action.',
      koNextPoint: '등지고 받을 때는 원터치로 내줄 동료를 먼저 정하세요.',
      enNextPoint:
          'When receiving with your back to goal, preselect the teammate for a one-touch layoff.',
    ),
    _ShortAnswerKnowledgeSeed(
      id: 'open_body_shape',
      difficulty: 1,
      category: _QuizCategory.technique,
      koClue: '받기 전에 몸을 반쯤 열어 첫 터치 후 여러 선택지를 만드는 자세',
      enClue:
          'Receiving posture with the body half-open to keep multiple options after the first touch',
      acceptedAnswers: ['오픈 바디', '열린 자세', 'open body', 'open body shape'],
      koExplain: '정답은 "오픈 바디"입니다. 시야와 첫 터치 방향이 넓어져 압박 속에서도 선택지가 늘어납니다.',
      enExplain:
          'The answer is "open body shape." It widens vision and first-touch options under pressure.',
      koNextPoint: '받기 전 어깨 너머를 보고 첫 터치 방향을 정하세요.',
      enNextPoint:
          'Scan over your shoulder before receiving and set the first-touch direction.',
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
      id: 'activation',
      difficulty: 2,
      category: _QuizCategory.training,
      koClue: '본 훈련 전에 엉덩이와 코어, 발목 반응을 깨우는 준비 단계',
      enClue:
          'Preparation phase before the main session that wakes up the hips, core, and ankle response',
      acceptedAnswers: ['활성화', 'activation'],
      koExplain: '정답은 "활성화"입니다. 워밍업 안에서도 목표 부위를 더 선명하게 깨우는 단계입니다.',
      enExplain:
          'The answer is "activation." It is the part of warm-up that sharpens key body areas for the session.',
      koNextPoint: '훈련 목적에 맞는 활성화 루틴을 먼저 정하세요.',
      enNextPoint:
          'Choose activation work according to the goal of the session.',
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
      id: 'self_talk',
      difficulty: 2,
      category: _QuizCategory.mindset,
      koClue: '긴장되거나 실수했을 때 스스로에게 짧게 건네는 조절 문장',
      enClue:
          'Short regulating phrase a player says to themselves when tense or after a mistake',
      acceptedAnswers: ['셀프토크', 'self-talk', 'self talk'],
      koExplain: '정답은 "셀프토크"입니다. 짧은 문장이 집중과 감정 조절을 돕습니다.',
      enExplain:
          'The answer is "self-talk." Short phrases can support focus and emotional control.',
      koNextPoint: '경기 중 바로 쓸 수 있는 한 문장 셀프토크를 정하세요.',
      enNextPoint:
          'Prepare one self-talk sentence you can use immediately in matches.',
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
      id: 'protein',
      difficulty: 1,
      category: _QuizCategory.nutrition,
      koClue: '훈련 후 근육 회복과 조직 재건에 특히 중요한 영양소',
      enClue:
          'Nutrient especially important after training for muscle recovery and tissue repair',
      acceptedAnswers: ['단백질', 'protein'],
      koExplain: '정답은 "단백질"입니다. 회복 식단에서 탄수화물과 함께 자주 고려됩니다.',
      enExplain:
          'The answer is "protein." It is often planned together with carbohydrates in recovery meals.',
      koNextPoint: '회복 식사는 에너지와 조직 회복을 함께 생각하세요.',
      enNextPoint:
          'Think about restoring energy and rebuilding tissue together in recovery meals.',
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
      id: 'cooldown_recovery_bridge',
      difficulty: 1,
      category: _QuizCategory.training,
      koTrueStatement: '쿨다운은 훈련을 갑자기 끝내기보다 회복 단계로 부드럽게 넘어가게 돕는다.',
      enTrueStatement:
          'A cool-down helps the player move smoothly into recovery instead of stopping abruptly.',
      koFalseStatement: '쿨다운은 회복과 큰 관련이 없어서 강한 훈련 직후 바로 끝내도 항상 같다.',
      enFalseStatement:
          'A cool-down has little to do with recovery, so finishing immediately after hard work is always the same.',
      koExplain: '쿨다운은 강도 하강과 회복 루틴 연결에 의미가 있습니다.',
      enExplain:
          'A cool-down matters because it lowers intensity and links the session to recovery habits.',
      koNextPoint: '훈련 종료 루틴도 세션 설계의 일부로 본다.',
      enNextPoint:
          'Treat the end-of-session routine as part of session design.',
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
      id: 'protein_repair',
      difficulty: 1,
      category: _QuizCategory.nutrition,
      koTrueStatement: '단백질은 훈련 후 근육 회복과 조직 재건에 도움을 줄 수 있다.',
      enTrueStatement:
          'Protein can help muscle recovery and tissue repair after training.',
      koFalseStatement: '단백질은 축구 선수의 회복과 거의 관련이 없고 오직 경기 전 흥분만 높인다.',
      enFalseStatement:
          'Protein has almost nothing to do with recovery for football players and only raises excitement before matches.',
      koExplain: '단백질은 회복 식사에서 중요한 축 중 하나입니다.',
      enExplain: 'Protein is one of the important pillars of a recovery meal.',
      koNextPoint: '회복 영양은 탄수화물과 단백질의 역할을 나눠서 이해한다.',
      enNextPoint:
          'Understand recovery nutrition by separating the roles of carbohydrates and protein.',
    ),
    _OxFactSeed(
      id: 'self_talk_focus',
      difficulty: 2,
      category: _QuizCategory.mindset,
      koTrueStatement: '짧고 긍정적인 셀프토크는 긴장 상황에서 집중 회복에 도움이 될 수 있다.',
      enTrueStatement:
          'Short positive self-talk can help restore focus in tense situations.',
      koFalseStatement: '셀프토크는 경기 집중과 무관해서 오히려 생각을 완전히 멈추는 편이 항상 낫다.',
      enFalseStatement:
          'Self-talk is unrelated to match focus, so it is always better to stop thinking entirely.',
      koExplain: '짧은 자기 대화는 주의를 다시 현재 과제로 돌리는 데 도움이 됩니다.',
      enExplain:
          'Brief self-talk can help bring attention back to the present task.',
      koNextPoint: '셀프토크는 길게 설명하기보다 짧고 실행 가능해야 한다.',
      enNextPoint:
          'Self-talk should stay short and actionable rather than long and complex.',
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
      id: 'small_sided_game_value',
      difficulty: 2,
      category: _QuizCategory.training,
      koStem: '스몰사이드 게임 훈련의 대표 장점으로 가장 알맞은 것은?',
      enStem:
          'Which answer best describes a typical benefit of small-sided games?',
      options: [
        _FootballQuizOption(
          koText: '반복적인 의사결정과 볼 관여를 늘리기',
          enText: 'Increasing repeated decision-making and ball involvement',
        ),
        _FootballQuizOption(
          koText: '공을 거의 만지지 않게 만들기',
          enText: 'Making players barely touch the ball',
        ),
        _FootballQuizOption(
          koText: '항상 걷기만 하게 만들기',
          enText: 'Making players only walk all the time',
        ),
        _FootballQuizOption(
          koText: '규칙을 전부 없애기',
          enText: 'Removing all rules completely',
        ),
      ],
      correctIndex: 0,
      koExplain: '스몰사이드 게임은 접촉 횟수와 판단 빈도를 높여 실전 연결에 도움이 됩니다.',
      enExplain:
          'Small-sided games raise touch frequency and decision repetition, helping transfer to real play.',
      koNextPoint: '훈련 형식은 경기 장면을 얼마나 재현하는지 함께 본다.',
      enNextPoint:
          'Judge training formats by how well they reproduce match moments.',
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
      id: 'breathing_reset',
      difficulty: 1,
      category: _QuizCategory.mindset,
      koStem: '긴장으로 호흡이 급해졌을 때 가장 도움이 되는 반응은?',
      enStem:
          'When tension makes breathing too rushed, which response helps most?',
      options: [
        _FootballQuizOption(
          koText: '짧게 호흡을 정리하고 다음 과제 한 가지에 집중하기',
          enText: 'Reset the breath briefly and focus on one next task',
        ),
        _FootballQuizOption(
          koText: '더 급하게 뛰기만 하기',
          enText: 'Only run even more frantically',
        ),
        _FootballQuizOption(
          koText: '실수 장면만 계속 떠올리기',
          enText: 'Keep replaying the mistake only',
        ),
        _FootballQuizOption(
          koText: '동료와 언쟁부터 하기',
          enText: 'Start arguing with teammates first',
        ),
      ],
      correctIndex: 0,
      koExplain: '호흡과 주의 초점을 짧게 정리하면 다음 플레이 복귀가 빨라집니다.',
      enExplain:
          'A brief breathing reset and narrowed focus can speed up the return to the next play.',
      koNextPoint: '감정 조절은 몸 반응과 다음 행동을 함께 다룬다.',
      enNextPoint:
          'Emotional control should address both body response and next action.',
    ),
    _McqSeed(
      id: 'controllables_focus',
      difficulty: 2,
      category: _QuizCategory.mindset,
      koStem: '경기 중 마인드 관리에서 가장 우선해서 붙잡아야 할 대상은?',
      enStem: 'In match mindset management, what should be prioritized first?',
      options: [
        _FootballQuizOption(
          koText: '내가 통제할 수 있는 다음 행동',
          enText: 'The next action I can control',
        ),
        _FootballQuizOption(
          koText: '이미 지난 판정',
          enText: 'A refereeing decision that is already over',
        ),
        _FootballQuizOption(
          koText: '관중 반응 전체',
          enText: 'The entire crowd reaction',
        ),
        _FootballQuizOption(
          koText: '상대의 감정 상태 추측',
          enText: 'Guessing the opponent’s emotional state',
        ),
      ],
      correctIndex: 0,
      koExplain: '통제 가능한 행동에 집중해야 실행력이 다시 살아납니다.',
      enExplain: 'Focusing on controllable action is what restores execution.',
      koNextPoint: '마인드 루틴은 감정보다 행동 단서 중심으로 만든다.',
      enNextPoint:
          'Build mindset routines around action cues rather than raw emotion.',
    ),
    _McqSeed(
      id: 'recovery_meal_balance',
      difficulty: 2,
      category: _QuizCategory.nutrition,
      koStem: '강한 훈련 뒤 회복 식사 방향으로 가장 알맞은 것은?',
      enStem:
          'Which option best matches a recovery meal direction after a hard session?',
      options: [
        _FootballQuizOption(
          koText: '탄수화물과 단백질, 수분을 함께 고려하기',
          enText: 'Considering carbohydrates, protein, and fluids together',
        ),
        _FootballQuizOption(
          koText: '아무것도 먹지 않고 오래 버티기',
          enText: 'Eating nothing and waiting a long time',
        ),
        _FootballQuizOption(koText: '탄산음료만 마시기', enText: 'Drinking only soda'),
        _FootballQuizOption(
          koText: '다음 날까지 수분을 끊기',
          enText: 'Avoiding fluids until the next day',
        ),
      ],
      correctIndex: 0,
      koExplain: '회복 식사는 에너지 보충, 조직 회복, 수분 회복을 함께 봐야 합니다.',
      enExplain:
          'Recovery meals should cover energy restoration, tissue repair, and fluid replacement together.',
      koNextPoint: '회복은 한 가지 영양소가 아니라 전체 루틴으로 관리한다.',
      enNextPoint:
          'Manage recovery as a full routine, not as a single nutrient only.',
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
