# 2.1 Hardware Requirements

## Minimum Specifications

- CPU: x86_64 processor with virtualization support (Intel VT-x or AMD-V)
- RAM: 4GB minimum (8GB+ recommended for virtualization workloads)
- Storage: 25GB minimum NVMe SSD
- Network: Single Gigabit Ethernet adapter

## Recommended for Production

- CPU: Multi-core processor with VT-x/AMD-V and VT-d/AMD-Vi (for I/O virtualization)
- RAM: 16GB+ (depending on workload)
- Storage: NVMe SSD (motherboard M.2 slot)
- Network: Single Gigabit Ethernet

## Virtualization Requirements

For running virtual machines (KVM/QEMU), the following CPU features are required:

| Feature | Intel | AMD | Purpose |
|---------|-------|-----|---------|
| CPU Virtualization | VT-x | AMD-V | Basic VM support |
| I/O Virtualization | VT-d | AMD-Vi | PCIe passthrough |
| Nested Virtualization | VMX | SVM | VMs inside VMs |

## Storage Considerations

This deployment uses a **single disk** configuration with ext4 for the root filesystem. The host OS is intentionally disposable - recovery is achieved by rebuilding from autoinstall media, not hardware redundancy.

| Component | Strategy |
|-----------|----------|
| OS/Host | Rebuild from autoinstall media (ext4 root) |
| Configuration | Version-controlled in this repository |
| VMs | Restore from backup, or use separate ZFS pool with redundancy |

**Disk Selection:** Autoinstall selects the largest available disk. See [5.2 Autoinstall Configuration](../AUTOINSTALL_MEDIA_CREATION/AUTOINSTALL_CONFIGURATION.md) for disk matching options.

**Future VM Storage:** When additional drives are added, create a separate ZFS pool with RAIDZ for VM storage redundancy. See [6.10 Virtualization Fragment](../CLOUD_INIT_CONFIGURATION/VIRTUALIZATION_FRAGMENT.md).
