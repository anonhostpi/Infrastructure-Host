# Test 6.4: SSH Hardening Fragment

**Template:** `src/autoinstall/cloud-init/25-ssh.yaml.tpl`
**Fragment Docs:** [6.4 SSH Hardening Fragment](../../CLOUD_INIT_CONFIGURATION/SSH_HARDENING_FRAGMENT.md)

Tests sshd hardening configuration.

---

## Test 6.4.1: SSH Configuration File

```bash
# On VM: Verify hardening config exists
cat /etc/ssh/sshd_config.d/99-hardening.conf
# Expected: Shows hardening settings
```

---

## Test 6.4.2: Authentication Settings

```bash
# On VM: Get effective SSH config
sudo sshd -T | grep -E "^permitrootlogin|^maxauthtries|^logingracetime|^permitemptypasswords|^challengeresponseauthentication"
```

| Check | Command | Expected |
|-------|---------|----------|
| Root login | `sudo sshd -T \| grep permitrootlogin` | no |
| Max auth tries | `sudo sshd -T \| grep maxauthtries` | 3 |
| Login grace time | `sudo sshd -T \| grep logingracetime` | 20 |
| Empty passwords | `sudo sshd -T \| grep permitemptypasswords` | no |
| Challenge-response | `sudo sshd -T \| grep challengeresponseauthentication` | no |

---

## Test 6.4.3: Forwarding Settings

```bash
# On VM: Verify forwarding settings
sudo sshd -T | grep -E "^x11forwarding|^allowtcpforwarding"
```

| Check | Command | Expected |
|-------|---------|----------|
| X11 forwarding | `sudo sshd -T \| grep x11forwarding` | no |
| TCP forwarding | `sudo sshd -T \| grep allowtcpforwarding` | yes |

---

## Test 6.4.4: Session Timeout

```bash
# On VM: Verify timeout settings
sudo sshd -T | grep -E "^clientaliveinterval|^clientalivecountmax"
```

| Check | Command | Expected |
|-------|---------|----------|
| Alive interval | `sudo sshd -T \| grep clientaliveinterval` | 300 |
| Alive count max | `sudo sshd -T \| grep clientalivecountmax` | 2 |

---

## Test 6.4.5: SSH Service Running

```bash
# On VM: Verify SSH service is active
systemctl is-active ssh
# Expected: active
```

---

## PowerShell Test Commands

```powershell
# Run from host with multipass VM
$VMName = "cloud-init-test"

multipass exec $VMName -- cat /etc/ssh/sshd_config.d/99-hardening.conf
multipass exec $VMName -- sudo sshd -T | Select-String "permitrootlogin|maxauthtries|logingracetime"
multipass exec $VMName -- sudo sshd -T | Select-String "x11forwarding|allowtcpforwarding"
multipass exec $VMName -- sudo sshd -T | Select-String "clientaliveinterval|clientalivecountmax"
multipass exec $VMName -- systemctl is-active ssh
```
