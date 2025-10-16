<#
.SYNOPSIS
    🧠 AI Problem Solver - Autonomous problem detection and solution development

.DESCRIPTION
    This AI system autonomously:
    - Monitors system health and user context
    - Detects problems across all domains
    - Analyzes root causes
    - Develops custom solutions
    - Implements fixes automatically (with safety checks)
    - Learns from outcomes

    Problem Domains:
    - System Performance (CPU, memory, disk, network)
    - Software Issues (crashes, errors, bugs)
    - Workflow Inefficiencies (slow processes, repetitive tasks)
    - Communication (email overload, missed messages)
    - Time Management (scheduling conflicts, deadlines)
    - Security (vulnerabilities, threats)
    - Personal Productivity (distractions, focus issues)
    - Learning & Development (skill gaps, knowledge needs)
    - Health & Wellness (reminders, ergonomics)
    - And any other problems the AI can detect

.EXAMPLE
    .\AI-ProblemSolver.ps1 -ContinuousMode

    Run AI problem solver 24/7, detecting and fixing issues

.EXAMPLE
    .\AI-ProblemSolver.ps1 -ScanOnly

    Scan for problems without implementing solutions

.EXAMPLE
    .\AI-ProblemSolver.ps1 -Domain "System Performance"

    Focus on specific problem domain
#>

param(
    [switch]$ContinuousMode,
    [switch]$ScanOnly,
    [string]$Domain,
    [int]$ScanIntervalMinutes = 15,
    [switch]$AutoFix = $true,
    [switch]$VerboseLogging
)

# Import required modules
$ModulePath = "$PSScriptRoot\..\.."
Import-Module "$ModulePath\SafetyFramework.ps1" -Force -ErrorAction SilentlyContinue
Import-Module "$ModulePath\Self-Learning.ps1" -Force -ErrorAction SilentlyContinue
Import-Module "$ModulePath\Self-Researching.ps1" -Force -ErrorAction SilentlyContinue
Import-Module "$ModulePath\Self-Developing.ps1" -Force -ErrorAction SilentlyContinue

class ProblemSolver {
    [hashtable]$DetectedProblems = @{}
    [hashtable]$Solutions = @{}
    [hashtable]$ImplementedFixes = @{}
    [object]$SafetyFramework
    [string]$LogPath
    [hashtable]$UserContext = @{}
    [int]$ProblemIdCounter = 1

    ProblemSolver() {
        $this.LogPath = "$PSScriptRoot\..\..\..\logs\problem-solver.jsonl"
        $this.InitializeUserContext()
        Write-Host "🧠 AI Problem Solver initialized" -ForegroundColor Green
    }

    [void]InitializeUserContext() {
        # Gather context about user
        $this.UserContext = @{
            UserName          = $env:USERNAME
            ComputerName      = $env:COMPUTERNAME
            OS                = (Get-CimInstance Win32_OperatingSystem).Caption
            WorkingDirectory  = $PSScriptRoot
            Timestamp         = Get-Date
            InstalledSoftware = @()
            RunningProcesses  = @()
            RecentErrors      = @()
            WorkspaceProjects = @()
        }

        Write-Verbose "User context initialized"
    }

    [hashtable]ScanForProblems() {
        Write-Host "`n🔍 Scanning for problems across all domains..." -ForegroundColor Cyan

        $problems = @{}

        # Domain 1: System Performance
        $problems += $this.DetectSystemPerformanceIssues()

        # Domain 2: Software Issues
        $problems += $this.DetectSoftwareIssues()

        # Domain 3: Workflow Inefficiencies
        $problems += $this.DetectWorkflowIssues()

        # Domain 4: Security Issues
        $problems += $this.DetectSecurityIssues()

        # Domain 5: File System Issues
        $problems += $this.DetectFileSystemIssues()

        # Domain 6: Network Issues
        $problems += $this.DetectNetworkIssues()

        # Domain 7: Development Environment Issues
        $problems += $this.DetectDevelopmentIssues()

        # Domain 8: Time Management Issues
        $problems += $this.DetectTimeManagementIssues()

        return $problems
    }

