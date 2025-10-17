# Article Analysis: Pangolin Reverse Proxy for Home Labs

**Source**: https://www.virtualizationhowto.com/2025/09/why-pangolin-is-the-one-reverse-proxy-id-pick-if-i-was-starting-my-home-lab-today/  
**Date**: September 29, 2025  
**Category**: Home Lab  
**Author**: Brandon Lee

## Executive Summary

Pangolin is an advanced open-source reverse proxy that combines the simplicity of Nginx Proxy Manager with enterprise features like clustering, cloud coordination, and hybrid tunneling. It represents a next-generation approach to home lab networking, offering both basic SSL termination and advanced multi-node failover capabilities managed through a cloud control plane.

## Key Technical Components

### Core Architecture
- **Base Technology**: Built on Traefik reverse proxy
- **Container Stack**:
  - `traefik` - HTTP/HTTPS routing engine
  - `pangolin` - Main control plane and API
  - `gerbil` - WireGuard and UDP ingress handler
- **Management**: Cloud-managed dashboard (optional local mode available)
- **Network**: SSL termination on ports 80/443

### Advanced Features
1. **Multi-Node Clustering**: Unlike NPM's single-node limitation, supports distributed deployment
2. **Cloud Coordination**: Automatic DNS and failover orchestration
3. **Tunneling (Newt Agent)**: Secure tunneling to remote networks without port forwarding
4. **Hybrid Deployment**: Can function as simple reverse proxy or full distributed system

## Windows 11 Customization Implications

### 1. Network Infrastructure Modernization
**Pattern**: Infrastructure-as-Code for network services

**Implementation Strategy**:
```yaml
# Pangolin replaces manual IIS/WinNAT reverse proxy configurations
Services:
  - Traditional: IIS reverse proxy + manual SSL management
  - Modern: Pangolin container with automatic Let's Encrypt
  
Governance:
  - Automated certificate lifecycle (90-day renewal)
  - Version-controlled proxy configurations
  - Blockchain-auditable routing changes
```

**Ceremony Integration**:
- **Foundation Ceremony**: Replace IIS reverse proxy with Pangolin during network setup
- **Network Ceremony**: Automated CNAME record validation and SSL provisioning
- **Audit Ceremony**: Log all proxy configuration changes to blockchain

### 2. Containerization of Windows Network Services
**Current Pain Point**: Windows Server roles (IIS, routing) require full OS installations

**Pangolin Solution**:
- Deploy as Windows container or WSL2 Docker
- Eliminates need for dedicated Windows Server VMs for reverse proxy
- Reduces attack surface (container vs full Windows Server)

**Automation Script**:
```powershell
# Add to ceremonies/03-network/Deploy-Pangolin.ps1
function Install-PangolinProxy {
    param(
        [string]$CloudManaged = $true,
        [string]$Domain
    )
    
    # Pull Pangolin installer
    Invoke-WebRequest -Uri "https://digpangolin.com/get-installer.sh" `
        -OutFile "C:\civic-infrastructure\pangolin-installer.sh"
    
    # Deploy via WSL2
    wsl bash -c "bash C:\civic-infrastructure\pangolin-installer.sh"
    
    # Log to blockchain
    Add-BlockchainRecord -Action "Pangolin Deployed" `
        -Metadata @{ Domain = $Domain; CloudManaged = $CloudManaged }
}
```

### 3. Self-Healing Network Layer
**Pangolin's Clustering** enables Windows 11 civic infrastructure to have:

- **Failover**: If primary node fails, traffic auto-routes to secondary
- **Zero-Downtime Updates**: Rolling updates across Pangolin nodes
- **Geographic Distribution**: Newt tunneling connects remote Windows instances

**Civic Infrastructure Application**:
```
Primary Workstation (C:\civic-infrastructure)
├── Pangolin Node 1 (main proxy, local)
├── Evidence Server (tunneled via Newt)
└── Backup Node (secondary location)

Cloud Coordination automatically handles:
- DNS updates if primary IP changes
- Certificate renewals across all nodes
- Traffic routing based on node health
```

### 4. Governance-Anchored Proxy Configuration
**Challenge**: Traditional proxies lack audit trails for configuration changes

**Pangolin + Blockchain Integration**:
```json
{
  "action": "Proxy Route Added",
  "timestamp": "2025-09-29T12:00:00Z",
  "route": {
    "domain": "civic-evidence.local",
    "backend": "192.168.1.100:8080",
    "ssl": "auto-renewed"
  },
  "previous_hash": "abc123...",
  "record_hash": "def456..."
}
```

