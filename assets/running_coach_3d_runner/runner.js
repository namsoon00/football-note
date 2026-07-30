import * as THREE from 'three';
import { GLTFLoader } from './vendor/loaders/GLTFLoader.js';

const MODEL_URL = './models/reference_runner.glb';
const DEFAULT_CURRENT = '#ef7370';
const DEFAULT_TARGET = '#78a8ff';
const MIN_CONFIDENCE = 0.35;
// Motion comes from the captured pose sequence. These bounds only make a
// very short or very long capture comfortable to inspect on a phone; they do
// not synthesize a gait or alter the order of measured poses.
const MEASURED_PLAYBACK_SPEED = 0.90;
const MIN_MEASURED_PLAYBACK_CYCLE_MS = 950;
const MAX_MEASURED_PLAYBACK_CYCLE_MS = 2800;

const canvas = document.getElementById('scene');
const statusEl = document.getElementById('status');
const noticeEl = document.getElementById('notice');
const hudEl = document.getElementById('hud');
const currentLabelEl = document.getElementById('currentLabel');
const targetLabelEl = document.getElementById('targetLabel');
const currentConfidenceEl = document.getElementById('currentConfidence');
const targetConfidenceEl = document.getElementById('targetConfidence');
const currentSwatchEl = document.getElementById('currentSwatch');
const targetSwatchEl = document.getElementById('targetSwatch');

let payload = null;
let assetReady = false;
let prototype = null;
let avatar = null;
let comparisonVisible = true;
let measuredPlaybackStartedAt = performance.now();

let renderer;
try {
  renderer = new THREE.WebGLRenderer({
    canvas,
    antialias: true,
    alpha: false,
    powerPreference: 'high-performance',
  });
} catch (error) {
  showStatus('');
  throw error;
}

renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFShadowMap;
renderer.autoClear = false;

const stage = createStage();
const camera = createCamera();
const shared = {
  markerGeometry: new THREE.SphereGeometry(0.027, 14, 10),
  markerHaloGeometry: new THREE.RingGeometry(0.035, 0.052, 20),
};

window.runningThreeDRunnerSetPayload = setPayload;
window.addEventListener('message', (event) => {
  const data = event.data;
  if (!data || data.type !== 'football-note-running-3d-runner-payload') return;
  setPayload(data.payload);
});

window.addEventListener('resize', resizeRenderer);
loadRunnerAsset();
requestAnimationFrame(render);

function createStage() {
  const scene = new THREE.Scene();
  scene.background = new THREE.Color('#101929');
  scene.fog = new THREE.Fog('#101929', 3.2, 6.4);

  scene.add(new THREE.HemisphereLight(0xdbe9ff, 0x1b2638, 2.35));
  const key = new THREE.DirectionalLight(0xfff4df, 2.65);
  key.position.set(2.8, 4.1, 3.4);
  key.castShadow = true;
  key.shadow.mapSize.set(1024, 1024);
  key.shadow.camera.left = -2;
  key.shadow.camera.right = 2;
  key.shadow.camera.top = 2.6;
  key.shadow.camera.bottom = -0.4;
  scene.add(key);

  const rim = new THREE.DirectionalLight(0x7ca8ff, 1.45);
  rim.position.set(-3.2, 2.3, -2.6);
  scene.add(rim);

  const ground = new THREE.Mesh(
    new THREE.PlaneGeometry(4.4, 3.6),
    new THREE.MeshStandardMaterial({
      color: '#17243a',
      roughness: 0.96,
      metalness: 0.0,
    }),
  );
  ground.rotation.x = -Math.PI / 2;
  ground.position.set(0, -0.002, 0);
  ground.receiveShadow = true;
  scene.add(ground);

  const lane = new THREE.Mesh(
    new THREE.BoxGeometry(2.45, 0.006, 0.022),
    new THREE.MeshBasicMaterial({ color: '#7c8ba3', transparent: true, opacity: 0.45 }),
  );
  lane.position.set(0, 0.005, 0.16);
  scene.add(lane);
  return scene;
}

function createCamera() {
  // A coaching comparison needs consistent proportions. A narrow mobile
  // perspective camera exaggerated the head and hands at the panel edges.
  const camera = new THREE.OrthographicCamera(-0.8, 0.8, 1.1, -0.1, 0.05, 20);
  camera.position.set(0, 0.94, 3.15);
  camera.lookAt(0, 0.86, 0);
  return camera;
}

