# DevMode2026 Strateegiline Analüüs - Käsklus

**Kuupäev**: 17. oktoober 2025
**Staatus**: OOTAB PÕHIKOODIBAASI JUURDEPÄÄSU

---

## 📋 Situatsiooni Ülevaade

### Leitud Repository

**URL**: https://github.com/Sven-Katkosilt/DevMode2026-Portal
**Tüüp**: Governance Portal (Juhtimisportaal)
**Sisu**:

- GitHub Actions governance workflow
- Civic ledger (`docs/ledger/merge-log.json`)
- Governance dokumentatsioon
- Validation testid

### Vajalik Repository

**Tüüp**: DevMode2026 Peamine Arenduskeskkond
**Oodatav sisu**:

- ✅ PowerShelli skriptid (`scripts/DevMode2026.ps1`, `Verify-Security.ps1`)
- ✅ Pythoni agendid (`agents/device/` koos `utils`, `adapters`, `validators`)
- ✅ Docker failid (`Dockerfile`, `Dockerfile.agents`, `docker-compose.yml`)
- ✅ Konfiguratsioonid (`.yaml`, `.json`, `Caddyfile`, `env/`)
- ✅ Web IDE (`webide/Dockerfile` koos `codercom/code-server`)
- ✅ Network Intelligence Platform kood
- ✅ Dokumentatsioon (`docs/NETWORK_INTELLIGENCE_IMPLEMENTATION.md`)

---

## 🎯 Algne Analüüsikäsklus (Estonian)

### Ülesanne

Teostada DevMode2026 projekti **süvaanalüüs ja moderniseerimine** (Q4 2025 tasemel).

### Roll

Ekspert-süsteemiarhitekt ja juhtiv tarkvaraarendaja.

### Põhiprintsiibid

1. **Isemajandamine ja null-eelarve** (Self-Hosted & Budget-Zero) [viide: 86, 114]
2. **Reetmiskindlus** (Betrayal-Resistance) [viide: 10, 83]
3. **Null-vea poliitika** (Zero Error Policy) [viide: 108, 111]
4. **Failide terviklikkuse poliitika** (File Integrity) [viide: 93, 103, 112]

---

## 📊 ETAPP 1: Põhjalik Analüüs

### 1.1 Koodi Kvaliteet ja Modulaarsus

**Analüüsitavad aspektid**:

- [ ] **Korduv kood**: Tuvasta PowerShelli funktsioonid nagu:

  - `Write-Log` - Logimise funktsioon
  - `Test-Prerequisites` - Eeltingimuste kontroll
  - `Invoke-Rollback` - Rollback funktsioon
  - Muud dubleeritud utiliidid

- [ ] **Monoliitsed skriptid**: Hinda järgmiste skriptide struktuuri:

  - `DevMode2026.ps1` - Peamine käivitusskript
  - `Verify-Security.ps1` - Turvakontroll
  - `Install-DevMode2026.ps1` - Paigaldamine
  - Kas need vajaksid jagamist väiksemateks mooduliteks?

- [ ] **Pythoni agentide struktuur** (`agents/device/`):
  - `utils/` - Abifunktsioonid
  - `adapters/` - Seadme adapterid (netconf.py, restconf.py)
  - `validators/` - Valideerijad
  - Kas esineb tsirkulaarseid sõltuvusi?
  - Kas struktuur on optimaalne?

### 1.2 Arhitektuur ja Disain

**Analüüsitavad aspektid**:

- [ ] **Komponentide koostoime**:

  - PowerShell ↔ Docker konteinerid
  - Docker ↔ Python agendid
  - Kuidas `docker-compose.yml` orkestreerida komponente?
  - Kas suhtlus on sujuv ja efektiivne?

- [ ] **Konfiguratsioonihaldus**:
  - Failiformaadid: `.yaml`, `.json`, `Caddyfile`
  - Kas kasutatakse keskkonna profiile (`env/`)?
  - Kas konfiguratsiooni saaks tsentraliseerida?
  - Kas dünaamiline konfigureerimine on võimalik?

### 1.3 Jõudlus ja Optimeerimine

**Analüüsitavad aspektid**:

- [ ] **Käivitusaeg**:

  - `DevMode2026.ps1` käivitusprotsess
  - Pudelikaelad (bottlenecks)
  - Ootetsüklid (nt Docker deemoni ootamine)
  - Paralleelsete käivitamise võimalused

- [ ] **Docker pildid**:
  - Baaspildid: Kas optimaalsed?
  - `webide/Dockerfile` (praegu: `codercom/code-server:4.96.2`)
  - `Dockerfile.agents`
  - **Multi-stage builds**: Kas kasutatakse? Kas saaks rakendada?
  - Pildi suurus: Kuidas vähendada?
  - Rünnakupind (attack surface): Kuidas minimeerida?

### 1.4 Turvalisus ja Vastupidavus

**Analüüsitavad aspektid**:

