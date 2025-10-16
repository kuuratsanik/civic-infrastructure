<#
.SYNOPSIS
    Master Orchestrator Agent - Central AI that manages all other agents
.DESCRIPTION
    The Master Agent is the brain of the system. It:
    - Receives high-level user requests
    - Analyzes requirements and breaks down into tasks
    - Decides which specialist agents are needed
    - Dynamically spawns/terminates agents based on workload
    - Monitors execution and ensures quality
    - Scales teams up/down as needed
    - Uses local Ollama/CodeLlama for AI inference (privacy-first)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$UserRequest,
    
    [Parameter(Mandatory=$false)]
    [switch]$WatchMode,
    
    [Parameter(Mandatory=$false)]
    [string]$OllamaUrl = "http://localhost:11434"
)

$ErrorActionPreference = "Stop"

# Import modules
$scriptRoot = Split-Path -Parent $PSScriptRoot
Import-Module "$scriptRoot\modules\CivicGovernance.psm1" -Force

# Master Agent Configuration
$global:MasterConfig = @{
    AgentId = "master-orchestrator-001"
    Version = "1.0.0"
    OllamaUrl = $OllamaUrl
    Model = "codellama:7b"
    MaxConcurrentAgents = 10
    AgentScalingThreshold = 0.8  # Scale up when 80% busy
    IdleTerminationMinutes = 5
    
    # Agent skill definitions (Master decides these)
    AgentTypes = @{
        "coding" = @{
            Skills = @("code-generation", "refactoring", "bug-fixing")
            Model = "codellama:7b"
            MaxInstances = 3
        }
        "testing" = @{
            Skills = @("test-generation", "test-execution", "coverage-analysis")
            Model = "codellama:7b"
            MaxInstances = 2
        }
        "review" = @{
            Skills = @("code-review", "security-analysis", "quality-check")
            Model = "llama2:7b"
            MaxInstances = 2
        }
        "documentation" = @{
            Skills = @("readme-generation", "api-docs", "comments")
            Model = "llama2:7b"
            MaxInstances = 1
        }
        "deployment" = @{
            Skills = @("build", "deploy", "rollback", "smoke-test")
            Model = "codellama:7b"
            MaxInstances = 1
        }
        "git" = @{
            Skills = @("commit", "branch", "merge", "pull-request")
            Model = "llama2:7b"
            MaxInstances = 1
        }
    }
    
    # Paths
    Paths = @{
        AgentRegistry = "$scriptRoot\..\council\keys\agents-registry.json"
        ActiveAgents = "$scriptRoot\..\council\keys\active-agents.json"
        TaskQueue = "$scriptRoot\..\bus\inbox"
        Results = "$scriptRoot\..\bus\outbox"
        Logs = "$scriptRoot\..\logs"
    }
}

#region Helper Functions

function Write-MasterLog {
    param([string]$Message, [string]$Level = "INFO")
    
    $logEntry = @{
        timestamp = (Get-Date -Format "o")
        agent = "master-orchestrator"
        level = $Level
        message = $Message
    } | ConvertTo-Json -Compress
    
    Add-Content -Path "$($global:MasterConfig.Paths.Logs)\master.jsonl" -Value $logEntry
    
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "Cyan" }
    }
    
    Write-Host "[$Level] $Message" -ForegroundColor $color
}

function Invoke-LocalLLM {
    param(
        [string]$Prompt,
        [string]$SystemPrompt = "You are a helpful AI assistant for software development.",
        [int]$MaxTokens = 2048
    )
    
    try {
        $requestBody = @{
            model = $global:MasterConfig.Model
            prompt = $Prompt
            system = $SystemPrompt
            stream = $false
            options = @{
                temperature = 0.7
                num_predict = $MaxTokens
            }
        } | ConvertTo-Json -Depth 10
        
        $response = Invoke-RestMethod -Uri "$($global:MasterConfig.OllamaUrl)/api/generate" `
            -Method Post `
            -Body $requestBody `
            -ContentType "application/json" `
            -TimeoutSec 120
        
        return $response.response
    } catch {
        Write-MasterLog "LLM invocation failed: $_" -Level "ERROR"
        return $null
    }
}

function Get-AgentRegistry {
    $registryPath = $global:MasterConfig.Paths.AgentRegistry
    
    if (Test-Path $registryPath) {
        return Get-Content $registryPath | ConvertFrom-Json
    } else {
        # Initialize empty registry
        $registry = @{
            agents = @()
            last_updated = (Get-Date -Format "o")
        }
        
        $registry | ConvertTo-Json -Depth 10 | Set-Content $registryPath
        return $registry
    }
}

