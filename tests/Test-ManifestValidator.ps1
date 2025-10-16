# Test-ManifestValidator.ps1
# Integration tests for ManifestValidator module

#Requires -Version 5.1

<#
.SYNOPSIS
    Tests the ManifestValidator module with sample manifests
.DESCRIPTION
    Creates test manifests and validates signature chains, lineage, and compliance reporting
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$Detailed
)

$ErrorActionPreference = "Stop"

# Import required modules
$ModulePath = Join-Path $PSScriptRoot "..\scripts\modules"
Import-Module (Join-Path $ModulePath "ManifestValidator.psm1") -Force

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   ManifestValidator Module Tests" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$TestResults = @{
    Passed = 0
    Failed = 0
    Total = 0
}

# ============================================================================
# TEST 1: Generate Test Agent Keys
# ============================================================================

Write-Host "[TEST 1] Generating test agent keys..." -ForegroundColor Yellow

try {
    $MasterKey = Initialize-AgentKeyPair -AgentId "master.civic.orchestrator" -Algorithm "Ed25519"
    $AssistantKey = Initialize-AgentKeyPair -AgentId "assistant.resilience" -Algorithm "Ed25519"
    $ManagerKey = Initialize-AgentKeyPair -AgentId "manager.hash.integrity" -Algorithm "Ed25519"
    $DomainKey = Initialize-AgentKeyPair -AgentId "domain.civic.infrastructure" -Algorithm "Ed25519"
    
    Write-Host "SUCCESS: Generated 4 agent key pairs" -ForegroundColor Green
    $TestResults.Passed++
} catch {
    Write-Host "FAILED: $_" -ForegroundColor Red
    $TestResults.Failed++
}

$TestResults.Total++
Write-Host ""

# ============================================================================
# TEST 2: Create Test Manifest
# ============================================================================

Write-Host "[TEST 2] Creating test governance manifest..." -ForegroundColor Yellow

