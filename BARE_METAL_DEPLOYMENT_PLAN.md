# Bare-Metal Ubuntu Deployment Plan with Cloud-init

## 1. Overview & Architecture

### 1.1 Deployment Strategy
This plan outlines the deployment of Ubuntu Server on bare-metal hardware using USB/ISO boot with autoinstall and cloud-init for automated configuration.

**Deployment Flow:**
```
Hardware Preparation → BIOS Configuration → Custom ISO Creation →
Boot & Autoinstall → Cloud-init Execution → Post-Deploy Validation
```

### 1.2 Key Components
- **Ubuntu Server** - Base operating system (latest LTS recommended: 22.04 or 24.04)
- **Autoinstall** - Ubuntu's automated installation system (Subiquity-based)
- **Cloud-init** - Post-installation configuration automation
- **Cockpit** - Web-based server management interface

### 1.3 Architecture Benefits
- **Repeatability** - Same configuration across multiple servers
- **Version Control** - Infrastructure as code with cloud-init configs
- **Rapid Deployment** - Minimal manual intervention required
- **Consistency** - Eliminates configuration drift

### 1.4 How to Use This Document

**For First-Time Users:**
1. Start with Section 1 (Overview) to understand the approach
2. Review Section 2 (Hardware & BIOS Setup) to prepare hardware
3. Plan network configuration using Section 3
4. Create installation media per Section 4
5. Configure cloud-init per Section 5
6. Follow Section 6 for deployment
7. Validate with Section 7

**For Quick Deployment:**
1. Use the cloud-init example in Section 5.2 as a starting point
2. Modify for your environment
3. Follow Section 4.3 to create bootable media
4. Deploy per Section 6.2

**For Multiple Servers:**
1. Review Section 9 for templating strategy
2. Create configuration templates
3. Generate per-host configurations
4. Consider Ansible or Terraform automation (Section 9.2)

**For Troubleshooting:**
1. Check Section 8 for common issues
2. Review logs per Section 8.2
3. Run validation commands from Section 7.2

---

## 2. Hardware & BIOS Setup

### 2.1 Hardware Requirements

**Minimum Specifications:**
- CPU: x86_64 processor with virtualization support (Intel VT-x or AMD-V)
- RAM: 4GB minimum (8GB+ recommended for virtualization workloads)
- Storage: 25GB minimum (SSD recommended)
- Network: Gigabit Ethernet adapter

**Recommended for Production:**
- CPU: Multi-core processor with VT-x/AMD-V and VT-d/AMD-Vi (for I/O virtualization)
- RAM: 16GB+ (depending on workload)
- Storage:
  - RAID configuration for redundancy (RAID 1 for OS, RAID 10 for data)
  - NVMe SSD for optimal performance
- Network: Dual NICs for bonding/redundancy

### 2.2 Pre-Installation Hardware Checklist

- [ ] Verify CPU supports virtualization extensions
  ```bash
  # On existing Linux system, check CPU flags
  grep -E 'vmx|svm' /proc/cpuinfo
  ```
- [ ] Test all RAM modules (use memtest86+ if available)
- [ ] Configure RAID arrays if applicable
- [ ] Verify all NICs are recognized
- [ ] Document MAC addresses for network planning

### 2.3 BIOS/UEFI Configuration

**Access BIOS:**
- Reboot and press DEL, F2, F10, or F12 (varies by manufacturer)
- Common keys: Dell (F2), HP (F10), Lenovo (F1), Supermicro (DEL)

**Critical BIOS Settings:**

1. **Boot Settings**
   - Boot Mode: UEFI (recommended) or Legacy BIOS
   - Secure Boot: Disabled (or configure for Ubuntu)
   - Boot Order: USB/Removable Media first

2. **Virtualization Support** (CRITICAL)
   - Intel Virtualization Technology (VT-x): **Enabled**
   - Intel VT-d (I/O virtualization): **Enabled**
   - AMD-V (AMD virtualization): **Enabled**
   - AMD-Vi (AMD I/O virtualization): **Enabled**

   **Note:** These settings may be under:
   - Advanced → CPU Configuration
   - System Configuration → Virtualization Technology
   - Processor → Intel Virtualization Technology

3. **Power Management**
   - Power Profile: Maximum Performance (for servers)
   - CPU C-States: May need adjustment based on workload
   - Wake on LAN: Enabled (if needed for remote management)

