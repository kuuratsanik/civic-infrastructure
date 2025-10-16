<#
.SYNOPSIS
    Safety-Enhanced Master Orchestrator with "First Rule: DO NO HARM"

.DESCRIPTION
    Core AI agent that makes system decisions with mandatory safety validation.
    All decisions must pass through SafetyFramework before execution.
#>

#Requires -Version 5.1

# Import safety framework (MANDATORY)
Import-Module "$PSScriptRoot\..\safety\SafetyFramework.ps1" -Force

# Import self-capabilities
Import-Module "$PSScriptRoot\..\self-capabilities\SelfLearning.ps1" -Force
Import-Module "$PSScriptRoot\..\self-capabilities\SelfResearching.ps1" -Force

# ============================================
# CONFIGURATION
# ============================================

$script:ConfigPath = "ai-system\config\orchestrator-config.json"
$script:StatePath = "ai-system\state\orchestrator-state.json"
$script:DecisionLog = "ai-system\logs\decisions\decisions-$(Get-Date -Format 'yyyyMMdd').jsonl"

# ============================================
# ORCHESTRATOR FUNCTIONS
# ============================================

function Initialize-MasterOrchestrator {
    Write-Host "🎭 Initializing Master Orchestrator with Safety Framework..." -ForegroundColor Cyan

    # Initialize safety framework
    Write-Host "  🛡️ Loading Safety Framework (First Rule: DO NO HARM)" -ForegroundColor Yellow

    # Initialize learning system
    Initialize-LearningSystem

    # Load state
    $State = if (Test-Path $script:StatePath) {
        Get-Content $script:StatePath | ConvertFrom-Json
    } else {
        @{
            StartedAt        = Get-Date
            DecisionCount    = 0
            SafetyViolations = 0
            LastDecision     = $null
        }
    }

    Write-Host "✅ Master Orchestrator initialized with safety enabled" -ForegroundColor Green

    return $State
}

function Invoke-AIDecision {
    <#
    .SYNOPSIS
        Make an AI decision with MANDATORY safety validation
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Context,

        [string[]]$AvailableActions,

        [hashtable]$SystemState = @{}
    )

    Write-Host "`n🤖 AI Decision Request: $Context" -ForegroundColor Cyan

    # Step 1: Research best approach
    Write-Host "  🔬 Researching solutions..." -ForegroundColor Gray
    $Solutions = Find-Solution -Problem $Context -Context "system management"

    # Step 2: Use learning to get best action
    Write-Host "  🧠 Checking learned knowledge..." -ForegroundColor Gray
    $LearnedBest = Get-BestAction -Context $Context -AvailableActions $AvailableActions

    # Step 3: Determine proposed action
    $ProposedAction = if ($LearnedBest) {
        $LearnedBest.Action
    } elseif ($Solutions.Count -gt 0) {
        $Solutions[0].Solution
    } elseif ($AvailableActions.Count -gt 0) {
        $AvailableActions[0]
    } else {
        "No action - insufficient information"
    }

    Write-Host "  💡 Proposed Action: $ProposedAction" -ForegroundColor Yellow

    # Step 4: MANDATORY SAFETY CHECK (Cannot be skipped)
    Write-Host "  🛡️ Running Safety Validation..." -ForegroundColor Yellow

    $SafetyResult = Invoke-SafetyCheck -Action $ProposedAction -Context @{
        Scope            = "System"
        Context          = $Context
        AvailableActions = $AvailableActions
        SystemState      = $SystemState
    }

    # Step 5: Decision based on safety result
    $Decision = @{
        Timestamp      = Get-Date
        Context        = $Context
        ProposedAction = $ProposedAction
        SafetyApproved = $SafetyResult.Approved
        RiskLevel      = $SafetyResult.RiskLevel
        Reason         = $SafetyResult.Reason
        Executed       = $false
        Outcome        = $null
    }

    if ($SafetyResult.Approved) {
        Write-Host "  ✅ SAFETY APPROVED - Executing action" -ForegroundColor Green

        try {
            # Execute the action
            $Outcome = Invoke-Expression $ProposedAction
            $Decision.Executed = $true
            $Decision.Outcome = "Success: $Outcome"

            # Record success for learning
            Add-Experience `
                -Context $Context `
                -Action $ProposedAction `
                -Outcome "Success" `
                -Result "Success" `
                -ConfidenceScore 0.8

        } catch {
            $Decision.Outcome = "Failed: $_"
            Write-Host "  ❌ Execution failed: $_" -ForegroundColor Red

            # Record failure for learning
            Add-Experience `
                -Context $Context `
                -Action $ProposedAction `
                -Outcome "Failed: $_" `
                -Result "Failure" `
                -ConfidenceScore 0.3
        }

    } else {
        Write-Host "  🛑 SAFETY BLOCKED - Action not executed" -ForegroundColor Red
        $Decision.Outcome = "Blocked by safety framework: $($SafetyResult.Reason)"

        # Record blocked action
        Add-Experience `
            -Context $Context `
            -Action $ProposedAction `
            -Outcome "Blocked by safety" `
            -Result "Failure" `
            -ConfidenceScore 0.1
    }

    # Log decision
    $Decision | ConvertTo-Json -Compress | Add-Content $script:DecisionLog

    return $Decision
}

function Start-AutonomousMode {
    <#
    .SYNOPSIS
        Run in autonomous mode with safety monitoring
    #>
    param(
        [int]$IntervalSeconds = 30
    )

    Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║   MASTER ORCHESTRATOR - AUTONOMOUS MODE              ║" -ForegroundColor Cyan
    Write-Host "║   First Rule: DO NO HARM                              ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

    $State = Initialize-MasterOrchestrator

    while ($true) {
        try {
            # Analyze system state
            $SystemState = Get-SystemState

            # Determine what needs attention
            $NeedsAttention = Analyze-SystemNeeds -SystemState $SystemState

            foreach ($Need in $NeedsAttention) {
                Write-Host "`n📋 System Need: $($Need.Description)" -ForegroundColor Cyan

                # Make AI decision with safety validation
                $Decision = Invoke-AIDecision `
                    -Context $Need.Context `
                    -AvailableActions $Need.PossibleActions `
                    -SystemState $SystemState

                # Update state
                $State.DecisionCount++
                $State.LastDecision = Get-Date

                if (-not $Decision.SafetyApproved) {
                    $State.SafetyViolations++
                }

                # Save state
                $State | ConvertTo-Json | Set-Content $script:StatePath
            }

            # Display status
            Write-Host "`n📊 Status: $($State.DecisionCount) decisions, $($State.SafetyViolations) blocked by safety" -ForegroundColor Gray

        } catch {
            Write-SafetyLog "ERROR in autonomous mode: $_" -Level ERROR
        }

        Start-Sleep -Seconds $IntervalSeconds
    }
}

