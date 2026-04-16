#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

LOCK_DIR="/tmp/football_note_issue_worker.lock"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  echo "[issue-worker] Another run is active. Exiting."
  ISSUE_QUEUE_FILE="$ROOT_DIR/docs/ISSUE_QUEUE.md"
  ISSUE_NUMBER_LOCK="$(
    (
      grep -Eo '#[0-9]+' "$ISSUE_QUEUE_FILE" 2>/dev/null || true
    ) | head -n1 | tr -d '#'
  )"
  if [[ -n "${ISSUE_NUMBER_LOCK:-}" && -n "${GITHUB_REPOSITORY:-}" && -n "${GITHUB_TOKEN:-}" ]]; then
    curl -sS \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      -X POST \
      "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${ISSUE_NUMBER_LOCK}/comments" \
      -d "{\"body\":\"자동 워커가 이미 실행 중이라 이번 수동 실행은 건너뛰었습니다. 잠시 후 다시 실행해 주세요.\"}" \
      >/dev/null || true
  fi
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
CODEX_MODEL="gpt-5.4"
CODEX_REASONING_EFFORT="xhigh"
FORCE_MAIN_MERGE="${FORCE_MAIN_MERGE:-1}"
LOCAL_SYNC_REPO_PATH="${LOCAL_SYNC_REPO_PATH:-/Users/namsoon00/Devel/football_note/football_note}"
ISSUE_NUMBER=""
LINKED_DISCUSSION_URL=""

log() {
  echo "[issue-worker] $*"
}

json_body_payload() {
  python3 - <<'PY' "${1:-}"
import json
import sys

print(json.dumps({"body": sys.argv[1]}, ensure_ascii=False))
PY
}

extract_discussion_url_from_text() {
  python3 - <<'PY' "${1:-}" "${GITHUB_REPOSITORY}"
import re
import sys

text = sys.argv[1]
repo = sys.argv[2]

match = re.search(r"https://github\.com/[^/\s]+/[^/\s]+/discussions/[0-9]+", text, re.IGNORECASE)
if match:
    print(match.group(0))
    raise SystemExit(0)

match = re.search(r"(?:discussion|discussions|논의)\s*#?\s*([0-9]+)", text, re.IGNORECASE)
if match and repo:
    print(f"https://github.com/{repo}/discussions/{match.group(1)}")
PY
}

find_linked_discussion_url() {
  local text_url comments_json

  text_url="$(
    extract_discussion_url_from_text "$(printf '%s\n%s' "${ISSUE_TITLE:-}" "${ISSUE_BODY:-}")"
  )"
  if [[ -n "${text_url}" ]]; then
    echo "${text_url}"
    return 0
  fi

  comments_json="$(
    curl -sS \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${ISSUE_NUMBER}/comments?per_page=100"
  )"

  python3 - <<'PY' "${comments_json}" "${GITHUB_REPOSITORY}"
import json
import re
import sys

raw, repo = sys.argv[1:3]

def extract(text: str) -> str:
    match = re.search(r"https://github\.com/[^/\s]+/[^/\s]+/discussions/[0-9]+", text, re.IGNORECASE)
    if match:
        return match.group(0)
    match = re.search(r"(?:discussion|discussions|논의)\s*#?\s*([0-9]+)", text, re.IGNORECASE)
    if match and repo:
        return f"https://github.com/{repo}/discussions/{match.group(1)}"
    return ""

try:
    comments = json.loads(raw)
except Exception:
    print("")
    raise SystemExit(0)

if isinstance(comments, list):
    for item in comments:
        url = extract(str((item or {}).get("body", "")))
        if url:
            print(url)
            raise SystemExit(0)

print("")
PY
}

post_issue_comment() {
  local message="${1:-}" payload
  if [[ -z "$message" || -z "${ISSUE_NUMBER:-}" ]]; then
    return 0
  fi
  payload="$(json_body_payload "$message")"
  curl -sS \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -X POST \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${ISSUE_NUMBER}/comments" \
    -d "${payload}" \
    >/dev/null || true
}