function loadRunnerAsset() {
  showStatus((payload && payload.labels && payload.labels.loading) || '');
  new GLTFLoader().load(
    MODEL_URL,
    (gltf) => {
      prototype = gltf.scene;
      avatar = createAvatar(stage);
      assetReady = true;
      updateHud();
      if (payload) hideStatus();
    },
    undefined,
    () => showStatus((payload && payload.labels && payload.labels.error) || ''),
  );
}

function createAvatar(scene) {
  // A single loaded rig is rendered twice per frame. This keeps the left and
  // right panels perfectly comparable and avoids cloning a skinned hierarchy.
  const root = new THREE.Group();
  const model = prototype;
  root.add(model);
  model.rotation.set(0, Math.PI / 2, 0);
  root.updateMatrixWorld(true);

  const rawBounds = new THREE.Box3().setFromObject(root);
  const rawHeight = rawBounds.getSize(new THREE.Vector3()).y;
  // The rig's crouched landing pose is substantially shorter than its bind
  // pose. A presentation scale closer to a standing runner keeps the athlete
  // legible on a phone without cropping the contact foot.
  root.scale.setScalar(2.18 / Math.max(rawHeight, 0.001));
  root.updateMatrixWorld(true);
  const fittedBounds = new THREE.Box3().setFromObject(root);
  const fittedCenter = fittedBounds.getCenter(new THREE.Vector3());
  root.position.set(-fittedCenter.x, -fittedBounds.min.y, -fittedCenter.z);
  root.updateMatrixWorld(true);

  const bones = {};
  const accentMaterials = [];
  root.traverse((node) => {
    if (node.isBone || node.type === 'Bone') registerBone(bones, node);
    if (!node.isMesh) return;
    if (node.isSkinnedMesh && node.skeleton) {
      node.skeleton.bones.forEach((bone) => {
        registerBone(bones, bone);
      });
    }
    node.castShadow = true;
    node.receiveShadow = true;
    node.frustumCulled = false;
    node.material = cloneAndTuneMaterials(node.material, node.name, accentMaterials);
  });
  scene.add(root);

  const guides = createGuides(scene);
  return {
    root,
    bones,
    restPose: captureRestPose(bones),
    guides,
    accentMaterials,
  };
}

function registerBone(bones, bone) {
  // GLTFLoader sanitizes ':' from node names on some platforms. The coaching
  // mapping uses Mixamo's canonical spelling, so restore it in one place.
  const rawName = String(bone.name || '');
  const compactName = rawName.replace(':', '');
  const canonicalName = compactName.startsWith('mixamorig')
    ? `mixamorig:${compactName.slice('mixamorig'.length)}`
    : rawName;
  bones[canonicalName] = bone;
}

function captureRestPose(bones) {
  const restPose = new Map();
  Object.entries(bones).forEach(([name, bone]) => {
    restPose.set(name, {
      position: bone.position.clone(),
      quaternion: bone.quaternion.clone(),
      scale: bone.scale.clone(),
    });
  });
  return restPose;
}

function cloneAndTuneMaterials(source, meshName, accentMaterials) {
  const materialList = Array.isArray(source) ? source : [source];
  const tuned = materialList.map((material) => {
    const copy = material.clone();
    const description = `${meshName || ''} ${copy.name || ''}`.toLowerCase();
    const isHair = /hair|short0?3|eyebrow|lash/.test(description);

    // MakeHuman exports these opaque clothes as alpha-blended materials. In a
    // WebGL renderer this makes skin show through the shirt and hides the
    // short hair depending on draw order. Use alpha cutout only where the hair
    // texture needs it; every solid garment must write depth normally.
    copy.transparent = false;
    copy.opacity = 1;
    copy.depthWrite = true;
    copy.depthTest = true;
    copy.alphaTest = isHair ? 0.24 : 0;
    copy.premultipliedAlpha = false;
    if (/shirt|t-shirt|crude/.test(description)) {
      copy.userData.runnerAccent = true;
      accentMaterials.push(copy);
      copy.color.set('#1f78bd');
      copy.roughness = 0.67;
    } else if (/short|jean/.test(description)) {
      copy.color = new THREE.Color('#182132');
      copy.roughness = 0.78;
    } else if (/shoe/.test(description)) {
      copy.color.set('#f3f5f8');
      copy.roughness = 0.56;
    } else if (isHair) {
      copy.color.set('#211b1a');
      copy.roughness = 0.92;
    }
    return copy;
  });
  return Array.isArray(source) ? tuned : tuned[0];
}

