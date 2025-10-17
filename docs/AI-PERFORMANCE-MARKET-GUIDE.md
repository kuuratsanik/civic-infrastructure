# Agent Performance Market System

## Overview

The **Performance Market** is a decentralized task routing system where agents compete for tasks through competitive bidding. This creates a natural selection mechanism where high-performing agents earn more work and reputation credits, while maintaining audit trails and GDPR compliance.

## Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                    PERFORMANCE MARKET                          │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐   │
│  │   Task       │───▶│   Auction    │───▶│   Winner     │   │
│  │   Posted     │    │   Bids       │    │   Awarded    │   │
│  └──────────────┘    └──────────────┘    └──────────────┘   │
│         │                    │                    │          │
│         ▼                    ▼                    ▼          │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐   │
│  │ Requirements │    │ Capability   │    │  Execution   │   │
│  │  • Latency   │    │ Match Agents │    │  • Success?  │   │
│  │  • Cost      │    │  • Cost Bid  │    │  • Latency?  │   │
│  │  • Quality   │    │  • SLA Match │    │  • Quality?  │   │
│  └──────────────┘    └──────────────┘    └──────────────┘   │
│         │                    │                    │          │
│         └────────────────────┴────────────────────┘          │
│                             ▼                                │
│                  ┌──────────────────────┐                    │
│                  │  Reputation Update   │                    │
│                  │  • Credits Earned    │                    │
│                  │  • Calibration Score │                    │
│                  │  • Performance Stats │                    │
│                  └──────────────────────┘                    │
└────────────────────────────────────────────────────────────────┘
```

## Core Concepts

### 1. Agent Marketplace

Agents register their capabilities, SLAs, and cost models:

```yaml
agent_id: build-iso-optimizer
capabilities:
  - iso_construction
  - driver_injection
  - debloat
sla:
  p50_latency: "20m"
  p95_latency: "30m"
  p99_latency: "45m"
  success_rate: 0.98
  max_cost: "€2.50/task"
cost_model:
  base_cost: 1.5
  per_minute_cost: 0.05
  complexity_multiplier: 1.3
reputation:
  current_credits: 125.50
  calibration_score: 0.92
  completed_tasks: 42
  failed_tasks: 2
  average_latency: 22.3
```

**Storage**: `agents/registry/agent-marketplace.yaml`

### 2. Task Auctions

Tasks are posted with requirements and constraints:

```yaml
task_id: task-20251016-143022-abc12345
task_type: iso_construction
requirements:
  capability: iso_construction
  max_latency_minutes: 30
  min_success_rate: 0.95
  max_cost: 2.5
  complexity: medium
status: open
bids:
  - agent_id: build-iso-optimizer
    bid_cost: 2.30
    estimated_latency_minutes: 25
    estimated_success_rate: 0.98
    bid_score: 0.4521
    calibration_score: 0.92
  - agent_id: build-iso-optimizer-backup
    bid_cost: 1.80
    estimated_latency_minutes: 40
    estimated_success_rate: 0.92
    bid_score: 0.5834
    calibration_score: 0.85
```

**Storage**: `agents/registry/task-auctions/{task_id}.yaml`

### 3. Bid Scoring Algorithm

Bids are ranked by a composite score:

```
bid_score = (cost_weight × normalized_cost) +
            (latency_weight × normalized_latency) +
            (success_penalty) +
            (reputation_bonus)

Where:
  • cost_weight = 0.4
  • latency_weight = 0.3
  • success_penalty = (1 - estimated_success_rate) × 2
  • reputation_bonus = (calibration_score - 0.5) × -0.2

Lower scores win.
```

**Example**:

- Agent A: Cost 2.30, Latency 25m, Success 98%, Calibration 0.92
  - `bid_score = (0.4 × 0.92) + (0.3 × 0.833) + (0.02 × 2) + (-0.084) = 0.4521`
- Agent B: Cost 1.80, Latency 40m, Success 92%, Calibration 0.85
  - `bid_score = (0.4 × 0.72) + (0.3 × 1.333) + (0.08 × 2) + (-0.07) = 0.5834`

**Winner**: Agent A (lower score)

### 4. Reputation Credits

Agents earn or lose credits based on performance:

```
if success:
    accuracy_bonus = ((latency_accuracy + cost_accuracy) / 2) × base_cost × 0.2
    credits_earned = base_cost + accuracy_bonus
