# Scan Pass source-grounded spatial library

The measured 2D spatial library is the primary Scan Pass experience. It is a
pitch-first viewer of broadcast-visible SkillCorner tracking, not a diagram
invented from video. The separate 12-passage official-video viewer remains
available through one More-menu route and keeps its existing history and
progress storage. Its authored qualitative diagrams are not measured replays;
see [`SCAN_PASS_VIDEO_LEARNING.md`](SCAN_PASS_VIDEO_LEARNING.md).

## Shipped catalogue

`education-catalog.json` is the only default runtime entry. It contains 70
evidence-reviewed passages from 10 matches: 25 accepted scenes from eight of
the nine pinned 2019/20 matches and 45 newly exported scenes from both requested
2024/25 A-League matches. The importer audited all 72 scenes in the original
catalogue and rejected 47 that did not demonstrate a supported before/after
learning outcome. The original `catalog.json`, every original scene and the
original source/quality/preservation files remain byte-identical as archive
and test fixtures; they are not a second menu or a fallback.

There is no scene-count, fame, team or player quota. The current evidence
produces 9 receiving-lane, 11 pressure-outlet, 34 distinct-third-player and 16
opposite-side-space lessons. A later source revision can change those counts
only by passing the same deterministic measurements.

`ScanPassSpatialLibraryScreen` opens directly on one top-down metric pitch.
Orientation stays fixed for the passage. Precomputed overlapping four-second
source windows ease the camera between local action envelopes: every frame
keeps the recorded ball, current source-labelled owner, blue teaching focus and
actors named by the current question/observation visible. The camera never
fills gaps or treats an
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

The compact title contains match identity. A single short teaching card is
placed in a currently clear part of the pitch without a connector line.
It has one learning-objective title and one contextual question or observation.
Before the action it asks what to watch; during the action it names the
observed actor and movement; after it reports the measured consequence and,
only after its source time is reached, the next source-labelled connection.
Placement rejects overlap with observed actors, the ball and the reached ball
trace. Gold identifies only a directly observed, nearby source ownership
record; blue identifies the reviewed learning actor independently, including
when that actor is off the ball. Player names stay beside their own badges and
may be suppressed when no safe nearby slot is available. Action words are never
combined with those names. A source-grounded action instead uses one neutral,
high-contrast 32–40 px athlete category illustration attached to the observed
actor. A separate black-and-white football marks the relevant generic contact:
carry stays at the foot, direction change adds a modest curved route, and a
header stays at the forehead. Receive moves the ball in and holds it at contact;
one-touch moves it in and out through exactly one contact. That motion is a
non-looping function of the current source time, so pause freezes it and forward
or backward seek reproduces it; reduced-motion settings show the static contact
and route. The illustration and gesture do not reconstruct measured body/foot
pose, contact, ball height or direction.

The target remains at least 44 px. Its clamped viewport rectangle and the visible
illustration use the same recorded geometry, so edge clamping cannot shift the
picture away from the target. Placement is kept stable for the same event and
viewport, remains inside the surrounding pitch viewport, and tries 40 px, then
36 px and finally 32 px while rejecting players, the recorded ball, names and
teaching overlays. If no attached slot within 24 px exists, no distant symbol is
invented. Tapping or keyboard-activating the illustration pauses the replay and
shows the localized actor and action name; hover and focus expose the same
meaning. Scene changes, seeking and action changes dismiss that explanation,
while the existing bottom play action resumes from the same source time.
Recorded traces never preview a future path and clear after the
evidenced action. Seeking always uses source time and pauses safely. The primary
play action resumes at the current source time in the selected mode. Guided
mode runs the remaining setup at 1x, the central evidence window at 0.5x and
the remaining aftermath at 1x; wall-clock duration is the remaining source-time
span divided by that rate, so one source second takes two wall-clock seconds at
0.5x. The source-speed More action restarts at zero and keeps 1x selected across
later pause, seek and resume actions. The guided-replay action restarts at zero
and restores guided mode, while each newly loaded scene defaults to guided
mode. Replaying after the true end restarts at zero in the selected mode.
Previous, play/pause, scene list and next remain in the bottom controls.

The scene list reports the learning goal, actual clip duration, match, teaching
actor, date and 2019/20 or 2024/25 season. One search field matches Korean and
English player/team aliases, the four learning terms and season/year as well as
accent, case and spacing variants. Its attacking/play-team and player selectors
combine with search and the four objective chips; the player selector contains
only named lesson participants, never an entire match roster. The filtered
count, clear-search action and one-step reset remain in the same scrollable
bottom sheet.
Source information and guided replay are discreet More-menu actions. There are
no tabs, scores, joystick controls, mandatory quiz or separate start screen.

## Source and license

The only positional provider is MIT-licensed SkillCorner Open Data. Historical
scenes stay pinned to commit
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

The Bayern–Dortmund match remains in the byte-identical 72-scene archive and
the complete audit, but no scene from it passes the stricter v2 education
rules. The v2 mixed-source `matchCount` therefore derives to ten represented
matches rather than counting that audit-only source.

