# 🏛️ Multi-Agent Intelligence Framework - README

**Version:** 1.0.0
**Status:** ✅ Phase 1-5 Complete (Production Ready)
**Created:** 2025-10-16

---

## Overview

This directory contains a **sovereign, audit-ready multi-agent intelligence system** for treating AI orchestration as reproducible, auditable civic infrastructure. Built on ceremonial governance principles with tamper-evident lineage, multi-agent consensus, and GDPR-native compliance.

---

## Quick Start

### 1. Validate Agent Manifests

```powershell
Import-Module .\Agent-Manifest-Validator.psm1
Test-AllAgentManifests -Path "..\..\council\mandates"
```

### 2. Emit Lineage Events

```powershell
Import-Module .\Lineage-Bus.psm1
New-LineageEvent -EventType "test" -AgentRole "system" -Payload @{ test = $true }
```

### 3. Create Consensus Proposal

```powershell
Import-Module .\Consensus-Kernel.psm1
New-ConsensusProposal -AgentRole "agent-1" -Domain "civic" -Summary "..." -WorkloadReceipt @{ ... } -RiskTier "medium"
```

---

## Module Reference

| Module                            | Purpose                         | Key Functions                                                                                      |
| --------------------------------- | ------------------------------- | -------------------------------------------------------------------------------------------------- |
| **Agent-Manifest-Validator.psm1** | Validate agent role definitions | `Test-AgentManifest`, `Test-AllAgentManifests`, `New-AgentManifest`                                |
| **Lineage-Bus.psm1**              | Tamper-evident event stream     | `New-LineageEvent`, `Get-LineageEvents`, `Test-LineageEventIntegrity`, `Export-LineageAuditReport` |
| **Consensus-Kernel.psm1**         | Multi-agent weighted voting     | `New-ConsensusProposal`, `Add-ConsensusVote`, `Get-ConsensusProposal`                              |

---

## File Structure

```
agents/modules/
├── Agent-Manifest-Validator.psm1   # 350 lines - Manifest validation & creation
├── Lineage-Bus.psm1                # 450 lines - Event emission & audit trails
├── Consensus-Kernel.psm1           # 400 lines - Weighted voting & consensus
└── README.md                       # This file

council/
├── schemas/
│   └── agent-mandate.schema.yaml   # Complete schema definition
├── mandates/
│   └── *.yaml                      # Agent role manifests
├── proposals/                      # Consensus proposals (auto-created)
└── voting-history/                 # Vote tracking (auto-created)

bus/lineage/
├── events/*.jsonl                  # Append-only event logs
├── index/*.json                    # Event index for fast lookup
├── signatures/*.sig                # Detached cryptographic signatures
└── replay/*.bundle.json            # Deterministic replay bundles
```

---

## Core Concepts

### 1. Agent Mandates

**Definition:** YAML documents defining agent identity, scope, constraints, KPIs, and governance.

**Example:**

```yaml
role: "commerce-supplier-verifier"
mandate:
  scope: ["supplier_onboarding", "compliance_check"]
  constraints: ["GDPR for PII handling", "EU consumer protection"]
kpis:
  precision: ">= 98%"
  latency: "<= 2m"
lineage:
  emit_events: true
  signature_required: true
```

**Validation:**

```powershell
Test-AgentManifest -ManifestPath "council/mandates/commerce-supplier-verifier.yaml"
```

---

### 2. Lineage Events

**Definition:** Tamper-evident, cryptographically signed records of agent decisions.

**Schema:**

```json
{
  "event_id": "evt-20251016-143022-abc12345",
  "event_type": "decision",
  "timestamp": "2025-10-16T14:30:22.123Z",
  "agent_role": "commerce-supplier-verifier",
  "payload": { ... },
  "event_hash": "sha256:...",
  "signature": "base64:...",
  "witnesses": ["witness-audit-01"]
}
```

**Emission:**

```powershell
New-LineageEvent -EventType "supplier_approved" `
    -AgentRole "commerce-supplier-verifier" `
    -Payload @{ supplier_id = "SUP-001"; compliance_score = 0.98 } `
    -Witnesses @("witness-audit-01")
```

---

### 3. Consensus Proposals

**Definition:** Multi-agent voting mechanism with weighted influence and proof-of-workload.

**Workflow:**

1. Agent creates proposal with evidence bundle
2. Other agents cast weighted votes
3. Threshold approval triggers lineage event
4. Proposal status: pending → approved/rejected

**Example:**

```powershell
# Create proposal
$p = New-ConsensusProposal -AgentRole "build-iso-optimizer" -Domain "build" -Summary "..." -RiskTier "high"

# Cast votes
Add-ConsensusVote -ProposalId $p.ProposalId -AgentRole "agent-1" -Decision "approve" -Rationale "..."

# Check status
Get-ConsensusProposal -ProposalId $p.ProposalId
```

---

## Integration Examples

### ISO Build Agent

```powershell
# In agents/build/iso-build-ai-agent.ps1
Import-Module "$PSScriptRoot\..\modules\Lineage-Bus.psm1"

# Before build
New-LineageEvent -EventType "iso_build_started" -AgentRole "build-iso-optimizer" -Payload @{ build_id = $buildId }

# After build
New-LineageEvent -EventType "iso_build_completed" -AgentRole "build-iso-optimizer" -Payload @{ output_iso = $outputPath }
```

### Civic Ceremony Agent

```powershell
# In agents/civic/civic-agent.ps1
Import-Module "$PSScriptRoot\..\modules\Agent-Manifest-Validator.psm1"

