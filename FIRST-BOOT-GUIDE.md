# First Boot Preparation Guide

## 🎯 Overview

This guide helps you:

1. **Remove Ubuntu dual-boot artifacts** (GRUB, partitions)
2. **Repair Windows bootloader** (make Windows boot directly)
3. **Reclaim disk space** from deleted Ubuntu partitions
4. **Prepare for Foundation Ceremony** (civic infrastructure setup)

---

## ⚠️ IMPORTANT WARNINGS

### This Process Will

- ❌ **PERMANENTLY DELETE** all Ubuntu partitions and data
- ❌ **REMOVE GRUB** bootloader (no more boot menu)
- ✅ **Restore Windows** as the only bootable OS
- ✅ **Reclaim disk space** for Windows use

### Before You Start

- 🔴 **Backup any data from Ubuntu** (if you haven't already)
- 🔴 **Ensure you have Windows installation media** (for emergency boot repair)
- 🔴 **Close all applications** and save your work
- 🔴 **Plug in laptop** if on battery power

---

## 🚀 Quick Start (Recommended)

### Step 1: Run First Boot Preparation Script

```powershell
# Open PowerShell as Administrator
# Press Win+X → Windows PowerShell (Admin)

# Navigate to workspace
cd "c:\Users\svenk\OneDrive\All_My_Projects\New folder"

# Run preparation script
.\scripts\setup\Prepare-FirstBoot.ps1
```

**What this does:**

- Detects boot mode (UEFI/BIOS)
- Identifies Ubuntu partitions
- Removes GRUB bootloader
- Repairs Windows boot configuration
- Cleans up disk space
- Prepares for Foundation Ceremony

**Duration:** ~5-10 minutes

---

### Step 2: Restart Computer

After the script completes:

```powershell
Restart-Computer
```

**Expected behavior:**

- Computer boots directly to Windows (no GRUB menu)
- Faster boot time
- No Ubuntu option

---

### Step 3: Extend C: Drive (Optional)

After restart, reclaim the space from deleted Ubuntu partitions:

#### Option A: Disk Management (GUI)

```
1. Press Win+X → Disk Management
2. Look for "Unallocated" space (this was Ubuntu)
3. Right-click C: drive → Extend Volume
4. Select all unallocated space
5. Click Next → Finish
```

#### Option B: PowerShell (Command Line)

```powershell
# Run as Administrator
Get-Partition -DriveLetter C | Resize-Partition -Size (Get-PartitionSupportedSize -DriveLetter C).SizeMax
```

---

### Step 4: Run Foundation Ceremony

Now your system is ready for civic infrastructure setup:

```powershell
# Navigate to workspace (if not already there)
cd "c:\Users\svenk\OneDrive\All_My_Projects\New folder"

# Run Foundation Ceremony
.\scripts\ceremonies\01-foundation\Initialize-Foundation.ps1
```

**What this does:**

- Sets up governance structure
- Establishes audit trails
- Configures civic infrastructure
- Prepares for future ceremonies

---

## 📋 Manual Cleanup (If Script Fails)

### Manual GRUB Removal (UEFI Systems)

```powershell
# 1. Mount EFI partition
mountvol Z: /S

# 2. Navigate to EFI folder
cd Z:\EFI

# 3. List bootloaders
dir

# 4. Remove Ubuntu folder
Remove-Item -Path Z:\EFI\ubuntu -Recurse -Force

# 5. Remove other Linux bootloaders if present
Remove-Item -Path Z:\EFI\grub -Recurse -Force -ErrorAction SilentlyContinue

# 6. Dismount
cd C:\
mountvol Z: /D
```

### Manual Boot Repair (Legacy BIOS)

```powershell
# Run these commands as Administrator
bootrec /fixmbr
bootrec /fixboot
bootrec /rebuildbcd
```

### Manual Partition Deletion

```powershell
# 1. Open Disk Management
diskmgmt.msc

# 2. Identify Ubuntu partitions (usually without drive letters, marked as "Unknown" or "Unallocated")

# 3. Right-click each Ubuntu partition → Delete Volume

# 4. Right-click C: drive → Extend Volume → Use freed space
```

---

## 🛠️ Advanced Options

### Preview Changes (What-If Mode)

Test the script without making changes:

```powershell
.\scripts\setup\Prepare-FirstBoot.ps1 -WhatIf
```

### Skip Specific Phases

```powershell
# Skip disk cleanup (only remove GRUB)
.\scripts\setup\Prepare-FirstBoot.ps1 -SkipDiskCleanup

# Skip boot repair (only delete partitions)
.\scripts\setup\Prepare-FirstBoot.ps1 -SkipBootRepair

# Auto-confirm all prompts
.\scripts\setup\Prepare-FirstBoot.ps1 -AutoConfirm
```

---

## 🔍 Verification Checklist

### After Running Script

- [ ] Script completed without errors
- [ ] Boot mode detected correctly (UEFI/BIOS)
- [ ] Ubuntu GRUB folder removed
- [ ] Boot configuration backed up
- [ ] Ubuntu partitions identified

### After Restart

- [ ] Windows boots directly (no GRUB menu)
- [ ] Boot time is faster
- [ ] No error messages during boot
- [ ] All Windows features work normally

### After Disk Extension

- [ ] C: drive shows increased size
- [ ] No "Unallocated" space remaining
- [ ] Disk Management shows clean layout

---

## ⚙️ What Gets Removed

### Boot-related

- ✅ GRUB bootloader (Z:\EFI\ubuntu)
- ✅ GRUB configuration files
- ✅ Ubuntu boot entries in BCD/UEFI
- ✅ Other Linux bootloaders (Fedora, Debian, etc.)

### Disk-related

- ✅ Ubuntu system partition (root `/`)
- ✅ Ubuntu swap partition
- ✅ Ubuntu home partition (if separate)
- ✅ Extended/Logical partitions used by Linux

### What Stays Intact

- ✅ Windows partition (C:)
- ✅ EFI System Partition
- ✅ Windows Recovery partition
- ✅ Any data drives (D:, E:, etc.)
- ✅ All Windows programs and data

---

## 🚨 Troubleshooting

### Problem: Windows Won't Boot After Cleanup

**Symptoms:**

- Black screen with error message
- "No bootable device"
- "Operating system not found"

**Solution:**

1. **Boot from Windows installation media:**
   - Insert USB/DVD with Windows 11
   - Restart and select boot device (F12/F11/Esc)
   - Choose "Repair your computer"

2. **Run Startup Repair:**

   ```
   Troubleshoot → Advanced Options → Startup Repair
   ```

3. **Manual Boot Repair (if Startup Repair fails):**

   ```
   Troubleshoot → Advanced Options → Command Prompt

   bootrec /fixmbr
   bootrec /fixboot
   bootrec /rebuildbcd

   exit
   ```

4. **Restart and remove installation media**

---

### Problem: Script Reports Errors

**Common issues:**

1. **"Access Denied"**
   - Solution: Run PowerShell as Administrator
   - Right-click PowerShell → Run as Administrator

2. **"Execution Policy Restricted"**
   - Solution:

     ```powershell
     Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
     ```

3. **"Cannot find EFI partition"**
   - This is normal on Legacy BIOS systems
   - Use Legacy BIOS boot repair methods instead

4. **"Cannot remove partition: In use"**
   - Restart computer and try again
   - Some partitions may be mounted by Windows

---

### Problem: Disk Management Can't Extend C: Drive

**Possible causes:**

1. **Recovery partition between C: and unallocated space**
   - Solution: Use third-party tool like MiniTool Partition Wizard
   - Or: Keep unallocated space as separate data drive

2. **Drive is MBR and already has 4 primary partitions**
   - Solution: Convert to GPT (requires data backup)
   - Or: Create extended partition for data

3. **Unallocated space is on different physical disk**
   - Check Disk Management carefully
   - Can only extend into adjacent unallocated space

---

## 📊 Expected Results

### Disk Space Recovery

Small SSD example (256 GB):

**Before:**

```
Disk 0:
├── EFI System Partition:    500 MB
├── Windows (C:):            180 GB
├── Recovery:                  1 GB
├── Ubuntu root:              30 GB  ← Will be removed
└── Ubuntu swap:               4 GB  ← Will be removed
```

**After:**

```
Disk 0:
├── EFI System Partition:    500 MB
├── Windows (C:):            214 GB  ← Extended!
└── Recovery:                  1 GB
```

**Reclaimed:** ~34 GB for Windows!

---

## 📚 Additional Resources

### Official Documentation

- **Boot Repair:** <https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/bcdedit-command-line-options>
- **Disk Management:** <https://docs.microsoft.com/en-us/windows-server/storage/disk-management/overview-of-disk-management>
- **UEFI/BIOS:** <https://docs.microsoft.com/en-us/windows-hardware/drivers/bringup/uefi-in-windows>

### Tools Referenced

- `bcdedit` - Boot Configuration Data editor
- `bootrec` - Boot recovery tool (requires Windows installation media)
- `diskpart` - Disk partitioning utility
- `mountvol` - EFI partition mounting

### Next Ceremony

After first boot preparation:

- **Foundation Ceremony:** `docs\ceremonies\01-foundation.md`
- **Quick Start Guide:** `QUICK-START.md`
- **Implementation Guide:** `IMPLEMENTATION_QUICKSTART.md`

---

## ✅ Success Criteria

You're ready to proceed when:

1. ✅ Windows boots directly without GRUB menu
2. ✅ C: drive shows increased available space
3. ✅ No errors in Event Viewer related to boot
4. ✅ Disk Management shows clean partition layout
5. ✅ PowerShell execution policy allows scripts
6. ✅ System runs smoothly with good performance

---

## 🎯 Summary

| Phase | Action | Duration | Risk |
|-------|--------|----------|------|
| 1 | System Assessment | 1 min | Low |
| 2 | Remove GRUB | 2 min | Medium |
| 3 | Delete Ubuntu Partitions | 2 min | High ⚠️ |
| 4 | System Optimization | 3 min | Low |
| 5 | Prepare Foundation | 1 min | Low |
| **Total** | **First Boot Prep** | **~10 min** | **Medium** |

**Post-Restart:**

| Phase | Action | Duration | Risk |
|-------|--------|----------|------|
| 6 | Verify Boot | 2 min | Low |
| 7 | Extend C: Drive | 2 min | Low |
| 8 | Foundation Ceremony | 5 min | Low |
| **Total** | **Complete Setup** | **~10 min** | **Low** |

---

**Ready to begin?** Run the preparation script:

```powershell
cd "c:\Users\svenk\OneDrive\All_My_Projects\New folder"
.\scripts\setup\Prepare-FirstBoot.ps1
```

---

*Last Updated: 2025-10-15*
*Part of Windows 11 Pro Civic Infrastructure Project*
