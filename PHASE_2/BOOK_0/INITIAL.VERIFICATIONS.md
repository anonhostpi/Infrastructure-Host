# Review: Verifications Module

## Missing Layer Implementations (4-18)

**Current State**: Only layers 1-3 are implemented in the refactored Verifications.ps1.

---

### Run Method References All 18 Layers

```powershell
Run = {
    param($Worker, [int]$Layer)
    $methods = @{
        1 = "Network"; 2 = "Kernel"; 3 = "Users"; 4 = "SSH"; 5 = "UFW"
        6 = "System"; 7 = "MSMTP"; 8 = "PackageSecurity"; 9 = "SecurityMonitoring"
        10 = "Virtualization"; 11 = "Cockpit"; 12 = "ClaudeCode"
        13 = "CopilotCLI"; 14 = "OpenCode"; 15 = "UI"
        16 = "PackageManagerUpdates"; 17 = "UpdateSummary"; 18 = "NotificationFlush"
    }
    foreach ($l in 1..$Layer) {
        if ($methods.ContainsKey($l)) {
            $methodName = $methods[$l]
            if ($this.PSObject.Methods[$methodName]) {
                $this.$methodName($Worker)
            }
        }
    }
}
```

---

### Implementation Status

| Layer | Method | Status | Test Count | Complexity |
|-------|--------|--------|------------|------------|
| 1 | Network | Implemented | 8 | Simple |
| 2 | Kernel | Implemented | 4 | Simple |
| 3 | Users | Implemented | 5 | Simple |
| 4 | SSH | **Missing** | 5 | Medium (host SSH tests) |
| 5 | UFW | **Missing** | 3 | Simple |
| 6 | System | **Missing** | 3 | Simple |
| 7 | MSMTP | **Missing** | 11 | Complex (config validation, provider logic) |
| 8 | PackageSecurity | **Missing** | 18 | Medium (many tests) |
| 9 | SecurityMonitoring | **Missing** | 3 | Simple |
| 10 | Virtualization | **Missing** | 9 | Complex (nested VM tests, KVM) |
| 11 | Cockpit | **Missing** | 7 | Complex (SSH tunnel, web requests) |
| 12 | ClaudeCode | **Missing** | 5 | Complex (AI response, jobs) |
| 13 | CopilotCLI | **Missing** | 5 | Complex (AI response, jobs) |
| 14 | OpenCode | **Missing** | 7 | Complex (AI response, credential chain) |
| 15 | UI | **Missing** | 2 | Simple |
| 16 | PackageManagerUpdates | **Missing** | 7 | Medium (testing mode only) |
| 17 | UpdateSummary | **Missing** | 3 | Medium (AI summary validation) |
| 18 | NotificationFlush | **Missing** | 1 | Simple |

---

## Complexity Categories

### Simple (UFW, System, SecurityMonitoring, UI, NotificationFlush)

Direct `$Worker.Exec()` + `$mod.SDK.Testing.Record()` pattern. No special logic.

### Medium (SSH, PackageSecurity, PackageManagerUpdates, UpdateSummary)

Multiple tests, some conditional logic, but no external processes or Jobs.

### Complex (MSMTP, Virtualization, Cockpit, ClaudeCode, CopilotCLI, OpenCode)

Involve one or more of:
- Host-side SSH connections (not via Worker)
- SSH tunnels
- PowerShell Jobs with timeouts
- External process management
- Config-dependent conditional test paths (forking)
- AI CLI invocations

---

## Migration Pattern

### Standard Pattern (Simple/Medium)

**Old (master)**:
```powershell
function Test-SSHFragment {
    param([string]$VMName)
    $result = multipass exec $VMName -- test -f /etc/ssh/sshd_config 2>&1
    <# (multi) return #> @{
        Test = "6.4.1"; Name = "SSHD config exists"
        Pass = ($LASTEXITCODE -eq 0); Output = $result
    }
}
```