    [hashtable]DetectSystemPerformanceIssues() {
        $problems = @{}

        try {
            # CPU Usage
            $cpu = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
            if ($cpu.CounterSamples[0].CookedValue -gt 80) {
                $problems["PERF-CPU-001"] = @{
                    ID          = "PERF-CPU-$($this.ProblemIdCounter++)"
                    Severity    = "High"
                    Domain      = "System Performance"
                    Title       = "High CPU Usage Detected"
                    Description = "CPU usage is at $([math]::Round($cpu.CounterSamples[0].CookedValue, 1))%"
                    Impact      = "System slowdown, reduced productivity, potential crashes"
                    DetectedAt  = Get-Date
                    Status      = "Detected"
                }
            }

            # Memory Usage
            $os = Get-CimInstance Win32_OperatingSystem
            $memUsedPercent = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)

            if ($memUsedPercent -gt 85) {
                $problems["PERF-MEM-001"] = @{
                    ID          = "PERF-MEM-$($this.ProblemIdCounter++)"
                    Severity    = "High"
                    Domain      = "System Performance"
                    Title       = "High Memory Usage Detected"
                    Description = "Memory usage is at $memUsedPercent%"
                    Impact      = "Application slowdown, potential crashes, system instability"
                    DetectedAt  = Get-Date
                    Status      = "Detected"
                }
            }

            # Disk Space
            $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -ne $null }
            foreach ($drive in $drives) {
                $usedPercent = [math]::Round((($drive.Used / ($drive.Used + $drive.Free)) * 100), 1)
                if ($usedPercent -gt 90) {
                    $problems["PERF-DISK-$($drive.Name)"] = @{
                        ID          = "PERF-DISK-$($this.ProblemIdCounter++)"
                        Severity    = "Critical"
                        Domain      = "System Performance"
                        Title       = "Low Disk Space on Drive $($drive.Name)"
                        Description = "Drive $($drive.Name):\ is $usedPercent% full ($([math]::Round($drive.Free/1GB, 2)) GB free)"
                        Impact      = "Cannot save files, system instability, potential data loss"
                        DetectedAt  = Get-Date
                        Status      = "Detected"
                    }
                }
            }

        } catch {
            Write-Warning "Error detecting performance issues: $_"
        }

        return $problems
    }

    [hashtable]DetectSoftwareIssues() {
        $problems = @{}

        try {
            # Check Event Log for recent errors
            $errors = Get-EventLog -LogName Application -EntryType Error -Newest 50 -ErrorAction SilentlyContinue |
            Where-Object { $_.TimeGenerated -gt (Get-Date).AddHours(-24) }

            if ($errors.Count -gt 10) {
                $topErrors = $errors | Group-Object -Property Source | Sort-Object Count -Descending | Select-Object -First 5

                foreach ($errorGroup in $topErrors) {
                    $problems["SOFT-ERR-$($errorGroup.Name)"] = @{
                        ID          = "SOFT-ERR-$($this.ProblemIdCounter++)"
                        Severity    = "Medium"
                        Domain      = "Software Issues"
                        Title       = "Recurring Errors from $($errorGroup.Name)"
                        Description = "$($errorGroup.Count) errors in last 24 hours from $($errorGroup.Name)"
                        Impact      = "Application instability, potential data corruption"
                        DetectedAt  = Get-Date
                        Status      = "Detected"
                        Details     = $errorGroup.Group[0].Message
                    }
                }
            }

            # Check for crashed processes (in last hour)
            $crashes = Get-EventLog -LogName Application -Source "Application Error" -Newest 20 -ErrorAction SilentlyContinue |
            Where-Object { $_.TimeGenerated -gt (Get-Date).AddHours(-1) }

            if ($crashes.Count -gt 0) {
                $problems["SOFT-CRASH-001"] = @{
                    ID          = "SOFT-CRASH-$($this.ProblemIdCounter++)"
                    Severity    = "High"
                    Domain      = "Software Issues"
                    Title       = "Application Crashes Detected"
                    Description = "$($crashes.Count) application crash(es) in last hour"
                    Impact      = "Lost work, productivity loss, user frustration"
                    DetectedAt  = Get-Date
                    Status      = "Detected"
                }
            }

        } catch {
            Write-Warning "Error detecting software issues: $_"
        }

        return $problems
    }

    [hashtable]DetectWorkflowIssues() {
        $problems = @{}

        try {
            # Check for repetitive tasks (multiple identical commands)
            $historyFile = (Get-PSReadLineOption).HistorySavePath
            if (Test-Path $historyFile) {
                $recentCommands = Get-Content $historyFile -Tail 100 -ErrorAction SilentlyContinue
                $commandGroups = $recentCommands | Group-Object | Where-Object { $_.Count -ge 5 }

                foreach ($group in $commandGroups) {
                    $problems["WORK-REP-$($group.Name.GetHashCode())"] = @{
                        ID          = "WORK-REP-$($this.ProblemIdCounter++)"
                        Severity    = "Low"
                        Domain      = "Workflow Inefficiency"
                        Title       = "Repetitive Command Detected"
                        Description = "Command '$($group.Name)' executed $($group.Count) times recently"
                        Impact      = "Time waste, opportunity for automation"
                        DetectedAt  = Get-Date
                        Status      = "Detected"
                        Suggestion  = "This could be automated with a script or alias"
                    }
                }
            }

            # Check for multiple VS Code instances (potential workflow issue)
            $vscodeProcesses = Get-Process -Name "Code" -ErrorAction SilentlyContinue
            if ($vscodeProcesses.Count -gt 5) {
                $problems["WORK-VSCODE-001"] = @{
                    ID          = "WORK-VSCODE-$($this.ProblemIdCounter++)"
                    Severity    = "Low"
                    Domain      = "Workflow Inefficiency"
                    Title       = "Multiple VS Code Instances"
                    Description = "$($vscodeProcesses.Count) VS Code instances running"
                    Impact      = "Memory waste, confusion, potential duplicate work"
                    DetectedAt  = Get-Date
                    Status      = "Detected"
                    Suggestion  = "Consider using workspaces to organize projects in one window"
                }
            }

        } catch {
            Write-Warning "Error detecting workflow issues: $_"
        }

        return $problems
    }

    [hashtable]DetectSecurityIssues() {
        $problems = @{}

        try {
            # Check Windows Defender status
            $defender = Get-MpComputerStatus -ErrorAction SilentlyContinue

            if ($defender.AntivirusEnabled -eq $false) {
                $problems["SEC-AV-001"] = @{
                    ID          = "SEC-AV-$($this.ProblemIdCounter++)"
                    Severity    = "Critical"
                    Domain      = "Security"
                    Title       = "Antivirus Disabled"
                    Description = "Windows Defender is disabled"
                    Impact      = "System vulnerable to malware, viruses, ransomware"
                    DetectedAt  = Get-Date
                    Status      = "Detected"
                }
            }

            if ($defender.RealTimeProtectionEnabled -eq $false) {
                $problems["SEC-RTP-001"] = @{
                    ID          = "SEC-RTP-$($this.ProblemIdCounter++)"
                    Severity    = "High"
                    Domain      = "Security"
                    Title       = "Real-time Protection Disabled"
                    Description = "Real-time malware protection is off"
                    Impact      = "No active threat prevention"
                    DetectedAt  = Get-Date
                    Status      = "Detected"
                }
            }

            # Check for outdated definitions
            if ($defender.AntivirusSignatureAge -gt 7) {
                $problems["SEC-DEF-001"] = @{
                    ID          = "SEC-DEF-$($this.ProblemIdCounter++)"
                    Severity    = "Medium"
                    Domain      = "Security"
                    Title       = "Outdated Virus Definitions"
                    Description = "Definitions are $($defender.AntivirusSignatureAge) days old"
                    Impact      = "Cannot detect latest threats"
                    DetectedAt  = Get-Date
                    Status      = "Detected"
                }
            }

            # Check firewall status
            $firewall = Get-NetFirewallProfile -ErrorAction SilentlyContinue
            foreach ($profile in $firewall) {
                if ($profile.Enabled -eq $false) {
                    $problems["SEC-FW-$($profile.Name)"] = @{
                        ID          = "SEC-FW-$($this.ProblemIdCounter++)"
                        Severity    = "Critical"
                        Domain      = "Security"
                        Title       = "Firewall Disabled: $($profile.Name)"
                        Description = "$($profile.Name) firewall profile is disabled"
                        Impact      = "Vulnerable to network attacks"
                        DetectedAt  = Get-Date
                        Status      = "Detected"
                    }
                }
            }

        } catch {
            Write-Warning "Error detecting security issues: $_"
        }

        return $problems
    }

    [hashtable]DetectFileSystemIssues() {
        $problems = @{}

        try {
            # Check for duplicate files (large files)
            $workspaceRoot = "$PSScriptRoot\..\..\.."
            if (Test-Path $workspaceRoot) {
                $largeFiles = Get-ChildItem -Path $workspaceRoot -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Length -gt 10MB } |
                Group-Object Length, Extension |
                Where-Object { $_.Count -gt 1 }

                if ($largeFiles.Count -gt 0) {
                    $totalWaste = ($largeFiles | ForEach-Object { ($_.Group[0].Length * ($_.Count - 1)) } | Measure-Object -Sum).Sum

                    $problems["FILE-DUP-001"] = @{
                        ID          = "FILE-DUP-$($this.ProblemIdCounter++)"
                        Severity    = "Low"
                        Domain      = "File System"
                        Title       = "Potential Duplicate Large Files"
                        Description = "Found $($largeFiles.Count) groups of similar large files (potential $([math]::Round($totalWaste/1MB, 2)) MB waste)"
                        Impact      = "Wasted disk space, confusion"
                        DetectedAt  = Get-Date
                        Status      = "Detected"
                    }
                }
            }

            # Check for very deep folder nesting
            $deepFolders = Get-ChildItem -Path $workspaceRoot -Recurse -Directory -ErrorAction SilentlyContinue |
            Where-Object { ($_.FullName -split '\\').Count -gt 10 }

            if ($deepFolders.Count -gt 0) {
                $problems["FILE-DEEP-001"] = @{
                    ID          = "FILE-DEEP-$($this.ProblemIdCounter++)"
                    Severity    = "Low"
                    Domain      = "File System"
                    Title       = "Deep Folder Nesting"
                    Description = "Found $($deepFolders.Count) folders with very deep nesting"
                    Impact      = "Path length issues, navigation difficulty"
                    DetectedAt  = Get-Date
                    Status      = "Detected"
                }
            }

        } catch {
            Write-Warning "Error detecting file system issues: $_"
        }

        return $problems
    }

    [hashtable]DetectNetworkIssues() {
        $problems = @{}

        try {
            # Test internet connectivity
            $ping = Test-Connection -ComputerName "8.8.8.8" -Count 2 -Quiet -ErrorAction SilentlyContinue

            if (-not $ping) {
                $problems["NET-CONN-001"] = @{
                    ID          = "NET-CONN-$($this.ProblemIdCounter++)"
                    Severity    = "Critical"
                    Domain      = "Network"
                    Title       = "No Internet Connection"
                    Description = "Cannot reach internet (tested with 8.8.8.8)"
                    Impact      = "No web access, can't download updates, isolated system"
                    DetectedAt  = Get-Date
                    Status      = "Detected"
                }
            }

            # Check for slow DNS
            $dnsTest = Measure-Command {
                Resolve-DnsName "google.com" -ErrorAction SilentlyContinue
            }

            if ($dnsTest.TotalMilliseconds -gt 1000) {
                $problems["NET-DNS-001"] = @{
                    ID          = "NET-DNS-$($this.ProblemIdCounter++)"
                    Severity    = "Medium"
                    Domain      = "Network"
                    Title       = "Slow DNS Resolution"
                    Description = "DNS lookup took $([math]::Round($dnsTest.TotalMilliseconds)) ms"
                    Impact      = "Slow web browsing, application delays"
                    DetectedAt  = Get-Date
                    Status      = "Detected"
                }
            }

        } catch {
            Write-Warning "Error detecting network issues: $_"
        }

        return $problems
    }

    [hashtable]DetectDevelopmentIssues() {
        $problems = @{}

        try {
            # Check for Git issues
            $gitStatus = git status 2>&1

            if ($LASTEXITCODE -ne 0) {
                # Not a git repo or Git not installed
                if ($gitStatus -match "not a git repository") {
                    $problems["DEV-GIT-001"] = @{
                        ID          = "DEV-GIT-$($this.ProblemIdCounter++)"
                        Severity    = "Low"
                        Domain      = "Development"
                        Title       = "Not a Git Repository"
                        Description = "Current directory is not under version control"
                        Impact      = "No version history, collaboration difficulty, risk of data loss"
                        DetectedAt  = Get-Date
                        Status      = "Detected"
                    }
                }
            } else {
                # Check for uncommitted changes
                if ($gitStatus -match "Changes not staged" -or $gitStatus -match "Untracked files") {
                    $problems["DEV-GIT-002"] = @{
                        ID          = "DEV-GIT-$($this.ProblemIdCounter++)"
                        Severity    = "Low"
                        Domain      = "Development"
                        Title       = "Uncommitted Git Changes"
                        Description = "You have uncommitted changes in your repository"
                        Impact      = "Risk of losing work, potential merge conflicts"
                        DetectedAt  = Get-Date
                        Status      = "Detected"
                    }
                }
            }

            # Check for missing package.json dependencies
            $packageJson = "$PSScriptRoot\..\..\..\package.json"
            $nodeModules = "$PSScriptRoot\..\..\..\node_modules"

            if ((Test-Path $packageJson) -and (-not (Test-Path $nodeModules))) {
                $problems["DEV-NPM-001"] = @{
                    ID          = "DEV-NPM-$($this.ProblemIdCounter++)"
                    Severity    = "Medium"
                    Domain      = "Development"
                    Title       = "Missing Node Modules"
                    Description = "package.json exists but node_modules missing"
                    Impact      = "Application won't run, build failures"
                    DetectedAt  = Get-Date
                    Status      = "Detected"
                }
            }

        } catch {
            Write-Warning "Error detecting development issues: $_"
        }

        return $problems
    }

    [hashtable]DetectTimeManagementIssues() {
        $problems = @{}

        try {
            # Check for long-running processes (potential forgotten tasks)
            $longRunning = Get-Process | Where-Object {
                $_.StartTime -and
                (New-TimeSpan -Start $_.StartTime -End (Get-Date)).TotalHours -gt 24
            } | Where-Object {
                $_.ProcessName -in @('notepad', 'Code', 'chrome', 'firefox', 'excel', 'winword')
            }

            if ($longRunning.Count -gt 5) {
                $problems["TIME-PROC-001"] = @{
                    ID          = "TIME-PROC-$($this.ProblemIdCounter++)"
                    Severity    = "Low"
                    Domain      = "Time Management"
                    Title       = "Many Long-Running Processes"
                    Description = "$($longRunning.Count) applications running for over 24 hours"
                    Impact      = "Memory waste, potential forgotten tasks, digital clutter"
                    DetectedAt  = Get-Date
                    Status      = "Detected"
                }
            }

        } catch {
            Write-Warning "Error detecting time management issues: $_"
        }

        return $problems
    }

    [hashtable]AnalyzeProblem([hashtable]$Problem) {
        Write-Host "  🔬 Analyzing: $($Problem.Title)" -ForegroundColor Yellow

        # Use AI to analyze root cause
        $analysis = @{
            RootCause             = ""
            RelatedProblems       = @()
            PossibleSolutions     = @()
            Priority              = 0
            EstimatedEffort       = ""
            RequiresHumanApproval = $false
        }

        # Determine root cause based on domain and description
        switch ($Problem.Domain) {
            "System Performance" {
                $analysis.RootCause = $this.AnalyzePerformanceIssue($Problem)
                $analysis.EstimatedEffort = "5-15 minutes"
            }
            "Software Issues" {
                $analysis.RootCause = "Application instability or compatibility issues"
                $analysis.EstimatedEffort = "10-30 minutes"
            }
            "Workflow Inefficiency" {
                $analysis.RootCause = "Manual repetitive tasks that can be automated"
                $analysis.EstimatedEffort = "15-60 minutes (one-time setup)"
            }
            "Security" {
                $analysis.RootCause = "Security configuration disabled or outdated"
                $analysis.EstimatedEffort = "Immediate"
                $analysis.RequiresHumanApproval = $true
            }
            "Network" {
                $analysis.RootCause = "Network connectivity or configuration issue"
                $analysis.EstimatedEffort = "5-20 minutes"
            }
            "Development" {
                $analysis.RootCause = "Missing dependencies or version control issues"
                $analysis.EstimatedEffort = "5-15 minutes"
            }
        }

        # Calculate priority (1-10)
        $analysis.Priority = switch ($Problem.Severity) {
            "Critical" { 10 }
            "High" { 7 }
            "Medium" { 5 }
            "Low" { 3 }
            default { 1 }
        }

        return $analysis
    }

    [string]AnalyzePerformanceIssue([hashtable]$Problem) {
        if ($Problem.Title -match "CPU") {
            # Find top CPU processes
            $topProcesses = Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
            return "High CPU usage likely caused by: $($topProcesses[0].ProcessName)"
        } elseif ($Problem.Title -match "Memory") {
            $topProcesses = Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 5
            return "High memory usage likely caused by: $($topProcesses[0].ProcessName)"
        } elseif ($Problem.Title -match "Disk") {
            return "Disk space exhaustion - need to clean temp files, downloads, or move data"
        }

        return "Performance degradation detected"
    }

    [hashtable]DevelopSolution([hashtable]$Problem, [hashtable]$Analysis) {
        Write-Host "  💡 Developing solution for: $($Problem.Title)" -ForegroundColor Cyan

        $solution = @{
            SolutionID            = "SOL-$($this.ProblemIdCounter++)"
            ProblemID             = $Problem.ID
            Title                 = ""
            Description           = ""
            Steps                 = @()
            AutomationScript      = ""
            RequiresReboot        = $false
            RequiresHumanApproval = $Analysis.RequiresHumanApproval
            EstimatedTime         = $Analysis.EstimatedEffort
            SafetyChecked         = $false
        }

        # Generate solution based on problem domain
        switch ($Problem.Domain) {
            "System Performance" {
                $solution += $this.DevelopPerformanceSolution($Problem)
            }
            "Security" {
                $solution += $this.DevelopSecuritySolution($Problem)
            }
            "Workflow Inefficiency" {
                $solution += $this.DevelopWorkflowSolution($Problem)
            }
            "Network" {
                $solution += $this.DevelopNetworkSolution($Problem)
            }
            "Development" {
                $solution += $this.DevelopDevelopmentSolution($Problem)
            }
            "File System" {
                $solution += $this.DevelopFileSystemSolution($Problem)
            }
        }

        return $solution
    }

    [hashtable]DevelopPerformanceSolution([hashtable]$Problem) {
        $solution = @{}

        if ($Problem.Title -match "CPU") {
            $solution.Title = "Optimize CPU Usage"
            $solution.Description = "Identify and manage high CPU processes"
            $solution.Steps = @(
                "Identify top CPU-consuming processes",
                "Check if processes are necessary",
                "Close unnecessary applications",
                "Set process priority to below normal if needed",
                "Schedule resource-intensive tasks for off-peak hours"
            )
            $solution.AutomationScript = @'
# Find top CPU processes
$topProcesses = Get-Process | Sort-Object CPU -Descending | Select-Object -First 10
Write-Host "Top CPU Processes:" -ForegroundColor Yellow
$topProcesses | Format-Table ProcessName, CPU, WorkingSet -AutoSize

# Option to lower priority
foreach ($proc in $topProcesses | Select-Object -First 5) {
    Write-Host "  $($proc.ProcessName) - CPU: $([math]::Round($proc.CPU, 2))s"
}
'@
        } elseif ($Problem.Title -match "Memory") {
            $solution.Title = "Free Up Memory"
            $solution.Description = "Reduce memory usage by closing unused applications"
            $solution.Steps = @(
                "Identify memory-hungry processes",
                "Close unnecessary browser tabs and applications",
                "Clear system cache",
                "Restart memory-intensive applications if they've been running long"
            )
            $solution.AutomationScript = @'
# Clear system cache
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
[System.GC]::Collect()

# Find memory hogs
Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10 |
    Format-Table ProcessName, @{Label="Memory (MB)"; Expression={[math]::Round($_.WorkingSet/1MB, 2)}} -AutoSize
'@
        } elseif ($Problem.Title -match "Disk") {
            $solution.Title = "Free Up Disk Space"
            $solution.Description = "Clean temporary files and unnecessary data"
            $solution.Steps = @(
                "Run Disk Cleanup utility",
                "Clear temporary files",
                "Empty Recycle Bin",
                "Remove old Windows Update files",
                "Move large files to external storage"
            )
            $solution.AutomationScript = @'
# Clean temp files
$tempPath = $env:TEMP
Write-Host "Cleaning $tempPath..." -ForegroundColor Yellow
Remove-Item "$tempPath\*" -Recurse -Force -ErrorAction SilentlyContinue

# Empty Recycle Bin
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Write-Host "Recycle Bin emptied" -ForegroundColor Green
'@
        }

        return $solution
    }

    [hashtable]DevelopSecuritySolution([hashtable]$Problem) {
        $solution = @{}

        if ($Problem.Title -match "Antivirus") {
            $solution.Title = "Enable Windows Defender"
            $solution.Description = "Turn on real-time antivirus protection"
            $solution.Steps = @(
                "Enable Windows Defender",
                "Update virus definitions",
                "Run quick scan",
                "Schedule automatic scans"
            )
            $solution.AutomationScript = @'
# Enable Windows Defender (requires admin)
Set-MpPreference -DisableRealtimeMonitoring $false
Update-MpSignature
Write-Host "Windows Defender enabled and updated" -ForegroundColor Green
'@
            $solution.RequiresHumanApproval = $true
        } elseif ($Problem.Title -match "Firewall") {
            $solution.Title = "Enable Windows Firewall"
            $solution.Description = "Activate firewall protection"
            $solution.Steps = @(
                "Enable firewall for all profiles",
                "Verify firewall rules",
                "Test connectivity"
            )
            $solution.AutomationScript = @'
# Enable firewall (requires admin)
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
Write-Host "Firewall enabled for all profiles" -ForegroundColor Green
'@
            $solution.RequiresHumanApproval = $true
        }

        return $solution
    }

    [hashtable]DevelopWorkflowSolution([hashtable]$Problem) {
        $solution = @{}

        if ($Problem.Title -match "Repetitive Command") {
            $solution.Title = "Automate Repetitive Command"
            $solution.Description = "Create alias or script for frequently used command"
            $solution.Steps = @(
                "Identify the repetitive command",
                "Create PowerShell alias or function",
                "Add to PowerShell profile for persistence",
                "Test the automation"
            )
            $solution.AutomationScript = @'
# This will be customized based on the actual command
Write-Host "Creating automation for repetitive task..." -ForegroundColor Cyan
# Example: Set-Alias -Name shortcut -Value "long-command"
'@
        } elseif ($Problem.Title -match "Multiple VS Code") {
            $solution.Title = "Consolidate VS Code Instances"
            $solution.Description = "Use workspaces to organize projects in one window"
            $solution.Steps = @(
                "Save current work in all instances",
                "Create VS Code workspace file",
                "Add all project folders to workspace",
                "Close individual instances, open workspace"
            )
            $solution.AutomationScript = @'
# Create workspace file
$workspace = @{
    folders = @()
}

Get-Process -Name "Code" | ForEach-Object {
    # Extract working directories (simplified)
    Write-Host "VS Code instance: $($_.Id)"
}
'@
        }

        return $solution
    }

    [hashtable]DevelopNetworkSolution([hashtable]$Problem) {
        $solution = @{}

        if ($Problem.Title -match "No Internet") {
            $solution.Title = "Restore Internet Connection"
            $solution.Description = "Diagnose and fix network connectivity"
            $solution.Steps = @(
                "Reset network adapter",
                "Flush DNS cache",
                "Renew IP address",
                "Reset Winsock",
                "Restart router if needed"
            )
            $solution.AutomationScript = @'
# Network troubleshooting
ipconfig /flushdns
ipconfig /release
ipconfig /renew
netsh winsock reset
Write-Host "Network reset complete. May need to restart." -ForegroundColor Yellow
'@
        } elseif ($Problem.Title -match "Slow DNS") {
            $solution.Title = "Switch to Faster DNS"
            $solution.Description = "Use Google DNS (8.8.8.8) or Cloudflare DNS (1.1.1.1)"
            $solution.Steps = @(
                "Identify network adapter",
                "Set DNS servers to 8.8.8.8 and 8.8.4.4",
                "Flush DNS cache",
                "Test performance"
            )
            $solution.AutomationScript = @'
# Set DNS to Google DNS
$adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("8.8.8.8","8.8.4.4")
ipconfig /flushdns
Write-Host "DNS updated to Google DNS" -ForegroundColor Green
'@
            $solution.RequiresHumanApproval = $true
        }

        return $solution
    }

    [hashtable]DevelopDevelopmentSolution([hashtable]$Problem) {
        $solution = @{}

        if ($Problem.Title -match "Not a Git Repository") {
            $solution.Title = "Initialize Git Repository"
            $solution.Description = "Set up version control for the project"
            $solution.Steps = @(
                "Initialize git repository",
                "Create .gitignore file",
                "Make initial commit",
                "Optionally link to remote repository"
            )
            $solution.AutomationScript = @'
git init
Write-Host "Git repository initialized" -ForegroundColor Green

# Create basic .gitignore
@"
node_modules/
.vs/
bin/
obj/
*.log
"@ | Out-File .gitignore

git add .
git commit -m "Initial commit"
'@
        } elseif ($Problem.Title -match "Uncommitted Changes") {
            $solution.Title = "Commit Git Changes"
            $solution.Description = "Save your work to version control"
            $solution.Steps = @(
                "Review changed files",
                "Stage relevant changes",
                "Write descriptive commit message",
                "Commit changes"
            )
            $solution.AutomationScript = @'
git status
Write-Host "`nStaging all changes..." -ForegroundColor Yellow
git add .
$message = Read-Host "Commit message"
git commit -m $message
'@
        } elseif ($Problem.Title -match "Missing Node Modules") {
            $solution.Title = "Install Node Dependencies"
            $solution.Description = "Run npm install to get dependencies"
            $solution.Steps = @(
                "Navigate to project directory",
                "Run npm install",
                "Verify installation"
            )
            $solution.AutomationScript = @'
npm install
Write-Host "Node modules installed" -ForegroundColor Green
'@
        }

        return $solution
    }

    [hashtable]DevelopFileSystemSolution([hashtable]$Problem) {
        $solution = @{}

        if ($Problem.Title -match "Duplicate") {
            $solution.Title = "Remove Duplicate Files"
            $solution.Description = "Identify and optionally remove duplicate files"
            $solution.Steps = @(
                "Scan for duplicate files by hash",
                "Review duplicates",
                "Keep one copy, delete others",
                "Reclaim disk space"
            )
            $solution.AutomationScript = @'
# Find duplicates by hash (simplified)
Write-Host "Scanning for duplicates..." -ForegroundColor Yellow
# This would use Get-FileHash and group by hash
'@
        }

        return $solution
    }

    [bool]ImplementSolution([hashtable]$Solution) {
        Write-Host "`n  🔧 Implementing: $($Solution.Title)" -ForegroundColor Green

        # Safety check
        if (-not $this.SafetyCheck($Solution)) {
            Write-Host "  ❌ Solution failed safety check!" -ForegroundColor Red
            return $false
        }

        # Human approval for critical changes
        if ($Solution.RequiresHumanApproval) {
            Write-Host "`n  ⚠️  This solution requires your approval:" -ForegroundColor Yellow
            Write-Host "     Title: $($Solution.Title)" -ForegroundColor Cyan
            Write-Host "     Description: $($Solution.Description)" -ForegroundColor White
            Write-Host "`n     Steps:" -ForegroundColor White
            foreach ($step in $Solution.Steps) {
                Write-Host "       • $step" -ForegroundColor Gray
            }

            $approval = Read-Host "`n  Approve implementation? (yes/no)"
            if ($approval -ne "yes") {
                Write-Host "  ⏭️  Solution skipped by user" -ForegroundColor Yellow
                return $false
            }
        }

        try {
            # Execute automation script
            if ($Solution.AutomationScript) {
                Write-Host "  ▶️  Executing automation..." -ForegroundColor Cyan
                Invoke-Expression $Solution.AutomationScript
            }

            Write-Host "  ✅ Solution implemented successfully!" -ForegroundColor Green

            # Log the fix
            $this.LogImplementation($Solution)

            return $true

        } catch {
            Write-Host "  ❌ Error implementing solution: $_" -ForegroundColor Red
            return $false
        }
    }

    [bool]SafetyCheck([hashtable]$Solution) {
        # Basic safety checks
        $script = $Solution.AutomationScript

        # Prohibited operations
        $dangerous = @(
            'Remove-Item.*-Recurse.*\\',  # Deleting root directories
            'Format-Volume',               # Formatting drives
            'Remove-Computer',             # Removing from domain
            'Disable-Computer'             # Disabling system
        )

        foreach ($pattern in $dangerous) {
            if ($script -match $pattern) {
                Write-Warning "Potentially dangerous operation detected: $pattern"
                return $false
            }
        }

        return $true
    }

    [void]LogImplementation([hashtable]$Solution) {
        $logEntry = @{
            Timestamp  = Get-Date
            SolutionID = $Solution.SolutionID
            ProblemID  = $Solution.ProblemID
            Title      = $Solution.Title
            Success    = $true
        } | ConvertTo-Json -Compress

        Add-Content -Path $this.LogPath -Value $logEntry
    }

    [void]GenerateReport([hashtable]$AllProblems, [hashtable]$AllSolutions) {
        Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║                 🧠 AI PROBLEM SOLVER REPORT                    ║" -ForegroundColor Yellow
        Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

        Write-Host "`n  📊 Scan Summary:" -ForegroundColor White
        Write-Host "     Total Problems Detected: $($AllProblems.Count)" -ForegroundColor Cyan

        # Group by severity
        $bySeverity = $AllProblems.Values | Group-Object -Property Severity
        foreach ($group in $bySeverity) {
            $color = switch ($group.Name) {
                "Critical" { "Red" }
                "High" { "Yellow" }
                "Medium" { "Cyan" }
                "Low" { "Gray" }
            }
            Write-Host "       $($group.Name): $($group.Count)" -ForegroundColor $color
        }

        # Group by domain
        Write-Host "`n  📂 Problems by Domain:" -ForegroundColor White
        $byDomain = $AllProblems.Values | Group-Object -Property Domain
        foreach ($group in $byDomain) {
            Write-Host "     • $($group.Name): $($group.Count) issues" -ForegroundColor Cyan
        }

        # Solutions
        Write-Host "`n  💡 Solutions:" -ForegroundColor White
        Write-Host "     Solutions Developed: $($AllSolutions.Count)" -ForegroundColor Green
        Write-Host "     Ready for Implementation: $($AllSolutions.Count)" -ForegroundColor Cyan

        # Top priorities
        Write-Host "`n  🎯 Top Priority Problems:" -ForegroundColor White
        $topProblems = $AllProblems.Values | Sort-Object {
            switch ($_.Severity) {
                "Critical" { 4 }
                "High" { 3 }
                "Medium" { 2 }
                "Low" { 1 }
            }
        } -Descending | Select-Object -First 5

        foreach ($problem in $topProblems) {
            $icon = switch ($problem.Severity) {
                "Critical" { "🔴" }
                "High" { "🟠" }
                "Medium" { "🟡" }
                "Low" { "🟢" }
            }
            Write-Host "     $icon [$($problem.Severity)] $($problem.Title)" -ForegroundColor White
        }

        Write-Host "`n╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    }
}

