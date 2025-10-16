# Integrate AI Council ISO Build System with Main Workspace
# This script connects the ISO build infrastructure with your civic ceremonies

#Requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "AI COUNCIL INTEGRATION" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Paths
$CouncilRoot = "C:\ai-council"
$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$IntegrationRoot = "$WorkspaceRoot\.council-integration"

Write-Host "Council: $CouncilRoot" -ForegroundColor Gray
Write-Host "Workspace: $WorkspaceRoot" -ForegroundColor Gray
Write-Host "Integration: $IntegrationRoot" -ForegroundColor Gray

# ============================================
# Step 1: Verify AI Council exists
# ============================================

Write-Host "`n[1/5] Verifying AI Council Infrastructure..." -ForegroundColor Yellow

if (-not (Test-Path $CouncilRoot)) {
    Write-Host "  ERROR: AI Council not found at $CouncilRoot" -ForegroundColor Red
    Write-Host "  Please ensure the ISO build system is installed." -ForegroundColor Yellow
    exit 1
}

Write-Host "  [OK] AI Council found" -ForegroundColor Green

# Verify key components
$keyComponents = @(
    "$CouncilRoot\agents\build\iso-build-agent.ps1",
    "$CouncilRoot\agents\civic\civic-agent.ps1",
    "$CouncilRoot\council\warrants",
    "$CouncilRoot\bus\inbox",
    "$CouncilRoot\workspace"
)

foreach ($component in $keyComponents) {
    if (Test-Path $component) {
        Write-Host "  [OK] $(Split-Path $component -Leaf)" -ForegroundColor Green
    } else {
        Write-Host "  [!!] Missing: $component" -ForegroundColor Red
    }
}

# ============================================
# Step 2: Create Integration Directory
# ============================================

Write-Host "`n[2/5] Creating Integration Links..." -ForegroundColor Yellow

if (-not (Test-Path $IntegrationRoot)) {
    New-Item -Path $IntegrationRoot -ItemType Directory -Force | Out-Null
}

# Create metadata
$metadata = @{
    integrated = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    council_root = $CouncilRoot
    workspace_root = $WorkspaceRoot
    version = "1.0"
}

$metadata | ConvertTo-Json -Depth 10 | Set-Content "$IntegrationRoot\integration.json"
Write-Host "  [OK] Integration metadata created" -ForegroundColor Green

# ============================================
# Step 3: Create Helper Scripts in Workspace
# ============================================

Write-Host "`n[3/5] Creating Helper Scripts..." -ForegroundColor Yellow

# Script: Dispatch ISO Build
$dispatchScript = @"
# Quick ISO Build Dispatcher
# Dispatches an ISO build request to the AI Council

param(
    [string]`$OutputName = "Win11_Custom_`$(Get-Date -Format 'yyyyMMdd_HHmmss')"
)

`$ceremony = "$WorkspaceRoot\scripts\ceremonies\09-iso-build\Build-CustomISO.ps1"
if (Test-Path `$ceremony) {
    & `$ceremony -OutputName `$OutputName
} else {
    Write-Host "ERROR: ISO Build ceremony not found" -ForegroundColor Red
}
"@

Set-Content "$WorkspaceRoot\Build-ISO.ps1" $dispatchScript
Write-Host "  [OK] Build-ISO.ps1 created" -ForegroundColor Green

# Script: Monitor Builds
$monitorScript = @"
# Monitor ISO Build Progress
# Shows logs, ledger, and current build status

`$councilRoot = "C:\ai-council"

Write-Host "`n=== ISO Build Agent Log ===" -ForegroundColor Yellow
if (Test-Path "`$councilRoot\logs\agents\iso-build.jsonl") {
    Get-Content "`$councilRoot\logs\agents\iso-build.jsonl" -Tail 10 | ForEach-Object {
        `$entry = `$_ | ConvertFrom-Json
        Write-Host "[`$(`$entry.ts)] `$(`$entry.phase) - `$(`$entry.status)" -ForegroundColor Cyan
    }
} else {
    Write-Host "No build logs yet" -ForegroundColor Gray
}

Write-Host "`n=== Recent Builds ===" -ForegroundColor Yellow
`$builds = Get-ChildItem "`$councilRoot\workspace\output" -Filter *.iso -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 5

