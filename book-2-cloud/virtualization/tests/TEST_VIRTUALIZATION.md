# Test 6.10: Virtualization Fragment

**Template:** `book-2-cloud/virtualization/fragment.yaml.tpl`
**Fragment Docs:** [Virtualization Fragment](../../docs/FRAGMENT.md)

Tests KVM/libvirt installation, multipass, default network, and qemu hook.

---

## Test 6.10.1: Package Installation

```bash
# On VM: Verify virtualization packages
dpkg -l | grep -E "qemu-kvm|libvirt-daemon-system|libvirt-clients|virtinst"
# Expected: All four packages installed
```

| Check | Command | Expected |
|-------|---------|----------|
| qemu-kvm | `dpkg -l \| grep qemu-kvm` | Installed |
| libvirt-daemon | `dpkg -l \| grep libvirt-daemon-system` | Installed |
| libvirt-clients | `dpkg -l \| grep libvirt-clients` | Installed |
| virtinst | `dpkg -l \| grep virtinst` | Installed |

---

## Test 6.10.2: Multipass Installation

```bash
# On VM: Verify multipass snap installed
snap list | grep multipass
# Expected: multipass listed

multipass version
# Expected: Shows version
```

| Check | Command | Expected |
|-------|---------|----------|
| multipass snap | `snap list \| grep multipass` | Listed |
| multipass works | `multipass version` | Shows version |

---

## Test 6.10.3: Libvirt Service

```bash
# On VM: Verify libvirtd running
systemctl is-active libvirtd
# Expected: active

systemctl is-enabled libvirtd
# Expected: enabled
```

| Check | Command | Expected |
|-------|---------|----------|
| libvirtd active | `systemctl is-active libvirtd` | active |
| libvirtd enabled | `systemctl is-enabled libvirtd` | enabled |

---

## Test 6.10.4: Default Network

```bash
# On VM: Verify default network exists and is active
virsh net-list --all | grep default
# Expected: default active yes (autostart)

# On VM: Verify network autostart
virsh net-info default | grep Autostart
# Expected: Autostart: yes
```

| Check | Command | Expected |
|-------|---------|----------|
| Network exists | `virsh net-list --all \| grep default` | Listed |
| Network active | `virsh net-list \| grep default` | active |
| Autostart | `virsh net-info default \| grep Autostart` | yes |

---

## Test 6.10.5: KVM Support

```bash
# On VM: Verify KVM acceleration available
kvm-ok 2>/dev/null || ls -la /dev/kvm
# Expected: KVM acceleration available OR /dev/kvm exists
```

---

## Test 6.10.6: QEMU Hook Script

```bash
# On VM: Verify qemu hook exists with correct permissions
ls -la /etc/libvirt/hooks/qemu
# Expected: -rwxr-xr-x (755)

# On VM: Verify hook content
head -5 /etc/libvirt/hooks/qemu
# Expected: #!/bin/bash with VM lifecycle handling
```

| Check | Command | Expected |
|-------|---------|----------|
| Hook exists | `test -f /etc/libvirt/hooks/qemu` | File exists |
| Hook executable | `test -x /etc/libvirt/hooks/qemu` | Executable |

---

## Test 6.10.7: Multipass VM Lifecycle (Optional)

```bash
# On VM: Test multipass can create/destroy VM
multipass launch --name test-vm --cpus 1 --memory 512M --disk 2G
multipass exec test-vm -- uname -a
# Expected: Shows Linux kernel info

multipass delete test-vm && multipass purge
# Expected: VM deleted
```

---

## PowerShell Test Commands

```powershell
# Run from host with multipass VM
$VMName = "cloud-init-test"

multipass exec $VMName -- dpkg -l | Select-String "qemu-kvm|libvirt-daemon-system|libvirt-clients|virtinst"
multipass exec $VMName -- snap list | Select-String "multipass"
multipass exec $VMName -- systemctl is-active libvirtd
multipass exec $VMName -- virsh net-list --all
multipass exec $VMName -- virsh net-info default
multipass exec $VMName -- ls -la /etc/libvirt/hooks/qemu
multipass exec $VMName -- head -10 /etc/libvirt/hooks/qemu
```
