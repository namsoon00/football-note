#!/bin/sh
set -eu

if [ "${PLATFORM_NAME:-}" != "iphoneos" ]; then
  exit 0
fi

if [ "${CODE_SIGNING_REQUIRED:-}" = "NO" ]; then
  exit 0
fi

if [ -z "${EXPANDED_CODE_SIGN_IDENTITY:-}" ]; then
  exit 0
fi

frameworks_dir="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
native_manifest="${frameworks_dir}/App.framework/flutter_assets/NativeAssetsManifest.json"

if [ ! -f "${native_manifest}" ]; then
  exit 0
fi

python3 - <<'PY' "${native_manifest}" | while IFS= read -r framework_name; do
import json
import os
import sys

with open(sys.argv[1], encoding="utf-8") as file:
    payload = json.load(file)

frameworks = set()
for per_platform in (payload.get("native-assets") or {}).values():
    if not isinstance(per_platform, dict):
        continue
    for asset in per_platform.values():
        if not (isinstance(asset, list) and len(asset) == 2):
            continue
        if asset[0] != "absolute" or not isinstance(asset[1], str):
            continue
        framework_dir = os.path.dirname(asset[1])
        if framework_dir.endswith(".framework"):
            frameworks.add(framework_dir[: -len(".framework")])

for framework in sorted(frameworks):
    print(framework)
PY
  framework_path="${frameworks_dir}/${framework_name}.framework"
  if [ -d "${framework_path}" ]; then
    echo "Resigning native asset framework ${framework_name}.framework"
    codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" --timestamp=none "${framework_path}"
  fi
done
