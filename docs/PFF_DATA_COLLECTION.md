# PFF / Gradient Sports data collection

Checked on 2026-11-09 (KST). This record describes both the acquired release
slice and its app catalogue coverage.

## Full release

Gradient Sports, formerly PFF FC, advertises tracking, event, roster and match metadata for all **64 matches of the 2022 men's World Cup**:

- [Current enhanced release](https://www.gradientsports.com/blog/enhanced-2022-world-cup-dataset)
- [Legacy enhanced release](https://www.blog.fc.pff.com/blog/enhanced-2022-world-cup-dataset)
- [Original release](https://www.blog.fc.pff.com/blog/pff-fc-release-2022-world-cup-data)

The legacy page embeds Klaviyo form `R4ZPQU`. Its public configuration links to
the genuine [PFF FC public release folder](https://drive.google.com/drive/folders/1_a_q1e9CXeEPJ3GdCv_3-rNO3gPqacfa).
The connected folder lists 64 match files in each of Metadata, Rosters,
Tracking Data and Event Data. The Event Data listing has 67 entries when its
specification and extra folder entries are included; Tracking Data has 65 when
its specification is included. No email, form submission, newsletter signup,
account creation, paid agreement or message was used.

**Full match files acquired: 12 files for 3 matches, plus 2 specifications.
Full PFF matches imported into the app: 3, represented by 4 derived clips.**

The local ignored source contains complete metadata, roster, event and tracking
files for Argentina–France (`10517`), Brazil–South Korea (`10507`) and South
Korea–Portugal (`3857`). Exact Google Drive file IDs, public URLs, byte lengths
and SHA-256 hashes are committed in
`assets/scan_pass_spatial/worldcup-source-manifest.json`. The release does not
state a separate data licence in the acquired material, so the app and docs do
not describe it as MIT, open data or public domain. Raw match files remain
ignored and are not bundled.

The earlier “access form unavailable” conclusion was stale because it did not
inspect the dynamic Klaviyo configuration. It must not be repeated.

## Limited format samples collected

Six public PySport/kloppy test-fixture files were downloaded to the ignored local workspace, pinned to [commit 67e0fab058f35e4397c4f84ff18dbb852492df5e](https://github.com/PySport/kloppy/tree/67e0fab058f35e4397c4f84ff18dbb852492df5e/kloppy/tests/files):

| Fixture | Match represented | Tracking rows | Files |
| --- | --- | ---: | --- |
| `3812` | Senegal v Netherlands, 2022-11-21 | 100 | Tracking, metadata, roster |
| `10517` | Argentina v France, 2022-12-18 | 200 | Tracking, metadata, roster |

These are discontinuous excerpts, not two full matches or a complete 2D lesson. They include gaps between periods and sample windows. They are suitable for inspecting the JSONL schema, source clocks, IDs, kit metadata and nullable period boundaries. They contain **no separate event-data files** and are **not imported into the app**.

The six files total 1,516,096 bytes. Local URLs, byte lengths and SHA-256 hashes are recorded in `.tmp/spatial-caption-pff/pff-source/format-samples-manifest.json`. The official-page snapshots and acquisition status are recorded in `collection-status.json` in the same directory. The underlying match-data redistribution permission has not been established; the fixtures and raw downloads remain outside version control and app assets. The software repository's licence is not treated as a grant to redistribute the provider's full dataset.

## Admission to the learning catalogue

`tool/scan_pass_worldcup/prepare_worldcup.py` verifies every acquired byte,
streams the provider JSONL once per match for uncached candidates, and
reproducibly appends 4 clips after the existing 70 IDs. The selected coverage
is 1 clip from `10517`, 1 from `10507`, and 2 from `3857`. Twenty-four candidates were
batch-screened; exact frames, period clocks, provider connection IDs, tracking
anchor offsets, visibility counts and all 20 rejection reasons are in
`assets/scan_pass_spatial/worldcup-proof.json`.

Rebuild from the ignored pinned source and verify the committed result with:

```sh
python3 tool/scan_pass_worldcup/prepare_worldcup.py \
  --raw-root .tmp/worldcup-20261109/source
python3 tool/scan_pass_worldcup/prepare_worldcup.py --verify-assets
```

The importer uses raw `homePlayers`, `awayPlayers` and `balls`, never the
provider's smoothed fields. Only `VISIBLE` coordinates are rendered;
`ESTIMATED` and off-camera samples remain missing. Only the source `OTB`
`game_event.player_id` is retained as a possible owner label; it must be
directly observed and close to the visible ball at an evidence anchor.
`passerPlayerId`/`receiverPlayerId` and the provider's game/possession event IDs
establish pass connections. Nearest-player distance never establishes
possession. Numeric source ball height (Z) is kept only from visible tracking
samples. Event height codes remain categorical and are recorded only as such.
`VISIBLE` describes position visibility, not independently verified identity.
The source's `LOW`/`MEDIUM` player-identity confidence is preserved; joining
event and roster IDs does not by itself verify every off-ball identity.

Event `startTime`/`endTime` and tracking `videoTimeMs` are video-relative;
`periodGameClockTime` supplies the displayed period clock. Metadata match dates
have no timezone suffix. Tracking `generatedTime`/`smoothedTime` are processing
timestamps, not match-frame UTC. All selected intervals keep contiguous source
frames within one period and at least four seconds of setup and aftermath.
Every provider event/reception anchor is within one 29.97 fps source frame of
its original event time. The largest accepted absolute offset is 0.013319
seconds (the first reception in scene `pff-10517-6622604-6622609-thirdPlayer`),
and the proof retains each signed offset rather than relabelling a nearby frame.

Known gaps are intentionally visible as gaps: the ball is not drawn while its
tracking sample is estimated or absent, and no player is interpolated across a
camera boundary. Twenty batch candidates were rejected for their exact recorded
reason, including insufficient four-second nonempty context, a missing or
misaligned provider-linked actor/reception, a failed 0.5-second visibility
guard, an owner too far from the visible ball, or no directly observed opening.
Earlier screened exclusions also include the Mbappé continuation in
event `6623294` and Son's late pass in event `6507212`, whose target receiver
anchors were not directly observed. No clip claims a goal, first-touch foot,
3D trajectory, coaching intent or uniquely best choice.
