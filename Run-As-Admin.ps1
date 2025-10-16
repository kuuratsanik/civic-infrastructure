<#
.SYNOPSIS
    Launches Build-RealISO.ps1 with Administrator privileges
.DESCRIPTION
    Restarts the build process as Administrator to complete ISO creation
#>

$ErrorActionPreference = 'Stop'

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  ADMINISTRATOR ELEVATION REQUIRED" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "The ISO build ceremony requires Administrator rights for:" -ForegroundColor White
Write-Host "  - Mounting WIM images (DISM operations)" -ForegroundColor Yellow
Write-Host "  - Applying registry modifications" -ForegroundColor Yellow
Write-Host "  - Creating bootable ISO" -ForegroundColor Yellow
Write-Host "`nGood news: ISO is already downloaded and extracted!" -ForegroundColor Green
Write-Host "Ready to build: C:\Users\svenk\Downloads\Win11_25H2_Estonian_x64.iso`n" -ForegroundColor Green

$scriptPath = "C:\Users\svenk\OneDrive\All_My_Projects\New folder\Build-RealISO.ps1"

Write-Host "Restarting as Administrator...`n" -ForegroundColor Cyan

# Since ISO is already extracted, we can skip directly to ceremony
$ceremonyPath = "C:\Users\svenk\OneDrive\All_My_Projects\New folder\scripts\ceremonies\09-iso-build\Build-CustomISO.ps1"

Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -NoExit -Command cd 'C:\Users\svenk\OneDrive\All_My_Projects\New folder'; Write-Host '`n========================================' -ForegroundColor Green; Write-Host '  BUILDING CUSTOM ISO (AS ADMIN)' -ForegroundColor Green; Write-Host '========================================`n' -ForegroundColor Green; .\scripts\ceremonies\09-iso-build\Build-CustomISO.ps1 -OutputName 'Win11_Custom_EstonianBase' -IncludeTweaks -Debloat" -Verb RunAs

Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  ADMIN WINDOW LAUNCHED!" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

Write-Host "The build will continue in the new Administrator window." -ForegroundColor White
Write-Host "This should take 20-30 minutes.`n" -ForegroundColor Yellow

Write-Host "What's happening:" -ForegroundColor Cyan
Write-Host "  1. Mount install.wim" -ForegroundColor White
Write-Host "  2. Apply privacy tweaks (reg files)" -ForegroundColor White
Write-Host "  3. Remove bloatware (50+ apps)" -ForegroundColor White
Write-Host "  4. Unmount and save changes" -ForegroundColor White
Write-Host "  5. Create bootable ISO" -ForegroundColor White
Write-Host "  6. Generate SHA256 hash" -ForegroundColor White
Write-Host "  7. Create audit trail`n" -ForegroundColor White

Write-Host "Output will be at:" -ForegroundColor Cyan
Write-Host "  workspace\output\Win11_Custom_EstonianBase.iso`n" -ForegroundColor White

Write-Host "========================================`n" -ForegroundColor Magenta
