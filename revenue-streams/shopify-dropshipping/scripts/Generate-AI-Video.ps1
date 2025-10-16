# Synthesia AI Video Generator Integration
# 100% Automated TikTok Content Creation - NO FILMING REQUIRED

param(
  [Parameter(Mandatory = $true)]
  [string]$ProductName,

  [Parameter(Mandatory = $true)]
  [string]$Script,

  [string]$ProductImageURL,
  [string]$AvatarID = 'anna_costume1_cameraA',
  [string]$Voice = 'en-US-Neural2-C',
  [string]$OutputFolder = "$PSScriptRoot\..\videos",

  [switch]$WaitForCompletion,
  [int]$TimeoutMinutes = 10
)

$ErrorActionPreference = 'Stop'

# ============================================================================
# CONFIGURATION
# ============================================================================

$ConfigPath = "$PSScriptRoot\config.json"

# Check if config exists
if (-not (Test-Path $ConfigPath)) {
  Write-Host "[ERROR] Config file not found: $ConfigPath" -ForegroundColor Red
  Write-Host "`nCreate config.json with:" -ForegroundColor Yellow
  Write-Host @"
{
  "Synthesia": {
    "APIKey": "YOUR-SYNTHESIA-API-KEY",
    "Endpoint": "https://api.synthesia.io/v2"
  },
  "TikTok": {
    "AccessToken": "YOUR-TIKTOK-TOKEN"
  }
}
"@ -ForegroundColor Gray

  Write-Host "`nGet Synthesia API key: https://www.synthesia.io/features/api" -ForegroundColor Cyan
  exit 1
}

$Config = Get-Content $ConfigPath | ConvertFrom-Json
$SynthesiaAPIKey = $Config.Synthesia.APIKey
$SynthesiaEndpoint = $Config.Synthesia.Endpoint

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-ColorOutput {
  param([string]$Message, [string]$Color = 'White')
  Write-Host $Message -ForegroundColor $Color
}

function Show-Banner {
  Write-ColorOutput @"

================================================================

     SYNTHESIA AI VIDEO GENERATOR

     Product: $ProductName
     Avatar: $AvatarID
     Output: 1080x1920 (TikTok vertical)

================================================================

"@ -Color Cyan
}

