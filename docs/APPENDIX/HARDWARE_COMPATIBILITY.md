# 11.4 Hardware Compatibility

## Check Ubuntu Hardware Compatibility

- **Ubuntu Certified Hardware**: https://ubuntu.com/certified
- **Hardware Probe Database**: https://linux-hardware.org/

## Verify Before Purchase

- Network card Linux driver support
- RAID controller compatibility
- GPU support (if needed for GPU passthrough)

## Common Compatible Hardware

### Server Vendors
- Dell PowerEdge
- HP ProLiant
- Lenovo ThinkSystem
- Supermicro

### Network Cards
- Intel I210/I350 (well supported)
- Mellanox ConnectX (well supported)
- Broadcom NetXtreme

### RAID Controllers
- LSI/Broadcom MegaRAID
- Dell PERC (PowerEdge RAID Controller)
- HP Smart Array

### Storage
- Samsung Enterprise SSDs
- Intel Optane
- Western Digital Enterprise

## Virtualization Requirements

| Feature | Intel | AMD |
|---------|-------|-----|
| Basic Virtualization | VT-x | AMD-V |
| I/O Virtualization | VT-d | AMD-Vi |
| Nested Virtualization | VMX | SVM |

## Checking Compatibility

```bash
# Check CPU virtualization support
egrep -c '(vmx|svm)' /proc/cpuinfo

# Validate virtualization
virt-host-validate

# Check hardware details
lspci
lsusb
lscpu
```

## Known Issues

- Some consumer NICs may lack driver support
- Consumer RAID controllers may not support Linux
- Ensure server firmware is up to date before deployment
