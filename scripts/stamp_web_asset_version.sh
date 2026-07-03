#!/usr/bin/env bash
set -euo pipefail

target_dir="${1:-build/web}"
raw_version="${2:-${WEB_ASSET_VERSION:-}}"

if [[ -z "${raw_version}" ]]; then
  raw_version="$(git rev-parse --short=12 HEAD 2>/dev/null || date -u +%Y%m%d%H%M%S)"
fi

version="$(printf '%s' "${raw_version}" | tr -c 'A-Za-z0-9._-' '-')"

if [[ ! -d "${target_dir}" ]]; then
  echo "Web build directory not found: ${target_dir}" >&2
  exit 1
fi

required_files=(
  "${target_dir}/index.html"
  "${target_dir}/flutter_bootstrap.js"
)
version_file="${target_dir}/version.json"

for file in "${required_files[@]}"; do
  if [[ ! -f "${file}" ]]; then
    echo "Required web asset not found: ${file}" >&2
    exit 1
  fi
done

WEB_ASSET_VERSION="${version}" perl -0pi -e \
  's/__WEB_ASSET_VERSION__/$ENV{WEB_ASSET_VERSION}/g' \
  "${required_files[@]}"

if grep -R "__WEB_ASSET_VERSION__" "${required_files[@]}" >/dev/null; then
  echo "Unstamped web asset version placeholder remains." >&2
  exit 1
fi

generated_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
printf '{"assetVersion":"%s","generatedAt":"%s"}\n' \
  "${version}" \
  "${generated_at}" >"${version_file}"

echo "Stamped web asset version: ${version}"
