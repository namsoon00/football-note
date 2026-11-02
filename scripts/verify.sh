#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

requested_scope="${VERIFY_SCOPE:-quick}"
case "${requested_scope}" in
  quick|minimal)
    VERIFY_SCOPE="quick"
    ;;
  full)
    VERIFY_SCOPE="full"
    ;;
  *)
    echo "Unknown VERIFY_SCOPE: ${requested_scope} (expected quick, minimal, or full)" >&2
    exit 2
    ;;
esac

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
flutter analyze --no-pub

echo "==> design consistency guardrails"
./scripts/check_design_consistency.sh

if [[ "${VERIFY_SCOPE}" == "quick" ]]; then
  echo "==> prelaunch smoke tests"
  ./scripts/run_prelaunch_smoke_tests.sh
  echo "==> quick prelaunch verification complete"
  exit 0
fi

echo "==> spatial education asset verification"
python3 tool/scan_pass_replay/prepare_spatial_education.py --verify-assets

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

echo "==> verification profile pipeline regression"
./scripts/test_verify_profiles.sh

echo "==> iOS native asset embedding regression"
./scripts/test_ios_native_assets.sh

echo "==> iOS path provider plugin compatibility"
./scripts/test_ios_path_provider_foundation_compatibility.sh

echo "==> android upload mediapipe contract"
./scripts/test_android_upload_mediapipe_contract.sh

echo "==> web upload video analysis contract"
./scripts/test_web_running_video_analysis_contract.sh

echo "==> running analysis v2 cross-platform contract"
./scripts/test_running_analysis_v2_contract.sh

echo "==> published Pages root artifact contract"
./scripts/test_pages_root_static_web_contract.sh

echo "==> running 3D removal contract"
./scripts/test_running_no_3d_runner_contract.sh

echo "==> running release video fixture contract"
./scripts/test_running_release_video_fixtures_contract.sh

echo "==> flutter test"
run_with_timeout 600 flutter test

echo "==> full verification complete"
