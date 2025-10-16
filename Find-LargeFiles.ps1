<#
.SYNOPSIS
    Find Large Files - Help move files from C: to D: drive

.DESCRIPTION
    Identifies large files on C: drive that can be moved to D: (40 GB free)
    while preserving all important user data in their original locations.
#>

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  LARGE FILE FINDER" -ForegroundColor Yellow
Write-Host "  C: drive: 90.6% (needs <80%)" -ForegroundColor Red
Write-Host "  D: drive: 40 GB FREE" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Scanning for large files on C: drive..." -ForegroundColor Yellow
Write-Host "(This may take a few minutes)`n" -ForegroundColor Gray

# Find large files
$largeFiles = Get-ChildItem -Path "C:\Users\$env:USERNAME" -File -Recurse -ErrorAction SilentlyContinue |
Where-Object { $_.Length -gt 100MB -and $_.DirectoryName -notlike "*\OneDrive\*" } |
Sort-Object Length -Descending |
Select-Object -First 30

if ($largeFiles) {
    Write-Host "LARGE FILES FOUND (>100 MB each):" -ForegroundColor Yellow
    Write-Host "====================================`n" -ForegroundColor Gray

    $totalSize = 0
    $fileList = @()

    foreach ($file in $largeFiles) {
        $sizeGB = [math]::Round($file.Length / 1GB, 2)
        $sizeMB = [math]::Round($file.Length / 1MB, 0)
        $totalSize += $file.Length

        $fileInfo = @{
            Path     = $file.FullName
            Name     = $file.Name
            SizeGB   = $sizeGB
            SizeMB   = $sizeMB
            Modified = $file.LastWriteTime
        }
        $fileList += $fileInfo

        $displaySize = if ($sizeGB -ge 1) { "$sizeGB GB" } else { "$sizeMB MB" }

        Write-Host "$displaySize - $($file.Name)" -ForegroundColor Cyan
        Write-Host "  Location: $($file.DirectoryName)" -ForegroundColor Gray
        Write-Host "  Modified: $($file.LastWriteTime)" -ForegroundColor Gray
        Write-Host ""
    }

    $totalGB = [math]::Round($totalSize / 1GB, 2)

    Write-Host "====================================`n" -ForegroundColor Gray
    Write-Host "SUMMARY:" -ForegroundColor White
    Write-Host "  Total files found: $($largeFiles.Count)" -ForegroundColor Cyan
    Write-Host "  Total size: $totalGB GB" -ForegroundColor Cyan
    Write-Host "`n  If moved to D:, C: usage would drop to ~$(90.6 - ($totalGB / 197 * 100))%" -ForegroundColor Green

    Write-Host "`n====================================`n" -ForegroundColor Gray
    Write-Host "RECOMMENDATIONS:" -ForegroundColor Yellow

    # Group by type
    $byExtension = $largeFiles | Group-Object Extension | Sort-Object Count -Descending

    Write-Host "`nFile types found:" -ForegroundColor White
    foreach ($group in $byExtension) {
        $groupSize = ($group.Group | Measure-Object -Property Length -Sum).Sum / 1GB
        Write-Host "  $($group.Name): $($group.Count) files ($([math]::Round($groupSize, 2)) GB)" -ForegroundColor Gray
    }

    Write-Host "`n====================================`n" -ForegroundColor Gray
    Write-Host "TO MOVE FILES TO D: DRIVE:" -ForegroundColor Yellow
    Write-Host "`nOption 1 - Move specific file:" -ForegroundColor Cyan
    Write-Host "  Move-Item 'C:\path\to\file.ext' 'D:\path\to\file.ext'" -ForegroundColor White

    Write-Host "`nOption 2 - Create organized folders on D::" -ForegroundColor Cyan
    Write-Host "  New-Item -Path 'D:\LargeFiles' -ItemType Directory" -ForegroundColor White
    Write-Host "  Move-Item 'C:\Users\...\file.ext' 'D:\LargeFiles\'" -ForegroundColor White

    Write-Host "`nOption 3 - Let me help you move them:" -ForegroundColor Cyan
    $response = Read-Host "`nWould you like me to prepare a move script? (yes/no)"

    if ($response -eq "yes") {
        $scriptPath = ".\Move-LargeFiles-To-D.ps1"

        $moveScript = @"
# Auto-generated script to move large files to D: drive
# Generated: $(Get-Date)

Write-Host "Creating organized structure on D: drive..." -ForegroundColor Yellow

# Create folders
`$folders = @('LargeFiles\Videos', 'LargeFiles\ISOs', 'LargeFiles\Archives', 'LargeFiles\Other')
foreach (`$folder in `$folders) {
    New-Item -Path "D:\`$folder" -ItemType Directory -Force | Out-Null
}

Write-Host "Moving files..." -ForegroundColor Yellow

# Move commands (uncomment to execute)
"@

        foreach ($file in $fileList) {
            $ext = [System.IO.Path]::GetExtension($file.Name).ToLower()
            $destination = switch ($ext) {
                { $_ -in '.mp4', '.avi', '.mkv', '.mov' } { 'D:\LargeFiles\Videos\' }
                { $_ -in '.iso', '.img' } { 'D:\LargeFiles\ISOs\' }
                { $_ -in '.zip', '.rar', '.7z' } { 'D:\LargeFiles\Archives\' }
                default { 'D:\LargeFiles\Other\' }
            }

            $moveScript += "`n# $($file.SizeMB) MB - $($file.Name)"
            $moveScript += "`n# Move-Item '$($file.Path)' '$destination'"
        }

        $moveScript += @"

Write-Host "`nDone! Files moved to D: drive" -ForegroundColor Green
Write-Host "Check D:\LargeFiles for your files" -ForegroundColor Cyan
"@

        $moveScript | Out-File $scriptPath -Encoding UTF8

        Write-Host "`nMove script created: $scriptPath" -ForegroundColor Green
        Write-Host "`nTo execute:" -ForegroundColor Yellow
        Write-Host "  1. Review the script (it has moves commented out for safety)" -ForegroundColor White
        Write-Host "  2. Uncomment the Move-Item lines you want to execute" -ForegroundColor White
        Write-Host "  3. Run: .\$scriptPath" -ForegroundColor White
    }

} else {
    Write-Host "No large files found (>100 MB)" -ForegroundColor Green
    Write-Host "Your disk usage might be from many small files." -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  CURRENT DISK STATUS" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

$driveC = Get-PSDrive C
$driveD = Get-PSDrive D

$cFree = [math]::Round($driveC.Free / 1GB, 2)
$cUsed = [math]::Round($driveC.Used / 1GB, 2)
$cPercent = [math]::Round((($driveC.Used / ($driveC.Used + $driveC.Free)) * 100), 1)

$dFree = [math]::Round($driveD.Free / 1GB, 2)
$dUsed = [math]::Round($driveD.Used / 1GB, 2)
$dPercent = [math]::Round((($driveD.Used / ($driveD.Used + $driveD.Free)) * 100), 1)

Write-Host "`nC: Drive (System):" -ForegroundColor White
Write-Host "  Free: $cFree GB" -ForegroundColor $(if ($cFree -lt 20) { "Red" } else { "Yellow" })
Write-Host "  Used: $cUsed GB ($cPercent%)" -ForegroundColor $(if ($cPercent -gt 90) { "Red" } elseif ($cPercent -gt 80) { "Yellow" } else { "Green" })

Write-Host "`nD: Drive (Storage):" -ForegroundColor White
Write-Host "  Free: $dFree GB" -ForegroundColor Green
Write-Host "  Used: $dUsed GB ($dPercent%)" -ForegroundColor Green

Write-Host "`n========================================`n" -ForegroundColor Cyan

# Save report
$reportPath = ".\evidence\large-files-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$fileCount = if ($largeFiles) { $largeFiles.Count } else { 0 }
$totalSizeText = if ($largeFiles) { "$totalGB GB" } else { "0 GB" }

@"
LARGE FILES REPORT
Generated: $(Get-Date)

FILES FOUND: $fileCount
TOTAL SIZE: $totalSizeText

CURRENT STATUS:
C: Drive - Free: $cFree GB, Used: $cUsed GB ($cPercent%)
D: Drive - Free: $dFree GB, Used: $dUsed GB ($dPercent%)

LARGE FILES (>100 MB):
$(if ($largeFiles) {
    foreach ($file in $fileList) {
        "- $($file.SizeMB) MB - $($file.Name)`n  Path: $($file.Path)`n  Modified: $($file.Modified)`n"
    }
} else {
    "None found"
})

RECOMMENDATION:
$(if ($cPercent -gt 85) {
    "Move large files to D: drive to free up C: space"
} else {
    "Disk usage is acceptable"
})
"@ | Out-File $reportPath -Encoding UTF8

Write-Host "Report saved: $reportPath" -ForegroundColor Gray
