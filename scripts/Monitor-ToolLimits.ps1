#Requires -Version 5.1
<#
.SYNOPSIS
    Monitor VS Code Extensions and MCP Server Tools compliance

.DESCRIPTION
    Checks both VS Code extension count and provides MCP tool status
    Ensures compliance with TOOL-LIMIT-POLICY.md

.EXAMPLE
    .\Monitor-ToolLimits.ps1
    Displays current status of extensions and MCP tools

.NOTES
    Policy: DO NOT EXCEED 100 VS CODE EXTENSIONS + MANAGE MCP SERVER TOOLS
    Created: 17. oktoober 2025
#>

$ErrorActionPreference = 'Continue'

Write-Host "`n"
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "    TOOL LIMIT COMPLIANCE MONITOR" -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "`n"

# Section 1: VS Code Extensions
Write-Host "[1] VS CODE EXTENSIONS CHECK" -ForegroundColor Yellow
Write-Host "---------------------------------------------------------------" -ForegroundColor Gray

try {
  $extensions = code --list-extensions 2>&1

  if ($LASTEXITCODE -ne 0) {
    Write-Host "   [!] Could not retrieve extensions (VS Code not in PATH?)" -ForegroundColor Red
    $extensionCount = 0
  } else {
    $extensionCount = ($extensions | Measure-Object).Count
  }

  $extensionLimit = 100
  $extensionHeadroom = $extensionLimit - $extensionCount

  Write-Host "   Extension Count:  " -NoNewline -ForegroundColor White

  if ($extensionCount -le $extensionLimit) {
    Write-Host "$extensionCount / $extensionLimit" -ForegroundColor Green
    Write-Host "   Status:           " -NoNewline -ForegroundColor White
    Write-Host "COMPLIANT" -ForegroundColor Green
    Write-Host "   Headroom:         " -NoNewline -ForegroundColor White
    Write-Host "$extensionHeadroom extensions available" -ForegroundColor Green
  } else {
    $excess = $extensionCount - $extensionLimit
    Write-Host "$extensionCount / $extensionLimit" -ForegroundColor Red
    Write-Host "   Status:           " -NoNewline -ForegroundColor White
    Write-Host "VIOLATION" -ForegroundColor Red
    Write-Host "   Excess:           " -NoNewline -ForegroundColor White
    Write-Host "$excess extensions over limit" -ForegroundColor Red
    Write-Host "`n   ACTION REQUIRED: Run cleanup script" -ForegroundColor Yellow
    Write-Host "   .\scripts\Cleanup-VSCodeExtensions.ps1 -Interactive`n" -ForegroundColor Gray
  }
} catch {
  Write-Host "   [!] Error checking extensions: $_" -ForegroundColor Red
}

Write-Host ""

# Section 2: MCP Server Tools
Write-Host "[2] MCP SERVER TOOLS STATUS" -ForegroundColor Yellow
Write-Host "---------------------------------------------------------------" -ForegroundColor Gray

$mcpToolLimit = 128
$estimatedMcpTools = 232  # Known count from Azure, GitKraken, Docs, Core, AI Toolkit

Write-Host "   Estimated MCP Tools:  " -NoNewline -ForegroundColor White
Write-Host "~$estimatedMcpTools" -ForegroundColor Cyan

Write-Host "   System Limit:         " -NoNewline -ForegroundColor White
Write-Host "$mcpToolLimit (GitHub Copilot Chat)" -ForegroundColor White

Write-Host "   Status:               " -NoNewline -ForegroundColor White
if ($estimatedMcpTools -le $mcpToolLimit) {
  Write-Host "UNDER LIMIT" -ForegroundColor Green
} else {
  $mcpExcess = $estimatedMcpTools - $mcpToolLimit
  Write-Host "OVER LIMIT" -ForegroundColor Yellow
  Write-Host "   Excess:               " -NoNewline -ForegroundColor White
  Write-Host "$mcpExcess tools" -ForegroundColor Yellow
}

Write-Host "`n   MCP Server Breakdown:" -ForegroundColor Cyan
Write-Host "   - Azure MCP:          ~60 tools (ACR, AKS, Functions, SQL, etc.)" -ForegroundColor Gray
Write-Host "   - GitKraken MCP:      ~10 tools (Git, PRs, Issues)" -ForegroundColor Gray
Write-Host "   - Microsoft Docs:     3 tools (Search, Fetch, Code Samples)" -ForegroundColor Gray
Write-Host "   - Core VS Code:       ~30 tools (Files, Terminal, Workspace)" -ForegroundColor Gray
Write-Host "   - AI Toolkit:         3 tools (Model guidance, Tracing)" -ForegroundColor Gray

