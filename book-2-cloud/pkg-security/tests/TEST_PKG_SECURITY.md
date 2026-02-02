# Test 6.8: Package Security Fragment

**Template:** `book-2-cloud/pkg-security/fragment.yaml.tpl`
**Fragment Docs:** [6.8 Package Security Fragment](../../docs/FRAGMENT.md)

Tests unattended upgrades configuration.

---

## Test 6.8.1: Package Installation

```bash
# On VM: Verify unattended-upgrades installed
dpkg -l | grep unattended-upgrades
# Expected: Shows installed

dpkg -l | grep apt-listchanges
# Expected: Shows installed
```

| Check | Command | Expected |
|-------|---------|----------|
| unattended-upgrades | `dpkg -l \| grep unattended-upgrades` | Installed |
| apt-listchanges | `dpkg -l \| grep apt-listchanges` | Installed |

---

## Test 6.8.2: Unattended Upgrades Configuration

```bash
# On VM: Verify configuration file
cat /etc/apt/apt.conf.d/50unattended-upgrades | grep -E "Allowed-Origins|Automatic-Reboot|Mail"
# Expected: Security origins, Reboot false, Mail root
```

| Check | Command | Expected |
|-------|---------|----------|
| Security origins | `grep "security" /etc/apt/apt.conf.d/50unattended-upgrades` | Present |
| Auto-reboot disabled | `grep "Automatic-Reboot" /etc/apt/apt.conf.d/50unattended-upgrades` | "false" |
| Mail notifications | `grep 'Mail "root"' /etc/apt/apt.conf.d/50unattended-upgrades` | Present |

---

## Test 6.8.3: Auto-Upgrades Timer

```bash
# On VM: Verify auto-upgrades configuration
cat /etc/apt/apt.conf.d/20auto-upgrades
# Expected: Update-Package-Lists "1", Unattended-Upgrade "1"
```

| Check | Command | Expected |
|-------|---------|----------|
| Daily updates | `grep Update-Package-Lists /etc/apt/apt.conf.d/20auto-upgrades` | "1" |
| Daily upgrades | `grep Unattended-Upgrade /etc/apt/apt.conf.d/20auto-upgrades` | "1" |

---

## Test 6.8.4: Service Status

```bash
# On VM: Verify unattended-upgrades service
systemctl is-enabled unattended-upgrades
# Expected: enabled
```

---

## PowerShell Test Commands

```powershell
# Run from host with multipass VM
$VMName = "cloud-init-test"

multipass exec $VMName -- dpkg -l | Select-String "unattended-upgrades|apt-listchanges"
multipass exec $VMName -- cat /etc/apt/apt.conf.d/50unattended-upgrades
multipass exec $VMName -- cat /etc/apt/apt.conf.d/20auto-upgrades
multipass exec $VMName -- systemctl is-enabled unattended-upgrades
```