Every proxy configuration change logged to `council_ledger.jsonl` with cryptographic verification.

## Comparison with Existing Solutions

| Feature | Nginx Proxy Manager | Traefik | Caddy | **Pangolin** |
|---------|---------------------|---------|-------|-------------|
| **Web UI** | ✅ Simple | ❌ File-based | ❌ File-based | ✅ Cloud Dashboard |
| **Auto SSL** | ✅ Let's Encrypt | ✅ LE/ACME | ✅ Auto HTTPS | ✅ Auto + Multi-node |
| **Clustering** | ❌ Single node | ⚠️ Complex | ⚠️ Limited | ✅ Native support |
| **Tunneling** | ❌ No | ❌ No | ❌ No | ✅ Newt agent |
| **Cloud Coordination** | ❌ No | ❌ No | ❌ No | ✅ Built-in |
| **Windows Support** | ✅ Docker | ✅ Docker | ✅ Docker/Native | ✅ Docker/WSL2 |
| **Governance Ready** | ⚠️ Manual logs | ⚠️ Manual logs | ⚠️ Manual logs | ✅ API + audit hooks |

**Pangolin's Advantages**:
1. NPM-like simplicity with enterprise features
2. Cloud management eliminates local config drift
3. Newt tunneling removes port forwarding security risks
4. Multi-node setup provides true high availability

## Implementation Roadmap for Civic Infrastructure

### Phase 1: Basic Deployment (Week 1)
**Goal**: Replace any existing reverse proxy with Pangolin

```powershell
# ceremonies/03-network/01-Install-Pangolin.ps1
- Install Docker Desktop on Windows 11
- Pull Pangolin quick installer
- Deploy with cloud management
- Configure first domain (e.g., civic-evidence.local)
- Test SSL certificate auto-provisioning
- Log deployment to blockchain
```

**Expected Outcome**:
- Pangolin running in Docker on Windows 11
- One domain configured with auto-renewed SSL
- Blockchain record created for deployment

### Phase 2: Multi-Node Clustering (Week 2-3)
**Goal**: Add redundancy with secondary Pangolin node

```powershell
# ceremonies/03-network/02-Add-Secondary-Node.ps1
- Deploy second Pangolin instance (different machine or WSL container)
- Adopt node in Pangolin cloud dashboard
- Configure same domains on both nodes
- Test failover (stop Node 1, verify Node 2 takes over)
- Document failover SLA (expected downtime: < 30 seconds)
```

**Expected Outcome**:
- Two Pangolin nodes operational
- Automatic failover tested and verified
- Zero downtime during simulated node failure

### Phase 3: Newt Tunneling (Week 4)
**Goal**: Securely expose remote Windows instances without port forwarding

```powershell
# ceremonies/03-network/03-Deploy-Newt-Tunnel.ps1
- Install Newt agent on remote Windows 11 machine
- Configure tunnel back to Pangolin cluster
- Expose remote evidence server via tunnel
- Test access (should work without opening firewall ports)
- Monitor tunnel health metrics
```

**Expected Outcome**:
- Remote services accessible via Pangolin
- No inbound firewall rules required on remote machine
- Encrypted WireGuard tunnel established

### Phase 4: Integration with Evidence System (Week 5-6)
**Goal**: Route all civic infrastructure services through Pangolin

```
Domains to configure:
- civic-evidence.yourdomain.com → Evidence storage API
- civic-blockchain.yourdomain.com → Blockchain explorer UI
- civic-n8n.yourdomain.com → n8n automation dashboard
- civic-monitor.yourdomain.com → System health monitoring

All domains:
✅ Auto-renewed SSL certificates
✅ Logged to blockchain on creation
✅ Multi-node failover enabled
✅ Accessible via cloud dashboard
```

## Best Practices for Windows 11 Implementation

### 1. Docker Configuration
```yaml
# Use WSL2 backend for optimal Linux container performance
Docker Desktop Settings:
  - Use WSL2 engine: ✅
  - Resource limits: 8GB RAM, 4 CPUs (adjust based on hardware)
  - File sharing: Enable for C:\civic-infrastructure
  - Start Docker on Windows startup: ✅
```

### 2. DNS Management
**Choice**: CNAME vs NS Delegation

- **CNAME (Recommended for home lab)**:
  - Point `civic-evidence.domain.com` → `pangolin-cname-[ID].ingress.pangolin.fossorial.io`
  - Easy to set up, works with dynamic IPs
  - Suitable for individual subdomains

