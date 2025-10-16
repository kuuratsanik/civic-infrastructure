# Multi-Agent Governance Manifest Schema

## Overview

This schema defines the structure for multi-signature governance manifests that flow through the hierarchical AI team management system. Each tier (Master, Assistant, Manager, Domain Team) contributes signatures and evidence, creating a **tamper-evident lineage chain** from feature execution to final approval.

---

## Schema Version: 1.0

```json
{
  "$schema": "https://civic-infrastructure.local/schemas/multi-agent-governance-v1.json",
  "version": "1.0.0",
  "ceremony": {
    "id": "string (uuid or timestamp-based)",
    "type": "enum [weekly_resilience, monthly_review, quarterly_audit, policy_update, emergency_response]",
    "initiated_at": "ISO8601 timestamp",
    "completed_at": "ISO8601 timestamp",
    "duration_seconds": "number",
    "status": "enum [pending, active, completed, failed, cancelled]",
    "master_directive": {
      "text": "Natural language directive from Master",
      "priority": "enum [critical, high, medium, low]",
      "resource_allocation": {
        "cpu_ceiling": "number (percentage, default 80)",
        "ram_ceiling": "number (percentage, default 70)",
        "time_limit_minutes": "number (default 15)",
        "max_concurrent_packets": "number (default 4)"
      },
      "approval_metadata": {
        "approved_by": "master.civic.orchestrator",
        "approval_timestamp": "ISO8601 timestamp",
        "approval_reason": "string (governance rationale)",
        "override_flags": "array of strings (if any policies overridden)"
      }
    }
  },
  "signatures": {
    "master": {
      "agent_id": "master.civic.orchestrator",
      "key_id": "string (public key identifier)",
      "algorithm": "enum [SHA256-RSA, Ed25519, ECDSA-secp256k1]",
      "signature": "string (hex-encoded signature)",
      "signed_at": "ISO8601 timestamp",
      "manifest_hash_at_signing": "string (SHA256 of manifest before Master signature)",
      "status": "enum [approved, rejected, conditional]",
      "conditions": "array of strings (if status=conditional)",
      "metadata": {
        "conflicts_arbitrated": "array of conflict resolutions",
        "policy_exceptions": "array of approved exceptions",
        "compliance_notes": "string"
      }
    },
    "assistants": [
      {
        "agent_id": "string (e.g., assistant.resilience)",
        "domain": "enum [resilience, governance, operations, security, finance, healthcare, marketing]",
        "key_id": "string",
        "algorithm": "string",
        "signature": "string",
        "signed_at": "ISO8601 timestamp",
        "manifest_hash_at_signing": "string",
        "execution_summary": {
          "packets_assigned": "number",
          "packets_completed": "number",
          "packets_failed": "number",
          "total_features": "number",
          "anomalies_escalated": "number",
          "evidence_packs_produced": "number"
        },
        "escalations": [
          {
            "escalation_id": "string",
            "severity": "enum [critical, high, medium, low]",
            "description": "string",
            "escalated_at": "ISO8601 timestamp",
            "resolved": "boolean",
            "resolution": "string (if resolved)"
          }
        ],
        "metadata": {
          "domain_context": "object (domain-specific data)",
          "coordinator_notes": "string"
        }
      }
    ],
    "managers": [
      {
        "agent_id": "string (e.g., manager.hash.integrity)",
        "feature_family": "enum [hash_verification, port_allowlist, firewall_diff, sbom_presence, policy_compliance, audit_trail]",
        "packet_id": "string",
        "key_id": "string",
        "algorithm": "string",
        "signature": "string",
        "signed_at": "ISO8601 timestamp",
        "evidence_pack_hash": "string (SHA256 of evidence pack)",
        "execution_summary": {
          "features_executed": "number",
          "features_passed": "number",
          "features_anomaly": "number",
          "features_failed": "number",
          "execution_time_seconds": "number",
          "parallel_execution": "boolean",
          "thread_count": "number (if parallel)"
        },
        "deduplication": {
          "enabled": "boolean",
          "total_evidence_items": "number",
          "unique_deltas": "number",
          "duplicates_found": "number",
          "deduplication_ratio": "number (percentage)",
          "storage_savings_bytes": "number"
        },
        "anomalies": [
          {
            "feature_id": "string",
            "severity": "enum [critical, high, medium, low]",
            "description": "string",
            "evidence_delta_hash": "string",
            "detected_at": "ISO8601 timestamp",
            "action_taken": "enum [escalated, auto_remediated, logged, deferred]"
          }
        ],
        "metadata": {
          "resource_utilization": {
            "cpu_peak": "number (percentage)",
            "ram_peak": "number (percentage)",
            "disk_io_mb": "number"
          },
          "executor_notes": "string"
        }
      }
    ],
    "domain_teams": [
      {
        "team_id": "string (e.g., domain.civic.infrastructure)",
        "domain": "string",
        "key_id": "string",
        "algorithm": "string",
        "signature": "string",
        "signed_at": "ISO8601 timestamp",
        "features_manifest_hash": "string (SHA256 of all feature results)",
        "execution_summary": {
          "features_executed": "number",
          "features_passed": "number",
          "features_anomaly": "number",
          "features_failed": "number",
          "templates_used": "array of template names"
        },
        "feature_results": [
          {
            "feature_id": "string",
            "template_family": "string",
            "parameters": "object (feature-specific params)",
            "status": "enum [pass, anomaly, failed, deferred, blocked]",
            "yield": "enum [high, medium, low, clean, error]",
            "evidence_delta_hash": "string",
            "execution_time_ms": "number",
            "signed_at": "ISO8601 timestamp",
            "signature": "string (optional per-feature signature)"
          }
        ],
        "metadata": {
          "domain_context": "object",
          "knowledge_base_version": "string",
          "team_notes": "string"
        }
      }
    ]
  },
  "evidence": {
    "packs": [
      {
        "pack_id": "string (e.g., pack_20251013_001)",
        "packet_id": "string",
        "manager_id": "string",
        "pack_hash": "string (SHA256 of entire pack)",
        "created_at": "ISO8601 timestamp",
        "manifest_path": "string (file path)",
        "deltas": [
          {
            "delta_id": "string",
            "delta_hash": "string (SHA256)",
            "size_bytes": "number",
            "compression": "enum [none, gzip, optimal]",
            "path": "string (file path)",
            "referenced_by": "array of feature_ids"
          }
        ],
        "feature_references": [
          {
            "feature_id": "string",
            "reference_type": "enum [direct, reference]",
            "delta_hash": "string",
            "status": "string",
            "yield": "string",
            "timestamp": "ISO8601 timestamp"
          }
        ],
        "integrity": {
          "verified": "boolean",
          "verified_at": "ISO8601 timestamp",
          "verification_method": "enum [hash_chain, signature_chain, both]"
        }
      }
    ],
    "aggregation_summary": {
      "total_packs": "number",
      "total_features": "number",
      "total_deltas": "number",
      "total_size_bytes": "number",
      "total_size_compressed_bytes": "number",
      "compression_ratio": "number",
      "deduplication_savings_bytes": "number"
    }
  },
  "lineage": {
    "chain": [
      {
        "from": "string (agent_id)",
        "to": "string (agent_id)",
        "artifact": "string (what was passed)",
        "artifact_hash": "string (SHA256)",
        "transferred_at": "ISO8601 timestamp",
        "signature_verified": "boolean"
      }
    ],
    "integrity": {
      "complete": "boolean",
      "verified": "boolean",
      "verification_timestamp": "ISO8601 timestamp",
      "breaks": "array of objects (if any chain breaks detected)"
    },
    "traceability": {
      "feature_to_master": "object mapping feature_id to full chain",
      "decision_points": "array of governance decisions with justifications"
    }
  },
  "metrics": {
    "performance": {
      "total_duration_seconds": "number",
      "packet_execution_times": "array of numbers",
      "average_packet_time": "number",
      "parallel_efficiency": "number (percentage)",
      "resource_utilization": {
        "cpu_average": "number",
        "cpu_peak": "number",
        "ram_average": "number",
        "ram_peak": "number"
      }
    },
    "governance": {
      "total_signatures": "number",
      "signature_verification_success_rate": "number (percentage)",
      "escalations_raised": "number",
      "escalations_resolved": "number",
      "overrides_applied": "number"
    },
    "quality": {
      "features_passed": "number",
      "features_anomaly": "number",
      "features_failed": "number",
      "anomaly_rate": "number (percentage)",
      "false_positive_rate": "number (percentage, if available)",
      "yield_distribution": {
        "high": "number",
        "medium": "number",
        "low": "number",
        "clean": "number"
      }
    }
  },
  "audit": {
    "trail_entry_id": "string (reference to audit trail)",
    "compliance_checkpoints": [
      {
        "checkpoint": "string (what was checked)",
        "status": "enum [pass, fail, warning]",
        "details": "string"
      }
    ],
    "external_references": [
      {
        "reference_type": "enum [policy, regulation, standard, baseline]",
        "reference_id": "string",
        "compliance_status": "enum [compliant, non_compliant, partial]"
      }
    ]
  },
  "metadata": {
    "schema_version": "string",
    "created_by": "string (agent or operator)",
    "workspace": "string (computer/environment identifier)",
    "tags": "array of strings (for categorization)",
    "notes": "string (free-form operational notes)"
  }
}
```

