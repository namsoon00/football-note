import 'dart:math' as math;

import 'real_match_replay.dart';

enum RealMatchReplayDetailPoseFidelity { recorded, simplified }

/// A short, source-only inspection window for a recorded football action.
///
/// Eligibility, bounds and the fixed camera use only the focal player's
/// observed source positions and the recorded ball. Display reconstruction is
/// deliberately excluded so it can never become evidence for a touch, turn,
/// pass target or technique.
class RealMatchReplayActionDetail {
  static const double playbackRate = .65;
  static const double maximumDuration = 3.5;

  final RealMatchReplayStep step;
  final int actorIndex;
  final double start;
  final double end;
  final RealMatchReplayCamera camera;
  final RealMatchReplayDetailPoseFidelity poseFidelity;
  final bool ballHeightAvailable;

  const RealMatchReplayActionDetail._({
    required this.step,
    required this.actorIndex,
    required this.start,
    required this.end,
    required this.camera,
    required this.poseFidelity,
    required this.ballHeightAvailable,
  });

  double get duration => end - start;

  bool get hasRecordedPose =>
      poseFidelity == RealMatchReplayDetailPoseFidelity.recorded;

  double sourceTimeAt(double progress) =>
      start + duration * progress.clamp(0.0, 1.0);

  double sourceTimeAfter(Duration playbackElapsed) => sourceTimeAt(
        playbackElapsed.inMicroseconds /
            Duration.microsecondsPerSecond *
            playbackRate /
            duration,
      );

  bool contains(RealMatchReplayPoint point, {bool includeHeight = false}) {
    final lift = includeHeight ? point.z.abs() * .85 : 0.0;
    return point.x - lift >= camera.minX - 1e-9 &&
        point.x + lift <= camera.maxX + 1e-9 &&
        point.y - lift >= camera.minY - 1e-9 &&
        point.y + lift <= camera.maxY + 1e-9;
  }

  static RealMatchReplayActionDetail? forStep(
    RealMatchReplayData data,
    RealMatchReplayStep step,
  ) {
    if (step.kind != RealMatchReplayStepKind.receive &&
        step.kind != RealMatchReplayStepKind.pass &&
        step.kind != RealMatchReplayStepKind.carry) {
      return null;
    }
    final stepIndex = data.scene.steps.indexOf(step);
    if (stepIndex < 0) return null;
    final actorIndex = data.playerIndex(step.actorId);
    final sourceFrame = (step.time * data.fps).clamp(
      0.0,
      data.frames.length - 1.0,
    );
    final anchorLower = sourceFrame.floor();
    final anchorUpper = sourceFrame.ceil();
    if (!data.isVisibleAtFrame(anchorLower, actorIndex) ||
        !data.isVisibleAtFrame(anchorUpper, actorIndex)) {
      return null;
    }

    var firstObserved = anchorLower;
    while (firstObserved > 0 &&
        data.isVisibleAtFrame(firstObserved - 1, actorIndex)) {
      firstObserved--;
    }
    var lastObserved = anchorUpper;
    while (lastObserved + 1 < data.frames.length &&
        data.isVisibleAtFrame(lastObserved + 1, actorIndex)) {
      lastObserved++;
    }

    final nextActionTime = stepIndex + 1 < data.scene.steps.length
        ? data.scene.steps[stepIndex + 1].time
        : data.duration;
    final desiredStart = math.max(0.0, step.time - .5);
    final desiredEnd = switch (step.kind) {
      RealMatchReplayStepKind.carry => math.min(
          step.end ?? nextActionTime,
          desiredStart + maximumDuration,
        ),
      RealMatchReplayStepKind.receive ||
      RealMatchReplayStepKind.pass =>
        math.min(step.time + 1.2, nextActionTime),
      _ => step.time,
    };
    final start = math.max(desiredStart, firstObserved / data.fps);
    final end = math.min(
      math.min(desiredEnd, data.duration),
      lastObserved / data.fps,
    );
    // A few observed frames on both sides (where source bounds allow) are
    // needed for a useful replay. A single point is not action evidence.
    if (end - start < math.min(.24, data.duration) ||
        step.time < start - 1e-9 ||
        step.time > end + 1e-9) {
      return null;
    }

    final points = <RealMatchReplayPoint>[];
    void addAt(double time) {
      final sample = data.sample(time);
      final actor = sample.players[actorIndex];
      if (actor != null) points.add(actor);
      points.add(sample.ball);
    }

    addAt(start);
    final firstFrame = (start * data.fps).ceil();
    final finalFrame = (end * data.fps).floor();
    for (var frame = firstFrame; frame <= finalFrame; frame++) {
      addAt(frame / data.fps);
    }
    addAt(end);
    final camera = _cameraFor(
      data,
      points,
      includeBallHeight: data.ballHeightAvailable,
    );
    var recordedPoseThroughout = data.hasRecordedPoseFor(step.actorId);
    if (recordedPoseThroughout) {
      for (var time = start; time < end; time += 1 / data.fps) {
        if (data.poseAt(time, actorIndex) == null) {
          recordedPoseThroughout = false;
          break;
        }
      }
      recordedPoseThroughout =
          recordedPoseThroughout && data.poseAt(end, actorIndex) != null;
    }
    return RealMatchReplayActionDetail._(
      step: step,
      actorIndex: actorIndex,
      start: start,
      end: end,
      camera: camera,
      poseFidelity: recordedPoseThroughout
          ? RealMatchReplayDetailPoseFidelity.recorded
          : RealMatchReplayDetailPoseFidelity.simplified,
      ballHeightAvailable: data.ballHeightAvailable,
    );
  }

  static RealMatchReplayCamera _cameraFor(
    RealMatchReplayData data,
    List<RealMatchReplayPoint> points, {
    required bool includeBallHeight,
  }) {
    var minX = points.first.x;
    var maxX = points.first.x;
    var minY = points.first.y;
    var maxY = points.first.y;
    for (final point in points) {
      final lift = includeBallHeight ? point.z.abs() * .85 : 0.0;
      minX = math.min(minX, point.x - lift);
      maxX = math.max(maxX, point.x + lift);
      minY = math.min(minY, point.y - lift);
      maxY = math.max(maxY, point.y + lift);
    }
    const horizontalPadding = 2.2;
    const verticalPadding = 1.8;
    final width = math.max(12.0, maxX - minX + horizontalPadding * 2);
    final height = math.max(9.0, maxY - minY + verticalPadding * 2);
    final worldMinX = math.min(-data.pitchLength / 2 - 3, minX);
    final worldMaxX = math.max(data.pitchLength / 2 + 3, maxX);
    final worldMinY = math.min(-data.pitchWidth / 2 - 2, minY);
    final worldMaxY = math.max(data.pitchWidth / 2 + 2, maxY);
    final fittedWidth = math.min(width, worldMaxX - worldMinX);
    final fittedHeight = math.min(height, worldMaxY - worldMinY);
    final centerX = ((minX + maxX) / 2).clamp(
      worldMinX + fittedWidth / 2,
      worldMaxX - fittedWidth / 2,
    );
    final centerY = ((minY + maxY) / 2).clamp(
      worldMinY + fittedHeight / 2,
      worldMaxY - fittedHeight / 2,
    );
    return RealMatchReplayCamera(
      minX: centerX - fittedWidth / 2,
      maxX: centerX + fittedWidth / 2,
      minY: centerY - fittedHeight / 2,
      maxY: centerY + fittedHeight / 2,
    );
  }
}
