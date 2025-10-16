<#
.SYNOPSIS
    Foundation Ceremony - Initialize Windows 11 Pro civic infrastructure
    
.DESCRIPTION
    Establishes the foundational layer for treating Windows 11 Pro as 
    reproducible, auditable civic infrastructure. This ceremony sets up
    the basic governance structure and system identity.
    
.NOTES
    Layer: 01-Foundation
    Requires: Administrator privileges
    Duration: ~5 minutes
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$SkipBitLocker
)

# Import the civic governance module
$ModulePath = Join-Path $PSScriptRoot "..\..\modules\CivicGovernance.psm1"
Import-Module $ModulePath -Force

Write-Host "=== Windows 11 Pro Foundation Ceremony ===" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Initialize civic governance
Initialize-CivicGovernance

Write-Host "`nPhase 1: System Identity Setup" -ForegroundColor Yellow

# Set computer description for civic identification
$ComputerDescription = "Windows 11 Pro - Civic Infrastructure Node"
if ($PSCmdlet.ShouldProcess("Computer Description", "Set to '$ComputerDescription'")) {
    try {
        # Using WMI to set computer description
        $Computer = Get-WmiObject -Class Win32_OperatingSystem
        $Computer.Description = $ComputerDescription
        $Computer.Put() | Out-Null
        
        Write-Host "   Success: Computer description set to civic infrastructure identifier" -ForegroundColor Green
        
        Write-CeremonialAudit -Action "Set Computer Description" -Layer "Foundation" -Metadata @{
            Description = $ComputerDescription
        }
    } catch {
        Write-Warning "Failed to set computer description: $($_.Exception.Message)"
    }
}

Write-Host "`nPhase 2: Security Foundation" -ForegroundColor Yellow

# Check BitLocker status
if (-not $SkipBitLocker) {
    if ($PSCmdlet.ShouldProcess("BitLocker", "Check and configure")) {
        try {
            $BitLockerStatus = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue
            
            if ($BitLockerStatus) {
                if ($BitLockerStatus.ProtectionStatus -eq "On") {
                    Write-Host "   SUCCESS: BitLocker is already enabled on system drive" -ForegroundColor Green
                } else {
                    Write-Host "   WARNING: BitLocker is available but not enabled" -ForegroundColor Yellow
                    Write-Host "     Run 'Enable-BitLocker -MountPoint C: -TpmProtector' to enable" -ForegroundColor Gray
                }
            } else {
                Write-Host "   WARNING: BitLocker not available or accessible" -ForegroundColor Yellow
            }
            
            Write-CeremonialAudit -Action "Check BitLocker Status" -Layer "Foundation" -Metadata @{
                Available = ($null -ne $BitLockerStatus)
                Enabled = ($BitLockerStatus.ProtectionStatus -eq "On")
            }
        } catch {
            Write-Warning "Failed to check BitLocker status: $($_.Exception.Message)"
        }
    }
}

Write-Host "`nPhase 3: System Information Audit" -ForegroundColor Yellow

