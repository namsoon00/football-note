import 'dart:math' as math;
import 'dart:ui';

import '../../domain/entities/running_video_analysis_result.dart';

const double runningPoseOverlayMinimumJointConfidence = 0.18;
const double runningPoseOverlayMinimumConnectionConfidence = 0.24;

RunningPoseFrame? runningPoseFrameAtPosition({
  required List<RunningPoseFrame> frames,
  required Duration position,
}) {
  final sortedFrames = frames
      .where((frame) => frame.landmarks.length == mediaPipePoseLandmarkCount)
      .toList(growable: false)
    ..sort((a, b) => a.timestampMs.compareTo(b.timestampMs));
  if (sortedFrames.isEmpty) return null;

  final targetMs = position.inMilliseconds;
  if (sortedFrames.length == 1) {
    return sortedFrames.first;
  }

  final medianIntervalMs = _medianIntervalMs(sortedFrames);
  final halfIntervalMs = math.max(1, (medianIntervalMs / 2).round());
  final bracket = _bracketFrames(sortedFrames, targetMs, halfIntervalMs);
  if (bracket == null) return null;

  final baseFrame = _interpolateFrame(bracket.$1, bracket.$2, targetMs);
  return _smoothFrame(
    baseFrame,
    sortedFrames,
    targetMs,
    smoothingWindowMs: medianIntervalMs,
  );
}

Offset runningPoseCoverOffset({
  required RunningVideoPoseLandmark landmark,
  required int imageWidth,
  required int imageHeight,
  required Size outputSize,
}) {
  if (imageWidth <= 0 || imageHeight <= 0 || outputSize.isEmpty) {
    return Offset.zero;
  }
  final scale = math.max(
    outputSize.width / imageWidth,
    outputSize.height / imageHeight,
  );
  final displayWidth = imageWidth * scale;
  final displayHeight = imageHeight * scale;
  final dx = (outputSize.width - displayWidth) / 2;
  final dy = (outputSize.height - displayHeight) / 2;
  return Offset(
    dx + (landmark.x * imageWidth * scale),
    dy + (landmark.y * imageHeight * scale),
  );
}

int? nearestRunningPoseFrameIndex({
  required List<RunningPoseFrame> frames,
  required Duration position,
}) {
  if (frames.isEmpty) return null;
  final targetMs = position.inMilliseconds;
  var bestIndex = 0;
  var bestDistance = (frames.first.timestampMs - targetMs).abs();
  for (var index = 1; index < frames.length; index += 1) {
    final distance = (frames[index].timestampMs - targetMs).abs();
    if (distance < bestDistance) {
      bestDistance = distance;
      bestIndex = index;
    }
  }
  return bestIndex;
}

(RunningPoseFrame, RunningPoseFrame)? _bracketFrames(
  List<RunningPoseFrame> frames,
  int targetMs,
  int halfIntervalMs,
) {
  final first = frames.first;
  if (targetMs <= first.timestampMs) {
    return (first.timestampMs - targetMs).abs() <= halfIntervalMs
        ? (first, first)
        : null;
  }

  final last = frames.last;
  if (targetMs >= last.timestampMs) {
    return (targetMs - last.timestampMs).abs() <= halfIntervalMs
        ? (last, last)
        : null;
  }

  for (var index = 0; index < frames.length - 1; index += 1) {
    final current = frames[index];
    final next = frames[index + 1];
    if (targetMs >= current.timestampMs && targetMs <= next.timestampMs) {
      return (current, next);
    }
  }
  return null;
}

RunningPoseFrame _interpolateFrame(
  RunningPoseFrame first,
  RunningPoseFrame second,
  int targetMs,
) {
  if (first.timestampMs == second.timestampMs) return first;
  final t = ((targetMs - first.timestampMs) /
          (second.timestampMs - first.timestampMs))
      .clamp(0.0, 1.0)
      .toDouble();
  final landmarks = <RunningVideoPoseLandmark>[];
  for (var index = 0; index < mediaPipePoseLandmarkCount; index += 1) {
    final a = first.landmarkByIndex(index);
    final b = second.landmarkByIndex(index);
    if (a == null || b == null) {
      return first;
    }
    landmarks.add(_lerpLandmark(a, b, t));
  }
  return RunningPoseFrame(
    timestamp: Duration(milliseconds: targetMs),
    imageWidth: first.imageWidth,
    imageHeight: first.imageHeight,
    landmarks: List<RunningVideoPoseLandmark>.unmodifiable(landmarks),
  );
}

