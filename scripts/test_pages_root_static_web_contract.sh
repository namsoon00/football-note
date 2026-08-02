#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

required_files=(
  index.html
  flutter_bootstrap.js
  main.dart.js
  version.json
  running_video_pose_analysis.js
  mediapipe/pose_landmarker_full.task
)

for file in "${required_files[@]}"; do
  if [[ ! -f "${file}" ]]; then
    echo "Published Pages artifact is missing ${file}" >&2
    exit 1
  fi
done

if grep -R "__WEB_ASSET_VERSION__" index.html flutter_bootstrap.js >/dev/null; then
  echo "Published Pages artifact has an unstamped asset version." >&2
  exit 1
fi

grep -F "running_video_pose_analysis.js?v=" index.html >/dev/null
grep -F "webAssetVersion" flutter_bootstrap.js >/dev/null
grep -F "assetVersion" version.json >/dev/null
grep -F "runningVideoPoseAnalysis" main.dart.js >/dev/null

asset_version="$(python3 - <<'PY'
import json
from pathlib import Path

raw = json.loads(Path('version.json').read_text(encoding='utf-8'))
version = raw.get('assetVersion')
if not isinstance(version, str) or not version:
    raise SystemExit('Published Pages asset version is missing.')
print(version)
PY
)"
grep -F "main.dart.js?v=${asset_version}" index.html >/dev/null
grep -F "running_video_pose_analysis.js?v=${asset_version}" index.html >/dev/null
grep -F "const webAssetVersion = '${asset_version}';" flutter_bootstrap.js >/dev/null

if command -v node >/dev/null 2>&1; then
  node --check running_video_pose_analysis.js
fi

echo "Published Pages root artifact contract passed"
