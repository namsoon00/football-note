part of 'scan_pass_game_screen.dart';

/// The learner stays with number 6, including the movement after a pass.
class TouchChainTrainingScreen extends StatefulWidget {
  final int? seed;
  final WidgetBuilder? freeAttackBuilder;

  const TouchChainTrainingScreen(
      {super.key, this.seed, this.freeAttackBuilder});

  @override
  State<TouchChainTrainingScreen> createState() =>
      _TouchChainTrainingScreenState();
}

class _TouchChainTrainingScreenState extends State<TouchChainTrainingScreen>
    with WidgetsBindingObserver {
  static const _step = .02;
  final _engine = const TouchChainEngine();
  final _pitchFocus = FocusNode();
  final _pageScroll = ScrollController();
  final _dockScroll = ScrollController();
  final List<ChainState> _frames = [];
  late ChainState _state;
  late int _seed;
  Timer? _timer;
  ScanPassPoint? _draft;
  int? _receiver;
  ChainActionKind _mode = ChainActionKind.pass;
  bool _playing = false;
  bool _replaying = false;
  int? _reviewMoment;
  int? _reviewFrame;
  double _replayTime = 0;
  double _sampleTime = 0;

  bool get _picking => const [
        ChainPhase.prepareTouch,
        ChainPhase.decide,
        ChainPhase.prepareRun,
      ].contains(_state.phase);
  bool get _moving => !_picking && !_state.finished;
  AttackPlayer get _learner =>
      _state.pitch.attackers.firstWhere((player) => player.number == 6);
  double get _radius => switch (_state.phase) {
        ChainPhase.prepareTouch => 3,
        ChainPhase.prepareRun => 7,
        _ => _mode == ChainActionKind.turn ? 1.5 : 4,
      };
  ChainSnapshot? get _snapshot =>
      _reviewMoment == null ? null : _state.moments[_reviewMoment!];
  ChainState get _shownState =>
      _reviewFrame == null ? _state : _frames[_reviewFrame!];
  AttackState get _shownPitch => _snapshot?.pitch ?? _shownState.pitch;
  ScanPassPoint? get _target {
    if (_snapshot != null) return _snapshot!.target;
    if (_reviewFrame != null) return null;
    if (_picking) return _draft;
    return switch (_state.phase) {
      ChainPhase.receiving || ChainPhase.touching => _state.touchTarget,
      ChainPhase.running => _state.runTarget,
      ChainPhase.acting => _state.action?.target,
      _ => null,
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _seed = widget.seed ?? 0;
    _state = _engine.start(seed: _seed);
    _frames.add(_state);
    _timer = Timer.periodic(const Duration(milliseconds: 40), (_) => _tick());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pitchFocus.dispose();
    _pageScroll.dispose();
    _dockScroll.dispose();
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
        _replayTime += _step;
        var next = _reviewFrame ?? 0;
        while (next < _frames.length - 1 &&
            _frames[next + 1].elapsed <= _replayTime) {
          next++;
        }
        _reviewFrame = next;
        if (next == _frames.length - 1) _replaying = false;
      });
    } else if (_playing && _moving) {
      _advance(_step);
    }
  }

  void _record({bool force = false}) {
    if (!force && _state.elapsed - _sampleTime < .075) return;
    _sampleTime = _state.elapsed;
    _frames.add(_state);
    // Bound long carry/turn sequences without changing the live simulation.
    if (_frames.length > 3000) _frames.removeRange(1, 301);
  }

  void _advance(double seconds) {
    final before = _state.phase;
    setState(() {
      _state = _engine.advance(_state, seconds);
      _record(force: before != _state.phase);
      if (_picking || _state.finished) {
        _playing = false;
        _draft = null;
        _receiver = null;
        _mode = ChainActionKind.pass;
        if (before != _state.phase) _resetScroll();
      }
    });
  }

  void _resetScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final controller in [_pageScroll, _dockScroll]) {
        if (controller.hasClients) controller.jumpTo(0);
      }
    });
  }

  void _choosePass(int number) {
    if (_state.phase != ChainPhase.decide) return;
    setState(() {
      _mode = ChainActionKind.pass;
      _receiver = number;
      _draft = _state.pitch.attackers
          .firstWhere((player) => player.number == number)
          .position;
    });
  }

  void _selectPoint(ScanPassPoint point, {bool allowReceiver = true}) {
    if (!_picking) return;
    if (_state.phase == ChainPhase.decide && allowReceiver) {
      for (final player in _state.pitch.attackers) {
        if (player.number != 6 &&
            _engine.distanceMetres(player.position, point) < 1.25) {
          _choosePass(player.number);
          return;
        }
      }
    }
    setState(() {
      if (_state.phase == ChainPhase.decide && _mode == ChainActionKind.pass) {
        _mode = ChainActionKind.carry;
      }
      _receiver = null;
      final bounded =
          point.clampToField(minX: .04, maxX: .96, minY: .06, maxY: .94);
      final metres = _engine.distanceMetres(_learner.position, bounded);
      _draft = metres > _radius
          ? _learner.position.lerp(bounded, _radius / metres)
          : bounded;
    });
  }

  void _commit() {
    if (!_picking || _draft == null) return;
    setState(() {
      _record(force: true);
      _state = switch (_state.phase) {
        ChainPhase.prepareTouch => _engine.takeTouch(_state, _draft!),
        ChainPhase.prepareRun => _engine.run(_state, _draft!),
        ChainPhase.decide => _engine.act(
            _state,
            switch (_mode) {
              ChainActionKind.pass => ChainAction.pass(_receiver!),
              ChainActionKind.carry => ChainAction.carry(_draft!),
              ChainActionKind.turn => ChainAction.turn(_draft!),
            }),
        _ => _state,
      };
      _draft = null;
      _receiver = null;
      _playing = _moving;
      _record(force: true);
    });
  }

  void _restart({bool newLayout = false}) {
    setState(() {
      if (newLayout) _seed++;
      _state = _engine.start(seed: _seed);
      _draft = null;
      _receiver = null;
      _mode = ChainActionKind.pass;
      _playing = false;
      _replaying = false;
      _reviewFrame = null;
      _reviewMoment = null;
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
        title: Text(l10n.chainHelpTitle),
        content: Text(l10n.chainHelpBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.spaceClose))
        ],
      ),
    );
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (!_picking || event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_state.phase == ChainPhase.decide) {
      if (event.logicalKey == LogicalKeyboardKey.digit4 ||
          event.logicalKey == LogicalKeyboardKey.digit8) {
        _choosePass(event.logicalKey == LogicalKeyboardKey.digit4 ? 4 : 8);
        return KeyEventResult.handled;
      }
    }
    final delta = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => const ScanPassPoint(-.015, 0),
      LogicalKeyboardKey.arrowRight => const ScanPassPoint(.015, 0),
      LogicalKeyboardKey.arrowUp => const ScanPassPoint(0, -.0225),
      LogicalKeyboardKey.arrowDown => const ScanPassPoint(0, .0225),
      _ => null,
    };
    if (delta != null) {
      final origin =
          _receiver == null ? _draft ?? _learner.position : _learner.position;
      _selectPoint(origin + delta, allowReceiver: false);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _commit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  int get _stage => switch (_state.phase) {
        ChainPhase.prepareTouch ||
        ChainPhase.receiving ||
        ChainPhase.touching =>
          0,
        ChainPhase.decide || ChainPhase.acting => 1,
        _ => 2,
      };

  String _instruction(AppLocalizations l10n) => switch (_state.phase) {
        ChainPhase.prepareTouch =>
          _state.returning ? l10n.chainPickReturnTouch : l10n.chainPickTouch,
        ChainPhase.receiving => l10n.chainWatchIncoming,
        ChainPhase.touching => l10n.chainWatchTouch,
        ChainPhase.decide => _mode == ChainActionKind.turn
            ? l10n.chainPickTurn
            : _mode == ChainActionKind.carry
                ? l10n.chainPickCarry
                : l10n.chainPickAction,
        ChainPhase.acting => l10n.chainWatchAction,
        ChainPhase.prepareRun => l10n.chainPickRun,
        ChainPhase.running => l10n.chainWatchRun,
        ChainPhase.complete => l10n.chainReviewInstruction,
      };

  String _momentLabel(AppLocalizations l10n, ChainSnapshot moment) {
    final label = switch (moment.moment) {
      ChainMoment.beforeTouch => l10n.chainBeforeTouch,
      ChainMoment.afterTouch => l10n.chainAfterTouch,
      ChainMoment.afterAction => l10n.chainAfterAction,
      ChainMoment.afterRun => l10n.chainAfterRun,
      ChainMoment.returnReady => l10n.chainReturnReady,
    };
    return l10n.chainMomentLabel(moment.cycle + 1, label);
  }

  String _outcome(AppLocalizations l10n) => switch (_state.end) {
        ChainEnd.linked => l10n.chainEndLinked,
        ChainEnd.lostTouch => l10n.chainEndTouch,
        ChainEnd.intercepted => l10n.chainEndIntercepted,
        ChainEnd.crowded => l10n.chainEndCrowded,
        ChainEnd.noReturnLane => l10n.chainEndLane,
        ChainEnd.supportPressed => l10n.chainEndSupport,
        null => l10n.chainReviewInstruction,
      };

  String _reason(AppLocalizations l10n) => switch (_state.end) {
        ChainEnd.linked => l10n.chainReasonLinked,
        ChainEnd.lostTouch => l10n.chainReasonTouch,
        ChainEnd.intercepted => l10n.chainReasonIntercepted,
        ChainEnd.crowded => l10n.chainReasonCrowded,
        ChainEnd.noReturnLane => l10n.chainReasonLane,
        ChainEnd.supportPressed => l10n.chainReasonSupport,
        null => l10n.chainReviewInstruction,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = _ScanPassColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(l10n.chainTitle),
        actions: [
          if (widget.freeAttackBuilder != null)
            IconButton(
              key: const ValueKey('chain-free-attack'),
              tooltip: l10n.scanPassFreeAttackAction,
              icon: const Icon(Icons.sports_soccer_outlined),
              onPressed: () async {
                setState(() {
                  _playing = false;
                  _replaying = false;
                });
                await Navigator.of(context).push<void>(
                    MaterialPageRoute(builder: widget.freeAttackBuilder!));
              },
            ),
          IconButton(
              key: const ValueKey('chain-help'),
              tooltip: l10n.chainHelpTitle,
              onPressed: () => _help(l10n),
              icon: const Icon(Icons.help_outline)),
        ],
      ),
      body: SafeArea(child: LayoutBuilder(builder: (context, bounds) {
        final wide = bounds.maxWidth >= 900;
        final landscape =
            bounds.maxWidth >= 560 && bounds.maxWidth > bounds.maxHeight * 1.45;
        final instruction = _header(l10n, colors);
        final pitch = _pitch(l10n);
        final dock = _state.finished
            ? _reviewDock(l10n, colors)
            : _actionDock(l10n, colors);
        if (wide || landscape) {
          return Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(
                child: Column(children: [
                  if (bounds.maxHeight >= 430) ...[
                    instruction,
                    const SizedBox(height: 12),
                  ],
                  Expanded(
                      child: Center(
                          child: AspectRatio(aspectRatio: 1.5, child: pitch))),
                ]),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: wide ? 296 : 208,
                child: SingleChildScrollView(
                  controller: _dockScroll,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (bounds.maxHeight < 430) ...[
                          instruction,
                          const SizedBox(height: 12),
                        ],
                        dock,
                      ]),
                ),
              ),
            ]),
          );
        }
        return SingleChildScrollView(
          controller: _pageScroll,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  instruction,
                  const SizedBox(height: 12),
                  AspectRatio(aspectRatio: 1.5, child: pitch),
                  const SizedBox(height: 14),
                  dock,
                ]),
          ),
        );
      })),
    );
  }

  Widget _header(AppLocalizations l10n, _ScanPassColors colors) {
    final stages = [
      l10n.chainStepTouch,
      l10n.chainStepAction,
      l10n.chainStepRun
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        for (var i = 0; i < stages.length; i++) ...[
          if (i > 0)
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child:
                    Icon(Icons.chevron_right, size: 15, color: colors.muted)),
          Flexible(
              child: Text(stages[i],
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: i == _stage && !_state.finished
                          ? colors.accent
                          : colors.muted,
                      fontWeight:
                          i == _stage ? FontWeight.w800 : FontWeight.w400))),
        ]
      ]),
      const SizedBox(height: 9),
      Text(_instruction(l10n),
          key: const ValueKey('chain-instruction'),
          style:
              Theme.of(context).textTheme.titleSmall?.copyWith(height: 1.45)),
      if (_state.finished) ...[
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (var i = 0; i < _state.moments.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  key: ValueKey('chain-moment-$i'),
                  label: Text(_momentLabel(l10n, _state.moments[i])),
                  selected: _reviewMoment == i,
                  showCheckmark: false,
                  onSelected: (_) => setState(() {
                    _replaying = false;
                    _reviewFrame = null;
                    _reviewMoment = i;
                  }),
                ),
              ),
          ]),
        ),
      ],
    ]);
  }

  Widget _pitch(AppLocalizations l10n) =>
      LayoutBuilder(builder: (context, bounds) {
        final geometry = _PitchGeometry(Size(bounds.maxWidth, bounds.maxHeight),
            space: true);
        void point(Offset local, {bool allowReceiver = true}) {
          if (!geometry.fieldRect.contains(local)) return;
          _pitchFocus.requestFocus();
          _selectPoint(
              ScanPassPoint(
                  (local.dx - geometry.fieldRect.left) /
                      geometry.fieldRect.width,
                  (local.dy - geometry.fieldRect.top) /
                      geometry.fieldRect.height),
              allowReceiver: allowReceiver);
        }

        return Focus(
          focusNode: _pitchFocus,
          onKeyEvent: _key,
          child: Semantics(
            key: const ValueKey('chain-pitch-semantics'),
            label: l10n.chainPitchDescription,
            value: _instruction(l10n),
            focusable: true,
            onDidGainAccessibilityFocus: _pitchFocus.requestFocus,
            child: GestureDetector(
              key: const ValueKey('chain-pitch'),
              // Web semantic taps synthesize the node centre. Spatial input
              // must use real pointer coordinates; keyboard access is above.
              excludeFromSemantics: true,
              behavior: HitTestBehavior.opaque,
              onTapDown: _picking ? (d) => point(d.localPosition) : null,
              onPanStart: _picking
                  ? (d) => point(d.localPosition, allowReceiver: false)
                  : null,
              onPanUpdate: _picking
                  ? (d) => point(d.localPosition, allowReceiver: false)
                  : null,
              child: CustomPaint(
                key: const ValueKey('chain-painter'),
                painter: _ChainPitchPainter(
                  state: _shownState,
                  pitch: _shownPitch,
                  selectedTarget: _target,
                  selectedReceiver: _receiver,
                  radius: _picking &&
                          (_state.phase != ChainPhase.decide ||
                              _mode != ChainActionKind.pass)
                      ? _radius
                      : null,
                  review: _state.finished,
                  reviewFrames: _state.finished
                      ? _frames
                          .where((f) => f.elapsed <= _shownPitch.elapsed)
                          .toList()
                      : const [],
                  labels: _PitchLabels.from(l10n),
                  l10n: l10n,
                  brightness: Theme.of(context).brightness,
                  fontFamily:
                      Theme.of(context).textTheme.bodyMedium?.fontFamily,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
      });

  Widget _actionDock(AppLocalizations l10n, _ScanPassColors colors) {
    final deciding = _state.phase == ChainPhase.decide;
    final heading = switch (_state.phase) {
      ChainPhase.prepareTouch ||
      ChainPhase.receiving ||
      ChainPhase.touching =>
        _state.returning ? l10n.chainReturnTouch : l10n.chainStepTouch,
      ChainPhase.prepareRun || ChainPhase.running => l10n.chainStepRun,
      _ => l10n.chainStepAction,
    };
    final selected = _draft == null
        ? l10n.chainNoSelection
        : _receiver != null
            ? l10n.scanPassAttackPassPlayerLabel(_receiver!)
            : l10n.chainSelectedDistance(_engine
                .distanceMetres(_learner.position, _draft!)
                .toStringAsFixed(1));
    final primary = switch (_state.phase) {
      ChainPhase.prepareTouch => l10n.chainReceive,
      ChainPhase.prepareRun => l10n.chainRun,
      ChainPhase.decide => switch (_mode) {
          ChainActionKind.pass => l10n.chainPass,
          ChainActionKind.carry => l10n.chainCarry,
          ChainActionKind.turn => l10n.chainTurn,
        },
      _ => l10n.spaceInMotion,
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Icon(Icons.person_outline, size: 18, color: colors.team),
        const SizedBox(width: 6),
        Expanded(
            child: Text(l10n.chainYourPlayer,
                style: Theme.of(context).textTheme.labelLarge)),
        Text(l10n.chainReturns(_state.returns),
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: colors.muted)),
      ]),
      const SizedBox(height: 12),
      if (deciding) ...[
        Wrap(spacing: 6, runSpacing: 4, children: [
          for (final kind in ChainActionKind.values)
            ChoiceChip(
                key: ValueKey('chain-mode-${kind.name}'),
                label: Text(switch (kind) {
                  ChainActionKind.pass => l10n.chainModePass,
                  ChainActionKind.carry => l10n.chainModeCarry,
                  ChainActionKind.turn => l10n.chainModeTurn,
                }),
                selected: _mode == kind,
                showCheckmark: false,
                onSelected: (_) => setState(() {
                      _mode = kind;
                      _draft = null;
                      _receiver = null;
                    })),
        ]),
        const SizedBox(height: 10),
        if (_mode == ChainActionKind.pass)
          Row(children: [
            for (final number in [4, 8]) ...[
              if (number == 8) const SizedBox(width: 8),
              Expanded(
                  child: OutlinedButton.icon(
                key: ValueKey('chain-pass-$number'),
                onPressed: () => _choosePass(number),
                icon: const Icon(Icons.near_me_outlined, size: 17),
                label: Text(l10n.scanPassAttackPassAction(number)),
              )),
            ]
          ]),
      ],
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(heading,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          Text(_picking ? selected : l10n.chainWatchRelation,
              key: const ValueKey('chain-selection'),
              style: Theme.of(context).textTheme.bodyMedium),
          if (_picking || _state.phase == ChainPhase.running) ...[
            const SizedBox(height: 6),
            Text(
                _state.phase == ChainPhase.prepareRun ||
                        _state.phase == ChainPhase.running
                    ? l10n.chainOffBallNote(_state.pitch.carrierNumber)
                    : _draft != null
                        ? l10n.chainNeutralSelection
                        : l10n.chainDragHint,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.muted, height: 1.45)),
          ],
        ]),
      ),
      const SizedBox(height: 12),
      if (_picking)
        FilledButton.icon(
          key: const ValueKey('chain-commit'),
          onPressed: _draft == null ? null : _commit,
          style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: colors.accent,
              foregroundColor: Colors.white),
          icon: Icon(
              _state.phase == ChainPhase.prepareRun
                  ? Icons.directions_run
                  : Icons.near_me_outlined,
              size: 19),
          label: Text(primary),
        ),
      if (_moving) ...[
        Row(children: [
          Expanded(
              child: OutlinedButton.icon(
                  key: const ValueKey('chain-pause'),
                  onPressed: () => setState(() => _playing = !_playing),
                  icon:
                      Icon(_playing ? Icons.pause : Icons.play_arrow, size: 19),
                  label: Text(_playing ? l10n.spacePause : l10n.spaceResume))),
          const SizedBox(width: 8),
          IconButton.outlined(
              key: const ValueKey('chain-step'),
              tooltip: l10n.spaceStepMotion,
              onPressed: () {
                setState(() => _playing = false);
                _advance(.2);
              },
              icon: const Icon(Icons.skip_next_outlined)),
        ]),
        const SizedBox(height: 6),
        Text(_playing ? l10n.chainSlowMotion : l10n.spacePausedNote,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.muted)),
      ],
      const SizedBox(height: 14),
      Text(l10n.chainLegend,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: colors.muted, height: 1.5)),
      const SizedBox(height: 6),
      TextButton.icon(
          key: const ValueKey('chain-restart'),
          onPressed: _restart,
          icon: const Icon(Icons.restart_alt, size: 18),
          label: Text(l10n.spaceRestart)),
    ]);
  }

  Widget _reviewDock(AppLocalizations l10n, _ScanPassColors colors) {
    final selected = _snapshot;
    ChainSnapshot? before;
    ChainSnapshot? after;
    final cycle = selected?.cycle ??
        (_state.moments.isEmpty ? 0 : _state.moments.last.cycle);
    for (final moment in _state.moments) {
      if (moment.cycle != cycle) continue;
      if (moment.moment == ChainMoment.beforeTouch) before = moment;
      if (moment.moment == ChainMoment.afterTouch) after = moment;
    }
    String lanes(ChainSnapshot snapshot) => snapshot.openPasses.isEmpty
        ? l10n.chainNoLane
        : snapshot.openPasses
            .map((number) => l10n.chainPlayerNumber(number))
            .join(' · ');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(_outcome(l10n),
          key: const ValueKey('chain-outcome'),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text(_reason(l10n),
          key: const ValueKey('chain-reason'),
          style:
              Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45)),
      const SizedBox(height: 14),
      if (before != null && after != null) ...[
        Text(l10n.chainMomentLabel(cycle + 1, l10n.chainReviewTouch),
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 7),
        Text(
            l10n.chainPressureChange(before.pressureMetres.toStringAsFixed(1),
                after.pressureMetres.toStringAsFixed(1)),
            key: const ValueKey('chain-pressure-comparison'),
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 5),
        Text(l10n.chainLanesChange(lanes(before), lanes(after)),
            key: const ValueKey('chain-lanes-comparison'),
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 5),
      ],
      Text(l10n.chainReviewHint,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: colors.muted, height: 1.4)),
      const SizedBox(height: 8),
      const SizedBox(height: 10),
      Slider(
          key: const ValueKey('chain-timeline'),
          min: 0,
          max: math.max(1, _frames.length - 1).toDouble(),
          value: (_reviewFrame ?? _frames.length - 1).toDouble(),
          semanticFormatterCallback: (value) => l10n.chainPlaybackPosition(
              (value / math.max(1, _frames.length - 1) * 100).round()),
          onChanged: (value) => setState(() {
                _replaying = false;
                _reviewMoment = null;
                _reviewFrame = value.round();
              })),
      OutlinedButton.icon(
          key: const ValueKey('chain-replay'),
          onPressed: () => setState(() {
                if (_replaying) {
                  _replaying = false;
                } else {
                  _reviewMoment = null;
                  _reviewFrame = 0;
                  _replayTime = 0;
                  _replaying = true;
                }
              }),
          icon: Icon(_replaying ? Icons.pause : Icons.replay, size: 18),
          label: Text(_replaying ? l10n.spacePause : l10n.chainReplay)),
      const SizedBox(height: 10),
      FilledButton(
          key: const ValueKey('chain-retry'),
          onPressed: _restart,
          style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: colors.accent,
              foregroundColor: Colors.white),
          child: Text(l10n.chainRetry)),
      const SizedBox(height: 8),
      TextButton.icon(
          key: const ValueKey('chain-new-layout'),
          onPressed: () => _restart(newLayout: true),
          icon: const Icon(Icons.shuffle, size: 18),
          label: Text(l10n.spaceNewLayout)),
    ]);
  }
}

