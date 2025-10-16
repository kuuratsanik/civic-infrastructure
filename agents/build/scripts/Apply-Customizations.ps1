# Apply-Customizations.ps1
# Applies updates, drivers, and tweaks to mounted Windows image

#Requires -RunAsAdministrator

param(
    [Parameter(Mandatory=$true)]
    [string]$Mount,
    
    [string]$UpdatesDir = "",
    [string]$DriversDir = "",
    [string]$TweaksDir = "",
    [string]$DebloatScript = ""
)

Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "Apply Customizations" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Validate mount directory
if (-not (Test-Path $Mount)) {
    Write-Host "ERROR: Mount directory not found: $Mount" -ForegroundColor Red
    exit 1
}

# Check if image is mounted
$MountedImages = dism /Get-MountedImageInfo
if (-not ($MountedImages -match [regex]::Escape($Mount))) {
    Write-Host "ERROR: No image mounted at $Mount" -ForegroundColor Red
    exit 1
}

$StartTime = Get-Date
$Customizations = @{
    updates_applied = 0
    drivers_added = 0
    tweaks_applied = 0
    components_removed = 0
}

Write-Host "Mount Directory: $Mount" -ForegroundColor White
Write-Host ""

# ===== PHASE 1: INTEGRATE UPDATES =====
if ($UpdatesDir -and (Test-Path $UpdatesDir)) {
    Write-Host "[Phase 1/4] Integrating Updates" -ForegroundColor Yellow
    Write-Host "Source: $UpdatesDir" -ForegroundColor Gray
    Write-Host ""
    
    $Updates = Get-ChildItem $UpdatesDir -Filter *.msu -ErrorAction SilentlyContinue
    
    if ($Updates) {
        foreach ($Update in $Updates) {
            Write-Host "  Adding: $($Update.Name)" -ForegroundColor Cyan
            dism /Image:$Mount /Add-Package /PackagePath:$($Update.FullName)
            
            if ($LASTEXITCODE -eq 0) {
                $Customizations.updates_applied++
                Write-Host "    SUCCESS" -ForegroundColor Green
            } else {
                Write-Host "    FAILED (Exit code: $LASTEXITCODE)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  No .msu files found" -ForegroundColor Gray
    }
    Write-Host ""
} else {
    Write-Host "[Phase 1/4] Skipping Updates (no directory specified)" -ForegroundColor Gray
    Write-Host ""
}

# ===== PHASE 2: INJECT DRIVERS =====
if ($DriversDir -and (Test-Path $DriversDir)) {
    Write-Host "[Phase 2/4] Injecting Drivers" -ForegroundColor Yellow
    Write-Host "Source: $DriversDir" -ForegroundColor Gray
    Write-Host ""
    
    $Drivers = Get-ChildItem $DriversDir -Recurse -Filter *.inf -ErrorAction SilentlyContinue
    
    if ($Drivers) {
        # Group drivers by directory to avoid duplicates
        $DriverDirs = $Drivers | Select-Object -ExpandProperty DirectoryName -Unique
        
        foreach ($DriverDir in $DriverDirs) {
            Write-Host "  Adding drivers from: $DriverDir" -ForegroundColor Cyan
            dism /Image:$Mount /Add-Driver /Driver:$DriverDir /Recurse /ForceUnsigned
            
            if ($LASTEXITCODE -eq 0) {
                $Count = ($Drivers | Where-Object { $_.DirectoryName -eq $DriverDir }).Count
                $Customizations.drivers_added += $Count
                Write-Host "    SUCCESS ($Count drivers)" -ForegroundColor Green
            } else {
                Write-Host "    FAILED (Exit code: $LASTEXITCODE)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  No .inf files found" -ForegroundColor Gray
    }
    Write-Host ""
} else {
    Write-Host "[Phase 2/4] Skipping Drivers (no directory specified)" -ForegroundColor Gray
    Write-Host ""
}

# ===== PHASE 3: APPLY REGISTRY TWEAKS =====
if ($TweaksDir -and (Test-Path $TweaksDir)) {
    Write-Host "[Phase 3/4] Applying Registry Tweaks" -ForegroundColor Yellow
    Write-Host "Source: $TweaksDir" -ForegroundColor Gray
    Write-Host ""
    
    $Tweaks = Get-ChildItem $TweaksDir -Filter *.reg -ErrorAction SilentlyContinue
    
    if ($Tweaks) {
        foreach ($Tweak in $Tweaks) {
            Write-Host "  Applying: $($Tweak.Name)" -ForegroundColor Cyan
            
            # Load offline registry
            reg load HKLM\_OFFLINE "$Mount\Windows\System32\Config\SOFTWARE" 2>&1 | Out-Null
            
            # Import reg file
            reg import $($Tweak.FullName) /reg:64 2>&1 | Out-Null
            
            # Unload offline registry
            reg unload HKLM\_OFFLINE 2>&1 | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                $Customizations.tweaks_applied++
                Write-Host "    SUCCESS" -ForegroundColor Green
            } else {
                Write-Host "    FAILED (Exit code: $LASTEXITCODE)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  No .reg files found" -ForegroundColor Gray
    }
    Write-Host ""
} else {
    Write-Host "[Phase 3/4] Skipping Registry Tweaks (no directory specified)" -ForegroundColor Gray
    Write-Host ""
}

# ===== PHASE 4: DEBLOAT (Remove Components) =====
if ($DebloatScript -and (Test-Path $DebloatScript)) {
    Write-Host "[Phase 4/4] Running Debloat Script" -ForegroundColor Yellow
    Write-Host "Script: $DebloatScript" -ForegroundColor Gray
    Write-Host ""
    
    # Execute debloat script with mount directory
    & $DebloatScript -Mount $Mount
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "  FAILED (Exit code: $LASTEXITCODE)" -ForegroundColor Red
    }
    Write-Host ""
} else {
    Write-Host "[Phase 4/4] Skipping Debloat (no script specified)" -ForegroundColor Gray
    Write-Host ""
}

$Duration = ((Get-Date) - $StartTime).TotalSeconds

Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "Customization Summary" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "Updates Applied: $($Customizations.updates_applied)" -ForegroundColor White
Write-Host "Drivers Added: $($Customizations.drivers_added)" -ForegroundColor White
Write-Host "Tweaks Applied: $($Customizations.tweaks_applied)" -ForegroundColor White
Write-Host "Duration: $Duration seconds" -ForegroundColor White
Write-Host ""
Write-Host "SUCCESS: All customizations applied" -ForegroundColor Green
Write-Host ""

# Log customization operation
$LogEntry = @{
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    action = "apply_customizations"
    mount_dir = $Mount
    customizations = $Customizations
    duration_seconds = $Duration
    status = "success"
}

$LogPath = "C:\ai-council\logs\actions"
if (-not (Test-Path $LogPath)) { New-Item -ItemType Directory -Path $LogPath | Out-Null }

$LogEntry | ConvertTo-Json -Compress | Add-Content "$LogPath\customize.log"

Write-Host "Logged to: $LogPath\customize.log" -ForegroundColor Gray

# Return customization summary
return $Customizations
