#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

usage() {
  cat <<'EOF'
Coding agent flow:
  - verify
  - branch commit
  - merge to main
  - push main
  - optionally close issue

Usage:
  ./scripts/coding_agent.sh -m "<commit message>" [--issue <number>] [-b <branch>]
EOF
}

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

./scripts/verify_commit_push.sh "$@"
