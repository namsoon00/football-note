# Scan Pass source-grounded spatial library

The measured 2D spatial library is the primary Scan Pass experience. It is a
pitch-first viewer of broadcast-visible SkillCorner tracking, not a diagram
invented from video. The separate 12-passage official-video viewer remains
available through one More-menu route and keeps its existing history and
progress storage. Its authored qualitative diagrams are not measured replays;
see [`SCAN_PASS_VIDEO_LEARNING.md`](SCAN_PASS_VIDEO_LEARNING.md).

## Shipped catalogue

The reviewed catalogue contains 72 passages from all nine pinned 2019/20
matches, with 62 focal players. Durations are 20.7–30.0 seconds. The three
source-backed themes are:

- 24 spatial switches (`lateralSwitch`);
- 24 support-under-pressure passages (`pressureSupport`); and
- 24 observed combinations (`combination`).

These counts result from the stronger evidence gates; they are not per-match or
per-player quotas. The previous 108-scene catalogue was reassessed and is not
exposed as a supposedly safe fallback.

`ScanPassSpatialLibraryScreen` opens directly on one top-down metric pitch.
Orientation stays fixed for the passage. Precomputed overlapping four-second
source windows ease the camera between local action envelopes: every frame
keeps the recorded ball, current source-labelled owner and current relevant
actors visible, while the guarded teaching sequence also keeps its core,
support and opponent actors together. The camera never fills gaps or treats an
unobserved actor as empty space. Numbered flat kit symbols have a separate
ground anchor, and the ball remains a separate visible object. The symbols are
shirts and shorts, not bodies, and do not claim real orientation, feet,
contact posture or scanning direction.

## Kit presentation

Outfield markers for the nine pinned fixture IDs use small, presentation-only
2019/20-inspired kit families: Barcelona checkerboard, Juventus black/white
halves with a narrow pink centre, Inter blue/black stripes, Paris a navy
white-red-white centre band, Liverpool deep red pinstripes, Manchester City
sky blue with purple trim and white shorts, Real Madrid off-white with gold
trim, Dortmund yellow with black sleeves and shorts, Bayern red tonal panels,
and Marseille white with sky-blue trim. These restrained flat symbols aid team
recognition at the actual 26/32 px marker sizes; they have no logos or sponsors
and are not claims about the exact match-specific garment worn in every clip.

Resolution is deliberately scoped to the exact fixture ID and expected home
and away names listed below. A future fixture, a team-name mismatch, or any
goalkeeper uses the scene's plain source shirt and number colours. The source
has no goalkeeper-kit fields, so an unverified outfield pattern is never
assigned to a keeper. The minimap uses the same resolved representative main
colour as the pitch. Original source player numbers remain on the shirt with a
contrasting halo, while gold confirmed-ownership and blue teaching-focus rings
retain their existing independent meanings.

