part of 'scan_pass_game_screen.dart';

enum _PressureLessonPhase {
  observing,
  firstDecision,
  executing,
  nextDecision,
  review,
  summary,
}

enum _PressurePlayback { observation, learnerAction, replay, alternative }

class ScanPassPressureLessonScreen extends StatefulWidget {
  final int? seed;
  final Duration? observationDuration;
  final Duration executionDuration;
  final MatchMomentSourceLauncher? sourceLauncher;

  const ScanPassPressureLessonScreen({
    super.key,
    this.seed,
    this.observationDuration,
    this.executionDuration = const Duration(milliseconds: 1000),
    this.sourceLauncher,
  });

  @override
  State<ScanPassPressureLessonScreen> createState() =>
      _ScanPassPressureLessonScreenState();
}

class _ScanPassPressureLessonScreenState
    extends State<ScanPassPressureLessonScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _engine = ScanPassPressureEngine();

  late final AnimationController _motion;
  late PressureLessonSession _session;
  late PressureObservation _observation;
  late PressureWorld _current;
  late PressureWorld _decisionSnapshot;
  late Rect _viewBounds;

  _PressureLessonPhase _phase = _PressureLessonPhase.observing;
  _PressurePlayback _playback = _PressurePlayback.observation;
  int _situationIndex = 0;
  int _sessionGeneration = 0;
  List<PressureDecisionOption> _options = const [];
  List<PressureTrace> _completedTraces = const [];
  PressureTrace? _activeTrace;
  PressureSimulationResult? _firstResult;
  PressureSimulationResult? _nextResult;
  PressureLessonAttempt? _attempt;
  PressureDecisionStage _lastStage = PressureDecisionStage.firstContact;
  PressureWorld? _lastSnapshot;
  PressureDecisionOption? _lastOption;
  List<PressureDecisionOption> _lastOptions = const [];
  PressureSimulationResult? _alternativeResult;
  PressureDecisionOption? _alternativeOption;
  bool _showingAlternative = false;
  bool _manualPause = false;
  bool _modalOpen = false;
  bool _foreground = true;
  VoidCallback? _motionCompletion;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  bool get _isChoosing =>
      _phase == _PressureLessonPhase.firstDecision ||
      _phase == _PressureLessonPhase.nextDecision;
  bool get _isMoving =>
      _phase == _PressureLessonPhase.observing ||
      _phase == _PressureLessonPhase.executing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _motion = AnimationController(vsync: this)
      ..addStatusListener(_handleMotionStatus);
    final situations = _buildSituations();
    _session = PressureLessonSession(situations: situations);
    _prepareSituation(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startObservation();
    });
  }

  @override
  void didUpdateWidget(covariant ScanPassPressureLessonScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed) {
      _sessionGeneration = 0;
      final situations = _buildSituations();
      _session = PressureLessonSession(situations: situations);
      _prepareSituation(0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startObservation();
      });
    }
  }

  List<PressureLessonScenario> _buildSituations() {
    final base = widget.seed ??
        DateTime.now().millisecondsSinceEpoch.remainder(0x3fffffff);
    return PressureLessonCatalog.build(
      seed: base + _sessionGeneration * 9973,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _foreground = false;
      _motion.stop();
      return;
    }
    if (state != AppLifecycleState.resumed) return;
    _foreground = true;
    _resumeMotionIfAllowed();
  }

  void _prepareSituation(int index) {
    _motion
      ..stop()
      ..value = 0;
    _motionCompletion = null;
    _situationIndex = index;
    _observation = _engine.observe(_session.situations[index]);
    _viewBounds = _pressureViewBounds(_observation);
    _current = _observation.trace.first;
    _decisionSnapshot = _observation.decisionState;
    _phase = _PressureLessonPhase.observing;
    _playback = _PressurePlayback.observation;
    _options = const [];
    _completedTraces = const [];
    _activeTrace = _observation.trace;
    _firstResult = null;
    _nextResult = null;
    _attempt = null;
    _lastSnapshot = null;
    _lastOption = null;
    _lastOptions = const [];
    _alternativeResult = null;
    _alternativeOption = null;
    _showingAlternative = false;
    _manualPause = false;
  }

  void _startObservation() {
    if (_phase != _PressureLessonPhase.observing) return;
    _playTrace(
      _observation.trace,
      widget.observationDuration ?? const Duration(milliseconds: 2400),
      () {
        setState(() {
          _current = _observation.decisionState;
          _decisionSnapshot = _current;
          _completedTraces = [_observation.trace];
          _activeTrace = null;
          _phase = _PressureLessonPhase.firstDecision;
          _options =
              _engine.optionsFor(_current, PressureDecisionStage.firstContact);
        });
      },
    );
  }

  void _playTrace(
    PressureTrace trace,
    Duration duration,
    VoidCallback completion,
  ) {
    _motionCompletion = completion;
    _activeTrace = trace;
    _motion.duration = duration;
    _manualPause = false;
    if (duration == Duration.zero) {
      _motion.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _motionCompletion == null) return;
        final callback = _motionCompletion!;
        _motionCompletion = null;
        callback();
      });
      return;
    }
    unawaited(_motion.forward(from: 0));
  }

  void _handleMotionStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _motionCompletion == null) {
      return;
    }
    final callback = _motionCompletion!;
    _motionCompletion = null;
    callback();
  }

  void _choose(PressureDecisionOption option) {
    if (!_isChoosing) return;
    final stage = _phase == _PressureLessonPhase.firstDecision
        ? PressureDecisionStage.firstContact
        : PressureDecisionStage.nextConnection;
    final snapshot = _decisionSnapshot;
    final result = _engine.simulate(snapshot, option.action);
    _lastStage = stage;
    _lastSnapshot = snapshot;
    _lastOption = option;
    _lastOptions = List.unmodifiable(_options);
    if (stage == PressureDecisionStage.firstContact) {
      _firstResult = result;
      _nextResult = null;
    } else {
      _nextResult = result;
    }
    setState(() {
      _phase = _PressureLessonPhase.executing;
      _playback = _PressurePlayback.learnerAction;
      _options = const [];
      _showingAlternative = false;
      _activeTrace = result.trace;
    });
    _playTrace(result.trace, widget.executionDuration, () {
      setState(() {
        _current = result.after;
        _completedTraces = [..._completedTraces, result.trace];
        _activeTrace = null;
        if (stage == PressureDecisionStage.firstContact &&
            option.action.kind == PressureActionKind.firstTouch &&
            result.after.possession == PressurePossession.attack) {
          _decisionSnapshot = result.after;
          _phase = _PressureLessonPhase.nextDecision;
          _options = _engine.optionsFor(
              result.after, PressureDecisionStage.nextConnection);
        } else {
          _finishAttempt();
        }
      });
    });
  }

  void _finishAttempt() {
    final first = _firstResult!;
    final lastSnapshot = _lastSnapshot!;
    final attempt = PressureLessonAttempt(
      situationIndex: _situationIndex,
      firstDecisionState: first.before,
      firstDecision: first,
      lastDecisionState: lastSnapshot,
      nextDecision: _nextResult,
    );
    _attempt = attempt;
    _session = _session.recordFirstAttempt(attempt);
    _buildAlternative();
    _current = attempt.terminal.after;
    _phase = _PressureLessonPhase.review;
  }

  void _buildAlternative() {
    final snapshot = _lastSnapshot;
    final selected = _lastOption;
    if (snapshot == null || selected == null) return;
    final candidates = _lastOptions
        .where((option) => option.key != selected.key)
        .map((option) => (
              option: option,
              result: _engine.simulate(snapshot, option.action),
            ))
        .toList();
    candidates.sort((a, b) {
      final quality = _qualityRank(b.result).compareTo(_qualityRank(a.result));
      if (quality != 0) return quality;
      final progress = b.result.assessment.actionProgressMetres
          .compareTo(a.result.assessment.actionProgressMetres);
      if (progress != 0) return progress;
      return b.result.assessment.pressureClearanceMetres
          .compareTo(a.result.assessment.pressureClearanceMetres);
    });
    if (candidates.isEmpty) return;
    _alternativeOption = candidates.first.option;
    _alternativeResult = candidates.first.result;
  }

  int _qualityRank(PressureSimulationResult result) =>
      switch (result.assessment.quality) {
        PressureDecisionQuality.strong => 3,
        PressureDecisionQuality.sound => 2,
        PressureDecisionQuality.compromised => 1,
        PressureDecisionQuality.lost => 0,
      };

  void _retryLastDecision() {
    final snapshot = _lastSnapshot;
    if (snapshot == null) return;
    setState(() {
      _current = snapshot;
      _decisionSnapshot = snapshot;
      _options = _lastOptions;
      _phase = _lastStage == PressureDecisionStage.firstContact
          ? _PressureLessonPhase.firstDecision
          : _PressureLessonPhase.nextDecision;
      if (_lastStage == PressureDecisionStage.firstContact) {
        _firstResult = null;
        _nextResult = null;
        _completedTraces = [_observation.trace];
      } else {
        _nextResult = null;
        _completedTraces = [_observation.trace, _firstResult!.trace];
      }
      _attempt = null;
      _alternativeResult = null;
      _alternativeOption = null;
      _showingAlternative = false;
    });
  }

  void _playAlternative() {
    final result = _alternativeResult;
    if (result == null) return;
    setState(() {
      _current = result.before;
      _phase = _PressureLessonPhase.executing;
      _playback = _PressurePlayback.alternative;
      _activeTrace = result.trace;
      _showingAlternative = true;
    });
    _playTrace(result.trace, widget.executionDuration, () {
      setState(() {
        _current = result.after;
        _activeTrace = null;
        _phase = _PressureLessonPhase.review;
      });
    });
  }

  void _returnToAttempt() {
    final attempt = _attempt;
    if (attempt == null) return;
    setState(() {
      _showingAlternative = false;
      _current = attempt.terminal.after;
      _activeTrace = null;
      _phase = _PressureLessonPhase.review;
    });
  }

  void _replayAttempt() {
    final attempt = _attempt;
    if (attempt == null) return;
    final trace = PressureTrace.join([
      _observation.trace,
      attempt.firstDecision.trace,
      if (attempt.nextDecision != null) attempt.nextDecision!.trace,
    ]);
    setState(() {
      _current = trace.first;
      _phase = _PressureLessonPhase.executing;
      _playback = _PressurePlayback.replay;
      _activeTrace = trace;
      _showingAlternative = false;
    });
    final perSecond = widget.executionDuration == Duration.zero
        ? Duration.zero
        : Duration(milliseconds: math.max(900, (trace.duration * 420).round()));
    _playTrace(trace, perSecond, () {
      setState(() {
        _current = attempt.terminal.after;
        _activeTrace = null;
        _phase = _PressureLessonPhase.review;
      });
    });
  }

  void _nextSituation() {
    if (_situationIndex == PressureLessonCatalog.situationCount - 1) {
      for (var index = 0;
          index < PressureLessonCatalog.situationCount;
          index++) {
        if (!_session.firstAttempts.containsKey(index)) {
          _openSituation(index);
          return;
        }
      }
      setState(() {
        _phase = _PressureLessonPhase.summary;
        _activeTrace = null;
      });
      return;
    }
    _openSituation(_situationIndex + 1);
  }

  void _openSituation(int index) {
    setState(() => _prepareSituation(index));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startObservation();
    });
  }

  void _restartLesson() {
    _sessionGeneration += 1;
    _session = PressureLessonSession(situations: _buildSituations());
    _openSituation(0);
  }

  Future<void> _openReference() async {
    _motion.stop();
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ScanPassMatchMomentScreen(
        sourceLauncher: widget.sourceLauncher,
        referenceOnly: true,
      ),
    ));
    if (!mounted) return;
    _resumeMotionIfAllowed();
  }

  void _togglePause() {
    if (!_isMoving) return;
    setState(() {
      _manualPause = !_manualPause;
      if (_manualPause) {
        _motion.stop();
      } else {
        _resumeMotionIfAllowed();
      }
    });
  }

  void _resumeMotionIfAllowed() {
    if (!_foreground || _modalOpen || _manualPause || !_isMoving) return;
    if (_motion.value < 1) unawaited(_motion.forward());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final colors = _ScanPassColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.pressureLessonTitle,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: colors.surface,
        foregroundColor: colors.text,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_isMoving)
            AppBarActionButton.icon(
              key: const ValueKey<String>('pressure-pause'),
              icon: _manualPause ? Icons.play_arrow : Icons.pause,
              tooltip: _manualPause
                  ? l10n.pressureLessonResume
                  : l10n.pressureLessonPause,
              onPressed: _togglePause,
            ),
          if (_phase == _PressureLessonPhase.review) ...[
            AppBarActionButton.icon(
              key: const ValueKey<String>('pressure-replay'),
              icon: Icons.replay,
              tooltip: _showingAlternative
                  ? l10n.pressureLessonReplayAlternative
                  : l10n.pressureLessonReplayMine,
              onPressed:
                  _showingAlternative ? _playAlternative : _replayAttempt,
            ),
            AppBarActionButton.icon(
              key: const ValueKey<String>('pressure-reference'),
              icon: Icons.ondemand_video_outlined,
              tooltip: l10n.pressureLessonReference,
              onPressed: () => unawaited(_openReference()),
            ),
          ],
          AppBarActionMenuButton<VoidCallback>(
            key: const ValueKey<String>('pressure-more'),
            icon: Icons.more_horiz,
            tooltip: l10n.pressureLessonMore,
            onOpened: () {
              _modalOpen = true;
              _motion.stop();
            },
            onCanceled: () {
              _modalOpen = false;
              _resumeMotionIfAllowed();
            },
            onSelected: (action) {
              _modalOpen = false;
              action();
              _resumeMotionIfAllowed();
            },
            itemBuilder: (_) => [
              if (_attempt != null)
                PopupMenuItem(
                  key: const ValueKey<String>('pressure-menu-replay'),
                  value: _replayAttempt,
                  child: Text(l10n.pressureLessonReplayMine),
                ),
              if (_attempt != null)
                PopupMenuItem(
                  key: const ValueKey<String>('pressure-menu-reference'),
                  value: () => unawaited(_openReference()),
                  child: Text(l10n.pressureLessonReference),
                ),
              for (var index = 0;
                  index < PressureLessonCatalog.situationCount;
                  index++)
                PopupMenuItem(
                  key: ValueKey<String>('pressure-menu-situation-${index + 1}'),
                  value: () => _openSituation(index),
                  child: Text(l10n.pressureLessonSituationMenu(index + 1)),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _motion,
          builder: (context, _) => _buildBody(l10n, colors),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, _ScanPassColors colors) {
    return LayoutBuilder(builder: (context, constraints) {
      final landscape = constraints.maxWidth > constraints.maxHeight * 1.25;
      final field = _buildField(l10n, colors, portrait: !landscape);
      final panel = _buildPanel(l10n, colors);
      if (landscape) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(child: field),
            const SizedBox(width: 8),
            SizedBox(
              width: math.min(350, constraints.maxWidth * .38),
              child: panel,
            ),
          ]),
        );
      }
      final panelHeight = math.min(230.0, constraints.maxHeight * .34);
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        child: Column(children: [
          Expanded(child: field),
          const SizedBox(height: 8),
          SizedBox(height: panelHeight, child: panel),
        ]),
      );
    });
  }

  Widget _buildField(
    AppLocalizations l10n,
    _ScanPassColors colors, {
    required bool portrait,
  }) {
    final trace = _activeTrace;
    final displayed = trace?.frameAt(_motion.value) ?? _current;
    final reviewResult =
        _showingAlternative ? _alternativeResult : _attempt?.terminal;
    return RepaintBoundary(
      key: const ValueKey<String>('pressure-lesson-capture'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildHeader(l10n, colors),
        const SizedBox(height: 6),
        Expanded(
          child: Semantics(
            image: true,
            label: l10n.pressureLessonGoal,
            child: Stack(fit: StackFit.expand, children: [
              CustomPaint(
                key: const ValueKey<String>('pressure-pitch'),
                painter: _PressureLessonPitchPainter(
                  displayWorld: displayed,
                  portrait: portrait,
                  completedTraces: _completedTraces,
                  activeTrace: trace,
                  activeProgress: _motion.value,
                  reviewResult: _phase == _PressureLessonPhase.review
                      ? reviewResult
                      : null,
                  l10n: l10n,
                  names: _pressureNames(l10n),
                  brightness: Theme.of(context).brightness,
                  fontFamily:
                      Theme.of(context).textTheme.bodyMedium?.fontFamily,
                  viewBounds: _viewBounds,
                ),
              ),
              if (_isChoosing)
                _buildChoiceLayer(displayed, portrait: portrait, l10n: l10n),
              if (_isMoving)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 9,
                  child: LinearProgressIndicator(
                    key: const ValueKey<String>('pressure-motion-progress'),
                    minHeight: 3,
                    value: _motion.value,
                    color: colors.accent,
                    backgroundColor: colors.line.withValues(alpha: .45),
                  ),
                ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, _ScanPassColors colors) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.pressureLessonGoal,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.pressureLessonSyntheticNote,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.muted,
                        fontSize: 10.5,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.active,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              child: Text(
                l10n.pressureLessonProgress(
                  _situationIndex + 1,
                  PressureLessonCatalog.situationCount,
                ),
                key: const ValueKey<String>('pressure-progress'),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildChoiceLayer(
    PressureWorld world, {
    required bool portrait,
    required AppLocalizations l10n,
  }) {
    return Positioned.fill(
      child: LayoutBuilder(builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final geometry = _MatchPitchGeometry(
          size,
          portrait: portrait,
          viewBounds: _viewBounds,
        );
        final source = geometry.toOffset(_normalise(world.ball.position));
        final controls = _pressureChoiceTargets(
          geometry,
          source,
          size,
          world,
          _options,
        );
        return Stack(children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                key: const ValueKey<String>('pressure-choice-paths'),
                painter: _PressureChoicePainter(
                  source: source,
                  targets: controls,
                  brightness: Theme.of(context).brightness,
                ),
              ),
            ),
          ),
          for (final target in controls)
            Positioned(
              left: target.controlCenter.dx - target.controlSize.width / 2,
              top: target.controlCenter.dy - target.controlSize.height / 2,
              width: target.controlSize.width,
              height: target.controlSize.height,
              child: Semantics(
                button: true,
                label: l10n.pressureLessonChoiceSemantics(
                    _optionLabel(l10n, target.option, world)),
                child: Material(
                  color: Theme.of(context).colorScheme.surface.withValues(
                      alpha:
                          target.option.action.kind == PressureActionKind.pass
                              ? .34
                              : .94),
                  shape: target.option.action.kind == PressureActionKind.pass
                      ? CircleBorder(
                          side: BorderSide(
                              color: _ScanPassColors.of(context).text),
                        )
                      : RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                              color: _ScanPassColors.of(context).text),
                        ),
                  child: InkWell(
                    key: ValueKey<String>(
                        'pressure-action-${target.option.key}'),
                    customBorder:
                        target.option.action.kind == PressureActionKind.pass
                            ? const CircleBorder()
                            : RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                    onTap: () => _choose(target.option),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          target.option.action.kind == PressureActionKind.pass
                              ? _optionIcon(target.option.kind)
                              : _projectedDirectionIcon(
                                  target.endpoint - source),
                          size: target.option.action.kind ==
                                  PressureActionKind.pass
                              ? 19
                              : 16,
                        ),
                        if (target.option.action.kind !=
                            PressureActionKind.pass)
                          Text(
                            target.option.action.kind ==
                                    PressureActionKind.firstTouch
                                ? l10n.pressureLessonTouchMarker
                                : l10n.pressureLessonCarryMarker,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        Text(
                          _optionMarker(l10n, target.option, world),
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ]);
      }),
    );
  }

  IconData _projectedDirectionIcon(Offset delta) {
    final angle = math.atan2(delta.dy, delta.dx);
    if (angle >= -math.pi / 8 && angle < math.pi / 8) {
      return Icons.arrow_forward;
    }
    if (angle >= math.pi / 8 && angle < 3 * math.pi / 8) {
      return Icons.south_east;
    }
    if (angle >= 3 * math.pi / 8 && angle < 5 * math.pi / 8) {
      return Icons.arrow_downward;
    }
    if (angle >= 5 * math.pi / 8 && angle < 7 * math.pi / 8) {
      return Icons.south_west;
    }
    if (angle >= -3 * math.pi / 8 && angle < -math.pi / 8) {
      return Icons.north_east;
    }
    if (angle >= -5 * math.pi / 8 && angle < -3 * math.pi / 8) {
      return Icons.arrow_upward;
    }
    if (angle >= -7 * math.pi / 8 && angle < -5 * math.pi / 8) {
      return Icons.north_west;
    }
    return Icons.arrow_back;
  }

  Widget _buildPanel(AppLocalizations l10n, _ScanPassColors colors) {
    final compact = _phase != _PressureLessonPhase.review &&
        _phase != _PressureLessonPhase.summary;
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: switch (_phase) {
          _PressureLessonPhase.review => _buildReview(l10n, colors),
          _PressureLessonPhase.summary => _buildSummary(l10n, colors),
          _ => _buildInstruction(l10n, colors),
        },
      ),
    );
    return compact
        ? Align(alignment: Alignment.topCenter, child: panel)
        : panel;
  }

  Widget _buildInstruction(AppLocalizations l10n, _ScanPassColors colors) {
    final title = switch (_phase) {
      _PressureLessonPhase.observing => l10n.pressureLessonObserve,
      _PressureLessonPhase.firstDecision => l10n.pressureLessonChooseFirst,
      _PressureLessonPhase.nextDecision => l10n.pressureLessonChooseNext,
      _PressureLessonPhase.executing => switch (_playback) {
          _PressurePlayback.alternative => l10n.pressureLessonAlternativeView,
          _PressurePlayback.replay => l10n.pressureLessonReplayView,
          _ => l10n.pressureLessonExecuting,
        },
      _ => l10n.pressureLessonGoal,
    };
    return Column(
      key: ValueKey<String>('pressure-phase-${_phase.name}'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          _isMoving ? Icons.visibility_outlined : Icons.touch_app_outlined,
          color: colors.accent,
          size: 22,
        ),
        const SizedBox(height: 7),
        Text(
          title,
          key: const ValueKey<String>('pressure-instruction'),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w900,
                height: 1.12,
              ),
        ),
        const SizedBox(height: 7),
        Text(
          _isChoosing
              ? l10n.pressureLessonOneTapHint
              : l10n.pressureLessonSyntheticNote,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.muted,
                height: 1.22,
              ),
        ),
      ],
    );
  }

  Widget _buildReview(AppLocalizations l10n, _ScanPassColors colors) {
    final result =
        _showingAlternative ? _alternativeResult! : _attempt!.terminal;
    return Column(
      key: const ValueKey<String>('pressure-review-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _showingAlternative
              ? l10n.pressureLessonAlternative
              : l10n.pressureLessonMyAttempt,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 5),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _reviewLine(
                  key: 'pressure-review-observed',
                  icon: Icons.visibility_outlined,
                  text: _observedLine(l10n, result),
                  colors: colors,
                ),
                _reviewLine(
                  key: 'pressure-review-effect',
                  icon: Icons.call_split_outlined,
                  text: _effectLine(l10n, result),
                  colors: colors,
                ),
                if (!_showingAlternative && _alternativeResult != null)
                  _reviewLine(
                    key: 'pressure-review-alternative',
                    icon: Icons.compare_arrows_outlined,
                    text: _alternativeLine(l10n),
                    colors: colors,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              key: ValueKey<String>(_showingAlternative
                  ? 'pressure-return-attempt'
                  : 'pressure-retry'),
              onPressed:
                  _showingAlternative ? _returnToAttempt : _retryLastDecision,
              child: Text(_showingAlternative
                  ? l10n.pressureLessonReturnMine
                  : l10n.pressureLessonRetry),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: FilledButton(
              key: ValueKey<String>(_showingAlternative
                  ? 'pressure-return-next'
                  : 'pressure-next'),
              onPressed:
                  _showingAlternative ? _returnToAttempt : _nextSituation,
              child: Text(_showingAlternative
                  ? l10n.pressureLessonReturnMine
                  : _situationIndex == PressureLessonCatalog.situationCount - 1
                      ? l10n.pressureLessonFinish
                      : l10n.pressureLessonNext),
            ),
          ),
          if (!_showingAlternative && _alternativeResult != null) ...[
            const SizedBox(width: 4),
            AppBarActionButton.icon(
              key: const ValueKey<String>('pressure-compare'),
              icon: Icons.compare_arrows_outlined,
              tooltip: l10n.pressureLessonCompare,
              onPressed: _playAlternative,
              compact: true,
              margin: EdgeInsets.zero,
            ),
          ],
        ]),
      ],
    );
  }

  Widget _reviewLine({
    required String key,
    required IconData icon,
    required String text,
    required _ScanPassColors colors,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: colors.accent, size: 15),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            key: ValueKey<String>(key),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.text,
                  height: 1.18,
                ),
          ),
        ),
      ]),
    );
  }

  Widget _buildSummary(AppLocalizations l10n, _ScanPassColors colors) {
    final attempts = _session.firstAttempts.length;
    final focusPressure =
        _session.retainedFirstAttempts < math.max(1, attempts ~/ 2);
    return SingleChildScrollView(
      key: const ValueKey<String>('pressure-summary'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.fact_check_outlined, color: colors.accent, size: 28),
          const SizedBox(height: 7),
          Text(
            l10n.pressureLessonSummaryTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 7),
          Text(l10n.pressureLessonSummaryCoverage),
          const SizedBox(height: 5),
          Text(l10n.pressureLessonSummaryConnections(
              _session.openedConnections, attempts)),
          const SizedBox(height: 5),
          Text(focusPressure
              ? l10n.pressureLessonSummaryFocusPressure
              : l10n.pressureLessonSummaryFocusConnection),
          const SizedBox(height: 10),
          FilledButton(
            key: const ValueKey<String>('pressure-restart'),
            onPressed: _restartLesson,
            child: Text(l10n.pressureLessonRestart),
          ),
        ],
      ),
    );
  }

  String _observedLine(AppLocalizations l10n, PressureSimulationResult result) {
    final snapshot = result.before;
    final carrier = snapshot.carrier!;
    final defender =
        snapshot.actorByRole(_pressureRelevantDefenderRole(result));
    if (result.action.kind == PressureActionKind.pass) {
      final laneDistance = _pressureDistanceToSegment(
        defender.position,
        snapshot.ball.position,
        result.action.target,
      ).toStringAsFixed(1);
      final lanePoint = _pressureClosestPointOnSegment(
        defender.position,
        snapshot.ball.position,
        result.action.target,
      );
      final towardLane = lanePoint - defender.position;
      final closing = towardLane.distance > .01 &&
          defender.velocity.dot(towardLane * (1 / towardLane.distance)) > .15;
      return closing
          ? l10n.pressureLessonObservedLaneClosing(
              defender.number, laneDistance)
          : l10n.pressureLessonObservedLaneHolding(
              defender.number, laneDistance);
    }
    final distance =
        carrier.position.distanceTo(defender.position).toStringAsFixed(1);
    final lateral = defender.position.y - carrier.position.y;
    if (lateral < -1) {
      return l10n.pressureLessonObservedOutside(defender.number, distance);
    }
    if (lateral > 1) {
      return l10n.pressureLessonObservedInside(defender.number, distance);
    }
    return l10n.pressureLessonObservedLevel(defender.number, distance);
  }

  String _effectLine(AppLocalizations l10n, PressureSimulationResult result) {
    if (result.offside) {
      final role = result.intendedReceiverRole!;
      return l10n.pressureLessonEffectOffside(
        result.before.actorByRole(role).number,
      );
    }
    final contact = result.contact;
    if (contact != null &&
        result.after.possession == PressurePossession.defense) {
      return l10n.pressureLessonEffectLost(
        contact.defenderNumber,
        (contact.clock - result.before.clock).toStringAsFixed(1),
      );
    }
    if (result.after.possession == PressurePossession.loose) {
      return l10n.pressureLessonEffectLoose;
    }
    if (result.assessment.missedForwardOpportunity) {
      return l10n.pressureLessonEffectMissed;
    }
    final carrier = result.after.carrier;
    if (result.action.kind == PressureActionKind.pass &&
        carrier != null &&
        carrier.team == PressureTeam.attack &&
        result.assessment.actionProgressMetres >= 1.5) {
      return l10n.pressureLessonEffectForwardPass(
        carrier.number,
        result.assessment.pressureClearanceMetres.toStringAsFixed(1),
      );
    }
    final connection = result.assessment.connections
        .where((value) => value.safe && value.forward)
        .cast<PressureConnectionEvidence?>()
        .firstOrNull;
    if (connection != null) {
      return l10n.pressureLessonEffectConnection(
        result.after.actorByRole(connection.receiverRole).number,
        result.assessment.pressureClearanceMetres.toStringAsFixed(1),
      );
    }
    return l10n.pressureLessonEffectRetained(
      result.assessment.pressureClearanceMetres.toStringAsFixed(1),
      result.assessment.availableTimeSeconds.toStringAsFixed(1),
    );
  }

  String _alternativeLine(AppLocalizations l10n) {
    final result = _alternativeResult!;
    final option = _alternativeOption!;
    final action = _optionLabel(l10n, option, result.before);
    if (result.offside) {
      return l10n.pressureLessonAlternativeOffside(action);
    }
    if (result.after.possession == PressurePossession.defense) {
      return l10n.pressureLessonAlternativeLost(
          action, result.contact!.defenderNumber);
    }
    if (result.after.possession == PressurePossession.loose) {
      return l10n.pressureLessonAlternativeLoose(action);
    }
    final connection = result.assessment.connections
        .where((value) => value.safe && value.forward)
        .cast<PressureConnectionEvidence?>()
        .firstOrNull;
    if (connection != null) {
      return l10n.pressureLessonAlternativeConnection(
          action, result.after.actorByRole(connection.receiverRole).number);
    }
    if (result.assessment.pressureClearanceMetres >
        _attempt!.terminal.assessment.pressureClearanceMetres + .2) {
      return l10n.pressureLessonAlternativeClearance(
        action,
        result.assessment.pressureClearanceMetres.toStringAsFixed(1),
      );
    }
    return l10n.pressureLessonAlternativeSimilar(action);
  }

  String _optionLabel(
    AppLocalizations l10n,
    PressureDecisionOption option,
    PressureWorld world,
  ) {
    final number = _targetNumber(option, world);
    return switch (option.kind) {
      PressureOptionKind.touchInside => l10n.pressureLessonTouchInside,
      PressureOptionKind.touchOutside => l10n.pressureLessonTouchOutside,
      PressureOptionKind.immediatePass => l10n.pressureLessonPassNow(number),
      PressureOptionKind.immediateRunnerPass =>
        l10n.pressureLessonPassRunner(number),
      PressureOptionKind.immediateBackPass =>
        l10n.pressureLessonPassBack(number),
      PressureOptionKind.passSupport => l10n.pressureLessonPassSupport(number),
      PressureOptionKind.passRunner => l10n.pressureLessonPassRunner(number),
      PressureOptionKind.carryForward => l10n.pressureLessonCarryForward,
    };
  }

  int _targetNumber(PressureDecisionOption option, PressureWorld world) {
    final role = switch (option.kind) {
      PressureOptionKind.immediatePass ||
      PressureOptionKind.passSupport =>
        PressureActorRole.support,
      PressureOptionKind.immediateRunnerPass ||
      PressureOptionKind.passRunner =>
        PressureActorRole.runner,
      PressureOptionKind.immediateBackPass => PressureActorRole.passer,
      _ => PressureActorRole.receiver,
    };
    return world.actorByRole(role).number;
  }

  String _optionMarker(AppLocalizations l10n, PressureDecisionOption option,
      PressureWorld world) {
    if (option.action.kind == PressureActionKind.pass) {
      return l10n.pressureLessonPlayerMarker(_targetNumber(option, world));
    }
    return l10n.pressureLessonApproxMetres(
      world.ball.position.distanceTo(option.action.target).toStringAsFixed(1),
    );
  }

  IconData _optionIcon(PressureOptionKind kind) => switch (kind) {
        PressureOptionKind.touchInside ||
        PressureOptionKind.touchOutside =>
          Icons.touch_app_outlined,
        PressureOptionKind.immediatePass ||
        PressureOptionKind.immediateRunnerPass ||
        PressureOptionKind.immediateBackPass ||
        PressureOptionKind.passSupport ||
        PressureOptionKind.passRunner =>
          Icons.sports_soccer,
        PressureOptionKind.carryForward => Icons.arrow_forward,
      };

  Map<String, String> _pressureNames(AppLocalizations l10n) => {
        MatchMomentEpisode.spain2: l10n.matchMomentPlayerDaniCarvajal,
        MatchMomentEpisode.spain10: l10n.matchMomentPlayerDaniOlmo,
        MatchMomentEpisode.spain17: l10n.matchMomentPlayerNicoWilliams,
        MatchMomentEpisode.spain19: l10n.matchMomentPlayerLamineYamal,
        MatchMomentEpisode.england3: l10n.matchMomentPlayerLukeShaw,
        MatchMomentEpisode.england4: l10n.matchMomentPlayerDeclanRice,
        MatchMomentEpisode.england5: l10n.matchMomentPlayerJohnStones,
      };
}