- [ ] **Sõltuvused**:

  - `requirements.txt` (Python)
  - `package.json` (Node.js)
  - Turvanõrkused: Kas on teadaolevaid CVE-sid?
  - Versioonid: Kas on fikseeritud?
  - Kas saaks kasutada `pip-tools` või `npm audit`?

- [ ] **Konteinerite turvalisus**:

  - Kas konteinerid töötavad root kasutajana?
  - Baaspildid: Kas saaks kasutada turvalisemaid (`alpine`, `slim-bookworm`)?
  - Kas rakendatakse parimate tavade mudelit?

- [ ] **Veahaldus**:
  - Kas `ZERO_ERROR_POLICY` on järjepidevalt rakendatud?
  - Rollback mehhanismid kõikides skriptides?
  - Logimise kvaliteet ja järjepidevus?

---

## 🔧 ETAPP 2: Strateegiline Moderniseerimine

### 2.1 Modulaarsuse Suurendamine

#### A. PowerShelli Keskne Moodul

**Ülesanne**: Luua `DevMode2026.psm1` moodul

**Sisu** (minimaalne struktuur):

```powershell
# DevMode2026.psm1
# Keskne PowerShelli moodul DevMode2026 projektile

#region Logging Functions
function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )
    # Implementatsioon
}

function Initialize-LogFile {
    param([string]$LogPath)
    # Implementatsioon
}
#endregion

#region Prerequisites
function Test-Prerequisites {
    param([hashtable]$Requirements)
    # Kontrollib WSL2, Docker, Hyper-V jne
}

function Test-NestedVirtualization {
    # Kontrollib pesastatud virtualiseerimise tuge
}
#endregion

#region Error Handling & Rollback
function Invoke-Rollback {
    param(
        [string]$CheckpointId,
        [scriptblock]$RollbackAction
    )
    # ZERO_ERROR_POLICY rakendamine
}

function New-Checkpoint {
    param([string]$Description)
    # Loob taastepunkti
}
#endregion

#region Configuration Management
function Get-DevModeConfig {
    param([string]$ConfigPath)
    # Laeb konfiguratsiooni
}

function Test-ConfigIntegrity {
    param([string]$ManifestPath)
    # FILE_INTEGRITY_POLICY rakendamine
}
#endregion

# Ekspordid
Export-ModuleMember -Function @(
    'Write-Log',
    'Initialize-LogFile',
    'Test-Prerequisites',
    'Test-NestedVirtualization',
    'Invoke-Rollback',
    'New-Checkpoint',
    'Get-DevModeConfig',
    'Test-ConfigIntegrity'
)
```

**Kasutamine** refaktoreeritud skriptides:

```powershell
# DevMode2026.ps1 (refaktoreeritud)
#Requires -Modules DevMode2026

Import-Module DevMode2026

Write-Log "Starting DevMode2026..." -Level INFO
Test-Prerequisites -Requirements @{
    WSL2 = $true
    Docker = $true
    NestedVirtualization = $true
}

# Jätka käivitusega...
```

#### B. Skriptide Refaktoreerimine

**Prioriteet 1**: `DevMode2026.ps1`

- Kasuta `DevMode2026.psm1` funktsioone
- Vähenda skripti pikkust 50%+
- Eemalda dubleeritud kood

**Prioriteet 2**: `Verify-Security.ps1`

- Kasuta keskset `Write-Log` funktsiooni
- Rakenda `Test-ConfigIntegrity` kasutamist

### 2.2 Moderniseerimine ja Parimad Praktikad (Q4 2025)

#### A. PowerShelli Klassid

**Soovitus**: Loo `Phase` klass käivitusfaaside haldamiseks

```powershell
class DevModePhase {
    [string]$Name
    [string]$Description
    [scriptblock]$Action
    [scriptblock]$Rollback
    [bool]$Critical
    [datetime]$StartTime
    [datetime]$EndTime
    [string]$Status  # Pending, Running, Success, Failed

    [void]Execute() {
        $this.Status = 'Running'
        $this.StartTime = Get-Date

        try {
            & $this.Action
            $this.Status = 'Success'
        }
        catch {
            $this.Status = 'Failed'
            if ($this.Critical) {
                & $this.Rollback
                throw
            }
        }
        finally {
            $this.EndTime = Get-Date
        }
    }
}

# Kasutamine
$phases = @(
    [DevModePhase]@{
        Name = 'Prerequisites'
        Description = 'Verify system requirements'
        Action = { Test-Prerequisites }
        Rollback = { Write-Log 'No rollback needed' }
        Critical = $true
    },
    [DevModePhase]@{
        Name = 'Docker'
        Description = 'Start Docker containers'
        Action = { docker-compose up -d }
        Rollback = { docker-compose down }
        Critical = $true
    }
)

foreach ($phase in $phases) {
    $phase.Execute()
}
```

#### B. Docker Optimeerimine

**1. Multi-Stage Build - webide/Dockerfile**

