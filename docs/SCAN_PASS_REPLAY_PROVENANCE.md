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
The proof records roster mapping, starting-goalkeeper attack-direction evidence,
possession runs, per-step rationale, visible-player counts, ball Z counts,
maximum speeds and centimetre-quantization error. Recorded jersey and number
colors and squad numbers are used as metadata; simplified kits are not licensed
logos or complete historical uniform reconstructions.

## Broadcast-visible coverage and missing data

Historical tracking is broadcast-visible coverage, not an extrapolated full-22
view. Each derived frame has an explicit player visibility row. A hidden player
has no rendered point, trail, motion state, nearest-opponent contribution or
camera anchor. Sampling never interpolates across a missing endpoint, and gait
integration does not bridge a tracking gap.

An unlabelled home/away team observation is retained as an anonymous track when
its `track_id` cannot be resolved safely. It has no invented name or shirt
number. A track id is resolved to a known player only when the interval has one
team-consistent mapping; ambiguous or conflicting identity observations are
not guessed. The five shipped intervals happen to resolve all retained team
tracks, but the schema and importer preserve anonymous visible opponents for
other auditable intervals.

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
samples. The other 24 scenes use procedural limbs driven by observed
speed/direction and distance-integrated gait. Those limbs are not recordings of
foot contacts, body orientation, scanning, first foot, torso motion or technique.

Player rendering may use bounded smoothing only between two visible adjacent
samples. The recorded ball path stays linearly sampled and is never snapped to
a player's foot. Source timing is preserved. The automatic camera ignores
missing player samples and eases between authored context and close views so a
hidden player cannot pull the frame toward a fabricated coordinate.

The public viewer remains the simple one-action experience: picture, compact
title, one relevant cue and one play/pause/continue action. The catalog and
source disclosure remain in the overflow menu; there is no scrubber, speed
selector, chapter strip, manual camera, mini-map or expanded mode.

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
The roughly 125 MB of raw tracking stays outside committed assets.

The original `replay-data.json` remains 509710 bytes with SHA-256
`cf73a11f566d974f3dada609e0d16111e6896dc522d88c08c257eb7332efaa71`.
`catalog-proof.json` and `data-proof.json` retain the existing current-data
evidence. `historical-catalog-proof.json` and `mixed-catalog-proof.json` add the
historical and cross-revision evidence without changing the original scene
payloads.