Recent scenes are pinned independently to commit
`4340d274572876239c154c90bc507a9b3250a656`:

- Brisbane Roar FC v Perth Glory Football Club, 2024-12-21 (1925299)
- Sydney Football Club v Adelaide United Football Club, 2025-02-01 (1996435)

For those matches the importer reads the full original
`tracking_extrapolated.jsonl`, but only a player record with
`is_detected == true` is an observation. Extrapolated and carry-forward player
coordinates never enter visibility, teaching evidence or rendering. Ball XY is
available only when the source ball flag is detected; every exported recent
clip has a continuous detected-ball interval. Source period, timestamp, active
roster and original shirt numbers are preserved. Export is XY-only.

`assets/scan_pass_spatial/source-manifest.json` pins every raw URL, size,
SHA-256 and Git blob. The raw files are not bundled.
`assets/scan_pass_spatial/LICENSE` is the exact upstream MIT license. The
library includes no video and does not use StatsBomb data.

`education-source-manifest.json` pins URL, bytes and SHA-256 for both complete
tracking files and their match/event/phase companions, including the Git LFS
media URLs. Its archive-preservation section also records the immutable
metadata hashes and derives all 115 pre-existing asset hashes from the tracked
v1 catalogue and preservation manifest. `education-proof.json` records all archive and recent accept/reject
decisions. Teacher references shape the four lesson definitions; they are not
provenance for match coordinates and are not described as actual coach review.

## Source-grounded on-pitch actions

Only the 45 recent scenes have Dynamic Events metadata. Their catalogue entries
preserve each relevant original `player_possession` event ID, actor ID, source
and display name, period, source start/end frame, start/end type, nullable
`one_touch`, `carry`, `is_header` and `hand_pass` values, matching flags and the
pinned CSV path/commit. Incoming `is_previous_pass_matched` and outgoing
`is_pass_reception_matched` remain separate metadata rather than being treated
as interchangeable boundaries. The 25 historical XY-only lessons have an
empty action list; no header or contact metadata is inferred for them.

The current pinned clips contain 375 relevant possession records. After the
fail-closed source and geometry gates, they provide 45 carry onsets, four
observed direction-change onsets, eight source headers, 266 matched non-one-touch
pass receptions and 56 non-header one-touch pass endings. These are source
evidence counts, not a scene quota. Exact source-contact observation leaves six
displayable headers, 261 receives and 55 one-touch passes. One header actor is
not observed at its source instant and another header has a 3.574 m actor-ball
gap, so neither produces an on-pitch symbol. When display windows overlap, the most recently reached
action wins; `header` wins a same-frame tie with `one-touch pass`. A brief event
keeps its symbol available for 1.2–1.6 seconds after its source instant, but it
never appears before that frame. Pause, forward seek and backward seek resolve the same symbol
from source time without changing playback mode.

Vocabulary is deliberately narrower than common coaching shorthand:

- **Carry:** provider `carry=true` plus matched boundaries and uninterrupted
  observed control. Player and ball stay directly visible, the tracking owner
  is the same actor, their separation is at most 3.5 m, and observed
  displacement reaches 2.0 m. This does not claim a defender was dribbled.
- **Direction change:** only inside a qualified carry, after the already
  reached XY trajectory has two 1.5 m legs and bends by at least 55 degrees. It
  describes trajectory, not body rotation, a turn skill, feint or pose. Future
  samples cannot start it early.
- **Receive:** `start_type=pass_reception`, matched possession start, and
  `is_previous_pass_matched=true` for the incoming pass, excluding known
  one-touch, header and hand actions. The separate
  `is_pass_reception_matched` field describes reception of this player's own
  outgoing pass and does not qualify the incoming receive label.
  A nullable `one_touch` remains unknown rather than becoming a confident
  one-touch technique claim. This does not claim a foot/chest trap or technique.
- **Header:** source `is_header=true`; an unsupported hand-pass combination is
  rejected. No jump, ball height or body contact is rendered.
- **One-touch pass:** source `one_touch=true`, an actual `end_type=pass`, a
  matched end and no header/hand-pass conflict.

At runtime a header/receive symbol additionally requires the named actor and
ball to be directly observed within 3.5 m at the original start frame; a
one-touch pass applies the same gate at the original end frame. Later actor
reappearance cannot repair missing contact evidence, and ownership is not
required for these instant actions. Carry/direction evidence requires the
observed ball throughout the source-controlled interval. The active actor is
included in camera and name priority, while player numbers, gold confirmed
ownership and blue teaching
focus keep their independent meanings. The action symbol receives no invented
ring or leader line. Its athlete pose, contact point and short ball route are
generic category illustrations driven only by the already active action and its
source-time phase; they do not alter the recorded field ball or claim a measured
foot, body heading, ball height, contact pose or travel direction. The neutral
action badge stays separate from both rings and from player-name labels.
Ordinary names remain within 18 pixels of their own actor badge and never
acquire action words.

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

The four education claims are deliberately narrow and use the same named,
continuously observed opponent for each before/after comparison:

