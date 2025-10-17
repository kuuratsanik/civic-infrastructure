<#
.SYNOPSIS
    Lineage Bus Module - Signed Event Stream for Audit Trails

.DESCRIPTION
    Provides tamper-evident, cryptographically signed event emission system.
    All agent decisions emit lineage events with provenance, witnesses, and replay capability.

.NOTES
    Version: 1.0.0
    Part of: Multi-Agent Intelligence Framework
    Requires: PowerShell 5.1+

.ARCHITECTURE
    - bus/lineage/events/*.jsonl     - Append-only event log (one event per line)
    - bus/lineage/index/*.json       - Event index by agent, type, date
    - bus/lineage/signatures/*.sig   - Detached signatures for events
    - bus/lineage/replay/*.bundle    - Deterministic replay bundles
#>

# === CONFIGURATION ===
$script:LineageBusPath = "$PSScriptRoot\..\..\bus\lineage"
$script:EventLogPath = "$script:LineageBusPath\events"
$script:IndexPath = "$script:LineageBusPath\index"
$script:SignaturePath = "$script:LineageBusPath\signatures"
$script:ReplayPath = "$script:LineageBusPath\replay"

# Ensure directories exist
@($script:EventLogPath, $script:IndexPath, $script:SignaturePath, $script:ReplayPath) | ForEach-Object {
  if (-not (Test-Path $_)) {
    New-Item -ItemType Directory -Path $_ -Force | Out-Null
  }
}

<#
.SYNOPSIS
    Emits a lineage event to the tamper-evident bus.

.DESCRIPTION
    Creates a cryptographically signed event record with full provenance.
    Events are append-only, indexed for fast retrieval, and support deterministic replay.

.PARAMETER EventType
    Type of event (e.g., "decision", "mandate_created", "agent_hot_swap").

.PARAMETER AgentRole
    Role of the agent emitting the event.

.PARAMETER Payload
    Hashtable containing event-specific data.

.PARAMETER Witnesses
    Array of witness role identifiers for attestation.

.PARAMETER Deterministic
    Whether this event supports deterministic replay.

.PARAMETER Signature
    Pre-computed signature (if signing externally).

.EXAMPLE
    New-LineageEvent -EventType "supplier_approved" `
        -AgentRole "commerce-supplier-verifier" `
        -Payload @{
            supplier_id = "SUP-001"
            compliance_score = 0.98
            checks_performed = 47
        } `
        -Witnesses @("witness-audit-01")

.EXAMPLE
    # With deterministic replay
    New-LineageEvent -EventType "iso_built" `
        -AgentRole "build-iso-optimizer" `
        -Payload @{
            iso_path = "workspace/output/custom.iso"
            build_time_seconds = 2743
            driver_count = 23
        } `
        -Deterministic `
        -ReplaySnapshot @{
            inputs = @{ base_iso = "Win11_25H2_Estonian_x64.iso" }
            environment = @{ powershell_version = "5.1.22621" }
        }
#>
function New-LineageEvent {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$EventType,

    [Parameter(Mandatory = $true)]
    [string]$AgentRole,

    [Parameter(Mandatory = $true)]
    [hashtable]$Payload,

    [string[]]$Witnesses = @(),

    [switch]$Deterministic,

    [hashtable]$ReplaySnapshot = @{},

    [string]$Signature
  )

  # Generate unique event ID
  $eventId = "evt-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$([Guid]::NewGuid().ToString().Substring(0,8))"

  # Build event structure
  $event = [ordered]@{
    event_id      = $eventId
    event_type    = $EventType
    timestamp     = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
    agent_role    = $AgentRole
    user          = $env:USERNAME
    machine       = $env:COMPUTERNAME
    payload       = $Payload
    deterministic = $Deterministic.IsPresent
  }

  # Add replay snapshot if deterministic
  if ($Deterministic -and $ReplaySnapshot.Count -gt 0) {
    $event.replay_snapshot = $ReplaySnapshot
  }

  # Add witnesses
  if ($Witnesses.Count -gt 0) {
    $event.witnesses = $Witnesses
    $event.witness_signatures = @{}
    foreach ($witness in $Witnesses) {
      $event.witness_signatures[$witness] = "pending"
    }
  }

  # Compute event hash (SHA-256 of canonical JSON)
  $canonicalJson = ($event | ConvertTo-Json -Depth 10 -Compress)
  $eventHash = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($canonicalJson))) -Algorithm SHA256).Hash
  $event.event_hash = $eventHash

  # Sign event (simplified - in production use proper PKI)
  if (-not $Signature) {
    $Signature = Sign-Event -Event $event
  }
  $event.signature = $Signature

  # Convert to JSONL (one line)
  $jsonLine = ($event | ConvertTo-Json -Depth 10 -Compress)

  # Append to daily log file (append-only)
  $logFile = Join-Path $script:EventLogPath "$(Get-Date -Format 'yyyy-MM-dd').jsonl"
  Add-Content -Path $logFile -Value $jsonLine -Encoding UTF8

  # Update index
  Update-EventIndex -Event $event

  # Save detached signature
  $sigFile = Join-Path $script:SignaturePath "$eventId.sig"
  $Signature | Out-File -FilePath $sigFile -Encoding UTF8

  # Create replay bundle if deterministic
  if ($Deterministic) {
    New-ReplayBundle -Event $event -EventId $eventId
  }

  Write-Verbose "✅ Lineage event emitted: $eventId"

  return @{
    EventId   = $eventId
    EventHash = $eventHash
    LogFile   = $logFile
    Signature = $Signature
  }
}

<#
.SYNOPSIS
    Simplified event signing (replace with proper PKI in production).

.PARAMETER Event
    Event hashtable to sign.

.OUTPUTS
    Base64-encoded signature string.
#>
function Sign-Event {
  param([hashtable]$Event)

  # Compute hash
  $canonicalJson = ($Event | ConvertTo-Json -Depth 10 -Compress)
  $hash = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($canonicalJson))) -Algorithm SHA256).Hash

  # Simplified signature (in production: use X509 certificates, GPG, or Azure Key Vault)
  $signatureData = "SIG:$hash:$($env:USERNAME)@$($env:COMPUTERNAME):$(Get-Date -Format 'yyyyMMddHHmmss')"
  $signatureBytes = [System.Text.Encoding]::UTF8.GetBytes($signatureData)
  $signatureBase64 = [Convert]::ToBase64String($signatureBytes)

  return $signatureBase64
}

<#
.SYNOPSIS
    Updates the event index for fast lookups.

.PARAMETER Event
    Event to index.
#>
function Update-EventIndex {
  param([hashtable]$Event)

  $date = Get-Date -Format "yyyy-MM-dd"
  $indexFile = Join-Path $script:IndexPath "$date.json"

  # Load existing index or create new
  if (Test-Path $indexFile) {
    $index = Get-Content -Path $indexFile -Raw | ConvertFrom-Json
    $entries = @($index.events)
  } else {
    $entries = @()
  }

  # Add entry
  $entries += @{
    event_id   = $Event.event_id
    event_type = $Event.event_type
    timestamp  = $Event.timestamp
    agent_role = $Event.agent_role
    event_hash = $Event.event_hash
  }

  # Save index
  $indexData = @{
    index_date  = $date
    event_count = $entries.Count
    events      = $entries
  }

  $indexData | ConvertTo-Json -Depth 10 | Out-File -FilePath $indexFile -Encoding UTF8
}

<#
.SYNOPSIS
    Creates a deterministic replay bundle.

.PARAMETER Event
    Event with replay snapshot.

.PARAMETER EventId
    Event identifier.
#>
function New-ReplayBundle {
  param(
    [hashtable]$Event,
    [string]$EventId
  )

  $bundlePath = Join-Path $script:ReplayPath "$EventId.bundle.json"

  $bundle = @{
    replay_id     = "replay-$EventId"
    lineage_event = $EventId
    snapshot      = $Event.replay_snapshot
    outputs       = $Event.payload
    verification  = @{
      verified               = $false
      verification_timestamp = $null
      verification_agent     = $null
    }
  }

  $bundle | ConvertTo-Json -Depth 10 | Out-File -FilePath $bundlePath -Encoding UTF8
}

<#
.SYNOPSIS
    Queries lineage events by filter criteria.

.PARAMETER AgentRole
    Filter by agent role.

.PARAMETER EventType
    Filter by event type.

.PARAMETER StartDate
    Filter events after this date (inclusive).

.PARAMETER EndDate
    Filter events before this date (inclusive).

.PARAMETER EventId
    Retrieve specific event by ID.

.PARAMETER Limit
    Maximum number of events to return.

.EXAMPLE
    Get-LineageEvents -AgentRole "commerce-supplier-verifier" -Limit 10

.EXAMPLE
    Get-LineageEvents -EventType "decision" -StartDate "2025-10-16"

.EXAMPLE
    Get-LineageEvents -EventId "evt-20251016-143022-abc12345"
#>
function Get-LineageEvents {
  [CmdletBinding()]
  param(
    [string]$AgentRole,
    [string]$EventType,
    [datetime]$StartDate,
    [datetime]$EndDate = (Get-Date),
    [string]$EventId,
    [int]$Limit = 100
  )

  # If specific event ID requested
  if ($EventId) {
    # Extract date from event ID (evt-YYYYMMDD-...)
    if ($EventId -match '^evt-(\d{8})') {
      $dateStr = $matches[1]
      $year = $dateStr.Substring(0, 4)
      $month = $dateStr.Substring(4, 2)
      $day = $dateStr.Substring(6, 2)
      $logFile = Join-Path $script:EventLogPath "$year-$month-$day.jsonl"

      if (Test-Path $logFile) {
        $events = Get-Content -Path $logFile | ForEach-Object {
          $_ | ConvertFrom-Json
        } | Where-Object { $_.event_id -eq $EventId }

        return $events
      }
    }

    Write-Warning "Event not found: $EventId"
    return $null
  }

  # Build date range
  if (-not $StartDate) {
    $StartDate = (Get-Date).AddDays(-7)  # Last 7 days by default
  }

  $currentDate = $StartDate
  $allEvents = @()

  while ($currentDate -le $EndDate -and $allEvents.Count -lt $Limit) {
    $logFile = Join-Path $script:EventLogPath ($currentDate.ToString("yyyy-MM-dd") + ".jsonl")

    if (Test-Path $logFile) {
      $dayEvents = Get-Content -Path $logFile | ForEach-Object {
        $_ | ConvertFrom-Json
      }

      # Apply filters
      if ($AgentRole) {
        $dayEvents = $dayEvents | Where-Object { $_.agent_role -eq $AgentRole }
      }

      if ($EventType) {
        $dayEvents = $dayEvents | Where-Object { $_.event_type -eq $EventType }
      }

      $allEvents += $dayEvents
    }

    $currentDate = $currentDate.AddDays(1)
  }

  # Limit results
  if ($allEvents.Count -gt $Limit) {
    $allEvents = $allEvents | Select-Object -First $Limit
  }

  Write-Verbose "Found $($allEvents.Count) events matching filters"

  return $allEvents
}

<#
.SYNOPSIS
    Verifies the integrity of a lineage event.

.PARAMETER EventId
    Event identifier to verify.

.PARAMETER Event
    Event object (if already loaded).

.EXAMPLE
    Test-LineageEventIntegrity -EventId "evt-20251016-143022-abc12345"
#>
function Test-LineageEventIntegrity {
  [CmdletBinding()]
  param(
    [Parameter(ParameterSetName = 'ById', Mandatory = $true)]
    [string]$EventId,

    [Parameter(ParameterSetName = 'ByEvent', Mandatory = $true)]
    [object]$Event
  )

  # Load event if only ID provided
  if ($EventId) {
    $Event = Get-LineageEvents -EventId $EventId
    if (-not $Event) {
      Write-Error "Event not found: $EventId"
      return $false
    }
  }

  # Extract signature and hash
  $storedSignature = $Event.signature
  $storedHash = $Event.event_hash

  # Recompute hash
  $eventCopy = $Event.PSObject.Copy()
  $eventCopy.PSObject.Properties.Remove('event_hash')
  $eventCopy.PSObject.Properties.Remove('signature')

  $canonicalJson = ($eventCopy | ConvertTo-Json -Depth 10 -Compress)
  $computedHash = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($canonicalJson))) -Algorithm SHA256).Hash

  # Compare hashes
  if ($computedHash -ne $storedHash) {
    Write-Warning "Hash mismatch for event $($Event.event_id)"
    Write-Warning "  Stored:   $storedHash"
    Write-Warning "  Computed: $computedHash"
    return $false
  }

  # Verify signature (simplified)
  # In production: verify X509, GPG, or Azure Key Vault signature
  $signatureBytes = [Convert]::FromBase64String($storedSignature)
  $signatureData = [System.Text.Encoding]::UTF8.GetString($signatureBytes)

  if ($signatureData -notlike "SIG:$computedHash:*") {
    Write-Warning "Signature invalid for event $($Event.event_id)"
    return $false
  }

  Write-Verbose "✅ Event integrity verified: $($Event.event_id)"
  return $true
}

<#
.SYNOPSIS
    Exports lineage events for audit reporting (e.g., GDPR RoPA).

.PARAMETER StartDate
    Start of reporting period.

.PARAMETER EndDate
    End of reporting period.

.PARAMETER Format
    Output format (JSON, CSV, HTML).

.PARAMETER OutputPath
    Where to save the report.

.EXAMPLE
    Export-LineageAuditReport -StartDate "2025-10-01" -EndDate "2025-10-31" -Format CSV -OutputPath "reports/october-audit.csv"
#>
function Export-LineageAuditReport {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [datetime]$StartDate,

    [Parameter(Mandatory = $true)]
    [datetime]$EndDate,

    [ValidateSet('JSON', 'CSV', 'HTML')]
    [string]$Format = 'JSON',

    [string]$OutputPath
  )

  # Get all events in date range
  $events = Get-LineageEvents -StartDate $StartDate -EndDate $EndDate -Limit 99999

  if ($events.Count -eq 0) {
    Write-Warning "No events found in date range: $StartDate to $EndDate"
    return
  }

  # Generate report
  $report = @{
    report_id    = "audit-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    period_start = $StartDate.ToString("yyyy-MM-dd")
    period_end   = $EndDate.ToString("yyyy-MM-dd")
    generated    = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    total_events = $events.Count
    agents       = ($events | Select-Object -ExpandProperty agent_role -Unique | Sort-Object)
    event_types  = ($events | Select-Object -ExpandProperty event_type -Unique | Sort-Object)
    events       = $events
  }

  # Default output path
  if (-not $OutputPath) {
    $OutputPath = Join-Path $PSScriptRoot "..\..\reports\lineage-audit-$(Get-Date -Format 'yyyyMMdd').$($Format.ToLower())"
    $reportsDir = Split-Path $OutputPath -Parent
    if (-not (Test-Path $reportsDir)) {
      New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
    }
  }

  # Export based on format
  switch ($Format) {
    'JSON' {
      $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    }
    'CSV' {
      $events | Select-Object event_id, event_type, timestamp, agent_role, event_hash |
      Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    }
    'HTML' {
      $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Lineage Audit Report</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 20px; }
        h1 { color: #0078D4; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th { background-color: #0078D4; color: white; padding: 10px; text-align: left; }
        td { border: 1px solid #ddd; padding: 8px; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .summary { background-color: #e7f3ff; padding: 15px; margin-bottom: 20px; border-left: 4px solid #0078D4; }
    </style>
</head>
<body>
    <h1>🏛️ Lineage Audit Report</h1>
    <div class="summary">
        <p><strong>Report ID:</strong> $($report.report_id)</p>
        <p><strong>Period:</strong> $($report.period_start) to $($report.period_end)</p>
        <p><strong>Generated:</strong> $($report.generated)</p>
        <p><strong>Total Events:</strong> $($report.total_events)</p>
        <p><strong>Agents:</strong> $($report.agents -join ', ')</p>
    </div>
    <h2>Events</h2>
    <table>
        <tr>
            <th>Event ID</th>
            <th>Type</th>
            <th>Timestamp</th>
            <th>Agent</th>
            <th>Hash</th>
        </tr>
$($events | ForEach-Object {
    "        <tr><td>$($_.event_id)</td><td>$($_.event_type)</td><td>$($_.timestamp)</td><td>$($_.agent_role)</td><td>$($_.event_hash.Substring(0,16))...</td></tr>"
} | Out-String)
    </table>
</body>
</html>
"@
      $html | Out-File -FilePath $OutputPath -Encoding UTF8
    }
  }

  Write-Host "✅ Audit report exported: $OutputPath" -ForegroundColor Green
  Write-Host "   Period: $($report.period_start) to $($report.period_end)" -ForegroundColor Cyan
  Write-Host "   Events: $($report.total_events)" -ForegroundColor Cyan
  Write-Host "   Agents: $($report.agents.Count)" -ForegroundColor Cyan

  return $OutputPath
}

# Export functions
Export-ModuleMember -Function New-LineageEvent, Get-LineageEvents, Test-LineageEventIntegrity, Export-LineageAuditReport