post_linked_discussion_comment() {
  local message="${1:-}" body_file discussion_target

  if [[ -z "$message" || -z "${LINKED_DISCUSSION_URL:-}" ]]; then
    return 0
  fi

  body_file="$(mktemp "${TMP_BASE}/discussion-comment.XXXXXX")"
  python3 - <<'PY' "${body_file}" "${ISSUE_NUMBER:-}" "${ISSUE_TITLE:-}" "${ISSUE_URL:-}" "${message}"
import pathlib
import sys

body_path, issue_number, issue_title, issue_url, message = sys.argv[1:6]
body = f"""## 자동 워커 업데이트
- Issue: #{issue_number}
- 제목: {issue_title}
- 링크: {issue_url}

{message}
"""
pathlib.Path(body_path).write_text(body, encoding="utf-8")
PY

  if discussion_target="$(
    scripts/post_discussion.sh \
      --discussion-url "${LINKED_DISCUSSION_URL}" \
      --body-file "${body_file}"
  )"; then
    LINKED_DISCUSSION_URL="${discussion_target}"
    return 0
  fi

  log "Failed to post discussion comment to ${LINKED_DISCUSSION_URL}."
  return 1
}

notify_issue_and_discussion() {
  local message="${1:-}"
  if [[ -z "${message}" ]]; then
    return 0
  fi
  post_issue_comment "${message}"
  post_linked_discussion_comment "${message}" || true
}

is_plan_request_issue() {
  local haystack
  haystack="$(printf '%s\n%s' "${ISSUE_TITLE:-}" "${ISSUE_BODY:-}" | tr '[:upper:]' '[:lower:]')"
  if grep -Eiq '계획|플랜|기획|논의|discussion|plan' <<<"$haystack"; then
    return 0
  fi
  return 1
}

create_plan_discussion() {
  local title body_file discussion_target

  title="$(
    python3 - <<'PY' "${ISSUE_NUMBER}" "${ISSUE_TITLE}"
import sys

issue_number, issue_title = sys.argv[1:3]
print(f"[계획] Issue #{issue_number} - {issue_title}")
PY
  )"

  body_file="$(mktemp "${TMP_BASE}/plan-discussion.XXXXXX")"
  python3 - <<'PY' "${body_file}" "${ISSUE_NUMBER}" "${ISSUE_TITLE}" "${ISSUE_URL}" "${ISSUE_BODY}"
import pathlib
import sys

body_path, issue_number, issue_title, issue_url, issue_body = sys.argv[1:6]
trimmed_body = (issue_body or "").strip()
if len(trimmed_body) > 1200:
    trimmed_body = trimmed_body[:1200].rstrip() + "\n..."
body = f"""## 이슈 정보
- Issue: #{issue_number}
- 제목: {issue_title}
- 링크: {issue_url}

## 요청 요약
{trimmed_body if trimmed_body else '(본문 없음)'}

## 작업 계획(초안)
1. 문제/요구사항 범위 확정
2. 영향받는 화면/로직 식별
3. 최소 변경안과 대안 비교
4. 구현 순서/검증 방법 확정
5. 리스크와 롤백 포인트 정리

자동 워커가 생성한 계획 Discussion입니다. 필요하면 여기서 바로 피드백 주세요.
"""
pathlib.Path(body_path).write_text(body, encoding="utf-8")
PY

  if [[ -n "${LINKED_DISCUSSION_URL:-}" ]]; then
    if discussion_target="$(
      scripts/post_discussion.sh \
        --discussion-url "${LINKED_DISCUSSION_URL}" \
        --body-file "${body_file}"
    )"; then
      LINKED_DISCUSSION_URL="${discussion_target}"
      post_issue_comment "요청하신 계획을 연결된 Discussion에 남겼습니다: ${discussion_target}"
      log "Plan discussion comment posted: ${discussion_target}"
      return 0
    fi
    log "Failed to comment on linked discussion ${LINKED_DISCUSSION_URL}; creating a new discussion."
  fi

  if discussion_target="$(
    scripts/post_discussion.sh \
      --title "${title}" \
      --body-file "${body_file}" \
      --repo "${GITHUB_REPOSITORY}"
  )"; then
    LINKED_DISCUSSION_URL="${discussion_target}"
    post_issue_comment "요청하신 계획을 Discussion에 남겼습니다: ${discussion_target}"
    log "Plan discussion created: ${discussion_target}"
    return 0
  fi

  log "Failed to create discussion."
  return 1
}

