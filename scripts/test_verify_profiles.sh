#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

TMP_ROOT="$(mktemp -d "${ROOT_DIR}/.tmp/verify-profiles.XXXXXX")"
FIXTURE_ROOT="${TMP_ROOT}/repo"
FIXTURE_BIN="${FIXTURE_ROOT}/bin"
VERIFY_LOG="${TMP_ROOT}/verify.log"
FLOW_LOG="${TMP_ROOT}/flow.log"
OUTPUT_LOG="${TMP_ROOT}/output.log"
trap 'rm -rf "${TMP_ROOT}"' EXIT

isolated_fixture_env=(
  env
  -u VERIFY_SCOPE
  -u GITHUB_ACTIONS
  -u HARNESS_RUN_VERIFY
  -u HARNESS_VERIFY_COMMAND
  -u HARNESS_REPAIR_ATTEMPTS
)

fail() {
  echo "[verify-profiles] $*" >&2
  exit 1
}

assert_line() {
  local expected="$1"
  local file="$2"
  rg --fixed-strings --line-regexp --quiet "${expected}" "${file}" ||
    fail "missing line in ${file}: ${expected}"
}

assert_absent() {
  local unexpected="$1"
  local file="$2"
  if rg --fixed-strings --quiet "${unexpected}" "${file}"; then
    fail "unexpected text in ${file}: ${unexpected}"
  fi
}

assert_no_line() {
  local unexpected="$1"
  local file="$2"
  if rg --fixed-strings --line-regexp --quiet "${unexpected}" "${file}"; then
    fail "unexpected line in ${file}: ${unexpected}"
  fi
}

assert_count() {
  local expected_count="$1"
  local pattern="$2"
  local file="$3"
  local actual_count
  actual_count="$(rg --fixed-strings --count-matches "${pattern}" "${file}" || true)"
  actual_count="${actual_count:-0}"
  [[ "${actual_count}" == "${expected_count}" ]] ||
    fail "expected ${expected_count} matches for '${pattern}' in ${file}; found ${actual_count}"
}

mkdir -p \
  "${FIXTURE_BIN}" \
  "${FIXTURE_ROOT}/scripts" \
  "${FIXTURE_ROOT}/test/application" \
  "${FIXTURE_ROOT}/test/presentation"

cp scripts/verify.sh scripts/run_prelaunch_smoke_tests.sh "${FIXTURE_ROOT}/scripts/"
cp scripts/coding_agent.sh scripts/chat_task.sh "${FIXTURE_ROOT}/scripts/"

cat > "${FIXTURE_BIN}/flutter" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
{
  printf 'flutter'
  for argument in "$@"; do
    printf ' <%s>' "${argument}"
  done
  printf '\n'
} >> "${VERIFY_PROFILE_LOG:?}"
EOF

cat > "${FIXTURE_BIN}/python3" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
{
  printf 'python3'
  for argument in "$@"; do
    printf ' <%s>' "${argument}"
  done
  printf '\n'
} >> "${VERIFY_PROFILE_LOG:?}"
if [[ "${1:-}" == "-" ]]; then
  shift
  shift
  "$@"
fi
EOF

