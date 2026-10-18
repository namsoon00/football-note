part of 'scan_pass_game_screen.dart';

enum _PressureLessonPhase { observing, choosing, executing, review, summary }

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
  final ScrollController _reviewTimelineController = ScrollController();
  late PressureEpisodeSession _session;
  late PressureEpisodeState _episode;
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
  PressureEpisodeDecision? _activeDecision;
  PressureEpisodeState? _completedEpisode;
  PressureEpisodeDecision? _alternativeDecision;
  int _reviewIndex = 0;
  bool _showingAlternative = false;
  bool _manualPause = false;
  bool _modalOpen = false;
  bool _foreground = true;
  VoidCallback? _motionCompletion;

  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  bool get _isChoosing => _phase == _PressureLessonPhase.choosing;
  bool get _isMoving =>
      _phase == _PressureLessonPhase.observing ||
      _phase == _PressureLessonPhase.executing;
  PressureEpisodeDecision? get _reviewedDecision {
    final timeline = _completedEpisode?.timeline;
    if (timeline == null || timeline.isEmpty) return null;
    return timeline[_reviewIndex.clamp(0, timeline.length - 1)];
  }

  PressureEpisodeDecision? get _displayedDecision =>
      _showingAlternative ? _alternativeDecision : _reviewedDecision;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _motion = AnimationController(vsync: this)
      ..addStatusListener(_handleMotionStatus);
    final situations = _buildSituations();
    _session = PressureEpisodeSession(situations: situations);
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
      _session = PressureEpisodeSession(situations: situations);
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
    _reviewTimelineController.dispose();
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
    _episode = _engine.startEpisode(_session.situations[index]);
    _observation = _episode.observation;
    _viewBounds = _pressureObservationViewBounds(_observation);
    _current = _observation.trace.first;
    _decisionSnapshot = _observation.decisionState;
    _phase = _PressureLessonPhase.observing;
    _playback = _PressurePlayback.observation;
    _options = const [];
    _completedTraces = const [];
    _activeTrace = _observation.trace;
    _activeDecision = null;
    _completedEpisode = null;
    _alternativeDecision = null;
    _reviewIndex = 0;
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
          _phase = _PressureLessonPhase.choosing;
          _options = _engine.episodeOptions(_episode);
          _viewBounds = _boundsForEpisode(_episode);
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
    if (_episode.pendingDecision == PressureEpisodeDecisionKind.support) return;
    final next = _engine.chooseEpisodeOption(_episode, option);
    if (next.timeline.length == _episode.timeline.length) return;
    _executeDecision(next);
  }

  void _chooseSupport(ScanPassPoint target) {
    if (!_isChoosing ||
        _episode.pendingDecision != PressureEpisodeDecisionKind.support) {
      return;
    }
    final next = _engine.chooseSupportTarget(_episode, target);
    if (next.timeline.length == _episode.timeline.length) return;
    _executeDecision(next);
  }

  void _executeDecision(PressureEpisodeState next) {
    final decision = next.timeline.last;
    _episode = next;
    _activeDecision = decision;
    setState(() {
      _phase = _PressureLessonPhase.executing;
      _playback = _PressurePlayback.learnerAction;
      _options = const [];
      _showingAlternative = false;
      _alternativeDecision = null;
      _activeTrace = decision.fullTrace;
      _viewBounds = _boundsForDecision(decision);
    });
    _playTrace(decision.fullTrace, widget.executionDuration, () {
      setState(() {
        _current = decision.after;
        _decisionSnapshot = decision.after;
        _completedTraces = [..._completedTraces, decision.fullTrace];
        _activeTrace = null;
        _activeDecision = null;
        if (_episode.isComplete) {
          _finishAttempt();
        } else {
          _phase = _PressureLessonPhase.choosing;
          _options = _engine.episodeOptions(_episode);
          _viewBounds = _boundsForEpisode(_episode);
        }
      });
    });
  }

  void _finishAttempt() {
    _completedEpisode = _episode;
    final attempt = PressureEpisodeAttempt(
      situationIndex: _situationIndex,
      scenario: _episode.scenario,
      timeline: _episode.timeline,
      outcome: _episode.outcome!,
    );
    _session = _session.recordFirstAttempt(attempt);
    _reviewIndex = _episode.timeline.length - 1;
    _buildAlternative();
    _setReviewFrame();
    _phase = _PressureLessonPhase.review;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_reviewTimelineController.hasClients) return;
      _reviewTimelineController.jumpTo(
        _reviewTimelineController.position.maxScrollExtent,
      );
    });
  }

  void _buildAlternative() {
    final selected = _reviewedDecision;
    _alternativeDecision = null;
    if (selected == null) return;
    if (selected.kind == PressureEpisodeDecisionKind.support) {
      final focus = selected.before.actorByRole(_episode.scenario.focusRole);
      final chosen = selected.supportResult!.boundedTarget - focus.position;
      final alternativeTarget = ScanPassPoint(
        focus.position.x +
            math.max(3.5, chosen.x.abs()) * (chosen.x < 0 ? -1 : 1),
        focus.position.y - (chosen.y.abs() < 1 ? 5.5 : chosen.y),
      );
      _alternativeDecision =
          _engine.alternativeSupport(selected, alternativeTarget);
      return;
    }
    final chosenKey = selected.selectedOption?.key;
    final candidates = selected.availableOptions
        .where((option) => option.key != chosenKey)
        .map((option) => _engine.alternativeOption(selected, option))
        .toList()
      ..sort((a, b) => _qualityRank(b).compareTo(_qualityRank(a)));
    if (candidates.isNotEmpty) _alternativeDecision = candidates.first;
  }

  int _qualityRank(PressureEpisodeDecision decision) {
    final result =
        decision.actionResult ?? decision.supportResult?.continuation?.result;
    if (result == null) return decision.lost ? 0 : 1;
    return switch (result.assessment.quality) {
      PressureDecisionQuality.strong => 3,
      PressureDecisionQuality.sound => 2,
      PressureDecisionQuality.compromised => 1,
      PressureDecisionQuality.lost => 0,
    };
  }

  void _setReviewFrame() {
    final decision = _displayedDecision;
    if (decision == null) return;
    final result =
        decision.actionResult ?? decision.supportResult?.continuation?.result;
    _current = result == null
        ? decision.after
        : _engine.actionEvidence(result).freezeFrame;
    _viewBounds = _boundsForDecision(decision);
  }

  void _retryReviewedDecision() {
    final completed = _completedEpisode;
    if (completed == null) return;
    final restored = _engine.retryFrom(completed, _reviewIndex);
    setState(() {
      _episode = restored;
      _current = restored.world;
      _decisionSnapshot = restored.world;
      _options = _engine.episodeOptions(restored);
      _viewBounds = _boundsForEpisode(restored);
      _phase = _PressureLessonPhase.choosing;
      _completedTraces = [
        _observation.trace,
        for (final item in restored.timeline) item.fullTrace,
      ];
      _activeDecision = null;
      _alternativeDecision = null;
      _showingAlternative = false;
    });
  }

  void _playAlternative() {
    final decision = _alternativeDecision;
    if (decision == null) return;
    setState(() {
      _current = decision.before;
      _viewBounds = _boundsForDecision(decision);
      _phase = _PressureLessonPhase.executing;
      _playback = _PressurePlayback.alternative;
      _activeTrace = decision.fullTrace;
      _showingAlternative = true;
    });
    _playTrace(decision.fullTrace, widget.executionDuration, () {
      setState(() {
        _setReviewFrame();
        _activeTrace = null;
        _phase = _PressureLessonPhase.review;
      });
    });
  }

  void _returnToAttempt() {
    setState(() {
      _showingAlternative = false;
      _setReviewFrame();
      _activeTrace = null;
      _phase = _PressureLessonPhase.review;
    });
  }

  void _replayAttempt() {
    final attempt = _completedEpisode;
    if (attempt == null) return;
    final trace = PressureTrace.join([
      _observation.trace,
      for (final decision in attempt.timeline) decision.fullTrace,
    ]);
    setState(() {
      _current = trace.first;
      _viewBounds = _pressureObservationViewBounds(_observation);
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
        _setReviewFrame();
        _activeTrace = null;
        _phase = _PressureLessonPhase.review;
      });
    });
  }

  void _selectReviewDecision(int index) {
    if (index == _reviewIndex) return;
    setState(() {
      _reviewIndex = index;
      _showingAlternative = false;
      _activeTrace = null;
      _buildAlternative();
      _setReviewFrame();
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
    _session = PressureEpisodeSession(situations: _buildSituations());
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
              if (_completedEpisode != null)
                PopupMenuItem(
                  key: const ValueKey<String>('pressure-menu-replay'),
                  value: _replayAttempt,
                  child: Text(l10n.pressureLessonReplayMine),
                ),
              if (_completedEpisode != null)
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
      final hasPanel = _phase == _PressureLessonPhase.review ||
          _phase == _PressureLessonPhase.summary;
      if (!hasPanel) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: field,
        );
      }
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
      final panelHeight = _phase == _PressureLessonPhase.review
          ? math.min(300.0, constraints.maxHeight * .46)
          : math.min(280.0, constraints.maxHeight * .40);
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
    final displayedDecision = _displayedDecision;
    final reviewResult =
        displayedDecision?.kind == PressureEpisodeDecisionKind.support
            ? null
            : displayedDecision?.actionResult;
    final reviewEvidence =
        reviewResult == null ? null : _engine.actionEvidence(reviewResult);
    final contextWorld =
        _phase == _PressureLessonPhase.review && displayedDecision != null
            ? displayedDecision.before
            : displayed;
    final contextKind = _phase == _PressureLessonPhase.review
        ? displayedDecision?.kind
        : _phase == _PressureLessonPhase.executing
            ? _activeDecision?.kind ?? _episode.pendingDecision
            : _episode.pendingDecision;
    final contextStage = switch (contextKind) {
      PressureEpisodeDecisionKind.receive => PressureDecisionStage.firstContact,
      PressureEpisodeDecisionKind.support => PressureDecisionStage.support,
      _ => PressureDecisionStage.reRead,
    };
    final focusRole = _episode.scenario.focusRole;
    final supportTarget = _phase == _PressureLessonPhase.executing
        ? _activeDecision?.supportResult?.boundedTarget
        : _phase == _PressureLessonPhase.review
            ? displayedDecision?.supportResult?.boundedTarget
            : _episode.timeline.lastOrNull?.supportResult?.boundedTarget;
    final reviewTraces = <PressureTrace>[
      _observation.trace,
      if (_completedEpisode != null)
        for (final decision
            in _completedEpisode!.timeline.take(_reviewIndex + 1))
          decision.fullTrace,
    ];
    return RepaintBoundary(
      key: const ValueKey<String>('pressure-lesson-capture'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildSituationRibbon(
          l10n,
          colors,
          _engine.situationContext(contextWorld, contextStage),
        ),
        const SizedBox(height: 6),
        _buildInstruction(l10n, colors),
        const SizedBox(height: 5),
        Expanded(
          child: Semantics(
            image: true,
            label: _contextTask(l10n),
            child: ClipRect(
              child: Stack(fit: StackFit.expand, children: [
                CustomPaint(
                  key: const ValueKey<String>('pressure-pitch'),
                  painter: _PressureLessonPitchPainter(
                    displayWorld: displayed,
                    portrait: portrait,
                    completedTraces: _phase == _PressureLessonPhase.review
                        ? reviewTraces
                        : _playback == _PressurePlayback.replay && _isMoving
                            ? const []
                            : _completedTraces,
                    activeTrace: trace,
                    activeProgress: _motion.value,
                    reviewResult: _phase == _PressureLessonPhase.review
                        ? reviewResult
                        : null,
                    reviewEvidence: _phase == _PressureLessonPhase.review
                        ? reviewEvidence
                        : null,
                    l10n: l10n,
                    names: _pressureNames(l10n),
                    brightness: Theme.of(context).brightness,
                    fontFamily:
                        Theme.of(context).textTheme.bodyMedium?.fontFamily,
                    viewBounds: _viewBounds,
                    focusRole: focusRole,
                    showSupportRange: _isChoosing &&
                        _episode.pendingDecision ==
                            PressureEpisodeDecisionKind.support &&
                        _episode.scenario.showMovementGuidance,
                    supportTarget: supportTarget,
                  ),
                ),
                if (_isChoosing &&
                    _episode.pendingDecision ==
                        PressureEpisodeDecisionKind.support)
                  Positioned.fill(
                    child: LayoutBuilder(builder: (context, constraints) {
                      return GestureDetector(
                        key: const ValueKey<String>('pressure-support-surface'),
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) => _chooseSupportAtOffset(
                          details.localPosition,
                          Size(constraints.maxWidth, constraints.maxHeight),
                          portrait,
                        ),
                      );
                    }),
                  ),
                if (_isChoosing &&
                    _episode.pendingDecision !=
                        PressureEpisodeDecisionKind.support)
                  _buildChoiceLayer(displayed, portrait: portrait, l10n: l10n),
                Positioned.fill(
                  child: IgnorePointer(
                    child: LayoutBuilder(builder: (context, constraints) {
                      final geometry = _MatchPitchGeometry(
                        Size(constraints.maxWidth, constraints.maxHeight),
                        portrait: portrait,
                        viewBounds: _viewBounds,
                      );
                      final rect = _pressureOverviewRect(
                        geometry,
                        _isMoving ? _decisionSnapshot : displayed,
                      );
                      return Stack(children: [
                        Positioned.fromRect(
                          rect: rect,
                          child: Semantics(
                            label: l10n.pressureLessonOverview,
                            image: true,
                            child: CustomPaint(
                              key: const ValueKey<String>('pressure-overview'),
                              painter: _PressureOverviewPainter(
                                world: displayed,
                                viewBounds: _viewBounds,
                                portrait: portrait,
                                brightness: Theme.of(context).brightness,
                              ),
                            ),
                          ),
                        ),
                      ]);
                    }),
                  ),
                ),
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
        ),
      ]),
    );
  }

  Widget _buildSituationRibbon(
    AppLocalizations l10n,
    _ScanPassColors colors,
    PressureSituationContext situation,
  ) {
    final location = _pressureLocation(l10n, situation);
    final scenario = _episode.scenario;
    final family = _familyLabel(l10n, scenario.family);
    final variant = _variantLabel(l10n, scenario.variant);
    final side = switch (situation.approachSide) {
      PressureApproachSide.outside => l10n.pressureEpisodePressureSideRight,
      PressureApproachSide.inside => l10n.pressureEpisodePressureSideLeft,
      PressureApproachSide.level => l10n.pressureEpisodePressureSideLevel,
    };
    final movement = switch (situation.pressureMovement) {
      PressureMovement.closing => l10n.pressureEpisodePressureClosing,
      PressureMovement.holding => l10n.pressureEpisodePressureHolding,
    };
    final pressure = _judgmentCue(
      l10n,
      situation,
      pressure: l10n.pressureEpisodePressureFact(
        situation.presserNumber,
        movement,
        side,
        situation.pressureDistanceMetres.toStringAsFixed(1),
      ),
    );
    final facts = l10n.pressureEpisodeFacts(
      location,
      situation.carrierNumber,
      scenario.observationStart.actorByRole(scenario.focusRole).number,
      pressure,
    );
    final task = _contextTask(l10n);
    return DecoratedBox(
      key: const ValueKey<String>('pressure-situation-ribbon'),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.pressureEpisodeIdentity(
                _situationIndex + 1,
                PressureLessonCatalog.situationCount,
                family,
                variant,
              ),
              key: const ValueKey<String>('pressure-progress'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              facts,
              key: const ValueKey<String>('pressure-situation-facts'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.text,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 1),
            Text(
              task,
              key: const ValueKey<String>('pressure-situation-task'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.muted,
                    height: 1.1,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _chooseSupportAtOffset(Offset offset, Size size, bool portrait) {
    final geometry = _MatchPitchGeometry(
      size,
      portrait: portrait,
      viewBounds: _viewBounds,
    );
    if (!geometry.viewportRect.contains(offset) ||
        _pressureOverviewRect(geometry, _current).contains(offset)) {
      return;
    }
    final normalised = geometry.vertical
        ? ScanPassPoint(
            geometry.minX +
                (geometry.viewportRect.bottom - offset.dy) /
                    (105 * geometry.scale),
            geometry.minY +
                (geometry.viewportRect.right - offset.dx) /
                    (68 * geometry.scale),
          )
        : ScanPassPoint(
            geometry.minX +
                (offset.dx - geometry.viewportRect.left) /
                    (105 * geometry.scale),
            geometry.minY +
                (geometry.viewportRect.bottom - offset.dy) /
                    (68 * geometry.scale),
          );
    _chooseSupport(ScanPassPoint(
      normalised.x * ScanPassPressureEngine.fieldLengthMetres,
      normalised.y * ScanPassPressureEngine.fieldWidthMetres,
    ));
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
      _PressureLessonPhase.choosing => switch (_episode.pendingDecision) {
          PressureEpisodeDecisionKind.receive =>
            l10n.pressureEpisodeChooseReceive,
          PressureEpisodeDecisionKind.onBall =>
            l10n.pressureEpisodeChooseOnBall,
          PressureEpisodeDecisionKind.support =>
            l10n.pressureEpisodeChooseSupport(
              _episode.world.actorByRole(_episode.scenario.focusRole).number,
            ),
          null => l10n.pressureLessonChooseNext,
        },
      _PressureLessonPhase.executing => switch (_playback) {
          _PressurePlayback.alternative => l10n.pressureLessonAlternativeView,
          _PressurePlayback.replay => l10n.pressureLessonReplayView,
          _ => l10n.pressureLessonExecuting,
        },
      _PressureLessonPhase.review => l10n.pressureEpisodeReviewInstruction,
      _PressureLessonPhase.summary => l10n.pressureEpisodeSummaryTitle,
    };
    final hint = _isChoosing
        ? _episode.pendingDecision == PressureEpisodeDecisionKind.support
            ? l10n.pressureEpisodeSupportHint
            : l10n.pressureLessonOneTapHint
        : l10n.pressureLessonSyntheticNote;
    return DecoratedBox(
      key: ValueKey<String>('pressure-phase-${_phase.name}'),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(children: [
          Icon(
            _isMoving ? Icons.visibility_outlined : Icons.touch_app_outlined,
            color: colors.accent,
            size: 19,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  key: const ValueKey<String>('pressure-instruction'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                ),
                Text(
                  hint,
                  key: const ValueKey<String>('pressure-instruction-hint'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.muted,
                        height: 1.08,
                      ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildReview(AppLocalizations l10n, _ScanPassColors colors) {
    final decision = _displayedDecision!;
    final timeline = _completedEpisode!.timeline;
    return Column(
      key: const ValueKey<String>('pressure-review-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                _showingAlternative
                    ? l10n.pressureLessonAlternative
                    : _outcomeLabel(l10n, _completedEpisode!.outcome!),
                key: _showingAlternative
                    ? null
                    : const ValueKey<String>('pressure-episode-outcome'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            if (!_showingAlternative) ...[
              const SizedBox(width: 6),
              Text(
                l10n.pressureEpisodeDecisionCount(timeline.length),
                key: const ValueKey<String>('pressure-review-count'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.muted,
                    ),
              ),
            ],
          ],
        ),
        if (!_showingAlternative)
          SizedBox(
            key: const ValueKey<String>('pressure-review-timeline'),
            height: 39,
            child: Scrollable(
              controller: _reviewTimelineController,
              axisDirection: AxisDirection.right,
              viewportBuilder: (context, offset) => Viewport(
                axisDirection: AxisDirection.right,
                offset: offset,
                slivers: [
                  SliverToBoxAdapter(
                    child: Row(children: [
                      for (var index = 0; index < timeline.length; index++) ...[
                        if (index > 0) const SizedBox(width: 5),
                        ChoiceChip(
                          key: ValueKey<String>(
                              'pressure-review-decision-$index'),
                          label: Text(l10n.pressureEpisodeTimelineItem(
                            index + 1,
                            _decisionKindLabel(l10n, timeline[index].kind),
                          )),
                          selected: index == _reviewIndex,
                          onSelected: (_) => _selectReviewDecision(index),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ]),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 5),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _reviewLine(
                  key: 'pressure-review-action',
                  icon: Icons.sports_soccer_outlined,
                  text: _decisionActionLine(l10n, decision),
                  colors: colors,
                ),
                _reviewLine(
                  key: 'pressure-review-benefit',
                  icon: Icons.add_circle_outline,
                  text: _decisionBenefitLine(l10n, decision),
                  colors: colors,
                ),
                _reviewLine(
                  key: 'pressure-review-limitation',
                  icon: Icons.gps_fixed,
                  text: _decisionLimitationLine(l10n, decision),
                  colors: colors,
                ),
                if (decision.supportResult?.continuation != null)
                  _reviewLine(
                    key: 'pressure-review-consequence',
                    icon: Icons.fast_forward_outlined,
                    text: _supportConsequenceLine(l10n, decision),
                    colors: colors,
                  ),
                if (!_showingAlternative && _alternativeDecision != null)
                  _reviewLine(
                    key: 'pressure-review-alternative',
                    icon: Icons.compare_arrows_outlined,
                    text: l10n.pressureEpisodeAlternativeAvailable,
                    colors: colors,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (_showingAlternative)
          FilledButton(
            key: const ValueKey<String>('pressure-return-attempt'),
            onPressed: _returnToAttempt,
            child: Text(l10n.pressureLessonReturnMine),
          )
        else
          Row(children: [
            Expanded(
              child: OutlinedButton(
                key: const ValueKey<String>('pressure-retry'),
                onPressed: _retryReviewedDecision,
                child: Text(l10n.pressureLessonRetry),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: FilledButton(
                key: const ValueKey<String>('pressure-next'),
                onPressed: _nextSituation,
                child: Text(
                    _situationIndex == PressureLessonCatalog.situationCount - 1
                        ? l10n.pressureLessonFinish
                        : l10n.pressureLessonNext),
              ),
            ),
            if (_alternativeDecision != null) ...[
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
    return SingleChildScrollView(
      key: const ValueKey<String>('pressure-summary'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.fact_check_outlined, color: colors.accent, size: 28),
          const SizedBox(height: 7),
          Text(
            l10n.pressureEpisodeSummaryTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 7),
          Text(l10n.pressureEpisodeSummaryCoverage(
              attempts, PressureLessonCatalog.situationCount)),
          const SizedBox(height: 5),
          Text(l10n.pressureEpisodeSummaryRetained(
              _session.retainedAttacks, attempts)),
          const SizedBox(height: 5),
          Text(l10n.pressureEpisodeSummaryUnseen(
              _session.unseenRetained, _session.unseenAttempts)),
          const SizedBox(height: 5),
          Text(l10n.pressureEpisodeSummaryLimit),
          const SizedBox(height: 10),
          FilledButton(
            key: const ValueKey<String>('pressure-restart'),
            onPressed: _restartLesson,
            child: Text(l10n.pressureEpisodeRestart),
          ),
        ],
      ),
    );
  }

  String _decisionActionLine(
    AppLocalizations l10n,
    PressureEpisodeDecision decision,
  ) {
    final support = decision.supportResult;
    if (support != null) {
      return l10n.pressureEpisodeReviewSupportAction(
        decision.before.actorByRole(support.focusRole).number,
        support.movementDistanceMetres.toStringAsFixed(1),
      );
    }
    final result = decision.actionResult!;
    final evidence = _engine.actionEvidence(result);
    final option = decision.selectedOption;
    final action = option == null
        ? l10n.pressureLessonCarryForward
        : _optionLabel(l10n, option, result.before);
    return l10n.pressureLessonReviewSelectedAction(
      evidence.actorNumber,
      action,
    );
  }

  String _decisionBenefitLine(
    AppLocalizations l10n,
    PressureEpisodeDecision decision,
  ) {
    final support = decision.supportResult;
    if (support == null) {
      return _evidenceBenefitLine(
          l10n, _engine.actionEvidence(decision.actionResult!));
    }
    final lane = support.demonstratedPositiveLaneChange;
    if (lane != null && lane.usableAfter && !lane.usableBefore) {
      final receiver = support.afterMovement.actorByRole(lane.receiverRole);
      final defender = lane.beforeDefenderRole == null
          ? support.stationaryCounterfactual
              .actorByRole(PressureActorRole.cover)
          : support.stationaryCounterfactual
              .actorByRole(lane.beforeDefenderRole!);
      return l10n.pressureEpisodeSupportOpenedLane(
          receiver.number, defender.number);
    }
    if (lane != null && lane.clearanceChangeMetres >= .35) {
      final receiver = support.afterMovement.actorByRole(lane.receiverRole);
      return l10n.pressureEpisodeSupportWidenedLane(
        receiver.number,
        lane.clearanceChangeMetres.toStringAsFixed(1),
      );
    }
    return l10n.pressureEpisodeSupportNoMeasuredBenefit;
  }

  String _evidenceBenefitLine(
    AppLocalizations l10n,
    PressureActionEvidence evidence,
  ) =>
      switch (evidence.benefit) {
        PressureActionBenefit.none => l10n.pressureLessonBenefitNone,
        PressureActionBenefit.increasedSeparation =>
          l10n.pressureLessonBenefitSeparation(
            evidence.separationChangeMetres.toStringAsFixed(1),
          ),
        PressureActionBenefit.passReceived =>
          l10n.pressureLessonBenefitPassReceived(
            evidence.benefitReceiverNumber!,
          ),
        PressureActionBenefit.forwardPassReceived =>
          l10n.pressureLessonBenefitForwardPassReceived(
            evidence.benefitReceiverNumber!,
            evidence.progressMetres.toStringAsFixed(1),
          ),
        PressureActionBenefit.openedSimulatedForwardLane =>
          l10n.pressureLessonBenefitSimulatedLane(
            evidence.benefitReceiverNumber!,
          ),
        PressureActionBenefit.progressedWithControl =>
          l10n.pressureLessonBenefitControlledProgress(
            evidence.progressMetres.toStringAsFixed(1),
          ),
        PressureActionBenefit.retainedControl =>
          l10n.pressureLessonBenefitRetainedControl,
      };

  String _decisionLimitationLine(
    AppLocalizations l10n,
    PressureEpisodeDecision decision,
  ) {
    final support = decision.supportResult;
    if (support == null) {
      return _evidenceLimitationLine(
          l10n, _engine.actionEvidence(decision.actionResult!));
    }
    if (decision.offside) {
      final automatic = support.continuation?.result;
      final destination = automatic?.intendedReceiverRole;
      final number = destination == null
          ? support.after.actorByRole(support.focusRole).number
          : support.before.actorByRole(destination).number;
      return l10n.pressureLessonLimitationOffside(number);
    }
    if (decision.lost) {
      final contact = support.contact;
      if (contact != null) {
        return l10n.pressureLessonLimitationInterception(
          contact.defenderNumber,
          (contact.clock - support.before.clock).toStringAsFixed(1),
        );
      }
      return l10n.pressureLessonLimitationLoose;
    }
    final lane = support.demonstratedNegativeLaneChange;
    if (lane != null && lane.usableBefore && !lane.usableAfter) {
      final receiver = support.afterMovement.actorByRole(lane.receiverRole);
      final defender = lane.afterDefenderRole == null
          ? support.afterMovement.actorByRole(PressureActorRole.cover)
          : support.afterMovement.actorByRole(lane.afterDefenderRole!);
      return l10n.pressureEpisodeSupportBlockedLane(
          receiver.number, defender.number);
    }
    final stillBlocked = support.laneChanges
            .where((candidate) =>
                candidate.receiverRole == support.focusRole &&
                !candidate.usableAfter)
            .firstOrNull ??
        support.laneChanges
            .where((candidate) => !candidate.usableAfter)
            .firstOrNull;
    if (stillBlocked != null) {
      final receiver =
          support.afterMovement.actorByRole(stillBlocked.receiverRole);
      final defender = stillBlocked.afterDefenderRole == null
          ? support.afterMovement.actorByRole(PressureActorRole.cover)
          : support.afterMovement.actorByRole(stillBlocked.afterDefenderRole!);
      return l10n.pressureEpisodeSupportLaneStillBlocked(
        receiver.number,
        defender.number,
      );
    }
    if (support.continuation == null) {
      return l10n.pressureEpisodeSupportNoContinuation;
    }
    return l10n.pressureEpisodeSupportLanesUnchanged;
  }

  String _supportConsequenceLine(
    AppLocalizations l10n,
    PressureEpisodeDecision decision,
  ) {
    final support = decision.supportResult!;
    final automatic = support.continuation!;
    final from = automatic.result.before.carrier!.number;
    final to = automatic.result.after.carrier?.number;
    return switch (automatic.kind) {
      PressureAutomaticKind.pass when to != null =>
        l10n.pressureEpisodeAutomaticPass(from, to),
      PressureAutomaticKind.recycle
          when to != null &&
              automatic.result.action.target.x <
                  automatic.result.before.ball.position.x - .5 =>
        l10n.pressureEpisodeAutomaticRecycle(from, to),
      PressureAutomaticKind.recycle when to != null =>
        l10n.pressureEpisodeAutomaticPass(from, to),
      _ => l10n.pressureEpisodeAutomaticCarry(from),
    };
  }

  String _judgmentCue(
    AppLocalizations l10n,
    PressureSituationContext situation, {
    required String pressure,
  }) {
    final coverMovement = switch (situation.coverMovement) {
      PressureMovement.closing => l10n.pressureEpisodePressureClosing,
      PressureMovement.holding => l10n.pressureEpisodePressureHolding,
    };
    if (situation.stage == PressureDecisionStage.support) {
      return l10n.pressureEpisodeReturnLaneFact(
        situation.supportNumber,
        situation.coverNumber,
        coverMovement,
        situation.coverLaneDistanceMetres.toStringAsFixed(1),
      );
    }
    if (_episode.scenario.family == PressureLearningFamily.runnerTiming) {
      final runnerMovement = switch (situation.runnerMovement) {
        PressureRunnerMovement.breakingForward =>
          l10n.pressureLessonContextRunnerBreaking,
        PressureRunnerMovement.movingForward =>
          l10n.pressureLessonContextRunnerMoving,
        PressureRunnerMovement.held => l10n.pressureLessonContextRunnerHeld,
      };
      return l10n.pressureEpisodeRunnerFact(
        situation.runnerNumber,
        runnerMovement,
      );
    }
    if (_episode.scenario.family == PressureLearningFamily.thirdPlayer ||
        _episode.scenario.family == PressureLearningFamily.recycleAndSwitch) {
      return l10n.pressureEpisodeCoverFact(
        situation.supportNumber,
        situation.coverNumber,
        coverMovement,
        situation.coverLaneDistanceMetres.toStringAsFixed(1),
      );
    }
    return pressure;
  }

  String _evidenceLimitationLine(
    AppLocalizations l10n,
    PressureActionEvidence evidence,
  ) =>
      switch (evidence.limitation) {
        PressureActionLimitation.interception =>
          l10n.pressureLessonLimitationInterception(
            evidence.defenderNumber!,
            evidence.contactSeconds!.toStringAsFixed(1),
          ),
        PressureActionLimitation.offside =>
          l10n.pressureLessonLimitationOffside(
            evidence.destinationNumber!,
          ),
        PressureActionLimitation.looseBall =>
          l10n.pressureLessonLimitationLoose,
        PressureActionLimitation.lostForwardWindow =>
          l10n.pressureLessonLimitationForwardWindow,
        PressureActionLimitation.closingPressure =>
          l10n.pressureLessonLimitationClosingPressure(
            evidence.defenderNumber!,
            evidence.pressureClearanceMetres.toStringAsFixed(1),
          ),
        PressureActionLimitation.limitedProgression =>
          l10n.pressureLessonLimitationProgress(
            evidence.progressMetres.toStringAsFixed(1),
          ),
        PressureActionLimitation.remainingPressure =>
          l10n.pressureLessonLimitationRemainingPressure(
            evidence.defenderNumber!,
            evidence.pressureClearanceMetres.toStringAsFixed(1),
          ),
      };

  String _pressureLocation(
    AppLocalizations l10n,
    PressureSituationContext situation,
  ) {
    final band = switch (situation.fieldBand) {
      PressureFieldBand.middleThird => l10n.pressureLessonMiddleThird,
      PressureFieldBand.attackingThird => l10n.pressureLessonAttackingThird,
    };
    final channel = switch (situation.fieldChannel) {
      PressureFieldChannel.right => l10n.pressureLessonRightChannel,
      PressureFieldChannel.central => l10n.pressureLessonCentralChannel,
      PressureFieldChannel.left => l10n.pressureLessonLeftChannel,
    };
    return l10n.pressureLessonLocation(band, channel);
  }

  String _familyLabel(
    AppLocalizations l10n,
    PressureLearningFamily family,
  ) =>
      switch (family) {
        PressureLearningFamily.pressureReception =>
          l10n.pressureEpisodeFamilyReception,
        PressureLearningFamily.drawAndRelease =>
          l10n.pressureEpisodeFamilyDrawRelease,
        PressureLearningFamily.supportAfterPass =>
          l10n.pressureEpisodeFamilySupport,
        PressureLearningFamily.runnerTiming =>
          l10n.pressureEpisodeFamilyRunnerTiming,
        PressureLearningFamily.thirdPlayer =>
          l10n.pressureEpisodeFamilyThirdPlayer,
        PressureLearningFamily.recycleAndSwitch =>
          l10n.pressureEpisodeFamilyRecycle,
      };

  String _variantLabel(
    AppLocalizations l10n,
    PressureLessonVariant variant,
  ) =>
      switch (variant) {
        PressureLessonVariant.guided => l10n.pressureEpisodeVariantGuided,
        PressureLessonVariant.contrast => l10n.pressureEpisodeVariantContrast,
        PressureLessonVariant.unseen => l10n.pressureEpisodeVariantUnseen,
      };

  String _decisionKindLabel(
    AppLocalizations l10n,
    PressureEpisodeDecisionKind kind,
  ) =>
      switch (kind) {
        PressureEpisodeDecisionKind.receive =>
          l10n.pressureEpisodeDecisionReceive,
        PressureEpisodeDecisionKind.onBall =>
          l10n.pressureEpisodeDecisionOnBall,
        PressureEpisodeDecisionKind.support =>
          l10n.pressureEpisodeDecisionSupport,
      };

  String _outcomeLabel(
    AppLocalizations l10n,
    PressureEpisodeOutcome outcome,
  ) =>
      switch (outcome) {
        PressureEpisodeOutcome.penetration =>
          l10n.pressureEpisodeOutcomePenetration,
        PressureEpisodeOutcome.pressureEscape =>
          l10n.pressureEpisodeOutcomeEscape,
        PressureEpisodeOutcome.safeRecycle =>
          l10n.pressureEpisodeOutcomeRecycle,
        PressureEpisodeOutcome.intercepted =>
          l10n.pressureEpisodeOutcomeIntercepted,
        PressureEpisodeOutcome.offside => l10n.pressureEpisodeOutcomeOffside,
        PressureEpisodeOutcome.loose => l10n.pressureEpisodeOutcomeLoose,
        PressureEpisodeOutcome.retainedUnresolved =>
          l10n.pressureEpisodeOutcomeUnresolved,
      };

  String _contextTask(AppLocalizations l10n) {
    if (_phase == _PressureLessonPhase.summary) {
      return l10n.pressureEpisodeSummaryTitle;
    }
    if (_phase == _PressureLessonPhase.review) {
      if (_showingAlternative) {
        return l10n.pressureLessonContextTaskAlternative;
      }
      return l10n.pressureEpisodeContextReview(
        _reviewIndex + 1,
        _completedEpisode!.timeline.length,
      );
    }
    if (_phase == _PressureLessonPhase.executing) {
      if (_playback == _PressurePlayback.alternative) {
        return l10n.pressureLessonContextTaskAlternative;
      }
      return _playback == _PressurePlayback.replay
          ? l10n.pressureLessonContextTaskReplay
          : l10n.pressureEpisodeContextExecuting;
    }
    if (_phase == _PressureLessonPhase.observing) {
      return l10n.pressureEpisodeContextObserve;
    }
    return switch (_episode.pendingDecision) {
      PressureEpisodeDecisionKind.receive => l10n.pressureEpisodeTaskReceive,
      PressureEpisodeDecisionKind.onBall => l10n.pressureEpisodeTaskOnBall,
      PressureEpisodeDecisionKind.support => l10n.pressureEpisodeTaskSupport(
          _episode.world.actorByRole(_episode.scenario.focusRole).number),
      null => l10n.pressureEpisodeContextExecuting,
    };
  }

  String _optionLabel(
    AppLocalizations l10n,
    PressureDecisionOption option,
    PressureWorld world,
  ) {
    final number = _targetNumber(option, world);
    if (option.action.kind == PressureActionKind.pass) {
      if (option.action.target.x < world.ball.position.x - .5) {
        return l10n.pressureLessonPassBack(number);
      }
      if (option.kind == PressureOptionKind.recycle ||
          option.kind == PressureOptionKind.immediateBackPass) {
        return l10n.pressureLessonPassTo(number);
      }
    }
    return switch (option.kind) {
      PressureOptionKind.touchInside => l10n.pressureLessonTouchInside,
      PressureOptionKind.touchOutside => l10n.pressureLessonTouchOutside,
      PressureOptionKind.touchLeft => l10n.pressureEpisodeTouchLeft,
      PressureOptionKind.touchRight => l10n.pressureEpisodeTouchRight,
      PressureOptionKind.immediatePass => l10n.pressureLessonPassNow(number),
      PressureOptionKind.immediateRunnerPass =>
        l10n.pressureLessonPassRunner(number),
      PressureOptionKind.immediateBackPass =>
        l10n.pressureLessonPassBack(number),
      PressureOptionKind.passSupport => l10n.pressureLessonPassSupport(number),
      PressureOptionKind.passRunner => l10n.pressureLessonPassRunner(number),
      PressureOptionKind.passFocus ||
      PressureOptionKind.passOther =>
        l10n.pressureLessonPassTo(number),
      PressureOptionKind.recycle => l10n.pressureLessonPassBack(number),
      PressureOptionKind.carryForward => l10n.pressureLessonCarryForward,
    };
  }

  int _targetNumber(PressureDecisionOption option, PressureWorld world) {
    if (option.action.kind != PressureActionKind.pass) {
      return world.carrier?.number ?? 19;
    }
    final teammates = world
        .team(PressureTeam.attack)
        .where((actor) => actor.id != world.ball.carrierId)
        .toList()
      ..sort((a, b) => a.position
          .distanceTo(option.action.target)
          .compareTo(b.position.distanceTo(option.action.target)));
    return teammates.first.number;
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
        PressureOptionKind.touchOutside ||
        PressureOptionKind.touchLeft ||
        PressureOptionKind.touchRight =>
          Icons.touch_app_outlined,
        PressureOptionKind.immediatePass ||
        PressureOptionKind.immediateRunnerPass ||
        PressureOptionKind.immediateBackPass ||
        PressureOptionKind.passSupport ||
        PressureOptionKind.passRunner ||
        PressureOptionKind.passFocus ||
        PressureOptionKind.passOther ||
        PressureOptionKind.recycle =>
          Icons.sports_soccer,
        PressureOptionKind.carryForward => Icons.arrow_forward,
      };

  Rect _boundsForEpisode(PressureEpisodeState episode) {
    final options =
        episode.pendingDecision == PressureEpisodeDecisionKind.support
            ? _supportBoundsOptions(episode.world)
            : _engine.episodeOptions(episode);
    return _pressureDecisionViewBounds(episode.world, options);
  }

  Rect _boundsForDecision(PressureEpisodeDecision decision) {
    final result = decision.actionResult;
    if (result != null) {
      return _pressureDecisionViewBounds(
        decision.before,
        decision.availableOptions,
        reviewResult: result,
      );
    }
    return _pressureDecisionViewBounds(
      decision.before,
      [
        ..._supportBoundsOptions(decision.before),
        PressureDecisionOption(
          key: 'support-executed',
          kind: PressureOptionKind.carryForward,
          action: PressureAction(
            kind: PressureActionKind.offBallRun,
            target: decision.executedTarget,
          ),
        ),
      ],
    );
  }

  List<PressureDecisionOption> _supportBoundsOptions(PressureWorld world) {
    final focus = world.actorByRole(_episode.scenario.focusRole).position;
    return [
      for (final delta in const [
        ScanPassPoint(8, 0),
        ScanPassPoint(-8, 0),
        ScanPassPoint(0, 8),
        ScanPassPoint(0, -8),
      ])
        PressureDecisionOption(
          key: 'support-bound-${delta.x}-${delta.y}',
          kind: PressureOptionKind.carryForward,
          action: PressureAction(
            kind: PressureActionKind.offBallRun,
            target: focus + delta,
          ),
        ),
    ];
  }

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

Rect _pressureOverviewRect(_MatchPitchGeometry geometry, PressureWorld world) {
  final size = geometry.vertical ? const Size(56, 84) : const Size(84, 56);
  final candidates = [
    Rect.fromLTWH(8, 12, size.width, size.height),
    Rect.fromLTWH(
        8, geometry.size.height - size.height - 12, size.width, size.height),
    Rect.fromLTWH(
        geometry.size.width - size.width - 8, 12, size.width, size.height),
    Rect.fromLTWH(geometry.size.width - size.width - 8,
        geometry.size.height - size.height - 12, size.width, size.height),
  ];
  final occupied = [
    for (final actor in world.actors)
      Rect.fromCenter(
        center:
            geometry.toOffset(_normalise(actor.position)) - const Offset(0, 8),
        width: 48,
        height: 60,
      ),
    Rect.fromPoints(geometry.attackArrowStart, geometry.attackArrowEnd)
        .inflate(12),
  ];
  double score(Rect rect) => occupied.fold(0.0, (total, actor) {
        if (!rect.overlaps(actor)) return total;
        final overlap = rect.intersect(actor);
        return total + overlap.width * overlap.height;
      });
  var best = candidates.first;
  var bestScore = score(best);
  for (final candidate in candidates.skip(1)) {
    final candidateScore = score(candidate);
    if (candidateScore < bestScore) {
      best = candidate;
      bestScore = candidateScore;
    }
  }
  return best;
}

class _PressureOverviewPainter extends CustomPainter {
  final PressureWorld world;
  final Rect viewBounds;
  final bool portrait;
  final Brightness brightness;

  const _PressureOverviewPainter({
    required this.world,
    required this.viewBounds,
    required this.portrait,
    required this.brightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dark = brightness == Brightness.dark;
    final area = (Offset.zero & size).deflate(3);
    Offset point(double x, double y) => portrait
        ? Offset(area.right - y * area.width, area.bottom - x * area.height)
        : Offset(area.left + x * area.width, area.bottom - y * area.height);
    final line = Paint()
      ..color = dark ? const Color(0xFF94AEA2) : const Color(0xFF6A8476)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;
    canvas.drawRRect(
      BorderRadius.circular(4).toRRect(Offset.zero & size),
      Paint()..color = dark ? const Color(0xEE203A33) : const Color(0xEEF7FAF6),
    );
    canvas.drawRect(area, line);
    canvas.drawLine(point(.5, 0), point(.5, 1), line);
    canvas.drawCircle(
        area.center, math.min(area.width, area.height) * .13, line);
    final crop = Rect.fromPoints(point(viewBounds.left, viewBounds.top),
        point(viewBounds.right, viewBounds.bottom));
    canvas.drawRect(
        crop, Paint()..color = const Color(0xFF397DB2).withValues(alpha: .14));
    canvas.drawRect(
        crop,
        line
          ..color = const Color(0xFF397DB2)
          ..strokeWidth = 1.2);
    for (final actor in world.actors) {
      final p = _normalise(actor.position);
      canvas.drawCircle(
          point(p.x, p.y),
          1.8,
          Paint()
            ..color = actor.team == PressureTeam.attack
                ? const Color(0xFFC80F24)
                : const Color(0xFF486D96));
    }
    final ball = _normalise(world.ball.position);
    canvas.drawCircle(
        point(ball.x, ball.y), 2.1, Paint()..color = const Color(0xFFEDB942));
  }

  @override
  bool shouldRepaint(covariant _PressureOverviewPainter oldDelegate) =>
      oldDelegate.world != world ||
      oldDelegate.viewBounds != viewBounds ||
      oldDelegate.portrait != portrait ||
      oldDelegate.brightness != brightness;
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
    _pressureOverviewRect(geometry, world),
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
  final PressureActionEvidence? reviewEvidence;
  final AppLocalizations l10n;
  final Map<String, String> names;
  final Brightness brightness;
  final String? fontFamily;
  final Rect viewBounds;
  final PressureActorRole focusRole;
  final bool showSupportRange;
  final ScanPassPoint? supportTarget;

  const _PressureLessonPitchPainter({
    required this.displayWorld,
    required this.portrait,
    required this.completedTraces,
    required this.activeTrace,
    required this.activeProgress,
    required this.reviewResult,
    required this.reviewEvidence,
    required this.l10n,
    required this.names,
    required this.brightness,
    required this.fontFamily,
    required this.viewBounds,
    required this.focusRole,
    required this.showSupportRange,
    required this.supportTarget,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const episode = MatchMomentEpisode();
    final delegate = _MatchMomentPitchPainter(
      episode: episode,
      portrait: portrait,
      frame: _matchFrame(displayWorld, viewBounds),
      completedSegments: const [],
      activeSegment: null,
      activeSegmentProgress: 0,
      names: names,
      reference: false,
      brightness: brightness,
      fontFamily: fontFamily,
      viewBounds: viewBounds,
      emphasizePlayers: true,
    );
    delegate.paint(canvas, size);
    final geometry = _MatchPitchGeometry(
      size,
      portrait: portrait,
      viewBounds: viewBounds,
    );
    _drawFocus(canvas, geometry);
    _drawOffsideReference(canvas, geometry);
    for (final trace in completedTraces) {
      _drawTrace(canvas, geometry, trace, 1, active: false);
    }
    final active = activeTrace;
    if (active != null) {
      _drawTrace(canvas, geometry, active, activeProgress, active: true);
    }
    final review = reviewResult;
    final evidence = reviewEvidence;
    if (review != null && evidence != null) {
      _drawReview(canvas, geometry, review, evidence);
    }
  }

  void _drawFocus(Canvas canvas, _MatchPitchGeometry geometry) {
    final focus = displayWorld.actorByRole(focusRole);
    final point = geometry.toOffset(_normalise(focus.position));
    final accent = brightness == Brightness.dark
        ? const Color(0xFFFFD166)
        : const Color(0xFF7A4F00);
    canvas.drawCircle(
      point,
      19,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    if (showSupportRange) {
      canvas.drawCircle(
        point,
        8 * geometry.scale,
        Paint()
          ..color = accent.withValues(alpha: .36)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
    }
    final target = supportTarget;
    if (target != null) {
      final endpoint = geometry.toOffset(_normalise(target));
      final paint = Paint()
        ..color = accent.withValues(alpha: .9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      _pressureDrawDashedLine(canvas, point, endpoint, paint, dash: 6, gap: 4);
      _pressureDrawArrowHead(canvas, point, endpoint, paint);
      canvas.drawCircle(endpoint, 7, paint);
    }
    final label = TextPainter(
      text: TextSpan(
        text: l10n.pressureEpisodeLearnerMarker(focus.number),
        style: TextStyle(
          color: brightness == Brightness.dark
              ? const Color(0xFFF9F4E8)
              : const Color(0xFF302612),
          backgroundColor: (brightness == Brightness.dark
                  ? const Color(0xFF243033)
                  : const Color(0xFFFFFBED))
              .withValues(alpha: .88),
          fontFamily: fontFamily,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 100);
    label.paint(
      canvas,
      Offset(
        (point.dx - label.width / 2)
            .clamp(3.0, geometry.size.width - label.width - 3),
        (point.dy + 21).clamp(3.0, geometry.size.height - label.height - 3),
      ),
    );
  }

  void _drawOffsideReference(
    Canvas canvas,
    _MatchPitchGeometry geometry,
  ) {
    final reference =
        const ScanPassPressureEngine().offsideReferenceX(displayWorld);
    final normalisedReference =
        reference / ScanPassPressureEngine.fieldLengthMetres;
    final outsideAhead = normalisedReference > geometry.maxX;
    final outsideBehind = normalisedReference < geometry.minX;
    final drawnReference =
        normalisedReference.clamp(geometry.minX, geometry.maxX).toDouble();
    final from = geometry.toOffset(_normalise(
      ScanPassPoint(
        drawnReference * ScanPassPressureEngine.fieldLengthMetres,
        ScanPassPressureEngine.fieldWidthMetres * geometry.minY,
      ),
    ));
    final to = geometry.toOffset(_normalise(
      ScanPassPoint(
        drawnReference * ScanPassPressureEngine.fieldLengthMetres,
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
        text: outsideAhead || outsideBehind
            ? l10n.pressureLessonOffsideAhead
            : l10n.pressureLessonOffsideLine,
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
    if (outsideAhead || outsideBehind) {
      final forward = outsideAhead ? 1.0 : -1.0;
      final arrowPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final tip = geometry.vertical
          ? midpoint + Offset(0, -7 * forward)
          : midpoint + Offset(7 * forward, 0);
      final wingA = geometry.vertical
          ? tip + Offset(-4, 5 * forward)
          : tip + Offset(-5 * forward, -4);
      final wingB = geometry.vertical
          ? tip + Offset(4, 5 * forward)
          : tip + Offset(-5 * forward, 4);
      canvas.drawLine(tip, wingA, arrowPaint);
      canvas.drawLine(tip, wingB, arrowPaint);
    }
    var offset = geometry.vertical
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
    final occupied = [
      _pressureOverviewRect(geometry, displayWorld),
      for (final actor in displayWorld.actors)
        Rect.fromCenter(
          center: geometry.toOffset(_normalise(actor.position)) -
              const Offset(0, 8),
          width: 44,
          height: 56,
        ),
    ];
    for (final candidate in [
      offset,
      Offset(geometry.size.width - label.width - 8, offset.dy),
      Offset(8, offset.dy),
      offset + const Offset(0, 22),
      offset - const Offset(0, 22),
    ]) {
      final clamped = Offset(
        candidate.dx.clamp(4.0, geometry.size.width - label.width - 4),
        candidate.dy.clamp(4.0, geometry.size.height - label.height - 4),
      );
      if (!occupied.any((rect) => rect.overlaps(clamped & label.size))) {
        offset = clamped;
        break;
      }
    }
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
    PressureActionEvidence evidence,
  ) {
    final relevantRole = _pressureRelevantDefenderRole(result);
    final freezeClock = evidence.freezeFrame.clock;
    final frames = result.trace.frames
        .where((frame) => frame.clock <= freezeClock + 1e-9)
        .toList();
    if (frames.isEmpty) return;
    final routePoints = frames
        .map((frame) => geometry.toOffset(_normalise(frame.ball.position)))
        .toList();
    final routePaint = Paint()
      ..color = (brightness == Brightness.dark
              ? const Color(0xFFFFD166)
              : const Color(0xFF795B20))
          .withValues(alpha: .88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    if (result.action.kind == PressureActionKind.pass) {
      _pressureDrawDashedPolyline(canvas, routePoints, routePaint,
          dash: 7, gap: 4);
    } else {
      _pressureDrawPolyline(canvas, routePoints, routePaint);
    }
    if (routePoints.length > 1) {
      _pressureDrawArrowHead(
        canvas,
        _pressureArrowStart(routePoints),
        routePoints.last,
        routePaint,
      );
    }

    final originPaint = Paint()
      ..color = (brightness == Brightness.dark
              ? const Color(0xFFE9EEEB)
              : const Color(0xFF263A3D))
          .withValues(alpha: .34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(routePoints.first, 8, originPaint);

    final defenderPoints = frames
        .map((frame) => geometry
            .toOffset(_normalise(frame.actorByRole(relevantRole).position)))
        .toList();
    final defenderPaint = Paint()
      ..color = const Color(0xFFB15F49).withValues(alpha: .78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    _pressureDrawDashedPolyline(canvas, defenderPoints, defenderPaint,
        dash: 5, gap: 3);
    if (defenderPoints.length > 1) {
      _pressureDrawArrowHead(
        canvas,
        _pressureArrowStart(defenderPoints),
        defenderPoints.last,
        defenderPaint,
      );
    }
    canvas.drawCircle(defenderPoints.first, 9, originPaint);
    canvas.drawCircle(defenderPoints.last, 19, defenderPaint);

    final contactPoint = evidence.contactPoint;
    if (contactPoint != null) {
      final contact = geometry.toOffset(_normalise(contactPoint));
      final contactPaint = Paint()
        ..color = const Color(0xFFD85240)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4;
      canvas.drawCircle(contact, 8, contactPaint);
      canvas.drawLine(contact - const Offset(5, 5),
          contact + const Offset(5, 5), contactPaint);
      canvas.drawLine(contact + const Offset(-5, 5),
          contact + const Offset(5, -5), contactPaint);
    }

    if (evidence.benefit != PressureActionBenefit.openedSimulatedForwardLane) {
      return;
    }
    final carrier = result.after.carrier;
    final receiverNumber = evidence.benefitReceiverNumber;
    if (carrier == null || receiverNumber == null) return;
    PressureConnectionEvidence? connection;
    for (final value in result.assessment.connections) {
      if (value.safe &&
          result.after.actorByRole(value.receiverRole).number ==
              receiverNumber) {
        connection = value;
        break;
      }
    }
    if (connection == null) return;
    final from = geometry.toOffset(_normalise(carrier.position));
    final to = geometry.toOffset(_normalise(connection.target));
    final connectionPaint = Paint()
      ..color = (brightness == Brightness.dark
              ? const Color(0xFF8EC5FF)
              : const Color(0xFF315F78))
          .withValues(alpha: .56)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    _pressureDrawDashedLine(
      canvas,
      from,
      to,
      connectionPaint,
      dash: 7,
      gap: 5,
    );
    _pressureDrawArrowHead(canvas, from, to, connectionPaint);
  }

  @override
  bool shouldRepaint(covariant _PressureLessonPitchPainter oldDelegate) =>
      oldDelegate.displayWorld != displayWorld ||
      oldDelegate.portrait != portrait ||
      oldDelegate.completedTraces != completedTraces ||
      oldDelegate.activeTrace != activeTrace ||
      oldDelegate.activeProgress != activeProgress ||
      oldDelegate.reviewResult != reviewResult ||
      oldDelegate.reviewEvidence != reviewEvidence ||
      oldDelegate.l10n != l10n ||
      oldDelegate.viewBounds != viewBounds ||
      oldDelegate.brightness != brightness ||
      oldDelegate.fontFamily != fontFamily ||
      oldDelegate.focusRole != focusRole ||
      oldDelegate.showSupportRange != showSupportRange ||
      oldDelegate.supportTarget != supportTarget;
}

MatchMomentFrame _matchFrame(PressureWorld world, Rect viewBounds) =>
    MatchMomentFrame(
      actors: Map.unmodifiable({
        for (final actor in world.actors)
          if (viewBounds.contains(Offset(
              _normalise(actor.position).x, _normalise(actor.position).y)))
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

ScanPassPoint _normalise(ScanPassPoint metres) => ScanPassPoint(
      metres.x / ScanPassPressureEngine.fieldLengthMetres,
      metres.y / ScanPassPressureEngine.fieldWidthMetres,
    );

Rect _pressureObservationViewBounds(PressureObservation observation) {
  const engine = ScanPassPressureEngine();
  final options = engine.optionsFor(
    observation.decisionState,
    PressureDecisionStage.firstContact,
  );
  return _pressureDecisionViewBounds(
    observation.decisionState,
    options,
    observation: observation.trace,
  );
}

Rect _pressureDecisionViewBounds(
  PressureWorld decision,
  List<PressureDecisionOption> options, {
  PressureTrace? observation,
  PressureSimulationResult? reviewResult,
}) {
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

  final observed = observation;
  if (observed != null) {
    for (final frame in observed.frames) {
      include(frame.ball.position);
      include(frame.actorByRole(PressureActorRole.receiver).position);
      include(frame.actorByRole(PressureActorRole.presser).position);
    }
  }
  include(decision.ball.position);
  final review = reviewResult;
  final relevantPoints = <ScanPassPoint>[
    decision.ball.position,
    if (review == null)
      for (final option in options) option.action.target
    else
      review.action.target,
  ];
  if (review != null) {
    final evidence = const ScanPassPressureEngine().actionEvidence(review);
    if (evidence.benefit == PressureActionBenefit.openedSimulatedForwardLane) {
      for (final connection in review.assessment.connections) {
        if (connection.safe &&
            review.after.actorByRole(connection.receiverRole).number ==
                evidence.benefitReceiverNumber) {
          relevantPoints.add(connection.target);
        }
      }
    }
  }
  for (final point in relevantPoints) {
    include(point);
  }
  for (final actor in decision.actors) {
    final nearDecision = relevantPoints.any(
      (point) => actor.position.distanceTo(point) <= (review == null ? 11 : 8),
    );
    final alwaysRelevant = actor.id == decision.ball.carrierId ||
        actor.role == PressureActorRole.receiver ||
        actor.role == PressureActorRole.presser;
    if (!nearDecision && !alwaysRelevant) continue;
    include(actor.position);
    include(actor.position + actor.velocity * 1.15);
  }
  if (review != null) {
    include(review.before.ball.position);
    include(review.action.target);
    include(review.after.ball.position);
    final receiverRole = review.intendedReceiverRole;
    if (receiverRole != null) {
      include(review.before.actorByRole(receiverRole).position);
      include(review.after.actorByRole(receiverRole).position);
    }
    if (review.contact != null) include(review.contact!.point);
    final relevantRole = _pressureRelevantDefenderRole(review);
    include(review.before.actorByRole(relevantRole).position);
    include(review.after.actorByRole(relevantRole).position);
  }
  include(decision.ball.position + const ScanPassPoint(4, 0));

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
    review == null ? 3.2 : 4.5,
    review == null ? 28 : 18,
    ScanPassPressureEngine.fieldLengthMetres,
  );
  final y = fit(
    minY,
    maxY,
    3.2,
    review == null ? 22 : 16,
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
