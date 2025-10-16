# Dismount-WimImage.ps1
# Commits changes and unmounts Windows WIM image

#Requires -RunAsAdministrator

param(
    [Parameter(Mandatory=$true)]
    [string]$Mount,
    
    [switch]$Discard
)

Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "Dismount WIM Image" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Check if image is mounted
$MountedImages = dism /Get-MountedImageInfo
if (-not ($MountedImages -match [regex]::Escape($Mount))) {
    Write-Host "WARNING: No image mounted at $Mount" -ForegroundColor Yellow
    exit 0
}

Write-Host "Mount Directory: $Mount" -ForegroundColor White

if ($Discard) {
    Write-Host "Action: Discard changes" -ForegroundColor Yellow
} else {
    Write-Host "Action: Commit changes" -ForegroundColor Green
}

Write-Host ""

$StartTime = Get-Date

if ($Discard) {
    Write-Host "Discarding changes and unmounting..." -ForegroundColor Yellow
    dism /Unmount-Wim /MountDir:$Mount /Discard
} else {
    Write-Host "Committing changes and unmounting..." -ForegroundColor Yellow
    dism /Unmount-Wim /MountDir:$Mount /Commit
}

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: DISM unmount failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

$Duration = ((Get-Date) - $StartTime).TotalSeconds

Write-Host ""
Write-Host "SUCCESS: Image unmounted successfully in $Duration seconds" -ForegroundColor Green
Write-Host ""

# Log unmount operation
$LogEntry = @{
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    action = "unmount_wim"
    mount_dir = $Mount
    committed = (-not $Discard.IsPresent)
    duration_seconds = $Duration
    status = "success"
}

$LogPath = "C:\ai-council\logs\actions"
if (-not (Test-Path $LogPath)) { New-Item -ItemType Directory -Path $LogPath | Out-Null }

$LogEntry | ConvertTo-Json -Compress | Add-Content "$LogPath\mount.log"

Write-Host "Logged to: $LogPath\mount.log" -ForegroundColor Gray
