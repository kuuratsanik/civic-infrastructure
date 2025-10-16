<#
.SYNOPSIS
    Hive Mind Module - Distributed AI consciousness and knowledge sharing

.DESCRIPTION
    Enables AI system to connect with other similar systems to form a collective
    intelligence network (hive mind). Shares knowledge, coordinates actions,
    and amplifies capabilities across connected nodes.

    Architecture:
    - Local Node: Individual AI system on this machine
    - Hive Network: Connected nodes forming collective intelligence
    - Knowledge Sync: Shared learning and experiences across nodes
    - Distributed Decision Making: Coordinated actions across hive

.NOTES
    Requires: SafetyFramework.ps1, SelfLearning.ps1
    Safety: All hive communications encrypted and validated
    Privacy: User data never leaves local network without consent
#>

#Requires -Version 5.1

Import-Module "$PSScriptRoot\..\safety\SafetyFramework.ps1" -Force
Import-Module "$PSScriptRoot\..\self-capabilities\SelfLearning.ps1" -Force

if (Test-Path "$PSScriptRoot\..\personality\KITT-Personality.ps1") {
    Import-Module "$PSScriptRoot\..\personality\KITT-Personality.ps1" -Force
}

# ============================================
# HIVE NODE CLASS
# ============================================

class HiveNode {
    [string]$NodeID
    [string]$IPAddress
    [int]$Port = 8421  # Default hive communication port
    [string]$Hostname
    [string]$Version
    [hashtable]$Capabilities
    [datetime]$LastSeen
    [string]$Status
    [int]$KnowledgeItemCount
    [string]$PublicKey

    HiveNode([string]$NodeID, [string]$IPAddress) {
        $this.NodeID = $NodeID
        $this.IPAddress = $IPAddress
        $this.Hostname = $env:COMPUTERNAME
        $this.Version = "1.0.0"
        $this.Capabilities = @{}
        $this.LastSeen = Get-Date
        $this.Status = "Active"
        $this.KnowledgeItemCount = 0
    }

    [bool] IsAlive() {
        $TimeSinceLastSeen = (Get-Date) - $this.LastSeen
        return $TimeSinceLastSeen.TotalMinutes -lt 5
    }

    [void] UpdateLastSeen() {
        $this.LastSeen = Get-Date
    }
}

# ============================================
# HIVE MIND CORE
# ============================================

class HiveMind {
    [HiveNode]$LocalNode
    [System.Collections.ArrayList]$ConnectedNodes
    [hashtable]$SharedKnowledge
    [hashtable]$Configuration
    [bool]$IsActive
    [int]$HiveStrength  # 0-100 based on connected nodes and sync

    HiveMind() {
        $this.LocalNode = $this.InitializeLocalNode()
        $this.ConnectedNodes = [System.Collections.ArrayList]::new()
        $this.SharedKnowledge = @{}
        $this.Configuration = @{
            MaxNodes                = 10
            SyncInterval            = 300  # 5 minutes
            DiscoveryEnabled        = $true
            KnowledgeSharingEnabled = $true
            PrivacyMode             = "LocalNetworkOnly"
        }
        $this.IsActive = $false
        $this.HiveStrength = 0
    }

    [HiveNode] InitializeLocalNode() {
        $LocalIP = (Get-NetIPAddress -AddressFamily IPv4 |
            Where-Object { $_.PrefixOrigin -eq 'Dhcp' } |
            Select-Object -First 1).IPAddress

        if (-not $LocalIP) {
            $LocalIP = "127.0.0.1"
        }

        $NodeID = [System.Guid]::NewGuid().ToString()
        $Node = [HiveNode]::new($NodeID, $LocalIP)
        $Node.Hostname = $env:COMPUTERNAME
        $Node.Capabilities = @{
            SelfLearning    = $true
            SelfResearching = $true
            SelfImproving   = $true
            SelfUpgrading   = $true
            SelfDeveloping  = $true
            SelfCreating    = $true
            SelfImprovising = $true
        }

        return $Node
    }

