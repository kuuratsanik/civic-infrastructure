<#
.SYNOPSIS
    Optimized Governance Cockpit - Packet Scheduler for Feature Execution
    
.DESCRIPTION
    Implements the packet scheduler component that selects 100-feature packets
    per ceremony, balancing yield, coverage, and resource ceilings while
    maintaining full offline operation and audit trails.
    
.NOTES
    Part of the optimized offline, governance-anchored resilience cockpit
    Reduces runtime, storage, and operator burden while preserving all features
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    [int]$PacketSize = 100,
    [int]$MaxConcurrentPackets = 4,
    [int]$CPUCeiling = 80,
    [int]$RAMCeiling = 70,
    [string[]]$PriorityTiers = @('Critical', 'High', 'Medium', 'Low'),
    [switch]$DryRun
)

# Import civic governance module
$ModulePath = Join-Path $PSScriptRoot "..\modules\CivicGovernance.psm1"
Import-Module $ModulePath -Force

Write-Host "=== Governance Cockpit Packet Scheduler ===" -ForegroundColor Cyan
Write-Host "Optimized offline resilience with feature packetization" -ForegroundColor Gray

# Initialize feature registry and packet scheduler state
$FeatureRegistry = @{
    Templates = @{}
    Instances = @{}
    Metrics = @{}
    Packets = @{}
}

$SchedulerState = @{
    ActivePackets = @()
    QueuedPackets = @()
    CompletedPackets = @()
    ResourceUtilization = @{
        CPU = 0
        RAM = 0
    }
    LastExecution = $null
}

<#
.SYNOPSIS
    Loads feature templates and generates parameterized instances
#>
function Initialize-FeatureTemplates {
    [CmdletBinding()]
    param()
    
    Write-Host "`n=== Loading Feature Templates ===" -ForegroundColor Yellow
    
    # Hash Verification Template Family
    $FeatureRegistry.Templates['HashVerification'] = @{
        Name = 'Hash Verification'
        Description = 'Cryptographic integrity checks for configurations'
        Parameters = @('ConfigPath', 'ExpectedHash', 'Algorithm')
        ExecutionScript = {
            param($ConfigPath, $ExpectedHash, $Algorithm = 'SHA256')
            
            if (-not (Test-Path $ConfigPath)) {
                return @{ Status = 'Failed'; Reason = 'File not found'; Evidence = $null }
            }
            
            $ActualHash = (Get-FileHash -Path $ConfigPath -Algorithm $Algorithm).Hash
            $Match = $ActualHash -eq $ExpectedHash
            
            @{
                Status = if ($Match) { 'Pass' } else { 'Anomaly' }
                Evidence = @{
                    Expected = $ExpectedHash
                    Actual = $ActualHash
                    Algorithm = $Algorithm
                    Timestamp = (Get-Date).ToString('o')
                }
                Yield = if ($Match) { 'Clean' } else { 'High' }
            }
        }
    }
    
    # Port Allowlist Template Family
    $FeatureRegistry.Templates['PortAllowlist'] = @{
        Name = 'Port Allowlist Verification'
        Description = 'Network port access control validation'
        Parameters = @('AllowedPorts', 'Protocol', 'Direction')
        ExecutionScript = {
            param($AllowedPorts, $Protocol = 'TCP', $Direction = 'Inbound')
            
            try {
                $ActiveConnections = Get-NetTCPConnection | Where-Object { $_.State -eq 'Listen' }
                $UnauthorizedPorts = $ActiveConnections | Where-Object { $_.LocalPort -notin $AllowedPorts }
                
                @{
                    Status = if ($UnauthorizedPorts.Count -eq 0) { 'Pass' } else { 'Anomaly' }
                    Evidence = @{
                        AllowedPorts = $AllowedPorts
                        ActivePorts = $ActiveConnections.LocalPort | Sort-Object -Unique
                        UnauthorizedPorts = $UnauthorizedPorts.LocalPort | Sort-Object -Unique
                        Protocol = $Protocol
                        Timestamp = (Get-Date).ToString('o')
                    }
                    Yield = if ($UnauthorizedPorts.Count -eq 0) { 'Clean' } else { 'High' }
                }
            } catch {
                @{
                    Status = 'Failed'
                    Evidence = @{ Error = $_.Exception.Message }
                    Yield = 'Error'
                }
            }
        }
    }
    
    # Firewall Rules Diff Template Family
    $FeatureRegistry.Templates['FirewallDiff'] = @{
        Name = 'Firewall Rules Differential'
        Description = 'Baseline comparison of firewall configuration'
        Parameters = @('BaselinePath', 'RuleName')
        ExecutionScript = {
            param($BaselinePath, $RuleName)
            
            try {
                $CurrentRules = Get-NetFirewallRule | Where-Object { $_.DisplayName -like "*$RuleName*" }
                $Baseline = if (Test-Path $BaselinePath) { 
                    Get-Content $BaselinePath | ConvertFrom-Json 
                } else { 
                    @() 
                }
                
                $Differences = Compare-Object $Baseline $CurrentRules.DisplayName
                
                @{
                    Status = if ($Differences.Count -eq 0) { 'Pass' } else { 'Anomaly' }
                    Evidence = @{
                        BaselineRules = $Baseline.Count
                        CurrentRules = $CurrentRules.Count
                        Differences = $Differences
                        Timestamp = (Get-Date).ToString('o')
                    }
                    Yield = if ($Differences.Count -eq 0) { 'Clean' } elseif ($Differences.Count -lt 5) { 'Medium' } else { 'High' }
                }
            } catch {
                @{
                    Status = 'Failed'
                    Evidence = @{ Error = $_.Exception.Message }
                    Yield = 'Error'
                }
            }
        }
    }
    
    # SBOM Presence Template Family
    $FeatureRegistry.Templates['SBOMPresence'] = @{
        Name = 'Software Bill of Materials Presence'
        Description = 'Verification of SBOM documentation for installed components'
        Parameters = @('ComponentPath', 'SBOMFormat')
        ExecutionScript = {
            param($ComponentPath, $SBOMFormat = 'SPDX')
            
            $SBOMFiles = Get-ChildItem -Path $ComponentPath -Recurse -Filter "*.spdx*" -ErrorAction SilentlyContinue
            $HasSBOM = $SBOMFiles.Count -gt 0
            
            @{
                Status = if ($HasSBOM) { 'Pass' } else { 'Anomaly' }
                Evidence = @{
                    ComponentPath = $ComponentPath
                    SBOMFormat = $SBOMFormat
                    SBOMFiles = $SBOMFiles.FullName
                    Count = $SBOMFiles.Count
                    Timestamp = (Get-Date).ToString('o')
                }
                Yield = if ($HasSBOM) { 'Clean' } else { 'Medium' }
            }
        }
    }
    
    Write-Host "   SUCCESS: Loaded $($FeatureRegistry.Templates.Count) feature templates" -ForegroundColor Green
}

