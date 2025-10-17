# Multi-Agent Intelligence Framework

## Sovereign, Audit-Ready IA Teams for Civic Infrastructure

**Version:** 1.0.0
**Status:** Active Design
**Governance Tier:** Strategic Foundation
**Last Updated:** 2025-10-16

---

## Executive Summary

This framework defines advanced, composable intelligence methods controlled by federated IA (Intelligent Agent) teams. It is designed for **operational sovereignty**, **betrayal resistance**, and **lineage-anchored governance** — treating AI orchestration as reproducible, auditable civic infrastructure.

### Core Principles

1. **Sovereignty**: Self-hosted coordination nucleus with no external dependencies for critical decisions
2. **Auditability**: Every decision emits signed, tamper-evident lineage events
3. **Reproducibility**: Deterministic pipelines with pinned dependencies and seeded randomness
4. **Compliance**: EU GDPR-native with data minimization and purpose limitation
5. **Resilience**: Defense-in-depth safety with hot-swap capabilities and chaos testing

---

## Architecture Overview

### Layered Federation Model

```
┌─────────────────────────────────────────────────────────────┐
│                      WITNESS RING                           │
│           (Independent Verifiers & Attestation)             │
└─────────────────────────────────────────────────────────────┘
         │                    │                    │
┌────────▼──────────┐ ┌───────▼──────────┐ ┌──────▼───────────┐
│  COMMERCE CELL    │ │    OPS CELL      │ │ GOVERNANCE CELL  │
│ ┌───────────────┐ │ │ ┌──────────────┐ │ │ ┌──────────────┐ │
│ │ Supplier Ver. │ │ │ │ CI/CD Hygiene│ │ │ │ Mandates     │ │
│ │ Catalog Check │ │ │ │ Observability│ │ │ │ Audits       │ │
│ │ Compliance    │ │ │ │ Cost Control │ │ │ │ Witness Coord│ │
│ └───────────────┘ │ │ └──────────────┘ │ │ └──────────────┘ │
└────────┬──────────┘ └───────┬──────────┘ └──────┬───────────┘
         │                    │                    │
         └────────────────────▼────────────────────┘
                    TRUST GATEWAYS
              (Policy Enforcement Boundaries)
                          │
                ┌─────────▼─────────┐
                │ SOVEREIGN NUCLEUS │
                │ • Identity/Keys   │
                │ • Policy Kernel   │
                │ • Lineage Bus     │
                │ • Revocation Graph│
                └───────────────────┘
```

### Component Responsibilities

#### 1. Sovereign Nucleus

**Location:** `council/`, `bus/`, `agents/factory/`

- **Identity Management**: Decentralized agent identities with role-based credentials
- **Key Management**: Multi-sig governance with threshold approvals
- **Lineage Bus**: Signed event stream for all decisions
- **Policy Kernel**: Baseline constraints, safety guards, escalation rules
- **Revocation Graph**: Kill-switch and backward invalidation for compromised components

#### 2. Domain Cells

**Location:** `agents/civic/`, `agents/build/`, `agents/audit/`

- **Commerce Cell**: Supplier verification, catalog hygiene, compliance gating
- **Build Cell**: ISO construction, driver integration, customization workflows
- **Civic Cell**: Ceremony orchestration, governance enforcement, audit trails
- **Audit Cell**: Evidence collection, lineage verification, compliance reporting

#### 3. Trust Gateways

**Location:** `agents/factory/agent-factory.ps1`, policy enforcers

- **Data Access Control**: Scoped permissions per agent role
- **Capability Mediation**: API rate limits, resource quotas, sandbox boundaries
- **Cross-Cell Requests**: Mutual TLS, signed payloads, witness attestation
- **Firewall Rules**: Context isolation to prevent cross-domain leakage

#### 4. Witness Ring

**Location:** `council/warrants/`, `evidence/`

- **Decision Attestation**: Independent verification of high-impact actions
- **Data Transformation Proofs**: Hashing, signing, timestamping of artifacts
- **Ceremony Outcomes**: Validation of execution against mandates
- **Compliance Witnesses**: Third-party validators for regulatory requirements

