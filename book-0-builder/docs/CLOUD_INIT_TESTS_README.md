# Cloud-Init Fragment Tests

Individual test specifications for each Chapter 6 cloud-init fragment.

---

## Testing Platform Requirements

> **CRITICAL: NOTHING RUNS ON THE WINDOWS HOST**
>
> | Task | Where it runs |
> |------|---------------|
> | Build (`make cloud-init`) | **Builder VM** (multipass) |
> | Run fragment tests | **Test VM** (multipass) |
> | Autoinstall ISO tests | **Test VM** (VirtualBox) |
>
> The Windows host only orchestrates VMs via `multipass` commands.
> **Never run Python, make, or test scripts directly on Windows.**

**Why Multipass for cloud-init tests?**
- Fast iteration (seconds to launch)
- Native cloud-init support
- No manual ISO burning required
- Bridged networking for realistic testing

**When to use VirtualBox instead:**
- Testing the autoinstall ISO boot process
- Testing ZFS root filesystem (requires real disk partitioning)
- Testing UEFI boot sequence

---

## Test Files

| Test | Fragment | Template |
|------|----------|----------|
| [TEST_6.1](./TEST_6.1_NETWORK.md) | Network Configuration | `10-network.yaml.tpl` |
| [TEST_6.2](./TEST_6.2_KERNEL_HARDENING.md) | Kernel Hardening | `15-kernel.yaml.tpl` |
| [TEST_6.3](./TEST_6.3_USERS.md) | Users Configuration | `20-users.yaml.tpl` |
| [TEST_6.4](./TEST_6.4_SSH_HARDENING.md) | SSH Hardening | `25-ssh.yaml.tpl` |
| [TEST_6.5](./TEST_6.5_UFW.md) | UFW Firewall | `30-ufw.yaml.tpl` |
| [TEST_6.6](./TEST_6.6_SYSTEM_SETTINGS.md) | System Settings | `40-system.yaml.tpl` |
| [TEST_6.7](./TEST_6.7_MSMTP.md) | MSMTP Mail | `45-msmtp.yaml.tpl` |
| [TEST_6.8](./TEST_6.8_PACKAGE_SECURITY.md) | Package Security | `50-pkg-security.yaml.tpl` |
| [TEST_6.9](./TEST_6.9_SECURITY_MONITORING.md) | Security Monitoring | `55-security-mon.yaml.tpl` |
| [TEST_6.10](./TEST_6.10_VIRTUALIZATION.md) | Virtualization | `60-virtualization.yaml.tpl` |
| [TEST_6.11](./TEST_6.11_COCKPIT.md) | Cockpit | `70-cockpit.yaml.tpl` |
| [TEST_6.12](./TEST_6.12_CLAUDE_CODE.md) | Claude Code | `75-claude-code.yaml.tpl` |
| [TEST_6.13](./TEST_6.13_COPILOT_CLI.md) | Copilot CLI | `76-copilot-cli.yaml.tpl` |
| [TEST_6.14](./TEST_6.14_OPENCODE.md) | OpenCode | `77-opencode.yaml.tpl` |
| [TEST_6.15](./TEST_6.15_UI_TOUCHES.md) | UI Touches | `90-ui.yaml.tpl` |

---

## Running Tests

**All orchestration uses `vm.config.ps1`** - always source it first.

### Step 1: Build cloud-init configuration (on Builder VM)

```powershell
. .\vm.config.ps1

multipass exec $BuilderVMName -- bash -c "cd /home/ubuntu/infra-host && make cloud-init"
```

### Step 2: Launch test VM

```powershell
. .\vm.config.ps1

multipass launch --name $VMName --cpus $VMCpus --memory $VMMemory --disk $VMDisk --network $VMNetwork --cloud-init output/cloud-init.yaml
multipass exec $VMName -- cloud-init status --wait
```

### Step 3: Run tests on the VM

```powershell
. .\vm.config.ps1

# All commands run ON THE VM via multipass exec
multipass exec $VMName -- hostname -f
multipass exec $VMName -- systemctl is-active libvirtd
multipass exec $VMName -- sudo ufw status
```

### Step 4: Cleanup

```powershell
. .\vm.config.ps1

multipass delete $VMName && multipass purge
```

---

## Test Structure

Each test file follows a consistent format:

1. **Header** - Template file and fragment documentation link
2. **Platform Notice** - Confirms tests run on multipass VM
3. **Numbered Tests** - Individual test cases with bash commands
4. **Check Tables** - Command and expected result for verification
5. **PowerShell Section** - Host-side commands using `multipass exec`
6. **Footer** - Test results and lessons learned

---

## Conditional Tests

Some fragments are optional and tests should be skipped if not configured:

| Fragment | Skip Condition |
|----------|----------------|
| 6.7 MSMTP | `smtp.config.yaml` does not exist |
| 6.12 Claude Code | `claude_code.enabled: false` or not set |
| 6.13 Copilot CLI | `copilot_cli.enabled: false` or not set |
| 6.14 OpenCode | `opencode.enabled: false` or not set |

Check the individual test file for skip conditions.
