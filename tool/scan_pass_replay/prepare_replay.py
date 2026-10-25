#!/usr/bin/env python3
"""Rebuild the bundled Scan Pass replay from pinned SkillCorner inputs."""

from pathlib import Path
import argparse
import csv
import gzip
import json
import math


parser = argparse.ArgumentParser()
parser.add_argument(
    "raw_dir",
    type=Path,
    help="Directory containing the four pinned upstream source files",
)
args = parser.parse_args()

repo = Path(__file__).resolve().parents[2]
output_dir = repo / "assets" / "scan_pass_replay"
manifest = json.loads((output_dir / "source-manifest.json").read_text())
raw_dir = args.raw_dir.resolve()

match = json.loads((raw_dir / "1925299_match.json").read_text())
with gzip.open(raw_dir / "sample_1925299_phase406.jsonl.gz", "rt") as stream:
    raw = [json.loads(line) for line in stream]

# Body-pose frames are 25 fps. Playing-time and event frames are 10 fps;
# multiplying those source frames by 2.5 is the authoritative alignment.
start_tracking_frame = raw[0]["frame"] / 2.5
players = [
    player
    for player in match["players"]
    if player.get("playing_time")
    and player["playing_time"].get("total")
    and player["playing_time"]["total"]["start_frame"]
    <= start_tracking_frame
    <= player["playing_time"]["total"]["end_frame"]
]
players.sort(
    key=lambda player: (
        player["team_id"] != match["home_team"]["id"],
        player["number"],
    )
)
assert len(players) == 22
player_ids = [player["id"] for player in players]
joints = [
    "nose",
    "neck",
    "lShoulder",
    "rShoulder",
    "lElbow",
    "rElbow",
    "lWrist",
    "rWrist",
    "lHip",
    "rHip",
    "lKnee",
    "rKnee",
    "lAnkle",
    "rAnkle",
    "lHeel",
    "rHeel",
    "lBigToe",
    "rBigToe",
]
frames = []
poses = []
max_xy_error = 0
for index, frame in enumerate(raw):
    by_id = {player["player_id"]: player for player in frame["player_data"]}
    xy = []
    for player_id in player_ids:
        player = by_id[player_id]
        assert all(
            isinstance(player[key], (int, float)) and math.isfinite(player[key])
            for key in ["x", "y"]
        )
        for key in ["x", "y"]:
            quantized = round(player[key] * 100)
            xy.append(quantized)
            max_xy_error = max(max_xy_error, abs(quantized / 100 - player[key]))
    ball = frame["ball_data"]
    frames.append(xy + [round(ball[key] * 100) for key in ["x", "y", "z"]])
    if index % 2 == 0:
        pose_row = []
        for player_id in player_ids:
            player = by_id[player_id]
            pose = player.get("joints")
            if not pose or any(joint not in pose for joint in joints):
                pose_row.append(None)
                continue
            values = []
            for joint in joints:
                xyz = pose[joint]["xyz"]
                values.extend(
                    [
                        round((xyz[0] - player["x"]) * 100),
                        round((xyz[1] - player["y"]) * 100),
                        round(xyz[2] * 100),
                    ]
                )
            pose_row.append(values)
        poses.append(pose_row)

events = []
with (raw_dir / "1925299_dynamic_events.csv").open() as stream:
    for event in csv.DictReader(stream):
        if event["event_type"] != "player_possession":
            continue
        start, end = float(event["frame_start"]), float(event["frame_end"])
        if start > raw[-1]["frame"] / 2.5 or end < start_tracking_frame:
            continue
        events.append(
            {
                key: event.get(key)
                for key in [
                    "event_id",
                    "player_id",
                    "player_name",
                    "player_targeted_id",
                    "player_targeted_name",
                    "end_type",
                    "pass_outcome",
                ]
            }
            | {
                "start": round((start * 2.5 - raw[0]["frame"]) / 25, 3),
                "end": round((end * 2.5 - raw[0]["frame"]) / 25, 3),
            }
        )

data = {
    "fps": 25,
    "poseStep": 2,
    "duration": (len(raw) - 1) / 25,
    "startClock": 77 * 60 + 34.48,
    "pitch": [105, 68],
    "match": {
        "id": match["id"],
        "date": "2024-12-21",
        "home": "Brisbane Roar",
        "away": "Perth Glory",
    },
    "players": [
        {
            "id": player["id"],
            "number": player["number"],
            "name": player["short_name"],
            "home": player["team_id"] == match["home_team"]["id"],
            "keeper": player["player_role"]["acronym"] == "GK",
        }
        for player in players
    ],
    "joints": joints,
    "frames": frames,
    "poses": poses,
    "events": events,
    "sourceCommit": manifest["commit"],
}
payload = json.dumps(data, ensure_ascii=False, separators=(",", ":"))
(output_dir / "replay-data.json").write_text(payload)
proof = {
    "frames": len(frames),
    "activePlayers": len(player_ids),
    "homePlayers": sum(
        player["team_id"] == match["home_team"]["id"] for player in players
    ),
    "awayPlayers": sum(
        player["team_id"] != match["home_team"]["id"] for player in players
    ),
    "poseFrames": len(poses),
    "poseObservations": sum(pose is not None for row in poses for pose in row),
    "durationSeconds": data["duration"],
    "fps": data["fps"],
    "poseStep": data["poseStep"],
    "maxPositionQuantizationErrorMeters": max_xy_error,
    "events": events,
    "sourceCommit": manifest["commit"],
}
print(json.dumps(proof, ensure_ascii=False, indent=2))