```dockerfile
# webide/Dockerfile (ENNE - Monoliitne)
FROM codercom/code-server:4.96.2
USER root
RUN apt-get update && apt-get install -y build-essential python3-pip
RUN pip3 install jupyter pandas numpy
COPY config.yaml /home/coder/.config/code-server/
USER coder
EXPOSE 8080
CMD ["code-server", "--bind-addr", "0.0.0.0:8080"]
```

**webide/Dockerfile (PÄRAST - Multi-Stage + Non-Root)**

```dockerfile
# Stage 1: Build stage
FROM codercom/code-server:4.96.2 AS builder
USER root

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        python3-pip \
        python3-dev && \
    rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip3 install --no-cache-dir --user \
    jupyter==1.0.0 \
    pandas==2.1.4 \
    numpy==1.26.2

# Stage 2: Runtime stage (Q4 2025 - kasuta uuemat versiooni)
FROM codercom/code-server:latest AS runtime

# Create non-root user (if not exists)
RUN if ! id -u coder > /dev/null 2>&1; then \
        useradd -m -s /bin/bash coder; \
    fi

# Copy only necessary files from builder
COPY --from=builder --chown=coder:coder /root/.local /home/coder/.local

# Copy config
COPY --chown=coder:coder config.yaml /home/coder/.config/code-server/

# Security: Run as non-root
USER coder

# Minimal runtime dependencies
USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3-minimal && \
    rm -rf /var/lib/apt/lists/*
USER coder

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/healthz || exit 1

EXPOSE 8080
ENTRYPOINT ["code-server"]
CMD ["--bind-addr", "0.0.0.0:8080", "--auth", "none"]
```

**Võidu märgid**:

- ✅ 40-60% väiksem lõplik pilt (build tools not included)
- ✅ Non-root kasutaja (turvaline)
- ✅ Health check (Kubernetes-ready)
- ✅ Minimeeritud rünnakupind

**2. Agents Dockerfile Optimeerimine**

```dockerfile
# Dockerfile.agents (PÄRAST - Multi-Stage + Alpine)
FROM python:3.12-alpine AS builder

WORKDIR /build

# Install build dependencies (only in builder)
RUN apk add --no-cache gcc musl-dev libffi-dev

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Stage 2: Runtime (minimal)
FROM python:3.12-alpine

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder --chown=appuser:appgroup /root/.local /home/appuser/.local

# Copy application code
COPY --chown=appuser:appgroup agents/ /app/agents/

# Security
USER appuser

# Set PATH to include user packages
ENV PATH="/home/appuser/.local/bin:$PATH"

# Health check
HEALTHCHECK --interval=60s --timeout=5s --start-period=10s \
    CMD python -c "import sys; sys.exit(0)"

CMD ["python", "-m", "agents.device.main"]
```

#### C. Python Agents Täiustamine

**1. pathlib Kasutamine**

```python
# agents/device/utils/file_ops.py (ENNE)
import os

config_path = os.path.join(os.path.dirname(__file__), '..', 'config.yaml')
if os.path.exists(config_path):
    with open(config_path, 'r') as f:
        config = yaml.safe_load(f)
```

```python
# agents/device/utils/file_ops.py (PÄRAST - pathlib)
from pathlib import Path

config_path = Path(__file__).parent.parent / 'config.yaml'
if config_path.exists():
    config = yaml.safe_load(config_path.read_text())
```

**2. requirements.txt Täiustamine (pip-tools)**

```bash
# Genereeri fikseeritud sõltuvused räsidega
pip-compile --generate-hashes --output-file=requirements.txt requirements.in

# Uuenda turvaliselt
pip-compile --upgrade --generate-hashes --output-file=requirements.txt requirements.in
```

```txt
# requirements.txt (PÄRAST - pip-tools)
certifi==2024.2.2 \
    --hash=sha256:0569859f95fc761b18b45ef421b1290a0f65f147e92a1e5eb3e635f9a5e4e66f
charset-normalizer==3.3.2 \
    --hash=sha256:f30c3cb33b24454a82faecaf01b19c18562b1e89558fb6c56de4d9118a032fd5
# ... (kõik sõltuvused koos SHA256 räsidega)
```

### 2.3 Nested Virtualization Strateegia

#### Uus Dokument: `docs/NESTED_VIRTUALIZATION_STRATEGY.md`

**Sisu** (täielik struktuur):

```markdown
# Pesastatud Virtualiseerimise Strateegia

# Nested Virtualization Strategy for DevMode2026

**Versioon**: 1.0.0
**Kuupäev**: 17. oktoober 2025
**Staatus**: STRATEEGILINE PLAAN

---

## 📖 Sissejuhatus

### Mis on Pesastatud Virtualiseerimine?

Pesastatud virtualiseerimine (nested virtualization) võimaldab käivitada
virtuaalmasinaid (VM) juba virtualiseeritud keskkonnas. DevMode2026
kontekstis tähendab see:

**WSL2 → Hyper-V/KVM → Võrguseadme VM-id**
```