---

## Advanced Intelligence Methods

### 1. Hierarchical Planning with Constraint Weaving

**Purpose:** Decompose strategic intents into scoped work packets with explicit guardrails.

**Implementation:**

- **Goal Decomposition**: Break high-level tasks into atomic ceremonies
- **Constraint Injection**: Pre-load legal, safety, budget, SLA constraints
- **Adversarial Pre-Mortems**: Red agents simulate failure scenarios

**Example:**

```powershell
# scripts/ceremonies/planning/New-WorkPacket.ps1
param(
    [string]$StrategyIntent,
    [string[]]$Constraints,
    [switch]$AdversarialReview
)

# Decompose into ceremonies
$workPackets = Split-StrategyIntoCeremonies -Intent $StrategyIntent

# Weave constraints
foreach ($packet in $workPackets) {
    Add-Constraints -Packet $packet -Rules $Constraints

    if ($AdversarialReview) {
        # Red agent simulates failure
        $risks = Invoke-RedTeamAnalysis -Packet $packet
        $packet.Risks = $risks
    }
}
```

### 2. Deliberative Consensus with Proof-of-Workload

**Purpose:** Multi-agent voting with verifiable computation receipts.

**Implementation:**

- **Multi-View Proposals**: Diverse agents produce competing plans
- **Weighted Voting**: Track record × domain relevance × calibration score
- **Proof-of-Workload**: Verifiable traces of data access and checks performed

**Consensus Algorithm:**

1. Agents submit proposals with evidence bundles
2. Workload receipts verified (data accessed, checks run, time spent)
3. Votes weighted by historical accuracy and domain expertise
4. Threshold approval triggers lineage event emission

**Example Schema:**

```yaml
# council/proposals/supplier-onboarding-proposal.yaml
proposal_id: "prop-2025-10-16-001"
domain: "commerce"
proposer: "agent-supplier-verifier-01"
workload_receipt:
  data_accessed: ["supplier_docs", "regulatory_db", "cert_registry"]
  checks_performed: 47
  compute_time_ms: 1842
  evidence_hash: "sha256:abc123..."
votes:
  - agent: "agent-compliance-check-02"
    weight: 0.85 # Track record score
    decision: "approve"
  - agent: "agent-risk-assessor-01"
    weight: 0.72
    decision: "approve_with_conditions"
threshold: 0.75
status: "approved"
lineage_event: "evt-2025-10-16-001"
```

### 3. Retrieval-Augmented Reasoning with Staged Verification

**Purpose:** Fact-checking pipeline with provenance tracking.

**Implementation:**

- **Tiered Retrieval**: Private corpora → public regs → supplier docs
- **Staged Verification**: Syntax → cross-source triangulation → expert validation
- **Semantic Diffing**: Detect policy changes and trigger re-validation

**Verification Stages:**

```powershell
# agents/modules/RAG-Verifier.psm1
function Invoke-StagedVerification {
    param([object]$Claim)

    # Stage 1: Syntax validation
    $syntaxValid = Test-ClaimSyntax -Claim $Claim
    if (-not $syntaxValid) { return @{Valid=$false; Stage="syntax"} }

    # Stage 2: Cross-source triangulation
    $sources = Get-ClaimSources -Claim $Claim
    $agreement = Measure-SourceAgreement -Sources $sources
    if ($agreement -lt 0.8) { return @{Valid=$false; Stage="triangulation"; Agreement=$agreement} }

    # Stage 3: Domain expert validation
    $expertScore = Invoke-ExpertValidator -Claim $Claim -Domain $Claim.Domain
    if ($expertScore -lt 0.9) { return @{Valid=$false; Stage="expert"; Score=$expertScore} }

    # All stages passed
    return @{
        Valid = $true
        Provenance = $sources | Select-Object Source, Freshness, License
        VerificationTimestamp = Get-Date
        Signature = Sign-Claim -Claim $Claim
    }
}
```

### 4. Adaptive Task Routing with Performance Markets

