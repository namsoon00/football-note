#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

target="scripts/run_issue_worker.sh"

assert_contains() {
  local pattern="$1"
  if ! rg -Fq -- "$pattern" "$target"; then
    echo "[issue-worker-wording] missing pattern: $pattern" >&2
    exit 1
  fi
}

assert_not_contains() {
  local pattern="$1"
  if rg -Fq -- "$pattern" "$target"; then
    echo "[issue-worker-wording] unexpected pattern: $pattern" >&2
    exit 1
  fi
}

assert_contains 'print(f"[플랜] Issue #{issue_number} - {issue_title}")'
assert_contains '## 작업 플랜(초안)'
assert_contains '자동 워커가 생성한 플랜 Discussion입니다. 필요하면 여기서 바로 피드백 주세요.'
assert_contains '요청하신 플랜을 연결된 Discussion에 남겼습니다: ${discussion_target}'
assert_contains '요청하신 플랜을 Discussion에 남겼습니다: ${discussion_target}'
assert_contains '"플랜 Discussion 작성 완료"'
assert_contains '"요청하신 플랜을 Discussion에 남겼습니다."'
assert_contains 'notify_issue_and_discussion "플랜 요청을 감지했지만 Discussion 생성에 실패했습니다. 저장소 Discussions 활성화/권한을 확인해 주세요."'

assert_not_contains 'print(f"[계획] Issue #{issue_number} - {issue_title}")'
assert_not_contains '## 작업 계획(초안)'
assert_not_contains '자동 워커가 생성한 계획 Discussion입니다. 필요하면 여기서 바로 피드백 주세요.'
assert_not_contains '요청하신 계획을'
assert_not_contains '"계획 Discussion 작성 완료"'
assert_not_contains 'notify_issue_and_discussion "계획 요청을 감지했지만 Discussion 생성에 실패했습니다. 저장소 Discussions 활성화/권한을 확인해 주세요."'

echo "[issue-worker-wording] ok"
