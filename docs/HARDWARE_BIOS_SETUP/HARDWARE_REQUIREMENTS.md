# 2.1 Hardware Requirements

## Minimum Specifications

- CPU: x86_64 processor with virtualization support (Intel VT-x or AMD-V)
- RAM: 4GB minimum (8GB+ recommended for virtualization workloads)
- Storage: 25GB minimum (SSD recommended)
- Network: Gigabit Ethernet adapter

## Recommended for Production

- CPU: Multi-core processor with VT-x/AMD-V and VT-d/AMD-Vi (for I/O virtualization)
- RAM: 16GB+ (depending on workload)
- Storage:
  - RAID configuration for redundancy (RAID 1 for OS, RAID 10 for data)
  - NVMe SSD for optimal performance
- Network: Dual NICs for bonding/redundancy

## Virtualization Requirements

For running virtual machines (KVM/QEMU), the following CPU features are required:

| Feature | Intel | AMD | Purpose |
|---------|-------|-----|---------|
| CPU Virtualization | VT-x | AMD-V | Basic VM support |
| I/O Virtualization | VT-d | AMD-Vi | PCIe passthrough |
| Nested Virtualization | VMX | SVM | VMs inside VMs |

## Storage Considerations

| Use Case | Recommended Configuration |
|----------|--------------------------|
| Development | Single SSD, no RAID |
| Production (basic) | RAID 1 (mirror) for OS |
| Production (performance) | RAID 10 for OS + data |
| Production (capacity) | RAID 1 for OS, RAID 6 for data |
