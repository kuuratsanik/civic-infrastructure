<#
.SYNOPSIS
    Agent Mandate Validator Module

.DESCRIPTION
    Validates agent role manifests against the governance schema.
    Ensures all mandates meet sovereignty, audit, and compliance requirements.

.NOTES
    Version: 1.0.0
    Part of: Multi-Agent Intelligence Framework
    Requires: PowerShell 5.1+, powershell-yaml module
#>

# Import YAML parser (install if missing)
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
  Write-Warning "Installing powershell-yaml module for YAML parsing..."
  Install-Module -Name powershell-yaml -Force -Scope CurrentUser
}
Import-Module powershell-yaml

<#
.SYNOPSIS
    Tests if an agent manifest file is valid against the schema.

.PARAMETER ManifestPath
    Path to the agent manifest YAML file.

.PARAMETER SchemaPath
    Path to the schema YAML file. Defaults to council/schemas/agent-mandate.schema.yaml

.PARAMETER Strict
    If set, treats warnings as errors.

.EXAMPLE
    Test-AgentManifest -ManifestPath "council/mandates/commerce-supplier-verifier.yaml"

.EXAMPLE
    Test-AgentManifest -ManifestPath $path -Strict
#>
function Test-AgentManifest {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$ManifestPath,

    [Parameter(Mandatory = $false)]
    [string]$SchemaPath = "$PSScriptRoot\..\..\council\schemas\agent-mandate.schema.yaml",

    [switch]$Strict
  )

  $errors = @()
  $warnings = @()

  # Load manifest
  if (-not (Test-Path $ManifestPath)) {
    throw "Manifest not found: $ManifestPath"
  }

  try {
    $manifestContent = Get-Content -Path $ManifestPath -Raw
    $manifest = ConvertFrom-Yaml $manifestContent
  } catch {
    throw "Failed to parse manifest YAML: $_"
  }

  # Load schema
  if (-not (Test-Path $SchemaPath)) {
    throw "Schema not found: $SchemaPath"
  }

  try {
    $schemaContent = Get-Content -Path $SchemaPath -Raw
    $schema = ConvertFrom-Yaml $schemaContent
  } catch {
    throw "Failed to parse schema YAML: $_"
  }

  Write-Verbose "Validating manifest: $ManifestPath"

  # === REQUIRED FIELDS ===
  $requiredFields = @('role', 'mandate', 'kpis', 'lineage', 'risk_tiers')
  foreach ($field in $requiredFields) {
    if (-not $manifest.ContainsKey($field)) {
      $errors += "Missing required field: $field"
    }
  }

  # === ROLE FORMAT ===
  if ($manifest.role) {
    if ($manifest.role -notmatch '^[a-z0-9-]+$') {
      $errors += "Role must be lowercase alphanumeric with hyphens: '$($manifest.role)'"
    }
  }

  # === VERSION FORMAT ===
  if ($manifest.version -and $manifest.version -notmatch '^\d+\.\d+\.\d+$') {
    $errors += "Version must follow semver (e.g., 1.0.0): '$($manifest.version)'"
  }

  # === STATUS ===
  if ($manifest.status) {
    $validStatuses = @('active', 'suspended', 'quarantined', 'retired')
    if ($manifest.status -notin $validStatuses) {
      $errors += "Status must be one of: $($validStatuses -join ', ')"
    }
  }

  # === MANDATE VALIDATION ===
  if ($manifest.mandate) {
    # Scope
    if (-not $manifest.mandate.scope -or $manifest.mandate.scope.Count -eq 0) {
      $errors += "Mandate.scope must contain at least one allowed action"
    }

    # Constraints
    if (-not $manifest.mandate.constraints -or $manifest.mandate.constraints.Count -eq 0) {
      $warnings += "Mandate.constraints is empty - consider adding governance rules"
    }

    # Data Access
    if ($manifest.mandate.data_access) {
      $validAccessLevels = @('read-only', 'read-write', 'read-write-delete')
      if ($manifest.mandate.data_access.access_level -notin $validAccessLevels) {
        $errors += "data_access.access_level must be one of: $($validAccessLevels -join ', ')"
      }

      $validPiiHandling = @('no-access', 'tokenized', 'scoped-cell', 'full-access')
      if ($manifest.mandate.data_access.pii_handling -notin $validPiiHandling) {
        $errors += "data_access.pii_handling must be one of: $($validPiiHandling -join ', ')"
      }
    }
  }

  # === KPI VALIDATION ===
  if ($manifest.kpis) {
    $requiredKpis = @('precision', 'latency', 'compliance_ratio')
    foreach ($kpi in $requiredKpis) {
      if (-not $manifest.kpis.ContainsKey($kpi)) {
        $errors += "Missing required KPI: $kpi"
      }
    }

    # Validate KPI formats
    if ($manifest.kpis.precision -and $manifest.kpis.precision -notmatch '^(>=|<=|>|<|=) \d+(\.\d+)?%?$') {
      $errors += "KPI precision format invalid: '$($manifest.kpis.precision)' (expected: '>= 98%' or '>= 0.98')"
    }

    if ($manifest.kpis.latency -and $manifest.kpis.latency -notmatch '^<= \d+(s|m|h)$') {
      $errors += "KPI latency format invalid: '$($manifest.kpis.latency)' (expected: '<= 120s' or '<= 2m')"
    }
  }

  # === LINEAGE VALIDATION ===
  if ($manifest.lineage) {
    if (-not $manifest.lineage.ContainsKey('emit_events')) {
      $errors += "Lineage.emit_events is required (boolean)"
    }

    if ($manifest.lineage.evidence_retention_days -and $manifest.lineage.evidence_retention_days -lt 30) {
      $warnings += "Evidence retention < 30 days may violate compliance requirements"
    }
  }

  # === RISK TIERS VALIDATION ===
  if ($manifest.risk_tiers) {
    $validTiers = @('low_impact', 'medium_impact', 'high_impact', 'critical_impact')
    foreach ($tier in $validTiers) {
      if ($manifest.risk_tiers.ContainsKey($tier)) {
        $tierData = $manifest.risk_tiers.$tier

        if (-not $tierData.signatures_required -or $tierData.signatures_required -lt 1) {
          $errors += "risk_tiers.$tier.signatures_required must be >= 1"
        }

        if (-not $tierData.ContainsKey('witness_count')) {
          $warnings += "risk_tiers.$tier.witness_count not specified"
        }
      }
    }
  }

  # === ROUTING/SLA VALIDATION ===
  if ($manifest.routing -and $manifest.routing.sla) {
    if ($manifest.routing.sla.success_rate -and
      ($manifest.routing.sla.success_rate -lt 0 -or $manifest.routing.sla.success_rate -gt 1)) {
      $errors += "routing.sla.success_rate must be between 0 and 1"
    }
  }

  # === SAFETY VALIDATION ===
  if ($manifest.safety -and $manifest.safety.resource_limits) {
    if ($manifest.safety.resource_limits.max_cpu_percent) {
      $cpu = $manifest.safety.resource_limits.max_cpu_percent
      if ($cpu -lt 1 -or $cpu -gt 100) {
        $errors += "safety.resource_limits.max_cpu_percent must be 1-100"
      }
    }
  }

  # === GDPR COMPLIANCE CHECKS ===
  if ($manifest.mandate -and $manifest.mandate.data_access) {
    # If handling PII, must have proper constraints
    if ($manifest.mandate.data_access.pii_handling -in @('scoped-cell', 'full-access')) {
      $gdprKeywords = @('GDPR', 'PII', 'personal data', 'Art. 6', 'Art. 32')
      $hasGdprConstraint = $false
      foreach ($constraint in $manifest.mandate.constraints) {
        foreach ($keyword in $gdprKeywords) {
          if ($constraint -like "*$keyword*") {
            $hasGdprConstraint = $true
            break
          }
        }
      }
      if (-not $hasGdprConstraint) {
        $errors += "Agent handles PII but lacks GDPR constraints"
      }
    }
  }

  # === SOVEREIGNTY CHECKS ===
  # Ensure audit trail is enabled for all agents
  if ($manifest.lineage -and -not $manifest.lineage.emit_events) {
    $errors += "Sovereignty violation: lineage.emit_events must be true"
  }

  if ($manifest.lineage -and -not $manifest.lineage.signature_required) {
    $warnings += "Audit trail recommendation: lineage.signature_required should be true"
  }

  # === RESULTS ===
  $result = @{
    Valid        = ($errors.Count -eq 0 -and (-not $Strict -or $warnings.Count -eq 0))
    Errors       = $errors
    Warnings     = $warnings
    ManifestPath = $ManifestPath
    Role         = $manifest.role
    Version      = $manifest.version
    Status       = $manifest.status
  }

  # Output
  if ($errors.Count -gt 0) {
    Write-Host "`n❌ VALIDATION FAILED: $ManifestPath" -ForegroundColor Red
    foreach ($error in $errors) {
      Write-Host "  ERROR: $error" -ForegroundColor Red
    }
  }

  if ($warnings.Count -gt 0) {
    Write-Host "`n⚠️  WARNINGS: $ManifestPath" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
      Write-Host "  WARNING: $warning" -ForegroundColor Yellow
    }
  }

  if ($result.Valid) {
    Write-Host "`n✅ VALIDATION PASSED: $ManifestPath" -ForegroundColor Green
    Write-Host "   Role: $($manifest.role)" -ForegroundColor Cyan
    Write-Host "   Version: $($manifest.version)" -ForegroundColor Cyan
    Write-Host "   Status: $($manifest.status)" -ForegroundColor Cyan
  }

  return $result
}

