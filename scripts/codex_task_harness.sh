#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/codex_task_harness.sh [options]

Options:
  --source <local|issue>      Task source label (default: local)
  --title <text>              Task title
  --body <text>               Task body
  --body-file <path>          Read task body from file
  --issue-number <number>     GitHub issue number
  --issue-url <url>           GitHub issue URL
  --head-branch <name>        Working branch name
  --base-branch <name>        Base branch name (default: main)
  --context-path <path>       Add an explicit related path (repeatable)
  --run-verify <0|1>          Run verification after Codex execution
  --verify-command <cmd>      Verification command (default: ./scripts/verify.sh)
  --repair-attempts <count>   Verify-repair retries after the first attempt
  --print-prompt-only         Build prompt/context and exit without running Codex
  -h, --help                  Show this help
EOF
}

log() {
  echo "[harness] $*"
}

sanitize_reasoning_effort() {
  local raw="${1:-${CODEX_REASONING_EFFORT:-${OPENAI_REASONING_EFFORT:-high}}}"
  case "${raw}" in
    minimal|low|medium|high)
      echo "${raw}"
      ;;
    xhigh)
      echo "high"
      ;;
    xmedium)
      echo "medium"
      ;;
    xlow)
      echo "low"
      ;;
    *)
      echo "high"
      ;;
  esac
}

append_unique_line() {
  local target_file="$1"
  local value="$2"
  if [[ -z "${value}" ]]; then
    return 0
  fi
  if [[ ! -f "${target_file}" ]] || ! grep -Fxq "${value}" "${target_file}"; then
    printf '%s\n' "${value}" >> "${target_file}"
  fi
}

trim_text_file() {
  local input_file="$1"
  local line_limit="$2"
  local char_limit="$3"
  python3 - "$input_file" "$line_limit" "$char_limit" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
line_limit = int(sys.argv[2])
char_limit = int(sys.argv[3])
if not path.exists():
    print("")
    raise SystemExit(0)

lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
snippet = "\n".join(lines[-line_limit:])
if len(snippet) > char_limit:
    snippet = snippet[-char_limit:]
print(snippet)
PY
}

TASK_SOURCE="${TASK_SOURCE:-local}"
TASK_TITLE="${TASK_TITLE:-}"
TASK_BODY="${TASK_BODY:-}"
TASK_BODY_FILE=""
ISSUE_NUMBER="${ISSUE_NUMBER:-}"
ISSUE_URL="${ISSUE_URL:-}"
HEAD_BRANCH="${HEAD_BRANCH:-}"
BASE_BRANCH="${BASE_BRANCH:-main}"
RUN_VERIFY="${HARNESS_RUN_VERIFY:-0}"
VERIFY_COMMAND="${HARNESS_VERIFY_COMMAND:-./scripts/verify.sh}"
REPAIR_ATTEMPTS="${HARNESS_REPAIR_ATTEMPTS:-1}"
PRINT_PROMPT_ONLY=0

CONTEXT_PATHS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      shift
      TASK_SOURCE="${1:-}"
      ;;
    --title)
      shift
      TASK_TITLE="${1:-}"
      ;;
    --body)
      shift
      TASK_BODY="${1:-}"
      ;;
    --body-file)
      shift
      TASK_BODY_FILE="${1:-}"
      ;;
    --issue-number)
      shift
      ISSUE_NUMBER="${1:-}"
      ;;
    --issue-url)
      shift
      ISSUE_URL="${1:-}"
      ;;
    --head-branch)
      shift
      HEAD_BRANCH="${1:-}"
      ;;
    --base-branch)
      shift
      BASE_BRANCH="${1:-}"
      ;;
    --context-path)
      shift
      CONTEXT_PATHS+=("${1:-}")
      ;;
    --run-verify)
      shift
      RUN_VERIFY="${1:-}"
      ;;
    --verify-command)
      shift
      VERIFY_COMMAND="${1:-}"
      ;;
    --repair-attempts)
      shift
      REPAIR_ATTEMPTS="${1:-}"
      ;;
    --print-prompt-only)
      PRINT_PROMPT_ONLY=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift || true
done

if [[ -n "${TASK_BODY_FILE}" ]]; then
  if [[ ! -f "${TASK_BODY_FILE}" ]]; then
    echo "Task body file not found: ${TASK_BODY_FILE}" >&2
    exit 1
  fi
  TASK_BODY="$(cat "${TASK_BODY_FILE}")"
fi

