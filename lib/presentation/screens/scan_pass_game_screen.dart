import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../../application/scan_pass_history_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../../domain/scan_pass/scan_pass_game.dart';
import '../theme/app_motion.dart';

enum _ScanPassPhase { preview, choice, pass, feedback, result }

class ScanPassGameScreen extends StatefulWidget {
  final OptionRepository optionRepository;
  final int? seed;
  final Duration previewDuration;
  final Duration choiceDuration;
  final Duration passAnimationDuration;

  const ScanPassGameScreen({
    super.key,
    required this.optionRepository,
    this.seed,
    this.previewDuration = const Duration(milliseconds: 1100),
    this.choiceDuration = ScanPassScorer.defaultChoiceWindow,
    this.passAnimationDuration = const Duration(milliseconds: 620),
  });

  @override
  State<ScanPassGameScreen> createState() => _ScanPassGameScreenState();
}

class _ScanPassGameScreenState extends State<ScanPassGameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _navy = Color(0xFF071A2F);
  static const Color _surface = Color(0xFF0D2740);
  static const Color _cyan = Color(0xFF34D5E5);
  static const int _roundCount = ScanPassRoundGenerator.roundCount;

  final ScanPassScorer _scorer = const ScanPassScorer();
  late final AnimationController _previewController;
  late final AnimationController _passController;
  late List<ScanPassRound> _rounds;
  Timer? _phaseTimer;
  Timer? _choiceTicker;
  ScanPassChoiceClock? _choiceClock;
  ScanPassPersonalSummary _personalSummary =
      const ScanPassPersonalSummary.empty();
  ScanPassRoundEvaluation? _evaluation;
  ScanPassRouteScore? _selectedScore;
  Duration _remainingChoice = ScanPassScorer.defaultChoiceWindow;
  _ScanPassPhase _phase = _ScanPassPhase.preview;
  final List<ScanPassRoundResult> _results = <ScanPassRoundResult>[];
  int _roundIndex = 0;
  int _phaseToken = 0;
  bool _savingHistory = false;

  ScanPassRound get _round => _rounds[_roundIndex];

  int get _currentRoundNumber => _roundIndex + 1;

  int get _currentTopGroupStreak {
    var streak = 0;
    for (final result in _results.reversed) {
      if (result.timedOut || result.bestScore - result.chosenScore > 7) break;
      streak += 1;
    }
    return streak;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _previewController = AnimationController(
      vsync: this,
      duration: widget.previewDuration,
    );
    _passController = AnimationController(
      vsync: this,
      duration: widget.passAnimationDuration,
    );
    _personalSummary = ScanPassHistoryService(widget.optionRepository).load();
    _startSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimers();
    _previewController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _cancelTimers();
      return;
    }
    if (state != AppLifecycleState.resumed || !mounted) return;
    switch (_phase) {
      case _ScanPassPhase.preview:
        _startPreview();
        break;
      case _ScanPassPhase.choice:
        _beginChoice();
        break;
      case _ScanPassPhase.pass:
        _showFeedback();
        break;
      case _ScanPassPhase.feedback:
      case _ScanPassPhase.result:
        break;
    }
  }

  void _startSession() {
    final seed = widget.seed ?? DateTime.now().millisecondsSinceEpoch;
    _rounds = ScanPassRoundGenerator(seed: seed).generateSession();
    _results.clear();
    _roundIndex = 0;
    _selectedScore = null;
    _evaluation = null;
    _savingHistory = false;
    _startPreview();
  }

  void _startPreview() {
    _cancelTimers();
    _phaseToken += 1;
    final token = _phaseToken;
    _previewController
      ..stop()
      ..value = 0;
    _passController
      ..stop()
      ..value = 0;
    setState(() {
      _phase = _ScanPassPhase.preview;
      _selectedScore = null;
      _evaluation = null;
      _remainingChoice = widget.choiceDuration;
    });
    if (_round.occlusionMode == ScanPassOcclusionMode.prediction &&
        !AppMotion.reduceMotion(context)) {
      unawaited(_previewController.forward(from: 0));
    } else {
      _previewController.value = 1;
    }
    _phaseTimer = Timer(widget.previewDuration, () {
      if (!mounted || token != _phaseToken) return;
      _beginChoice();
    });
  }

  void _beginChoice() {
    _cancelTimers(incrementToken: false);
    _phaseToken += 1;
    final token = _phaseToken;
    final now = DateTime.now();
    _choiceClock = ScanPassChoiceClock(
      startedAt: now,
      choiceWindow: widget.choiceDuration,
    );
    setState(() {
      _phase = _ScanPassPhase.choice;
      _remainingChoice = widget.choiceDuration;
    });
    _choiceTicker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final clock = _choiceClock;
      if (!mounted || token != _phaseToken || clock == null) return;
      final remaining = clock.remainingAt(DateTime.now());
      if (remaining == Duration.zero) {
        _handleTimeout(token);
      } else {
        setState(() => _remainingChoice = remaining);
      }
    });
  }

  void _handleTimeout(int token) {
    if (!mounted || token != _phaseToken || _phase != _ScanPassPhase.choice) {
      return;
    }
    _choiceTicker?.cancel();
    final evaluation = _scorer.evaluateRound(
      _round,
      responseTime: widget.choiceDuration,
      choiceWindow: widget.choiceDuration,
    );
    _results.add(
      ScanPassRoundResult(
        roundNumber: _currentRoundNumber,
        targetId: null,
        chosenScore: 0,
        bestScore: evaluation.bestScore,
        responseTime: widget.choiceDuration,
        timedOut: true,
      ),
    );
    setState(() {
      _evaluation = evaluation;
      _selectedScore = null;
      _remainingChoice = Duration.zero;
      _phase = _ScanPassPhase.feedback;
    });
  }

  void _selectTarget(ScanPassPlayer target) {
    if (_phase != _ScanPassPhase.choice || _selectedScore != null) return;
    final clock = _choiceClock;
    if (clock == null) return;
    _phaseToken += 1;
    _choiceTicker?.cancel();
    final responseTime = clock.responseTimeAt(DateTime.now());
    final evaluation = _scorer.evaluateRound(
      _round,
      responseTime: responseTime,
      choiceWindow: widget.choiceDuration,
    );
    final selected = evaluation.routeForTarget(target.id);
    _results.add(
      ScanPassRoundResult(
        roundNumber: _currentRoundNumber,
        targetId: target.id,
        chosenScore: selected.totalScore,
        bestScore: evaluation.bestScore,
        responseTime: responseTime,
      ),
    );
    HapticFeedback.selectionClick();
    setState(() {
      _evaluation = evaluation;
      _selectedScore = selected;
      _phase = _ScanPassPhase.pass;
    });
    if (AppMotion.reduceMotion(context) ||
        widget.passAnimationDuration == Duration.zero) {
      _passController.value = 1;
      _showFeedback();
      return;
    }
    _passController
      ..duration = widget.passAnimationDuration
      ..forward(from: 0).whenComplete(() {
        if (!mounted || _phase != _ScanPassPhase.pass) return;
        _showFeedback();
      });
  }

  void _showFeedback() {
    _cancelTimers(incrementToken: false);
    if (!mounted) return;
    setState(() => _phase = _ScanPassPhase.feedback);
  }

  void _advance() {
    if (_phase != _ScanPassPhase.feedback) return;
    if (_results.length >= _roundCount) {
      _showResult();
      return;
    }
    _roundIndex += 1;
    _startPreview();
  }

  void _showResult() {
    _cancelTimers();
    setState(() => _phase = _ScanPassPhase.result);
    _saveHistoryIfNeeded();
  }

  Future<void> _saveHistoryIfNeeded() async {
    if (_savingHistory) return;
    _savingHistory = true;
    final session = ScanPassSessionSummary.fromResults(_results);
    final next = await ScanPassHistoryService(
      widget.optionRepository,
    ).recordSession(session);
    if (!mounted) return;
    setState(() => _personalSummary = next);
  }

  void _cancelTimers({bool incrementToken = true}) {
    if (incrementToken) _phaseToken += 1;
    _phaseTimer?.cancel();
    _phaseTimer = null;
    _choiceTicker?.cancel();
    _choiceTicker = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        title: Text(l10n.scanPassTitle),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: _phase == _ScanPassPhase.result
            ? _buildResult(l10n)
            : _buildRound(l10n),
      ),
    );
  }

  Widget _buildRound(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 620;
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, compact ? 8 : 12, 16, 8),
              child: _buildStatus(l10n),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _previewController,
                      _passController,
                    ]),
                    builder: (context, _) {
                      return _ScanPassField(
                        round: _round,
                        phase: _phase,
                        previewProgress: _previewController.value,
                        passProgress: _passController.value,
                        selectedTargetId: _selectedScore?.targetId,
                        onTargetTap: _phase == _ScanPassPhase.choice
                            ? _selectTarget
                            : null,
                        l10n: l10n,
                      );
                    },
                  ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: math.max(150, constraints.maxHeight * 0.34),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 8, 16, compact ? 10 : 16),
                child: _buildBottomPanel(l10n),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatus(AppLocalizations l10n) {
    final seconds = (_remainingChoice.inMilliseconds / 1000).clamp(0.0, 99.0);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _ScanPassStatusPill(
          icon: Icons.flag_outlined,
          label: l10n.scanPassRoundStatus(_currentRoundNumber, _roundCount),
        ),
        _ScanPassStatusPill(
          icon: Icons.timer_outlined,
          label: l10n.scanPassTimeStatus(seconds.toStringAsFixed(1)),
          emphasized: _phase == _ScanPassPhase.choice,
        ),
        _ScanPassStatusPill(
          icon: Icons.bolt_outlined,
          label: l10n.scanPassStreakStatus(_currentTopGroupStreak),
        ),
      ],
    );
  }

  Widget _buildBottomPanel(AppLocalizations l10n) {
    final feedback = _feedbackText(l10n);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              feedback,
              key: const ValueKey<String>('scan-pass-bottom-text'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFF5F7FA),
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (_phase == _ScanPassPhase.feedback) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: const ValueKey<String>('scan-pass-next-button'),
                  onPressed: _advance,
                  icon: Icon(
                    _results.length >= _roundCount
                        ? Icons.assessment_outlined
                        : Icons.arrow_forward,
                  ),
                  label: Text(
                    _results.length >= _roundCount
                        ? l10n.scanPassSeeResultAction
                        : l10n.scanPassNextRoundAction,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _feedbackText(AppLocalizations l10n) {
    switch (_phase) {
      case _ScanPassPhase.preview:
        if (_round.occlusionMode == ScanPassOcclusionMode.prediction) {
          return l10n.scanPassPredictionPreviewInstruction;
        }
        return l10n.scanPassPreviewInstruction;
      case _ScanPassPhase.choice:
        return switch (_round.occlusionMode) {
          ScanPassOcclusionMode.silhouettes =>
            l10n.scanPassSilhouetteChoiceInstruction,
          ScanPassOcclusionMode.hidden => l10n.scanPassHiddenChoiceInstruction,
          ScanPassOcclusionMode.prediction =>
            l10n.scanPassPredictionChoiceInstruction,
        };
      case _ScanPassPhase.pass:
        return l10n.scanPassPassInFlight;
      case _ScanPassPhase.feedback:
        final evaluation = _evaluation;
        final selected = _selectedScore;
        if (selected == null) {
          return l10n.scanPassTimeoutFeedback(evaluation?.bestScore ?? 0);
        }
        final reason = _reasonText(l10n, selected.feedbackType);
        if (evaluation == null || evaluation.isComparableToBest(selected)) {
          return l10n.scanPassFeedbackComparable(
            selected.totalScore,
            reason,
          );
        }
        return l10n.scanPassFeedbackBehind(
          selected.totalScore,
          evaluation.bestScore,
          reason,
        );
      case _ScanPassPhase.result:
        return '';
    }
  }

  String _reasonText(
    AppLocalizations l10n,
    ScanPassRouteFeedbackType feedbackType,
  ) {
    return switch (feedbackType) {
      ScanPassRouteFeedbackType.clearLane => l10n.scanPassReasonClearLane,
      ScanPassRouteFeedbackType.timedRun => l10n.scanPassReasonTimedRun,
      ScanPassRouteFeedbackType.openSpace => l10n.scanPassReasonOpenSpace,
      ScanPassRouteFeedbackType.forwardThreat =>
        l10n.scanPassReasonForwardThreat,
      ScanPassRouteFeedbackType.pressuredLane =>
        l10n.scanPassReasonPressuredLane,
      ScanPassRouteFeedbackType.lateArrival => l10n.scanPassReasonLateArrival,
      ScanPassRouteFeedbackType.tightReceiver =>
        l10n.scanPassReasonTightReceiver,
      ScanPassRouteFeedbackType.lowProgression =>
        l10n.scanPassReasonLowProgression,
    };
  }

  Widget _buildResult(AppLocalizations l10n) {
    final session = ScanPassSessionSummary.fromResults(_results);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _cyan.withValues(alpha: 0.34),
                      width: 1.2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.scanPassResultTitle,
                          key: const ValueKey<String>(
                            'scan-pass-result-title',
                          ),
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.scanPassResultSubtitle(
                            session.averageRouteScore.round(),
                            session.decisionAccuracyPercent.round(),
                            l10n.scanPassSecondsValue(
                              (session.averageResponseMs / 1000)
                                  .toStringAsFixed(2),
                            ),
                          ),
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.80),
                                    height: 1.25,
                                  ),
                        ),
                        const SizedBox(height: 18),
                        _ScanPassMetricGrid(
                          metrics: [
                            _ScanPassMetricData(
                              label: l10n.scanPassAverageRouteScore,
                              value:
                                  session.averageRouteScore.round().toString(),
                            ),
                            _ScanPassMetricData(
                              label: l10n.scanPassDecisionAccuracy,
                              value: l10n.scanPassPercentValue(
                                session.decisionAccuracyPercent.round(),
                              ),
                            ),
                            _ScanPassMetricData(
                              label: l10n.scanPassAverageResponse,
                              value: l10n.scanPassSecondsValue(
                                (session.averageResponseMs / 1000)
                                    .toStringAsFixed(2),
                              ),
                            ),
                            _ScanPassMetricData(
                              label: l10n.scanPassBestAverageRouteScore,
                              value: _personalSummary.bestAverageRouteScore
                                  .round()
                                  .toString(),
                            ),
                            _ScanPassMetricData(
                              label: l10n.scanPassBestAccuracy,
                              value: l10n.scanPassPercentValue(
                                _personalSummary.bestDecisionAccuracyPercent
                                    .round(),
                              ),
                            ),
                            _ScanPassMetricData(
                              label: l10n.scanPassBestResponse,
                              value: _personalSummary.bestAverageResponseMs == 0
                                  ? l10n.scanPassNoHistoryValue
                                  : l10n.scanPassSecondsValue(
                                      (_personalSummary.bestAverageResponseMs /
                                              1000)
                                          .toStringAsFixed(2),
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          key: const ValueKey<String>(
                            'scan-pass-play-again-button',
                          ),
                          onPressed: _startSession,
                          icon: const Icon(Icons.replay),
                          label: Text(l10n.scanPassPlayAgainAction),
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
    );
  }
}

class _ScanPassStatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool emphasized;

  const _ScanPassStatusPill({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: emphasized
            ? const Color(0xFF34D5E5).withValues(alpha: 0.20)
            : Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: emphasized
              ? const Color(0xFF34D5E5)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanPassField extends StatelessWidget {
  final ScanPassRound round;
  final _ScanPassPhase phase;
  final double previewProgress;
  final double passProgress;
  final int? selectedTargetId;
  final ValueChanged<ScanPassPlayer>? onTargetTap;
  final AppLocalizations l10n;

  const _ScanPassField({
    required this.round,
    required this.phase,
    required this.previewProgress,
    required this.passProgress,
    required this.selectedTargetId,
    required this.onTargetTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(
          constraints.maxWidth,
          constraints.maxHeight * 0.68,
        );
        final height = math.min(constraints.maxHeight, width / 0.68);
        final size = Size(width, height);
        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ScanPassFieldPainter(
                    round: round,
                    phase: phase,
                    previewProgress: previewProgress,
                    passProgress: passProgress,
                    selectedTargetId: selectedTargetId,
                  ),
                ),
              ),
              for (final teammate in round.teammates)
                _targetHotspot(teammate, size),
            ],
          ),
        );
      },
    );
  }

  Widget _targetHotspot(ScanPassPlayer teammate, Size size) {
    final center = _toOffset(teammate.position, size);
    const side = 58.0;
    return Positioned(
      left: center.dx - (side / 2),
      top: center.dy - (side / 2),
      width: side,
      height: side,
      child: Semantics(
        button: true,
        enabled: onTargetTap != null,
        label: l10n.scanPassTargetSemantics(teammate.number),
        child: GestureDetector(
          key: ValueKey<String>('scan-pass-target-${teammate.id}'),
          behavior: HitTestBehavior.translucent,
          onTap: onTargetTap == null ? null : () => onTargetTap!(teammate),
        ),
      ),
    );
  }
}

