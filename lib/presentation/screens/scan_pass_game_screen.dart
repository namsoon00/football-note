import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../../application/scan_pass_history_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../../domain/scan_pass/scan_pass_game.dart';
import '../theme/app_motion.dart';
import '../widgets/app_bar_action_button.dart';

enum _ScanPassFlow { intro, practice, challenge }

enum _ScanPassPhase { observe, firstTouch, nextAction, review, result }

class ScanPassGameScreen extends StatefulWidget {
  final OptionRepository optionRepository;
  final int? seed;
  final Duration previewDuration;
  final Duration choiceDuration;
  final Duration passAnimationDuration;

  const ScanPassGameScreen({
    super.key,
    required this.optionRepository,
    this.seed,
    this.previewDuration = const Duration(milliseconds: 1250),
    this.choiceDuration = ScanPassMatchEngine.defaultChoiceWindow,
    this.passAnimationDuration = const Duration(milliseconds: 2000),
  });

  @override
  State<ScanPassGameScreen> createState() => _ScanPassGameScreenState();
}

class _ScanPassGameScreenState extends State<ScanPassGameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _charcoal = Color(0xFF101820);
  static const Color _surface = Color(0xFF17212B);
  static const Color _surfaceAlt = Color(0xFF202B35);
  static const Color _line = Color(0xFF3A4652);
  static const Color _offWhite = Color(0xFFF2EFE7);
  static const int _roundCount = ScanPassScenarioLibrary.roundCount;

  final ScanPassMatchEngine _engine = const ScanPassMatchEngine();
  late final AnimationController _observeController;
  late final AnimationController _reviewController;
  late final AnimationController _touchController;
  Timer? _phaseTimer;
  Timer? _choiceTicker;
  Timer? _choiceDeadlineTimer;
  ScanPassChoiceClock? _choiceClock;
  ScanPassPersonalSummary _personalSummary =
      const ScanPassPersonalSummary.empty();
  List<ScanPassScenario> _rounds = const <ScanPassScenario>[];
  final List<ScanPassRoundResult> _results = <ScanPassRoundResult>[];
  final List<ScanPassScanObservation> _scans = <ScanPassScanObservation>[];
  _ScanPassFlow _flow = _ScanPassFlow.intro;
  _ScanPassPhase _phase = _ScanPassPhase.observe;
  int _roundIndex = 0;
  int _phaseToken = 0;
  bool _savingHistory = false;
  bool _showAlternative = false;
  bool _executingTouch = false;
  Duration _remainingChoice = ScanPassMatchEngine.defaultChoiceWindow;
  Duration _stageElapsedBeforePause = Duration.zero;
  Duration _firstDecisionTime = Duration.zero;
  ScanPassFirstTouch? _selectedFirstTouch;
  ScanPassNextAction? _selectedNextAction;
  ScanPassFirstTouchState? _firstTouchState;
  ScanPassPlanEvaluation? _evaluation;
  ScanPassPlanResult? _selectedResult;
  ScanPassTimeoutPhase? _timeoutPhase;

  static final ScanPassScenario _practiceScenario =
      ScanPassScenarioLibrary.byId('return-wall-upper').copyWithRoundNumber(0);

  bool get _isPractice => _flow == _ScanPassFlow.practice;

  bool get _isChallenge => _flow == _ScanPassFlow.challenge;

  ScanPassScenario get _scenario =>
      _isPractice ? _practiceScenario : _rounds[_roundIndex];

  int get _currentRoundNumber => _roundIndex + 1;

  ScanPassScanObservation? get _lastScan => _scans.isEmpty ? null : _scans.last;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _observeController = AnimationController(
      vsync: this,
      duration: widget.previewDuration,
    );
    _reviewController = AnimationController(
      vsync: this,
      duration: widget.passAnimationDuration,
    );
    _touchController = AnimationController(vsync: this, value: 1)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _completeFirstTouch();
      });
    _observeController.value = 1;
    _reviewController.value = 1;
    _personalSummary = ScanPassHistoryService(widget.optionRepository).load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimers();
    _observeController.dispose();
    _reviewController.dispose();
    _touchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _pauseActiveRound();
      return;
    }
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }
    if (_executingTouch) {
      unawaited(_touchController.forward());
      return;
    }
    if (_phase == _ScanPassPhase.review && _reviewController.value < 1) {
      unawaited(_reviewController.forward());
      return;
    }
    if (!_isChallenge) return;
    if (_phase == _ScanPassPhase.observe) {
      _observeController.value = 1;
      _beginFirstTouch();
    } else if (_phase == _ScanPassPhase.firstTouch ||
        _phase == _ScanPassPhase.nextAction) {
      if (_remainingChoice == Duration.zero) {
        _handleTimeout(_phase, _phaseToken);
      } else {
        _startDecisionTimer(
          _phase,
          _remainingChoice,
          elapsedBeforeStart: _stageElapsedBeforePause,
        );
      }
    }
  }

  void _pauseActiveRound() {
    if (_isChallenge &&
        (_phase == _ScanPassPhase.firstTouch ||
            _phase == _ScanPassPhase.nextAction) &&
        _choiceClock != null) {
      _stageElapsedBeforePause = _currentDecisionElapsed();
      _remainingChoice = _remainingForElapsed(_stageElapsedBeforePause);
    }
    _observeController.stop();
    _reviewController.stop();
    _touchController.stop();
    _cancelTimers(incrementToken: false);
  }

  void _showIntro() {
    _cancelTimers();
    _observeController
      ..stop()
      ..value = 1;
    _reviewController
      ..stop()
      ..value = 1;
    setState(() {
      _flow = _ScanPassFlow.intro;
      _phase = _ScanPassPhase.observe;
      _rounds = const <ScanPassScenario>[];
      _roundIndex = 0;
      _results.clear();
      _resetRoundState();
      _savingHistory = false;
    });
  }

  void _startPractice() {
    _cancelTimers();
    _observeController
      ..stop()
      ..value = 1;
    _reviewController
      ..stop()
      ..value = 1;
    setState(() {
      _flow = _ScanPassFlow.practice;
      _phase = _ScanPassPhase.observe;
      _rounds = const <ScanPassScenario>[];
      _roundIndex = 0;
      _results.clear();
      _resetRoundState();
      _savingHistory = false;
    });
  }

  void _startSession() {
    final seed = widget.seed ?? DateTime.now().millisecondsSinceEpoch;
    _rounds = ScanPassScenarioLibrary(seed: seed).generateSession();
    _roundIndex = 0;
    _results.clear();
    _savingHistory = false;
    _flow = _ScanPassFlow.challenge;
    _startObserve();
  }

  void _startObserve() {
    _cancelTimers();
    _phaseToken += 1;
    final token = _phaseToken;
    _resetRoundState();
    _observeController
      ..stop()
      ..value = 0;
    _reviewController
      ..stop()
      ..value = 0;
    setState(() {
      _phase = _ScanPassPhase.observe;
      _remainingChoice = widget.choiceDuration;
    });
    if (AppMotion.reduceMotion(context) ||
        widget.previewDuration == Duration.zero) {
      _observeController.value = 1;
    } else {
      unawaited(_observeController.forward(from: 0));
    }
    _phaseTimer = Timer(widget.previewDuration, () {
      if (!mounted || token != _phaseToken) return;
      _beginFirstTouch();
    });
  }

  void _beginFirstTouch() {
    if (_phase != _ScanPassPhase.observe) return;
    _cancelTimers(incrementToken: false);
    setState(() {
      _phase = _ScanPassPhase.firstTouch;
      _remainingChoice = widget.choiceDuration;
      _stageElapsedBeforePause = Duration.zero;
    });
    if (_isChallenge) {
      _startDecisionTimer(_ScanPassPhase.firstTouch, widget.choiceDuration);
    }
  }

  void _startDecisionTimer(
    _ScanPassPhase phase,
    Duration window, {
    Duration elapsedBeforeStart = Duration.zero,
  }) {
    _cancelTimers(incrementToken: false);
    _phaseToken += 1;
    final token = _phaseToken;
    final now = DateTime.now();
    _choiceClock = ScanPassChoiceClock(startedAt: now, choiceWindow: window);
    _stageElapsedBeforePause = elapsedBeforeStart;
    setState(() {
      _phase = phase;
      _remainingChoice = window;
    });
    _choiceTicker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final clock = _choiceClock;
      if (!mounted || token != _phaseToken || clock == null) return;
      final remaining = _remainingForElapsed(_currentDecisionElapsed());
      if (remaining == Duration.zero) {
        _handleTimeout(phase, token);
      } else {
        setState(() => _remainingChoice = remaining);
      }
    });
    _choiceDeadlineTimer = Timer(window, () {
      if (!mounted || token != _phaseToken || _phase != phase) return;
      _handleTimeout(phase, token);
    });
  }

  void _handleTimeout(_ScanPassPhase phase, int token) {
    if (!mounted ||
        !_isChallenge ||
        token != _phaseToken ||
        _phase != phase ||
        (phase != _ScanPassPhase.firstTouch &&
            phase != _ScanPassPhase.nextAction)) {
      return;
    }
    _choiceTicker?.cancel();
    _choiceDeadlineTimer?.cancel();
    final timeoutPhase = phase == _ScanPassPhase.firstTouch
        ? ScanPassTimeoutPhase.firstTouch
        : ScanPassTimeoutPhase.nextAction;
    final phaseElapsed = _currentDecisionElapsed();
    final evaluation = _engine.evaluateAlternatives(
      _scenario,
      firstDecisionTime: phase == _ScanPassPhase.firstTouch
          ? phaseElapsed
          : _firstDecisionTime,
      secondDecisionTime: phase == _ScanPassPhase.nextAction
          ? phaseElapsed
          : widget.choiceDuration,
    );
    _results.add(
      ScanPassRoundResult(
        roundNumber: _currentRoundNumber,
        scenarioId: _scenario.id,
        planId: null,
        chosenScore: 0,
        bestScore: evaluation.bestScore,
        decisionTime: phase == _ScanPassPhase.firstTouch
            ? phaseElapsed
            : _firstDecisionTime + phaseElapsed,
        timedOut: true,
        timeoutPhase: timeoutPhase,
        pressureEarned: 0,
        pressureMax: ScanPassScoreWeights.pressureEscape,
        continuationEarned: 0,
        continuationMax: ScanPassScoreWeights.continuation,
      ),
    );
    HapticFeedback.lightImpact();
    setState(() {
      _timeoutPhase = timeoutPhase;
      _evaluation = evaluation;
      _selectedResult = null;
      _showAlternative = false;
      _remainingChoice = Duration.zero;
      _phase = _ScanPassPhase.review;
    });
    _startReviewAnimation();
  }

  void _recordScan() {
    if (_phase == _ScanPassPhase.review || _phase == _ScanPassPhase.result) {
      return;
    }
    final time = _currentScenarioTime();
    setState(() {
      _scans.add(
        ScanPassScanObservation(
          observedAt: Duration(milliseconds: (time * 1000).round()),
          defenders: _scenario.defendersAt(time),
        ),
      );
    });
    HapticFeedback.selectionClick();
  }

  double _currentScenarioTime() {
    final touch = _firstTouchState;
    if (_executingTouch && touch != null) {
      return touch.touchStartTime +
          (touch.completedAt - touch.touchStartTime) * _touchController.value;
    }
    if (_phase == _ScanPassPhase.observe) {
      return _scenario.ballTravelTime * _observeController.value;
    }
    if (_phase == _ScanPassPhase.firstTouch) {
      final elapsed = _isChallenge ? _currentDecisionElapsed() : Duration.zero;
      return _scenario.ballTravelTime + elapsed.inMilliseconds / 1000;
    }
    if (_phase == _ScanPassPhase.nextAction) {
      final elapsed = _isChallenge ? _currentDecisionElapsed() : Duration.zero;
      return (_firstTouchState?.completedAt ?? _scenario.ballTravelTime) +
          elapsed.inMilliseconds / 1000;
    }
    return _displayedReviewResult?.finalTime ??
        _firstTouchState?.completedAt ??
        _scenario.ballTravelTime;
  }

  void _selectFirstTouch(ScanPassFirstTouch action) {
    if (_phase != _ScanPassPhase.firstTouch || _selectedFirstTouch != null) {
      return;
    }
    final responseTime =
        _isChallenge ? _currentDecisionElapsed() : Duration.zero;
    _cancelTimers(incrementToken: false);
    _phaseToken += 1;
    final state = _engine.applyFirstTouch(
      _scenario,
      action,
      decisionTime: responseTime,
    );
    HapticFeedback.selectionClick();
    setState(() {
      _selectedFirstTouch = action;
      _firstTouchState = state;
      _firstDecisionTime = responseTime;
      _phase = _ScanPassPhase.nextAction;
      _executingTouch = true;
      _remainingChoice = widget.choiceDuration;
      _stageElapsedBeforePause = Duration.zero;
    });
    if (AppMotion.reduceMotion(context) ||
        widget.passAnimationDuration == Duration.zero) {
      _completeFirstTouch();
    } else {
      _touchController.duration = Duration(
        milliseconds: ((state.completedAt - state.touchStartTime) * 1000)
            .round()
            .clamp(1, widget.passAnimationDuration.inMilliseconds),
      );
      unawaited(_touchController.forward(from: 0));
    }
  }

  void _completeFirstTouch() {
    if (!mounted || !_executingTouch || _firstTouchState == null) return;
    setState(() => _executingTouch = false);
    if (_firstTouchState!.ballLost) {
      // No off-ball decision can continue after the return was intercepted.
      _selectNextAction(ScanPassNextAction.holdPocket);
      return;
    }
    if (_isChallenge) {
      _startDecisionTimer(_ScanPassPhase.nextAction, widget.choiceDuration);
    }
  }

  void _selectNextAction(ScanPassNextAction action) {
    if (_phase != _ScanPassPhase.nextAction ||
        _executingTouch ||
        _selectedNextAction != null ||
        _selectedFirstTouch == null) {
      return;
    }
    final responseTime =
        _isChallenge ? _currentDecisionElapsed() : Duration.zero;
    _cancelTimers(incrementToken: false);
    _phaseToken += 1;
    final evaluation = _engine.evaluateAlternatives(
      _scenario,
      selectedFirstTouch: _selectedFirstTouch,
      selectedNextAction: action,
      firstDecisionTime: _firstDecisionTime,
      secondDecisionTime: responseTime,
    );
    final selected = evaluation.selected!;
    if (_isChallenge) {
      _results.add(
        ScanPassRoundResult(
          roundNumber: _currentRoundNumber,
          scenarioId: _scenario.id,
          planId: selected.planId,
          chosenScore: selected.totalScore,
          bestScore: evaluation.bestScore,
          decisionTime: _firstDecisionTime + responseTime,
          pressureEarned: selected
              .component(ScanPassScoreComponentKind.pressureEscape)
              .earned,
          pressureMax:
              selected.component(ScanPassScoreComponentKind.pressureEscape).max,
          continuationEarned: selected
              .component(ScanPassScoreComponentKind.continuation)
              .earned,
          continuationMax:
              selected.component(ScanPassScoreComponentKind.continuation).max,
        ),
      );
    }
    HapticFeedback.selectionClick();
    setState(() {
      _selectedNextAction = action;
      _evaluation = evaluation;
      _selectedResult = selected;
      _showAlternative = false;
      _timeoutPhase = null;
      _phase = _ScanPassPhase.review;
    });
    _startReviewAnimation();
  }

  void _startReviewAnimation() {
    _reviewController
      ..stop()
      ..value = 0;
    if (AppMotion.reduceMotion(context) ||
        widget.passAnimationDuration == Duration.zero) {
      _reviewController.value = 1;
    } else {
      unawaited(_reviewController.forward(from: 0));
    }
  }

  void _toggleReview(bool alternative) {
    if (_phase != _ScanPassPhase.review) return;
    setState(() => _showAlternative = alternative);
    _startReviewAnimation();
  }

  void _advance() {
    if (!_isChallenge || _phase != _ScanPassPhase.review) return;
    if (_results.length >= _roundCount) {
      _showResult();
      return;
    }
    _roundIndex += 1;
    _startObserve();
  }

  void _showResult() {
    _cancelTimers();
    setState(() => _phase = _ScanPassPhase.result);
    _saveHistoryIfNeeded();
  }

  Future<void> _saveHistoryIfNeeded() async {
    if (_savingHistory) return;
    _savingHistory = true;
    final session = ScanPassSessionSummary.fromResults(_results);
    final next = await ScanPassHistoryService(
      widget.optionRepository,
    ).recordSession(session);
    if (!mounted) return;
    setState(() => _personalSummary = next);
  }

  void _resetRoundState() {
    _executingTouch = false;
    _touchController
      ..stop()
      ..value = 1;
    _scans.clear();
    _selectedFirstTouch = null;
    _selectedNextAction = null;
    _firstTouchState = null;
    _evaluation = null;
    _selectedResult = null;
    _timeoutPhase = null;
    _showAlternative = false;
    _firstDecisionTime = Duration.zero;
    _stageElapsedBeforePause = Duration.zero;
  }

  void _cancelTimers({bool incrementToken = true}) {
    if (incrementToken) _phaseToken += 1;
    _phaseTimer?.cancel();
    _phaseTimer = null;
    _choiceTicker?.cancel();
    _choiceTicker = null;
    _choiceDeadlineTimer?.cancel();
    _choiceDeadlineTimer = null;
    _choiceClock = null;
  }

  Duration _currentDecisionElapsed() {
    final liveElapsed =
        _choiceClock?.elapsedAt(DateTime.now()) ?? Duration.zero;
    final elapsed = _stageElapsedBeforePause + liveElapsed;
    return elapsed > widget.choiceDuration ? widget.choiceDuration : elapsed;
  }

  Duration _remainingForElapsed(Duration elapsed) {
    final remaining = widget.choiceDuration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  ScanPassPlanResult? get _displayedReviewResult {
    final evaluation = _evaluation;
    if (evaluation == null) return _selectedResult;
    if (_showAlternative) {
      return evaluation.strongAlternativeFor(_selectedResult) ??
          evaluation.selected ??
          evaluation.bestPlan;
    }
    return _selectedResult ?? evaluation.bestPlan;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _charcoal,
      appBar: AppBar(
        title: Text(l10n.scanPassTitle),
        backgroundColor: _charcoal,
        foregroundColor: _offWhite,
        iconTheme: const IconThemeData(color: _offWhite),
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_flow != _ScanPassFlow.intro)
            AppBarActionButton(
              key: const ValueKey<String>('scan-pass-help-button'),
              tooltip: l10n.scanPassHelpAction,
              onPressed: _showIntro,
              icon: const Icon(Icons.help_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: switch (_flow) {
          _ScanPassFlow.intro => _buildIntro(l10n),
          _ when _phase == _ScanPassPhase.result => _buildResult(l10n),
          _ => _buildRound(l10n),
        },
      ),
    );
  }

  Widget _buildIntro(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 480 || constraints.maxHeight < 640;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, compact ? 14 : 24, 18, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.scanPassIntroTitle,
                    key: const ValueKey<String>('scan-pass-intro-title'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: _offWhite,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.scanPassIntroSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _offWhite.withValues(alpha: 0.78),
                          height: 1.34,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: compact ? 210 : 310,
                    child: _buildField(
                      l10n,
                      key: const ValueKey<String>('scan-pass-intro-field'),
                      scenario: _practiceScenario,
                      phase: _ScanPassPhase.observe,
                      observeProgress: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ScanPassLegend(l10n: l10n),
                  const SizedBox(height: 16),
                  _ScanPassIntroSteps(l10n: l10n),
                  const SizedBox(height: 12),
                  _ScanPassScoringGuide(l10n: l10n),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        key:
                            const ValueKey<String>('scan-pass-practice-button'),
                        onPressed: _startPractice,
                        icon: const Icon(Icons.sports_soccer_outlined),
                        label: Text(l10n.scanPassPracticeAction),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(190, 50),
                        ),
                      ),
                      OutlinedButton.icon(
                        key: const ValueKey<String>(
                          'scan-pass-start-challenge-button',
                        ),
                        onPressed: _startSession,
                        icon: const Icon(Icons.flag_outlined),
                        label: Text(l10n.scanPassStartChallengeAction),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _offWhite,
                          backgroundColor: _surface,
                          side: const BorderSide(color: _line),
                          minimumSize: const Size(190, 50),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRound(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactHeight = constraints.maxHeight < 620;
        final wide =
            constraints.maxWidth >= 900 && constraints.maxHeight >= 520;
        final field = AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[
            _observeController,
            _reviewController,
            _touchController,
          ]),
          builder: (context, _) => _buildField(
            l10n,
            key: const ValueKey<String>('scan-pass-active-field'),
            scenario: _scenario,
            phase: _phase,
            scenarioTime: _currentScenarioTime(),
            observeProgress: _observeController.value,
            reviewProgress: _reviewController.value,
            firstTouchState: _firstTouchState,
            reviewResult:
                _phase == _ScanPassPhase.review ? _displayedReviewResult : null,
            lastScan: _lastScan,
          ),
        );
        final status = Padding(
          padding: EdgeInsets.fromLTRB(16, compactHeight ? 8 : 12, 16, 6),
          child: _buildStatus(l10n),
        );

        if (wide) {
          final panelWidth = math.min(430.0, constraints.maxWidth * 0.38);
          return Column(
            children: [
              status,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  child: Row(
                    key: const ValueKey<String>('scan-pass-wide-layout'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: Center(child: field)),
                      const SizedBox(width: 18),
                      SizedBox(
                        width: panelWidth,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _surface.withValues(alpha: 0.86),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _line),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: _buildPanel(l10n),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        final compactTimed = _isChallenge &&
            (_phase == _ScanPassPhase.observe ||
                _phase == _ScanPassPhase.firstTouch ||
                _phase == _ScanPassPhase.nextAction);
        if (compactTimed) {
          return _buildCompactTimedRound(l10n, field);
        }

        final expectedFieldHeight =
            (constraints.maxWidth - 24) / _ScanPassField.aspectRatio;
        final fieldHeight = expectedFieldHeight
            .clamp(206.0, compactHeight ? 252.0 : 350.0)
            .toDouble();
        return Column(
          children: [
            status,
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: SizedBox(height: fieldHeight, child: Center(child: field)),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _surface.withValues(alpha: 0.70),
                  border: const Border(top: BorderSide(color: _line)),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    compactHeight ? 12 : 18,
                  ),
                  child: _buildPanel(l10n),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactTimedRound(
    AppLocalizations l10n,
    Widget field,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: _buildCompactStatus(l10n),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 6),
            child: Center(child: field),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: _buildCompactTimedPanel(l10n),
        ),
      ],
    );
  }

  Widget _buildCompactStatus(AppLocalizations l10n) {
    final seconds = (_remainingChoice.inMilliseconds / 1000).clamp(0.0, 99.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _phaseHeading(l10n),
                key: const ValueKey<String>('scan-pass-phase-heading'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: _offWhite,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            _ScanPassStatusPill(
              icon: _phase == _ScanPassPhase.observe
                  ? Icons.flag_outlined
                  : Icons.timer_outlined,
              label: _phase == _ScanPassPhase.observe
                  ? l10n.scanPassRoundStatus(_currentRoundNumber, _roundCount)
                  : l10n.scanPassTimeStatus(seconds.toStringAsFixed(1)),
              emphasized: _phase != _ScanPassPhase.observe,
            ),
          ],
        ),
        const SizedBox(height: 7),
        _ScanPassPhaseStrip(phase: _phase, l10n: l10n),
      ],
    );
  }

  Widget _buildCompactTimedPanel(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _regionText(l10n, _scenario.region),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _offWhite.withValues(alpha: 0.72),
                    ),
              ),
            ),
            Expanded(
              child: Text(
                _objectiveText(l10n, _scenario.objective),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _offWhite.withValues(alpha: 0.86),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _instructionText(l10n),
          key: const ValueKey<String>('scan-pass-bottom-text'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _offWhite,
                height: 1.20,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 7),
        _buildScanRow(l10n, compact: true),
        const SizedBox(height: 8),
        switch (_phase) {
          _ScanPassPhase.firstTouch => _buildFirstTouchActions(
              l10n,
              compact: true,
            ),
          _ScanPassPhase.nextAction => _buildNextActions(
              l10n,
              compact: true,
            ),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }

  Widget _buildField(
    AppLocalizations l10n, {
    required Key key,
    required ScanPassScenario scenario,
    required _ScanPassPhase phase,
    double? scenarioTime,
    required double observeProgress,
    double reviewProgress = 1,
    ScanPassFirstTouchState? firstTouchState,
    ScanPassPlanResult? reviewResult,
    ScanPassScanObservation? lastScan,
  }) {
    return Semantics(
      label: l10n.scanPassFieldSemantics,
      image: true,
      child: _ScanPassField(
        key: key,
        scenario: scenario,
        phase: phase,
        scenarioTime: scenarioTime ?? scenario.ballTravelTime * observeProgress,
        observeProgress: observeProgress,
        reviewProgress: reviewProgress,
        firstTouchState: firstTouchState,
        reviewResult: reviewResult,
        lastScan: lastScan,
        fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
      ),
    );
  }

  Widget _buildStatus(AppLocalizations l10n) {
    final seconds = (_remainingChoice.inMilliseconds / 1000).clamp(0.0, 99.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _phaseHeading(l10n),
          key: const ValueKey<String>('scan-pass-phase-heading'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _offWhite,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        _ScanPassPhaseStrip(phase: _phase, l10n: l10n),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            if (_isChallenge)
              _ScanPassStatusPill(
                icon: Icons.flag_outlined,
                label: l10n.scanPassRoundStatus(
                  _currentRoundNumber,
                  _roundCount,
                ),
              )
            else
              _ScanPassStatusPill(
                icon: Icons.school_outlined,
                label: l10n.scanPassPracticeStatus,
              ),
            _ScanPassStatusPill(
              icon: Icons.stadium_outlined,
              label: _regionText(l10n, _scenario.region),
            ),
            _ScanPassStatusPill(
              icon: Icons.track_changes_outlined,
              label: _objectiveText(l10n, _scenario.objective),
            ),
            if (_isChallenge &&
                (_phase == _ScanPassPhase.firstTouch ||
                    _phase == _ScanPassPhase.nextAction))
              _ScanPassStatusPill(
                icon: Icons.timer_outlined,
                label: l10n.scanPassTimeStatus(seconds.toStringAsFixed(1)),
                emphasized: true,
              ),
          ],
        ),
      ],
    );
  }

  String _phaseHeading(AppLocalizations l10n) {
    return switch (_phase) {
      _ScanPassPhase.observe => _isPractice
          ? l10n.scanPassPracticeObserveHeading
          : l10n.scanPassPhaseObserveHeading,
      _ScanPassPhase.firstTouch => _isPractice
          ? l10n.scanPassPracticeFirstTouchHeading
          : l10n.scanPassPhaseFirstTouchHeading,
      _ScanPassPhase.nextAction => _isPractice
          ? l10n.scanPassPracticeNextActionHeading
          : l10n.scanPassPhaseNextActionHeading,
      _ScanPassPhase.review => _isPractice
          ? l10n.scanPassPracticeReviewHeading
          : l10n.scanPassPhaseReviewHeading,
      _ScanPassPhase.result => '',
    };
  }

  Widget _buildPanel(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildScenarioContext(l10n),
        const SizedBox(height: 12),
        Text(
          _instructionText(l10n),
          key: const ValueKey<String>('scan-pass-bottom-text'),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: _offWhite,
                height: 1.34,
                fontWeight: FontWeight.w600,
              ),
        ),
        if (_phase != _ScanPassPhase.review) ...[
          const SizedBox(height: 12),
          _buildScanRow(l10n),
        ],
        const SizedBox(height: 14),
        switch (_phase) {
          _ScanPassPhase.observe => _buildObserveActions(l10n),
          _ScanPassPhase.firstTouch => _buildFirstTouchActions(l10n),
          _ScanPassPhase.nextAction => _buildNextActions(l10n),
          _ScanPassPhase.review => _buildReview(l10n),
          _ScanPassPhase.result => const SizedBox.shrink(),
        },
      ],
    );
  }

  Widget _buildScenarioContext(AppLocalizations l10n) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _phase == _ScanPassPhase.review
                  ? _familyText(l10n, _scenario.family)
                  : l10n.scanPassScenarioContextTitle,
              key: const ValueKey<String>('scan-pass-scenario-family'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: _offWhite,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _ScanPassInlineMarker(
                  icon: Icons.schedule_outlined,
                  label: l10n.scanPassMatchClock(
                    _scenario.matchClockLabel,
                    _scenario.scoreLabel,
                  ),
                ),
                _ScanPassInlineMarker(
                  icon: Icons.map_outlined,
                  label: _regionText(l10n, _scenario.region),
                ),
                _ScanPassInlineMarker(
                  icon: Icons.track_changes_outlined,
                  label: _objectiveText(l10n, _scenario.objective),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanRow(AppLocalizations l10n, {bool compact = false}) {
    final scan = _lastScan;
    final status = scan == null
        ? l10n.scanPassNoScanStatus
        : l10n.scanPassLastScanStatus(
            (scan.observedAt.inMilliseconds / 1000).toStringAsFixed(1),
          );
    return Row(
      children: [
        Expanded(
          child: Text(
            status,
            key: const ValueKey<String>('scan-pass-scan-status'),
            maxLines: compact ? 1 : null,
            overflow: compact ? TextOverflow.ellipsis : null,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _offWhite.withValues(alpha: 0.70),
                  height: 1.24,
                ),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          key: const ValueKey<String>('scan-pass-scan-button'),
          onPressed: _recordScan,
          icon: const Icon(Icons.visibility_outlined),
          label: Text(l10n.scanPassScanAction),
          style: OutlinedButton.styleFrom(
            foregroundColor: _offWhite,
            backgroundColor: _surface,
            side: BorderSide(color: _line.withValues(alpha: 0.92)),
            minimumSize: Size(compact ? 90 : 112, compact ? 40 : 44),
            padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
          ),
        ),
      ],
    );
  }

  Widget _buildObserveActions(AppLocalizations l10n) {
    if (!_isPractice) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerRight,
      child: FilledButton.icon(
        key: const ValueKey<String>('scan-pass-ready-button'),
        onPressed: _beginFirstTouch,
        icon: const Icon(Icons.arrow_forward),
        label: Text(l10n.scanPassPracticeReadyAction),
      ),
    );
  }

  Widget _buildFirstTouchActions(AppLocalizations l10n,
      {bool compact = false}) {
    return _ScanPassActionGrid(
      compact: compact,
      children: [
        _ScanPassActionButton(
          key: const ValueKey<String>('scan-pass-touch-upper'),
          icon: Icons.north_east_outlined,
          title: l10n.scanPassTouchUpperTitle,
          subtitle: l10n.scanPassTouchUpperSubtitle,
          compact: compact,
          onPressed: () => _selectFirstTouch(ScanPassFirstTouch.upperTouch),
        ),
        _ScanPassActionButton(
          key: const ValueKey<String>('scan-pass-touch-lower'),
          icon: Icons.south_east_outlined,
          title: l10n.scanPassTouchLowerTitle,
          subtitle: l10n.scanPassTouchLowerSubtitle,
          compact: compact,
          onPressed: () => _selectFirstTouch(ScanPassFirstTouch.lowerTouch),
        ),
        _ScanPassActionButton(
          key: const ValueKey<String>('scan-pass-touch-turn'),
          icon: Icons.rotate_right_outlined,
          title: l10n.scanPassTouchTurnTitle,
          subtitle: l10n.scanPassTouchTurnSubtitle,
          compact: compact,
          onPressed: () => _selectFirstTouch(ScanPassFirstTouch.turnForward),
        ),
        _ScanPassActionButton(
          key: const ValueKey<String>('scan-pass-touch-return'),
          icon: Icons.keyboard_return_outlined,
          title: l10n.scanPassTouchReturnTitle,
          subtitle: l10n.scanPassTouchReturnSubtitle,
          compact: compact,
          onPressed: () => _selectFirstTouch(ScanPassFirstTouch.returnTo4),
        ),
      ],
    );
  }

  Widget _buildNextActions(AppLocalizations l10n, {bool compact = false}) {
    return IgnorePointer(
      ignoring: _executingTouch,
      child: Opacity(
        opacity: _executingTouch ? 0.45 : 1,
        child: _buildNextActionOptions(l10n, compact: compact),
      ),
    );
  }

  Widget _buildNextActionOptions(AppLocalizations l10n,
      {bool compact = false}) {
    final first = _selectedFirstTouch;
    if (first == null) return const SizedBox.shrink();
    if (first == ScanPassFirstTouch.returnTo4) {
      return _ScanPassActionGrid(
        compact: compact,
        children: [
          _ScanPassActionButton(
            key: const ValueKey<String>('scan-pass-next-support-upper'),
            icon: Icons.north_west_outlined,
            title: l10n.scanPassSupportUpperTitle,
            subtitle: l10n.scanPassSupportUpperSubtitle,
            compact: compact,
            onPressed: () => _selectNextAction(ScanPassNextAction.supportUpper),
          ),
          _ScanPassActionButton(
            key: const ValueKey<String>('scan-pass-next-support-forward'),
            icon: Icons.trending_flat_outlined,
            title: l10n.scanPassSupportForwardTitle,
            subtitle: l10n.scanPassSupportForwardSubtitle,
            compact: compact,
            onPressed: () =>
                _selectNextAction(ScanPassNextAction.supportForward),
          ),
          _ScanPassActionButton(
            key: const ValueKey<String>('scan-pass-next-hold-pocket'),
            icon: Icons.pause_outlined,
            title: l10n.scanPassHoldPocketTitle,
            subtitle: l10n.scanPassHoldPocketSubtitle,
            compact: compact,
            onPressed: () => _selectNextAction(ScanPassNextAction.holdPocket),
          ),
        ],
      );
    }
    return _ScanPassActionGrid(
      compact: compact,
      children: [
        _ScanPassActionButton(
          key: const ValueKey<String>('scan-pass-next-pass-4'),
          icon: Icons.keyboard_return_outlined,
          title: l10n.scanPassPass4Title,
          subtitle: l10n.scanPassPass4Subtitle,
          compact: compact,
          onPressed: () => _selectNextAction(ScanPassNextAction.passTo4),
        ),
        _ScanPassActionButton(
          key: const ValueKey<String>('scan-pass-next-pass-8'),
          icon: Icons.call_made_outlined,
          title: l10n.scanPassPass8Title,
          subtitle: l10n.scanPassPass8Subtitle,
          compact: compact,
          onPressed: () => _selectNextAction(ScanPassNextAction.passTo8),
        ),
        _ScanPassActionButton(
          key: const ValueKey<String>('scan-pass-next-pass-9'),
          icon: Icons.arrow_forward_outlined,
          title: l10n.scanPassPass9Title,
          subtitle: l10n.scanPassPass9Subtitle,
          compact: compact,
          onPressed: () => _selectNextAction(ScanPassNextAction.passTo9),
        ),
        _ScanPassActionButton(
          key: const ValueKey<String>('scan-pass-next-hold-8'),
          icon: Icons.more_time_outlined,
          title: l10n.scanPassHold8Title,
          subtitle: l10n.scanPassHold8Subtitle,
          compact: compact,
          onPressed: () => _selectNextAction(ScanPassNextAction.holdPassTo8),
        ),
      ],
    );
  }

  Widget _buildReview(AppLocalizations l10n) {
    final evaluation = _evaluation;
    final shown = _displayedReviewResult;
    if (evaluation == null || shown == null) return const SizedBox.shrink();
    final selected = _selectedResult;
    return Column(
      key: const ValueKey<String>('scan-pass-review-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selected != null) ...[
          Row(
            children: [
              Expanded(
                child: _ScanPassReviewToggle(
                  key: const ValueKey<String>('scan-pass-review-mine'),
                  selected: !_showAlternative,
                  label: l10n.scanPassReviewMineAction,
                  onPressed: () => _toggleReview(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ScanPassReviewToggle(
                  key: const ValueKey<String>('scan-pass-review-alternative'),
                  selected: _showAlternative,
                  label: l10n.scanPassReviewAlternativeAction,
                  onPressed: () => _toggleReview(true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Text(
          _showAlternative
              ? l10n.scanPassReviewAlternativeTitle
              : _timeoutPhase == null
                  ? l10n.scanPassReviewMineTitle
                  : l10n.scanPassReviewTimeoutTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: _offWhite,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          _reviewSummary(l10n, shown, evaluation),
          key: const ValueKey<String>('scan-pass-review-summary'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _offWhite.withValues(alpha: 0.76),
                height: 1.28,
              ),
        ),
        const SizedBox(height: 12),
        _ScanPassScoreBreakdown(result: shown, l10n: l10n),
        const SizedBox(height: 12),
        _ScanPassReasonPanel(result: shown, l10n: l10n),
        const SizedBox(height: 12),
        _ScanPassPlanComparison(
          evaluation: evaluation,
          selectedPlanId: selected?.planId,
          l10n: l10n,
          actionName: _planName,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.scanPassMethodologyNote,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _offWhite.withValues(alpha: 0.62),
                height: 1.24,
              ),
        ),
        const SizedBox(height: 14),
        if (_isPractice)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                key: const ValueKey<String>('scan-pass-retry-practice-button'),
                onPressed: _startPractice,
                icon: const Icon(Icons.replay),
                label: Text(l10n.scanPassRetryPracticeAction),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _offWhite,
                  backgroundColor: _surface,
                  side: BorderSide(color: _line.withValues(alpha: 0.92)),
                ),
              ),
              FilledButton.icon(
                key: const ValueKey<String>(
                  'scan-pass-practice-start-challenge-button',
                ),
                onPressed: _startSession,
                icon: const Icon(Icons.flag_outlined),
                label: Text(l10n.scanPassStartChallengeAction),
              ),
            ],
          )
        else
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              key: const ValueKey<String>('scan-pass-next-button'),
              onPressed: _advance,
              icon: Icon(
                _results.length >= _roundCount
                    ? Icons.assessment_outlined
                    : Icons.arrow_forward,
              ),
              label: Text(
                _results.length >= _roundCount
                    ? l10n.scanPassSeeResultAction
                    : l10n.scanPassNextRoundAction,
              ),
            ),
          ),
      ],
    );
  }

  String _instructionText(AppLocalizations l10n) {
    return switch (_phase) {
      _ScanPassPhase.observe => _isPractice
          ? l10n.scanPassPracticeObserveInstruction
          : l10n.scanPassObserveInstruction,
      _ScanPassPhase.firstTouch => l10n.scanPassFirstTouchInstruction,
      _ScanPassPhase.nextAction =>
        _selectedFirstTouch == ScanPassFirstTouch.returnTo4
            ? l10n.scanPassNextMoveInstruction
            : l10n.scanPassNextPassInstruction,
      _ScanPassPhase.review => _timeoutPhase == null
          ? l10n.scanPassReviewInstruction
          : _timeoutPhase == ScanPassTimeoutPhase.firstTouch
              ? l10n.scanPassTimeoutFirstTouch
              : l10n.scanPassTimeoutNextAction,
      _ScanPassPhase.result => '',
    };
  }

  String _reviewSummary(
    AppLocalizations l10n,
    ScanPassPlanResult result,
    ScanPassPlanEvaluation evaluation,
  ) {
    final label = _planName(l10n, result);
    final score = result.totalScore;
    final best = evaluation.bestScore;
    final outcome = _outcomeText(l10n, result.outcome);
    if (_timeoutPhase != null && _selectedResult == null) {
      return l10n.scanPassTimeoutReviewSummary(label, score, outcome);
    }
    if (evaluation.isComparableToBest(result)) {
      return l10n.scanPassReviewComparable(label, score, outcome);
    }
    return l10n.scanPassReviewBehind(label, score, best, outcome);
  }

  String _planName(AppLocalizations l10n, ScanPassPlanResult result) {
    if (result.firstTouchState.ballLost) {
      return _firstTouchText(l10n, result.firstTouch);
    }
    return l10n.scanPassPlanName(
      _firstTouchText(l10n, result.firstTouch),
      _nextActionText(l10n, result.nextAction),
    );
  }

  Widget _buildResult(AppLocalizations l10n) {
    final session = ScanPassSessionSummary.fromResults(_results);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _line, width: 1.2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.scanPassResultTitle,
                          key: const ValueKey<String>('scan-pass-result-title'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: _offWhite,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.scanPassResultSubtitle(
                            session.averageScore.round(),
                            session.decisionAccuracyPercent.round(),
                            session.timeouts,
                          ),
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: _offWhite.withValues(alpha: 0.78),
                                    height: 1.28,
                                  ),
                        ),
                        const SizedBox(height: 18),
                        _ScanPassMetricGrid(
                          metrics: [
                            _ScanPassMetricData(
                              label: l10n.scanPassAverageRouteScore,
                              value: session.averageScore.round().toString(),
                            ),
                            _ScanPassMetricData(
                              label: l10n.scanPassDecisionAccuracy,
                              value: l10n.scanPassPercentValue(
                                session.decisionAccuracyPercent.round(),
                              ),
                            ),
                            _ScanPassMetricData(
                              label: l10n.scanPassPressureHandling,
                              value: l10n.scanPassPercentValue(
                                session.pressureHandlingPercent.round(),
                              ),
                            ),
                            _ScanPassMetricData(
                              label: l10n.scanPassContinuation,
                              value: l10n.scanPassPercentValue(
                                session.continuationPercent.round(),
                              ),
                            ),
                            _ScanPassMetricData(
                              label: l10n.scanPassIncompleteRounds,
                              value: session.timeouts.toString(),
                            ),
                            _ScanPassMetricData(
                              label: l10n.scanPassBestAverageRouteScore,
                              value: _personalSummary.bestAverageScore
                                  .round()
                                  .toString(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _ScanPassResultNotes(l10n: l10n),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          key: const ValueKey<String>(
                            'scan-pass-play-again-button',
                          ),
                          onPressed: _startSession,
                          icon: const Icon(Icons.replay),
                          label: Text(l10n.scanPassPlayAgainAction),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScanPassField extends StatelessWidget {
  static const double aspectRatio = 1.58;

  final ScanPassScenario scenario;
  final _ScanPassPhase phase;
  final double scenarioTime;
  final double observeProgress;
  final double reviewProgress;
  final ScanPassFirstTouchState? firstTouchState;
  final ScanPassPlanResult? reviewResult;
  final ScanPassScanObservation? lastScan;
  final String? fontFamily;

  const _ScanPassField({
    super.key,
    required this.scenario,
    required this.phase,
    required this.scenarioTime,
    required this.observeProgress,
    required this.reviewProgress,
    required this.firstTouchState,
    required this.reviewResult,
    required this.lastScan,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(
          constraints.maxWidth,
          constraints.maxHeight * aspectRatio,
        );
        final height = math.min(constraints.maxHeight, width / aspectRatio);
        return SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _ScanPassFieldPainter(
              scenario: scenario,
              phase: phase,
              scenarioTime: scenarioTime,
              observeProgress: observeProgress,
              reviewProgress: reviewProgress,
              firstTouchState: firstTouchState,
              reviewResult: reviewResult,
              lastScan: lastScan,
              fontFamily: fontFamily,
            ),
          ),
        );
      },
    );
  }
}

class _ScanPassFieldPainter extends CustomPainter {
  static const Color _pitch = Color(0xFF31483F);
  static const Color _pitchDark = Color(0xFF293D36);
  static const Color _line = Color(0xFFE0D6C0);
  static const Color _blue = Color(0xFF6F8FAF);
  static const Color _coral = Color(0xFFC77868);
  static const Color _amber = Color(0xFFD6B46C);
  static const Color _offWhite = Color(0xFFF2EFE7);

  final ScanPassScenario scenario;
  final _ScanPassPhase phase;
  final double scenarioTime;
  final double observeProgress;
  final double reviewProgress;
  final ScanPassFirstTouchState? firstTouchState;
  final ScanPassPlanResult? reviewResult;
  final ScanPassScanObservation? lastScan;
  final String? fontFamily;

  const _ScanPassFieldPainter({
    required this.scenario,
    required this.phase,
    required this.scenarioTime,
    required this.observeProgress,
    required this.reviewProgress,
    required this.firstTouchState,
    required this.reviewResult,
    required this.lastScan,
    required this.fontFamily,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final field = Offset.zero & size;
    canvas.drawRRect(
      BorderRadius.circular(8).toRRect(field),
      Paint()..color = _pitch,
    );
    _drawStripes(canvas, size);
    _drawFieldLines(canvas, size);
    final snapshot = _snapshot();
    _drawPaths(canvas, size, snapshot.time);
    _drawDefenders(canvas, size, snapshot);
    _drawAttackers(canvas, size, snapshot);
    _drawBall(canvas, size, snapshot);
  }

  ScanPassMatchSnapshot _snapshot() {
    final result = reviewResult;
    final time = result == null
        ? scenarioTime
        : result.finalTime * reviewProgress.clamp(0.0, 1.0).toDouble();
    return ScanPassTimeline.snapshot(
      scenario: scenario,
      time: time,
      firstTouchState: firstTouchState,
      result: result,
    );
  }

  void _drawStripes(Canvas canvas, Size size) {
    final stripePaint = Paint()..color = _pitchDark.withValues(alpha: 0.24);
    final stripeHeight = size.height / 8;
    for (var i = 0; i < 8; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight),
        stripePaint,
      );
    }
  }

  void _drawFieldLines(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = _line.withValues(alpha: 0.46)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final margin = size.shortestSide * 0.055;
    final inner = Rect.fromLTWH(
      margin,
      margin,
      size.width - (margin * 2),
      size.height - (margin * 2),
    );
    canvas.drawRRect(BorderRadius.circular(6).toRRect(inner), linePaint);
    canvas.drawLine(
      Offset(inner.center.dx, inner.top),
      Offset(inner.center.dx, inner.bottom),
      linePaint,
    );
    canvas.drawCircle(inner.center, size.shortestSide * 0.095, linePaint);
    canvas.drawRect(
      Rect.fromLTWH(
        inner.left,
        inner.center.dy - inner.height * 0.21,
        inner.width * 0.16,
        inner.height * 0.42,
      ),
      linePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        inner.right - inner.width * 0.16,
        inner.center.dy - inner.height * 0.21,
        inner.width * 0.16,
        inner.height * 0.42,
      ),
      linePaint,
    );
    final arrowPaint = Paint()
      ..color = _line.withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final y = inner.top + (inner.height * 0.10);
    final start = Offset(inner.right - inner.width * 0.22, y);
    final end = Offset(inner.right - inner.width * 0.10, y);
    canvas.drawLine(start, end, arrowPaint);
    canvas.drawLine(end, end + const Offset(-7, -5), arrowPaint);
    canvas.drawLine(end, end + const Offset(-7, 5), arrowPaint);
  }

  void _drawPaths(Canvas canvas, Size size, double time) {
    final result = reviewResult;
    final first = firstTouchState;
    final segments = result?.pathSegments ?? first?.pathSegments;
    if (segments == null) return;
    for (final segment in segments) {
      if (time < segment.startTime) continue;
      final localProgress = segment.endTime <= segment.startTime
          ? 1.0
          : ((time - segment.startTime) / (segment.endTime - segment.startTime))
              .clamp(0.0, 1.0)
              .toDouble();
      final paint = Paint()
        ..color = (segment.contested ? _coral : _offWhite).withValues(
          alpha: segment.type == ScanPassPathType.offBallRun ? 0.48 : 0.74,
        )
        ..strokeWidth = segment.type == ScanPassPathType.offBallRun ? 1.8 : 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final from = _toOffset(segment.from, size);
      final visibleTo = segment.from.lerp(segment.to, localProgress);
      final to = _toOffset(visibleTo, size);
      if (segment.type == ScanPassPathType.hold) {
        canvas.drawCircle(from, size.shortestSide * 0.035, paint);
      } else {
        canvas.drawLine(from, to, paint);
        if (localProgress > 0.16) {
          _drawArrowHead(canvas, from, to, paint);
        }
      }
    }
  }

  void _drawDefenders(
    Canvas canvas,
    Size size,
    ScanPassMatchSnapshot snapshot,
  ) {
    if (phase == _ScanPassPhase.review && reviewResult != null) {
      for (final defender in snapshot.defenders) {
        _drawDefender(canvas, size, defender.position, alpha: 0.90);
      }
      return;
    }
    final receiver = snapshot.attacker(ScanPassPlayerRole.midfielder6);
    for (final defender in snapshot.defenders) {
      if (_isVisibleFrontSide(defender.position, receiver)) {
        _drawDefender(canvas, size, defender.position, alpha: 0.82);
      }
    }
    final scan = lastScan;
    if (scan == null) return;
    final scanSnapshot = ScanPassTimeline.snapshot(
      scenario: scenario,
      time: scan.observedAt.inMilliseconds / 1000,
      firstTouchState: firstTouchState,
    );
    final scanReceiver = scanSnapshot.attacker(ScanPassPlayerRole.midfielder6);
    for (final defender in scan.defenders) {
      final current = snapshot.defenders.firstWhere(
        (candidate) => candidate.id == defender.id,
      );
      if (_isVisibleFrontSide(current.position, receiver)) continue;
      if (_isVisibleFrontSide(defender.position, scanReceiver)) continue;
      _drawDefender(canvas, size, defender.position, alpha: 0.42, ghost: true);
    }
  }

  bool _isVisibleFrontSide(ScanPassPoint point, ScanPassPlayer receiver) {
    final delta = point - receiver.position;
    if (delta.distance < 0.01) return true;
    final angle = math.atan2(delta.y, delta.x);
    final diff = _angleDifference(receiver.facingRadians, angle);
    return diff <= math.pi * 0.58;
  }

  void _drawAttackers(
    Canvas canvas,
    Size size,
    ScanPassMatchSnapshot snapshot,
  ) {
    for (final player in snapshot.attackers) {
      _drawPlayer(
        canvas,
        size,
        player,
        fill: player.role == ScanPassPlayerRole.midfielder6 ? _amber : _blue,
        textColor: player.role == ScanPassPlayerRole.midfielder6
            ? const Color(0xFF102135)
            : _offWhite,
        radiusScale: player.role == ScanPassPlayerRole.midfielder6 ? 1.08 : 1,
      );
    }
  }

  void _drawBall(
    Canvas canvas,
    Size size,
    ScanPassMatchSnapshot snapshot,
  ) {
    var center = _toOffset(snapshot.ball, size);
    final radius = math.max(4.0, size.shortestSide * 0.013);
    if (snapshot.ballLost) {
      final markerRadius = radius * 2;
      final markerPaint = Paint()
        ..color = _coral
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(
        center,
        markerRadius + 4,
        Paint()..color = const Color(0xFF101820).withValues(alpha: 0.88),
      );
      canvas.drawLine(
        center + Offset(-markerRadius, -markerRadius),
        center + Offset(markerRadius, markerRadius),
        markerPaint,
      );
      canvas.drawLine(
        center + Offset(-markerRadius, markerRadius),
        center + Offset(markerRadius, -markerRadius),
        markerPaint,
      );
      return;
    }
    final holder = snapshot.ballHolder;
    if (holder != null) {
      final player = snapshot.attacker(holder);
      final playerRadius = math.max(12.0, size.shortestSide * 0.052) *
          (holder == ScanPassPlayerRole.midfielder6 ? 1.08 : 1);
      // Draw a held ball at the player's foot, leaving the number readable.
      center += Offset(
            math.cos(player.facingRadians),
            math.sin(player.facingRadians),
          ) *
          (playerRadius + radius * 0.7);
    }
    canvas.drawCircle(
      center,
      radius + 1.5,
      Paint()..color = const Color(0xFF102135),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = _offWhite,
    );
  }

  void _drawPlayer(
    Canvas canvas,
    Size size,
    ScanPassPlayer player, {
    required Color fill,
    required Color textColor,
    double radiusScale = 1,
  }) {
    final center = _toOffset(player.position, size);
    final radius = math.max(12.0, size.shortestSide * 0.052) * radiusScale;
    canvas.drawCircle(
      center,
      radius + 2,
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
    canvas.drawCircle(center, radius, Paint()..color = fill);
    _drawFacingMarker(canvas, center, radius, player.facingRadians, textColor);
    final painter = TextPainter(
      text: TextSpan(
        text: player.number.toString(),
        style: TextStyle(
          color: textColor,
          fontSize: radius * 0.82,
          fontWeight: FontWeight.w800,
          fontFamily: fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  void _drawDefender(
    Canvas canvas,
    Size size,
    ScanPassPoint point, {
    required double alpha,
    bool ghost = false,
  }) {
    final center = _toOffset(point, size);
    final radius = math.max(10.0, size.shortestSide * 0.044);
    final paint = Paint()
      ..color = _coral.withValues(alpha: alpha)
      ..style = ghost ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = 2.0;
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius, center.dy)
      ..close();
    canvas.drawPath(path, paint);
    if (ghost) {
      canvas.drawCircle(
        center,
        radius + 5,
        Paint()
          ..color = _coral.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  void _drawFacingMarker(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    Color color,
  ) {
    final tip =
        center + Offset(math.cos(angle), math.sin(angle)) * (radius + 6);
    final left = center +
        Offset(math.cos(angle + 0.4), math.sin(angle + 0.4)) * (radius * 0.85);
    final right = center +
        Offset(math.cos(angle - 0.4), math.sin(angle - 0.4)) * (radius * 0.85);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.74));
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Paint paint) {
    final vector = to - from;
    if (vector.distance < 2) return;
    final angle = math.atan2(vector.dy, vector.dx);
    const length = 8.0;
    final left =
        to - Offset(math.cos(angle - 0.55), math.sin(angle - 0.55)) * length;
    final right =
        to - Offset(math.cos(angle + 0.55), math.sin(angle + 0.55)) * length;
    canvas.drawLine(to, left, paint);
    canvas.drawLine(to, right, paint);
  }

  @override
  bool shouldRepaint(covariant _ScanPassFieldPainter oldDelegate) {
    return oldDelegate.scenario != scenario ||
        oldDelegate.phase != phase ||
        oldDelegate.scenarioTime != scenarioTime ||
        oldDelegate.observeProgress != observeProgress ||
        oldDelegate.reviewProgress != reviewProgress ||
        oldDelegate.firstTouchState != firstTouchState ||
        oldDelegate.reviewResult != reviewResult ||
        oldDelegate.lastScan != lastScan ||
        oldDelegate.fontFamily != fontFamily;
  }
}

Offset _toOffset(ScanPassPoint point, Size size) {
  return Offset(point.x * size.width, point.y * size.height);
}

double _angleDifference(double a, double b) {
  final diff = (a - b).abs() % (math.pi * 2);
  return diff > math.pi ? (math.pi * 2) - diff : diff;
}

String _familyText(AppLocalizations l10n, ScanPassScenarioFamily family) {
  return switch (family) {
    ScanPassScenarioFamily.rearPressUpper => l10n.scanPassFamilyRearPress,
    ScanPassScenarioFamily.rearPressLower => l10n.scanPassFamilyRearPress,
    ScanPassScenarioFamily.retreatingPressure =>
      l10n.scanPassFamilyRetreatingPressure,
    ScanPassScenarioFamily.markedSupport => l10n.scanPassFamilyMarkedSupport,
    ScanPassScenarioFamily.closingForwardLane =>
      l10n.scanPassFamilyClosingForwardLane,
    ScanPassScenarioFamily.returnReceive => l10n.scanPassFamilyReturnReceive,
  };
}

class _ScanPassActionGrid extends StatelessWidget {
  final List<Widget> children;
  final bool compact;

  const _ScanPassActionGrid({
    required this.children,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = compact || constraints.maxWidth >= 360 ? 2 : 1;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final child in children)
              SizedBox(
                width: columns == 2
                    ? (constraints.maxWidth - 8) / 2
                    : constraints.maxWidth,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class _ScanPassActionButton extends StatelessWidget {
  static const Color _surfaceAlt = Color(0xFF202B35);
  static const Color _line = Color(0xFF3A4652);
  static const Color _offWhite = Color(0xFFF2EFE7);
  static const Color _amber = Color(0xFFD6B46C);

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final bool compact;

  const _ScanPassActionButton({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: _offWhite,
          backgroundColor: _surfaceAlt,
          side: const BorderSide(color: _line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: EdgeInsets.all(compact ? 9 : 12),
          minimumSize: Size(0, compact ? 58 : 76),
        ),
        child: Row(
          crossAxisAlignment:
              compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _amber, size: compact ? 19 : 20),
            SizedBox(width: compact ? 7 : 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: _offWhite,
                          fontWeight: FontWeight.w700,
                          height: 1.12,
                        ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _offWhite.withValues(alpha: 0.68),
                            height: 1.15,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanPassPhaseStrip extends StatelessWidget {
  static const Color _line = Color(0xFF3A4652);
  static const Color _offWhite = Color(0xFFF2EFE7);
  static const Color _amber = Color(0xFFD6B46C);

  final _ScanPassPhase phase;
  final AppLocalizations l10n;

  const _ScanPassPhaseStrip({required this.phase, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final items = [
      (_ScanPassPhase.observe, l10n.scanPassStageObserve),
      (_ScanPassPhase.firstTouch, l10n.scanPassStageFirstTouch),
      (_ScanPassPhase.nextAction, l10n.scanPassStageNextAction),
      (_ScanPassPhase.review, l10n.scanPassStageReview),
    ];
    return Row(
      children: [
        for (final item in items) ...[
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 2,
                    color: item.$1 == phase ? _amber : _line,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  item.$2,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: item.$1 == phase
                            ? _offWhite
                            : _offWhite.withValues(alpha: 0.56),
                        fontWeight: item.$1 == phase
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                ),
              ),
            ),
          ),
          if (item != items.last) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

class _ScanPassStatusPill extends StatelessWidget {
  static const Color _surface = Color(0xFF17212B);
  static const Color _line = Color(0xFF3A4652);
  static const Color _offWhite = Color(0xFFF2EFE7);
  static const Color _amber = Color(0xFFD6B46C);

  final IconData icon;
  final String label;
  final bool emphasized;

  const _ScanPassStatusPill({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: emphasized
            ? _amber.withValues(alpha: 0.14)
            : _surface.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: emphasized ? _amber.withValues(alpha: 0.72) : _line,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: emphasized ? _amber : _offWhite),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: _offWhite,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanPassLegend extends StatelessWidget {
  static const Color _blue = Color(0xFF6F8FAF);
  static const Color _coral = Color(0xFFC77868);
  static const Color _yellow = Color(0xFFD6B46C);
  static const Color _offWhite = Color(0xFFF2EFE7);

  final AppLocalizations l10n;

  const _ScanPassLegend({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: _offWhite.withValues(alpha: 0.82),
          fontWeight: FontWeight.w600,
        );
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _ScanPassLegendItem(
          color: _yellow,
          label: l10n.scanPassLegendBallCarrier,
          textStyle: style,
        ),
        _ScanPassLegendItem(
          color: _blue,
          label: l10n.scanPassLegendTeammate,
          textStyle: style,
        ),
        _ScanPassLegendItem(
          color: _coral,
          label: l10n.scanPassLegendDefender,
          diamond: true,
          textStyle: style,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_forward, size: 18, color: _offWhite),
            const SizedBox(width: 5),
            Text(l10n.scanPassAttackDirection, style: style),
          ],
        ),
      ],
    );
  }
}

class _ScanPassLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final TextStyle? textStyle;
  final bool diamond;

  const _ScanPassLegendItem({
    required this.color,
    required this.label,
    required this.textStyle,
    this.diamond = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: diamond ? math.pi / 4 : 0,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              shape: diamond ? BoxShape.rectangle : BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFF2EFE7).withValues(alpha: 0.36),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: textStyle),
      ],
    );
  }
}

class _ScanPassIntroSteps extends StatelessWidget {
  final AppLocalizations l10n;

  const _ScanPassIntroSteps({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _ScanPassIntroStep(
        icon: Icons.visibility_outlined,
        title: l10n.scanPassIntroStepObserveTitle,
        body: l10n.scanPassIntroStepObserveBody,
      ),
      _ScanPassIntroStep(
        icon: Icons.touch_app_outlined,
        title: l10n.scanPassIntroStepTouchTitle,
        body: l10n.scanPassIntroStepTouchBody,
      ),
      _ScanPassIntroStep(
        icon: Icons.compare_arrows_outlined,
        title: l10n.scanPassIntroStepCompareTitle,
        body: l10n.scanPassIntroStepCompareBody,
      ),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF17212B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A4652)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 640;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < steps.length; i += 1) ...[
                    Expanded(child: steps[i]),
                    if (i != steps.length - 1) const SizedBox(width: 12),
                  ],
                ],
              );
            }
            return Column(
              children: [
                for (var i = 0; i < steps.length; i += 1) ...[
                  steps[i],
                  if (i != steps.length - 1) const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ScanPassIntroStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _ScanPassIntroStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFD6B46C), size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFFF2EFE7),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFF2EFE7).withValues(alpha: 0.72),
                      height: 1.25,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScanPassScoringGuide extends StatelessWidget {
  static const Color _surface = Color(0xFF17212B);
  static const Color _line = Color(0xFF3A4652);
  static const Color _offWhite = Color(0xFFF2EFE7);
  static const Color _amber = Color(0xFFD6B46C);

  final AppLocalizations l10n;

  const _ScanPassScoringGuide({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: _offWhite,
          fontWeight: FontWeight.w700,
        );
    final bodyStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: _offWhite.withValues(alpha: 0.72),
          height: 1.28,
        );
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: _amber.withValues(alpha: 0.08),
        highlightColor: _amber.withValues(alpha: 0.08),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _line),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          iconColor: _offWhite,
          collapsedIconColor: _offWhite.withValues(alpha: 0.72),
          title: Text(l10n.scanPassIntroScoringGuideTitle, style: titleStyle),
          subtitle:
              Text(l10n.scanPassIntroScoringGuideSummary, style: bodyStyle),
          children: [
            _ScanPassGuideLine(
              icon: Icons.analytics_outlined,
              text: l10n.scanPassScoringGuideDecision,
            ),
            _ScanPassGuideLine(
              icon: Icons.timer_outlined,
              text: l10n.scanPassScoringGuideReaction,
            ),
            _ScanPassGuideLine(
              icon: Icons.school_outlined,
              text: l10n.scanPassScoringGuidePractice,
            ),
            _ScanPassGuideLine(
              icon: Icons.info_outline,
              text: l10n.scanPassScoringGuideMethod,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanPassGuideLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ScanPassGuideLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFD6B46C), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFF2EFE7).withValues(alpha: 0.74),
                    height: 1.28,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanPassReviewToggle extends StatelessWidget {
  static const Color _surfaceAlt = Color(0xFF202B35);
  static const Color _line = Color(0xFF3A4652);
  static const Color _offWhite = Color(0xFFF2EFE7);
  static const Color _amber = Color(0xFFD6B46C);

  final bool selected;
  final String label;
  final VoidCallback onPressed;

  const _ScanPassReviewToggle({
    super.key,
    required this.selected,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? _amber : _offWhite,
        backgroundColor:
            selected ? _amber.withValues(alpha: 0.12) : _surfaceAlt,
        side: BorderSide(color: selected ? _amber : _line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        minimumSize: const Size(0, 44),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ScanPassScoreBreakdown extends StatelessWidget {
  static const Color _surfaceAlt = Color(0xFF202B35);
  static const Color _line = Color(0xFF3A4652);
  static const Color _offWhite = Color(0xFFF2EFE7);

  final ScanPassPlanResult result;
  final AppLocalizations l10n;

  const _ScanPassScoreBreakdown({
    required this.result,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.scanPassScoreBreakdownTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _offWhite,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Text(
                  l10n.scanPassComponentValue(
                    result.totalScore,
                    ScanPassScoreWeights.total,
                  ),
                  key: const ValueKey<String>('scan-pass-total-score'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: _offWhite,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final component in result.components) ...[
              _ScanPassComponentRow(component: component, l10n: l10n),
              if (component != result.components.last)
                const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScanPassComponentRow extends StatelessWidget {
  static const Color _line = Color(0xFF3A4652);
  static const Color _offWhite = Color(0xFFF2EFE7);
  static const Color _amber = Color(0xFFD6B46C);

  final ScanPassScoreComponent component;
  final AppLocalizations l10n;

  const _ScanPassComponentRow({
    required this.component,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey<String>('scan-pass-component-${component.kind.name}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _componentLabel(l10n, component.kind),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _offWhite,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Text(
              l10n.scanPassComponentValue(component.earned, component.max),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _offWhite,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            minHeight: 5,
            value: (component.earned / component.max).clamp(0.0, 1.0),
            backgroundColor: _line,
            valueColor: AlwaysStoppedAnimation<Color>(
              component.earned >= component.max * 0.72
                  ? _amber
                  : _offWhite.withValues(
                      alpha: component.earned >= component.max * 0.48
                          ? 0.58
                          : 0.38,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanPassReasonPanel extends StatelessWidget {
  static const Color _line = Color(0xFF3A4652);
  static const Color _offWhite = Color(0xFFF2EFE7);
  static const Color _amber = Color(0xFFD6B46C);

  final ScanPassPlanResult result;
  final AppLocalizations l10n;

  const _ScanPassReasonPanel({
    required this.result,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final reasons = result.reasons.take(4).toList(growable: false);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _line.withValues(alpha: 0.82)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.scanPassReasonPanelTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: _offWhite,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            for (final reason in reasons) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.remove, size: 14, color: _amber),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _reasonText(l10n, reason),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _offWhite.withValues(alpha: 0.72),
                            height: 1.26,
                          ),
                    ),
                  ),
                ],
              ),
              if (reason != reasons.last) const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScanPassPlanComparison extends StatelessWidget {
  static const Color _surfaceAlt = Color(0xFF202B35);
  static const Color _line = Color(0xFF3A4652);
  static const Color _offWhite = Color(0xFFF2EFE7);
  static const Color _amber = Color(0xFFD6B46C);

  final ScanPassPlanEvaluation evaluation;
  final String? selectedPlanId;
  final AppLocalizations l10n;
  final String Function(AppLocalizations, ScanPassPlanResult) actionName;

  const _ScanPassPlanComparison({
    required this.evaluation,
    required this.selectedPlanId,
    required this.l10n,
    required this.actionName,
  });

  @override
  Widget build(BuildContext context) {
    final plans = List<ScanPassPlanResult>.from(evaluation.alternatives)
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));
    final shown = plans.take(4).toList(growable: false);
    return Column(
      key: const ValueKey<String>('scan-pass-route-comparison'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.scanPassRouteComparisonTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: _offWhite,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        for (final plan in shown) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: plan.planId == selectedPlanId
                  ? _amber.withValues(alpha: 0.12)
                  : _surfaceAlt,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: plan.planId == selectedPlanId ? _amber : _line,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      actionName(l10n, plan),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _offWhite,
                            fontWeight: FontWeight.w700,
                            height: 1.18,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.scanPassComponentValue(
                      plan.totalScore,
                      ScanPassScoreWeights.total,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _offWhite,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (plan != shown.last) const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _ScanPassInlineMarker extends StatelessWidget {
  static const Color _offWhite = Color(0xFFF2EFE7);
  static const Color _amber = Color(0xFFD6B46C);

  final IconData icon;
  final String label;

  const _ScanPassInlineMarker({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _amber, size: 14),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: _offWhite.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _ScanPassResultNotes extends StatelessWidget {
  static const Color _line = Color(0xFF3A4652);
  static const Color _offWhite = Color(0xFFF2EFE7);
  static const Color _amber = Color(0xFFD6B46C);

  final AppLocalizations l10n;

  const _ScanPassResultNotes({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final notes = [
      l10n.scanPassResultAverageScoreNote,
      l10n.scanPassResultAccuracyNote,
      l10n.scanPassResultTimeoutNote,
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.scanPassResultMethodTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: _offWhite,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            for (final note in notes) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.remove, size: 14, color: _amber),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _offWhite.withValues(alpha: 0.70),
                            height: 1.26,
                          ),
                    ),
                  ),
                ],
              ),
              if (note != notes.last) const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScanPassMetricData {
  final String label;
  final String value;

  const _ScanPassMetricData({required this.label, required this.value});
}

class _ScanPassMetricGrid extends StatelessWidget {
  static const Color _surfaceAlt = Color(0xFF202B35);
  static const Color _line = Color(0xFF3A4652);
  static const Color _offWhite = Color(0xFFF2EFE7);

  final List<_ScanPassMetricData> metrics;

  const _ScanPassMetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 460 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: columns == 3 ? 2.15 : 1.75,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return DecoratedBox(
              decoration: BoxDecoration(
                color: _surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _line),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        metric.value,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: _offWhite,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metric.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: _offWhite.withValues(alpha: 0.70),
                            height: 1.05,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

String _regionText(AppLocalizations l10n, ScanPassFieldRegion region) {
  return switch (region) {
    ScanPassFieldRegion.centralMidfield => l10n.scanPassRegionCentralMidfield,
    ScanPassFieldRegion.leftHalfSpace => l10n.scanPassRegionLeftHalfSpace,
    ScanPassFieldRegion.rightHalfSpace => l10n.scanPassRegionRightHalfSpace,
    ScanPassFieldRegion.defensiveThird => l10n.scanPassRegionDefensiveThird,
    ScanPassFieldRegion.attackingHalf => l10n.scanPassRegionAttackingHalf,
  };
}

String _objectiveText(AppLocalizations l10n, ScanPassMatchObjective objective) {
  return switch (objective) {
    ScanPassMatchObjective.protectPossession =>
      l10n.scanPassObjectiveProtectPossession,
    ScanPassMatchObjective.chaseGoal => l10n.scanPassObjectiveChaseGoal,
  };
}

String _firstTouchText(AppLocalizations l10n, ScanPassFirstTouch touch) {
  return switch (touch) {
    ScanPassFirstTouch.upperTouch => l10n.scanPassTouchUpperShort,
    ScanPassFirstTouch.lowerTouch => l10n.scanPassTouchLowerShort,
    ScanPassFirstTouch.turnForward => l10n.scanPassTouchTurnShort,
    ScanPassFirstTouch.returnTo4 => l10n.scanPassTouchReturnShort,
  };
}

String _nextActionText(AppLocalizations l10n, ScanPassNextAction action) {
  return switch (action) {
    ScanPassNextAction.passTo4 => l10n.scanPassPass4Short,
    ScanPassNextAction.passTo8 => l10n.scanPassPass8Short,
    ScanPassNextAction.passTo9 => l10n.scanPassPass9Short,
    ScanPassNextAction.holdPassTo8 => l10n.scanPassHold8Short,
    ScanPassNextAction.supportUpper => l10n.scanPassSupportUpperShort,
    ScanPassNextAction.supportForward => l10n.scanPassSupportForwardShort,
    ScanPassNextAction.holdPocket => l10n.scanPassHoldPocketShort,
  };
}

String _componentLabel(
  AppLocalizations l10n,
  ScanPassScoreComponentKind kind,
) {
  return switch (kind) {
    ScanPassScoreComponentKind.control => l10n.scanPassComponentControl,
    ScanPassScoreComponentKind.pressureEscape =>
      l10n.scanPassComponentPressureEscape,
    ScanPassScoreComponentKind.continuation =>
      l10n.scanPassComponentContinuation,
    ScanPassScoreComponentKind.contextFit => l10n.scanPassComponentContextFit,
  };
}

String _outcomeText(AppLocalizations l10n, ScanPassOutcomeType outcome) {
  return switch (outcome) {
    ScanPassOutcomeType.kept => l10n.scanPassOutcomeKept,
    ScanPassOutcomeType.progressed => l10n.scanPassOutcomeProgressed,
    ScanPassOutcomeType.recycled => l10n.scanPassOutcomeRecycled,
    ScanPassOutcomeType.contested => l10n.scanPassOutcomeContested,
    ScanPassOutcomeType.intercepted => l10n.scanPassOutcomeIntercepted,
    ScanPassOutcomeType.timeout => l10n.scanPassOutcomeTimeout,
  };
}

String _reasonText(AppLocalizations l10n, ScanPassReason reason) {
  return switch (reason) {
    ScanPassReason.controlledFirstTouch => l10n.scanPassReasonControlledTouch,
    ScanPassReason.exposedFirstTouch => l10n.scanPassReasonExposedTouch,
    ScanPassReason.pressureEscaped => l10n.scanPassReasonPressureEscaped,
    ScanPassReason.pressureStayed => l10n.scanPassReasonPressureStayed,
    ScanPassReason.clearLane => l10n.scanPassReasonClearLane,
    ScanPassReason.laneClosed => l10n.scanPassReasonPressuredLane,
    ScanPassReason.receiverAvailable => l10n.scanPassReasonReceiverAvailable,
    ScanPassReason.receiverCrowded => l10n.scanPassReasonTightReceiver,
    ScanPassReason.supportAngleCreated =>
      l10n.scanPassReasonSupportAngleCreated,
    ScanPassReason.supportAngleWeak => l10n.scanPassReasonSupportAngleWeak,
    ScanPassReason.holdOpenedLane => l10n.scanPassReasonHoldOpenedLane,
    ScanPassReason.holdInvitedPressure =>
      l10n.scanPassReasonHoldInvitedPressure,
    ScanPassReason.objectiveProtected => l10n.scanPassReasonObjectiveProtected,
    ScanPassReason.objectiveProgressed =>
      l10n.scanPassReasonObjectiveProgressed,
  };
}
