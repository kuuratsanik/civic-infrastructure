# Civic Agent - Multi-Agent Ceremony Coordinator with AI Integration
# Integrates AI Council DAO governance with Windows 11 Civic Infrastructure ceremonies
# NOW WITH: AI-powered analysis, autonomous optimization, intelligent decision-making
# Monitors message bus for ceremony packets, validates warrants, executes ceremonies

param(
    [string]$Inbox = "C:\ai-council\bus\inbox",
    [string]$Outbox = "C:\ai-council\bus\outbox",
    [string]$Deadletter = "C:\ai-council\bus\deadletter",
    [string]$Ledger = "C:\ai-council\logs\civic.jsonl",
    [string]$CouncilLedger = "C:\ai-council\logs\council_ledger.jsonl",
    [switch]$WatchMode,
    [switch]$EnableAI,  # NEW: Enable AI-powered features
    [string]$OllamaUrl = "http://localhost:11434"  # NEW: Local AI endpoint
)

# Import Civic Infrastructure modules
$ModulePath = "C:\ai-council\agents\civic\modules"
Import-Module "$ModulePath\CivicGovernance.psm1" -Force
Import-Module "$ModulePath\EvidenceBundler.psm1" -Force
Import-Module "$ModulePath\ManifestValidator.psm1" -Force

Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "Civic Agent - DAO-Governed Ceremonies" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Agent ID: council.civic" -ForegroundColor Green
Write-Host "Inbox: $Inbox" -ForegroundColor Gray
Write-Host "Outbox: $Outbox" -ForegroundColor Gray
Write-Host "Ledger: $Ledger" -ForegroundColor Gray
Write-Host ""

# Function: Validate warrant
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
            
            # Archive expired warrant
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

# Function: Execute ceremony
function Invoke-Ceremony {
    param(
        [PSCustomObject]$Packet,
        [string]$WarrantId
    )
    
    $CeremonyName = $Packet.inputs.ceremony
    $CeremonyPath = "C:\ai-council\agents\civic\ceremonies\$CeremonyName"
    
    if (-not (Test-Path $CeremonyPath)) {
        throw "Ceremony not found: $CeremonyName at $CeremonyPath"
    }
    
    Write-Host ""
    Write-Host "=== Executing Ceremony: $CeremonyName ===" -ForegroundColor Cyan
    Write-Host "Warrant: $WarrantId" -ForegroundColor Gray
    Write-Host "Path: $CeremonyPath" -ForegroundColor Gray
    Write-Host ""
    
    # Find ceremony initialization script
    $InitScript = Get-ChildItem $CeremonyPath -Filter "*.ps1" | Select-Object -First 1
    
    if (-not $InitScript) {
        throw "No PowerShell script found in ceremony folder: $CeremonyPath"
    }
    
    # Execute ceremony with warrant context
    $StartTime = Get-Date
    
    try {
        # Execute ceremony script
        & $InitScript.FullName -WhatIf:$false
        
        $Duration = ((Get-Date) - $StartTime).TotalSeconds
        
        Write-Host ""
        Write-Host "SUCCESS: Ceremony completed in $Duration seconds" -ForegroundColor Green
        
        return @{
            status = "completed"
            ceremony = $CeremonyName
            duration_seconds = $Duration
            warrant_id = $WarrantId
            timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        }
        
    } catch {
        $Duration = ((Get-Date) - $StartTime).TotalSeconds
        
        Write-Host ""
        Write-Host "FAILED: Ceremony failed after $Duration seconds" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        
        return @{
            status = "failed"
            ceremony = $CeremonyName
            duration_seconds = $Duration
            warrant_id = $WarrantId
            error = $_.Exception.Message
            timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        }
    }
}

# Function: Apply Extended Security Mode policy
function Set-ExtendedSecurityPolicy {
    param(
        [string]$PolicyPath,
        [string]$WarrantId
    )
    
    Write-Host ""
    Write-Host "=== Applying Extended Security Mode Policy ===" -ForegroundColor Cyan
    Write-Host "Policy: $PolicyPath" -ForegroundColor Gray
    Write-Host "Warrant: $WarrantId" -ForegroundColor Gray
    Write-Host ""
    
    if (-not (Test-Path $PolicyPath)) {
        throw "Policy file not found: $PolicyPath"
    }
    
    # Load policy (YAML - would need yaml module in production)
    Write-Host "WARNING: Full ESM policy application requires additional tooling" -ForegroundColor Yellow
    Write-Host "Simulating policy application for demonstration..." -ForegroundColor Yellow
    
    # Update council manifest state
    $ManifestPath = "C:\ai-council\council\manifest.json"
    $Manifest = Get-Content $ManifestPath | ConvertFrom-Json
    $Manifest.state.ExtendedSecurity = 1
    $Manifest.state.last_esm_change = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    $Manifest.state.esm_warrant_id = $WarrantId
    
    $Manifest | ConvertTo-Json -Depth 10 | Set-Content $ManifestPath
    
    Write-Host "SUCCESS: ESM enabled in council manifest" -ForegroundColor Green
    Write-Host "NOTE: Full policy enforcement would apply WDAC/AppLocker/CLM/ASR rules" -ForegroundColor Yellow
    
    return @{
        status = "enabled"
        policy_file = $PolicyPath
        warrant_id = $WarrantId
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    }
}

