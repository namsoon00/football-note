import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../../domain/repositories/option_repository.dart';
import '../../domain/scan_pass/scan_pass_game.dart';
import '../theme/app_motion.dart';
import '../widgets/app_bar_action_button.dart';
import 'scan_pass_learning_intent.dart';

enum _ScanPassFlow { intro, learning }

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
  static const int _sessionSceneCount = ScanPassScenarioLibrary.roundCount;
  static final ScanPassScenario _openingScenario =
      ScanPassScenarioLibrary.byId('rear-upper-protect').copyWithRoundNumber(1);

  final ScanPassMatchEngine _engine = const ScanPassMatchEngine();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _fieldAnchor = GlobalKey();
  final GlobalKey _choicesAnchor = GlobalKey();

  late final AnimationController _receiveController;
  late final AnimationController _touchController;
  late final AnimationController _reviewController;

  List<ScanPassScenario> _rounds = <ScanPassScenario>[_openingScenario];
  _ScanPassFlow _flow = _ScanPassFlow.intro;
  _ScanPassPhase _phase = _ScanPassPhase.observe;
  int _roundIndex = 0;
  final Set<int> _reviewedScenes = <int>{};
  bool _helpOpen = false;
  bool _foreground = true;
  bool _scanned = false;
  bool _receiving = false;
  bool _executingTouch = false;
  bool _showAlternative = false;
  ScanPassScanObservation? _scan;
  ScanPassFirstTouch? _previewFirstTouch;
  ScanPassFirstTouchState? _previewFirstTouchState;
  ScanPassFirstTouch? _selectedFirstTouch;
  ScanPassFirstTouchState? _firstTouchState;
  ScanPassNextAction? _previewNextAction;
  List<ScanPassLearningIntent> _previewNextIntents =
      const <ScanPassLearningIntent>[];
  ScanPassPlanEvaluation? _evaluation;
  ScanPassPlanResult? _selectedResult;

  ScanPassScenario get _scenario => _rounds[_roundIndex];

  ScanPassPlanResult? get _displayedReviewResult {
    final evaluation = _evaluation;
    if (evaluation == null) return _selectedResult;
    if (_showAlternative) {
      return evaluation.strongAlternativeFor(_selectedResult) ??
          evaluation.bestPlan;
    }
    return _selectedResult ?? evaluation.bestPlan;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _receiveController = AnimationController(
      vsync: this,
      duration: widget.previewDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _completeReceive();
      });
    _touchController = AnimationController(vsync: this, value: 1)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _completeFirstTouch();
      });
    _reviewController = AnimationController(
      vsync: this,
      duration: widget.passAnimationDuration,
      value: 1,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _receiveController.dispose();
    _touchController.dispose();
    _reviewController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _foreground = false;
      _receiveController.stop();
      _touchController.stop();
      _reviewController.stop();
      return;
    }
    if (state != AppLifecycleState.resumed || !mounted) return;
    _foreground = true;
    if (_helpOpen) return;
    if (_receiving) {
      unawaited(_receiveController.forward());
    } else if (_executingTouch) {
      unawaited(_touchController.forward());
    } else if (_phase == _ScanPassPhase.review && _reviewController.value < 1) {
      unawaited(_reviewController.forward());
    }
  }

  void _startOpeningScene() {
    _startLearning(_buildOpeningRoundSet());
  }

  void _startDifferentScene() {
    final seed = widget.seed ?? DateTime.now().millisecondsSinceEpoch;
    final generated =
        ScanPassScenarioLibrary(seed: seed).generateSession(count: 12);
    final rotated = <ScanPassScenario>[
      ...generated.where((scenario) => scenario.id != _openingScenario.id),
      _openingScenario.copyWithRoundNumber(generated.length),
    ];
    _startLearning(
      [
        for (var i = 0; i < _sessionSceneCount; i += 1)
          rotated[i % rotated.length].copyWithRoundNumber(i + 1),
      ],
    );
  }

  List<ScanPassScenario> _buildOpeningRoundSet() {
    final seed = widget.seed ?? 7;
    final generated =
        ScanPassScenarioLibrary(seed: seed).generateSession(count: 12);
    final rest =
        generated.where((scenario) => scenario.id != _openingScenario.id);
    return <ScanPassScenario>[
      _openingScenario,
      for (final indexed in rest.take(_sessionSceneCount - 1).indexed)
        indexed.$2.copyWithRoundNumber(indexed.$1 + 2),
    ];
  }

  void _startLearning(List<ScanPassScenario> rounds) {
    setState(() {
      _flow = _ScanPassFlow.learning;
      _rounds = rounds;
      _roundIndex = 0;
      _reviewedScenes.clear();
      _resetSceneState();
    });
    _scrollToTop();
  }

  void _retryScene() {
    setState(_resetSceneState);
    _scrollToTop();
  }

  void _nextScene() {
    if (_phase != _ScanPassPhase.review) return;
    if (_roundIndex + 1 >= _rounds.length) {
      setState(() => _phase = _ScanPassPhase.result);
      _scrollToTop();
      return;
    }
    setState(() {
      _roundIndex += 1;
      _resetSceneState();
    });
    _scrollToTop();
  }

  void _resetSceneState() {
    _phase = _ScanPassPhase.observe;
    _scanned = false;
    _receiving = false;
    _executingTouch = false;
    _showAlternative = false;
    _scan = null;
    _previewFirstTouch = null;
    _previewFirstTouchState = null;
    _selectedFirstTouch = null;
    _firstTouchState = null;
    _previewNextAction = null;
    _previewNextIntents = const <ScanPassLearningIntent>[];
    _evaluation = null;
    _selectedResult = null;
    _receiveController
      ..stop()
      ..value = 0;
    _touchController
      ..stop()
      ..value = 1;
    _reviewController
      ..stop()
      ..value = 1;
  }

  void _recordScan() {
    if (_phase != _ScanPassPhase.observe || _receiving) return;
    final time = _observationTime(_scenario);
    setState(() {
      _scanned = true;
      _scan = ScanPassScanObservation(
        observedAt: Duration(milliseconds: (time * 1000).round()),
        defenders: _scenario.defendersAt(time),
      );
    });
    HapticFeedback.selectionClick();
    _showChoicePreview();
  }

  void _receiveBall() {
    if (!_scanned || _phase != _ScanPassPhase.observe || _receiving) return;
    HapticFeedback.selectionClick();
    setState(() => _receiving = true);
    _receiveController.duration = widget.previewDuration;
    if (AppMotion.reduceMotion(context) ||
        widget.previewDuration == Duration.zero) {
      _receiveController.value = 1;
      _completeReceive();
    } else {
      unawaited(_receiveController.forward(from: 0));
    }
    _scrollToTop();
  }

  void _completeReceive() {
    if (!mounted || !_receiving) return;
    setState(() {
      _receiving = false;
      _phase = _ScanPassPhase.firstTouch;
    });
    _scrollToTop();
  }

  void _previewFirstTouchAction(ScanPassFirstTouch action) {
    if (_phase != _ScanPassPhase.firstTouch || _executingTouch) return;
    setState(() {
      _previewFirstTouch = action;
      _previewFirstTouchState = _engine.applyFirstTouch(
        _scenario,
        action,
        decisionTime: Duration.zero,
      );
    });
    HapticFeedback.selectionClick();
    _showChoicePreview();
  }

  void _executeFirstTouch() {
    if (_phase != _ScanPassPhase.firstTouch ||
        _previewFirstTouch == null ||
        _previewFirstTouchState == null) {
      return;
    }
    final state = _previewFirstTouchState!;
    setState(() {
      _selectedFirstTouch = _previewFirstTouch;
      _firstTouchState = state;
      _previewFirstTouch = null;
      _previewFirstTouchState = null;
      _phase = _ScanPassPhase.nextAction;
      _executingTouch = true;
      _previewNextAction = null;
      _previewNextIntents = const <ScanPassLearningIntent>[];
    });
    HapticFeedback.mediumImpact();
    if (AppMotion.reduceMotion(context) ||
        widget.passAnimationDuration == Duration.zero) {
      _touchController.value = 1;
      _completeFirstTouch();
    } else {
      _touchController.duration = Duration(
        milliseconds: ((state.completedAt - state.touchStartTime) * 1000)
            .round()
            .clamp(1, widget.passAnimationDuration.inMilliseconds),
      );
      unawaited(_touchController.forward(from: 0));
    }
    _scrollToTop();
  }

  void _completeFirstTouch() {
    if (!mounted || !_executingTouch || _firstTouchState == null) return;
    setState(() => _executingTouch = false);
    if (_firstTouchState!.ballLost) {
      _commitNextAction(ScanPassNextAction.holdPocket);
    }
  }

  void _previewNextActionChoice(ScanPassNextAction action) {
    final first = _selectedFirstTouch;
    final firstState = _firstTouchState;
    if (_phase != _ScanPassPhase.nextAction ||
        _executingTouch ||
        first == null ||
        firstState == null ||
        firstState.ballLost) {
      return;
    }
    setState(() {
      _previewNextAction = action;
      _previewNextIntents = ScanPassLearningIntent.nextAction(
        firstState,
        action,
      );
    });
    HapticFeedback.selectionClick();
    _showChoicePreview();
  }

  void _executeNextAction() {
    final action = _previewNextAction;
    if (action == null) return;
    _commitNextAction(action);
  }

  void _commitNextAction(ScanPassNextAction action) {
    if (_phase != _ScanPassPhase.nextAction ||
        _executingTouch ||
        _selectedResult != null) {
      return;
    }
    final first = _selectedFirstTouch;
    if (first == null) return;
    final evaluation = _engine.evaluateAlternatives(
      _scenario,
      selectedFirstTouch: first,
      selectedNextAction: action,
      firstDecisionTime: Duration.zero,
      secondDecisionTime: Duration.zero,
    );
    setState(() {
      _evaluation = evaluation;
      _selectedResult = evaluation.selected;
      _previewNextAction = null;
      _previewNextIntents = const <ScanPassLearningIntent>[];
      _showAlternative = false;
      _phase = _ScanPassPhase.review;
      _reviewedScenes.add(_roundIndex);
    });
    HapticFeedback.mediumImpact();
    _startReviewAnimation();
    _scrollToTop();
  }

  void _toggleReview(bool alternative) {
    if (_phase != _ScanPassPhase.review) return;
    setState(() => _showAlternative = alternative);
    _startReviewAnimation();
    _scrollToTop();
  }

  void _startReviewAnimation() {
    _reviewController.duration = widget.passAnimationDuration;
    if (AppMotion.reduceMotion(context) ||
        widget.passAnimationDuration == Duration.zero) {
      _reviewController.value = 1;
    } else {
      _reviewController
        ..stop()
        ..value = 0;
      unawaited(_reviewController.forward());
    }
  }

  void _showHelp() {
    if (_helpOpen) return;
    _helpOpen = true;
    final l10n = AppLocalizations.of(context)!;
    final resumeReceive = _receiving && _receiveController.isAnimating;
    final resumeTouch = _executingTouch && _touchController.isAnimating;
    final resumeReview =
        _phase == _ScanPassPhase.review && _reviewController.isAnimating;
    _receiveController.stop();
    _touchController.stop();
    _reviewController.stop();
    unawaited(showDialog<void>(
      context: context,
      builder: (context) {
        final colors = _ScanPassColors.of(context);
        return AlertDialog(
          backgroundColor: colors.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(l10n.scanPassHelpSheetTitle),
          content: Text(
            l10n.scanPassHelpSheetBody,
            style: TextStyle(color: colors.muted, height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.scanPassHelpCloseAction),
            ),
          ],
        );
      },
    ).then((_) {
      if (!mounted) return;
      _helpOpen = false;
      if (!_foreground) return;
      if (resumeReceive && _receiving) {
        unawaited(_receiveController.forward());
      } else if (resumeTouch && _executingTouch) {
        unawaited(_touchController.forward());
      } else if (resumeReview &&
          _phase == _ScanPassPhase.review &&
          _reviewController.value < 1) {
        unawaited(_reviewController.forward());
      }
    }));
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (AppMotion.reduceMotion(context)) {
        _scrollController.jumpTo(0);
        return;
      }
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _showChoicePreview() {
    if (!_usesStickyExecuteBar(context)) return;
    _scrollToAnchor(_fieldAnchor);
  }

  void _changeChoice() {
    setState(() {
      _previewFirstTouch = null;
      _previewFirstTouchState = null;
      _previewNextAction = null;
      _previewNextIntents = const <ScanPassLearningIntent>[];
    });
    _scrollToAnchor(_choicesAnchor);
  }

  void _scrollToAnchor(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || key.currentContext == null) return;
      Scrollable.ensureVisible(
        key.currentContext!,
        alignment: 0.02,
        duration: AppMotion.reduceMotion(context)
            ? Duration.zero
            : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = _ScanPassColors.of(context);
    return Theme(
      data: Theme.of(context).copyWith(
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: colors.text,
            foregroundColor: colors.background,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: Text(l10n.scanPassTitle),
          backgroundColor: colors.surface,
          foregroundColor: colors.text,
          iconTheme: IconThemeData(color: colors.text),
          surfaceTintColor: Colors.transparent,
          actions: [
            AppBarActionButton(
              key: const ValueKey<String>('scan-pass-help-button'),
              tooltip: l10n.scanPassHelpAction,
              onPressed: _showHelp,
              icon: const Icon(Icons.help_outline),
            ),
          ],
        ),
        bottomNavigationBar: _buildStickyExecuteBar(l10n),
        body: SafeArea(
          child: switch (_flow) {
            _ScanPassFlow.intro => _buildIntro(l10n),
            _ScanPassFlow.learning when _phase == _ScanPassPhase.result =>
              _buildResult(l10n),
            _ScanPassFlow.learning => _buildLearning(l10n),
          },
        ),
      ),
    );
  }

  Widget? _buildStickyExecuteBar(AppLocalizations l10n) {
    if (!_usesStickyExecuteBar(context)) return null;
    final colors = _ScanPassColors.of(context);
    final VoidCallback? onPressed;
    final Key key;
    final String choice;
    if (_phase == _ScanPassPhase.firstTouch && _previewFirstTouch != null) {
      onPressed = _executeFirstTouch;
      key = const ValueKey<String>('scan-pass-execute-first-touch');
      choice = _firstTouchText(l10n, _previewFirstTouch!);
    } else if (_phase == _ScanPassPhase.nextAction &&
        !_executingTouch &&
        _previewNextAction != null) {
      onPressed = _executeNextAction;
      key = const ValueKey<String>('scan-pass-execute-next-action');
      choice = _nextActionText(l10n, _previewNextAction!);
    } else {
      return null;
    }
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.line)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(choice,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: colors.text, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(children: [
                TextButton(
                  key: const ValueKey<String>('scan-pass-change-choice'),
                  onPressed: _changeChoice,
                  style: TextButton.styleFrom(
                      foregroundColor: colors.text,
                      minimumSize: const Size(0, 48)),
                  child: Text(l10n.scanPassChangeChoiceAction),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: FilledButton.icon(
                  key: key,
                  onPressed: onPressed,
                  icon: const Icon(Icons.play_arrow_outlined),
                  label: Text(l10n.scanPassExecuteChoiceAction),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                  ),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  bool _usesStickyExecuteBar(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width < 900 || size.height < 616;
  }

  Widget _buildIntro(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1060),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSceneContext(
                    l10n,
                    scenario: _openingScenario,
                    trailing: l10n.scanPassIntroPreviewLabel,
                  ),
                  const SizedBox(height: 12),
                  _ScanPassPhaseStrip(
                    phase: _ScanPassPhase.observe,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 18),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 430,
                            child: _buildField(
                              l10n,
                              key: const ValueKey<String>(
                                'scan-pass-intro-field',
                              ),
                              scenario: _openingScenario,
                              phase: _ScanPassPhase.observe,
                              scanned: false,
                              receiveProgress: 0,
                              previewNextIntents: const <ScanPassLearningIntent>[],
                            ),
                          ),
                        ),
                        const SizedBox(width: 22),
                        SizedBox(width: 320, child: _buildIntroPanel(l10n)),
                      ],
                    )
                  else ...[
                    AspectRatio(
                      aspectRatio: _ScanPassField.aspectRatio,
                      child: _buildField(
                        l10n,
                        key: const ValueKey<String>('scan-pass-intro-field'),
                        scenario: _openingScenario,
                        phase: _ScanPassPhase.observe,
                        scanned: false,
                        receiveProgress: 0,
                        previewNextIntents: const <ScanPassLearningIntent>[],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildIntroPanel(l10n),
                  ],
                  const SizedBox(height: 14),
                  _ScanPassLegend(l10n: l10n),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIntroPanel(AppLocalizations l10n) {
    final colors = _ScanPassColors.of(context);
    return _PanelBody(
      children: [
        _PhaseLabel(text: l10n.scanPassObservePhaseLabel),
        Text(
          l10n.scanPassIntroSceneQuestion,
          key: const ValueKey<String>('scan-pass-intro-title'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w600,
                height: 1.18,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.scanPassIntroSceneTask,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.muted,
                height: 1.30,
              ),
        ),
        const SizedBox(height: 16),
        _FactList(
          rows: [
            _FactRowData(
              label: l10n.scanPassFactMyPlayer,
              value: l10n.scanPassFactMyPlayerValue,
            ),
            _FactRowData(
              label: l10n.scanPassFactPasser,
              value: l10n.scanPassFactPasserValue,
            ),
            _FactRowData(
              label: l10n.scanPassFactAttackDirection,
              value: l10n.scanPassFactAttackRight,
            ),
          ],
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          key: const ValueKey<String>('scan-pass-understand-scene-button'),
          onPressed: _startOpeningScene,
          icon: const Icon(Icons.visibility_outlined),
          label: Text(l10n.scanPassUnderstandSceneAction),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const ValueKey<String>('scan-pass-other-scene-button'),
          onPressed: _startDifferentScene,
          icon: const Icon(Icons.shuffle_outlined),
          label: Text(l10n.scanPassOtherSceneAction),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.text,
            minimumSize: const Size.fromHeight(46),
            side: BorderSide(color: colors.line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLearning(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth >= 900 && constraints.maxHeight >= 560;
        final field = KeyedSubtree(
          key: _fieldAnchor,
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[
              _receiveController,
              _touchController,
              _reviewController,
            ]),
            builder: (context, _) => _buildField(
              l10n,
              key: const ValueKey<String>('scan-pass-active-field'),
              scenario: _scenario,
              phase: _phase,
              scanned: _scanned,
              receiving: _receiving,
              receiveProgress: _receiveController.value,
              touchProgress: _touchController.value,
              reviewProgress: _reviewController.value,
              lastScan: _scan,
              firstTouchState: _firstTouchState,
              previewFirstTouchState: _previewFirstTouchState,
              previewNextIntents: _previewNextIntents,
              reviewResult: _phase == _ScanPassPhase.review
                  ? _displayedReviewResult
                  : null,
              showAlternative: _showAlternative,
            ),
          ),
        );
        final panel =
            KeyedSubtree(key: _choicesAnchor, child: _buildPanel(l10n));
        final header = <Widget>[
          _buildSceneContext(
            l10n,
            scenario: _scenario,
            trailing: l10n.scanPassRoundStatus(
              _roundIndex + 1,
              _rounds.length,
            ),
          ),
          const SizedBox(height: 12),
          _ScanPassPhaseStrip(phase: _phase, l10n: l10n),
          const SizedBox(height: 16),
        ];

        if (wide) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...header,
                Expanded(
                  child: Row(
                    key: const ValueKey<String>('scan-pass-wide-layout'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: field),
                      const SizedBox(width: 22),
                      SizedBox(
                        width: 320,
                        child: SingleChildScrollView(child: panel),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...header,
            SizedBox(
              height: math.min(
                  (constraints.maxWidth - 28) / _ScanPassField.aspectRatio,
                  math.max(140.0, constraints.maxHeight - 16)),
              child: field,
            ),
            const SizedBox(height: 14),
            panel,
          ],
        );

        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 22),
          child: content,
        );
      },
    );
  }

  Widget _buildSceneContext(
    AppLocalizations l10n, {
    required ScanPassScenario scenario,
    required String trailing,
  }) {
    final colors = _ScanPassColors.of(context);
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.scanPassSessionKicker(
            scenario.roundNumber,
            _regionText(l10n, scenario.region),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.muted,
                letterSpacing: 1.1,
              ),
        ),
        const SizedBox(height: 5),
        Text(
          _sceneTitle(l10n, scenario),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w500,
                height: 1.15,
              ),
        ),
      ],
    );
    final matchBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          trailing,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.muted,
              ),
        ),
        const SizedBox(height: 5),
        Text(
          l10n.scanPassMatchClock(
            scenario.matchClockLabel,
            scenario.scoreLabel,
          ),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w500,
              ),
        ),
        Text(
          l10n.scanPassMatchShape,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.muted,
              ),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 430 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.15) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleBlock,
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerLeft, child: matchBlock),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 12),
            Flexible(child: matchBlock),
          ],
        );
      },
    );
  }

  Widget _buildPanel(AppLocalizations l10n) {
    return switch (_phase) {
      _ScanPassPhase.observe => _buildObservePanel(l10n),
      _ScanPassPhase.firstTouch => _buildFirstTouchPanel(l10n),
      _ScanPassPhase.nextAction => _buildNextActionPanel(l10n),
      _ScanPassPhase.review => _buildReviewPanel(l10n),
      _ScanPassPhase.result => const SizedBox.shrink(),
    };
  }

  Widget _buildObservePanel(AppLocalizations l10n) {
    final colors = _ScanPassColors.of(context);
    final cue = _scanned ? _scanCueText(l10n, _scenario) : null;
    return _PanelBody(
      children: [
        _PhaseLabel(text: l10n.scanPassObservePhaseLabel),
        _QuestionText(text: l10n.scanPassObserveQuestion),
        const SizedBox(height: 8),
        _BodyText(text: l10n.scanPassObserveInstruction),
        const SizedBox(height: 14),
        _FactList(
          rows: [
            _FactRowData(
              label: l10n.scanPassFactBodyDirection,
              value: math.cos(_scenario.receiver.facingRadians) > 0.5
                  ? l10n.scanPassFactFacingForward
                  : l10n.scanPassFactFacingPasser,
            ),
            _FactRowData(
              label: l10n.scanPassFactVisibleOption,
              value: l10n.scanPassFactForwardOption,
            ),
            _FactRowData(
              label: l10n.scanPassFactRearPressure,
              value: _scanned
                  ? l10n.scanPassFactObserved
                  : l10n.scanPassFactNotObserved,
            ),
          ],
        ),
        if (cue != null) ...[
          const SizedBox(height: 14),
          _CueBox(text: cue),
        ],
        const SizedBox(height: 16),
        if (!_scanned)
          FilledButton.icon(
            key: const ValueKey<String>('scan-pass-scan-button'),
            onPressed: _recordScan,
            icon: const Icon(Icons.visibility_outlined),
            label: Text(l10n.scanPassScanAction),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          )
        else
          FilledButton.icon(
            key: const ValueKey<String>('scan-pass-receive-button'),
            onPressed: _receiving ? null : _receiveBall,
            icon: const Icon(Icons.sports_soccer_outlined),
            label: Text(l10n.scanPassReceiveAction),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              disabledBackgroundColor: colors.line,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFirstTouchPanel(AppLocalizations l10n) {
    final preview = _previewFirstTouch;
    return _PanelBody(
      children: [
        _PhaseLabel(text: l10n.scanPassFirstTouchPhaseLabel),
        _QuestionText(text: l10n.scanPassFirstTouchQuestion),
        const SizedBox(height: 8),
        _BodyText(text: l10n.scanPassFirstTouchInstruction),
        const SizedBox(height: 14),
        _FactList(
          rows: [
            _FactRowData(
              label: l10n.scanPassFactObservedPressure,
              value:
                  _scanCueText(l10n, _scenario, at: _scenario.ballTravelTime),
            ),
            _FactRowData(
              label: l10n.scanPassFactCurrentPossession,
              value: l10n.scanPassPossession6,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ActionList(
          children: [
            _ScanPassActionButton(
              key: const ValueKey<String>('scan-pass-touch-upper'),
              selected: preview == ScanPassFirstTouch.upperTouch,
              icon: Icons.north_outlined,
              title: l10n.scanPassTouchUpperTitle,
              subtitle: l10n.scanPassTouchUpperSubtitle,
              onPressed: () =>
                  _previewFirstTouchAction(ScanPassFirstTouch.upperTouch),
            ),
            _ScanPassActionButton(
              key: const ValueKey<String>('scan-pass-touch-lower'),
              selected: preview == ScanPassFirstTouch.lowerTouch,
              icon: Icons.south_outlined,
              title: l10n.scanPassTouchLowerTitle,
              subtitle: l10n.scanPassTouchLowerSubtitle,
              onPressed: () =>
                  _previewFirstTouchAction(ScanPassFirstTouch.lowerTouch),
            ),
            _ScanPassActionButton(
              key: const ValueKey<String>('scan-pass-touch-turn'),
              selected: preview == ScanPassFirstTouch.turnForward,
              icon: Icons.rotate_right_outlined,
              title: l10n.scanPassTouchTurnTitle,
              subtitle: l10n.scanPassTouchTurnSubtitle,
              onPressed: () =>
                  _previewFirstTouchAction(ScanPassFirstTouch.turnForward),
            ),
            _ScanPassActionButton(
              key: const ValueKey<String>('scan-pass-touch-return'),
              selected: preview == ScanPassFirstTouch.returnTo4,
              icon: Icons.keyboard_return_outlined,
              title: l10n.scanPassTouchReturnTitle,
              subtitle: l10n.scanPassTouchReturnSubtitle,
              onPressed: () =>
                  _previewFirstTouchAction(ScanPassFirstTouch.returnTo4),
            ),
          ],
        ),
        if (preview != null) ...[
          const SizedBox(height: 14),
          _CueBox(text: _firstTouchPreviewText(l10n, preview)),
          if (!_usesStickyExecuteBar(context)) ...[
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const ValueKey<String>('scan-pass-execute-first-touch'),
              onPressed: _executeFirstTouch,
              icon: const Icon(Icons.play_arrow_outlined),
              label: Text(l10n.scanPassExecuteChoiceAction),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildNextActionPanel(AppLocalizations l10n) {
    final first = _selectedFirstTouch;
    final firstState = _firstTouchState;
    if (first == null || firstState == null) return const SizedBox.shrink();
    if (_executingTouch) {
      return _PanelBody(
        children: [
          _PhaseLabel(text: l10n.scanPassNextActionPhaseLabel),
          _QuestionText(text: l10n.scanPassTouchExecutingTitle),
          const SizedBox(height: 8),
          _BodyText(text: l10n.scanPassTouchInMotionBody),
        ],
      );
    }
    final returned = first == ScanPassFirstTouch.returnTo4;
    final available = _engine.availableNextActions(first);
    return _PanelBody(
      children: [
        _PhaseLabel(text: l10n.scanPassNextActionPhaseLabel),
        _QuestionText(
          text: returned
              ? l10n.scanPassNextMoveQuestion
              : l10n.scanPassNextPassQuestion,
        ),
        const SizedBox(height: 8),
        _BodyText(
          text: returned
              ? l10n.scanPassNextMoveInstruction
              : l10n.scanPassNextPassInstruction,
        ),
        const SizedBox(height: 14),
        _FactList(
          rows: [
            _FactRowData(
              label: l10n.scanPassFactFirstChoice,
              value: _firstTouchText(l10n, first),
            ),
            _FactRowData(
              label: l10n.scanPassFactCurrentPossession,
              value: returned
                  ? l10n.scanPassPossession4
                  : l10n.scanPassPossession6,
            ),
            _FactRowData(
              label: l10n.scanPassFactPressureNow,
              value: _touchChangeText(l10n, firstState),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ActionList(
          children: [
            if (available.contains(ScanPassNextAction.passTo4))
              _ScanPassActionButton(
                key: const ValueKey<String>('scan-pass-next-pass-4'),
                selected: _previewNextAction == ScanPassNextAction.passTo4,
                icon: Icons.keyboard_return_outlined,
                title: l10n.scanPassPass4Title,
                subtitle: l10n.scanPassPass4Subtitle,
                onPressed: () =>
                    _previewNextActionChoice(ScanPassNextAction.passTo4),
              ),
            if (available.contains(ScanPassNextAction.passTo8))
              _ScanPassActionButton(
                key: const ValueKey<String>('scan-pass-next-pass-8'),
                selected: _previewNextAction == ScanPassNextAction.passTo8,
                icon: Icons.call_made_outlined,
                title: l10n.scanPassPass8Title,
                subtitle: l10n.scanPassPass8Subtitle,
                onPressed: () =>
                    _previewNextActionChoice(ScanPassNextAction.passTo8),
              ),
            if (available.contains(ScanPassNextAction.passTo9))
              _ScanPassActionButton(
                key: const ValueKey<String>('scan-pass-next-pass-9'),
                selected: _previewNextAction == ScanPassNextAction.passTo9,
                icon: Icons.arrow_forward_outlined,
                title: l10n.scanPassPass9Title,
                subtitle: l10n.scanPassPass9Subtitle,
                onPressed: () =>
                    _previewNextActionChoice(ScanPassNextAction.passTo9),
              ),
            if (available.contains(ScanPassNextAction.holdPassTo8))
              _ScanPassActionButton(
                key: const ValueKey<String>('scan-pass-next-hold-8'),
                selected: _previewNextAction == ScanPassNextAction.holdPassTo8,
                icon: Icons.more_time_outlined,
                title: l10n.scanPassHold8Title,
                subtitle: l10n.scanPassHold8Subtitle,
                onPressed: () =>
                    _previewNextActionChoice(ScanPassNextAction.holdPassTo8),
              ),
            if (available.contains(ScanPassNextAction.supportUpper))
              _ScanPassActionButton(
                key: const ValueKey<String>('scan-pass-next-support-upper'),
                selected: _previewNextAction == ScanPassNextAction.supportUpper,
                icon: Icons.north_west_outlined,
                title: l10n.scanPassSupportUpperTitle,
                subtitle: l10n.scanPassSupportUpperSubtitle,
                onPressed: () =>
                    _previewNextActionChoice(ScanPassNextAction.supportUpper),
              ),
            if (available.contains(ScanPassNextAction.supportForward))
              _ScanPassActionButton(
                key: const ValueKey<String>('scan-pass-next-support-forward'),
                selected:
                    _previewNextAction == ScanPassNextAction.supportForward,
                icon: Icons.trending_flat_outlined,
                title: l10n.scanPassSupportForwardTitle,
                subtitle: l10n.scanPassSupportForwardSubtitle,
                onPressed: () =>
                    _previewNextActionChoice(ScanPassNextAction.supportForward),
              ),
            if (available.contains(ScanPassNextAction.holdPocket))
              _ScanPassActionButton(
                key: const ValueKey<String>('scan-pass-next-hold-pocket'),
                selected: _previewNextAction == ScanPassNextAction.holdPocket,
                icon: Icons.pause_outlined,
                title: l10n.scanPassHoldPocketTitle,
                subtitle: l10n.scanPassHoldPocketSubtitle,
                onPressed: () =>
                    _previewNextActionChoice(ScanPassNextAction.holdPocket),
              ),
          ],
        ),
        if (_previewNextAction != null) ...[
          const SizedBox(height: 14),
          _CueBox(text: _nextActionPreviewText(l10n, _previewNextAction!)),
          if (!_usesStickyExecuteBar(context)) ...[
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const ValueKey<String>('scan-pass-execute-next-action'),
              onPressed: _executeNextAction,
              icon: const Icon(Icons.play_arrow_outlined),
              label: Text(l10n.scanPassExecuteChoiceAction),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildReviewPanel(AppLocalizations l10n) {
    final shown = _displayedReviewResult;
    final selected = _selectedResult;
    final evaluation = _evaluation;
    if (shown == null || selected == null || evaluation == null) {
      return const SizedBox.shrink();
    }
    final colors = _ScanPassColors.of(context);
    return _PanelBody(
      key: const ValueKey<String>('scan-pass-review-panel'),
      children: [
        _PhaseLabel(text: l10n.scanPassReviewPhaseLabel),
        Text(
          _showAlternative
              ? l10n.scanPassReviewViewingAlternative
              : l10n.scanPassReviewViewingMine,
          key: const ValueKey<String>('scan-pass-review-path-label'),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.accent,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        _QuestionText(
          key: const ValueKey<String>('scan-pass-review-summary'),
          text: l10n.scanPassReviewOutcomeSummary(
            _planName(l10n, shown),
            _outcomeText(l10n, shown.outcome),
          ),
        ),
        const SizedBox(height: 14),
        _ReviewRows(rows: _reviewRows(l10n, shown)),
        const SizedBox(height: 14),
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
        _DetailedEvaluation(
          l10n: l10n,
          result: shown,
          evaluation: evaluation,
          selectedPlanId: selected.planId,
          actionName: _planName,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            OutlinedButton.icon(
              key: const ValueKey<String>('scan-pass-retry-scene-button'),
              onPressed: _retryScene,
              icon: const Icon(Icons.replay),
              label: Text(l10n.scanPassRetrySceneAction),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.text,
                side: BorderSide(color: colors.line),
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            FilledButton.icon(
              key: const ValueKey<String>('scan-pass-next-button'),
              onPressed: _nextScene,
              icon: Icon(
                _roundIndex + 1 >= _rounds.length
                    ? Icons.check_circle_outline
                    : Icons.arrow_forward,
              ),
              label: Text(
                _roundIndex + 1 >= _rounds.length
                    ? l10n.scanPassFinishLearningAction
                    : l10n.scanPassNextSceneAction,
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResult(AppLocalizations l10n) {
    final colors = _ScanPassColors.of(context);
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.check_circle_outline, color: colors.accent, size: 42),
              const SizedBox(height: 12),
              Text(
                l10n.scanPassLearningResultTitle,
                key: const ValueKey<String>('scan-pass-result-title'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.scanPassLearningResultBody(_reviewedScenes.length),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.muted,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                key: const ValueKey<String>('scan-pass-play-again-button'),
                onPressed: _startOpeningScene,
                icon: const Icon(Icons.replay),
                label: Text(l10n.scanPassPlayAgainAction),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _startDifferentScene,
                icon: const Icon(Icons.shuffle_outlined),
                label: Text(l10n.scanPassOtherSceneAction),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.text,
                  side: BorderSide(color: colors.line),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    AppLocalizations l10n, {
    required Key key,
    required ScanPassScenario scenario,
    required _ScanPassPhase phase,
    required bool scanned,
    bool receiving = false,
    required double receiveProgress,
    double touchProgress = 1,
    double reviewProgress = 1,
    ScanPassScanObservation? lastScan,
    ScanPassFirstTouchState? firstTouchState,
    ScanPassFirstTouchState? previewFirstTouchState,
    required List<ScanPassLearningIntent> previewNextIntents,
    ScanPassPlanResult? reviewResult,
    bool showAlternative = false,
  }) {
    return Semantics(
      label: l10n.scanPassFieldSemantics,
      image: true,
      child: _ScanPassField(
        key: key,
        scenario: scenario,
        phase: phase,
        scanned: scanned,
        receiving: receiving,
        receiveProgress: receiveProgress,
        touchProgress: touchProgress,
        reviewProgress: reviewProgress,
        lastScan: lastScan,
        firstTouchState: firstTouchState,
        previewFirstTouchState: previewFirstTouchState,
        previewNextIntents: previewNextIntents,
        reviewResult: reviewResult,
        showAlternative: showAlternative,
        labels: _FieldLabels.from(l10n),
        brightness: Theme.of(context).brightness,
        fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
      ),
    );
  }

  String _scanCueText(
    AppLocalizations l10n,
    ScanPassScenario scenario, {
    double? at,
  }) {
    final time = (_scan?.observedAt.inMilliseconds ?? 0) / 1000;
    final scanTime = at ?? (time == 0 ? _observationTime(scenario) : time);
    final snapshot = ScanPassTimeline.snapshot(
      scenario: scenario,
      time: scanTime,
    );
    final receiver = snapshot.attacker(ScanPassPlayerRole.midfielder6);
    final nearest = snapshot.defenders.reduce((a, b) {
      final aDistance = a.position.distanceTo(receiver.position);
      final bDistance = b.position.distanceTo(receiver.position);
      return aDistance <= bDistance ? a : b;
    });
    final vertical = nearest.position.y - receiver.position.y;
    final side = vertical < -0.035
        ? l10n.scanPassPressureUpperSide
        : vertical > 0.035
            ? l10n.scanPassPressureLowerSide
            : l10n.scanPassPressureCentralSide;
    final laterTime = scanTime + 0.55;
    final laterDefender = nearest.at(0.55);
    final laterReceiver = scenario.receiver.at(laterTime);
    final nowDistance = nearest.position.distanceTo(receiver.position);
    final laterDistance =
        laterDefender.position.distanceTo(laterReceiver.position);
    final motion = laterDistance < nowDistance - 0.012
        ? l10n.scanPassPressureClosingMotion
        : laterDistance > nowDistance + 0.012
            ? l10n.scanPassPressureLeavingMotion
            : l10n.scanPassPressureHoldingMotion;
    return l10n.scanPassPressureCue(side, motion);
  }

  String _touchChangeText(
    AppLocalizations l10n,
    ScanPassFirstTouchState state,
  ) {
    if (state.ballLost) return l10n.scanPassTouchChangeIntercepted;
    if (state.returned) return l10n.scanPassTouchChangeReturned;
    if (state.contested) return l10n.scanPassTouchChangeContested;
    return state.pressureEscapeRaw >= 62
        ? l10n.scanPassTouchChangeKept
        : l10n.scanPassTouchChangePressureRemains;
  }

  String _firstTouchPreviewText(
    AppLocalizations l10n,
    ScanPassFirstTouch touch,
  ) {
    return switch (touch) {
      ScanPassFirstTouch.upperTouch => l10n.scanPassTouchUpperPreview,
      ScanPassFirstTouch.lowerTouch => l10n.scanPassTouchLowerPreview,
      ScanPassFirstTouch.turnForward => l10n.scanPassTouchTurnPreview,
      ScanPassFirstTouch.returnTo4 => l10n.scanPassTouchReturnPreview,
    };
  }

  String _nextActionPreviewText(
    AppLocalizations l10n,
    ScanPassNextAction action,
  ) {
    return switch (action) {
      ScanPassNextAction.passTo4 => l10n.scanPassPass4Preview,
      ScanPassNextAction.passTo8 => l10n.scanPassPass8Preview,
      ScanPassNextAction.passTo9 => l10n.scanPassPass9Preview,
      ScanPassNextAction.holdPassTo8 => l10n.scanPassHold8Preview,
      ScanPassNextAction.supportUpper => l10n.scanPassSupportUpperPreview,
      ScanPassNextAction.supportForward => l10n.scanPassSupportForwardPreview,
      ScanPassNextAction.holdPocket => l10n.scanPassHoldPocketPreview,
    };
  }

  List<_ReviewRowData> _reviewRows(
    AppLocalizations l10n,
    ScanPassPlanResult result,
  ) {
    final reason = result.reasons.isEmpty
        ? l10n.scanPassReviewReasonFallback
        : _reasonText(l10n, result.reasons.first);
    final nextReasons = <ScanPassReason>[
      if (result.firstTouchState.returned) ...[
        ScanPassReason.supportAngleCreated,
        ScanPassReason.supportAngleWeak,
      ],
      if (result.nextAction == ScanPassNextAction.holdPassTo8) ...[
        ScanPassReason.holdOpenedLane,
        ScanPassReason.holdInvitedPressure,
      ],
      ScanPassReason.laneClosed,
      ScanPassReason.receiverCrowded,
      ScanPassReason.receiverAvailable,
      ScanPassReason.clearLane,
    ];
    final nextReason = nextReasons.where(result.reasons.contains).firstOrNull;
    return [
      _ReviewRowData(
        label: l10n.scanPassReviewSituationLabel,
        value: _scanCueText(l10n, result.scenario,
            at: result.scenario.ballTravelTime),
        body: l10n.scanPassReviewSituationBody,
      ),
      _ReviewRowData(
        label: _showAlternative
            ? l10n.scanPassReviewAlternativeAction
            : l10n.scanPassReviewChoiceLabel,
        value: _planName(l10n, result),
        body: reason,
      ),
      _ReviewRowData(
        label: l10n.scanPassReviewNextSceneLabel,
        value: _finalReceiverText(l10n, result),
        body: [
          _outcomeDetailText(l10n, result),
          if (nextReason != null) _reasonText(l10n, nextReason),
        ].join('\n'),
      ),
    ];
  }

  String _finalReceiverText(AppLocalizations l10n, ScanPassPlanResult result) {
    if (result.isLoss) return l10n.scanPassFinalReceiverLoose;
    return switch (result.finalReceiverRole) {
      ScanPassPlayerRole.centerBack4 => l10n.scanPassFinalReceiver4,
      ScanPassPlayerRole.midfielder6 => l10n.scanPassFinalReceiver6,
      ScanPassPlayerRole.support8 => l10n.scanPassFinalReceiver8,
      ScanPassPlayerRole.forward9 => l10n.scanPassFinalReceiver9,
      null => l10n.scanPassFinalReceiverLoose,
    };
  }

  String _outcomeDetailText(AppLocalizations l10n, ScanPassPlanResult result) {
    return switch (result.outcome) {
      ScanPassOutcomeType.kept => l10n.scanPassOutcomeDetailKept,
      ScanPassOutcomeType.progressed => l10n.scanPassOutcomeDetailProgressed,
      ScanPassOutcomeType.recycled => l10n.scanPassOutcomeDetailRecycled,
      ScanPassOutcomeType.contested => l10n.scanPassOutcomeDetailContested,
      ScanPassOutcomeType.intercepted => l10n.scanPassOutcomeDetailIntercepted,
      ScanPassOutcomeType.timeout => l10n.scanPassOutcomeDetailKept,
    };
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
}

class _ScanPassField extends StatelessWidget {
  static const double aspectRatio = 1.58;

  final ScanPassScenario scenario;
  final _ScanPassPhase phase;
  final bool scanned;
  final bool receiving;
  final double receiveProgress;
  final double touchProgress;
  final double reviewProgress;
  final ScanPassScanObservation? lastScan;
  final ScanPassFirstTouchState? firstTouchState;
  final ScanPassFirstTouchState? previewFirstTouchState;
  final List<ScanPassLearningIntent> previewNextIntents;
  final ScanPassPlanResult? reviewResult;
  final bool showAlternative;
  final _FieldLabels labels;
  final Brightness brightness;
  final String? fontFamily;

  const _ScanPassField({
    super.key,
    required this.scenario,
    required this.phase,
    required this.scanned,
    required this.receiving,
    required this.receiveProgress,
    required this.touchProgress,
    required this.reviewProgress,
    required this.lastScan,
    required this.firstTouchState,
    required this.previewFirstTouchState,
    required this.previewNextIntents,
    required this.reviewResult,
    required this.showAlternative,
    required this.labels,
    required this.brightness,
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
              scanned: scanned,
              receiving: receiving,
              receiveProgress: receiveProgress,
              touchProgress: touchProgress,
              reviewProgress: reviewProgress,
              lastScan: lastScan,
              firstTouchState: firstTouchState,
              previewFirstTouchState: previewFirstTouchState,
              previewNextIntents: previewNextIntents,
              reviewResult: reviewResult,
              showAlternative: showAlternative,
              labels: labels,
              brightness: brightness,
              fontFamily: fontFamily,
            ),
          ),
        );
      },
    );
  }
}

class _ScanPassFieldPainter extends CustomPainter {
  final ScanPassScenario scenario;
  final _ScanPassPhase phase;
  final bool scanned;
  final bool receiving;
  final double receiveProgress;
  final double touchProgress;
  final double reviewProgress;
  final ScanPassScanObservation? lastScan;
  final ScanPassFirstTouchState? firstTouchState;
  final ScanPassFirstTouchState? previewFirstTouchState;
  final List<ScanPassLearningIntent> previewNextIntents;
  final ScanPassPlanResult? reviewResult;
  final bool showAlternative;
  final _FieldLabels labels;
  final Brightness brightness;
  final String? fontFamily;

  const _ScanPassFieldPainter({
    required this.scenario,
    required this.phase,
    required this.scanned,
    required this.receiving,
    required this.receiveProgress,
    required this.touchProgress,
    required this.reviewProgress,
    required this.lastScan,
    required this.firstTouchState,
    required this.previewFirstTouchState,
    required this.previewNextIntents,
    required this.reviewResult,
    required this.showAlternative,
    required this.labels,
    required this.brightness,
    required this.fontFamily,
  });

  bool get _isDark => brightness == Brightness.dark;

  Color get _pitch =>
      _isDark ? const Color(0xFF263E38) : const Color(0xFFE0E8DF);

  Color get _pitchStripe =>
      _isDark ? const Color(0xFF1F342F) : const Color(0xFFD6E0D7);

  Color get _fieldLine =>
      _isDark ? const Color(0xFF657C70) : const Color(0xFF8AA092);

  Color get _text =>
      _isDark ? const Color(0xFFE9EEEB) : const Color(0xFF202E33);

  Color get _muted =>
      _isDark ? const Color(0xFFA7B8BB) : const Color(0xFF53666D);

  Color get _team =>
      _isDark ? const Color(0xFF8EB2C3) : const Color(0xFF47748A);

  Color get _defender =>
      _isDark ? const Color(0xFFCF927B) : const Color(0xFFA86250);

  Color get _self =>
      _isDark ? const Color(0xFFDDC18D) : const Color(0xFFA88644);

  Color get _ball => _isDark ? const Color(0xFFF6F3E9) : Colors.white;

  Color get _route =>
      _isDark ? const Color(0xFFDDC18D) : const Color(0xFF785C25);

  @override
  void paint(Canvas canvas, Size size) {
    final field = Offset.zero & size;
    canvas.drawRRect(
      BorderRadius.circular(6).toRRect(field),
      Paint()..color = _pitch,
    );
    _drawStripes(canvas, size);
    _drawFieldLines(canvas, size);

    final snapshot = _snapshot();
    _drawIncomingGuide(canvas, size);
    if (!scanned && phase == _ScanPassPhase.observe) {
      _drawUnknownArea(canvas, size, snapshot);
    }
    _drawPreviewPaths(canvas, size);
    _drawExecutedPaths(canvas, size, snapshot);
    _drawDefenders(canvas, size, snapshot);
    _drawAttackers(canvas, size, snapshot);
    _drawBall(canvas, size, snapshot);
    _drawAttackArrow(canvas, size);
  }

  ScanPassMatchSnapshot _snapshot() {
    final result = reviewResult;
    if (result != null) {
      return ScanPassTimeline.snapshot(
        scenario: scenario,
        time: result.finalTime * reviewProgress.clamp(0.0, 1.0).toDouble(),
        result: result,
      );
    }
    final first = firstTouchState;
    if (first != null &&
        phase == _ScanPassPhase.nextAction &&
        touchProgress < 1) {
      final time = first.touchStartTime +
          ((first.completedAt - first.touchStartTime) *
              touchProgress.clamp(0.0, 1.0).toDouble());
      return ScanPassTimeline.snapshot(
        scenario: scenario,
        time: time,
        firstTouchState: first,
      );
    }
    if (first != null) {
      return ScanPassTimeline.snapshot(
        scenario: scenario,
        time: first.completedAt,
        firstTouchState: first,
      );
    }
    final time = receiving
        ? scenario.ballTravelTime * receiveProgress.clamp(0.0, 1.0).toDouble()
        : phase == _ScanPassPhase.firstTouch
            ? scenario.ballTravelTime
            : _observationTime(scenario);
    return ScanPassTimeline.snapshot(scenario: scenario, time: time);
  }

  void _drawStripes(Canvas canvas, Size size) {
    final paint = Paint()..color = _pitchStripe.withValues(alpha: 0.45);
    final stripeHeight = size.height / 8;
    for (var i = 0; i < 8; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight),
        paint,
      );
    }
  }

  void _drawFieldLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _fieldLine.withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final margin = size.shortestSide * 0.055;
    final inner = Rect.fromLTWH(
      margin,
      margin,
      size.width - margin * 2,
      size.height - margin * 2,
    );
    canvas.drawRRect(BorderRadius.circular(4).toRRect(inner), paint);
    canvas.drawLine(
      Offset(inner.center.dx, inner.top),
      Offset(inner.center.dx, inner.bottom),
      paint,
    );
    canvas.drawCircle(inner.center, size.shortestSide * 0.15, paint);
    canvas.drawRect(
      Rect.fromLTWH(
        inner.left,
        inner.center.dy - inner.height * 0.22,
        inner.width * 0.16,
        inner.height * 0.44,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        inner.right - inner.width * 0.16,
        inner.center.dy - inner.height * 0.22,
        inner.width * 0.16,
        inner.height * 0.44,
      ),
      paint,
    );
  }

  void _drawIncomingGuide(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _route.withValues(alpha: 0.58)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    _drawDashedLine(
      canvas,
      _toOffset(scenario.centerBack.position, size),
      _toOffset(scenario.receiver.position, size),
      paint,
      dash: 6,
      gap: 5,
    );
  }

  void _drawUnknownArea(
      Canvas canvas, Size size, ScanPassMatchSnapshot snapshot) {
    final receiver = snapshot.attacker(ScanPassPlayerRole.midfielder6);
    final center = _toOffset(receiver.position, size);
    final behind = receiver.facingRadians + math.pi;
    const radius = ScanPassLearningSpace.rearCheckRadius;
    const spread = ScanPassLearningSpace.rearHalfAngle;
    final path = Path()..moveTo(center.dx, center.dy);
    for (var i = 0; i <= 32; i++) {
      final angle = behind - spread + spread * 2 * i / 32;
      final point = receiver.position +
          ScanPassPoint(math.cos(angle) * radius, math.sin(angle) * radius);
      final offset = _toOffset(point, size);
      path.lineTo(offset.dx, offset.dy);
    }
    path.close();
    canvas.drawPath(
        path,
        Paint()
          ..color =
              (_isDark ? Colors.black : Colors.white).withValues(alpha: .28));
    canvas.drawPath(
        path,
        Paint()
          ..color = _route.withValues(alpha: .45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    final label = _toOffset(
        receiver.position +
            ScanPassPoint(math.cos(behind) * radius * .74,
                math.sin(behind) * radius * .74),
        size);
    _drawText(canvas, labels.unknownArea, label,
        color: _muted,
        fontSize: 11,
        align: TextAlign.center,
        anchor: _TextAnchor.center);
  }

  void _drawPreviewPaths(Canvas canvas, Size size) {
    final firstPreview = previewFirstTouchState;
    if (firstPreview != null) {
      final paint = Paint()
        ..color = _route.withValues(alpha: 0.62)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final intent = ScanPassLearningIntent.firstTouch(firstPreview);
      _drawLearningIntent(canvas, size, intent, paint);
      if (intent.type == ScanPassPathType.firstTouch) {
        _drawGhostReceiver(canvas, size, intent.to);
      }
    }

    if (previewNextIntents.isNotEmpty) {
      final paint = Paint()
        ..color = _route.withValues(alpha: 0.56)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (final intent in previewNextIntents) {
        _drawLearningIntent(canvas, size, intent, paint);
      }
      final target = previewNextIntents.last.to;
      _drawText(
        canvas,
        labels.intendedRoute,
        _toOffset(target, size) + const Offset(0, -18),
        color: _route,
        fontSize: size.shortestSide * 0.032,
        align: TextAlign.center,
        anchor: _TextAnchor.center,
      );
    }
  }

  void _drawLearningIntent(
    Canvas canvas,
    Size size,
    ScanPassLearningIntent intent,
    Paint paint,
  ) {
    _drawRouteSegment(
      canvas,
      size,
      ScanPassPathSegment(
        from: intent.from,
        to: intent.to,
        type: intent.type,
        startTime: 0,
        endTime: 1,
      ),
      paint,
      dashed: true,
    );
  }

  void _drawExecutedPaths(
    Canvas canvas,
    Size size,
    ScanPassMatchSnapshot snapshot,
  ) {
    final result = reviewResult;
    final segments = result?.pathSegments ?? firstTouchState?.pathSegments;
    if (segments == null) return;
    final time = snapshot.time;
    for (final segment in segments) {
      if (time < segment.startTime) continue;
      final progress = segment.endTime <= segment.startTime
          ? 1.0
          : ((time - segment.startTime) / (segment.endTime - segment.startTime))
              .clamp(0.0, 1.0)
              .toDouble();
      final visible = ScanPassPathSegment(
        from: segment.from,
        to: segment.from.lerp(segment.to, progress),
        type: segment.type,
        startTime: segment.startTime,
        endTime: segment.endTime,
        contested: segment.contested,
      );
      final paint = Paint()
        ..color =
            (segment.contested ? _defender : _route).withValues(alpha: 0.82)
        ..strokeWidth = segment.type == ScanPassPathType.offBallRun ? 1.7 : 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      _drawRouteSegment(
        canvas,
        size,
        visible,
        paint,
        dashed: segment.type == ScanPassPathType.offBallRun,
      );
    }
  }

  void _drawRouteSegment(
    Canvas canvas,
    Size size,
    ScanPassPathSegment segment,
    Paint paint, {
    required bool dashed,
  }) {
    final from = _toOffset(segment.from, size);
    final to = _toOffset(segment.to, size);
    if (segment.type == ScanPassPathType.hold) {
      canvas.drawCircle(from, size.shortestSide * 0.034, paint);
      return;
    }
    if (dashed) {
      _drawDashedLine(canvas, from, to, paint, dash: 6, gap: 5);
    } else {
      canvas.drawLine(from, to, paint);
    }
    if ((to - from).distance > 6) _drawArrowHead(canvas, from, to, paint);
  }

  void _drawDefenders(
      Canvas canvas, Size size, ScanPassMatchSnapshot snapshot) {
    final receiver = snapshot.attacker(ScanPassPlayerRole.midfielder6);
    for (final defender in snapshot.defenders) {
      if (scanned ||
          phase != _ScanPassPhase.observe ||
          !ScanPassLearningSpace.needsRearCheck(defender.position, receiver)) {
        _drawDefender(canvas, size, defender.position, alpha: .90);
      }
    }
    if (scanned &&
        (phase == _ScanPassPhase.observe ||
            phase == _ScanPassPhase.firstTouch)) {
      final nearest = snapshot.defenders.reduce((a, b) =>
          a.position.distanceTo(receiver.position) <=
                  b.position.distanceTo(receiver.position)
              ? a
              : b);
      _drawPressureCue(canvas, size, nearest);
    }
  }

  void _drawPressureCue(Canvas canvas, Size size, ScanPassDefender defender) {
    final from = _toOffset(defender.position, size);
    final vector = Offset(
        defender.velocity.x * size.width, defender.velocity.y * size.height);
    if (vector.distance < 1) return;
    final length = (vector.distance * .5).clamp(18.0, 42.0);
    final end = from + vector / vector.distance * length;
    final paint = Paint()
      ..color = _defender.withValues(alpha: .78)
      ..strokeWidth = 1.7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    _drawDashedLine(canvas, from, end, paint, dash: 4, gap: 4);
    _drawArrowHead(canvas, from, end, paint);
  }

  void _drawAttackers(
    Canvas canvas,
    Size size,
    ScanPassMatchSnapshot snapshot,
  ) {
    for (final player in snapshot.attackers) {
      final isSelf = player.role == ScanPassPlayerRole.midfielder6;
      _drawAttacker(
        canvas,
        size,
        player,
        fill: isSelf ? _self : _team,
        textColor: isSelf
            ? (_isDark ? const Color(0xFF142229) : Colors.white)
            : Colors.white,
      );
    }
  }

  void _drawBall(Canvas canvas, Size size, ScanPassMatchSnapshot snapshot) {
    var center = _toOffset(snapshot.ball, size);
    final radius = math.max(4.0, size.shortestSide * 0.013);
    if (snapshot.ballLost) {
      final markerRadius = radius * 2.1;
      final paint = Paint()
        ..color = _defender
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(
        center,
        markerRadius + 4,
        Paint()..color = Colors.black.withValues(alpha: 0.38),
      );
      canvas.drawLine(
        center + Offset(-markerRadius, -markerRadius),
        center + Offset(markerRadius, markerRadius),
        paint,
      );
      canvas.drawLine(
        center + Offset(-markerRadius, markerRadius),
        center + Offset(markerRadius, -markerRadius),
        paint,
      );
      return;
    }
    final holder = snapshot.ballHolder;
    if (holder != null) {
      final player = snapshot.attacker(holder);
      final footOffset = Offset(
            math.cos(player.facingRadians),
            math.sin(player.facingRadians),
          ) *
          (size.shortestSide * 0.045);
      center = _toOffset(player.position, size) + footOffset;
    }
    canvas.drawCircle(
      center,
      radius + 1.4,
      Paint()..color = Colors.black.withValues(alpha: 0.34),
    );
    canvas.drawCircle(center, radius, Paint()..color = _ball);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _fieldLine.withValues(alpha: 0.70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawAttacker(
    Canvas canvas,
    Size size,
    ScanPassPlayer player, {
    required Color fill,
    required Color textColor,
  }) {
    final center = _toOffset(player.position, size);
    final scale = player.role == ScanPassPlayerRole.midfielder6 ? 1.08 : 1.0;
    final r = math.max(13.0, size.shortestSide * 0.043) * scale;
    if (player.role == ScanPassPlayerRole.midfielder6) {
      canvas.drawCircle(
          center,
          r + 6,
          Paint()
            ..color = fill.withValues(alpha: .50)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
    }
    _drawFacingCone(canvas, center, r, player.facingRadians, fill);
    final shirt = Path()
      ..moveTo(center.dx - r * 0.42, center.dy - r * 0.58)
      ..lineTo(center.dx - r * 0.88, center.dy - r * 0.26)
      ..lineTo(center.dx - r * 0.62, center.dy + r * 0.18)
      ..lineTo(center.dx - r * 0.42, center.dy + r * 0.02)
      ..lineTo(center.dx - r * 0.42, center.dy + r * 0.78)
      ..lineTo(center.dx + r * 0.42, center.dy + r * 0.78)
      ..lineTo(center.dx + r * 0.42, center.dy + r * 0.02)
      ..lineTo(center.dx + r * 0.62, center.dy + r * 0.18)
      ..lineTo(center.dx + r * 0.88, center.dy - r * 0.26)
      ..lineTo(center.dx + r * 0.42, center.dy - r * 0.58)
      ..close();
    canvas.drawPath(shirt, Paint()..color = fill);
    canvas.drawCircle(
      center + Offset(0, -r * 0.92),
      r * 0.24,
      Paint()..color = fill,
    );
    _drawText(
      canvas,
      player.number.toString(),
      center + Offset(0, r * 0.16),
      color: textColor,
      fontSize: r * 0.78,
      fontWeight: FontWeight.w700,
      align: TextAlign.center,
      anchor: _TextAnchor.center,
    );
    if (player.role == ScanPassPlayerRole.midfielder6) {
      _drawText(
        canvas,
        labels.selfPlayer,
        center + Offset(0, r * 1.85),
        color: _text,
        fontSize: size.shortestSide * 0.034,
        align: TextAlign.center,
        anchor: _TextAnchor.center,
      );
    } else if (player.role == ScanPassPlayerRole.centerBack4) {
      _drawText(
        canvas,
        labels.passer,
        center + Offset(0, r * 1.55),
        color: _text,
        fontSize: size.shortestSide * 0.030,
        align: TextAlign.center,
        anchor: _TextAnchor.center,
      );
    }
  }

  void _drawGhostReceiver(Canvas canvas, Size size, ScanPassPoint point) {
    final center = _toOffset(point, size);
    canvas.drawCircle(
      center,
      size.shortestSide * 0.045,
      Paint()
        ..color = _self.withValues(alpha: 0.16)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      size.shortestSide * 0.045,
      Paint()
        ..color = _self.withValues(alpha: 0.48)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _drawDefender(
    Canvas canvas,
    Size size,
    ScanPassPoint point, {
    required double alpha,
  }) {
    final center = _toOffset(point, size);
    final r = math.max(10.0, size.shortestSide * 0.036);
    final paint = Paint()..color = _defender.withValues(alpha: alpha);
    final body = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r, center.dy)
      ..close();
    canvas.drawPath(body, paint);
    canvas.drawCircle(center + Offset(0, -r * 1.05), r * 0.25, paint);
  }

  void _drawFacingCone(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    Color color,
  ) {
    final tip =
        center + Offset(math.cos(angle), math.sin(angle)) * (radius * 1.38);
    final left = center +
        Offset(math.cos(angle + 0.46), math.sin(angle + 0.46)) * radius;
    final right = center +
        Offset(math.cos(angle - 0.46), math.sin(angle - 0.46)) * radius;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.34));
  }

  void _drawAttackArrow(Canvas canvas, Size size) {
    final start = Offset(size.width * 0.76, size.height * 0.10);
    final end = Offset(size.width * 0.89, size.height * 0.10);
    final paint = Paint()
      ..color = _fieldLine.withValues(alpha: 0.80)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, paint);
    _drawArrowHead(canvas, start, end, paint);
    _drawText(
      canvas,
      labels.attackDirection,
      start + const Offset(-4, -12),
      color: _muted,
      fontSize: size.shortestSide * 0.030,
      align: TextAlign.right,
      anchor: _TextAnchor.right,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint paint, {
    required double dash,
    required double gap,
  }) {
    final delta = to - from;
    final distance = delta.distance;
    if (distance == 0) return;
    final direction = delta / distance;
    var travelled = 0.0;
    while (travelled < distance) {
      final start = from + direction * travelled;
      final end = from + direction * math.min(travelled + dash, distance);
      canvas.drawLine(start, end, paint);
      travelled += dash + gap;
    }
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Paint paint) {
    final vector = to - from;
    if (vector.distance < 2) return;
    final angle = math.atan2(vector.dy, vector.dx);
    const length = 7.0;
    final left =
        to - Offset(math.cos(angle - 0.55), math.sin(angle - 0.55)) * length;
    final right =
        to - Offset(math.cos(angle + 0.55), math.sin(angle + 0.55)) * length;
    canvas.drawLine(to, left, paint);
    canvas.drawLine(to, right, paint);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset anchorOffset, {
    required Color color,
    required double fontSize,
    FontWeight fontWeight = FontWeight.w500,
    TextAlign align = TextAlign.start,
    _TextAnchor anchor = _TextAnchor.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: math.max(10.0, fontSize),
          fontWeight: fontWeight,
          fontFamily: fontFamily,
          height: 1.05,
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 150);
    final dx = switch (anchor) {
      _TextAnchor.left => anchorOffset.dx,
      _TextAnchor.center => anchorOffset.dx - painter.width / 2,
      _TextAnchor.right => anchorOffset.dx - painter.width,
    };
    painter.paint(canvas, Offset(dx, anchorOffset.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _ScanPassFieldPainter oldDelegate) {
    return oldDelegate.scenario != scenario ||
        oldDelegate.phase != phase ||
        oldDelegate.scanned != scanned ||
        oldDelegate.receiving != receiving ||
        oldDelegate.receiveProgress != receiveProgress ||
        oldDelegate.touchProgress != touchProgress ||
        oldDelegate.reviewProgress != reviewProgress ||
        oldDelegate.lastScan != lastScan ||
        oldDelegate.firstTouchState != firstTouchState ||
        oldDelegate.previewFirstTouchState != previewFirstTouchState ||
        oldDelegate.previewNextIntents != previewNextIntents ||
        oldDelegate.reviewResult != reviewResult ||
        oldDelegate.showAlternative != showAlternative ||
        oldDelegate.brightness != brightness ||
        oldDelegate.fontFamily != fontFamily;
  }
}

class _FieldLabels {
  final String unknownArea;
  final String selfPlayer;
  final String passer;
  final String attackDirection;
  final String intendedRoute;

  const _FieldLabels({
    required this.unknownArea,
    required this.selfPlayer,
    required this.passer,
    required this.attackDirection,
    required this.intendedRoute,
  });

  factory _FieldLabels.from(AppLocalizations l10n) {
    return _FieldLabels(
      unknownArea: l10n.scanPassUnknownRearArea,
      selfPlayer: l10n.scanPassSelfPlayerLabel,
      passer: l10n.scanPassPasserLabel,
      attackDirection: l10n.scanPassAttackDirectionShort,
      intendedRoute: l10n.scanPassIntendedRouteLabel,
    );
  }
}

class _PanelBody extends StatelessWidget {
  final List<Widget> children;

  const _PanelBody({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _PhaseLabel extends StatelessWidget {
  final String text;

  const _PhaseLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.accent,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
            ),
      ),
    );
  }
}

class _QuestionText extends StatelessWidget {
  final String text;

  const _QuestionText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colors.text,
            fontWeight: FontWeight.w600,
            height: 1.28,
          ),
    );
  }
}

class _BodyText extends StatelessWidget {
  final String text;

  const _BodyText({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.muted,
            height: 1.30,
          ),
    );
  }
}

class _FactList extends StatelessWidget {
  final List<_FactRowData> rows;

  const _FactList({required this.rows});

  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          children: [
            for (final row in rows) _FactRow(row: row),
          ],
        ),
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  final _FactRowData row;

  const _FactRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              row.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.muted,
                    height: 1.20,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              row.value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                    height: 1.20,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FactRowData {
  final String label;
  final String value;

  const _FactRowData({required this.label, required this.value});
}

class _CueBox extends StatelessWidget {
  final String text;

  const _CueBox({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: colors.accent, width: 2)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 7, 0, 7),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.text,
                height: 1.28,
              ),
        ),
      ),
    );
  }
}

class _ActionList extends StatelessWidget {
  final List<Widget> children;

  const _ActionList({required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i += 1) ...[
          children[i],
          if (i != children.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ScanPassActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onPressed;

  const _ScanPassActionButton({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $subtitle',
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: selected ? colors.accent : colors.text,
          backgroundColor:
              selected ? colors.active : colors.surface.withValues(alpha: 0.70),
          side: BorderSide(color: selected ? colors.accent : colors.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.accent, size: 19),
            const SizedBox(width: 10),
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
                          color: colors.text,
                          fontWeight: FontWeight.w600,
                          height: 1.12,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.muted,
                          height: 1.14,
                        ),
                  ),
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
  final _ScanPassPhase phase;
  final AppLocalizations l10n;

  const _ScanPassPhaseStrip({required this.phase, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    final items = [
      (_ScanPassPhase.observe, '01', l10n.scanPassStageObserve),
      (_ScanPassPhase.firstTouch, '02', l10n.scanPassStageFirstTouch),
      (_ScanPassPhase.nextAction, '03', l10n.scanPassStageNextAction),
      (_ScanPassPhase.review, '04', l10n.scanPassStageReview),
    ];
    final activeIndex = items.indexWhere((item) => item.$1 == phase);
    return Row(
      children: [
        for (var i = 0; i < items.length; i += 1) ...[
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 2,
                    color: i == activeIndex ? colors.accent : colors.line,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      items[i].$2,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color:
                                i == activeIndex ? colors.accent : colors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        items[i].$3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color:
                                  i == activeIndex ? colors.text : colors.muted,
                              fontWeight: i == activeIndex
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (i != items.length - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

class _ScanPassLegend extends StatelessWidget {
  final AppLocalizations l10n;

  const _ScanPassLegend({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colors.muted,
          fontWeight: FontWeight.w500,
        );
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _LegendItem(
          color: colors.self,
          label: l10n.scanPassLegendBallCarrier,
          style: style,
        ),
        _LegendItem(
          color: colors.team,
          label: l10n.scanPassLegendTeammate,
          style: style,
        ),
        _LegendItem(
          color: colors.defender,
          label: l10n.scanPassLegendDefender,
          style: style,
          diamond: true,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              child: Divider(color: colors.muted, thickness: 1),
            ),
            const SizedBox(width: 6),
            Text(l10n.scanPassLegendRoute, style: style),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final TextStyle? style;
  final bool diamond;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.style,
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
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(diamond ? 0 : 2),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: style),
      ],
    );
  }
}

class _ReviewRows extends StatelessWidget {
  final List<_ReviewRowData> rows;

  const _ReviewRows({required this.rows});

  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          row.label,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.muted,
                                    height: 1.18,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          row.value,
                          textAlign: TextAlign.end,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.accent,
                                    fontWeight: FontWeight.w600,
                                    height: 1.18,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    row.body,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.muted,
                          height: 1.25,
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

class _ReviewRowData {
  final String label;
  final String value;
  final String body;

  const _ReviewRowData({
    required this.label,
    required this.value,
    required this.body,
  });
}

class _DetailedEvaluation extends StatelessWidget {
  final AppLocalizations l10n;
  final ScanPassPlanResult result;
  final ScanPassPlanEvaluation evaluation;
  final String selectedPlanId;
  final String Function(AppLocalizations, ScanPassPlanResult) actionName;

  const _DetailedEvaluation({
    required this.l10n,
    required this.result,
    required this.evaluation,
    required this.selectedPlanId,
    required this.actionName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: colors.accent.withValues(alpha: 0.08),
        highlightColor: colors.accent.withValues(alpha: 0.08),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(6),
        ),
        child: ExpansionTile(
          key: const ValueKey<String>('scan-pass-details-expansion'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          iconColor: colors.text,
          collapsedIconColor: colors.muted,
          title: Text(
            l10n.scanPassDetailedEvaluationTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w600,
                ),
          ),
          subtitle: Text(
            l10n.scanPassDetailedEvaluationSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.muted,
                  height: 1.22,
                ),
          ),
          children: [
            _ScanPassScoreBreakdown(result: result, l10n: l10n),
            const SizedBox(height: 10),
            _ScanPassReasonPanel(result: result, l10n: l10n),
            const SizedBox(height: 10),
            _ScanPassPlanComparison(
              evaluation: evaluation,
              selectedPlanId: selectedPlanId,
              l10n: l10n,
              actionName: actionName,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanPassReviewToggle extends StatelessWidget {
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
    final colors = _ScanPassColors.of(context);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? colors.accent : colors.text,
        backgroundColor:
            selected ? colors.active : colors.surface.withValues(alpha: 0.70),
        side: BorderSide(color: selected ? colors.accent : colors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _ScanPassScoreBreakdown extends StatelessWidget {
  final ScanPassPlanResult result;
  final AppLocalizations l10n;

  const _ScanPassScoreBreakdown({
    required this.result,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    return Column(
      key: const ValueKey<String>('scan-pass-score-breakdown'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.scanPassScoreBreakdownTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w600,
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
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final component in result.components) ...[
          _ScanPassComponentRow(component: component, l10n: l10n),
          if (component != result.components.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ScanPassComponentRow extends StatelessWidget {
  final ScanPassScoreComponent component;
  final AppLocalizations l10n;

  const _ScanPassComponentRow({
    required this.component,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    return Column(
      key: ValueKey<String>('scan-pass-component-${component.kind.name}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _componentLabel(l10n, component.kind),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Text(
              l10n.scanPassComponentValue(component.earned, component.max),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            minHeight: 4,
            value: (component.earned / component.max).clamp(0.0, 1.0),
            backgroundColor: colors.line,
            valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
          ),
        ),
      ],
    );
  }
}

class _ScanPassReasonPanel extends StatelessWidget {
  final ScanPassPlanResult result;
  final AppLocalizations l10n;

  const _ScanPassReasonPanel({required this.result, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    final reasons = result.reasons.take(3).toList(growable: false);
    return Column(
      key: const ValueKey<String>('scan-pass-reason-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.scanPassReasonPanelTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 7),
        for (final reason in reasons)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(Icons.remove, size: 13, color: colors.accent),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _reasonText(l10n, reason),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.muted,
                          height: 1.24,
                        ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ScanPassPlanComparison extends StatelessWidget {
  final ScanPassPlanEvaluation evaluation;
  final String selectedPlanId;
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
    final colors = _ScanPassColors.of(context);
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
                color: colors.text,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 7),
        for (final plan in shown) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: plan.planId == selectedPlanId
                  ? colors.active
                  : colors.surface.withValues(alpha: 0.54),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color:
                    plan.planId == selectedPlanId ? colors.accent : colors.line,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      actionName(l10n, plan),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.text,
                            fontWeight: FontWeight.w600,
                            height: 1.16,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.scanPassComponentValue(
                      plan.totalScore,
                      ScanPassScoreWeights.total,
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w600,
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

class _ScanPassColors {
  final Color background;
  final Color surface;
  final Color text;
  final Color muted;
  final Color line;
  final Color accent;
  final Color active;
  final Color team;
  final Color defender;
  final Color self;

  const _ScanPassColors({
    required this.background,
    required this.surface,
    required this.text,
    required this.muted,
    required this.line,
    required this.accent,
    required this.active,
    required this.team,
    required this.defender,
    required this.self,
  });

  factory _ScanPassColors.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark) {
      return const _ScanPassColors(
        background: Color(0xFF141D21),
        surface: Color(0xFF1C282E),
        text: Color(0xFFE9EEEB),
        muted: Color(0xFFA7B8BB),
        line: Color(0xFF34454B),
        accent: Color(0xFFDDC18D),
        active: Color(0xFF3B382D),
        team: Color(0xFF8EB2C3),
        defender: Color(0xFFCF927B),
        self: Color(0xFFDDC18D),
      );
    }
    return const _ScanPassColors(
      background: Color(0xFFF2F4F2),
      surface: Color(0xFFFFFFFF),
      text: Color(0xFF202E33),
      muted: Color(0xFF53666D),
      line: Color(0xFFCCD5D3),
      accent: Color(0xFF785C25),
      active: Color(0xFFE7DCC5),
      team: Color(0xFF47748A),
      defender: Color(0xFFA86250),
      self: Color(0xFFA88644),
    );
  }
}

enum _TextAnchor { left, center, right }

Offset _toOffset(ScanPassPoint point, Size size) {
  return Offset(point.x * size.width, point.y * size.height);
}

double _observationTime(ScanPassScenario scenario) {
  return scenario.ballTravelTime * 0.34;
}

String _sceneTitle(AppLocalizations l10n, ScanPassScenario scenario) {
  return switch (scenario.family) {
    ScanPassScenarioFamily.rearPressUpper ||
    ScanPassScenarioFamily.rearPressLower =>
      l10n.scanPassSceneRearPressureTitle,
    ScanPassScenarioFamily.retreatingPressure =>
      l10n.scanPassFamilyRetreatingPressure,
    ScanPassScenarioFamily.markedSupport => l10n.scanPassFamilyMarkedSupport,
    ScanPassScenarioFamily.closingForwardLane =>
      l10n.scanPassFamilyClosingForwardLane,
    ScanPassScenarioFamily.returnReceive => l10n.scanPassFamilyReturnReceive,
  };
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
