#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v rg >/dev/null 2>&1; then
  echo "[design] ripgrep is required for design consistency checks." >&2
  exit 1
fi

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

presentation_files="$(printf '%s\n' "${changed_files}" | rg '^lib/presentation/.*\.dart$' || true)"
if [[ -z "${presentation_files}" ]]; then
  echo "[design] No changed presentation Dart files to check."
  exit 0
fi

failed=0
while IFS= read -r file; do
  [[ -z "${file}" || ! -f "${file}" ]] && continue

  copy_matches="$(rg -n "isKo[[:space:]]*\\?[[:space:]]*['\"]|Localizations\\.localeOf\\(context\\)\\.languageCode[[:space:]]*==[[:space:]]*['\"]ko['\"]" "${file}" 2>/dev/null || true)"
  if [[ -n "${copy_matches}" ]]; then
    echo "[design] ${file}: move locale-specific user-facing copy to lib/l10n/*.arb." >&2
    echo "${copy_matches}" >&2
    failed=1
  fi

  if [[ "${file}" == "lib/presentation/widgets/app_bar_action_button.dart" ]]; then
    continue
  fi

  action_matches="$(awk '
    /AppBar[[:space:]]*\(/ { appbar = 90 }
    appbar > 0 && /actions[[:space:]]*:[[:space:]]*\[/ { actions = 45 }
    actions > 0 && /(IconButton[[:space:]]*\(|TextButton[.]icon[[:space:]]*\(|PopupMenuButton[<[:space:]]|PopupMenuButton[[:space:]]*\()/ {
      print FNR ":" $0
      found = 1
    }
    {
      if (appbar > 0) appbar--
      if (actions > 0) actions--
    }
    END { exit found ? 1 : 0 }
  ' "${file}" || true)"
  if [[ -n "${action_matches}" ]]; then
    echo "[design] ${file}: use AppBarActionButton or AppBarActionMenuButton for top-right app bar actions." >&2
    echo "${action_matches}" >&2
    failed=1
  fi
done <<< "${presentation_files}"

if [[ "${failed}" -ne 0 ]]; then
  echo "[design] Design consistency guardrails failed." >&2
  exit 1
fi

echo "[design] Design consistency guardrails passed."
