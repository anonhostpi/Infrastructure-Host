# 3.2 Network Topology Considerations

## Single NIC Configuration
- Simplest setup for basic deployments
- Single point of failure
- Suitable for development/testing

## Bonded/Teamed NICs
- Redundancy and/or increased bandwidth
- Common modes:
  - `mode=1` (active-backup) - Failover only
  - `mode=4` (802.3ad/LACP) - Aggregation + failover (requires switch support)
  - `mode=6` (balance-alb) - Adaptive load balancing

### Bonding Mode Comparison

| Mode | Name | Requires Switch Config | Use Case |
|------|------|------------------------|----------|
| 0 | balance-rr | Yes | Load balancing |
| 1 | active-backup | No | Simple failover |
| 2 | balance-xor | Yes | Load balancing |
| 4 | 802.3ad | Yes (LACP) | Aggregation + failover |
| 5 | balance-tlb | No | Outbound load balancing |
| 6 | balance-alb | No | Adaptive load balancing |

## VLAN Configuration
- Tagged VLANs for network segmentation
- Common VLAN separation:
  - Management network (VLAN 10)
  - Production network (VLAN 100)
  - Storage network (VLAN 200)
  - VM traffic (VLAN 300)

## Bridge Configuration (for VMs)
When running virtual machines, a bridge interface allows VMs to communicate on the physical network:

```
Physical NIC (ens18) → Bridge (br0) → Virtual Machines
                          ↓
                    Host connectivity
```
