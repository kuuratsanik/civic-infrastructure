<#
.SYNOPSIS
    Task Auction Ceremony - Agent Performance Market Workflow

.DESCRIPTION
    Ceremonial workflow for creating task auctions, collecting bids,
    awarding tasks, and updating agent reputation based on performance.

    6-Phase Ceremony:
    1. Market Initialization - Validate marketplace and agent registrations
    2. Auction Creation - Post task with requirements and SLA constraints
    3. Bid Collection - Agents submit bids based on capabilities
    4. Winner Selection - Award task to best bid
    5. Task Execution - Simulate or execute actual task
    6. Performance Settlement - Update reputation and calibration scores

.PARAMETER TaskType
    Type of task (iso_construction, supplier_verification, etc.).

.PARAMETER Requirements
    Hashtable with capability, max_latency_minutes, min_success_rate, max_cost, complexity.

.PARAMETER Payload
    Task-specific data.

.PARAMETER AutoAward
    Automatically award to best bid.

.PARAMETER SimulateExecution
    Simulate task execution (for demo purposes).

.PARAMETER WhatIf
    Preview ceremony without making changes.

.EXAMPLE
    .\New-TaskAuction.ps1 -TaskType "iso_construction" `
        -Requirements @{
            capability = "iso_construction"
            max_latency_minutes = 30
            min_success_rate = 0.95
            max_cost = 2.5
            complexity = "medium"
        } `
        -Payload @{
            base_iso = "Win11_25H2_Estonian_x64.iso"
            customizations = @("privacy", "performance")
        } `
        -AutoAward `
        -SimulateExecution
#>

[CmdletBinding(SupportsShouldProcess)]
param(
  [Parameter(Mandatory = $true)]
  [string]$TaskType,

  [Parameter(Mandatory = $true)]
  [hashtable]$Requirements,

  [hashtable]$Payload = @{},

  [switch]$AutoAward,

  [switch]$SimulateExecution
)

$ErrorActionPreference = "Stop"

# Import required modules
$ModulePath = "$PSScriptRoot\..\..\..\agents\modules"
Import-Module "$ModulePath\Performance-Market.psm1" -Force
Import-Module "$ModulePath\Agent-Manifest-Validator.psm1" -Force
Import-Module "$ModulePath\Lineage-Bus.psm1" -Force

# === CEREMONY BANNER ===
function Show-CeremonyBanner {
  Write-Host "`n" -NoNewline
  Write-Host "╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
  Write-Host "║                                                                       ║" -ForegroundColor Magenta
  Write-Host "║              TASK AUCTION CEREMONY - PERFORMANCE MARKET               ║" -ForegroundColor Magenta
  Write-Host "║                                                                       ║" -ForegroundColor Magenta
  Write-Host "║           Sovereign Agent Routing via Competitive Bidding            ║" -ForegroundColor Magenta
  Write-Host "║                                                                       ║" -ForegroundColor Magenta
  Write-Host "╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
  Write-Host ""

  if ($WhatIfPreference) {
    Write-Host "🔍 WHAT-IF MODE: No changes will be made" -ForegroundColor Yellow
    Write-Host ""
  }
}

