#!/usr/bin/env python3
"""Rebuild the offline scene catalog from hash-verified, pinned SkillCorner data.

The curation file selects recorded intervals, never simulated routes. Source
coordinates are metres; the compact assets quantize them to centimetres.
"""

import argparse
import csv
import hashlib
import json
import math
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
ASSETS = REPO / "assets/scan_pass_replay"
COMMIT = "4340d274572876239c154c90bc507a9b3250a656"
SOURCE_URL = f"https://github.com/SkillCorner/opendata/tree/{COMMIT}"
JOINTS = [
    "nose", "neck", "lShoulder", "rShoulder", "lElbow", "rElbow",
    "lWrist", "rWrist", "lHip", "rHip", "lKnee", "rKnee",
    "lAnkle", "rAnkle", "lHeel", "rHeel", "lBigToe", "rBigToe",
]


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save(path, value, pretty=False):
    path.parent.mkdir(parents=True, exist_ok=True)
    text = json.dumps(
        value, ensure_ascii=False,
        **({"indent": 2} if pretty else {"separators": (",", ":")}),
    )
    path.write_text(text + ("\n" if pretty else ""), encoding="utf-8")


def verify_sources(raw_dir, manifest):
    if manifest["commit"] != COMMIT:
        raise ValueError("Unexpected source revision")
    for entry in manifest["files"]:
        name = Path(entry["path"]).name
        local = raw_dir / name
        # The tracking payload is the Git LFS object, not its pointer text.
        if name.endswith("_tracking_extrapolated.jsonl"):
            local = raw_dir / name.replace("_tracking_extrapolated", "_tracking")
        if not local.exists():
            raise ValueError(f"Missing source file: {local}")
        if local.stat().st_size != entry["bytes"] or digest(local) != entry["sha256"]:
            raise ValueError(f"Source hash mismatch: {local}")


def source_event(row, start_frame):
    fields = [
        "event_id", "player_id", "player_name", "player_targeted_id",
        "player_targeted_name", "end_type", "pass_outcome", "event_type",
        "event_subtype", "high_pass", "one_touch", "initiate_give_and_go",
        "overall_pressure_start", "overall_pressure_end", "last_line_break",
        "first_line_break", "second_last_line_break", "furthest_line_break_type",
        "received", "received_in_space", "lead_to_shot", "lead_to_goal",
        "phase_index", "team_id", "fully_extrapolated", "team_in_possession_phase_type",
    ]
    return {
        **{key: row.get(key) for key in fields},
        "start": round((int(row["frame_start"]) - start_frame) / 10, 3),
        "end": round((int(row["frame_end"]) - start_frame) / 10, 3),
    }


def number(row, name):
    value = row[name]
    if not isinstance(value, (int, float)) or not math.isfinite(value):
        raise ValueError(f"Missing/non-finite {name} in source frame")
    return value


def clock_seconds(timestamp):
    hours, minutes, seconds = timestamp.split(":")
    return round(int(hours) * 3600 + int(minutes) * 60 + float(seconds), 3)


def bounds_for(frames, players, focal_ids):
    indices = [i for i, p in enumerate(players) if p["id"] in focal_ids]
    xs, ys = [], []
    for row in frames[::10] + frames[-1:]:
        bx, by = row[-3] / 100, row[-2] / 100
        xs.append(bx)
        ys.append(by)
        # Include the support/defensive shape near the action, not only the ball.
        nearest = sorted(
            [i for i, p in enumerate(players) if not p["keeper"]],
            key=lambda i: (row[i * 2] / 100 - bx) ** 2
            + (row[i * 2 + 1] / 100 - by) ** 2,
        )[:10]
        for i in set(indices + nearest):
            xs.append(row[i * 2] / 100)
            ys.append(row[i * 2 + 1] / 100)
    def extent(values, minimum, limit):
        low, high = min(values) - 8, max(values) + 8
        width = min(limit * 2, max(minimum, high - low))
        centre = max(-limit + width / 2, min(limit - width / 2, (low + high) / 2))
        return [round(centre - width / 2, 2), round(centre + width / 2, 2)]
    # Keep the actual ball visible even when the sequence ends out of play.
    x_limit = max(55, max(abs(row[-3] / 100) for row in frames) + 4)
    y_limit = max(36, max(abs(row[-2] / 100) for row in frames) + 4)
    return extent(xs, 74, x_limit) + extent(ys, 54, y_limit)


