#!/usr/bin/env python3
"""Build honest source and continuous display replay layers.

Historic SkillCorner tracking is a JSON array at 10 fps. It does not contain
dynamic event annotations or extrapolated off-camera players, so this importer
preserves missing observations in a sparse source layer. A separate,
provenance-marked display layer keeps the active 22 visible without promoting
reconstructed coordinates to evidence.
"""

from __future__ import annotations

import argparse
import bisect
import hashlib
import json
import math
import statistics
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
ASSETS = REPO / "assets/scan_pass_replay"
SPEC_PATH = Path(__file__).with_name("historical_scenes.json")
MANIFEST_PATH = ASSETS / "historical-source-manifest.json"
HISTORICAL_COMMIT = "1ed50b775f93075c2a6d00d0d795f13b7b89709e"
CURRENT_COMMIT = "4340d274572876239c154c90bc507a9b3250a656"
CURRENT_SOURCE_URL = (
    "https://github.com/SkillCorner/opendata/tree/"
    "4340d274572876239c154c90bc507a9b3250a656"
)
HISTORICAL_SOURCE_ROOT = (
    "https://github.com/SkillCorner/opendata/tree/"
    "1ed50b775f93075c2a6d00d0d795f13b7b89709e"
)
JOINTS = [
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
CONTEXT_RADIUS_FRAMES = 600
CONTINUATION_DECAY_SECONDS = 1.2
MAX_CONTINUATION_SPEED = 7.0
DISPLAY_CAMERA_MARGIN_METERS = 2.0


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def save(path: Path, value, *, pretty: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    options = {"indent": 2} if pretty else {"separators": (",", ":")}
    text = json.dumps(value, ensure_ascii=False, **options)
    path.write_text(text + ("\n" if pretty else ""), encoding="utf-8")


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def asset_record(path: Path) -> dict:
    return {
        "path": path.relative_to(REPO).as_posix(),
        "bytes": path.stat().st_size,
        "sha256": digest(path),
    }


def number(value, label: str) -> float:
    if not isinstance(value, (int, float)) or not math.isfinite(value):
        raise ValueError(f"Missing/non-finite {label}")
    return float(value)


def clock_seconds(value: str) -> float:
    parts = [float(part) for part in value.split(":")]
    if len(parts) == 2:
        minute, second = parts
        return round(minute * 60 + second, 2)
    if len(parts) == 3:
        hour, minute, second = parts
        return round(hour * 3600 + minute * 60 + second, 2)
    raise ValueError(f"Invalid match clock: {value}")


def verify_sources(raw_dir: Path, manifest: dict) -> None:
    if manifest.get("commit") != HISTORICAL_COMMIT:
        raise ValueError("Unexpected historical source revision")
    for entry in manifest["files"]:
        path = raw_dir / entry["path"]
        if not path.is_file():
            raise ValueError(f"Missing historical source file: {path}")
        if path.stat().st_size != entry["bytes"] or digest(path) != entry["sha256"]:
            raise ValueError(f"Historical source hash mismatch: {path}")


def full_name(player: dict) -> str:
    return " ".join(
        part for part in (player.get("first_name", ""), player["last_name"]) if part
    )


def team_group(match: dict, player: dict) -> str:
    return "home team" if player["team_id"] == match["home_team"]["id"] else "away team"


def anonymous_id(track_id: int) -> int:
    return -(1_000_000 + abs(track_id))


def source_url(manifest: dict, match_id: int) -> str:
    suffix = f"data/matches/{match_id}/structured_data.json"
    # Keep the exact raw download in the manifest, while the user-facing link
    # opens the browsable match directory instead of a 55–69 MB JSON document.
    if not any(entry["path"] == suffix for entry in manifest["files"]):
        raise ValueError(f"Historical source is not pinned for match {match_id}")
    return f"{HISTORICAL_SOURCE_ROOT}/data/matches/{match_id}"


def verify_possession_evidence(spec: dict, source_frames: list[dict]) -> None:
    for evidence in spec["possessionEvidence"]:
        for frame_number in range(evidence["startFrame"], evidence["endFrame"] + 1):
            frame = source_frames[frame_number]
            if frame["possession"].get("trackable_object") != evidence["trackableObject"]:
                raise ValueError(
                    f"Possession evidence mismatch for {spec['id']} at {frame_number}"
                )


def goalkeeper_direction(match: dict, source_frames: list[dict], period: int) -> tuple[int, dict]:
    home_id = match["home_team"]["id"]
    starters = [
        player
        for player in match["players"]
        if player["player_role"]["acronym"] == "GK"
        and player.get("start_time") == "00:00:00"
    ]
    if len(starters) != 2:
        raise ValueError("Expected two starting goalkeepers")
    medians = {}
    for keeper in starters:
        xs = [
            number(item.get("x"), "goalkeeper x")
            for frame in source_frames
            if frame["period"] == period
            for item in frame["data"]
            if item.get("trackable_object") == keeper["trackable_object"]
        ]
        if not xs:
            raise ValueError("Goalkeeper direction cannot be established")
        medians[keeper["trackable_object"]] = statistics.median(xs)
    home_keeper = next(player for player in starters if player["team_id"] == home_id)
    away_keeper = next(player for player in starters if player["team_id"] != home_id)
    home_median = medians[home_keeper["trackable_object"]]
    away_median = medians[away_keeper["trackable_object"]]
    if abs(home_median - away_median) < 50:
        raise ValueError("Goalkeeper medians do not establish opposing ends")
    direction = 1 if home_median < away_median else -1
    proof = {
        "method": "opposite starting-goalkeeper period medians",
        "homeGoalkeeperTrackableObject": home_keeper["trackable_object"],
        "homeMedianX": round(home_median, 4),
        "awayGoalkeeperTrackableObject": away_keeper["trackable_object"],
        "awayMedianX": round(away_median, 4),
        "homeAttackDirection": direction,
    }
    return direction, proof


def active_players(match: dict, interval: list[dict]) -> list[dict]:
    start_clock = clock_seconds(interval[0]["time"])
    end_clock = clock_seconds(interval[-1]["time"])

    def active_at(player: dict, clock: float) -> bool:
        start = player.get("start_time")
        end = player.get("end_time")
        return (
            start is not None
            and clock_seconds(start) <= clock
            and (end is None or clock < clock_seconds(end))
        )

    at_start = {
        player["trackable_object"]
        for player in match["players"]
        if active_at(player, start_clock)
    }
    at_end = {
        player["trackable_object"]
        for player in match["players"]
        if active_at(player, end_clock)
    }
    if at_start != at_end or len(at_start) != 22:
        raise ValueError("Selected clip must retain one active 22-player roster")
    home_id = match["home_team"]["id"]
    active = [
        player
        for player in match["players"]
        if player["trackable_object"] in at_start
    ]
    active.sort(
        key=lambda player: (
            player["team_id"] != home_id,
            player["number"],
            player["trackable_object"],
        )
    )
    if sum(player["team_id"] == home_id for player in active) != 11:
        raise ValueError("Active roster must contain 11 players per team")
    return active


def resolve_entities(
    match: dict,
    interval: list[dict],
    resolution_frames: list[dict],
    active: list[dict],
) -> tuple[list[dict], dict[int, int], dict]:
    metadata = {player["trackable_object"]: player for player in match["players"]}
    track_mappings: dict[int, set[int]] = {}
    anonymous_groups: dict[int, set[str]] = {}
    for frame in resolution_frames:
        for item in frame["data"]:
            track_id = item.get("track_id")
            trackable = item.get("trackable_object")
            if not isinstance(track_id, int):
                continue
            if trackable in metadata:
                track_mappings.setdefault(track_id, set()).add(trackable)
            elif trackable is None and item.get("group_name") in {
                "home team",
                "away team",
            }:
                anonymous_groups.setdefault(track_id, set()).add(item["group_name"])

    resolutions: dict[int, int] = {}
    for track_id, groups in anonymous_groups.items():
        candidates = track_mappings.get(track_id, set())
        if len(candidates) != 1 or len(groups) != 1:
            continue
        trackable = next(iter(candidates))
        if team_group(match, metadata[trackable]) == next(iter(groups)):
            resolutions[track_id] = trackable

    unresolved: dict[int, str] = {}
    for frame in interval:
        for item in frame["data"]:
            if item.get("trackable_object") is None and item.get("group_name") in {
                "home team",
                "away team",
            }:
                track_id = item.get("track_id")
                if not isinstance(track_id, int):
                    raise ValueError("Anonymous team observation has no integer track id")
                if track_id not in resolutions:
                    unresolved[track_id] = item["group_name"]

    home_id = match["home_team"]["id"]

    players = [
        {
            "id": value["trackable_object"],
            "number": value["number"],
            "name": full_name(value),
            "home": value["team_id"] == home_id,
            "keeper": value["player_role"]["acronym"] == "GK",
        }
        for value in active
    ]
    index_by_entity = {player["id"]: index for index, player in enumerate(players)}
    resolution_proof = {
        "resolvedTrackIds": [
            {"trackId": track_id, "trackableObject": trackable}
            for track_id, trackable in sorted(resolutions.items())
        ],
        "unresolvedTracks": [
            {
                "trackId": track_id,
                "group": group,
            }
            for track_id, group in sorted(unresolved.items())
        ],
    }
    return players, index_by_entity, resolution_proof


def entity_for_item(
    item: dict,
    metadata: dict[int, dict],
    resolutions: dict[int, int],
) -> int | None:
    trackable = item.get("trackable_object")
    if trackable in metadata:
        return trackable
    if trackable is not None or item.get("group_name") not in {
        "home team",
        "away team",
    }:
        return None
    track_id = item.get("track_id")
    if not isinstance(track_id, int):
        raise ValueError("Anonymous team observation has no integer track id")
    return resolutions.get(track_id, anonymous_id(track_id))


def observations_by_entity(
    source_frames: list[dict],
    period: int,
    entity_ids: set[int],
    metadata: dict[int, dict],
    resolutions: dict[int, int],
) -> dict[int, dict[int, tuple[int, int]]]:
    observations: dict[int, dict[int, tuple[int, int]]] = {
        entity: {} for entity in entity_ids
    }
    for frame in source_frames:
        if frame["period"] != period:
            continue
        frame_points: dict[int, tuple[tuple[int, int], bool]] = {}
        ambiguous: set[int] = set()
        for item in frame["data"]:
            entity = entity_for_item(item, metadata, resolutions)
            if entity not in observations:
                continue
            direct = item.get("trackable_object") == entity
            if entity in ambiguous and not direct:
                continue
            point = (
                round(number(item.get("x"), "player x") * 100),
                round(number(item.get("y"), "player y") * 100),
            )
            previous = frame_points.get(entity)
            if previous is not None and previous[0] != point:
                if direct and not previous[1]:
                    frame_points[entity] = (point, True)
                    ambiguous.discard(entity)
                    continue
                if previous[1] and not direct:
                    continue
                if direct:
                    raise ValueError(
                        f"Conflicting direct identity at frame {frame['frame']}"
                    )
                frame_points.pop(entity)
                ambiguous.add(entity)
                continue
            frame_points[entity] = (point, direct)
        for entity, (point, _) in frame_points.items():
            observations[entity][frame["frame"]] = point
    return observations


def _bounded_continuation(
    observations: dict[int, tuple[int, int]],
    frames: list[int],
    anchor_frame: int,
    target_frame: int,
) -> tuple[int, int]:
    anchor = observations[anchor_frame]
    forward = target_frame > anchor_frame
    index = bisect.bisect_left(frames, anchor_frame)
    neighbour_index = index - 1 if forward else index + 1
    if not 0 <= neighbour_index < len(frames):
        return anchor
    neighbour_frame = frames[neighbour_index]
    if abs(neighbour_frame - anchor_frame) > 10:
        return anchor
    neighbour = observations[neighbour_frame]
    elapsed = abs(anchor_frame - neighbour_frame) / 10
    velocity = (
        (anchor[0] - neighbour[0]) / 100 / elapsed,
        (anchor[1] - neighbour[1]) / 100 / elapsed,
    ) if forward else (
        (neighbour[0] - anchor[0]) / 100 / elapsed,
        (neighbour[1] - anchor[1]) / 100 / elapsed,
    )
    speed = math.hypot(*velocity)
    if speed > MAX_CONTINUATION_SPEED:
        scale = MAX_CONTINUATION_SPEED / speed
        velocity = (velocity[0] * scale, velocity[1] * scale)
    seconds = abs(target_frame - anchor_frame) / 10
    effective = CONTINUATION_DECAY_SECONDS * (
        1 - math.exp(-seconds / CONTINUATION_DECAY_SECONDS)
    )
    direction = 1 if forward else -1
    return (
        round(anchor[0] + velocity[0] * effective * direction * 100),
        round(anchor[1] + velocity[1] * effective * direction * 100),
    )


def _fallback_position(player: dict, team_index: int) -> tuple[int, int]:
    if player["keeper"]:
        x = -49 if player["home"] else 49
        return (x * 100, 0)
    rank = team_index - 1
    x_slots = (-32, -12, 10, 30)
    y_slots = (-24, -12, 0, 12, 24)
    x = x_slots[(rank // len(y_slots)) % len(x_slots)]
    if not player["home"]:
        x = -x
    return (x * 100, y_slots[rank % len(y_slots)] * 100)


def reconstruct_display(
    spec: dict,
    players: list[dict],
    frames: list[list[int]],
    visibility: list[list[int]],
    observations: dict[int, dict[int, tuple[int, int]]],
    pitch_length: float,
    pitch_width: float,
) -> tuple[list[list[int]], list[list[int]], list[dict]]:
    start = spec["startFrame"]
    end = spec["endFrame"]
    count = len(frames)
    per_player: list[list[tuple[int, int]]] = []
    proofs: list[dict] = []
    team_ranks = {True: 0, False: 0}

    def bounded(point: tuple[int, int]) -> tuple[int, int]:
        return (
            max(round(-pitch_length * 50), min(round(pitch_length * 50), point[0])),
            max(round(-pitch_width * 50), min(round(pitch_width * 50), point[1])),
        )

    for player_index, player in enumerate(players):
        team_ranks[player["home"]] += 1
        points: list[tuple[int, int] | None] = [
            (frames[index][player_index * 2], frames[index][player_index * 2 + 1])
            if visibility[index][player_index]
            else None
            for index in range(count)
        ]
        entity_observations = observations[player["id"]]
        observation_frames = sorted(entity_observations)
        local_frames = [
            frame
            for frame in observation_frames
            if start - CONTEXT_RADIUS_FRAMES <= frame <= end + CONTEXT_RADIUS_FRAMES
        ]
        spans = []
        cursor = 0
        while cursor < count:
            if points[cursor] is not None:
                cursor += 1
                continue
            span_start = cursor
            while cursor + 1 < count and points[cursor + 1] is None:
                cursor += 1
            span_end = cursor
            global_start = start + span_start
            global_end = start + span_end
            insertion = bisect.bisect_left(observation_frames, global_start)
            previous = observation_frames[insertion - 1] if insertion > 0 else None
            next_index = bisect.bisect_right(observation_frames, global_end)
            following = (
                observation_frames[next_index]
                if next_index < len(observation_frames)
                else None
            )
            previous_near = (
                previous is not None
                and global_start - previous <= CONTEXT_RADIUS_FRAMES
            )
            following_near = (
                following is not None
                and following - global_end <= CONTEXT_RADIUS_FRAMES
            )
            anchors = []
            if not local_frames:
                if observation_frames:
                    midpoint = (start + end) / 2
                    nearest = min(
                        observation_frames,
                        key=lambda frame: (abs(frame - midpoint), frame),
                    )
                    point = bounded(entity_observations[nearest])
                    method = "nearest-period-anchor-hold"
                    anchors = [nearest]
                else:
                    point = _fallback_position(
                        player,
                        team_ranks[player["home"]],
                    )
                    method = "role-grid-last-resort"
                for index in range(span_start, span_end + 1):
                    points[index] = point
            elif previous_near and following_near:
                before = entity_observations[previous]
                after = entity_observations[following]
                span = following - previous
                for index in range(span_start, span_end + 1):
                    source_frame = start + index
                    fraction = (source_frame - previous) / span
                    points[index] = bounded(
                        (
                            round(before[0] + (after[0] - before[0]) * fraction),
                            round(before[1] + (after[1] - before[1]) * fraction),
                        )
                    )
                method = (
                    "internal-linear-bridge"
                    if start <= previous and following <= end
                    else "context-anchor-interpolation"
                )
                anchors = [previous, following]
            elif previous_near:
                for index in range(span_start, span_end + 1):
                    points[index] = bounded(
                        _bounded_continuation(
                            entity_observations,
                            observation_frames,
                            previous,
                            start + index,
                        )
                    )
                method = "bounded-forward-continuation"
                anchors = [previous]
            elif following_near:
                for index in range(span_start, span_end + 1):
                    points[index] = bounded(
                        _bounded_continuation(
                            entity_observations,
                            observation_frames,
                            following,
                            start + index,
                        )
                    )
                method = "bounded-backward-continuation"
                anchors = [following]
            else:
                nearest = min(
                    local_frames,
                    key=lambda frame: (
                        abs(frame - (global_start + global_end) / 2),
                        frame,
                    ),
                )
                point = bounded(entity_observations[nearest])
                for index in range(span_start, span_end + 1):
                    points[index] = point
                method = "local-anchor-hold"
                anchors = [nearest]
            spans.append(
                {
                    "startFrame": global_start,
                    "endFrame": global_end,
                    "method": method,
                    "anchorFrames": anchors,
                }
            )
            cursor += 1
        dense = [point for point in points if point is not None]
        if len(dense) != count:
            raise ValueError(f"Incomplete display reconstruction for {spec['id']}")
        per_player.append(dense)
        inferred = sum(not row[player_index] for row in visibility)
        proofs.append(
            {
                "trackableObject": player["id"],
                "observedFrames": count - inferred,
                "inferredFrames": inferred,
                "inferredCoverage": round(inferred / count, 6),
                "contextRadiusFrames": CONTEXT_RADIUS_FRAMES,
                "spans": spans,
            }
        )

    display_frames = [
        [coordinate for player in per_player for coordinate in player[frame_index]]
        for frame_index in range(count)
    ]
    provenance = [
        [0 if visibility[frame][player] else 1 for player in range(len(players))]
        for frame in range(count)
    ]
    return display_frames, provenance, proofs


def camera_bounds(
    frames: list[list[int]],
    display_frames: list[list[int]],
    players: list[dict],
    pitch_length: float,
    pitch_width: float,
) -> list[float]:
    xs = [-pitch_length / 2, pitch_length / 2]
    ys = [-pitch_width / 2, pitch_width / 2]
    for source, display in zip(frames, display_frames):
        xs.append(source[-3] / 100)
        ys.append(source[-2] / 100)
        for player in range(len(players)):
            xs.append(display[player * 2] / 100)
            ys.append(display[player * 2 + 1] / 100)
    return [
        round(min(xs) - DISPLAY_CAMERA_MARGIN_METERS, 2),
        round(max(xs) + DISPLAY_CAMERA_MARGIN_METERS, 2),
        round(min(ys) - DISPLAY_CAMERA_MARGIN_METERS, 2),
        round(max(ys) + DISPLAY_CAMERA_MARGIN_METERS, 2),
    ]


def max_speed(
    frames: list[list[int]], visibility: list[list[int]], player_count: int
) -> float:
    maximum = 0.0
    for player in range(player_count):
        for frame in range(1, len(frames)):
            if not visibility[frame - 1][player] or not visibility[frame][player]:
                continue
            dx = (frames[frame][player * 2] - frames[frame - 1][player * 2]) / 100
            dy = (
                frames[frame][player * 2 + 1]
                - frames[frame - 1][player * 2 + 1]
            ) / 100
            maximum = max(maximum, math.hypot(dx, dy) * 10)
    return maximum


def max_display_speed(frames: list[list[int]], player_count: int) -> float:
    return max_speed(
        frames,
        [[1] * player_count for _ in frames],
        player_count,
    )


def build_scene(
    spec: dict,
    match: dict,
    source_frames: list[dict],
    manifest: dict,
) -> tuple[dict, dict]:
    start = spec["startFrame"]
    end = spec["endFrame"]
    interval = source_frames[start : end + 1]
    if len(interval) != end - start + 1:
        raise ValueError(f"Incomplete source interval for {spec['id']}")
    for expected, frame in enumerate(interval, start=start):
        if frame["frame"] != expected or frame["period"] != spec["period"]:
            raise ValueError(f"Non-contiguous source interval for {spec['id']}")
        if frame["time"] is None:
            raise ValueError(f"Missing source clock for {spec['id']}")
    verify_possession_evidence(spec, source_frames)

    active = active_players(match, interval)
    resolution_frames = [
        frame for frame in source_frames if frame["period"] == spec["period"]
    ]
    players, index_by_entity, resolution_proof = resolve_entities(
        match,
        interval,
        resolution_frames,
        active,
    )
    metadata = {player["trackable_object"]: player for player in match["players"]}
    resolutions = {
        row["trackId"]: row["trackableObject"]
        for row in resolution_proof["resolvedTrackIds"]
    }
    ball_id = match["ball"]["trackable_object"]
    ball_items = []
    for frame in interval:
        matches = [
            item for item in frame["data"] if item.get("trackable_object") == ball_id
        ]
        if len(matches) != 1:
            raise ValueError(f"Ball XY is not continuous for {spec['id']}")
        number(matches[0].get("x"), "ball x")
        number(matches[0].get("y"), "ball y")
        ball_items.append(matches[0])
    ball_height_samples = sum(
        isinstance(item.get("z"), (int, float)) and math.isfinite(item["z"])
        for item in ball_items
    )
    ball_height_available = ball_height_samples == len(interval)

    frames: list[list[int]] = []
    visibility: list[list[int]] = []
    max_error = 0.0
    known_counts = []
    anonymous_counts = []
    anonymous_near_ball = 0
    for source_frame, ball in zip(interval, ball_items):
        observed: dict[int, tuple[float, float]] = {}
        for item in source_frame["data"]:
            entity = entity_for_item(item, metadata, resolutions)
            if entity is None or entity not in index_by_entity:
                continue
            point = (
                number(item.get("x"), "player x"),
                number(item.get("y"), "player y"),
            )
            if entity in observed:
                raise ValueError(
                    f"Conflicting identity observations for {spec['id']} "
                    f"at frame {source_frame['frame']}"
                )
            observed[entity] = point
        row = []
        flags = []
        for player in players:
            point = observed.get(player["id"])
            flags.append(1 if point is not None else 0)
            for value in point or (0.0, 0.0):
                quantized = round(value * 100)
                if point is not None:
                    max_error = max(max_error, abs(quantized / 100 - value))
                row.append(quantized)
        ball_x = number(ball.get("x"), "ball x")
        ball_y = number(ball.get("y"), "ball y")
        row.extend((round(ball_x * 100), round(ball_y * 100)))
        row.append(round(number(ball.get("z"), "ball z") * 100) if ball_height_available else 0)
        frames.append(row)
        visibility.append(flags)
        known_counts.append(
            sum(flag and players[index]["number"] is not None for index, flag in enumerate(flags))
        )
        anonymous_counts.append(
            sum(flag and players[index]["number"] is None for index, flag in enumerate(flags))
        )
        for index, flag in enumerate(flags):
            if not flag or players[index]["number"] is not None:
                continue
            px, py = observed[players[index]["id"]]
            if math.hypot(px - ball_x, py - ball_y) <= 15:
                anonymous_near_ball += 1

    source_observations = observations_by_entity(
        source_frames,
        spec["period"],
        set(index_by_entity),
        metadata,
        resolutions,
    )
    display_frames, display_provenance, reconstruction_proof = reconstruct_display(
        spec,
        players,
        frames,
        visibility,
        source_observations,
        match["pitch_length"],
        match["pitch_width"],
    )

    roster_ids = set(index_by_entity)
    focus = spec["focusTrackableObject"]
    if focus not in roster_ids:
        raise ValueError(f"Focal player is absent for {spec['id']}")
    steps = []
    focal_ids = {focus}
    for authored in spec["steps"]:
        source_frame = authored["sourceFrame"]
        if not start <= source_frame < end:
            raise ValueError(f"Step outside interval for {spec['id']}")
        step = {
            "time": round((source_frame - start) / 10, 3),
            "kind": authored["kind"],
            "actorId": authored["actorTrackableObject"],
        }
        mapping = {
            "targetTrackableObject": "targetId",
            "secondaryTrackableObject": "secondaryId",
        }
        for source_key, target_key in mapping.items():
            if source_key in authored:
                step[target_key] = authored[source_key]
        if "endFrame" in authored:
            step["end"] = round((authored["endFrame"] - start) / 10, 3)
        if "runType" in authored:
            step["runType"] = authored["runType"]
        for entity in (step["actorId"], step.get("targetId"), step.get("secondaryId")):
            if entity is None:
                continue
            if entity not in roster_ids or players[index_by_entity[entity]]["number"] is None:
                raise ValueError(f"Authored step uses unknown identity for {spec['id']}")
            if not visibility[source_frame - start][index_by_entity[entity]]:
                raise ValueError(
                    f"Authored step uses hidden actor for {spec['id']} at {source_frame}"
                )
            focal_ids.add(entity)
        steps.append(step)
    if steps[0]["time"] != 0 or any(
        left["time"] >= right["time"] for left, right in zip(steps, steps[1:])
    ):
        raise ValueError(f"Invalid authored step order for {spec['id']}")

    home_direction, direction_proof = goalkeeper_direction(
        match, source_frames, spec["period"]
    )
    attack_direction = (
        home_direction if spec["attackingTeam"] == "home" else -home_direction
    )
    duration = (end - start) / 10
    url = source_url(manifest, spec["matchId"])
    scene = {
        key: spec[key] for key in ("id", "category", "titleKey", "focusKey")
    }
    scene.update(
        {
            "homeColor": match["home_team_kit"]["jersey_color"],
            "awayColor": match["away_team_kit"]["jersey_color"],
            "homeNumberColor": match["home_team_kit"]["number_color"],
            "awayNumberColor": match["away_team_kit"]["number_color"],
            "attackDirection": attack_direction,
            "focusPlayerId": focus,
            "camera": camera_bounds(
                frames,
                display_frames,
                players,
                match["pitch_length"],
                match["pitch_width"],
            ),
            "steps": steps,
            "outcome": "end",
        }
    )
    data = {
        "fps": 10,
        "poseStep": 1,
        "duration": duration,
        "startClock": clock_seconds(interval[0]["time"]),
        "pitch": [match["pitch_length"], match["pitch_width"]],
        "match": {
            "id": match["id"],
            "date": match["date_time"][:10],
            "home": match["home_team"]["short_name"],
            "away": match["away_team"]["short_name"],
        },
        "players": players,
        "joints": JOINTS,
        "frames": frames,
        "visibility": visibility,
        "displayFrames": display_frames,
        "displayProvenance": display_provenance,
        "poses": [],
        "events": [],
        "sourceCommit": HISTORICAL_COMMIT,
        "sourceUrl": url,
        "sourceFrameStart": start,
        "period": spec["period"],
        "coverage": "broadcastVisible",
        "annotationSource": "derived",
        "ballHeightAvailable": ball_height_available,
        "scene": scene,
    }
    player_speed = max_speed(frames, visibility, len(players))
    if player_speed > 15:
        raise ValueError(f"Implausible identity continuity in {spec['id']}: {player_speed:.2f} m/s")
    ball_speed = max(
        math.hypot(
            (frames[index][-3] - frames[index - 1][-3]) / 100,
            (frames[index][-2] - frames[index - 1][-2]) / 100,
        )
        * 10
        for index in range(1, len(frames))
    )
    display_speed = max_display_speed(display_frames, len(players))
    if display_speed > 15:
        raise ValueError(
            f"Implausible display continuity in {spec['id']}: {display_speed:.2f} m/s"
        )
    proof = {
        "id": spec["id"],
        "matchId": match["id"],
        "competition": match["competition_edition"]["competition"]["name"],
        "sourceStartFrame": start,
        "sourceEndFrame": end,
        "sourceStartTime": interval[0]["time"],
        "sourceEndTime": interval[-1]["time"],
        "period": spec["period"],
        "frames": len(frames),
        "fps": 10,
        "durationSeconds": duration,
        "ballXYObservations": len(frames),
        "ballZObservations": ball_height_samples,
        "ballHeightAvailable": ball_height_available,
        "identifiedPlayers": sum(player["number"] is not None for player in players),
        "anonymousPlayers": sum(player["number"] is None for player in players),
        "minimumIdentifiedPlayersVisible": min(known_counts),
        "maximumAnonymousPlayersVisible": max(anonymous_counts),
        "anonymousObservationsWithin15mOfBall": anonymous_near_ball,
        "maxPlayerSpeedMetersPerSecond": round(player_speed, 4),
        "maxDisplaySpeedMetersPerSecond": round(display_speed, 4),
        "maxBallSpeedMetersPerSecond": round(ball_speed, 4),
        "maxPositionQuantizationErrorMeters": round(max_error, 8),
        "attackDirection": attack_direction,
        "directionProof": direction_proof,
        "trackContinuity": resolution_proof,
        "displayReconstruction": {
            "method": (
                "observed XY copied exactly; internal linear bridges; nearby "
                "same-period anchors; velocity-capped decaying continuation; "
                "nearest same-period anchor hold, then role grid only as last resort"
            ),
            "provenance": {"observed": 0, "reconstructed": 1},
            "contextRadiusFrames": CONTEXT_RADIUS_FRAMES,
            "continuationDecaySeconds": CONTINUATION_DECAY_SECONDS,
            "maximumContinuationSpeedMetersPerSecond": MAX_CONTINUATION_SPEED,
            "players": reconstruction_proof,
        },
        "rosterMapping": [
            {
                "entityId": player["id"],
                "metadataPlayerId": metadata[player["id"]]["id"]
                if player["id"] > 0
                else None,
                "trackableObject": player["id"] if player["id"] > 0 else None,
                "trackId": player.get("trackId"),
                "number": player["number"],
                "name": player["name"],
                "team": "home" if player["home"] else "away",
            }
            for player in players
        ],
        "possessionEvidence": spec["possessionEvidence"],
        "annotationRationale": [
            {
                "sourceFrame": step["sourceFrame"],
                "kind": step["kind"],
                "rationale": step["rationale"],
            }
            for step in spec["steps"]
        ],
        "coverageDecision": spec["coverageDecision"],
    }
    return data, proof


def catalog_entry(spec: dict, data: dict, path: Path) -> dict:
    return {
        "id": spec["id"],
        "category": spec["category"],
        "titleKey": spec["titleKey"],
        "focusKey": spec["focusKey"],
        "asset": path.relative_to(REPO).as_posix(),
        "matchId": data["match"]["id"],
        "date": data["match"]["date"],
        "home": data["match"]["home"],
        "away": data["match"]["away"],
        "startClock": data["startClock"],
        "duration": data["duration"],
        "hasPose": False,
        "sourceCommit": data["sourceCommit"],
        "sourceUrl": data["sourceUrl"],
    }


def write_mixed_catalog(historical_entries: list[dict]) -> tuple[dict, Path, Path]:
    catalog_path = ASSETS / "catalog.json"
    existing = read_json(catalog_path)
    historical_ids = {entry["id"] for entry in historical_entries}
    current_entries = [
        entry for entry in existing["scenes"] if entry["id"] not in historical_ids
    ]
    if len(current_entries) != 20 or any(
        entry.get("sourceCommit", CURRENT_COMMIT) != CURRENT_COMMIT
        for entry in current_entries
    ):
        raise ValueError("Expected the 20 current-data scenes before catalog merge")
    catalog = {
        "version": 1,
        "sourceCommit": CURRENT_COMMIT,
        "sourceUrl": CURRENT_SOURCE_URL,
        "scenes": historical_entries + current_entries,
    }
    save(catalog_path, catalog)
    mixed_proof_path = ASSETS / "mixed-catalog-proof.json"
    mixed_proof = {
        "catalog": asset_record(catalog_path),
        "sourceCommits": [HISTORICAL_COMMIT, CURRENT_COMMIT],
        "sceneCount": len(catalog["scenes"]),
        "scenes": [
            {
                "id": entry["id"],
                "sourceCommit": entry.get("sourceCommit", CURRENT_COMMIT),
                "asset": entry["asset"],
                "sha256": digest(REPO / entry["asset"]),
            }
            for entry in catalog["scenes"]
        ],
    }
    save(mixed_proof_path, mixed_proof, pretty=True)
    return catalog, catalog_path, mixed_proof_path


def update_current_manifest(catalog_path: Path, mixed_proof_path: Path) -> None:
    path = ASSETS / "source-manifest.json"
    manifest = read_json(path)
    records = {
        entry["path"]: entry for entry in manifest.get("derivedAssets", [])
    }
    for asset in (catalog_path, mixed_proof_path):
        record = asset_record(asset)
        records[record["path"]] = record
    manifest["derivedAssets"] = list(records.values())
    save(path, manifest, pretty=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "raw_dir",
        type=Path,
        help="Root containing README.md, LICENSE and data/matches/<id>",
    )
    args = parser.parse_args()
    raw_dir = args.raw_dir.resolve()
    manifest = read_json(MANIFEST_PATH)
    verify_sources(raw_dir, manifest)
    specs = read_json(SPEC_PATH)

    built: dict[str, tuple[dict, dict]] = {}
    for match_id in sorted({spec["matchId"] for spec in specs}):
        match_dir = raw_dir / "data/matches" / str(match_id)
        match = read_json(match_dir / "match_data.json")
        source_frames = read_json(match_dir / "structured_data.json")
        if any(frame["frame"] != index for index, frame in enumerate(source_frames)):
            raise ValueError(f"Source frame/index mismatch for match {match_id}")
        for spec in (item for item in specs if item["matchId"] == match_id):
            built[spec["id"]] = build_scene(spec, match, source_frames, manifest)

    entries = []
    proofs = []
    derived = []
    for spec in specs:
        data, proof = built[spec["id"]]
        path = ASSETS / "scenes" / f"{spec['id']}.json"
        save(path, data)
        proof["asset"] = path.relative_to(REPO).as_posix()
        proof["sha256"] = digest(path)
        proofs.append(proof)
        entries.append(catalog_entry(spec, data, path))
        derived.append(asset_record(path))

    historical_catalog_path = ASSETS / "historical-catalog.json"
    save(
        historical_catalog_path,
        {
            "version": 1,
            "sourceCommit": HISTORICAL_COMMIT,
            "sourceUrl": HISTORICAL_SOURCE_ROOT,
            "scenes": entries,
        },
    )
    proof_path = ASSETS / "historical-catalog-proof.json"
    save(
        proof_path,
        {"sourceCommit": HISTORICAL_COMMIT, "scenes": proofs},
        pretty=True,
    )
    derived.extend((asset_record(historical_catalog_path), asset_record(proof_path)))
    catalog, catalog_path, mixed_proof_path = write_mixed_catalog(entries)
    derived.extend((asset_record(catalog_path), asset_record(mixed_proof_path)))

    manifest["matchIds"] = sorted({spec["matchId"] for spec in specs})
    manifest["derivedAssets"] = derived
    save(MANIFEST_PATH, manifest, pretty=True)
    update_current_manifest(catalog_path, mixed_proof_path)
    print(
        f"Rebuilt {len(entries)} historical scenes; mixed catalog has "
        f"{len(catalog['scenes'])} scenes."
    )


if __name__ == "__main__":
    main()
