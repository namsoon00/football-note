#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

usage() {
  cat <<'EOF'
Usage:
  ./scripts/verify_commit_push.sh -m "<commit message>" [-b "<branch-name>"]

Options:
  -m, --message   Commit message (required)
  -b, --branch    Work branch name (optional)
EOF
}

commit_message=""
work_branch=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--message)
      shift
      commit_message="${1:-}"
      ;;
    -b|--branch)
      shift
      work_branch="${1:-}"
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

slugify() {
  echo "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g' \
    | cut -c1-40
}

current_branch="$(git rev-parse --abbrev-ref HEAD)"

if [[ "${current_branch}" == "main" ]]; then
  echo "==> git pull --rebase origin main"
  git pull --rebase origin main
fi

echo "==> verify"
./scripts/verify.sh

echo "==> git status"
if [[ -z "$(git status --porcelain)" ]]; then
  echo "No changes to commit."
  exit 0
fi

if [[ -z "${work_branch}" ]]; then
  if [[ "${current_branch}" == "main" ]]; then
    msg_slug="$(slugify "${commit_message}")"
    if [[ -z "${msg_slug}" ]]; then
      msg_slug="work"
    fi
    work_branch="work/$(date +%Y%m%d-%H%M%S)-${msg_slug}"
  else
    work_branch="${current_branch}"
  fi
fi

if [[ "${current_branch}" == "main" ]]; then
  echo "==> git checkout -b ${work_branch}"
  git checkout -b "${work_branch}"
else
  if [[ "${current_branch}" != "${work_branch}" ]]; then
    echo "==> git checkout ${work_branch}"
    git checkout "${work_branch}"
  fi
fi

echo "==> git add -A"
git add -A

echo "==> git commit"
git commit -m "${commit_message}"

echo "==> git checkout main"
git checkout main

echo "==> git merge --no-ff ${work_branch}"
git merge --no-ff "${work_branch}" -m "merge: ${commit_message}"

echo "==> git push origin main"
git push origin main