RunningPoseFrame _smoothFrame(
  RunningPoseFrame baseFrame,
  List<RunningPoseFrame> sourceFrames,
  int targetMs, {
  required int smoothingWindowMs,
}) {
  final windowMs = math.max(1, smoothingWindowMs);
  final nearby = sourceFrames
      .where((frame) => (frame.timestampMs - targetMs).abs() <= windowMs)
      .toList(growable: false);
  if (nearby.isEmpty) return baseFrame;

  final smoothed = <RunningVideoPoseLandmark>[];
  for (var index = 0; index < mediaPipePoseLandmarkCount; index += 1) {
    final base = baseFrame.landmarkByIndex(index);
    if (base == null) return baseFrame;

    var totalWeight = 1.0 + base.confidence;
    var x = base.x * totalWeight;
    var y = base.y * totalWeight;
    var z = base.z * totalWeight;
    var visibility = (base.visibility ?? 0) * totalWeight;
    var visibilityWeight = base.visibility == null ? 0.0 : totalWeight;
    var presence = (base.presence ?? 0) * totalWeight;
    var presenceWeight = base.presence == null ? 0.0 : totalWeight;
    var confidence = base.confidence * totalWeight;

    for (final frame in nearby) {
      final landmark = frame.landmarkByIndex(index);
      if (landmark == null) continue;
      final distanceRatio = ((frame.timestampMs - targetMs).abs() / windowMs)
          .clamp(0.0, 1.0)
          .toDouble();
      final temporalWeight = 1.0 - distanceRatio;
      if (temporalWeight <= 0) continue;
      final confidenceWeight = landmark.confidence.clamp(0.05, 1.0).toDouble();
      final weight = 0.45 * temporalWeight * confidenceWeight;
      totalWeight += weight;
      x += landmark.x * weight;
      y += landmark.y * weight;
      z += landmark.z * weight;
      confidence += landmark.confidence * weight;
      if (landmark.visibility != null) {
        visibility += landmark.visibility! * weight;
        visibilityWeight += weight;
      }
      if (landmark.presence != null) {
        presence += landmark.presence! * weight;
        presenceWeight += weight;
      }
    }

    smoothed.add(
      RunningVideoPoseLandmark(
        index: index,
        x: x / totalWeight,
        y: y / totalWeight,
        z: z / totalWeight,
        visibility:
            visibilityWeight <= 0 ? null : visibility / visibilityWeight,
        presence: presenceWeight <= 0 ? null : presence / presenceWeight,
        confidence: (confidence / totalWeight).clamp(0.0, 1.0).toDouble(),
      ),
    );
  }

  return RunningPoseFrame(
    timestamp: baseFrame.timestamp,
    imageWidth: baseFrame.imageWidth,
    imageHeight: baseFrame.imageHeight,
    landmarks: List<RunningVideoPoseLandmark>.unmodifiable(smoothed),
  );
}

RunningVideoPoseLandmark _lerpLandmark(
  RunningVideoPoseLandmark first,
  RunningVideoPoseLandmark second,
  double t,
) {
  return RunningVideoPoseLandmark(
    index: first.index,
    x: _lerpDouble(first.x, second.x, t),
    y: _lerpDouble(first.y, second.y, t),
    z: _lerpDouble(first.z, second.z, t),
    visibility: _lerpNullable(first.visibility, second.visibility, t),
    presence: _lerpNullable(first.presence, second.presence, t),
    confidence: _lerpDouble(first.confidence, second.confidence, t)
        .clamp(0.0, 1.0)
        .toDouble(),
  );
}

int _medianIntervalMs(List<RunningPoseFrame> frames) {
  final intervals = <int>[];
  for (var index = 0; index < frames.length - 1; index += 1) {
    final interval = frames[index + 1].timestampMs - frames[index].timestampMs;
    if (interval > 0) {
      intervals.add(interval);
    }
  }
  if (intervals.isEmpty) return 1;
  intervals.sort();
  return intervals[intervals.length ~/ 2];
}

double _lerpDouble(double a, double b, double t) => a + ((b - a) * t);

double? _lerpNullable(double? a, double? b, double t) {
  if (a == null && b == null) return null;
  if (a == null) return b;
  if (b == null) return a;
  return _lerpDouble(a, b, t);
}
