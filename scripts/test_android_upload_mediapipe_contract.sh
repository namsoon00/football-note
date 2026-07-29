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
ios_channel = root / "ios/Runner/RunningPoseAnalysisChannel.swift"
main_activity = root / "android/app/src/main/kotlin/com/namsoon/footballnote/MainActivity.kt"
gradle = root / "android/app/build.gradle"
model = root / "android/app/src/main/assets/pose_landmarker_full.task"

channel_text = channel.read_text()
ios_text = ios_channel.read_text()
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
    require(
        re.search(rf"\b{re.escape(forbidden)}\b", ios_text) is None,
        f"iOS running channel must not use ML Kit token: {forbidden}",
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
    "landmarkConfidence(landmark)",
    "min(visibility, presence)",
    "else -> 0f",
    "coarsePoseLandmarker?.close()",
    "densePoseLandmarker?.close()",
    "bitmap.recycle()",
    "\"model_missing\"",
    "\"mediapipe_pose_failed\"",
    "\"video_too_short\"",
    "\"video_too_blurry\"",
    "\"no_pose_detected\"",
    "\"insufficient_contact_evidence\"",
    "coarseSampleTimestamps",
    "deriveContactCandidateWindows",
    "fallbackContactCandidateWindows",
    "denseTimestampsForContactWindows",
    "validateDenseContactFrames",
    "selectDenseContactFrame",
    "hasGroundBandPersistence",
    "enteredGroundBand",
    "windowCenterTimestampMs",
    "uniqueContactFrameCount",
    "mergePoseFrames",
    "maxDenseFrameBudget",
    "minimumValidatedContactFrames",
    "coarseContactProxyConfidencePenalty",
    "frameSharpness",
    "sharpnessValues",
    "minimumMedianSharpness",
):
    require(required in channel_text, f"upload channel is missing required token: {required}")

for required in (
    "MediaPipeTasksVision",
    "PoseLandmarkerOptions",
    "options.runningMode = .video",
    "options.numPoses = 1",
    "options.minPoseDetectionConfidence = Self.minimumLikelihood",
    "options.minPosePresenceConfidence = Self.minimumLikelihood",
    "options.minTrackingConfidence = Self.minimumLikelihood",
    "poseLandmarker.detect",
    "landmarkConfidence(landmark)",
    "min(visibility, presence)",
    "confidence = 0",
    "actualTime: &actualTime",
    "NSNull()",
    '"model_missing"',
    '"mediapipe_pose_failed"',
    '"video_too_short"',
    '"video_too_blurry"',
    '"no_pose_detected"',
    '"insufficient_contact_evidence"',
    "coarseSampleTimestamps",
    "deriveContactCandidateWindows",
    "fallbackContactCandidateWindows",
    "denseTimestampsForContactWindows",
    "validateDenseContactFrames",
    "selectDenseContactFrame",
    "hasGroundBandPersistence",
    "enteredGroundBand",
    "windowCenterTimestampMs",
    "uniqueContactFrameCount",
    "mergePoseFrames",
    "maxDenseFrameBudget",
    "minimumValidatedContactFrames",
    "coarseContactProxyConfidencePenalty",
    "frameSharpness",
    "sharpnessValues",
    "minimumMedianSharpness",
):
    require(required in ios_text, f"iOS running channel is missing required token: {required}")

for required in (
    '"poseFrames"',
    '"coarseSamples"',
    '"denseSamples"',
    '"contactWindows"',
    '"validatedContactFrameTimestampsMs"',
    '"contactConfidence"',
    '"metricQualities"',
    '"footStrike"',
    '"kneeFlexion"',
    '"maxFrameBudget"',
    '"targetFps"',
    '"timestampMs"',
    '"imageWidth"',
    '"imageHeight"',
    '"landmarks"',
    '"index"',
    '"x"',
    '"y"',
    '"z"',
    '"visibility"',
    '"presence"',
    '"confidence"',
):
    require(required in channel_text, f"Android poseFrames schema is missing token: {required}")
    require(required in ios_text, f"iOS poseFrames schema is missing token: {required}")

