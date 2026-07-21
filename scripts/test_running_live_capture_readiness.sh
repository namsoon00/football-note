#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p .tmp
TEMP_DIR="$(mktemp -d ".tmp/running_live_capture_readiness.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT

LOG="$TEMP_DIR/session.log"
PASS_REPORT="$TEMP_DIR/pass_report.json"
FAIL_REPORT="$TEMP_DIR/fail_report.json"
FAIL_STDERR="$TEMP_DIR/fail_stderr.txt"
INVALID_STDERR="$TEMP_DIR/invalid_stderr.txt"

cat >"$LOG" <<'LOG'
I/flutter (123): [RunningLiveCalibrationCapture] {"schemaVersion":1,"sessionId":"running-a","event":"end","elapsedMs":6000,"targetFrameIntervalMs":50,"metrics":{"analyzedFrames":110,"analyzedFrameIntervalMs":{"sampleCount":109,"p95":76},"averageConfidence":{"timing":0.82,"sideView":0.86},"skippedFrames":{"analysisError":0}},"events":{"total":12,"timeline":[[100,"left","touchdown",900],[250,"right","toeOff",900],[400,"left","touchdown",900],[550,"right","toeOff",900],[700,"left","touchdown",900],[850,"right","toeOff",900],[1000,"left","touchdown",900],[1150,"right","toeOff",900],[1300,"left","touchdown",900],[1450,"right","toeOff",900],[1600,"left","touchdown",900],[1750,"right","toeOff",900]]}}
LOG

dart bin/running_live_capture_readiness.dart \
  --logs "$LOG" \
  --session-id running-a \
  >"$PASS_REPORT"

python3 - "$PASS_REPORT" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as fh:
    report = json.load(fh)

assert report["input"]["format"] == "runningLiveCalibrationCapture"
assert report["capture"]["hasEndEvent"] is True
assert report["capture"]["analyzedFrameIntervalMs"]["p95"] == 76.0
assert report["readinessGate"]["passed"] is True
assert report["readinessGate"]["violations"] == []
PY

set +e
dart bin/running_live_capture_readiness.dart \
  --logs "$LOG" \
  --max-analyzed-frame-p95-ms 70 \
  >"$FAIL_REPORT" 2>"$FAIL_STDERR"
FAIL_STATUS=$?
set -e

if [[ "$FAIL_STATUS" -ne 2 ]]; then
  echo "[running-live-capture-readiness-test] expected gate failure exit 2, got $FAIL_STATUS" >&2
  cat "$FAIL_STDERR" >&2
  exit 1
fi

python3 - "$FAIL_REPORT" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as fh:
    report = json.load(fh)

assert report["readinessGate"]["passed"] is False
metrics = [item["metric"] for item in report["readinessGate"]["violations"]]
assert metrics == ["metrics.analyzedFrameIntervalMs.p95"], metrics
PY

set +e
dart bin/running_live_capture_readiness.dart \
  --logs "$LOG" \
  --min-timing-confidence 1.1 \
  >"$TEMP_DIR/invalid_stdout.txt" 2>"$INVALID_STDERR"
INVALID_STATUS=$?
set -e

if [[ "$INVALID_STATUS" -ne 64 ]]; then
  echo "[running-live-capture-readiness-test] expected usage error exit 64, got $INVALID_STATUS" >&2
  cat "$INVALID_STDERR" >&2
  exit 1
fi

set +e
dart bin/running_live_capture_readiness.dart \
  --logs "$LOG" \
  --max-analyzed-frame-p95-ms Infinity \
  >"$TEMP_DIR/nonfinite_stdout.txt" 2>"$INVALID_STDERR"
NONFINITE_STATUS=$?
set -e

if [[ "$NONFINITE_STATUS" -ne 64 ]]; then
  echo "[running-live-capture-readiness-test] expected usage error exit 64 for non-finite P95 threshold, got $NONFINITE_STATUS" >&2
  cat "$INVALID_STDERR" >&2
  exit 1
fi

echo "[running-live-capture-readiness-test] ok"
