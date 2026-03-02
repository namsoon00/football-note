#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Stop previous flutter/chrome debug runs to avoid stale sessions.
pkill -f "flutter run -d chrome" >/dev/null 2>&1 || true
pkill -f "org-dartlang-app:/web_entrypoint.dart" >/dev/null 2>&1 || true

exec flutter run -d chrome "$@"
