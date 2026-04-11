#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

usage() {
  cat <<'EOF'
Chat task flow:
  - normalize a chat-style request
  - derive harness title and default commit message
  - run coding agent through the shared harness
  - verify, merge to main, and push

Usage:
  ./scripts/chat_task.sh --request "<task request>" [-m "<commit message>"] [--issue <number>] [-b <branch>]
  ./scripts/chat_task.sh --request-file task.md [-m "<commit message>"] [--issue <number>] [-b <branch>]
  printf '<task request>\n' | ./scripts/chat_task.sh [-m "<commit message>"] [--issue <number>] [-b <branch>]

Options:
  --request <text>                Task request text
  --request-file <path>           Read task request from file
  -m, --message <text>            Commit message override
  --issue <number>                GitHub issue number
  --issue-url <url>               GitHub issue URL
  -b, --branch <name>             Work branch name
  --context-path <path>           Extra context path for the shared harness (repeatable)
  --no-harness-verify             Skip harness-side verify/repair loop
  --harness-verify-command <cmd>  Harness verification command override
  --repair-attempts <count>       Harness repair retries
  --print-only                    Print the derived title/message and exit
  -h, --help                      Show this help
EOF
}

read_request_file() {
  local path="$1"
  if [[ ! -f "${path}" ]]; then
    echo "Request file not found: ${path}" >&2
    exit 1
  fi
  cat "${path}"
}

derive_title() {
  local request_text="$1"
  python3 - "$request_text" <<'PY'
import re
import sys

text = sys.argv[1]
lines = [line.strip() for line in text.splitlines() if line.strip()]
title = lines[0] if lines else "Chat task"
title = re.sub(r"^[#*\-\d.\s]+", "", title).strip()
if len(title) > 72:
    title = title[:72].rstrip()
print(title or "Chat task")
PY
}

derive_commit_message() {
  local title="$1"
  local issue_number="$2"
  python3 - "$title" "$issue_number" <<'PY'
import re
import sys

title = sys.argv[1].strip() or "chat task"
issue_number = sys.argv[2].strip()

summary = title.lower()
summary = re.sub(r"[^a-z0-9가-힣]+", " ", summary)
summary = " ".join(summary.split())
if not summary:
    summary = "chat task"
words = summary.split()[:6]
summary = " ".join(words)
suffix = f"(#{issue_number})" if issue_number else "(#0)"
print(f"chore: {summary} {suffix}")
PY
}

request_text=""
request_file=""
commit_message=""
issue_number=""
issue_url=""
work_branch=""
harness_run_verify="${HARNESS_RUN_VERIFY:-1}"
harness_verify_command="${HARNESS_VERIFY_COMMAND:-./scripts/verify.sh}"
harness_repair_attempts="${HARNESS_REPAIR_ATTEMPTS:-1}"
print_only=0
context_paths=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --request)
      shift
      request_text="${1:-}"
      ;;
    --request-file)
      shift
      request_file="${1:-}"
      ;;
    -m|--message)
      shift
      commit_message="${1:-}"
      ;;
    --issue)
      shift
      issue_number="${1:-}"
      ;;
    --issue-url)
      shift
      issue_url="${1:-}"
      ;;
    -b|--branch)
      shift
      work_branch="${1:-}"
      ;;
    --context-path)
      shift
      context_paths+=("${1:-}")
      ;;
    --no-harness-verify)
      harness_run_verify="0"
      ;;
    --harness-verify-command)
      shift
      harness_verify_command="${1:-}"
      ;;
    --repair-attempts)
      shift
      harness_repair_attempts="${1:-}"
      ;;
    --print-only)
      print_only=1
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

if [[ -n "${request_file}" ]]; then
  request_text="$(read_request_file "${request_file}")"
elif [[ -z "${request_text}" ]] && [[ ! -t 0 ]]; then
  request_text="$(cat)"
fi

if [[ -z "${request_text}" ]]; then
  echo "Task request is required. Use --request, --request-file, or stdin." >&2
  usage
  exit 1
fi

task_title="$(derive_title "${request_text}")"
if [[ -z "${commit_message}" ]]; then
  commit_message="$(derive_commit_message "${task_title}" "${issue_number}")"
fi

if [[ "${print_only}" == "1" ]]; then
  echo "title=${task_title}"
  echo "commit_message=${commit_message}"
  echo "issue_number=${issue_number:-"(none)"}"
  echo "work_branch=${work_branch:-"(auto)"}"
  exit 0
fi

coding_args=(
  -m "${commit_message}"
  --title "${task_title}"
  --body "${request_text}"
  --harness-verify-command "${harness_verify_command}"
  --repair-attempts "${harness_repair_attempts}"
)

if [[ "${harness_run_verify}" == "0" ]]; then
  coding_args+=(--no-harness-verify)
fi
if [[ -n "${issue_number}" ]]; then
  coding_args+=(--issue "${issue_number}")
fi
if [[ -n "${issue_url}" ]]; then
  coding_args+=(--issue-url "${issue_url}")
fi
if [[ -n "${work_branch}" ]]; then
  coding_args+=(-b "${work_branch}")
fi
if (( ${#context_paths[@]} > 0 )); then
  for context_path in "${context_paths[@]}"; do
    coding_args+=(--context-path "${context_path}")
  done
fi

./scripts/coding_agent.sh "${coding_args[@]}"
