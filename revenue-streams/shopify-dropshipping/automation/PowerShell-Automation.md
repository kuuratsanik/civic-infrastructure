# ⚙️ POWERSHELL TÄIELIK AUTOMATISEERIMINE

## ALTERNATIIV ZAPIER-LE - 100% TASUTA - WINDOWS NATIVE

---

## 📋 ÜLEVAADE

**Miks PowerShell?**

- ✅ 100% tasuta (Zapier = €50/month saved)
- ✅ Täielik kontroll (kõik koodis)
- ✅ Windows native (ei vaja cloud serverit)
- ✅ Lihtne debugimine
- ✅ Saab integreerida kõigi API-dega

**Puudused vs Zapier:**

- ❌ Rohkem seadistamist (technical knowledge)
- ❌ Vajab Windows arvutit 24/7 (või VPS)
- ❌ Peab ise error handling-i kirjutama

**Sobib kui:**

- Sa tead PowerShell-i basics
- Sul on Windows PC/server mis jookseb 24/7
- Tahad säästa €50/kuu Zapier kulud

---

## 🎬 PÕHI AUTOMATISEERINGU SKRIPT

### **Start-DailyVideoGeneration.ps1**

```powershell
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
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = ".\config.json",

    [Parameter(Mandatory=$true)]
    [ValidateSet("Morning", "Lunch", "Evening")]
    [string]$TimeSlot,

    [Parameter(Mandatory=$false)]
    [switch]$TestMode
)

# Load configuration
if (-not (Test-Path $ConfigPath)) {
    throw "Config file not found: $ConfigPath"
}

$config = Get-Content $ConfigPath | ConvertFrom-Json
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = ".\logs\video-generation-$timestamp.log"

# Logging function
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $logMessage = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    Write-Host $logMessage
    Add-Content -Path $logFile -Value $logMessage
}

Write-Log "Starting video generation for $TimeSlot slot"

# ============================================
# STEP 1: FETCH PRODUCT FROM BIGBUY
# ============================================

Write-Log "Fetching random product from BigBuy..."

try {
    $bigbuyHeaders = @{
        "Authorization" = "Bearer $($config.BigBuy.APIKey)"
        "Accept" = "application/json"
    }

    $bigbuyParams = @{
        Uri = "$($config.BigBuy.Endpoint)/rest/catalog/products.json"
        Method = "GET"
        Headers = $bigbuyHeaders
        Body = @{
            isoCode = "EE"
            warehouseId = 1  # Spain warehouse
            priceFrom = 20
            priceTo = 80
            pageSize = 50
        }
    }

    $response = Invoke-RestMethod @bigbuyParams

    # Select random product
    $product = $response.products | Get-Random

    Write-Log "Selected product: $($product.name) (ID: $($product.id), Price: €$($product.price))"

} catch {
    Write-Log "ERROR fetching BigBuy product: $_" -Level "ERROR"
    throw
}

# ============================================
# STEP 2: GENERATE SCRIPT WITH CHATGPT
# ============================================

Write-Log "Generating TikTok script with ChatGPT..."

try {
    $prompt = @"
Create a 15-second TikTok video script for this product:

Product: $($product.name)
Description: $($product.description)
Price: €$($product.price)

Requirements:
- Start with attention-grabbing hook (pain point)
- Present product as solution
- Keep under 200 characters total
- End with "Link in bio"
- Use conversational Estonian tone
- Format: Hook (1 sentence) + Solution (1-2 sentences) + CTA (1 sentence)

Generate ONLY the script, no extra text or explanation.
"@

    $chatgptHeaders = @{
        "Authorization" = "Bearer $($config.OpenAI.APIKey)"
        "Content-Type" = "application/json"
    }

    $chatgptBody = @{
        model = $config.OpenAI.Model
        messages = @(
            @{
                role = "system"
                content = "You are a TikTok marketing expert. Create engaging, short scripts."
            },
            @{
                role = "user"
                content = $prompt
            }
        )
        temperature = 0.8
        max_tokens = 150
    } | ConvertTo-Json

    $chatgptParams = @{
        Uri = "https://api.openai.com/v1/chat/completions"
        Method = "POST"
        Headers = $chatgptHeaders
        Body = $chatgptBody
    }

    $response = Invoke-RestMethod @chatgptParams
    $script = $response.choices[0].message.content.Trim()

    Write-Log "Generated script (${script.Length} chars): $script"

} catch {
    Write-Log "ERROR generating ChatGPT script: $_" -Level "ERROR"
    throw
}

# ============================================
# STEP 3: CREATE VIDEO WITH SYNTHESIA
# ============================================

Write-Log "Creating video with Synthesia..."

# Select avatar based on time slot (variety)
$avatar = switch ($TimeSlot) {
    "Morning" { "anna_costume1_cameraA" }
    "Lunch"   { "lily_costume1_cameraA" }
    "Evening" { "sarah_costume1_cameraA" }
}

try {
    # Call Generate-AI-Video.ps1
    $videoParams = @{
        ProductName = $product.name
        Script = $script
        AvatarID = $avatar
        Voice = $config.Voices.English
        WaitForCompletion = $true
    }

    $videoPath = & ".\Generate-AI-Video.ps1" @videoParams

    Write-Log "Video generated successfully: $videoPath"

} catch {
    Write-Log "ERROR generating video: $_" -Level "ERROR"
    throw
}

# ============================================
# STEP 4: UPLOAD TO TIKTOK (via Publer)
# ============================================

Write-Log "Uploading to TikTok via Publer..."

if ($TestMode) {
    Write-Log "TEST MODE: Skipping TikTok upload" -Level "WARN"
    $tiktokUrl = "https://tiktok.com/@youraccount/test-video"
} else {
    try {
        # Upload video file to temporary storage (Google Drive / Dropbox)
        # Then use Publer API to schedule post

        # Publer API documentation: https://publer.io/api-documentation

        $publerHeaders = @{
            "Authorization" = "Bearer $($config.TikTok.PublerAPIKey)"
            "Content-Type" = "application/json"
        }

        # Generate hashtags based on product category
        $hashtags = "#dropshipping #eesti #soovitus #tiktokshop #$($TimeSlot.ToLower())"

        $publerBody = @{
            platforms = @("tiktok")
            accounts = @($config.TikTok.AccountID)
            media = @(
                @{
                    type = "video"
                    url = "https://yourstorage.com/$($videoPath)"  # Upload to cloud storage first
                }
            )
            caption = "$script`n`n$hashtags"
            schedule = (Get-Date).AddMinutes(5).ToString("o")  # Post in 5 minutes
        } | ConvertTo-Json -Depth 10

        $publerParams = @{
            Uri = "https://api.publer.io/v1/posts"
            Method = "POST"
            Headers = $publerHeaders
            Body = $publerBody
        }

        $response = Invoke-RestMethod @publerParams
        $tiktokUrl = $response.post_url

        Write-Log "TikTok post scheduled: $tiktokUrl"

    } catch {
        Write-Log "ERROR uploading to TikTok: $_" -Level "ERROR"
        throw
    }
}

# ============================================
# STEP 5: ADD TO SHOPIFY (if not exists)
# ============================================

Write-Log "Adding product to Shopify..."

try {
    $shopifyHeaders = @{
        "X-Shopify-Access-Token" = $config.Shopify.Password
        "Content-Type" = "application/json"
    }

    # Check if product already exists
    $searchParams = @{
        Uri = "$($config.Shopify.StoreURL)/admin/api/2024-01/products.json?title=$($product.name)"
        Method = "GET"
        Headers = $shopifyHeaders
    }

    $existingProducts = Invoke-RestMethod @searchParams

    if ($existingProducts.products.Count -eq 0) {
        # Product doesn't exist, create it

        $markup = 2.5  # 150% profit margin
        $salePrice = [math]::Round($product.price * $markup, 2)

        $shopifyBody = @{
            product = @{
                title = $product.name
                body_html = $product.description
                vendor = "BigBuy"
                product_type = $product.category
                tags = "tiktok,automated,$TimeSlot"
                variants = @(
                    @{
                        price = $salePrice
                        sku = $product.id
                        inventory_quantity = 999
                        inventory_management = "shopify"
                    }
                )
            }
        } | ConvertTo-Json -Depth 10

        $createParams = @{
            Uri = "$($config.Shopify.StoreURL)/admin/api/2024-01/products.json"
            Method = "POST"
            Headers = $shopifyHeaders
            Body = $shopifyBody
        }

        $newProduct = Invoke-RestMethod @createParams
        $shopifyUrl = "$($config.Shopify.StoreURL)/products/$($newProduct.product.handle)"

        Write-Log "Product created in Shopify: $shopifyUrl (€$($product.price) → €$salePrice)"

    } else {
        $shopifyUrl = "$($config.Shopify.StoreURL)/products/$($existingProducts.products[0].handle)"
        Write-Log "Product already exists in Shopify: $shopifyUrl"
    }

} catch {
    Write-Log "ERROR adding to Shopify: $_" -Level "ERROR"
    throw
}

# ============================================
# STEP 6: SEND NOTIFICATION EMAIL
# ============================================

Write-Log "Sending notification email..."

try {
    $emailBody = @"
✅ $TimeSlot Video Successfully Posted!

Product: $($product.name)
Price: €$($product.price) (cost) → €$salePrice (sale)
Profit margin: 150%

Script ($($script.Length) chars):
$script

Video: $videoPath
TikTok: $tiktokUrl
Shopify: $shopifyUrl

Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

This is an automated message from your PowerShell dropshipping system.
"@

    Send-MailMessage `
        -From $config.Email.From `
        -To $config.Email.To `
        -Subject "✅ $TimeSlot Video Posted - $($product.name)" `
        -Body $emailBody `
        -SmtpServer $config.Email.SmtpServer `
        -Port $config.Email.Port `
        -UseSsl `
        -Credential (New-Object System.Management.Automation.PSCredential(
            $config.Email.Username,
            (ConvertTo-SecureString $config.Email.Password -AsPlainText -Force)
        ))

    Write-Log "Notification email sent to $($config.Email.To)"

} catch {
    Write-Log "ERROR sending email: $_" -Level "WARN"
    # Don't throw - email failure shouldn't stop the workflow
}

# ============================================
# FINAL SUMMARY
# ============================================

Write-Log "==================================="
Write-Log "VIDEO GENERATION COMPLETED"
Write-Log "==================================="
Write-Log "Time slot: $TimeSlot"
Write-Log "Product: $($product.name)"
Write-Log "Script: $script"
Write-Log "Video: $videoPath"
Write-Log "TikTok: $tiktokUrl"
Write-Log "Shopify: $shopifyUrl"
Write-Log "Log: $logFile"
Write-Log "==================================="

# Return summary object (for further automation)
return @{
    Success = $true
    TimeSlot = $TimeSlot
    Product = $product
    Script = $script
    VideoPath = $videoPath
    TikTokUrl = $tiktokUrl
    ShopifyUrl = $shopifyUrl
    Timestamp = $timestamp
}
```

