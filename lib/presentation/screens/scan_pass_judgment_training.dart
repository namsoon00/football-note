part of 'scan_pass_game_screen.dart';

enum _JudgmentUiPhase { observing, choosing, executing, review, summary }

class JudgmentEpisodeTrainingScreen extends StatefulWidget {
  final int? seed;
  final Duration observationDuration;
  final Duration executionDuration;
  final WidgetBuilder? freeAttackBuilder;

  const JudgmentEpisodeTrainingScreen({
    super.key,
    this.seed,
    this.observationDuration = const Duration(milliseconds: 2400),
    this.executionDuration = const Duration(milliseconds: 1800),
    this.freeAttackBuilder,
  });

  @override
  State<JudgmentEpisodeTrainingScreen> createState() =>
      _JudgmentEpisodeTrainingScreenState();
}

class _JudgmentEpisodeTrainingScreenState
    extends State<JudgmentEpisodeTrainingScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final JudgmentEngine _engine = const JudgmentEngine();
  late final AnimationController _observationController;
  late final AnimationController _executionController;

  late List<JudgmentSceneSpec> _session;
  late JudgmentScene _scene;
  late JudgmentPhase _decision;
  int _sessionSeed = 0;
  int _sceneIndex = 0;
  int _sceneToken = 0;
  _JudgmentUiPhase _phase = _JudgmentUiPhase.observing;
  JudgmentResult? _activeResult;
  JudgmentResult? _terminalResult;
  JudgmentResult? _viewResult;
  List<JudgmentResult> _alternatives = const <JudgmentResult>[];
  int _alternativeIndex = -1;
  final List<JudgmentResult> _episodeResults = <JudgmentResult>[];
  final List<_JudgmentRecord> _records = <_JudgmentRecord>[];
  bool _foreground = true;
  bool _helpOpen = false;
  bool _observationReplay = false;
  bool _executingAlternative = false;
  bool _replayingChoice = false;
  bool _fullPitchOverview = false;
  int _replayResultIndex = 0;
  int _reviewIndex = 0;
  int _recurrenceCount = 0;
  final Set<JudgmentFamily> _recurrenceFamilies = {};
  bool _replayingLeadIn = false;
  _PitchFrame? _focusFrame;

  bool get _canChoose => _phase == _JudgmentUiPhase.choosing;

  List<AttackTransition> get _episodeTransitions => [
        for (final result in _episodeResults) ...result.transitions,
      ];

  List<AttackTransition> get _historyForPainter {
    final active = _activeResult;
    if (_phase == _JudgmentUiPhase.executing && active != null) {
      if (_executingAlternative) {
        return _transitionsBefore(active.phase);
      }
      if (_replayingChoice) {
        return [
          for (var i = 0; i < _replayResultIndex; i += 1)
            ..._episodeResults[i].transitions,
        ];
      }
      return _transitionsBefore(active.phase);
    }
    final view = _viewResult;
    if (_phase == _JudgmentUiPhase.review && view != null) {
      return [..._transitionsBefore(view.phase), ...view.transitions];
    }
    return _episodeTransitions;
  }

  AttackState get _displayState {
    if (_phase == _JudgmentUiPhase.observing) {
      return _engine.observationFrame(_scene, _observationController.value);
    }
    if (_phase == _JudgmentUiPhase.executing && _activeResult != null) {
      return _activeResult!.frame(_executionController.value);
    }
    if (_phase == _JudgmentUiPhase.review && _viewResult != null) {
      return _viewResult!.after;
    }
    return _decision.state;
  }

  AttackState get _baseState {
    final active = _activeResult;
    if (_phase == _JudgmentUiPhase.executing && active != null) {
      return active.before;
    }
    final view = _viewResult;
    if (_phase == _JudgmentUiPhase.review && view != null) {
      return view.before;
    }
    return _decision.state;
  }

  ({AttackTransition transition, double progress})? get _activeMotion {
    if (_phase == _JudgmentUiPhase.observing) {
      return (
        transition: AttackTransition(
          before: _scene.initial,
          after: _scene.reception,
          action: const AttackAction.pass(6),
          duration: 2.4,
          ballEnd: _scene.reception.ball,
        ),
        progress: _observationController.value,
      );
    }
    final result = _activeResult;
    if (_phase != _JudgmentUiPhase.executing || result == null) return null;
    var remaining = result.duration * _executionController.value;
    for (final transition in result.transitions) {
      if (remaining <= transition.duration) {
        return (
          transition: transition,
          progress:
              transition.duration <= 0 ? 1 : remaining / transition.duration,
        );
      }
      remaining -= transition.duration;
    }
    return result.transitions.isEmpty
        ? null
        : (transition: result.transitions.last, progress: 1);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionSeed = widget.seed ?? 0;
    _observationController = AnimationController(vsync: this)
      ..addStatusListener(_handleObservationStatus);
    _executionController = AnimationController(vsync: this)
      ..addStatusListener(_handleExecutionStatus);
    _startSession();
  }

  @override
  void didUpdateWidget(covariant JudgmentEpisodeTrainingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed) {
      _sessionSeed = widget.seed ?? 0;
      _startSession();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _observationController.dispose();
    _executionController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _foreground = false;
      _observationController.stop();
      _executionController.stop();
      return;
    }
    if (state != AppLifecycleState.resumed || !mounted) return;
    _foreground = true;
    if (_helpOpen) return;
    _resumeMotion();
  }

  void _startSession() {
    _session = _engine.session(seed: _sessionSeed).toList();
    _sceneIndex = 0;
    _records.clear();
    _recurrenceCount = 0;
    _recurrenceFamilies.clear();
    _loadScene(replayObservation: false);
  }

  void _loadScene({required bool replayObservation}) {
    _sceneToken += 1;
    final token = _sceneToken;
    _scene = _engine.scene(_session[_sceneIndex]);
    _decision = _engine.firstPhase(_scene);
    _focusFrame = _judgmentFocusFrame(_scene);
    _phase = _JudgmentUiPhase.observing;
    _activeResult = null;
    _terminalResult = null;
    _viewResult = null;
    _alternatives = const <JudgmentResult>[];
    _alternativeIndex = -1;
    _episodeResults.clear();
    _observationReplay = replayObservation;
    _executingAlternative = false;
    _replayingChoice = false;
    _replayResultIndex = 0;
    _reviewIndex = 0;
    _replayingLeadIn = false;
    _executionController
      ..stop()
      ..value = 0;
    _observationController
      ..stop()
      ..value = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || token != _sceneToken) return;
      _runObservation();
    });
  }

  void _runObservation() {
    _observationController.stop();
    if (AppMotion.reduceMotion(context) ||
        widget.observationDuration == Duration.zero) {
      _observationController.value = 1;
      _finishObservation();
      return;
    }
    _observationController.duration = widget.observationDuration;
    unawaited(_observationController.forward(from: 0));
  }

  void _handleObservationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      _finishObservation();
    }
  }

  void _finishObservation() {
    if (!mounted || _phase != _JudgmentUiPhase.observing) return;
    if (_observationReplay && _episodeResults.isNotEmpty) {
      setState(() {
        _observationReplay = false;
        _replayingLeadIn = true;
        _replayingChoice = true;
        _replayResultIndex = 0;
        _activeResult = _episodeResults.first;
        _phase = _JudgmentUiPhase.executing;
      });
      _runExecution(_activeResult!);
      return;
    }
    setState(() {
      _phase = _JudgmentUiPhase.choosing;
      _observationReplay = false;
    });
  }

  void _choose(JudgmentChoice choice) {
    if (!_canChoose) return;
    final result = _engine.choose(_decision, choice);
    final alternatives = _engine
        .alternatives(_decision)
        .where((item) => item.choice.action != choice.action)
        .toList(growable: false);
    setState(() {
      _activeResult = result;
      _viewResult = result;
      _alternatives = alternatives;
      _alternativeIndex = -1;
      _phase = _JudgmentUiPhase.executing;
      _executingAlternative = false;
      _replayingChoice = false;
    });
    HapticFeedback.mediumImpact();
    _runExecution(result);
  }

  void _runExecution(JudgmentResult result) {
    _executionController
      ..stop()
      ..value = 0;
    if (AppMotion.reduceMotion(context) ||
        widget.executionDuration == Duration.zero) {
      _executionController.value = 1;
      _handleExecutionStatus(AnimationStatus.completed);
      return;
    }
    final maximum = math.max(1, widget.executionDuration.inMilliseconds);
    final model = (result.duration * 1000).round();
    _executionController.duration = Duration(
      milliseconds: model.clamp(math.min(620, maximum), maximum),
    );
    unawaited(_executionController.forward(from: 0));
  }

  void _handleExecutionStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    final result = _activeResult;
    if (_phase != _JudgmentUiPhase.executing || result == null) return;
    if (_executingAlternative) {
      setState(() {
        _phase = _JudgmentUiPhase.review;
        _activeResult = null;
        _executionController.value = 0;
      });
      return;
    }
    if (_replayingChoice) {
      if (_replayResultIndex + 1 < _episodeResults.length) {
        setState(() {
          _replayResultIndex += 1;
          _activeResult = _episodeResults[_replayResultIndex];
          _executionController.value = 0;
        });
        _runExecution(_activeResult!);
        return;
      }
      setState(() {
        _phase = _replayingLeadIn
            ? _JudgmentUiPhase.choosing
            : _JudgmentUiPhase.review;
        _replayingLeadIn = false;
        _activeResult = null;
        _replayingChoice = false;
        _executionController.value = 0;
      });
      return;
    }
    final next = result.nextPhase;
    setState(() {
      _episodeResults.add(result);
      _activeResult = null;
      _executionController.value = 0;
      if (next != null) {
        _decision = next;
        _phase = _JudgmentUiPhase.choosing;
      } else {
        _terminalResult = result;
        _viewResult = result;
        _phase = _JudgmentUiPhase.review;
        _reviewIndex = _episodeResults.length - 1;
        _records.removeWhere((record) => record.sceneIndex == _sceneIndex);
        _records.add(_JudgmentRecord(
          sceneIndex: _sceneIndex,
          family: _scene.spec.family,
          quality: result.quality,
          reason: result.reason,
        ));
        _scheduleRecurrence(result);
      }
    });
  }

  void _scheduleRecurrence(JudgmentResult result) {
    if (_sceneIndex >= 8 ||
        _recurrenceCount >= 2 ||
        _recurrenceFamilies.contains(_scene.spec.family)) {
      return;
    }
    if (result.quality == JudgmentQuality.lost ||
        result.reason == JudgmentReason.pressureRemains ||
        result.reason == JudgmentReason.optionsReduced) {
      final slot = 8 + _recurrenceCount;
      if (slot < _session.length) {
        _session[slot] = _scene.spec.nextConfiguration();
        _recurrenceFamilies.add(_scene.spec.family);
        _recurrenceCount++;
      }
    }
  }

  void _selectReview(int index) {
    if (_phase != _JudgmentUiPhase.review || index >= _episodeResults.length) {
      return;
    }
    final result = _episodeResults[index];
    setState(() {
      _reviewIndex = index;
      _viewResult = result;
      _alternativeIndex = -1;
      _alternatives = _engine
          .alternatives(result.phase)
          .where((item) => item.choice.action != result.choice.action)
          .toList();
    });
  }

  void _resumeMotion() {
    if (_phase == _JudgmentUiPhase.observing &&
        !_observationController.isCompleted) {
      unawaited(_observationController.forward());
    }
    if (_phase == _JudgmentUiPhase.executing &&
        !_executionController.isCompleted) {
      unawaited(_executionController.forward());
    }
  }

  Future<void> _pauseForModal(Future<void> Function() open) async {
    if (_helpOpen) return;
    _helpOpen = true;
    final observationWasAnimating = _observationController.isAnimating;
    final executionWasAnimating = _executionController.isAnimating;
    _observationController.stop();
    _executionController.stop();
    await open();
    if (!mounted) return;
    _helpOpen = false;
    if (!_foreground) return;
    if (observationWasAnimating && _phase == _JudgmentUiPhase.observing) {
      unawaited(_observationController.forward());
    }
    if (executionWasAnimating && _phase == _JudgmentUiPhase.executing) {
      unawaited(_executionController.forward());
    }
  }

  void _replayObservation() {
    if (_phase == _JudgmentUiPhase.executing ||
        _phase == _JudgmentUiPhase.summary) {
      return;
    }
    setState(() {
      _phase = _JudgmentUiPhase.observing;
      _observationReplay = true;
      _observationController.value = 0;
    });
    _runObservation();
  }

  void _replayChoice() {
    if (_phase != _JudgmentUiPhase.review || _episodeResults.isEmpty) return;
    _selectReview(_episodeResults.length - 1);
    setState(() {
      _replayingLeadIn = false;
      _replayingChoice = true;
      _executingAlternative = false;
      _replayResultIndex = 0;
      _activeResult = _episodeResults.first;
      _viewResult = _terminalResult;
      _phase = _JudgmentUiPhase.executing;
    });
    _runExecution(_activeResult!);
  }

  void _viewAlternative() {
    final base =
        _episodeResults.isEmpty ? null : _episodeResults[_reviewIndex].phase;
    if (_phase != _JudgmentUiPhase.review ||
        base == null ||
        _alternatives.isEmpty) {
      return;
    }
    final nextIndex = (_alternativeIndex + 1) % _alternatives.length;
    final alternative = _alternatives[nextIndex];
    setState(() {
      _alternativeIndex = nextIndex;
      _activeResult = alternative;
      _viewResult = alternative;
      _executingAlternative = true;
      _replayingChoice = false;
      _phase = _JudgmentUiPhase.executing;
    });
    _runExecution(alternative);
  }

  void _practiceCuePair() {
    if (_phase != _JudgmentUiPhase.review ||
        _sceneIndex + 1 >= _session.length) {
      return;
    }
    _session[_sceneIndex + 1] = _scene.spec.pairedCue();
    _continueSession();
  }

  void _toggleOverview() {
    setState(() {
      _fullPitchOverview = !_fullPitchOverview;
    });
  }

  void _showCoachDetail() {
    final result = _viewResult;
    if (_phase != _JudgmentUiPhase.review || result == null) return;
    final l10n = AppLocalizations.of(context)!;
    final evidence = _coachingEvidence(result);
    unawaited(_pauseForModal(() => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          useSafeArea: true,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .76,
          ),
          builder: (context) {
            final colors = _ScanPassColors.of(context);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          l10n.scanPassJudgmentCoachDetailTitle,
                          key: const ValueKey<String>(
                              'judgment-coach-detail-sheet'),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: colors.text,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.scanPassHelpCloseAction),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _coachDetailLine(
                              l10n.scanPassJudgmentCoachObservedLabel,
                              _coachObserved(l10n, evidence),
                              colors,
                            ),
                            _coachDetailLine(
                              l10n.scanPassJudgmentCoachConsequenceLabel,
                              _coachConsequence(l10n, result, evidence),
                              colors,
                            ),
                            _coachDetailLine(
                              l10n.scanPassJudgmentCoachConnectionsLabel,
                              _coachConnections(l10n, result),
                              colors,
                            ),
                            _coachDetailLine(
                              l10n.scanPassJudgmentCoachNextLabel,
                              _coachNext(l10n, evidence),
                              colors,
                            ),
                            _coachDetailLine(
                              l10n.scanPassJudgmentCoachAlternativeLabel,
                              _coachAlternative(l10n, evidence),
                              colors,
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
        )));
  }

  void _retryScene() {
    if (_phase == _JudgmentUiPhase.summary) return;
    setState(() {
      _loadScene(replayObservation: true);
    });
  }

  void _continueSession() {
    if (_phase != _JudgmentUiPhase.review) return;
    if (_sceneIndex + 1 >= _session.length) {
      setState(() {
        _phase = _JudgmentUiPhase.summary;
        _activeResult = null;
        _viewResult = null;
      });
      return;
    }
    setState(() {
      _sceneIndex += 1;
      _loadScene(replayObservation: true);
    });
  }

  void _freshSession() {
    setState(() {
      _sessionSeed += 11;
      _startSession();
    });
  }

  void _openFreeAttack() {
    final builder = widget.freeAttackBuilder;
    if (builder == null) return;
    unawaited(_pauseForModal(() async {
      await Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: builder));
    }));
  }

  void _showHelp() {
    final l10n = AppLocalizations.of(context)!;
    unawaited(_pauseForModal(() => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          useSafeArea: true,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .85,
          ),
          builder: (context) {
            final colors = _ScanPassColors.of(context);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          l10n.scanPassHelpSheetTitle,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: colors.text,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.scanPassHelpCloseAction),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Text(
                          l10n.scanPassJudgmentHelpBody,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: colors.muted, height: 1.45),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        )));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = _ScanPassColors.of(context);
    return Theme(
      data: Theme.of(context).copyWith(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
        ),
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
            if (widget.freeAttackBuilder != null)
              AppBarActionButton.label(
                key: const ValueKey<String>('judgment-free-attack'),
                tooltip: l10n.scanPassFreeAttackTooltip,
                onPressed: _openFreeAttack,
                icon: const Icon(Icons.sports_soccer_outlined),
                label: l10n.scanPassFreeAttackAction,
                maxLabelWidth: 92,
              ),
            AppBarActionButton(
              key: const ValueKey<String>('judgment-help'),
              tooltip: l10n.scanPassHelpAction,
              onPressed: _showHelp,
              icon: const Icon(Icons.help_outline),
            ),
          ],
        ),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge(
              [_observationController, _executionController],
            ),
            builder: (context, _) => _buildBoard(l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildBoard(AppLocalizations l10n) {
    return LayoutBuilder(builder: (context, constraints) {
      final landscape = constraints.maxWidth > constraints.maxHeight &&
          constraints.maxHeight < 430;
      final strip = Padding(
        padding: EdgeInsets.fromLTRB(
          landscape ? 10 : 14,
          landscape ? 8 : 10,
          landscape ? 8 : 14,
          0,
        ),
        child: _buildStrip(l10n),
      );
      final pitch = Padding(
        padding: EdgeInsets.fromLTRB(
          landscape ? 10 : 14,
          landscape ? 8 : 10,
          landscape ? 8 : 14,
          landscape ? 8 : 10,
        ),
        child: _buildPitch(l10n),
      );
      final dock = _buildDock(l10n, landscape: landscape);
      if (landscape) {
        final dockWidth = math.min(238.0, constraints.maxWidth * .38);
        return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [strip, Expanded(child: pitch)],
            ),
          ),
          SizedBox(width: dockWidth, child: dock),
        ]);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [strip, Expanded(child: pitch), dock],
      );
    });
  }

  Widget _buildStrip(AppLocalizations l10n) {
    final colors = _ScanPassColors.of(context);
    return SizedBox(
      height: math.max(
        48,
        MediaQuery.textScalerOf(context).scale(13) * 1.08 * 2 + 4,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
          child: Row(children: [
            Icon(Icons.visibility_outlined, color: colors.accent, size: 18),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                _status(l10n),
                key: const ValueKey<String>('judgment-status'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w600,
                      height: 1.14,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            _MiniChip(
              text: MediaQuery.sizeOf(context).width >= 700
                  ? l10n.scanPassJudgmentProgress(
                      math.min(_sceneIndex + 1, _session.length),
                      _session.length,
                      _familyLabel(l10n, _scene.spec.family),
                    )
                  : l10n.scanPassRoundStatus(
                      math.min(_sceneIndex + 1, _session.length),
                      _session.length),
              color: colors.background,
            ),
            const SizedBox(width: 4),
            AppBarActionButton(
              key: const ValueKey<String>('judgment-overview-toggle'),
              tooltip: _fullPitchOverview
                  ? l10n.scanPassJudgmentFocusAction
                  : l10n.scanPassJudgmentOverviewAction,
              onPressed: _toggleOverview,
              compact: true,
              margin: EdgeInsets.zero,
              icon: Icon(
                  _fullPitchOverview
                      ? Icons.center_focus_strong_outlined
                      : Icons.fullscreen_outlined,
                  size: 18),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildPitch(AppLocalizations l10n) {
    final labels = _PitchLabels.from(l10n);
    final colors = _ScanPassColors.of(context);
    final motion = _activeMotion;
    final view = _viewResult;
    final reviewEvidence = _phase == _JudgmentUiPhase.review && view != null
        ? _coachingEvidence(view)
        : null;
    final frame = _fullPitchOverview ? null : _focusFrame;
    return LayoutBuilder(builder: (context, constraints) {
      final portrait = MediaQuery.sizeOf(context).width < 600 &&
          MediaQuery.sizeOf(context).height > MediaQuery.sizeOf(context).width;
      final availableAspect = constraints.maxWidth / constraints.maxHeight;
      final aspect = _fullPitchOverview
          ? availableAspect.clamp(portrait ? .95 : 1.55, portrait ? 1.35 : 2.6)
          : availableAspect;
      return Center(
        child: AspectRatio(
          aspectRatio: aspect,
          child: ClipRect(
              child: Stack(fit: StackFit.expand, children: [
            Semantics(
              label: l10n.scanPassJudgmentFieldSemantics,
              image: true,
              child: CustomPaint(
                key: const ValueKey<String>('judgment-pitch'),
                painter: _AttackPitchPainter(
                  displayState: _displayState,
                  baseState: _baseState,
                  selectedAction: null,
                  selectedTarget: null,
                  previewOffside: null,
                  activeTransition: motion?.transition,
                  activeProgress: motion?.progress ?? 0,
                  history: _historyForPainter,
                  scanOverlay: false,
                  terminalBanner: false,
                  labels: labels,
                  brightness: Theme.of(context).brightness,
                  fontFamily:
                      Theme.of(context).textTheme.bodyMedium?.fontFamily,
                  learnerNumber: 6,
                  focusFrame: frame,
                  decisionCueFrom: reviewEvidence?.observedCue.from,
                  decisionCueTo: reviewEvidence?.observedCue.to,
                  decisionCueIsOpponent:
                      reviewEvidence?.observedCue.opponent ?? false,
                  decisionPressurePoint: _phase == _JudgmentUiPhase.review
                      ? view?.pressurePoint
                      : null,
                  decisionOutletPoints:
                      _phase == _JudgmentUiPhase.review && view != null
                          ? view.outletPoints
                          : const <ScanPassPoint>[],
                  decisionBranchLabel:
                      _phase == _JudgmentUiPhase.review && view != null
                          ? _branchLabel(l10n, view)
                          : null,
                ),
              ),
            ),
            if (_canChoose)
              LayoutBuilder(builder: (context, box) {
                final size = Size(box.maxWidth, box.maxHeight);
                final geometry = _PitchGeometry(size, frame: frame);
                final centers =
                    _judgmentOptionCenters(_decision, geometry, size);
                final origin = geometry.toOffset(_decision.state.attackers
                    .firstWhere((p) => p.number == _decision.activeNumber)
                    .position);
                return Stack(children: [
                  IgnorePointer(
                      child: CustomPaint(
                          size: size,
                          painter: _JudgmentOptionPaths(
                              origin: origin,
                              targets: _decision.choices
                                  .map((c) => geometry.toOffset(c.target))
                                  .toList(),
                              centers: centers,
                              color: colors.team))),
                  for (var i = 0; i < _decision.choices.length; i++)
                    _PitchButton(
                      key: ValueKey<String>(
                          'judgment-action-${_decision.choices[i].action.name}'),
                      center: centers[i],
                      label:
                          _actionSemantics(l10n, _decision.choices[i].action),
                      selected: false,
                      color: colors.team,
                      onPressed: () => _choose(_decision.choices[i]),
                      child: _pitchButtonChild(_decision.choices[i]),
                    ),
                ]);
              }),
          ])),
        ),
      );
    });
  }

  Widget _pitchButtonChild(JudgmentChoice choice) {
    final number = choice.targetNumber;
    if (number != null) {
      return Text(
        number.toString(),
        style: const TextStyle(fontWeight: FontWeight.w800),
      );
    }
    return Icon(_actionIcon(choice.action), size: 18);
  }

  Widget _buildDock(AppLocalizations l10n, {required bool landscape}) {
    final colors = _ScanPassColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: landscape ? BorderSide.none : BorderSide(color: colors.line),
          left: landscape ? BorderSide(color: colors.line) : BorderSide.none,
        ),
      ),
      child: SafeArea(
        top: false,
        left: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            landscape ? 10 : 14,
            10,
            landscape ? 10 : 14,
            10,
          ),
          child: SizedBox(
            height: landscape ? null : _dockHeight(),
            child: Align(
              alignment: Alignment.topCenter,
              child: _dockContent(l10n, landscape: landscape),
            ),
          ),
        ),
      ),
    );
  }

  double _dockHeight() {
    final width = MediaQuery.sizeOf(context).width;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final small = width < 380;
    final base = switch (_phase) {
      _JudgmentUiPhase.observing => 86.0,
      _JudgmentUiPhase.executing => 20.0,
      _JudgmentUiPhase.choosing => small ? 146.0 : 140.0,
      _JudgmentUiPhase.review => small ? 172.0 : 166.0,
      _JudgmentUiPhase.summary => 190.0,
    };
    return base + math.max(0, scale - 1) * 50;
  }

  Widget _dockContent(AppLocalizations l10n, {required bool landscape}) {
    return switch (_phase) {
      _JudgmentUiPhase.summary => _summaryDock(l10n),
      _JudgmentUiPhase.executing => _busyDock(),
      _JudgmentUiPhase.review => _reviewDock(l10n),
      _ => _choiceDock(l10n, landscape: landscape),
    };
  }

  Widget _choiceDock(AppLocalizations l10n, {required bool landscape}) {
    final colors = _ScanPassColors.of(context);
    final compact = landscape || MediaQuery.sizeOf(context).width < 1000;
    final buttons = [
      for (final choice in _decision.choices)
        _DockActionButton(
          key: ValueKey<String>('judgment-dock-${choice.action.name}'),
          selected: false,
          icon: _actionIcon(choice.action),
          label: _actionLabel(l10n, choice.action),
          semanticsLabel: _actionSemantics(l10n, choice.action),
          compact: compact,
          onPressed: _canChoose ? () => _choose(choice) : () {},
        ),
    ];
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _phaseHeader(l10n),
          const SizedBox(height: 7),
          if (_canChoose)
            compact
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final button in buttons)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: SizedBox(width: 76, child: button),
                        ),
                    ]),
                  )
                : Row(children: [
                    for (final button in buttons)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: button,
                        ),
                      ),
                  ])
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                minHeight: 4,
                value: _observationController.value.clamp(0.0, 1.0),
                backgroundColor: colors.line,
                valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
              ),
            ),
          const SizedBox(height: 7),
          OutlinedButton.icon(
            key: const ValueKey<String>('judgment-replay-observation'),
            onPressed: _replayObservation,
            icon: const Icon(Icons.replay, size: 18),
            label: Text(l10n.scanPassJudgmentReplayObservationAction),
            style: _outlinedStyle(colors),
          ),
        ],
      ),
    );
  }

  Widget _phaseHeader(AppLocalizations l10n) {
    final colors = _ScanPassColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(children: [
          Icon(_phaseIcon(), size: 16, color: colors.accent),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              _phaseLabel(l10n),
              key: const ValueKey<String>('judgment-phase-label'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _busyDock() {
    final colors = _ScanPassColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            minHeight: 4,
            value: _executionController.value.clamp(0.0, 1.0),
            backgroundColor: colors.line,
            valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
          ),
        ),
      ],
    );
  }

  Widget _reviewDock(AppLocalizations l10n) {
    final colors = _ScanPassColors.of(context);
    final result = _viewResult;
    final evidence = result == null ? null : _coachingEvidence(result);
    return LayoutBuilder(builder: (context, constraints) {
      final compact =
          constraints.maxWidth / MediaQuery.textScalerOf(context).scale(1) <
              370;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (var i = 0; i < _episodeResults.length; i++)
                Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                        key: ValueKey('judgment-moment-$i'),
                        visualDensity: VisualDensity.compact,
                        label: Text(_actionLabel(
                            l10n, _episodeResults[i].choice.action)),
                        selected: i == _reviewIndex,
                        onSelected: (_) => _selectReview(i))),
            ])),
        if (result != null && evidence != null)
          Semantics(
              key: const ValueKey<String>('judgment-review-result'),
              liveRegion: true,
              child: Padding(
                  padding: const EdgeInsets.only(top: 3, bottom: 4),
                  child: Text(_coachCompact(l10n, result, evidence),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.text,
                          height: 1.16,
                          fontWeight: FontWeight.w600)))),
        Row(children: [
          Expanded(
              child: AppBarActionButton(
                  key: const ValueKey<String>('judgment-replay-choice'),
                  tooltip: l10n.scanPassJudgmentReplayChoiceAction,
                  onPressed: _replayChoice,
                  compact: true,
                  margin: EdgeInsets.zero,
                  icon: const Icon(Icons.replay, size: 17),
                  label: compact
                      ? l10n.scanPassJudgmentReplayShort
                      : l10n.scanPassJudgmentReplayChoiceAction,
                  maxLabelWidth: 280)),
          const SizedBox(width: 3),
          Expanded(
              child: AppBarActionButton(
                  key: const ValueKey<String>('judgment-view-alternative'),
                  tooltip: l10n.scanPassJudgmentViewAlternativeAction,
                  onPressed: _alternatives.isEmpty ? null : _viewAlternative,
                  compact: true,
                  margin: EdgeInsets.zero,
                  icon: const Icon(Icons.compare_arrows_outlined, size: 17),
                  label: compact
                      ? l10n.scanPassJudgmentCompareShort
                      : l10n.scanPassJudgmentViewAlternativeAction,
                  maxLabelWidth: 280)),
          const SizedBox(width: 3),
          Expanded(
              child: AppBarActionButton(
                  key: const ValueKey<String>('judgment-coach-detail'),
                  tooltip: l10n.scanPassJudgmentCoachDetailAction,
                  onPressed: _showCoachDetail,
                  compact: true,
                  margin: EdgeInsets.zero,
                  icon: const Icon(Icons.lightbulb_outline, size: 17),
                  label: l10n.scanPassJudgmentCoachShort)),
        ]),
        Row(children: [
          if (compact) ...[
            AppBarActionButton(
                key: const ValueKey<String>('judgment-retry'),
                tooltip: l10n.scanPassJudgmentRetryAction,
                onPressed: _retryScene,
                compact: true,
                margin: EdgeInsets.zero,
                icon: const Icon(Icons.refresh_outlined)),
            const SizedBox(width: 3),
            AppBarActionButton(
                key: const ValueKey<String>('judgment-cue-pair'),
                tooltip: l10n.scanPassJudgmentPairCueAction,
                onPressed: _sceneIndex + 1 >= _session.length
                    ? null
                    : _practiceCuePair,
                compact: true,
                margin: EdgeInsets.zero,
                icon: const Icon(Icons.swap_horiz_outlined)),
          ] else ...[
            Expanded(
                child: OutlinedButton(
                    key: const ValueKey<String>('judgment-retry'),
                    onPressed: _retryScene,
                    style: _outlinedStyle(colors),
                    child: Text(l10n.scanPassJudgmentRetryAction))),
            const SizedBox(width: 6),
            Expanded(
                child: OutlinedButton.icon(
                    key: const ValueKey<String>('judgment-cue-pair'),
                    onPressed: _sceneIndex + 1 >= _session.length
                        ? null
                        : _practiceCuePair,
                    icon: const Icon(Icons.swap_horiz_outlined, size: 17),
                    label: Text(l10n.scanPassJudgmentPairCueAction),
                    style: _outlinedStyle(colors))),
          ],
          const SizedBox(width: 6),
          Expanded(
              child: FilledButton.icon(
                  key: const ValueKey<String>('judgment-next'),
                  onPressed: _continueSession,
                  icon: const Icon(Icons.arrow_forward_outlined, size: 18),
                  label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                          _sceneIndex + 1 >= _session.length
                              ? l10n.scanPassJudgmentSummaryAction
                              : l10n.scanPassJudgmentContinueAction,
                          maxLines: 1)),
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 10)))),
        ]),
      ]);
    });
  }

  Widget _summaryDock(AppLocalizations l10n) {
    final colors = _ScanPassColors.of(context);
    final lines = _summaryLines(l10n);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.scanPassJudgmentSummaryTitle,
            key: const ValueKey<String>('judgment-summary-title'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 5),
          for (final line in lines.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                line,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.muted,
                      height: 1.16,
                    ),
              ),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const ValueKey<String>('judgment-fresh-session'),
            onPressed: _freshSession,
            icon: const Icon(Icons.replay_circle_filled_outlined),
            label: Text(l10n.scanPassJudgmentFreshSessionAction),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _outlinedStyle(_ScanPassColors colors) {
    return OutlinedButton.styleFrom(
      foregroundColor: colors.text,
      side: BorderSide(color: colors.line),
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );
  }

  List<AttackTransition> _transitionsBefore(JudgmentPhase phase) {
    final result = <AttackTransition>[];
    for (final item in _episodeResults) {
      if (identical(item.phase, phase)) break;
      result.addAll(item.transitions);
    }
    return result;
  }

  String _status(AppLocalizations l10n) {
    return switch (_phase) {
      _JudgmentUiPhase.observing => _observationReplay
          ? l10n.scanPassJudgmentReplayObservationStatus
          : l10n.scanPassJudgmentObserveStatus,
      _JudgmentUiPhase.choosing => switch (_decision.kind) {
          JudgmentDecisionKind.firstTouch => l10n.scanPassJudgmentChooseTouch,
          JudgmentDecisionKind.nextAction => l10n.scanPassJudgmentChooseAction,
          JudgmentDecisionKind.support => l10n.scanPassJudgmentChooseSupport,
        },
      _JudgmentUiPhase.executing => l10n.scanPassJudgmentExecutingStatus,
      _JudgmentUiPhase.review => _viewResult == null
          ? l10n.scanPassJudgmentReviewStatus
          : l10n.scanPassJudgmentReviewStatusWithQuality(
              _qualityLabel(l10n, _viewResult!.quality),
            ),
      _JudgmentUiPhase.summary => l10n.scanPassJudgmentSummaryStatus,
    };
  }

  String _phaseLabel(AppLocalizations l10n) {
    if (_phase == _JudgmentUiPhase.observing) {
      return l10n.scanPassJudgmentPhaseObserve;
    }
    return switch (_decision.kind) {
      JudgmentDecisionKind.firstTouch => l10n.scanPassJudgmentPhaseFirstTouch,
      JudgmentDecisionKind.nextAction => l10n.scanPassJudgmentPhaseNextAction,
      JudgmentDecisionKind.support => l10n.scanPassJudgmentPhaseSupport,
    };
  }

  IconData _phaseIcon() {
    if (_phase == _JudgmentUiPhase.observing) return Icons.visibility_outlined;
    return switch (_decision.kind) {
      JudgmentDecisionKind.firstTouch => Icons.touch_app_outlined,
      JudgmentDecisionKind.nextAction => Icons.near_me_outlined,
      JudgmentDecisionKind.support => Icons.directions_run_outlined,
    };
  }

  String _branchLabel(AppLocalizations l10n, JudgmentResult result) {
    final action = _actionLabel(l10n, result.choice.action);
    return _episodeResults.contains(result)
        ? l10n.scanPassJudgmentBranchOwn(action)
        : l10n.scanPassJudgmentBranchAlternative(action);
  }

  List<String> _summaryLines(AppLocalizations l10n) {
    if (_records.isEmpty) return [l10n.scanPassJudgmentSummaryEmpty];
    final revisit = _records
        .where((record) => record.quality == JudgmentQuality.lost)
        .toList();
    final source = revisit.isEmpty ? _records : revisit;
    return [
      l10n.scanPassJudgmentSummaryCompleted(_records.length, _session.length),
      for (final record in source.take(3))
        l10n.scanPassJudgmentSummaryRevisit(
          _familyLabel(l10n, record.family),
          _reasonLabel(l10n, record.reason),
        ),
    ];
  }

  JudgmentCoachingEvidence _coachingEvidence(JudgmentResult result) =>
      _engine.coachingEvidence(
        result,
        alternatives: _engine.alternatives(result.phase),
      );

  Widget _coachDetailLine(
    String label,
    String value,
    _ScanPassColors colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.accent,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.text,
                height: 1.35,
              ),
        ),
      ]),
    );
  }

  String _coachCompact(
    AppLocalizations l10n,
    JudgmentResult result,
    JudgmentCoachingEvidence evidence,
  ) {
    return l10n.scanPassJudgmentCoachCompact(
      _actorLabel(l10n, evidence.observedCue),
      _cueKindLabel(l10n, evidence.observedCue.kind),
      _reasonLabel(l10n, result.reason),
      _habitLabel(l10n, evidence.nextHabit),
    );
  }

  String _coachObserved(
    AppLocalizations l10n,
    JudgmentCoachingEvidence evidence,
  ) {
    return l10n.scanPassJudgmentCoachObserved(
      _actorLabel(l10n, evidence.observedCue),
      _cueKindLabel(l10n, evidence.observedCue.kind),
    );
  }

  String _coachConsequence(
    AppLocalizations l10n,
    JudgmentResult result,
    JudgmentCoachingEvidence evidence,
  ) {
    if (evidence.technicalPassCompleted && !evidence.receiverSupportUseful) {
      return l10n.scanPassJudgmentCoachPassArrivedIsolated(
        _reasonLabel(l10n, result.reason),
      );
    }
    if (evidence.technicalPassCompleted && evidence.receiverSupportUseful) {
      return l10n.scanPassJudgmentCoachPassArrivedSupported(
        _reasonLabel(l10n, result.reason),
      );
    }
    return l10n.scanPassJudgmentCoachConsequence(
      _qualityLabel(l10n, result.quality),
      _reasonLabel(l10n, result.reason),
    );
  }

  String _coachConnections(AppLocalizations l10n, JudgmentResult result) {
    String numbers(AttackState state) {
      final values = _engine.availableConnections(state);
      return values.isEmpty
          ? l10n.scanPassJudgmentCoachNoConnections
          : values.map(l10n.scanPassJudgmentCoachTeammateNumber).join(', ');
    }

    final change = l10n.scanPassJudgmentCoachConnectionChange(
        numbers(result.before), numbers(result.after));
    if (result.after.finished) {
      return '${l10n.scanPassJudgmentCoachLostConnection}\n$change';
    }
    final defenders = result.after.defenders
        .where((p) => !p.goalkeeper)
        .toList()
      ..sort((a, b) => a.position
          .distanceTo(result.after.ball)
          .compareTo(b.position.distanceTo(result.after.ball)));
    final context = l10n.scanPassJudgmentCoachConnections(
        l10n.scanPassJudgmentCoachTeammateNumber(result.after.carrierNumber),
        l10n.scanPassJudgmentCoachOpponentNumber(defenders.first.number),
        numbers(result.after));
    return '$context\n$change';
  }

  String _coachNext(
    AppLocalizations l10n,
    JudgmentCoachingEvidence evidence,
  ) {
    return l10n.scanPassJudgmentCoachNext(
      _habitLabel(l10n, evidence.nextHabit),
    );
  }

  String _coachAlternative(
    AppLocalizations l10n,
    JudgmentCoachingEvidence evidence,
  ) {
    if (!evidence.hasSupportedAlternative) {
      return l10n.scanPassJudgmentCoachNoAlternative;
    }
    return l10n.scanPassJudgmentCoachAlternative(
      _actionLabel(l10n, evidence.supportedAlternative!),
      _qualityLabel(l10n, evidence.supportedAlternativeQuality!),
      _reasonLabel(l10n, evidence.supportedAlternativeReason!),
    );
  }

  String _actorLabel(AppLocalizations l10n, JudgmentActorCue cue) {
    return cue.opponent
        ? l10n.scanPassJudgmentCoachOpponentNumber(cue.number)
        : l10n.scanPassJudgmentCoachTeammateNumber(cue.number);
  }

  String _cueKindLabel(AppLocalizations l10n, JudgmentCueKind kind) {
    return switch (kind) {
      JudgmentCueKind.pressure => l10n.scanPassJudgmentCuePressure,
      JudgmentCueKind.pressureRetreating =>
        l10n.scanPassJudgmentCuePressureRetreating,
      JudgmentCueKind.pressureHolding =>
        l10n.scanPassJudgmentCuePressureHolding,
      JudgmentCueKind.coverLane => l10n.scanPassJudgmentCueCoverLane,
      JudgmentCueKind.supportRun => l10n.scanPassJudgmentCueSupportRun,
      JudgmentCueKind.receiverMovement =>
        l10n.scanPassJudgmentCueReceiverMovement,
      JudgmentCueKind.recoveryRun => l10n.scanPassJudgmentCueRecoveryRun,
      JudgmentCueKind.offsideLine => l10n.scanPassJudgmentCueOffsideLine,
    };
  }

  String _habitLabel(AppLocalizations l10n, JudgmentHabit habit) {
    return switch (habit) {
      JudgmentHabit.firstTouchAway => l10n.scanPassJudgmentHabitFirstTouchAway,
      JudgmentHabit.scanCover => l10n.scanPassJudgmentHabitScanCover,
      JudgmentHabit.supportReceiver =>
        l10n.scanPassJudgmentHabitSupportReceiver,
      JudgmentHabit.useSparePlayer => l10n.scanPassJudgmentHabitUseSparePlayer,
      JudgmentHabit.secureBehindBall =>
        l10n.scanPassJudgmentHabitSecureBehindBall,
      JudgmentHabit.adjustReturnAngle =>
        l10n.scanPassJudgmentHabitAdjustReturnAngle,
    };
  }

  IconData _actionIcon(JudgmentAction action) {
    return switch (action) {
      JudgmentAction.touchLeft => Icons.north_east_outlined,
      JudgmentAction.touchRight => Icons.south_east_outlined,
      JudgmentAction.touchForward => Icons.arrow_forward_outlined,
      JudgmentAction.shield => Icons.shield_outlined,
      JudgmentAction.oneTouchReturn => Icons.keyboard_return_outlined,
      JudgmentAction.passForward => Icons.north_east_outlined,
      JudgmentAction.passWide => Icons.open_in_full_outlined,
      JudgmentAction.passBack => Icons.keyboard_return_outlined,
      JudgmentAction.carryForward => Icons.arrow_forward_outlined,
      JudgmentAction.protect => Icons.shield_outlined,
      JudgmentAction.supportInside => Icons.call_merge_outlined,
      JudgmentAction.supportWide => Icons.open_in_full_outlined,
      JudgmentAction.supportBehind => Icons.subdirectory_arrow_left_outlined,
    };
  }

  String _actionLabel(AppLocalizations l10n, JudgmentAction action) {
    return switch (action) {
      JudgmentAction.touchLeft => l10n.scanPassJudgmentActionTouchLeft,
      JudgmentAction.touchRight => l10n.scanPassJudgmentActionTouchRight,
      JudgmentAction.touchForward => l10n.scanPassJudgmentActionTouchForward,
      JudgmentAction.shield => l10n.scanPassJudgmentActionShield,
      JudgmentAction.oneTouchReturn =>
        l10n.scanPassJudgmentActionOneTouchReturn,
      JudgmentAction.passForward => l10n.scanPassJudgmentActionPassForward,
      JudgmentAction.passWide => l10n.scanPassJudgmentActionPassWide,
      JudgmentAction.passBack => l10n.scanPassJudgmentActionPassBack,
      JudgmentAction.carryForward => l10n.scanPassJudgmentActionCarryForward,
      JudgmentAction.protect => l10n.scanPassJudgmentActionProtect,
      JudgmentAction.supportInside => l10n.scanPassJudgmentActionSupportInside,
      JudgmentAction.supportWide => l10n.scanPassJudgmentActionSupportWide,
      JudgmentAction.supportBehind => l10n.scanPassJudgmentActionSupportBehind,
    };
  }

  String _actionSemantics(AppLocalizations l10n, JudgmentAction action) {
    return switch (action) {
      JudgmentAction.touchLeft => l10n.scanPassJudgmentActionTouchLeftLabel,
      JudgmentAction.touchRight => l10n.scanPassJudgmentActionTouchRightLabel,
      JudgmentAction.touchForward =>
        l10n.scanPassJudgmentActionTouchForwardLabel,
      JudgmentAction.shield => l10n.scanPassJudgmentActionShieldLabel,
      JudgmentAction.oneTouchReturn =>
        l10n.scanPassJudgmentActionOneTouchReturnLabel,
      JudgmentAction.passForward => l10n.scanPassJudgmentActionPassForwardLabel,
      JudgmentAction.passWide => l10n.scanPassJudgmentActionPassWideLabel,
      JudgmentAction.passBack => l10n.scanPassJudgmentActionPassBackLabel,
      JudgmentAction.carryForward =>
        l10n.scanPassJudgmentActionCarryForwardLabel,
      JudgmentAction.protect => l10n.scanPassJudgmentActionProtectLabel,
      JudgmentAction.supportInside =>
        l10n.scanPassJudgmentActionSupportInsideLabel,
      JudgmentAction.supportWide => l10n.scanPassJudgmentActionSupportWideLabel,
      JudgmentAction.supportBehind =>
        l10n.scanPassJudgmentActionSupportBehindLabel,
    };
  }

  String _familyLabel(AppLocalizations l10n, JudgmentFamily family) {
    return switch (family) {
      JudgmentFamily.rearPressure => l10n.scanPassJudgmentFamilyRearPressure,
      JudgmentFamily.sidePressure => l10n.scanPassJudgmentFamilySidePressure,
      JudgmentFamily.openFrontSecondDefender =>
        l10n.scanPassJudgmentFamilyOpenFront,
      JudgmentFamily.passingLane => l10n.scanPassJudgmentFamilyPassingLane,
      JudgmentFamily.receiverSupport =>
        l10n.scanPassJudgmentFamilyReceiverSupport,
      JudgmentFamily.numericalAdvantage =>
        l10n.scanPassJudgmentFamilyNumericalAdvantage,
      JudgmentFamily.postPassSupportAngle =>
        l10n.scanPassJudgmentFamilySupportAngle,
      JudgmentFamily.transitionBackSpace =>
        l10n.scanPassJudgmentFamilyTransitionBackSpace,
    };
  }

  String _qualityLabel(AppLocalizations l10n, JudgmentQuality quality) {
    return switch (quality) {
      JudgmentQuality.spaceGained => l10n.scanPassJudgmentQualitySpaceGained,
      JudgmentQuality.possessionRetained =>
        l10n.scanPassJudgmentQualityPossessionRetained,
      JudgmentQuality.optionsPreserved =>
        l10n.scanPassJudgmentQualityOptionsPreserved,
      JudgmentQuality.lost => l10n.scanPassJudgmentQualityLost,
    };
  }

  String _reasonLabel(AppLocalizations l10n, JudgmentReason reason) {
    return switch (reason) {
      JudgmentReason.rearPressureEscaped =>
        l10n.scanPassJudgmentReasonRearPressureEscaped,
      JudgmentReason.rearPressureArrived =>
        l10n.scanPassJudgmentReasonRearPressureArrived,
      JudgmentReason.sidePressureUsed =>
        l10n.scanPassJudgmentReasonSidePressureUsed,
      JudgmentReason.sidePressureTrap =>
        l10n.scanPassJudgmentReasonSidePressureTrap,
      JudgmentReason.secondDefenderContained =>
        l10n.scanPassJudgmentReasonSecondDefenderContained,
      JudgmentReason.secondDefenderStepped =>
        l10n.scanPassJudgmentReasonSecondDefenderStepped,
      JudgmentReason.laneOpened => l10n.scanPassJudgmentReasonLaneOpened,
      JudgmentReason.laneScreened => l10n.scanPassJudgmentReasonLaneScreened,
      JudgmentReason.receiverSupported =>
        l10n.scanPassJudgmentReasonReceiverSupported,
      JudgmentReason.receiverIsolated =>
        l10n.scanPassJudgmentReasonReceiverIsolated,
      JudgmentReason.overloadUsed => l10n.scanPassJudgmentReasonOverloadUsed,
      JudgmentReason.sparePlayerMissed =>
        l10n.scanPassJudgmentReasonSparePlayerMissed,
      JudgmentReason.supportAngleOpened =>
        l10n.scanPassJudgmentReasonSupportAngleOpened,
      JudgmentReason.supportAngleBlocked =>
        l10n.scanPassJudgmentReasonSupportAngleBlocked,
      JudgmentReason.transitionSecured =>
        l10n.scanPassJudgmentReasonTransitionSecured,
      JudgmentReason.backSpaceExposed =>
        l10n.scanPassJudgmentReasonBackSpaceExposed,
      JudgmentReason.pressureRemains =>
        l10n.scanPassJudgmentReasonPressureRemains,
      JudgmentReason.spaceCreated => l10n.scanPassJudgmentReasonSpaceCreated,
      JudgmentReason.optionsReduced =>
        l10n.scanPassJudgmentReasonOptionsReduced,
      JudgmentReason.possessionKept =>
        l10n.scanPassJudgmentReasonPossessionKept,
      JudgmentReason.intercepted => l10n.scanPassJudgmentReasonIntercepted,
      JudgmentReason.offside => l10n.scanPassJudgmentReasonOffside,
    };
  }
}

