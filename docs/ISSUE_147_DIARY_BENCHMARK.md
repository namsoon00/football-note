# Issue #147 Diary Benchmark

Source checked: Figma official FigJam product material on `figma.com` (2026-03-26).

Applied takeaways:
- A diary page should exist only when the user intentionally creates it.
- Source material should be attachable in small reusable units, similar to sticky notes rather than a fully auto-generated document.
- Empty states should still let the user start a blank page first, then pull in records selectively.

Implemented mapping in this repo:
- Diary pages are now built from saved diary entries, not from training records or plans.
- A new diary can be created on any date, including days without training.
- Training, match, and plan items can be pinned into the diary as record stickers.