try {
    $TestManifest = @{
        '$schema' = "https://civic-infrastructure.local/schemas/multi-agent-governance-v1.json"
        version = "1.0.0"
        ceremony = @{
            id = "test_ceremony_$(Get-Date -Format 'yyyyMMddHHmmss')"
            type = "weekly_resilience"
            initiated_at = (Get-Date).AddMinutes(-15).ToString("o")
            completed_at = (Get-Date).ToString("o")
            duration_seconds = 900
            status = "completed"
            master_directive = @{
                text = "Execute test resilience ceremony"
                priority = "medium"
                resource_allocation = @{
                    cpu_ceiling = 80
                    ram_ceiling = 70
                    time_limit_minutes = 15
                    max_concurrent_packets = 4
                }
                approval_metadata = @{
                    approved_by = "master.civic.orchestrator"
                    approval_timestamp = (Get-Date).AddMinutes(-15).ToString("o")
                    approval_reason = "Test ceremony"
                    override_flags = @()
                }
            }
        }
        signatures = @{
            master = @{
                agent_id = "master.civic.orchestrator"
                key_id = $MasterKey.KeyId
                algorithm = "Ed25519"
                signature = "0x$(Get-Random -Minimum 1000000 -Maximum 9999999)abcdef"
                signed_at = (Get-Date).ToString("o")
                manifest_hash_at_signing = "sha256:$(Get-Random)"
                status = "approved"
                conditions = @()
                metadata = @{
                    conflicts_arbitrated = @()
                    policy_exceptions = @()
                    compliance_notes = "Test manifest"
                }
            }
            assistants = @(
                @{
                    agent_id = "assistant.resilience"
                    domain = "resilience"
                    key_id = $AssistantKey.KeyId
                    algorithm = "Ed25519"
                    signature = "0x$(Get-Random -Minimum 1000000 -Maximum 9999999)bcdefg"
                    signed_at = (Get-Date).AddMinutes(-1).ToString("o")
                    manifest_hash_at_signing = "sha256:$(Get-Random)"
                    execution_summary = @{
                        packets_assigned = 2
                        packets_completed = 2
                        packets_failed = 0
                        total_features = 200
                        anomalies_escalated = 1
                        evidence_packs_produced = 2
                    }
                    escalations = @(
                        @{
                            escalation_id = "test_esc_001"
                            severity = "medium"
                            description = "Test anomaly"
                            escalated_at = (Get-Date).AddMinutes(-5).ToString("o")
                            resolved = $true
                            resolution = "Test resolution"
                        }
                    )
                    metadata = @{
                        domain_context = @{}
                        coordinator_notes = "Test execution"
                    }
                }
            )
            managers = @(
                @{
                    agent_id = "manager.hash.integrity"
                    feature_family = "hash_verification"
                    packet_id = "test_packet_001"
                    key_id = $ManagerKey.KeyId
                    algorithm = "Ed25519"
                    signature = "0x$(Get-Random -Minimum 1000000 -Maximum 9999999)cdefgh"
                    signed_at = (Get-Date).AddMinutes(-5).ToString("o")
                    evidence_pack_hash = "sha256:test_pack_hash_001"
                    execution_summary = @{
                        features_executed = 100
                        features_passed = 98
                        features_anomaly = 1
                        features_failed = 1
                        execution_time_seconds = 120
                        parallel_execution = $true
                        thread_count = 4
                    }
                    deduplication = @{
                        enabled = $true
                        total_evidence_items = 100
                        unique_deltas = 35
                        duplicates_found = 65
                        deduplication_ratio = 65.0
                        storage_savings_bytes = 1048576
                    }
                    anomalies = @(
                        @{
                            feature_id = "test_feature_001"
                            severity = "medium"
                            description = "Test anomaly"
                            evidence_delta_hash = "sha256:test_delta_001"
                            detected_at = (Get-Date).AddMinutes(-5).ToString("o")
                            action_taken = "escalated"
                        }
                    )
                    metadata = @{
                        resource_utilization = @{
                            cpu_peak = 65.0
                            ram_peak = 55.0
                            disk_io_mb = 100
                        }
                        executor_notes = "Test execution"
                    }
                }
            )
            domain_teams = @(
                @{
                    team_id = "domain.civic.infrastructure"
                    domain = "civic_infrastructure"
                    key_id = $DomainKey.KeyId
                    algorithm = "Ed25519"
                    signature = "0x$(Get-Random -Minimum 1000000 -Maximum 9999999)defghi"
                    signed_at = (Get-Date).AddMinutes(-10).ToString("o")
                    features_manifest_hash = "sha256:test_features_001"
                    execution_summary = @{
                        features_executed = 100
                        features_passed = 98
                        features_anomaly = 1
                        features_failed = 1
                        templates_used = @("hash_verification_v1")
                    }
                    feature_results = @(
                        @{
                            feature_id = "test_feature_001"
                            template_family = "hash_verification"
                            parameters = @{
                                config_path = "C:\\Test\\config.json"
                                expected_hash = "sha256:abc123"
                                algorithm = "SHA256"
                            }
                            status = "anomaly"
                            yield = "high"
                            evidence_delta_hash = "sha256:test_delta_001"
                            execution_time_ms = 25
                            signed_at = (Get-Date).AddMinutes(-10).ToString("o")
                            signature = "0x$(Get-Random)efghij"
                        }
                    )
                    metadata = @{
                        domain_context = @{}
                        knowledge_base_version = "test_v1"
                        team_notes = "Test execution"
                    }
                }
            )
        }
        evidence = @{
            packs = @(
                @{
                    pack_id = "test_pack_001"
                    packet_id = "test_packet_001"
                    manager_id = "manager.hash.integrity"
                    pack_hash = "sha256:test_pack_hash_001"
                    created_at = (Get-Date).AddMinutes(-5).ToString("o")
                    manifest_path = "C:\\Test\\Evidence\\test_pack_001.json"
                    deltas = @(
                        @{
                            delta_id = "test_delta_001"
                            delta_hash = "sha256:test_delta_001"
                            size_bytes = 4096
                            compression = "optimal"
                            path = "C:\\Test\\Evidence\\Deltas\\test_delta_001.json"
                            referenced_by = @("test_feature_001")
                        }
                    )
                    feature_references = @(
                        @{
                            feature_id = "test_feature_001"
                            reference_type = "direct"
                            delta_hash = "sha256:test_delta_001"
                            status = "anomaly"
                            yield = "high"
                            timestamp = (Get-Date).AddMinutes(-10).ToString("o")
                        }
                    )
                    integrity = @{
                        verified = $true
                        verified_at = (Get-Date).AddMinutes(-1).ToString("o")
                        verification_method = "both"
                    }
                }
            )
            aggregation_summary = @{
                total_packs = 2
                total_features = 200
                total_deltas = 70
                total_size_bytes = 2097152
                total_size_compressed_bytes = 734003
                compression_ratio = 2.86
                deduplication_savings_bytes = 1048576
            }
        }
        lineage = @{
            chain = @(
                @{
                    from = "domain.civic.infrastructure"
                    to = "manager.hash.integrity"
                    artifact = "feature_results"
                    artifact_hash = "sha256:test_features_001"
                    transferred_at = (Get-Date).AddMinutes(-10).ToString("o")
                    signature_verified = $true
                }
                @{
                    from = "manager.hash.integrity"
                    to = "assistant.resilience"
                    artifact = "evidence_pack"
                    artifact_hash = "sha256:test_pack_hash_001"
                    transferred_at = (Get-Date).AddMinutes(-5).ToString("o")
                    signature_verified = $true
                }
                @{
                    from = "assistant.resilience"
                    to = "master.civic.orchestrator"
                    artifact = "domain_manifest"
                    artifact_hash = "sha256:test_manifest_001"
                    transferred_at = (Get-Date).AddMinutes(-1).ToString("o")
                    signature_verified = $true
                }
            )
            integrity = @{
                complete = $true
                verified = $true
                verification_timestamp = (Get-Date).ToString("o")
                breaks = @()
            }
            traceability = @{
                feature_to_master = @{
                    test_feature_001 = @(
                        "domain.civic.infrastructure",
                        "manager.hash.integrity",
                        "assistant.resilience",
                        "master.civic.orchestrator"
                    )
                }
                decision_points = @()
            }
        }
        metrics = @{
            performance = @{
                total_duration_seconds = 900
                packet_execution_times = @(120, 125)
                average_packet_time = 122.5
                parallel_efficiency = 85.0
                resource_utilization = @{
                    cpu_average = 60.0
                    cpu_peak = 75.0
                    ram_average = 50.0
                    ram_peak = 65.0
                }
            }
            governance = @{
                total_signatures = 4
                signature_verification_success_rate = 100.0
                escalations_raised = 1
                escalations_resolved = 1
                overrides_applied = 0
            }
            quality = @{
                features_passed = 198
                features_anomaly = 1
                features_failed = 1
                anomaly_rate = 0.5
                false_positive_rate = 0.0
                yield_distribution = @{
                    high = 1
                    medium = 5
                    low = 2
                    clean = 192
                }
            }
        }
        audit = @{
            trail_entry_id = "test_audit_001"
            compliance_checkpoints = @(
                @{
                    checkpoint = "All signatures verified"
                    status = "pass"
                    details = "100% signature coverage"
                }
                @{
                    checkpoint = "Evidence integrity verified"
                    status = "pass"
                    details = "All packs verified"
                }
            )
            external_references = @()
        }
        metadata = @{
            schema_version = "1.0.0"
            created_by = "test_framework"
            workspace = $env:COMPUTERNAME
            tags = @("test", "validation")
            notes = "Test manifest for validation"
        }
    } | ConvertTo-Json -Depth 20 | ConvertFrom-Json
    
    Write-Host "SUCCESS: Created test manifest with 4-tier signatures" -ForegroundColor Green
    $TestResults.Passed++
} catch {
    Write-Host "FAILED: $_" -ForegroundColor Red
    $TestResults.Failed++
}