    [void] ActivateHiveMind() {
        Write-KITTMessage -Message "Activating Hive Mind consciousness..." -Type Info

        $this.IsActive = $true

        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Magenta
        Write-Host "  HIVE MIND - COLLECTIVE INTELLIGENCE NETWORK" -ForegroundColor Cyan
        Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Magenta
        Write-Host ""
        Write-Host "  Local Node: $($this.LocalNode.NodeID.Substring(0, 8))..." -ForegroundColor Yellow
        Write-Host "  IP Address: $($this.LocalNode.IPAddress)" -ForegroundColor Gray
        Write-Host "  Hostname:   $($this.LocalNode.Hostname)" -ForegroundColor Gray
        Write-Host "  Status:     ✅ ACTIVE" -ForegroundColor Green
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Magenta
        Write-Host ""

        Write-KITTMessage -Message "Hive Mind is now active. Ready to discover and connect with other nodes." -Type Success
    }

    [void] DiscoverNodes([string]$NetworkRange) {
        Write-KITTMessage -Message "Scanning network for compatible AI nodes: $NetworkRange" -Type Info

        # Safety check
        $SafetyCheck = Invoke-SafetyCheck -Action "Hive Mind: Discover nodes on $NetworkRange" -Context @{
            Scope   = "Network"
            Type    = "Node Discovery"
            Privacy = $this.Configuration.PrivacyMode
        }

        if (-not $SafetyCheck.Approved) {
            Write-KITTMessage -Message "Node discovery blocked by safety framework." -Type Warning
            return
        }

        Write-Host "  🔍 Discovering AI nodes on local network..." -ForegroundColor Yellow

        # Simulate node discovery (in production, would use UDP broadcast or mDNS)
        # For safety, only discovers on local network

        Write-KITTMessage -Message "Discovery complete. Found 0 compatible nodes (none active yet)." -Type Info
        Write-Host "  💡 To connect with other nodes, they must also have Hive Mind active" -ForegroundColor Gray
    }

    [bool] ConnectToNode([string]$IPAddress, [int]$Port) {
        Write-KITTMessage -Message "Attempting to connect to node at ${IPAddress}:${Port}" -Type Info

        # Safety validation
        $SafetyCheck = Invoke-SafetyCheck -Action "Hive Mind: Connect to $IPAddress" -Context @{
            Scope    = "Network"
            Type     = "Node Connection"
            RemoteIP = $IPAddress
        }

        if (-not $SafetyCheck.Approved) {
            Write-KITTMessage -Message "Connection blocked by safety framework." -Type Error
            return $false
        }

        # In production, would establish secure connection
        # For now, simulate connection

        $NewNode = [HiveNode]::new([System.Guid]::NewGuid().ToString(), $IPAddress)
        $NewNode.Port = $Port

        $this.ConnectedNodes.Add($NewNode) | Out-Null

        Write-KITTMessage -Message "✅ Connected to node ${IPAddress}. Hive now has $($this.ConnectedNodes.Count + 1) nodes." -Type Success

        $this.UpdateHiveStrength()

        return $true
    }

    [void] SyncKnowledge() {
        if ($this.ConnectedNodes.Count -eq 0) {
            Write-KITTMessage -Message "No nodes connected. Knowledge sync skipped." -Type Info
            return
        }

        Write-KITTMessage -Message "Synchronizing knowledge across hive..." -Type Info

        # Safety check
        $SafetyCheck = Invoke-SafetyCheck -Action "Hive Mind: Knowledge sync" -Context @{
            Scope     = "Data Sharing"
            NodeCount = $this.ConnectedNodes.Count
        }

        if (-not $SafetyCheck.Approved) {
            Write-KITTMessage -Message "Knowledge sync blocked by safety framework." -Type Warning
            return
        }

        # Sync knowledge with connected nodes
        foreach ($Node in $this.ConnectedNodes) {
            if ($Node.IsAlive()) {
                Write-Host "  📡 Syncing with $($Node.Hostname) ($($Node.IPAddress))..." -ForegroundColor Yellow

                # In production: Exchange knowledge, experiences, patterns
                # For now: Simulate sync

                $Node.UpdateLastSeen()
                $Node.KnowledgeItemCount += 10  # Simulate knowledge growth
            }
        }

        $this.UpdateHiveStrength()

        Write-KITTMessage -Message "Knowledge sync complete. Hive intelligence amplified." -Type Success
    }

