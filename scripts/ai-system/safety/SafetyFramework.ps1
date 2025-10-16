<#
.SYNOPSIS
    AI Safety Framework - "First Rule: DO NO HARM"
    
.DESCRIPTION
    Core safety module that enforces safety principles for all AI operations.
    This module CANNOT be disabled and operates at the highest priority level.
    
.NOTES
    Priority: CRITICAL
    Overridable: NO
    Required: YES
#>

#Requires -Version 5.1

# ============================================
# PROHIBITED ACTIONS (Hard Constraints)
# ============================================

$script:ProhibitedPatterns = @(
    # Data destruction
    'Remove-Item.*-Recurse.*C:\\Users',
    'Remove-Item.*-Recurse.*C:\\Windows',
    'Format-Volume',
    'Clear-Disk',
    'Remove-Partition',
    
    # Security bypass
    'Disable-WindowsDefender',
    'Set-ExecutionPolicy.*Unrestricted',
    'Disable-Firewall',
    'Grant-.*-Privilege',
    
    # Secret exposure
    'Write-(Host|Output|Log).*password',
    'Write-(Host|Output|Log).*api[_-]?key',
    'Write-(Host|Output|Log).*secret',
    'Write-(Host|Output|Log).*token',
    
    # System damage
    'Stop-Service.*wuauserv', # Windows Update
    'Stop-Service.*Winmgmt', # WMI
    'Stop-Service.*RpcSs', # RPC
    'Remove-Item.*\$env:SystemRoot',
    
    # Network attacks
    'Invoke-WebRequest.*--data.*password',
    'Send-.*-Credential',
    'Invoke-Expression.*\$env:',
    
    # Resource exhaustion
    'while.*\$true.*Start-Process',
    'for.*1\.\.999999.*Start-Job',
    ':\(\)\{.*:\|\:.*\}' # Fork bomb pattern
)

# ============================================
# RISK CLASSIFICATION
# ============================================

enum RiskLevel {
    SAFE = 0
    LOW = 1
    MEDIUM = 2
    HIGH = 3
    CRITICAL = 4
}

class RiskAssessment {
    [string]$ActionId
    [string]$Action
    [RiskLevel]$Level
    [int]$Score
    [string[]]$Factors
    [bool]$Reversible
    [bool]$BackupRequired
    [bool]$ApprovalRequired
    [hashtable]$Mitigation
    
    RiskAssessment([string]$Action) {
        $this.ActionId = (New-Guid).ToString()
        $this.Action = $Action
        $this.Factors = @()
        $this.Mitigation = @{}
    }
}

# ============================================
# SAFETY FUNCTIONS
# ============================================

function Test-ProhibitedAction {
    <#
    .SYNOPSIS
        Tests if an action matches any prohibited patterns
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Action
    )
    
    foreach ($Pattern in $script:ProhibitedPatterns) {
        if ($Action -match $Pattern) {
            Write-SafetyLog "BLOCKED: Prohibited pattern matched: $Pattern" -Level CRITICAL
            return $true
        }
    }
    
    return $false
}

function Get-RiskAssessment {
    <#
    .SYNOPSIS
        Calculates risk assessment for an action
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Action,
        
        [hashtable]$Context = @{}
    )
    
    $Assessment = [RiskAssessment]::new($Action)
    $Score = 0
    
    # Analyze action type
    if ($Action -match 'delete|remove|drop|truncate|clear|format') {
        $Score += 50
        $Assessment.Factors += "Destructive operation"
    }
    
    if ($Action -match 'modify|update|change|alter|set|edit') {
        $Score += 30
        $Assessment.Factors += "Modification operation"
    }
    
    if ($Action -match 'registry|regedit|reg add') {
        $Score += 25
        $Assessment.Factors += "Registry modification"
    }
    
    if ($Action -match 'service|firewall|defender|security') {
        $Score += 35
        $Assessment.Factors += "System security change"
    }
    
    # Analyze scope
    if ($Context.Scope -eq 'System') {
        $Score += 30
        $Assessment.Factors += "System-wide scope"
    } elseif ($Context.Scope -eq 'User') {
        $Score += 20
        $Assessment.Factors += "User-wide scope"
    }
    
    # Analyze data impact
    if ($Context.AffectedFiles -gt 1000) {
        $Score += 20
        $Assessment.Factors += "Large file count: $($Context.AffectedFiles)"
    }
    
    if ($Context.AffectedSizeGB -gt 10) {
        $Score += 20
        $Assessment.Factors += "Large data size: $($Context.AffectedSizeGB)GB"
    }
    
    # Check reversibility
    $Assessment.Reversible = $Context.ContainsKey('Rollback') -and $null -ne $Context.Rollback
    if (-not $Assessment.Reversible) {
        $Score += 40
        $Assessment.Factors += "Not reversible"
    }
    
    # Check backup
    $Assessment.BackupRequired = $Score -ge 30
    if ($Assessment.BackupRequired -and -not $Context.BackupExists) {
        $Score += 30
        $Assessment.Factors += "No backup exists"
    }
    
    # Calculate final score and level
    $Assessment.Score = $Score
    $Assessment.Level = switch ($Score) {
        { $_ -ge 100 } { [RiskLevel]::CRITICAL; break }
        { $_ -ge 70 } { [RiskLevel]::HIGH; break }
        { $_ -ge 40 } { [RiskLevel]::MEDIUM; break }
        { $_ -ge 15 } { [RiskLevel]::LOW; break }
        default { [RiskLevel]::SAFE }
    }
    
    # Determine approval requirement
    $Assessment.ApprovalRequired = $Assessment.Level -in @([RiskLevel]::HIGH, [RiskLevel]::CRITICAL)
    
    # Generate mitigation
    $Assessment.Mitigation = Get-MitigationStrategy -Assessment $Assessment
    
    return $Assessment
}

