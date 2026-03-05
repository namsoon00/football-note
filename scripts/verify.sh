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

echo "==> flutter analyze"
flutter analyze

if [[ "${VERIFY_SCOPE}" == "minimal" ]]; then
  echo "==> minimal verification complete (skipping flutter test/iOS run)"
  exit 0
fi

echo "==> flutter test"
run_with_timeout "${FLUTTER_TEST_TIMEOUT_SECONDS:-900}" flutter test

echo "==> launch iOS simulator"
run_with_timeout "${FLUTTER_EMULATOR_TIMEOUT_SECONDS:-120}" flutter emulators --launch apple_ios_simulator

SIM_ID=$(flutter devices | rg "simulator" | head -n1 | awk -F '•' '{print $2}' | xargs)
if [[ -z "${SIM_ID}" ]]; then
  echo "No iOS simulator found. Aborting."
  exit 1
fi

echo "==> flutter run (iOS simulator: ${SIM_ID})"
run_with_timeout "${FLUTTER_RUN_TIMEOUT_SECONDS:-600}" flutter run -d "${SIM_ID}" --no-resident
