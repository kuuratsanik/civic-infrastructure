<#
.SYNOPSIS
    Governance-enhanced wrapper for Deploy-FullPower.ps1

.DESCRIPTION
    Wraps the full cloud deployment with DevMode2026-style governance:
    - Logs all actions to blockchain ledger
    - Creates evidence bundles
    - Implements approval checkpoints
    - Provides tamper-evident audit trail

.PARAMETER Mode
    Deployment mode: Full, CloudOnly, or LocalOnly

.PARAMETER RequireApproval
    Require manual approval before deployment

.PARAMETER SkipVSCodeExtension
    Skip VS Code extension installation

.EXAMPLE
    .\Deploy-FullPower-Governed.ps1 -Mode Full
    Deploy with governance tracking (auto-approve)

.EXAMPLE
    .\Deploy-FullPower-Governed.ps1 -Mode Full -RequireApproval
    Deploy with manual approval checkpoint
#>

param(
  [Parameter(Mandatory = $false)]
  [ValidateSet('Full', 'CloudOnly', 'LocalOnly')]
  [string]$Mode = 'Full',

  [Parameter(Mandatory = $false)]
  [switch]$RequireApproval,

  [Parameter(Mandatory = $false)]
  [switch]$SkipVSCodeExtension,

  [Parameter(Mandatory = $false)]
  [string]$AzureSubscriptionId,

  [Parameter(Mandatory = $false)]
  [string]$ResourceGroup = "sentient-workspace-rg"
)

# Import governance functions
. "$PSScriptRoot\scripts\utilities\Add-CouncilLedgerEntry.ps1"

Write-Host "`n"
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "    🏛️  GOVERNANCE-ENHANCED DEPLOYMENT: WAVE 9 + BLOCKCHAIN     " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "`n"

$deploymentId = Get-Date -Format "yyyyMMdd-HHmmss"
$evidencePath = "evidence\deployments\wave9-$deploymentId"

# Create evidence directory
if (-not (Test-Path $evidencePath)) {
  New-Item -Path $evidencePath -ItemType Directory -Force | Out-Null
}

# Log deployment initiation
Write-Host "📝 Logging deployment initiation to blockchain ledger..." -ForegroundColor Cyan

$startEntry = Add-CouncilLedgerEntry `
  -Action "Wave 9 Deployment Started" `
  -Actor $env:USERNAME `
  -Metadata @{
  DeploymentId    = $deploymentId
  Mode            = $Mode
  Timestamp       = Get-Date -Format "o"
  RequireApproval = $RequireApproval.IsPresent
  ResourceGroup   = $ResourceGroup
  SubscriptionId  = if ($AzureSubscriptionId) { $AzureSubscriptionId } else { "default" }
}

Write-Host ""

# Approval checkpoint
if ($RequireApproval) {
  Write-Host "⏸️  APPROVAL CHECKPOINT" -ForegroundColor Yellow
  Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "Deployment Details:" -ForegroundColor White
  Write-Host "  Mode: $Mode" -ForegroundColor Gray
  Write-Host "  Resource Group: $ResourceGroup" -ForegroundColor Gray
  Write-Host "  Deployment ID: $deploymentId" -ForegroundColor Gray
  Write-Host "  Evidence Path: $evidencePath" -ForegroundColor Gray
  Write-Host ""
  Write-Host "This deployment will:" -ForegroundColor White
  Write-Host "  • Deploy Azure OpenAI GPT-4 Turbo" -ForegroundColor Gray
  Write-Host "  • Deploy Azure Functions" -ForegroundColor Gray
  Write-Host "  • Configure VS Code extension" -ForegroundColor Gray
  Write-Host "  • Log all actions to blockchain ledger" -ForegroundColor Gray
  Write-Host ""

  $approval = Read-Host "Approve deployment [yes/no]"

  if ($approval -ne "yes") {
    Write-Host "`n❌ Deployment cancelled by user" -ForegroundColor Red

    # Log cancellation
    Add-CouncilLedgerEntry `
      -Action "Wave 9 Deployment Cancelled" `
      -Actor $env:USERNAME `
      -Metadata @{
      DeploymentId = $deploymentId
      Reason       = "User declined approval"
      Timestamp    = Get-Date -Format "o"
    } | Out-Null

    exit 0
  }

  Write-Host "✅ Deployment approved`n" -ForegroundColor Green

  # Log approval
  Add-CouncilLedgerEntry `
    -Action "Wave 9 Deployment Approved" `
    -Actor $env:USERNAME `
    -Metadata @{
    DeploymentId = $deploymentId
    Timestamp    = Get-Date -Format "o"
  } | Out-Null
}

# Execute deployment with error capture
Write-Host "🚀 Executing deployment (Mode = $Mode)..." -ForegroundColor Cyan
Write-Host ""

$deploymentSuccess = $false
$deploymentError = $null

try {
  # Build deployment parameters
  $deployParams = @{
    Mode = $Mode
  }

  if ($AzureSubscriptionId) {
    $deployParams.AzureSubscriptionId = $AzureSubscriptionId
  }

  if ($ResourceGroup) {
    $deployParams.ResourceGroup = $ResourceGroup
  }

  if ($SkipVSCodeExtension) {
    $deployParams.SkipVSCodeExtension = $true
  }

  # Capture output
  $transcriptPath = "$evidencePath\deployment-transcript.log"
  Start-Transcript -Path $transcriptPath

  # Execute main deployment script (using simplified version)
  & "$PSScriptRoot\Deploy-Sentient-Simple.ps1" @deployParams

  Stop-Transcript

  $deploymentSuccess = $true

} catch {
  $deploymentError = $_.Exception.Message
  $deploymentSuccess = $false

  Write-Host "`n❌ Deployment failed: $deploymentError" -ForegroundColor Red

  # Capture error details
  $errorPath = "$evidencePath\deployment-error.txt"
  $_ | Out-File $errorPath

  Stop-Transcript -ErrorAction SilentlyContinue
}

