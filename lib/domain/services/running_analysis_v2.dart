import 'dart:math' as math;

import '../entities/running_video_analysis_result.dart';

class RunningWeightedValue {
  final double value;
  final double confidence;
  final Duration timestamp;

  const RunningWeightedValue({
    required this.value,
    required this.confidence,
    required this.timestamp,
  });
}

class RunningWeightedEstimate {
  final double value;
  final RunningExpectedRange range;
  final double confidence;
  final int sampleCount;

  const RunningWeightedEstimate({
    required this.value,
    required this.range,
    required this.confidence,
    required this.sampleCount,
  });
}

class RunningFallbackContact {
  final Duration timestamp;
  final RunningContactSide side;
  final double confidence;
  final bool isConfirmed;

  const RunningFallbackContact({
    required this.timestamp,
    required this.side,
    required this.confidence,
    required this.isConfirmed,
  });
}

class RunningTrajectoryRhythmEstimate {
  final double cadenceSpm;
  final double stepTimeMs;
  final double? leftRightAsymmetryPercent;
  final double confidence;
  final int sampleCount;
  final List<Duration> evidenceTimestamps;

  const RunningTrajectoryRhythmEstimate({
    required this.cadenceSpm,
    required this.stepTimeMs,
    required this.leftRightAsymmetryPercent,
    required this.confidence,
    required this.sampleCount,
    required this.evidenceTimestamps,
  });
}

/// Deterministic trajectory-only rhythm fallback. Local ankle extrema are
/// treated as cycle observations, never as validated ground contacts.
RunningTrajectoryRhythmEstimate? runningTrajectoryRhythmEstimate(
  List<RunningPoseFrame> source,
) {
  final frames = runningStabilizedPoseFrames(source);
  final extrema =
      <({Duration timestamp, RunningContactSide side, double confidence})>[];
  for (final side in const <RunningContactSide>[
    RunningContactSide.left,
    RunningContactSide.right,
  ]) {
    final samples =
        <({RunningPoseFrame frame, double value, double confidence})>[];
    for (final frame in frames) {
      final ankle = _point(
        frame,
        side == RunningContactSide.left ? 27 : 28,
      );
      final knee = _point(
        frame,
        side == RunningContactSide.left ? 25 : 26,
      );
      final hip = _point(
        frame,
        side == RunningContactSide.left ? 23 : 24,
      );
      final shoulder = _point(
        frame,
        side == RunningContactSide.left ? 11 : 12,
      );
      if (ankle == null || knee == null || hip == null || shoulder == null) {
        continue;
      }
      final scale = _distance(shoulder, hip);
      if (!scale.isFinite || scale <= 0.01) continue;
      samples.add((
        frame: frame,
        value: (ankle.y - hip.y) / scale,
        confidence: math.min(
          ankle.confidence,
          math.min(knee.confidence, hip.confidence),
        ),
      ));
    }
    Duration? lastTimestamp;
    for (var index = 1; index < samples.length - 1; index += 1) {
      final previous = samples[index - 1];
      final current = samples[index];
      final next = samples[index + 1];
      if (current.frame.timestampMs - previous.frame.timestampMs > 350 ||
          next.frame.timestampMs - current.frame.timestampMs > 350) {
        continue;
      }
      final prominence = current.value - math.max(previous.value, next.value);
      if (prominence < 0.012) continue;
      if (lastTimestamp != null &&
          current.frame.timestamp - lastTimestamp <
              const Duration(milliseconds: 260)) {
        continue;
      }
      lastTimestamp = current.frame.timestamp;
      extrema.add((
        timestamp: current.frame.timestamp,
        side: side,
        confidence:
            (current.confidence * (0.42 + math.min(0.16, prominence * 0.8)))
                .clamp(0.0, 0.58)
                .toDouble(),
      ));
    }
  }
  extrema.sort((left, right) => left.timestamp.compareTo(right.timestamp));
  final deduplicated =
      <({Duration timestamp, RunningContactSide side, double confidence})>[];
  for (final item in extrema) {
    if (deduplicated.isNotEmpty &&
        item.timestamp - deduplicated.last.timestamp <
            const Duration(milliseconds: 110)) {
      if (item.confidence > deduplicated.last.confidence) {
        deduplicated[deduplicated.length - 1] = item;
      }
      continue;
    }
    deduplicated.add(item);
  }
  final intervals = <double>[];
  final bySide = <RunningContactSide, List<double>>{
    RunningContactSide.left: <double>[],
    RunningContactSide.right: <double>[],
  };
  for (var index = 0; index < deduplicated.length - 1; index += 1) {
    final current = deduplicated[index];
    final next = deduplicated[index + 1];
    if (current.side == next.side) continue;
    final interval =
        (next.timestamp - current.timestamp).inMilliseconds.toDouble();
    if (interval < 120 || interval > 650) continue;
    intervals.add(interval);
    bySide[current.side]!.add(interval);
  }
  if (intervals.length < 2) return null;
  intervals.sort();
  final stepTime = _median(intervals);
  final left = bySide[RunningContactSide.left]!;
  final right = bySide[RunningContactSide.right]!;
  double? asymmetry;
  if (left.isNotEmpty && right.isNotEmpty) {
    left.sort();
    right.sort();
    final leftMedian = _median(left);
    final rightMedian = _median(right);
    asymmetry = (leftMedian - rightMedian).abs() /
        math.max(1, (leftMedian + rightMedian) / 2) *
        100;
  }
  final confidence = deduplicated.isEmpty
      ? 0.0
      : deduplicated.fold<double>(
            0,
            (total, item) => total + item.confidence,
          ) /
          deduplicated.length;
  return RunningTrajectoryRhythmEstimate(
    cadenceSpm: 60000 / stepTime,
    stepTimeMs: stepTime,
    leftRightAsymmetryPercent: asymmetry,
    confidence: math.min(0.58, confidence),
    sampleCount: intervals.length,
    evidenceTimestamps: List<Duration>.unmodifiable(
      deduplicated.take(4).map((item) => item.timestamp),
    ),
  );
}

RunningWeightedEstimate? runningWeightedEstimate(
  Iterable<RunningWeightedValue> source,
) {
  final values = source
      .where((item) => item.value.isFinite && item.confidence.isFinite)
      .map(
        (item) => RunningWeightedValue(
          value: item.value,
          confidence: item.confidence.clamp(0.01, 1.0).toDouble(),
          timestamp: item.timestamp,
        ),
      )
      .toList(growable: false)
    ..sort((left, right) {
      final valueOrder = left.value.compareTo(right.value);
      return valueOrder != 0
          ? valueOrder
          : left.timestamp.compareTo(right.timestamp);
    });
  if (values.isEmpty) return null;
  final totalWeight = values.fold<double>(
    0,
    (total, item) => total + item.confidence,
  );
  double quantile(double fraction) {
    final target = totalWeight * fraction;
    var accumulated = 0.0;
    for (final item in values) {
      accumulated += item.confidence;
      if (accumulated >= target) return item.value;
    }
    return values.last.value;
  }

  final median = quantile(0.5);
  var lower = quantile(values.length < 3 ? 0.0 : 0.1);
  var upper = quantile(values.length < 3 ? 1.0 : 0.9);
  if ((upper - lower).abs() < 0.000001 && values.length == 1) {
    final uncertainty =
        math.max(median.abs() * 0.06, 0.01) * (1.1 - values.first.confidence);
    lower = median - uncertainty;
    upper = median + uncertainty;
  }
  final confidence = values.fold<double>(
        0,
        (total, item) => total + item.confidence,
      ) /
      values.length;
  return RunningWeightedEstimate(
    value: median,
    range: RunningExpectedRange(lower: lower, upper: upper),
    confidence: confidence.clamp(0.0, 1.0).toDouble(),
    sampleCount: values.length,
  );
}

