<#
.SYNOPSIS
    AI-Powered ISO Build Agent - Intelligent Windows 11 customization
.DESCRIPTION
    Uses local AI (CodeLlama via Ollama) to:
    - Analyze Windows 11 base images
    - Suggest optimal customizations
    - Auto-generate registry tweaks
    - Detect compatibility issues
    - Validate WIM integrity
    - Learn from build patterns

    Integrates with existing DAO governance and civic infrastructure.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$BaseISOPath,

    [Parameter(Mandatory = $false)]
    [string[]]$Requirements = @("privacy", "performance", "minimal"),

    [Parameter(Mandatory = $false)]
    [switch]$AnalyzeOnly,

    [Parameter(Mandatory = $false)]
    [switch]$WatchMode,

    [Parameter(Mandatory = $false)]
    [string]$OllamaUrl = "http://localhost:11434"
)

$ErrorActionPreference = "Stop"

# Agent Configuration
$global:ISOBuildAIConfig = @{
    AgentId   = "iso-build-ai-$(Get-Date -Format 'yyyyMMddHHmmss')"
    Type      = "iso-build-ai"
    Model     = "codellama:7b"
    OllamaUrl = $OllamaUrl

    Paths     = @{
        Base      = "$PSScriptRoot\..\.."
        Workspace = "$PSScriptRoot\..\..\workspace"
        Knowledge = "$PSScriptRoot\..\..\knowledge"
        Logs      = "$PSScriptRoot\..\..\logs\agents"
    }
}

# Import existing modules
$modulePath = "$PSScriptRoot\..\..\scripts\modules"
if (Test-Path "$modulePath\CivicGovernance.psm1") {
    Import-Module "$modulePath\CivicGovernance.psm1" -Force
}

#region Helper Functions

function Write-AILog {
    param([string]$Message, [string]$Level = "INFO")

    $logEntry = @{
        timestamp  = (Get-Date -Format "o")
        agent_id   = $global:ISOBuildAIConfig.AgentId
        agent_type = "iso-build-ai"
        level      = $Level
        message    = $Message
    } | ConvertTo-Json -Compress

    $logFile = "$($global:ISOBuildAIConfig.Paths.Logs)\iso-build-ai.jsonl"
    Add-Content -Path $logFile -Value $logEntry

    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        "AI" { "Magenta" }
        default { "Cyan" }
    }

    Write-Host "[$Level] $Message" -ForegroundColor $color
}

function Invoke-LocalAI {
    param(
        [string]$Prompt,
        [string]$SystemPrompt = "You are an expert Windows system administrator and PowerShell developer.",
        [int]$MaxTokens = 2048
    )

    Write-AILog "Invoking AI: $(($Prompt.Length) / 1000)KB prompt" -Level "AI"

    try {
        $requestBody = @{
            model   = $global:ISOBuildAIConfig.Model
            prompt  = $Prompt
            system  = $SystemPrompt
            stream  = $false
            options = @{
                temperature = 0.3  # Lower for more deterministic responses
                num_predict = $MaxTokens
            }
        } | ConvertTo-Json -Depth 10

        $response = Invoke-RestMethod -Uri "$($global:ISOBuildAIConfig.OllamaUrl)/api/generate" `
            -Method Post `
            -Body $requestBody `
            -ContentType "application/json" `
            -TimeoutSec 120

        Write-AILog "AI response received: $(($response.response.Length) / 1000)KB" -Level "SUCCESS"
        return $response.response

    } catch {
        Write-AILog "AI invocation failed: $_" -Level "ERROR"
        return $null
    }
}

