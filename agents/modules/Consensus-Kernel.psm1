<#
.SYNOPSIS
    Consensus Kernel Module - Weighted Voting with Proof-of-Workload

.DESCRIPTION
    Enables multi-agent deliberative decision making with:
    - Weighted voting by track record, domain relevance, and calibration
    - Proof-of-workload verification (data accessed, checks performed)
    - Threshold-based approval with witness attestation
    - Lineage event emission for all consensus outcomes

.NOTES
    Version: 1.0.0
    Part of: Multi-Agent Intelligence Framework
    Requires: PowerShell 5.1+, Lineage-Bus module

.ARCHITECTURE
    - Agents submit proposals with evidence bundles
    - Workload receipts verified (data sources, computation time)
    - Votes weighted by historical accuracy (calibration score)
    - Threshold approval triggers lineage event
    - Failed proposals escalated or rejected
#>

Import-Module "$PSScriptRoot\Lineage-Bus.psm1" -Force

# === CONFIGURATION ===
$script:ProposalsPath = "$PSScriptRoot\..\..\council\proposals"
$script:VotingHistoryPath = "$PSScriptRoot\..\..\council\voting-history"

# Ensure directories exist
@($script:ProposalsPath, $script:VotingHistoryPath) | ForEach-Object {
  if (-not (Test-Path $_)) {
    New-Item -ItemType Directory -Path $_ -Force | Out-Null
  }
}

<#
.SYNOPSIS
    Creates a new proposal for multi-agent consensus.

.DESCRIPTION
    Agents submit proposals with evidence bundles and workload receipts.
    The proposal enters the deliberation pipeline for voting.

.PARAMETER ProposalId
    Unique identifier (auto-generated if not provided).

.PARAMETER AgentRole
    Proposing agent role.

.PARAMETER Domain
    Domain cell (commerce, build, civic, audit).

.PARAMETER Summary
    Brief description of the proposal.

.PARAMETER Evidence
    Array of evidence file paths or data hashes.

.PARAMETER WorkloadReceipt
    Hashtable with data_accessed, checks_performed, compute_time_ms, evidence_hash.

.PARAMETER RiskTier
    Impact level (low, medium, high, critical).

.EXAMPLE
    New-ConsensusProposal `
        -AgentRole "commerce-supplier-verifier" `
        -Domain "commerce" `
        -Summary "Approve supplier XYZ for EU market" `
        -Evidence @("supplier-docs.pdf", "compliance-cert.pdf") `
        -WorkloadReceipt @{
            data_accessed = @("supplier_docs", "regulatory_db", "cert_registry")
            checks_performed = 47
            compute_time_ms = 1842
            evidence_hash = "sha256:abc123..."
        } `
        -RiskTier "high"