function Register-Agent {
    param(
        [string]$AgentId,
        [string]$Type,
        [array]$Skills,
        [string]$Status = "idle"
    )
    
    $registry = Get-AgentRegistry
    
    $agent = @{
        agent_id = $AgentId
        type = $Type
        skills = $Skills
        status = $Status
        created = (Get-Date -Format "o")
        last_heartbeat = (Get-Date -Format "o")
        tasks_completed = 0
        tasks_failed = 0
    }
    
    $registry.agents += $agent
    $registry.last_updated = (Get-Date -Format "o")
    
    $registry | ConvertTo-Json -Depth 10 | Set-Content $global:MasterConfig.Paths.AgentRegistry
    
    Write-MasterLog "Registered agent: $AgentId ($Type)" -Level "SUCCESS"
}

function Get-ActiveAgents {
    $registry = Get-AgentRegistry
    return $registry.agents | Where-Object { $_.status -ne "terminated" }
}

function Invoke-TaskAnalysis {
    param([string]$UserRequest)
    
    Write-MasterLog "Analyzing user request with AI..."
    
    $systemPrompt = @"
You are the Master Orchestrator for a multi-agent development system. Analyze the user's request and break it down into specific tasks.

For each task, specify:
1. Agent type needed (coding, testing, review, documentation, deployment, git)
2. Specific action to perform
3. Dependencies on other tasks
4. Estimated complexity (low, medium, high)

Respond in JSON format:
{
  "tasks": [
    {
      "id": "task-001",
      "agent_type": "coding",
      "action": "...",
      "dependencies": [],
      "complexity": "medium"
    }
  ],
  "agents_needed": {
    "coding": 1,
    "testing": 1
  }
}
"@
    
    $prompt = "User request: $UserRequest`n`nAnalyze and break down into tasks:"
    
    $response = Invoke-LocalLLM -Prompt $prompt -SystemPrompt $systemPrompt -MaxTokens 4096
    
    if ($response) {
        try {
            # Extract JSON from response (LLM might add explanation)
            if ($response -match '\{[\s\S]*\}') {
                $jsonMatch = $Matches[0]
                return $jsonMatch | ConvertFrom-Json
            }
        } catch {
            Write-MasterLog "Failed to parse AI response: $_" -Level "ERROR"
        }
    }
    
    return $null
}

function Invoke-TeamScaling {
    param([hashtable]$AgentsNeeded)
    
    Write-MasterLog "Determining team composition..."
    
    $activeAgents = Get-ActiveAgents
    $spawnCommands = @()
    
    foreach ($agentType in $AgentsNeeded.Keys) {
        $needed = $AgentsNeeded[$agentType]
        $existing = ($activeAgents | Where-Object { $_.type -eq $agentType }).Count
        
        if ($existing -lt $needed) {
            $toSpawn = $needed - $existing
            Write-MasterLog "Need to spawn $toSpawn x $agentType agents" -Level "WARN"
            
            for ($i = 1; $i -le $toSpawn; $i++) {
                $spawnCommands += @{
                    Type = $agentType
                    Index = $existing + $i
                }
            }
        } elseif ($existing -gt $needed) {
            Write-MasterLog "May terminate $(($existing - $needed)) idle $agentType agents" -Level "INFO"
        }
    }
    
    return $spawnCommands
}

function Start-Agent {
    param(
        [string]$Type,
        [int]$Index = 1
    )
    
    $agentId = "$Type-agent-$(Get-Date -Format 'yyyyMMddHHmmss')-$Index"
    $agentScript = "$scriptRoot\$Type\$Type-agent.ps1"
    
    if (-not (Test-Path $agentScript)) {
        Write-MasterLog "Agent script not found: $agentScript" -Level "ERROR"
        return $null
    }
    
    # Spawn agent in background
    $job = Start-Job -ScriptBlock {
        param($ScriptPath, $AgentId)
        & $ScriptPath -AgentId $AgentId -WatchMode
    } -ArgumentList $agentScript, $agentId
    
    # Register agent
    $skills = $global:MasterConfig.AgentTypes[$Type].Skills
    Register-Agent -AgentId $agentId -Type $Type -Skills $skills -Status "idle"
    
    Write-MasterLog "Spawned agent: $agentId (Job ID: $($job.Id))" -Level "SUCCESS"
    
    return @{
        AgentId = $agentId
        JobId = $job.Id
        Type = $Type
    }
}

