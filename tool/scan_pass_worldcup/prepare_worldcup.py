#!/usr/bin/env python3
"""Build the pinned PFF FC 2022 World Cup spatial teaching clips.

Generation reads only the four provider files for each selected match. It uses
raw (not smoothed) VISIBLE tracking samples and source pass/receiver identities.
ESTIMATED or absent players and balls remain missing in the replay payload.
"""

from __future__ import annotations

import argparse
import bz2
import hashlib
import json
import math
from pathlib import Path
from typing import Any


REPO = Path(__file__).resolve().parents[2]
DEFAULT_RAW_ROOT = REPO / ".tmp/worldcup-20261109/source"
ASSET_ROOT = REPO / "assets/scan_pass_spatial"
SCENE_ROOT = ASSET_ROOT / "education_scenes"
CATALOG_PATH = ASSET_ROOT / "education-catalog.json"
MANIFEST_PATH = ASSET_ROOT / "worldcup-source-manifest.json"
PROOF_PATH = ASSET_ROOT / "worldcup-proof.json"
PUBLIC_FOLDER = (
    "https://drive.google.com/drive/folders/"
    "1_a_q1e9CXeEPJ3GdCv_3-rNO3gPqacfa"
)
MISSING = -(2**31)
CACHE_NORMALIZATION_VERSION = 2


def source_file(
    role: str, file_id: str, size: int, sha256: str, relative_path: str
) -> dict[str, Any]:
    return {
        "role": role,
        "fileId": file_id,
        "bytes": size,
        "sha256": sha256,
        "url": f"https://drive.google.com/file/d/{file_id}/view",
        "relativePath": relative_path,
    }


SOURCE_FILES = {
    10517: {
        "metadata": source_file(
            "metadata",
            "1Xfvmdv7XiZAUumPbjGqYfrUVAhX-0Dl3",
            955,
            "9416812b85807dc9c02a2e86e6269a5ef9def47d7ca353c70994626bcc5d417a",
            "metadata/10517.json",
        ),
        "rosters": source_file(
            "rosters",
            "1nJcElKpNPp_Tl2TNaOhvdCh5E98T2YtR",
            7575,
            "e7053ba5aa8d626a41dd725edc2e9d867fa283d3fdf138ab22918f3692bc0057",
            "rosters/10517.json",
        ),
        "events": source_file(
            "events",
            "1Zi9rP8x4-V-9AQ_jGysmkU14wuFgzsIv",
            22818080,
            "d571475b7f733c93b1161f39aa0bb2119a14ca15c74b064029e102ff1ad99c99",
            "events/10517.json",
        ),
        "tracking": source_file(
            "tracking",
            "1punYKj2mY1HtewOJ5V1EFO7gHn0jaQm0",
            66646392,
            "3c899b41eb5fcf4c74bf62c83853910a24098eb4b2485cc799fab6fce622a72c",
            "tracking/10517.jsonl.bz2",
        ),
    },
    10507: {
        "metadata": source_file(
            "metadata",
            "1PhzVr4cGZ3P6-XQFqomh709mSMlvGY4i",
            989,
            "097d70bd7b3dca46d0ad18f3f8c291ca17bbc578a28042bb9cd8351c8ac1aeef",
            "metadata/10507.json",
        ),
        "rosters": source_file(
            "rosters",
            "1mjm50gm4UFrpTOL7p-6uyBnuOt-ADTG2",
            7273,
            "e27385e17e5a50e6b67fa4e9545760cf193819ad7cc5a3bae1b41aa4d2ac8ed9",
            "rosters/10507.json",
        ),
        "events": source_file(
            "events",
            "1hhxfeTO1QrHL_wCZQvdpKjNwvnbUg4u1",
            19670744,
            "df95ecba371ac1ba18426f636e4c3c443a2e0a2fc80ebe78c296d4d3f3cb9df6",
            "events/10507.json",
        ),
        "tracking": source_file(
            "tracking",
            "1T0dx4YvpkycARke_Nv0JtfOhue4u50Cn",
            46996047,
            "41cd9896ef663fbcb811c2f97fd9bc7c5fdb92dcf75e1d66ff748a2ddba4acbe",
            "tracking/10507.jsonl.bz2",
        ),
    },
    3857: {
        "metadata": source_file(
            "metadata",
            "1GOUsQIE78-oBcs0mD-8VfYenwMG7zd-K",
            994,
            "7e9254ee5306c9417294d6a325c06fa4ffea8ef753d98f48077b5bf062d1eb91",
            "metadata/3857.json",
        ),
        "rosters": source_file(
            "rosters",
            "1cKygKfjmM6ryiiZCxnacQFacvuD1MWbv",
            7393,
            "bd86b75a905c0f0ab183256b235b8c1ff757af6708013abaf0512eebefebd2a0",
            "rosters/3857.json",
        ),
        "events": source_file(
            "events",
            "1vitJQ9Yh4xVAeOV0VhgNVOc6C0QS_-G0",
            16976388,
            "c1b77d5a07e88b1a28bbafcbaa2d6845540604f8f7ffac99bf617a4a80e37188",
            "events/3857.json",
        ),
        "tracking": source_file(
            "tracking",
            "1UwuVYtQNvnUT5-eTDpF7-WanggQPYwY-",
            40392472,
            "fdb32802ccb0d8eecae0f67c91d1a03b3690ca4275fcd1e8bc97fca836660f9e",
            "tracking/3857.jsonl.bz2",
        ),
    },
}

SPEC_FILES = {
    "tracking-spec": source_file(
        "tracking-spec",
        "17kl9XOlA932IU_K6969VYDYntYJt3Pan",
        186300,
        "d6d2ab083f864e749c951a3256f6d3415eba7bd5f67eea6025403eaa59838f49",
        "spec/PFF FC Tracking Data Specification v2.2.pdf",
    ),
    "event-spec": source_file(
        "event-spec",
        "1Q5Wg-q2lOdFreqyZqfmWKBXLPE8HJopt",
        824166,
        "90b34f6b7e0401a0ab4c9f1328ef8e10a8f7237e4461359ee8c292d8fa9e0246",
        "spec/PFF FC Event Data Specification v2.5.pdf",
    ),
}

