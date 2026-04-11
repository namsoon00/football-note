#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

usage() {
  cat <<'EOF'
Usage:
  ./scripts/verify_commit_push.sh -m "<commit message>" [-b "<branch-name>"] [--issue "<number>"]

Options:
  -m, --message   Commit message (required)
  -b, --branch    Work branch name (optional)
  --issue         GitHub issue number to close after push (optional)
EOF
}

commit_message=""
work_branch=""
issue_number=""

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
    --issue)
      shift
      issue_number="${1:-}"
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

if [[ -n "${issue_number}" ]] && ! [[ "${issue_number}" =~ ^[0-9]+$ ]]; then
  echo "Issue number must be numeric: ${issue_number}"
  exit 1
fi

infer_issue_from_message() {
  local raw="$1"
  if [[ "${raw}" =~ \#([0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    echo ""
  fi
}

normalize_issue_number() {
  local raw="$1"
  if [[ "${raw}" == "0" ]]; then
    echo ""
  else
    echo "${raw}"
  fi
}

slugify() {
  echo "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g' \
    | cut -c1-40
}

infer_repo_from_origin() {
  local origin_url repo
  origin_url="$(git remote get-url origin)"
  if [[ "${origin_url}" =~ ^git@github.com:(.+)\.git$ ]]; then
    repo="${BASH_REMATCH[1]}"
  elif [[ "${origin_url}" =~ ^https://github.com/(.+)\.git$ ]]; then
    repo="${BASH_REMATCH[1]}"
  elif [[ "${origin_url}" =~ ^https://github.com/(.+)$ ]]; then
    repo="${BASH_REMATCH[1]}"
  else
    repo=""
  fi
  echo "${repo}"
}

close_issue() {
  local issue="$1"
  local repo token merge_sha
  repo="${GITHUB_REPOSITORY:-$(infer_repo_from_origin)}"
  token="${GITHUB_TOKEN:-}"
  merge_sha="$(git rev-parse --short HEAD)"

  if [[ -z "${repo}" ]]; then
    echo "Cannot resolve GitHub repository. Set GITHUB_REPOSITORY."
    return 1
  fi

  if command -v gh >/dev/null 2>&1; then
    echo "==> gh issue close #${issue} (${repo})"
    gh issue close "${issue}" \
      --repo "${repo}" \
      --comment "Merged into main at ${merge_sha}."
    return $?
  fi

  if [[ -z "${token}" ]]; then
    echo "Cannot close issue #${issue}: gh CLI not found and GITHUB_TOKEN is not set."
    return 1
  fi

  echo "==> close issue #${issue} via GitHub API (${repo})"
  curl -sS \
    -H "Authorization: Bearer ${token}" \
    -H "Accept: application/vnd.github+json" \
    -X PATCH \
    "https://api.github.com/repos/${repo}/issues/${issue}" \
    -d '{"state":"closed","state_reason":"completed"}' \
    >/dev/null

  curl -sS \
    -H "Authorization: Bearer ${token}" \
    -H "Accept: application/vnd.github+json" \
    -X POST \
    "https://api.github.com/repos/${repo}/issues/${issue}/comments" \
    -d "{\"body\":\"Merged into main at ${merge_sha}.\"}" \
    >/dev/null
}

current_branch="$(git rev-parse --abbrev-ref HEAD)"

if [[ -z "${issue_number}" ]]; then
  issue_number="$(infer_issue_from_message "${commit_message}")"
  if [[ -n "${issue_number}" ]]; then
    echo "==> inferred issue #${issue_number} from commit message"
  fi
fi

issue_number="$(normalize_issue_number "${issue_number}")"

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
if [[ -n "${issue_number}" ]]; then
  git commit -m "${commit_message}" -m "Closes #${issue_number}"
else
  git commit -m "${commit_message}"
fi

echo "==> git checkout main"
git checkout main

echo "==> git merge --no-ff ${work_branch}"
if [[ -n "${issue_number}" ]]; then
  git merge --no-ff "${work_branch}" -m "merge: ${commit_message}" -m "Closes #${issue_number}"
else
  git merge --no-ff "${work_branch}" -m "merge: ${commit_message}"
fi

echo "==> git push origin main"
git push origin main

if [[ -n "${issue_number}" ]]; then
  close_issue "${issue_number}"
fi
