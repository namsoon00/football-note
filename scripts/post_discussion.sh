#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

usage() {
  cat <<'EOF'
Usage:
  ./scripts/post_discussion.sh --title "<title>" --body-file <path> [--repo owner/name] [--category "<name>"]
  ./scripts/post_discussion.sh --discussion-url <url> --body-file <path> [--repo owner/name]
  ./scripts/post_discussion.sh --discussion-number <number> --body-file <path> [--repo owner/name]

Options:
  --title <text>             Discussion title for create mode
  --body-file <path>         Markdown body file (required)
  --repo <owner/name>        GitHub repository (defaults to GITHUB_REPOSITORY or origin remote)
  --category <name>          Preferred discussion category name for create mode
  --discussion-url <url>     Existing discussion URL for comment mode
  --discussion-number <num>  Existing discussion number for comment mode
EOF
}

title=""
body_file=""
repo="${GITHUB_REPOSITORY:-}"
preferred_category="${DISCUSSION_CATEGORY:-}"
discussion_url=""
discussion_number=""

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
    --discussion-url)
      shift
      discussion_url="${1:-}"
      ;;
    --discussion-number)
      shift
      discussion_number="${1:-}"
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

if [[ -z "${body_file}" ]]; then
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

resolve_repo_from_origin() {
  local origin_url

  origin_url="$(git remote get-url origin)"
  if [[ "${origin_url}" =~ ^git@github.com:(.+)\.git$ ]]; then
    echo "${BASH_REMATCH[1]}"
    return 0
  fi
  if [[ "${origin_url}" =~ ^https://github.com/(.+)\.git$ ]]; then
    echo "${BASH_REMATCH[1]}"
    return 0
  fi
  if [[ "${origin_url}" =~ ^https://github.com/(.+)$ ]]; then
    echo "${BASH_REMATCH[1]}"
    return 0
  fi
  return 1
}

graphql_request() {
  local payload="${1:-}"

  curl -fsSL \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "Content-Type: application/json" \
    -X POST \
    "https://api.github.com/graphql" \
    -d "${payload}"
}

extract_graphql_error() {
  python3 - <<'PY' "${1:-}"
import json
import sys

try:
    payload = json.loads(sys.argv[1])
except Exception:
    print("")
    raise SystemExit(0)

errors = payload.get("errors") or []
if errors:
    print(str((errors[0] or {}).get("message", "")).strip())
PY
}

mode="create"
if [[ -n "${discussion_url}" || -n "${discussion_number}" ]]; then
  mode="comment"
fi

if [[ "${mode}" == "create" ]]; then
  if [[ -z "${title}" ]]; then
    usage
    exit 1
  fi
else
  if [[ -z "${discussion_url}" && -z "${discussion_number}" ]]; then
    echo "Discussion URL or discussion number is required for comment mode." >&2
    exit 1
  fi
  if [[ -n "${title}" ]]; then
    echo "--title is only valid in create mode." >&2
    exit 1
  fi
fi

if [[ -z "${repo}" ]]; then
  repo="$(resolve_repo_from_origin || true)"
fi

if [[ "${mode}" == "create" ]]; then
  if [[ -z "${repo}" ]]; then
    echo "Repository could not be resolved." >&2
    exit 1
  fi

  repo_context_response="$(
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
categories = ((repository.get("discussionCategories") or {}).get("nodes") or [])
preferred_name = preferred_category.strip().lower()
preferred_fallbacks = ["general", "ideas", "q&a", "announcements"]

category_id = ""
if preferred_name:
    for item in categories:
        if str(item.get("name", "")).strip().lower() == preferred_name:
            category_id = str(item.get("id", "")).strip()
            break

if not category_id:
    for fallback in preferred_fallbacks:
        for item in categories:
            if str(item.get("name", "")).strip().lower() == fallback:
                category_id = str(item.get("id", "")).strip()
                break
        if category_id:
            break

if not category_id and categories:
    category_id = str((categories[0] or {}).get("id", "")).strip()

print(
    json.dumps(
        {
            "repository_id": str(repository.get("id", "")).strip(),
            "category_id": category_id,
            "errors": payload.get("errors") or [],
        },
        ensure_ascii=False,
    )
)
PY
  )"

  repository_id="$(
    python3 - <<'PY' "${repo_context_response}"
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
    python3 - <<'PY' "${repo_context_response}"
import json
import sys

try:
    payload = json.loads(sys.argv[1])
except Exception:
    print("")
    raise SystemExit(0)

print(str(payload.get("category_id", "")).strip())
PY
  )"

  if [[ -z "${repository_id}" || -z "${category_id}" ]]; then
    error_message="$(extract_graphql_error "${repo_context_response}")"
    if [[ -n "${error_message}" ]]; then
      echo "Discussion repository/category could not be resolved: ${error_message}" >&2
    else
      echo "Discussion repository/category could not be resolved." >&2
    fi
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

  response="$(graphql_request "${payload}")"
  output_url="$(
    python3 - <<'PY' "${response}"
import json
import sys

try:
    payload = json.loads(sys.argv[1])
except Exception:
    print("")
    raise SystemExit(0)

discussion = (((payload.get("data") or {}).get("createDiscussion") or {}).get("discussion")) or {}
print(str(discussion.get("url", "")).strip())
PY
  )"

  if [[ -z "${output_url}" ]]; then
    error_message="$(extract_graphql_error "${response}")"
    if [[ -n "${error_message}" ]]; then
      echo "Discussion creation failed: ${error_message}" >&2
    else
      echo "Discussion creation failed." >&2
    fi
    exit 1
  fi

  echo "${output_url}"
  exit 0
fi

discussion_ref_json="$(
  python3 - <<'PY' "${repo}" "${discussion_url}" "${discussion_number}"
import json
import re
import sys

repo, discussion_url, discussion_number = sys.argv[1:4]

if discussion_url:
    match = re.search(r"https://github\.com/([^/]+/[^/]+)/discussions/([0-9]+)", discussion_url)
    if match:
        repo = match.group(1)
        discussion_number = match.group(2)

print(
    json.dumps(
        {
            "repo": repo.strip(),
            "discussion_number": str(discussion_number).strip(),
        },
        ensure_ascii=False,
    )
)
PY
)"

