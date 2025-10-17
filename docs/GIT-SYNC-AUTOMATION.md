# Git Sync Automation & Lineage Logging

This documentation explains the automated sync workflow and the governance-anchored lineage logging.

## Overview

The repository includes a GitHub Actions workflow (`.github/workflows/sync-and-log.yml`) and a PowerShell script (`scripts/ci/rebase-and-log.ps1`) that perform a safe synchronization between local and remote branches, either by rebasing or by merging if rebase fails.

When the workflow runs it:
- Checks out the repository with full history
- Runs `rebase-and-log.ps1` under PowerShell
- The script fetches remote changes, attempts a rebase, runs validation tests (if present), appends a lineage entry to `logs/council_ledger.jsonl`, and pushes reconciled commits back to the remote.

## Usage

### Manual run
You can run the script locally to test it before enabling the scheduled workflow:

```powershell
pwsh ./scripts/ci/rebase-and-log.ps1 -AutoMode
```

- `-AutoMode` will automatically fallback to merge when rebase fails and perform the push.

### GitHub Actions
To enable automatic syncing:
1. Ensure `GITHUB_TOKEN` is available (built-in for Actions)
2. The workflow runs daily by default (02:00 UTC) and can be triggered manually via the Actions tab.

## Governance & Audit
Each run appends a compact JSON lineage entry to `logs/council_ledger.jsonl` with timestamp, action, branch, and commit—providing an auditable trail of sync events.

## Best Practices
- Use feature branches for development; sync `main` only after reconciliation.
- Protect `main` branch and require reviews for PRs.
- Run validation tests in CI to ensure safe merges.

## Troubleshooting
- If rebase conflicts occur locally, run:

```powershell
git rebase --abort
# Resolve conflicts by hand, then:
git rebase --continue
```

- If the workflow fails to push due to permissions, ensure the token has write access.

---

If you want, I can also scaffold a more advanced CI job which automatically opens a Pull Request with the rebased changes instead of pushing directly to `main` (safer for protected branches).
