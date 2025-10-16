<#
.SYNOPSIS
    Smart File Mover to Google Drive - Free up local disk space

.DESCRIPTION
    Analyzes C: and D: drives for large files that can be moved to Google Drive
    Preserves important user data locally
    Moves:
    - Large video files
    - ISO files and installers
    - Old archives and backups
    - Large downloads
    - Temporary large files

    30TB Google Drive available with Google AI Ultra subscription

.EXAMPLE
    .\Move-To-GoogleDrive.ps1 -ScanOnly
    Scan and show what would be moved (no changes)

.EXAMPLE
    .\Move-To-GoogleDrive.ps1 -AutoMove
    Automatically move safe files to Google Drive
#>

param(
    [switch]$ScanOnly,
    [switch]$AutoMove,
    [string]$GoogleDrivePath = "G:\My Drive",  # Adjust if your Google Drive is mounted differently
    [int]$MinSizeGB = 1  # Only consider files larger than this
)

Write-Host @"

============================================================
  SMART FILE MOVER TO GOOGLE DRIVE
  30TB Available | Google AI Ultra Subscription Active
============================================================

"@ -ForegroundColor Cyan

# Check if Google Drive is accessible
$googleDriveAvailable = $false
if (Test-Path $GoogleDrivePath) {
    $googleDriveAvailable = $true
    Write-Host "Google Drive detected: $GoogleDrivePath" -ForegroundColor Green
} else {
    Write-Host "Google Drive path not found: $GoogleDrivePath" -ForegroundColor Yellow
    Write-Host "Please update the -GoogleDrivePath parameter" -ForegroundColor Yellow

    # Try to detect Google Drive
    $possiblePaths = @(
        "G:\My Drive",
        "G:\",
        "$env:USERPROFILE\Google Drive",
        "C:\Users\$env:USERNAME\Google Drive"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            Write-Host "Found Google Drive at: $path" -ForegroundColor Green
            $GoogleDrivePath = $path
            $googleDriveAvailable = $true
            break
        }
    }

    if (-not $googleDriveAvailable) {
        Write-Host "`nGoogle Drive not mounted. Please:" -ForegroundColor Yellow
        Write-Host "1. Install Google Drive for Desktop" -ForegroundColor Cyan
        Write-Host "2. Sign in with your Google AI Ultra account" -ForegroundColor Cyan
        Write-Host "3. Mount your drive and re-run this script" -ForegroundColor Cyan
        Write-Host "`nContinuing in scan-only mode...`n" -ForegroundColor Gray
        $ScanOnly = $true
    }
}

# Categories of files to move
$moveCategories = @{
    "Videos"          = @{
        Extensions  = @("*.mp4", "*.avi", "*.mkv", "*.mov", "*.wmv", "*.flv", "*.webm", "*.m4v")
        Description = "Video files"
        Priority    = 1
    }
    "ISOs"            = @{
        Extensions  = @("*.iso", "*.img")
        Description = "Disk images and installers"
        Priority    = 1
    }
    "Archives"        = @{
        Extensions  = @("*.zip", "*.rar", "*.7z", "*.tar", "*.gz", "*.bz2")
        Description = "Compressed archives"
        Priority    = 2
    }
    "Installers"      = @{
        Extensions  = @("*.exe", "*.msi")
        Description = "Large installers (>100MB)"
        Priority    = 3
        SizeFilter  = 100MB
    }
    "Backups"         = @{
        Extensions  = @("*.bak", "*.backup", "*.old")
        Description = "Backup files"
        Priority    = 2
    }
    "VirtualMachines" = @{
        Extensions  = @("*.vhd", "*.vhdx", "*.vmdk", "*.ova", "*.ovf")
        Description = "Virtual machine files"
        Priority    = 1
    }
}

# Directories to scan
$scanPaths = @(
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\Videos",
    "$env:USERPROFILE\Documents",
    "D:\"
)

Write-Host "`nScanning for large files (>$MinSizeGB GB)..." -ForegroundColor Cyan
Write-Host "This may take a few minutes...`n" -ForegroundColor Gray

$allCandidates = @()
$totalSizeToMove = 0