/// Produces a deterministic single-runner pose timeline before metrics are
/// derived. A one-frame gap is interpolated with a confidence penalty, while a
/// point that jumps away from two mutually consistent neighbours is replaced
/// by the same penalized interpolation. Longer gaps remain missing.
List<RunningPoseFrame> runningStabilizedPoseFrames(
  List<RunningPoseFrame> source,
) {
  final frames = _orderedPoseFrames(source);
  if (frames.length < 3) return List<RunningPoseFrame>.unmodifiable(frames);
  final stabilized = <RunningPoseFrame>[frames.first];
  for (var frameIndex = 1; frameIndex < frames.length - 1; frameIndex += 1) {
    final previous = frames[frameIndex - 1];
    final current = frames[frameIndex];
    final next = frames[frameIndex + 1];
    final beforeGap = current.timestampMs - previous.timestampMs;
    final afterGap = next.timestampMs - current.timestampMs;
    if (beforeGap <= 0 || afterGap <= 0 || beforeGap > 350 || afterGap > 350) {
      stabilized.add(current);
      continue;
    }
    final scales = <double>[
      if (_bodyScale(previous) case final scale?) scale,
      if (_bodyScale(current) case final scale?) scale,
      if (_bodyScale(next) case final scale?) scale,
    ]..sort();
    if (scales.isEmpty) {
      stabilized.add(current);
      continue;
    }
    final scale = _median(scales);
    final landmarks = <int, RunningVideoPoseLandmark>{
      for (final landmark in current.landmarks) landmark.index: landmark,
    };
    var changed = false;
    if (_hasLikelyLeftRightSwap(previous, current, next, scale)) {
      for (final pair in const <(int, int)>[
        (11, 12),
        (13, 14),
        (15, 16),
        (23, 24),
        (25, 26),
        (27, 28),
        (29, 30),
        (31, 32),
      ]) {
        final left = landmarks[pair.$1];
        final right = landmarks[pair.$2];
        if (left == null || right == null) continue;
        landmarks[pair.$1] = _copyLandmark(
          right,
          index: pair.$1,
          confidencePenalty: 0.58,
        );
        landmarks[pair.$2] = _copyLandmark(
          left,
          index: pair.$2,
          confidencePenalty: 0.58,
        );
        changed = true;
      }
    }
    for (var index = 0; index < mediaPipePoseLandmarkCount; index += 1) {
      final before = previous.landmarkByIndex(index);
      final observed = landmarks[index];
      final after = next.landmarkByIndex(index);
      if (!_usableLandmark(before) || !_usableLandmark(after)) continue;
      final neighbourDistance = _landmarkDistance(before!, after!);
      if (neighbourDistance > scale * 0.42) continue;
      final isMissing = !_usableLandmark(observed);
      final isSpike = !isMissing &&
          _landmarkDistance(observed!, before) > scale * 0.55 &&
          _landmarkDistance(observed, after) > scale * 0.55;
      if (!isMissing && !isSpike) continue;
      final fraction = beforeGap / (beforeGap + afterGap);
      landmarks[index] = _interpolateLandmark(
        before,
        after,
        fraction,
        confidencePenalty: isSpike ? 0.45 : 0.62,
      );
      changed = true;
    }
    stabilized.add(
      changed
          ? RunningPoseFrame(
              timestamp: current.timestamp,
              imageWidth: current.imageWidth,
              imageHeight: current.imageHeight,
              landmarks: (landmarks.values.toList()
                    ..sort((left, right) => left.index.compareTo(right.index)))
                  .toList(growable: false),
            )
          : current,
    );
  }
  stabilized.add(frames.last);
  return List<RunningPoseFrame>.unmodifiable(stabilized);
}

bool _hasLikelyLeftRightSwap(
  RunningPoseFrame previous,
  RunningPoseFrame current,
  RunningPoseFrame next,
  double scale,
) {
  var directCost = 0.0;
  var swappedCost = 0.0;
  var compared = 0;
  for (final pair in const <(int, int)>[
    (23, 24),
    (25, 26),
    (27, 28),
  ]) {
    final beforeLeft = previous.landmarkByIndex(pair.$1);
    final beforeRight = previous.landmarkByIndex(pair.$2);
    final observedLeft = current.landmarkByIndex(pair.$1);
    final observedRight = current.landmarkByIndex(pair.$2);
    final afterLeft = next.landmarkByIndex(pair.$1);
    final afterRight = next.landmarkByIndex(pair.$2);
    if (!_usableLandmark(beforeLeft) ||
        !_usableLandmark(beforeRight) ||
        !_usableLandmark(observedLeft) ||
        !_usableLandmark(observedRight) ||
        !_usableLandmark(afterLeft) ||
        !_usableLandmark(afterRight)) {
      continue;
    }
    directCost += _landmarkDistance(observedLeft!, beforeLeft!) +
        _landmarkDistance(observedLeft, afterLeft!) +
        _landmarkDistance(observedRight!, beforeRight!) +
        _landmarkDistance(observedRight, afterRight!);
    swappedCost += _landmarkDistance(observedRight, beforeLeft) +
        _landmarkDistance(observedRight, afterLeft) +
        _landmarkDistance(observedLeft, beforeRight) +
        _landmarkDistance(observedLeft, afterRight);
    compared += 1;
  }
  return compared >= 2 && directCost - swappedCost > scale * 0.28 * compared;
}

/// Returns the local foot envelope around a candidate instead of relying on a
/// single ground line for the whole clip.
double? runningLocalGroundLevel(
  List<RunningPoseFrame> source, {
  required RunningContactSide side,
  required Duration around,
  Duration window = const Duration(milliseconds: 600),
}) {
  final values = <double>[];
  for (final frame in runningStabilizedPoseFrames(source)) {
    if ((frame.timestampMs - around.inMilliseconds).abs() >
        window.inMilliseconds) {
      continue;
    }
    final foot = _footBottom(frame, side);
    if (foot != null) values.add(foot.y);
  }
  if (values.isEmpty) return null;
  values.sort();
  return _quantile(values, 0.82);
}

List<RunningScaleSegment> runningScaleSegments(
  List<RunningPoseFrame> frames,
) {
  final samples = <_ScaleSample>[];
  for (final frame in runningStabilizedPoseFrames(frames)) {
    final scale = _bodyScale(frame);
    if (scale == null) continue;
    samples.add(
      _ScaleSample(
        timestamp: frame.timestamp,
        scale: scale,
        confidence: _frameConfidence(frame, const <int>[11, 12, 23, 24]),
      ),
    );
  }
  if (samples.isEmpty) return const <RunningScaleSegment>[];
  final smoothed = <_ScaleSample>[];
  for (var index = 0; index < samples.length; index += 1) {
    final start = math.max(0, index - 2);
    final end = math.min(samples.length, index + 3);
    final local = samples.sublist(start, end).map((item) => item.scale).toList()
      ..sort();
    smoothed.add(
      _ScaleSample(
        timestamp: samples[index].timestamp,
        scale: _median(local),
        confidence: samples[index].confidence,
      ),
    );
  }

  if (smoothed.length == 1) {
    final sample = smoothed.single;
    return <RunningScaleSegment>[
      RunningScaleSegment(
        start: sample.timestamp,
        end: sample.timestamp,
        trend: RunningScaleTrend.stable,
        medianScale: sample.scale,
        confidence: sample.confidence,
        sampleCount: 1,
      ),
    ];
  }
  final intervalTrends = <RunningScaleTrend>[];
  for (var index = 1; index < smoothed.length; index += 1) {
    final previous = smoothed[index - 1];
    final current = smoothed[index];
    final relativeChange = (current.scale - previous.scale) /
        math.max(previous.scale.abs(), 0.000001);
    intervalTrends.add(
      relativeChange.abs() < 0.018
          ? RunningScaleTrend.stable
          : relativeChange > 0
              ? RunningScaleTrend.approaching
              : RunningScaleTrend.receding,
    );
  }
  // Remove one-interval trend noise before splitting. Sustained transitions,
  // including stable <-> approaching/receding, remain explicit segments.
  final denoisedTrends = [...intervalTrends];
  for (var index = 1; index < intervalTrends.length - 1; index += 1) {
    if (intervalTrends[index - 1] == intervalTrends[index + 1] &&
        intervalTrends[index] != intervalTrends[index - 1]) {
      denoisedTrends[index] = intervalTrends[index - 1];
    }
  }
  final chunks = <List<_ScaleSample>>[];
  var chunkStart = 0;
  var currentTrend = denoisedTrends.first;
  for (var intervalIndex = 1;
      intervalIndex < denoisedTrends.length;
      intervalIndex += 1) {
    final gap = smoothed[intervalIndex + 1].timestamp.inMilliseconds -
        smoothed[intervalIndex].timestamp.inMilliseconds;
    final shouldSplit = gap > 700 ||
        intervalIndex - chunkStart >= 119 ||
        denoisedTrends[intervalIndex] != currentTrend;
    if (!shouldSplit) continue;
    chunks.add(smoothed.sublist(chunkStart, intervalIndex + 1));
    chunkStart = intervalIndex;
    currentTrend = denoisedTrends[intervalIndex];
  }
  chunks.add(smoothed.sublist(chunkStart));
  // Very short pieces are normally tracking noise. Merge them into the
  // adjacent segment instead of exposing a one-frame scale transition.
  for (var index = 0; index < chunks.length && chunks.length > 1;) {
    if (chunks[index].length >= 3) {
      index += 1;
      continue;
    }
    if (index == 0) {
      chunks[1] = <_ScaleSample>{...chunks[0], ...chunks[1]}.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      chunks.removeAt(0);
    } else {
      chunks[index - 1] = <_ScaleSample>{
        ...chunks[index - 1],
        ...chunks[index],
      }.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      chunks.removeAt(index);
      index -= 1;
    }
  }

  return List<RunningScaleSegment>.unmodifiable(
    chunks.map((chunk) {
      final scales = chunk.map((item) => item.scale).toList()..sort();
      final first = chunk.first.scale;
      final last = chunk.last.scale;
      final change = (last - first) / math.max(first.abs(), 0.000001);
      final trend = change.abs() <= 0.06
          ? RunningScaleTrend.stable
          : change > 0
              ? RunningScaleTrend.approaching
              : RunningScaleTrend.receding;
      final dispersion = (scales.last - scales.first) /
          math.max(_median(scales).abs(), 0.000001);
      final visibility = chunk.fold<double>(
            0,
            (total, item) => total + item.confidence,
          ) /
          chunk.length;
      return RunningScaleSegment(
        start: chunk.first.timestamp,
        end: chunk.last.timestamp,
        trend: trend,
        medianScale: _median(scales),
        confidence: (visibility * (1 - math.min(0.7, dispersion)))
            .clamp(0.0, 1.0)
            .toDouble(),
        sampleCount: chunk.length,
      );
    }),
  );
}

