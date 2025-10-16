<#
.SYNOPSIS
    Complete AI + Civic Infrastructure Integration Script
.DESCRIPTION
    Integrates the AI Agent Orchestration System with existing DAO-governed
    Windows 11 ISO build infrastructure. Enables AI-powered ceremonies,
    intelligent optimization, and autonomous execution with full governance.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Setup,

    [Parameter(Mandatory = $false)]
    [switch]$Test,

    [Parameter(Mandatory = $false)]
    [switch]$FullDemo
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  AI + CIVIC INFRASTRUCTURE INTEGRATION" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

$scriptRoot = $PSScriptRoot

#region Setup Functions

function Initialize-Integration {
    Write-Host "[STEP 1] Verifying AI System..." -ForegroundColor Yellow

    # Check Ollama
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:11434/api/version" -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host "  ✓ Ollama service running" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ✗ Ollama not running - please start: ollama serve" -ForegroundColor Red
        Write-Host "  Or install: .\scripts\setup\Install-Ollama.ps1`n" -ForegroundColor Yellow
        return $false
    }

    # Check models
    Write-Host "`n[STEP 2] Verifying AI Models..." -ForegroundColor Yellow

    $ollamaPath = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
    if (-not (Test-Path $ollamaPath)) {
        $ollamaPath = "ollama" # Fallback to PATH if available
    }

    try {
        $models = & $ollamaPath list | Out-String
    } catch {
        Write-Host "  ✗ Cannot query models - ollama command failed" -ForegroundColor Red
        return $false
    }

    if ($models -match "codellama") {
        Write-Host "  ✓ CodeLlama available" -ForegroundColor Green
    } else {
        Write-Host "  ✗ CodeLlama not found - run: ollama pull codellama:7b" -ForegroundColor Red
        return $false
    }

    # Update civic agent paths
    Write-Host "`n[STEP 3] Configuring Civic Agent..." -ForegroundColor Yellow

    $civicAgent = "$scriptRoot\agents\civic\civic-agent.ps1"
    if (Test-Path $civicAgent) {
        Write-Host "  ✓ Civic agent found" -ForegroundColor Green

        # Update inbox/outbox paths to use integrated bus
        $content = Get-Content $civicAgent -Raw
        if ($content -match "C:\\ai-council\\bus") {
            $content = $content -replace 'C:\\ai-council\\bus', "$scriptRoot\bus"
            $content = $content -replace 'C:\\ai-council\\logs', "$scriptRoot\logs"
            $content = $content -replace 'C:\\ai-council\\council', "$scriptRoot\council"
            $content = $content -replace 'C:\\ai-council\\agents', "$scriptRoot\agents"

            $content | Set-Content $civicAgent
            Write-Host "  ✓ Paths updated to integrated bus" -ForegroundColor Green
        } else {
            Write-Host "  ✓ Already using integrated paths" -ForegroundColor Green
        }
    }

    # Create unified directories
    Write-Host "`n[STEP 4] Creating Unified Directory Structure..." -ForegroundColor Yellow

    $directories = @(
        "$scriptRoot\bus\inbox\critical",
        "$scriptRoot\bus\inbox\high",
        "$scriptRoot\bus\inbox\normal",
        "$scriptRoot\bus\inbox\low",
        "$scriptRoot\council\keys\agents",
        "$scriptRoot\knowledge\patterns",
        "$scriptRoot\knowledge\context",
        "$scriptRoot\knowledge\lessons\iso-builds",
        "$scriptRoot\logs\agents"
    )

    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-Host "  ✓ Created: $(Split-Path $dir -Leaf)" -ForegroundColor Green
        }
    }

    # Initialize knowledge base with ISO patterns
    Write-Host "`n[STEP 5] Initializing Knowledge Base..." -ForegroundColor Yellow

    $isoPatterns = @'
# Windows 11 ISO Build Patterns

## Successful Patterns

### Privacy Optimization
- Disable telemetry: HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection
- Remove Cortana, OneDrive, Xbox apps
- Manual Windows Update control

### Performance
- Disable unnecessary services
- Compact install.wim
- Remove language packs (keep 1-2)

### Compatibility
- Keep Windows Security
- Keep Microsoft Store (for driver updates)
- Keep .NET frameworks

## Failed Patterns (Avoid)

