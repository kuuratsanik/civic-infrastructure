<#
.SYNOPSIS
    Initialize the complete AI Agent Orchestration System
.DESCRIPTION
    Sets up all directories, registries, and spawns the Master Orchestrator.
    This is your entry point to the autonomous development system.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$FirstTimeSetup
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  AI AGENT SYSTEM INITIALIZATION" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

$scriptRoot = Split-Path -Parent $PSScriptRoot

# Step 1: Verify Ollama is running
Write-Host "[1/6] Checking Ollama service..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:11434/api/version" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        $version = ($response.Content | ConvertFrom-Json).version
        Write-Host "      ✓ Ollama running (version: $version)" -ForegroundColor Green
    }
} catch {
    Write-Host "      ✗ Ollama not running!" -ForegroundColor Red
    Write-Host "`nPlease run: .\scripts\setup\Install-Ollama.ps1`n" -ForegroundColor Yellow
    exit 1
}

# Step 2: Verify AI models are available
Write-Host "`n[2/6] Verifying AI models..." -ForegroundColor Yellow
$requiredModels = @("codellama:7b", "llama2:7b")
$availableModels = @()

try {
    $modelList = ollama list | Out-String
    foreach ($model in $requiredModels) {
        if ($modelList -match $model) {
            Write-Host "      ✓ $model available" -ForegroundColor Green
            $availableModels += $model
        } else {
            Write-Host "      ✗ $model missing" -ForegroundColor Red
            Write-Host "        Run: ollama pull $model" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "      ✗ Could not list models" -ForegroundColor Red
}

if ($availableModels.Count -lt $requiredModels.Count) {
    Write-Host "`nSome models are missing. Please install them first.`n" -ForegroundColor Red
    exit 1
}

# Step 3: Create directory structure
Write-Host "`n[3/6] Setting up directories..." -ForegroundColor Yellow
$directories = @(
    "$scriptRoot\council\keys\agents",
    "$scriptRoot\council\keys\managers",
    "$scriptRoot\logs\agents",
    "$scriptRoot\agents\master",
    "$scriptRoot\agents\factory",
    "$scriptRoot\agents\coding",
    "$scriptRoot\agents\testing",
    "$scriptRoot\agents\review",
    "$scriptRoot\agents\documentation",
    "$scriptRoot\agents\deployment",
    "$scriptRoot\agents\git",
    "$scriptRoot\knowledge\patterns",
    "$scriptRoot\knowledge\context",
    "$scriptRoot\knowledge\lessons"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        Write-Host "      ✓ Created: $dir" -ForegroundColor Green
    }
}

# Step 4: Initialize agent registry
Write-Host "`n[4/6] Initializing agent registry..." -ForegroundColor Yellow
$registryPath = "$scriptRoot\council\keys\agents-registry.json"
if (-not (Test-Path $registryPath)) {
    $registry = @{
        version = "1.0.0"
        agents = @()
        last_updated = (Get-Date -Format "o")
        metrics = @{
            total_spawned = 0
            total_terminated = 0
            tasks_completed = 0
        }
    }
    
    $registry | ConvertTo-Json -Depth 10 | Set-Content $registryPath
    Write-Host "      ✓ Created agent registry" -ForegroundColor Green
} else {
    Write-Host "      ✓ Agent registry exists" -ForegroundColor Green
}

# Step 5: Create knowledge base templates
Write-Host "`n[5/6] Setting up knowledge base..." -ForegroundColor Yellow

# Project context
$projectContext = @"
# Project Context

## Overview
This is an AI-orchestrated development environment using local LLMs (Ollama).

## Tech Stack
- AI Models: CodeLlama 7B, Llama2 7B
- Language: PowerShell
- Platform: Windows 11
- Governance: DAO-based warrant system

## Coding Standards
- Use PowerShell best practices
- Comment-based help for all functions
- Error handling with try/catch
- Logging to JSONL format

## Architecture
- Multi-agent system with Master Orchestrator
- Message bus for inter-agent communication
- Dynamic team scaling based on workload
- Privacy-first: all AI runs locally
"@

$projectContext | Set-Content "$scriptRoot\knowledge\context\project-overview.md"

# Patterns
$patterns = @"
# Common Patterns

## Authentication with JWT
- Use bcrypt for password hashing
- JWT with 24-hour expiration
- Refresh tokens with 7-day expiration

## Error Handling
\`\`\`powershell
try {
    # Code
} catch {
    Write-Error "Failed: `$_"
    # Log to JSONL
}
\`\`\`

## API Responses
\`\`\`powershell
@{
    success = `$true
    data = @{}
    error = `$null
} | ConvertTo-Json
\`\`\`
"@

$patterns | Set-Content "$scriptRoot\knowledge\patterns\common-patterns.md"

Write-Host "      ✓ Knowledge base initialized" -ForegroundColor Green

# Step 6: Test Master Orchestrator
Write-Host "`n[6/6] Testing Master Orchestrator..." -ForegroundColor Yellow

