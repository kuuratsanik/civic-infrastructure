# Complete ISO Build Setup Wizard
# Guides you through installing prerequisites and building your first ISO

$ErrorActionPreference = "Continue"

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "ISO BUILD SYSTEM - SETUP WIZARD" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

Write-Host "This wizard will guide you through:" -ForegroundColor Yellow
Write-Host "  1. Installing Windows ADK (~20 min)" -ForegroundColor White
Write-Host "  2. Downloading Windows 11 ISO (~30 min)" -ForegroundColor White
Write-Host "  3. Extracting ISO to workspace (~10 min)" -ForegroundColor White
Write-Host "  4. Building your first custom ISO (~20 min)" -ForegroundColor White
Write-Host "`nTotal time: ~80 minutes" -ForegroundColor Cyan
Write-Host "`n========================================`n" -ForegroundColor Magenta

# ============================================
# STEP 1: Windows ADK
# ============================================

Write-Host "[STEP 1/4] Windows ADK Installation" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Gray

# Check if already installed
$adkPaths = @(
    "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
    "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\x86\Oscdimg\oscdimg.exe"
)

$adkFound = $false
foreach ($path in $adkPaths) {
    if (Test-Path $path) {
        Write-Host "Windows ADK already installed!" -ForegroundColor Green
        Write-Host "Location: $path" -ForegroundColor Gray
        $adkFound = $true
        break
    }
}

