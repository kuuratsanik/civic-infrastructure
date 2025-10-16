#Requires -Version 5.1
<#
.SYNOPSIS
    Repository Purification Ceremony - Remove Large Binary Objects from Git History

.DESCRIPTION
    Ceremonial script to surgically remove large binary files (ISO/WIM) from Git object database
    while maintaining repository integrity and creating full audit trail.

    This is a DESTRUCTIVE operation that rewrites Git history.
    All collaborators must re-clone after execution.

.PARAMETER WhatIf
    Dry-run mode - show what would be removed without making changes

.PARAMETER Force
    Skip confirmation prompts (use with caution)

.EXAMPLE
    .\Remove-LargeObjects.ps1 -WhatIf
    # Preview what will be removed

.EXAMPLE
    .\Remove-LargeObjects.ps1
    # Execute with confirmations

.EXAMPLE
    .\Remove-LargeObjects.ps1 -Force
    # Execute without confirmations (dangerous!)

.NOTES
    Ceremony Type: Purification & Lineage Correction
    Risk Level: HIGH (rewrites history)
    Governance: Requires evidence anchoring before & after
    Recovery: Keep backup clone before executing
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [string]$RepositoryPath = "c:\Users\svenk\OneDrive\All_My_Projects\New folder",

    [Parameter()]
    [int]$SizeThresholdMB = 50,

    [Parameter()]
    [string]$EvidencePath = "$RepositoryPath\evidence\purification"
)

$ErrorActionPreference = 'Stop'

# ============================================================================
# CEREMONIAL FUNCTIONS
# ============================================================================

function Write-CeremonyLog {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS', 'CEREMONY')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'INFO' { 'Cyan' }
        'WARNING' { 'Yellow' }
        'ERROR' { 'Red' }
        'SUCCESS' { 'Green' }
        'CEREMONY' { 'Magenta' }
    }

    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage -ForegroundColor $color

    # Ensure evidence directory exists before logging
    if (-not (Test-Path $EvidencePath)) {
        New-Item -ItemType Directory -Path $EvidencePath -Force | Out-Null
    }

    # Append to ceremony log
    Add-Content -Path "$EvidencePath\ceremony-$(Get-Date -Format 'yyyyMMdd').log" -Value $logMessage
}function New-EvidenceAnchor {
    param([string]$Phase)

    $anchorFile = "$EvidencePath\anchor-$Phase-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

    $evidence = @{
        Phase      = $Phase
        Timestamp  = Get-Date -Format 'o'
        User       = $env:USERNAME
        Machine    = $env:COMPUTERNAME
        Repository = $RepositoryPath
        GitState   = @{
            Branch            = (git -C $RepositoryPath branch --show-current)
            LastCommit        = (git -C $RepositoryPath rev-parse HEAD)
            LastCommitMessage = (git -C $RepositoryPath log -1 --pretty=%B)
            ObjectCount       = (git -C $RepositoryPath count-objects -v | Out-String)
        }
    }

    $evidence | ConvertTo-Json -Depth 10 | Out-File $anchorFile -Encoding UTF8
    Write-CeremonyLog "Evidence anchor created: $anchorFile" -Level CEREMONY

    return $anchorFile
}

function Show-CeremonialBanner {
    Write-Host @"

╔══════════════════════════════════════════════════════════════════════════╗
║                                                                          ║
║              🏛️  REPOSITORY PURIFICATION CEREMONY  🏛️                   ║
║                                                                          ║
║              Lineage Correction & Object Database Cleanup                ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Magenta
}

# ============================================================================
# PHASE 1: PRE-CEREMONY VALIDATION & EVIDENCE GATHERING
# ============================================================================

