# Common Issues and Solutions

This document provides troubleshooting guidance for common issues encountered during Windows 11 Pro civic infrastructure ceremonies.

## PowerShell Execution Policy Issues

### Problem
```
.\Initialize-Foundation.ps1 : File cannot be loaded because running scripts is disabled on this system.
```

### Solution
Run PowerShell as Administrator and execute:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Or run the script with bypass policy:
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Initialize-Foundation.ps1
```

## Permission Issues

### Problem
```
Access denied when creating governance directories
```

### Solution
1. Run PowerShell as Administrator
2. Ensure user has write permissions to Documents folder
3. Check if antivirus is blocking file creation

## BitLocker Issues

### Problem
```
Get-BitLockerVolume : The term 'Get-BitLockerVolume' is not recognized
```

### Solution
This indicates BitLocker PowerShell cmdlets are not available:
1. Run the ceremony with `-SkipBitLocker` parameter
2. Or enable BitLocker management tools:
   ```powershell
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-BitLocker-Recovery-Tools
   ```

## WSL2 Installation Issues

### Problem
```
wsl --install fails with error code
```

### Solution
1. Ensure Windows Subsystem for Linux is enabled:
   ```powershell
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
   ```
2. Enable Virtual Machine Platform:
   ```powershell
   Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
   ```
3. Restart computer and try again

## Winget Issues

### Problem
```
winget : The term 'winget' is not recognized
```

### Solution
1. Install App Installer from Microsoft Store
2. Or download from GitHub: https://github.com/microsoft/winget-cli/releases
3. Run ceremony with development tools already installed

## VS Code Extension Installation Fails

### Problem
```
code --install-extension fails with network error
```

### Solution
1. Check internet connectivity
2. Run VS Code and install extensions manually
3. Configure proxy settings if behind corporate firewall:
   ```bash
   code --proxy-server=http://proxy:port
   ```

## Configuration Integrity Failures

### Problem
```
Configuration integrity FAILED - hash mismatch
```

### Solution
1. Check if configuration file was manually modified
2. Re-run the ceremony to regenerate configuration
3. Restore from backup if available:
   ```powershell
   Copy-Item "$env:USERPROFILE\Documents\WindowsGovernance\Backups\*.json" "$env:USERPROFILE\Documents\WindowsGovernance\Configurations\"
   ```

## Ceremony Hangs or Freezes

### Problem
Ceremony script appears to hang during execution

### Solution
1. Check Task Manager for PowerShell processes
2. Look for user input prompts that may be hidden
3. Cancel with Ctrl+C and re-run with `-WhatIf` to preview actions
4. Run ceremony in phases by commenting out sections

## Docker Desktop Issues

### Problem
```
Docker Desktop installation fails or won't start
```

### Solution
1. Ensure WSL2 is properly installed
2. Enable Hyper-V if available:
   ```powershell
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
   ```
3. Check system requirements (virtualization enabled in BIOS)
4. Run Docker Desktop as Administrator

## Network Connectivity Issues

### Problem
Package installations fail due to network issues

### Solution
1. Check internet connectivity
2. Configure Windows firewall exceptions
3. If behind corporate proxy, configure system proxy settings
4. Try running ceremonies during off-peak hours

## Disk Space Issues

### Problem
```
Insufficient disk space for installations
```

### Solution
1. Free up disk space using Disk Cleanup
2. Move user folders to different drive if needed
3. Clean temporary files:
   ```powershell
   Get-ChildItem $env:TEMP -Recurse | Remove-Item -Force -Recurse
   ```

## Antivirus Interference

### Problem
Antivirus blocks script execution or file creation

### Solution
1. Temporarily disable real-time protection during ceremonies
2. Add PowerShell and script directories to antivirus exclusions
3. Whitelist the governance directory structure

## System Restart Required

### Problem
Some installations require system restart

### Solution
1. Complete current ceremony phase
2. Restart system as prompted
3. Re-run ceremony to continue from where it left off
4. Use validation tests to verify completion

## Registry Access Issues

### Problem
```
Access denied when modifying registry keys
```

### Solution
1. Run PowerShell as Administrator
2. Check User Account Control (UAC) settings
3. Ensure user has registry modification permissions
4. Use Group Policy for system-wide changes instead

## Module Import Issues

### Problem
```
Import-Module : The specified module 'CivicGovernance' was not loaded
```

### Solution
1. Verify module file exists in scripts/modules/
2. Check file path in script
3. Run from correct working directory
4. Set PowerShell execution policy appropriately

## General Troubleshooting Steps

1. **Check Prerequisites**: Ensure all requirements are met
2. **Run as Administrator**: Most ceremonies require elevated privileges
3. **Review Logs**: Check audit trail for detailed error information
4. **Use What-If Mode**: Preview changes before execution
5. **Run Validation**: Use validation tests to identify issues
6. **Incremental Approach**: Run ceremonies in smaller phases
7. **Backup First**: Create system restore point before major changes

## Getting Help

If issues persist:

1. Review the audit trail: `%USERPROFILE%\Documents\WindowsGovernance\AuditTrail.jsonl`
2. Run validation tests: `.\tests\Invoke-ValidationTests.ps1 -Detailed`
3. Check Windows Event Logs for system-level issues
4. Consult PowerShell documentation for specific cmdlet issues
5. Review ceremony documentation for known limitations

## Recovery Procedures

### Complete System Recovery
1. Boot from Windows installation media
2. Access System Recovery options
3. Restore from system restore point created before ceremonies
4. Reinstall Windows if necessary and restart ceremony process

### Partial Recovery
1. Restore specific configurations from backups
2. Re-run individual ceremony phases
3. Use validation tests to verify system state
4. Document lessons learned for future improvements