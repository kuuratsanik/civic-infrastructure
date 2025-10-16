<#
.SYNOPSIS
    Core module for Windows 11 Pro civic infrastructure ceremonies
    
.DESCRIPTION
    Provides foundational functions for conducting ceremonial customizations
    with proper governance, audit trails, and reproducibility patterns.
    
.NOTES
    Author: Civic Infrastructure Team
    Version: 1.0.0
    Requires: PowerShell 5.1+
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

# Module-level variables
$Script:AuditLogPath = "$env:USERPROFILE\Documents\WindowsGovernance\AuditTrail.jsonl"
$Script:ConfigHashPath = "$env:USERPROFILE\Documents\WindowsGovernance\ConfigHashes.json"

<#
.SYNOPSIS
    Initializes the civic governance structure
#>
function Initialize-CivicGovernance {
    [CmdletBinding()]
    param()
    
    Write-Host "=== Initializing Civic Governance Structure ===" -ForegroundColor Cyan
    
    $GovernanceDir = "$env:USERPROFILE\Documents\WindowsGovernance"
    if (-not (Test-Path $GovernanceDir)) {
        New-Item -Path $GovernanceDir -ItemType Directory -Force | Out-Null
        Write-Host "   Created governance directory: $GovernanceDir" -ForegroundColor Green
    }
    
    # Initialize audit trail
    if (-not (Test-Path $Script:AuditLogPath)) {
        @() | ConvertTo-Json | Out-File -FilePath $Script:AuditLogPath -Encoding UTF8
        Write-Host "   Initialized audit trail: $Script:AuditLogPath" -ForegroundColor Green
    }
    
    # Initialize config hash registry
    if (-not (Test-Path $Script:ConfigHashPath)) {
        @{} | ConvertTo-Json | Out-File -FilePath $Script:ConfigHashPath -Encoding UTF8
        Write-Host "   Initialized config hash registry: $Script:ConfigHashPath" -ForegroundColor Green
    }
}

<#
.SYNOPSIS
    Records a ceremonial action in the audit trail
#>
function Write-CeremonialAudit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Action,
        
        [Parameter(Mandatory)]
        [string]$Layer,
        
        [string]$ConfigHash,
        
        [hashtable]$Metadata = @{},
        
        [ValidateSet('Success', 'Warning', 'Error')]
        [string]$Status = 'Success'
    )
    
    $AuditEntry = @{
        Timestamp = (Get-Date).ToString('o')
        Action = $Action
        Layer = $Layer
        Status = $Status
        ConfigHash = $ConfigHash
        Machine = $env:COMPUTERNAME
        User = $env:USERNAME
        Metadata = $Metadata
    }
    
    # Append to audit trail
    $AuditEntry | ConvertTo-Json -Compress | Add-Content -Path $Script:AuditLogPath -Encoding UTF8
    
    $StatusColor = switch ($Status) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
    }
    
    Write-Host "   AUDIT: $Action ($Status)" -ForegroundColor $StatusColor
}

<#
.SYNOPSIS
    Computes and anchors a configuration hash
#>
function Set-ConfigurationAnchor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigName,
        
        [Parameter(Mandatory)]
        [string]$ConfigPath,
        
        [string]$Layer = 'General'
    )
    
    if (-not (Test-Path $ConfigPath)) {
        Write-Warning "Configuration file not found: $ConfigPath"
        return $null
    }
    
    # Compute hash
    $Hash = Get-FileHash -Path $ConfigPath -Algorithm SHA256
    
    # Load existing hashes
    $HashRegistry = @{}
    if (Test-Path $Script:ConfigHashPath) {
        $HashData = Get-Content $Script:ConfigHashPath | ConvertFrom-Json
        # Convert PSCustomObject to hashtable for PowerShell 5.1 compatibility
        $HashRegistry = @{}
        if ($HashData) {
            $HashData.PSObject.Properties | ForEach-Object {
                $HashRegistry[$_.Name] = $_.Value
            }
        }
    }
    
    # Add/update hash
    $HashRegistry[$ConfigName] = @{
        Hash = $Hash.Hash
        Path = $ConfigPath
        Layer = $Layer
        Timestamp = (Get-Date).ToString('o')
    }
    
    # Save hash registry
    $HashRegistry | ConvertTo-Json -Depth 3 | Out-File -FilePath $Script:ConfigHashPath -Encoding UTF8
    
    Write-Host "   ANCHOR: Configuration anchored: $ConfigName" -ForegroundColor Magenta
    Write-Host "       Hash: $($Hash.Hash.Substring(0,16))..." -ForegroundColor Gray
    
    return $Hash.Hash
}

<#
.SYNOPSIS
    Validates configuration integrity against anchored hashes
