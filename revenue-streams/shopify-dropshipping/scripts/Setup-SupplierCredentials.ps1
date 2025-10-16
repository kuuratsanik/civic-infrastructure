# Multi-Platform Supplier Setup Script
# Supports: Spocket, BigBuy, vidaXL, AliExpress + Manual alternatives

param(
  [ValidateSet('Spocket', 'BigBuy', 'vidaXL', 'AliExpress', 'All')]
  [string]$Platform = 'All',

  [switch]$CheckStatus,
  [switch]$OpenRegistration
)

$ErrorActionPreference = 'Stop'

# ============================================================================
# SUPPLIER CONFIGURATION
# ============================================================================

$Suppliers = @{
  Spocket    = @{
    Name        = 'Spocket'
    Status      = 'DOWN'
    Priority    = 1

    URLs        = @{
      Registration = 'https://app.spocket.co/auth/register'
      Login        = 'https://app.spocket.co/auth/login'
      Dashboard    = 'https://app.spocket.co/dashboard'
      Pricing      = 'https://www.spocket.co/pricing'
    }

    Pricing     = @{
      Free  = @{ Monthly = 0; Products = 25; Note = 'Starter plan' }
      Basic = @{ Monthly = 29; Products = 'Unlimited'; Premium = $false }
      Pro   = @{ Monthly = 49; Products = 'Unlimited'; Premium = $true }
    }

    Features    = @(
      '[OK] EU warehouse focus (3-7 day delivery)'
      '[OK] Automated order fulfillment'
      '[OK] Invoice customization (remove supplier branding)'
      '[OK] Shopify/WooCommerce integration'
      '[!!] Currently unavailable (IT department working on it)'
    )

    Alternative = 'BigBuy'
  }

  BigBuy     = @{
    Name     = 'BigBuy'
    Status   = 'AVAILABLE'
    Priority = 2

    URLs     = @{
      Registration = 'https://www.bigbuy.eu/en/register'
      Login        = 'https://www.bigbuy.eu/en/login'
      Dashboard    = 'https://www.bigbuy.eu/en/dashboard'
      Catalog      = 'https://www.bigbuy.eu/en/catalogue.html'
      API          = 'https://api.bigbuy.eu'
    }

    Pricing  = @{
      Free = @{ Monthly = 0; Note = 'No subscription fees, pay per order' }
    }

    Features = @(
      '[OK] 100,000+ products'
      '[OK] Spanish warehouse (2-5 day EU delivery)'
      '[OK] Multi-language support'
      '[OK] API integration available'
      '[OK] White-label shipping'
      '[OK] AVAILABLE NOW'
    )

    Setup    = @(
      '1. Register at bigbuy.eu/en/register'
      '2. Verify email and company details'
      '3. Browse catalog (100k+ products)'
      '4. Get API credentials (Dashboard - Integrations)'
      '5. Configure in Order-Samples.ps1'
    )
  }

  vidaXL     = @{
    Name     = 'vidaXL Dropshipping'
    Status   = 'AVAILABLE'
    Priority = 3

    URLs     = @{
      Registration = 'https://www.vidaxl.com/dropshipping'
      Dashboard    = 'https://dropshipping.vidaxl.com'
      Catalog      = 'https://www.vidaxl.com'
    }

    Pricing  = @{
      Free = @{ Monthly = 0; Note = 'No subscription, wholesale prices' }
    }

    Features = @(
      '[OK] 70,000+ products'
      '[OK] Netherlands warehouse (3-7 day EU delivery)'
      '[OK] Furniture and home goods focus'
      '[OK] No monthly fees'
      '[OK] Automated order processing'
      '[OK] AVAILABLE NOW'
    )

    Setup    = @(
      '1. Apply at vidaxl.com/dropshipping'
      '2. Approval process (1-3 business days)'
      '3. Access wholesale catalog'
      '4. Connect to Shopify via app'
      '5. Start importing products'
    )
  }

  AliExpress = @{
    Name     = 'AliExpress Dropshipping'
    Status   = 'AVAILABLE'
    Priority = 4

    URLs     = @{
      Homepage     = 'https://www.aliexpress.com'
      Dropshipping = 'https://www.aliexpress.com/dropshipping'
      DSers        = 'https://www.dsers.com'
    }

    Pricing  = @{
      Free          = @{ Monthly = 0; Note = 'Pay per product' }
      DSersAdvanced = @{ Monthly = 19; Note = 'Automation tool' }
    }

    Features = @(
      '[OK] Largest product selection (millions)'
      '[OK] Very low prices'
      '[!!] Longer shipping (15-30 days from China)'
      '[!!] Requires IOSS registration for EU'
      '[OK] DSers automation tool'
      '[OK] AVAILABLE NOW'
    )

    Setup    = @(
      '1. Register at aliexpress.com'
      '2. Install DSers app on Shopify'
      '3. Connect AliExpress account to DSers'
      '4. [!!] Register IOSS at emta.ee (MANDATORY)'
      '5. Add IOSS number to all orders'
    )

    Warning  = '[!!] IMPORTANT: EU customers require IOSS registration to avoid 80 percent cart abandonment!'
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

================================================================

     SUPPLIER REGISTRATION & SETUP

     Platform: $($Platform.PadRight(20))
     Mode:     $(if($CheckStatus){'Status Check'.PadRight(20)}elseif($OpenRegistration){'Open Registration'.PadRight(20)}else{'Interactive Setup'.PadRight(20)})

================================================================

"@ -Color Cyan
}

function Show-SupplierStatus {
  Write-ColorOutput "`nSupplier Platform Status:" -Color Cyan
  Write-ColorOutput ("=" * 70) -Color Gray

  $sortedSuppliers = $Suppliers.GetEnumerator() | Sort-Object { $_.Value.Priority }

  foreach ($supplier in $sortedSuppliers) {
    $name = $supplier.Value.Name
    $status = $supplier.Value.Status
    $priority = $supplier.Value.Priority

    $statusSymbol = if ($status -eq 'AVAILABLE') { '[OK]' } else { '[!!]' }
    $statusColor = if ($status -eq 'AVAILABLE') { 'Green' } else { 'Yellow' }

    Write-ColorOutput "`n$statusSymbol $name (Priority: $priority)" -Color White
    Write-ColorOutput "   Status: $status" -Color $statusColor
    Write-ColorOutput "   Registration: $($supplier.Value.URLs.Registration)" -Color Blue

    if ($supplier.Value.Pricing.Free) {
      Write-ColorOutput "   Pricing: EUR$($supplier.Value.Pricing.Free.Monthly)/month" -Color Gray
    }

    Write-ColorOutput "   Features:" -Color Gray
    foreach ($feature in $supplier.Value.Features) {
      Write-ColorOutput "      $feature" -Color DarkGray
    }
  }

  Write-ColorOutput "`n" + ("=" * 70) -Color Gray
  Write-ColorOutput "[TIP] Recommendation:" -Color Yellow

  $available = $Suppliers.GetEnumerator() | Where-Object { $_.Value.Status -eq 'AVAILABLE' } | Sort-Object { $_.Value.Priority }
  $recommended = $available[0]

  Write-ColorOutput "   Start with: $($recommended.Value.Name)" -Color Green
  Write-ColorOutput "   Reason: $($recommended.Value.Features[0])" -Color Gray
  Write-ColorOutput "   Register: $($recommended.Value.URLs.Registration)" -Color Blue
}

function Open-SupplierRegistration {
  param([string]$SupplierName)

  $supplier = $Suppliers[$SupplierName]

  Write-ColorOutput "`nOpening registration for: $($supplier.Name)..." -Color Cyan

  if ($supplier.Status -eq 'DOWN') {
    Write-ColorOutput "   [!!] WARNING: This platform is currently unavailable!" -Color Yellow
    Write-ColorOutput "   Error: System messages IT department have been notified" -Color Yellow
    Write-ColorOutput "`n   Recommended alternative: $($supplier.Alternative)" -Color Green

    $altSupplier = $Suppliers[$supplier.Alternative]
    Write-ColorOutput "   Alternative URL: $($altSupplier.URLs.Registration)" -Color Blue

    $response = Read-Host "`n   Switch to $($supplier.Alternative)? (Y/N)"
    if ($response -eq 'Y') {
      Start-Process $altSupplier.URLs.Registration
      return
    } else {
      Write-ColorOutput "   Opening anyway (may not work)..." -Color Yellow
    }
  }

  Start-Process $supplier.URLs.Registration
  Write-ColorOutput "   [OK] Browser opened!" -Color Green

  Write-ColorOutput "`nSetup Steps:" -Color Cyan
  if ($supplier.Setup) {
    foreach ($step in $supplier.Setup) {
      Write-ColorOutput "   $step" -Color Gray
    }
  }

  if ($supplier.Warning) {
    Write-ColorOutput "`n$($supplier.Warning)" -Color Red
  }
}

function Show-SetupGuide {
  param([string]$SupplierName)

  $supplier = $Suppliers[$SupplierName]

  Write-ColorOutput "`n================================================================" -Color Cyan
  Write-ColorOutput "                                                              " -Color Cyan
  Write-ColorOutput "     SETUP GUIDE: $($supplier.Name.PadRight(38))      " -Color Cyan
  Write-ColorOutput "                                                              " -Color Cyan
  Write-ColorOutput "================================================================" -Color Cyan

  Write-ColorOutput "`nURLs:" -Color White
  foreach ($urlType in $supplier.URLs.Keys) {
    Write-ColorOutput "   $urlType : $($supplier.URLs[$urlType])" -Color Gray
  }

  Write-ColorOutput "`nPricing:" -Color White
  foreach ($plan in $supplier.Pricing.Keys) {
    $planData = $supplier.Pricing[$plan]
    Write-ColorOutput "   $plan :" -Color Gray
    foreach ($detail in $planData.Keys) {
      Write-ColorOutput "      $detail : $($planData[$detail])" -Color DarkGray
    }
  }

  Write-ColorOutput "`nFeatures:" -Color White
  foreach ($feature in $supplier.Features) {
    Write-ColorOutput "   $feature" -Color Gray
  }

  if ($supplier.Setup) {
    Write-ColorOutput "`nSetup Steps:" -Color White
    foreach ($step in $supplier.Setup) {
      Write-ColorOutput "   $step" -Color Gray
    }
  }

  if ($supplier.Warning) {
    Write-ColorOutput "`n$($supplier.Warning)" -Color Yellow
  }

  Write-ColorOutput "`nQuick Start:" -Color Cyan
  Write-ColorOutput "   .\Setup-SupplierCredentials.ps1 -Platform $SupplierName -OpenRegistration" -Color White
}

function Interactive-SupplierSelection {
  Write-ColorOutput "`nLet's find the best supplier for you!" -Color Cyan
  Write-ColorOutput ("=" * 70) -Color Gray

  Write-ColorOutput "`n1. Spocket (DOWN - IT working on it)" -Color Yellow
  Write-ColorOutput "   Best for: Fast EU delivery (3-7 days)" -Color Gray
  Write-ColorOutput "   Status: [!!] Currently unavailable" -Color Red

  Write-ColorOutput "`n2. BigBuy (AVAILABLE) [***RECOMMENDED***]" -Color Green
  Write-ColorOutput "   Best for: Large catalog (100k+), Spain warehouse" -Color Gray
  Write-ColorOutput "   Status: [OK] Ready to use" -Color Green

  Write-ColorOutput "`n3. vidaXL (AVAILABLE)" -Color Green
  Write-ColorOutput "   Best for: Furniture & home goods, Netherlands warehouse" -Color Gray
  Write-ColorOutput "   Status: [OK] Ready to use" -Color Green

  Write-ColorOutput "`n4. AliExpress (AVAILABLE)" -Color Green
  Write-ColorOutput "   Best for: Lowest prices, largest selection" -Color Gray
  Write-ColorOutput "   Status: [OK] Ready to use ([!!] Requires IOSS)" -Color Yellow

  Write-ColorOutput "`n5. All (Compare all options)" -Color White

  $choice = Read-Host "`nSelect option (1-5)"

  $selection = switch ($choice) {
    '1' { 'Spocket' }
    '2' { 'BigBuy' }
    '3' { 'vidaXL' }
    '4' { 'AliExpress' }
    '5' { 'All' }
    default { 'BigBuy' }
  }

  if ($selection -eq 'All') {
    Show-SupplierStatus

    $nextChoice = Read-Host "`nOpen registration for which supplier? (1-4)"
    $selection = switch ($nextChoice) {
      '1' { 'Spocket' }
      '2' { 'BigBuy' }
      '3' { 'vidaXL' }
      '4' { 'AliExpress' }
      default { 'BigBuy' }
    }
  }

  Show-SetupGuide -SupplierName $selection

  $openNow = Read-Host "`nOpen registration page now? (Y/N)"
  if ($openNow -eq 'Y') {
    Open-SupplierRegistration -SupplierName $selection
  }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Show-Banner

if ($CheckStatus) {
  Show-SupplierStatus

} elseif ($OpenRegistration) {
  if ($Platform -eq 'All') {
    Write-ColorOutput "[!!] Cannot open 'All' - please specify a platform" -Color Yellow
    Show-SupplierStatus
  } else {
    Open-SupplierRegistration -SupplierName $Platform
  }

} else {
  if ($Platform -ne 'All') {
    Show-SetupGuide -SupplierName $Platform

    $openNow = Read-Host "`nOpen registration page? (Y/N)"
    if ($openNow -eq 'Y') {
      Open-SupplierRegistration -SupplierName $Platform
    }
  } else {
    Interactive-SupplierSelection
  }
}

Write-ColorOutput "`n================================================================" -Color Green
Write-ColorOutput "                                                              " -Color Green
Write-ColorOutput "     [OK] NEXT STEPS                                           " -Color Green
Write-ColorOutput "                                                              " -Color Green
Write-ColorOutput "     1. Complete registration on chosen platform             " -Color Green
Write-ColorOutput "     2. Get API credentials (if available)                   " -Color Green
Write-ColorOutput "     3. Configure Order-Samples.ps1 with credentials         " -Color Green
Write-ColorOutput "     4. Run: .\Order-Samples.ps1 -Platform [NAME]           " -Color Green
Write-ColorOutput "     5. Start TikTok content creation (30-day calendar)      " -Color Green
Write-ColorOutput "                                                              " -Color Green
Write-ColorOutput "================================================================" -Color Green

Write-ColorOutput "`nDocumentation:" -Color Cyan
Write-ColorOutput "   Strategy: .\EUROPEAN-DROPSHIPPING-STRATEGY.md" -Color Gray
Write-ColorOutput "   Checklist: .\QUICK-START-CHECKLIST.md" -Color Gray
Write-ColorOutput "   Products: .\100-PRODUCT-IDEAS-DATABASE.md" -Color Gray
Write-ColorOutput "   TikTok: .\TIKTOK-30DAY-CALENDAR.md" -Color Gray

Write-ColorOutput "`n================================================================`n" -Color Gray
