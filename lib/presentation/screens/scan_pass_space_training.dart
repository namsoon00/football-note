part of 'scan_pass_game_screen.dart';

/// A single 3v2 possession in which the learner supplies every spatial action.
class SpaceTrainingScreen extends StatefulWidget {
  final int? seed;
  final WidgetBuilder? freeAttackBuilder;

  const SpaceTrainingScreen({super.key, this.seed, this.freeAttackBuilder});

  @override
  State<SpaceTrainingScreen> createState() => _SpaceTrainingScreenState();
}

class _SpaceTrainingScreenState extends State<SpaceTrainingScreen>
    with WidgetsBindingObserver {
  // Half-speed playback leaves time to read the same physical simulation.
  static const _simulationStep = .02;
  final SpaceEngine _engine = const SpaceEngine();
  final FocusNode _pitchFocus = FocusNode();
  final ScrollController _dockScroll = ScrollController();
  final ScrollController _pageScroll = ScrollController();
  late SpaceState _state;
  late int _seed;
  final List<SpaceState> _frames = [];
  Timer? _timer;
  ScanPassPoint? _draft;
  SpaceState? _previous;
  bool _playing = false;
  bool _hasMoved = false;
  bool _replaying = false;
  int _actionFrame = 0;
  int? _reviewFrame;
  double _sampleTime = 0;
  double _replayTime = 0;

  bool get _review => _state.finished;
  bool get _canAim =>
      !_review &&
      const [SpacePhase.positioning, SpacePhase.received, SpacePhase.releasing]
          .contains(_state.phase);
  bool get _continuous => const [SpacePhase.positioning, SpacePhase.releasing]
      .contains(_state.phase);
  SpaceState get _shown =>
      _reviewFrame == null ? _state : _frames[_reviewFrame!];
  ScanPassPoint? get _aim => switch (_state.phase) {
        SpacePhase.positioning => _state.receiveTarget,
        SpacePhase.incoming => _state.receiveTarget,
        SpacePhase.received => _draft,
        SpacePhase.touching => _state.touchTarget,
        SpacePhase.releasing => _draft,
        SpacePhase.outgoing => _state.passTarget,
        SpacePhase.complete =>
          _state.passTarget ?? _state.touchTarget ?? _state.receiveTarget,
      };
  ScanPassPoint? get _previousAim => switch (_state.phase) {
        SpacePhase.positioning ||
        SpacePhase.incoming =>
          _previous?.receiveTarget,
        SpacePhase.received || SpacePhase.touching => _previous?.touchTarget,
        _ => _previous?.passTarget,
      };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _seed = widget.seed ?? 0;
    _state = _engine.start(_engine.scenario(_seed));
    _frames.add(_state);
    _timer = Timer.periodic(const Duration(milliseconds: 40), (_) => _tick());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pitchFocus.dispose();
    _dockScroll.dispose();
    _pageScroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && mounted) {
      setState(() {
        _playing = false;
        _replaying = false;
      });
    }
  }

  void _tick() {
    if (!mounted) return;
    if (_replaying) {
      setState(() {
        _replayTime += _simulationStep;
        var next = _reviewFrame ?? _actionFrame;
        while (next < _frames.length - 1 &&
            _frames[next + 1].elapsed <= _replayTime) {
          next++;
        }
        if (next >= _frames.length - 1) {
          _replaying = false;
          _reviewFrame = null;
        } else {
          _reviewFrame = next;
        }
      });
    } else if (_playing && !_review) {
      _advance(_simulationStep);
    }
  }

  void _record({bool force = false}) {
    if (!force && _state.elapsed - _sampleTime < .075) return;
    _sampleTime = _state.elapsed;
    _frames.add(_state);
    // Keep the opening frame and the current action while bounding long waits.
    if (_frames.length > 2400) {
      _frames.removeRange(1, 301);
      _actionFrame = math.max(0, _actionFrame - 300);
    }
  }

  void _advance(double seconds) {
    final before = _state.phase;
    setState(() {
      _state = _engine.advance(_state, seconds);
      _record(force: before != _state.phase);
      if (_state.phase != before) {
        _draft = null;
        if (_state.phase == SpacePhase.received ||
            _state.phase == SpacePhase.releasing ||
            _state.finished) {
          _playing = false;
          _resetScroll();
        }
      }
    });
  }

  void _resetScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final scroll in [_dockScroll, _pageScroll]) {
        if (scroll.hasClients) scroll.jumpTo(0);
      }
    });
  }

  void _setAim(ScanPassPoint point) {
    if (!_canAim) return;
    var bounded =
        point.clampToField(minX: .06, maxX: .94, minY: .10, maxY: .90);
    if (_state.phase == SpacePhase.received) {
      final origin = _state.pitch.carrier.position;
      final metres = _engine.distanceMetres(origin, bounded);
      if (metres > 4) bounded = origin.lerp(bounded, 4 / metres);
    }
    setState(() {
      if (_state.phase == SpacePhase.positioning) {
        _state = _engine.aimReceive(_state, bounded);
      } else {
        _draft = bounded;
      }
    });
  }

  void _commit() {
    if (_aim == null || !_canAim) return;
    if (_state.phase == SpacePhase.positioning && !_hasMoved) {
      setState(() {
        _hasMoved = true;
        _playing = true;
      });
      return;
    }
    setState(() {
      _record(force: true);
      _actionFrame = _frames.length - 1;
      _state = switch (_state.phase) {
        SpacePhase.positioning => _engine.receive(_state),
        SpacePhase.received => _engine.touch(_state, _draft!),
        SpacePhase.releasing => _engine.pass(_state, _draft!),
        _ => _state,
      };
      _playing = !_state.finished;
      _draft = null;
      _record(force: true);
    });
  }

  void _newAttempt({required bool newLayout}) {
    setState(() {
      _previous = newLayout ? null : _state;
      if (newLayout) _seed++;
      _state = _engine.start(_engine.scenario(_seed));
      _draft = null;
      _playing = false;
      _hasMoved = false;
      _replaying = false;
      _reviewFrame = null;
      _actionFrame = 0;
      _sampleTime = 0;
      _frames
        ..clear()
        ..add(_state);
      _resetScroll();
    });
  }

  Future<void> _help(AppLocalizations l10n) async {
    setState(() {
      _playing = false;
      _replaying = false;
    });
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(l10n.spaceHelpTitle),
        content: Text(l10n.spaceHelpBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.spaceClose))
        ],
      ),
    );
  }

  String _instruction(AppLocalizations l10n) => switch (_state.phase) {
        SpacePhase.positioning => _state.receiveTarget == null
            ? l10n.spacePickReceive
            : _hasMoved
                ? l10n.spaceReadRun
                : l10n.spaceWatchRun,
        SpacePhase.incoming => l10n.spaceWatchArrival,
        SpacePhase.received => l10n.spacePickTouch,
        SpacePhase.touching => l10n.spaceTouching,
        SpacePhase.releasing => l10n.spacePickPass,
        SpacePhase.outgoing => l10n.spaceWatchPass,
        SpacePhase.complete => l10n.spaceReviewInstruction,
      };

  String _outcome(AppLocalizations l10n) => switch (_state.outcome) {
        SpaceOutcome.open => l10n.spaceOutcomeOpen,
        SpaceOutcome.pressured => l10n.spaceOutcomePressured,
        SpaceOutcome.intercepted => l10n.spaceOutcomeIntercepted,
        SpaceOutcome.unreachable => l10n.spaceOutcomeUnreachable,
        null => l10n.spaceOutcomePressured,
      };

  String _reason(AppLocalizations l10n) => switch (_state.reason) {
        SpaceReason.spaceHeld => l10n.spaceReasonHeld,
        SpaceReason.defenderArrived => l10n.spaceReasonDefender,
        SpaceReason.receiverLate => l10n.spaceReasonLate,
        SpaceReason.closedLane => l10n.spaceReasonLane,
        SpaceReason.touchIntoPressure => l10n.spaceReasonTouch,
        null => l10n.spaceReasonDefender,
      };

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (!_canAim || event is! KeyDownEvent) return KeyEventResult.ignored;
    final delta = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => const ScanPassPoint(-.025, 0),
      LogicalKeyboardKey.arrowRight => const ScanPassPoint(.025, 0),
      LogicalKeyboardKey.arrowUp => const ScanPassPoint(0, -.0375),
      LogicalKeyboardKey.arrowDown => const ScanPassPoint(0, .0375),
      _ => null,
    };
    if (delta != null) {
      _setAim((_aim ??
              _state.pitch.attackers
                  .firstWhere((p) => p.number == 6)
                  .position) +
          delta);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _commit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = _ScanPassColors.of(context);
    final phaseIndex = switch (_state.phase) {
      SpacePhase.positioning || SpacePhase.incoming => 0,
      SpacePhase.received || SpacePhase.touching => 1,
      _ => 2,
    };
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.spaceTitle),
        actions: [
          if (widget.freeAttackBuilder != null)
            TextButton.icon(
              key: const ValueKey('space-free-attack'),
              onPressed: () async {
                setState(() {
                  _playing = false;
                  _replaying = false;
                });
                await Navigator.of(context).push<void>(
                    MaterialPageRoute(builder: widget.freeAttackBuilder!));
              },
              icon: const Icon(Icons.sports_soccer_outlined, size: 18),
              label: Text(l10n.scanPassFreeAttackAction),
            ),
          IconButton(
              key: const ValueKey('space-help'),
              tooltip: l10n.spaceHelpTitle,
              onPressed: () => _help(l10n),
              icon: const Icon(Icons.help_outline)),
        ],
      ),
      body: SafeArea(child: LayoutBuilder(builder: (context, bounds) {
        final wide = bounds.maxWidth >= 900;
        final landscape = bounds.maxWidth > bounds.maxHeight * 1.45;
        final labels = [
          l10n.spaceStepReceive,
          l10n.spaceStepTouch,
          l10n.spaceStepPass
        ];
        final instruction = Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(12)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              for (var i = 0; i < labels.length; i++) ...[
                if (i != 0)
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.chevron_right,
                          size: 14, color: colors.muted)),
                Flexible(
                    child: Text(labels[i],
                        maxLines: 1,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                                color: i == phaseIndex
                                    ? colors.accent
                                    : colors.muted,
                                fontWeight: i == phaseIndex
                                    ? FontWeight.w800
                                    : FontWeight.w400))),
              ],
            ]),
            const SizedBox(height: 7),
            Text(_instruction(l10n),
                key: const ValueKey('space-instruction'),
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(height: 1.4)),
          ]),
        );
        final pitch = _pitch(l10n, colors);
        final dock = _dock(l10n, colors);
        if (wide || (landscape && bounds.maxWidth >= 560)) {
          return Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(
                    child: Column(children: [
                  if (bounds.maxHeight >= 430) ...[
                    instruction,
                    const SizedBox(height: 10)
                  ],
                  Expanded(
                      child: Center(
                          child: AspectRatio(aspectRatio: 1.5, child: pitch))),
                ])),
                const SizedBox(width: 14),
                SizedBox(
                    width: wide ? 292 : 206,
                    child: SingleChildScrollView(
                        controller: _dockScroll,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (bounds.maxHeight < 430) ...[
                                instruction,
                                const SizedBox(height: 10)
                              ],
                              dock,
                            ]))),
              ]));
        }
        return SingleChildScrollView(
            controller: _pageScroll,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: bounds.maxHeight),
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      instruction,
                      const SizedBox(height: 12),
                      AspectRatio(aspectRatio: 1.5, child: pitch),
                      const SizedBox(height: 12),
                      dock,
                    ],
                  )),
            ));
      })),
    );
  }

  Widget _pitch(AppLocalizations l10n, _ScanPassColors colors) {
    return LayoutBuilder(builder: (context, bounds) {
      final geometry =
          _PitchGeometry(Size(bounds.maxWidth, bounds.maxHeight), space: true);
      final frame = _shown;
      return Focus(
        focusNode: _pitchFocus,
        onKeyEvent: _key,
        child: Semantics(
          key: const ValueKey('space-pitch-semantics'),
          label: l10n.spacePitchDescription,
          value: _instruction(l10n),
          focusable: true,
          onDidGainAccessibilityFocus: _pitchFocus.requestFocus,
          child: GestureDetector(
            key: const ValueKey('space-pitch'),
            // A semantic tap has no ground coordinate and is synthesized at
            // the node's centre on web. Keep pointer geometry on the canvas;
            // the enclosing focus node provides keyboard access.
            excludeFromSemantics: true,
            behavior: HitTestBehavior.opaque,
            onTapDown: !_canAim
                ? null
                : (details) {
                    _pitchFocus.requestFocus();
                    final point = details.localPosition;
                    if (!geometry.fieldRect.contains(point)) return;
                    _setAim(ScanPassPoint(
                      (point.dx - geometry.fieldRect.left) /
                          geometry.fieldRect.width,
                      (point.dy - geometry.fieldRect.top) /
                          geometry.fieldRect.height,
                    ));
                  },
            child: CustomPaint(
              key: const ValueKey('space-painter'),
              painter: _SpacePitchPainter(
                state: frame,
                selectedTarget: _aim,
                previousTarget: _previousAim,
                reviewFrames: _review
                    ? _frames.sublist(
                        _actionFrame, (_reviewFrame ?? _frames.length - 1) + 1)
                    : const [],
                showReview: _review,
                labels: _PitchLabels.from(l10n),
                l10n: l10n,
                brightness: Theme.of(context).brightness,
                fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
    });
  }

  Widget _dock(AppLocalizations l10n, _ScanPassColors colors) {
    if (_review) return _reviewDock(l10n, colors);
    final picking = _canAim;
    final aimLabel = switch (_state.phase) {
      SpacePhase.positioning || SpacePhase.incoming => l10n.spaceReceiveTarget,
      SpacePhase.received || SpacePhase.touching => l10n.spaceTouchTarget,
      _ => l10n.spacePassTarget,
    };
    final primary = switch (_state.phase) {
      SpacePhase.positioning =>
        _hasMoved ? l10n.spaceReceiveNow : l10n.spaceStartRun,
      SpacePhase.received => l10n.spaceExecuteTouch,
      SpacePhase.releasing => l10n.spacePassNow,
      _ => l10n.spaceInMotion,
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l10n.spaceContext, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 10),
      Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(12)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(_aim == null ? Icons.touch_app_outlined : Icons.my_location,
                color: colors.accent, size: 20),
            const SizedBox(width: 9),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(aimLabel, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                      _aim == null
                          ? l10n.spaceTapGround
                          : l10n.spaceTargetNeutral,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colors.muted, height: 1.4)),
                ])),
          ])),
      const SizedBox(height: 12),
      FilledButton.icon(
        key: const ValueKey('space-commit'),
        onPressed: picking && _aim != null ? _commit : null,
        style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: colors.accent,
            foregroundColor: Colors.white),
        icon: Icon(
            _state.phase == SpacePhase.positioning && !_hasMoved
                ? Icons.directions_run
                : Icons.near_me_outlined,
            size: 19),
        label: Text(primary),
      ),
      const SizedBox(height: 8),
      if (_hasMoved || !picking)
        Row(children: [
          Expanded(
              child: OutlinedButton.icon(
            key: const ValueKey('space-pause'),
            onPressed: () => setState(() => _playing = !_playing),
            icon: Icon(_playing ? Icons.pause : Icons.play_arrow, size: 18),
            label: Text(_playing ? l10n.spacePause : l10n.spaceResume),
          )),
          const SizedBox(width: 8),
          IconButton.outlined(
            key: const ValueKey('space-step'),
            tooltip: l10n.spaceStepMotion,
            onPressed: () {
              setState(() => _playing = false);
              _advance(.20);
            },
            icon: const Icon(Icons.skip_next_outlined, size: 20),
          ),
        ]),
      if (!_playing && _hasMoved && _continuous)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(l10n.spacePausedNote,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.muted)),
        ),
      const SizedBox(height: 12),
      Text(l10n.spaceLegend,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: colors.muted, height: 1.5)),
      if (_previousAim != null)
        Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(l10n.spacePreviousNote,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.muted))),
      const SizedBox(height: 10),
      TextButton.icon(
          key: const ValueKey('space-restart'),
          onPressed: () => _newAttempt(newLayout: false),
          icon: const Icon(Icons.restart_alt, size: 18),
          label: Text(l10n.spaceRestart)),
    ]);
  }

  Widget _reviewDock(AppLocalizations l10n, _ScanPassColors colors) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(12)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_outcome(l10n),
                key: const ValueKey('space-outcome'),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(_reason(l10n),
                key: const ValueKey('space-reason'),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.45)),
            const SizedBox(height: 10),
            Text(l10n.spaceReviewLegend,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.muted, height: 1.5)),
          ])),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: OutlinedButton(
                key: const ValueKey('space-at-choice'),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
                onPressed: () => setState(() {
                      _replaying = false;
                      _reviewFrame = _actionFrame;
                      _replayTime = _frames[_actionFrame].elapsed;
                    }),
                child: Text(l10n.spaceAtChoice))),
        const SizedBox(width: 8),
        Expanded(
            child: OutlinedButton(
                key: const ValueKey('space-at-arrival'),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
                onPressed: () => setState(() {
                      _replaying = false;
                      _reviewFrame = null;
                    }),
                child: Text(l10n.spaceAtArrival))),
      ]),
      Slider(
          key: const ValueKey('space-timeline'),
          min: _actionFrame.toDouble(),
          max: (_frames.length - 1).toDouble(),
          value: (_reviewFrame ?? _frames.length - 1).toDouble(),
          semanticFormatterCallback: (value) => value < _frames.length - 1
              ? l10n.spaceAtChoice
              : l10n.spaceAtArrival,
          onChanged: (value) => setState(() {
                _replaying = false;
                _reviewFrame = value.round();
              })),
      OutlinedButton.icon(
          key: const ValueKey('space-replay'),
          onPressed: () => setState(() {
                _reviewFrame = _actionFrame;
                _replayTime = _frames[_actionFrame].elapsed;
                _replaying = true;
              }),
          icon: const Icon(Icons.replay, size: 18),
          label: Text(l10n.spaceReplay)),
      const SizedBox(height: 10),
      FilledButton(
          key: const ValueKey('space-retry'),
          onPressed: () => _newAttempt(newLayout: false),
          style: FilledButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48)),
          child: Text(l10n.spaceRetry)),
      const SizedBox(height: 8),
      TextButton.icon(
          key: const ValueKey('space-new-layout'),
          onPressed: () => _newAttempt(newLayout: true),
          icon: const Icon(Icons.shuffle, size: 18),
          label: Text(l10n.spaceNewLayout)),
    ]);
  }
}

