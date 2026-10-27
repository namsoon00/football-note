#!/usr/bin/env python3
"""Generate the famous-match spatial learning library from pinned SkillCorner data.

The historical feed is tracking-only.  A "connection" below therefore means a
change between two observed possession owners from the same source-labelled
team while the ball is continuously recorded.  It is deliberately not promoted
to an event-provider pass, completion, goal, or optimal-choice claim.

The importer scans each match once, builds possession/identity indices, then
selects non-overlapping clips.  Missing broadcast coordinates are retained as
missing evidence and get a separate provenance-marked display reconstruction.
"""

from __future__ import annotations

import argparse
import collections
import hashlib
import json
import math
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from prepare_historical import (  # noqa: E402
    HISTORICAL_COMMIT,
    HISTORICAL_SOURCE_ROOT,
    JOINTS,
    active_players,
    clock_seconds,
    digest,
    full_name,
    goalkeeper_direction,
    max_display_speed,
    max_speed,
    number,
    read_json,
    reconstruct_display,
    save,
)


REPO = Path(__file__).resolve().parents[2]
ASSETS = REPO / "assets/scan_pass_spatial"
SCENES = ASSETS / "scenes"
SCENES_PER_MATCH = 12
FPS = 10
CLIP_FRAMES = 200
MIN_CLIP_FRAMES = 100
LEAD_FRAMES = 50
MIN_LEAD_FRAMES = 20
MIN_FOLLOW_FRAMES = 30
MIN_ANCHOR_SEPARATION = 210
MAX_FOCAL_PER_MATCH = 3
MAX_THEME_PER_MATCH = 3

THEMES = (
    "lateralSwitch",
    "forwardConnection",
    "pressureSupport",
    "carryThenConnect",
    "wideToInside",
    "combination",
    "turnover",
    "recovery",
)

CATEGORY = {
    "lateralSwitch": "switchPlay",
    "forwardConnection": "penetration",
    "pressureSupport": "pressure",
    "carryThenConnect": "transition",
    "wideToInside": "wideAttack",
    "combination": "combination",
    "turnover": "turnover",
    "recovery": "turnover",
}

# Default focal actors are intentionally recognisable.  Other roster members
# remain visible as match context, but never become the library card's actor.
FAMOUS_LAST_NAMES = {
    "Aguero", "Alaba", "Alexander-Arnold", "Bale", "Barella", "Benzema",
    "Bonucci", "Brozovic", "Busquets", "Carvajal", "Casemiro", "Coman",
    "Courtois", "Cuadrado", "Davies", "de Bruyne", "de Jong", "de Ligt",
    "Di Maria", "Dybala", "Fabinho", "Fernandinho", "Firmino", "Foden",
    "Gnabry", "Goretzka", "Griezmann", "Gündogan", "Hakimi", "Haland",
    "Handanovic", "Henderson", "Hummels", "Icardi", "Isco", "Kimmich",
    "Kroos", "Laporte", "Lewandowski", "Lukaku", "Mane", "Marquinhos",
    "Martinez", "Mbappe", "Messi", "Modric", "Müller", "Neuer", "Navas",
    "Payet", "Pique", "Pjanic", "Rakitic", "Ramos", "Robertson", "Ronaldo",
    "Salah", "Sancho", "Silva", "Sterling", "Suarez", "ter Stegen",
    "Thiago Silva", "van Dijk", "Verratti", "Vinicius", "Walker", "Witsel",
}


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def team_label(match: dict, player: dict) -> str:
    return (
        "home team"
        if player["team_id"] == match["home_team"]["id"]
        else "away team"
    )


def is_famous(player: dict) -> bool:
    name = full_name(player)
    last = player["last_name"]
    return last in FAMOUS_LAST_NAMES or name in FAMOUS_LAST_NAMES


def item_at(frame: dict, trackable_object: int) -> dict | None:
    matches = [
        item
        for item in frame["data"]
        if item.get("trackable_object") == trackable_object
    ]
    return matches[0] if len(matches) == 1 else None


def point_at(frame: dict, trackable_object: int) -> tuple[float, float] | None:
    item = item_at(frame, trackable_object)
    if item is None:
        return None
    x, y = item.get("x"), item.get("y")
    if not isinstance(x, (int, float)) or not isinstance(y, (int, float)):
        return None
    if not math.isfinite(x) or not math.isfinite(y):
        return None
    return float(x), float(y)


def ball_at(frame: dict, ball_id: int) -> tuple[float, float] | None:
    return point_at(frame, ball_id)


def direct_observations_by_entity(
    frames: list[dict], entity_ids: set[int]
) -> dict[int, dict[int, tuple[int, int]]]:
    """Index only metadata-linked observations; anonymous tracks are not evidence."""
    observations = {entity: {} for entity in entity_ids}
    for frame in frames:
        if frame["period"] not in {1, 2}:
            continue
        for item in frame["data"]:
            entity = item.get("trackable_object")
            if entity not in observations:
                continue
            point = (
                round(number(item.get("x"), "player x") * 100),
                round(number(item.get("y"), "player y") * 100),
            )
            previous = observations[entity].get(frame["frame"])
            if previous is not None and previous != point:
                raise ValueError("Conflicting direct player observations")
            observations[entity][frame["frame"]] = point
    return observations


def possession_touches(match: dict, frames: list[dict]) -> list[dict]:
    metadata = {player["trackable_object"]: player for player in match["players"]}
    touches: list[dict] = []
    current: dict | None = None
    for frame in frames:
        owner = frame["possession"].get("trackable_object")
        if owner not in metadata or frame["period"] not in {1, 2}:
            current = None
            continue
        if current is not None and current["owner"] == owner:
            current["endFrame"] = frame["frame"]
            continue
        current = {
            "owner": owner,
            "team": team_label(match, metadata[owner]),
            "period": frame["period"],
            "startFrame": frame["frame"],
            "endFrame": frame["frame"],
            "clock": frame["time"],
        }
        # Repeated tags for one continuous touch are merged across a very
        # short unassigned gap.  A different owner always starts a new touch.
        if (
            touches
            and touches[-1]["owner"] == owner
            and touches[-1]["period"] == current["period"]
            and current["startFrame"] - touches[-1]["endFrame"] <= 5
        ):
            touches[-1]["endFrame"] = current["endFrame"]
            current = touches[-1]
        else:
            touches.append(current)
    return touches


