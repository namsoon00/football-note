#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

python3 - <<'PY'
from html.parser import HTMLParser
from pathlib import Path
import sys
from typing import List, Optional, Tuple

root = Path("assets/running_coach_3d_runner")
runner = root / "runner.js"
html = root / "runner.html"
model = root / "models/reference_runner.glb"
three = root / "vendor/three.module.js"
three_core = root / "vendor/three.core.js"
loader = root / "vendor/loaders/GLTFLoader.js"
skeleton_utils = root / "vendor/utils/SkeletonUtils.js"
buffer_utils = root / "vendor/utils/BufferGeometryUtils.js"
notice = root / "THIRD_PARTY_NOTICES.md"
pubspec = Path("pubspec.yaml")

failures: list[str] = []


def require(condition: bool, message: str) -> None:
    if not condition:
        failures.append(message)


class RunnerHTMLParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.scripts: List[str] = []
        self.canvas_ids: List[str] = []

    def handle_starttag(self, tag: str, attrs: List[Tuple[str, Optional[str]]]) -> None:
        attr_map = dict(attrs)
        if tag == "script" and attr_map.get("src"):
            self.scripts.append(attr_map["src"] or "")
        if tag == "canvas" and attr_map.get("id"):
            self.canvas_ids.append(attr_map["id"] or "")


for path, label in (
    (runner, "3D runner JavaScript asset"),
    (html, "3D runner HTML asset"),
    (model, "rigged reference runner GLB"),
    (three, "bundled Three.js runtime"),
    (three_core, "bundled Three.js core runtime"),
    (loader, "bundled GLTF loader"),
    (skeleton_utils, "bundled GLTF skeleton utility"),
    (buffer_utils, "bundled buffer geometry utility"),
    (notice, "third-party asset notice"),
):
    require(path.is_file(), f"{label} is missing")

if runner.is_file() and html.is_file():
    runner_text = runner.read_text()
    html_text = html.read_text()
    parser = RunnerHTMLParser()
    parser.feed(html_text)

    require("scene" in parser.canvas_ids, "Renderer HTML must expose the WebGL canvas")
    require(
        len(parser.scripts) == 1 and parser.scripts[0].startswith("runner.js"),
        "Renderer HTML must load only local runner.js",
    )
    require('type="module"' in html_text, "Renderer HTML must load the renderer as a module")
    require("three.module.js" in html_text, "Renderer HTML must map local Three.js")
    require("is-single" in html_text, "Renderer HTML must support a single current-pose layout")
    require("http://" not in html_text and "https://" not in html_text, "Renderer HTML must not load network resources")
    require(
        "payload.status === 'good'" not in runner_text,
        "Renderer must not hide the target motion when a metric is already good",
    )

    for required in (
        "WebGLRenderer",
        "GLTFLoader",
        "reference_runner.glb",
        "OrthographicCamera",
        "applyMeasuredFramePose(",
        "applyPoseCorrection(",
        "selectedRig(",
        "shouldShowComparison(",
        "rigForMeasuredPlayback(",
        "interpolateMeasuredRig(",
        "controlledPlaybackProgress(",
        "MEASURED_PLAYBACK_SPEED",
        "copy.transparent = false",
        "copy.depthWrite = true",
        "registerBone(",
        "setBoneWorldDirection(",
        "guidePositionForRig(",
        "updateGuides(",
        "boneCorrections",
        "mixamorig:LeftUpLeg",
        "mixamorig:RightArm",
        "renderer.setScissor",
        "window.runningThreeDRunnerSetPayload",
        "focusIndices",
    ):
        require(required in runner_text, f"Rigged renderer is missing required token: {required}")

    for retired in (
        "getContext('2d'",
        'getContext("2d"',
        "CanvasRenderingContext2D",
        "createSphereMesh",
        "drawTaperedSegment",
        "drawTorso(",
        "drawRunnerHead(",
        "drawShoe(",
        "procedural-webgl-runner-v1",
        "applyNaturalRunCycle(",
        "rigForTime(",
        "interpolateRig(",
        "startTime",
        "Math.sin(",
        "cdn",
        "http://",
        "https://",
    ):
        require(retired not in runner_text, f"Renderer must not retain retired token: {retired}")

if model.is_file():
    require(model.stat().st_size > 1_000_000, "Reference runner GLB is unexpectedly small")

if pubspec.is_file():
    pubspec_text = pubspec.read_text()
    for asset_path in (
        "assets/running_coach_3d_runner/models/reference_runner.glb",
        "assets/running_coach_3d_runner/vendor/three.module.js",
        "assets/running_coach_3d_runner/vendor/three.core.js",
        "assets/running_coach_3d_runner/vendor/loaders/GLTFLoader.js",
        "assets/running_coach_3d_runner/vendor/utils/BufferGeometryUtils.js",
        "assets/running_coach_3d_runner/vendor/utils/SkeletonUtils.js",
    ):
        require(asset_path in pubspec_text, f"Release bundle must include nested runner asset: {asset_path}")

if failures:
    print("3D runner renderer contract check failed:", file=sys.stderr)
    for failure in failures:
        print(f"- {failure}", file=sys.stderr)
    sys.exit(1)

print("3D runner renderer contract check passed")
PY

if command -v node >/dev/null 2>&1; then
  node --input-type=module --check < assets/running_coach_3d_runner/runner.js
else
  echo "[running-3d-runner-renderer] node unavailable; skipped JavaScript parse check" >&2
fi
