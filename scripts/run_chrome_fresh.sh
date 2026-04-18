#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
# shellcheck disable=SC1091
source "${ROOT_DIR}/scripts/flutter_env.sh"
load_local_flutter_env "${ROOT_DIR}"
build_flutter_define_args

# Stop previous flutter/chrome debug runs to avoid stale sessions.
pkill -f "flutter run -d chrome" >/dev/null 2>&1 || true
pkill -f "org-dartlang-app:/web_entrypoint.dart" >/dev/null 2>&1 || true

exec flutter run "${FLUTTER_DEFINE_ARGS[@]}" -d chrome "$@"
