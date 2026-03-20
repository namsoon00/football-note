import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../application/player_level_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/app_feedback.dart';
import '../widgets/level_up_dialog.dart';

class SkillQuizScreen extends StatefulWidget {
  final OptionRepository optionRepository;
  static const String completionKey = 'skill_quiz_completed_at';
  static const String sessionKey = 'skill_quiz_session_v1';
  static const String pendingWrongQuestionsKey = 'skill_quiz_pending_wrong_v1';
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
    final pendingWrongQuestions = _QuizQuestionSnapshot.decodeList(
      optionRepository.getValue<String>(pendingWrongQuestionsKey),
    );
    return SkillQuizResumeSummary(
      hasActiveSession: session != null,
      reviewMode: session?.reviewMode ?? false,
      currentIndex: session?.index ?? 0,
      totalQuestions: session?.questions.length ?? 0,
      pendingWrongCount: pendingWrongQuestions.length,
    );
  }

  @override
  State<SkillQuizScreen> createState() => _SkillQuizScreenState();
}

class _SkillQuizScreenState extends State<SkillQuizScreen> {
  static const int _dailyQuestionCount = 20;

  late final List<_QuizQuestion> _mixedPool;
  late List<_QuizQuestion> _dailyQuestions;
  late List<_QuizQuestion> _questions;
  bool _reviewMode = false;
  String _sessionSource = _QuizSessionSource.today.name;

  int _index = 0;
  int _score = 0;
  int? _selectedIndex;
  bool _answered = false;
  bool _retryUsed = false;
  String? _retryFeedback;
  final Set<String> _wrongIds = <String>{};
  bool _completionRecorded = false;
  PlayerLevelAward? _quizAward;

  bool get _isFinished => _index >= _questions.length;

  @override
  void initState() {
    super.initState();
    _mixedPool = _buildMixedQuizPool();
    _dailyQuestions = _loadOrCreateTodayQuestions();
    _restoreOrStartSession();
  }

  void _restoreOrStartSession() {
    final restored = _QuizSessionSnapshot.tryParse(
      widget.optionRepository.getValue<String>(SkillQuizScreen.sessionKey),
    );
    if (restored != null) {
      _applySession(restored);
      return;
    }

    final pendingWrongQuestions = _QuizQuestionSnapshot.decodeList(
      widget.optionRepository.getValue<String>(
        SkillQuizScreen.pendingWrongQuestionsKey,
      ),
    );
    if (pendingWrongQuestions.isNotEmpty) {
      _startQuestionSession(
        questions: pendingWrongQuestions,
        reviewMode: true,
        sessionSource: _QuizSessionSource.review.name,
        clearPendingWrongQuestions: false,
        shouldNotify: false,
      );
      return;
    }

    _startTodaySession(shouldNotify: false);
  }

  void _applySession(_QuizSessionSnapshot session) {
    _dailyQuestions = session.dailyQuestions;
    _questions = session.questions;
    _reviewMode = session.reviewMode;
    _sessionSource = session.sessionSource;
    _index = session.index.clamp(0, session.questions.length);
    _score = session.score;
    _selectedIndex = session.selectedIndex;
    _answered = session.answered;
    _retryUsed = session.retryUsed;
    _retryFeedback = session.retryFeedback;
    _wrongIds
      ..clear()
      ..addAll(session.wrongIds);
  }

  void _startTodaySession({bool shouldNotify = true}) {
    _dailyQuestions = _loadOrCreateTodayQuestions();
    _startQuestionSession(
      questions: _dailyQuestions,
      reviewMode: false,
      sessionSource: _QuizSessionSource.today.name,
      clearPendingWrongQuestions: false,
      shouldNotify: shouldNotify,
    );
  }

  void _startRandomMixedSession({bool shouldNotify = true}) {
    final random = math.Random(DateTime.now().microsecondsSinceEpoch);
    final picked = [..._mixedPool]..shuffle(random);
    final selected = picked
        .take(math.min(_dailyQuestionCount, picked.length))
        .map((question) => _shuffleQuestionOptions(question, random))
        .toList(growable: false);

    _startQuestionSession(
      questions: selected,
      reviewMode: false,
      sessionSource: _QuizSessionSource.random.name,
      clearPendingWrongQuestions: false,
      shouldNotify: shouldNotify,
    );
  }

  void _startQuestionSession({
    required List<_QuizQuestion> questions,
    required bool reviewMode,
    required String sessionSource,
    required bool clearPendingWrongQuestions,
    required bool shouldNotify,
  }) {
    void apply() {
      if (!reviewMode && sessionSource == _QuizSessionSource.today.name) {
        _dailyQuestions = questions;
      }
      _questions = questions;
      _reviewMode = reviewMode;
      _sessionSource = sessionSource;
      _index = 0;
      _score = 0;
      _selectedIndex = null;
      _answered = false;
      _retryUsed = false;
      _retryFeedback = null;
      _wrongIds.clear();
    }

    if (shouldNotify) {
      setState(apply);
    } else {
      apply();
    }
    if (clearPendingWrongQuestions) {
      unawaited(_persistPendingWrongQuestions(const <_QuizQuestion>[]));
    }
    unawaited(_persistSession());
  }

  void _selectAnswer(int choice) {
    if (_isFinished || _answered) return;
    final question = _questions[_index];
    final isCorrect = choice == question.correctIndex;
    setState(() {
      _selectedIndex = choice;
      if (isCorrect) {
        _answered = true;
        _score++;
        _retryFeedback = null;
      } else if (!_retryUsed) {
        _retryUsed = true;
        _retryFeedback = 'incorrect';
      } else {
        _answered = true;
        _wrongIds.add(question.id);
        _retryFeedback = null;
      }
    });
    unawaited(_persistSession());
  }

  void _next() {
    if (!_answered) return;
    var didFinish = false;
    setState(() {
      _index++;
      _selectedIndex = null;
      _answered = false;
      _retryUsed = false;
      _retryFeedback = null;
      didFinish = _index >= _questions.length;
    });
    if (didFinish) {
      unawaited(_completeCurrentSession());
      return;
    }
    unawaited(_persistSession());
  }

