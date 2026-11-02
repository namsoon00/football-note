# 태오의노트

A new Flutter project.

## Getting Started

## Verification

Run the quick prelaunch verification profile (the required default for normal
development):

```bash
./scripts/verify.sh
```

Quick verification resolves dependencies, generates and checks localization,
runs `flutter analyze --no-pub` and the design consistency guard, then runs the
seven tagged `prelaunch-smoke` tests from an explicit three-file allowlist. It
does not discover or compile the entire test directory.

`VERIFY_SCOPE=minimal` is a compatibility alias for the same quick profile.
Run all specialized contracts and the full Flutter suite only when explicitly
needed or for a mobile release:

```bash
VERIFY_SCOPE=full ./scripts/verify.sh
```

Or use the project CLI:

```bash
./scripts/cli.sh verify
```

## Auto-Fix

Run auto-fixable steps (dependencies, l10n, format) and then verify:

```bash
./scripts/fix.sh
```

## CLI

Single entrypoint for common project tasks:

```bash
./scripts/cli.sh help
```

Local Codex tasks can share the same harness as the issue worker:

```bash
./scripts/cli.sh coding \
  -m "chore: improve harness flow (#0)" \
  --title "Improve automation harness" \
  --body "Unify local CLI and issue worker through the shared harness."
```

Chat-style requests can go through the same flow with a single entrypoint:

```bash
./scripts/cli.sh request \
  --request "Unify the onboarding CTA spacing and add tests for the updated layout."
```

Chat/coding flows run the final verification once before commit and push.
Harness-side verify/repair is opt-in with `--harness-verify`, an explicitly
supplied `--harness-verify-command`, or `HARNESS_RUN_VERIFY=1`.

## Issue Workflow

This repo supports issue-driven remote tasking.

1. Install repo hooks once:

```bash
./scripts/setup_git_hooks.sh
```

2. Commit messages must include an issue number:

```text
feat: add profile card spacing (#123)
```

Issue number가 들어간 커밋은 훅이 `Closes #123` 라인을 자동으로 붙여
해당 이슈가 자동 종료되도록 설정되어 있습니다 (`#0` 제외).

3. Issue queue is synced automatically every 30 minutes by GitHub Actions:

- workflow: `.github/workflows/issue-queue-sync.yml`
- queue file: `docs/ISSUE_QUEUE.md`

Detailed guide: `docs/ISSUE_WORKFLOW.md`

Self-hosted local Codex automation guide:
`docs/LOCAL_CODEX_AUTOMATION.md`

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