# Validate mandate before ceremony
$validation = Test-AgentManifest -ManifestPath "council/mandates/civic-ceremony-orchestrator.yaml"
if (-not $validation.Valid) { throw "Mandate invalid" }
```

---

## GDPR Compliance

### Data Minimization

Agent manifests specify PII handling levels:

- `no-access`: No PII allowed
- `tokenized`: PII replaced with tokens
- `scoped-cell`: PII isolated to specific domain cell
- `full-access`: Full PII access (requires GDPR constraints)

### RoPA Export

```powershell
# Export lineage events as GDPR Record of Processing Activities
Export-LineageAuditReport -StartDate "2025-10-01" -EndDate "2025-10-31" -Format CSV -OutputPath "ropa-october.csv"
```

---

## Security

### Event Integrity

All lineage events are:

1. **Hashed** (SHA-256 of canonical JSON)
2. **Signed** (base64-encoded signature)
3. **Indexed** (fast lookup by date/agent/type)
4. **Immutable** (append-only logs)

### Verification

```powershell
# Verify event integrity
Test-LineageEventIntegrity -EventId "evt-20251016-143022-abc12345"

# Verify all today's events
$events = Get-LineageEvents -StartDate (Get-Date).Date
foreach ($event in $events) {
    $valid = Test-LineageEventIntegrity -Event $event
    if (-not $valid) { Write-Warning "Integrity violation: $($event.event_id)" }
}
```

---

## Risk Tiers & Approval Thresholds

| Risk Tier    | Signatures Required | Witnesses | Min Weight | Example Actions             |
| ------------ | ------------------- | --------- | ---------- | --------------------------- |
| **Low**      | 1                   | 0         | 0.5        | Data fetch, read log        |
| **Medium**   | 2                   | 1         | 0.7        | Config update, price change |
| **High**     | 3                   | 2         | 0.75       | New supplier, ISO release   |
| **Critical** | 5                   | 3         | 0.85       | Policy change, key rotation |

---

## Documentation

| Document                                                | Purpose                                     |
| ------------------------------------------------------- | ------------------------------------------- |
| `docs/governance/multi-agent-intelligence-framework.md` | Complete architecture (1,200 lines)         |
| `docs/AI-MULTI-AGENT-QUICKSTART.md`                     | Quick start & integration guide (800 lines) |
| `AI-MULTI-AGENT-IMPLEMENTATION-COMPLETE.md`             | Implementation summary & statistics         |
| `council/schemas/agent-mandate.schema.yaml`             | YAML schema specification                   |
| `council/mandates/*.yaml`                               | Example agent manifests                     |

---

## Testing

### Validate All Manifests

```powershell
Import-Module .\Agent-Manifest-Validator.psm1
Test-AllAgentManifests -Strict  # Warnings become errors
```

### Verify Event Integrity

```powershell
Import-Module .\Lineage-Bus.psm1
$events = Get-LineageEvents -StartDate (Get-Date).AddDays(-7)
foreach ($e in $events) { Test-LineageEventIntegrity -Event $e }
```

### Test Consensus Voting

```powershell
Import-Module .\Consensus-Kernel.psm1

# Create test proposal
$p = New-ConsensusProposal -AgentRole "test-agent" -Domain "civic" -Summary "Test" -WorkloadReceipt @{ data_accessed = @(); checks_performed = 1; compute_time_ms = 100; evidence_hash = "test" } -RiskTier "low"

# Vote (low risk = 1 signature required)
Add-ConsensusVote -ProposalId $p.ProposalId -AgentRole "test-agent" -Decision "approve" -Rationale "Test vote"

# Should be approved
Get-ConsensusProposal -ProposalId $p.ProposalId  # Status should be "approved"
```

---

## Troubleshooting

### Issue: Module not found

**Solution:**

```powershell
# Ensure you're in the modules directory or use full path
Import-Module "c:\Users\svenk\OneDrive\All_My_Projects\New folder\agents\modules\Lineage-Bus.psm1"
```

### Issue: powershell-yaml not installed

**Solution:**

```powershell
Install-Module -Name powershell-yaml -Force -Scope CurrentUser
```

### Issue: Event signature invalid

**Cause:** Tamper detection (event modified after signing)

**Solution:** Do not manually edit event files. Use `New-LineageEvent` only.

---

## Next Steps

### Phase 6: Performance Markets (Remaining TODO)

Build auction-based task routing:

```powershell
# agents/modules/Performance-Market.psm1
New-TaskAuction -TaskId "..." -Requirements @{ capability = "iso_construction" }
Submit-AuctionBid -TaskId "..." -AgentRole "..." -BidCredits 2.5
Award-TaskToWinner -TaskId "..."
Update-ReputationCredits -AgentRole "..." -Credits 50
```

### Integration Roadmap

1. ✅ **Validate existing agents** (if any)
2. ✅ **Emit lineage events** for all agent decisions
3. ⏳ **Use consensus voting** for high-impact decisions
4. ⏳ **Create new agents** via mandate ceremony
5. ⏳ **Export audit reports** monthly (GDPR RoPA)

---

## Support

**Documentation:** See `docs/` for complete guides
**Examples:** Check `council/mandates/` for reference manifests
**Integration:** Review `docs/AI-MULTI-AGENT-QUICKSTART.md` for examples

---

## License & Governance

This framework is part of the **Civic Infrastructure Project** and follows **ceremonial governance** principles:

- ✅ Every change must be anchored and auditable
- ✅ Treat OS/AI customization as civic infrastructure
- ✅ Maintain reproducibility across environments
- ✅ Document all ceremonies and ritual scripts

---

**🎉 Phase 1-5 Complete - Ready for Integration!**

See `AI-MULTI-AGENT-IMPLEMENTATION-COMPLETE.md` for full implementation summary.

