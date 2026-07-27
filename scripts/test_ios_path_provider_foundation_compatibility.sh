#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

python3 - <<'PY'
import re
import sys
from pathlib import Path

lock = Path("pubspec.lock").read_text(encoding="utf-8")
pubspec = Path("pubspec.yaml").read_text(encoding="utf-8")

if not re.search(
    r"^  path_provider_foundation: 2\.5\.1$", pubspec, flags=re.MULTILINE
):
    sys.exit("path_provider_foundation must stay pinned to the plugin-based 2.5.1 release.")

package = re.search(
    r"^  path_provider_foundation:\n(?P<body>(?:    .*\n)+)",
    lock,
    flags=re.MULTILINE,
)
if package is None or 'version: "2.5.1"' not in package.group("body"):
    sys.exit("pubspec.lock must resolve path_provider_foundation 2.5.1.")

if re.search(r"^  objective_c:\n", lock, flags=re.MULTILINE):
    sys.exit("iOS path discovery must not pull in the objective_c native asset.")

print("[ios-path-provider-foundation] plugin compatibility lock passed")
PY