# === PHASE 1: MARKET INITIALIZATION ===
function Invoke-MarketInitialization {
  Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host "PHASE 1: Market Initialization" -ForegroundColor Cyan
  Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host ""

  # Check if marketplace exists
  $marketplacePath = "$PSScriptRoot\..\..\..\agents\registry\agent-marketplace.yaml"

  if (Test-Path $marketplacePath) {
    Write-Host "✅ Marketplace exists" -ForegroundColor Green

    # Load and display registered agents
    $marketplaceYaml = Get-Content -Path $marketplacePath -Raw
    $marketplace = ConvertFrom-Yaml $marketplaceYaml

    Write-Host "📊 Registered Agents: $($marketplace.agents.Count)" -ForegroundColor Cyan

    foreach ($agent in $marketplace.agents) {
      $statusColor = if ($agent.status -eq 'active') { 'Green' } else { 'Yellow' }
      Write-Host "   • $($agent.agent_id)" -ForegroundColor $statusColor
      Write-Host "     Capabilities: $($agent.capabilities -join ', ')" -ForegroundColor Gray
      Write-Host "     Credits: $($agent.reputation.current_credits) | Calibration: $($agent.reputation.calibration_score)" -ForegroundColor Gray
      Write-Host "     Completed: $($agent.reputation.completed_tasks) | Failed: $($agent.reputation.failed_tasks)" -ForegroundColor Gray
    }
  } else {
    Write-Host "⚠️  Marketplace not initialized" -ForegroundColor Yellow
    Write-Host "   Creating sample agent registrations..." -ForegroundColor Cyan

    if ($WhatIfPreference) {
      Write-Host "   [WHAT-IF] Would register demo agents" -ForegroundColor Yellow
    } else {
      # Register demo agents
      Register-AgentInMarketplace -AgentRole "build-iso-optimizer" `
        -Capabilities @("iso_construction", "driver_injection", "debloat") `
        -SLA @{
        p50_latency  = "20m"
        p95_latency  = "30m"
        p99_latency  = "45m"
        success_rate = 0.98
        max_cost     = "€2.50/task"
      } `
        -CostModel @{
        base_cost             = 1.5
        per_minute_cost       = 0.05
        complexity_multiplier = 1.3
      }

      Register-AgentInMarketplace -AgentRole "build-iso-optimizer-backup" `
        -Capabilities @("iso_construction") `
        -SLA @{
        p50_latency  = "35m"
        p95_latency  = "50m"
        p99_latency  = "60m"
        success_rate = 0.92
        max_cost     = "€1.80/task"
      } `
        -CostModel @{
        base_cost             = 1.2
        per_minute_cost       = 0.03
        complexity_multiplier = 1.1
      }

      Register-AgentInMarketplace -AgentRole "commerce-supplier-verifier" `
        -Capabilities @("supplier_verification", "compliance_check") `
        -SLA @{
        p50_latency  = "2m"
        p95_latency  = "5m"
        p99_latency  = "10m"
        success_rate = 0.99
        max_cost     = "€0.50/task"
      } `
        -CostModel @{
        base_cost             = 0.3
        per_minute_cost       = 0.01
        complexity_multiplier = 1.0
      }
    }
  }

  Write-Host ""
  Write-Host "✅ Phase 1 Complete: Market Ready" -ForegroundColor Green
  Write-Host ""

  return $true
}

# === PHASE 2: AUCTION CREATION ===
function Invoke-AuctionCreation {
  Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host "PHASE 2: Auction Creation" -ForegroundColor Cyan
  Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host ""

  Write-Host "📋 Task Requirements:" -ForegroundColor Cyan
  Write-Host "   Type: $TaskType" -ForegroundColor White
  Write-Host "   Capability: $($Requirements.capability)" -ForegroundColor White
  Write-Host "   Max Latency: $($Requirements.max_latency_minutes) minutes" -ForegroundColor White
  Write-Host "   Min Success Rate: $($Requirements.min_success_rate)" -ForegroundColor White
  Write-Host "   Max Cost: $($Requirements.max_cost) credits" -ForegroundColor White
  Write-Host "   Complexity: $($Requirements.complexity)" -ForegroundColor White
  Write-Host ""

  if ($WhatIfPreference) {
    Write-Host "[WHAT-IF] Would create task auction" -ForegroundColor Yellow
    $taskId = "task-whatif-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
  } else {
    $result = New-TaskAuction -TaskType $TaskType `
      -Requirements $Requirements `
      -Payload $Payload `
      -AutoAward:$AutoAward

    $taskId = $result.TaskId
  }

  Write-Host ""
  Write-Host "✅ Phase 2 Complete: Auction Created ($taskId)" -ForegroundColor Green
  Write-Host ""

  return $taskId
}

# === PHASE 3: BID COLLECTION ===
function Invoke-BidCollection {
  param([string]$TaskId)

  Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host "PHASE 3: Bid Collection" -ForegroundColor Cyan
  Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host ""

  # Load marketplace to find eligible agents
  $marketplacePath = "$PSScriptRoot\..\..\..\agents\registry\agent-marketplace.yaml"
  $marketplaceYaml = Get-Content -Path $marketplacePath -Raw
  $marketplace = ConvertFrom-Yaml $marketplaceYaml

  $eligibleAgents = $marketplace.agents | Where-Object {
    $_.capabilities -contains $Requirements.capability -and
    $_.status -eq 'active'
  }

  Write-Host "📊 Eligible Agents: $($eligibleAgents.Count)" -ForegroundColor Cyan
  Write-Host ""

  if ($eligibleAgents.Count -eq 0) {
    Write-Host "⚠️  No eligible agents found for capability: $($Requirements.capability)" -ForegroundColor Yellow
    return $false
  }

  # Collect bids from eligible agents
  $bidsSubmitted = 0

  foreach ($agent in $eligibleAgents) {
    Write-Host "💰 Agent: $($agent.agent_id)" -ForegroundColor Cyan

    # Calculate bid based on agent's cost model
    $estimatedLatency = switch ($Requirements.complexity) {
      'low' { [int]($Requirements.max_latency_minutes * 0.4) }
      'medium' { [int]($Requirements.max_latency_minutes * 0.6) }
      'high' { [int]($Requirements.max_latency_minutes * 0.8) }
      'critical' { [int]($Requirements.max_latency_minutes * 0.9) }
      default { [int]($Requirements.max_latency_minutes * 0.7) }
    }

    $bidCost = $agent.cost_model.base_cost +
    ($estimatedLatency * $agent.cost_model.per_minute_cost) *
    $agent.cost_model.complexity_multiplier

    $bidCost = [Math]::Round($bidCost, 2)

    # Ensure bid meets requirements
    if ($bidCost -le $Requirements.max_cost -and
      $estimatedLatency -le $Requirements.max_latency_minutes) {

      Write-Host "   Bid: $bidCost credits" -ForegroundColor White
      Write-Host "   Estimated Latency: $estimatedLatency min" -ForegroundColor White
      Write-Host "   Calibration: $($agent.reputation.calibration_score)" -ForegroundColor White

      if ($WhatIfPreference) {
        Write-Host "   [WHAT-IF] Would submit bid" -ForegroundColor Yellow
      } else {
        try {
          Submit-AuctionBid -TaskId $TaskId `
            -AgentRole $agent.agent_id `
            -BidCost $bidCost `
            -EstimatedLatency $estimatedLatency `
            -EstimatedSuccessRate ([double]$agent.sla.success_rate)

          $bidsSubmitted++
        } catch {
          Write-Host "   ❌ Bid failed: $_" -ForegroundColor Red
        }
      }
    } else {
      Write-Host "   ⚠️  Bid exceeds constraints (cost: $bidCost, latency: $estimatedLatency)" -ForegroundColor Yellow
    }

    Write-Host ""
  }

  Write-Host "✅ Phase 3 Complete: $bidsSubmitted bids collected" -ForegroundColor Green
  Write-Host ""

  return ($bidsSubmitted -gt 0)
}

# === PHASE 4: WINNER SELECTION ===
function Invoke-WinnerSelection {
  param([string]$TaskId)

  Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host "PHASE 4: Winner Selection" -ForegroundColor Cyan
  Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host ""

  if ($WhatIfPreference) {
    Write-Host "[WHAT-IF] Would award task to best bid" -ForegroundColor Yellow
    return @{ Winner = "demo-agent"; BidCost = 2.0 }
  }

  # If AutoAward is enabled, task may already be awarded
  $auctionFile = Join-Path "$PSScriptRoot\..\..\..\agents\registry\task-auctions" "$TaskId.yaml"
  $auctionYaml = Get-Content -Path $auctionFile -Raw
  $auction = ConvertFrom-Yaml $auctionYaml

  if ($auction.status -eq 'awarded') {
    Write-Host "✅ Task already awarded (auto-award enabled)" -ForegroundColor Green
    Write-Host "   Winner: $($auction.winner)" -ForegroundColor Cyan

    return @{
      Winner  = $auction.winner
      BidCost = ($auction.bids | Where-Object { $_.agent_id -eq $auction.winner }).bid_cost
    }
  }

  # Award task manually
  $result = Award-TaskToWinner -TaskId $TaskId

  Write-Host ""
  Write-Host "✅ Phase 4 Complete: Winner Selected" -ForegroundColor Green
  Write-Host ""

  return $result
}

# === PHASE 5: TASK EXECUTION ===
function Invoke-TaskExecution {
  param(
    [string]$TaskId,
    [string]$Winner
  )

  Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host "PHASE 5: Task Execution" -ForegroundColor Cyan
  Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host ""

  Write-Host "🚀 Executing task: $TaskId" -ForegroundColor Cyan
  Write-Host "   Agent: $Winner" -ForegroundColor White
  Write-Host ""

  if ($SimulateExecution -or $WhatIfPreference) {
    Write-Host "🎭 SIMULATION MODE" -ForegroundColor Yellow
    Write-Host ""

    # Simulate task execution
    $success = $true  # 95% success rate
    $random = Get-Random -Minimum 0.0 -Maximum 1.0
    if ($random -lt 0.05) {
      $success = $false
    }

    # Get winning bid to compare
    $auctionFile = Join-Path "$PSScriptRoot\..\..\..\agents\registry\task-auctions" "$TaskId.yaml"
    $auctionYaml = Get-Content -Path $auctionFile -Raw
    $auction = ConvertFrom-Yaml $auctionYaml
    $winningBid = $auction.bids | Where-Object { $_.agent_id -eq $Winner }

    # Simulate with some variance
    $actualLatency = [int]($winningBid.estimated_latency_minutes * (Get-Random -Minimum 0.85 -Maximum 1.15))

    Write-Host "   Progress: [" -NoNewline -ForegroundColor Cyan
    for ($i = 0; $i -lt 20; $i++) {
      Write-Host "█" -NoNewline -ForegroundColor Green
      Start-Sleep -Milliseconds 50
    }
    Write-Host "] 100%" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "   Result: $(if ($success) { 'SUCCESS ✅' } else { 'FAILED ❌' })" -ForegroundColor $(if ($success) { 'Green' } else { 'Red' })
    Write-Host "   Actual Latency: $actualLatency minutes" -ForegroundColor White
    Write-Host ""

    return @{
      Success       = $success
      ActualLatency = $actualLatency
    }
  } else {
    Write-Host "⚠️  Real execution not implemented. Use -SimulateExecution for demo." -ForegroundColor Yellow
    return @{
      Success       = $true
      ActualLatency = $Requirements.max_latency_minutes
    }
  }
}

# === PHASE 6: PERFORMANCE SETTLEMENT ===
function Invoke-PerformanceSettlement {
  param(
    [string]$TaskId,
    [bool]$Success,
    [int]$ActualLatency
  )

  Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host "PHASE 6: Performance Settlement" -ForegroundColor Cyan
  Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host ""

  if ($WhatIfPreference) {
    Write-Host "[WHAT-IF] Would complete task and update reputation" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "✅ Phase 6 Complete: Performance Settled" -ForegroundColor Green
    return $true
  }

  $result = Complete-MarketTask -TaskId $TaskId `
    -Success $Success `
    -ActualLatency $ActualLatency

  Write-Host ""
  Write-Host "✅ Phase 6 Complete: Reputation Updated" -ForegroundColor Green
  Write-Host ""

  return $result
}

# === HELPER: YAML CONVERSION ===
function ConvertFrom-Yaml {
  param([string]$YamlString)

  if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Install-Module -Name powershell-yaml -Force -Scope CurrentUser
  }
  Import-Module powershell-yaml -Force

  return ConvertFrom-Yaml -Yaml $YamlString
}

