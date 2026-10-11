part of 'scan_pass_game_screen.dart';

/// Two attackers, two defenders, and one spatial choice at a time.
class ScanPassFlowScreen extends StatefulWidget {
  final Duration? observationDuration;
  final Duration executionDuration;

  const ScanPassFlowScreen({
    super.key,
    this.observationDuration,
    this.executionDuration = const Duration(seconds: 1),
  });

  @override
  State<ScanPassFlowScreen> createState() => _ScanPassFlowScreenState();
}

class _FlowCommand {
  final PracticeActionKind kind;
  final ScanPassPoint? target;
  const _FlowCommand(this.kind, [this.target]);
}

class _ScanPassFlowScreenState extends State<ScanPassFlowScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _engine = FlowEngine();
  late final AnimationController _controller;
  late PracticeSession _session;
  List<AttackTransition> _motion = const [];
  Map<int, ScanPassPoint> _movingRuns = const {};
  PracticeAction? _intent;
  PracticeDecision? _previousAttempt;
  PracticeStep? _pendingStep;
  (double, TextScaler, TextStyle, String, TextDirection)? _headerMeasureKey;
  double _headerInstructionHeight = 0;

  // During the opening pass the authored receiving session is already known.
  PracticeSession? get _upcomingSession =>
      _pendingStep?.session ?? (_busy && !_replaying ? _session : null);
  _FlowCommand? _queued;
  ScanPassPoint? _hover;
  VoidCallback? _afterMotion;
  int _caseIndex = 0;
  int _reviewIndex = 0;
  bool _busy = false;
  bool _review = false;
  bool _before = false;
  bool _pendingPass = false;
  bool _pendingThrough = false;
  bool _paused = false;
  bool _modal = false;
  bool _foreground = true;
  bool _replaying = false;
  bool _replayingPrevious = false;

  AppLocalizations get _l => AppLocalizations.of(context)!;
  FlowCase get _case => FlowEngine.catalog[_caseIndex];
  PracticeDecision? get _decision => _session.decisions.isEmpty
      ? null
      : _session
          .decisions[_reviewIndex.clamp(0, _session.decisions.length - 1)];
  int _receiverFor(PracticeSession session) => session.state.attackers
      .firstWhere((p) => p.number != session.state.carrierNumber)
      .number;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session = _engine.start(_case);
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        final complete = _afterMotion;
        _afterMotion = null;
        setState(() {
          _busy = false;
          _intent = null;
          _movingRuns = const {};
          _replaying = false;
          _replayingPrevious = false;
        });
        complete?.call();
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _open(0);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _controller.stop();
    } else {
      _resumeMotion();
    }
  }

  void _resumeMotion() {
    if (_busy && !_paused && !_modal && _foreground) {
      unawaited(_controller.forward());
    }
  }

  void _open(int index) {
    _controller.stop();
    _afterMotion = null;
    setState(() {
      _caseIndex = index % FlowEngine.catalog.length;
      _session = _engine.start(_case);
      _busy = false;
      _review = false;
      _before = false;
      _pendingPass = false;
      _pendingThrough = false;
      _paused = false;
      _queued = null;
      _hover = null;
      _previousAttempt = null;
      _pendingStep = null;
      _intent = null;
      _movingRuns = const {};
      _reviewIndex = 0;
      _replaying = false;
      _replayingPrevious = false;
    });
    _animate([_case.lesson.observation], () => _completeAction(null),
        opening: true);
  }

  void _animate(List<AttackTransition> transitions, VoidCallback done,
      {bool opening = false}) {
    _controller.stop();
    final seconds = transitions.fold<double>(0, (sum, t) => sum + t.duration);
    final duration = opening && widget.observationDuration != null
        ? widget.observationDuration!
        : Duration(
            milliseconds: math.max(1,
                (seconds * widget.executionDuration.inMilliseconds).round()));
    _motion = transitions;
    _afterMotion = done;
    if (transitions.isEmpty ||
        duration == Duration.zero ||
        widget.executionDuration == Duration.zero && !opening ||
        MediaQuery.of(context).disableAnimations) {
      _afterMotion = null;
      setState(() {
        _busy = false;
        _intent = null;
        _movingRuns = const {};
        _replaying = false;
        _replayingPrevious = false;
      });
      done();
      return;
    }
    setState(() {
      _busy = true;
    });
    _controller.duration = duration;
    _controller.value = 0;
    _resumeMotion();
  }

  ({AttackTransition transition, double progress})? get _active {
    if (!_busy || _motion.isEmpty) return null;
    var time = _motion.fold<double>(0, (sum, t) => sum + t.duration) *
        _controller.value;
    for (final transition in _motion) {
      if (time <= transition.duration) {
        return (
          transition: transition,
          progress: transition.duration == 0 ? 1 : time / transition.duration,
        );
      }
      time -= transition.duration;
    }
    return (transition: _motion.last, progress: 1);
  }

  AttackState _displayFor(
      ({AttackTransition transition, double progress})? active) {
    if (active != null) return active.transition.frame(active.progress);
    final decision = _decision;
    if (_review && decision != null) {
      return _before ? decision.before : decision.after;
    }
    return _session.state;
  }

  bool _isPassActive(
          ({AttackTransition transition, double progress})? active) =>
      active != null &&
      (active.transition.action.kind == AttackActionKind.pass ||
          active.transition.action.kind == AttackActionKind.shoot) &&
      active.transition.after.end != AttackEnd.offside;

  PracticeSession _controlSession(
      ({AttackTransition transition, double progress})? active) {
    if (!_busy || _pendingStep == null || _isPassActive(active)) {
      return _session;
    }
    return _pendingStep!.session;
  }

  Map<int, ScanPassPoint> get _visibleRuns {
    if (_replaying) {
      return _replayingPrevious
          ? _previousAttempt?.runTargetsBefore ?? const {}
          : const {};
    }
    if (_busy) return _movingRuns;
    if (_review) return _decision?.runTargetsBefore ?? const {};
    return _session.runTargets;
  }

  void _completeAction(PracticeStep? completed) {
    if (completed != null) {
      setState(() {
        _session = completed.session;
        _reviewIndex = _session.decisions.length - 1;
        _pendingStep = null;
      });
    }
    if (_session.finished) {
      setState(() {
        _review = true;
        _reviewIndex = _session.decisions.length - 1;
        _before = false;
        _pendingPass = false;
        _pendingThrough = false;
        _queued = null;
        _hover = null;
      });
      return;
    }
    final queued = _queued;
    if (queued != null) {
      setState(() => _queued = null);
      final queuedPass = queued.kind == PracticeActionKind.pass ||
          queued.kind == PracticeActionKind.through;
      if (!_session.finished &&
          !(queuedPass && _session.phase == PracticePhase.firstTouch)) {
        _execute(queued);
      }
    }
  }

  void _submit(_FlowCommand command) {
    if (_review || _session.finished || !_foreground) return;
    setState(() {
      _hover = null;
      _pendingPass = false;
      _pendingThrough = false;
    });
    if (_busy) {
      setState(() => _queued = command);
    } else {
      _execute(command);
    }
  }

  void _execute(_FlowCommand command) {
    if (_session.finished) return;
    final before = _session;
    final step = switch (command.kind) {
      PracticeActionKind.touch => _engine.touchTo(before, command.target!),
      PracticeActionKind.carry ||
      PracticeActionKind.move =>
        _engine.moveTo(before, command.target!),
      PracticeActionKind.pass || PracticeActionKind.through => _engine
          .pass(before, through: command.kind == PracticeActionKind.through),
      PracticeActionKind.hold => _engine.hold(before),
    };
    setState(() {
      _pendingStep = step;
      _intent = step.decision.action;
      _movingRuns = step.decision.runTargetsBefore;
    });
    _animate(step.transitions, () => _completeAction(step));
  }

  void _choosePass({bool through = false}) {
    final active = _active;
    final controlSession = _controlSession(active);
    if (_review ||
        controlSession.finished ||
        _isPassActive(active) ||
        controlSession.phase == PracticePhase.firstTouch) {
      return;
    }
    _submit(_FlowCommand(
        through ? PracticeActionKind.through : PracticeActionKind.pass));
  }

  void _tapSpace(ScanPassPoint point) {
    if (_review || _session.finished || _replaying) return;
    if (_busy) {
      final active = _active;
      final future = _upcomingSession;
      if (future == null || future.finished) return;
      if (_isPassActive(active) && future.phase == PracticePhase.firstTouch) {
        _submit(_FlowCommand(
            PracticeActionKind.touch, _engine.touchTarget(future, point)));
      } else if (!_isPassActive(active) &&
          future.phase != PracticePhase.firstTouch) {
        _submit(_FlowCommand(
            PracticeActionKind.carry, PracticeEngine.boundedTarget(point)));
      }
      return;
    }
    if (_session.phase == PracticePhase.firstTouch) {
      _submit(_FlowCommand(
          PracticeActionKind.touch, _engine.touchTarget(_session, point)));
    } else {
      _submit(_FlowCommand(
          PracticeActionKind.carry, PracticeEngine.boundedTarget(point)));
    }
  }

  void _reviewNow() {
    if (_busy || _session.decisions.isEmpty) return;
    setState(() {
      _review = true;
      _reviewIndex = _session.decisions.length - 1;
      _before = false;
      _pendingPass = false;
      _pendingThrough = false;
      _hover = null;
      _queued = null;
    });
  }

  void _retry() {
    final decision = _decision;
    if (decision == null || _busy) return;
    final restored = _engine.beforeDecision(_session, _reviewIndex);
    setState(() {
      _previousAttempt = decision;
      _session = restored;
      _review = false;
      _before = false;
      _paused = false;
      _queued = null;
      _intent = null;
      _pendingStep = null;
      _hover = null;
      _movingRuns = const {};
      _pendingPass = false;
      _pendingThrough = false;
    });
  }

  void _replay({bool previous = false}) {
    final attempt = _previousAttempt;
    if (_busy || previous && attempt == null) return;
    setState(() {
      _paused = false;
      _replaying = true;
      _replayingPrevious = previous;
      _intent = null;
    });
    _animate(previous ? attempt!.transitions : _session.history, () {});
  }

  Future<void> _help() async {
    _modal = true;
    _controller.stop();
    await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(_l.flowHelpTitle),
              content: SingleChildScrollView(child: Text(_l.flowHelpBody)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(_l.close)),
              ],
            ));
    if (!mounted) return;
    _modal = false;
    _resumeMotion();
  }

  Future<void> _pickCase() async {
    _modal = true;
    _controller.stop();
    final index = await showModalBottomSheet<int>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
              child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: FlowEngine.catalog.length,
                  itemBuilder: (context, index) => ListTile(
                        key: ValueKey('flow-case-$index'),
                        leading: Text(_l.flowCaseNumber(
                            index + 1, FlowEngine.catalog.length)),
                        title: Text(
                            _flowGoal(_l, FlowEngine.catalog[index].focus)),
                        selected: index == _caseIndex,
                        onTap: () => Navigator.pop(context, index),
                      )),
            ));
    if (!mounted) return;
    _modal = false;
    if (index != null) _open(index);
    _resumeMotion();
  }

  Future<void> _pickDecision() async {
    _modal = true;
    _controller.stop();
    final index = await showModalBottomSheet<int>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
              child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _session.decisions.length,
                  itemBuilder: (context, index) => ListTile(
                        key: ValueKey('flow-decision-$index'),
                        title: Text(_l.practiceDecision(
                            index + 1, _session.decisions.length)),
                        subtitle: Text(_result(_session.decisions[index])),
                        selected: index == _reviewIndex,
                        onTap: () => Navigator.pop(context, index),
                      )),
            ));
    if (!mounted) return;
    _modal = false;
    if (index != null) {
      setState(() {
        _reviewIndex = index;
        _before = false;
      });
    }
  }

  PopupMenuItem<VoidCallback> _menuItem(
          String key, String label, VoidCallback action) =>
      PopupMenuItem(key: ValueKey(key), value: action, child: Text(label));

  Widget _menu() => PopupMenuButton<VoidCallback>(
        key: const ValueKey('flow-more'),
        tooltip: _l.flowMore,
        icon: const Icon(Icons.more_horiz),
        onOpened: () {
          _modal = true;
          _controller.stop();
        },
        onCanceled: () {
          _modal = false;
          _resumeMotion();
        },
        onSelected: (action) {
          _modal = false;
          action();
          _resumeMotion();
        },
        itemBuilder: (context) => [
          if (!_busy && _session.decisions.isNotEmpty && !_review)
            _menuItem('flow-review-now', _l.flowReviewNow, _reviewNow),
          if (_review && !_busy) ...[
            _menuItem('flow-replay', _l.practiceReplayMine, _replay),
            if (_previousAttempt != null)
              _menuItem('flow-replay-previous', _l.flowReplayPrevious,
                  () => _replay(previous: true)),
            _menuItem('flow-frame', _before ? _l.flowAfter : _l.flowBefore,
                () => setState(() => _before = !_before)),
            if (_session.decisions.length > 1)
              _menuItem('flow-decisions', _l.flowOtherDecisions, _pickDecision),
            const PopupMenuDivider(),
          ],
          _menuItem('flow-restart', _l.flowRestart, () => _open(_caseIndex)),
          _menuItem('flow-cases', _l.flowChooseCase, _pickCase),
          _menuItem('flow-help', _l.flowHelpTitle, _help),
        ],
      );

  String get _instruction {
    if (_replayingPrevious) return _l.flowReplayPrevious;
    if (_replaying) return _l.practiceReplayMine;
    if (_review) return _before ? _l.flowBefore : _l.flowAfter;
    final active = _active;
    final future = _upcomingSession;
    if (_isPassActive(active) &&
        future != null &&
        future.phase == PracticePhase.firstTouch) {
      final receiver = future.state.carrierNumber;
      if (_queued?.kind == PracticeActionKind.touch) {
        return _l.flowTouchPrepared(receiver);
      }
      return _l.flowPrepareTouch(receiver);
    }
    if (_isPassActive(active)) return _l.flowPassTravelling;
    if (_queued != null) return _l.flowQueued;
    if (_busy && _intent?.kind == PracticeActionKind.touch) {
      return _l.flowTouchInMotion;
    }
    if (_busy &&
        (_intent?.kind == PracticeActionKind.carry ||
            _intent?.kind == PracticeActionKind.move)) {
      return _l.flowMoveInMotion;
    }
    if (_session.finished) return _l.flowPlaying;
    if (_session.phase == PracticePhase.firstTouch) {
      return _l.flowChooseTouch(_session.state.carrierNumber);
    }
    return _l.flowChooseBall(
        _session.state.carrierNumber, _receiverFor(_session));
  }

  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    final feedback = _review ? _feedback() : null;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(_l.flowTitle,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          if (_busy)
            IconButton(
                key: const ValueKey('flow-pause'),
                tooltip: _paused
                    ? _l.scanPassPossessionResume
                    : _l.scanPassPossessionPause,
                icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                onPressed: () => setState(() {
                      _paused = !_paused;
                      if (_paused) {
                        _controller.stop();
                      } else {
                        _resumeMotion();
                      }
                    })),
          _menu(),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: _controller,
          child: _fieldHeader(),
          builder: (context, header) {
            final active = _active;
            final display = _displayFor(active);
            return LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth > constraints.maxHeight * 1.55;
              final portrait =
                  constraints.maxHeight > constraints.maxWidth * 1.1;
              final field = _field(portrait, display, active, header!);
              if (!_review) return field;
              if (wide) {
                return Row(children: [
                  Expanded(child: field),
                  SizedBox(
                      width: math.min(340, constraints.maxWidth * .44),
                      child: feedback),
                ]);
              }
              return Column(children: [
                Expanded(child: field),
                SizedBox(
                    height: math.min(300, constraints.maxHeight * .47),
                    child: feedback),
              ]);
            });
          },
        ),
      ),
    );
  }

  // Cache the tallest localized instruction for this width and font scale.
  // The field must not move when a pass, a queued action or its cancel control
  // changes the instruction. This widget is also reused between animation ticks.
  double _instructionHeight(double width, TextStyle style) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final key = (width, scaler, style, _l.localeName, direction);
    if (_headerMeasureKey == key) return _headerInstructionHeight;
    final messages = [
      _l.flowChooseTouch(6),
      _l.flowChooseBall(6, 8),
      _l.flowPrepareTouch(8),
      _l.flowTouchPrepared(8),
      _l.flowPassTravelling,
      _l.flowTouchInMotion,
      _l.flowMoveInMotion,
      _l.flowQueued,
      _l.flowPlaying,
      _l.flowReplayPrevious,
      _l.practiceReplayMine,
      _l.flowBefore,
      _l.flowAfter,
    ];
    var height = 0.0;
    for (final message in messages) {
      final painter = TextPainter(
        text: TextSpan(text: _l.flowNowLine(message), style: style),
        textDirection: direction,
        textScaler: scaler,
        locale: Localizations.localeOf(context),
      )..layout(maxWidth: width);
      height = math.max(height, painter.height);
      painter.dispose();
    }
    _headerMeasureKey = key;
    return _headerInstructionHeight = height.ceilToDouble() + 1;
  }

  Widget _fieldHeader() {
    final colors = _ScanPassColors.of(context);
    final instruction = _l.flowNowLine(_instruction);
    final style = (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
        .copyWith(
            fontSize: 14, fontWeight: FontWeight.w700, color: colors.text);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
      child: LayoutBuilder(builder: (context, constraints) {
        final height =
            _instructionHeight(math.max(1.0, constraints.maxWidth - 48), style);
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_l.flowGoalLine(_flowGoal(_l, _case.focus)),
                    style: TextStyle(fontSize: 12, color: colors.text)),
                const SizedBox(height: 5),
                SizedBox(
                  height: height,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(instruction,
                        key: const ValueKey('flow-instruction'), style: style),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: _pendingPass || _queued != null
                ? AppBarActionButton(
                    key: const ValueKey('flow-cancel'),
                    compact: true,
                    margin: EdgeInsets.zero,
                    tooltip: _l.flowCancelChoice,
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() {
                          _pendingPass = false;
                          _pendingThrough = false;
                          _queued = null;
                          _hover = null;
                        }))
                : Center(
                    child: Text(
                      _l.flowCaseNumber(
                          _caseIndex + 1, FlowEngine.catalog.length),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: colors.text),
                    ),
                  ),
          ),
        ]);
      }),
    );
  }

  Widget _field(bool portrait, AttackState display,
      ({AttackTransition transition, double progress})? active, Widget header) {
    final controlSession = _controlSession(active);
    final passInFlight = _isPassActive(active);
    final future = _upcomingSession;
    final preparingTouch = passInFlight &&
        future != null &&
        !future.finished &&
        future.phase == PracticePhase.firstTouch;
    final selected = _review || _session.finished || display.carrierIsDefender
        ? null
        : display.carrierNumber;
    final showActions = !_review &&
        !_pendingPass &&
        !controlSession.finished &&
        !passInFlight &&
        controlSession.phase != PracticePhase.firstTouch;
    final through = showActions ? _engine.throughTarget(controlSession) : null;
    final touchOrigin = !_review &&
            !_pendingPass &&
            !controlSession.finished &&
            (preparingTouch ||
                (!passInFlight &&
                    controlSession.phase == PracticePhase.firstTouch))
        ? (preparingTouch
            ? future.state.carrier.position
            : controlSession.state.carrier.position)
        : null;
    return ColoredBox(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1B3931)
          : const Color(0xFFD4E1D5),
      child: Column(children: [
        header,
        Expanded(child: LayoutBuilder(builder: (context, constraints) {
          final size = constraints.biggest;
          final geometry = _PracticeGeometry(size, portrait: portrait);
          ScanPassPoint? target = _queued?.target ?? _hover;
          if (target != null && touchOrigin != null) {
            target = _engine.touchTarget(
                preparingTouch ? future : controlSession, target);
          }
          final receiver = _receiverFor(controlSession);
          final receiverPosition = controlSession.finished
              ? null
              : display.attackers
                  .firstWhere((p) => p.number == receiver)
                  .position;
          final carrierPosition = controlSession.finished
              ? null
              : display.attackers
                  .firstWhere(
                      (p) => p.number == controlSession.state.carrierNumber)
                  .position;
          final receiverOffset = receiverPosition == null
              ? null
              : geometry.toOffset(receiverPosition);
          final carrierAnchor = carrierPosition == null
              ? null
              : geometry.toOffset(carrierPosition) - const Offset(0, 18);
          Offset? holdOffset = carrierAnchor;
          final throughAnchor =
              through == null ? null : geometry.toOffset(through);
          Offset? throughOffset = throughAnchor;
          Offset? passLabelOffset;
          final controlLinks = <(Offset, Offset)>[];
          if (showActions && receiverOffset != null && holdOffset != null) {
            const passLabelSize = Size(58, 24);
            final reserved = _flowReservedRects(display, geometry);
            passLabelOffset = _flowRectCenter(
              receiverOffset + const Offset(0, -56),
              size,
              passLabelSize,
              reserved,
            );
            if ((passLabelOffset - receiverOffset).distance > 34) {
              controlLinks.add((passLabelOffset, receiverOffset));
            }
            reserved
              ..add(Rect.fromCenter(
                      center: passLabelOffset,
                      width: passLabelSize.width,
                      height: passLabelSize.height)
                  .inflate(5))
              ..add(
                  Rect.fromCenter(center: receiverOffset, width: 72, height: 72)
                      .inflate(5));
            holdOffset = _flowControlCenter(holdOffset, size, reserved);
            if ((holdOffset - carrierAnchor!).distance > 1) {
              controlLinks.add((holdOffset, carrierAnchor));
            }
            reserved.add(
                Rect.fromCenter(center: holdOffset, width: 44, height: 44)
                    .inflate(5));
            if (throughOffset != null) {
              throughOffset = _flowControlCenter(throughOffset, size, reserved);
              if ((throughOffset - throughAnchor!).distance > 1) {
                controlLinks.add((throughOffset, throughAnchor));
              }
            }
          }
          return MouseRegion(
            cursor: _review ? MouseCursor.defer : SystemMouseCursors.precise,
            onHover: (event) {
              if (_review || _session.finished) return;
              setState(() => _hover = geometry.fromOffset(event.localPosition));
            },
            onExit: (_) {
              if (_hover != null) setState(() => _hover = null);
            },
            child: GestureDetector(
              key: const ValueKey('flow-pitch'),
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) =>
                  _tapSpace(geometry.fromOffset(details.localPosition)),
              child: Stack(children: [
                Positioned.fill(
                  child: CustomPaint(
                    key: const ValueKey('flow-pitch-paint'),
                    painter: _FlowPitchPainter(
                      state: display,
                      lesson: _case.lesson,
                      l10n: _l,
                      brightness: Theme.of(context).brightness,
                      fontFamily:
                          Theme.of(context).textTheme.bodyMedium?.fontFamily,
                      portrait: portrait,
                      selectedPlayer: selected,
                      active: active?.transition,
                      progress: active?.progress ?? 0,
                      intent: _intent,
                      review: _review && !_busy ? _decision : null,
                      runTargets: _visibleRuns,
                      touchOrigin: touchOrigin,
                      controlLinks: controlLinks,
                      preview: target,
                      previewOrigin: controlSession.finished
                          ? null
                          : (touchOrigin ??
                              controlSession.state.carrier.position),
                      previewTouch: touchOrigin != null,
                      pendingPassTarget: _pendingPass
                          ? _pendingThrough
                              ? _engine.throughTarget(controlSession)
                              : receiverPosition
                          : null,
                    ),
                  ),
                ),
                if (showActions) ...[
                  ..._passControl(
                      'flow-pass',
                      _l.practicePass(receiver),
                      _l.flowPassLabel,
                      receiverOffset!,
                      passLabelOffset!,
                      () => _choosePass()),
                  if (throughOffset != null)
                    _jerseyControl('flow-through', _l.flowThrough,
                        throughOffset, () => _choosePass(through: true),
                        icon: Icons.double_arrow_rounded),
                  _jerseyControl(
                      'flow-hold',
                      _l.flowKeepBall,
                      holdOffset!,
                      () =>
                          _submit(const _FlowCommand(PracticeActionKind.hold)),
                      icon: (holdOffset - carrierAnchor!).distance > 1
                          ? Icons.hourglass_bottom_rounded
                          : null),
                ],
                if (touchOrigin != null)
                  _firstTouchBadge(geometry, touchOrigin,
                      _flowReservedRects(display, geometry),
                      preparing: preparingTouch),
              ]),
            ),
          );
        })),
      ]),
    );
  }

  List<Widget> _passControl(String key, String label, String shortLabel,
          Offset center, Offset labelCenter, VoidCallback action) =>
      [
        Positioned(
          left: center.dx - 36,
          top: center.dy - 36,
          width: 72,
          height: 72,
          child: Tooltip(
            message: label,
            child: Semantics(
              label: label,
              button: true,
              child: Stack(alignment: Alignment.center, children: [
                IgnorePointer(
                  child: DecoratedBox(
                    key: const ValueKey('flow-pass-ring-visual'),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                      border:
                          Border.all(color: const Color(0xFFFFD166), width: 3),
                    ),
                    child: const SizedBox(width: 56, height: 56),
                  ),
                ),
                TextButton(
                  key: ValueKey(key),
                  onPressed: action,
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                      backgroundColor: Colors.transparent),
                  child: const SizedBox.expand(),
                ),
              ]),
            ),
          ),
        ),
        Positioned(
          left: labelCenter.dx - 29,
          top: labelCenter.dy - 12,
          width: 58,
          height: 24,
          child: IgnorePointer(
            child: DecoratedBox(
              key: const ValueKey('flow-pass-label'),
              decoration: BoxDecoration(
                color: const Color(0xFF173D35).withValues(alpha: .90),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFFD166)),
              ),
              child: Center(
                child: Text(shortLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ),
      ];

  Widget _jerseyControl(
          String key, String label, Offset center, VoidCallback action,
          {IconData? icon}) =>
      Positioned(
        left: center.dx - 22,
        top: center.dy - 22,
        width: 44,
        height: 44,
        child: Tooltip(
          message: label,
          child: Semantics(
            label: label,
            button: true,
            child: TextButton(
              key: ValueKey(key),
              onPressed: action,
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                  backgroundColor: icon == null
                      ? Colors.transparent
                      : const Color(0xFF215B70)),
              child: icon == null
                  ? const SizedBox.expand()
                  : Icon(icon, color: Colors.white, size: 23),
            ),
          ),
        ),
      );

  Widget _firstTouchBadge(
      _PracticeGeometry geometry, ScanPassPoint origin, List<Rect> reserved,
      {bool preparing = false}) {
    final at = geometry.toOffset(origin);
    final edge = geometry.toOffset(ScanPassPoint(
        origin.x + FlowEngine.touchLimitMetres / PracticeEngine.fieldLength,
        origin.y));
    final radius = (edge - at).distance;
    const badgeSize = Size(124, 28);
    final rightCenter = Offset(at.dx + radius + 8 + badgeSize.width / 2, at.dy);
    final leftCenter = Offset(at.dx - radius - 8 - badgeSize.width / 2, at.dy);
    final preferred =
        rightCenter.dx + badgeSize.width / 2 <= geometry.size.width - 6
            ? rightCenter
            : leftCenter;
    final center =
        _flowRectCenter(preferred, geometry.size, badgeSize, reserved);
    return Positioned(
      left: center.dx - badgeSize.width / 2,
      top: center.dy - badgeSize.height / 2,
      width: badgeSize.width,
      height: badgeSize.height,
      child: IgnorePointer(
        child: DecoratedBox(
          key: const ValueKey('flow-first-touch-badge'),
          decoration: BoxDecoration(
            color: const Color(0xFF805B18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFE6A3)),
          ),
          child: Center(
            child: Text(
                preparing ? _l.flowPrepareTouchBadge : _l.flowFirstTouchBadge,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900)),
          ),
        ),
      ),
    );
  }

  String _result(PracticeDecision decision) {
    if (decision.after.carrierIsDefender) {
      return _l.practiceStolenBy(decision.after.carrierNumber);
    }
    if (decision.reason == PracticeReason.controlledGate) {
      return _l.practiceGateReached;
    }
    if (decision.reason == PracticeReason.offsideAtKick) {
      return _l.practiceOffsideEnd;
    }
    return switch (decision.action.kind) {
      PracticeActionKind.touch => _l.flowResultTouch,
      PracticeActionKind.carry || PracticeActionKind.move => _l.flowResultMove,
      PracticeActionKind.pass ||
      PracticeActionKind.through =>
        _l.flowResultPass(decision.after.carrierNumber),
      PracticeActionKind.hold => _l.flowResultHold,
    };
  }

  String _advice(PracticeDecision decision) {
    if (decision.after.carrierIsDefender &&
        decision.action.kind == PracticeActionKind.hold) {
      return _l.flowAdviceHold;
    }
    return switch (decision.action.kind) {
      PracticeActionKind.touch => _l.flowAdviceTouch,
      PracticeActionKind.carry || PracticeActionKind.move => _l.flowAdviceCarry,
      PracticeActionKind.pass => _l.flowAdvicePassRun,
      PracticeActionKind.through => _l.flowAdviceThrough,
      PracticeActionKind.hold => _l.flowAdviceHold,
    };
  }

  Widget _feedback() {
    final decision = _replayingPrevious ? _previousAttempt : _decision;
    if (decision == null) return const SizedBox.shrink();
    final colors = _ScanPassColors.of(context);
    return Material(
      key: const ValueKey('flow-feedback'),
      color: colors.surface,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Text(
              _l.practiceDecision(_reviewIndex + 1, _session.decisions.length),
              style: TextStyle(fontSize: 11, color: colors.muted)),
        ),
        Expanded(
          child: SingleChildScrollView(
            key: const ValueKey('flow-feedback-scroll'),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _feedbackLine(_l.flowResult, _result(decision)),
              _feedbackLine(_l.flowWhy, _reasonLabel(_l, decision.reason)),
              _feedbackLine(_l.flowTry, _advice(decision)),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Row(key: const ValueKey('flow-review-actions'), children: [
            Expanded(
              flex: 3,
              child: FilledButton(
                  key: const ValueKey('flow-retry'),
                  onPressed: _busy ? null : _retry,
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10)),
                  child: Text(_l.flowRetry, textAlign: TextAlign.center)),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: OutlinedButton(
                  key: const ValueKey('flow-next'),
                  onPressed: _busy
                      ? null
                      : () {
                          if (_session.finished) {
                            _open(_caseIndex + 1);
                          } else {
                            setState(() => _review = false);
                          }
                        },
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10)),
                  child: Text(
                      _session.finished ? _l.practiceNext : _l.flowContinue,
                      textAlign: TextAlign.center)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _feedbackLine(String label, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: MediaQuery.textScalerOf(context).scale(52),
            child: Text(label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 13, height: 1.35))),
        ]),
      );
}

