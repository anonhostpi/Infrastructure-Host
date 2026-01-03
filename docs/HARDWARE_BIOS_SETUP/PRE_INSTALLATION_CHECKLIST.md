# 2.2 Pre-Installation Hardware Checklist

Complete these checks before beginning installation.

## Checklist

- [x] Verify CPU supports virtualization extensions
  ```bash
  # On existing Linux system, check CPU flags
  grep -E 'vmx|svm' /proc/cpuinfo
  ```
- [x] Test all RAM modules (use memtest86+ if available)
- [x] Verify target disk is the largest disk in the system
- [x] Verify NIC is recognized
- [x] Document MAC address for network planning

## CPU Verification

To verify virtualization support on an existing Linux system:

```bash
# Check for Intel VT-x (vmx) or AMD-V (svm)
grep -E 'vmx|svm' /proc/cpuinfo

# Count virtualization-capable cores
egrep -c '(vmx|svm)' /proc/cpuinfo
```

If no output, virtualization may be disabled in BIOS or unsupported by the CPU.

## Memory Testing

Before production deployment, test RAM with memtest86+:
1. Download memtest86+ from https://www.memtest.org/
2. Create bootable USB
3. Run full test (several hours)
4. Replace any modules that show errors

## Network Documentation

Document the NIC:
- MAC Address
- Port location (physical label)
- Connected switch/port

Example:
```
NIC: AA:BB:CC:DD:EE:01 - Port 1 - Switch A/Port 24
```