### Breaking Changes
- DO NOT remove Windows Security
- DO NOT remove all Microsoft Edge (breaks updates)
- DO NOT disable Windows Update completely

### Compatibility Issues
- Removing all Store apps breaks provisioned drivers
- Disabling WinSxS breaks updates
- Removing PowerShell breaks admin tools

## Best Practices

1. Always keep backup of original ISO
2. Test in VM before physical deployment
3. Document all customizations
4. Generate SHA256 hashes
5. Maintain audit trail via DAO ledger
'@

    $isoPatterns | Set-Content "$scriptRoot\knowledge\patterns\iso-build-patterns.md"
    Write-Host "  ✓ ISO build patterns initialized" -ForegroundColor Green

    # Create civic governance context
    $civicContext = @'
# Civic Governance Rules for AI Agents

## Warrant Requirements

All AI agent actions require valid warrants:
- Standard actions: 7-day warrant
- Critical changes: Multi-signature warrant
- ISO builds: Civic agent approval required

## Audit Trail

Every action must be logged to:
- council_ledger.jsonl (governance)
- civic.jsonl (operations)
- agent-specific logs (details)

## Decision Authority

1. Master Orchestrator: Task planning & agent assignment
2. Civic Agent: Governance validation & approval
3. Specialist Agents: Task execution only

## Override Protocol

Human can override AI decisions via:
- Warrant revocation
- Manual ceremony execution
- Direct council ledger entry
'@

    $civicContext | Set-Content "$scriptRoot\knowledge\context\civic-governance.md"
    Write-Host "  ✓ Governance context initialized" -ForegroundColor Green

    Write-Host "`n[COMPLETE] Integration setup complete!`n" -ForegroundColor Green
    return $true
}

