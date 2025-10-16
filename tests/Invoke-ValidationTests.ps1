<#
.SYNOPSIS
    Validation test suite for Windows 11 Pro civic infrastructure
    
.DESCRIPTION
    Comprehensive validation tests to ensure all ceremonial configurations
    are working correctly and maintaining their integrity.
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    [string[]]$TestCategories = @('All'),
    [switch]$Detailed
)

# Import the civic governance module
$ModulePath = Join-Path $PSScriptRoot "..\scripts\modules\CivicGovernance.psm1"
if (Test-Path $ModulePath) {
    Import-Module $ModulePath -Force
} else {
    Write-Error "Civic governance module not found: $ModulePath"
    exit 1
}

Write-Host "🔍 Windows 11 Pro Civic Infrastructure Validation" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

$TestResults = @{
    Passed = 0
    Failed = 0
    Warnings = 0
    Details = @()
}

function Test-CivicComponent {
    param(
        [string]$Component,
        [string]$TestName,
        [scriptblock]$TestScript,
        [string]$Category = 'General'
    )
    
    if ($TestCategories -contains 'All' -or $TestCategories -contains $Category) {
        try {
            Write-Host "`n🔬 Testing: $TestName" -ForegroundColor Yellow
            
            $Result = & $TestScript
            
            if ($Result.Success) {
                Write-Host "   ✅ PASS: $TestName" -ForegroundColor Green
                $TestResults.Passed++
                
                if ($Detailed -and $Result.Details) {
                    Write-Host "      $($Result.Details)" -ForegroundColor Gray
                }
            } else {
                Write-Host "   ❌ FAIL: $TestName" -ForegroundColor Red
                if ($Result.Details) {
                    Write-Host "      $($Result.Details)" -ForegroundColor Red
                }
                $TestResults.Failed++
            }
            
            if ($Result.Warnings) {
                Write-Host "   ⚠️  WARNING: $($Result.Warnings)" -ForegroundColor Yellow
                $TestResults.Warnings++
            }
            
            $TestResults.Details += @{
                Component = $Component
                TestName = $TestName
                Category = $Category
                Success = $Result.Success
                Details = $Result.Details
                Warnings = $Result.Warnings
            }
            
        } catch {
            Write-Host "   ❌ ERROR: $TestName - $($_.Exception.Message)" -ForegroundColor Red
            $TestResults.Failed++
            
            $TestResults.Details += @{
                Component = $Component
                TestName = $TestName
                Category = $Category
                Success = $false
                Details = $_.Exception.Message
                Warnings = $null
            }
        }
    }
}

# Test 1: Civic Governance Structure
Test-CivicComponent -Component "Governance" -TestName "Civic Governance Structure" -Category "Foundation" -TestScript {
    $GovernanceDir = "$env:USERPROFILE\Documents\WindowsGovernance"
    $AuditLog = "$GovernanceDir\AuditTrail.jsonl"
    $ConfigHashes = "$GovernanceDir\ConfigHashes.json"
    
    $Success = (Test-Path $GovernanceDir) -and (Test-Path $AuditLog) -and (Test-Path $ConfigHashes)
    
    @{
        Success = $Success
        Details = if ($Success) { "Governance structure is properly initialized" } else { "Governance structure missing or incomplete" }
    }
}

# Test 2: Configuration Integrity
Test-CivicComponent -Component "Configuration" -TestName "Configuration Hash Integrity" -Category "Foundation" -TestScript {
    try {
        $IntegrityCheck = Test-ConfigurationIntegrity
        @{
            Success = $IntegrityCheck
            Details = if ($IntegrityCheck) { "All configurations maintain integrity" } else { "Configuration integrity compromised" }
        }
    } catch {
        @{
            Success = $false
            Details = "Failed to verify configuration integrity: $($_.Exception.Message)"
        }
    }
}

# Test 3: PowerShell Environment
Test-CivicComponent -Component "PowerShell" -TestName "PowerShell Environment" -Category "Developer" -TestScript {
    $PS5Available = $PSVersionTable.PSVersion.Major -ge 5
    $PS7Available = $null -ne (Get-Command pwsh -ErrorAction SilentlyContinue)
    
    $Success = $PS5Available
    $Details = "PS5: $PS5Available, PS7: $PS7Available"
    
    @{
        Success = $Success
        Details = $Details
        Warnings = if (-not $PS7Available) { "PowerShell 7 not available - consider installing for better cross-platform support" }
    }
}

# Test 4: Development Tools
Test-CivicComponent -Component "DevTools" -TestName "Essential Development Tools" -Category "Developer" -TestScript {
    $Tools = @{
        Git = $null -ne (Get-Command git -ErrorAction SilentlyContinue)
        VSCode = $null -ne (Get-Command code -ErrorAction SilentlyContinue)
        Winget = $null -ne (Get-Command winget -ErrorAction SilentlyContinue)
    }
    
    $Available = ($Tools.Values | Where-Object { $_ }).Count
    $Total = $Tools.Count
    $Success = $Available -ge 2  # At least 2 out of 3 tools should be available
    
    $ToolStatus = ($Tools.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }) -join ", "
    
    @{
        Success = $Success
        Details = "Available tools ($Available/$Total): $ToolStatus"
        Warnings = if ($Available -lt $Total) { "Some development tools are missing" }
    }
}

