param(
    [switch]$AutoMode,
    [string]$Remote = 'origin',
    [string]$Branch = 'main'
)

# Minimal, robust script to safely sync local branch with remote and append a governance ledger entry.
# Usage:
#   pwsh ./scripts/ci/rebase-and-log.ps1 -AutoMode

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info($msg){ Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Err($msg){ Write-Host "[ERROR] $msg" -ForegroundColor Red }

Write-Info "Starting rebase-and-log on branch '$Branch' against remote '$Remote'"

# Configure git user for CI
if ($env:GIT_USER_NAME) { git config user.name $env:GIT_USER_NAME }
if ($env:GIT_USER_EMAIL) { git config user.email $env:GIT_USER_EMAIL }

# Fetch remote updates
git fetch $Remote --prune

# Check divergence
$localHead = git rev-parse --verify HEAD
$remoteHead = git rev-parse --verify $Remote/$Branch

Write-Info "Local HEAD: $localHead"
Write-Info "Remote HEAD: $remoteHead"

if ($localHead -eq $remoteHead) {
    Write-Info "Local branch already up-to-date with remote. Nothing to do."
    exit 0
}

# Attempt rebase for cleaner history; fallback to merge if rebase fails and AutoMode is set to false
try {
    Write-Info "Attempting rebase: git rebase $Remote/$Branch"
    git rebase $Remote/$Branch
    Write-Info "Rebase successful"
} catch {
    Write-Err "Rebase failed: $_"
    if ($AutoMode) {
        Write-Info "AutoMode enabled — aborting rebase and attempting merge"
        git rebase --abort 2>$null
        git merge --no-edit $Remote/$Branch
    } else {
        Write-Err "Manual intervention required to resolve rebase conflicts. Exiting with failure."
        exit 1
    }
}

# Run tests or validation if present
if (Test-Path "./tests/Invoke-ValidationTests.ps1") {
    Write-Info "Running validation tests..."
    pwsh -NoProfile -NonInteractive -File ./tests/Invoke-ValidationTests.ps1 -Detailed
}

# Create lineage anchor in the ledger
$timestamp = Get-Date -Format 'o'
$commit = git rev-parse --verify HEAD
$entry = @{
    timestamp = $timestamp
    action = "Sync local branch with remote and rebase/merge"
    actor = "civic-deploy-bot"
    metadata = @{
        branch = $Branch
        commit = $commit
        remote = $Remote
    }
}

$ledgerPath = Join-Path $PSScriptRoot "../../logs/council_ledger.jsonl" | Resolve-Path -ErrorAction SilentlyContinue
if (-not $ledgerPath) { $ledgerPath = Join-Path (Get-Location) "logs/council_ledger.jsonl" }

$entryJson = $entry | ConvertTo-Json -Compress
Add-Content -Path $ledgerPath -Value $entryJson
Write-Info "Appended lineage entry to $ledgerPath"

# Push changes back to remote (only if we created commits)
try {
    if (git rev-list --count $Remote/$Branch..HEAD -gt 0) {
        Write-Info "Pushing reconciled branch to $Remote/$Branch"
        git push $Remote HEAD:$Branch --follow-tags
    } else {
        Write-Info "No new commits to push after sync"
    }
} catch {
    Write-Err "Push failed: $_"
    exit 1
}

Write-Info "Sync-and-log completed successfully"