#>
function New-ConsensusProposal {
  [CmdletBinding()]
  param(
    [string]$ProposalId,

    [Parameter(Mandatory = $true)]
    [string]$AgentRole,

    [Parameter(Mandatory = $true)]
    [ValidateSet('commerce', 'build', 'civic', 'audit')]
    [string]$Domain,

    [Parameter(Mandatory = $true)]
    [string]$Summary,

    [string[]]$Evidence = @(),

    [Parameter(Mandatory = $true)]
    [hashtable]$WorkloadReceipt,

    [Parameter(Mandatory = $true)]
    [ValidateSet('low', 'medium', 'high', 'critical')]
    [string]$RiskTier
  )

  # Generate proposal ID if not provided
  if (-not $ProposalId) {
    $ProposalId = "prop-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$([Guid]::NewGuid().ToString().Substring(0,8))"
  }

  # Validate workload receipt
  $requiredFields = @('data_accessed', 'checks_performed', 'compute_time_ms', 'evidence_hash')
  foreach ($field in $requiredFields) {
    if (-not $WorkloadReceipt.ContainsKey($field)) {
      throw "Workload receipt missing required field: $field"
    }
  }

  # Determine approval threshold by risk tier
  $thresholds = @{
    'low'      = @{ signatures = 1; witnesses = 0; min_weight = 0.5 }
    'medium'   = @{ signatures = 2; witnesses = 1; min_weight = 0.7 }
    'high'     = @{ signatures = 3; witnesses = 2; min_weight = 0.75 }
    'critical' = @{ signatures = 5; witnesses = 3; min_weight = 0.85 }
  }

  $threshold = $thresholds[$RiskTier]

  # Create proposal
  $proposal = [ordered]@{
    proposal_id      = $ProposalId
    domain           = $Domain
    proposer         = $AgentRole
    summary          = $Summary
    created          = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    updated          = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    risk_tier        = $RiskTier
    status           = "pending"
    evidence         = $Evidence
    workload_receipt = $WorkloadReceipt
    threshold        = $threshold
    votes            = @()
    witnesses        = @()
    decision         = $null
    lineage_event    = $null
  }

  # Save proposal
  $proposalFile = Join-Path $script:ProposalsPath "$ProposalId.yaml"
  $proposal | ConvertTo-Yaml | Out-File -FilePath $proposalFile -Encoding UTF8

  # Emit lineage event
  $eventResult = New-LineageEvent -EventType "proposal_created" `
    -AgentRole $AgentRole `
    -Payload @{
    proposal_id = $ProposalId
    domain      = $Domain
    risk_tier   = $RiskTier
    summary     = $Summary
  }

  Write-Host "✅ Proposal created: $ProposalId" -ForegroundColor Green
  Write-Host "   Domain: $Domain" -ForegroundColor Cyan
  Write-Host "   Risk Tier: $RiskTier" -ForegroundColor Cyan
  Write-Host "   Requires: $($threshold.signatures) signatures, $($threshold.witnesses) witnesses" -ForegroundColor Cyan

  return @{
    ProposalId   = $ProposalId
    ProposalFile = $proposalFile
    LineageEvent = $eventResult.EventId
  }
}

<#
.SYNOPSIS
    Casts a vote on a consensus proposal.

.DESCRIPTION
    Agents vote on proposals with weighted influence based on:
    - Track record (historical accuracy)
    - Domain relevance (how closely aligned to proposal domain)
    - Calibration score (recent performance)

.PARAMETER ProposalId
    Proposal identifier.

.PARAMETER AgentRole
    Voting agent role.

.PARAMETER Decision
    Vote decision (approve, approve_with_conditions, reject, abstain).

.PARAMETER Rationale
    Explanation for the vote.

.PARAMETER Conditions
    Array of conditions (if approve_with_conditions).

.PARAMETER Weight
    Vote weight (0.0-1.0, auto-calculated from agent track record if not provided).

