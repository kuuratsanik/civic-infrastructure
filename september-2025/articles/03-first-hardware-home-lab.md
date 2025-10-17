# Article Analysis: Essential Home Lab Hardware Components

**Source**: https://www.virtualizationhowto.com/2025/09/the-first-hardware-i-always-buy-for-any-home-lab/  
**Date**: September 26, 2025  
**Category**: Home Lab  
**Author**: Brandon Lee

## Executive Summary

This article identifies the four absolute core hardware components needed to build a successful home lab: managed switches, mini PCs, UPS (uninterruptible power supply), and NAS (network-attached storage). The author emphasizes that these foundational pieces should be prioritized before any software stacks, as they provide the physical infrastructure that everything else depends on.

## Key Hardware Categories

### 1. Managed Switches - The Network Foundation

**Core Requirements**:
- Management capabilities (VLAN, LAG, SVI configuration)
- Low power consumption and fanless operation
- Minimum 10 GbE uplinks (2 ports)
- Optional: 2.5 GbE multi-gig copper ports

**Recommended Models**:

#### MikroTik CRS310-8G+2S+IN (~$210)
- **8x 2.5G copper ports** (backward compatible to 1 GbE)
- **2x SFP+ 10G uplinks**
- **Fanless** (silent operation)
- **Power efficient**
- **MikroTik Winbox** management tool
- **Best for**: Future-proofing with 2.5G + 10G mix

#### MikroTik CRS305-1G-4S+IN
- **4x SFP+ 10G ports**
- **1x 1G management port**
- **Fanless**
- **Low power draw**
- **Best for**: Dedicated 10 GbE uplinks (DAC/fiber between nodes)

#### Netgear GS108T-300NAS (Budget Option)
- **8x 1G smart managed ports**
- **VLAN and trunking support**
- **Set-and-forget reliability**
- **Best for**: Entry-level managed switching on a budget

**Why Switches First?**:
- Enables network segmentation (VLANs) like production environments
- Unlocks higher throughput (10 GbE for storage, multi-gig for clients)
- Provides management interface for advanced configurations
- Foundation for all other home lab services

### 2. Mini PCs - The Compute Foundation

**Author's Evolution**: "I've moved from enterprise 2U servers to mini PCs and couldn't be happier" (driven by 3x electricity cost increase)

**Recommended Models**:

#### Minisforum MS-A2
- **CPUs**: Uniform Ryzen processors
- **NICs**: Intel (VMware + Proxmox compatible)
- **Memory**: DDR5, up to 128 GB
- **Storage**: Multiple NVMe slots
- **Best for**: Serious workloads with enterprise compatibility

#### DIY Mini PC Build - Minisforum BD795i SE / BD790i X3D Motherboards
- **CPU Options**: Ryzen 9 7945HX, X3D chips
- **Form Factor**: Mini-ITX
- **Features**: Control over CPU boost (power efficiency tuning)
- **Flexibility**: Custom cooling, storage, RAM configurations
- **Best for**: Enthusiasts who want maximum control

#### Geekom A5 2025 Edition (Budget + Low Power)
- **CPU**: Ryzen 5 7430U
- **RAM**: 16 GB out of box
- **Power**: Ultra-low consumption
- **Proxmox**: Tested and verified excellent compatibility
- **Best for**: Budget-conscious, multi-node clusters, low power priority

**Mini PC Advantages**:
- **Energy efficient**: 1/10th power of enterprise servers
- **Silent**: Can run in bedroom without noise
- **Horizontal scaling**: Easy to add more nodes
- **Modern specs**: DDR5, NVMe, 10 GbE capable
- **Cost-effective**: 3-4 mini PCs < cost of 1 enterprise server

### 3. UPS - The Protection Layer

**Why UPS is Core, Not Optional**:
- **Data integrity**: Prevents dirty shutdowns and corruption
- **Hardware protection**: Guards against surges, brownouts, voltage spikes
- **Insurance**: Protects entire hardware investment
- **Graceful shutdown**: Time to properly shut down services