**New (module method)**:
```powershell
SSH = {
    param($Worker)
    $result = $Worker.Exec("test -f /etc/ssh/sshd_config")
    $mod.SDK.Testing.Record(@{
        Test = "6.4.1"; Name = "SSHD config exists"
        Pass = $result.Success; Output = $result.Output
    })
}
```

### Key Differences

| Aspect | Old (master) | New (module) |
|--------|--------------|--------------|
| Parameter | `$VMName` string | `$Worker` object |
| Execution | `multipass exec $VMName --` | `$Worker.Exec()` |
| Return | Multiple `@{}` hashtables | `$mod.SDK.Testing.Record()` calls |
| Exit check | `$LASTEXITCODE -eq 0` | `$result.Success` |
| Scope | Multipass-only | Works with any worker type |
| Fork logging | `Write-TestFork` | `$this.Fork()` |

---

## Design Decisions

### 1. Host-Side SSH Tests (SSH, Cockpit)

**Problem**: Tests like 6.4.4 (root SSH login rejected) and 6.11.7 (Cockpit via SSH tunnel) require the HOST to initiate SSH connections to the VM, not the Worker executing commands inside the VM.

**Options**:

A. **Worker provides SSH connection info** - Worker exposes `$Worker.SSHUser`, `$Worker.SSHHost`, `$Worker.SSHPort` for host-side operations.

B. **SDK.Network methods** - Use `$mod.SDK.Network.SSH()` for host-side SSH.

C. **Skip these tests** - Mark as not applicable in Worker-based testing.

**Decision**: Option A + B. The Worker already has `SSHUser`, `SSHHost`, `SSHPort` properties (from Worker.ps1 line 70-71). Verification methods can use these with `$mod.SDK.Network.SSH()` for host-side tests.

### 2. PowerShell Jobs with Timeouts (ClaudeCode, CopilotCLI, OpenCode)

**Problem**: AI CLI tests use `Start-Job` + `Wait-Job -Timeout` to handle hanging commands.

**Options**:

A. **Keep Jobs** - Port the Job logic directly.

B. **SDK.Job** - Use `$mod.SDK.Job()` which already handles timeout Jobs.

C. **timeout command** - Use `timeout` inside Worker.Exec() (Linux-side).

**Decision**: Option C preferred for simplicity. Use `$Worker.Exec("timeout 30 claude -p test")`. If the command hangs, Linux `timeout` kills it. Falls back to Option A for complex cases.

### 3. Config-Dependent Forking

**Problem**: Many tests fork based on SDK.Settings (e.g., MSMTP tests skip if `smtp.host` not configured).

**Decision**: Use `$mod.SDK.Settings` directly and call `$this.Fork()` for logging fork decisions. This is already supported.

### 4. Helper Functions

**Problem**: Master has helpers like `Get-SMTPProviderName` and `Test-FuzzyModelMatch`.

**Decision**: Add as private methods or nested functions within the method body. Avoid polluting module namespace.

---

## Implementation Plan by Layer

### Layer 4: SSH (Medium - 5 tests)

- 6.4.1: SSH hardening config exists - `$Worker.Exec("test -f ...")`
- 6.4.2: Key settings (PermitRootLogin, MaxAuthTries) - `$Worker.Exec("grep ...")`
- 6.4.3: SSH service active - `$Worker.Exec("systemctl is-active ssh")`
- 6.4.4: Root SSH login rejected - **Host-side**: `$mod.SDK.Network.SSH()` as root
- 6.4.5: SSH key auth works - **Host-side**: `$mod.SDK.Network.SSH()` as user

### Layer 5: UFW (Simple - 3 tests)

- 6.5.1: UFW is active
- 6.5.2: SSH allowed in UFW
- 6.5.3: Default deny incoming

### Layer 6: System (Simple - 3 tests)

- 6.6.1: Timezone configured
- 6.6.2: Locale set
- 6.6.3: NTP enabled

### Layer 7: MSMTP (Complex - 11 tests)

