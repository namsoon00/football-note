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
    max_speed,
    number,
    read_json,
    save,
)


REPO = Path(__file__).resolve().parents[2]
ASSETS = REPO / "assets/scan_pass_spatial"
SCENES = ASSETS / "scenes"
FPS = 10
PREFERRED_CLIP_FRAMES = 300
MIN_CLIP_FRAMES = 200
MAX_CLIP_FRAMES = 400
MIN_CONTEXT_FRAMES = 40
ACTOR_GUARD_FRAMES = 5
MIN_ANCHOR_SEPARATION = 200
MIN_PRESSURE_CONNECTION_METERS = 4
MIN_COMBINATION_LEG_METERS = 5
MAX_CATALOG_SCENES = 18
MAX_VALIDATED_CANDIDATES_PER_MATCH = 24
MISSING_COORDINATE = -(2**31)

THEMES = (
    "lateralSwitch",
    "pressureSupport",
    "combination",
)

CATEGORY = {
    "lateralSwitch": "switchPlay",
    "pressureSupport": "pressure",
    "combination": "combination",
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
    """Return the closest feasible 20-40 s clip to 30 s.

    The returned interval is entirely source-backed and keeps at least four
    seconds before the departure anchor and after the final arrival anchor.
    Nothing is padded or time-stretched when the continuous source segment is
    shorter than the preferred duration.
    """
    segment_start = first_anchor
    while (
        segment_start > 0
        and first_anchor - segment_start < MAX_CLIP_FRAMES
        and frames[segment_start - 1]["period"] == period
        and frames[segment_start - 1]["frame"] == segment_start - 1
        and frames[segment_start - 1]["time"] is not None
        and ball_at(frames[segment_start - 1], ball_id) is not None
    ):
        segment_start -= 1
    segment_end = last_anchor
    while (
        segment_end + 1 < len(frames)
        and segment_end - last_anchor < MAX_CLIP_FRAMES
        and frames[segment_end + 1]["period"] == period
        and frames[segment_end + 1]["frame"] == segment_end + 1
        and frames[segment_end + 1]["time"] is not None
        and ball_at(frames[segment_end + 1], ball_id) is not None
    ):
        segment_end += 1
    anchor_span = last_anchor - first_anchor
    minimum_length = max(
        MIN_CLIP_FRAMES,
        anchor_span + MIN_CONTEXT_FRAMES * 2,
    )
    available_length = segment_end - segment_start
    if minimum_length > MAX_CLIP_FRAMES or available_length < minimum_length:
        return None

    length = min(
        MAX_CLIP_FRAMES,
        max(minimum_length, min(PREFERRED_CLIP_FRAMES, available_length)),
    )
    earliest = max(segment_start, last_anchor + MIN_CONTEXT_FRAMES - length)
    latest = min(first_anchor - MIN_CONTEXT_FRAMES, segment_end - length)
    if earliest > latest:
        return None
    balanced = first_anchor - (length - anchor_span) // 2
    start = min(max(balanced, earliest), latest)
    end = start + length
    if not (
        MIN_CLIP_FRAMES <= end - start <= MAX_CLIP_FRAMES
        and first_anchor - start >= MIN_CONTEXT_FRAMES
        and end - last_anchor >= MIN_CONTEXT_FRAMES
        and start < first_anchor < last_anchor < end
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


def continuously_observed(
    frames: list[dict], entity: int, start: int, end: int
) -> bool:
    return all(point_at(frames[index], entity) is not None for index in range(start, end + 1))


def guarded_anchor(
    frames: list[dict], entity: int, source_frame: int
) -> dict | None:
    start = source_frame - ACTOR_GUARD_FRAMES
    end = source_frame + ACTOR_GUARD_FRAMES
    if start < 0 or end >= len(frames) or not continuously_observed(
        frames, entity, start, end
    ):
        return None
    return {
        "playerId": entity,
        "sourceFrame": source_frame,
        "sourceStartFrame": start,
        "sourceEndFrame": end,
        "observedFrames": end - start + 1,
        "expectedFrames": end - start + 1,
    }


def ownership_visibility(
    frames: list[dict], metadata: dict[int, dict], start: int, end: int
) -> dict | None:
    """Prove every meaningful source-labelled owner stays directly visible."""
    segments = []
    ignored_short_frames = 0
    cursor = start
    while cursor <= end:
        owner = frames[cursor]["possession"].get("trackable_object")
        if owner not in metadata:
            cursor += 1
            continue
        segment_end = cursor
        while (
            segment_end + 1 <= end
            and frames[segment_end + 1]["possession"].get("trackable_object") == owner
        ):
            segment_end += 1
        length = segment_end - cursor + 1
        if length < 3:
            ignored_short_frames += length
        else:
            observed = sum(
                point_at(frames[index], owner) is not None
                for index in range(cursor, segment_end + 1)
            )
            if observed != length:
                return None
            segments.append(
                {
                    "playerId": owner,
                    "sourceStartFrame": cursor,
                    "sourceEndFrame": segment_end,
                    "observedFrames": observed,
                    "expectedFrames": length,
                }
            )
        cursor = segment_end + 1
    if not segments:
        return None
    return {
        "segments": segments,
        "meaningfulFrames": sum(item["expectedFrames"] for item in segments),
        "observedFrames": sum(item["observedFrames"] for item in segments),
        "ignoredShortFrames": ignored_short_frames,
    }


def source_anchor(touch: dict, source_frame: int, role: str) -> dict:
    return {
        **touch,
        "startFrame": source_frame,
        "endFrame": source_frame,
        "role": role,
    }


def classified_themes(metrics: dict, has_third: bool) -> list[str]:
    themes = []
    if metrics["lateralMeters"] >= 22:
        themes.append("lateralSwitch")
    if (
        metrics["pressureMeters"] is not None
        and metrics["pressureMeters"] <= 6
        and metrics["forwardMeters"] < 10
    ):
        themes.append("pressureSupport")
    if has_third:
        themes.append("combination")
    return themes


def teaching_travel_rejection(theme: str, leg_meters: list[float]) -> str | None:
    if (
        theme == "pressureSupport"
        and leg_meters[0] < MIN_PRESSURE_CONNECTION_METERS
    ):
        return "pressure-support-connection-under-four-metres"
    if theme == "combination" and min(leg_meters) < MIN_COMBINATION_LEG_METERS:
        return "combination-leg-under-five-metres"
    return None


def candidate_score(candidate: dict) -> float:
    metrics = candidate["metrics"]
    theme = candidate["theme"]
    score = {
        "lateralSwitch": metrics["lateralMeters"],
        "pressureSupport": 12 - (metrics["pressureMeters"] or 12),
        "combination": 12 - metrics["sequenceSeconds"],
    }[theme]
    duration = (candidate["endFrame"] - candidate["startFrame"]) / FPS
    recognisable = 1 if candidate.get("recognisableFocus") else 0
    return round(
        score
        + candidate["visibleParticipantCount"] * 0.1
        + recognisable * .25
        - abs(duration - PREFERRED_CLIP_FRAMES / FPS) * .05,
        4,
    )


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
        if first["team"] != second["team"]:
            reject(first, "connection-owners-belong-to-different-teams")
            continue

        departure = source_anchor(first, first["endFrame"], "departure")
        arrival = source_anchor(second, second["startFrame"], "arrival")
        first_point = point_at(frames[departure["startFrame"]], first["owner"])
        second_point = point_at(frames[second["startFrame"]], second["owner"])
        if first_point is None or second_point is None:
            reject(first, "possession-anchor-player-not-directly-observed")
            continue
        if not ball_continuous(
            frames, ball_id, departure["startFrame"], arrival["startFrame"]
        ):
            reject(first, "ball-xy-not-continuous-between-anchors")
            continue
        anchor_distances = [
            anchor_ball_distance(frames, ball_id, anchor)
            for anchor in (departure, arrival)
        ]
        if any(
            distance is None or distance > 3.5
            for distance in anchor_distances
        ):
            reject(first, "possession-anchor-ball-distance-over-3.5m")
            continue

        if not group_consistent(
            frames, departure["startFrame"], arrival["startFrame"], first["team"]
        ):
            reject(first, "source-possession-team-changes-between-same-team-owners")
            continue
        home_actor = actor["team_id"] == match["home_team"]["id"]
        direction = directions[first["period"]] * (1 if home_actor else -1)
        pressure_evidence = nearest_opponent_distance(
            match, frames[departure["startFrame"]], actor, first_point
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
            "sequenceSeconds": round((arrival["startFrame"] - departure["startFrame"]) / FPS, 3),
            "connectionMeters": round(
                math.dist(
                    ball_at(frames[departure["startFrame"]], ball_id),
                    ball_at(frames[arrival["startFrame"]], ball_id),
                ),
                3,
            ),
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
                    third = source_anchor(option, option["startFrame"], "arrival")
                    break

        themes = classified_themes(metrics, third is not None)
        if not themes:
            reject(first, "connection-does-not-pass-an-approved-theme-threshold")
            continue
        for theme in themes:
            anchors = [departure, arrival]
            participants = [first["owner"], second["owner"]]
            theme_metrics = dict(metrics)
            leg_meters = [theme_metrics["connectionMeters"]]
            if theme == "combination":
                if third is None:
                    continue
                anchors.append(third)
                participants.append(third["owner"])
                second_leg = math.dist(
                    ball_at(frames[arrival["startFrame"]], ball_id),
                    ball_at(frames[third["startFrame"]], ball_id),
                )
                leg_meters.append(round(second_leg, 3))
                theme_metrics["legMeters"] = leg_meters
                theme_metrics["sequenceSeconds"] = round(
                    (third["startFrame"] - departure["startFrame"]) / FPS, 3
                )
            if reason := teaching_travel_rejection(theme, leg_meters):
                reject(first, reason)
                continue
            bounds = final_clip_bounds(match, frames, ball_id, anchors)
            if bounds is None:
                reject(first, "no-20-to-40-second-source-clip-with-four-second-context")
                continue
            start, end = bounds
            ownership = ownership_visibility(frames, metadata, start, end)
            if ownership is None:
                reject(first, "meaningful-owned-ball-segment-has-an-unobserved-owner")
                continue

            core_start = anchors[0]["startFrame"] - ACTOR_GUARD_FRAMES
            core_end = anchors[-1]["startFrame"] + ACTOR_GUARD_FRAMES
            guards = [
                guarded_anchor(frames, anchor["owner"], anchor["startFrame"])
                for anchor in anchors
            ]
            if any(guard is None for guard in guards):
                reject(first, "departure-or-arrival-actor-missing-in-guard-window")
                continue
            core_player_ids = list(dict.fromkeys(participants))
            if any(
                not continuously_observed(frames, player_id, core_start, core_end)
                for player_id in core_player_ids
            ):
                reject(first, "core-actor-has-a-central-visibility-gap")
                continue

            support_ids = [
                player_id
                for player_id, player in metadata.items()
                if player["team_id"] == actor["team_id"]
                and player_id not in core_player_ids
                and continuously_observed(frames, player_id, core_start, core_end)
            ]
            support_ids.sort(
                key=lambda player_id: math.dist(
                    point_at(frames[departure["startFrame"]], player_id),
                    first_point,
                )
            )
            if not support_ids:
                reject(first, "no-continuously-observed-off-ball-support-actor")
                continue

            opponent_ids = [
                player_id
                for player_id, player in metadata.items()
                if player["team_id"] != actor["team_id"]
                and continuously_observed(frames, player_id, core_start, core_end)
            ]
            opponent_ids.sort(
                key=lambda player_id: math.dist(
                    point_at(frames[departure["startFrame"]], player_id),
                    first_point,
                )
            )
            minimum_observed_opponents = min(
                sum(
                    point_at(frames[source_frame], player["trackable_object"])
                    is not None
                    for player in match["players"]
                    if player["team_id"] != actor["team_id"]
                )
                for source_frame in range(core_start, core_end + 1)
            )
            if not opponent_ids or minimum_observed_opponents < 2:
                reject(first, "insufficient-directly-observed-opposing-context")
                continue
            if theme == "pressureSupport" and pressure_player_id not in opponent_ids:
                reject(first, "pressure-context-defender-not-continuously-observed")
                continue

            relevant_opponents = (
                [pressure_player_id]
                if theme == "pressureSupport"
                else [opponent_ids[0]]
            )
            relevant_opponents.extend(
                player_id
                for player_id in opponent_ids
                if player_id not in relevant_opponents
            )
            relevant_opponents = relevant_opponents[:2]
            highlighted = list(
                dict.fromkeys(core_player_ids + [support_ids[0]] + relevant_opponents)
            )
            candidate = {
                "matchId": match["id"],
                "period": first["period"],
                "startFrame": start,
                "endFrame": end,
                "anchorFrame": departure["startFrame"],
                "focusId": first["owner"],
                "attackingTeam": "home" if home_actor else "away",
                "attackDirection": direction,
                "theme": theme,
                "participants": core_player_ids,
                "corePlayerIds": core_player_ids,
                "supportPlayerIds": [support_ids[0]],
                "opponentContextPlayerIds": relevant_opponents,
                "highlightPlayerIds": highlighted,
                "anchors": anchors,
                "guardWindows": guards,
                "coreStartFrame": core_start,
                "coreEndFrame": core_end,
                "pressurePlayerId": (
                    pressure_player_id if theme == "pressureSupport" else None
                ),
                "ownershipVisibility": ownership,
                "minimumObservedOpponents": minimum_observed_opponents,
                "metrics": theme_metrics,
                "visibleParticipantCount": len(highlighted),
                "recognisableFocus": is_famous(actor),
            }
            candidate["score"] = candidate_score(candidate)
            candidates.append(candidate)
    return candidates, rejected


def validate_candidates(
    candidates: list[dict],
    match_id: int,
    validator=None,
) -> tuple[list[dict], list[dict]]:
    validated: list[dict] = []
    rejected = []
    by_theme = {
        theme: sorted(
            (candidate for candidate in candidates if candidate["theme"] == theme),
            key=lambda candidate: (
                -candidate["score"],
                candidate["anchorFrame"],
                candidate["focusId"],
            ),
        )
        for theme in THEMES
    }
    cursors = {theme: 0 for theme in THEMES}
    seen = set()
    while len(validated) < MAX_VALIDATED_CANDIDATES_PER_MATCH:
        progressed = False
        for theme in THEMES:
            values = by_theme[theme]
            candidate = None
            while cursors[theme] < len(values):
                value = values[cursors[theme]]
                cursors[theme] += 1
                key = (value["anchorFrame"], value["focusId"], value["theme"])
                if key in seen:
                    continue
                seen.add(key)
                candidate = value
                break
            if candidate is None:
                continue
            progressed = True
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
            validated.append(candidate)
            if len(validated) >= MAX_VALIDATED_CANDIDATES_PER_MATCH:
                break
        if not progressed:
            break
    rejected_keys = {
        (item["sourceFrame"], item["owner"], item["reason"]) for item in rejected
    }
    for candidate in candidates:
        key = (candidate["anchorFrame"], candidate["focusId"], candidate["theme"])
        rejection_key = (
            candidate["anchorFrame"],
            candidate["focusId"],
            "ranked-below-validated-source-safe-pool",
        )
        if key in seen or rejection_key in rejected_keys:
            continue
        seen.add(key)
        rejected.append(
            {
                "matchId": match_id,
                "sourceFrame": candidate["anchorFrame"],
                "owner": candidate["focusId"],
                "reason": "ranked-below-validated-source-safe-pool",
            }
        )
    return validated, rejected


def choose_catalog_candidates(candidates: list[dict]) -> tuple[list[dict], list[dict]]:
    ordered = sorted(
        candidates,
        key=lambda candidate: (
            -candidate["score"],
            THEMES.index(candidate["theme"]),
            candidate["matchId"],
            candidate["anchorFrame"],
        ),
    )
    selected: list[dict] = []
    rejected = []

    def overlaps(candidate: dict) -> bool:
        return any(
            candidate["matchId"] == item["matchId"]
            and not (
                candidate["endFrame"] + MIN_ANCHOR_SEPARATION <= item["startFrame"]
                or candidate["startFrame"] >= item["endFrame"] + MIN_ANCHOR_SEPARATION
            )
            for item in selected
        )

    def add(candidate: dict) -> bool:
        if candidate in selected or overlaps(candidate):
            return False
        selected.append(candidate)
        return True

    # Candidate score units are theme-specific, so compare scores only within
    # a theme. Round-robin curation keeps a high-metre switch score from
    # crowding out independently safe support or combination lessons. Match
    # and player diversity are preferences applied after every safety gate.
    while len(selected) < MAX_CATALOG_SCENES:
        progressed = False
        for theme in THEMES:
            options = [
                item
                for item in ordered
                if item["theme"] == theme
                and item not in selected
                and not overlaps(item)
            ]
            if not options:
                continue
            option = min(
                options,
                key=lambda item: (
                    any(value["matchId"] == item["matchId"] for value in selected),
                    any(
                        value["matchId"] == item["matchId"]
                        and value["focusId"] == item["focusId"]
                        for value in selected
                    ),
                    -item["score"],
                    item["matchId"],
                    item["anchorFrame"],
                ),
            )
            if len(selected) >= MAX_CATALOG_SCENES:
                break
            progressed = add(option) or progressed
        if not progressed:
            break
    missing_themes = set(THEMES) - {item["theme"] for item in selected}
    if missing_themes:
        raise ValueError(
            "Pinned source has no non-overlapping safe lesson for: "
            + ", ".join(sorted(missing_themes))
        )
    for candidate in ordered:
        if candidate in selected:
            continue
        rejected.append(
            {
                "matchId": candidate["matchId"],
                "sourceFrame": candidate["anchorFrame"],
                "owner": candidate["focusId"],
                "reason": (
                    "overlaps-a-higher-ranked-selected-lesson"
                    if overlaps(candidate)
                    else "catalogue-curation-limit"
                ),
            }
        )
    if len({item["matchId"] for item in selected}) < 3 or len(
        {(item["matchId"], item["focusId"]) for item in selected}
    ) < 3:
        raise ValueError("Safe catalogue lacks representative match/player diversity")
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
            for value in point or (None, None):
                if value is None:
                    row.append(MISSING_COORDINATE)
                    continue
                quantized = round(value * 100)
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
                raw_frames[local][player_index * 2] = MISSING_COORDINATE
                raw_frames[local][player_index * 2 + 1] = MISSING_COORDINATE
    identified_counts = [sum(flags) for flags in visibility]
    if min(identified_counts) == 0:
        raise ValueError("Motion-continuity filter left an empty source frame")

    def directly_visible(player_id: int, source_start: int, source_end: int) -> bool:
        player_index = index_by_id.get(player_id)
        if player_index is None:
            return False
        return all(
            visibility[source_frame - start][player_index]
            for source_frame in range(source_start, source_end + 1)
        )

    for guard in candidate["guardWindows"]:
        if not directly_visible(
            guard["playerId"],
            guard["sourceStartFrame"],
            guard["sourceEndFrame"],
        ):
            raise ValueError("Guarded actor failed the motion-continuity filter")
    for player_id in candidate["corePlayerIds"]:
        if not directly_visible(
            player_id,
            candidate["coreStartFrame"],
            candidate["coreEndFrame"],
        ):
            raise ValueError("Core actor failed the motion-continuity filter")
    for player_id in (
        candidate["supportPlayerIds"] + candidate["opponentContextPlayerIds"]
    ):
        if not directly_visible(
            player_id,
            candidate["coreStartFrame"],
            candidate["coreEndFrame"],
        ):
            raise ValueError("Context actor failed the motion-continuity filter")
    for segment in candidate["ownershipVisibility"]["segments"]:
        if not directly_visible(
            segment["playerId"],
            segment["sourceStartFrame"],
            segment["sourceEndFrame"],
        ):
            raise ValueError("Owned-ball actor failed the motion-continuity filter")

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
    player_speed = max_speed(raw_frames, visibility, len(players))
    if player_speed > 15:
        raise ValueError(f"Implausible player continuity ({player_speed:.2f} m/s)")
    ball_speed = validate_ball_speed(raw_frames)

    # Preserve exact metric scale while allowing genuine positions just beyond
    # the touchline or goal line to remain visible.  The view is fixed for the
    # entire scene and includes a small marker/tail safety margin.
    half_length = match["pitch_length"] / 2
    half_width = match["pitch_width"] / 2
    observed_x = [
        abs(row[player_index * 2] / 100)
        for row, flags in zip(raw_frames, visibility)
        for player_index in range(len(players))
        if flags[player_index]
    ]
    observed_y = [
        abs(row[player_index * 2 + 1] / 100)
        for row, flags in zip(raw_frames, visibility)
        for player_index in range(len(players))
        if flags[player_index]
    ]
    maximum_x = max([abs(row[-3] / 100) for row in raw_frames] + observed_x)
    maximum_y = max([abs(row[-2] / 100) for row in raw_frames] + observed_y)
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
        "displayFrames": [],
        "displayProvenance": [],
        "missingPlayerCoordinate": MISSING_COORDINATE,
        "sourcePossessionOwners": [
            source["possession"].get("trackable_object")
            if source["possession"].get("trackable_object") in metadata
            else None
            for source in interval
        ],
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
            "role": anchor["role"],
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
                "role": anchor["role"],
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
        "coreStart": round((candidate["coreStartFrame"] - start) / FPS, 3),
        "coreEnd": round((candidate["coreEndFrame"] - start) / FPS, 3),
        "corePlayerIds": candidate["corePlayerIds"],
        "supportPlayerIds": candidate["supportPlayerIds"],
        "opponentContextPlayerIds": candidate["opponentContextPlayerIds"],
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
        "maxBallSpeedMetersPerSecond": round(ball_speed, 4),
        "maxQuantizationErrorMeters": round(quantization_error, 8),
        "motionContinuityExcludedObservations": continuity_exclusions,
        "directionProof": direction_proof,
        "anchors": local_anchors,
        "guardWindows": [
            {
                **guard,
                "localStart": round((guard["sourceStartFrame"] - start) / FPS, 3),
                "localEnd": round((guard["sourceEndFrame"] - start) / FPS, 3),
                "coverage": 1.0,
            }
            for guard in candidate["guardWindows"]
        ],
        "coreVisibility": {
            "sourceStartFrame": candidate["coreStartFrame"],
            "sourceEndFrame": candidate["coreEndFrame"],
            "expectedFrames": candidate["coreEndFrame"] - candidate["coreStartFrame"] + 1,
            "playerIds": candidate["corePlayerIds"],
            "coverageByPlayer": {
                str(player_id): 1.0 for player_id in candidate["corePlayerIds"]
            },
        },
        "supportContext": {
            "playerIds": candidate["supportPlayerIds"],
            "continuousSourceStartFrame": candidate["coreStartFrame"],
            "continuousSourceEndFrame": candidate["coreEndFrame"],
        },
        "opponentContext": {
            "playerIds": candidate["opponentContextPlayerIds"],
            "continuousSourceStartFrame": candidate["coreStartFrame"],
            "continuousSourceEndFrame": candidate["coreEndFrame"],
            "minimumDirectlyObservedOpponentsPerFrame": candidate["minimumObservedOpponents"],
        },
        "ownedBallVisibility": candidate["ownershipVisibility"],
        "metricChecks": metric_checks,
        "metrics": candidate["metrics"],
        "displayEvidence": {
            "reconstructionIncluded": False,
            "missingSamplesRendered": False,
            "missingCoordinateSentinel": MISSING_COORDINATE,
        },
    }
    return data, {"entry": entry, "proof": proof}


def interleave(entries: list[dict]) -> list[dict]:
    remaining = sorted(
        entries,
        key=lambda entry: (
            THEMES.index(entry["theme"]),
            entry["matchId"],
            entry["startFrame"],
        ),
    )
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
        for entry in remaining
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
    remaining = [entry for entry in remaining if entry is not opener]
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
            next_index = 0
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
    theme_counts = collections.Counter(item["theme"] for item in catalog["scenes"])
    if set(theme_counts) != set(THEMES):
        raise ValueError("Spatial catalog does not cover the three approved themes")
    if max(theme_counts.values()) - min(theme_counts.values()) > 1:
        raise ValueError("Spatial catalog curation is not balanced across safe themes")
    if len({item["matchId"] for item in catalog["scenes"]}) < 3:
        raise ValueError("Spatial catalog lacks representative match diversity")
    if len({item["focusPlayerName"] for item in catalog["scenes"]}) < 3:
        raise ValueError("Spatial catalog lacks representative player diversity")
    records = {item["id"]: item for item in proof["scenes"]}
    for scene in catalog["scenes"]:
        path = REPO / scene["asset"]
        record = records[scene["id"]]
        if not path.is_file() or digest(path) != record["assetSha256"]:
            raise ValueError(f"Derived scene hash mismatch: {scene['id']}")
        data = read_json(path)
        players = data["players"]
        player_index = {item["id"]: index for index, item in enumerate(players)}
        frames = data["frames"]
        visibility = data["visibility"]
        owners = data.get("sourcePossessionOwners")
        if (
            len(frames) != len(visibility)
            or not isinstance(owners, list)
            or len(owners) != len(frames)
            or data.get("displayFrames")
            or data.get("displayProvenance")
            or data.get("missingPlayerCoordinate") != MISSING_COORDINATE
        ):
            raise ValueError(f"Invalid shipped visibility model: {scene['id']}")
        if not MIN_CLIP_FRAMES / FPS <= scene["duration"] <= MAX_CLIP_FRAMES / FPS:
            raise ValueError(f"Invalid source duration: {scene['id']}")
        if scene["evidenceStart"] < MIN_CONTEXT_FRAMES / FPS or (
            scene["duration"] - scene["evidenceEnd"] < MIN_CONTEXT_FRAMES / FPS
        ):
            raise ValueError(f"Insufficient source context: {scene['id']}")
        for frame_index, row in enumerate(frames):
            for index in range(len(players)):
                pair = row[index * 2 : index * 2 + 2]
                if visibility[frame_index][index]:
                    if MISSING_COORDINATE in pair:
                        raise ValueError(f"Observed player uses missing sentinel: {scene['id']}")
                elif pair != [MISSING_COORDINATE, MISSING_COORDINATE]:
                    raise ValueError(f"Missing player was assigned a position: {scene['id']}")

        anchors = scene.get("evidenceAnchors", [])
        anchor_ball_points = []
        for anchor in anchors:
            local = round(anchor["time"] * FPS)
            index = player_index.get(anchor["playerId"])
            if index is None:
                raise ValueError(f"Unknown evidence actor: {scene['id']}")
            guard_start = local - ACTOR_GUARD_FRAMES
            guard_end = local + ACTOR_GUARD_FRAMES
            if guard_start < 0 or guard_end >= len(frames) or not all(
                visibility[value][index] for value in range(guard_start, guard_end + 1)
            ):
                raise ValueError(f"Unobserved guarded actor: {scene['id']}")
            player_xy = (frames[local][index * 2] / 100, frames[local][index * 2 + 1] / 100)
            ball_xy = (frames[local][-3] / 100, frames[local][-2] / 100)
            anchor_ball_points.append(ball_xy)
            if math.dist(player_xy, ball_xy) > 3.5:
                raise ValueError(f"Distant ownership anchor: {scene['id']}")
            if owners[local] != anchor["playerId"]:
                raise ValueError(f"Anchor is not the source-labelled owner: {scene['id']}")

        theme = scene["theme"]
        if theme == "lateralSwitch":
            if len(anchor_ball_points) < 2 or abs(
                anchor_ball_points[1][1] - anchor_ball_points[0][1]
            ) < 22:
                raise ValueError(f"Unproven lateral-switch geometry: {scene['id']}")
        elif theme == "pressureSupport":
            first_anchor = anchors[0]
            second_anchor = anchors[1]
            first_local = round(first_anchor["time"] * FPS)
            second_local = round(second_anchor["time"] * FPS)
            actor_index = player_index[first_anchor["playerId"]]
            actor_home = players[actor_index]["home"]
            actor_point = (
                frames[first_local][actor_index * 2] / 100,
                frames[first_local][actor_index * 2 + 1] / 100,
            )
            opponent_distances = []
            for index, player in enumerate(players):
                if player["home"] == actor_home or not visibility[first_local][index]:
                    continue
                opponent_distances.append(
                    math.dist(
                        actor_point,
                        (
                            frames[first_local][index * 2] / 100,
                            frames[first_local][index * 2 + 1] / 100,
                        ),
                    )
                )
            forward = (
                frames[second_local][-3] - frames[first_local][-3]
            ) / 100 * scene["attackDirection"]
            connection_meters = math.dist(
                anchor_ball_points[0], anchor_ball_points[1]
            )
            if (
                not opponent_distances
                or min(opponent_distances) > 6
                or forward >= 10
                or connection_meters < MIN_PRESSURE_CONNECTION_METERS
            ):
                raise ValueError(f"Unproven pressure-support geometry: {scene['id']}")
        elif theme == "combination":
            if len(anchors) < 3 or anchors[-1]["time"] - anchors[0]["time"] > 8:
                raise ValueError(f"Unproven combination sequence: {scene['id']}")
            if any(
                math.dist(first, second) < MIN_COMBINATION_LEG_METERS
                for first, second in zip(anchor_ball_points, anchor_ball_points[1:])
            ):
                raise ValueError(f"Combination leg below teaching threshold: {scene['id']}")
        else:
            raise ValueError(f"Unapproved spatial theme: {scene['id']}")

        core_start = round(scene["coreStart"] * FPS)
        core_end = round(scene["coreEnd"] * FPS)
        for field in ("corePlayerIds", "supportPlayerIds", "opponentContextPlayerIds"):
            ids = scene.get(field, [])
            if not ids:
                raise ValueError(f"Missing {field}: {scene['id']}")
            for player_id in ids:
                index = player_index.get(player_id)
                if index is None or not all(
                    visibility[value][index] for value in range(core_start, core_end + 1)
                ):
                    raise ValueError(f"Unobserved {field}: {scene['id']}")

        checked_owned_frames = 0
        cursor = 0
        while cursor < len(owners):
            owner = owners[cursor]
            if owner not in player_index:
                cursor += 1
                continue
            segment_end = cursor
            while segment_end + 1 < len(owners) and owners[segment_end + 1] == owner:
                segment_end += 1
            if segment_end - cursor + 1 >= 3:
                checked_owned_frames += segment_end - cursor + 1
                index = player_index[owner]
                if not all(visibility[value][index] for value in range(cursor, segment_end + 1)):
                    raise ValueError(f"Ghost source-labelled owner: {scene['id']}")
            cursor = segment_end + 1
        if checked_owned_frames == 0:
            raise ValueError(f"No meaningful owned-ball segment: {scene['id']}")
        if max_speed(frames, visibility, len(players)) > 15:
            raise ValueError(f"Implausible player continuity: {scene['id']}")
        validate_ball_speed(frames)
        anchors = scene.get("evidenceAnchors", [])
        highlights = scene.get("highlightPlayerIds", [])
        if (
            len(anchors) < 2
            or len(highlights) < 4
            or len(highlights) > 6
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

    safe_built = []
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

        validated, validation_rejected = validate_candidates(
            candidates, match_id, validate_and_build
        )
        all_rejected.extend(rejected)
        all_rejected.extend(validation_rejected)
        for candidate in validated:
            key = (candidate["anchorFrame"], candidate["focusId"], candidate["theme"])
            data, built = built_candidates[key]
            safe_built.append((candidate, data, built))
        print(
            f"validated {len(validated)} of {len(candidates)} candidates for "
            f"{match['home_team']['short_name']} v {match['away_team']['short_name']}",
            flush=True,
        )
        del frames, observations

    selected, curation_rejected = choose_catalog_candidates(
        [candidate for candidate, _, _ in safe_built]
    )
    all_rejected.extend(curation_rejected)
    selected_ids = {id(candidate) for candidate in selected}
    scenes = []
    proofs = []
    for candidate, data, built in safe_built:
        if id(candidate) not in selected_ids:
            continue
        path = SCENES / f"{data['scene']['id']}.json"
        save(path, data)
        built["entry"]["assetSha256"] = digest(path)
        built["proof"]["asset"] = path.relative_to(REPO).as_posix()
        built["proof"]["assetBytes"] = path.stat().st_size
        built["proof"]["assetSha256"] = digest(path)
        scenes.append(built["entry"])
        proofs.append(built["proof"])
    scenes = interleave(scenes)
    catalog = {
        "version": 1,
        "provider": "SkillCorner Open Data",
        "license": "MIT",
        "sourceCommit": HISTORICAL_COMMIT,
        "sourceUrl": HISTORICAL_SOURCE_ROOT,
        "matchCount": 9,
        "selection": {
            "fps": FPS,
            "preferredClipSeconds": PREFERRED_CLIP_FRAMES / FPS,
            "minimumClipSeconds": MIN_CLIP_FRAMES / FPS,
            "maximumClipSeconds": MAX_CLIP_FRAMES / FPS,
            "minimumContextBeforeAndAfterSeconds": MIN_CONTEXT_FRAMES / FPS,
            "actorGuardSeconds": ACTOR_GUARD_FRAMES / FPS,
            "minimumAnchorSeparationSeconds": MIN_ANCHOR_SEPARATION / FPS,
            "catalogueLimit": MAX_CATALOG_SCENES,
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
        REPO / "assets/video_learning",
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
                "a tracking-derived change between distinct same-team source-labelled "
                "owners; every departure/arrival actor is directly observed for a "
                "0.5 s guard on each side and the ball remains continuously recorded"
            ),
            "claims": (
                "tracking-derived geometric descriptions only; no pass, goal, "
                "optimal-choice, body, foot, scan, or ball-height event is inferred"
            ),
            "themeThresholds": {
                "lateralSwitch": "at least 22 m lateral change",
                "pressureSupport": (
                    "nearest observed opposing player at the ownership anchor is "
                    "at most 6 m away, the recorded ball connection is at least "
                    "4 m, and the connection is less than 10 m "
                    "forward; no approach or closing speed is inferred"
                ),
                "combination": (
                    "three directly observed same-team ownership segments within "
                    "8 s with at least 5 m of recorded ball displacement on each "
                    "leg; the first and third may be the same player in a return link"
                ),
            },
            "visibilityGuarantees": (
                "core, one off-ball support actor, and relevant opponents stay directly "
                "observed through the central sequence after impossible-speed filtering; "
                "meaningful source-labelled owner runs are visible throughout"
            ),
            "missingData": (
                "missing coordinates use a non-pitch sentinel plus visibility=0; no "
                "(0,0), carry-forward, interpolation, or display reconstruction is shipped"
            ),
        },
        "counts": {
            "validatedSafeCandidates": len(safe_built),
            "validatedSafeThemes": collections.Counter(
                candidate["theme"] for candidate, _, _ in safe_built
            ),
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
