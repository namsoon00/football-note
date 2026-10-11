part of 'scan_pass_game_screen.dart';

/// Decisions pause time. Every attacking run and ball action is player-owned;
/// only the opposition reacts automatically after the opening observation.
class ScanPassCurriculumScreen extends StatefulWidget {
  final Duration? observationDuration;
  final Duration executionDuration;

  const ScanPassCurriculumScreen({
    super.key,
    this.observationDuration,
    this.executionDuration = const Duration(seconds: 1),
  });

  @override
  State<ScanPassCurriculumScreen> createState() =>
      _ScanPassCurriculumScreenState();
}

class _ScanPassCurriculumScreenState extends State<ScanPassCurriculumScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _engine = PracticeEngine();
  late final AnimationController _controller;
  late PracticeSession _session;
  final Set<String> _reviewed = {};
  List<AttackTransition> _motion = [];
  VoidCallback? _afterMotion;
  int _index = 0;
  int _reviewIndex = 0;
  int _attackerCount = 2;
  int _selectedPlayer = 6;
  bool _passAndMove = false;
  bool _positioning = false;
  bool _placingRun = false;
  bool _catalog = true;
  bool _busy = false;
  bool _review = false;
  bool _observing = false;
  bool _paused = false;
  bool _foreground = true;
  bool _modal = false;
  bool _slow = false;
  bool _before = true;
  PracticeStep? _comparison;
  PracticeSession? _continuation;
  PracticeAction? _intent;

  AppLocalizations get _l => AppLocalizations.of(context)!;
  PracticeCase get _lesson => _session.lesson;
  String get _goalText => _session.settings.passAndMove
      ? _l.practiceReturnGoal
      : _skillGoal(_l, _lesson.skill);
  List<int> get _caseIndices => [
        for (var i = 0; i < PracticeEngine.catalog.length; i++)
          if (PracticeEngine.catalog[i].stage == _attackerCount) i
      ];
  PracticeDecision? get _decision => _session.decisions.isEmpty
      ? null
      : _session
          .decisions[_reviewIndex.clamp(0, _session.decisions.length - 1)];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session = _engine.start(PracticeEngine.catalog.first);
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        final finished = _afterMotion;
        _afterMotion = null;
        setState(() {
          _busy = false;
          _observing = false;
        });
        finished?.call();
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
    } else if (_busy && !_paused && !_modal) {
      unawaited(_controller.forward());
    }
  }

  void _open(int index) {
    _controller.stop();
    setState(() {
      _index = index;
      _session = _engine.start(PracticeEngine.catalog[index],
          settings: PracticeSettings(passAndMove: _passAndMove));
      _attackerCount = _lesson.stage;
      _selectedPlayer = _session.state.carrierNumber;
      _positioning = false;
      _placingRun = false;
      _catalog = false;
      _review = false;
      _paused = false;
      _comparison = null;
      _continuation = null;
      _intent = null;
      _observing = true;
    });
    _animate([_lesson.observation], () {}, observing: true);
  }

  void _animate(List<AttackTransition> transitions, VoidCallback done,
      {bool observing = false}) {
    _controller.stop();
    final seconds =
        transitions.fold<double>(0, (sum, item) => sum + item.duration);
    final override = observing ? widget.observationDuration : null;
    final duration = override ??
        Duration(
            milliseconds: math.max(
                1,
                (seconds *
                        widget.executionDuration.inMilliseconds /
                        (_slow ? .65 : 1))
                    .round()));
    _motion = transitions;
    _afterMotion = done;
    if (duration == Duration.zero ||
        MediaQuery.of(context).disableAnimations ||
        transitions.isEmpty) {
      setState(() {
        _busy = false;
        _observing = false;
      });
      _afterMotion = null;
      done();
      return;
    }
    setState(() => _busy = true);
    _controller.duration = duration;
    _controller.value = 0;
    if (!_paused && _foreground && !_modal) unawaited(_controller.forward());
  }

  ({AttackTransition transition, double progress})? get _active {
    if (!_busy || _motion.isEmpty) return null;
    var seconds = _motion.fold<double>(0, (sum, t) => sum + t.duration) *
        _controller.value;
    for (final transition in _motion) {
      if (seconds <= transition.duration) {
        return (
          transition: transition,
          progress: transition.duration == 0
              ? 1
              : (seconds / transition.duration).clamp(0, 1)
        );
      }
      seconds -= transition.duration;
    }
    return (transition: _motion.last, progress: 1);
  }

  AttackState get _display {
    final active = _active;
    if (active != null) return active.transition.frame(active.progress);
    if (_continuation != null) return _continuation!.state;
    if (_comparison != null) return _comparison!.session.state;
    final decision = _decision;
    if (_review && decision != null) {
      return _before || decision.transitions.isEmpty
          ? decision.before
          : decision.transitions.last.after;
    }
    return _session.state;
  }

  Map<int, ScanPassPoint> get _visibleRunTargets {
    if (_busy) {
      // A whole-play replay spans several past plans. Showing the final live
      // plan over those earlier frames would invent a command before it existed.
      if (_intent == null) return const {};
      return _comparison?.decision.runTargetsBefore ?? _session.runTargets;
    }
    if (_continuation != null) return const {};
    return _review
        ? (_comparison?.decision ?? _decision)?.runTargetsBefore ?? const {}
        : _session.runTargets;
  }

  void _choose(PracticeAction action) {
    if (_busy || _review || _catalog) return;
    _execute(_engine.choose(_session, action), action);
  }

  void _execute(PracticeStep step, PracticeAction action) {
    setState(() => _intent = action);
    _animate(step.transitions, () {
      setState(() {
        _session = step.session;
        _selectedPlayer = _session.state.carrierNumber;
        _positioning = false;
        _placingRun = false;
        _intent = null;
        if (_session.outcome != null ||
            _session.phase == PracticePhase.finished) {
          _review = true;
          _reviewIndex = _session.outcome == PracticeOutcome.intercepted
              ? _session.decisions.length - 1
              : 0;
          _before = _session.outcome != PracticeOutcome.intercepted;
          _reviewed.add(_lesson.id);
        }
      });
    });
  }

  void _tapSpace(ScanPassPoint target) {
    if (_busy ||
        _review ||
        _catalog ||
        _session.phase == PracticePhase.firstTouch) {
      return;
    }
    if (_positioning && _selectedPlayer != _session.state.carrierNumber) {
      setState(() {
        _session = _engine.planRun(_session, _selectedPlayer, target);
        _positioning = false;
        _placingRun = false;
        _selectedPlayer = _session.state.carrierNumber;
      });
      return;
    }
    final step = _engine.moveTo(_session, target,
        playerNumber: _positioning ? _selectedPlayer : null);
    _execute(step, step.decision.action);
  }

  void _replayMine() {
    _comparison = null;
    _continuation = null;
    _intent = null;
    _animate(_session.history, () => setState(() {}));
  }

  void _compare() {
    if (_decision == null || _busy) return;
    final before = _engine.beforeDecision(_session, _reviewIndex);
    final chosen = _decision!.action;
    final ranked = _engine.rankedChoices(before);
    final action = ranked.firstWhere(
        (a) =>
            a.kind != chosen.kind ||
            a.receiver != chosen.receiver ||
            PracticeEngine.distanceMetres(a.target, chosen.target) > .1,
        orElse: () => ranked.first);
    final comparison = _engine.choose(before, action);
    setState(() {
      _comparison = comparison;
      _intent = action;
    });
    _animate(comparison.transitions, () => setState(() => _intent = null));
  }

  Future<void> _help() async {
    _modal = true;
    _controller.stop();
    await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(_l.practiceHelp),
              content: SingleChildScrollView(child: Text(_l.practiceHelpBody)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(_l.close))
              ],
            ));
    if (!mounted) return;
    _modal = false;
    if (_busy && !_paused && _foreground) unawaited(_controller.forward());
  }

  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
            _catalog
                ? _l.practiceTitle
                : _session.settings.passAndMove
                    ? _l.practicePassAndMove
                    : _skillTitle(_l, _lesson.skill),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          if (!_catalog)
            AppBarActionButton.icon(
                tooltip: _l.scanPassPossessionCatalogReturnAction,
                icon: Icons.grid_view_rounded,
                onPressed: () {
                  _controller.stop();
                  setState(() {
                    _catalog = true;
                    _busy = false;
                  });
                }),
          AppBarActionButton.icon(
              tooltip: _l.practiceHelp,
              icon: Icons.help_outline,
              onPressed: _help),
        ],
      ),
      body: SafeArea(
          top: false, child: _catalog ? _buildCatalog() : _buildPractice()),
    );
  }

  Widget _buildCatalog() => LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 850;
        return SingleChildScrollView(
          key: const ValueKey('practice-catalog'),
          padding: const EdgeInsets.all(18),
          child: Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_l.practiceIntro,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Text(_l.practiceGateRule),
              const SizedBox(height: 18),
              Text(_l.practiceSetupPlayers,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, children: [
                for (final count in [2, 3, 4])
                  ChoiceChip(
                    key: ValueKey('practice-count-$count'),
                    label: Text(_l.practiceAttackers(count)),
                    selected: _attackerCount == count,
                    onSelected: (_) => setState(() => _attackerCount = count),
                  ),
              ]),
              const SizedBox(height: 12),
              Text(_l.practiceSetupPassing,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Wrap(spacing: 8, children: [
                ChoiceChip(
                    key: const ValueKey('practice-mode-free'),
                    label: Text(_l.practiceFreePlay),
                    selected: !_passAndMove,
                    onSelected: (_) => setState(() => _passAndMove = false)),
                ChoiceChip(
                    key: const ValueKey('practice-mode-return'),
                    label: Text(_l.practicePassAndMove),
                    selected: _passAndMove,
                    onSelected: (_) => setState(() => _passAndMove = true)),
              ]),
              Text(_passAndMove
                  ? _l.practicePassAndMoveDescription
                  : _l.practiceFreePlayDescription),
              const SizedBox(height: 20),
              Wrap(spacing: 14, runSpacing: 14, children: [
                for (final i in _caseIndices)
                  SizedBox(
                      width: wide
                          ? (math.min(1180, constraints.maxWidth - 36) - 28) / 3
                          : constraints.maxWidth >= 560
                              ? (constraints.maxWidth - 50) / 2
                              : constraints.maxWidth - 36,
                      child: _catalogCard(i)),
              ]),
            ]),
          )),
        );
      });

  Widget _catalogCard(int index) {
    final lesson = PracticeEngine.catalog[index];
    final colors = _ScanPassColors.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        key: ValueKey('practice-case-${lesson.id}'),
        onTap: () => _open(index),
        child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                      child: Text(
                          _l.practiceStage(lesson.reception.attackers.length,
                              lesson.reception.defenders.length),
                          style: TextStyle(fontSize: 12, color: colors.muted))),
                  if (_reviewed.contains(lesson.id))
                    Tooltip(
                        message: _l.practiceCompleted,
                        child:
                            const Icon(Icons.check_circle_outline, size: 18)),
                ]),
                const SizedBox(height: 8),
                Text(
                    _passAndMove
                        ? _l.practicePassAndMove
                        : _skillTitle(_l, lesson.skill),
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(_conditionLabel(_l, lesson),
                    style: TextStyle(color: colors.muted)),
                const SizedBox(height: 12),
                SizedBox(
                    height: 118,
                    width: double.infinity,
                    child: CustomPaint(
                        painter: _CurriculumPitchPainter(
                            state: lesson.reception,
                            lesson: lesson,
                            l10n: _l,
                            brightness: Theme.of(context).brightness,
                            fontFamily: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.fontFamily,
                            miniature: true))),
                const SizedBox(height: 12),
                Text(
                    _passAndMove
                        ? _l.practiceReturnGoal
                        : _skillGoal(_l, lesson.skill),
                    style: const TextStyle(height: 1.4)),
              ],
            )),
      ),
    );
  }

  Widget _buildPractice() => AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => LayoutBuilder(builder: (context, constraints) {
            final landscape =
                constraints.maxWidth > constraints.maxHeight * 1.6;
            final showReview = _review && !_busy;
            final panelWidth = landscape && showReview
                ? math.min(340.0, constraints.maxWidth * .42)
                : 0.0;
            final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
            final hudHeight = landscape
                ? math.max(64.0, 52 * textScale + 12)
                : math.max(116.0, 86 * textScale + 30) +
                    (constraints.maxWidth < 360 && textScale > 1.1 ? 26 : 0);
            final panelHeight = !landscape && showReview
                ? math.min(constraints.maxHeight * .46, 320.0)
                : 0.0;
            final pitch = Rect.fromLTWH(
                panelWidth,
                hudHeight,
                constraints.maxWidth - panelWidth,
                math.max(120, constraints.maxHeight - hudHeight - panelHeight));
            final size = pitch.size;
            final portrait = constraints.maxHeight > constraints.maxWidth * 1.1;
            final geometry = _PracticeGeometry(size, portrait: portrait);
            final canMove = !_busy &&
                !_review &&
                _session.phase != PracticePhase.firstTouch;
            final actions = !_busy && !_review && !_positioning
                ? [
                    ..._engine.choices(_session).where((a) =>
                        _session.phase == PracticePhase.firstTouch ||
                        a.kind == PracticeActionKind.pass ||
                        a.kind == PracticeActionKind.through ||
                        a.kind == PracticeActionKind.hold),
                    for (final run in _session.runTargets.entries)
                      PracticeAction(
                          id: 'run-${run.key}',
                          kind: PracticeActionKind.move,
                          actorNumber: run.key,
                          target: run.value),
                  ]
                : <PracticeAction>[];
            final reserved = <Rect>[
              if (canMove) const Rect.fromLTWH(6, 4, 124, 44),
              ..._practiceRunLabels(_session.runTargets, geometry).values,
              if (_positioning &&
                  _session.runTargets.containsKey(_selectedPlayer))
                Rect.fromLTWH(size.width - 136, 4, 130, 44),
            ];
            final centers = _practiceActionCenters(actions, geometry, _display,
                reserved: reserved);
            final selectors = _positioning && !_placingRun
                ? [
                    for (final p in _display.attackers)
                      PracticeAction(
                          id: 'select-${p.number}',
                          kind: PracticeActionKind.pass,
                          target: p.position,
                          receiver: p.number),
                  ]
                : <PracticeAction>[];
            final selectorCenters = _practiceActionCenters(
                selectors, geometry, _display,
                reserved: reserved);
            return ColoredBox(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF162E29)
                  : const Color(0xFFD4E1D5),
              child: Stack(children: [
                Positioned.fromRect(
                    rect: pitch,
                    child: GestureDetector(
                      key: const ValueKey('practice-pitch'),
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) =>
                          _tapSpace(geometry.fromOffset(details.localPosition)),
                      child: Stack(children: [
                        Positioned.fill(
                            child: CustomPaint(
                                key: const ValueKey('practice-pitch-paint'),
                                painter: _CurriculumPitchPainter(
                                  state: _display,
                                  lesson: _lesson,
                                  l10n: _l,
                                  brightness: Theme.of(context).brightness,
                                  fontFamily: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.fontFamily,
                                  active: _active?.transition,
                                  progress: _active?.progress ?? 0,
                                  intent: _intent,
                                  selectedPlayer: _positioning
                                      ? _selectedPlayer
                                      : _display.carrierNumber,
                                  portrait: portrait,
                                  runTargets: _visibleRunTargets,
                                  touchOptions: _session.phase ==
                                              PracticePhase.firstTouch &&
                                          !_busy &&
                                          !_review
                                      ? actions
                                      : const [],
                                  review: _review && !_busy
                                      ? (_comparison?.decision ?? _decision)
                                      : null,
                                  controlLinks: [
                                    for (var i = 0; i < actions.length; i++)
                                      if (actions[i].kind !=
                                          PracticeActionKind.hold)
                                        (
                                          from: centers[i],
                                          to: geometry.toOffset(
                                              actions[i].kind ==
                                                      PracticeActionKind.pass
                                                  ? _display.attackers
                                                      .firstWhere((p) =>
                                                          p.number ==
                                                          actions[i].receiver)
                                                      .position
                                                  : actions[i].target)
                                        ),
                                    for (var i = 0; i < selectors.length; i++)
                                      (
                                        from: selectorCenters[i],
                                        to: geometry
                                            .toOffset(selectors[i].target)
                                      ),
                                  ],
                                ))),
                        for (var i = 0; i < actions.length; i++)
                          _actionButton(actions[i], centers[i], geometry),
                        if (canMove)
                          Positioned(
                              left: 6,
                              top: 4,
                              width: 124,
                              height: 44,
                              child: FilledButton.tonalIcon(
                                key: const ValueKey('practice-position-mode'),
                                style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8)),
                                onPressed: () => setState(() {
                                  if (_placingRun) {
                                    _placingRun = false;
                                  } else {
                                    _positioning = !_positioning;
                                    _selectedPlayer =
                                        _session.state.carrierNumber;
                                  }
                                }),
                                icon: Icon(
                                    _positioning
                                        ? Icons.sports_soccer
                                        : Icons.open_with,
                                    size: 17),
                                label: FittedBox(
                                    child: Text(_placingRun
                                        ? _l.practiceChangePlayer
                                        : _positioning
                                            ? _l.practiceBackToBall
                                            : _l.practiceSetMovement)),
                              )),
                        for (var i = 0; i < selectors.length; i++)
                          _playerSelector(
                              selectors[i].receiver!, selectorCenters[i]),
                        if (_positioning &&
                            _session.runTargets.containsKey(_selectedPlayer))
                          Positioned(
                              right: 6,
                              top: 4,
                              width: 130,
                              height: 44,
                              child: FilledButton.tonal(
                                key: const ValueKey('practice-cancel-run'),
                                onPressed: () => setState(() {
                                  _session = _engine.cancelRun(
                                      _session, _selectedPlayer);
                                }),
                                child: FittedBox(
                                    child: Text(
                                        _l.practiceCancelRun(_selectedPlayer))),
                              )),
                      ]),
                    )),
                Positioned(
                    left: 0,
                    top: 0,
                    right: 0,
                    height: hudHeight,
                    child: _hud(landscape)),
                if (showReview)
                  Positioned(
                      left: 0,
                      top: landscape ? hudHeight : null,
                      bottom: 0,
                      width: landscape ? panelWidth : constraints.maxWidth,
                      height: landscape ? null : panelHeight,
                      child: _reviewPanel()),
              ]),
            );
          }));

  Widget _hud(bool compact) {
    final colors = _ScanPassColors.of(context);
    final message = _busy
        ? (_observing
            ? _l.practiceObserve
            : _intent != null
                ? _actionLabel(_intent!)
                : _l.practiceExecuting)
        : _review
            ? (_comparison != null
                ? _l.practiceCompareLabel
                : _l.practiceReview)
            : _positioning
                ? _placingRun
                    ? _l.practiceChooseDestination(_selectedPlayer)
                    : _l.practiceChoosePlayerRun(_selectedPlayer)
                : switch (_session.phase) {
                    PracticePhase.firstTouch => _l.practiceChooseTouch,
                    PracticePhase.onBall =>
                      _l.practiceChooseBallFor(_session.state.carrierNumber),
                    PracticePhase.support => _l.practiceChooseSupport,
                    PracticePhase.finished => _l.practiceReview,
                  };
    return Material(
        color: colors.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
                child: SingleChildScrollView(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                  Text(
                      compact && _session.returnTarget != null
                          ? _l.practiceReturnTarget(_session.returnTarget!)
                          : _goalText,
                      style: TextStyle(
                          fontSize: compact ? 12 : 13, color: colors.muted)),
                  const SizedBox(height: 4),
                  Text(message,
                      style: TextStyle(
                          fontSize: compact ? 12 : 14,
                          fontWeight: FontWeight.w700)),
                  if (!compact)
                    Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                            _intent != null
                                ? _actionLabel(_intent!)
                                : _positioning
                                    ? _l.practiceRunPlanHint
                                    : _session.returnTarget != null
                                        ? _l.practiceReturnTarget(
                                            _session.returnTarget!)
                                        : _session.runTargets.isNotEmpty
                                            ? _l.practiceRunsReady(
                                                _session.runTargets.length)
                                            : _l.practiceTeamControl,
                            style:
                                TextStyle(fontSize: 11, color: colors.muted))),
                ]))),
            const SizedBox(width: 6),
            if (_busy)
              _smallButton(
                  _paused
                      ? _l.scanPassPossessionResume
                      : _l.scanPassPossessionPause,
                  _paused ? Icons.play_arrow : Icons.pause,
                  () => setState(() {
                        _paused = !_paused;
                        if (_paused) {
                          _controller.stop();
                        } else {
                          unawaited(_controller.forward());
                        }
                      })),
            _smallButton(
                _l.scanPassPossessionSlowMotionTooltip,
                _slow ? Icons.slow_motion_video : Icons.speed,
                () => setState(() {
                      _slow = !_slow;
                      if (_busy) {
                        final value = _controller.value;
                        _controller.duration = Duration(
                            milliseconds:
                                (_controller.duration!.inMilliseconds *
                                        (_slow ? 1 / .65 : .65))
                                    .round());
                        if (!_paused) {
                          unawaited(_controller.forward(from: value));
                        }
                      }
                    })),
          ]),
        ));
  }

  Widget _smallButton(String label, IconData icon, VoidCallback action) =>
      Tooltip(
          message: label,
          child: SizedBox(
              width: 44,
              height: 44,
              child: OutlinedButton(
                  onPressed: action,
                  style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child:
                      Semantics(label: label, child: Icon(icon, size: 21)))));

  String _actionLabel(PracticeAction action) {
    final from = _session.state.attackers
        .firstWhere((p) =>
            p.number == (action.actorNumber ?? _session.state.carrierNumber))
        .position;
    final metres = math
        .sqrt(math.pow((action.target.x - from.x) * 40, 2) +
            math.pow((action.target.y - from.y) * 28, 2))
        .toStringAsFixed(1);
    return switch (action.kind) {
      PracticeActionKind.touch => _l.practiceTouch(metres),
      PracticeActionKind.carry => _l.practiceCarry(metres),
      PracticeActionKind.move => _l.practicePlayerMove(
          action.actorNumber ?? _session.state.carrierNumber, metres),
      PracticeActionKind.pass => _l.practicePass(action.receiver!),
      PracticeActionKind.through => _l.practiceThrough(action.receiver!),
      PracticeActionKind.hold => _l.practiceAdvance,
    };
  }

  Widget _playerSelector(int number, Offset center) => Positioned(
        left: center.dx - 24,
        top: center.dy - 24,
        width: 48,
        height: 48,
        child: Tooltip(
          message: _l.practiceSelectPlayer(number),
          child: OutlinedButton(
            key: ValueKey('practice-player-$number'),
            onPressed: () => setState(() {
              _selectedPlayer = number;
              _placingRun = true;
            }),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: _selectedPlayer == number
                  ? const Color(0xFF155C72).withValues(alpha: .88)
                  : Colors.transparent,
              side: BorderSide(
                  color: _selectedPlayer == number
                      ? const Color(0xFFFADE84)
                      : const Color(0xFF155C72),
                  width: 2),
              shape: const CircleBorder(),
            ),
            child: Semantics(
                label: _l.practiceSelectPlayer(number),
                selected: _selectedPlayer == number,
                child: _selectedPlayer == number
                    ? Text(number.toString(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold))
                    : const SizedBox.expand()),
          ),
        ),
      );

  Widget _actionButton(
      PracticeAction action, Offset center, _PitchGeometry geometry) {
    final isPass = action.kind == PracticeActionKind.pass;
    final isHold = action.kind == PracticeActionKind.hold;
    final isTouch = action.kind == PracticeActionKind.touch;
    final player = _display.attackers.firstWhere(
        (p) => p.number == (action.actorNumber ?? _display.carrierNumber));
    final delta =
        geometry.toOffset(action.target) - geometry.toOffset(player.position);
    final metres = PracticeEngine.distanceMetres(player.position, action.target)
        .toStringAsFixed(1);
    final label = isTouch
        ? _l.practiceTouchDestination(_touchNumber(action), metres)
        : _actionLabel(action);
    return Positioned(
      left: center.dx - 24,
      top: center.dy - 24,
      width: 48,
      height: 48,
      child: Tooltip(
          message: label,
          child: Semantics(
            button: true,
            label: label,
            child: OutlinedButton(
              key: ValueKey('practice-action-${action.id}'),
              onPressed: () => _choose(action),
              style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: isPass
                      ? Colors.transparent
                      : isTouch
                          ? _touchColor(action)
                          : const Color(0xFF183F42).withValues(alpha: .90),
                  foregroundColor: Colors.white,
                  side: BorderSide(
                      color: isPass ? const Color(0xFF1B4E67) : Colors.white70,
                      width: 1.5),
                  shape: const CircleBorder()),
              child: isPass
                  ? const SizedBox.expand()
                  : isHold
                      ? const Icon(Icons.play_arrow_rounded, size: 25)
                      : action.kind == PracticeActionKind.move
                          ? const Icon(Icons.directions_run_rounded, size: 24)
                          : isTouch
                              ? FittedBox(
                                  child: Padding(
                                      padding: const EdgeInsets.all(3),
                                      child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                      _touchNumber(action)
                                                          .toString(),
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w800)),
                                                  Transform.rotate(
                                                      angle: math.atan2(
                                                          delta.dy, delta.dx),
                                                      child: const Icon(
                                                          Icons
                                                              .arrow_forward_rounded,
                                                          size: 18)),
                                                ]),
                                            Text(_l.practiceMetres(metres),
                                                style: const TextStyle(
                                                    fontSize: 10)),
                                          ])))
                              : Transform.rotate(
                                  angle: math.atan2(delta.dy, delta.dx),
                                  child: Icon(
                                      action.kind == PracticeActionKind.through
                                          ? Icons.double_arrow_rounded
                                          : Icons.arrow_forward_rounded,
                                      size: 23)),
            ),
          )),
    );
  }

  Widget _reviewPanel() {
    final decision = _comparison?.decision ?? _decision;
    if (decision == null) return const SizedBox.shrink();
    final colors = _ScanPassColors.of(context);
    final outcome = _continuation?.outcome ??
        (_comparison != null ? _comparison!.session.outcome : _session.outcome);
    return Material(
      color: colors.surface,
      child: SingleChildScrollView(
        key: const ValueKey('practice-review'),
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (outcome != null)
            Text(
                outcome == PracticeOutcome.intercepted
                    ? _l.practiceStolenBy((_continuation?.state ??
                            _comparison?.session.state ??
                            _session.state)
                        .carrierNumber)
                    : _outcomeLabel(_l, outcome),
                style: TextStyle(fontSize: 12, color: colors.muted)),
          Row(children: [
            Expanded(
                child: Text(
                    _l.practiceDecision(
                        _reviewIndex + 1, _session.decisions.length),
                    style: const TextStyle(fontWeight: FontWeight.w700))),
            _smallButton(
                _l.practicePreviousDecision,
                Icons.chevron_left,
                () => _selectReview((_reviewIndex - 1)
                    .clamp(0, _session.decisions.length - 1))),
            _smallButton(
                _l.next,
                Icons.chevron_right,
                () => _selectReview((_reviewIndex + 1)
                    .clamp(0, _session.decisions.length - 1))),
          ]),
          Text(decision.useful ? _l.practiceUseful : _l.practiceReconsider,
              style: TextStyle(
                  color: decision.useful ? colors.accent : colors.muted,
                  fontWeight: FontWeight.w700)),
          if (decision.goalDemonstrated)
            Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_l.practiceLearningEvidence,
                    style: TextStyle(fontSize: 11, color: colors.muted))),
          const SizedBox(height: 9),
          Text(_l.practiceRead,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          Text(_observation(decision),
              style: const TextStyle(fontSize: 13, height: 1.45)),
          const SizedBox(height: 8),
          Text(_l.practiceEffect,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          Text(_reasonLabel(_l, decision.reason),
              style: const TextStyle(fontSize: 13, height: 1.45)),
          const SizedBox(height: 5),
          Text(_evidence(decision),
              style: TextStyle(fontSize: 12, color: colors.muted)),
          const SizedBox(height: 8),
          Text(_l.practiceNextFocus,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          Text(_advice(decision),
              style: const TextStyle(fontSize: 13, height: 1.45)),
          const SizedBox(height: 8),
          if (_comparison == null)
            Wrap(spacing: 6, children: [
              ChoiceChip(
                  label: Text(_l.practiceRead),
                  selected: _before,
                  onSelected: (_) => setState(() => _before = true)),
              ChoiceChip(
                  label: Text(_l.practiceEffect),
                  selected: !_before,
                  onSelected: (_) => setState(() => _before = false)),
            ]),
          Wrap(spacing: 6, runSpacing: 4, children: [
            OutlinedButton(
                key: const ValueKey('practice-replay'),
                onPressed: _replayMine,
                child: Text(_l.practiceReplayMine)),
            if (_comparison == null)
              OutlinedButton(
                  key: const ValueKey('practice-compare'),
                  onPressed: _compare,
                  child: Text(_l.practiceCompare))
            else
              OutlinedButton(
                  onPressed: () => setState(() {
                        _comparison = null;
                        _continuation = null;
                        _before = true;
                      }),
                  child: Text(_l.practiceBackReview)),
          ]),
          if (_comparison != null)
            OutlinedButton(
                key: const ValueKey('practice-continuation'),
                onPressed: _continueAlternative,
                child: Text(_l.practiceContinueAlternative)),
          if (_continuation != null)
            Text(_l.practiceContinuationNote,
                style: TextStyle(fontSize: 12, color: colors.muted)),
          if (_comparison != null)
            Text(_l.practiceCompareNote,
                style: TextStyle(fontSize: 12, color: colors.muted)),
          const Divider(),
          Wrap(spacing: 6, runSpacing: 4, children: [
            FilledButton(
                key: const ValueKey('practice-retry'),
                onPressed: () => _open(_index),
                child: Text(_l.practiceRetry)),
            OutlinedButton(
                key: const ValueKey('practice-pair'),
                onPressed: () => _open(_index.isEven ? _index + 1 : _index - 1),
                child: Text(_l.practicePair)),
            OutlinedButton(
                key: const ValueKey('practice-next'),
                onPressed: () => _open(_caseIndices[
                    (_caseIndices.indexOf(_index) + 1) % _caseIndices.length]),
                child: Text(_l.practiceNext)),
          ]),
        ]),
      ),
    );
  }

  void _continueAlternative() {
    if (_comparison == null || _busy) return;
    var continued = _comparison!.session;
    while (!continued.finished) {
      continued =
          _engine.choose(continued, _engine.recommended(continued)).session;
    }
    setState(() => _continuation = continued);
    final start = _engine.beforeDecision(_session, _reviewIndex).history.length;
    _animate(continued.history.skip(start).toList(), () => setState(() {}));
  }

  String _observation(PracticeDecision d) {
    if (d.cue == PracticeCue.pressureSide ||
        d.cue == PracticeCue.defenderCommitment) {
      final me = d.before.attackers.firstWhere(
          (p) => p.number == (d.action.actorNumber ?? d.before.carrierNumber));
      final defenders = [...d.before.defenders]
        ..sort((a, b) => PracticeEngine.distanceMetres(a.position, me.position)
            .compareTo(PracticeEngine.distanceMetres(b.position, me.position)));
      final nearest = defenders.first;
      final distance =
          PracticeEngine.distanceMetres(nearest.position, me.position)
              .toStringAsFixed(1);
      final dy =
          (nearest.position.y - me.position.y) * PracticeEngine.fieldWidth;
      return dy < -.8
          ? _l.practiceEvidenceUpper(nearest.number, distance)
          : dy > .8
              ? _l.practiceEvidenceLower(nearest.number, distance)
              : _l.practiceEvidenceLevel(nearest.number, distance);
    }
    if (d.cue == PracticeCue.runnerTiming) {
      final runners = d.before.attackers
          .where((p) => p.number != d.before.carrierNumber)
          .toList()
        ..sort((a, b) => b.velocity.x.compareTo(a.velocity.x));
      final runner = runners.firstWhere((p) => p.number == d.action.receiver,
          orElse: () => runners.first);
      final planned = d.runTargetsBefore[runner.number];
      final forward = planned == null
          ? runner.velocity.x * PracticeEngine.fieldLength
          : (planned.x - runner.position.x) * PracticeEngine.fieldLength;
      if (forward > .5) {
        return _l.practiceEvidenceForwardRun(runner.number);
      }
      if (forward < -.5) {
        return _l.practiceEvidenceCheckingRun(runner.number);
      }
      return _l.practiceEvidenceWaitingRun(runner.number);
    }
    if (d.cue == PracticeCue.supportLane) {
      return _l.practiceEvidenceSupport(d.laneBefore.toStringAsFixed(1));
    }
    if (d.cue == PracticeCue.farSideSpace) {
      final count = d.before.defenders
          .where((p) => (p.position.y < .5) == (d.before.ball.y < .5))
          .length;
      return _l.practiceEvidenceFarSide(count);
    }
    return _l.practiceEvidenceConnections(d.optionsBefore);
  }

  String _advice(PracticeDecision d) {
    if (d.after.carrierIsDefender && d.action.kind == PracticeActionKind.hold) {
      return _l.practiceAdviceStealHold;
    }
    if (d.reason == PracticeReason.offsideAtKick) {
      return _l.practiceAdviceOffside;
    }
    return switch (d.action.kind) {
      PracticeActionKind.touch => _l.practiceAdviceTouch,
      PracticeActionKind.carry => _l.practiceAdviceCarry,
      PracticeActionKind.pass => _l.practiceAdvicePass,
      PracticeActionKind.through => _l.practiceAdviceThrough,
      PracticeActionKind.move => _l.practiceAdviceSupport,
      PracticeActionKind.hold => d.phaseBefore == PracticePhase.support
          ? _l.practiceAdviceSupport
          : _goalText,
    };
  }

  void _selectReview(int index) => setState(() {
        _reviewIndex = index;
        _comparison = null;
        _continuation = null;
        _before = true;
      });

  String _evidence(PracticeDecision d) {
    final defender = d.transitions.first.interceptorNumber;
    if (defender != null) return _l.practiceStealEvidence(defender);
    return switch (d.cue) {
      PracticeCue.pressureSide ||
      PracticeCue.defenderCommitment =>
        _l.practicePressureEvidence(d.pressureBefore.toStringAsFixed(1),
            d.pressureAfter.toStringAsFixed(1)),
      PracticeCue.runnerTiming ||
      PracticeCue.passingLane ||
      PracticeCue.supportLane =>
        _l.practiceLaneEvidence(
            d.laneBefore.toStringAsFixed(1), d.laneAfter.toStringAsFixed(1)),
      PracticeCue.thirdPlayerLane ||
      PracticeCue.farSideSpace =>
        _l.practiceOptionsEvidence(
            d.optionsBefore.toString(), d.optionsAfter.toString()),
    };
  }
}

