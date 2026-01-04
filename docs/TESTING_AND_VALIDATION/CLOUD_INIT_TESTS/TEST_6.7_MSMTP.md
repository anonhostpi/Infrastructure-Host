# Test 6.7: MSMTP Fragment

**Template:** `src/autoinstall/cloud-init/45-msmtp.yaml.tpl`
**Fragment Docs:** [6.7 MSMTP Fragment](../../CLOUD_INIT_CONFIGURATION/MSMTP_FRAGMENT.md)

Tests msmtp installation, configuration files, and helper script.

**Note:** These tests only apply if `smtp.config.yaml` is configured.

---

## Test 6.7.1: Package Installation

```bash
# On VM: Verify msmtp installed
which msmtp
# Expected: /usr/bin/msmtp

dpkg -l | grep msmtp-mta
# Expected: Shows msmtp-mta installed
```

| Check | Command | Expected |
|-------|---------|----------|
| msmtp binary | `which msmtp` | /usr/bin/msmtp |
| msmtp-mta package | `dpkg -l \| grep msmtp-mta` | Installed |

---

## Test 6.7.2: Configuration Files

```bash
# On VM: Verify msmtprc exists with correct permissions
ls -la /etc/msmtprc
# Expected: -rw------- (600) root root

# On VM: Verify aliases file
cat /etc/aliases | grep "^root:"
# Expected: root: <configured recipient>
```

| Check | Command | Expected |
|-------|---------|----------|
| msmtprc exists | `test -f /etc/msmtprc` | File exists |
| msmtprc permissions | `stat -c %a /etc/msmtprc` | 600 |
| aliases configured | `grep "^root:" /etc/aliases` | Shows recipient |

---

## Test 6.7.3: Helper Script

```bash
# On VM: Verify config helper script exists
ls -la /usr/local/bin/msmtp-config
# Expected: -rwxr-xr-x (755)
```

---

## Test 6.7.4: Log Rotation

```bash
# On VM: Verify logrotate config
cat /etc/logrotate.d/msmtp
# Expected: Shows rotation config for /var/log/msmtp.log
```

---

## Test 6.7.5: Send Test (Manual)

```bash
# On VM: After running msmtp-config to set password
# echo -e "Subject: Test\n\nTest from VM" | msmtp root
# Expected: Email received (requires valid SMTP credentials)
```

---

## PowerShell Test Commands

```powershell
# Run from host with multipass VM
$VMName = "cloud-init-test"

multipass exec $VMName -- which msmtp
multipass exec $VMName -- dpkg -l | Select-String "msmtp"
multipass exec $VMName -- ls -la /etc/msmtprc
multipass exec $VMName -- stat -c "%a %U:%G" /etc/msmtprc
multipass exec $VMName -- cat /etc/aliases
multipass exec $VMName -- ls -la /usr/local/bin/msmtp-config
multipass exec $VMName -- cat /etc/logrotate.d/msmtp
```