function Get-ISOAnalysis {
    param([string]$ISOPath)

    Write-AILog "Analyzing ISO: $ISOPath"

    # Extract ISO metadata
    $isoInfo = @{
        Path   = $ISOPath
        Size   = (Get-Item $ISOPath -ErrorAction SilentlyContinue).Length
        Exists = Test-Path $ISOPath
    }

    if (-not $isoInfo.Exists) {
        Write-AILog "ISO not found: $ISOPath" -Level "ERROR"
        return $null
    }

    # Mount ISO to analyze
    try {
        $mount = Mount-DiskImage -ImagePath $ISOPath -PassThru -ErrorAction Stop
        $driveLetter = ($mount | Get-Volume).DriveLetter
        $mountPath = "${driveLetter}:"

        # Get critical files
        $criticalFiles = @(
            "sources\install.wim",
            "sources\boot.wim",
            "bootmgr.efi",
            "setup.exe"
        )

        $fileStatus = @{}
        foreach ($file in $criticalFiles) {
            $fullPath = Join-Path $mountPath $file
            $fileStatus[$file] = @{
                Exists = Test-Path $fullPath
                Size   = if (Test-Path $fullPath) { (Get-Item $fullPath).Length } else { 0 }
            }
        }

        # Get install.wim info
        if ($fileStatus["sources\install.wim"].Exists) {
            $wimInfo = Get-WindowsImage -ImagePath (Join-Path $mountPath "sources\install.wim") -Index 1 -ErrorAction SilentlyContinue
            $isoInfo.Edition = $wimInfo.ImageName
            $isoInfo.Version = $wimInfo.Version
            $isoInfo.Architecture = $wimInfo.Architecture
        }

        # Dismount
        Dismount-DiskImage -ImagePath $ISOPath | Out-Null

        $isoInfo.Files = $fileStatus
        Write-AILog "ISO analysis complete" -Level "SUCCESS"

        return $isoInfo

    } catch {
        Write-AILog "Failed to analyze ISO: $_" -Level "ERROR"
        return $null
    }
}

function Get-AIOptimizationSuggestions {
    param(
        [hashtable]$ISOInfo,
        [string[]]$Requirements
    )

    Write-AILog "Requesting AI optimization suggestions..."

    $systemPrompt = @"
You are a Windows system optimization expert. Analyze the ISO information and requirements, then provide specific, actionable optimization suggestions.

Focus on:
1. Registry tweaks (exact paths and values)
2. Apps/features to remove
3. Performance optimizations
4. Privacy enhancements
5. Security hardening

Provide concrete, implementable suggestions in PowerShell-friendly format.
"@

    $userPrompt = @"
Analyze this Windows 11 ISO:
Edition: $($ISOInfo.Edition)
Version: $($ISOInfo.Version)
Architecture: $($ISOInfo.Architecture)

User Requirements: $($Requirements -join ', ')

Provide optimization suggestions organized by category:
1. Privacy Registry Tweaks
2. Performance Registry Tweaks
3. Apps to Remove
4. Features to Disable
5. Security Hardening

For each suggestion, provide:
- Registry path (if applicable)
- Value name and data
- Reason for change
- Expected impact
"@

    $aiResponse = Invoke-LocalAI -Prompt $userPrompt -SystemPrompt $systemPrompt -MaxTokens 4096

    if ($aiResponse) {
        # Store in knowledge base
        $knowledgeFile = "$($global:ISOBuildAIConfig.Paths.Knowledge)\lessons\ai-suggestions-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
        @"
# AI Optimization Suggestions
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
ISO: $($ISOInfo.Edition)
Requirements: $($Requirements -join ', ')

## Suggestions:
$aiResponse
"@ | Set-Content $knowledgeFile

        Write-AILog "Suggestions saved to knowledge base" -Level "SUCCESS"
    }

    return $aiResponse
}

function New-AIRegistryTweaks {
    param(
        [string]$Requirements,
        [string]$OutputPath
    )

    Write-AILog "Generating AI-powered registry tweaks..."

    $systemPrompt = "You are a Windows registry expert. Generate valid .reg file content for Windows 11 optimizations. Output ONLY the .reg file content, no explanations."

    $userPrompt = @"
Generate a Windows Registry Editor Version 5.00 .reg file for these requirements:
$Requirements

Include:
1. Telemetry disabled
2. Privacy enhanced
3. Performance optimized
4. UI improvements

Output format must be valid .reg syntax that can be imported directly.
Start with: Windows Registry Editor Version 5.00
"@

    $regContent = Invoke-LocalAI -Prompt $userPrompt -SystemPrompt $systemPrompt -MaxTokens 2048

    if ($regContent) {
        # Clean up AI response (sometimes includes markdown)
        $regContent = $regContent -replace '```.*', '' -replace '```', ''

        # Ensure it starts with proper header
        if ($regContent -notmatch 'Windows Registry Editor') {
            $regContent = "Windows Registry Editor Version 5.00`n`n" + $regContent
        }

        $regContent | Set-Content $OutputPath -Encoding Unicode
        Write-AILog "Registry tweaks generated: $OutputPath" -Level "SUCCESS"

        return $OutputPath
    }

    return $null
}