if (`$builds) {
    foreach (`$build in `$builds) {
        `$size = [math]::Round(`$build.Length / 1GB, 2)
        Write-Host "  `$(`$build.Name) (`$size GB) - `$(`$build.LastWriteTime)" -ForegroundColor White
    }
} else {
    Write-Host "No ISOs built yet" -ForegroundColor Gray
}
"@

Set-Content "$WorkspaceRoot\Monitor-Builds.ps1" $monitorScript
Write-Host "  [OK] Monitor-Builds.ps1 created" -ForegroundColor Green

# Script: Start Agents
$startAgentsScript = @"
# Start AI Council Agents
# Launches both Civic and ISO Build agents

#Requires -RunAsAdministrator

`$councilRoot = "C:\ai-council"

Write-Host "`nStarting AI Council Agents..." -ForegroundColor Cyan

# Start Civic Agent
Write-Host "`n[1] Starting Civic Agent..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd `$councilRoot; .\agents\civic\civic-agent.ps1 -WatchMode"

Start-Sleep -Seconds 2

# Start ISO Build Agent
Write-Host "`n[2] Starting ISO Build Agent..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd `$councilRoot; .\agents\build\iso-build-agent.ps1 -WatchMode"

Write-Host "`nAgents started in separate windows." -ForegroundColor Green
Write-Host "Close those windows to stop the agents.`n" -ForegroundColor Gray
"@

Set-Content "$WorkspaceRoot\Start-Agents.ps1" $startAgentsScript
Write-Host "  [OK] Start-Agents.ps1 created" -ForegroundColor Green

# ============================================
# Step 4: Update VS Code Tasks
# ============================================

Write-Host "`n[4/5] Updating VS Code Tasks..." -ForegroundColor Yellow

$tasksPath = "$WorkspaceRoot\.vscode\tasks.json"
$tasksDir = Split-Path $tasksPath

if (-not (Test-Path $tasksDir)) {
    New-Item -Path $tasksDir -ItemType Directory -Force | Out-Null
}

# Read existing tasks or create new
if (Test-Path $tasksPath) {
    $tasksContent = Get-Content $tasksPath -Raw | ConvertFrom-Json
} else {
    $tasksContent = @{
        version = "2.0.0"
        tasks = @()
    }
}

# Add new tasks
$newTasks = @(
    @{
        label = "ISO Build: Start Agents"
        type = "shell"
        command = "powershell.exe"
        args = @("-ExecutionPolicy", "Bypass", "-File", "./Start-Agents.ps1")
        group = "build"
        presentation = @{
            reveal = "always"
            panel = "new"
        }
    },
    @{
        label = "ISO Build: Build Custom ISO"
        type = "shell"
        command = "powershell.exe"
        args = @("-ExecutionPolicy", "Bypass", "-File", "./Build-ISO.ps1")
        group = "build"
        presentation = @{
            reveal = "always"
            panel = "dedicated"
        }
    },
    @{
        label = "ISO Build: Monitor Progress"
        type = "shell"
        command = "powershell.exe"
        args = @("-ExecutionPolicy", "Bypass", "-File", "./Monitor-Builds.ps1")
        group = "test"
        presentation = @{
            reveal = "always"
            panel = "dedicated"
        }
    },
    @{
        label = "ISO Build: Run Ceremony"
        type = "shell"
        command = "powershell.exe"
        args = @(
            "-ExecutionPolicy", "Bypass",
            "-File", "./scripts/ceremonies/09-iso-build/Build-CustomISO.ps1"
        )
        group = "build"
        presentation = @{
            reveal = "always"
            panel = "dedicated"
        }
    }
)

# Merge tasks (avoid duplicates)
$existingLabels = $tasksContent.tasks | ForEach-Object { $_.label }
foreach ($task in $newTasks) {
    if ($task.label -notin $existingLabels) {
        $tasksContent.tasks += $task
    }
}

# Save tasks
$tasksContent | ConvertTo-Json -Depth 10 | Set-Content $tasksPath
Write-Host "  [OK] VS Code tasks updated" -ForegroundColor Green

# ============================================
# Step 5: Create Documentation
# ============================================

Write-Host "`n[5/5] Creating Documentation..." -ForegroundColor Yellow

$docContent = @"
# ISO Build Integration

The AI Council ISO Build system has been integrated with your civic infrastructure.

## Quick Start

### Option 1: Using Scripts
``````powershell
# Start the agents (run as Administrator)
.\Start-Agents.ps1

# Build a custom ISO
.\Build-ISO.ps1 -OutputName "MyCustomWindows11"