if [[ -z "${TASK_TITLE}" ]]; then
  if [[ -n "${ISSUE_NUMBER}" ]]; then
    TASK_TITLE="Implement issue #${ISSUE_NUMBER}"
  else
    TASK_TITLE="Local Codex task"
  fi
fi

TMP_DIR="${HARNESS_TMP_DIR:-$ROOT_DIR/.tmp/codex_harness}"
mkdir -p "${TMP_DIR}"
RUN_STAMP="$(date +%Y%m%d-%H%M%S)-$$"
PROMPT_FILE="${TMP_DIR}/task_${RUN_STAMP}.prompt"
CONTEXT_PATH_FILE="${TMP_DIR}/context_paths_${RUN_STAMP}.txt"
KEYWORD_FILE="${TMP_DIR}/context_keywords_${RUN_STAMP}.txt"
CONTEXT_FILE="${TMP_DIR}/context_${RUN_STAMP}.txt"
VERIFY_LOG_FILE="${TMP_DIR}/verify_${RUN_STAMP}.log"

: > "${CONTEXT_PATH_FILE}"
: > "${KEYWORD_FILE}"

if (( ${#CONTEXT_PATHS[@]} > 0 )); then
  for context_path in "${CONTEXT_PATHS[@]}"; do
    if [[ -e "${context_path}" ]]; then
      append_unique_line "${CONTEXT_PATH_FILE}" "${context_path}"
    elif [[ -e "${ROOT_DIR}/${context_path}" ]]; then
      append_unique_line "${CONTEXT_PATH_FILE}" "${context_path}"
    fi
  done
fi

python3 - "${ROOT_DIR}" "${TASK_TITLE}" "${TASK_BODY}" > "${TMP_DIR}/detected_context_${RUN_STAMP}.json" <<'PY'
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
title = sys.argv[2]
body = sys.argv[3]
text = "\n".join(part for part in (title, body) if part)

path_candidates = []
patterns = [
    r"`([^`]+)`",
    r"(?<![A-Za-z0-9_])((?:lib|test|scripts|docs|assets|\.github|fastlane|ios|android|web)/[A-Za-z0-9_./-]+)",
    r"(?<![A-Za-z0-9_])([A-Za-z0-9_./-]+\.(?:dart|sh|md|yml|yaml|json|arb|txt))",
]

for pattern in patterns:
    for match in re.findall(pattern, text):
        candidate = match.strip()
        if not candidate:
            continue
        candidate_path = root / candidate
        if candidate_path.exists():
            path_candidates.append(candidate)

stop_words = {
    "the", "and", "with", "from", "that", "this", "into", "when", "then",
    "make", "keep", "after", "before", "issue", "local", "codex", "task",
    "main", "flow", "merge", "push", "verify", "using", "used", "both",
    "cli", "worker", "harness", "build", "run", "runs", "path", "paths",
    "script", "scripts", "repo", "branch", "changes", "change", "support",
}
keywords = []
seen = set()
for raw in re.findall(r"[A-Za-z][A-Za-z0-9_/-]{2,}", text.lower()):
    word = raw.strip("/-")
    if word in stop_words or word in seen:
        continue
    seen.add(word)
    keywords.append(word)
    if len(keywords) >= 8:
        break

print(json.dumps({"paths": path_candidates, "keywords": keywords}, ensure_ascii=False))
PY

while IFS= read -r detected_path; do
  append_unique_line "${CONTEXT_PATH_FILE}" "${detected_path}"
done < <(python3 - "${TMP_DIR}/detected_context_${RUN_STAMP}.json" <<'PY'
import json
import pathlib
import sys

data = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
for item in data.get("paths", []):
    print(item)
PY
)

while IFS= read -r keyword; do
  append_unique_line "${KEYWORD_FILE}" "${keyword}"
done < <(python3 - "${TMP_DIR}/detected_context_${RUN_STAMP}.json" <<'PY'
import json
import pathlib
import sys

data = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
for item in data.get("keywords", []):
    print(item)
PY
)

while IFS= read -r keyword; do
  [[ -z "${keyword}" ]] && continue
  while IFS= read -r match_path; do
    append_unique_line "${CONTEXT_PATH_FILE}" "${match_path}"
  done < <(rg -l -F "${keyword}" lib test scripts docs .github 2>/dev/null | head -n 4)
done < "${KEYWORD_FILE}"

python3 - "${CONTEXT_PATH_FILE}" <<'PY' > "${CONTEXT_PATH_FILE}.trimmed"
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
items = []
if path.exists():
    items = [line.strip() for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
for item in items[:10]:
    print(item)
PY
mv "${CONTEXT_PATH_FILE}.trimmed" "${CONTEXT_PATH_FILE}"

{
  echo "Suggested related paths:"
  if [[ -s "${CONTEXT_PATH_FILE}" ]]; then
    sed 's#^#- #' "${CONTEXT_PATH_FILE}"
  else
    echo "- lib/"
    echo "- test/"
    echo "- scripts/"
  fi
  echo
  echo "Keyword search hints:"
  if [[ -s "${KEYWORD_FILE}" ]]; then
    sed 's#^#- #' "${KEYWORD_FILE}"
  else
    echo "- No strong keywords detected from the task text."
  fi
  echo
  echo "Recent keyword hits:"
  if [[ -s "${KEYWORD_FILE}" ]]; then
    while IFS= read -r keyword; do
      [[ -z "${keyword}" ]] && continue
      hits="$(rg -n -F "${keyword}" lib test scripts docs .github 2>/dev/null | head -n 2 || true)"
      if [[ -n "${hits}" ]]; then
        echo "- ${keyword}"
        printf '%s\n' "${hits}" | sed 's#^#  #'
      fi
    done < "${KEYWORD_FILE}"
  else
    echo "- No keyword hits collected."
  fi
} > "${CONTEXT_FILE}"

REPO_NAME="${GITHUB_REPOSITORY:-$(basename "$(git rev-parse --show-toplevel 2>/dev/null || printf '%s' "${ROOT_DIR}")")}"

cat > "${PROMPT_FILE}" <<EOF
You are working in repository ${REPO_NAME}.

Task metadata:
- Source: ${TASK_SOURCE}
- Title: ${TASK_TITLE}
- Base branch: ${BASE_BRANCH}
- Head branch: ${HEAD_BRANCH:-"(not provided)"}
EOF

if [[ -n "${ISSUE_NUMBER}" ]]; then
  cat >> "${PROMPT_FILE}" <<EOF
- Issue: #${ISSUE_NUMBER}
EOF
fi

if [[ -n "${ISSUE_URL}" ]]; then
  cat >> "${PROMPT_FILE}" <<EOF
- URL: ${ISSUE_URL}
EOF
fi

cat >> "${PROMPT_FILE}" <<EOF

Task body:
${TASK_BODY:-"(no additional body provided)"}

Execution stages:
1. Inspect the repository before editing. Use rg to confirm existing patterns and search for related files.
2. Narrow the impact. Keep unrelated code and behavior unchanged unless the task explicitly requires it.
3. Implement the smallest defensible change.
4. Update or add tests for the changed behavior. Prefer focused tests near the touched feature.
5. For user-visible Flutter copy, update lib/l10n/*.arb and use generated localization classes instead of hardcoded strings.
6. Run verification and fix any failures before finishing.
7. Summarize changed files, verification status, and any residual risk.

Acceptance checklist:
- The request is satisfied without unrelated refactors.
- Localized UI text uses lib/l10n/*.arb and generated localization accessors.
- Tests were updated when behavior changed.
- Verification command passes: ${VERIFY_COMMAND}

Suggested context:
$(cat "${CONTEXT_FILE}")
EOF

export CODEX_PROMPT_FILE="${PROMPT_FILE}"
export HARNESS_PROMPT_FILE="${PROMPT_FILE}"
export HARNESS_CONTEXT_FILE="${CONTEXT_FILE}"
export HARNESS_VERIFY_LOG_FILE="${VERIFY_LOG_FILE}"

if [[ "${PRINT_PROMPT_ONLY}" == "1" ]]; then
  log "Prompt generated at ${PROMPT_FILE}"
  cat "${PROMPT_FILE}"
  exit 0
fi

run_codex_prompt() {
  local prompt_file="$1"
  local prompt_text exit_code reasoning_effort

  reasoning_effort="$(sanitize_reasoning_effort)"
  if [[ "${reasoning_effort}" != "${CODEX_REASONING_EFFORT:-${OPENAI_REASONING_EFFORT:-}}" ]]; then
    log "Normalizing model_reasoning_effort to ${reasoning_effort}"
  fi

  if [[ "${USE_CUSTOM_CODEX_CMD:-0}" == "1" && -n "${CODEX_RUNNER_CMD:-}" ]]; then
    log "Running custom Codex command"
    CODEX_PROMPT_FILE="${prompt_file}" \
      CODEX_REASONING_EFFORT="${reasoning_effort}" \
      OPENAI_REASONING_EFFORT="${reasoning_effort}" \
      bash -lc "cd \"$ROOT_DIR\" && ${CODEX_RUNNER_CMD}"
    return $?
  fi

  if [[ -n "${CODEX_RUNNER_CMD:-}" ]]; then
    log "Ignoring CODEX_RUNNER_CMD because USE_CUSTOM_CODEX_CMD!=1"
  fi

  if ! command -v codex >/dev/null 2>&1; then
    echo "codex CLI not found. Set CODEX_RUNNER_CMD or install codex." >&2
    return 127
  fi

  prompt_text="$(cat "${prompt_file}")"
  log "Running codex CLI (model=${CODEX_MODEL:-gpt-5}, sandbox=${CODEX_SANDBOX:-workspace-write}, approval=${CODEX_APPROVAL:-never}, unsafe=${CODEX_UNSAFE:-1})"

  if codex exec --help >/dev/null 2>&1; then
    if [[ "${CODEX_UNSAFE:-1}" == "1" ]]; then
      codex -C "${ROOT_DIR}" \
        -m "${CODEX_MODEL:-gpt-5}" \
        -c "model_reasoning_effort=\"${reasoning_effort}\"" \
        --dangerously-bypass-approvals-and-sandbox \
        exec "${prompt_text}"
      exit_code=$?
    else
      codex -C "${ROOT_DIR}" \
        -m "${CODEX_MODEL:-gpt-5}" \
        -c "model_reasoning_effort=\"${reasoning_effort}\"" \
        --sandbox "${CODEX_SANDBOX:-workspace-write}" \
        --ask-for-approval "${CODEX_APPROVAL:-never}" \
        exec "${prompt_text}"
      exit_code=$?
    fi
  else
    if [[ "${CODEX_UNSAFE:-1}" == "1" ]]; then
      codex -C "${ROOT_DIR}" \
        -m "${CODEX_MODEL:-gpt-5}" \
        -c "model_reasoning_effort=\"${reasoning_effort}\"" \
        --dangerously-bypass-approvals-and-sandbox \
        "${prompt_text}"
      exit_code=$?
    else
      codex -C "${ROOT_DIR}" \
        -m "${CODEX_MODEL:-gpt-5}" \
        -c "model_reasoning_effort=\"${reasoning_effort}\"" \
        --sandbox "${CODEX_SANDBOX:-workspace-write}" \
        --ask-for-approval "${CODEX_APPROVAL:-never}" \
        "${prompt_text}"
      exit_code=$?
    fi
  fi

  return "${exit_code}"
}

run_verify() {
  local verify_command="$1"
  local log_file="$2"

  if [[ "${RUN_VERIFY}" != "1" ]]; then
    return 0
  fi

  log "Running verification: ${verify_command}"
  if bash -lc "cd \"$ROOT_DIR\" && ${verify_command}" 2>&1 | tee "${log_file}"; then
    return 0
  fi
  return 1
}

build_repair_prompt() {
  local repair_prompt_file="$1"
  local attempt_number="$2"
  local verify_excerpt

  verify_excerpt="$(trim_text_file "${VERIFY_LOG_FILE}" 160 14000)"

  cat > "${repair_prompt_file}" <<EOF
You are repairing a partially completed Codex task in repository ${REPO_NAME}.

Original prompt:
$(cat "${PROMPT_FILE}")

Repair attempt: ${attempt_number}
Verification command that failed:
${VERIFY_COMMAND}

Failure log excerpt:
${verify_excerpt:-"(verification log was empty)"}

Repair instructions:
1. Fix only the issues required to make verification pass while preserving the original task intent.
2. Re-check nearby tests, localization, and script behavior affected by your edits.
3. Do not revert unrelated user changes.
4. After edits, assume the same verification command will be run again.
EOF
}

if ! run_codex_prompt "${PROMPT_FILE}"; then
  exit $?
fi

if [[ "${RUN_VERIFY}" == "1" ]]; then
  attempt=0
  until run_verify "${VERIFY_COMMAND}" "${VERIFY_LOG_FILE}"; do
    if (( attempt >= REPAIR_ATTEMPTS )); then
      log "Verification failed after $((attempt + 1)) attempt(s)"
      exit 20
    fi
    attempt=$((attempt + 1))
    repair_prompt_file="${TMP_DIR}/repair_${RUN_STAMP}_${attempt}.prompt"
    build_repair_prompt "${repair_prompt_file}" "${attempt}"
    if ! run_codex_prompt "${repair_prompt_file}"; then
      exit $?
    fi
  done
fi

log "Harness completed successfully"
