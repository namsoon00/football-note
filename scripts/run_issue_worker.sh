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
CODEX_SANDBOX="${CODEX_SANDBOX:-workspace-write}"
CODEX_APPROVAL="${CODEX_APPROVAL:-never}"
USE_CUSTOM_CODEX_CMD="${USE_CUSTOM_CODEX_CMD:-0}"
CODEX_UNSAFE="${CODEX_UNSAFE:-1}"
FORCE_MAIN_MERGE="${FORCE_MAIN_MERGE:-1}"
LOCAL_SYNC_REPO_PATH="${LOCAL_SYNC_REPO_PATH:-/Users/namsoon00/Devel/football_note/football_note}"

log() {
  echo "[issue-worker] $*"
}

# Some self-hosted macOS runners deny /tmp fallback paths used by xcrun/git.
TMP_BASE="$ROOT_DIR/.tmp"
mkdir -p "$TMP_BASE"
export TMPDIR="$TMP_BASE"

log "Syncing repository"
git fetch origin "$DEFAULT_BRANCH"
git checkout "$DEFAULT_BRANCH"
git pull --ff-only origin "$DEFAULT_BRANCH"

log "Refreshing queue file"
python3 scripts/sync_issue_queue.py || true

if [[ ! -f "docs/ISSUE_QUEUE.md" ]]; then
  log "Queue file not found. Exiting."
  exit 0
fi

ISSUE_NUMBER="$(
  (
    grep -Eo '#[0-9]+' docs/ISSUE_QUEUE.md || true
  ) | head -n1 | tr -d '#'
)"
if [[ -z "${ISSUE_NUMBER:-}" ]]; then
  log "No queued issue found."
  exit 0
fi
# Queue sync updates docs/ISSUE_QUEUE.md on main; discard it for feature branch work
# to avoid checkout/rebase conflicts.
git restore --worktree --staged docs/ISSUE_QUEUE.md 2>/dev/null || true

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
  log "Aligning local branch with origin/${HEAD_BRANCH}"
  git fetch origin "$HEAD_BRANCH"
  git checkout -B "$HEAD_BRANCH" "origin/$HEAD_BRANCH"
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

CODEX_EXIT=0
set +e
if [[ "$USE_CUSTOM_CODEX_CMD" == "1" && -n "${CODEX_RUNNER_CMD:-}" ]]; then
  log "Running custom Codex command in $ROOT_DIR"
  log "Custom command: $CODEX_RUNNER_CMD"
  bash -lc "cd \"$ROOT_DIR\" && $CODEX_RUNNER_CMD"
  CODEX_EXIT=$?
else
  if [[ -n "${CODEX_RUNNER_CMD:-}" ]]; then
    log "Ignoring CODEX_RUNNER_CMD because USE_CUSTOM_CODEX_CMD!=1"
  fi
  if ! command -v codex >/dev/null 2>&1; then
    set -e
    log "codex CLI not found. Set CODEX_RUNNER_CMD or install codex."
    exit 1
  fi
  log "Running codex CLI (sandbox=$CODEX_SANDBOX, approval=$CODEX_APPROVAL, unsafe=$CODEX_UNSAFE)"
  if codex exec --help >/dev/null 2>&1; then
    if [[ "$CODEX_UNSAFE" == "1" ]]; then
      codex -C "$ROOT_DIR" \
        --dangerously-bypass-approvals-and-sandbox \
        exec "$(cat "$PROMPT_FILE")"
      CODEX_EXIT=$?
    else
      codex -C "$ROOT_DIR" \
        --sandbox "$CODEX_SANDBOX" \
        --ask-for-approval "$CODEX_APPROVAL" \
        exec "$(cat "$PROMPT_FILE")"
      CODEX_EXIT=$?
    fi
  else
    if [[ "$CODEX_UNSAFE" == "1" ]]; then
      codex -C "$ROOT_DIR" \
        --dangerously-bypass-approvals-and-sandbox \
        "$(cat "$PROMPT_FILE")"
      CODEX_EXIT=$?
    else
      codex -C "$ROOT_DIR" \
        --sandbox "$CODEX_SANDBOX" \
        --ask-for-approval "$CODEX_APPROVAL" \
        "$(cat "$PROMPT_FILE")"
      CODEX_EXIT=$?
    fi
  fi
fi
set -e

if [[ "$CODEX_EXIT" != "0" ]]; then
  log "Codex command exited with status ${CODEX_EXIT}. Checking git state before deciding failure."
fi

