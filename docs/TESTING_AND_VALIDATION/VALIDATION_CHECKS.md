# 6.2 Validation Checks

Validation checks to run at each stage of the build and test process.

## YAML Syntax Validation

Before building, validate YAML syntax:

```bash
# Check YAML syntax with Python
python3 -c "import yaml; yaml.safe_load(open('cloud-init.yml'))"
python3 -c "import yaml; yaml.safe_load(open('autoinstall.yml'))"

# After build, validate composed user-data
python3 -c "import yaml; yaml.safe_load(open('user-data'))"
```

## Cloud-init Schema Validation

On an Ubuntu system, validate against cloud-init schema:

```bash
# Validate cloud-init syntax
cloud-init schema --config-file cloud-init-built.yaml

# Check for warnings
cloud-init schema --config-file cloud-init-built.yaml 2>&1 | grep -i warn
```

## Build Output Validation

After running build scripts, verify outputs:

```bash
# Verify build_network.py output
python3 -c "
from build_network import load_network_config, generate_net_env
net = load_network_config()
env = generate_net_env(net)
print('Network env generated:')
print(env)
"

# Verify build_cloud_init.py output
python3 -c "
from build_cloud_init import build_cloud_init
ci = build_cloud_init()
print('bootcmd entries:', len(ci.get('bootcmd', [])))
print('packages:', ci.get('packages', []))
"

# Verify user-data structure
python3 -c "
import yaml
with open('user-data') as f:
    data = yaml.safe_load(f)
ai = data.get('autoinstall', {})
print('autoinstall version:', ai.get('version'))
print('has early-commands:', 'early-commands' in ai)
print('has user-data:', 'user-data' in ai)
ud = ai.get('user-data', {})
print('user-data has bootcmd:', 'bootcmd' in ud)
print('user-data has users:', 'users' in ud)
"
```

## ISO Validation

After building ISO, verify contents:

```bash
# List nocloud directory contents
xorriso -indev ubuntu-autoinstall.iso -ls /nocloud 2>/dev/null

# Verify GRUB config
xorriso -indev ubuntu-autoinstall.iso -extract /boot/grub/grub.cfg /tmp/grub.cfg
cat /tmp/grub.cfg | grep -A5 "Autoinstall"

# Verify user-data on ISO
xorriso -indev ubuntu-autoinstall.iso -extract /nocloud/user-data /tmp/user-data
head -20 /tmp/user-data
```

## Cloud-init Test Validation

After multipass cloud-init test:

```bash
# Check cloud-init status
cloud-init status

# Check for errors in cloud-init log
grep -i error /var/log/cloud-init.log

# Verify network configuration applied
cat /etc/netplan/90-static.yaml

# Verify user created
id admin

# Verify services running
systemctl status cockpit.socket
systemctl status libvirtd
```

## Autoinstall Test Validation

After VirtualBox installation completes:

```powershell
# SSH into the VM
ssh -p 2222 admin@localhost

# Then run these checks inside the VM:
```

```bash
# Verify autoinstall completed
cat /var/log/installer/autoinstall-user-data

# Verify cloud-init completed
cloud-init status

# Verify ZFS root
zfs list

# Verify network
ip addr show
cat /etc/netplan/90-static.yaml

# Verify services
systemctl status cockpit.socket
systemctl status libvirtd
systemctl status ssh

# Verify packages
dpkg -l | grep -E "qemu-kvm|libvirt|cockpit"

# Verify user and groups
id admin
groups admin

# Verify firewall
ufw status
```

## Common Validation Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Malformed YAML` | Inline comments in list items | Remove comments from list items |
| `Invalid user-data` | Missing `#cloud-config` header | Ensure first line is `#cloud-config` |
| `Schema validation failed` | Invalid cloud-init keys | Check cloud-init documentation |
| `No autoinstall config found` | Missing datasource parameter | Add `ds=nocloud;s=/cdrom/nocloud/` to GRUB |
| `Network not configured` | arping failed to find interface | Check gateway/DNS IPs are reachable |

## Validation Checklist

### Pre-Build
- [ ] `network.config.yaml` exists and has valid IPs
- [ ] `identity.config.yaml` exists with credentials
- [ ] Template files exist (`autoinstall.yml`, `cloud-init.yml`)
- [ ] Shell scripts exist (`early-net.sh`, `net-setup.sh`)

### Post-Build
- [ ] `user-data` generated without errors
- [ ] YAML syntax valid
- [ ] Contains `autoinstall.version: 1`
- [ ] Contains `early-commands` array
- [ ] Contains embedded `user-data` with `bootcmd`

### Post-ISO
- [ ] ISO file exists and is ~3GB
- [ ] `/nocloud/user-data` exists on ISO
- [ ] `/nocloud/meta-data` exists on ISO
- [ ] GRUB config has autoinstall entry with `ds=nocloud`

### Post-Install
- [ ] System boots without manual intervention
- [ ] Network configured with static IP
- [ ] SSH accessible
- [ ] User created with correct groups
- [ ] Services running (cockpit, libvirt)
- [ ] ZFS root filesystem configured
