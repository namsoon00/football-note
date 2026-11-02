#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

smoke_tag="prelaunch-smoke"
expected_test_count=7
smoke_test_files=(
  test/application/scan_pass_spatial_library_service_test.dart
  test/presentation/scan_pass_spatial_library_screen_test.dart
  test/hive_training_repository_index_test.dart
)

for test_file in "${smoke_test_files[@]}"; do
  if [[ ! -f "${test_file}" ]]; then
    echo "Missing prelaunch smoke test file: ${test_file}" >&2
    exit 2
  fi
done

selected_test_count="$({
  rg --no-filename --only-matching \
    "tags:[[:space:]]*['\"]${smoke_tag}['\"]" \
    "${smoke_test_files[@]}" || true
} | wc -l | tr -d '[:space:]')"

if [[ "${selected_test_count}" != "${expected_test_count}" ]]; then
  echo \
    "Expected ${expected_test_count} '${smoke_tag}' tests in the explicit allowlist; found ${selected_test_count}." \
    >&2
  exit 2
fi

echo "==> ${selected_test_count} tagged tests across ${#smoke_test_files[@]} allowlisted files"
flutter test --no-pub --tags "${smoke_tag}" "${smoke_test_files[@]}"
