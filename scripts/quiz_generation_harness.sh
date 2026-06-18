#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

flutter test test/quality/quiz_generation_harness_test.dart
echo "quiz generation report: build/reports/quiz_generation_harness.md"