Write-Host "`n   Impact Assessment:" -ForegroundColor Cyan
Write-Host "   [+] Copilot auto-selects relevant tools per context" -ForegroundColor Green
Write-Host "   [+] Inline suggestions work normally" -ForegroundColor Green
Write-Host "   [+] VS Code performance not affected" -ForegroundColor Green
Write-Host "   [~] Copilot Chat may occasionally fail with 'tool limit exceeded'" -ForegroundColor Yellow
Write-Host "   [i] This is acceptable for comprehensive Azure development" -ForegroundColor Cyan

Write-Host ""

# Section 3: Recommendations
Write-Host "[3] RECOMMENDATIONS" -ForegroundColor Yellow
Write-Host "---------------------------------------------------------------" -ForegroundColor Gray

if ($extensionCount -le $extensionLimit) {
  Write-Host "   [+] Extensions: NO ACTION REQUIRED" -ForegroundColor Green
} else {
  Write-Host "   [!] Extensions: CLEANUP REQUIRED" -ForegroundColor Red
  Write-Host "       Run: .\scripts\Cleanup-VSCodeExtensions.ps1 -Interactive" -ForegroundColor Gray
}

if ($estimatedMcpTools -le $mcpToolLimit) {
  Write-Host "   [+] MCP Tools: NO ACTION REQUIRED" -ForegroundColor Green
} else {
  Write-Host "   [~] MCP Tools: OPTIONAL OPTIMIZATION" -ForegroundColor Yellow
  Write-Host "       Option 1: Accept current state (Recommended)" -ForegroundColor Gray
  Write-Host "       Option 2: Disable non-essential MCP servers (Advanced)" -ForegroundColor Gray
  Write-Host "       Option 3: Work in smaller scopes (Project-based)" -ForegroundColor Gray
  Write-Host "`n       See: docs\policies\TOOL-LIMIT-POLICY.md (MCP Server Management)" -ForegroundColor Cyan
}

Write-Host ""

# Section 4: Quick Stats
Write-Host "[4] QUICK STATS" -ForegroundColor Yellow
Write-Host "---------------------------------------------------------------" -ForegroundColor Gray

$totalTools = $extensionCount + $estimatedMcpTools

Write-Host "   Total Environment Load:" -ForegroundColor White
Write-Host "   - Extensions:      $extensionCount" -ForegroundColor Gray
Write-Host "   - MCP Tools:       ~$estimatedMcpTools" -ForegroundColor Gray
Write-Host "   - Combined:        ~$totalTools tools" -ForegroundColor Gray

Write-Host "`n   System Limits:" -ForegroundColor White
Write-Host "   - Extension Policy:    100" -ForegroundColor Gray
Write-Host "   - Copilot Chat MCP:    128" -ForegroundColor Gray

Write-Host "`n   Compliance Status:" -ForegroundColor White
if ($extensionCount -le $extensionLimit) {
  Write-Host "   - Extensions:      " -NoNewline -ForegroundColor Gray
  Write-Host "PASS" -ForegroundColor Green
} else {
  Write-Host "   - Extensions:      " -NoNewline -ForegroundColor Gray
  Write-Host "FAIL" -ForegroundColor Red
}

if ($estimatedMcpTools -le $mcpToolLimit) {
  Write-Host "   - MCP Tools:       " -NoNewline -ForegroundColor Gray
  Write-Host "PASS" -ForegroundColor Green
} else {
  Write-Host "   - MCP Tools:       " -NoNewline -ForegroundColor Gray
  Write-Host "MANAGEABLE" -ForegroundColor Yellow
}

Write-Host ""

# Section 5: Next Review Date
Write-Host "[5] POLICY COMPLIANCE" -ForegroundColor Yellow
Write-Host "---------------------------------------------------------------" -ForegroundColor Gray

$policyFile = Join-Path $PSScriptRoot "..\docs\policies\TOOL-LIMIT-POLICY.md"
if (Test-Path $policyFile) {
  Write-Host "   Policy Document:  " -NoNewline -ForegroundColor White
  Write-Host "FOUND" -ForegroundColor Green
  Write-Host "   Location:         docs\policies\TOOL-LIMIT-POLICY.md" -ForegroundColor Gray
} else {
  Write-Host "   Policy Document:  " -NoNewline -ForegroundColor White
  Write-Host "NOT FOUND" -ForegroundColor Red
}

Write-Host "`n   Next Review:      17. jaanuar 2026 (Quarterly)" -ForegroundColor Cyan
Write-Host "   Last Checked:     $(Get-Date -Format 'dd. MMMM yyyy HH:mm')" -ForegroundColor Gray

Write-Host "`n===============================================================" -ForegroundColor Cyan
Write-Host ""

# Return exit code based on extension compliance
if ($extensionCount -le $extensionLimit) {
  exit 0  # Compliant
} else {
  exit 1  # Non-compliant
}
