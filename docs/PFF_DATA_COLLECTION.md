# PFF / Gradient Sports data collection

Checked on 2026-11-03 (KST). This record describes acquisition status, not app catalogue coverage.

## Full release

Gradient Sports, formerly PFF FC, advertises tracking, event, roster and match metadata for all **64 matches of the 2022 men's World Cup**:

- [Current enhanced release](https://www.gradientsports.com/blog/enhanced-2022-world-cup-dataset)
- [Legacy enhanced release](https://www.blog.fc.pff.com/blog/enhanced-2022-world-cup-dataset)
- [Original release](https://www.blog.fc.pff.com/blog/pff-fc-release-2022-world-cup-data)

**Full match files acquired: 0. Full PFF matches imported into the app: 0.**

The retrieved official pages say to complete a form, but contain no dataset access form or downloadable dataset URL. The legacy `fc.pff.com` site returns HTTP 530. The footer's newsletter signup is not the dataset request form. This is an access blocker; it does not establish that the release has been withdrawn.

The next required input is an authorised download URL/access method from the user or provider. The [official contact page](https://www.gradientsports.com/contact) lists `support@gradientsports.com`. An unsent request asking for the dataset, specification and permission to show derived educational 2D sequences is saved locally at `.tmp/spatial-caption-pff/pff-source/access-request.eml`. No message, signup, licence acceptance or paid order has been submitted.

## Limited format samples collected

Six public PySport/kloppy test-fixture files were downloaded to the ignored local workspace, pinned to [commit 67e0fab058f35e4397c4f84ff18dbb852492df5e](https://github.com/PySport/kloppy/tree/67e0fab058f35e4397c4f84ff18dbb852492df5e/kloppy/tests/files):

| Fixture | Match represented | Tracking rows | Files |
| --- | --- | ---: | --- |
| `3812` | Senegal v Netherlands, 2022-11-21 | 100 | Tracking, metadata, roster |
| `10517` | Argentina v France, 2022-12-18 | 200 | Tracking, metadata, roster |

These are discontinuous excerpts, not two full matches or a complete 2D lesson. They include gaps between periods and sample windows. They are suitable for inspecting the JSONL schema, source clocks, IDs, kit metadata and nullable period boundaries. They contain **no separate event-data files** and are **not imported into the app**.

The six files total 1,516,096 bytes. Local URLs, byte lengths and SHA-256 hashes are recorded in `.tmp/spatial-caption-pff/pff-source/format-samples-manifest.json`. The official-page snapshots and acquisition status are recorded in `collection-status.json` in the same directory. The underlying match-data redistribution permission has not been established; the fixtures and raw downloads remain outside version control and app assets. The software repository's licence is not treated as a grant to redistribute the provider's full dataset.

## Admission to the learning catalogue

After access is available, inspect one complete match before bulk collection. Preserve provider files and hashes locally. Confirm permitted educational display and any later public/commercial use. Align tracking and events with their original clocks; inspect period direction changes, observation gaps, player identities and ball validity. Only then select continuous teaching sequences and add a source-specific importer. Do not join the discontinuous fixtures, invent missing coordinates, or present provider grades as proof of a uniquely best decision.

The existing 70-lesson SkillCorner catalogue is unchanged by this collection work.