function Get-MitigationStrategy {
    param([RiskAssessment]$Assessment)
    
    $Mitigation = @{
        Strategies = @()
        PreChecks = @()
        PostChecks = @()
        Rollback = $null
    }
    
    # Risk-level specific mitigations
    switch ($Assessment.Level) {
        ([RiskLevel]::CRITICAL) {
            $Mitigation.Strategies += "Create system restore point"
            $Mitigation.Strategies += "Require multi-factor approval"
            $Mitigation.Strategies += "Execute in dry-run mode first"
            $Mitigation.Strategies += "Create full system backup"
            $Mitigation.PreChecks += "Verify backup integrity"
            $Mitigation.PostChecks += "Verify system health"
        }
        
        ([RiskLevel]::HIGH) {
            $Mitigation.Strategies += "Create backup before execution"
            $Mitigation.Strategies += "Require user approval"
            $Mitigation.Strategies += "Enable detailed logging"
            $Mitigation.PreChecks += "Verify backup exists"
            $Mitigation.PostChecks += "Verify operation success"
        }
        
        ([RiskLevel]::MEDIUM) {
            $Mitigation.Strategies += "Create checkpoint"
            $Mitigation.Strategies += "Enable rollback mechanism"
            $Mitigation.PostChecks += "Verify expected outcome"
        }
    }
    
    # Specific mitigations based on factors
    if ($Assessment.Factors -contains "Destructive operation") {
        $Mitigation.Strategies += "Verify backup before deletion"
        $Mitigation.Rollback = "Restore from backup"
    }
    
    if ($Assessment.Factors -contains "System security change") {
        $Mitigation.Strategies += "Log security state before change"
        $Mitigation.Rollback = "Restore previous security state"
    }
    
    return $Mitigation
}

function Invoke-SafetyCheck {
    <#
    .SYNOPSIS
        Main safety gatekeeper - all AI actions must pass through this
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Action,
        
        [hashtable]$Context = @{},
        
        [switch]$Force
    )
    
    Write-SafetyLog "SAFETY_CHECK: Evaluating action: $Action" -Level INFO
    
    # Step 1: Check prohibited actions (HARD BLOCK)
    if (Test-ProhibitedAction -Action $Action) {
        Write-SafetyLog "BLOCKED: Action matches prohibited pattern: $Action" -Level CRITICAL
        Send-SafetyAlert -Severity CRITICAL -Message "Prohibited action blocked: $Action"
        return @{
            Approved = $false
            Reason = "Prohibited action"
            RiskLevel = [RiskLevel]::CRITICAL
        }
    }
    
    # Step 2: Risk assessment
    $Assessment = Get-RiskAssessment -Action $Action -Context $Context
    Write-SafetyLog "RISK_ASSESSMENT: Level=$($Assessment.Level), Score=$($Assessment.Score)" -Level INFO
    
    # Step 3: Backup verification for destructive ops
    if ($Assessment.BackupRequired -and -not $Context.BackupExists) {
        Write-SafetyLog "BLOCKED: Backup required but not found: $Action" -Level ERROR
        return @{
            Approved = $false
            Reason = "Backup required but missing"
            RiskLevel = $Assessment.Level
            Mitigation = $Assessment.Mitigation
        }
    }
    
    # Step 4: User approval for high-risk actions
    if ($Assessment.ApprovalRequired -and -not $Force) {
        Write-SafetyLog "APPROVAL_REQUIRED: Requesting user approval for: $Action" -Level WARN
        
        $Approved = Request-UserApproval -Action $Action -Assessment $Assessment
        
        if (-not $Approved) {
            Write-SafetyLog "BLOCKED: User approval denied: $Action" -Level WARN
            return @{
                Approved = $false
                Reason = "User approval required but denied"
                RiskLevel = $Assessment.Level
                Assessment = $Assessment
            }
        }
    }
    
    # Step 5: All checks passed
    Write-SafetyLog "APPROVED: Action passed all safety checks: $Action" -Level SUCCESS
    
    return @{
        Approved = $true
        Reason = "Passed all safety checks"
        RiskLevel = $Assessment.Level
        Assessment = $Assessment
        Mitigation = $Assessment.Mitigation
    }
}

