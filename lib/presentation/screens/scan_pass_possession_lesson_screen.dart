part of 'scan_pass_game_screen.dart';

enum _PossessionMode { guided, independent, changedCue }

enum _PossessionUiPhase {
  catalog,
  guidedCue,
  observing,
  choosing,
  executing,
  review,
}

enum _PossessionBranchView { mine, coach }

class ScanPassPossessionLessonScreen extends StatefulWidget {
  final int? seed;
  final Duration? observationDuration;
  final Duration executionDuration;
  final WidgetBuilder? freeAttackBuilder;

  const ScanPassPossessionLessonScreen({
    super.key,
    this.seed,
    this.observationDuration,
    this.executionDuration = const Duration(milliseconds: 1000),
    this.freeAttackBuilder,
  });

  @override
  State<ScanPassPossessionLessonScreen> createState() =>
      _ScanPassPossessionLessonScreenState();
}

class _ScanPassPossessionLessonScreenState
    extends State<ScanPassPossessionLessonScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _catalog = ScanPassPossessionLessonEngine.catalog;

  final ScanPassPossessionLessonEngine _engine =
      const ScanPassPossessionLessonEngine();

  late final AnimationController _motionController;
  late ScanPassPossessionScene _scene;
  late ScanPassPossessionDecisionPoint _decision;
  late ScanPassPossessionBranch _coachBranch;

  _PossessionMode _mode = _PossessionMode.independent;
  _PossessionUiPhase _phase = _PossessionUiPhase.catalog;
  _PossessionBranchView _branchView = _PossessionBranchView.coach;
  ScanPassPossessionMoment _moment = ScanPassPossessionMoment.receive;
  int _catalogIndex = 0;
  int _cueIndex = 0;
  bool _foreground = true;
  bool _manuallyPaused = false;
  bool _modalOpen = false;
  bool _routeOpen = false;
  bool _playingReplay = false;
  bool _slowMotion = false;
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
    _loadCatalogItem(_catalog.first, startObservation: false);
  }

  @override
  void didUpdateWidget(covariant ScanPassPossessionLessonScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed) {
      _loadCatalogItem(_catalog[_catalogIndex], startObservation: false);
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

  void _loadCatalogItem(
    ScanPassPossessionScenario item, {
    required bool startObservation,
  }) {
    _scene = _engine.scene(variant: item.variant, situation: item.situation);
    _decision = _engine.firstPhase(_scene);
    _coachBranch = _engine.recommendedBranch(_scene);
    final itemIndex = _catalog.indexOf(item);
    _catalogIndex = itemIndex < 0 ? 0 : itemIndex;
    final mode = item.variant == ScanPassPossessionVariant.cover
        ? _PossessionMode.changedCue
        : _PossessionMode.independent;
    _mode = mode;
    _phase = startObservation
        ? _PossessionUiPhase.observing
        : _PossessionUiPhase.catalog;
    _branchView = _PossessionBranchView.mine;
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
    if (startObservation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _phase == _PossessionUiPhase.observing) {
          _runObservation();
        }
      });
    }
  }

  void _returnToCatalog() {
    setState(() {
      _phase = _PossessionUiPhase.catalog;
      _playingReplay = false;
      _pendingResult = null;
      _motionTransitions = const <AttackTransition>[];
      _motionController
        ..stop()
        ..value = 0;
    });
  }

  void _startScenario(int index) {
    setState(() => _loadCatalogItem(_catalog[index], startObservation: true));
  }

  void _restartScenario() {
    setState(() =>
        _loadCatalogItem(_catalog[_catalogIndex], startObservation: true));
  }

  void _nextScenario() {
    final next = (_catalogIndex + 1) % _catalog.length;
    setState(() => _loadCatalogItem(_catalog[next], startObservation: true));
  }

  void _runObservation() {
    _playTransitions(
      <AttackTransition>[_scene.observation],
      overrideDuration: widget.observationDuration,
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
    Duration? overrideDuration,
    required bool replay,
  }) {
    setState(() {
      _motionTransitions = transitions;
      _pendingResult = null;
      _phase = _PossessionUiPhase.executing;
      _playingReplay = replay;
      _motionController.value = 0;
    });
    _runMotion(transitions, overrideDuration: overrideDuration);
  }

  void _runMotion(
    List<AttackTransition> transitions, {
    Duration? overrideDuration,
  }) {
    _manuallyPaused = false;
    final reduced = AppMotion.reduceMotion(context);
    final modelSecondDuration = widget.executionDuration;
    if (transitions.isEmpty ||
        reduced ||
        overrideDuration == Duration.zero ||
        (overrideDuration == null && modelSecondDuration == Duration.zero)) {
      _motionController.value = 1;
      _finishMotion();
      return;
    }
    final modelSeconds =
        transitions.fold<double>(0, (sum, item) => sum + item.duration);
    // Preserve readable time for the whole possession. A full replay must not
    // be squeezed into the per-action animation duration.
    final speed = _slowMotion ? .65 : 1.0;
    final milliseconds = overrideDuration != null
        ? overrideDuration.inMilliseconds
        : (modelSeconds * modelSecondDuration.inMilliseconds / speed).round();
    _motionController.duration =
        Duration(milliseconds: math.max(1, milliseconds));
    unawaited(_motionController.forward(from: 0));
  }

  void _togglePlaybackSpeed() {
    final running = _motionController.isAnimating;
    final progress = _motionController.value;
    final oldSpeed = _slowMotion ? .65 : 1.0;
    final duration = _motionController.duration;
    setState(() {
      _slowMotion = !_slowMotion;
      if (_phase == _PossessionUiPhase.executing && duration != null) {
        _motionController.stop();
        _motionController.duration = Duration(
            microseconds:
                (duration.inMicroseconds * oldSpeed / (_slowMotion ? .65 : 1.0))
                    .round());
        _motionController.value = progress;
      }
    });
    if (running &&
        _foreground &&
        !_modalOpen &&
        !_routeOpen &&
        !_manuallyPaused) {
      unawaited(_motionController.forward(from: progress));
    }
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
          title: Text(_appBarTitle(l10n)),
          backgroundColor: colors.surface,
          foregroundColor: colors.text,
          iconTheme: IconThemeData(color: colors.text),
          surfaceTintColor: Colors.transparent,
          actions: [
            if (_phase != _PossessionUiPhase.catalog)
              AppBarActionButton.label(
                key: const ValueKey<String>('possession-return-catalog'),
                tooltip: l10n.scanPassPossessionCatalogReturnAction,
                onPressed: _returnToCatalog,
                icon: const Icon(Icons.grid_view_outlined),
                label: l10n.scanPassPossessionCatalogReturnShort,
                maxLabelWidth: 84,
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
            builder: (context, _) => _phase == _PossessionUiPhase.catalog
                ? _buildCatalog(l10n)
                : _buildBoard(l10n),
          ),
        ),
      ),
    );
  }

  String _appBarTitle(AppLocalizations l10n) {
    if (_phase == _PossessionUiPhase.catalog) return l10n.scanPassTitle;
    return l10n.scanPassPossessionSceneProgressTitle(
      _catalogIndex + 1,
      _catalog.length,
      _scenarioTitle(l10n, _catalog[_catalogIndex]),
    );
  }

  Widget _buildCatalog(AppLocalizations l10n) {
    final colors = _ScanPassColors.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final columns = width >= 1000
          ? 3
          : width >= 640
              ? 2
              : 1;
      final spacing = width < 380 ? 8.0 : 12.0;
      final itemWidth = (width - 28 - spacing * (columns - 1)) / columns;
      final cards = <Widget>[
        for (var i = 0; i < _catalog.length; i += 1)
          SizedBox(
            width: itemWidth,
            child: _ScenarioCatalogCard(
              key: ValueKey<String>('possession-card-${_catalog[i].id}'),
              scene: _previewScene(_catalog[i]),
              title: _scenarioTitle(l10n, _catalog[i]),
              description: _scenarioDescription(l10n, _catalog[i]),
              setup: _variantLabel(l10n, _catalog[i].variant),
              progress: l10n.scanPassPossessionCatalogCardProgress(
                i + 1,
                _catalog.length,
              ),
              actionLabel: l10n.scanPassPossessionStartScenarioAction,
              labels: _PitchLabels.from(l10n),
              colors: colors,
              onPressed: () => _startScenario(i),
            ),
          ),
        if (widget.freeAttackBuilder != null)
          SizedBox(
            width: itemWidth,
            child: _SecondaryCatalogAction(
              key: const ValueKey<String>('possession-free-attack-card'),
              title: l10n.scanPassFreeAttackAction,
              description: l10n.scanPassPossessionFreeAttackDescription,
              actionLabel: l10n.scanPassPossessionOpenFreeAttackAction,
              colors: colors,
              onPressed: () => _openBuilder(widget.freeAttackBuilder!),
            ),
          ),
      ];
      return SingleChildScrollView(
        key: const ValueKey<String>('possession-catalog'),
        padding: EdgeInsets.fromLTRB(14, 12, 14, 18 + spacing),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
            l10n.scanPassPossessionCatalogTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.scanPassPossessionCatalogIntro,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.muted,
                  height: 1.22,
                ),
          ),
          SizedBox(height: spacing),
          Wrap(spacing: spacing, runSpacing: spacing, children: cards),
        ]),
      );
    });
  }

  ScanPassPossessionScene _previewScene(ScanPassPossessionScenario item) =>
      _engine.scene(variant: item.variant, situation: item.situation);

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
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: math.max(
          48,
          MediaQuery.textScalerOf(context).scale(13) * 1.12 * 2 + 8,
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
              if (constraints.maxWidth >= 420) ...[
                _MiniChip(text: _modeLabel(l10n), color: colors.background),
                const SizedBox(width: 6),
              ],
              _SpeedToggle(
                key: const ValueKey<String>('possession-speed-toggle'),
                slow: _slowMotion,
                label: _slowMotion
                    ? l10n.scanPassPossessionSpeedSlow
                    : l10n.scanPassPossessionSpeedNormal,
                tooltip: l10n.scanPassPossessionSlowMotionTooltip,
                onPressed: _togglePlaybackSpeed,
              ),
            ]),
          ),
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
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    key: const ValueKey<String>('possession-route-overlay'),
                    painter: _PossessionRouteOverlayPainter(
                      routes: _routeOverlayItems(l10n),
                      showLabels: !_canChoose,
                      actors: [
                        ..._displayState.attackers,
                        ..._displayState.defenders
                      ].map((p) => p.position).toList(),
                      legendPass: l10n.scanPassPossessionLegendPassPath,
                      legendRun: l10n.scanPassPossessionLegendRunPath,
                      brightness: Theme.of(context).brightness,
                      fontFamily:
                          Theme.of(context).textTheme.bodyMedium?.fontFamily,
                    ),
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
      final routes = _choiceRouteItems(l10n);
      final targets = [for (final route in routes) geometry.toOffset(route.to)];
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
        for (var i = 0; i < routes.length; i += 1)
          _PitchButton(
            key: ValueKey<String>('possession-action-${routes[i].choice.name}'),
            center: centers[i],
            label: routes[i].semanticsLabel,
            selected: false,
            color: colors.team,
            onPressed: () => _choose(routes[i].choice),
            child: Text(
              l10n.scanPassPossessionRouteDistance(routes[i].numberLabel,
                  _distanceText(routes[i].distanceMetres)),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                  color: colors.text,
                  fontSize: 11,
                  height: 1.15,
                  fontWeight: FontWeight.w900),
            ),
          ),
      ]);
    });
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
    return 186.0 + math.max(0, scale - 1) * 50;
  }

  Widget _dockContent(AppLocalizations l10n, {required bool landscape}) {
    return switch (_phase) {
      _PossessionUiPhase.catalog => const SizedBox.shrink(),
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
    final colors = _ScanPassColors.of(context);
    final routes = _choiceRouteItems(l10n);
    final buttons = [
      for (final route in routes)
        Semantics(
            button: true,
            label: route.semanticsLabel,
            child: OutlinedButton(
                key: ValueKey<String>('possession-dock-${route.choice.name}'),
                onPressed: () => _choose(route.choice),
                style: _outlinedStyle(colors).copyWith(
                    minimumSize: const WidgetStatePropertyAll(Size(0, 64)),
                    padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 4, vertical: 5))),
                child: Text(route.dockLabel,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    style:
                        TextStyle(fontSize: compact ? 12 : 14, height: 1.2)))),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _phaseHeader(
        icon: _decisionIcon(_decision.kind),
        label: _decisionPrompt(l10n, _decision.kind),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            key: const ValueKey<String>('possession-coach-demo'),
            onPressed: _playGuidedRoute,
            style: _outlinedStyle(_ScanPassColors.of(context)),
            icon: const Icon(Icons.school_outlined, size: 18),
            label: Text(l10n.scanPassPossessionCoachDemoAction),
          ),
        ),
      ]),
      const SizedBox(height: 8),
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
                key: const ValueKey('possession-retry'),
                onPressed: _restartScenario,
                style: _outlinedStyle(colors),
                child: Text(l10n.scanPassJudgmentRetryAction,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12, height: 1.1)))),
        const SizedBox(width: 6),
        Expanded(
            child: FilledButton(
                key: const ValueKey('possession-next-scenario'),
                onPressed: _nextScenario,
                style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 6)),
                child: Text(l10n.scanPassPossessionNextScenarioAction,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12, height: 1.1)))),
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
    if (_phase == _PossessionUiPhase.catalog) return _scene.reception;
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
    if (_phase == _PossessionUiPhase.catalog) return _scene.reception;
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
        _PossessionUiPhase.catalog => l10n.scanPassPossessionCatalogTitle,
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
        _PossessionMode.independent => l10n.scanPassPossessionVariantPressure,
        _PossessionMode.changedCue => l10n.scanPassPossessionVariantCover,
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

  List<_PossessionChoiceRoute> _choiceRouteItems(AppLocalizations l10n) {
    return [
      for (var i = 0; i < _decision.choices.length; i += 1)
        _choiceRoute(l10n, _decision.choices[i], i + 1),
    ];
  }

  _PossessionChoiceRoute _choiceRoute(
    AppLocalizations l10n,
    ScanPassPossessionChoice choice,
    int number,
  ) {
    final target = _engine.targetFor(_decision, choice);
    final ballRoute = _choiceUsesBallPath(choice);
    final origin = ballRoute
        ? _decision.state.ball
        : _playerByNumber(_decision.state.attackers, 6)!.position;
    final distance = _distanceMetres(origin, target);
    final distanceText = _distanceText(distance);
    final baseLabel = _choiceLabel(l10n, choice);
    return _PossessionChoiceRoute(
      choice: choice,
      from: origin,
      to: target,
      ballPath: ballRoute,
      numberLabel: number.toString(),
      dockLabel: l10n.scanPassPossessionNumberedChoice(
        number,
        baseLabel,
        distanceText,
      ),
      semanticsLabel: l10n.scanPassPossessionChoiceWithDistanceLabel(
        number,
        _choiceSemantics(l10n, choice),
        distanceText,
      ),
      distanceMetres: distance,
    );
  }

  List<_PossessionRouteOverlayItem> _routeOverlayItems(AppLocalizations l10n) {
    if (_phase == _PossessionUiPhase.choosing) {
      return [
        for (final route in _choiceRouteItems(l10n))
          _PossessionRouteOverlayItem(
            from: route.from,
            to: route.to,
            ballPath: route.ballPath,
            label: l10n.scanPassPossessionRouteDistance(
              route.numberLabel,
              _distanceText(route.distanceMetres),
            ),
            distanceMetres: route.distanceMetres,
          ),
      ];
    }
    if (_phase == _PossessionUiPhase.executing) {
      final transition = _activeMotion?.transition;
      if (transition == null) return const <_PossessionRouteOverlayItem>[];
      return _selectedTransitionRoutes(l10n, transition);
    }
    return const <_PossessionRouteOverlayItem>[];
  }

  List<_PossessionRouteOverlayItem> _selectedTransitionRoutes(
    AppLocalizations l10n,
    AttackTransition transition,
  ) {
    final routes = <_PossessionRouteOverlayItem>[];
    if (transition.action.kind == AttackActionKind.pass ||
        transition.action.kind == AttackActionKind.shoot) {
      final distance =
          _distanceMetres(transition.before.ball, transition.ballEnd);
      routes.add(_PossessionRouteOverlayItem(
        from: transition.before.ball,
        to: transition.ballEnd,
        ballPath: true,
        label: l10n.scanPassPossessionSelectedRouteDistance(
          _distanceText(distance),
        ),
        distanceMetres: distance,
      ));
    }
    final before6 = _playerByNumber(transition.before.attackers, 6);
    final after6 = _playerByNumber(transition.after.attackers, 6);
    if (before6 != null && after6 != null) {
      final path = transition.motionSamples.isEmpty
          ? [before6.position, after6.position]
          : [
              for (final sample in transition.motionSamples)
                _playerByNumber(sample.attackers, 6)!.position
            ];
      var distance = 0.0;
      for (var i = 1; i < path.length; i++) {
        distance += _distanceMetres(path[i - 1], path[i]);
      }
      if (distance >= .4 ||
          transition.action.kind == AttackActionKind.hold ||
          transition.action.kind == AttackActionKind.carry) {
        routes.add(_PossessionRouteOverlayItem(
          from: before6.position,
          to: after6.position,
          path: path,
          ballPath: false,
          label: l10n.scanPassPossessionSelectedRunDistance(
            _distanceText(distance),
          ),
          distanceMetres: distance,
        ));
      }
    }
    return routes;
  }

  bool _choiceUsesBallPath(ScanPassPossessionChoice choice) =>
      choice == ScanPassPossessionChoice.oneTouchLayoff ||
      choice == ScanPassPossessionChoice.passTo8 ||
      choice == ScanPassPossessionChoice.passTo9 ||
      choice == ScanPassPossessionChoice.recycle4;

  static double _distanceMetres(ScanPassPoint from, ScanPassPoint to) =>
      ScanPassPossessionLessonEngine.distanceMetres(from, to);

  static String _distanceText(double metres) => metres.toStringAsFixed(1);

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

  String _scenarioTitle(
    AppLocalizations l10n,
    ScanPassPossessionScenario item,
  ) =>
      l10n.scanPassPossessionScenarioTitle(
        _situationTitle(l10n, item.situation),
        _variantLabel(l10n, item.variant),
      );

  String _scenarioDescription(
    AppLocalizations l10n,
    ScanPassPossessionScenario item,
  ) =>
      l10n.scanPassPossessionScenarioDescription(
        _situationDescription(l10n, item.situation),
        _variantDescription(l10n, item.variant),
      );

  String _variantLabel(
    AppLocalizations l10n,
    ScanPassPossessionVariant variant,
  ) =>
      switch (variant) {
        ScanPassPossessionVariant.pressure =>
          l10n.scanPassPossessionVariantPressure,
        ScanPassPossessionVariant.cover => l10n.scanPassPossessionVariantCover,
      };

  String _variantDescription(
    AppLocalizations l10n,
    ScanPassPossessionVariant variant,
  ) =>
      switch (variant) {
        ScanPassPossessionVariant.pressure =>
          l10n.scanPassPossessionVariantPressureDescription,
        ScanPassPossessionVariant.cover =>
          l10n.scanPassPossessionVariantCoverDescription,
      };

  String _situationTitle(
    AppLocalizations l10n,
    ScanPassPossessionSituation situation,
  ) =>
      switch (situation) {
        ScanPassPossessionSituation.centralReceive =>
          l10n.scanPassPossessionSituationCentralReceive,
        ScanPassPossessionSituation.halfSpace =>
          l10n.scanPassPossessionSituationHalfSpace,
        ScanPassPossessionSituation.touchline =>
          l10n.scanPassPossessionSituationTouchline,
        ScanPassPossessionSituation.layoff =>
          l10n.scanPassPossessionSituationLayoff,
        ScanPassPossessionSituation.thirdPlayer =>
          l10n.scanPassPossessionSituationThirdPlayer,
        ScanPassPossessionSituation.transition =>
          l10n.scanPassPossessionSituationTransition,
      };

  String _situationDescription(
    AppLocalizations l10n,
    ScanPassPossessionSituation situation,
  ) =>
      switch (situation) {
        ScanPassPossessionSituation.centralReceive =>
          l10n.scanPassPossessionSituationCentralReceiveDescription,
        ScanPassPossessionSituation.halfSpace =>
          l10n.scanPassPossessionSituationHalfSpaceDescription,
        ScanPassPossessionSituation.touchline =>
          l10n.scanPassPossessionSituationTouchlineDescription,
        ScanPassPossessionSituation.layoff =>
          l10n.scanPassPossessionSituationLayoffDescription,
        ScanPassPossessionSituation.thirdPlayer =>
          l10n.scanPassPossessionSituationThirdPlayerDescription,
        ScanPassPossessionSituation.transition =>
          l10n.scanPassPossessionSituationTransitionDescription,
      };

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

