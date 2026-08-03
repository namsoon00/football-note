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

class RunningCycleGuidePlayer extends StatefulWidget {
  const RunningCycleGuidePlayer({super.key});

  @override
  State<RunningCycleGuidePlayer> createState() =>
      _RunningCycleGuidePlayerState();
}

class _RunningCycleGuidePlayerState extends State<RunningCycleGuidePlayer> {
  RunningCycleGuidePhase _selectedPhase = RunningCycleGuidePhase.landing;

  void _stepPhase() {
    const phases = RunningCycleGuidePhase.values;
    final nextIndex = (_selectedPhase.index + 1) % phases.length;
    _selectPhase(phases[nextIndex]);
  }

  void _selectPhase(RunningCycleGuidePhase phase) {
    if (_selectedPhase == phase) {
      return;
    }
    setState(() => _selectedPhase = phase);
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
                  frame: runningCycleGuideRepresentativeFrameForPhase(
                    _selectedPhase,
                  ),
                  phase: _selectedPhase,
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
                OutlinedButton.icon(
                  key: const ValueKey('running-coach-good-form-cycle-step'),
                  onPressed: _stepPhase,
                  icon: const Icon(Icons.skip_next_rounded),
                  label: Text(l10n.runningCoachGoodFormStepAction),
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
  final int frame;
  final RunningCycleGuidePhase phase;
  final _RunningCyclePhaseCopy phaseCopy;
  final double cellAspectRatio;

  const _RunningCycleFrameView({
    required this.atlas,
    required this.frame,
    required this.phase,
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
                      frame: frame,
                      cellAspectRatio: cellAspectRatio,
                    ),
                  ),
                  IgnorePointer(
                    child: CustomPaint(
                      painter: _ObservationOverlayPainter(
                        phase: phase,
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
  final int frame;
  final double cellAspectRatio;

  const _RunningCycleAtlasPainter({
    required this.atlas,
    required this.frame,
    required this.cellAspectRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final destination = _contentRectFor(size, cellAspectRatio);

    canvas.drawImageRect(
      atlas,
      _sourceRectForFrame(atlas, frame),
      destination,
      _imagePaint(),
    );
  }

  @override
  bool shouldRepaint(covariant _RunningCycleAtlasPainter oldDelegate) {
    return atlas != oldDelegate.atlas ||
        frame != oldDelegate.frame ||
        cellAspectRatio != oldDelegate.cellAspectRatio;
  }
}

class _ObservationOverlayPainter extends CustomPainter {
  final RunningCycleGuidePhase phase;
  final double cellAspectRatio;

  const _ObservationOverlayPainter({
    required this.phase,
    required this.cellAspectRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final content = _contentRectFor(size, cellAspectRatio).deflate(5);
    final band = _phaseBandFor(content, phase);
    final radius = Radius.circular(math.min(18, content.width * 0.05));

    canvas.drawRRect(
      RRect.fromRectAndRadius(band, radius),
      Paint()
        ..color = _observationBlue.withValues(alpha: 0.10)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(content, radius),
      Paint()
        ..color = _observationBlue.withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final groundY = content.top + content.height * 0.82;
    canvas.drawLine(
      Offset(content.left + content.width * 0.12, groundY),
      Offset(content.right - content.width * 0.12, groundY),
      Paint()
        ..color = _observationBlue.withValues(alpha: 0.48)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ObservationOverlayPainter oldDelegate) {
    return phase != oldDelegate.phase ||
        cellAspectRatio != oldDelegate.cellAspectRatio;
  }
}

class _RunningCyclePhaseCopy {
  final RunningCycleGuidePhase phase;
  final int number;
  final IconData icon;
  final String title;
  final String cue;

  const _RunningCyclePhaseCopy({
    required this.phase,
    required this.number,
    required this.icon,
    required this.title,
    required this.cue,
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
    ),
    _RunningCyclePhaseCopy(
      phase: RunningCycleGuidePhase.support,
      number: 2,
      icon: Icons.accessibility_new_rounded,
      title: l10n.runningCoachGoodFormPhaseSupportTitle,
      cue: l10n.runningCoachGoodFormPhaseSupportCue,
    ),
    _RunningCyclePhaseCopy(
      phase: RunningCycleGuidePhase.pushOff,
      number: 3,
      icon: Icons.trending_flat_rounded,
      title: l10n.runningCoachGoodFormPhasePushOffTitle,
      cue: l10n.runningCoachGoodFormPhasePushOffCue,
    ),
    _RunningCyclePhaseCopy(
      phase: RunningCycleGuidePhase.recovery,
      number: 4,
      icon: Icons.autorenew_rounded,
      title: l10n.runningCoachGoodFormPhaseRecoveryTitle,
      cue: l10n.runningCoachGoodFormPhaseRecoveryCue,
    ),
  ];
}

int _representativeFrameForPhase(RunningCycleGuidePhase phase) {
  return switch (phase) {
    // The atlas cells are static illustrations, not a dependable timeline.
    // These representatives were selected by visible body shape.
    RunningCycleGuidePhase.landing => 4,
    RunningCycleGuidePhase.support => 5,
    RunningCycleGuidePhase.pushOff => 2,
    RunningCycleGuidePhase.recovery => 3,
  };
}

@visibleForTesting
int runningCycleGuideRepresentativeFrameForPhase(
  RunningCycleGuidePhase phase,
) {
  return _representativeFrameForPhase(phase);
}

@visibleForTesting
Rect runningCycleGuideSourceRectForFrame(ui.Image atlas, int frame) {
  return _sourceRectForFrame(atlas, frame);
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

Rect _phaseBandFor(Rect content, RunningCycleGuidePhase phase) {
  final (start, end) = switch (phase) {
    RunningCycleGuidePhase.landing => (0.16, 0.40),
    RunningCycleGuidePhase.support => (0.31, 0.55),
    RunningCycleGuidePhase.pushOff => (0.47, 0.71),
    RunningCycleGuidePhase.recovery => (0.60, 0.86),
  };
  return Rect.fromLTRB(
    content.left + content.width * start,
    content.top + content.height * 0.12,
    content.left + content.width * end,
    content.bottom - content.height * 0.06,
  );
}

Paint _imagePaint() {
  return Paint()
    ..filterQuality = FilterQuality.high
    ..isAntiAlias = true;
}
