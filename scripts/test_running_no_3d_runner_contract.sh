#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

python3 - <<'PY'
from pathlib import Path
import sys

failures: list[str] = []

for path in (
    Path("assets/running_coach_3d_runner"),
    Path("assets/assets/running_coach_3d_runner"),
    Path("ios/Runner/RunningThreeDRunnerView.swift"),
    Path("lib/presentation/running_coach/running_three_d_runner.dart"),
    Path("lib/presentation/running_coach/running_three_d_runner_view.dart"),
):
    if path.exists():
        failures.append(f"Removed running 3D path still exists: {path}")

blocked_tokens = (
    "running_coach_3d_runner",
    "running_three_d_runner",
    "RunningThreeDRunner",
    "runningThreeDRunner",
    "football_note/running_3d_runner",
    "reference_runner.glb",
    "three.module.js",
    "GLTFLoader",
    "WebGLRenderer",
)

scan_roots = [
    Path("lib"),
    Path("test"),
    Path("ios/Runner"),
    Path("android/app/src/main"),
    Path("web"),
    Path("scripts"),
    Path(".github"),
]
for root in scan_roots:
    if not root.exists():
        continue
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if path == Path("scripts/test_running_no_3d_runner_contract.sh"):
            continue
        if path.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp", ".task", ".mp4", ".bin"}:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for token in blocked_tokens:
            if token in text:
                failures.append(f"{path} still contains removed 3D token: {token}")

pubspec = Path("pubspec.yaml").read_text(encoding="utf-8")
for token in blocked_tokens:
    if token in pubspec:
        failures.append(f"pubspec.yaml still bundles removed 3D token: {token}")

build_manifest = Path("build/web/assets/AssetManifest.json")
if build_manifest.exists():
    manifest = build_manifest.read_text(encoding="utf-8", errors="ignore")
    for token in blocked_tokens:
        if token in manifest:
            failures.append(f"release web asset manifest still contains removed 3D token: {token}")

if failures:
    print("Running 3D removal contract failed:", file=sys.stderr)
    for failure in failures:
        print(f"- {failure}", file=sys.stderr)
    sys.exit(1)

print("Running 3D removal contract passed")
PY