class _ScanPassFieldPainter extends CustomPainter {
  static const Color _emerald = Color(0xFF087A5F);
  static const Color _emeraldDark = Color(0xFF05664F);
  static const Color _cyan = Color(0xFF34D5E5);
  static const Color _blue = Color(0xFF3D7BFF);
  static const Color _coral = Color(0xFFFF6B5F);
  static const Color _yellow = Color(0xFFFFD54D);
  static const Color _offWhite = Color(0xFFF5F7FA);

  final ScanPassRound round;
  final _ScanPassPhase phase;
  final double previewProgress;
  final double passProgress;
  final int? selectedTargetId;

  const _ScanPassFieldPainter({
    required this.round,
    required this.phase,
    required this.previewProgress,
    required this.passProgress,
    required this.selectedTargetId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final field = Offset.zero & size;
    final fieldRadius = BorderRadius.circular(8).toRRect(field);
    canvas.drawRRect(fieldRadius, Paint()..color = _emerald);
    _drawStripes(canvas, size);
    _drawFieldLines(canvas, size);
    _drawDefenders(canvas, size);
    _drawPass(canvas, size);
    _drawPlayer(
      canvas,
      size,
      round.ballCarrier,
      fill: _yellow,
      textColor: const Color(0xFF102135),
      radiusScale: 1.08,
    );
    for (final teammate in round.teammates) {
      _drawPlayer(
        canvas,
        size,
        teammate,
        fill: _blue,
        textColor: _offWhite,
        selected: teammate.id == selectedTargetId,
      );
    }
  }

  void _drawStripes(Canvas canvas, Size size) {
    final stripePaint = Paint()..color = _emeraldDark.withValues(alpha: 0.18);
    final stripeHeight = size.height / 8;
    for (var i = 0; i < 8; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight),
        stripePaint,
      );
    }
  }

  void _drawFieldLines(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = _offWhite.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final margin = size.shortestSide * 0.055;
    final inner = Rect.fromLTWH(
      margin,
      margin,
      size.width - (margin * 2),
      size.height - (margin * 2),
    );
    canvas.drawRRect(BorderRadius.circular(6).toRRect(inner), linePaint);
    canvas.drawLine(
      Offset(inner.left, inner.center.dy),
      Offset(inner.right, inner.center.dy),
      linePaint,
    );
    canvas.drawCircle(inner.center, size.width * 0.095, linePaint);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(inner.center.dx, inner.top),
        width: size.width * 0.42,
        height: size.height * 0.16,
      ),
      linePaint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(inner.center.dx, inner.bottom),
        width: size.width * 0.42,
        height: size.height * 0.16,
      ),
      linePaint,
    );
  }

  void _drawDefenders(Canvas canvas, Size size) {
    final visible = phase == _ScanPassPhase.preview ||
        phase == _ScanPassPhase.pass ||
        phase == _ScanPassPhase.feedback ||
        (phase == _ScanPassPhase.choice &&
            round.occlusionMode == ScanPassOcclusionMode.silhouettes);
    if (!visible) return;
    final alpha = switch (phase) {
      _ScanPassPhase.preview => 0.92,
      _ScanPassPhase.choice => 0.24,
      _ => 0.62,
    };
    final radius = size.shortestSide * 0.034;
    for (final defender in round.defenders) {
      final predicted = defender.predictedPosition();
      final position = round.occlusionMode == ScanPassOcclusionMode.prediction
          ? defender.position.lerp(predicted, previewProgress)
          : defender.position;
      if (round.occlusionMode == ScanPassOcclusionMode.prediction &&
          phase == _ScanPassPhase.preview) {
        final trailPaint = Paint()
          ..color = _coral.withValues(alpha: 0.36)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          _toOffset(defender.position, size),
          _toOffset(predicted, size),
          trailPaint,
        );
      }
      final center = _toOffset(position, size);
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = _coral.withValues(alpha: alpha),
      );
      _drawFacingMarker(
        canvas,
        center,
        radius,
        defender.velocity.distance == 0
            ? -math.pi / 2
            : math.atan2(defender.velocity.y, defender.velocity.x),
        _offWhite.withValues(alpha: alpha),
      );
    }
  }

  void _drawPass(Canvas canvas, Size size) {
    final targetId = selectedTargetId;
    if (targetId == null ||
        (phase != _ScanPassPhase.pass && phase != _ScanPassPhase.feedback)) {
      return;
    }
    final target =
        round.teammates.firstWhere((player) => player.id == targetId);
    final from = _toOffset(round.ballCarrier.position, size);
    final to = _toOffset(target.position, size);
    final linePaint = Paint()
      ..color = _cyan.withValues(alpha: 0.72)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, linePaint);
    final ringPaint = Paint()
      ..color = _cyan.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(
      to,
      (size.shortestSide * 0.050) + (8 * passProgress),
      ringPaint,
    );
    final ballPosition = Offset.lerp(from, to, passProgress.clamp(0.0, 1.0))!;
    canvas.drawCircle(
      ballPosition,
      math.max(4, size.shortestSide * 0.013),
      Paint()..color = _yellow,
    );
  }

  void _drawPlayer(
    Canvas canvas,
    Size size,
    ScanPassPlayer player, {
    required Color fill,
    required Color textColor,
    bool selected = false,
    double radiusScale = 1,
  }) {
    final center = _toOffset(player.position, size);
    final radius = size.shortestSide * 0.040 * radiusScale;
    if (selected &&
        (phase == _ScanPassPhase.pass || phase == _ScanPassPhase.feedback)) {
      canvas.drawCircle(
        center,
        radius + 8,
        Paint()
          ..color = _cyan.withValues(alpha: 0.20)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    canvas.drawCircle(
      center,
      radius + 2,
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
    canvas.drawCircle(center, radius, Paint()..color = fill);
    _drawFacingMarker(canvas, center, radius, player.facingRadians, textColor);
    final painter = TextPainter(
      text: TextSpan(
        text: player.number.toString(),
        style: TextStyle(
          color: textColor,
          fontSize: radius * 0.86,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  void _drawFacingMarker(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    Color color,
  ) {
    final tip =
        center + Offset(math.cos(angle), math.sin(angle)) * (radius + 6);
    final left = center +
        Offset(
              math.cos(angle + 2.55),
              math.sin(angle + 2.55),
            ) *
            (radius * 0.38);
    final right = center +
        Offset(
              math.cos(angle - 2.55),
              math.sin(angle - 2.55),
            ) *
            (radius * 0.38);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ScanPassFieldPainter oldDelegate) {
    return oldDelegate.round != round ||
        oldDelegate.phase != phase ||
        oldDelegate.previewProgress != previewProgress ||
        oldDelegate.passProgress != passProgress ||
        oldDelegate.selectedTargetId != selectedTargetId;
  }
}

Offset _toOffset(ScanPassPoint point, Size size) {
  return Offset(point.x * size.width, point.y * size.height);
}

class _ScanPassMetricData {
  final String label;
  final String value;

  const _ScanPassMetricData({required this.label, required this.value});
}

class _ScanPassMetricGrid extends StatelessWidget {
  final List<_ScanPassMetricData> metrics;

  const _ScanPassMetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 460 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: columns == 3 ? 2.15 : 1.75,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        metric.value,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metric.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.74),
                            height: 1.05,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
