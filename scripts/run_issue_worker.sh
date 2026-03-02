#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

LOCK_DIR="/tmp/football_note_issue_worker.lock"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  echo "[issue-worker] Another run is active. Exiting."
  exit 0
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

: "${GITHUB_REPOSITORY:?Missing GITHUB_REPOSITORY}"
: "${GITHUB_TOKEN:?Missing GITHUB_TOKEN}"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"

log() {
  echo "[issue-worker] $*"
}

log "Syncing repository"
git fetch origin "$DEFAULT_BRANCH"
git checkout "$DEFAULT_BRANCH"
git pull --ff-only origin "$DEFAULT_BRANCH"

log "Refreshing queue file"
python3 scripts/sync_issue_queue.py || true

ISSUE_NUMBER="$(grep -Eo '#[0-9]+' docs/ISSUE_QUEUE.md | head -n1 | tr -d '#')"
if [[ -z "${ISSUE_NUMBER:-}" ]]; then
  log "No queued issue found."
  exit 0
fi

ISSUE_JSON="$(curl -sS -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "Accept: application/vnd.github+json" "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${ISSUE_NUMBER}")"
ISSUE_STATE="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read()).get("state",""))' <<< "$ISSUE_JSON")"
if [[ "$ISSUE_STATE" != "open" ]]; then
  log "Issue #$ISSUE_NUMBER is not open."
  exit 0
fi

ISSUE_TITLE="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read()).get("title","").strip())' <<< "$ISSUE_JSON")"
ISSUE_BODY="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read()).get("body","").strip())' <<< "$ISSUE_JSON")"
ISSUE_URL="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read()).get("html_url",""))' <<< "$ISSUE_JSON")"

SAFE_SLUG="$(python3 - "$ISSUE_TITLE" <<'PY'
import re,sys
text=sys.argv[1].lower()
text=re.sub(r'[^a-z0-9가-힣]+','-',text).strip('-')
print((text[:40] or 'task'))
PY
)"

HEAD_BRANCH="auto/issue-${ISSUE_NUMBER}-${SAFE_SLUG}"

if git show-ref --verify --quiet "refs/heads/${HEAD_BRANCH}"; then
  git checkout "$HEAD_BRANCH"
else
  git checkout -b "$HEAD_BRANCH" "$DEFAULT_BRANCH"
fi

if git ls-remote --exit-code --heads origin "$HEAD_BRANCH" >/dev/null 2>&1; then
  git pull --ff-only origin "$HEAD_BRANCH" || true
fi

PROMPT_FILE="/tmp/codex_issue_${ISSUE_NUMBER}.prompt"
cat > "$PROMPT_FILE" <<PROMPT
You are working in repository ${GITHUB_REPOSITORY}.

Implement GitHub issue #${ISSUE_NUMBER}.
Title: ${ISSUE_TITLE}
URL: ${ISSUE_URL}

Issue body:
${ISSUE_BODY}

Requirements:
- Make direct code changes in this repo.
- Keep existing features unless explicitly changed in the issue.
- Run minimal verification (at least flutter analyze for touched files).
- Prepare commit-ready changes.
PROMPT

export ISSUE_NUMBER ISSUE_TITLE ISSUE_URL ISSUE_BODY HEAD_BRANCH BASE_BRANCH="$DEFAULT_BRANCH" CODEX_PROMPT_FILE="$PROMPT_FILE"

if [[ -n "${CODEX_RUNNER_CMD:-}" ]]; then
  log "Running custom Codex command"
  bash -lc "$CODEX_RUNNER_CMD"
else
  if ! command -v codex >/dev/null 2>&1; then
    log "codex CLI not found. Set CODEX_RUNNER_CMD or install codex."
    exit 1
  fi
  log "Running codex CLI"
  if codex exec --help >/dev/null 2>&1; then
    codex exec "$(cat "$PROMPT_FILE")"
  else
    codex "$(cat "$PROMPT_FILE")"
  fi
fi

if git diff --quiet; then
  log "No changes produced by Codex."
  exit 0
fi

if [[ "${RUN_VERIFY:-0}" == "1" ]]; then
  log "Running verify"
  scripts/verify.sh || true
fi

COMMIT_TITLE="$(python3 - "$ISSUE_TITLE" "$ISSUE_NUMBER" <<'PY'
import sys,re
title=sys.argv[1]
num=sys.argv[2]
clean=re.sub(r'\s+',' ',title).strip()
print(f"feat: {clean} (#{num})")
PY
)"

log "Committing changes"
git add -A
git commit -m "$COMMIT_TITLE" -m "Closes #${ISSUE_NUMBER}"

log "Pushing branch $HEAD_BRANCH"
git push -u origin "$HEAD_BRANCH"

log "Creating/updating PR"
python3 scripts/create_or_update_pr.py

log "Done"
