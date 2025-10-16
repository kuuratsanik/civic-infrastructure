# Mount-WimImage.ps1
# Mounts Windows WIM/ESD image for customization

#Requires -RunAsAdministrator

param(
    [Parameter(Mandatory=$true)]
    [string]$Wim,
    
    [Parameter(Mandatory=$true)]
    [string]$Mount,
    
    [int]$Index = 1,
    
    [switch]$Optimize
)

Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "Mount WIM Image" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Validate WIM exists
if (-not (Test-Path $Wim)) {
    Write-Host "ERROR: WIM file not found: $Wim" -ForegroundColor Red
    exit 1
}

# Create mount directory if needed
if (-not (Test-Path $Mount)) {
    Write-Host "Creating mount directory: $Mount" -ForegroundColor Gray
    New-Item -ItemType Directory -Path $Mount | Out-Null
}

# Check if already mounted
$MountedImages = dism /Get-MountedImageInfo
if ($MountedImages -match [regex]::Escape($Mount)) {
    Write-Host "WARNING: Image already mounted at $Mount" -ForegroundColor Yellow
    Write-Host "Unmounting first..." -ForegroundColor Yellow
    dism /Unmount-Wim /MountDir:$Mount /Discard
}

Write-Host "WIM File: $Wim" -ForegroundColor White
Write-Host "Mount Dir: $Mount" -ForegroundColor White
Write-Host "Index: $Index" -ForegroundColor White
Write-Host ""

# Get image info
Write-Host "Getting image information..." -ForegroundColor Gray
dism /Get-WimInfo /WimFile:$Wim /Index:$Index

Write-Host ""
Write-Host "Mounting WIM image..." -ForegroundColor Yellow

$StartTime = Get-Date

if ($Optimize) {
    dism /Mount-Wim /WimFile:$Wim /Index:$Index /MountDir:$Mount /Optimize
} else {
    dism /Mount-Wim /WimFile:$Wim /Index:$Index /MountDir:$Mount
}

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: DISM mount failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

$Duration = ((Get-Date) - $StartTime).TotalSeconds

Write-Host ""
Write-Host "SUCCESS: WIM mounted successfully in $Duration seconds" -ForegroundColor Green
Write-Host "Mount point: $Mount" -ForegroundColor Green
Write-Host ""

# Log mount operation
$LogEntry = @{
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    action = "mount_wim"
    wim_file = $Wim
    mount_dir = $Mount
    index = $Index
    optimize = $Optimize.IsPresent
    duration_seconds = $Duration
    status = "success"
}

$LogPath = "C:\ai-council\logs\actions"
if (-not (Test-Path $LogPath)) { New-Item -ItemType Directory -Path $LogPath | Out-Null }

$LogEntry | ConvertTo-Json -Compress | Add-Content "$LogPath\mount.log"

Write-Host "Logged to: $LogPath\mount.log" -ForegroundColor Gray