.EXAMPLE
    Add-ConsensusVote -ProposalId "prop-20251016-001" `
        -AgentRole "agent-compliance-check-02" `
        -Decision "approve" `
        -Rationale "All GDPR requirements met"

.EXAMPLE
    Add-ConsensusVote -ProposalId "prop-20251016-001" `
        -AgentRole "agent-risk-assessor-01" `
        -Decision "approve_with_conditions" `
        -Rationale "Payment integration needs additional review" `
        -Conditions @("Manual review of payment API credentials")
#>
function Add-ConsensusVote {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$ProposalId,

    [Parameter(Mandatory = $true)]
    [string]$AgentRole,

    [Parameter(Mandatory = $true)]
    [ValidateSet('approve', 'approve_with_conditions', 'reject', 'abstain')]
    [string]$Decision,

    [Parameter(Mandatory = $true)]
    [string]$Rationale,

    [string[]]$Conditions = @(),

    [ValidateRange(0.0, 1.0)]
    [double]$Weight
  )

  # Load proposal
  $proposalFile = Join-Path $script:ProposalsPath "$ProposalId.yaml"
  if (-not (Test-Path $proposalFile)) {
    throw "Proposal not found: $ProposalId"
  }

  $proposalYaml = Get-Content -Path $proposalFile -Raw
  $proposal = ConvertFrom-Yaml $proposalYaml

  # Check if proposal is still open
  if ($proposal.status -ne "pending") {
    throw "Proposal is not open for voting. Status: $($proposal.status)"
  }

  # Check if agent already voted
  $existingVote = $proposal.votes | Where-Object { $_.agent -eq $AgentRole }
  if ($existingVote) {
    throw "Agent $AgentRole has already voted on this proposal"
  }

  # Calculate vote weight if not provided
  if (-not $PSBoundParameters.ContainsKey('Weight')) {
    $Weight = Get-AgentVoteWeight -AgentRole $AgentRole -Domain $proposal.domain
  }

  # Create vote
  $vote = @{
    agent      = $AgentRole
    decision   = $Decision
    weight     = $Weight
    rationale  = $Rationale
    conditions = $Conditions
    timestamp  = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
  }

  # Add vote to proposal
  $proposal.votes += $vote
  $proposal.updated = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"

  # Check if threshold reached
  $consensusResult = Test-ConsensusThreshold -Proposal $proposal

  if ($consensusResult.ThresholdReached) {
    $proposal.status = "approved"
    $proposal.decision = $consensusResult.Decision

    # Emit lineage event
    $eventResult = New-LineageEvent -EventType "proposal_approved" `
      -AgentRole "consensus-kernel" `
      -Payload @{
      proposal_id  = $ProposalId
      vote_count   = $proposal.votes.Count
      total_weight = $consensusResult.TotalWeight
      decision     = $consensusResult.Decision
    } `
      -Witnesses $proposal.witnesses

    $proposal.lineage_event = $eventResult.EventId

    Write-Host "✅ CONSENSUS REACHED: Proposal $ProposalId approved" -ForegroundColor Green
  } elseif ($consensusResult.RejectionThresholdReached) {
    $proposal.status = "rejected"
    $proposal.decision = "rejected"

    # Emit lineage event
    $eventResult = New-LineageEvent -EventType "proposal_rejected" `
      -AgentRole "consensus-kernel" `
      -Payload @{
      proposal_id      = $ProposalId
      vote_count       = $proposal.votes.Count
      rejection_weight = $consensusResult.RejectionWeight
    }

    $proposal.lineage_event = $eventResult.EventId

    Write-Host "❌ CONSENSUS REACHED: Proposal $ProposalId rejected" -ForegroundColor Red
  } else {
    Write-Host "⏳ Vote recorded. Awaiting additional votes..." -ForegroundColor Yellow
    Write-Host "   Current weight: $($consensusResult.TotalWeight) / $($proposal.threshold.min_weight) required" -ForegroundColor Yellow
  }

  # Save updated proposal
  $proposal | ConvertTo-Yaml | Out-File -FilePath $proposalFile -Encoding UTF8

  # Record vote in history
  Save-VoteToHistory -ProposalId $ProposalId -Vote $vote

  return @{
    ProposalId       = $ProposalId
    VoteRecorded     = $true
    ThresholdReached = $consensusResult.ThresholdReached
    Status           = $proposal.status
  }
}

<#
.SYNOPSIS
    Calculates an agent's vote weight based on track record.

.PARAMETER AgentRole
    Agent role identifier.

.PARAMETER Domain
    Proposal domain.

.OUTPUTS
    Weight value between 0.0 and 1.0.
