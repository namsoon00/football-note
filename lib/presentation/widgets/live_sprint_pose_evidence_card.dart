import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/running_coach_session.dart';
import '../../domain/entities/running_live_coaching_state.dart';
import '../../gen/app_localizations.dart';
import '../../realtime_analysis/running_coaching/running_visual_pose_tracker.dart';
import '../models/camera_viewport_transform.dart';
import '../painters/running_pose_anatomical_painter.dart';

class LiveSprintPoseEvidenceCard extends StatelessWidget {
  final LiveSprintSessionReport report;

  const LiveSprintPoseEvidenceCard({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final evidence = report.poseEvidence;
    final diagnostic = report.poseEvidenceDiagnostic;
    if (evidence.isEmpty) {
      return Card(
        key: const ValueKey('running-live-session-report-pose-evidence'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.runningCoachLiveSessionReportEvidenceUnavailable,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              _EvidenceCaptureSummary(
                evidence: evidence,
                diagnostic: diagnostic,
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: evidence.length,
      child: Card(
        key: const ValueKey('running-live-session-report-pose-evidence'),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.runningCoachLiveSessionReportEvidenceBody,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              _EvidenceCaptureSummary(
                evidence: evidence,
                diagnostic: diagnostic,
              ),
              if (evidence.length > 1) ...[
                const SizedBox(height: 12),
                TabBar(
                  tabs: [
                    for (final frame in evidence)
                      Tab(text: _phaseLabel(l10n, frame.phase)),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                height: 350,
                child: TabBarView(
                  physics: evidence.length == 1
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  children: [
                    for (final frame in evidence) _EvidencePage(frame: frame),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EvidencePage extends StatelessWidget {
  final LiveSprintPoseEvidenceFrame frame;

  const _EvidencePage({required this.frame});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _PoseEvidenceCanvas(frame: frame)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _EvidencePill(
              icon: _phaseIcon(frame.phase),
              label: _phaseLabel(l10n, frame.phase),
              foreground: scheme.primary,
            ),
            _EvidencePill(
              icon: Icons.verified_outlined,
              label: l10n.runningCoachConfidenceLabel(
                (frame.quality * 100).round(),
              ),
            ),
            _EvidencePill(
              icon: Icons.straighten_rounded,
              label: l10n.runningCoachLiveSessionReportEvidenceSideView(
                (frame.sideViewConfidence * 100).round(),
              ),
            ),
            if (frame.leadFoot != null)
              _EvidencePill(
                icon: Icons.directions_run_rounded,
                label: _leadFootLabel(l10n, frame.leadFoot!),
                foreground: scheme.primary,
              ),
          ],
        ),
      ],
    );
  }
}

class _EvidencePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? foreground;

  const _EvidencePill({
    required this.icon,
    required this.label,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = foreground ?? scheme.onSurfaceVariant;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidenceCaptureSummary extends StatelessWidget {
  final List<LiveSprintPoseEvidenceFrame> evidence;
  final LiveSprintPoseEvidenceDiagnostic diagnostic;

  const _EvidenceCaptureSummary({
    required this.evidence,
    required this.diagnostic,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final captured = evidence.map((frame) => frame.phase).toSet();
    final blocker = diagnostic.dominantBlocker;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _EvidencePill(
              icon: Icons.flag_outlined,
              label: l10n.runningCoachLiveSessionReportEvidenceCoverage(
                captured.length,
              ),
              foreground: scheme.primary,
            ),
            for (final phase in LiveSprintPoseEvidencePhase.values)
              _EvidencePill(
                icon: captured.contains(phase)
                    ? Icons.check_circle_outline_rounded
                    : Icons.radio_button_unchecked_rounded,
                label: captured.contains(phase)
                    ? l10n.runningCoachLiveSessionReportEvidencePhaseCaptured(
                        _phaseLabel(l10n, phase),
                      )
                    : l10n.runningCoachLiveSessionReportEvidencePhaseMissing(
                        _phaseLabel(l10n, phase),
                      ),
                foreground: captured.contains(phase)
                    ? scheme.primary
                    : scheme.onSurfaceVariant,
              ),
          ],
        ),
        if (blocker != null &&
            captured.length < LiveSprintPoseEvidencePhase.values.length) ...[
          const SizedBox(height: 10),
          Text(
            l10n.runningCoachLiveSessionReportEvidenceLimit(
              _poseEvidenceBlockerText(l10n, blocker),
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.3,
                ),
          ),
        ],
      ],
    );
  }
}

class _PoseEvidenceCanvas extends StatefulWidget {
  final LiveSprintPoseEvidenceFrame frame;

  const _PoseEvidenceCanvas({required this.frame});

  @override
  State<_PoseEvidenceCanvas> createState() => _PoseEvidenceCanvasState();
}

class _PoseEvidenceCanvasState extends State<_PoseEvidenceCanvas> {
  late final ValueNotifier<RunningVisualPoseFrame?> _visualFrame;

  @override
  void initState() {
    super.initState();
    _visualFrame = ValueNotifier<RunningVisualPoseFrame?>(
      _toVisualFrame(widget.frame),
    );
  }

  @override
  void didUpdateWidget(covariant _PoseEvidenceCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.frame, widget.frame)) {
      _visualFrame.value = _toVisualFrame(widget.frame);
    }
  }

  @override
  void dispose() {
    _visualFrame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: scheme.inverseSurface,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: RunningPoseAnatomicalPainter(
                frameListenable: _visualFrame,
                mirrorHorizontally: false,
                fit: BoxFit.contain,
              ),
            ),
            CustomPaint(
              painter: _PoseEvidenceGuidePainter(
                frame: widget.frame,
                guideColor: scheme.primary.withValues(alpha: 0.65),
                touchdownColor: scheme.error.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PoseEvidenceGuidePainter extends CustomPainter {
  final LiveSprintPoseEvidenceFrame frame;
  final Color guideColor;
  final Color touchdownColor;

  const _PoseEvidenceGuidePainter({
    required this.frame,
    required this.guideColor,
    required this.touchdownColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sourceSize = _sourceSize(frame);
    final transform = CameraViewportTransform.fit(
      sourceSize: sourceSize,
      viewportSize: size,
      fit: BoxFit.contain,
    );
    if (!transform.isValid) {
      return;
    }
    final leftHip = _project(
      transform,
      frame.joint(RunningPoseLandmarkType.leftHip),
      sourceSize,
    );
    final rightHip = _project(
      transform,
      frame.joint(RunningPoseLandmarkType.rightHip),
      sourceSize,
    );
    final leftFoot = _project(
      transform,
      frame.joint(RunningPoseLandmarkType.leftFootIndex) ??
          frame.joint(RunningPoseLandmarkType.leftAnkle),
      sourceSize,
    );
    final rightFoot = _project(
      transform,
      frame.joint(RunningPoseLandmarkType.rightFootIndex) ??
          frame.joint(RunningPoseLandmarkType.rightAnkle),
      sourceSize,
    );
    if (leftHip == null ||
        rightHip == null ||
        leftFoot == null ||
        rightFoot == null) {
      return;
    }

    final hipCenter = Offset(
      (leftHip.dx + rightHip.dx) / 2,
      (leftHip.dy + rightHip.dy) / 2,
    );
    final groundY = math.min(
      size.height - 12,
      math.max(leftFoot.dy, rightFoot.dy) + 12,
    );
    final linePaint = Paint()
      ..color = guideColor
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    _drawDashedLine(
      canvas,
      Offset(hipCenter.dx, hipCenter.dy),
      Offset(hipCenter.dx, groundY),
      linePaint,
    );
    canvas.drawLine(
        Offset(12, groundY), Offset(size.width - 12, groundY), linePaint);

    if (frame.phase == LiveSprintPoseEvidencePhase.touchdown) {
      final foot =
          frame.leadFoot == RunningFootSide.left ? leftFoot : rightFoot;
      final emphasis = Paint()
        ..color = touchdownColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4;
      canvas.drawCircle(foot, 10, emphasis);
      canvas.drawCircle(foot, 3.5, emphasis..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant _PoseEvidenceGuidePainter oldDelegate) {
    return oldDelegate.frame != frame ||
        oldDelegate.guideColor != guideColor ||
        oldDelegate.touchdownColor != touchdownColor;
  }
}

RunningVisualPoseFrame _toVisualFrame(LiveSprintPoseEvidenceFrame frame) {
  final imageSize = _sourceSize(frame);
  return RunningVisualPoseFrame(
    imageSize: imageSize,
    timestamp: DateTime.fromMillisecondsSinceEpoch(frame.capturedOffsetMs),
    observedAt: DateTime.fromMillisecondsSinceEpoch(frame.capturedOffsetMs),
    landmarks: <RunningPoseLandmarkType, RunningVisualPoseLandmark>{
      for (final joint in frame.joints)
        joint.type: RunningVisualPoseLandmark(
          position:
              Offset(joint.x * imageSize.width, joint.y * imageSize.height),
          confidence: joint.confidence,
          rawConfidence: joint.confidence,
          z: joint.z,
          worldZ: null,
          visibility: null,
          presence: null,
          state: joint.observed
              ? RunningVisualPoseLandmarkState.observed
              : RunningVisualPoseLandmarkState.inferred,
        ),
    },
  );
}

Size _sourceSize(LiveSprintPoseEvidenceFrame frame) {
  final aspectRatio = frame.imageAspectRatio.isFinite
      ? frame.imageAspectRatio.clamp(0.2, 4.0).toDouble()
      : 1.0;
  return Size(aspectRatio * 1000, 1000);
}

Offset? _project(
  CameraViewportTransform transform,
  LiveSprintPoseEvidenceJoint? joint,
  Size sourceSize,
) {
  if (joint == null) {
    return null;
  }
  return transform.project(
    Offset(joint.x * sourceSize.width, joint.y * sourceSize.height),
  );
}

void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
  const dashLength = 7.0;
  const gapLength = 5.0;
  final vector = to - from;
  final distance = vector.distance;
  if (distance <= 0) {
    return;
  }
  final direction = vector / distance;
  for (var offset = 0.0; offset < distance; offset += dashLength + gapLength) {
    final segmentEnd = math.min(offset + dashLength, distance);
    canvas.drawLine(
        from + (direction * offset), from + (direction * segmentEnd), paint);
  }
}

String _phaseLabel(
  AppLocalizations l10n,
  LiveSprintPoseEvidencePhase phase,
) {
  return switch (phase) {
    LiveSprintPoseEvidencePhase.touchdown =>
      l10n.runningCoachLiveSessionReportEvidenceTouchdown,
    LiveSprintPoseEvidencePhase.support =>
      l10n.runningCoachLiveSessionReportEvidenceSupport,
    LiveSprintPoseEvidencePhase.flight =>
      l10n.runningCoachLiveSessionReportEvidenceFlight,
  };
}

String _leadFootLabel(AppLocalizations l10n, RunningFootSide side) {
  return switch (side) {
    RunningFootSide.left => l10n.runningCoachLiveSessionReportEvidenceLeftLead,
    RunningFootSide.right =>
      l10n.runningCoachLiveSessionReportEvidenceRightLead,
  };
}

String _poseEvidenceBlockerText(
  AppLocalizations l10n,
  LiveSprintPoseEvidenceBlocker blocker,
) {
  return switch (blocker) {
    LiveSprintPoseEvidenceBlocker.fullBodyVisibility =>
      l10n.runningCoachPoseEvidenceBlockerFullBody,
    LiveSprintPoseEvidenceBlocker.stableSideView =>
      l10n.runningCoachPoseEvidenceBlockerSideView,
    LiveSprintPoseEvidenceBlocker.observedCoreJoints =>
      l10n.runningCoachPoseEvidenceBlockerCoreJoints,
    LiveSprintPoseEvidenceBlocker.gaitPhaseReadiness =>
      l10n.runningCoachPoseEvidenceBlockerGaitPhase,
  };
}

IconData _phaseIcon(LiveSprintPoseEvidencePhase phase) {
  return switch (phase) {
    LiveSprintPoseEvidencePhase.touchdown => Icons.south_rounded,
    LiveSprintPoseEvidencePhase.support => Icons.accessibility_new_rounded,
    LiveSprintPoseEvidencePhase.flight => Icons.flight_takeoff_rounded,
  };
}
