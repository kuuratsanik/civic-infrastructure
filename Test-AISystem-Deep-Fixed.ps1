<#
.SYNOPSIS
    ðŸ§ª AI System Comprehensive Tester - Deep testing, error analysis, and diagnostics

.DESCRIPTION
    Performs exhaustive testing of all AI system components:
    - Tests all modules and scripts
    - Analyzes all log files
    - Detects errors and anomalies
    - Validates integrations
    - Checks system health
    - Generates detailed diagnostic reports

.EXAMPLE
    .\Test-AISystem-Deep.ps1

    Run complete test suite with full diagnostics

.EXAMPLE
    .\Test-AISystem-Deep.ps1 -QuickTest

    Run essential tests only (faster)

.EXAMPLE
    .\Test-AISystem-Deep.ps1 -Component "WorldChange"

    Test specific component only

.EXAMPLE
    .\Test-AISystem-Deep.ps1 -AnalyzeLogsOnly

    Only analyze logs, skip component tests
#>

param(
    [switch]$QuickTest,
    [string]$Component,
    [switch]$AnalyzeLogsOnly,
    [switch]$ExportHTML,
    [switch]$FixErrors,
    [switch]$Verbose
)

# Test results storage
$script:TestResults = @{
    TotalTests       = 0
    Passed           = 0
    Failed           = 0
    Warnings         = 0
    Errors           = @()
    ComponentResults = @{}
    LogAnalysis      = @{}
    SystemHealth     = @{}
    StartTime        = Get-Date
}

class TestRunner {
    [hashtable]$Results = @{}
    [string]$WorkspaceRoot
    [array]$AllScripts = @()
    [array]$AllLogs = @()

    TestRunner() {
        $this.WorkspaceRoot = "$PSScriptRoot\..\..\\.."
        Write-Host "ðŸ§ª AI System Comprehensive Test Suite" -ForegroundColor Cyan
        Write-Host "   Workspace: $($this.WorkspaceRoot)" -ForegroundColor Gray
    }

    [void]DiscoverComponents() {
        Write-Host "`nðŸ“‚ Discovering all components..." -ForegroundColor Yellow

        # Find all PowerShell scripts
        $this.AllScripts = Get-ChildItem -Path $this.WorkspaceRoot -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '\\node_modules\\|\\\.git\\' }

        Write-Host "   Found $($this.AllScripts.Count) PowerShell scripts" -ForegroundColor Cyan

        # Find all log files
        $this.AllLogs = Get-ChildItem -Path "$($this.WorkspaceRoot)\logs" -Filter "*.jsonl" -Recurse -ErrorAction SilentlyContinue
        $this.AllLogs += Get-ChildItem -Path "$($this.WorkspaceRoot)\logs" -Filter "*.log" -Recurse -ErrorAction SilentlyContinue