#>
function Test-ConfigurationIntegrity {
    [CmdletBinding()]
    param(
        [string]$ConfigName
    )
    
    if (-not (Test-Path $Script:ConfigHashPath)) {
        Write-Warning "No configuration hash registry found"
        return $false
    }
    
    $HashData = Get-Content $Script:ConfigHashPath | ConvertFrom-Json
    $HashRegistry = @{}
    if ($HashData) {
        $HashData.PSObject.Properties | ForEach-Object {
            $HashRegistry[$_.Name] = $_.Value
        }
    }
    
    if ($ConfigName) {
        # Test specific configuration
        if (-not $HashRegistry.ContainsKey($ConfigName)) {
            Write-Warning "Configuration '$ConfigName' not found in hash registry"
            return $false
        }
        
        $Config = $HashRegistry[$ConfigName]
        if (-not (Test-Path $Config.Path)) {
            Write-Warning "Configuration file not found: $($Config.Path)"
            return $false
        }
        
        $CurrentHash = (Get-FileHash -Path $Config.Path -Algorithm SHA256).Hash
        $Valid = $CurrentHash -eq $Config.Hash
        
        if ($Valid) {
            Write-Host "   SUCCESS: Configuration '$ConfigName' integrity verified" -ForegroundColor Green
        } else {
            Write-Host "   FAILED: Configuration '$ConfigName' integrity FAILED" -ForegroundColor Red
        }
        
        return $Valid
    } else {
        # Test all configurations
        $AllValid = $true
        foreach ($Name in $HashRegistry.Keys) {
            $Valid = Test-ConfigurationIntegrity -ConfigName $Name
            $AllValid = $AllValid -and $Valid
        }
        return $AllValid
    }
}

<#
.SYNOPSIS
    Executes a ceremonial script with proper governance
#>
function Invoke-CeremonialScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory)]
        [string]$CeremonyName,
        
        [Parameter(Mandatory)]
        [string]$Layer,
        
        [hashtable]$Parameters = @{},
        
        [switch]$WhatIf
    )
    
    Write-Host "=== Beginning Ceremony: $CeremonyName ===" -ForegroundColor Cyan
    Write-Host "   Layer: $Layer" -ForegroundColor Gray
    Write-Host "   Script: $ScriptPath" -ForegroundColor Gray
    
    if (-not (Test-Path $ScriptPath)) {
        Write-Error "Ceremonial script not found: $ScriptPath"
        return
    }
    
    try {
        $StartTime = Get-Date
        
        if ($WhatIf) {
            Write-Host "   [WHAT-IF MODE] Would execute: $ScriptPath" -ForegroundColor Yellow
            $Status = 'Success'
        } else {
            # Execute the ceremonial script
            & $ScriptPath @Parameters
            $Status = if ($LASTEXITCODE -eq 0) { 'Success' } else { 'Error' }
        }
        
        $Duration = (Get-Date) - $StartTime
        
        Write-CeremonialAudit -Action "Ceremony: $CeremonyName" -Layer $Layer -Status $Status -Metadata @{
            Script = $ScriptPath
            Duration = $Duration.TotalSeconds
            Parameters = $Parameters
            WhatIf = $WhatIf.IsPresent
        }
        
        Write-Host "=== Ceremony completed: $CeremonyName ($($Duration.TotalSeconds.ToString('F2'))s) ===" -ForegroundColor Green
        
    } catch {
        Write-Error "Ceremony failed: $($_.Exception.Message)"
        Write-CeremonialAudit -Action "Ceremony: $CeremonyName" -Layer $Layer -Status 'Error' -Metadata @{
            Script = $ScriptPath
            Error = $_.Exception.Message
            Parameters = $Parameters
        }
    }
}

<#
.SYNOPSIS
    Exports ceremonial configuration for reproducibility
#>
function Export-CeremonialConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigName,
        
        [Parameter(Mandatory)]
        [string]$ExportPath,
        
        [scriptblock]$ExportScript
    )
    
    Write-Host "=== Exporting ceremonial configuration: $ConfigName ===" -ForegroundColor Cyan
    
    try {
        if ($ExportScript) {
            & $ExportScript
        }
        
        if (Test-Path $ExportPath) {
            $Hash = Set-ConfigurationAnchor -ConfigName $ConfigName -ConfigPath $ExportPath
            Write-Host "   SUCCESS: Configuration exported and anchored" -ForegroundColor Green
            return $Hash
        } else {
            Write-Warning "Export failed - file not created: $ExportPath"
            return $null
        }
        
    } catch {
        Write-Error "Export failed: $($_.Exception.Message)"
        return $null
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-CivicGovernance',
    'Write-CeremonialAudit',
    'Set-ConfigurationAnchor',
    'Test-ConfigurationIntegrity',
    'Invoke-CeremonialScript',
    'Export-CeremonialConfig'
)