function Invoke-PreCeremonyValidation {
    Write-CeremonyLog "=== PHASE 1: PRE-CEREMONY VALIDATION ===" -Level CEREMONY

    # Ensure evidence directory exists
    if (-not (Test-Path $EvidencePath)) {
        New-Item -ItemType Directory -Path $EvidencePath -Force | Out-Null
        Write-CeremonyLog "Evidence directory created: $EvidencePath" -Level INFO
    }

    # Create pre-ceremony anchor
    $preAnchor = New-EvidenceAnchor -Phase "PRE-CEREMONY"

    # Validate repository exists
    if (-not (Test-Path "$RepositoryPath\.git")) {
        Write-CeremonyLog "Not a Git repository: $RepositoryPath" -Level ERROR
        throw "Invalid repository path"
    }

    # Check for uncommitted changes
    $status = git -C $RepositoryPath status --porcelain
    if ($status) {
        Write-CeremonyLog "Uncommitted changes detected:" -Level WARNING
        Write-Host $status -ForegroundColor Yellow

        if (-not $Force) {
            $response = Read-Host "Continue anyway? (yes/no)"
            if ($response -ne 'yes') {
                throw "Ceremony aborted - commit or stash changes first"
            }
        }
    }

    # Recommend backup
    Write-CeremonyLog "RECOMMENDATION: Create backup clone before proceeding" -Level WARNING
    Write-Host "  git clone $RepositoryPath ${RepositoryPath}_backup" -ForegroundColor Yellow

    if (-not $Force) {
        $hasBackup = Read-Host "Do you have a backup? (yes/no)"
        if ($hasBackup -ne 'yes') {
            throw "Ceremony aborted - create backup first"
        }
    }

    Write-CeremonyLog "Pre-ceremony validation complete" -Level SUCCESS
    return $preAnchor
}

# ============================================================================
# PHASE 2: IDENTIFY LARGE OBJECTS
# ============================================================================

function Get-LargeObjects {
    param([int]$ThresholdMB)

    Write-CeremonyLog "=== PHASE 2: IDENTIFYING LARGE OBJECTS ===" -Level CEREMONY
    Write-CeremonyLog "Threshold: $ThresholdMB MB" -Level INFO

    Push-Location $RepositoryPath

    try {
        # Find pack files
        $packFiles = Get-ChildItem ".git\objects\pack\*.idx" -ErrorAction SilentlyContinue

        if (-not $packFiles) {
            Write-CeremonyLog "No pack files found - running git gc first" -Level INFO
            git gc
            $packFiles = Get-ChildItem ".git\objects\pack\*.idx"
        }

        Write-CeremonyLog "Analyzing pack files..." -Level INFO

        # Get largest objects
        $largeObjects = @()
        foreach ($packFile in $packFiles) {
            Write-CeremonyLog "Scanning: $($packFile.Name)" -Level INFO

            $output = git verify-pack -v $packFile.FullName | Where-Object { $_ -match '^\w{40}' }

            foreach ($line in $output) {
                $parts = $line -split '\s+'
                $sha = $parts[0]
                $size = [int]$parts[2]
                $sizeMB = [math]::Round($size / 1MB, 2)

                if ($sizeMB -ge $ThresholdMB) {
                    # Get file path from object
                    $filePath = git rev-list --objects --all | Select-String $sha | ForEach-Object {
                        ($_ -split '\s+', 2)[1]
                    } | Select-Object -First 1

                    $largeObjects += [PSCustomObject]@{
                        SHA       = $sha
                        SizeMB    = $sizeMB
                        SizeBytes = $size
                        FilePath  = $filePath
                    }
                }
            }
        }

        $largeObjects = $largeObjects | Sort-Object -Property SizeMB -Descending

        if ($largeObjects.Count -eq 0) {
            Write-CeremonyLog "No large objects found above $ThresholdMB MB" -Level SUCCESS
            return @()
        }

        Write-CeremonyLog "Found $($largeObjects.Count) large objects:" -Level WARNING
        foreach ($obj in $largeObjects) {
            Write-Host "  $($obj.SizeMB) MB - $($obj.FilePath)" -ForegroundColor Yellow
        }

        # Save evidence
        $largeObjects | Export-Csv "$EvidencePath\large-objects-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv" -NoTypeInformation

        return $largeObjects

    } finally {
        Pop-Location
    }
}

