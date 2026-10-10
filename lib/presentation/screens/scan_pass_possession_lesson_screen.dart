part of 'scan_pass_game_screen.dart';

enum _PossessionMode { guided, independent, changedCue }

enum _PossessionUiPhase { guidedCue, observing, choosing, executing, review }

enum _PossessionBranchView { mine, coach }

class ScanPassPossessionLessonScreen extends StatefulWidget {
  final int? seed;
  final Duration observationDuration;
  final Duration executionDuration;
  final WidgetBuilder? freeAttackBuilder;
  final WidgetBuilder? judgmentPracticeBuilder;

  const ScanPassPossessionLessonScreen({
    super.key,
    this.seed,
    this.observationDuration = const Duration(milliseconds: 2400),
    this.executionDuration = const Duration(milliseconds: 3600),
    this.freeAttackBuilder,
    this.judgmentPracticeBuilder,
  });

  @override
  State<ScanPassPossessionLessonScreen> createState() =>
      _ScanPassPossessionLessonScreenState();
}

class _ScanPassPossessionLessonScreenState
    extends State<ScanPassPossessionLessonScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final ScanPassPossessionLessonEngine _engine =
      const ScanPassPossessionLessonEngine();

  late final AnimationController _motionController;
  late ScanPassPossessionScene _scene;
  late ScanPassPossessionDecisionPoint _decision;
  late ScanPassPossessionBranch _coachBranch;

  _PossessionMode _mode = _PossessionMode.guided;
  _PossessionUiPhase _phase = _PossessionUiPhase.guidedCue;
  _PossessionBranchView _branchView = _PossessionBranchView.coach;
  ScanPassPossessionMoment _moment = ScanPassPossessionMoment.receive;
  int _cueIndex = 0;
  bool _foreground = true;
  bool _manuallyPaused = false;
  bool _modalOpen = false;
  bool _routeOpen = false;
  bool _playingReplay = false;
  List<AttackTransition> _motionTransitions = const <AttackTransition>[];
  ScanPassPossessionStepResult? _pendingResult;
  ScanPassPossessionBranch? _myBranch;

  ScanPassPossessionBranch? get _selectedBranch => switch (_branchView) {
        _PossessionBranchView.mine => _myBranch,
        _PossessionBranchView.coach => _coachBranch,
      };

  bool get _canChoose =>
      _phase == _PossessionUiPhase.choosing && _mode != _PossessionMode.guided;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _motionController = AnimationController(vsync: this)
      ..addStatusListener(_handleMotionStatus);
    _loadScene(_PossessionMode.guided);
  }

  @override
  void didUpdateWidget(covariant ScanPassPossessionLessonScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed) {
      _loadScene(_PossessionMode.guided);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motionController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _foreground = false;
      _motionController.stop();
      return;
    }
    if (state != AppLifecycleState.resumed || !mounted) return;
    _foreground = true;
    if (!_modalOpen &&
        !_routeOpen &&
        !_manuallyPaused &&
        _phase == _PossessionUiPhase.executing) {
      unawaited(_motionController.forward());
    }
  }

  void _loadScene(_PossessionMode mode) {
    final variant = mode == _PossessionMode.changedCue
        ? ScanPassPossessionVariant.cover
        : ScanPassPossessionVariant.pressure;
    _scene = _engine.scene(variant: variant);
    _decision = _engine.firstPhase(_scene);
    _coachBranch = _engine.recommendedBranch(_scene);
    _mode = mode;
    _phase = mode == _PossessionMode.guided
        ? _PossessionUiPhase.guidedCue
        : _PossessionUiPhase.observing;
    _branchView = mode == _PossessionMode.guided
        ? _PossessionBranchView.coach
        : _PossessionBranchView.mine;
    _moment = ScanPassPossessionMoment.receive;
    _cueIndex = 0;
    _myBranch = null;
    _pendingResult = null;
    _playingReplay = false;
    _manuallyPaused = false;
    _motionTransitions = const <AttackTransition>[];
    _motionController
      ..stop()
      ..value = 0;
    if (_phase == _PossessionUiPhase.observing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _phase == _PossessionUiPhase.observing) {
          _runObservation();
        }
      });
    }
  }

  void _runObservation() {
    _playTransitions(
      <AttackTransition>[_scene.observation],
      reducedDuration: widget.observationDuration,
      replay: false,
    );
  }

  void _playGuidedRoute() {
    setState(() {
      _branchView = _PossessionBranchView.coach;
      _moment = ScanPassPossessionMoment.receive;
    });
    _playTransitions(_coachBranch.fullTransitions, replay: true);
  }

  void _choose(ScanPassPossessionChoice choice) {
    if (!_canChoose) return;
    final result = _engine.choose(_decision, choice);
    setState(() {
      _pendingResult = result;
      _motionTransitions = result.transitions;
      _phase = _PossessionUiPhase.executing;
      _playingReplay = false;
      _motionController.value = 0;
    });
    _runMotion(result.transitions);
  }

  void _replaySelectedBranch() {
    final branch = _selectedBranch;
    if (branch == null) return;
    _playTransitions(branch.fullTransitions, replay: true);
  }

  void _playTransitions(
    List<AttackTransition> transitions, {
    Duration? reducedDuration,
    required bool replay,
  }) {
    setState(() {
      _motionTransitions = transitions;
      _pendingResult = null;
      _phase = _PossessionUiPhase.executing;
      _playingReplay = replay;
      _motionController.value = 0;
    });
    _runMotion(transitions, overrideDuration: reducedDuration);
  }

  void _runMotion(
    List<AttackTransition> transitions, {
    Duration? overrideDuration,
  }) {
    _manuallyPaused = false;
    final reduced = AppMotion.reduceMotion(context);
    final duration = overrideDuration ?? widget.executionDuration;
    if (transitions.isEmpty || reduced || duration == Duration.zero) {
      _motionController.value = 1;
      _finishMotion();
      return;
    }
    final modelSeconds =
        transitions.fold<double>(0, (sum, item) => sum + item.duration);
    // Preserve readable time for the whole possession. A full replay must not
    // be squeezed into the per-action animation duration.
    final milliseconds = overrideDuration != null
        ? overrideDuration.inMilliseconds
        : (modelSeconds * 3600 * widget.executionDuration.inMilliseconds / 3600)
            .round();
    _motionController.duration =
        Duration(milliseconds: math.max(1, milliseconds));
    unawaited(_motionController.forward(from: 0));
  }

  void _handleMotionStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      _finishMotion();
    }
  }

  void _finishMotion() {
    if (!mounted || _phase != _PossessionUiPhase.executing) return;
    final pending = _pendingResult;
    setState(() {
      _motionController.value = 0;
      if (pending != null) {
        if (pending.nextPoint != null) {
          _decision = pending.nextPoint!;
          _pendingResult = null;
          _motionTransitions = const <AttackTransition>[];
          _phase = _PossessionUiPhase.choosing;
        } else {
          _myBranch = pending.branch;
          _branchView = _PossessionBranchView.mine;
          _moment = ScanPassPossessionMoment.finish;
          _pendingResult = null;
          _motionTransitions = const <AttackTransition>[];
          _phase = _PossessionUiPhase.review;
        }
      } else {
        if (_playingReplay || _mode == _PossessionMode.guided) {
          _moment = ScanPassPossessionMoment.finish;
          _phase = _PossessionUiPhase.review;
        } else {
          _phase = _PossessionUiPhase.choosing;
        }
        _motionTransitions = const <AttackTransition>[];
      }
      _playingReplay = false;
    });
  }

  Future<void> _pauseForModal(Future<void> Function() open) async {
    if (_modalOpen) return;
    _modalOpen = true;
    final wasAnimating = _motionController.isAnimating;
    _motionController.stop();
    await open();
    if (!mounted) return;
    _modalOpen = false;
    if (wasAnimating &&
        !_routeOpen &&
        _foreground &&
        !_manuallyPaused &&
        _phase == _PossessionUiPhase.executing) {
      unawaited(_motionController.forward());
    }
  }

  void _showPracticeMenu() {
    final l10n = AppLocalizations.of(context)!;
    final colors = _ScanPassColors.of(context);
    unawaited(_pauseForModal(() {
      return showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        backgroundColor: colors.surface,
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.scanPassPossessionPracticeTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const ValueKey<String>('possession-open-free-attack'),
                  onPressed: widget.freeAttackBuilder == null
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          _openBuilder(widget.freeAttackBuilder!);
                        },
                  icon: const Icon(Icons.sports_soccer_outlined, size: 18),
                  label: Text(l10n.scanPassFreeAttackAction),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const ValueKey<String>(
                    'possession-open-judgment-practice',
                  ),
                  onPressed: widget.judgmentPracticeBuilder == null
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          _openBuilder(widget.judgmentPracticeBuilder!);
                        },
                  icon: const Icon(Icons.grid_view_outlined, size: 18),
                  label: Text(l10n.scanPassPossessionJudgmentPracticeAction),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.scanPassHelpCloseAction),
                ),
              ],
            ),
          ),
        ),
      );
    }));
  }

  Future<void> _openBuilder(WidgetBuilder builder) async {
    _routeOpen = true;
    _motionController.stop();
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: builder));
    if (!mounted) return;
    _routeOpen = false;
    if (_foreground &&
        !_modalOpen &&
        !_manuallyPaused &&
        _phase == _PossessionUiPhase.executing) {
      unawaited(_motionController.forward());
    }
  }

  void _showHelp() {
    final l10n = AppLocalizations.of(context)!;
    final colors = _ScanPassColors.of(context);
    unawaited(_pauseForModal(() {
      return showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        backgroundColor: colors.surface,
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.scanPassHelpSheetTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.scanPassPossessionHelpBody,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.text,
                        height: 1.25,
                      ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.scanPassHelpCloseAction),
                ),
              ],
            ),
          ),
        ),
      );
    }));
  }

  void _showCoachDetail() {
    final branch = _selectedBranch;
    if (branch == null) return;
    final l10n = AppLocalizations.of(context)!;
    final colors = _ScanPassColors.of(context);
    unawaited(_pauseForModal(() {
      return showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        backgroundColor: colors.surface,
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.scanPassPossessionDetailTitle,
                  key: const ValueKey<String>('possession-detail-sheet'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  _detailBody(l10n, branch),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.text,
                        height: 1.25,
                      ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.scanPassHelpCloseAction),
                ),
              ],
            ),
          ),
        ),
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = _ScanPassColors.of(context);
    return Theme(
      data: Theme.of(context).copyWith(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
            AppBarActionButton.label(
              key: const ValueKey<String>('possession-practice-menu'),
              tooltip: l10n.scanPassPossessionPracticeTooltip,
              onPressed: _showPracticeMenu,
              icon: const Icon(Icons.menu_book_outlined),
              label: l10n.scanPassPossessionPracticeAction,
              maxLabelWidth: 92,
            ),
            AppBarActionButton(
              key: const ValueKey<String>('possession-help'),
              tooltip: l10n.scanPassHelpAction,
              onPressed: _showHelp,
              icon: const Icon(Icons.help_outline),
            ),
          ],
        ),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _motionController,
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
        final dockWidth = math.min(250.0, constraints.maxWidth * .40);
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
        MediaQuery.textScalerOf(context).scale(13) * 1.12 * 2 + 6,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          child: Row(children: [
            Icon(_modeIcon(), color: colors.accent, size: 18),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                _status(l10n),
                key: const ValueKey<String>('possession-status'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w700,
                      height: 1.12,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            _MiniChip(text: _modeLabel(l10n), color: colors.background),
          ]),
        ),
      ),
    );
  }

  Widget _buildPitch(AppLocalizations l10n) {
    final labels = _PitchLabels.from(l10n);
    final motion = _activeMotion;
    final spotlight = _activeSpotlight;
    final branch = _selectedBranch;
    return LayoutBuilder(builder: (context, constraints) {
      final portrait = MediaQuery.sizeOf(context).width < 600 &&
          MediaQuery.sizeOf(context).height > MediaQuery.sizeOf(context).width;
      final availableAspect = constraints.maxWidth / constraints.maxHeight;
      final aspect = availableAspect.clamp(
        portrait ? .95 : 1.55,
        portrait ? 1.35 : 2.6,
      );
      return Center(
        child: AspectRatio(
          aspectRatio: aspect,
          child: ClipRect(
            child: Stack(fit: StackFit.expand, children: [
              Semantics(
                label: l10n.scanPassPossessionFieldSemantics,
                image: true,
                child: CustomPaint(
                  key: const ValueKey<String>('possession-pitch'),
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
                    learnerLabel: l10n.scanPassPossessionLearnerLabel,
                    decisionCueFrom: spotlight?.from,
                    decisionCueTo: spotlight?.to,
                    decisionCueIsOpponent: spotlight?.opponent ?? false,
                    decisionPressurePoint: _reviewPressurePoint(branch),
                    decisionOutletPoints: _reviewOutletPoints(branch),
                    decisionBranchLabel: _pitchBranchLabel(l10n),
                  ),
                ),
              ),
              if (_canChoose) _buildPitchTargets(l10n),
            ]),
          ),
        ),
      );
    });
  }

  Widget _buildPitchTargets(AppLocalizations l10n) {
    final colors = _ScanPassColors.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final geometry = _PitchGeometry(Size(
        constraints.maxWidth,
        constraints.maxHeight,
      ));
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final targets = [
        for (final choice in _decision.choices)
          geometry.toOffset(_engine.targetFor(_decision, choice))
      ];
      final people = [
        for (final p in [
          ..._decision.state.attackers,
          ..._decision.state.defenders
        ])
          geometry.toOffset(p.position)
      ];
      final centers = _possessionOptionCenters(targets, people, size);
      return Stack(children: [
        Positioned.fill(
            child: IgnorePointer(
                child: CustomPaint(
                    painter: _PossessionTargetConnectors(
                        targets, centers, colors.team)))),
        for (final choice in _decision.choices)
          _PitchButton(
            key: ValueKey<String>('possession-action-${choice.name}'),
            center: centers[_decision.choices.indexOf(choice)],
            label: _choiceSemantics(l10n, choice),
            selected: false,
            color: colors.team,
            onPressed: () => _choose(choice),
            child: _choicePitchChild(choice),
          ),
      ]);
    });
  }

  Widget _choicePitchChild(ScanPassPossessionChoice choice) {
    final targetNumber = switch (choice) {
      ScanPassPossessionChoice.passTo8 => 8,
      ScanPassPossessionChoice.passTo9 => 9,
      ScanPassPossessionChoice.recycle4 ||
      ScanPassPossessionChoice.oneTouchLayoff =>
        4,
      _ => null,
    };
    if (targetNumber != null) {
      return Text(
        targetNumber.toString(),
        style: const TextStyle(fontWeight: FontWeight.w800),
      );
    }
    return Icon(_choiceIcon(choice), size: 18);
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
            child: SingleChildScrollView(
              child: _dockContent(l10n, landscape: landscape),
            ),
          ),
        ),
      ),
    );
  }

  double _dockHeight() {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return (MediaQuery.sizeOf(context).width < 600 ? 218.0 : 186.0) +
        math.max(0, scale - 1) * 66;
  }

  Widget _dockContent(AppLocalizations l10n, {required bool landscape}) {
    return switch (_phase) {
      _PossessionUiPhase.guidedCue => _guidedDock(l10n),
      _PossessionUiPhase.observing => _observingDock(),
      _PossessionUiPhase.choosing => _choiceDock(l10n, landscape: landscape),
      _PossessionUiPhase.executing => _executingDock(l10n),
      _PossessionUiPhase.review => _reviewDock(l10n),
    };
  }

  Widget _guidedDock(AppLocalizations l10n) {
    final colors = _ScanPassColors.of(context);
    final atLastCue = _cueIndex >= _scene.spotlights.length - 1;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _phaseHeader(
        icon: Icons.visibility_outlined,
        label: _spotlightCaption(l10n, _scene.spotlights[_cueIndex]),
      ),
      const SizedBox(height: 8),
      Text(
        l10n.scanPassPossessionGuidedObjective,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.text,
              fontWeight: FontWeight.w600,
              height: 1.16,
            ),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: OutlinedButton(
            key: const ValueKey<String>('possession-guided-next-cue'),
            onPressed: atLastCue ? null : () => setState(() => _cueIndex += 1),
            style: _outlinedStyle(colors),
            child: Text(l10n.scanPassPossessionNextCueAction),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            key: const ValueKey<String>('possession-guided-play'),
            onPressed: atLastCue ? _playGuidedRoute : null,
            icon: const Icon(Icons.play_arrow_outlined, size: 18),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(l10n.scanPassPossessionPlayCoachRouteAction),
            ),
          ),
        ),
      ]),
    ]);
  }

  Widget _observingDock() {
    final colors = _ScanPassColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        minHeight: 4,
        value: _motionController.value.clamp(0.0, 1.0),
        backgroundColor: colors.line,
        valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
      ),
    );
  }

  Widget _executingDock(AppLocalizations l10n) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _phaseHeader(
              icon: Icons.play_circle_outline, label: _motionCaption(l10n)),
          const SizedBox(height: 12),
          _observingDock(),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('possession-pause'),
            onPressed: () => setState(() {
              _manuallyPaused = !_manuallyPaused;
              if (_manuallyPaused) {
                _motionController.stop();
              } else if (_foreground && !_modalOpen) {
                unawaited(_motionController.forward());
              }
            }),
            style: _outlinedStyle(_ScanPassColors.of(context)),
            icon: Icon(_manuallyPaused ? Icons.play_arrow : Icons.pause),
            label: Text(_manuallyPaused
                ? l10n.scanPassPossessionResume
                : l10n.scanPassPossessionPause),
          ),
        ],
      );

  String _motionCaption(AppLocalizations l10n) {
    final motion = _activeMotion;
    if (motion == null) return l10n.scanPassPossessionExecutingStatus;
    final t = motion.transition;
    return switch (t.action.kind) {
      AttackActionKind.pass => l10n.scanPassPossessionMotionPass(
          t.before.carrierNumber, t.action.targetNumber!),
      AttackActionKind.hold => l10n.scanPassPossessionMotionSupport,
      AttackActionKind.carry =>
        l10n.scanPassPossessionMotionCarry(t.before.carrierNumber),
      AttackActionKind.shoot =>
        l10n.scanPassPossessionMotionShot(t.before.carrierNumber),
    };
  }

  Widget _choiceDock(
    AppLocalizations l10n, {
    required bool landscape,
  }) {
    final compact = landscape || MediaQuery.sizeOf(context).width < 900;
    final buttons = [
      for (final choice in _decision.choices)
        _DockActionButton(
          key: ValueKey<String>('possession-dock-${choice.name}'),
          selected: false,
          icon: _choiceIcon(choice),
          label: _choiceLabel(l10n, choice),
          semanticsLabel: _choiceSemantics(l10n, choice),
          compact: compact,
          onPressed: () => _choose(choice),
        ),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _phaseHeader(
        icon: _decisionIcon(_decision.kind),
        label: _decisionPrompt(l10n, _decision.kind),
      ),
      const SizedBox(height: 8),
      if (compact)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final button in buttons)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: SizedBox(width: 96, child: button),
              ),
          ]),
        )
      else
        Row(children: [
          for (final button in buttons)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: button,
              ),
            ),
        ]),
    ]);
  }

  Widget _reviewDock(AppLocalizations l10n) {
    final colors = _ScanPassColors.of(context);
    final branch = _selectedBranch;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        if (_myBranch != null) ...[
          Expanded(
              child: _DockActionButton(
                  key: const ValueKey('possession-compare-mine'),
                  selected: _branchView == _PossessionBranchView.mine,
                  icon: Icons.person_outline,
                  label: l10n.scanPassPossessionMineShort,
                  semanticsLabel: l10n.scanPassPossessionMineBranch,
                  compact: true,
                  onPressed: () => _selectBranch(_PossessionBranchView.mine))),
          const SizedBox(width: 4),
        ],
        Expanded(
            child: _DockActionButton(
                key: const ValueKey('possession-compare-coach'),
                selected: _branchView == _PossessionBranchView.coach,
                icon: Icons.school_outlined,
                label: l10n.scanPassPossessionCoachShort,
                semanticsLabel: l10n.scanPassPossessionCoachBranch,
                compact: true,
                onPressed: () => _selectBranch(_PossessionBranchView.coach))),
        const SizedBox(width: 4),
        AppBarActionButton(
            key: const ValueKey('possession-replay'),
            tooltip: l10n.scanPassPossessionReplayAction,
            onPressed: _replaySelectedBranch,
            compact: true,
            margin: EdgeInsets.zero,
            icon: const Icon(Icons.replay, size: 20)),
        const SizedBox(width: 4),
        AppBarActionButton(
            key: const ValueKey('possession-coach-detail'),
            tooltip: l10n.scanPassJudgmentCoachDetailAction,
            onPressed: branch == null ? null : _showCoachDetail,
            compact: true,
            margin: EdgeInsets.zero,
            icon: const Icon(Icons.lightbulb_outline, size: 20)),
      ]),
      const SizedBox(height: 4),
      SizedBox(
          height: 44,
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final moment
                    in branch?.availableMoments ?? <ScanPassPossessionMoment>[])
                  Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: ChoiceChip(
                          key: ValueKey('possession-moment-${moment.name}'),
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                          label: Text(_momentLabel(l10n, moment)),
                          selected: _moment == moment,
                          onSelected: (_) => setState(() => _moment = moment))),
              ]))),
      if (branch != null)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(_coachLine(l10n, branch),
                key: const ValueKey('possession-review-result'),
                maxLines: MediaQuery.sizeOf(context).width < 600 &&
                        MediaQuery.sizeOf(context).height >= 430
                    ? 3
                    : 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.text,
                    height: 1.16,
                    fontWeight: FontWeight.w600))),
      Row(children: [
        Expanded(
            child: OutlinedButton(
                key: ValueKey(_mode == _PossessionMode.guided
                    ? 'possession-try-independent'
                    : 'possession-retry'),
                onPressed: () => setState(() => _loadScene(
                    _mode == _PossessionMode.changedCue
                        ? _PossessionMode.changedCue
                        : _PossessionMode.independent)),
                style: _outlinedStyle(colors),
                child: Text(_mode == _PossessionMode.guided
                    ? l10n.scanPassPossessionTryIndependentAction
                    : l10n.scanPassJudgmentRetryAction))),
        const SizedBox(width: 6),
        Expanded(
            child: FilledButton.icon(
                key: const ValueKey('possession-changed-cue'),
                onPressed: () =>
                    setState(() => _loadScene(_PossessionMode.changedCue)),
                style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: Text(l10n.scanPassPossessionChangedCueAction))),
      ]),
    ]);
  }

  void _selectBranch(_PossessionBranchView view) => setState(() {
        _branchView = view;
        if (!(_selectedBranch?.availableMoments.contains(_moment) ?? false)) {
          _moment = ScanPassPossessionMoment.finish;
        }
      });

  Widget _phaseHeader({required IconData icon, required String label}) {
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
          Icon(icon, size: 16, color: colors.accent),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              key: const ValueKey<String>('possession-phase-label'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                  ),
            ),
          ),
        ]),
      ),
    );
  }

  ({AttackTransition transition, double progress})? get _activeMotion {
    if (_motionTransitions.isEmpty || _phase != _PossessionUiPhase.executing) {
      return null;
    }
    var remaining = _totalMotionDuration * _motionController.value;
    for (final transition in _motionTransitions) {
      if (remaining <= transition.duration) {
        return (
          transition: transition,
          progress: transition.duration <= 0
              ? 1
              : (remaining / transition.duration).clamp(0.0, 1.0),
        );
      }
      remaining -= transition.duration;
    }
    return (transition: _motionTransitions.last, progress: 1);
  }

  double get _totalMotionDuration => _motionTransitions.fold<double>(
        0,
        (sum, item) => sum + item.duration,
      );

  AttackState get _displayState {
    if (_phase == _PossessionUiPhase.executing) {
      final motion = _activeMotion;
      if (motion != null) return motion.transition.frame(motion.progress);
    }
    if (_phase == _PossessionUiPhase.guidedCue) return _scene.reception;
    if (_phase == _PossessionUiPhase.observing) return _scene.initial;
    if (_phase == _PossessionUiPhase.choosing) return _decision.state;
    final branch = _selectedBranch;
    return branch?.stateAt(_moment) ?? _scene.reception;
  }

  AttackState get _baseState {
    if (_phase == _PossessionUiPhase.executing &&
        _motionTransitions.isNotEmpty) {
      return _motionTransitions.first.before;
    }
    if (_phase == _PossessionUiPhase.choosing) return _decision.state;
    final branch = _selectedBranch;
    return branch?.stateAt(_moment) ?? _scene.reception;
  }

  List<AttackTransition> get _historyForPainter {
    if (_phase == _PossessionUiPhase.executing) {
      var elapsed = _totalMotionDuration * _motionController.value;
      final shown = <AttackTransition>[];
      for (final transition in _motionTransitions) {
        if (elapsed <= 0) break;
        if (elapsed >= transition.duration) {
          shown.add(transition);
          elapsed -= transition.duration;
        } else {
          break;
        }
      }
      return shown;
    }
    if (_phase == _PossessionUiPhase.review) {
      final branch = _selectedBranch;
      if (branch == null) return const [];
      final index = branch.transitionIndexAt(_moment) ?? -1;
      return branch.transitions.take(index + 1).toList();
    }
    if (_phase == _PossessionUiPhase.choosing) {
      return _decision.history;
    }
    return const <AttackTransition>[];
  }

  ScanPassPossessionSpotlight? get _activeSpotlight {
    if (_phase == _PossessionUiPhase.guidedCue) {
      return _scene.spotlights[_cueIndex];
    }
    if (_phase == _PossessionUiPhase.review &&
        _moment == ScanPassPossessionMoment.touch) {
      return _scene.spotlights.first;
    }
    if (_phase == _PossessionUiPhase.review &&
        _moment == ScanPassPossessionMoment.support) {
      final branch = _selectedBranch;
      final index = branch?.transitionIndexAt(_moment);
      if (branch == null || index == null || index < 0) return null;
      final t = branch.transitions[index];
      final from = _playerByNumber(t.before.attackers, 6)!.position;
      final to = _playerByNumber(t.after.attackers, 6)!.position;
      return ScanPassPossessionSpotlight(
          kind: ScanPassPossessionSpotlightKind.futureSpace,
          actorNumber: 6,
          opponent: false,
          from: from,
          to: to,
          focus: to);
    }
    return null;
  }

  ScanPassPoint? _reviewPressurePoint(ScanPassPossessionBranch? branch) {
    if (_phase != _PossessionUiPhase.review || branch == null) return null;
    if (_moment == ScanPassPossessionMoment.touch &&
        branch.evidence.contains(ScanPassPossessionEvidence.pressureStayed)) {
      final state = branch.stateAt(_moment);
      return state.defenders
          .where((p) => !p.goalkeeper)
          .reduce((a, b) => a.position.distanceTo(state.ball) <
                  b.position.distanceTo(state.ball)
              ? a
              : b)
          .position;
    }
    return null;
  }

  List<ScanPassPoint> _reviewOutletPoints(ScanPassPossessionBranch? branch) {
    if (_phase != _PossessionUiPhase.review ||
        branch == null ||
        _moment == ScanPassPossessionMoment.receive) {
      return const [];
    }
    final state = branch.stateAt(_moment);
    return [
      for (final number in _engine.availableConnections(branch.scene, state))
        _playerByNumber(state.attackers, number)!.position
    ];
  }

  String? _pitchBranchLabel(AppLocalizations l10n) {
    if (_phase == _PossessionUiPhase.guidedCue) {
      return l10n.scanPassPossessionGuidedBranch;
    }
    if (_phase == _PossessionUiPhase.executing && _playingReplay) {
      return _branchView == _PossessionBranchView.mine
          ? l10n.scanPassPossessionMineBranch
          : l10n.scanPassPossessionCoachBranch;
    }
    if (_phase == _PossessionUiPhase.review) {
      return _branchView == _PossessionBranchView.mine
          ? l10n.scanPassPossessionMineBranch
          : l10n.scanPassPossessionCoachBranch;
    }
    return null;
  }

  String _status(AppLocalizations l10n) => switch (_phase) {
        _PossessionUiPhase.guidedCue => l10n.scanPassPossessionGuidedStatus,
        _PossessionUiPhase.observing => _mode == _PossessionMode.changedCue
            ? l10n.scanPassPossessionChangedObserveStatus
            : l10n.scanPassPossessionObserveStatus,
        _PossessionUiPhase.choosing => l10n.scanPassPossessionChooseStatus,
        _PossessionUiPhase.executing =>
          !_playingReplay && _pendingResult == null
              ? (_mode == _PossessionMode.changedCue
                  ? l10n.scanPassPossessionChangedObserveStatus
                  : l10n.scanPassPossessionObserveStatus)
              : l10n.scanPassPossessionExecutingStatus,
        _PossessionUiPhase.review => l10n.scanPassPossessionReviewStatus,
      };

  String _modeLabel(AppLocalizations l10n) => switch (_mode) {
        _PossessionMode.guided => l10n.scanPassPossessionModeGuided,
        _PossessionMode.independent => l10n.scanPassPossessionModeIndependent,
        _PossessionMode.changedCue => l10n.scanPassPossessionModeChangedCue,
      };

  IconData _modeIcon() => switch (_mode) {
        _PossessionMode.guided => Icons.visibility_outlined,
        _PossessionMode.independent => Icons.person_outline,
        _PossessionMode.changedCue => Icons.swap_horiz_outlined,
      };

  IconData _decisionIcon(ScanPassPossessionDecisionKind kind) => switch (kind) {
        ScanPassPossessionDecisionKind.firstTouch =>
          Icons.sports_soccer_outlined,
        ScanPassPossessionDecisionKind.nextAction =>
          Icons.arrow_forward_outlined,
        ScanPassPossessionDecisionKind.support => Icons.directions_run_outlined,
      };

  IconData _choiceIcon(ScanPassPossessionChoice choice) => switch (choice) {
        ScanPassPossessionChoice.touchAway => Icons.south_east_outlined,
        ScanPassPossessionChoice.turnForward => Icons.turn_right_outlined,
        ScanPassPossessionChoice.oneTouchLayoff => Icons.keyboard_return,
        ScanPassPossessionChoice.passTo8 ||
        ScanPassPossessionChoice.passTo9 ||
        ScanPassPossessionChoice.recycle4 =>
          Icons.near_me_outlined,
        ScanPassPossessionChoice.supportInside => Icons.call_split_outlined,
        ScanPassPossessionChoice.supportWide => Icons.open_in_full_outlined,
        ScanPassPossessionChoice.supportBehind => Icons.undo_outlined,
      };

  String _decisionPrompt(
    AppLocalizations l10n,
    ScanPassPossessionDecisionKind kind,
  ) =>
      switch (kind) {
        ScanPassPossessionDecisionKind.firstTouch =>
          l10n.scanPassPossessionPromptFirstTouch,
        ScanPassPossessionDecisionKind.nextAction =>
          l10n.scanPassPossessionPromptNextAction,
        ScanPassPossessionDecisionKind.support =>
          l10n.scanPassPossessionPromptSupport,
      };

  String _choiceLabel(
    AppLocalizations l10n,
    ScanPassPossessionChoice choice,
  ) =>
      switch (choice) {
        ScanPassPossessionChoice.touchAway =>
          l10n.scanPassPossessionChoiceTouchAway,
        ScanPassPossessionChoice.turnForward =>
          l10n.scanPassPossessionChoiceTurnForward,
        ScanPassPossessionChoice.oneTouchLayoff =>
          l10n.scanPassPossessionChoiceLayoff,
        ScanPassPossessionChoice.passTo8 => l10n.scanPassPossessionChoicePass8,
        ScanPassPossessionChoice.passTo9 => l10n.scanPassPossessionChoicePass9,
        ScanPassPossessionChoice.recycle4 =>
          l10n.scanPassPossessionChoiceRecycle4,
        ScanPassPossessionChoice.supportInside =>
          l10n.scanPassPossessionChoiceSupportInside,
        ScanPassPossessionChoice.supportWide =>
          l10n.scanPassPossessionChoiceSupportWide,
        ScanPassPossessionChoice.supportBehind =>
          l10n.scanPassPossessionChoiceSupportBehind,
      };

  String _choiceSemantics(
    AppLocalizations l10n,
    ScanPassPossessionChoice choice,
  ) =>
      switch (choice) {
        ScanPassPossessionChoice.touchAway =>
          l10n.scanPassPossessionChoiceTouchAwayLabel,
        ScanPassPossessionChoice.turnForward =>
          l10n.scanPassPossessionChoiceTurnForwardLabel,
        ScanPassPossessionChoice.oneTouchLayoff =>
          l10n.scanPassPossessionChoiceLayoffLabel,
        ScanPassPossessionChoice.passTo8 =>
          l10n.scanPassPossessionChoicePass8Label,
        ScanPassPossessionChoice.passTo9 =>
          l10n.scanPassPossessionChoicePass9Label,
        ScanPassPossessionChoice.recycle4 =>
          l10n.scanPassPossessionChoiceRecycle4Label,
        ScanPassPossessionChoice.supportInside =>
          l10n.scanPassPossessionChoiceSupportInsideLabel,
        ScanPassPossessionChoice.supportWide =>
          l10n.scanPassPossessionChoiceSupportWideLabel,
        ScanPassPossessionChoice.supportBehind =>
          l10n.scanPassPossessionChoiceSupportBehindLabel,
      };

  String _momentLabel(
    AppLocalizations l10n,
    ScanPassPossessionMoment moment,
  ) =>
      switch (moment) {
        ScanPassPossessionMoment.receive =>
          l10n.scanPassPossessionMomentReceive,
        ScanPassPossessionMoment.touch => l10n.scanPassPossessionMomentTouch,
        ScanPassPossessionMoment.link => l10n.scanPassPossessionMomentLink,
        ScanPassPossessionMoment.support =>
          l10n.scanPassPossessionMomentSupport,
        ScanPassPossessionMoment.finish => l10n.scanPassPossessionMomentFinish,
      };

  String _spotlightCaption(
    AppLocalizations l10n,
    ScanPassPossessionSpotlight spotlight,
  ) {
    if (_scene.variant == ScanPassPossessionVariant.cover &&
        spotlight.kind == ScanPassPossessionSpotlightKind.pressure) {
      return l10n.scanPassPossessionCuePressureRetreats;
    }
    return switch (spotlight.kind) {
      ScanPassPossessionSpotlightKind.pressure =>
        l10n.scanPassPossessionCuePressure,
      ScanPassPossessionSpotlightKind.support =>
        l10n.scanPassPossessionCueSupport,
      ScanPassPossessionSpotlightKind.futureSpace =>
        l10n.scanPassPossessionCueFutureSpace,
    };
  }

  String _coachLine(AppLocalizations l10n, ScanPassPossessionBranch branch,
      {ScanPassPossessionMoment? moment}) {
    final reviewMoment = moment ?? _moment;
    final state = branch.stateAt(reviewMoment);
    final closest = state.defenders.where((p) => !p.goalkeeper).reduce((a, b) =>
        a.position.distanceTo(state.ball) < b.position.distanceTo(state.ball)
            ? a
            : b);
    final index = branch.transitionIndexAt(reviewMoment);
    final transition =
        index == null || index < 0 ? null : branch.transitions[index];
    switch (reviewMoment) {
      case ScanPassPossessionMoment.receive:
        return branch.scene.variant == ScanPassPossessionVariant.cover
            ? l10n.scanPassPossessionReviewReceiveChanged
            : l10n.scanPassPossessionReviewReceive;
      case ScanPassPossessionMoment.touch:
        if (state.finished) {
          return state.end == AttackEnd.offside
              ? l10n.scanPassAttackOutcomeOffsideStatus
              : l10n.scanPassPossessionTouchLost(
                  transition?.interceptorNumber ?? closest.number);
        }
        if (transition?.action.kind == AttackActionKind.pass) {
          return l10n.scanPassPossessionTouchLayoff;
        }
        return branch.evidence
                .contains(ScanPassPossessionEvidence.pressureEscaped)
            ? l10n.scanPassPossessionTouchSpace(closest.number)
            : l10n.scanPassPossessionTouchPressed(closest.number);
      case ScanPassPossessionMoment.link:
        final receiver = transition?.action.targetNumber ?? state.carrierNumber;
        if (state.finished) {
          return state.end == AttackEnd.offside
              ? l10n.scanPassAttackOutcomeOffsideStatus
              : l10n.scanPassPossessionPassStopped(
                  transition?.interceptorNumber ?? closest.number, receiver);
        }
        final connections = _engine.availableConnections(branch.scene, state);
        return connections.isEmpty
            ? l10n.scanPassPossessionPassIsolated(receiver)
            : l10n.scanPassPossessionPassConnected(
                receiver, connections.join(', '));
      case ScanPassPossessionMoment.support:
        if (state.finished) {
          return l10n.scanPassPossessionSupportPressed(
              transition?.interceptorNumber ?? closest.number,
              state.carrierNumber);
        }
        final following = branch.transitions.skip((index ?? 0) + 1).toList();
        final connected = following.any((t) =>
            t.action.kind == AttackActionKind.pass &&
            t.action.targetNumber == 6 &&
            !t.after.finished);
        return connected
            ? l10n.scanPassPossessionReturnConnected(state.carrierNumber)
            : l10n.scanPassPossessionReturnClosed;
      case ScanPassPossessionMoment.finish:
        if (branch.outcome == ScanPassPossessionOutcomeKind.chanceCreated) {
          final result = switch (state.end) {
            AttackEnd.goal => l10n.scanPassAttackOutcomeGoalStatus,
            AttackEnd.saved => l10n.scanPassAttackOutcomeSavedStatus,
            AttackEnd.blocked => l10n.scanPassAttackOutcomeBlockedStatus,
            _ => l10n.scanPassPossessionReviewChance,
          };
          return l10n.scanPassPossessionShotResult(state.carrierNumber, result);
        }
        if (state.end == AttackEnd.offside) {
          return l10n.scanPassAttackOutcomeOffsideStatus;
        }
        if (branch.outcome == ScanPassPossessionOutcomeKind.recycled) {
          return l10n.scanPassPossessionReviewRecycle;
        }
        final last = branch.transitions.last;
        final opponent = last.interceptorNumber ?? closest.number;
        return switch (last.action.kind) {
          AttackActionKind.pass => l10n.scanPassPossessionPassStopped(
              opponent, last.action.targetNumber!),
          AttackActionKind.hold => l10n.scanPassPossessionSupportPressed(
              opponent, last.before.carrierNumber),
          _ => l10n.scanPassPossessionTouchLost(opponent),
        };
    }
  }

  String _detailBody(
    AppLocalizations l10n,
    ScanPassPossessionBranch branch,
  ) {
    final outcome = switch (branch.outcome) {
      ScanPassPossessionOutcomeKind.chanceCreated =>
        l10n.scanPassPossessionOutcomeChance,
      ScanPassPossessionOutcomeKind.recycled =>
        l10n.scanPassPossessionOutcomeRecycle,
      ScanPassPossessionOutcomeKind.turnover =>
        l10n.scanPassPossessionOutcomeTurnover,
    };
    return l10n.scanPassPossessionDetailBody(
      outcome,
      [
        for (final moment in branch.availableMoments)
          [_momentLabel(l10n, moment), _coachLine(l10n, branch, moment: moment)]
              .join('\n')
      ].join('\n\n'),
    );
  }

  ButtonStyle _outlinedStyle(_ScanPassColors colors) =>
      OutlinedButton.styleFrom(
        foregroundColor: colors.text,
        side: BorderSide(color: colors.line),
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      );
}

List<Offset> _possessionOptionCenters(
    List<Offset> targets, List<Offset> people, Size size) {
  final centers = <Offset>[];
  for (final target in targets) {
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

class _PossessionTargetConnectors extends CustomPainter {
  final List<Offset> targets;
  final List<Offset> centers;
  final Color color;
  const _PossessionTargetConnectors(this.targets, this.centers, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color.withValues(alpha: .5)
      ..strokeWidth = 1.2;
    for (var i = 0; i < targets.length; i++) {
      final delta = centers[i] - targets[i];
      if (delta.distance > 25) {
        canvas.drawLine(
            targets[i], centers[i] - delta / delta.distance * 24, line);
      }
      canvas.drawCircle(targets[i], 2.5, line);
    }
  }

  @override
  bool shouldRepaint(covariant _PossessionTargetConnectors oldDelegate) => true;
}