**Purpose:** Auction-based task assignment with reputation tracking.

**Implementation:**

- **Capability Profiles**: Agents publish audited strengths and cost curves
- **Routing Auctions**: Tasks bid against SLAs; winners earn reputation credits
- **Auto-Calibration**: Underperformers get shadow tasks; chronic failure → quarantine

**Market Mechanics:**

```yaml
# agents/registry/agent-marketplace.yaml
agents:
  - agent_id: "agent-iso-builder-01"
    capabilities:
      - iso_construction
      - driver_injection
    sla:
      p95_latency_minutes: 45
      success_rate: 0.98
      cost_per_build: 2.50 # Reputation credits
    reputation_credits: 1247
    calibration_score: 0.94

  - agent_id: "agent-iso-builder-02"
    capabilities:
      - iso_construction
    sla:
      p95_latency_minutes: 60
      success_rate: 0.92
      cost_per_build: 1.80
    reputation_credits: 843
    calibration_score: 0.87

task_auction:
  task_id: "build-iso-secure-2025-10-16"
  requirements:
    - capability: "iso_construction"
    - max_latency_minutes: 50
    - min_success_rate: 0.95
  bids:
    - agent_id: "agent-iso-builder-01"
      bid_credits: 2.30
      estimated_latency: 42
    - agent_id: "agent-iso-builder-02"
      bid_credits: 1.60
      estimated_latency: 58 # Exceeds max latency
  winner: "agent-iso-builder-01"
  award_credits: 2.30
```

### 5. Defense-in-Depth Safety

**Purpose:** Multi-layer safety controls with deterministic replay.

**Implementation:**

- **Policy Sandboxing**: Risky ops in constrained execution cells
- **Output Guards**: Structured validators for legality/safety/compliance
- **Context Firewalls**: Prevent cross-domain PII leakage

**Sandbox Configuration:**

```powershell
# agents/modules/Safety-Sandbox.psm1
function Invoke-SandboxedCeremony {
    param(
        [string]$CeremonyScript,
        [hashtable]$ResourceLimits
    )

    # Create isolated execution environment
    $sandbox = New-ExecutionSandbox -Limits $ResourceLimits

    # Record initial state for replay
    $stateSnapshot = Export-SandboxState -Sandbox $sandbox

    try {
        # Execute with output guards
        $result = Invoke-CeremonyInSandbox `
            -Sandbox $sandbox `
            -Script $CeremonyScript `
            -OutputValidator { param($output)
                Test-LegalCompliance -Output $output
                Test-SafetyConstraints -Output $output
                Test-DataMinimization -Output $output
            }

        # Emit lineage event
        New-LineageEvent -Type "sandboxed_execution" `
            -StateSnapshot $stateSnapshot `
            -Result $result `
            -Deterministic $true

        return $result
    }
    finally {
        # Cleanup
        Remove-ExecutionSandbox -Sandbox $sandbox
    }
}
```

---

## Governance Ceremonies

### Ceremony 1: Mandate Definition

**Purpose:** Establish agent role scope, KPIs, and boundaries.

**Inputs:**

- Domain specification
- Allowed actions list
- Data access levels
- Performance KPIs
- Non-negotiable constraints

**Outputs:**

- Signed mandate YAML
- Lineage event with witness attestations
- Registry entry in `council/manifest.json`

**Example Workflow:**

```powershell
# scripts/ceremonies/12-mandate-definition/New-AgentMandate.ps1
param(
    [string]$AgentRole,
    [string]$Domain,
    [string[]]$AllowedActions,
    [hashtable]$KPIs,
    [string[]]$Constraints
)

# Create mandate document
$mandate = @{
    role = $AgentRole
    domain = $Domain
    scope = $AllowedActions
    kpis = $KPIs
    constraints = $Constraints
    created = Get-Date
    version = "1.0.0"
}

# Witness attestation
$witnesses = Request-WitnessApproval -Mandate $mandate -RequiredCount 2

# Sign and publish
$signature = Sign-Manifest -Manifest $mandate -Witnesses $witnesses
Save-Mandate -Mandate $mandate -Signature $signature -Path "council/mandates/$AgentRole.yaml"

# Emit lineage event
New-LineageEvent -Type "mandate_created" -Mandate $mandate -Witnesses $witnesses
```

