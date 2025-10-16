<#
.SYNOPSIS
    Multi-platform, multi-language video generation and posting

.DESCRIPTION
    Expands single video generation to:
    - Multiple languages (Synthesia 140+ voices)
    - Multiple platforms (TikTok, Instagram, YouTube, Facebook, Pinterest, etc.)
    - Automatic translation (ChatGPT API)
    - Cross-platform posting (Publer/Make.com)

.PARAMETER ProductName
    Product to generate video for

.PARAMETER Languages
    Array of language codes (e.g., @("Estonian","Latvian","Lithuanian"))

.PARAMETER Platforms
    Array of platforms (e.g., @("TikTok","Instagram","YouTube"))

.PARAMETER TimeSlot
    Morning, Lunch, or Evening

.EXAMPLE
    .\Generate-Global-Content.ps1 -ProductName "Orthopedic Dog Bed" -Languages @("Estonian","Finnish") -Platforms @("TikTok","Instagram")
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [string]$ProductName,

  [Parameter(Mandatory = $false)]
  [string[]]$Languages = @("Estonian"),

  [Parameter(Mandatory = $false)]
  [string[]]$Platforms = @("TikTok"),

  [Parameter(Mandatory = $false)]
  [ValidateSet("Morning", "Lunch", "Evening")]
  [string]$TimeSlot = "Morning",

  [Parameter(Mandatory = $false)]
  [string]$ConfigPath = "..\scripts\config.json"
)

