# Agent Working Rules

## Verification (Mandatory)
- After any code change, run `./scripts/verify.sh` from repo root before final response.
- In the final response, always report:
  - command executed
  - pass/fail status
  - failing step and key error if failed
- If full verify cannot complete due environment limits (for example simulator unavailable), report the exact blocking step and still include completed steps' results.

## Git Workflow (Mandatory)
- Every completed code task must be delivered as: feature branch -> commit -> pull request -> merge to `main`.
- Prefer GitHub CLI for PR creation/merge: `gh pr create` and `gh pr merge`.
- In the final response, always include the PR link and merged commit hash on `main`.
