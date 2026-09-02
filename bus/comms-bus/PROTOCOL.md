# Comms bus 2026

Lane: civic only. Cloud never executes civic ceremonies (`run_ceremony`, `execute_ceremony`).

Webhook URL lives on the Grok Automations card for `comms-bus-webhook` only.

Tracking: Linear SVE-5 · GitHub #2 · PR #3

## Device

1. `config.example.json` → `config.json`, paste webhook URL.
2. `.\heartbeat.ps1` or `./heartbeat.sh`
3. Optional: `.\install-scheduled-task.ps1` (15 min)
4. Optional: `.\outbox-watch.ps1` against `bus/outbox`

## Packet actions

Grok hops: heartbeat notify linear github gmail_draft route
Civic native packets are notify-only. Never run PowerShell from the packet.
