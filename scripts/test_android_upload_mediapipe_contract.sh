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
    "\"video_too_long\"",
    "\"video_too_blurry\"",
    "\"no_pose_detected\"",
    "\"insufficient_contact_evidence\"",
    "coarseSampleTimestamps",
    "deriveContactCandidateWindows",
    "fallbackContactCandidateWindows",
    "mergeContactCandidateSets",
    "denseTimestampsForContactWindows",
    "validateDenseContactFrames",
    "selectDenseContactFrame",
    "selectDenseContactFrameForSide",
    "contactMotionReason",
    "enforceContactValidationAlternation",
    "enteredGroundBand",
    "hasTemporalNeighbor",
    "not_descending_to_contact",
    "isKinematicContactCandidate",
    "kinematicContactConfidencePenalty",
    "kinematic_contact_estimate",
    "alternation_estimated",
    "missing_contact_joint_chain",
    "centerOfPoints",
    "groundLineForFootEvidence",
    "GroundLine",
    "candidateFrameCount",
    "rejectedFrameCounts",
    "insufficient_contact_persistence",
    "windowCenterTimestampMs",
    "uniqueConfirmedContactFrameCount",
    "mergePoseFrames",
    "maxDenseFrameBudget",
    "minimumValidatedContactFrames",
    "minimumDistinctContactSeparationMs",
    "foot.toe.x - foot.heel.x",
    "coarseContactProxyConfidencePenalty",
    "frameSharpness",
    "sharpnessValues",
    "minimumMedianSharpness",
    "maxVideoDurationMs",
    "percentile",
    "verticalBounceTrajectory",
    "verticalBounceRatio",
    "minimumBounceTrajectorySamples",
    "previewPoseSafeInsetMs",
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
    '"video_too_long"',
    '"video_too_blurry"',
    '"no_pose_detected"',
    '"insufficient_contact_evidence"',
    "coarseSampleTimestamps",
    "deriveContactCandidateWindows",
    "fallbackContactCandidateWindows",
    "mergeContactCandidateSets",
    "denseTimestampsForContactWindows",
    "validateDenseContactFrames",
    "selectDenseContactFrame",
    "selectDenseContactFrameForSide",
    "contactMotionReason",
    "enforceContactValidationAlternation",
    "enteredGroundBand",
    "hasTemporalNeighbor",
    "not_descending_to_contact",
    "isKinematicContactCandidate",
    "kinematicContactConfidencePenalty",
    "kinematic_contact_estimate",
    "alternation_estimated",
    "missing_contact_joint_chain",
    "centerOfPoints",
    "groundLineForFootEvidence",
    "GroundLine",
    "candidateFrameCount",
    "rejectedFrameCounts",
    "insufficient_contact_persistence",
    "windowCenterTimestampMs",
    "uniqueConfirmedContactFrameCount",
    "mergePoseFrames",
    "maxDenseFrameBudget",
    "minimumValidatedContactFrames",
    "minimumDistinctContactSeparationMs",
    "foot.toe.x - foot.heel.x",
    "coarseContactProxyConfidencePenalty",
    "frameSharpness",
    "sharpnessValues",
    "minimumMedianSharpness",
    "maxVideoDurationMs",
    "percentile",
    "verticalBounceTrajectory",
    "verticalBounceRatio",
    "minimumBounceTrajectorySamples",
    "previewPoseSafeInsetMs",
):
    require(required in ios_text, f"iOS running channel is missing required token: {required}")

