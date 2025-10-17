# September 2025 — Implementation Roadmap

**Analysis Date**: 2025-10-17
**Articles Analyzed**: 10/10

## Objective

Turn September article insights into a prioritized, timeboxed implementation plan for the civic infrastructure project.

## Priority Workstreams (6-8 weeks)

### 1. Reverse Proxy Modernization (Pangolin / NPMplus) — 2 weeks

- Goal: Standardize ingress, enable clustering, and integrate audit logging.
- Tasks:
  - Deploy Pangolin in Docker (week 1)
  - Migrate existing proxy routes (week 1)
  - Add secondary node and test failover (week 2)
  - Configure n8n health-check workflow and blockchain logging

### 2. Core Service Foundation (DNS, DHCP, Monitoring) — 1 week

- Goal: Deploy DNS/DHCP and monitoring (Netdata) to ensure observability.
- Tasks:
  - Deploy DNS service in foundation VLAN
  - Deploy Netdata and Dozzle for container logs
  - n8n scheduled monitoring workflows

### 3. Hardware & Storage Upgrades (Mini PC + NAS) — 2 weeks

- Goal: Implement Tier-2 hardware plan (Geekom mini PC + TerraMaster NAS)
- Tasks:
  - Procure MINIX/Geekom units and TerraMaster NAS
  - Configure UPS and graceful shutdown scripts
  - Set up NAS for evidence storage and backups to Azure Blob

### 4. GPU & AI Testbeds (PECU + Ollama/MCP) — 1-2 weeks

- Goal: Prepare GPU-enabled test nodes and local AI stack.
- Tasks:
  - Use PECU to enable GPU passthrough on Proxmox test nodes
  - Deploy Ollama or LocalAI containers for inference
  - Create n8n triggers for scheduled AI analysis runs

### 5. Security & Hardening (OPNsense, CrowdSec) — 1 week

- Goal: Harden perimeter and add intrusion detection.
- Tasks:
  - Deploy OPNsense and configure firewall rules and plugins
  - Integrate CrowdSec with reverse proxy where possible
  - Schedule weekly audit ceremonies and blockchain logging

## Deliverables

- `september-2025/implementation-roadmap.md` (this file)
- `september-2025/executive-summary.md`
- `september-2025/articles/*` (10 article analyses)
- `SEPTEMBER-REPORT.md` (final summary)
- n8n workflows for monitoring and scheduled AI runs

## Acceptance Criteria

- Reverse proxy supports automatic SSL and failover
- Evidence storage is backed up weekly to Azure Blob
- Monitoring sends alerts to Discord for critical events
- GPU testbed can run basic model inference locally
- Blockchain record #11 appended with summary hash

_Generated automatically by Analyze-September-2025 workflow._
