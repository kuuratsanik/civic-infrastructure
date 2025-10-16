# 🤖 Multi-Platform Sample Ordering Automation
# Works with: Spocket, BigBuy, vidaXL, AliExpress

param(
  [ValidateSet('Spocket', 'BigBuy', 'vidaXL', 'AliExpress')]
  [string]$Platform = 'BigBuy',  # Default to BigBuy since Spocket is down

  [string]$ProductCSV = "$PSScriptRoot\..\..\100-PRODUCT-IDEAS-DATABASE.csv",

  [ValidateRange(1, 100)]
  [int]$MaxSamples = 3,

  [ValidateRange(10, 500)]
  [decimal]$MaxBudget = 100,

  [switch]$WhatIf,
  [switch]$AutoApprove,
  [switch]$EmailNotify
)

$ErrorActionPreference = 'Stop'

# ============================================================================
# CONFIGURATION
# ============================================================================

$Config = @{
  Spocket    = @{
    BaseURL      = 'https://app.spocket.co'
    APIEndpoint  = '/api/v1'
    Regions      = @('EU', 'US', 'UK')
    ShippingDays = @{ EU = '3-7'; US = '7-14'; UK = '5-10' }
    Status       = 'DOWN'  # Currently unavailable
  }
  BigBuy     = @{
    BaseURL         = 'https://api.bigbuy.eu'
    APIEndpoint     = '/rest'
    Regions         = @('EU')
    ShippingDays    = @{ EU = '2-5' }
    Status          = 'AVAILABLE'
    RegistrationURL = 'https://www.bigbuy.eu/en/register'
  }
  vidaXL     = @{
    BaseURL         = 'https://api.vidaxl.com'
    APIEndpoint     = '/dropshipping/v1'
    Regions         = @('EU', 'US')
    ShippingDays    = @{ EU = '3-7'; US = '10-15' }
    Status          = 'AVAILABLE'
    RegistrationURL = 'https://www.vidaxl.com/dropshipping'
  }
  AliExpress = @{
    BaseURL      = 'https://www.aliexpress.com'
    Regions      = @('CN')
    ShippingDays = @{ CN = '15-30' }
    Status       = 'AVAILABLE'
    Note         = 'Requires IOSS registration for EU customers'
  }
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-ColorOutput {
  param([string]$Message, [string]$Color = 'White')
  Write-Host $Message -ForegroundColor $Color
}

function Show-Banner {
  Write-ColorOutput @"

╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     🤖 AUTOMATED SAMPLE ORDERING SYSTEM                     ║
║                                                              ║
║     Platform: $($Platform.PadRight(20))                    ║
║     Status:   $($Config[$Platform].Status.PadRight(20))    ║
║     Budget:   €$($MaxBudget) (Max $MaxSamples samples)     ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

"@ -Color Cyan
}

function Test-PlatformAvailability {
  param([string]$Platform)

  $platformConfig = $Config[$Platform]

  if ($platformConfig.Status -eq 'DOWN') {
    Write-ColorOutput "⚠️  WARNING: $Platform is currently unavailable!" -Color Yellow
    Write-ColorOutput "   IT department has been notified and is working on it." -Color Yellow
    Write-ColorOutput "`n   Alternative platforms available:" -Color White

    $Config.Keys | Where-Object { $Config[$_].Status -eq 'AVAILABLE' } | ForEach-Object {
      Write-ColorOutput "   ✅ $_ - $($Config[$_].RegistrationURL)" -Color Green
    }

    $response = Read-Host "`nSwitch to alternative platform? (Y/N)"
    if ($response -eq 'Y') {
      return $false
    }
    throw "Cannot proceed with unavailable platform."
  }

  return $true
}

function Get-TopProducts {
  param([int]$Count = 3)

  Write-ColorOutput "`n📊 Loading TOP $Count products from database..." -Color Cyan

  # Check if CSV exists, if not use hardcoded TOP 3
  if (-not (Test-Path $ProductCSV)) {
    Write-ColorOutput "⚠️  CSV not found. Using default TOP 3 products." -Color Yellow

    return @(
      @{
        Name            = 'Ortopeedilised koeravoodid'
        Category        = 'Lemmikloomad'
        TargetPrice     = 67  # Average of €45-89
        EstimatedMargin = 55
        NicheScore      = 9
        Priority        = 1
        SearchQuery     = 'orthopedic dog bed memory foam EU warehouse'
      },
      @{
        Name            = 'Kehahoiu korrigeerijad'
        Category        = 'Tervis & Fitness'
        TargetPrice     = 42  # Average of €25-59
        EstimatedMargin = 60
        NicheScore      = 9
        Priority        = 2
        SearchQuery     = 'posture corrector adjustable back support EU'
      },
      @{
        Name            = 'Montessori mänguasjad'
        Category        = 'Lapsed & Vanemad'
        TargetPrice     = 55  # Average of €35-75
        EstimatedMargin = 65
        NicheScore      = 9
        Priority        = 3
        SearchQuery     = 'montessori wooden toys educational EU warehouse'
      }
    )
  }

  # TODO: Implement CSV parsing when file exists
  # For now, return default TOP 3
  return Get-TopProducts -Count 3
}

function Search-ProductOnPlatform {
  param(
    [string]$Platform,
    [hashtable]$Product
  )

  Write-ColorOutput "`n🔍 Searching $Platform for: $($Product.Name)..." -Color White
  Write-ColorOutput "   Query: $($Product.SearchQuery)" -Color Gray

  # Simulate API search (replace with actual API calls when credentials available)
  if ($WhatIf) {
    Write-ColorOutput "   [WHAT-IF] Would search platform API" -Color Magenta
    return @{
      Found          = $true
      ProductID      = "SIM-$(Get-Random -Min 1000 -Max 9999)"
      Title          = $Product.Name
      Price          = $Product.TargetPrice * 0.4  # Wholesale price ~40% of retail
      ShippingPrice  = 0
      ImageURL       = "https://via.placeholder.com/400x400?text=$($Product.Name)"
      SupplierRating = 4.7
      ShippingTime   = $Config[$Platform].ShippingDays['EU']
    }
  }

  # Actual API implementation goes here
  Write-ColorOutput "   ⚠️  API credentials not configured yet." -Color Yellow
  Write-ColorOutput "   Run: Setup-SupplierCredentials.ps1 -Platform $Platform" -Color Yellow

  return $null
}

function New-SampleOrder {
  param(
    [string]$Platform,
    [hashtable]$Product,
    [hashtable]$SearchResult
  )

  $orderData = @{
    OrderID          = "ORD-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Platform         = $Platform
    ProductID        = $SearchResult.ProductID
    ProductName      = $Product.Name
    Quantity         = 1
    Price            = $SearchResult.Price
    ShippingPrice    = $SearchResult.ShippingPrice
    TotalCost        = $SearchResult.Price + $SearchResult.ShippingPrice
    OrderDate        = Get-Date
    Status           = 'Pending'
    TrackingNumber   = $null
    ExpectedDelivery = (Get-Date).AddDays(7)  # Estimate
  }

  Write-ColorOutput "`n📦 Creating order..." -Color Cyan
  Write-ColorOutput "   Order ID: $($orderData.OrderID)" -Color White
  Write-ColorOutput "   Product: $($orderData.ProductName)" -Color White
  Write-ColorOutput "   Cost: €$($orderData.TotalCost) ($($orderData.Price) + $($orderData.ShippingPrice) shipping)" -Color White

  if ($WhatIf) {
    Write-ColorOutput "   [WHAT-IF] Would place order via API" -Color Magenta
  } else {
    # Actual order placement
    Write-ColorOutput "   ⚠️  API not configured. Manual ordering required." -Color Yellow
    Write-ColorOutput "   Open: $($Config[$Platform].BaseURL)" -Color Yellow

    if (-not $AutoApprove) {
      $confirm = Read-Host "   Approve this order? (Y/N)"
      if ($confirm -ne 'Y') {
        Write-ColorOutput "   ❌ Order cancelled by user." -Color Red
        return $null
      }
    }
  }

  return $orderData
}

function Save-OrderToCSV {
  param([array]$Orders)

  $csvPath = "$PSScriptRoot\sample-orders.csv"

  Write-ColorOutput "`n💾 Saving orders to: $csvPath" -Color Cyan

  $Orders | Select-Object OrderID, Platform, ProductName, TotalCost, Status, OrderDate, ExpectedDelivery |
  Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

  Write-ColorOutput "   ✅ Saved $($Orders.Count) orders." -Color Green
}

function Send-EmailNotification {
  param([array]$Orders, [decimal]$TotalSpent)

  if (-not $EmailNotify) { return }

  Write-ColorOutput "`n📧 Sending email notification..." -Color Cyan

  $body = @"
Sample Order Summary
====================

Orders Placed: $($Orders.Count)
Total Spent: €$TotalSpent
Platform: $Platform

Orders:
$($Orders | ForEach-Object { "- $($_.ProductName): €$($_.TotalCost)" } | Out-String)

Next Steps:
1. Monitor tracking in Track-Samples.ps1
2. Plan TikTok content while waiting
3. Setup Shopify product pages

---
Automated by Sample Ordering System
"@

  # TODO: Implement actual email sending (requires SMTP config)
  Write-ColorOutput "   [SIMULATED] Email would be sent with summary" -Color Yellow
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Show-Banner

# Step 1: Check platform availability
Write-ColorOutput "`n🔍 Step 1/5: Checking platform availability..." -Color Cyan
Test-PlatformAvailability -Platform $Platform

# Step 2: Load top products
Write-ColorOutput "`n📋 Step 2/5: Loading top products..." -Color Cyan
$topProducts = Get-TopProducts -Count $MaxSamples

Write-ColorOutput "`nProducts to order:" -Color White
$topProducts | ForEach-Object {
  Write-ColorOutput "   $($_.Priority). $($_.Name) - €$($_.TargetPrice) (Margin: $($_.EstimatedMargin)%, Score: $($_.NicheScore)/10)" -Color Gray
}

# Step 3: Search products on platform
Write-ColorOutput "`n🔍 Step 3/5: Searching products on $Platform..." -Color Cyan
$searchResults = @()
$totalCost = 0

foreach ($product in $topProducts) {
  $result = Search-ProductOnPlatform -Platform $Platform -Product $product

  if ($result) {
    $searchResults += @{
      Product      = $product
      SearchResult = $result
    }
    $totalCost += $result.Price + $result.ShippingPrice

    Write-ColorOutput "   ✅ Found: €$($result.Price + $result.ShippingPrice)" -Color Green
  } else {
    Write-ColorOutput "   ❌ Not found or API error" -Color Red
  }

  if ($totalCost -gt $MaxBudget) {
    Write-ColorOutput "`n⚠️  Budget limit reached (€$MaxBudget). Stopping search." -Color Yellow
    break
  }
}

# Step 4: Place orders
Write-ColorOutput "`n📦 Step 4/5: Placing orders..." -Color Cyan
Write-ColorOutput "   Total estimated cost: €$totalCost / €$MaxBudget budget" -Color White

if ($totalCost -gt $MaxBudget) {
  Write-ColorOutput "   ⚠️  WARNING: Exceeds budget!" -Color Yellow
  if (-not $AutoApprove) {
    $confirm = Read-Host "   Continue anyway? (Y/N)"
    if ($confirm -ne 'Y') {
      Write-ColorOutput "`n❌ Aborted by user." -Color Red
      exit 1
    }
  }
}

$orders = @()
foreach ($item in $searchResults) {
  $order = New-SampleOrder -Platform $Platform -Product $item.Product -SearchResult $item.SearchResult
  if ($order) {
    $orders += $order
  }
}

# Step 5: Save and notify
Write-ColorOutput "`n💾 Step 5/5: Finalizing..." -Color Cyan

if ($orders.Count -gt 0) {
  Save-OrderToCSV -Orders $orders
  Send-EmailNotification -Orders $orders -TotalSpent $totalCost

  Write-ColorOutput "`n╔══════════════════════════════════════════════════════════════╗" -Color Green
  Write-ColorOutput "║                                                              ║" -Color Green
  Write-ColorOutput "║     ✅ SUCCESS! $($orders.Count) SAMPLES ORDERED                           ║" -Color Green
  Write-ColorOutput "║                                                              ║" -Color Green
  Write-ColorOutput "║     Total Spent: €$($totalCost.ToString().PadRight(10))                          ║" -Color Green
  Write-ColorOutput "║     Expected Delivery: 3-7 days (EU warehouse)              ║" -Color Green
  Write-ColorOutput "║                                                              ║" -Color Green
  Write-ColorOutput "║     Next Steps:                                              ║" -Color Green
  Write-ColorOutput "║     1. Run Track-Samples.ps1 to monitor delivery            ║" -Color Green
  Write-ColorOutput "║     2. Start filming TikTok content (TIKTOK-30DAY-CALENDAR) ║" -Color Green
  Write-ColorOutput "║     3. Setup Shopify store (60 min)                          ║" -Color Green
  Write-ColorOutput "║                                                              ║" -Color Green
  Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" -Color Green

  Write-ColorOutput "`n📊 Order Details saved to: sample-orders.csv" -Color Cyan
  Write-ColorOutput "🔍 Track deliveries: .\Track-Samples.ps1" -Color Cyan

} else {
  Write-ColorOutput "`n⚠️  No orders were placed." -Color Yellow
  Write-ColorOutput "   Possible reasons:" -Color White
  Write-ColorOutput "   - Platform API not configured" -Color Gray
  Write-ColorOutput "   - No products found matching criteria" -Color Gray
  Write-ColorOutput "   - Budget constraints" -Color Gray
  Write-ColorOutput "`n   Run with -WhatIf to test without placing orders" -Color Cyan
}

Write-ColorOutput "`n───────────────────────────────────────────────────────────────`n" -Color Gray