else:
    credits_earned = -base_cost × 0.5  # 50% penalty
```

**Example**:

- Base cost: 2.30 credits
- Estimated latency: 25 min → Actual: 23 min (accuracy: 92%)
- Latency accuracy: 0.92
- Cost accuracy: 1.0 (actual = bid)
- Accuracy bonus: ((0.92 + 1.0) / 2) × 2.30 × 0.2 = 0.44
- **Total earned: 2.74 credits**

**Storage**: `agents/registry/reputation-ledger.jsonl`

### 5. Calibration Score

Agents are calibrated based on estimate accuracy:

```
new_calibration = (0.6 × latency_accuracy) + (0.4 × success_rate)
calibration_score = (0.3 × new_calibration) + (0.7 × old_calibration)  # EMA
```

**Impact**:

- High calibration (0.9+) → Better bid scores → More tasks won
- Low calibration (< 0.5) → Worse bid scores → Fewer tasks won
- Creates incentive for honest SLA claims

## PowerShell Module Functions

### Register-AgentInMarketplace

Register agent with capabilities and SLAs.

```powershell
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
        base_cost = 1.5
        per_minute_cost = 0.05
        complexity_multiplier = 1.3
    }
```

**Output**:

- Updates `agent-marketplace.yaml`
- Emits `agent_registered` lineage event
- Initializes reputation at 0 credits, 1.0 calibration

### New-TaskAuction

Create task auction for agents to bid on.

```powershell
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
    } `
    -AutoAward
```

**Parameters**:

- `TaskType`: Type of task (matches agent capability)
- `Requirements`: Constraints (latency, cost, quality)
- `Payload`: Task-specific data
- `AutoAward`: Automatically award to best bid

**Output**:

- Creates `task-auctions/{task_id}.yaml`
- Emits `auction_created` lineage event
- Returns `TaskId`, `AuctionFile`, `Status`

### Submit-AuctionBid

Agent submits bid for task.

```powershell
Submit-AuctionBid -TaskId "task-20251016-001" `
    -AgentRole "build-iso-optimizer" `
    -BidCost 2.30 `
    -EstimatedLatency 25 `
    -EstimatedSuccessRate 0.98
```

**Validation**:

- ✅ Estimated latency ≤ max_latency_minutes
- ✅ Estimated success rate ≥ min_success_rate
- ✅ Bid cost ≤ max_cost
- ✅ Agent has required capability

**Output**:

- Adds bid to auction
- Calculates bid score
- Auto-awards if enabled and best bid

### Award-TaskToWinner

Select winning bid and award task.

```powershell
Award-TaskToWinner -TaskId "task-20251016-001"
```

**Algorithm**:

1. Sort bids by `bid_score` (ascending)
2. Select best (lowest) score
3. Update auction status to "awarded"
4. Emit `task_awarded` lineage event

**Output**:

- Updates auction with winner
- Returns `Winner`, `BidCost`, `EstimatedLatency`

### Complete-MarketTask

Record task completion and update reputation.

```powershell
Complete-MarketTask -TaskId "task-20251016-001" `
    -Success $true `
    -ActualLatency 23 `
    -ActualCost 2.10
```

**Logic**:

1. Compare actual vs. estimated performance
2. Calculate accuracy scores (latency, cost)
3. Award credits with accuracy bonus (if success)
4. Update calibration score (EMA)
5. Emit `task_completed` lineage event

**Output**:

- Updates auction status to "completed"
- Updates agent reputation in marketplace
- Appends to reputation ledger

### Get-AgentMarketProfile

Retrieve agent's marketplace profile.

```powershell
$profile = Get-AgentMarketProfile -AgentRole "build-iso-optimizer"
```

**Returns**:

```yaml
agent_id: build-iso-optimizer
capabilities: [iso_construction, driver_injection]
reputation:
  current_credits: 127.24
  calibration_score: 0.93
  completed_tasks: 43
  failed_tasks: 2
  average_latency: 22.1
