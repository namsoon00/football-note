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
    Path("assets/videos/running_coach_portrait_side_view_sample.mp4"),
    Path("assets/videos/running_coach_mistake_sample.mp4"),
]
coarse_target_fps = 10
coarse_frame_interval_ms = 100
max_coarse_frame_budget = 240
min_confidence = 0.35
minimum_valid_frames = 6
minimum_detected_frames = 10
minimum_pose_frame_timestamp_span_ms = 1200
minimum_motion_ratio = 0.12
minimum_validated_contact_frames = 3
minimum_contact_confidence = 0.34
kinematic_contact_confidence_penalty = 0.82
kinematic_contact_lower_percentile = 0.65
kinematic_contact_motion_tolerance_ratio = 0.025
media_pipe_landmark_count = 33
dense_target_fps = 30
dense_interval_ms = 33
dense_window_radius_ms = 500
max_dense_frame_budget = 240
max_contact_windows = 8
minimum_contact_center_separation_ms = 180
coarse_ground_tolerance_ratio = 0.15
dense_ground_tolerance_ratio = 0.16
local_extremum_tolerance_ratio = 0.035
contact_motion_tolerance_ratio = 0.035
contact_motion_neighbor_gap_ms = 100
ground_line_sample_fraction = 0.45
ground_line_minimum_samples = 3

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
    ground_gap: float
    tolerance: float
    confidence: float
    in_ground_band: bool


@dataclass(frozen=True)
class GroundLine:
    slope: float
    intercept: float

    def y_at(self, x: float) -> float:
        return (self.slope * x) + self.intercept


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


def center_points(points: list[tuple[float, float]]) -> tuple[float, float]:
    return (
        sum(point[0] for point in points) / len(points),
        sum(point[1] for point in points) / len(points),
    )


def build_sample(timestamp_ms: int, landmarks, width: int, height: int):
    if len(landmarks) < media_pipe_landmark_count:
        return None
    core_names = [
        "left_shoulder",
        "right_shoulder",
        "left_hip",
        "right_hip",
        "left_knee",
        "right_knee",
        "left_ankle",
        "right_ankle",
    ]
    points = {name: point(landmarks, name, width, height) for name in core_names}
    shoulder_points = [
        points[name]
        for name in ("left_shoulder", "right_shoulder")
        if points[name] is not None
    ]
    hip_points = [
        points[name]
        for name in ("left_hip", "right_hip")
        if points[name] is not None
    ]
    if not shoulder_points or not hip_points:
        return None
    shoulder_center = center_points(shoulder_points)
    hip = center_points(hip_points)
    ankle_points = [
        points[name]
        for name in ("left_ankle", "right_ankle")
        if points[name] is not None
    ]
    scale = max(
        distance(shoulder_center, hip),
        distance(hip, center_points(ankle_points)) if ankle_points else 0.0,
    )
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


class SyntheticLandmark:
    def __init__(self, x: float, y: float, visible: float = 1.0):
        self.x = x
        self.y = y
        self.visibility = visible
        self.presence = visible


# Regression guard: a visible landing leg must remain usable even when the
# far-side knee and ankle are occluded at the same instant.
synthetic_landmarks = [SyntheticLandmark(0.5, 0.5) for _ in range(media_pipe_landmark_count)]
for name, x, y in (
    ("left_shoulder", 0.45, 0.25),
    ("right_shoulder", 0.55, 0.25),
    ("left_hip", 0.46, 0.54),
    ("right_hip", 0.54, 0.54),
    ("left_knee", 0.43, 0.72),
    ("left_ankle", 0.42, 0.90),
):
    synthetic_landmarks[LANDMARK[name]] = SyntheticLandmark(x, y)
synthetic_landmarks[LANDMARK["right_knee"]] = SyntheticLandmark(0.58, 0.72, visible=0.0)
synthetic_landmarks[LANDMARK["right_ankle"]] = SyntheticLandmark(0.59, 0.90, visible=0.0)
assert build_sample(0, synthetic_landmarks, 400, 800) is not None


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


