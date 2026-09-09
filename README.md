# Civic Infrastructure — Cross-Platform Autonomous System

Reproducible, auditable civic infrastructure with a portable AI orchestration layer that runs on **Windows, Linux, macOS, Docker, and Kubernetes**.

Windows-specific ceremonies (registry, ISO image builds, Group Policy) remain available on Windows hosts and are capability-gated elsewhere.

## Quick start (any OS)

```bash
# Capability check
./civic check

# Native host (PowerShell 7+)
./civic host --light

# Docker Compose
cp docker/.env.example docker/.env   # edit password for full profile
./civic docker --light               # orchestrator only
./civic docker                       # orchestrator + Ollama + n8n

# Kubernetes (Helm)
./civic kubernetes --light
```

PowerShell (Windows / pwsh everywhere):

```powershell
.\civic.ps1 check
.\civic.ps1 host -LightMode
.\civic.ps1 docker -LightMode
.\civic.ps1 kubernetes -LightMode
```

See **[platform/README.md](platform/README.md)** for the capability matrix and layout.

## Platform support

| Target | How to run |
|--------|------------|
| Windows 11 / Server | `.\civic.ps1 host` + optional Windows ceremonies under `scripts/ceremonies/` |
| Linux | `./civic host` or systemd via `Install-CivicService.ps1` |
| macOS | `./civic host` or launchd via `Install-CivicService.ps1` |
| Docker | `docker compose -f docker/docker-compose.yml --profile light\|full up -d` |
| Kubernetes | Helm chart `deploy/kubernetes/helm/civic-infrastructure` or plain YAML under `deploy/kubernetes/plain/` |
| CI / Cloud Agents | `.cursor/install.sh` provisions pwsh + env shims |

## AI Autonomous System (portable core)

```powershell
# Prefer the cross-platform bootstrap; legacy Windows installer still works:
.\scripts\ai-system\Initialize-AIAutonomousSystem.ps1 -LightMode -SkipOllamaInstall
```

Docs:

- [AI System Quick Start](AI-SYSTEM-QUICKSTART.md)
- [AI System Complete Guide](AI-AUTONOMOUS-SYSTEM-GUIDE.md)
- [Platform runtime](platform/README.md)

## Ceremony layers (Windows host)

1. Foundation — Installation & Provisioning  
2. System Identity & Governance  
3. Operational Hygiene  
4. Performance & Resource Control  
5. Developer Cockpit  
6. UI & Ritual Layer  
7. Observability & Audit  
8. Resilience & Recovery  

```powershell
.\scripts\ceremonies\01-foundation\Initialize-Foundation.ps1
.\tests\Invoke-ValidationTests.ps1
```

## Layout

```
├── civic / civic.ps1          # Unified CLI
├── platform/                  # OS detection, services (systemd/launchd/Windows)
├── configs/platform/          # Capability matrix
├── scripts/cross-platform/    # Bootstrap + portable orchestrator
├── docker/                    # Multi-arch image + Compose profiles
├── deploy/kubernetes/         # Helm + plain manifests
├── scripts/ceremonies/        # Windows-oriented ceremonies
├── agents/                    # Multi-agent modules
├── council/                   # Mandates & policies
└── terraform/                 # Cloud IaC (Azure, …)
```

## Security notes

- Compose binds published ports to `127.0.0.1` by default.
- Orchestrator container drops capabilities, uses read-only rootfs, and runs as UID 10001.
- Do not commit `docker/.env`; use `docker/.env.example` as the template.

## License

See repository license / governance docs.
