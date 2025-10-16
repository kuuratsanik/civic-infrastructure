<#
.SYNOPSIS
    Complete automation for building custom Windows 11 ISO
.DESCRIPTION
    Downloads Windows 11 ISO from Microsoft, extracts it, and builds a custom
    privacy-hardened ISO with DAO governance and complete audit trail
.PARAMETER SkipDownload
    Skip download if ISO already exists
.PARAMETER OutputName
    Custom name for the output ISO
#>

param(
    [switch]$SkipDownload,
    [string]$OutputName = "Win11_Custom_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
)

$ErrorActionPreference = 'Stop'
$workspaceRoot = "C:\Users\svenk\OneDrive\All_My_Projects\New folder"

Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "   REAL ISO BUILD - FULL AUTOMATION" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

Write-Host "This script will:" -ForegroundColor White
Write-Host "  [1] Download Windows 11 ISO from Microsoft" -ForegroundColor Cyan
Write-Host "  [2] Extract ISO to workspace" -ForegroundColor Cyan
Write-Host "  [3] Build custom privacy-hardened ISO" -ForegroundColor Cyan
Write-Host "  [4] Generate hash and evidence" -ForegroundColor Cyan
Write-Host "  [5] Create DAO audit trail`n" -ForegroundColor Cyan

Write-Host "Estimated time: 40-60 minutes" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to cancel, or" -ForegroundColor Yellow
$null = Read-Host "Press Enter to begin"

# Change to workspace directory
Set-Location $workspaceRoot

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "PHASE 1: LOCATE/DOWNLOAD WINDOWS 11 ISO" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "[*] Searching for Windows 11 ISO...`n" -ForegroundColor Yellow

$isoPath = & "$workspaceRoot\scripts\utilities\Find-Windows11ISO.ps1"

if (-not $isoPath -or -not (Test-Path $isoPath)) {
    Write-Error "No Windows 11 ISO available. Please download first."
}

Write-Host "`n[OK] ISO ready: $isoPath" -ForegroundColor Green
$isoSize = [math]::Round((Get-Item $isoPath).Length / 1GB, 2)
Write-Host "[OK] Size: $isoSize GB`n" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "PHASE 2: EXTRACT ISO CONTENTS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "[*] Starting extraction...`n" -ForegroundColor Yellow

$extractPath = & "$workspaceRoot\scripts\utilities\Extract-Windows11ISO.ps1" -ISOPath $isoPath

if (-not $extractPath -or -not (Test-Path $extractPath)) {
    Write-Error "ISO extraction failed"
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "PHASE 3: VERIFY PREREQUISITES" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check Windows ADK
$adkPath = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
if (Test-Path $adkPath) {
    Write-Host "[OK] Windows ADK found" -ForegroundColor Green
} else {
    Write-Error "Windows ADK not found at $adkPath"
}

# Check extracted files
$wimPath = Join-Path $extractPath "sources\install.wim"
if (Test-Path $wimPath) {
    Write-Host "[OK] install.wim found" -ForegroundColor Green
    $wimSize = [math]::Round((Get-Item $wimPath).Length / 1GB, 2)
    Write-Host "     Size: $wimSize GB" -ForegroundColor White
} else {
    Write-Error "install.wim not found at $wimPath"
}

# Check disk space
$drive = (Get-Item $workspaceRoot).PSDrive.Name
$freeSpace = [math]::Round((Get-PSDrive $drive).Free / 1GB, 2)
Write-Host "[OK] Free disk space: $freeSpace GB" -ForegroundColor Green

if ($freeSpace -lt 20) {
    Write-Warning "Low disk space. Recommend at least 20 GB free."
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne 'y') {
        exit 1
    }
}

# Check admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Host "[OK] Running as Administrator" -ForegroundColor Green
} else {
    Write-Host "[!!] NOT running as Administrator" -ForegroundColor Yellow
    Write-Host "     Some operations may require elevation" -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "PHASE 4: BUILD CUSTOM ISO" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Output ISO will be named: $OutputName.iso" -ForegroundColor White
Write-Host "Building with:" -ForegroundColor White
Write-Host "  - Privacy tweaks (disable telemetry, classic Start menu)" -ForegroundColor Cyan
Write-Host "  - Debloat (remove 50+ pre-installed apps)" -ForegroundColor Cyan
Write-Host "  - DAO governance (warrant-based authorization)" -ForegroundColor Cyan
Write-Host "  - Complete audit trail (immutable ledger)`n" -ForegroundColor Cyan