#>
function Get-AgentVoteWeight {
  param(
    [string]$AgentRole,
    [string]$Domain
  )

  # Load agent manifest to get calibration score
  $manifestPath = Join-Path "$PSScriptRoot\..\..\council\mandates" "$AgentRole.yaml"

  if (-not (Test-Path $manifestPath)) {
    Write-Warning "Agent manifest not found: $AgentRole. Using default weight 0.5"
    return 0.5
  }

  $manifestYaml = Get-Content -Path $manifestPath -Raw
  $manifest = ConvertFrom-Yaml $manifestYaml

  # Base weight from calibration score
  $calibrationScore = 1.0
  if ($manifest.routing -and $manifest.routing.reputation -and $manifest.routing.reputation.calibration_score) {
    $calibrationScore = $manifest.routing.reputation.calibration_score
  }

  # Domain relevance multiplier
  $domainRelevance = 1.0
  if ($manifest.metadata -and $manifest.metadata.domain) {
    if ($manifest.metadata.domain -eq $Domain) {
      $domainRelevance = 1.0  # Same domain, full weight
    } else {
      $domainRelevance = 0.7  # Different domain, reduced weight
    }
  }

  # Combined weight
  $weight = $calibrationScore * $domainRelevance
  $weight = [Math]::Round($weight, 2)
  $weight = [Math]::Max(0.1, [Math]::Min(1.0, $weight))  # Clamp to 0.1-1.0

  return $weight
}

<#
.SYNOPSIS
    Tests if a proposal has reached consensus threshold.

.PARAMETER Proposal
    Proposal hashtable.

.OUTPUTS
    Hashtable with ThresholdReached, Decision, TotalWeight.
#>
function Test-ConsensusThreshold {
  param([hashtable]$Proposal)

  $approvalVotes = @($Proposal.votes | Where-Object { $_.decision -in @('approve', 'approve_with_conditions') })
  $rejectionVotes = @($Proposal.votes | Where-Object { $_.decision -eq 'reject' })

  $totalApprovalWeight = ($approvalVotes | Measure-Object -Property weight -Sum).Sum
  $totalRejectionWeight = ($rejectionVotes | Measure-Object -Property weight -Sum).Sum

  if ($null -eq $totalApprovalWeight) { $totalApprovalWeight = 0 }
  if ($null -eq $totalRejectionWeight) { $totalRejectionWeight = 0 }

  $minWeight = $Proposal.threshold.min_weight
  $minSignatures = $Proposal.threshold.signatures

  # Check approval threshold
  $thresholdReached = ($totalApprovalWeight -ge $minWeight) -and ($approvalVotes.Count -ge $minSignatures)

  # Check rejection threshold (if majority rejects)
  $rejectionThresholdReached = ($totalRejectionWeight -ge $minWeight) -and ($rejectionVotes.Count -ge $minSignatures)

  # Determine decision
  $decision = $null
  if ($thresholdReached) {
    $hasConditions = ($approvalVotes | Where-Object { $_.decision -eq 'approve_with_conditions' }).Count -gt 0
    $decision = if ($hasConditions) { "approved_with_conditions" } else { "approved" }
  }

  return @{
    ThresholdReached          = $thresholdReached
    RejectionThresholdReached = $rejectionThresholdReached
    Decision                  = $decision
    TotalWeight               = $totalApprovalWeight
    RejectionWeight           = $totalRejectionWeight
    VoteCount                 = $Proposal.votes.Count
  }
}

<#
.SYNOPSIS
    Saves vote to historical record for reputation tracking.

.PARAMETER ProposalId
    Proposal identifier.

.PARAMETER Vote
    Vote hashtable.
#>
function Save-VoteToHistory {
  param(
    [string]$ProposalId,
    [hashtable]$Vote
  )

  $date = Get-Date -Format "yyyy-MM"
  $historyFile = Join-Path $script:VotingHistoryPath "$date.jsonl"

  $record = @{
    proposal_id = $ProposalId
    agent       = $Vote.agent
    decision    = $Vote.decision
    weight      = $Vote.weight
    timestamp   = $Vote.timestamp
  }

  $jsonLine = ($record | ConvertTo-Json -Compress)
  Add-Content -Path $historyFile -Value $jsonLine -Encoding UTF8
}

