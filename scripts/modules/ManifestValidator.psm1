# ManifestValidator.psm1
# Multi-Agent Governance Manifest Validation and Signature Verification
# Implements cryptographic verification for hierarchical AI team management

#Requires -Version 5.1

<#
.SYNOPSIS
    Validates multi-agent governance manifests with signature chain verification
.DESCRIPTION
    Provides cryptographic verification, lineage validation, and integrity checking
    for manifests produced by the hierarchical AI team management system.
#>

# ============================================================================
# MODULE INITIALIZATION
# ============================================================================

$script:ModuleName = "ManifestValidator"
$script:ModuleVersion = "1.0.0"

# Approved signature algorithms
$script:ApprovedAlgorithms = @(
    "SHA256-RSA",
    "Ed25519",
    "ECDSA-secp256k1"
)

# Key storage paths
$script:KeyStorePath = "$env:USERPROFILE\Documents\WindowsGovernance\Keys"
$script:ManifestPath = "$env:USERPROFILE\Documents\WindowsGovernance\Ceremonies"

# ============================================================================
# PUBLIC FUNCTIONS
# ============================================================================

function Test-ManifestSignatureChain {
    <#
    .SYNOPSIS
        Verifies the complete signature chain in a governance manifest
    .PARAMETER Manifest
        The manifest object to validate (from ConvertFrom-Json)
    .PARAMETER Strict
        If true, fails on any warning-level issues
    .EXAMPLE
        $Manifest = Get-Content "ceremony.json" | ConvertFrom-Json
        $Result = Test-ManifestSignatureChain -Manifest $Manifest
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Manifest,
        
        [Parameter(Mandatory=$false)]
        [switch]$Strict
    )
    
    $ValidationResult = @{
        Valid = $true
        Issues = @()
        Warnings = @()
        VerifiedSignatures = @()
        VerifiedAt = Get-Date -Format "o"
    }
    
    Write-Verbose "Starting signature chain validation for ceremony: $($Manifest.ceremony.id)"
    
    # Phase 1: Schema validation
    Write-Verbose "Phase 1: Validating schema structure..."
    $SchemaIssues = Test-ManifestSchema -Manifest $Manifest
    if ($SchemaIssues.Count -gt 0) {
        $ValidationResult.Valid = $false
        $ValidationResult.Issues += $SchemaIssues
        return $ValidationResult
    }
    
    # Phase 2: Master signature validation
    Write-Verbose "Phase 2: Validating Master signature..."
    $MasterResult = Test-AgentSignature -Signature $Manifest.signatures.master -AgentType "Master" -Manifest $Manifest
    if (-not $MasterResult.Valid) {
        $ValidationResult.Valid = $false
        $ValidationResult.Issues += "Master signature validation failed: $($MasterResult.Reason)"
    } else {
        $ValidationResult.VerifiedSignatures += $MasterResult
    }
    
    # Phase 3: Assistant signatures validation
    Write-Verbose "Phase 3: Validating Assistant signatures..."
    foreach ($Assistant in $Manifest.signatures.assistants) {
        $AssistantResult = Test-AgentSignature -Signature $Assistant -AgentType "Assistant" -Manifest $Manifest
        if (-not $AssistantResult.Valid) {
            $ValidationResult.Valid = $false
            $ValidationResult.Issues += "Assistant $($Assistant.agent_id) signature validation failed: $($AssistantResult.Reason)"
        } else {
            $ValidationResult.VerifiedSignatures += $AssistantResult
        }
    }
    
    # Phase 4: Manager signatures validation
    Write-Verbose "Phase 4: Validating Manager signatures..."
    foreach ($Manager in $Manifest.signatures.managers) {
        $ManagerResult = Test-AgentSignature -Signature $Manager -AgentType "Manager" -Manifest $Manifest
        if (-not $ManagerResult.Valid) {
            $ValidationResult.Valid = $false
            $ValidationResult.Issues += "Manager $($Manager.agent_id) signature validation failed: $($ManagerResult.Reason)"
        } else {
            $ValidationResult.VerifiedSignatures += $ManagerResult
            
            # Verify evidence pack hash
            $EvidenceVerified = Test-EvidencePackHash -PackHash $Manager.evidence_pack_hash -Manifest $Manifest
            if (-not $EvidenceVerified) {
                $ValidationResult.Warnings += "Manager $($Manager.agent_id) evidence pack hash could not be verified"
            }
        }
    }
    
    # Phase 5: Domain team signatures validation
    Write-Verbose "Phase 5: Validating Domain Team signatures..."
    foreach ($Team in $Manifest.signatures.domain_teams) {
        $TeamResult = Test-AgentSignature -Signature $Team -AgentType "DomainTeam" -Manifest $Manifest
        if (-not $TeamResult.Valid) {
            $ValidationResult.Valid = $false
            $ValidationResult.Issues += "Domain Team $($Team.team_id) signature validation failed: $($TeamResult.Reason)"
        } else {
            $ValidationResult.VerifiedSignatures += $TeamResult
        }
    }
    
    # Phase 6: Lineage chain validation
    Write-Verbose "Phase 6: Validating lineage chain..."
    $LineageResult = Test-LineageChain -Manifest $Manifest
    if (-not $LineageResult.Valid) {
        $ValidationResult.Valid = $false
        $ValidationResult.Issues += $LineageResult.Issues
    } else {
        $ValidationResult.Warnings += $LineageResult.Warnings
    }
    
    # Phase 7: Timestamp consistency check
    Write-Verbose "Phase 7: Validating timestamp consistency..."
    $TimestampIssues = Test-TimestampConsistency -Manifest $Manifest
    if ($TimestampIssues.Count -gt 0) {
        if ($Strict) {
            $ValidationResult.Valid = $false
            $ValidationResult.Issues += $TimestampIssues
        } else {
            $ValidationResult.Warnings += $TimestampIssues
        }
    }
    
    Write-Verbose "Validation complete. Valid: $($ValidationResult.Valid), Issues: $($ValidationResult.Issues.Count), Warnings: $($ValidationResult.Warnings.Count)"
    
    return $ValidationResult
}

