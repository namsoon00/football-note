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
from __future__ import annotations
from dataclasses import dataclass
from pathlib import Path
import math
import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

model_path = Path("ios/Runner/pose_landmarker_full.task")
videos = [
    Path("assets/videos/running_coach_reference_sample.mp4"),
    Path("assets/videos/running_coach_mistake_sample.mp4"),
]
sample_count = 14
sample_start = 0.15
sample_end = 0.85
min_confidence = 0.35
minimum_valid_frames = 6
minimum_detected_frames = 10
minimum_pose_frame_timestamp_span_ms = 1200
minimum_motion_ratio = 0.12
minimum_validated_contact_frames = 2
minimum_contact_confidence = 0.34
media_pipe_landmark_count = 33
dense_target_fps = 30
dense_interval_ms = 33
dense_window_radius_ms = 180
max_dense_frame_budget = 48
max_contact_windows = 6
minimum_contact_center_separation_ms = 120
coarse_ground_tolerance_ratio = 0.12
dense_ground_tolerance_ratio = 0.13
local_extremum_tolerance_ratio = 0.025

LEFT = "left"
RIGHT = "right"
FOOT_SIDES = [LEFT, RIGHT]

LANDMARK = {
    "left_shoulder": 11,
    "right_shoulder": 12,
    "left_hip": 23,
    "right_hip": 24,
    "left_knee": 25,
    "right_knee": 26,
    "left_ankle": 27,
    "right_ankle": 28,
    "left_heel": 29,
    "right_heel": 30,
    "left_toe": 31,
    "right_toe": 32,
}


@dataclass(frozen=True)
class Sample:
    timestamp_ms: int
    landmarks: list
    width: int
    height: int
    shoulder_center: tuple[float, float]
    hip_center: tuple[float, float]
    body_scale: float


@dataclass(frozen=True)
class ContactWindow:
    side: str
    center_timestamp_ms: int
    start_timestamp_ms: int
    end_timestamp_ms: int
    confidence: float


@dataclass(frozen=True)
class ContactFrame:
    timestamp_ms: int
    window_center_timestamp_ms: int
    side: str
    foot_strike_ratio: float
    knee_angle_degrees: float
    confidence: float


@dataclass(frozen=True)
class ContactFrameCandidate:
    sample: Sample
    side: str
    evidence: dict
    proximity: float
    tolerance: float
    confidence: float
    in_ground_band: bool


def confidence(landmark) -> float:
    values = []
    if landmark.visibility is not None:
        values.append(float(landmark.visibility))
    if landmark.presence is not None:
        values.append(float(landmark.presence))
    return min(values) if values else 0.0


def point(landmarks, name: str, width: int, height: int):
    index = LANDMARK[name]
    if len(landmarks) <= index:
        return None
    landmark = landmarks[index]
    if confidence(landmark) < min_confidence:
        return None
    return (float(landmark.x) * width, float(landmark.y) * height)


def distance(first, second) -> float:
    return math.hypot(first[0] - second[0], first[1] - second[1])


def midpoint(first, second) -> tuple[float, float]:
    return ((first[0] + second[0]) / 2.0, (first[1] + second[1]) / 2.0)


def build_sample(timestamp_ms: int, landmarks, width: int, height: int):
    if len(landmarks) < media_pipe_landmark_count:
        return None
    required_names = [
        "left_shoulder",
        "right_shoulder",
        "left_hip",
        "right_hip",
        "left_knee",
        "right_knee",
        "left_ankle",
        "right_ankle",
    ]
    points = {name: point(landmarks, name, width, height) for name in required_names}
    if any(value is None for value in points.values()):
        return None
    shoulder_center = midpoint(points["left_shoulder"], points["right_shoulder"])
    hip = midpoint(points["left_hip"], points["right_hip"])
    ankle_center = midpoint(points["left_ankle"], points["right_ankle"])
    scale = max(distance(shoulder_center, hip), distance(hip, ankle_center))
    if scale < 40.0:
        return None
    return Sample(
        timestamp_ms=timestamp_ms,
        landmarks=landmarks,
        width=width,
        height=height,
        shoulder_center=shoulder_center,
        hip_center=hip,
        body_scale=scale,
    )


def side_name(side: str, part: str) -> str:
    return f"{side}_{part}"