List<RunningFallbackContact> runningFallbackContacts(
  RunningVideoAnalysisResult result,
) {
  final platformContacts = _platformContacts(result);
  final confirmed = platformContacts
      .where((contact) => contact.isConfirmed)
      .toList(growable: false);
  if (confirmed.length >= runningCoachMinimumReliableMetricSamples) {
    return List<RunningFallbackContact>.unmodifiable(confirmed);
  }
  final frames = runningStabilizedPoseFrames(result.poseFrames);
  final candidates = <RunningFallbackContact>[];
  for (final side in const <RunningContactSide>[
    RunningContactSide.left,
    RunningContactSide.right,
  ]) {
    final samples = <_FootSample>[];
    for (final frame in frames) {
      final foot = _footBottom(frame, side);
      final hip = _point(frame, side == RunningContactSide.left ? 23 : 24);
      final knee = _point(frame, side == RunningContactSide.left ? 25 : 26);
      final ankle = _point(frame, side == RunningContactSide.left ? 27 : 28);
      final scale = _bodyScale(frame);
      if (foot == null ||
          hip == null ||
          knee == null ||
          ankle == null ||
          scale == null) {
        continue;
      }
      samples.add(
        _FootSample(
          frame: frame,
          x: foot.x,
          y: foot.y,
          hipX: hip.x,
          hipY: hip.y,
          scale: scale,
          confidence: math.min(
            foot.confidence,
            math.min(
                hip.confidence, math.min(knee.confidence, ankle.confidence)),
          ),
          kneeAngle: _jointAngle(hip, knee, ankle),
        ),
      );
    }
    if (samples.length < 3) continue;
    for (var index = 1; index < samples.length - 1; index += 1) {
      final previous = samples[index - 1];
      final current = samples[index];
      final next = samples[index + 1];
      final previousGap =
          current.frame.timestampMs - previous.frame.timestampMs;
      final nextGap = next.frame.timestampMs - current.frame.timestampMs;
      if (previousGap > 350 || nextGap > 350) continue;
      final tolerance = current.scale * 0.025;
      final isLocalBottom = current.y >= previous.y - tolerance &&
          current.y >= next.y - tolerance;
      if (!isLocalBottom) continue;
      if (current.confidence < 0.35) continue;
      final localMotion = math.max(
        (current.y - previous.y).abs(),
        (next.y - current.y).abs(),
      );
      if (localMotion < current.scale * 0.018) continue;
      final localGround = runningLocalGroundLevel(
            frames,
            side: side,
            around: current.frame.timestamp,
          ) ??
          current.y;
      final nearLocalGround = localGround - current.y <= current.scale * 0.13;
      if (!nearLocalGround) continue;
      final descendingBeforeContact =
          current.y - previous.y >= current.scale * 0.010;
      final verticalTurn = descendingBeforeContact &&
          (next.y - current.y) <= current.scale * 0.006;
      final relativeY = current.y - current.hipY;
      final previousRelativeY = previous.y - previous.hipY;
      final nextRelativeY = next.y - next.hipY;
      final relativeX = current.x - current.hipX;
      final previousRelativeX = previous.x - previous.hipX;
      final nextRelativeX = next.x - next.hipX;
      final relativeTurn =
          relativeY - previousRelativeY >= current.scale * 0.010 &&
              nextRelativeY - relativeY <= current.scale * 0.010;
      final footPelvisRelativeMotion = (relativeX - previousRelativeX).abs() +
              (nextRelativeX - relativeX).abs() >=
          current.scale * 0.010;
      final footBelowPelvis = relativeY >= current.scale * 0.45;
      final kneeFlexionBegins = next.kneeAngle <= current.kneeAngle + 4;
      final persistence = localGround - previous.y <= current.scale * 0.18 ||
          localGround - next.y <= current.scale * 0.18;
      final notRecoveryKnee = current.kneeAngle >= 105;
      final signalCount = <bool>[
        verticalTurn,
        relativeTurn,
        footPelvisRelativeMotion,
        footBelowPelvis,
        kneeFlexionBegins,
        persistence,
        notRecoveryKnee,
      ].where((value) => value).length;
      if (signalCount < 4) continue;
      candidates.add(
        RunningFallbackContact(
          timestamp: current.frame.timestamp,
          side: side,
          confidence: (current.confidence * (0.42 + signalCount * 0.07))
              .clamp(0.0, 0.62)
              .toDouble(),
          isConfirmed: false,
        ),
      );
    }
  }
  final merged = <RunningFallbackContact>[...platformContacts, ...candidates]
    ..sort((left, right) {
      final time = left.timestamp.compareTo(right.timestamp);
      if (time != 0) return time;
      return right.confidence.compareTo(left.confidence);
    });
  final deduplicated = <RunningFallbackContact>[];
  for (final candidate in merged) {
    final collision = deduplicated.indexWhere(
      (item) =>
          (item.timestamp.inMilliseconds - candidate.timestamp.inMilliseconds)
              .abs() <
          120,
    );
    if (collision < 0) {
      deduplicated.add(candidate);
    } else if (candidate.confidence > deduplicated[collision].confidence) {
      deduplicated[collision] = candidate;
    }
  }
  deduplicated.sort((left, right) => left.timestamp.compareTo(right.timestamp));
  return List<RunningFallbackContact>.unmodifiable(
    _enforceFallbackContactAlternation(deduplicated).take(12),
  );
}

List<RunningFallbackContact> _enforceFallbackContactAlternation(
  List<RunningFallbackContact> contacts,
) {
  final filtered = <RunningFallbackContact>[];
  for (final contact in contacts) {
    if (filtered.isEmpty ||
        contact.side == RunningContactSide.unknown ||
        filtered.last.side == RunningContactSide.unknown ||
        contact.isConfirmed ||
        filtered.last.isConfirmed ||
        contact.side != filtered.last.side ||
        contact.timestamp - filtered.last.timestamp >=
            const Duration(milliseconds: 420)) {
      filtered.add(contact);
      continue;
    }
    if (contact.confidence > filtered.last.confidence) {
      filtered[filtered.length - 1] = contact;
    }
  }
  return filtered;
}