# Ensure logs directory
$logsDir = Join-Path $PSScriptRoot "logs"
if (-not (Test-Path $logsDir)) {
  New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

# Load config
if (-not (Test-Path $ConfigPath)) {
  throw "Config file not found: $ConfigPath"
}

$config = Get-Content $ConfigPath | ConvertFrom-Json
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $logsDir "global-content-$timestamp.log"

function Write-Log {
  param([string]$Message, [string]$Level = "INFO")
  $logMessage = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"

  switch ($Level) {
    "ERROR" { Write-Host $logMessage -ForegroundColor Red }
    "WARN" { Write-Host $logMessage -ForegroundColor Yellow }
    "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
    default { Write-Host $logMessage }
  }

  Add-Content -Path $logFile -Value $logMessage
}

Write-Log "========================================" "INFO"
Write-Log "GLOBAL CONTENT GENERATION" "INFO"
Write-Log "========================================" "INFO"
Write-Log "Product: $ProductName"
Write-Log "Languages: $($Languages -join ', ')"
Write-Log "Platforms: $($Platforms -join ', ')"
Write-Log "Time slot: $TimeSlot"
Write-Log "Total videos: $($Languages.Count * $Platforms.Count)"
Write-Log ""

# Language to voice mapping (Synthesia voices)
$languageVoices = @{
  "Estonian"   = "et-EE-AnuNeural"
  "Latvian"    = "lv-LV-EveritaNeural"
  "Lithuanian" = "lt-LT-LeonasNeural"
  "Finnish"    = "fi-FI-NooraNeural"
  "Swedish"    = "sv-SE-SofieNeural"
  "Norwegian"  = "nb-NO-FinnNeural"
  "Danish"     = "da-DK-ChristelNeural"
  "German"     = "de-DE-KatjaNeural"
  "French"     = "fr-FR-DeniseNeural"
  "Dutch"      = "nl-NL-ColetteNeural"
  "Polish"     = "pl-PL-ZofiaNeural"
  "Czech"      = "cs-CZ-VlastaNeural"
  "Italian"    = "it-IT-ElsaNeural"
  "Spanish"    = "es-ES-ElviraNeural"
  "Portuguese" = "pt-PT-RaquelNeural"
  "English"    = "en-US-JennyNeural"
  "Russian"    = "ru-RU-SvetlanaNeural"
  "Japanese"   = "ja-JP-NanamiNeural"
  "Korean"     = "ko-KR-SunHiNeural"
  "Chinese"    = "zh-CN-XiaoxiaoNeural"
}

# Avatar selection per time slot
$avatar = switch ($TimeSlot) {
  "Morning" { "anna_costume1_cameraA" }
  "Lunch" { "lily_costume1_cameraA" }
  "Evening" { "sarah_costume1_cameraA" }
}

# ============================================
# STEP 1: GET PRODUCT (if not provided)
# ============================================

if (-not $ProductName) {
  Write-Log "Fetching random product from BigBuy..."

  try {
    $bigbuyHeaders = @{
      "Authorization" = "Bearer $($config.BigBuy.APIKey)"
      "Accept"        = "application/json"
    }

    $response = Invoke-RestMethod `
      -Uri "$($config.BigBuy.Endpoint)/rest/catalog/products.json" `
      -Method GET `
      -Headers $bigbuyHeaders `
      -Body @{
      isoCode     = "EE"
      warehouseId = 1
      priceFrom   = 20
      priceTo     = 80
      pageSize    = 50
    }

    $product = $response.products | Get-Random
    $ProductName = $product.name
    $ProductDescription = $product.description
    $ProductPrice = $product.price

    Write-Log "Selected: $ProductName (€$ProductPrice)" "SUCCESS"

  } catch {
    Write-Log "ERROR fetching product: $_" "ERROR"
    throw
  }
} else {
  $ProductDescription = "Amazing product"
  $ProductPrice = 50
}

# ============================================
# STEP 2: GENERATE BASE SCRIPT (ENGLISH)
# ============================================

Write-Log "Generating base script (English)..."

$baseScript = ""

if ($config.OpenAI.APIKey -and $config.OpenAI.APIKey -ne "YOUR-OPENAI-API-KEY-HERE") {
  try {
    $prompt = @"
Create a 15-second TikTok video script for: $ProductName

Requirements:
- Hook (pain point)
- Solution (product benefit)
- CTA (link in bio)
- Under 200 characters
- Conversational tone

Generate ONLY the script, no extra text.
"@

    $chatgptHeaders = @{
      "Authorization" = "Bearer $($config.OpenAI.APIKey)"
      "Content-Type"  = "application/json"
    }

    $chatgptBody = @{
      model       = $config.OpenAI.Model
      messages    = @(
        @{
          role    = "system"
          content = "You are a TikTok marketing expert. Create short, engaging scripts."
        },
        @{
          role    = "user"
          content = $prompt
        }
      )
      temperature = 0.8
      max_tokens  = 150
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod `
      -Uri "https://api.openai.com/v1/chat/completions" `
      -Method POST `
      -Headers $chatgptHeaders `
      -Body $chatgptBody

    $baseScript = $response.choices[0].message.content.Trim()
    Write-Log "Base script: `"$baseScript`"" "SUCCESS"

  } catch {
    Write-Log "ChatGPT error: $_" "WARN"
    $baseScript = "This $ProductName is amazing! Perfect for everyday use. Link in bio for discount."
  }
} else {
  $baseScript = "This $ProductName is a game-changer! Get yours now. Link in bio!"
}

# ============================================
# STEP 3: TRANSLATE TO ALL LANGUAGES
# ============================================

Write-Log ""
Write-Log "Translating to $($Languages.Count) language(s)..."

$translatedScripts = @{}

foreach ($lang in $Languages) {
  Write-Log "  - Translating to $lang..."

  if ($lang -eq "English") {
    $translatedScripts[$lang] = $baseScript
    continue
  }

  if ($config.OpenAI.APIKey -and $config.OpenAI.APIKey -ne "YOUR-OPENAI-API-KEY-HERE") {
    try {
      $translatePrompt = "Translate this TikTok script to $lang language. Keep it natural and conversational. Under 200 characters:`n`n$baseScript"

      $chatgptBody = @{
        model       = $config.OpenAI.Model
        messages    = @(
          @{
            role    = "system"
            content = "You are a professional translator. Translate accurately and naturally."
          },
          @{
            role    = "user"
            content = $translatePrompt
          }
        )
        temperature = 0.3
        max_tokens  = 150
      } | ConvertTo-Json -Depth 10

      $response = Invoke-RestMethod `
        -Uri "https://api.openai.com/v1/chat/completions" `
        -Method POST `
        -Headers $chatgptHeaders `
        -Body $chatgptBody

      $translatedScripts[$lang] = $response.choices[0].message.content.Trim()
      Write-Log "    Translated: `"$($translatedScripts[$lang])`"" "SUCCESS"

    } catch {
      Write-Log "    Translation failed, using template" "WARN"
      $translatedScripts[$lang] = "[Translation needed for: $baseScript]"
    }
  } else {
    $translatedScripts[$lang] = "[Translation needed for: $baseScript]"
  }
}

# ============================================
# STEP 4: GENERATE VIDEOS FOR ALL LANGUAGES
# ============================================

Write-Log ""
Write-Log "Generating videos..."

$generatedVideos = @{}

foreach ($lang in $Languages) {
  Write-Log "  - Generating video for $lang..."

  $voice = $languageVoices[$lang]
  if (-not $voice) {
    Write-Log "    No voice mapping for $lang, using English" "WARN"
    $voice = "en-US-JennyNeural"
  }

  try {
    $videoScriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) "scripts\Generate-AI-Video.ps1"

    $videoParams = @{
      ProductName       = "$ProductName ($lang)"
      Script            = $translatedScripts[$lang]
      AvatarID          = $avatar
      Voice             = $voice
      WaitForCompletion = $true
    }

    $result = & $videoScriptPath @videoParams

    if ($result.Success) {
      $generatedVideos[$lang] = $result.VideoPath
      Write-Log "    Video ready: $($result.VideoPath)" "SUCCESS"
    } else {
      Write-Log "    Video generation failed: $($result.Error)" "ERROR"
    }

  } catch {
    Write-Log "    ERROR: $_" "ERROR"
  }
}