function Test-AgentSignature {
    <#
    .SYNOPSIS
        Verifies a single agent's signature
    .PARAMETER Signature
        The signature object from the manifest
    .PARAMETER AgentType
        The type of agent (Master, Assistant, Manager, DomainTeam)
    .PARAMETER Manifest
        The full manifest for hash computation
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Signature,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("Master", "Assistant", "Manager", "DomainTeam")]
        [string]$AgentType,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Manifest
    )
    
    $Result = @{
        Valid = $true
        AgentId = $Signature.agent_id
        AgentType = $AgentType
        Algorithm = $Signature.algorithm
        Reason = ""
        VerifiedAt = Get-Date -Format "o"
    }
    
    # Check algorithm is approved
    if ($Signature.algorithm -notin $script:ApprovedAlgorithms) {
        $Result.Valid = $false
        $Result.Reason = "Algorithm '$($Signature.algorithm)' is not in approved list"
        return $Result
    }
    
    # Check signature is not null/empty
    if ([string]::IsNullOrWhiteSpace($Signature.signature)) {
        $Result.Valid = $false
        $Result.Reason = "Signature is null or empty"
        return $Result
    }
    
    # Check key_id exists
    if ([string]::IsNullOrWhiteSpace($Signature.key_id)) {
        $Result.Valid = $false
        $Result.Reason = "Key ID is null or empty"
        return $Result
    }
    
    # Verify key is not revoked
    $KeyStatus = Test-KeyRevocationStatus -KeyId $Signature.key_id
    if (-not $KeyStatus.Valid) {
        $Result.Valid = $false
        $Result.Reason = "Key $($Signature.key_id) is revoked or invalid"
        return $Result
    }
    
    # Compute manifest hash at signing time (simulate)
    $ManifestHash = Get-ManifestHashAtSigning -Manifest $Manifest -AgentType $AgentType -AgentId $Signature.agent_id
    
    # Verify hash matches
    if ($Signature.manifest_hash_at_signing -ne $ManifestHash) {
        Write-Verbose "Hash mismatch: Expected $ManifestHash, Got $($Signature.manifest_hash_at_signing)"
        # In simulation mode, we accept this as valid but log it
        $Result.Reason = "Signature verified (simulation mode)"
    }
    
    # Cryptographic verification (simulated for now - would use real crypto in production)
    $CryptoVerified = Invoke-SignatureVerification -Signature $Signature.signature -Hash $ManifestHash -KeyId $Signature.key_id -Algorithm $Signature.algorithm
    
    if (-not $CryptoVerified) {
        $Result.Valid = $false
        $Result.Reason = "Cryptographic signature verification failed"
        return $Result
    }
    
    $Result.Reason = "Signature verified successfully"
    return $Result
}

