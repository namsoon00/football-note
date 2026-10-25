# Scan Pass actual-match replay provenance

## Source and license

The default Scan Pass replay is derived from the MIT-licensed
[SkillCorner Open Data](https://github.com/SkillCorner/opendata) repository at
commit `4340d274572876239c154c90bc507a9b3250a656`. It uses match 1925299,
Brisbane Roar v Perth Glory, 2024-12-21.

The pinned upstream filenames, byte sizes and SHA-256 digests are recorded in
`assets/scan_pass_replay/source-manifest.json`. The upstream MIT license is
bundled at `assets/scan_pass_replay/LICENSE` and registered with Flutter's
license registry by the replay screen.

## Alignment and filtering

The body-pose JSONL uses frames 124487 through 124795 at 25 fps. Match event and
playing-time frames use 10 fps. The preprocessor multiplies the latter by 2.5
before aligning them and never treats `phase406` in the raw filename as a
semantic phase index; the overlapping CSV phase index is 397.

The 22-player roster is selected once at the first aligned tracking frame using
each player's `playing_time.total.start_frame` and `end_frame`. The raw sample
has 32 player records; filtering removes 10 bench or substituted ghost records.
The resulting order is stored unchanged in
the compact asset.

Coordinates and ball height are rounded to centimetres by the preprocessor and
converted to metres exactly once by `RealMatchReplayData`. The 309 samples
include both endpoints. Playback interpolates adjacent frames without changing
either endpoint. Pose XY values are centimetres relative to the tracked player;
pose Z is absolute centimetres. A pose is interpolated only when both adjacent
12.5 fps snapshots exist.

## Rebuild

1. Check out the pinned SkillCorner revision and copy these files into one local
   input directory: `sample_1925299_phase406.jsonl.gz`, `1925299_match.json`,
   `1925299_phases_of_play.csv`, and `1925299_dynamic_events.csv`.
2. Verify each input against `assets/scan_pass_replay/source-manifest.json`.
3. From the repository root run:

   ```sh
   python3 tool/scan_pass_replay/prepare_replay.py /path/to/pinned-inputs
   ```

4. Confirm the compact output is 509710 bytes with SHA-256
   `cf73a11f566d974f3dada609e0d16111e6896dc522d88c08c257eb7332efaa71`
   and re-run the replay domain tests.

`assets/scan_pass_replay/data-proof.json` records the expected counts, event
identity and numeric quantization bound. The phase CSV is retained in the input
manifest as provenance even though frame alignment, not its phase label, drives
the replay clip.
