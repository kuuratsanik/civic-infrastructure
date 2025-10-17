<#
.SYNOPSIS
    Add governance entry to blockchain-style council ledger

.DESCRIPTION
    Implements DevMode2026-style governance with:
    - Blockchain-style hash chaining (tamper-evident)
    - Previous hash linking
    - Cryptographic verification
    - Citizen-auditable trail

.PARAMETER Action
    The action being logged (e.g., "Deploy", "Approve", "Execute")

.PARAMETER Actor
    Who performed the action

.PARAMETER Metadata
    Additional data about the action

.EXAMPLE
    Add-CouncilLedgerEntry -Action "Deploy Wave 9" -Actor "System" -Metadata @{ Mode = "Full" }
#>

function Add-CouncilLedgerEntry {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Action,

    [Parameter(Mandatory = $true)]
    [string]$Actor,

    [Parameter(Mandatory = $false)]
    [hashtable]$Metadata = @{},

    [Parameter(Mandatory = $false)]
    [string]$LedgerPath = "logs\council_ledger.jsonl"
  )

  # Ensure logs directory exists
  $logsDir = Split-Path $LedgerPath -Parent
  if (-not (Test-Path $logsDir)) {
    New-Item -Path $logsDir -ItemType Directory -Force | Out-Null
  }

  # Read existing records
  $previousRecords = @()
  if (Test-Path $LedgerPath) {
    $previousRecords = @(Get-Content $LedgerPath | ForEach-Object {
        if ($_.Trim()) {
          $_ | ConvertFrom-Json
        }
      })
  }  # Calculate previous hash (blockchain-style)
  $previousHash = if ($previousRecords.Count -gt 0) {
    $lastRecord = $previousRecords[-1]

    # Use the stored record_hash from previous entry
    if ($lastRecord.record_hash) {
      $lastRecord.record_hash
    } else {
      # Fallback: calculate hash of last record
      $lastRecordJson = $lastRecord | ConvertTo-Json -Compress
      $bytes = [System.Text.Encoding]::UTF8.GetBytes($lastRecordJson)
      $hasher = [System.Security.Cryptography.SHA256]::Create()
      $hashBytes = $hasher.ComputeHash($bytes)
      [System.BitConverter]::ToString($hashBytes).Replace('-', '').ToLower()
    }
  } else {
    # Genesis block - all zeros
    "0" * 64
  }

  # Create new record (without hash yet)
  $newRecord = [PSCustomObject]@{
    timestamp     = Get-Date -Format "o"
    action        = $Action
    actor         = $Actor
    metadata      = $Metadata
    previous_hash = $previousHash
    record_hash   = $null  # Will be calculated
    record_index  = $previousRecords.Count
  }

  # Calculate current record hash
  $recordForHashing = [PSCustomObject]@{
    timestamp     = $newRecord.timestamp
    action        = $newRecord.action
    actor         = $newRecord.actor
    metadata      = $newRecord.metadata
    previous_hash = $newRecord.previous_hash
    record_index  = $newRecord.record_index
  }

  $recordJson = $recordForHashing | ConvertTo-Json -Compress
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($recordJson)
  $hasher = [System.Security.Cryptography.SHA256]::Create()
  $hashBytes = $hasher.ComputeHash($bytes)
  $currentHash = [System.BitConverter]::ToString($hashBytes).Replace('-', '').ToLower()

  # Add hash to record
  $newRecord.record_hash = $currentHash

  # Append to ledger (JSONL format - one JSON object per line)
  $newRecord | ConvertTo-Json -Compress | Add-Content -Path $LedgerPath -Encoding UTF8

  # Return ledger entry summary
  $summary = @{
    Index        = $newRecord.record_index
    Hash         = $currentHash.Substring(0, 8) + "..."
    PreviousHash = $previousHash.Substring(0, 8) + "..."
    Action       = $Action
    Actor        = $Actor
    Timestamp    = $newRecord.timestamp
  }

  Write-Host "✅ Ledger entry #$($summary.Index) added" -ForegroundColor Green
  Write-Host "   Hash: $($summary.Hash)" -ForegroundColor Gray
  Write-Host "   Chain: $($summary.PreviousHash) → $($summary.Hash)" -ForegroundColor Gray
  Write-Host "   Action: $($summary.Action) by $($summary.Actor)" -ForegroundColor Gray

  return $newRecord
}

# Export function
Export-ModuleMember -Function Add-CouncilLedgerEntry
