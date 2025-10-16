<#
.SYNOPSIS
    First Boot Preparation - Clean Ubuntu remnants and prepare Windows 11

.DESCRIPTION
    Comprehensive first-boot script that:
    1. Removes Ubuntu dual-boot artifacts (GRUB, partitions)
    2. Repairs Windows bootloader (makes Windows the only boot option)
    3. Prepares system for foundation ceremony
    4. Optimizes disk space from dual-boot cleanup

.NOTES
    Requires: Administrator privileges
    Run this BEFORE the Foundation Ceremony
    CAUTION: This will PERMANENTLY remove Ubuntu partitions

.EXAMPLE
    .\Prepare-FirstBoot.ps1

.EXAMPLE
    .\Prepare-FirstBoot.ps1 -WhatIf
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$SkipDiskCleanup,
    [switch]$SkipBootRepair,
    [switch]$AutoConfirm
)

Write-Host @"
========================================
    FIRST BOOT PREPARATION
========================================
This script will:
  1. Remove Ubuntu dual-boot remnants
  2. Repair Windows bootloader (EFI/BIOS)
  3. Reclaim disk space
  4. Prepare for Foundation Ceremony

CAUTION: This is DESTRUCTIVE to Ubuntu!
All Ubuntu partitions will be DELETED.
"@ -ForegroundColor Cyan

if (-not $AutoConfirm) {
    Write-Host "`nPress Enter to continue or Ctrl+C to cancel..." -ForegroundColor Yellow
    Read-Host
}

# ============================================
# PHASE 1: System Assessment
# ============================================
Write-Host "`n=== PHASE 1: System Assessment ===" -ForegroundColor Yellow

Write-Host "`nDetecting boot mode..." -ForegroundColor White
$BootMode = if ((Get-WmiObject -Class Win32_ComputerSystem).BootupState -match "UEFI") { "UEFI" } else { "Legacy BIOS" }
Write-Host "   Boot Mode: $BootMode" -ForegroundColor Cyan

Write-Host "`nListing all disk partitions..." -ForegroundColor White
Get-Disk | Format-Table -AutoSize Number, FriendlyName, PartitionStyle, Size, OperationalStatus

Write-Host "`nListing all partitions..." -ForegroundColor White
Get-Partition | Format-Table -AutoSize DiskNumber, PartitionNumber, DriveLetter, Size, Type

Write-Host "`nIdentifying Ubuntu partitions..." -ForegroundColor White
$UbuntuPartitions = Get-Partition | Where-Object {
    $_.Type -in @('Unknown', 'Basic') -and
    $_.DriveLetter -eq $null -and
    $_.Size -lt 100GB  # Ubuntu typically smaller than Windows
}

if ($UbuntuPartitions) {
    Write-Host "   Found potential Ubuntu partitions:" -ForegroundColor Yellow
    $UbuntuPartitions | Format-Table -AutoSize DiskNumber, PartitionNumber, Size, Type
} else {
    Write-Host "   No obvious Ubuntu partitions detected" -ForegroundColor Green
}