4. **Storage Configuration**
   - SATA Mode: AHCI (for better performance and compatibility)
   - RAID Mode: If using hardware RAID, configure arrays now

5. **Network Settings**
   - PXE Boot: Disabled (unless needed)
   - Wake on LAN: Configure as needed
   - Network Stack: IPv4 and/or IPv6 as required

**BIOS Configuration Checklist:**
- [ ] Boot mode set to UEFI
- [ ] Virtualization extensions enabled (VT-x/AMD-V)
- [ ] I/O virtualization enabled (VT-d/AMD-Vi)
- [ ] Boot order configured (USB first)
- [ ] Secure Boot configured or disabled
- [ ] RAID arrays configured (if applicable)
- [ ] Power management optimized
- [ ] Save BIOS settings and verify on reboot

---

## 3. Network Configuration Planning

### 3.1 Network Information Gathering

Before deployment, collect the following information:

**Per-Server Network Details:**
- Hostname: `host-XX` or per naming convention
- Primary IP Address: `10.0.1.X/24` (example)
- Gateway: `10.0.1.1`
- DNS Servers: `8.8.8.8, 8.8.4.4` or internal DNS
- DNS Search Domain: `example.local`
- VLAN ID (if applicable): `100`
- NIC MAC Address: `AA:BB:CC:DD:EE:FF`

### 3.2 Network Topology Considerations

**Single NIC Configuration:**
- Simplest setup for basic deployments
- Single point of failure

**Bonded/Teamed NICs:**
- Redundancy and/or increased bandwidth
- Common modes:
  - `mode=1` (active-backup) - Failover only
  - `mode=4` (802.3ad/LACP) - Aggregation + failover (requires switch support)
  - `mode=6` (balance-alb) - Adaptive load balancing

**VLAN Configuration:**
- Tagged VLANs for network segmentation
- Management, production, storage networks

### 3.3 Network Configuration in Cloud-init