sla:
  p50_latency: "20m"
  success_rate: 0.98
```

### Get-TaskAuctions

List all task auctions by status.

```powershell
# Get all open auctions
$openAuctions = Get-TaskAuctions -Status "open"

# Get completed auctions
$completedAuctions = Get-TaskAuctions -Status "completed"
```

**Filters**:

- `open` - Active auctions accepting bids
- `awarded` - Tasks awarded, awaiting completion
- `completed` - Finished tasks with outcomes
- `all` - All auctions

## Ceremony Workflow

Use the **Task Auction Ceremony** for end-to-end workflow:

```powershell
cd "scripts/ceremonies/14-market-auction"

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
    } `
    -AutoAward `
    -SimulateExecution
```

**6 Phases**:

1. **Market Initialization** - Validate marketplace, register demo agents if needed
2. **Auction Creation** - Post task with requirements
3. **Bid Collection** - Eligible agents submit bids
4. **Winner Selection** - Award to best bid
5. **Task Execution** - Simulate or execute real task
6. **Performance Settlement** - Update reputation and calibration

**WhatIf Mode**:

```powershell
.\New-TaskAuction.ps1 -TaskType "..." -Requirements @{...} -WhatIf
```

## Integration with Existing Agents

### ISO Build Agent

```powershell
# In iso-build-agent.ps1
Import-Module "$PSScriptRoot\..\modules\Performance-Market.psm1"

# Create auction for ISO build task
$auction = New-TaskAuction -TaskType "iso_construction" `
    -Requirements @{
        capability = "iso_construction"
        max_latency_minutes = 45
        min_success_rate = 0.95
        max_cost = 3.0
        complexity = "high"
    } `
    -Payload @{
        base_iso = $BaseISOPath
        customizations = $Customizations
    } `
    -AutoAward

# Execute as winner
if ($auction.Winner -eq $env:AGENT_ROLE) {
    # Build ISO...
    $success = Build-CustomISO @params

    # Report completion
    Complete-MarketTask -TaskId $auction.TaskId `
        -Success $success `
        -ActualLatency $actualMinutes
}
```

### Civic Agent

```powershell
# In civic-agent.ps1
Import-Module "$PSScriptRoot\..\modules\Performance-Market.psm1"

# Register civic agent capabilities
Register-AgentInMarketplace -AgentRole "civic-ceremony-orchestrator" `
    -Capabilities @("mandate_definition", "governance_approval") `
    -SLA @{
        p50_latency = "5m"
        p95_latency = "10m"
        success_rate = 0.99
        max_cost = "€0.80/task"
    }
```

### Master Orchestrator

```powershell
# In master-orchestrator.ps1
Import-Module "$PSScriptRoot\..\modules\Performance-Market.psm1"

# Route task to best agent via auction
function Route-TaskViaMarket {
    param($Task)

    $auction = New-TaskAuction -TaskType $Task.Type `
        -Requirements $Task.Requirements `
        -AutoAward

    # Wait for completion
    $result = Wait-TaskCompletion -TaskId $auction.TaskId

    return $result
}
```

## Performance Metrics Dashboard

Query marketplace for agent performance:

```powershell
# Load marketplace
$marketplace = ConvertFrom-Yaml (Get-Content "agents/registry/agent-marketplace.yaml" -Raw)

# Top performers by calibration
$topPerformers = $marketplace.agents |
    Sort-Object { $_.reputation.calibration_score } -Descending |
    Select-Object -First 5

foreach ($agent in $topPerformers) {
    Write-Host "$($agent.agent_id): Calibration $($agent.reputation.calibration_score) | Credits $($agent.reputation.current_credits)"
}

# Success rate analysis
$marketplace.agents | ForEach-Object {
    $total = $_.reputation.completed_tasks + $_.reputation.failed_tasks
    $successRate = if ($total -gt 0) { $_.reputation.completed_tasks / $total } else { 0 }

    [PSCustomObject]@{
        Agent = $_.agent_id
        SuccessRate = [Math]::Round($successRate, 2)
        TotalTasks = $total
        AvgLatency = $_.reputation.average_latency
        Credits = $_.reputation.current_credits
    }
} | Format-Table
```