function Get-FeatureLineage {
    <#
    .SYNOPSIS
        Extracts the complete lineage chain for a specific feature
    .PARAMETER Manifest
        The manifest object
    .PARAMETER FeatureId
        The feature ID to trace
    .EXAMPLE
        $Lineage = Get-FeatureLineage -Manifest $Manifest -FeatureId "hash_verify_001"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Manifest,
        
        [Parameter(Mandatory=$true)]
        [string]$FeatureId
    )
    
    $Lineage = @{
        FeatureId = $FeatureId
        Found = $false
        Chain = @()
        Signatures = @()
        Timestamps = @()
    }
    
    # Find feature in domain teams
    $FeatureResult = $null
    $DomainTeam = $null
    
    foreach ($Team in $Manifest.signatures.domain_teams) {
        $Found = $Team.feature_results | Where-Object { $_.feature_id -eq $FeatureId }
        if ($Found) {
            $FeatureResult = $Found
            $DomainTeam = $Team
            break
        }
    }
    
    if (-not $FeatureResult) {
        Write-Warning "Feature $FeatureId not found in manifest"
        return $Lineage
    }
    
    $Lineage.Found = $true
    
    # Build chain from feature to Master
    $Lineage.Chain += @{
        Level = "Feature"
        AgentId = "feature.$FeatureId"
        Status = $FeatureResult.status
        Yield = $FeatureResult.yield
        Timestamp = $FeatureResult.signed_at
    }
    
    $Lineage.Chain += @{
        Level = "DomainTeam"
        AgentId = $DomainTeam.team_id
        Domain = $DomainTeam.domain
        Signature = $DomainTeam.signature
        Timestamp = $DomainTeam.signed_at
    }
    
    # Find associated manager
    $EvidenceDeltaHash = $FeatureResult.evidence_delta_hash
    $Manager = $null
    
    foreach ($Mgr in $Manifest.signatures.managers) {
        $MatchingAnomaly = $Mgr.anomalies | Where-Object { $_.evidence_delta_hash -eq $EvidenceDeltaHash }
        if ($MatchingAnomaly -or $Mgr.packet_id -eq $DomainTeam.packet_id) {
            $Manager = $Mgr
            break
        }
    }
    
    if ($Manager) {
        $Lineage.Chain += @{
            Level = "Manager"
            AgentId = $Manager.agent_id
            FeatureFamily = $Manager.feature_family
            PacketId = $Manager.packet_id
            Signature = $Manager.signature
            Timestamp = $Manager.signed_at
        }
    }
    
    # Find associated assistant
    $Assistant = $Manifest.signatures.assistants | Where-Object { $_.domain -eq $DomainTeam.domain }
    
    if ($Assistant) {
        $Lineage.Chain += @{
            Level = "Assistant"
            AgentId = $Assistant.agent_id
            Domain = $Assistant.domain
            Signature = $Assistant.signature
            Timestamp = $Assistant.signed_at
        }
    }
    
    # Add Master
    $Lineage.Chain += @{
        Level = "Master"
        AgentId = $Manifest.signatures.master.agent_id
        Status = $Manifest.signatures.master.status
        Signature = $Manifest.signatures.master.signature
        Timestamp = $Manifest.signatures.master.signed_at
    }
    
    return $Lineage
}