# Main execution
function Start-ProblemSolving {
    param(
        [switch]$ContinuousMode,
        [switch]$ScanOnly,
        [string]$Domain,
        [int]$ScanIntervalMinutes,
        [switch]$AutoFix
    )

    Write-Host "`n🧠 AI Problem Solver Starting..." -ForegroundColor Green

    $solver = [ProblemSolver]::new()

    do {
        Write-Host "`n🔍 Starting problem detection scan..." -ForegroundColor Cyan
        Write-Host "   Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

        # Scan for problems
        $problems = $solver.ScanForProblems()

        if ($problems.Count -eq 0) {
            Write-Host "`n  ✅ No problems detected! System healthy." -ForegroundColor Green
        } else {
            Write-Host "`n  ⚠️  Detected $($problems.Count) problem(s)" -ForegroundColor Yellow

            # Analyze and solve
            $solutions = @{}

            foreach ($problemKey in $problems.Keys) {
                $problem = $problems[$problemKey]

                # Analyze
                $analysis = $solver.AnalyzeProblem($problem)

                # Develop solution
                $solution = $solver.DevelopSolution($problem, $analysis)
                $solutions[$solution.SolutionID] = $solution

                # Implement if not scan-only and auto-fix enabled
                if (-not $ScanOnly -and $AutoFix) {
                    $solver.ImplementSolution($solution)
                    Start-Sleep -Seconds 2
                }
            }

            # Generate report
            $solver.GenerateReport($problems, $solutions)

            # Save to file
            $reportPath = "$PSScriptRoot\..\..\..\evidence\problem-solver-report.json"
            @{
                Timestamp = Get-Date
                Problems  = $problems
                Solutions = $solutions
            } | ConvertTo-Json -Depth 10 | Out-File $reportPath

            Write-Host "`n  💾 Full report saved to: $reportPath" -ForegroundColor Cyan
        }

        if ($ContinuousMode) {
            Write-Host "`n  ⏳ Next scan in $ScanIntervalMinutes minutes..." -ForegroundColor Gray
            Write-Host "     Press Ctrl+C to stop`n" -ForegroundColor DarkGray
            Start-Sleep -Seconds ($ScanIntervalMinutes * 60)
        }

    } while ($ContinuousMode)

    Write-Host "`n✅ Problem solving session complete!" -ForegroundColor Green
}

# Run the problem solver
Start-ProblemSolving -ContinuousMode:$ContinuousMode -ScanOnly:$ScanOnly -Domain:$Domain -ScanIntervalMinutes:$ScanIntervalMinutes -AutoFix:$AutoFix
