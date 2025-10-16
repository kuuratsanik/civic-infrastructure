# Windows 11 Custom ISO Upgrade Guide

## Overview

This guide shows you how to upgrade your Windows 11 system using a custom ISO built with AI-powered optimization.

---

## 🎯 Upgrade Methods

### Method 1: In-Place Upgrade (Recommended)

**Keeps your files, apps, and settings**

- No data loss
- Fastest upgrade path
- Preserves installed applications
- Maintains user profiles

### Method 2: Clean Install

**Fresh start with custom configuration**

- Maximum customization control
- Best performance
- Requires backup and reinstall apps
- Recommended for major changes

---

## 📋 Prerequisites

### 1. Check System Requirements

```powershell
# Run this to verify your system is ready
.\scripts\utilities\Test-SystemRequirements.ps1
```

**Minimum Requirements:**

- 64-bit processor (1 GHz, 2+ cores)
- 4 GB RAM (8 GB recommended)
- 64 GB storage (128 GB recommended)
- UEFI firmware with Secure Boot
- TPM 2.0

### 2. Backup Your Data

```powershell
# Create system backup
wbAdmin start backup -backupTarget:E: -include:C: -allCritical -quiet

# Or use Windows Settings → Update & Security → Backup
```

**What to Backup:**

- Personal files (Documents, Pictures, Desktop)
- Application data and settings
- Browser bookmarks and passwords
- Custom configurations
- License keys

### 3. Download Base Windows 11 ISO

**Official Sources:**