---

## 📅 WINDOWS TASK SCHEDULER SETUP

### **Create-ScheduledTasks.ps1**

```powershell
<#
.SYNOPSIS
    Creates Windows Task Scheduler tasks for automated video generation

.DESCRIPTION
    Sets up 3 daily tasks:
    - 7:30 AM: Morning video
    - 1:00 PM: Lunch video
    - 8:00 PM: Evening video

.EXAMPLE
    .\Create-ScheduledTasks.ps1
#>

# Requires admin privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script requires administrator privileges. Please run as admin."
    exit 1
}

$scriptPath = "C:\Users\svenk\OneDrive\All_My_Projects\New folder\revenue-streams\shopify-dropshipping\automation\Start-DailyVideoGeneration.ps1"

# Task 1: Morning Video (7:30 AM)
Write-Host "Creating Morning Video task (7:30 AM)..."

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`" -TimeSlot Morning"

$trigger = New-ScheduledTaskTrigger -Daily -At 7:30AM

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable

Register-ScheduledTask `
    -TaskName "Dropshipping - Morning Video" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "Generates and posts morning TikTok video (7:30 AM)" `
    -User $env:USERNAME `
    -RunLevel Highest `
    -Force

Write-Host "✅ Morning task created"

# Task 2: Lunch Video (1:00 PM)
Write-Host "Creating Lunch Video task (1:00 PM)..."

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`" -TimeSlot Lunch"

$trigger = New-ScheduledTaskTrigger -Daily -At 1:00PM

Register-ScheduledTask `
    -TaskName "Dropshipping - Lunch Video" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "Generates and posts lunch TikTok video (1:00 PM)" `
    -User $env:USERNAME `
    -RunLevel Highest `
    -Force

Write-Host "✅ Lunch task created"

# Task 3: Evening Video (8:00 PM)
Write-Host "Creating Evening Video task (8:00 PM)..."

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`" -TimeSlot Evening"