function New-SynthesiaVideo {
  param(
    [string]$Title,
    [string]$ScriptText,
    [string]$Avatar,
    [string]$VoiceID,
    [string]$BackgroundImage
  )

  Write-ColorOutput "`n[1/4] Creating video configuration..." -Color Cyan

  $videoConfig = @{
    test        = $false
    title       = $Title
    description = "AI-generated TikTok product video"
    visibility  = "private"

    input       = @(
      @{
        avatarSettings = @{
          horizontalAlign = "center"
          scale           = 1.2
          style           = "rectangular"
          seamless        = $false
        }

        avatar         = $Avatar

        scriptText     = $ScriptText

        voice          = $VoiceID
      }
    )

    aspectRatio = "9:16"  # TikTok vertical format
  }

  # Add background if provided
  if ($BackgroundImage) {
    $videoConfig.input[0].background = $BackgroundImage
    $videoConfig.input[0].backgroundSettings = @{
      videoSettings = @{
        shortBackgroundContentMatchMode = "freeze"
        longBackgroundContentMatchMode  = "trim"
      }
    }
  }

  $body = $videoConfig | ConvertTo-Json -Depth 10

  $headers = @{
    "Authorization" = $SynthesiaAPIKey
    "Content-Type"  = "application/json"
  }

  Write-ColorOutput "   Script: $($ScriptText.Substring(0, [Math]::Min(50, $ScriptText.Length)))..." -Color Gray
  Write-ColorOutput "   Avatar: $Avatar" -Color Gray
  Write-ColorOutput "   Voice: $VoiceID" -Color Gray

  try {
    Write-ColorOutput "`n[2/4] Sending request to Synthesia API..." -Color Cyan

    $response = Invoke-RestMethod -Uri "$SynthesiaEndpoint/videos" `
      -Method Post `
      -Headers $headers `
      -Body $body

    Write-ColorOutput "   [OK] Video generation started!" -Color Green
    Write-ColorOutput "   Video ID: $($response.id)" -Color White
    Write-ColorOutput "   Status: $($response.status)" -Color Yellow
    Write-ColorOutput "   ETA: 2-5 minutes" -Color Gray

    return $response
  } catch {
    Write-ColorOutput "   [ERROR] API request failed" -Color Red
    Write-ColorOutput "   $($_.Exception.Message)" -Color Red

    if ($_.ErrorDetails) {
      Write-ColorOutput "   Details: $($_.ErrorDetails.Message)" -Color Red
    }

    throw
  }
}

function Get-VideoStatus {
  param([string]$VideoID)

  $headers = @{
    "Authorization" = $SynthesiaAPIKey
  }

  try {
    $response = Invoke-RestMethod -Uri "$SynthesiaEndpoint/videos/$VideoID" `
      -Method Get `
      -Headers $headers

    return $response
  } catch {
    Write-ColorOutput "[ERROR] Failed to get video status" -Color Red
    throw
  }
}

function Wait-ForVideo {
  param(
    [string]$VideoID,
    [int]$TimeoutMinutes
  )

  Write-ColorOutput "`n[3/4] Waiting for video generation..." -Color Cyan

  $startTime = Get-Date
  $timeout = (Get-Date).AddMinutes($TimeoutMinutes)

  $iteration = 0
  while ((Get-Date) -lt $timeout) {
    $iteration++

    $status = Get-VideoStatus -VideoID $VideoID

    $elapsed = ((Get-Date) - $startTime).TotalSeconds
    Write-ColorOutput "   Check #$iteration (${elapsed}s elapsed) - Status: $($status.status)" -Color Gray

    switch ($status.status) {
      'complete' {
        Write-ColorOutput "   [OK] Video generation complete!" -Color Green
        return $status
      }
      'failed' {
        Write-ColorOutput "   [ERROR] Video generation failed!" -Color Red
        throw "Video generation failed: $($status.error)"
      }
      'in_progress' {
        Write-ColorOutput "      Progress: Processing..." -Color Yellow
        Start-Sleep -Seconds 15
      }
      default {
        Start-Sleep -Seconds 15
      }
    }
  }

  throw "Timeout waiting for video ($TimeoutMinutes minutes)"
}

function Download-SynthesiaVideo {
  param(
    [string]$VideoURL,
    [string]$OutputPath
  )

  Write-ColorOutput "`n[4/4] Downloading video..." -Color Cyan
  Write-ColorOutput "   URL: $VideoURL" -Color Gray
  Write-ColorOutput "   Destination: $OutputPath" -Color Gray

  try {
    # Ensure output directory exists
    $outputDir = Split-Path $OutputPath -Parent
    if (-not (Test-Path $outputDir)) {
      New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    Invoke-WebRequest -Uri $VideoURL -OutFile $OutputPath

    $fileSize = (Get-Item $OutputPath).Length / 1MB
    Write-ColorOutput "   [OK] Downloaded: $([Math]::Round($fileSize, 2)) MB" -Color Green

    return $OutputPath
  } catch {
    Write-ColorOutput "   [ERROR] Download failed" -Color Red
    throw
  }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Show-Banner

# Validate script length (TikTok optimal: 100-200 characters)
$scriptLength = $Script.Length
if ($scriptLength -lt 50) {
  Write-ColorOutput "[WARNING] Script very short ($scriptLength chars). Recommended: 100-200 chars" -Color Yellow
} elseif ($scriptLength -gt 300) {
  Write-ColorOutput "[WARNING] Script too long ($scriptLength chars). May exceed 15 sec TikTok limit" -Color Yellow
}

# Create video
try {
  $videoResponse = New-SynthesiaVideo -Title "TikTok - $ProductName" `
    -ScriptText $Script `
    -Avatar $AvatarID `
    -VoiceID $Voice `
    -BackgroundImage $ProductImageURL

  $videoID = $videoResponse.id

  # Save video ID for tracking
  $trackingFile = "$PSScriptRoot\..\videos\tracking.json"
  $tracking = @{
    VideoID     = $videoID
    ProductName = $ProductName
    Script      = $Script
    CreatedAt   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Status      = "in_progress"
  }

  if (Test-Path $trackingFile) {
    $allTracking = Get-Content $trackingFile | ConvertFrom-Json
    $allTracking += $tracking
  } else {
    $allTracking = @($tracking)
  }

  $allTracking | ConvertTo-Json -Depth 10 | Out-File $trackingFile -Encoding UTF8

  if ($WaitForCompletion) {
    # Wait for video to complete
    $completedVideo = Wait-ForVideo -VideoID $videoID -TimeoutMinutes $TimeoutMinutes

    # Download video
    $downloadURL = $completedVideo.download
    $outputPath = Join-Path $OutputFolder "$ProductName-$(Get-Date -Format 'yyyyMMdd-HHmmss').mp4"

    $localPath = Download-SynthesiaVideo -VideoURL $downloadURL -OutputPath $outputPath

    Write-ColorOutput "`n================================================================" -Color Green
    Write-ColorOutput "                                                              " -Color Green
    Write-ColorOutput "     [SUCCESS] AI VIDEO GENERATED!                            " -Color Green
    Write-ColorOutput "                                                              " -Color Green
    Write-ColorOutput "     Video ID: $videoID" -Color Green
    Write-ColorOutput "     Local Path: $localPath" -Color Green
    Write-ColorOutput "     Duration: ~15 seconds" -Color Green
    Write-ColorOutput "     Format: 1080x1920 (TikTok vertical)" -Color Green
    Write-ColorOutput "                                                              " -Color Green
    Write-ColorOutput "     Next: Upload to TikTok or use Auto-Post script          " -Color Green
    Write-ColorOutput "                                                              " -Color Green
    Write-ColorOutput "================================================================" -Color Green

    # Update tracking
    $allTracking[-1].Status = "completed"
    $allTracking[-1].LocalPath = $localPath
    $allTracking | ConvertTo-Json -Depth 10 | Out-File $trackingFile -Encoding UTF8

    return @{
      VideoID     = $videoID
      LocalPath   = $localPath
      DownloadURL = $downloadURL
      Status      = "completed"
    }
  } else {
    Write-ColorOutput "`n================================================================" -Color Yellow
    Write-ColorOutput "                                                              " -Color Yellow
    Write-ColorOutput "     [SUBMITTED] Video generation in progress                 " -Color Yellow
    Write-ColorOutput "                                                              " -Color Yellow
    Write-ColorOutput "     Video ID: $videoID" -Color Yellow
    Write-ColorOutput "     ETA: 2-5 minutes" -Color Yellow
    Write-ColorOutput "                                                              " -Color Yellow
    Write-ColorOutput "     Check status:                                            " -Color Yellow
    Write-ColorOutput "     .\Check-VideoStatus.ps1 -VideoID $videoID               " -Color Yellow
    Write-ColorOutput "                                                              " -Color Yellow
    Write-ColorOutput "================================================================" -Color Yellow

    return @{
      VideoID = $videoID
      Status  = "in_progress"
    }
  }
} catch {
  Write-ColorOutput "`n[ERROR] Video generation failed:" -Color Red
  Write-ColorOutput $_.Exception.Message -Color Red
  exit 1
}
