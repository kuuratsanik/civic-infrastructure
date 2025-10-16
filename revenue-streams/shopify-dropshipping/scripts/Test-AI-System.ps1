# Test AI Video Generation System
# Quick test to verify Synthesia API integration

param(
  [switch]$CreateConfig,
  [switch]$TestAPI,
  [switch]$GenerateTestVideo
)

$ErrorActionPreference = 'Stop'

function Write-ColorOutput {
  param([string]$Message, [string]$Color = 'White')
  Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput @"

================================================================

     AI VIDEO SYSTEM - QUICK TEST

================================================================

"@ -Color Cyan

# ============================================================================
# STEP 1: CONFIG SETUP
# ============================================================================

if ($CreateConfig) {
  Write-ColorOutput "`n[STEP 1] Creating config.json from template..." -Color Cyan

  $templatePath = "$PSScriptRoot\config.template.json"
  $configPath = "$PSScriptRoot\config.json"

  if (Test-Path $configPath) {
    Write-ColorOutput "   [WARNING] config.json already exists!" -Color Yellow
    $overwrite = Read-Host "   Overwrite? (Y/N)"
    if ($overwrite -ne 'Y') {
      Write-ColorOutput "   Skipped." -Color Gray
      return
    }
  }

  Copy-Item $templatePath $configPath
  Write-ColorOutput "   [OK] config.json created!" -Color Green
  Write-ColorOutput "`n   Now edit config.json and add your API keys:" -Color Yellow
  Write-ColorOutput "      1. Synthesia API key (https://www.synthesia.io/features/api)" -Color Gray
  Write-ColorOutput "      2. OpenAI API key (https://platform.openai.com/api-keys)" -Color Gray
  Write-ColorOutput "      3. BigBuy API key (optional)" -Color Gray
  Write-ColorOutput "      4. TikTok access token (optional)" -Color Gray

  # Open config for editing
  $edit = Read-Host "`n   Open config.json for editing now? (Y/N)"
  if ($edit -eq 'Y') {
    notepad $configPath
  }

  return
}

# ============================================================================
# STEP 2: API TEST
# ============================================================================

if ($TestAPI) {
  Write-ColorOutput "`n[STEP 2] Testing Synthesia API connection..." -Color Cyan

  $configPath = "$PSScriptRoot\config.json"

  if (-not (Test-Path $configPath)) {
    Write-ColorOutput "   [ERROR] config.json not found!" -Color Red
    Write-ColorOutput "   Run: .\Test-AI-System.ps1 -CreateConfig" -Color Yellow
    return
  }

  $config = Get-Content $configPath | ConvertFrom-Json
  $apiKey = $config.Synthesia.APIKey

  if ($apiKey -eq "YOUR-SYNTHESIA-API-KEY-HERE") {
    Write-ColorOutput "   [ERROR] Synthesia API key not configured!" -Color Red
    Write-ColorOutput "   Edit config.json and add your API key" -Color Yellow
    return
  }

  try {
    Write-ColorOutput "   Testing API endpoint..." -Color Gray

    $headers = @{
      "Authorization" = $apiKey
    }

    $response = Invoke-RestMethod -Uri "$($config.Synthesia.Endpoint)/videos" `
      -Method Get `
      -Headers $headers

    Write-ColorOutput "   [OK] API connection successful!" -Color Green
    Write-ColorOutput "   Account has $($response.videos.Count) videos" -Color Gray

  } catch {
    Write-ColorOutput "   [ERROR] API test failed!" -Color Red
    Write-ColorOutput "   $($_.Exception.Message)" -Color Red

    if ($_.Exception.Response.StatusCode -eq 401) {
      Write-ColorOutput "`n   This is an authentication error. Check your API key." -Color Yellow
    }
  }

  return
}

# ============================================================================
# STEP 3: GENERATE TEST VIDEO
# ============================================================================

if ($GenerateTestVideo) {
  Write-ColorOutput "`n[STEP 3] Generating test video..." -Color Cyan

  $testProduct = "Orthopedic Dog Bed"
  $testScript = "Your dog wakes up in pain every morning. This orthopedic memory foam bed changes everything. Better sleep. Happier dog. Link in bio."

  Write-ColorOutput "   Product: $testProduct" -Color Gray
  Write-ColorOutput "   Script: $testScript" -Color Gray
  Write-ColorOutput "`n   Generating video (this takes 2-5 minutes)..." -Color Yellow

  try {
    $result = & "$PSScriptRoot\Generate-AI-Video.ps1" `
      -ProductName $testProduct `
      -Script $testScript `
      -WaitForCompletion

    Write-ColorOutput "`n   [SUCCESS] Test video generated!" -Color Green
    Write-ColorOutput "   Path: $($result.LocalPath)" -Color White
    Write-ColorOutput "`n   Open video? (Y/N)" -Color Cyan
    $open = Read-Host

    if ($open -eq 'Y') {
      Start-Process $result.LocalPath
    }

  } catch {
    Write-ColorOutput "`n   [ERROR] Test failed!" -Color Red
    Write-ColorOutput "   $($_.Exception.Message)" -Color Red
  }

  return
}

# ============================================================================
# INTERACTIVE MODE
# ============================================================================

Write-ColorOutput "`nWhat would you like to test?" -Color Cyan
Write-ColorOutput "  1. Create config.json (first time setup)" -Color White
Write-ColorOutput "  2. Test API connection" -Color White
Write-ColorOutput "  3. Generate test video (full end-to-end test)" -Color White
Write-ColorOutput "  4. All of the above (full system test)" -Color White

$choice = Read-Host "`nSelect (1-4)"

switch ($choice) {
  '1' {
    & $MyInvocation.MyCommand.Path -CreateConfig
  }
  '2' {
    & $MyInvocation.MyCommand.Path -TestAPI
  }
  '3' {
    & $MyInvocation.MyCommand.Path -GenerateTestVideo
  }
  '4' {
    Write-ColorOutput "`n========== FULL SYSTEM TEST ==========" -Color Cyan

    # Step 1
    & $MyInvocation.MyCommand.Path -CreateConfig

    Write-ColorOutput "`nPress Enter when you've added API keys to config.json..." -Color Yellow
    Read-Host

    # Step 2
    & $MyInvocation.MyCommand.Path -TestAPI

    # Step 3
    $proceed = Read-Host "`nProceed with test video generation? (Y/N)"
    if ($proceed -eq 'Y') {
      & $MyInvocation.MyCommand.Path -GenerateTestVideo
    }

    Write-ColorOutput "`n========== TEST COMPLETE ==========" -Color Green
  }
  default {
    Write-ColorOutput "Invalid choice." -Color Red
  }
}

Write-ColorOutput "`n================================================================`n" -Color Gray