List<Offset> _practiceActionCenters(
    List<PracticeAction> actions, _PitchGeometry geometry, AttackState state,
    {List<Rect> reserved = const []}) {
  final placed = <Offset>[];
  final size = geometry.size;
  Offset bounded(Offset p) => Offset(
      p.dx.clamp(27.0, math.max(27, size.width - 27)),
      p.dy.clamp(27.0, math.max(27, size.height - 27)));
  // Put foot passes directly on jerseys first. Other controls can spread to
  // avoid hitbox overlap; fine connector lines retain the actual destination.
  final centers = List<Offset>.filled(actions.length, Offset.zero);
  final order = List<int>.generate(actions.length, (i) => i)
    ..sort((a, b) => (actions[a].kind == PracticeActionKind.pass ? 0 : 1)
        .compareTo(actions[b].kind == PracticeActionKind.pass ? 0 : 1));
  for (final index in order) {
    final action = actions[index];
    final touchDelta =
        geometry.toOffset(action.target) - geometry.toOffset(state.ball);
    final raw = action.kind == PracticeActionKind.touch
        ? geometry.toOffset(state.ball) +
            touchDelta /
                math.max(.01, touchDelta.distance) *
                math.max(78, touchDelta.distance + 48)
        : action.kind == PracticeActionKind.pass
            ? geometry.toOffset(state.attackers
                    .firstWhere((p) => p.number == action.receiver)
                    .position) -
                const Offset(0, 16.52)
            : action.kind == PracticeActionKind.hold
                ? Offset(34, size.height - 34)
                : geometry.toOffset(action.target);
    var candidate = bounded(raw);
    bool clear(Offset p) =>
        placed.every((q) => (p - q).distance >= 51) &&
        reserved
            .every((r) => !r.overlaps(Rect.fromCircle(center: p, radius: 27)));
    if (!clear(candidate)) {
      final candidates = <Offset>[];
      for (var radius = 52.0;
          radius <= math.max(size.width, size.height);
          radius += 26) {
        for (var j = 0; j < 16; j++) {
          final angle = math.pi * 2 * j / 16;
          final point =
              bounded(raw + Offset(math.cos(angle), math.sin(angle)) * radius);
          if (clear(point)) candidates.add(point);
        }
        if (candidates.isNotEmpty) break;
      }
      if (candidates.isNotEmpty) {
        candidates
            .sort((a, b) => (a - raw).distance.compareTo((b - raw).distance));
        candidate = candidates.first;
      }
    }
    centers[index] = candidate;
    placed.add(candidate);
  }
  return centers;
}

