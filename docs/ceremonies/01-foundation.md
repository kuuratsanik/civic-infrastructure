# Foundation Ceremony Documentation

The Foundation ceremony establishes the basic governance structure and system identity for treating Windows 11 Pro as civic infrastructure.

## Overview

This ceremony is the first step in transforming a standard Windows 11 Pro installation into a governed, auditable, and reproducible system following civic infrastructure principles.

## Prerequisites

- Windows 11 Pro
- Administrator privileges
- PowerShell 5.1 or later

## Ceremony Actions

### Phase 1: System Identity Setup
- Sets computer description to identify as civic infrastructure
- Records system identity in governance logs

### Phase 2: Security Foundation
- Checks BitLocker status and configuration
- Documents encryption state for audit trail

### Phase 3: System Information Audit
- Gathers comprehensive system information
- Creates system baseline for future comparison
- Anchors system configuration with cryptographic hash

### Phase 4: Governance Directory Structure
- Creates standardized directory structure for governance
- Establishes locations for ceremonies, configurations, scripts, and backups

### Phase 5: Foundation Documentation
- Generates ceremony completion log
- Documents all actions taken
- Provides guidance for next steps

## Directory Structure Created

```
%USERPROFILE%\Documents\WindowsGovernance\
├── AuditTrail.jsonl          # Comprehensive audit log
├── ConfigHashes.json         # Configuration integrity hashes
├── SystemBaseline.json       # System information baseline
├── Ceremonies\               # Ceremony completion logs  
├── Configurations\           # Exported configurations
├── Scripts\                  # Custom governance scripts
└── Backups\                  # Configuration backups
```

## Usage

```powershell
# Run the foundation ceremony
.\scripts\ceremonies\01-foundation\Initialize-Foundation.ps1

# Run with BitLocker check disabled
.\scripts\ceremonies\01-foundation\Initialize-Foundation.ps1 -SkipBitLocker

# Preview what would be done (What-If mode)
.\scripts\ceremonies\01-foundation\Initialize-Foundation.ps1 -WhatIf
```

## Outputs

- **System Baseline**: JSON export of system information
- **Ceremony Log**: Markdown documentation of ceremony completion
- **Audit Entries**: JSONL records of all ceremonial actions
- **Configuration Hashes**: Cryptographic anchors for integrity verification

## Next Steps

After completing the Foundation ceremony:

1. **Governance Ceremony**: Apply security policies and governance controls
2. **Operational Hygiene**: Configure updates, security, and key rotation
3. **Developer Cockpit**: Set up development environment
4. **UI Ritual**: Customize interface and user experience

## Validation

Verify foundation ceremony completion:

```powershell
# Check governance structure
Test-Path "$env:USERPROFILE\Documents\WindowsGovernance"

# Verify configuration integrity
.\tests\Invoke-ValidationTests.ps1 -TestCategories Foundation
```

## Troubleshooting

### Common Issues

**Issue**: BitLocker check fails
**Solution**: Run with `-SkipBitLocker` parameter if BitLocker is not available

**Issue**: Insufficient privileges
**Solution**: Run PowerShell as Administrator

**Issue**: Directory creation fails
**Solution**: Ensure sufficient disk space and permissions

### Recovery

If the ceremony fails partway through:
1. Review the audit trail at `%USERPROFILE%\Documents\WindowsGovernance\AuditTrail.jsonl`
2. Check for any error messages in the PowerShell output
3. Re-run the ceremony - it will skip completed actions
4. Contact support if issues persist

## Security Considerations

- All configurations are anchored with SHA256 hashes
- Audit trail provides complete ceremony history
- Directory permissions follow Windows security model
- No sensitive information is stored in plain text

## Governance Integration

The foundation ceremony establishes:
- **Audit Trail**: Complete history of system changes
- **Configuration Anchoring**: Cryptographic integrity verification
- **Reproducibility**: Documented and repeatable process
- **Accountability**: User and timestamp tracking for all actions