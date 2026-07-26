#!/usr/bin/env python3
"""Render the portrait Running Coach guide video from the clothed source clip.

Requires the same OpenCV and MediaPipe packages installed by
scripts/test_running_release_video_fixtures.sh plus macOS ``avconvert``. The
result is H.264 MP4 so it can be played by the iOS and Android video players.
"""

from __future__ import annotations

import argparse
import shutil
import statistics
import subprocess
from pathlib import Path

import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE = REPO_ROOT / "assets/videos/running_coach_reference_sample.mp4"
DEFAULT_MODEL = REPO_ROOT / "ios/Runner/pose_landmarker_full.task"
DEFAULT_OUTPUT = REPO_ROOT / "assets/videos/running_coach_portrait_side_view_sample.mp4"
DEFAULT_INTERMEDIATE = REPO_ROOT / ".tmp/running_coach_portrait_sample_intermediate.mp4"
OUTPUT_WIDTH = 720
OUTPUT_HEIGHT = 1280
HIP_CONFIDENCE = 0.35
# The beach runner moves left-to-right. Reserve room in front of the runner so
# the lead shoe remains in the crop at touchdown.
FORWARD_ROOM_RATIO = 0.09


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--model", type=Path, default=DEFAULT_MODEL)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument(
        "--intermediate",
        type=Path,
        default=DEFAULT_INTERMEDIATE,
        help="temporary MP4V path created before H.264 conversion",
    )
    return parser.parse_args()


def pose_options(model: Path) -> vision.PoseLandmarkerOptions:
    return vision.PoseLandmarkerOptions(
        base_options=python.BaseOptions(model_asset_path=str(model)),
        running_mode=vision.RunningMode.VIDEO,
        num_poses=1,
        min_pose_detection_confidence=HIP_CONFIDENCE,
        min_pose_presence_confidence=HIP_CONFIDENCE,
        min_tracking_confidence=HIP_CONFIDENCE,
    )


def measure_fixed_crop_center(source: Path, model: Path) -> float:
    capture = cv2.VideoCapture(str(source))
    if not capture.isOpened():
        raise RuntimeError(f"Could not open source video: {source}")

    fps = float(capture.get(cv2.CAP_PROP_FPS) or 0.0)
    width = int(capture.get(cv2.CAP_PROP_FRAME_WIDTH) or 0)
    if fps <= 0 or width <= 0:
        capture.release()
        raise RuntimeError(f"Invalid source video metadata: {source}")

    hip_centers: list[float] = []
    frame_index = 0
    try:
        with vision.PoseLandmarker.create_from_options(pose_options(model)) as detector:
            while True:
                ok, frame = capture.read()
                if not ok:
                    break
                result = detector.detect_for_video(
                    mp.Image(
                        image_format=mp.ImageFormat.SRGB,
                        data=cv2.cvtColor(frame, cv2.COLOR_BGR2RGB),
                    ),
                    round((frame_index / fps) * 1000),
                )
                if result.pose_landmarks:
                    landmarks = result.pose_landmarks[0]
                    hip_confidence = min(
                        float(landmarks[index].visibility or 0)
                        for index in (23, 24)
                    )
                    if hip_confidence >= HIP_CONFIDENCE:
                        hip_centers.append(
                            (float(landmarks[23].x) + float(landmarks[24].x))
                            * width
                            / 2
                        )
                frame_index += 1
    finally:
        capture.release()

    return statistics.median(hip_centers) if hip_centers else width / 2


def render_portrait(
    source: Path,
    crop_center_x: float,
    intermediate: Path,
) -> tuple[int, float]:
    capture = cv2.VideoCapture(str(source))
    if not capture.isOpened():
        raise RuntimeError(f"Could not open source video: {source}")

    fps = float(capture.get(cv2.CAP_PROP_FPS) or 0.0)
    width = int(capture.get(cv2.CAP_PROP_FRAME_WIDTH) or 0)
    height = int(capture.get(cv2.CAP_PROP_FRAME_HEIGHT) or 0)
    if fps <= 0 or width <= 0 or height <= 0:
        capture.release()
        raise RuntimeError(f"Invalid source video metadata: {source}")

    crop_width = round(height * 9 / 16)
    if crop_width > width:
        capture.release()
        raise RuntimeError(f"Source is too narrow for a 9:16 crop: {source}")

    intermediate.parent.mkdir(parents=True, exist_ok=True)
    writer = cv2.VideoWriter(
        str(intermediate),
        cv2.VideoWriter_fourcc(*"mp4v"),
        fps,
        (OUTPUT_WIDTH, OUTPUT_HEIGHT),
    )
    if not writer.isOpened():
        capture.release()
        raise RuntimeError("OpenCV could not create the portrait MP4V intermediate.")

    framed_center_x = crop_center_x - crop_width * FORWARD_ROOM_RATIO
    crop_left = round(
        max(0, min(width - crop_width, framed_center_x - crop_width / 2))
    )
    frames_written = 0
    try:
        while True:
            ok, frame = capture.read()
            if not ok:
                break
            crop = frame[:, crop_left : crop_left + crop_width]
            crop = cv2.resize(
                crop,
                (OUTPUT_WIDTH, OUTPUT_HEIGHT),
                interpolation=cv2.INTER_LANCZOS4,
            )
            # Small unsharp mask preserves contact-edge detail after encoding.
            blurred = cv2.GaussianBlur(crop, (0, 0), 1.1)
            writer.write(cv2.addWeighted(crop, 1.65, blurred, -0.65, 0))
            frames_written += 1
    finally:
        writer.release()
        capture.release()
    return frames_written, fps


def encode_h264(intermediate: Path, output: Path) -> None:
    avconvert = shutil.which("avconvert")
    if avconvert is None:
        raise RuntimeError("Missing avconvert; run this script on macOS to encode H.264.")
    output.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            avconvert,
            "--source",
            str(intermediate),
            "--preset",
            "PresetHighestQuality",
            "--output",
            str(output),
            "--replace",
        ],
        check=True,
    )


def main() -> int:
    args = parse_args()
    source = args.source.resolve()
    model = args.model.resolve()
    output = args.output.resolve()
    intermediate = args.intermediate.resolve()
    if not source.is_file():
        raise SystemExit(f"Missing source video: {source}")
    if not model.is_file():
        raise SystemExit(f"Missing pose model: {model}")

    crop_center_x = measure_fixed_crop_center(source, model)
    frames_written, fps = render_portrait(source, crop_center_x, intermediate)
    if frames_written < 8:
        raise RuntimeError(f"Only rendered {frames_written} frames from {source}")
    encode_h264(intermediate, output)
    print(
        f"[running-coach-portrait-sample] rendered {frames_written} frames "
        f"at {fps:.3f}fps with crop center {crop_center_x:.1f}: {output}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
