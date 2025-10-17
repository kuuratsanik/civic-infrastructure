<#
.SYNOPSIS
    Performance Market Module - Task Auction System with Reputation Tracking

.DESCRIPTION
    Implements auction-based task routing where agents bid on tasks based on their
    capability profiles, SLAs, and reputation scores. Winners earn reputation credits
    and improve their calibration scores through successful task completion.

.NOTES
    Version: 1.0.0
    Part of: Multi-Agent Intelligence Framework
    Requires: PowerShell 5.1+, Lineage-Bus module

.ARCHITECTURE
    - agents/registry/agent-marketplace.yaml - Agent capability profiles & SLAs
    - agents/registry/task-auctions/*.yaml - Active and completed auctions
    - agents/registry/reputation-ledger.jsonl - Reputation credit history
    - Automatic calibration scoring based on performance vs. claimed SLAs
#>

Import-Module "$PSScriptRoot\Lineage-Bus.psm1" -Force

# === CONFIGURATION ===
$script:MarketplacePath = "$PSScriptRoot\..\..\agents\registry\agent-marketplace.yaml"
$script:AuctionsPath = "$PSScriptRoot\..\..\agents\registry\task-auctions"
$script:ReputationLedgerPath = "$PSScriptRoot\..\..\agents\registry\reputation-ledger.jsonl"

# Ensure directories exist
@($script:AuctionsPath, (Split-Path $script:ReputationLedgerPath -Parent)) | ForEach-Object {
  if (-not (Test-Path $_)) {
    New-Item -ItemType Directory -Path $_ -Force | Out-Null
  }
}

<#
.SYNOPSIS
    Registers an agent in the performance marketplace.

.DESCRIPTION
    Agents publish their capability profiles, SLAs, and cost models.
    This enables them to participate in task auctions.

.PARAMETER AgentRole
    Agent role identifier.

.PARAMETER Capabilities
    Array of capabilities (e.g., "iso_construction", "supplier_verification").

.PARAMETER SLA
    Hashtable with p50_latency, p95_latency, p99_latency, success_rate, max_cost.

.PARAMETER CostModel
    Hashtable with base_cost, per_minute_cost, complexity_multiplier.

.EXAMPLE
    Register-AgentInMarketplace -AgentRole "build-iso-optimizer" `
        -Capabilities @("iso_construction", "driver_injection") `
        -SLA @{
            p50_latency = "20m"
            p95_latency = "30m"
            p99_latency = "45m"
            success_rate = 0.98
            max_cost = "€2.50/task"
        } `
        -CostModel @{
            base_cost = 1.0
            per_minute_cost = 0.05
            complexity_multiplier = 1.2
        }
#>
function Register-AgentInMarketplace {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$AgentRole,

    [Parameter(Mandatory = $true)]
    [string[]]$Capabilities,

    [Parameter(Mandatory = $true)]
    [hashtable]$SLA,

    [hashtable]$CostModel = @{
      base_cost             = 1.0
      per_minute_cost       = 0.0
      complexity_multiplier = 1.0
    }
  )

  # Load existing marketplace or create new
  if (Test-Path $script:MarketplacePath) {
    $marketplaceYaml = Get-Content -Path $script:MarketplacePath -Raw
    $marketplace = ConvertFrom-Yaml $marketplaceYaml
    $agents = @($marketplace.agents)
  } else {
    $agents = @()
  }

  # Check if agent already registered
  $existingIndex = -1
  for ($i = 0; $i -lt $agents.Count; $i++) {
    if ($agents[$i].agent_id -eq $AgentRole) {
      $existingIndex = $i
      break
    }
  }

  # Create agent profile
  $profile = @{
    agent_id     = $AgentRole
    capabilities = $Capabilities
    sla          = $SLA
    cost_model   = $CostModel
    reputation   = @{
      current_credits   = if ($existingIndex -ge 0) { $agents[$existingIndex].reputation.current_credits } else { 0 }
      calibration_score = if ($existingIndex -ge 0) { $agents[$existingIndex].reputation.calibration_score } else { 1.0 }
      completed_tasks   = if ($existingIndex -ge 0) { $agents[$existingIndex].reputation.completed_tasks } else { 0 }
      failed_tasks      = if ($existingIndex -ge 0) { $agents[$existingIndex].reputation.failed_tasks } else { 0 }
      average_latency   = if ($existingIndex -ge 0) { $agents[$existingIndex].reputation.average_latency } else { $null }
      last_calibration  = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    }
    registered   = if ($existingIndex -ge 0) { $agents[$existingIndex].registered } else { Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ" }
    updated      = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    status       = "active"
  }

  # Update or add agent
  if ($existingIndex -ge 0) {
    $agents[$existingIndex] = $profile
    Write-Host "✅ Updated agent profile: $AgentRole" -ForegroundColor Green
  } else {
    $agents += $profile
    Write-Host "✅ Registered new agent: $AgentRole" -ForegroundColor Green
  }

  # Save marketplace
  $marketplace = @{
    marketplace_version = "1.0.0"
    updated             = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    total_agents        = $agents.Count
    agents              = $agents
  }

  $marketplace | ConvertTo-Yaml | Out-File -FilePath $script:MarketplacePath -Encoding UTF8

  # Emit lineage event
  New-LineageEvent -EventType "agent_registered" `
    -AgentRole "performance-market" `
    -Payload @{
    agent_id     = $AgentRole
    capabilities = $Capabilities
    sla          = $SLA
  }

  return $profile
}

<#
.SYNOPSIS
    Creates a task auction for agents to bid on.

.DESCRIPTION
    Tasks are posted with requirements and SLA constraints.
    Agents bid based on their capability match and cost model.

.PARAMETER TaskId
    Unique task identifier (auto-generated if not provided).

.PARAMETER TaskType
    Type of task (matches agent capability).

.PARAMETER Requirements
    Hashtable with capability, max_latency, min_success_rate, max_cost, complexity.

.PARAMETER Payload
    Task-specific data (e.g., base_iso path, supplier_id).

.PARAMETER AutoAward
    If true, automatically award to best bid when auction closes.

.EXAMPLE
    New-TaskAuction -TaskType "iso_construction" `
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
        }
#>
function New-TaskAuction {
  [CmdletBinding()]
  param(
    [string]$TaskId,

    [Parameter(Mandatory = $true)]
    [string]$TaskType,

    [Parameter(Mandatory = $true)]
    [hashtable]$Requirements,

    [hashtable]$Payload = @{},

    [switch]$AutoAward
  )

  # Generate task ID if not provided
  if (-not $TaskId) {
    $TaskId = "task-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$([Guid]::NewGuid().ToString().Substring(0,8))"
  }

  # Validate requirements
  $requiredFields = @('capability', 'max_latency_minutes', 'min_success_rate', 'max_cost')
  foreach ($field in $requiredFields) {
    if (-not $Requirements.ContainsKey($field)) {
      throw "Requirements missing required field: $field"
    }
  }

  # Create auction
  $auction = [ordered]@{
    task_id      = $TaskId
    task_type    = $TaskType
    requirements = $Requirements
    payload      = $Payload
    created      = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    updated      = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    status       = "open"
    bids         = @()
    winner       = $null
    awarded_at   = $null
    completed_at = $null
    auto_award   = $AutoAward.IsPresent
  }

  # Save auction
  $auctionFile = Join-Path $script:AuctionsPath "$TaskId.yaml"
  $auction | ConvertTo-Yaml | Out-File -FilePath $auctionFile -Encoding UTF8

  # Emit lineage event
  New-LineageEvent -EventType "auction_created" `
    -AgentRole "performance-market" `
    -Payload @{
    task_id      = $TaskId
    task_type    = $TaskType
    requirements = $Requirements
  }

  Write-Host "✅ Task auction created: $TaskId" -ForegroundColor Green
  Write-Host "   Type: $TaskType" -ForegroundColor Cyan
  Write-Host "   Max Latency: $($Requirements.max_latency_minutes) minutes" -ForegroundColor Cyan
  Write-Host "   Min Success Rate: $($Requirements.min_success_rate)" -ForegroundColor Cyan
  Write-Host "   Max Cost: $($Requirements.max_cost)" -ForegroundColor Cyan

  return @{
    TaskId      = $TaskId
    AuctionFile = $auctionFile
    Status      = "open"
  }
}

<#
.SYNOPSIS
    Agent submits a bid for a task auction.

.DESCRIPTION
    Agents bid based on their cost model and estimated performance.
    Bids include estimated latency, cost, and success probability.

.PARAMETER TaskId
    Task auction identifier.

.PARAMETER AgentRole
    Bidding agent role.

.PARAMETER BidCost
    Bid cost in reputation credits.

.PARAMETER EstimatedLatency
    Estimated completion time in minutes.

.PARAMETER EstimatedSuccessRate
    Estimated probability of success (0.0-1.0).

.EXAMPLE
    Submit-AuctionBid -TaskId "task-20251016-001" `
        -AgentRole "build-iso-optimizer" `
        -BidCost 2.30 `
        -EstimatedLatency 25 `
        -EstimatedSuccessRate 0.98
#>
function Submit-AuctionBid {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$TaskId,

    [Parameter(Mandatory = $true)]
    [string]$AgentRole,

    [Parameter(Mandatory = $true)]
    [double]$BidCost,

    [Parameter(Mandatory = $true)]
    [int]$EstimatedLatency,

    [ValidateRange(0.0, 1.0)]
    [double]$EstimatedSuccessRate = 0.95
  )

  # Load auction
  $auctionFile = Join-Path $script:AuctionsPath "$TaskId.yaml"
  if (-not (Test-Path $auctionFile)) {
    throw "Auction not found: $TaskId"
  }

  $auctionYaml = Get-Content -Path $auctionFile -Raw
  $auction = ConvertFrom-Yaml $auctionYaml

  # Check auction status
  if ($auction.status -ne "open") {
    throw "Auction is not open. Status: $($auction.status)"
  }

  # Validate bid against requirements
  $reqs = $auction.requirements

  if ($EstimatedLatency -gt $reqs.max_latency_minutes) {
    throw "Estimated latency ($EstimatedLatency min) exceeds max allowed ($($reqs.max_latency_minutes) min)"
  }

  if ($EstimatedSuccessRate -lt $reqs.min_success_rate) {
    throw "Estimated success rate ($EstimatedSuccessRate) below min required ($($reqs.min_success_rate))"
  }

  if ($BidCost -gt $reqs.max_cost) {
    throw "Bid cost ($BidCost) exceeds max allowed ($($reqs.max_cost))"
  }

  # Get agent profile for scoring
  $agentProfile = Get-AgentMarketProfile -AgentRole $AgentRole

  # Calculate bid score (lower is better)
  # Score = (cost_weight * normalized_cost) + (latency_weight * normalized_latency) + (reputation_penalty)
  $costWeight = 0.4
  $latencyWeight = 0.3
  $successWeight = 0.3

  $normalizedCost = $BidCost / $reqs.max_cost
  $normalizedLatency = $EstimatedLatency / $reqs.max_latency_minutes
  $successPenalty = (1.0 - $EstimatedSuccessRate) * 2  # Penalty for lower success rate
  $reputationBonus = ($agentProfile.reputation.calibration_score - 0.5) * -0.2  # Bonus for high calibration

  $bidScore = ($costWeight * $normalizedCost) +
  ($latencyWeight * $normalizedLatency) +
  ($successWeight * $successPenalty) +
  $reputationBonus

  # Create bid
  $bid = @{
    agent_id                  = $AgentRole
    bid_cost                  = $BidCost
    estimated_latency_minutes = $EstimatedLatency
    estimated_success_rate    = $EstimatedSuccessRate
    bid_score                 = [Math]::Round($bidScore, 4)
    calibration_score         = $agentProfile.reputation.calibration_score
    submitted_at              = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
  }

  # Add bid to auction
  $auction.bids += $bid
  $auction.updated = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"

  # Save auction
  $auction | ConvertTo-Yaml | Out-File -FilePath $auctionFile -Encoding UTF8

  Write-Host "✅ Bid submitted for task $TaskId" -ForegroundColor Green
  Write-Host "   Agent: $AgentRole" -ForegroundColor Cyan
  Write-Host "   Cost: $BidCost credits" -ForegroundColor Cyan
  Write-Host "   Estimated Latency: $EstimatedLatency min" -ForegroundColor Cyan
  Write-Host "   Bid Score: $bidScore (lower is better)" -ForegroundColor Cyan

  # Auto-award if enabled and this is a qualified bid
  if ($auction.auto_award -and $auction.bids.Count -ge 1) {
    Write-Host "`n⚡ Auto-award enabled. Evaluating bids..." -ForegroundColor Yellow
    $awardResult = Award-TaskToWinner -TaskId $TaskId
    if ($awardResult.Winner) {
      Write-Host "✅ Task awarded to: $($awardResult.Winner)" -ForegroundColor Green
    }
  }

  return @{
    TaskId       = $TaskId
    BidSubmitted = $true
    BidScore     = $bidScore
  }
}

<#
.SYNOPSIS
    Awards task to the winning bid.

.DESCRIPTION
    Selects the best bid based on bid score (cost, latency, success rate, reputation).
    Updates agent's active tasks and auction status.

.PARAMETER TaskId
    Task auction identifier.

.EXAMPLE
    Award-TaskToWinner -TaskId "task-20251016-001"
#>
function Award-TaskToWinner {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$TaskId
  )

  # Load auction
  $auctionFile = Join-Path $script:AuctionsPath "$TaskId.yaml"
  if (-not (Test-Path $auctionFile)) {
    throw "Auction not found: $TaskId"
  }

  $auctionYaml = Get-Content -Path $auctionFile -Raw
  $auction = ConvertFrom-Yaml $auctionYaml

  # Check if auction is open
  if ($auction.status -ne "open") {
    throw "Auction is not open. Status: $($auction.status)"
  }

  # Check if there are bids
  if ($auction.bids.Count -eq 0) {
    throw "No bids submitted for task $TaskId"
  }

  # Find best bid (lowest score)
  $bestBid = $auction.bids | Sort-Object bid_score | Select-Object -First 1

  # Award task
  $auction.status = "awarded"
  $auction.winner = $bestBid.agent_id
  $auction.awarded_at = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
  $auction.updated = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"

  # Save auction
  $auction | ConvertTo-Yaml | Out-File -FilePath $auctionFile -Encoding UTF8

  # Emit lineage event
  New-LineageEvent -EventType "task_awarded" `
    -AgentRole "performance-market" `
    -Payload @{
    task_id           = $TaskId
    winner            = $bestBid.agent_id
    bid_cost          = $bestBid.bid_cost
    estimated_latency = $bestBid.estimated_latency_minutes
    bid_score         = $bestBid.bid_score
    total_bids        = $auction.bids.Count
  }

  Write-Host "`n🏆 TASK AWARDED" -ForegroundColor Green
  Write-Host "════════════════════════════════════════════════════" -ForegroundColor Green
  Write-Host "Task ID: $TaskId" -ForegroundColor Cyan
  Write-Host "Winner: $($bestBid.agent_id)" -ForegroundColor Cyan
  Write-Host "Bid Cost: $($bestBid.bid_cost) credits" -ForegroundColor Cyan
  Write-Host "Estimated Latency: $($bestBid.estimated_latency_minutes) min" -ForegroundColor Cyan
  Write-Host "Bid Score: $($bestBid.bid_score)" -ForegroundColor Cyan
  Write-Host "Total Bids: $($auction.bids.Count)" -ForegroundColor Cyan

  return @{
    Winner           = $bestBid.agent_id
    BidCost          = $bestBid.bid_cost
    EstimatedLatency = $bestBid.estimated_latency_minutes
    TotalBids        = $auction.bids.Count
  }
}

<#
.SYNOPSIS
    Records task completion and updates agent reputation.

.DESCRIPTION
    Updates reputation credits, calibration score, and performance metrics.
    Compares actual performance against estimated performance from bid.

.PARAMETER TaskId
    Task identifier.

.PARAMETER Success
    Whether task completed successfully.

.PARAMETER ActualLatency
    Actual completion time in minutes.

.PARAMETER ActualCost
    Actual cost incurred (optional, defaults to bid cost).

.EXAMPLE
    Complete-MarketTask -TaskId "task-20251016-001" `
        -Success $true `
        -ActualLatency 23 `
        -ActualCost 2.10
#>
function Complete-MarketTask {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$TaskId,

    [Parameter(Mandatory = $true)]
    [bool]$Success,

    [Parameter(Mandatory = $true)]
    [int]$ActualLatency,

    [double]$ActualCost = 0
  )

  # Load auction
  $auctionFile = Join-Path $script:AuctionsPath "$TaskId.yaml"
  if (-not (Test-Path $auctionFile)) {
    throw "Auction not found: $TaskId"
  }

  $auctionYaml = Get-Content -Path $auctionFile -Raw
  $auction = ConvertFrom-Yaml $auctionYaml

  # Check if task was awarded
  if ($auction.status -ne "awarded") {
    throw "Task must be awarded before completion. Status: $($auction.status)"
  }

  if (-not $auction.winner) {
    throw "No winner assigned to task $TaskId"
  }

  $winner = $auction.winner

  # Get winning bid
  $winningBid = $auction.bids | Where-Object { $_.agent_id -eq $winner } | Select-Object -First 1

  if (-not $winningBid) {
    throw "Winning bid not found for agent $winner"
  }

  # Calculate actual cost if not provided
  if ($ActualCost -eq 0) {
    $ActualCost = $winningBid.bid_cost
  }

  # Calculate performance vs. estimate
  $latencyAccuracy = 1.0 - [Math]::Abs($ActualLatency - $winningBid.estimated_latency_minutes) / $winningBid.estimated_latency_minutes
  $latencyAccuracy = [Math]::Max(0, [Math]::Min(1, $latencyAccuracy))

  $costAccuracy = 1.0 - [Math]::Abs($ActualCost - $winningBid.bid_cost) / $winningBid.bid_cost
  $costAccuracy = [Math]::Max(0, [Math]::Min(1, $costAccuracy))

  # Calculate reputation credits earned/lost
  $baseCredits = $winningBid.bid_cost

  if ($Success) {
    # Bonus for accuracy
    $accuracyBonus = (($latencyAccuracy + $costAccuracy) / 2) * $baseCredits * 0.2
    $creditsEarned = $baseCredits + $accuracyBonus
  } else {
    # Penalty for failure
    $creditsEarned = - $baseCredits * 0.5
  }

  $creditsEarned = [Math]::Round($creditsEarned, 2)

  # Update auction
  $auction.status = "completed"
  $auction.completed_at = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
  $auction.outcome = @{
    success                = $Success
    actual_latency_minutes = $ActualLatency
    actual_cost            = $ActualCost
    latency_accuracy       = [Math]::Round($latencyAccuracy, 2)
    cost_accuracy          = [Math]::Round($costAccuracy, 2)
    credits_earned         = $creditsEarned
  }
  $auction.updated = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"

  # Save auction
  $auction | ConvertTo-Yaml | Out-File -FilePath $auctionFile -Encoding UTF8

  # Update agent reputation
  Update-ReputationCredits -AgentRole $winner `
    -Credits $creditsEarned `
    -TaskId $TaskId `
    -Success $Success `
    -ActualLatency $ActualLatency `
    -EstimatedLatency $winningBid.estimated_latency_minutes

  # Emit lineage event
  New-LineageEvent -EventType "task_completed" `
    -AgentRole $winner `
    -Payload @{
    task_id           = $TaskId
    success           = $Success
    actual_latency    = $ActualLatency
    estimated_latency = $winningBid.estimated_latency_minutes
    credits_earned    = $creditsEarned
    latency_accuracy  = [Math]::Round($latencyAccuracy, 2)
  }

  Write-Host "`n✅ TASK COMPLETED" -ForegroundColor $(if ($Success) { 'Green' } else { 'Red' })
  Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host "Task ID: $TaskId" -ForegroundColor Cyan
  Write-Host "Agent: $winner" -ForegroundColor Cyan
  Write-Host "Success: $Success" -ForegroundColor $(if ($Success) { 'Green' } else { 'Red' })
  Write-Host "Actual Latency: $ActualLatency min (estimated: $($winningBid.estimated_latency_minutes) min)" -ForegroundColor Cyan
  Write-Host "Latency Accuracy: $([Math]::Round($latencyAccuracy * 100, 1))%" -ForegroundColor Cyan
  Write-Host "Credits Earned: $creditsEarned" -ForegroundColor $(if ($creditsEarned -gt 0) { 'Green' } else { 'Red' })

  return @{
    TaskId          = $TaskId
    Success         = $Success
    CreditsEarned   = $creditsEarned
    LatencyAccuracy = $latencyAccuracy
  }
}

<#
.SYNOPSIS
    Updates agent reputation credits and calibration score.

.PARAMETER AgentRole
    Agent role identifier.

.PARAMETER Credits
    Credits to add (positive) or deduct (negative).

.PARAMETER TaskId
    Associated task ID (optional).

.PARAMETER Success
    Task success (for calibration).

.PARAMETER ActualLatency
    Actual latency (for calibration).

.PARAMETER EstimatedLatency
    Estimated latency (for calibration).
#>
function Update-ReputationCredits {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$AgentRole,

    [Parameter(Mandatory = $true)]
    [double]$Credits,

    [string]$TaskId = $null,

    [bool]$Success = $true,

    [int]$ActualLatency = 0,

    [int]$EstimatedLatency = 0
  )

  # Load marketplace
  if (-not (Test-Path $script:MarketplacePath)) {
    throw "Marketplace not initialized. Register agent first."
  }

  $marketplaceYaml = Get-Content -Path $script:MarketplacePath -Raw
  $marketplace = ConvertFrom-Yaml $marketplaceYaml

  # Find agent
  $agentIndex = -1
  for ($i = 0; $i -lt $marketplace.agents.Count; $i++) {
    if ($marketplace.agents[$i].agent_id -eq $AgentRole) {
      $agentIndex = $i
      break
    }
  }

  if ($agentIndex -eq -1) {
    throw "Agent not found in marketplace: $AgentRole"
  }

  $agent = $marketplace.agents[$agentIndex]

  # Update credits
  $oldCredits = $agent.reputation.current_credits
  $agent.reputation.current_credits += $Credits
  $agent.reputation.current_credits = [Math]::Round($agent.reputation.current_credits, 2)

  # Update task counts
  if ($Success) {
    $agent.reputation.completed_tasks++
  } else {
    $agent.reputation.failed_tasks++
  }

  # Update average latency
  if ($ActualLatency -gt 0) {
    $totalTasks = $agent.reputation.completed_tasks + $agent.reputation.failed_tasks
    if ($agent.reputation.average_latency) {
      $agent.reputation.average_latency = (($agent.reputation.average_latency * ($totalTasks - 1)) + $ActualLatency) / $totalTasks
    } else {
      $agent.reputation.average_latency = $ActualLatency
    }
    $agent.reputation.average_latency = [Math]::Round($agent.reputation.average_latency, 1)
  }

  # Recalibrate score
  if ($EstimatedLatency -gt 0 -and $ActualLatency -gt 0) {
    $latencyAccuracy = 1.0 - [Math]::Abs($ActualLatency - $EstimatedLatency) / $EstimatedLatency
    $latencyAccuracy = [Math]::Max(0, [Math]::Min(1, $latencyAccuracy))

    $successRate = $agent.reputation.completed_tasks / ($agent.reputation.completed_tasks + $agent.reputation.failed_tasks)

    # New calibration = weighted average of latency accuracy and success rate
    $newCalibration = (0.6 * $latencyAccuracy) + (0.4 * $successRate)

    # Smooth with existing calibration (exponential moving average)
    $alpha = 0.3  # Weight for new observation
    $agent.reputation.calibration_score = ($alpha * $newCalibration) + ((1 - $alpha) * $agent.reputation.calibration_score)
    $agent.reputation.calibration_score = [Math]::Round($agent.reputation.calibration_score, 2)
  }

  $agent.reputation.last_calibration = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
  $agent.updated = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"

  # Save marketplace
  $marketplace.updated = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
  $marketplace.agents[$agentIndex] = $agent
  $marketplace | ConvertTo-Yaml | Out-File -FilePath $script:MarketplacePath -Encoding UTF8

  # Record in reputation ledger
  $ledgerEntry = @{
    timestamp         = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    agent_id          = $AgentRole
    task_id           = $TaskId
    credits_change    = $Credits
    credits_total     = $agent.reputation.current_credits
    calibration_score = $agent.reputation.calibration_score
    success           = $Success
  }

  $jsonLine = ($ledgerEntry | ConvertTo-Json -Compress)
  Add-Content -Path $script:ReputationLedgerPath -Value $jsonLine -Encoding UTF8

  Write-Verbose "Updated reputation for $AgentRole : $oldCredits → $($agent.reputation.current_credits) credits (Δ $Credits)"

  return @{
    AgentRole        = $AgentRole
    OldCredits       = $oldCredits
    NewCredits       = $agent.reputation.current_credits
    CalibrationScore = $agent.reputation.calibration_score
  }
}

<#
.SYNOPSIS
    Retrieves agent's marketplace profile.

.PARAMETER AgentRole
    Agent role identifier.

.EXAMPLE
    Get-AgentMarketProfile -AgentRole "build-iso-optimizer"
#>
function Get-AgentMarketProfile {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$AgentRole
  )

  if (-not (Test-Path $script:MarketplacePath)) {
    throw "Marketplace not initialized"
  }

  $marketplaceYaml = Get-Content -Path $script:MarketplacePath -Raw
  $marketplace = ConvertFrom-Yaml $marketplaceYaml

  $agent = $marketplace.agents | Where-Object { $_.agent_id -eq $AgentRole } | Select-Object -First 1

  if (-not $agent) {
    throw "Agent not found in marketplace: $AgentRole"
  }

  return $agent
}

<#
.SYNOPSIS
    Lists all active task auctions.

.PARAMETER Status
    Filter by status (open, awarded, completed).

.EXAMPLE
    Get-TaskAuctions -Status "open"
#>
function Get-TaskAuctions {
  [CmdletBinding()]
  param(
    [ValidateSet('open', 'awarded', 'completed', 'all')]
    [string]$Status = 'all'
  )

  if (-not (Test-Path $script:AuctionsPath)) {
    return @()
  }

  $auctionFiles = Get-ChildItem -Path $script:AuctionsPath -Filter "*.yaml"
  $auctions = @()

  foreach ($file in $auctionFiles) {
    $auctionYaml = Get-Content -Path $file.FullName -Raw
    $auction = ConvertFrom-Yaml $auctionYaml

    if ($Status -eq 'all' -or $auction.status -eq $Status) {
      $auctions += $auction
    }
  }

  return $auctions
}

# Helper functions for YAML conversion
function ConvertTo-Yaml {
  param([Parameter(ValueFromPipeline)]$InputObject)

  if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Install-Module -Name powershell-yaml -Force -Scope CurrentUser
  }
  Import-Module powershell-yaml -Force

  return ConvertTo-Yaml -Data $InputObject
}

function ConvertFrom-Yaml {
  param([Parameter(ValueFromPipeline)][string]$YamlString)

  if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Install-Module -Name powershell-yaml -Force -Scope CurrentUser
  }
  Import-Module powershell-yaml -Force

  return ConvertFrom-Yaml -Yaml $YamlString
}

# Export functions
Export-ModuleMember -Function Register-AgentInMarketplace, New-TaskAuction, Submit-AuctionBid, Award-TaskToWinner, Complete-MarketTask, Update-ReputationCredits, Get-AgentMarketProfile, Get-TaskAuctions