function createGuides(scene) {
  const group = new THREE.Group();
  group.renderOrder = 2;
  const markerMaterial = new THREE.MeshBasicMaterial({
    color: DEFAULT_CURRENT,
    transparent: true,
    opacity: 0.9,
    depthTest: false,
  });
  const haloMaterial = new THREE.MeshBasicMaterial({
    color: DEFAULT_CURRENT,
    transparent: true,
    opacity: 0.38,
    side: THREE.DoubleSide,
    depthTest: false,
  });
  const markers = [];
  for (let index = 0; index < 8; index += 1) {
    const halo = new THREE.Mesh(shared.markerHaloGeometry, haloMaterial.clone());
    halo.rotation.x = -Math.PI / 2;
    const marker = new THREE.Mesh(shared.markerGeometry, markerMaterial.clone());
    marker.add(halo);
    marker.visible = false;
    markers.push(marker);
    group.add(marker);
  }
  const positions = new Float32Array(16 * 3);
  const lineGeometry = new THREE.BufferGeometry();
  const positionAttribute = new THREE.BufferAttribute(positions, 3);
  positionAttribute.setUsage(THREE.DynamicDrawUsage);
  lineGeometry.setAttribute('position', positionAttribute);
  lineGeometry.setDrawRange(0, 0);
  const lines = new THREE.LineSegments(
    lineGeometry,
    new THREE.LineBasicMaterial({
      color: DEFAULT_CURRENT,
      transparent: true,
      opacity: 0.70,
      depthTest: false,
    }),
  );
  lines.renderOrder = 3;
  group.add(lines);
  scene.add(group);
  return { group, markers, lines, positionAttribute };
}

function setPayload(rawPayload) {
  try {
    payload = typeof rawPayload === 'string' ? JSON.parse(rawPayload) : rawPayload;
    if (controlledPlaybackProgress() === null) resetMeasuredPlayback();
    updateHud();
    if (assetReady) {
      hideStatus();
    } else {
      showStatus((payload.labels && payload.labels.loading) || '');
    }
  } catch (error) {
    showStatus((payload && payload.labels && payload.labels.error) || '');
  }
}

function updateHud() {
  if (!payload) return;
  const labels = payload.labels || {};
  const colors = payload.colors || {};
  const confidence = payload.confidence || {};
  const currentColor = colors.current || DEFAULT_CURRENT;
  const targetColor = colors.target || DEFAULT_TARGET;
  currentLabelEl.textContent = labels.current || '';
  targetLabelEl.textContent = labels.target || '';
  noticeEl.textContent = labels.referenceNotice || '';
  currentSwatchEl.style.background = currentColor;
  currentSwatchEl.style.color = currentColor;
  targetSwatchEl.style.background = targetColor;
  targetSwatchEl.style.color = targetColor;
  const confidenceLabel = labels.confidence || '';
  currentConfidenceEl.textContent = confidenceLabel
    ? `${confidenceLabel} ${Math.round((confidence.current || 0) * 100)}%`
    : '';
  targetConfidenceEl.textContent = confidenceLabel
    ? `${confidenceLabel} ${Math.round((confidence.target || 0) * 100)}%`
    : '';
}

function render(now) {
  requestAnimationFrame(render);
  resizeRenderer();
  const currentRig = rigForMeasuredPlayback('current', now);
  const targetRig = rigForMeasuredPlayback('target', now);
  const showComparison = shouldShowComparison(targetRig);
  syncComparisonLayout(showComparison);
  const colors = payload && payload.colors ? payload.colors : {};
  if (assetReady) {
    prepareAvatarPose(avatar, currentRig);
    setAvatarAccent(avatar, colors.current || DEFAULT_CURRENT);
    updateGuides(avatar, currentRig, currentRig);
    if (payload) hideStatus();
  }

  // Three.js viewport coordinates are CSS pixels. `getDrawingBufferSize()` is
  // device-pixel-ratio adjusted, so using it here would push the right panel
  // outside high-density mobile canvases.
  const viewportWidth = Math.max(1, canvas.clientWidth || window.innerWidth);
  const viewportHeight = Math.max(1, canvas.clientHeight || window.innerHeight);
  const panelWidth = Math.max(1, Math.floor(viewportWidth / 2));
  const currentWidth = showComparison ? panelWidth : viewportWidth;
  renderPanel(stage, camera, 0, currentWidth, viewportHeight, '#101929');

  if (showComparison && assetReady) {
    prepareAvatarPose(avatar, targetRig);
    setAvatarAccent(avatar, colors.target || DEFAULT_TARGET);
    updateGuides(avatar, targetRig, currentRig);
  }
  if (showComparison) {
    renderPanel(stage, camera, panelWidth, viewportWidth - panelWidth, viewportHeight, '#111d32');
  }
}

