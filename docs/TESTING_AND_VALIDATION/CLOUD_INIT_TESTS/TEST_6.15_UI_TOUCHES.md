# Test 6.15: UI Touches Fragment

**Template:** `src/autoinstall/cloud-init/90-ui.yaml.tpl`
**Fragment Docs:** [6.15 UI Touches Fragment](../../CLOUD_INIT_CONFIGURATION/UI_TOUCHES_FRAGMENT.md)

Tests CLI productivity tools, dynamic MOTD, and shell aliases.

---

## Test 6.15.1: CLI Package Installation

```bash
# On VM: Verify all CLI packages installed
dpkg -l | grep -E "bat|fd-find|jq|tree|htop|ncdu|neofetch"
# Expected: All packages installed
```

| Check | Command | Expected |
|-------|---------|----------|
| bat | `dpkg -l \| grep "^ii  bat "` | Installed |
| fd-find | `dpkg -l \| grep fd-find` | Installed |
| jq | `which jq` | /usr/bin/jq |
| tree | `which tree` | /usr/bin/tree |
| htop | `which htop` | /usr/bin/htop |
| ncdu | `which ncdu` | /usr/bin/ncdu |
| neofetch | `which neofetch` | /usr/bin/neofetch |

---

## Test 6.15.2: MOTD News Disabled

```bash
# On VM: Verify Ubuntu MOTD news disabled
cat /etc/default/motd-news
# Expected: ENABLED=0

grep "ENABLED=0" /etc/default/motd-news
# Expected: Match found
```

| Check | Command | Expected |
|-------|---------|----------|
| motd-news disabled | `grep ENABLED /etc/default/motd-news` | ENABLED=0 |

---

## Test 6.15.3: Custom MOTD Scripts Exist

```bash
# On VM: Verify custom MOTD scripts exist and are executable
ls -la /etc/update-motd.d/00-header
ls -la /etc/update-motd.d/10-sysinfo
ls -la /etc/update-motd.d/20-vms
ls -la /etc/update-motd.d/30-ssh-config
ls -la /etc/update-motd.d/90-updates
# Expected: All files exist with 755 permissions
```

| Check | Command | Expected |
|-------|---------|----------|
| 00-header | `test -x /etc/update-motd.d/00-header` | Executable |
| 10-sysinfo | `test -x /etc/update-motd.d/10-sysinfo` | Executable |
| 20-vms | `test -x /etc/update-motd.d/20-vms` | Executable |
| 30-ssh-config | `test -x /etc/update-motd.d/30-ssh-config` | Executable |
| 90-updates | `test -x /etc/update-motd.d/90-updates` | Executable |

---

## Test 6.15.4: Ubuntu Default MOTD Disabled

```bash
# On VM: Verify default Ubuntu MOTD scripts are disabled
test -x /etc/update-motd.d/10-help-text && echo "FAIL: still executable" || echo "PASS: disabled"
test -x /etc/update-motd.d/50-motd-news && echo "FAIL: still executable" || echo "PASS: disabled"
test -x /etc/update-motd.d/88-esm-announce && echo "FAIL: still executable" || echo "PASS: disabled"
test -x /etc/update-motd.d/91-contract-ua-esm-status && echo "FAIL: still executable" || echo "PASS: disabled"
# Expected: All return "PASS: disabled"
```

| Check | Command | Expected |
|-------|---------|----------|
| 10-help-text | `test ! -x /etc/update-motd.d/10-help-text` | Not executable |
| 50-motd-news | `test ! -x /etc/update-motd.d/50-motd-news` | Not executable |
| 88-esm-announce | `test ! -x /etc/update-motd.d/88-esm-announce` | Not executable |
| 91-contract | `test ! -x /etc/update-motd.d/91-contract-ua-esm-status` | Not executable |

---

## Test 6.15.5: MOTD Script Execution