RunningVideoAnalysisResult deriveRunningAnalysisV2(
  RunningVideoAnalysisResult source,
) {
  if (source.analysisVersion >= runningAnalysisVersionV2 &&
      source.measurements.isNotEmpty) {
    return source;
  }
  final frames = runningStabilizedPoseFrames(source.poseFrames);
  final segments = runningScaleSegments(frames);
  final analysisWindow = runningBestAnalysisWindow(frames, segments);
  final stableFrames = frames.where((frame) {
    if (analysisWindow == null) return true;
    return frame.timestamp >= analysisWindow.$1 &&
        frame.timestamp <= analysisWindow.$2;
  }).toList(growable: false);
  final preferredFrames = stableFrames.length >= 3 ? stableFrames : frames;
  final contacts = runningFallbackContacts(source);
  final preferredContacts = analysisWindow == null
      ? contacts
      : contacts
          .where(
            (contact) =>
                contact.timestamp >= analysisWindow.$1 &&
                contact.timestamp <= analysisWindow.$2,
          )
          .toList(growable: false);
  final metricContacts =
      preferredContacts.length >= 2 ? preferredContacts : contacts;
  final measurements = <RunningAnalysisMetric, RunningMetricMeasurement>{};

  void add(RunningMetricMeasurement measurement) {
    measurements[measurement.metric] = measurement;
  }

  add(_postureMeasurement(source, preferredFrames));
  add(_bounceMeasurement(source, preferredFrames));
  add(_armMeasurement(source, preferredFrames));
  add(_armSwingMeasurement(preferredFrames));
  add(_armAsymmetryMeasurement(preferredFrames));
  add(_contactMeasurement(
    source,
    frames,
    metricContacts,
    metric: RunningAnalysisMetric.footStrike,
  ));
  add(_contactMeasurement(
    source,
    frames,
    metricContacts,
    metric: RunningAnalysisMetric.kneeAtContact,
  ));
  add(_maximumKneeMeasurement(source, preferredFrames, metricContacts));
  add(_recoveryKneeMeasurement(source, preferredFrames, metricContacts));
  add(_rhythmMeasurement(
    source,
    metricContacts,
    preferredFrames,
    metric: RunningAnalysisMetric.cadence,
  ));
  add(_rhythmMeasurement(
    source,
    metricContacts,
    preferredFrames,
    metric: RunningAnalysisMetric.stepTime,
  ));
  add(_rhythmMeasurement(
    source,
    metricContacts,
    preferredFrames,
    metric: RunningAnalysisMetric.leftRightTiming,
  ));
  add(_footRollingMeasurement(preferredFrames, metricContacts));

  final qualities = Map<RunningCoachMetric, RunningMetricQuality>.from(
    source.metricQualities,
  );
  for (final entry in const <RunningCoachMetric, RunningAnalysisMetric>{
    RunningCoachMetric.posture: RunningAnalysisMetric.posture,
    RunningCoachMetric.bounce: RunningAnalysisMetric.bounce,
    RunningCoachMetric.footStrike: RunningAnalysisMetric.footStrike,
    RunningCoachMetric.kneeFlexion: RunningAnalysisMetric.kneeAtContact,
    RunningCoachMetric.armCarriage: RunningAnalysisMetric.elbowAngle,
  }.entries) {
    final measurement = measurements[entry.value]!;
    final existing = qualities[entry.key];
    qualities[entry.key] = switch (measurement.state) {
      RunningMeasurementState.unavailable => const RunningMetricQuality(
          confidence: 0,
          sampleCount: 0,
          reason: 'coordinates_unavailable',
        ),
      RunningMeasurementState.estimated => RunningMetricQuality(
          confidence: math.min(0.64, measurement.confidence),
          sampleCount: measurement.sampleCount,
          reason: measurement.method,
        ),
      RunningMeasurementState.confirmed => RunningMetricQuality(
          confidence: math
              .max(
                measurement.confidence,
                existing?.confidence ?? 0,
              )
              .clamp(0.0, 1.0)
              .toDouble(),
          sampleCount: math.max(
            measurement.sampleCount,
            existing?.sampleCount ?? 0,
          ),
          reason: existing?.reason == 'kinematic_contact_estimate'
              ? existing?.reason
              : null,
        ),
    };
  }

  double valueOr(
    RunningAnalysisMetric metric,
    double fallback, {
    double scale = 1,
  }) {
    final value = measurements[metric]?.value;
    return value == null || !value.isFinite ? fallback : value / scale;
  }

  return source.copyWith(
    analysisVersion: runningAnalysisVersionV2,
    forwardLeanDegrees: valueOr(
      RunningAnalysisMetric.posture,
      source.forwardLeanDegrees,
    ),
    verticalBounceRatio: valueOr(
      RunningAnalysisMetric.bounce,
      source.verticalBounceRatio,
      scale: 100,
    ),
    footStrikeDistanceRatio: valueOr(
      RunningAnalysisMetric.footStrike,
      source.footStrikeDistanceRatio,
    ),
    stanceKneeAngleDegrees: valueOr(
      RunningAnalysisMetric.kneeAtContact,
      source.stanceKneeAngleDegrees,
    ),
    elbowAngleDegrees: valueOr(
      RunningAnalysisMetric.elbowAngle,
      source.elbowAngleDegrees,
    ),
    metricQualities: Map<RunningCoachMetric, RunningMetricQuality>.unmodifiable(
      qualities,
    ),
    measurements:
        Map<RunningAnalysisMetric, RunningMetricMeasurement>.unmodifiable(
      measurements,
    ),
    scaleSegments: segments,
    analysisWindowStart: analysisWindow?.$1,
    analysisWindowEnd: analysisWindow?.$2,
  );
}

RunningMetricMeasurement _postureMeasurement(
  RunningVideoAnalysisResult result,
  List<RunningPoseFrame> frames,
) {
  final values = <RunningWeightedValue>[];
  for (final frame in frames) {
    final shoulder = _midpoint(_point(frame, 11), _point(frame, 12));
    final hip = _midpoint(_point(frame, 23), _point(frame, 24));
    if (shoulder == null || hip == null) continue;
    final radians = math.atan2(shoulder.x - hip.x, hip.y - shoulder.y);
    var degrees = radians * 180 / math.pi;
    if (result.direction == RunningDirection.rightToLeft) degrees = -degrees;
    values.add(RunningWeightedValue(
      value: degrees,
      confidence: math.min(shoulder.confidence, hip.confidence),
      timestamp: frame.timestamp,
    ));
  }
  return _measurementFromEstimate(
    metric: RunningAnalysisMetric.posture,
    estimate: runningWeightedEstimate(values),
    method: 'stable_segment_trunk_median',
    confirmed: _qualityConfirms(result, RunningCoachMetric.posture) &&
        values.length >= 5,
    timestamps: values.map((value) => value.timestamp),
  );
}

RunningMetricMeasurement _bounceMeasurement(
  RunningVideoAnalysisResult result,
  List<RunningPoseFrame> frames,
) {
  final raw = <({Duration timestamp, double position, double confidence})>[];
  for (final frame in frames) {
    final hip = _midpoint(_point(frame, 23), _point(frame, 24));
    final scale = _bodyScale(frame);
    if (hip == null || scale == null) continue;
    raw.add((
      timestamp: frame.timestamp,
      position: hip.y / scale,
      confidence: hip.confidence,
    ));
  }
  if (raw.length < 3) {
    return const RunningMetricMeasurement.unavailable(
      metric: RunningAnalysisMetric.bounce,
      method: 'scale_drift_corrected_trajectory',
      reason: 'coordinates_unavailable',
    );
  }
  final startMs = raw.first.timestamp.inMilliseconds.toDouble();
  final durationMs = math.max(
    1.0,
    raw.last.timestamp.inMilliseconds.toDouble() - startMs,
  );
  final first = raw.first.position;
  final drift = raw.last.position - first;
  final corrected = raw.map((item) {
    final fraction = (item.timestamp.inMilliseconds - startMs) / durationMs;
    return RunningWeightedValue(
      value: item.position - (first + drift * fraction),
      confidence: item.confidence,
      timestamp: item.timestamp,
    );
  }).toList(growable: false);
  final sorted = corrected.map((value) => value.value).toList()..sort();
  final bouncePercent =
      (_quantile(sorted, 0.90) - _quantile(sorted, 0.10)).abs() * 100;
  final spans = <RunningWeightedValue>[];
  const chunkSize = 8;
  for (var start = 0; start < corrected.length; start += chunkSize ~/ 2) {
    final end = math.min(corrected.length, start + chunkSize);
    if (end - start < 3) continue;
    final chunk = corrected.sublist(start, end);
    final chunkValues = chunk.map((value) => value.value).toList()..sort();
    spans.add(RunningWeightedValue(
      value: (_quantile(chunkValues, 0.9) - _quantile(chunkValues, 0.1)).abs() *
          100,
      confidence:
          chunk.fold<double>(0, (sum, value) => sum + value.confidence) /
              chunk.length,
      timestamp: chunk[chunk.length ~/ 2].timestamp,
    ));
  }
  final estimate = runningWeightedEstimate(spans) ??
      RunningWeightedEstimate(
        value: bouncePercent,
        range: RunningExpectedRange(
          lower: math.max(0, bouncePercent * 0.88),
          upper: bouncePercent * 1.12,
        ),
        confidence: corrected.fold<double>(
              0,
              (sum, value) => sum + value.confidence,
            ) /
            corrected.length,
        sampleCount: corrected.length,
      );
  return _measurementFromEstimate(
    metric: RunningAnalysisMetric.bounce,
    estimate: estimate,
    method: 'scale_drift_corrected_trajectory',
    confirmed: _qualityConfirms(result, RunningCoachMetric.bounce) &&
        corrected.length >= 5,
    timestamps: spans.map((value) => value.timestamp),
  );
}

