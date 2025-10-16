# AI Council ISO Build System - Sample Customization Files

This directory contains **sample customization files** for Windows 11 ISO builds.

## 📁 Directory Structure

```
templates/
├── privacy-tweaks/          # Registry modifications for privacy & telemetry
│   ├── disable-telemetry.reg       ✅ Complete
│   ├── start-menu-classic.reg      ✅ Complete
│   └── README.md                   (this file)
├── debloat/                 # PowerShell scripts to remove bloatware
│   ├── Remove-Bloatware.ps1        ✅ Complete
│   └── README.md
├── updates/                 # Windows update packages (.msu)
│   └── README.md
└── drivers/                 # Hardware driver packages (.inf)
    └── README.md
```

## 🔧 Privacy Tweaks (Registry Files)

### `disable-telemetry.reg`
**Purpose**: Disables Windows 11 telemetry, tracking, and privacy-invasive features

**Tweaks Applied**:
- ✅ Telemetry & DiagTrack disabled
- ✅ Advertising ID disabled
- ✅ Activity Feed disabled
- ✅ Location tracking disabled
- ✅ Cortana disabled
- ✅ Bing search in Start Menu disabled
- ✅ Windows Tips & Suggestions disabled
- ✅ Online Speech Recognition disabled
- ✅ Delivery Optimization P2P disabled
- ✅ Wi-Fi Sense disabled
- ✅ Windows Error Reporting disabled

**Usage**:
```powershell
# Copy to workspace customization directory
Copy-Item .\disable-telemetry.reg C:\ai-council\workspace\customization\tweaks\

# Applied automatically by Apply-Customizations.ps1 Phase 3
```

### `start-menu-classic.reg`
**Purpose**: Restores classic Windows behaviors and removes UI clutter

**Tweaks Applied**:
- ✅ Taskbar left-aligned (classic style)
- ✅ Widgets disabled
- ✅ Chat icon removed
- ✅ Task View button hidden
- ✅ Recently Added Apps hidden
- ✅ Recommended section in Start Menu disabled
- ✅ File extensions shown
- ✅ Hidden files visible
- ✅ Quick Access recent files disabled
- ✅ Compact view in File Explorer
- ✅ Aero Shake disabled

**Usage**:
```powershell
# Copy to workspace customization directory
Copy-Item .\start-menu-classic.reg C:\ai-council\workspace\customization\tweaks\

# Applied automatically by Apply-Customizations.ps1 Phase 3
```

## 🗑️ Debloat Scripts (PowerShell)

### `Remove-Bloatware.ps1`
**Purpose**: Removes pre-installed apps and unnecessary components from WIM

**Components Removed**:
- **Social & Communication**: Bing apps, Mail/Calendar, Your Phone, Skype, People
- **Entertainment**: Xbox apps, Zune Music/Video, Groove Music
- **Third-Party Bloat**: Candy Crush, Disney, Netflix, Spotify, TikTok, LinkedIn
- **Microsoft Bloat**: Cortana, Office Hub, 3D Viewer, Mixed Reality Portal
- **Optional Features**: Internet Explorer, Windows Media Player, XPS Services

**Usage**:
```powershell
# Manual execution (for testing)
.\Remove-Bloatware.ps1 -MountDir "C:\ai-council\workspace\customization\mount"

# Automatic execution via Apply-Customizations.ps1
# Just specify debloat script in packet:
# inputs.customizations.debloat = "templates/debloat/Remove-Bloatware.ps1"
```

**Output**: Returns count of components removed (integrates with build manifest)

## 📋 How Customizations Are Applied

### Workflow Integration

1. **Mount WIM** - `Mount-WimImage.ps1` mounts Windows image to `customization/mount/`

2. **Apply Customizations** - `Apply-Customizations.ps1` runs 4 phases:
   - **Phase 1**: Update integration (`.msu` files from `updates/`)
   - **Phase 2**: Driver injection (`.inf` files from `drivers/`)
   - **Phase 3**: Registry tweaks (`.reg` files from `tweaks/`)
     * Loads offline registry hive: `reg load HKLM\_OFFLINE mount\Windows\System32\config\SOFTWARE`
     * Imports registry files: `reg import tweaks\*.reg`
     * Unloads hive: `reg unload HKLM\_OFFLINE`
   - **Phase 4**: Debloat script execution (`Remove-Bloatware.ps1`)

3. **Unmount WIM** - `Dismount-WimImage.ps1` commits changes

4. **Create ISO** - `New-BootableISO.ps1` generates bootable ISO

5. **Hash ISO** - `Get-ISOHash.ps1` computes SHA256 for verification

### DAO Packet Example

