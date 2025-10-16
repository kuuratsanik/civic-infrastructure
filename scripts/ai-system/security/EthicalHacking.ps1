<#
.SYNOPSIS
    Ethical Hacking Module - Security assessment for user-owned infrastructure

.DESCRIPTION
    Performs security assessments and vulnerability scanning on user-owned networks,
    infrastructure, and devices. Provides remediation recommendations.

    IMPORTANT: Only operates on user-owned assets with explicit authorization.

.NOTES
    Requires: SafetyFramework.ps1
    Safety: Validates ownership before scanning, never voids warranties
#>

#Requires -Version 5.1

Import-Module "$PSScriptRoot\..\safety\SafetyFramework.ps1" -Force
if (Test-Path "$PSScriptRoot\..\personality\KITT-Personality.ps1") {
    Import-Module "$PSScriptRoot\..\personality\KITT-Personality.ps1" -Force
}

# ============================================
# OWNERSHIP VERIFICATION
# ============================================

function Test-AssetOwnership {
    <#
    .SYNOPSIS
        Verify user owns the asset before security testing
    #>
    param(
        [Parameter(Mandatory)]
        [string]$AssetIdentifier,

        [ValidateSet('Network', 'Device', 'System', 'Service')]
        [string]$AssetType
    )

    Write-KITTMessage -Message "Verifying ownership of ${AssetType}: ${AssetIdentifier}" -Type Info

    # Display ownership confirmation dialog
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host "  ETHICAL HACKING - OWNERSHIP VERIFICATION" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Asset Type: $AssetType" -ForegroundColor Cyan
    Write-Host "Asset ID:   $AssetIdentifier" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "⚠️  IMPORTANT: You must OWN this asset to proceed." -ForegroundColor Yellow
    Write-Host "⚠️  Unauthorized security testing is ILLEGAL." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Do you legally own this asset and authorize security testing?" -ForegroundColor White
    Write-Host ""

    $Response = Read-Host "Type 'I OWN THIS ASSET' to confirm ownership"

    if ($Response -ne 'I OWN THIS ASSET') {
        Write-KITTMessage -Message "Ownership not confirmed. Security testing cancelled." -Type Error
        Write-SafetyLog "OWNERSHIP_DENIED: User did not confirm ownership of $AssetIdentifier" -Level CRITICAL
        return $false
    }

    # Log ownership confirmation
    $OwnershipLog = @{
        Timestamp = Get-Date
        User      = $env:USERNAME
        Asset     = $AssetIdentifier
        AssetType = $AssetType
        Confirmed = $true
        IPAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.PrefixOrigin -eq 'Dhcp' } | Select-Object -First 1).IPAddress
    }

    $LogPath = "logs\ownership-confirmations.jsonl"
    $OwnershipLog | ConvertTo-Json -Compress | Add-Content -Path $LogPath

    Write-KITTMessage -Message "Ownership confirmed and logged. Proceeding with security assessment." -Type Success
    return $true
}

# ============================================
# NETWORK SECURITY ASSESSMENT
# ============================================

function Invoke-NetworkSecurityScan {
    <#
    .SYNOPSIS
        Scan network for security vulnerabilities
    #>
    param(
        [Parameter(Mandatory)]
        [string]$NetworkRange,  # e.g., "192.168.1.0/24"

        [switch]$QuickScan,

        [switch]$DeepScan
    )

    # Ownership verification
    if (-not (Test-AssetOwnership -AssetIdentifier $NetworkRange -AssetType 'Network')) {
        return $null
    }

    # Safety check
    $SafetyCheck = Invoke-SafetyCheck -Action "Network security scan: $NetworkRange" -Context @{
        Scope      = "Network"
        Type       = "Security Assessment"
        Authorized = $true
    }

    if (-not $SafetyCheck.Approved) {
        Write-KITTMessage -Message "Security scan blocked by safety framework." -Type Error
        return $null
    }

    Write-KITTMessage -Message "Initiating network security assessment for $NetworkRange" -Type Info

    $ScanResults = @{
        NetworkRange    = $NetworkRange
        ScanDate        = Get-Date
        Devices         = @()
        Vulnerabilities = @()
        Recommendations = @()
    }

    # Step 1: Device Discovery
    Write-Host "  🔍 Phase 1: Device Discovery" -ForegroundColor Yellow
    $Devices = Find-NetworkDevices -NetworkRange $NetworkRange
    $ScanResults.Devices = $Devices

    Write-KITTMessage -Message "Discovered $($Devices.Count) devices on the network." -Type Info

    # Step 2: Port Scanning (Non-invasive)
    Write-Host "  🔍 Phase 2: Port Analysis" -ForegroundColor Yellow
    foreach ($Device in $Devices) {
        $OpenPorts = Get-OpenPorts -IPAddress $Device.IP -QuickScan:$QuickScan
        $Device | Add-Member -NotePropertyName 'OpenPorts' -NotePropertyValue $OpenPorts -Force
    }

    # Step 3: Vulnerability Detection
    Write-Host "  🔍 Phase 3: Vulnerability Detection" -ForegroundColor Yellow
    $Vulnerabilities = Find-NetworkVulnerabilities -Devices $Devices
    $ScanResults.Vulnerabilities = $Vulnerabilities

    # Step 4: Generate Recommendations
    Write-Host "  🔍 Phase 4: Generating Recommendations" -ForegroundColor Yellow
    $Recommendations = New-SecurityRecommendations -Vulnerabilities $Vulnerabilities
    $ScanResults.Recommendations = $Recommendations

    # Display Results
    Show-SecurityScanResults -Results $ScanResults

    return $ScanResults
}