String _flowGoal(AppLocalizations l, FlowFocus focus) => switch (focus) {
      FlowFocus.firstTouch => l.flowGoalFirstTouch,
      FlowFocus.drawDefender => l.flowGoalDrawDefender,
      FlowFocus.supportAngle => l.flowGoalSupportAngle,
      FlowFocus.throughPass => l.flowGoalThroughPass,
      FlowFocus.beatCover => l.flowGoalBeatCover,
      FlowFocus.changeLane => l.flowGoalChangeLane,
    };

/// Keep direct field controls independently hittable when players converge.
Offset _flowControlCenter(Offset desired, Size size, List<Rect> reserved) {
  Offset bounded(Offset point) => Offset(
      point.dx.clamp(24.0, math.max(24.0, size.width - 24)).toDouble(),
      point.dy.clamp(24.0, math.max(24.0, size.height - 24)).toDouble());
  bool clear(Offset point) {
    final hitBox = Rect.fromCenter(center: point, width: 44, height: 44);
    return reserved.every((rect) => !rect.overlaps(hitBox));
  }

  final initial = bounded(desired);
  if (clear(initial)) return initial;
  for (var radius = 28.0;
      radius <= math.max(size.width, size.height);
      radius += 28) {
    final candidates = <Offset>[
      for (var direction = 0; direction < 16; direction++)
        bounded(desired +
            Offset(math.cos(direction * math.pi / 8),
                    math.sin(direction * math.pi / 8)) *
                radius),
    ].where(clear).toList()
      ..sort(
          (a, b) => (a - desired).distance.compareTo((b - desired).distance));
    if (candidates.isNotEmpty) return candidates.first;
  }
  return initial;
}