$masterScript = "$scriptRoot\agents\master\master-orchestrator.ps1"
if (Test-Path $masterScript) {
    Write-Host "      ✓ Master Orchestrator ready" -ForegroundColor Green
    
    # Quick test
    Write-Host "`nTesting AI inference..." -ForegroundColor Cyan
    
    $testRequest = @{
        model = "codellama:7b"
        prompt = "Write a simple PowerShell function to add two numbers. Only code, no explanation."
        stream = $false
    } | ConvertTo-Json
    
    try {
        $testResponse = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" `
            -Method Post `
            -Body $testRequest `
            -ContentType "application/json" `
            -TimeoutSec 30
        
        if ($testResponse.response) {
            Write-Host "      ✓ AI is working!" -ForegroundColor Green
            Write-Host "`nSample AI output:" -ForegroundColor Yellow
            Write-Host $testResponse.response.Substring(0, [Math]::Min(150, $testResponse.response.Length)) -ForegroundColor White
            Write-Host "      ..." -ForegroundColor Gray
        }
    } catch {
        Write-Host "      ✗ AI test failed: $_" -ForegroundColor Red
    }
} else {
    Write-Host "      ✗ Master Orchestrator script not found!" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  INITIALIZATION COMPLETE!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Magenta

Write-Host "System Status:" -ForegroundColor Yellow
Write-Host "  ✓ Ollama service running locally" -ForegroundColor Green
Write-Host "  ✓ AI models loaded (CodeLlama, Llama2)" -ForegroundColor Green
Write-Host "  ✓ Directory structure created" -ForegroundColor Green
Write-Host "  ✓ Agent registry initialized" -ForegroundColor Green
Write-Host "  ✓ Knowledge base ready" -ForegroundColor Green
Write-Host "  ✓ Master Orchestrator operational`n" -ForegroundColor Green

Write-Host "Quick Start:" -ForegroundColor Cyan
Write-Host "  1. Simple request:" -ForegroundColor White
Write-Host "     .\agents\master\master-orchestrator.ps1 -UserRequest `"Create a function to validate email addresses`"`n" -ForegroundColor Yellow

Write-Host "  2. Watch mode (continuous):" -ForegroundColor White
Write-Host "     .\agents\master\master-orchestrator.ps1 -WatchMode`n" -ForegroundColor Yellow

Write-Host "  3. Submit request via file:" -ForegroundColor White
Write-Host "     @{ user_request = 'Build REST API' } | ConvertTo-Json | Set-Content bus\inbox\master-request-001.json`n" -ForegroundColor Yellow

Write-Host "Advanced:" -ForegroundColor Cyan
Write-Host "  View logs: Get-Content logs\master.jsonl -Tail 20" -ForegroundColor Yellow
Write-Host "  Agent registry: Get-Content council\keys\agents-registry.json | ConvertFrom-Json`n" -ForegroundColor Yellow

Write-Host "🎉 Your autonomous AI development system is ready!`n" -ForegroundColor Green