if (-not $adkFound) {
    Write-Host "Windows ADK not detected." -ForegroundColor Yellow
    Write-Host "`nDownload page opened in your browser." -ForegroundColor White
    Write-Host "`nINSTRUCTIONS:" -ForegroundColor Cyan
    Write-Host "  1. Download adksetup.exe" -ForegroundColor White
    Write-Host "  2. Run the installer" -ForegroundColor White
    Write-Host "  3. Select 'Deployment Tools' ONLY" -ForegroundColor Red
    Write-Host "  4. Uncheck all other features" -ForegroundColor White
    Write-Host "  5. Complete installation" -ForegroundColor White
    
    Write-Host "`nPress Enter after Windows ADK is installed..." -ForegroundColor Yellow
    Read-Host
    
    # Verify installation
    $adkFound = $false
    foreach ($path in $adkPaths) {
        if (Test-Path $path) {
            Write-Host "SUCCESS: Windows ADK detected!" -ForegroundColor Green
            $adkFound = $true
            break
        }
    }
    
    if (-not $adkFound) {
        Write-Host "ERROR: Windows ADK still not detected" -ForegroundColor Red
        Write-Host "Please verify installation and run this wizard again." -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "`n[OK] Windows ADK ready!" -ForegroundColor Green
Start-Sleep -Seconds 2

# ============================================
# STEP 2: Download Windows 11 ISO
# ============================================

Write-Host "`n[STEP 2/4] Windows 11 ISO Download" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Gray

# Check if ISO already exists
$downloadsPath = "$env:USERPROFILE\Downloads"
$existingISO = Get-ChildItem $downloadsPath -Filter "Win11*.iso" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if ($existingISO) {
    Write-Host "Found existing Windows 11 ISO:" -ForegroundColor Green
    Write-Host "  $($existingISO.Name)" -ForegroundColor White
    Write-Host "  Size: $([math]::Round($existingISO.Length/1GB, 2)) GB" -ForegroundColor Gray
    Write-Host "  Modified: $($existingISO.LastWriteTime)" -ForegroundColor Gray
    
    $useExisting = Read-Host "`nUse this ISO? (yes/no)"
    if ($useExisting -eq "yes") {
        $isoPath = $existingISO.FullName
    } else {
        $existingISO = $null
    }
}

if (-not $existingISO) {
    Write-Host "Download page opened in your browser." -ForegroundColor White
    Write-Host "`nINSTRUCTIONS:" -ForegroundColor Cyan
    Write-Host "  1. Select 'Windows 11 (multi-edition ISO)'" -ForegroundColor White
    Write-Host "  2. Click Download" -ForegroundColor White
    Write-Host "  3. Select language (English)" -ForegroundColor White
    Write-Host "  4. Click '64-bit Download'" -ForegroundColor White
    Write-Host "  5. Save to Downloads folder" -ForegroundColor White
    Write-Host "  6. Wait for download to complete (~5-6 GB)" -ForegroundColor White
    
    Write-Host "`nPress Enter after ISO download completes..." -ForegroundColor Yellow
    Read-Host
    
    # Find the ISO
    $isoFile = Get-ChildItem $downloadsPath -Filter "Win11*.iso" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    
    if (-not $isoFile) {
        Write-Host "ERROR: Windows 11 ISO not found in Downloads" -ForegroundColor Red
        Write-Host "Please ensure download completed and try again." -ForegroundColor Yellow
        exit 1
    }
    
    $isoPath = $isoFile.FullName
}

Write-Host "`n[OK] Windows 11 ISO ready!" -ForegroundColor Green
Write-Host "  Path: $isoPath" -ForegroundColor Gray
Start-Sleep -Seconds 2

# ============================================
# STEP 3: Extract ISO
# ============================================

Write-Host "`n[STEP 3/4] Extracting Windows 11 ISO" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Gray

$destPath = "C:\ai-council\workspace\windows11-base"

# Check if already extracted
if (Test-Path "$destPath\sources\install.wim") {
    Write-Host "Windows 11 base files already extracted!" -ForegroundColor Green
    $wimSize = [math]::Round((Get-Item "$destPath\sources\install.wim").Length / 1GB, 2)
    Write-Host "  WIM size: $wimSize GB" -ForegroundColor Gray
    
    $reExtract = Read-Host "`nRe-extract ISO? (yes/no)"
    if ($reExtract -ne "yes") {
        Write-Host "[OK] Using existing extraction" -ForegroundColor Green
        Start-Sleep -Seconds 2
        $extracted = $true
    } else {
        $extracted = $false
    }
} else {
    $extracted = $false
}

if (-not $extracted) {
    Write-Host "Extracting ISO to workspace..." -ForegroundColor Cyan
    Write-Host "This will take 5-10 minutes..." -ForegroundColor Gray
    Write-Host ""
    
    try {
        # Create destination
        if (Test-Path $destPath) {
            Remove-Item $destPath -Recurse -Force
        }
        New-Item -Path $destPath -ItemType Directory -Force | Out-Null
        
        # Mount ISO
        Write-Host "Mounting ISO..." -ForegroundColor White
        $mountResult = Mount-DiskImage -ImagePath $isoPath -PassThru
        $driveLetter = ($mountResult | Get-Volume).DriveLetter
        Write-Host "  Mounted as $($driveLetter):\" -ForegroundColor Green
        
        # Copy files
        Write-Host "`nCopying files..." -ForegroundColor White
        $sourcePath = "$($driveLetter):\"
        Copy-Item "$sourcePath*" $destPath -Recurse -Force
        
        Write-Host "  Copy complete!" -ForegroundColor Green
        
        # Unmount
        Write-Host "`nUnmounting ISO..." -ForegroundColor White
        Dismount-DiskImage -ImagePath $isoPath | Out-Null
        Write-Host "  Unmounted" -ForegroundColor Green
        
    } catch {
        Write-Host "ERROR: Failed to extract ISO" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
}

# Verify critical files
Write-Host "`nVerifying extraction..." -ForegroundColor Yellow
$criticalFiles = @(
    "$destPath\sources\install.wim",
    "$destPath\sources\boot.wim"
)

$allGood = $true
foreach ($file in $criticalFiles) {
    if (Test-Path $file) {
        $size = [math]::Round((Get-Item $file).Length / 1MB, 2)
        Write-Host "  [OK] $(Split-Path $file -Leaf) ($size MB)" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $(Split-Path $file -Leaf)" -ForegroundColor Red
        $allGood = $false
    }
}

if (-not $allGood) {
    Write-Host "`nERROR: Extraction incomplete" -ForegroundColor Red
    exit 1
}

Write-Host "`n[OK] Extraction complete!" -ForegroundColor Green
Start-Sleep -Seconds 2

# ============================================
# STEP 4: Build First ISO
# ============================================

Write-Host "`n[STEP 4/4] Building Your First Custom ISO" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Gray

Write-Host "Ready to build a privacy-hardened Windows 11 ISO!" -ForegroundColor Cyan
Write-Host "`nCustomizations that will be applied:" -ForegroundColor White
Write-Host "  - Telemetry disabled (11 registry tweaks)" -ForegroundColor Gray
Write-Host "  - Classic UI restored (taskbar, file extensions)" -ForegroundColor Gray
Write-Host "  - Bloatware removed (50+ apps)" -ForegroundColor Gray
Write-Host "  - Hash verification enabled" -ForegroundColor Gray

$startBuild = Read-Host "`nStart ISO build now? (yes/no)"

if ($startBuild -ne "yes") {
    Write-Host "`nSetup complete!" -ForegroundColor Green
    Write-Host "You can build an ISO anytime with:" -ForegroundColor White
    Write-Host "  cd 'C:\Users\svenk\OneDrive\All_My_Projects\New folder'" -ForegroundColor Cyan
    Write-Host "  .\scripts\ceremonies\09-iso-build\Build-CustomISO.ps1" -ForegroundColor Cyan
    Write-Host "`nOr use VS Code task: 'Build Custom ISO'" -ForegroundColor White
    exit 0
}

Write-Host "`nStarting ISO build ceremony..." -ForegroundColor Cyan
Write-Host "This will take approximately 15-20 minutes" -ForegroundColor Gray
Write-Host ""

# Run the build ceremony
$mainWorkspace = "C:\Users\svenk\OneDrive\All_My_Projects\New folder"
$ceremonyCript = "$mainWorkspace\scripts\ceremonies\09-iso-build\Build-CustomISO.ps1"

if (Test-Path $ceremonyScript) {
    & $ceremonyScript
} else {
    Write-Host "ERROR: Build ceremony script not found" -ForegroundColor Red
    Write-Host "Expected: $ceremonyScript" -ForegroundColor Gray
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "SETUP WIZARD COMPLETE!" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

Write-Host "Your custom Windows 11 ISO is ready!" -ForegroundColor Green
Write-Host "`nWhat you can do now:" -ForegroundColor Yellow
Write-Host "  1. Find your ISO in: C:\ai-council\workspace\output\" -ForegroundColor White
Write-Host "  2. Verify hash in: C:\ai-council\evidence\hashes\iso-builds\" -ForegroundColor White
Write-Host "  3. Review logs: C:\ai-council\logs\agents\iso-build.jsonl" -ForegroundColor White
Write-Host "  4. Build more ISOs using VS Code task or ceremony script" -ForegroundColor White

Write-Host "`n========================================`n" -ForegroundColor Magenta
