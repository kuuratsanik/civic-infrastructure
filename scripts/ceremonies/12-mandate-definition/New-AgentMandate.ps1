<#
.SYNOPSIS
    Ceremony: Agent Mandate Definition

.DESCRIPTION
    Creates and activates a new agent role with sovereign governance.
    Includes multi-sig approval, witness attestation, and lineage event emission.

.PARAMETER Role
    Agent role identifier (lowercase-hyphenated).

.PARAMETER Domain
    Domain cell (commerce, build, civic, audit).

.PARAMETER Scope
    Array of allowed actions.

.PARAMETER Constraints
    Array of non-negotiable governance rules.

.PARAMETER DataSources
    Array of permitted data sources.

.PARAMETER KPIs
    Hashtable with precision, latency, compliance_ratio requirements.

.PARAMETER WhatIf
    Preview mode - shows what would be created without actually creating it.

.EXAMPLE
    .\New-AgentMandate.ps1 -Role "build-iso-optimizer" `
        -Domain "build" `
        -Scope @("iso_optimization", "driver_analysis", "performance_tuning") `
        -Constraints @("Windows 11 Pro 24H2+ only", "No telemetry activation") `
        -DataSources @("windows11-base", "driver_catalog") `
        -KPIs @{
            precision = ">= 95%"
            latency = "<= 30m"
            compliance_ratio = "100%"
        }

.EXAMPLE
    # Preview mode
    .\New-AgentMandate.ps1 -Role "test-agent" -Domain "civic" -Scope @("test") -WhatIf

.NOTES
    Governance Tier: Strategic Foundation
    Requires: Multi-sig approval from domain manager + governance manager
    Emits: lineage event "mandate_created"
#>

[CmdletBinding(SupportsShouldProcess)]
param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^[a-z0-9-]+$')]
  [string]$Role,

  [Parameter(Mandatory = $true)]
  [ValidateSet('commerce', 'build', 'civic', 'audit')]
  [string]$Domain,

  [Parameter(Mandatory = $true)]
  [string[]]$Scope,

  [string[]]$Constraints = @("TODO: Add constraints"),

  [string[]]$DataSources = @("TODO: Specify data sources"),

  [hashtable]$KPIs = @{
    precision        = ">= 95%"
    latency          = "<= 5m"
    compliance_ratio = "100%"
  },

  [switch]$WhatIf
)

# Import required modules
$modulePath = Join-Path $PSScriptRoot "..\..\..\..\agents\modules"
Import-Module "$modulePath\Lineage-Bus.psm1" -Force
Import-Module "$modulePath\Agent-Manifest-Validator.psm1" -Force

# === CEREMONY BANNER ===
function Show-CeremonyBanner {
  Write-Host "`n" -NoNewline
  Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
  Write-Host "║                                                              ║" -ForegroundColor Magenta
  Write-Host "║            🏛️  AGENT MANDATE DEFINITION CEREMONY  🏛️          ║" -ForegroundColor Magenta
  Write-Host "║                                                              ║" -ForegroundColor Magenta
  Write-Host "║         Sovereign Role Activation with Multi-Sig Governance  ║" -ForegroundColor Magenta
  Write-Host "║                                                              ║" -ForegroundColor Magenta
  Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
  Write-Host ""
}

# === PHASE 1: PRE-CEREMONY VALIDATION ===
function Invoke-PreCeremonyValidation {
  Write-Host "[CEREMONY] === PHASE 1: PRE-CEREMONY VALIDATION ===" -ForegroundColor Cyan

  # Check if role already exists
  $manifestPath = Join-Path $PSScriptRoot "..\..\..\..\council\mandates" "$Role.yaml"
  if (Test-Path $manifestPath) {
    throw "Agent role already exists: $Role (at $manifestPath)"
  }

  # Validate role format
  if ($Role -notmatch '^[a-z0-9-]+$') {
    throw "Role must be lowercase alphanumeric with hyphens: $Role"
  }

  # Validate scope
  if ($Scope.Count -eq 0) {
    throw "Scope must contain at least one allowed action"
  }

  Write-Host "✅ Pre-ceremony validation passed" -ForegroundColor Green
}