List<_PressureChoiceTarget> _pressureChoiceTargets(
  _MatchPitchGeometry geometry,
  Offset source,
  Size size,
  PressureWorld world,
  List<PressureDecisionOption> options,
) {
  final values = <_PressureChoiceTarget>[];
  final used = <Rect>[];
  final occupied = <Rect>[
    for (final actor in world.actors)
      Rect.fromCenter(
        center:
            geometry.toOffset(_normalise(actor.position)) - const Offset(0, 5),
        width: 44,
        height: 56,
      ),
  ];
  for (var index = 0; index < options.length; index++) {
    final option = options[index];
    final endpoint = geometry.toOffset(_normalise(option.action.target));
    final controlSize = option.action.kind == PressureActionKind.pass
        ? const Size(52, 52)
        : const Size(72, 56);
    final delta = endpoint - source;
    final direction =
        delta.distance < .01 ? const Offset(1, 0) : delta / delta.distance;
    final normal = Offset(-direction.dy, direction.dx);
    final candidates = option.action.kind == PressureActionKind.pass
        ? <Offset>[
            endpoint + normal * 42,
            endpoint - normal * 42,
            endpoint + direction * 44,
            endpoint - direction * 44,
            endpoint + normal * 64,
            endpoint - normal * 64,
            endpoint + normal * 52 + direction * 42,
            endpoint - normal * 52 + direction * 42,
            endpoint + normal * 52 - direction * 42,
            endpoint - normal * 52 - direction * 42,
          ]
        : index.isEven
            ? <Offset>[
                source + const Offset(-82, -54),
                source + const Offset(-88, 54),
                source + const Offset(0, -82),
                source + const Offset(0, 82),
                source + const Offset(-124, 0),
                source + const Offset(124, 0),
                source + const Offset(-112, -80),
                source + const Offset(112, 80),
              ]
            : <Offset>[
                source + const Offset(82, 54),
                source + const Offset(88, -54),
                source + const Offset(0, 82),
                source + const Offset(0, -82),
                source + const Offset(124, 0),
                source + const Offset(-124, 0),
                source + const Offset(112, -80),
                source + const Offset(-112, 80),
              ];
    Offset clampCenter(Offset candidate) => Offset(
          candidate.dx
              .clamp(controlSize.width / 2, size.width - controlSize.width / 2)
              .toDouble(),
          candidate.dy
              .clamp(
                  controlSize.height / 2, size.height - controlSize.height / 2)
              .toDouble(),
        );
    var center = clampCenter(candidates.first);
    var rect = Rect.fromCenter(
        center: center, width: controlSize.width, height: controlSize.height);
    var placed = false;
    for (final candidate in candidates) {
      final proposedCenter = clampCenter(candidate);
      final proposed = Rect.fromCenter(
          center: proposedCenter,
          width: controlSize.width,
          height: controlSize.height);
      final overlapsControl =
          used.any((other) => other.inflate(5).overlaps(proposed));
      final overlapsActor =
          occupied.any((other) => other.inflate(3).overlaps(proposed));
      if (!overlapsControl && !overlapsActor) {
        center = proposedCenter;
        rect = proposed;
        placed = true;
        break;
      }
    }
    if (!placed) {
      for (final candidate in candidates) {
        final proposedCenter = clampCenter(candidate);
        final proposed = Rect.fromCenter(
            center: proposedCenter,
            width: controlSize.width,
            height: controlSize.height);
        if (!used.any((other) => other.inflate(5).overlaps(proposed))) {
          center = proposedCenter;
          rect = proposed;
          break;
        }
      }
    }
    used.add(rect);
    values.add(_PressureChoiceTarget(
      option: option,
      endpoint: endpoint,
      controlCenter: center,
      controlSize: controlSize,
    ));
  }
  return List.unmodifiable(values);
}

