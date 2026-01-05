# 7.1 Cloud-init Testing

Test cloud-init configuration with multipass using incremental fragment testing.

> **CRITICAL: NOTHING RUNS ON THE WINDOWS HOST**
>
> | Task | Where it runs |
> |------|---------------|
> | Build (`make cloud-init`) | **Builder VM** (multipass) |
> | Run tests | **Test VM** (multipass) |
>
> The Windows host only orchestrates VMs via PowerShell scripts that source `vm.config.ps1`.
> Never run Python, make, or test scripts directly on Windows.
>
> VirtualBox is only used for [7.2 Autoinstall Testing](./AUTOINSTALL_TESTING.md) (ZFS root, ISO boot).

---

## Incremental Testing Methodology

Cloud-init fragments are tested **incrementally** - each test level includes all fragments from previous levels. This approach:

1. **Isolates failures** - When a test fails, you know exactly which fragment caused it
2. **Validates dependencies** - Ensures fragments work together properly
3. **Provides confidence** - Each level builds on verified previous levels

### Test Levels

| Level | Fragment(s) | Cumulative Fragments |
|-------|-------------|----------------------|
| 6.1 | 10-network | 10-network |
| 6.2 | 15-kernel | 10-network, 15-kernel |
| 6.3 | 20-users | 10-network, 15-kernel, 20-users |
| 6.4 | 25-ssh | + 25-ssh |
| 6.5 | 30-ufw | + 30-ufw |
| 6.6 | 40-system | + 40-system |
| 6.7 | 45-msmtp | + 45-msmtp |
| 6.8 | 50-packages, 50-pkg-security | + 50-packages, 50-pkg-security |
| 6.9 | 55-security-mon | + 55-security-mon |
| 6.10 | 60-virtualization | + 60-virtualization |
| 6.11 | 70-cockpit | + 70-cockpit |
| 6.12 | 75-opencode | + 75-opencode |
| 6.13 | 90-ui | + 90-ui (all fragments) |

---

## Running Tests

### Using the Incremental Test Script

The primary testing method uses `tests/Invoke-IncrementalTest.ps1`:

```powershell
# Test network fragment only (6.1)
.\tests\Invoke-IncrementalTest.ps1 -Level 6.1

# Test fragments 6.1 through 6.5 (network, kernel, users, ssh, ufw)
.\tests\Invoke-IncrementalTest.ps1 -Level 6.5

# Full integration test - all fragments (equivalent to 7.2)
.\tests\Invoke-IncrementalTest.ps1 -Level all

# Keep VMs running for debugging
.\tests\Invoke-IncrementalTest.ps1 -Level 6.3 -SkipCleanup
```

### What the Script Does

Each invocation performs a **complete fresh test cycle**:

1. **Destroys all existing VMs** (builder and runner)
2. **Launches fresh Builder VM** with dependencies
3. **Builds cloud-init** with exactly the fragments needed
4. **Launches Runner VM** with the generated cloud-init
5. **Runs ALL tests** from 6.1 up to the specified level
6. **Reports pass/fail** for each test
7. **Cleans up VMs** (unless `-SkipCleanup`)

### Example Output

```
========================================
 Infrastructure-Host Incremental Tests
========================================

Test Level: 6.3
Levels to test: 6.1, 6.2, 6.3

[1/5] Cleaning up existing VMs...
  Done

[2/5] Setting up builder VM...
  Launching: cloud-init-test
  Waiting for cloud-init...
  Mounting repository...
  Installing dependencies...
  Done

[3/5] Building cloud-init...
  Fragments: 10-network, 15-kernel, 20-users
  Builder args: -i 10-network -i 15-kernel -i 20-users
  Done

[4/5] Launching runner VM...
  Name: cloud-init-runner
  Network: Ethernet 3
  Waiting for cloud-init to complete...
  Done

[5/5] Running tests...

--- Test 6.1 : Network ---
  [PASS] 6.1.1: Short hostname set
  [PASS] 6.1.1: FQDN has domain
  [PASS] 6.1.2: Hostname in /etc/hosts
  [PASS] 6.1.3: Netplan config exists
  [PASS] 6.1.4: IP address assigned
  [PASS] 6.1.4: Default gateway configured
  [PASS] 6.1.4: DNS resolution works

--- Test 6.2 : Kernel Hardening ---
  [PASS] 6.2.1: Security sysctl config exists
  [PASS] 6.2.2: Reverse path filtering enabled
  [PASS] 6.2.2: SYN cookies enabled
  [PASS] 6.2.2: ICMP redirects disabled

--- Test 6.3 : Users ---
  [PASS] 6.3.1: Admin user exists
  [PASS] 6.3.1: Admin shell is bash
  [PASS] 6.3.2: Admin in sudo group
  [PASS] 6.3.3: NOPASSWD sudo configured
  [PASS] 6.3.4: Root account locked

========================================
 Test Summary
========================================

  Levels tested: 6.1, 6.2, 6.3
  Total tests:   16
  Passed:        16
  Failed:        0
```

---

## Individual Test Files

Detailed test specifications for each fragment are in [CLOUD_INIT_TESTS/](./CLOUD_INIT_TESTS/):