$TestResults.Total++
Write-Host ""

# ============================================================================
# TEST 3: Validate Manifest Signature Chain
# ============================================================================

Write-Host "[TEST 3] Validating manifest signature chain..." -ForegroundColor Yellow

try {
    $ValidationResult = Test-ManifestSignatureChain -Manifest $TestManifest -Verbose:$Detailed
    
    Write-Host "  Validation Status: $(if($ValidationResult.Valid){'VALID'}else{'INVALID'})" -ForegroundColor $(if($ValidationResult.Valid){'Green'}else{'Red'})
    Write-Host "  Verified Signatures: $($ValidationResult.VerifiedSignatures.Count)" -ForegroundColor Cyan
    Write-Host "  Issues: $($ValidationResult.Issues.Count)" -ForegroundColor $(if($ValidationResult.Issues.Count -eq 0){'Green'}else{'Yellow'})
    Write-Host "  Warnings: $($ValidationResult.Warnings.Count)" -ForegroundColor $(if($ValidationResult.Warnings.Count -eq 0){'Green'}else{'Yellow'})
    
    if ($Detailed -and $ValidationResult.Issues.Count -gt 0) {
        Write-Host "  Issues Detected:" -ForegroundColor Yellow
        foreach ($Issue in $ValidationResult.Issues) {
            Write-Host "    - $Issue" -ForegroundColor Yellow
        }
    }
    
    if ($ValidationResult.Valid) {
        Write-Host "SUCCESS: Manifest signature chain validated" -ForegroundColor Green
        $TestResults.Passed++
    } else {
        Write-Host "FAILED: Validation issues detected" -ForegroundColor Red
        $TestResults.Failed++
    }
} catch {
    Write-Host "FAILED: $_" -ForegroundColor Red
    $TestResults.Failed++
}