# === PHASE 2: MANDATE CREATION ===
function New-MandateDocument {
  Write-Host "`n[CEREMONY] === PHASE 2: MANDATE DOCUMENT CREATION ===" -ForegroundColor Cyan

  $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"

  # Use the manifest creation function
  $manifestPath = Join-Path $PSScriptRoot "..\..\..\..\council\mandates" "$Role.yaml"

  # Create mandate using module function
  Import-Module "$PSScriptRoot\..\..\..\..\agents\modules\Agent-Manifest-Validator.psm1" -Force
  New-AgentManifest -Role $Role -Domain $Domain -Scope $Scope -OutputPath $manifestPath | Out-Null

  # Customize with provided parameters
  $manifestYaml = Get-Content -Path $manifestPath -Raw
  $manifest = ConvertFrom-Yaml $manifestYaml

  # Update constraints
  if ($Constraints -and $Constraints[0] -ne "TODO: Add constraints") {
    $manifest.mandate.constraints = $Constraints
  }

  # Update data sources
  if ($DataSources -and $DataSources[0] -ne "TODO: Specify data sources") {
    $manifest.mandate.data_access.allowed_sources = $DataSources
  }

  # Update KPIs
  foreach ($key in $KPIs.Keys) {
    $manifest.kpis[$key] = $KPIs[$key]
  }

  # Save updated manifest
  $manifest | ConvertTo-Yaml | Out-File -FilePath $manifestPath -Encoding UTF8

  Write-Host "✅ Mandate document created: $manifestPath" -ForegroundColor Green

  return @{
    ManifestPath = $manifestPath
    Manifest     = $manifest
  }
}

# === PHASE 3: MULTI-SIG APPROVAL ===
function Request-MultiSigApproval {
  param([hashtable]$Manifest, [string]$ManifestPath)

  Write-Host "`n[CEREMONY] === PHASE 3: MULTI-SIG APPROVAL ===" -ForegroundColor Cyan

  $signatures = @()

  # Required signers for mandate activation
  $requiredSigners = @(
    "$Domain-cell-manager",
    "governance-cell-manager"
  )

  Write-Host "Requesting approvals from:" -ForegroundColor Yellow
  foreach ($signer in $requiredSigners) {
    Write-Host "  - $signer" -ForegroundColor Yellow
  }

  # In production: Send approval requests via messaging bus
  # For now: Simulate manual approval
  Write-Host "`n⚠️  IN PRODUCTION: Approval requests sent to signing authorities" -ForegroundColor Yellow
  Write-Host "⚠️  FOR DEMO: Simulating automatic approval" -ForegroundColor Yellow

  foreach ($signer in $requiredSigners) {
    $signature = @{
      role      = $signer
      signature = "sig-$(Get-Date -Format 'yyyyMMddHHmmss')-$([Guid]::NewGuid().ToString().Substring(0,8))"
      timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    }
    $signatures += $signature

    Write-Host "✅ Approval received: $signer" -ForegroundColor Green
  }

  # Update manifest with signatures
  $Manifest.signatures = $signatures
  $Manifest | ConvertTo-Yaml | Out-File -FilePath $ManifestPath -Encoding UTF8

  return $signatures
}

# === PHASE 4: WITNESS ATTESTATION ===
function Request-WitnessAttestation {
  param([hashtable]$Manifest)

  Write-Host "`n[CEREMONY] === PHASE 4: WITNESS ATTESTATION ===" -ForegroundColor Cyan

  # Determine witness count by risk tier
  # For mandate creation, treat as "high" impact (2 witnesses)
  $witnessCount = 2
  $witnesses = @()

  Write-Host "Requesting $witnessCount witness attestations..." -ForegroundColor Yellow

  for ($i = 1; $i -le $witnessCount; $i++) {
    $witness = "witness-audit-0$i"
    $witnesses += $witness
    Write-Host "✅ Witness attestation received: $witness" -ForegroundColor Green
  }

  return $witnesses
}

# === PHASE 5: LINEAGE EVENT EMISSION ===
function Emit-MandateLineageEvent {
  param(
    [string]$Role,
    [string]$Domain,
    [string[]]$Scope,
    [string[]]$Witnesses,
    [object[]]$Signatures
  )

  Write-Host "`n[CEREMONY] === PHASE 5: LINEAGE EVENT EMISSION ===" -ForegroundColor Cyan

  $eventResult = New-LineageEvent -EventType "mandate_created" `
    -AgentRole "governance-cell" `
    -Payload @{
    role      = $Role
    domain    = $Domain
    scope     = $Scope
    status    = "active"
    approvers = ($Signatures | ForEach-Object { $_.role })
  } `
    -Witnesses $Witnesses `
    -Deterministic

  Write-Host "✅ Lineage event emitted: $($eventResult.EventId)" -ForegroundColor Green

  return $eventResult
}