- **NS Delegation (For production)**:
  - Delegate entire subdomain (`civic.domain.com`) to Pangolin nameservers
  - Enables full zone control
  - Requires static IP or dynamic DNS integration

### 3. Security Hardening
```powershell
# ceremonies/03-network/04-Harden-Pangolin.ps1

# 1. Restrict cloud dashboard access
Set-PangolinFirewall -AllowFrom @("192.168.1.0/24", "YourPublicIP")

# 2. Enable audit logging
Enable-PangolinAuditLog -Destination "C:\civic-infrastructure\logs\pangolin-audit.jsonl"

# 3. Rotate node secrets quarterly
Schedule-PangolinSecretRotation -Interval 90

# 4. Monitor certificate expiry
New-ScheduledTask -TaskName "Monitor Pangolin Certs" `
    -Script "C:\civic-infrastructure\scripts\Monitor-PangolinCerts.ps1" `
    -Schedule Daily -Time 03:00
```

### 4. Blockchain Integration Points
```json
// Events to log to council_ledger.jsonl
{
  "events": [
    "Pangolin Node Deployed",
    "Domain Added",
    "SSL Certificate Issued",
    "SSL Certificate Renewed",
    "Node Failover Occurred",
    "Configuration Changed",
    "Newt Tunnel Established",
    "Security Alert (unauthorized access attempt)"
  ]
}
```

Each event includes:
- Timestamp (ISO 8601)
- Action description
- Metadata (domain, certificate ID, node ID)
- Previous record hash (blockchain linkage)
- Current record hash (SHA256)

## Monitoring and Observability

### Metrics to Track
```yaml
Pangolin Health Metrics:
  - Node uptime (target: 99.9%)
  - Certificate renewal success rate (target: 100%)
  - Request latency (target: < 100ms)
  - Failover time (target: < 30 seconds)
  - Newt tunnel stability (target: 99.5% uptime)

Integration with civic-infrastructure:
  - Export metrics to evidence/ directory
  - Daily reports generated by n8n
  - Anomalies trigger Discord alerts
  - Monthly summaries added to blockchain
```

### n8n Workflow Integration
**Workflow**: Pangolin Health Monitoring

```
[Schedule: Every 15 minutes]
    ↓
[HTTP Request: Query Pangolin API]
    ↓
[If: Node count < 2 or Certificate expiring < 7 days]
    ↓
[Discord Webhook: Alert channel]
    ↓
[Append to logs/pangolin-health.jsonl]
    ↓
[If: Critical issue]
    ↓
[Add Blockchain Record: Security Alert]
```

## Migration Path from Existing Proxies

### From Nginx Proxy Manager
```powershell
# Export NPM configuration
docker exec npm-container npm export > npm-config.json

# Analyze routes
$routes = Get-Content npm-config.json | ConvertFrom-Json

# Recreate in Pangolin
foreach ($route in $routes.proxy_hosts) {
    New-PangolinResource `
        -Domain $route.domain_names[0] `
        -Backend "$($route.forward_host):$($route.forward_port)" `
        -SSL Auto
}

# Log migration
Add-BlockchainRecord -Action "Migrated from NPM to Pangolin" `
    -Metadata @{ RoutesCount = $routes.Count }
```

### From Traefik
```yaml
# Traefik routes are file-based
# Create Pangolin resources via API for each Traefik route

Migration Benefits:
  - No more YAML file management
  - Cloud dashboard replaces file editing
  - Built-in clustering (vs complex Traefik setup)
  - Automatic certificate management (vs manual ACME config)
```

## Cost Analysis

| Item | Monthly Cost | Notes |
|------|--------------|-------|
| **Pangolin Free Tier** | $0 | 1 managed node, unlimited local nodes |
| **Pangolin Pro** | $9/month | 3 managed nodes, SSO, advanced auth |
| **Pangolin Business** | $29/month | Unlimited nodes, white-label, priority support |
| **Domain Registration** | ~$1/month | For custom domains (one-time ~$12/year) |
| **Let's Encrypt SSL** | $0 | Free automated certificates |
| **Cloud Storage (backup)** | ~$1/month | Azure Blob for config backups |

**Total for Home Lab**: $0-10/month (Free tier sufficient for most home labs)

**Comparison**:
- NPM: $0 (but lacks clustering, cloud management)
- Traefik: $0 (but higher operational complexity)
- Cloudflare Tunnel: $0 (but vendor lock-in, limited customization)
- **Pangolin**: $0-9 (best balance of features and cost)

