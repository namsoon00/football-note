import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../../domain/repositories/option_repository.dart';
import '../../domain/scan_pass/scan_pass_attack.dart';
import '../../domain/scan_pass/scan_pass_game.dart' show ScanPassPoint;
import '../theme/app_motion.dart';
import '../widgets/app_bar_action_button.dart';

enum _AttackMode { intro, choosing, executing, terminal, replaying }

class ScanPassGameScreen extends StatefulWidget {
  final OptionRepository optionRepository;
  final int? seed;
  final Duration previewDuration;
  final Duration choiceDuration;
  final Duration passAnimationDuration;
  final AttackState? initialAttack;

  const ScanPassGameScreen({
    super.key,
    required this.optionRepository,
    this.seed,
    this.previewDuration = const Duration(milliseconds: 1250),
    this.choiceDuration = const Duration(seconds: 12),
    this.passAnimationDuration = const Duration(milliseconds: 1600),
    this.initialAttack,
  });

  @override
  State<ScanPassGameScreen> createState() => _ScanPassGameScreenState();
}

class _ScanPassGameScreenState extends State<ScanPassGameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final AttackEngine _engine = const AttackEngine();

  late final AnimationController _motionController;
  late AttackState _state;

  _AttackMode _mode = _AttackMode.intro;
  AttackAction? _selectedAction;
  AttackTransition? _activeTransition;
  final List<AttackTransition> _history = <AttackTransition>[];
  List<AttackTransition> _replaySequence = const <AttackTransition>[];
  int _replayIndex = 0;
  int _restartCount = 0;
  bool _scanOverlay = false;
  bool _helpOpen = false;
  bool _foreground = true;

  bool get _isBusy =>
      _mode == _AttackMode.executing || _mode == _AttackMode.replaying;

  bool get _canChoose =>
      _mode == _AttackMode.choosing && !_state.finished && !_isBusy;

  bool get _canUndo => !_isBusy && _history.isNotEmpty;

  List<AttackAction> get _availableActions =>
      _canChoose ? _engine.availableActions(_state) : const <AttackAction>[];

  AttackState get _displayState {
    final transition = _activeTransition;
    if (transition == null) return _state;
    final offside = transition.offside;
    if (offside != null &&
        transition.after.end == AttackEnd.offside &&
        offside.offside &&
        _motionController.value >= 0.18) {
      return offside.atKick;
    }
    return transition.frame(_motionController.value.clamp(0.0, 1.0));
  }

  AttackOffsideSnapshot? get _previewOffside {
    final action = _selectedAction;
    if (!_canChoose || action == null || action.kind != AttackActionKind.pass) {
      return null;
    }
    final target = action.targetNumber;
    if (target == null) return null;
    return _engine.checkOffside(_state, target);
  }

  ScanPassPoint? get _previewTarget {
    final action = _selectedAction;
    if (!_canChoose || action == null) return null;
    return _engine.intendedTarget(_state, action);
  }

  bool get _showTerminalBanner =>
      _mode == _AttackMode.terminal && _state.end != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _motionController = AnimationController(vsync: this)
      ..addStatusListener(_handleMotionStatus);
    _resetAttack(useInitialOverride: true);
  }

  @override
  void didUpdateWidget(covariant ScanPassGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed ||
        oldWidget.initialAttack != widget.initialAttack) {
      _resetAttack(useInitialOverride: true);
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
    if (_helpOpen || _activeTransition == null) return;
    unawaited(_motionController.forward());
  }

  void _resetAttack({required bool useInitialOverride}) {
    final override = useInitialOverride ? widget.initialAttack : null;
    final variant = (widget.seed ?? 0) + _restartCount;
    _state = override ?? _engine.initial(variant: variant);
    _selectedAction = null;
    _activeTransition = null;
    _history.clear();
    _replaySequence = const <AttackTransition>[];
    _replayIndex = 0;
    _scanOverlay = false;
    _mode = override == null ? _AttackMode.intro : _AttackMode.choosing;
    _motionController
      ..stop()
      ..value = 0;
  }

  void _handleMotionStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    if (_mode == _AttackMode.executing) {
      _completeExecution();
    } else if (_mode == _AttackMode.replaying) {
      _advanceReplay();
    }
  }

  void _startAttack() {
    if (_mode != _AttackMode.intro || _isBusy) return;
    final action = _openingPassAction();
    if (action == null) {
      setState(() => _mode = _AttackMode.choosing);
      return;
    }
    _playAction(action, opening: true);
  }

  AttackAction? _openingPassAction() {
    final actions = _engine.availableActions(_state);
    const preferred = AttackAction.pass(6);
    if (actions.contains(preferred)) return preferred;
    for (final action in actions) {
      if (action.kind == AttackActionKind.pass) return action;
    }
    return actions.isEmpty ? null : actions.first;
  }

  void _selectAction(AttackAction action) {
    if (!_canChoose || !_availableActions.contains(action)) return;
    setState(() => _selectedAction = action);
    HapticFeedback.selectionClick();
  }

  void _clearSelection() {
    if (!_canChoose || _selectedAction == null) return;
    setState(() => _selectedAction = null);
  }

  void _executeSelectedAction() {
    final action = _selectedAction;
    if (!_canChoose || action == null) return;
    _playAction(action);
  }

  void _playAction(AttackAction action, {bool opening = false}) {
    final transition = _engine.play(_state, action);
    setState(() {
      _mode = _AttackMode.executing;
      _activeTransition = transition;
      _selectedAction = null;
      _scanOverlay = false;
    });
    HapticFeedback.mediumImpact();
    _runMotion(opening ? widget.previewDuration : _durationFor(transition));
  }

  Duration _durationFor(AttackTransition transition) {
    if (widget.passAnimationDuration == Duration.zero) return Duration.zero;
    final maxMilliseconds =
        math.max(1, widget.passAnimationDuration.inMilliseconds);
    final minMilliseconds = math.min(520, maxMilliseconds);
    final milliseconds = (transition.duration * 1000)
        .round()
        .clamp(minMilliseconds, maxMilliseconds);
    return Duration(milliseconds: milliseconds);
  }

  void _runMotion(Duration duration) {
    _motionController
      ..stop()
      ..duration = duration;
    if (duration == Duration.zero || AppMotion.reduceMotion(context)) {
      _motionController.value = 1;
      return;
    }
    unawaited(_motionController.forward(from: 0));
  }

  void _completeExecution() {
    final transition = _activeTransition;
    if (transition == null) return;
    setState(() {
      _history.add(transition);
      _state = transition.after;
      _activeTransition = null;
      _mode = _state.finished ? _AttackMode.terminal : _AttackMode.choosing;
      _motionController.value = 0;
    });
  }

  void _toggleScan() {
    if (_isBusy) return;
    setState(() => _scanOverlay = !_scanOverlay);
    HapticFeedback.selectionClick();
  }

  void _undoLastDecision() {
    if (!_canUndo) return;
    final removed = _history.removeLast();
    setState(() {
      _state = removed.before;
      _selectedAction = null;
      _activeTransition = null;
      _mode = _state.finished ? _AttackMode.terminal : _AttackMode.choosing;
      _scanOverlay = false;
    });
    HapticFeedback.selectionClick();
  }

  void _replayPossession() {
    if (_isBusy || _history.isEmpty) return;
    setState(() {
      _replaySequence = List<AttackTransition>.unmodifiable(_history);
      _replayIndex = 0;
      _activeTransition = _replaySequence.first;
      _selectedAction = null;
      _mode = _AttackMode.replaying;
      _scanOverlay = false;
    });
    _runMotion(_durationFor(_activeTransition!));
  }

  void _advanceReplay() {
    if (_mode != _AttackMode.replaying || _replaySequence.isEmpty) return;
    if (_replayIndex + 1 < _replaySequence.length) {
      setState(() {
        _replayIndex += 1;
        _activeTransition = _replaySequence[_replayIndex];
        _motionController.value = 0;
      });
      _runMotion(_durationFor(_activeTransition!));
      return;
    }
    setState(() {
      _activeTransition = null;
      _replaySequence = const <AttackTransition>[];
      _replayIndex = 0;
      _mode = _state.finished ? _AttackMode.terminal : _AttackMode.choosing;
      _motionController.value = 0;
    });
  }

  void _newAttack() {
    if (_isBusy) return;
    setState(() {
      _restartCount += 1;
      _resetAttack(useInitialOverride: false);
    });
  }

  Future<void> _pauseForModal(Future<void> Function() open) async {
    if (_helpOpen) return;
    _helpOpen = true;
    final wasAnimating = _motionController.isAnimating;
    _motionController.stop();
    await open();
    if (!mounted) return;
    _helpOpen = false;
    if (_foreground && wasAnimating && _activeTransition != null) {
      unawaited(_motionController.forward());
    }
  }

  void _showHelp() {
    final l10n = AppLocalizations.of(context)!;
    unawaited(_pauseForModal(() => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          useSafeArea: true,
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .85),
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
                        child: Text(l10n.scanPassHelpSheetTitle,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                    color: colors.text,
                                    fontWeight: FontWeight.w700))),
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.scanPassHelpCloseAction)),
                  ]),
                  const SizedBox(height: 10),
                  Flexible(
                      child: SingleChildScrollView(
                          child: Text(
                    l10n.scanPassAttackHelpBody,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: colors.muted, height: 1.45),
                  ))),
                ],
              ),
            ));
          },
        )));
  }

  void _showSequenceReview() {
    final l10n = AppLocalizations.of(context)!;
    unawaited(_pauseForModal(() {
      return showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) {
          final colors = _ScanPassColors.of(context);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.scanPassAttackSequenceTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  if (_history.isEmpty)
                    Text(
                      l10n.scanPassAttackNoSequence,
                      style: TextStyle(color: colors.muted),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _history.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: colors.line,
                        ),
                        itemBuilder: (context, index) {
                          final transition = _history[index];
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: colors.active,
                              foregroundColor: colors.text,
                              child: Text('${index + 1}'),
                            ),
                            title: Text(
                              _historyLabel(l10n, transition),
                              style: TextStyle(color: colors.text),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    }));
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
            if (_canChoose && _canUndo)
              AppBarActionButton(
                key: const ValueKey<String>('attack-back-step'),
                tooltip: l10n.scanPassAttackUndoAction,
                onPressed: _undoLastDecision,
                icon: const Icon(Icons.undo),
              ),
            if (_canChoose)
              AppBarActionButton(
                key: const ValueKey<String>('attack-restart'),
                tooltip: l10n.scanPassAttackNewAction,
                onPressed: _newAttack,
                icon: const Icon(Icons.restart_alt),
              ),
            AppBarActionButton(
              key: const ValueKey<String>('attack-help'),
              tooltip: l10n.scanPassHelpAction,
              onPressed: _showHelp,
              icon: const Icon(Icons.help_outline),
            ),
          ],
        ),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _motionController,
            builder: (context, _) => _buildAttackBoard(l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildAttackBoard(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final landscape = constraints.maxWidth > constraints.maxHeight &&
            constraints.maxHeight < 430;
        final pitch = Padding(
          padding: EdgeInsets.fromLTRB(
            landscape ? 10 : 14,
            landscape ? 8 : 10,
            landscape ? 8 : 14,
            landscape ? 8 : 10,
          ),
          child: _buildPitch(l10n),
        );
        final strip = Padding(
          padding: EdgeInsets.fromLTRB(
            landscape ? 10 : 14,
            landscape ? 8 : 10,
            landscape ? 8 : 14,
            0,
          ),
          child: _buildProgressStrip(l10n),
        );
        final dock = _buildDock(l10n, landscape: landscape);
        if (landscape) {
          final dockWidth = math.min(210.0, constraints.maxWidth * .34);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    strip,
                    Expanded(child: pitch),
                  ],
                ),
              ),
              SizedBox(width: dockWidth, child: dock),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            strip,
            Expanded(child: pitch),
            dock,
          ],
        );
      },
    );
  }

  Widget _buildProgressStrip(AppLocalizations l10n) {
    final colors = _ScanPassColors.of(context);
    final carrier = _displayState.carrierNumber;
    return LayoutBuilder(
      builder: (context, constraints) {
        final showPossessionChip =
            constraints.maxWidth >= 430 && !_displayState.finished && !_isBusy;
        final showProgressChip = constraints.maxWidth >= 560;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.line),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Icon(
                  Icons.sports_soccer_outlined,
                  color: colors.accent,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _statusText(l10n),
                    key: const ValueKey<String>('attack-status'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w600,
                          height: 1.12,
                        ),
                  ),
                ),
                if (showPossessionChip) ...[
                  const SizedBox(width: 8),
                  _MiniChip(
                    text: l10n.scanPassAttackPossessionChip(carrier),
                    color: colors.active,
                  ),
                ],
                if (showProgressChip) ...[
                  const SizedBox(width: 6),
                  _MiniChip(
                    text: l10n.scanPassAttackProgressStatus(
                      _state.completedPasses,
                      _state.actionCount,
                    ),
                    color: colors.background,
                  ),
                ],
                const SizedBox(width: 2),
                SizedBox.square(
                  key: const ValueKey<String>('attack-scan'),
                  dimension: 44,
                  child: Tooltip(
                    message: l10n.scanPassAttackScanAction,
                    child: TextButton(
                      onPressed: _isBusy ? null : _toggleScan,
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor:
                              _scanOverlay ? colors.accent : colors.text),
                      child: Icon(
                          _scanOverlay
                              ? Icons.visibility
                              : Icons.visibility_outlined,
                          semanticLabel: l10n.scanPassAttackScanAction),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPitch(AppLocalizations l10n) {
    final labels = _PitchLabels.from(l10n);
    final selected = _selectedAction;
    final selectedTarget = _previewTarget;
    return Semantics(
      label: l10n.scanPassFieldSemantics,
      image: true,
      child: LayoutBuilder(builder: (context, constraints) {
        final portrait = MediaQuery.sizeOf(context).width < 600 &&
            MediaQuery.sizeOf(context).height >
                MediaQuery.sizeOf(context).width;
        final aspect = (constraints.maxWidth / constraints.maxHeight)
            .clamp(portrait ? .95 : 1.55, portrait ? 1.35 : 2.6);
        return Center(
            child: AspectRatio(
          aspectRatio: aspect,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                key: const ValueKey<String>('attack-pitch'),
                painter: _AttackPitchPainter(
                  displayState: _displayState,
                  baseState: _state,
                  selectedAction: selected,
                  selectedTarget: selectedTarget,
                  previewOffside: _previewOffside,
                  activeTransition: _activeTransition,
                  activeProgress: _motionController.value,
                  history: _visibleTrailHistory,
                  scanOverlay: _scanOverlay,
                  terminalBanner: _showTerminalBanner,
                  labels: labels,
                  brightness: Theme.of(context).brightness,
                  fontFamily:
                      Theme.of(context).textTheme.bodyMedium?.fontFamily,
                ),
              ),
              if (_canChoose) _buildPitchTargets(l10n),
            ],
          ),
        ));
      }),
    );
  }

  List<AttackTransition> get _visibleTrailHistory {
    if (_mode == _AttackMode.replaying && _replaySequence.isNotEmpty) {
      return _replaySequence.take(_replayIndex).toList(growable: false);
    }
    return List<AttackTransition>.unmodifiable(_history);
  }

  Widget _buildPitchTargets(AppLocalizations l10n) {
    final colors = _ScanPassColors.of(context);
    final passTargets = _availableActions
        .where((action) => action.kind == AttackActionKind.pass)
        .map((action) => action.targetNumber)
        .whereType<int>()
        .toSet();
    final shotActions = _availableActions
        .where((action) => action.kind == AttackActionKind.shoot)
        .toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final geometry = _PitchGeometry(size);
        final children = <Widget>[];
        for (final targetNumber in passTargets) {
          final player = _playerByNumber(_state.attackers, targetNumber);
          if (player == null) continue;
          final center = geometry.toOffset(player.position);
          final action = AttackAction.pass(targetNumber);
          children.add(
            _PitchButton(
              key: ValueKey<String>('attack-pass-$targetNumber'),
              center: center,
              label: l10n.scanPassAttackPassPlayerLabel(targetNumber),
              selected: _selectedAction == action,
              color: colors.team,
              unobscured: true,
              onPressed: () => _selectAction(action),
              child: const SizedBox.shrink(),
            ),
          );
        }
        // Small goal mouths cannot contain three non-overlapping 48px targets.
        for (final action in geometry.fieldRect.height * .12 >= 48
            ? shotActions
            : const <AttackAction>[]) {
          final target = action.shotTarget;
          if (target == null) continue;
          final center = geometry.toOffset(_shotPoint(target));
          children.add(
            _PitchButton(
              key: ValueKey<String>('attack-field-shoot-${target.name}'),
              center: center,
              label: _shotSemantics(l10n, target),
              selected: _selectedAction == action,
              color: colors.accent,
              onPressed: () => _selectAction(action),
              child: const Icon(Icons.adjust, size: 16),
            ),
          );
        }
        return Stack(children: children);
      },
    );
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
            height: landscape
                ? null
                : MediaQuery.sizeOf(context).width < 1000
                    ? 166
                    : 108,
            child: Align(
                alignment: Alignment.topCenter,
                child: _buildDockContent(l10n, landscape: landscape)),
          ),
        ),
      ),
    );
  }

  Widget _buildDockContent(AppLocalizations l10n, {required bool landscape}) {
    return switch (_mode) {
      _AttackMode.intro => _buildIntroDock(l10n),
      _AttackMode.choosing => _buildChoiceDock(l10n, landscape: landscape),
      _AttackMode.executing => _buildBusyDock(l10n),
      _AttackMode.replaying => _buildBusyDock(l10n),
      _AttackMode.terminal => _buildTerminalDock(l10n),
    };
  }

  Widget _buildIntroDock(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          key: const ValueKey<String>('attack-start'),
          onPressed: _startAttack,
          icon: const Icon(Icons.play_arrow_outlined),
          label: Text(l10n.scanPassAttackStartAction),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceDock(
    AppLocalizations l10n, {
    required bool landscape,
  }) {
    final compact = landscape || MediaQuery.sizeOf(context).width < 1000;
    final actions = _availableActions
        .where((action) =>
            (!compact || action.kind != AttackActionKind.shoot) &&
            (!compact || action.kind != AttackActionKind.pass))
        .toList();
    Widget control(AttackAction action) => _DockActionButton(
          key: ValueKey<String>(_dockActionKey(action)),
          selected: _selectedAction == action,
          icon: _actionIcon(action),
          label: compact && action.kind == AttackActionKind.carry
              ? l10n.scanPassAttackCarryShort
              : _actionLabel(l10n, action),
          semanticsLabel: _actionSemantics(l10n, action),
          compact: compact,
          onPressed: () => _selectAction(action),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_state.canShoot && compact) ...[
          Row(children: [
            for (final target in AttackShotTarget.values)
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _DockActionButton(
                  key: ValueKey<String>('attack-shoot-${target.name}'),
                  selected: _selectedAction == AttackAction.shoot(target),
                  icon: landscape ? null : Icons.gps_fixed_outlined,
                  label: compact
                      ? _shotName(l10n, target)
                      : _actionLabel(l10n, AttackAction.shoot(target)),
                  semanticsLabel: _shotSemantics(l10n, target),
                  compact: compact,
                  onPressed: () => _selectAction(AttackAction.shoot(target)),
                ),
              )),
          ]),
          const SizedBox(height: 6),
        ],
        if (landscape)
          LayoutBuilder(
              builder: (context, constraints) => Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final action in actions)
                        SizedBox(
                            width: (constraints.maxWidth - 6) / 2,
                            child: control(action))
                    ],
                  ))
        else if (compact)
          Row(children: [
            for (final action in actions)
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: control(action),
              ))
          ]),
        if (!compact)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final action in actions)
                Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: control(action))
            ]),
          ),
        if (_selectedAction != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            TextButton(
              key: const ValueKey<String>('attack-change'),
              onPressed: _clearSelection,
              style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.close, size: 18),
                if (!landscape) ...[
                  const SizedBox(width: 4),
                  Text(l10n.scanPassAttackChangeAction),
                ],
              ]),
            ),
            const SizedBox(width: 6),
            Expanded(
                child: FilledButton.icon(
              key: const ValueKey<String>('attack-execute'),
              onPressed: _executeSelectedAction,
              icon: const Icon(Icons.play_arrow_outlined),
              label: Text(l10n.scanPassAttackExecuteAction),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
            )),
          ]),
        ],
      ],
    );
  }

  Widget _buildBusyDock(AppLocalizations l10n) {
    final colors = _ScanPassColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            minHeight: 4,
            value: _motionController.value.clamp(0.0, 1.0),
            backgroundColor: colors.line,
            valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
          ),
        ),
      ],
    );
  }

  Widget _buildTerminalDock(AppLocalizations l10n) {
    final colors = _ScanPassColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            OutlinedButton.icon(
              key: const ValueKey<String>('attack-review'),
              onPressed: _history.isEmpty ? null : _showSequenceReview,
              icon: const Icon(Icons.list_alt_outlined),
              label: Text(l10n.scanPassAttackSequenceTitle),
              style: _outlinedStyle(colors),
            ),
            OutlinedButton.icon(
              key: const ValueKey<String>('attack-replay'),
              onPressed: _history.isEmpty ? null : _replayPossession,
              icon: const Icon(Icons.replay),
              label: Text(l10n.scanPassAttackReplayAction),
              style: _outlinedStyle(colors),
            ),
            OutlinedButton.icon(
              key: const ValueKey<String>('attack-undo'),
              onPressed: _canUndo ? _undoLastDecision : null,
              icon: const Icon(Icons.undo),
              label: Text(l10n.scanPassAttackUndoAction),
              style: _outlinedStyle(colors),
            ),
            FilledButton.icon(
              key: const ValueKey<String>('attack-new'),
              onPressed: _newAttack,
              icon: const Icon(Icons.add_circle_outline),
              label: Text(l10n.scanPassAttackNewAction),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  ButtonStyle _outlinedStyle(_ScanPassColors colors) {
    return OutlinedButton.styleFrom(
      foregroundColor: colors.text,
      side: BorderSide(color: colors.line),
      minimumSize: const Size(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );
  }

  String _statusText(AppLocalizations l10n) {
    if (_mode == _AttackMode.intro) return l10n.scanPassAttackIntroStatus;
    if (_mode == _AttackMode.executing) return l10n.scanPassAttackExecuting;
    if (_mode == _AttackMode.replaying) return l10n.scanPassAttackReplaying;
    final end = _state.end;
    if (end != null) return _outcomeStatus(l10n, end);
    final selected = _selectedAction;
    if (selected != null) return _previewText(l10n, selected);
    if (_scanOverlay) return l10n.scanPassAttackScanStatus;
    return _state.canShoot
        ? _choicePrompt(l10n)
        : l10n.scanPassAttackPossessionStatus(_state.carrierNumber);
  }

  String _choicePrompt(AppLocalizations l10n) {
    final selected = _selectedAction;
    if (selected != null) return _previewText(l10n, selected);
    if (_state.canShoot) return l10n.scanPassAttackChooseWithShotStatus;
    return l10n.scanPassAttackChooseStatus;
  }

  String _previewText(AppLocalizations l10n, AttackAction action) {
    return switch (action.kind) {
      AttackActionKind.pass =>
        l10n.scanPassAttackPreviewPass(action.targetNumber ?? 0),
      AttackActionKind.carry => switch (action.carryDirection) {
          AttackCarryDirection.upper => l10n.scanPassAttackPreviewCarryUpper,
          AttackCarryDirection.forward =>
            l10n.scanPassAttackPreviewCarryForward,
          AttackCarryDirection.lower => l10n.scanPassAttackPreviewCarryLower,
          null => l10n.scanPassAttackPreviewCarryForward,
        },
      AttackActionKind.hold => l10n.scanPassAttackPreviewHold,
      AttackActionKind.shoot => switch (action.shotTarget) {
          AttackShotTarget.upper => l10n.scanPassAttackPreviewShootUpper,
          AttackShotTarget.center => l10n.scanPassAttackPreviewShootCenter,
          AttackShotTarget.lower => l10n.scanPassAttackPreviewShootLower,
          null => l10n.scanPassAttackPreviewShootCenter,
        },
    };
  }

  String _outcomeStatus(AppLocalizations l10n, AttackEnd end) {
    return switch (end) {
      AttackEnd.goal => l10n.scanPassAttackOutcomeGoalStatus,
      AttackEnd.intercepted => l10n.scanPassAttackOutcomeInterceptedStatus,
      AttackEnd.offside => l10n.scanPassAttackOutcomeOffsideStatus,
      AttackEnd.saved => l10n.scanPassAttackOutcomeSavedStatus,
      AttackEnd.wide => l10n.scanPassAttackOutcomeWideStatus,
      AttackEnd.blocked => l10n.scanPassAttackOutcomeBlockedStatus,
    };
  }

  String _historyLabel(AppLocalizations l10n, AttackTransition transition) {
    final action = transition.action;
    return switch (action.kind) {
      AttackActionKind.pass => l10n.scanPassAttackSequencePass(
          transition.before.carrierNumber,
          action.targetNumber ?? transition.after.carrierNumber,
        ),
      AttackActionKind.carry => switch (action.carryDirection) {
          AttackCarryDirection.upper => l10n.scanPassAttackSequenceCarryUpper(
              transition.before.carrierNumber,
            ),
          AttackCarryDirection.forward =>
            l10n.scanPassAttackSequenceCarryForward(
              transition.before.carrierNumber,
            ),
          AttackCarryDirection.lower => l10n.scanPassAttackSequenceCarryLower(
              transition.before.carrierNumber,
            ),
          null => l10n.scanPassAttackSequenceCarryForward(
              transition.before.carrierNumber,
            ),
        },
      AttackActionKind.hold =>
        l10n.scanPassAttackSequenceHold(transition.before.carrierNumber),
      AttackActionKind.shoot => l10n.scanPassAttackSequenceShoot(
          transition.before.carrierNumber,
          _shotName(l10n, action.shotTarget ?? AttackShotTarget.center),
        ),
    };
  }

  String _actionKey(AttackAction action) {
    return switch (action.kind) {
      AttackActionKind.pass => 'attack-pass-${action.targetNumber}',
      AttackActionKind.carry => switch (action.carryDirection) {
          AttackCarryDirection.upper => 'attack-carry-upper',
          AttackCarryDirection.forward => 'attack-carry-forward',
          AttackCarryDirection.lower => 'attack-carry-lower',
          null => 'attack-carry-forward',
        },
      AttackActionKind.hold => 'attack-hold',
      AttackActionKind.shoot => switch (action.shotTarget) {
          AttackShotTarget.upper => 'attack-shoot-upper',
          AttackShotTarget.center => 'attack-shoot-center',
          AttackShotTarget.lower => 'attack-shoot-lower',
          null => 'attack-shoot-center',
        },
    };
  }

  String _dockActionKey(AttackAction action) =>
      action.kind == AttackActionKind.pass
          ? 'attack-dock-pass-${action.targetNumber}'
          : _actionKey(action);

  IconData _actionIcon(AttackAction action) {
    return switch (action.kind) {
      AttackActionKind.pass => Icons.call_made_outlined,
      AttackActionKind.carry => switch (action.carryDirection) {
          AttackCarryDirection.upper => Icons.north_east_outlined,
          AttackCarryDirection.forward => Icons.arrow_forward_outlined,
          AttackCarryDirection.lower => Icons.south_east_outlined,
          null => Icons.arrow_forward_outlined,
        },
      AttackActionKind.hold => Icons.pause_outlined,
      AttackActionKind.shoot => Icons.gps_fixed_outlined,
    };
  }

  String _actionLabel(AppLocalizations l10n, AttackAction action) {
    return switch (action.kind) {
      AttackActionKind.pass =>
        l10n.scanPassAttackPassAction(action.targetNumber ?? 0),
      AttackActionKind.carry => switch (action.carryDirection) {
          AttackCarryDirection.upper => l10n.scanPassAttackCarryUpperAction,
          AttackCarryDirection.forward => l10n.scanPassAttackCarryForwardAction,
          AttackCarryDirection.lower => l10n.scanPassAttackCarryLowerAction,
          null => l10n.scanPassAttackCarryForwardAction,
        },
      AttackActionKind.hold => l10n.scanPassAttackHoldAction,
      AttackActionKind.shoot => switch (action.shotTarget) {
          AttackShotTarget.upper => l10n.scanPassAttackShootUpperAction,
          AttackShotTarget.center => l10n.scanPassAttackShootCenterAction,
          AttackShotTarget.lower => l10n.scanPassAttackShootLowerAction,
          null => l10n.scanPassAttackShootCenterAction,
        },
    };
  }

  String _actionSemantics(AppLocalizations l10n, AttackAction action) {
    return switch (action.kind) {
      AttackActionKind.pass =>
        l10n.scanPassAttackPassPlayerLabel(action.targetNumber ?? 0),
      AttackActionKind.carry => switch (action.carryDirection) {
          AttackCarryDirection.upper => l10n.scanPassAttackCarryUpperLabel,
          AttackCarryDirection.forward => l10n.scanPassAttackCarryForwardLabel,
          AttackCarryDirection.lower => l10n.scanPassAttackCarryLowerLabel,
          null => l10n.scanPassAttackCarryForwardLabel,
        },
      AttackActionKind.hold => l10n.scanPassAttackHoldLabel,
      AttackActionKind.shoot => switch (action.shotTarget) {
          AttackShotTarget.upper => l10n.scanPassAttackShootUpperLabel,
          AttackShotTarget.center => l10n.scanPassAttackShootCenterLabel,
          AttackShotTarget.lower => l10n.scanPassAttackShootLowerLabel,
          null => l10n.scanPassAttackShootCenterLabel,
        },
    };
  }

  String _shotSemantics(AppLocalizations l10n, AttackShotTarget target) {
    return switch (target) {
      AttackShotTarget.upper => l10n.scanPassAttackShootUpperLabel,
      AttackShotTarget.center => l10n.scanPassAttackShootCenterLabel,
      AttackShotTarget.lower => l10n.scanPassAttackShootLowerLabel,
    };
  }

  String _shotName(AppLocalizations l10n, AttackShotTarget target) {
    return switch (target) {
      AttackShotTarget.upper => l10n.scanPassAttackShotUpperName,
      AttackShotTarget.center => l10n.scanPassAttackShotCenterName,
      AttackShotTarget.lower => l10n.scanPassAttackShotLowerName,
    };
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _DockActionButton extends StatelessWidget {
  final bool selected;
  final IconData? icon;
  final String label;
  final String semanticsLabel;
  final VoidCallback onPressed;
  final bool compact;

  const _DockActionButton(
      {super.key,
      required this.selected,
      required this.icon,
      required this.label,
      required this.semanticsLabel,
      required this.onPressed,
      this.compact = false});

  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    return Tooltip(
        message: semanticsLabel,
        child: Semantics(
          button: true,
          selected: selected,
          label: semanticsLabel,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: selected ? colors.accent : colors.text,
              backgroundColor: selected ? colors.active : colors.surface,
              side: BorderSide(color: selected ? colors.accent : colors.line),
              minimumSize: const Size(44, 44),
              padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[
                Icon(icon, size: compact ? 16 : 18),
                SizedBox(width: compact ? 3 : 7),
              ],
              Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: compact ? const TextStyle(fontSize: 12) : null)),
            ]),
          ),
        ));
  }
}