class _PressureChoiceTarget {
  final PressureDecisionOption option;
  final Offset endpoint;
  final Offset controlCenter;
  final Size controlSize;

  const _PressureChoiceTarget({
    required this.option,
    required this.endpoint,
    required this.controlCenter,
    required this.controlSize,
  });
}

class _PressureChoicePainter extends CustomPainter {
  final Offset source;
  final List<_PressureChoiceTarget> targets;
  final Brightness brightness;

  const _PressureChoicePainter({
    required this.source,
    required this.targets,
    required this.brightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final color = brightness == Brightness.dark
        ? const Color(0xFFE9EEEB)
        : const Color(0xFF263A3D);
    for (final target in targets) {
      final paint = Paint()
        ..color = color.withValues(alpha: .72)
        ..style = PaintingStyle.stroke
        ..strokeWidth =
            target.option.action.kind == PressureActionKind.pass ? 1.6 : 2.0
        ..strokeCap = StrokeCap.round;
      if (target.option.action.kind == PressureActionKind.pass) {
        _pressureDrawDashedLine(canvas, source, target.endpoint, paint,
            dash: 7, gap: 5);
      } else {
        canvas.drawLine(source, target.endpoint, paint);
      }
      _pressureDrawArrowHead(canvas, source, target.endpoint, paint);
      canvas.drawCircle(
        target.endpoint,
        5,
        Paint()
          ..color = color.withValues(alpha: .88)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      if ((target.controlCenter - target.endpoint).distance > 10) {
        _pressureDrawDashedLine(
          canvas,
          target.endpoint,
          target.controlCenter,
          paint..color = color.withValues(alpha: .42),
          dash: 3,
          gap: 3,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PressureChoicePainter oldDelegate) =>
      oldDelegate.source != source ||
      oldDelegate.targets != targets ||
      oldDelegate.brightness != brightness;
}

class _PressureLessonPitchPainter extends CustomPainter {
  final PressureWorld displayWorld;
  final bool portrait;
  final List<PressureTrace> completedTraces;
  final PressureTrace? activeTrace;
  final double activeProgress;
  final PressureSimulationResult? reviewResult;
  final AppLocalizations l10n;
  final Map<String, String> names;
  final Brightness brightness;
  final String? fontFamily;
  final Rect viewBounds;

  const _PressureLessonPitchPainter({
    required this.displayWorld,
    required this.portrait,
    required this.completedTraces,
    required this.activeTrace,
    required this.activeProgress,
    required this.reviewResult,
    required this.l10n,
    required this.names,
    required this.brightness,
    required this.fontFamily,
    required this.viewBounds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const episode = MatchMomentEpisode();
    final delegate = _MatchMomentPitchPainter(
      episode: episode,
      portrait: portrait,
      frame: _matchFrame(displayWorld),
      completedSegments: const [],
      activeSegment: null,
      activeSegmentProgress: 0,
      names: names,
      reference: false,
      brightness: brightness,
      fontFamily: fontFamily,
      viewBounds: viewBounds,
    );
    delegate.paint(canvas, size);
    final geometry = _MatchPitchGeometry(
      size,
      portrait: portrait,
      viewBounds: viewBounds,
    );
    _drawOffsideReference(canvas, geometry);
    for (final trace in completedTraces) {
      _drawTrace(canvas, geometry, trace, 1, active: false);
    }
    final active = activeTrace;
    if (active != null) {
      _drawTrace(canvas, geometry, active, activeProgress, active: true);
    }
    final review = reviewResult;
    if (review != null) _drawReview(canvas, geometry, review);
  }

  void _drawOffsideReference(
    Canvas canvas,
    _MatchPitchGeometry geometry,
  ) {
    final reference =
        const ScanPassPressureEngine().offsideReferenceX(displayWorld);
    final from = geometry.toOffset(_normalise(
      ScanPassPoint(
        reference,
        ScanPassPressureEngine.fieldWidthMetres * geometry.minY,
      ),
    ));
    final to = geometry.toOffset(_normalise(
      ScanPassPoint(
        reference,
        ScanPassPressureEngine.fieldWidthMetres * geometry.maxY,
      ),
    ));
    final color = (brightness == Brightness.dark
            ? const Color(0xFFD1D7D4)
            : const Color(0xFF5B6965))
        .withValues(alpha: .43);
    _pressureDrawDashedLine(
      canvas,
      from,
      to,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
      dash: 5,
      gap: 5,
    );
    final label = TextPainter(
      text: TextSpan(
        text: l10n.pressureLessonOffsideLine,
        style: TextStyle(
          color: color.withValues(alpha: .9),
          fontFamily: fontFamily,
          fontSize: 8,
          fontWeight: FontWeight.w600,
          backgroundColor: (brightness == Brightness.dark
                  ? const Color(0xFF162526)
                  : const Color(0xFFF7F8F6))
              .withValues(alpha: .72),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: math.max(70, geometry.size.width * .28));
    final midpoint = Offset.lerp(from, to, .5)!;
    final offset = geometry.vertical
        ? Offset(
            (midpoint.dx - label.width / 2)
                .clamp(4.0, geometry.size.width - label.width - 4),
            (midpoint.dy + 4)
                .clamp(4.0, geometry.size.height - label.height - 4),
          )
        : Offset(
            (midpoint.dx + 4).clamp(4.0, geometry.size.width - label.width - 4),
            (midpoint.dy - label.height / 2)
                .clamp(4.0, geometry.size.height - label.height - 4),
          );
    label.paint(canvas, offset);
  }

  void _drawTrace(
    Canvas canvas,
    _MatchPitchGeometry geometry,
    PressureTrace trace,
    double progress, {
    required bool active,
  }) {
    final clippedProgress = progress.clamp(0.0, 1.0).toDouble();
    if (clippedProgress <= 0) return;
    final targetClock = trace.first.clock + trace.duration * clippedProgress;
    final frames = trace.frames
        .where((frame) => frame.clock <= targetClock + 1e-9)
        .toList();
    final displayed = trace.frameAt(clippedProgress);
    if (frames.isEmpty ||
        frames.last.clock < displayed.clock - 1e-9 ||
        frames.last.ball.position.distanceTo(displayed.ball.position) > 1e-6) {
      frames.add(displayed);
    }
    if (frames.length < 2) return;
    final passTrace = trace.frames.any((frame) => frame.ball.inFlight);
    final ballPaint = Paint()
      ..color = (brightness == Brightness.dark
              ? const Color(0xFFFFD166)
              : const Color(0xFF795B20))
          .withValues(alpha: active ? .88 : .27)
      ..style = PaintingStyle.stroke
      ..strokeWidth = active ? 2.5 : 1.3
      ..strokeCap = StrokeCap.round;
    final ballPoints = frames
        .map((frame) => geometry.toOffset(_normalise(frame.ball.position)))
        .toList();
    if (passTrace) {
      _pressureDrawDashedPolyline(canvas, ballPoints, ballPaint,
          dash: 7, gap: 4);
    } else {
      _pressureDrawPolyline(canvas, ballPoints, ballPaint);
    }
    _pressureDrawArrowHead(
        canvas, _pressureArrowStart(ballPoints), ballPoints.last, ballPaint);
    canvas.drawCircle(
      ballPoints.last,
      active && !passTrace ? 4.5 : 3.2,
      Paint()
        ..color = ballPaint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    if (active && !passTrace && ballPoints.length > 1) {
      final movement = ballPoints.last - ballPoints.first;
      if (movement.distance > .5) {
        final unit = movement / movement.distance;
        final normal = Offset(-unit.dy, unit.dx);
        final sign = ballPoints.first.dx < geometry.size.width / 2 ? 1.0 : -1.0;
        final side = normal * 30 * sign;
        final leader = Paint()
          ..color = ballPaint.color.withValues(alpha: .55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        _pressureDrawDashedLine(
            canvas, ballPoints.first, ballPoints.first + side, leader,
            dash: 3, gap: 3);
        _pressureDrawDashedLine(
            canvas, ballPoints.last, ballPoints.last + side, leader,
            dash: 3, gap: 3);
        canvas.drawLine(
            ballPoints.first + side, ballPoints.last + side, ballPaint);
        _pressureDrawArrowHead(
            canvas, ballPoints.first + side, ballPoints.last + side, ballPaint);
      }
    }
    for (final role in const [
      PressureActorRole.receiver,
      PressureActorRole.support,
      PressureActorRole.runner,
      PressureActorRole.passer,
    ]) {
      final points = frames
          .map((frame) =>
              geometry.toOffset(_normalise(frame.actorByRole(role).position)))
          .toList();
      final paint = Paint()
        ..color = (brightness == Brightness.dark
                ? const Color(0xFF8EC5FF)
                : const Color(0xFF315F78))
            .withValues(alpha: active ? .42 : .13)
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? 1.2 : .8;
      _pressureDrawDashedPolyline(canvas, points, paint, dash: 4, gap: 4);
      _pressureDrawArrowHead(
          canvas, _pressureArrowStart(points), points.last, paint);
    }
    for (final role in const [
      PressureActorRole.presser,
      PressureActorRole.cover,
      PressureActorRole.tracker,
    ]) {
      final points = frames
          .map((frame) =>
              geometry.toOffset(_normalise(frame.actorByRole(role).position)))
          .toList();
      final paint = Paint()
        ..color = (brightness == Brightness.dark
                ? const Color(0xFFFF9F6E)
                : const Color(0xFF9D4F32))
            .withValues(alpha: active ? .58 : .18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? 1.5 : .9;
      _pressureDrawDashedPolyline(canvas, points, paint, dash: 5, gap: 4);
      _pressureDrawArrowHead(
          canvas, _pressureArrowStart(points), points.last, paint);
    }
    if (active && passTrace && ballPoints.length > 1) {
      var metres = 0.0;
      for (var index = 1; index < frames.length; index++) {
        metres += frames[index - 1]
            .ball
            .position
            .distanceTo(frames[index].ball.position);
      }
      final caption = TextPainter(
        text: TextSpan(
          text: l10n.pressureLessonTracePass(metres.toStringAsFixed(1)),
          style: TextStyle(
            color: brightness == Brightness.dark
                ? const Color(0xFFF5F7F5)
                : const Color(0xFF1C2C2F),
            fontFamily: fontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            backgroundColor: (brightness == Brightness.dark
                    ? const Color(0xFF223033)
                    : const Color(0xFFF7F8F6))
                .withValues(alpha: .78),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 130);
      final anchor = ballPoints[ballPoints.length ~/ 2];
      final actorRects = <Rect>[
        for (final actor in displayWorld.actors)
          Rect.fromCenter(
            center: geometry.toOffset(_normalise(actor.position)),
            width: 42,
            height: 48,
          ),
      ];
      final candidates = <Offset>[
        anchor + const Offset(10, -34),
        anchor + const Offset(10, 18),
        anchor - Offset(caption.width + 10, 34),
        anchor - Offset(caption.width + 10, -18),
      ];
      var captionOffset = candidates.first;
      for (final candidate in candidates) {
        final clamped = Offset(
          candidate.dx.clamp(4.0, geometry.size.width - caption.width - 4),
          candidate.dy.clamp(4.0, geometry.size.height - caption.height - 4),
        );
        final rect = clamped & caption.size;
        if (!actorRects.any((actor) => actor.overlaps(rect))) {
          captionOffset = clamped;
          break;
        }
      }
      caption.paint(canvas, captionOffset);
    }
  }

  void _drawReview(
    Canvas canvas,
    _MatchPitchGeometry geometry,
    PressureSimulationResult result,
  ) {
    final assessment = result.assessment;
    final relevantRole = _pressureRelevantDefenderRole(result);
    PressureActor? defender;
    for (final actor in result.after.team(PressureTeam.defense)) {
      if (actor.role == relevantRole) defender = actor;
    }
    if (defender != null) {
      final center = geometry.toOffset(_normalise(defender.position));
      canvas.drawCircle(
        center,
        21,
        Paint()
          ..color = const Color(0xFFB15F49).withValues(alpha: .55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }
    final carrier = result.after.carrier;
    final connection = assessment.connections
        .where((value) => value.safe)
        .cast<PressureConnectionEvidence?>()
        .firstOrNull;
    if (carrier == null || connection == null) return;
    final from = geometry.toOffset(_normalise(carrier.position));
    final to = geometry.toOffset(_normalise(connection.target));
    final paint = Paint()
      ..color = (brightness == Brightness.dark
              ? const Color(0xFF8EC5FF)
              : const Color(0xFF315F78))
          .withValues(alpha: .70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    _pressureDrawDashedLine(canvas, from, to, paint, dash: 7, gap: 5);
    _pressureDrawArrowHead(canvas, from, to, paint);
  }

  @override
  bool shouldRepaint(covariant _PressureLessonPitchPainter oldDelegate) =>
      oldDelegate.displayWorld != displayWorld ||
      oldDelegate.portrait != portrait ||
      oldDelegate.completedTraces != completedTraces ||
      oldDelegate.activeTrace != activeTrace ||
      oldDelegate.activeProgress != activeProgress ||
      oldDelegate.reviewResult != reviewResult ||
      oldDelegate.l10n != l10n ||
      oldDelegate.viewBounds != viewBounds ||
      oldDelegate.brightness != brightness ||
      oldDelegate.fontFamily != fontFamily;
}

MatchMomentFrame _matchFrame(PressureWorld world) => MatchMomentFrame(
      actors: Map.unmodifiable({
        for (final actor in world.actors)
          actor.id: MatchMomentActorState(
            position: _normalise(actor.position),
            facingRadians: actor.velocity.distance < .05
                ? 0
                : math.atan2(actor.velocity.y, actor.velocity.x),
          ),
      }),
      ball: _normalise(world.ball.position),
      carrierId: world.ball.carrierId,
      elapsed: world.clock,
    );

PressureActorRole _pressureRelevantDefenderRole(
    PressureSimulationResult result) {
  final contact = result.contact;
  if (contact != null) {
    for (final defender in result.before.team(PressureTeam.defense)) {
      if (defender.id == contact.defenderId) return defender.role;
    }
  }
  if (result.action.kind == PressureActionKind.pass) {
    final start = result.before.ball.position;
    final length = start.distanceTo(result.action.target);
    PressureActorRole? closestRole;
    var closest = double.infinity;
    for (final frame in result.trace.frames) {
      if (!frame.ball.inFlight ||
          frame.ball.position.distanceTo(start) < length * .15) {
        continue;
      }
      for (final defender in frame.team(PressureTeam.defense)) {
        final distance = defender.position.distanceTo(frame.ball.position);
        if (distance < closest) {
          closest = distance;
          closestRole = defender.role;
        }
      }
    }
    if (closestRole != null) return closestRole;
  }
  return result.assessment.nearestDefenderRole;
}

ScanPassPoint _pressureClosestPointOnSegment(
  ScanPassPoint point,
  ScanPassPoint start,
  ScanPassPoint end,
) {
  final segment = end - start;
  final squared = segment.dot(segment);
  final fraction = squared <= 1e-10
      ? 0.0
      : ((point - start).dot(segment) / squared).clamp(0.0, 1.0).toDouble();
  return start + segment * fraction;
}

double _pressureDistanceToSegment(
  ScanPassPoint point,
  ScanPassPoint start,
  ScanPassPoint end,
) =>
    point.distanceTo(_pressureClosestPointOnSegment(point, start, end));

ScanPassPoint _normalise(ScanPassPoint metres) => ScanPassPoint(
      metres.x / ScanPassPressureEngine.fieldLengthMetres,
      metres.y / ScanPassPressureEngine.fieldWidthMetres,
    );

Rect _pressureViewBounds(PressureObservation observation) {
  var minX = double.infinity;
  var maxX = double.negativeInfinity;
  var minY = double.infinity;
  var maxY = double.negativeInfinity;

  void include(ScanPassPoint point) {
    minX = math.min(minX, point.x);
    maxX = math.max(maxX, point.x);
    minY = math.min(minY, point.y);
    maxY = math.max(maxY, point.y);
  }

  for (final frame in observation.trace.frames) {
    include(frame.ball.position);
    for (final actor in frame.actors) {
      include(actor.position);
    }
  }
  final decision = observation.decisionState;
  for (final actor in decision.actors) {
    include(actor.position);
    include(actor.position + actor.velocity * 2.75);
  }
  const engine = ScanPassPressureEngine();
  for (final option
      in engine.optionsFor(decision, PressureDecisionStage.firstContact)) {
    include(option.action.target);
  }
  include(ScanPassPoint(
    engine.offsideReferenceX(decision),
    decision.ball.position.y,
  ));

  ({double min, double max}) fit(
    double minimum,
    double maximum,
    double padding,
    double minimumSpan,
    double fieldMaximum,
  ) {
    var lower = minimum - padding;
    var upper = maximum + padding;
    if (upper - lower < minimumSpan) {
      final center = (lower + upper) / 2;
      lower = center - minimumSpan / 2;
      upper = center + minimumSpan / 2;
    }
    if (lower < 0) {
      upper -= lower;
      lower = 0;
    }
    if (upper > fieldMaximum) {
      lower -= upper - fieldMaximum;
      upper = fieldMaximum;
    }
    return (
      min: lower.clamp(0.0, fieldMaximum).toDouble(),
      max: upper.clamp(0.0, fieldMaximum).toDouble(),
    );
  }

  final x = fit(
    minX,
    maxX,
    4.5,
    46,
    ScanPassPressureEngine.fieldLengthMetres,
  );
  final y = fit(
    minY,
    maxY,
    4,
    26,
    ScanPassPressureEngine.fieldWidthMetres,
  );
  return Rect.fromLTRB(
    x.min / ScanPassPressureEngine.fieldLengthMetres,
    y.min / ScanPassPressureEngine.fieldWidthMetres,
    x.max / ScanPassPressureEngine.fieldLengthMetres,
    y.max / ScanPassPressureEngine.fieldWidthMetres,
  );
}

void _pressureDrawPolyline(Canvas canvas, List<Offset> points, Paint paint) {
  if (points.length < 2) return;
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final point in points.skip(1)) {
    path.lineTo(point.dx, point.dy);
  }
  canvas.drawPath(path, paint);
}

void _pressureDrawDashedPolyline(
  Canvas canvas,
  List<Offset> points,
  Paint paint, {
  required double dash,
  required double gap,
}) {
  if (points.length < 2) return;
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final point in points.skip(1)) {
    path.lineTo(point.dx, point.dy);
  }
  for (final metric in path.computeMetrics()) {
    var travelled = 0.0;
    while (travelled < metric.length) {
      canvas.drawPath(
        metric.extractPath(
          travelled,
          math.min(travelled + dash, metric.length),
        ),
        paint,
      );
      travelled += dash + gap;
    }
  }
}

void _pressureDrawDashedLine(
  Canvas canvas,
  Offset from,
  Offset to,
  Paint paint, {
  required double dash,
  required double gap,
}) {
  final delta = to - from;
  if (delta.distance < .01) return;
  final direction = delta / delta.distance;
  var travelled = 0.0;
  while (travelled < delta.distance) {
    canvas.drawLine(
      from + direction * travelled,
      from + direction * math.min(travelled + dash, delta.distance),
      paint,
    );
    travelled += dash + gap;
  }
}

Offset _pressureArrowStart(List<Offset> points) {
  if (points.length < 2) return points.first;
  final end = points.last;
  for (var index = points.length - 2; index >= 0; index--) {
    if ((end - points[index]).distance >= 7) return points[index];
  }
  return points.first;
}

void _pressureDrawArrowHead(
    Canvas canvas, Offset from, Offset to, Paint paint) {
  final delta = to - from;
  if (delta.distance < 5) return;
  final angle = math.atan2(delta.dy, delta.dx);
  const length = 8.0;
  canvas.drawLine(
    to,
    to - Offset(math.cos(angle - .55), math.sin(angle - .55)) * length,
    paint,
  );
  canvas.drawLine(
    to,
    to - Offset(math.cos(angle + .55), math.sin(angle + .55)) * length,
    paint,
  );
}
