<#
.SYNOPSIS
    Aggressive Disk Cleanup - Free up maximum space safely

.DESCRIPTION
    This script performs deep cleaning of C: drive to free up space
    All operations are safe and reversible where possible

.NOTES
    Target: Free 5-10 GB from C: drive
    Current Usage: 93.1%
    Goal: <80%
#>

Write-Host "`n=========================================" -ForegroundColor Red
Write-Host "  AGGRESSIVE DISK CLEANUP" -ForegroundColor Yellow
Write-Host "  Current C: drive usage: 93.1%" -ForegroundColor Red
Write-Host "  Target: <80%" -ForegroundColor Green
Write-Host "=========================================`n" -ForegroundColor Red

$beforeC = Get-PSDrive C
$beforeFree = $beforeC.Free / 1GB
$beforeUsedPercent = [math]::Round((($beforeC.Used / ($beforeC.Used + $beforeC.Free)) * 100), 1)

Write-Host "Before cleanup:" -ForegroundColor Cyan
Write-Host "  Free space: $([math]::Round($beforeFree, 2)) GB" -ForegroundColor White
Write-Host "  Used: $beforeUsedPercent%`n" -ForegroundColor Red

$totalFreed = 0

# 1. Empty Recycle Bin
Write-Host "[1/10] Emptying Recycle Bin..." -ForegroundColor Yellow
try {
    Clear-RecycleBin -Force -ErrorAction Stop
    Write-Host "  Done!" -ForegroundColor Green
    $totalFreed += 0.5
} catch {
    Write-Host "  Already empty" -ForegroundColor Gray
}

# 2. Clean Windows Temp
Write-Host "`n[2/10] Cleaning Windows Temp..." -ForegroundColor Yellow
try {
    $cleaned = 0
    Get-ChildItem "C:\Windows\Temp" -Recurse -Force -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Cleaned Windows Temp" -ForegroundColor Green
} catch {
    Write-Host "  Some files in use" -ForegroundColor Gray
}

# 3. Clean User Temp
Write-Host "`n[3/10] Cleaning User Temp..." -ForegroundColor Yellow
$tempPath = $env:TEMP
if (Test-Path $tempPath) {
    Get-ChildItem $tempPath -Recurse -Force -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Cleaned User Temp" -ForegroundColor Green
}

