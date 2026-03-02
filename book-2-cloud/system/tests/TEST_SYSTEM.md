# Test 6.6: System Settings Fragment

**Template:** `book-2-cloud/system/fragment.yaml.tpl`
**Fragment Docs:** [6.6 System Settings Fragment](../docs/FRAGMENT.md)

Tests locale, keyboard, and timezone configuration.

---

## Test 6.6.1: Locale Configuration

```bash
# On VM: Verify locale
localectl status | grep "System Locale"
# Expected: LANG=en_US.UTF-8

locale | grep LANG
# Expected: LANG=en_US.UTF-8
```

| Check | Command | Expected |
|-------|---------|----------|
| System locale | `localectl status` | en_US.UTF-8 |

---

## Test 6.6.2: Keyboard Layout

```bash
# On VM: Verify keyboard layout
localectl status | grep "VC Keymap"
# Expected: us (or configured layout)
```

---

## Test 6.6.3: Timezone

```bash
# On VM: Verify timezone
timedatectl show --property=Timezone --value
# Expected: America/Phoenix (or configured timezone)

# On VM: Alternative check
cat /etc/timezone
# Expected: America/Phoenix
```

| Check | Command | Expected |
|-------|---------|----------|
| Timezone set | `timedatectl show --property=Timezone` | America/Phoenix |

---

## PowerShell Test Commands

```powershell
# Run from host with multipass VM
$VMName = "cloud-init-test"

multipass exec $VMName -- localectl status
multipass exec $VMName -- locale
multipass exec $VMName -- timedatectl
multipass exec $VMName -- cat /etc/timezone
```
