# ISO Build Agent - Windows 11 Pro Customization
# Integrates with AI Council DAO governance for sovereign ISO builds

#Requires -RunAsAdministrator

param(
    [string]$Inbox = "C:\ai-council\bus\inbox",
    [string]$Outbox = "C:\ai-council\bus\outbox",
    [string]$Deadletter = "C:\ai-council\bus\deadletter",
    [string]$Ledger = "C:\ai-council\logs\agents\iso-build.jsonl",
    [string]$CouncilLedger = "C:\ai-council\logs\council_ledger.jsonl",
    [string]$Workspace = "C:\ai-council\workspace",
    [switch]$WatchMode
)

$ErrorActionPreference = "Stop"

Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "ISO Build Agent - DAO-Governed Builds" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Agent ID: council.build" -ForegroundColor Green
Write-Host "Inbox: $Inbox" -ForegroundColor Gray
Write-Host "Outbox: $Outbox" -ForegroundColor Gray
Write-Host "Workspace: $Workspace" -ForegroundColor Gray
Write-Host "Ledger: $Ledger" -ForegroundColor Gray
Write-Host ""

# Import helper scripts path
$ScriptPath = "C:\ai-council\agents\build\scripts"

function Test-Warrant {
    param([string]$WarrantId)
    
    $WarrantPath = "C:\ai-council\council\warrants\active\$WarrantId.json"
    
    if (-not (Test-Path $WarrantPath)) {
        Write-Host "ERROR: Warrant not found or expired: $WarrantId" -ForegroundColor Red
        return $false
    }
    
    try {
        $Warrant = Get-Content $WarrantPath | ConvertFrom-Json
        
        # Check expiry
        $ExpiresAt = [datetime]::Parse($Warrant.expires_at)
        if ((Get-Date) -gt $ExpiresAt) {
            Write-Host "ERROR: Warrant expired at $($Warrant.expires_at)" -ForegroundColor Red
            Move-Item $WarrantPath "C:\ai-council\council\warrants\archive\" -Force
            return $false
        }
        
        Write-Host "SUCCESS: Warrant validated: $WarrantId" -ForegroundColor Green
        Write-Host "  Proposal: $($Warrant.proposal_id)" -ForegroundColor Gray
        Write-Host "  Issued: $($Warrant.issued_at)" -ForegroundColor Gray
        Write-Host "  Expires: $($Warrant.expires_at)" -ForegroundColor Gray
        
        return $true
        
    } catch {
        Write-Host "ERROR: Failed to validate warrant: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Invoke-ISOBuildCeremony {
    param(
        [PSCustomObject]$Packet,
        [string]$WarrantId
    )
    
    Write-Host ""
    Write-Host "=======================================" -ForegroundColor Magenta
    Write-Host "ISO BUILD CEREMONY" -ForegroundColor Magenta
    Write-Host "=======================================" -ForegroundColor Magenta
    Write-Host "Warrant: $WarrantId" -ForegroundColor Gray
    Write-Host "Packet: $($Packet.packet_id)" -ForegroundColor Gray
    Write-Host ""
    
    $BuildManifest = @{
        packet_id = $Packet.packet_id
        warrant_id = $WarrantId
        timestamp_start = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        phases = @()
        status = "in_progress"
        customizations = @{
            updates_applied = 0
            drivers_added = 0
            tweaks_applied = 0
        }
    }
    
    try {
        # ===== PHASE 1: MOUNT WIM =====
        Write-Host "[Phase 1/6] Mounting WIM Image" -ForegroundColor Yellow
        Write-Host "-----------------------------------" -ForegroundColor DarkGray
        
        $WimPath = Join-Path $Workspace $Packet.inputs.base_iso
        $MountDir = Join-Path $Workspace $Packet.inputs.mount_dir
        
        & "$ScriptPath\Mount-WimImage.ps1" -Wim $WimPath -Mount $MountDir -Index 1 -Optimize
        
        if ($LASTEXITCODE -ne 0) {
            throw "Mount WIM failed with exit code $LASTEXITCODE"
        }
        
        $BuildManifest.phases += @{
            phase = "mount_wim"
            status = "completed"
            wim_path = $WimPath
            mount_dir = $MountDir
            timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        }
        
        # ===== PHASE 2: APPLY CUSTOMIZATIONS =====
        Write-Host ""
        Write-Host "[Phase 2/6] Applying Customizations" -ForegroundColor Yellow
        Write-Host "-----------------------------------" -ForegroundColor DarkGray
        
        $CustomParams = @{
            Mount = $MountDir
        }
        
        if ($Packet.inputs.customizations.updates) {
            $CustomParams.UpdatesDir = Join-Path $Workspace $Packet.inputs.customizations.updates
        }
        
        if ($Packet.inputs.customizations.drivers) {
            $CustomParams.DriversDir = Join-Path $Workspace $Packet.inputs.customizations.drivers
        }
        
        if ($Packet.inputs.customizations.tweaks) {
            $CustomParams.TweaksDir = Join-Path $Workspace $Packet.inputs.customizations.tweaks
        }
        
        $CustomResult = & "$ScriptPath\Apply-Customizations.ps1" @CustomParams
        
        if ($LASTEXITCODE -ne 0) {
            throw "Apply customizations failed with exit code $LASTEXITCODE"
        }
        
        $BuildManifest.customizations = $CustomResult
        $BuildManifest.phases += @{
            phase = "apply_customizations"
            status = "completed"
            customizations = $CustomResult
            timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        }
        
        # ===== PHASE 3: UNMOUNT WIM =====
        Write-Host ""
        Write-Host "[Phase 3/6] Committing Changes and Unmounting" -ForegroundColor Yellow
        Write-Host "-----------------------------------" -ForegroundColor DarkGray
        
        & "$ScriptPath\Dismount-WimImage.ps1" -Mount $MountDir
        
        if ($LASTEXITCODE -ne 0) {
            throw "Unmount WIM failed with exit code $LASTEXITCODE"
        }
        
        $BuildManifest.phases += @{
            phase = "unmount_wim"
            status = "completed"
            timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        }
        
        # ===== PHASE 4: CREATE ISO =====
        Write-Host ""
        Write-Host "[Phase 4/6] Creating Bootable ISO" -ForegroundColor Yellow
        Write-Host "-----------------------------------" -ForegroundColor DarkGray
        
        $SourceDir = Split-Path $WimPath -Parent | Split-Path -Parent
        $OutISO = Join-Path $Workspace $Packet.inputs.output_iso
        
        & "$ScriptPath\New-BootableISO.ps1" -Source $SourceDir -OutISO $OutISO -Label "WIN11_CUSTOM"
        
        if ($LASTEXITCODE -ne 0) {
            throw "Create ISO failed with exit code $LASTEXITCODE"
        }
        
        $BuildManifest.phases += @{
            phase = "create_iso"
            status = "completed"
            output_path = $OutISO
            timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        }
        
        # ===== PHASE 5: HASH ISO =====
        Write-Host ""
        Write-Host "[Phase 5/6] Computing ISO Hash" -ForegroundColor Yellow
        Write-Host "-----------------------------------" -ForegroundColor DarkGray
        
        $ISOHash = & "$ScriptPath\Get-ISOHash.ps1" -ISO $OutISO
        
        if ($LASTEXITCODE -ne 0) {
            throw "Hash ISO failed with exit code $LASTEXITCODE"
        }
        
        $BuildManifest.phases += @{
            phase = "hash_iso"
            status = "completed"
            sha256 = $ISOHash
            timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        }
        
        # ===== PHASE 6: VM TEST (OPTIONAL) =====
        if ($Packet.inputs.test_in_vm) {
            Write-Host ""
            Write-Host "[Phase 6/6] Testing ISO in VM" -ForegroundColor Yellow
            Write-Host "-----------------------------------" -ForegroundColor DarkGray
            
            $TestResult = & "$ScriptPath\Test-ISOInVM.ps1" -ISO $OutISO
            
            $BuildManifest.phases += @{
                phase = "vm_test"
                status = $TestResult.status
                test_log = $TestResult.log_path
                timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
            }
        }
        
        # ===== CEREMONY COMPLETE =====
        $BuildManifest.status = "completed"
        $BuildManifest.timestamp_end = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        $BuildManifest.output_iso = $OutISO
        $BuildManifest.sha256 = $ISOHash
        
        Write-Host ""
        Write-Host "=======================================" -ForegroundColor Green
        Write-Host "ISO BUILD COMPLETE" -ForegroundColor Green
        Write-Host "=======================================" -ForegroundColor Green
        Write-Host "Output: $OutISO" -ForegroundColor White
        Write-Host "SHA256: $ISOHash" -ForegroundColor White
        Write-Host "Updates: $($BuildManifest.customizations.updates_applied)" -ForegroundColor White
        Write-Host "Drivers: $($BuildManifest.customizations.drivers_added)" -ForegroundColor White
        Write-Host "Tweaks: $($BuildManifest.customizations.tweaks_applied)" -ForegroundColor White
        Write-Host ""
        
        return $BuildManifest
        
    } catch {
        Write-Host ""
        Write-Host "=======================================" -ForegroundColor Red
        Write-Host "ISO BUILD FAILED" -ForegroundColor Red
        Write-Host "=======================================" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        
        # Try to clean up mounted image
        try {
            $MountDir = Join-Path $Workspace $Packet.inputs.mount_dir
            if (Test-Path $MountDir) {
                Write-Host "Attempting to unmount and discard changes..." -ForegroundColor Yellow
                dism /Unmount-Wim /MountDir:$MountDir /Discard 2>&1 | Out-Null
            }
        } catch {
            Write-Host "WARNING: Cleanup failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        $BuildManifest.status = "failed"
        $BuildManifest.error = $_.Exception.Message
        $BuildManifest.timestamp_end = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        
        return $BuildManifest
    }
}

function Invoke-PacketProcessor {
    param([string]$PacketPath)
    
    Write-Host ""
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host "Processing Packet" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host "File: $(Split-Path $PacketPath -Leaf)" -ForegroundColor White
    Write-Host ""
    
    try {
        $Packet = Get-Content $PacketPath | ConvertFrom-Json
        
        # Validate packet is for build agent
        if ($Packet.role -ne "build") {
            Write-Host "INFO: Packet not for build agent (role: $($Packet.role)), skipping" -ForegroundColor Gray
            return
        }
        
        # Validate warrant
        if (-not $Packet.warrant_id) {
            throw "No warrant ID provided - DAO approval required for ISO build"
        }
        
        if (-not (Test-Warrant -WarrantId $Packet.warrant_id)) {
            throw "Warrant validation failed: $($Packet.warrant_id)"
        }
        
        # Execute build ceremony
        $Result = Invoke-ISOBuildCeremony -Packet $Packet -WarrantId $Packet.warrant_id
        
        # Write result to outbox
        $OutputPacket = @{
            packet_id = $Packet.packet_id
            agent = "council.build"
            action = $Packet.action
            warrant_id = $Packet.warrant_id
            result = $Result
            timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        }
        
        $OutputPath = "$Outbox\$($Packet.packet_id)-result.json"
        $OutputPacket | ConvertTo-Json -Depth 10 | Set-Content $OutputPath
        
        Write-Host "Result written to outbox: $OutputPath" -ForegroundColor Green
        
        # Log to ledgers
        @{
            ts = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
            packet_id = $Packet.packet_id
            agent = "council.build"
            action = $Packet.action
            warrant_id = $Packet.warrant_id
            status = $Result.status
            iso_hash = $Result.sha256
        } | ConvertTo-Json -Compress | Add-Content $Ledger
        
        @{
            ts = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
            packet_id = $Packet.packet_id
            agent = "build"
            action = "iso_build"
            status = $Result.status
            warrant = $Packet.warrant_id
        } | ConvertTo-Json -Compress | Add-Content $CouncilLedger
        
        # Remove processed packet
        Remove-Item $PacketPath -Force
        Write-Host "Packet removed from inbox" -ForegroundColor Gray
        
    } catch {
        Write-Host ""
        Write-Host "PACKET PROCESSING FAILED" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        
        # Log failure
        @{
            ts = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
            packet_id = $Packet.packet_id
            agent = "council.build"
            action = $Packet.action
            status = "failed"
            error = $_.Exception.Message
        } | ConvertTo-Json -Compress | Add-Content $Ledger
        
        # Move to deadletter
        Copy-Item $PacketPath $Deadletter -Force
        Remove-Item $PacketPath -Force
        
        Write-Host "Packet moved to deadletter queue" -ForegroundColor Yellow
    }
}

# Main execution loop
if ($WatchMode) {
    Write-Host "=======================================" -ForegroundColor Magenta
    Write-Host "WATCH MODE ACTIVE" -ForegroundColor Magenta
    Write-Host "=======================================" -ForegroundColor Magenta
    Write-Host "Monitoring inbox every 10 seconds..." -ForegroundColor Gray
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
    Write-Host ""
    
    while ($true) {
        $Packets = Get-ChildItem $Inbox -Filter *.json -ErrorAction SilentlyContinue
        
        if ($Packets) {
            foreach ($PacketFile in $Packets) {
                Invoke-PacketProcessor -PacketPath $PacketFile.FullName
            }
        }
        
        Start-Sleep -Seconds 10
    }
    
} else {
    Write-Host "SINGLE-PASS MODE" -ForegroundColor Magenta
    Write-Host "Processing current inbox contents" -ForegroundColor Gray
    Write-Host ""
    
    $Packets = Get-ChildItem $Inbox -Filter *.json -ErrorAction SilentlyContinue
    
    if (-not $Packets) {
        Write-Host "No packets found in inbox" -ForegroundColor Gray
        exit 0
    }
    
    foreach ($PacketFile in $Packets) {
        Invoke-PacketProcessor -PacketPath $PacketFile.FullName
    }
    
    Write-Host ""
    Write-Host "=== Processing Complete ===" -ForegroundColor Cyan
}