# Gather and log system information for governance
if ($PSCmdlet.ShouldProcess("System Information", "Audit and log")) {
    try {
        $SystemInfo = @{
            ComputerName = $env:COMPUTERNAME
            OSVersion = (Get-WmiObject -Class Win32_OperatingSystem).Version
            OSBuild = (Get-WmiObject -Class Win32_OperatingSystem).BuildNumber
            OSArchitecture = (Get-WmiObject -Class Win32_OperatingSystem).OSArchitecture
            TotalMemory = [math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
            Processor = (Get-WmiObject -Class Win32_Processor).Name
            Domain = (Get-WmiObject -Class Win32_ComputerSystem).Domain
            Workgroup = (Get-WmiObject -Class Win32_ComputerSystem).Workgroup
        }
        
        Write-Host "   SUCCESS: System information gathered for civic registry" -ForegroundColor Green
        Write-Host "     Computer: $($SystemInfo.ComputerName)" -ForegroundColor Gray
        Write-Host "     OS Build: $($SystemInfo.OSBuild)" -ForegroundColor Gray
        Write-Host "     Memory: $($SystemInfo.TotalMemory) GB" -ForegroundColor Gray
        
        Write-CeremonialAudit -Action "System Information Audit" -Layer "Foundation" -Metadata $SystemInfo
        
        # Export system baseline
        $BaselinePath = "$env:USERPROFILE\Documents\WindowsGovernance\SystemBaseline.json"
        $SystemInfo | ConvertTo-Json -Depth 2 | Out-File -FilePath $BaselinePath -Encoding UTF8
        
        Set-ConfigurationAnchor -ConfigName "SystemBaseline" -ConfigPath $BaselinePath -Layer "Foundation"
        
    } catch {
        Write-Warning "Failed to audit system information: $($_.Exception.Message)"
    }
}

Write-Host "`nPhase 4: Governance Directory Structure" -ForegroundColor Yellow

# Create standard directories for civic governance
$GovernanceDirs = @(
    "$env:USERPROFILE\Documents\WindowsGovernance\Ceremonies",
    "$env:USERPROFILE\Documents\WindowsGovernance\Configurations",
    "$env:USERPROFILE\Documents\WindowsGovernance\Scripts",
    "$env:USERPROFILE\Documents\WindowsGovernance\Backups"
)

foreach ($Dir in $GovernanceDirs) {
    if ($PSCmdlet.ShouldProcess($Dir, "Create governance directory")) {
        if (-not (Test-Path $Dir)) {
            New-Item -Path $Dir -ItemType Directory -Force | Out-Null
            Write-Host "   SUCCESS: Created: $Dir" -ForegroundColor Green
        } else {
            Write-Host "   EXISTS: $Dir" -ForegroundColor Gray
        }
    }
}

Write-CeremonialAudit -Action "Create Governance Directories" -Layer "Foundation" -Metadata @{
    Directories = $GovernanceDirs
}

Write-Host "`nPhase 5: Foundation Documentation" -ForegroundColor Yellow

# Create foundation ceremony log
$CeremonyLogPath = "$env:USERPROFILE\Documents\WindowsGovernance\Ceremonies\01-Foundation.md"
$CeremonyLog = @"
# Foundation Ceremony Log

**Date**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  
**Computer**: $env:COMPUTERNAME  
**User**: $env:USERNAME  

## Ceremony Actions

- [x] Civic governance structure initialized
- [x] Computer description set to civic infrastructure identifier
- [x] BitLocker status checked and documented
- [x] System information audited and baselined
- [x] Governance directory structure created
- [x] Foundation ceremony documented

## Next Steps

1. Run Governance ceremony: `.\scripts\ceremonies\02-governance\Apply-GovernancePolicies.ps1`
2. Configure operational hygiene: `.\scripts\ceremonies\03-operational-hygiene\`
3. Set up developer environment: `.\scripts\ceremonies\05-developer-cockpit\`

## Audit Trail

All ceremonial actions have been recorded in the civic audit trail:
`$env:USERPROFILE\Documents\WindowsGovernance\AuditTrail.jsonl`

Configuration hashes are anchored in:
`$env:USERPROFILE\Documents\WindowsGovernance\ConfigHashes.json`
"@

if ($PSCmdlet.ShouldProcess($CeremonyLogPath, "Create ceremony documentation")) {
    $CeremonyLog | Out-File -FilePath $CeremonyLogPath -Encoding UTF8
    Write-Host "   SUCCESS: Foundation ceremony documented" -ForegroundColor Green
    
    Set-ConfigurationAnchor -ConfigName "FoundationCeremonyLog" -ConfigPath $CeremonyLogPath -Layer "Foundation"
}

Write-Host "`n=== Foundation Ceremony Complete ===" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host "The civic infrastructure foundation has been established." -ForegroundColor White
Write-Host "Review the ceremony log: $CeremonyLogPath" -ForegroundColor Gray
Write-Host "`nNext: Run the Governance ceremony to establish policies and controls." -ForegroundColor Cyan

# Final audit entry
Write-CeremonialAudit -Action "Foundation Ceremony Complete" -Layer "Foundation" -Metadata @{
    Duration = "Complete"
    CeremonyLog = $CeremonyLogPath
}