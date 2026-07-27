#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

mkdir -p .tmp
tmp_dir="$(mktemp -d ".tmp/ios-native-assets.XXXXXX")"
trap 'rm -rf "${tmp_dir}"' EXIT

app_dir="${tmp_dir}/app"
target_dir="${tmp_dir}/target"
manifest="${target_dir}/Frameworks/App.framework/flutter_assets/NativeAssetsManifest.json"
source_framework="${app_dir}/build/native_assets/ios/objective_c.framework"
target_framework="${target_dir}/Frameworks/objective_c.framework"

mkdir -p "$(dirname "${manifest}")" "${source_framework}"
printf 'native asset fixture\n' >"${source_framework}/objective_c"
printf '%s\n' \
  '{"format-version":[1,0,0],"native-assets":{"ios_arm64":{"package:objective_c/objective_c.dylib":["absolute","objective_c.framework/objective_c"]}}}' \
  >"${manifest}"

run_native_asset_script() {
  PLATFORM_NAME=iphoneos \
    CODE_SIGNING_REQUIRED=NO \
    TARGET_BUILD_DIR="${target_dir}" \
    FRAMEWORKS_FOLDER_PATH=Frameworks \
    FLUTTER_APPLICATION_PATH="${app_dir}" \
    FLUTTER_BUILD_DIR=build \
    SRCROOT="${tmp_dir}/project/ios" \
    /bin/sh ios/scripts/resign_native_assets.sh
}

run_native_asset_script
test -f "${target_framework}/objective_c"
cmp "${source_framework}/objective_c" "${target_framework}/objective_c"

rm -rf "${target_framework}" "${source_framework}"
set +e
failure_output="$(run_native_asset_script 2>&1)"
failure_status=$?
set -e

if [ "${failure_status}" -eq 0 ]; then
  echo "Expected missing native asset framework to fail the iOS build phase." >&2
  exit 1
fi

grep -F "Native asset framework objective_c.framework is missing" <<<"${failure_output}" >/dev/null

echo "[ios-native-assets] ok"
