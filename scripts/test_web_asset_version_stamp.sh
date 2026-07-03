#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

tmp_dir=".tmp/web-asset-version-stamp-test"
rm -rf "${tmp_dir}"
mkdir -p "${tmp_dir}"
trap 'rm -rf "${tmp_dir}"' EXIT

cp web/index.html "${tmp_dir}/index.html"
cp web/flutter_bootstrap.js "${tmp_dir}/flutter_bootstrap.js"
printf '{"assetVersion":"old"}\n' >"${tmp_dir}/version.json"

./scripts/stamp_web_asset_version.sh "${tmp_dir}" "feature/test@123"

expected_version="feature-test-123"

if grep -R "__WEB_ASSET_VERSION__" \
  "${tmp_dir}/index.html" \
  "${tmp_dir}/flutter_bootstrap.js" >/dev/null; then
  echo "Expected web asset placeholders to be replaced." >&2
  exit 1
fi

grep -F "main.dart.js?v=${expected_version}" "${tmp_dir}/index.html" >/dev/null
grep -F "flutter_bootstrap.js?v=${expected_version}" \
  "${tmp_dir}/index.html" >/dev/null
grep -F "const webAssetVersion = '${expected_version}'" \
  "${tmp_dir}/flutter_bootstrap.js" >/dev/null
grep -F "const unstampedAssetVersionToken = ['__WEB', 'ASSET', 'VERSION__'].join('_')" \
  "${tmp_dir}/flutter_bootstrap.js" >/dev/null
if grep -F "webAssetVersion.includes('${expected_version}')" \
  "${tmp_dir}/flutter_bootstrap.js" >/dev/null; then
  echo "Expected unstamped placeholder detection to survive stamping." >&2
  exit 1
fi
grep -F "\"assetVersion\":\"${expected_version}\"" \
  "${tmp_dir}/version.json" >/dev/null

echo "[web-asset-version-stamp] ok"