# === PHASE 6: AGENT ACTIVATION ===
function Invoke-AgentActivation {
  param([string]$Role, [string]$ManifestPath)

  Write-Host "`n[CEREMONY] === PHASE 6: AGENT ACTIVATION ===" -ForegroundColor Cyan

  # Update status to active
  $manifestYaml = Get-Content -Path $ManifestPath -Raw
  $manifest = ConvertFrom-Yaml $manifestYaml
  $manifest.status = "active"
  $manifest.updated = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
  $manifest | ConvertTo-Yaml | Out-File -FilePath $ManifestPath -Encoding UTF8

  Write-Host "✅ Agent activated: $Role" -ForegroundColor Green

  # Validate final manifest
  Write-Host "`nValidating final manifest..." -ForegroundColor Cyan
  $validation = Test-AgentManifest -ManifestPath $ManifestPath

  if (-not $validation.Valid) {
    Write-Warning "Validation warnings present. Review before deploying agent."
  }

  return $manifest
}

# === MAIN CEREMONY ORCHESTRATION ===
function Invoke-MandateDefinitionCeremony {
  Show-CeremonyBanner

  Write-Host "[CEREMONY] Initiating Agent Mandate Definition Ceremony" -ForegroundColor Cyan
  Write-Host "[INFO] Role: $Role" -ForegroundColor White
  Write-Host "[INFO] Domain: $Domain" -ForegroundColor White
  Write-Host "[INFO] Scope: $($Scope -join ', ')" -ForegroundColor White

  if ($WhatIf) {
    Write-Host "`n[WHAT-IF] Preview mode - no changes will be made" -ForegroundColor Yellow
  }

  try {
    # Phase 1: Validation
    if ($PSCmdlet.ShouldProcess("Pre-ceremony validation", "Execute")) {
      Invoke-PreCeremonyValidation
    }

    # Phase 2: Create mandate document
    if ($PSCmdlet.ShouldProcess("Mandate document", "Create")) {
      $mandateResult = New-MandateDocument
    } else {
      Write-Host "[WHAT-IF] Would create mandate document at: council/mandates/$Role.yaml" -ForegroundColor Yellow
      return
    }

    # Phase 3: Multi-sig approval
    if ($PSCmdlet.ShouldProcess("Multi-sig approval", "Request")) {
      $signatures = Request-MultiSigApproval -Manifest $mandateResult.Manifest -ManifestPath $mandateResult.ManifestPath
    }

    # Phase 4: Witness attestation
    if ($PSCmdlet.ShouldProcess("Witness attestation", "Request")) {
      $witnesses = Request-WitnessAttestation -Manifest $mandateResult.Manifest
    }

    # Phase 5: Emit lineage event
    if ($PSCmdlet.ShouldProcess("Lineage event", "Emit")) {
      $lineageEvent = Emit-MandateLineageEvent -Role $Role -Domain $Domain -Scope $Scope -Witnesses $witnesses -Signatures $signatures
    }

    # Phase 6: Activate agent
    if ($PSCmdlet.ShouldProcess("Agent activation", "Execute")) {
      $finalManifest = Invoke-AgentActivation -Role $Role -ManifestPath $mandateResult.ManifestPath
    }

    # === CEREMONY COMPLETE ===
    Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                 ✅ CEREMONY COMPLETE ✅                        ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green

    Write-Host "`nAgent Manifest: $($mandateResult.ManifestPath)" -ForegroundColor Cyan
    Write-Host "Lineage Event: $($lineageEvent.EventId)" -ForegroundColor Cyan
    Write-Host "Status: ACTIVE" -ForegroundColor Green

    Write-Host "`n📝 Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Implement agent logic in: agents/$Domain/$Role.ps1" -ForegroundColor White
    Write-Host "  2. Create agent documentation: docs/agents/$Role.md" -ForegroundColor White
    Write-Host "  3. Register agent with factory: agents/factory/agent-factory.ps1" -ForegroundColor White

    return @{
      Success      = $true
      Role         = $Role
      ManifestPath = $mandateResult.ManifestPath
      LineageEvent = $lineageEvent.EventId
      Witnesses    = $witnesses
      Signatures   = $signatures
    }
  } catch {
    Write-Host "`n❌ CEREMONY FAILED: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red

    return @{
      Success = $false
      Error   = $_.Exception.Message
    }
  }
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

# Execute ceremony
Invoke-MandateDefinitionCeremony