function shouldShowComparison(targetRig) {
  // Even a metric already in range needs a current-versus-target view. In
  // that case both tracks intentionally replay the same measured movement,
  // which is the honest target: maintain this motion.
  return Boolean(payload && targetRig && targetRig.joints);
}

function syncComparisonLayout(showComparison) {
  if (comparisonVisible === showComparison) return;
  comparisonVisible = showComparison;
  hudEl.classList.toggle('is-single', !showComparison);
}

function prepareAvatarPose(avatar, rig) {
  restoreRestPose(avatar);
  applyMeasuredFramePose(avatar, rig);
  // Each rendered pose is an interpolation between adjacent captured frames,
  // then landmark data makes bounded corrections. This avoids inventing a
  // repeating gait while retaining stable limbs when video landmarks are
  // noisy.
  applyPoseCorrection(avatar, rig);
}

function setAvatarAccent(avatar, color) {
  const accent = new THREE.Color(color);
  avatar.guides.markers.forEach((marker) => {
    marker.material.color.copy(accent);
    const halo = marker.children[0];
    if (halo && halo.material && halo.material.color) halo.material.color.copy(accent);
  });
  avatar.guides.lines.material.color.copy(accent);
}

function restoreRestPose(avatar) {
  avatar.restPose.forEach((rest, name) => {
    const bone = avatar.bones[name];
    if (!bone) return;
    bone.position.copy(rest.position);
    bone.quaternion.copy(rest.quaternion);
    bone.scale.copy(rest.scale);
  });
  avatar.root.updateMatrixWorld(true);
}

const localXAxis = new THREE.Vector3(1, 0, 0);

function applyMeasuredFramePose(avatar, rig) {
  const { leftSwing, rightSwing } = stanceForRig(rig);
  setLocalX(avatar, 'mixamorig:LeftUpLeg', 0.48 * leftSwing);
  setLocalX(avatar, 'mixamorig:RightUpLeg', 0.48 * rightSwing);
  setLocalX(avatar, 'mixamorig:LeftLeg', 0.12 + 0.50 * Math.max(0, -leftSwing));
  setLocalX(avatar, 'mixamorig:RightLeg', 0.12 + 0.50 * Math.max(0, -rightSwing));
  setLocalX(avatar, 'mixamorig:LeftFoot', -0.08 - 0.14 * leftSwing);
  setLocalX(avatar, 'mixamorig:RightFoot', -0.08 - 0.14 * rightSwing);
  setLocalX(avatar, 'mixamorig:LeftToeBase', 0.04 + 0.11 * Math.max(0, leftSwing));
  setLocalX(avatar, 'mixamorig:RightToeBase', 0.04 + 0.11 * Math.max(0, rightSwing));
  poseMeasuredFrameArm(avatar, 'Left', -leftSwing);
  poseMeasuredFrameArm(avatar, 'Right', -rightSwing);
  avatar.root.updateMatrixWorld(true);
}

function stanceForRig(rig) {
  const joints = rig && rig.joints ? rig.joints : {};
  const pelvis = vectorFromRig(joints.pelvisCenter);
  const leftAnkle = vectorFromRig(joints.leftAnkle);
  const rightAnkle = vectorFromRig(joints.rightAnkle);
  const bodyHeight = Math.max(0.8, Number(rig && rig.bodyHeight) || 1.72);
  if (!pelvis || !leftAnkle || !rightAnkle) {
    return { leftSwing: 0.34, rightSwing: -0.34 };
  }
  const stride = clamp(
    ((leftAnkle.x - pelvis.x) - (rightAnkle.x - pelvis.x)) / bodyHeight * 1.25,
    -0.76,
    0.76,
  );
  return { leftSwing: stride, rightSwing: -stride };
}