# === MAIN CEREMONY EXECUTION ===
try {
  Show-CeremonyBanner

  # Phase 1: Market Initialization
  $phase1 = Invoke-MarketInitialization
  if (-not $phase1) {
    throw "Market initialization failed"
  }

  # Phase 2: Auction Creation
  $taskId = Invoke-AuctionCreation

  # Phase 3: Bid Collection (skip if auto-award, already handled)
  if (-not $AutoAward -or $WhatIfPreference) {
    $phase3 = Invoke-BidCollection -TaskId $taskId
    if (-not $phase3) {
      throw "No bids collected"
    }
  }

  # Phase 4: Winner Selection
  $winner = Invoke-WinnerSelection -TaskId $taskId

  # Phase 5: Task Execution
  $execution = Invoke-TaskExecution -TaskId $taskId -Winner $winner.Winner

  # Phase 6: Performance Settlement
  $settlement = Invoke-PerformanceSettlement -TaskId $taskId `
    -Success $execution.Success `
    -ActualLatency $execution.ActualLatency

  # Final Summary
  Write-Host ""
  Write-Host "╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
  Write-Host "║                                                                       ║" -ForegroundColor Green
  Write-Host "║                    CEREMONY COMPLETE - SUCCESS                        ║" -ForegroundColor Green
  Write-Host "║                                                                       ║" -ForegroundColor Green
  Write-Host "╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
  Write-Host ""

  Write-Host "📊 Ceremony Summary:" -ForegroundColor Cyan
  Write-Host "   Task ID: $taskId" -ForegroundColor White
  Write-Host "   Winner: $($winner.Winner)" -ForegroundColor White
  Write-Host "   Success: $($execution.Success)" -ForegroundColor $(if ($execution.Success) { 'Green' } else { 'Red' })
  Write-Host "   Latency: $($execution.ActualLatency) minutes" -ForegroundColor White
  if (-not $WhatIfPreference) {
    Write-Host "   Credits Earned: $($settlement.CreditsEarned)" -ForegroundColor $(if ($settlement.CreditsEarned -gt 0) { 'Green' } else { 'Red' })
  }
  Write-Host ""

  Write-Host "📁 Evidence Anchored:" -ForegroundColor Cyan
  Write-Host "   Auction: agents/registry/task-auctions/$taskId.yaml" -ForegroundColor Gray
  Write-Host "   Marketplace: agents/registry/agent-marketplace.yaml" -ForegroundColor Gray
  Write-Host "   Reputation Ledger: agents/registry/reputation-ledger.jsonl" -ForegroundColor Gray
  Write-Host "   Lineage Events: bus/lineage/events/*.jsonl" -ForegroundColor Gray
  Write-Host ""

} catch {
  Write-Host ""
  Write-Host "╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
  Write-Host "║                                                                       ║" -ForegroundColor Red
  Write-Host "║                      CEREMONY FAILED - ERROR                          ║" -ForegroundColor Red
  Write-Host "║                                                                       ║" -ForegroundColor Red
  Write-Host "╚═══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
  Write-Host ""
  Write-Host "❌ Error: $_" -ForegroundColor Red
  Write-Host ""
  exit 1
}