<#
.SYNOPSIS
    Validates all agent manifests in the council/mandates directory.

.PARAMETER Path
    Path to directory containing manifests. Defaults to council/mandates/

.PARAMETER Strict
    Treat warnings as errors.

.EXAMPLE
    Test-AllAgentManifests

.EXAMPLE
    Test-AllAgentManifests -Strict
#>
function Test-AllAgentManifests {
  [CmdletBinding()]
  param(
    [string]$Path = "$PSScriptRoot\..\..\council\mandates",
    [switch]$Strict
  )

  Write-Host "`n🏛️  AGENT MANDATE VALIDATION CEREMONY" -ForegroundColor Magenta
  Write-Host "════════════════════════════════════════════════════" -ForegroundColor Magenta

  if (-not (Test-Path $Path)) {
    Write-Warning "Mandates directory not found: $Path"
    return @{
      TotalManifests = 0
      Valid          = 0
      Invalid        = 0
      Results        = @()
    }
  }

  $manifestFiles = Get-ChildItem -Path $Path -Filter "*.yaml" -File

  if ($manifestFiles.Count -eq 0) {
    Write-Warning "No manifest files found in: $Path"
    return @{
      TotalManifests = 0
      Valid          = 0
      Invalid        = 0
      Results        = @()
    }
  }

  $results = @()
  $validCount = 0
  $invalidCount = 0

  foreach ($file in $manifestFiles) {
    $result = Test-AgentManifest -ManifestPath $file.FullName -Strict:$Strict
    $results += $result

    if ($result.Valid) {
      $validCount++
    } else {
      $invalidCount++
    }
  }

  Write-Host "`n════════════════════════════════════════════════════" -ForegroundColor Magenta
  Write-Host "SUMMARY:" -ForegroundColor Cyan
  Write-Host "  Total Manifests: $($manifestFiles.Count)" -ForegroundColor White
  Write-Host "  Valid: $validCount" -ForegroundColor Green
  Write-Host "  Invalid: $invalidCount" -ForegroundColor Red

  return @{
    TotalManifests = $manifestFiles.Count
    Valid          = $validCount
    Invalid        = $invalidCount
    Results        = $results
  }
}