List<Rect> _flowReservedRects(AttackState state, _PracticeGeometry geometry) {
  final playerRadius = math.max(11.0, geometry.size.shortestSide * .037);
  final rects = <Rect>[
    for (final player in [...state.attackers, ...state.defenders])
      Rect.fromCenter(
        center: geometry.toOffset(player.position),
        width: playerRadius * 3.4,
        height: playerRadius * 4.5,
      ).inflate(3),
  ];
  final ballRadius = math.max(
    geometry.size.width >= 700 ? 8.0 : 5.0,
    geometry.size.shortestSide * .014,
  );
  rects.add(Rect.fromCircle(
          center: geometry.toOffset(state.ball), radius: ballRadius * 1.8)
      .inflate(3));
  return rects;
}

Offset _flowRectCenter(
    Offset desired, Size size, Size rectSize, List<Rect> reserved) {
  final minX = rectSize.width / 2 + 6;
  final minY = rectSize.height / 2 + 6;
  final maxX = math.max(minX, size.width - rectSize.width / 2 - 6);
  final maxY = math.max(minY, size.height - rectSize.height / 2 - 6);
  Offset bounded(Offset point) => Offset(
        point.dx.clamp(minX, maxX).toDouble(),
        point.dy.clamp(minY, maxY).toDouble(),
      );
  bool clear(Offset point) {
    final rect = Rect.fromCenter(
      center: point,
      width: rectSize.width,
      height: rectSize.height,
    );
    return reserved.every((item) => !item.overlaps(rect));
  }

  final initial = bounded(desired);
  if (clear(initial)) return initial;
  for (var radius = 22.0;
      radius <= math.max(size.width, size.height);
      radius += 22) {
    final candidates = <Offset>[
      for (var direction = 0; direction < 16; direction++)
        bounded(desired +
            Offset(math.cos(direction * math.pi / 8),
                    math.sin(direction * math.pi / 8)) *
                radius),
    ].where(clear).toList()
      ..sort(
          (a, b) => (a - desired).distance.compareTo((b - desired).distance));
    if (candidates.isNotEmpty) return candidates.first;
  }
  return initial;
}

