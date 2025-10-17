# Verify blockchain-style council ledger integrity
# DevMode2026 governance verification

param(
  [string]$LedgerPath = "logs\council_ledger.jsonl",
  [switch]$Verbose
)

Write-Host "`nBlockchain Ledger Integrity Verification" -ForegroundColor Cyan
Write-Host "==================================================`n" -ForegroundColor Cyan

if (-not (Test-Path $LedgerPath)) {
  Write-Host "Ledger not found: $LedgerPath" -ForegroundColor Red
  exit 1
}

$records = Get-Content $LedgerPath | ForEach-Object {
  if ($_.Trim()) { $_ | ConvertFrom-Json }
}

Write-Host "Total Records: $($records.Count)`n" -ForegroundColor Yellow

$errors = @()
$verifiedCount = 0

for ($i = 0; $i -lt $records.Count; $i++) {
  $record = $records[$i]

  $recordForHashing = [PSCustomObject]@{
    timestamp     = $record.timestamp
    action        = $record.action
    actor         = $record.actor
    metadata      = $record.metadata
    previous_hash = $record.previous_hash
    record_index  = $record.record_index
  }

  $recordJson = $recordForHashing | ConvertTo-Json -Compress
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($recordJson)
  $hasher = [System.Security.Cryptography.SHA256]::Create()
  $hashBytes = $hasher.ComputeHash($bytes)
  $calculatedHash = [System.BitConverter]::ToString($hashBytes).Replace('-', '').ToLower()

  if ($calculatedHash -ne $record.record_hash) {
    $errors += "Record $i hash mismatch"
  } else {
    $verifiedCount++
    if ($Verbose) {
      Write-Host "OK #$i $($calculatedHash.Substring(0,8))... $($record.action)" -ForegroundColor Green
    }
  }

  if ($i -gt 0) {
    $previousRecord = $records[$i - 1]
    if ($record.previous_hash -ne $previousRecord.record_hash) {
      $errors += "Record $i chain broken"
    }
  }
}

Write-Host "`n==================================================`n" -ForegroundColor Cyan
Write-Host "Verified: $verifiedCount / $($records.Count)" -ForegroundColor Yellow

if ($errors.Count -eq 0) {
  Write-Host "`nLEDGER INTEGRITY VERIFIED" -ForegroundColor Green
  Write-Host "No tampering detected`n" -ForegroundColor Green

  Write-Host "Hash Chain:" -ForegroundColor Cyan
  $records | ForEach-Object {
    $shortHash = $_.record_hash.Substring(0, 8)
    Write-Host " -> Record $($_.record_index): $shortHash... ($($_.action))" -ForegroundColor Gray
  }
  Write-Host ""
  exit 0
} else {
  Write-Host "`nLEDGER COMPROMISED!" -ForegroundColor Red
  $errors | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
  Write-Host ""
  exit 1
}
