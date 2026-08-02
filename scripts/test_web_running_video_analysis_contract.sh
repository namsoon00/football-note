#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

python3 - <<'PY'
from pathlib import Path
import re
import sys

bridge = Path("web/running_video_pose_analysis.js")
model = Path("web/mediapipe/pose_landmarker_full.task")
index = Path("web/index.html")
adapter = Path("lib/application/running_video_analysis_platform_web.dart")
facade = Path("lib/application/running_video_analysis_service.dart")

failures: list[str] = []

def require(condition: bool, message: str) -> None:
    if not condition:
        failures.append(message)

require(bridge.exists(), "Web MediaPipe analysis bridge is missing")
require(model.is_file() and model.stat().st_size > 9_000_000, "Web Full pose model is missing or incomplete")

bridge_text = bridge.read_text()
index_text = index.read_text()
adapter_text = adapter.read_text()
facade_text = facade.read_text()

for required in (
    "@mediapipe/tasks-vision@${config.taskVersion}",
    "PoseLandmarker.createFromOptions",
    "runningMode: 'VIDEO'",
    "pose_landmarker_full.task",
    "minConfidence: 0.35",
    "sampleCount: 14",
    "maxDenseFrames: 48",
    "minValidatedContacts: 3",
    "groundLineSampleFraction",
    "contactMotionToleranceRatio",
    "candidateFrameCount",
    "rejectedFrameCounts",
    "maxVideoDurationMs: 15000",
    "percentile(normalizedShoulderYs, 0.10)",
    "detectForVideo",
    "poseFrames",
    "coarseSamples",
    "denseSamples",
    "contactWindows",
    "validatedContactFrameTimestampsMs",
    "metricQualities",
    "window.runningVideoPoseAnalysis",
):
    require(required in bridge_text, f"Web analyzer is missing required token: {required}")

require(
    re.search(r"taskVersion:\s*'0\.10\.35'", bridge_text) is not None,
    "Web analyzer must pin MediaPipe Tasks Vision 0.10.35",
)
require(
    "running_video_pose_analysis.js?v=__WEB_ASSET_VERSION__" in index_text,
    "Web app must load the video analysis bridge before Flutter",
)
require(
    "dart.library.html" in facade_text,
    "Running video analysis service must select a web implementation",
)
for required in ("readAsBytes", "runningVideoPoseAnalysis", "toDart", "RunningVideoAnalysisResult.fromMap"):
    require(required in adapter_text, f"Web Dart adapter is missing required token: {required}")

for required in (
    "maxVideoBytes",
    "analysisTimeout",
    "video_too_large",
    "analysis_timeout",
    "video.length",
    ".timeout(analysisTimeout)",
):
    require(required in facade_text, f"Running video service is missing launch safety token: {required}")

for retired in (
    "getUserMedia",
    "CameraController",
    "requestAnimationFrame(() => analyze",
    "MediaPipePoseLandmarkerChannel",
):
    require(retired not in bridge_text, f"Web analyzer must not retain live coaching token: {retired}")

if failures:
    print("Web running video analysis contract check failed:", file=sys.stderr)
    for failure in failures:
        print(f"- {failure}", file=sys.stderr)
    sys.exit(1)

print("Web running video analysis contract check passed")
PY

if command -v node >/dev/null 2>&1; then
  node --check web/running_video_pose_analysis.js
else
  echo "[web-running-video-analysis] node unavailable; skipped JavaScript parse check" >&2
fi
