#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

usage() {
  cat <<'EOF'
Usage:
  ./scripts/verify_commit_push.sh -m "<commit message>"

Options:
  -m, --message   Commit message (required)
EOF
}

commit_message=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--message)
      shift
      commit_message="${1:-}"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
  shift || true
done

if [[ -z "${commit_message}" ]]; then
  echo "Commit message is required."
  usage
  exit 1
fi

echo "==> verify"
./scripts/verify.sh

echo "==> git status"
if [[ -z "$(git status --porcelain)" ]]; then
  echo "No changes to commit."
  exit 0
fi

echo "==> git add -A"
git add -A

echo "==> git commit"
git commit -m "${commit_message}"

echo "==> git push origin main"
git push origin main
