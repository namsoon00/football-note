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
- Before Codex runs, the worker now builds a shared prompt/context bundle through `scripts/codex_task_harness.sh`.

## 3) Workflow files
- Queue sync: `.github/workflows/issue-queue-sync.yml`
- Auto worker: `.github/workflows/issue-auto-worker.yml`

Both run every 30 minutes.

## 4) Optional repository variables
- `CODEX_RUNNER_CMD`: custom Codex invocation command
- `USE_CUSTOM_CODEX_CMD`: set `1` only if you really want to use `CODEX_RUNNER_CMD`
- `CODEX_SANDBOX`: default `workspace-write`
- `CODEX_APPROVAL`: default `never`
- `CODEX_UNSAFE`: default `1` (uses `--dangerously-bypass-approvals-and-sandbox`)
- `CODEX_MODEL`: default `gpt-5` (latest model). Override if needed.
- `CODEX_REASONING_EFFORT`: optional; supported values are `minimal`, `low`, `medium`, `high` and invalid values are normalized by the harness
- `RUN_VERIFY`: default `1`; set `0` to skip the worker-side verify/repair loop
- `AUTO_MERGE`: default `1` (try merge PR to `main` automatically)
- `AUTO_MERGE_METHOD`: `squash` (default), `merge`, or `rebase`
- `FORCE_MAIN_MERGE`: default `1` (merge worker branch directly into `main` and close issue)
- `LOCAL_SYNC_REPO_PATH`: optional local repo path to run extra `git pull` after merge

## 4-1) Required GitHub Actions permission for PR auto-create
Repository Settings -> Actions -> General -> Workflow permissions:
- `Read and write permissions`
- Enable `Allow GitHub Actions to create and approve pull requests`

Repository Settings -> General:
- Enable `Allow auto-merge` (recommended)

## 5) What happens each run
1. Pull latest `main`
2. Refresh `docs/ISSUE_QUEUE.md`
3. Pick first open issue from queue
4. Create/use branch `auto/issue-<number>-<slug>`
5. Build a shared harness prompt with context hints and repo rules
6. Run Codex against the harness prompt
7. Run verification/repair loop when enabled
8. Commit and push changes
9. Create or update PR
10. Leave issue comment with PR link

## 5-1) Shared local/remote harness
- Local coding flow can call the same harness through `./scripts/cli.sh coding --title ... --body-file ...`
- Remote issue automation calls the harness inside `scripts/run_issue_worker.sh`
- Common improvements live in one place:
  - prompt normalization
  - related file hints
  - localization/testing reminders
  - optional verify + repair retry

## 6) Commit and close behavior
- Commit hook requires issue numbers in messages.
- If commit includes `#<issue>`, hook auto appends `Closes #<issue>` (except `#0`).