repo="$(
  python3 - <<'PY' "${discussion_ref_json}"
import json
import sys

try:
    payload = json.loads(sys.argv[1])
except Exception:
    print("")
    raise SystemExit(0)

print(str(payload.get("repo", "")).strip())
PY
)"

discussion_number="$(
  python3 - <<'PY' "${discussion_ref_json}"
import json
import sys

try:
    payload = json.loads(sys.argv[1])
except Exception:
    print("")
    raise SystemExit(0)

print(str(payload.get("discussion_number", "")).strip())
PY
)"

if [[ -z "${repo}" || -z "${discussion_number}" ]]; then
  echo "Discussion repository/number could not be resolved for comment mode." >&2
  exit 1
fi

discussion_lookup_payload="$(
  python3 - <<'PY' "${repo}" "${discussion_number}"
import json
import sys

repo = sys.argv[1]
discussion_number = int(sys.argv[2])
owner, name = repo.split("/", 1)
print(
    json.dumps(
        {
            "query": """
query($owner:String!, $name:String!, $number:Int!) {
  repository(owner:$owner, name:$name) {
    discussion(number:$number) {
      id
      url
    }
  }
}
""",
            "variables": {
                "owner": owner,
                "name": name,
                "number": discussion_number,
            },
        },
        ensure_ascii=False,
    )
)
PY
)"

discussion_lookup_response="$(graphql_request "${discussion_lookup_payload}")"
discussion_id="$(
  python3 - <<'PY' "${discussion_lookup_response}"
import json
import sys

try:
    payload = json.loads(sys.argv[1])
except Exception:
    print("")
    raise SystemExit(0)

discussion = (((payload.get("data") or {}).get("repository")) or {}).get("discussion") or {}
print(str(discussion.get("id", "")).strip())
PY
)"

resolved_discussion_url="$(
  python3 - <<'PY' "${discussion_lookup_response}"
import json
import sys

try:
    payload = json.loads(sys.argv[1])
except Exception:
    print("")
    raise SystemExit(0)

discussion = (((payload.get("data") or {}).get("repository")) or {}).get("discussion") or {}
print(str(discussion.get("url", "")).strip())
PY
)"

if [[ -z "${discussion_id}" || -z "${resolved_discussion_url}" ]]; then
  error_message="$(extract_graphql_error "${discussion_lookup_response}")"
  if [[ -n "${error_message}" ]]; then
    echo "Discussion lookup failed: ${error_message}" >&2
  else
    echo "Discussion lookup failed." >&2
  fi
  exit 1
fi

comment_payload="$(
  python3 - <<'PY' "${discussion_id}" "${body_file}"
import json
import pathlib
import sys

discussion_id, body_path = sys.argv[1:3]
body = pathlib.Path(body_path).read_text(encoding="utf-8")
print(
    json.dumps(
        {
            "query": """
mutation($input: AddDiscussionCommentInput!) {
  addDiscussionComment(input: $input) {
    comment {
      id
    }
  }
}
""",
            "variables": {
                "input": {
                    "discussionId": discussion_id,
                    "body": body,
                }
            },
        },
        ensure_ascii=False,
    )
)
PY
)"

comment_response="$(graphql_request "${comment_payload}")"
comment_id="$(
  python3 - <<'PY' "${comment_response}"
import json
import sys

try:
    payload = json.loads(sys.argv[1])
except Exception:
    print("")
    raise SystemExit(0)

comment = (((payload.get("data") or {}).get("addDiscussionComment") or {}).get("comment")) or {}
print(str(comment.get("id", "")).strip())
PY
)"

if [[ -z "${comment_id}" ]]; then
  error_message="$(extract_graphql_error "${comment_response}")"
  if [[ -n "${error_message}" ]]; then
    echo "Discussion comment failed: ${error_message}" >&2
  else
    echo "Discussion comment failed." >&2
  fi
  exit 1
fi

echo "${resolved_discussion_url}"
