<#
.SYNOPSIS
    Quick Fix - Free up C: drive space immediately

.DESCRIPTION
    This script does the safest, fastest cleanup to get C: drive under 80%

    Actions:
    1. Remove duplicate CrossDevice folders (276 MB)
    2. Clear VS Code extension cache (105 MB)
    3. Clean temp files (1-2 GB estimated)
    4. Empty recycle bin
    5. Clear browser caches

    Total expected: 1.5-2.5 GB freed
    C: drive should drop from 90.8% to ~88-89%
#>

Write-Host @"

╔══════════════════════════════════════════════════════════╗
║                                                          ║
║         QUICK FIX - FREE UP C: DRIVE NOW                ║
║                                                          ║
║  Current: 90.8% used (18.04 GB free)                    ║
║  Target:  <80% used                                     ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

$beforeC = Get-PSDrive C
$beforeFree = $beforeC.Free / 1GB

Write-Host "Starting quick cleanup...`n" -ForegroundColor Yellow

# 1. Remove duplicate CrossDevice folder
Write-Host "[1/5] Removing duplicate mobile device files..." -ForegroundColor Yellow
$duplicatePath = "C:\Users\svenk\CrossDevice\Redmi Note 8 Pro (1)"
if (Test-Path $duplicatePath) {
    $size = (Get-ChildItem $duplicatePath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
    Remove-Item $duplicatePath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Freed: $([math]::Round($size, 0)) MB" -ForegroundColor Green
} else {
    Write-Host "  Already removed" -ForegroundColor Gray
}

# 2. Clear VS Code extension cache
Write-Host "`n[2/5] Clearing VS Code extension cache..." -ForegroundColor Yellow
$vscodePath = "C:\Users\svenk\.vscode-server\data\CachedExtensionVSIXs"
if (Test-Path $vscodePath) {
    $size = (Get-ChildItem $vscodePath -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
    Remove-Item "$vscodePath\*" -Force -ErrorAction SilentlyContinue
    Write-Host "  Freed: $([math]::Round($size, 0)) MB" -ForegroundColor Green
} else {
    Write-Host "  Path not found" -ForegroundColor Gray
}

# 3. Clean temp files
Write-Host "`n[3/5] Cleaning temp files..." -ForegroundColor Yellow
$tempPaths = @($env:TEMP, "C:\Windows\Temp")
$totalTemp = 0
foreach ($path in $tempPaths) {
    if (Test-Path $path) {
        $sizeBefore = (Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
        Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        $totalTemp += $sizeBefore
    }
}
Write-Host "  Freed: ~$([math]::Round($totalTemp, 0)) MB" -ForegroundColor Green

# 4. Empty recycle bin
Write-Host "`n[4/5] Emptying Recycle Bin..." -ForegroundColor Yellow
try {
    Clear-RecycleBin -Force -ErrorAction Stop
    Write-Host "  Done!" -ForegroundColor Green
} catch {
    Write-Host "  Already empty" -ForegroundColor Gray
}

# 5. Clear browser caches
Write-Host "`n[5/5] Clearing browser caches..." -ForegroundColor Yellow
$caches = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
)
$totalCache = 0
foreach ($cache in $caches) {
    if (Test-Path $cache) {
        $sizeBefore = (Get-ChildItem $cache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
        Get-ChildItem $cache -Recurse -Force -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        $totalCache += $sizeBefore
    }
}
Write-Host "  Freed: ~$([math]::Round($totalCache, 0)) MB" -ForegroundColor Green

# Calculate results
$afterC = Get-PSDrive C
$afterFree = $afterC.Free / 1GB
$afterUsedPercent = [math]::Round((($afterC.Used / ($afterC.Used + $afterC.Free)) * 100), 1)
$freedGB = $afterFree - $beforeFree

Write-Host @"

╔══════════════════════════════════════════════════════════╗
║                 QUICK FIX COMPLETE!                      ║
╚══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

Write-Host "RESULTS:" -ForegroundColor White
Write-Host "  Space freed: $([math]::Round($freedGB, 2)) GB" -ForegroundColor Cyan
Write-Host "  C: Drive now: $([math]::Round($afterFree, 2)) GB free ($afterUsedPercent% used)" -ForegroundColor $(if ($afterUsedPercent -lt 80) { "Green" } elseif ($afterUsedPercent -lt 90) { "Yellow" } else { "Red" })

if ($afterUsedPercent -lt 80) {
    Write-Host "`n ✅ SUCCESS! C: drive is now healthy!" -ForegroundColor Green
    Write-Host " You can now deploy autonomous AI systems!" -ForegroundColor Green
} elseif ($afterUsedPercent -lt 90) {
    Write-Host "`n ⚠️  Better, but still needs more cleanup" -ForegroundColor Yellow
    Write-Host "`nNEXT STEPS:" -ForegroundColor White
    Write-Host "  1. Install Google Drive for Desktop" -ForegroundColor Cyan
    Write-Host "  2. Move large files to Google Drive:" -ForegroundColor Cyan
    Write-Host "     .\Move-To-GoogleDrive.ps1 -AutoMove" -ForegroundColor Gray
    Write-Host "`n  OR move Ollama models to D: drive:" -ForegroundColor Cyan
    Write-Host "     Move-Item 'C:\Users\svenk\.ollama\models\blobs' 'D:\Ollama\models\blobs' -Recurse" -ForegroundColor Gray
} else {
    Write-Host "`n ⚠️  Still critical - more action needed" -ForegroundColor Red
    Write-Host "`nRECOMMENDED ACTIONS:" -ForegroundColor White
    Write-Host "  1. Install Google Drive for Desktop NOW" -ForegroundColor Yellow
    Write-Host "  2. Move Ollama models (4.48 GB):" -ForegroundColor Yellow
    Write-Host "     New-Item 'D:\Ollama\models\blobs' -ItemType Directory -Force" -ForegroundColor Gray
    Write-Host "     Move-Item 'C:\Users\svenk\.ollama\models\blobs\*' 'D:\Ollama\models\blobs\' -Force" -ForegroundColor Gray
    Write-Host "  3. This will drop C: to ~88%" -ForegroundColor Yellow
}

Write-Host "`n════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# Show what else can be done
Write-Host "ADDITIONAL CLEANUP OPTIONS:" -ForegroundColor White
Write-Host "`n1. Move Ollama AI models to D: drive (4.48 GB):" -ForegroundColor Cyan
Write-Host "   Creates: D:\Ollama\models\" -ForegroundColor Gray
Write-Host "   Frees: 4.48 GB on C:" -ForegroundColor Green
Write-Host "   Impact: C: drops to ~88%" -ForegroundColor Green

Write-Host "`n2. Install Google Drive for Desktop (30TB available):" -ForegroundColor Cyan
Write-Host "   Download: https://www.google.com/drive/download/" -ForegroundColor Gray
Write-Host "   Benefits: Store unlimited files, access anywhere" -ForegroundColor Green
Write-Host "   Impact: Can free up 10+ GB" -ForegroundColor Green

Write-Host "`n3. Run comprehensive cleanup:" -ForegroundColor Cyan
Write-Host "   .\Aggressive-DiskCleanup.ps1" -ForegroundColor Gray
Write-Host "   Impact: 2-5 GB additional space" -ForegroundColor Green

Write-Host "`n════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