---

## Example: Complete Weekly Resilience Ceremony

```json
{
  "$schema": "https://civic-infrastructure.local/schemas/multi-agent-governance-v1.json",
  "version": "1.0.0",
  "ceremony": {
    "id": "ceremony_20251013_193000_weekly_resilience",
    "type": "weekly_resilience",
    "initiated_at": "2025-10-13T19:30:00Z",
    "completed_at": "2025-10-13T19:42:15Z",
    "duration_seconds": 735,
    "status": "completed",
    "master_directive": {
      "text": "Execute weekly resilience drill with focus on hash integrity and firewall baseline validation. Prioritize civic infrastructure domain.",
      "priority": "high",
      "resource_allocation": {
        "cpu_ceiling": 80,
        "ram_ceiling": 70,
        "time_limit_minutes": 15,
        "max_concurrent_packets": 4
      },
      "approval_metadata": {
        "approved_by": "master.civic.orchestrator",
        "approval_timestamp": "2025-10-13T19:30:00Z",
        "approval_reason": "Scheduled weekly governance maintenance",
        "override_flags": []
      }
    }
  },
  "signatures": {
    "master": {
      "agent_id": "master.civic.orchestrator",
      "key_id": "master_key_v1_20251001",
      "algorithm": "Ed25519",
      "signature": "0xa1b2c3d4e5f67890abcdef1234567890abcdef1234567890abcdef1234567890",
      "signed_at": "2025-10-13T19:42:30Z",
      "manifest_hash_at_signing": "sha256:789abc...",
      "status": "approved",
      "conditions": [],
      "metadata": {
        "conflicts_arbitrated": [],
        "policy_exceptions": [],
        "compliance_notes": "All procedures followed, no deviations"
      }
    },
    "assistants": [
      {
        "agent_id": "assistant.resilience",
        "domain": "resilience",
        "key_id": "assistant_resilience_v1_20251001",
        "algorithm": "Ed25519",
        "signature": "0xb2c3d4e5f67890abcdef1234567890abcdef1234567890abcdef1234567890ab",
        "signed_at": "2025-10-13T19:42:00Z",
        "manifest_hash_at_signing": "sha256:456def...",
        "execution_summary": {
          "packets_assigned": 5,
          "packets_completed": 5,
          "packets_failed": 0,
          "total_features": 500,
          "anomalies_escalated": 3,
          "evidence_packs_produced": 5
        },
        "escalations": [
          {
            "escalation_id": "esc_001_hash_mismatch",
            "severity": "high",
            "description": "SystemBaseline.json hash mismatch detected - potential unauthorized modification",
            "escalated_at": "2025-10-13T19:35:12Z",
            "resolved": true,
            "resolution": "Verified change was from approved ceremony_20251012, hash registry updated"
          },
          {
            "escalation_id": "esc_002_port_anomaly",
            "severity": "medium",
            "description": "Unauthorized port 8080 listening - not in allowlist",
            "escalated_at": "2025-10-13T19:36:45Z",
            "resolved": true,
            "resolution": "Development server from authorized session, temporary exception granted"
          },
          {
            "escalation_id": "esc_003_firewall_drift",
            "severity": "low",
            "description": "Firewall rule count increased by 2 from baseline",
            "escalated_at": "2025-10-13T19:38:20Z",
            "resolved": true,
            "resolution": "New rules from approved policy update, baseline will be refreshed"
          }
        ],
        "metadata": {
          "domain_context": {
            "last_weekly_ceremony": "2025-10-06T19:30:00Z",
            "ceremony_count_this_month": 2
          },
          "coordinator_notes": "Smooth execution, anomalies within expected range"
        }
      }
    ],
    "managers": [
      {
        "agent_id": "manager.hash.integrity",
        "feature_family": "hash_verification",
        "packet_id": "packet_20251013_001",
        "key_id": "manager_hash_v1_20251001",
        "algorithm": "Ed25519",
        "signature": "0xc3d4e5f67890abcdef1234567890abcdef1234567890abcdef1234567890abcd",
        "signed_at": "2025-10-13T19:32:30Z",
        "evidence_pack_hash": "sha256:a1b2c3d4e5f67890...",
        "execution_summary": {
          "features_executed": 100,
          "features_passed": 97,
          "features_anomaly": 2,
          "features_failed": 1,
          "execution_time_seconds": 145,
          "parallel_execution": true,
          "thread_count": 4
        },
        "deduplication": {
          "enabled": true,
          "total_evidence_items": 100,
          "unique_deltas": 32,
          "duplicates_found": 68,
          "deduplication_ratio": 68.0,
          "storage_savings_bytes": 2457600
        },
        "anomalies": [
          {
            "feature_id": "hash_verify_001_systembaseline",
            "severity": "high",
            "description": "Hash mismatch: expected sha256:abc123..., got sha256:def456...",
            "evidence_delta_hash": "sha256:evidence_delta_001...",
            "detected_at": "2025-10-13T19:35:12Z",
            "action_taken": "escalated"
          },
          {
            "feature_id": "hash_verify_045_audittrail",
            "severity": "medium",
            "description": "Hash verification succeeded but file size unexpected",
            "evidence_delta_hash": "sha256:evidence_delta_002...",
            "detected_at": "2025-10-13T19:35:45Z",
            "action_taken": "logged"
          }
        ],
        "metadata": {
          "resource_utilization": {
            "cpu_peak": 72.5,
            "ram_peak": 58.3,
            "disk_io_mb": 145
          },
          "executor_notes": "Parallel execution efficient, deduplication performing well"
        }
      }
    ],
    "domain_teams": [
      {
        "team_id": "domain.civic.infrastructure",
        "domain": "civic_infrastructure",
        "key_id": "domain_civic_v1_20251001",
        "algorithm": "Ed25519",
        "signature": "0xd4e5f67890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        "signed_at": "2025-10-13T19:32:15Z",
        "features_manifest_hash": "sha256:feature_results_001...",
        "execution_summary": {
          "features_executed": 75,
          "features_passed": 72,
          "features_anomaly": 2,
          "features_failed": 1,
          "templates_used": ["hash_verification_v1", "policy_compliance_v1"]
        },
        "feature_results": [
          {
            "feature_id": "hash_verify_001_systembaseline",
            "template_family": "hash_verification",
            "parameters": {
              "config_path": "C:\\Users\\svenk\\Documents\\WindowsGovernance\\SystemBaseline.json",
              "expected_hash": "sha256:abc123...",
              "algorithm": "SHA256"
            },
            "status": "anomaly",
            "yield": "high",
            "evidence_delta_hash": "sha256:evidence_delta_001...",
            "execution_time_ms": 23,
            "signed_at": "2025-10-13T19:35:12Z",
            "signature": "0xe5f67890abcdef..."
          }
        ],
        "metadata": {
          "domain_context": {
            "os_version": "Windows 11 Pro 26220",
            "governance_tier": "sovereign"
          },
          "knowledge_base_version": "civic_kb_v2.1",
          "team_notes": "Standard execution, anomalies match expected patterns"
        }
      }
    ]
  },
  "evidence": {
    "packs": [
      {
        "pack_id": "pack_20251013_001",
        "packet_id": "packet_20251013_001",
        "manager_id": "manager.hash.integrity",
        "pack_hash": "sha256:pack_hash_001...",
        "created_at": "2025-10-13T19:32:30Z",
        "manifest_path": "C:\\Users\\svenk\\Documents\\WindowsGovernance\\Evidence\\Manifests\\packet_20251013_001.json",
        "deltas": [
          {
            "delta_id": "delta_a1b2c3",
            "delta_hash": "sha256:delta_001...",
            "size_bytes": 4096,
            "compression": "optimal",
            "path": "C:\\Users\\svenk\\Documents\\WindowsGovernance\\Evidence\\Deltas\\delta_a1b2c3.json",
            "referenced_by": ["hash_verify_001", "hash_verify_045", "hash_verify_078"]
          }
        ],
        "feature_references": [
          {
            "feature_id": "hash_verify_001_systembaseline",
            "reference_type": "direct",
            "delta_hash": "sha256:evidence_delta_001...",
            "status": "anomaly",
            "yield": "high",
            "timestamp": "2025-10-13T19:35:12Z"
          }
        ],
        "integrity": {
          "verified": true,
          "verified_at": "2025-10-13T19:42:00Z",
          "verification_method": "both"
        }
      }
    ],
    "aggregation_summary": {
      "total_packs": 5,
      "total_features": 500,
      "total_deltas": 156,
      "total_size_bytes": 10485760,
      "total_size_compressed_bytes": 3670016,
      "compression_ratio": 2.86,
      "deduplication_savings_bytes": 12288000
    }
  },
  "lineage": {
    "chain": [
      {
        "from": "domain.civic.infrastructure",
        "to": "manager.hash.integrity",
        "artifact": "feature_results_bundle",
        "artifact_hash": "sha256:feature_results_001...",
        "transferred_at": "2025-10-13T19:32:15Z",
        "signature_verified": true
      },
      {
        "from": "manager.hash.integrity",
        "to": "assistant.resilience",
        "artifact": "evidence_pack_001",
        "artifact_hash": "sha256:pack_hash_001...",
        "transferred_at": "2025-10-13T19:32:30Z",
        "signature_verified": true
      },
      {
        "from": "assistant.resilience",
        "to": "master.civic.orchestrator",
        "artifact": "domain_manifest_resilience",
        "artifact_hash": "sha256:456def...",
        "transferred_at": "2025-10-13T19:42:00Z",
        "signature_verified": true
      }
    ],
    "integrity": {
      "complete": true,
      "verified": true,
      "verification_timestamp": "2025-10-13T19:42:30Z",
      "breaks": []
    },
    "traceability": {
      "feature_to_master": {
        "hash_verify_001_systembaseline": [
          "domain.civic.infrastructure",
          "manager.hash.integrity",
          "assistant.resilience",
          "master.civic.orchestrator"
        ]
      },
      "decision_points": [
        {
          "decision": "Approve ceremony execution",
          "made_by": "master.civic.orchestrator",
          "timestamp": "2025-10-13T19:30:00Z",
          "justification": "Scheduled weekly governance maintenance"
        },
        {
          "decision": "Escalate hash mismatch anomaly",
          "made_by": "assistant.resilience",
          "timestamp": "2025-10-13T19:35:12Z",
          "justification": "High severity anomaly requires Master review"
        }
      ]
    }
  },
  "metrics": {
    "performance": {
      "total_duration_seconds": 735,
      "packet_execution_times": [145, 152, 138, 147, 153],
      "average_packet_time": 147,
      "parallel_efficiency": 87.3,
      "resource_utilization": {
        "cpu_average": 64.2,
        "cpu_peak": 78.5,
        "ram_average": 52.1,
        "ram_peak": 65.8
      }
    },
    "governance": {
      "total_signatures": 12,
      "signature_verification_success_rate": 100.0,
      "escalations_raised": 3,
      "escalations_resolved": 3,
      "overrides_applied": 0
    },
    "quality": {
      "features_passed": 485,
      "features_anomaly": 12,
      "features_failed": 3,
      "anomaly_rate": 2.4,
      "false_positive_rate": 0.0,
      "yield_distribution": {
        "high": 15,
        "medium": 32,
        "low": 8,
        "clean": 445
      }
    }
  },
  "audit": {
    "trail_entry_id": "audit_entry_20251013_193000",
    "compliance_checkpoints": [
      {
        "checkpoint": "All features signed by appropriate domain teams",
        "status": "pass",
        "details": "100% feature signature coverage"
      },
      {
        "checkpoint": "Evidence packs integrity verified",
        "status": "pass",
        "details": "All 5 packs verified with hash chains"
      },
      {
        "checkpoint": "Resource ceilings respected",
        "status": "pass",
        "details": "CPU max 78.5% (limit 80%), RAM max 65.8% (limit 70%)"
      }
    ],
    "external_references": [
      {
        "reference_type": "policy",
        "reference_id": "civic_infrastructure_policy_v2.0",
        "compliance_status": "compliant"
      }
    ]
  },
  "metadata": {
    "schema_version": "1.0.0",
    "created_by": "master.civic.orchestrator",
    "workspace": "SVEN-DELL",
    "tags": ["weekly", "resilience", "hash_integrity", "firewall_baseline"],
    "notes": "Successful ceremony with minimal anomalies, all escalations resolved within ceremony timeframe"
  }
}
```

