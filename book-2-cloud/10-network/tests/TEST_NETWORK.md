# Test 6.1: Network Fragment

**Template:** `src/autoinstall/cloud-init/10-network.yaml.tpl`
**Fragment Docs:** [6.1 Network Fragment](../../CLOUD_INIT_CONFIGURATION/NETWORK_FRAGMENT.md)

Tests hostname, FQDN, /etc/hosts management, and network script execution.

---

## Multipass Testing Note

> **Important:** When testing with multipass, the bridged interface will have **two IP addresses**:
> - DHCP address from multipass's `50-cloud-init.yaml` (e.g., 192.168.1.168/24)
> - Static address from our `90-static.yaml` (e.g., 192.168.1.25/24)
>
> This is expected behavior in the multipass test environment. In **production (bare metal)**, only our `90-static.yaml` will exist, so only the static IP will be configured.
>
> The script also detects multipass by parsing `/etc/netplan/50-cloud-init.yaml` and protects the NAT interface (eth0) to maintain multipass connectivity.

---

## Test 6.1.1: Hostname Configuration

```bash
# On VM: Verify short hostname is set
hostname -s
# Expected: Non-empty, not "localhost"

# On VM: Verify FQDN is set with domain
hostname -f
# Expected: Contains "." (e.g., lab.hostpi.io)
```

| Check | Command | Expected |
|-------|---------|----------|
| Short hostname set | `hostname -s` | Non-empty string |
| FQDN has domain | `hostname -f` | Contains `.` |

---

## Test 6.1.2: /etc/hosts Management

```bash
# On VM: Verify cloud-init manages /etc/hosts
grep "127.0.1.1" /etc/hosts
# Expected: Contains hostname

grep "127.0.0.1.*localhost" /etc/hosts
# Expected: localhost entry exists
```

| Check | Command | Expected |
|-------|---------|----------|
| Hostname in hosts | `grep "127.0.1.1" /etc/hosts` | Contains hostname |
| Localhost entry | `grep "127.0.0.1.*localhost" /etc/hosts` | Entry exists |

---

## Test 6.1.3: Netplan Configuration

```bash
# On VM: Verify our static netplan config exists
ls -la /etc/netplan/90-static.yaml
# Expected: File exists with 0600 permissions

# On VM: Verify static IP configured
sudo cat /etc/netplan/90-static.yaml
# Expected: Shows static IP, gateway, DNS
```

| Check | Command | Expected |
|-------|---------|----------|
| Static config exists | `ls /etc/netplan/90-static.yaml` | File present |
| Correct permissions | `stat -c %a /etc/netplan/90-static.yaml` | 600 |
| Static IP in config | `sudo grep addresses /etc/netplan/90-static.yaml` | Contains IP/CIDR |

---

## Test 6.1.4: Network Connectivity

```bash
# On VM: Verify static IP address assigned
ip -4 addr show eth1 | grep "192.168.1.25"
# Expected: Shows static IP (may also show DHCP IP in multipass)

# On VM: Verify default gateway
ip route | grep "^default"
# Expected: default via <gateway>

# On VM: Verify gateway reachable
ping -c 1 -W 2 192.168.1.1
# Expected: 1 received

# On VM: Verify DNS resolution
host -W 2 ubuntu.com
# Expected: Resolves successfully
```

| Check | Command | Expected |
|-------|---------|----------|
| Static IP assigned | `ip addr show eth1` | Shows static IP |
| Gateway configured | `ip route \| grep default` | Shows default route |
| Gateway reachable | `ping -c 1 <gateway>` | 1 packet received |
| DNS works | `host ubuntu.com` | Resolves |

---

## Test 6.1.5: Script Logging

```bash
# On VM: Verify network setup script ran correctly
grep "net-setup" /var/log/syslog
# Expected: Shows detection, configuration, and success messages
```

Expected log entries:
- `Starting network detection`
- `Multipass detected - protecting interface with MAC` (in multipass only)
- `Skipping eth0 (protected multipass interface)` (in multipass only)
- `eth1 can reach gateway`
- `Static network configuration written to eth1`

---

## PowerShell Test Commands

```powershell
# Run from host with multipass VM
$VMName = "cloud-init-runner"

# Hostname tests
multipass exec $VMName -- hostname -s
multipass exec $VMName -- hostname -f
multipass exec $VMName -- grep "127.0.1.1" /etc/hosts

# Netplan tests
multipass exec $VMName -- bash -c "ls -la /etc/netplan/"
multipass exec $VMName -- bash -c "sudo cat /etc/netplan/90-static.yaml"

# Network tests
multipass exec $VMName -- ip -4 addr show scope global
multipass exec $VMName -- ip route
multipass exec $VMName -- ping -c 1 192.168.1.1
multipass exec $VMName -- host ubuntu.com

# Log verification
multipass exec $VMName -- bash -c "grep 'net-setup' /var/log/syslog"
```
