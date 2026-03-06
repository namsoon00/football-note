#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

usage() {
  cat <<'EOF'
Build agent flow (no code edits, no git writes):
  - iOS archive/IPA build
  - Android app bundle/APK build

Usage:
  ./scripts/build_agent.sh <ios|android|all>
EOF
}

build_ios() {
  echo "==> flutter build ios --release"
  flutter build ios --release

  echo "==> flutter build ipa --release"
  flutter build ipa --release
}

build_android() {
  echo "==> flutter build appbundle --release"
  flutter build appbundle --release

  echo "==> flutter build apk --release"
  flutter build apk --release
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