function Invoke-TaskDispatch {
    param([array]$Tasks)
    
    Write-MasterLog "Dispatching $(($Tasks.Count)) tasks to agents..."
    
    foreach ($task in $Tasks) {
        # Create task packet
        $packet = @{
            packet_id = "pkt-$(New-Guid)"
            task_id = $task.id
            agent_type = $task.agent_type
            action = $task.action
            dependencies = $task.dependencies
            complexity = $task.complexity
            created = (Get-Date -Format "o")
            status = "pending"
        }
        
        # Write to inbox
        $filename = "$($packet.packet_id)-$($task.agent_type).json"
        $packet | ConvertTo-Json -Depth 10 | Set-Content "$($global:MasterConfig.Paths.TaskQueue)\$filename"
        
        Write-MasterLog "Dispatched task $($task.id) for $($task.agent_type)" -Level "INFO"
    }
}

function Invoke-MasterOrchestration {
    param([string]$UserRequest)
    
    Write-Host "`n========================================" -ForegroundColor Magenta
    Write-Host "  MASTER ORCHESTRATOR ACTIVATED" -ForegroundColor Magenta
    Write-Host "========================================`n" -ForegroundColor Magenta
    
    # Step 1: Analyze request with AI
    Write-Host "[PHASE 1] AI Task Analysis" -ForegroundColor Cyan
    $analysis = Invoke-TaskAnalysis -UserRequest $UserRequest
    
    if (-not $analysis) {
        Write-MasterLog "Failed to analyze request" -Level "ERROR"
        return
    }
    
    Write-Host "  ✓ Identified $($analysis.tasks.Count) tasks" -ForegroundColor Green
    Write-Host "  ✓ Agents needed: $($analysis.agents_needed | ConvertTo-Json -Compress)" -ForegroundColor Green
    
    # Step 2: Scale team
    Write-Host "`n[PHASE 2] Team Composition & Scaling" -ForegroundColor Cyan
    $spawnCommands = Invoke-TeamScaling -AgentsNeeded $analysis.agents_needed
    
    foreach ($cmd in $spawnCommands) {
        Start-Agent -Type $cmd.Type -Index $cmd.Index
        Start-Sleep -Milliseconds 500  # Stagger spawning
    }
    
    # Step 3: Dispatch tasks
    Write-Host "`n[PHASE 3] Task Dispatch" -ForegroundColor Cyan
    Invoke-TaskDispatch -Tasks $analysis.tasks
    
    # Step 4: Monitor execution
    Write-Host "`n[PHASE 4] Monitoring Execution" -ForegroundColor Cyan
    Write-Host "  Agents are now processing tasks..." -ForegroundColor Yellow
    Write-Host "  Check logs: $($global:MasterConfig.Paths.Logs)\master.jsonl`n" -ForegroundColor Cyan
}

#endregion

#region Main Execution

if ($WatchMode) {
    Write-Host "Master Orchestrator watching for requests..." -ForegroundColor Cyan
    Write-Host "Submit requests to: $($global:MasterConfig.Paths.TaskQueue)\master-request-*.json`n" -ForegroundColor Yellow
    
    while ($true) {
        # Watch for master request files
        $requests = Get-ChildItem "$($global:MasterConfig.Paths.TaskQueue)\master-request-*.json" -ErrorAction SilentlyContinue
        
        foreach ($request in $requests) {
            try {
                $requestData = Get-Content $request.FullName | ConvertFrom-Json
                Write-MasterLog "Processing request: $($requestData.user_request)"
                
                Invoke-MasterOrchestration -UserRequest $requestData.user_request
                
                # Move to processed
                Move-Item $request.FullName "$($global:MasterConfig.Paths.Results)\processed-$(Split-Path $request -Leaf)"
            } catch {
                Write-MasterLog "Error processing request: $_" -Level "ERROR"
            }
        }
        
        Start-Sleep -Seconds 5
    }
} elseif ($UserRequest) {
    Invoke-MasterOrchestration -UserRequest $UserRequest
} else {
    Write-Host "Master Orchestrator Agent v$($global:MasterConfig.Version)" -ForegroundColor Cyan
    Write-Host "`nUsage:" -ForegroundColor Yellow
    Write-Host "  .\master-orchestrator.ps1 -UserRequest `"Build a REST API`"" -ForegroundColor White
    Write-Host "  .\master-orchestrator.ps1 -WatchMode`n" -ForegroundColor White
}

#endregion