  Future<void> _completeCurrentSession() async {
    final wrongQuestions = _questions
        .where((question) => _wrongIds.contains(question.id))
        .toList(growable: false);
    await _persistPendingWrongQuestions(wrongQuestions);
    if (!_reviewMode) {
      await _persistClearedSet(
        _ClearedQuizSet(
          completedAt: DateTime.now(),
          source: _sessionSource,
          questions: _questions,
        ),
      );
    }
    await widget.optionRepository.setValue(SkillQuizScreen.sessionKey, '');
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return Scaffold(
      appBar: AppBar(
        title: Text(isKo ? '실전 퀴즈' : 'Match Quiz'),
        actions: [
          IconButton(
            tooltip: isKo ? '퀴즈 세트 메뉴' : 'Quiz set menu',
            onPressed: _openQuizSetMenu,
            icon: const Icon(Icons.tune_outlined),
          ),
          IconButton(
            tooltip: isKo ? '클리어 세트 기록' : 'Cleared set history',
            onPressed: _openClearedHistory,
            icon: const Icon(Icons.history_outlined),
          ),
        ],
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
              : (_sessionSource == _QuizSessionSource.today.name
                    ? (isKo
                          ? '오늘의 퀴즈 · 진행 $progress'
                          : 'Daily quiz · $progress')
                    : _sessionSource == _QuizSessionSource.history.name
                    ? (isKo
                          ? '클리어 세트 다시 풀기 · 진행 $progress'
                          : 'Replay cleared set · $progress')
                    : (isKo
                          ? '추가 랜덤 세트 · 진행 $progress'
                          : 'Bonus random set · $progress')),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          isKo
              ? '혼합 문제풀 ${_mixedPool.length}개 · 이번 세트 ${_dailyQuestions.length}개'
              : 'Mixed pool ${_mixedPool.length} · this set ${_dailyQuestions.length}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        if (question.scenario != null) ...[
          _QuizScenarioCard(question: question, isKo: isKo),
          const SizedBox(height: 10),
        ],
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
            child: OutlinedButton(
              onPressed: () => _selectAnswer(optionIndex),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                side: BorderSide(
                  color:
                      borderColor ??
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
                  if ((_answered || _retryUsed) && selected && !isCorrect)
                    const Icon(Icons.cancel, color: Color(0xFFEB5757)),
                ],
              ),
            ),
          );
        }),
        if (!_answered && _retryFeedback == 'incorrect') ...[
          const SizedBox(height: 2),
          Text(
            isKo
                ? '틀렸어요. 다시 한 번 풀어보세요.'
                : 'Incorrect. Try this question one more time.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFFEB5757),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
    if (!_completionRecorded) {
      _completionRecorded = true;
      unawaited(_recordCompletionReward());
    }
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
                      : (_sessionSource == _QuizSessionSource.today.name
                            ? (isKo ? '오늘의 퀴즈 결과' : 'Daily Quiz Result')
                            : _sessionSource == _QuizSessionSource.history.name
                            ? (isKo ? '클리어 세트 재도전 결과' : 'Replay Result')
                            : (isKo ? '추가 세트 결과' : 'Bonus Set Result')),
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
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
                if (wrongCount > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    isKo
                        ? '오답은 복습 목록에 저장됩니다. 다음에 열면 먼저 다시 풀게 됩니다.'
                        : 'Wrong answers are saved for later review and will open first next time.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (_quizAward != null && _quizAward!.gainedXp > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _quizAward!.didLevelUp
                          ? (isKo
                                ? '+${_quizAward!.gainedXp} XP · Lv.${_quizAward!.after.level} ${PlayerLevelService.levelName(_quizAward!.after.level, true)} 달성'
                                : '+${_quizAward!.gainedXp} XP · Reached Lv.${_quizAward!.after.level} ${PlayerLevelService.levelName(_quizAward!.after.level, false)}')
                          : (isKo
                                ? '+${_quizAward!.gainedXp} XP 획득'
                                : '+${_quizAward!.gainedXp} XP earned'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  isKo ? '퀴즈 세트' : 'Quiz set',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _startTodaySession,
                  icon: const Icon(Icons.today_outlined),
                  label: Text(isKo ? '오늘 퀴즈 다시 풀기' : 'Replay today quiz'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: wrongCount == 0
                      ? null
                      : () => _startQuestionSession(
                          questions: _questions
                              .where(
                                (question) => _wrongIds.contains(question.id),
                              )
                              .toList(growable: false),
                          reviewMode: true,
                          sessionSource: _QuizSessionSource.review.name,
                          clearPendingWrongQuestions: false,
                          shouldNotify: true,
                        ),
                  icon: const Icon(Icons.rule_folder_outlined),
                  label: Text(
                    isKo ? '이번 오답 바로 복습' : 'Review wrong answers now',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _startRandomMixedSession,
                  icon: const Icon(Icons.casino_outlined),
                  label: Text(isKo ? '추가 랜덤 세트 받기' : 'Get another random set'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _openClearedHistory,
                  icon: const Icon(Icons.history_outlined),
                  label: Text(isKo ? '클리어 세트 다시 풀기' : 'Replay cleared sets'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _recordCompletionReward() async {
    final completedAt = DateTime.now();
    await widget.optionRepository.setValue(
      SkillQuizScreen.completionKey,
      completedAt.toIso8601String(),
    );
    final award = await PlayerLevelService(
      widget.optionRepository,
    ).awardForQuizCompletion(completedAt: completedAt);
    if (!mounted) return;
    setState(() => _quizAward = award);
    if (award.gainedXp <= 0) return;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    AppFeedback.showSuccess(
      context,
      text: award.didLevelUp
          ? (isKo
                ? '+${award.gainedXp} XP · Lv.${award.after.level} ${PlayerLevelService.levelName(award.after.level, true)} 달성'
                : '+${award.gainedXp} XP · Reached Lv.${award.after.level} ${PlayerLevelService.levelName(award.after.level, false)}')
          : (isKo
                ? '+${award.gainedXp} XP 획득'
                : '+${award.gainedXp} XP earned'),
    );
    if (!award.didLevelUp) return;
    final customRewardName = PlayerLevelService(
      widget.optionRepository,
    ).customRewardNameForLevel(award.after.level);
    await showLevelUpCelebrationDialog(
      context,
      award: award,
      isKo: isKo,
      customRewardName: customRewardName,
      onClaimReward: () async {
        final claim = await PlayerLevelService(
          widget.optionRepository,
        ).claimRewardForLevel(award.after.level);
        if (!mounted || claim == null) return;
        final rewardName = claim.customRewardName.trim().isNotEmpty
            ? claim.customRewardName
            : (isKo ? claim.reward.nameKo : claim.reward.nameEn);
        AppFeedback.showSuccess(
          context,
          text: isKo ? '$rewardName 선물을 받았어요.' : 'Claimed $rewardName.',
        );
      },
    );
  }

  Future<void> _persistSession() async {
    if (_isFinished) {
      await widget.optionRepository.setValue(SkillQuizScreen.sessionKey, '');
      return;
    }
    final snapshot = _QuizSessionSnapshot(
      reviewMode: _reviewMode,
      dailyQuestions: _dailyQuestions,
      questions: _questions,
      index: _index,
      score: _score,
      selectedIndex: _selectedIndex,
      answered: _answered,
      retryUsed: _retryUsed,
      retryFeedback: _retryFeedback,
      sessionSource: _sessionSource,
      wrongIds: _wrongIds.toList(growable: false),
    );
    await widget.optionRepository.setValue(
      SkillQuizScreen.sessionKey,
      snapshot.encode(),
    );
  }

  Future<void> _persistPendingWrongQuestions(
    List<_QuizQuestion> questions,
  ) async {
    await widget.optionRepository.setValue(
      SkillQuizScreen.pendingWrongQuestionsKey,
      _QuizQuestionSnapshot.encodeList(questions),
    );
  }

  List<_QuizQuestion> _loadOrCreateTodayQuestions() {
    final todayToken = _todayToken();
    final savedToken = widget.optionRepository.getValue<String>(
      SkillQuizScreen.dailyQuestionsDayKey,
    );
    if (savedToken == todayToken) {
      final stored = _QuizQuestionSnapshot.decodeList(
        widget.optionRepository.getValue<String>(
          SkillQuizScreen.dailyQuestionsKey,
        ),
      );
      if (stored.isNotEmpty) return stored;
    }
    final selected = _selectDailyQuestions(todayToken);
    unawaited(
      widget.optionRepository.setValue(
        SkillQuizScreen.dailyQuestionsDayKey,
        todayToken,
      ),
    );
    unawaited(
      widget.optionRepository.setValue(
        SkillQuizScreen.dailyQuestionsKey,
        _QuizQuestionSnapshot.encodeList(selected),
      ),
    );
    return selected;
  }

  List<_QuizQuestion> _selectDailyQuestions(String token) {
    final random = math.Random(_stableHash(token));
    final picked = [..._mixedPool]..shuffle(random);
    return picked
        .take(math.min(_dailyQuestionCount, picked.length))
        .map((question) => _shuffleQuestionOptions(question, random))
        .toList(growable: false);
  }

  String _todayToken() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  List<_ClearedQuizSet> _loadClearedSets() {
    return _ClearedQuizSet.decodeList(
      widget.optionRepository.getValue<String>(SkillQuizScreen.clearedSetsKey),
    );
  }

  Future<void> _persistClearedSet(_ClearedQuizSet set) async {
    final sets = _loadClearedSets();
    final deduped = sets
        .where((item) {
          final sameTime = item.completedAt == set.completedAt;
          final sameQuestions =
              item.questions.map((question) => question.id).join(',') ==
              set.questions.map((question) => question.id).join(',');
          return !(sameTime || sameQuestions);
        })
        .toList(growable: true);
    deduped.insert(0, set);
    await widget.optionRepository.setValue(
      SkillQuizScreen.clearedSetsKey,
      _ClearedQuizSet.encodeList(deduped.take(12).toList(growable: false)),
    );
  }

  Future<void> _openQuizSetMenu() async {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.today_outlined),
              title: Text(isKo ? '오늘 퀴즈 시작' : 'Start today quiz'),
              subtitle: Text(
                isKo ? '매일 고정 세트로 실력을 쌓아요.' : 'Use the fixed daily set.',
              ),
              onTap: () => Navigator.of(context).pop('today'),
            ),
            ListTile(
              leading: const Icon(Icons.rule_folder_outlined),
              title: Text(isKo ? '오답 복습' : 'Wrong-answer review'),
              subtitle: Text(
                isKo ? '이전에 틀린 문제를 다시 풉니다.' : 'Retry saved wrong answers.',
              ),
              onTap: () => Navigator.of(context).pop('wrong'),
            ),
            ListTile(
              leading: const Icon(Icons.casino_outlined),
              title: Text(isKo ? '추가 랜덤 세트' : 'Bonus random set'),
              subtitle: Text(
                isKo ? '오늘 세트 외에 더 풀어봅니다.' : 'Get extra mixed questions.',
              ),
              onTap: () => Navigator.of(context).pop('random'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || selected == null) return;
    if (selected == 'today') {
      _startTodaySession();
      return;
    }
    if (selected == 'random') {
      _startRandomMixedSession();
      return;
    }
    final wrongQuestions = _QuizQuestionSnapshot.decodeList(
      widget.optionRepository.getValue<String>(
        SkillQuizScreen.pendingWrongQuestionsKey,
      ),
    );
    if (wrongQuestions.isEmpty) return;
    _startQuestionSession(
      questions: wrongQuestions,
      reviewMode: true,
      sessionSource: _QuizSessionSource.review.name,
      clearPendingWrongQuestions: false,
      shouldNotify: true,
    );
  }

  Future<void> _openClearedHistory() async {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final sets = _loadClearedSets();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isKo ? '클리어 세트 다시 풀기' : 'Replay cleared sets',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              if (sets.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    isKo ? '아직 저장된 클리어 세트가 없어요.' : 'No cleared sets saved yet.',
                  ),
                ),
              ...sets.map((set) {
                final label = _formatClearedSetLabel(set, isKo);
                return Card(
                  child: ListTile(
                    leading: Icon(
                      set.source == _QuizSessionSource.today.name
                          ? Icons.today_outlined
                          : Icons.history_toggle_off_outlined,
                    ),
                    title: Text(label),
                    subtitle: Text(
                      isKo
                          ? '${set.questions.length}문제'
                          : '${set.questions.length} questions',
                    ),
                    trailing: const Icon(Icons.play_arrow_outlined),
                    onTap: () {
                      Navigator.of(context).pop();
                      _startQuestionSession(
                        questions: set.questions,
                        reviewMode: false,
                        sessionSource: _QuizSessionSource.history.name,
                        clearPendingWrongQuestions: false,
                        shouldNotify: true,
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _formatClearedSetLabel(_ClearedQuizSet set, bool isKo) {
    final dateLabel = '${set.completedAt.month}/${set.completedAt.day}';
    switch (set.source) {
      case 'today':
        return isKo ? '$dateLabel 오늘 퀴즈 세트' : '$dateLabel daily quiz set';
      case 'random':
        return isKo ? '$dateLabel 추가 랜덤 세트' : '$dateLabel bonus random set';
      default:
        return isKo ? '$dateLabel 저장 세트' : '$dateLabel saved set';
    }
  }
}

class _QuizScenarioCard extends StatefulWidget {
  final _QuizQuestion question;
  final bool isKo;

  const _QuizScenarioCard({required this.question, required this.isKo});

  @override
  State<_QuizScenarioCard> createState() => _QuizScenarioCardState();
}

class _QuizScenarioCardState extends State<_QuizScenarioCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.question.scenario?.hasMotion == true) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _QuizScenarioCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasMotion = widget.question.scenario?.hasMotion == true;
    if (hasMotion) {
      if (!_controller.isAnimating) {
        _controller
          ..value = 0
          ..repeat(reverse: true);
      }
    } else {
      _controller
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scenario = widget.question.scenario!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isKo ? scenario.koTitle : scenario.enTitle,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            AspectRatio(
              aspectRatio: 1.55,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  painter: _PitchScenarioPainter(
                    scenario: scenario,
                    motionProgress: _controller.value,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            if (scenario.hasMotion) ...[
              const SizedBox(height: 10),
              Text(
                widget.isKo
                    ? scenario.koMovementCaption ?? ''
                    : scenario.enMovementCaption ?? '',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PitchScenarioPainter extends CustomPainter {
  final _QuizScenario scenario;
  final double motionProgress;

  const _PitchScenarioPainter({
    required this.scenario,
    required this.motionProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fieldRect = Offset.zero & size;
    final fieldPaint = Paint()..color = const Color(0xFF2F7D4E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(fieldRect, const Radius.circular(18)),
      fieldPaint,
    );
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(fieldRect.deflate(8), const Radius.circular(14)),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width / 2, 8),
      Offset(size.width / 2, size.height - 8),
      linePaint,
    );
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 24, linePaint);
    final lanePaint = Paint()
      ..color = const Color(0x66FFD54F)
      ..style = PaintingStyle.fill;
    if (scenario.highlightedLane == 'left-half') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.22,
            8,
            size.width * 0.16,
            size.height - 16,
          ),
          const Radius.circular(14),
        ),
        lanePaint,
      );
    } else if (scenario.highlightedLane == 'right-half') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.62,
            8,
            size.width * 0.16,
            size.height - 16,
          ),
          const Radius.circular(14),
        ),
        lanePaint,
      );
    } else if (scenario.highlightedLane == 'center') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.42,
            8,
            size.width * 0.16,
            size.height - 16,
          ),
          const Radius.circular(14),
        ),
        lanePaint,
      );
    }

    Offset scale(Offset point) =>
        Offset(point.dx * size.width, point.dy * size.height);

    void drawMovementArrow(Offset from, Offset to, Color color) {
      final start = scale(from);
      final end = scale(to);
      final arrowPaint = Paint()
        ..color = color.withValues(alpha: 0.55)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, arrowPaint);
      final direction = end - start;
      if (direction.distance < 8) return;
      final unit = direction / direction.distance;
      final wing = Offset(-unit.dy, unit.dx);
      final arrowA = end - unit * 12 + wing * 6;
      final arrowB = end - unit * 12 - wing * 6;
      canvas.drawLine(end, arrowA, arrowPaint);
      canvas.drawLine(end, arrowB, arrowPaint);
    }

    Offset interpolate(Offset base, Offset? target) {
      if (target == null) return base;
      return Offset.lerp(base, target, motionProgress) ?? base;
    }

    void drawPlayer(Offset point, Color color) {
      final center = scale(point);
      canvas.drawCircle(center, 11, Paint()..color = color);
      canvas.drawCircle(center, 11, linePaint);
    }

    for (var i = 0; i < scenario.attackPoints.length; i++) {
      final base = scenario.attackPoints[i];
      final target =
          scenario.attackMoveTargets != null &&
              i < scenario.attackMoveTargets!.length
          ? scenario.attackMoveTargets![i]
          : null;
      if (target != null) {
        drawMovementArrow(base, target, const Color(0xFFB3E5FC));
      }
      drawPlayer(interpolate(base, target), const Color(0xFF5EC8FF));
    }
    for (var i = 0; i < scenario.defendPoints.length; i++) {
      final base = scenario.defendPoints[i];
      final target =
          scenario.defendMoveTargets != null &&
              i < scenario.defendMoveTargets!.length
          ? scenario.defendMoveTargets![i]
          : null;
      if (target != null) {
        drawMovementArrow(base, target, const Color(0xFFFFCCBC));
      }
      drawPlayer(interpolate(base, target), const Color(0xFFFF8A65));
    }
    if (scenario.ballMoveTarget != null) {
      drawMovementArrow(
        scenario.ballPoint,
        scenario.ballMoveTarget!,
        const Color(0xFFFFF59D),
      );
    }
    final ballPoint = interpolate(scenario.ballPoint, scenario.ballMoveTarget);
    final ballCenter = scale(ballPoint);
    canvas.drawCircle(ballCenter, 7, Paint()..color = const Color(0xFFFFF3E0));
    canvas.drawCircle(ballCenter, 7, linePaint);
  }

  @override
  bool shouldRepaint(covariant _PitchScenarioPainter oldDelegate) {
    return oldDelegate.scenario != scenario ||
        oldDelegate.motionProgress != motionProgress;
  }
}

class SkillQuizResumeSummary {
  final bool hasActiveSession;
  final bool reviewMode;
  final int currentIndex;
  final int totalQuestions;
  final int pendingWrongCount;

  const SkillQuizResumeSummary({
    required this.hasActiveSession,
    required this.reviewMode,
    required this.currentIndex,
    required this.totalQuestions,
    required this.pendingWrongCount,
  });
}

class _QuizSessionSnapshot {
  final bool reviewMode;
  final List<_QuizQuestion> dailyQuestions;
  final List<_QuizQuestion> questions;
  final String sessionSource;
  final int index;
  final int score;
  final int? selectedIndex;
  final bool answered;
  final bool retryUsed;
  final String? retryFeedback;
  final List<String> wrongIds;

  const _QuizSessionSnapshot({
    required this.reviewMode,
    required this.dailyQuestions,
    required this.questions,
    required this.sessionSource,
    required this.index,
    required this.score,
    required this.selectedIndex,
    required this.answered,
    required this.retryUsed,
    required this.retryFeedback,
    required this.wrongIds,
  });

  String encode() {
    return jsonEncode(<String, dynamic>{
      'reviewMode': reviewMode,
      'dailyQuestions': dailyQuestions
          .map(_QuizQuestionSnapshot.fromQuestion)
          .map((item) => item.toMap())
          .toList(growable: false),
      'questions': questions
          .map(_QuizQuestionSnapshot.fromQuestion)
          .map((item) => item.toMap())
          .toList(growable: false),
      'sessionSource': sessionSource,
      'index': index,
      'score': score,
      'selectedIndex': selectedIndex,
      'answered': answered,
      'retryUsed': retryUsed,
      'retryFeedback': retryFeedback,
      'wrongIds': wrongIds,
    });
  }

  static _QuizSessionSnapshot? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final dailyQuestions = _QuizQuestionSnapshot.fromDynamicList(
        decoded['dailyQuestions'],
      );
      final questions = _QuizQuestionSnapshot.fromDynamicList(
        decoded['questions'],
      );
      if (questions.isEmpty) return null;
      return _QuizSessionSnapshot(
        reviewMode: decoded['reviewMode'] == true,
        dailyQuestions: dailyQuestions.isEmpty ? questions : dailyQuestions,
        questions: questions,
        sessionSource:
            decoded['sessionSource']?.toString() ??
            _QuizSessionSource.today.name,
        index: (decoded['index'] as num?)?.toInt() ?? 0,
        score: (decoded['score'] as num?)?.toInt() ?? 0,
        selectedIndex: (decoded['selectedIndex'] as num?)?.toInt(),
        answered: decoded['answered'] == true,
        retryUsed: decoded['retryUsed'] == true,
        retryFeedback: decoded['retryFeedback']?.toString(),
        wrongIds:
            (decoded['wrongIds'] as List?)
                ?.map((item) => item.toString())
                .toList(growable: false) ??
            const <String>[],
      );
    } catch (_) {
      return null;
    }
  }
}