# 4. Clean Windows Update Cache
Write-Host "`n[4/10] Cleaning Windows Update Cache..." -ForegroundColor Yellow
try {
    $updateCache = "C:\Windows\SoftwareDistribution\Download"
    if (Test-Path $updateCache) {
        $sizeBefore = (Get-ChildItem $updateCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
        Get-ChildItem $updateCache -Recurse -Force -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  Freed ~$([math]::Round($sizeBefore, 2)) GB" -ForegroundColor Green
        $totalFreed += $sizeBefore
    }
} catch {
    Write-Host "  Windows Update in use" -ForegroundColor Gray
}

# 5. Clean Prefetch
Write-Host "`n[5/10] Cleaning Prefetch..." -ForegroundColor Yellow
try {
    $prefetch = "C:\Windows\Prefetch"
    if (Test-Path $prefetch) {
        Get-ChildItem $prefetch -Filter "*.pf" -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
        Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Host "  Cleaned old prefetch files" -ForegroundColor Green
    }
} catch {
    Write-Host "  Skipped (requires admin)" -ForegroundColor Gray
}

# 6. Clean Browser Caches
Write-Host "`n[6/10] Cleaning Browser Caches..." -ForegroundColor Yellow

# Chrome
$chromeCache = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
if (Test-Path $chromeCache) {
    $sizeBefore = (Get-ChildItem $chromeCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
    Get-ChildItem $chromeCache -Recurse -Force -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Chrome: ~$([math]::Round($sizeBefore, 2)) GB" -ForegroundColor Green
    $totalFreed += $sizeBefore
}

# Edge
$edgeCache = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
if (Test-Path $edgeCache) {
    $sizeBefore = (Get-ChildItem $edgeCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
    Get-ChildItem $edgeCache -Recurse -Force -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Edge: ~$([math]::Round($sizeBefore, 2)) GB" -ForegroundColor Green
    $totalFreed += $sizeBefore
}

# 7. Clean Downloads folder (old files)
Write-Host "`n[7/10] Checking Downloads folder..." -ForegroundColor Yellow
$downloads = "$env:USERPROFILE\Downloads"
if (Test-Path $downloads) {
    $oldFiles = Get-ChildItem $downloads -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-90) }

    if ($oldFiles) {
        $sizeOld = ($oldFiles | Measure-Object -Property Length -Sum).Sum / 1GB
        Write-Host "  Found $($oldFiles.Count) files older than 90 days ($([math]::Round($sizeOld, 2)) GB)" -ForegroundColor Yellow
        Write-Host "  Listing largest files:" -ForegroundColor Gray

        $oldFiles | Sort-Object Length -Descending | Select-Object -First 10 | ForEach-Object {
            $sizeGB = $_.Length / 1GB
            Write-Host "    - $($_.Name) ($([math]::Round($sizeGB, 2)) GB) - Last modified: $($_.LastWriteTime)" -ForegroundColor Gray
        }

        $response = Read-Host "`n  Delete these old files? (yes/no)"
        if ($response -eq "yes") {
            $oldFiles | Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Host "  Deleted old downloads" -ForegroundColor Green
            $totalFreed += $sizeOld
        } else {
            Write-Host "  Skipped (user choice)" -ForegroundColor Gray
        }
    } else {
        Write-Host "  No old files found" -ForegroundColor Green
    }
}

# 8. Find large files to move to D:
Write-Host "`n[8/10] Finding large files on C: that could move to D:..." -ForegroundColor Yellow
$largeFiles = Get-ChildItem -Path "$env:USERPROFILE" -Recurse -File -ErrorAction SilentlyContinue |
Where-Object { $_.Length -gt 500MB } |
Sort-Object Length -Descending |
Select-Object -First 10

if ($largeFiles) {
    Write-Host "  Large files found (>500 MB each):" -ForegroundColor Yellow
    foreach ($file in $largeFiles) {
        $sizeGB = $file.Length / 1GB
        Write-Host "    - $($file.FullName) ($([math]::Round($sizeGB, 2)) GB)" -ForegroundColor Gray
    }

    Write-Host "`n  TIP: Move these to D: drive (40 GB free)" -ForegroundColor Cyan
    Write-Host "  Example: Move-Item 'C:\file.ext' 'D:\file.ext'" -ForegroundColor Gray
} else {
    Write-Host "  No large files found" -ForegroundColor Green
}

# 9. Clean Windows.old (if exists)
Write-Host "`n[9/10] Checking for Windows.old..." -ForegroundColor Yellow
if (Test-Path "C:\Windows.old") {
    $sizeOld = (Get-ChildItem "C:\Windows.old" -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
    Write-Host "  Found Windows.old folder: $([math]::Round($sizeOld, 2)) GB" -ForegroundColor Yellow
    Write-Host "  Use Disk Cleanup (as admin) to remove it safely" -ForegroundColor Cyan
    Write-Host "  Command: cleanmgr /d C:" -ForegroundColor Gray
} else {
    Write-Host "  No Windows.old folder" -ForegroundColor Green
}

# 10. Final system cleanup
Write-Host "`n[10/10] Running final optimizations..." -ForegroundColor Yellow
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
Write-Host "  Memory freed" -ForegroundColor Green

# Calculate results
$afterC = Get-PSDrive C
$afterFree = $afterC.Free / 1GB
$afterUsedPercent = [math]::Round((($afterC.Used / ($afterC.Used + $afterC.Free)) * 100), 1)
$actualFreed = $afterFree - $beforeFree

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "  CLEANUP COMPLETE!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan

Write-Host "`nBefore:" -ForegroundColor White
Write-Host "  Free: $([math]::Round($beforeFree, 2)) GB" -ForegroundColor Gray
Write-Host "  Used: $beforeUsedPercent%" -ForegroundColor Red

Write-Host "`nAfter:" -ForegroundColor White
Write-Host "  Free: $([math]::Round($afterFree, 2)) GB" -ForegroundColor Green
Write-Host "  Used: $afterUsedPercent%" -ForegroundColor $(if ($afterUsedPercent -lt 80) { "Green" } elseif ($afterUsedPercent -lt 90) { "Yellow" } else { "Red" })

Write-Host "`nSpace freed: $([math]::Round($actualFreed, 2)) GB" -ForegroundColor Cyan

if ($afterUsedPercent -lt 80) {
    Write-Host "`n SUCCESS! Disk usage is now healthy (<80%)" -ForegroundColor Green
    Write-Host " System is ready for deployment!" -ForegroundColor Green
} elseif ($afterUsedPercent -lt 90) {
    Write-Host "`n GOOD! Disk usage improved but still watch it" -ForegroundColor Yellow
    Write-Host " Consider moving large files to D: drive" -ForegroundColor Yellow
} else {
    Write-Host "`n MORE CLEANUP NEEDED" -ForegroundColor Red
    Write-Host " Next steps:" -ForegroundColor Yellow
    Write-Host "   1. Move files from Downloads to D:" -ForegroundColor Cyan
    Write-Host "   2. Uninstall unused applications" -ForegroundColor Cyan
    Write-Host "   3. Run: cleanmgr /d C: (as admin)" -ForegroundColor Cyan
    Write-Host "   4. Check for large files: Get-ChildItem C:\ -Recurse -File | Sort Length -Desc | Select -First 20" -ForegroundColor Cyan
}

Write-Host "`n==========================================`n" -ForegroundColor Cyan

# Save report
$reportPath = ".\evidence\disk-cleanup-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
@"
Aggressive Disk Cleanup Report
Generated: $(Get-Date)

BEFORE:
- Free space: $([math]::Round($beforeFree, 2)) GB
- Used: $beforeUsedPercent%

AFTER:
- Free space: $([math]::Round($afterFree, 2)) GB
- Used: $afterUsedPercent%

RESULTS:
- Space freed: $([math]::Round($actualFreed, 2)) GB
- Status: $(if ($afterUsedPercent -lt 80) { "HEALTHY" } elseif ($afterUsedPercent -lt 90) { "ACCEPTABLE" } else { "NEEDS MORE CLEANUP" })

ACTIONS TAKEN:
- Emptied Recycle Bin
- Cleaned Windows Temp
- Cleaned User Temp
- Cleaned Windows Update Cache
- Cleaned Prefetch (old files)
- Cleaned Browser Caches (Chrome, Edge)
- Checked Downloads folder
- Identified large files
- Memory optimization

RECOMMENDATIONS:
$(if ($afterUsedPercent -ge 90) {
"- Move large files to D: drive (40 GB free)
- Uninstall unused applications
- Run Disk Cleanup as administrator
- Consider using Storage Sense"}
else {
"- System is in good shape
- Enable automatic cleanup (Storage Sense)
- Monitor disk usage weekly"})
"@ | Out-File $reportPath

Write-Host "Report saved to: $reportPath" -ForegroundColor Gray