function poseMeasuredFrameArm(avatar, side, swing) {
  const upperArm = `mixamorig:${side}Arm`;
  const forearm = `mixamorig:${side}ForeArm`;
  // Mixamo's child bones point down their local Y axis. Rotating around the
  // local X axis moves the arm forward/back in the side profile without the
  // world-axis spin that made the old avatar look like a zombie.
  setLocalX(avatar, upperArm, 0.30 * swing);
  setLocalX(avatar, forearm, 1.04 - 0.16 * swing);
}

function setBoneWorldDirection(avatar, boneName, childName, targetDirection) {
  const bone = avatar.bones[boneName];
  const child = avatar.bones[childName];
  if (!bone || !child || targetDirection.lengthSq() < 0.00001) return;
  const boneStart = bone.getWorldPosition(new THREE.Vector3());
  const currentDirection = child.getWorldPosition(new THREE.Vector3()).sub(boneStart);
  if (currentDirection.lengthSq() < 0.00001) return;
  const delta = new THREE.Quaternion().setFromUnitVectors(
    currentDirection.normalize(),
    targetDirection.normalize(),
  );
  const currentWorld = bone.getWorldQuaternion(new THREE.Quaternion());
  const desiredWorld = delta.multiply(currentWorld).normalize();
  const parentWorld = bone.parent.getWorldQuaternion(new THREE.Quaternion()).invert();
  bone.quaternion.copy(parentWorld.multiply(desiredWorld).normalize());
  bone.updateMatrixWorld(true);
}

function setLocalX(avatar, boneName, radians) {
  const bone = avatar.bones[boneName];
  const rest = avatar.restPose.get(boneName);
  if (!bone || !rest) return;
  bone.quaternion.copy(rest.quaternion).multiply(
    new THREE.Quaternion().setFromAxisAngle(localXAxis, radians),
  );
}

function renderPanel(scene, camera, x, width, height, background) {
  // Leave room below the contact foot. The rig can extend slightly below its
  // bind-pose floor at a long stride, and clipping the lower leg makes a
  // runner look even more unnatural than a smaller, complete figure.
  const halfHeight = 1.27;
  const halfWidth = Math.max(0.64, halfHeight * width / Math.max(1, height));
  const frameCenterY = 0.50;
  camera.left = -halfWidth;
  camera.right = halfWidth;
  camera.top = frameCenterY + halfHeight;
  camera.bottom = frameCenterY - halfHeight;
  camera.updateProjectionMatrix();
  scene.background.set(background);
  scene.fog.color.set(background);
  renderer.setViewport(x, 0, width, height);
  renderer.setScissor(x, 0, width, height);
  renderer.setScissorTest(true);
  renderer.setClearColor(background, 1);
  renderer.clear(true, true, true);
  renderer.render(scene, camera);
  renderer.setScissorTest(false);
}

function resizeRenderer() {
  const width = Math.max(1, canvas.clientWidth || window.innerWidth);
  const height = Math.max(1, canvas.clientHeight || window.innerHeight);
  const drawingSize = renderer.getDrawingBufferSize(new THREE.Vector2());
  const expectedWidth = Math.floor(width * renderer.getPixelRatio());
  const expectedHeight = Math.floor(height * renderer.getPixelRatio());
  if (drawingSize.x !== expectedWidth || drawingSize.y !== expectedHeight) {
    renderer.setSize(width, height, false);
  }
}

function selectedRig(kind) {
  if (!payload || !Array.isArray(payload.frames) || payload.frames.length === 0) return null;
  const frames = payload.frames;
  const index = clamp(Number(payload.selectedFrameIndex) || 0, 0, frames.length - 1);
  return frames[index][kind];
}

function resetMeasuredPlayback() {
  const range = measuredPlaybackRange();
  if (!range || range.sourceDuration <= 0) {
    measuredPlaybackStartedAt = performance.now();
    return;
  }
  const frames = payload.frames;
  const selectedIndex = clamp(
    Number(payload.selectedFrameIndex) || 0,
    0,
    frames.length - 1,
  );
  const selectedTimestamp = frameTimestamp(frames[selectedIndex], range.firstTimestamp);
  const selectedProgress = clamp(
    (selectedTimestamp - range.firstTimestamp) / range.sourceDuration,
    0,
    1,
  );
  // Start where the result screen selected the coaching frame, then continue
  // through the actual sequence in chronological order.
  measuredPlaybackStartedAt = performance.now() - selectedProgress * range.displayDuration;
}