class _JudgmentRecord {
  final int sceneIndex;
  final JudgmentFamily family;
  final JudgmentQuality quality;
  final JudgmentReason reason;

  const _JudgmentRecord({
    required this.sceneIndex,
    required this.family,
    required this.quality,
    required this.reason,
  });
}

List<Offset> _judgmentOptionCenters(
    JudgmentPhase phase, _PitchGeometry geometry, Size size) {
  final people = [...phase.state.attackers, ...phase.state.defenders]
      .map((p) => geometry.toOffset(p.position))
      .toList();
  final centers = <Offset>[];
  for (final choice in phase.choices) {
    final target = geometry.toOffset(choice.target);
    Offset? best;
    var bestCost = double.infinity;
    for (var radius = 0; radius <= 180; radius += 12) {
      for (var angle = 0; angle < 24; angle++) {
        final radians = angle * math.pi / 12;
        final candidate = Offset(
          (target.dx + math.cos(radians) * radius)
              .clamp(26.0, math.max(26.0, size.width - 26)),
          (target.dy + math.sin(radians) * radius)
              .clamp(26.0, math.max(26.0, size.height - 26)),
        );
        final overlaps = centers.any((p) =>
            (p.dx - candidate.dx).abs() < 52 &&
            (p.dy - candidate.dy).abs() < 52);
        final coversPlayer = people.any((p) => (p - candidate).distance < 36);
        final cost = (candidate - target).distance +
            (overlaps ? 10000 : 0) +
            (coversPlayer ? 1000 : 0);
        if (cost < bestCost) {
          bestCost = cost;
          best = candidate;
        }
      }
    }
    centers.add(best ?? target);
  }
  return centers;
}

