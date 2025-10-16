# Get-ISOHash.ps1
# Computes and stores SHA256 hash of ISO file

param(
    [Parameter(Mandatory=$true)]
    [string]$ISO,
    
    [switch]$Verify
)

Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "Compute ISO Hash" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Validate ISO exists
if (-not (Test-Path $ISO)) {
    Write-Host "ERROR: ISO file not found: $ISO" -ForegroundColor Red
    exit 1
}

$ISOName = Split-Path $ISO -LeafBase
$HashFile = "C:\ai-council\evidence\hashes\iso-builds\$ISOName.sha256"

Write-Host "ISO File: $ISO" -ForegroundColor White
Write-Host "Hash File: $HashFile" -ForegroundColor White
Write-Host ""

$StartTime = Get-Date

Write-Host "Computing SHA256..." -ForegroundColor Yellow

$Hash = (Get-FileHash $ISO -Algorithm SHA256).Hash

$Duration = ((Get-Date) - $StartTime).TotalSeconds

Write-Host ""
Write-Host "SHA256: $Hash" -ForegroundColor Cyan
Write-Host "Duration: $Duration seconds" -ForegroundColor Gray
Write-Host ""

# Create hash file directory if needed
$HashDir = Split-Path $HashFile -Parent
if (-not (Test-Path $HashDir)) {
    New-Item -ItemType Directory -Path $HashDir | Out-Null
}

# Store hash
$HashEntry = @{
    file = $ISO
    sha256 = $Hash
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    size_bytes = (Get-Item $ISO).Length
}

$HashEntry | ConvertTo-Json | Set-Content $HashFile -Encoding ASCII

Write-Host "SUCCESS: Hash stored at $HashFile" -ForegroundColor Green
Write-Host ""

# Verification mode
if ($Verify) {
    Write-Host "Verification mode enabled" -ForegroundColor Yellow
    
    if (Test-Path $HashFile) {
        $StoredHash = (Get-Content $HashFile | ConvertFrom-Json).sha256
        
        if ($Hash -eq $StoredHash) {
            Write-Host "SUCCESS: Hash matches stored value" -ForegroundColor Green
        } else {
            Write-Host "ERROR: Hash mismatch!" -ForegroundColor Red
            Write-Host "  Computed: $Hash" -ForegroundColor Red
            Write-Host "  Stored:   $StoredHash" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "WARNING: No stored hash found for verification" -ForegroundColor Yellow
    }
}

# Log hash operation
$LogEntry = @{
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    action = "hash_iso"
    iso_file = $ISO
    sha256 = $Hash
    duration_seconds = $Duration
    status = "success"
}

$LogPath = "C:\ai-council\logs\actions"
if (-not (Test-Path $LogPath)) { New-Item -ItemType Directory -Path $LogPath | Out-Null }

$LogEntry | ConvertTo-Json -Compress | Add-Content "$LogPath\iso.log"

Write-Host "Logged to: $LogPath\iso.log" -ForegroundColor Gray

return $Hash