def scene_steps(spec, rows, players, frames):
    start, end = spec["startFrame"], spec["endFrame"]
    duration = (end - start) / 10
    by_id = {r["event_id"]: r for r in rows}
    primary = by_id[spec["eventId"]]
    actor = int(primary["player_id"])
    active = {p["id"] for p in players}
    result = [dict(time=0, kind="observe", actorId=actor, eventId=spec["eventId"])]
    focal = {actor}
    target = primary["player_targeted_id"]
    if target and int(target) in active:
        focal.add(int(target))
        result[0]["targetId"] = int(target)
    run = by_id.get(spec.get("runId"))
    if run:
        runner = int(run["player_id"])
        if runner not in active or run["event_type"] != "off_ball_run":
            raise ValueError("Invalid curated off-ball run")
        focal.add(runner)
        result.append(dict(
            time=max(.1, (int(run["frame_start"]) - start) / 10),
            kind="run", actorId=runner, targetId=actor,
            eventId=run["event_id"], runType=run["event_subtype"],
            end=round((int(run["frame_end"]) - start) / 10, 3),
        ))
    possessions = [
        r for r in rows if r["event_type"] == "player_possession"
        and start <= int(r["frame_start"]) < end
        and int(r["player_id"]) in active
    ]
    primary_index = next(i for i, r in enumerate(possessions) if r["event_id"] == spec["eventId"])
    # Keep the coaching rhythm readable. All source possessions stay in events,
    # but only the focal action and first receiving action become chapters.
    coaching_rows = possessions[primary_index:primary_index + 2]
    for row in coaching_rows:
        a, b = int(row["frame_start"]), int(row["frame_end"])
        pid = int(row["player_id"])
        at = (a - start) / 10
        carrying = row["carry"] == "True" and b - a >= 15
        if at > .5 and not carrying:
            result.append(dict(time=at, kind="receive", actorId=pid, eventId=row["event_id"]))
        if carrying and at < duration:
            result.append(dict(
                time=round(max(.1, at), 3), kind="carry",
                actorId=pid, eventId=row["event_id"], end=min(duration, (b - start) / 10),
            ))
        if row["end_type"] == "pass" and b < end:
            step = dict(
                time=round((b - start) / 10, 3), kind="pass", actorId=pid,
                eventId=row["event_id"],
            )
            if row["player_targeted_id"] and int(row["player_targeted_id"]) in active:
                step["targetId"] = int(row["player_targeted_id"])
            result.append(step)
    # All outcome copy describes the recorded segment, not whether a decision
    # was optimal. Include turnovers as well as continuing passes and shots.
    team_rows = [
        r for r in possessions if r["team_id"] == primary["team_id"]
        and int(r["frame_end"]) <= end
    ]
    shots = [r for r in team_rows if r["end_type"] == "shot" and int(r["frame_end"]) <= end]
    losses = [
        r for r in team_rows if int(r["frame_end"]) <= end
        and (r["end_type"] == "possession_loss" or r["pass_outcome"] == "unsuccessful")
    ]
    takeover = next((
        r for r in possessions
        if r["team_id"] != primary["team_id"]
        and int(r["frame_start"]) > int(primary["frame_end"])
    ), None)
    takeover_time = None
    if shots:
        outcome_row, outcome = shots[-1], "shot"
    elif losses and int(losses[-1]["frame_end"]) >= int(primary["frame_end"]):
        outcome_row, outcome = losses[-1], "lost"
    elif takeover is not None:
        outcome_row, outcome = takeover, "lost"
        takeover_time = (int(takeover["frame_start"]) - start) / 10
    else:
        outcome_row = team_rows[-1] if team_rows else primary
        outcome = "kept" if outcome_row["pass_outcome"] == "successful" else "end"
    outcome_time = max(0, min(
        duration - .1,
        (takeover_time if takeover_time is not None else (int(outcome_row["frame_end"]) - start) / 10)
        + (1.8 if outcome == "kept" else .2),
    ))
    # Remove later generic labels which could obscure the segment outcome.
    result = [s for s in result if s["time"] < outcome_time]
    result.append(dict(
        time=round(outcome_time, 3), kind="outcome",
        actorId=int(outcome_row["player_id"]), eventId=outcome_row["event_id"],
    ))
    # Dense one-touch events can have reception and release at the same time.
    # Release takes priority and exact source time remains unchanged.
    unique = {}
    priority = {"observe": 0, "receive": 1, "carry": 2, "run": 3, "pass": 4, "outcome": 5}
    for step in result:
        key = round(step["time"], 3)
        if key not in unique or priority[step["kind"]] > priority[unique[key]["kind"]]:
            unique[key] = step
    steps = [unique[key] for key in sorted(unique) if 0 <= key < duration]
    if not steps or steps[0]["time"] != 0:
        raise ValueError("Scene must begin with observation")
    return steps, outcome, focal