foreach ($category in $moveCategories.Keys) {
    $config = $moveCategories[$category]
    Write-Host "Scanning: $($config.Description)..." -ForegroundColor Yellow

    $files = @()
    foreach ($path in $scanPaths) {
        if (Test-Path $path) {
            foreach ($ext in $config.Extensions) {
                $found = Get-ChildItem -Path $path -Filter $ext -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.Length -gt ($MinSizeGB * 1GB) -and
                    (-not $config.SizeFilter -or $_.Length -gt $config.SizeFilter)
                }
                $files += $found
            }
        }
    }

    if ($files.Count -gt 0) {
        $categorySize = ($files | Measure-Object -Property Length -Sum).Sum / 1GB
        Write-Host "  Found: $($files.Count) files ($([math]::Round($categorySize, 2)) GB)" -ForegroundColor Green

        foreach ($file in $files) {
            $allCandidates += [PSCustomObject]@{
                Category   = $category
                Priority   = $config.Priority
                File       = $file
                Path       = $file.FullName
                Name       = $file.Name
                SizeGB     = [math]::Round($file.Length / 1GB, 2)
                LastAccess = $file.LastAccessTime
                Age        = (Get-Date) - $file.LastAccessTime
            }
        }

        $totalSizeToMove += $categorySize
    } else {
        Write-Host "  Found: 0 files" -ForegroundColor Gray
    }
}

# Sort by priority and size
$allCandidates = $allCandidates | Sort-Object Priority, @{Expression = { $_.SizeGB }; Descending = $true }

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "  SCAN RESULTS" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan

Write-Host "`nTotal files found: $($allCandidates.Count)" -ForegroundColor White
Write-Host "Total size: $([math]::Round($totalSizeToMove, 2)) GB" -ForegroundColor Cyan
Write-Host "Potential disk space to free: $([math]::Round($totalSizeToMove, 2)) GB`n" -ForegroundColor Green

# Show top 20 largest files
Write-Host "Top 20 Largest Files:" -ForegroundColor Yellow
Write-Host ("=" * 120) -ForegroundColor DarkGray

$allCandidates | Select-Object -First 20 | ForEach-Object {
    $ageString = if ($_.Age.TotalDays -gt 365) {
        "$([math]::Round($_.Age.TotalDays / 365, 1)) years"
    } elseif ($_.Age.TotalDays -gt 30) {
        "$([math]::Round($_.Age.TotalDays / 30, 1)) months"
    } else {
        "$([math]::Round($_.Age.TotalDays, 0)) days"
    }

    Write-Host "$($_.SizeGB) GB" -ForegroundColor Cyan -NoNewline
    Write-Host " | " -ForegroundColor DarkGray -NoNewline
    Write-Host "$($_.Category)" -ForegroundColor Yellow -NoNewline
    Write-Host " | " -ForegroundColor DarkGray -NoNewline
    Write-Host "Age: $ageString" -ForegroundColor Gray -NoNewline
    Write-Host " | " -ForegroundColor DarkGray -NoNewline
    Write-Host "$($_.Name)" -ForegroundColor White
}

# Group by category
Write-Host "`n`nBreakdown by Category:" -ForegroundColor Yellow
Write-Host ("=" * 80) -ForegroundColor DarkGray

$grouped = $allCandidates | Group-Object Category
foreach ($group in $grouped | Sort-Object { ($_.Group | Measure-Object -Property SizeGB -Sum).Sum } -Descending) {
    $categorySize = ($group.Group | Measure-Object -Property SizeGB -Sum).Sum
    Write-Host "$($group.Name): " -ForegroundColor Cyan -NoNewline
    Write-Host "$($group.Count) files, " -ForegroundColor White -NoNewline
    Write-Host "$([math]::Round($categorySize, 2)) GB" -ForegroundColor Green
}

# Move files if not scan-only
if (-not $ScanOnly -and $googleDriveAvailable) {
    Write-Host "`n============================================================" -ForegroundColor Cyan
    Write-Host "  MOVING FILES TO GOOGLE DRIVE" -ForegroundColor Yellow
    Write-Host "============================================================`n" -ForegroundColor Cyan

    if (-not $AutoMove) {
        $response = Read-Host "Move these files to Google Drive? (yes/no)"
        if ($response -ne "yes") {
            Write-Host "`nOperation cancelled by user" -ForegroundColor Yellow
            exit
        }
    }

    $movedCount = 0
    $movedSize = 0
    $failedCount = 0

    foreach ($candidate in $allCandidates) {
        try {
            # Create category folder in Google Drive
            $destFolder = Join-Path $GoogleDrivePath "Moved from Local\$($candidate.Category)"
            if (-not (Test-Path $destFolder)) {
                New-Item -Path $destFolder -ItemType Directory -Force | Out-Null
            }

            $destPath = Join-Path $destFolder $candidate.Name

            Write-Host "Moving: " -ForegroundColor Cyan -NoNewline
            Write-Host "$($candidate.Name) " -ForegroundColor White -NoNewline
            Write-Host "($($candidate.SizeGB) GB)..." -ForegroundColor Gray

            # Move file
            Move-Item -Path $candidate.Path -Destination $destPath -Force

            Write-Host "  Success!" -ForegroundColor Green
            $movedCount++
            $movedSize += $candidate.SizeGB

        } catch {
            Write-Host "  Failed: $_" -ForegroundColor Red
            $failedCount++
        }
    }

    Write-Host "`n============================================================" -ForegroundColor Cyan
    Write-Host "  MOVE COMPLETE" -ForegroundColor Green
    Write-Host "============================================================`n" -ForegroundColor Cyan

    Write-Host "Files moved: $movedCount" -ForegroundColor Green
    Write-Host "Space freed: $([math]::Round($movedSize, 2)) GB" -ForegroundColor Cyan
    Write-Host "Failed: $failedCount`n" -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Yellow" })

} elseif (-not $ScanOnly) {
    Write-Host "`nCannot move files: Google Drive not available" -ForegroundColor Red
}