def nearest_opponent_distance(
    match: dict,
    frame: dict,
    actor: dict,
    actor_point: tuple[float, float],
) -> tuple[float, int] | None:
    values = []
    for opponent in match["players"]:
        if opponent["team_id"] == actor["team_id"]:
            continue
        point = point_at(frame, opponent["trackable_object"])
        if point is not None:
            values.append(
                (math.dist(actor_point, point), opponent["trackable_object"])
            )
    return min(values) if values else None


def anchor_ball_distance(
    frames: list[dict], ball_id: int, anchor: dict
) -> float | None:
    player = point_at(frames[anchor["startFrame"]], anchor["owner"])
    ball = ball_at(frames[anchor["startFrame"]], ball_id)
    if player is None or ball is None:
        return None
    return math.dist(player, ball)


def final_clip_bounds(
    match: dict,
    frames: list[dict],
    ball_id: int,
    anchors: list[dict],
) -> tuple[int, int] | None:
    bounds = clip_bounds(
        frames,
        ball_id,
        anchors[0]["period"],
        anchors[0]["startFrame"],
        anchors[-1]["startFrame"],
    )
    if bounds is None:
        return None
    start, end = bounds
    interval = frames[start : end + 1]
    if any(
        frame["frame"] != start + offset
        or frame["period"] != anchors[0]["period"]
        or frame["time"] is None
        for offset, frame in enumerate(interval)
    ):
        return None
    try:
        active_players(match, interval)
    except ValueError:
        return None
    if not ball_continuous(frames, ball_id, start, end):
        return None
    return bounds


def ball_continuous(frames: list[dict], ball_id: int, start: int, end: int) -> bool:
    return all(ball_at(frames[index], ball_id) is not None for index in range(start, end + 1))


def validate_ball_speed(raw_frames: list[list[int]]) -> float:
    ball_speed = max(
        math.hypot(
            (raw_frames[index][-3] - raw_frames[index - 1][-3]) / 100,
            (raw_frames[index][-2] - raw_frames[index - 1][-2]) / 100,
        )
        * FPS
        for index in range(1, len(raw_frames))
    )
    if ball_speed > 50:
        raise ValueError(f"Implausible ball continuity ({ball_speed:.2f} m/s)")
    return ball_speed


def clip_bounds(
    frames: list[dict],
    ball_id: int,
    period: int,
    first_anchor: int,
    last_anchor: int,
) -> tuple[int, int] | None:
    """Return a 10-20 s continuous-ball clip with context around the anchors."""
    segment_start = first_anchor
    while (
        segment_start > 0
        and first_anchor - segment_start < CLIP_FRAMES
        and frames[segment_start - 1]["period"] == period
        and frames[segment_start - 1]["frame"] == segment_start - 1
        and frames[segment_start - 1]["time"] is not None
        and ball_at(frames[segment_start - 1], ball_id) is not None
    ):
        segment_start -= 1
    segment_end = last_anchor
    while (
        segment_end + 1 < len(frames)
        and segment_end - last_anchor < CLIP_FRAMES
        and frames[segment_end + 1]["period"] == period
        and frames[segment_end + 1]["frame"] == segment_end + 1
        and frames[segment_end + 1]["time"] is not None
        and ball_at(frames[segment_end + 1], ball_id) is not None
    ):
        segment_end += 1
    if segment_end - segment_start < MIN_CLIP_FRAMES:
        return None
    start = max(segment_start, first_anchor - LEAD_FRAMES)
    end = min(segment_end, start + CLIP_FRAMES)
    if end - start < MIN_CLIP_FRAMES:
        start = max(segment_start, end - MIN_CLIP_FRAMES)
    # Retain meaningful action after the last evidence anchor where source
    # continuity permits it; shift earlier context rather than truncating the
    # clip immediately after one connection.
    desired_after = min(50, max(25, MIN_CLIP_FRAMES - (last_anchor - start)))
    if end < last_anchor + desired_after:
        end = min(segment_end, last_anchor + desired_after)
        start = max(segment_start, end - CLIP_FRAMES)
    if (
        end - start < MIN_CLIP_FRAMES
        or first_anchor - start < MIN_LEAD_FRAMES
        or end - last_anchor < MIN_FOLLOW_FRAMES
        or not (start < first_anchor < last_anchor <= end)
    ):
        return None
    return start, end


def group_consistent(
    frames: list[dict], start: int, end: int, expected: str
) -> bool:
    labels = {
        frames[index]["possession"].get("group")
        for index in range(start, end + 1)
    }
    return not ({"home team", "away team"} - {expected}).intersection(labels)


def classify_connection(metrics: dict, has_third: bool) -> str | None:
    if metrics["carryMeters"] >= 3.5:
        return "carryThenConnect"
    if metrics["lateralMeters"] >= 22:
        return "lateralSwitch"
    if (
        metrics["startWidthMeters"] >= 20
        and metrics["insideGainMeters"] >= 6
    ):
        return "wideToInside"
    if (
        metrics["pressureMeters"] is not None
        and metrics["pressureMeters"] <= 6
        and metrics["forwardMeters"] < 10
    ):
        return "pressureSupport"
    if has_third:
        return "combination"
    if metrics["forwardMeters"] >= 9:
        return "forwardConnection"
    return None


def candidate_score(candidate: dict) -> float:
    metrics = candidate["metrics"]
    theme = candidate["theme"]
    score = {
        "lateralSwitch": metrics["lateralMeters"],
        "forwardConnection": metrics["forwardMeters"],
        "pressureSupport": 12 - (metrics["pressureMeters"] or 12),
        "carryThenConnect": metrics["carryMeters"],
        "wideToInside": metrics["insideGainMeters"],
        "combination": 12 - metrics["sequenceSeconds"],
        "turnover": 12 - metrics["sequenceSeconds"],
        "recovery": 14 - metrics["sequenceSeconds"],
    }[theme]
    # Prefer anchors with both players comfortably inside the broadcast view.
    return round(score + candidate["visibleParticipantCount"] * 0.1, 4)