for required in (
    '"poseFrames"',
    '"coarseSamples"',
    '"denseSamples"',
    '"contactWindows"',
    '"validatedContactFrameTimestampsMs"',
    '"estimatedContactFrameTimestampsMs"',
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

for required in (
    'liveFrameMethodName = "analyzeRunningLiveFrame"',
    "analyzeLiveFrame",
    "RunningMode.IMAGE",
    "bitmapFromYuv420",
    "normalizeLiveBitmap",
    '"live_pose_unsupported"',
):
    require(required in channel_text, f"Android live framing contract is missing token: {required}")

for required in (
    'liveFrameMethodName = "analyzeRunningLiveFrame"',
    "analyzeLiveFrame",
    "runningMode: .image",
    'format == "bgra8888"',
    "normalizeLiveImage",
    '"live_pose_unsupported"',
):
    require(required in ios_text, f"iOS live framing contract is missing token: {required}")

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
    re.search(r"private const val coarseTargetFps\s*=\s*8\b", channel_text) is not None,
    "Android upload analysis must scan 60-second clips at a documented 8 fps budget",
)
require(
    re.search(r"private static let coarseTargetFps\s*=\s*8\b", ios_text) is not None,
    "iOS upload analysis must scan 60-second clips at a documented 8 fps budget",
)
require(
    re.search(r"private const val previewPoseFrameIntervalMs\s*=\s*125L\b", channel_text) is not None
    and re.search(r"private const val maxPreviewPoseFrameBudget\s*=\s*121\b", channel_text) is not None
    and re.search(r"private const val previewPoseRecoveryFrameIntervalMs\s*=\s*67L\b", channel_text) is not None
    and re.search(r"private const val maxPreviewRecoveryPoseFrameBudget\s*=\s*48\b", channel_text) is not None
    and re.search(r"private const val previewPoseSafeInsetMs\s*=\s*150L\b", channel_text) is not None,
    "Android preview pose analysis must use bounded dense interior timestamps with recovery",
)
require(
    re.search(r"private static let previewPoseFrameIntervalMs\s*=\s*125\b", ios_text) is not None
    and re.search(r"private static let maxPreviewPoseFrameBudget\s*=\s*121\b", ios_text) is not None
    and re.search(r"private static let previewPoseRecoveryFrameIntervalMs\s*=\s*67\b", ios_text) is not None
    and re.search(r"private static let maxPreviewRecoveryPoseFrameBudget\s*=\s*48\b", ios_text) is not None
    and re.search(r"private static let previewPoseSafeInsetMs\s*=\s*150\b", ios_text) is not None,
    "iOS preview pose analysis must use bounded dense interior timestamps with recovery",
)
require(
    "previewPoseRecoveryTimestamps" in channel_text
    and "previewPoseRecoveryTimestamps" in ios_text
    and "previewPass.poseFrames" in channel_text
    and "recoveryPass.poseFrames" in channel_text
    and "previewPass.poseFrames" in ios_text
    and "recoveryPass.poseFrames" in ios_text,
    "Android/iOS preview pose analysis must retry a bounded recovery pass before declaring pose unavailable",
)
require(
    "val recoveryLandmarker = makePoseLandmarker()" in channel_text
    and "poseLandmarker = recoveryLandmarker" in channel_text
    and "let recoveryPoseLandmarker = try makePoseLandmarker()" in ios_text
    and "poseLandmarker: recoveryPoseLandmarker" in ios_text,
    "Android/iOS preview recovery must use a fresh VIDEO-mode landmarker so timestamps stay monotonic",
)
require(
    "normalizedShoulderYs" not in channel_text
    and "normalizedShoulderYs" not in ios_text,
    "Android/iOS analyzers must not compute bounce from absolute shoulder y divided by bodyScale",
)
require(
    re.search(r"private const val coarseFrameIntervalMs\s*=\s*125L\b", channel_text) is not None
    and re.search(r"private const val maxCoarseFrameBudget\s*=\s*481\b", channel_text) is not None,
    "Android upload analysis must retain a bounded 481-frame whole-clip scan",
)
require(
    re.search(r"private static let coarseFrameIntervalMs\s*=\s*125\b", ios_text) is not None
    and re.search(r"private static let maxCoarseFrameBudget\s*=\s*481\b", ios_text) is not None,
    "iOS upload analysis must retain a bounded 481-frame whole-clip scan",
)
require(
    re.search(r"private const val maxVideoDurationMs\s*=\s*60000L\b", channel_text)
    is not None,
    "Android upload analysis must accept clips through 60 seconds",
)
require(
    re.search(r"private static let maxVideoDurationMs\s*=\s*60000\b", ios_text)
    is not None,
    "iOS upload analysis must accept clips through 60 seconds",
)
require(
    "coarseFrameTimestamps = coarseSampleTimestamps(durationMs)" in channel_text
    and "attemptedFrames = coarseFrameTimestamps.size" in channel_text
    and "analyzedFrameTimestamps" in channel_text,
    "Android must report the actual whole-clip and dense frame counts",
)
require(
    "coarseFrameTimestamps = coarseSampleTimestamps(durationMs: durationMs)" in ios_text
    and "attemptedFrames: coarseFrameTimestamps.count" in ios_text
    and "analyzedFrameTimestamps" in ios_text,
    "iOS must report the actual whole-clip and dense frame counts",
)
require(
    re.search(r"private const val minimumValidatedContactFrames\s*=\s*3\b", channel_text)
    is not None,
    "Android lower-body coaching must require three validated contacts",
)
require(
    re.search(r"private const val kinematicContactConfidencePenalty\s*=\s*0\.82\b", channel_text)
    is not None
    and re.search(r"private static let kinematicContactConfidencePenalty\s*=\s*0\.82\b", ios_text)
    is not None,
    "Android/iOS must use the same conservative confidence penalty for trajectory-backed contact",
)
require(
    "listOfNotNull(leftShoulder, rightShoulder)" in channel_text
    and "[leftShoulder?.point, rightShoulder?.point].compactMap" in ios_text,
    "Android/iOS must retain a torso sample when the far-side leg is occluded",
)
require(
    re.search(r"private static let minimumValidatedContactFrames\s*=\s*3\b", ios_text)
    is not None,
    "iOS lower-body coaching must require three validated contacts",
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
    require(int(android_budget.group(1)) == 240, "Android dense frame budget must be 240")
if ios_budget is not None:
    require(int(ios_budget.group(1)) == 240, "iOS dense frame budget must be 240")
require(
    re.search(r"private const val denseFrameIntervalMs\s*=\s*33L\b", channel_text)
    is not None,
    "Android dense pass must target approximately 30 fps",
)
require(
    re.search(r"private const val denseWindowRadiusMs\s*=\s*500L\b", channel_text)
    is not None,
    "Android dense contact recovery window must match the web analyzer at 500 ms",
)
require(
    re.search(r"private static let denseWindowRadiusMs\s*=\s*500\b", ios_text)
    is not None,
    "iOS dense contact recovery window must match the web analyzer at 500 ms",
)
require(
    re.search(r"private static let denseFrameIntervalMs\s*=\s*33\b", ios_text)
    is not None,
    "iOS dense pass must target approximately 30 fps",
)
require(
    re.search(
        r"uniqueConfirmedContactFrameCount\s*=\s*confirmedContactFrames\s*\.map\s*\{\s*it\.timestampMs\s*\}\s*\.distinct\(\)\s*\.size",
        channel_text,
        re.DOTALL,
    )
    is not None,
    "Android dense contact evidence must require unique selected contact events",
)
require(
    "confirmedContactFrames.map(\\.timestampMs)" in ios_text,
    "iOS dense contact evidence must require unique selected contact events",
)
require(
    "selectedIndexes" in channel_text and "selectedIndexes" in ios_text
    and "minimumDistinctContactSeparationMs" in channel_text
    and "minimumDistinctContactSeparationMs" in ios_text,
    "Android/iOS dense contact validation must deduplicate nearby contact events",
)
require(
    "perspectiveQuality" in channel_text and "perspectiveQuality" in ios_text
    and "minimumBodyScaleRatio" in channel_text and "minimumBodyScaleRatio" in ios_text
    and '"not_side_on"' in channel_text and '"not_side_on"' in ios_text
    and '"scale_drift"' in channel_text and '"scale_drift"' in ios_text,
    "Android/iOS analyzers must emit perspective quality limitations",
)
require(
    'if (reason == "too_small_runner") 0.0 else 0.55' not in channel_text
    and 'reason == "too_small_runner" ? 0 : 0.55' not in ios_text
    and "confidence = min(confidence, 0.55)" in channel_text
    and "confidence: min(confidence, 0.55)" in ios_text,
    "Android/iOS too-small perspective quality must remain a low-confidence estimate, not confidence zero",
)
require(
    re.search(
        r"return\s*\[\s*leftShoulder,\s*rightShoulder,\s*leftHip,\s*rightHip,"
        r"\s*leftKnee,\s*rightKnee,\s*leftAnkle,\s*rightAnkle,"
        r"\s*leftHeel,\s*rightHeel,\s*leftToe,\s*rightToe,\s*\]"
        r"\.compactMap\s*\{\s*\$0\s*\}\.contains",
        ios_text,
        re.DOTALL,
    )
    is None,
    "iOS edge cutoff must not use one oversized optional CGPoint compactMap/contains expression",
)
for edge_group in (
    "let shoulderEdgePoints: [CGPoint]",
    "let hipEdgePoints: [CGPoint]",
    "let kneeEdgePoints: [CGPoint]",
    "let ankleEdgePoints: [CGPoint]",
    "let heelEdgePoints: [CGPoint]",
    "let toeEdgePoints: [CGPoint]",
):
    require(edge_group in ios_text, f"iOS edge cutoff must keep typed {edge_group}")
require(
    "hasHorizontalEdgeContact" in ios_text
    and "hasVerticalEdgeContact" in ios_text
    and "edgeContactPoints.append(contentsOf: shoulderEdgePoints)" in ios_text
    and "edgeContactPoints.append(contentsOf: hipEdgePoints)" in ios_text
    and "edgeContactPoints.append(contentsOf: kneeEdgePoints)" in ios_text
    and "edgeContactPoints.append(contentsOf: ankleEdgePoints)" in ios_text
    and "edgeContactPoints.append(contentsOf: heelEdgePoints)" in ios_text
    and "edgeContactPoints.append(contentsOf: toeEdgePoints)" in ios_text,
    "iOS edge cutoff must preserve typed edge checks for shoulders, hips, knees, ankles, heels, and toes",
)
require(
    "val usesContactProxy = contactFrames.isEmpty()" in channel_text,
    "Android must retain selected confirmed or estimated contact observations instead of replacing them with a proxy",
)
require(
    "let usesContactProxy = contactFrames.isEmpty" in ios_text,
    "iOS must retain selected confirmed or estimated contact observations instead of replacing them with a proxy",
)
require(
    "persistentCandidates.isEmpty()) {\n            eligibleCandidates" not in channel_text,
    "Android must not promote an isolated near-ground frame to contact",
)
require(
    "persistentCandidates" not in channel_text,
    "Android must not keep persistent near-ground frames in the strict contact selector",
)
require(
    "persistentCandidates.isEmpty\n      ? eligibleCandidates" not in ios_text,
    "iOS must not promote an isolated near-ground frame to contact",
)
require(
    "persistentCandidates" not in ios_text,
    "iOS must not keep persistent near-ground frames in the strict contact selector",
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