# Test 5: WSL2 Status
Test-CivicComponent -Component "WSL" -TestName "WSL2 Environment" -Category "Developer" -TestScript {
    try {
        $WSLStatus = wsl --status 2>$null
        $WSLAvailable = $LASTEXITCODE -eq 0
        
        if ($WSLAvailable) {
            $Distros = wsl --list --quiet 2>$null
            $DistroCount = if ($Distros) { $Distros.Count } else { 0 }
            
            @{
                Success = $true
                Details = "WSL2 available with $DistroCount distribution(s)"
                Warnings = if ($DistroCount -eq 0) { "No WSL distributions installed" }
            }
        } else {
            @{
                Success = $false
                Details = "WSL2 not available or not properly configured"
            }
        }
    } catch {
        @{
            Success = $false
            Details = "Failed to check WSL2 status"
        }
    }
}

# Test 6: Security Features
Test-CivicComponent -Component "Security" -TestName "Security Features" -Category "Security" -TestScript {
    $SecurityFeatures = @{
        BitLocker = $false
        WindowsDefender = $false
        UAC = $false
    }
    
    # Check BitLocker
    try {
        $BitLockerStatus = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue
        $SecurityFeatures.BitLocker = $BitLockerStatus -and $BitLockerStatus.ProtectionStatus -eq "On"
    } catch { }
    
    # Check Windows Defender
    try {
        $DefenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
        $SecurityFeatures.WindowsDefender = $DefenderStatus -and $DefenderStatus.AntivirusEnabled
    } catch { }
    
    # Check UAC
    try {
        $UACKey = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue
        $SecurityFeatures.UAC = $UACKey -and $UACKey.EnableLUA -eq 1
    } catch { }
    
    $EnabledFeatures = ($SecurityFeatures.GetEnumerator() | Where-Object { $_.Value }).Count
    $TotalFeatures = $SecurityFeatures.Count
    
    $FeatureStatus = ($SecurityFeatures.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }) -join ", "
    
    @{
        Success = $EnabledFeatures -ge 1  # At least one security feature should be enabled
        Details = "Security features ($EnabledFeatures/$TotalFeatures): $FeatureStatus"
        Warnings = if ($EnabledFeatures -lt $TotalFeatures) { "Some security features are disabled" }
    }
}

# Test 7: System Performance
Test-CivicComponent -Component "Performance" -TestName "System Performance Indicators" -Category "Performance" -TestScript {
    $MemoryUsage = Get-WmiObject -Class Win32_OperatingSystem
    $MemoryUtilization = [math]::Round((($MemoryUsage.TotalVisibleMemorySize - $MemoryUsage.FreePhysicalMemory) / $MemoryUsage.TotalVisibleMemorySize) * 100, 2)
    
    $DiskSpace = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
    $DiskUtilization = [math]::Round((($DiskSpace.Size - $DiskSpace.FreeSpace) / $DiskSpace.Size) * 100, 2)
    
    $PerformanceGood = $MemoryUtilization -lt 90 -and $DiskUtilization -lt 90
    
    @{
        Success = $PerformanceGood
        Details = "Memory: $MemoryUtilization%, Disk C: $DiskUtilization%"
        Warnings = if (-not $PerformanceGood) { "High resource utilization detected" }
    }
}

Write-Host "`n📊 Validation Summary" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host "✅ Passed: $($TestResults.Passed)" -ForegroundColor Green
Write-Host "❌ Failed: $($TestResults.Failed)" -ForegroundColor Red
Write-Host "⚠️  Warnings: $($TestResults.Warnings)" -ForegroundColor Yellow

$TotalTests = $TestResults.Passed + $TestResults.Failed
$SuccessRate = if ($TotalTests -gt 0) { [math]::Round(($TestResults.Passed / $TotalTests) * 100, 2) } else { 0 }

Write-Host "`nOverall Success Rate: $SuccessRate%" -ForegroundColor $(if ($SuccessRate -ge 80) { 'Green' } elseif ($SuccessRate -ge 60) { 'Yellow' } else { 'Red' })

# Generate validation report
$ReportPath = "$env:USERPROFILE\Documents\WindowsGovernance\ValidationReport.json"
$ValidationReport = @{
    Timestamp = (Get-Date).ToString('o')
    Computer = $env:COMPUTERNAME
    TestCategories = $TestCategories
    Summary = @{
        Passed = $TestResults.Passed
        Failed = $TestResults.Failed
        Warnings = $TestResults.Warnings
        SuccessRate = $SuccessRate
    }
    Details = $TestResults.Details
}

$ValidationReport | ConvertTo-Json -Depth 4 | Out-File -FilePath $ReportPath -Encoding UTF8
Write-Host "`n📄 Validation report saved to: $ReportPath" -ForegroundColor Gray

if ($TestResults.Failed -gt 0) {
    Write-Host "`n⚠️  Some tests failed. Review the details above and address any issues." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "`n🎉 All tests passed! Your civic infrastructure is functioning correctly." -ForegroundColor Green
    exit 0
}