# Scan Pass famous-match spatial library

## Public experience

`ScanPassGameScreen` opens `ScanPassSpatialLibraryScreen`. It is one pitch-first
viewer with 108 distinct passages from nine familiar European matches in the
SkillCorner 2019/20 historical sample. Each match contributes 12 non-overlapping
passages. The catalog currently covers 53 focal players and eight measured
themes: lateral switch, forward connection, nearby-defender support, carry then
connect, wide to inside, multi-player combination, turnover, and recovery.

The pitch uses a stable metric full-field view for the entire passage. All 22
active players remain displayed, with hollow/slashed markers for reconstructed
off-camera positions. Only directly observed positions make player tails or
support speed, defender distance, lane, space, and learning cues. Only the
recorded ball trace up to the current source time is drawn; the endpoint region
appears only after its directly observed ownership anchor. Normal playback is
source time at 1x.
The optional focused replay uses 0.5x only between the evidence anchors, then
returns to source speed.

The single More menu contains the searchable player/team/theme scene picker,
source information, the retained 25-scene replay reference, and the separately
authored first-touch sample. Neither older A-League matches nor the fictional
sample appears in the default catalog.

Theme search uses the current EN/KO/JA labels, and the principal star aliases
(including 메시, 호날두, 음바페, メッシ, and ロナウド) are localized search terms;
official source names remain unchanged in catalog and provenance data. In the
nearby-defender theme, a warm ring, short source-only tail, and gap line identify
the currently observed nearest opponent only while the actor is directly
observed near the recorded ball. The text states the current distance and never
turns static proximity into an approach-speed claim.

## Source and license

The only data source for this library is MIT-licensed SkillCorner Open Data at
commit `1ed50b775f93075c2a6d00d0d795f13b7b89709e`. The included matches are:

- Manchester City v Liverpool (4039)
- Dortmund v Bayern München (3749)
- Juventus v Inter (3518)
- Real Madrid v FC Barcelona (3442)
- FC Barcelona v Real Madrid (2841)
- Liverpool v Manchester City (2440)
- Bayern München v Dortmund (2417)
- Paris v Marseille (2269)
- Inter v Juventus (2068)

`assets/scan_pass_spatial/source-manifest.json` records the upstream raw URL,
byte size, SHA-256, and Git blob SHA for every input. The raw match files are not
bundled. `assets/scan_pass_spatial/LICENSE` is the exact upstream MIT license.
The new library neither includes nor proxies StatsBomb data.

## Reproducible selection

Generation scans each raw match once to precompute possession, identity, and
direct-observation indices. A connection is a change between two distinct,
directly observed possession owners with continuous recorded ball XY. A
same-team connection is retained only when the source possession-team label is
consistent. This does not promote the transition to a provider-labelled pass.
Every claimed ownership anchor also requires the observed player to be within
3.5 m of the observed ball. Raw ball motion above 50 m/s is rejected rather
than repaired or replaced with synthetic movement.

Candidates must provide 10–20 seconds of continuous ball XY around the action,
an unchanged active 22-player roster, visible evidence anchors, a familiar focal
player, and a theme-specific spatial threshold. Selection then applies a
three-scenes-per-player and three-scenes-per-theme per-match cap, prevents clip
overlap, and interleaves matches deterministically after a context-rich Lionel
Messi opener. The generator records every rejection reason. Starting-goalkeeper
period medians establish attack direction.

Run from the repository root:

```sh
python3 tool/scan_pass_replay/prepare_spatial_library.py \
  .tmp/spatial-library/source \
  --audit .tmp/spatial-library/source-audit.json
python3 tool/scan_pass_replay/prepare_spatial_library.py --verify-assets
```

The generator reuses the established historical importer's source checks and
display reconstruction. Metadata identity and kit fields come from match
metadata; `trackable_object` is the tracking join key, not the metadata player
ID. Adjacent impossible identity jumps are removed from usable motion evidence
and counted in the proof. Selected source and reconstructed display speeds must
both remain at or below 15 m/s. Ordered evidence anchors retain valid return
sequences such as A→B→A, while the separate highlighted-player set is distinct.

Runtime loading follows the app's domain boundaries: a domain repository
contract defines catalog/scene access, the application service validates every
catalog-to-scene pairing, and the infrastructure asset repository checks each
scene SHA-256 before parsing. Flutter asset APIs do not enter the domain layer.

## Assets and proof

- `catalog.json`: lazy-load index, source clocks/frames, player and theme fields,
  ordered evidence anchors, distinct highlights, metrics, and asset hashes.
- `scenes/*.json`: compact 10 fps source/display clips using the existing honest
  sparse-source and provenance-marked display schema.
- `quality-proof.json`: selection definition and thresholds, scene clocks,
  direction proof, visible cue anchors, speed/quantization checks,
  reconstruction coverage, and rejected candidates.
- `legacy-asset-preservation.json`: byte-for-byte hashes for every pre-existing
  `scan_pass_replay` and `scan_pass_authored` asset.

Educational annotations are geometric interpretations of recorded tracking.
They do not establish intent, a globally best play, coach approval, or learning
transfer. This library intentionally renders only the pitch plane (XY), even
where historical raw observations contain height. No ball-height claim, exact
body/foot contact, or scan behavior is invented.
