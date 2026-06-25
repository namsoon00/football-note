# Design System Guardrails

This app already has a small design system. New screen work should extend these
tokens and components instead of adding one-off styling.

## Current Consistency Rules

- Theme: use `AppTheme.light()` and `AppTheme.dark()` as the source of truth.
- Typography: use `Theme.of(context).textTheme`; both light and dark modes use
  `Noto Sans KR` so Korean, English, and Japanese keep the same visual voice.
- Spacing: use `AppSpacing` for screen padding, card padding, and gaps.
- Radius: use `AppRadius` for controls, cards, and pill shapes.
- Size: use `AppSizes` for touch targets, app bar actions, and primary buttons.
- Surfaces: use `AppSurfaces` and `AppShadows` for cards, subtle panels, and
  hero panels so light and dark modes stay aligned.
- Screen background: wrap standard full-screen content with `AppBackground`.
- Top-right app bar actions: use `AppBarActionButton` and
  `AppBarActionMenuButton`.
- Copy: add user-facing strings to every `lib/l10n/*.arb` file and access them
  through `AppLocalizations`.

## Screen Patterns

- Operational screens should be compact, quiet, and scan-friendly.
- Related data should be grouped in one surface before adding another section.
- Avoid cards inside cards. Use full-width sections or a single card surface.
- Avoid decorative gradients, orbs, and one-off palettes unless the screen is a
  deliberate game or illustration surface.
- Prefer color scheme roles over raw colors. Use custom colors only for semantic
  visuals such as medals, charts, or domain-specific status marks.

## Automated Check

`./scripts/verify.sh` runs `./scripts/check_design_consistency.sh`.

The guardrail checks newly added lines in changed presentation Dart files for:

- Korean/English copy split with locale checks instead of localization keys.
- Newly added raw `IconButton`, `TextButton.icon`, or `PopupMenuButton`
  controls. Top-right app bar actions should use the shared app bar action
  components.

The check is intentionally focused on changed files so existing debt can be
fixed incrementally without blocking unrelated work.