- 6.7.1-6.7.3: Basic msmtp installation checks
- 6.7.4-6.7.8: Config verification against `$mod.SDK.Settings.SMTP`
- 6.7.9: Root alias configured
- 6.7.10: msmtp-config helper exists
- 6.7.11: Send test email (conditional on password configured)

**Note**: Contains `Get-SMTPProviderName` helper logic.

### Layer 8: PackageSecurity (Medium - 18 tests)

- 6.8.1-6.8.4: Unattended upgrades
- 6.8.5-6.8.6: apt-listchanges
- 6.8.7-6.8.9: apt-notify scripts and hooks
- 6.8.10-6.8.15: Package manager update scripts (snap, brew, pip, npm, deno)
- 6.8.16-6.8.18: Timer and common library

### Layer 9: SecurityMonitoring (Simple - 3 tests)

- 6.9.1: fail2ban installed
- 6.9.2: fail2ban service active
- 6.9.3: SSH jail configured

### Layer 10: Virtualization (Complex - 9 tests)

- 6.10.1-6.10.6: libvirt, QEMU, Multipass basics
- 6.10.7: KVM available for nesting
- 6.10.8-6.10.9: Nested VM launch and exec (conditional on KVM)

**Note**: Nested VM tests launch/delete VMs inside the Worker VM.

### Layer 11: Cockpit (Complex - 7 tests)

- 6.11.1-6.11.3: Cockpit installation
- 6.11.4-6.11.6: Socket listening, web UI responds, login page
- 6.11.7: Cockpit via SSH tunnel - **Host-side**: SSH tunnel + curl

### Layer 12: ClaudeCode (Complex - 5 tests)

- 6.12.1-6.12.3: Installation and config
- 6.12.4: Auth configured (OAuth or API key)
- 6.12.5: AI response test (conditional, with timeout)

### Layer 13: CopilotCLI (Complex - 5 tests)

- 6.13.1-6.13.3: Installation and config
- 6.13.4: Auth configured
- 6.13.5: AI response test (conditional, with timeout)

### Layer 14: OpenCode (Complex - 7 tests)

- 6.14.1-6.14.4: Node.js, npm, installation, config
- 6.14.5: Auth.json configured
- 6.14.6: AI response test (conditional, with timeout)
- 6.14.7: Credential chain verification (host → builder → runner)

### Layer 15: UI (Simple - 2 tests)

- 6.15.1: MOTD directory exists
- 6.15.2: MOTD scripts present

### Layer 16: PackageManagerUpdates (Medium - 7 tests, testing mode only)

- 6.8.19: Testing mode enabled
- 6.8.20-6.8.24: Individual package manager script execution tests
- All require `TESTING_MODE=true`

### Layer 17: UpdateSummary (Medium - 3 tests, testing mode only)

- 6.8.25: apt-notify-flush generates test report
- 6.8.26: Report contains expected sections
- 6.8.27: AI summary reports valid model

### Layer 18: NotificationFlush (Simple - 1 test)

- 6.8.28: apt-notify-flush logged execution

---

## Estimated Scope

| Complexity | Layers | Estimated Commits |
|------------|--------|-------------------|
| Simple | 5, 6, 9, 15, 18 | ~10 (2 per layer) |
| Medium | 4, 8, 16, 17 | ~25 |
| Complex | 7, 10, 11, 12, 13, 14 | ~40 |

**Total**: ~75 commits for full implementation

---

## Open Questions

1. **Should complex host-side tests be skipped for non-Multipass workers?**
   - Option: Check `$Worker.SSHHost` availability before host-side tests

2. **Should AI response tests default to skip if no auth configured?**
   - Current behavior: Pass with "no auth" message
   - Alternative: Skip entirely

3. **Should testing-mode tests (16-18) be in a separate module?**
   - Current: All in Verifications
   - Alternative: SDK.Testing.TestingMode submodule

---

## Next Steps

1. Get user approval on design decisions
2. Create PLAN.md with commit breakdown
3. Implement in complexity order: Simple → Medium → Complex
