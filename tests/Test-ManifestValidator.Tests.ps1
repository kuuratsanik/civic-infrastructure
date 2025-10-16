# Test-ManifestValidator.Tests.ps1
# Pester tests for ManifestValidator module

BeforeAll {
    # Import the module
    $ModulePath = Join-Path $PSScriptRoot "..\scripts\modules\ManifestValidator.psm1"
    Import-Module $ModulePath -Force
    
    # Create test directory
    $TestRoot = Join-Path $env:TEMP "ManifestValidatorTests_$(Get-Date -Format 'yyyyMMddHHmmss')"
    New-Item -Path $TestRoot -ItemType Directory -Force | Out-Null
    
    # Sample valid manifest structure
    $script:ValidManifest = @{
        version = "1.0.0"
        ceremony = @{
            id = "ceremony_test_001"
            type = "weekly_resilience"
            initiated_at = "2025-10-14T10:00:00Z"
            completed_at = "2025-10-14T10:15:00Z"
            duration_seconds = 900
            status = "completed"
        }
        signatures = @{
            master = @{
                agent_id = "master.civic.orchestrator"
                key_id = "test_master_key"
                algorithm = "SHA256-RSA"
                signature = "test_signature_master"
                signed_at = "2025-10-14T10:15:00Z"
                manifest_hash_at_signing = "abc123"
                status = "approved"
            }
            assistants = @(
                @{
                    agent_id = "assistant.resilience"
                    domain = "resilience"
                    key_id = "test_assistant_key"
                    algorithm = "SHA256-RSA"
                    signature = "test_signature_assistant"
                    signed_at = "2025-10-14T10:12:00Z"
                    manifest_hash_at_signing = "def456"
                    execution_summary = @{
                        packets_assigned = 2
                        packets_completed = 2
                        packets_failed = 0
                        total_features = 200
                    }
                    escalations = @()
                }
            )
            managers = @(
                @{
                    agent_id = "manager.hash.integrity"
                    feature_family = "hash_verification"
                    packet_id = "packet_001"
                    key_id = "test_manager_key"
                    algorithm = "SHA256-RSA"
                    signature = "test_signature_manager"
                    signed_at = "2025-10-14T10:08:00Z"
                    evidence_pack_hash = "sha256:pack001"
                    execution_summary = @{
                        features_executed = 100
                        features_passed = 98
                        features_anomaly = 1
                        features_failed = 1
                    }
                    anomalies = @()
                }
            )
            domain_teams = @(
                @{
                    team_id = "domain.civic.infrastructure"
                    domain = "civic_infrastructure"
                    key_id = "test_domain_key"
                    algorithm = "SHA256-RSA"
                    signature = "test_signature_domain"
                    signed_at = "2025-10-14T10:05:00Z"
                    features_manifest_hash = "sha256:features001"
                    execution_summary = @{
                        features_executed = 75
                        features_passed = 73
                        features_anomaly = 1
                        features_failed = 1
                    }
                    feature_results = @(
                        @{
                            feature_id = "hash_001"
                            template_family = "hash_verification"
                            status = "pass"
                            yield = "clean"
                            evidence_delta_hash = "sha256:delta001"
                            execution_time_ms = 23
                        }
                    )
                }
            )
        }
        evidence = @{
            packs = @(
                @{
                    pack_id = "pack_001"
                    packet_id = "packet_001"
                    manager_id = "manager.hash.integrity"
                    pack_hash = "sha256:pack001"
                    created_at = "2025-10-14T10:08:00Z"
                    deltas = @(
                        @{
                            delta_id = "delta_001"
                            delta_hash = "sha256:delta001"
                            size_bytes = 4096
                        }
                    )
                    integrity = @{
                        verified = $true
                        verified_at = "2025-10-14T10:08:30Z"
                    }
                }
            )
        }
        lineage = @{
            chain = @(
                @{
                    from = "domain.civic.infrastructure"
                    to = "manager.hash.integrity"
                    artifact = "feature_results_bundle"
                    artifact_hash = "sha256:features001"
                    transferred_at = "2025-10-14T10:05:30Z"
                    signature_verified = $true
                },
                @{
                    from = "manager.hash.integrity"
                    to = "assistant.resilience"
                    artifact = "evidence_pack_001"
                    artifact_hash = "sha256:pack001"
                    transferred_at = "2025-10-14T10:08:30Z"
                    signature_verified = $true
                },
                @{
                    from = "assistant.resilience"
                    to = "master.civic.orchestrator"
                    artifact = "domain_manifest"
                    artifact_hash = "sha256:manifest001"
                    transferred_at = "2025-10-14T10:12:30Z"
                    signature_verified = $true
                }
            )
            integrity = @{
                complete = $true
                verified = $true
            }
        }
        metrics = @{
            performance = @{
                total_duration_seconds = 900
            }
            governance = @{
                total_signatures = 4
                signature_verification_success_rate = 100.0
            }
        }
    }
}