<#
.SYNOPSIS
    Retrieves the status of a consensus proposal.

.PARAMETER ProposalId
    Proposal identifier.

.EXAMPLE
    Get-ConsensusProposal -ProposalId "prop-20251016-001"
#>
function Get-ConsensusProposal {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$ProposalId
  )

  $proposalFile = Join-Path $script:ProposalsPath "$ProposalId.yaml"

  if (-not (Test-Path $proposalFile)) {
    throw "Proposal not found: $ProposalId"
  }

  $proposalYaml = Get-Content -Path $proposalFile -Raw
  $proposal = ConvertFrom-Yaml $proposalYaml

  # Display status
  Write-Host "`n🗳️  CONSENSUS PROPOSAL: $ProposalId" -ForegroundColor Magenta
  Write-Host "════════════════════════════════════════════════════" -ForegroundColor Magenta
  Write-Host "Summary: $($proposal.summary)" -ForegroundColor White
  Write-Host "Domain: $($proposal.domain)" -ForegroundColor Cyan
  Write-Host "Proposer: $($proposal.proposer)" -ForegroundColor Cyan
  Write-Host "Risk Tier: $($proposal.risk_tier)" -ForegroundColor $(if ($proposal.risk_tier -in @('high', 'critical')) { 'Red' } else { 'Yellow' })
  Write-Host "Status: $($proposal.status)" -ForegroundColor $(if ($proposal.status -eq 'approved') { 'Green' } elseif ($proposal.status -eq 'rejected') { 'Red' } else { 'Yellow' })

  Write-Host "`nThreshold Requirements:" -ForegroundColor Cyan
  Write-Host "  Signatures: $($proposal.threshold.signatures)" -ForegroundColor White
  Write-Host "  Witnesses: $($proposal.threshold.witnesses)" -ForegroundColor White
  Write-Host "  Min Weight: $($proposal.threshold.min_weight)" -ForegroundColor White

  Write-Host "`nVotes ($($proposal.votes.Count)):" -ForegroundColor Cyan
  foreach ($vote in $proposal.votes) {
    $color = switch ($vote.decision) {
      'approve' { 'Green' }
      'approve_with_conditions' { 'Yellow' }
      'reject' { 'Red' }
      default { 'Gray' }
    }
    Write-Host "  [$($vote.decision)] $($vote.agent) (weight: $($vote.weight))" -ForegroundColor $color
    Write-Host "    → $($vote.rationale)" -ForegroundColor Gray
  }

  if ($proposal.status -eq "pending") {
    $consensusCheck = Test-ConsensusThreshold -Proposal $proposal
    Write-Host "`nProgress:" -ForegroundColor Cyan
    Write-Host "  Current Weight: $($consensusCheck.TotalWeight) / $($proposal.threshold.min_weight)" -ForegroundColor White
    Write-Host "  Votes: $($proposal.votes.Count) / $($proposal.threshold.signatures)" -ForegroundColor White
  }

  return $proposal
}

# Helper function to convert hashtable to YAML (simplified)
function ConvertTo-Yaml {
  param([Parameter(ValueFromPipeline)]$InputObject)

  # Install powershell-yaml if not available
  if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Install-Module -Name powershell-yaml -Force -Scope CurrentUser
  }
  Import-Module powershell-yaml

  return ConvertTo-Yaml -Data $InputObject
}

function ConvertFrom-Yaml {
  param([Parameter(ValueFromPipeline)][string]$YamlString)

  # Install powershell-yaml if not available
  if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Install-Module -Name powershell-yaml -Force -Scope CurrentUser
  }
  Import-Module powershell-yaml

  return ConvertFrom-Yaml -Yaml $YamlString
}

# Export functions
Export-ModuleMember -Function New-ConsensusProposal, Add-ConsensusVote, Get-ConsensusProposal, Get-AgentVoteWeight