## Recommendations

### For Civic Infrastructure Project
**PRIORITY: HIGH**

**Why Deploy Pangolin**:
1. **Governance**: Cloud API enables blockchain audit of all proxy changes
2. **Resilience**: Multi-node failover ensures evidence server is always accessible
3. **Security**: Newt tunneling eliminates exposed ports on Windows 11 firewall
4. **Automation**: Integrates cleanly with n8n workflows (API-first design)
5. **Modern**: Represents 2025 best practices vs legacy IIS/NPM approaches

**Recommended Tier**: **Free** (1 managed node + unlimited local nodes)
- Sufficient for home lab use
- Can upgrade to Pro if SSO or >1 managed node needed
- Local-only mode available if cloud management not desired

### Quick Win Ceremony
**Title**: "Pangolin Reverse Proxy Deployment"

**Duration**: 2-3 hours

**Steps**:
1. Install Docker Desktop on Windows 11 (30 min)
2. Deploy Pangolin via quick installer (15 min)
3. Configure first domain with auto SSL (30 min)
4. Test failover with second node (45 min)
5. Document configuration in evidence/ (30 min)
6. Log to blockchain (15 min)

**Outcome**:
- Production-ready reverse proxy with HA
- SSL certificates auto-renewed
- Blockchain-audited deployment
- Foundation for all civic services

### Integration Points with Existing Work
```
october-2025/implementation-roadmap.md:
  → Add "Pangolin Reverse Proxy" to Phase 3: Network Infrastructure

docker/n8n/:
  → Create workflow: "Pangolin Health Monitoring"
  → Create workflow: "Pangolin Cert Renewal Alerts"

evidence/:
  → Store Pangolin config backups
  → Log all route changes with SHA256 hashes

logs/council_ledger.jsonl:
  → Record Pangolin deployments, config changes, failovers
```

## Technical Deep Dive: Newt Tunneling

### How Newt Works
```
Remote Windows 11 Machine (behind NAT)
├── Newt Agent (WireGuard client)
└── Local Service (e.g., evidence API on :8080)

          ↓ Encrypted tunnel (outbound only)

Pangolin Cloud (fossorial.io)
├── Route traffic to Newt tunnel
└── Present as: civic-evidence.domain.com

          ↓ SSL-terminated traffic

End User
└── Accesses https://civic-evidence.domain.com
    (Appears as normal HTTPS site, actually tunneled)
```

**Security Benefits**:
1. **No Inbound Firewall Rules**: All traffic outbound from Newt agent
2. **Encrypted Transport**: WireGuard encryption (same as VPN)
3. **Access Control**: Managed via Pangolin dashboard (can restrict by IP)
4. **Certificate Management**: SSL certs handled by Pangolin (not exposed on remote machine)

**Use Cases for Civic Infrastructure**:
- **Distributed Evidence Nodes**: Multiple Windows 11 machines, all accessible via centralized Pangolin
- **Backup Sites**: Secondary location with Newt tunnel (automatic failover)
- **Developer Access**: Securely expose local dev environment without port forwarding

## Conclusion

Pangolin represents a paradigm shift in home lab reverse proxies, combining the simplicity of Nginx Proxy Manager with enterprise-grade clustering and cloud coordination. For the Windows 11 civic infrastructure project, it provides:

1. **Immediate Value**: Replace IIS/manual reverse proxy with automated SSL and cloud dashboard
2. **Long-Term Scalability**: Multi-node clustering grows with infrastructure needs
3. **Governance Alignment**: API-first design enables blockchain audit trails
4. **Modern Architecture**: Container-based, cloud-coordinated, self-healing

**Recommendation**: **DEPLOY IMMEDIATELY** as part of Network Ceremony. Pangolin is the foundation for all civic services' external access.

---

**Next Steps**:
1. Create `ceremonies/03-network/Deploy-Pangolin.ps1`
2. Test deployment on Windows 11 VM
3. Configure first domain (civic-n8n.local for testing)
4. Document in QUICK-START.md
5. Log deployment to blockchain
6. Create n8n health monitoring workflow

**Estimated Timeline**: 1 week to full deployment with HA

**Risk Level**: LOW (well-documented, active community, simple rollback via Docker)

**Priority**: HIGH (blocks external access to civic services)

---

*Analysis completed as part of September 2025 civic infrastructure research.*  
*See `september-2025/implementation-roadmap.md` for full integration plan.*