<#
.SYNOPSIS
    Creates a new agent manifest from template.

.PARAMETER Role
    Agent role identifier (lowercase-hyphenated).

.PARAMETER Domain
    Domain cell (commerce, build, civic, audit).

.PARAMETER Scope
    Array of allowed actions.

.PARAMETER OutputPath
    Where to save the manifest. Defaults to council/mandates/<role>.yaml

.EXAMPLE
    New-AgentManifest -Role "build-iso-optimizer" -Domain "build" -Scope @("iso_optimization", "driver_analysis")
#>
function New-AgentManifest {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9-]+$')]
    [string]$Role,

    [Parameter(Mandatory = $true)]
    [ValidateSet('commerce', 'build', 'civic', 'audit')]
    [string]$Domain,

    [Parameter(Mandatory = $true)]
    [string[]]$Scope,

    [string]$OutputPath = "$PSScriptRoot\..\..\council\mandates\$Role.yaml"
  )

  $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"

  $manifest = @"
# Agent Mandate: $Role
# Sovereign role definition for $Domain domain
# Created: $(Get-Date -Format 'yyyy-MM-dd') | Status: Active | Version: 1.0.0

role: "$Role"
version: "1.0.0"
created: "$timestamp"
updated: "$timestamp"
status: "active"

# === MANDATE (Scope and Permissions) ===
mandate:
  scope:
$($Scope | ForEach-Object { "    - `"$_`"" })

  constraints:
    - "TODO: Add legal constraints"
    - "TODO: Add safety constraints"
    - "TODO: Add compliance constraints"

  data_access:
    allowed_sources:
      - "TODO: Specify data sources"
    access_level: "read-only"
    pii_handling: "no-access"

  escalation_paths:
    - condition: "Compliance violation detected"
      escalate_to: "governance-cell-manager"

# === KPIs (Performance Expectations) ===
kpis:
  precision: ">= 95%"
  latency: "<= 5m"
  compliance_ratio: "100%"
  cost_per_decision: "<= €1.00"
  monthly_budget: "<= €500"

# === CAPABILITIES ===
capabilities:
  retrieval:
    - "TODO: Specify data sources"

  validators:
    - "TODO: Specify validators"

  models:
    - name: "TODO: Model name"
      purpose: "TODO: Purpose"
      version: "1.0.0"

  tools:
    - "PowerShell"

# === LINEAGE (Audit and Traceability) ===
lineage:
  emit_events: true
  witness_required: []
  evidence_retention_days: 365
  replay_enabled: true
  signature_required: true

# === RISK TIERS (Approval Thresholds) ===
risk_tiers:
  low_impact:
    actions:
      - "TODO: Low risk actions"
    signatures_required: 1
    witness_count: 0

  medium_impact:
    actions:
      - "TODO: Medium risk actions"
    signatures_required: 2
    witness_count: 1

  high_impact:
    actions:
      - "TODO: High risk actions"
    signatures_required: 3
    witness_count: 2

# === ROUTING (Performance Market) ===
routing:
  sla:
    p95_latency: "5m"
    success_rate: 0.95
    max_cost: "€1.00/decision"

  reputation:
    current_credits: 0
    calibration_score: 1.0
    last_calibration: null

# === SAFETY (Sandboxing and Guards) ===
safety:
  sandbox_required: false

  resource_limits:
    max_memory_mb: 2048
    max_cpu_percent: 50
    max_execution_time: "10m"

  output_guards:
    - "legal_compliance_check"

  context_firewall: true

# === METADATA ===
metadata:
  domain: "$Domain"
  owner: "$Domain-cell-manager"
  contact: "governance@civic-infrastructure.local"
  documentation: "docs/agents/$Role.md"
  source_code: "agents/$Domain/$Role.ps1"
  dependencies: []
  tags:
    - "$Domain"

# === GOVERNANCE SIGNATURES ===
signatures:
  - role: "$Domain-cell-manager"
    signature: "pending"
    timestamp: null
  - role: "governance-cell-manager"
    signature: "pending"
    timestamp: null
"@

  # Save manifest
  $manifest | Out-File -FilePath $OutputPath -Encoding UTF8

  Write-Host "✅ Created agent manifest: $OutputPath" -ForegroundColor Green
  Write-Host "   Role: $Role" -ForegroundColor Cyan
  Write-Host "   Domain: $Domain" -ForegroundColor Cyan
  Write-Host "`n⚠️  TODO: Complete the following sections:" -ForegroundColor Yellow
  Write-Host "   - mandate.constraints (legal, safety, compliance)" -ForegroundColor Yellow
  Write-Host "   - mandate.data_access.allowed_sources" -ForegroundColor Yellow
  Write-Host "   - capabilities (retrieval, validators, models)" -ForegroundColor Yellow
  Write-Host "   - risk_tiers actions" -ForegroundColor Yellow

  return $OutputPath
}

# Export functions
Export-ModuleMember -Function Test-AgentManifest, Test-AllAgentManifests, New-AgentManifest
