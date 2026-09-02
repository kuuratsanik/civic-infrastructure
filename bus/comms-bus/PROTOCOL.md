# Comms bus 2026

Lane: civic only. Cloud never executes civic ceremonies (`run_ceremony`, `execute_ceremony`).

Device is **live** only when `fleet.cloud_ack.at` is newer than 26 hours. A local `last_heartbeat` write is not enough.

## Live Grok jobs

| Name | Task ID | Trigger |
|---|---|---|
| comms-bus-daily | aec7c79a-19ea-4f60-8f17-127189813f04 | 08:30 Europe/Tallinn |
| comms-bus-gmail | 09b2da78-6d21-4af3-906b-6c5e67cb5f24 | AGENT-COMMS / COMMS-BUS / ROUTE-ME |
| comms-bus-outlook | 34d79415-8052-418d-8008-a8744137d0ce | same tokens |
| comms-bus-linear | 519a697d-fcad-4cbd-a1f9-dfc0e49c422c | SVE assigned to me |
| comms-bus-github | 98e1e8f3-24a5-4f9c-9845-fb76795658b2 | civic-infrastructure comments (issue owner = me) |
| comms-bus-github-any | 7d4a7277-ef79-451a-8535-18b938c4a22e | same repo, any author except bots; prompt filters AGENT-COMMS |
| comms-bus-webhook | 3bedb9e5-1526-46f3-8086-f377805dec49 | POST |

Webhook URL lives on the Automations card only.

Tracking: Linear SVE-5 · GitHub #2 · PR #3

## Local gateway

```bash
python3 gateway.py selftest
python3 gateway.py heartbeat
python3 gateway.py mcp
```

Set `webhook_url` and `bus_token` in `config.json`.
