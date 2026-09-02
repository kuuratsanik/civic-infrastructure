# Comms bus — this end (done) / other end (later)

Lane: civic only. Do not send ASG / SFR / Unrouted packets here.

## Live Grok jobs

| Name | Task ID | Trigger |
|---|---|---|
| comms-bus-daily | aec7c79a-19ea-4f60-8f17-127189813f04 | 08:30 Europe/Tallinn |
| comms-bus-gmail | 09b2da78-6d21-4af3-906b-6c5e67cb5f24 | subject AGENT-COMMS / COMMS-BUS / ROUTE-ME |
| comms-bus-outlook | 34d79415-8052-418d-8008-a8744137d0ce | same subject tokens |
| comms-bus-linear | 519a697d-fcad-4cbd-a1f9-dfc0e49c422c | SVE assigned to me |
| comms-bus-github | 98e1e8f3-24a5-4f9c-9845-fb76795658b2 | comment on civic-infrastructure |
| comms-bus-webhook | 3bedb9e5-1526-46f3-8086-f377805dec49 | signed POST |

Webhook URL is on the Grok Automations card for `comms-bus-webhook`. The list API does not return it.

## Finish on the device

1. Copy `config.example.json` → `config.json`.
2. Paste `webhook_url`. Never commit `config.json`.
3. Windows: `.\heartbeat.ps1`
4. Linux/mac: `chmod +x heartbeat.sh && ./heartbeat.sh`
5. Optional: Task Scheduler / cron every 900 seconds.
6. Optional: `outbox-watch.ps1` against `bus/outbox`.

## Actions the cloud will honor

- `heartbeat` / `notify` — chat note
- `linear` — SVE issue if payload has title/body
- `github` — comment only if payload has issue_number on kuuratsanik/civic-infrastructure
- `gmail_draft` — draft to sven.katkosilt@gmail.com, no send
- `route` — cheapest safe hop

Cloud will not: run shell from payload, spend money, deploy, resume `db368212-033d-46d5-bb26-eb0b12d235a4`, or touch fiction DBs.
