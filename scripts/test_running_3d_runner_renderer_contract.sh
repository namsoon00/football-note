#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

python3 - <<'PY'
from html.parser import HTMLParser
from pathlib import Path
import sys
from typing import List, Optional, Tuple

runner = Path("assets/running_coach_3d_runner/runner.js")
html = Path("assets/running_coach_3d_runner/runner.html")

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


require(runner.is_file(), "3D runner JavaScript asset is missing")
require(html.is_file(), "3D runner HTML asset is missing")

runner_text = runner.read_text()
html_text = html.read_text()

parser = RunnerHTMLParser()
parser.feed(html_text)

require("scene" in parser.canvas_ids, "Renderer HTML must expose the WebGL canvas")
require(parser.scripts == ["runner.js"], "Renderer HTML must load only local runner.js")
require("http://" not in html_text and "https://" not in html_text, "Renderer HTML must not load network resources")

for required in (
    "canvas.getContext('webgl'",
    "window.runningThreeDRunnerSetPayload",
    "cameraForRig(",
    "runnerBounds(",
    "requiredWidth",
    "requiredHeight",
    "drawTaperedSegment(",
    "taperedMeshCache",
    "drawTorso(",
    "drawRunnerHead(",
    "drawArm(",
    "drawLeg(",
    "drawShoe(",
    "drawFootShadow(",
    "leftEar",
    "rightEar",
    "mouthLeft",
    "uCameraPosition",
    "uLightDirection",
):
    require(required in runner_text, f"Renderer is missing required token: {required}")

for retired in (
    "getContext('2d'",
    'getContext("2d"',
    "CanvasRenderingContext2D",
    "drawJointHalo",
    "THREE.",
    "cdn",
    "http://",
    "https://",
):
    require(retired not in runner_text, f"Renderer must not retain token: {retired}")

if failures:
    print("3D runner renderer contract check failed:", file=sys.stderr)
    for failure in failures:
        print(f"- {failure}", file=sys.stderr)
    sys.exit(1)

print("3D runner renderer contract check passed")
PY

if command -v node >/dev/null 2>&1; then
  node --check assets/running_coach_3d_runner/runner.js
else
  echo "[running-3d-runner-renderer] node unavailable; skipped JavaScript parse check" >&2
fi
