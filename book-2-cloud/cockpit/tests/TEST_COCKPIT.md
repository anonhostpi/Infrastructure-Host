# Test 6.11: Cockpit Fragment

**Template:** `book-2-cloud/cockpit/fragment.yaml.tpl`
**Fragment Docs:** [6.11 Cockpit Fragment](../docs/FRAGMENT.md)

Tests Cockpit web console installation, localhost binding, and SSH tunnel access.

---

## Test 6.11.1: Package Installation

```bash
# On VM: Verify cockpit packages installed
dpkg -l | grep cockpit
# Expected: cockpit and cockpit-machines installed
```

| Check | Command | Expected |
|-------|---------|----------|
| cockpit | `dpkg -l \| grep "^ii  cockpit "` | Installed |
| cockpit-machines | `dpkg -l \| grep cockpit-machines` | Installed |

---

## Test 6.11.2: Socket Status

```bash
# On VM: Verify cockpit.socket running
systemctl is-active cockpit.socket
# Expected: active

systemctl is-enabled cockpit.socket
# Expected: enabled
```

| Check | Command | Expected |
|-------|---------|----------|
| Socket active | `systemctl is-active cockpit.socket` | active |
| Socket enabled | `systemctl is-enabled cockpit.socket` | enabled |

---

## Test 6.11.3: Localhost-Only Binding

```bash
# On VM: Verify socket listens only on localhost
ss -tlnp | grep 443
# Expected: 127.0.0.1:443 (NOT 0.0.0.0:443)

# On VM: Verify socket drop-in config
cat /etc/systemd/system/cockpit.socket.d/listen.conf
# Expected: ListenStream=127.0.0.1:443
```

| Check | Command | Expected |
|-------|---------|----------|
| Listening address | `ss -tlnp \| grep 443` | 127.0.0.1:443 |
| Drop-in config | `test -f /etc/systemd/system/cockpit.socket.d/listen.conf` | File exists |
| ListenStream | `grep ListenStream /etc/systemd/system/cockpit.socket.d/listen.conf` | 127.0.0.1:443 |

---

## Test 6.11.4: Configuration File

```bash
# On VM: Verify cockpit.conf exists
cat /etc/cockpit/cockpit.conf
# Expected: [WebService] section with AllowUnencrypted = false

grep AllowUnencrypted /etc/cockpit/cockpit.conf
# Expected: AllowUnencrypted = false
```

| Check | Command | Expected |
|-------|---------|----------|
| Config exists | `test -f /etc/cockpit/cockpit.conf` | File exists |
| HTTPS required | `grep AllowUnencrypted /etc/cockpit/cockpit.conf` | false |

---

## Test 6.11.5: Not Reachable from Network

```bash
# On VM: Verify cockpit NOT listening on all interfaces
ss -tlnp | grep -E "0\.0\.0\.0:443|:::443"
# Expected: No output (nothing on 0.0.0.0 or ::)

# From host: Verify cannot connect directly to VM IP
curl -k --connect-timeout 5 https://<VM_IP>:443
# Expected: Connection refused or timeout
```

| Check | Command | Expected |
|-------|---------|----------|
| Not on 0.0.0.0 | `ss -tlnp \| grep "0\.0\.0\.0:443"` | No output |
| Not on IPv6 | `ss -tlnp \| grep ":::443"` | No output |

---

## Test 6.11.6: SSH Tunnel Access

```bash
# From host: Create SSH tunnel
ssh -L 9443:localhost:443 -N user@<VM_IP> &
SSH_PID=$!
sleep 2

# From host: Test tunnel connection
curl -k https://localhost:9443
# Expected: Returns Cockpit HTML

kill $SSH_PID
```

---

## Test 6.11.7: Idle Timeout (If Configured)

```bash
# On VM: Check idle timeout setting
grep IdleTimeout /etc/cockpit/cockpit.conf
# Expected: IdleTimeout = <configured_value> (or not present if 0)
```

---

## Test 6.11.8: Cockpit Web Access (Manual)

After establishing SSH tunnel:

1. Open browser to `https://localhost:9443` (or configured tunnel port)
2. Accept self-signed certificate warning
3. Login with admin credentials from `identity.config.yaml`
4. Verify dashboard loads
5. Navigate to "Virtual Machines" - should show libvirt VMs

---

## PowerShell Test Commands

```powershell
# Run from host with multipass VM
$VMName = "cloud-init-test"

multipass exec $VMName -- dpkg -l | Select-String "cockpit"
multipass exec $VMName -- systemctl is-active cockpit.socket
multipass exec $VMName -- systemctl is-enabled cockpit.socket
multipass exec $VMName -- ss -tlnp | Select-String "443"
multipass exec $VMName -- cat /etc/cockpit/cockpit.conf
multipass exec $VMName -- cat /etc/systemd/system/cockpit.socket.d/listen.conf

# Test SSH tunnel (requires multipass shell access)
# Note: For full tunnel testing, use VirtualBox or direct SSH
```