# ============================================
# STEP 5: POST TO ALL PLATFORMS
# ============================================

Write-Log ""
Write-Log "Posting to platforms..."

$postedLinks = @{}

foreach ($lang in $Languages) {
  if (-not $generatedVideos.ContainsKey($lang)) {
    Write-Log "  - No video for $lang, skipping platforms" "WARN"
    continue
  }

  $videoPath = $generatedVideos[$lang]

  foreach ($platform in $Platforms) {
    Write-Log "  - Posting $lang video to $platform..."

    # Note: This requires Publer API or similar multi-platform posting service
    # For now, we'll log the intent

    $platformKey = "$lang-$platform"

    if ($config.TikTok.PublerAPIKey -and $config.TikTok.PublerAPIKey -ne "YOUR-PUBLER-API-KEY-HERE") {
      # TODO: Implement actual Publer API call
      # See Zapier-Workflows.md for Publer API documentation

      Write-Log "    Publer API integration needed for auto-posting" "WARN"
      $postedLinks[$platformKey] = "[Manual upload required: $videoPath to $platform]"

    } else {
      Write-Log "    Manual upload required: $videoPath to $platform" "WARN"
      $postedLinks[$platformKey] = "[Upload manually: $videoPath]"
    }
  }
}

# ============================================
# STEP 6: SUMMARY EMAIL
# ============================================

Write-Log ""
Write-Log "Sending summary email..."

$totalVideos = $Languages.Count * $Platforms.Count
$successfulVideos = $generatedVideos.Count
$platformPosts = $Platforms.Count * $successfulVideos

$emailBody = @"
🌍 GLOBAL CONTENT GENERATION COMPLETE

Product: $ProductName
Time slot: $TimeSlot

Languages: $($Languages -join ', ')
Platforms: $($Platforms -join ', ')

Videos generated: $successfulVideos / $($Languages.Count)
Platform posts: $platformPosts planned

Base script (English):
"$baseScript"

Translations:
$($translatedScripts.GetEnumerator() | ForEach-Object { "  - $($_.Key): `"$($_.Value)`"" } | Out-String)

Generated videos:
$($generatedVideos.GetEnumerator() | ForEach-Object { "  - $($_.Key): $($_.Value)" } | Out-String)

Platform posting status:
$($postedLinks.GetEnumerator() | ForEach-Object { "  - $($_.Key): $($_.Value)" } | Out-String)

Log file: $logFile

---
Automated global content generation
Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

try {
  if ($config.Email.Username -and $config.Email.Username -ne "your-email@gmail.com") {
    Send-MailMessage `
      -From $config.Email.From `
      -To $config.Email.To `
      -Subject "🌍 Global Content - $ProductName ($successfulVideos videos, $platformPosts posts)" `
      -Body $emailBody `
      -SmtpServer $config.Email.SmtpServer `
      -Port $config.Email.Port `
      -UseSsl `
      -Credential (New-Object System.Management.Automation.PSCredential(
        $config.Email.Username,
        (ConvertTo-SecureString $config.Email.Password -AsPlainText -Force)
      ))

    Write-Log "Summary email sent" "SUCCESS"
  } else {
    Write-Log "Email not configured, skipping notification" "WARN"
  }
} catch {
  Write-Log "Email send failed: $_" "WARN"
}

# ============================================
# FINAL SUMMARY
# ============================================

Write-Log ""
Write-Log "========================================" "SUCCESS"
Write-Log "GLOBAL CONTENT GENERATION COMPLETE" "SUCCESS"
Write-Log "========================================" "SUCCESS"
Write-Log "Product: $ProductName"
Write-Log "Languages: $($Languages.Count) ($($Languages -join ', '))"
Write-Log "Platforms: $($Platforms.Count) ($($Platforms -join ', '))"
Write-Log "Videos generated: $successfulVideos"
Write-Log "Platform posts planned: $platformPosts"
Write-Log "Log file: $logFile"
Write-Log "========================================" "SUCCESS"

return @{
  Success         = $true
  Product         = $ProductName
  Languages       = $Languages
  Platforms       = $Platforms
  VideosGenerated = $successfulVideos
  PlatformPosts   = $platformPosts
  GeneratedVideos = $generatedVideos
  PostedLinks     = $postedLinks
  LogFile         = $logFile
}
