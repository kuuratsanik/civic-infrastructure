# Cross-platform runtime for civic-infrastructure

## What is portable vs Windows-only

| Area | Windows | Linux | macOS | Docker | Kubernetes |
|------|---------|-------|-------|--------|------------|
| AI orchestrator / lineage / consensus | yes | yes | yes | yes | yes |
| Docker Compose stack | yes | yes | yes | n/a | n/a |
| Helm / plain manifests | yes | yes | yes | — | yes |
| Registry / ISO / Win ceremonies | yes | no | no | no | no |

## Quick start

```bash
# Detect + print capability matrix
./civic check

# Native host (needs PowerShell 7+)
./civic host --light

# Docker (light = orchestrator only; full = + ollama + n8n)
cp docker/.env.example docker/.env   # required for --profile full
./civic docker --light

# Kubernetes
./civic kubernetes --light
# or: helm upgrade --install civic deploy/kubernetes/helm/civic-infrastructure -n civic --create-namespace
```

Windows (PowerShell):

```powershell
.\civic.ps1 check
.\civic.ps1 host -LightMode
.\civic.ps1 docker -LightMode
.\civic.ps1 kubernetes -LightMode
```

## Layout

- `platform/Platform.psm1` — OS / container / k8s detection + path helpers
- `configs/platform/capabilities.json` — feature gates per platform
- `scripts/cross-platform/` — bootstrap, orchestrator, service installer
- `docker/` — multi-arch Dockerfile + Compose profiles
- `deploy/kubernetes/` — Helm chart + plain manifests
- `platform/services/` — systemd / launchd / Windows task templates