## GDPR Compliance

### Data Minimization

Task auctions contain **only task-relevant data**:

- ✅ Task requirements (latency, cost, quality)
- ✅ Bid details (agent ID, cost, estimates)
- ❌ No PII in auction payloads
- ❌ No sensitive data in reputation ledger

### Right to Erasure

Agent can be removed from marketplace:

```powershell
# Load marketplace
$marketplace = ConvertFrom-Yaml (Get-Content "agents/registry/agent-marketplace.yaml" -Raw)

# Remove agent
$marketplace.agents = $marketplace.agents | Where-Object { $_.agent_id -ne "agent-to-remove" }

# Save
$marketplace | ConvertTo-Yaml | Out-File "agents/registry/agent-marketplace.yaml"
```

### Audit Trail

All market events logged in lineage bus:

- `agent_registered` - Agent joins marketplace
- `auction_created` - Task posted
- `task_awarded` - Winner selected
- `task_completed` - Task finished, reputation updated

```powershell
# Query market events
Import-Module "$PSScriptRoot\Lineage-Bus.psm1"

$marketEvents = Get-LineageEvents -AgentRole "performance-market" `
    -StartDate "2025-10-01" `
    -EndDate "2025-10-31"

# Export RoPA report
Export-LineageAuditReport -StartDate "2025-10-01" -EndDate "2025-10-31" `
    -Format HTML -OutputPath "evidence/market-audit-2025-10.html"
```

## Troubleshooting

### Issue 1: No Eligible Agents Found

**Symptom**: `No eligible agents found for capability: iso_construction`

**Solution**:

```powershell
# Check registered agents
$marketplace = ConvertFrom-Yaml (Get-Content "agents/registry/agent-marketplace.yaml" -Raw)
$marketplace.agents | Select-Object agent_id, capabilities, status

# Register agent with capability
Register-AgentInMarketplace -AgentRole "new-agent" `
    -Capabilities @("iso_construction") `
    -SLA @{...}
```

### Issue 2: Bid Exceeds Constraints

**Symptom**: `Bid cost (3.50) exceeds max allowed (2.50)`

**Solution**:

- Adjust agent's cost model (lower base_cost or per_minute_cost)
- OR adjust task requirements (higher max_cost)

```powershell
# Lower cost model
Register-AgentInMarketplace -AgentRole "agent" `
    -CostModel @{
        base_cost = 1.0  # Lower from 1.5
        per_minute_cost = 0.03  # Lower from 0.05
    }
```

### Issue 3: Calibration Score Too Low

**Symptom**: Agent wins fewer tasks despite low bid cost

**Cause**: Low calibration score (< 0.5) adds penalty to bid score

**Solution**:

- Complete tasks with accurate estimates
- Avoid over-promising (lower estimated latency than achievable)
- Calibration improves with each successful task

```powershell
# Check current calibration
$profile = Get-AgentMarketProfile -AgentRole "agent"
Write-Host "Calibration: $($profile.reputation.calibration_score)"

# Improve by completing tasks accurately
Complete-MarketTask -TaskId "task-001" `
    -Success $true `
    -ActualLatency 25  # Close to estimated 27
```

## Next Steps

### Phase 7: Resilience & Chaos Engineering

- Hot-swap failing agents mid-task
- Circuit breaker for low-calibration agents
- Automatic bid rebalancing

### Phase 8: Production Hardening

- Azure Key Vault for agent signing keys
- Azure Storage for auction archives
- CI/CD pipeline integration
- Grafana dashboards for market metrics

## References

- **Module**: `agents/modules/Performance-Market.psm1`
- **Ceremony**: `scripts/ceremonies/14-market-auction/New-TaskAuction.ps1`
- **Storage**: `agents/registry/`
  - `agent-marketplace.yaml` - Agent profiles
  - `task-auctions/*.yaml` - Auction history
  - `reputation-ledger.jsonl` - Credit transactions
- **Lineage Events**: `bus/lineage/events/*.jsonl`