def foot_bottom(sample: Sample, side: str):
    ankle = point(sample.landmarks, side_name(side, "ankle"), sample.width, sample.height)
    if ankle is None:
        return None
    heel = point(sample.landmarks, side_name(side, "heel"), sample.width, sample.height)
    toe = point(sample.landmarks, side_name(side, "toe"), sample.width, sample.height)
    ankle_conf = confidence(sample.landmarks[LANDMARK[side_name(side, "ankle")]])
    heel_conf = (
        confidence(sample.landmarks[LANDMARK[side_name(side, "heel")]])
        if heel is not None
        else None
    )
    toe_conf = (
        confidence(sample.landmarks[LANDMARK[side_name(side, "toe")]])
        if toe is not None
        else None
    )
    bottom = max([point for point in (ankle, heel, toe) if point is not None], key=lambda item: item[1])
    return {
        "bottom": bottom,
        "ankle": ankle,
        "heel": heel or ankle,
        "toe": toe or ankle,
        "confidence": min(value for value in (ankle_conf, heel_conf, toe_conf) if value is not None),
    }


def joint_angle(first, vertex, third) -> float:
    first_dx = first[0] - vertex[0]
    first_dy = first[1] - vertex[1]
    second_dx = third[0] - vertex[0]
    second_dy = third[1] - vertex[1]
    first_len = math.hypot(first_dx, first_dy)
    second_len = math.hypot(second_dx, second_dy)
    if first_len <= 0 or second_len <= 0:
        return 180.0
    cosine = ((first_dx * second_dx) + (first_dy * second_dy)) / (first_len * second_len)
    return math.degrees(math.acos(max(-1.0, min(1.0, cosine))))


def contact_knee_angle(sample: Sample, side: str) -> float:
    hip = point(sample.landmarks, side_name(side, "hip"), sample.width, sample.height)
    knee = point(sample.landmarks, side_name(side, "knee"), sample.width, sample.height)
    ankle = point(sample.landmarks, side_name(side, "ankle"), sample.width, sample.height)
    return joint_angle(hip, knee, ankle)


def contact_landmark_confidence(sample: Sample, side: str, evidence) -> float:
    hip_conf = confidence(sample.landmarks[LANDMARK[side_name(side, "hip")]])
    knee_conf = confidence(sample.landmarks[LANDMARK[side_name(side, "knee")]])
    return min(evidence["confidence"], hip_conf, knee_conf)


def resolve_direction(samples: list[Sample]) -> str:
    if len(samples) < 2:
        return "stationary"
    hip_motion = samples[-1].hip_center[0] - samples[0].hip_center[0]
    average_scale = sum(sample.body_scale for sample in samples) / max(1, len(samples))
    if abs(hip_motion) < average_scale * minimum_motion_ratio:
        return "stationary"
    return "leftToRight" if hip_motion > 0 else "rightToLeft"


def contact_foot_strike_ratio(sample: Sample, side: str, direction: str) -> float:
    evidence = foot_bottom(sample, side)
    foot_x = evidence["ankle"][0]
    if direction == "leftToRight":
        reach_px = foot_x - sample.hip_center[0]
    elif direction == "rightToLeft":
        reach_px = sample.hip_center[0] - foot_x
    else:
        reach_px = abs(foot_x - sample.hip_center[0])
    return max(0.0, reach_px) / max(1.0, sample.body_scale)


def options():
    return vision.PoseLandmarkerOptions(
        base_options=python.BaseOptions(model_asset_path=str(model_path)),
        running_mode=vision.RunningMode.VIDEO,
        num_poses=1,
        min_pose_detection_confidence=min_confidence,
        min_pose_presence_confidence=min_confidence,
        min_tracking_confidence=min_confidence,
    )


def coarse_timestamps(duration_ms: int) -> list[int]:
    timestamps = []
    for index in range(sample_count):
        progress = 0.5 if sample_count == 1 else index / (sample_count - 1)
        fraction = sample_start + ((sample_end - sample_start) * progress)
        timestamps.append(min(duration_ms, max(0, round(duration_ms * fraction))))
    return timestamps


def frame_at_timestamp(capture, fps: float, frame_count: int, timestamp_ms: int):
    frame_index = min(frame_count - 1, max(0, round((timestamp_ms / 1000.0) * fps)))
    capture.set(cv2.CAP_PROP_POS_FRAMES, frame_index)
    ok, frame_bgr = capture.read()
    if not ok:
        return None
    return cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)