class _SpacePitchPainter extends CustomPainter {
  final SpaceState state;
  final ScanPassPoint? selectedTarget;
  final ScanPassPoint? previousTarget;
  final List<SpaceState> reviewFrames;
  final bool showReview;
  final _PitchLabels labels;
  final AppLocalizations l10n;
  final Brightness brightness;
  final String? fontFamily;

  const _SpacePitchPainter(
      {required this.state,
      required this.selectedTarget,
      required this.previousTarget,
      required this.reviewFrames,
      required this.showReview,
      required this.labels,
      required this.l10n,
      required this.brightness,
      required this.fontFamily});

  @override
  void paint(Canvas canvas, Size size) {
    final g = _PitchGeometry(size, space: true);
    final p = _AttackPitchPainter(
        displayState: state.pitch,
        baseState: state.pitch,
        selectedAction: null,
        selectedTarget: null,
        previewOffside: null,
        activeTransition: state.ballInFlight || state.finished
            ? AttackTransition(
                before: state.pitch,
                after: state.pitch,
                action: const AttackAction.pass(6),
                duration: 1,
                ballEnd: state.pitch.ball)
            : null,
        activeProgress: state.elapsed % 1,
        history: const [],
        scanOverlay: false,
        terminalBanner: false,
        labels: labels,
        brightness: brightness,
        fontFamily: fontFamily,
        learnerNumber: 6);
    canvas.drawRRect(BorderRadius.circular(12).toRRect(Offset.zero & size),
        Paint()..color = p._pitch);
    for (var i = 0; i < 6; i += 2) {
      canvas.drawRect(
          Rect.fromLTWH(g.fieldRect.left + g.fieldRect.width * i / 6,
              g.fieldRect.top, g.fieldRect.width / 6, g.fieldRect.height),
          Paint()..color = p._stripe.withValues(alpha: .65));
    }
    canvas.drawRect(
        g.fieldRect,
        Paint()
          ..color = p._line.withValues(alpha: .65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1);
    p._drawText(canvas, l10n.spacePitchHeader,
        Offset(g.fieldRect.left, size.height * .025),
        color: p._muted, fontSize: 11);
    p._drawText(canvas, labels.attackRight,
        Offset(g.fieldRect.right, size.height * .025),
        color: p._muted, fontSize: 10, anchorMode: _TextAnchor.right);

    if (state.phase == SpacePhase.received) {
      final c = g.toOffset(state.pitch.carrier.position);
      canvas.drawOval(
          Rect.fromCenter(
              center: c,
              width: g.fieldRect.width * 8 / 30,
              height: g.fieldRect.height * 8 / 20),
          Paint()..color = p._team.withValues(alpha: .055));
      canvas.drawOval(
          Rect.fromCenter(
              center: c,
              width: g.fieldRect.width * 8 / 30,
              height: g.fieldRect.height * 8 / 20),
          Paint()
            ..color = p._team.withValues(alpha: .35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
    }
    if (showReview && reviewFrames.isNotEmpty) {
      for (final number in [2, 3]) {
        final path = Path();
        for (var i = 0; i < reviewFrames.length; i++) {
          final defender = reviewFrames[i]
              .pitch
              .defenders
              .firstWhere((d) => d.number == number);
          final point = g.toOffset(defender.position);
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        canvas.drawPath(
            path,
            Paint()
              ..color = p._defender.withValues(alpha: .6)
              ..strokeWidth = 2
              ..style = PaintingStyle.stroke);
      }
      final ballPath = Path();
      for (var i = 0; i < reviewFrames.length; i++) {
        final point = g.toOffset(reviewFrames[i].pitch.ball);
        if (i == 0) {
          ballPath.moveTo(point.dx, point.dy);
        } else {
          ballPath.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(
          ballPath,
          Paint()
            ..color = p._accent.withValues(alpha: .55)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke);
    }
    if (previousTarget != null) {
      canvas.drawCircle(
          g.toOffset(previousTarget!),
          11,
          Paint()
            ..color = p._muted.withValues(alpha: .4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
    if (selectedTarget != null) {
      final target = g.toOffset(selectedTarget!);
      final origin = state.phase == SpacePhase.positioning
          ? state.pitch.attackers.firstWhere((a) => a.number == 6).position
          : state.pitch.ball;
      p._drawDashedLine(
          canvas,
          g.toOffset(origin),
          target,
          Paint()
            ..color = p._accent.withValues(alpha: .6)
            ..strokeWidth = 1.5,
          dash: 4,
          gap: 4);
      canvas.drawCircle(
          target, 12, Paint()..color = p._accent.withValues(alpha: .11));
      canvas.drawCircle(
          target,
          12,
          Paint()
            ..color = p._accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.7);
      canvas.drawLine(
          target - const Offset(5, 0),
          target + const Offset(5, 0),
          Paint()
            ..color = p._accent
            ..strokeWidth = 1.5);
      canvas.drawLine(
          target - const Offset(0, 5),
          target + const Offset(0, 5),
          Paint()
            ..color = p._accent
            ..strokeWidth = 1.5);
    }
    for (final actor in [...state.pitch.defenders, ...state.pitch.attackers]) {
      final jersey = actor.opponent ? p._defender : p._team;
      final speed = actor.velocity.x.abs() + actor.velocity.y.abs();
      if (speed > .001 && !showReview) {
        final from = g.toOffset(actor.position);
        final to = g.toOffset(actor.position + actor.velocity * .65);
        final paint = Paint()
          ..color = jersey.withValues(alpha: .5)
          ..strokeWidth = 1.4;
        canvas.drawLine(from, to, paint);
        p._drawArrowHead(canvas, from, to, paint);
      }
      p._drawPlayer(canvas, g, actor,
          jersey: jersey,
          shorts: actor.opponent
              ? const Color(0xFF783B31)
              : const Color(0xFF174E66),
          textColor: Colors.white,
          current: !actor.opponent &&
              !state.ballInFlight &&
              !state.finished &&
              actor.number == state.pitch.carrierNumber);
      if (actor.number == 6 && !actor.opponent) {
        p._drawText(
            canvas,
            l10n.spaceLearner,
            g.toOffset(actor.position) -
                Offset(0, math.max(20, size.shortestSide * .07)),
            color: p._text,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            anchorMode: _TextAnchor.center);
      }
    }
    p._drawBall(canvas, g);
    if (showReview && state.reception != null) {
      final r = state.reception!;
      final from = g.toOffset(r.defenderArrival);
      final to = g.toOffset(r.target);
      canvas.drawLine(
          from,
          to,
          Paint()
            ..color = p._defender.withValues(alpha: .65)
            ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant _SpacePitchPainter oldDelegate) =>
      state != oldDelegate.state ||
      selectedTarget != oldDelegate.selectedTarget ||
      previousTarget != oldDelegate.previousTarget ||
      showReview != oldDelegate.showReview ||
      reviewFrames != oldDelegate.reviewFrames ||
      brightness != oldDelegate.brightness ||
      l10n != oldDelegate.l10n;
}