cat > "${FIXTURE_ROOT}/scripts/contract_stub.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'contract <%s>\n' "${0##*/}" >> "${VERIFY_PROFILE_LOG:?}"
EOF

contract_scripts=(
  check_design_consistency.sh
  quiz_quality_harness.sh
  quiz_generation_harness.sh
  test_issue_plan_request_classifier.sh
  test_issue_worker_plan_wording.sh
  test_web_asset_version_stamp.sh
  test_verify_profiles.sh
  test_ios_native_assets.sh
  test_ios_path_provider_foundation_compatibility.sh
  test_android_upload_mediapipe_contract.sh
  test_web_running_video_analysis_contract.sh
  test_running_analysis_v2_contract.sh
  test_pages_root_static_web_contract.sh
  test_running_no_3d_runner_contract.sh
  test_running_release_video_fixtures_contract.sh
)
for contract_script in "${contract_scripts[@]}"; do
  ln -s contract_stub.sh "${FIXTURE_ROOT}/scripts/${contract_script}"
done

cat > "${FIXTURE_ROOT}/test/application/scan_pass_spatial_library_service_test.dart" <<'EOF'
void main() {
  test('asset integrity', () {}, tags: 'prelaunch-smoke');
  test('resume preferences', () {}, tags: 'prelaunch-smoke');
  test('stale data', () {}, tags: 'prelaunch-smoke');
}
EOF
cat > "${FIXTURE_ROOT}/test/presentation/scan_pass_spatial_library_screen_test.dart" <<'EOF'
void main() {
  test('root navigation', () {}, tags: 'prelaunch-smoke');
  test('playback controls', () {}, tags: 'prelaunch-smoke');
  test('re-entry', () {}, tags: 'prelaunch-smoke');
}
EOF
cat > "${FIXTURE_ROOT}/test/hive_training_repository_index_test.dart" <<'EOF'
void main() {
  test('storage CRUD', () {}, tags: 'prelaunch-smoke');
}
EOF

chmod +x "${FIXTURE_BIN}/flutter" "${FIXTURE_BIN}/python3"
chmod +x "${FIXTURE_ROOT}/scripts/"*.sh

expected_smoke_command="flutter <test> <--no-pub> <--tags> <prelaunch-smoke> <test/application/scan_pass_spatial_library_service_test.dart> <test/presentation/scan_pass_spatial_library_screen_test.dart> <test/hive_training_repository_index_test.dart>"

: > "${VERIFY_LOG}"
(
  cd "${FIXTURE_ROOT}"
  "${isolated_fixture_env[@]}" \
    PATH="${FIXTURE_BIN}:${PATH}" \
    VERIFY_PROFILE_LOG="${VERIFY_LOG}" \
    ./scripts/verify.sh > "${OUTPUT_LOG}"
)
assert_line "${expected_smoke_command}" "${VERIFY_LOG}"
assert_absent "contract <quiz_quality_harness.sh>" "${VERIFY_LOG}"
assert_no_line "flutter <test>" "${VERIFY_LOG}"
assert_count 1 "flutter <test>" "${VERIFY_LOG}"

: > "${VERIFY_LOG}"
(
  cd "${FIXTURE_ROOT}"
  "${isolated_fixture_env[@]}" \
    PATH="${FIXTURE_BIN}:${PATH}" \
    VERIFY_PROFILE_LOG="${VERIFY_LOG}" \
    VERIFY_SCOPE=minimal \
    ./scripts/verify.sh > "${OUTPUT_LOG}"
)
assert_line "${expected_smoke_command}" "${VERIFY_LOG}"
assert_count 1 "flutter <test>" "${VERIFY_LOG}"

: > "${VERIFY_LOG}"
(
  cd "${FIXTURE_ROOT}"
  "${isolated_fixture_env[@]}" \
    PATH="${FIXTURE_BIN}:${PATH}" \
    VERIFY_PROFILE_LOG="${VERIFY_LOG}" \
    VERIFY_SCOPE=full \
    GITHUB_ACTIONS=true \
    ./scripts/verify.sh > "${OUTPUT_LOG}"
)
assert_line "flutter <test>" "${VERIFY_LOG}"
assert_absent "prelaunch-smoke" "${VERIFY_LOG}"
assert_line \
  "python3 <tool/scan_pass_replay/prepare_spatial_education.py> <--verify-assets>" \
  "${VERIFY_LOG}"
for contract_script in "${contract_scripts[@]:1}"; do
  assert_line "contract <${contract_script}>" "${VERIFY_LOG}"
done

: > "${VERIFY_LOG}"
if (
  cd "${FIXTURE_ROOT}"
  "${isolated_fixture_env[@]}" \
    PATH="${FIXTURE_BIN}:${PATH}" \
    VERIFY_PROFILE_LOG="${VERIFY_LOG}" \
    VERIFY_SCOPE=unexpected \
    ./scripts/verify.sh > "${OUTPUT_LOG}" 2>&1
); then
  fail "unknown VERIFY_SCOPE unexpectedly passed"
fi
[[ ! -s "${VERIFY_LOG}" ]] || fail "unknown scope invoked tools before failing"

mv \
  "${FIXTURE_ROOT}/test/hive_training_repository_index_test.dart" \
  "${FIXTURE_ROOT}/test/hive_training_repository_index_test.dart.missing"
: > "${VERIFY_LOG}"
if (
  cd "${FIXTURE_ROOT}"
  "${isolated_fixture_env[@]}" \
    PATH="${FIXTURE_BIN}:${PATH}" \
    VERIFY_PROFILE_LOG="${VERIFY_LOG}" \
    ./scripts/verify.sh > "${OUTPUT_LOG}" 2>&1
); then
  fail "quick profile passed with an allowlisted test file missing"
fi
assert_no_line "flutter <test>" "${VERIFY_LOG}"
mv \
  "${FIXTURE_ROOT}/test/hive_training_repository_index_test.dart.missing" \
  "${FIXTURE_ROOT}/test/hive_training_repository_index_test.dart"

for smoke_file in \
  "${FIXTURE_ROOT}/test/application/scan_pass_spatial_library_service_test.dart" \
  "${FIXTURE_ROOT}/test/presentation/scan_pass_spatial_library_screen_test.dart" \
  "${FIXTURE_ROOT}/test/hive_training_repository_index_test.dart"; do
  sed 's/prelaunch-smoke/not-smoke/g' "${smoke_file}" > "${smoke_file}.rewritten"
  mv "${smoke_file}.rewritten" "${smoke_file}"
done
: > "${VERIFY_LOG}"
if (
  cd "${FIXTURE_ROOT}"
  "${isolated_fixture_env[@]}" \
    PATH="${FIXTURE_BIN}:${PATH}" \
    VERIFY_PROFILE_LOG="${VERIFY_LOG}" \
    ./scripts/verify.sh > "${OUTPUT_LOG}" 2>&1
); then
  fail "quick profile passed with zero selected smoke tests"
fi
assert_no_line "flutter <test>" "${VERIFY_LOG}"

cat > "${FIXTURE_ROOT}/scripts/codex_task_harness.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
run_verify=0
verify_command="./scripts/verify.sh"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-verify)
      shift
      run_verify="${1:-}"
      ;;
    --verify-command)
      shift
      verify_command="${1:-}"
      ;;
  esac
  shift || true