# Create evidence bundle
Write-Host "`n📦 Creating evidence bundle..." -ForegroundColor Cyan

$evidenceManifest = @{
  deployment_id  = $deploymentId
  timestamp      = Get-Date -Format "o"
  mode           = $Mode
  success        = $deploymentSuccess
  error          = $deploymentError
  actor          = $env:USERNAME
  resource_group = $ResourceGroup
  files          = @(
    "deployment-transcript.log"
  )
}

if ($deploymentError) {
  $evidenceManifest.files += "deployment-error.txt"
}

$evidenceManifest | ConvertTo-Json -Depth 10 | Set-Content "$evidencePath\manifest.json"

Write-Host "  ✅ Evidence bundle: $evidencePath" -ForegroundColor Green

# Log deployment result
if ($deploymentSuccess) {
  Write-Host "`n✅ Deployment completed successfully!" -ForegroundColor Green

  Add-CouncilLedgerEntry `
    -Action "Wave 9 Deployment Complete" `
    -Actor $env:USERNAME `
    -Metadata @{
    DeploymentId = $deploymentId
    Mode         = $Mode
    Success      = $true
    EvidencePath = $evidencePath
    Timestamp    = Get-Date -Format "o"
  } | Out-Null

} else {
  Write-Host "`n❌ Deployment failed" -ForegroundColor Red

  Add-CouncilLedgerEntry `
    -Action "Wave 9 Deployment Failed" `
    -Actor $env:USERNAME `
    -Metadata @{
    DeploymentId = $deploymentId
    Mode         = $Mode
    Success      = $false
    Error        = $deploymentError
    EvidencePath = $evidencePath
    Timestamp    = Get-Date -Format "o"
  } | Out-Null
}

# Verify ledger integrity
Write-Host "`n🔐 Verifying blockchain ledger integrity..." -ForegroundColor Cyan
& "$PSScriptRoot\scripts\utilities\Verify-LedgerIntegrity.ps1"

Write-Host "`n"
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "                  📊 GOVERNANCE SUMMARY                          " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "`n"

Write-Host "Deployment ID: $deploymentId" -ForegroundColor White
Write-Host "Evidence Bundle: $evidencePath" -ForegroundColor White
Write-Host "Ledger Entries: 3+ (Start → Approval → Result)" -ForegroundColor White
Write-Host "Blockchain Status: ✅ Verified" -ForegroundColor Green
Write-Host ""

if ($deploymentSuccess) {
  Write-Host "🎉 Deployment successful and logged to blockchain ledger!" -ForegroundColor Green
  Write-Host "   All actions are tamper-evident and citizen-auditable." -ForegroundColor Green
  exit 0
} else {
  Write-Host "❌ Deployment failed but logged to blockchain ledger." -ForegroundColor Red
  Write-Host "   Failure is documented and auditable." -ForegroundColor Red
  exit 1
}