RunningMetricMeasurement _armMeasurement(
  RunningVideoAnalysisResult result,
  List<RunningPoseFrame> frames,
) {
  final values = <RunningWeightedValue>[];
  for (final frame in frames) {
    final angles = <double>[];
    final confidences = <double>[];
    for (final indexes in const <List<int>>[
      <int>[11, 13, 15],
      <int>[12, 14, 16],
    ]) {
      final shoulder = _point(frame, indexes[0]);
      final elbow = _point(frame, indexes[1]);
      final wrist = _point(frame, indexes[2]);
      if (shoulder == null || elbow == null || wrist == null) continue;
      angles.add(_jointAngle(shoulder, elbow, wrist));
      confidences.add(math.min(
          shoulder.confidence, math.min(elbow.confidence, wrist.confidence)));
    }
    if (angles.isEmpty) continue;
    values.add(RunningWeightedValue(
      value: angles.reduce((sum, value) => sum + value) / angles.length,
      confidence:
          confidences.reduce((sum, value) => sum + value) / confidences.length,
      timestamp: frame.timestamp,
    ));
  }
  return _measurementFromEstimate(
    metric: RunningAnalysisMetric.elbowAngle,
    estimate: runningWeightedEstimate(values),
    method: 'bilateral_elbow_angle_median',
    confirmed: _qualityConfirms(result, RunningCoachMetric.armCarriage) &&
        values.length >= 5,
    timestamps: values.map((value) => value.timestamp),
  );
}

RunningMetricMeasurement _armSwingMeasurement(List<RunningPoseFrame> frames) {
  final values = <RunningWeightedValue>[];
  for (final side in const <List<int>>[
    <int>[11, 15],
    <int>[12, 16],
  ]) {
    final sideValues = <RunningWeightedValue>[];
    for (final frame in frames) {
      final shoulder = _point(frame, side[0]);
      final wrist = _point(frame, side[1]);
      final scale = _bodyScale(frame);
      if (shoulder == null || wrist == null || scale == null) continue;
      sideValues.add(RunningWeightedValue(
        value: (wrist.x - shoulder.x) / scale,
        confidence: math.min(shoulder.confidence, wrist.confidence),
        timestamp: frame.timestamp,
      ));
    }
    if (sideValues.length < 2) continue;
    final positions = sideValues.map((value) => value.value).toList()..sort();
    values.add(RunningWeightedValue(
      value: (_quantile(positions, 0.9) - _quantile(positions, 0.1)).abs(),
      confidence: sideValues.fold<double>(
            0,
            (sum, value) => sum + value.confidence,
          ) /
          sideValues.length,
      timestamp: sideValues[sideValues.length ~/ 2].timestamp,
    ));
  }
  return _measurementFromEstimate(
    metric: RunningAnalysisMetric.armSwingRange,
    estimate: runningWeightedEstimate(values),
    method: 'normalized_wrist_swing_range',
    confirmed: values.length == 2 && frames.length >= 5,
    timestamps: values.map((value) => value.timestamp),
  );
}

RunningMetricMeasurement _armAsymmetryMeasurement(
  List<RunningPoseFrame> frames,
) {
  final perSide = <double>[];
  var confidence = 0.0;
  for (final side in const <List<int>>[
    <int>[11, 15],
    <int>[12, 16],
  ]) {
    final values = <RunningWeightedValue>[];
    for (final frame in frames) {
      final shoulder = _point(frame, side[0]);
      final wrist = _point(frame, side[1]);
      final scale = _bodyScale(frame);
      if (shoulder == null || wrist == null || scale == null) continue;
      values.add(RunningWeightedValue(
        value: (wrist.x - shoulder.x) / scale,
        confidence: math.min(shoulder.confidence, wrist.confidence),
        timestamp: frame.timestamp,
      ));
    }
    if (values.length < 3) continue;
    final sorted = values.map((value) => value.value).toList()..sort();
    perSide.add((_quantile(sorted, 0.9) - _quantile(sorted, 0.1)).abs());
    confidence +=
        values.fold<double>(0, (sum, value) => sum + value.confidence) /
            values.length;
  }
  if (perSide.length != 2) {
    return const RunningMetricMeasurement.unavailable(
      metric: RunningAnalysisMetric.armAsymmetry,
      method: 'bilateral_arm_swing_asymmetry',
      reason: 'coordinates_unavailable',
    );
  }
  final denominator = math.max(0.000001, (perSide[0] + perSide[1]) / 2);
  final value = (perSide[0] - perSide[1]).abs() / denominator * 100;
  return RunningMetricMeasurement(
    metric: RunningAnalysisMetric.armAsymmetry,
    state: RunningMeasurementState.estimated,
    value: value,
    expectedRange: RunningExpectedRange(
      lower: math.max(0, value * 0.8),
      upper: math.min(100, value * 1.2 + 1),
    ),
    confidence: (confidence / 2 * 0.82).clamp(0.0, 1.0).toDouble(),
    sampleCount: frames.length,
    method: 'bilateral_arm_swing_asymmetry',
    evidenceTimestamps:
        frames.take(4).map((frame) => frame.timestamp).toList(growable: false),
  );
}

RunningMetricMeasurement _contactMeasurement(
  RunningVideoAnalysisResult result,
  List<RunningPoseFrame> frames,
  List<RunningFallbackContact> contacts, {
  required RunningAnalysisMetric metric,
}) {
  final values = <RunningWeightedValue>[];
  for (final contact in contacts) {
    final frame = _nearestFrame(frames, contact.timestamp, toleranceMs: 160);
    if (frame == null) continue;
    final indexes = contact.side == RunningContactSide.left
        ? const <int>[23, 25, 27]
        : const <int>[24, 26, 28];
    final hip = _point(frame, indexes[0]);
    final knee = _point(frame, indexes[1]);
    final ankle = _point(frame, indexes[2]);
    final scale = _bodyScale(frame);
    if (hip == null || knee == null || ankle == null || scale == null) continue;
    final value = metric == RunningAnalysisMetric.footStrike
        ? _forwardDistanceRatio(result.direction, hip, ankle, scale)
        : _jointAngle(hip, knee, ankle);
    values.add(RunningWeightedValue(
      value: value,
      confidence: math.min(
        contact.confidence,
        math.min(hip.confidence, math.min(knee.confidence, ankle.confidence)),
      ),
      timestamp: frame.timestamp,
    ));
  }
  final confirmedContacts =
      contacts.where((contact) => contact.isConfirmed).length;
  return _measurementFromEstimate(
    metric: metric,
    estimate: runningWeightedEstimate(values),
    method: confirmedContacts >= runningCoachMinimumReliableMetricSamples
        ? 'dense_contact_weighted_median'
        : 'coarse_kinematic_contact_estimate',
    confirmed: confirmedContacts >= runningCoachMinimumReliableMetricSamples &&
        _qualityConfirms(
          result,
          metric == RunningAnalysisMetric.footStrike
              ? RunningCoachMetric.footStrike
              : RunningCoachMetric.kneeFlexion,
        ),
    timestamps: values.map((value) => value.timestamp),
  );
}

