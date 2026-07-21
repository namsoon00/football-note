#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT_DIR="$(pwd)"
# shellcheck disable=SC1091
source "${ROOT_DIR}/scripts/flutter_env.sh"
load_local_flutter_env "${ROOT_DIR}"
build_flutter_define_args

usage() {
  cat <<'EOF'
Build agent flow (no code edits, no git writes):
  - iOS archive/IPA build
  - Android app bundle/APK build

Usage:
  ./scripts/build_agent.sh <ios|android|all>
EOF
}

run_flutter_build() {
  if [[ ${#FLUTTER_DEFINE_ARGS[@]} -gt 0 ]]; then
    flutter "$@" "${FLUTTER_DEFINE_ARGS[@]}"
  else
    flutter "$@"
  fi
}

build_ios() {
  echo "==> flutter build ios --release"
  run_flutter_build build ios --release

  echo "==> flutter build ipa --release"
  run_flutter_build build ipa --release
}

build_android() {
  echo "==> flutter build appbundle --release"
  run_flutter_build build appbundle --release

  echo "==> flutter build apk --release"
  run_flutter_build build apk --release
}

target="${1:-all}"

case "${target}" in
  ios)
    build_ios
    ;;
  android)
    build_android
    ;;
  all)
    build_ios
    build_android
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    echo "Unknown target: ${target}"
    usage
    exit 1
    ;;
esac