AfterAll {
    # Cleanup
    if (Test-Path $TestRoot) {
        Remove-Item -Path $TestRoot -Recurse -Force
    }
}

Describe "Import-GovernanceManifest" {
    It "Should import valid JSON manifest" {
        $JsonPath = Join-Path $TestRoot "valid_manifest.json"
        $ValidManifest | ConvertTo-Json -Depth 10 | Set-Content $JsonPath
        
        $Result = Import-GovernanceManifest -ManifestPath $JsonPath
        
        $Result | Should -Not -BeNullOrEmpty
        $Result.ceremony.id | Should -Be "ceremony_test_001"
    }
    
    It "Should fail gracefully with invalid JSON" {
        $JsonPath = Join-Path $TestRoot "invalid_manifest.json"
        "{ invalid json }" | Set-Content $JsonPath
        
        $Result = Import-GovernanceManifest -ManifestPath $JsonPath
        
        $Result | Should -BeNullOrEmpty
    }
    
    It "Should fail gracefully with missing file" {
        $JsonPath = Join-Path $TestRoot "nonexistent.json"
        
        $Result = Import-GovernanceManifest -ManifestPath $JsonPath
        
        $Result | Should -BeNullOrEmpty
    }
}

Describe "Test-ManifestSchema" {
    It "Should validate complete manifest structure" {
        $Result = Test-ManifestSchema -Manifest $ValidManifest
        
        $Result.Valid | Should -Be $true
        $Result.Issues | Should -BeNullOrEmpty
    }
    
    It "Should detect missing ceremony section" {
        $InvalidManifest = $ValidManifest.Clone()
        $InvalidManifest.Remove('ceremony')
        
        $Result = Test-ManifestSchema -Manifest $InvalidManifest
        
        $Result.Valid | Should -Be $false
        $Result.Issues | Should -Contain "Missing required field: ceremony"
    }
    
    It "Should detect missing signatures section" {
        $InvalidManifest = $ValidManifest.Clone()
        $InvalidManifest.Remove('signatures')
        
        $Result = Test-ManifestSchema -Manifest $InvalidManifest
        
        $Result.Valid | Should -Be $false
        $Result.Issues | Should -Contain "Missing required field: signatures"
    }
    
    It "Should detect missing master signature" {
        $InvalidManifest = $ValidManifest.Clone()
        $InvalidManifest.signatures.Remove('master')
        
        $Result = Test-ManifestSchema -Manifest $InvalidManifest
        
        $Result.Valid | Should -Be $false
        $Result.Issues -match "master signature" | Should -Not -BeNullOrEmpty
    }
    
    It "Should validate with minimal required fields" {
        $MinimalManifest = @{
            version = "1.0.0"
            ceremony = @{
                id = "test"
                type = "weekly_resilience"
            }
            signatures = @{
                master = @{
                    agent_id = "master"
                    signature = "sig"
                }
                assistants = @()
                managers = @()
                domain_teams = @()
            }
            lineage = @{
                chain = @()
                integrity = @{ complete = $true }
            }
        }
        
        $Result = Test-ManifestSchema -Manifest $MinimalManifest
        
        $Result.Valid | Should -Be $true
    }
}

