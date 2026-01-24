# 4.2 Network Topology Considerations

## Configuration: Single NIC

This deployment uses a single NIC configuration:

- Single NIC connected directly to network
- Host serves as a KVM hypervisor
- VM networking architecture is out of scope for this deployment

## Network Detection

Since NIC names vary by hardware (e.g., `enp0s3`, `eno1`, `eth0`), the deployment uses ARP probing to detect the correct interface at runtime. See [4.3 Network Scripts](./NETWORK_SCRIPTS.md) for details.
