# Local Codex Automation (Self-hosted Runner)

This setup runs GitHub Actions on your Mac and lets the workflow call your local Codex CLI.

## 1) Register a self-hosted runner
1. Open: `https://github.com/namsoon00/football-note/settings/actions/runners`
2. Click **New self-hosted runner**
3. Select macOS and follow GitHub's generated commands on your Mac.
4. Add labels including `self-hosted` and `macOS`.

Keep the runner service always on.

## 2) Ensure Codex CLI is available for the runner user
- `codex` command must be executable from shell PATH.
- Optional: set repository variable `CODEX_RUNNER_CMD` if your Codex command differs.

Default worker behavior:
- If `CODEX_RUNNER_CMD` is set, it runs that command.
- Else it tries `codex exec "<prompt>"`.

## 3) Workflow files
- Queue sync: `.github/workflows/issue-queue-sync.yml`
- Auto worker: `.github/workflows/issue-auto-worker.yml`

Both run every 30 minutes.

## 4) Optional repository variables
- `CODEX_RUNNER_CMD`: custom Codex invocation command
- `RUN_VERIFY`: set `1` to run `scripts/verify.sh` in worker

## 5) What happens each run
1. Pull latest `main`
2. Refresh `docs/ISSUE_QUEUE.md`
3. Pick first open issue from queue
4. Create/use branch `auto/issue-<number>-<slug>`
5. Run Codex against issue title/body
6. Commit and push changes
7. Create or update PR
8. Leave issue comment with PR link

## 6) Commit and close behavior
- Commit hook requires issue numbers in messages.
- If commit includes `#<issue>`, hook auto appends `Closes #<issue>` (except `#0`).