RunningMetricMeasurement _maximumKneeMeasurement(
  RunningVideoAnalysisResult result,
  List<RunningPoseFrame> frames,
  List<RunningFallbackContact> contacts,
) {
  final values = <RunningWeightedValue>[];
  for (final contact in contacts) {
    RunningWeightedValue? minimum;
    for (final frame in frames) {
      final delta = frame.timestampMs - contact.timestamp.inMilliseconds;
      if (delta < 0 || delta > 260) continue;
      final indexes = contact.side == RunningContactSide.left
          ? const <int>[23, 25, 27]
          : const <int>[24, 26, 28];
      final hip = _point(frame, indexes[0]);
      final knee = _point(frame, indexes[1]);
      final ankle = _point(frame, indexes[2]);
      if (hip == null || knee == null || ankle == null) continue;
      final value = RunningWeightedValue(
        value: _jointAngle(hip, knee, ankle),
        confidence: math.min(
            contact.confidence,
            math.min(
                hip.confidence, math.min(knee.confidence, ankle.confidence))),
        timestamp: frame.timestamp,
      );
      if (minimum == null || value.value < minimum.value) minimum = value;
    }
    if (minimum != null) values.add(minimum);
  }
  return _measurementFromEstimate(
    metric: RunningAnalysisMetric.maximumKneeFlexion,
    estimate: runningWeightedEstimate(values),
    method: contacts.any((contact) => !contact.isConfirmed)
        ? 'estimated_contact_maximum_flexion'
        : 'dense_contact_maximum_flexion',
    confirmed: contacts.where((contact) => contact.isConfirmed).length >= 3 &&
        _qualityConfirms(result, RunningCoachMetric.kneeFlexion),
    timestamps: values.map((value) => value.timestamp),
  );
}

RunningMetricMeasurement _recoveryKneeMeasurement(
  RunningVideoAnalysisResult result,
  List<RunningPoseFrame> frames,
  List<RunningFallbackContact> contacts,
) {
  final values = <RunningWeightedValue>[];
  for (final contact in contacts) {
    final localFrames = frames
        .where((frame) =>
            frame.timestamp >=
                contact.timestamp - const Duration(milliseconds: 520) &&
            frame.timestamp <=
                contact.timestamp - const Duration(milliseconds: 120))
        .toList(growable: false);
    if (localFrames.isEmpty) continue;
    final ground = runningLocalGroundLevel(
      frames,
      side: contact.side,
      around: contact.timestamp,
    );
    RunningWeightedValue? minimum;
    for (final frame in localFrames) {
      final indexes = contact.side == RunningContactSide.left
          ? const <int>[23, 25, 27]
          : const <int>[24, 26, 28];
      final hip = _point(frame, indexes[0]);
      final knee = _point(frame, indexes[1]);
      final ankle = _point(frame, indexes[2]);
      final foot = _footBottom(frame, contact.side);
      final scale = _bodyScale(frame);
      if (hip == null ||
          knee == null ||
          ankle == null ||
          foot == null ||
          scale == null) {
        continue;
      }
      final isClearlyAirborne =
          ground == null || ground - foot.y >= scale * 0.055;
      if (!isClearlyAirborne) continue;
      final value = RunningWeightedValue(
        value: _jointAngle(hip, knee, ankle),
        confidence: math.min(
          contact.confidence,
          math.min(
            hip.confidence,
            math.min(knee.confidence, ankle.confidence),
          ),
        ),
        timestamp: frame.timestamp,
      );
      if (minimum == null || value.value < minimum.value) minimum = value;
    }
    if (minimum != null) values.add(minimum);
  }
  final confirmedContacts = contacts.where((contact) => contact.isConfirmed);
  return _measurementFromEstimate(
    metric: RunningAnalysisMetric.recoveryKneeFlexion,
    estimate: runningWeightedEstimate(values),
    method: contacts.any((contact) => !contact.isConfirmed)
        ? 'estimated_recovery_maximum_knee_flexion'
        : 'recovery_maximum_knee_flexion',
    confirmed: confirmedContacts.length >= 3 &&
        values.length >= 3 &&
        _qualityConfirms(result, RunningCoachMetric.kneeFlexion),
    timestamps: values.map((value) => value.timestamp),
  );
}

RunningMetricMeasurement _rhythmMeasurement(
  RunningVideoAnalysisResult result,
  List<RunningFallbackContact> contacts,
  List<RunningPoseFrame> frames, {
  required RunningAnalysisMetric metric,
}) {
  final intervals = <RunningWeightedValue>[];
  final leftIntervals = <double>[];
  final rightIntervals = <double>[];
  for (var index = 0; index < contacts.length - 1; index += 1) {
    final current = contacts[index];
    final next = contacts[index + 1];
    final interval =
        next.timestamp.inMilliseconds - current.timestamp.inMilliseconds;
    if (interval < 120 ||
        interval > 1000 ||
        (current.side == next.side &&
            current.side != RunningContactSide.unknown)) {
      continue;
    }
    intervals.add(RunningWeightedValue(
      value: interval.toDouble(),
      confidence: math.min(current.confidence, next.confidence),
      timestamp: current.timestamp,
    ));
    if (current.side == RunningContactSide.left) {
      leftIntervals.add(interval.toDouble());
    }
    if (current.side == RunningContactSide.right) {
      rightIntervals.add(interval.toDouble());
    }
  }
  final timing = runningWeightedEstimate(intervals);
  if (timing == null || intervals.length < 2) {
    return _trajectoryRhythmMeasurement(frames, metric: metric);
  }
  double? value;
  RunningExpectedRange? range;
  if (metric == RunningAnalysisMetric.cadence) {
    value = 60000 / timing.value;
    range = RunningExpectedRange(
      lower: 60000 / math.max(1, timing.range.upper),
      upper: 60000 / math.max(1, timing.range.lower),
    );
  } else if (metric == RunningAnalysisMetric.stepTime) {
    value = timing.value;
    range = timing.range;
  } else {
    if (leftIntervals.length < 2 || rightIntervals.length < 2) {
      return RunningMetricMeasurement.unavailable(
        metric: metric,
        method: 'bilateral_pose_cycle_timing',
        reason: 'limited_bilateral_samples',
      );
    }
    final left = _median(leftIntervals..sort());
    final right = _median(rightIntervals..sort());
    value = (left - right).abs() / math.max(1, (left + right) / 2) * 100;
    range = RunningExpectedRange(
      lower: math.max(0, value * 0.75),
      upper: math.min(100, value * 1.25 + 1),
    );
  }
  final confirmed =
      contacts.where((contact) => contact.isConfirmed).length >= 3 &&
          result.hasDenseContactEvidence;
  return RunningMetricMeasurement(
    metric: metric,
    state: confirmed
        ? RunningMeasurementState.confirmed
        : RunningMeasurementState.estimated,
    value: value,
    expectedRange: range,
    confidence: (confirmed ? timing.confidence : timing.confidence * 0.78)
        .clamp(0.0, 1.0)
        .toDouble(),
    sampleCount: intervals.length,
    method:
        confirmed ? 'validated_contact_timing' : 'pose_cycle_period_estimate',
    evidenceTimestamps: contacts
        .take(4)
        .map((contact) => contact.timestamp)
        .toList(growable: false),
  );
}

RunningMetricMeasurement _trajectoryRhythmMeasurement(
  List<RunningPoseFrame> frames, {
  required RunningAnalysisMetric metric,
}) {
  final estimate = runningTrajectoryRhythmEstimate(frames);
  if (estimate == null ||
      (metric == RunningAnalysisMetric.leftRightTiming &&
          estimate.leftRightAsymmetryPercent == null)) {
    return RunningMetricMeasurement.unavailable(
      metric: metric,
      method: 'pose_trajectory_cycle_estimate',
      reason: estimate == null
          ? 'limited_cycle_samples'
          : 'limited_bilateral_samples',
    );
  }
  final value = switch (metric) {
    RunningAnalysisMetric.cadence => estimate.cadenceSpm,
    RunningAnalysisMetric.stepTime => estimate.stepTimeMs,
    RunningAnalysisMetric.leftRightTiming =>
      estimate.leftRightAsymmetryPercent!,
    _ => throw ArgumentError.value(metric, 'metric'),
  };
  final uncertainty = switch (metric) {
    RunningAnalysisMetric.cadence => math.max(4.0, value * 0.08),
    RunningAnalysisMetric.stepTime => math.max(18.0, value * 0.08),
    RunningAnalysisMetric.leftRightTiming => math.max(1.0, value * 0.25),
    _ => 0.0,
  };
  return RunningMetricMeasurement(
    metric: metric,
    state: RunningMeasurementState.estimated,
    value: value,
    expectedRange: RunningExpectedRange(
      lower: math.max(0, value - uncertainty),
      upper: value + uncertainty,
    ),
    confidence: estimate.confidence,
    sampleCount: estimate.sampleCount,
    method: 'pose_trajectory_cycle_estimate',
    reason: 'contact_not_validated',
    evidenceTimestamps: estimate.evidenceTimestamps,
  );
}