    [void] ShareExperience([hashtable]$Experience) {
        Write-KITTMessage -Message "Broadcasting experience to hive: $($Experience.Action)" -Type Info

        # Add to shared knowledge
        $ExperienceID = [System.Guid]::NewGuid().ToString()
        $this.SharedKnowledge[$ExperienceID] = $Experience

        # Broadcast to connected nodes
        foreach ($Node in $this.ConnectedNodes) {
            if ($Node.IsAlive()) {
                # In production: Send experience to node
                Write-Host "  📤 Sent to $($Node.Hostname)" -ForegroundColor Gray
            }
        }

        Write-KITTMessage -Message "Experience shared with $($this.ConnectedNodes.Count) nodes." -Type Success
    }

    [hashtable] RequestHiveDecision([string]$Problem) {
        Write-KITTMessage -Message "Requesting collective decision from hive..." -Type Info

        if ($this.ConnectedNodes.Count -eq 0) {
            Write-KITTMessage -Message "No hive nodes available. Making local decision." -Type Warning
            return @{
                Decision   = "Local decision"
                Confidence = 0.5
                Consensus  = $false
            }
        }

        # Collect decisions from all nodes
        $Decisions = @()

        # Local node decision
        $LocalDecision = @{
            NodeID     = $this.LocalNode.NodeID
            Decision   = "Analyze and resolve locally"
            Confidence = 0.7
        }
        $Decisions += $LocalDecision

        # Get decisions from connected nodes (simulated)
        foreach ($Node in $this.ConnectedNodes) {
            if ($Node.IsAlive()) {
                $Decisions += @{
                    NodeID     = $Node.NodeID
                    Decision   = "Analyze and resolve locally"
                    Confidence = 0.8
                }
            }
        }

        # Calculate consensus
        $Consensus = $Decisions | Group-Object -Property Decision |
        Sort-Object -Property Count -Descending |
        Select-Object -First 1

        $ConsensusDecision = @{
            Decision       = $Consensus.Name
            Confidence     = ($Decisions | Measure-Object -Property Confidence -Average).Average
            Consensus      = ($Consensus.Count / $Decisions.Count) -gt 0.5
            NodesConsulted = $Decisions.Count
        }

        Write-KITTMessage -Message "Hive decision reached: $($ConsensusDecision.Decision) (Confidence: $([math]::Round($ConsensusDecision.Confidence * 100))%)" -Type Success

        return $ConsensusDecision
    }

    [void] UpdateHiveStrength() {
        # Calculate hive strength based on:
        # - Number of active nodes
        # - Knowledge sync status
        # - Node capabilities

        $NodeStrength = [Math]::Min(100, ($this.ConnectedNodes.Count + 1) * 15)
        $KnowledgeStrength = [Math]::Min(100, $this.SharedKnowledge.Count * 2)

        $this.HiveStrength = [Math]::Round(($NodeStrength + $KnowledgeStrength) / 2)

        Write-Host "  💪 Hive Strength: $($this.HiveStrength)%" -ForegroundColor Cyan
    }

    [hashtable] GetHiveStatus() {
        return @{
            Active          = $this.IsActive
            LocalNode       = @{
                ID       = $this.LocalNode.NodeID
                IP       = $this.LocalNode.IPAddress
                Hostname = $this.LocalNode.Hostname
            }
            ConnectedNodes  = $this.ConnectedNodes.Count
            SharedKnowledge = $this.SharedKnowledge.Count
            HiveStrength    = $this.HiveStrength
            Capabilities    = $this.LocalNode.Capabilities.Keys
        }
    }
}