class _QuizQuestionSnapshot {
  final String id;
  final String koQuestion;
  final String enQuestion;
  final List<_QuizOption> options;
  final int correctIndex;
  final String koExplain;
  final String enExplain;
  final _QuizScenario? scenario;

  const _QuizQuestionSnapshot({
    required this.id,
    required this.koQuestion,
    required this.enQuestion,
    required this.options,
    required this.correctIndex,
    required this.koExplain,
    required this.enExplain,
    required this.scenario,
  });

  factory _QuizQuestionSnapshot.fromQuestion(_QuizQuestion question) {
    return _QuizQuestionSnapshot(
      id: question.id,
      koQuestion: question.koQuestion,
      enQuestion: question.enQuestion,
      options: question.options,
      correctIndex: question.correctIndex,
      koExplain: question.koExplain,
      enExplain: question.enExplain,
      scenario: question.scenario,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'koQuestion': koQuestion,
      'enQuestion': enQuestion,
      'options': options
          .map(
            (option) => <String, String>{
              'koText': option.koText,
              'enText': option.enText,
            },
          )
          .toList(growable: false),
      'correctIndex': correctIndex,
      'koExplain': koExplain,
      'enExplain': enExplain,
      'scenario': scenario?.toMap(),
    };
  }

  _QuizQuestion toQuestion() {
    return _QuizQuestion(
      id: id,
      koQuestion: koQuestion,
      enQuestion: enQuestion,
      options: options,
      correctIndex: correctIndex,
      koExplain: koExplain,
      enExplain: enExplain,
      scenario: scenario,
    );
  }

  static List<_QuizQuestion> decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <_QuizQuestion>[];
    try {
      final decoded = jsonDecode(raw);
      return fromDynamicList(decoded);
    } catch (_) {
      return const <_QuizQuestion>[];
    }
  }

  static String encodeList(List<_QuizQuestion> questions) {
    return jsonEncode(
      questions
          .map(_QuizQuestionSnapshot.fromQuestion)
          .map((snapshot) => snapshot.toMap())
          .toList(growable: false),
    );
  }

  static List<_QuizQuestion> fromDynamicList(dynamic raw) {
    if (raw is! List) return const <_QuizQuestion>[];
    return raw
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .map(_fromMap)
        .whereType<_QuizQuestion>()
        .toList(growable: false);
  }

  static _QuizQuestion? _fromMap(Map<String, dynamic> map) {
    final optionsRaw = map['options'];
    if (optionsRaw is! List) return null;
    final options = optionsRaw
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .map(
          (item) => _QuizOption(
            koText: item['koText']?.toString() ?? '',
            enText: item['enText']?.toString() ?? '',
          ),
        )
        .toList(growable: false);
    if (options.isEmpty) return null;
    final correctIndex = (map['correctIndex'] as num?)?.toInt() ?? 0;
    if (correctIndex < 0 || correctIndex >= options.length) return null;
    return _QuizQuestion(
      id: map['id']?.toString() ?? '',
      koQuestion: map['koQuestion']?.toString() ?? '',
      enQuestion: map['enQuestion']?.toString() ?? '',
      options: options,
      correctIndex: correctIndex,
      koExplain: map['koExplain']?.toString() ?? '',
      enExplain: map['enExplain']?.toString() ?? '',
      scenario: _QuizScenario.fromDynamic(map['scenario']),
    );
  }
}

enum _QuizSessionSource { today, random, history, review }

enum _QuizType { pass, dribble, control, scan, match }

class _QuizQuestion {
  final String id;
  final String koQuestion;
  final String enQuestion;
  final List<_QuizOption> options;
  final int correctIndex;
  final String koExplain;
  final String enExplain;
  final _QuizScenario? scenario;

  const _QuizQuestion({
    required this.id,
    required this.koQuestion,
    required this.enQuestion,
    required this.options,
    required this.correctIndex,
    required this.koExplain,
    required this.enExplain,
    this.scenario,
  });
}

class _QuizOption {
  final String koText;
  final String enText;

  const _QuizOption({required this.koText, required this.enText});
}

class _QuizScenario {
  final String koTitle;
  final String enTitle;
  final List<Offset> attackPoints;
  final List<Offset> defendPoints;
  final Offset ballPoint;
  final String? highlightedLane;
  final List<Offset>? attackMoveTargets;
  final List<Offset>? defendMoveTargets;
  final Offset? ballMoveTarget;
  final String? koMovementCaption;
  final String? enMovementCaption;

  const _QuizScenario({
    required this.koTitle,
    required this.enTitle,
    required this.attackPoints,
    required this.defendPoints,
    required this.ballPoint,
    this.highlightedLane,
    this.attackMoveTargets,
    this.defendMoveTargets,
    this.ballMoveTarget,
    this.koMovementCaption,
    this.enMovementCaption,
  });