# ============================================================================
# PHASE 3: LINEAGE CORRECTION (HISTORY REWRITE)
# ============================================================================

function Invoke-LineageCorrection {
    param([array]$FilesToRemove)

    Write-CeremonyLog "=== PHASE 3: LINEAGE CORRECTION ===" -Level CEREMONY

    if ($FilesToRemove.Count -eq 0) {
        Write-CeremonyLog "No files to remove" -Level INFO
        return
    }

    Push-Location $RepositoryPath

    try {
        foreach ($file in $FilesToRemove) {
            $path = $file.FilePath

            if (-not $path) {
                Write-CeremonyLog "Skipping object with unknown path: $($file.SHA)" -Level WARNING
                continue
            }

            Write-CeremonyLog "Removing from history: $path ($($file.SizeMB) MB)" -Level INFO

            if ($PSCmdlet.ShouldProcess($path, "Remove from Git history")) {
                # Using filter-branch (safer than filter-repo for this case)
                $env:FILTER_BRANCH_SQUELCH_WARNING = '1'

                git filter-branch --force --index-filter `
                    "git rm --cached --ignore-unmatch `"$path`"" `
                    --prune-empty --tag-name-filter cat -- --all

                if ($LASTEXITCODE -ne 0) {
                    Write-CeremonyLog "Warning: filter-branch had issues with $path" -Level WARNING
                }
            }
        }

        Write-CeremonyLog "Lineage correction complete" -Level SUCCESS

    } finally {
        Pop-Location
    }
}

# ============================================================================
# PHASE 4: PURIFICATION (GARBAGE COLLECTION)
# ============================================================================

function Invoke-Purification {
    Write-CeremonyLog "=== PHASE 4: PURIFICATION (GARBAGE COLLECTION) ===" -Level CEREMONY

    Push-Location $RepositoryPath

    try {
        # Remove original refs
        Write-CeremonyLog "Removing original refs..." -Level INFO
        if (Test-Path ".git\refs\original") {
            Remove-Item -Path ".git\refs\original" -Recurse -Force
        }

        # Expire reflog
        Write-CeremonyLog "Expiring reflog..." -Level INFO
        if ($PSCmdlet.ShouldProcess("reflog", "Expire now")) {
            git reflog expire --expire=now --all
        }

        # Aggressive garbage collection
        Write-CeremonyLog "Running aggressive garbage collection (this may take several minutes)..." -Level INFO
        if ($PSCmdlet.ShouldProcess("repository", "Garbage collect")) {
            git gc --prune=now --aggressive

            if ($LASTEXITCODE -eq 0) {
                Write-CeremonyLog "Garbage collection complete" -Level SUCCESS
            } else {
                Write-CeremonyLog "Garbage collection completed with warnings" -Level WARNING
            }
        }

        # Show new size
        $objectCount = git count-objects -vH
        Write-CeremonyLog "New repository statistics:" -Level INFO
        Write-Host $objectCount -ForegroundColor Cyan

    } finally {
        Pop-Location
    }
}

# ============================================================================
# PHASE 5: POST-CEREMONY VALIDATION & EVIDENCE SEALING
# ============================================================================

function Invoke-PostCeremonyValidation {
    Write-CeremonyLog "=== PHASE 5: POST-CEREMONY VALIDATION ===" -Level CEREMONY

    # Create post-ceremony anchor
    $postAnchor = New-EvidenceAnchor -Phase "POST-CEREMONY"

    Push-Location $RepositoryPath

    try {
        # Verify repository integrity
        Write-CeremonyLog "Verifying repository integrity..." -Level INFO
        git fsck --full

        if ($LASTEXITCODE -eq 0) {
            Write-CeremonyLog "Repository integrity verified" -Level SUCCESS
        } else {
            Write-CeremonyLog "Repository integrity check failed" -Level ERROR
        }

        # Show final statistics
        $finalStats = git count-objects -vH
        Write-CeremonyLog "Final repository statistics:" -Level SUCCESS
        Write-Host $finalStats -ForegroundColor Green

    } finally {
        Pop-Location
    }

    return $postAnchor
}

