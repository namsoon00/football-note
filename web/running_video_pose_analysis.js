(() => {
  'use strict';

  const config = Object.freeze({
    taskVersion: '0.10.35',
    minVideoDurationMs: 1500,
    // Clips through 60 seconds keep the full 8 fps scan. Longer clips use the
    // same bounded whole-video budget plus a best-runner recovery window.
    maxVideoDurationMs: 60000,
    maxDecodableVideoDurationMs: 600000,
    minConfidence: 0.35,
    minValidFrames: 6,
    previewFrameIntervalMs: 1000,
    maxPreviewPoseFrames: 9,
    // Read the whole clip at a predictable coarse density. The release budget
    // is 8 fps through the supported 60-second capture, capped at 481 inclusive
    // timestamps so start, middle, and end are always represented.
    coarseTargetFps: 8,
    coarseFrameIntervalMs: 125,
    maxCoarseFrames: 481,
    recoveryTargetFps: 15,
    recoveryFrameIntervalMs: 67,
    maxRecoveryFrames: 120,
    minMedianSharpness: 0.018,
    minSharpnessSamples: 6,
    minBodyScalePx: 40,
    stationaryThresholdRatio: 0.12,
    denseIntervalMs: 33,
    // Coarse candidates can be up to one scan interval away from a true
    // contact. Recover a full second around each candidate at 30 fps.
    denseWindowRadiusMs: 500,
    denseTargetFps: 30,
    maxDenseFrames: 240,
    maxContactWindows: 8,
    // A single foot remains close to the floor for several coarse frames.
    // Same-side contacts faster than 320 ms apart are therefore treated as
    // one event; a real running stride returns to the same foot later.
    minContactSeparationMs: 320,
    // Left/right detections can describe the same physical landing a frame
    // apart. Collapse those before applying the three-contact reliability
    // threshold so duplicated windows cannot create a false pass.
    minDistinctContactSeparationMs: 120,
    minValidatedContacts: 3,
    minContactConfidence: 0.34,
    // A phone video can lose the far-side shoe for a frame exactly when the
    // visible foot lands. When a stable, locally-low visible foot trajectory
    // remains, use it as a lower-confidence kinematic contact rather than
    // discarding an otherwise usable stride.
    kinematicContactConfidencePenalty: 0.82,
    kinematicContactLowerPercentile: 0.65,
    kinematicContactMotionToleranceRatio: 0.025,
    groundLineSampleFraction: 0.45,
    groundLineMinimumSamples: 3,
    minimumBodyScaleRatio: 0.12,
    minimumSideViewScore: 0.46,
    maximumScaleDriftRatio: 0.34,
    maximumCutOffFrameRatio: 0.18,
    minimumVisibilityCoverage: 0.62,
    edgeCutOffMarginRatio: 0.025,
    // A contact must persist over adjacent dense samples. A single shoe point
    // near the fitted ground line is only a candidate: it can just as easily
    // be a swing leg or a tracking spike.
    contactMotionToleranceRatio: 0.035,
    contactMotionNeighborGapMs: 100,
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
  const percentile = (values, fraction) => {
    if (values.length === 0) return null;
    const sorted = [...values].sort((a, b) => a - b);
    const index = Math.max(
      0,
      Math.min(sorted.length - 1, (sorted.length - 1) * fraction),
    );
    const lower = Math.floor(index);
    const upper = Math.ceil(index);
    if (lower === upper) return sorted[lower];
    return sorted[lower] + ((sorted[upper] - sorted[lower]) * (index - lower));
  };
  const distance = (first, second) =>
    Math.hypot(first.x - second.x, first.y - second.y);
  const midpoint = (first, second) => ({
    x: (first.x + second.x) / 2,
    y: (first.y + second.y) / 2,
  });
  const centerOfPoints = (points) => ({
    x: average(points.map((point) => point.x)),
    y: average(points.map((point) => point.y)),
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

  function loadVideoUrl(url, ownsUrl = false) {
    return new Promise((resolve, reject) => {
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
        resolve({ video, url, ownsUrl });
      };
      const onError = () => {
        cleanup();
        if (ownsUrl) URL.revokeObjectURL(url);
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

  function loadVideo(bytes, name) {
    const blob = new Blob([bytes], {
      type: name && name.toLowerCase().endsWith('.mov')
        ? 'video/quicktime'
        : 'video/mp4',
    });
    return loadVideoUrl(URL.createObjectURL(blob), true);
  }

  function releaseVideo(video, url, ownsUrl) {
    video.pause();
    video.removeAttribute('src');
    video.load();
    if (ownsUrl) URL.revokeObjectURL(url);
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

  const evidenceStoreConfig = Object.freeze({
    databaseName: 'football_note_running_evidence_v1',
    storeName: 'frames',
    version: 1,
  });

  function openEvidenceDatabase() {
    return new Promise((resolve, reject) => {
      if (!('indexedDB' in window)) {
        reject(
          createError(
            'web_evidence_storage_unavailable',
            'Browser evidence storage is unavailable.',
          ),
        );
        return;
      }
      const request = window.indexedDB.open(
        evidenceStoreConfig.databaseName,
        evidenceStoreConfig.version,
      );
      request.onupgradeneeded = () => {
        const database = request.result;
        if (!database.objectStoreNames.contains(evidenceStoreConfig.storeName)) {
          database.createObjectStore(evidenceStoreConfig.storeName);
        }
      };
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(
        createError(
          'web_evidence_storage_failed',
          request.error?.message || 'Browser evidence storage failed.',
        ),
      );
      request.onblocked = () => reject(
        createError(
          'web_evidence_storage_blocked',
          'Browser evidence storage is blocked by another tab.',
        ),
      );
    });
  }

  function evidenceStoreRequest(mode, callback) {
    return openEvidenceDatabase().then((database) => new Promise((resolve, reject) => {
      const transaction = database.transaction(evidenceStoreConfig.storeName, mode);
      const store = transaction.objectStore(evidenceStoreConfig.storeName);
      let request;
      try {
        request = callback(store);
      } catch (error) {
        database.close();
        reject(error);
        return;
      }
      transaction.oncomplete = () => {
        database.close();
        resolve(request?.result ?? true);
      };
      transaction.onerror = () => {
        database.close();
        reject(
          createError(
            'web_evidence_storage_failed',
            transaction.error?.message || 'Browser evidence storage failed.',
          ),
        );
      };
      transaction.onabort = transaction.onerror;
    }));
  }

  function storeEvidenceFrame(reference, dataUrl) {
    if (!reference || typeof reference !== 'string' || !dataUrl) {
      return Promise.reject(
        createError('web_evidence_storage_failed', 'Invalid evidence frame.'),
      );
    }
    return evidenceStoreRequest('readwrite', (store) =>
      store.put({ dataUrl, savedAt: Date.now() }, reference),
    ).then(() => reference);
  }

  function readEvidenceFrame(reference) {
    if (!reference || typeof reference !== 'string') return Promise.resolve(null);
    return evidenceStoreRequest('readonly', (store) => store.get(reference))
      .then((record) => record?.dataUrl || null);
  }

  function deleteEvidenceFrames(referencesJson) {
    let references;
    try {
      references = JSON.parse(referencesJson || '[]');
    } catch (_) {
      references = [];
    }
    const keys = (Array.isArray(references) ? references : [])
      .filter((reference) => typeof reference === 'string' && reference);
    if (keys.length === 0) return Promise.resolve(true);
    return evidenceStoreRequest('readwrite', (store) => {
      let lastRequest = null;
      for (const reference of keys) {
        lastRequest = store.delete(reference);
      }
      return lastRequest;
    }).then(() => true);
  }

  function sampleTimestamps(durationMs) {
    const safeDurationMs = Math.max(0, Math.round(durationMs));
    const intervalCount = Math.max(
      1,
      Math.min(
        config.maxCoarseFrames - 1,
        Math.ceil(safeDurationMs / config.coarseFrameIntervalMs),
      ),
    );
    return Array.from({ length: intervalCount + 1 }, (_, index) =>
      Math.round((safeDurationMs * index) / intervalCount),
    );
  }

  function previewPoseTimestamps(durationMs) {
    const safeDurationMs = Math.max(0, Math.round(durationMs));
    const intervalCount = Math.max(
      1,
      Math.min(
        config.maxPreviewPoseFrames - 1,
        Math.ceil(safeDurationMs / config.previewFrameIntervalMs),
      ),
    );
    return Array.from({ length: intervalCount + 1 }, (_, index) =>
      Math.round((safeDurationMs * index) / intervalCount),
    );
  }

  function recoveryRunningMotionScore(samples) {
    if (!Array.isArray(samples) || samples.length < 3) return 0;
    let hipTravel = 0;
    let ankleTravel = 0;
    let kneeTravel = 0;
    let transitions = 0;
    const normalizedDistance = (first, second, scale) =>
      !first || !second ? 0 : distance(first, second) / scale;
    for (let sampleIndex = 1; sampleIndex < samples.length; sampleIndex += 1) {
      const previous = samples[sampleIndex - 1];
      const current = samples[sampleIndex];
      if (current.timestampMs - previous.timestampMs > 400) continue;
      const scale = Math.max(1, (previous.bodyScale + current.bodyScale) / 2);
      hipTravel += normalizedDistance(previous.hipCenter, current.hipCenter, scale);
      ankleTravel += normalizedDistance(previous.leftAnkle, current.leftAnkle, scale);
      ankleTravel += normalizedDistance(previous.rightAnkle, current.rightAnkle, scale);
      kneeTravel += normalizedDistance(previous.leftKnee, current.leftKnee, scale);
      kneeTravel += normalizedDistance(previous.rightKnee, current.rightKnee, scale);
      transitions += 1;
    }
    if (transitions === 0) return 0;
    return Math.max(0, Math.min(1,
      (hipTravel / transitions / 0.10) * 0.35 +
      (ankleTravel / transitions / 0.22) * 0.45 +
      (kneeTravel / transitions / 0.16) * 0.20
    ));
  }

  function recoveryTimestamps(samples, durationMs) {
    if (!Array.isArray(samples) || samples.length === 0) return [];
    const maximumWindowMs = 8000;
    let selectedStartMs = Math.max(
      0,
      Math.min(durationMs, samples[0].timestampMs - maximumWindowMs / 2),
    );
    let selectedScore = -1;
    for (const center of samples) {
      const startMs = Math.max(
        0,
        Math.min(durationMs - maximumWindowMs, center.timestampMs - maximumWindowMs / 2),
      );
      const endMs = Math.min(durationMs, startMs + maximumWindowMs);
      const visible = samples.filter((sample) =>
        sample.timestampMs >= startMs && sample.timestampMs <= endMs,
      );
      const scales = visible.map((sample) => sample.bodyScale).filter((value) => value > 0);
      const lower = percentile(scales, 0.10) ?? 0;
      const upper = percentile(scales, 0.90) ?? lower;
      const driftPenalty = lower > 0 ? Math.min(0.7, (upper - lower) / lower) : 0.7;
      const confidence = visible.length === 0 ? 0 : average(visible.map(coreConfidence));
      const runningMotion = recoveryRunningMotionScore(visible);
      const score = visible.length * confidence *
        (0.20 + 0.80 * runningMotion) * (1 - driftPenalty);
      if (score > selectedScore || (score === selectedScore && startMs < selectedStartMs)) {
        selectedScore = score;
        selectedStartMs = startMs;
      }
    }
    const selectedEndMs = Math.min(durationMs, selectedStartMs + maximumWindowMs);
    const intervalCount = Math.max(
      1,
      Math.min(
        config.maxRecoveryFrames - 1,
        Math.ceil((selectedEndMs - selectedStartMs) / config.recoveryFrameIntervalMs),
      ),
    );
    return Array.from({ length: intervalCount + 1 }, (_, sampleIndex) =>
      Math.round(selectedStartMs + ((selectedEndMs - selectedStartMs) * sampleIndex) / intervalCount),
    );
  }

  function mergedSamples(...groups) {
    const byTimestamp = new Map();
    for (const sample of groups.flat()) {
      const existing = byTimestamp.get(sample.timestampMs);
      if (!existing || coreConfidence(sample) > coreConfidence(existing)) {
        byTimestamp.set(sample.timestampMs, sample);
      }
    }
    return [...byTimestamp.values()].sort((left, right) => left.timestampMs - right.timestampMs);
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

  function poseFrame(landmarks, worldLandmarks, timestampMs, width, height) {
    if (!Array.isArray(landmarks) || landmarks.length < 33) return null;
    return {
      timestampMs,
      imageWidth: width,
      imageHeight: height,
      landmarks: landmarks.slice(0, 33).map((landmark, landmarkIndex) => {
        const payload = {
          index: landmarkIndex,
          x: landmark.x,
          y: landmark.y,
          z: landmark.z ?? 0,
          visibility: Number.isFinite(landmark.visibility)
            ? landmark.visibility
            : null,
          presence: Number.isFinite(landmark.presence) ? landmark.presence : null,
          confidence: landmarkConfidence(landmark),
        };
        const world = Array.isArray(worldLandmarks)
          ? worldLandmarks[landmarkIndex]
          : null;
        if (
          Number.isFinite(world?.x) &&
          Number.isFinite(world?.y) &&
          Number.isFinite(world?.z)
        ) {
          payload.worldX = world.x;
          payload.worldY = world.y;
          payload.worldZ = world.z;
          payload.worldVisibility = Number.isFinite(world.visibility)
            ? world.visibility
            : null;
          payload.worldPresence = Number.isFinite(world.presence)
            ? world.presence
            : null;
          payload.worldConfidence = landmarkConfidence(world) || payload.confidence;
        }
        return payload;
      }),
    };
  }

  function extractSample(landmarks, timestampMs, width, height) {
    const optional = (landmarkIndex) =>
      confidentPoint(landmarks, landmarkIndex, width, height);
    const leftShoulder = optional(index.leftShoulder);
    const rightShoulder = optional(index.rightShoulder);
    const leftHip = optional(index.leftHip);
    const rightHip = optional(index.rightHip);
    const leftKnee = optional(index.leftKnee);
    const rightKnee = optional(index.rightKnee);
    const leftAnkle = optional(index.leftAnkle);
    const rightAnkle = optional(index.rightAnkle);

    // Do not throw away a full frame merely because the far-side leg is
    // briefly occluded. A side-view running video commonly has only the
    // landing leg readable for several frames. The torso still establishes a
    // body scale, while lower-body measurements require a complete chain on
    // the individual side that is actually being measured.
    const shoulderPoints = [leftShoulder, rightShoulder]
      .filter(Boolean)
      .map((landmark) => landmark.point);
    const hipPoints = [leftHip, rightHip]
      .filter(Boolean)
      .map((landmark) => landmark.point);
    if (shoulderPoints.length === 0 || hipPoints.length === 0) return null;

    const shoulderCenter = centerOfPoints(shoulderPoints);
    const hipCenter = centerOfPoints(hipPoints);
    const anklePoints = [leftAnkle, rightAnkle]
      .filter(Boolean)
      .map((landmark) => landmark.point);
    const bodyScale = Math.max(
      distance(shoulderCenter, hipCenter),
      anklePoints.length === 0 ? 0 : distance(hipCenter, centerOfPoints(anklePoints)),
    );
    if (bodyScale < config.minBodyScalePx) return null;

    return {
      timestampMs,
      imageWidth: width,
      imageHeight: height,
      shoulderCenter,
      hipCenter,
      bodyScale,
      leftShoulder: leftShoulder?.point ?? null,
      rightShoulder: rightShoulder?.point ?? null,
      leftHip: leftHip?.point ?? null,
      rightHip: rightHip?.point ?? null,
      leftKnee: leftKnee?.point ?? null,
      rightKnee: rightKnee?.point ?? null,
      leftAnkle: leftAnkle?.point ?? null,
      rightAnkle: rightAnkle?.point ?? null,
      leftElbow: optional(index.leftElbow)?.point ?? null,
      rightElbow: optional(index.rightElbow)?.point ?? null,
      leftWrist: optional(index.leftWrist)?.point ?? null,
      rightWrist: optional(index.rightWrist)?.point ?? null,
      leftHeel: optional(index.leftHeel)?.point ?? null,
      rightHeel: optional(index.rightHeel)?.point ?? null,
      leftToe: optional(index.leftToe)?.point ?? null,
      rightToe: optional(index.rightToe)?.point ?? null,
      leftShoulderConfidence: leftShoulder?.confidence ?? null,
      rightShoulderConfidence: rightShoulder?.confidence ?? null,
      leftHipConfidence: leftHip?.confidence ?? null,
      rightHipConfidence: rightHip?.confidence ?? null,
      leftKneeConfidence: leftKnee?.confidence ?? null,
      rightKneeConfidence: rightKnee?.confidence ?? null,
      leftAnkleConfidence: leftAnkle?.confidence ?? null,
      rightAnkleConfidence: rightAnkle?.confidence ?? null,
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
        const worldLandmarks = result?.worldLandmarks?.[0];
        if (!landmarks) {
          await nextAnimationFrame();
          continue;
        }
        const width = video.videoWidth;
        const height = video.videoHeight;
        const frame = poseFrame(landmarks, worldLandmarks, timestampMs, width, height);
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
    if (Math.abs(movement) >= scale * config.stationaryThresholdRatio) {
      return movement > 0 ? 'leftToRight' : 'rightToLeft';
    }

    // A treadmill runner stays in the same image location, but the heel-toe
    // direction still tells us which way the runner faces. Without this
    // fallback the analyzer produced a numeric posture value and then the
    // evidence layer discarded it because the direction was "stationary".
    const footDirections = [];
    for (const sample of samples) {
      for (const side of ['left', 'right']) {
        const prefix = side === 'left' ? 'left' : 'right';
        const heel = sample[`${prefix}Heel`];
        const toe = sample[`${prefix}Toe`];
        if (!heel || !toe) continue;
        const normalizedDirection = (toe.x - heel.x) / Math.max(1, sample.bodyScale);
        if (Math.abs(normalizedDirection) >= 0.02) {
          footDirections.push(normalizedDirection);
        }
      }
    }
    const facingDirection = median(footDirections);
    if (facingDirection !== null && Math.abs(facingDirection) >= 0.02) {
      return facingDirection > 0 ? 'leftToRight' : 'rightToLeft';
    }
    return 'stationary';
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
        : 0;
    return (Math.atan2(forwardOffset, verticalTravel) * 180) / Math.PI;
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
    const hip = sample[`${prefix}Hip`];
    const knee = sample[`${prefix}Knee`];
    const hipConfidence = sample[`${prefix}HipConfidence`];
    const kneeConfidence = sample[`${prefix}KneeConfidence`];
    if (!hip || !knee ||
        !Number.isFinite(hipConfidence) || !Number.isFinite(kneeConfidence)) {
      return null;
    }
    return Math.min(foot.confidence, hipConfidence, kneeConfidence);
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
    const prefix = side === 'left' ? 'left' : 'right';
    const hip = sample[`${prefix}Hip`];
    const knee = sample[`${prefix}Knee`];
    const ankle = sample[`${prefix}Ankle`];
    if (!hip || !knee || !ankle) return null;
    return jointAngle(hip, knee, ankle);
  }

  function elbowAngle(sample) {
    const values = [];
    if (sample.leftShoulder && sample.leftElbow && sample.leftWrist) {
      values.push(jointAngle(sample.leftShoulder, sample.leftElbow, sample.leftWrist));
    }
    if (sample.rightShoulder && sample.rightElbow && sample.rightWrist) {
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
    ].filter(Number.isFinite));
  }

  function armConfidence(sample) {
    const sides = [];
    if (Number.isFinite(sample.leftShoulderConfidence) &&
        Number.isFinite(sample.leftElbowConfidence) && Number.isFinite(sample.leftWristConfidence)) {
      sides.push(average([
        sample.leftShoulderConfidence,
        sample.leftElbowConfidence,
        sample.leftWristConfidence,
      ]));
    }
    if (Number.isFinite(sample.rightShoulderConfidence) &&
        Number.isFinite(sample.rightElbowConfidence) && Number.isFinite(sample.rightWristConfidence)) {
      sides.push(average([
        sample.rightShoulderConfidence,
        sample.rightElbowConfidence,
        sample.rightWristConfidence,
      ]));
    }
    return sides.length === 0 ? null : average(sides);
  }

  function leastSquaresGroundLine(points) {
    if (points.length === 0) return { slope: 0, intercept: 0 };
    const meanX = average(points.map((point) => point.x));
    const meanY = average(points.map((point) => point.y));
    const covariance = points.reduce(
      (sum, point) => sum + (point.x - meanX) * (point.y - meanY),
      0,
    );
    const variance = points.reduce(
      (sum, point) => sum + (point.x - meanX) * (point.x - meanX),
      0,
    );
    return {
      slope: variance <= 0.0001 ? 0 : covariance / variance,
      intercept: meanY - (variance <= 0.0001 ? 0 : covariance / variance) * meanX,
    };
  }

  function groundLineForFootEvidence(footEvidence) {
    if (footEvidence.length === 0) return { slope: 0, intercept: 0 };
    // A scalar lowest-pixel baseline breaks as soon as the camera is slightly
    // tilted. Fit the lower envelope of both feet instead, then reject the
    // outliers from a swing foot or a mistracked shoe point.
    const points = footEvidence.map(({ sample, foot }) => ({
      x: foot.bottomPoint.x,
      y: foot.bottomPoint.y,
      bodyScale: sample.bodyScale,
    }));
    const lowerEnvelope = [...points]
      .sort((left, right) => right.y - left.y)
      .slice(
        0,
        Math.min(
          points.length,
          Math.max(
            config.groundLineMinimumSamples,
            Math.ceil(points.length * config.groundLineSampleFraction),
          ),
        ),
      );
    let line = leastSquaresGroundLine(lowerEnvelope);
    const residuals = lowerEnvelope.map((point) => point.y - (line.slope * point.x + line.intercept));
    const residualCenter = median(residuals) ?? 0;
    const medianDeviation = median(residuals.map((residual) => Math.abs(residual - residualCenter))) ?? 0;
    const averageScale = Math.max(1, average(lowerEnvelope.map((point) => point.bodyScale)));
    const residualTolerance = Math.max(averageScale * 0.025, medianDeviation * 2.5);
    const inliers = lowerEnvelope.filter((point) =>
      Math.abs(point.y - (line.slope * point.x + line.intercept) - residualCenter) <= residualTolerance,
    );
    if (inliers.length >= 2) line = leastSquaresGroundLine(inliers);
    return line;
  }

  function groundYAt(groundLine, x) {
    return groundLine.slope * x + groundLine.intercept;
  }

  function groundGap(groundLine, foot) {
    return groundYAt(groundLine, foot.bottomPoint.x) - foot.bottomPoint.y;
  }

  function selectContactCandidateWindows(candidates) {
    const deduped = [];
    for (const candidate of [...candidates].sort(
      (left, right) => right.confidence - left.confidence || left.centerTimestampMs - right.centerTimestampMs,
    )) {
      const duplicatesSameStep = deduped.some((selectedCandidate) =>
        selectedCandidate.side === candidate.side &&
        Math.abs(selectedCandidate.centerTimestampMs - candidate.centerTimestampMs) <
          config.minContactSeparationMs,
      );
      if (!duplicatesSameStep) deduped.push(candidate);
    }
    if (deduped.length <= config.maxContactWindows) {
      return deduped.sort((left, right) => left.centerTimestampMs - right.centerTimestampMs);
    }

    const ordered = deduped.sort((left, right) => left.centerTimestampMs - right.centerTimestampMs);
    const firstTime = ordered[0].centerTimestampMs;
    const lastTime = ordered[ordered.length - 1].centerTimestampMs;
    const selected = [];
    const selectedIndexes = new Set();
    for (let slot = 0; slot < config.maxContactWindows; slot += 1) {
      const target = config.maxContactWindows <= 1
        ? (firstTime + lastTime) / 2
        : firstTime + ((lastTime - firstTime) * slot) / (config.maxContactWindows - 1);
      let bestIndex = -1;
      for (let index = 0; index < ordered.length; index += 1) {
        if (selectedIndexes.has(index)) continue;
        if (bestIndex < 0) {
          bestIndex = index;
          continue;
        }
        const current = ordered[index];
        const best = ordered[bestIndex];
        const distance = Math.abs(current.centerTimestampMs - target);
        const bestDistance = Math.abs(best.centerTimestampMs - target);
        if (distance < bestDistance ||
            (distance === bestDistance && current.confidence > best.confidence) ||
            (distance === bestDistance && current.confidence === best.confidence &&
              current.centerTimestampMs < best.centerTimestampMs)) {
          bestIndex = index;
        }
      }
      if (bestIndex >= 0) {
        selectedIndexes.add(bestIndex);
        selected.push(ordered[bestIndex]);
      }
    }
    return selected.sort((left, right) => left.centerTimestampMs - right.centerTimestampMs);
  }

  function deriveContactCandidates(samples, durationMs) {
    const footEvidence = [];
    for (const sample of samples) {
      for (const side of ['left', 'right']) {
        const foot = footBottom(sample, side);
        if (foot) footEvidence.push({ sample, side, foot });
      }
    }
    if (footEvidence.length === 0) return { windows: [], groundLine: { slope: 0, intercept: 0 } };
    const groundLine = groundLineForFootEvidence(footEvidence);
    const averageScale = Math.max(1, average(samples.map((sample) => sample.bodyScale)));
    const groundTolerance = averageScale * 0.15;
    const localTolerance = averageScale * 0.035;
    const candidates = [];

    for (const side of ['left', 'right']) {
      const sideEvidence = footEvidence.filter((item) => item.side === side);
      for (let itemIndex = 0; itemIndex < sideEvidence.length; itemIndex += 1) {
        const current = sideEvidence[itemIndex];
        const bottomY = current.foot.bottomPoint.y;
        const previousY = sideEvidence[itemIndex - 1]?.foot.bottomPoint.y;
        const nextY = sideEvidence[itemIndex + 1]?.foot.bottomPoint.y;
        const gap = groundGap(groundLine, current.foot);
        const nearGround =
          gap >= -groundTolerance * 0.55 && gap <= groundTolerance * 1.1;
        const localExtremum =
          (previousY === undefined || bottomY >= previousY - localTolerance) &&
          (nextY === undefined || bottomY >= nextY - localTolerance);
        if (!nearGround || !localExtremum) continue;
        const proximity = Math.max(0, gap);
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

    return {
      windows: selectContactCandidateWindows(candidates),
      groundLine,
    };
  }

  function fallbackContactCandidates(samples, durationMs) {
    const footEvidence = [];
    const candidates = [];
    const averageScale = Math.max(1, average(samples.map((sample) => sample.bodyScale)));
    const localTolerance = averageScale * config.kinematicContactMotionToleranceRatio;
    for (const side of ['left', 'right']) {
      const sideEvidence = samples
        .map((sample) => ({ sample, foot: footBottom(sample, side) }))
        .filter(({ foot }) => foot !== null)
        .sort((left, right) => left.sample.timestampMs - right.sample.timestampMs);
      for (const item of sideEvidence) {
        footEvidence.push({ sample: item.sample, side, foot: item.foot });
      }
      const lowerEnvelopeY = percentile(
        sideEvidence.map((item) => item.foot.bottomPoint.y),
        config.kinematicContactLowerPercentile,
      );
      if (lowerEnvelopeY === null) continue;
      for (let itemIndex = 0; itemIndex < sideEvidence.length; itemIndex += 1) {
        const current = sideEvidence[itemIndex];
        const currentY = current.foot.bottomPoint.y;
        const previous = sideEvidence[itemIndex - 1];
        const next = sideEvidence[itemIndex + 1];
        const closeToPrevious = previous &&
          current.sample.timestampMs - previous.sample.timestampMs <=
            config.coarseFrameIntervalMs * 2;
        const closeToNext = next &&
          next.sample.timestampMs - current.sample.timestampMs <=
            config.coarseFrameIntervalMs * 2;
        const locallyLow =
          (!closeToPrevious || currentY >= previous.foot.bottomPoint.y - localTolerance) &&
          (!closeToNext || currentY >= next.foot.bottomPoint.y - localTolerance);
        if (currentY < lowerEnvelopeY || !locallyLow) continue;
        candidates.push({
          side,
          centerTimestampMs: current.sample.timestampMs,
          startTimestampMs: Math.max(0, current.sample.timestampMs - config.denseWindowRadiusMs),
          endTimestampMs: Math.min(durationMs, current.sample.timestampMs + config.denseWindowRadiusMs),
          confidence: current.foot.confidence,
        });
      }
    }
    return {
      windows: selectContactCandidateWindows(candidates),
      groundLine: groundLineForFootEvidence(footEvidence),
    };
  }

  function mergedContactCandidateSet(detected, fallback) {
    return {
      windows: selectContactCandidateWindows([
        ...detected.windows,
        ...fallback.windows,
      ]),
      groundLine: detected.windows.length > 0
        ? detected.groundLine
        : fallback.groundLine,
    };
  }

  function denseTimestamps(windows, durationMs) {
    // A global "closest to coarse center" sort had an unfortunate failure
    // mode: with several contact candidates it spent the entire dense budget
    // around the coarse centers, never reaching the true contact near either
    // edge of a window. Reserve a small, evenly distributed budget for every
    // candidate window instead. This is still bounded by maxDenseFrames.
    const selectedWindows = windows.slice(0, config.maxContactWindows);
    if (selectedWindows.length === 0) return [];
    const perWindowBudget = Math.max(
      3,
      Math.floor(config.maxDenseFrames / selectedWindows.length),
    );
    const timestamps = new Set();
    const add = (timestampMs) => {
      timestamps.add(Math.round(Math.max(0, Math.min(durationMs, timestampMs))));
    };

    for (const window of selectedWindows) {
      const frameTimes = [];
      for (
        let timestamp = window.startTimestampMs;
        timestamp <= window.endTimestampMs;
        timestamp += config.denseIntervalMs
      ) {
        frameTimes.push(timestamp);
      }
      if (frameTimes.length === 0 ||
          frameTimes[frameTimes.length - 1] !== window.endTimestampMs) {
        frameTimes.push(window.endTimestampMs);
      }
      const selected = new Set();
      const nearestToCenter = [...frameTimes].sort((left, right) =>
        Math.abs(left - window.centerTimestampMs) -
          Math.abs(right - window.centerTimestampMs) ||
        left - right,
      );
      for (const timestamp of nearestToCenter.slice(0, Math.min(3, perWindowBudget))) {
        selected.add(timestamp);
      }
      const remaining = perWindowBudget - selected.size;
      for (let index = 0; index < remaining; index += 1) {
        const fraction = remaining <= 1 ? 0.5 : index / (remaining - 1);
        selected.add(frameTimes[Math.round((frameTimes.length - 1) * fraction)]);
      }
      // Rounded evenly-spaced indices can coincide in short windows. Fill the
      // spare slots with center-near frames before moving to another window.
      for (const timestamp of nearestToCenter) {
        if (selected.size >= perWindowBudget) break;
        selected.add(timestamp);
      }
      for (const timestamp of selected) add(timestamp);
    }
    return [...timestamps]
      .sort((left, right) => left - right)
      .slice(0, config.maxDenseFrames);
  }

  function incrementReason(rejectedFrameCounts, reason) {
    rejectedFrameCounts[reason] = (rejectedFrameCounts[reason] ?? 0) + 1;
  }

  function isEligibleContactRecord(record) {
    return record.inGroundBand && record.confidence >= config.minContactConfidence;
  }

  function isTemporalNeighbor(current, neighbor) {
    return neighbor &&
      Math.abs(current.sample.timestampMs - neighbor.sample.timestampMs) <=
        config.contactMotionNeighborGapMs;
  }

  function enteredGroundBand(current, previous) {
    return isTemporalNeighbor(current, previous) &&
      previous.groundGap > current.tolerance;
  }

  function contactMotionReason(records, index) {
    const current = records[index];
    const previous = records[index - 1];
    const next = records[index + 1];
    const hasPrevious = isTemporalNeighbor(current, previous);
    const hasNext = isTemporalNeighbor(current, next);
    if (!hasPrevious && !hasNext) return 'insufficient_motion_window';
    const tolerance = Math.max(1, current.sample.bodyScale * config.contactMotionToleranceRatio);
    const currentY = current.foot.bottomPoint.y;
    const isLowestNearPrevious = !hasPrevious || currentY >= previous.foot.bottomPoint.y - tolerance;
    const isLowestNearNext = !hasNext || currentY >= next.foot.bottomPoint.y - tolerance;
    if (!isLowestNearPrevious || !isLowestNearNext) return 'unstable_foot_motion';

    // Do not promote an isolated near-ground frame to initial contact. We
    // need at least one neighbouring, eligible ground-band frame from the
    // same tracked foot. This catches the common failure where the flexed
    // swing leg happens to be the lowest landmark in one frame.
    const hasGroundBandPersistence = [previous, next].some((neighbor) =>
      isTemporalNeighbor(current, neighbor) && isEligibleContactRecord(neighbor),
    );
    return hasGroundBandPersistence ? null : 'insufficient_contact_persistence';
  }

  function kinematicContactCandidate(records, index, lowerEnvelopeY) {
    const current = records[index];
    if (current.confidence < config.minContactConfidence ||
        current.foot.bottomPoint.y < lowerEnvelopeY) {
      return false;
    }
    const previous = records[index - 1];
    const next = records[index + 1];
    const hasPrevious = isTemporalNeighbor(current, previous);
    const hasNext = isTemporalNeighbor(current, next);
    if (!hasPrevious && !hasNext) return false;

    const tolerance = Math.max(
      1,
      current.sample.bodyScale * config.kinematicContactMotionToleranceRatio,
    );
    const currentY = current.foot.bottomPoint.y;
    const isLowestNearPrevious = !hasPrevious || currentY >= previous.foot.bottomPoint.y - tolerance;
    const isLowestNearNext = !hasNext || currentY >= next.foot.bottomPoint.y - tolerance;
    return isLowestNearPrevious && isLowestNearNext;
  }

  function contactSelectionScore(timestampMs, confidence, window) {
    const distanceRatio = Math.min(
      1,
      Math.abs(timestampMs - window.centerTimestampMs) /
        Math.max(1, config.denseWindowRadiusMs),
    );
    return confidence * (1 - (distanceRatio * 0.65));
  }

  function contactPayload(selected, window, side, direction, confidence, selectionMethod) {
    const kneeAngleDegrees = contactKneeAngle(selected.sample, side);
    if (kneeAngleDegrees === null) return null;
    return {
      timestampMs: selected.sample.timestampMs,
      windowCenterTimestampMs: window.centerTimestampMs,
      side,
      footStrikeRatio: contactFootStrikeRatio(selected.sample, side, direction),
      kneeAngleDegrees,
      confidence,
      selectionMethod,
    };
  }

  function validatedContactForSide(window, side, samples, groundLine, direction) {
    const rejectedFrameCounts = {};
    const records = [];
    for (const sample of samples) {
      if (sample.timestampMs < window.startTimestampMs || sample.timestampMs > window.endTimestampMs) continue;
      const foot = footBottom(sample, side);
      if (!foot) {
        incrementReason(rejectedFrameCounts, 'missing_foot_landmark');
        continue;
      }
      const landmarkConfidence = contactLandmarkConfidence(sample, side, foot);
      if (landmarkConfidence === null) {
        incrementReason(rejectedFrameCounts, 'missing_contact_joint_chain');
        continue;
      }
      const tolerance = Math.max(1, sample.bodyScale * 0.16);
      const gap = groundGap(groundLine, foot);
      const inGroundBand = gap >= -tolerance * 0.55 && gap <= tolerance * 1.1;
      const proximityFactor = Math.max(0, Math.min(1, 1 - Math.max(0, gap) / tolerance));
      records.push({
        sample,
        foot,
        groundGap: gap,
        tolerance,
        confidence: landmarkConfidence * (0.75 + 0.25 * proximityFactor),
        inGroundBand,
      });
    }

    const temporalCandidates = [];
    const persistentCandidates = [];
    for (let recordIndex = 0; recordIndex < records.length; recordIndex += 1) {
      const candidate = records[recordIndex];
      if (!candidate.inGroundBand) {
        incrementReason(rejectedFrameCounts, 'outside_ground_band');
        continue;
      }
      if (!isEligibleContactRecord(candidate)) {
        incrementReason(rejectedFrameCounts, 'low_contact_confidence');
        continue;
      }
      const motionReason = contactMotionReason(records, recordIndex);
      if (motionReason) {
        incrementReason(rejectedFrameCounts, motionReason);
        continue;
      }
      if (enteredGroundBand(candidate, records[recordIndex - 1])) {
        temporalCandidates.push(candidate);
      } else {
        persistentCandidates.push(candidate);
      }
    }

    const candidates = temporalCandidates.length > 0
      ? temporalCandidates
      : persistentCandidates;
    candidates.sort((left, right) =>
      contactSelectionScore(right.sample.timestampMs, right.confidence, window) -
        contactSelectionScore(left.sample.timestampMs, left.confidence, window) ||
      right.confidence - left.confidence ||
      Math.abs(left.sample.timestampMs - window.centerTimestampMs) - Math.abs(right.sample.timestampMs - window.centerTimestampMs),
    );
    const selected = candidates[0];
    const kinematicLowerEnvelope = percentile(
      records.map((record) => record.foot.bottomPoint.y),
      config.kinematicContactLowerPercentile,
    );
    const kinematicCandidates = kinematicLowerEnvelope === null
      ? []
      : records.filter((record, recordIndex) =>
          kinematicContactCandidate(records, recordIndex, kinematicLowerEnvelope),
        );
    const kinematicSelection = [...kinematicCandidates].sort((left, right) =>
      contactSelectionScore(right.sample.timestampMs, right.confidence, window) -
        contactSelectionScore(left.sample.timestampMs, left.confidence, window) ||
      right.confidence - left.confidence ||
      Math.abs(left.sample.timestampMs - window.centerTimestampMs) -
        Math.abs(right.sample.timestampMs - window.centerTimestampMs),
    )[0];
    const strictContact = selected
      ? contactPayload(selected, window, side, direction, selected.confidence, 'ground')
      : null;
    const kinematicContact = strictContact || !kinematicSelection
      ? null
      : contactPayload(
          kinematicSelection,
          window,
          side,
          direction,
          kinematicSelection.confidence * config.kinematicContactConfidencePenalty,
          'kinematic',
        );
    if (kinematicContact) {
      incrementReason(rejectedFrameCounts, 'kinematic_contact_estimate');
    }
    return {
      contact: strictContact ?? kinematicContact,
      candidateFrameCount: Math.max(
        records.filter((record) => record.inGroundBand).length,
        kinematicCandidates.length,
      ),
      rejectedFrameCounts,
    };
  }

  function mergeRejectedFrameCounts(...counts) {
    const merged = {};
    for (const count of counts) {
      for (const [reason, value] of Object.entries(count)) {
        merged[reason] = (merged[reason] ?? 0) + value;
      }
    }
    return merged;
  }

  function validatedContact(window, samples, groundLine, direction) {
    const otherSide = window.side === 'left' ? 'right' : 'left';
    const preferred = validatedContactForSide(
      window,
      window.side,
      samples,
      groundLine,
      direction,
    );
    const alternate = validatedContactForSide(
      window,
      otherSide,
      samples,
      groundLine,
      direction,
    );
    const options = [preferred.contact, alternate.contact].filter(Boolean);
    options.sort((left, right) => {
      const preferredBiasLeft = left.side === window.side ? 1.03 : 1;
      const preferredBiasRight = right.side === window.side ? 1.03 : 1;
      return (
        contactSelectionScore(right.timestampMs, right.confidence, window) * preferredBiasRight -
        contactSelectionScore(left.timestampMs, left.confidence, window) * preferredBiasLeft
      );
    });
    return {
      contact: options[0] ?? null,
      candidateFrameCount: Math.max(
        preferred.candidateFrameCount,
        alternate.candidateFrameCount,
      ),
      rejectedFrameCounts: mergeRejectedFrameCounts(
        preferred.rejectedFrameCounts,
        alternate.rejectedFrameCounts,
      ),
    };
  }

  function deduplicateContactValidations(validations) {
    const selectedIndexes = [];
    const rankedIndexes = validations
      .map((validation, validationIndex) => ({ validation, validationIndex }))
      .filter(({ validation }) => validation.contact)
      .sort((left, right) =>
        right.validation.contact.confidence - left.validation.contact.confidence ||
        left.validation.contact.timestampMs - right.validation.contact.timestampMs,
      );
    for (const item of rankedIndexes) {
      const timestampMs = item.validation.contact.timestampMs;
      const isSameEvent = selectedIndexes.some((selectedIndex) =>
        Math.abs(validations[selectedIndex].contact.timestampMs - timestampMs) <
          config.minDistinctContactSeparationMs,
      );
      if (!isSameEvent) selectedIndexes.push(item.validationIndex);
    }
    const selected = new Set(selectedIndexes);
    return validations.map((validation, validationIndex) =>
      validation.contact && !selected.has(validationIndex)
        ? { ...validation, contact: null }
        : validation,
    );
  }

  function deduplicateContacts(contacts) {
    const selected = [];
    for (const contact of [...contacts].sort(
      (left, right) => right.confidence - left.confidence || left.timestampMs - right.timestampMs,
    )) {
      if (selected.some((item) =>
        Math.abs(item.timestampMs - contact.timestampMs) <
          config.minDistinctContactSeparationMs,
      )) {
        continue;
      }
      selected.push(contact);
    }
    return selected.sort((left, right) => left.timestampMs - right.timestampMs);
  }

  function contactProxies(samples, windows, direction, confidencePenalty) {
    const proxies = [];
    for (const window of windows) {
      const candidate = samples
        .filter((sample) =>
          sample.timestampMs >= window.startTimestampMs && sample.timestampMs <= window.endTimestampMs,
        )
        .flatMap((sample) => ['left', 'right'].map((side) => {
          const foot = footBottom(sample, side);
          const landmarkConfidence = foot
            ? contactLandmarkConfidence(sample, side, foot)
            : null;
          return { sample, side, foot, landmarkConfidence };
        }))
        .filter(({ foot, landmarkConfidence }) =>
          foot !== null && landmarkConfidence !== null,
        )
        .sort((left, right) =>
          Math.abs(left.sample.timestampMs - window.centerTimestampMs) -
            Math.abs(right.sample.timestampMs - window.centerTimestampMs) ||
          right.landmarkConfidence - left.landmarkConfidence,
        )[0];
      if (!candidate) continue;
      const confidence = Math.min(
        window.confidence,
        candidate.landmarkConfidence,
      ) * confidencePenalty;
      const kneeAngleDegrees = contactKneeAngle(candidate.sample, candidate.side);
      if (kneeAngleDegrees === null) continue;
      const proxy = {
        timestampMs: candidate.sample.timestampMs,
        windowCenterTimestampMs: window.centerTimestampMs,
        side: candidate.side,
        footStrikeRatio: contactFootStrikeRatio(candidate.sample, candidate.side, direction),
        kneeAngleDegrees,
        confidence,
      };
      proxies.push(proxy);
    }
    return deduplicateContacts(proxies);
  }

  function contactWindowPayloads(windows, denseFrameTimes, validations) {
    return windows.map((window, windowIndex) => {
      const validation = validations[windowIndex];
      const contact = validation?.contact;
      const isEstimated = contact?.selectionMethod === 'kinematic';
      return {
        side: contact?.side ?? window.side,
        startTimestampMs: window.startTimestampMs,
        centerTimestampMs: window.centerTimestampMs,
        endTimestampMs: window.endTimestampMs,
        coarseConfidence: round3(window.confidence),
        denseSampleCount: denseFrameTimes.filter((timestamp) =>
          timestamp >= window.startTimestampMs && timestamp <= window.endTimestampMs,
        ).length,
        candidateFrameCount: validation?.candidateFrameCount ?? 0,
        rejectedFrameCounts: validation?.rejectedFrameCounts ?? {},
        validatedContactFrameTimestampsMs: contact && !isEstimated ? [contact.timestampMs] : [],
        estimatedContactFrameTimestampsMs: isEstimated ? [contact.timestampMs] : [],
        selectionMethod: contact?.selectionMethod ?? null,
        confidence: round3(contact && !isEstimated ? contact.confidence : 0),
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

  function presentPointCount(sample, points) {
    return points.filter((point) => point !== null && point !== undefined).length;
  }

  function sideViewWidthRatio(sample) {
    const widths = [];
    if (sample.leftShoulder && sample.rightShoulder) {
      widths.push(distance(sample.leftShoulder, sample.rightShoulder) / Math.max(1, sample.bodyScale));
    }
    if (sample.leftHip && sample.rightHip) {
      widths.push(distance(sample.leftHip, sample.rightHip) / Math.max(1, sample.bodyScale));
    }
    return widths.length === 0 ? null : average(widths);
  }

  function sampleTouchesFrameEdge(sample) {
    const marginX = sample.imageWidth * config.edgeCutOffMarginRatio;
    const marginY = sample.imageHeight * config.edgeCutOffMarginRatio;
    const points = [
      sample.leftShoulder,
      sample.rightShoulder,
      sample.leftHip,
      sample.rightHip,
      sample.leftKnee,
      sample.rightKnee,
      sample.leftAnkle,
      sample.rightAnkle,
      sample.leftHeel,
      sample.rightHeel,
      sample.leftToe,
      sample.rightToe,
    ].filter(Boolean);
    return points.some((point) =>
      point.x <= marginX ||
      point.x >= sample.imageWidth - marginX ||
      point.y <= marginY ||
      point.y >= sample.imageHeight - marginY,
    );
  }

  function perspectiveQuality(samples) {
    if (samples.length === 0) {
      return {
        evaluatedFrameCount: 0,
        medianBodyScaleRatio: 0,
        minBodyScaleRatio: 0,
        visibilityCoverage: 0,
        sideViewScore: 0,
        scaleDriftRatio: 0,
        cutOffFrameRatio: 0,
        issues: [],
      };
    }
    const bodyScaleRatios = samples.map((sample) =>
      sample.bodyScale / Math.max(1, Math.min(sample.imageWidth, sample.imageHeight)),
    );
    const medianBodyScaleRatio = median(bodyScaleRatios) ?? 0;
    const minBodyScaleRatio = Math.min(...bodyScaleRatios);
    const scales = samples.map((sample) => sample.bodyScale).filter((value) => value > 0);
    const lowerScale = percentile(scales, 0.10) ?? 0;
    const upperScale = percentile(scales, 0.90) ?? lowerScale;
    const scaleDriftRatio = lowerScale <= 0 ? 0 : (upperScale - lowerScale) / lowerScale;
    const visibilityCoverage = average(samples.map((sample) =>
      presentPointCount(sample, [
        sample.leftShoulder,
        sample.rightShoulder,
        sample.leftHip,
        sample.rightHip,
        sample.leftKnee,
        sample.rightKnee,
        sample.leftAnkle,
        sample.rightAnkle,
      ]) / 8,
    ));
    const sideRatios = samples.map(sideViewWidthRatio).filter((value) => value !== null);
    const sideWidthRatio = median(sideRatios) ?? 1;
    const sideViewScore = Math.max(0, Math.min(1, 1 - ((sideWidthRatio - 0.18) / 0.34)));
    const cutOffFrameRatio =
      samples.filter(sampleTouchesFrameEdge).length / Math.max(1, samples.length);
    const issues = [];
    if (medianBodyScaleRatio < config.minimumBodyScaleRatio ||
        minBodyScaleRatio < config.minimumBodyScaleRatio * 0.72) {
      issues.push('tooSmall');
    }
    if (sideViewScore < config.minimumSideViewScore) {
      issues.push('notSideOn');
    }
    if (cutOffFrameRatio > config.maximumCutOffFrameRatio ||
        visibilityCoverage < config.minimumVisibilityCoverage) {
      issues.push('bodyCutOff');
    }
    if (scaleDriftRatio > config.maximumScaleDriftRatio) {
      issues.push('scaleDrift');
    }
    return {
      evaluatedFrameCount: samples.length,
      medianBodyScaleRatio: round3(medianBodyScaleRatio),
      minBodyScaleRatio: round3(minBodyScaleRatio),
      visibilityCoverage: round3(visibilityCoverage),
      sideViewScore: round3(sideViewScore),
      scaleDriftRatio: round3(scaleDriftRatio),
      cutOffFrameRatio: round3(cutOffFrameRatio),
      issues,
    };
  }

  function perspectiveReasonForMetric(quality, metric) {
    if (!quality || !Array.isArray(quality.issues)) return null;
    if (quality.issues.includes('tooSmall')) return 'too_small_runner';
    if (quality.issues.includes('bodyCutOff')) return 'body_cut_off';
    const isLowerBody = metric === 'footStrike' || metric === 'kneeFlexion';
    if (isLowerBody && quality.issues.includes('notSideOn')) return 'not_side_on';
    if ((isLowerBody || metric === 'bounce') && quality.issues.includes('scaleDrift')) {
      return 'scale_drift';
    }
    return null;
  }

  function applyPerspectiveQuality(metric, baseQuality, quality) {
    const reason = perspectiveReasonForMetric(quality, metric);
    if (!reason) return baseQuality;
    return metricQuality(
      Math.min(baseQuality.confidence, reason === 'too_small_runner' ? 0 : 0.55),
      baseQuality.sampleCount,
      reason,
    );
  }

  async function extractEvidenceFramesFromLoader(load, timestampsJson, jpegQuality = 72) {
    let timestamps;
    try {
      timestamps = JSON.parse(timestampsJson || '[]');
    } catch (_) {
      timestamps = [];
    }
    const uniqueTimestamps = [...new Set(
      (Array.isArray(timestamps) ? timestamps : [])
        .map((value) => Math.round(Number(value)))
        .filter((value) => Number.isFinite(value) && value >= 0),
    )].sort((left, right) => left - right).slice(0, 24);
    if (uniqueTimestamps.length === 0) return [];
    const { video, url, ownsUrl } = await load();
    try {
      const sourceWidth = video.videoWidth;
      const sourceHeight = video.videoHeight;
      if (sourceWidth <= 0 || sourceHeight <= 0) return [];
      const maximumDimension = 640;
      const safeQuality = Math.max(45, Math.min(Number(jpegQuality) || 72, 92)) / 100;
      const scale = Math.min(1, maximumDimension / Math.max(sourceWidth, sourceHeight));
      const width = Math.max(1, Math.round(sourceWidth * scale));
      const height = Math.max(1, Math.round(sourceHeight * scale));
      const canvas = document.createElement('canvas');
      canvas.width = width;
      canvas.height = height;
      const context = canvas.getContext('2d');
      if (!context) return [];
      const frames = [];
      for (const timestampMs of uniqueTimestamps) {
        await seekVideo(video, timestampMs / 1000);
        context.drawImage(video, 0, 0, width, height);
        frames.push({
          timestampMs,
          width,
          height,
          dataUrl: canvas.toDataURL('image/jpeg', safeQuality),
        });
      }
      return frames;
    } finally {
      releaseVideo(video, url, ownsUrl);
    }
  }

  function extractEvidenceFrames(bytes, name, timestampsJson, jpegQuality) {
    return extractEvidenceFramesFromLoader(
      () => loadVideo(bytes, name),
      timestampsJson,
      jpegQuality,
    );
  }

  function extractEvidenceFramesFromUrl(url, name, timestampsJson, jpegQuality) {
    return extractEvidenceFramesFromLoader(
      () => loadVideoUrl(url, false),
      timestampsJson,
      jpegQuality,
    );
  }

  async function analyzeFromLoader(load) {
    const { video, url, ownsUrl } = await load();
    try {
      const durationMs = Math.round(video.duration * 1000);
      if (!Number.isFinite(durationMs) || durationMs < config.minVideoDurationMs) {
        throw createError(
          'video_too_short',
          'Please select a running clip that is at least 1.5 seconds long.',
        );
      }
      if (durationMs > config.maxDecodableVideoDurationMs) {
        throw createError(
          'video_too_long',
          'This video is longer than the bounded on-device decoding budget.',
        );
      }
      if (video.videoWidth <= 0 || video.videoHeight <= 0) {
        throw createError('web_video_decode_failed', 'The selected video has no readable frames.');
      }

      const coarseFrameTimes = sampleTimestamps(durationMs);
      let coarse;
      try {
        coarse = await runPosePass(video, coarseFrameTimes, true);
      } catch (error) {
        if (error?.code) throw error;
        throw createError('mediapipe_pose_failed', error?.message || 'MediaPipe pose inference failed.');
      }
      if (coarse.samples.length < 2) {
        throw createError('no_pose_detected', 'We could not detect a clear running pose in this video.');
      }
      const sharpness = median(coarse.sharpnessValues);
      const hasUsableSharpness = coarse.sharpnessValues.length >= config.minSharpnessSamples &&
        sharpness !== null && sharpness >= config.minMedianSharpness;

      let analysisSamples = coarse.samples;
      let recovery = { samples: [], poseFrames: [], sharpnessValues: [] };
      let recoveryFrameTimes = [];
      let perspective = perspectiveQuality(analysisSamples);
      let initialCandidateSet = mergedContactCandidateSet(
        deriveContactCandidates(analysisSamples, durationMs),
        fallbackContactCandidates(analysisSamples, durationMs),
      );
      const needsRecovery =
        durationMs > config.maxVideoDurationMs ||
        initialCandidateSet.windows.length < config.minValidatedContacts ||
        perspective.scaleDriftRatio > config.maximumScaleDriftRatio ||
        analysisSamples.length / Math.max(1, coarseFrameTimes.length) < 0.45;
      if (needsRecovery) {
        recoveryFrameTimes = recoveryTimestamps(analysisSamples, durationMs);
        if (recoveryFrameTimes.length > 0) {
          recovery = await runPosePass(video, recoveryFrameTimes, false);
          analysisSamples = mergedSamples(analysisSamples, recovery.samples);
          perspective = perspectiveQuality(analysisSamples);
          initialCandidateSet = mergedContactCandidateSet(
            deriveContactCandidates(analysisSamples, durationMs),
            fallbackContactCandidates(analysisSamples, durationMs),
          );
        }
      }
      const direction = resolveDirection(analysisSamples);
      const leanDegrees = average(
        analysisSamples.map((sample) => forwardLeanDegrees(sample, direction)),
      );
      // Use the central 80% of body-scale-normalized shoulder positions.
      // A single tracking spike should not make a compact stride look like an
      // exaggerated jump.
      const normalizedShoulderYs = analysisSamples.map(
        (sample) => sample.shoulderCenter.y / Math.max(1, sample.bodyScale),
      );
      const lowerBouncePosition = percentile(normalizedShoulderYs, 0.10);
      const upperBouncePosition = percentile(normalizedShoulderYs, 0.90);
      const bounceRatio = lowerBouncePosition === null || upperBouncePosition === null
        ? 0
        : Math.max(0, upperBouncePosition - lowerBouncePosition);
      const candidateSet = initialCandidateSet;
      const denseFrameTimes = denseTimestamps(candidateSet.windows, durationMs);

      let dense = { samples: [], poseFrames: [], sharpnessValues: [] };
      if (denseFrameTimes.length > 0) {
        try {
          dense = await runPosePass(video, denseFrameTimes, false);
        } catch (error) {
          if (error?.code) throw error;
          throw createError('mediapipe_pose_failed', error?.message || 'MediaPipe pose inference failed.');
        }
      }
      const contactValidations = deduplicateContactValidations(
        candidateSet.windows.map((window) =>
          validatedContact(window, dense.samples, candidateSet.groundLine, direction),
        ),
      );
      const contacts = contactValidations
        .map((validation) => validation.contact)
        .filter(Boolean);
      const confirmedContacts = contacts.filter(
        (contact) => contact.selectionMethod !== 'kinematic',
      );
      const estimatedContacts = contacts.filter(
        (contact) => contact.selectionMethod === 'kinematic',
      );
      const usesKinematicContactEstimate = estimatedContacts.length > 0;
      // One or two verified contacts are not enough for a score, cadence, or
      // left/right comparison, but they are still real measured observations.
      // Keep them distinct from the old proxy path so the UI can show the
      // exact frame and value without pretending it is a complete assessment.
      const usesContactProxy = contacts.length === 0;
      const hasCompleteContactSample = confirmedContacts.length >= config.minValidatedContacts;
      const denseProxies = usesContactProxy
        ? contactProxies(dense.samples, candidateSet.windows, direction, 0.6)
        : [];
      const metricContacts = !usesContactProxy
        ? contacts
        : denseProxies.length > 0
          ? denseProxies
          : contactProxies(analysisSamples, candidateSet.windows, direction, 0.42);

      const elbowAngles = analysisSamples.map(elbowAngle).filter((value) => value !== null);
      const bodyConfidence = average(analysisSamples.map(coreConfidence));
      const armConfidenceValues = analysisSamples.map(armConfidence).filter((value) => value !== null);
      const contactConfidence = metricContacts.length === 0
        ? 0
        : average(metricContacts.map((contact) => contact.confidence));
      const contactReason = usesContactProxy
        ? 'contact_phase_proxy'
        : usesKinematicContactEstimate
          ? 'kinematic_contact_estimate'
          : hasCompleteContactSample ? null : 'limited_contact_samples';

      const analyzedFrameTimestamps = new Set([
        ...coarseFrameTimes,
        ...recoveryFrameTimes,
        ...denseFrameTimes,
      ]);
      const validFrameTimestamps = new Set([
        ...analysisSamples.map((sample) => sample.timestampMs),
        ...dense.samples.map((sample) => sample.timestampMs),
      ]);

      const baseMetricQualities = {
        posture: metricQuality(
          hasUsableSharpness ? bodyConfidence : Math.min(bodyConfidence, 0.58),
          analysisSamples.length,
          hasUsableSharpness ? null : 'low_sharpness',
        ),
        bounce: metricQuality(
          hasUsableSharpness ? bodyConfidence : Math.min(bodyConfidence, 0.58),
          analysisSamples.length,
          hasUsableSharpness ? null : 'low_sharpness',
        ),
        footStrike: metricQuality(
          hasUsableSharpness ? contactConfidence : Math.min(contactConfidence, 0.58),
          metricContacts.length,
          metricContacts.length === 0 ? 'coordinates_unavailable' : contactReason ?? (hasUsableSharpness ? null : 'low_sharpness'),
        ),
        kneeFlexion: metricQuality(
          hasUsableSharpness ? contactConfidence : Math.min(contactConfidence, 0.58),
          metricContacts.length,
          metricContacts.length === 0 ? 'coordinates_unavailable' : contactReason ?? (hasUsableSharpness ? null : 'low_sharpness'),
        ),
        armCarriage: metricQuality(
          armConfidenceValues.length === 0 ? 0 : Math.min(average(armConfidenceValues), hasUsableSharpness ? 1 : 0.58),
          armConfidenceValues.length,
          armConfidenceValues.length === 0 ? 'coordinates_unavailable' : hasUsableSharpness ? null : 'low_sharpness',
        ),
      };

      return {
        analysisVersion: 2,
        durationMs,
        sampledFrames: analyzedFrameTimestamps.size,
        validFrames: validFrameTimestamps.size,
        direction,
        forwardLeanDegrees: round3(leanDegrees),
        verticalBounceRatio: round3(Math.max(0, bounceRatio)),
        footStrikeDistanceRatio: metricContacts.length === 0 ? null : round3(average(metricContacts.map((contact) => contact.footStrikeRatio))),
        stanceKneeAngleDegrees: metricContacts.length === 0 ? null : round3(average(metricContacts.map((contact) => contact.kneeAngleDegrees))),
        elbowAngleDegrees: elbowAngles.length === 0 ? null : round3(average(elbowAngles)),
        metricQualities: {
          posture: applyPerspectiveQuality('posture', baseMetricQualities.posture, perspective),
          bounce: applyPerspectiveQuality('bounce', baseMetricQualities.bounce, perspective),
          footStrike: applyPerspectiveQuality('footStrike', baseMetricQualities.footStrike, perspective),
          kneeFlexion: applyPerspectiveQuality('kneeFlexion', baseMetricQualities.kneeFlexion, perspective),
          armCarriage: applyPerspectiveQuality('armCarriage', baseMetricQualities.armCarriage, perspective),
        },
        coarseSamples: {
          attemptedFrames: coarseFrameTimes.length,
          validFrames: coarse.samples.length,
          poseFrameCount: coarse.poseFrames.length,
          maxFrameBudget: config.maxCoarseFrames,
          targetFps: config.coarseTargetFps,
        },
        recoverySamples: {
          attemptedFrames: recoveryFrameTimes.length,
          validFrames: recovery.samples.length,
          poseFrameCount: recovery.poseFrames.length,
          maxFrameBudget: config.maxRecoveryFrames,
          targetFps: config.recoveryTargetFps,
        },
        denseSamples: {
          attemptedFrames: denseFrameTimes.length,
          validFrames: dense.samples.length,
          poseFrameCount: dense.poseFrames.length,
          maxFrameBudget: config.maxDenseFrames,
          targetFps: config.denseTargetFps,
        },
        contactWindows: contactWindowPayloads(candidateSet.windows, denseFrameTimes, contactValidations),
        validatedContactFrameTimestampsMs: [...new Set(confirmedContacts.map((contact) => contact.timestampMs))].sort((a, b) => a - b),
        estimatedContactFrameTimestampsMs: [...new Set(estimatedContacts.map((contact) => contact.timestampMs))].sort((a, b) => a - b),
        contactConfidence: round3(contactConfidence),
        perspectiveQuality: perspective,
        poseFrames: mergedPoseFrames(
          mergedPoseFrames(coarse.poseFrames, recovery.poseFrames),
          dense.poseFrames,
        ),
      };
    } finally {
      releaseVideo(video, url, ownsUrl);
    }
  }

  function analyze(bytes, name) {
    return analyzeFromLoader(() => loadVideo(bytes, name));
  }

  function analyzeUrl(url, name) {
    return analyzeFromLoader(() => loadVideoUrl(url, false));
  }

  async function analyzePreviewPoseFromLoader(load) {
    const { video, url, ownsUrl } = await load();
    try {
      const durationMs = Math.round(video.duration * 1000);
      if (!Number.isFinite(durationMs) || durationMs < config.minVideoDurationMs) {
        throw createError(
          'video_too_short',
          'Please select a running clip that is at least 1.5 seconds long.',
        );
      }
      if (durationMs > config.maxDecodableVideoDurationMs) {
        throw createError(
          'video_too_long',
          'This video is longer than the bounded on-device decoding budget.',
        );
      }
      if (video.videoWidth <= 0 || video.videoHeight <= 0) {
        throw createError('web_video_decode_failed', 'The selected video has no readable frames.');
      }

      const previewFrameTimes = previewPoseTimestamps(durationMs);
      let preview;
      try {
        preview = await runPosePass(video, previewFrameTimes, false);
      } catch (error) {
        if (error?.code) throw error;
        throw createError('mediapipe_pose_failed', error?.message || 'MediaPipe pose inference failed.');
      }
      if (preview.poseFrames.length === 0) {
        throw createError(
          'preview_pose_unavailable',
          'No readable pose frame was found for preview.',
        );
      }
      return {
        durationMs,
        sampledFrames: previewFrameTimes.length,
        validFrames: preview.samples.length,
        perspectiveQuality: perspectiveQuality(preview.samples),
        poseFrames: preview.poseFrames,
      };
    } finally {
      releaseVideo(video, url, ownsUrl);
    }
  }

  function analyzePreviewPose(bytes, name) {
    return analyzePreviewPoseFromLoader(() => loadVideo(bytes, name));
  }

  function analyzePreviewPoseUrl(url, name) {
    return analyzePreviewPoseFromLoader(() => loadVideoUrl(url, false));
  }

  window.runningVideoPoseAnalysis = Object.freeze({
    analyze,
    analyzeUrl,
    analyzePreviewPose,
    analyzePreviewPoseUrl,
    extractEvidenceFrames,
    extractEvidenceFramesFromUrl,
    storeEvidenceFrame,
    readEvidenceFrame,
    deleteEvidenceFrames,
  });
})();