Map<int, Rect> _practiceRunLabels(
    Map<int, ScanPassPoint> targets, _PitchGeometry geometry) {
  final placed = <int, Rect>{};
  final width = math.min(148.0, geometry.size.width - 12);
  for (final entry in targets.entries) {
    final target = geometry.toOffset(entry.value);
    Rect at(double shift) => Rect.fromCenter(
        center: Offset(
            target.dx.clamp(width / 2 + 6, geometry.size.width - width / 2 - 6),
            (target.dy + 25 + shift)
                .clamp(60.0, math.max(60, geometry.size.height - 24))),
        width: width,
        height: 22);
    var rect = at(0);
    for (final shift in [0.0, 28.0, -54.0, 56.0, -82.0]) {
      final candidate = at(shift);
      if (placed.values.every((r) => !r.inflate(3).overlaps(candidate))) {
        rect = candidate;
        break;
      }
    }
    placed[entry.key] = rect;
  }
  return placed;
}

int _touchNumber(PracticeAction action) => switch (action.id) {
      'touch-forward' => 1,
      'touch-upper' => 2,
      _ => 3,
    };

Color _touchColor(PracticeAction action) => switch (_touchNumber(action)) {
      1 => const Color(0xFF176782),
      2 => const Color(0xFF73559B),
      _ => const Color(0xFF8B5B23),
    };