class _ScenarioCatalogCard extends StatelessWidget {
  final ScanPassPossessionScene scene;
  final String title;
  final String description;
  final String setup;
  final String progress;
  final String actionLabel;
  final _PitchLabels labels;
  final _ScanPassColors colors;
  final VoidCallback onPressed;

  const _ScenarioCatalogCard({
    super.key,
    required this.scene,
    required this.title,
    required this.description,
    required this.setup,
    required this.progress,
    required this.actionLabel,
    required this.labels,
    required this.colors,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.line),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              _MiniChip(text: progress, color: colors.background),
            ]),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 1.75,
              child: CustomPaint(
                painter: _AttackPitchPainter(
                  displayState: scene.reception,
                  baseState: scene.reception,
                  selectedAction: null,
                  selectedTarget: null,
                  previewOffside: null,
                  activeTransition: null,
                  activeProgress: 0,
                  history: const <AttackTransition>[],
                  scanOverlay: false,
                  terminalBanner: false,
                  labels: labels,
                  brightness: Theme.of(context).brightness,
                  fontFamily:
                      Theme.of(context).textTheme.bodyMedium?.fontFamily,
                  learnerNumber: 6,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.muted,
                    height: 1.18,
                  ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _MiniChip(text: setup, color: colors.active)),
              const SizedBox(width: 8),
              FilledButton.icon(
                key: ValueKey<String>('possession-start-${title.hashCode}'),
                onPressed: onPressed,
                icon: const Icon(Icons.play_arrow_outlined, size: 18),
                label: Text(actionLabel),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _SecondaryCatalogAction extends StatelessWidget {
  final String title;
  final String description;
  final String actionLabel;
  final _ScanPassColors colors;
  final VoidCallback onPressed;

  const _SecondaryCatalogAction({
    super.key,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.colors,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.background,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.line),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Icon(Icons.sports_soccer_outlined, color: colors.accent, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.muted,
                    height: 1.18,
                  ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.open_in_new_outlined, size: 18),
                label: Text(actionLabel),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SpeedToggle extends StatelessWidget {
  final bool slow;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  const _SpeedToggle(
      {super.key,
      required this.slow,
      required this.label,
      required this.tooltip,
      required this.onPressed});

  @override
  Widget build(BuildContext context) => AppBarActionButton.label(
      icon:
          Icon(slow ? Icons.slow_motion_video : Icons.speed_outlined, size: 17),
      label: label,
      tooltip: tooltip,
      onPressed: onPressed,
      selected: slow,
      compact: true,
      margin: EdgeInsets.zero,
      maxLabelWidth: 48);
}

class _PossessionChoiceRoute {
  final ScanPassPossessionChoice choice;
  final ScanPassPoint from;
  final ScanPassPoint to;
  final bool ballPath;
  final String numberLabel;
  final String dockLabel;
  final String semanticsLabel;
  final double distanceMetres;

  const _PossessionChoiceRoute({
    required this.choice,
    required this.from,
    required this.to,
    required this.ballPath,
    required this.numberLabel,
    required this.dockLabel,
    required this.semanticsLabel,
    required this.distanceMetres,
  });
}

class _PossessionRouteOverlayItem {
  final ScanPassPoint from;
  final ScanPassPoint to;
  final bool ballPath;
  final List<ScanPassPoint> path;
  final String label;
  final double distanceMetres;

  const _PossessionRouteOverlayItem({
    required this.from,
    required this.to,
    required this.ballPath,
    this.path = const [],
    required this.label,
    required this.distanceMetres,
  });
}

class _PossessionRouteOverlayPainter extends CustomPainter {
  final List<_PossessionRouteOverlayItem> routes;
  final String legendPass;
  final String legendRun;
  final Brightness brightness;
  final String? fontFamily;
  final List<ScanPassPoint> actors;
  final bool showLabels;

  const _PossessionRouteOverlayPainter({
    required this.routes,
    required this.legendPass,
    required this.legendRun,
    required this.brightness,
    this.fontFamily,
    this.actors = const [],
    this.showLabels = true,
  });

  bool get _isDark => brightness == Brightness.dark;

  Color get _pass =>
      _isDark ? const Color(0xFFE2C57E) : const Color(0xFF84611F);

  Color get _run => _isDark ? const Color(0xFF77A9C4) : const Color(0xFF35718D);

  Color get _text =>
      _isDark ? const Color(0xFFE9EEEB) : const Color(0xFF1D2D31);

  Color get _surface =>
      (_isDark ? const Color(0xFF111A1E) : Colors.white).withValues(alpha: .90);

  @override
  void paint(Canvas canvas, Size size) {
    if (routes.isEmpty) return;
    final geometry = _PitchGeometry(size);
    final usedLabels = [
      for (final p in actors)
        Rect.fromCenter(
            center: geometry.toOffset(p) + const Offset(0, 4),
            width: 42,
            height: 64)
    ];
    for (final route in routes) {
      final paint = Paint()
        ..color = (route.ballPath ? _pass : _run).withValues(alpha: .88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = route.ballPath ? 2.3 : 2.0
        ..strokeCap = StrokeCap.round;
      final from = geometry.toOffset(route.from);
      final to = geometry.toOffset(route.to);
      if ((to - from).distance < 3) continue;
      if (route.ballPath) {
        canvas.drawLine(from, to, paint);
      } else {
        final points = route.path.length > 1
            ? route.path.map(geometry.toOffset).toList()
            : [from, to];
        final path = Path()..moveTo(points.first.dx, points.first.dy);
        for (final p in points.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
        for (final metric in path.computeMetrics()) {
          for (var distance = 0.0; distance < metric.length; distance += 12) {
            canvas.drawPath(
                metric.extractPath(
                    distance, math.min(distance + 7, metric.length)),
                paint);
          }
        }
      }
      final arrowFrom = route.path.length > 1
          ? route.path.reversed.skip(1).map(geometry.toOffset).firstWhere(
              (point) => (to - point).distance >= 10,
              orElse: () => from)
          : from;
      _drawArrowHead(canvas, arrowFrom, to, paint);
      _drawArrival(canvas, to, route.ballPath ? _pass : _run);
      if (showLabels) {
        _drawLabel(canvas, geometry, route.label, from, to, usedLabels);
      }
    }
    _drawLegend(canvas, geometry);
  }

  void _drawArrival(Canvas canvas, Offset center, Color color) {
    canvas.drawCircle(
      center,
      7,
      Paint()..color = color.withValues(alpha: .14),
    );
    canvas.drawCircle(
      center,
      7,
      Paint()
        ..color = color.withValues(alpha: .88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  void _drawLabel(
    Canvas canvas,
    _PitchGeometry geometry,
    String label,
    Offset from,
    Offset to,
    List<Rect> usedLabels,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: _text,
          fontSize: math.max(10, geometry.size.shortestSide * .030),
          fontWeight: FontWeight.w800,
          fontFamily: fontFamily,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 110);
    final delta = to - from;
    final normal = delta.distance < 1
        ? const Offset(0, -1)
        : Offset(-delta.dy, delta.dx) / delta.distance;
    final anchor = Offset.lerp(from, to, .58)! + normal * 24;
    Rect rectFor(Offset point) => Rect.fromLTWH(
        point.dx - painter.width / 2 - 7,
        point.dy - painter.height / 2 - 4,
        painter.width + 14,
        painter.height + 8);
    Rect clamp(Rect rect) {
      return rect.shift(Offset(
          rect.left < geometry.fieldRect.left
              ? geometry.fieldRect.left - rect.left
              : rect.right > geometry.fieldRect.right
                  ? geometry.fieldRect.right - rect.right
                  : 0,
          rect.top < geometry.fieldRect.top
              ? geometry.fieldRect.top - rect.top
              : rect.bottom > geometry.fieldRect.bottom
                  ? geometry.fieldRect.bottom - rect.bottom
                  : 0));
    }

    var rect = clamp(rectFor(anchor));
    var bestCost = double.infinity;
    for (var radius = 0; radius <= 180; radius += 12) {
      for (var angle = 0; angle < 16; angle++) {
        final candidate = clamp(rectFor(anchor +
            Offset(math.cos(angle * math.pi / 8) * radius,
                math.sin(angle * math.pi / 8) * radius)));
        final cost = (candidate.center - anchor).distance +
            usedLabels.where((r) => r.overlaps(candidate.inflate(3))).length *
                10000;
        if (cost < bestCost) {
          bestCost = cost;
          rect = candidate;
        }
      }
      if (bestCost < 10000) break;
    }
    usedLabels.add(rect);
    canvas.drawRRect(
      BorderRadius.circular(5).toRRect(rect),
      Paint()..color = _surface,
    );
    painter.paint(
      canvas,
      Offset(
        rect.center.dx - painter.width / 2,
        rect.center.dy - painter.height / 2,
      ),
    );
  }

  void _drawLegend(Canvas canvas, _PitchGeometry geometry) {
    final field = geometry.fieldRect;
    final width = math.min(190.0, field.width * .58);
    final rect = Rect.fromLTWH(
      field.left + 8,
      field.bottom - 38,
      width,
      30,
    );
    canvas.drawRRect(
      BorderRadius.circular(5).toRRect(rect),
      Paint()..color = _surface,
    );
    final start = Offset(rect.left + 10, rect.center.dy - 6);
    _legendLine(canvas, start, _pass, dashed: false);
    _legendText(canvas, legendPass, start + const Offset(26, 0));
    final second = Offset(rect.left + 10, rect.center.dy + 8);
    _legendLine(canvas, second, _run, dashed: true);
    _legendText(canvas, legendRun, second + const Offset(26, 0));
  }

  void _legendLine(Canvas canvas, Offset start, Color color,
      {required bool dashed}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final end = start + const Offset(20, 0);
    if (dashed) {
      _drawDashedLine(canvas, start, end, paint, dash: 4, gap: 3);
    } else {
      canvas.drawLine(start, end, paint);
    }
  }

  void _legendText(Canvas canvas, String label, Offset anchor) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: _text,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: fontFamily,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 145);
    painter.paint(canvas, anchor - Offset(0, painter.height / 2));
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
    if (vector.distance < 5) return;
    final angle = math.atan2(vector.dy, vector.dx);
    const length = 8.0;
    final left =
        to - Offset(math.cos(angle - .55), math.sin(angle - .55)) * length;
    final right =
        to - Offset(math.cos(angle + .55), math.sin(angle + .55)) * length;
    canvas.drawLine(to, left, paint);
    canvas.drawLine(to, right, paint);
  }

  @override
  bool shouldRepaint(covariant _PossessionRouteOverlayPainter oldDelegate) {
    return oldDelegate.routes != routes ||
        oldDelegate.legendPass != legendPass ||
        oldDelegate.legendRun != legendRun ||
        oldDelegate.brightness != brightness ||
        oldDelegate.fontFamily != fontFamily ||
        oldDelegate.actors != actors ||
        oldDelegate.showLabels != showLabels;
  }
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
        final coversPlayer = people.any((p) => (p - candidate).distance < 46);
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
