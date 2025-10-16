<#
.SYNOPSIS
    Extracts Windows 11 ISO to workspace directory
.DESCRIPTION
    Mounts and extracts Windows 11 ISO contents to workspace/windows11-base/
    for use in custom ISO builds
.PARAMETER ISOPath
    Path to the Windows 11 ISO file
.PARAMETER DestinationPath
    Where to extract the ISO contents (defaults to workspace/windows11-base/)
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ISOPath,
    
    [string]$DestinationPath = "C:\Users\svenk\OneDrive\All_My_Projects\New folder\workspace\windows11-base"
)

$ErrorActionPreference = 'Stop'

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   Windows 11 ISO Extraction" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Auto-detect ISO if not provided
if (-not $ISOPath) {
    Write-Host "[*] Searching for Windows 11 ISO..." -ForegroundColor Yellow
    
    $searchPaths = @(
        "$env:USERPROFILE\Downloads\*.iso",
        "C:\Users\svenk\OneDrive\All_My_Projects\New folder\workspace\*.iso"
    )
    
    foreach ($pattern in $searchPaths) {
        $found = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            $ISOPath = $found.FullName
            Write-Host "[OK] Found: $ISOPath" -ForegroundColor Green
            break
        }
    }
    
    if (-not $ISOPath) {
        Write-Error "No Windows 11 ISO found. Please specify -ISOPath or download first."
    }
}

if (-not (Test-Path $ISOPath)) {
    Write-Error "ISO file not found: $ISOPath"
}

Write-Host "`n[1/5] Checking ISO file..." -ForegroundColor Cyan
$isoFile = Get-Item $ISOPath
Write-Host "      File: $($isoFile.Name)" -ForegroundColor White
Write-Host "      Size: $([math]::Round($isoFile.Length/1GB, 2)) GB" -ForegroundColor White

Write-Host "`n[2/5] Preparing destination directory..." -ForegroundColor Cyan
if (Test-Path $DestinationPath) {
    Write-Host "      Cleaning existing directory..." -ForegroundColor Yellow
    Remove-Item -Path $DestinationPath -Recurse -Force
}
New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
Write-Host "      Created: $DestinationPath" -ForegroundColor White

Write-Host "`n[3/5] Mounting ISO..." -ForegroundColor Cyan
$mountResult = Mount-DiskImage -ImagePath $ISOPath -PassThru
$driveLetter = ($mountResult | Get-Volume).DriveLetter

if (-not $driveLetter) {
    Write-Error "Failed to mount ISO"
}

Write-Host "      Mounted at: ${driveLetter}:\" -ForegroundColor White

try {
    Write-Host "`n[4/5] Copying ISO contents..." -ForegroundColor Cyan
    Write-Host "      This may take 5-10 minutes..." -ForegroundColor Yellow
    
    $source = "${driveLetter}:\"
    $fileCount = (Get-ChildItem -Path $source -Recurse -File).Count
    Write-Host "      Files to copy: $fileCount" -ForegroundColor White
    
    # Copy with progress
    robocopy $source $DestinationPath /E /MT:8 /NFL /NDL /NJH /NJS /NC /NS /NP | Out-Null
    
    if ($LASTEXITCODE -ge 8) {
        throw "Robocopy failed with exit code $LASTEXITCODE"
    }
    
    Write-Host "      [OK] All files copied" -ForegroundColor Green
    
} finally {
    Write-Host "`n[5/5] Dismounting ISO..." -ForegroundColor Cyan
    Dismount-DiskImage -ImagePath $ISOPath | Out-Null
    Write-Host "      [OK] ISO dismounted" -ForegroundColor Green
}

# Verify critical files
Write-Host "`n[*] Verifying extraction..." -ForegroundColor Cyan
$criticalFiles = @(
    "sources\install.wim",
    "sources\boot.wim",
    "bootmgr.efi"
)

$allFound = $true
foreach ($file in $criticalFiles) {
    $fullPath = Join-Path $DestinationPath $file
    if (Test-Path $fullPath) {
        Write-Host "      [OK] $file" -ForegroundColor Green
    } else {
        Write-Host "      [!!] MISSING: $file" -ForegroundColor Red
        $allFound = $false
    }
}

if (-not $allFound) {
    Write-Error "Extraction incomplete - missing critical files"
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "     EXTRACTION SUCCESSFUL!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "[OK] Windows 11 base extracted to:" -ForegroundColor Green
Write-Host "     $DestinationPath" -ForegroundColor White

$extractedSize = (Get-ChildItem -Path $DestinationPath -Recurse | Measure-Object -Property Length -Sum).Sum / 1GB
Write-Host "     Size: $([math]::Round($extractedSize, 2)) GB" -ForegroundColor White
Write-Host "     Files: $((Get-ChildItem -Path $DestinationPath -Recurse -File).Count)" -ForegroundColor White

Write-Host "`n[NEXT STEP] Build your custom ISO:" -ForegroundColor Cyan
Write-Host "  .\scripts\ceremonies\09-iso-build\Build-CustomISO.ps1`n" -ForegroundColor White

return $DestinationPath
