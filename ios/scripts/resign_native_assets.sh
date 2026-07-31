#!/bin/sh
set -eu

if [ "${PLATFORM_NAME:-}" != "iphoneos" ]; then
  exit 0
fi

frameworks_dir="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
native_manifest="${frameworks_dir}/App.framework/flutter_assets/NativeAssetsManifest.json"

if [ ! -f "${native_manifest}" ]; then
  exit 0
fi

flutter_application_path="${FLUTTER_APPLICATION_PATH:-${SRCROOT}/..}"
flutter_build_dir="${FLUTTER_BUILD_DIR:-build}"
case "${flutter_build_dir}" in
  /*)
    native_assets_dir="${flutter_build_dir}/native_assets/ios"
    ;;
  *)
    native_assets_dir="${flutter_application_path}/${flutter_build_dir}/native_assets/ios"
    ;;
esac

frameworks_file="$(mktemp "${TMPDIR:-/tmp}/football-note-native-assets.XXXXXX")"
trap 'rm -f "${frameworks_file}"' EXIT

python3 - "${native_manifest}" >"${frameworks_file}" <<'PY'
import json
import os
import sys

with open(sys.argv[1], encoding="utf-8") as file:
    payload = json.load(file)

frameworks = set()
for platform, per_platform in (payload.get("native-assets") or {}).items():
    if not isinstance(platform, str) or not platform.startswith("ios_"):
        continue
    if not isinstance(per_platform, dict):
        continue
    for asset in per_platform.values():
        if not (isinstance(asset, list) and len(asset) == 2):
            continue
        if asset[0] != "absolute" or not isinstance(asset[1], str):
            continue
        framework_dir = os.path.dirname(asset[1])
        if framework_dir.endswith(".framework"):
            frameworks.add((framework_dir[: -len(".framework")], asset[1]))

for framework, asset_path in sorted(frameworks):
    print(f"{framework}\t{asset_path}")
PY

while IFS="$(printf '\t')" read -r framework_name asset_path; do
  [ -n "${framework_name}" ] || continue

  framework_path="${frameworks_dir}/${framework_name}.framework"
  target_asset_path="${frameworks_dir}/${asset_path}"
  source_framework_path="${native_assets_dir}/${framework_name}.framework"
  source_asset_path="${native_assets_dir}/${asset_path}"

  if [ ! -f "${target_asset_path}" ]; then
    if [ ! -f "${source_asset_path}" ]; then
      echo "error: Native asset framework ${framework_name}.framework is missing from ${native_assets_dir}." >&2
      exit 1
    fi

    mkdir -p "${frameworks_dir}"
    echo "Embedding native asset framework ${framework_name}.framework"
    if command -v ditto >/dev/null 2>&1; then
      ditto "${source_framework_path}" "${framework_path}"
    else
      cp -R "${source_framework_path}" "${framework_path}"
    fi
  fi

  if [ ! -f "${target_asset_path}" ]; then
    echo "error: Native asset framework ${framework_name}.framework was not embedded into ${frameworks_dir}." >&2
    exit 1
  fi

  if [ "${CODE_SIGNING_REQUIRED:-}" != "NO" ] && [ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" ]; then
    echo "Resigning native asset framework ${framework_name}.framework"
    codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" --timestamp=none "${framework_path}"
  fi
done <"${frameworks_file}"