class _FlowPitchPainter extends CustomPainter {
  final AttackState state;
  final PracticeCase lesson;
  final AppLocalizations l10n;
  final Brightness brightness;
  final String? fontFamily;
  final bool portrait;
  final int? selectedPlayer;
  final AttackTransition? active;
  final double progress;
  final PracticeAction? intent;
  final PracticeDecision? review;
  final Map<int, ScanPassPoint> runTargets;
  final ScanPassPoint? touchOrigin;
  final ScanPassPoint? preview;
  final ScanPassPoint? previewOrigin;
  final bool previewTouch;
  final ScanPassPoint? pendingPassTarget;
  final List<(Offset, Offset)> controlLinks;

  const _FlowPitchPainter({
    required this.state,
    required this.lesson,
    required this.l10n,
    required this.brightness,
    required this.portrait,
    this.fontFamily,
    this.selectedPlayer,
    this.active,
    this.progress = 0,
    this.intent,
    this.review,
    this.runTargets = const {},
    this.touchOrigin,
    this.preview,
    this.previewOrigin,
    this.previewTouch = false,
    this.pendingPassTarget,
    this.controlLinks = const [],
  });

  Offset offsetFor(ScanPassPoint point, Size size) =>
      _PracticeGeometry(size, portrait: portrait).toOffset(point);

