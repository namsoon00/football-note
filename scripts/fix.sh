#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> flutter pub get"
flutter pub get

echo "==> flutter gen-l10n"
flutter gen-l10n

echo "==> dart format"
dart format .

echo "==> flutter analyze"
if ! flutter analyze; then
  echo ""
  echo "Analyze failed. Please fix the reported issues manually."
  exit 1
fi

echo "==> flutter test"
if ! flutter test; then
  echo ""
  echo "Tests failed. Please fix failing tests manually."
  exit 1
fi