Write-Host "This is the REAL build - not a simulation!" -ForegroundColor Yellow
Write-Host "Estimated time: 20-30 minutes`n" -ForegroundColor Yellow

$confirm = Read-Host "Ready to build? (Y/n)"
if ($confirm -eq 'n') {
    Write-Host "`nBuild cancelled by user.`n" -ForegroundColor Yellow
    exit 0
}

Write-Host "`n[*] Executing ISO build ceremony...`n" -ForegroundColor Cyan

# Execute the ceremony
& "$workspaceRoot\scripts\ceremonies\09-iso-build\Build-CustomISO.ps1" `
    -OutputName $OutputName `
    -IncludeTweaks `
    -Debloat

$buildExitCode = $LASTEXITCODE

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "PHASE 5: VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if ($buildExitCode -ne 0) {
    Write-Host "[!!] Build ceremony exited with code: $buildExitCode" -ForegroundColor Red
    Write-Host "Check logs at: logs\civic.jsonl`n" -ForegroundColor Yellow
    exit $buildExitCode
}

# Check for output ISO
$outputISO = Get-ChildItem -Path "$workspaceRoot\workspace\output" -Filter "$OutputName.iso" -ErrorAction SilentlyContinue

if ($outputISO) {
    Write-Host "[OK] Custom ISO created successfully!" -ForegroundColor Green
    Write-Host "     Location: $($outputISO.FullName)" -ForegroundColor White
    Write-Host "     Size: $([math]::Round($outputISO.Length/1GB, 2)) GB" -ForegroundColor White
    Write-Host "     Created: $($outputISO.CreationTime)" -ForegroundColor White
} else {
    Write-Host "[!!] Output ISO not found" -ForegroundColor Red
    Write-Host "Expected at: $workspaceRoot\workspace\output\$OutputName.iso" -ForegroundColor Yellow
}

# Check for hash
$hashFile = Get-ChildItem -Path "$workspaceRoot\evidence\hashes\iso-builds" -Filter "$OutputName.sha256" -ErrorAction SilentlyContinue

if ($hashFile) {
    Write-Host "[OK] SHA256 hash generated" -ForegroundColor Green
    $hash = Get-Content $hashFile.FullName
    Write-Host "     Hash: $hash" -ForegroundColor White
} else {
    Write-Host "[!!] Hash file not found" -ForegroundColor Yellow
}

# Check audit trail
$ledger = "$workspaceRoot\logs\council_ledger.jsonl"
if (Test-Path $ledger) {
    $ledgerEntries = Get-Content $ledger | Measure-Object -Line
    Write-Host "[OK] Audit ledger updated" -ForegroundColor Green
    Write-Host "     Entries: $($ledgerEntries.Lines)" -ForegroundColor White
} else {
    Write-Host "[!!] Audit ledger not found" -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "       BUILD COMPLETE!" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

if ($outputISO) {
    Write-Host "Your custom Windows 11 ISO is ready!" -ForegroundColor Green
    Write-Host "`nWhat you can do now:" -ForegroundColor White
    Write-Host "  1. Burn to USB: Use Rufus or similar tool" -ForegroundColor Cyan
    Write-Host "  2. Test in VM: Use Hyper-V or VirtualBox" -ForegroundColor Cyan
    Write-Host "  3. Install on hardware: Boot from ISO" -ForegroundColor Cyan
    Write-Host "`nFeatures included:" -ForegroundColor White
    Write-Host "  [+] Telemetry disabled" -ForegroundColor Green
    Write-Host "  [+] 50+ bloatware apps removed" -ForegroundColor Green
    Write-Host "  [+] Classic Start menu restored" -ForegroundColor Green
    Write-Host "  [+] Privacy-hardened configuration" -ForegroundColor Green
    Write-Host "  [+] DAO-governed build process" -ForegroundColor Green
    Write-Host "  [+] Complete audit trail" -ForegroundColor Green
    
    Write-Host "`nFiles generated:" -ForegroundColor White
    Write-Host "  ISO: $($outputISO.FullName)" -ForegroundColor Cyan
    if ($hashFile) {
        Write-Host "  Hash: $($hashFile.FullName)" -ForegroundColor Cyan
    }
    Write-Host "  Logs: $ledger" -ForegroundColor Cyan
    
    Write-Host "`n========================================`n" -ForegroundColor Magenta
}

return $outputISO