class _ChainPitchPainter extends CustomPainter {
  final ChainState state;
  final AttackState pitch;
  final ScanPassPoint? selectedTarget;
  final int? selectedReceiver;
  final double? radius;
  final bool review;
  final List<ChainState> reviewFrames;
  final _PitchLabels labels;
  final AppLocalizations l10n;
  final Brightness brightness;
  final String? fontFamily;

  const _ChainPitchPainter({
    required this.state,
    required this.pitch,
    required this.selectedTarget,
    required this.selectedReceiver,
    required this.radius,
    required this.review,
    required this.reviewFrames,
    required this.labels,
    required this.l10n,
    required this.brightness,
    required this.fontFamily,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final g = _PitchGeometry(size, space: true);
    final p = _AttackPitchPainter(
        displayState: pitch,
        baseState: pitch,
        selectedAction: null,
        selectedTarget: null,
        previewOffside: null,
        activeTransition: state.ballInFlight || review
            ? AttackTransition(
                before: pitch,
                after: pitch,
                action: const AttackAction.pass(6),
                duration: 1,
                ballEnd: pitch.ball)
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
    p._drawText(canvas, l10n.chainPitchHeader,
        Offset(g.fieldRect.left, size.height * .025),
        color: p._muted, fontSize: 11);
    final learner = pitch.attackers.firstWhere((a) => a.number == 6);
    final origin = g.toOffset(learner.position);
    if (radius != null) {
      final rect = Rect.fromCenter(
          center: origin,
          width: g.fieldRect.width * radius! * 2 / 30,
          height: g.fieldRect.height * radius! * 2 / 20);
      canvas.save();
      canvas.clipRect(g.fieldRect);
      canvas.drawOval(rect, Paint()..color = p._team.withValues(alpha: .045));
      canvas.drawOval(
          rect,
          Paint()
            ..color = p._team.withValues(alpha: .30)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
      canvas.restore();
    }
    if (!review && state.phase == ChainPhase.prepareTouch) {
      p._drawDashedLine(
          canvas,
          g.toOffset(pitch.carrier.position),
          origin,
          Paint()
            ..color = p._muted.withValues(alpha: .4)
            ..strokeWidth = 1.2,
          dash: 3,
          gap: 6);
    }
    if (review && reviewFrames.isNotEmpty) {
      for (final number in [6, 2, 3]) {
        final path = Path();
        for (var i = 0; i < reviewFrames.length; i++) {
          final actors = number == 6
              ? reviewFrames[i].pitch.attackers
              : reviewFrames[i].pitch.defenders;
          final at =
              g.toOffset(actors.firstWhere((p) => p.number == number).position);
          if (i == 0) {
            path.moveTo(at.dx, at.dy);
          } else {
            path.lineTo(at.dx, at.dy);
          }
        }
        canvas.drawPath(
            path,
            Paint()
              ..color =
                  (number == 6 ? p._team : p._defender).withValues(alpha: .40)
              ..strokeWidth = 2
              ..style = PaintingStyle.stroke);
      }
      if (pitch.carrierNumber == 6) {
        final open = const TouchChainEngine().openPasses(pitch);
        for (final teammate
            in pitch.attackers.where((a) => open.contains(a.number))) {
          p._drawDashedLine(
              canvas,
              origin,
              g.toOffset(teammate.position),
              Paint()
                ..color = p._team.withValues(alpha: .55)
                ..strokeWidth = 2,
              dash: 6,
              gap: 5);
        }
      }
    }
    if (selectedTarget != null) {
      final target = g.toOffset(selectedTarget!);
      final paint = Paint()
        ..color = p._accent
        ..strokeWidth = 2;
      p._drawDashedLine(canvas, origin, target, paint, dash: 5, gap: 4);
      p._drawArrowHead(canvas, origin, target, paint);
      canvas.drawCircle(target, selectedReceiver == null ? 9 : 22,
          Paint()..color = p._accent.withValues(alpha: .10));
      canvas.drawCircle(
          target,
          selectedReceiver == null ? 9 : 22,
          Paint()
            ..color = p._accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.7);
    }
    for (final actor in [...pitch.defenders, ...pitch.attackers]) {
      final jersey = actor.opponent ? p._defender : p._team;
      if (!review && actor.velocity.x.abs() + actor.velocity.y.abs() > .001) {
        final from = g.toOffset(actor.position);
        final to = g.toOffset(actor.position + actor.velocity * .65);
        final paint = Paint()
          ..color = jersey.withValues(alpha: .50)
          ..strokeWidth = 1.4;
        canvas.drawLine(from, to, paint);
        p._drawArrowHead(canvas, from, to, paint);
      }
      if (!actor.opponent && actor.number == 6) {
        canvas.drawCircle(
            g.toOffset(actor.position),
            math.max(18, size.shortestSide * .055),
            Paint()..color = p._team.withValues(alpha: .16));
      }
      final hasBall = !actor.opponent &&
          actor.number == pitch.carrierNumber &&
          !state.ballInFlight &&
          !review;
      if (hasBall && actor.number == 6) {
        canvas.drawCircle(
            g.toOffset(actor.position),
            math.max(11.0, size.shortestSide * .037) * 1.42,
            Paint()
              ..color = p._accent.withValues(alpha: .72)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.1);
      }
      p._drawPlayer(canvas, g, actor,
          jersey: jersey,
          shorts: actor.opponent
              ? const Color(0xFF783B31)
              : const Color(0xFF174E66),
          textColor: Colors.white,
          current: hasBall && actor.number != 6);
      if (!actor.opponent && actor.number == 6) {
        p._drawText(
            canvas,
            l10n.spaceLearner,
            g.toOffset(actor.position) -
                Offset(0, math.max(22, size.shortestSide * .075)),
            color: p._text,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            anchorMode: _TextAnchor.center);
      }
    }
    p._drawBall(canvas, g);
  }

  @override
  bool shouldRepaint(covariant _ChainPitchPainter oldDelegate) =>
      state != oldDelegate.state ||
      pitch != oldDelegate.pitch ||
      selectedTarget != oldDelegate.selectedTarget ||
      selectedReceiver != oldDelegate.selectedReceiver ||
      radius != oldDelegate.radius ||
      review != oldDelegate.review ||
      brightness != oldDelegate.brightness ||
      l10n != oldDelegate.l10n;
}