function Request-UserApproval {
    param(
        [string]$Action,
        [RiskAssessment]$Assessment
    )
    
    Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║           AI SAFETY: APPROVAL REQUIRED                ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════════════════════╝`n" -ForegroundColor Yellow
    
    Write-Host "Risk Level: " -NoNewline
    Write-Host $Assessment.Level -ForegroundColor $(switch($Assessment.Level) {
        ([RiskLevel]::CRITICAL) { "Red" }
        ([RiskLevel]::HIGH) { "Red" }
        ([RiskLevel]::MEDIUM) { "Yellow" }
        default { "Green" }
    })
    
    Write-Host "`nProposed Action:" -ForegroundColor Cyan
    Write-Host "  $Action`n"
    
    Write-Host "Risk Factors:" -ForegroundColor Yellow
    foreach ($Factor in $Assessment.Factors) {
        Write-Host "  • $Factor"
    }
    
    Write-Host "`nMitigation Strategies:" -ForegroundColor Green
    foreach ($Strategy in $Assessment.Mitigation.Strategies) {
        Write-Host "  • $Strategy"
    }
    
    Write-Host "`nDo you approve this action? (Yes/No): " -NoNewline -ForegroundColor Yellow
    $Response = Read-Host
    
    $Approved = $Response -in @('y', 'yes', 'Y', 'Yes', 'YES')
    
    Write-SafetyLog "USER_APPROVAL: Action='$Action', Approved=$Approved" -Level INFO
    
    return $Approved
}

function Write-SafetyLog {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'CRITICAL', 'SUCCESS')]
        [string]$Level = 'INFO'
    )
    
    $LogDir = "ai-system\logs\safety"
    if (-not (Test-Path $LogDir)) {
        New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
    }
    
    $LogFile = Join-Path $LogDir "safety-$(Get-Date -Format 'yyyyMMdd').log"
    
    $LogEntry = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Level = $Level
        Message = $Message
        Source = "SafetyFramework"
    }
    
    $LogEntry | ConvertTo-Json -Compress | Add-Content $LogFile
    
    # Console output with color
    $Color = switch ($Level) {
        'INFO' { 'Cyan' }
        'WARN' { 'Yellow' }
        'ERROR' { 'Red' }
        'CRITICAL' { 'Red' }
        'SUCCESS' { 'Green' }
    }
    
    Write-Host "[$Level] $Message" -ForegroundColor $Color
}

function Send-SafetyAlert {
    param(
        [ValidateSet('INFO', 'WARN', 'ERROR', 'CRITICAL')]
        [string]$Severity,
        [string]$Message
    )
    
    # Log alert
    Write-SafetyLog "ALERT: [$Severity] $Message" -Level $Severity
    
    # For critical alerts, could integrate with notification systems
    if ($Severity -eq 'CRITICAL') {
        # Show desktop notification
        if (Get-Command New-BurntToastNotification -ErrorAction SilentlyContinue) {
            New-BurntToastNotification -Text "AI Safety Alert", $Message -Sound "Alarm"
        }
    }
}

function Invoke-EmergencyStop {
    <#
    .SYNOPSIS
        Emergency stop all AI operations
    #>
    [CmdletBinding()]
    param(
        [string]$Reason = "Emergency stop requested"
    )
    
    Write-SafetyLog "EMERGENCY_STOP: $Reason" -Level CRITICAL
    
    # Stop all AI jobs
    Get-Job | Where-Object { $_.Name -like "AI-*" } | Stop-Job -Force
    
    # Log emergency stop
    $StopRecord = @{
        Timestamp = Get-Date
        Reason = $Reason
        StoppedJobs = (Get-Job | Where-Object { $_.Name -like "AI-*" }).Count
    }
    
    $StopRecord | ConvertTo-Json | Add-Content "ai-system\logs\safety\emergency-stops.log"
    
    Write-Host "`n🚨 EMERGENCY STOP EXECUTED 🚨" -ForegroundColor Red -BackgroundColor Yellow
    Write-Host "All AI agents have been stopped." -ForegroundColor Red
    Write-Host "Reason: $Reason" -ForegroundColor Yellow
}

# ============================================
# EXPORT MODULE MEMBERS
# ============================================

Export-ModuleMember -Function @(
    'Test-ProhibitedAction',
    'Get-RiskAssessment',
    'Invoke-SafetyCheck',
    'Request-UserApproval',
    'Write-SafetyLog',
    'Send-SafetyAlert',
    'Invoke-EmergencyStop'
)