**Key Features to Look For**:
- **Capacity**: Measured in VA (volt-amperes)
- **Waveform**: Pure sine wave preferred for sensitive equipment
- **Monitoring**: USB or network connection for software integration
- **Runtime**: Enough to gracefully shut down (10-15 minutes typical for home lab)

**Recommended Models**:

#### APC Back-UPS Pro 1000VA
- **Capacity**: 1000VA / 600W
- **Front display**: Status at a glance
- **Runtime**: Enough for 2-3 mini PCs + switch
- **USB**: Monitoring and auto-shutdown software
- **Best for**: Small to medium home labs

#### CyberPower CP1500PFCLCD
- **Capacity**: 1500VA / 1000W
- **Pure sine wave**: Clean power output
- **LCD display**: Detailed metrics
- **USB monitoring**: Full integration with NUTs, etc.
- **Popular in home lab community**
- **Best for**: Larger setups, multiple nodes + NAS

#### GoldenMate 1000VA UPS (LiFePO4 Battery)
- **Battery Tech**: LiFePO4 (lithium iron phosphate)
- **Lifespan**: Never need to replace battery (10+ years)
- **Weight**: Lighter than lead-acid UPS
- **Maintenance**: Zero maintenance
- **Best for**: Long-term investment, eco-conscious users

**UPS as Infrastructure**:
- Treat as foundational, not nice-to-have
- Budget $150-300 depending on capacity needs
- Plan for graceful shutdown scripts (NUTs integration)
- Test quarterly (pull plug, verify shutdown automation)

### 4. NAS - The Storage Foundation (or Mini PC Substitute)

**Modern NAS Evolution**: "NAS devices today are essentially hyperconverged nodes"

**Key Observation**: NAS devices are now so powerful (Ryzen CPUs, DDR5, NVMe) that they can **replace** mini PCs, not just complement them.

**Recommended Models**:

#### Aoostar WTR Max (Hyperconverged NAS/Compute)
- **CPU**: Ryzen 7 8845HS (high-performance)
- **Memory**: DDR5 support
- **Storage**: Multiple NVMe slots
- **Use Cases**:
  - NAS duties (TrueNAS, Unraid)
  - **OR** Proxmox host (run VMs on the NAS itself)
  - **OR** Docker host (containerized services)
- **Best for**: Single-node hyperconverged setup

#### TerraMaster F8 SSD Plus (All-Flash NAS)
- **8x NVMe bays** (no spinning disks)
- **All-flash array**: High IOPS for performance workloads
- **TOS Software**: TerraMaster OS (improving)
- **iSCSI Target**: Tested with VMware vSphere clusters
- **Note**: NVMe slots don't run at full PCIe 4.0 speeds (shared lanes)
- **Best for**: High-performance storage, iSCSI LUNs, database workloads

#### Ugreen NASync 4800DX (Balanced 8-Bay NAS)
- **CPU**: Modern Intel processor
- **NICs**: 10 GbE networking
- **Bays**: 8x drive bays (spinning + SSD mix)
- **OS**: Newer to market, but feature-rich
- **Hardware**: Excellent build quality
- **Best for**: Large capacity needs, 10 GbE connectivity, expandability

**NAS Strategy: "OR" vs "AND"**:
- **Traditional**: Mini PC **AND** NAS (separate compute + storage)
- **Modern**: NAS **OR** Mini PC (hyperconverged - NAS can run VMs/containers)
- **Decision Factors**:
  - Budget: Hyperconverged NAS = one purchase instead of two
  - Use case: If NAS CPU powerful enough, skip mini PC
  - Redundancy: Separate compute + storage allows independent failures

## Windows 11 Customization Implications

### 1. Minimal Hardware for Civic Infrastructure

**Current Project Assumption**: Running on single Windows 11 Pro workstation

**Recommended Minimum Upgrade**:

```yaml
Tier 1 - Bare Minimum ($400-600):
  Switch: Netgear GS108T-300NAS (~$80)
    - 8x 1 GbE managed ports
    - VLAN support for network segmentation
  
  Compute: Use existing Windows 11 workstation
    - No additional mini PC needed yet
  
  UPS: APC Back-UPS Pro 1000VA (~$180)
    - Protects workstation + switch
    - Graceful shutdown automation
  
  Storage: External USB 3.0 SSD (2TB) (~$150)
    - Backup evidence/ directory
    - Separate from primary OS drive

Tier 2 - Recommended ($1500-2000):
  Switch: MikroTik CRS310-8G+2S+IN (~$210)
    - 2.5G ports for future expansion
    - 10G uplinks ready
  
  Compute: Geekom A5 2025 + existing workstation (~$600)
    - Geekom runs Proxmox (isolated test VMs)
    - Existing workstation runs main civic infrastructure
  
  UPS: CyberPower CP1500PFCLCD (~$250)
    - Pure sine wave
    - Enough capacity for both machines + switch
  
  Storage: TerraMaster F2 (2-bay NAS) (~$400)
    - RAID 1 mirroring for evidence/
    - Automated backups via n8n

Tier 3 - Production-Ready ($3000-4000):
  Switch: MikroTik CRS310-8G+2S+IN (~$210)
  
  Compute: Minisforum MS-A2 x 2 (~$1600)
    - Proxmox cluster (HA)
    - Run civic infrastructure in VMs
    - Failover capabilities
  
  UPS: CyberPower CP1500PFCLCD x 2 (~$500)
    - One UPS per mini PC + shared switch
  
  Storage: Aoostar WTR Max (~$1200)
    - Hyperconverged NAS/compute
    - Can run Proxmox + TrueNAS in VMs
    - NVMe storage for evidence/
```

**Recommendation for Civic Infrastructure**: **Tier 2**
- Balances cost, capability, and future-proofing
- Enables testing/staging (Geekom) vs production (main workstation)
- Provides network segmentation (VLAN isolation for civic services)
- Protects investment with UPS + RAID storage

### 2. Network Segmentation for Governance

**Use Case**: Separate civic infrastructure services by trust level

```
VLAN Design (requires managed switch):

VLAN 10 - Management
  - MikroTik switch management interface
  - Proxmox web UI
  - UPS monitoring (NUTs)

VLAN 20 - Civic Infrastructure (Trusted)
  - docker/n8n automation
  - logs/council_ledger.jsonl (blockchain)
  - evidence/ storage

VLAN 30 - External Services (Untrusted)
  - Reverse proxy (Pangolin/NPM)
  - Public-facing services
  - Test/staging environments

VLAN 40 - IoT/Lab (Isolated)
  - Smart home devices
  - Experimental VMs
  - Untrusted workloads

Firewall Rules:
  - VLAN 30 → VLAN 20: Denied (external cannot access blockchain directly)
  - VLAN 20 → VLAN 30: Allowed (civic services can respond to external)
  - VLAN 40 → Any: Denied (IoT fully isolated)
  - VLAN 10 → Any: Allowed (management access)
```

**Implementation**:
```powershell
# ceremonies/02-network/Configure-VLANs.ps1
function Set-CivicVLANs {
    param(
        [string]$SwitchIP = "192.168.1.1"
    )
    
    # Configure VLANs via MikroTik API
    $vlans = @(
        @{ ID = 10; Name = "Management"; Subnet = "192.168.10.0/24" },
        @{ ID = 20; Name = "Civic-Infra"; Subnet = "192.168.20.0/24" },
        @{ ID = 30; Name = "External"; Subnet = "192.168.30.0/24" },
        @{ ID = 40; Name = "IoT-Lab"; Subnet = "192.168.40.0/24" }
    )
    
    foreach ($vlan in $vlans) {
        New-MikroTikVLAN -SwitchIP $SwitchIP -VLANID $vlan.ID -Name $vlan.Name
        Write-Host "✓ VLAN $($vlan.ID) ($($vlan.Name)) created" -ForegroundColor Green
    }
    
    # Log to blockchain
    Add-BlockchainRecord -Action "VLAN Configuration Applied" `
        -Metadata @{ VLANs = $vlans.Count; Switch = $SwitchIP }
}
```

### 3. Power Management and Graceful Shutdown

**Challenge**: Windows 11 doesn't have native UPS integration like Linux (NUTs)

**Solution**: Use Windows-compatible UPS software

```powershell
# ceremonies/04-power/Configure-UPS.ps1

