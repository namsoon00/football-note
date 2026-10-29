# Scan Pass video learning

The primary Scan Pass entry is a video-first viewer for six reviewed,
goal-ending passages from four publicly available videos published by official
competition or club channels. The app embeds the official YouTube player; it
does not contain, download, proxy, or rehost broadcast video or thumbnails.

## Sources and reviewed boundaries

The committed catalogue is
[`assets/video_learning/catalog.json`](../assets/video_learning/catalog.json).
Its boundaries were supplied by the parent review manifest dated 2026-10-30.
The review used official publisher storyboard stills and official match reports,
not downloaded video files. A boundary is an absolute time in its YouTube
source, not a match-clock value.

| Passage | Official publisher video | Clip | Goal conclusion | Storyboard tolerance |
| --- | --- | ---: | ---: | ---: |
| Real Madrid–Barcelona, Messi | [FC Barcelona full match](https://www.youtube.com/watch?v=3j_daNHio4o) | 1:40:45–1:41:13 | 1:41:10 | about ±10 s |
| Barcelona–Albacete, Messi/Ronaldinho | [FC Barcelona](https://www.youtube.com/watch?v=j9ihJMqZGD0) | 0:26–0:39 | 0:38 | about ±1 s |
| Juventus–Inter, Dybala | [Serie A](https://www.youtube.com/watch?v=6K1nqPcLkZ4) | 1:56–2:12 | 2:10 | about ±2 s |
| Inter–Juventus, Higuaín | [Serie A](https://www.youtube.com/watch?v=EXrtdXC65ik) | 3:06–3:20 | 3:18 | about ±2 s |
| Inter–Juventus, Dybala | [Serie A](https://www.youtube.com/watch?v=EXrtdXC65ik) | 0:10–0:22 | 0:18 | about ±2 s |
| Juventus–Inter, Ramsey | [Serie A](https://www.youtube.com/watch?v=6K1nqPcLkZ4) | 1:10–1:24 | 1:18 | about ±2 s |

The 2017 full-match source has coarse ten-second storyboard sampling. Its
three phases are broad explanation windows, not frame-accurate events. The
closing sequence was cross-checked against the official LaLiga shorter edition.
The 2005 clip deliberately excludes the earlier offside attempt and includes
only the valid second attack. Only Ronaldinho (10) and Messi (30) are drawn for
that passage; unverified defensive identities are not invented. The other sources have one- or two-second storyboard
intervals. These tolerances describe source review precision only; they never
reduce the playback required to earn watched status.

## What the two visual systems mean

The video companion diagrams are manually authored, qualitative spatial
illustrations. They show two to seven source-identifiable actors, current
focus numbers, match-era kit patterns, ball/pass/run/carry/shot directions, and
useful space for the current broad phase. Coordinates describe a local
attacking half: the presentation mirrors the authored attack-right layout when
the reviewed video attacks left and draws the goal and penalty area at that
end. They are not measured coordinates, calibrated distances, continuous
trajectories, or a claim of exact synchronization. They describe what to
observe without claiming player intent, expert approval, or one globally best
action.

The secondary **Measured 2D spatial library** remains available from the
bottom settings sheet. Its 108 passages use broadcast-visible XY source data
and retain their original footprints, visibility gaps, camera safety, and
source limitations, as documented in
[`SCAN_PASS_SPATIAL_LIBRARY.md`](SCAN_PASS_SPATIAL_LIBRARY.md). The two systems
must not be presented as equivalent evidence.

## Playback and persistence

On web, `web/football_learning_video.js` uses the public YouTube IFrame Player
API. It cues only the reviewed range, clamps seeks, reports real player time and
state, applies supported playback rates, and stops part mode at a phase
boundary. A stable Flutter-owned platform-view wrapper contains a replaceable
player mount so scene changes and retries do not reuse a detached iframe host.
Whole mode continues to the reviewed end. Browser autoplay policy,
publisher restrictions, regional availability, deleted videos, and network
errors can still prevent playback. The UI then offers retry and direct official
video/report/channel links; direct video links include the selected in-clip
timestamp. Opening a link or loading an iframe does not count as watching.

Native builds intentionally show the official-link fallback instead of
simulating playback. No YouTube credential is required.

Progress is stored through `OptionRepository`. Coverage accumulates only from
small, positive deltas while the official player reports real playback. Seeks,
loading, background jumps, and malformed/overlapping saved ranges do not add
coverage. A scene becomes watched only after at least 80% unique clip coverage
and real playback reaches the reviewed goal-conclusion time (within the
universal 250 ms telemetry precision). Resume time, current scene, team/status
filters, supported speed preference, and auto-next are also persisted. Writes
are serialized, and a storage failure is surfaced without claiming that state
was saved.

The in-picture spatial-guide disclosure stays above the diagram so that it is
visible before scrolling on phones. Match metadata appears once, and observation
instructions wrap in full at enlarged text sizes. Video surfaces keep the
source's 16:9 ratio where space allows and always retain a minimum 200 px height.
The bottom controls use a proper chevron icon rather than a font-dependent glyph.
YouTube's supported `controls=0` and `disablekb=1` parameters keep playback and
bounded seeking in the app's bottom controls; branding and the official-source
link remain available. Native builds explicitly offer that timestamped source
link, without presenting an unsupported inline player as a retryable failure.

## Runtime source acceptance

On 2026-10-30 an actual Chrome/YouTube API cue probe accepted all four shipped
source IDs and returned playback rates including 0.5, 0.75 and 1. The initially
selected LaLiga highlights (`fVufY4SCoOk`) and City highlights (`i3Uai46WLjc`)
returned embed error150 despite their watch-page metadata indicating embedding
availability. They are excluded from the default catalogue. The Messi winner
uses the club's accepted official full-match source; the second passage now
teaches Ronaldinho's lifted return and Messi's off-ball run. The catalogue has
six passages from four videos and five clubs. Cue acceptance does not guarantee
availability in every future region or successful video decoding. No restriction
is bypassed; official timestamped-link fallback remains available.

A YouTube iframe's `onReady` event alone no longer enables app playback controls.
The adapter waits for the actual media `CUED` state and reads supported rates
then, refreshing them on confirmed playback. This prevents a rejected iframe
from being reported as a playable learning video.
