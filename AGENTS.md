# Agent Working Rules

## Verification (Mandatory)
- After any code change, run `./scripts/verify.sh` from repo root before final response. This is the quick prelaunch profile by default.
- Use `VERIFY_SCOPE=full ./scripts/verify.sh` only for an explicit full request, a real mobile release/tag publication, or a concrete failure whose relevant specialized/full-suite coverage is needed. `VERIFY_SCOPE=minimal` remains a compatibility alias for quick.
- For routine changes, add or run a few focused regressions only when the changed behavior justifies them. New tests should protect important behavior such as persistence/data loss, core navigation, or similarly costly failures; do not add routine every-viewport or multilingual screenshot sweeps for reversible changes.
- Repository-specific prelaunch override: broader parent guidance to always run iOS simulator and Chrome checks does not apply to documentation-, test-, script-, or verification-only changes. Run native/Chrome checks when changed UI or platform behavior needs them. Full verification does not automatically launch simulators or Chrome.
- In the final response, always report:
  - command executed
  - pass/fail status
  - failing step and key error if failed
- If requested verification cannot complete due environment limits, report the exact blocking step and still include completed steps' results.

## Git Workflow (Mandatory)
- Default workflow is branch-based merge to `main` (no PR by default): create work branch -> commit -> merge to `main` with a merge commit -> push `main`.
- Before starting any implementation task, confirm the current branch is `main`. If it is not `main`, switch back to `main` first, or use a separate clean worktree based on `main`, and only then create a fresh work branch.
- After merging work back into `main`, leave the local repository on `main`. Do not finish a task while leaving the primary working checkout on a feature branch.
- Do not consider an implementation task complete until `git push origin main` succeeds after the merge commit. Never intentionally skip, defer, or leave the push for the user; if push is blocked by credentials, network, or remote rejection, report the exact blocker in the final response.
- If a PR flow is requested, use: feature branch -> commit -> pull request -> merge to `main`.
- If an issue number is provided or detected from commit message `#<number>`, close the issue after main push (and leave a merge comment).
- In the final response, always include the commit hash applied on `main`.

## Agent Split (Mandatory)
- Coding agent: `./scripts/coding_agent.sh` (or `./scripts/cli.sh coding ...`)
  - Scope: code changes, verify, branch merge, main push, optional issue close.
- Build agent: `./scripts/build_agent.sh` (or `./scripts/cli.sh build ...`)
  - Scope: build/release artifacts only (iOS/Android), no code edits and no git writes.

## Chat Task Flow (Mandatory)
- For chat-originated implementation requests in this repository, prefer `./scripts/cli.sh request ...` (or `./scripts/chat_task.sh ...`) so the shared harness normalizes the request and injects repo rules. By default, the outer coding flow performs one final quick verification; harness-side verify/repair is opt-in.

## Temp Workspace (Mandatory)
- Do not stop to ask for confirmation before editing agent-created temporary files or generated task artifacts inside this repository.
- You may create, update, and remove temporary files under repo-local paths such as `.tmp/`, `tmp/`, and other generated working directories that live under the repository root.
- Default to modifying the needed repository files directly in the current checkout/work branch for normal implementation tasks. Do not create a separate temporary worktree or alternate checkout just to make routine file edits.
- Use a separate clean worktree only when there is a concrete git-safety reason, such as protecting unrelated in-progress local changes, satisfying the required `main`-first branch workflow, or completing merge/push/branch-cleanup work without disturbing the primary checkout.
- Prefer repo-local temporary paths over external paths such as `/private/tmp/...` to avoid sandbox and approval prompts.
- If a clean worktree is needed, create it under `.tmp/worktrees/` inside the repository unless that is impossible for a concrete technical reason.

## Localization (Mandatory)
- All user-facing text must be added through the localization files under `lib/l10n/` and accessed through generated localization classes.
- Do not introduce new hardcoded UI strings in screens, widgets, dialogs, snackbars, buttons, labels, or tooltips, even if only English/Korean exists today.
- When adding or changing copy, update every supported ARB file consistently so the app remains ready for additional locales later.

## XP Guide Consistency (Mandatory)
- Whenever XP, level thresholds, level rewards, streak bonuses, routine bonuses, daily caps, or other progression rules change, update every affected guide/explanation surface in the same task.
- This includes the XP/level guide screens, summary copy, and any localized reward text under `lib/l10n/*.arb` that mentions concrete XP amounts or progression rules.
- Do not leave gameplay/progression logic on new numbers while the guide still shows old numbers.
