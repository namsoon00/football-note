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
football_note CLI

Usage:
  ./scripts/cli.sh <command>

Commands:
  coding    Coding agent flow (optional harness -> verify -> branch merge -> push main)
  request   Chat task flow (request normalization -> harness -> verify -> merge/push)
  chat      Alias for `request`
  build     Build agent flow (ios/android/all)
  verify    Run full verification (includes iOS simulator build/run)
  verify-push  Verify, commit on work branch, merge/push main (supports --issue N)
  fix       Run auto-fix steps and checks
  test      Run flutter tests
  analyze   Run flutter analyze
  format    Run dart format
  run       Run app with local dart-defines forwarded to flutter run
  run-ios   Run app on first available iOS simulator
  help      Show this help
EOF
}

run_ios() {
  echo "==> launch iOS simulator"
  flutter emulators --launch apple_ios_simulator

  local sim_id
  sim_id=$(flutter devices | rg "simulator" | head -n1 | awk -F '•' '{print $2}' | xargs)
  if [[ -z "${sim_id}" ]]; then
    echo "No iOS simulator found. Aborting."
    exit 1
  fi

  echo "==> flutter run (iOS simulator: ${sim_id})"
  flutter run "${FLUTTER_DEFINE_ARGS[@]}" -d "${sim_id}" --no-resident "$@"
}

cmd="${1:-help}"

case "${cmd}" in
  coding)
    shift || true
    ./scripts/coding_agent.sh "$@"
    ;;
  request|chat)
    shift || true
    ./scripts/chat_task.sh "$@"
    ;;
  build)
    shift || true
    ./scripts/build_agent.sh "${1:-all}"
    ;;
  verify)
    ./scripts/verify.sh
    ;;
  verify-push)
    shift || true
    ./scripts/verify_commit_push.sh "$@"
    ;;
  fix)
    ./scripts/fix.sh
    ;;
  test)
    flutter test
    ;;
  analyze)
    flutter analyze
    ;;
  format)
    dart format .
    ;;
  run)
    shift || true
    flutter run "${FLUTTER_DEFINE_ARGS[@]}" "$@"
    ;;
  run-ios)
    shift || true
    run_ios "$@"
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    echo "Unknown command: ${cmd}"
    echo ""
    usage
    exit 1
    ;;
esac