┌─────────────────────────────────────────┐
│ Windows 11 Pro Host │
│ ├─ Hyper-V Enabled │
│ │ │
│ └─ WSL2 Instance (Ubuntu 24.04) │
│ ├─ DevMode2026 Environment │
│ │ │
│ └─ Nested VMs (KVM/QEMU) │
│ ├─ OPNsense VM (Router/FW) │
│ ├─ Juniper vSRX (Enterprise FW) │
│ └─ Cisco CSR1000v (Router) │
└─────────────────────────────────────────┘

```

### Miks See on DevMode2026 Jaoks Väärtuslik?

1. **Täielik Isoleerimine**: Võrguseadmete testimine ei mõjuta host süsteemi
2. **Korratavus**: Virtuaalsed seadmed on skriptitavad ja versioonitud
3. **Null-Eelarve**: Kasuta tasuta virtuaalseid seadmeid füüsilise riistvara asemel
4. **Turvaline Eksperimenteerimine**: Pahavara analüüs isoleeritud keskkonnas

---

## 🎯 Kasutusjuhud

### 1. Universal Device Agent Testimine

**Probleem**: Seadmeagendi (`agents/device/`) testimine nõuab juurdepääsu
erinevatele võrguseadmetele (Cisco, Juniper, OPNsense).

**Lahendus**: WSL2-s pesastatud virtualiseerimisega käivita virtuaalsed
võrguseadmed.

**Arhitektuur**:
```

DevMode2026 (WSL2)
↓
agents/device/
├── adapters/
│ ├── netconf.py → Ühendus virtuaalsele Juniper vSRX
│ ├── restconf.py → Ühendus virtuaalsele Cisco CSR1000v
│ └── ssh.py → Ühendus virtuaalsele OPNsense
│
└── tests/
└── integration/
├── test_netconf_juniper.py
├── test_restconf_cisco.py
└── test_ssh_opnsense.py

```

**Testimise voog**:
1. `New-VirtualTestLab.ps1` loob virtuaalse võrgu
2. Käivitab OPNsense, Juniper vSRX, Cisco CSR1000v VM-id
3. Konfigur voog testib kõiki adaptereid vastu virtuaalseid seadmeid
4. `Remove-VirtualTestLab.ps1` puhastab keskkonna

**Eelised**:
- ✅ Ei nõua füüsilist riistvara ($0 kulud)
- ✅ Täielikult automatiseeritud ja korratav
- ✅ Saab testida ohtlikke stsenaariume (seadme crash, võrgu katkestus)
- ✅ CI/CD integratsioon (GitHub Actions self-hosted runner WSL2-s)

### 2. Network Intelligence Platform Täiustamine

**Viide**: `docs/NETWORK_INTELLIGENCE_IMPLEMENTATION.md`

**Probleem**: Andmekogumisagendid (`collectors`) peavad töötlema potentsiaalselt
ohtlikke andmeid (log analüüs, traffic inspection).

**Lahendus**: Käivita collectors'id isoleeritud VM-ides.

**Arhitektuur**:
```

Network Intelligence Platform
↓
collectors/ (iga VM-is)
├── log-collector VM → Analüüsib syslog (isoleeritud)
├── snmp-collector VM → SNMP trap handling (isoleeritud)
└── flow-collector VM → NetFlow/sFlow (isoleeritud)
↓
Central Database (host)

```

**Turvaeelised**:
- ⚠️ Kui collector kompromiteeritakse, on kahjustus piiratud ühe VM-iga
- ✅ VM saab ennistada snapshot'ist sekundite jooksul
- ✅ Pahavara analüüs ilma host süsteemi ohustamata

### 3. Integratsioonitestide Raamistik

**Eesmärk**: Luua automatiseeritud testimisraamistik, mis käivitab keerukaid
võrgu stsenaariume.

**Näide testsüsteemist**:
```

Test Scenario: "Multi-Vendor BGP Peering"
├── VM1: Cisco CSR1000v (AS 65001)
├── VM2: Juniper vSRX (AS 65002)
└── VM3: OPNsense (AS 65003)

Test: Kontrolli, kas DevMode2026 agent suudab:

1. Konfigureerida BGP peering'uid kõigis 3 seadmes
2. Verifitseerida, et peering on UP
3. Simuleerida link failure'it
4. Kontrollida failover käitumist

````

**Skript**: `tests/integration/test_bgp_multivendor.py`

