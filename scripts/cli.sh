#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

usage() {
  cat <<'EOF'
football_note CLI

Usage:
  ./scripts/cli.sh <command>

Commands:
  coding    Coding agent flow (optional harness -> verify -> branch merge -> push main)
  build     Build agent flow (ios/android/all)
  verify    Run full verification (includes iOS simulator build/run)
  verify-push  Verify, commit on work branch, merge/push main (supports --issue N)
  fix       Run auto-fix steps and checks
  test      Run flutter tests
  analyze   Run flutter analyze
  format    Run dart format
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
  flutter run -d "${sim_id}" --no-resident
}

cmd="${1:-help}"

case "${cmd}" in
  coding)
    shift || true
    ./scripts/coding_agent.sh "$@"
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
  run-ios)
    run_ios
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