- **Receiving lane:** the receiver moves at least 0.75 m during the second
  before release. The same defender must project onto the finite
  passer-to-receiver segment both before and at release. Visible angular
  separation must start at no more than 25 degrees and the defender must start
  within 3 m of the pass line. Angular separation must increase by at least 3
  degrees and perpendicular line clearance by at least 0.5 m. Receiver movement
  alone must contribute at least 1 degree and 0.25 m when the final passer and
  defender are held fixed. Stationary, far-lateral, beyond-receiver,
  passer/defender-only or post-release-only movement fails.
- **Pressure outlet:** an observed defender is within 4 m of the passer; the
  receiver gains at least 1 m of clearance; and a later directly observed,
  source-labelled same-team connection exists without intervening opposing or
  reversed ownership.
- **Third player:** A, B and C are distinct. C moves at least 0.6 m before B
  receives, moves at least 1 m overall in a continuing direction, and gains
  at least 1.5 m forward or 1 m of defender clearance. A→B→C ownership must be
  uninterrupted; A→B→A and an opponent touch followed by recovery are rejected.
- **Opposite-side space:** the lateral connection spans at least 22 m and the
  receiving player gains at least 1 m of visible defender clearance. Distance
  by itself is insufficient.

Coordinates are stored to centimetres (maximum point error 0.005 m). Runtime
measurement comparisons use a 0.0011 stored-unit tolerance; threshold checks
allow at most the 0.01 m two-point quantization bound, not a broad pass margin.

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
python3 tool/scan_pass_replay/prepare_spatial_education.py \
  --raw-dir .tmp/spatial-education/recent-source
python3 tool/scan_pass_replay/prepare_spatial_education.py --verify-assets
```

The recent raw directory contains the basenames listed in the committed
`education-source-manifest.json`. Generation verifies each exact pinned path,
URL, byte count and SHA-256 from that manifest; `--source-manifest` can select
an equivalent audited manifest explicitly. Asset-only verification needs no
raw download and no `.tmp` file, and is part of `scripts/verify.sh` for CI. If
the pinned raw Dynamic Events CSVs are present, the same verifier also checks
their bytes/hashes and reproduces every committed action record from them.

Generation scans the raw files deterministically, records all rejection
reasons, and emits only the selected source-safe catalogue. The immutable v1
archive proof records 198 source-safe candidates before non-overlap and archive
curation: 56 switches, 73 support-under-pressure candidates and 69
combinations. That archive proof selected 72 scenes and records 10,715 rejected
or ranked-out candidates. Those 198/72 figures describe only the preserved
archive proof; the current default v2 education catalogue contains 70 scenes
(25 accepted archive passages plus 45 recent passages).
Rejections include short/discontinuous context, absent guard/core/ownership
actors, missing opponent or support context, post-filter actor loss and
implausible ball continuity.

Both `--verify-assets` commands must pass. The education verifier first checks
that all 115 pre-existing catalogue/source/quality/scene/legacy bytes still
match hashes derived from the immutable tracked manifests. It does not trust
manifest booleans: it reloads every selected replay,
recomputes each objective and metric, checks source ownership and direct
visibility, recomputes carry/direction geometry, checks typed nullable flags and
action provenance, checks the strict mixed-source allowlist and derives
`matchCount` from represented matches.

The historical `--verify-assets` does not trust summary booleans. It reloads each shipped
source frame and visibility mask, then recomputes duration and context bounds,
guard coverage, continuous core/support/opponent coverage, owned-ball actor
visibility, ball continuity, speeds, hashes, match identity and the archived
source-safety guarantees.

The runtime keeps domain geometry and validation independent of Flutter. The
application service validates catalogue-to-scene identity, and the asset
repository verifies each scene SHA-256 before parsing.

## Assets and limits

- `education-catalog.json`: default v2 mixed-source index with learning actors,
  exact source frames, measurements, reference URLs, scene hashes and typed
  recent Dynamic Events action evidence.
- `catalog.json`: byte-identical v1 archive/test fixture; not runtime fallback.
- `scenes/*.json`: 10 fps source frames, sparse visibility, source ownership
  labels and metadata reused without modification by accepted historical lessons.
- `education_scenes/*.json`: 10 fps 2024/25 direct-detection-only XY clips;
  no pose, carry-forward, extrapolated actor or reconstructed display layer.
- `education-proof.json` and `education-source-manifest.json`: all decisions,
  thresholds, measurements and pinned recent input hashes.
- `quality-proof.json`: thresholds, precise guard/core windows, actor coverage,
  speed/continuity results and every candidate rejection.
- `legacy-asset-preservation.json`: byte hashes for the retained official-video,
  25-scene replay and authored-sample assets.

This remains broadcast-visible XY coverage rather than complete full-pitch
measurement. Real visibility gaps outside the teaching evidence are preserved,
ball height is unavailable for every education scene and is not taught, and absence
from the feed is not evidence of open space. Kit symbols add no body pose or
orientation inference. Those source limits are surfaced rather than repaired
by the camera, symbols or copy.