# Option 1: APC PowerChute Personal Edition (for APC UPS)
function Install-APCPowerChute {
    $downloadUrl = "https://www.apc.com/shop/us/en/products/PowerChute-Personal-Edition-v3-1-0-Windows"
    Invoke-WebRequest -Uri $downloadUrl -OutFile "C:\Temp\PowerChute.exe"
    
    Start-Process -FilePath "C:\Temp\PowerChute.exe" -ArgumentList "/S" -Wait
    
    # Configure graceful shutdown
    Set-APCShutdownDelay -Minutes 5
    Set-APCLowBatteryAction -Action "Shutdown"
}

# Option 2: CyberPower PowerPanel (for CyberPower UPS)
function Install-CyberPowerPanel {
    $downloadUrl = "https://www.cyberpowersystems.com/products/software/power-panel-personal/"
    Invoke-WebRequest -Uri $downloadUrl -OutFile "C:\Temp\PowerPanel.exe"
    
    Start-Process -FilePath "C:\Temp\PowerPanel.exe" -ArgumentList "/SILENT" -Wait
    
    # Configure actions
    Set-PowerPanelShutdownScript -Path "C:\civic-infrastructure\scripts\Pre-Shutdown-Backup.ps1"
}

# Custom pre-shutdown script
# C:\civic-infrastructure\scripts\Pre-Shutdown-Backup.ps1
function Invoke-PreShutdownBackup {
    Write-Host "UPS battery low - executing emergency backup..." -ForegroundColor Red
    
    # 1. Stop n8n gracefully
    docker stop civic-n8n
    
    # 2. Backup blockchain ledger
    Copy-Item "C:\civic-infrastructure\logs\council_ledger.jsonl" `
        -Destination "C:\civic-infrastructure\evidence\emergency-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').jsonl"
    
    # 3. Export Docker volumes
    docker run --rm -v civic-n8n-data:/data -v C:\Backups:/backup `
        alpine tar czf /backup/n8n-emergency-$(Get-Date -Format 'yyyyMMdd').tar.gz /data
    
    # 4. Log to blockchain (if time permits)
    Add-BlockchainRecord -Action "Emergency UPS Shutdown" `
        -Metadata @{ Reason = "Power loss"; Backup = "Completed" }
    
    # 5. Sync all writes to disk
    Write-VolumeCache -DriveLetter C
    
    Write-Host "✓ Emergency backup complete - system shutting down" -ForegroundColor Green
}
```

**Ceremony Integration**:
- **Foundation Ceremony**: Install UPS software, configure shutdown scripts
- **Power Ceremony**: Test UPS failover monthly, verify backup scripts execute
- **Audit Ceremony**: Review UPS logs quarterly, check battery health

### 4. Storage Strategy for Evidence and Logs

**Current State**: Everything on C:\ (single point of failure)

**Recommended Architecture**:

```
Primary Storage (C:\):
  └── civic-infrastructure/
      ├── scripts/       # PowerShell automation
      ├── configs/       # Templates and policies
      └── docker/        # Compose files

Secondary Storage (NAS at \\civic-nas\):
  └── evidence/
      ├── builds/        # ISO build evidence
      ├── hashes/        # Cryptographic verification
      └── deltas/        # Change tracking
  └── logs/
      ├── council_ledger.jsonl  # PRIMARY BLOCKCHAIN COPY
      ├── civic.jsonl    # Civic agent logs
      └── backups/       # Automated daily backups

Tertiary Storage (Cloud - Azure Blob):
  └── civic-backups/
      ├── weekly/        # Weekly full backups
      └── monthly/       # Monthly archival
```

**Implementation**:
```powershell
# ceremonies/05-storage/Configure-Storage-Tiers.ps1

function Set-CivicStorageTiers {
    # 1. Mount NAS as network drive
    New-PSDrive -Name "CivicNAS" -PSProvider FileSystem `
        -Root "\\192.168.20.100\civic-share" -Persist
    
    # 2. Create directory structure
    $nasDirs = @("evidence/builds", "evidence/hashes", "evidence/deltas", 
                 "logs", "logs/backups")
    foreach ($dir in $nasDirs) {
        New-Item -Path "CivicNAS:\$dir" -ItemType Directory -Force
    }
    
    # 3. Migrate blockchain ledger to NAS (primary copy)
    Copy-Item "C:\civic-infrastructure\logs\council_ledger.jsonl" `
        -Destination "CivicNAS:\logs\council_ledger.jsonl" -Force
    
    # 4. Create symlink on C:\ for backward compatibility
    New-Item -ItemType SymbolicLink `
        -Path "C:\civic-infrastructure\logs\council_ledger.jsonl" `
        -Target "CivicNAS:\logs\council_ledger.jsonl"
    
    # 5. Configure automated backups (n8n workflow)
    # See: docker/n8n/workflows/storage-backup.json
    
    Write-Host "✓ Storage tiers configured" -ForegroundColor Green
    Write-Host "  - Primary: C:\ (scripts, configs)" -ForegroundColor Gray
    Write-Host "  - Secondary: CivicNAS (evidence, logs)" -ForegroundColor Gray
    Write-Host "  - Tertiary: Azure Blob (cloud backups)" -ForegroundColor Gray
}
```

### 5. Horizontal Scaling with Mini PC Cluster

**Future State**: Transition from single workstation to 3-node Proxmox cluster

```
Node Architecture:

Node 1 (Minisforum MS-A2):
  - Proxmox VE host
  - VM: Windows 11 Pro (civic infrastructure primary)
  - VM: Ubuntu Server (n8n, Docker services)
  - VM: TrueNAS (centralized storage)

Node 2 (Minisforum MS-A2):
  - Proxmox VE host
  - VM: Windows 11 Pro (civic infrastructure replica)
  - VM: Ubuntu Server (n8n replica)
  - VM: Test/staging environment

Node 3 (Geekom A5):
  - Proxmox VE host
  - VM: Windows Server 2025 (testing Windows features)
  - VM: Kubernetes (container orchestration experiments)
  - VM: GitLab (source control, CI/CD)

Proxmox Cluster Benefits:
  - HA: If Node 1 fails, Node 2 takes over (VM migration)
  - Live migration: Move VMs between nodes without downtime
  - Centralized management: Single Proxmox UI for all nodes
  - Resource pooling: Distribute VMs based on load
  - Snapshot/backup: Unified backup strategy across nodes
```

**Migration Path**:
```powershell
# Phase 1: Keep existing Windows 11 workstation
# Phase 2: Add Node 1 (Geekom A5) for testing
# Phase 3: Add Node 2 (MS-A2) and migrate workloads to VMs
# Phase 4: Add Node 3 (MS-A2) for full HA cluster
# Phase 5: Repurpose physical workstation for other uses

# Each phase logged to blockchain
Add-BlockchainRecord -Action "Cluster Expansion - Node 2 Added" `
    -Metadata @{ Node = "Minisforum MS-A2"; Role = "HA Replica"; IP = "192.168.20.12" }
```

## Hardware Budget Guidance

### Entry Level ($500-800)
**Goal**: Protect current setup, add minimal expansion

- **Switch**: Netgear GS108T-300NAS ($80)
- **UPS**: APC Back-UPS Pro 1000VA ($180)
- **Storage**: USB 3.0 SSD 2TB ($150)
- **Network**: CAT6 cables, patch panel ($50)
- **Total**: ~$460

**Use Case**: Single Windows 11 workstation, basic protection

### Intermediate ($1500-2500)
**Goal**: Add compute redundancy, network segmentation, reliable storage

- **Switch**: MikroTik CRS310-8G+2S+IN ($210)
- **Compute**: Geekom A5 2025 ($600)
- **UPS**: CyberPower CP1500PFCLCD ($250)
- **Storage**: TerraMaster F2 2-bay NAS ($400) + 2x 4TB SSD ($400)
- **Network**: 10 GbE DAC cables, patch panel ($100)
- **Total**: ~$1960

**Use Case**: Production + staging environments, VLAN segmentation, RAID storage

### Advanced ($3500-5000)
**Goal**: Full HA cluster, enterprise features, high performance

- **Switch**: MikroTik CRS310-8G+2S+IN ($210) x 2 (stacked) ($420)
- **Compute**: Minisforum MS-A2 ($800) x 2 + Geekom A5 ($600) = $2200
- **UPS**: CyberPower CP1500PFCLCD ($250) x 2 ($500)
- **Storage**: Aoostar WTR Max ($1200) + NVMe drives ($400)
- **Network**: 10 GbE NICs, SFP+ modules, fiber ($300)
- **Total**: ~$4620

**Use Case**: 3-node Proxmox cluster, hyperconverged storage, 10 GbE everywhere

### Expert/Production ($8000-12000)
**Goal**: Rack-mounted, enterprise-grade, full redundancy

- **Switch**: MikroTik CRS328-24P-4S+RM (rackmount, PoE) ($400) x 2 ($800)
- **Compute**: Custom Ryzen builds in 2U chassis ($2000) x 3 = $6000
- **UPS**: APC SMT3000RM2U (rackmount, 3000VA) ($1800)
- **Storage**: TerraMaster F8 SSD Plus ($1000) + 8x 4TB NVMe ($2400)
- **Network**: Ubiquiti UDM-Pro, managed PoE switches, 40 GbE uplinks ($1500)
- **Rack**: 42U rack with cable management ($800)
- **Total**: ~$13300

**Use Case**: Production environment, rack-mounted, enterprise features, 24/7 uptime

**Civic Infrastructure Recommendation**: **Intermediate ($1500-2500)**
- Sufficient for current and near-future needs
- Enables production + staging separation
- Provides hardware redundancy (UPS, RAID)
- Budget-friendly while future-proof

## Best Practices from the Article

### 1. Start with Hardware, Not Software
**Quote**: "Software stacks will change often in your home lab, but good hardware that has a lot of capabilities is an investment that continues to pay off."

**Lesson**: Invest in quality hardware first
- Managed switch over basic switch (enables future VLANs, LAGs)
- 10 GbE-capable over 1 GbE-only (future-proof for storage)
- Pure sine wave UPS over simulated (cleaner power for sensitive gear)
- DDR5-capable mini PC over DDR4 (memory upgrade path)

### 2. Power Efficiency Matters
**Quote**: "Electricity has gone up 3x where I live, I have retrofitted everything with mini PCs."

**Calculation**:
```
Traditional 2U Server:
  - Power draw: 300-400W idle
  - 24/7 operation: 300W × 24h × 365d = 2628 kWh/year
  - Cost at $0.15/kWh: $394/year

Mini PC (Geekom A5):
  - Power draw: 15-25W idle
  - 24/7 operation: 20W × 24h × 365d = 175 kWh/year
  - Cost at $0.15/kWh: $26/year

Savings: $368/year per server replaced
```

**ROI**: Geekom A5 ($600) pays for itself in power savings vs enterprise server in <2 years

### 3. Modern NAS = Hyperconverged Node
**Quote**: "NAS devices today are essentially hyperconverged nodes - they have everything you need including compute, memory, and storage."

**Decision Matrix**:
```
When to buy NAS instead of Mini PC:
  ✓ Need >8TB storage capacity
  ✓ Require RAID redundancy
  ✓ Want single-unit hyperconverged solution
  ✓ Have budget for high-end NAS (Aoostar WTR Max, Ugreen 4800DX)

When to buy Mini PC + separate storage:
  ✓ Prefer separation of compute and storage (independent failures)
  ✓ Already have NAS or plan cloud storage
  ✓ Need maximum compute performance (dedicated CPU)
  ✓ Want to build Proxmox cluster (3+ mini PCs)

Civic Infrastructure: Mini PC + NAS
  - Geekom A5 (Proxmox host, testing)
  - TerraMaster F2 (evidence storage, RAID 1)
  - Keeps compute flexible, storage dedicated
```

### 4. Silent Operation is a Feature
**Quote**: "Mini PCs are quiet enough to run in most rooms of the house, even in a bedroom."

**Noise Levels**:
- Enterprise 2U server: 50-70 dB (loud, requires separate room/closet)
- Mini PC (fanless/low-rpm): 20-35 dB (whisper-quiet, bedroom-safe)
- Managed switch (fanless): 0 dB (completely silent)
- UPS (no load): 0 dB (silent until battery backup kicks in)

**Civic Infrastructure Benefit**:
- Can run 24/7 in home office without noise pollution
- Enables home lab in apartment/shared living without disturbing others
- Reduces WAF (Wife Acceptance Factor) friction

### 5. Don't Skimp on UPS
**Quote**: "Don't think of a UPS as an unnecessary piece of hardware. Think of it as something you NEED to put in place as a core part of your home lab."

**UPS is Insurance**:
```
Scenario: Power outage without UPS
  - Corrupted database: Hours/days to restore
  - Lost blockchain ledger: Months of work gone
  - Damaged hardware: $500-2000 replacement cost
  - Time cost: Countless hours rebuilding

Scenario: Power outage with UPS
  - Graceful shutdown: 5 minutes automated
  - Data integrity: 100% preserved
  - Hardware damage: 0% risk
  - Recovery time: Power restored, boot up, continue
```

**ROI**: $250 UPS protects $3000+ of hardware and priceless data. No-brainer investment.

## Implementation Ceremony

### New Ceremony: "Hardware Foundation Ceremony"

**Purpose**: Establish physical infrastructure for civic infrastructure

**Prerequisites**:
- Budget approved (Tier 1, 2, or 3)
- Hardware ordered and received
- Space prepared (desk, shelf, or rack)

**Steps**:

1. **Network Setup** (60 min)
   ```powershell
   - Unbox and mount MikroTik switch
   - Connect to management port
   - Configure VLANs (10, 20, 30, 40)
   - Test VLAN isolation
   - Log to blockchain
   ```

2. **Power Setup** (45 min)
   ```powershell
   - Unbox and position UPS
   - Install monitoring software (PowerChute/PowerPanel)
   - Configure graceful shutdown script
   - Test power fail simulation
   - Log to blockchain
   ```

3. **Compute Setup** (90 min)
   ```powershell
   - Unbox mini PC (Geekom A5)
   - Install Proxmox VE
   - Create first VM (Windows 11 test environment)
   - Verify network connectivity
   - Log to blockchain
   ```

4. **Storage Setup** (120 min)
   ```powershell
   - Unbox NAS (TerraMaster F2)
   - Install SSDs in RAID 1 configuration
   - Configure SMB share for evidence/
   - Mount on Windows 11 as network drive
   - Test read/write performance
   - Log to blockchain
   ```

5. **Integration Testing** (60 min)
   ```powershell
   - Verify all VLANs route correctly
   - Test UPS failover (pull plug, verify shutdown)
   - Migrate evidence/ directory to NAS
   - Verify blockchain ledger accessible from all VLANs
   - Create evidence bundle of hardware setup
   ```

6. **Documentation** (30 min)
   ```powershell
   - Update docs/governance/hardware-inventory.md
   - Create network diagram (draw.io or similar)
   - Document IP assignments, VLAN mappings
   - Create runbook for common tasks
   - Log ceremony completion to blockchain
   ```

**Total Time**: ~6 hours (one weekend day)

**Outcome**:
- Production-ready hardware infrastructure
- Network segmentation operational
- UPS protection active
- Evidence storage on RAID
- Blockchain-audited deployment

## Recommendations

### For Civic Infrastructure Project
**PRIORITY: MEDIUM-HIGH** (after software ceremonies, before production use)

**Why Upgrade Hardware**:
1. **Risk Mitigation**: UPS protects blockchain ledger from power-related corruption
2. **Scalability**: Managed switch + mini PC enable future growth (Proxmox cluster)
3. **Separation**: VLAN segmentation improves security (isolate civic services)
4. **Redundancy**: RAID NAS prevents single point of failure for evidence/
5. **Professionalism**: Enterprise features (VLANs, monitoring) align with civic governance goals

**Recommended Timeline**:
- **Month 1**: Purchase Tier 2 hardware ($2000 budget)
- **Month 2**: Execute Hardware Foundation Ceremony
- **Month 3**: Migrate civic infrastructure to hardware-backed environment
- **Month 6**: Evaluate Tier 3 upgrade (if scaling demands)

**Quick Wins**:
1. **UPS Deployment** (Week 1, $250)
   - Immediate protection for existing workstation
   - Graceful shutdown scripts
   - Blockchain evidence of power events

2. **Managed Switch** (Week 2, $210)
   - Enable VLAN segmentation
   - Improves security posture
   - Foundation for future 10 GbE

3. **NAS Storage** (Month 1, $800)
   - Migrate evidence/ to RAID 1
   - Automated backups via n8n
   - Blockchain-verified storage integrity

### Integration with Existing Work

```
october-2025/implementation-roadmap.md:
  → Add "Phase 4: Hardware Foundation"
  → Include Tier 2 hardware BOM
  → Estimate 6-hour ceremony

docker/n8n/workflows/:
  → Create "UPS Monitoring" workflow (alerts on battery events)
  → Create "NAS Backup" workflow (daily evidence/ sync)
  → Create "Hardware Health" workflow (disk SMART, switch uptime)

ceremonies/:
  → Create 06-hardware/ directory
  → Add Configure-VLANs.ps1
  → Add Configure-UPS.ps1
  → Add Configure-NAS.ps1

evidence/hardware/:
  → Store hardware purchase receipts
  → Log hardware inventory
  → Track warranty expirations
```

## Conclusion

Hardware is the foundation upon which all civic infrastructure operates. Investing in the four core components (managed switch, mini PC, UPS, NAS) provides:

1. **Reliability**: UPS and RAID storage prevent data loss
2. **Scalability**: Managed switch + mini PCs enable horizontal growth
3. **Professionalism**: Enterprise features align with governance goals
4. **Efficiency**: Modern hardware reduces power costs 80-90%
5. **Future-Proofing**: 10 GbE, DDR5, NVMe ready for next decade

**Recommendation**: **PROCEED WITH TIER 2 HARDWARE** ($2000 investment)
- Balances cost and capability
- Enables production + staging separation
- Provides redundancy and protection
- Aligns with civic infrastructure professionalism

**Timeline**: Month 1-2 for procurement and deployment

**Risk**: LOW (standard hardware, well-documented, proven in home lab community)

**ROI**: HIGH (protects $5000+ of work, enables future scaling, reduces power costs)

---

**Next Steps**:
1. Create hardware BOM (Bill of Materials) in `docs/governance/hardware-inventory.md`
2. Budget approval for Tier 2 hardware ($2000)
3. Schedule Hardware Foundation Ceremony (6-hour weekend)
4. Create n8n monitoring workflows
5. Document in QUICK-START.md
6. Log to blockchain upon completion

---

*Analysis completed as part of September 2025 civic infrastructure research.*  
*See `september-2025/implementation-roadmap.md` for hardware integration plan.*