function measuredPlaybackRange() {
  if (!payload || !Array.isArray(payload.frames) || payload.frames.length < 2) return null;
  const frames = payload.frames;
  const firstTimestamp = frameTimestamp(frames[0], 0);
  const lastTimestamp = frameTimestamp(frames[frames.length - 1], firstTimestamp);
  const sourceDuration = Math.max(0, lastTimestamp - firstTimestamp);
  const displayDuration = clamp(
    sourceDuration / MEASURED_PLAYBACK_SPEED,
    MIN_MEASURED_PLAYBACK_CYCLE_MS,
    MAX_MEASURED_PLAYBACK_CYCLE_MS,
  );
  return { firstTimestamp, sourceDuration, displayDuration };
}

function rigForMeasuredPlayback(kind, now) {
  const range = measuredPlaybackRange();
  if (!range || range.sourceDuration <= 0 || !payload.hasMotion) return selectedRig(kind);
  const frames = payload.frames;
  const suppliedProgress = controlledPlaybackProgress();
  const elapsed = Math.max(0, now - measuredPlaybackStartedAt);
  const cycleProgress = suppliedProgress === null
    ? (elapsed % range.displayDuration) / range.displayDuration
    : suppliedProgress;
  const measuredTimestamp = range.firstTimestamp + cycleProgress * range.sourceDuration;

  let previousFrame = frames[0];
  for (let index = 1; index < frames.length; index += 1) {
    const nextFrame = frames[index];
    const nextTimestamp = frameTimestamp(nextFrame, range.firstTimestamp);
    if (measuredTimestamp <= nextTimestamp || index === frames.length - 1) {
      const previousTimestamp = frameTimestamp(previousFrame, range.firstTimestamp);
      const gap = Math.max(1, nextTimestamp - previousTimestamp);
      const progress = clamp((measuredTimestamp - previousTimestamp) / gap, 0, 1);
      return interpolateMeasuredRig(
        previousFrame[kind],
        nextFrame[kind],
        smoothstep(progress),
      );
    }
    previousFrame = nextFrame;
  }
  return selectedRig(kind);
}

function controlledPlaybackProgress() {
  if (!payload || typeof payload.playbackProgress !== 'number') return null;
  if (!Number.isFinite(payload.playbackProgress)) return null;
  return clamp(payload.playbackProgress, 0, 1);
}

function frameTimestamp(frame, fallback) {
  const timestamp = Number(frame && frame.timestampMs);
  return Number.isFinite(timestamp) ? timestamp : fallback;
}

function interpolateMeasuredRig(previousRig, nextRig, amount) {
  if (!previousRig) return nextRig || null;
  if (!nextRig) return previousRig;
  const previousJoints = previousRig.joints || {};
  const nextJoints = nextRig.joints || {};
  const joints = {};
  const jointNames = new Set([...Object.keys(previousJoints), ...Object.keys(nextJoints)]);
  jointNames.forEach((name) => {
    joints[name] = interpolateMeasuredJoint(
      previousJoints[name],
      nextJoints[name],
      amount,
    );
  });
  return {
    ...nextRig,
    joints,
    confidence: interpolateMeasuredNumber(
      previousRig.confidence,
      nextRig.confidence,
      amount,
      0,
    ),
    bodyHeight: interpolateMeasuredNumber(
      previousRig.bodyHeight,
      nextRig.bodyHeight,
      amount,
      1.72,
    ),
  };
}

function interpolateMeasuredJoint(previousPoint, nextPoint, amount) {
  if (!Array.isArray(previousPoint)) return nextPoint;
  if (!Array.isArray(nextPoint)) return previousPoint;
  const length = Math.max(previousPoint.length, nextPoint.length);
  return Array.from({ length }, (_, index) => interpolateMeasuredNumber(
    previousPoint[index],
    nextPoint[index],
    amount,
    0,
  ));
}

function interpolateMeasuredNumber(previous, next, amount, fallback) {
  const start = Number(previous);
  const end = Number(next);
  if (!Number.isFinite(start)) return Number.isFinite(end) ? end : fallback;
  if (!Number.isFinite(end)) return start;
  return start + (end - start) * amount;
}

function smoothstep(amount) {
  const clamped = clamp(amount, 0, 1);
  return clamped * clamped * (3 - 2 * clamped);
}

