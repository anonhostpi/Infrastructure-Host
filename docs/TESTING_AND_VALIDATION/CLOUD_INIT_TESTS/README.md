# Cloud-Init Fragment Tests

Individual test specifications for each Chapter 6 cloud-init fragment.

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
| [TEST_6.12](./TEST_6.12_OPENCODE.md) | OpenCode | `75-opencode.yaml.tpl` |
| [TEST_6.13](./TEST_6.13_UI_TOUCHES.md) | UI Touches | `90-ui.yaml.tpl` |

## Testing Platform

All tests in this folder are designed to run on **multipass VMs**. See the [Testing Overview](../OVERVIEW.md) for platform requirements.

## Test Structure

Each test file follows a consistent format:

1. **Header** - Template file and fragment documentation link
2. **Numbered Tests** - Individual test cases (e.g., Test 6.1.1, 6.1.2, etc.)
3. **Check Tables** - Command and expected result for each verification
4. **PowerShell Commands** - Host-side commands for running tests via multipass exec

## Running Tests

### Quick Test (Single Fragment)

```powershell
$VMName = "cloud-init-test"

# Example: Run network tests
multipass exec $VMName -- ip addr show
multipass exec $VMName -- cat /etc/netplan/50-cloud-init.yaml
```

### Full Test Suite

Use the comprehensive test script from the parent [CLOUD_INIT_TESTING.md](../CLOUD_INIT_TESTING.md).

## Conditional Tests

Some fragments are optional and tests should be skipped if not configured:

| Fragment | Condition |
|----------|-----------|
| 6.7 MSMTP | `smtp.config.yaml` exists |
| 6.12 OpenCode | `opencode.enabled: true` |

Check the individual test file for skip conditions.
