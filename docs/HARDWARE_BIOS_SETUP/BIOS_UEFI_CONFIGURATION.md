# 2.3 BIOS/UEFI Configuration

## Accessing BIOS

Reboot and press the appropriate key (varies by manufacturer):
- Dell: F2
- HP: F10
- Lenovo: F1
- Supermicro: DEL
- Generic: DEL, F2, F10, or F12

## Critical BIOS Settings

### 1. Boot Settings
- Boot Mode: UEFI (recommended) or Legacy BIOS
- Secure Boot: Disabled (or configure for Ubuntu)
- Boot Order: USB/Removable Media first

### 2. Virtualization Support (CRITICAL)
- Intel Virtualization Technology (VT-x): **Enabled**
- Intel VT-d (I/O virtualization): **Enabled**
- AMD-V (AMD virtualization): **Enabled**
- AMD-Vi (AMD I/O virtualization): **Enabled**

**Note:** These settings may be found under:
- Advanced → CPU Configuration
- System Configuration → Virtualization Technology
- Processor → Intel Virtualization Technology

### 3. Power Management
- Power Profile: Maximum Performance (for servers)
- CPU C-States: May need adjustment based on workload
- Wake on LAN: Enabled (if needed for remote management)

### 4. Storage Configuration
- SATA Mode: AHCI (for better performance and compatibility)
- RAID Mode: If using hardware RAID, configure arrays now

### 5. Network Settings
- PXE Boot: Disabled (unless needed)
- Wake on LAN: Configure as needed
- Network Stack: IPv4 and/or IPv6 as required

## BIOS Configuration Checklist

- [x] Boot mode set to UEFI
- [x] Virtualization extensions enabled (VT-x/AMD-V)
- [x] I/O virtualization enabled (VT-d/AMD-Vi)
- [x] Boot order configured (USB first)
- [x] Secure Boot configured or disabled
- [ ] ~~RAID arrays configured (if applicable)~~
- [x] Power management optimized
- [x] Save BIOS settings and verify on reboot

## Vendor-Specific Notes

### Dell PowerEdge
- Access via F2 during POST
- Virtualization settings under "Processor Settings"
- RAID configuration via Ctrl+R or UEFI RAID config

### HP ProLiant
- Access via F10 during POST
- Use "Intelligent Provisioning" for advanced config
- iLO for remote management

### Supermicro
- Access via DEL during POST
- Virtualization under "Advanced" → "CPU Configuration"
- IPMI for remote management
