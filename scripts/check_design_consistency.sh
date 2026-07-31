#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v rg >/dev/null 2>&1 && ! command -v grep >/dev/null 2>&1; then
  echo "[design] ripgrep or grep is required for design consistency checks." >&2
  exit 1
fi

search() {
  if command -v rg >/dev/null 2>&1; then
    rg "$@"
  else
    grep -E "$@"
  fi
}

base_ref="${DESIGN_BASE_REF:-origin/main}"
if ! git rev-parse --verify "${base_ref}" >/dev/null 2>&1; then
  base_ref="$(git rev-list --max-parents=0 HEAD | tail -1)"
fi

changed_files="$(
  {
    git diff --name-only --diff-filter=ACMR "${base_ref}"...HEAD 2>/dev/null || true
    git diff --name-only --diff-filter=ACMR
    git diff --name-only --cached --diff-filter=ACMR
  } | sort -u
)"

presentation_files="$(printf '%s\n' "${changed_files}" | search '^lib/presentation/.*\.dart$' || true)"
if [[ -z "${presentation_files}" ]]; then
  echo "[design] No changed presentation Dart files to check."
  exit 0
fi

failed=0
while IFS= read -r file; do
  [[ -z "${file}" || ! -f "${file}" ]] && continue

  added_lines="$(
    {
      git diff --unified=0 "${base_ref}"...HEAD -- "${file}" 2>/dev/null || true
      git diff --unified=0 --cached -- "${file}" 2>/dev/null || true
      git diff --unified=0 -- "${file}" 2>/dev/null || true
    } | awk '/^\+\+\+ / { next } /^\+/ { print substr($0, 2) }'
  )"
  [[ -z "${added_lines}" ]] && continue

  copy_matches="$(printf '%s\n' "${added_lines}" | search -n "isKo[[:space:]]*\\?[[:space:]]*['\"]|Localizations\\.localeOf\\(context\\)\\.languageCode[[:space:]]*==[[:space:]]*['\"]ko['\"]" 2>/dev/null || true)"
  if [[ -n "${copy_matches}" ]]; then
    echo "[design] ${file}: move newly added locale-specific user-facing copy to lib/l10n/*.arb." >&2
    echo "${copy_matches}" >&2
    failed=1
  fi

  if [[ "${file}" == "lib/presentation/widgets/app_bar_action_button.dart" ]]; then
    continue
  fi

  action_matches="$(printf '%s\n' "${added_lines}" | search -n "IconButton[[:space:]]*\\(|TextButton[.]icon[[:space:]]*\\(|PopupMenuButton[<[:space:]]|PopupMenuButton[[:space:]]*\\(" 2>/dev/null || true)"
  if [[ -n "${action_matches}" ]]; then
    echo "[design] ${file}: use AppBarActionButton/AppBarActionMenuButton for newly added top-right app bar actions." >&2
    echo "${action_matches}" >&2
    failed=1
  fi
done <<< "${presentation_files}"

if [[ "${failed}" -ne 0 ]]; then
  echo "[design] Design consistency guardrails failed." >&2
  exit 1
fi

echo "[design] Design consistency guardrails passed."