The season references used for the simplified visual treatment are the clubs'
primary material for [Barcelona's checkerboard](https://www.fcbarcelona.com/en/football/first-team/news/1234297/new-fc-barcelona-jersey-expresses-the-clubs-passion-for-the-city/featured),
[Juventus's halves and pink centre](https://www.juventus.com/en/news/articles/juventus-unveil-2019-20-home-kit),
[Manchester City's sky-blue/purple palette](https://www.mancity.com/news/club-news/picture-special/2019/july/man-city-puma-2019-20-home-kit-gallery),
[Liverpool's 2019/20 kit](https://www.liverpoolfc.com/news/announcements/346207-pictures-photos-liverpool-home-kit-2019-20),
and [Real Madrid's 2019/20 kit](https://static.realmadrid.com/StaticFiles/RealMadridResponsive/especiales/en/shirts-and-kits/liga_34.html).
The other club families are representative palettes, not source-backed exact
garment claims. Raw pinned match metadata provides only shirt and number
colours, includes older catalogue entries, and does not describe patterns.

The compact title contains match identity. A single short teaching cue is
placed in a currently clear part of the pitch without a connector line.
Placement rejects overlap with observed actors, the ball and the reached ball
trace. Gold identifies only a directly observed, nearby source ownership
record; blue identifies the current teaching focus independently. Player names
stay beside their own badges and may be suppressed when no safe nearby slot is
available. Recorded traces never preview a future path and clear after the
evidenced action. Normal play and seeking remain at source time and 1x. Guided
replay starts with the complete setup at 1x, uses 0.5x only across the central
evidence window, then returns to 1x for the aftermath. Previous, play/pause,
scene list and next remain in the bottom controls.

The scene list reports the actual clip duration, match, focal player and theme.
One search field matches Korean and English player/team aliases as well as
accent, case and spacing variants. Its attacking/play-team and player selectors
combine with search and theme filters; the player selector contains only focal
players and directly evidenced connection participants, never an entire match
roster. The filtered count, clear-search action and one-step reset remain in the
same scrollable bottom sheet.
Source information and guided replay are discreet More-menu actions. There are
no tabs, scores, joystick controls, mandatory quiz or separate start screen.

## Source and license

The only positional source is MIT-licensed SkillCorner Open Data at commit
`1ed50b775f93075c2a6d00d0d795f13b7b89709e`:

- Manchester City v Liverpool (4039)
- Dortmund v Bayern München (3749)
- Juventus v Inter (3518)
- Real Madrid v FC Barcelona (3442)
- FC Barcelona v Real Madrid (2841)
- Liverpool v Manchester City (2440)
- Bayern München v Dortmund (2417)
- Paris v Marseille (2269)
- Inter v Juventus (2068)

`assets/scan_pass_spatial/source-manifest.json` pins every raw URL, size,
SHA-256 and Git blob. The raw files are not bundled.
`assets/scan_pass_spatial/LICENSE` is the exact upstream MIT license. The
library includes no video and does not use StatsBomb data.

## Selection and evidence gates

The importer prefers a 30-second source interval and permits only 20–40
seconds. It requires at least four seconds of real setup before the central
connection and four seconds of aftermath after it. It never pads a clip,
fabricates a trajectory or slows the stored timeline to meet a duration.

A candidate connection starts from a source-labelled ownership change between
distinct same-team actors. That label is only a search lead; it is not promoted
to an authoritative provider pass event. Every claimed departure and arrival
actor must be directly observed with a 0.5-second guard on both sides of the
anchor and within 3.5 m of the recorded ball at the anchor. Core actors must
remain directly observed across the whole teaching sequence. At least one
off-ball support actor and relevant opposing context must also remain directly
observed. Pressure copy is allowed only when this observed opposing context is
present.

All source-labelled ownership runs across the full clip are inspected. A
meaningful controlled/touch run is rejected when its named owner is absent.
The checks are repeated after impossible-speed filtering, so filtering cannot
silently remove a previously visible core, guard, owner or context actor. The
same gates also retain the period, active roster, source timing, ball
continuity, metadata jersey numbers and match kit metadata.

Missing players keep `visibility=0` and a non-pitch sentinel coordinate. No
missing coordinate is replaced with `(0,0)`, carry-forward or interpolation.
The spatial assets contain no display reconstruction. Hidden actors do not
become evidence, and an unobserved area is never described as empty space.

The three theme claims are deliberately narrow:

- a spatial switch has at least 22 m of observed lateral ball change;
- support under pressure has a directly observed opponent within 6 m at the
  ownership anchor, at least 4 m of recorded ball travel, and less than 10 m
  of forward connection; and
- an observed combination has three directly observed same-team ownership
  segments within eight seconds, with at least 5 m of recorded ball travel on
  each leg. The first and third may be the same player in a return link. The
  shipped 24 contain nine A→B→A returns and 15 A→B→C links.

They do not assert intent, a globally best play, a goal, a precise foot/body
action, expert validation or learning transfer.

## Reproducible build and verification

From the repository root, after placing the pinned files at the audited source
path:

```sh
python3 tool/scan_pass_replay/prepare_spatial_library.py \
  .tmp/spatial-lessons/source \
  --audit .tmp/spatial-lessons/source-audit.json
python3 tool/scan_pass_replay/prepare_spatial_library.py --verify-assets
```

Generation scans the raw files deterministically, records all rejection
reasons, and emits only the selected source-safe catalogue. The shipped proof
currently records 198 source-safe candidates before non-overlap and catalogue
curation: 56 switches, 73 support-under-pressure candidates and 69
combinations. It ships 72 selected scenes and records 10,715 rejected or
ranked-out candidates.
Rejections include short/discontinuous context, absent guard/core/ownership
actors, missing opponent or support context, post-filter actor loss and
implausible ball continuity.

`--verify-assets` does not trust summary booleans. It reloads each shipped
source frame and visibility mask, then recomputes duration and context bounds,
guard coverage, continuous core/support/opponent coverage, owned-ball actor
visibility, ball continuity, speeds, hashes, match identity and the three
representative theme guarantees.

The runtime keeps domain geometry and validation independent of Flutter. The
application service validates catalogue-to-scene identity, and the asset
repository verifies each scene SHA-256 before parsing.

## Assets and limits

- `catalog.json`: lazy-load index with clocks, frames, match/player/theme data,
  evidence bounds, actor roles, metrics and scene hashes.
- `scenes/*.json`: 10 fps source frames, sparse visibility, source ownership
  labels and metadata; no reconstructed display layer.
- `quality-proof.json`: thresholds, precise guard/core windows, actor coverage,
  speed/continuity results and every candidate rejection.
- `legacy-asset-preservation.json`: byte hashes for the retained official-video,
  25-scene replay and authored-sample assets.

This remains broadcast-visible XY coverage rather than complete full-pitch
measurement. Real visibility gaps outside the teaching evidence are preserved,
ball height is unavailable for all 72 scenes and is not taught, and absence
from the feed is not evidence of open space. Kit symbols add no body pose or
orientation inference. Those source limits are surfaced rather than repaired
by the camera, symbols or copy.
