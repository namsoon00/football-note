#!/usr/bin/env bash
set -euo pipefail

load_local_flutter_env() {
  local root_dir="$1"
  local env_file="${root_dir}/.env"
  if [[ ! -f "${env_file}" ]]; then
    return
  fi

  set -a
  # shellcheck disable=SC1090
  source "${env_file}"
  set +a
}

build_flutter_define_args() {
  FLUTTER_DEFINE_ARGS=()
  if [[ -n "${KMA_API_KEY:-}" ]]; then
    FLUTTER_DEFINE_ARGS+=("--dart-define=KMA_API_KEY=${KMA_API_KEY}")
  fi
}