---

## Validation Rules

### **Schema Integrity**
1. All signatures must be present for respective agent tiers
2. Lineage chain must be complete from Domain → Manager → Assistant → Master
3. Evidence pack hashes must match referenced deltas
4. Timestamps must be chronologically consistent
5. All required fields must be non-null

### **Signature Verification**
1. Each signature must verify against agent's public key
2. Manifest hash at signing must match computed hash at verification
3. Signature algorithms must be from approved list
4. Key IDs must reference current, non-revoked keys

### **Lineage Validation**
1. Each artifact transfer must have verified signatures
2. No breaks in chain from feature to Master
3. All decision points must reference signing agent
4. Timestamp ordering must be consistent

---

## Usage in PowerShell

```powershell
# Load and validate manifest
$ManifestPath = "C:\Users\svenk\Documents\WindowsGovernance\Ceremonies\ceremony_20251013.json"
$Manifest = Get-Content $ManifestPath | ConvertFrom-Json

# Verify signature chain
$ValidationResult = Test-ManifestSignatureChain -Manifest $Manifest

if ($ValidationResult.Valid) {
    Write-Host "Manifest signature chain verified successfully" -ForegroundColor Green
} else {
    Write-Host "Manifest validation FAILED: $($ValidationResult.Issues)" -ForegroundColor Red
}

# Extract lineage for specific feature
$FeatureLineage = Get-FeatureLineage -Manifest $Manifest -FeatureId "hash_verify_001_systembaseline"

# Generate compliance report
$ComplianceReport = New-ComplianceReport -Manifest $Manifest -OutputPath "C:\Reports\compliance.html"
```

---

**Status: Schema defined and ready for implementation in governance toolkit.**