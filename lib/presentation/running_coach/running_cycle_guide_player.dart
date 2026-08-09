import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../gen/app_localizations.dart';

const runningCycleAnimationAtlasAsset =
    'assets/images/running_guides/professional_runner/'
    'running_cycle_continuous_atlas_v2.png';

const _atlasColumns = 4;
const _atlasRows = 2;
const _frameCount = _atlasColumns * _atlasRows;
const _observationBlue = Color(0xFF2563EB);
const _inspectedAtlasCellHeight = 470.5;
const _sharedGroundY = 403.0;

Future<ui.Image>? _runningCycleAnimationAtlasFuture;

/// Loads the eight-frame professional running-cycle atlas once for the app.
Future<ui.Image> loadRunningCycleAnimationAtlas() {
  return _runningCycleAnimationAtlasFuture ??=
      _loadRunningCycleAnimationAtlas();
}

Future<ui.Image> _loadRunningCycleAnimationAtlas() async {
  final data = await rootBundle.load(runningCycleAnimationAtlasAsset);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  try {
    final frame = await codec.getNextFrame();
    return frame.image;
  } finally {
    codec.dispose();
  }
}

enum RunningCycleGuidePhase { landing, support, pushOff, recovery }

enum _RunningCycleGuideSpeed { normal, slow }

class RunningCycleGuidePlayer extends StatefulWidget {
  const RunningCycleGuidePlayer({super.key});

  @override
  State<RunningCycleGuidePlayer> createState() =>
      _RunningCycleGuidePlayerState();
}

class _RunningCycleGuidePlayerState extends State<RunningCycleGuidePlayer> {
  Timer? _timer;
  int _currentFrame = runningCycleGuideRepresentativeFrameForPhase(
    RunningCycleGuidePhase.landing,
  );
  _RunningCycleGuideSpeed _speed = _RunningCycleGuideSpeed.normal;
  var _isPlaying = false;
  var _didApplyInitialMotionPreference = false;