Describe "Test-SignatureChain" {
    It "Should validate complete signature chain" {
        $Result = Test-SignatureChain -Manifest $ValidManifest
        
        $Result.Valid | Should -Be $true
        $Result.VerifiedSignatures | Should -Be 4
        $Result.Issues | Should -BeNullOrEmpty
    }
    
    It "Should detect missing domain team signature" {
        $InvalidManifest = $ValidManifest.Clone()
        $InvalidManifest.signatures.domain_teams = @()
        
        $Result = Test-SignatureChain -Manifest $InvalidManifest
        
        $Result.Valid | Should -Be $false
        $Result.Issues -match "domain team" | Should -Not -BeNullOrEmpty
    }
    
    It "Should validate timestamp ordering" {
        # Valid: Domain (10:05) -> Manager (10:08) -> Assistant (10:12) -> Master (10:15)
        $Result = Test-SignatureChain -Manifest $ValidManifest
        
        $Result.Valid | Should -Be $true
        $Result.TimestampOrderValid | Should -Be $true
    }
    
    It "Should detect timestamp ordering violations" {
        $InvalidManifest = $ValidManifest.Clone()
        # Make Master sign before Assistant (invalid)
        $InvalidManifest.signatures.master.signed_at = "2025-10-14T10:10:00Z"
        
        $Result = Test-SignatureChain -Manifest $InvalidManifest
        
        $Result.Valid | Should -Be $false
        $Result.TimestampOrderValid | Should -Be $false
    }
    
    It "Should count all signature tiers" {
        $Result = Test-SignatureChain -Manifest $ValidManifest
        
        $Result.VerifiedSignatures | Should -Be 4  # Master + 1 Assistant + 1 Manager + 1 Domain
    }
}

Describe "Test-LineageChain" {
    It "Should validate complete lineage chain" {
        $Result = Test-LineageChain -Manifest $ValidManifest
        
        $Result.Valid | Should -Be $true
        $Result.ChainLength | Should -Be 3
        $Result.Issues | Should -BeNullOrEmpty
    }
    
    It "Should detect broken lineage chain" {
        $InvalidManifest = $ValidManifest.Clone()
        $InvalidManifest.lineage.chain[1].signature_verified = $false
        
        $Result = Test-LineageChain -Manifest $InvalidManifest
        
        $Result.Valid | Should -Be $false
        $Result.Issues -match "not verified" | Should -Not -BeNullOrEmpty
    }
    
    It "Should detect incomplete lineage chain" {
        $InvalidManifest = $ValidManifest.Clone()
        $InvalidManifest.lineage.integrity.complete = $false
        
        $Result = Test-LineageChain -Manifest $InvalidManifest
        
        $Result.Valid | Should -Be $false
        $Result.Issues -match "incomplete" | Should -Not -BeNullOrEmpty
    }
    
    It "Should validate artifact hash consistency" {
        $Result = Test-LineageChain -Manifest $ValidManifest
        
        $Result.Valid | Should -Be $true
        $Result.HashConsistencyValid | Should -Be $true
    }
    
    It "Should detect missing artifact hashes" {
        $InvalidManifest = $ValidManifest.Clone()
        $InvalidManifest.lineage.chain[0].artifact_hash = ""
        
        $Result = Test-LineageChain -Manifest $InvalidManifest
        
        $Result.Valid | Should -Be $false
    }
}

