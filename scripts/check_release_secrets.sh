#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/check_release_secrets.sh <platform>

Platforms:
  ios
  android
EOF
}

platform="${1:-}"
if [[ -z "${platform}" ]]; then
  usage
  exit 1
fi

missing=()

require_env() {
  local key="$1"
  if [[ -z "${!key:-}" ]]; then
    missing+=("$key")
  fi
}

case "${platform}" in
  ios)
    require_env "ASC_KEY_ID"
    require_env "ASC_ISSUER_ID"
    require_env "ASC_KEY_CONTENT"
    require_env "IOS_DISTRIBUTION_CERT_B64"
    require_env "IOS_DISTRIBUTION_CERT_PASSWORD"
    require_env "IOS_PROVISIONING_PROFILE_B64"
    require_env "KEYCHAIN_PASSWORD"
    ;;
  android)
    require_env "ANDROID_UPLOAD_KEYSTORE_B64"
    require_env "ANDROID_KEYSTORE_PASSWORD"
    require_env "ANDROID_KEY_ALIAS"
    require_env "ANDROID_KEY_PASSWORD"
    require_env "PLAY_JSON_KEY"
    ;;
  *)
    echo "Unknown platform: ${platform}"
    usage
    exit 1
    ;;
esac

if [[ "${#missing[@]}" -gt 0 ]]; then
  echo "Missing required release secrets (${platform}):"
  for key in "${missing[@]}"; do
    echo "- ${key}"
  done
  exit 1
fi

echo "All required ${platform} release secrets are set."