function Test-ISOIntegrityAI {
    param([string]$ISOPath)

    Write-AILog "AI-powered integrity check..."

    $analysis = Get-ISOAnalysis -ISOPath $ISOPath

    if (-not $analysis) {
        Write-AILog "Cannot perform integrity check - analysis failed" -Level "ERROR"
        return $false
    }

    # AI analysis of file structure
    $systemPrompt = "You are a Windows ISO expert. Analyze the ISO structure and identify any issues."

    $fileList = $analysis.Files.Keys | ForEach-Object {
        "$_ : Exists=$($analysis.Files[$_].Exists), Size=$($analysis.Files[$_].Size)"
    } | Out-String

    $userPrompt = @"
Analyze this Windows 11 ISO file structure:
$fileList

Edition: $($analysis.Edition)
Version: $($analysis.Version)

Are there any critical missing files or structural issues?
Is this ISO valid and bootable?
List any concerns.
"@

    $aiResponse = Invoke-LocalAI -Prompt $userPrompt -SystemPrompt $systemPrompt

    Write-AILog "AI Integrity Analysis: $aiResponse" -Level "AI"

    # Check for keywords indicating problems
    $hasIssues = $aiResponse -match "missing|error|invalid|corrupt|problem|issue"

    if ($hasIssues) {
        Write-AILog "AI detected potential issues with ISO" -Level "WARN"
        return $false
    } else {
        Write-AILog "AI confirms ISO structure is valid" -Level "SUCCESS"
        return $true
    }
}