  bool get hasMotion =>
      attackMoveTargets != null ||
      defendMoveTargets != null ||
      ballMoveTarget != null;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'koTitle': koTitle,
    'enTitle': enTitle,
    'attackPoints': attackPoints
        .map((point) => <String, double>{'dx': point.dx, 'dy': point.dy})
        .toList(growable: false),
    'defendPoints': defendPoints
        .map((point) => <String, double>{'dx': point.dx, 'dy': point.dy})
        .toList(growable: false),
    'ballPoint': <String, double>{'dx': ballPoint.dx, 'dy': ballPoint.dy},
    'highlightedLane': highlightedLane,
    'attackMoveTargets': attackMoveTargets
        ?.map((point) => <String, double>{'dx': point.dx, 'dy': point.dy})
        .toList(growable: false),
    'defendMoveTargets': defendMoveTargets
        ?.map((point) => <String, double>{'dx': point.dx, 'dy': point.dy})
        .toList(growable: false),
    'ballMoveTarget': ballMoveTarget == null
        ? null
        : <String, double>{'dx': ballMoveTarget!.dx, 'dy': ballMoveTarget!.dy},
    'koMovementCaption': koMovementCaption,
    'enMovementCaption': enMovementCaption,
  };

  static _QuizScenario? fromDynamic(dynamic raw) {
    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();
    final ballMap = map['ballPoint'];
    if (ballMap is! Map) return null;
    Offset toOffset(Map<dynamic, dynamic> value) => Offset(
      (value['dx'] as num?)?.toDouble() ?? 0,
      (value['dy'] as num?)?.toDouble() ?? 0,
    );
    List<Offset>? toOffsetList(dynamic value) {
      if (value is! List) return null;
      return value.whereType<Map>().map(toOffset).toList(growable: false);
    }

    final ballMoveMap = map['ballMoveTarget'];
    return _QuizScenario(
      koTitle: map['koTitle']?.toString() ?? '',
      enTitle: map['enTitle']?.toString() ?? '',
      attackPoints: (map['attackPoints'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map(toOffset)
          .toList(growable: false),
      defendPoints: (map['defendPoints'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map(toOffset)
          .toList(growable: false),
      ballPoint: toOffset(ballMap),
      highlightedLane: map['highlightedLane']?.toString(),
      attackMoveTargets: toOffsetList(map['attackMoveTargets']),
      defendMoveTargets: toOffsetList(map['defendMoveTargets']),
      ballMoveTarget: ballMoveMap is Map ? toOffset(ballMoveMap) : null,
      koMovementCaption: map['koMovementCaption']?.toString(),
      enMovementCaption: map['enMovementCaption']?.toString(),
    );
  }
}

class _ClearedQuizSet {
  final DateTime completedAt;
  final String source;
  final List<_QuizQuestion> questions;

  const _ClearedQuizSet({
    required this.completedAt,
    required this.source,
    required this.questions,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'completedAt': completedAt.toIso8601String(),
    'source': source,
    'questions': questions
        .map(_QuizQuestionSnapshot.fromQuestion)
        .map((item) => item.toMap())
        .toList(growable: false),
  };

  static String encodeList(List<_ClearedQuizSet> sets) =>
      jsonEncode(sets.map((set) => set.toMap()).toList(growable: false));

  static List<_ClearedQuizSet> decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <_ClearedQuizSet>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <_ClearedQuizSet>[];
      return decoded
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .map((map) {
            final completedAt = DateTime.tryParse(
              map['completedAt']?.toString() ?? '',
            );
            if (completedAt == null) return null;
            final questions = _QuizQuestionSnapshot.fromDynamicList(
              map['questions'],
            );
            if (questions.isEmpty) return null;
            return _ClearedQuizSet(
              completedAt: completedAt,
              source:
                  map['source']?.toString() ?? _QuizSessionSource.history.name,
              questions: questions,
            );
          })
          .whereType<_ClearedQuizSet>()
          .toList(growable: false);
    } catch (_) {
      return const <_ClearedQuizSet>[];
    }
  }
}

class _QuizSituation {
  final String id;
  final String koPrefix;
  final String enPrefix;

  const _QuizSituation({
    required this.id,
    required this.koPrefix,
    required this.enPrefix,
  });
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

class _MatchPhaseContext {
  final String id;
  final String koPrefix;
  final String enPrefix;

  const _MatchPhaseContext({
    required this.id,
    required this.koPrefix,
    required this.enPrefix,
  });
}

class _MatchScoreContext {
  final String id;
  final String koPrefix;
  final String enPrefix;

  const _MatchScoreContext({
    required this.id,
    required this.koPrefix,
    required this.enPrefix,
  });
}

class _MatchKnowledgeTemplate {
  final String id;
  final String koPrompt;
  final String enPrompt;
  final _QuizOption correct;
  final _QuizOption wrongA;
  final _QuizOption wrongB;
  final String koExplain;
  final String enExplain;

  const _MatchKnowledgeTemplate({
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

class _ScenarioQuizTemplate {
  final String id;
  final String koQuestion;
  final String enQuestion;
  final _QuizOption correct;
  final _QuizOption wrongA;
  final _QuizOption wrongB;
  final String koExplain;
  final String enExplain;
  final _QuizScenario scenario;

  const _ScenarioQuizTemplate({
    required this.id,
    required this.koQuestion,
    required this.enQuestion,
    required this.correct,
    required this.wrongA,
    required this.wrongB,
    required this.koExplain,
    required this.enExplain,
    required this.scenario,
  });
}

List<_QuizQuestion> _buildTypedQuizPool(_QuizType type) {
  if (type == _QuizType.match) {
    return _buildMatchQuizPool();
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

List<_QuizQuestion> _buildMixedQuizPool() {
  return [
    ..._buildTypedQuizPool(_QuizType.pass),
    ..._buildTypedQuizPool(_QuizType.dribble),
    ..._buildTypedQuizPool(_QuizType.control),
    ..._buildTypedQuizPool(_QuizType.scan),
    ..._buildTypedQuizPool(_QuizType.match),
    ..._buildScenarioQuizPool(),
  ];
}

List<_QuizQuestion> _buildScenarioQuizPool() {
  return _scenarioTemplates
      .map((template) {
        final pack = _buildOptionPack(
          template.id,
          template.correct,
          template.wrongA,
          template.wrongB,
        );
        return _QuizQuestion(
          id: template.id,
          koQuestion: template.koQuestion,
          enQuestion: template.enQuestion,
          options: pack.options,
          correctIndex: pack.correctIndex,
          koExplain: template.koExplain,
          enExplain: template.enExplain,
          scenario: template.scenario,
        );
      })
      .toList(growable: false);
}

List<_QuizQuestion> _buildMatchQuizPool() {
  final pool = <_QuizQuestion>[];
  for (final phase in _matchPhaseContexts) {
    for (final score in _matchScoreContexts) {
      for (final template in _matchKnowledgeTemplates) {
        final id = 'm_${phase.id}_${score.id}_${template.id}';
        final pack = _buildOptionPack(
          id,
          template.correct,
          template.wrongA,
          template.wrongB,
        );
        pool.add(
          _QuizQuestion(
            id: id,
            koQuestion:
                '${phase.koPrefix} ${score.koPrefix} ${template.koPrompt}',
            enQuestion:
                '${phase.enPrefix} ${score.enPrefix} ${template.enPrompt}',
            options: pack.options,
            correctIndex: pack.correctIndex,
            koExplain: template.koExplain,
            enExplain: template.enExplain,
          ),
        );
      }
    }
  }
  return pool;
}

_QuizQuestion _shuffleQuestionOptions(
  _QuizQuestion question,
  math.Random random,
) {
  final indexed = question.options.asMap().entries.toList(growable: false)
    ..shuffle(random);
  final shuffledOptions = indexed
      .map((entry) => entry.value)
      .toList(growable: false);
  final shuffledCorrectIndex = indexed.indexWhere(
    (entry) => entry.key == question.correctIndex,
  );
  return _QuizQuestion(
    id: question.id,
    koQuestion: question.koQuestion,
    enQuestion: question.enQuestion,
    options: shuffledOptions,
    correctIndex: shuffledCorrectIndex,
    koExplain: question.koExplain,
    enExplain: question.enExplain,
    scenario: question.scenario,
  );
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

int _stableHash(String text) {
  var hash = 0;
  for (final code in text.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  return hash;
}

const List<_MatchPhaseContext> _matchPhaseContexts = <_MatchPhaseContext>[
  _MatchPhaseContext(
    id: 'ph01',
    koPrefix: '전반 초반(1~10분),',
    enPrefix: 'Early first half (1-10 min),',
  ),
  _MatchPhaseContext(
    id: 'ph02',
    koPrefix: '전반 중반(11~25분),',
    enPrefix: 'Mid first half (11-25 min),',
  ),
  _MatchPhaseContext(
    id: 'ph03',
    koPrefix: '전반 막판(26~45분),',
    enPrefix: 'Late first half (26-45 min),',
  ),
  _MatchPhaseContext(
    id: 'ph04',
    koPrefix: '후반 초반(46~60분),',
    enPrefix: 'Early second half (46-60 min),',
  ),
  _MatchPhaseContext(
    id: 'ph05',
    koPrefix: '후반 중반(61~75분),',
    enPrefix: 'Mid second half (61-75 min),',
  ),
  _MatchPhaseContext(
    id: 'ph06',
    koPrefix: '후반 막판(76~90분),',
    enPrefix: 'Late second half (76-90 min),',
  ),
  _MatchPhaseContext(id: 'ph07', koPrefix: '추가시간,', enPrefix: 'Stoppage time,'),
  _MatchPhaseContext(
    id: 'ph08',
    koPrefix: '우리 팀이 방금 실점 직후,',
    enPrefix: 'Right after our team conceded,',
  ),
  _MatchPhaseContext(
    id: 'ph09',
    koPrefix: '우리 팀이 방금 득점 직후,',
    enPrefix: 'Right after our team scored,',
  ),
  _MatchPhaseContext(
    id: 'ph10',
    koPrefix: '교체 직후 새 포지션 적응 상황에서,',
    enPrefix: 'Right after a substitution in a new role,',
  ),
];

const List<_MatchScoreContext> _matchScoreContexts = <_MatchScoreContext>[
  _MatchScoreContext(
    id: 'sc01',
    koPrefix: '0-0 균형 상황에서',
    enPrefix: 'at 0-0 balance',
  ),
  _MatchScoreContext(
    id: 'sc02',
    koPrefix: '1점 앞선 상황에서',
    enPrefix: 'while leading by one',
  ),
  _MatchScoreContext(
    id: 'sc03',
    koPrefix: '2점 이상 앞선 상황에서',
    enPrefix: 'while leading by two or more',
  ),
  _MatchScoreContext(
    id: 'sc04',
    koPrefix: '1점 뒤진 상황에서',
    enPrefix: 'while trailing by one',
  ),
  _MatchScoreContext(
    id: 'sc05',
    koPrefix: '2점 이상 뒤진 상황에서',
    enPrefix: 'while trailing by two or more',
  ),
  _MatchScoreContext(
    id: 'sc06',
    koPrefix: '상대가 수비 블록을 내린 상황에서',
    enPrefix: 'against a low defensive block',
  ),
  _MatchScoreContext(
    id: 'sc07',
    koPrefix: '상대가 전방 압박을 강하게 거는 상황에서',
    enPrefix: 'against intense high press',
  ),
  _MatchScoreContext(
    id: 'sc08',
    koPrefix: '우리 팀에 경고 누적 선수가 많은 상황에서',
    enPrefix: 'with many teammates on cautions',
  ),
  _MatchScoreContext(
    id: 'sc09',
    koPrefix: '비가 와서 그라운드가 미끄러운 상황에서',
    enPrefix: 'on a slippery rainy pitch',
  ),
  _MatchScoreContext(
    id: 'sc10',
    koPrefix: '체력 저하가 뚜렷해진 상황에서',
    enPrefix: 'with clear physical fatigue',
  ),
];

const List<_MatchKnowledgeTemplate>
_matchKnowledgeTemplates = <_MatchKnowledgeTemplate>[
  _MatchKnowledgeTemplate(
    id: 'mk01',
    koPrompt: '빌드업 첫 선택으로 가장 안전한 원칙은?',
    enPrompt: 'what is the safest first principle in buildup?',
    correct: _QuizOption(
      koText: '볼-몸-상대 순서로 보호하며 가까운 지원부터 연결',
      enText:
          'Protect ball-body-opponent order and connect nearest support first',
    ),
    wrongA: _QuizOption(
      koText: '압박 방향과 무관하게 중앙 고정 패스',
      enText: 'Force central pass regardless of pressure',
    ),
    wrongB: _QuizOption(
      koText: '첫 터치 후 멈춘 뒤 판단',
      enText: 'Stop after first touch, then decide',
    ),
    koExplain: '시합에서는 위험을 먼저 줄이는 선택이 실점/턴오버를 줄입니다.',
    enExplain:
        'In matches, lowering immediate risk reduces goals conceded and turnovers.',
  ),
  _MatchKnowledgeTemplate(
    id: 'mk02',
    koPrompt: '전환 수비에서 가장 먼저 해야 할 행동은?',
    enPrompt: 'what is the first action in defensive transition?',
    correct: _QuizOption(
      koText: '가장 가까운 패스길 차단과 지연',
      enText: 'Block nearest passing lane and delay',
    ),
    wrongA: _QuizOption(
      koText: '즉시 공만 향해 전원 돌진',
      enText: 'Everyone sprints straight to the ball',
    ),
    wrongB: _QuizOption(
      koText: '뒤로만 빠지며 압박 포기',
      enText: 'Drop only and abandon pressure',
    ),
    koExplain: '지연과 패스길 차단이 동료 복귀 시간을 벌어줍니다.',
    enExplain: 'Delay and lane blocking buy recovery time for teammates.',
  ),
  _MatchKnowledgeTemplate(
    id: 'mk03',
    koPrompt: '공격 전환에서 우선 확인할 정보는?',
    enPrompt: 'what should be checked first in attacking transition?',
    correct: _QuizOption(
      koText: '상대 뒷공간과 전진 런 타이밍',
      enText: 'Back-space and forward-run timing',
    ),
    wrongA: _QuizOption(koText: '항상 측면으로만 전개', enText: 'Always play wide only'),
    wrongB: _QuizOption(
      koText: '공 점유를 위해 무조건 후퇴',
      enText: 'Always retreat for possession',
    ),
    koExplain: '전환 순간에는 뒷공간과 런 정보가 득점 기회를 만듭니다.',
    enExplain: 'In transition moments, back-space and run cues create chances.',
  ),
  _MatchKnowledgeTemplate(
    id: 'mk04',
    koPrompt: '세트피스 수비에서 기본 원칙으로 맞는 것은?',
    enPrompt: 'which basic principle is correct in set-piece defense?',
    correct: _QuizOption(
      koText: '마크 대상과 볼 궤적을 교차 확인',
      enText: 'Alternate checks between mark and ball flight',
    ),
    wrongA: _QuizOption(koText: '볼만 끝까지 응시', enText: 'Stare at ball only'),
    wrongB: _QuizOption(
      koText: '상대만 잡고 볼은 포기',
      enText: 'Hold mark only and ignore ball',
    ),
    koExplain: '마크와 볼을 함께 봐야 세컨드볼 대응이 가능합니다.',
    enExplain: 'Tracking both mark and ball enables second-ball responses.',
  ),
  _MatchKnowledgeTemplate(
    id: 'mk05',
    koPrompt: '오프사이드 라인 관리에서 핵심은?',
    enPrompt: 'what is key in offside-line management?',
    correct: _QuizOption(
      koText: '라인 간격과 커버 선수 소통 유지',
      enText: 'Maintain line spacing and cover communication',
    ),
    wrongA: _QuizOption(
      koText: '각자 판단으로 개별 전진',
      enText: 'Each player steps independently',
    ),
    wrongB: _QuizOption(
      koText: '항상 라인을 깊게만 내림',
      enText: 'Always keep an extremely deep line',
    ),
    koExplain: '라인 수비는 동기화와 커버 의사소통이 핵심입니다.',
    enExplain:
        'Line defending depends on synchronization and cover communication.',
  ),
  _MatchKnowledgeTemplate(
    id: 'mk06',
    koPrompt: '측면 수비에서 크로스 억제의 우선순위는?',
    enPrompt: 'what is the priority to suppress crosses on the flank?',
    correct: _QuizOption(
      koText: '안쪽 유도 후 크로스 발 차단',
      enText: 'Show inside then block crossing foot',
    ),
    wrongA: _QuizOption(
      koText: '거리 두고 기다리기만',
      enText: 'Keep distance and only wait',
    ),
    wrongB: _QuizOption(koText: '무조건 태클 먼저 시도', enText: 'Always tackle first'),
    koExplain: '크로스 발을 막는 각도 수비가 실점 확률을 낮춥니다.',
    enExplain:
        'Angle defending that blocks crossing foot reduces conceding risk.',
  ),
  _MatchKnowledgeTemplate(
    id: 'mk07',
    koPrompt: '박스 근처 수비에서 파울을 줄이는 선택은?',
    enPrompt: 'which choice reduces fouls near the box?',
    correct: _QuizOption(
      koText: '발보다 몸의 위치 선점',
      enText: 'Win position with body before foot',
    ),
    wrongA: _QuizOption(koText: '뒤에서 발만 뻗기', enText: 'Stab a foot from behind'),
    wrongB: _QuizOption(
      koText: '볼과 상관없이 밀어내기',
      enText: 'Push regardless of ball',
    ),
    koExplain: '박스 앞에서는 무리한 발 동작보다 위치 선점이 안전합니다.',
    enExplain:
        'Near the box, positional body control is safer than risky foot actions.',
  ),
  _MatchKnowledgeTemplate(
    id: 'mk08',
    koPrompt: '경기 운영(게임 매니지먼트)에서 중요한 행동은?',
    enPrompt: 'what matters in game management?',
    correct: _QuizOption(
      koText: '스코어/시간에 맞는 템포 조절',
      enText: 'Adjust tempo to scoreline and time',
    ),
    wrongA: _QuizOption(
      koText: '항상 같은 속도로 플레이',
      enText: 'Play at one constant speed always',
    ),
    wrongB: _QuizOption(
      koText: '개인 리듬만 고집',
      enText: 'Stick to personal rhythm only',
    ),
    koExplain: '시합은 상황별 템포 조절 능력이 승부를 좌우합니다.',
    enExplain: 'Match outcomes often depend on contextual tempo control.',
  ),
  _MatchKnowledgeTemplate(
    id: 'mk09',
    koPrompt: '역습 상황에서 마지막 패스 성공률을 높이는 법은?',
    enPrompt: 'how do you improve final-pass success in counterattacks?',
    correct: _QuizOption(
      koText: '러너의 몸 방향 앞 공간에 맞춤 전달',
      enText: 'Play into runner front-space by body angle',
    ),
    wrongA: _QuizOption(
      koText: '러너 발밑으로만 고정 전달',
      enText: 'Always pass directly to feet',
    ),
    wrongB: _QuizOption(
      koText: '속도와 관계없이 강하게만 전달',
      enText: 'Hit hard regardless of speed',
    ),
    koExplain: '러너의 진행 방향과 속도에 맞춰야 마무리 확률이 올라갑니다.',
    enExplain:
        'Matching runner direction and speed increases finishing probability.',
  ),
  _MatchKnowledgeTemplate(
    id: 'mk10',
    koPrompt: '의사결정 속도를 높이는 가장 현실적인 루틴은?',
    enPrompt: 'what is the most practical routine for faster decisions?',
    correct: _QuizOption(
      koText: '받기 전 짧은 좌우 스캔 반복',
      enText: 'Repeat brief left-right pre-scans',
    ),
    wrongA: _QuizOption(
      koText: '공 받은 뒤에만 주변 확인',
      enText: 'Check surroundings only after receiving',
    ),
    wrongB: _QuizOption(
      koText: '시선 고정 후 터치 수 늘리기',
      enText: 'Fix gaze and add touches',
    ),
    koExplain: '프리스캔 루틴은 경기 속도에서 판단 지연을 줄입니다.',
    enExplain: 'Pre-scan routines reduce decision lag at game speed.',
  ),
  _MatchKnowledgeTemplate(
    id: 'mk11',
    koPrompt: '멘탈 흔들림(실수 직후)에서 바른 반응은?',
    enPrompt: 'what is the right reaction after a mistake?',
    correct: _QuizOption(
      koText: '즉시 다음 수비/지원 역할에 재집중',
      enText: 'Refocus immediately on next defensive/support task',
    ),
    wrongA: _QuizOption(
      koText: '이전 실수 장면만 계속 생각',
      enText: 'Keep replaying the mistake',
    ),
    wrongB: _QuizOption(
      koText: '한 플레이 쉬면서 감정 정리',
      enText: 'Take a play off to reset emotions',
    ),
    koExplain: '시합 중 회복 탄력성은 다음 행동의 질로 드러납니다.',
    enExplain: 'In-game resilience is shown by quality of the next action.',
  ),
  _MatchKnowledgeTemplate(
    id: 'mk12',
    koPrompt: '경고가 있는 상황에서 수비 선택으로 맞는 것은?',
    enPrompt: 'which defensive choice is correct when on a yellow card?',
    correct: _QuizOption(
      koText: '접촉 타이밍 관리와 커버 유도',
      enText: 'Manage contact timing and guide into cover',
    ),
    wrongA: _QuizOption(
      koText: '이전처럼 동일 강도로 태클',
      enText: 'Tackle at same intensity as before',
    ),
    wrongB: _QuizOption(
      koText: '압박 자체를 완전히 중단',
      enText: 'Completely stop pressing',
    ),
    koExplain: '경고 상황에서는 타이밍/각도/커버 활용이 필수입니다.',
    enExplain: 'On a caution, timing-angle-cover discipline is essential.',
  ),
];

const List<_ScenarioQuizTemplate> _scenarioTemplates = <_ScenarioQuizTemplate>[
  _ScenarioQuizTemplate(
    id: 'scn01',
    koQuestion: '운동장 상황을 보면 가장 좋은 다음 선택은?',
    enQuestion: 'Looking at the pitch, what is the best next action?',
    correct: _QuizOption(
      koText: '오른쪽 하프스페이스로 빠른 전진 패스',
      enText: 'Quick forward pass into the right half-space',
    ),
    wrongA: _QuizOption(
      koText: '볼을 멈추고 중앙 압박을 기다린다',
      enText: 'Stop the ball and wait for central pressure',
    ),
    wrongB: _QuizOption(
      koText: '가장 먼 측면으로 큰 전환만 시도한다',
      enText: 'Force a long switch to the far wing',
    ),
    koExplain: '중앙 압박 전, 열린 하프스페이스를 빠르게 쓰는 판단이 좋습니다.',
    enExplain:
        'Before central pressure arrives, the open half-space is the best route.',
    scenario: _QuizScenario(
      koTitle: '중앙 압박 직전, 오른쪽 하프스페이스가 열려 있어요.',
      enTitle: 'Central pressure is closing, but the right half-space is open.',
      attackPoints: [Offset(0.18, 0.52), Offset(0.36, 0.35), Offset(0.7, 0.44)],
      defendPoints: [Offset(0.3, 0.5), Offset(0.46, 0.5), Offset(0.58, 0.56)],
      ballPoint: Offset(0.18, 0.52),
      highlightedLane: 'right-half',
      attackMoveTargets: [
        Offset(0.18, 0.52),
        Offset(0.48, 0.33),
        Offset(0.78, 0.42),
      ],
      defendMoveTargets: [
        Offset(0.34, 0.5),
        Offset(0.52, 0.48),
        Offset(0.64, 0.58),
      ],
      ballMoveTarget: Offset(0.48, 0.33),
      koMovementCaption: '움직임을 보면 공과 2선 러너가 오른쪽 하프스페이스로 같이 속도를 냅니다.',
      enMovementCaption:
          'The ball and second runner accelerate together into the right half-space.',
    ),
  ),
  _ScenarioQuizTemplate(
    id: 'scn02',
    koQuestion: '이 장면에서 수비 전환 첫 행동으로 맞는 것은?',
    enQuestion:
        'In this scene, what is the correct first action in defensive transition?',
    correct: _QuizOption(
      koText: '가장 가까운 패스길을 막으며 지연한다',
      enText: 'Delay while blocking the nearest passing lane',
    ),
    wrongA: _QuizOption(
      koText: '볼만 향해 정면 태클을 시도한다',
      enText: 'Launch a straight tackle at the ball',
    ),
    wrongB: _QuizOption(
      koText: '즉시 박스까지 전원 후퇴한다',
      enText: 'Have everyone sprint back to the box',
    ),
    koExplain: '전환 수비는 첫 태클보다 지연과 패스길 차단이 우선입니다.',
    enExplain:
        'In defensive transition, delaying and blocking the first lane comes before tackling.',
    scenario: _QuizScenario(
      koTitle: '공을 잃은 직후 상대가 중앙으로 전진하려고 합니다.',
      enTitle:
          'Right after losing the ball, the opponent wants to break centrally.',
      attackPoints: [
        Offset(0.32, 0.42),
        Offset(0.48, 0.48),
        Offset(0.66, 0.35),
      ],
      defendPoints: [Offset(0.4, 0.58), Offset(0.54, 0.62), Offset(0.7, 0.6)],
      ballPoint: Offset(0.48, 0.48),
      highlightedLane: 'center',
      defendMoveTargets: [
        Offset(0.44, 0.53),
        Offset(0.58, 0.57),
        Offset(0.7, 0.58),
      ],
      attackMoveTargets: [
        Offset(0.36, 0.45),
        Offset(0.54, 0.46),
        Offset(0.72, 0.39),
      ],
      ballMoveTarget: Offset(0.54, 0.46),
      koMovementCaption: '가까운 수비가 중앙 길목을 닫으며 속도를 늦추면 뒤 동료가 복귀할 시간을 벌 수 있어요.',
      enMovementCaption:
          'If the nearest defender slows play through the center, teammates gain recovery time.',
    ),
  ),
  _ScenarioQuizTemplate(
    id: 'scn03',
    koQuestion: '박스 앞에서 가장 좋은 판단은?',
    enQuestion: 'Near the box, what is the best decision?',
    correct: _QuizOption(
      koText: '컷백 각도를 만들며 한 번 더 연결한다',
      enText: 'Create a cutback angle and connect one more pass',
    ),
    wrongA: _QuizOption(
      koText: '각도가 닫혀도 바로 슛한다',
      enText: 'Shoot immediately even with a closed angle',
    ),
    wrongB: _QuizOption(
      koText: '볼을 뒤로 끌고 다시 하프라인까지 간다',
      enText: 'Drag the ball back toward midfield',
    ),
    koExplain: '닫힌 슛보다 컷백 연결이 더 높은 확률의 찬스를 만듭니다.',
    enExplain:
        'A cutback connection creates a higher-probability chance than a closed-angle shot.',
    scenario: _QuizScenario(
      koTitle: '측면 돌파 뒤, 박스 안쪽에 컷백 길이 열려 있어요.',
      enTitle:
          'After beating on the wing, a cutback lane opens inside the box.',
      attackPoints: [
        Offset(0.72, 0.24),
        Offset(0.78, 0.48),
        Offset(0.56, 0.54),
      ],
      defendPoints: [
        Offset(0.66, 0.36),
        Offset(0.68, 0.54),
        Offset(0.84, 0.56),
      ],
      ballPoint: Offset(0.78, 0.48),
      highlightedLane: 'right-half',
      attackMoveTargets: [
        Offset(0.76, 0.26),
        Offset(0.74, 0.52),
        Offset(0.48, 0.56),
      ],
      defendMoveTargets: [
        Offset(0.68, 0.39),
        Offset(0.72, 0.56),
        Offset(0.86, 0.58),
      ],
      ballMoveTarget: Offset(0.56, 0.54),
      koMovementCaption: '공과 중앙 침투 선수가 안쪽으로 교차하며 컷백 속도가 살아나는 장면입니다.',
      enMovementCaption:
          'The ball and central runner cut across the box, increasing cutback timing.',
    ),
  ),
  _ScenarioQuizTemplate(
    id: 'scn04',
    koQuestion: '이 장면에서 스캔 후 첫 터치 방향은 어디가 좋은가?',
    enQuestion: 'After scanning this scene, where should your first touch go?',
    correct: _QuizOption(
      koText: '압박 반대편 왼발 앞 공간',
      enText: 'Into the far-side front space away from pressure',
    ),
    wrongA: _QuizOption(
      koText: '등 뒤 압박 쪽으로 끌어온다',
      enText: 'Pull it toward the blind-side pressure',
    ),
    wrongB: _QuizOption(
      koText: '발밑에 멈춰 세운다',
      enText: 'Dead-stop it under your feet',
    ),
    koExplain: '블라인드 압박을 피하는 첫 터치가 다음 전진 선택지를 살립니다.',
    enExplain:
        'A first touch away from blind pressure preserves the next progressive option.',
    scenario: _QuizScenario(
      koTitle: '등 뒤 압박이 오고 있고, 반대편 앞 공간은 비어 있습니다.',
      enTitle:
          'Blind-side pressure is coming, while the far-side front space is open.',
      attackPoints: [
        Offset(0.44, 0.58),
        Offset(0.28, 0.42),
        Offset(0.62, 0.36),
      ],
      defendPoints: [Offset(0.5, 0.62), Offset(0.56, 0.52), Offset(0.34, 0.58)],
      ballPoint: Offset(0.44, 0.58),
      highlightedLane: 'left-half',
      attackMoveTargets: [
        Offset(0.32, 0.5),
        Offset(0.22, 0.38),
        Offset(0.66, 0.32),
      ],
      defendMoveTargets: [
        Offset(0.56, 0.6),
        Offset(0.6, 0.52),
        Offset(0.38, 0.56),
      ],
      ballMoveTarget: Offset(0.32, 0.5),
      koMovementCaption: '첫 터치가 압박 반대편 앞으로 나가면 다음 패스와 드리블 속도를 이어갈 수 있어요.',
      enMovementCaption:
          'A first touch into the far-side front space keeps the next pass and dribble alive.',
    ),
  ),
  _ScenarioQuizTemplate(
    id: 'scn05',
    koQuestion: '움직임을 보고 가장 좋은 침투 지원은 무엇일까?',
    enQuestion: 'Watching the movement, what is the best supporting run?',
    correct: _QuizOption(
      koText: '볼 받은 동료 앞쪽 빈 채널로 사선 침투',
      enText: 'Diagonal run into the open channel ahead of the receiver',
    ),
    wrongA: _QuizOption(
      koText: '공 쪽으로 같은 선에서 붙는다',
      enText: 'Move onto the same line close to the ball',
    ),
    wrongB: _QuizOption(
      koText: '뒤로만 물러나 패스 길을 줄인다',
      enText: 'Drop only backward and shrink the lane',
    ),
    koExplain: '동료가 전진 중일 때 앞 채널로 비켜 뛰어야 속도와 공간을 함께 살릴 수 있습니다.',
    enExplain:
        'When a teammate drives forward, a run into the front channel preserves both speed and space.',
    scenario: _QuizScenario(
      koTitle: '중앙에서 공을 운반하는 동료가 있고, 오른쪽 채널 수비 간격이 벌어집니다.',
      enTitle:
          'A teammate carries centrally while the right-channel defenders separate.',
      attackPoints: [Offset(0.3, 0.56), Offset(0.42, 0.42), Offset(0.62, 0.38)],
      defendPoints: [Offset(0.46, 0.5), Offset(0.66, 0.44), Offset(0.74, 0.58)],
      ballPoint: Offset(0.42, 0.42),
      highlightedLane: 'right-half',
      attackMoveTargets: [
        Offset(0.3, 0.56),
        Offset(0.5, 0.42),
        Offset(0.78, 0.3),
      ],
      defendMoveTargets: [
        Offset(0.5, 0.48),
        Offset(0.68, 0.46),
        Offset(0.76, 0.56),
      ],
      ballMoveTarget: Offset(0.5, 0.42),
      koMovementCaption: '볼 운반자 속도가 올라갈수록, 앞 채널 침투가 더 큰 공간을 만듭니다.',
      enMovementCaption:
          'As the ball carrier accelerates, the front-channel run creates a larger window.',
    ),
  ),
  _ScenarioQuizTemplate(
    id: 'scn06',
    koQuestion: '이 움직임에서 가장 좋은 수비 판단은?',
    enQuestion: 'In this movement pattern, what is the best defensive read?',
    correct: _QuizOption(
      koText: '안쪽 패스길을 먼저 닫고 측면으로 유도',
      enText: 'Shut the inside lane first and guide play outside',
    ),
    wrongA: _QuizOption(
      koText: '공만 보고 바로 달려든다',
      enText: 'Sprint straight at the ball only',
    ),
    wrongB: _QuizOption(
      koText: '박스 안까지 물러나며 기다린다',
      enText: 'Retreat to the box and wait',
    ),
    koExplain: '빠른 공격수일수록 안쪽 직선 길을 먼저 지워야 속도를 빼앗을 수 있습니다.',
    enExplain:
        'Against pace, removing the direct inside lane first is what actually slows the attack.',
    scenario: _QuizScenario(
      koTitle: '상대 윙어가 빠르게 전진하고, 안쪽 침투 지원도 따라옵니다.',
      enTitle:
          'The opponent winger drives fast, with an inside support run following.',
      attackPoints: [Offset(0.2, 0.3), Offset(0.34, 0.42), Offset(0.54, 0.58)],
      defendPoints: [Offset(0.38, 0.32), Offset(0.44, 0.5), Offset(0.62, 0.62)],
      ballPoint: Offset(0.2, 0.3),
      highlightedLane: 'left-half',
      attackMoveTargets: [
        Offset(0.34, 0.36),
        Offset(0.48, 0.46),
        Offset(0.62, 0.62),
      ],
      defendMoveTargets: [
        Offset(0.42, 0.34),
        Offset(0.48, 0.48),
        Offset(0.64, 0.6),
      ],
      ballMoveTarget: Offset(0.34, 0.36),
      koMovementCaption: '볼과 안쪽 지원이 동시에 속도를 낼 때는 중앙 문을 먼저 닫아야 해요.',
      enMovementCaption:
          'When the ball and inside support accelerate together, the central door must close first.',
    ),
  ),
  _ScenarioQuizTemplate(
    id: 'scn07',
    koQuestion: '가장 좋은 첫 패스 타이밍은 언제일까?',
    enQuestion: 'When is the best timing for the first pass?',
    correct: _QuizOption(
      koText: '동료가 수비 사이 빈 공간으로 속도를 붙이는 순간',
      enText:
          'The moment your teammate accelerates into the gap between defenders',
    ),
    wrongA: _QuizOption(
      koText: '동료가 멈춰 선 뒤',
      enText: 'After your teammate has already stopped',
    ),
    wrongB: _QuizOption(
      koText: '수비 두 명이 완전히 붙은 뒤',
      enText: 'After both defenders fully close together',
    ),
    koExplain: '속도가 붙는 순간에 맞춰 넣어야 동료가 공간으로 받으며 다음 플레이를 이어갑니다.',
    enExplain:
        'Passing on the teammate acceleration cue lets them receive into space and keep flowing.',
    scenario: _QuizScenario(
      koTitle: '투톱 사이에서 한 명이 뒤로 끌고, 다른 한 명이 뒷공간으로 뛰기 시작합니다.',
      enTitle:
          'One forward checks short while the other begins a run into the back space.',
      attackPoints: [Offset(0.28, 0.5), Offset(0.5, 0.48), Offset(0.7, 0.32)],
      defendPoints: [
        Offset(0.46, 0.44),
        Offset(0.58, 0.42),
        Offset(0.66, 0.54),
      ],
      ballPoint: Offset(0.28, 0.5),
      highlightedLane: 'center',
      attackMoveTargets: [
        Offset(0.28, 0.5),
        Offset(0.44, 0.52),
        Offset(0.82, 0.24),
      ],
      defendMoveTargets: [
        Offset(0.48, 0.45),
        Offset(0.6, 0.42),
        Offset(0.68, 0.54),
      ],
      ballMoveTarget: Offset(0.6, 0.34),
      koMovementCaption: '체크 움직임이 수비를 끌어내는 순간, 반대 러너는 더 큰 뒷공간을 얻습니다.',
      enMovementCaption:
          'As the check run pulls defenders out, the opposite runner gains a bigger back-space lane.',
    ),
  ),
  _ScenarioQuizTemplate(
    id: 'scn08',
    koQuestion: '이 장면에서 가장 좋은 오프더볼 선택은?',
    enQuestion: 'In this scene, what is the best off-ball choice?',
    correct: _QuizOption(
      koText: '공보다 한 박자 먼저 빈 공간으로 이동해 패스 각도 만들기',
      enText:
          'Arrive in the open space a beat early to create the passing angle',
    ),
    wrongA: _QuizOption(
      koText: '볼 온 뒤에만 움직인다',
      enText: 'Move only after the ball arrives',
    ),
    wrongB: _QuizOption(
      koText: '동료 뒤에 숨어 서 있다',
      enText: 'Stand hidden behind your teammate',
    ),
    koExplain: '공보다 먼저 공간을 점유하면 패스 속도에 맞춰 한 번에 연결할 수 있습니다.',
    enExplain:
        'Occupying the space early lets you connect in one touch at game speed.',
    scenario: _QuizScenario(
      koTitle: '좌우로 공이 순환되고 있고, 중앙 미드필더 앞 공간이 잠깐 비었습니다.',
      enTitle:
          'The ball circulates side to side, and a pocket opens briefly in front of midfield.',
      attackPoints: [Offset(0.18, 0.54), Offset(0.44, 0.46), Offset(0.72, 0.5)],
      defendPoints: [
        Offset(0.36, 0.46),
        Offset(0.52, 0.48),
        Offset(0.64, 0.52),
      ],
      ballPoint: Offset(0.18, 0.54),
      highlightedLane: 'center',
      attackMoveTargets: [
        Offset(0.3, 0.54),
        Offset(0.5, 0.4),
        Offset(0.72, 0.5),
      ],
      defendMoveTargets: [
        Offset(0.4, 0.46),
        Offset(0.54, 0.48),
        Offset(0.66, 0.52),
      ],
      ballMoveTarget: Offset(0.5, 0.4),
      koMovementCaption: '잠깐 열린 포켓은 오래 남지 않으니, 공이 오기 전에 먼저 들어가야 합니다.',
      enMovementCaption:
          'The pocket will not stay open, so you need to enter before the ball gets there.',
    ),
  ),
];

const List<_QuizSituation> _situations = <_QuizSituation>[
  _QuizSituation(
    id: 's01',
    koPrefix: '하프라인 부근에서 받는 순간,',
    enPrefix: 'Near midfield when receiving,',
  ),
  _QuizSituation(
    id: 's02',
    koPrefix: '측면 압박이 빠르게 올 때,',
    enPrefix: 'When wing pressure comes fast,',
  ),
  _QuizSituation(
    id: 's03',
    koPrefix: '중앙 좁은 공간에서,',
    enPrefix: 'In tight central space,',
  ),
  _QuizSituation(
    id: 's04',
    koPrefix: '역습 전환 1~2초 안에,',
    enPrefix: 'Within 1-2 seconds of transition,',
  ),
  _QuizSituation(
    id: 's05',
    koPrefix: '수비수와 1:1 대치 시,',
    enPrefix: 'In a 1v1 against a defender,',
  ),
  _QuizSituation(
    id: 's06',
    koPrefix: '3인 연계 훈련 템포 유지에서,',
    enPrefix: 'To keep tempo in a 3-player combo,',
  ),
  _QuizSituation(
    id: 's07',
    koPrefix: '패스 후 다시 지원할 때,',
    enPrefix: 'After passing and supporting again,',
  ),
  _QuizSituation(
    id: 's08',
    koPrefix: '박스 앞 의사결정에서,',
    enPrefix: 'In decision making near the box,',
  ),
  _QuizSituation(
    id: 's09',
    koPrefix: '압박 탈출 첫 선택에서,',
    enPrefix: 'In your first pressure-escape choice,',
  ),
  _QuizSituation(
    id: 's10',
    koPrefix: '템포를 끊지 않아야 할 때,',
    enPrefix: 'When you must not break tempo,',
  ),
];

const Map<_QuizType, List<_QuizConcept>>
_conceptsByType = <_QuizType, List<_QuizConcept>>{
  _QuizType.pass: <_QuizConcept>[
    _QuizConcept(
      id: 'p01',
      koPrompt: '패스 각도 선택으로 가장 좋은 것은?',
      enPrompt: 'what is the best passing-angle choice?',
      correct: _QuizOption(
        koText: '열린 발 앞 공간으로 보낸다',
        enText: 'Play into the open front foot space',
      ),
      wrongA: _QuizOption(
        koText: '수비 정면으로 찌른다',
        enText: 'Force straight at defender',
      ),
      wrongB: _QuizOption(koText: '무조건 뒤로만 준다', enText: 'Always pass backward'),
      koExplain: '열린 발 앞 공간 패스가 다음 동작 연결에 유리합니다.',
      enExplain:
          'Passing into open front-foot space improves next-action flow.',
    ),
    _QuizConcept(
      id: 'p02',
      koPrompt: '짧은 패스 접촉 면으로 맞는 것은?',
      enPrompt: 'which contact surface is correct for short pass?',
      correct: _QuizOption(koText: '발 안쪽', enText: 'Inside of foot'),
      wrongA: _QuizOption(koText: '발끝', enText: 'Toe'),
      wrongB: _QuizOption(koText: '뒤꿈치', enText: 'Heel'),
      koExplain: '발 안쪽은 방향과 힘 제어가 안정적입니다.',
      enExplain: 'Inside foot gives stable direction and power control.',
    ),
    _QuizConcept(
      id: 'p03',
      koPrompt: '패스 강도 조절의 기준은?',
      enPrompt: 'what should determine pass weight?',
      correct: _QuizOption(
        koText: '동료 속도와 수비 거리',
        enText: 'Teammate speed and defender distance',
      ),
      wrongA: _QuizOption(koText: '항상 최대 힘', enText: 'Always max power'),
      wrongB: _QuizOption(koText: '항상 약하게', enText: 'Always too soft'),
      koExplain: '패스 세기는 상황 기반으로 바뀌어야 정확도가 올라갑니다.',
      enExplain: 'Context-based weight increases pass accuracy.',
    ),
    _QuizConcept(
      id: 'p04',
      koPrompt: '원터치 패스를 쓰는 주된 이유는?',
      enPrompt: 'why use one-touch passing primarily?',
      correct: _QuizOption(
        koText: '압박 시간을 줄이기 위해',
        enText: 'To reduce pressure time',
      ),
      wrongA: _QuizOption(koText: '폼을 보여주기 위해', enText: 'To show style only'),
      wrongB: _QuizOption(
        koText: '항상 더 강하게 차기 위해',
        enText: 'To kick harder always',
      ),
      koExplain: '볼 점유 시간을 줄여 압박을 무력화합니다.',
      enExplain: 'It neutralizes pressure by shortening ball-holding time.',
    ),
    _QuizConcept(
      id: 'p05',
      koPrompt: '패스 전 딛는 발의 역할은?',
      enPrompt: 'what is the role of your plant foot?',
      correct: _QuizOption(
        koText: '몸 균형과 방향 고정',
        enText: 'Stabilize body and direction',
      ),
      wrongA: _QuizOption(
        koText: '공을 건드리는 용도',
        enText: 'Touch the ball itself',
      ),
      wrongB: _QuizOption(koText: '점프 준비 용도', enText: 'Prepare a jump'),
      koExplain: '딛는 발이 안정되면 패스 오차가 줄어듭니다.',
      enExplain: 'A stable plant foot reduces passing error.',
    ),
    _QuizConcept(
      id: 'p06',
      koPrompt: '패스 라인이 막히면 우선 무엇을 할까?',
      enPrompt: 'what should you do first if lane is blocked?',
      correct: _QuizOption(
        koText: '각도 재조정 후 연결',
        enText: 'Re-angle then connect',
      ),
      wrongA: _QuizOption(koText: '무리한 직선 패스', enText: 'Force straight pass'),
      wrongB: _QuizOption(koText: '볼을 멈추고 기다림', enText: 'Stop and wait'),
      koExplain: '작은 위치 조정으로 새 라인을 만들 수 있습니다.',
      enExplain: 'Small repositioning opens new lanes.',
    ),
    _QuizConcept(
      id: 'p07',
      koPrompt: '전진 패스가 좋은 타이밍은?',
      enPrompt: 'when is forward pass timing best?',
      correct: _QuizOption(
        koText: '동료가 몸을 열고 받을 때',
        enText: 'When teammate is open to receive',
      ),
      wrongA: _QuizOption(
        koText: '동료가 등진 상태일 때',
        enText: 'When teammate is fully back-turned',
      ),
      wrongB: _QuizOption(
        koText: '수비 둘 사이 닫혔을 때',
        enText: 'When two defenders close lane',
      ),
      koExplain: '받는 자세가 열려야 다음 전개가 이어집니다.',
      enExplain: 'Open receiving posture supports next progression.',
    ),
    _QuizConcept(
      id: 'p08',
      koPrompt: '패스 후 가장 좋은 움직임은?',
      enPrompt: 'what is best movement after pass?',
      correct: _QuizOption(
        koText: '삼각형 지원 각도 만들기',
        enText: 'Create support triangle angle',
      ),
      wrongA: _QuizOption(koText: '제자리 정지', enText: 'Stand still'),
      wrongB: _QuizOption(
        koText: '공 쪽 직선 돌진만',
        enText: 'Run straight only to ball',
      ),
      koExplain: '지원 각도가 생기면 연계 성공률이 높아집니다.',
      enExplain: 'Support angles increase combination success rate.',
    ),
    _QuizConcept(
      id: 'p09',
      koPrompt: '리턴 패스를 사용할 상황은?',
      enPrompt: 'when should return pass be used?',
      correct: _QuizOption(
        koText: '강한 압박에서 안전 연결이 필요할 때',
        enText: 'When heavy pressure needs safe link',
      ),
      wrongA: _QuizOption(
        koText: '항상 리턴만 고집',
        enText: 'Always force return pass',
      ),
      wrongB: _QuizOption(
        koText: '압박이 없을 때만 사용',
        enText: 'Use only without pressure',
      ),
      koExplain: '리턴 패스는 압박 탈출의 기본 옵션입니다.',
      enExplain: 'Return pass is a core pressure-escape option.',
    ),
    _QuizConcept(
      id: 'p10',
      koPrompt: '패스 성공률을 높이는 시선은?',
      enPrompt: 'what vision habit boosts pass success?',
      correct: _QuizOption(
        koText: '수비와 동료를 번갈아 짧게 확인',
        enText: 'Alternate quick checks of defenders and teammates',
      ),
      wrongA: _QuizOption(koText: '공만 끝까지 응시', enText: 'Stare only at ball'),
      wrongB: _QuizOption(
        koText: '고개를 완전히 돌리고 멈춤',
        enText: 'Turn head away and stop',
      ),
      koExplain: '짧은 스캔 반복이 패스 의사결정을 빠르게 합니다.',
      enExplain: 'Repeated micro-scans accelerate pass decisions.',
    ),
  ],
  _QuizType.dribble: <_QuizConcept>[
    _QuizConcept(
      id: 'd01',
      koPrompt: '돌파 시작 전 핵심은?',
      enPrompt: 'what is key before starting a beat?',
      correct: _QuizOption(koText: '템포 변화 준비', enText: 'Prepare tempo change'),
      wrongA: _QuizOption(koText: '처음부터 최고속', enText: 'Max speed from start'),
      wrongB: _QuizOption(koText: '고개 숙이고 전진', enText: 'Head down run'),
      koExplain: '템포 변화가 수비 중심을 흔듭니다.',
      enExplain: 'Tempo change destabilizes defender balance.',
    ),
    _QuizConcept(
      id: 'd02',
      koPrompt: '좁은 공간 드리블 기본은?',
      enPrompt: 'what is basic dribbling in tight space?',
      correct: _QuizOption(
        koText: '짧은 터치와 몸 보호',
        enText: 'Short touches with body shielding',
      ),
      wrongA: _QuizOption(koText: '큰 터치 반복', enText: 'Repeated long touches'),
      wrongB: _QuizOption(
        koText: '정지 후 출발 반복',
        enText: 'Stop-start without control',
      ),
      koExplain: '짧은 터치가 볼 소유 안정성을 높입니다.',
      enExplain: 'Short touches improve possession stability.',
    ),
    _QuizConcept(
      id: 'd03',
      koPrompt: '수비를 흔드는 가장 쉬운 방법은?',
      enPrompt: 'what is easiest way to unbalance defender?',
      correct: _QuizOption(
        koText: '시선 페이크 + 방향 전환',
        enText: 'Eye fake plus direction change',
      ),
      wrongA: _QuizOption(koText: '속도만 올린다', enText: 'Only increase speed'),
      wrongB: _QuizOption(
        koText: '항상 같은 터치 리듬',
        enText: 'Always same touch rhythm',
      ),
      koExplain: '시선과 템포 조합이 수비 반응을 늦춥니다.',
      enExplain: 'Eye-tempo combo delays defensive reaction.',
    ),
    _QuizConcept(
      id: 'd04',
      koPrompt: '드리블 중 시야 확보 습관은?',
      enPrompt: 'what keeps vision while dribbling?',
      correct: _QuizOption(
        koText: '짧은 터치 후 고개 들기',
        enText: 'Head-up checks after short touches',
      ),
      wrongA: _QuizOption(koText: '볼만 지속 응시', enText: 'Keep staring at ball'),
      wrongB: _QuizOption(
        koText: '시선 고정하고 가속',
        enText: 'Fixed gaze with acceleration',
      ),
      koExplain: '시야가 열려야 다음 선택이 빨라집니다.',
      enExplain: 'Open vision speeds up next action choice.',
    ),
    _QuizConcept(
      id: 'd05',
      koPrompt: '1:1에서 먼저 해야 할 것은?',
      enPrompt: 'what should come first in 1v1?',
      correct: _QuizOption(
        koText: '수비 발/무게중심 관찰',
        enText: 'Read defender foot and weight',
      ),
      wrongA: _QuizOption(koText: '바로 큰 터치', enText: 'Immediate big touch'),
      wrongB: _QuizOption(koText: '멈춰서 공만 보호', enText: 'Only stop and shield'),
      koExplain: '상대 중심을 읽어야 효율적인 돌파가 가능합니다.',
      enExplain: 'Reading balance enables efficient beating.',
    ),
    _QuizConcept(
      id: 'd06',
      koPrompt: '가속 타이밍은 언제가 좋은가?',
      enPrompt: 'when is acceleration timing best?',
      correct: _QuizOption(
        koText: '수비 발이 멈춘 순간',
        enText: 'When defender feet get planted',
      ),
      wrongA: _QuizOption(
        koText: '항상 첫 터치 직후',
        enText: 'Always right after first touch',
      ),
      wrongB: _QuizOption(
        koText: '라인 밖으로 밀린 뒤',
        enText: 'After being pushed wide',
      ),
      koExplain: '수비가 멈추는 찰나가 가속 창입니다.',
      enExplain: 'Defender planted moment is acceleration window.',
    ),
    _QuizConcept(
      id: 'd07',
      koPrompt: '측면 돌파 후 우선 판단은?',
      enPrompt: 'after wing beat, what is first read?',
      correct: _QuizOption(
        koText: '컷백/크로스 각도',
        enText: 'Cutback or cross angle',
      ),
      wrongA: _QuizOption(koText: '무조건 슛', enText: 'Always shoot immediately'),
      wrongB: _QuizOption(koText: '다시 후퇴 드리블', enText: 'Retreat dribble again'),
      koExplain: '돌파 이후는 선택지 판단이 더 중요합니다.',
      enExplain: 'Post-beat choice quality matters most.',
    ),
    _QuizConcept(
      id: 'd08',
      koPrompt: '드리블 접촉 부위 활용으로 맞는 것은?',
      enPrompt: 'which touch-surface usage is right?',
      correct: _QuizOption(
        koText: '안/밖/발등을 상황별 혼합',
        enText: 'Mix inside/outside/laces by context',
      ),
      wrongA: _QuizOption(koText: '한 부위만 고정', enText: 'Use only one surface'),
      wrongB: _QuizOption(koText: '발끝만 사용', enText: 'Use only toe'),
      koExplain: '접촉 부위 다양성이 궤적 선택폭을 넓힙니다.',
      enExplain: 'Surface variety expands trajectory options.',
    ),
    _QuizConcept(
      id: 'd09',
      koPrompt: '압박 2명일 때 현실적인 선택은?',
      enPrompt: 'what is realistic choice vs two pressers?',
      correct: _QuizOption(
        koText: '짧게 벗기고 패스 연결',
        enText: 'Escape briefly and link pass',
      ),
      wrongA: _QuizOption(
        koText: '두 명 모두 개인기로 돌파',
        enText: 'Beat both with solo move',
      ),
      wrongB: _QuizOption(
        koText: '멈춰서 반칙 유도만',
        enText: 'Stop only to draw foul',
      ),
      koExplain: '2인 압박에서는 빠른 연결이 효율적입니다.',
      enExplain: 'Quick link play is efficient against double pressure.',
    ),
    _QuizConcept(
      id: 'd10',
      koPrompt: '드리블 성공률을 높이는 훈련법은?',
      enPrompt: 'what training improves dribble success?',
      correct: _QuizOption(
        koText: '속도 변화 포함 반복',
        enText: 'Repetition with speed variation',
      ),
      wrongA: _QuizOption(
        koText: '저속만 반복',
        enText: 'Only low-speed repetition',
      ),
      wrongB: _QuizOption(koText: '폼만 확인', enText: 'Check form only'),
      koExplain: '실전은 속도 변화가 핵심이므로 훈련에도 포함해야 합니다.',
      enExplain: 'Game dribbling needs speed variation in training.',
    ),
  ],
  _QuizType.control: <_QuizConcept>[
    _QuizConcept(
      id: 'c01',
      koPrompt: '퍼스트 터치의 목표는?',
      enPrompt: 'what is goal of first touch?',
      correct: _QuizOption(
        koText: '다음 동작 가능한 위치 만들기',
        enText: 'Set up the next action',
      ),
      wrongA: _QuizOption(koText: '무조건 정지', enText: 'Always dead stop'),
      wrongB: _QuizOption(koText: '강하게 튕기기', enText: 'Bounce it hard away'),
      koExplain: '퍼스트 터치는 다음 플레이를 위한 준비 동작입니다.',
      enExplain: 'First touch is preparation for next play.',
    ),
    _QuizConcept(
      id: 'c02',
      koPrompt: '압박 속 볼 보호 기본은?',
      enPrompt: 'what is basic ball protection under pressure?',
      correct: _QuizOption(
        koText: '몸-볼-수비 순서 유지',
        enText: 'Keep body-ball-defender order',
      ),
      wrongA: _QuizOption(koText: '볼을 먼저 멀리 둠', enText: 'Put ball far first'),
      wrongB: _QuizOption(koText: '정면 대치만', enText: 'Face up directly only'),
      koExplain: '몸을 먼저 두면 공 소유를 지키기 쉽습니다.',
      enExplain: 'Body-first positioning protects possession.',
    ),
    _QuizConcept(
      id: 'c03',
      koPrompt: '먼 발 컨트롤 장점은?',
      enPrompt: 'what is advantage of far-foot control?',
      correct: _QuizOption(
        koText: '수비와 공 사이에 몸 배치',
        enText: 'Body between defender and ball',
      ),
      wrongA: _QuizOption(koText: '더 강한 트래핑', enText: 'Stronger trap only'),
      wrongB: _QuizOption(koText: '무조건 빠른 턴', enText: 'Always faster turn'),
      koExplain: '먼 발 컨트롤은 차단 가능성을 줄입니다.',
      enExplain: 'Far-foot control reduces interception risk.',
    ),
    _QuizConcept(
      id: 'c04',
      koPrompt: '트래핑 소음을 줄여야 하는 이유는?',
      enPrompt: 'why reduce heavy trap sound?',
      correct: _QuizOption(
        koText: '반동 감소로 다음 동작이 쉬움',
        enText: 'Less rebound, easier next move',
      ),
      wrongA: _QuizOption(koText: '속도만 빠르게', enText: 'Only to be faster'),
      wrongB: _QuizOption(koText: '폼이 좋아 보여서', enText: 'Only for cleaner form'),
      koExplain: '완충 컨트롤이 곧 다음 플레이 품질입니다.',
      enExplain: 'Cushion control improves next-play quality.',
    ),
    _QuizConcept(
      id: 'c05',
      koPrompt: '열린 자세로 받을 때 좋은 점은?',
      enPrompt: 'benefit of receiving with open body?',
      correct: _QuizOption(
        koText: '전/후/측면 선택지 확보',
        enText: 'Keep forward/back/side options',
      ),
      wrongA: _QuizOption(
        koText: '턴 없이 보호만 가능',
        enText: 'Only shielding without turn',
      ),
      wrongB: _QuizOption(koText: '속도 감소', enText: 'Reduce speed only'),
      koExplain: '열린 자세가 의사결정 속도를 높입니다.',
      enExplain: 'Open shape speeds decision making.',
    ),
    _QuizConcept(
      id: 'c06',
      koPrompt: '컨트롤 후 시선 우선순위는?',
      enPrompt: 'what is first visual priority after control?',
      correct: _QuizOption(
        koText: '가장 가까운 압박 위치',
        enText: 'Nearest pressure location',
      ),
      wrongA: _QuizOption(koText: '볼 궤적만 보기', enText: 'Watch ball path only'),
      wrongB: _QuizOption(koText: '벤치 보기', enText: 'Look at bench'),
      koExplain: '압박 확인이 다음 터치 방향을 결정합니다.',
      enExplain: 'Pressure read defines next touch direction.',
    ),
    _QuizConcept(
      id: 'c07',
      koPrompt: '약발 컨트롤 훈련의 목적은?',
      enPrompt: 'purpose of weak-foot control drills?',
      correct: _QuizOption(
        koText: '압박 상황 선택지 확대',
        enText: 'Expand options under pressure',
      ),
      wrongA: _QuizOption(koText: '시간 단축', enText: 'Save training time'),
      wrongB: _QuizOption(koText: '강발 휴식', enText: 'Rest strong foot'),
      koExplain: '양발 컨트롤이 전개 속도를 높입니다.',
      enExplain: 'Two-foot control improves buildup speed.',
    ),
    _QuizConcept(
      id: 'c08',
      koPrompt: '컨트롤 실패(긴 터치) 시 대처는?',
      enPrompt: 'response to heavy touch failure?',
      correct: _QuizOption(
        koText: '몸 먼저 넣어 재확보',
        enText: 'Insert body first and recover',
      ),
      wrongA: _QuizOption(koText: '멈추고 기다림', enText: 'Stop and wait'),
      wrongB: _QuizOption(koText: '시선 회피', enText: 'Look away'),
      koExplain: '즉시 신체 개입이 실점/턴오버를 줄입니다.',
      enExplain: 'Immediate body intervention reduces turnovers.',
    ),
    _QuizConcept(
      id: 'c09',
      koPrompt: '받을 때 발 간격의 기준은?',
      enPrompt: 'what foot spacing is preferred on receive?',
      correct: _QuizOption(
        koText: '어깨 너비 기반 균형 유지',
        enText: 'Shoulder-width for balance',
      ),
      wrongA: _QuizOption(koText: '두 발 붙임', enText: 'Feet glued together'),
      wrongB: _QuizOption(koText: '과하게 넓힘', enText: 'Overly wide stance'),
      koExplain: '적절한 간격이 회전과 안정성을 동시에 확보합니다.',
      enExplain: 'Proper spacing secures both turnability and balance.',
    ),
    _QuizConcept(
      id: 'c10',
      koPrompt: '컨트롤 후 2터치 연결의 장점은?',
      enPrompt: 'benefit of controlled two-touch link?',
      correct: _QuizOption(
        koText: '안정성과 템포 균형',
        enText: 'Balance of control and tempo',
      ),
      wrongA: _QuizOption(
        koText: '항상 원터치보다 빠름',
        enText: 'Always faster than one-touch',
      ),
      wrongB: _QuizOption(koText: '판단 불필요', enText: 'No decision needed'),
      koExplain: '2터치는 안정성을 주면서 템포를 크게 해치지 않습니다.',
      enExplain: 'Two-touch adds control without major tempo loss.',
    ),
  ],
  _QuizType.scan: <_QuizConcept>[
    _QuizConcept(
      id: 's01',
      koPrompt: '기본 스캔 타이밍으로 맞는 것은?',
      enPrompt: 'which is correct basic scan timing?',
      correct: _QuizOption(
        koText: '받기 전-순간-직후 3회',
        enText: 'Before-during-after receive',
      ),
      wrongA: _QuizOption(
        koText: '받은 후 1회만',
        enText: 'Only once after receive',
      ),
      wrongB: _QuizOption(koText: '상대 없을 때만', enText: 'Only when unpressed'),
      koExplain: '3단계 스캔이 정보 누락을 줄입니다.',
      enExplain: 'Three-phase scan reduces missed information.',
    ),
    _QuizConcept(
      id: 's02',
      koPrompt: '스캔의 첫 대상은?',
      enPrompt: 'what is first scan target?',
      correct: _QuizOption(koText: '가장 가까운 압박자', enText: 'Nearest presser'),
      wrongA: _QuizOption(koText: '관중석', enText: 'Spectator stand'),
      wrongB: _QuizOption(koText: '볼 표면', enText: 'Ball surface only'),
      koExplain: '압박자 확인이 우선입니다.',
      enExplain: 'Pressing threat check comes first.',
    ),
    _QuizConcept(
      id: 's03',
      koPrompt: '패스 전 스캔 목적은?',
      enPrompt: 'purpose of scan before pass?',
      correct: _QuizOption(
        koText: '패스 각/차단 위험 확인',
        enText: 'Check lane and interception risk',
      ),
      wrongA: _QuizOption(koText: '자세만 확인', enText: 'Only check posture'),
      wrongB: _QuizOption(koText: '속도만 확인', enText: 'Only check speed'),
      koExplain: '각도와 위험 판단이 패스 성공률을 높입니다.',
      enExplain: 'Lane-risk read boosts pass success.',
    ),
    _QuizConcept(
      id: 's04',
      koPrompt: '스캔 시 고개 움직임 원칙은?',
      enPrompt: 'head-movement principle while scanning?',
      correct: _QuizOption(
        koText: '짧고 빠르게 반복',
        enText: 'Short and frequent checks',
      ),
      wrongA: _QuizOption(koText: '한 번 길게 보기', enText: 'One long look'),
      wrongB: _QuizOption(koText: '고개 고정', enText: 'Keep head fixed'),
      koExplain: '짧은 스캔이 볼 컨트롤과 정보 수집을 동시에 가능하게 합니다.',
      enExplain: 'Short scans balance control and information intake.',
    ),
    _QuizConcept(
      id: 's05',
      koPrompt: '스캔과 첫 터치의 관계는?',
      enPrompt: 'relationship of scan and first touch?',
      correct: _QuizOption(
        koText: '스캔이 첫 터치 방향을 결정',
        enText: 'Scan determines first-touch direction',
      ),
      wrongA: _QuizOption(koText: '무관하다', enText: 'They are unrelated'),
      wrongB: _QuizOption(
        koText: '첫 터치 후 스캔만 중요',
        enText: 'Only post-touch scan matters',
      ),
      koExplain: '선행 스캔 없이는 좋은 첫 터치가 어렵습니다.',
      enExplain: 'Without pre-scan, quality first touch is difficult.',
    ),
    _QuizConcept(
      id: 's06',
      koPrompt: '패스 후 재스캔 이유는?',
      enPrompt: 'why rescan after passing?',
      correct: _QuizOption(
        koText: '다음 지원 위치 즉시 선택',
        enText: 'Choose next support position quickly',
      ),
      wrongA: _QuizOption(koText: '방금 패스만 감상', enText: 'Watch your pass only'),
      wrongB: _QuizOption(koText: '멈춰서 지시만', enText: 'Stop and only instruct'),
      koExplain: '패스 후 재스캔이 연계 속도를 높입니다.',
      enExplain: 'Post-pass rescan speeds up combinations.',
    ),
    _QuizConcept(
      id: 's07',
      koPrompt: '역습 상황 스캔 우선순위는?',
      enPrompt: 'scan priority in transition attack?',
      correct: _QuizOption(
        koText: '수비 라인과 전진 런',
        enText: 'Defensive line and forward runs',
      ),
      wrongA: _QuizOption(koText: '가장 먼 동료만', enText: 'Only farthest teammate'),
      wrongB: _QuizOption(koText: '공만 보기', enText: 'Ball only'),
      koExplain: '라인과 런 정보를 동시에 보면 선택이 빨라집니다.',
      enExplain: 'Line+run reading accelerates transition choices.',
    ),
    _QuizConcept(
      id: 's08',
      koPrompt: '좁은 공간에서 스캔 빈도는?',
      enPrompt: 'scan frequency in tight space?',
      correct: _QuizOption(
        koText: '더 짧고 더 자주',
        enText: 'Shorter and more frequent',
      ),
      wrongA: _QuizOption(koText: '덜 자주', enText: 'Less frequent'),
      wrongB: _QuizOption(koText: '없어도 됨', enText: 'Can skip scanning'),
      koExplain: '공간이 좁을수록 정보 갱신 주기가 짧아야 합니다.',
      enExplain: 'Tighter space needs faster information refresh.',
    ),
    _QuizConcept(
      id: 's09',
      koPrompt: '스캔에서 놓치면 위험한 정보는?',
      enPrompt: 'critical info that must not be missed while scanning?',
      correct: _QuizOption(
        koText: '블라인드 사이드 압박',
        enText: 'Blind-side pressure',
      ),
      wrongA: _QuizOption(koText: '유니폼 색상', enText: 'Jersey color'),
      wrongB: _QuizOption(koText: '관중 반응', enText: 'Crowd reaction'),
      koExplain: '블라인드 압박을 놓치면 즉시 턴오버 위험이 큽니다.',
      enExplain: 'Missing blind pressure causes immediate turnover risk.',
    ),
    _QuizConcept(
      id: 's10',
      koPrompt: '훈련에서 스캔을 습관화하는 방법은?',
      enPrompt: 'how to build scanning habit in training?',
      correct: _QuizOption(
        koText: '받기 전 양쪽 호출 루틴',
        enText: 'Pre-receive left-right call routine',
      ),
      wrongA: _QuizOption(koText: '정답만 외우기', enText: 'Memorize answers only'),
      wrongB: _QuizOption(
        koText: '컨디션 좋을 때만',
        enText: 'Only when feeling good',
      ),
      koExplain: '루틴화가 경기 중 자동 스캔을 만듭니다.',
      enExplain: 'Routines create automatic in-game scanning.',
    ),
  ],
};
