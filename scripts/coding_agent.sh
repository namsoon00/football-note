#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

usage() {
  cat <<'EOF'
Coding agent flow:
  - optional Codex harness run
  - verify
  - branch commit
  - merge to main
  - push main
  - optionally close issue

Usage:
  ./scripts/coding_agent.sh -m "<commit message>" [--issue <number>] [-b <branch>]
  ./scripts/coding_agent.sh -m "<commit message>" --title "<task>" [--body "<details>" | --body-file task.md]
EOF
}

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

task_title=""
task_body=""
task_body_file=""
issue_number=""
issue_url=""
harness_run_verify="${HARNESS_RUN_VERIFY:-1}"
harness_verify_command="${HARNESS_VERIFY_COMMAND:-./scripts/fix.sh}"
harness_repair_attempts="${HARNESS_REPAIR_ATTEMPTS:-1}"
forward_args=()
context_paths=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title)
      shift
      task_title="${1:-}"
      ;;
    --body)
      shift
      task_body="${1:-}"
      ;;
    --body-file)
      shift
      task_body_file="${1:-}"
      ;;
    --issue-url)
      shift
      issue_url="${1:-}"
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
    -h|--help)
      usage
      exit 0
      ;;
    --issue)
      forward_args+=("$1")
      shift
      issue_number="${1:-}"
      forward_args+=("${issue_number}")
      ;;
    *)
      forward_args+=("$1")
      ;;
  esac
  shift || true
done

if [[ -n "${task_title}" || -n "${task_body}" || -n "${task_body_file}" ]]; then
  harness_args=(
    --source local
    --title "${task_title:-Local coding task}"
    --issue-number "${issue_number}"
    --issue-url "${issue_url}"
    --run-verify "${harness_run_verify}"
    --verify-command "${harness_verify_command}"
    --repair-attempts "${harness_repair_attempts}"
  )

  if [[ -n "${task_body}" ]]; then
    harness_args+=(--body "${task_body}")
  fi
  if [[ -n "${task_body_file}" ]]; then
    harness_args+=(--body-file "${task_body_file}")
  fi
  if (( ${#context_paths[@]} > 0 )); then
    for context_path in "${context_paths[@]}"; do
      harness_args+=(--context-path "${context_path}")
    done
  fi

  ./scripts/codex_task_harness.sh "${harness_args[@]}"
fi

./scripts/verify_commit_push.sh "${forward_args[@]}"
