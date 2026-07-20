#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p .tmp
TEMP_DIR="$(mktemp -d ".tmp/running_gait_gate.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT

GROUND_TRUTH="$TEMP_DIR/ground_truth.json"
PREDICTIONS_LOG="$TEMP_DIR/predictions.log"
BAD_PREDICTIONS="$TEMP_DIR/bad_predictions.json"
PASS_REPORT="$TEMP_DIR/pass_report.json"
FAIL_REPORT="$TEMP_DIR/fail_report.json"
FAIL_STDERR="$TEMP_DIR/fail_stderr.txt"
BAD_STDERR="$TEMP_DIR/bad_stderr.txt"

cat >"$GROUND_TRUTH" <<'JSON'
{
  "schemaVersion": 1,
  "events": [
    {"timestampMs": 100, "side": "left", "type": "touchdown"},
    {"timestampMs": 220, "side": "left", "type": "toeOff"},
    {"timestampMs": 360, "side": "right", "type": "touchdown"}
  ]
}
JSON

cat >"$PREDICTIONS_LOG" <<'LOG'
unrelated debug line
I/flutter (123): [RunningLiveSession] {"sessionId":"running-a","event":"periodic","events":{"timeline":[{"timestampMs":108,"side":"left","type":"touchdown","timestamp":"2026-07-21T09:00:00.108","absoluteTimestampMs":1784592000108,"confidence":"0.900"}]}}
I/flutter (123): [RunningLiveSession] {"sessionId":"running-b","event":"periodic","events":{"timeline":[{"timestampMs":999,"side":"left","type":"touchdown","timestamp":"2026-07-21T09:00:00.999","absoluteTimestampMs":1784592000999,"confidence":"0.500"}]}}
I/flutter (123): [RunningLiveSession] {"sessionId":"running-a","event":"periodic","events":{"timeline":[{"timestampMs":108,"side":"left","type":"touchdown","timestamp":"2026-07-21T09:00:00.108","absoluteTimestampMs":1784592000108,"confidence":"0.900"},{"timestampMs":228,"side":"left","type":"toeOff","timestamp":"2026-07-21T09:00:00.228","absoluteTimestampMs":1784592000228,"confidence":"0.850"},{"timestampMs":365,"side":"right","type":"touchdown","timestamp":"2026-07-21T09:00:00.365","absoluteTimestampMs":1784592000365,"confidence":"0.880"}]}}
LOG

dart bin/running_gait_calibration_evaluator.dart \
  --ground-truth "$GROUND_TRUTH" \
  --predictions "$PREDICTIONS_LOG" \
  --prediction-session-id running-a \
  --tolerance-ms 20 \
  --min-ground-truth-events 3 \
  --min-overall-precision 1 \
  --min-overall-recall 1 \
  --min-overall-f1 1 \
  --max-timing-mae-ms 10 \
  --max-timing-p95-ms 10 \
  --min-touchdown-precision 1 \
  --min-touchdown-recall 1 \
  --min-toe-off-precision 1 \
  --min-toe-off-recall 1 \
  >"$PASS_REPORT"

python3 - "$PASS_REPORT" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as fh:
    report = json.load(fh)

assert report["qualityGate"]["passed"] is True
assert report["qualityGate"]["violations"] == []
assert report["predictionInput"]["format"] == "runningLiveSessionLog"
assert report["predictionInput"]["sessionId"] == "running-a"
assert report["predictionInput"]["deduplicatedRepeatedEvents"] == 1
assert report["overall"]["tp"] == 3
assert report["overall"]["fp"] == 0
assert report["overall"]["fn"] == 0
PY

set +e
dart bin/running_gait_calibration_evaluator.dart \
  --ground-truth "$GROUND_TRUTH" \
  --predictions "$PREDICTIONS_LOG" \
  --prediction-session-id running-a \
  --tolerance-ms 20 \
  --max-timing-mae-ms 6 \
  >"$FAIL_REPORT" 2>"$FAIL_STDERR"
FAIL_STATUS=$?
set -e

if [[ "$FAIL_STATUS" -ne 2 ]]; then
  echo "[running-gait-gate-test] expected gate failure exit 2, got $FAIL_STATUS" >&2
  cat "$FAIL_STDERR" >&2
  exit 1
fi

python3 - "$FAIL_REPORT" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as fh:
    report = json.load(fh)

assert report["qualityGate"]["passed"] is False
metrics = [item["metric"] for item in report["qualityGate"]["violations"]]
assert metrics == ["overall.maeMs"], metrics
PY

printf '{"events":' >"$BAD_PREDICTIONS"
set +e
dart bin/running_gait_calibration_evaluator.dart \
  --ground-truth "$GROUND_TRUTH" \
  --predictions "$BAD_PREDICTIONS" \
  >"$TEMP_DIR/bad_stdout.txt" 2>"$BAD_STDERR"
BAD_STATUS=$?
set -e

if [[ "$BAD_STATUS" -ne 65 ]]; then
  echo "[running-gait-gate-test] expected input error exit 65, got $BAD_STATUS" >&2
  cat "$BAD_STDERR" >&2
  exit 1
fi

echo "[running-gait-gate-test] ok"