class _JudgmentOptionPaths extends CustomPainter {
  final Offset origin;
  final List<Offset> targets;
  final List<Offset> centers;
  final Color color;
  const _JudgmentOptionPaths(
      {required this.origin,
      required this.targets,
      required this.centers,
      required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color.withValues(alpha: .48)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < targets.length; i++) {
      final target = targets[i];
      final delta = target - origin;
      if (delta.distance > 18) {
        final unit = delta / delta.distance;
        canvas.drawLine(origin + unit * 17, target, line);
        final normal = Offset(-unit.dy, unit.dx);
        canvas.drawPath(
            Path()
              ..moveTo((target - unit * 6 + normal * 3).dx,
                  (target - unit * 6 + normal * 3).dy)
              ..lineTo(target.dx, target.dy)
              ..lineTo((target - unit * 6 - normal * 3).dx,
                  (target - unit * 6 - normal * 3).dy),
            line);
      }
      canvas.drawCircle(target, 3, Paint()..color = color);
      if ((centers[i] - target).distance > 28) {
        final delta = centers[i] - target;
        canvas.drawLine(
            target,
            centers[i] - delta / delta.distance * 24,
            Paint()
              ..color = color.withValues(alpha: .35)
              ..strokeWidth = .8);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _JudgmentOptionPaths oldDelegate) => true;
}

_PitchFrame _judgmentFocusFrame(JudgmentScene scene) {
  final points = <ScanPassPoint>[
    // Include all reachable support destinations without shifting the frame.
    const ScanPassPoint(.04, .08),
    const ScanPassPoint(.96, .92),
    for (final state in [scene.initial, scene.reception]) ...[
      for (final player in state.attackers)
        if (!player.goalkeeper) player.position,
      for (final player in state.defenders)
        if (!player.goalkeeper) player.position,
      state.ball,
    ],
    scene.cueFrom,
    scene.cueTo,
    ScanPassPoint(const AttackEngine().offsideLine(scene.reception), .50),
  ];
  var minX = points.map((point) => point.x).reduce(math.min) - .07;
  var maxX = points.map((point) => point.x).reduce(math.max) + .09;
  var minY = points.map((point) => point.y).reduce(math.min) - .09;
  var maxY = points.map((point) => point.y).reduce(math.max) + .09;
  const minWidth = .76;
  const minHeight = .68;
  if (maxX - minX < minWidth) {
    final center = (minX + maxX) / 2;
    minX = center - minWidth / 2;
    maxX = center + minWidth / 2;
  }
  if (maxY - minY < minHeight) {
    final center = (minY + maxY) / 2;
    minY = center - minHeight / 2;
    maxY = center + minHeight / 2;
  }
  if (minX < 0) {
    maxX -= minX;
    minX = 0;
  }
  if (maxX > 1.04) {
    minX -= maxX - 1.04;
    maxX = 1.04;
  }
  if (minY < 0) {
    maxY -= minY;
    minY = 0;
  }
  if (maxY > 1) {
    minY -= maxY - 1;
    maxY = 1;
  }
  return _PitchFrame(
    minX.clamp(0.0, 1.04).toDouble(),
    maxX.clamp(0.0, 1.04).toDouble(),
    minY.clamp(0.0, 1.0).toDouble(),
    maxY.clamp(0.0, 1.0).toDouble(),
  );
}
