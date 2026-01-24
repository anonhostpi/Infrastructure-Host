# Test 6.2: Kernel Hardening Fragment

**Template:** `src/autoinstall/cloud-init/15-kernel.yaml.tpl`
**Fragment Docs:** [6.2 Kernel Hardening Fragment](../../CLOUD_INIT_CONFIGURATION/KERNEL_HARDENING_FRAGMENT.md)

Tests sysctl security parameters.

---

## Test 6.2.1: Network Security Parameters

```bash
# On VM: Reverse path filtering
sysctl net.ipv4.conf.all.rp_filter
# Expected: = 1

sysctl net.ipv4.conf.default.rp_filter
# Expected: = 1

# On VM: Source routing disabled
sysctl net.ipv4.conf.all.accept_source_route
# Expected: = 0

sysctl net.ipv6.conf.all.accept_source_route
# Expected: = 0

# On VM: ICMP redirects disabled
sysctl net.ipv4.conf.all.accept_redirects
# Expected: = 0

sysctl net.ipv4.conf.all.send_redirects
# Expected: = 0

# On VM: SYN cookies enabled
sysctl net.ipv4.tcp_syncookies
# Expected: = 1

# On VM: Martian logging enabled
sysctl net.ipv4.conf.all.log_martians
# Expected: = 1
```

| Check | Command | Expected |
|-------|---------|----------|
| RP filter (all) | `sysctl net.ipv4.conf.all.rp_filter` | = 1 |
| RP filter (default) | `sysctl net.ipv4.conf.default.rp_filter` | = 1 |
| No source route (IPv4) | `sysctl net.ipv4.conf.all.accept_source_route` | = 0 |
| No source route (IPv6) | `sysctl net.ipv6.conf.all.accept_source_route` | = 0 |
| No ICMP redirects | `sysctl net.ipv4.conf.all.accept_redirects` | = 0 |
| No send redirects | `sysctl net.ipv4.conf.all.send_redirects` | = 0 |
| SYN cookies | `sysctl net.ipv4.tcp_syncookies` | = 1 |
| Log martians | `sysctl net.ipv4.conf.all.log_martians` | = 1 |

---

## Test 6.2.2: Kernel Security Parameters

```bash
# On VM: dmesg restricted
sysctl kernel.dmesg_restrict
# Expected: = 1

# On VM: Kernel pointers hidden
sysctl kernel.kptr_restrict
# Expected: = 2
```

| Check | Command | Expected |
|-------|---------|----------|
| dmesg restricted | `sysctl kernel.dmesg_restrict` | = 1 |
| kptr restricted | `sysctl kernel.kptr_restrict` | = 2 |

---

## Test 6.2.3: Configuration File Exists

```bash
# On VM: Verify sysctl config file deployed
cat /etc/sysctl.d/99-security.conf
# Expected: Contains security settings
```

---

## PowerShell Test Commands

```powershell
# Run from host with multipass VM
$VMName = "cloud-init-test"

multipass exec $VMName -- sysctl net.ipv4.conf.all.rp_filter
multipass exec $VMName -- sysctl net.ipv4.conf.all.accept_source_route
multipass exec $VMName -- sysctl net.ipv4.conf.all.accept_redirects
multipass exec $VMName -- sysctl net.ipv4.tcp_syncookies
multipass exec $VMName -- sysctl kernel.dmesg_restrict
multipass exec $VMName -- sysctl kernel.kptr_restrict
multipass exec $VMName -- cat /etc/sysctl.d/99-security.conf
```