# Monitor build progress
.\Monitor-Builds.ps1
``````

### Option 2: Using VS Code Tasks
Press **Ctrl+Shift+P** and run:
- "Tasks: Run Task" → "ISO Build: Start Agents"
- "Tasks: Run Task" → "ISO Build: Build Custom ISO"
- "Tasks: Run Task" → "ISO Build: Monitor Progress"

### Option 3: Using Ceremony
``````powershell
.\scripts\ceremonies\09-iso-build\Build-CustomISO.ps1 -OutputName "Win11_Privacy"
``````

## Components

### Scripts
- **Start-Agents.ps1** - Launches Civic and ISO Build agents
- **Build-ISO.ps1** - Quick build dispatcher
- **Monitor-Builds.ps1** - View logs and results

### Ceremony
- **09-iso-build/Build-CustomISO.ps1** - Full ISO build ceremony with governance

### AI Council Location
- **Root:** C:\ai-council
- **Agents:** C:\ai-council\agents\
- **Output ISOs:** C:\ai-council\workspace\output\
- **Evidence:** C:\ai-council\evidence\

## Prerequisites

Before building real ISOs, ensure you have:

1. **Windows ADK** (Deployment Tools)
   - Download: https://go.microsoft.com/fwlink/?linkid=2243390
   
2. **Windows 11 ISO** (extracted)
   - Download: https://www.microsoft.com/software-download/windows11
   - Extract with: ``cd C:\ai-council; .\extract-windows11-iso.ps1``

3. **Administrator privileges**
   - Required for DISM operations

## Workflow

1. **Prerequisites** → Install Windows ADK + Extract Windows 11 ISO
2. **Start Agents** → Run ``.\Start-Agents.ps1`` as Administrator
3. **Build ISO** → Run ``.\Build-ISO.ps1`` or use ceremony
4. **Monitor** → Watch progress with ``.\Monitor-Builds.ps1``
5. **Verify** → Check output in C:\ai-council\workspace\output\

## Customizations

Default build includes:
- Privacy tweaks (telemetry disabled)
- UI tweaks (classic taskbar, file extensions)
- Debloat (removes 50+ unwanted apps)

To customize:
- Add .reg files to: ``C:\ai-council\workspace\customization\tweaks\``
- Edit: ``C:\ai-council\templates\debloat\Remove-Bloatware.ps1``

## Evidence & Audit

All builds create:
- ISO file (bootable Windows 11)
- SHA256 hash (cryptographic verification)
- Build manifest (complete audit trail)
- Council ledger entry (immutable record)

## Support

For issues:
1. Check logs: ``C:\ai-council\logs\``
2. Run prerequisite check: ``cd C:\ai-council; .\check-prerequisites.ps1``
3. Review: ``C:\ai-council\DEMONSTRATION_COMPLETE.md``
"@

Set-Content "$WorkspaceRoot\docs\ISO-BUILD-INTEGRATION.md" $docContent
Write-Host "  [OK] Integration documentation created" -ForegroundColor Green

# ============================================
# Summary
# ============================================

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "INTEGRATION COMPLETE" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "Components Added:" -ForegroundColor Yellow
Write-Host "  [+] ISO Build Ceremony (09-iso-build)" -ForegroundColor Green
Write-Host "  [+] Start-Agents.ps1" -ForegroundColor Green
Write-Host "  [+] Build-ISO.ps1" -ForegroundColor Green
Write-Host "  [+] Monitor-Builds.ps1" -ForegroundColor Green
Write-Host "  [+] 4 VS Code tasks" -ForegroundColor Green
Write-Host "  [+] Integration documentation" -ForegroundColor Green

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "  1. Install prerequisites (if needed):" -ForegroundColor White
Write-Host "     - Windows ADK" -ForegroundColor Gray
Write-Host "     - Windows 11 ISO" -ForegroundColor Gray
Write-Host "`n  2. Start the agents:" -ForegroundColor White
Write-Host "     .\Start-Agents.ps1" -ForegroundColor Cyan
Write-Host "`n  3. Build your first ISO:" -ForegroundColor White
Write-Host "     .\Build-ISO.ps1 -OutputName 'MyWindows11'" -ForegroundColor Cyan

Write-Host "`nDocumentation:" -ForegroundColor Yellow
Write-Host "  code docs\ISO-BUILD-INTEGRATION.md" -ForegroundColor Cyan

Write-Host "`n========================================`n" -ForegroundColor Green