  RunningCycleGuidePhase get _selectedPhase =>
      runningCycleGuidePhaseForFrame(_currentFrame);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didApplyInitialMotionPreference) return;
    _didApplyInitialMotionPreference = true;
    _isPlaying = !MediaQuery.of(context).disableAnimations;
    _syncTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncTimer() {
    _timer?.cancel();
    if (!_isPlaying) return;
    final duration = switch (_speed) {
      _RunningCycleGuideSpeed.normal => const Duration(milliseconds: 340),
      _RunningCycleGuideSpeed.slow => const Duration(milliseconds: 720),
    };
    _timer = Timer.periodic(duration, (_) => _advanceFrame());
  }

  void _stepPhase() {
    _advanceFrame();
  }

  void _selectPhase(RunningCycleGuidePhase phase) {
    final frame = runningCycleGuideRepresentativeFrameForPhase(phase);
    if (_currentFrame == frame) {
      return;
    }
    setState(() => _currentFrame = frame);
  }

  void _advanceFrame() {
    if (!mounted) return;
    setState(() {
      _currentFrame = _nextRunningCycleGuideFrame(_currentFrame);
    });
  }

  void _togglePlayback() {
    setState(() => _isPlaying = !_isPlaying);
    _syncTimer();
  }

  void _selectSpeed(_RunningCycleGuideSpeed speed) {
    if (_speed == speed) return;
    setState(() => _speed = speed);
    _syncTimer();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final phaseCopies = _phaseCopies(l10n);
    final activeCopy = phaseCopies[_selectedPhase.index];

    return Card(
      key: const ValueKey('running-coach-good-form-cycle'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.runningCoachGoodFormCycleTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.runningCoachGoodFormCycleBody,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            FutureBuilder<ui.Image>(
              future: loadRunningCycleAnimationAtlas(),
              builder: (context, snapshot) {
                final atlas = snapshot.data;
                if (atlas == null) {
                  return const AspectRatio(
                    aspectRatio: 0.9,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final cellAspectRatio =
                    (atlas.width / _atlasColumns) / (atlas.height / _atlasRows);
                return _RunningCycleFrameView(
                  atlas: atlas,
                  presentation: runningCycleGuidePresentationForFrame(
                    _currentFrame,
                  ),
                  phaseCopy: activeCopy,
                  cellAspectRatio: cellAspectRatio,
                );
              },
            ),
            const SizedBox(height: 12),
            _ActivePhasePanel(
              key: ValueKey(
                'running-coach-good-form-active-phase-${activeCopy.phase.name}',
              ),
              copy: activeCopy,
            ),
            const SizedBox(height: 12),
            Wrap(
              key: const ValueKey(
                'running-coach-good-form-phase-selectors',
              ),
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final copy in phaseCopies)
                  ChoiceChip(
                    key: ValueKey(
                      'running-coach-good-form-phase-${copy.phase.index}',
                    ),
                    avatar: Icon(copy.icon, size: 18),
                    label: Text('${copy.number}. ${copy.title}'),
                    selected: _selectedPhase == copy.phase,
                    onSelected: (_) => _selectPhase(copy.phase),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              key: const ValueKey('running-coach-good-form-cycle-controls'),
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: const ValueKey(
                    'running-coach-good-form-cycle-play-pause',
                  ),
                  onPressed: _togglePlayback,
                  icon: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    _isPlaying
                        ? l10n.runningCoachGoodFormPauseAction
                        : l10n.runningCoachGoodFormPlayAction,
                  ),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('running-coach-good-form-cycle-step'),
                  onPressed: _stepPhase,
                  icon: const Icon(Icons.skip_next_rounded),
                  label: Text(l10n.runningCoachGoodFormStepFrameAction),
                ),
                SegmentedButton<_RunningCycleGuideSpeed>(
                  key: const ValueKey('running-coach-good-form-cycle-speed'),
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment<_RunningCycleGuideSpeed>(
                      value: _RunningCycleGuideSpeed.normal,
                      label: Text(l10n.runningCoachGoodFormSpeedNormal),
                    ),
                    ButtonSegment<_RunningCycleGuideSpeed>(
                      value: _RunningCycleGuideSpeed.slow,
                      label: Text(l10n.runningCoachGoodFormSpeedSlow),
                    ),
                  ],
                  selected: {_speed},
                  onSelectionChanged: (selection) =>
                      _selectSpeed(selection.single),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RunningCycleFrameView extends StatelessWidget {
  final ui.Image atlas;
  final RunningCycleGuideFramePresentation presentation;
  final _RunningCyclePhaseCopy phaseCopy;
  final double cellAspectRatio;

  const _RunningCycleFrameView({
    required this.atlas,
    required this.presentation,
    required this.phaseCopy,
    required this.cellAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 420),
        child: AspectRatio(
          aspectRatio: cellAspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    key: const ValueKey(
                      'running-coach-good-form-cycle-atlas-frame',
                    ),
                    painter: _RunningCycleAtlasPainter(
                      atlas: atlas,
                      presentation: presentation,
                      cellAspectRatio: cellAspectRatio,
                    ),
                  ),
                  IgnorePointer(
                    child: CustomPaint(
                      key: ValueKey(
                        'running-coach-good-form-cycle-focus-overlay-'
                        '${presentation.phase.name}',
                      ),
                      painter: _ObservationOverlayPainter(
                        presentation: presentation,
                        cellAspectRatio: cellAspectRatio,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _observationBlue.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.visibility_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              l10n.runningCoachGoodFormCycleObservationLabel(
                                phaseCopy.title,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivePhasePanel extends StatelessWidget {
  final _RunningCyclePhaseCopy copy;

  const _ActivePhasePanel({
    super.key,
    required this.copy,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _observationBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _observationBlue.withValues(alpha: 0.34)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(copy.icon, color: _observationBlue, size: 20),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    copy.cue,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    copy.focusLegend,
                    key: ValueKey(
                      'running-coach-good-form-focus-legend-'
                      '${copy.phase.name}',
                    ),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _observationBlue,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunningCycleAtlasPainter extends CustomPainter {
  final ui.Image atlas;
  final RunningCycleGuideFramePresentation presentation;
  final double cellAspectRatio;

  const _RunningCycleAtlasPainter({
    required this.atlas,
    required this.presentation,
    required this.cellAspectRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final content = _contentRectFor(size, cellAspectRatio);
    final destination = _destinationRectForPresentation(
      content,
      presentation,
    );

    canvas.save();
    canvas.clipRect(content);
    canvas.drawImageRect(
      atlas,
      _sourceRectForFrame(atlas, presentation.frame),
      destination,
      _imagePaint(),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RunningCycleAtlasPainter oldDelegate) {
    return atlas != oldDelegate.atlas ||
        presentation != oldDelegate.presentation ||
        cellAspectRatio != oldDelegate.cellAspectRatio;
  }
}

class _ObservationOverlayPainter extends CustomPainter {
  final RunningCycleGuideFramePresentation presentation;
  final double cellAspectRatio;

  const _ObservationOverlayPainter({
    required this.presentation,
    required this.cellAspectRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final content = _contentRectFor(size, cellAspectRatio);
    final destination = _destinationRectForPresentation(
      content,
      presentation,
    );
    final groundY = _targetGroundYFor(content, presentation);

    canvas.save();
    canvas.clipRect(content.deflate(2));
    canvas.drawLine(
      Offset(content.left + content.width * 0.10, groundY),
      Offset(content.right - content.width * 0.10, groundY),
      Paint()
        ..color = _observationBlue.withValues(alpha: 0.68)
        ..strokeWidth = math.max(1.2, content.width * 0.004)
        ..strokeCap = StrokeCap.round,
    );

    final guidePaint = Paint()
      ..color = _observationBlue.withValues(alpha: 0.86)
      ..strokeWidth = math.max(1.6, content.width * 0.006)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final guideLine in presentation.guideLines) {
      _drawDashedLine(
        canvas,
        _sourcePointToCanvas(destination, guideLine.start),
        _sourcePointToCanvas(destination, guideLine.end),
        guidePaint,
      );
    }

    final radius = math.max(10.0, math.min(17.0, content.shortestSide * 0.038));
    final haloPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(3.8, content.width * 0.012);
    final ringPaint = Paint()
      ..color = _observationBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, content.width * 0.007);
    final dotPaint = Paint()
      ..color = _observationBlue
      ..style = PaintingStyle.fill;
    for (final focusPoint in presentation.focusPoints) {
      final point = _sourcePointToCanvas(destination, focusPoint);
      canvas.drawCircle(point, radius, haloPaint);
      canvas.drawCircle(point, radius, ringPaint);
      canvas.drawCircle(point, math.max(2.5, radius * 0.22), dotPaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ObservationOverlayPainter oldDelegate) {
    return presentation != oldDelegate.presentation ||
        cellAspectRatio != oldDelegate.cellAspectRatio;
  }
}

@immutable
class RunningCycleGuideRelationLine {
  final Offset start;
  final Offset end;

  const RunningCycleGuideRelationLine({
    required this.start,
    required this.end,
  });
}

@immutable
class RunningCycleGuideFramePresentation {
  final RunningCycleGuidePhase phase;
  final int frame;
  final double sourceGroundY;
  final double targetGroundY;
  final double scale;
  final List<Offset> focusPoints;
  final List<RunningCycleGuideRelationLine> guideLines;

  const RunningCycleGuideFramePresentation({
    required this.phase,
    required this.frame,
    required this.sourceGroundY,
    required this.targetGroundY,
    required this.scale,
    required this.focusPoints,
    required this.guideLines,
  });

  RunningCycleGuideFramePresentation copyWith({
    RunningCycleGuidePhase? phase,
    int? frame,
    double? sourceGroundY,
    double? targetGroundY,
    double? scale,
    List<Offset>? focusPoints,
    List<RunningCycleGuideRelationLine>? guideLines,
  }) {
    return RunningCycleGuideFramePresentation(
      phase: phase ?? this.phase,
      frame: frame ?? this.frame,
      sourceGroundY: sourceGroundY ?? this.sourceGroundY,
      targetGroundY: targetGroundY ?? this.targetGroundY,
      scale: scale ?? this.scale,
      focusPoints: focusPoints ?? this.focusPoints,
      guideLines: guideLines ?? this.guideLines,
    );
  }
}

class _RunningCyclePhaseCopy {
  final RunningCycleGuidePhase phase;
  final int number;
  final IconData icon;
  final String title;
  final String cue;
  final String focusLegend;

  const _RunningCyclePhaseCopy({
    required this.phase,
    required this.number,
    required this.icon,
    required this.title,
    required this.cue,
    required this.focusLegend,
  });
}

List<_RunningCyclePhaseCopy> _phaseCopies(AppLocalizations l10n) {
  return [
    _RunningCyclePhaseCopy(
      phase: RunningCycleGuidePhase.landing,
      number: 1,
      icon: Icons.vertical_align_bottom_rounded,
      title: l10n.runningCoachGoodFormPhaseLandingTitle,
      cue: l10n.runningCoachGoodFormPhaseLandingCue,
      focusLegend: l10n.runningCoachGoodFormCycleFocusLegend(
        l10n.runningCoachGoodFormPhaseLandingFocus,
      ),
    ),
    _RunningCyclePhaseCopy(
      phase: RunningCycleGuidePhase.support,
      number: 2,
      icon: Icons.accessibility_new_rounded,
      title: l10n.runningCoachGoodFormPhaseSupportTitle,
      cue: l10n.runningCoachGoodFormPhaseSupportCue,
      focusLegend: l10n.runningCoachGoodFormCycleFocusLegend(
        l10n.runningCoachGoodFormPhaseSupportFocus,
      ),
    ),
    _RunningCyclePhaseCopy(
      phase: RunningCycleGuidePhase.pushOff,
      number: 3,
      icon: Icons.trending_flat_rounded,
      title: l10n.runningCoachGoodFormPhasePushOffTitle,
      cue: l10n.runningCoachGoodFormPhasePushOffCue,
      focusLegend: l10n.runningCoachGoodFormCycleFocusLegend(
        l10n.runningCoachGoodFormPhasePushOffFocus,
      ),
    ),
    _RunningCyclePhaseCopy(
      phase: RunningCycleGuidePhase.recovery,
      number: 4,
      icon: Icons.autorenew_rounded,
      title: l10n.runningCoachGoodFormPhaseRecoveryTitle,
      cue: l10n.runningCoachGoodFormPhaseRecoveryCue,
      focusLegend: l10n.runningCoachGoodFormCycleFocusLegend(
        l10n.runningCoachGoodFormPhaseRecoveryFocus,
      ),
    ),
  ];
}

const _runningCycleGuidePresentations =
    <RunningCycleGuidePhase, RunningCycleGuideFramePresentation>{
  RunningCycleGuidePhase.landing: RunningCycleGuideFramePresentation(
    phase: RunningCycleGuidePhase.landing,
    frame: 3,
    sourceGroundY: _sharedGroundY,
    targetGroundY: _sharedGroundY,
    scale: 1.0,
    focusPoints: [Offset(0.72, 0.87)],
    guideLines: [
      RunningCycleGuideRelationLine(
        start: Offset(0.60, _sharedGroundY / _inspectedAtlasCellHeight),
        end: Offset(0.78, _sharedGroundY / _inspectedAtlasCellHeight),
      ),
    ],
  ),
  RunningCycleGuidePhase.support: RunningCycleGuideFramePresentation(
    phase: RunningCycleGuidePhase.support,
    frame: 4,
    sourceGroundY: _sharedGroundY,
    targetGroundY: _sharedGroundY,
    scale: 1.0,
    focusPoints: [Offset(0.62, 0.64)],
    guideLines: [
      RunningCycleGuideRelationLine(
        start: Offset(0.62, 0.64),
        end: Offset(0.68, 0.84),
      ),
    ],
  ),
  RunningCycleGuidePhase.pushOff: RunningCycleGuideFramePresentation(
    phase: RunningCycleGuidePhase.pushOff,
    frame: 5,
    sourceGroundY: _sharedGroundY,
    targetGroundY: _sharedGroundY,
    scale: 1.0,
    focusPoints: [Offset(0.34, 0.82)],
    guideLines: [
      RunningCycleGuideRelationLine(
        start: Offset(0.34, 0.82),
        end: Offset(0.50, _sharedGroundY / _inspectedAtlasCellHeight),
      ),
    ],
  ),
  RunningCycleGuidePhase.recovery: RunningCycleGuideFramePresentation(
    phase: RunningCycleGuidePhase.recovery,
    frame: 6,
    sourceGroundY: _sharedGroundY,
    targetGroundY: _sharedGroundY,
    scale: 1.0,
    focusPoints: [Offset(0.63, 0.55), Offset(0.52, 0.73)],
    guideLines: [
      RunningCycleGuideRelationLine(
        start: Offset(0.63, 0.55),
        end: Offset(0.52, 0.73),
      ),
    ],
  ),
};

int _representativeFrameForPhase(RunningCycleGuidePhase phase) {
  return _presentationForPhase(phase).frame;
}

const _runningCycleGuideLoopFrames = <int>[3, 4, 5, 6, 7, 0, 1, 2];

int _nextRunningCycleGuideFrame(int currentFrame) {
  final normalized = _normalizedFrame(currentFrame);
  final currentIndex = _runningCycleGuideLoopFrames.indexOf(normalized);
  if (currentIndex < 0) return _runningCycleGuideLoopFrames.first;
  return _runningCycleGuideLoopFrames[
      (currentIndex + 1) % _runningCycleGuideLoopFrames.length];
}

@visibleForTesting
int runningCycleGuideRepresentativeFrameForPhase(
  RunningCycleGuidePhase phase,
) {
  return _representativeFrameForPhase(phase);
}

@visibleForTesting
List<int> runningCycleGuideLoopFrameOrderForTesting() {
  return List<int>.unmodifiable(_runningCycleGuideLoopFrames);
}

@visibleForTesting
RunningCycleGuidePhase runningCycleGuidePhaseForFrame(int frame) {
  return switch (_normalizedFrame(frame)) {
    3 || 0 => RunningCycleGuidePhase.landing,
    4 || 1 => RunningCycleGuidePhase.support,
    5 || 2 => RunningCycleGuidePhase.pushOff,
    6 || 7 => RunningCycleGuidePhase.recovery,
    _ => RunningCycleGuidePhase.landing,
  };
}

@visibleForTesting
RunningCycleGuideFramePresentation runningCycleGuidePresentationForPhase(
  RunningCycleGuidePhase phase,
) {
  return _presentationForPhase(phase);
}

@visibleForTesting
RunningCycleGuideFramePresentation runningCycleGuidePresentationForFrame(
  int frame,
) {
  final normalized = _normalizedFrame(frame);
  final base =
      _presentationForPhase(runningCycleGuidePhaseForFrame(normalized));
  return base.copyWith(
    frame: normalized,
    sourceGroundY: _sharedGroundY,
    targetGroundY: _sharedGroundY,
    scale: 1.0,
  );
}

@visibleForTesting
Rect runningCycleGuideSourceRectForFrame(ui.Image atlas, int frame) {
  return _sourceRectForFrame(atlas, frame);
}

@visibleForTesting
Rect runningCycleGuideDestinationRectForPhase(
  Size size,
  double aspectRatio,
  RunningCycleGuidePhase phase,
) {
  return _destinationRectForPresentation(
    _contentRectFor(size, aspectRatio),
    _presentationForPhase(phase),
  );
}

@visibleForTesting
Rect runningCycleGuideDestinationRectForFrame(
  Size size,
  double aspectRatio,
  int frame,
) {
  return _destinationRectForPresentation(
    _contentRectFor(size, aspectRatio),
    runningCycleGuidePresentationForFrame(frame),
  );
}

RunningCycleGuideFramePresentation _presentationForPhase(
  RunningCycleGuidePhase phase,
) {
  return _runningCycleGuidePresentations[phase]!;
}

int _normalizedFrame(int frame) => frame % _frameCount;

Rect _sourceRectForFrame(ui.Image atlas, int frame) {
  final cellWidth = atlas.width / _atlasColumns;
  final cellHeight = atlas.height / _atlasRows;
  final normalized = _normalizedFrame(frame);
  final column = normalized % _atlasColumns;
  final row = normalized ~/ _atlasColumns;
  return Rect.fromLTWH(
    cellWidth * column,
    cellHeight * row,
    cellWidth,
    cellHeight,
  );
}

Rect _contentRectFor(Size size, double aspectRatio) {
  var width = size.width;
  var height = width / aspectRatio;
  if (height > size.height) {
    height = size.height;
    width = height * aspectRatio;
  }
  return Rect.fromLTWH(
    (size.width - width) / 2,
    (size.height - height) / 2,
    width,
    height,
  );
}

Rect _destinationRectForPresentation(
  Rect content,
  RunningCycleGuideFramePresentation presentation,
) {
  final width = content.width * presentation.scale;
  final height = content.height * presentation.scale;
  final groundY = _targetGroundYFor(content, presentation);
  final sourceGroundFraction =
      presentation.sourceGroundY / _inspectedAtlasCellHeight;
  return Rect.fromLTWH(
    content.left + (content.width - width) / 2,
    groundY - height * sourceGroundFraction,
    width,
    height,
  );
}

double _targetGroundYFor(
  Rect content,
  RunningCycleGuideFramePresentation presentation,
) {
  return content.top +
      content.height * presentation.targetGroundY / _inspectedAtlasCellHeight;
}

Offset _sourcePointToCanvas(Rect destination, Offset sourcePoint) {
  return Offset(
    destination.left + destination.width * sourcePoint.dx,
    destination.top + destination.height * sourcePoint.dy,
  );
}

void _drawDashedLine(
  Canvas canvas,
  Offset start,
  Offset end,
  Paint paint,
) {
  final delta = end - start;
  final distance = delta.distance;
  if (distance <= 0) {
    return;
  }
  final unit = delta / distance;
  const dash = 7.0;
  const gap = 5.0;
  var current = 0.0;
  while (current < distance) {
    final next = math.min(current + dash, distance);
    canvas.drawLine(start + unit * current, start + unit * next, paint);
    current += dash + gap;
  }
}

Paint _imagePaint() {
  return Paint()
    ..filterQuality = FilterQuality.high
    ..isAntiAlias = true;
}
