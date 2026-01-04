# Test 6.1: Network Fragment

**Template:** `src/autoinstall/cloud-init/10-network.yaml.tpl`
**Fragment Docs:** [6.1 Network Fragment](../../CLOUD_INIT_CONFIGURATION/NETWORK_FRAGMENT.md)

Tests hostname, FQDN, /etc/hosts management, and network script execution.

---

## Test 6.1.1: Hostname Configuration

```bash
# On VM: Verify short hostname is set
hostname -s
# Expected: Non-empty, not "localhost"

# On VM: Verify FQDN is set with domain
hostname -f
# Expected: Contains "." (e.g., kvm-host.local.lan)
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
# On VM: Verify netplan config exists
ls /etc/netplan/*.yaml
# Expected: At least one .yaml file

# On VM: Verify static IP configured (bridged mode)
grep -E "addresses:|gateway" /etc/netplan/*.yaml
# Expected: Shows addresses and gateway4
```

| Check | Command | Expected |
|-------|---------|----------|
| Netplan exists | `ls /etc/netplan/*.yaml` | File(s) present |
| Static config | `grep addresses /etc/netplan/*.yaml` | Contains addresses |

---

## Test 6.1.4: Network Connectivity

```bash
# On VM: Verify IP address assigned
ip -4 addr show scope global | grep "inet "
# Expected: At least one global IP

# On VM: Verify default gateway
ip route | grep "^default"
# Expected: default via <gateway>

# On VM: Verify gateway reachable
ping -c 1 -W 2 $(ip route | grep "^default" | awk '{print $3}')
# Expected: 1 received

# On VM: Verify DNS resolution
host -W 2 ubuntu.com
# Expected: Resolves successfully
```

| Check | Command | Expected |
|-------|---------|----------|
| IP assigned | `ip -4 addr show scope global` | Shows inet address |
| Gateway configured | `ip route \| grep default` | Shows default route |
| Gateway reachable | `ping -c 1 <gateway>` | 1 packet received |
| DNS works | `host ubuntu.com` | Resolves |

---

## PowerShell Test Commands

```powershell
# Run from host with multipass VM
$VMName = "cloud-init-test"

multipass exec $VMName -- hostname -s
multipass exec $VMName -- hostname -f
multipass exec $VMName -- grep "127.0.1.1" /etc/hosts
multipass exec $VMName -- ls /etc/netplan/
multipass exec $VMName -- ip -4 addr show scope global
multipass exec $VMName -- ip route
multipass exec $VMName -- host ubuntu.com
```
