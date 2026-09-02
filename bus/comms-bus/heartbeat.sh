#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="${1:-$DIR/config.json}"
ACTION="${2:-heartbeat}"
SUBJECT="${3:-heartbeat}"
STATUS="${4:-ok}"
if [[ ! -f "$CONFIG" ]]; then
  echo "Missing $CONFIG — copy config.example.json to config.json" >&2
  exit 1
fi
python3 - "$CONFIG" "$ACTION" "$SUBJECT" "$STATUS" <<'PY'
import json, sys, urllib.request
cfg_path, action, subject, status = sys.argv[1:5]
cfg = json.load(open(cfg_path))
url = cfg.get("webhook_url", "")
if not url or url.startswith("PASTE_"):
    sys.exit("Set webhook_url in config.json from the comms-bus-webhook card.")
packet = {
    "from_agent": cfg.get("from_agent", "unknown-device"),
    "to_agent": "comms-bus",
    "channel": "webhook",
    "action": action,
    "subject": subject,
    "lane": "civic",
    "payload": {
        "device": cfg.get("device", "unknown"),
        "agents": ["heartbeat"],
        "status": status,
        "queue": 0,
    },
}
data = json.dumps(packet).encode()
req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
with urllib.request.urlopen(req, timeout=30) as resp:
    print(resp.status, resp.read().decode()[:2000])
PY