const boneCorrections = [
  { bone: 'mixamorig:LeftArm', child: 'mixamorig:LeftForeArm', start: 'leftShoulder', end: 'leftElbow', max: 13, weight: 0.42 },
  { bone: 'mixamorig:LeftForeArm', child: 'mixamorig:LeftHand', start: 'leftElbow', end: 'leftWrist', max: 12, weight: 0.38 },
  { bone: 'mixamorig:RightArm', child: 'mixamorig:RightForeArm', start: 'rightShoulder', end: 'rightElbow', max: 13, weight: 0.42 },
  { bone: 'mixamorig:RightForeArm', child: 'mixamorig:RightHand', start: 'rightElbow', end: 'rightWrist', max: 12, weight: 0.38 },
  { bone: 'mixamorig:LeftUpLeg', child: 'mixamorig:LeftLeg', start: 'leftHip', end: 'leftKnee', max: 16, weight: 0.52 },
  { bone: 'mixamorig:LeftLeg', child: 'mixamorig:LeftFoot', start: 'leftKnee', end: 'leftAnkle', max: 14, weight: 0.46 },
  { bone: 'mixamorig:RightUpLeg', child: 'mixamorig:RightLeg', start: 'rightHip', end: 'rightKnee', max: 16, weight: 0.52 },
  { bone: 'mixamorig:RightLeg', child: 'mixamorig:RightFoot', start: 'rightKnee', end: 'rightAnkle', max: 14, weight: 0.46 },
];

function applyPoseCorrection(avatar, rig) {
  if (!avatar || !rig || !rig.joints) return;
  const confidence = clamp(Number(rig.confidence) || 0, 0, 1);
  if (confidence < MIN_CONFIDENCE) return;
  avatar.root.updateMatrixWorld(true);
  for (const correction of boneCorrections) {
    const bone = avatar.bones[correction.bone];
    const child = avatar.bones[correction.child];
    const start = vectorFromRig(rig.joints[correction.start]);
    const end = vectorFromRig(rig.joints[correction.end]);
    if (!bone || !child || !start || !end) continue;
    const measured = toAvatarDirection(end.sub(start));
    if (measured.lengthSq() < 0.00001) continue;
    const boneStart = bone.getWorldPosition(new THREE.Vector3());
    const boneEnd = child.getWorldPosition(new THREE.Vector3());
    const animatedDirection = boneEnd.sub(boneStart);
    if (animatedDirection.lengthSq() < 0.00001) continue;
    animatedDirection.normalize();
    measured.normalize();
    const rawDelta = new THREE.Quaternion().setFromUnitVectors(animatedDirection, measured);
    const rawAngle = 2 * Math.acos(clamp(Math.abs(rawDelta.w), -1, 1));
    const maxAngle = THREE.MathUtils.degToRad(correction.max * (0.55 + confidence * 0.45));
    const delta = rawAngle > maxAngle
      ? new THREE.Quaternion().slerp(rawDelta, maxAngle / rawAngle)
      : rawDelta;
    const currentWorld = bone.getWorldQuaternion(new THREE.Quaternion());
    const desiredWorld = delta.multiply(currentWorld).normalize();
    const parentWorld = bone.parent.getWorldQuaternion(new THREE.Quaternion()).invert();
    const desiredLocal = parentWorld.multiply(desiredWorld).normalize();
    bone.quaternion.slerp(desiredLocal, correction.weight * confidence);
    bone.updateMatrixWorld(true);
  }
  avatar.root.updateMatrixWorld(true);
}

function vectorFromRig(value) {
  if (!Array.isArray(value) || value.length < 2) return null;
  const x = Number(value[0]);
  const y = Number(value[1]);
  const z = Number(value[2] || 0);
  if (![x, y, z].every(Number.isFinite)) return null;
  return new THREE.Vector3(x, y, z);
}

function toAvatarDirection(vector) {
  return new THREE.Vector3(vector.x, vector.y, -vector.z * 0.22);
}

const landmarkToJoint = {
  0: 'head', 11: 'leftShoulder', 12: 'rightShoulder', 13: 'leftElbow', 14: 'rightElbow',
  15: 'leftWrist', 16: 'rightWrist', 19: 'leftPinky', 20: 'rightPinky',
  21: 'leftIndex', 22: 'rightIndex', 23: 'leftHip', 24: 'rightHip',
  25: 'leftKnee', 26: 'rightKnee', 27: 'leftAnkle', 28: 'rightAnkle',
  29: 'leftHeel', 30: 'rightHeel', 31: 'leftToe', 32: 'rightToe',
};