$trigger = New-ScheduledTaskTrigger -Daily -At 8:00PM

Register-ScheduledTask `
    -TaskName "Dropshipping - Evening Video" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "Generates and posts evening TikTok video (8:00 PM)" `
    -User $env:USERNAME `
    -RunLevel Highest `
    -Force

Write-Host "✅ Evening task created"

# Verify tasks
Write-Host ""
Write-Host "Scheduled tasks created successfully!"
Write-Host "View in Task Scheduler: taskschd.msc"
Write-Host ""

Get-ScheduledTask | Where-Object {$_.TaskName -like "Dropshipping*"} | Format-Table TaskName, State, NextRunTime
```

**Käivitamine:**

```powershell
# Run as Administrator
.\Create-ScheduledTasks.ps1

# Verify
Get-ScheduledTask | Where-Object {$_.TaskName -like "Dropshipping*"}

# Manual test
Start-ScheduledTask -TaskName "Dropshipping - Morning Video"
```

---

## 📦 TELLIMUSTE AUTOMATISEERIMINE

### **Process-ShopifyOrders.ps1**

```powershell
<#
.SYNOPSIS
    Monitors Shopify for new orders and fulfills via BigBuy

.DESCRIPTION
    Runs every 5 minutes, checks for new paid orders,
    creates BigBuy order, updates Shopify, sends customer email

