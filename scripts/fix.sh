#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> dart format"
dart format .

echo "==> quick prelaunch verification"
./scripts/verify.sh
