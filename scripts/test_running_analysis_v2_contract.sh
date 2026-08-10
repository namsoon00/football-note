#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

python3 - <<'PY'
from pathlib import Path
import re
import sys

sources = {
    "web": Path("web/running_video_pose_analysis.js").read_text(),
    "android": Path("android/app/src/main/kotlin/com/namsoon/footballnote/RunningPoseAnalysisChannel.kt").read_text(),
    "ios": Path("ios/Runner/RunningPoseAnalysisChannel.swift").read_text(),
}
dart_contract = Path("lib/domain/entities/running_video_analysis_result.dart").read_text()
measurement_contract = Path("lib/domain/entities/running_analysis_measurement.dart").read_text()
failures: list[str] = []


def require(condition: bool, message: str) -> None:
    if not condition:
        failures.append(message)


payload_fields = (
    "analysisVersion",
    "durationMs",
    "sampledFrames",
    "validFrames",
    "direction",
    "forwardLeanDegrees",
    "verticalBounceRatio",
    "footStrikeDistanceRatio",
    "stanceKneeAngleDegrees",
    "elbowAngleDegrees",
    "metricQualities",
    "coarseSamples",
    "recoverySamples",
    "denseSamples",
    "contactWindows",
    "validatedContactFrameTimestampsMs",
    "estimatedContactFrameTimestampsMs",
    "contactConfidence",
    "perspectiveQuality",
    "poseFrames",
)
for platform, text in sources.items():
    for field in payload_fields:
        require(field in text, f"{platform} payload is missing {field}")
    for token in (
        "low_sharpness",
        "coordinates_unavailable",
        "maxVideoDurationMs",
        "maxDecodableVideoDurationMs",
        "kinematic_contact_estimate",
        "selectionMethod",
        "recoveryRunningMotionScore",
        "0.20 + 0.80",
    ):
        require(token in text, f"{platform} is missing v2 quality token {token}")

constant_patterns = {
    "web": (
        r"recoveryTargetFps:\s*15",
        r"maxRecoveryFrames:\s*120",
        r"maxVideoDurationMs:\s*60000",
        r"maxDecodableVideoDurationMs:\s*600000",
    ),
    "android": (
        r"recoveryTargetFps\s*=\s*15",
        r"maxRecoveryFrameBudget\s*=\s*120",
        r"maxVideoDurationMs\s*=\s*60000L",
        r"maxDecodableVideoDurationMs\s*=\s*600000L",
    ),
    "ios": (
        r"recoveryTargetFps\s*=\s*15",
        r"maxRecoveryFrameBudget\s*=\s*120",
        r"maxVideoDurationMs\s*=\s*60000",
        r"maxDecodableVideoDurationMs\s*=\s*600000",
    ),
}
for platform, patterns in constant_patterns.items():
    for pattern in patterns:
        require(
            re.search(pattern, sources[platform]) is not None,
            f"{platform} threshold mismatch: {pattern}",
        )

require(
    "durationMs > config.maxVideoDurationMs ||" in sources["web"]
    and "durationMs > config.maxDecodableVideoDurationMs" in sources["web"],
    "web must recover after 60 seconds and reject only beyond the decode budget",
)
require(
    "durationMs > maxVideoDurationMs ||" in sources["android"]
    and "durationMs > maxDecodableVideoDurationMs" in sources["android"],
    "Android must recover after 60 seconds and reject only beyond the decode budget",
)
require(
    "durationMs > Self.maxVideoDurationMs ||" in sources["ios"]
    and "durationMs <= Self.maxDecodableVideoDurationMs" in sources["ios"],
    "iOS must recover after 60 seconds and reject only beyond the decode budget",
)

ios_selection_method = sources["ios"]
require(
    re.search(r"let selectionMethod:\s*Any\b", ios_selection_method) is not None
    and 'selectionMethod = "ground"' in ios_selection_method
    and 'selectionMethod = "kinematic"' in ios_selection_method
    and "selectionMethod = NSNull()" in ios_selection_method
    and '"selectionMethod": selectionMethod' in ios_selection_method,
    "iOS selectionMethod must use an Any-typed payload value for ground, kinematic, and null states",
)
require(
    re.search(
        r"estimated\.isEmpty\s*\?\s*NSNull\(\)\s*:\s*\"kinematic\"",
        ios_selection_method,
    ) is None,
    "iOS must not mix NSNull and String directly in a nested ternary",
)

partial_result_tokens = {
    "web": (
        "metricContacts.length === 0 ? null",
        "elbowAngles.length === 0 ? null",
    ),
    "android": ("metricContactFrames.isEmpty()", '"analysisVersion" to 2'),
    "ios": ("metricContactFrames.isEmpty", '"analysisVersion": 2'),
}
for platform, tokens in partial_result_tokens.items():
    for token in tokens:
        require(token in sources[platform], f"{platform} partial-result path is missing {token}")

for field in (
    "analysisVersion",
    "recoverySamples",
    "measurements",
    "scaleSegments",
    "analysisWindowStart",
    "analysisWindowEnd",
    "estimatedContactFrameTimestamps",
    "selectionMethod",
):
    require(field in dart_contract, f"Dart result contract is missing {field}")

for platform, text in sources.items():
    require(
        text.find("validatedContactFrameTimestampsMs") !=
        text.find("estimatedContactFrameTimestampsMs"),
        f"{platform} must serialize confirmed and estimated contacts separately",
    )

require(
    "shouldDemoteLegacyKinematicContacts" in dart_contract,
    "Dart history compatibility must demote early-v2 kinematic contacts",
)
for field in (
    "state",
    "value",
    "expectedRange",
    "confidence",
    "sampleCount",
    "method",
    "reason",
    "evidenceTimestampsMs",
):
    require(field in measurement_contract, f"Dart measurement contract is missing {field}")

if failures:
    print("Running analysis v2 platform contract check failed:", file=sys.stderr)
    for failure in failures:
        print(f"- {failure}", file=sys.stderr)
    sys.exit(1)

print("Running analysis v2 platform contract check passed")
PY