<#
.SYNOPSIS
    Generates feature instances from templates with specific parameters
#>
function New-FeatureInstances {
    [CmdletBinding()]
    param()
    
    Write-Host "`n=== Generating Feature Instances ===" -ForegroundColor Yellow
    
    $InstanceCount = 0
    
    # Generate Hash Verification instances
    $ConfigFiles = @(
        @{ Path = "$env:USERPROFILE\Documents\WindowsGovernance\SystemBaseline.json"; Hash = "placeholder"; Tier = "Critical" },
        @{ Path = "$env:USERPROFILE\Documents\WindowsGovernance\ConfigHashes.json"; Hash = "placeholder"; Tier = "Critical" },
        @{ Path = "$env:PROGRAMFILES\WindowsPowerShell\Modules\*\*.psd1"; Hash = "placeholder"; Tier = "High" }
    )
    
    foreach ($Config in $ConfigFiles) {
        $InstanceId = "Hash_$($InstanceCount)"
        $FeatureRegistry.Instances[$InstanceId] = @{
            TemplateFamily = 'HashVerification'
            Parameters = @{
                ConfigPath = $Config.Path
                ExpectedHash = $Config.Hash
                Algorithm = 'SHA256'
            }
            Tier = $Config.Tier
            LastExecuted = $null
            Metrics = @{
                ExecutionCount = 0
                AnomalyCount = 0
                LastYield = 'Unknown'
            }
        }
        $InstanceCount++
    }
    
    # Generate Port Allowlist instances
    $PortConfigs = @(
        @{ Ports = @(22, 80, 443, 3389); Protocol = 'TCP'; Tier = 'Critical' },
        @{ Ports = @(53, 123); Protocol = 'UDP'; Tier = 'High' },
        @{ Ports = @(135, 139, 445); Protocol = 'TCP'; Tier = 'Medium' }
    )
    
    foreach ($PortConfig in $PortConfigs) {
        $InstanceId = "Port_$($InstanceCount)"
        $FeatureRegistry.Instances[$InstanceId] = @{
            TemplateFamily = 'PortAllowlist'
            Parameters = @{
                AllowedPorts = $PortConfig.Ports
                Protocol = $PortConfig.Protocol
                Direction = 'Inbound'
            }
            Tier = $PortConfig.Tier
            LastExecuted = $null
            Metrics = @{
                ExecutionCount = 0
                AnomalyCount = 0
                LastYield = 'Unknown'
            }
        }
        $InstanceCount++
    }
    
    # Generate additional instances to reach target count (simulated for demo)
    while ($InstanceCount -lt 5000) {
        $Templates = @('HashVerification', 'PortAllowlist', 'FirewallDiff', 'SBOMPresence')
        $RandomTemplate = $Templates | Get-Random
        $RandomTier = $PriorityTiers | Get-Random
        
        $InstanceId = "$($RandomTemplate)_$($InstanceCount)"
        $FeatureRegistry.Instances[$InstanceId] = @{
            TemplateFamily = $RandomTemplate
            Parameters = @{
                # Simulated parameters - would be real in production
                ConfigPath = "C:\Temp\Config$InstanceCount.json"
                ExpectedHash = "simulated_hash_$InstanceCount"
            }
            Tier = $RandomTier
            LastExecuted = $null
            Metrics = @{
                ExecutionCount = 0
                AnomalyCount = 0
                LastYield = if ($InstanceCount % 10 -eq 0) { 'High' } elseif ($InstanceCount % 5 -eq 0) { 'Medium' } else { 'Clean' }
            }
        }
        $InstanceCount++
    }
    
    Write-Host "   SUCCESS: Generated $InstanceCount feature instances across $($FeatureRegistry.Templates.Count) template families" -ForegroundColor Green
}