  @override
  void paint(Canvas canvas, Size size) {
    final base = _CurriculumPitchPainter(
        state: state,
        lesson: lesson,
        l10n: l10n,
        brightness: brightness,
        fontFamily: fontFamily,
        portrait: portrait,
        selectedPlayer: selectedPlayer,
        active: active,
        progress: progress,
        intent: intent,
        review: review,
        runTargets: runTargets,
        showFieldLabels: false,
        showRunDistances: false);
    base.paint(canvas, size);
    final linkPaint = Paint()
      ..color = brightness == Brightness.dark
          ? const Color(0xFFDFEBE8)
          : const Color(0xFF37636A)
      ..strokeWidth = 1.5;
    for (final link in controlLinks) {
      canvas.drawLine(link.$1, link.$2, linkPaint);
      canvas.drawCircle(link.$2, 2.5, linkPaint);
    }
    final g = _PracticeGeometry(size, portrait: portrait);
    const blue = Color(0xFF245E80);
    final dark = brightness == Brightness.dark;
    final mark = dark ? const Color(0xFFF4D994) : const Color(0xFF805B18);
    final origin = touchOrigin;
    if (origin != null) {
      final at = g.toOffset(origin);
      final edge = g.toOffset(ScanPassPoint(
          origin.x + FlowEngine.touchLimitMetres / PracticeEngine.fieldLength,
          origin.y));
      canvas.drawCircle(at, (edge - at).distance,
          Paint()..color = mark.withValues(alpha: .08));
      canvas.drawCircle(
          at,
          (edge - at).distance,
          Paint()
            ..color = mark.withValues(alpha: .65)
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke);
    }
    if (selectedPlayer != null) {
      final player =
          state.attackers.firstWhere((p) => p.number == selectedPlayer);
      canvas.drawOval(
          Rect.fromCenter(
              center: g.toOffset(player.position), width: 34, height: 14),
          Paint()
            ..color = mark
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
    }
    final from = previewOrigin;
    if (pendingPassTarget != null && from != null) {
      base._arrow(
          canvas, g.toOffset(from), g.toOffset(pendingPassTarget!), blue,
          dashed: true);
    }
    final point = preview;
    if (point != null && from != null) {
      final target = g.toOffset(point);
      base._arrow(canvas, g.toOffset(from), target, mark,
          dashed: !previewTouch);
      canvas.drawCircle(target, previewTouch ? 6 : 10,
          Paint()..color = mark.withValues(alpha: .2));
      canvas.drawCircle(
          target,
          previewTouch ? 6 : 10,
          Paint()
            ..color = mark
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      if (previewTouch) {
        canvas.drawCircle(target, 2.5, Paint()..color = mark);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FlowPitchPainter oldDelegate) => true;
}