def run_pose_pass(capture, fps: float, frame_count: int, timestamps_ms: list[int]):
    samples: list[Sample] = []
    pose_timestamps: list[int] = []
    detected = 0
    last_analysis_timestamp_ms = -1
    with vision.PoseLandmarker.create_from_options(options()) as landmarker:
        for timestamp_ms in sorted(set(timestamps_ms)):
            frame_rgb = frame_at_timestamp(capture, fps, frame_count, timestamp_ms)
            if frame_rgb is None:
                continue
            image = mp.Image(image_format=mp.ImageFormat.SRGB, data=frame_rgb)
            analysis_timestamp_ms = max(timestamp_ms, last_analysis_timestamp_ms + 1)
            last_analysis_timestamp_ms = analysis_timestamp_ms
            result = landmarker.detect_for_video(image, analysis_timestamp_ms)
            if not result.pose_landmarks:
                continue
            detected += 1
            landmarks = result.pose_landmarks[0]
            if len(landmarks) >= media_pipe_landmark_count:
                pose_timestamps.append(timestamp_ms)
            sample = build_sample(timestamp_ms, landmarks, frame_rgb.shape[1], frame_rgb.shape[0])
            if sample is not None:
                samples.append(sample)
    return {
        "samples": samples,
        "pose_timestamps": pose_timestamps,
        "detected": detected,
    }


def derive_contact_windows(samples: list[Sample], duration_ms: int):
    foot_bottoms = []
    for sample in samples:
        for side in FOOT_SIDES:
            evidence = foot_bottom(sample, side)
            if evidence is not None:
                foot_bottoms.append((sample, side, evidence))
    if not foot_bottoms:
        return [], 0.0
    ground_y = max(item[2]["bottom"][1] for item in foot_bottoms)
    average_scale = sum(sample.body_scale for sample in samples) / max(1, len(samples))
    ground_tolerance = max(1.0, average_scale * coarse_ground_tolerance_ratio)
    local_tolerance = average_scale * local_extremum_tolerance_ratio
    candidates: list[ContactWindow] = []
    for side in FOOT_SIDES:
        side_evidence = [
            (sample, foot_bottom(sample, side))
            for sample in samples
            if foot_bottom(sample, side) is not None
        ]
        for index, (sample, evidence) in enumerate(side_evidence):
            bottom_y = evidence["bottom"][1]
            previous_y = side_evidence[index - 1][1]["bottom"][1] if index > 0 else None
            next_y = side_evidence[index + 1][1]["bottom"][1] if index + 1 < len(side_evidence) else None
            near_ground = ground_y - bottom_y <= ground_tolerance
            local_extremum = (
                (previous_y is None or bottom_y >= previous_y - local_tolerance)
                and (next_y is None or bottom_y >= next_y - local_tolerance)
            )
            if not near_ground or not local_extremum:
                continue
            proximity_factor = max(0.0, min(1.0, 1.0 - (max(0.0, ground_y - bottom_y) / ground_tolerance)))
            candidates.append(
                ContactWindow(
                    side=side,
                    center_timestamp_ms=sample.timestamp_ms,
                    start_timestamp_ms=max(0, sample.timestamp_ms - dense_window_radius_ms),
                    end_timestamp_ms=min(duration_ms, sample.timestamp_ms + dense_window_radius_ms),
                    confidence=max(0.0, min(1.0, evidence["confidence"] * proximity_factor)),
                )
            )
    selected: list[ContactWindow] = []
    for candidate in sorted(candidates, key=lambda item: (-item.confidence, item.center_timestamp_ms)):
        overlaps = any(
            existing.side == candidate.side
            and (
                abs(existing.center_timestamp_ms - candidate.center_timestamp_ms)
                < minimum_contact_center_separation_ms
                or (
                    candidate.start_timestamp_ms <= existing.end_timestamp_ms
                    and candidate.end_timestamp_ms >= existing.start_timestamp_ms
                )
            )
            for existing in selected
        )
        if not overlaps:
            selected.append(candidate)
        if len(selected) >= max_contact_windows:
            break
    return sorted(selected, key=lambda item: item.center_timestamp_ms), ground_y


def dense_timestamps_for_windows(windows: list[ContactWindow], duration_ms: int) -> list[int]:
    timestamp_distances: dict[int, int] = {}
    for window in windows:
        timestamp_ms = window.start_timestamp_ms
        while timestamp_ms <= window.end_timestamp_ms:
            clamped = min(duration_ms, max(0, timestamp_ms))
            distance = abs(clamped - window.center_timestamp_ms)
            if clamped not in timestamp_distances or distance < timestamp_distances[clamped]:
                timestamp_distances[clamped] = distance
            timestamp_ms += dense_interval_ms
        center = min(duration_ms, max(0, window.center_timestamp_ms))
        timestamp_distances[center] = min(
            timestamp_distances.get(center, 10**9),
            abs(center - window.center_timestamp_ms),
        )
    selected = sorted(timestamp_distances.items(), key=lambda item: (item[1], item[0]))[:max_dense_frame_budget]
    return sorted(timestamp for timestamp, _ in selected)