String _skillTitle(AppLocalizations l, PracticeSkill skill) => switch (skill) {
      PracticeSkill.firstTouch => l.practiceSkillFirstTouch,
      PracticeSkill.drawDefender => l.practiceSkillDrawDefender,
      PracticeSkill.throughPass => l.practiceSkillThroughPass,
      PracticeSkill.supportAngle => l.practiceSkillSupportAngle,
      PracticeSkill.thirdPlayer => l.practiceSkillThirdPlayer,
      PracticeSkill.switchPlay => l.practiceSkillSwitchPlay,
    };
String _skillGoal(AppLocalizations l, PracticeSkill skill) => switch (skill) {
      PracticeSkill.firstTouch => l.practiceGoalFirstTouch,
      PracticeSkill.drawDefender => l.practiceGoalDrawDefender,
      PracticeSkill.throughPass => l.practiceGoalThroughPass,
      PracticeSkill.supportAngle => l.practiceGoalSupportAngle,
      PracticeSkill.thirdPlayer => l.practiceGoalThirdPlayer,
      PracticeSkill.switchPlay => l.practiceGoalSwitchPlay,
    };
String _reasonLabel(AppLocalizations l, PracticeReason reason) =>
    switch (reason) {
      PracticeReason.touchOpensView => l.practiceReasonTouchOpensView,
      PracticeReason.touchIntoPressure => l.practiceReasonTouchIntoPressure,
      PracticeReason.defenderDrawn => l.practiceReasonDefenderDrawn,
      PracticeReason.carryIntoCover => l.practiceReasonCarryIntoCover,
      PracticeReason.runnerMetInStride => l.practiceReasonRunnerMetInStride,
      PracticeReason.runnerNotReady => l.practiceReasonRunnerNotReady,
      PracticeReason.possessionSecured => l.practiceReasonPossessionSecured,
      PracticeReason.receivedUnderPressure =>
        l.practiceReasonReceivedUnderPressure,
      PracticeReason.passToFeet => l.practiceReasonPassToFeet,
      PracticeReason.passLaneClosed => l.practiceReasonPassLaneClosed,
      PracticeReason.supportLaneOpened => l.practiceReasonSupportLaneOpened,
      PracticeReason.supportStillHidden => l.practiceReasonSupportStillHidden,
      PracticeReason.thirdPlayerConnected =>
        l.practiceReasonThirdPlayerConnected,
      PracticeReason.farSideOpened => l.practiceReasonFarSideOpened,
      PracticeReason.holdCreatesWindow => l.practiceReasonHoldCreatesWindow,
      PracticeReason.holdUnderPressure => l.practiceReasonHoldUnderPressure,
      PracticeReason.controlledGate => l.practiceReasonControlledGate,
      PracticeReason.offsideAtKick => l.practiceReasonOffsideAtKick,
    };