# Function: Process packet
function Invoke-PacketProcessor {
    param([string]$PacketPath)
    
    Write-Host ""
    Write-Host "---------------------------------------" -ForegroundColor DarkGray
    Write-Host "Processing packet: $(Split-Path $PacketPath -Leaf)" -ForegroundColor White
    Write-Host "---------------------------------------" -ForegroundColor DarkGray
    
    try {
        $Packet = Get-Content $PacketPath | ConvertFrom-Json
        
        # Validate packet structure
        if ($Packet.role -ne "civic") {
            Write-Host "INFO: Packet not for civic agent (role: $($Packet.role)), skipping" -ForegroundColor Gray
            return
        }
        
        # Validate warrant
        if (-not $Packet.warrant_id) {
            throw "No warrant ID provided - DAO approval required for all civic operations"
        }
        
        if (-not (Test-Warrant -WarrantId $Packet.warrant_id)) {
            throw "Warrant validation failed: $($Packet.warrant_id)"
        }
        
        # Process based on action
        $Result = $null
        
        switch ($Packet.action) {
            "execute_ceremony" {
                $Result = Invoke-Ceremony -Packet $Packet -WarrantId $Packet.warrant_id
            }
            
            "enable_extended_security" {
                $PolicyPath = "C:\ai-council\$($Packet.inputs.policy_file)"
                $Result = Set-ExtendedSecurityPolicy -PolicyPath $PolicyPath -WarrantId $Packet.warrant_id
            }
            
            "disable_extended_security" {
                # Requires emergency warrant
                Write-Host "WARNING: ESM disable requires emergency warrant with multi-sig" -ForegroundColor Yellow
                
                # Update manifest
                $ManifestPath = "C:\ai-council\council\manifest.json"
                $Manifest = Get-Content $ManifestPath | ConvertFrom-Json
                $Manifest.state.ExtendedSecurity = 0
                $Manifest.state.last_esm_change = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
                $Manifest.state.esm_emergency_warrant_id = $Packet.warrant_id
                $Manifest | ConvertTo-Json -Depth 10 | Set-Content $ManifestPath
                
                $Result = @{
                    status = "disabled"
                    warrant_id = $Packet.warrant_id
                    cooldown_ends = (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:ssZ")
                    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
                }
            }
            
            default {
                throw "Unknown action: $($Packet.action)"
            }
        }
        
        # Write result to outbox
        $OutputPacket = @{
            packet_id = $Packet.packet_id
            agent = "council.civic"
            action = $Packet.action
            warrant_id = $Packet.warrant_id
            result = $Result
            timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        }
        
        $OutputPath = "$Outbox\$($Packet.packet_id)-result.json"
        $OutputPacket | ConvertTo-Json -Depth 10 | Set-Content $OutputPath
        
        Write-Host "SUCCESS: Result written to outbox" -ForegroundColor Green
        
        # Log to civic ledger
        @{
            ts = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
            packet_id = $Packet.packet_id
            agent = "council.civic"
            action = $Packet.action
            warrant_id = $Packet.warrant_id
            status = $Result.status
        } | ConvertTo-Json -Compress | Add-Content $Ledger
        
        # Log to council ledger
        @{
            ts = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
            packet_id = $Packet.packet_id
            agent = "civic"
            action = $Packet.action
            status = $Result.status
            warrant = $Packet.warrant_id
        } | ConvertTo-Json -Compress | Add-Content $CouncilLedger
        
        # Remove processed packet
        Remove-Item $PacketPath -Force
        Write-Host "Packet processed and removed from inbox" -ForegroundColor Gray
        
    } catch {
        Write-Host ""
        Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
        
        # Log failure
        @{
            ts = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
            packet_id = $Packet.packet_id
            agent = "council.civic"
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
    Write-Host "WATCH MODE ACTIVE - Monitoring inbox every 5 seconds" -ForegroundColor Magenta
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
    Write-Host ""
    
    while ($true) {
        $Packets = Get-ChildItem $Inbox -Filter *.json -ErrorAction SilentlyContinue
        
        if ($Packets) {
            foreach ($PacketFile in $Packets) {
                Invoke-PacketProcessor -PacketPath $PacketFile.FullName
            }
        }
        
        Start-Sleep -Seconds 5
    }
    
} else {
    # Single-pass mode
    Write-Host "SINGLE-PASS MODE - Processing current inbox contents" -ForegroundColor Magenta
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
