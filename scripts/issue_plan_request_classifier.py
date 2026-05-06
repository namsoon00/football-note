#!/usr/bin/env python3
"""Classify whether an issue should stop at a plan/discussion stage.

The issue worker only routes explicit planning requests to GitHub Discussions.
Implementation issues that merely mention a discussion for reporting, or that
explicitly say "do not post to discussion", must continue through normal coding.
"""

from __future__ import annotations

import argparse
import re

DISCUSSION_TERMS = r"(?:discussion|discussions|논의|디스커션)"

NEGATIVE_PATTERNS = (
    rf"{DISCUSSION_TERMS}\s*(?:에|으로)?\s*남기지\s*말",
    rf"{DISCUSSION_TERMS}\s*(?:말고|없이)",
    rf"{DISCUSSION_TERMS}.{{0,40}}(?:바로|곧)\s*(?:구현|수정|반영|적용|작업)",
    rf"(?:바로|곧)\s*(?:구현|수정|반영|적용|작업).{{0,40}}{DISCUSSION_TERMS}",
)

POST_COMPLETION_DISCUSSION_PATTERNS = (
    rf"(?:작업|구현|수정|검증)\s*(?:완료\s*)?후.{{0,120}}{DISCUSSION_TERMS}",
    rf"{DISCUSSION_TERMS}.{{0,120}}(?:작업|구현|수정|검증)\s*(?:완료\s*)?후",
)

STRONG_PLAN_PATTERNS = (
    r"(?:개발|작업|구현)?\s*(?:계획|플랜|기획)(?:서|안|을)?\s*(?:잡아|세워|정리|작성|제안|공유|설명|검토)",
    r"(?:설계|아키텍처)(?:부터|안|를)?\s*(?:제안|정리|작성|설명|검토|잡아)",
    r"우선(?:은)?\s*(?:설계|계획)",
    r"(?:mvp|로드맵|todo).{0,20}(?:계획|설계)",
    rf"{DISCUSSION_TERMS}\s*(?:에|으로)?\s*(?:계획|초안|proposal|요약)\s*(?:을|만)?\s*(?:먼저\s*)?(?:남겨|올려|작성|정리|공유)",
    rf"(?:계획|플랜|기획).{{0,40}}{DISCUSSION_TERMS}\s*(?:에|으로)?\s*(?:먼저\s*)?(?:남겨|올려|작성|정리|공유)",
)

TITLE_PLAN_PATTERNS = (
    r"^\s*(?:\[?\s*)?(?:계획|플랜|기획|설계)(?:\s*]?)\s*$",
    r"^\s*(?:계획|플랜|기획|설계)\b",
)


def _normalize(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip().casefold()


def is_plan_request(title: str, body: str) -> bool:
    normalized_title = _normalize(title)
    normalized_body = _normalize(body)
    normalized_text = _normalize(f"{title}\n{body}")

    for pattern in NEGATIVE_PATTERNS:
        if re.search(pattern, normalized_text):
            return False

    for pattern in POST_COMPLETION_DISCUSSION_PATTERNS:
        if re.search(pattern, normalized_text):
            return False

    for pattern in STRONG_PLAN_PATTERNS:
        if re.search(pattern, normalized_text):
            return True

    for pattern in TITLE_PLAN_PATTERNS:
        if re.search(pattern, normalized_title) and "구현" not in normalized_body:
            return True

    return False


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--title", default="", help="Issue title")
    parser.add_argument("--body", default="", help="Issue body")
    args = parser.parse_args()

    print("plan" if is_plan_request(args.title, args.body) else "implementation")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