def build_scene(spec, match, rows, raw_frames):
    start, end = spec["startFrame"], spec["endFrame"]
    roster = [
        p for p in match["players"]
        if p.get("playing_time") and p["playing_time"].get("total")
        and p["playing_time"]["total"]["start_frame"] <= start
        and p["playing_time"]["total"]["end_frame"] >= end
    ]
    roster.sort(key=lambda p: (p["team_id"] != match["home_team"]["id"], p["number"]))
    if len(roster) != 22:
        raise ValueError("Curated interval must retain a complete stable active roster")
    players = [
        dict(id=p["id"], number=p["number"], name=p["short_name"],
             home=p["team_id"] == match["home_team"]["id"],
             keeper=p["player_role"]["acronym"] == "GK")
        for p in roster
    ]
    frames, error = [], 0
    detected, all_observations = 0, 0
    for frame_id in range(start, end + 1):
        raw = raw_frames[frame_id]
        if raw["period"] != spec["period"]:
            raise ValueError("Scene crosses source period")
        by_id = {p["player_id"]: p for p in raw["player_data"]}
        row = []
        for player in players:
            source = by_id[player["id"]]
            detected += source.get("is_detected") is True
            all_observations += 1
            for key in ("x", "y"):
                value = number(source, key)
                cm = round(value * 100)
                error = max(error, abs(cm / 100 - value))
                row.append(cm)
        for key in ("x", "y", "z"):
            row.append(round(number(raw["ball_data"], key) * 100))
        frames.append(row)
    period = spec["period"]
    home = next(r for r in rows if r["event_id"] == spec["eventId"])["team_id"] == str(match["home_team"]["id"])
    home_direction = match["home_team_side"][period - 1]
    direction = 1 if (home_direction == "left_to_right") == home else -1
    steps, outcome, focal = scene_steps(spec, rows, players, frames)
    metadata = {
        **{k: spec[k] for k in ("id", "category", "titleKey", "focusKey")},
        "homeColor": match["home_team_kit"]["jersey_color"],
        "awayColor": match["away_team_kit"]["jersey_color"],
        "homeNumberColor": match["home_team_kit"]["number_color"],
        "awayNumberColor": match["away_team_kit"]["number_color"],
        "attackDirection": direction,
        "focusPlayerId": int(next(r for r in rows if r["event_id"] == spec["eventId"])["player_targeted_id"]
                             or next(r for r in rows if r["event_id"] == spec["eventId"])["player_id"]),
        "camera": bounds_for(frames, players, focal),
        "steps": steps, "outcome": outcome,
    }
    data = dict(
        fps=10, poseStep=1, duration=(end - start) / 10,
        startClock=clock_seconds(raw_frames[start]["timestamp"]),
        pitch=[match["pitch_length"], match["pitch_width"]],
        match=dict(id=match["id"], date=match["date_time"][:10],
                   home=match["home_team"]["short_name"],
                   away=match["away_team"]["short_name"]),
        players=players, joints=JOINTS, frames=frames, poses=[],
        events=[
            source_event(r, start) for r in rows
            if (r["event_type"] == "player_possession" or r["event_id"] == spec.get("runId"))
            and int(r["frame_start"]) <= end and int(r["frame_end"]) >= start
        ],
        sourceCommit=COMMIT, sourceFrameStart=start, period=period, scene=metadata,
    )
    proof = dict(
        id=spec["id"], matchId=match["id"], sourceStartFrame=start,
        sourceEndFrame=end, frames=len(frames), activePlayers=len(players),
        fps=10, durationSeconds=data["duration"], poseObservations=0,
        detectedObservations=detected, totalObservations=all_observations,
        maxPositionQuantizationErrorMeters=round(error, 8),
        primaryEvent=spec["eventId"],
        primaryRun=spec.get("runId"),
        stepEventIds=sorted({s["eventId"] for s in steps}),
        attackDirection=direction,
    )
    return data, proof


