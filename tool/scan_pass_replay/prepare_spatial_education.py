#!/usr/bin/env python3
"""Build and verify the evidence-led spatial education catalogue.

Version 1 remains an immutable archive.  This tool audits every archived scene,
recomputes each accepted lesson from observed replay frames, then independently
adapts pinned 2024/25 tracking.  In the recent feed an actor exists for evidence
only when ``player_data.is_detected is true`` and the ball exists only when
``ball_data.is_detected is true``.  Extrapolated coordinates are never copied.
"""

from __future__ import annotations

import argparse
import collections
import csv
import hashlib
import json
import math
import shutil
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
ASSETS = REPO / "assets/scan_pass_spatial"
ARCHIVE_CATALOG = ASSETS / "catalog.json"
EDUCATION_CATALOG = ASSETS / "education-catalog.json"
EDUCATION_PROOF = ASSETS / "education-proof.json"
EDUCATION_MANIFEST = ASSETS / "education-source-manifest.json"
EDUCATION_SCENES = ASSETS / "education_scenes"
FPS = 10
MISSING = -(2**31)
HISTORICAL_COMMIT = "1ed50b775f93075c2a6d00d0d795f13b7b89709e"
RECENT_COMMIT = "4340d274572876239c154c90bc507a9b3250a656"
PROOF_VERSION = "spatial-education-evidence-v2"
CATALOG_PROOF_VERSION = "spatial-education-catalog-v2"
ACTION_PROOF_VERSION = "spatial-source-actions-v1"
QUANTIZATION_METERS = 0.005
ACTION_CONTROL_MAXIMUM_METERS = 3.5
ACTION_CARRY_MINIMUM_METERS = 2.0
ACTION_DIRECTION_LEG_MINIMUM_METERS = 1.5
ACTION_DIRECTION_MINIMUM_DEGREES = 55.0
REFERENCES = {
    "receivingLane": "https://www.fifatrainingcentre.com/en/practice/talent-coach-programme/build-and-progress/passing-circuit-receiving-between-the-lines.php",
    "pressureOutlet": "https://www.fifatrainingcentre.com/en/practice/talent-coach-programme/build-and-progress/passing-circuit-receiving-between-the-lines.php",
    "thirdPlayer": "https://www.fifatrainingcentre.com/en/game/game-analysis/in-possession/third-player-combinations.php",
    "switchingSpace": "https://www.fifatrainingcentre.com/en/game/game-analysis/in-possession/switch-of-play.php",
}
OBJECTIVE_SUFFIX = {
    "receivingLane": "ReceivingLane",
    "pressureOutlet": "PressureOutlet",
    "thirdPlayer": "ThirdPlayer",
    "switchingSpace": "SwitchingSpace",
}


