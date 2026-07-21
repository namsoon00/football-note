#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="$ROOT_DIR/.tmp/running_release_video_venv"
OUTPUT_DIR="$ROOT_DIR/.tmp/running-release-video-validation"
PYTHON_BIN="${PYTHON_BIN:-python3}"
KEEP_VENV=0

usage() {
  cat <<'EOF'
Usage: ./scripts/test_running_release_video_fixtures.sh [options]

Creates portrait fixtures from the repository's real runner sample MP4s and
checks them with the bundled MediaPipe pose_landmarker_lite.task model.

Options:
  --output-dir <path>  Directory under .tmp for derived MP4s, JSON reports, and logs.
  --keep-venv          Keep the temporary Python environment for diagnosis.
  -h, --help           Show this help text.

The generated videos are derived test inputs, not newly recorded device video.
This command exits 2 when a fixture does not meet its expected allow/reject gate.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-dir)
      shift
      if [[ -z "${1:-}" ]]; then
        echo "--output-dir requires a path" >&2
        exit 64
      fi
      OUTPUT_DIR="${1:-}"
      ;;
    --keep-venv)
      KEEP_VENV=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 64
      ;;
  esac
  shift || true
done

cd "$ROOT_DIR"
OUTPUT_DIR="$("$PYTHON_BIN" - "$ROOT_DIR" "$OUTPUT_DIR" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1]).resolve()
output = Path(sys.argv[2])
if not output.is_absolute():
    output = root / output
output = output.resolve()
tmp_root = (root / ".tmp").resolve()
try:
    output.relative_to(tmp_root)
except ValueError:
    print(f"--output-dir must be under {root / '.tmp'}: {output}", file=sys.stderr)
    raise SystemExit(64)
print(output)
PY
)"
LOG_DIR="$OUTPUT_DIR/logs"
PIP_LOG="$LOG_DIR/pip_install.log"
RUN_LOG="$LOG_DIR/release_validation.log"

mkdir -p "$ROOT_DIR/.tmp"
rm -rf "$VENV_DIR" "$OUTPUT_DIR"
mkdir -p "$LOG_DIR"

exec > >(tee "$RUN_LOG") 2>&1

cleanup() {
  if [[ "$KEEP_VENV" != "1" ]]; then
    rm -rf "$VENV_DIR"
  fi
}
trap cleanup EXIT

echo "==> create MediaPipe fixture environment"
"$PYTHON_BIN" -m venv "$VENV_DIR"
"$VENV_DIR/bin/python" -m pip install --upgrade pip >"$PIP_LOG"
"$VENV_DIR/bin/python" -m pip install \
  mediapipe==0.10.21 \
  opencv-python-headless==4.10.0.84 \
  >>"$PIP_LOG"
echo "==> dependency log: $PIP_LOG"

echo "==> generate derived real-video fixtures"
"$VENV_DIR/bin/python" scripts/generate_running_release_video_fixtures.py \
  --output-dir "$OUTPUT_DIR"

echo "==> analyze fixtures with bundled Pose Landmarker"
"$VENV_DIR/bin/python" scripts/analyze_running_release_video_fixtures.py \
  --fixture-dir "$OUTPUT_DIR" \
  --model ios/Runner/pose_landmarker_lite.task \
  --repo-root "$ROOT_DIR" \
  --report "$OUTPUT_DIR/release_validation_report.json"

echo "==> validation log: $RUN_LOG"
