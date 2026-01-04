# Test 6.5: UFW Fragment

**Template:** `src/autoinstall/cloud-init/30-ufw.yaml.tpl`
**Fragment Docs:** [6.5 UFW Fragment](../../CLOUD_INIT_CONFIGURATION/UFW_FRAGMENT.md)

Tests firewall status, default policies, and SSH rate limiting.

---

## Test 6.5.1: UFW Status

```bash
# On VM: Verify UFW is active
sudo ufw status
# Expected: Status: active
```

---

## Test 6.5.2: Default Policies

```bash
# On VM: Verify default policies
sudo ufw status verbose | grep -E "^Default:"
# Expected: deny (incoming), allow (outgoing)
```

| Check | Command | Expected |
|-------|---------|----------|
| Incoming default | `sudo ufw status verbose` | deny (incoming) |
| Outgoing default | `sudo ufw status verbose` | allow (outgoing) |

---

## Test 6.5.3: SSH Rule

```bash
# On VM: Verify SSH is allowed with rate limiting
sudo ufw status | grep -E "22/tcp|ssh"
# Expected: LIMIT IN (not just ALLOW)
```

| Check | Command | Expected |
|-------|---------|----------|
| SSH allowed | `sudo ufw status \| grep 22` | Shows rule |
| Rate limited | `sudo ufw status \| grep 22` | LIMIT |

---

## Test 6.5.4: Logging Enabled

```bash
# On VM: Verify logging level
sudo ufw status verbose | grep "^Logging:"
# Expected: on (medium) or higher
```

---

## PowerShell Test Commands

```powershell
# Run from host with multipass VM
$VMName = "cloud-init-test"

multipass exec $VMName -- sudo ufw status
multipass exec $VMName -- sudo ufw status verbose
multipass exec $VMName -- sudo ufw status numbered
```