function Find-NetworkDevices {
    param([string]$NetworkRange)

    $Devices = @()

    # Use built-in Windows tools (non-invasive)
    try {
        # ARP cache
        $ArpCache = arp -a | Select-String "dynamic"

        foreach ($Entry in $ArpCache) {
            if ($Entry -match '(\d+\.\d+\.\d+\.\d+)\s+([0-9a-f-]+)') {
                $Devices += @{
                    IP              = $Matches[1]
                    MAC             = $Matches[2]
                    DiscoveryMethod = 'ARP Cache'
                }
            }
        }

        # Local network
        $LocalDevices = Get-NetNeighbor -AddressFamily IPv4 -State Reachable, Stale
        foreach ($Device in $LocalDevices) {
            if ($Device.IPAddress -ne '0.0.0.0') {
                $Devices += @{
                    IP              = $Device.IPAddress
                    MAC             = $Device.LinkLayerAddress
                    DiscoveryMethod = 'NetNeighbor'
                }
            }
        }

    } catch {
        Write-KITTMessage -Message "Device discovery encountered an issue: $_" -Type Warning
    }

    # Remove duplicates
    $Devices = $Devices | Sort-Object -Property IP -Unique

    return $Devices
}

function Get-OpenPorts {
    param(
        [string]$IPAddress,
        [switch]$QuickScan
    )

    # Common ports to scan (non-invasive)
    $PortsToScan = if ($QuickScan) {
        @(21, 22, 23, 25, 80, 443, 445, 3389, 8080)  # Quick scan - common services
    } else {
        @(21, 22, 23, 25, 53, 80, 110, 135, 139, 143, 443, 445, 993, 995, 1433, 3306, 3389, 5900, 8080, 8443)  # Standard scan
    }

    $OpenPorts = @()

    foreach ($Port in $PortsToScan) {
        try {
            $Connection = New-Object System.Net.Sockets.TcpClient
            $Connection.ReceiveTimeout = 500
            $Connection.SendTimeout = 500

            $AsyncResult = $Connection.BeginConnect($IPAddress, $Port, $null, $null)
            $Wait = $AsyncResult.AsyncWaitHandle.WaitOne(500, $false)

            if ($Wait -and $Connection.Connected) {
                $OpenPorts += @{
                    Port    = $Port
                    Service = Get-ServiceName -Port $Port
                    State   = 'Open'
                }
            }

            $Connection.Close()

        } catch {
            # Port closed or filtered - expected behavior
        }
    }

    return $OpenPorts
}

function Get-ServiceName {
    param([int]$Port)

    $Services = @{
        21   = 'FTP'
        22   = 'SSH'
        23   = 'Telnet'
        25   = 'SMTP'
        53   = 'DNS'
        80   = 'HTTP'
        110  = 'POP3'
        135  = 'RPC'
        139  = 'NetBIOS'
        143  = 'IMAP'
        443  = 'HTTPS'
        445  = 'SMB'
        993  = 'IMAPS'
        995  = 'POP3S'
        1433 = 'MS-SQL'
        3306 = 'MySQL'
        3389 = 'RDP'
        5900 = 'VNC'
        8080 = 'HTTP-Alt'
        8443 = 'HTTPS-Alt'
    }

    return $Services[$Port]
}