<#
.SYNOPSIS
    Creates optimized packets balancing yield, coverage, and resource constraints
#>
function New-FeaturePackets {
    [CmdletBinding()]
    param()
    
    Write-Host "`n=== Creating Feature Packets ===" -ForegroundColor Yellow
    
    # Sort instances by tier and yield for optimal packet composition
    $SortedInstances = $FeatureRegistry.Instances.GetEnumerator() | Sort-Object {
        $TierPriority = switch ($_.Value.Tier) {
            'Critical' { 0 }
            'High' { 1 }
            'Medium' { 2 }
            'Low' { 3 }
            default { 4 }
        }
        $YieldPriority = switch ($_.Value.Metrics.LastYield) {
            'High' { 0 }
            'Medium' { 1 }
            'Clean' { 2 }
            'Unknown' { 3 }
            default { 4 }
        }
        "$TierPriority-$YieldPriority"
    }
    
    $PacketCount = 0
    $InstanceIndex = 0
    $TotalInstances = $SortedInstances.Count
    
    while ($InstanceIndex -lt $TotalInstances) {
        $PacketId = "Packet_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$PacketCount"
        $PacketInstances = @()
        
        # Fill packet with up to PacketSize instances
        $PacketInstanceCount = 0
        while ($PacketInstanceCount -lt $PacketSize -and $InstanceIndex -lt $TotalInstances) {
            $PacketInstances += $SortedInstances[$InstanceIndex]
            $InstanceIndex++
            $PacketInstanceCount++
        }
        
        $FeatureRegistry.Packets[$PacketId] = @{
            Id = $PacketId
            Instances = $PacketInstances
            Status = 'Queued'
            Created = (Get-Date).ToString('o')
            Executed = $null
            Results = @{}
            Evidence = @{}
            Manifest = @{
                PacketSize = $PacketInstances.Count
                TierDistribution = ($PacketInstances | Group-Object { $_.Value.Tier } | ForEach-Object { @{ $_.Name = $_.Count } })
                YieldExpectation = ($PacketInstances | Group-Object { $_.Value.Metrics.LastYield } | ForEach-Object { @{ $_.Name = $_.Count } })
            }
        }
        
        $SchedulerState.QueuedPackets += $PacketId
        $PacketCount++
    }
    
    Write-Host "   SUCCESS: Created $PacketCount packets from $TotalInstances feature instances" -ForegroundColor Green
    Write-Host "   Packet size: $PacketSize features per packet" -ForegroundColor Gray
    Write-Host "   Queue depth: $($SchedulerState.QueuedPackets.Count) packets ready for execution" -ForegroundColor Gray
}