CLIPS = {
    10517: [
        ("pff-10517-6622232-6622241-thirdPlayer", 6622232, 6622241),
        ("pff-10517-6624101-6624111-thirdPlayer", 6624101, 6624111),
        ("pff-10517-6622272-dimaria-receivingLane", 6622272, None),
        ("pff-10517-6622327-6622334-thirdPlayer", 6622327, 6622334),
        ("pff-10517-6622360-6622367-thirdPlayer", 6622360, 6622367),
        ("pff-10517-6622532-6622537-thirdPlayer", 6622532, 6622537),
        ("pff-10517-6622604-6622609-thirdPlayer", 6622604, 6622609),
        ("pff-10517-6623005-6623547-thirdPlayer", 6623005, 6623547),
        ("pff-10517-6623341-6623348-thirdPlayer", 6623341, 6623348),
        ("pff-10517-6623504-6623505-thirdPlayer", 6623504, 6623505),
        ("pff-10517-6622577-6622584-thirdPlayer", 6622577, 6622584),
        ("pff-10517-6622901-6622905-thirdPlayer", 6622901, 6622905),
        ("pff-10517-6623195-6623199-mbappe-thirdPlayer", 6623195, 6623199),
        ("pff-10517-6622785-6622790-thirdPlayer", 6622785, 6622790),
        ("pff-10517-6623572-6623577-thirdPlayer", 6623572, 6623577),
        ("pff-10517-6624075-6624076-thirdPlayer", 6624075, 6624076),
        ("pff-10517-6624132-6624134-thirdPlayer", 6624132, 6624134),
        ("pff-10517-6623558-6623564-mbappe-thirdPlayer", 6623558, 6623564),
    ],
    10507: [
        ("pff-10507-6525618-6525622-thirdPlayer", 6525618, 6525622),
        ("pff-10507-6525919-6525929-thirdPlayer", 6525919, 6525929),
        ("pff-10507-6525942-lee-switchingSpace", 6525942, None),
    ],
    3857: [
        ("pff-3857-6504653-6504660-thirdPlayer", 6504653, 6504660),
        ("pff-3857-6505127-6505134-ronaldo-thirdPlayer", 6505127, 6505134),
        ("pff-3857-6506619-6506642-thirdPlayer", 6506619, 6506642),
    ],
}