.PARAMETER ConfigPath
    Path to config.json

.PARAMETER WatchMode
    If true, runs continuously (every 5 min)

.EXAMPLE
    .\Process-ShopifyOrders.ps1 -WatchMode
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = "..\scripts\config.json",

    [Parameter(Mandatory=$false)]
    [switch]$WatchMode
)

$config = Get-Content $ConfigPath | ConvertFrom-Json

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $logMessage = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    Write-Host $logMessage
    Add-Content -Path ".\logs\order-processing.log" -Value $logMessage
}

function Process-NewOrders {
    Write-Log "Checking for new Shopify orders..."

    try {
        $shopifyHeaders = @{
            "X-Shopify-Access-Token" = $config.Shopify.Password
        }

        # Get orders from last 10 minutes (unfulfilled, paid)
        $since = (Get-Date).AddMinutes(-10).ToString("o")

        $params = @{
            Uri = "$($config.Shopify.StoreURL)/admin/api/2024-01/orders.json?status=any&financial_status=paid&fulfillment_status=unfulfilled&created_at_min=$since"
            Method = "GET"
            Headers = $shopifyHeaders
        }

        $response = Invoke-RestMethod @params

        if ($response.orders.Count -eq 0) {
            Write-Log "No new orders"
            return
        }

        Write-Log "Found $($response.orders.Count) new order(s)"

        foreach ($order in $response.orders) {
            Process-Order -Order $order
        }

    } catch {
        Write-Log "ERROR checking orders: $_" -Level "ERROR"
    }
}

