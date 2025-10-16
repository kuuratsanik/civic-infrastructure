# New-BootableISO.ps1
# Creates bootable Windows 11 ISO with BIOS and UEFI support

#Requires -RunAsAdministrator

param(
    [Parameter(Mandatory=$true)]
    [string]$Source,
    
    [Parameter(Mandatory=$true)]
    [string]$OutISO,
    
    [string]$Label = "WIN11_CUSTOM"
)

Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "Create Bootable ISO" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Validate source directory
if (-not (Test-Path $Source)) {
    Write-Host "ERROR: Source directory not found: $Source" -ForegroundColor Red
    exit 1
}

# Validate oscdimg.exe exists
$OscdimgPath = where.exe oscdimg 2>$null
if (-not $OscdimgPath) {
    # Try common paths
    $CommonPaths = @(
        "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
        "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\x86\Oscdimg\oscdimg.exe"
    )
    
    foreach ($Path in $CommonPaths) {
        if (Test-Path $Path) {
            $OscdimgPath = $Path
            break
        }
    }
    
    if (-not $OscdimgPath) {
        Write-Host "ERROR: oscdimg.exe not found" -ForegroundColor Red
        Write-Host "Install Windows ADK: https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install" -ForegroundColor Yellow
        exit 1
    }
}

# Validate boot files
$BootBin = Join-Path $Source "boot\etfsboot.com"
$EfiBoot = Join-Path $Source "efi\microsoft\boot\efisys.bin"

if (-not (Test-Path $BootBin)) {
    Write-Host "ERROR: BIOS boot file not found: $BootBin" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $EfiBoot)) {
    Write-Host "ERROR: UEFI boot file not found: $EfiBoot" -ForegroundColor Red
    exit 1
}

Write-Host "Source Directory: $Source" -ForegroundColor White
Write-Host "Output ISO: $OutISO" -ForegroundColor White
Write-Host "Volume Label: $Label" -ForegroundColor White
Write-Host "oscdimg Path: $OscdimgPath" -ForegroundColor Gray
Write-Host ""

# Create output directory if needed
$OutDir = Split-Path $OutISO -Parent
if ($OutDir -and (-not (Test-Path $OutDir))) {
    New-Item -ItemType Directory -Path $OutDir | Out-Null
}

Write-Host "Creating bootable ISO..." -ForegroundColor Yellow
Write-Host ""

$StartTime = Get-Date

# Build ISO with dual boot (BIOS + UEFI)
# -bootdata:2 = dual boot
# #p0,e,b = primary boot (BIOS)
# #pEF,e,b = EFI boot (UEFI)
# -u2 = UDF file system
# -m = ignore max size limit
# -o = optimize storage by encoding duplicate files once

$Arguments = @(
    "-bootdata:2#p0,e,b`"$BootBin`"#pEF,e,b`"$EfiBoot`""
    "-u2"
    "-m"
    "-o"
    "-l`"$Label`""
    "`"$Source`""
    "`"$OutISO`""
)

Write-Host "Command: oscdimg $($Arguments -join ' ')" -ForegroundColor Gray
Write-Host ""

& $OscdimgPath $Arguments

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: oscdimg failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

$Duration = ((Get-Date) - $StartTime).TotalSeconds

# Get ISO file size
$ISOSize = (Get-Item $OutISO).Length
$ISOSizeMB = [math]::Round($ISOSize / 1MB, 2)

Write-Host ""
Write-Host "SUCCESS: ISO created successfully in $Duration seconds" -ForegroundColor Green
Write-Host "  Path: $OutISO" -ForegroundColor Green
Write-Host "  Size: $ISOSizeMB MB" -ForegroundColor Green
Write-Host ""

# Log ISO creation
$LogEntry = @{
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    action = "create_iso"
    source_dir = $Source
    output_iso = $OutISO
    size_mb = $ISOSizeMB
    label = $Label
    duration_seconds = $Duration
    status = "success"
}

$LogPath = "C:\ai-council\logs\actions"
if (-not (Test-Path $LogPath)) { New-Item -ItemType Directory -Path $LogPath | Out-Null }

$LogEntry | ConvertTo-Json -Compress | Add-Content "$LogPath\iso.log"

Write-Host "Logged to: $LogPath\iso.log" -ForegroundColor Gray

return $OutISO
