# Civic comms-bus heartbeat 2026. Cloud hop only.
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot "config.json"),
    [string]$Action = "heartbeat",
    [string]$Subject = "heartbeat",
    [string]$Status = "ok",
    [int]$Retries = 2
)
$ErrorActionPreference = "Stop"
$allowed = @("heartbeat", "notify", "linear", "github", "gmail_draft", "route")
if ($allowed -notcontains $Action) { $Action = "notify" }
if (-not (Test-Path $ConfigPath)) { Write-Error "Missing $ConfigPath" }
$config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json
if (-not $config.webhook_url -or $config.webhook_url -like "PASTE_*") { Write-Error "Set webhook_url" }
$now = [DateTimeOffset]::UtcNow.ToString("o")
$packet = [ordered]@{ from_agent=$config.from_agent; to_agent="comms-bus"; channel="webhook"; action=$Action; subject=$Subject; lane="civic"; timestamp=$now; packet_id="hb-$($config.device)-$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"; payload=[ordered]@{ device=$config.device; agents=@("heartbeat"); status=$Status; queue=0; year=2026 } }
$body = $packet | ConvertTo-Json -Depth 6 -Compress
$attempt = 0
while ($true) {
    $attempt++
    try {
        $res = Invoke-RestMethod -Method Post -Uri $config.webhook_url -ContentType "application/json; charset=utf-8" -Body $body -TimeoutSec 30
        ([ordered]@{ ok=$true; at=$now; device=$config.device }) | ConvertTo-Json | Set-Content (Join-Path $PSScriptRoot "last-heartbeat.json") -Encoding utf8
        $res | ConvertTo-Json -Depth 6
        break
    } catch {
        if ($attempt -gt $Retries) { Write-Error $_; exit 1 }
        Start-Sleep -Seconds (3 * $attempt)
    }
}
