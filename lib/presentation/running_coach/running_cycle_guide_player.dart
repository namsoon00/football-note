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
const _normalSequenceDuration = Duration(milliseconds: 1280);
const _slowSequenceDuration = Duration(milliseconds: 2560);
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
  final Duration sequenceDuration;

  const RunningCycleGuidePlayer({
    super.key,
    this.sequenceDuration = _normalSequenceDuration,
  });

  @override
  State<RunningCycleGuidePlayer> createState() =>
      _RunningCycleGuidePlayerState();
}

class _RunningCycleGuidePlayerState extends State<RunningCycleGuidePlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _didApplyInitialMotionPreference = false;
  bool _isPlaying = false;
  bool _isSlow = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.sequenceDuration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!_didApplyInitialMotionPreference) {
      _didApplyInitialMotionPreference = true;
      if (!reduceMotion) {
        _startController();
        _isPlaying = true;
      }
    } else if (reduceMotion && _isPlaying) {
      _controller.stop();
      _isPlaying = false;
    }
  }

  @override
  void didUpdateWidget(covariant RunningCycleGuidePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sequenceDuration != widget.sequenceDuration && !_isSlow) {
      _controller.duration = widget.sequenceDuration;
      if (_isPlaying) {
        _play();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Duration get _activeDuration =>
      _isSlow ? _slowSequenceDuration : widget.sequenceDuration;

  int get _activeFrame => _frameForProgress(_controller.value);

  RunningCycleGuidePhase get _activePhase => _phaseForFrame(_activeFrame);

  void _startController() {
    final progress = _normalizedProgress(_controller.value);
    _controller
      ..stop()
      ..duration = _activeDuration
      ..value = progress
      ..repeat();
  }

  void _play() {
    _startController();
    if (!_isPlaying) {
      setState(() => _isPlaying = true);
    }
  }

  void _pause() {
    _controller.stop();
    if (_isPlaying) {
      setState(() => _isPlaying = false);
    }
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  void _toggleSlowView() {
    setState(() => _isSlow = !_isSlow);
    if (_isPlaying) {
      _play();
    }
  }

  void _stepPhase() {
    const phases = RunningCycleGuidePhase.values;
    final nextIndex = (_activePhase.index + 1) % phases.length;
    _selectPhase(phases[nextIndex]);
  }

  void _selectPhase(RunningCycleGuidePhase phase) {
    _controller
      ..stop()
      ..value = _startFrameForPhase(phase) / _frameCount;
    setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final phaseCopies = _phaseCopies(l10n);

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
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final frame = _activeFrame;
                    final activePhase = _phaseForFrame(frame);
                    final copy = phaseCopies[activePhase.index];
                    return _RunningCycleFrameView(
                      atlas: atlas,
                      progress: _controller.value,
                      phase: activePhase,
                      phaseCopy: copy,
                      cellAspectRatio: cellAspectRatio,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final copy = phaseCopies[_activePhase.index];
                return _ActivePhasePanel(
                  key: ValueKey(
                    'running-coach-good-form-active-phase-${copy.phase.name}',
                  ),
                  copy: copy,
                );
              },
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final activePhase = _activePhase;
                return Wrap(
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
                        selected: activePhase == copy.phase,
                        onSelected: (_) => _selectPhase(copy.phase),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            Wrap(
              key: const ValueKey('running-coach-good-form-cycle-controls'),
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  key: const ValueKey(
                    'running-coach-good-form-cycle-play-pause',
                  ),
                  onPressed: _togglePlayback,
                  icon: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    _isPlaying
                        ? l10n.runningCoachArchivedVideoPause
                        : l10n.runningCoachArchivedVideoPlay,
                  ),
                ),
                OutlinedButton.icon(
                  key: const ValueKey(
                    'running-coach-good-form-cycle-slow-view',
                  ),
                  onPressed: _toggleSlowView,
                  icon: const Icon(Icons.slow_motion_video_rounded),
                  label: Text(l10n.runningCoachGoodFormSlowMotionAction),
                  style: _isSlow
                      ? OutlinedButton.styleFrom(
                          foregroundColor: scheme.onPrimaryContainer,
                          backgroundColor: scheme.primaryContainer,
                          side: BorderSide(color: scheme.primary),
                        )
                      : null,
                ),
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
  final double progress;
  final RunningCycleGuidePhase phase;
  final _RunningCyclePhaseCopy phaseCopy;
  final double cellAspectRatio;

  const _RunningCycleFrameView({
    required this.atlas,
    required this.progress,
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
                      progress: progress,
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
  final double progress;
  final double cellAspectRatio;

  const _RunningCycleAtlasPainter({
    required this.atlas,
    required this.progress,
    required this.cellAspectRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final destination = _contentRectFor(size, cellAspectRatio);
    final currentFrame = _frameForProgress(progress);

    canvas.drawImageRect(
      atlas,
      _sourceRectForFrame(atlas, currentFrame),
      destination,
      _imagePaint(),
    );
  }

  @override
  bool shouldRepaint(covariant _RunningCycleAtlasPainter oldDelegate) {
    return atlas != oldDelegate.atlas ||
        progress != oldDelegate.progress ||
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

RunningCycleGuidePhase _phaseForFrame(int frame) {
  return switch (
      _normalizedFrame(frame) % RunningCycleGuidePhase.values.length) {
    0 => RunningCycleGuidePhase.landing,
    1 => RunningCycleGuidePhase.support,
    2 => RunningCycleGuidePhase.pushOff,
    _ => RunningCycleGuidePhase.recovery,
  };
}

int _startFrameForPhase(RunningCycleGuidePhase phase) => phase.index;

@visibleForTesting
Duration get runningCycleGuideNormalSequenceDuration => _normalSequenceDuration;

@visibleForTesting
int runningCycleGuideFrameForProgress(double progress) {
  return _frameForProgress(progress);
}

@visibleForTesting
RunningCycleGuidePhase runningCycleGuidePhaseForFrame(int frame) {
  return _phaseForFrame(frame);
}

@visibleForTesting
int runningCycleGuideRepresentativeFrameForPhase(
  RunningCycleGuidePhase phase,
) {
  return _startFrameForPhase(phase);
}

@visibleForTesting
Rect runningCycleGuideSourceRectForFrame(ui.Image atlas, int frame) {
  return _sourceRectForFrame(atlas, frame);
}

int _frameForProgress(double progress) {
  final frame = (_normalizedProgress(progress) * _frameCount).floor();
  return _normalizedFrame(frame);
}

int _normalizedFrame(int frame) => frame % _frameCount;

double _normalizedProgress(double progress) {
  final normalized = progress % 1;
  return normalized < 0 ? normalized + 1 : normalized;
}

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