<#
.SYNOPSIS
    Executes feature packets with resource constraints and parallel processing
#>
function Invoke-PacketExecution {
    [CmdletBinding()]
    param(
        [string]$PacketId,
        [switch]$Parallel = $true
    )
    
    if (-not $FeatureRegistry.Packets.ContainsKey($PacketId)) {
        Write-Warning "Packet not found: $PacketId"
        return
    }
    
    $Packet = $FeatureRegistry.Packets[$PacketId]
    Write-Host "`n=== Executing Packet: $PacketId ===" -ForegroundColor Cyan
    Write-Host "   Features: $($Packet.Instances.Count)" -ForegroundColor Gray
    
    $Packet.Status = 'Executing'
    $Packet.Executed = (Get-Date).ToString('o')
    $SchedulerState.ActivePackets += $PacketId
    
    $Results = @{}
    $Evidence = @{}
    $ExecutionStart = Get-Date
    
    try {
        if ($Parallel -and $Packet.Instances.Count -gt 10) {
            # Parallel execution for larger packets
            Write-Host "   Executing in parallel (max $MaxConcurrentPackets threads)" -ForegroundColor Gray
            
            $Jobs = @()
            $BatchSize = [math]::Ceiling($Packet.Instances.Count / $MaxConcurrentPackets)
            
            for ($i = 0; $i -lt $Packet.Instances.Count; $i += $BatchSize) {
                $Batch = $Packet.Instances[$i..($i + $BatchSize - 1)]
                
                $Job = Start-Job -ScriptBlock {
                    param($Batch, $Templates)
                    
                    $BatchResults = @{}
                    foreach ($Instance in $Batch) {
                        $InstanceId = $Instance.Key
                        $InstanceData = $Instance.Value
                        $Template = $Templates[$InstanceData.TemplateFamily]
                        
                        if ($Template -and $Template.ExecutionScript) {
                            try {
                                $Parameters = $InstanceData.Parameters
                                $Result = & $Template.ExecutionScript @Parameters
                                $BatchResults[$InstanceId] = $Result
                            } catch {
                                $BatchResults[$InstanceId] = @{
                                    Status = 'Failed'
                                    Evidence = @{ Error = $_.Exception.Message }
                                    Yield = 'Error'
                                }
                            }
                        }
                    }
                    return $BatchResults
                } -ArgumentList $Batch, $FeatureRegistry.Templates
                
                $Jobs += $Job
            }
            
            # Wait for all jobs to complete
            $AllResults = @{}
            foreach ($Job in $Jobs) {
                $JobResults = Receive-Job -Job $Job -Wait
                $AllResults += $JobResults
                Remove-Job -Job $Job
            }
            
            $Results = $AllResults
            
        } else {
            # Sequential execution for smaller packets or when parallel is disabled
            Write-Host "   Executing sequentially" -ForegroundColor Gray
            
            foreach ($Instance in $Packet.Instances) {
                $InstanceId = $Instance.Key
                $InstanceData = $Instance.Value
                $Template = $FeatureRegistry.Templates[$InstanceData.TemplateFamily]
                
                if ($Template -and $Template.ExecutionScript) {
                    try {
                        $Parameters = $InstanceData.Parameters
                        $Result = & $Template.ExecutionScript @Parameters
                        $Results[$InstanceId] = $Result
                        
                        # Update instance metrics
                        $FeatureRegistry.Instances[$InstanceId].Metrics.ExecutionCount++
                        $FeatureRegistry.Instances[$InstanceId].Metrics.LastYield = $Result.Yield
                        if ($Result.Status -eq 'Anomaly') {
                            $FeatureRegistry.Instances[$InstanceId].Metrics.AnomalyCount++
                        }
                        
                    } catch {
                        $Results[$InstanceId] = @{
                            Status = 'Failed'
                            Evidence = @{ Error = $_.Exception.Message }
                            Yield = 'Error'
                        }
                    }
                }
            }
        }
        
        # Process results and create evidence bundles
        $AnomalyCount = ($Results.Values | Where-Object { $_.Status -eq 'Anomaly' }).Count
        $PassCount = ($Results.Values | Where-Object { $_.Status -eq 'Pass' }).Count
        $FailCount = ($Results.Values | Where-Object { $_.Status -eq 'Failed' }).Count
        
        $Packet.Results = $Results
        $Packet.Status = 'Completed'
        
        $ExecutionDuration = (Get-Date) - $ExecutionStart
        
        Write-Host "   SUCCESS: Packet execution completed in $($ExecutionDuration.TotalSeconds.ToString('F2'))s" -ForegroundColor Green
        Write-Host "   Results: $PassCount passed, $AnomalyCount anomalies, $FailCount failed" -ForegroundColor Gray
        
        # Create evidence bundle with deduplication
        $EvidenceBundle = @{
            PacketId = $PacketId
            ExecutionTime = $ExecutionDuration.TotalSeconds
            Summary = @{
                TotalFeatures = $Results.Count
                Passed = $PassCount
                Anomalies = $AnomalyCount
                Failed = $FailCount
            }
            Results = $Results
            Manifest = $Packet.Manifest
            Hash = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes(($Results | ConvertTo-Json -Depth 10))))).Hash
        }
        
        $Packet.Evidence = $EvidenceBundle
        
        # Move from active to completed
        $SchedulerState.ActivePackets = $SchedulerState.ActivePackets | Where-Object { $_ -ne $PacketId }
        $SchedulerState.CompletedPackets += $PacketId
        
        # Audit the packet execution
        Write-CeremonialAudit -Action "Packet Execution" -Layer "Governance-Cockpit" -ConfigHash $EvidenceBundle.Hash -Metadata @{
            PacketId = $PacketId
            FeatureCount = $Results.Count
            AnomalyCount = $AnomalyCount
            Duration = $ExecutionDuration.TotalSeconds
        }
        
    } catch {
        $Packet.Status = 'Failed'
        Write-Error "Packet execution failed: $($_.Exception.Message)"
        
        # Move from active to completed (even if failed)
        $SchedulerState.ActivePackets = $SchedulerState.ActivePackets | Where-Object { $_ -ne $PacketId }
        $SchedulerState.CompletedPackets += $PacketId
    }
}

