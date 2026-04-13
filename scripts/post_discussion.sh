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
  python3 - <<'PY' "${repo}" "${preferred_category}"
import json
import os
import sys
import urllib.request

repo = sys.argv[1]
preferred_category = sys.argv[2]
owner, name = repo.split("/", 1)
query = """
query($owner:String!, $name:String!) {
  repository(owner:$owner, name:$name) {
    id
    discussionCategories(first:20) {
      nodes {
        id
        name
        slug
      }
    }
  }
}
"""
request = urllib.request.Request(
    "https://api.github.com/graphql",
    data=json.dumps(
        {"query": query, "variables": {"owner": owner, "name": name}},
        ensure_ascii=False,
    ).encode(),
    headers={
        "Authorization": f"Bearer {os.environ['GITHUB_TOKEN']}",
        "Content-Type": "application/json",
        "Accept": "application/vnd.github+json",
    },
    method="POST",
)
with urllib.request.urlopen(request) as response:
    payload = json.loads(response.read().decode())

repository = (((payload.get("data") or {}).get("repository")) or {})
print(
    json.dumps(
        {
            "repository_id": repository.get("id", ""),
            "categories": ((repository.get("discussionCategories") or {}).get("nodes") or []),
            "preferred_category": preferred_category,
        },
        ensure_ascii=False,
    )
)
PY
)"

repository_id="$(
  python3 - <<'PY' "${categories_json}"
import json
import sys

try:
    payload = json.loads(sys.argv[1])
except Exception:
    print("")
    raise SystemExit(0)

print(str(payload.get("repository_id", "")).strip())
PY
)"

category_id="$(
  python3 - <<'PY' "${categories_json}"
import json
import sys

try:
    payload = json.loads(sys.argv[1])
except Exception:
    print("")
    raise SystemExit(0)

categories = payload.get("categories") or []
preferred_name = str(payload.get("preferred_category", "")).strip().lower()
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

if [[ -z "${repository_id}" || -z "${category_id}" ]]; then
  echo "Discussion repository/category could not be resolved." >&2
  exit 1
fi

payload="$(
  python3 - <<'PY' "${title}" "${repository_id}" "${category_id}" "${body_file}"
import json
import pathlib
import sys

title, repository_id, category_id, body_path = sys.argv[1:5]
body = pathlib.Path(body_path).read_text(encoding="utf-8")
print(
    json.dumps(
        {
            "query": """
mutation($input: CreateDiscussionInput!) {
  createDiscussion(input: $input) {
    discussion {
      url
    }
  }
}
""",
            "variables": {
                "input": {
                    "repositoryId": repository_id,
                    "categoryId": category_id,
                    "title": title,
                    "body": body,
                }
            },
        },
        ensure_ascii=False,
    )
)
PY
)"

response="$(
  curl -fsSL \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "Content-Type: application/json" \
    -X POST \
    "https://api.github.com/graphql" \
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

discussion = (((response.get("data") or {}).get("createDiscussion") or {}).get("discussion")) or {}
print(str(discussion.get("url", "")).strip())
PY
)"

if [[ -z "${discussion_url}" ]]; then
  echo "Discussion creation failed." >&2
  exit 1
fi

echo "${discussion_url}"