RunningMetricMeasurement _footRollingMeasurement(
  List<RunningPoseFrame> frames,
  List<RunningFallbackContact> contacts,
) {
  final values = <RunningWeightedValue>[];
  for (final contact in contacts) {
    final frame = _nearestFrame(frames, contact.timestamp, toleranceMs: 160);
    if (frame == null) continue;
    final heelIndex = contact.side == RunningContactSide.left ? 29 : 30;
    final toeIndex = contact.side == RunningContactSide.left ? 31 : 32;
    final heel = _point(frame, heelIndex);
    final toe = _point(frame, toeIndex);
    if (heel == null || toe == null) continue;
    values.add(RunningWeightedValue(
      value: math.atan2(toe.y - heel.y, toe.x - heel.x).abs() * 180 / math.pi,
      confidence: math.min(
              contact.confidence, math.min(heel.confidence, toe.confidence)) *
          0.72,
      timestamp: frame.timestamp,
    ));
  }
  final estimate = runningWeightedEstimate(values);
  if (estimate == null) {
    return const RunningMetricMeasurement.unavailable(
      metric: RunningAnalysisMetric.footRolling,
      method: 'visible_foot_orientation_only',
      reason: 'foot_direction_coordinates_unavailable',
    );
  }
  return RunningMetricMeasurement(
    metric: RunningAnalysisMetric.footRolling,
    state: RunningMeasurementState.estimated,
    value: estimate.value,
    expectedRange: estimate.range,
    confidence: math.min(0.58, estimate.confidence),
    sampleCount: estimate.sampleCount,
    method: 'visible_foot_orientation_only',
    reason: 'pressure_path_not_observable',
    evidenceTimestamps:
        values.take(4).map((value) => value.timestamp).toList(growable: false),
  );
}

RunningMetricMeasurement _measurementFromEstimate({
  required RunningAnalysisMetric metric,
  required RunningWeightedEstimate? estimate,
  required String method,
  required bool confirmed,
  required Iterable<Duration> timestamps,
}) {
  if (estimate == null || !estimate.value.isFinite) {
    return RunningMetricMeasurement.unavailable(
      metric: metric,
      method: method,
      reason: 'coordinates_unavailable',
    );
  }
  return RunningMetricMeasurement(
    metric: metric,
    state: confirmed
        ? RunningMeasurementState.confirmed
        : RunningMeasurementState.estimated,
    value: estimate.value,
    expectedRange: estimate.range,
    confidence: (confirmed ? estimate.confidence : estimate.confidence * 0.82)
        .clamp(0.0, 1.0)
        .toDouble(),
    sampleCount: estimate.sampleCount,
    method: method,
    evidenceTimestamps: timestamps.toSet().toList(growable: false)..sort(),
  );
}

bool _qualityConfirms(
  RunningVideoAnalysisResult result,
  RunningCoachMetric metric,
) {
  final quality = result.qualityFor(metric);
  return quality == null
      ? result.analysisConfidence >= runningCoachReliableMetricConfidence
      : quality.isReliableForCoaching;
}

List<RunningFallbackContact> _platformContacts(
  RunningVideoAnalysisResult result,
) {
  final contacts = <RunningFallbackContact>[];
  for (final timestamp in result.validatedContactFrameTimestamps) {
    RunningContactWindow? selected;
    var distance = 1 << 30;
    for (final window in result.contactWindows) {
      final currentDistance =
          (window.centerMs - timestamp.inMilliseconds).abs();
      if (currentDistance < distance) {
        selected = window;
        distance = currentDistance;
      }
    }
    contacts.add(RunningFallbackContact(
      timestamp: timestamp,
      side: selected?.side ?? RunningContactSide.unknown,
      confidence: math
          .max(
            result.contactConfidence,
            selected?.confidence ?? 0,
          )
          .clamp(0.0, 1.0)
          .toDouble(),
      isConfirmed: true,
    ));
  }
  for (final timestamp in result.estimatedContactFrameTimestamps) {
    RunningContactWindow? selected;
    var distance = 1 << 30;
    for (final window in result.contactWindows) {
      final explicitlyEstimated = window.estimatedContactTimestamps.any(
        (candidate) => candidate == timestamp,
      );
      final currentDistance = explicitlyEstimated
          ? 0
          : (window.centerMs - timestamp.inMilliseconds).abs();
      if (currentDistance < distance) {
        selected = window;
        distance = currentDistance;
      }
    }
    contacts.add(RunningFallbackContact(
      timestamp: timestamp,
      side: selected?.side ?? RunningContactSide.unknown,
      confidence: math
          .min(
            0.62,
            math.max(result.contactConfidence, selected?.confidence ?? 0),
          )
          .clamp(0.0, 1.0)
          .toDouble(),
      isConfirmed: false,
    ));
  }
  contacts.sort((left, right) => left.timestamp.compareTo(right.timestamp));
  return contacts;
}

double runningMotionScore(List<RunningPoseFrame> source) {
  final frames = runningStabilizedPoseFrames(source);
  if (frames.length < 3) return 0;
  var hipTravel = 0.0;
  var ankleTravel = 0.0;
  var kneeTravel = 0.0;
  var transitions = 0;
  for (var index = 1; index < frames.length; index += 1) {
    final previous = frames[index - 1];
    final current = frames[index];
    if (current.timestampMs - previous.timestampMs > 400) continue;
    final scale = _bodyScale(current);
    final previousScale = _bodyScale(previous);
    if (scale == null || previousScale == null) continue;
    final normalization = math.max(0.01, (scale + previousScale) / 2);
    final previousHip = _midpoint(_point(previous, 23), _point(previous, 24));
    final currentHip = _midpoint(_point(current, 23), _point(current, 24));
    if (previousHip != null && currentHip != null) {
      hipTravel += _distance(previousHip, currentHip) / normalization;
    }
    for (final joint in const <int>[25, 26, 27, 28]) {
      final before = _point(previous, joint);
      final after = _point(current, joint);
      if (before == null || after == null) continue;
      final distance = _distance(before, after) / normalization;
      if (joint >= 27) {
        ankleTravel += distance;
      } else {
        kneeTravel += distance;
      }
    }
    transitions += 1;
  }
  if (transitions == 0) return 0;
  final hip = hipTravel / transitions;
  final ankle = ankleTravel / transitions;
  final knee = kneeTravel / transitions;
  // Hip translation separates an actual pass from jogging in place, while
  // ankle/knee periodic travel still recognizes treadmill running.
  return ((hip / 0.10) * 0.35 + (ankle / 0.22) * 0.45 + (knee / 0.16) * 0.20)
      .clamp(0.0, 1.0)
      .toDouble();
}

(Duration, Duration)? runningBestAnalysisWindow(
  List<RunningPoseFrame> frames,
  List<RunningScaleSegment> segments,
) {
  if (frames.isEmpty) return null;
  final candidates =
      segments.where((segment) => segment.sampleCount >= 3).toList();
  if (candidates.isEmpty) {
    return (frames.first.timestamp, frames.last.timestamp);
  }
  candidates.sort((left, right) {
    double score(RunningScaleSegment segment) {
      final segmentFrames = frames
          .where(
            (frame) =>
                frame.timestamp >= segment.start &&
                frame.timestamp <= segment.end,
          )
          .toList(growable: false);
      final motion = runningMotionScore(segmentFrames);
      final stableBonus = segment.trend == RunningScaleTrend.stable ? 0.08 : 0;
      return motion * 0.68 + segment.confidence * 0.24 + stableBonus;
    }

    final byScore = score(right).compareTo(score(left));
    if (byScore != 0) return byScore;
    final samples = right.sampleCount.compareTo(left.sampleCount);
    return samples != 0 ? samples : left.start.compareTo(right.start);
  });
  final selected = candidates.first;
  const maximumWindow = Duration(seconds: 15);
  final end = selected.end - selected.start > maximumWindow
      ? selected.start + maximumWindow
      : selected.end;
  return (selected.start, end);
}

List<RunningPoseFrame> _orderedPoseFrames(List<RunningPoseFrame> frames) {
  final byTimestamp = <int, RunningPoseFrame>{};
  for (final frame in frames) {
    final existing = byTimestamp[frame.timestampMs];
    if (existing == null ||
        _poseConfidence(frame) > _poseConfidence(existing)) {
      byTimestamp[frame.timestampMs] = frame;
    }
  }
  return byTimestamp.values.toList(growable: false)
    ..sort((left, right) => left.timestamp.compareTo(right.timestamp));
}