function Get-SystemState {
    return @{
        CPU       = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
        Memory    = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
        Disk      = (Get-PSDrive C).Free / 1GB
        Processes = (Get-Process).Count
        Timestamp = Get-Date
    }
}

function Analyze-SystemNeeds {
    param([hashtable]$SystemState)

    $Needs = @()

    # Check CPU
    if ($SystemState.CPU -gt 80) {
        $Needs += @{
            Description     = "High CPU usage: $([math]::Round($SystemState.CPU, 1))%"
            Context         = "Performance optimization needed"
            PossibleActions = @(
                "Analyze-ProcessUsage",
                "Write-Host 'CPU usage high, monitoring'",
                "Get-Process | Sort-Object CPU -Descending | Select-Object -First 5"
            )
        }
    }

    # Check Memory
    if ($SystemState.Memory -lt 1000) {
        $Needs += @{
            Description     = "Low memory: $([math]::Round($SystemState.Memory, 0))MB available"
            Context         = "Memory management needed"
            PossibleActions = @(
                "Get-Process | Sort-Object WS -Descending | Select-Object -First 5",
                "Write-Host 'Memory low, monitoring'"
            )
        }
    }

    # Check Disk
    if ($SystemState.Disk -lt 10) {
        $Needs += @{
            Description     = "Low disk space: $([math]::Round($SystemState.Disk, 1))GB free"
            Context         = "Disk cleanup recommended"
            PossibleActions = @(
                "Write-Host 'Disk space low - user should clean up'",
                "Get-ChildItem C:\Temp -Recurse | Measure-Object -Property Length -Sum"
            )
        }
    }

    return $Needs
}

# ============================================
# EXPORT MODULE MEMBERS
# ============================================

Export-ModuleMember -Function @(
    'Initialize-MasterOrchestrator',
    'Invoke-AIDecision',
    'Start-AutonomousMode'
)

# ============================================
# MAIN EXECUTION (if run directly)
# ============================================

if ($MyInvocation.InvocationName -ne '.') {
    Start-AutonomousMode -IntervalSeconds 30
}
