#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

python3 - <<'PY'
import re
import sys
from pathlib import Path

root = Path(".")
channel = root / "android/app/src/main/kotlin/com/namsoon/footballnote/RunningPoseAnalysisChannel.kt"
main_activity = root / "android/app/src/main/kotlin/com/namsoon/footballnote/MainActivity.kt"
gradle = root / "android/app/build.gradle"
model = root / "android/app/src/main/assets/pose_landmarker_lite.task"

channel_text = channel.read_text()
main_text = main_activity.read_text()
gradle_text = gradle.read_text()
failures: list[str] = []


def require(condition: bool, message: str) -> None:
    if not condition:
        failures.append(message)


for forbidden in (
    "com.google.mlkit",
    "PoseDetection",
    "PoseDetectorOptions",
    "InputImage",
    "PoseLandmark",
):
    require(
        re.search(rf"\b{re.escape(forbidden)}\b", channel_text) is None,
        f"upload channel must not use ML Kit token: {forbidden}",
    )

for required in (
    "com.google.mediapipe.framework.image.BitmapImageBuilder",
    "com.google.mediapipe.tasks.core.BaseOptions",
    "com.google.mediapipe.tasks.vision.core.RunningMode",
    "com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker",
    "RunningMode.VIDEO",
    ".setNumPoses(1)",
    ".setMinPoseDetectionConfidence(minimumLikelihood)",
    ".setMinPosePresenceConfidence(minimumLikelihood)",
    ".setMinTrackingConfidence(minimumLikelihood)",
    "detectForVideo",
    "poseLandmarker?.close()",
    "bitmap.recycle()",
    "\"model_missing\"",
    "\"mediapipe_pose_failed\"",
    "\"video_too_short\"",
    "\"no_pose_detected\"",
):
    require(required in channel_text, f"upload channel is missing required token: {required}")

require(
    re.search(r"class RunningPoseAnalysisChannel\(\s*private val context: Context,", channel_text)
    is not None,
    "upload channel must receive Android Context",
)
require(
    re.search(r"private const val sampleCount\s*=\s*14\b", channel_text) is not None,
    "upload channel must keep the 14-frame sampling window",
)
require(
    re.search(r"private const val minimumLikelihood\s*=\s*0\.45f\b", channel_text)
    is not None,
    "upload channel must keep the 0.45 MediaPipe confidence threshold",
)
require(
    re.search(
        r"RunningPoseAnalysisChannel\(\s*this,\s*flutterEngine\.dartExecutor\.binaryMessenger",
        main_text,
        re.DOTALL,
    )
    is not None,
    "MainActivity must pass Context into RunningPoseAnalysisChannel",
)
require(
    'implementation "com.google.mlkit:pose-detection' not in gradle_text,
    "direct Android ML Kit pose dependency must not remain",
)
require(
    'implementation "com.google.mediapipe:tasks-vision:0.10.35"' in gradle_text,
    "Android MediaPipe tasks-vision dependency must remain",
)
require(model.exists(), "Android pose landmarker model asset must be packaged")

if failures:
    print("Android upload MediaPipe contract check failed:", file=sys.stderr)
    for failure in failures:
        print(f"- {failure}", file=sys.stderr)
    sys.exit(1)

print("Android upload MediaPipe contract check passed")
PY