function Find-NetworkVulnerabilities {
    param([array]$Devices)

    $Vulnerabilities = @()

    foreach ($Device in $Devices) {
        # Check for insecure services
        foreach ($Port in $Device.OpenPorts) {
            if ($Port.Port -eq 23) {
                $Vulnerabilities += @{
                    Device         = $Device.IP
                    Type           = 'Insecure Protocol'
                    Severity       = 'High'
                    Description    = 'Telnet (port 23) is unencrypted and insecure'
                    Recommendation = 'Disable Telnet and use SSH instead'
                }
            }

            if ($Port.Port -eq 21) {
                $Vulnerabilities += @{
                    Device         = $Device.IP
                    Type           = 'Insecure Protocol'
                    Severity       = 'Medium'
                    Description    = 'FTP (port 21) transmits credentials in plain text'
                    Recommendation = 'Use SFTP or FTPS instead'
                }
            }

            if ($Port.Port -eq 445 -and $Device.IP -notmatch '^192\.168\.') {
                $Vulnerabilities += @{
                    Device         = $Device.IP
                    Type           = 'Exposed Service'
                    Severity       = 'High'
                    Description    = 'SMB (port 445) exposed to external network'
                    Recommendation = 'Restrict SMB to local network only'
                }
            }
        }
    }

    return $Vulnerabilities
}

function New-SecurityRecommendations {
    param([array]$Vulnerabilities)

    $Recommendations = @()

    # Group vulnerabilities by type
    $ByType = $Vulnerabilities | Group-Object -Property Type

    foreach ($Group in $ByType) {
        $Recommendations += @{
            Category        = $Group.Name
            Priority        = ($Group.Group | Measure-Object -Property Severity -Maximum).Maximum
            AffectedDevices = $Group.Count
            Actions         = $Group.Group.Recommendation | Select-Object -Unique
        }
    }

    return $Recommendations
}

function Show-SecurityScanResults {
    param($Results)

    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  SECURITY SCAN RESULTS" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Network: $($Results.NetworkRange)" -ForegroundColor White
    Write-Host "Scan Date: $($Results.ScanDate)" -ForegroundColor Gray
    Write-Host ""

    Write-Host "📊 Summary:" -ForegroundColor Cyan
    Write-Host "  Devices Discovered: $($Results.Devices.Count)" -ForegroundColor White
    Write-Host "  Vulnerabilities: $($Results.Vulnerabilities.Count)" -ForegroundColor $(if ($Results.Vulnerabilities.Count -gt 0) { 'Red' } else { 'Green' })
    Write-Host ""

    if ($Results.Vulnerabilities.Count -gt 0) {
        Write-Host "🚨 Vulnerabilities Found:" -ForegroundColor Red
        Write-Host ""

        foreach ($Vuln in $Results.Vulnerabilities) {
            $Color = switch ($Vuln.Severity) {
                'High' { 'Red' }
                'Medium' { 'Yellow' }
                'Low' { 'White' }
            }

            Write-Host "  [$($Vuln.Severity)] " -ForegroundColor $Color -NoNewline
            Write-Host "$($Vuln.Device) - $($Vuln.Description)" -ForegroundColor White
            Write-Host "    💡 $($Vuln.Recommendation)" -ForegroundColor Gray
            Write-Host ""
        }
    }

    if ($Results.Recommendations.Count -gt 0) {
        Write-Host "✅ Recommended Actions:" -ForegroundColor Green
        Write-Host ""

        foreach ($Rec in $Results.Recommendations) {
            Write-Host "  Category: $($Rec.Category)" -ForegroundColor Cyan
            Write-Host "  Priority: $($Rec.Priority)" -ForegroundColor Yellow
            Write-Host "  Affected: $($Rec.AffectedDevices) device(s)" -ForegroundColor Gray
            foreach ($Action in $Rec.Actions) {
                Write-Host "    • $Action" -ForegroundColor White
            }
            Write-Host ""
        }
    }

    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    Write-KITTMessage -Message "Security assessment complete. Review recommendations above." -Type Success
}

# ============================================
# DEVICE SECURITY ASSESSMENT
# ============================================

