# 7.1 Cloud-init Testing

Test cloud-init configuration with multipass before building the full autoinstall ISO.

## Pre-Build Checklist

Before starting, verify these files exist:

- [ ] `network.config.yaml` - valid IPs, gateway, DNS
- [ ] `identity.config.yaml` - username, password
- [ ] `autoinstall.yml` - autoinstall template
- [ ] `cloud-init.yml` - cloud-init template
- [ ] `early-net.sh` - autoinstall network script
- [ ] `net-setup.sh` - cloud-init network script

## Phase 1: Cloud-init Testing

Test cloud-init configuration before embedding in autoinstall.

### Step 1: Start Builder VM

```powershell
# Create or start the builder VM
multipass launch --name iso-builder --cpus 2 --memory 4G --disk 20G

# Or if it already exists
multipass start iso-builder
```

### Step 2: Transfer Build Scripts

```powershell
# Transfer config files
multipass transfer network.config.yaml iso-builder:/home/ubuntu/
multipass transfer identity.config.yaml iso-builder:/home/ubuntu/

# Transfer build scripts
multipass transfer build_network.py iso-builder:/home/ubuntu/
multipass transfer build_cloud_init.py iso-builder:/home/ubuntu/

# Transfer templates
multipass transfer cloud-init.yml iso-builder:/home/ubuntu/
multipass transfer net-setup.sh iso-builder:/home/ubuntu/
```

### Step 3: Build and Validate cloud-init.yml

```powershell
# Install dependencies
multipass exec iso-builder -- sudo apt-get update -qq
multipass exec iso-builder -- sudo apt-get install -y -qq python3-yaml

# Validate YAML syntax before build
multipass exec iso-builder -- python3 -c "import yaml; yaml.safe_load(open('cloud-init.yml'))"

# Build cloud-init configuration
multipass exec iso-builder -- python3 build_cloud_init.py

# Validate built output (check printed output manually)
multipass exec iso-builder -- python3 -c "
from build_cloud_init import build_cloud_init
ci = build_cloud_init()
print('bootcmd entries:', len(ci.get('bootcmd', [])))
print('packages:', ci.get('packages', []))
print('users:', [u.get('name') for u in ci.get('users', [])])
"

# Validate against cloud-init schema
multipass exec iso-builder -- cloud-init schema --config-file cloud-init-built.yaml

# Retrieve built config
multipass transfer iso-builder:/home/ubuntu/cloud-init-built.yaml ./cloud-init-test.yaml
```

### Step 4: Test with Multipass and Validate

```powershell
# Launch test VM with cloud-init config (may timeout - that's OK)
multipass launch --name cloud-init-test --cloud-init cloud-init-test.yaml 2>$null

# Wait for cloud-init to complete (THIS is the true success indicator)
multipass exec cloud-init-test -- cloud-init status --wait
```

**Validation** - Run these commands and verify output:

```powershell
# Check cloud-init status
multipass exec cloud-init-test -- cloud-init status

# Check for errors in cloud-init log
multipass exec cloud-init-test -- grep -i error /var/log/cloud-init.log

# Verify network configuration applied
multipass exec cloud-init-test -- cat /etc/netplan/90-static.yaml

# Verify user created
multipass exec cloud-init-test -- id admin

# Verify services running
multipass exec cloud-init-test -- systemctl status cockpit.socket --no-pager
multipass exec cloud-init-test -- systemctl status libvirtd --no-pager
```

### Step 5: Cleanup Test VM

```powershell
multipass delete cloud-init-test
multipass purge
```

If cloud-init test passes, proceed to [6.2 Autoinstall Testing](./AUTOINSTALL_TESTING.md).
