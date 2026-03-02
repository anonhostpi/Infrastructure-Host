# Test 6.3: Users Fragment

**Template:** `book-2-cloud/users/fragment.yaml.tpl`
**Fragment Docs:** [6.3 Users Fragment](../docs/FRAGMENT.md)

Tests user creation, groups, sudo configuration, and SSH keys.

---

## Test 6.3.1: User Exists

```bash
# On VM: Verify admin user exists
id admin
# Expected: uid and gid shown

# On VM: Verify user has home directory
test -d /home/admin && echo "Home exists"
# Expected: Home exists

# On VM: Verify shell is bash
getent passwd admin | cut -d: -f7
# Expected: /bin/bash
```

| Check | Command | Expected |
|-------|---------|----------|
| User exists | `id admin` | Shows uid/gid |
| Home directory | `test -d /home/admin` | Exists |
| Shell is bash | `getent passwd admin \| cut -d: -f7` | /bin/bash |

---

## Test 6.3.2: Group Membership

```bash
# On VM: Verify user in required groups
groups admin
# Expected: Contains sudo, libvirt, kvm

groups admin | grep -q sudo && echo "In sudo group"
groups admin | grep -q libvirt && echo "In libvirt group"
groups admin | grep -q kvm && echo "In kvm group"
```

| Check | Command | Expected |
|-------|---------|----------|
| In sudo group | `groups admin \| grep sudo` | Match |
| In libvirt group | `groups admin \| grep libvirt` | Match |
| In kvm group | `groups admin \| grep kvm` | Match |

---

## Test 6.3.3: Sudo Configuration

```bash
# On VM: Verify passwordless sudo
sudo -l -U admin
# Expected: NOPASSWD: ALL

# On VM: Test sudo works without password
sudo -n whoami
# Expected: root
```

| Check | Command | Expected |
|-------|---------|----------|
| NOPASSWD configured | `sudo -l -U admin` | Shows NOPASSWD |
| Sudo works | `sudo -n whoami` | root |

---

## Test 6.3.4: Root Disabled

```bash
# On VM: Verify root login disabled
grep "^root:" /etc/shadow | cut -d: -f2
# Expected: Starts with ! or * (locked)
```

---

## Test 6.3.5: SSH Keys (if configured)

```bash
# On VM: Verify authorized_keys exists (if SSH keys were configured)
test -f /home/admin/.ssh/authorized_keys && wc -l < /home/admin/.ssh/authorized_keys
# Expected: Number of keys configured
```

---

## PowerShell Test Commands

```powershell
# Run from host with multipass VM
$VMName = "cloud-init-test"

multipass exec $VMName -- id admin
multipass exec $VMName -- groups admin
multipass exec $VMName -- sudo -l -U admin
multipass exec $VMName -- sudo -n whoami
multipass exec $VMName -- getent passwd admin
```