def build_candidates(match: dict, frames: list[dict]) -> tuple[list[dict], list[dict]]:
    metadata = {player["trackable_object"]: player for player in match["players"]}
    ball_id = match["ball"]["trackable_object"]
    touches = possession_touches(match, frames)
    directions = {
        period: goalkeeper_direction(match, frames, period)[0]
        for period in (1, 2)
    }
    candidates: list[dict] = []
    rejected: list[dict] = []

    def reject(touch: dict, reason: str) -> None:
        rejected.append(
            {
                "matchId": match["id"],
                "sourceFrame": touch["startFrame"],
                "owner": touch["owner"],
                "reason": reason,
            }
        )

    for index, first in enumerate(touches[:-1]):
        actor = metadata[first["owner"]]
        if not is_famous(actor):
            reject(first, "focal-player-not-in-recognisable-default-set")
            continue
        second_index = next(
            (
                cursor
                for cursor in range(index + 1, len(touches))
                if touches[cursor]["period"] == first["period"]
                and touches[cursor]["owner"] != first["owner"]
            ),
            None,
        )
        if second_index is None:
            reject(first, "no-subsequent-distinct-owner")
            continue
        second = touches[second_index]
        gap = (second["startFrame"] - first["endFrame"]) / FPS
        if gap < 0 or gap > 8:
            reject(first, "subsequent-owner-outside-eight-seconds")
            continue
        bounds = final_clip_bounds(match, frames, ball_id, [first, second])
        if bounds is None:
            reject(first, "no-ten-second-continuous-ball-clip-around-anchors")
            continue
        start, end = bounds
        interval = frames[start : end + 1]
        if any(
            frame["frame"] != start + offset
            or frame["period"] != first["period"]
            or frame["time"] is None
            for offset, frame in enumerate(interval)
        ):
            reject(first, "clip-crosses-period-or-source-gap")
            continue
        try:
            active_players(match, interval)
        except ValueError:
            reject(first, "active-roster-changes-inside-clip")
            continue
        first_point = point_at(frames[first["startFrame"]], first["owner"])
        second_point = point_at(frames[second["startFrame"]], second["owner"])
        if first_point is None or second_point is None:
            reject(first, "possession-anchor-player-not-directly-observed")
            continue
        if not ball_continuous(
            frames, ball_id, first["startFrame"], second["startFrame"]
        ):
            reject(first, "ball-xy-not-continuous-between-anchors")
            continue
        first_ball = ball_at(frames[first["startFrame"]], ball_id)
        second_ball = ball_at(frames[second["startFrame"]], ball_id)
        if first_ball is None or second_ball is None:
            reject(first, "ball-anchor-not-observed")
            continue
        anchor_distances = [
            anchor_ball_distance(frames, ball_id, anchor)
            for anchor in (first, second)
        ]
        if any(
            distance is None or distance > 3.5
            for distance in anchor_distances
        ):
            reject(first, "possession-anchor-ball-distance-over-3.5m")
            continue

        same_team = first["team"] == second["team"]
        if same_team and not group_consistent(
            frames, first["startFrame"], second["startFrame"], first["team"]
        ):
            reject(first, "source-possession-team-changes-between-same-team-owners")
            continue
        home_actor = actor["team_id"] == match["home_team"]["id"]
        direction = directions[first["period"]] * (1 if home_actor else -1)
        pressure_evidence = nearest_opponent_distance(
            match, frames[first["startFrame"]], actor, first_point
        )
        pressure = pressure_evidence[0] if pressure_evidence is not None else None
        pressure_player_id = (
            pressure_evidence[1] if pressure_evidence is not None else None
        )
        carry_start = point_at(frames[first["startFrame"]], first["owner"])
        carry_end = point_at(frames[first["endFrame"]], first["owner"])
        carry = (
            math.dist(carry_start, carry_end)
            if carry_start is not None and carry_end is not None
            else 0
        )
        metrics = {
            "forwardMeters": round((second_point[0] - first_point[0]) * direction, 3),
            "lateralMeters": round(abs(second_point[1] - first_point[1]), 3),
            "startWidthMeters": round(abs(first_point[1]), 3),
            "insideGainMeters": round(abs(first_point[1]) - abs(second_point[1]), 3),
            "pressureMeters": round(pressure, 3) if pressure is not None else None,
            "carryMeters": round(carry, 3),
            "sequenceSeconds": round((second["startFrame"] - first["startFrame"]) / FPS, 3),
        }
        third = None
        for cursor in range(second_index + 1, min(second_index + 8, len(touches))):
            option = touches[cursor]
            if option["period"] != first["period"]:
                break
            if (option["startFrame"] - second["startFrame"]) / FPS > 8:
                break
            if option["owner"] == second["owner"]:
                continue
            if option["team"] == first["team"]:
                point = point_at(frames[option["startFrame"]], option["owner"])
                distance = anchor_ball_distance(frames, ball_id, option)
                if (
                    point is not None
                    and distance is not None
                    and distance <= 3.5
                    and ball_continuous(
                    frames, ball_id, second["startFrame"], option["startFrame"]
                    )
                    and group_consistent(
                        frames,
                        first["startFrame"],
                        option["startFrame"],
                        first["team"],
                    )
                ):
                    third = option
            break

        if same_team:
            theme = classify_connection(metrics, third is not None)
            if theme is None:
                reject(first, "connection-does-not-pass-a-spatial-theme-threshold")
                continue
        else:
            theme = "turnover"

        participants = [first["owner"], second["owner"]]
        anchors = [first, second]
        if theme == "combination" and third is not None:
            participants.append(third["owner"])
            anchors.append(third)
            metrics["sequenceSeconds"] = round(
                (third["startFrame"] - first["startFrame"]) / FPS, 3
            )
            bounds = final_clip_bounds(match, frames, ball_id, anchors)
            if bounds is None:
                reject(first, "no-continuous-clip-around-final-combination-anchor")
                continue
            start, end = bounds
        highlighted = list(dict.fromkeys(participants))
        if theme == "pressureSupport" and pressure_player_id is not None:
            highlighted.append(pressure_player_id)
            highlighted = list(dict.fromkeys(highlighted))
        candidate = {
            "matchId": match["id"],
            "period": first["period"],
            "startFrame": start,
            "endFrame": end,
            "anchorFrame": first["startFrame"],
            "focusId": first["owner"],
            "attackingTeam": "home" if home_actor else "away",
            "attackDirection": direction,
            "theme": theme,
            "participants": participants,
            "highlightPlayerIds": highlighted,
            "anchors": anchors,
            "pressurePlayerId": (
                pressure_player_id if theme == "pressureSupport" else None
            ),
            "metrics": metrics,
            "visibleParticipantCount": len(highlighted),
        }
        candidate["score"] = candidate_score(candidate)
        candidates.append(candidate)

        # A quick regain is a distinct factual pattern and uses the recovering
        # player as focal actor when that player belongs to the familiar set.
        if not same_team:
            for cursor in range(second_index + 1, min(second_index + 10, len(touches))):
                third_touch = touches[cursor]
                if third_touch["period"] != first["period"]:
                    break
                seconds = (third_touch["startFrame"] - second["startFrame"]) / FPS
                if seconds > 10:
                    break
                third_player = metadata[third_touch["owner"]]
                if third_touch["team"] != first["team"] or not is_famous(third_player):
                    continue
                third_point = point_at(
                    frames[third_touch["startFrame"]], third_touch["owner"]
                )
                third_distance = anchor_ball_distance(frames, ball_id, third_touch)
                if (
                    third_point is None
                    or third_distance is None
                    or third_distance > 3.5
                    or not ball_continuous(
                    frames, ball_id, second["startFrame"], third_touch["startFrame"]
                    )
                ):
                    continue
                recovery_anchors = [first, second, third_touch]
                recovery_bounds = final_clip_bounds(
                    match, frames, ball_id, recovery_anchors
                )
                if recovery_bounds is None:
                    continue
                recovery = dict(candidate)
                recovery["theme"] = "recovery"
                recovery["focusId"] = third_touch["owner"]
                recovery["participants"] = [
                    first["owner"],
                    second["owner"],
                    third_touch["owner"],
                ]
                recovery["anchors"] = recovery_anchors
                recovery["highlightPlayerIds"] = list(
                    dict.fromkeys(recovery["participants"])
                )
                recovery["pressurePlayerId"] = None
                recovery["startFrame"], recovery["endFrame"] = recovery_bounds
                recovery["visibleParticipantCount"] = len(
                    recovery["highlightPlayerIds"]
                )
                recovery["metrics"] = dict(metrics)
                recovery["metrics"]["sequenceSeconds"] = round(
                    (third_touch["startFrame"] - first["startFrame"]) / FPS, 3
                )
                recovery["score"] = candidate_score(recovery)
                candidates.append(recovery)
                break
    return candidates, rejected


