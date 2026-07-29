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
    ambient: gl.getUniformLocation(program, 'uAmbient'),
  };

  const sphere = createSphereMesh(18, 14);
  const cylinder = createCylinderMesh(18);
  const plane = createPlaneMesh();

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
    gl.clearColor(0.052, 0.083, 0.145, 1);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.disable(gl.SCISSOR_TEST);

    const aspect = width / Math.max(1, height);
    const projection = mat4Perspective(Math.PI / 4.7, aspect, 0.05, 30);
    const view = mat4LookAt([0.08, 0.88, 3.15], [0.10, 0.82, 0.0], [0, 1, 0]);
    const viewProjection = mat4Multiply(projection, view);

    gl.useProgram(program);
    gl.uniformMatrix4fv(locations.viewProjection, false, viewProjection);
    gl.uniform3fv(locations.lightDirection, normalizeVec([0.35, 0.82, 0.44]));
    gl.uniform1f(locations.ambient, 0.36);

    drawGround(viewProjection);
    drawShadow(rig, viewProjection, accentHex);
    drawHuman(rig, viewProjection, accentHex, isTarget);
  }

  function drawGround(viewProjection) {
    const model = composeBasisMatrix(
      [-0.02, -0.012, 0],
      [1, 0, 0],
      [0, 0, 1],
      [0, 1, 0],
      [2.15, 1.12, 1],
    );
    drawMesh(plane, model, viewProjection, [0.20, 0.26, 0.34, 0.42]);
  }

  function drawShadow(rig, viewProjection, accentHex) {
    const pelvis = rig.joints.pelvisCenter || [0, 0.9, 0];
    const color = hexToRgba(accentHex, 0.18);
    const model = composeBasisMatrix(
      [pelvis[0] + 0.06, 0.006, 0],
      [1, 0, 0],
      [0, 0, 1],
      [0, 1, 0],
      [0.74, 0.28, 0.018],
    );
    drawMesh(sphere, model, viewProjection, color);
  }

  function drawHuman(rig, viewProjection, accentHex, isTarget) {
    const j = rig.joints;
    const skin = isTarget ? [0.86, 0.60, 0.42, 1] : [0.90, 0.63, 0.45, 1];
    const skinShadow = [0.70, 0.43, 0.32, 1];
    const shirt = isTarget ? hexToRgba(accentHex, 1) : [0.86, 0.23, 0.25, 1];
    const shorts = [0.08, 0.13, 0.21, 1];
    const shoe = isTarget ? [0.16, 0.31, 0.62, 1] : [0.18, 0.19, 0.23, 1];
    const shoeSole = [0.92, 0.95, 0.98, 1];

    drawSegment(j.pelvisCenter, j.chest, 0.18, 0.115, shirt, viewProjection);
    drawEllipsoidBetween(j.pelvisCenter, j.chest, [0.18, 0.44, 0.12], shirt, viewProjection);
    drawEllipsoid(j.pelvisCenter, [0.19, 0.115, 0.145], shorts, viewProjection);
    drawSegment(j.neck, j.head, 0.052, 0.040, skin, viewProjection);
    drawEllipsoid(j.head, [0.125, 0.155, 0.116], skin, viewProjection);
    drawEllipsoid(j.nose, [0.035, 0.025, 0.026], skinShadow, viewProjection);
    drawEllipsoid(j.leftEye, [0.014, 0.010, 0.010], [0.08, 0.09, 0.10, 1], viewProjection);
    drawEllipsoid(j.rightEye, [0.014, 0.010, 0.010], [0.08, 0.09, 0.10, 1], viewProjection);

    drawLimb(j.leftShoulder, j.leftElbow, j.leftWrist, skin, viewProjection, 0.052, 0.043);
    drawLimb(j.rightShoulder, j.rightElbow, j.rightWrist, skinShadow, viewProjection, 0.050, 0.041);
    drawHand(j, 'left', skin, viewProjection);
    drawHand(j, 'right', skinShadow, viewProjection);

    drawLimb(j.leftHip, j.leftKnee, j.leftAnkle, skin, viewProjection, 0.074, 0.058);
    drawLimb(j.rightHip, j.rightKnee, j.rightAnkle, skinShadow, viewProjection, 0.072, 0.056);
    drawShoe(j.leftHeel, j.leftToe, shoe, shoeSole, viewProjection);
    drawShoe(j.rightHeel, j.rightToe, shoe, shoeSole, viewProjection);

    drawJointHalo(j.pelvisCenter, accentHex, viewProjection);
    for (const decision of rig.footLocks || []) {
      if (!decision.locked) continue;
      const toe = j[`${decision.side}Toe`];
      if (toe) drawEllipsoid(toe, [0.035, 0.012, 0.035], hexToRgba(accentHex, 0.8), viewProjection);
    }
  }

  function drawLimb(root, joint, end, color, viewProjection, upperRadius, lowerRadius) {
    drawSegment(root, joint, upperRadius, upperRadius * 0.76, color, viewProjection);
    drawSegment(joint, end, lowerRadius, lowerRadius * 0.70, color, viewProjection);
    drawEllipsoid(joint, [lowerRadius * 1.08, lowerRadius * 1.08, lowerRadius * 1.08], color, viewProjection);
  }

  function drawHand(joints, side, color, viewProjection) {
    const wrist = joints[`${side}Wrist`];
    const hand = joints[`${side}Hand`];
    if (!wrist || !hand) return;
    drawSegment(wrist, hand, 0.038, 0.030, color, viewProjection);
    drawEllipsoid(hand, [0.045, 0.030, 0.038], color, viewProjection);
    for (const finger of ['Pinky', 'Index', 'Thumb']) {
      const tip = joints[`${side}${finger}`];
      if (tip) drawSegment(hand, tip, 0.010, 0.007, color, viewProjection);
    }
  }

  function drawShoe(heel, toe, shoeColor, soleColor, viewProjection) {
    if (!heel || !toe) return;
    const center = scaleVec(addVec(heel, toe), 0.5);
    const direction = normalizeVec(subVec(toe, heel));
    const side = normalizeVec(crossVec(direction, [0, 1, 0]));
    const up = normalizeVec(crossVec(side, direction));
    const length = Math.max(0.12, lengthVec(subVec(toe, heel)));
    const model = composeBasisMatrix(center, side, direction, up, [0.075, length * 0.60, 0.040]);
    drawMesh(sphere, model, viewProjection, shoeColor);
    const soleCenter = addVec(center, [0, -0.028, 0]);
    const soleModel = composeBasisMatrix(soleCenter, side, direction, up, [0.080, length * 0.62, 0.012]);
    drawMesh(sphere, soleModel, viewProjection, soleColor);
  }

  function drawJointHalo(point, accentHex, viewProjection) {
    if (!point) return;
    drawEllipsoid(point, [0.055, 0.055, 0.055], hexToRgba(accentHex, 0.22), viewProjection);
  }

  function drawEllipsoidBetween(start, end, scale, color, viewProjection) {
    if (!start || !end) return;
    const center = scaleVec(addVec(start, end), 0.5);
    const axis = normalizeVec(subVec(end, start));
    const fallback = Math.abs(axis[1]) > 0.92 ? [1, 0, 0] : [0, 1, 0];
    const xAxis = normalizeVec(crossVec(fallback, axis));
    const zAxis = normalizeVec(crossVec(xAxis, axis));
    const model = composeBasisMatrix(center, xAxis, axis, zAxis, scale);
    drawMesh(sphere, model, viewProjection, color);
  }

  function drawEllipsoid(center, scale, color, viewProjection) {
    if (!center) return;
    const model = composeBasisMatrix(center, [1, 0, 0], [0, 1, 0], [0, 0, 1], scale);
    drawMesh(sphere, model, viewProjection, color);
  }

  function drawSegment(start, end, startRadius, endRadius, color, viewProjection) {
    if (!start || !end) return;
    const vector = subVec(end, start);
    const length = lengthVec(vector);
    if (length < 0.001) return;
    const yAxis = scaleVec(vector, 1 / length);
    const fallback = Math.abs(yAxis[1]) > 0.92 ? [1, 0, 0] : [0, 1, 0];
    const xAxis = normalizeVec(crossVec(fallback, yAxis));
    const zAxis = normalizeVec(crossVec(xAxis, yAxis));
    const center = scaleVec(addVec(start, end), 0.5);
    const radius = (startRadius + endRadius) / 2;
    const model = composeBasisMatrix(center, xAxis, yAxis, zAxis, [radius, length, radius]);
    drawMesh(cylinder, model, viewProjection, color);
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

  function createCylinderMesh(segments) {
    const vertices = [];
    const indices = [];
    for (let i = 0; i <= segments; i += 1) {
      const u = i / segments;
      const angle = u * Math.PI * 2;
      const x = Math.cos(angle);
      const z = Math.sin(angle);
      vertices.push(x, -0.5, z, x, 0, z);
      vertices.push(x, 0.5, z, x, 0, z);
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
      uniform float uAmbient;
      varying vec3 vNormal;
      varying vec3 vWorld;
      void main() {
        vec3 normal = normalize(vNormal);
        float diffuse = max(dot(normal, normalize(uLightDirection)), 0.0);
        float rim = pow(1.0 - max(dot(normal, vec3(0.0, 0.0, 1.0)), 0.0), 2.0) * 0.18;
        float shade = min(1.0, uAmbient + diffuse * 0.64 + rim);
        vec3 color = uColor.rgb * shade + vec3(1.0) * diffuse * 0.045;
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
    return [
      ((value >> 16) & 255) / 255,
      ((value >> 8) & 255) / 255,
      (value & 255) / 255,
      alpha,
    ];
  }
}());
