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
- In the final response, always include the commit hash applied on `main`.