```json
{
  "packet_id": "iso-build-20240115-143022",
  "role": "build",
  "action": "iso_build",
  "warrant_id": "warrant-iso-001",
  "inputs": {
    "base_iso": "windows11-base/sources/install.wim",
    "mount_dir": "customization/mount",
    "output_iso": "output/Win11_Custom_Privacy.iso",
    "customizations": {
      "updates": "customization/updates",
      "drivers": "customization/drivers",
      "tweaks": "customization/tweaks",
      "debloat": "templates/debloat/Remove-Bloatware.ps1"
    },
    "test_in_vm": false
  }
}
```

## 🚀 Quick Start

### 1. Copy Templates to Workspace

```powershell
# Create customization directories
New-Item -ItemType Directory -Path "C:\ai-council\workspace\customization\tweaks" -Force
New-Item -ItemType Directory -Path "C:\ai-council\workspace\customization\updates" -Force
New-Item -ItemType Directory -Path "C:\ai-council\workspace\customization\drivers" -Force

# Copy privacy tweaks
Copy-Item "C:\ai-council\agents\build\templates\privacy-tweaks\*.reg" `
    "C:\ai-council\workspace\customization\tweaks\"

# Copy debloat script (referenced directly from templates/)
```

### 2. Add Updates (Optional)

```powershell
# Download .msu update packages from Microsoft Update Catalog
# https://www.catalog.update.microsoft.com/

# Copy to updates directory
Copy-Item "C:\Downloads\windows11.0-kb5034123-x64.msu" `
    "C:\ai-council\workspace\customization\updates\"
```

### 3. Add Drivers (Optional)

```powershell
# Extract driver packages (must be .inf format)
# Copy to drivers directory (supports subdirectories)
Copy-Item "C:\Drivers\*" `
    "C:\ai-council\workspace\customization\drivers\" -Recurse
```

### 4. Dispatch ISO Build

```powershell
# Create warrant
.\ai-council\tasks.json -> "Create: Sample Warrant (ISO Build)"

# Dispatch packet
.\ai-council\tasks.json -> "Dispatch: ISO Build Ceremony"

# Start agent
.\ai-council\tasks.json -> "ISO Build Agent: Watch Mode"
```

## 🔍 Registry Tweak Development

### Creating Custom Registry Files

1. **Export baseline state**:
   ```cmd
   reg export HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion baseline.reg
   ```

2. **Make changes via GUI** (Settings app, Group Policy Editor, etc.)

3. **Export modified state**:
   ```cmd
   reg export HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion modified.reg
   ```

4. **Diff and extract changes**:
   ```powershell
   Compare-Object (Get-Content baseline.reg) (Get-Content modified.reg)
   ```

5. **Create new .reg file** with only changed keys

6. **Test in offline WIM**:
   ```powershell
   reg load HKLM\_OFFLINE "C:\mount\Windows\System32\config\SOFTWARE"
   reg import custom-tweaks.reg
   reg unload HKLM\_OFFLINE
   ```

### Registry Path Translation

| Live System Path | Offline WIM Path |
|------------------|------------------|
| `HKEY_LOCAL_MACHINE` | `HKEY_LOCAL_MACHINE\_OFFLINE` |
| `HKEY_CURRENT_USER` | Not supported (user-specific) |
| `HKEY_USERS` | Requires loading `C:\mount\Users\Default\NTUSER.DAT` |

## 🛡️ Governance Notes

### Why Templates Are DAO-Governed

**Customizations modify sovereign infrastructure** and must be:
- ✅ **Auditable**: Every tweak documented in git + DAO ledger
- ✅ **Reproducible**: Same inputs → same outputs (hash-verified)
- ✅ **Reversible**: Discard WIM changes if build fails
- ✅ **Warrant-Authorized**: Require DAO approval for execution

### Customization Manifest Example

```json
{
  "customizations": {
    "updates_applied": 5,
    "drivers_added": 12,
    "tweaks_applied": 8,
    "components_removed": 47
  },
  "sha256": "a3f5b2c7e9d1...",
  "governance": {
    "warrant_id": "warrant-iso-001",
    "proposal_id": "proposal-custom-iso-001",
    "approved_by": ["council.civic", "council.registry", "council.audit"]
  }
}
```

## 📚 Additional Resources

- **Microsoft Docs - DISM**: https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/dism---deployment-image-servicing-and-management-technical-reference-for-windows
- **Group Policy Reference**: https://admx.help/
- **Windows Privacy Guide**: https://privacy.sexy/
- **Windows 11 Debloat**: https://github.com/Sycnex/Windows10Debloater

## ⚠️ Disclaimer

These customizations are **templates for sovereign infrastructure**. Test thoroughly before production deployment. Some tweaks may:
- Break Windows Update functionality
- Require manual intervention for certain apps
- Impact enterprise feature compatibility

Always maintain **baseline ISOs** alongside custom builds for rollback capability.

---

**Status**: ✅ Phase D Sample Files Complete  
**Next**: Phase E - End-to-End Testing