- [Microsoft Download Page](https://www.microsoft.com/software-download/windows11)
- Windows Media Creation Tool
- Your MSDN/VLSC subscription

**Recommended:**

- Windows 11 Pro/Enterprise (better customization)
- Latest version (currently 25H2)
- Match your language (Estonian if preferred)

---

## 🔨 Step 1: Build Custom ISO with AI

### Option A: AI-Optimized Build (Recommended)

```powershell
# AI analyzes and builds optimized ISO
.\agents\build\iso-build-ai-agent.ps1 `
    -BaseISOPath "C:\Users\svenk\Downloads\Win11_25H2_Estonian_x64.iso" `
    -Requirements "privacy,performance,minimal" `
    -OutputPath "C:\CustomISO\Win11_Custom.iso"
```

**AI will:**

- ✅ Analyze base ISO structure
- ✅ Remove bloatware (Cortana, OneDrive, Edge telemetry)
- ✅ Inject privacy tweaks
- ✅ Optimize for performance
- ✅ Generate custom autounattend.xml
- ✅ Create governance audit trail

### Option B: Manual Build with Ceremony

```powershell
# Traditional ceremonial build
.\scripts\ceremonies\09-iso-build\Build-CustomISO.ps1 `
    -SourceISO "C:\Users\svenk\Downloads\Win11_25H2_Estonian_x64.iso" `
    -OutputISO "C:\CustomISO\Win11_Custom.iso" `
    -RemoveBloat `
    -ApplyPrivacyTweaks `
    -CreateWarrant
```

### Build Process (~15-30 minutes)

1. **Extraction** (5 min)
   - Mounts base ISO
   - Extracts to workspace/windows11-base/

2. **AI Analysis** (2-3 min)
   - Identifies installed apps
   - Recommends removals
   - Generates optimization plan

3. **Customization** (10 min)
   - Removes bloatware packages
   - Injects registry tweaks
   - Adds custom scripts
   - Creates autounattend.xml

4. **Packaging** (5-10 min)
   - Creates bootable ISO
   - Generates SHA256 hash
   - Creates audit evidence

**Output:**

```
C:\CustomISO\
├── Win11_Custom.iso (4.5 GB)
├── Win11_Custom.iso.sha256
├── customization-manifest.json
└── build-evidence.json
```

---

## 🚀 Step 2: Prepare Installation Media

### Option A: Mount ISO (In-Place Upgrade)

**Windows Explorer Method:**

1. Right-click `Win11_Custom.iso`
2. Select "Mount"
3. ISO appears as DVD drive (e.g., D:)
4. Ready to run setup.exe

**PowerShell Method:**

```powershell
# Mount the custom ISO
$isoPath = "C:\CustomISO\Win11_Custom.iso"
$mount = Mount-DiskImage -ImagePath $isoPath -PassThru
$driveLetter = ($mount | Get-Volume).DriveLetter

Write-Host "ISO mounted at ${driveLetter}:\"
Write-Host "Run: ${driveLetter}:\setup.exe"
```

### Option B: Create Bootable USB (Clean Install)

**Requirements:**

- USB drive (16 GB minimum)
- Rufus or Windows Media Creation Tool

**Using Rufus (Recommended):**

1. Download [Rufus](https://rufus.ie/)
2. Insert USB drive
3. Select your USB device
4. Boot selection: SELECT → Choose `Win11_Custom.iso`
5. Partition scheme: GPT
6. Target system: UEFI
7. Click START
8. Wait 5-10 minutes

**Using PowerShell:**

```powershell
# Create bootable USB (requires admin)
.\scripts\utilities\Create-BootableUSB.ps1 `
    -ISOPath "C:\CustomISO\Win11_Custom.iso" `
    -USBDrive "E:"
```

---

## 💻 Step 3: Upgrade Windows

### Method 1: In-Place Upgrade (Keep Everything)

**From Mounted ISO:**

1. **Open setup.exe**

   ```powershell
   # If mounted to D: drive
   D:\setup.exe
   ```

2. **Windows Setup Wizard:**
   - Click "Next"
   - Accept license terms
   - Choose: **"Keep personal files and apps"**
   - Click "Install"

3. **Installation Process (60-90 min):**
   - Copying files (20%)
   - Installing features (40%)
   - Installing updates (30%)
   - Finishing up (10%)
   - Multiple restarts (automatic)

4. **Post-Install:**
   - Completes setup
   - Restores your files and apps
   - Applies customizations
   - First login

**Advanced Options:**

```powershell
# Upgrade with specific options
D:\setup.exe /Auto Upgrade /DynamicUpdate Disable /Telemetry Disable
```

### Method 2: Clean Install (Fresh Start)

**From Bootable USB:**

1. **Boot from USB:**
   - Restart computer
   - Press Boot Menu key (F12, F11, Esc, or Del)
   - Select USB drive
   - UEFI boot mode

2. **Windows Setup:**
   - Language/Region settings
   - Click "Install now"
   - Enter product key (or skip)
   - Choose Windows edition
   - Accept license
   - Select: **"Custom: Install Windows only"**

3. **Partition Setup:**

   ```
   WARNING: This erases your C: drive!
   ```

   - Select drive
   - Delete existing partitions (if clean install)
   - Create new partition
   - Click "Next"

4. **Installation (45-60 min):**
   - Copying files
   - Installing features
   - Installing updates
   - Multiple restarts

5. **OOBE Setup:**
   - Region/Keyboard
   - Network setup
   - **SKIP Microsoft account** (use local account)
   - Privacy settings (decline all)
   - Desktop appears

---

## ✅ Step 4: Post-Upgrade Validation

### Verify Customizations Applied

```powershell
# Check if bloatware removed
Get-AppxPackage | Select-Object Name, PackageFullName

# Should NOT see:
# - Microsoft.549981C3F5F10 (Cortana)
# - Microsoft.BingWeather
# - Microsoft.GetHelp
# - Microsoft.Getstarted
# - Microsoft.MicrosoftOfficeHub
# - Microsoft.MicrosoftSolitaireCollection
```

### Run Foundation Ceremony

```powershell
# Establish civic governance on fresh system
.\scripts\ceremonies\01-foundation\Initialize-Foundation.ps1

# This creates:
# - DAO council structure
# - Audit trail system
# - Policy framework
# - Evidence tracking
```

### Apply Additional Ceremonies

```powershell
# Developer environment
.\scripts\ceremonies\05-developer-cockpit\Setup-DeveloperEnvironment.ps1

# Privacy hardening
.\scripts\ceremonies\02-privacy\Apply-PrivacyTweaks.ps1

# Performance optimization
.\scripts\ceremonies\03-performance\Optimize-System.ps1
```

### Verify System Health

```powershell
# Run comprehensive validation
.\tests\Invoke-ValidationTests.ps1 -Detailed

# Checks:
# ✓ Windows activation
# ✓ Driver status
# ✓ Windows Update
# ✓ Security settings
# ✓ Customizations applied
# ✓ DAO governance
# ✓ Audit trail
```

---

## 🎛️ Advanced: Autounattend.xml

Your custom ISO includes an **autounattend.xml** file for unattended installation.

**Features:**

- Skips OOBE (Out of Box Experience)
- Creates local admin account
- Disables telemetry
- Removes bloatware automatically
- Applies privacy settings
- Joins domain (optional)

**Location in ISO:**

```
Win11_Custom.iso
└── sources\
    └── $OEM$\
        └── $$\Setup\Scripts\
            └── autounattend.xml
```

**Customize Before Build:**

```powershell
# Edit autounattend template
code .\configs\templates\autounattend.xml

# Rebuild ISO with custom settings
.\agents\build\iso-build-ai-agent.ps1 -UseCustomAutounattend
```

---

## 🔧 Troubleshooting

### Issue: "This PC can't run Windows 11"

**Cause:** TPM/Secure Boot not enabled

**Solution:**

```powershell
# Check TPM status
Get-Tpm

# If TPM not found, enable in BIOS/UEFI:
# 1. Restart → Enter BIOS (F2/Del/F12)
# 2. Security → TPM Device → Enable
# 3. Boot → Secure Boot → Enable
# 4. Save and exit
```

**Bypass Check (NOT RECOMMENDED):**

```powershell
# Add registry bypass to autounattend.xml
# Allows install on unsupported hardware
```

### Issue: "Windows cannot install required files"

**Cause:** Corrupted ISO or USB

**Solution:**

```powershell
# Verify ISO integrity
$hash = Get-FileHash "C:\CustomISO\Win11_Custom.iso" -Algorithm SHA256
$expectedHash = Get-Content "C:\CustomISO\Win11_Custom.iso.sha256"

if ($hash.Hash -eq $expectedHash) {
    Write-Host "✓ ISO is valid"
} else {
    Write-Host "✗ ISO corrupted - rebuild required"
}

# Rebuild ISO
.\scripts\ceremonies\09-iso-build\Build-CustomISO.ps1
```

### Issue: Product Key Not Working

**Solution:**

```powershell
# Activate Windows manually
slmgr /ipk YOUR-PRODUCT-KEY-HERE
slmgr /ato

# Or use digital license
# Settings → Update & Security → Activation → Troubleshoot
```

### Issue: Apps Missing After Upgrade

**Cause:** In-place upgrade removed incompatible apps

**Solution:**

```powershell
# Check what was removed
Get-Content "C:\Windows\Panther\setupact.log" | Select-String "removed"

# Reinstall from backup or download fresh
```

---

## 📊 Upgrade Comparison

| Feature | In-Place Upgrade | Clean Install |
|---------|------------------|---------------|
| **Duration** | 60-90 min | 45-60 min + setup time |
| **Data Loss** | ❌ None | ⚠️ Erases C: drive |
| **Apps Kept** | ✅ Yes | ❌ Must reinstall |
| **Settings Kept** | ✅ Yes | ❌ Reset to defaults |
| **Best For** | Quick updates | Major changes |
| **Bloatware Removal** | ⚠️ Limited | ✅ Complete |
| **Performance** | 🔶 Good | ✅ Excellent |

---

## 🎯 Recommended Workflow

### For Most Users: In-Place Upgrade

```powershell
# 1. Build custom ISO
.\agents\build\iso-build-ai-agent.ps1 -BaseISOPath "Downloads\Win11.iso" -Requirements "privacy,minimal"

# 2. Mount and run setup
Mount-DiskImage -ImagePath "C:\CustomISO\Win11_Custom.iso"
D:\setup.exe  # Keep files and apps

# 3. Post-upgrade cleanup
.\scripts\ceremonies\01-foundation\Initialize-Foundation.ps1
```

### For Advanced Users: Clean Install

```powershell
# 1. Backup everything
.\scripts\utilities\Backup-System.ps1

# 2. Build custom ISO with autounattend
.\agents\build\iso-build-ai-agent.ps1 -FullCustomization

# 3. Create bootable USB
.\scripts\utilities\Create-BootableUSB.ps1

# 4. Boot from USB and install

# 5. Restore data and run ceremonies
.\scripts\ceremonies\01-foundation\Initialize-Foundation.ps1
```

---

## 📚 Additional Resources

### Documentation

- `QUICK-START.md` - Quick reference guide
- `AI-DEPLOYMENT-COMPLETE.md` - AI system overview
- `docs/ceremonies/01-foundation.md` - Foundation ceremony details

### Scripts

- `Build-CustomISO.ps1` - ISO builder
- `Initialize-Foundation.ps1` - Post-install setup
- `Invoke-ValidationTests.ps1` - System verification

### Keyboard Shortcuts

- **Ctrl+Shift+I** - Analyze ISO with AI
- **Ctrl+Alt+C** - Run ceremony
- **Ctrl+Shift+T** - Test AI system

---

## ⚠️ Important Notes

1. **Always backup before upgrading**
2. **Verify ISO hash before installation**
3. **Check hardware compatibility**
4. **Keep Windows product key handy**
5. **Disable antivirus during upgrade**
6. **Ensure stable power supply (laptop: plug in)**
7. **Minimum 20 GB free space required**
8. **Close all applications before starting**

---

## 🆘 Need Help?

```powershell
# Test AI system
ollama run qwen2.5-coder:1.5b "Help me troubleshoot Windows upgrade"

# Check system logs
.\scripts\utilities\Get-SystemLogs.ps1

# Run diagnostics
.\tests\Invoke-ValidationTests.ps1 -Detailed -Verbose
```

**AI Agents Available:**

- Master Orchestrator (task coordination)
- ISO Build Agent (customization help)
- Civic Agent (governance validation)

**Your AI swarm can help with upgrade planning and troubleshooting!**

---

*Last Updated: October 15, 2025*
*System Status: AI Agents Deployed ✅*
