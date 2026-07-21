#!/usr/bin/env python3
"""Create reproducible portrait video fixtures from the bundled runner clips.

The fixtures retain real human-runner frames from the repository samples. They
are intentionally derived clips, not new device recordings. Generated media is
written below .tmp and must not be committed.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Callable

import cv2
import numpy as np


REPO_ROOT = Path(__file__).resolve().parents[1]
TMP_ROOT = REPO_ROOT / ".tmp"
TARGET_WIDTH = 720
TARGET_HEIGHT = 1280
DEFAULT_FPS = 15.0
DEFAULT_DURATION_SECONDS = 2.0


@dataclass(frozen=True)
class FixtureSpec:
    identifier: str
    source_filename: str
    expected_scoring_allowed: bool
    expected_rejection_reasons: tuple[str, ...]
    conditions: tuple[str, ...]
    transform: Callable[[np.ndarray], np.ndarray]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def ensure_under_tmp(path: Path) -> Path:
    resolved = path.resolve()
    tmp_root = TMP_ROOT.resolve()
    try:
        resolved.relative_to(tmp_root)
    except ValueError as exc:
        raise SystemExit(
            f"Generated fixture output must be under {TMP_ROOT.relative_to(REPO_ROOT)}: {resolved}"
        ) from exc
    return resolved


def portrait_canvas(frame: np.ndarray) -> np.ndarray:
    """Fit a landscape source on a 9:16 canvas with a blurred source backdrop."""
    source_height, source_width = frame.shape[:2]
    scale = TARGET_WIDTH / source_width
    fitted_height = max(1, round(source_height * scale))
    fitted = cv2.resize(
        frame,
        (TARGET_WIDTH, fitted_height),
        interpolation=cv2.INTER_AREA if scale < 1 else cv2.INTER_LINEAR,
    )
    backdrop = cv2.resize(frame, (TARGET_WIDTH, TARGET_HEIGHT), interpolation=cv2.INTER_LINEAR)
    backdrop = cv2.GaussianBlur(backdrop, (0, 0), 22)
    top = (TARGET_HEIGHT - fitted_height) // 2
    backdrop[top : top + fitted_height, :TARGET_WIDTH] = fitted
    return backdrop


def lower_body_crop(frame: np.ndarray) -> np.ndarray:
    canvas = portrait_canvas(frame)
    source_height, source_width = frame.shape[:2]
    fitted_height = max(1, round(source_height * (TARGET_WIDTH / source_width)))
    top = (TARGET_HEIGHT - fitted_height) // 2
    # This removes the runner's lower third from the clear foreground plane.
    crop_start = top + round(fitted_height * 0.67)
    canvas[crop_start : top + fitted_height, :TARGET_WIDTH] = (18, 22, 30)
    return canvas


def ankle_occlusion(frame: np.ndarray) -> np.ndarray:
    canvas = portrait_canvas(frame)
    source_height, source_width = frame.shape[:2]
    fitted_height = max(1, round(source_height * (TARGET_WIDTH / source_width)))
    top = (TARGET_HEIGHT - fitted_height) // 2
    # An opaque foreground band covers the expected lower-leg/ankle zone.
    y1 = top + round(fitted_height * 0.62)
    y2 = top + round(fitted_height * 0.93)
    x_margin = round(TARGET_WIDTH * 0.15)
    canvas[y1:y2, x_margin : TARGET_WIDTH - x_margin] = (26, 30, 38)
    return canvas


def motion_blur(frame: np.ndarray) -> np.ndarray:
    kernel = np.zeros((1, 31), dtype=np.float32)
    kernel[0, :] = 1.0 / kernel.shape[1]
    blurred = cv2.filter2D(frame, -1, kernel)
    return portrait_canvas(blurred)


def build_specs() -> tuple[FixtureSpec, ...]:
    return (
        FixtureSpec(
            identifier="portrait_reference_full_body",
            source_filename="running_coach_reference_sample.mp4",
            expected_scoring_allowed=True,
            expected_rejection_reasons=(),
            conditions=("portrait_9_16", "full_body", "derived_real_runner_frames"),
            transform=portrait_canvas,
        ),
        FixtureSpec(
            identifier="portrait_track_full_body",
            source_filename="running_coach_mistake_sample.mp4",
            expected_scoring_allowed=True,
            expected_rejection_reasons=(),
            conditions=("portrait_9_16", "full_body", "derived_real_runner_frames"),
            transform=portrait_canvas,
        ),
        FixtureSpec(
            identifier="portrait_lower_body_cropped",
            source_filename="running_coach_reference_sample.mp4",
            expected_scoring_allowed=False,
            expected_rejection_reasons=(
                "full_body_not_visible",
                "lower_body_not_visible",
                "ankle_region_occluded",
            ),
            conditions=("portrait_9_16", "lower_body_cropped", "derived_real_runner_frames"),
            transform=lower_body_crop,
        ),
        FixtureSpec(
            identifier="portrait_ankle_occluded",
            source_filename="running_coach_reference_sample.mp4",
            expected_scoring_allowed=False,
            expected_rejection_reasons=(
                "ankles_not_visible",
                "ankle_region_occluded",
            ),
            conditions=("portrait_9_16", "ankle_occluded", "derived_real_runner_frames"),
            transform=ankle_occlusion,
        ),
        FixtureSpec(
            identifier="portrait_strong_motion_blur",
            source_filename="running_coach_reference_sample.mp4",
            expected_scoring_allowed=False,
            expected_rejection_reasons=("image_too_blurry",),
            conditions=("portrait_9_16", "strong_motion_blur", "derived_real_runner_frames"),
            transform=motion_blur,
        ),
    )


def generate_fixture(
    spec: FixtureSpec,
    source_dir: Path,
    output_dir: Path,
    output_fps: float,
    duration_seconds: float,
) -> dict:
    source_path = source_dir / spec.source_filename
    if not source_path.is_file():
        raise FileNotFoundError(f"Missing source video: {source_path}")

    capture = cv2.VideoCapture(str(source_path))
    if not capture.isOpened():
        raise RuntimeError(f"Could not open source video: {source_path}")

    source_fps = float(capture.get(cv2.CAP_PROP_FPS) or 0.0)
    source_width = int(capture.get(cv2.CAP_PROP_FRAME_WIDTH) or 0)
    source_height = int(capture.get(cv2.CAP_PROP_FRAME_HEIGHT) or 0)
    source_frames = int(capture.get(cv2.CAP_PROP_FRAME_COUNT) or 0)
    if source_fps <= 0 or source_width <= 0 or source_height <= 0:
        capture.release()
        raise RuntimeError(f"Invalid source video metadata: {source_path}")

    target_frame_count = max(1, round(output_fps * duration_seconds))
    frame_step = max(1, round(source_fps / output_fps))
    output_path = output_dir / f"{spec.identifier}.mp4"
    writer = cv2.VideoWriter(
        str(output_path),
        cv2.VideoWriter_fourcc(*"mp4v"),
        output_fps,
        (TARGET_WIDTH, TARGET_HEIGHT),
    )
    if not writer.isOpened():
        capture.release()
        raise RuntimeError(
            "OpenCV could not create an MP4 fixture. Install an OpenCV build with MP4V support."
        )

    written = 0
    read_index = 0
    try:
        while written < target_frame_count:
            ok, frame = capture.read()
            if not ok:
                break
            if read_index % frame_step == 0:
                writer.write(spec.transform(frame))
                written += 1
            read_index += 1
    finally:
        writer.release()
        capture.release()

    if written < max(8, round(target_frame_count * 0.8)):
        raise RuntimeError(
            f"{source_path.name} ended after {written} output frames; expected {target_frame_count}."
        )

    return {
        "id": spec.identifier,
        "video": output_path.name,
        "sourceVideo": f"assets/videos/{spec.source_filename}",
        "sourceSha256": sha256(source_path),
        "generatedVideoSha256": sha256(output_path),
        "expectedScoringAllowed": spec.expected_scoring_allowed,
        "expectedRejectionReasons": list(spec.expected_rejection_reasons),
        "conditions": list(spec.conditions),
        "transform": {
            "canvas": "9:16 portrait, 720x1280",
            "foreground": "fit-width source frame over blurred source backdrop",
            "variant": spec.identifier,
            "frameSource": "actual repository runner sample frames",
        },
        "source": {
            "width": source_width,
            "height": source_height,
            "fps": source_fps,
            "frameCount": source_frames,
        },
        "output": {
            "width": TARGET_WIDTH,
            "height": TARGET_HEIGHT,
            "fps": output_fps,
            "frameCount": written,
        },
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source-dir",
        type=Path,
        default=Path("assets/videos"),
        help="directory containing the bundled source MP4 files",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path(".tmp/running-release-video-validation"),
        help="directory for generated videos and fixture_manifest.json",
    )
    parser.add_argument("--fps", type=float, default=DEFAULT_FPS, help="fixture FPS")
    parser.add_argument(
        "--duration-seconds",
        type=float,
        default=DEFAULT_DURATION_SECONDS,
        help="duration of each generated fixture",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.fps <= 0 or args.duration_seconds <= 0:
        raise SystemExit("--fps and --duration-seconds must both be positive.")

    source_dir = args.source_dir.resolve()
    output_dir = ensure_under_tmp(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    fixtures = [
        generate_fixture(
            spec,
            source_dir=source_dir,
            output_dir=output_dir,
            output_fps=args.fps,
            duration_seconds=args.duration_seconds,
        )
        for spec in build_specs()
    ]
    manifest = {
        "schemaVersion": 1,
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "provenance": {
            "recordingStatus": "derived_from_repository_real_runner_samples",
            "claim": "These are reproducible transformations of bundled videos, not new device recordings.",
        },
        "fixtures": fixtures,
    }
    manifest_path = output_dir / "fixture_manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"[running-release-fixtures] generated {len(fixtures)} videos in {output_dir}")
    print(f"[running-release-fixtures] manifest: {manifest_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