issue_state() {
  curl -sS \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${ISSUE_NUMBER}" \
    | python3 -c 'import json,sys; print(json.loads(sys.stdin.read()).get("state",""))'
}

close_issue_completed() {
  local message="${1:-자동 머지 반영으로 이슈를 completed로 닫았습니다.}"
  curl -sS \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -X PATCH \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${ISSUE_NUMBER}" \
    -d '{"state":"closed","state_reason":"completed"}' \
    >/dev/null || true
  notify_issue_and_discussion "${message}"
}

ensure_issue_closed_if_merged() {
  log "Verifying merge status for ${HEAD_BRANCH} -> ${DEFAULT_BRANCH}"
  git fetch origin "$DEFAULT_BRANCH" "$HEAD_BRANCH" >/dev/null 2>&1 || true

  local merged="0"
  if git show-ref --verify --quiet "refs/remotes/origin/${HEAD_BRANCH}" && \
     git merge-base --is-ancestor "origin/$HEAD_BRANCH" "origin/$DEFAULT_BRANCH"; then
    merged="1"
  else
    # Remote branch may be auto-deleted after PR merge.
    local pr_merged_at
    pr_merged_at="$(
      curl -sS \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls?state=closed&head=${GITHUB_REPOSITORY%%/*}:${HEAD_BRANCH}&base=${DEFAULT_BRANCH}&per_page=1" \
      | python3 -c 'import json,sys; d=json.load(sys.stdin); print((d[0].get("merged_at","") if isinstance(d,list) and d else ""))'
    )"
    if [[ -n "${pr_merged_at}" ]]; then
      log "Detected merged PR for ${HEAD_BRANCH} (merged_at=${pr_merged_at})."
      merged="1"
    fi
  fi

  if [[ "$merged" == "1" ]]; then
    local state
    state="$(issue_state)"
    if [[ "$state" == "open" ]]; then
      log "Issue #${ISSUE_NUMBER} is still open after merge; closing explicitly."
      close_issue_completed "main 반영 완료를 확인하여 이슈를 자동 종료했습니다."
    else
      log "Issue #${ISSUE_NUMBER} already closed."
    fi
  else
    log "HEAD branch is not merged into ${DEFAULT_BRANCH}; issue remains open."
  fi
}

# Some self-hosted macOS runners deny /tmp fallback paths used by xcrun/git.
TMP_BASE="$ROOT_DIR/.tmp"
mkdir -p "$TMP_BASE"
export TMPDIR="$TMP_BASE"

cleanup_tmp_artifacts() {
  # Keep repo-local TMPDIR, but ignore transient files from toolchains.
  if [[ -d "$TMP_BASE" ]]; then
    find "$TMP_BASE" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
  fi
}

log "Syncing repository"
git fetch origin "$DEFAULT_BRANCH"
git checkout "$DEFAULT_BRANCH"
git pull --ff-only origin "$DEFAULT_BRANCH"

log "Refreshing queue file"
python3 scripts/sync_issue_queue.py || true

if [[ ! -f "docs/ISSUE_QUEUE.md" ]]; then
  log "Queue file not found. Exiting."
  post_issue_comment "자동 워커 종료: \`docs/ISSUE_QUEUE.md\` 파일이 없어 작업 대상을 찾지 못했습니다."
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
  post_issue_comment "자동 워커 종료: 이슈가 open 상태가 아니어서 작업을 중단했습니다."
  exit 0
fi

ISSUE_TITLE="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read()).get("title","").strip())' <<< "$ISSUE_JSON")"
ISSUE_BODY="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read()).get("body","").strip())' <<< "$ISSUE_JSON")"
ISSUE_URL="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read()).get("html_url",""))' <<< "$ISSUE_JSON")"
LINKED_DISCUSSION_URL="$(find_linked_discussion_url)"
if [[ -n "${LINKED_DISCUSSION_URL}" ]]; then
  log "Linked discussion detected: ${LINKED_DISCUSSION_URL}"
fi

if is_plan_request_issue; then
  log "Plan request detected for issue #${ISSUE_NUMBER}."
  if create_plan_discussion; then
    log "Plan discussion flow completed."
    exit 0
  fi
  notify_issue_and_discussion "계획 요청을 감지했지만 Discussion 생성에 실패했습니다. 저장소 Discussions 활성화/권한을 확인해 주세요."
fi

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
  CODEX_PROMPT_FILE="$PROMPT_FILE" \
  CODEX_MODEL="$CODEX_MODEL" \
  CODEX_REASONING_EFFORT="$CODEX_REASONING_EFFORT" \
  OPENAI_REASONING_EFFORT="$CODEX_REASONING_EFFORT" \
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
  log "Running codex CLI (model=$CODEX_MODEL, effort=$CODEX_REASONING_EFFORT, sandbox=$CODEX_SANDBOX, approval=$CODEX_APPROVAL, unsafe=$CODEX_UNSAFE)"
  if codex exec --help >/dev/null 2>&1; then
    if [[ "$CODEX_UNSAFE" == "1" ]]; then
      codex -C "$ROOT_DIR" \
        -m "$CODEX_MODEL" \
        -c "model_reasoning_effort=\"${CODEX_REASONING_EFFORT}\"" \
        --dangerously-bypass-approvals-and-sandbox \
        exec "$(cat "$PROMPT_FILE")"
      CODEX_EXIT=$?
    else
      codex -C "$ROOT_DIR" \
        -m "$CODEX_MODEL" \
        -c "model_reasoning_effort=\"${CODEX_REASONING_EFFORT}\"" \
        --sandbox "$CODEX_SANDBOX" \
        --ask-for-approval "$CODEX_APPROVAL" \
        exec "$(cat "$PROMPT_FILE")"
      CODEX_EXIT=$?
    fi
  else
    if [[ "$CODEX_UNSAFE" == "1" ]]; then
      codex -C "$ROOT_DIR" \
        -m "$CODEX_MODEL" \
        -c "model_reasoning_effort=\"${CODEX_REASONING_EFFORT}\"" \
        --dangerously-bypass-approvals-and-sandbox \
        "$(cat "$PROMPT_FILE")"
      CODEX_EXIT=$?
    else
      codex -C "$ROOT_DIR" \
        -m "$CODEX_MODEL" \
        -c "model_reasoning_effort=\"${CODEX_REASONING_EFFORT}\"" \
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
cleanup_tmp_artifacts
HAS_WORKTREE_CHANGES=1
if \
  git diff --quiet && \
  git diff --cached --quiet && \
  [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
  HAS_WORKTREE_CHANGES=0
  if [[ "$AHEAD_COUNT" == "0" ]]; then
    log "No changes produced by Codex and no pending commits on ${HEAD_BRANCH}."
    notify_issue_and_discussion "자동 작업이 실행됐지만 코드 변경이 없어 종료했습니다. (이미 반영되었거나 추가 수정이 필요합니다)"
    exit 0
  fi
  log "No local changes, but branch is ${AHEAD_COUNT} commit(s) ahead of ${DEFAULT_BRANCH}. Continuing."
fi

if [[ "$CODEX_EXIT" != "0" ]]; then
  if [[ "$HAS_WORKTREE_CHANGES" == "0" && "$AHEAD_COUNT" != "0" ]]; then
    log "Codex exited non-zero, but branch already has ${AHEAD_COUNT} commit(s) to merge. Continuing."
    notify_issue_and_discussion "자동 워커 경고: Codex 실행은 비정상 종료(${CODEX_EXIT})했지만, 브랜치에 기존 커밋이 있어 병합 절차를 계속 진행했습니다."
  else
    log "Failing run because Codex exited non-zero and there are pending changes/commits to inspect."
    notify_issue_and_discussion "자동 워커 실패: Codex 실행이 비정상 종료(${CODEX_EXIT})했고 변경사항 검증이 필요해 중단했습니다."
    exit "$CODEX_EXIT"
  fi
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
    close_issue_completed "$(printf '자동 병합 완료: `%s` -> `%s`\n이슈를 completed로 닫았습니다.' "${HEAD_BRANCH}" "${DEFAULT_BRANCH}")"
  else
    notify_issue_and_discussion "자동 main 병합 실패: 브랜치 충돌 또는 보호 규칙으로 병합되지 않았습니다. 수동 병합이 필요합니다."
    exit 1
  fi
fi

ensure_issue_closed_if_merged

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