def contact_knee_angle(sample: Sample, side: str) -> float | None:
    hip = point(sample.landmarks, side_name(side, "hip"), sample.width, sample.height)
    knee = point(sample.landmarks, side_name(side, "knee"), sample.width, sample.height)
    ankle = point(sample.landmarks, side_name(side, "ankle"), sample.width, sample.height)
    if hip is None or knee is None or ankle is None:
        return None
    return joint_angle(hip, knee, ankle)


def contact_landmark_confidence(sample: Sample, side: str, evidence) -> float | None:
    hip = point(sample.landmarks, side_name(side, "hip"), sample.width, sample.height)
    knee = point(sample.landmarks, side_name(side, "knee"), sample.width, sample.height)
    if hip is None or knee is None:
        return None
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


def percentile(values: list[float], fraction: float) -> float | None:
    if not values:
        return None
    ordered = sorted(values)
    position = max(0.0, min(1.0, fraction)) * (len(ordered) - 1)
    lower_index = int(math.floor(position))
    upper_index = int(math.ceil(position))
    if lower_index == upper_index:
        return ordered[lower_index]
    weight = position - lower_index
    return ordered[lower_index] + ((ordered[upper_index] - ordered[lower_index]) * weight)


def least_squares_ground_line(points: list[tuple[float, float, float]]) -> GroundLine:
    if not points:
        return GroundLine(slope=0.0, intercept=0.0)
    mean_x = sum(point[0] for point in points) / len(points)
    mean_y = sum(point[1] for point in points) / len(points)
    covariance = sum((point[0] - mean_x) * (point[1] - mean_y) for point in points)
    variance = sum((point[0] - mean_x) ** 2 for point in points)
    slope = 0.0 if variance <= 0.0001 else covariance / variance
    return GroundLine(slope=slope, intercept=mean_y - (slope * mean_x))


def ground_line_for_foot_evidence(foot_observations) -> GroundLine | None:
    points = [
        (evidence["bottom"][0], evidence["bottom"][1], sample.body_scale)
        for sample, _side, evidence in foot_observations
    ]
    if not points:
        return None
    lower_envelope_count = min(
        len(points),
        max(ground_line_minimum_samples, math.ceil(len(points) * ground_line_sample_fraction)),
    )
    lower_envelope = sorted(points, key=lambda point: point[1], reverse=True)[:lower_envelope_count]
    line = least_squares_ground_line(lower_envelope)
    residuals = [point[1] - line.y_at(point[0]) for point in lower_envelope]
    residual_center = percentile(residuals, 0.5) or 0.0
    median_deviation = percentile(
        [abs(residual - residual_center) for residual in residuals],
        0.5,
    ) or 0.0
    average_scale = max(1.0, sum(point[2] for point in lower_envelope) / len(lower_envelope))
    residual_tolerance = max(average_scale * 0.025, median_deviation * 2.5)
    inliers = [
        point
        for point in lower_envelope
        if abs(point[1] - line.y_at(point[0]) - residual_center) <= residual_tolerance
    ]
    if len(inliers) >= 2:
        line = least_squares_ground_line(inliers)
    return line


def ground_gap(ground_line: GroundLine, evidence) -> float:
    return ground_line.y_at(evidence["bottom"][0]) - evidence["bottom"][1]


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
    requested_interval_count = max(1, math.ceil(duration_ms / coarse_frame_interval_ms))
    interval_count = min(max_coarse_frame_budget - 1, requested_interval_count)
    return [
        min(duration_ms, max(0, round((duration_ms * index) / interval_count)))
        for index in range(interval_count + 1)
    ]