def original_scene(spec):
    data = read_json(ASSETS / "replay-data.json")
    data["sourceFrameStart"] = 124487
    data["period"] = 2
    data["scene"] = {
        **{k: spec[k] for k in ("id", "category", "titleKey", "focusKey")},
        "homeColor": "#ff8000", "awayColor": "#ffffff",
        "homeNumberColor": "#ffffff", "awayNumberColor": "#000000",
        "attackDirection": 1, "focusPlayerId": 965698,
        "camera": bounds_for(data["frames"], data["players"], {287934, 965698, 11897, 795533}),
        "steps": [
            dict(time=0, kind="observe", actorId=287934, targetId=965698, eventId="8_870"),
            dict(time=.6, kind="run", actorId=965698, targetId=287934),
            dict(time=2.42, kind="pass", actorId=287934, targetId=965698, eventId="8_870"),
            dict(time=4.22, kind="receive", actorId=965698, eventId="8_871"),
            dict(time=5, kind="carry", actorId=965698, secondaryId=11897, eventId="8_871"),
            dict(time=8, kind="pressure", actorId=965698, secondaryId=795533, eventId="8_871"),
            dict(time=11.22, kind="outcome", actorId=965698, secondaryId=560985, eventId="8_871"),
        ],
        "outcome": "shot",
    }
    return data, dict(
        id=spec["id"], matchId=1925299, sourceStartFrame=124487,
        sourceEndFrame=124795, frames=309, activePlayers=22, fps=25,
        durationSeconds=12.32,
        poseObservations=sum(p is not None for row in data["poses"] for p in row),
        maxPositionQuantizationErrorMeters=.004, primaryEvent="8_870",
        primaryRun=None, stepEventIds=["8_870", "8_871"], attackDirection=1,
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("raw_dir", type=Path)
    args = parser.parse_args()
    raw_dir = args.raw_dir.resolve()
    manifest = read_json(ASSETS / "source-manifest.json")
    verify_sources(raw_dir, manifest)
    specs = read_json(Path(__file__).with_name("scenes.json"))
    built, proofs = {}, []
    for mid in sorted({s["matchId"] for s in specs if not s.get("original")}):
        selected = [s for s in specs if s.get("matchId") == mid]
        match = read_json(raw_dir / f"{mid}_match.json")
        with (raw_dir / f"{mid}_dynamic_events.csv").open() as stream:
            rows = list(csv.DictReader(stream))
        raw = {}
        with (raw_dir / f"{mid}_tracking.jsonl").open() as stream:
            for line in stream:
                frame = json.loads(line)
                n = frame["frame"]
                if any(s["startFrame"] <= n <= s["endFrame"] for s in selected):
                    raw[n] = frame
        for spec in selected:
            built[spec["id"]] = build_scene(spec, match, rows, raw)
    catalog = dict(
        version=1, sourceCommit=COMMIT, sourceUrl=SOURCE_URL, scenes=[]
    )
    derived = []
    for spec in specs:
        data, proof = original_scene(spec) if spec.get("original") else built[spec["id"]]
        path = ASSETS / "scenes" / f'{spec["id"]}.json'
        save(path, data)
        relative = path.relative_to(REPO).as_posix()
        entry = dict(
            **{k: spec[k] for k in ("id", "category", "titleKey", "focusKey")},
            asset=relative, matchId=data["match"]["id"], date=data["match"]["date"],
            home=data["match"]["home"], away=data["match"]["away"],
            startClock=data["startClock"], duration=data["duration"],
            hasPose=any(p is not None for row in data["poses"] for p in row),
        )
        catalog["scenes"].append(entry)
        proof["asset"] = relative
        proof["sha256"] = digest(path)
        proofs.append(proof)
        derived.append(dict(path=relative, bytes=path.stat().st_size, sha256=digest(path)))
    historical_catalog_path = ASSETS / "historical-catalog.json"
    if historical_catalog_path.exists():
        historical_catalog = read_json(historical_catalog_path)
        if historical_catalog.get("sourceCommit") != (
            "1ed50b775f93075c2a6d00d0d795f13b7b89709e"
        ):
            raise ValueError("Unexpected historical catalog revision")
        historical_ids = {entry["id"] for entry in historical_catalog["scenes"]}
        if historical_ids & {entry["id"] for entry in catalog["scenes"]}:
            raise ValueError("Historical catalog duplicates a current scene id")
        catalog["scenes"] = historical_catalog["scenes"] + catalog["scenes"]
    save(ASSETS / "catalog.json", catalog)
    save(ASSETS / "catalog-proof.json", dict(sourceCommit=COMMIT, scenes=proofs), pretty=True)
    mixed_proof = {
        "catalog": {
            "path": "assets/scan_pass_replay/catalog.json",
            "bytes": (ASSETS / "catalog.json").stat().st_size,
            "sha256": digest(ASSETS / "catalog.json"),
        },
        "sourceCommits": sorted(
            {entry.get("sourceCommit", COMMIT) for entry in catalog["scenes"]}
        ),
        "sceneCount": len(catalog["scenes"]),
        "scenes": [
            {
                "id": entry["id"],
                "sourceCommit": entry.get("sourceCommit", COMMIT),
                "asset": entry["asset"],
                "sha256": digest(REPO / entry["asset"]),
            }
            for entry in catalog["scenes"]
        ],
    }
    save(ASSETS / "mixed-catalog-proof.json", mixed_proof, pretty=True)
    for name in ("catalog.json", "catalog-proof.json", "mixed-catalog-proof.json"):
        path = ASSETS / name
        derived.append(dict(path=path.relative_to(REPO).as_posix(), bytes=path.stat().st_size, sha256=digest(path)))
    manifest["derivedAssets"] = derived
    manifest["matchIds"] = sorted({s["matchId"] for s in specs if not s.get("original")})
    save(ASSETS / "source-manifest.json", manifest, pretty=True)
    print(f'Rebuilt {len(specs)} current scenes from {len(manifest["matchIds"])} matches.')
    print(f'Mixed catalog contains {len(catalog["scenes"])} scenes.')
    print(f'Total scene payload: {sum(p["bytes"] for p in derived)} bytes.')


if __name__ == "__main__":
    main()