require(
    re.search(r"class RunningPoseAnalysisChannel\(\s*private val context: Context,", channel_text)
    is not None,
    "upload channel must receive Android Context",
)
require(
    re.search(r"private const val minimumMedianSharpness\s*=\s*0\.018\b", channel_text)
    is not None,
    "Android sharpness gate must keep the calibrated 0.018 threshold",
)
require(
    re.search(r"private static let minimumMedianSharpness\s*=\s*0\.018\b", ios_text)
    is not None,
    "iOS sharpness gate must keep the calibrated 0.018 threshold",
)
require(
    re.search(r"private const val sampleCount\s*=\s*14\b", channel_text) is not None,
    "upload channel must keep the 14-frame sampling window",
)
require(
    re.search(r"private static let sampleCount\s*=\s*14\b", ios_text) is not None,
    "iOS running channel must keep the 14-frame sampling window",
)
require(
    re.search(r"private const val minimumLikelihood\s*=\s*0\.35f\b", channel_text)
    is not None,
    "upload channel must keep the 0.35 MediaPipe confidence threshold",
)
require(
    re.search(r"private static let minimumLikelihood:\s*Float\s*=\s*0\.35\b", ios_text)
    is not None,
    "iOS running channel must keep the 0.35 MediaPipe confidence threshold",
)
require(
    re.search(r"private const val mediaPipePoseLandmarkCount\s*=\s*33\b", channel_text)
    is not None,
    "Android poseFrames must serialize 33 MediaPipe landmarks",
)
require(
    re.search(r"private static let mediaPipePoseLandmarkCount\s*=\s*33\b", ios_text)
    is not None,
    "iOS poseFrames must serialize 33 MediaPipe landmarks",
)
android_budget = re.search(r"private const val maxDenseFrameBudget\s*=\s*(\d+)\b", channel_text)
ios_budget = re.search(r"private static let maxDenseFrameBudget\s*=\s*(\d+)\b", ios_text)
require(android_budget is not None, "Android dense pass must define a hard maxDenseFrameBudget")
require(ios_budget is not None, "iOS dense pass must define a hard maxDenseFrameBudget")
if android_budget is not None:
    require(int(android_budget.group(1)) <= 48, "Android dense frame budget must stay at or below 48")
if ios_budget is not None:
    require(int(ios_budget.group(1)) <= 48, "iOS dense frame budget must stay at or below 48")
require(
    re.search(r"private const val denseFrameIntervalMs\s*=\s*33L\b", channel_text)
    is not None,
    "Android dense pass must target approximately 30 fps",
)
require(
    re.search(r"private static let denseFrameIntervalMs\s*=\s*33\b", ios_text)
    is not None,
    "iOS dense pass must target approximately 30 fps",
)
require(
    re.search(
        r"uniqueContactFrameCount\s*=\s*contactFrames\s*\.map\s*\{\s*it\.timestampMs\s*\}\s*\.distinct\(\)\s*\.size",
        channel_text,
        re.DOTALL,
    )
    is not None,
    "Android dense contact evidence must require at least two unique selected events",
)
require(
    "Set(contactFrames.map(\\.timestampMs)).count" in ios_text,
    "iOS dense contact evidence must require at least two unique selected events",
)
require(
    "selectedByTimestamp" in channel_text and "selectedByTimestamp" in ios_text,
    "Android/iOS dense contact validation must deduplicate selected event timestamps",
)
require(
    re.search(
        r"fallbackContactCandidateWindows\(frameSamples,\s*durationMs\).*?"
        r"contactProxyFrames\(\s*samples\s*=\s*frameSamples,.*?"
        r"confidencePenalty\s*=\s*coarseContactProxyConfidencePenalty",
        channel_text,
        re.DOTALL,
    )
    is not None,
    "Android must retain a low-confidence coarse contact proxy when dense contact frames are absent",
)
require(
    re.search(
        r"fallbackContactCandidateWindows\(\s*from:\s*frameSamples,\s*"
        r"durationMs:\s*durationMs.*?contactProxyFrames\(\s*from:\s*frameSamples,.*?"
        r"confidencePenalty:\s*Self\.coarseContactProxyConfidencePenalty",
        ios_text,
        re.DOTALL,
    )
    is not None,
    "iOS must retain a low-confidence coarse contact proxy when dense contact frames are absent",
)
require(
    "actualSourceTimestampMs(from: actualTime)" in ios_text
    and "seenSourceTimestamps" in ios_text
    and "timestampMs: sourceTimestampMs" in ios_text
    and "max(sourceTimestampMs, lastAnalysisTimestampMs + 1)" in ios_text,
    "iOS pose samples must use actualTime for source timestamps while keeping MediaPipe timestamps increasing",
)
require(
    "loadingSamples" not in channel_text and ".leadFootStrikeRatio(direction)" not in channel_text,
    "Android foot/knee upload metrics must not use the old largest-forward-reach proxy",
)
require(
    "loadingSamples" not in ios_text and ".leadFootStrikeRatio(direction: direction)" not in ios_text,
    "iOS foot/knee upload metrics must not use the old largest-forward-reach proxy",
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
    "MediaPipePoseLandmarkerChannel" not in main_text,
    "MainActivity must not register the retired live pose channel",
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
require(
    'private const val modelAssetPath = "pose_landmarker_full.task"' in channel_text,
    "Android upload analysis must select the Full pose model",
)
require(
    'private static let modelResourceName = "pose_landmarker_full"' in ios_text,
    "iOS upload analysis must select the Full pose model",
)

if failures:
    print("Android upload MediaPipe contract check failed:", file=sys.stderr)
    for failure in failures:
        print(f"- {failure}", file=sys.stderr)
    sys.exit(1)

print("Android upload MediaPipe contract check passed")
PY
