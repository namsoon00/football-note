# Scan Pass actual-match scene provenance

## Source and license

The 20-scene library is derived from the MIT-licensed
[SkillCorner Open Data](https://github.com/SkillCorner/opendata) at commit
`4340d274572876239c154c90bc507a9b3250a656`, from two matches:

- 1925299: Brisbane Roar v Perth Glory, 2024-12-21.
- 1996435: Sydney FC v Adelaide United, 2025-02-01.

The eight observation themes are transition, build-up, pressure, switching
play, penetration, combinations, wide attacks and turnovers. These are
editorial observation prompts, not certifications that a player chose an
optimal action. Continuing attacks and losses are both included. The original
pose replay remains first; the other 19 scenes use distinct recorded intervals.

Pinned filenames, byte sizes and SHA-256 digests are in
`assets/scan_pass_replay/source-manifest.json`. The MIT license is bundled at
`assets/scan_pass_replay/LICENSE` and registered in Flutter's license registry.

## Selection and alignment

`tool/scan_pass_replay/scenes.json` records each interval's match, exact tracking
start/end frames, focal possession event and any curated off-ball run event.
The additional clips use 10 fps source tracking, including extrapolated
off-camera positions. Every bundled frame has finite coordinates for all 22
active players and the ball. Missing positions are rejected, not filled by a
simulation; rosters must remain active throughout the interval.

The extractor keeps original player XY and ball XYZ, quantized to centimetres.
Match metadata supplies shirt/number colours, squad numbers, pitch dimensions
and half-specific attack direction. Camera bounds include nearby supporting
players and defensive shape throughout each sequence, not only the ball.

Event intervals can start before or end after a clip. Their original relative
times are retained; they are not clamped to invent release/reception moments.
A pass is marked at its recorded possession end; reception is marked from a
recorded receiving possession. Only events completed within the clip can
determine the recorded outcome. A few focal moments become coaching chapters;
continuous playback includes the surrounding actions too.

An overlap, underlap or run-behind label is backed by its actual dynamic-event
subtype. We do not infer head scans, decoy intentions, the touching foot or why
a defender moved. Successful recorded passes are not automatically best
decisions, and a turnover alone does not prove the choice was wrong.

## Motion fidelity

Nineteen additional clips contain no pose samples. Their limbs illustrate
tracked speed/direction with a distance-integrated gait; they are not recordings
of foot contacts. Kit design, shorts and skin tones remain simplified. Only the
original clip supports the measured/estimated pose close-up.

Raw sampling interpolates source endpoints without changing them. Player
rendering can use bounded smooth interpolation between the same samples; the
ball remains linearly sampled from recorded XYZ. Source timing is preserved
at normal/half speed and with reduced-motion accessibility enabled.

This is an observational reconstruction, not a validated best-play model or
evidence of measured improvements in football judgement.

### Original body-pose interval

The original JSONL uses source frames 124487–124795 at 25 fps. Event and
playing-time frames are 10 fps and align by multiplying them by 2.5.
The filename `phase406` is not used as a semantic phase index; the overlapping
phase CSV index is 397.

The active 22-player roster excludes ten bench/substituted ghost records in
the 32-record raw sample. There are 309 position samples, including endpoints,
and 155 pose snapshots. Pose XY is relative to the tracked player; pose Z is
absolute. Interpolation requires both adjacent pose snapshots; missing poses
are not invented in the close-up.

## Rebuild

1. Collect the pinned source files listed under `files` in the manifest into
   one input directory, using their basenames.
2. Retrieve actual tracking payloads through Git LFS or pinned GitHub media URLs.
   The raw GitHub URL returns a 133-byte pointer, not tracking data. Save the
   payloads as `1925299_tracking.jsonl` and `1996435_tracking.jsonl`.
3. From the repository root run:

   ```sh
   python3 tool/scan_pass_replay/prepare_replay.py /path/to/pinned-inputs
   python3 tool/scan_pass_replay/prepare_catalog.py /path/to/pinned-inputs
   ```

4. The original `replay-data.json` must remain 509710 bytes with SHA-256
   `cf73a11f566d974f3dada609e0d16111e6896dc522d88c08c257eb7332efaa71`.
   The catalog builder verifies source byte counts/hashes before extraction
   and updates derived hashes in the manifest. Re-run the replay domain tests.

`assets/scan_pass_replay/catalog-proof.json` records per-scene frame ranges,
sample counts, pose availability, quantization error, focal event IDs,
detection counts and derived hashes. `data-proof.json` retains the original
pose interval proof. Phase CSVs remain in the source manifest for provenance;
frame alignment, rather than phase filenames, determines each clip.