def validate_contact_frames(
    samples: list[Sample],
    windows: list[ContactWindow],
    ground_y: float,
    direction: str,
) -> list[ContactFrame]:
    selected_by_timestamp: dict[int, ContactFrame] = {}
    ordered_samples = sorted(samples, key=lambda item: item.timestamp_ms)
    for window in sorted(windows, key=lambda item: item.center_timestamp_ms):
        frame = select_contact_frame_for_window(
            window,
            ordered_samples=ordered_samples,
            ground_y=ground_y,
            direction=direction,
        )
        if frame is None:
            continue
        existing = selected_by_timestamp.get(frame.timestamp_ms)
        if existing is None or frame.confidence > existing.confidence:
            selected_by_timestamp[frame.timestamp_ms] = frame
    return [selected_by_timestamp[key] for key in sorted(selected_by_timestamp)]


def select_contact_frame_for_window(
    window: ContactWindow,
    ordered_samples: list[Sample],
    ground_y: float,
    direction: str,
) -> ContactFrame | None:
    candidates = [
        candidate
        for sample in ordered_samples
        if window.start_timestamp_ms <= sample.timestamp_ms <= window.end_timestamp_ms
        for candidate in [dense_contact_candidate(sample, window.side, ground_y)]
        if candidate is not None
    ]
    eligible_candidates: list[ContactFrameCandidate] = []
    persistent_candidates: list[ContactFrameCandidate] = []
    for index, current in enumerate(candidates):
        if not is_eligible_contact(current):
            continue
        eligible_candidates.append(current)
        previous = candidates[index - 1] if index > 0 else None
        next_candidate = candidates[index + 1] if index + 1 < len(candidates) else None
        if entered_ground_band(current, previous):
            return contact_frame_from_candidate(current, window, direction)
        if has_ground_band_persistence(current, previous, next_candidate):
            persistent_candidates.append(current)
    candidates_for_selection = persistent_candidates or eligible_candidates
    if not candidates_for_selection:
        return None
    selected = sorted(
        candidates_for_selection,
        key=lambda item: (
            -item.confidence,
            abs(item.sample.timestamp_ms - window.center_timestamp_ms),
            item.sample.timestamp_ms,
        ),
    )[0]
    return contact_frame_from_candidate(selected, window, direction)


def dense_contact_candidate(sample: Sample, side: str, ground_y: float):
    evidence = foot_bottom(sample, side)
    if evidence is None:
        return None
    tolerance = max(1.0, sample.body_scale * dense_ground_tolerance_ratio)
    proximity = ground_y - evidence["bottom"][1]
    proximity_factor = max(0.0, min(1.0, 1.0 - (max(0.0, proximity) / tolerance)))
    contact_confidence = max(
        0.0,
        min(
            1.0,
            contact_landmark_confidence(sample, side, evidence)
            * (0.75 + (0.25 * proximity_factor)),
        ),
    )
    return ContactFrameCandidate(
        sample=sample,
        side=side,
        evidence=evidence,
        proximity=proximity,
        tolerance=tolerance,
        confidence=contact_confidence,
        in_ground_band=proximity >= -tolerance * 0.35 and proximity <= tolerance,
    )


def is_eligible_contact(candidate: ContactFrameCandidate) -> bool:
    return candidate.in_ground_band and candidate.confidence >= minimum_contact_confidence


def entered_ground_band(
    current: ContactFrameCandidate,
    previous: ContactFrameCandidate | None,
) -> bool:
    return (
        previous is not None
        and previous.proximity > current.tolerance
        and abs(previous.sample.timestamp_ms - current.sample.timestamp_ms) <= dense_interval_ms * 2
    )


def has_ground_band_persistence(
    current: ContactFrameCandidate,
    previous: ContactFrameCandidate | None,
    next_candidate: ContactFrameCandidate | None,
) -> bool:
    return any(
        neighbor is not None
        and is_eligible_contact(neighbor)
        and abs(neighbor.sample.timestamp_ms - current.sample.timestamp_ms) <= dense_interval_ms * 2
        for neighbor in (previous, next_candidate)
    )


def contact_frame_from_candidate(
    candidate: ContactFrameCandidate,
    window: ContactWindow,
    direction: str,
) -> ContactFrame:
    return ContactFrame(
        timestamp_ms=candidate.sample.timestamp_ms,
        window_center_timestamp_ms=window.center_timestamp_ms,
        side=candidate.side,
        foot_strike_ratio=contact_foot_strike_ratio(candidate.sample, candidate.side, direction),
        knee_angle_degrees=contact_knee_angle(candidate.sample, candidate.side),
        confidence=candidate.confidence,
    )


