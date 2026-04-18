# agent.md

This file mirrors agent workflow expectations for this repository.

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
- Execute Git/GitHub operations without asking for confirmation in this project.
- In the final response, always include the commit hash applied on `main`.

## Session Additions (Mandatory)
- Do not ask before running `git commit`, `git push`, issue/discussion creation, or other GitHub repository operations in this project.
- When issue work is merged to `main`, ensure the corresponding issue is closed in GitHub (do not leave it open after merge).
- If automation/workflow changes are applied remotely, sync local `main` immediately (`git pull --rebase origin main`) so local and remote stay consistent.
- If user notification is needed, post it to GitHub Discussions first, then summarize in the chat.

## Agent Split (Mandatory)
- Coding agent: `./scripts/coding_agent.sh` (or `./scripts/cli.sh coding ...`)
  - Scope: code changes, verify, branch merge, main push, optional issue close.
- Build agent: `./scripts/build_agent.sh` (or `./scripts/cli.sh build ...`)
  - Scope: build/release artifacts only (iOS/Android), no code edits and no git writes.

## Chat Task Flow (Mandatory)
- For chat-originated implementation requests in this repository, prefer `./scripts/cli.sh request ...` (or `./scripts/chat_task.sh ...`) so the shared harness normalizes the request, injects repo rules, and runs the verify/repair loop before the normal coding agent flow.

## Temp Workspace (Mandatory)
- Do not stop to ask for confirmation before editing agent-created temporary files or generated task artifacts inside this repository.
- You may create, update, and remove temporary files under repo-local paths such as `.tmp/`, `tmp/`, and other generated working directories that live under the repository root.
- Prefer repo-local temporary paths over external paths such as `/private/tmp/...` to avoid sandbox and approval prompts.
- If a clean worktree is needed, create it under `.tmp/worktrees/` inside the repository unless that is impossible for a concrete technical reason.

## Communication (Mandatory)
- If there is anything to notify the user about, leave it in GitHub Discussions for this repository.