def choose_candidates(
    candidates: list[dict],
    match_id: int,
    validator=None,
) -> tuple[list[dict], list[dict]]:
    selected: list[dict] = []
    focal_counts: collections.Counter[int] = collections.Counter()
    theme_counts: collections.Counter[str] = collections.Counter()
    rejected = []
    ordered = sorted(
        candidates,
        key=lambda candidate: (
            -candidate["score"],
            THEMES.index(candidate["theme"]),
            candidate["anchorFrame"],
            candidate["focusId"],
        ),
    )
    # First establish local theme breadth, then fill by evidence score.
    passes = [True, False]
    for diversity_pass in passes:
        for candidate in ordered:
            if len(selected) >= SCENES_PER_MATCH:
                break
            if candidate in selected:
                continue
            reason = None
            if diversity_pass and theme_counts[candidate["theme"]] > 0:
                continue
            if focal_counts[candidate["focusId"]] >= MAX_FOCAL_PER_MATCH:
                reason = "per-match-focal-cap"
            elif theme_counts[candidate["theme"]] >= MAX_THEME_PER_MATCH:
                reason = "per-match-theme-cap"
            elif any(
                abs(candidate["anchorFrame"] - item["anchorFrame"])
                < MIN_ANCHOR_SEPARATION
                for item in selected
            ):
                reason = "overlaps-an-already-selected-learning-interval"
            if reason is not None:
                if not diversity_pass:
                    rejected.append(
                        {
                            "matchId": match_id,
                            "sourceFrame": candidate["anchorFrame"],
                            "owner": candidate["focusId"],
                            "reason": reason,
                        }
                    )
                continue
            if validator is not None:
                try:
                    validator(candidate)
                except ValueError as error:
                    rejected.append(
                        {
                            "matchId": match_id,
                            "sourceFrame": candidate["anchorFrame"],
                            "owner": candidate["focusId"],
                            "reason": f"derived-asset-quality: {error}",
                        }
                    )
                    continue
            selected.append(candidate)
            focal_counts[candidate["focusId"]] += 1
            theme_counts[candidate["theme"]] += 1
    if len(selected) != SCENES_PER_MATCH:
        raise ValueError(
            f"Match {match_id} produced {len(selected)} balanced scenes, "
            f"expected {SCENES_PER_MATCH}; reasons="
            f"{dict(collections.Counter(item['reason'] for item in rejected))}"
        )
    return selected, rejected


def player_payload(match: dict, active: list[dict]) -> list[dict]:
    home_id = match["home_team"]["id"]
    result = [
        {
            "id": player["trackable_object"],
            "number": player["number"],
            "name": full_name(player),
            "home": player["team_id"] == home_id,
            "keeper": player["player_role"]["acronym"] == "GK",
        }
        for player in active
    ]
    result.sort(key=lambda item: (not item["home"], item["number"], item["id"]))
    return result


def source_steps(candidate: dict, frames: list[dict], players: list[dict], ball_id: int) -> list[dict]:
    start = candidate["startFrame"]
    player_ids = {player["id"] for player in players}
    opening = frames[start]
    ball = ball_at(opening, ball_id)
    visible = [
        player
        for player in players
        if point_at(opening, player["id"]) is not None
    ]
    if not visible or ball is None:
        raise ValueError("Opening context has no visible identified actor")
    opener = min(
        visible,
        key=lambda player: math.dist(point_at(opening, player["id"]), ball),
    )
    steps = [{"time": 0.0, "kind": "observe", "actorId": opener["id"]}]
    for anchor_index, anchor in enumerate(candidate["anchors"]):
        actor = anchor["owner"]
        if actor not in player_ids:
            raise ValueError("Anchor actor is outside active roster")
        time = round((anchor["startFrame"] - start) / FPS, 3)
        if time <= steps[-1]["time"] or time >= (candidate["endFrame"] - start) / FPS:
            continue
        if anchor_index == 0:
            kind = "carry" if candidate["theme"] == "carryThenConnect" else "receive"
        else:
            kind = "receive"
        steps.append({"time": time, "kind": kind, "actorId": actor})
    if len(steps) < 2:
        raise ValueError("Scene does not contain a usable evidence step")
    return steps