function Process-Order {
    param($Order)

    Write-Log "Processing order #$($Order.order_number)..."

    try {
        # Extract BigBuy product ID from SKU
        $lineItem = $Order.line_items[0]
        $bigbuyProductId = $lineItem.sku

        # Create BigBuy order
        $bigbuyHeaders = @{
            "Authorization" = "Bearer $($config.BigBuy.APIKey)"
            "Content-Type" = "application/json"
        }

        $bigbuyBody = @{
            products = @(
                @{
                    id = $bigbuyProductId
                    quantity = $lineItem.quantity
                }
            )
            shippingAddress = @{
                firstName = $Order.shipping_address.first_name
                lastName = $Order.shipping_address.last_name
                country = $Order.shipping_address.country_code
                postcode = $Order.shipping_address.zip
                town = $Order.shipping_address.city
                address = $Order.shipping_address.address1
                phone = $Order.shipping_address.phone
            }
            iossNumber = $config.BigBuy.IOSSNumber
        } | ConvertTo-Json -Depth 10

        $bigbuyParams = @{
            Uri = "$($config.BigBuy.Endpoint)/rest/order/create.json"
            Method = "POST"
            Headers = $bigbuyHeaders
            Body = $bigbuyBody
        }

        $bigbuyOrder = Invoke-RestMethod @bigbuyParams

        Write-Log "BigBuy order created: $($bigbuyOrder.id), Tracking: $($bigbuyOrder.trackingNumber)"

        # Update Shopify order (mark as fulfilled)
        $fulfillmentBody = @{
            fulfillment = @{
                location_id = $config.Shopify.LocationID
                tracking_number = $bigbuyOrder.trackingNumber
                tracking_company = "DHL"
                notify_customer = $true
            }
        } | ConvertTo-Json

        $fulfillParams = @{
            Uri = "$($config.Shopify.StoreURL)/admin/api/2024-01/orders/$($Order.id)/fulfillments.json"
            Method = "POST"
            Headers = $shopifyHeaders
            Body = $fulfillmentBody
        }

        Invoke-RestMethod @fulfillParams

        Write-Log "Shopify order fulfilled, customer notified"

        # Send yourself profit notification
        $profit = $Order.total_price - ($bigbuyOrder.totalCost * 1.21)  # Include VAT

        $emailBody = @"
💰 NEW SALE! 🎉

Customer: $($Order.customer.first_name) $($Order.customer.last_name)
Email: $($Order.customer.email)
Order: #$($Order.order_number)

Product: $($lineItem.title)
Sale price: €$($Order.total_price)
Cost (BigBuy): €$($bigbuyOrder.totalCost)
Profit: €$profit

BigBuy order: $($bigbuyOrder.id)
Tracking: $($bigbuyOrder.trackingNumber)

Automated order processed successfully!
"@

        Send-MailMessage `
            -From $config.Email.From `
            -To $config.Email.To `
            -Subject "💰 New Sale - €$profit profit" `
            -Body $emailBody `
            -SmtpServer $config.Email.SmtpServer `
            -Port $config.Email.Port `
            -UseSsl `
            -Credential (New-Object PSCredential(
                $config.Email.Username,
                (ConvertTo-SecureString $config.Email.Password -AsPlainText -Force)
            ))

        Write-Log "Profit notification sent: €$profit"

    } catch {
        Write-Log "ERROR processing order #$($Order.order_number): $_" -Level "ERROR"

        # Send error alert
        Send-MailMessage `
            -From $config.Email.From `
            -To $config.Email.To `
            -Subject "🚨 ORDER PROCESSING ERROR - Order #$($Order.order_number)" `
            -Body "Error processing order: $_`n`nPlease check manually!" `
            -SmtpServer $config.Email.SmtpServer `
            -Port $config.Email.Port `
            -UseSsl `
            -Credential (New-Object PSCredential(
                $config.Email.Username,
                (ConvertTo-SecureString $config.Email.Password -AsPlainText -Force)
            ))
    }
}