Network configuration will be handled via cloud-init using Netplan (Ubuntu's network configuration tool).

**Example Network Config (to be included in cloud-init):**
```yaml
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: false
      addresses:
        - 10.0.1.100/24
      gateway4: 10.0.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
        search:
          - example.local
```

---

## 4. Creating Ubuntu Autoinstall Media

### 4.1 Download Ubuntu Server ISO

```bash
# Download Ubuntu 24.04 LTS Server (example)
wget https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso

# Verify checksum
wget https://releases.ubuntu.com/24.04/SHA256SUMS
sha256sum -c SHA256SUMS 2>&1 | grep OK
```

### 4.2 Autoinstall Configuration

Autoinstall uses a `user-data` file for installation automation.

**Create autoinstall directory structure:**
```bash
mkdir -p autoinstall/nocloud
cd autoinstall/nocloud
```

**Create `meta-data` (empty but required):**
```bash
touch meta-data
```

**Create `user-data` for autoinstall:**

```yaml
#cloud-config
autoinstall:
  version: 1

  # Locale and keyboard
  locale: en_US.UTF-8
  keyboard:
    layout: us

  # Network configuration (DHCP during install, cloud-init will reconfigure)
  network:
    network:
      version: 2
      ethernets:
        any:
          match:
            name: en*
          dhcp4: true

  # Storage configuration
  storage:
    layout:
      name: lvm
      sizing-policy: all

  # Identity (temporary, will be managed by cloud-init)
  identity:
    hostname: ubuntu-server
    username: installer
    password: "$6$rounds=4096$saltsaltexample$hashedpasswordhere"
    # Generate with: mkpasswd -m sha-512

  # SSH server
  ssh:
    install-server: true
    allow-pw: true

  # Packages to install during installation
  packages:
    - cloud-init
    - qemu-guest-agent

  # Late commands (runs at end of installation)
  late-commands:
    - curtin in-target --target=/target -- systemctl enable cloud-init
    - curtin in-target --target=/target -- systemctl enable ssh

  # Reboot after installation
  shutdown: reboot
```

### 4.3 Methods to Create Bootable Media

#### Method A: Modify ISO with autoinstall (Recommended)

```bash
# Install required tools
sudo apt install xorriso isolinux

# Extract ISO
xorriso -osirrox on -indev ubuntu-24.04-live-server-amd64.iso -extract / iso_extract

# Copy autoinstall files
cp user-data iso_extract/nocloud/user-data
cp meta-data iso_extract/nocloud/meta-data

# Modify grub config to use autoinstall
cat > iso_extract/boot/grub/grub.cfg << 'EOF'
set timeout=5
menuentry "Autoinstall Ubuntu Server" {
    linux /casper/vmlinuz autoinstall ds=nocloud;s=/cdrom/nocloud/ ---
    initrd /casper/initrd
}
EOF

# Rebuild ISO
cd iso_extract
sudo xorriso -as mkisofs -r \
  -V "Ubuntu Autoinstall" \
  -o ../ubuntu-autoinstall.iso \
  -J -joliet-long \
  -cache-inodes \
  -b isolinux/isolinux.bin \
  -c isolinux/boot.cat \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -eltorito-alt-boot \
  -e boot/grub/efi.img \
  -no-emul-boot \
  -isohybrid-gpt-basdat \
  .

cd ..
```

#### Method B: USB with separate autoinstall files

```bash
# Write ISO to USB
sudo dd if=ubuntu-24.04-live-server-amd64.iso of=/dev/sdX bs=4M status=progress
sync

# Mount USB and add autoinstall files
sudo mount /dev/sdX1 /mnt
sudo mkdir -p /mnt/nocloud
sudo cp user-data /mnt/nocloud/
sudo cp meta-data /mnt/nocloud/
sudo umount /mnt
```

---

## 5. Cloud-init Configuration

### 5.1 Cloud-init Data Sources

For bare-metal deployments, use NoCloud data source:

**Option 1: Separate cloud-init ISO (Recommended)**
- Create a second ISO containing only cloud-init configuration
- Attach during first boot

**Option 2: Embed in autoinstall**
- Include cloud-init directives in autoinstall user-data
- Applied after installation completes

**Option 3: Local filesystem**
- Place cloud-init files in `/var/lib/cloud/seed/nocloud-net/`
- Useful for manual installation followed by cloud-init

### 5.2 Cloud-init Configuration Structure

**Create `user-data` for cloud-init:**

```yaml
#cloud-config

# Hostname
hostname: ubuntu-host-01
fqdn: ubuntu-host-01.example.local

# Manage /etc/hosts
manage_etc_hosts: true

# Users
users:
  - name: admin
    groups: [sudo, docker]
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ... user@workstation

# Disable root login
disable_root: true

# SSH configuration
ssh_pwauth: false
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ... user@workstation

# Timezone
timezone: America/New_York

# Network configuration (static IP)
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: false
      addresses:
        - 10.0.1.100/24
      routes:
        - to: default
          via: 10.0.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
        search:
          - example.local

# Package management
package_update: true
package_upgrade: true
package_reboot_if_required: true

# Packages to install
packages:
  # System utilities
  - vim
  - tmux
  - htop
  - curl
  - wget
  - git
  - net-tools
  - dnsutils

  # Virtualization (KVM/QEMU)
  - qemu-kvm
  - libvirt-daemon-system
  - libvirt-clients
  - bridge-utils
  - virt-manager
  - virtinst

  # Cockpit web interface
  - cockpit
  - cockpit-machines
  - cockpit-podman
  - cockpit-networkmanager

  # Container runtime
  - docker.io
  - docker-compose

  # Monitoring
  - prometheus-node-exporter

# Systemd services to enable
runcmd:
  # Enable and start libvirtd
  - systemctl enable libvirtd
  - systemctl start libvirtd

  # Add admin user to libvirt group
  - usermod -aG libvirt admin
  - usermod -aG kvm admin

  # Enable and start Cockpit
  - systemctl enable cockpit.socket
  - systemctl start cockpit.socket

  # Configure firewall for Cockpit (port 9090)
  - ufw allow 9090/tcp
  - ufw --force enable

  # Enable and start Docker
  - systemctl enable docker
  - systemctl start docker

  # Configure libvirt default network
  - virsh net-autostart default
  - virsh net-start default || true

  # Set up br0 bridge for VMs (example)
  - |
    cat > /etc/netplan/60-bridge.yaml << 'NETPLAN_EOF'
    network:
      version: 2
      bridges:
        br0:
          interfaces: []
          dhcp4: false
          addresses:
            - 10.0.100.1/24
    NETPLAN_EOF
  - netplan apply || true

# Write files
write_files:
  # Custom MOTD
  - path: /etc/motd
    content: |
      ========================================
      Ubuntu Infrastructure Host
      Managed by cloud-init
      ========================================
    permissions: '0644'

  # Docker daemon configuration
  - path: /etc/docker/daemon.json
    content: |
      {
        "log-driver": "json-file",
        "log-opts": {
          "max-size": "10m",
          "max-file": "3"
        }
      }
    permissions: '0644'

  # Cockpit configuration
  - path: /etc/cockpit/cockpit.conf
    content: |
      [WebService]
      AllowUnencrypted = false
      UrlRoot = /cockpit
    permissions: '0644'

# Final message
final_message: "Cloud-init deployment complete! System is ready. Cockpit available at https://<host-ip>:9090"

# Power state
power_state:
  mode: reboot
  timeout: 30
  condition: true
```

**Create `meta-data`:**

```yaml
instance-id: ubuntu-host-01
local-hostname: ubuntu-host-01
```

**Optional `network-config` (alternative to network in user-data):**

```yaml
version: 2
ethernets:
  ens18:
    dhcp4: false
    addresses:
      - 10.0.1.100/24
    routes:
      - to: default
        via: 10.0.1.1
    nameservers:
      addresses:
        - 8.8.8.8
        - 8.8.4.4
      search:
        - example.local
```

### 5.3 Creating Cloud-init ISO

```bash
# Create cloud-init directory
mkdir cloud-init-data
cd cloud-init-data

# Create your user-data and meta-data files
# (use configurations from section 5.2)

# Generate ISO
sudo genisoimage -output cloud-init.iso \
  -volid cidata \
  -joliet \
  -rock \
  user-data meta-data

# Or using xorriso
xorriso -as mkisofs \
  -o cloud-init.iso \
  -V cidata \
  -J -r \
  user-data meta-data
```

### 5.4 Cloud-init Variables and Templating

Cloud-init supports Jinja2 templating for dynamic configurations:

```yaml
#cloud-config
hostname: host-{{ ds.meta_data.instance_id }}

runcmd:
  - echo "Instance ID: {{ ds.meta_data.instance_id }}" > /etc/instance-info
  - echo "Local IPv4: {{ ds.meta_data.local_ipv4 }}" >> /etc/instance-info
```

---

## 6. Deployment Process

### 6.1 Pre-Deployment Checklist

- [ ] BIOS configured (virtualization enabled, boot order set)
- [ ] Network details documented (IP, gateway, DNS)
- [ ] SSH public key ready for cloud-init
- [ ] Autoinstall ISO created and tested
- [ ] Cloud-init ISO created with correct configurations
- [ ] Backup of any existing data (if applicable)
- [ ] USB devices or ISO files ready

### 6.2 Step-by-Step Deployment

**Step 1: Boot from Installation Media**
1. Insert USB or attach ISO via IPMI/iLO/iDRAC
2. Power on server
3. Press boot menu key (F11, F12, ESC - varies by vendor)
4. Select USB/ISO device
5. Ubuntu installer should start automatically with autoinstall

**Step 2: Monitor Autoinstall Process**
1. Autoinstall will proceed automatically
2. Monitor for any errors (usually network or storage related)
3. Installation takes 5-15 minutes depending on hardware
4. System will reboot automatically when complete

**Step 3: First Boot - Cloud-init Execution**
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

**Step 4: Attach Cloud-init Configuration (if not embedded)**

If using separate cloud-init ISO:
1. After autoinstall completes and system reboots
2. Attach cloud-init ISO as second CD/DVD
3. Cloud-init will detect and apply configuration on first boot

Alternative - Manual placement:
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

### 6.3 Monitoring Cloud-init Progress

**Check cloud-init status:**
```bash
# Wait for cloud-init to complete
cloud-init status --wait

# Check cloud-init status
cloud-init status

# View cloud-init logs
sudo tail -f /var/log/cloud-init-output.log

# Check for errors
sudo grep -i error /var/log/cloud-init.log
```

**Cloud-init stages:**
1. `init-local` - Identifies datasource
2. `init` - Network configuration
3. `modules-config` - Package installation, user creation
4. `modules-final` - Scripts, final configurations

---

## 7. Post-Deployment Validation

### 7.1 System Validation Checklist

**Basic System:**
- [ ] System boots successfully
- [ ] Hostname configured correctly: `hostnamectl`
- [ ] Network configured with static IP: `ip addr show`
- [ ] Default gateway reachable: `ping -c 3 10.0.1.1`
- [ ] DNS resolution working: `nslookup google.com`
- [ ] Timezone correct: `timedatectl`

**Users and SSH:**
- [ ] Admin user created: `id admin`
- [ ] SSH key authentication working: `ssh admin@<host-ip>`
- [ ] Password authentication disabled: `sudo grep PasswordAuthentication /etc/ssh/sshd_config`
- [ ] Sudo access working: `sudo whoami`

**Virtualization:**
- [ ] KVM modules loaded: `lsmod | grep kvm`
- [ ] Virtualization enabled in CPU: `egrep -c '(vmx|svm)' /proc/cpuinfo` (should be > 0)
- [ ] Libvirt running: `systemctl status libvirtd`
- [ ] Default network active: `virsh net-list --all`
- [ ] Admin user in libvirt group: `groups admin | grep libvirt`

**Cockpit:**
- [ ] Cockpit service running: `systemctl status cockpit.socket`
- [ ] Cockpit accessible: Open browser to `https://<host-ip>:9090`
- [ ] Login with admin user credentials
- [ ] Verify modules loaded (Machines, Podman, Network)

**Docker:**
- [ ] Docker service running: `systemctl status docker`
- [ ] Docker functional: `sudo docker run hello-world`
- [ ] Admin user in docker group (may require logout/login): `groups admin | grep docker`

**Firewall:**
- [ ] UFW enabled: `sudo ufw status`
- [ ] Required ports open: `sudo ufw status numbered`

### 7.2 Validation Commands

```bash
#!/bin/bash
# System validation script

echo "=== System Information ==="
hostnamectl
echo ""

echo "=== Network Configuration ==="
ip addr show
ip route show
echo ""

echo "=== DNS Resolution ==="
resolvectl status
nslookup google.com
echo ""

echo "=== Virtualization Support ==="
echo "CPU virtualization: $(egrep -c '(vmx|svm)' /proc/cpuinfo) cores with VT"
lsmod | grep kvm
virsh version
echo ""

echo "=== Services Status ==="
systemctl status libvirtd --no-pager
systemctl status cockpit.socket --no-pager
systemctl status docker --no-pager
echo ""

echo "=== Cockpit Access ==="
echo "Cockpit URL: https://$(hostname -I | awk '{print $1}'):9090"
echo ""

echo "=== Cloud-init Status ==="
cloud-init status
echo ""

echo "Validation complete!"
```

### 7.3 Cockpit Access and Configuration

**Access Cockpit:**
1. Open web browser
2. Navigate to: `https://<host-ip>:9090`
3. Accept self-signed certificate (or configure proper TLS)
4. Login with `admin` user and password

**Cockpit Features Available:**
- **Overview** - System resources, performance graphs
- **Machines** - Virtual machine management (create, start, stop VMs)
- **Podman** - Container management
- **Networking** - Network interface configuration, firewall rules
- **Storage** - Disk and filesystem management
- **Services** - Systemd service management
- **Terminal** - Web-based terminal access

**Optional: Configure Cockpit TLS Certificate**
```bash
# Generate self-signed certificate (or use Let's Encrypt)
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/cockpit/ws-certs.d/cockpit.key \
  -out /etc/cockpit/ws-certs.d/cockpit.cert

# Combine into single file
sudo cat /etc/cockpit/ws-certs.d/cockpit.cert \
  /etc/cockpit/ws-certs.d/cockpit.key | \
  sudo tee /etc/cockpit/ws-certs.d/0-self-signed.cert

# Restart cockpit
sudo systemctl restart cockpit.socket
```

---

## 8. Troubleshooting

### 8.1 Common Issues

**Issue: Autoinstall not starting**
- Solution: Verify boot parameters include `autoinstall ds=nocloud`
- Check that `user-data` and `meta-data` files exist in correct location
- Use Shift/Esc during boot to access GRUB menu manually

**Issue: Network not configured after installation**
- Solution: Check `/var/log/cloud-init.log` for network errors
- Verify network configuration in user-data
- Manually apply with `sudo netplan apply`

**Issue: Cloud-init not running**
- Solution: Check datasource detection: `cloud-init query -a`
- Verify cloud-init enabled: `systemctl status cloud-init`
- Re-run cloud-init: `sudo cloud-init clean && sudo cloud-init init`

**Issue: Cockpit not accessible**
- Solution: Check service status: `systemctl status cockpit.socket`
- Verify firewall: `sudo ufw status | grep 9090`
- Check listening ports: `sudo ss -tlnp | grep 9090`

**Issue: Virtualization not working**
- Solution: Verify BIOS settings (VT-x/AMD-V enabled)
- Check kernel modules: `lsmod | grep kvm`
- Verify CPU support: `egrep -c '(vmx|svm)' /proc/cpuinfo`

### 8.2 Logs and Debugging

**Key log files:**
```bash
# Cloud-init logs
/var/log/cloud-init.log          # Detailed cloud-init execution
/var/log/cloud-init-output.log   # Output from scripts and commands

# Installation logs
/var/log/installer/              # Autoinstall logs

# System logs
journalctl -u cloud-init         # Cloud-init service logs
journalctl -u cockpit            # Cockpit logs
journalctl -u libvirtd           # Libvirt logs
```

**Debug cloud-init:**
```bash
# Run cloud-init in debug mode
sudo cloud-init init --debug

# Analyze cloud-init run
sudo cloud-init analyze show

# Dump cloud-init data
sudo cloud-init query -a
```

---

## 9. Multiple Server Deployment

### 9.1 Templating Strategy

For deploying multiple servers, use a template-based approach:

**Create base templates:**
```
templates/
├── user-data.template       # Base cloud-init config with variables
├── meta-data.template       # Instance metadata template
└── generate-config.sh       # Script to generate per-host configs
```

**Example `generate-config.sh`:**
```bash
#!/bin/bash

# Host-specific variables
HOSTNAME=$1
IP_ADDRESS=$2
INSTANCE_ID=$3

# Generate user-data
sed -e "s/{{HOSTNAME}}/${HOSTNAME}/g" \
    -e "s/{{IP_ADDRESS}}/${IP_ADDRESS}/g" \
    templates/user-data.template > configs/${HOSTNAME}/user-data

# Generate meta-data
sed -e "s/{{INSTANCE_ID}}/${INSTANCE_ID}/g" \
    -e "s/{{HOSTNAME}}/${HOSTNAME}/g" \
    templates/meta-data.template > configs/${HOSTNAME}/meta-data

# Create ISO
genisoimage -output configs/${HOSTNAME}/cloud-init.iso \
  -volid cidata -joliet -rock \
  configs/${HOSTNAME}/user-data \
  configs/${HOSTNAME}/meta-data

echo "Generated configuration for ${HOSTNAME}"
```

**Usage:**
```bash
./generate-config.sh ubuntu-host-01 10.0.1.101 host-01
./generate-config.sh ubuntu-host-02 10.0.1.102 host-02
./generate-config.sh ubuntu-host-03 10.0.1.103 host-03
```

### 9.2 Automation Considerations

For large-scale deployments, consider:

**Option 1: Ansible Automation**
- Automate ISO creation and server provisioning
- Manage post-deployment configuration
- Template cloud-init configurations

Example Ansible structure:
```
ansible/
├── playbooks/
│   ├── create-cloud-init.yml      # Automate cloud-init ISO creation
│   ├── deploy-bare-metal.yml      # Orchestrate deployment
│   └── validate-deployment.yml    # Post-deployment validation
├── roles/
│   ├── cloud-init-generator/      # Cloud-init generation role
│   └── iso-builder/               # ISO creation role
├── inventory/
│   └── hosts.yaml                 # Inventory file template
├── group_vars/
│   └── all.yml                    # Global variables
└── README.md
```

**Option 2: Terraform + Cloud-init**
- Infrastructure as code for bare-metal provisioning
- Integration with IPMI/Redfish for remote management

Example Terraform structure:
```
terraform/
├── modules/
│   ├── bare-metal-server/         # Server provisioning module
│   └── network-config/            # Network configuration module
├── environments/
│   ├── dev/                       # Development environment
│   └── prod/                      # Production environment
├── variables.tf                   # Input variables
├── outputs.tf                     # Output values
└── README.md
```

**Option 3: PXE Boot Infrastructure**
- Centralized network-based deployment
- No physical media required
- Ideal for datacenter deployments

---

## 10. Security Hardening

### 10.1 Post-Deployment Security

**Immediate actions:**
```yaml
# Add to cloud-init user-data
runcmd:
  # Update system
  - apt update && apt upgrade -y

  # Configure automatic security updates
  - apt install unattended-upgrades -y
  - dpkg-reconfigure -plow unattended-upgrades

  # Harden SSH
  - sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
  - sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
  - systemctl restart sshd

  # Configure fail2ban
  - apt install fail2ban -y
  - systemctl enable fail2ban
  - systemctl start fail2ban
```

### 10.2 Firewall Configuration

```yaml
runcmd:
  # Configure UFW
  - ufw default deny incoming
  - ufw default allow outgoing
  - ufw allow ssh
  - ufw allow 9090/tcp    # Cockpit
  - ufw --force enable
```

### 10.3 Monitoring and Logging

Consider adding to cloud-init:
- Centralized logging (rsyslog to remote server)
- Monitoring agents (Prometheus node exporter, Telegraf)
- AIDE (file integrity monitoring)

---

## 11. Appendix

### 11.1 Reference Files

**Minimal cloud-init for testing:**
```yaml
#cloud-config
hostname: test-host
users:
  - name: testuser
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-rsa AAAAB3... user@host
```

### 11.2 Useful Commands

```bash
# Generate password hash for autoinstall
mkpasswd -m sha-512

# Test cloud-init config syntax
cloud-init schema --config-file user-data

# List available cloud-init modules
cloud-init list

# Check network configuration
netplan get
netplan try  # Test configuration with auto-rollback

# Verify virtualization
virt-host-validate
```

### 11.3 Additional Resources

- Ubuntu Autoinstall Documentation: https://ubuntu.com/server/docs/install/autoinstall
- Cloud-init Documentation: https://cloudinit.readthedocs.io/
- Netplan Documentation: https://netplan.io/
- Cockpit Project: https://cockpit-project.org/
- KVM/QEMU Documentation: https://www.linux-kvm.org/

### 11.4 Hardware Compatibility

**Check Ubuntu hardware compatibility:**
- Ubuntu Certified Hardware: https://ubuntu.com/certified
- Hardware probe database: https://linux-hardware.org/

**Verify before purchase:**
- Network card Linux driver support
- RAID controller compatibility
- GPU support (if needed for GPU passthrough)

### 11.5 Repository Structure

When splitting this document into a modular repository, use the following structure:

```
Infrastructure-Host/
├── README.md
├── TABLE_OF_CONTENTS.md
│
├── docs/                              # Documentation
│   ├── OVERVIEW_ARCHITECTURE/
│   ├── HARDWARE_BIOS_SETUP/
│   ├── NETWORK_PLANNING/
│   ├── AUTOINSTALL_MEDIA_CREATION/
│   ├── CLOUD_INIT_CONFIGURATION/
│   ├── DEPLOYMENT_PROCESS/
│   ├── POST_DEPLOYMENT_VALIDATION/
│   ├── TROUBLESHOOTING/
│   ├── MULTIPLE_SERVER_DEPLOYMENT/
│   ├── SECURITY_HARDENING/
│   └── APPENDIX/
│
├── config/                            # Configuration templates
│   ├── autoinstall/                   # user-data.yaml, meta-data.yaml, grub.cfg
│   ├── cloud-init/                    # Production and minimal configs
│   ├── network/                       # Netplan templates (static, bonded, VLAN, bridge)
│   └── services/                      # cockpit.conf, docker-daemon.json, etc.
│
├── scripts/                           # Automation scripts
│   ├── iso-creation/                  # ISO creation and modification
│   ├── deployment/                    # Config generation, USB writing, validation
│   ├── templates/                     # Multi-host generation
│   └── utils/                         # Helper utilities
│
├── examples/                          # Example configurations
│   ├── single-server/                 # basic-server, virtualization-host, cockpit
│   ├── multi-server/                  # lab-cluster, production-setup
│   └── network/                       # Network configuration examples
│
└── tests/                             # Validation and testing
    ├── validation/                    # Test scripts
    └── fixtures/                      # Test data
```

**File Organization Principles:**
1. **Modularity** - Each document focuses on a single topic
2. **Reusability** - Configuration templates can be used independently
3. **Scalability** - Structure supports both single and multiple server deployments
4. **Automation-Ready** - Scripts and templates enable CI/CD integration
5. **Version Control Friendly** - Small, focused files are easier to track and merge

**Naming Conventions:**
- Documentation directories: `UPPER_UNDERSCORE_CASE`
- Each section directory contains an `OVERVIEW.md` entry point
- Config files: lowercase with `.yaml` extension
- Scripts: lowercase with `.sh` extension

---

## Document Version Control

- Version: 1.0
- Date: 2025-12-27
- Purpose: Bare-metal Ubuntu deployment with cloud-init and Cockpit
- Target: Ubuntu 22.04/24.04 LTS