String _outcomeLabel(AppLocalizations l, PracticeOutcome outcome) =>
    switch (outcome) {
      PracticeOutcome.gateReached => l.practiceGateReached,
      PracticeOutcome.retained => l.practiceRetained,
      PracticeOutcome.intercepted => l.practiceIntercepted,
      PracticeOutcome.offside => l.practiceOffsideEnd,
    };

/// Preserve metres on both axes. Portrait phones face up the pitch, rather
/// than stretching a wide 40 x 28 m practice into a misleading tall rectangle.
class _PracticeGeometry extends _PitchGeometry {
  final bool? _portrait;
  _PracticeGeometry(super.size, {bool? portrait})
      : _portrait = portrait,
        super(space: true);
  bool get portrait => _portrait ?? size.height > size.width * 1.1;
  late final Rect _practiceRect = _field();
  @override
  Rect get fieldRect => _practiceRect;

  Rect _field() {
    final available =
        Size(math.max(1, size.width - 36), math.max(1, size.height - 40));
    final ratio = portrait
        ? PracticeEngine.fieldWidth / PracticeEngine.fieldLength
        : PracticeEngine.fieldLength / PracticeEngine.fieldWidth;
    final width = math.min(available.width, available.height * ratio);
    final height = width / ratio;
    return Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: width,
        height: height);
  }

  @override
  Offset toOffset(ScanPassPoint p) => portrait
      ? Offset(fieldRect.left + p.y * fieldRect.width,
          fieldRect.bottom - p.x * fieldRect.height)
      : Offset(fieldRect.left + p.x * fieldRect.width,
          fieldRect.top + p.y * fieldRect.height);
  @override
  ScanPassPoint fromOffset(Offset p) => PracticeEngine.boundedTarget(portrait
      ? ScanPassPoint((fieldRect.bottom - p.dy) / fieldRect.height,
          (p.dx - fieldRect.left) / fieldRect.width)
      : ScanPassPoint((p.dx - fieldRect.left) / fieldRect.width,
          (p.dy - fieldRect.top) / fieldRect.height));
}

