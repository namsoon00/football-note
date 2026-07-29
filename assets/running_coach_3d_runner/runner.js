(function () {
  'use strict';

  const canvas = document.getElementById('scene');
  const statusEl = document.getElementById('status');
  const noticeEl = document.getElementById('notice');
  const currentLabelEl = document.getElementById('currentLabel');
  const targetLabelEl = document.getElementById('targetLabel');
  const currentConfidenceEl = document.getElementById('currentConfidence');
  const targetConfidenceEl = document.getElementById('targetConfidence');
  const currentSwatchEl = document.getElementById('currentSwatch');
  const targetSwatchEl = document.getElementById('targetSwatch');

  const gl = canvas.getContext('webgl', {
    antialias: true,
    alpha: false,
    premultipliedAlpha: false,
  });

  let payload = null;
  let startTime = performance.now();
  let animationHandle = 0;

  if (!gl) {
    showStatus('WebGL renderer is unavailable.');
    return;
  }

  const program = createProgram(gl, vertexShaderSource(), fragmentShaderSource());
  const locations = {
    position: gl.getAttribLocation(program, 'aPosition'),
    normal: gl.getAttribLocation(program, 'aNormal'),
    model: gl.getUniformLocation(program, 'uModel'),
    viewProjection: gl.getUniformLocation(program, 'uViewProjection'),
    color: gl.getUniformLocation(program, 'uColor'),
    lightDirection: gl.getUniformLocation(program, 'uLightDirection'),
    cameraPosition: gl.getUniformLocation(program, 'uCameraPosition'),
    ambient: gl.getUniformLocation(program, 'uAmbient'),
  };

  const sphere = createSphereMesh(26, 18);
  const plane = createPlaneMesh();
  const taperedMeshCache = new Map();

  gl.enable(gl.DEPTH_TEST);
  gl.enable(gl.CULL_FACE);
  gl.enable(gl.BLEND);
  gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

  window.runningThreeDRunnerSetPayload = setPayload;
  window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || data.type !== 'football-note-running-3d-runner-payload') return;
    setPayload(data.payload);
  });

  function setPayload(rawPayload) {
    try {
      payload = typeof rawPayload === 'string' ? JSON.parse(rawPayload) : rawPayload;
      startTime = performance.now();
      updateHud();
      hideStatus();
      if (!animationHandle) {
        animationHandle = requestAnimationFrame(render);
      }
    } catch (error) {
      showStatus((payload && payload.labels && payload.labels.error) || '3D renderer failed.');
    }
  }

  function updateHud() {
    if (!payload) return;
    const labels = payload.labels || {};
    const confidence = payload.confidence || {};
    const colors = payload.colors || {};
    currentLabelEl.textContent = labels.current || '';
    targetLabelEl.textContent = labels.target || '';
    noticeEl.textContent = labels.referenceNotice || '';
    currentSwatchEl.style.background = colors.current || '#e44747';
    targetSwatchEl.style.background = colors.target || '#3f7ee8';
    const confidenceLabel = labels.confidence || '';
    currentConfidenceEl.textContent = confidenceLabel
      ? `${confidenceLabel} ${Math.round((confidence.current || 0) * 100)}%`
      : '';
    targetConfidenceEl.textContent = confidenceLabel
      ? `${confidenceLabel} ${Math.round((confidence.target || 0) * 100)}%`
      : '';
  }

  function showStatus(message) {
    statusEl.textContent = message;
    statusEl.style.display = 'grid';
  }

  function hideStatus() {
    statusEl.style.display = 'none';
  }

  function render(now) {
    animationHandle = requestAnimationFrame(render);
    resizeCanvas();
    gl.clearColor(0.043, 0.071, 0.125, 1);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    if (!payload || !Array.isArray(payload.frames) || payload.frames.length === 0) {
      showStatus((payload && payload.labels && payload.labels.loading) || '');
      return;
    }
    hideStatus();

    const currentRig = rigForTime('current', now);
    const targetRig = rigForTime('target', now);
    const width = canvas.width;
    const height = canvas.height;
    const halfWidth = Math.max(1, Math.floor(width / 2));
    drawRunnerPanel(currentRig, 0, 0, halfWidth, height, payload.colors.current || '#e44747', false);
    drawRunnerPanel(
      targetRig,
      halfWidth,
      0,
      width - halfWidth,
      height,
      payload.colors.target || '#3f7ee8',
      true,
    );
  }

  function rigForTime(kind, now) {
    const frames = payload.frames;
    if (!payload.hasMotion || frames.length === 1) {
      const index = clamp(payload.selectedFrameIndex || 0, 0, frames.length - 1);
      return frames[index][kind];
    }
    const first = frames[0].timestampMs || 0;
    const last = frames[frames.length - 1].timestampMs || first + 1000;
    const duration = Math.max(700, last - first);
    const elapsed = (now - startTime) % duration;
    const timestamp = first + elapsed;
    let nextIndex = frames.findIndex((frame) => frame.timestampMs >= timestamp);
    if (nextIndex <= 0) {
      nextIndex = nextIndex < 0 ? 0 : nextIndex;
      return frames[nextIndex][kind];
    }
    const previous = frames[nextIndex - 1];
    const next = frames[nextIndex];
    const span = Math.max(1, next.timestampMs - previous.timestampMs);
    const t = clamp((timestamp - previous.timestampMs) / span, 0, 1);
    return interpolateRig(previous[kind], next[kind], smoothstep(t));
  }

  function interpolateRig(first, second, t) {
    const joints = {};
    const firstJoints = first.joints || {};
    const secondJoints = second.joints || {};
    for (const name of Object.keys(firstJoints)) {
      if (!secondJoints[name]) continue;
      joints[name] = lerpVec(firstJoints[name], secondJoints[name], t);
    }
    return {
      ...second,
      joints,
    };
  }

  function drawRunnerPanel(rig, x, y, width, height, accentHex, isTarget) {
    if (!rig || !rig.joints) return;
    gl.viewport(x, y, width, height);
    gl.scissor(x, y, width, height);
    gl.enable(gl.SCISSOR_TEST);
    gl.clearColor(0.050, 0.079, 0.135, 1);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.disable(gl.SCISSOR_TEST);

    const aspect = width / Math.max(1, height);
    const camera = cameraForRig(rig, aspect);
    const projection = mat4Perspective(camera.fovy, aspect, 0.05, 60);
    const view = mat4LookAt(camera.eye, camera.target, [0, 1, 0]);
    const viewProjection = mat4Multiply(projection, view);

    gl.useProgram(program);
    gl.uniformMatrix4fv(locations.viewProjection, false, viewProjection);
    gl.uniform3fv(locations.lightDirection, normalizeVec([0.44, 0.82, 0.36]));
    gl.uniform3fv(locations.cameraPosition, camera.eye);
    gl.uniform1f(locations.ambient, 0.30);

    drawGround(viewProjection, camera);
    drawShadow(rig, viewProjection, accentHex);
    drawHuman(rig, viewProjection, accentHex, isTarget);
  }

  function cameraForRig(rig, aspect) {
    const bounds = runnerBounds(rig);
    const safeAspect = Math.max(0.34, aspect);
    const fovy = safeAspect < 0.58 ? Math.PI / 4.05 : Math.PI / 4.35;
    const viewTangent = Math.tan(fovy / 2);
    const requiredHeight = Math.max(2.05, bounds.maxY - bounds.minY);
    const requiredWidth = Math.max(1.18, bounds.maxX - bounds.minX);
    const heightDistance = requiredHeight / (2 * viewTangent);
    const widthDistance = requiredWidth / (2 * viewTangent * safeAspect);
    const distance = clamp(Math.max(heightDistance, widthDistance) + 0.32, 3.15, 5.35);
    const targetX = clamp((bounds.minX + bounds.maxX) / 2, -0.08, 0.18);
    const targetY = clamp((bounds.minY + bounds.maxY) / 2, 0.74, 0.94);
    const targetZ = clamp((bounds.minZ + bounds.maxZ) / 2, -0.08, 0.08);
    const target = [targetX, targetY, targetZ];
    return {
      bounds,
      fovy,
      target,
      eye: [targetX + 0.18, targetY + 0.06, targetZ + distance],
    };
  }

  function runnerBounds(rig) {
    const joints = Object.values(rig.joints || {}).filter((point) => Array.isArray(point));
    if (joints.length === 0) {
      return {
        minX: -0.55,
        maxX: 0.58,
        minY: -0.07,
        maxY: 1.82,
        minZ: -0.30,
        maxZ: 0.30,
      };
    }
    let minX = joints[0][0];
    let maxX = joints[0][0];
    let minY = joints[0][1];
    let maxY = joints[0][1];
    let minZ = joints[0][2];
    let maxZ = joints[0][2];
    for (const point of joints) {
      minX = Math.min(minX, point[0]);
      maxX = Math.max(maxX, point[0]);
      minY = Math.min(minY, point[1]);
      maxY = Math.max(maxY, point[1]);
      minZ = Math.min(minZ, point[2]);
      maxZ = Math.max(maxZ, point[2]);
    }
    return {
      minX: minX - 0.24,
      maxX: maxX + 0.24,
      minY: Math.min(-0.07, minY - 0.08),
      maxY: maxY + 0.20,
      minZ: minZ - 0.24,
      maxZ: maxZ + 0.24,
    };
  }

  function drawGround(viewProjection, camera) {
    const groundWidth = Math.max(2.1, camera.bounds.maxX - camera.bounds.minX + 0.78);
    const model = composeBasisMatrix(
      [camera.target[0], -0.018, camera.target[2]],
      [1, 0, 0],
      [0, 0, 1],
      [0, 1, 0],
      [groundWidth, 1.26, 1],
    );
    drawMesh(plane, model, viewProjection, [0.17, 0.23, 0.31, 0.52]);
  }

  function drawShadow(rig, viewProjection, accentHex) {
    const bounds = runnerBounds(rig);
    const center = [
      (bounds.minX + bounds.maxX) / 2,
      0.008,
      (bounds.minZ + bounds.maxZ) / 2,
    ];
    const width = Math.max(0.58, (bounds.maxX - bounds.minX) * 0.40);
    const model = composeBasisMatrix(
      center,
      [1, 0, 0],
      [0, 0, 1],
      [0, 1, 0],
      [width, 0.25, 0.014],
    );
    drawMesh(sphere, model, viewProjection, [0.01, 0.014, 0.022, 0.25]);
    drawFootShadow(rig.joints.leftHeel, rig.joints.leftToe, viewProjection);
    drawFootShadow(rig.joints.rightHeel, rig.joints.rightToe, viewProjection);
  }

  function drawHuman(rig, viewProjection, accentHex, isTarget) {
    const j = rig.joints;
    const accent = hexToRgba(accentHex, 1);
    const palette = {
      accent,
      skin: isTarget ? [0.86, 0.60, 0.42, 1] : [0.90, 0.63, 0.45, 1],
      skinShadow: isTarget ? [0.70, 0.45, 0.34, 1] : [0.72, 0.45, 0.33, 1],
      shirt: accent,
      shirtShade: colorShade(accent, -0.16),
      shirtLight: colorShade(accent, 0.12),
      shorts: isTarget ? [0.06, 0.12, 0.25, 1] : [0.08, 0.10, 0.15, 1],
      shortsTrim: colorShade(accent, -0.05),
      shoe: isTarget ? [0.12, 0.28, 0.66, 1] : [0.20, 0.20, 0.24, 1],
      shoeSole: [0.91, 0.94, 0.96, 1],
      hair: isTarget ? [0.13, 0.09, 0.06, 1] : [0.08, 0.065, 0.05, 1],
      feature: [0.055, 0.065, 0.075, 1],
    };
    const leftHipZ = j.leftHip ? j.leftHip[2] : 0;
    const rightHipZ = j.rightHip ? j.rightHip[2] : 0;
    const leftNear = leftHipZ >= rightHipZ;
    const nearSide = leftNear ? 'left' : 'right';
    const farSide = leftNear ? 'right' : 'left';

    drawLeg(j, farSide, palette, palette.skinShadow, viewProjection);
    drawArm(j, farSide, palette, palette.skinShadow, viewProjection);
    drawTorso(j, palette, viewProjection);
    drawLeg(j, nearSide, palette, palette.skin, viewProjection);
    drawArm(j, nearSide, palette, palette.skin, viewProjection);
    drawRunnerHead(j, palette, viewProjection);

    for (const decision of rig.footLocks || []) {
      if (!decision.locked) continue;
      const toe = j[`${decision.side}Toe`];
      if (toe) drawEllipsoid(toe, [0.036, 0.010, 0.032], hexToRgba(accentHex, 0.64), viewProjection);
    }
  }

  function drawTorso(j, palette, viewProjection) {
    if (!j.pelvisCenter || !j.chest) return;
    const axes = bodyAxes(j.pelvisCenter, j.chest);
    const lowerRib = lerpVec(j.pelvisCenter, j.chest, 0.43);
    const upperChest = lerpVec(j.pelvisCenter, j.chest, 0.75);
    drawOrientedEllipsoid(lowerRib, axes, [0.125, 0.215, 0.128], palette.shirtShade, viewProjection);
    drawOrientedEllipsoid(upperChest, axes, [0.160, 0.245, 0.185], palette.shirt, viewProjection);
    drawOrientedEllipsoid(j.pelvisCenter, axes, [0.155, 0.120, 0.156], palette.shorts, viewProjection);
    drawOrientedEllipsoid(lerpVec(j.pelvisCenter, j.chest, 0.25), axes, [0.135, 0.034, 0.132], palette.shirtLight, viewProjection);
    if (j.neck) {
      drawSegment(j.chest, j.neck, 0.050, 0.036, palette.shirtLight, viewProjection);
      drawEllipsoid(j.neck, [0.050, 0.036, 0.046], palette.skin, viewProjection);
    }
  }

  function drawRunnerHead(j, palette, viewProjection) {
    if (!j.head) return;
    const faceVector = j.nose ? subVec(j.nose, j.head) : [1, 0, 0];
    const forward = normalizeVecOr([faceVector[0], 0, faceVector[2]], [1, 0, 0]);
    const sideAxis = normalizeVecOr(crossVec([0, 1, 0], forward), [0, 0, 1]);
    const axes = {
      xAxis: forward,
      yAxis: [0, 1, 0],
      zAxis: sideAxis,
    };
    if (j.neck) drawSegment(j.neck, j.head, 0.036, 0.030, palette.skin, viewProjection);
    drawOrientedEllipsoid(j.head, axes, [0.103, 0.138, 0.098], palette.skin, viewProjection);
    drawOrientedEllipsoid(
      addVec(addVec(j.head, [0, 0.055, 0]), scaleVec(forward, -0.020)),
      axes,
      [0.096, 0.064, 0.100],
      palette.hair,
      viewProjection,
    );
    drawOrientedEllipsoid(
      addVec(addVec(j.head, [0, 0.012, 0]), scaleVec(forward, -0.070)),
      axes,
      [0.036, 0.090, 0.088],
      palette.hair,
      viewProjection,
    );
    if (j.leftEar) drawEllipsoid(j.leftEar, [0.017, 0.027, 0.013], palette.skinShadow, viewProjection);
    if (j.rightEar) drawEllipsoid(j.rightEar, [0.017, 0.027, 0.013], palette.skinShadow, viewProjection);
    const noseCenter = addVec(j.head, scaleVec(forward, 0.092));
    drawOrientedEllipsoid(noseCenter, axes, [0.020, 0.017, 0.015], palette.skinShadow, viewProjection);
    if (j.leftEye) drawEllipsoid(j.leftEye, [0.010, 0.007, 0.008], palette.feature, viewProjection);
    if (j.rightEye) drawEllipsoid(j.rightEye, [0.010, 0.007, 0.008], palette.feature, viewProjection);
    if (j.mouthLeft && j.mouthRight) {
      drawSegment(j.mouthLeft, j.mouthRight, 0.0045, 0.0045, [0.32, 0.14, 0.13, 1], viewProjection);
    }
  }

  function drawArm(j, side, palette, skinColor, viewProjection) {
    const shoulder = j[`${side}Shoulder`];
    const elbow = j[`${side}Elbow`];
    const wrist = j[`${side}Wrist`];
    if (!shoulder || !elbow || !wrist) return;
    const sleeveEnd = lerpVec(shoulder, elbow, 0.38);
    const sleeveHem = lerpVec(shoulder, elbow, 0.46);
    drawEllipsoid(shoulder, [0.066, 0.046, 0.062], palette.shirt, viewProjection);
    drawSegment(shoulder, sleeveEnd, 0.061, 0.052, palette.shirt, viewProjection);
    drawSegment(sleeveEnd, sleeveHem, 0.054, 0.048, palette.shirtLight, viewProjection);
    drawSegment(sleeveHem, elbow, 0.043, 0.035, skinColor, viewProjection);
    drawSegment(elbow, wrist, 0.038, 0.029, skinColor, viewProjection);
    drawEllipsoid(elbow, [0.039, 0.032, 0.036], colorShade(skinColor, -0.06), viewProjection);
    drawHand(j, side, skinColor, viewProjection);
  }

  function drawLeg(j, side, palette, skinColor, viewProjection) {
    const hip = j[`${side}Hip`];
    const knee = j[`${side}Knee`];
    const ankle = j[`${side}Ankle`];
    if (!hip || !knee || !ankle) return;
    const shortsEnd = lerpVec(hip, knee, 0.34);
    const shortsHem = lerpVec(hip, knee, 0.42);
    drawEllipsoid(hip, [0.074, 0.052, 0.066], palette.shorts, viewProjection);
    drawSegment(hip, shortsEnd, 0.088, 0.077, palette.shorts, viewProjection);
    drawSegment(shortsEnd, shortsHem, 0.080, 0.074, palette.shortsTrim, viewProjection);
    drawSegment(shortsHem, knee, 0.066, 0.050, skinColor, viewProjection);
    drawSegment(knee, ankle, 0.052, 0.038, skinColor, viewProjection);
    drawEllipsoid(knee, [0.049, 0.038, 0.045], colorShade(skinColor, -0.045), viewProjection);
    drawEllipsoid(ankle, [0.032, 0.024, 0.030], skinColor, viewProjection);
    drawShoe(j[`${side}Heel`], j[`${side}Toe`], palette.shoe, palette.shoeSole, palette.accent, viewProjection);
  }

  function drawHand(joints, side, color, viewProjection) {
    const wrist = joints[`${side}Wrist`];
    const hand = joints[`${side}Hand`];
    if (!wrist || !hand) return;
    drawSegment(wrist, hand, 0.030, 0.024, color, viewProjection);
    drawEllipsoid(hand, [0.039, 0.025, 0.033], color, viewProjection);
    for (const finger of ['Pinky', 'Index', 'Thumb']) {
      const tip = joints[`${side}${finger}`];
      if (!tip) continue;
      drawSegment(hand, tip, finger === 'Thumb' ? 0.009 : 0.0075, 0.0045, color, viewProjection);
      drawEllipsoid(tip, [0.006, 0.006, 0.005], color, viewProjection);
    }
  }

  function drawShoe(heel, toe, shoeColor, soleColor, accentColor, viewProjection) {
    if (!heel || !toe) return;
    const center = scaleVec(addVec(heel, toe), 0.5);
    const direction = normalizeVecOr(subVec(toe, heel), [1, 0, 0]);
    const side = normalizeVecOr(crossVec(direction, [0, 1, 0]), [0, 0, 1]);
    const up = normalizeVecOr(crossVec(side, direction), [0, 1, 0]);
    const length = Math.max(0.12, lengthVec(subVec(toe, heel)));
    const bodyCenter = addVec(center, scaleVec(direction, length * 0.07));
    const model = composeBasisMatrix(bodyCenter, side, direction, up, [0.060, length * 0.46, 0.044]);
    drawMesh(sphere, model, viewProjection, shoeColor);
    const toeCenter = addVec(center, scaleVec(direction, length * 0.34));
    const toeModel = composeBasisMatrix(toeCenter, side, direction, up, [0.066, length * 0.20, 0.041]);
    drawMesh(sphere, toeModel, viewProjection, colorShade(shoeColor, 0.08));
    const heelCenter = addVec(center, scaleVec(direction, -length * 0.30));
    const heelModel = composeBasisMatrix(heelCenter, side, direction, up, [0.053, length * 0.18, 0.045]);
    drawMesh(sphere, heelModel, viewProjection, colorShade(shoeColor, -0.12));
    const soleCenter = addVec(center, [0, -0.030, 0]);
    const soleModel = composeBasisMatrix(soleCenter, side, direction, up, [0.071, length * 0.56, 0.010]);
    drawMesh(sphere, soleModel, viewProjection, soleColor);
    const stripeCenter = addVec(addVec(center, scaleVec(up, 0.016)), scaleVec(direction, length * 0.04));
    const stripeModel = composeBasisMatrix(stripeCenter, side, direction, up, [0.014, length * 0.34, 0.009]);
    drawMesh(sphere, stripeModel, viewProjection, accentColor);
  }

  function drawFootShadow(heel, toe, viewProjection) {
    if (!heel || !toe) return;
    const center = [
      (heel[0] + toe[0]) / 2,
      0.010,
      (heel[2] + toe[2]) / 2,
    ];
    const direction = normalizeVecOr([toe[0] - heel[0], 0, toe[2] - heel[2]], [1, 0, 0]);
    const side = normalizeVecOr(crossVec([0, 1, 0], direction), [0, 0, 1]);
    const length = Math.max(0.16, lengthVec(subVec(toe, heel)));
    const model = composeBasisMatrix(center, side, direction, [0, 1, 0], [0.060, length * 0.40, 0.007]);
    drawMesh(sphere, model, viewProjection, [0.005, 0.007, 0.012, 0.20]);
  }

  function bodyAxes(start, end) {
    const yAxis = normalizeVecOr(subVec(end, start), [0, 1, 0]);
    const xAxis = normalizeVecOr([yAxis[1], -yAxis[0], 0], [1, 0, 0]);
    const zAxis = normalizeVecOr(crossVec(xAxis, yAxis), [0, 0, 1]);
    return { xAxis, yAxis, zAxis };
  }

  function drawEllipsoidBetween(start, end, scale, color, viewProjection) {
    if (!start || !end) return;
    const center = scaleVec(addVec(start, end), 0.5);
    const axis = normalizeVecOr(subVec(end, start), [0, 1, 0]);
    const fallback = Math.abs(axis[1]) > 0.92 ? [1, 0, 0] : [0, 1, 0];
    const xAxis = normalizeVecOr(crossVec(fallback, axis), [1, 0, 0]);
    const zAxis = normalizeVecOr(crossVec(xAxis, axis), [0, 0, 1]);
    const model = composeBasisMatrix(center, xAxis, axis, zAxis, scale);
    drawMesh(sphere, model, viewProjection, color);
  }

  function drawOrientedEllipsoid(center, axes, scale, color, viewProjection) {
    if (!center) return;
    const model = composeBasisMatrix(center, axes.xAxis, axes.yAxis, axes.zAxis, scale);
    drawMesh(sphere, model, viewProjection, color);
  }

  function drawEllipsoid(center, scale, color, viewProjection) {
    if (!center) return;
    const model = composeBasisMatrix(center, [1, 0, 0], [0, 1, 0], [0, 0, 1], scale);
    drawMesh(sphere, model, viewProjection, color);
  }

  function drawSegment(start, end, startRadius, endRadius, color, viewProjection) {
    drawTaperedSegment(start, end, startRadius, endRadius, color, viewProjection);
  }

  function drawTaperedSegment(start, end, startRadius, endRadius, color, viewProjection) {
    if (!start || !end) return;
    const vector = subVec(end, start);
    const length = lengthVec(vector);
    if (length < 0.001) return;
    const yAxis = scaleVec(vector, 1 / length);
    const fallback = Math.abs(yAxis[1]) > 0.92 ? [1, 0, 0] : [0, 1, 0];
    const xAxis = normalizeVecOr(crossVec(fallback, yAxis), [1, 0, 0]);
    const zAxis = normalizeVecOr(crossVec(xAxis, yAxis), [0, 0, 1]);
    const center = scaleVec(addVec(start, end), 0.5);
    const model = composeBasisMatrix(center, xAxis, yAxis, zAxis, [1, length, 1]);
    drawMesh(taperedCylinderMesh(startRadius, endRadius), model, viewProjection, color);
  }

  function drawMesh(mesh, model, viewProjection, color) {
    gl.useProgram(program);
    gl.bindBuffer(gl.ARRAY_BUFFER, mesh.vertexBuffer);
    gl.enableVertexAttribArray(locations.position);
    gl.vertexAttribPointer(locations.position, 3, gl.FLOAT, false, 24, 0);
    gl.enableVertexAttribArray(locations.normal);
    gl.vertexAttribPointer(locations.normal, 3, gl.FLOAT, false, 24, 12);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.indexBuffer);
    gl.uniformMatrix4fv(locations.model, false, model);
    gl.uniformMatrix4fv(locations.viewProjection, false, viewProjection);
    gl.uniform4fv(locations.color, color);
    gl.drawElements(gl.TRIANGLES, mesh.indexCount, gl.UNSIGNED_SHORT, 0);
  }

  function createSphereMesh(segments, rings) {
    const vertices = [];
    const indices = [];
    for (let ring = 0; ring <= rings; ring += 1) {
      const v = ring / rings;
      const theta = v * Math.PI;
      const sinTheta = Math.sin(theta);
      const cosTheta = Math.cos(theta);
      for (let segment = 0; segment <= segments; segment += 1) {
        const u = segment / segments;
        const phi = u * Math.PI * 2;
        const x = Math.cos(phi) * sinTheta;
        const y = cosTheta;
        const z = Math.sin(phi) * sinTheta;
        vertices.push(x, y, z, x, y, z);
      }
    }
    for (let ring = 0; ring < rings; ring += 1) {
      for (let segment = 0; segment < segments; segment += 1) {
        const first = ring * (segments + 1) + segment;
        const second = first + segments + 1;
        indices.push(first, second, first + 1, second, second + 1, first + 1);
      }
    }
    return uploadMesh(vertices, indices);
  }

  function taperedCylinderMesh(startRadius, endRadius) {
    const start = Math.max(0.002, startRadius);
    const end = Math.max(0.002, endRadius);
    const key = `${Math.round(start * 1000)}:${Math.round(end * 1000)}`;
    if (!taperedMeshCache.has(key)) {
      taperedMeshCache.set(key, createCylinderMesh(24, start, end));
    }
    return taperedMeshCache.get(key);
  }

  function createCylinderMesh(segments, startRadius, endRadius) {
    const vertices = [];
    const indices = [];
    const normalY = startRadius - endRadius;
    for (let i = 0; i <= segments; i += 1) {
      const u = i / segments;
      const angle = u * Math.PI * 2;
      const x = Math.cos(angle);
      const z = Math.sin(angle);
      const normal = normalizeVecOr([x, normalY, z], [x, 0, z]);
      vertices.push(x * startRadius, -0.5, z * startRadius, normal[0], normal[1], normal[2]);
      vertices.push(x * endRadius, 0.5, z * endRadius, normal[0], normal[1], normal[2]);
    }
    for (let i = 0; i < segments; i += 1) {
      const a = i * 2;
      indices.push(a, a + 1, a + 2, a + 1, a + 3, a + 2);
    }
    return uploadMesh(vertices, indices);
  }

  function createPlaneMesh() {
    return uploadMesh(
      [
        -0.5, 0, -0.5, 0, 1, 0,
        0.5, 0, -0.5, 0, 1, 0,
        0.5, 0, 0.5, 0, 1, 0,
        -0.5, 0, 0.5, 0, 1, 0,
      ],
      [0, 1, 2, 0, 2, 3],
    );
  }

  function uploadMesh(vertices, indices) {
    const vertexBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW);
    const indexBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(indices), gl.STATIC_DRAW);
    return {
      vertexBuffer,
      indexBuffer,
      indexCount: indices.length,
    };
  }

  function createProgram(context, vertexSource, fragmentSource) {
    const vertexShader = compileShader(context, context.VERTEX_SHADER, vertexSource);
    const fragmentShader = compileShader(context, context.FRAGMENT_SHADER, fragmentSource);
    const shaderProgram = context.createProgram();
    context.attachShader(shaderProgram, vertexShader);
    context.attachShader(shaderProgram, fragmentShader);
    context.linkProgram(shaderProgram);
    if (!context.getProgramParameter(shaderProgram, context.LINK_STATUS)) {
      throw new Error(context.getProgramInfoLog(shaderProgram) || 'WebGL link failed');
    }
    return shaderProgram;
  }

  function compileShader(context, type, source) {
    const shader = context.createShader(type);
    context.shaderSource(shader, source);
    context.compileShader(shader);
    if (!context.getShaderParameter(shader, context.COMPILE_STATUS)) {
      throw new Error(context.getShaderInfoLog(shader) || 'WebGL shader failed');
    }
    return shader;
  }

  function vertexShaderSource() {
    return `
      attribute vec3 aPosition;
      attribute vec3 aNormal;
      uniform mat4 uModel;
      uniform mat4 uViewProjection;
      varying vec3 vNormal;
      varying vec3 vWorld;
      void main() {
        vec4 world = uModel * vec4(aPosition, 1.0);
        vWorld = world.xyz;
        vNormal = normalize((uModel * vec4(aNormal, 0.0)).xyz);
        gl_Position = uViewProjection * world;
      }
    `;
  }

  function fragmentShaderSource() {
    return `
      precision mediump float;
      uniform vec4 uColor;
      uniform vec3 uLightDirection;
      uniform vec3 uCameraPosition;
      uniform float uAmbient;
      varying vec3 vNormal;
      varying vec3 vWorld;
      void main() {
        vec3 normal = normalize(vNormal);
        vec3 light = normalize(uLightDirection);
        vec3 viewDir = normalize(uCameraPosition - vWorld);
        vec3 halfDir = normalize(light + viewDir);
        float diffuse = max(dot(normal, light), 0.0);
        float rim = pow(1.0 - max(dot(normal, viewDir), 0.0), 2.0) * 0.16;
        float specular = pow(max(dot(normal, halfDir), 0.0), 18.0) * 0.10;
        float shade = min(1.0, uAmbient + diffuse * 0.66 + rim);
        vec3 color = uColor.rgb * shade + vec3(1.0) * (diffuse * 0.035 + specular);
        gl_FragColor = vec4(color, uColor.a);
      }
    `;
  }

  function resizeCanvas() {
    const ratio = Math.max(1, window.devicePixelRatio || 1);
    const width = Math.max(1, Math.floor(canvas.clientWidth * ratio));
    const height = Math.max(1, Math.floor(canvas.clientHeight * ratio));
    if (canvas.width !== width || canvas.height !== height) {
      canvas.width = width;
      canvas.height = height;
    }
  }

  function composeBasisMatrix(center, xAxis, yAxis, zAxis, scale) {
    return new Float32Array([
      xAxis[0] * scale[0], xAxis[1] * scale[0], xAxis[2] * scale[0], 0,
      yAxis[0] * scale[1], yAxis[1] * scale[1], yAxis[2] * scale[1], 0,
      zAxis[0] * scale[2], zAxis[1] * scale[2], zAxis[2] * scale[2], 0,
      center[0], center[1], center[2], 1,
    ]);
  }

  function mat4Perspective(fovy, aspect, near, far) {
    const f = 1.0 / Math.tan(fovy / 2);
    const nf = 1 / (near - far);
    return new Float32Array([
      f / aspect, 0, 0, 0,
      0, f, 0, 0,
      0, 0, (far + near) * nf, -1,
      0, 0, 2 * far * near * nf, 0,
    ]);
  }

  function mat4LookAt(eye, center, up) {
    const z = normalizeVec(subVec(eye, center));
    const x = normalizeVec(crossVec(up, z));
    const y = crossVec(z, x);
    return new Float32Array([
      x[0], y[0], z[0], 0,
      x[1], y[1], z[1], 0,
      x[2], y[2], z[2], 0,
      -dotVec(x, eye), -dotVec(y, eye), -dotVec(z, eye), 1,
    ]);
  }

  function mat4Multiply(a, b) {
    const out = new Float32Array(16);
    for (let column = 0; column < 4; column += 1) {
      for (let row = 0; row < 4; row += 1) {
        out[column * 4 + row] =
          a[0 * 4 + row] * b[column * 4 + 0] +
          a[1 * 4 + row] * b[column * 4 + 1] +
          a[2 * 4 + row] * b[column * 4 + 2] +
          a[3 * 4 + row] * b[column * 4 + 3];
      }
    }
    return out;
  }

  function addVec(a, b) {
    return [a[0] + b[0], a[1] + b[1], a[2] + b[2]];
  }

  function subVec(a, b) {
    return [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
  }

  function scaleVec(a, s) {
    return [a[0] * s, a[1] * s, a[2] * s];
  }

  function dotVec(a, b) {
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
  }

  function crossVec(a, b) {
    return [
      a[1] * b[2] - a[2] * b[1],
      a[2] * b[0] - a[0] * b[2],
      a[0] * b[1] - a[1] * b[0],
    ];
  }

  function lengthVec(a) {
    return Math.hypot(a[0], a[1], a[2]);
  }

  function normalizeVec(a) {
    const length = lengthVec(a);
    if (!Number.isFinite(length) || length < 0.00001) return [1, 0, 0];
    return scaleVec(a, 1 / length);
  }

  function normalizeVecOr(a, fallback) {
    const length = lengthVec(a);
    if (!Number.isFinite(length) || length < 0.00001) return fallback;
    return scaleVec(a, 1 / length);
  }

  function lerpVec(a, b, t) {
    return [
      a[0] + (b[0] - a[0]) * t,
      a[1] + (b[1] - a[1]) * t,
      a[2] + (b[2] - a[2]) * t,
    ];
  }

  function smoothstep(t) {
    return t * t * (3 - 2 * t);
  }

  function clamp(value, min, max) {
    return Math.min(max, Math.max(min, value));
  }

  function hexToRgba(hex, alpha) {
    const normalized = String(hex || '#3f7ee8').replace('#', '');
    const value = Number.parseInt(normalized.length === 3
      ? normalized.split('').map((part) => part + part).join('')
      : normalized, 16);
    if (!Number.isFinite(value)) return [0.247, 0.494, 0.91, alpha];
    return [
      ((value >> 16) & 255) / 255,
      ((value >> 8) & 255) / 255,
      (value & 255) / 255,
      alpha,
    ];
  }

  function colorShade(color, amount) {
    const target = amount >= 0 ? [1, 1, 1] : [0, 0, 0];
    const t = Math.min(1, Math.abs(amount));
    return [
      color[0] + (target[0] - color[0]) * t,
      color[1] + (target[1] - color[1]) * t,
      color[2] + (target[2] - color[2]) * t,
      color[3],
    ];
  }
}());
