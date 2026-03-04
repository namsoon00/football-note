#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> flutter pub get"
flutter pub get

echo "==> flutter gen-l10n"
flutter gen-l10n

echo "==> flutter analyze"
flutter analyze

echo "==> flutter test"
flutter test

echo "==> launch iOS simulator"
flutter emulators --launch apple_ios_simulator

SIM_ID=$(flutter devices | rg "simulator" | head -n1 | awk -F '•' '{print $2}' | xargs)
if [[ -z "${SIM_ID}" ]]; then
  echo "No iOS simulator found. Aborting."
  exit 1
fi

echo "==> flutter run (iOS simulator: ${SIM_ID})"
flutter run -d "${SIM_ID}" --no-resident
