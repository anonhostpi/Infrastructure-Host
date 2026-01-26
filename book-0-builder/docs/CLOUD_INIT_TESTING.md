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
| 6.1 | network | network |
| 6.2 | kernel | network, kernel |
| 6.3 | users | network, kernel, users |
| 6.4 | ssh | + ssh |
| 6.5 | ufw | + ufw |
| 6.6 | system | + system |
| 6.7 | msmtp | + msmtp |
| 6.8 | packages, pkg-security, pkg-upgrade | + packages, pkg-security, pkg-upgrade |
| 6.9 | security-mon | + security-mon |
| 6.10 | virtualization | + virtualization |
| 6.11 | cockpit | + cockpit |
| 6.12 | claude-code | + claude-code |
| 6.13 | copilot-cli | + copilot-cli |
| 6.14 | opencode | + opencode |
| 6.15 | ui | + ui (all fragments) |

### Extended Test Levels

These levels run after all fragment tests to validate cross-fragment functionality:

| Level | Tests | Description |
|-------|-------|-------------|
| 6.8-updates | 6.8.19-6.8.24 | Execute package manager update scripts |
| 6.8-summary | 6.8.25-6.8.27 | Validate apt-notify-flush report generation and AI summary |
| 6.8-flush | 6.8.28 | Verify notification flush logging |

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
Levels to test: 6.1 6.2 6.3

[1/6] Cleaning up existing VMs -- This may take a while. Please wait...
  Done

[2/6] Setting up builder VM -- This may take a while. Please wait...
  Launching: cloud-init-test
  Waiting for cloud-init...
  Mounting repository...
  Installing dependencies...
  Done

[3/6] Building cloud-init -- This may take a while. Please wait...
  Fragments: network, kernel, users
  Builder args: -i network -i kernel -i users
  Output: D:\Orchestrations\Infrastructure-Host\output\cloud-init.yaml
  Done

[4/6] Launching runner VM -- This may take a while. Please wait...
  Name: cloud-init-runner
  Network: Ethernet 3
  Done

[5/6] Waiting for cloud-init to complete -- This may take a while. Please wait...
  Done

[6/6] Enabling nested virtualization -- This may take a while. Please wait...
  Stopping VM for reconfiguration...
  Enabling ExposeVirtualizationExtensions...
  Nested virtualization enabled
  Starting VM...
  Done

Running tests...

--- Test 6.1 : Network ---
  [PASS] 6.1.1: Short hostname set (00:02.314)
  [PASS] 6.1.1: FQDN has domain (00:02.564)
  [PASS] 6.1.2: Hostname in /etc/hosts (00:02.666)
  [PASS] 6.1.3: Netplan config exists (00:02.776)
  [PASS] 6.1.4: IP address assigned (00:02.752)
  [PASS] 6.1.4: Default gateway configured (00:02.432)
  [PASS] 6.1.4: DNS resolution works (00:02.747)

--- Test 6.2 : Kernel Hardening ---
  [PASS] 6.2.1: Security sysctl config exists (00:02.641)
  [PASS] 6.2.2: Reverse path filtering enabled (00:03.269)
  [PASS] 6.2.2: SYN cookies enabled (00:03.017)
  [PASS] 6.2.2: ICMP redirects disabled (00:04.109)

--- Test 6.3 : Users ---
  [PASS] 6.3.1: admin user exists (00:02.845)
  [PASS] 6.3.1: admin shell is bash (00:02.967)
  [PASS] 6.3.2: admin in sudo group (00:02.608)
  [PASS] 6.3.3: Sudoers file exists (00:02.617)
  [PASS] 6.3.4: Root account locked (00:02.813)

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
| [TEST_6.8](./CLOUD_INIT_TESTS/TEST_6.8_PACKAGE_SECURITY.md) | Package Security | Unattended upgrades, pkg manager scripts |
| [TEST_6.9](./CLOUD_INIT_TESTS/TEST_6.9_SECURITY_MONITORING.md) | Security Monitoring | fail2ban jails |
| [TEST_6.10](./CLOUD_INIT_TESTS/TEST_6.10_VIRTUALIZATION.md) | Virtualization | KVM, libvirt, nested VMs |
| [TEST_6.11](./CLOUD_INIT_TESTS/TEST_6.11_COCKPIT.md) | Cockpit | Web console, localhost binding |
| [TEST_6.12](./CLOUD_INIT_TESTS/TEST_6.12_CLAUDE_CODE.md) | Claude Code | Anthropic's Claude Code CLI |
| [TEST_6.13](./CLOUD_INIT_TESTS/TEST_6.13_COPILOT_CLI.md) | Copilot CLI | GitHub Copilot CLI |
| [TEST_6.14](./CLOUD_INIT_TESTS/TEST_6.14_OPENCODE.md) | OpenCode | OpenCode AI coding agent |
| [TEST_6.15](./CLOUD_INIT_TESTS/TEST_6.15_UI_TOUCHES.md) | UI Touches | MOTD scripts |

---

## Configuration Files

Configuration files in `book-*/*/config/` directories are created once from examples and **persist across test runs**. They contain values gathered during earlier chapters.

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
python -m builder render cloud-init -o output/cloud-init.yaml -i network -i users -i ssh
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