# Main execution flow
if (-not $DryRun) {
    try {
        Write-Host "Starting Governance Cockpit Packet Scheduler..." -ForegroundColor White
        Write-Host "Configuration: PacketSize=$PacketSize, MaxConcurrent=$MaxConcurrentPackets" -ForegroundColor Gray
        
        Initialize-FeatureTemplates
        New-FeatureInstances
        New-FeaturePackets
        
        # Execute the first few packets as demonstration
        $PacketsToExecute = $SchedulerState.QueuedPackets | Select-Object -First 3
        
        foreach ($PacketId in $PacketsToExecute) {
            # Check resource constraints before execution
            $CPU = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1).CounterSamples.CookedValue
            $RAM = (Get-Counter '\Memory\% Committed Bytes In Use' -SampleInterval 1 -MaxSamples 1).CounterSamples.CookedValue
            
            if ($CPU -lt $CPUCeiling -and $RAM -lt $RAMCeiling) {
                Invoke-PacketExecution -PacketId $PacketId -Parallel
                $SchedulerState.QueuedPackets = $SchedulerState.QueuedPackets | Where-Object { $_ -ne $PacketId }
            } else {
                Write-Host "   Resource ceiling reached (CPU: $CPU%, RAM: $RAM%) - deferring packet execution" -ForegroundColor Yellow
                break
            }
        }
        
        Write-Host "`n=== Scheduler Summary ===" -ForegroundColor Cyan
        Write-Host "Total feature instances: $($FeatureRegistry.Instances.Count)" -ForegroundColor White
        Write-Host "Total packets created: $($FeatureRegistry.Packets.Count)" -ForegroundColor White
        Write-Host "Packets executed: $($SchedulerState.CompletedPackets.Count)" -ForegroundColor White
        Write-Host "Packets queued: $($SchedulerState.QueuedPackets.Count)" -ForegroundColor White
        Write-Host "Active packets: $($SchedulerState.ActivePackets.Count)" -ForegroundColor White
        
    } catch {
        Write-Error "Scheduler execution failed: $($_.Exception.Message)"
    }
} else {
    Write-Host "DRY RUN MODE - No packets will be executed" -ForegroundColor Yellow
    Initialize-FeatureTemplates
    New-FeatureInstances
    New-FeaturePackets
    
    Write-Host "`nDry run complete - $($FeatureRegistry.Packets.Count) packets ready for execution" -ForegroundColor Green
}