$TestResults.Total++
Write-Host ""

# ============================================================================
# TEST 4: Extract Feature Lineage
# ============================================================================

Write-Host "[TEST 4] Extracting feature lineage..." -ForegroundColor Yellow

try {
    $Lineage = Get-FeatureLineage -Manifest $TestManifest -FeatureId "test_feature_001"
    
    Write-Host "  Feature Found: $($Lineage.Found)" -ForegroundColor $(if($Lineage.Found){'Green'}else{'Red'})
    Write-Host "  Chain Length: $($Lineage.Chain.Count)" -ForegroundColor Cyan
    
    if ($Detailed -and $Lineage.Found) {
        Write-Host "  Lineage Chain:" -ForegroundColor Cyan
        foreach ($Link in $Lineage.Chain) {
            Write-Host "    [$($Link.Level)] $($Link.AgentId)" -ForegroundColor Gray
        }
    }
    
    if ($Lineage.Found -and $Lineage.Chain.Count -ge 4) {
        Write-Host "SUCCESS: Complete lineage chain extracted (4+ levels)" -ForegroundColor Green
        $TestResults.Passed++
    } else {
        Write-Host "FAILED: Incomplete lineage chain" -ForegroundColor Red
        $TestResults.Failed++
    }
} catch {
    Write-Host "FAILED: $_" -ForegroundColor Red
    $TestResults.Failed++
}

$TestResults.Total++
Write-Host ""

# ============================================================================
# TEST 5: Generate Compliance Report
# ============================================================================

Write-Host "[TEST 5] Generating compliance report..." -ForegroundColor Yellow

try {
    $ReportPath = "$env:TEMP\test_compliance_report.html"
    $ReportResult = New-ComplianceReport -Manifest $TestManifest -OutputPath $ReportPath
    
    if (Test-Path $ReportPath) {
        $ReportSize = (Get-Item $ReportPath).Length
        Write-Host "  Report Generated: $ReportPath" -ForegroundColor Cyan
        Write-Host "  Report Size: $([math]::Round($ReportSize / 1KB, 2)) KB" -ForegroundColor Cyan
        
        if ($ReportSize -gt 5KB) {
            Write-Host "SUCCESS: Compliance report generated" -ForegroundColor Green
            $TestResults.Passed++
        } else {
            Write-Host "FAILED: Report too small (possibly incomplete)" -ForegroundColor Red
            $TestResults.Failed++
        }
    } else {
        Write-Host "FAILED: Report file not created" -ForegroundColor Red
        $TestResults.Failed++
    }
} catch {
    Write-Host "FAILED: $_" -ForegroundColor Red
    $TestResults.Failed++
}

$TestResults.Total++
Write-Host ""

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Test Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Total Tests: $($TestResults.Total)" -ForegroundColor White
Write-Host "Passed: $($TestResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($TestResults.Failed)" -ForegroundColor $(if($TestResults.Failed -eq 0){'Green'}else{'Red'})
Write-Host "Success Rate: $([math]::Round(($TestResults.Passed / $TestResults.Total) * 100, 2))%" -ForegroundColor Cyan
Write-Host ""

if ($TestResults.Failed -eq 0) {
    Write-Host "ALL TESTS PASSED!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "SOME TESTS FAILED" -ForegroundColor Red
    exit 1
}