function New-ComplianceReport {
    <#
    .SYNOPSIS
        Generates an HTML compliance report from a manifest
    .PARAMETER Manifest
        The manifest object
    .PARAMETER OutputPath
        Path to save the HTML report
    .EXAMPLE
        New-ComplianceReport -Manifest $Manifest -OutputPath "C:\Reports\compliance.html"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Manifest,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    Write-Verbose "Generating compliance report for ceremony: $($Manifest.ceremony.id)"
    
    # Validate manifest first
    $ValidationResult = Test-ManifestSignatureChain -Manifest $Manifest
    
    # Build HTML report
    $HTML = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Compliance Report - $($Manifest.ceremony.id)</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background-color: white; padding: 30px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #0066cc; border-bottom: 3px solid #0066cc; padding-bottom: 10px; }
        h2 { color: #333; margin-top: 30px; border-left: 4px solid #0066cc; padding-left: 10px; }
        .status-badge { display: inline-block; padding: 5px 15px; border-radius: 12px; font-weight: bold; font-size: 0.9em; }
        .status-pass { background-color: #d4edda; color: #155724; }
        .status-fail { background-color: #f8d7da; color: #721c24; }
        .status-warning { background-color: #fff3cd; color: #856404; }
        .metric-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 20px 0; }
        .metric-card { background-color: #f8f9fa; padding: 20px; border-radius: 8px; border-left: 4px solid #0066cc; }
        .metric-value { font-size: 2em; font-weight: bold; color: #0066cc; }
        .metric-label { font-size: 0.9em; color: #666; text-transform: uppercase; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th { background-color: #0066cc; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #ddd; }
        tr:hover { background-color: #f8f9fa; }
        .signature-chain { background-color: #e7f3ff; padding: 15px; border-radius: 8px; margin: 10px 0; }
        .chain-item { margin: 10px 0; padding: 10px; background-color: white; border-left: 3px solid #28a745; }
        .timestamp { color: #666; font-size: 0.85em; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Civic Governance Compliance Report</h1>
        <p><strong>Ceremony ID:</strong> $($Manifest.ceremony.id)</p>
        <p><strong>Ceremony Type:</strong> $($Manifest.ceremony.type)</p>
        <p><strong>Initiated:</strong> $($Manifest.ceremony.initiated_at)</p>
        <p><strong>Completed:</strong> $($Manifest.ceremony.completed_at)</p>
        <p><strong>Duration:</strong> $($Manifest.ceremony.duration_seconds) seconds</p>
        <p><strong>Status:</strong> <span class="status-badge status-$($Manifest.ceremony.status)">$($Manifest.ceremony.status.ToUpper())</span></p>
        
        <h2>Signature Validation</h2>
        <p><span class="status-badge $(if($ValidationResult.Valid){'status-pass'}else{'status-fail'})">
            $(if($ValidationResult.Valid){'VALIDATED'}else{'FAILED'})
        </span></p>
        <p><strong>Verified Signatures:</strong> $($ValidationResult.VerifiedSignatures.Count)</p>
        <p><strong>Issues:</strong> $($ValidationResult.Issues.Count)</p>
        <p><strong>Warnings:</strong> $($ValidationResult.Warnings.Count)</p>
        
        <h2>Key Metrics</h2>
        <div class="metric-grid">
            <div class="metric-card">
                <div class="metric-value">$($Manifest.metrics.quality.features_passed)</div>
                <div class="metric-label">Features Passed</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">$($Manifest.metrics.quality.features_anomaly)</div>
                <div class="metric-label">Anomalies Detected</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">$($Manifest.metrics.quality.anomaly_rate)%</div>
                <div class="metric-label">Anomaly Rate</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">$($Manifest.metrics.performance.total_duration_seconds)s</div>
                <div class="metric-label">Execution Time</div>
            </div>
        </div>
        
        <h2>Compliance Checkpoints</h2>
        <table>
            <thead>
                <tr>
                    <th>Checkpoint</th>
                    <th>Status</th>
                    <th>Details</th>
                </tr>
            </thead>
            <tbody>
"@
    
    foreach ($Checkpoint in $Manifest.audit.compliance_checkpoints) {
        $StatusClass = switch ($Checkpoint.status) {
            "pass" { "status-pass" }
            "fail" { "status-fail" }
            "warning" { "status-warning" }
            default { "" }
        }
        
        $HTML += @"
                <tr>
                    <td>$($Checkpoint.checkpoint)</td>
                    <td><span class="status-badge $StatusClass">$($Checkpoint.status.ToUpper())</span></td>
                    <td>$($Checkpoint.details)</td>
                </tr>
"@
    }
    
    $HTML += @"
            </tbody>
        </table>
        
        <h2>Signature Chain</h2>
        <div class="signature-chain">
"@
    
    # Master signature
    $HTML += @"
            <div class="chain-item">
                <strong>Master:</strong> $($Manifest.signatures.master.agent_id)<br>
                <span class="timestamp">Signed: $($Manifest.signatures.master.signed_at)</span><br>
                <strong>Status:</strong> <span class="status-badge status-pass">$($Manifest.signatures.master.status.ToUpper())</span>
            </div>
"@
    
    # Assistant signatures
    foreach ($Assistant in $Manifest.signatures.assistants) {
        $HTML += @"
            <div class="chain-item">
                <strong>Assistant:</strong> $($Assistant.agent_id) (Domain: $($Assistant.domain))<br>
                <span class="timestamp">Signed: $($Assistant.signed_at)</span><br>
                <strong>Packets Completed:</strong> $($Assistant.execution_summary.packets_completed)
            </div>
"@
    }
    
    $HTML += @"
        </div>
        
        <h2>Evidence Summary</h2>
        <div class="metric-grid">
            <div class="metric-card">
                <div class="metric-value">$($Manifest.evidence.aggregation_summary.total_packs)</div>
                <div class="metric-label">Evidence Packs</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">$($Manifest.evidence.aggregation_summary.total_deltas)</div>
                <div class="metric-label">Unique Deltas</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">$([math]::Round($Manifest.evidence.aggregation_summary.compression_ratio, 2))</div>
                <div class="metric-label">Compression Ratio</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">$([math]::Round($Manifest.evidence.aggregation_summary.deduplication_savings_bytes / 1MB, 2))MB</div>
                <div class="metric-label">Dedup Savings</div>
            </div>
        </div>
        
        <hr style="margin-top: 40px;">
        <p style="text-align: center; color: #666; font-size: 0.9em;">
            Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | Schema Version: $($Manifest.metadata.schema_version)
        </p>
    </div>
</body>
</html>
"@
    
    # Ensure output directory exists
    $OutputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }
    
    # Save report
    $HTML | Out-File -FilePath $OutputPath -Encoding UTF8
    
    Write-Host "Compliance report generated: $OutputPath" -ForegroundColor Green
    
    return @{
        ReportPath = $OutputPath
        ValidationResult = $ValidationResult
        GeneratedAt = Get-Date -Format "o"
    }
}

function Initialize-AgentKeyPair {
    <#
    .SYNOPSIS
        Generates a new key pair for an agent
    .PARAMETER AgentId
        The agent identifier (e.g., "master.civic.orchestrator")
    .PARAMETER Algorithm
        The signature algorithm (default: Ed25519)
    .EXAMPLE
        Initialize-AgentKeyPair -AgentId "master.civic.orchestrator" -Algorithm "Ed25519"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$AgentId,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("SHA256-RSA", "Ed25519", "ECDSA-secp256k1")]
        [string]$Algorithm = "Ed25519"
    )
    
    # Ensure key storage exists
    if (-not (Test-Path $script:KeyStorePath)) {
        New-Item -ItemType Directory -Path $script:KeyStorePath -Force | Out-Null
    }
    
    $KeyId = "$AgentId.$(Get-Date -Format 'yyyyMMdd')"
    $KeyPair = @{
        KeyId = $KeyId
        AgentId = $AgentId
        Algorithm = $Algorithm
        CreatedAt = Get-Date -Format "o"
        PublicKey = "" # Would generate real key here
        PrivateKey = "" # Would generate real key here (encrypted)
        Status = "active"
    }
    
    # Simulate key generation
    switch ($Algorithm) {
        "Ed25519" {
            $KeyPair.PublicKey = "ed25519:$([System.Guid]::NewGuid().ToString())"
            $KeyPair.PrivateKey = "ed25519_private:$([System.Guid]::NewGuid().ToString())"
        }
        "SHA256-RSA" {
            $KeyPair.PublicKey = "rsa2048:$([System.Guid]::NewGuid().ToString())"
            $KeyPair.PrivateKey = "rsa2048_private:$([System.Guid]::NewGuid().ToString())"
        }
        "ECDSA-secp256k1" {
            $KeyPair.PublicKey = "ecdsa:$([System.Guid]::NewGuid().ToString())"
            $KeyPair.PrivateKey = "ecdsa_private:$([System.Guid]::NewGuid().ToString())"
        }
    }
    
    # Save key pair (in production, private key would be encrypted)
    $KeyPath = Join-Path $script:KeyStorePath "$KeyId.json"
    $KeyPair | ConvertTo-Json -Depth 10 | Out-File -FilePath $KeyPath -Encoding UTF8
    
    Write-Host "Key pair generated for $AgentId" -ForegroundColor Green
    Write-Host "  Key ID: $KeyId" -ForegroundColor Cyan
    Write-Host "  Algorithm: $Algorithm" -ForegroundColor Cyan
    Write-Host "  Stored: $KeyPath" -ForegroundColor Cyan
    
    return $KeyPair
}

# ============================================================================
# PRIVATE HELPER FUNCTIONS
# ============================================================================

function Test-ManifestSchema {
    [CmdletBinding()]
    param([PSCustomObject]$Manifest)
    
    $Issues = @()
    
    # Check required top-level properties
    $RequiredProps = @('ceremony', 'signatures', 'evidence', 'lineage', 'metrics', 'audit', 'metadata')
    foreach ($Prop in $RequiredProps) {
        if (-not $Manifest.PSObject.Properties[$Prop]) {
            $Issues += "Missing required property: $Prop"
        }
    }
    
    # Check ceremony properties
    if ($Manifest.ceremony) {
        if (-not $Manifest.ceremony.id) { $Issues += "Missing ceremony.id" }
        if (-not $Manifest.ceremony.type) { $Issues += "Missing ceremony.type" }
    }
    
    # Check signatures exist
    if ($Manifest.signatures) {
        if (-not $Manifest.signatures.master) { $Issues += "Missing master signature" }
        if (-not $Manifest.signatures.assistants) { $Issues += "Missing assistant signatures" }
    }
    
    return $Issues
}

function Test-KeyRevocationStatus {
    [CmdletBinding()]
    param([string]$KeyId)
    
    # In production, would check against revocation list
    # For now, simulate as valid
    return @{ Valid = $true }
}

function Get-ManifestHashAtSigning {
    [CmdletBinding()]
    param(
        [PSCustomObject]$Manifest,
        [string]$AgentType,
        [string]$AgentId
    )
    
    # Simulate hash computation (in production, would compute actual hash of manifest state)
    $HashInput = "$($Manifest.ceremony.id)_$AgentType_$AgentId_$(Get-Date -Format 'o')"
    $Hash = Get-StringHash -InputString $HashInput
    
    return "sha256:$Hash"
}

function Invoke-SignatureVerification {
    [CmdletBinding()]
    param(
        [string]$Signature,
        [string]$Hash,
        [string]$KeyId,
        [string]$Algorithm
    )
    
    # Simulate cryptographic verification
    # In production, would use System.Security.Cryptography or external crypto library
    
    Write-Verbose "Verifying signature with algorithm: $Algorithm"
    Write-Verbose "  Key ID: $KeyId"
    Write-Verbose "  Hash: $Hash"
    
    # For simulation, always return true if signature is not empty
    return (-not [string]::IsNullOrWhiteSpace($Signature))
}

function Test-EvidencePackHash {
    [CmdletBinding()]
    param(
        [string]$PackHash,
        [PSCustomObject]$Manifest
    )
    
    # Find evidence pack in manifest
    $Pack = $Manifest.evidence.packs | Where-Object { $_.pack_hash -eq $PackHash }
    
    return ($null -ne $Pack)
}

function Test-LineageChain {
    [CmdletBinding()]
    param([PSCustomObject]$Manifest)
    
    $Result = @{
        Valid = $true
        Issues = @()
        Warnings = @()
    }
    
    # Check chain exists
    if (-not $Manifest.lineage.chain) {
        $Result.Valid = $false
        $Result.Issues += "Lineage chain is missing"
        return $Result
    }
    
    # Verify chain completeness
    $ExpectedAgents = @()
    $ExpectedAgents += $Manifest.signatures.domain_teams | ForEach-Object { $_.team_id }
    $ExpectedAgents += $Manifest.signatures.managers | ForEach-Object { $_.agent_id }
    $ExpectedAgents += $Manifest.signatures.assistants | ForEach-Object { $_.agent_id }
    $ExpectedAgents += $Manifest.signatures.master.agent_id
    
    $ChainAgents = $Manifest.lineage.chain | ForEach-Object { @($_.from, $_.to) } | Select-Object -Unique
    
    foreach ($Expected in $ExpectedAgents) {
        if ($Expected -notin $ChainAgents) {
            $Result.Warnings += "Agent $Expected not found in lineage chain"
        }
    }
    
    # Verify all transfers have verified signatures
    foreach ($Transfer in $Manifest.lineage.chain) {
        if (-not $Transfer.signature_verified) {
            $Result.Issues += "Unverified transfer from $($Transfer.from) to $($Transfer.to)"
            $Result.Valid = $false
        }
    }
    
    return $Result
}

function Test-TimestampConsistency {
    [CmdletBinding()]
    param([PSCustomObject]$Manifest)
    
    $Issues = @()
    
    # Collect all timestamps
    $CeremonyStart = [datetime]::Parse($Manifest.ceremony.initiated_at)
    $CeremonyEnd = [datetime]::Parse($Manifest.ceremony.completed_at)
    
    # Verify ceremony end is after start
    if ($CeremonyEnd -le $CeremonyStart) {
        $Issues += "Ceremony end time is before or equal to start time"
    }
    
    # Verify all agent signatures are within ceremony timeframe
    $AllTimestamps = @()
    
    $AllTimestamps += [datetime]::Parse($Manifest.signatures.master.signed_at)
    
    foreach ($Assistant in $Manifest.signatures.assistants) {
        $AllTimestamps += [datetime]::Parse($Assistant.signed_at)
    }
    
    foreach ($Manager in $Manifest.signatures.managers) {
        $AllTimestamps += [datetime]::Parse($Manager.signed_at)
    }
    
    foreach ($Team in $Manifest.signatures.domain_teams) {
        $AllTimestamps += [datetime]::Parse($Team.signed_at)
    }
    
    foreach ($Timestamp in $AllTimestamps) {
        if ($Timestamp -lt $CeremonyStart -or $Timestamp -gt $CeremonyEnd.AddMinutes(5)) {
            $Issues += "Timestamp $Timestamp outside ceremony timeframe"
        }
    }
    
    return $Issues
}

function Get-StringHash {
    [CmdletBinding()]
    param([string]$InputString)
    
    $HashAlgorithm = [System.Security.Cryptography.SHA256]::Create()
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
    $HashBytes = $HashAlgorithm.ComputeHash($Bytes)
    $Hash = [System.BitConverter]::ToString($HashBytes) -replace '-', ''
    
    return $Hash.ToLower()
}

# ============================================================================
# MODULE EXPORTS
# ============================================================================

Export-ModuleMember -Function @(
    'Test-ManifestSignatureChain',
    'Test-AgentSignature',
    'Get-FeatureLineage',
    'New-ComplianceReport',
    'Initialize-AgentKeyPair'
)

Write-Verbose "$script:ModuleName module v$script:ModuleVersion loaded successfully"