```python
import pytest
from devmode2026.testing import VirtualLab
from agents.device import DeviceAgent

@pytest.fixture
def bgp_lab():
    lab = VirtualLab()
    lab.add_device('cisco-csr', image='cisco-csr1000v')
    lab.add_device('juniper-vsrx', image='juniper-vsrx')
    lab.add_device('opnsense', image='opnsense')
    lab.start()
    yield lab
    lab.destroy()

def test_bgp_peering(bgp_lab):
    agent = DeviceAgent()

    # Configure BGP on all devices
    agent.configure_bgp('cisco-csr', as_number=65001)
    agent.configure_bgp('juniper-vsrx', as_number=65002)
    agent.configure_bgp('opnsense', as_number=65003)

    # Verify peerings
    assert agent.verify_bgp_peer('cisco-csr', '192.168.1.2')
    assert agent.verify_bgp_peer('juniper-vsrx', '192.168.1.3')
````

---

## 🛠️ Rakendusplaan

### Faas 1: Eeltingimused (1-2 päeva)

#### 1.1 Luba Pesastatud Virtualiseerimine Windows-is

**Skript**: Uuenda `Install-DevMode2026.ps1`

```powershell
# Install-DevMode2026.ps1 (Lisa)
function Enable-NestedVirtualization {
    Write-Log "Checking nested virtualization support..." -Level INFO

    # Check CPU support
    $cpuSupport = Get-WmiObject -Class Win32_Processor |
        Select-Object -ExpandProperty SecondLevelAddressTranslationExtensions

    if (-not $cpuSupport) {
        Write-Log "CPU does not support nested virtualization (SLAT required)" -Level ERROR
        throw "Hardware requirement not met"
    }

    # Check Hyper-V status
    $hyperv = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V
    if ($hyperv.State -ne 'Enabled') {
        Write-Log "Enabling Hyper-V..." -Level WARN
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
        Write-Log "Hyper-V enabled. Restart required!" -Level WARN
        return $false
    }

    # Configure WSL2 for nested virtualization
    $wslConfig = @"
[wsl2]
nestedVirtualization=true
kernel=C:\\wsl-kernel\\bzImage
memory=16GB
processors=8
"@

    $wslConfigPath = "$env:USERPROFILE\.wslconfig"
    $wslConfig | Out-File -FilePath $wslConfigPath -Encoding utf8

    Write-Log "Nested virtualization configured in .wslconfig" -Level SUCCESS
    Write-Log "Restart WSL: wsl --shutdown" -Level INFO

    return $true
}

# Lisa põhiskriptisse
if (-not (Enable-NestedVirtualization)) {
    Write-Log "Please restart your computer and run this script again" -Level WARN
    exit 1
}
```

#### 1.2 Installi KVM/QEMU WSL2-s

```bash
# WSL2 (Ubuntu 24.04)
sudo apt-get update
sudo apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager

# Verify
sudo systemctl status libvirtd
```

### Faas 2: Virtual Test Lab Automation (3-5 päeva)

#### 2.1 PowerShelli Raamistik

**Uus skript**: `scripts/New-VirtualTestLab.ps1`

```powershell
#Requires -Version 7.0
#Requires -Modules DevMode2026

<#
.SYNOPSIS
    Create virtual network test lab with nested VMs

.EXAMPLE
    .\New-VirtualTestLab.ps1 -Scenario BGP-MultiVendor
#>

param(
    [Parameter(Mandatory)]
    [ValidateSet('Basic', 'BGP-MultiVendor', 'OSPF-Failover', 'Security-Test')]
    [string]$Scenario,

    [string]$LabName = "TestLab-$(Get-Date -Format 'yyyyMMdd-HHmmss')",

    [switch]$SkipImageDownload
)

Import-Module DevMode2026

class VirtualDevice {
    [string]$Name
    [string]$Type  # cisco, juniper, opnsense
    [string]$Image
    [string]$ManagementIP
    [int]$Memory  # MB
    [int]$CPUs
    [hashtable]$Interfaces

    [void]Deploy() {
        Write-Log "Deploying $($this.Name) ($($this.Type))..." -Level INFO

        # Create VM using virsh/KVM in WSL2
        $cmd = @"
wsl bash -c "virsh define <(cat <<EOF
<domain type='kvm'>
  <name>$($this.Name)</name>
  <memory unit='MB'>$($this.Memory)</memory>
  <vcpu>$($this.CPUs)</vcpu>
  <os>
    <type arch='x86_64'>hvm</type>
  </os>
  <devices>
    <disk type='file' device='disk'>
      <source file='/var/lib/libvirt/images/$($this.Image)'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <interface type='network'>
      <source network='$($this.ManagementNetwork)'/>
      <model type='virtio'/>
    </interface>
  </devices>
</domain>
EOF
)"
"@

        Invoke-Expression $cmd

        # Start VM
        wsl bash -c "virsh start $($this.Name)"

        Write-Log "$($this.Name) deployed successfully" -Level SUCCESS
    }

    [void]WaitForBoot() {
        Write-Log "Waiting for $($this.Name) to boot..." -Level INFO

        $timeout = 300  # 5 minutes
        $elapsed = 0

        while ($elapsed -lt $timeout) {
            $reachable = Test-NetConnection -ComputerName $this.ManagementIP -Port 22 -WarningAction SilentlyContinue

            if ($reachable.TcpTestSucceeded) {
                Write-Log "$($this.Name) is ready!" -Level SUCCESS
                return
            }

            Start-Sleep -Seconds 10
            $elapsed += 10
        }

        throw "$($this.Name) failed to boot within $timeout seconds"
    }
}