| Test | Fragment | Description |
|------|----------|-------------|
| [TEST_6.1](./CLOUD_INIT_TESTS/TEST_6.1_NETWORK.md) | Network | Hostname, netplan, connectivity |
| [TEST_6.2](./CLOUD_INIT_TESTS/TEST_6.2_KERNEL_HARDENING.md) | Kernel Hardening | sysctl security parameters |
| [TEST_6.3](./CLOUD_INIT_TESTS/TEST_6.3_USERS.md) | Users | User creation, groups, sudo |
| [TEST_6.4](./CLOUD_INIT_TESTS/TEST_6.4_SSH_HARDENING.md) | SSH Hardening | sshd configuration |
| [TEST_6.5](./CLOUD_INIT_TESTS/TEST_6.5_UFW.md) | UFW | Firewall rules, rate limiting |
| [TEST_6.6](./CLOUD_INIT_TESTS/TEST_6.6_SYSTEM_SETTINGS.md) | System Settings | Locale, timezone |
| [TEST_6.7](./CLOUD_INIT_TESTS/TEST_6.7_MSMTP.md) | MSMTP | Mail configuration |
| [TEST_6.8](./CLOUD_INIT_TESTS/TEST_6.8_PACKAGE_SECURITY.md) | Package Security | Unattended upgrades |
| [TEST_6.9](./CLOUD_INIT_TESTS/TEST_6.9_SECURITY_MONITORING.md) | Security Monitoring | fail2ban jails |
| [TEST_6.10](./CLOUD_INIT_TESTS/TEST_6.10_VIRTUALIZATION.md) | Virtualization | KVM, libvirt |
| [TEST_6.11](./CLOUD_INIT_TESTS/TEST_6.11_COCKPIT.md) | Cockpit | Web console, localhost binding |
| [TEST_6.12](./CLOUD_INIT_TESTS/TEST_6.12_OPENCODE.md) | OpenCode | AI coding agent |
| [TEST_6.13](./CLOUD_INIT_TESTS/TEST_6.13_UI_TOUCHES.md) | UI Touches | CLI tools, MOTD, aliases |

---

## Configuration Files

Configuration files in `src/config/` are created once from examples and **persist across test runs**. They contain values gathered during earlier chapters.

| File | Created From | Contains |
|------|--------------|----------|
| `network.config.yaml` | Chapter 4 values | IP, gateway, DNS from network planning |
| `identity.config.yaml` | Chapter 5 values | Username, password, SSH keys |
| `storage.config.yaml` | Chapter 5 values | Disk selection settings |
| `image.config.yaml` | Chapter 5 values | Ubuntu release |
| `vm.config.ps1` | Repository root | VM orchestration settings |

**Do not delete or recreate these files** - they are your deployment configuration.

---

## VM Orchestration

**All VM orchestration uses `vm.config.ps1`** in the repository root.

```powershell
# vm.config.ps1 contains:
$VMName = "cloud-init-test"           # Builder VM name
$RunnerVMName = "cloud-init-runner"   # Test VM name
$RunnerNetwork = "Ethernet 3"         # Bridged network for static IP testing
```

The test scripts source this file automatically.

---

## Test Script Files

| Script | Purpose |
|--------|---------|
| `tests/Invoke-IncrementalTest.ps1` | Main test runner - use this |
| `tests/lib/Config.ps1` | Fragment-to-test mapping |
| `tests/lib/Verifications.ps1` | Test verification functions |

---

## Manual Testing (for Debugging)

If you need to manually test or debug:

### Step 1: Build with Specific Fragments

```powershell
# List available fragments
python -m builder list-fragments

# Build cloud-init with specific fragments
python -m builder render cloud-init -o output/cloud-init.yaml -i 10-network -i 20-users -i 25-ssh
```

### Step 2: Launch Test VM

```powershell
. .\vm.config.ps1

multipass launch --name $RunnerVMName --cpus $RunnerCpus --memory $RunnerMemory --disk $RunnerDisk --network $RunnerNetwork --cloud-init output/cloud-init.yaml

multipass exec $RunnerVMName -- cloud-init status --wait
```

### Step 3: Run Manual Checks

```powershell
. .\vm.config.ps1

# Check specific things
multipass exec $RunnerVMName -- hostname -f
multipass exec $RunnerVMName -- id admin
multipass exec $RunnerVMName -- sudo ufw status
```

---

## Troubleshooting

### Debug Commands

```powershell
. .\vm.config.ps1

# Full cloud-init log
multipass exec $RunnerVMName -- cat /var/log/cloud-init-output.log

# Cloud-init errors
multipass exec $RunnerVMName -- grep -iE "error|failed" /var/log/cloud-init.log

# Rendered cloud-init config
multipass exec $RunnerVMName -- sudo cat /var/lib/cloud/instance/cloud-config.txt

# Per-module results
multipass exec $RunnerVMName -- cat /run/cloud-init/result.json
```

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Package not found | Typo or unavailable | Verify package name in Ubuntu repos |
| Service failed | Missing dependency | Check `journalctl -u <service>` |
| Permission denied | Wrong file mode | Verify `write_files` permissions |
| Cockpit on 0.0.0.0 | Socket override missing | Check drop-in config exists |
| fail2ban jail inactive | Config syntax error | Check `/var/log/fail2ban.log` |

### When Tests Fail

1. Run with `-SkipCleanup` to keep VMs running
2. SSH into the runner VM to investigate
3. Check cloud-init logs for errors
4. Fix the fragment template
5. Run the **full test again from scratch** (always reverify all previous levels)