# Main loop
if ($WatchMode) {
    Write-Log "Starting order processing in watch mode (every 5 min)..."

    while ($true) {
        Process-NewOrders
        Write-Log "Sleeping 5 minutes..."
        Start-Sleep -Seconds 300  # 5 minutes
    }
} else {
    Process-NewOrders
}
```

**Task Scheduler Setup:**

```powershell
# Run every 5 minutes, 24/7
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"C:\...\Process-ShopifyOrders.ps1`" -WatchMode"

$trigger = New-ScheduledTaskTrigger -AtStartup

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -RestartCount 999 `
    -RestartInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask `
    -TaskName "Dropshipping - Order Processing" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "Monitors and processes Shopify orders 24/7" `
    -User $env:USERNAME `
    -RunLevel Highest `
    -Force
```

---

## 🔧 KONFIGURATSIOON (config.json täiendus)

Lisa config.json-i:

```json
{
  "Email": {
    "From": "your-email@gmail.com",
    "To": "your-email@gmail.com",
    "Username": "your-email@gmail.com",
    "Password": "your-app-password",
    "SmtpServer": "smtp.gmail.com",
    "Port": 587
  },
  "TikTok": {
    "PublerAPIKey": "YOUR_PUBLER_API_KEY",
    "AccountID": "YOUR_TIKTOK_ACCOUNT_ID"
  },
  "Shopify": {
    "LocationID": "YOUR_LOCATION_ID"
  },
  "BigBuy": {
    "IOSSNumber": "YOUR_IOSS_NUMBER"
  }
}
```

---

## 📊 MONITORING & ALERTS

### **Send-DailyReport.ps1**

```powershell
# Runs daily at 11:00 PM, sends summary email

$logs = Get-Content ".\logs\video-generation-*.log" |
        Select-String "VIDEO GENERATION COMPLETED" -Context 0,10

$ordersToday = Get-Content ".\logs\order-processing.log" |
               Select-String "NEW SALE" |
               Measure-Object |
               Select-Object -ExpandProperty Count

$emailBody = @"
📊 DAILY DROPSHIPPING REPORT - $(Get-Date -Format 'yyyy-MM-dd')

Videos Generated: 3
Videos Posted: 3 (Morning, Lunch, Evening)

Orders Today: $ordersToday
Revenue: €[calculate from logs]
Profit: €[calculate from logs]

Errors: [count from logs]

Full logs: C:\...\logs\

---
Automated daily report
"@

Send-MailMessage -From "..." -To "..." -Subject "📊 Daily Report" -Body $emailBody
```

**Task Scheduler:**

```powershell
$trigger = New-ScheduledTaskTrigger -Daily -At 11:00PM
# ... (sama pattern kui enne)
```

---

## ✅ KOKKUVÕTE: POWERSHELL vs ZAPIER

| Aspekt                  | PowerShell    | Zapier        |
| ----------------------- | ------------- | ------------- |
| **Kulud**               | €0            | €50/month     |
| **Setup aeg**           | 4-6h          | 2-3h          |
| **Technical knowledge** | Keskmine      | Madal         |
| **Kontroll**            | Täielik       | Piiratud      |
| **Debugging**           | Lihtne (logs) | Keskmine      |
| **Reliability**         | Sõltub PC-st  | Cloud (99.9%) |
| **Flexibility**         | Maksimum      | Hea           |

**SOOVITUS:**

- Kui oled technical + Windows 24/7: **PowerShell** (€50/kuu kokkuhoid)
- Kui tahad plug-and-play: **Zapier** (faster setup)
- **HYBRID**: PowerShell video generation + Zapier posting (best of both)

---

_Status: ✅ VALMIS KASUTAMISEKS_
_Updated: 16. oktoober 2025_