def build_scene(
    candidate: dict,
    match: dict,
    frames: list[dict],
    observations: dict[int, dict[int, tuple[int, int]]],
) -> tuple[dict, dict]:
    start, end = candidate["startFrame"], candidate["endFrame"]
    interval = frames[start : end + 1]
    active = active_players(match, interval)
    players = player_payload(match, active)
    index_by_id = {player["id"]: index for index, player in enumerate(players)}
    metadata = {player["trackable_object"]: player for player in match["players"]}
    ball_id = match["ball"]["trackable_object"]
    raw_frames = []
    visibility = []
    identified_counts = []
    quantization_error = 0.0
    for source in interval:
        observed: dict[int, tuple[float, float]] = {}
        for item in source["data"]:
            entity = item.get("trackable_object")
            if entity not in index_by_id:
                continue
            point = (number(item.get("x"), "player x"), number(item.get("y"), "player y"))
            if entity in observed and observed[entity] != point:
                raise ValueError("Conflicting direct identity observations")
            observed[entity] = point
        row, flags = [], []
        for player in players:
            point = observed.get(player["id"])
            flags.append(1 if point is not None else 0)
            for value in point or (0.0, 0.0):
                quantized = round(value * 100)
                if point is not None:
                    quantization_error = max(
                        quantization_error, abs(quantized / 100 - value)
                    )
                row.append(quantized)
        ball = item_at(source, ball_id)
        if ball is None:
            raise ValueError("Ball XY is not continuous inside selected clip")
        row.extend(
            (
                round(number(ball.get("x"), "ball x") * 100),
                round(number(ball.get("y"), "ball y") * 100),
                0,
            )
        )
        raw_frames.append(row)
        visibility.append(flags)
        identified_counts.append(sum(flags))

    # A small number of metadata-linked tracks contain adjacent-frame identity
    # jumps.  They are source observations, but impossible motion is not usable
    # evidence.  Remove a wide enough window for a provenance-marked bridge to
    # stay at or below 15 m/s.  The original values remain reproducible from
    # the pinned raw hash and every removal is counted in the proof.
    continuity_exclusions = 0
    excluded_local_frames: dict[int, set[int]] = {
        player["id"]: set() for player in players
    }
    for player_index, player in enumerate(players):
        for local in range(1, len(raw_frames)):
            if not visibility[local - 1][player_index] or not visibility[local][player_index]:
                continue
            distance = math.hypot(
                (raw_frames[local][player_index * 2] - raw_frames[local - 1][player_index * 2]) / 100,
                (raw_frames[local][player_index * 2 + 1] - raw_frames[local - 1][player_index * 2 + 1]) / 100,
            )
            if distance * FPS <= 15:
                continue
            needed = max(2, math.ceil(distance / 15 * FPS))
            bad_start = max(0, local - needed // 2)
            bad_end = min(len(raw_frames) - 1, bad_start + needed - 1)
            for bad in range(bad_start, bad_end + 1):
                excluded_local_frames[player["id"]].add(bad)
    for player_index, player in enumerate(players):
        for local in excluded_local_frames[player["id"]]:
            if visibility[local][player_index]:
                continuity_exclusions += 1
                visibility[local][player_index] = 0
                raw_frames[local][player_index * 2] = 0
                raw_frames[local][player_index * 2 + 1] = 0
    identified_counts = [sum(flags) for flags in visibility]
    if min(identified_counts) == 0:
        raise ValueError("Motion-continuity filter left an empty source frame")

    for anchor in candidate["anchors"]:
        local = anchor["startFrame"] - start
        if local < 0 or local >= len(visibility):
            raise ValueError("Evidence anchor falls outside selected clip")
        player_index = index_by_id.get(anchor["owner"])
        if player_index is None or not visibility[local][player_index]:
            raise ValueError("Evidence anchor failed the motion-continuity filter")
        distance = anchor_ball_distance(frames, ball_id, anchor)
        if distance is None or distance > 3.5:
            raise ValueError("Evidence owner is more than 3.5 m from the ball")
    metric_checks = []
    if candidate["theme"] == "carryThenConnect":
        carry_frame = candidate["anchors"][0]["endFrame"]
        carry_local = carry_frame - start
        carry_player_id = candidate["anchors"][0]["owner"]
        carry_index = index_by_id.get(carry_player_id)
        if (
            carry_local < 0
            or carry_local >= len(visibility)
            or carry_index is None
            or not visibility[carry_local][carry_index]
        ):
            raise ValueError("Carry endpoint failed the motion-continuity filter")
        metric_checks.append(
            {
                "kind": "carryEnd",
                "sourceFrame": carry_frame,
                "playerId": carry_player_id,
                "playerObserved": True,
            }
        )
    pressure_player_id = candidate.get("pressurePlayerId")
    if pressure_player_id is not None:
        pressure_index = index_by_id.get(pressure_player_id)
        pressure_local = candidate["anchors"][0]["startFrame"] - start
        if pressure_index is None or not visibility[pressure_local][pressure_index]:
            raise ValueError("Nearby opponent failed the motion-continuity filter")
        metric_checks.append(
            {
                "kind": "nearestOpponent",
                "sourceFrame": candidate["anchors"][0]["startFrame"],
                "playerId": pressure_player_id,
                "playerObserved": True,
            }
        )

    spec = {"id": "pending", "startFrame": start, "endFrame": end}
    subset_observations = {}
    for player in players:
        excluded_source_frames = {
            start + local for local in excluded_local_frames[player["id"]]
        }
        subset_observations[player["id"]] = {
            frame: point
            for frame, point in observations[player["id"]].items()
            if frame not in excluded_source_frames
        }
    display_frames, display_provenance, reconstruction = reconstruct_display(
        spec,
        players,
        raw_frames,
        visibility,
        subset_observations,
        match["pitch_length"],
        match["pitch_width"],
    )
    player_speed = max_speed(raw_frames, visibility, len(players))
    display_speed = max_display_speed(display_frames, len(players))
    if player_speed > 15 or display_speed > 15:
        raise ValueError(
            f"Implausible player continuity ({player_speed:.2f}/{display_speed:.2f} m/s)"
        )
    ball_speed = validate_ball_speed(raw_frames)

    # Preserve exact metric scale while allowing genuine positions just beyond
    # the touchline or goal line to remain visible.  The view is fixed for the
    # entire scene and includes a small marker/tail safety margin.
    half_length = match["pitch_length"] / 2
    half_width = match["pitch_width"] / 2
    maximum_x = max(
        [abs(row[-3] / 100) for row in raw_frames]
        + [abs(row[index] / 100) for row in display_frames for index in range(0, len(row), 2)]
    )
    maximum_y = max(
        [abs(row[-2] / 100) for row in raw_frames]
        + [abs(row[index] / 100) for row in display_frames for index in range(1, len(row), 2)]
    )
    margin_x = max(1.4, maximum_x - half_length + 1.4)
    margin_y = max(1.4, maximum_y - half_width + 1.4)
    focus = metadata[candidate["focusId"]]
    focus_slug = "-".join(
        "".join(character.lower() if character.isalnum() else " " for character in focus["last_name"]).split()
    )
    clock_slug = str(candidate["anchorFrame"])
    scene_id = f"{match['id']}-{clock_slug}-{focus_slug}-{candidate['theme']}"
    spec["id"] = scene_id
    home_direction, direction_proof = goalkeeper_direction(
        match, frames, candidate["period"]
    )
    direction = home_direction if candidate["attackingTeam"] == "home" else -home_direction
    if direction != candidate["attackDirection"]:
        raise ValueError("Candidate attacking direction changed")
    steps = source_steps(candidate, frames, players, ball_id)
    duration = (end - start) / FPS
    data = {
        "fps": FPS,
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
        "frames": raw_frames,
        "visibility": visibility,
        "displayFrames": display_frames,
        "displayProvenance": display_provenance,
        "poses": [],
        "events": [],
        "sourceCommit": HISTORICAL_COMMIT,
        "sourceUrl": f"{HISTORICAL_SOURCE_ROOT}/data/matches/{match['id']}",
        "sourceFrameStart": start,
        "period": candidate["period"],
        "coverage": "broadcastVisible",
        "annotationSource": "derived",
        "ballHeightAvailable": False,
        "scene": {
            "id": scene_id,
            "category": CATEGORY[candidate["theme"]],
            "titleKey": f"spatialTheme{candidate['theme'][0].upper()}{candidate['theme'][1:]}",
            "focusKey": f"spatialObjective{candidate['theme'][0].upper()}{candidate['theme'][1:]}",
            "homeColor": match["home_team_kit"]["jersey_color"],
            "awayColor": match["away_team_kit"]["jersey_color"],
            "homeNumberColor": match["home_team_kit"]["number_color"],
            "awayNumberColor": match["away_team_kit"]["number_color"],
            "attackDirection": direction,
            "focusPlayerId": candidate["focusId"],
            "camera": [
                -half_length - margin_x,
                half_length + margin_x,
                -half_width - margin_y,
                half_width + margin_y,
            ],
            "steps": steps,
            "outcome": "end",
        },
    }
    local_anchors = [
        {
            "sourceFrame": anchor["startFrame"],
            "sourceClock": frames[anchor["startFrame"]]["time"],
            "time": round((anchor["startFrame"] - start) / FPS, 3),
            "playerId": anchor["owner"],
            "playerName": full_name(metadata[anchor["owner"]]),
            "ballDistanceMeters": round(
                anchor_ball_distance(frames, ball_id, anchor), 4
            ),
            "playerObserved": point_at(frames[anchor["startFrame"]], anchor["owner"]) is not None,
            "ballObserved": ball_at(frames[anchor["startFrame"]], ball_id) is not None,
            "possessionOwner": frames[anchor["startFrame"]]["possession"].get("trackable_object"),
            "possessionGroup": frames[anchor["startFrame"]]["possession"].get("group"),
        }
        for anchor in candidate["anchors"]
    ]
    evidence_start = local_anchors[0]["time"]
    evidence_end = local_anchors[-1]["time"]
    entry = {
        "id": scene_id,
        "asset": f"assets/scan_pass_spatial/scenes/{scene_id}.json",
        "theme": candidate["theme"],
        "matchId": match["id"],
        "date": match["date_time"][:10],
        "home": match["home_team"]["short_name"],
        "away": match["away_team"]["short_name"],
        "period": candidate["period"],
        "startFrame": start,
        "endFrame": end,
        "startClock": data["startClock"],
        "duration": duration,
        "focusPlayerId": candidate["focusId"],
        "focusPlayerName": full_name(focus),
        "evidenceAnchors": [
            {
                "time": anchor["time"],
                "playerId": anchor["playerId"],
                "playerName": anchor["playerName"],
            }
            for anchor in local_anchors
        ],
        "highlightPlayerIds": candidate["highlightPlayerIds"],
        "attackingTeam": candidate["attackingTeam"],
        "attackDirection": direction,
        "evidenceStart": evidence_start,
        "evidenceEnd": evidence_end,
        "metrics": candidate["metrics"],
        "sourceCommit": HISTORICAL_COMMIT,
        "sourceUrl": data["sourceUrl"],
    }
    proof = {
        "id": scene_id,
        "matchId": match["id"],
        "theme": candidate["theme"],
        "selectionScore": candidate["score"],
        "sourceStartFrame": start,
        "sourceEndFrame": end,
        "sourceStartClock": interval[0]["time"],
        "sourceEndClock": interval[-1]["time"],
        "period": candidate["period"],
        "durationSeconds": duration,
        "ballXYObservations": len(interval),
        "ballHeightAvailable": False,
        "minimumObservedPlayers": min(identified_counts),
        "meanObservedPlayers": round(sum(identified_counts) / len(identified_counts), 4),
        "maxSourcePlayerSpeedMetersPerSecond": round(player_speed, 4),
        "maxDisplayPlayerSpeedMetersPerSecond": round(display_speed, 4),
        "maxBallSpeedMetersPerSecond": round(ball_speed, 4),
        "maxQuantizationErrorMeters": round(quantization_error, 8),
        "motionContinuityExcludedObservations": continuity_exclusions,
        "directionProof": direction_proof,
        "anchors": local_anchors,
        "metricChecks": metric_checks,
        "metrics": candidate["metrics"],
        "reconstruction": {
            "observedProvenance": 0,
            "inferredProvenance": 1,
            "inferredExcludedFromEvidence": True,
            "players": [
                {
                    "trackableObject": item["trackableObject"],
                    "observedFrames": item["observedFrames"],
                    "inferredFrames": item["inferredFrames"],
                    "inferredCoverage": item["inferredCoverage"],
                }
                for item in reconstruction
            ],
        },
    }
    return data, {"entry": entry, "proof": proof}


def interleave(entries_by_match: dict[int, list[dict]], match_order: list[int]) -> list[dict]:
    per_match = {
        match_id: sorted(
            entries,
            key=lambda entry: (
                THEMES.index(entry["theme"]),
                entry["startFrame"],
                entry["id"],
            ),
        )
        for match_id, entries in entries_by_match.items()
    }
    result = []
    for row in range(SCENES_PER_MATCH):
        # Rotate the match order on each row so adjacent scenes do not keep the
        # same competition ordering either.
        offset = row % len(match_order)
        rotated = match_order[offset:] + match_order[:offset]
        for match_id in rotated:
            result.append(per_match[match_id][row])
    opener_priority = {
        name: rank
        for rank, name in enumerate(
            (
                "Lionel Messi",
                "Cristiano Ronaldo",
                "Kylian Mbappe",
                "Kevin de Bruyne",
                "Erling Haland",
            )
        )
    }
    eligible = [
        entry
        for entry in result
        if entry["focusPlayerName"] in opener_priority
        and entry["duration"] >= 15
        and entry["evidenceStart"] >= 4
        and entry["duration"] - entry["evidenceEnd"] >= 4
    ]
    if not eligible:
        raise ValueError("No recognisable opener has sufficient source context")
    opener = min(
        eligible,
        key=lambda entry: (
            opener_priority[entry["focusPlayerName"]],
            -entry["duration"],
            -(entry["evidenceEnd"] - entry["evidenceStart"]),
            entry["id"],
        ),
    )
    remaining = [entry for entry in result if entry is not opener]
    balanced = [opener]
    while remaining:
        next_index = next(
            (
                index
                for index, entry in enumerate(remaining)
                if entry["matchId"] != balanced[-1]["matchId"]
            ),
            None,
        )
        if next_index is None:
            raise ValueError("Unable to interleave source matches without adjacency")
        balanced.append(remaining.pop(next_index))
    return balanced


def verify_audit(raw_dir: Path, audit: dict) -> None:
    if audit.get("provider") != "SkillCorner Open Data":
        raise ValueError("Unexpected provider")
    if audit.get("commit") != HISTORICAL_COMMIT or audit.get("license") != "MIT":
        raise ValueError("Unexpected source revision or license")
    if audit.get("matchCount") != 9:
        raise ValueError("Expected exactly nine pinned historical matches")
    for record in audit["files"]:
        path = raw_dir / record["path"]
        if not path.is_file():
            raise ValueError(f"Missing source input: {path}")
        if path.stat().st_size != record["bytes"] or digest(path) != record["sha256"]:
            raise ValueError(f"Source hash mismatch: {record['path']}")


def verify_assets() -> None:
    catalog = read_json(ASSETS / "catalog.json")
    proof = read_json(ASSETS / "quality-proof.json")
    if len(catalog["scenes"]) < 100:
        raise ValueError("Spatial catalog contains fewer than 100 scenes")
    if len({item["matchId"] for item in catalog["scenes"]}) != 9:
        raise ValueError("Spatial catalog does not cover all nine matches")
    if len({item["focusPlayerName"] for item in catalog["scenes"]}) < 20:
        raise ValueError("Spatial catalog contains fewer than 20 focal players")
    if set(item["theme"] for item in catalog["scenes"]) != set(THEMES):
        raise ValueError("Spatial catalog does not cover all spatial themes")
    records = {item["id"]: item for item in proof["scenes"]}
    for scene in catalog["scenes"]:
        path = REPO / scene["asset"]
        record = records[scene["id"]]
        if not path.is_file() or digest(path) != record["assetSha256"]:
            raise ValueError(f"Derived scene hash mismatch: {scene['id']}")
        if any(
            not anchor["playerObserved"]
            or not anchor["ballObserved"]
            or anchor["playerId"] != anchor["possessionOwner"]
            for anchor in record["anchors"]
        ):
            raise ValueError(f"Unobserved evidence anchor: {scene['id']}")
        if any(
            anchor["ballDistanceMeters"] > 3.5
            for anchor in record["anchors"]
        ):
            raise ValueError(f"Distant ownership anchor: {scene['id']}")
        if record["maxBallSpeedMetersPerSecond"] > 50:
            raise ValueError(f"Implausible ball continuity: {scene['id']}")
        anchors = scene.get("evidenceAnchors", [])
        highlights = scene.get("highlightPlayerIds", [])
        if (
            len(anchors) < 2
            or len(highlights) < 2
            or len(highlights) > 4
            or len(highlights) != len(set(highlights))
            or any(anchor["playerId"] not in highlights for anchor in anchors)
        ):
            raise ValueError(f"Invalid ordered evidence model: {scene['id']}")
    preservation = read_json(ASSETS / "legacy-asset-preservation.json")
    for record in preservation["files"]:
        path = REPO / record["path"]
        if (
            not path.is_file()
            or path.stat().st_size != record["bytes"]
            or digest(path) != record["sha256"]
        ):
            raise ValueError(f"Legacy asset changed: {record['path']}")
    print(
        "VERIFIED "
        f"{len(catalog['scenes'])} scenes, "
        f"{len({item['matchId'] for item in catalog['scenes']})} matches, "
        f"{len({item['focusPlayerName'] for item in catalog['scenes']})} players, "
        f"{len(set(item['theme'] for item in catalog['scenes']))} themes"
    )


def generate(raw_dir: Path, audit_path: Path) -> None:
    audit = read_json(audit_path)
    verify_audit(raw_dir, audit)
    matches_index = read_json(raw_dir / "data/matches.json")
    match_order = [item["id"] for item in matches_index]
    if len(match_order) != 9:
        raise ValueError("Pinned match index changed")
    ASSETS.mkdir(parents=True, exist_ok=True)
    SCENES.mkdir(parents=True, exist_ok=True)
    for old in SCENES.glob("*.json"):
        old.unlink()
    shutil.copyfile(raw_dir / "LICENSE", ASSETS / "LICENSE")

    entries_by_match: dict[int, list[dict]] = {}
    proofs = []
    all_rejected = []
    for match_id in match_order:
        match = read_json(raw_dir / f"data/matches/{match_id}/match_data.json")
        frames = read_json(raw_dir / f"data/matches/{match_id}/structured_data.json")
        if any(frame["frame"] != index for index, frame in enumerate(frames)):
            raise ValueError(f"Source frame indices are not contiguous for {match_id}")
        metadata = {player["trackable_object"]: player for player in match["players"]}
        observations = direct_observations_by_entity(frames, set(metadata))
        candidates, rejected = build_candidates(match, frames)
        built_candidates = {}

        def validate_and_build(candidate: dict) -> None:
            key = (candidate["anchorFrame"], candidate["focusId"], candidate["theme"])
            built_candidates[key] = build_scene(
                candidate, match, frames, observations
            )

        selected, balance_rejected = choose_candidates(
            candidates, match_id, validate_and_build
        )
        all_rejected.extend(rejected)
        all_rejected.extend(balance_rejected)
        entries = []
        for candidate in selected:
            key = (candidate["anchorFrame"], candidate["focusId"], candidate["theme"])
            data, built = built_candidates[key]
            path = SCENES / f"{data['scene']['id']}.json"
            save(path, data)
            built["entry"]["assetSha256"] = digest(path)
            built["proof"]["asset"] = path.relative_to(REPO).as_posix()
            built["proof"]["assetBytes"] = path.stat().st_size
            built["proof"]["assetSha256"] = digest(path)
            entries.append(built["entry"])
            proofs.append(built["proof"])
        entries_by_match[match_id] = entries
        print(
            f"selected {len(entries)} of {len(candidates)} candidates for "
            f"{match['home_team']['short_name']} v {match['away_team']['short_name']}",
            flush=True,
        )
        del frames, observations

    scenes = interleave(entries_by_match, match_order)
    catalog = {
        "version": 1,
        "provider": "SkillCorner Open Data",
        "license": "MIT",
        "sourceCommit": HISTORICAL_COMMIT,
        "sourceUrl": HISTORICAL_SOURCE_ROOT,
        "matchCount": 9,
        "selection": {
            "fps": FPS,
            "preferredClipSeconds": CLIP_FRAMES / FPS,
            "minimumClipSeconds": MIN_CLIP_FRAMES / FPS,
            "leadSeconds": LEAD_FRAMES / FPS,
            "minimumAnchorSeparationSeconds": MIN_ANCHOR_SEPARATION / FPS,
            "scenesPerMatch": SCENES_PER_MATCH,
            "maximumScenesPerFocalPlayerPerMatch": MAX_FOCAL_PER_MATCH,
            "maximumScenesPerThemePerMatch": MAX_THEME_PER_MATCH,
            "interleaving": (
                "recognisable context-rich opener, then deterministic balanced "
                "source-match interleaving"
            ),
        },
        "scenes": scenes,
    }
    save(ASSETS / "catalog.json", catalog, pretty=True)
    source_manifest = {
        "provider": audit["provider"],
        "license": audit["license"],
        "commit": audit["commit"],
        "sourceUrl": HISTORICAL_SOURCE_ROOT,
        "rawDataBundled": False,
        "files": audit["files"],
    }
    save(ASSETS / "source-manifest.json", source_manifest, pretty=True)
    legacy_files = []
    for directory in (
        REPO / "assets/scan_pass_replay",
        REPO / "assets/scan_pass_authored",
    ):
        for path in sorted(value for value in directory.rglob("*") if value.is_file()):
            legacy_files.append(
                {
                    "path": path.relative_to(REPO).as_posix(),
                    "bytes": path.stat().st_size,
                    "sha256": digest(path),
                }
            )
    save(
        ASSETS / "legacy-asset-preservation.json",
        {
            "purpose": (
                "Independent byte-for-byte guard for the replay and authored "
                "asset families that predate the spatial library"
            ),
            "files": legacy_files,
        },
        pretty=True,
    )
    reason_counts = collections.Counter(item["reason"] for item in all_rejected)
    quality = {
        "generator": "tool/scan_pass_replay/prepare_spatial_library.py",
        "selectionDefinition": {
            "connection": (
                "successive distinct observed possession owners with continuously "
                "recorded ball XY; same-team labels are source-consistent"
            ),
            "claims": (
                "tracking-derived geometric descriptions only; no pass, goal, "
                "optimal-choice, body, foot, scan, or ball-height event is inferred"
            ),
            "themeThresholds": {
                "lateralSwitch": "at least 22 m lateral change",
                "forwardConnection": "at least 9 m in established attack direction",
                "pressureSupport": (
                    "nearest observed opposing player at the ownership anchor is "
                    "at most 6 m away and the connection is less than 10 m "
                    "forward; no approach or closing speed is inferred"
                ),
                "carryThenConnect": "possession owner moves at least 3.5 m while continuously tagged",
                "wideToInside": "starts at least 20 m wide and gains at least 6 m inside",
                "combination": "three observed same-team owners, each within 8 s",
                "turnover": "next observed owner belongs to the opposing source-labelled team",
                "recovery": "original team has a familiar observed owner within 10 s of a turnover",
            },
        },
        "counts": {
            "scenes": len(scenes),
            "matches": len({item["matchId"] for item in scenes}),
            "focalPlayers": len({item["focusPlayerName"] for item in scenes}),
            "focalPlayerScenes": dict(
                sorted(
                    collections.Counter(
                        item["focusPlayerName"] for item in scenes
                    ).items()
                )
            ),
            "themes": collections.Counter(item["theme"] for item in scenes),
            "rejectedCandidates": len(all_rejected),
            "rejectedReasons": reason_counts,
        },
        "scenes": sorted(proofs, key=lambda item: item["id"]),
        "rejectedCandidates": sorted(
            all_rejected,
            key=lambda item: (
                item["matchId"], item["sourceFrame"], item["owner"], item["reason"]
            ),
        ),
    }
    save(ASSETS / "quality-proof.json", quality, pretty=True)
    verify_assets()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("raw_dir", nargs="?", type=Path)
    parser.add_argument("--audit", type=Path)
    parser.add_argument("--verify-assets", action="store_true")
    args = parser.parse_args()
    if args.verify_assets:
        verify_assets()
        return
    if args.raw_dir is None or args.audit is None:
        parser.error("raw_dir and --audit are required for generation")
    generate(args.raw_dir.resolve(), args.audit.resolve())


if __name__ == "__main__":
    main()