```bash
# On VM: Test each MOTD script runs without error
/etc/update-motd.d/00-header
# Expected: Shows hostname banner

/etc/update-motd.d/10-sysinfo
# Expected: Shows uptime, load, memory, disk

/etc/update-motd.d/20-vms
# Expected: Shows VM count (if virsh available)

/etc/update-motd.d/30-ssh-config
# Expected: Shows SSH config snippet

/etc/update-motd.d/90-updates
# Expected: Shows update count (or nothing if up to date)
```

---

## Test 6.15.6: Full MOTD Generation

```bash
# On VM: Generate full MOTD
run-parts /etc/update-motd.d/
# Expected: Complete MOTD output with all sections
```

---

## Test 6.15.7: Shell Aliases File

```bash
# On VM: Verify aliases file exists
cat /etc/profile.d/aliases.sh
# Expected: Shows alias definitions

# On VM: Verify specific aliases defined
grep "alias cat=" /etc/profile.d/aliases.sh
grep "alias fd=" /etc/profile.d/aliases.sh
grep "alias vms=" /etc/profile.d/aliases.sh
# Expected: All aliases present
```

| Check | Command | Expected |
|-------|---------|----------|
| aliases.sh exists | `test -f /etc/profile.d/aliases.sh` | File exists |
| cat alias | `grep "alias cat=" /etc/profile.d/aliases.sh` | batcat |
| fd alias | `grep "alias fd=" /etc/profile.d/aliases.sh` | fdfind |
| vms alias | `grep "alias vms=" /etc/profile.d/aliases.sh` | virsh list |

---

## Test 6.15.8: Aliases Work in New Shell

```bash
# On VM: Start new shell to load aliases
bash -l -c 'type cat'
# Expected: cat is aliased to `batcat --paging=never'

bash -l -c 'type fd'
# Expected: fd is aliased to `fdfind'

bash -l -c 'type vms'
# Expected: vms is aliased to `virsh list --all'
```

---

## Test 6.15.9: CLI Tools Function

```bash
# On VM: Test CLI tools work
batcat --version
# Expected: Shows version

fdfind --version
# Expected: Shows version

jq --version
# Expected: Shows version

tree --version
# Expected: Shows version

htop --version
# Expected: Shows version

ncdu -v
# Expected: Shows version

neofetch --version
# Expected: Shows version
```

---

## Test 6.15.10: Neofetch Profile Script

```bash
# On VM: Verify neofetch profile script exists (disabled by default)
cat /etc/profile.d/neofetch.sh
# Expected: Shows commented neofetch invocation
```

---

## Test 6.15.11: Final Message in Cloud-Init Log

```bash
# On VM: Verify final_message appears in cloud-init output
grep -A 5 "Cloud-init complete" /var/log/cloud-init-output.log
# Expected: Shows final message with Cockpit SSH tunnel instructions
```

---

## PowerShell Test Commands

```powershell
# Run from host with multipass VM
$VMName = "cloud-init-test"

# Package installation
multipass exec $VMName -- dpkg -l | Select-String "bat|fd-find|jq|tree|htop|ncdu|neofetch"

# MOTD configuration
multipass exec $VMName -- cat /etc/default/motd-news
multipass exec $VMName -- ls -la /etc/update-motd.d/

# Test MOTD scripts
multipass exec $VMName -- /etc/update-motd.d/00-header
multipass exec $VMName -- /etc/update-motd.d/10-sysinfo
multipass exec $VMName -- /etc/update-motd.d/20-vms
multipass exec $VMName -- /etc/update-motd.d/30-ssh-config

# Aliases
multipass exec $VMName -- cat /etc/profile.d/aliases.sh

# CLI tools
multipass exec $VMName -- batcat --version
multipass exec $VMName -- fdfind --version
multipass exec $VMName -- jq --version
multipass exec $VMName -- neofetch

# Final message
multipass exec $VMName -- grep -A 5 "Cloud-init complete" /var/log/cloud-init-output.log
```