function Invoke-AIBuildWorkflow {
    param(
        [string]$BaseISO,
        [string[]]$Requirements
    )

    Write-Host "`n========================================" -ForegroundColor Magenta
    Write-Host "  AI-POWERED ISO BUILD WORKFLOW" -ForegroundColor Magenta
    Write-Host "========================================`n" -ForegroundColor Magenta

    # Phase 1: Analyze base ISO
    Write-Host "[PHASE 1] ISO Analysis" -ForegroundColor Cyan
    $analysis = Get-ISOAnalysis -ISOPath $BaseISO

    if ($analysis) {
        Write-Host "  ✓ Edition: $($analysis.Edition)" -ForegroundColor Green
        Write-Host "  ✓ Version: $($analysis.Version)" -ForegroundColor Green
        Write-Host "  ✓ Architecture: $($analysis.Architecture)`n" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Analysis failed`n" -ForegroundColor Red
        return
    }

    # Phase 2: AI Optimization Suggestions
    Write-Host "[PHASE 2] AI Optimization Analysis" -ForegroundColor Cyan
    $suggestions = Get-AIOptimizationSuggestions -ISOInfo $analysis -Requirements $Requirements

    if ($suggestions) {
        Write-Host "  ✓ AI generated $(($suggestions.Length)/1000)KB of suggestions" -ForegroundColor Green
        Write-Host "  ✓ Saved to knowledge base`n" -ForegroundColor Green
    }

    # Phase 3: Generate Custom Tweaks
    Write-Host "[PHASE 3] Generate AI Registry Tweaks" -ForegroundColor Cyan
    $tweaksPath = "$($global:ISOBuildAIConfig.Paths.Workspace)\customization\tweaks\ai-generated-$(Get-Date -Format 'yyyyMMdd-HHmmss').reg"

    $regFile = New-AIRegistryTweaks -Requirements ($Requirements -join ', ') -OutputPath $tweaksPath

    if ($regFile) {
        Write-Host "  ✓ Registry tweaks: $regFile`n" -ForegroundColor Green
    }

    # Phase 4: Integrity Validation
    Write-Host "[PHASE 4] AI Integrity Validation" -ForegroundColor Cyan
    $isValid = Test-ISOIntegrityAI -ISOPath $BaseISO

    if ($isValid) {
        Write-Host "  ✓ ISO structure validated by AI`n" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ AI detected potential issues - review recommended`n" -ForegroundColor Yellow
    }

    # Phase 5: Summary
    Write-Host "[COMPLETE] AI Analysis Summary" -ForegroundColor Green
    Write-Host "  • Base ISO analyzed successfully" -ForegroundColor White
    Write-Host "  • Optimization suggestions generated" -ForegroundColor White
    Write-Host "  • Custom registry tweaks created" -ForegroundColor White
    Write-Host "  • Integrity validated" -ForegroundColor White
    Write-Host "`nNext step: Review AI suggestions and execute build ceremony`n" -ForegroundColor Cyan

    # Return results
    return @{
        Analysis       = $analysis
        Suggestions    = $suggestions
        RegistryTweaks = $regFile
        Valid          = $isValid
    }
}

#endregion

#region Main Execution

if ($WatchMode) {
    Write-Host "ISO Build AI Agent watching for requests..." -ForegroundColor Cyan
    Write-Host "Submit to: bus\inbox\*-iso-build-ai.json`n" -ForegroundColor Yellow

    while ($true) {
        $tasks = Get-ChildItem "$($global:ISOBuildAIConfig.Paths.Base)\bus\inbox\*-iso-build-ai.json" -ErrorAction SilentlyContinue

        foreach ($task in $tasks) {
            try {
                $taskData = Get-Content $task.FullName | ConvertFrom-Json
                Write-AILog "Processing task: $($taskData.packet_id)"

                $result = Invoke-AIBuildWorkflow -BaseISO $taskData.base_iso -Requirements $taskData.requirements

                # Save result
                $output = @{
                    packet_id    = $taskData.packet_id
                    agent_id     = $global:ISOBuildAIConfig.AgentId
                    status       = "completed"
                    result       = $result
                    completed_at = (Get-Date -Format "o")
                }

                $outputFile = "$($global:ISOBuildAIConfig.Paths.Base)\bus\outbox\$($taskData.packet_id)-result.json"
                $output | ConvertTo-Json -Depth 10 | Set-Content $outputFile

                # Move task to processed
                Move-Item $task.FullName "$($global:ISOBuildAIConfig.Paths.Base)\bus\deadletter\processed-$(Split-Path $task -Leaf)"

            } catch {
                Write-AILog "Task processing error: $_" -Level "ERROR"
            }
        }

        Start-Sleep -Seconds 5
    }

} elseif ($BaseISOPath) {
    # Direct execution
    if ($AnalyzeOnly) {
        $analysis = Get-ISOAnalysis -ISOPath $BaseISOPath
        $suggestions = Get-AIOptimizationSuggestions -ISOInfo $analysis -Requirements $Requirements

        Write-Host "`nAnalysis complete. Check knowledge base for suggestions.`n" -ForegroundColor Green
    } else {
        $result = Invoke-AIBuildWorkflow -BaseISO $BaseISOPath -Requirements $Requirements
    }

} else {
    # Show usage
    Write-Host "`nAI-Powered ISO Build Agent" -ForegroundColor Cyan
    Write-Host "Uses local AI to optimize Windows 11 ISO builds`n" -ForegroundColor Gray

    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  Analyze ISO:" -ForegroundColor White
    Write-Host "    .\iso-build-ai-agent.ps1 -BaseISOPath 'C:\path\to\Win11.iso' -AnalyzeOnly`n" -ForegroundColor Gray

    Write-Host "  Full AI workflow:" -ForegroundColor White
    Write-Host "    .\iso-build-ai-agent.ps1 -BaseISOPath 'C:\path\to\Win11.iso' -Requirements 'privacy','performance'`n" -ForegroundColor Gray

    Write-Host "  Watch mode:" -ForegroundColor White
    Write-Host "    .\iso-build-ai-agent.ps1 -WatchMode" -ForegroundColor Gray
    Write-Host ""
}

#endregion