### Ceremony 2: Proposal and Approval

**Purpose:** Multi-sig approval for high-impact decisions.

**Phases:**

1. **Draft**: Agent prepares proposal with evidence bundle
2. **Attestation**: Domain leads and witnesses review and sign
3. **Publication**: Lineage event with hashes and timestamps

**Approval Thresholds by Risk Tier:**
| Risk Tier | Signatures Required | Witness Count | Example Actions |
|-----------|---------------------|---------------|-----------------|
| Low | 1 (agent self-approval) | 0 | Routine data fetch |
| Medium | 2 (agent + domain lead) | 1 | Config changes |
| High | 3 (agent + 2 domain leads) | 2 | New supplier activation |
| Critical | 5 (multi-domain quorum) | 3 | Policy changes, key rotation |

**Example Schema:**

```yaml
# council/proposals/iso-build-optimization-proposal.yaml
proposal_id: "prop-iso-opt-2025-10-16"
agent: "agent-iso-builder-ai-01"
risk_tier: "medium"
summary: "Optimize ISO build ceremony to reduce build time by 30%"
evidence:
  - performance_benchmarks.csv
  - cost_analysis.json
  - safety_validation_report.md
approvers:
  - role: "agent-iso-builder-ai-01"
    signature: "sig:abc123..."
    timestamp: "2025-10-16T14:23:00Z"
  - role: "manager-build-cell"
    signature: "sig:def456..."
    timestamp: "2025-10-16T14:45:00Z"
witnesses:
  - role: "witness-audit-01"
    signature: "sig:ghi789..."
    timestamp: "2025-10-16T15:00:00Z"
status: "approved"
lineage_event: "evt-prop-iso-opt-2025-10-16"
```

### Ceremony 3: Execution and Audit

**Purpose:** Execute approved actions with full observability.

**Phases:**

1. **Load Mandate**: Pin versions, fetch constraints
2. **Pre-Checks**: Validate identity, keys, environment hashes
3. **Plan**: Decompose tasks with red-team pre-mortem
4. **Verify**: Staged RAG with provenance collection
5. **Decide**: Consensus kernel if risk tier ≥ medium
6. **Emit**: Publish lineage event with artifacts
7. **Seal**: Update reputation, archive replay bundle

**Audit Trail Requirements:**

- **Immutable Logs**: Append-only JSONL in `logs/council_ledger.jsonl`
- **Evidence Anchors**: Pre/post state snapshots in `evidence/`
- **Artifact Hashing**: SHA-256 of all inputs/outputs
- **Witness Signatures**: Third-party attestation for high-risk actions
- **Replay Bundles**: Deterministic reproduction packages

---

## Operational Hygiene

### Metrics and SLOs

**Per-Domain KPIs:**

```yaml
# configs/slos/commerce-cell-slos.yaml
domain: "commerce"
slos:
  accuracy:
    supplier_verification_precision: ">= 0.98"
    compliance_check_recall: ">= 0.95"
  latency:
    supplier_onboarding_p95: "<= 120s"
    catalog_update_p50: "<= 30s"
  cost:
    cost_per_decision: "<= €0.50"
    monthly_compute_budget: "<= €500"
  safety:
    blocked_outputs_per_week: "<= 5"
    escalations_per_month: "<= 10"
    override_frequency: "<= 2%"
```

### Tracing and Replay

**Deterministic Pipeline Requirements:**

1. **Seeded Randomness**: All stochastic operations use reproducible seeds
2. **Pinned Dependencies**: Lock file for PowerShell modules, Docker images, model versions
3. **Immutable Data Snapshots**: Copy-on-write for all input datasets
4. **Step Replay**: Reconstruct any decision from lineage event + input payload

**Replay Bundle Schema:**

