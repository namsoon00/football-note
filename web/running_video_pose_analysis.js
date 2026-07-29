(() => {
  'use strict';

  const config = Object.freeze({
    taskVersion: '0.10.35',
    minVideoDurationMs: 1500,
    minConfidence: 0.35,
    minValidFrames: 6,
    sampleCount: 14,
    sampleStartFraction: 0.15,
    sampleEndFraction: 0.85,
    minMedianSharpness: 0.018,
    minSharpnessSamples: 6,
    minBodyScalePx: 40,
    stationaryThresholdRatio: 0.12,
    denseIntervalMs: 33,
    denseWindowRadiusMs: 180,
    denseTargetFps: 30,
    maxDenseFrames: 48,
    maxContactWindows: 6,
    minContactSeparationMs: 120,
    minValidatedContacts: 2,
    minContactConfidence: 0.34,
  });

  const index = Object.freeze({
    leftShoulder: 11,
    rightShoulder: 12,
    leftElbow: 13,
    rightElbow: 14,
    leftWrist: 15,
    rightWrist: 16,
    leftHip: 23,
    rightHip: 24,
    leftKnee: 25,
    rightKnee: 26,
    leftAnkle: 27,
    rightAnkle: 28,
    leftHeel: 29,
    rightHeel: 30,
    leftToe: 31,
    rightToe: 32,
  });

  let visionModulePromise;

  const createError = (code, message) => {
    const error = new Error(message);
    error.code = code;
    return error;
  };

  const round3 = (value) => Math.round(value * 1000) / 1000;
  const average = (values) =>
    values.length === 0
      ? 0
      : values.reduce((sum, value) => sum + value, 0) / values.length;
  const median = (values) => {
    if (values.length === 0) return null;
    const sorted = [...values].sort((a, b) => a - b);
    const upper = Math.floor(sorted.length / 2);
    const lower = Math.floor((sorted.length - 1) / 2);
    return (sorted[lower] + sorted[upper]) / 2;
  };
  const distance = (first, second) =>
    Math.hypot(first.x - second.x, first.y - second.y);
  const midpoint = (first, second) => ({
    x: (first.x + second.x) / 2,
    y: (first.y + second.y) / 2,
  });
  const nextAnimationFrame = () =>
    new Promise((resolve) => requestAnimationFrame(resolve));

  const assetUrl = (path) => new URL(path, document.baseURI).toString();

  async function loadVisionModule() {
    if (!visionModulePromise) {
      const base = `https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@${config.taskVersion}`;
      visionModulePromise = import(`${base}/vision_bundle.mjs`);
    }
    return visionModulePromise;
  }

  async function createLandmarker() {
    const visionModule = await loadVisionModule();
    const wasmRoot =
      `https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@${config.taskVersion}/wasm`;
    const vision = await visionModule.FilesetResolver.forVisionTasks(wasmRoot);
    return visionModule.PoseLandmarker.createFromOptions(vision, {
      baseOptions: {
        modelAssetPath: assetUrl('mediapipe/pose_landmarker_full.task'),
      },
      runningMode: 'VIDEO',
      numPoses: 1,
      minPoseDetectionConfidence: config.minConfidence,
      minPosePresenceConfidence: config.minConfidence,
      minTrackingConfidence: config.minConfidence,
    });
  }

  function loadVideo(bytes, name) {
    return new Promise((resolve, reject) => {
      const blob = new Blob([bytes], {
        type: name && name.toLowerCase().endsWith('.mov')
          ? 'video/quicktime'
          : 'video/mp4',
      });
      const url = URL.createObjectURL(blob);
      const video = document.createElement('video');
      video.muted = true;
      video.playsInline = true;
      video.preload = 'auto';
      video.src = url;

      const cleanup = () => {
        video.removeEventListener('loadedmetadata', onLoaded);
        video.removeEventListener('error', onError);
      };
      const onLoaded = () => {
        cleanup();
        resolve({ video, url });
      };
      const onError = () => {
        cleanup();
        URL.revokeObjectURL(url);
        reject(
          createError(
            'web_video_decode_failed',
            'The selected video could not be decoded by this browser.',
          ),
        );
      };
      video.addEventListener('loadedmetadata', onLoaded, { once: true });
      video.addEventListener('error', onError, { once: true });
    });
  }

  function seekVideo(video, seconds) {
    return new Promise((resolve, reject) => {
      const target = Math.max(0, Math.min(seconds, video.duration));
      if (Math.abs(video.currentTime - target) < 0.0005) {
        resolve();
        return;
      }
      const onSeeked = () => {
        cleanup();
        resolve();
      };
      const onError = () => {
        cleanup();
        reject(
          createError(
            'web_video_decode_failed',
            'The selected video could not be read at an analysis frame.',
          ),
        );
      };
      const cleanup = () => {
        video.removeEventListener('seeked', onSeeked);
        video.removeEventListener('error', onError);
      };
      video.addEventListener('seeked', onSeeked, { once: true });
      video.addEventListener('error', onError, { once: true });
      video.currentTime = target;
    });
  }

  function sampleTimestamps(durationMs) {
    return Array.from({ length: config.sampleCount }, (_, sampleIndex) => {
      const progress = config.sampleCount === 1
        ? 0.5
        : sampleIndex / (config.sampleCount - 1);
      const fraction = config.sampleStartFraction +
        (config.sampleEndFraction - config.sampleStartFraction) * progress;
      return Math.round(durationMs * fraction);
    });
  }

  function landmarkConfidence(landmark) {
    const visibility = Number.isFinite(landmark?.visibility)
      ? landmark.visibility
      : null;
    const presence = Number.isFinite(landmark?.presence)
      ? landmark.presence
      : null;
    const confidence = visibility !== null && presence !== null
      ? Math.min(visibility, presence)
      : visibility ?? presence ?? 0;
    return Math.max(0, Math.min(1, confidence));
  }

  function confidentPoint(landmarks, landmarkIndex, width, height) {
    const landmark = landmarks[landmarkIndex];
    if (!landmark) return null;
    const confidence = landmarkConfidence(landmark);
    if (confidence < config.minConfidence) return null;
    return {
      point: { x: landmark.x * width, y: landmark.y * height },
      confidence,
    };
  }

  function poseFrame(landmarks, timestampMs, width, height) {
    if (!Array.isArray(landmarks) || landmarks.length < 33) return null;
    return {
      timestampMs,
      imageWidth: width,
      imageHeight: height,
      landmarks: landmarks.slice(0, 33).map((landmark, landmarkIndex) => ({
        index: landmarkIndex,
        x: landmark.x,
        y: landmark.y,
        z: landmark.z ?? 0,
        visibility: Number.isFinite(landmark.visibility)
          ? landmark.visibility
          : null,
        presence: Number.isFinite(landmark.presence) ? landmark.presence : null,
        confidence: landmarkConfidence(landmark),
      })),
    };
  }

  function extractSample(landmarks, timestampMs, width, height) {
    const core = {
      leftShoulder: confidentPoint(landmarks, index.leftShoulder, width, height),
      rightShoulder: confidentPoint(landmarks, index.rightShoulder, width, height),
      leftHip: confidentPoint(landmarks, index.leftHip, width, height),
      rightHip: confidentPoint(landmarks, index.rightHip, width, height),
      leftKnee: confidentPoint(landmarks, index.leftKnee, width, height),
      rightKnee: confidentPoint(landmarks, index.rightKnee, width, height),
      leftAnkle: confidentPoint(landmarks, index.leftAnkle, width, height),
      rightAnkle: confidentPoint(landmarks, index.rightAnkle, width, height),
    };
    if (Object.values(core).some((value) => value === null)) return null;

    const shoulderCenter = midpoint(
      core.leftShoulder.point,
      core.rightShoulder.point,
    );
    const hipCenter = midpoint(core.leftHip.point, core.rightHip.point);
    const ankleCenter = midpoint(core.leftAnkle.point, core.rightAnkle.point);
    const bodyScale = Math.max(
      distance(shoulderCenter, hipCenter),
      distance(hipCenter, ankleCenter),
    );
    if (bodyScale < config.minBodyScalePx) return null;

    const optional = (landmarkIndex) =>
      confidentPoint(landmarks, landmarkIndex, width, height);
    return {
      timestampMs,
      shoulderCenter,
      hipCenter,
      bodyScale,
      leftShoulder: core.leftShoulder.point,
      rightShoulder: core.rightShoulder.point,
      leftHip: core.leftHip.point,
      rightHip: core.rightHip.point,
      leftKnee: core.leftKnee.point,
      rightKnee: core.rightKnee.point,
      leftAnkle: core.leftAnkle.point,
      rightAnkle: core.rightAnkle.point,
      leftElbow: optional(index.leftElbow)?.point ?? null,
      rightElbow: optional(index.rightElbow)?.point ?? null,
      leftWrist: optional(index.leftWrist)?.point ?? null,
      rightWrist: optional(index.rightWrist)?.point ?? null,
      leftHeel: optional(index.leftHeel)?.point ?? null,
      rightHeel: optional(index.rightHeel)?.point ?? null,
      leftToe: optional(index.leftToe)?.point ?? null,
      rightToe: optional(index.rightToe)?.point ?? null,
      leftShoulderConfidence: core.leftShoulder.confidence,
      rightShoulderConfidence: core.rightShoulder.confidence,
      leftHipConfidence: core.leftHip.confidence,
      rightHipConfidence: core.rightHip.confidence,
      leftKneeConfidence: core.leftKnee.confidence,
      rightKneeConfidence: core.rightKnee.confidence,
      leftAnkleConfidence: core.leftAnkle.confidence,
      rightAnkleConfidence: core.rightAnkle.confidence,
      leftElbowConfidence: optional(index.leftElbow)?.confidence ?? null,
      rightElbowConfidence: optional(index.rightElbow)?.confidence ?? null,
      leftWristConfidence: optional(index.leftWrist)?.confidence ?? null,
      rightWristConfidence: optional(index.rightWrist)?.confidence ?? null,
      leftHeelConfidence: optional(index.leftHeel)?.confidence ?? null,
      rightHeelConfidence: optional(index.rightHeel)?.confidence ?? null,
      leftToeConfidence: optional(index.leftToe)?.confidence ?? null,
      rightToeConfidence: optional(index.rightToe)?.confidence ?? null,
    };
  }

  function frameSharpness(video, canvas) {
    const context = canvas.getContext('2d', { willReadFrequently: true });
    if (!context || video.videoWidth < 3 || video.videoHeight < 3) return null;
    const sourceLeft = Math.floor(video.videoWidth * 0.1);
    const sourceRight = video.videoWidth - sourceLeft;
    const sourceTop = Math.floor(video.videoHeight * 0.32);
    const sourceBottom = Math.floor(video.videoHeight * 0.68);
    const sourceWidth = sourceRight - sourceLeft;
    const sourceHeight = sourceBottom - sourceTop;
    if (sourceWidth < 3 || sourceHeight < 3) return null;

    canvas.width = 96;
    canvas.height = 64;
    context.drawImage(
      video,
      sourceLeft,
      sourceTop,
      sourceWidth,
      sourceHeight,
      0,
      0,
      canvas.width,
      canvas.height,
    );
    const pixels = context.getImageData(0, 0, canvas.width, canvas.height).data;
    const luminance = new Float64Array(canvas.width * canvas.height);
    for (let pixelIndex = 0; pixelIndex < luminance.length; pixelIndex += 1) {
      const offset = pixelIndex * 4;
      luminance[pixelIndex] =
        pixels[offset] * 0.299 + pixels[offset + 1] * 0.587 + pixels[offset + 2] * 0.114;
    }
    let sum = 0;
    let squaredSum = 0;
    let count = 0;
    for (let y = 1; y < canvas.height - 1; y += 1) {
      for (let x = 1; x < canvas.width - 1; x += 1) {
        const at = y * canvas.width + x;
        const laplacian =
          4 * luminance[at] -
          luminance[at - 1] -
          luminance[at + 1] -
          luminance[at - canvas.width] -
          luminance[at + canvas.width];
        sum += laplacian;
        squaredSum += laplacian * laplacian;
        count += 1;
      }
    }
    if (count === 0) return null;
    const mean = sum / count;
    return Math.max(0, squaredSum / count - mean * mean) / (255 * 255);
  }

  async function runPosePass(video, timestamps, collectSharpness) {
    const landmarker = await createLandmarker();
    const samples = [];
    const poseFrames = [];
    const sharpnessValues = [];
    const canvas = collectSharpness ? document.createElement('canvas') : null;
    let lastDetectionTimestamp = -1;
    try {
      for (const timestampMs of [...new Set(timestamps)].sort((a, b) => a - b)) {
        await seekVideo(video, timestampMs / 1000);
        if (collectSharpness) {
          const sharpness = frameSharpness(video, canvas);
          if (sharpness !== null) sharpnessValues.push(sharpness);
        }
        const detectionTimestamp = Math.max(timestampMs, lastDetectionTimestamp + 1);
        lastDetectionTimestamp = detectionTimestamp;
        const result = landmarker.detectForVideo(video, detectionTimestamp);
        const landmarks = result?.landmarks?.[0];
        if (!landmarks) {
          await nextAnimationFrame();
          continue;
        }
        const width = video.videoWidth;
        const height = video.videoHeight;
        const frame = poseFrame(landmarks, timestampMs, width, height);
        if (frame) poseFrames.push(frame);
        const sample = extractSample(landmarks, timestampMs, width, height);
        if (sample) samples.push(sample);
        await nextAnimationFrame();
      }
    } finally {
      landmarker.close();
    }
    return { samples, poseFrames, sharpnessValues };
  }

  function resolveDirection(samples) {
    const movement =
      samples[samples.length - 1].hipCenter.x - samples[0].hipCenter.x;
    const scale = Math.max(1, average(samples.map((sample) => sample.bodyScale)));
    if (Math.abs(movement) < scale * config.stationaryThresholdRatio) {
      return 'stationary';
    }
    return movement > 0 ? 'leftToRight' : 'rightToLeft';
  }

  function jointAngle(first, vertex, third) {
    const firstX = first.x - vertex.x;
    const firstY = first.y - vertex.y;
    const secondX = third.x - vertex.x;
    const secondY = third.y - vertex.y;
    const firstLength = Math.hypot(firstX, firstY);
    const secondLength = Math.hypot(secondX, secondY);
    if (firstLength <= 0 || secondLength <= 0) return 180;
    const cosine = Math.max(
      -1,
      Math.min(1, (firstX * secondX + firstY * secondY) / (firstLength * secondLength)),
    );
    return (Math.acos(cosine) * 180) / Math.PI;
  }

  function forwardLeanDegrees(sample, direction) {
    const verticalTravel = Math.max(1, sample.hipCenter.y - sample.shoulderCenter.y);
    const rawOffset = sample.shoulderCenter.x - sample.hipCenter.x;
    const forwardOffset = direction === 'leftToRight'
      ? rawOffset
      : direction === 'rightToLeft'
        ? -rawOffset
        : Math.abs(rawOffset);
    if (direction !== 'stationary' && forwardOffset <= 0) return 0;
    return (Math.atan2(Math.abs(forwardOffset), verticalTravel) * 180) / Math.PI;
  }

  function footBottom(sample, side) {
    const prefix = side === 'left' ? 'left' : 'right';
    const ankle = sample[`${prefix}Ankle`];
    if (!ankle) return null;
    const heel = sample[`${prefix}Heel`] ?? ankle;
    const toe = sample[`${prefix}Toe`] ?? ankle;
    const points = [ankle, heel, toe];
    const bottomPoint = points.reduce((lowest, point) =>
      point.y > lowest.y ? point : lowest,
    );
    const confidences = [
      sample[`${prefix}AnkleConfidence`],
      sample[`${prefix}HeelConfidence`],
      sample[`${prefix}ToeConfidence`],
    ].filter(Number.isFinite);
    return {
      ankle,
      heel,
      toe,
      bottomPoint,
      confidence: Math.min(...confidences),
    };
  }

  function contactLandmarkConfidence(sample, side, foot) {
    const prefix = side === 'left' ? 'left' : 'right';
    return Math.min(
      foot.confidence,
      sample[`${prefix}HipConfidence`],
      sample[`${prefix}KneeConfidence`],
    );
  }

  function contactFootStrikeRatio(sample, side, direction) {
    const foot = footBottom(sample, side);
    if (!foot) return 0;
    const rawReach = foot.ankle.x - sample.hipCenter.x;
    const forwardReach = direction === 'leftToRight'
      ? rawReach
      : direction === 'rightToLeft'
        ? -rawReach
        : Math.abs(rawReach);
    return Math.max(0, forwardReach) / Math.max(1, sample.bodyScale);
  }

  function contactKneeAngle(sample, side) {
    return side === 'left'
      ? jointAngle(sample.leftHip, sample.leftKnee, sample.leftAnkle)
      : jointAngle(sample.rightHip, sample.rightKnee, sample.rightAnkle);
  }

  function elbowAngle(sample) {
    const values = [];
    if (sample.leftElbow && sample.leftWrist) {
      values.push(jointAngle(sample.leftShoulder, sample.leftElbow, sample.leftWrist));
    }
    if (sample.rightElbow && sample.rightWrist) {
      values.push(jointAngle(sample.rightShoulder, sample.rightElbow, sample.rightWrist));
    }
    return values.length === 0 ? null : average(values);
  }

  function coreConfidence(sample) {
    return average([
      sample.leftShoulderConfidence,
      sample.rightShoulderConfidence,
      sample.leftHipConfidence,
      sample.rightHipConfidence,
      sample.leftKneeConfidence,
      sample.rightKneeConfidence,
      sample.leftAnkleConfidence,
      sample.rightAnkleConfidence,
    ]);
  }

  function armConfidence(sample) {
    const sides = [];
    if (Number.isFinite(sample.leftElbowConfidence) && Number.isFinite(sample.leftWristConfidence)) {
      sides.push(average([
        sample.leftShoulderConfidence,
        sample.leftElbowConfidence,
        sample.leftWristConfidence,
      ]));
    }
    if (Number.isFinite(sample.rightElbowConfidence) && Number.isFinite(sample.rightWristConfidence)) {
      sides.push(average([
        sample.rightShoulderConfidence,
        sample.rightElbowConfidence,
        sample.rightWristConfidence,
      ]));
    }
    return sides.length === 0 ? null : average(sides);
  }

  function deriveContactCandidates(samples, durationMs) {
    const footEvidence = [];
    for (const sample of samples) {
      for (const side of ['left', 'right']) {
        const foot = footBottom(sample, side);
        if (foot) footEvidence.push({ sample, side, foot });
      }
    }
    if (footEvidence.length === 0) return { windows: [], groundY: 0 };
    const groundY = Math.max(...footEvidence.map(({ foot }) => foot.bottomPoint.y));
    const averageScale = Math.max(1, average(samples.map((sample) => sample.bodyScale)));
    const groundTolerance = averageScale * 0.12;
    const localTolerance = averageScale * 0.025;
    const candidates = [];

    for (const side of ['left', 'right']) {
      const sideEvidence = footEvidence.filter((item) => item.side === side);
      for (let itemIndex = 0; itemIndex < sideEvidence.length; itemIndex += 1) {
        const current = sideEvidence[itemIndex];
        const bottomY = current.foot.bottomPoint.y;
        const previousY = sideEvidence[itemIndex - 1]?.foot.bottomPoint.y;
        const nextY = sideEvidence[itemIndex + 1]?.foot.bottomPoint.y;
        const nearGround = groundY - bottomY <= groundTolerance;
        const localExtremum =
          (previousY === undefined || bottomY >= previousY - localTolerance) &&
          (nextY === undefined || bottomY >= nextY - localTolerance);
        if (!nearGround || !localExtremum) continue;
        const proximity = Math.max(0, groundY - bottomY);
        const confidence =
          current.foot.confidence * Math.max(0, Math.min(1, 1 - proximity / Math.max(1, groundTolerance)));
        candidates.push({
          side,
          centerTimestampMs: current.sample.timestampMs,
          startTimestampMs: Math.max(0, current.sample.timestampMs - config.denseWindowRadiusMs),
          endTimestampMs: Math.min(durationMs, current.sample.timestampMs + config.denseWindowRadiusMs),
          confidence,
        });
      }
    }

    const selected = [];
    for (const candidate of [...candidates].sort(
      (left, right) => right.confidence - left.confidence || left.centerTimestampMs - right.centerTimestampMs,
    )) {
      const overlaps = selected.some((selectedCandidate) =>
        selectedCandidate.side === candidate.side &&
        (Math.abs(selectedCandidate.centerTimestampMs - candidate.centerTimestampMs) < config.minContactSeparationMs ||
          (candidate.startTimestampMs <= selectedCandidate.endTimestampMs &&
            candidate.endTimestampMs >= selectedCandidate.startTimestampMs)),
      );
      if (!overlaps) selected.push(candidate);
      if (selected.length >= config.maxContactWindows) break;
    }
    return { windows: selected.sort((left, right) => left.centerTimestampMs - right.centerTimestampMs), groundY };
  }

  function fallbackContactCandidates(samples, durationMs) {
    const windows = [];
    let groundY = 0;
    for (const side of ['left', 'right']) {
      const candidates = samples
        .map((sample) => ({ sample, foot: footBottom(sample, side) }))
        .filter(({ foot }) => foot !== null)
        .sort((left, right) => right.foot.bottomPoint.y - left.foot.bottomPoint.y);
      const selected = candidates[0];
      if (!selected) continue;
      groundY = Math.max(groundY, selected.foot.bottomPoint.y);
      windows.push({
        side,
        centerTimestampMs: selected.sample.timestampMs,
        startTimestampMs: Math.max(0, selected.sample.timestampMs - config.denseWindowRadiusMs),
        endTimestampMs: Math.min(durationMs, selected.sample.timestampMs + config.denseWindowRadiusMs),
        confidence: selected.foot.confidence,
      });
    }
    return { windows: windows.sort((left, right) => left.centerTimestampMs - right.centerTimestampMs), groundY };
  }

  function denseTimestamps(windows, durationMs) {
    const distances = new Map();
    const record = (timestampMs, centerTimestampMs) => {
      const time = Math.max(0, Math.min(durationMs, timestampMs));
      const distanceFromCenter = Math.abs(time - centerTimestampMs);
      const existing = distances.get(time);
      if (existing === undefined || distanceFromCenter < existing) {
        distances.set(time, distanceFromCenter);
      }
    };
    for (const window of windows) {
      for (let timestamp = window.startTimestampMs; timestamp <= window.endTimestampMs; timestamp += config.denseIntervalMs) {
        record(timestamp, window.centerTimestampMs);
      }
      record(window.centerTimestampMs, window.centerTimestampMs);
    }
    return [...distances.entries()]
      .sort((left, right) => left[1] - right[1] || left[0] - right[0])
      .slice(0, config.maxDenseFrames)
      .map(([timestamp]) => timestamp)
      .sort((left, right) => left - right);
  }

  function validatedContact(window, samples, groundY, direction) {
    const candidates = samples
      .filter((sample) =>
        sample.timestampMs >= window.startTimestampMs && sample.timestampMs <= window.endTimestampMs,
      )
      .map((sample) => {
        const foot = footBottom(sample, window.side);
        if (!foot) return null;
        const tolerance = Math.max(1, sample.bodyScale * 0.13);
        const proximity = groundY - foot.bottomPoint.y;
        const inGroundBand = proximity >= -tolerance * 0.35 && proximity <= tolerance;
        const proximityFactor = Math.max(0, Math.min(1, 1 - Math.max(0, proximity) / tolerance));
        return {
          sample,
          foot,
          confidence: contactLandmarkConfidence(sample, window.side, foot) * (0.75 + 0.25 * proximityFactor),
          inGroundBand,
        };
      })
      .filter(Boolean)
      .filter((candidate) => candidate.inGroundBand && candidate.confidence >= config.minContactConfidence)
      .sort((left, right) =>
        right.confidence - left.confidence ||
        Math.abs(left.sample.timestampMs - window.centerTimestampMs) - Math.abs(right.sample.timestampMs - window.centerTimestampMs),
      );
    const selected = candidates[0];
    if (!selected) return null;
    return {
      timestampMs: selected.sample.timestampMs,
      windowCenterTimestampMs: window.centerTimestampMs,
      side: window.side,
      footStrikeRatio: contactFootStrikeRatio(selected.sample, window.side, direction),
      kneeAngleDegrees: contactKneeAngle(selected.sample, window.side),
      confidence: selected.confidence,
    };
  }

  function contactProxies(samples, windows, direction, confidencePenalty) {
    const byTimestamp = new Map();
    for (const window of windows) {
      const candidate = samples
        .filter((sample) =>
          sample.timestampMs >= window.startTimestampMs && sample.timestampMs <= window.endTimestampMs,
        )
        .map((sample) => ({ sample, foot: footBottom(sample, window.side) }))
        .filter(({ foot }) => foot !== null)
        .sort((left, right) =>
          Math.abs(left.sample.timestampMs - window.centerTimestampMs) -
          Math.abs(right.sample.timestampMs - window.centerTimestampMs),
        )[0];
      if (!candidate) continue;
      const confidence = Math.min(
        window.confidence,
        contactLandmarkConfidence(candidate.sample, window.side, candidate.foot),
      ) * confidencePenalty;
      const proxy = {
        timestampMs: candidate.sample.timestampMs,
        windowCenterTimestampMs: window.centerTimestampMs,
        side: window.side,
        footStrikeRatio: contactFootStrikeRatio(candidate.sample, window.side, direction),
        kneeAngleDegrees: contactKneeAngle(candidate.sample, window.side),
        confidence,
      };
      const existing = byTimestamp.get(proxy.timestampMs);
      if (!existing || proxy.confidence > existing.confidence) {
        byTimestamp.set(proxy.timestampMs, proxy);
      }
    }
    return [...byTimestamp.values()];
  }

  function contactWindowPayloads(windows, denseFrameTimes, contacts) {
    return windows.map((window) => {
      const validated = contacts.filter((contact) =>
        contact.side === window.side &&
        contact.windowCenterTimestampMs === window.centerTimestampMs &&
        contact.timestampMs >= window.startTimestampMs &&
        contact.timestampMs <= window.endTimestampMs,
      );
      return {
        side: window.side,
        startTimestampMs: window.startTimestampMs,
        centerTimestampMs: window.centerTimestampMs,
        endTimestampMs: window.endTimestampMs,
        coarseConfidence: round3(window.confidence),
        denseSampleCount: denseFrameTimes.filter((timestamp) =>
          timestamp >= window.startTimestampMs && timestamp <= window.endTimestampMs,
        ).length,
        validatedContactFrameTimestampsMs: [...new Set(validated.map((contact) => contact.timestampMs))].sort((a, b) => a - b),
        confidence: round3(average(validated.map((contact) => contact.confidence))),
      };
    });
  }

  function mergedPoseFrames(coarseFrames, denseFrames) {
    const byTimestamp = new Map();
    for (const frame of [...coarseFrames, ...denseFrames]) {
      byTimestamp.set(frame.timestampMs, frame);
    }
    return [...byTimestamp.values()].sort((left, right) => left.timestampMs - right.timestampMs);
  }

  function metricQuality(confidence, sampleCount, reason = null) {
    return {
      confidence: round3(Math.max(0, Math.min(1, confidence))),
      sampleCount,
      ...(reason ? { reason } : {}),
    };
  }

  async function analyze(bytes, name) {
    const { video, url } = await loadVideo(bytes, name);
    try {
      const durationMs = Math.round(video.duration * 1000);
      if (!Number.isFinite(durationMs) || durationMs < config.minVideoDurationMs) {
        throw createError(
          'video_too_short',
          'Please select a running clip that is at least 1.5 seconds long.',
        );
      }
      if (video.videoWidth <= 0 || video.videoHeight <= 0) {
        throw createError('web_video_decode_failed', 'The selected video has no readable frames.');
      }

      let coarse;
      try {
        coarse = await runPosePass(video, sampleTimestamps(durationMs), true);
      } catch (error) {
        if (error?.code) throw error;
        throw createError('mediapipe_pose_failed', error?.message || 'MediaPipe pose inference failed.');
      }
      if (coarse.samples.length < config.minValidFrames) {
        throw createError('no_pose_detected', 'We could not detect a clear running pose in this video.');
      }
      const sharpness = median(coarse.sharpnessValues);
      if (coarse.sharpnessValues.length < config.minSharpnessSamples ||
          sharpness === null || sharpness < config.minMedianSharpness) {
        throw createError('video_too_blurry', 'This video is too blurry for precise running coaching.');
      }

      const direction = resolveDirection(coarse.samples);
      const averageScale = Math.max(1, average(coarse.samples.map((sample) => sample.bodyScale)));
      const leanDegrees = average(
        coarse.samples.map((sample) => forwardLeanDegrees(sample, direction)),
      );
      const shoulderYs = coarse.samples.map((sample) => sample.shoulderCenter.y);
      const bounceRatio = (Math.max(...shoulderYs) - Math.min(...shoulderYs)) / averageScale;
      let candidateSet = deriveContactCandidates(coarse.samples, durationMs);
      if (candidateSet.windows.length === 0) {
        candidateSet = fallbackContactCandidates(coarse.samples, durationMs);
      }
      if (candidateSet.windows.length === 0) {
        throw createError('insufficient_contact_evidence', 'We could not verify foot-contact frames in this video.');
      }
      const denseFrameTimes = denseTimestamps(candidateSet.windows, durationMs);
      if (denseFrameTimes.length === 0) {
        throw createError('insufficient_contact_evidence', 'We could not verify foot-contact frames in this video.');
      }

      let dense;
      try {
        dense = await runPosePass(video, denseFrameTimes, false);
      } catch (error) {
        if (error?.code) throw error;
        throw createError('mediapipe_pose_failed', error?.message || 'MediaPipe pose inference failed.');
      }
      const contacts = candidateSet.windows
        .map((window) => validatedContact(window, dense.samples, candidateSet.groundY, direction))
        .filter(Boolean);
      const usesContactProxy = contacts.length < config.minValidatedContacts;
      const denseProxies = usesContactProxy
        ? contactProxies(dense.samples, candidateSet.windows, direction, 0.6)
        : [];
      const metricContacts = !usesContactProxy
        ? contacts
        : denseProxies.length > 0
          ? denseProxies
          : contactProxies(coarse.samples, candidateSet.windows, direction, 0.42);
      if (metricContacts.length === 0) {
        throw createError('insufficient_contact_evidence', 'We could not verify foot-contact frames in this video.');
      }

      const elbowAngles = coarse.samples.map(elbowAngle).filter((value) => value !== null);
      if (elbowAngles.length === 0) {
        throw createError('no_pose_detected', 'We could not detect a clear running pose in this video.');
      }
      const bodyConfidence = average(coarse.samples.map(coreConfidence));
      const armConfidenceValues = coarse.samples.map(armConfidence).filter((value) => value !== null);
      const contactConfidence = average(metricContacts.map((contact) => contact.confidence));
      const contactReason = usesContactProxy ? 'contact_phase_proxy' : null;

      return {
        durationMs,
        sampledFrames: config.sampleCount,
        validFrames: coarse.samples.length,
        direction,
        forwardLeanDegrees: round3(leanDegrees),
        verticalBounceRatio: round3(Math.max(0, bounceRatio)),
        footStrikeDistanceRatio: round3(average(metricContacts.map((contact) => contact.footStrikeRatio))),
        stanceKneeAngleDegrees: round3(average(metricContacts.map((contact) => contact.kneeAngleDegrees))),
        elbowAngleDegrees: round3(average(elbowAngles)),
        metricQualities: {
          posture: metricQuality(bodyConfidence, coarse.samples.length),
          bounce: metricQuality(bodyConfidence, coarse.samples.length),
          footStrike: metricQuality(contactConfidence, metricContacts.length, contactReason),
          kneeFlexion: metricQuality(contactConfidence, metricContacts.length, contactReason),
          armCarriage: metricQuality(average(armConfidenceValues), armConfidenceValues.length),
        },
        coarseSamples: {
          attemptedFrames: config.sampleCount,
          validFrames: coarse.samples.length,
          poseFrameCount: coarse.poseFrames.length,
        },
        denseSamples: {
          attemptedFrames: denseFrameTimes.length,
          validFrames: dense.samples.length,
          poseFrameCount: dense.poseFrames.length,
          maxFrameBudget: config.maxDenseFrames,
          targetFps: config.denseTargetFps,
        },
        contactWindows: contactWindowPayloads(candidateSet.windows, denseFrameTimes, contacts),
        validatedContactFrameTimestampsMs: [...new Set(contacts.map((contact) => contact.timestampMs))].sort((a, b) => a - b),
        contactConfidence: round3(contactConfidence),
        poseFrames: mergedPoseFrames(coarse.poseFrames, dense.poseFrames),
      };
    } finally {
      video.removeAttribute('src');
      video.load();
      URL.revokeObjectURL(url);
    }
  }

  window.runningVideoPoseAnalysis = Object.freeze({ analyze });
})();