assert coarse_target_fps == 1000 // coarse_frame_interval_ms
assert coarse_timestamps(15_000) == list(range(0, 15_001, 100))
long_scan_timestamps = coarse_timestamps(60_000)
assert len(long_scan_timestamps) == max_coarse_frame_budget
assert long_scan_timestamps[0] == 0 and long_scan_timestamps[-1] == 60_000
assert all(
    later > earlier
    for earlier, later in zip(long_scan_timestamps, long_scan_timestamps[1:])
)


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
    foot_observations = []
    for sample in samples:
        for side in FOOT_SIDES:
            evidence = foot_bottom(sample, side)
            if evidence is not None:
                foot_observations.append((sample, side, evidence))
    ground_line = ground_line_for_foot_evidence(foot_observations)
    if ground_line is None:
        return [], GroundLine(slope=0.0, intercept=0.0)
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
            gap = ground_gap(ground_line, evidence)
            near_ground = (
                gap >= -ground_tolerance * 0.55
                and gap <= ground_tolerance * 1.1
            )
            local_extremum = (
                (previous_y is None or bottom_y >= previous_y - local_tolerance)
                and (next_y is None or bottom_y >= next_y - local_tolerance)
            )
            if not near_ground or not local_extremum:
                continue
            proximity_factor = max(
                0.0,
                min(1.0, 1.0 - (max(0.0, gap) / ground_tolerance)),
            )
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
            and abs(existing.center_timestamp_ms - candidate.center_timestamp_ms)
            < minimum_contact_center_separation_ms
            for existing in selected
        )
        if not overlaps:
            selected.append(candidate)
        if len(selected) >= max_contact_windows:
            break
    return sorted(selected, key=lambda item: item.center_timestamp_ms), ground_line