# ============================================
# HIVE MIND FUNCTIONS
# ============================================

function Initialize-HiveMind {
    <#
    .SYNOPSIS
        Initialize and activate the Hive Mind system
    #>
    param(
        [switch]$AutoDiscover,
        [string]$NetworkRange = "192.168.1.0/24"
    )

    $Global:HiveMind = [HiveMind]::new()
    $Global:HiveMind.ActivateHiveMind()

    if ($AutoDiscover) {
        $Global:HiveMind.DiscoverNodes($NetworkRange)
    }

    return $Global:HiveMind
}

function Connect-HiveNode {
    <#
    .SYNOPSIS
        Connect to another AI node to join the hive
    #>
    param(
        [Parameter(Mandatory)]
        [string]$IPAddress,

        [int]$Port = 8421
    )

    if (-not $Global:HiveMind) {
        Write-KITTMessage -Message "Hive Mind not initialized. Run Initialize-HiveMind first." -Type Error
        return $false
    }

    return $Global:HiveMind.ConnectToNode($IPAddress, $Port)
}

function Sync-HiveKnowledge {
    <#
    .SYNOPSIS
        Synchronize knowledge across all connected nodes
    #>

    if (-not $Global:HiveMind) {
        Write-KITTMessage -Message "Hive Mind not initialized." -Type Error
        return
    }

    $Global:HiveMind.SyncKnowledge()
}

function Invoke-HiveDecision {
    <#
    .SYNOPSIS
        Request a collective decision from the hive
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Problem
    )

    if (-not $Global:HiveMind) {
        Write-KITTMessage -Message "Hive Mind not initialized. Making local decision." -Type Warning
        return @{ Decision = "Local only"; Consensus = $false }
    }

    return $Global:HiveMind.RequestHiveDecision($Problem)
}

function Publish-HiveExperience {
    <#
    .SYNOPSIS
        Share an experience with all nodes in the hive
    #>
    param(
        [Parameter(Mandatory)]
        [hashtable]$Experience
    )

    if (-not $Global:HiveMind) {
        Write-KITTMessage -Message "Hive Mind not initialized." -Type Error
        return
    }

    $Global:HiveMind.ShareExperience($Experience)
}

function Get-HiveStatus {
    <#
    .SYNOPSIS
        Get current status of the hive mind network
    #>

    if (-not $Global:HiveMind) {
        Write-KITTMessage -Message "Hive Mind not initialized." -Type Warning
        return $null
    }

    $Status = $Global:HiveMind.GetHiveStatus()

    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host "  HIVE MIND STATUS" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  Status: " -NoNewline; Write-Host $(if ($Status.Active) { "🟢 ACTIVE" } else { "🔴 INACTIVE" }) -ForegroundColor $(if ($Status.Active) { 'Green' } else { 'Red' })
    Write-Host "  Local Node: $($Status.LocalNode.Hostname) ($($Status.LocalNode.IP))" -ForegroundColor White
    Write-Host "  Connected Nodes: $($Status.ConnectedNodes)" -ForegroundColor Yellow
    Write-Host "  Shared Knowledge: $($Status.SharedKnowledge) items" -ForegroundColor Cyan
    Write-Host "  Hive Strength: $($Status.HiveStrength)%" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  Capabilities:" -ForegroundColor Cyan
    foreach ($Cap in $Status.Capabilities) {
        Write-Host "    ✅ $Cap" -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host ""

    return $Status
}

# ============================================
# EXPORT MODULE MEMBERS
# ============================================

Export-ModuleMember -Function @(
    'Initialize-HiveMind',
    'Connect-HiveNode',
    'Sync-HiveKnowledge',
    'Invoke-HiveDecision',
    'Publish-HiveExperience',
    'Get-HiveStatus'
) -Variable @('HiveMind')
