#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="$ROOT_DIR/.tmp/mediapipe_sample_venv"
LOG_FILE="$ROOT_DIR/.tmp/mediapipe_sample_pip.log"
PYTHON_BIN="${PYTHON_BIN:-python3}"

cd "$ROOT_DIR"

mkdir -p "$ROOT_DIR/.tmp"
rm -rf "$VENV_DIR"
cleanup() {
  rm -rf "$VENV_DIR"
}
trap cleanup EXIT

"$PYTHON_BIN" -m venv "$VENV_DIR"
"$VENV_DIR/bin/python" -m pip install --upgrade pip >"$LOG_FILE"
"$VENV_DIR/bin/python" -m pip install \
  mediapipe==0.10.21 \
  opencv-python-headless==4.10.0.84 \
  >>"$LOG_FILE"

"$VENV_DIR/bin/python" - <<'PY'
from pathlib import Path
import math
import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

model_path = Path("ios/Runner/pose_landmarker_lite.task")
videos = [
    Path("assets/videos/running_coach_reference_sample.mp4"),
    Path("assets/videos/running_coach_mistake_sample.mp4"),
]
sample_count = 14
sample_start = 0.15
sample_end = 0.85
min_confidence = 0.45
minimum_valid_frames = 6
minimum_detected_frames = 10
minimum_motion_ratio = 0.12
required_indices = [11, 12, 23, 24, 25, 26, 27, 28]

def confidence(landmark):
    values = []
    if landmark.visibility is not None:
        values.append(float(landmark.visibility))
    if landmark.presence is not None:
        values.append(float(landmark.presence))
    return min(values) if values else 0.0

def point(landmark, width, height):
    return (float(landmark.x) * width, float(landmark.y) * height)

def distance(first, second):
    return math.hypot(first[0] - second[0], first[1] - second[1])

def body_scale(landmarks, width, height):
    left_shoulder = point(landmarks[11], width, height)
    right_shoulder = point(landmarks[12], width, height)
    left_hip = point(landmarks[23], width, height)
    right_hip = point(landmarks[24], width, height)
    left_ankle = point(landmarks[27], width, height)
    right_ankle = point(landmarks[28], width, height)
    shoulder_center = ((left_shoulder[0] + right_shoulder[0]) / 2, (left_shoulder[1] + right_shoulder[1]) / 2)
    hip_center = ((left_hip[0] + right_hip[0]) / 2, (left_hip[1] + right_hip[1]) / 2)
    ankle_center = ((left_ankle[0] + right_ankle[0]) / 2, (left_ankle[1] + right_ankle[1]) / 2)
    return max(distance(shoulder_center, hip_center), distance(hip_center, ankle_center))

def hip_center(landmarks, width, height):
    left_hip = point(landmarks[23], width, height)
    right_hip = point(landmarks[24], width, height)
    return ((left_hip[0] + right_hip[0]) / 2, (left_hip[1] + right_hip[1]) / 2)

def options():
    return vision.PoseLandmarkerOptions(
        base_options=python.BaseOptions(model_asset_path=str(model_path)),
        running_mode=vision.RunningMode.VIDEO,
        num_poses=1,
        min_pose_detection_confidence=min_confidence,
        min_pose_presence_confidence=min_confidence,
        min_tracking_confidence=min_confidence,
    )

overall_ok = True
for video in videos:
    capture = cv2.VideoCapture(str(video))
    if not capture.isOpened():
        raise RuntimeError(f"Could not open {video}")
    frame_count = int(capture.get(cv2.CAP_PROP_FRAME_COUNT) or 0)
    fps = float(capture.get(cv2.CAP_PROP_FPS) or 30.0)
    width = int(capture.get(cv2.CAP_PROP_FRAME_WIDTH) or 0)
    height = int(capture.get(cv2.CAP_PROP_FRAME_HEIGHT) or 0)
    detected = 0
    valid = 0
    confidence_values = []
    valid_motion_samples = []
    last_timestamp_ms = 0
    with vision.PoseLandmarker.create_from_options(options()) as landmarker:
        for index in range(sample_count):
            progress = 0.5 if sample_count == 1 else index / (sample_count - 1)
            fraction = sample_start + ((sample_end - sample_start) * progress)
            frame_index = min(frame_count - 1, max(0, round((frame_count - 1) * fraction)))
            capture.set(cv2.CAP_PROP_POS_FRAMES, frame_index)
            ok, frame_bgr = capture.read()
            if not ok:
                continue
            frame_rgb = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)
            image = mp.Image(image_format=mp.ImageFormat.SRGB, data=frame_rgb)
            timestamp_ms = max(round((frame_index / fps) * 1000), last_timestamp_ms + 1)
            last_timestamp_ms = timestamp_ms
            result = landmarker.detect_for_video(image, timestamp_ms)
            if not result.pose_landmarks:
                continue
            detected += 1
            landmarks = result.pose_landmarks[0]
            if len(landmarks) <= max(required_indices):
                continue
            required_confidences = [confidence(landmarks[i]) for i in required_indices]
            confidence_values.extend(required_confidences)
            if min(required_confidences) < min_confidence:
                continue
            scale = body_scale(landmarks, width, height)
            if scale < 40.0:
                continue
            valid_motion_samples.append((timestamp_ms, hip_center(landmarks, width, height), scale))
            valid += 1
    capture.release()
    avg_confidence = sum(confidence_values) / len(confidence_values) if confidence_values else 0.0
    if len(valid_motion_samples) >= 2:
        first = valid_motion_samples[0]
        last = valid_motion_samples[-1]
        average_scale = sum(sample[2] for sample in valid_motion_samples) / len(valid_motion_samples)
        motion_ratio = abs(last[1][0] - first[1][0]) / max(average_scale, 1.0)
    else:
        motion_ratio = 0.0
    status = "PASS" if (
        detected >= minimum_detected_frames
        and valid >= minimum_valid_frames
        and motion_ratio >= minimum_motion_ratio
    ) else "FAIL"
    overall_ok = overall_ok and status == "PASS"
    print(
        f"{video.name}: sampled={sample_count} detected={detected} "
        f"valid={valid} detectionCoverage={detected / sample_count:.2f} "
        f"avgRequiredConfidence={avg_confidence:.3f} "
        f"hipMotionRatio={motion_ratio:.3f} status={status}"
    )

if not overall_ok:
    raise SystemExit(1)
PY
