# 6.2 Step-by-Step Deployment

## Step 1: Boot from Installation Media

1. Insert USB or attach ISO via IPMI/iLO/iDRAC
2. Power on server
3. Press boot menu key (F11, F12, ESC - varies by vendor)
4. Select USB/ISO device
5. Ubuntu installer should start automatically with autoinstall

## Step 2: Monitor Autoinstall Process

1. Autoinstall will proceed automatically
2. Monitor for any errors (usually network or storage related)
3. Installation takes 5-15 minutes depending on hardware
4. System will reboot automatically when complete

## Step 3: First Boot - Cloud-init Execution

1. After reboot, remove installation media
2. System boots into newly installed Ubuntu
3. Cloud-init executes on first boot
4. This applies:
   - Network configuration
   - User accounts
   - SSH keys
   - Package installations (including Cockpit)
   - Custom scripts

**Cloud-init execution takes 5-20 minutes depending on packages**

## Step 4: Attach Cloud-init Configuration (if not embedded)

If using separate cloud-init ISO:

1. After autoinstall completes and system reboots
2. Attach cloud-init ISO as second CD/DVD
3. Cloud-init will detect and apply configuration on first boot

### Alternative: Manual Placement

```bash
# SSH into server with installer account
ssh installer@10.0.1.100

# Become root
sudo su -

# Create cloud-init seed directory
mkdir -p /var/lib/cloud/seed/nocloud-net

# Upload or create user-data and meta-data files
cat > /var/lib/cloud/seed/nocloud-net/user-data << 'EOF'
#cloud-config
# (paste your cloud-init configuration)
EOF

cat > /var/lib/cloud/seed/nocloud-net/meta-data << 'EOF'
instance-id: ubuntu-host-01
local-hostname: ubuntu-host-01
EOF

# Clean cloud-init and re-run
cloud-init clean
cloud-init init
cloud-init modules --mode config
cloud-init modules --mode final

# Or simply reboot to trigger cloud-init
reboot
```

## Timeline Summary

| Phase | Duration | Description |
|-------|----------|-------------|
| Boot & BIOS | 1-2 min | POST, boot menu selection |
| Autoinstall | 5-15 min | Base OS installation |
| First Reboot | 1-2 min | System restart |
| Cloud-init | 5-20 min | Post-install configuration |
| **Total** | **12-40 min** | Complete deployment |