done
printf 'harness <%s> <%s>\n' "${run_verify}" "${verify_command}" >> "${FLOW_LOG:?}"
if [[ "${run_verify}" == "1" ]]; then
  printf 'harness-verify <%s>\n' "${verify_command}" >> "${FLOW_LOG:?}"
fi
EOF
cat > "${FIXTURE_ROOT}/scripts/verify_commit_push.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'outer-verify\n' >> "${FLOW_LOG:?}"
EOF
chmod +x \
  "${FIXTURE_ROOT}/scripts/codex_task_harness.sh" \
  "${FIXTURE_ROOT}/scripts/verify_commit_push.sh"

: > "${FLOW_LOG}"
(
  cd "${FIXTURE_ROOT}"
  "${isolated_fixture_env[@]}" FLOW_LOG="${FLOW_LOG}" \
    ./scripts/coding_agent.sh -m "chore: fixture (#0)" --title "fixture"
)
assert_line "harness <0> <./scripts/verify.sh>" "${FLOW_LOG}"
assert_line "outer-verify" "${FLOW_LOG}"
assert_absent "harness-verify" "${FLOW_LOG}"
assert_count 1 "outer-verify" "${FLOW_LOG}"

: > "${FLOW_LOG}"
(
  cd "${FIXTURE_ROOT}"
  "${isolated_fixture_env[@]}" FLOW_LOG="${FLOW_LOG}" \
    ./scripts/chat_task.sh --request "fixture request"
)
assert_line "harness <0> <./scripts/verify.sh>" "${FLOW_LOG}"
assert_count 1 "outer-verify" "${FLOW_LOG}"
assert_absent "harness-verify" "${FLOW_LOG}"

: > "${FLOW_LOG}"
(
  cd "${FIXTURE_ROOT}"
  "${isolated_fixture_env[@]}" FLOW_LOG="${FLOW_LOG}" \
    ./scripts/coding_agent.sh \
      -m "chore: fixture (#0)" \
      --title "fixture" \
      --harness-verify-command "./parent-review-gate.sh"
)
assert_line "harness-verify <./parent-review-gate.sh>" "${FLOW_LOG}"
assert_line "outer-verify" "${FLOW_LOG}"
harness_line="$(rg --line-number 'harness-verify' "${FLOW_LOG}" | cut -d: -f1)"
outer_line="$(rg --line-number 'outer-verify' "${FLOW_LOG}" | cut -d: -f1)"
(( harness_line < outer_line )) || fail "custom harness verification did not precede final verification"

: > "${FLOW_LOG}"
(
  cd "${FIXTURE_ROOT}"
  "${isolated_fixture_env[@]}" \
    FLOW_LOG="${FLOW_LOG}" \
    HARNESS_RUN_VERIFY=1 \
    HARNESS_VERIFY_COMMAND="./environment-review-gate.sh" \
    ./scripts/coding_agent.sh -m "chore: fixture (#0)" --title "fixture"
)
assert_line "harness-verify <./environment-review-gate.sh>" "${FLOW_LOG}"
assert_line "outer-verify" "${FLOW_LOG}"

: > "${FLOW_LOG}"
(
  cd "${FIXTURE_ROOT}"
  "${isolated_fixture_env[@]}" FLOW_LOG="${FLOW_LOG}" \
    ./scripts/coding_agent.sh \
      -m "chore: fixture (#0)" \
      --title "fixture" \
      --harness-verify-command "./ignored.sh" \
      --no-harness-verify
)
assert_absent "harness-verify" "${FLOW_LOG}"
assert_line "outer-verify" "${FLOW_LOG}"

WEB_WORKFLOW="${ROOT_DIR}/.github/workflows/web-pages.yml"
MOBILE_WORKFLOW="${ROOT_DIR}/.github/workflows/mobile-release.yml"
assert_count 1 "run: ./scripts/verify.sh" "${WEB_WORKFLOW}"
assert_absent "run: flutter test" "${WEB_WORKFLOW}"
assert_absent "run: flutter pub get" "${WEB_WORKFLOW}"
assert_absent "run: flutter gen-l10n" "${WEB_WORKFLOW}"
assert_line "          VERIFY_SCOPE: \${{ github.event_name == 'workflow_dispatch' && inputs.verification_scope || 'quick' }}" "${WEB_WORKFLOW}"
assert_line "          --no-pub" "${WEB_WORKFLOW}"
assert_count 1 "run: ./scripts/verify.sh" "${MOBILE_WORKFLOW}"
assert_absent "run: flutter test" "${MOBILE_WORKFLOW}"
assert_line "          VERIFY_SCOPE: full" "${MOBILE_WORKFLOW}"
assert_count 2 "            --no-pub \\" "${MOBILE_WORKFLOW}"

echo "[verify-profiles] ok"
