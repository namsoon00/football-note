#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

usage() {
  cat <<'EOF'
Usage:
  ./scripts/post_discussion.sh --title "<title>" --body-file <path> [--repo owner/name] [--category "<name>"]

Options:
  --title <text>       Discussion title (required)
  --body-file <path>   Markdown body file (required)
  --repo <owner/name>  GitHub repository (defaults to GITHUB_REPOSITORY or origin remote)
  --category <name>    Preferred discussion category name
EOF
}

title=""
body_file=""
repo="${GITHUB_REPOSITORY:-}"
preferred_category="${DISCUSSION_CATEGORY:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title)
      shift
      title="${1:-}"
      ;;
    --body-file)
      shift
      body_file="${1:-}"
      ;;
    --repo)
      shift
      repo="${1:-}"
      ;;
    --category)
      shift
      preferred_category="${1:-}"
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

if [[ -z "${title}" || -z "${body_file}" ]]; then
  usage
  exit 1
fi

if [[ ! -f "${body_file}" ]]; then
  echo "Body file not found: ${body_file}" >&2
  exit 1
fi

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "GITHUB_TOKEN is required." >&2
  exit 1
fi

if [[ -z "${repo}" ]]; then
  origin_url="$(git remote get-url origin)"
  if [[ "${origin_url}" =~ ^git@github.com:(.+)\.git$ ]]; then
    repo="${BASH_REMATCH[1]}"
  elif [[ "${origin_url}" =~ ^https://github.com/(.+)\.git$ ]]; then
    repo="${BASH_REMATCH[1]}"
  elif [[ "${origin_url}" =~ ^https://github.com/(.+)$ ]]; then
    repo="${BASH_REMATCH[1]}"
  fi
fi

if [[ -z "${repo}" ]]; then
  echo "Repository could not be resolved." >&2
  exit 1
fi

categories_json="$(
  curl -fsSL \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${repo}/discussions/categories"
)"

category_id="$(
  python3 - <<'PY' "${categories_json}" "${preferred_category}"
import json
import sys

try:
    categories = json.loads(sys.argv[1])
except Exception:
    print("")
    raise SystemExit(0)

preferred_name = sys.argv[2].strip().lower()
preferred_fallbacks = ["general", "ideas", "q&a", "announcements"]

picked = ""
if isinstance(categories, list):
    if preferred_name:
        for item in categories:
            if str(item.get("name", "")).strip().lower() == preferred_name:
                picked = str(item.get("id", "")).strip()
                break

    if not picked:
        for fallback in preferred_fallbacks:
            for item in categories:
                if str(item.get("name", "")).strip().lower() == fallback:
                    picked = str(item.get("id", "")).strip()
                    break
            if picked:
                break

    if not picked and categories:
        picked = str(categories[0].get("id", "")).strip()

print(picked)
PY
)"

if [[ -z "${category_id}" ]]; then
  echo "Discussion category could not be resolved." >&2
  exit 1
fi

payload="$(
  python3 - <<'PY' "${title}" "${category_id}" "${body_file}"
import json
import pathlib
import sys

title, category_id, body_path = sys.argv[1:4]
body = pathlib.Path(body_path).read_text(encoding="utf-8")
print(
    json.dumps(
        {"title": title, "body": body, "category_id": category_id},
        ensure_ascii=False,
    )
)
PY
)"

response="$(
  curl -fsSL \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -X POST \
    "https://api.github.com/repos/${repo}/discussions" \
    -d "${payload}"
)"

discussion_url="$(
  python3 - <<'PY' "${response}"
import json
import sys

try:
    response = json.loads(sys.argv[1])
except Exception:
    print("")
    raise SystemExit(0)

print(str(response.get("html_url", "")).strip())
PY
)"

if [[ -z "${discussion_url}" ]]; then
  echo "Discussion creation failed." >&2
  exit 1
fi

echo "${discussion_url}"
