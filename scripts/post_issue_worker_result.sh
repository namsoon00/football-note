#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_TOKEN:?Missing GITHUB_TOKEN}"
: "${GITHUB_REPOSITORY:?Missing GITHUB_REPOSITORY}"

RESULT_FILE="${ISSUE_WORKER_RESULT_FILE:-}"
WORKFLOW_URL="${ISSUE_WORKER_WORKFLOW_URL:-}"

if [[ -z "${RESULT_FILE}" || ! -f "${RESULT_FILE}" ]]; then
  echo "[post-issue-worker-result] No result file found. Skipping."
  exit 0
fi

read_result_field() {
  local field="${1:-}"
  python3 - <<'PY' "${RESULT_FILE}" "${field}"
import json
import pathlib
import sys

path, field = sys.argv[1:3]
payload = {}
file_path = pathlib.Path(path)
if file_path.exists():
    try:
        payload = json.loads(file_path.read_text(encoding="utf-8"))
    except Exception:
        payload = {}
value = payload.get(field, "")
if isinstance(value, bool):
    print("true" if value else "false")
else:
    print(str(value).strip())
PY
}

write_posted_flag() {
  python3 - <<'PY' "${RESULT_FILE}"
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
payload = {}
if path.exists():
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        payload = {}
payload["final_comment_posted"] = True
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(
    json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
    encoding="utf-8",
)
PY
}

ISSUE_NUMBER="$(read_result_field "issue_number")"
if [[ -z "${ISSUE_NUMBER}" ]]; then
  echo "[post-issue-worker-result] No issue number in result file. Skipping."
  exit 0
fi

FINAL_COMMENT_POSTED="$(read_result_field "final_comment_posted")"
if [[ "${FINAL_COMMENT_POSTED}" == "true" || "${FINAL_COMMENT_POSTED}" == "1" ]]; then
  echo "[post-issue-worker-result] Final issue comment already posted. Skipping."
  exit 0
fi

COMMENT_BODY="$(read_result_field "comment_body")"
if [[ -z "${COMMENT_BODY}" ]]; then
  STATUS="$(read_result_field "status")"
  ISSUE_TITLE="$(read_result_field "issue_title")"
  ISSUE_URL="$(read_result_field "issue_url")"
  PR_URL="$(read_result_field "pr_url")"
  MAIN_SHA="$(read_result_field "main_sha")"
  NOTE="$(read_result_field "note")"

  COMMENT_BODY="$(
    python3 - <<'PY' \
"${ISSUE_NUMBER}" \
"${ISSUE_TITLE}" \
"${ISSUE_URL}" \
"${STATUS}" \
"${PR_URL}" \
"${MAIN_SHA}" \
"${NOTE}" \
"${WORKFLOW_URL}"
import sys

issue_number, issue_title, issue_url, status, pr_url, main_sha, note, workflow_url = sys.argv[1:9]

lines = [
    "## 자동 워커 실행 결과",
    f"- 상태: {status or '결과 확인 필요'}",
    f"- Issue: #{issue_number}",
]
if issue_title:
    lines.append(f"- 제목: {issue_title}")
if issue_url:
    lines.append(f"- 링크: {issue_url}")
if pr_url:
    lines.append(f"- PR: {pr_url}")
if main_sha:
    lines.append(f"- main 반영 커밋: `{main_sha}`")
if workflow_url:
    lines.append(f"- 워크플로: {workflow_url}")
if note:
    lines.append(f"- 메모: {note}")

print("\n".join(lines).strip())
PY
  )"
fi

if [[ -z "${COMMENT_BODY}" ]]; then
  echo "[post-issue-worker-result] Empty comment body. Skipping."
  exit 0
fi

PAYLOAD="$(
  python3 - <<'PY' "${COMMENT_BODY}"
import json
import sys

print(json.dumps({"body": sys.argv[1]}, ensure_ascii=False))
PY
)"

curl -sS \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  -X POST \
  "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${ISSUE_NUMBER}/comments" \
  -d "${PAYLOAD}" \
  >/dev/null

write_posted_flag
echo "[post-issue-worker-result] Comment posted to issue #${ISSUE_NUMBER}."
