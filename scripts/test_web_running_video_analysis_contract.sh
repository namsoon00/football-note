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
archive = Path("lib/application/running_coach_evidence_archive_web.dart")

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
archive_text = archive.read_text()

for required in (
    "@mediapipe/tasks-vision@${config.taskVersion}",
    "PoseLandmarker.createFromOptions",
    "runningMode: 'VIDEO'",
    "pose_landmarker_full.task",
    "minConfidence: 0.35",
    "previewFrameIntervalMs: 125",
    "maxPreviewPoseFrames: 121",
    "previewRecoveryFrameIntervalMs: 67",
    "maxPreviewRecoveryPoseFrames: 48",
    "previewSafeInsetMs: 150",
    "seekTimeoutMs: 3500",
    "coarseTargetFps: 8",
    "coarseFrameIntervalMs: 125",
    "maxCoarseFrames: 481",
    "maxDenseFrames: 240",
    "denseWindowRadiusMs: 500",
    "maxContactWindows: 8",
    "minValidatedContacts: 3",
    "minDistinctContactSeparationMs: 120",
    "kinematicContactConfidencePenalty: 0.82",
    "kinematicContactCandidate",
    "mergedContactCandidateSet",
    "validatedContactForSide",
    "deduplicateContactValidations",
    "enforceContactValidationAlternation",
    "toe.x - heel.x",
    "kinematic_contact_estimate",
    "alternation_estimated",
    "missing_contact_joint_chain",
    "centerOfPoints",
    "groundLineSampleFraction",
    "contactMotionToleranceRatio",
    "enteredGroundBand",
    "not_descending_to_contact",
    "insufficient_contact_persistence",
    "candidateFrameCount",
    "rejectedFrameCounts",
    "perWindowBudget",
    "selectedIndexes",
    "perspectiveQuality",
    "minimumBodyScaleRatio",
    "not_side_on",
    "scale_drift",
    "contacts.length === 0",
    "hasCompleteContactSample",
    "maxVideoDurationMs: 60000",
    "Math.ceil(safeDurationMs / config.coarseFrameIntervalMs)",
    "analyzedFrameTimestamps",
    "verticalBounceTrajectory",
    "verticalBounceRatio",
    "groundLineForFootEvidence(footEvidence)",
    "detectForVideo",
    "poseFrames",
    "coarseSamples",
    "denseSamples",
    "posePassCache",
    "posePassCache?.get(timestampMs)",
    "posePassCache?.set(timestampMs",
    "runPosePass(video, coarseFrameTimes, true, posePassCache)",
    "runPosePass(video, recoveryFrameTimes, false, posePassCache)",
    "runPosePass(video, denseFrameTimes, false, posePassCache)",
    "contactWindows",
    "validatedContactFrameTimestampsMs",
    "estimatedContactFrameTimestampsMs",
    "selectionMethod",
    "recoveryRunningMotionScore",
    "slice(0, 24)",
    "previewPoseTimestamps",
    "previewPoseRecoveryTimestamps",
    "analyzePreviewPoseFromLoader",
    "preview_pose_unavailable",
    "analyzePreviewPose",
    "analyzePreviewPoseUrl",
    "releaseVideo(video, url, ownsUrl)",
    "visionFilesetPromise",
    "analyzeUrl",
    "extractEvidenceFramesFromUrl",
    "evidenceDeadlineExpired",
    "deadlineEpochMs",
    "metricQualities",
    "window.runningVideoPoseAnalysis",
):
    require(required in bridge_text, f"Web analyzer is missing required token: {required}")

require(
    "shoulderPoints.length === 0 || hipPoints.length === 0" in bridge_text,
    "Web analyzer must retain a torso frame when the far-side leg is occluded",
)
require(
    "normalizedShoulderYs" not in bridge_text
    and "shoulderCenter.y / Math.max(1, sample.bodyScale)" not in bridge_text,
    "Web analyzer must not compute bounce from absolute shoulder y divided by bodyScale",
)

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
for required in (
    "analyzeUrl",
    "analyzePreviewPose",
    "analyzePreviewPoseUrl",
    "isReusableBrowserVideoUrl",
    "maximumRunningVideoBytes",
    "webMaxVideoBytes",
    "runningVideoPoseAnalysis",
    "toDart",
    "analyzeRunningVideoPreviewPose",
    "RunningVideoPosePreviewResult.fromMap",
    "RunningVideoAnalysisResult.fromMap",
):
    require(required in adapter_text, f"Web Dart adapter is missing required token: {required}")

for required in (
    "extractEvidenceFramesFromUrl",
    "web_evidence_storage_failed",
    "storageReference = dataUrl",
    "extractRawFrames",
    "_maximumWebEvidenceByteFallback",
    "_maximumWebEvidenceFrames = 24",
    "web_evidence_url_required",
    "evidence_archive_timeout",
    "deadlineEpochMs",
    "_beforeDeadline",
    "requestsByTimestamp",
):
    require(required in archive_text, f"Web evidence archive is missing required token: {required}")

for required in (
    "maxVideoBytes",
    "analysisTimeout",
    "video_too_large",
    "analysis_timeout",
    "previewPoseAnalysisTimeout",
    "preview_pose_timeout",
    "video.length",
    "platform.maximumRunningVideoBytes",
    "webMaxVideoBytes = 96 * 1024 * 1024",
    ".timeout(analysisTimeout)",
    ".timeout(previewPoseAnalysisTimeout)",
):
    require(required in facade_text, f"Running video service is missing launch safety token: {required}")

require(
    "previewPoseAnalysisTimeout = Duration(seconds: 45)" in facade_text,
    "Running video preview timeout must cover MediaPipe/WebAssembly cold starts",
)

require(
    "reason === 'too_small_runner' ? 0" not in bridge_text
    and "Math.min(baseQuality.confidence, 0.55)" in bridge_text,
    "Web too-small perspective quality must remain a low-confidence estimate, not confidence zero",
)

preview_match = re.search(
    r"async function analyzePreviewPoseFromLoader\(load\) \{(?P<body>.*?)\n  function analyzePreviewPose\(",
    bridge_text,
    re.DOTALL,
)
require(preview_match is not None, "Web preview pose analyzer function is missing")
if preview_match is not None:
    preview_body = preview_match.group("body")
    for forbidden in (
        "denseTimestamps",
        "deriveContactCandidates",
        "fallbackContactCandidates",
        "validatedContact",
        "contactWindows",
        "metricQualities",
        "forwardLeanDegrees",
    ):
        require(
            forbidden not in preview_body,
            f"Web preview pose analyzer must not run full-analysis token: {forbidden}",
        )

timestamp_match = re.search(
    r"function previewPoseTimestamps\(durationMs\) \{(?P<body>.*?)\n  \}",
    bridge_text,
    re.DOTALL,
)
require(timestamp_match is not None, "Web preview timestamp helper is missing")
if timestamp_match is not None:
    timestamp_body = timestamp_match.group("body")
    require("startMs" in timestamp_body and "endMs" in timestamp_body, "Web preview timestamps must use a safe interior window")
    require("config.previewSafeInsetMs" in timestamp_body, "Web preview timestamps must use the configured safe inset")
    require("safeDurationMs * index" not in timestamp_body, "Web preview timestamps must not include exact 0/duration endpoints")

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