function Invoke-IntegrationTest {
    Write-Host "[TEST] Running Integration Tests..." -ForegroundColor Cyan
    Write-Host ""

    # Test 1: AI service
    Write-Host "[TEST 1] AI Service Check" -ForegroundColor Yellow
    try {
        $test = @{
            model  = "codellama:7b"
            prompt = "Say 'AI integration working' and nothing else"
            stream = $false
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" `
            -Method Post `
            -Body $test `
            -ContentType "application/json" `
            -TimeoutSec 30

        if ($response.response) {
            Write-Host "  ✓ AI responding: $($response.response.Substring(0, [Math]::Min(50, $response.response.Length)))" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ✗ AI test failed: $_" -ForegroundColor Red
        return $false
    }

    # Test 2: Message bus
    Write-Host "`n[TEST 2] Message Bus Integration" -ForegroundColor Yellow
    $testPacket = @{
        packet_id = "test-integration-$(Get-Date -Format 'yyyyMMddHHmmss')"
        source    = "integration-test"
        target    = "civic-agent"
        action    = "test-governance"
        timestamp = (Get-Date -Format "o")
    } | ConvertTo-Json

    $testFile = "$scriptRoot\bus\inbox\test-packet.json"
    $testPacket | Set-Content $testFile

    if (Test-Path $testFile) {
        Write-Host "  ✓ Message bus writable" -ForegroundColor Green
        Remove-Item $testFile -Force
    } else {
        Write-Host "  ✗ Cannot write to message bus" -ForegroundColor Red
        return $false
    }

    # Test 3: Knowledge base
    Write-Host "`n[TEST 3] Knowledge Base Access" -ForegroundColor Yellow
    if (Test-Path "$scriptRoot\knowledge\patterns\iso-build-patterns.md") {
        Write-Host "  ✓ Knowledge base accessible" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Knowledge base missing" -ForegroundColor Red
        return $false
    }

    # Test 4: AI-powered ISO analysis (if ISO available)
    Write-Host "`n[TEST 4] AI ISO Analysis (Optional)" -ForegroundColor Yellow
    $testISO = "C:\Users\svenk\Downloads\Win11_25H2_Estonian_x64.iso"

    if (Test-Path $testISO) {
        Write-Host "  Found test ISO, running AI analysis..." -ForegroundColor Cyan

        try {
            $analysisResult = & "$scriptRoot\agents\build\iso-build-ai-agent.ps1" `
                -BaseISOPath $testISO `
                -AnalyzeOnly `
                -ErrorAction Stop

            Write-Host "  ✓ AI ISO analysis completed" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠ AI analysis failed (non-critical): $_" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ⊘ Test ISO not found (skipping)" -ForegroundColor Gray
    }

    Write-Host "`n[COMPLETE] Integration tests passed!`n" -ForegroundColor Green
    return $true
}

function Invoke-FullDemonstration {
    Write-Host "[DEMO] Full AI + Civic Integration Demo" -ForegroundColor Magenta
    Write-Host ""

    Write-Host "Scenario: AI-powered Windows 11 ISO optimization`n" -ForegroundColor Cyan

    # Demo request
    $demoRequest = @{
        packet_id        = "demo-ai-iso-$(Get-Date -Format 'yyyyMMddHHmmss')"
        source           = "human-operator"
        target           = "master-orchestrator"
        task_type        = "iso-optimization"
        action           = "analyze and suggest optimizations"
        payload          = @{
            base_iso     = "Win11_25H2_Estonian_x64.iso"
            requirements = @("maximum-privacy", "performance-optimized", "minimal-bloat")
        }
        warrant_required = $true
        priority         = "high"
        timestamp        = (Get-Date -Format "o")
    } | ConvertTo-Json -Depth 10

    Write-Host "Request submitted:" -ForegroundColor Yellow
    Write-Host $demoRequest -ForegroundColor Gray
    Write-Host ""

    # Save to message bus
    $demoFile = "$scriptRoot\bus\inbox\high\$($demoRequest.packet_id).json"
    $demoRequest | Set-Content $demoFile

    Write-Host "✓ Request saved to message bus: high priority queue`n" -ForegroundColor Green

    Write-Host "What happens next (autonomous):" -ForegroundColor Cyan
    Write-Host "  1. Civic Agent picks up request" -ForegroundColor White
    Write-Host "  2. Validates against governance policies" -ForegroundColor White
    Write-Host "  3. Creates 7-day warrant for AI operation" -ForegroundColor White
    Write-Host "  4. Forwards to Master Orchestrator" -ForegroundColor White
    Write-Host "  5. Master spawns ISO Build AI Agent" -ForegroundColor White
    Write-Host "  6. AI Agent analyzes base ISO" -ForegroundColor White
    Write-Host "  7. Generates optimization suggestions" -ForegroundColor White
    Write-Host "  8. Creates custom registry tweaks" -ForegroundColor White
    Write-Host "  9. Validates integrity" -ForegroundColor White
    Write-Host " 10. Returns results to outbox" -ForegroundColor White
    Write-Host " 11. All actions logged to council ledger`n" -ForegroundColor White

    Write-Host "To execute this demo:" -ForegroundColor Yellow
    Write-Host "  1. Start Civic Agent: .\agents\civic\civic-agent.ps1 -WatchMode -EnableAI" -ForegroundColor Cyan
    Write-Host "  2. Start Master: .\agents\master\master-orchestrator.ps1 -WatchMode" -ForegroundColor Cyan
    Write-Host "  3. Watch logs: Get-Content logs\civic.jsonl -Wait -Tail 10`n" -ForegroundColor Cyan
}

#endregion

#region Main Execution

if ($Setup) {
    $success = Initialize-Integration

    if ($success) {
        Write-Host "═══════════════════════════════════════" -ForegroundColor Green
        Write-Host "  INTEGRATION COMPLETE!" -ForegroundColor Green
        Write-Host "═══════════════════════════════════════`n" -ForegroundColor Green

        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Test: .\scripts\AI-Civic-Integration.ps1 -Test" -ForegroundColor Cyan
        Write-Host "  2. Demo: .\scripts\AI-Civic-Integration.ps1 -FullDemo`n" -ForegroundColor Cyan
    }

} elseif ($Test) {
    $success = Invoke-IntegrationTest

    if ($success) {
        Write-Host "All tests passed! System ready for use.`n" -ForegroundColor Green
    }

} elseif ($FullDemo) {
    Invoke-FullDemonstration

} else {
    Write-Host "AI + Civic Infrastructure Integration`n" -ForegroundColor Cyan

    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  Setup:  .\scripts\AI-Civic-Integration.ps1 -Setup" -ForegroundColor White
    Write-Host "  Test:   .\scripts\AI-Civic-Integration.ps1 -Test" -ForegroundColor White
    Write-Host "  Demo:   .\scripts\AI-Civic-Integration.ps1 -FullDemo`n" -ForegroundColor White
}

#endregion
