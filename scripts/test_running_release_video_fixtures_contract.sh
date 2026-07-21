#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

python3 -m py_compile \
  scripts/generate_running_release_video_fixtures.py \
  scripts/analyze_running_release_video_fixtures.py

python3 - <<'PY'
from pathlib import Path

generator = Path("scripts/generate_running_release_video_fixtures.py").read_text(encoding="utf-8")
analyzer = Path("scripts/analyze_running_release_video_fixtures.py").read_text(encoding="utf-8")
runner = Path("scripts/test_running_release_video_fixtures.sh").read_text(encoding="utf-8")

for expected in (
    "portrait_reference_full_body",
    "portrait_track_full_body",
    "portrait_lower_body_cropped",
    "portrait_ankle_occluded",
    "portrait_strong_motion_blur",
    "sourceSha256",
    "generatedVideoSha256",
    "derived_from_repository_real_runner_samples",
    "Generated fixture output must be under",
    "expectedRejectionReasons",
):
    assert expected in generator, expected

for expected in (
    "MediaPipe Tasks VIDEO",
    "fixture_video_hash_mismatch",
    "full_body_not_visible",
    "lower_body_not_visible",
    "ankles_not_visible",
    "ankle_region_occluded",
    "insufficient_motion_evidence",
    "image_too_blurry",
    "native_frame_sharpness",
    "medianNativeSharpness",
    "MINIMUM_NATIVE_SHARPNESS = 0.018",
    "hipTravelToTorsoRatio",
    "CONDITIONAL_NOT_DEVICE_APPROVED",
    "release_validation_report.json",
):
    assert expected in analyzer, expected

for expected in (
    "mediapipe==0.10.21",
    "opencv-python-headless==4.10.0.84",
    "pose_landmarker_lite.task",
    "--output-dir",
    "release_validation.log",
):
    assert expected in runner, expected
PY

echo "[running-release-video-fixtures-contract] ok"