Describe "Test-EvidencePackIntegrity" {
    It "Should validate evidence pack integrity" {
        $Result = Test-EvidencePackIntegrity -Manifest $ValidManifest
        
        $Result.Valid | Should -Be $true
        $Result.VerifiedPacks | Should -Be 1
        $Result.Issues | Should -BeNullOrEmpty
    }
    
    It "Should detect unverified evidence pack" {
        $InvalidManifest = $ValidManifest.Clone()
        $InvalidManifest.evidence.packs[0].integrity.verified = $false
        
        $Result = Test-EvidencePackIntegrity -Manifest $InvalidManifest
        
        $Result.Valid | Should -Be $false
        $Result.Issues -match "not verified" | Should -Not -BeNullOrEmpty
    }
    
    It "Should validate pack hash matches manager signature" {
        $Result = Test-EvidencePackIntegrity -Manifest $ValidManifest
        
        $Result.Valid | Should -Be $true
        $Result.HashConsistencyValid | Should -Be $true
    }
    
    It "Should detect pack hash mismatch" {
        $InvalidManifest = $ValidManifest.Clone()
        $InvalidManifest.evidence.packs[0].pack_hash = "sha256:wrong_hash"
        
        $Result = Test-EvidencePackIntegrity -Manifest $InvalidManifest
        
        $Result.Valid | Should -Be $false
        $Result.HashConsistencyValid | Should -Be $false
    }
    
    It "Should handle manifests with no evidence packs" {
        $ManifestNoEvidence = $ValidManifest.Clone()
        $ManifestNoEvidence.evidence.packs = @()
        
        $Result = Test-EvidencePackIntegrity -Manifest $ManifestNoEvidence
        
        $Result.Valid | Should -Be $true
        $Result.VerifiedPacks | Should -Be 0
    }
}

Describe "Get-FeatureLineage" {
    It "Should trace feature through complete chain" {
        $Result = Get-FeatureLineage -Manifest $ValidManifest -FeatureId "hash_001"
        
        $Result | Should -Not -BeNullOrEmpty
        $Result.FeatureId | Should -Be "hash_001"
        $Result.Chain.Count | Should -BeGreaterThan 0
    }
    
    It "Should include all agent tiers in chain" {
        $Result = Get-FeatureLineage -Manifest $ValidManifest -FeatureId "hash_001"
        
        $Result.Chain.agent_id | Should -Contain "domain.civic.infrastructure"
        $Result.Chain.agent_id | Should -Contain "manager.hash.integrity"
        $Result.Chain.agent_id | Should -Contain "assistant.resilience"
        $Result.Chain.agent_id | Should -Contain "master.civic.orchestrator"
    }
    
    It "Should return null for non-existent feature" {
        $Result = Get-FeatureLineage -Manifest $ValidManifest -FeatureId "nonexistent_feature"
        
        $Result | Should -BeNullOrEmpty
    }
    
    It "Should include evidence delta hash" {
        $Result = Get-FeatureLineage -Manifest $ValidManifest -FeatureId "hash_001"
        
        $Result.EvidenceDeltaHash | Should -Be "sha256:delta001"
    }
}

Describe "New-ComplianceReport" {
    It "Should generate HTML compliance report" {
        $ReportPath = Join-Path $TestRoot "compliance_report.html"
        
        $Result = New-ComplianceReport -Manifest $ValidManifest -OutputPath $ReportPath
        
        $Result | Should -Be $true
        Test-Path $ReportPath | Should -Be $true
    }
    
    It "Should include ceremony information in report" {
        $ReportPath = Join-Path $TestRoot "compliance_report2.html"
        New-ComplianceReport -Manifest $ValidManifest -OutputPath $ReportPath
        
        $Content = Get-Content $ReportPath -Raw
        
        $Content | Should -Match "ceremony_test_001"
        $Content | Should -Match "weekly_resilience"
    }
    
    It "Should include signature verification status" {
        $ReportPath = Join-Path $TestRoot "compliance_report3.html"
        New-ComplianceReport -Manifest $ValidManifest -OutputPath $ReportPath
        
        $Content = Get-Content $ReportPath -Raw
        
        $Content | Should -Match "Signature Chain"
        $Content | Should -Match "4.*signatures"
    }
    
    It "Should include lineage chain visualization" {
        $ReportPath = Join-Path $TestRoot "compliance_report4.html"
        New-ComplianceReport -Manifest $ValidManifest -OutputPath $ReportPath
        
        $Content = Get-Content $ReportPath -Raw
        
        $Content | Should -Match "Lineage Chain"
        $Content | Should -Match "domain.civic.infrastructure"
    }
    
    It "Should handle output to non-existent directory" {
        $ReportPath = Join-Path $TestRoot "subdir\compliance_report.html"
        
        $Result = New-ComplianceReport -Manifest $ValidManifest -OutputPath $ReportPath
        
        $Result | Should -Be $true
        Test-Path $ReportPath | Should -Be $true
    }
}

