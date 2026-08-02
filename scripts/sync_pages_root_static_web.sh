#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${1:-${ROOT_DIR}/build/web}"
ASSET_VERSION="${2:-$(git -C "${ROOT_DIR}" rev-parse --short=12 HEAD)}"

if [[ ! -d "${BUILD_DIR}" ]]; then
  echo "Web build directory not found: ${BUILD_DIR}" >&2
  exit 1
fi

for required in index.html flutter_bootstrap.js main.dart.js; do
  if [[ ! -f "${BUILD_DIR}/${required}" ]]; then
    echo "Web build is missing ${required}: ${BUILD_DIR}" >&2
    exit 1
  fi
done

"${ROOT_DIR}/scripts/stamp_web_asset_version.sh" "${BUILD_DIR}" "${ASSET_VERSION}"

if ! command -v rsync >/dev/null 2>&1; then
  echo "rsync is required to sync the Pages root artifact." >&2
  exit 1
fi

# GitHub Pages for this repository serves the main-branch root. Sync only the
# generated web artifact into that root; source files outside build/web remain
# untouched.
rsync -a --exclude='*.symbols' "${BUILD_DIR}/" "${ROOT_DIR}/"

echo "Synced root Pages artifact from ${BUILD_DIR} (asset version: ${ASSET_VERSION})"
