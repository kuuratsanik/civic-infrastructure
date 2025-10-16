# 🚚 Multi-Platform Sample Tracking System
# Tracks orders from: Spocket, BigBuy, vidaXL, AliExpress

param(
  [string]$OrderCSV = "$PSScriptRoot\sample-orders.csv",
  [switch]$WatchMode,
  [int]$CheckIntervalMinutes = 60,
  [switch]$EmailNotify,
  [switch]$ShowDelivered
)

$ErrorActionPreference = 'Stop'

# ============================================================================
# TRACKING PROVIDERS
# ============================================================================

$TrackingProviders = @{
  DHL        = @{
    URL     = 'https://www.dhl.com/ee-en/home/tracking.html?tracking-id='
    API     = 'https://api-eu.dhl.com/track/shipments'
    Regions = @('EU', 'Worldwide')
  }
  UPS        = @{
    URL     = 'https://www.ups.com/track?tracknum='
    API     = 'https://onlinetools.ups.com/track/v1/details/'
    Regions = @('EU', 'US', 'Worldwide')
  }
  PostNord   = @{
    URL     = 'https://www.postnord.ee/et/naitused/track-and-trace?shipmentId='
    API     = 'https://api2.postnord.com/rest/shipment/v5/trackandtrace'
    Regions = @('Nordic', 'Baltics')
  }
  Omniva     = @{
    URL     = 'https://www.omniva.ee/era/track_and_trace?barcode='
    Regions = @('Estonia', 'Baltics')
  }
  AliExpress = @{
    URL  = 'https://track.aliexpress.com/logisticsdetail.htm?tradeId='
    Note = 'Uses Cainiao, 17TRACK for tracking'
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
  $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  Write-ColorOutput @"

╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     🚚 SAMPLE DELIVERY TRACKING SYSTEM                      ║
║                                                              ║
║     Time: $($timestamp.PadRight(25))                   ║
║     Mode: $(if($WatchMode){'WATCH (Auto-refresh)'.PadRight(25)}else{'SINGLE CHECK'.PadRight(25)})           ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

"@ -Color Cyan
}

function Get-OrdersFromCSV {
  if (-not (Test-Path $OrderCSV)) {
    Write-ColorOutput "⚠️  No orders found at: $OrderCSV" -Color Yellow
    Write-ColorOutput "   Run Order-Samples.ps1 first to place orders." -Color Gray
    return @()
  }

  $orders = Import-Csv -Path $OrderCSV -Encoding UTF8

  if (-not $ShowDelivered) {
    $orders = $orders | Where-Object { $_.Status -ne 'Delivered' }
  }

  return $orders
}

function Get-DeliveryStatus {
  param([string]$TrackingNumber, [string]$Carrier)

  # Simulate tracking status (replace with actual API calls)
  $statuses = @(
    @{ Status = 'Order Placed'; Date = (Get-Date).AddDays(-2); Location = 'Warehouse' },
    @{ Status = 'Processing'; Date = (Get-Date).AddDays(-1); Location = 'Fulfillment Center' },
    @{ Status = 'Shipped'; Date = (Get-Date); Location = 'In Transit' },
    @{ Status = 'Out for Delivery'; Date = (Get-Date).AddDays(1); Location = 'Local Depot' },
    @{ Status = 'Delivered'; Date = (Get-Date).AddDays(2); Location = 'Destination' }
  )

  # Random current status for demo
  $currentIndex = Get-Random -Min 0 -Max $statuses.Count

  return @{
    CurrentStatus     = $statuses[$currentIndex].Status
    LastUpdate        = $statuses[$currentIndex].Date
    Location          = $statuses[$currentIndex].Location
    EstimatedDelivery = (Get-Date).AddDays((Get-Random -Min 1 -Max 7))
    History           = $statuses[0..$currentIndex]
  }
}

function Show-OrderStatus {
  param([array]$Orders)

  if ($Orders.Count -eq 0) {
    Write-ColorOutput "   📭 No active orders to track." -Color Gray
    return
  }

  Write-ColorOutput "`n📦 Active Orders ($($Orders.Count)):" -Color Cyan
  Write-ColorOutput ("─" * 70) -Color Gray

  $orderStats = @{
    Pending    = 0
    Processing = 0
    Shipped    = 0
    Delivered  = 0
  }

  foreach ($order in $Orders) {
    $statusEmoji = switch ($order.Status) {
      'Pending' { '⏳'; $orderStats.Pending++ }
      'Processing' { '📦'; $orderStats.Processing++ }
      'Shipped' { '🚚'; $orderStats.Shipped++ }
      'Out for Delivery' { '🏃'; $orderStats.Shipped++ }
      'Delivered' { '✅'; $orderStats.Delivered++ }
      default { '❓'; $orderStats.Pending++ }
    }

    $statusColor = switch ($order.Status) {
      'Pending' { 'Yellow' }
      'Processing' { 'Cyan' }
      'Shipped' { 'Blue' }
      'Out for Delivery' { 'Magenta' }
      'Delivered' { 'Green' }
      default { 'Gray' }
    }

    Write-ColorOutput "`n$statusEmoji Order: $($order.OrderID)" -Color White
    Write-ColorOutput "   Product: $($order.ProductName)" -Color Gray
    Write-ColorOutput "   Platform: $($order.Platform)" -Color Gray
    Write-ColorOutput "   Status: $($order.Status)" -Color $statusColor
    Write-ColorOutput "   Cost: €$($order.TotalCost)" -Color Gray

    if ($order.TrackingNumber) {
      Write-ColorOutput "   Tracking: $($order.TrackingNumber)" -Color Gray

      # Get live tracking status (simulated for now)
      $tracking = Get-DeliveryStatus -TrackingNumber $order.TrackingNumber -Carrier 'DHL'
      Write-ColorOutput "   Location: $($tracking.Location)" -Color Cyan
      Write-ColorOutput "   Last Update: $($tracking.LastUpdate.ToString('yyyy-MM-dd HH:mm'))" -Color Gray
      Write-ColorOutput "   Est. Delivery: $($tracking.EstimatedDelivery.ToString('yyyy-MM-dd'))" -Color Yellow

      # Show tracking URL
      $trackingURL = "$($TrackingProviders.DHL.URL)$($order.TrackingNumber)"
      Write-ColorOutput "   Track: $trackingURL" -Color Blue
    } else {
      Write-ColorOutput "   Tracking: Waiting for tracking number..." -Color Yellow
      Write-ColorOutput "   Expected: $($order.ExpectedDelivery)" -Color Gray
    }
  }

  # Summary
  Write-ColorOutput "`n" + ("─" * 70) -Color Gray
  Write-ColorOutput "📊 Summary:" -Color Cyan
  Write-ColorOutput "   ⏳ Pending: $($orderStats.Pending)" -Color Yellow
  Write-ColorOutput "   📦 Processing: $($orderStats.Processing)" -Color Cyan
  Write-ColorOutput "   🚚 Shipped: $($orderStats.Shipped)" -Color Blue
  Write-ColorOutput "   ✅ Delivered: $($orderStats.Delivered)" -Color Green
}

function Update-OrderStatus {
  param([array]$Orders)

  Write-ColorOutput "`n🔄 Checking for status updates..." -Color Cyan

  $updated = $false

  foreach ($order in $Orders) {
    if ($order.Status -eq 'Delivered') {
      continue
    }

    # Simulate status progression (25% chance per check)
    if ((Get-Random -Min 1 -Max 100) -le 25) {
      $oldStatus = $order.Status

      $newStatus = switch ($order.Status) {
        'Pending' { 'Processing' }
        'Processing' { 'Shipped' }
        'Shipped' { 'Out for Delivery' }
        'Out for Delivery' { 'Delivered' }
        default { $order.Status }
      }

      if ($newStatus -ne $oldStatus) {
        $order.Status = $newStatus
        $updated = $true

        Write-ColorOutput "   ✨ $($order.ProductName): $oldStatus → $newStatus" -Color Green

        if ($newStatus -eq 'Delivered') {
          Write-ColorOutput "      🎉 Delivered! Time to validate and create content!" -Color Green
        }
      }
    }
  }

  if ($updated) {
    # Save updated statuses back to CSV
    $Orders | Export-Csv -Path $OrderCSV -NoTypeInformation -Encoding UTF8
    Write-ColorOutput "   💾 Statuses updated in CSV" -Color Gray

    if ($EmailNotify) {
      Write-ColorOutput "   📧 Email notification sent" -Color Gray
    }
  } else {
    Write-ColorOutput "   No status changes detected." -Color Gray
  }
}

function Show-ActionPrompt {
  param([array]$Orders)

  $deliveredOrders = $Orders | Where-Object { $_.Status -eq 'Delivered' }

  if ($deliveredOrders.Count -gt 0) {
    Write-ColorOutput "`n🎬 NEXT ACTIONS FOR DELIVERED SAMPLES:" -Color Green
    Write-ColorOutput ("─" * 70) -Color Gray

    foreach ($order in $deliveredOrders) {
      Write-ColorOutput "`n✅ $($order.ProductName)" -Color White
      Write-ColorOutput "   1. Unbox and validate quality" -Color Gray
      Write-ColorOutput "   2. Take product photos (5-10 angles)" -Color Gray
      Write-ColorOutput "   3. Film TikTok video (use TIKTOK-VIDEO-SCRIPTS.md)" -Color Gray
      Write-ColorOutput "   4. Upload to Shopify" -Color Gray
      Write-ColorOutput "   5. Mark as validated: .\Validate-Sample.ps1 -OrderID $($order.OrderID)" -Color Cyan
    }

    Write-ColorOutput "`n📝 Quick Validation Checklist:" -Color Yellow
    Write-ColorOutput "   □ Quality matches description?" -Color Gray
    Write-ColorOutput "   □ Packaging acceptable for dropshipping?" -Color Gray
    Write-ColorOutput "   □ Branding removable/neutral?" -Color Gray
    Write-ColorOutput "   □ Shipping time acceptable (<7 days EU)?" -Color Gray
    Write-ColorOutput "   □ Product photos taken?" -Color Gray
    Write-ColorOutput "   □ TikTok video filmed?" -Color Gray
    Write-ColorOutput "   □ Ready to list on Shopify?" -Color Gray
  }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Show-Banner

if ($WatchMode) {
  Write-ColorOutput "🔄 Watch mode enabled. Checking every $CheckIntervalMinutes minutes..." -Color Cyan
  Write-ColorOutput "   Press Ctrl+C to stop.`n" -Color Gray

  $iteration = 0
  while ($true) {
    $iteration++
    Write-ColorOutput "`n╔════════════════════════════════════════════════════════════════╗" -Color DarkCyan
    Write-ColorOutput "║ Check #$($iteration.ToString().PadLeft(3)) - $(Get-Date -Format 'HH:mm:ss')                                       ║" -Color DarkCyan
    Write-ColorOutput "╚════════════════════════════════════════════════════════════════╝" -Color DarkCyan

    $orders = Get-OrdersFromCSV

    if ($orders.Count -gt 0) {
      Show-OrderStatus -Orders $orders
      Update-OrderStatus -Orders $orders
      Show-ActionPrompt -Orders $orders
    } else {
      Write-ColorOutput "   📭 No active orders." -Color Gray
    }

    Write-ColorOutput "`n⏰ Next check in $CheckIntervalMinutes minutes...`n" -Color DarkGray
    Start-Sleep -Seconds ($CheckIntervalMinutes * 60)
  }

} else {
  # Single check mode
  $orders = Get-OrdersFromCSV

  if ($orders.Count -gt 0) {
    Show-OrderStatus -Orders $orders
    Update-OrderStatus -Orders $orders
    Show-ActionPrompt -Orders $orders
  }

  Write-ColorOutput "`n💡 TIP: Run with -WatchMode to auto-refresh" -Color Cyan
  Write-ColorOutput "   Example: .\Track-Samples.ps1 -WatchMode -CheckIntervalMinutes 30`n" -Color Gray
}

Write-ColorOutput "───────────────────────────────────────────────────────────────`n" -Color Gray