```json
{
  "replay_id": "replay-evt-2025-10-16-001",
  "lineage_event": "evt-2025-10-16-001",
  "snapshot": {
    "inputs": {
      "supplier_document": "sha256:abc123...",
      "regulatory_db_version": "2025-10-15"
    },
    "environment": {
      "powershell_version": "5.1.22621.4111",
      "modules": {
        "RAG-Verifier": "1.2.0",
        "Safety-Sandbox": "2.0.1"
      },
      "random_seed": 42
    },
    "agent_version": "agent-supplier-verifier-01:v1.3.2"
  },
  "outputs": {
    "decision": "approve",
    "evidence_hash": "sha256:def456...",
    "witness_signatures": ["sig:ghi789..."]
  },
  "replay_verified": true,
  "verification_timestamp": "2025-10-16T16:00:00Z"
}
```

### Resilience and Recovery

**Hot-Swap Procedure:**

```powershell
# scripts/ceremonies/13-agent-hot-swap/Invoke-AgentReplacement.ps1
param(
    [string]$FailedAgentId,
    [string]$ReplacementAgentId
)

# 1. Quarantine failed agent
Set-AgentStatus -AgentId $FailedAgentId -Status "quarantined"

# 2. Load escrowed mandate
$mandate = Get-EscrowedMandate -AgentId $FailedAgentId

# 3. Provision warm cache for replacement
Initialize-AgentCache -AgentId $ReplacementAgentId -From $FailedAgentId

# 4. Transfer active tasks
$activeTasks = Get-ActiveTasks -AgentId $FailedAgentId
foreach ($task in $activeTasks) {
    Move-TaskToAgent -Task $task -ToAgent $ReplacementAgentId
}

# 5. Activate replacement
Set-AgentStatus -AgentId $ReplacementAgentId -Status "active" -Mandate $mandate

# 6. Emit lineage event
New-LineageEvent -Type "agent_hot_swap" `
    -Failed $FailedAgentId `
    -Replacement $ReplacementAgentId `
    -TasksTransferred $activeTasks.Count