EXPECTED_ACCEPTED_IDS = {
    "pff-10517-6622604-6622609-thirdPlayer",
    "pff-10507-6525919-6525929-thirdPlayer",
    "pff-3857-6504653-6504660-thirdPlayer",
    "pff-3857-6505127-6505134-ronaldo-thirdPlayer",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(json_bytes(value))


def json_bytes(value: Any) -> bytes:
    return (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def rounded(value: float) -> float:
    return round(value, 3)


def distance(first: tuple[float, float], second: tuple[float, float]) -> float:
    return math.hypot(first[0] - second[0], first[1] - second[1])


def angle_degrees(
    origin: tuple[float, float],
    first: tuple[float, float],
    second: tuple[float, float],
) -> float:
    first_vector = (first[0] - origin[0], first[1] - origin[1])
    second_vector = (second[0] - origin[0], second[1] - origin[1])
    denominator = math.hypot(*first_vector) * math.hypot(*second_vector)
    if denominator <= 1e-9:
        return 0
    cosine = (
        first_vector[0] * second_vector[0]
        + first_vector[1] * second_vector[1]
    ) / denominator
    return math.degrees(math.acos(max(-1.0, min(1.0, cosine))))


def segment_projection(
    start: tuple[float, float],
    end: tuple[float, float],
    point: tuple[float, float],
) -> float:
    delta = (end[0] - start[0], end[1] - start[1])
    denominator = delta[0] ** 2 + delta[1] ** 2
    if denominator <= 1e-9:
        return math.inf
    return (
        (point[0] - start[0]) * delta[0]
        + (point[1] - start[1]) * delta[1]
    ) / denominator


def line_gap(
    start: tuple[float, float],
    end: tuple[float, float],
    point: tuple[float, float],
) -> float:
    delta = (end[0] - start[0], end[1] - start[1])
    denominator = math.hypot(*delta)
    if denominator <= 1e-9:
        return math.inf
    return abs(
        delta[0] * (point[1] - start[1])
        - delta[1] * (point[0] - start[0])
    ) / denominator


def receiver_event(rows: list[dict[str, Any]], event: dict[str, Any]) -> dict[str, Any]:
    receiver = event["possessionEvents"]["receiverPlayerId"]
    candidates = [
        row
        for row in rows
        if row["sequence"] == event["sequence"]
        and row["gameEvents"].get("playerId") == receiver
        and row["startTime"] >= event["eventTime"] - 1e-6
    ]
    if not candidates:
        raise ValueError(f"No receiver event for {event['possessionEventId']}")
    return min(candidates, key=lambda row: row["startTime"])


def pass_actor(event: dict[str, Any]) -> int:
    values = event["possessionEvents"]
    return int(values.get("passerPlayerId") or values.get("crosserPlayerId"))


def pass_receiver(event: dict[str, Any]) -> int:
    return int(event["possessionEvents"]["receiverPlayerId"])


def quantized_point(row: dict[str, Any], player_id: int) -> tuple[float, float]:
    x, y, _ = row["players"][player_id]
    return round(x * 100) / 100, round(y * 100) / 100


def nearest_observed(
    rows: list[dict[str, Any]],
    time: float,
    player_id: int,
    owner: bool,
    fps: float,
    label: str,
) -> dict[str, Any]:
    values = [
        row
        for row in rows
        if player_id in row["players"]
        and (not owner or row["owner"] == player_id)
    ]
    if not values:
        raise ValueError(
            f"{label}: no directly observed source-labelled anchor for player {player_id}"
        )
    nearest = min(values, key=lambda row: abs(row["time"] - time))
    offset = abs(nearest["time"] - time)
    tolerance = 1 / fps + 0.001
    if offset > tolerance:
        raise ValueError(
            f"{label}: nearest directly observed anchor for player {player_id} is "
            f"{offset:.3f}s from provider time, beyond one {1 / fps:.3f}s source frame"
        )
    return nearest


def normalize_tracking(
    raw: dict[str, Any], key_to_id: dict[tuple[bool, str], int]
) -> dict[str, Any]:
    players: dict[int, tuple[float, float, str]] = {}
    for home, key in ((True, "homePlayers"), (False, "awayPlayers")):
        for value in raw[key]:
            player_id = key_to_id.get((home, str(value["jerseyNum"])))
            if (
                player_id is not None
                and value.get("visibility") == "VISIBLE"
                and math.isfinite(float(value["x"]))
                and math.isfinite(float(value["y"]))
            ):
                players[player_id] = (
                    float(value["x"]),
                    float(value["y"]),
                    str(value.get("confidence") or "UNKNOWN"),
                )
    balls = raw.get("balls")
    visible_balls = (
        [value for value in balls if value.get("visibility") == "VISIBLE"]
        if isinstance(balls, list)
        else []
    )
    ball = None
    if len(visible_balls) == 1:
        value = visible_balls[0]
        xyz = (float(value["x"]), float(value["y"]), float(value["z"]))
        if all(math.isfinite(item) for item in xyz) and 0 <= xyz[2] <= 15:
            ball = xyz
    game_event = raw.get("game_event") or {}
    owner_value = (
        game_event.get("player_id")
        if game_event.get("game_event_type") == "OTB"
        else None
    )
    owner = int(owner_value) if owner_value is not None else None
    if owner not in players:
        owner = None
    return {
        "frame": int(raw["frameNum"]),
        "time": float(raw["videoTimeMs"]) / 1000,
        "period": int(raw["period"]),
        "clock": float(raw["periodGameClockTime"]),
        "players": players,
        "ball": ball,
        "owner": owner,
    }


def active_players(
    rows: list[dict[str, Any]], roster_by_id: dict[int, dict[str, Any]], home_team_id: str
) -> list[dict[str, Any]]:
    ids = {player_id for row in rows for player_id in row["players"]}
    players = []
    for player_id in ids:
        roster = roster_by_id[player_id]
        players.append(
            {
                "id": player_id,
                "number": int(roster["shirtNumber"]),
                "name": roster["player"]["nickname"],
                "home": roster["team"]["id"] == home_team_id,
                "keeper": roster["positionGroupType"] == "GK",
            }
        )
    players.sort(key=lambda value: (not value["home"], value["number"], value["id"]))
    return players


def source_event_id(event: dict[str, Any]) -> str:
    return f"pff:{event['gameEventId']}:{event['possessionEventId']}"


def build_clip(
    clip_id: str,
    passes: list[dict[str, Any]],
    receptions: list[dict[str, Any]],
    available_rows: list[dict[str, Any]],
    metadata: dict[str, Any],
    roster_by_id: dict[int, dict[str, Any]],
    tracking_file: dict[str, Any],
) -> tuple[dict[str, Any], dict[str, Any], dict[str, Any]]:
    fps = float(metadata["fps"])
    release_rows = [
        nearest_observed(
            available_rows,
            event["eventTime"],
            pass_actor(event),
            True,
            fps,
            f"{clip_id} release {event['possessionEventId']}",
        )
        for event in passes
    ]
    receive_rows = [
        nearest_observed(
            available_rows,
            receipt["startTime"],
            pass_receiver(event),
            True,
            fps,
            f"{clip_id} reception {event['possessionEventId']}",
        )
        for event, receipt in zip(passes, receptions)
    ]
    first_actor = pass_actor(passes[0])
    movement_frame = release_rows[0]["frame"] - round(fps)
    trigger_row = release_rows[-1]
    outcome_row = receive_rows[-1]
    period = int(passes[0]["gameEvents"]["period"])
    available_by_frame: dict[int, dict[str, Any]] = {}
    for row in available_rows:
        previous = available_by_frame.get(row["frame"])
        if previous is not None and previous != row:
            raise ValueError(f"{clip_id}: conflicting duplicate source frame")
        available_by_frame[row["frame"]] = row

    for frame in range(movement_frame, outcome_row["frame"] + 1):
        row = available_by_frame.get(frame)
        if row is None or row["period"] != period or not row["players"]:
            raise ValueError(f"{clip_id}: empty frame or source cut in teaching action")
    run_start = movement_frame
    while (
        (row := available_by_frame.get(run_start - 1)) is not None
        and row["period"] == period
        and row["players"]
    ):
        run_start -= 1
    run_end = outcome_row["frame"]
    while (
        (row := available_by_frame.get(run_end + 1)) is not None
        and row["period"] == period
        and row["players"]
    ):
        run_end += 1

    context_frames = round(4 * fps)
    if (
        run_start > movement_frame - context_frames
        or run_end < outcome_row["frame"] + context_frames
    ):
        raise ValueError(f"{clip_id}: continuous nonempty context is under four seconds")
    nominal_start_frame = release_rows[0]["frame"] - round(6 * fps)
    latest_start_frame = movement_frame - context_frames
    preferred_start_frame = max(run_start, nominal_start_frame)
    visible_starts = [
        frame
        for frame in range(preferred_start_frame, latest_start_frame + 1)
        if first_actor in available_by_frame[frame]["players"]
    ] or [
        frame
        for frame in range(run_start, latest_start_frame + 1)
        if first_actor in available_by_frame[frame]["players"]
    ]
    if not visible_starts:
        raise ValueError(f"{clip_id}: no directly observed scene opening")
    start_frame = min(visible_starts)
    end_frame = min(run_end, start_frame + round(24 * fps))
    if (end_frame - start_frame) / fps < 15:
        raise ValueError(f"{clip_id}: continuous nonempty source interval is under 15s")
    row_by_frame = {
        frame: available_by_frame[frame]
        for frame in range(start_frame, end_frame + 1)
    }
    rows = [row_by_frame[frame] for frame in sorted(row_by_frame)]
    if not rows or rows[0]["frame"] != start_frame or rows[-1]["frame"] != end_frame:
        raise ValueError(f"{clip_id}: source interval is incomplete")
    if any(
        second["frame"] != first["frame"] + 1
        for first, second in zip(rows, rows[1:])
    ):
        raise ValueError(f"{clip_id}: source frame gap/cut in interval")
    if any(row["period"] != period for row in rows):
        raise ValueError(f"{clip_id}: interval crosses a period boundary")
    if any(
        event["gameEvents"].get("videoMissing") is not False
        or (
            event["possessionEvents"].get("passOutcomeType") != "C"
            and event["possessionEvents"].get("crossOutcomeType") != "C"
        )
        for event in passes
    ):
        raise ValueError(f"{clip_id}: pass is incomplete or video is missing")

    movement_row = row_by_frame.get(movement_frame)
    if movement_row is None:
        raise ValueError(f"{clip_id}: movement-start source frame is missing")
    local = lambda row: (row["frame"] - start_frame) / fps

    if len(passes) == 2:
        second_actor = pass_receiver(passes[0])
        if pass_actor(passes[1]) != second_actor:
            raise ValueError(f"{clip_id}: provider events do not form a pass chain")
        focus = pass_receiver(passes[1])
        objective = "thirdPlayer"
        core_ids = [first_actor, second_actor, focus]
        support_ids = [first_actor, second_actor]
    else:
        focus = pass_receiver(passes[0])
        objective = (
            "receivingLane" if clip_id.endswith("receivingLane") else "switchingSpace"
        )
        core_ids = [first_actor, focus]
        support_ids = [first_actor]

    core_rows = [
        row
        for row in rows
        if movement_frame <= row["frame"] <= outcome_row["frame"]
    ]
    # The measured focus run must be continuous. Passing actors may leave the
    # broadcast view after their provider-linked connection; those later gaps
    # stay missing and are never reconstructed.
    for player_id in [focus]:
        if not all(player_id in row["players"] for row in core_rows):
            raise ValueError(f"{clip_id}: teaching actor {player_id} has a visibility gap")
    focus_home = roster_by_id[focus]["team"]["id"] == metadata["homeTeam"]["id"]
    opponent_ids = [
        player_id
        for player_id, roster in roster_by_id.items()
        if (roster["team"]["id"] == metadata["homeTeam"]["id"]) != focus_home
        and all(player_id in row["players"] for row in core_rows)
    ]
    if not opponent_ids:
        raise ValueError(f"{clip_id}: no continuously observed opponent")
    receiving_measurements = None
    if objective == "receivingLane":
        passer_start = quantized_point(movement_row, first_actor)
        passer_trigger = quantized_point(trigger_row, first_actor)
        focus_start = quantized_point(movement_row, focus)
        focus_trigger = quantized_point(trigger_row, focus)
        for candidate in opponent_ids:
            defender_start = quantized_point(movement_row, candidate)
            defender_trigger = quantized_point(trigger_row, candidate)
            before_angle = angle_degrees(passer_start, focus_start, defender_start)
            after_angle = angle_degrees(
                passer_trigger, focus_trigger, defender_trigger
            )
            frozen_angle = angle_degrees(
                passer_trigger, focus_start, defender_trigger
            )
            projection_before = segment_projection(
                passer_start, focus_start, defender_start
            )
            projection_after = segment_projection(
                passer_trigger, focus_trigger, defender_trigger
            )
            baseline_gap = line_gap(passer_start, focus_start, defender_start)
            after_gap = line_gap(passer_trigger, focus_trigger, defender_trigger)
            frozen_gap = line_gap(passer_trigger, focus_start, defender_trigger)
            contribution = after_angle - frozen_angle
            line_contribution = after_gap - frozen_gap
            movement_to_trigger = distance(focus_start, focus_trigger)
            if (
                0 <= projection_before <= 1
                and 0 <= projection_after <= 1
                and baseline_gap <= 3
                and before_angle <= 25
                and after_gap - baseline_gap + 0.01 >= 0.5
                and line_contribution + 0.01 >= 0.25
                and movement_to_trigger + 0.01 >= 0.75
                and after_angle - before_angle >= 3
                and contribution >= 1
            ):
                opponent = candidate
                receiving_measurements = {
                    "before": before_angle,
                    "after": after_angle,
                    "contribution": contribution,
                    "projectionBefore": projection_before,
                    "projectionAfter": projection_after,
                    "baselineGap": baseline_gap,
                    "afterGap": after_gap,
                    "lineContribution": line_contribution,
                }
                break
        if receiving_measurements is None:
            raise ValueError(f"{clip_id}: receiving-lane threshold is not met")
    else:
        opponent = min(
            opponent_ids,
            key=lambda player_id: distance(
                quantized_point(movement_row, focus),
                quantized_point(movement_row, player_id),
            ),
        )

    # Source owners may be absent, but an intervening third owner is rejected.
    ownership_anchors = [release_rows[0]]
    expected_owners = [first_actor]
    if len(passes) == 2:
        ownership_anchors.append(release_rows[1])
        expected_owners.append(pass_actor(passes[1]))
    ownership_anchors.append(outcome_row)
    expected_owners.append(focus)
    guard_frames = round(fps * 0.5)
    linked_anchors = [
        (anchor, player_id)
        for event, release, receive in zip(passes, release_rows, receive_rows)
        for anchor, player_id in (
            (release, pass_actor(event)),
            (receive, pass_receiver(event)),
        )
    ]
    for anchor, expected_owner in linked_anchors:
        if any(
            expected_owner not in row_by_frame[frame]["players"]
            for frame in range(
                anchor["frame"] - guard_frames,
                anchor["frame"] + guard_frames + 1,
            )
        ):
            raise ValueError(
                f"{clip_id}: source-linked actor {expected_owner} is not directly "
                "observed through the 0.5s anchor guard"
            )
        ball = anchor["ball"]
        player = anchor["players"][expected_owner]
        if ball is not None and distance(player[:2], ball[:2]) > 3.5 + 1 / fps:
            raise ValueError(
                f"{clip_id}: source-labelled anchor owner {expected_owner} is "
                "too far from the visible source ball"
            )
    for index in range(len(ownership_anchors) - 1):
        first = ownership_anchors[index]["frame"]
        last = ownership_anchors[index + 1]["frame"]
        old_owner = expected_owners[index]
        new_owner = expected_owners[index + 1]
        if row_by_frame[first]["owner"] != old_owner or row_by_frame[last]["owner"] != new_owner:
            raise ValueError(f"{clip_id}: source ownership anchors disagree")
        advanced = False
        for frame in range(first, last + 1):
            owner = row_by_frame[frame]["owner"]
            if owner is None:
                continue
            if owner == new_owner:
                advanced = True
            elif owner != old_owner or advanced:
                raise ValueError(f"{clip_id}: intervening source-labelled owner")

    attack_value = passes[0]["stadiumMetadata"].get("teamAttackingDirection")
    attack_direction = {"L": -1, "R": 1}.get(attack_value)
    if attack_direction is None or any(
        event["stadiumMetadata"].get("teamAttackingDirection") != attack_value
        for event in passes
    ):
        raise ValueError(f"{clip_id}: provider attack direction is unavailable")
    focus_start = quantized_point(movement_row, focus)
    focus_trigger = quantized_point(trigger_row, focus)
    focus_outcome = quantized_point(outcome_row, focus)
    defender_start = quantized_point(movement_row, opponent)
    defender_outcome = quantized_point(outcome_row, opponent)
    before_clearance = distance(focus_start, defender_start)
    after_clearance = distance(focus_outcome, defender_outcome)
    clearance_gain = after_clearance - before_clearance
    movement = distance(
        focus_start,
        focus_outcome if objective == "switchingSpace" else focus_trigger,
    )
    total_movement = distance(focus_start, focus_outcome)
    pre_vector = (
        focus_trigger[0] - focus_start[0],
        focus_trigger[1] - focus_start[1],
    )
    total_vector = (
        focus_outcome[0] - focus_start[0],
        focus_outcome[1] - focus_start[1],
    )
    alignment = (
        (pre_vector[0] * total_vector[0] + pre_vector[1] * total_vector[1])
        / (movement * total_movement)
        if movement and total_movement
        else -1
    )
    forward = (focus_outcome[0] - focus_start[0]) * attack_direction
    lateral = abs(
        quantized_point(trigger_row, first_actor)[1] - focus_outcome[1]
    )
    if objective == "receivingLane":
        measurement = "laneAngleDegrees"
        before = receiving_measurements["before"]
        after = receiving_measurements["after"]
        improvement = after - before
    elif objective == "switchingSpace":
        measurement = "defenderClearanceMeters"
        before, after, improvement = before_clearance, after_clearance, clearance_gain
        if lateral < 22 or clearance_gain < 1:
            raise ValueError(f"{clip_id}: switching evidence threshold is not met")
    elif clearance_gain >= 1:
        measurement = "defenderClearanceMeters"
        before, after, improvement = before_clearance, after_clearance, clearance_gain
    else:
        measurement = "forwardAdvanceMeters"
        before, after, improvement = 0.0, forward, forward
        if forward < 1.5:
            raise ValueError(f"{clip_id}: third-player evidence threshold is not met")
    if objective == "thirdPlayer" and (movement < 0.6 or total_movement < 1 or alignment < 0.5):
        raise ValueError(f"{clip_id}: third-player movement is late or absent")

    players = active_players(rows, roster_by_id, metadata["homeTeam"]["id"])
    player_ids = [player["id"] for player in players]
    frames = []
    visibility = []
    ball_visibility = []
    ball_height_valid = []
    owners = []
    low_confidence_visible = 0
    for row in rows:
        frame_values = []
        visible_values = []
        for player_id in player_ids:
            value = row["players"].get(player_id)
            if value is None:
                frame_values.extend([MISSING, MISSING])
                visible_values.append(0)
            else:
                frame_values.extend([round(value[0] * 100), round(value[1] * 100)])
                visible_values.append(1)
                if value[2] == "LOW":
                    low_confidence_visible += 1
        ball = row["ball"]
        if ball is None:
            frame_values.extend([0, 0, 0])
            ball_visibility.append(0)
            ball_height_valid.append(False)
        else:
            frame_values.extend(
                [round(ball[0] * 100), round(ball[1] * 100), round(ball[2] * 100)]
            )
            ball_visibility.append(1)
            ball_height_valid.append(True)
        frames.append(frame_values)
        visibility.append(visible_values)
        owners.append(row["owner"])

    names = {player["id"]: player["name"] for player in players}
    event_payloads = []
    connection_ids = []
    for event, release, receive in zip(passes, release_rows, receive_rows):
        event_id = source_event_id(event)
        connection_ids.append(event_id)
        actor = pass_actor(event)
        receiver = pass_receiver(event)
        event_payloads.append(
            {
                "event_id": event_id,
                "player_id": actor,
                "player_name": names[actor],
                "player_targeted_id": receiver,
                "player_targeted_name": names[receiver],
                "end_type": "pass",
                "pass_outcome": "complete",
                "start": local(release),
                "end": local(receive),
            }
        )
    movement_time = local(movement_row)
    trigger_time = local(trigger_row)
    outcome_time = local(outcome_row)
    source_frames = {
        "movementStart": movement_frame,
        "trigger": trigger_row["frame"],
        "outcome": outcome_row["frame"],
        "nextConnection": None,
    }
    actor = lambda player_id: {
        "playerId": player_id,
        "playerName": names[player_id],
    }
    objective_suffix = {
        "thirdPlayer": "ThirdPlayer",
        "receivingLane": "ReceivingLane",
        "switchingSpace": "SwitchingSpace",
    }[objective]
    learning = {
        "objective": objective,
        "proofVersion": "spatial-education-evidence-v2",
        "referenceUrls": [
            (
                "https://www.fifatrainingcentre.com/en/practice/"
                "talent-coach-programme/build-and-progress/"
                "passing-circuit-receiving-between-the-lines.php"
                if objective == "receivingLane"
                else "https://www.fifatrainingcentre.com/en/game/game-analysis/"
                + (
                    "in-possession/third-player-combinations.php"
                    if objective == "thirdPlayer"
                    else "in-possession/switching-play.php"
                )
            )
        ],
        "sourceConnectionEventIds": connection_ids,
        "questionKey": f"spatialEducation{objective_suffix}Question",
        "actionKey": f"spatialEducation{objective_suffix}Action",
        "resultKey": f"spatialEducation{objective_suffix}Result",
        "focusActor": actor(focus),
        "supportActors": [actor(value) for value in support_ids],
        "opponentActors": [actor(opponent)],
        "nextActor": None,
        "movementStart": movement_time,
        "trigger": trigger_time,
        "outcome": outcome_time,
        "slowStart": movement_time,
        "slowEnd": outcome_time,
        "nextConnection": None,
        "sourceFrames": source_frames,
        "measurements": {
            "kind": measurement,
            "before": rounded(before),
            "after": rounded(after),
            "improvement": rounded(improvement),
            "movementMeters": rounded(movement),
            "pressureMeters": None,
            "lateralMeters": rounded(lateral) if objective == "switchingSpace" else None,
            "forwardMeters": rounded(forward),
            "receiverContributionDegrees": rounded(receiving_measurements["contribution"])
            if objective == "receivingLane"
            else None,
            "defenderProjectionBefore": rounded(receiving_measurements["projectionBefore"])
            if objective == "receivingLane"
            else None,
            "defenderProjectionAfter": rounded(receiving_measurements["projectionAfter"])
            if objective == "receivingLane"
            else None,
            "movementAlignment": rounded(alignment) if objective == "thirdPlayer" else None,
            "baselinePassLineGapMeters": rounded(receiving_measurements["baselineGap"])
            if objective == "receivingLane"
            else None,
            "afterPassLineGapMeters": rounded(receiving_measurements["afterGap"])
            if objective == "receivingLane"
            else None,
            "receiverLineGapContributionMeters": rounded(
                receiving_measurements["lineContribution"]
            )
            if objective == "receivingLane"
            else None,
            "quantizationMeters": 0.005,
        },
    }
    attacking_home = roster_by_id[first_actor]["team"]["id"] == metadata["homeTeam"]["id"]
    home_kit = metadata["homeTeamKit"]
    away_kit = metadata["awayTeamKit"]
    duration = (end_frame - start_frame) / fps
    steps = [{"time": 0.0, "kind": "observe", "actorId": first_actor}]
    for event_payload in event_payloads:
        steps.extend(
            [
                {
                    "time": event_payload["start"],
                    "kind": "pass",
                    "actorId": event_payload["player_id"],
                    "targetId": event_payload["player_targeted_id"],
                    "eventId": event_payload["event_id"],
                },
                {
                    "time": event_payload["end"],
                    "kind": "receive",
                    "actorId": event_payload["player_targeted_id"],
                    "eventId": event_payload["event_id"],
                },
            ]
        )
    steps.sort(key=lambda value: value["time"])
    replay = {
        "fps": fps,
        "poseStep": 1,
        "duration": duration,
        "startClock": rows[0]["clock"],
        "pitch": [
            float(passes[0]["stadiumMetadata"]["pitchLength"]),
            float(passes[0]["stadiumMetadata"]["pitchWidth"]),
        ],
        "match": {
            "id": int(metadata["id"]),
            "date": metadata["date"].split("T")[0],
            "home": metadata["homeTeam"]["name"],
            "away": metadata["awayTeam"]["name"],
        },
        "players": players,
        "joints": [],
        "frames": frames,
        "visibility": visibility,
        "ballVisibility": ball_visibility,
        "displayFrames": [],
        "displayProvenance": [],
        "missingPlayerCoordinate": MISSING,
        "sourcePossessionOwners": owners,
        "poses": [],
        "events": event_payloads,
        "sourceCommit": tracking_file["sha256"],
        "sourceUrl": tracking_file["url"],
        "sourceFrameStart": start_frame,
        "period": period,
        "coverage": "broadcastVisible",
        "annotationSource": "derived",
        "ballHeightAvailable": any(ball_height_valid),
        "ballHeightValid": ball_height_valid,
        "ballHeightSource": "pinned-source-z-cm-v1",
        "scene": {
            "id": clip_id,
            "category": (
                "combination"
                if objective == "thirdPlayer"
                else "penetration"
                if objective == "receivingLane"
                else "switchPlay"
            ),
            "titleKey": f"spatialEducationObjective{objective_suffix}",
            "focusKey": f"spatialEducation{objective_suffix}Question",
            "homeColor": home_kit["primaryColor"],
            "awayColor": away_kit["primaryColor"],
            "homeNumberColor": home_kit["primaryTextColor"],
            "awayNumberColor": away_kit["primaryTextColor"],
            "attackDirection": attack_direction,
            "focusPlayerId": focus,
            "camera": [-53.9, 53.9, -35.4, 35.4],
            "steps": steps,
            "outcome": "end",
        },
    }
    asset_hash = hashlib.sha256(json_bytes(replay)).hexdigest()
    first_departure = pass_actor(passes[0])
    evidence_anchors = [
        {
            "time": local(release_rows[0]),
            "role": "departure",
            "playerId": first_departure,
            "playerName": names[first_departure],
        }
    ]
    if len(passes) == 2:
        first_receiver = pass_receiver(passes[0])
        evidence_anchors.append(
            {
                "time": local(receive_rows[0]),
                "role": "arrival",
                "playerId": first_receiver,
                "playerName": names[first_receiver],
            }
        )
    evidence_anchors.append(
        {
            "time": outcome_time,
            "role": "arrival",
            "playerId": focus,
            "playerName": names[focus],
        }
    )
    highlight = list(dict.fromkeys([*core_ids, opponent]))
    catalog_scene = {
        "id": clip_id,
        "asset": f"assets/scan_pass_spatial/education_scenes/{clip_id}.json",
        "assetSha256": asset_hash,
        "theme": (
            "combination"
            if objective == "thirdPlayer"
            else "forwardConnection"
            if objective == "receivingLane"
            else "lateralSwitch"
        ),
        "matchId": int(metadata["id"]),
        "date": metadata["date"].split("T")[0],
        "season": "2022",
        "home": metadata["homeTeam"]["name"],
        "away": metadata["awayTeam"]["name"],
        "period": period,
        "startFrame": start_frame,
        "endFrame": end_frame,
        "startClock": rows[0]["clock"],
        "duration": duration,
        "focusPlayerId": focus,
        "focusPlayerName": names[focus],
        "evidenceAnchors": evidence_anchors,
        "highlightPlayerIds": highlight,
        "attackingTeam": "home" if attacking_home else "away",
        "attackDirection": attack_direction,
        "evidenceStart": local(release_rows[0]),
        "evidenceEnd": outcome_time,
        "coreStart": local(release_rows[0]) - 0.5,
        "coreEnd": outcome_time + 0.5,
        "corePlayerIds": core_ids,
        "supportPlayerIds": support_ids,
        "opponentContextPlayerIds": [opponent],
        "metrics": {
            "forwardMeters": rounded(forward),
            "lateralMeters": rounded(abs(focus_outcome[1] - focus_start[1])),
            "startWidthMeters": rounded(abs(focus_start[1])),
            "insideGainMeters": rounded(abs(focus_start[1]) - abs(focus_outcome[1])),
            "pressureMeters": None,
            "carryMeters": 0.0,
            "sequenceSeconds": rounded(outcome_time - local(release_rows[0])),
        },
        "sourceCommit": tracking_file["sha256"],
        "sourceUrl": tracking_file["url"],
        "learning": learning,
        "sourceActions": [],
    }
    proof = {
        "sceneId": clip_id,
        "assetSha256": asset_hash,
        "matchId": int(metadata["id"]),
        "period": period,
        "sourceFrames": {"start": start_frame, "end": end_frame, **source_frames},
        "periodClock": {"start": rows[0]["clock"], "end": rows[-1]["clock"]},
        "connectionEventIds": connection_ids,
        "possessionEventIds": [int(event["possessionEventId"]) for event in passes],
        "gameEventIds": [int(event["gameEventId"]) for event in passes],
        "eventBallHeightCategories": [
            event["possessionEvents"].get("ballHeightType") for event in passes
        ],
        "trackingAnchorOffsets": [
            {
                "connectionEventId": source_event_id(event),
                "release": {
                    "providerTime": event["eventTime"],
                    "trackingTime": release["time"],
                    "offsetSeconds": rounded(release["time"] - event["eventTime"]),
                    "sourceFrame": release["frame"],
                },
                "reception": {
                    "providerTime": receipt["startTime"],
                    "trackingTime": receive["time"],
                    "offsetSeconds": rounded(receive["time"] - receipt["startTime"]),
                    "sourceFrame": receive["frame"],
                },
            }
            for event, receipt, release, receive in zip(
                passes, receptions, release_rows, receive_rows
            )
        ],
        "attackDirection": {
            "providerCode": attack_value,
            "normalized": attack_direction,
        },
        "actors": {
            "focus": actor(focus),
            "support": [actor(value) for value in support_ids],
            "opponent": actor(opponent),
        },
        "coverage": {
            "frames": len(rows),
            "visibleBallFrames": sum(ball_visibility),
            "missingBallFrames": len(rows) - sum(ball_visibility),
            "missingPlayerSamples": sum(
                value == 0 for row in visibility for value in row
            ),
            "lowConfidenceVisiblePlayerSamples": low_confidence_visible,
        },
        "limitations": [
            "Only raw VISIBLE tracking is rendered; ESTIMATED/off-camera samples remain missing.",
            "VISIBLE denotes position visibility; LOW/MEDIUM identity confidence is preserved, and event/roster IDs do not independently verify every off-ball identity.",
            "Event height codes are categorical and are not converted to numeric ball Z.",
            "Ownership is the visible source game-event player, not a nearest-player heuristic.",
        ],
    }
    return catalog_scene, proof, replay


def source_manifest() -> dict[str, Any]:
    files = []
    for match_id, values in SOURCE_FILES.items():
        for value in values.values():
            files.append({"matchId": match_id, **value})
    files.extend({"matchId": None, **value} for value in SPEC_FILES.values())
    return {
        "version": 1,
        "provider": "PFF FC",
        "release": "Enhanced 2022 World Cup Dataset",
        "officialReleaseUrl": PUBLIC_FOLDER,
        "legacyReleasePage": "https://www.blog.fc.pff.com/blog/enhanced-2022-world-cup-dataset",
        "dynamicFormId": "R4ZPQU",
        "license": "Public release; no separate license stated",
        "inventoryCounts": {
            "metadata": 64,
            "rosters": 64,
            "eventsIncludingSpecifications": 67,
            "trackingIncludingSpecification": 65,
        },
        "acquired": {"matches": 3, "matchFiles": 12, "specifications": 2},
        "files": files,
    }


def source_pin(match_id: int) -> dict[str, Any]:
    files = [*SOURCE_FILES[match_id].values(), *SPEC_FILES.values()]
    return {
        "key": f"pff-world-cup-2022-{match_id}",
        "provider": "PFF FC",
        "license": "Public release; no separate license stated",
        "revision": SOURCE_FILES[match_id]["tracking"]["sha256"],
        "sourceUrl": PUBLIC_FOLDER,
        "matchIds": [match_id],
        "sourceFiles": [
            {key: value[key] for key in ("role", "fileId", "sha256", "bytes", "url")}
            for value in files
        ],
    }


def verify_sources(raw_root: Path) -> None:
    for values in [*SOURCE_FILES.values(), SPEC_FILES]:
        for value in values.values():
            path = raw_root / value["relativePath"]
            if not path.is_file():
                raise FileNotFoundError(path)
            if path.stat().st_size != value["bytes"] or sha256(path) != value["sha256"]:
                raise ValueError(f"Pinned source mismatch: {path}")


def generate(raw_root: Path, cache_dir: Path | None = None) -> None:
    verify_sources(raw_root)
    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    original_scenes = [
        scene for scene in catalog["scenes"] if scene["matchId"] not in SOURCE_FILES
    ]
    if len(original_scenes) != 70:
        raise ValueError("The compatible 70-scene base catalog is not intact")
    generated_scenes = []
    generated_proofs = []
    generated_replays: dict[str, dict[str, Any]] = {}
    rejected_candidates = []
    for match_id, definitions in CLIPS.items():
        metadata = json.loads(
            (raw_root / f"metadata/{match_id}.json").read_text(encoding="utf-8")
        )[0]
        roster = json.loads(
            (raw_root / f"rosters/{match_id}.json").read_text(encoding="utf-8")
        )
        events = json.loads(
            (raw_root / f"events/{match_id}.json").read_text(encoding="utf-8")
        )
        event_by_id = {
            int(value["possessionEventId"]): value
            for value in events
            if value.get("possessionEventId") is not None
        }
        roster_by_id = {int(value["player"]["id"]): value for value in roster}
        key_to_id = {
            (
                value["team"]["id"] == metadata["homeTeam"]["id"],
                str(value["shirtNumber"]),
            ): int(value["player"]["id"])
            for value in roster
            if value.get("shirtNumber") is not None
        }
        prepared = []
        for clip_id, first_id, second_id in definitions:
            try:
                passes = [event_by_id[first_id]]
                if second_id is not None:
                    passes.append(event_by_id[second_id])
                receptions = [receiver_event(events, value) for value in passes]
            except (KeyError, ValueError) as error:
                reason = (
                    f"{clip_id}: possession event {error.args[0]} is unavailable"
                    if isinstance(error, KeyError)
                    else f"{clip_id}: {error}"
                )
                rejected_candidates.append(
                    {
                        "sceneId": clip_id,
                        "matchId": match_id,
                        "possessionEventIds": [
                            value for value in (first_id, second_id) if value is not None
                        ],
                        "reason": reason,
                    }
                )
                continue
            prepared.append((clip_id, passes, receptions, []))
        cache_paths: dict[str, Path | None] = {
            clip_id: cache_dir / f"{clip_id}.json" if cache_dir else None
            for clip_id, _, _, _ in prepared
        }
        missing_cache = []
        for clip_id, passes, receptions, rows in prepared:
            path = cache_paths[clip_id]
            if path is not None and path.is_file():
                cached = json.loads(cache_paths[clip_id].read_text(encoding="utf-8"))
                if cached["sourceSha256"] != SOURCE_FILES[match_id]["tracking"]["sha256"]:
                    raise ValueError(f"Stale importer cache: {clip_id}")
                if cached.get("normalizationVersion") != CACHE_NORMALIZATION_VERSION:
                    missing_cache.append((clip_id, passes, receptions, rows))
                    continue
                for row in cached["rows"]:
                    row["players"] = {
                        int(player_id): tuple(value)
                        for player_id, value in row["players"].items()
                    }
                    row["ball"] = None if row["ball"] is None else tuple(row["ball"])
                    rows.append(row)
            else:
                missing_cache.append((clip_id, passes, receptions, rows))
        if missing_cache:
            minimum = min(value[1][0]["eventTime"] - 7 for value in missing_cache)
            maximum = max(value[1][0]["eventTime"] + 26 for value in missing_cache)
            with bz2.open(raw_root / f"tracking/{match_id}.jsonl.bz2", "rt") as handle:
                for line in handle:
                    raw = json.loads(line)
                    time = float(raw["videoTimeMs"]) / 1000
                    if time < minimum:
                        continue
                    if time > maximum:
                        break
                    targets = [
                        value
                        for value in missing_cache
                        if value[1][0]["eventTime"] - 7
                        <= time
                        <= value[1][0]["eventTime"] + 26
                    ]
                    if not targets:
                        continue
                    normalized = normalize_tracking(raw, key_to_id)
                    for _, _, _, rows in targets:
                        rows.append(normalized)
            if cache_dir is not None:
                cache_dir.mkdir(parents=True, exist_ok=True)
                for clip_id, _, _, rows in missing_cache:
                    write_json(
                        cache_paths[clip_id],
                        {
                            "normalizationVersion": CACHE_NORMALIZATION_VERSION,
                            "sourceSha256": SOURCE_FILES[match_id]["tracking"]["sha256"],
                            "rows": rows,
                        },
                    )
        for clip_id, passes, receptions, rows in prepared:
            try:
                scene, proof, replay = build_clip(
                    clip_id,
                    passes,
                    receptions,
                    rows,
                    metadata,
                    roster_by_id,
                    SOURCE_FILES[match_id]["tracking"],
                )
            except (KeyError, ValueError) as error:
                reason = (
                    f"{clip_id}: required player {error.args[0]} is not directly "
                    "observed at an evidence frame"
                    if isinstance(error, KeyError)
                    else str(error)
                )
                rejected_candidates.append(
                    {
                        "sceneId": clip_id,
                        "matchId": match_id,
                        "possessionEventIds": [
                            int(event["possessionEventId"]) for event in passes
                        ],
                        "reason": reason,
                    }
                )
                continue
            generated_scenes.append(scene)
            generated_proofs.append(proof)
            generated_replays[clip_id] = replay

    accepted_match_ids = {scene["matchId"] for scene in generated_scenes}
    missing_matches = set(CLIPS) - accepted_match_ids
    print(
        json.dumps(
            {
                "accepted": [scene["id"] for scene in generated_scenes],
                "rejected": rejected_candidates,
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    if missing_matches:
        raise ValueError(
            "No evidence-valid candidate for acquired match(es): "
            + ", ".join(str(value) for value in sorted(missing_matches))
        )
    accepted_ids = {scene["id"] for scene in generated_scenes}
    if accepted_ids != EXPECTED_ACCEPTED_IDS:
        raise ValueError(
            "Accepted World Cup IDs changed; review and explicitly update the frozen set: "
            + json.dumps(sorted(accepted_ids), ensure_ascii=False)
        )

    for path in SCENE_ROOT.glob("pff-*.json"):
        path.unlink()
    for clip_id, replay in generated_replays.items():
        write_json(SCENE_ROOT / f"{clip_id}.json", replay)

    catalog.update(
        {
            "version": 3,
            "provider": "Mixed pinned sources",
            "license": "Per-source terms",
            "proofVersion": "spatial-education-catalog-v3",
            "sourceCommit": "mixed-pinned-sources-v2",
            "sourceUrl": PUBLIC_FOLDER,
            "matchCount": len(
                {scene["matchId"] for scene in [*original_scenes, *generated_scenes]}
            ),
            "sourcePins": [
                *[pin for pin in catalog["sourcePins"] if pin["provider"] == "SkillCorner Open Data"],
                *[source_pin(match_id) for match_id in (10517, 10507, 3857)],
            ],
            "scenes": [*original_scenes, *generated_scenes],
        }
    )
    write_json(CATALOG_PATH, catalog)
    write_json(MANIFEST_PATH, source_manifest())
    write_json(
        PROOF_PATH,
        {
            "version": 1,
            "proofContract": "pff-visible-event-linked-spatial-v2",
            "candidateCount": sum(len(values) for values in CLIPS.values()),
            "sceneCount": len(generated_proofs),
            "matchSceneCounts": {
                str(match_id): sum(
                    proof["matchId"] == match_id for proof in generated_proofs
                )
                for match_id in (10517, 10507, 3857)
            },
            "scenes": generated_proofs,
            "rejectedCandidates": rejected_candidates,
            "screenedExclusions": [
                {
                    "matchId": 10517,
                    "possessionEventId": 6622730,
                    "player": "Rodrigo de Paul",
                    "reason": "The measured focus run contains a direct-visibility gap.",
                },
                {
                    "matchId": 10517,
                    "possessionEventId": 6623823,
                    "player": "Lionel Messi",
                    "reason": "The measured focus run contains a direct-visibility gap.",
                },
                {
                    "matchId": 10517,
                    "possessionEventId": 6623294,
                    "player": "Kylian Mbappé",
                    "reason": "Target receiver anchor is not directly observed.",
                },
                {
                    "matchId": 3857,
                    "possessionEventId": 6507212,
                    "player": "Heung-min Son",
                    "reason": "Target receiver anchor is not directly observed.",
                },
            ],
        },
    )
    verify_assets()


def verify_assets() -> None:
    if json.loads(MANIFEST_PATH.read_text(encoding="utf-8")) != source_manifest():
        raise ValueError("World Cup source manifest does not match the pinned importer")
    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    proof = json.loads(PROOF_PATH.read_text(encoding="utf-8"))
    pff_scenes = [scene for scene in catalog["scenes"] if scene["matchId"] in SOURCE_FILES]
    candidate_ids = {
        clip_id for definitions in CLIPS.values() for clip_id, _, _ in definitions
    }
    rejected_ids = {value["sceneId"] for value in proof["rejectedCandidates"]}
    if (
        catalog["version"] != 3
        or len(catalog["scenes"]) != 70 + proof["sceneCount"]
        or len(pff_scenes) != proof["sceneCount"]
        or {scene["id"] for scene in pff_scenes} != EXPECTED_ACCEPTED_IDS
        or proof["candidateCount"] != len(candidate_ids)
        or proof["candidateCount"]
        != proof["sceneCount"] + len(proof["rejectedCandidates"])
        or EXPECTED_ACCEPTED_IDS | rejected_ids != candidate_ids
        or EXPECTED_ACCEPTED_IDS & rejected_ids
        or any(proof["matchSceneCounts"].get(str(match_id), 0) < 1 for match_id in SOURCE_FILES)
    ):
        raise ValueError("World Cup catalog counts are invalid")
    if [scene["matchId"] for scene in catalog["scenes"][:70] if scene["matchId"] in SOURCE_FILES]:
        raise ValueError("World Cup scenes changed the compatible catalog prefix")
    proof_by_id = {value["sceneId"]: value for value in proof["scenes"]}
    expected_assets = {f"{scene['id']}.json" for scene in pff_scenes}
    actual_assets = {path.name for path in SCENE_ROOT.glob("pff-*.json")}
    if actual_assets != expected_assets:
        raise ValueError("Orphaned or missing World Cup scene assets")
    for scene in catalog["scenes"]:
        path = REPO / scene["asset"]
        if sha256(path) != scene["assetSha256"]:
            raise ValueError(f"Catalog asset hash mismatch: {scene['id']}")
        if scene not in pff_scenes:
            continue
        replay = json.loads(path.read_text(encoding="utf-8"))
        if replay["fps"] != 29.97 or replay["displayFrames"] or replay["displayProvenance"]:
            raise ValueError(f"Invalid World Cup replay contract: {scene['id']}")
        if (
            scene["duration"] < 15
            or scene["duration"] > 40
            or scene["learning"]["movementStart"] < 4
            or scene["duration"] - scene["learning"]["outcome"] < 4
        ):
            raise ValueError(f"Invalid World Cup context window: {scene['id']}")
        for frame, visible, ball_visible, ball_height in zip(
            replay["frames"],
            replay["visibility"],
            replay["ballVisibility"],
            replay["ballHeightValid"],
        ):
            if not any(visible):
                raise ValueError(f"Empty World Cup pitch frame: {scene['id']}")
            for index, flag in enumerate(visible):
                if not flag and frame[index * 2 : index * 2 + 2] != [MISSING, MISSING]:
                    raise ValueError(f"Hidden player coordinates leaked: {scene['id']}")
            if not ball_visible and frame[-3:] != [0, 0, 0]:
                raise ValueError(f"Hidden ball coordinates leaked: {scene['id']}")
            if bool(ball_visible) != bool(ball_height):
                raise ValueError(f"Ball Z validity mismatch: {scene['id']}")
        event_ids = {event["event_id"] for event in replay["events"]}
        if set(scene["learning"]["sourceConnectionEventIds"]) != event_ids:
            raise ValueError(f"Provider event links are incomplete: {scene['id']}")
        if proof_by_id[scene["id"]]["assetSha256"] != scene["assetSha256"]:
            raise ValueError(f"World Cup proof hash mismatch: {scene['id']}")
        for anchors in proof_by_id[scene["id"]]["trackingAnchorOffsets"]:
            for role in ("release", "reception"):
                if abs(anchors[role]["offsetSeconds"]) > 1 / replay["fps"] + 0.0011:
                    raise ValueError(f"World Cup event anchor drift: {scene['id']}")
    print(
        f"Verified {len(pff_scenes)} PFF clips across "
        f"{len({scene['matchId'] for scene in pff_scenes})} matches."
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--raw-root", type=Path, default=DEFAULT_RAW_ROOT)
    parser.add_argument("--cache-dir", type=Path)
    parser.add_argument("--verify-assets", action="store_true")
    args = parser.parse_args()
    if args.verify_assets:
        verify_assets()
    else:
        generate(
            args.raw_root.resolve(),
            cache_dir=args.cache_dir.resolve() if args.cache_dir else None,
        )


if __name__ == "__main__":
    main()