function Invoke-DeviceSecurityAudit {
    <#
    .SYNOPSIS
        Audit local device security configuration (WARRANTY-SAFE)
    #>
    param(
        [switch]$IncludeRegistry,
        [switch]$IncludeFirewall,
        [switch]$IncludeUpdates
    )

    Write-KITTMessage -Message "Initiating local device security audit..." -Type Info
    Write-Host ""
    Write-Host "  ⚠️  WARRANTY PROTECTION: This audit performs READ-ONLY operations" -ForegroundColor Yellow
    Write-Host "  ⚠️  NO modifications will be made to your system" -ForegroundColor Yellow
    Write-Host ""

    $AuditResults = @{
        DeviceName     = $env:COMPUTERNAME
        AuditDate      = Get-Date
        WindowsVersion = (Get-CimInstance Win32_OperatingSystem).Caption
        Findings       = @()
    }

    # Windows Update Status (READ-ONLY)
    if ($IncludeUpdates) {
        Write-Host "  🔍 Checking Windows Update status..." -ForegroundColor Yellow

        try {
            $UpdateSession = New-Object -ComObject Microsoft.Update.Session
            $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
            $PendingUpdates = $UpdateSearcher.Search("IsInstalled=0").Updates.Count

            if ($PendingUpdates -gt 0) {
                $AuditResults.Findings += @{
                    Category       = 'Updates'
                    Severity       = 'Medium'
                    Finding        = "$PendingUpdates pending Windows updates"
                    Recommendation = 'Install pending updates to maintain security'
                }
            }
        } catch {
            Write-KITTMessage -Message "Could not check Windows Update status: $_" -Type Warning
        }
    }

    # Firewall Status (READ-ONLY)
    if ($IncludeFirewall) {
        Write-Host "  🔍 Checking Windows Firewall..." -ForegroundColor Yellow

        $FirewallProfiles = Get-NetFirewallProfile
        foreach ($Profile in $FirewallProfiles) {
            if (-not $Profile.Enabled) {
                $AuditResults.Findings += @{
                    Category       = 'Firewall'
                    Severity       = 'High'
                    Finding        = "Windows Firewall disabled for $($Profile.Name) profile"
                    Recommendation = 'Enable Windows Firewall for all profiles'
                }
            }
        }
    }

    # Antivirus Status (READ-ONLY)
    Write-Host "  🔍 Checking antivirus status..." -ForegroundColor Yellow

    try {
        $AVStatus = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct
        if (-not $AVStatus) {
            $AuditResults.Findings += @{
                Category       = 'Antivirus'
                Severity       = 'Critical'
                Finding        = 'No antivirus software detected'
                Recommendation = 'Install and enable Windows Defender or third-party antivirus'
            }
        }
    } catch {
        Write-KITTMessage -Message "Could not check antivirus status: $_" -Type Warning
    }

    # UAC Status (READ-ONLY - Registry read only, no changes)
    if ($IncludeRegistry) {
        Write-Host "  🔍 Checking UAC configuration..." -ForegroundColor Yellow

        try {
            $UACValue = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue

            if ($UACValue.EnableLUA -eq 0) {
                $AuditResults.Findings += @{
                    Category       = 'UAC'
                    Severity       = 'High'
                    Finding        = 'User Account Control (UAC) is disabled'
                    Recommendation = 'Enable UAC for improved security'
                }
            }
        } catch {
            # Non-critical
        }
    }

    # Display Results
    Show-DeviceAuditResults -Results $AuditResults

    return $AuditResults
}

function Show-DeviceAuditResults {
    param($Results)

    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  DEVICE SECURITY AUDIT RESULTS" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Device: $($Results.DeviceName)" -ForegroundColor White
    Write-Host "Windows: $($Results.WindowsVersion)" -ForegroundColor White
    Write-Host "Audit Date: $($Results.AuditDate)" -ForegroundColor Gray
    Write-Host ""

    if ($Results.Findings.Count -eq 0) {
        Write-KITTMessage -Message "Excellent! No security issues detected." -Type Success
    } else {
        Write-Host "🔍 Findings ($($Results.Findings.Count)):" -ForegroundColor Yellow
        Write-Host ""

        foreach ($Finding in $Results.Findings) {
            $Color = switch ($Finding.Severity) {
                'Critical' { 'Red' }
                'High' { 'Red' }
                'Medium' { 'Yellow' }
                'Low' { 'White' }
            }

            Write-Host "  [$($Finding.Severity)] " -ForegroundColor $Color -NoNewline
            Write-Host "$($Finding.Category): $($Finding.Finding)" -ForegroundColor White
            Write-Host "    💡 $($Finding.Recommendation)" -ForegroundColor Gray
            Write-Host ""
        }
    }

    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================
# EXPORT MODULE MEMBERS
# ============================================

Export-ModuleMember -Function @(
    'Test-AssetOwnership',
    'Invoke-NetworkSecurityScan',
    'Invoke-DeviceSecurityAudit'
)
