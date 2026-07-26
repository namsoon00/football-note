#!/usr/bin/env python3
"""Analyze generated real-video fixtures with the bundled MediaPipe pose model."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import statistics
import sys
from datetime import datetime, timezone
from pathlib import Path

import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision


REPO_ROOT = Path(__file__).resolve().parents[1]
TMP_ROOT = REPO_ROOT / ".tmp"
MIN_LANDMARK_CONFIDENCE = 0.35
MIN_POSE_FRAMES = 8
MIN_FULL_BODY_FRAMES = 5
MIN_LOWER_BODY_FRAMES = 4
MIN_ANKLE_FOOT_FRAMES = 4
MIN_TIMESTAMP_SPAN_MS = 800
MIN_HIP_TRAVEL_TO_TORSO_RATIO = 0.12
MAX_SAMPLED_FRAMES = 30
MINIMUM_NATIVE_SHARPNESS = 0.018
MAX_ANKLE_REGION_DARK_RATIO = 0.55

FULL_BODY_INDICES = (11, 12, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32)
LOWER_BODY_INDICES = (23, 24, 25, 26, 27, 28)
ANKLE_FOOT_INDICES = (27, 28, 29, 30, 31, 32)
TORSO_INDICES = (11, 12, 23, 24)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def ensure_under_tmp(path: Path, label: str) -> Path:
    resolved = path.resolve()
    tmp_root = TMP_ROOT.resolve()
    try:
        resolved.relative_to(tmp_root)
    except ValueError as exc:
        raise SystemExit(
            f"{label} must be under {TMP_ROOT.relative_to(REPO_ROOT)}: {resolved}"
        ) from exc
    return resolved


def landmark_confidence(landmark) -> float:
    values = []
    if landmark.visibility is not None:
        values.append(float(landmark.visibility))
    if landmark.presence is not None:
        values.append(float(landmark.presence))
    return min(values) if values else 0.0


def landmark_group_confidence(landmarks: list, indices: tuple[int, ...]) -> float:
    if len(landmarks) <= max(indices):
        return 0.0
    return min(landmark_confidence(landmarks[index]) for index in indices)


def center(landmarks: list, left: int, right: int) -> tuple[float, float] | None:
    if len(landmarks) <= max(left, right):
        return None
    if landmark_confidence(landmarks[left]) < MIN_LANDMARK_CONFIDENCE:
        return None
    if landmark_confidence(landmarks[right]) < MIN_LANDMARK_CONFIDENCE:
        return None
    return (
        (float(landmarks[left].x) + float(landmarks[right].x)) / 2.0,
        (float(landmarks[left].y) + float(landmarks[right].y)) / 2.0,
    )


def point_distance(first: tuple[float, float], second: tuple[float, float]) -> float:
    return math.hypot(first[0] - second[0], first[1] - second[1])


def motion_sample(landmarks: list) -> dict | None:
    if landmark_group_confidence(landmarks, TORSO_INDICES) < MIN_LANDMARK_CONFIDENCE:
        return None
    shoulder_center = center(landmarks, 11, 12)
    hip_center = center(landmarks, 23, 24)
    if shoulder_center is None or hip_center is None:
        return None
    return {
        "hip": hip_center,
        "torsoScale": max(point_distance(shoulder_center, hip_center), 0.001),
    }


def foreground_bounds(fixture: dict) -> tuple[int, int]:
    output_width = int(fixture["output"]["width"])
    output_height = int(fixture["output"]["height"])
    source_width = int(fixture["source"]["width"])
    source_height = int(fixture["source"]["height"])
    fitted_height = max(1, round(source_height * (output_width / source_width)))
    top = max(0, (output_height - fitted_height) // 2)
    bottom = min(output_height, top + fitted_height)
    return top, bottom


def native_frame_sharpness(frame: object) -> float:
    height, width = frame.shape[:2]
    # Match the mobile analyzers: inspect the central runner band, sample it at
    # a fixed resolution without smoothing, then measure luma Laplacian spread.
    crop_left = int(width * 0.10)
    crop_right = width - crop_left
    crop_top = int(height * 0.32)
    crop_bottom = int(height * 0.68)
    crop = frame[crop_top:crop_bottom, crop_left:crop_right]
    if crop.shape[0] < 3 or crop.shape[1] < 3:
        return 0.0
    sample = cv2.resize(crop, (96, 64), interpolation=cv2.INTER_NEAREST)
    luminance = (
        sample[:, :, 2].astype("float64") * 0.299
        + sample[:, :, 1].astype("float64") * 0.587
        + sample[:, :, 0].astype("float64") * 0.114
    ) / 255.0
    center = luminance[1:-1, 1:-1]
    laplacian = (
        4.0 * center
        - luminance[1:-1, :-2]
        - luminance[1:-1, 2:]
        - luminance[:-2, 1:-1]
        - luminance[2:, 1:-1]
    )
    return float(laplacian.var())


def ankle_region_dark_ratio(frame: object, fixture: dict) -> float:
    top, bottom = foreground_bounds(fixture)
    height, width = frame.shape[:2]
    foreground_height = max(1, bottom - top)
    y1 = min(height, top + round(foreground_height * 0.62))
    y2 = min(height, top + round(foreground_height * 0.94))
    x_margin = round(width * 0.15)
    if y2 <= y1 or width - x_margin <= x_margin:
        return 0.0
    crop = frame[y1:y2, x_margin : width - x_margin]
    gray = cv2.cvtColor(crop, cv2.COLOR_BGR2GRAY)
    return float((gray < 48).mean())


def pose_options(model_path: Path) -> vision.PoseLandmarkerOptions:
    return vision.PoseLandmarkerOptions(
        base_options=python.BaseOptions(model_asset_path=str(model_path)),
        running_mode=vision.RunningMode.VIDEO,
        num_poses=1,
        min_pose_detection_confidence=MIN_LANDMARK_CONFIDENCE,
        min_pose_presence_confidence=MIN_LANDMARK_CONFIDENCE,
        min_tracking_confidence=MIN_LANDMARK_CONFIDENCE,
    )


def analyze_fixture(fixture: dict, output_dir: Path, model_path: Path, repo_root: Path) -> dict:
    video_path = output_dir / fixture["video"]
    if not video_path.is_file():
        raise FileNotFoundError(f"Fixture video is missing: {video_path}")

    source_path = repo_root / fixture["sourceVideo"]
    source_hash_matches = source_path.is_file() and sha256(source_path) == fixture["sourceSha256"]
    generated_video_sha256 = sha256(video_path)
    expected_fixture_sha256 = fixture.get("generatedVideoSha256")
    fixture_hash_matches = (
        isinstance(expected_fixture_sha256, str)
        and expected_fixture_sha256 == generated_video_sha256
    )
    capture = cv2.VideoCapture(str(video_path))
    if not capture.isOpened():
        raise RuntimeError(f"Could not open generated fixture: {video_path}")

    fps = float(capture.get(cv2.CAP_PROP_FPS) or 0.0)
    total_frames = int(capture.get(cv2.CAP_PROP_FRAME_COUNT) or 0)
    frame_width = int(capture.get(cv2.CAP_PROP_FRAME_WIDTH) or 0)
    frame_height = int(capture.get(cv2.CAP_PROP_FRAME_HEIGHT) or 0)
    if fps <= 0 or total_frames <= 0:
        capture.release()
        raise RuntimeError(f"Invalid generated fixture metadata: {video_path}")
    frame_stride = max(1, math.ceil(total_frames / MAX_SAMPLED_FRAMES))

    sampled_frames = 0
    pose_frames = 0
    full_body_frames = 0
    lower_body_frames = 0
    ankle_foot_frames = 0
    timestamps: list[int] = []
    full_body_confidences: list[float] = []
    lower_body_confidences: list[float] = []
    ankle_foot_confidences: list[float] = []
    motion_samples: list[dict] = []
    native_sharpness_values: list[float] = []
    ankle_dark_ratios: list[float] = []

    try:
        with vision.PoseLandmarker.create_from_options(pose_options(model_path)) as landmarker:
            frame_index = 0
            while True:
                ok, frame = capture.read()
                if not ok:
                    break
                if frame_index % frame_stride != 0:
                    frame_index += 1
                    continue

                timestamp_ms = round((frame_index / fps) * 1000)
                rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
                result = landmarker.detect_for_video(image, timestamp_ms)
                sampled_frames += 1
                native_sharpness_values.append(native_frame_sharpness(frame))

                if result.pose_landmarks:
                    landmarks = result.pose_landmarks[0]
                    pose_frames += 1
                    timestamps.append(timestamp_ms)
                    full_body_confidence = landmark_group_confidence(landmarks, FULL_BODY_INDICES)
                    lower_body_confidence = landmark_group_confidence(landmarks, LOWER_BODY_INDICES)
                    ankle_foot_confidence = landmark_group_confidence(landmarks, ANKLE_FOOT_INDICES)
                    full_body_confidences.append(full_body_confidence)
                    lower_body_confidences.append(lower_body_confidence)
                    ankle_foot_confidences.append(ankle_foot_confidence)
                    if full_body_confidence >= MIN_LANDMARK_CONFIDENCE:
                        full_body_frames += 1
                    if lower_body_confidence >= MIN_LANDMARK_CONFIDENCE:
                        lower_body_frames += 1
                    if ankle_foot_confidence >= MIN_LANDMARK_CONFIDENCE:
                        ankle_foot_frames += 1
                    sample = motion_sample(landmarks)
                    if sample is not None:
                        motion_samples.append(sample)
                ankle_dark_ratios.append(ankle_region_dark_ratio(frame, fixture))
                frame_index += 1
    finally:
        capture.release()

    timestamp_span_ms = (timestamps[-1] - timestamps[0]) if len(timestamps) >= 2 else 0
    hip_travel_to_torso_ratio = 0.0
    if len(motion_samples) >= 2:
        hip_x_values = [sample["hip"][0] for sample in motion_samples]
        torso_scale = statistics.median(sample["torsoScale"] for sample in motion_samples)
        hip_travel_to_torso_ratio = (
            (max(hip_x_values) - min(hip_x_values)) / max(torso_scale, 0.001)
        )

    return {
        "id": fixture["id"],
        "video": fixture["video"],
        "source": {
            "video": fixture["sourceVideo"],
            "sha256": fixture["sourceSha256"],
            "sha256MatchesRepository": source_hash_matches,
        },
        "fixture": {
            "sha256": generated_video_sha256,
            "sha256MatchesManifest": fixture_hash_matches,
        },
        "expected": {
            "scoringAllowed": fixture["expectedScoringAllowed"],
            "rejectionReasons": fixture.get(
                "expectedRejectionReasons",
                [fixture.get("expectedRejectionReason")]
                if fixture.get("expectedRejectionReason")
                else [],
            ),
        },
        "conditions": fixture["conditions"],
        "transform": fixture["transform"],
        "media": {
            "width": frame_width or fixture["output"]["width"],
            "height": frame_height or fixture["output"]["height"],
            "fps": fps,
            "totalFrames": total_frames,
            "sampledFrames": sampled_frames,
        },
        "poseEvidence": {
            "poseFrames": pose_frames,
            "fullBodyFrames": full_body_frames,
            "lowerBodyFrames": lower_body_frames,
            "ankleFootFrames": ankle_foot_frames,
            "poseFrameRatio": pose_frames / sampled_frames if sampled_frames else 0.0,
            "fullBodyFrameRatio": full_body_frames / sampled_frames if sampled_frames else 0.0,
            "lowerBodyFrameRatio": lower_body_frames / sampled_frames if sampled_frames else 0.0,
            "ankleFootFrameRatio": ankle_foot_frames / sampled_frames if sampled_frames else 0.0,
            "timestampSpanMs": timestamp_span_ms,
            "medianFullBodyConfidence": statistics.median(full_body_confidences)
            if full_body_confidences
            else 0.0,
            "medianLowerBodyConfidence": statistics.median(lower_body_confidences)
            if lower_body_confidences
            else 0.0,
            "medianAnkleFootConfidence": statistics.median(ankle_foot_confidences)
            if ankle_foot_confidences
            else 0.0,
            "hipTravelToTorsoRatio": hip_travel_to_torso_ratio,
        },
        "imageEvidence": {
            "medianNativeSharpness": statistics.median(native_sharpness_values)
            if native_sharpness_values
            else 0.0,
            "medianAnkleRegionDarkRatio": statistics.median(ankle_dark_ratios)
            if ankle_dark_ratios
            else 0.0,
        },
    }


def quality_gate(result: dict) -> dict:
    pose = result["poseEvidence"]
    image = result["imageEvidence"]
    reasons: list[str] = []
    if not result["source"]["sha256MatchesRepository"]:
        reasons.append("source_video_hash_mismatch")
    if not result["fixture"]["sha256MatchesManifest"]:
        reasons.append("fixture_video_hash_mismatch")
    if pose["poseFrames"] < MIN_POSE_FRAMES:
        reasons.append("insufficient_pose_frames")
    if pose["fullBodyFrames"] < MIN_FULL_BODY_FRAMES:
        reasons.append("full_body_not_visible")
    if pose["lowerBodyFrames"] < MIN_LOWER_BODY_FRAMES:
        reasons.append("lower_body_not_visible")
    if pose["ankleFootFrames"] < MIN_ANKLE_FOOT_FRAMES:
        reasons.append("ankles_not_visible")
    if pose["timestampSpanMs"] < MIN_TIMESTAMP_SPAN_MS:
        reasons.append("insufficient_pose_time_span")
    if pose["hipTravelToTorsoRatio"] < MIN_HIP_TRAVEL_TO_TORSO_RATIO:
        reasons.append("insufficient_motion_evidence")
    if image["medianNativeSharpness"] < MINIMUM_NATIVE_SHARPNESS:
        reasons.append("image_too_blurry")
    if image["medianAnkleRegionDarkRatio"] > MAX_ANKLE_REGION_DARK_RATIO:
        reasons.append("ankle_region_occluded")
    return {
        "scoringAllowed": not reasons,
        "reasons": reasons,
        "minimumNativeSharpness": MINIMUM_NATIVE_SHARPNESS,
        "maximumAnkleRegionDarkRatio": MAX_ANKLE_REGION_DARK_RATIO,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--fixture-dir",
        type=Path,
        default=Path(".tmp/running-release-video-validation"),
        help="directory containing fixture_manifest.json and generated MP4 files",
    )
    parser.add_argument(
        "--model",
        type=Path,
        default=Path("ios/Runner/pose_landmarker_full.task"),
        help="MediaPipe Pose Landmarker task model",
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path("."),
        help="repository root used to verify source video hashes",
    )
    parser.add_argument(
        "--report",
        type=Path,
        default=None,
        help="JSON report destination (defaults to fixture-dir/release_validation_report.json)",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    fixture_dir = ensure_under_tmp(args.fixture_dir, "Fixture directory")
    model_path = args.model.resolve()
    repo_root = args.repo_root.resolve()
    manifest_path = fixture_dir / "fixture_manifest.json"
    if not model_path.is_file():
        raise SystemExit(f"Missing MediaPipe model: {model_path}")
    if not manifest_path.is_file():
        raise SystemExit(f"Missing fixture manifest: {manifest_path}")

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    fixtures = manifest.get("fixtures")
    if not isinstance(fixtures, list) or not fixtures:
        raise SystemExit("Fixture manifest must contain at least one fixture.")

    results = [analyze_fixture(fixture, fixture_dir, model_path, repo_root) for fixture in fixtures]
    all_matches = True
    for result in results:
        gate = quality_gate(result)
        expected = result["expected"]
        expected_reasons = [
            reason for reason in expected.get("rejectionReasons", []) if reason
        ]
        reason_matches = expected["scoringAllowed"] or any(
            reason in gate["reasons"] for reason in expected_reasons
        )
        result["qualityGate"] = gate
        result["validation"] = {
            "matchesExpectedScoringDecision": gate["scoringAllowed"]
            == expected["scoringAllowed"],
            "matchesExpectedRejectionReason": reason_matches,
        }
        all_matches = all_matches and all(result["validation"].values())

    report = {
        "schemaVersion": 1,
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "provenance": manifest["provenance"],
        "analyzer": {
            "model": str(model_path.relative_to(repo_root)),
            "mode": "MediaPipe Tasks VIDEO",
            "minimumLandmarkConfidence": MIN_LANDMARK_CONFIDENCE,
            "thresholds": {
                "minimumPoseFrames": MIN_POSE_FRAMES,
                "minimumFullBodyFrames": MIN_FULL_BODY_FRAMES,
                "minimumLowerBodyFrames": MIN_LOWER_BODY_FRAMES,
                "minimumAnkleFootFrames": MIN_ANKLE_FOOT_FRAMES,
                "minimumTimestampSpanMs": MIN_TIMESTAMP_SPAN_MS,
                "minimumHipTravelToTorsoRatio": MIN_HIP_TRAVEL_TO_TORSO_RATIO,
                "minimumNativeSharpness": MINIMUM_NATIVE_SHARPNESS,
                "maximumAnkleRegionDarkRatio": MAX_ANKLE_REGION_DARK_RATIO,
            },
        },
        "releaseGate": {
            "passed": all_matches,
            "verdict": "CONDITIONAL_NOT_DEVICE_APPROVED" if all_matches else "FAILED",
            "deviceApproval": False,
            "limitations": [
                "Fixture videos are derived from repository samples, not new physical-device recordings.",
                "This invokes the shared .task model through Python MediaPipe, not the iOS or Android camera/plugin path.",
                "The source samples do not prove landscape handling, walking-vs-running classification, or sprint-quality correctness.",
                "Physical iPhone and Android portrait capture, upload, overlay orientation, thermal, and latency validation remain required before release approval.",
            ],
        },
        "fixtures": results,
    }
    report_path = (
        ensure_under_tmp(args.report, "Report path")
        if args.report
        else fixture_dir / "release_validation_report.json"
    )
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    for result in results:
        gate = result["qualityGate"]
        expectation = "allow" if result["expected"]["scoringAllowed"] else "reject"
        actual = "allow" if gate["scoringAllowed"] else "reject"
        details = ",".join(gate["reasons"]) or "none"
        print(f"{result['id']}: expected={expectation} actual={actual} reasons={details}")
    print(f"[running-release-validation] report: {report_path}")
    print(f"[running-release-validation] verdict: {report['releaseGate']['verdict']}")
    return 0 if all_matches else 2


if __name__ == "__main__":
    raise SystemExit(main())