function New-TestLabScenario {
    param([string]$Scenario)

    $devices = @()

    switch ($Scenario) {
        'BGP-MultiVendor' {
            $devices += [VirtualDevice]@{
                Name = 'cisco-csr1'
                Type = 'cisco'
                Image = 'csr1000v-universalk9.17.03.08.qcow2'
                ManagementIP = '192.168.100.10'
                Memory = 4096
                CPUs = 2
            }

            $devices += [VirtualDevice]@{
                Name = 'juniper-vsrx1'
                Type = 'juniper'
                Image = 'junos-vsrx3-x86-64-23.2R1.qcow2'
                ManagementIP = '192.168.100.11'
                Memory = 4096
                CPUs = 2
            }

            $devices += [VirtualDevice]@{
                Name = 'opnsense1'
                Type = 'opnsense'
                Image = 'OPNsense-24.1-OpenSSL-dvd-amd64.iso'
                ManagementIP = '192.168.100.12'
                Memory = 2048
                CPUs = 2
            }
        }

        # ... (teised stsenaariumid)
    }

    return $devices
}

# Main execution
try {
    Write-Log "Creating Virtual Test Lab: $LabName" -Level INFO
    Write-Log "Scenario: $Scenario" -Level INFO

    $checkpoint = New-Checkpoint -Description "Before creating $LabName"

    # Get scenario devices
    $devices = New-TestLabScenario -Scenario $Scenario

    # Deploy each device
    foreach ($device in $devices) {
        $device.Deploy()
        $device.WaitForBoot()
    }

    # Create lab metadata
    $labInfo = @{
        Name = $LabName
        Scenario = $Scenario
        Created = Get-Date
        Devices = $devices | ForEach-Object {
            @{
                Name = $_.Name
                Type = $_.Type
                ManagementIP = $_.ManagementIP
            }
        }
    } | ConvertTo-Json -Depth 10

    $labInfo | Out-File "labs/$LabName.json"

    Write-Log "Virtual Test Lab created successfully!" -Level SUCCESS
    Write-Log "Lab info saved to: labs/$LabName.json" -Level INFO

    # Display connection info
    Write-Host "`nDevice Access Information:" -ForegroundColor Cyan
    foreach ($device in $devices) {
        Write-Host "  $($device.Name): ssh admin@$($device.ManagementIP)" -ForegroundColor White
    }
}
catch {
    Write-Log "Failed to create lab: $_" -Level ERROR
    Invoke-Rollback -CheckpointId $checkpoint
    throw
}
```

#### 2.2 Cleanup Skript

**Uus skript**: `scripts/Remove-VirtualTestLab.ps1`

```powershell
param(
    [Parameter(Mandatory)]
    [string]$LabName
)

Import-Module DevMode2026

$labInfoPath = "labs/$LabName.json"

if (-not (Test-Path $labInfoPath)) {
    Write-Log "Lab not found: $LabName" -Level ERROR
    exit 1
}

$labInfo = Get-Content $labInfoPath | ConvertFrom-Json

Write-Log "Destroying lab: $($labInfo.Name)" -Level WARN

foreach ($device in $labInfo.Devices) {
    Write-Log "Stopping $($device.Name)..." -Level INFO
    wsl bash -c "virsh destroy $($device.Name)"
    wsl bash -c "virsh undefine $($device.Name)"
}

Remove-Item $labInfoPath
Write-Log "Lab destroyed successfully" -Level SUCCESS
```

### Faas 3: Integration Tests (5-7 päeva)

#### 3.1 Pytest Raamistik

**Uus moodul**: `tests/integration/virtual_lab.py`

```python
from pathlib import Path
import subprocess
import time
import pytest