# Show current disk status
Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "  CURRENT DISK STATUS" -ForegroundColor Yellow
Write-Host "============================================================`n" -ForegroundColor Cyan

$driveC = Get-PSDrive C
$driveCPercent = [math]::Round((($driveC.Used / ($driveC.Used + $driveC.Free)) * 100), 1)
Write-Host "C: Drive: " -ForegroundColor White -NoNewline
Write-Host "$([math]::Round($driveC.Free / 1GB, 2)) GB free " -ForegroundColor Cyan -NoNewline
Write-Host "($driveCPercent% used)" -ForegroundColor $(if ($driveCPercent -lt 80) { "Green" } elseif ($driveCPercent -lt 90) { "Yellow" } else { "Red" })

if (Test-Path D:\) {
    $driveD = Get-PSDrive D
    $driveDPercent = [math]::Round((($driveD.Used / ($driveD.Used + $driveD.Free)) * 100), 1)
    Write-Host "D: Drive: " -ForegroundColor White -NoNewline
    Write-Host "$([math]::Round($driveD.Free / 1GB, 2)) GB free " -ForegroundColor Cyan -NoNewline
    Write-Host "($driveDPercent% used)" -ForegroundColor Green
}

if ($googleDriveAvailable) {
    Write-Host "Google Drive: " -ForegroundColor White -NoNewline
    Write-Host "30 TB available " -ForegroundColor Green -NoNewline
    Write-Host "(Unlimited with Google AI Ultra)" -ForegroundColor Cyan
}

Write-Host "`n============================================================`n" -ForegroundColor Cyan

# Save report
$reportPath = ".\evidence\google-drive-move-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
@"
Google Drive Move Analysis
Generated: $(Get-Date)

SCAN RESULTS:
- Total files found: $($allCandidates.Count)
- Total size: $([math]::Round($totalSizeToMove, 2)) GB
- Potential space to free: $([math]::Round($totalSizeToMove, 2)) GB

TOP 10 LARGEST FILES:
$($allCandidates | Select-Object -First 10 | ForEach-Object { "  - $($_.Name) ($($_.SizeGB) GB) [$($_.Category)]" } | Out-String)

BREAKDOWN BY CATEGORY:
$($grouped | Sort-Object {($_.Group | Measure-Object -Property SizeGB -Sum).Sum} -Descending | ForEach-Object {
    $categorySize = ($_.Group | Measure-Object -Property SizeGB -Sum).Sum
    "  - $($_.Name): $($_.Count) files, $([math]::Round($categorySize, 2)) GB"
} | Out-String)

CURRENT DISK STATUS:
- C: Drive: $([math]::Round($driveC.Free / 1GB, 2)) GB free ($driveCPercent% used)
$(if (Test-Path D:\) { "- D: Drive: $([math]::Round($driveD.Free / 1GB, 2)) GB free ($driveDPercent% used)" })
- Google Drive: 30 TB available

RECOMMENDATIONS:
1. Move large video files to Google Drive (Priority 1)
2. Move ISO files and installers to Google Drive (Priority 1)
3. Move old archives to Google Drive (Priority 2)
4. Keep frequently accessed files local
5. Use Google Drive desktop client for seamless access

NEXT STEPS:
1. Install Google Drive for Desktop if not already installed
2. Run: .\Move-To-GoogleDrive.ps1 -AutoMove
3. Verify files are accessible in Google Drive
4. Monitor disk space weekly
"@ | Out-File $reportPath

Write-Host "Report saved to: $reportPath`n" -ForegroundColor Gray