const jointToBone = {
  head: 'mixamorig:Head', chest: 'mixamorig:Spine2', pelvisCenter: 'mixamorig:Hips',
  leftShoulder: 'mixamorig:LeftArm', rightShoulder: 'mixamorig:RightArm',
  leftElbow: 'mixamorig:LeftForeArm', rightElbow: 'mixamorig:RightForeArm',
  leftWrist: 'mixamorig:LeftHand', rightWrist: 'mixamorig:RightHand',
  leftIndex: 'mixamorig:LeftHandIndex1', rightIndex: 'mixamorig:RightHandIndex1',
  leftPinky: 'mixamorig:LeftHandPinky1', rightPinky: 'mixamorig:RightHandPinky1',
  leftHip: 'mixamorig:LeftUpLeg', rightHip: 'mixamorig:RightUpLeg',
  leftKnee: 'mixamorig:LeftLeg', rightKnee: 'mixamorig:RightLeg',
  leftAnkle: 'mixamorig:LeftFoot', rightAnkle: 'mixamorig:RightFoot',
  leftHeel: 'mixamorig:LeftFoot', rightHeel: 'mixamorig:RightFoot',
  leftToe: 'mixamorig:LeftToeBase', rightToe: 'mixamorig:RightToeBase',
};

const guidePairs = [
  ['leftShoulder', 'leftHip'], ['rightShoulder', 'rightHip'],
  ['leftShoulder', 'leftElbow'], ['leftElbow', 'leftWrist'],
  ['rightShoulder', 'rightElbow'], ['rightElbow', 'rightWrist'],
  ['leftHip', 'leftKnee'], ['leftKnee', 'leftAnkle'],
  ['rightHip', 'rightKnee'], ['rightKnee', 'rightAnkle'],
];

function updateGuides(avatar, rig, baselineRig) {
  if (!avatar) return;
  if (!rig || !rig.joints || !payload) {
    avatar.guides.group.visible = false;
    return;
  }
  const focusIndices = Array.isArray(payload.focusIndices) ? payload.focusIndices : [];
  const jointNames = [];
  for (const index of focusIndices) {
    const name = landmarkToJoint[index];
    if (name && !jointNames.includes(name)) jointNames.push(name);
  }
  if (jointNames.length === 0) jointNames.push('pelvisCenter', 'chest');
  const anchorPositions = {};
  for (const name of jointNames) {
    const position = guidePositionForRig(avatar, rig, baselineRig, name);
    if (position) anchorPositions[name] = position;
  }
  avatar.guides.group.visible = true;
  avatar.guides.markers.forEach((marker, index) => {
    const position = anchorPositions[jointNames[index]];
    marker.visible = Boolean(position);
    if (position) marker.position.copy(position);
  });
  let offset = 0;
  for (const [from, to] of guidePairs) {
    const start = anchorPositions[from];
    const end = anchorPositions[to];
    if (!start || !end) continue;
    avatar.guides.positionAttribute.setXYZ(offset, start.x, start.y, start.z);
    avatar.guides.positionAttribute.setXYZ(offset + 1, end.x, end.y, end.z);
    offset += 2;
  }
  avatar.guides.positionAttribute.needsUpdate = true;
  avatar.guides.lines.geometry.setDrawRange(0, offset);
}

function guidePositionForRig(avatar, rig, baselineRig, jointName) {
  const bone = avatar.bones[jointToBone[jointName]];
  if (!bone) return null;
  const anchor = bone.getWorldPosition(new THREE.Vector3());
  const measured = vectorFromRig(rig.joints[jointName]);
  const baseline = baselineRig && vectorFromRig(baselineRig.joints?.[jointName]);
  if (!measured || !baseline) return anchor;
  // A fixed reference body cannot reproduce a user's proportions. Align the
  // measured current pose to its anatomical anchor, then add only the exact
  // current-to-target coordinate delta for a stable, readable comparison.
  const delta = measured.sub(baseline);
  return anchor.add(new THREE.Vector3(delta.x, delta.y, -delta.z * 0.22));
}

function showStatus(message) {
  statusEl.textContent = message;
  statusEl.style.display = 'grid';
}

function hideStatus() {
  statusEl.style.display = 'none';
}

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}
