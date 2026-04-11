# Agent Working Rules

## Verification (Mandatory)
- After any code change, run `./scripts/verify.sh` from repo root before final response.
- In the final response, always report:
  - command executed
  - pass/fail status
  - failing step and key error if failed
- If full verify cannot complete due environment limits (for example simulator unavailable), report the exact blocking step and still include completed steps' results.

## Git Workflow (Mandatory)
- Default workflow is branch-based merge to `main` (no PR by default): create work branch -> commit -> merge to `main` with a merge commit -> push `main`.
- If a PR flow is requested, use: feature branch -> commit -> pull request -> merge to `main`.
- If an issue number is provided or detected from commit message `#<number>`, close the issue after main push (and leave a merge comment).
- In the final response, always include the commit hash applied on `main`.

## Agent Split (Mandatory)
- Coding agent: `./scripts/coding_agent.sh` (or `./scripts/cli.sh coding ...`)
  - Scope: code changes, verify, branch merge, main push, optional issue close.
- Build agent: `./scripts/build_agent.sh` (or `./scripts/cli.sh build ...`)
  - Scope: build/release artifacts only (iOS/Android), no code edits and no git writes.

## Chat Task Flow (Mandatory)
- For chat-originated implementation requests in this repository, prefer `./scripts/cli.sh request ...` (or `./scripts/chat_task.sh ...`) so the shared harness normalizes the request, injects repo rules, and runs the verify/repair loop before the normal coding agent flow.

## Localization (Mandatory)
- All user-facing text must be added through the localization files under `lib/l10n/` and accessed through generated localization classes.
- Do not introduce new hardcoded UI strings in screens, widgets, dialogs, snackbars, buttons, labels, or tooltips, even if only English/Korean exists today.
- When adding or changing copy, update every supported ARB file consistently so the app remains ready for additional locales later.