class VirtualLab:
    """Manage virtual test lab lifecycle for integration tests"""

    def __init__(self, scenario: str):
        self.scenario = scenario
        self.lab_name = f"pytest-{scenario}-{int(time.time())}"
        self.devices = []

    def start(self):
        """Create and start the virtual lab"""
        cmd = [
            "powershell.exe",
            "-File",
            "scripts/New-VirtualTestLab.ps1",
            "-Scenario", self.scenario,
            "-LabName", self.lab_name
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            raise RuntimeError(f"Failed to create lab: {result.stderr}")

        # Parse lab info
        lab_info_path = Path(f"labs/{self.lab_name}.json")
        with lab_info_path.open() as f:
            import json
            lab_info = json.load(f)
            self.devices = lab_info['Devices']

    def destroy(self):
        """Destroy the virtual lab"""
        cmd = [
            "powershell.exe",
            "-File",
            "scripts/Remove-VirtualTestLab.ps1",
            "-LabName", self.lab_name
        ]

        subprocess.run(cmd, capture_output=True)

    def get_device(self, name: str):
        """Get device by name"""
        for device in self.devices:
            if device['Name'] == name:
                return device
        raise ValueError(f"Device not found: {name}")


@pytest.fixture(scope="session")
def bgp_lab():
    """Session-scoped fixture for BGP multi-vendor lab"""
    lab = VirtualLab("BGP-MultiVendor")
    lab.start()
    yield lab
    lab.destroy()
```

#### 3.2 Integratsioonitestid

**Uus test**: `tests/integration/test_device_agent.py`

```python
import pytest
from agents.device import DeviceAgent
from tests.integration.virtual_lab import VirtualLab

def test_cisco_csr_connection(bgp_lab):
    """Test connection to Cisco CSR1000v"""
    agent = DeviceAgent()
    cisco = bgp_lab.get_device('cisco-csr1')

    result = agent.connect(
        host=cisco['ManagementIP'],
        adapter='netconf',
        username='admin',
        password='admin'
    )

    assert result.success
    assert result.device_type == 'cisco_iosxe'

def test_juniper_vsrx_connection(bgp_lab):
    """Test connection to Juniper vSRX"""
    agent = DeviceAgent()
    juniper = bgp_lab.get_device('juniper-vsrx1')

    result = agent.connect(
        host=juniper['ManagementIP'],
        adapter='netconf',
        username='root',
        password='Juniper'
    )

    assert result.success
    assert result.device_type == 'junos'

def test_bgp_configuration(bgp_lab):
    """Test BGP configuration across all devices"""
    agent = DeviceAgent()

    # Configure BGP on all devices
    cisco = bgp_lab.get_device('cisco-csr1')
    juniper = bgp_lab.get_device('juniper-vsrx1')
    opnsense = bgp_lab.get_device('opnsense1')

    # Cisco
    result = agent.configure_bgp(
        host=cisco['ManagementIP'],
        as_number=65001,
        router_id='1.1.1.1',
        neighbors=[
            {'ip': '192.168.1.2', 'remote_as': 65002},
            {'ip': '192.168.1.3', 'remote_as': 65003}
        ]
    )
    assert result.success

    # Juniper
    result = agent.configure_bgp(
        host=juniper['ManagementIP'],
        as_number=65002,
        router_id='2.2.2.2',
        neighbors=[
            {'ip': '192.168.1.1', 'remote_as': 65001}
        ]
    )
    assert result.success

    # Wait for BGP convergence
    time.sleep(30)

    # Verify peering
    peerings = agent.get_bgp_neighbors(cisco['ManagementIP'])
    assert len(peerings) == 2
    assert all(p['state'] == 'Established' for p in peerings)
```

---

## 📊 Rakenduse Ajaplaan

| Faas      | Ülesanded                         | Kestus          | Vastutus       |
| --------- | --------------------------------- | --------------- | -------------- |
| **1**     | Nested virt lubamine, KVM install | 1-2 päeva       | Infrastructure |
| **2**     | Virtual test lab automation       | 3-5 päeva       | DevOps         |
| **3**     | Integration tests framework       | 5-7 päeva       | QA/Testing     |
| **4**     | CI/CD integration                 | 2-3 päeva       | DevOps         |
| **Kokku** |                                   | **11-17 päeva** |                |

---

## ✅ Edukriitilised Tegurid

1. **Hardware Requirements**:

   - CPU: Intel VT-x või AMD-V toega (SLAT)
   - RAM: Minimaalselt 16GB (soovituslik 32GB)
   - Disk: 100GB+ vaba ruumi (VM pildid on suured)

2. **Licensing**:

   - Cisco CSR1000v: Eval license (90 päeva)
   - Juniper vSRX: Trial license
   - OPNsense: Open-source (tasuta)

3. **Network Configuration**:

   - WSL2 peab saama ligipääsu nested VM-idele
   - Libvirt default network (192.168.100.0/24)

4. **Documentation**:
   - Iga testsünastiku dokumenteerimine
   - Troubleshooting guide nested virt'i jaoks

---

## 🔐 Turvaaspektid

- ✅ Nested VM-id on isoleeritud host süsteemist
- ✅ Snapshots võimaldavad kiiret ennistamist
- ✅ Võrguliiklus ei lahku WSL2 keskkonnast (offline testing)
- ⚠️ VM pildid tuleb alla laadida usaldusväärsest allikast
- ⚠️ Kontrollida VM piltide räsisummasid (SHA256)

---

## 🎯 Järeldused

Pesastatud virtualiseerimise strateegia rakendamine DevMode2026 projektis
võimaldab:

1. **Null-Eelarve Testimine**: Võrguseadmete simulatsioon ilma riistvarata
2. **Täielik Automatiseerimine**: CI/CD pipeline'id integratsioonitestidega
3. **Turvalisus**: Isoleeritud testimiskeskkonnad
4. **Skaleeruvus**: Keerukate võrku stsenaariumide modelleerimine

See toetab DevMode2026 põhiprintsiipi: **Self-Hosted & Budget-Zero**.

---

**Järgmised sammud**:

1. Rakenda `Enable-NestedVirtualization` funktsioon
2. Loo `New-VirtualTestLab.ps1` skript
3. Kirjuta esimesed integratsioonitestid
4. Dokumenteeri VM piltide hankimise protsess

**Staatus**: ✅ STRATEEGIA MÄÄRATLETUD, OOTAB RAKENDAMIST

````

---

## 📋 ETAPP 3: Väljundi Formaat

### Oodatav Struktuur

```markdown
# DevMode2026 Süvaanalüüs ja Moderniseerimine
**Q4 2025 Tehnoloogiline Tase**

## 1. Kokkuvõte (Executive Summary)
- Peamised leiud (3-5 punkti)
- Kriitikapunktid (1-3 punkti)
- Strateegilised soovitused (5-7 punkti)

## 2. Analüüsi Tulemused

### 2.1 Koodi Kvaliteet ja Modulaarsus
- Korduv kood: [Analüüs ja näited]
- Monoliitsed skriptid: [Probleemid ja soovitused]
- Pythoni struktuuri: [Tsirkulaarsed sõltuvused, optimeerimisvõimalused]

### 2.2 Arhitektuur ja Disain
- Komponentide koostoime: [Analüüs]
- Konfiguratsioonihaldus: [Soovitused]

### 2.3 Jõudlus ja Optimeerimine
- Käivitusaja analüüs: [Bottleneck'id]
- Docker piltide analüüs: [Suurus, turvalisus]

### 2.4 Turvalisus ja Vastupidavus
- Sõltuvuste audit: [CVE-d, versioonid]
- Konteinerite turvalisus: [Root vs non-root]
- Veahaldus: [ZERO_ERROR_POLICY rakendamine]

## 3. Moderniseerimise Kava

### 3.1 Modulaarsuse Suurendamine
#### DevMode2026.psm1 Moodul
[Täielik kood 200-300 rida]

#### Refaktooritud Skriptid
- DevMode2026.ps1 (ENNE ja PÄRAST näited)
- Verify-Manifest.ps1 (ENNE ja PÄRAST näited)

### 3.2 Moderniseerimine ja Parimad Praktikad
#### PowerShelli Klassid
[Phase klass näide]

#### Docker Optimeerimine
- webide/Dockerfile (Multi-stage)
- Dockerfile.agents (Alpine + non-root)

#### Python Täiustused
- pathlib kasutamine
- pip-tools requirements.txt

### 3.3 Nested Virtualization Strategy
[Täielik docs/NESTED_VIRTUALIZATION_STRATEGY.md sisu]

## 4. Tegevuskava (Roadmap)

### Prioriteet 1 (Nädal 1-2)
1. Loo DevMode2026.psm1 moodul
2. Refaktoreeri DevMode2026.ps1
3. Lisa nested virt support Install-DevMode2026.ps1-le

### Prioriteet 2 (Nädal 3-4)
4. Optimeeri Docker pildid (multi-stage)
5. Uuenda Python agentide struktuuri (pathlib)
6. Loo New-VirtualTestLab.ps1

### Prioriteet 3 (Nädal 5-6)
7. Kirjuta integratsioonitestid nested VM-idega
8. Dokumenteeri kõik muudatused
9. CI/CD pipeline'i integratsioon

## 5. Riskid ja Leevendused

### Riskid
- Nested virt võib olla aeglane (mitigeer: RAM/CPU nõuded)
- VM piltide litsentsid (mitigeer: eval licenses)
- Keerukas troubleshooting (mitigeer: põhjalik dokumentatsioon)

## 6. Mõõdikud (Metrics)

### Enne
- Koodi duplikatsioon: X%
- Docker pildi suurus: Y MB
- Testkatvus: Z%

### Pärast (Eesmärgid)
- Koodi duplikatsioon: <5%
- Docker pildi suurus: -40%
- Testkatvus: >80%
````

---

## 🚀 Järgmised Sammud

### Kui DevMode2026 Peamine Koodibaas on Kättesaadav

1. **Klooni põhikoodibaas**:

   ```powershell
   git clone https://github.com/KASUTAJA/DevMode2026.git
   cd DevMode2026
   ```

2. **Käivita analüüs**:

   - Skaneeri `scripts/` kaust PowerShelli skriptide osas
   - Analüüsi `agents/device/` Pythoni struktuuri
   - Kontrolli `docker-compose.yml` ja Dockerfile'e
   - Loe `docs/` dokumentatsiooni

3. **Genereeri raport**:
   - Kasuta ülalpool kirjeldatud struktuuri
   - Lisa konkreetsed koodinäited
   - Paku välja täielik `DevMode2026.psm1` moodul
   - Kirjuta `docs/NESTED_VIRTUALIZATION_STRATEGY.md`

---

## 📞 Kontakt ja Küsimused

Kui on küsimusi või vajad täpsustusi:

- Milline on DevMode2026 peamise koodibaasi URL?
- Kas on olemasolevaid testimise stsenaariumid?
- Kas on konkreetseid võrguseadmeid, millega juba töötad?
- Kas on eelised või eelistused teatud tehnoloogiate osas?

---

**Staatus**: ✅ KÄSKLUS SALVESTATUD
**Järgmine Samm**: Oota DevMode2026 peamise koodibaasi URL-i

---

**Koostaja**: GitHub Copilot
**Keel**: Eesti keel (Estonian)
**Kuupäev**: 17. oktoober 2025

