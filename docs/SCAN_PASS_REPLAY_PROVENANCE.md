# Scan Pass actual-match scene provenance

## Shipped scope, source and license

The simple viewer ships 25 continuous observational scenes derived from the
MIT-licensed [SkillCorner Open Data](https://github.com/SkillCorner/opendata).
It keeps the original 20 A-League payloads unchanged and places five historical
Premier League/LaLiga scenes first in the mixed catalog.

The original 20 scenes use revision
`4340d274572876239c154c90bc507a9b3250a656` and these matches:

- 1925299: Brisbane Roar v Perth Glory, 2024-12-21.
- 1996435: Sydney FC v Adelaide United, 2025-02-01.

The five historical scenes use revision
`1ed50b775f93075c2a6d00d0d795f13b7b89709e`:

| Scene | Match | Period and source clock | Inclusive source frames |
| --- | --- | --- | --- |
| De Bruyne connects wide under pressure | Manchester City v Liverpool, 2020-07-02 | P1 5:31.40–5:40.00 | 3756–3842 |
| Salah starts a right-side recycle | Manchester City v Liverpool, 2020-07-02 | P1 30:48.80–30:59.00 | 18930–19032 |
| Messi carries on the right, then finds Semedo | Real Madrid v FC Barcelona, 2020-03-01 | P1 40:35.30–40:46.30 | 25268–25378 |
| Kroos recycles through Casemiro | Real Madrid v FC Barcelona, 2020-03-01 | P1 38:18.20–38:28.90 | 23897–24004 |
| Vinícius carries inside, then links with Kroos | Real Madrid v FC Barcelona, 2020-03-01 | P2 74:45.50–74:57.50 | 55945–56065 |

The bundled MIT license remains at `assets/scan_pass_replay/LICENSE` and is
registered in Flutter's license registry. Pinned source paths, raw URLs, byte
sizes and SHA-256 hashes are recorded separately in
`source-manifest.json` and `historical-source-manifest.json`. Catalog entries
carry their own source revision and URL; the source sheet therefore opens the
pinned match directory for the selected scene rather than downloading the full raw tracking file. Exact raw URLs remain in the manifests.

The eight catalog categories are editorial observation themes, not
certifications that a player chose an optimal action. The viewer contains no
linked or embedded match video in this release.

## Historical selection and annotation

`tool/scan_pass_replay/historical_scenes.json` is the explicit curation file.
It records each interval, period, inclusive source frames, focal player,
possession evidence, authored step frames, coverage decision and annotation
rationale. The source is a 10 fps JSON array whose clock field is `time`.
Tracking identities are joined with `player.trackable_object`, not the separate
player metadata `id`.

The historical source has no dynamic event annotations. Receive, carry, pass,
pressure, support and recorded-end steps are conservative derived labels based
on source possession runs, continuous ball/player trajectories and proximity.
They are disclosed as derived in the app and proof file; they are not presented
as provider-labelled passes, shots or goals. Every historical scene ends at its
real selected frame with outcome `end`. A later success, goal or optimal choice
is never inferred.

The five intervals were retained only after checking source continuity, focal
identity, ball XY coverage, local player coverage and identity-continuity speed.
The proof records the 22-player active roster, starting-goalkeeper
attack-direction evidence, possession runs, per-step rationale, source-visible
counts, ball Z counts, source/display maximum speeds, centimetre-quantization
error and every player's reconstructed spans and anchor frames. Recorded jersey
and number colors and squad numbers are used as metadata; simplified kits are
not licensed logos or complete historical uniform reconstructions.

## Broadcast-visible coverage and missing data

Historical tracking is broadcast-visible coverage, not measured full-22
tracking. Every payload therefore keeps two deliberately separate layers:

- `frames` plus `visibility` are the recorded source layer. Hidden XY remains
  zero/null, source sampling never bridges a missing endpoint, and all coaching
  classifications, trails, nearest-defender checks and authored-step validation
  use only this layer.
- `displayFrames` plus `displayProvenance` are a dense display layer for the 22
  players active at the selected match clock. Provenance `0` means the display
  XY is byte-for-byte the centimetre-quantized observation; `1` means only the
  displayed location was reconstructed. The renderer keeps the same opaque
  kit, number and body, adds a small hollow ground ring, and drives gait from
  this continuous display trajectory.

Internal gaps use linear interpolation between same-player observations.
Leading and trailing gaps use same-period observations within 600 source
frames (60 seconds): two anchors interpolate, while one anchor uses a
7 m/s-capped continuation whose velocity decays to a hold over 1.2 seconds. If
a player has no observation in that contextual window, the nearest
same-period anchor is held and recorded as `nearest-period-anchor-hold`. A
role-grid position is the documented last resort only when the player has no
same-period observation at all. All inferred XY is pitch-bounded. These rules
are deterministic display reconstruction, not guessed ground truth.

An unlabelled home/away observation contributes only when its `track_id` has
one team-consistent identity mapping in the same period. Ambiguous or
conflicting anonymous observations are ignored. They never create an invented
player: the shipped historical roster is taken from metadata `start_time` and
`end_time`, contains exactly 11 identified players per team, and is unchanged
through each clip.

Ball XY must be present in every selected source frame. Ball height is marked
available only if every frame also has a finite source Z. If any Z sample is
missing, the derived scene is explicitly XY-only, all stored Z values are zero,
and the UI states that no ball height is inferred.

## Current-data selection and alignment

`tool/scan_pass_replay/scenes.json` records the original A-League intervals,
exact tracking frames, focal possession event and curated off-ball run event.
Those current-data clips use the provider's complete/extrapolated positions;
missing required positions are rejected rather than filled by this app. The
extractor keeps player XY and ball XYZ, quantized to centimetres. Match metadata
supplies kit colors, squad numbers, pitch dimensions and half-specific attack
direction.

Provider event intervals can start before or end after a clip. Their original
relative times are retained rather than clamped to invent release/reception
moments. Only events completed within a clip determine a recorded outcome. An
overlap, underlap or run-behind label in those scenes is backed by its recorded
dynamic-event subtype.

When a receiver is still off-camera at release, a pass step shows the recorded ball path without inventing a recipient position. The later reception identifies that player once observed.

For both sources, steps less than 0.55 seconds apart are combined by cue
specificity so they do not create duplicate clicks. The final playback stop is
always the true selected duration, while the last source-derived cue can start
earlier without adding a no-op click.

## Motion and viewer fidelity

Only the original `transition-wing` clip supplies measured/estimated pose
samples. The other 24 scenes use procedural limbs driven by the displayed
speed/direction and distance-integrated gait. Those limbs are not recordings of
foot contacts, body orientation, scanning, first foot, torso motion or technique.

Source rendering uses bounded smoothing only between two visible adjacent
samples. Historical display rendering smooths adjacent dense display samples
without changing their frame endpoints. The recorded ball path stays linearly
sampled and is never snapped to a player's foot or an estimated player. Source
timing is preserved. The public viewer uses one stable overview camera per clip
that includes all display trajectories, the ball, the full pitch and body/header
margins.

Supported receive, pass and carry badges can open an optional source-faithful
detail sheet. Its interval and one fixed close camera are calculated from the
focal actor's continuous recorded visibility plus recorded ball positions only;
`displayFrames`, reconstructed players and procedural joints cannot establish
eligibility, bounds, camera evidence, contact, technique, target, turn, or
caption. Receive/pass windows aim for 0.5 seconds before and 1.2 seconds after,
stop at the next authored action boundary, and trim at any actor visibility gap.
Carry windows aim from 0.5 seconds before toward the recorded end/next action
and are capped at 3.5 seconds. Too-short continuous intervals are declined.
Ball lift affects camera safety only when complete recorded Z exists.

Detail playback begins automatically at a fixed 0.65x, stops at its exact
window end, and has one play/pause/replay control. Opening first pauses the main
viewer at its exact source time; dismissing or navigating back neither advances
nor resumes it. Backgrounding pauses detail playback. The in-picture phase cue
comes from the selected detail action and window, never from a stale main cue or
later action.

The badge follows the current source action even between teaching stops. Detail
geometry honors the fixed 12 m by 9 m minimum crop, and the map uses the stable
all-player overview bounds so out-of-pitch tracked positions remain visible.
The in-picture path key distinguishes recorded ball and observed actor traces.

Only `transition-wing` can enlarge the existing source pose samples. Every
other scene visibly says its path is enlarged while its pose remains simplified;
no procedural foot swing is represented as the named player's actual movement.
The close-up never claims a first-contact foot, foot surface, kick, feint, touch
count or optimal technique. XY-only scenes explicitly state that height is
unavailable and never render invented lift.

A separate synchronized context region in the detail sheet uses the display
layer to keep all 22 players visible, marks the selected actor and fixed camera
rectangle, and retains hollow reconstructed-position markers. That map supplies
team context only; it does not change source-only detail evidence.

The main viewer remains the simple one-action experience: picture, compact
title, one relevant cue and one play/pause/continue action. The catalog and
source disclosure remain in the overflow menu; there is no scrubber, speed
selector, chapter strip, manual camera, permanent mini-map or mode switch. The
context map and slow control exist only inside the optional action-detail sheet.

This is an observational reconstruction, not a validated best-play model or
evidence of improved football judgement.

### Original body-pose interval

The original JSONL uses source frames 124487–124795 at 25 fps. Event and
playing-time frames are 10 fps and align by multiplying them by 2.5. The
filename `phase406` is not used as a semantic phase index; the overlapping
phase CSV index is 397.

The active 22-player roster excludes ten bench/substituted ghost records in the
32-record raw sample. There are 309 position samples, including endpoints, and
155 pose snapshots. Pose XY is relative to the tracked player; pose Z is
absolute. Interpolation requires both adjacent pose snapshots; missing poses
are not invented in the close-up.

## Deterministic rebuild

For the original current-data assets:

1. Collect the files pinned under `files` in `source-manifest.json` into one
   input directory, using their basenames.
2. Retrieve tracking payloads through Git LFS or the pinned GitHub media URLs.
   The ordinary raw GitHub URL is a 133-byte pointer. Save the payloads as
   `1925299_tracking.jsonl` and `1996435_tracking.jsonl`.
3. Run:

   ```sh
   python3 tool/scan_pass_replay/prepare_replay.py /path/to/current-inputs
   python3 tool/scan_pass_replay/prepare_catalog.py /path/to/current-inputs
   ```

`prepare_catalog.py` rebuilds the 20 current scenes and, when the pinned
historical catalog is present, prepends it instead of erasing it.

For the historical assets, place the six files at the paths listed in
`historical-source-manifest.json`, rooted under one input directory, then run:

```sh
python3 tool/scan_pass_replay/prepare_historical.py /path/to/historical-inputs
```

The importer verifies every raw size/hash before parsing and reproduces the
five payloads, historical catalog/proof, 25-entry mixed catalog and mixed proof.
The proof includes reconstruction policy, contextual/period anchor frames and
per-player inferred coverage. The roughly 125 MB of raw tracking stays outside
committed assets.

The original `replay-data.json` remains 509710 bytes with SHA-256
`cf73a11f566d974f3dada609e0d16111e6896dc522d88c08c257eb7332efaa71`.
`catalog-proof.json` and `data-proof.json` retain the existing current-data
evidence. `historical-catalog-proof.json` and `mixed-catalog-proof.json` add the
historical and cross-revision evidence without changing the original scene
payloads.