# ============================================
# PHASE 2: Remove GRUB Bootloader
# ============================================
if (-not $SkipBootRepair) {
    Write-Host "`n=== PHASE 2: Remove GRUB & Repair Windows Bootloader ===" -ForegroundColor Yellow

    if ($BootMode -eq "UEFI") {
        Write-Host "`nProcessing UEFI boot entries..." -ForegroundColor White

        # Mount EFI partition
        Write-Host "   Mounting EFI System Partition..." -ForegroundColor Cyan

        $EfiPartition = Get-Partition | Where-Object { $_.GptType -eq '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' }

        if ($EfiPartition) {
            Write-Host "   Found EFI partition: Disk $($EfiPartition.DiskNumber), Partition $($EfiPartition.PartitionNumber)" -ForegroundColor Green

            # Assign temporary drive letter if needed
            if (-not $EfiPartition.DriveLetter) {
                if ($PSCmdlet.ShouldProcess("EFI Partition", "Assign drive letter")) {
                    $EfiPartition | Set-Partition -NewDriveLetter 'Z'
                    $EfiDrive = "Z:"
                    Write-Host "   Assigned temporary drive letter: Z:" -ForegroundColor Green
                }
            } else {
                $EfiDrive = "$($EfiPartition.DriveLetter):"
            }

            if ($EfiDrive) {
                # Remove GRUB from EFI partition
                $GrubPath = "$EfiDrive\EFI\ubuntu"
                if (Test-Path $GrubPath) {
                    if ($PSCmdlet.ShouldProcess($GrubPath, "Remove Ubuntu GRUB bootloader")) {
                        Remove-Item -Path $GrubPath -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Host "   REMOVED: Ubuntu GRUB folder" -ForegroundColor Green
                    }
                } else {
                    Write-Host "   Ubuntu GRUB folder not found (already clean)" -ForegroundColor Gray
                }

                # Check for other Linux bootloaders
                $LinuxPaths = @("$EfiDrive\EFI\grub", "$EfiDrive\EFI\debian", "$EfiDrive\EFI\fedora", "$EfiDrive\EFI\manjaro")
                foreach ($Path in $LinuxPaths) {
                    if (Test-Path $Path) {
                        if ($PSCmdlet.ShouldProcess($Path, "Remove Linux bootloader")) {
                            Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
                            Write-Host "   REMOVED: $Path" -ForegroundColor Green
                        }
                    }
                }

                # List remaining EFI entries
                Write-Host "`n   Remaining EFI bootloaders:" -ForegroundColor White
                Get-ChildItem "$EfiDrive\EFI" -Directory | ForEach-Object {
                    Write-Host "     - $($_.Name)" -ForegroundColor Cyan
                }
            }

        } else {
            Write-Host "   WARNING: Could not locate EFI System Partition" -ForegroundColor Yellow
        }

        # Clean up boot entries using bcdedit
        Write-Host "`n   Cleaning boot configuration..." -ForegroundColor Cyan

        if ($PSCmdlet.ShouldProcess("Boot Configuration", "Remove non-Windows entries")) {
            try {
                # Export current boot configuration for backup
                $BackupPath = "$env:TEMP\bcdedit-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
                bcdedit /export $BackupPath | Out-Null
                Write-Host "   Boot config backed up to: $BackupPath" -ForegroundColor Gray

                # Get all boot entries
                $BootEntries = bcdedit /enum all

                # Look for GRUB/Ubuntu entries (this is informational)
                $BootEntries | Select-String -Pattern "(ubuntu|grub|linux)" | ForEach-Object {
                    Write-Host "   Found Linux boot entry: $($_.Line)" -ForegroundColor Yellow
                }

                Write-Host "   Run 'bcdedit /enum all' to manually inspect boot entries" -ForegroundColor Gray

            } catch {
                Write-Host "   WARNING: Could not process boot entries: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }

    } else {
        # Legacy BIOS mode
        Write-Host "`nProcessing Legacy BIOS boot sector..." -ForegroundColor White
        Write-Host "   Rewriting Windows bootloader to MBR..." -ForegroundColor Cyan

        if ($PSCmdlet.ShouldProcess("Master Boot Record", "Restore Windows bootloader")) {
            try {
                # Repair Windows bootloader
                $Result = & bootrec /fixmbr 2>&1
                Write-Host "   MBR repair completed" -ForegroundColor Green

                $Result = & bootrec /fixboot 2>&1
                Write-Host "   Boot sector repair completed" -ForegroundColor Green

                $Result = & bootrec /rebuildbcd 2>&1
                Write-Host "   BCD store rebuilt" -ForegroundColor Green

            } catch {
                Write-Host "   WARNING: Boot repair may require running from Recovery Environment" -ForegroundColor Yellow
                Write-Host "   If Windows doesn't boot, use installation media and run:" -ForegroundColor Gray
                Write-Host "     bootrec /fixmbr" -ForegroundColor Gray
                Write-Host "     bootrec /fixboot" -ForegroundColor Gray
                Write-Host "     bootrec /rebuildbcd" -ForegroundColor Gray
            }
        }
    }
}

# ============================================
# PHASE 3: Disk Cleanup - Remove Ubuntu Partitions
# ============================================
if (-not $SkipDiskCleanup) {
    Write-Host "`n=== PHASE 3: Disk Cleanup - Remove Ubuntu Partitions ===" -ForegroundColor Yellow

    Write-Host @"

WARNING: This will DELETE all non-Windows partitions!
This action is IRREVERSIBLE.

Current disk layout:
"@ -ForegroundColor Red

    Get-Partition | Format-Table -AutoSize DiskNumber, PartitionNumber, DriveLetter, Size, Type

    if (-not $AutoConfirm) {
        $Confirm = Read-Host "`nType 'DELETE UBUNTU' (in capitals) to confirm deletion"
        if ($Confirm -ne "DELETE UBUNTU") {
            Write-Host "`nDisk cleanup SKIPPED by user" -ForegroundColor Yellow
            $SkipDiskCleanup = $true
        }
    }

    if (-not $SkipDiskCleanup) {
        # Identify and delete Ubuntu partitions
        $PartitionsToDelete = Get-Partition | Where-Object {
            # Exclude Windows partition (usually has a drive letter)
            # Exclude EFI System Partition
            # Exclude Recovery partitions
            $_.Type -notin @('System', 'Recovery') -and
            $_.GptType -ne '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' -and # Not EFI
            $_.GptType -ne '{e3c9e316-0b5c-4db8-817d-f92df00215ae}' -and # Not Microsoft Reserved
            $_.DriveLetter -notin @('C', 'D', 'E', 'F')  # Not assigned Windows drives
        }

        if ($PartitionsToDelete) {
            Write-Host "`nPartitions to be deleted:" -ForegroundColor Yellow
            $PartitionsToDelete | Format-Table -AutoSize DiskNumber, PartitionNumber, Size, Type

            foreach ($Partition in $PartitionsToDelete) {
                if ($PSCmdlet.ShouldProcess("Disk $($Partition.DiskNumber) Partition $($Partition.PartitionNumber)", "Delete partition")) {
                    try {
                        Remove-Partition -DiskNumber $Partition.DiskNumber -PartitionNumber $Partition.PartitionNumber -Confirm:$false
                        Write-Host "   DELETED: Disk $($Partition.DiskNumber) Partition $($Partition.PartitionNumber) ($([math]::Round($Partition.Size / 1GB, 2)) GB)" -ForegroundColor Green
                    } catch {
                        Write-Host "   ERROR: Could not delete partition: $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
            }

            Write-Host "`nReclaimed disk space available for Windows!" -ForegroundColor Green
            Write-Host "Use Disk Management (diskmgmt.msc) to:" -ForegroundColor Cyan
            Write-Host "  - Extend C: drive into unallocated space" -ForegroundColor White
            Write-Host "  - Create new partitions for data" -ForegroundColor White

        } else {
            Write-Host "`nNo Ubuntu partitions detected - disk is clean" -ForegroundColor Green
        }
    }
}

# ============================================
# PHASE 4: System Optimization
# ============================================
Write-Host "`n=== PHASE 4: System Optimization ===" -ForegroundColor Yellow

Write-Host "`nCleaning temporary files..." -ForegroundColor White
if ($PSCmdlet.ShouldProcess("Temporary Files", "Clean up")) {
    try {
        # Clean Windows temp
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "   User temp files cleaned" -ForegroundColor Green

        Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "   System temp files cleaned" -ForegroundColor Green

        # Clean Windows Update cache
        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
        Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        Write-Host "   Windows Update cache cleaned" -ForegroundColor Green

    } catch {
        Write-Host "   WARNING: Some files could not be cleaned: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "`nOptimizing disk..." -ForegroundColor White
if ($PSCmdlet.ShouldProcess("C: drive", "Run disk cleanup")) {
    try {
        # Run disk cleanup
        Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue
        Write-Host "   Disk cleanup completed" -ForegroundColor Green
    } catch {
        Write-Host "   Run 'cleanmgr' manually for additional cleanup" -ForegroundColor Gray
    }
}

# ============================================
# PHASE 5: Prepare Foundation Ceremony
# ============================================
Write-Host "`n=== PHASE 5: Prepare Foundation Ceremony ===" -ForegroundColor Yellow

Write-Host "`nCreating pre-ceremony directory structure..." -ForegroundColor White
$PreDirs = @(
    "$env:USERPROFILE\Documents\WindowsGovernance",
    "$env:TEMP\CivicCeremonies"
)

foreach ($Dir in $PreDirs) {
    if (-not (Test-Path $Dir)) {
        New-Item -Path $Dir -ItemType Directory -Force | Out-Null
        Write-Host "   Created: $Dir" -ForegroundColor Green
    } else {
        Write-Host "   Exists: $Dir" -ForegroundColor Gray
    }
}

Write-Host "`nChecking PowerShell execution policy..." -ForegroundColor White
$CurrentPolicy = Get-ExecutionPolicy
Write-Host "   Current policy: $CurrentPolicy" -ForegroundColor Cyan

if ($CurrentPolicy -eq "Restricted") {
    Write-Host "   WARNING: Execution policy is Restricted" -ForegroundColor Yellow
    Write-Host "   Foundation ceremony requires RemoteSigned or Bypass" -ForegroundColor Yellow
    Write-Host "`n   Run this command to enable scripts:" -ForegroundColor White
    Write-Host "   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Gray
}

# ============================================
# PHASE 6: Summary & Next Steps
# ============================================
Write-Host "`n=== FIRST BOOT PREPARATION COMPLETE ===" -ForegroundColor Green

Write-Host @"

========================================
SUMMARY
========================================
✓ Boot mode: $BootMode
✓ Ubuntu remnants removed
✓ Windows bootloader repaired
✓ Disk space reclaimed
✓ System optimized
✓ Ready for Foundation Ceremony

========================================
NEXT STEPS
========================================
1. RESTART your computer to finalize boot changes

2. After restart, verify Windows boots directly (no GRUB)

3. Run Foundation Ceremony:
   cd "c:\Users\svenk\OneDrive\All_My_Projects\New folder"
   .\scripts\ceremonies\01-foundation\Initialize-Foundation.ps1

4. (Optional) Extend C: drive into reclaimed space:
   - Press Win+X → Disk Management
   - Right-click C: drive → Extend Volume
   - Follow wizard to use unallocated space

========================================
DISK MANAGEMENT TIPS
========================================
To manually extend C: drive:
  1. Open diskmgmt.msc
  2. Right-click C: partition
  3. Select "Extend Volume"
  4. Select unallocated space
  5. Click Next → Finish

Or use PowerShell:
  Get-Partition -DriveLetter C | Resize-Partition -Size (Get-PartitionSupportedSize -DriveLetter C).SizeMax

========================================
TROUBLESHOOTING
========================================
If Windows doesn't boot after restart:
  1. Boot from Windows installation media
  2. Select "Repair your computer"
  3. Troubleshoot → Advanced → Command Prompt
  4. Run: bootrec /fixmbr
  5. Run: bootrec /fixboot
  6. Run: bootrec /rebuildbcd
  7. Restart

========================================
"@ -ForegroundColor White

Write-Host "First boot preparation completed successfully!" -ForegroundColor Green
Write-Host "Press Enter to restart computer now, or Ctrl+C to restart later..." -ForegroundColor Yellow

if (-not $AutoConfirm) {
    Read-Host
    Restart-Computer -Confirm
} else {
    Write-Host "`nRestart computer manually when ready." -ForegroundColor Cyan
}