AHEAD_COUNT="$(git rev-list --count "${DEFAULT_BRANCH}..HEAD")"
HAS_WORKTREE_CHANGES=1
if \
  git diff --quiet && \
  git diff --cached --quiet && \
  [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
  HAS_WORKTREE_CHANGES=0
  if [[ "$AHEAD_COUNT" == "0" ]]; then
    log "No changes produced by Codex and no pending commits on ${HEAD_BRANCH}."
    curl -sS \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      -X POST \
      "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${ISSUE_NUMBER}/comments" \
      -d "{\"body\":\"자동 작업이 실행됐지만 코드 변경이 없어 종료했습니다. (이미 반영되었거나 추가 수정이 필요합니다)\"}" \
      >/dev/null || true
    exit 0
  fi
  log "No local changes, but branch is ${AHEAD_COUNT} commit(s) ahead of ${DEFAULT_BRANCH}. Continuing."
fi

if [[ "$CODEX_EXIT" != "0" ]]; then
  if [[ "$HAS_WORKTREE_CHANGES" == "0" && "$AHEAD_COUNT" != "0" ]]; then
    log "Codex exited non-zero, but branch already has ${AHEAD_COUNT} commit(s) to merge. Continuing."
  else
  log "Failing run because Codex exited non-zero and there are pending changes/commits to inspect."
  exit "$CODEX_EXIT"
  fi
fi

if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
  log "Skipping verify in GitHub Actions workflow run"
elif [[ "${RUN_VERIFY:-0}" == "1" ]]; then
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

if [[ "$HAS_WORKTREE_CHANGES" == "1" ]]; then
  log "Committing changes"
  git add -A
  git commit -m "$COMMIT_TITLE" -m "Closes #${ISSUE_NUMBER}"

  log "Pushing branch $HEAD_BRANCH"
  if ! git push -u origin "$HEAD_BRANCH"; then
    log "Push rejected, rebasing with remote and retrying once"
    git fetch origin "$HEAD_BRANCH"
    git rebase "origin/$HEAD_BRANCH"
    git push -u origin "$HEAD_BRANCH"
  fi
else
  if ! git ls-remote --exit-code --heads origin "$HEAD_BRANCH" >/dev/null 2>&1; then
    log "Pushing existing local commits to new remote branch $HEAD_BRANCH"
    git push -u origin "$HEAD_BRANCH"
  else
    log "Skipping commit/push; using existing commits on $HEAD_BRANCH"
  fi
fi

log "Creating/updating PR"
python3 scripts/create_or_update_pr.py

log "FORCE_MAIN_MERGE=$FORCE_MAIN_MERGE"
if [[ "$FORCE_MAIN_MERGE" == "1" ]]; then
  log "Force merging ${HEAD_BRANCH} into ${DEFAULT_BRANCH}"
  git fetch origin "$DEFAULT_BRANCH" "$HEAD_BRANCH"
  git checkout "$DEFAULT_BRANCH"
  git pull --ff-only origin "$DEFAULT_BRANCH"
  git config user.name "github-actions[bot]"
  git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

  if git merge --no-ff --no-edit "origin/$HEAD_BRANCH"; then
    git push origin "$DEFAULT_BRANCH"
    curl -sS \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      -X PATCH \
      "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${ISSUE_NUMBER}" \
      -d '{"state":"closed","state_reason":"completed"}' \
      >/dev/null || true
    curl -sS \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      -X POST \
      "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${ISSUE_NUMBER}/comments" \
      -d "{\"body\":\"자동 병합 완료: \`${HEAD_BRANCH}\` -> \`${DEFAULT_BRANCH}\`\\n이슈를 completed로 닫았습니다.\"}" \
      >/dev/null || true
  else
    curl -sS \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      -X POST \
      "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${ISSUE_NUMBER}/comments" \
      -d "{\"body\":\"자동 main 병합 실패: 브랜치 충돌 또는 보호 규칙으로 병합되지 않았습니다. 수동 병합이 필요합니다.\"}" \
      >/dev/null || true
    exit 1
  fi
fi

log "Syncing local checkout to ${DEFAULT_BRANCH}"
git checkout "$DEFAULT_BRANCH"
git pull --ff-only origin "$DEFAULT_BRANCH"

if [[ "$LOCAL_SYNC_REPO_PATH" != "$ROOT_DIR" ]]; then
  if [[ -d "$LOCAL_SYNC_REPO_PATH/.git" ]]; then
    log "Syncing external local repo at ${LOCAL_SYNC_REPO_PATH}"
    git -C "$LOCAL_SYNC_REPO_PATH" fetch origin "$DEFAULT_BRANCH"
    git -C "$LOCAL_SYNC_REPO_PATH" checkout "$DEFAULT_BRANCH"
    git -C "$LOCAL_SYNC_REPO_PATH" pull --ff-only origin "$DEFAULT_BRANCH"
  else
    log "Skipping external local sync (not a git repo): ${LOCAL_SYNC_REPO_PATH}"
  fi
fi

log "Done"