bool _usableLandmark(RunningVideoPoseLandmark? landmark) {
  return landmark != null &&
      landmark.x.isFinite &&
      landmark.y.isFinite &&
      landmark.z.isFinite &&
      landmark.confidence.isFinite &&
      landmark.confidence >= 0.12;
}

double _landmarkDistance(
  RunningVideoPoseLandmark first,
  RunningVideoPoseLandmark second,
) {
  final x = first.x - second.x;
  final y = first.y - second.y;
  return math.sqrt(x * x + y * y);
}

RunningVideoPoseLandmark _interpolateLandmark(
  RunningVideoPoseLandmark first,
  RunningVideoPoseLandmark second,
  double fraction, {
  required double confidencePenalty,
}) {
  double interpolate(double firstValue, double secondValue) =>
      firstValue + ((secondValue - firstValue) * fraction);
  double? interpolateOptional(double? firstValue, double? secondValue) {
    if (firstValue == null || secondValue == null) return null;
    return interpolate(firstValue, secondValue);
  }

  final hasWorld = first.hasWorldCoordinates && second.hasWorldCoordinates;
  return RunningVideoPoseLandmark(
    index: first.index,
    x: interpolate(first.x, second.x),
    y: interpolate(first.y, second.y),
    z: interpolate(first.z, second.z),
    visibility: interpolateOptional(first.visibility, second.visibility),
    presence: interpolateOptional(first.presence, second.presence),
    confidence:
        (math.min(first.confidence, second.confidence) * confidencePenalty)
            .clamp(0.0, 1.0)
            .toDouble(),
    worldX: hasWorld ? interpolate(first.worldX!, second.worldX!) : null,
    worldY: hasWorld ? interpolate(first.worldY!, second.worldY!) : null,
    worldZ: hasWorld ? interpolate(first.worldZ!, second.worldZ!) : null,
    worldVisibility: interpolateOptional(
      first.worldVisibility,
      second.worldVisibility,
    ),
    worldPresence: interpolateOptional(
      first.worldPresence,
      second.worldPresence,
    ),
    worldConfidence: interpolateOptional(
      first.worldConfidence,
      second.worldConfidence,
    ),
  );
}

RunningVideoPoseLandmark _copyLandmark(
  RunningVideoPoseLandmark source, {
  required int index,
  required double confidencePenalty,
}) {
  return RunningVideoPoseLandmark(
    index: index,
    x: source.x,
    y: source.y,
    z: source.z,
    visibility: source.visibility,
    presence: source.presence,
    confidence:
        (source.confidence * confidencePenalty).clamp(0.0, 1.0).toDouble(),
    worldX: source.worldX,
    worldY: source.worldY,
    worldZ: source.worldZ,
    worldVisibility: source.worldVisibility,
    worldPresence: source.worldPresence,
    worldConfidence: source.worldConfidence == null
        ? null
        : (source.worldConfidence! * confidencePenalty)
            .clamp(0.0, 1.0)
            .toDouble(),
  );
}

RunningPoseFrame? _nearestFrame(
  List<RunningPoseFrame> frames,
  Duration timestamp, {
  required int toleranceMs,
}) {
  RunningPoseFrame? selected;
  var distance = toleranceMs + 1;
  for (final frame in frames) {
    final current = (frame.timestampMs - timestamp.inMilliseconds).abs();
    if (current < distance) {
      selected = frame;
      distance = current;
    }
  }
  return distance <= toleranceMs ? selected : null;
}

class _Point {
  final double x;
  final double y;
  final double confidence;

  const _Point(this.x, this.y, this.confidence);
}

_Point? _point(RunningPoseFrame frame, int index) {
  final landmark = frame.landmarkByIndex(index);
  if (landmark == null ||
      !landmark.x.isFinite ||
      !landmark.y.isFinite ||
      !landmark.confidence.isFinite ||
      landmark.confidence < 0.12) {
    return null;
  }
  return _Point(landmark.x, landmark.y, landmark.confidence);
}

_Point? _midpoint(_Point? first, _Point? second) {
  if (first == null && second == null) return null;
  if (first == null) return second;
  if (second == null) return first;
  return _Point(
    (first.x + second.x) / 2,
    (first.y + second.y) / 2,
    math.min(first.confidence, second.confidence),
  );
}

double? _bodyScale(RunningPoseFrame frame) {
  final shoulder = _midpoint(_point(frame, 11), _point(frame, 12));
  final hip = _midpoint(_point(frame, 23), _point(frame, 24));
  if (shoulder == null || hip == null) return null;
  final torso = _distance(shoulder, hip);
  final ankles = _midpoint(_point(frame, 27), _point(frame, 28));
  final leg = ankles == null ? 0.0 : _distance(hip, ankles);
  final scale = math.max(torso, leg);
  return scale.isFinite && scale > 0.01 ? scale : null;
}

_Point? _footBottom(RunningPoseFrame frame, RunningContactSide side) {
  final indexes = side == RunningContactSide.left
      ? const <int>[27, 29, 31]
      : const <int>[28, 30, 32];
  final points =
      indexes.map((index) => _point(frame, index)).whereType<_Point>().toList();
  if (points.isEmpty) return null;
  points.sort((left, right) => right.y.compareTo(left.y));
  return points.first;
}

double _jointAngle(_Point first, _Point vertex, _Point third) {
  final firstX = first.x - vertex.x;
  final firstY = first.y - vertex.y;
  final secondX = third.x - vertex.x;
  final secondY = third.y - vertex.y;
  final firstLength = math.sqrt(firstX * firstX + firstY * firstY);
  final secondLength = math.sqrt(secondX * secondX + secondY * secondY);
  if (firstLength <= 0 || secondLength <= 0) return 180;
  final cosine =
      ((firstX * secondX) + (firstY * secondY)) / (firstLength * secondLength);
  return math.acos(cosine.clamp(-1.0, 1.0)) * 180 / math.pi;
}

double _forwardDistanceRatio(
  RunningDirection direction,
  _Point hip,
  _Point ankle,
  double scale,
) {
  final signed = ankle.x - hip.x;
  final forward = direction == RunningDirection.rightToLeft ? -signed : signed;
  return math.max(0, forward) / scale;
}

double _distance(_Point first, _Point second) {
  final x = first.x - second.x;
  final y = first.y - second.y;
  return math.sqrt(x * x + y * y);
}

double _poseConfidence(RunningPoseFrame frame) {
  final values = frame.landmarks
      .map((landmark) => landmark.confidence)
      .where((value) => value.isFinite)
      .toList(growable: false);
  return values.isEmpty
      ? 0
      : values.reduce((sum, value) => sum + value) / values.length;
}

double _frameConfidence(RunningPoseFrame frame, List<int> indexes) {
  final values = indexes
      .map((index) => _point(frame, index)?.confidence)
      .whereType<double>()
      .toList(growable: false);
  return values.isEmpty
      ? 0
      : values.reduce((sum, value) => sum + value) / values.length;
}

double _median(List<double> sortedValues) {
  final middle = sortedValues.length ~/ 2;
  return sortedValues.length.isOdd
      ? sortedValues[middle]
      : (sortedValues[middle - 1] + sortedValues[middle]) / 2;
}

double _quantile(List<double> sortedValues, double fraction) {
  if (sortedValues.isEmpty) return 0;
  final position = (sortedValues.length - 1) * fraction.clamp(0.0, 1.0);
  final lower = position.floor();
  final upper = position.ceil();
  if (lower == upper) return sortedValues[lower];
  final weight = position - lower;
  return sortedValues[lower] +
      (sortedValues[upper] - sortedValues[lower]) * weight;
}

class _ScaleSample {
  final Duration timestamp;
  final double scale;
  final double confidence;

  const _ScaleSample({
    required this.timestamp,
    required this.scale,
    required this.confidence,
  });
}

class _FootSample {
  final RunningPoseFrame frame;
  final double x;
  final double y;
  final double hipX;
  final double hipY;
  final double scale;
  final double confidence;
  final double kneeAngle;

  const _FootSample({
    required this.frame,
    required this.x,
    required this.y,
    required this.hipX,
    required this.hipY,
    required this.scale,
    required this.confidence,
    required this.kneeAngle,
  });
}