def read_json(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def encoded(value: object) -> bytes:
    return (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode()


def save(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(encoded(value))


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def actor(data: dict, player_id: int) -> dict:
    player = next(item for item in data["players"] if item["id"] == player_id)
    return {"playerId": player_id, "playerName": player["name"]}


def index_by_id(data: dict) -> dict[int, int]:
    return {player["id"]: index for index, player in enumerate(data["players"])}


def point(data: dict, player_id: int, frame: int) -> tuple[float, float] | None:
    indices = index_by_id(data)
    index = indices.get(player_id)
    if index is None or frame < 0 or frame >= len(data["frames"]):
        return None
    if not data["visibility"][frame][index]:
        return None
    row = data["frames"][frame]
    return row[index * 2] / 100, row[index * 2 + 1] / 100


def ball(data: dict, frame: int) -> tuple[float, float] | None:
    if frame < 0 or frame >= len(data["frames"]):
        return None
    if data.get("ballVisibility") and not data["ballVisibility"][frame]:
        return None
    row = data["frames"][frame]
    return row[-3] / 100, row[-2] / 100


def distance(a: tuple[float, float], b: tuple[float, float]) -> float:
    return math.hypot(a[0] - b[0], a[1] - b[1])


def angle_degrees(
    origin: tuple[float, float],
    first: tuple[float, float],
    second: tuple[float, float],
) -> float:
    a = first[0] - origin[0], first[1] - origin[1]
    b = second[0] - origin[0], second[1] - origin[1]
    denominator = math.hypot(*a) * math.hypot(*b)
    if denominator <= 1e-9:
        return 0.0
    cosine = max(-1.0, min(1.0, (a[0] * b[0] + a[1] * b[1]) / denominator))
    return math.degrees(math.acos(cosine))


def segment_projection(
    start: tuple[float, float],
    end: tuple[float, float],
    point_value: tuple[float, float],
) -> float:
    dx, dy = end[0] - start[0], end[1] - start[1]
    denominator = dx * dx + dy * dy
    if denominator <= 1e-9:
        return math.inf
    return (
        (point_value[0] - start[0]) * dx
        + (point_value[1] - start[1]) * dy
    ) / denominator


def line_gap(
    start: tuple[float, float],
    end: tuple[float, float],
    point_value: tuple[float, float],
) -> float:
    dx, dy = end[0] - start[0], end[1] - start[1]
    denominator = math.hypot(dx, dy)
    if denominator <= 1e-9:
        return math.inf
    return abs(dx * (point_value[1] - start[1]) - dy * (point_value[0] - start[0])) / denominator


def continuous(data: dict, player_id: int, start: int, end: int) -> bool:
    return all(point(data, player_id, frame) is not None for frame in range(start, end + 1))


def opponents(data: dict, player_id: int, start: int, end: int) -> list[int]:
    player = next(item for item in data["players"] if item["id"] == player_id)
    return [
        item["id"]
        for item in data["players"]
        if item["home"] != player["home"] and continuous(data, item["id"], start, end)
    ]


def owner_at(data: dict, frame: int) -> int | None:
    owners = data.get("sourcePossessionOwners", [])
    return owners[frame] if 0 <= frame < len(owners) else None


def same_team(data: dict, first: int, second: int) -> bool:
    values = {player["id"]: player["home"] for player in data["players"]}
    return values.get(first) == values.get(second)


def next_controlled_owner(
    data: dict, receiver: int, outcome: int, maximum: int
) -> tuple[int, int] | None:
    for frame in range(outcome + 1, min(len(data["frames"]), maximum + 1)):
        candidate = owner_at(data, frame)
        if candidate is None or candidate == receiver:
            continue
        if not same_team(data, receiver, candidate):
            return None
        player_point = point(data, candidate, frame)
        ball_point = ball(data, frame)
        if player_point is not None and ball_point is not None and distance(player_point, ball_point) <= 3.5:
            return frame, candidate
    return None


def ordered_ownership(
    data: dict,
    anchors: list[tuple[int, int]],
) -> bool:
    """Require each source-labelled connection without intervening ownership."""
    for (start, first), (end, second) in zip(anchors, anchors[1:]):
        if start >= end or owner_at(data, start) != first or owner_at(data, end) != second:
            return False
        advanced = False
        for frame in range(start, end + 1):
            owner = owner_at(data, frame)
            if owner is None:
                continue
            if owner == second:
                advanced = True
            elif owner != first or advanced:
                return False
    return True


def base_lesson(
    objective: str,
    data: dict,
    source_start: int,
    focus_id: int,
    support_ids: list[int],
    opponent_ids: list[int],
    movement_start: int,
    trigger: int,
    outcome: int,
    measurement: str,
    before: float,
    after: float,
    movement: float,
    *,
    next_value: tuple[int, int] | None = None,
    pressure: float | None = None,
    lateral: float | None = None,
    forward: float | None = None,
    receiver_contribution: float | None = None,
    projection_before: float | None = None,
    projection_after: float | None = None,
    movement_alignment: float | None = None,
    baseline_line_gap: float | None = None,
    after_line_gap: float | None = None,
    receiver_line_gap_contribution: float | None = None,
) -> dict:
    suffix = OBJECTIVE_SUFFIX[objective]
    local = lambda frame: round(frame / FPS, 3)
    return {
        "objective": objective,
        "proofVersion": PROOF_VERSION,
        "referenceUrls": [REFERENCES[objective]],
        "questionKey": f"spatialEducation{suffix}Question",
        "actionKey": f"spatialEducation{suffix}Action",
        "resultKey": f"spatialEducation{suffix}Result",
        "focusActor": actor(data, focus_id),
        "supportActors": [actor(data, value) for value in support_ids],
        "opponentActors": [actor(data, value) for value in opponent_ids],
        "nextActor": actor(data, next_value[1]) if next_value else None,
        "movementStart": local(movement_start),
        "trigger": local(trigger),
        "outcome": local(outcome),
        "slowStart": local(movement_start),
        "slowEnd": local(outcome),
        "nextConnection": local(next_value[0]) if next_value else None,
        "sourceFrames": {
            "movementStart": source_start + movement_start,
            "trigger": source_start + trigger,
            "outcome": source_start + outcome,
            "nextConnection": source_start + next_value[0] if next_value else None,
        },
        "measurements": {
            "kind": measurement,
            "before": round(before, 3),
            "after": round(after, 3),
            "improvement": round(after - before, 3),
            "movementMeters": round(movement, 3),
            "pressureMeters": round(pressure, 3) if pressure is not None else None,
            "lateralMeters": round(lateral, 3) if lateral is not None else None,
            "forwardMeters": round(forward, 3) if forward is not None else None,
            "receiverContributionDegrees": (
                round(receiver_contribution, 3)
                if receiver_contribution is not None else None
            ),
            "defenderProjectionBefore": (
                round(projection_before, 3)
                if projection_before is not None else None
            ),
            "defenderProjectionAfter": (
                round(projection_after, 3)
                if projection_after is not None else None
            ),
            "movementAlignment": (
                round(movement_alignment, 3)
                if movement_alignment is not None else None
            ),
            "baselinePassLineGapMeters": (
                round(baseline_line_gap, 3)
                if baseline_line_gap is not None else None
            ),
            "afterPassLineGapMeters": (
                round(after_line_gap, 3)
                if after_line_gap is not None else None
            ),
            "receiverLineGapContributionMeters": (
                round(receiver_line_gap_contribution, 3)
                if receiver_line_gap_contribution is not None else None
            ),
            "quantizationMeters": QUANTIZATION_METERS,
        },
    }


def evaluate_objectives(
    data: dict,
    source_start: int,
    departure: int,
    reception: int,
    first_id: int,
    second_id: int,
    attack_direction: int,
    third: tuple[int, int] | None,
) -> tuple[dict[str, dict], dict[str, str]]:
    accepted: dict[str, dict] = {}
    rejected: dict[str, str] = {}
    baseline = departure - FPS
    if baseline < 4 * FPS or reception >= len(data["frames"]):
        return accepted, {value: "missing-one-second-observed-setup" for value in OBJECTIVE_SUFFIX}
    if owner_at(data, departure) != first_id or owner_at(data, reception) != second_id:
        return accepted, {value: "source-ownership-anchor-mismatch" for value in OBJECTIVE_SUFFIX}
    if not same_team(data, first_id, second_id):
        return accepted, {value: "connection-actors-are-not-same-team" for value in OBJECTIVE_SUFFIX}
    if any(ball(data, frame) is None for frame in range(departure, reception + 1)):
        return accepted, {value: "ball-not-continuously-observed" for value in OBJECTIVE_SUFFIX}
    for frame, player_id in ((departure, first_id), (reception, second_id)):
        player_point, ball_point = point(data, player_id, frame), ball(data, frame)
        if player_point is None or ball_point is None or distance(player_point, ball_point) > 3.5:
            return accepted, {value: "owner-not-observed-with-recorded-ball" for value in OBJECTIVE_SUFFIX}
    if not ordered_ownership(data, [(departure, first_id), (reception, second_id)]):
        return accepted, {
            value: "connection-has-intervening-or-reversed-possession"
            for value in OBJECTIVE_SUFFIX
        }

    common_opponents = opponents(data, second_id, baseline, reception)
    if not continuous(data, first_id, baseline, reception) or not continuous(data, second_id, baseline, reception):
        rejected["receivingLane"] = "passer-or-receiver-not-continuously-observed"
    elif not common_opponents:
        rejected["receivingLane"] = "no-continuously-observed-defender-context"
    else:
        candidates = []
        for defender in common_opponents:
            passer_before = point(data, first_id, baseline)
            passer_after = point(data, first_id, departure)
            receiver_before = point(data, second_id, baseline)
            receiver_after = point(data, second_id, departure)
            defender_before = point(data, defender, baseline)
            defender_after = point(data, defender, departure)
            before = angle_degrees(passer_before, receiver_before, defender_before)
            after = angle_degrees(passer_after, receiver_after, defender_after)
            projection_before = segment_projection(
                passer_before, receiver_before, defender_before,
            )
            projection_after = segment_projection(
                passer_after, receiver_after, defender_after,
            )
            frozen_receiver_angle = angle_degrees(
                passer_after, receiver_before, defender_after,
            )
            contribution = after - frozen_receiver_angle
            baseline_gap = line_gap(
                passer_before, receiver_before, defender_before,
            )
            after_gap = line_gap(
                passer_after, receiver_after, defender_after,
            )
            frozen_receiver_gap = line_gap(
                passer_after, receiver_before, defender_after,
            )
            gap_contribution = after_gap - frozen_receiver_gap
            if (
                -0.001 <= projection_before <= 1.001
                and -0.001 <= projection_after <= 1.001
            ):
                candidates.append((
                    contribution, after - before, defender, before, after,
                    projection_before, projection_after,
                    baseline_gap, after_gap, gap_contribution,
                ))
        if not candidates:
            rejected["receivingLane"] = "no-defender-on-finite-passing-segment"
        else:
            relevant_candidates = [
                item for item in candidates
                if item[7] <= 3.001 and item[3] <= 25.001
            ]
            if not relevant_candidates:
                rejected["receivingLane"] = "defender-too-far-from-baseline-pass-line"
            demonstrated_candidates = [
                item for item in relevant_candidates
                if item[1] + .001 >= 3
                and item[0] + .001 >= 1
                and item[8] - item[7] + .01 >= .5
                and item[9] + .01 >= .25
            ]
        if candidates and relevant_candidates and not demonstrated_candidates:
            best = max(
                relevant_candidates,
                key=lambda item: (item[0], item[1], -item[2]),
            )
            if best[1] + .001 < 3:
                rejected["receivingLane"] = "visible-passing-angle-gain-under-3-degrees"
            elif best[0] + .001 < 1:
                rejected["receivingLane"] = "receiver-motion-angle-contribution-under-1-degree"
            else:
                rejected["receivingLane"] = "receiver-does-not-create-line-clearance"
        if candidates and relevant_candidates and demonstrated_candidates:
            (
                contribution, _, defender, before, after,
                projection_before, projection_after,
                baseline_gap, after_gap, gap_contribution,
            ) = max(
                demonstrated_candidates,
                key=lambda item: (
                    min(
                        item[0],
                        item[1] / 3,
                        (item[8] - item[7]) / .5,
                        item[9] / .25,
                    ),
                    item[0], item[1], -item[2],
                ),
            )
        movement = distance(point(data, second_id, baseline), point(data, second_id, departure))
        if not candidates or not relevant_candidates or not demonstrated_candidates:
            pass
        elif movement + 0.01 < 0.75:
            rejected["receivingLane"] = "receiver-movement-before-release-under-0.75m"
        else:
            accepted["receivingLane"] = base_lesson(
                "receivingLane", data, source_start, second_id, [first_id], [defender], baseline,
                departure, reception, "laneAngleDegrees", before, after, movement,
                receiver_contribution=contribution,
                projection_before=projection_before,
                projection_after=projection_after,
                baseline_line_gap=baseline_gap,
                after_line_gap=after_gap,
                receiver_line_gap_contribution=gap_contribution,
            )

    clearance_ready = continuous(data, second_id, baseline, reception)
    clearance_opponents = opponents(data, second_id, baseline, reception) if clearance_ready else []
    comparison = None
    if clearance_opponents:
        comparison = min(
            clearance_opponents,
            key=lambda value: (distance(point(data, second_id, baseline), point(data, value, baseline)), value),
        )
    if comparison is None:
        rejected["switchingSpace"] = (
            "receiver-not-continuously-observed" if not clearance_ready
            else "no-continuously-observed-defender-context"
        )
        rejected["pressureOutlet"] = (
            "receiver-not-continuously-observed" if not clearance_ready
            else "no-continuously-observed-receiver-defender"
        )
    else:
        before = distance(point(data, second_id, baseline), point(data, comparison, baseline))
        after = distance(point(data, second_id, reception), point(data, comparison, reception))
        movement = distance(point(data, second_id, baseline), point(data, second_id, reception))
        lateral = abs(point(data, first_id, departure)[1] - point(data, second_id, reception)[1])
        if lateral + 0.01 < 22:
            rejected["switchingSpace"] = "lateral-connection-under-22m"
        elif after - before + 0.01 < 1:
            rejected["switchingSpace"] = "receiver-clearance-gain-under-1m"
        else:
            accepted["switchingSpace"] = base_lesson(
                "switchingSpace", data, source_start, second_id, [first_id], [comparison], baseline,
                departure, reception, "defenderClearanceMeters", before, after, movement,
                lateral=lateral,
            )

        pressure_opponents = opponents(data, first_id, baseline, reception) if continuous(data, first_id, baseline, reception) else []
        pressure_defender = min(
            pressure_opponents,
            key=lambda value: (distance(point(data, first_id, departure), point(data, value, departure)), value),
        ) if pressure_opponents else None
        pressure = distance(point(data, first_id, departure), point(data, pressure_defender, departure)) if pressure_defender else None
        next_value = next_controlled_owner(data, second_id, reception, reception + 8 * FPS)
        if pressure is None or pressure - 0.01 > 4:
            rejected["pressureOutlet"] = "passer-pressure-over-4m-or-unobserved"
        elif after - before + 0.01 < 1:
            rejected["pressureOutlet"] = "receiver-clearance-gain-under-1m"
        elif next_value is None:
            rejected["pressureOutlet"] = "no-uninterrupted-controlled-same-team-connection"
        elif not ordered_ownership(
            data,
            [(departure, first_id), (reception, second_id), next_value],
        ):
            rejected["pressureOutlet"] = "outlet-interrupted-before-next-connection"
        elif any(
            ball(data, frame) is None
            for frame in range(departure, next_value[0] + 1)
        ):
            rejected["pressureOutlet"] = "ball-hidden-before-next-connection"
        elif not continuous(data, next_value[1], baseline, next_value[0]):
            rejected["pressureOutlet"] = "next-connection-actor-not-continuously-observed"
        else:
            accepted["pressureOutlet"] = base_lesson(
                "pressureOutlet", data, source_start, second_id, [first_id, next_value[1]],
                [pressure_defender, comparison], baseline, departure, reception,
                "defenderClearanceMeters", before, after, movement,
                next_value=next_value, pressure=pressure,
            )

    if third is None:
        rejected["thirdPlayer"] = "no-observed-third-connection"
    else:
        third_frame, third_id = third
        movement_start = reception - FPS
        ids = {first_id, second_id, third_id}
        if len(ids) != 3:
            rejected["thirdPlayer"] = "aba-is-not-a-third-player-combination"
        elif movement_start < 0 or owner_at(data, third_frame) != third_id:
            rejected["thirdPlayer"] = "third-player-source-anchor-mismatch"
        elif (
            point(data, third_id, third_frame) is None
            or ball(data, third_frame) is None
            or distance(point(data, third_id, third_frame), ball(data, third_frame)) > 3.5
        ):
            rejected["thirdPlayer"] = "third-player-owner-not-observed-with-recorded-ball"
        elif not same_team(data, second_id, third_id):
            rejected["thirdPlayer"] = "third-player-actors-are-not-same-team"
        elif not ordered_ownership(
            data,
            [(departure, first_id), (reception, second_id), (third_frame, third_id)],
        ):
            rejected["thirdPlayer"] = "third-player-sequence-is-interrupted"
        elif any(ball(data, frame) is None for frame in range(departure, third_frame + 1)):
            rejected["thirdPlayer"] = "ball-hidden-during-third-player-sequence"
        elif not all(continuous(data, value, movement_start, third_frame) for value in ids):
            rejected["thirdPlayer"] = "third-player-actors-not-continuously-observed"
        else:
            start_point = point(data, third_id, movement_start)
            trigger_point = point(data, third_id, reception)
            outcome_point = point(data, third_id, third_frame)
            premove = distance(start_point, trigger_point)
            total = distance(start_point, outcome_point)
            if premove > 1e-9 and total > 1e-9:
                alignment = (
                    (trigger_point[0] - start_point[0]) * (outcome_point[0] - start_point[0])
                    + (trigger_point[1] - start_point[1]) * (outcome_point[1] - start_point[1])
                ) / (premove * total)
            else:
                alignment = -1
            context = opponents(data, third_id, movement_start, third_frame)
            defender = min(
                context,
                key=lambda value: (distance(start_point, point(data, value, movement_start)), value),
            ) if context else None
            forward = (outcome_point[0] - start_point[0]) * attack_direction
            clearance_before = distance(start_point, point(data, defender, movement_start)) if defender else 0
            clearance_after = distance(outcome_point, point(data, defender, third_frame)) if defender else 0
            if premove + 0.01 < 0.6:
                rejected["thirdPlayer"] = "third-player-movement-starts-too-late"
            elif total + 0.01 < 1:
                rejected["thirdPlayer"] = "third-player-total-movement-under-1m"
            elif alignment + 0.001 < 0.5:
                rejected["thirdPlayer"] = "pre-reception-movement-does-not-continue-to-outcome"
            elif defender is None:
                rejected["thirdPlayer"] = "no-continuously-observed-defender-context"
            elif forward + 0.01 >= 1.5:
                accepted["thirdPlayer"] = base_lesson(
                    "thirdPlayer", data, source_start, third_id, [first_id, second_id], [defender],
                    movement_start, reception, third_frame, "forwardAdvanceMeters", 0, forward,
                    premove, forward=forward, movement_alignment=alignment,
                )
            elif clearance_after - clearance_before + 0.01 >= 1:
                accepted["thirdPlayer"] = base_lesson(
                    "thirdPlayer", data, source_start, third_id, [first_id, second_id], [defender],
                    movement_start, reception, third_frame, "defenderClearanceMeters",
                    clearance_before, clearance_after, premove, forward=forward,
                    movement_alignment=alignment,
                )
            else:
                rejected["thirdPlayer"] = "no-1.5m-advance-or-1m-clearance-gain"
    return accepted, rejected


def choose_archive_objective(theme: str, accepted: dict[str, dict]) -> str | None:
    preferred = {
        "combination": "thirdPlayer",
        "lateralSwitch": "switchingSpace",
        "pressureSupport": "pressureOutlet",
    }.get(theme)
    if preferred in accepted:
        return preferred
    for value in ("receivingLane", "thirdPlayer", "pressureOutlet", "switchingSpace"):
        if value in accepted:
            return value
    return None


def audit_archive() -> tuple[list[dict], list[dict]]:
    catalogue = read_json(ARCHIVE_CATALOG)
    selected, audit = [], []
    for scene in catalogue["scenes"]:
        data = read_json(REPO / scene["asset"])
        anchors = scene["evidenceAnchors"]
        departure = round(anchors[0]["time"] * data["fps"])
        reception = round(anchors[1]["time"] * data["fps"])
        third = (
            (round(anchors[2]["time"] * data["fps"]), anchors[2]["playerId"])
            if len(anchors) == 3 else None
        )
        accepted, rejected = evaluate_objectives(
            data, scene["startFrame"], departure, reception,
            anchors[0]["playerId"], anchors[1]["playerId"], scene["attackDirection"], third,
        )
        objective = choose_archive_objective(scene["theme"], accepted)
        decision = {
            "id": scene["id"],
            "matchId": scene["matchId"],
            "source": "archive-2019-20",
            "accepted": objective is not None,
            "objective": objective,
            "acceptedRules": sorted(accepted),
            "rejectedRules": rejected,
        }
        if objective is None:
            decision["reason"] = "no-education-objective-has-observed-before-after-proof"
        else:
            entry = json.loads(json.dumps(scene))
            entry["season"] = "2019/20"
            entry["learning"] = accepted[objective]
            entry["highlightPlayerIds"] = sorted(
                set(entry["highlightPlayerIds"])
                | lesson_actor_ids(entry["learning"])
            )
            selected.append(entry)
            decision["reason"] = "objective-thresholds-recomputed-from-observed-frames"
            decision["measurements"] = entry["learning"]["measurements"]
        audit.append(decision)
    if len(audit) != 72:
        raise ValueError("Archive audit must account for all 72 original scenes")
    return selected, audit


def lesson_actor_ids(lesson: dict) -> set[int]:
    values = {lesson["focusActor"]["playerId"]}
    values.update(item["playerId"] for item in lesson["supportActors"])
    values.update(item["playerId"] for item in lesson["opponentActors"])
    if lesson.get("nextActor"):
        values.add(lesson["nextActor"]["playerId"])
    return values


def load_recent_frames(path: Path, known_ids: set[int]) -> tuple[list[dict], int]:
    frames: list[dict] = []
    extrapolated_ignored = 0
    with path.open(encoding="utf-8") as handle:
        for expected, line in enumerate(handle):
            source = json.loads(line)
            if source["frame"] != expected:
                raise ValueError(f"Non-contiguous source frame in {path}")
            observed: dict[int, tuple[float, float]] = {}
            for item in source.get("player_data", []):
                player_id = item.get("player_id")
                if player_id not in known_ids:
                    continue
                if item.get("is_detected") is not True:
                    extrapolated_ignored += 1
                    continue
                x, y = item.get("x"), item.get("y")
                if not isinstance(x, (int, float)) or not isinstance(y, (int, float)):
                    raise ValueError("Detected player is missing XY")
                observed[player_id] = (float(x), float(y))
            raw_ball = source.get("ball_data") or {}
            ball_point = None
            if raw_ball.get("is_detected") is True:
                x, y = raw_ball.get("x"), raw_ball.get("y")
                if not isinstance(x, (int, float)) or not isinstance(y, (int, float)):
                    raise ValueError("Detected ball is missing XY")
                ball_point = (float(x), float(y))
            frames.append({
                "frame": expected,
                "timestamp": source.get("timestamp"),
                "period": source.get("period"),
                "ball": ball_point,
                "owner": (source.get("possession") or {}).get("player_id"),
                "group": (source.get("possession") or {}).get("group"),
                "players": observed,
            })

    # Identity-linked detections with an adjacent speed above 15 m/s are not
    # usable observations. Match the historic continuity guard and remove a
    # window wide enough that the surviving observations do not imply a jump.
    exclusions: dict[int, set[int]] = collections.defaultdict(set)
    for player_id in known_ids:
        for frame in range(1, len(frames)):
            previous = frames[frame - 1]["players"].get(player_id)
            current = frames[frame]["players"].get(player_id)
            if previous is None or current is None:
                continue
            meters = distance(previous, current)
            if meters * FPS <= 15:
                continue
            needed = max(2, math.ceil(meters / 15 * FPS))
            start = max(0, frame - needed // 2)
            end = min(len(frames) - 1, start + needed - 1)
            exclusions[player_id].update(range(start, end + 1))
    removed = 0
    for player_id, values in exclusions.items():
        for frame in values:
            if frames[frame]["players"].pop(player_id, None) is not None:
                removed += 1
    return frames, extrapolated_ignored + removed


def recent_active_players(match: dict, start: int, end: int) -> list[dict]:
    values = []
    for player in match["players"]:
        playing = (player.get("playing_time") or {}).get("total") or {}
        player_start = playing.get("start_frame")
        player_end = playing.get("end_frame")
        if isinstance(player_start, int) and isinstance(player_end, int) and player_start <= start and player_end >= end - 1:
            values.append(player)
    if not (20 <= len(values) <= 22):
        raise ValueError(f"Clip does not have a stable active roster: {len(values)}")
    return sorted(values, key=lambda item: (item["team_id"], item.get("number") or 999, item["id"]))


def full_name(player: dict) -> str:
    value = " ".join(
        part.strip() for part in (player.get("first_name") or "", player.get("last_name") or "")
        if part.strip()
    )
    return value or player["short_name"]


def _source_bool(value: str, label: str) -> bool | None:
    if value == "":
        return None
    if value == "True":
        return True
    if value == "False":
        return False
    raise ValueError(f"Invalid source boolean for {label}: {value!r}")


def load_player_possession_actions(path: Path, match_id: int) -> list[dict]:
    required = {
        "event_id", "match_id", "frame_start", "frame_end", "period",
        "event_type", "player_id", "player_name", "start_type", "end_type",
        "one_touch", "carry", "is_header", "hand_pass",
        "is_player_possession_start_matched",
        "is_player_possession_end_matched", "is_previous_pass_matched",
        "is_pass_reception_matched",
        "fully_extrapolated",
    }
    values: list[dict] = []
    event_ids: set[str] = set()
    with path.open(newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None or not required.issubset(reader.fieldnames):
            raise ValueError(f"Dynamic-event CSV is missing action fields: {path}")
        for row in reader:
            if row["event_type"] != "player_possession":
                continue
            event_id = row["event_id"].strip()
            if not event_id or event_id in event_ids:
                raise ValueError(f"Invalid or duplicate player-possession event: {event_id!r}")
            event_ids.add(event_id)
            try:
                row_match_id = int(row["match_id"])
                start = int(row["frame_start"])
                end = int(row["frame_end"])
                period = int(row["period"])
                player_id = int(row["player_id"])
            except ValueError as error:
                raise ValueError(f"Malformed player-possession identity: {event_id}") from error
            if (
                row_match_id != match_id
                or start < 0
                or end < start
                or period not in (1, 2)
                or player_id <= 0
                or not row["player_name"].strip()
            ):
                raise ValueError(f"Invalid player-possession boundary: {event_id}")
            values.append({
                "eventId": event_id,
                "period": period,
                "playerId": player_id,
                "sourcePlayerName": row["player_name"].strip(),
                "sourceStartFrame": start,
                "sourceEndFrame": end,
                "startType": row["start_type"].strip(),
                "endType": row["end_type"].strip(),
                "flags": {
                    "oneTouch": _source_bool(row["one_touch"], f"{event_id}.one_touch"),
                    "carry": _source_bool(row["carry"], f"{event_id}.carry"),
                    "isHeader": _source_bool(row["is_header"], f"{event_id}.is_header"),
                    "handPass": _source_bool(row["hand_pass"], f"{event_id}.hand_pass"),
                },
                "matched": {
                    "possessionStart": _source_bool(
                        row["is_player_possession_start_matched"],
                        f"{event_id}.is_player_possession_start_matched",
                    ),
                    "possessionEnd": _source_bool(
                        row["is_player_possession_end_matched"],
                        f"{event_id}.is_player_possession_end_matched",
                    ),
                    "previousPass": _source_bool(
                        row["is_previous_pass_matched"],
                        f"{event_id}.is_previous_pass_matched",
                    ),
                    "passReception": _source_bool(
                        row["is_pass_reception_matched"],
                        f"{event_id}.is_pass_reception_matched",
                    ),
                },
                "fullyExtrapolated": _source_bool(
                    row["fully_extrapolated"],
                    f"{event_id}.fully_extrapolated",
                ),
            })
    return values


def _turn_degrees(
    first: tuple[float, float],
    pivot: tuple[float, float],
    last: tuple[float, float],
) -> float:
    incoming = pivot[0] - first[0], pivot[1] - first[1]
    outgoing = last[0] - pivot[0], last[1] - pivot[1]
    denominator = math.hypot(*incoming) * math.hypot(*outgoing)
    if denominator <= 1e-9:
        return 0.0
    cosine = max(-1.0, min(1.0, (
        incoming[0] * outgoing[0] + incoming[1] * outgoing[1]
    ) / denominator))
    return math.degrees(math.acos(cosine))


def source_action_geometry(
    data: dict,
    scene_start: int,
    event: dict,
) -> dict:
    empty = {
        "carryOnsetFrame": None,
        "carryOnsetDistanceMeters": None,
        "directionChangeOnsetFrame": None,
        "directionChangePivotFrame": None,
        "directionChangeDegrees": None,
    }
    if (
        event["flags"]["carry"] is not True
        or event["matched"]["possessionStart"] is not True
        or event["matched"]["possessionEnd"] is not True
        or event["fullyExtrapolated"] is True
    ):
        return empty
    first = event["sourceStartFrame"] - scene_start
    last = event["sourceEndFrame"] - scene_start
    player_id = event["playerId"]
    if first < 0 or last >= len(data["frames"]):
        return empty
    for frame in range(first, last + 1):
        player_point = point(data, player_id, frame)
        ball_point = ball(data, frame)
        if (
            player_point is None
            or ball_point is None
            or owner_at(data, frame) != player_id
            or distance(player_point, ball_point) > ACTION_CONTROL_MAXIMUM_METERS
        ):
            return empty
    start_point = point(data, player_id, first)
    carry_onset = next((
        frame for frame in range(first, last + 1)
        if distance(start_point, point(data, player_id, frame))
        >= ACTION_CARRY_MINIMUM_METERS
    ), None)
    if carry_onset is None:
        return empty
    carry_distance = distance(start_point, point(data, player_id, carry_onset))
    direction_onset = None
    direction_pivot = None
    direction_degrees = None
    # Three source samples on both legs, 1.5 m per leg, and a 55 degree bend
    # keep stationary jitter and tiny touches from becoming a direction label.
    for current in range(first + 6, last + 1):
        current_point = point(data, player_id, current)
        if distance(start_point, current_point) < ACTION_CARRY_MINIMUM_METERS:
            continue
        best: tuple[float, int] | None = None
        for pivot in range(first + 3, current - 2):
            pivot_point = point(data, player_id, pivot)
            if (
                distance(start_point, pivot_point)
                < ACTION_DIRECTION_LEG_MINIMUM_METERS
                or distance(pivot_point, current_point)
                < ACTION_DIRECTION_LEG_MINIMUM_METERS
            ):
                continue
            degrees = _turn_degrees(start_point, pivot_point, current_point)
            if degrees >= ACTION_DIRECTION_MINIMUM_DEGREES and (
                best is None or degrees > best[0]
            ):
                best = degrees, pivot
        if best is not None:
            direction_degrees, direction_pivot = best
            direction_onset = current
            break
    return {
        "carryOnsetFrame": scene_start + carry_onset,
        "carryOnsetDistanceMeters": round(carry_distance, 3),
        "directionChangeOnsetFrame": (
            scene_start + direction_onset if direction_onset is not None else None
        ),
        "directionChangePivotFrame": (
            scene_start + direction_pivot if direction_pivot is not None else None
        ),
        "directionChangeDegrees": (
            round(direction_degrees, 3) if direction_degrees is not None else None
        ),
    }


def build_scene_source_actions(
    data: dict,
    scene: dict,
    source_events: list[dict],
) -> list[dict]:
    players = {item["id"]: item for item in data["players"]}
    values = []
    for event in source_events:
        flags = event["flags"]
        relevant = (
            flags["carry"] is True
            or flags["isHeader"] is True
            or (flags["oneTouch"] is True and event["endType"] == "pass")
            or event["startType"] == "pass_reception"
        )
        if (
            not relevant
            or event["period"] != scene["period"]
            or event["sourceStartFrame"] < scene["startFrame"]
            or event["sourceEndFrame"] > scene["endFrame"]
            or event["playerId"] not in players
        ):
            continue
        value = {
            "proofVersion": ACTION_PROOF_VERSION,
            "eventId": event["eventId"],
            "actor": {
                "playerId": event["playerId"],
                "playerName": players[event["playerId"]]["name"],
                "sourcePlayerName": event["sourcePlayerName"],
            },
            "period": event["period"],
            "sourceStartFrame": event["sourceStartFrame"],
            "sourceEndFrame": event["sourceEndFrame"],
            "startType": event["startType"],
            "endType": event["endType"],
            "flags": event["flags"],
            "matched": event["matched"],
            "fullyExtrapolated": event["fullyExtrapolated"],
            "observedGeometry": source_action_geometry(
                data,
                scene["startFrame"],
                event,
            ),
            "provenance": {
                "provider": "SkillCorner Open Data",
                "commit": RECENT_COMMIT,
                "sourcePath": (
                    f"data/matches/{scene['matchId']}/"
                    f"{scene['matchId']}_dynamic_events.csv"
                ),
            },
        }
        values.append(value)
    return sorted(
        values,
        key=lambda item: (
            item["sourceStartFrame"], item["sourceEndFrame"], item["eventId"]
        ),
    )


def supports_source_action(action: dict, kind: str) -> bool:
    flags = action["flags"]
    matched = action["matched"]
    if action["fullyExtrapolated"] is True:
        return False
    if kind == "header":
        return (
            flags["isHeader"] is True
            and flags["handPass"] is not True
            and matched["possessionStart"] is True
            and matched["possessionEnd"] is True
        )
    if kind == "oneTouchPass":
        return (
            flags["oneTouch"] is True
            and flags["isHeader"] is not True
            and flags["handPass"] is not True
            and action["endType"] == "pass"
            and matched["possessionEnd"] is True
        )
    if kind == "receive":
        return (
            action["startType"] == "pass_reception"
            and flags["oneTouch"] is not True
            and flags["isHeader"] is not True
            and flags["handPass"] is not True
            and matched["possessionStart"] is True
            and matched["previousPass"] is True
        )
    if kind == "carry":
        return action["observedGeometry"]["carryOnsetFrame"] is not None
    if kind == "directionChange":
        return action["observedGeometry"]["directionChangeOnsetFrame"] is not None
    raise ValueError(f"Unsupported source action kind: {kind}")


def source_action_contact_observed(
    data: dict,
    scene: dict,
    action: dict,
    kind: str,
) -> bool:
    source_frame = (
        action["sourceEndFrame"] if kind == "oneTouchPass"
        else action["sourceStartFrame"]
    )
    local = source_frame - scene["startFrame"]
    if local < 0 or local >= len(data["frames"]):
        return False
    player_point = point(data, action["actor"]["playerId"], local)
    ball_point = ball(data, local)
    return (
        player_point is not None
        and ball_point is not None
        and distance(player_point, ball_point) <= ACTION_CONTROL_MAXIMUM_METERS
    )


def source_action_proof_counts(scenes: list[dict]) -> tuple[dict, dict]:
    kinds = ("carry", "directionChange", "header", "receive", "oneTouchPass")
    source_counts = {
        kind: sum(
            supports_source_action(action, kind)
            for scene in scenes
            for action in scene.get("sourceActions", [])
        )
        for kind in kinds
    }
    display_counts = {
        kind: source_counts[kind] for kind in ("carry", "directionChange")
    }
    display_counts.update({kind: 0 for kind in ("header", "receive", "oneTouchPass")})
    for scene in scenes:
        data = read_json(REPO / scene["asset"])
        for action in scene.get("sourceActions", []):
            for kind in ("header", "receive", "oneTouchPass"):
                if (
                    supports_source_action(action, kind)
                    and source_action_contact_observed(data, scene, action, kind)
                ):
                    display_counts[kind] += 1
    return source_counts, display_counts


def recent_touches(match: dict, frames: list[dict]) -> list[dict]:
    metadata = {player["id"]: player for player in match["players"]}
    touches: list[dict] = []
    current = None
    for frame in frames:
        owner = frame["owner"]
        if owner not in metadata or frame["period"] not in (1, 2):
            current = None
            continue
        team = "home" if metadata[owner]["team_id"] == match["home_team"]["id"] else "away"
        if current is not None and current["owner"] == owner:
            current["end"] = frame["frame"]
            continue
        value = {"owner": owner, "team": team, "period": frame["period"], "start": frame["frame"], "end": frame["frame"]}
        if touches and touches[-1]["owner"] == owner and touches[-1]["period"] == value["period"] and value["start"] - touches[-1]["end"] <= 5:
            touches[-1]["end"] = value["end"]
            current = touches[-1]
        else:
            touches.append(value)
            current = value
    return touches


def normalized_recent_data(match: dict, frames: list[dict]) -> dict:
    players = [
        {
            "id": item["id"],
            "number": item.get("number"),
            "name": full_name(item),
            "home": item["team_id"] == match["home_team"]["id"],
            "keeper": item.get("player_role", {}).get("name") == "Goalkeeper",
        }
        for item in match["players"]
    ]
    indices = {player["id"]: index for index, player in enumerate(players)}
    rows, visibility, ball_visibility, owners = [], [], [], []
    for frame in frames:
        row = [MISSING] * (len(players) * 2)
        flags = [0] * len(players)
        for player_id, value in frame["players"].items():
            index = indices[player_id]
            row[index * 2:index * 2 + 2] = [round(value[0] * 100), round(value[1] * 100)]
            flags[index] = 1
        ball_point = frame["ball"]
        row.extend((
            round(ball_point[0] * 100) if ball_point else 0,
            round(ball_point[1] * 100) if ball_point else 0,
            0,
        ))
        rows.append(row)
        visibility.append(flags)
        ball_visibility.append(1 if ball_point else 0)
        owners.append(frame["owner"] if frame["owner"] in indices else None)
    return {
        "fps": FPS,
        "players": players,
        "frames": rows,
        "visibility": visibility,
        "ballVisibility": ball_visibility,
        "sourcePossessionOwners": owners,
    }


def recent_clip_bounds(frames: list[dict], first: int, last: int, period: int) -> tuple[int, int] | None:
    segment_start = first
    while segment_start > 0 and first - segment_start < 400:
        previous = frames[segment_start - 1]
        if previous["period"] != period or previous["ball"] is None or previous["timestamp"] is None:
            break
        segment_start -= 1
    segment_end = last
    while segment_end + 1 < len(frames) and segment_end - last < 400:
        following = frames[segment_end + 1]
        if following["period"] != period or following["ball"] is None or following["timestamp"] is None:
            break
        segment_end += 1
    anchor_span = last - first
    minimum = max(200, anchor_span + 80)
    available = segment_end - segment_start
    if minimum > 400 or available < minimum:
        return None
    length = min(400, max(minimum, min(300, available)))
    earliest = max(segment_start, last + 40 - length)
    latest = min(first - 40, segment_end - length)
    if earliest > latest:
        return None
    balanced = first - (length - anchor_span) // 2
    start = min(max(balanced, earliest), latest)
    return start, start + length


def ownership_visible(frames: list[dict], start: int, end: int) -> bool:
    cursor = start
    observed_run = False
    while cursor <= end:
        owner = frames[cursor]["owner"]
        run_end = cursor
        while run_end + 1 <= end and frames[run_end + 1]["owner"] == owner:
            run_end += 1
        if owner is not None and run_end - cursor + 1 >= 3:
            observed_run = True
            if any(owner not in frames[frame]["players"] for frame in range(cursor, run_end + 1)):
                return False
        cursor = run_end + 1
    return observed_run


def goalkeeper_home_direction(match: dict, frames: list[dict], period: int) -> int:
    keepers = [
        item for item in match["players"]
        if item.get("player_role", {}).get("name") == "Goalkeeper"
    ]
    values = {}
    for team_id in (match["home_team"]["id"], match["away_team"]["id"]):
        team_values = []
        for keeper in keepers:
            if keeper["team_id"] != team_id:
                continue
            team_values.extend(
                frame["players"][keeper["id"]][0]
                for frame in frames
                if frame["period"] == period and keeper["id"] in frame["players"]
            )
        if team_values:
            values[team_id] = sorted(team_values)[len(team_values) // 2]
    if len(values) != 2 or abs(values[match["home_team"]["id"]] - values[match["away_team"]["id"]]) < 50:
        raise ValueError("Cannot establish attacking direction from observed goalkeepers")
    return 1 if values[match["home_team"]["id"]] < values[match["away_team"]["id"]] else -1


def lesson_margin(lesson: dict) -> float:
    metrics = lesson["measurements"]
    objective = lesson["objective"]
    if objective == "receivingLane":
        return min(
            metrics["movementMeters"] / .75,
            metrics["improvement"] / 3,
            metrics["receiverContributionDegrees"],
            (metrics["afterPassLineGapMeters"] - metrics["baselinePassLineGapMeters"]) / .5,
            metrics["receiverLineGapContributionMeters"] / .25,
        )
    if objective == "switchingSpace":
        return min(metrics["lateralMeters"] / 22, metrics["improvement"])
    if objective == "pressureOutlet":
        return min((5 - metrics["pressureMeters"]), metrics["improvement"])
    threshold = 1.5 if metrics["kind"] == "forwardAdvanceMeters" else 1
    return min(metrics["movementMeters"] / .6, metrics["improvement"] / threshold)


def find_recent_candidates(match: dict, frames: list[dict]) -> tuple[list[dict], list[dict]]:
    normalized = normalized_recent_data(match, frames)
    touches = recent_touches(match, frames)
    directions = {period: goalkeeper_home_direction(match, frames, period) for period in (1, 2)}
    candidates, rejected = [], []
    for index, first in enumerate(touches[:-1]):
        second_index = next((cursor for cursor in range(index + 1, len(touches)) if touches[cursor]["period"] == first["period"] and touches[cursor]["owner"] != first["owner"]), None)
        if second_index is None:
            continue
        second = touches[second_index]
        if second["start"] - first["end"] > 8 * FPS or first["team"] != second["team"]:
            continue
        third = next_controlled_owner(
            normalized,
            second["owner"],
            second["start"],
            second["start"] + 8 * FPS,
        )
        home_attack = first["team"] == "home"
        direction = directions[first["period"]] * (1 if home_attack else -1)
        accepted, reasons = evaluate_objectives(
            normalized, 0, first["end"], second["start"], first["owner"], second["owner"], direction, third,
        )
        objective = next((value for value in ("thirdPlayer", "pressureOutlet", "switchingSpace", "receivingLane") if value in accepted), None)
        if objective is None:
            rejected.append({"matchId": match["id"], "sourceFrame": first["end"], "reason": "no-education-rule-passed", "rules": reasons})
            continue
        lesson = accepted[objective]
        last_anchor = lesson["sourceFrames"]["nextConnection"] or lesson["sourceFrames"]["outcome"]
        bounds = recent_clip_bounds(frames, lesson["sourceFrames"]["movementStart"], last_anchor, first["period"])
        if bounds is None:
            rejected.append({"matchId": match["id"], "sourceFrame": first["end"], "reason": "no-20-to-40-second-observed-ball-clip"})
            continue
        start, end = bounds
        core_start = lesson["sourceFrames"]["movementStart"]
        core_end = lesson["sourceFrames"]["nextConnection"] or lesson["sourceFrames"]["outcome"]
        required = lesson_actor_ids(lesson)
        if any(not all(player_id in frames[frame]["players"] for frame in range(core_start, core_end + 1)) for player_id in required):
            rejected.append({"matchId": match["id"], "sourceFrame": first["end"], "reason": "learning-actor-has-detection-gap"})
            continue
        if not ownership_visible(frames, start, end):
            rejected.append({"matchId": match["id"], "sourceFrame": first["end"], "reason": "source-owner-has-detection-gap"})
            continue
        active = recent_active_players(match, start, end)
        active_ids = {item["id"] for item in active}
        if not required.issubset(active_ids):
            continue
        support = [
            item["id"] for item in active
            if (item["team_id"] == match["home_team"]["id"]) == home_attack
            and item["id"] not in {first["owner"], second["owner"], third[1] if third else -1}
            and all(item["id"] in frames[frame]["players"] for frame in range(core_start, core_end + 1))
        ]
        context_opponents = [
            item["id"] for item in active
            if (item["team_id"] == match["home_team"]["id"]) != home_attack
            and all(item["id"] in frames[frame]["players"] for frame in range(core_start, core_end + 1))
        ]
        if not support or len(context_opponents) < 2:
            rejected.append({"matchId": match["id"], "sourceFrame": first["end"], "reason": "missing-continuously-observed-support-or-opponents"})
            continue
        candidates.append({
            "matchId": match["id"], "period": first["period"], "start": start, "end": end,
            "departure": first["end"], "reception": second["start"], "third": third,
            "firstId": first["owner"], "secondId": second["owner"], "attackingHome": home_attack,
            "attackDirection": direction, "objective": objective, "lesson": lesson,
            "supportContext": support[0], "opponentContext": context_opponents[:2],
            "margin": round(lesson_margin(lesson), 4), "active": active,
        })
    return candidates, rejected


def select_non_overlapping(candidates: list[dict]) -> tuple[list[dict], list[dict]]:
    selected, rejected = [], []
    for candidate in sorted(candidates, key=lambda item: (-item["margin"], item["start"], item["departure"], item["objective"])):
        conflict = next((item for item in selected if not (candidate["end"] < item["start"] or candidate["start"] > item["end"])), None)
        if conflict is not None:
            rejected.append({
                "matchId": candidate["matchId"], "sourceFrame": candidate["departure"],
                "reason": "overlaps-stronger-observed-lesson", "selectedSourceFrame": conflict["departure"],
            })
            continue
        selected.append(candidate)
    return sorted(selected, key=lambda item: (item["matchId"], item["start"])), rejected


def clock_seconds(value: str) -> float:
    parts = value.split(":")
    if len(parts) != 3:
        raise ValueError(f"Invalid timestamp: {value}")
    return int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])


def build_recent_scene(
    match: dict,
    frames: list[dict],
    candidate: dict,
    source_events: list[dict],
) -> tuple[dict, dict, dict]:
    start, end = candidate["start"], candidate["end"]
    active = candidate["active"]
    active_ids = {item["id"] for item in active}
    players = [
        {
            "id": item["id"], "number": item.get("number"), "name": full_name(item),
            "home": item["team_id"] == match["home_team"]["id"],
            "keeper": item.get("player_role", {}).get("name") == "Goalkeeper",
        }
        for item in active
    ]
    indices = {player["id"]: index for index, player in enumerate(players)}
    raw_frames, visibility, owners, ball_visibility = [], [], [], []
    quantization_error = 0.0
    for source in frames[start:end + 1]:
        if source["ball"] is None:
            raise ValueError("Recent selected clip contains an unavailable ball")
        row, flags = [], []
        for player in players:
            value = source["players"].get(player["id"])
            flags.append(1 if value is not None else 0)
            for coordinate in value or (None, None):
                if coordinate is None:
                    row.append(MISSING)
                else:
                    quantized = round(coordinate * 100)
                    quantization_error = max(quantization_error, abs(quantized / 100 - coordinate))
                    row.append(quantized)
        row.extend((round(source["ball"][0] * 100), round(source["ball"][1] * 100), 0))
        if not any(flags):
            raise ValueError("Recent selected frame has no directly detected player")
        raw_frames.append(row)
        visibility.append(flags)
        ball_visibility.append(1)
        owners.append(source["owner"] if source["owner"] in active_ids else None)

    player_speed = 0.0
    for index in range(len(players)):
        for frame in range(1, len(raw_frames)):
            if not visibility[frame - 1][index] or not visibility[frame][index]:
                continue
            player_speed = max(player_speed, distance(
                (raw_frames[frame - 1][index * 2] / 100, raw_frames[frame - 1][index * 2 + 1] / 100),
                (raw_frames[frame][index * 2] / 100, raw_frames[frame][index * 2 + 1] / 100),
            ) * FPS)
    ball_speed = max(
        distance((raw_frames[index - 1][-3] / 100, raw_frames[index - 1][-2] / 100), (raw_frames[index][-3] / 100, raw_frames[index][-2] / 100)) * FPS
        for index in range(1, len(raw_frames))
    )
    if player_speed > 15.01 or ball_speed > 50:
        raise ValueError("Recent selected clip fails motion continuity")

    local_departure = candidate["departure"] - start
    local_reception = candidate["reception"] - start
    local_third = (candidate["third"][0] - start, candidate["third"][1]) if candidate["third"] else None
    anchors = [(local_departure, candidate["firstId"], "departure"), (local_reception, candidate["secondId"], "arrival")]
    if candidate["objective"] == "thirdPlayer" and local_third:
        anchors.append((local_third[0], local_third[1], "arrival"))
    for local, player_id, _ in anchors:
        index = indices[player_id]
        if local - 5 < 0 or local + 5 >= len(raw_frames) or not all(visibility[frame][index] for frame in range(local - 5, local + 6)):
            raise ValueError("Recent evidence anchor lacks a 0.5 second detection guard")
    core_start, core_end = anchors[0][0] - 5, anchors[-1][0] + 5
    context_ids = {candidate["supportContext"], *candidate["opponentContext"]}
    guarded_core_ids = context_ids | {item[1] for item in anchors}
    if any(not all(visibility[frame][indices[player_id]] for frame in range(core_start, core_end + 1)) for player_id in guarded_core_ids):
        raise ValueError("Recent core/support/opponent context has a central gap")
    cursor = 0
    meaningful = 0
    while cursor < len(owners):
        owner = owners[cursor]
        run_end = cursor
        while run_end + 1 < len(owners) and owners[run_end + 1] == owner:
            run_end += 1
        if owner is not None and run_end - cursor + 1 >= 3:
            meaningful += run_end - cursor + 1
            owner_index = indices[owner]
            if not all(visibility[frame][owner_index] for frame in range(cursor, run_end + 1)):
                raise ValueError("Recent source owner is not directly detected")
        cursor = run_end + 1
    if not meaningful:
        raise ValueError("Recent selected clip has no meaningful ownership run")

    home = match["home_team"]["name"]
    away = match["away_team"]["name"]
    date = match["date_time"][:10]
    source_url = f"https://github.com/SkillCorner/opendata/tree/{RECENT_COMMIT}/data/matches/{match['id']}"
    objective = candidate["objective"]
    slug = OBJECTIVE_SUFFIX[objective]
    focus_id = candidate["lesson"]["focusActor"]["playerId"]
    scene_id = f"{match['id']}-{candidate['departure']}-{focus_id}-{objective}"
    duration = (end - start) / FPS
    home_color = match["home_team_kit"]["jersey_color"]
    away_color = match["away_team_kit"]["jersey_color"]
    initial_actor = players[
        next(index for index, flag in enumerate(visibility[0]) if flag)
    ]["id"]
    data = {
        "fps": FPS, "poseStep": 2, "duration": duration,
        "startClock": clock_seconds(frames[start]["timestamp"]),
        "pitch": [match["pitch_length"], match["pitch_width"]],
        "match": {"id": match["id"], "date": date, "home": home, "away": away},
        "players": players, "joints": [], "frames": raw_frames, "visibility": visibility,
        "ballVisibility": ball_visibility, "displayFrames": [], "displayProvenance": [],
        "missingPlayerCoordinate": MISSING, "sourcePossessionOwners": owners,
        "poses": [], "events": [], "sourceCommit": RECENT_COMMIT, "sourceUrl": source_url,
        "sourceFrameStart": start, "period": candidate["period"],
        "coverage": "broadcastVisible", "annotationSource": "derived", "ballHeightAvailable": False,
        "scene": {
            "id": scene_id,
            "category": {"receivingLane": "penetration", "pressureOutlet": "pressure", "thirdPlayer": "combination", "switchingSpace": "switchPlay"}[objective],
            "titleKey": f"spatialEducationObjective{slug}", "focusKey": f"spatialEducation{slug}Question",
            "homeColor": home_color, "awayColor": away_color,
            "homeNumberColor": match["home_team_kit"]["number_color"],
            "awayNumberColor": match["away_team_kit"]["number_color"],
            "attackDirection": candidate["attackDirection"], "focusPlayerId": focus_id,
            "camera": [-match["pitch_length"] / 2 - 1.4, match["pitch_length"] / 2 + 1.4, -match["pitch_width"] / 2 - 1.4, match["pitch_width"] / 2 + 1.4],
            "steps": [
                {"time": 0.0, "kind": "observe", "actorId": initial_actor},
                *[
                    {"time": round(local / FPS, 3), "kind": "receive", "actorId": player_id}
                    for local, player_id, _ in anchors
                    if local > 0
                ],
            ],
            "outcome": "end",
        },
    }
    # Recompute from the quantized exported payload; raw floating point values
    # are never trusted as catalogue measurements.
    quantized_accepted, quantized_rejected = evaluate_objectives(
        data, start, local_departure, local_reception, candidate["firstId"], candidate["secondId"],
        candidate["attackDirection"], local_third,
    )
    if objective not in quantized_accepted:
        raise ValueError(f"Quantized recent scene lost education proof: {quantized_rejected.get(objective)}")
    lesson = quantized_accepted[objective]
    actor_ids = lesson_actor_ids(lesson)
    highlight = sorted(actor_ids | context_ids | {item[1] for item in anchors})
    first_point = point(data, candidate["firstId"], local_departure)
    second_point = point(data, candidate["secondId"], local_reception)
    evidence_anchors = [
        {"time": round(local / FPS, 3), "role": role, "playerId": player_id, "playerName": actor(data, player_id)["playerName"]}
        for local, player_id, role in anchors
    ]
    entry = {
        "id": scene_id,
        "asset": f"assets/scan_pass_spatial/education_scenes/{scene_id}.json",
        "assetSha256": "pending",
        "theme": {"receivingLane": "forwardConnection", "pressureOutlet": "pressureSupport", "thirdPlayer": "combination", "switchingSpace": "lateralSwitch"}[objective],
        "matchId": match["id"], "date": date, "season": "2024/25", "home": home, "away": away,
        "period": candidate["period"], "startFrame": start, "endFrame": end,
        "startClock": data["startClock"], "duration": duration,
        "focusPlayerId": focus_id, "focusPlayerName": actor(data, focus_id)["playerName"],
        "evidenceAnchors": evidence_anchors, "highlightPlayerIds": highlight,
        "attackingTeam": "home" if candidate["attackingHome"] else "away",
        "attackDirection": candidate["attackDirection"],
        "evidenceStart": evidence_anchors[0]["time"], "evidenceEnd": evidence_anchors[-1]["time"],
        "coreStart": round(core_start / FPS, 3), "coreEnd": round(core_end / FPS, 3),
        "corePlayerIds": [item[1] for item in anchors], "supportPlayerIds": [candidate["supportContext"]],
        "opponentContextPlayerIds": candidate["opponentContext"],
        "metrics": {
            "forwardMeters": round((second_point[0] - first_point[0]) * candidate["attackDirection"], 3),
            "lateralMeters": round(abs(second_point[1] - first_point[1]), 3),
            "startWidthMeters": round(abs(first_point[1]), 3),
            "insideGainMeters": round(abs(first_point[1]) - abs(second_point[1]), 3),
            "pressureMeters": lesson["measurements"]["pressureMeters"], "carryMeters": 0.0,
            "sequenceSeconds": round(evidence_anchors[-1]["time"] - evidence_anchors[0]["time"], 3),
        },
        "sourceCommit": RECENT_COMMIT, "sourceUrl": source_url, "learning": lesson,
    }
    entry["sourceActions"] = build_scene_source_actions(data, entry, source_events)
    proof = {
        "id": scene_id, "matchId": match["id"], "objective": objective,
        "sourceStartFrame": start, "sourceEndFrame": end, "period": candidate["period"],
        "durationSeconds": duration, "directDetectionOnly": True, "ballDetectedFrames": len(raw_frames),
        "minimumDetectedPlayers": min(sum(row) for row in visibility),
        "maxPlayerSpeedMetersPerSecond": round(player_speed, 4),
        "maxBallSpeedMetersPerSecond": round(ball_speed, 4),
        "maxQuantizationErrorMeters": round(quantization_error, 8),
        "sourceActionEvents": len(entry["sourceActions"]),
        "learning": lesson,
    }
    return data, entry, proof


def expected_recent_source_urls() -> dict[str, str]:
    paths = ["LICENSE"]
    for match_id in (1925299, 1996435):
        paths.extend([
            f"data/matches/{match_id}/{match_id}_dynamic_events.csv",
            f"data/matches/{match_id}/{match_id}_match.json",
            f"data/matches/{match_id}/{match_id}_phases_of_play.csv",
            f"data/matches/{match_id}/{match_id}_tracking_extrapolated.jsonl",
        ])
    values = {}
    for path in paths:
        host = (
            "https://media.githubusercontent.com/media"
            if path.endswith("tracking_extrapolated.jsonl")
            else "https://raw.githubusercontent.com"
        )
        values[path] = f"{host}/SkillCorner/opendata/{RECENT_COMMIT}/{path}"
    return values


def verify_source_manifest(manifest: dict) -> None:
    expected_urls = expected_recent_source_urls()
    if (
        manifest.get("provider") != "SkillCorner Open Data"
        or manifest.get("license") != "MIT"
        or manifest.get("commit") != RECENT_COMMIT
        or manifest.get("sourceUrl")
        != f"https://github.com/SkillCorner/opendata/tree/{RECENT_COMMIT}"
        or manifest.get("matchIds") != [1925299, 1996435]
    ):
        raise ValueError("Unexpected recent source identity")
    files = manifest.get("files")
    if not isinstance(files, list) or {item.get("path") for item in files} != set(expected_urls):
        raise ValueError("Recent source manifest does not have the exact pinned file set")
    for item in files:
        path = item.get("path")
        if (
            item.get("url") != expected_urls[path]
            or not isinstance(item.get("bytes"), int)
            or item["bytes"] <= 0
            or not isinstance(item.get("sha256"), str)
            or len(item["sha256"]) != 64
        ):
            raise ValueError(f"Malformed pinned recent source entry: {path}")


def verify_ready(raw_dir: Path, source_manifest_path: Path) -> dict:
    ready = read_json(source_manifest_path)
    verify_source_manifest(ready)
    for item in ready["files"]:
        path = raw_dir / Path(item["path"]).name
        if not path.is_file() or path.stat().st_size != item["bytes"] or sha256(path) != item["sha256"]:
            raise ValueError(f"Recent source hash mismatch: {path}")
    return ready


IMMUTABLE_SPATIAL_METADATA_HASHES = {
    "assets/scan_pass_spatial/source-manifest.json": "146ac3a9d1b6ad521a869b12a2e692bfef6c5533a0e8ce6a102836331b96ba1b",
    "assets/scan_pass_spatial/legacy-asset-preservation.json": "4b36f839cd639572f34cf0cd762c9e81e6942dfa49f0639b1e56d14cefdea4b8",
    "assets/scan_pass_spatial/LICENSE": "3384cc66ffd008209759af5e6328677eabded72756fb1f56f4f82e68e9b3c6eb",
    "assets/scan_pass_spatial/quality-proof.json": "a0b6a92442f408f6a340d98b7631b2afb1b4b447c1444008f6f6fe7a5c13e879",
    "assets/scan_pass_spatial/catalog.json": "1535cfef76a5d28c51e6cd438ca484b90906acef92fc8ed3aba384bb7d1796f1",
}


def expected_archive_hashes() -> dict[str, str]:
    values = dict(IMMUTABLE_SPATIAL_METADATA_HASHES)
    for scene in read_json(ARCHIVE_CATALOG)["scenes"]:
        values[scene["asset"]] = scene["assetSha256"]
    for item in read_json(ASSETS / "legacy-asset-preservation.json")["files"]:
        values[item["path"]] = item["sha256"]
    if len(values) != 115:
        raise ValueError(f"Immutable archive guard expected 115 files, found {len(values)}")
    return values


def assert_archive_unchanged() -> None:
    for relative, expected in expected_archive_hashes().items():
        path = REPO / relative
        if not path.is_file() or sha256(path) != expected:
            raise ValueError(f"Immutable archive asset changed: {relative}")


def generate(raw_dir: Path, source_manifest_path: Path) -> None:
    assert_archive_unchanged()
    ready = verify_ready(raw_dir, source_manifest_path)
    archive_scenes, archive_audit = audit_archive()
    if EDUCATION_SCENES.exists():
        shutil.rmtree(EDUCATION_SCENES)
    EDUCATION_SCENES.mkdir(parents=True)

    recent_entries, recent_proof, recent_rejected = [], [], []
    attempted_matches = []
    for match_id in ready["matchIds"]:
        match = read_json(raw_dir / f"{match_id}_match.json")
        known_ids = {item["id"] for item in match["players"]}
        source_events = load_player_possession_actions(
            raw_dir / f"{match_id}_dynamic_events.csv",
            match_id,
        )
        frames, ignored = load_recent_frames(
            raw_dir / f"{match_id}_tracking_extrapolated.jsonl", known_ids,
        )
        candidates, rejected = find_recent_candidates(match, frames)
        selected, overlap_rejected = select_non_overlapping(candidates)
        attempted_matches.append({
            "matchId": match_id, "candidateCount": len(candidates),
            "selectedForBuild": len(selected), "ignoredExtrapolatedOrImpossibleObservations": ignored,
        })
        recent_rejected.extend(rejected)
        recent_rejected.extend(overlap_rejected)
        for candidate in selected:
            try:
                data, entry, proof = build_recent_scene(
                    match,
                    frames,
                    candidate,
                    source_events,
                )
            except ValueError as error:
                recent_rejected.append({
                    "matchId": match_id, "sourceFrame": candidate["departure"],
                    "reason": f"export-validation: {error}",
                })
                continue
            path = REPO / entry["asset"]
            save(path, data)
            entry["assetSha256"] = sha256(path)
            proof["asset"] = entry["asset"]
            proof["assetBytes"] = path.stat().st_size
            proof["assetSha256"] = entry["assetSha256"]
            recent_entries.append(entry)
            recent_proof.append(proof)

    if not recent_entries:
        raise ValueError("Neither requested recent match produced an education-approved scene")
    represented_recent = {item["matchId"] for item in recent_entries}
    for match_id in ready["matchIds"]:
        if match_id not in represented_recent:
            recent_rejected.append({
                "matchId": match_id, "reason": "match-produced-no-export-valid-education-scene",
            })

    scenes = archive_scenes + recent_entries
    scenes.sort(key=lambda item: (item["season"] != "2024/25", item["date"], item["matchId"], item["startFrame"], item["id"]))
    historical_matches = sorted({item["matchId"] for item in archive_scenes})
    recent_matches = sorted({item["matchId"] for item in recent_entries})
    all_matches = sorted(set(historical_matches) | set(recent_matches))
    catalogue = {
        "version": 2,
        "provider": "SkillCorner Open Data",
        "license": "MIT",
        "proofVersion": CATALOG_PROOF_VERSION,
        "actionProofVersion": ACTION_PROOF_VERSION,
        "sourceCommit": "mixed-pinned-sources-v1",
        "sourceUrl": "https://github.com/SkillCorner/opendata",
        "matchCount": len(all_matches),
        "sourcePins": [
            {
                "key": "historical-2019-20", "provider": "SkillCorner Open Data", "license": "MIT",
                "commit": HISTORICAL_COMMIT,
                "sourceUrl": f"https://github.com/SkillCorner/opendata/tree/{HISTORICAL_COMMIT}",
                "matchIds": historical_matches,
            },
            {
                "key": "recent-2024-25", "provider": "SkillCorner Open Data", "license": "MIT",
                "commit": RECENT_COMMIT,
                "sourceUrl": f"https://github.com/SkillCorner/opendata/tree/{RECENT_COMMIT}",
                "matchIds": recent_matches,
            },
        ],
        "scenes": scenes,
    }
    source_action_counts, display_action_counts = source_action_proof_counts(
        recent_entries,
    )
    proof = {
        "generator": "tool/scan_pass_replay/prepare_spatial_education.py",
        "proofVersion": CATALOG_PROOF_VERSION,
        "rules": {
            "quantizationMeters": QUANTIZATION_METERS,
            "receivingLane": "receiver is continuously detected and moves at least 0.75 m in the second before release; the same defender projects onto the finite passer-to-receiver segment before and after, starts within 3 m and 25 degrees of that pass line, gains at least 0.5 m line clearance; receiver motion contributes at least 1 degree and 0.25 m with the final passer/defender fixed, while total angle grows at least 3 degrees",
            "pressureOutlet": "passer has a continuously observed opponent within 4 m; receiver clearance from the same observed defender increases by at least 1 m; the next directly observed same-team connection occurs without intervening or reversed source ownership",
            "thirdPlayer": "A, B and C are distinct same-team actors in uninterrupted source ownership order; C moves at least 0.6 m before B receives, at least 1 m overall, continues in the outcome direction, and gains either 1.5 m forward or 1 m clearance",
            "switchingSpace": "source-labelled lateral connection spans at least 22 m and receiver clearance from the same continuously observed defender increases by at least 1 m",
            "tolerance": "catalogue metrics are recomputed from centimetre-quantized exported frames; runtime comparison tolerance is 0.0011 in stored units and threshold allowance never exceeds the 0.01 m two-point quantization bound",
            "sourceActions": "player_possession rows only; nullable provider flags remain nullable; receive requires is_previous_pass_matched for its incoming pass and excludes known one-touch/header/hand actions, while is_pass_reception_matched remains distinct outgoing-pass metadata; header requires is_header; one-touch pass requires one_touch plus end_type=pass with header priority; instant labels additionally require actor and ball within 3.5 m at the original contact frame",
            "carryAction": "provider carry=true plus matched boundaries, uninterrupted directly observed player and ball, matching source owner, player-ball distance at most 3.5 m, and at least 2.0 m observed displacement before onset",
            "directionChangeAction": "a carry-qualified observed XY trajectory only; both reached legs are at least 1.5 m and bend at least 55 degrees, without claiming body rotation",
        },
        "references": REFERENCES,
        "counts": {
            "archiveAudited": len(archive_audit),
            "archiveAccepted": len(archive_scenes),
            "archiveRejected": len(archive_audit) - len(archive_scenes),
            "recentAccepted": len(recent_entries),
            "educationScenes": len(scenes),
            "matches": len(all_matches),
            "objectives": dict(collections.Counter(item["learning"]["objective"] for item in scenes)),
            "seasons": dict(collections.Counter(item["season"] for item in scenes)),
            "sourceActionEvents": sum(len(item.get("sourceActions", [])) for item in scenes),
            "sourceActionGeometry": source_action_counts,
            "sourceActionDisplayAnchors": display_action_counts,
        },
        "attemptedRecentMatches": attempted_matches,
        "archiveAudit": archive_audit,
        "recentScenes": recent_proof,
        "recentRejections": sorted(recent_rejected, key=lambda item: (item.get("matchId", 0), item.get("sourceFrame", -1), item["reason"])),
    }
    manifest = {
        "provider": ready["provider"], "license": ready["license"], "commit": ready["commit"],
        "sourceUrl": ready["sourceUrl"], "matchIds": ready["matchIds"],
        "sourceSemantics": ready["sourceSemantics"],
        "files": [
            {key: item[key] for key in ("path", "bytes", "sha256", "url")}
            for item in ready["files"]
        ],
        "archivePreservation": {
            "fileCount": len(expected_archive_hashes()),
            "derivedFrom": [
                "assets/scan_pass_spatial/catalog.json#scenes[].assetSha256",
                "assets/scan_pass_spatial/legacy-asset-preservation.json#files[].sha256",
            ],
            "metadataSha256": IMMUTABLE_SPATIAL_METADATA_HASHES,
        },
    }
    save(EDUCATION_CATALOG, catalogue)
    save(EDUCATION_PROOF, proof)
    save(EDUCATION_MANIFEST, manifest)
    verify_assets()
    print(
        f"Generated {len(scenes)} education scenes: {len(archive_scenes)} reviewed archive + "
        f"{len(recent_entries)} recent across {len(all_matches)} matches"
    )


def recompute_catalog_lesson(scene: dict, data: dict) -> dict:
    lesson = scene["learning"]
    departure = round(scene["evidenceAnchors"][0]["time"] * data["fps"])
    reception = round(scene["evidenceAnchors"][1]["time"] * data["fps"])
    third = None
    if lesson["objective"] == "thirdPlayer":
        third = (
            round(scene["evidenceAnchors"][-1]["time"] * data["fps"]),
            lesson["focusActor"]["playerId"],
        )
    accepted, rejected = evaluate_objectives(
        data, scene["startFrame"], departure, reception,
        scene["evidenceAnchors"][0]["playerId"], scene["evidenceAnchors"][1]["playerId"],
        scene["attackDirection"], third,
    )
    objective = lesson["objective"]
    if objective not in accepted:
        raise ValueError(f"Lesson no longer passes {objective}: {rejected.get(objective)}")
    return accepted[objective]


def verify_scene_source_actions(scene: dict, data: dict) -> None:
    actions = scene.get("sourceActions", [])
    if scene["sourceCommit"] != RECENT_COMMIT:
        if actions:
            raise ValueError(f"Historical scene fabricates source actions: {scene['id']}")
        return
    if not isinstance(actions, list):
        raise ValueError(f"Malformed source action list: {scene['id']}")
    event_ids: set[str] = set()
    players = {item["id"]: item for item in data["players"]}
    for action in actions:
        if not isinstance(action, dict):
            raise ValueError(f"Malformed source action: {scene['id']}")
        actor_value = action.get("actor")
        flags = action.get("flags")
        matched = action.get("matched")
        provenance = action.get("provenance")
        geometry = action.get("observedGeometry")
        event_id = action.get("eventId")
        if (
            action.get("proofVersion") != ACTION_PROOF_VERSION
            or not isinstance(event_id, str)
            or not event_id
            or event_id in event_ids
            or not isinstance(actor_value, dict)
            or not isinstance(flags, dict)
            or not isinstance(matched, dict)
            or not isinstance(provenance, dict)
            or not isinstance(geometry, dict)
        ):
            raise ValueError(f"Malformed source action identity: {scene['id']}")
        event_ids.add(event_id)
        player_id = actor_value.get("playerId")
        player = players.get(player_id)
        if (
            player is None
            or actor_value.get("playerName") != player["name"]
            or not isinstance(actor_value.get("sourcePlayerName"), str)
            or not actor_value["sourcePlayerName"]
            or action.get("period") != scene["period"]
            or not isinstance(action.get("sourceStartFrame"), int)
            or not isinstance(action.get("sourceEndFrame"), int)
            or action["sourceStartFrame"] < scene["startFrame"]
            or action["sourceEndFrame"] < action["sourceStartFrame"]
            or action["sourceEndFrame"] > scene["endFrame"]
            or not isinstance(action.get("startType"), str)
            or not isinstance(action.get("endType"), str)
        ):
            raise ValueError(f"Source action does not match scene: {scene['id']} {event_id}")
        nullable_booleans = [
            *(flags.get(key) for key in ("oneTouch", "carry", "isHeader", "handPass")),
            *(matched.get(key) for key in (
                "possessionStart", "possessionEnd", "previousPass", "passReception"
            )),
            action.get("fullyExtrapolated"),
        ]
        if any(type(value) not in (bool, type(None)) for value in nullable_booleans):
            raise ValueError(f"Source action flag is not nullable-boolean: {event_id}")
        if provenance != {
            "provider": "SkillCorner Open Data",
            "commit": RECENT_COMMIT,
            "sourcePath": (
                f"data/matches/{scene['matchId']}/"
                f"{scene['matchId']}_dynamic_events.csv"
            ),
        }:
            raise ValueError(f"Source action provenance mismatch: {event_id}")
        event = {
            "eventId": event_id,
            "period": action["period"],
            "playerId": player_id,
            "sourcePlayerName": actor_value["sourcePlayerName"],
            "sourceStartFrame": action["sourceStartFrame"],
            "sourceEndFrame": action["sourceEndFrame"],
            "startType": action["startType"],
            "endType": action["endType"],
            "flags": flags,
            "matched": matched,
            "fullyExtrapolated": action.get("fullyExtrapolated"),
        }
        expected_geometry = source_action_geometry(data, scene["startFrame"], event)
        if geometry != expected_geometry:
            raise ValueError(f"Stale source action geometry: {scene['id']} {event_id}")


def verify_assets(
    raw_dir: Path = REPO / ".tmp/spatial-education/recent-source",
) -> None:
    assert_archive_unchanged()
    catalogue = read_json(EDUCATION_CATALOG)
    proof = read_json(EDUCATION_PROOF)
    manifest = read_json(EDUCATION_MANIFEST)
    verify_source_manifest(manifest)
    preservation = manifest.get("archivePreservation")
    if (
        not isinstance(preservation, dict)
        or preservation.get("fileCount") != len(expected_archive_hashes())
        or preservation.get("metadataSha256") != IMMUTABLE_SPATIAL_METADATA_HASHES
    ):
        raise ValueError("Education manifest has stale archive preservation metadata")
    if (
        catalogue.get("version") != 2
        or catalogue.get("proofVersion") != CATALOG_PROOF_VERSION
        or catalogue.get("actionProofVersion") != ACTION_PROOF_VERSION
    ):
        raise ValueError("Invalid education catalogue version")
    if catalogue["matchCount"] != len({item["matchId"] for item in catalogue["scenes"]}):
        raise ValueError("Education matchCount is not derived from actual matches")
    if len({item["learning"]["objective"] for item in catalogue["scenes"]}) != 4:
        raise ValueError("Education catalogue does not cover all four objectives")
    archived = read_json(ARCHIVE_CATALOG)
    if len(proof["archiveAudit"]) != len(archived["scenes"]) or {item["id"] for item in proof["archiveAudit"]} != {item["id"] for item in archived["scenes"]}:
        raise ValueError("Education proof does not audit every archived scene")
    manifest_files = {item["path"]: item for item in manifest["files"]}
    source_actions_by_match: dict[int, list[dict]] = {}
    for match_id in (1925299, 1996435):
        expected = f"data/matches/{match_id}/{match_id}_tracking_extrapolated.jsonl"
        if expected not in manifest_files:
            raise ValueError(f"Missing pinned tracking source: {match_id}")
        csv_source = f"data/matches/{match_id}/{match_id}_dynamic_events.csv"
        csv_item = manifest_files.get(csv_source)
        if csv_item is None:
            raise ValueError(f"Missing pinned dynamic-event source: {match_id}")
        csv_path = raw_dir / f"{match_id}_dynamic_events.csv"
        if csv_path.is_file():
            if csv_path.stat().st_size != csv_item["bytes"] or sha256(csv_path) != csv_item["sha256"]:
                raise ValueError(f"Dynamic-event source hash mismatch: {match_id}")
            source_actions_by_match[match_id] = load_player_possession_actions(
                csv_path,
                match_id,
            )
    for scene in catalogue["scenes"]:
        path = REPO / scene["asset"]
        if not path.is_file() or sha256(path) != scene["assetSha256"]:
            raise ValueError(f"Education asset hash mismatch: {scene['id']}")
        data = read_json(path)
        if data.get("displayFrames") or data.get("displayProvenance"):
            raise ValueError(f"Education scene contains display reconstruction: {scene['id']}")
        if data.get("ballHeightAvailable") is not False or any(row[-1] for row in data["frames"]):
            raise ValueError(f"Education scene is not XY-only: {scene['id']}")
        if scene["sourceCommit"] == RECENT_COMMIT:
            if not data.get("ballVisibility") or not all(data["ballVisibility"]):
                raise ValueError(f"Recent ball availability is not faithfully exported: {scene['id']}")
            if not scene["asset"].startswith("assets/scan_pass_spatial/education_scenes/"):
                raise ValueError("Recent scene is outside the explicit education directory")
        else:
            if scene["asset"] not in {item["asset"] for item in archived["scenes"]}:
                raise ValueError("Education archive entry does not reuse an original scene")
        verify_scene_source_actions(scene, data)
        if scene["matchId"] in source_actions_by_match:
            expected_actions = build_scene_source_actions(
                data,
                scene,
                source_actions_by_match[scene["matchId"]],
            )
            if encoded(expected_actions) != encoded(scene.get("sourceActions", [])):
                raise ValueError(f"Source actions do not match pinned CSV: {scene['id']}")
        recomputed = recompute_catalog_lesson(scene, data)
        if encoded(recomputed) != encoded(scene["learning"]):
            raise ValueError(f"Tampered or stale lesson metrics: {scene['id']}")
    actual_counts = collections.Counter(item["learning"]["objective"] for item in catalogue["scenes"])
    if dict(actual_counts) != proof["counts"]["objectives"]:
        raise ValueError("Education proof counts are stale")
    recent_scenes = [
        scene for scene in catalogue["scenes"]
        if scene["sourceCommit"] == RECENT_COMMIT
    ]
    action_counts, display_action_counts = source_action_proof_counts(recent_scenes)
    if (
        proof["counts"].get("sourceActionEvents")
        != sum(len(scene.get("sourceActions", [])) for scene in catalogue["scenes"])
        or proof["counts"].get("sourceActionGeometry") != action_counts
        or proof["counts"].get("sourceActionDisplayAnchors")
        != display_action_counts
    ):
        raise ValueError("Education source-action proof counts are stale")
    print(
        f"Verified education catalogue: {len(catalogue['scenes'])} scenes, "
        f"{catalogue['matchCount']} matches, {len(actual_counts)} objectives"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--raw-dir", type=Path, default=REPO / ".tmp/spatial-education/recent-source")
    parser.add_argument(
        "--source-manifest",
        type=Path,
        default=EDUCATION_MANIFEST,
        help="Committed pinned source manifest used to verify files in --raw-dir",
    )
    parser.add_argument("--verify-assets", action="store_true")
    args = parser.parse_args()
    if args.verify_assets:
        verify_assets(args.raw_dir)
    else:
        generate(args.raw_dir, args.source_manifest)


if __name__ == "__main__":
    main()