Describe "Export-ManifestSummary" {
    It "Should export manifest summary to JSON" {
        $SummaryPath = Join-Path $TestRoot "summary.json"
        
        $Result = Export-ManifestSummary -Manifest $ValidManifest -OutputPath $SummaryPath
        
        $Result | Should -Be $true
        Test-Path $SummaryPath | Should -Be $true
    }
    
    It "Should include key metrics in summary" {
        $SummaryPath = Join-Path $TestRoot "summary2.json"
        Export-ManifestSummary -Manifest $ValidManifest -OutputPath $SummaryPath
        
        $Summary = Get-Content $SummaryPath | ConvertFrom-Json
        
        $Summary.ceremony_id | Should -Be "ceremony_test_001"
        $Summary.total_signatures | Should -Be 4
        $Summary.total_features | Should -BeGreaterThan 0
    }
    
    It "Should include validation results in summary" {
        $SummaryPath = Join-Path $TestRoot "summary3.json"
        Export-ManifestSummary -Manifest $ValidManifest -OutputPath $SummaryPath
        
        $Summary = Get-Content $SummaryPath | ConvertFrom-Json
        
        $Summary.validation | Should -Not -BeNullOrEmpty
        $Summary.validation.schema_valid | Should -Be $true
    }
}

Describe "PowerShell 5.1 Compatibility" {
    It "Should work without -AsHashtable parameter" {
        # This test ensures module works with PowerShell 5.1
        $JsonPath = Join-Path $TestRoot "compat_test.json"
        $ValidManifest | ConvertTo-Json -Depth 10 | Set-Content $JsonPath
        
        $Result = Import-GovernanceManifest -ManifestPath $JsonPath
        
        $Result | Should -Not -BeNullOrEmpty
    }
    
    It "Should handle PSCustomObject to Hashtable conversion" {
        $PsObject = [PSCustomObject]@{
            key1 = "value1"
            key2 = "value2"
        }
        
        # Module should handle this internally
        $Result = Test-ManifestSchema -Manifest @{ 
            version = "1.0.0"
            ceremony = $PsObject
            signatures = @{ master = @{ agent_id = "test"; signature = "sig" }; assistants = @(); managers = @(); domain_teams = @() }
            lineage = @{ chain = @(); integrity = @{ complete = $true } }
        }
        
        # Should not throw error
        $Result | Should -Not -BeNullOrEmpty
    }
}

Describe "Integration Tests" {
    It "Should validate complete real-world ceremony manifest" {
        $JsonPath = Join-Path $TestRoot "ceremony_integration.json"
        $ValidManifest | ConvertTo-Json -Depth 10 | Set-Content $JsonPath
        
        # Full validation workflow
        $Manifest = Import-GovernanceManifest -ManifestPath $JsonPath
        $SchemaResult = Test-ManifestSchema -Manifest $Manifest
        $SignatureResult = Test-SignatureChain -Manifest $Manifest
        $LineageResult = Test-LineageChain -Manifest $Manifest
        $EvidenceResult = Test-EvidencePackIntegrity -Manifest $Manifest
        
        $SchemaResult.Valid | Should -Be $true
        $SignatureResult.Valid | Should -Be $true
        $LineageResult.Valid | Should -Be $true
        $EvidenceResult.Valid | Should -Be $true
    }
    
    It "Should generate compliance report for valid ceremony" {
        $ReportPath = Join-Path $TestRoot "integration_report.html"
        
        $Result = New-ComplianceReport -Manifest $ValidManifest -OutputPath $ReportPath
        
        $Result | Should -Be $true
        
        $Content = Get-Content $ReportPath -Raw
        $Content.Length | Should -BeGreaterThan 1000  # Substantial report
    }
}