def dense_timestamps_for_windows(windows: list[ContactWindow], duration_ms: int) -> list[int]:
    selected_windows = windows[:max_contact_windows]
    if not selected_windows:
        return []
    per_window_budget = max(3, max_dense_frame_budget // len(selected_windows))
    timestamps: set[int] = set()
    for window in selected_windows:
        frame_times: list[int] = []
        timestamp_ms = window.start_timestamp_ms
        while timestamp_ms <= window.end_timestamp_ms:
            frame_times.append(min(duration_ms, max(0, timestamp_ms)))
            timestamp_ms += dense_interval_ms
        if not frame_times or frame_times[-1] != window.end_timestamp_ms:
            frame_times.append(min(duration_ms, max(0, window.end_timestamp_ms)))
        selected = set(
            sorted(
                frame_times,
                key=lambda timestamp: (abs(timestamp - window.center_timestamp_ms), timestamp),
            )[:min(3, per_window_budget)]
        )
        remaining = per_window_budget - len(selected)
        for index in range(remaining):
            fraction = 0.5 if remaining <= 1 else index / (remaining - 1)
            timestamp = round(
                window.start_timestamp_ms
                + ((window.end_timestamp_ms - window.start_timestamp_ms) * fraction)
            )
            selected.add(min(duration_ms, max(0, timestamp)))
        timestamps.update(selected)
    return sorted(timestamps)[:max_dense_frame_budget]


def validate_contact_frames(
    samples: list[Sample],
    windows: list[ContactWindow],
    ground_line: GroundLine,
    direction: str,
) -> list[ContactFrame]:
    selected_by_timestamp: dict[int, ContactFrame] = {}
    ordered_samples = sorted(samples, key=lambda item: item.timestamp_ms)
    for window in sorted(windows, key=lambda item: item.center_timestamp_ms):
        frame = select_contact_frame_for_window(
            window,
            ordered_samples=ordered_samples,
            ground_line=ground_line,
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
    ground_line: GroundLine,
    direction: str,
) -> ContactFrame | None:
    candidates = [
        candidate
        for sample in ordered_samples
        if window.start_timestamp_ms <= sample.timestamp_ms <= window.end_timestamp_ms
        for candidate in [dense_contact_candidate(sample, window.side, ground_line)]
        if candidate is not None
    ]
    temporal_candidates: list[ContactFrameCandidate] = []
    persistent_candidates: list[ContactFrameCandidate] = []
    for index, current in enumerate(candidates):
        if not is_eligible_contact(current):
            continue
        previous = candidates[index - 1] if index > 0 else None
        next_candidate = candidates[index + 1] if index + 1 < len(candidates) else None
        motion_reason = contact_motion_reason(current, previous, next_candidate)
        if motion_reason is not None:
            continue
        if entered_ground_band(current, previous):
            temporal_candidates.append(current)
        else:
            persistent_candidates.append(current)
    candidates_for_selection = temporal_candidates or persistent_candidates
    selected = (
        sorted(
            candidates_for_selection,
            key=lambda item: (
                -item.confidence,
                abs(item.sample.timestamp_ms - window.center_timestamp_ms),
                item.sample.timestamp_ms,
            ),
        )[0]
        if candidates_for_selection
        else None
    )
    strict_contact = (
        contact_frame_from_candidate(selected, window, direction, confidence=selected.confidence)
        if selected is not None
        else None
    )
    if strict_contact is not None:
        return strict_contact
    lower_envelope_y = percentile(
        [candidate.evidence["bottom"][1] for candidate in candidates],
        kinematic_contact_lower_percentile,
    )
    if lower_envelope_y is None:
        return None
    kinematic_candidates = [
        candidate
        for index, candidate in enumerate(candidates)
        if is_kinematic_contact_candidate(candidates, index, lower_envelope_y)
    ]
    if not kinematic_candidates:
        return None
    kinematic_candidate = sorted(
        kinematic_candidates,
        key=lambda item: (
            -item.confidence,
            abs(item.sample.timestamp_ms - window.center_timestamp_ms),
            item.sample.timestamp_ms,
        ),
    )[0]
    return contact_frame_from_candidate(
        kinematic_candidate,
        window,
        direction,
        confidence=kinematic_candidate.confidence * kinematic_contact_confidence_penalty,
    )


def dense_contact_candidate(sample: Sample, side: str, ground_line: GroundLine):
    evidence = foot_bottom(sample, side)
    if evidence is None:
        return None
    landmark_confidence = contact_landmark_confidence(sample, side, evidence)
    if landmark_confidence is None:
        return None
    tolerance = max(1.0, sample.body_scale * dense_ground_tolerance_ratio)
    gap = ground_gap(ground_line, evidence)
    proximity_factor = max(0.0, min(1.0, 1.0 - (max(0.0, gap) / tolerance)))
    contact_confidence = max(
        0.0,
        min(
            1.0,
            landmark_confidence
            * (0.75 + (0.25 * proximity_factor)),
        ),
    )
    return ContactFrameCandidate(
        sample=sample,
        side=side,
        evidence=evidence,
        ground_gap=gap,
        tolerance=tolerance,
        confidence=contact_confidence,
        in_ground_band=gap >= -tolerance * 0.55 and gap <= tolerance * 1.1,
    )


def is_eligible_contact(candidate: ContactFrameCandidate) -> bool:
    return candidate.in_ground_band and candidate.confidence >= minimum_contact_confidence


def entered_ground_band(
    current: ContactFrameCandidate,
    previous: ContactFrameCandidate | None,
) -> bool:
    return (
        previous is not None
        and previous.ground_gap > current.tolerance
        and abs(previous.sample.timestamp_ms - current.sample.timestamp_ms)
        <= contact_motion_neighbor_gap_ms
    )


def has_ground_band_persistence(
    current: ContactFrameCandidate,
    previous: ContactFrameCandidate | None,
    next_candidate: ContactFrameCandidate | None,
) -> bool:
    return any(
        neighbor is not None
        and is_eligible_contact(neighbor)
        and abs(neighbor.sample.timestamp_ms - current.sample.timestamp_ms)
        <= contact_motion_neighbor_gap_ms
        for neighbor in (previous, next_candidate)
    )


def contact_motion_reason(
    current: ContactFrameCandidate,
    previous: ContactFrameCandidate | None,
    next_candidate: ContactFrameCandidate | None,
) -> str | None:
    has_previous = (
        previous is not None
        and abs(current.sample.timestamp_ms - previous.sample.timestamp_ms)
        <= contact_motion_neighbor_gap_ms
    )
    has_next = (
        next_candidate is not None
        and abs(next_candidate.sample.timestamp_ms - current.sample.timestamp_ms)
        <= contact_motion_neighbor_gap_ms
    )
    if not has_previous and not has_next:
        return "insufficient_motion_window"
    tolerance = max(1.0, current.sample.body_scale * contact_motion_tolerance_ratio)
    current_y = current.evidence["bottom"][1]
    is_lowest_near_previous = (
        not has_previous
        or current_y >= previous.evidence["bottom"][1] - tolerance
    )
    is_lowest_near_next = (
        not has_next
        or current_y >= next_candidate.evidence["bottom"][1] - tolerance
    )
    if not is_lowest_near_previous or not is_lowest_near_next:
        return "unstable_foot_motion"
    if not has_ground_band_persistence(current, previous, next_candidate):
        return "insufficient_contact_persistence"
    return None


def is_kinematic_contact_candidate(
    candidates: list[ContactFrameCandidate],
    index: int,
    lower_envelope_y: float,
) -> bool:
    current = candidates[index]
    if (
        current.confidence < minimum_contact_confidence
        or current.evidence["bottom"][1] < lower_envelope_y
    ):
        return False
    previous = candidates[index - 1] if index > 0 else None
    next_candidate = candidates[index + 1] if index + 1 < len(candidates) else None
    has_previous = (
        previous is not None
        and abs(current.sample.timestamp_ms - previous.sample.timestamp_ms)
        <= contact_motion_neighbor_gap_ms
    )
    has_next = (
        next_candidate is not None
        and abs(next_candidate.sample.timestamp_ms - current.sample.timestamp_ms)
        <= contact_motion_neighbor_gap_ms
    )
    if not has_previous and not has_next:
        return False
    tolerance = max(1.0, current.sample.body_scale * kinematic_contact_motion_tolerance_ratio)
    current_y = current.evidence["bottom"][1]
    return (
        (not has_previous or current_y >= previous.evidence["bottom"][1] - tolerance)
        and (
            not has_next
            or current_y >= next_candidate.evidence["bottom"][1] - tolerance
        )
    )


def contact_frame_from_candidate(
    candidate: ContactFrameCandidate,
    window: ContactWindow,
    direction: str,
    confidence: float,
) -> ContactFrame | None:
    knee_angle = contact_knee_angle(candidate.sample, candidate.side)
    if knee_angle is None:
        return None
    return ContactFrame(
        timestamp_ms=candidate.sample.timestamp_ms,
        window_center_timestamp_ms=window.center_timestamp_ms,
        side=candidate.side,
        foot_strike_ratio=contact_foot_strike_ratio(candidate.sample, candidate.side, direction),
        knee_angle_degrees=knee_angle,
        confidence=confidence,
    )


overall_ok = True
for video in videos:
    capture = cv2.VideoCapture(str(video))
    if not capture.isOpened():
        raise RuntimeError(f"Could not open {video}")
    frame_count = int(capture.get(cv2.CAP_PROP_FRAME_COUNT) or 0)
    fps = float(capture.get(cv2.CAP_PROP_FPS) or dense_target_fps)
    duration_ms = max(0, round((frame_count / max(fps, 1.0)) * 1000))

    coarse_frame_timestamps = coarse_timestamps(duration_ms)
    coarse_pass = run_pose_pass(
        capture,
        fps=fps,
        frame_count=frame_count,
        timestamps_ms=coarse_frame_timestamps,
    )
    windows, ground_line = derive_contact_windows(coarse_pass["samples"], duration_ms)
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
        ground_line=ground_line,
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
    coarse_budget_ok = len(coarse_frame_timestamps) <= max_coarse_frame_budget
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
        and coarse_budget_ok
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
        f"{video.name}: coarse={len(coarse_pass['samples'])}/{len(coarse_frame_timestamps)} "
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