class _PitchButton extends StatelessWidget {
  final Offset center;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onPressed;
  final Widget child;
  final bool unobscured;

  const _PitchButton({
    super.key,
    required this.center,
    required this.label,
    required this.selected,
    required this.color,
    required this.onPressed,
    required this.child,
    this.unobscured = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _ScanPassColors.of(context);
    return Positioned(
      left: center.dx - 24,
      top: center.dy - 24,
      width: 48,
      height: 48,
      child: Tooltip(
        message: label,
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
              foregroundColor: selected ? colors.background : Colors.white,
              backgroundColor: unobscured
                  ? Colors.transparent
                  : selected
                      ? colors.accent
                      : color.withValues(alpha: 0.22),
              side: BorderSide(
                color: selected
                    ? colors.accent
                    : color.withValues(alpha: unobscured ? .35 : .85),
                width: selected ? 2.2 : 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AttackPitchPainter extends CustomPainter {
  final AttackState displayState;
  final AttackState baseState;
  final AttackAction? selectedAction;
  final ScanPassPoint? selectedTarget;
  final AttackOffsideSnapshot? previewOffside;
  final AttackTransition? activeTransition;
  final double activeProgress;
  final List<AttackTransition> history;
  final bool scanOverlay;
  final bool terminalBanner;
  final _PitchLabels labels;
  final Brightness brightness;
  final String? fontFamily;

  const _AttackPitchPainter({
    required this.displayState,
    required this.baseState,
    required this.selectedAction,
    required this.selectedTarget,
    required this.previewOffside,
    required this.activeTransition,
    required this.activeProgress,
    required this.history,
    required this.scanOverlay,
    required this.terminalBanner,
    required this.labels,
    required this.brightness,
    required this.fontFamily,
  });

  bool get _isDark => brightness == Brightness.dark;

  Color get _pitch =>
      _isDark ? const Color(0xFF203A33) : const Color(0xFFDCE8DC);

  Color get _stripe =>
      _isDark ? const Color(0xFF19312B) : const Color(0xFFD1DFD2);

  Color get _line =>
      _isDark ? const Color(0xFF7B9288) : const Color(0xFF7C9488);

  Color get _team =>
      _isDark ? const Color(0xFF77A9C4) : const Color(0xFF35718D);

  Color get _defender =>
      _isDark ? const Color(0xFFD08267) : const Color(0xFFB15F49);

  Color get _keeper =>
      _isDark ? const Color(0xFF8FCB8D) : const Color(0xFF2E8760);

  Color get _accent =>
      _isDark ? const Color(0xFFE2C57E) : const Color(0xFF84611F);

  Color get _text =>
      _isDark ? const Color(0xFFE9EEEB) : const Color(0xFF1D2D31);

  Color get _muted =>
      _isDark ? const Color(0xFFAFC0BE) : const Color(0xFF52686B);

  Color get _shadow => Colors.black.withValues(alpha: _isDark ? .34 : .20);

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = _PitchGeometry(size);
    _drawPitch(canvas, geometry);
    _drawOffside(canvas, geometry);
    _drawHistory(canvas, geometry);
    _drawPreview(canvas, geometry);
    _drawActivePath(canvas, geometry);
    if (scanOverlay) _drawMovementGhosts(canvas, geometry);
    _drawGoal(canvas, geometry);
    for (final defender in displayState.defenders) {
      _drawPlayer(
        canvas,
        geometry,
        defender,
        jersey: defender.goalkeeper ? _keeper : _defender,
        shorts: defender.goalkeeper
            ? (_isDark ? const Color(0xFF224A3C) : const Color(0xFF1B5D45))
            : (_isDark ? const Color(0xFF743B30) : const Color(0xFF783B31)),
        textColor: Colors.white,
        current: false,
      );
    }
    for (final player in displayState.attackers) {
      _drawPlayer(
        canvas,
        geometry,
        player,
        jersey: _team,
        shorts: _isDark ? const Color(0xFF2D5A6F) : const Color(0xFF174E66),
        textColor: Colors.white,
        current: player.number == displayState.carrierNumber &&
            (!displayState.finished || displayState.end == AttackEnd.offside),
      );
    }
    _drawBall(canvas, geometry);
    _drawAttackArrow(canvas, geometry);
    _drawTerminalBanner(canvas, geometry);
  }

  void _drawPitch(Canvas canvas, _PitchGeometry geometry) {
    canvas.drawRRect(
      BorderRadius.circular(7).toRRect(Offset.zero & geometry.size),
      Paint()..color = _pitch,
    );
    final stripePaint = Paint()..color = _stripe.withValues(alpha: .52);
    final stripeWidth = geometry.size.width / 9;
    for (var i = 0; i < 9; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, geometry.size.height),
        stripePaint,
      );
    }

    final paint = Paint()
      ..color = _line.withValues(alpha: .78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final field = geometry.fieldRect;
    canvas.drawRect(field, paint);
    canvas.drawLine(
      Offset(geometry.x(0.5), field.top),
      Offset(geometry.x(0.5), field.bottom),
      paint,
    );
    canvas.drawCircle(
      Offset(geometry.x(0.5), geometry.y(0.5)),
      field.height * .16,
      paint,
    );
    canvas.drawRect(
      Rect.fromLTRB(
        geometry.x(0.0),
        geometry.y(0.21),
        geometry.x(0.15),
        geometry.y(0.79),
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTRB(
        geometry.x(0.83),
        geometry.y(0.21),
        geometry.x(1.0),
        geometry.y(0.79),
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTRB(
        geometry.x(0.94),
        geometry.y(0.35),
        geometry.x(1.0),
        geometry.y(0.65),
      ),
      paint,
    );
  }

  void _drawGoal(Canvas canvas, _PitchGeometry geometry) {
    final mouthTop = geometry.toOffset(const ScanPassPoint(1.0, .35));
    final mouthBottom = geometry.toOffset(const ScanPassPoint(1.0, .65));
    final netBackTop = geometry.toOffset(const ScanPassPoint(1.04, .31));
    final netBackBottom = geometry.toOffset(const ScanPassPoint(1.04, .69));
    final postPaint = Paint()
      ..color = _isDark ? const Color(0xFFE9EEE8) : Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    final netPaint = Paint()
      ..color = _line.withValues(alpha: .50)
      ..strokeWidth = .8
      ..style = PaintingStyle.stroke;
    final netPath = Path()
      ..moveTo(mouthTop.dx, mouthTop.dy)
      ..lineTo(netBackTop.dx, netBackTop.dy)
      ..lineTo(netBackBottom.dx, netBackBottom.dy)
      ..lineTo(mouthBottom.dx, mouthBottom.dy);
    canvas.drawPath(netPath, netPaint);
    for (var i = 1; i < 5; i += 1) {
      final t = i / 5;
      canvas.drawLine(
        Offset.lerp(mouthTop, mouthBottom, t)!,
        Offset.lerp(netBackTop, netBackBottom, t)!,
        netPaint,
      );
    }
    for (var i = 1; i < 4; i += 1) {
      final t = i / 4;
      canvas.drawLine(
        Offset.lerp(mouthTop, netBackTop, t)!,
        Offset.lerp(mouthBottom, netBackBottom, t)!,
        netPaint,
      );
    }
    canvas.drawLine(mouthTop, mouthBottom, postPaint);
    canvas.drawLine(mouthTop, netBackTop, postPaint);
    canvas.drawLine(mouthBottom, netBackBottom, postPaint);
  }

  void _drawOffside(Canvas canvas, _PitchGeometry geometry) {
    if (displayState.finished && displayState.end != AttackEnd.offside) return;
    final evidence = activeTransition?.after.end == AttackEnd.offside
        ? activeTransition!.offside
        : terminalBanner &&
                baseState.end == AttackEnd.offside &&
                history.isNotEmpty
            ? history.last.offside
            : null;
    final lineX = evidence?.lineX ??
        activeTransition?.offside?.lineX ??
        previewOffside?.lineX ??
        const AttackEngine().offsideLine(baseState);
    final x = geometry.x(lineX);
    final field = geometry.fieldRect;
    canvas.drawRect(
      Rect.fromLTRB(x, field.top, geometry.x(1.04), field.bottom),
      Paint()
        ..color =
            (_isDark ? Colors.black : Colors.white).withValues(alpha: .075),
    );
    final paint = Paint()
      ..color = _accent.withValues(alpha: .58)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    _drawDashedLine(
      canvas,
      Offset(x, field.top),
      Offset(x, field.bottom),
      paint,
      dash: 5,
      gap: 5,
    );
    _drawText(
      canvas,
      labels.offsideLine,
      Offset(x + 4, field.top + 12),
      color: _accent,
      fontSize: math.max(10, geometry.size.shortestSide * .026),
      anchorMode: _TextAnchor.left,
    );

    final preview = previewOffside;
    if (preview != null && preview.offside && activeTransition == null) {
      final receiver =
          _playerByNumber(baseState.attackers, preview.receiverNumber);
      if (receiver != null) {
        _drawFlag(
          canvas,
          geometry.toOffset(receiver.position) +
              Offset(15, -math.max(32.0, geometry.size.shortestSide * .075)),
          labels.offsideWarning,
          geometry,
        );
      }
    }

    final active = evidence;
    if (active != null && (terminalBanner || activeProgress >= .18)) {
      final receiver = _playerByNumber(
        active.atKick.attackers,
        active.receiverNumber,
      );
      _drawFlag(
        canvas,
        geometry.toOffset(active.atKick.ball) +
            Offset(-12, -math.max(32.0, geometry.size.shortestSide * .085)),
        labels.offsideFreeze,
        geometry,
      );

      if (receiver != null) {
        _drawRoute(
            canvas,
            geometry,
            active.atKick.ball,
            receiver.position,
            Paint()
              ..color = _defender.withValues(alpha: .6)
              ..strokeWidth = 1.6
              ..style = PaintingStyle.stroke,
            dashed: true,
            arrow: true);
        _drawMarker(
          canvas,
          geometry.toOffset(receiver.position),
          labels.receiver,
          geometry,
          _defender,
        );
      }
      final opponents = active.atKick.defenders.toList()
        ..sort((a, b) => b.position.x.compareTo(a.position.x));
      _drawMarker(canvas, geometry.toOffset(opponents[1].position),
          labels.secondLast, geometry, _muted);
    }
  }

  void _drawHistory(Canvas canvas, _PitchGeometry geometry) {
    final paint = Paint()
      ..color = _accent.withValues(alpha: .32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    for (final transition in history) {
      _drawRoute(
        canvas,
        geometry,
        transition.before.ball,
        transition.ballEnd,
        paint,
        dashed: false,
        arrow: true,
      );
    }
  }

  void _drawPreview(Canvas canvas, _PitchGeometry geometry) {
    final action = selectedAction;
    final target = selectedTarget;
    if (action == null || target == null) return;
    final paint = Paint()
      ..color = _accent.withValues(alpha: .82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final from = baseState.ball;
    if (action.kind == AttackActionKind.carry) {
      _drawCurvedRoute(canvas, geometry, from, target, paint, dashed: true);
      _drawGhostPlayer(canvas, geometry, target);
    } else if (action.kind == AttackActionKind.hold) {
      final center = geometry.toOffset(from);
      canvas.drawCircle(center, geometry.size.shortestSide * .038, paint);
      _drawText(
        canvas,
        labels.hold,
        center + Offset(0, -geometry.size.shortestSide * .065),
        color: _accent,
        fontSize: geometry.size.shortestSide * .032,
        anchorMode: _TextAnchor.center,
      );
    } else {
      _drawRoute(
        canvas,
        geometry,
        from,
        target,
        paint,
        dashed: true,
        arrow: true,
      );
    }
  }

  void _drawActivePath(Canvas canvas, _PitchGeometry geometry) {
    final transition = activeTransition;
    if (transition == null) return;
    final paint = Paint()
      ..color = _accent.withValues(alpha: .88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final end = transition.before.ball.lerp(
      transition.ballEnd,
      activeProgress.clamp(0.0, 1.0),
    );
    _drawRoute(
      canvas,
      geometry,
      transition.before.ball,
      end,
      paint,
      dashed: false,
      arrow: true,
    );
  }

  void _drawMovementGhosts(Canvas canvas, _PitchGeometry geometry) {
    for (final player in <AttackPlayer>[
      ...displayState.attackers,
      ...displayState.defenders,
    ]) {
      final velocity = player.velocity;
      if (velocity.x.abs() + velocity.y.abs() < .001) continue;
      final start = geometry.toOffset(player.position);
      final ghostPoint = ScanPassPoint(
        (player.position.x + velocity.x * 3.0).clamp(0.0, 1.04),
        (player.position.y + velocity.y * 3.0).clamp(0.02, 0.98),
      );
      final end = geometry.toOffset(ghostPoint);
      final paint = Paint()
        ..color = (player.opponent ? _defender : _team).withValues(alpha: .45)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      _drawDashedLine(canvas, start, end, paint, dash: 4, gap: 4);
      _drawArrowHead(canvas, start, end, paint);
      canvas.drawCircle(
        end,
        geometry.size.shortestSide * .022,
        Paint()
          ..color =
              (player.opponent ? _defender : _team).withValues(alpha: .15),
      );
    }
  }

  void _drawPlayer(
    Canvas canvas,
    _PitchGeometry geometry,
    AttackPlayer player, {
    required Color jersey,
    required Color shorts,
    required Color textColor,
    required bool current,
  }) {
    final center = geometry.toOffset(player.position);
    final scale = player.goalkeeper ? 1.04 : 1.0;
    final r = math.max(11.0, geometry.size.shortestSide * .037) * scale;
    if (current) {
      canvas.drawCircle(
        center,
        r * 1.42,
        Paint()
          ..color = _accent.withValues(alpha: .72)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.1,
      );
      _drawText(
        canvas,
        labels.currentPlayer(player.number),
        center + Offset(0, r * 2.05),
        color: _text,
        fontSize: math.max(10, geometry.size.shortestSide * .028),
        anchorMode: _TextAnchor.center,
      );
    }

    final shadow = Paint()..color = _shadow;
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, r * 1.25),
        width: r * 1.55,
        height: r * .35,
      ),
      shadow,
    );

    final facing = Offset(
      math.cos(player.facingRadians),
      math.sin(player.facingRadians),
    );
    final legPaint = Paint()
      ..color = shorts
      ..strokeWidth = r * .18
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center + Offset(-r * .20, r * .72),
      center + Offset(-r * .42, r * 1.18) + facing * r * .10,
      legPaint,
    );
    canvas.drawLine(
      center + Offset(r * .20, r * .72),
      center + Offset(r * .42, r * 1.18) + facing * r * .10,
      legPaint,
    );

    final shirt = Path()
      ..moveTo(center.dx - r * .40, center.dy - r * .50)
      ..lineTo(center.dx - r * .88, center.dy - r * .18)
      ..lineTo(center.dx - r * .62, center.dy + r * .20)
      ..lineTo(center.dx - r * .42, center.dy + r * .04)
      ..lineTo(center.dx - r * .36, center.dy + r * .76)
      ..lineTo(center.dx + r * .36, center.dy + r * .76)
      ..lineTo(center.dx + r * .42, center.dy + r * .04)
      ..lineTo(center.dx + r * .62, center.dy + r * .20)
      ..lineTo(center.dx + r * .88, center.dy - r * .18)
      ..lineTo(center.dx + r * .40, center.dy - r * .50)
      ..close();
    canvas.drawPath(shirt, Paint()..color = jersey);
    canvas.drawRect(
      Rect.fromCenter(
        center: center + Offset(0, r * .78),
        width: r * .78,
        height: r * .34,
      ),
      Paint()..color = shorts,
    );
    canvas.drawCircle(
      center + Offset(0, -r * .86),
      r * .25,
      Paint()
        ..color = _isDark ? const Color(0xFFD9A77D) : const Color(0xFFC78C63),
    );
    if (player.goalkeeper) {
      final glove = Paint()..color = _isDark ? Colors.white70 : Colors.white;
      canvas.drawCircle(center + Offset(-r * .95, r * .08), r * .16, glove);
      canvas.drawCircle(center + Offset(r * .95, r * .08), r * .16, glove);
    }
    _drawText(
      canvas,
      player.number.toString(),
      center + Offset(0, r * .10),
      color: textColor,
      fontSize: r * .68,
      fontWeight: FontWeight.w800,
      anchorMode: _TextAnchor.center,
    );
  }

  void _drawGhostPlayer(
    Canvas canvas,
    _PitchGeometry geometry,
    ScanPassPoint point,
  ) {
    final center = geometry.toOffset(point);
    final r = math.max(11.0, geometry.size.shortestSide * .037);
    canvas.drawCircle(
      center,
      r * 1.18,
      Paint()..color = _team.withValues(alpha: .12),
    );
    canvas.drawCircle(
      center,
      r * 1.18,
      Paint()
        ..color = _team.withValues(alpha: .52)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _drawBall(Canvas canvas, _PitchGeometry geometry) {
    final holder =
        _playerByNumber(displayState.attackers, displayState.carrierNumber);
    var center = geometry.toOffset(displayState.ball);
    final inFlight = activeTransition != null &&
        (activeTransition!.action.kind == AttackActionKind.pass ||
            activeTransition!.action.kind == AttackActionKind.shoot) &&
        activeTransition!.after.end != AttackEnd.offside;
    if (holder != null &&
        (!displayState.finished || displayState.end == AttackEnd.offside) &&
        !inFlight) {
      center = geometry.toOffset(holder.position) +
          Offset(
                math.cos(holder.facingRadians),
                math.sin(holder.facingRadians),
              ) *
              (geometry.size.shortestSide * .043);
    }
    final radius = math.max(
      geometry.size.width >= 700 ? 8.0 : 5.0,
      geometry.size.shortestSide * .014,
    );
    final rotation = activeProgress * math.pi * 2;
    canvas.drawCircle(
      center + Offset(radius * .26, radius * .34),
      radius * 1.08,
      Paint()..color = _shadow,
    );
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    final outline = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.8, radius * .12);
    canvas.drawCircle(center, radius, outline);
    final pentagon = Path();
    for (var i = 0; i < 5; i += 1) {
      final angle = rotation - math.pi / 2 + i * math.pi * 2 / 5;
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * .38;
      if (i == 0) {
        pentagon.moveTo(point.dx, point.dy);
      } else {
        pentagon.lineTo(point.dx, point.dy);
      }
    }
    pentagon.close();
    canvas.drawPath(pentagon, Paint()..color = const Color(0xFF111111));
    for (var i = 0; i < 5; i += 1) {
      final angle = rotation - math.pi / 2 + i * math.pi * 2 / 5;
      final from =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * .42;
      final to =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * .92;
      canvas.drawLine(from, to, outline);
    }
  }

  void _drawAttackArrow(Canvas canvas, _PitchGeometry geometry) {
    final start = Offset(geometry.x(.72), geometry.y(.09));
    final end = Offset(geometry.x(.88), geometry.y(.09));
    final paint = Paint()
      ..color = _line.withValues(alpha: .78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, paint);
    _drawArrowHead(canvas, start, end, paint);
    _drawText(
      canvas,
      labels.attackRight,
      start + const Offset(-4, -11),
      color: _muted,
      fontSize: math.max(10, geometry.size.shortestSide * .028),
      anchorMode: _TextAnchor.right,
    );
  }

  void _drawTerminalBanner(Canvas canvas, _PitchGeometry geometry) {
    if (!terminalBanner || displayState.end == null) return;
    final text = labels.outcome(displayState.end!);
    final painter = _textPainter(
      text,
      color: _text,
      fontSize: math.max(14, geometry.size.shortestSide * .044),
      fontWeight: FontWeight.w800,
      align: TextAlign.center,
    )..layout(maxWidth: geometry.size.width * .72);
    final rect = Rect.fromCenter(
      center: Offset(geometry.size.width * .50, geometry.size.height * .14),
      width: painter.width + 34,
      height: painter.height + 18,
    );
    canvas.drawRRect(
      BorderRadius.circular(6).toRRect(rect),
      Paint()
        ..color = (_isDark ? const Color(0xFF111A1E) : Colors.white)
            .withValues(alpha: .90),
    );
    canvas.drawRRect(
      BorderRadius.circular(6).toRRect(rect),
      Paint()
        ..color = _accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    painter.paint(
      canvas,
      Offset(
        rect.center.dx - painter.width / 2,
        rect.center.dy - painter.height / 2,
      ),
    );
  }

  void _drawRoute(
    Canvas canvas,
    _PitchGeometry geometry,
    ScanPassPoint from,
    ScanPassPoint to,
    Paint paint, {
    required bool dashed,
    required bool arrow,
  }) {
    final a = geometry.toOffset(from);
    final b = geometry.toOffset(to);
    if ((b - a).distance < 2) return;
    if (dashed) {
      _drawDashedLine(canvas, a, b, paint, dash: 7, gap: 5);
    } else {
      canvas.drawLine(a, b, paint);
    }
    if (arrow) _drawArrowHead(canvas, a, b, paint);
  }

  void _drawCurvedRoute(
    Canvas canvas,
    _PitchGeometry geometry,
    ScanPassPoint from,
    ScanPassPoint to,
    Paint paint, {
    required bool dashed,
  }) {
    final a = geometry.toOffset(from);
    final b = geometry.toOffset(to);
    final mid = Offset((a.dx + b.dx) / 2, math.min(a.dy, b.dy) - 26);
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
    if (!dashed) {
      canvas.drawPath(path, paint);
    } else {
      _drawDashedPath(canvas, path, paint, dash: 7, gap: 5);
    }
    _drawArrowHead(canvas, mid, b, paint);
  }

  void _drawMarker(
    Canvas canvas,
    Offset center,
    String label,
    _PitchGeometry geometry,
    Color color,
  ) {
    canvas.drawCircle(
      center,
      geometry.size.shortestSide * .023,
      Paint()
        ..color = color.withValues(alpha: .16)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      geometry.size.shortestSide * .023,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    _drawText(
      canvas,
      label,
      center + Offset(0, -math.max(26.0, geometry.size.shortestSide * .075)),
      color: color,
      fontSize: math.max(9, geometry.size.shortestSide * .027),
      anchorMode: _TextAnchor.center,
    );
  }

  void _drawFlag(
    Canvas canvas,
    Offset anchor,
    String label,
    _PitchGeometry geometry,
  ) {
    final pole = Paint()
      ..color = _accent
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(anchor, anchor + const Offset(0, 24), pole);
    final flag = Path()
      ..moveTo(anchor.dx, anchor.dy)
      ..lineTo(anchor.dx + 18, anchor.dy + 5)
      ..lineTo(anchor.dx, anchor.dy + 11)
      ..close();
    canvas.drawPath(flag, Paint()..color = _accent);
    _drawText(
      canvas,
      label,
      anchor + Offset(anchor.dx > geometry.size.width * .65 ? -6 : 23, 7),
      color: _accent,
      fontSize: math.max(9, geometry.size.shortestSide * .030),
      anchorMode: anchor.dx > geometry.size.width * .65
          ? _TextAnchor.right
          : _TextAnchor.left,
    );
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dash,
    required double gap,
  }) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final extract = metric.extractPath(
          distance,
          math.min(distance + dash, metric.length),
        );
        canvas.drawPath(extract, paint);
        distance += dash + gap;
      }
    }
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

  void _drawText(
    Canvas canvas,
    String text,
    Offset anchor, {
    required Color color,
    required double fontSize,
    FontWeight fontWeight = FontWeight.w600,
    TextAlign align = TextAlign.start,
    _TextAnchor anchorMode = _TextAnchor.left,
  }) {
    final painter = _textPainter(
      text,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      align: align,
    )..layout(maxWidth: 190);
    final dx = switch (anchorMode) {
      _TextAnchor.left => anchor.dx,
      _TextAnchor.center => anchor.dx - painter.width / 2,
      _TextAnchor.right => anchor.dx - painter.width,
    };
    painter.paint(canvas, Offset(dx, anchor.dy - painter.height / 2));
  }

  TextPainter _textPainter(
    String text, {
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
    TextAlign align = TextAlign.start,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: math.max(10, fontSize),
          fontWeight: fontWeight,
          fontFamily: fontFamily,
          height: 1.05,
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    );
  }

  @override
  bool shouldRepaint(covariant _AttackPitchPainter oldDelegate) {
    return oldDelegate.displayState != displayState ||
        oldDelegate.baseState != baseState ||
        oldDelegate.selectedAction != selectedAction ||
        oldDelegate.selectedTarget != selectedTarget ||
        oldDelegate.previewOffside != previewOffside ||
        oldDelegate.activeTransition != activeTransition ||
        oldDelegate.activeProgress != activeProgress ||
        oldDelegate.history != history ||
        oldDelegate.scanOverlay != scanOverlay ||
        oldDelegate.terminalBanner != terminalBanner ||
        oldDelegate.brightness != brightness ||
        oldDelegate.fontFamily != fontFamily;
  }
}

class _PitchLabels {
  final String attackRight;
  final String offsideLine;
  final String offsideWarning;
  final String offsideFreeze;
  final String kickPoint;
  final String receiver;
  final String secondLast;
  final String hold;
  final String Function(int number) currentPlayer;
  final String Function(AttackEnd end) outcome;

  const _PitchLabels({
    required this.attackRight,
    required this.offsideLine,
    required this.offsideWarning,
    required this.offsideFreeze,
    required this.kickPoint,
    required this.receiver,
    required this.secondLast,
    required this.hold,
    required this.currentPlayer,
    required this.outcome,
  });

  factory _PitchLabels.from(AppLocalizations l10n) {
    return _PitchLabels(
      attackRight: l10n.scanPassAttackDirectionShort,
      offsideLine: l10n.scanPassAttackOffsideLine,
      offsideWarning: l10n.scanPassAttackOffsideWarning,
      offsideFreeze: l10n.scanPassAttackOffsideFreeze,
      kickPoint: l10n.scanPassAttackKickPoint,
      receiver: l10n.scanPassAttackOffsideReceiver,
      secondLast: l10n.scanPassAttackSecondLast,
      hold: l10n.scanPassAttackHoldShort,
      currentPlayer: l10n.scanPassAttackCurrentPlayerLabel,
      outcome: (end) => switch (end) {
        AttackEnd.goal => l10n.scanPassAttackOutcomeGoal,
        AttackEnd.intercepted => l10n.scanPassAttackOutcomeIntercepted,
        AttackEnd.offside => l10n.scanPassAttackOutcomeOffside,
        AttackEnd.saved => l10n.scanPassAttackOutcomeSaved,
        AttackEnd.wide => l10n.scanPassAttackOutcomeWide,
        AttackEnd.blocked => l10n.scanPassAttackOutcomeBlocked,
      },
    );
  }
}

class _PitchGeometry {
  static const double _maxX = 1.04;

  final Size size;
  late final Rect fieldRect = Rect.fromLTWH(
    size.width * .035,
    size.height * .065,
    size.width * .93,
    size.height * .86,
  );

  _PitchGeometry(this.size);

  double x(double value) => fieldRect.left + fieldRect.width * value / _maxX;

  double y(double value) => fieldRect.top + fieldRect.height * value;

  Offset toOffset(ScanPassPoint point) => Offset(x(point.x), y(point.y));
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

  const _ScanPassColors({
    required this.background,
    required this.surface,
    required this.text,
    required this.muted,
    required this.line,
    required this.accent,
    required this.active,
    required this.team,
  });

  factory _ScanPassColors.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark) {
      return const _ScanPassColors(
        background: Color(0xFF121B1F),
        surface: Color(0xFF1A272D),
        text: Color(0xFFE9EEEB),
        muted: Color(0xFFA7B8BB),
        line: Color(0xFF34454B),
        accent: Color(0xFFE2C57E),
        active: Color(0xFF3A362B),
        team: Color(0xFF77A9C4),
      );
    }
    return const _ScanPassColors(
      background: Color(0xFFF3F5F2),
      surface: Color(0xFFFFFFFF),
      text: Color(0xFF202E33),
      muted: Color(0xFF53666D),
      line: Color(0xFFCDD7D4),
      accent: Color(0xFF84611F),
      active: Color(0xFFE9DEC4),
      team: Color(0xFF35718D),
    );
  }
}

enum _TextAnchor { left, center, right }

AttackPlayer? _playerByNumber(List<AttackPlayer> players, int number) {
  for (final player in players) {
    if (player.number == number) return player;
  }
  return null;
}

ScanPassPoint _shotPoint(AttackShotTarget target) {
  return switch (target) {
    AttackShotTarget.upper => const ScanPassPoint(.995, .38),
    AttackShotTarget.center => const ScanPassPoint(.998, .50),
    AttackShotTarget.lower => const ScanPassPoint(.995, .62),
  };
}