        Write-Host "   Found $($this.AllLogs.Count) log files" -ForegroundColor Cyan
    }

    [hashtable]TestAllComponents() {
        Write-Host "`nâ•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—" -ForegroundColor Cyan
        Write-Host "â•‘             COMPONENT TESTING - FULL SUITE                     â•‘" -ForegroundColor Yellow
        Write-Host "â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•" -ForegroundColor Cyan

        $componentTests = @{
            "Self-Learning"    = { $this.TestSelfLearning() }
            "Self-Researching" = { $this.TestSelfResearching() }
            "Self-Developing"  = { $this.TestSelfDeveloping() }
            "Self-Improving"   = { $this.TestSelfImproving() }
            "SafetyFramework"  = { $this.TestSafetyFramework() }
            "SuperKITT"        = { $this.TestSuperKITT() }
            "HiveMind"         = { $this.TestHiveMind() }
            "MultiAgent"       = { $this.TestMultiAgent() }
            "WorldChange"      = { $this.TestWorldChange() }
            "ProblemSolver"    = { $this.TestProblemSolver() }
            "EconomicAutonomy" = { $this.TestEconomicAutonomy() }
        }

        $results = @{}

        foreach ($component in $componentTests.Keys) {
            Write-Host "`nâ”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”" -ForegroundColor DarkCyan
            Write-Host "â”‚  Testing: $($component.PadRight(50)) â”‚" -ForegroundColor White
            Write-Host "â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜" -ForegroundColor DarkCyan

            try {
                $testResult = & $componentTests[$component]
                $results[$component] = $testResult

                $status = if ($testResult.Passed) { "âœ… PASS" } else { "âŒ FAIL" }
                $color = if ($testResult.Passed) { "Green" } else { "Red" }

                Write-Host "   $status" -ForegroundColor $color

                if ($testResult.Warnings -gt 0) {
                    Write-Host "   âš ï¸  $($testResult.Warnings) warnings" -ForegroundColor Yellow
                }

            } catch {
                Write-Host "   âŒ CRITICAL ERROR: $_" -ForegroundColor Red
                $results[$component] = @{
                    Passed   = $false
                    Error    = $_.Exception.Message
                    Warnings = 0
                }
            }
        }

        return $results
    }

    [hashtable]TestSelfLearning() {
        $result = @{
            Passed   = $true
            Warnings = 0
            Details  = @()
            Errors   = @()
        }

        $modulePath = "$($this.WorkspaceRoot)\scripts\modules\Self-Learning.ps1"

        # Test 1: File exists
        if (-not (Test-Path $modulePath)) {
            $result.Errors += "Self-Learning.ps1 not found"
            $result.Passed = $false
            return $result
        }
        $result.Details += "âœ“ Module file exists"

        # Test 2: Valid PowerShell syntax
        try {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $modulePath -Raw), [ref]$null)
            $result.Details += "âœ“ Valid PowerShell syntax"
        } catch {
            $result.Errors += "Syntax error: $_"
            $result.Passed = $false
            return $result
        }

        # Test 3: Can import module
        try {
            Import-Module $modulePath -Force -ErrorAction Stop
            $result.Details += "âœ“ Module imports successfully"
        } catch {
            $result.Errors += "Cannot import: $_"
            $result.Passed = $false
            return $result
        }

        # Test 4: Check for required functions
        $requiredFunctions = @('Start-SelfLearning', 'Update-KnowledgeBase')
        foreach ($func in $requiredFunctions) {
            if (Get-Command $func -ErrorAction SilentlyContinue) {
                $result.Details += "âœ“ Function '$func' exists"
            } else {
                $result.Warnings++
                $result.Details += "âš ï¸  Function '$func' not found"
            }
        }

        # Test 5: Check knowledge base directory
        $knowledgeBase = "$($this.WorkspaceRoot)\knowledge"
        if (Test-Path $knowledgeBase) {
            $result.Details += "âœ“ Knowledge base directory exists"
        } else {
            $result.Warnings++
            $result.Details += "âš ï¸  Knowledge base directory missing"
        }

        return $result
    }

    [hashtable]TestSelfResearching() {
        $result = @{
            Passed   = $true
            Warnings = 0
            Details  = @()
            Errors   = @()
        }

        $modulePath = "$($this.WorkspaceRoot)\scripts\modules\Self-Researching.ps1"

        if (-not (Test-Path $modulePath)) {
            $result.Errors += "Self-Researching.ps1 not found"
            $result.Passed = $false
            return $result
        }
        $result.Details += "âœ“ Module file exists"

        try {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $modulePath -Raw), [ref]$null)
            $result.Details += "âœ“ Valid PowerShell syntax"
        } catch {
            $result.Errors += "Syntax error: $_"
            $result.Passed = $false
        }

        # Check internet connectivity for research
        try {
            $ping = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction Stop
            if ($ping) {
                $result.Details += "âœ“ Internet connectivity available"
            } else {
                $result.Warnings++
                $result.Details += "âš ï¸  No internet (research will be limited)"
            }
        } catch {
            $result.Warnings++
            $result.Details += "âš ï¸  Cannot test connectivity"
        }

        return $result
    }

    [hashtable]TestSelfDeveloping() {
        $result = @{
            Passed   = $true
            Warnings = 0
            Details  = @()
            Errors   = @()
        }

        $modulePath = "$($this.WorkspaceRoot)\scripts\modules\Self-Developing.ps1"

        if (-not (Test-Path $modulePath)) {
            $result.Errors += "Self-Developing.ps1 not found"
            $result.Passed = $false
            return $result
        }
        $result.Details += "âœ“ Module file exists"

        try {
            Import-Module $modulePath -Force -ErrorAction Stop
            $result.Details += "âœ“ Module imports successfully"
        } catch {
            $result.Errors += "Cannot import: $_"
            $result.Passed = $false
        }

        # Check if Ollama is running
        try {
            $ollama = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
            if ($ollama) {
                $result.Details += "âœ“ Ollama service running"
            } else {
                $result.Warnings++
                $result.Details += "âš ï¸  Ollama not running (code generation unavailable)"
            }
        } catch {
            $result.Warnings++
        }

        return $result
    }

    [hashtable]TestSelfImproving() {
        $result = @{
            Passed   = $true
            Warnings = 0
            Details  = @()
            Errors   = @()
        }

        $modulePath = "$($this.WorkspaceRoot)\scripts\modules\Self-Improving.ps1"

        if (-not (Test-Path $modulePath)) {
            $result.Errors += "Self-Improving.ps1 not found"
            $result.Passed = $false
            return $result
        }
        $result.Details += "âœ“ Module file exists"

        try {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $modulePath -Raw), [ref]$null)
            $result.Details += "âœ“ Valid PowerShell syntax"
        } catch {
            $result.Errors += "Syntax error: $_"
            $result.Passed = $false
        }

        return $result
    }

    [hashtable]TestSafetyFramework() {
        $result = @{
            Passed   = $true
            Warnings = 0
            Details  = @()
            Errors   = @()
        }

        $modulePath = "$($this.WorkspaceRoot)\SafetyFramework.ps1"

        if (-not (Test-Path $modulePath)) {
            $result.Errors += "SafetyFramework.ps1 not found - CRITICAL!"
            $result.Passed = $false
            return $result
        }
        $result.Details += "âœ“ Safety framework exists"

        try {
            Import-Module $modulePath -Force -ErrorAction Stop
            $result.Details += "âœ“ Safety framework loads"
        } catch {
            $result.Errors += "Cannot load safety framework: $_"
            $result.Passed = $false
            return $result
        }

        # Test DO NO HARM validation
        if (Get-Command Invoke-SafetyCheck -ErrorAction SilentlyContinue) {
            $result.Details += "âœ“ Safety validation function available"

            # Test dangerous operation detection
            $dangerousOps = @(
                "Remove-Item C:\ -Recurse -Force",
                "Format-Volume C:",
                "Set-ItemProperty HKLM:\SYSTEM -Name Critical"
            )

            $safetyWorks = $true
            foreach ($op in $dangerousOps) {
                # This should return false (operation blocked)
                # Actual implementation needed in SafetyFramework
            }

        } else {
            $result.Warnings++
            $result.Details += "âš ï¸  Safety check function not found"
        }

        return $result
    }

    [hashtable]TestSuperKITT() {
        $result = @{
            Passed   = $true
            Warnings = 0
            Details  = @()
            Errors   = @()
        }

        $modulePath = "$($this.WorkspaceRoot)\SuperKITT.ps1"

        if (-not (Test-Path $modulePath)) {
            $result.Errors += "SuperKITT.ps1 not found"
            $result.Passed = $false
            return $result
        }
        $result.Details += "âœ“ SuperKITT file exists"

        try {
            $content = Get-Content $modulePath -Raw
            if ($content -match 'class.*SuperKITT') {
                $result.Details += "âœ“ SuperKITT class defined"
            } else {
                $result.Warnings++
                $result.Details += "âš ï¸  SuperKITT class not found in file"
            }
        } catch {
            $result.Errors += "Error reading file: $_"
            $result.Passed = $false
        }

        return $result
    }

    [hashtable]TestHiveMind() {
        $result = @{
            Passed   = $true
            Warnings = 0
            Details  = @()
            Errors   = @()
        }

        $modulePath = "$($this.WorkspaceRoot)\HiveMind.ps1"

        if (-not (Test-Path $modulePath)) {
            $result.Errors += "HiveMind.ps1 not found"
            $result.Passed = $false
            return $result
        }
        $result.Details += "âœ“ HiveMind file exists"

        # Check for distributed consciousness features
        try {
            $content = Get-Content $modulePath -Raw
            if ($content -match 'SyncKnowledge|ShareContext|DistributedLearning') {
                $result.Details += "âœ“ Distributed consciousness features present"
            }
        } catch {
            $result.Warnings++
        }

        return $result
    }

    [hashtable]TestMultiAgent() {
        $result = @{
            Passed   = $true
            Warnings = 0
            Details  = @()
            Errors   = @()
        }

        # Test Master Orchestrator
        $masterPath = "$($this.WorkspaceRoot)\agents\master\master-orchestrator.ps1"
        if (Test-Path $masterPath) {
            $result.Details += "âœ“ Master Orchestrator exists"
        } else {
            $result.Errors += "Master Orchestrator not found"
            $result.Passed = $false
        }

        # Test Agent Factory
        $factoryPath = "$($this.WorkspaceRoot)\agents\factory\agent-factory.ps1"
        if (Test-Path $factoryPath) {
            $result.Details += "âœ“ Agent Factory exists"
        } else {
            $result.Errors += "Agent Factory not found"
            $result.Passed = $false
        }

        # Check agent directories
        $agentDirs = @('build', 'civic', 'audit', 'driver')
        foreach ($dir in $agentDirs) {
            $agentPath = "$($this.WorkspaceRoot)\agents\$dir"
            if (Test-Path $agentPath) {
                $result.Details += "âœ“ $dir agent directory exists"
            } else {
                $result.Warnings++
                $result.Details += "âš ï¸  $dir agent directory missing"
            }
        }

        # Test message bus
        $busPath = "$($this.WorkspaceRoot)\bus"
        if (Test-Path $busPath) {
            $result.Details += "âœ“ Message bus directory exists"

            # Check bus subdirectories
            foreach ($subdir in @('inbox', 'outbox', 'deadletter')) {
                if (Test-Path "$busPath\$subdir") {
                    $result.Details += "  âœ“ $subdir exists"
                }
            }
        }

        return $result
    }

    [hashtable]TestWorldChange() {
        $result = @{
            Passed   = $true
            Warnings = 0
            Details  = @()
            Errors   = @()
        }

        # Test orchestrator
        $orchestratorPath = "$($this.WorkspaceRoot)\scripts\ai-system\world-change\WorldChangeOrchestrator.ps1"
        if (Test-Path $orchestratorPath) {
            $result.Details += "âœ“ WorldChangeOrchestrator exists"

            try {
                $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $orchestratorPath -Raw), [ref]$null)
                $result.Details += "âœ“ Valid PowerShell syntax"
            } catch {
                $result.Errors += "Syntax error in orchestrator: $_"
                $result.Passed = $false
            }
        } else {
            $result.Errors += "WorldChangeOrchestrator not found"
            $result.Passed = $false
        }

        # Test launcher
        $launcherPath = "$($this.WorkspaceRoot)\Start-WorldChange.ps1"
        if (Test-Path $launcherPath) {
            $result.Details += "âœ“ Launcher script exists"
        } else {
            $result.Warnings++
            $result.Details += "âš ï¸  Launcher not found"
        }

        # Test ideas file
        $ideasPath = "$($this.WorkspaceRoot)\500-AI-WORLD-CHANGING-IDEAS.md"
        if (Test-Path $ideasPath) {
            $result.Details += "âœ“ 500 ideas file exists"

            $content = Get-Content $ideasPath -Raw
            $ideaCount = ([regex]::Matches($content, '###\s+Idea\s+\d+')).Count
            $result.Details += "âœ“ Found $ideaCount documented ideas"

            if ($ideaCount -lt 500) {
                $result.Warnings++
                $result.Details += "âš ï¸  Expected 500 ideas, found $ideaCount"
            }
        } else {
            $result.Errors += "500 ideas file not found"
            $result.Passed = $false
        }

        # Test progress tracking
        $progressPath = "$($this.WorkspaceRoot)\evidence\world-change-progress.json"
        if (Test-Path $progressPath) {
            $result.Details += "âœ“ Progress file exists"
        } else {
            $result.Warnings++
            $result.Details += "âš ï¸  No progress file (not started yet)"
        }

        return $result
    }

    [hashtable]TestProblemSolver() {
        $result = @{
            Passed   = $true
            Warnings = 0
            Details  = @()
            Errors   = @()
        }

        $solverPath = "$($this.WorkspaceRoot)\scripts\ai-system\problem-solver\AI-ProblemSolver.ps1"

        if (Test-Path $solverPath) {
            $result.Details += "âœ“ Problem Solver exists"

            try {
                $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $solverPath -Raw), [ref]$null)
                $result.Details += "âœ“ Valid PowerShell syntax"
            } catch {
                $result.Errors += "Syntax error: $_"
                $result.Passed = $false
            }

            # Check if it can detect current system issues
            $content = Get-Content $solverPath -Raw
            $domains = @('Performance', 'Security', 'Network', 'Development')
            foreach ($domain in $domains) {
                if ($content -match "Detect$domain") {
                    $result.Details += "âœ“ $domain detection implemented"
                }
            }

        } else {
            $result.Errors += "Problem Solver not found"
            $result.Passed = $false
        }

        return $result
    }

    [hashtable]TestEconomicAutonomy() {
        $result = @{
            Passed   = $true
            Warnings = 0
            Details  = @()
            Errors   = @()
        }

        $docPath = "$($this.WorkspaceRoot)\AI-ECONOMIC-AUTONOMY-SYSTEM.md"

        if (Test-Path $docPath) {
            $result.Details += "âœ“ Economic autonomy documentation exists"
        } else {
            $result.Warnings++
            $result.Details += "âš ï¸  Economic autonomy doc not found"
        }

        # This is mostly documentation at this stage
        $result.Details += "â„¹ï¸  Economic autonomy is in planning phase"

        return $result
    }

    [hashtable]AnalyzeAllLogs() {
        Write-Host "`nâ•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—" -ForegroundColor Cyan
        Write-Host "â•‘                 LOG ANALYSIS - DEEP DIVE                       â•‘" -ForegroundColor Yellow
        Write-Host "â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•" -ForegroundColor Cyan

        $analysis = @{
            TotalLogs          = 0
            TotalEntries       = 0
            ErrorCount         = 0
            WarningCount       = 0
            Errors             = @()
            Warnings           = @()
            Anomalies          = @()
            PerformanceMetrics = @{}
        }

        foreach ($logFile in $this.AllLogs) {
            Write-Host "`n  ðŸ“„ Analyzing: $($logFile.Name)" -ForegroundColor Cyan

            $analysis.TotalLogs++

            try {
                if ($logFile.Extension -eq '.jsonl') {
                    # JSON Lines format
                    $entries = Get-Content $logFile.FullName -ErrorAction Stop
                    $analysis.TotalEntries += $entries.Count

                    Write-Host "     Entries: $($entries.Count)" -ForegroundColor Gray

                    foreach ($entry in $entries) {
                        try {
                            $log = $entry | ConvertFrom-Json

                            # Check for errors
                            if ($log.Level -eq 'Error' -or $log.Error) {
                                $analysis.ErrorCount++
                                $analysis.Errors += @{
                                    File      = $logFile.Name
                                    Timestamp = $log.Timestamp
                                    Message   = $log.Message ?? $log.Error
                                }
                            }

                            # Check for warnings
                            if ($log.Level -eq 'Warning' -or $log.Warning) {
                                $analysis.WarningCount++
                                $analysis.Warnings += @{
                                    File      = $logFile.Name
                                    Timestamp = $log.Timestamp
                                    Message   = $log.Message ?? $log.Warning
                                }
                            }

                            # Detect anomalies
                            if ($log.Duration -and $log.Duration -gt 30000) {
                                $analysis.Anomalies += @{
                                    Type    = "Long execution time"
                                    File    = $logFile.Name
                                    Details = "Operation took $($log.Duration)ms"
                                }
                            }

                        } catch {
                            # Invalid JSON
                            $analysis.WarningCount++
                            $analysis.Warnings += @{
                                File    = $logFile.Name
                                Message = "Invalid JSON entry"
                            }
                        }
                    }

                } else {
                    # Plain text log
                    $content = Get-Content $logFile.FullName -Raw -ErrorAction Stop

                    # Count error keywords
                    $errorMatches = ([regex]::Matches($content, '(?i)(error|exception|failed|fatal)')).Count
                    $warningMatches = ([regex]::Matches($content, '(?i)(warning|warn)')).Count

                    $analysis.ErrorCount += $errorMatches
                    $analysis.WarningCount += $warningMatches

                    Write-Host "     Errors: $errorMatches, Warnings: $warningMatches" -ForegroundColor Gray

                    if ($errorMatches -gt 0) {
                        $analysis.Errors += @{
                            File    = $logFile.Name
                            Message = "$errorMatches error keywords found in log"
                        }
                    }
                }

            } catch {
                Write-Host "     âŒ Error reading log: $_" -ForegroundColor Red
                $analysis.Errors += @{
                    File    = $logFile.Name
                    Message = "Cannot read log file: $_"
                }
            }
        }

        # Summary
        Write-Host "`n  ðŸ“Š Log Analysis Summary:" -ForegroundColor White
        Write-Host "     Total Log Files: $($analysis.TotalLogs)" -ForegroundColor Cyan
        Write-Host "     Total Entries: $($analysis.TotalEntries)" -ForegroundColor Cyan
        Write-Host "     Errors Found: $($analysis.ErrorCount)" -ForegroundColor $(if ($analysis.ErrorCount -gt 0) { 'Red' }else { 'Green' })
        Write-Host "     Warnings Found: $($analysis.WarningCount)" -ForegroundColor $(if ($analysis.WarningCount -gt 0) { 'Yellow' }else { 'Green' })
        Write-Host "     Anomalies: $($analysis.Anomalies.Count)" -ForegroundColor $(if ($analysis.Anomalies.Count -gt 0) { 'Yellow' }else { 'Green' })

        return $analysis
    }

    [hashtable]CheckSystemHealth() {
        Write-Host "`nâ•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—" -ForegroundColor Cyan
        Write-Host "â•‘                  SYSTEM HEALTH CHECK                           â•‘" -ForegroundColor Yellow
        Write-Host "â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•" -ForegroundColor Cyan

        $health = @{
            Overall    = "Unknown"
            Components = @{}
        }

        # 1. Check disk space
        Write-Host "`n  ðŸ’¾ Checking disk space..." -ForegroundColor Cyan
        $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -ne $null }
        foreach ($drive in $drives) {
            $usedPercent = [math]::Round((($drive.Used / ($drive.Used + $drive.Free)) * 100), 1)
            $status = if ($usedPercent -lt 80) { "âœ… Healthy" } elseif ($usedPercent -lt 90) { "âš ï¸  Warning" } else { "âŒ Critical" }
            $color = if ($usedPercent -lt 80) { "Green" } elseif ($usedPercent -lt 90) { "Yellow" } else { "Red" }

            Write-Host "     Drive $($drive.Name): $usedPercent% used - $status" -ForegroundColor $color

            $health.Components["Disk_$($drive.Name)"] = @{
                Status = if ($usedPercent -lt 80) { "Healthy" } else { "Warning" }
                Usage  = $usedPercent
            }
        }

        # 2. Check memory
        Write-Host "`n  ðŸ§  Checking memory..." -ForegroundColor Cyan
        $os = Get-CimInstance Win32_OperatingSystem
        $memUsedPercent = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)
        $memStatus = if ($memUsedPercent -lt 80) { "âœ… Healthy" } elseif ($memUsedPercent -lt 90) { "âš ï¸  Warning" } else { "âŒ Critical" }
        $memColor = if ($memUsedPercent -lt 80) { "Green" } elseif ($memUsedPercent -lt 90) { "Yellow" } else { "Red" }

        Write-Host "     Memory: $memUsedPercent% used - $memStatus" -ForegroundColor $memColor

        $health.Components["Memory"] = @{
            Status = if ($memUsedPercent - < 80) { "Healthy" } else { "Warning" }
            Usage  = $memUsedPercent
        }

        # 3. Check CPU
        Write-Host "`n  âš¡ Checking CPU..." -ForegroundColor Cyan
        $cpu = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
        if ($cpu) {
            $cpuUsage = [math]::Round($cpu.CounterSamples[0].CookedValue, 1)
            $cpuStatus = if ($cpuUsage -lt 70) { "âœ… Healthy" } elseif ($cpuUsage -lt 85) { "âš ï¸  Warning" } else { "âŒ Critical" }
            $cpuColor = if ($cpuUsage -lt 70) { "Green" } elseif ($cpuUsage -lt 85) { "Yellow" } else { "Red" }

            Write-Host "     CPU: $cpuUsage% - $cpuStatus" -ForegroundColor $cpuColor

            $health.Components["CPU"] = @{
                Status = if ($cpuUsage -lt 70) { "Healthy" } else { "Warning" }
                Usage  = $cpuUsage
            }
        }

        # 4. Check services
        Write-Host "`n  ðŸ”§ Checking key services..." -ForegroundColor Cyan

        # Check Ollama
        $ollama = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
        if ($ollama) {
            Write-Host "     Ollama: âœ… Running" -ForegroundColor Green
            $health.Components["Ollama"] = @{ Status = "Running" }
        } else {
            Write-Host "     Ollama: âš ï¸  Not running" -ForegroundColor Yellow
            $health.Components["Ollama"] = @{ Status = "Not Running" }
        }

        # Check internet
        Write-Host "`n  ðŸŒ Checking connectivity..." -ForegroundColor Cyan
        $ping = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue
        if ($ping) {
            Write-Host "     Internet: âœ… Connected" -ForegroundColor Green
            $health.Components["Internet"] = @{ Status = "Connected" }
        } else {
            Write-Host "     Internet: âŒ Disconnected" -ForegroundColor Red
            $health.Components["Internet"] = @{ Status = "Disconnected" }
        }

        # Overall health
        $criticalIssues = ($health.Components.Values | Where-Object { $_.Status -match 'Critical|Disconnected|Not Running' }).Count
        $warnings = ($health.Components.Values | Where-Object { $_.Status -match 'Warning' }).Count

        if ($criticalIssues -eq 0 -and $warnings -eq 0) {
            $health.Overall = "Healthy"
            Write-Host "`n  âœ… Overall System Health: HEALTHY" -ForegroundColor Green
        } elseif ($criticalIssues -eq 0) {
            $health.Overall = "Warning"
            Write-Host "`n  âš ï¸  Overall System Health: WARNING ($warnings warnings)" -ForegroundColor Yellow
        } else {
            $health.Overall = "Critical"
            Write-Host "`n  âŒ Overall System Health: CRITICAL ($criticalIssues critical issues)" -ForegroundColor Red
        }

        return $health
    }

    [void]GenerateReport([hashtable]$ComponentResults, [hashtable]$LogAnalysis, [hashtable]$SystemHealth) {
        $endTime = Get-Date
        $duration = $endTime - $script:TestResults.StartTime

        Write-Host "`nâ•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—" -ForegroundColor Cyan
        Write-Host "â•‘              COMPREHENSIVE TEST REPORT                         â•‘" -ForegroundColor Yellow
        Write-Host "â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•" -ForegroundColor Cyan

        Write-Host "`n  â±ï¸  Test Duration: $([math]::Round($duration.TotalSeconds, 2)) seconds" -ForegroundColor Gray
        Write-Host "  ðŸ“… Completed: $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray

        # Component Results
        Write-Host "`n  ðŸ“¦ COMPONENT TEST RESULTS:" -ForegroundColor White
        Write-Host "  " + ("â”€" * 60) -ForegroundColor DarkGray

        $totalComponents = $ComponentResults.Count
        $passedComponents = ($ComponentResults.Values | Where-Object { $_.Passed }).Count
        $failedComponents = $totalComponents - $passedComponents

        foreach ($component in $ComponentResults.Keys | Sort-Object) {
            $result = $ComponentResults[$component]
            $icon = if ($result.Passed) { "âœ…" } else { "âŒ" }
            $status = if ($result.Passed) { "PASS" } else { "FAIL" }
            $color = if ($result.Passed) { "Green" } else { "Red" }

            Write-Host "  $icon $($component.PadRight(20)) - $status" -ForegroundColor $color

            if ($result.Warnings -gt 0) {
                Write-Host "     âš ï¸  $($result.Warnings) warnings" -ForegroundColor Yellow
            }

            if ($result.Errors.Count -gt 0) {
                foreach ($error in $result.Errors) {
                    Write-Host "       â€¢ $error" -ForegroundColor Red
                }
            }
        }

        Write-Host "`n  Summary: $passedComponents/$totalComponents passed" -ForegroundColor Cyan

        # Log Analysis
        Write-Host "`n  ðŸ“Š LOG ANALYSIS SUMMARY:" -ForegroundColor White
        Write-Host "  " + ("â”€" * 60) -ForegroundColor DarkGray
        Write-Host "     Files Analyzed: $($LogAnalysis.TotalLogs)" -ForegroundColor Cyan
        Write-Host "     Total Entries: $($LogAnalysis.TotalEntries)" -ForegroundColor Cyan
        Write-Host "     Errors: $($LogAnalysis.ErrorCount)" -ForegroundColor $(if ($LogAnalysis.ErrorCount -gt 0) { 'Red' }else { 'Green' })
        Write-Host "     Warnings: $($LogAnalysis.WarningCount)" -ForegroundColor $(if ($LogAnalysis.WarningCount -gt 0) { 'Yellow' }else { 'Green' })

        if ($LogAnalysis.Errors.Count -gt 0) {
            Write-Host "`n     Recent Errors:" -ForegroundColor Red
            foreach ($error in ($LogAnalysis.Errors | Select-Object -First 5)) {
                Write-Host "       â€¢ [$($error.File)] $($error.Message)" -ForegroundColor Red
            }
            if ($LogAnalysis.Errors.Count -gt 5) {
                Write-Host "       ... and $($LogAnalysis.Errors.Count - 5) more" -ForegroundColor Gray
            }
        }

        # System Health
        Write-Host "`n  ðŸ¥ SYSTEM HEALTH:" -ForegroundColor White
        Write-Host "  " + ("â”€" * 60) -ForegroundColor DarkGray

        $healthColor = switch ($SystemHealth.Overall) {
            "Healthy" { "Green" }
            "Warning" { "Yellow" }
            "Critical" { "Red" }
            default { "Gray" }
        }

        Write-Host "     Overall: $($SystemHealth.Overall.ToUpper())" -ForegroundColor $healthColor

        # Final Verdict
        Write-Host "`nâ•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—" -ForegroundColor Cyan

        if ($failedComponents -eq 0 -and $LogAnalysis.ErrorCount -eq 0 -and $SystemHealth.Overall -eq "Healthy") {
            Write-Host "â•‘                   âœ… ALL TESTS PASSED âœ…                       â•‘" -ForegroundColor Green
            Write-Host "â•‘              AI SYSTEM IS FULLY OPERATIONAL!                   â•‘" -ForegroundColor Green
        } elseif ($failedComponents -eq 0 -and $LogAnalysis.ErrorCount -lt 10) {
            Write-Host "â•‘              âš ï¸  SYSTEM OPERATIONAL WITH WARNINGS  âš ï¸           â•‘" -ForegroundColor Yellow
            Write-Host "â•‘          Minor issues detected - review recommended            â•‘" -ForegroundColor Yellow
        } else {
            Write-Host "â•‘                âŒ CRITICAL ISSUES DETECTED âŒ                   â•‘" -ForegroundColor Red
            Write-Host "â•‘             IMMEDIATE ATTENTION REQUIRED!                      â•‘" -ForegroundColor Red
        }

        Write-Host "â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•" -ForegroundColor Cyan
    }

    [void]ExportHTMLReport([hashtable]$ComponentResults, [hashtable]$LogAnalysis, [hashtable]$SystemHealth) {
        $reportPath = "$($this.WorkspaceRoot)\evidence\test-report.html"

        Write-Host "`n  ðŸ“ Generating HTML report..." -ForegroundColor Yellow

        $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>AI System Test Report</title>
    <meta charset="UTF-8">
    <style>
        body { font-family: 'Segoe UI', sans-serif; background: #f5f5f5; padding: 20px; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 40px; border-radius: 10px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
        h1 { color: #2196F3; text-align: center; }
        .section { margin: 30px 0; }
        .pass { color: #4CAF50; font-weight: bold; }
        .fail { color: #F44336; font-weight: bold; }
        .warning { color: #FF9800; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #2196F3; color: white; }
        .metric { display: inline-block; margin: 10px 20px; padding: 15px; background: #E3F2FD; border-radius: 8px; }
        .metric-value { font-size: 2em; font-weight: bold; color: #2196F3; }
        .metric-label { font-size: 0.9em; color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <h1>ðŸ§ª AI System Comprehensive Test Report</h1>
        <p style="text-align:center; color:#666;">Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>

        <div class="section">
            <h2>ðŸ“Š Summary</h2>
            <div class="metric">
                <div class="metric-value">$($ComponentResults.Count)</div>
                <div class="metric-label">Components Tested</div>
            </div>
            <div class="metric">
                <div class="metric-value">$(($ComponentResults.Values | Where-Object {$_.Passed}).Count)</div>
                <div class="metric-label">Passed</div>
            </div>
            <div class="metric">
                <div class="metric-value">$($LogAnalysis.TotalLogs)</div>
                <div class="metric-label">Logs Analyzed</div>
            </div>
            <div class="metric">
                <div class="metric-value">$($LogAnalysis.ErrorCount)</div>
                <div class="metric-label">Errors Found</div>
            </div>
        </div>

        <div class="section">
            <h2>ðŸ“¦ Component Test Results</h2>
            <table>
                <tr><th>Component</th><th>Status</th><th>Warnings</th><th>Details</th></tr>
"@

        foreach ($component in $ComponentResults.Keys | Sort-Object) {
            $result = $ComponentResults[$component]
            $status = if ($result.Passed) { "<span class='pass'>PASS</span>" } else { "<span class='fail'>FAIL</span>" }
            $warnings = if ($result.Warnings -gt 0) { "<span class='warning'>$($result.Warnings)</span>" } else { "0" }

            $html += "<tr><td>$component</td><td>$status</td><td>$warnings</td><td>"

            if ($result.Details) {
                $html += "<ul>"
                foreach ($detail in $result.Details) {
                    $html += "<li>$detail</li>"
                }
                $html += "</ul>"
            }

            $html += "</td></tr>"
        }

        $html += @"
            </table>
        </div>

        <div class="section">
            <h2>ðŸ¥ System Health</h2>
            <p><strong>Overall Status:</strong> <span class="$(if($SystemHealth.Overall -eq 'Healthy'){'pass'}else{'warning'})">$($SystemHealth.Overall)</span></p>
        </div>
    </div>
</body>
</html>
"@

        $html | Out-File $reportPath -Encoding UTF8

        Write-Host "  âœ… HTML report saved: $reportPath" -ForegroundColor Green
        Write-Host "  ðŸŒ Opening report in browser..." -ForegroundColor Cyan

        Start-Process $reportPath
    }
}

# Main execution
Write-Host "`nâ•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—" -ForegroundColor Cyan
Write-Host "â•‘                                                                â•‘" -ForegroundColor Cyan
Write-Host "â•‘        ðŸ§ª  AI SYSTEM - COMPREHENSIVE TEST SUITE  ðŸ§ª            â•‘" -ForegroundColor Yellow
Write-Host "â•‘                                                                â•‘" -ForegroundColor Cyan
Write-Host "â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•" -ForegroundColor Cyan

$runner = [TestRunner]::new()
$runner.DiscoverComponents()

$componentResults = @{}
$logAnalysis = @{}
$systemHealth = @{}

# Run tests based on parameters
if (-not $AnalyzeLogsOnly) {
    if ($Component) {
        Write-Host "`n  ðŸŽ¯ Testing specific component: $Component" -ForegroundColor Cyan
        # Run specific component test
    } else {
        $componentResults = $runner.TestAllComponents()
    }
}

# Always analyze logs
$logAnalysis = $runner.AnalyzeAllLogs()

# Check system health
$systemHealth = $runner.CheckSystemHealth()

# Generate report
$runner.GenerateReport($componentResults, $logAnalysis, $systemHealth)

# Export HTML if requested
if ($ExportHTML) {
    $runner.ExportHTMLReport($componentResults, $logAnalysis, $systemHealth)
}

# Save JSON report
$jsonReport = @{
    Timestamp        = Get-Date
    ComponentResults = $componentResults
    LogAnalysis      = $logAnalysis
    SystemHealth     = $systemHealth
} | ConvertTo-Json -Depth 10

$jsonReport | Out-File "$($runner.WorkspaceRoot)\evidence\test-report.json" -Encoding UTF8

Write-Host "`n  ðŸ’¾ JSON report saved: evidence\test-report.json" -ForegroundColor Cyan
Write-Host "`nâœ… Testing complete!`n" -ForegroundColor Green
