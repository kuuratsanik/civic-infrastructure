<#
.SYNOPSIS
    Daily automated video generation and posting for TikTok dropshipping

.DESCRIPTION
    Generates 3 TikTok videos per day:
    - 7:30 AM Morning video
    - 1:00 PM Lunch video
    - 8:00 PM Evening video

    Workflow:
    1. Fetch random product from BigBuy
    2. Generate TikTok script with ChatGPT
    3. Create video with Synthesia
    4. Upload to TikTok (via Publer API)
    5. Add to Shopify store
    6. Send notification email

.PARAMETER ConfigPath
    Path to config.json (API keys)

.PARAMETER TimeSlot
    Which video to generate: Morning, Lunch, Evening

.PARAMETER TestMode
    If true, doesn't actually post to TikTok (for testing)

.EXAMPLE
    .\Start-DailyVideoGeneration.ps1 -TimeSlot Morning
    .\Start-DailyVideoGeneration.ps1 -TimeSlot Evening -TestMode
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [string]$ConfigPath = "..\scripts\config.json",

  [Parameter(Mandatory = $true)]
  [ValidateSet("Morning", "Lunch", "Evening")]
  [string]$TimeSlot,

  [Parameter(Mandatory = $false)]
  [switch]$TestMode
)

# Ensure logs directory exists
$logsDir = Join-Path $PSScriptRoot "logs"
if (-not (Test-Path $logsDir)) {
  New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

# Load configuration
if (-not (Test-Path $ConfigPath)) {
  throw "Config file not found: $ConfigPath. Please copy config.template.json to config.json and add your API keys."
}

$config = Get-Content $ConfigPath | ConvertFrom-Json
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $logsDir "video-generation-$timestamp.log"

# Logging function
function Write-Log {
  param(
    [string]$Message,
    [string]$Level = "INFO"
  )
  $logMessage = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"

  # Color coding
  switch ($Level) {
    "ERROR" { Write-Host $logMessage -ForegroundColor Red }
    "WARN" { Write-Host $logMessage -ForegroundColor Yellow }
    "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
    default { Write-Host $logMessage }
  }

  Add-Content -Path $logFile -Value $logMessage
}

Write-Log "========================================" "INFO"
Write-Log "STARTING VIDEO GENERATION: $TimeSlot" "INFO"
Write-Log "========================================" "INFO"

# ============================================
# STEP 1: FETCH PRODUCT FROM BIGBUY
# ============================================

Write-Log "STEP 1: Fetching random product from BigBuy..."

try {
  if (-not $config.BigBuy.APIKey -or $config.BigBuy.APIKey -eq "YOUR-BIGBUY-API-KEY-HERE") {
    throw "BigBuy API key not configured. Please add it to config.json"
  }

  $bigbuyHeaders = @{
    "Authorization" = "Bearer $($config.BigBuy.APIKey)"
    "Accept"        = "application/json"
  }

  $bigbuyParams = @{
    Uri     = "$($config.BigBuy.Endpoint)/rest/catalog/products.json"
    Method  = "GET"
    Headers = $bigbuyHeaders
    Body    = @{
      isoCode     = "EE"
      warehouseId = 1  # Spain warehouse
      priceFrom   = 20
      priceTo     = 80
      pageSize    = 50
    }
  }

  $response = Invoke-RestMethod @bigbuyParams

  # Select random product
  $product = $response.products | Get-Random

  Write-Log "Selected product: $($product.name)" "SUCCESS"
  Write-Log "  - Product ID: $($product.id)"
  Write-Log "  - Price: EUR $($product.price)"
  Write-Log "  - Category: $($product.category)"

} catch {
  Write-Log "ERROR fetching BigBuy product: $_" "ERROR"
  Write-Log "Check: 1) API key valid? 2) Internet connection? 3) BigBuy API status?" "ERROR"
  throw
}

# ============================================
# STEP 2: GENERATE SCRIPT WITH CHATGPT
# ============================================

Write-Log "STEP 2: Generating TikTok script with ChatGPT..."

try {
  if (-not $config.OpenAI.APIKey -or $config.OpenAI.APIKey -eq "YOUR-OPENAI-API-KEY-HERE") {
    Write-Log "OpenAI API key not configured. Using template script instead." "WARN"

    # Fallback: Use template script
    $script = "This $($product.name) is amazing! Perfect for everyday use. Link in bio for discount."

  } else {
    $prompt = @"
Create a 15-second TikTok video script for this product:

Product: $($product.name)
Description: $($product.description)
Price: EUR $($product.price)

Requirements:
- Start with attention-grabbing hook (pain point)
- Present product as solution
- Keep under 200 characters total
- End with "Link in bio"
- Use conversational English tone
- Format: Hook (1 sentence) + Solution (1-2 sentences) + CTA (1 sentence)

Generate ONLY the script, no extra text or explanation.
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
          content = "You are a TikTok marketing expert. Create engaging, short scripts."
        },
        @{
          role    = "user"
          content = $prompt
        }
      )
      temperature = 0.8
      max_tokens  = 150
    } | ConvertTo-Json -Depth 10

    $chatgptParams = @{
      Uri     = "https://api.openai.com/v1/chat/completions"
      Method  = "POST"
      Headers = $chatgptHeaders
      Body    = $chatgptBody
    }

    $response = Invoke-RestMethod @chatgptParams
    $script = $response.choices[0].message.content.Trim()
  }

  Write-Log "Generated script ($($script.Length) chars):" "SUCCESS"
  Write-Log "  `"$script`""

} catch {
  Write-Log "ERROR generating ChatGPT script: $_" "ERROR"
  Write-Log "Falling back to template script..." "WARN"

  $script = "This $($product.name) is a game-changer! Perfect solution for your needs. Link in bio for special discount!"
}

# ============================================
# STEP 3: CREATE VIDEO WITH SYNTHESIA
# ============================================

Write-Log "STEP 3: Creating video with Synthesia..."

# Select avatar based on time slot (variety)
$avatar = switch ($TimeSlot) {
  "Morning" { $config.Avatars.Default }
  "Lunch" { $config.Avatars.Alternatives[0] }
  "Evening" { $config.Avatars.Alternatives[1] }
}

Write-Log "  - Avatar: $avatar"
Write-Log "  - Voice: $($config.Voices.English)"

try {
  # Call Generate-AI-Video.ps1
  $videoScriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) "scripts\Generate-AI-Video.ps1"

  if (-not (Test-Path $videoScriptPath)) {
    throw "Generate-AI-Video.ps1 not found at: $videoScriptPath"
  }

  $videoParams = @{
    ProductName       = $product.name
    Script            = $script
    AvatarID          = $avatar
    Voice             = $config.Voices.English
    WaitForCompletion = $true
  }

  Write-Log "Calling Generate-AI-Video.ps1 (this may take 2-5 minutes)..."

  $result = & $videoScriptPath @videoParams

  if ($result.Success) {
    $videoPath = $result.VideoPath
    Write-Log "Video generated successfully!" "SUCCESS"
    Write-Log "  - Video path: $videoPath"
    Write-Log "  - Video ID: $($result.VideoID)"
  } else {
    throw "Video generation failed: $($result.Error)"
  }

} catch {
  Write-Log "ERROR generating video: $_" "ERROR"
  Write-Log "Check: 1) Synthesia API key valid? 2) Generate-AI-Video.ps1 exists? 3) Synthesia API status?" "ERROR"
  throw
}

# ============================================
# STEP 4: UPLOAD TO TIKTOK (via Publer)
# ============================================

Write-Log "STEP 4: Uploading to TikTok via Publer..."

if ($TestMode) {
  Write-Log "TEST MODE: Skipping TikTok upload" "WARN"
  $tiktokUrl = "https://tiktok.com/@youraccount/test-video-$timestamp"
} else {
  try {
    if (-not $config.TikTok.PublerAPIKey -or $config.TikTok.PublerAPIKey -eq "YOUR-PUBLER-API-KEY-HERE") {
      Write-Log "Publer API key not configured. Skipping TikTok upload." "WARN"
      Write-Log "To enable auto-posting: 1) Register at publer.io, 2) Add API key to config.json" "WARN"
      $tiktokUrl = "[Manual upload required: $videoPath]"
    } else {
      # Note: This is a simplified example
      # In reality, you'd need to:
      # 1. Upload video to cloud storage (Google Drive, Dropbox, AWS S3)
      # 2. Use Publer API to schedule post with video URL

      Write-Log "Publer integration requires video upload to cloud storage first" "WARN"
      Write-Log "Manual step: Upload $videoPath to TikTok" "WARN"
      $tiktokUrl = "[Upload manually: $videoPath]"

      # TODO: Implement cloud storage upload + Publer API call
      # See Zapier-Workflows.md for detailed Publer API documentation
    }

  } catch {
    Write-Log "ERROR uploading to TikTok: $_" "ERROR"
    $tiktokUrl = "[Upload failed - manual intervention required]"
  }
}

# ============================================
# STEP 5: ADD TO SHOPIFY (if not exists)
# ============================================

Write-Log "STEP 5: Adding product to Shopify..."

try {
  if (-not $config.Shopify.APIKey -or $config.Shopify.APIKey -eq "YOUR-SHOPIFY-API-KEY-HERE") {
    Write-Log "Shopify API not configured. Skipping product creation." "WARN"
    $shopifyUrl = "[Configure Shopify API in config.json]"
  } else {
    $shopifyHeaders = @{
      "X-Shopify-Access-Token" = $config.Shopify.Password
      "Content-Type"           = "application/json"
    }

    # Check if product already exists
    $searchParams = @{
      Uri     = "$($config.Shopify.StoreURL)/admin/api/2024-01/products.json?title=$($product.name)"
      Method  = "GET"
      Headers = $shopifyHeaders
    }

    $existingProducts = Invoke-RestMethod @searchParams

    if ($existingProducts.products.Count -eq 0) {
      # Product doesn't exist, create it

      $markup = 2.5  # 150% profit margin
      $salePrice = [math]::Round($product.price * $markup, 2)

      Write-Log "Creating new product: EUR $($product.price) -> EUR $salePrice (150% markup)"

      $shopifyBody = @{
        product = @{
          title        = $product.name
          body_html    = $product.description
          vendor       = "BigBuy"
          product_type = $product.category
          tags         = "tiktok,automated,$TimeSlot"
          variants     = @(
            @{
              price                = $salePrice
              sku                  = $product.id
              inventory_quantity   = 999
              inventory_management = "shopify"
            }
          )
        }
      } | ConvertTo-Json -Depth 10

      $createParams = @{
        Uri     = "$($config.Shopify.StoreURL)/admin/api/2024-01/products.json"
        Method  = "POST"
        Headers = $shopifyHeaders
        Body    = $shopifyBody
      }

      $newProduct = Invoke-RestMethod @createParams
      $shopifyUrl = "$($config.Shopify.StoreURL)/products/$($newProduct.product.handle)"

      Write-Log "Product created in Shopify!" "SUCCESS"
      Write-Log "  - URL: $shopifyUrl"
      Write-Log "  - Price: EUR $salePrice (EUR $profit profit per sale)"

    } else {
      $shopifyUrl = "$($config.Shopify.StoreURL)/products/$($existingProducts.products[0].handle)"
      Write-Log "Product already exists in Shopify: $shopifyUrl" "SUCCESS"
    }
  }

} catch {
  Write-Log "ERROR adding to Shopify: $_" "ERROR"
  $shopifyUrl = "[Shopify error - check logs]"
}

# ============================================
# STEP 6: SEND NOTIFICATION EMAIL
# ============================================

Write-Log "STEP 6: Sending notification email..."

try {
  if (-not $config.Email.Username -or $config.Email.Username -eq "your-email@gmail.com") {
    Write-Log "Email not configured. Skipping notification." "WARN"
  } else {
    $salePrice = [math]::Round($product.price * 2.5, 2)
    $profit = [math]::Round($salePrice - $product.price, 2)

    $emailBody = @"
✅ $TimeSlot Video Successfully Generated!

Product: $($product.name)
Price: EUR $($product.price) (cost) -> EUR $salePrice (sale)
Profit margin: 150% (EUR $profit per sale)

Script ($($script.Length) chars):
"$script"

Video: $videoPath
TikTok: $tiktokUrl
Shopify: $shopifyUrl

Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Log file: $logFile

---
This is an automated message from your PowerShell dropshipping system.
DO NOT REPLY - this is a send-only email.
"@

    Send-MailMessage `
      -From $config.Email.From `
      -To $config.Email.To `
      -Subject "✅ $TimeSlot Video Generated - $($product.name)" `
      -Body $emailBody `
      -SmtpServer $config.Email.SmtpServer `
      -Port $config.Email.Port `
      -UseSsl `
      -Credential (New-Object System.Management.Automation.PSCredential(
        $config.Email.Username,
        (ConvertTo-SecureString $config.Email.Password -AsPlainText -Force)
      ))

    Write-Log "Notification email sent to $($config.Email.To)" "SUCCESS"
  }

} catch {
  Write-Log "ERROR sending email: $_" "WARN"
  Write-Log "Email notification failed, but workflow completed successfully" "WARN"
}

# ============================================
# FINAL SUMMARY
# ============================================

Write-Log "========================================" "SUCCESS"
Write-Log "VIDEO GENERATION COMPLETED" "SUCCESS"
Write-Log "========================================" "SUCCESS"
Write-Log "Time slot: $TimeSlot"
Write-Log "Product: $($product.name)"
Write-Log "Script: `"$script`""
Write-Log "Video: $videoPath"
Write-Log "TikTok: $tiktokUrl"
Write-Log "Shopify: $shopifyUrl"
Write-Log "Log file: $logFile"
Write-Log "========================================" "SUCCESS"

# Return summary object (for further automation)
return @{
  Success    = $true
  TimeSlot   = $TimeSlot
  Product    = @{
    Name  = $product.name
    ID    = $product.id
    Price = $product.price
  }
  Script     = $script
  VideoPath  = $videoPath
  TikTokUrl  = $tiktokUrl
  ShopifyUrl = $shopifyUrl
  Timestamp  = $timestamp
  LogFile    = $logFile
}
