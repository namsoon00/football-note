# Issue-Driven Workflow

## Goal
Use GitHub Issues as the remote task source and keep this repo aligned automatically.

## Maintainer flow
1. Create an issue in GitHub.
2. Add clear acceptance criteria and expected behavior.
3. (Recommended) Add labels such as `bug`, `enhancement`, `priority:high`, `priority:medium`.
4. The queue file `docs/ISSUE_QUEUE.md` is refreshed every 30 minutes by GitHub Actions.

## Developer flow
1. Pull latest `main`.
2. Open `docs/ISSUE_QUEUE.md` and pick from "Next Candidates".
3. Create a branch for the issue (`feature/issue-123-short-name`).
4. Commit messages must include the issue number (example: `fix: handle null profile (#123)`).
5. Push branch and open PR linked to the issue.

## Enforced rules
- Commit message must include `#<issue_number>`.
- Hook file: `.githooks/commit-msg`
- Hook setup command:

```bash
./scripts/setup_git_hooks.sh
```

## Automation
- Workflow file: `.github/workflows/issue-queue-sync.yml`
- Schedule: every 30 minutes (`*/30 * * * *`)
- Output: `docs/ISSUE_QUEUE.md`