```

**Chaos Drills:**

- **Frequency**: Monthly scheduled fault injections
- **Scenarios**: Agent crash, network partition, data corruption, credential compromise
- **Metrics**: Recovery time, data loss, cascading failures
- **Scorecards**: Published to witness ring with improvement targets

---

## EU Compliance Alignment

### GDPR Compliance Checklist

✅ **Data Minimization**

- PII routed through scoped cells with redaction by default
- Tokenization for cross-cell references
- Retention policies enforced by lineage bus

✅ **Purpose Limitation**

- Mandates encode lawful bases (consent, contract, legal obligation)
- Task payloads carry purpose tags validated at trust gateways
- Cross-purpose data reuse blocked by context firewalls

✅ **Record of Processing Activities (RoPA)**

- Lineage events double as RoPA entries
- Export format: `scripts/utilities/Export-RoPA.ps1`
- Automated auditor access via read-only council portal

✅ **Supplier Due Diligence**

- Automated verification of CE marks, safety certificates
- Returns policy and warranty terms extraction
- Contract clause checker for GDPR processor requirements

✅ **Incident Response**

- 72-hour notification timers in `agents/civic/ceremonies/incident-response/`
- Impact scoping with affected data subject counts
- Containment procedures with hot-swap and rollback

### Data Processing Agreements (DPA)

**Template Location:** `council/policies/dpa-template.yaml`

**Required Clauses:**

- Processor obligations (Art. 28 GDPR)
- Sub-processor approval mechanisms
- Data breach notification (72h)
- Data subject rights facilitation
- Audit rights and compliance reporting

---

## Bootstrapping Roadmap

### Phase 1: Sovereign Nucleus (Week 1-2)

**Deliverables:**

- ✅ Identity/key generation: `scripts/ceremonies/14-identity-bootstrap/`
- ✅ Lineage bus: `bus/inbox/`, `bus/outbox/`, signed event schema
- ✅ Policy kernel: `council/policies/baseline.yaml`
- ✅ Revocation graph: `council/keys/revocation-log.jsonl`

**Scripts to Create:**

```powershell
# scripts/ceremonies/14-identity-bootstrap/New-AgentIdentity.ps1
# scripts/ceremonies/15-lineage-bus/Initialize-LineageBus.ps1
# scripts/ceremonies/16-policy-kernel/New-PolicyBaseline.ps1
```

### Phase 2: Domain Cells (Week 3-4)

**Deliverables:**

- Commerce cell: Supplier verifier, catalog checker, compliance gater
- Ops cell: CI/CD monitor, cost tracker, incident responder
- Governance cell: Mandate manager, audit coordinator, witness registry

**Agent Creation:**

```powershell
# agents/civic/New-CommerceCellAgent.ps1
# agents/build/New-OpsCellAgent.ps1
# agents/audit/New-GovernanceCellAgent.ps1
```

### Phase 3: Markets and Consensus (Week 5-6)

**Deliverables:**

- Routing auction system: `agents/registry/agent-marketplace.yaml`
- Consensus kernel: `agents/modules/Consensus-Kernel.psm1`
- Red agents: `agents/adversarial/red-team-simulator.ps1`

### Phase 4: Resilience and Drills (Week 7-8)

**Deliverables:**

- Chaos exercise framework: `tests/chaos/`
- Hot-swap runbooks: `scripts/ceremonies/13-agent-hot-swap/`
- Compliance bake-offs: `tests/compliance/`

---

## Integration with Existing Infrastructure

### Mapping to Current Structure

| Component                               | Current Location   | New Function                         |
| --------------------------------------- | ------------------ | ------------------------------------ |
| `council/manifest.json`                 | Agent registry     | → Multi-sig mandate store            |
| `bus/inbox/`, `bus/outbox/`             | Message passing    | → Signed lineage event bus           |
| `agents/factory/agent-factory.ps1`      | Agent creation     | → Trust gateway + capability routing |
| `agents/master/master-orchestrator.ps1` | Coordination       | → Sovereign nucleus orchestrator     |
| `evidence/`                             | Audit trails       | → Witness ring evidence store        |
| `council/policies/`                     | Policy definitions | → Policy kernel constraint library   |

### Migration Strategy

1. **Backwards Compatibility**: Existing agents continue to work during migration
2. **Incremental Adoption**: Add lineage events to new ceremonies first
3. **Parallel Testing**: Run old and new governance side-by-side with comparison
4. **Cutover**: Switch to new system once all domain cells validated

---

## Next Steps

### Immediate Actions (This Session)

1. **Create Agent Role Manifest Schema** (`council/schemas/agent-mandate.schema.yaml`)
2. **Implement Lineage Event Bus** (`bus/lineage/`, event signing)
3. **Build Consensus Kernel Module** (`agents/modules/Consensus-Kernel.psm1`)
4. **Design Governance Ceremonies** (Mandate definition, proposal approval, execution audit)
5. **Create Performance Market System** (Routing auctions, reputation tracking)

### Documentation Deliverables

- [ ] Agent role manifest examples (3-5 roles)
- [ ] Lineage event schema with JSON-LD context
- [ ] Consensus algorithm pseudocode and implementation
- [ ] Governance ceremony runbooks (3 ceremonies)
- [ ] Compliance checklist and RoPA export tool

### Code Deliverables

- [ ] `agents/modules/Agent-Identity.psm1` - Identity and key management
- [ ] `agents/modules/Lineage-Bus.psm1` - Event emission and signing
- [ ] `agents/modules/Consensus-Kernel.psm1` - Weighted voting system
- [ ] `scripts/ceremonies/12-mandate-definition/` - Full ceremony
- [ ] `scripts/utilities/Export-RoPA.ps1` - GDPR compliance tool

---

**Ready to proceed with implementation. Which component should we build first?**

Options:
A. **Agent Role Manifest Schema** - Foundation for all other components
B. **Lineage Event Bus** - Critical for audit trail immediately
C. **Consensus Kernel** - Enable multi-agent decision making
D. **Governance Ceremonies** - Practical workflows for daily operations
E. **All of the above in parallel** - Comprehensive rollout (recommended)