overall_ok = True
for video in videos:
    capture = cv2.VideoCapture(str(video))
    if not capture.isOpened():
        raise RuntimeError(f"Could not open {video}")
    frame_count = int(capture.get(cv2.CAP_PROP_FRAME_COUNT) or 0)
    fps = float(capture.get(cv2.CAP_PROP_FPS) or dense_target_fps)
    duration_ms = max(0, round((frame_count / max(fps, 1.0)) * 1000))

    coarse_pass = run_pose_pass(
        capture,
        fps=fps,
        frame_count=frame_count,
        timestamps_ms=coarse_timestamps(duration_ms),
    )
    windows, ground_y = derive_contact_windows(coarse_pass["samples"], duration_ms)
    dense_timestamps = dense_timestamps_for_windows(windows, duration_ms)
    dense_pass = run_pose_pass(
        capture,
        fps=fps,
        frame_count=frame_count,
        timestamps_ms=dense_timestamps,
    )
    capture.release()

    direction = resolve_direction(coarse_pass["samples"])
    contact_frames = validate_contact_frames(
        dense_pass["samples"],
        windows=windows,
        ground_y=ground_y,
        direction=direction,
    )
    merged_pose_timestamps = sorted(
        set(coarse_pass["pose_timestamps"]) | set(dense_pass["pose_timestamps"])
    )
    timestamp_span_ms = (
        merged_pose_timestamps[-1] - merged_pose_timestamps[0]
        if len(merged_pose_timestamps) >= 2
        else 0
    )
    timestamps_increasing = all(
        later > earlier
        for earlier, later in zip(merged_pose_timestamps, merged_pose_timestamps[1:])
    )
    dense_timestamps_increasing = all(
        later > earlier
        for earlier, later in zip(dense_timestamps, dense_timestamps[1:])
    )
    dense_budget_ok = len(dense_timestamps) <= max_dense_frame_budget
    dense_source_timestamps = {frame.timestamp_ms for frame in contact_frames}
    unique_contact_event_count = len(dense_source_timestamps)
    bounded_event_selection = len(contact_frames) <= len(windows)
    foot_knee_from_dense = (
        bool(contact_frames)
        and dense_source_timestamps.issubset(set(dense_timestamps))
    )
    contact_confidence = (
        sum(frame.confidence for frame in contact_frames) / len(contact_frames)
        if contact_frames
        else 0.0
    )
    foot_strike = (
        sum(frame.foot_strike_ratio for frame in contact_frames) / len(contact_frames)
        if contact_frames
        else 0.0
    )
    stance_knee = (
        sum(frame.knee_angle_degrees for frame in contact_frames) / len(contact_frames)
        if contact_frames
        else 0.0
    )
    motion_ratio = 0.0
    if len(coarse_pass["samples"]) >= 2:
        first = coarse_pass["samples"][0]
        last = coarse_pass["samples"][-1]
        average_scale = sum(sample.body_scale for sample in coarse_pass["samples"]) / len(coarse_pass["samples"])
        motion_ratio = abs(last.hip_center[0] - first.hip_center[0]) / max(average_scale, 1.0)

    status = "PASS" if (
        coarse_pass["detected"] >= minimum_detected_frames
        and len(coarse_pass["samples"]) >= minimum_valid_frames
        and len(windows) > 0
        and len(dense_timestamps) > 0
        and dense_budget_ok
        and dense_timestamps_increasing
        and unique_contact_event_count >= minimum_validated_contact_frames
        and bounded_event_selection
        and foot_knee_from_dense
        and timestamps_increasing
        and timestamp_span_ms >= minimum_pose_frame_timestamp_span_ms
        and motion_ratio >= minimum_motion_ratio
    ) else "FAIL"
    overall_ok = overall_ok and status == "PASS"
    print(
        f"{video.name}: coarse={len(coarse_pass['samples'])}/{sample_count} "
        f"dense={len(dense_pass['samples'])}/{len(dense_timestamps)} "
        f"budget={len(dense_timestamps)}/{max_dense_frame_budget} "
        f"windows={len(windows)} contactFrames={len(contact_frames)} "
        f"boundedEvents={len(contact_frames)}/{len(windows)} "
        f"contactConfidence={contact_confidence:.3f} "
        f"footStrike={foot_strike:.3f} stanceKnee={stance_knee:.1f} "
        f"footKneeSource=dense_contact_frames "
        f"monotonic={timestamps_increasing and dense_timestamps_increasing} "
        f"hipMotionRatio={motion_ratio:.3f} status={status}"
    )

if not overall_ok:
    raise SystemExit(1)
PY
