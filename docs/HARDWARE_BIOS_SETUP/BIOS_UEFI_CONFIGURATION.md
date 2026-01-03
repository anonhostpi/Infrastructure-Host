# 2.3 BIOS/UEFI Configuration

## Accessing BIOS

Reboot and press the appropriate key during POST (commonly DEL, F2, or F10).

## Critical BIOS Settings

### 1. Boot Settings
- Boot Mode: UEFI
- Secure Boot: Disabled (or configure for Ubuntu)
- Boot Order: USB/Removable Media first

### 2. Virtualization Support (CRITICAL)
- Intel Virtualization Technology (VT-x): **Enabled**
- Intel VT-d (I/O virtualization): **Enabled**
- AMD-V (AMD virtualization): **Enabled**
- AMD-Vi (AMD I/O virtualization): **Enabled**

**Note:** These settings are typically found under:
- Advanced → CPU Configuration
- Processor → Virtualization Technology

### 3. Power Management
- Power Profile: Maximum Performance
- CPU C-States: May need adjustment based on workload
- Wake on LAN: Configure as needed

### 4. Network Settings
- PXE Boot: Disabled (unless needed)
- Wake on LAN: Configure as needed

## BIOS Configuration Checklist

- [x] Boot mode set to UEFI
- [x] Virtualization extensions enabled (VT-x/AMD-V)
- [x] I/O virtualization enabled (VT-d/AMD-Vi)
- [x] Boot order configured (USB first)
- [x] Secure Boot configured or disabled
- [x] Power management optimized
- [x] Save BIOS settings and verify on reboot