class _CurriculumPitchPainter extends CustomPainter {
  final AttackState state;
  final PracticeCase lesson;
  final AppLocalizations l10n;
  final Brightness brightness;
  final String? fontFamily;
  final bool miniature;
  final AttackTransition? active;
  final double progress;
  final PracticeAction? intent;
  final PracticeDecision? review;
  final int? selectedPlayer;
  final Map<int, ScanPassPoint> runTargets;
  final List<PracticeAction> touchOptions;
  final bool? portrait;
  final List<({Offset from, Offset to})> controlLinks;
  final bool showFieldLabels;
  final bool showRunDistances;

  const _CurriculumPitchPainter(
      {required this.state,
      required this.lesson,
      required this.l10n,
      required this.brightness,
      this.fontFamily,
      this.miniature = false,
      this.active,
      this.progress = 0,
      this.intent,
      this.review,
      this.selectedPlayer,
      this.runTargets = const {},
      this.touchOptions = const [],
      this.portrait,
      this.controlLinks = const [],
      this.showFieldLabels = true,
      this.showRunDistances = true});

  Offset offsetFor(ScanPassPoint point, Size size) =>
      _PracticeGeometry(size, portrait: portrait).toOffset(point);

  @override
  void paint(Canvas canvas, Size size) {
    final g = _PracticeGeometry(size, portrait: portrait);
    final dark = brightness == Brightness.dark;
    final textColor = dark ? const Color(0xFFE8F1EE) : const Color(0xFF203A36);
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = dark ? const Color(0xFF1B3931) : const Color(0xFFD4E1D5));
    for (var i = 0; i < 8; i += 2) {
      canvas.drawRect(
          Rect.fromLTWH(g.fieldRect.left + g.fieldRect.width * i / 8,
              g.fieldRect.top, g.fieldRect.width / 8, g.fieldRect.height),
          Paint()
            ..color = (dark ? Colors.white : const Color(0xFF23453B))
                .withValues(alpha: .04));
    }
    final line = Paint()
      ..color = textColor.withValues(alpha: .3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(g.fieldRect, line);
    canvas.drawLine(g.toOffset(const ScanPassPoint(.5, 0)),
        g.toOffset(const ScanPassPoint(.5, 1)), line);
    if (!miniature && showFieldLabels) {
      _text(
          canvas,
          g.portrait
              ? l10n.practiceAttackUp
              : l10n.scanPassAttackDirectionShort,
          Offset(g.fieldRect.center.dx, 10),
          textColor,
          10);
    }
    if (!miniature && showFieldLabels) {
      _text(
          canvas,
          lesson.offsideEnabled ? l10n.practiceOffside : l10n.practiceNoOffside,
          Offset(g.fieldRect.center.dx, size.height - 10),
          textColor,
          10);
    }
    for (var i = 0; i < lesson.gates.length; i++) {
      final gate = lesson.gates[i];
      final a = g.toOffset(
          ScanPassPoint(gate.center.x, gate.center.y - gate.halfWidth));
      final b = g.toOffset(
          ScanPassPoint(gate.center.x, gate.center.y + gate.halfWidth));
      _dashed(canvas, a, b, const Color(0xFFC78934), 2);
      _cone(canvas, a, miniature ? 5 : 8);
      _cone(canvas, b, miniature ? 5 : 8);
      if (!miniature) {
        _text(canvas, l10n.practiceGate(i + 1), Offset(a.dx, a.dy - 16),
            textColor, 10);
      }
    }
    if (lesson.offsideEnabled && state.defenders.length >= 2) {
      final xs = state.defenders.map((p) => p.position.x).toList()..sort();
      final lineX = math.max(.5, math.max(state.ball.x, xs[xs.length - 2]));
      _dashed(
          canvas,
          g.toOffset(ScanPassPoint(lineX, 0)),
          g.toOffset(ScanPassPoint(lineX, 1)),
          const Color(0xFFC08561).withValues(alpha: .65),
          1);
    }
    for (final p in [...state.attackers, ...state.defenders]) {
      final from = g.toOffset(p.position);
      final to = g.toOffset(ScanPassPoint(p.position.x + p.velocity.x * .55,
          p.position.y + p.velocity.y * .55));
      if ((to - from).distance > 4) {
        _arrow(canvas, from, to,
            p.opponent ? const Color(0xFFB77761) : const Color(0xFF367F98),
            dashed: true);
      }
    }
    final runLabels = _practiceRunLabels(runTargets, g);
    for (final entry in runTargets.entries) {
      final player = state.attackers.firstWhere((p) => p.number == entry.key);
      final from = g.toOffset(player.position);
      final target = g.toOffset(entry.value);
      const color = Color(0xFF246C91);
      _arrow(canvas, from, target, color, dashed: true);
      canvas.drawCircle(
          target, 9, Paint()..color = color.withValues(alpha: .12));
      canvas.drawCircle(
          target,
          9,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      if (!showRunDistances) continue;
      final metres = PracticeEngine.distanceMetres(player.position, entry.value)
          .toStringAsFixed(1);
      final label = runLabels[entry.key]!;
      canvas.drawRRect(
          RRect.fromRectAndRadius(label, const Radius.circular(6)),
          Paint()
            ..color = (dark ? const Color(0xFF122D27) : Colors.white)
                .withValues(alpha: .93));
      _text(canvas, l10n.practiceRunMarker(entry.key, metres), label.center,
          textColor, 11);
    }
    final choice = intent;
    if (choice != null && choice.kind != PracticeActionKind.hold) {
      final from = g.toOffset(state.attackers
          .firstWhere((p) =>
              p.number ==
              (choice.actorNumber ??
                  active?.before.carrierNumber ??
                  state.carrierNumber))
          .position);
      _arrow(canvas, from, g.toOffset(choice.target), const Color(0xFFE0AE4C),
          dashed: choice.kind == PracticeActionKind.move);
    }
    final decision = review;
    if (decision != null && !miniature) {
      final from = g.toOffset(decision.before.attackers
          .firstWhere((p) =>
              p.number ==
              (decision.action.actorNumber ?? decision.before.carrierNumber))
          .position);
      if (decision.action.kind != PracticeActionKind.hold) {
        _arrow(canvas, from, g.toOffset(decision.action.target),
            const Color(0xFFC2923E),
            dashed: decision.action.kind == PracticeActionKind.move);
      }
      AttackPlayer? focus;
      final cue = decision.cue;
      if (decision.after.carrierIsDefender) {
        focus = state.defenders.firstWhere(
            (p) => p.number == decision.after.carrierNumber);
      } else if (cue == PracticeCue.runnerTiming ||
          cue == PracticeCue.thirdPlayerLane ||
          cue == PracticeCue.farSideSpace) {
        final players = state.attackers
            .where((p) => p.number != decision.before.carrierNumber)
            .toList()
          ..sort((a, b) => b.velocity.x.compareTo(a.velocity.x));
        focus = players.firstWhere((p) => p.number == decision.action.receiver,
            orElse: () => players.first);
      } else {
        final me = state.attackers.firstWhere((p) =>
            p.number ==
            (cue == PracticeCue.supportLane
                ? decision.evidencePlayer ??
                    decision.action.actorNumber ??
                    decision.before.carrierNumber
                : decision.action.actorNumber ??
                    decision.before.carrierNumber));
        final defenders = [
          ...state.defenders
        ]..sort((a, b) => PracticeEngine.distanceMetres(a.position, me.position)
            .compareTo(PracticeEngine.distanceMetres(b.position, me.position)));
        focus = defenders.first;
        if (cue == PracticeCue.supportLane) {
          final teammate = state.attackers
              .firstWhere((p) => p.number == decision.before.carrierNumber);
          _dashed(canvas, g.toOffset(teammate.position),
              g.toOffset(me.position), textColor.withValues(alpha: .65), 1.5);
        }
      }
      canvas.drawCircle(
          g.toOffset(focus.position) - const Offset(0, 16.52),
          22,
          Paint()
            ..color = (focus.opponent
                    ? const Color(0xFFBF735B)
                    : const Color(0xFF3682A0))
                .withValues(alpha: .7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }

    for (final link in controlLinks) {
      if ((link.from - link.to).distance > 25) {
        canvas.drawLine(
            link.from,
            link.to,
            Paint()
              ..color = textColor.withValues(alpha: .35)
              ..strokeWidth = 1);
        canvas.drawCircle(
            link.to, 3, Paint()..color = textColor.withValues(alpha: .6));
      }
    }
    final people = _AttackPitchPainter(
        displayState: state,
        baseState: state,
        selectedAction: null,
        selectedTarget: null,
        previewOffside: null,
        activeTransition: active,
        activeProgress: progress,
        history: const [],
        scanOverlay: false,
        terminalBanner: false,
        labels: _PitchLabels.from(l10n),
        brightness: brightness,
        fontFamily: fontFamily,
        learnerNumber: selectedPlayer,
        learnerLabel: null);
    for (final p in [...state.defenders, ...state.attackers]) {
      people._drawPlayer(
          canvas,
          g,
          g.portrait
              ? p.copyWith(facingRadians: p.facingRadians - math.pi / 2)
              : p,
          radius: miniature ? 8 : 14,
          anchorAtFeet: true,
          jersey:
              p.opponent ? const Color(0xFFAE654F) : const Color(0xFF347B9B),
          shorts:
              p.opponent ? const Color(0xFF65392F) : const Color(0xFF21485E),
          textColor: Colors.white,
          current: !miniature &&
              p.number == state.carrierNumber &&
              p.opponent == state.carrierIsDefender);
    }
    if (!miniature && state.carrierIsDefender) {
      final at = g.toOffset(state.carrier.position);
      canvas.drawCircle(
          at,
          18,
          Paint()
            ..color = const Color(0xFFAD503D)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
      _text(canvas, l10n.practiceStolenBy(state.carrierNumber),
          at + const Offset(0, 24), textColor, 12);
    }
    // Draw at the sampled ball coordinate, including controlled gate crossings.
    final ball = g.toOffset(state.ball);
    final radius = miniature ? 3.5 : 5.5;
    canvas.drawCircle(
        ball + const Offset(1, 2), radius, Paint()..color = Colors.black26);
    canvas.drawCircle(ball, radius, Paint()..color = Colors.white);
    final pentagon = Path();
    for (var i = 0; i < 5; i++) {
      final angle = math.pi * 2 * i / 5 + progress * 4;
      final p = ball + Offset(math.cos(angle), math.sin(angle)) * radius * .48;
      if (i == 0) {
        pentagon.moveTo(p.dx, p.dy);
      } else {
        pentagon.lineTo(p.dx, p.dy);
      }
      canvas.drawLine(
          ball + Offset(math.cos(angle), math.sin(angle)) * radius * .4,
          ball + Offset(math.cos(angle), math.sin(angle)) * radius * .94,
          Paint()
            ..color = Colors.black87
            ..strokeWidth = .8);
    }
    canvas.drawPath(pentagon..close(), Paint()..color = Colors.black87);
    canvas.drawCircle(
        ball,
        radius,
        Paint()
          ..color = Colors.black54
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8);
    // Selection controls can be offset for a finger-sized hitbox. The solid
    // path and numbered football always end at the true world-space target.
    for (final option in touchOptions) {
      final target = g.toOffset(option.target);
      final color = _touchColor(option);
      _arrow(canvas, ball, target, color);
      canvas.drawCircle(target, 8, Paint()..color = Colors.white);
      canvas.drawCircle(
          target,
          8,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      final patch = Path();
      for (var i = 0; i < 5; i++) {
        final angle = math.pi * 2 * i / 5;
        final at = target + Offset(math.cos(angle), math.sin(angle)) * 3.4;
        if (i == 0) {
          patch.moveTo(at.dx, at.dy);
        } else {
          patch.lineTo(at.dx, at.dy);
        }
      }
      canvas.drawPath(patch..close(), Paint()..color = color);
      final badge = target + const Offset(9, -10);
      canvas.drawCircle(badge, 7, Paint()..color = color);
      _text(canvas, _touchNumber(option).toString(), badge, Colors.white, 10);
    }
  }

  void _cone(Canvas c, Offset p, double r) {
    c.drawOval(
        Rect.fromCenter(
            center: p + Offset(0, r * .5), width: r * 1.8, height: r * .6),
        Paint()..color = Colors.black26);
    c.drawPath(
        Path()
          ..moveTo(p.dx, p.dy - r)
          ..lineTo(p.dx - r * .7, p.dy + r * .55)
          ..lineTo(p.dx + r * .7, p.dy + r * .55)
          ..close(),
        Paint()..color = const Color(0xFFCE843C));
    c.drawLine(
        p + Offset(-r * .37, 0),
        p + Offset(r * .37, 0),
        Paint()
          ..color = const Color(0xFFFFE9C2)
          ..strokeWidth = 2);
  }

  void _dashed(Canvas c, Offset a, Offset b, Color color, double width) {
    final distance = (b - a).distance;
    if (distance < .1) return;
    final direction = (b - a) / distance;
    for (var d = 0.0; d < distance; d += 9) {
      c.drawLine(
          a + direction * d,
          a + direction * math.min(d + 4, distance),
          Paint()
            ..color = color
            ..strokeWidth = width);
    }
  }

  void _arrow(Canvas c, Offset a, Offset b, Color color,
      {bool dashed = false}) {
    if ((b - a).distance < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    if (dashed) {
      _dashed(c, a, b, color, 1.6);
    } else {
      c.drawLine(a, b, paint);
    }
    final direction = (b - a) / (b - a).distance;
    final side = Offset(-direction.dy, direction.dx);
    c.drawLine(b, b - direction * 8 + side * 4, paint);
    c.drawLine(b, b - direction * 8 - side * 4, paint);
  }

  void _text(Canvas c, String text, Offset at, Color color, double size) {
    final p = TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(
                fontSize: size, fontFamily: fontFamily, color: color)),
        textDirection: TextDirection.ltr)
      ..layout(maxWidth: 160);
    p.paint(c, at - Offset(p.width / 2, p.height / 2));
  }

  @override
  bool shouldRepaint(covariant _CurriculumPitchPainter old) => true;
}

String _conditionLabel(AppLocalizations l, PracticeCase lesson) =>
    switch (lesson.skill) {
      PracticeSkill.firstTouch => lesson.variant == 0
          ? l.practiceConditionUpperPressure
          : l.practiceConditionLowerPressure,
      PracticeSkill.drawDefender => lesson.variant == 0
          ? l.practiceConditionBallPressure
          : l.practiceConditionTrackRunner,
      PracticeSkill.throughPass => lesson.variant == 0
          ? l.practiceConditionForwardRun
          : l.practiceConditionCheckingRun,
      PracticeSkill.supportAngle ||
      PracticeSkill.thirdPlayer =>
        lesson.variant == 0
            ? l.practiceConditionLowerCover
            : l.practiceConditionUpperCover,
      PracticeSkill.switchPlay => lesson.variant == 0
          ? l.practiceConditionStayUpper
          : l.practiceConditionShiftLower,
    };
