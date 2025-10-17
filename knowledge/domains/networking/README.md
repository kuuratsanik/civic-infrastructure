# Networking Knowledge Domain

**Domain**: Network Architecture & Design  
**Last Updated**: October 17, 2025

## Overview

This domain covers network protocols, architecture, design patterns, and optimization strategies.

## Key Topics

### 1. Network Fundamentals
- OSI Model
- TCP/IP stack
- IP addressing and subnetting
- DHCP and DNS
- NAT and port forwarding

### 2. Network Protocols
- **Transport**: TCP, UDP, QUIC
- **Application**: HTTP/HTTPS, FTP, SSH, SMTP
- **Routing**: BGP, OSPF, RIP
- **Management**: SNMP, NetFlow, sFlow
- **Security**: TLS/SSL, IPSec

### 3. Network Architecture
- LAN (Local Area Network)
- WAN (Wide Area Network)
- VLAN design and segmentation
- Network topology
- Redundancy and failover

### 4. Routing & Switching
- Layer 2 switching
- Layer 3 routing
- Static vs dynamic routing
- VLANs and trunking
- Spanning Tree Protocol (STP)

### 5. Load Balancing
- Hardware vs software load balancers
- Load balancing algorithms
- Health checks
- Session persistence
- Global server load balancing (GSLB)

### 6. Network Security
- Firewalls and ACLs
- DDoS mitigation
- Network segmentation
- Intrusion detection/prevention
- Zero Trust networking

### 7. Wireless Networking
- Wi-Fi standards (802.11ax/Wi-Fi 6)
- Access point placement
- Channel planning
- Security (WPA3)
- Mesh networks

### 8. Performance Optimization
- Bandwidth management
- QoS (Quality of Service)
- Traffic shaping
- Latency optimization
- Packet loss mitigation

## Current Focus Areas

1. **Home Lab Networking**: Advanced home network design
2. **VLAN Segmentation**: Isolating services and devices
3. **VPN Solutions**: Secure remote access
4. **Network Monitoring**: Observability and alerting

## Network Design Patterns

### Three-Tier Architecture
1. **Core Layer**: High-speed backbone
2. **Distribution Layer**: Routing and policy enforcement
3. **Access Layer**: End-device connectivity

### Spine-Leaf Architecture
- Scalable data center design
- Consistent latency
- Easy horizontal scaling

### Hub-and-Spoke
- Centralized management
- Simplified routing
- Cost-effective for remote sites

## Essential Network Services

### DNS
- Name resolution
- Split-horizon DNS
- DNS security (DNSSEC)
- Private DNS servers

### DHCP
- Dynamic IP allocation
- Reservations
- Options and scope management
- Failover configuration

### VPN
- Site-to-Site VPN
- Remote Access VPN
- WireGuard
- OpenVPN
- IPSec

## Network Monitoring

### Metrics to Monitor
- Bandwidth utilization
- Packet loss
- Latency/jitter
- Error rates
- Connection states

### Tools
- Wireshark (packet capture)
- iperf3 (performance testing)
- ntopng (traffic analysis)
- Grafana + Prometheus
- PRTG Network Monitor

## Troubleshooting Methodology

1. **Identify the problem**: Gather symptoms
2. **Establish theory**: Determine probable cause
3. **Test the theory**: Validate or refute
4. **Establish plan**: Create action plan
5. **Implement solution**: Execute plan
6. **Verify functionality**: Confirm resolution
7. **Document findings**: Record for future reference

## Performance Considerations

### Bandwidth Planning
- Calculate required bandwidth
- Plan for growth
- Consider peak usage
- Account for overhead

### Latency Reduction
- Minimize hops
- Optimize routing
- Use CDNs
- Geographic distribution

### High Availability
- Redundant links
- Multiple uplinks
- Failover mechanisms
- Load distribution

## Related Blueprints

- [To be added]

## Related Lessons

- [To be added]

## Resources

### Learning Resources
- Cisco Networking Academy
- Network+ certification
- Computer Networking: A Top-Down Approach (book)
- r/networking
- r/homelab

### Tools & Software
- pfSense/OPNsense
- UniFi Network Controller
- MikroTik RouterOS
- OpenWrt
- VyOS

### Standards Organizations
- IEEE (802.x standards)
- IETF (RFC documents)
- ITU-T

### Vendors
- Cisco
- Juniper
- Ubiquiti
- MikroTik
- Aruba

## Integration Points

- **Infrastructure**: Network foundation for all services
- **Security**: Network-level security controls
- **Virtualization**: Virtual network design
- **Cloud**: Hybrid network connectivity

---

**Maintained by**: AI Autonomous System
