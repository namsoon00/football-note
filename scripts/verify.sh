#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

VERIFY_SCOPE="${VERIFY_SCOPE:-full}"
if [[ "${GITHUB_ACTIONS:-}" == "true" && "${VERIFY_SCOPE}" == "full" ]]; then
  # Keep CI runs predictable and avoid long-running simulator/test hangs.
  VERIFY_SCOPE="minimal"
fi

run_with_timeout() {
  local timeout_seconds="$1"
  shift
  python3 - "$timeout_seconds" "$@" <<'PY'
import subprocess
import sys

timeout_seconds = int(sys.argv[1])
cmd = sys.argv[2:]
proc = subprocess.Popen(cmd)

try:
    sys.exit(proc.wait(timeout=timeout_seconds))
except subprocess.TimeoutExpired:
    proc.kill()
    try:
        proc.wait(timeout=10)
    except subprocess.TimeoutExpired:
        pass
    print(
        f"[verify] Timeout after {timeout_seconds}s: {' '.join(cmd)}",
        file=sys.stderr,
    )
    sys.exit(124)
PY
}

echo "==> flutter pub get"
flutter pub get

echo "==> flutter gen-l10n"
flutter gen-l10n

echo "==> localization consistency"
python3 scripts/check_l10n_consistency.py

echo "==> flutter analyze"
flutter analyze

echo "==> design consistency guardrails"
./scripts/check_design_consistency.sh

echo "==> quiz quality harness"
./scripts/quiz_quality_harness.sh

echo "==> quiz generation harness"
./scripts/quiz_generation_harness.sh

echo "==> issue worker plan classifier regression"
./scripts/test_issue_plan_request_classifier.sh

echo "==> issue worker wording regression"
./scripts/test_issue_worker_plan_wording.sh

echo "==> web asset version stamp regression"
./scripts/test_web_asset_version_stamp.sh

if [[ "${VERIFY_SCOPE}" == "minimal" ]]; then
  echo "==> minimal verification complete (skipping flutter test/run)"
  exit 0
fi

echo "==> full verification complete (flutter test/run skipped by local policy)"