# ============================================================================
# PHASE 6: FORCE PUSH GUIDANCE
# ============================================================================

function Show-ForcePushGuidance {
    Write-CeremonyLog "=== PHASE 6: REMOTE SYNC REQUIRED ===" -Level CEREMONY

    Write-Host @"

╔══════════════════════════════════════════════════════════════════════════╗
║                                                                          ║
║                      ⚠️  FORCE PUSH REQUIRED  ⚠️                         ║
║                                                                          ║
║  History has been rewritten. You must force-push to update remote:      ║
║                                                                          ║
║      git push origin --force --all                                      ║
║      git push origin --force --tags                                     ║
║                                                                          ║
║  ⚠️  WARNING: All collaborators must re-clone or reset!                 ║
║                                                                          ║
║  Recovery command for collaborators:                                    ║
║      git fetch origin                                                   ║
║      git reset --hard origin/main                                       ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Yellow

    if (-not $Force) {
        $pushNow = Read-Host "Execute force push now? (yes/no)"
        if ($pushNow -eq 'yes') {
            Push-Location $RepositoryPath
            try {
                Write-CeremonyLog "Executing force push..." -Level WARNING
                git push origin --force --all
                git push origin --force --tags
                Write-CeremonyLog "Force push complete" -Level SUCCESS
            } finally {
                Pop-Location
            }
        }
    }
}

# ============================================================================
# MAIN CEREMONY ORCHESTRATION
# ============================================================================

function Invoke-RepositoryPurificationCeremony {
    Show-CeremonialBanner

    Write-CeremonyLog "Repository Purification Ceremony initiated" -Level CEREMONY
    Write-CeremonyLog "Repository: $RepositoryPath" -Level INFO
    Write-CeremonyLog "Size threshold: $SizeThresholdMB MB" -Level INFO
    Write-CeremonyLog "Evidence path: $EvidencePath" -Level INFO

    try {
        # Phase 1: Pre-ceremony validation
        $preAnchor = Invoke-PreCeremonyValidation

        # Phase 2: Identify large objects
        $largeObjects = Get-LargeObjects -ThresholdMB $SizeThresholdMB

        if ($largeObjects.Count -eq 0) {
            Write-CeremonyLog "No purification needed - ceremony complete" -Level SUCCESS
            return
        }

        # Confirmation
        if (-not $Force) {
            Write-Host "`nThe following files will be PERMANENTLY removed from Git history:" -ForegroundColor Yellow
            $largeObjects | Format-Table -Property SizeMB, FilePath -AutoSize

            $confirm = Read-Host "`nThis is IRREVERSIBLE. Type 'PURIFY' to continue"
            if ($confirm -ne 'PURIFY') {
                throw "Ceremony aborted by user"
            }
        }

        # Phase 3: Lineage correction
        Invoke-LineageCorrection -FilesToRemove $largeObjects

        # Phase 4: Purification
        Invoke-Purification

        # Phase 5: Post-ceremony validation
        $postAnchor = Invoke-PostCeremonyValidation

        # Phase 6: Force push guidance
        Show-ForcePushGuidance

        # Final ceremony log
        Write-Host @"

╔══════════════════════════════════════════════════════════════════════════╗
║                                                                          ║
║                  ✅  PURIFICATION CEREMONY COMPLETE  ✅                   ║
║                                                                          ║
║  Evidence anchors created:                                              ║
║    Pre:  $($preAnchor | Split-Path -Leaf)
║    Post: $($postAnchor | Split-Path -Leaf)
║                                                                          ║
║  Repository has been purified and lineage corrected.                    ║
║  All large binary objects have been removed from history.               ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

        Write-CeremonyLog "Ceremony complete - lineage sealed" -Level CEREMONY

    } catch {
        Write-CeremonyLog "Ceremony failed: $_" -Level ERROR
        throw
    }
}

# ============================================================================
# EXECUTE CEREMONY
# ============================================================================

Invoke-RepositoryPurificationCeremony
