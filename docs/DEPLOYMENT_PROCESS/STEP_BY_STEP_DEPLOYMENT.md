# 8.2 Step-by-Step Deployment

Deploy the autoinstall ISO to bare metal hardware.

## Step 1: Prepare Boot Media

### USB Drive

```powershell
# On Windows, use Rufus or similar tool
# Select the autoinstall ISO and write to USB drive
```

### Remote Console (IPMI/iLO/iDRAC)

1. Log into server management interface
2. Open remote console (Java/HTML5)
3. Mount ISO as virtual media

## Step 2: Boot from Installation Media

1. Power on server (or reboot if already on)
2. Press boot menu key during POST:
   - Dell: F11
   - HP: F11
   - Supermicro: F11
   - Generic: F12 or ESC
3. Select USB/CD device from boot menu
4. GRUB menu appears with "Autoinstall Ubuntu Server"

The autoinstall entry will be selected automatically after 5 seconds.

## Step 3: Monitor Autoinstall

The installation proceeds automatically:

1. **Partitioning** - Creates ZFS root layout
2. **Base install** - Installs Ubuntu base system
3. **early-commands** - Runs arping network detection for installer connectivity
4. **Package install** - Installs selected packages
5. **Reboot** - System reboots automatically

**Duration:** 5-15 minutes depending on hardware speed

### What to Watch For

- Disk detection (ensure target disk is found)
- Network connectivity during installation
- No error messages on screen

If errors occur, note the message and check [Chapter 9: Troubleshooting](../TROUBLESHOOTING/OVERVIEW.md).

## Step 4: First Boot - Cloud-init Execution

After reboot:

1. Remove installation media (USB/virtual media)
2. System boots from ZFS root
3. Cloud-init executes automatically

Cloud-init performs:

| Stage | What Happens |
|-------|--------------|
| bootcmd | Arping network detection, writes netplan config |
| Network | Static IP applied via netplan |
| Users | Admin user created with password and SSH key |
| Packages | KVM, libvirt, Cockpit, multipass installed |
| Services | libvirtd, cockpit.socket enabled and started |
| Firewall | UFW enabled, port 443 opened for Cockpit |

**Duration:** 5-20 minutes depending on package downloads

## Step 5: Verify Deployment

Once cloud-init completes, verify access:

### SSH Access

```bash
# From your workstation
ssh admin@<HOST_IP>

# Or if using SSH key
ssh -i ~/.ssh/your_key admin@<HOST_IP>
```

### Cockpit Access

Open in browser: `https://<HOST_IP>`

Login with admin credentials from `identity.config.yaml`.

### Verification Commands

Run these on the deployed server:

```bash
# Verify cloud-init completed
cloud-init status

# Verify ZFS
zfs list

# Verify network
ip addr show
cat /etc/netplan/90-static.yaml

# Verify services
systemctl status cockpit.socket
systemctl status libvirtd

# Verify KVM
virsh list --all
```

## Timeline Summary

| Phase | Duration | Description |
|-------|----------|-------------|
| Boot & BIOS | 1-2 min | POST, boot menu selection |
| Autoinstall | 5-15 min | Base OS installation with ZFS |
| Reboot | 1-2 min | System restart, remove media |
| Cloud-init | 5-20 min | Network config, packages, services |
| **Total** | **12-40 min** | Complete deployment |

## Next Steps

After successful deployment:

1. Complete [Chapter 9: Post-Deployment Validation](../POST_DEPLOYMENT_VALIDATION/OVERVIEW.md)
