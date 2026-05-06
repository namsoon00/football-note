#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

run_case() {
  local expected="$1" title="$2" body="$3" actual

  actual="$(
    python3 scripts/issue_plan_request_classifier.py \
      --title "$title" \
      --body "$body"
  )"

  if [[ "$actual" != "$expected" ]]; then
    echo "[classifier-test] expected=$expected actual=$actual title=$title" >&2
    exit 1
  fi
}

run_case \
  plan \
  "스플린트 코칭" \
  "Flutter 앱에 실시간 러닝 코칭 기능을 추가하는 개발 계획을 잡아줘. 우선은 설계 + MVP 구현 계획 + 폴더 구조 + 핵심 클래스 설계부터 제안해줘."

run_case \
  implementation \
  "검증" \
  "작업 완료 후 검증 결과를 GitHub Discussion에 정리해서 남겨줘. 작성 완료 후 Discussion 링크를 답변으로 알려줘."

run_case \
  implementation \
  "오늘의 소식" \
  "discussion에 남기지 말고 바로 구현해줘."

run_case \
  implementation \
  "스플레시" \
  "역할을 나눠서 논의해보고 적당한 스플래시 이미지를 적용해줘."

run_case \
  implementation \
  "실기기" \
  "작업 후에는 검증 결과를 채팅에만 쓰지 말고, GitHub Discussion에 구조화해서 먼저 남긴 다음 링크와 요약만 답변해줘."

run_case \
  plan \
  "설계" \
  "작업 계획을 Discussion에 먼저 정리해주고 구현은 다음 단계에서 진행하자."

echo "[classifier-test] ok"
