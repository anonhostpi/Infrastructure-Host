
### Commit 1: `book-0-builder/host-sdk/modules/Worker.ps1` - Enhance Test to accept scriptblock evaluator [COMPLETE]

### book-0-builder.host-sdk.modules.Worker.enhance-worker-test

> **File**: `book-0-builder/host-sdk/modules/Worker.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Enhance Test to accept scriptblock evaluator

#### Diff

```diff
                 Test = {
-                    param([string]$TestId, [string]$Name, [string]$Command, [string]$ExpectedPattern)
+                    param([string]$TestId, [string]$Name, [string]$Command, $ExpectedPattern)
                     $mod.SDK.Log.Debug("Running test: $Name")
                     try {
                         $result = $this.Exec($Command)
-                        $pass = $result.Success -and ($result.Output -join "`n") -match $ExpectedPattern
+                        $joined = $result.Output -join "`n"
+                        if ($ExpectedPattern -is [scriptblock]) {
+                            $pass = $result.Success -and (& $ExpectedPattern $joined)
+                        } else {
+                            $pass = $result.Success -and $joined -match $ExpectedPattern
+                        }
                         $testResult = @{ Test = $TestId; Name = $Name; Pass = $pass; Output = $result.Output; Error = $result.Error }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 2: `book-0-builder/host-sdk/modules/Verifications.ps1` - Replace with loader shell (module boilerplate + Extend) [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.loader-shell

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace with loader shell (module boilerplate + Extend)

#### Diff

```diff
+param([Parameter(Mandatory = $true)] $SDK)
+
+New-Module -Name SDK.Testing.Verifications -ScriptBlock {
+    param([Parameter(Mandatory = $true)] $SDK)
+    $mod = @{ SDK = $SDK }
+    . "$PSScriptRoot..helpersPowerShell.ps1"
+
+    $Verifications = New-Object PSObject
+
+    $SDK.Extend("Verifications", $Verifications, $SDK.Testing)
+    Export-ModuleMember -Function @()
+} -ArgumentList $SDK | Import-Module -Force
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 12 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 3: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add Fork method to Verifications [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.add-fork

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Fork method to Verifications

#### Diff

```diff
+    Add-ScriptMethods $Verifications @{
+        Fork = {
+            param([string]$Test, [string]$Decision, [string]$Reason = "")
+            $msg = "[FORK] $Test : $Decision"
+            if ($Reason) { $msg += " ($Reason)" }
+            $mod.SDK.Log.Debug($msg)
+        }
+    }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 8 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 4: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add Discover method for filesystem scan [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.add-discover

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Discover method for filesystem scan

#### Diff

```diff
+    Add-ScriptMethods $Verifications @{
+        Discover = {
+            param([int]$Layer)
+            $results = @()
+            foreach ($book in @("book-1-foundation", "book-2-cloud")) {
+                $pattern = Join-Path $book "*/tests/$Layer/verifications.ps1"
+                Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | ForEach-Object {
+                    $fragDir = $_.Directory.Parent.Parent
+                    $results += @{ Fragment = $fragDir.Name; Path = $_.FullName; Layer = $Layer }
+                }
+            }
+            return $results
+        }
+    }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 14 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 5: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add Load method [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.add-load

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Load method

#### Diff

```diff
+    Add-ScriptMethods $Verifications @{
+        Load = {
+            param([string]$Path)
+            return (& $Path -SDK $mod.SDK)
+        }
+    }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 6 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 6: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add Run method to iterate layers and dispatch tests [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.add-run

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Run method to iterate layers and dispatch tests

#### Diff

```diff
+    Add-ScriptMethods $Verifications @{
+        Run = {
+            param($Worker, [int]$Layer)
+            foreach ($l in 1..$Layer) {
+                $layerName = $mod.SDK.Fragments.LayerName($l)
+                $testFiles = $this.Discover($l)
+                foreach ($entry in $testFiles) {
+                    $mod.SDK.Log.Write("`n--- $layerName - $($entry.Fragment) ---", "Cyan")
+                    $tests = $this.Load($entry.Path)
+                    foreach ($id in $tests.Keys | Sort-Object) {
+                        $test = $tests[$id]
+                        $Worker.Test($id, $test.Name, $test.Command, $test.Pattern)
+                    }
+                }
+            }
+        }
+    }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 17 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 7: `book-1-foundation/base/build.yaml` - Add build.yaml for base, network, kernel (3 files) [COMPLETE]

### book-1-foundation.base.build.build-yaml-batch-1

> **File**: `book-1-foundation/base/build.yaml`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Add build.yaml for base, network, kernel (3 files)

#### Diff

```diff
+name: base
+description: Core autoinstall configuration for Ubuntu installation
+iso_required: true
+build_order: 0
+build_layer: 0
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 5 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 8: `book-2-cloud/users/build.yaml` - Add build.yaml for users, ssh, ufw (3 files) [COMPLETE]

### book-2-cloud.users.build.build-yaml-batch-2

> **File**: `book-2-cloud/users/build.yaml`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Add build.yaml for users, ssh, ufw (3 files)

#### Diff

```diff
+name: users
+description: User account creation and sudo configuration
+iso_required: true
+build_order: 20
+build_layer: 3
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 5 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 9: `book-2-cloud/system/build.yaml` - Add build.yaml for system, msmtp, packages (3 files) [COMPLETE]

### book-2-cloud.system.build.build-yaml-batch-3

> **File**: `book-2-cloud/system/build.yaml`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Add build.yaml for system, msmtp, packages (3 files)

#### Diff

```diff
+name: system
+description: System configuration (timezone, locale, hostname)
+iso_required: false
+build_order: 40
+build_layer: 6
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 5 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 10: `book-2-cloud/pkg-security/build.yaml` - Add build.yaml for pkg-security, security-mon, virtualization (3 files) [COMPLETE]

### book-2-cloud.pkg-security.build.build-yaml-batch-4

> **File**: `book-2-cloud/pkg-security/build.yaml`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Add build.yaml for pkg-security, security-mon, virtualization (3 files)

#### Diff

```diff
+name: pkg-security
+description: Security-related package installation (fail2ban, etc.)
+iso_required: false
+build_order: 50
+build_layer: 8
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 5 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 11: `book-2-cloud/cockpit/build.yaml` - Add build.yaml for cockpit, claude-code, copilot-cli (3 files) [COMPLETE]

### book-2-cloud.cockpit.build.build-yaml-batch-5

> **File**: `book-2-cloud/cockpit/build.yaml`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Add build.yaml for cockpit, claude-code, copilot-cli (3 files)

#### Diff

```diff
+name: cockpit
+description: Cockpit web-based server management interface
+iso_required: false
+build_order: 70
+build_layer: 11
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 5 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 12: `book-2-cloud/opencode/build.yaml` - Add build.yaml for opencode, ui, pkg-upgrade (3 files) [COMPLETE]

### book-2-cloud.opencode.build.build-yaml-batch-6

> **File**: `book-2-cloud/opencode/build.yaml`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Add build.yaml for opencode, ui, pkg-upgrade (3 files)

#### Diff

```diff
+name: opencode
+description: OpenCode AI assistant installation
+iso_required: false
+build_order: 77
+build_layer: 14
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 5 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 13: `book-1-foundation/base/tests/0/verifications.ps1` - Add skeleton verifications for base (layer 0) and network (layer 1) [COMPLETE]

### book-1-foundation.base.tests.0.verifications.skeleton-layer-0-1

> **File**: `book-1-foundation/base/tests/0/verifications.ps1`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Add skeleton verifications for base (layer 0) and network (layer 1)

#### Diff

```diff
+param([Parameter(Mandatory = $true)] $SDK)
+
+New-Module -Name "Verify.Base.base" -ScriptBlock {
+    param([Parameter(Mandatory = $true)] $SDK)
+    $mod = @{ SDK = $SDK }
+    . "$PSScriptRoot........ook-0-builderhost-sdkhelpersPowerShell.ps1"
+
+    return @{}
+} -ArgumentList $SDK
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 14: `book-2-cloud/kernel/tests/2/verifications.ps1` - Add skeleton verifications for kernel (layer 2) and users (layer 3) [COMPLETE]

### book-2-cloud.kernel.tests.2.verifications.skeleton-layer-2-3

> **File**: `book-2-cloud/kernel/tests/2/verifications.ps1`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Add skeleton verifications for kernel (layer 2) and users (layer 3)

#### Diff

```diff
+param([Parameter(Mandatory = $true)] $SDK)
+
+New-Module -Name "Verify.KernelHardening.kernel" -ScriptBlock {
+    param([Parameter(Mandatory = $true)] $SDK)
+    $mod = @{ SDK = $SDK }
+    . "$PSScriptRoot........ook-0-builderhost-sdkhelpersPowerShell.ps1"
+
+    return @{}
+} -ArgumentList $SDK
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 15: `book-2-cloud/ssh/tests/4/verifications.ps1` - Add skeleton verifications for ssh (layer 4) and ufw (layer 5) [COMPLETE]

### book-2-cloud.ssh.tests.4.verifications.skeleton-layer-4-5

> **File**: `book-2-cloud/ssh/tests/4/verifications.ps1`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Add skeleton verifications for ssh (layer 4) and ufw (layer 5)

#### Diff

```diff
+param([Parameter(Mandatory = $true)] $SDK)
+
+New-Module -Name "Verify.SSHHardening.ssh" -ScriptBlock {
+    param([Parameter(Mandatory = $true)] $SDK)
+    $mod = @{ SDK = $SDK }
+    . "$PSScriptRoot........ook-0-builderhost-sdkhelpersPowerShell.ps1"
+
+    return @{}
+} -ArgumentList $SDK
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 16: `book-2-cloud/system/tests/6/verifications.ps1` - Add skeleton verifications for system (layer 6) and msmtp (layer 7) [COMPLETE]

### book-2-cloud.system.tests.6.verifications.skeleton-layer-6-7

> **File**: `book-2-cloud/system/tests/6/verifications.ps1`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Add skeleton verifications for system (layer 6) and msmtp (layer 7)

#### Diff

```diff
+param([Parameter(Mandatory = $true)] $SDK)
+
+New-Module -Name "Verify.SystemSettings.system" -ScriptBlock {
+    param([Parameter(Mandatory = $true)] $SDK)
+    $mod = @{ SDK = $SDK }
+    . "$PSScriptRoot........ook-0-builderhost-sdkhelpersPowerShell.ps1"
+
+    return @{}
+} -ArgumentList $SDK
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 17: `book-2-cloud/pkg-security/tests/8/verifications.ps1` - Add skeleton verifications for pkg-security (layer 8) and security-mon (layer 9) [COMPLETE]

### book-2-cloud.pkg-security.tests.8.verifications.skeleton-layer-8-9

> **File**: `book-2-cloud/pkg-security/tests/8/verifications.ps1`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Add skeleton verifications for pkg-security (layer 8) and security-mon (layer 9)

#### Diff

```diff
+param([Parameter(Mandatory = $true)] $SDK)
+
+New-Module -Name "Verify.PackageSecurity.pkg-security" -ScriptBlock {
+    param([Parameter(Mandatory = $true)] $SDK)
+    $mod = @{ SDK = $SDK }
+    . "$PSScriptRoot........ook-0-builderhost-sdkhelpersPowerShell.ps1"
+
+    return @{}
+} -ArgumentList $SDK
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 18: `book-2-cloud/virtualization/tests/10/verifications.ps1` - Add skeleton verifications for virtualization (layer 10) and cockpit (layer 11) [COMPLETE]

### book-2-cloud.virtualization.tests.10.verifications.skeleton-layer-10-11

> **File**: `book-2-cloud/virtualization/tests/10/verifications.ps1`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Add skeleton verifications for virtualization (layer 10) and cockpit (layer 11)

#### Diff

```diff
+param([Parameter(Mandatory = $true)] $SDK)
+
+New-Module -Name "Verify.Virtualization.virtualization" -ScriptBlock {
+    param([Parameter(Mandatory = $true)] $SDK)
+    $mod = @{ SDK = $SDK }
+    . "$PSScriptRoot........ook-0-builderhost-sdkhelpersPowerShell.ps1"
+
+    return @{}
+} -ArgumentList $SDK
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 19: `book-2-cloud/claude-code/tests/12/verifications.ps1` - Add skeleton verifications for claude-code (layer 12) and copilot-cli (layer 13) [COMPLETE]

### book-2-cloud.claude-code.tests.12.verifications.skeleton-layer-12-13

> **File**: `book-2-cloud/claude-code/tests/12/verifications.ps1`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Add skeleton verifications for claude-code (layer 12) and copilot-cli (layer 13)

#### Diff

```diff
+param([Parameter(Mandatory = $true)] $SDK)
+
+New-Module -Name "Verify.ClaudeCode.claude-code" -ScriptBlock {
+    param([Parameter(Mandatory = $true)] $SDK)
+    $mod = @{ SDK = $SDK }
+    . "$PSScriptRoot........ook-0-builderhost-sdkhelpersPowerShell.ps1"
+
+    return @{}
+} -ArgumentList $SDK
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 20: `book-2-cloud/opencode/tests/14/verifications.ps1` - Add skeleton verifications for opencode (layer 14) and ui (layer 15) [COMPLETE]

### book-2-cloud.opencode.tests.14.verifications.skeleton-layer-14-15

> **File**: `book-2-cloud/opencode/tests/14/verifications.ps1`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Add skeleton verifications for opencode (layer 14) and ui (layer 15)

#### Diff

```diff
+param([Parameter(Mandatory = $true)] $SDK)
+
+New-Module -Name "Verify.OpenCode.opencode" -ScriptBlock {
+    param([Parameter(Mandatory = $true)] $SDK)
+    $mod = @{ SDK = $SDK }
+    . "$PSScriptRoot........ook-0-builderhost-sdkhelpersPowerShell.ps1"
+
+    return @{}
+} -ArgumentList $SDK
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 21: `book-2-cloud/pkg-security/tests/16/verifications.ps1` - Add skeleton verifications for pkg-security layers 16 and 17 [COMPLETE]

### book-2-cloud.pkg-security.tests.16.verifications.skeleton-layer-16-17

> **File**: `book-2-cloud/pkg-security/tests/16/verifications.ps1`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Add skeleton verifications for pkg-security layers 16 and 17

#### Diff

```diff
+param([Parameter(Mandatory = $true)] $SDK)
+
+New-Module -Name "Verify.PackageManagerUpdates.pkg-security" -ScriptBlock {
+    param([Parameter(Mandatory = $true)] $SDK)
+    $mod = @{ SDK = $SDK }
+    . "$PSScriptRoot........ook-0-builderhost-sdkhelpersPowerShell.ps1"
+
+    return @{}
+} -ArgumentList $SDK
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 22: `book-2-cloud/pkg-security/tests/18/verifications.ps1` - Add skeleton verifications for pkg-security layer 18 [COMPLETE]

### book-2-cloud.pkg-security.tests.18.verifications.skeleton-layer-18

> **File**: `book-2-cloud/pkg-security/tests/18/verifications.ps1`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Add skeleton verifications for pkg-security layer 18

#### Diff

```diff
+param([Parameter(Mandatory = $true)] $SDK)
+
+New-Module -Name "Verify.NotificationFlush.pkg-security" -ScriptBlock {
+    param([Parameter(Mandatory = $true)] $SDK)
+    $mod = @{ SDK = $SDK }
+    . "$PSScriptRoot........ook-0-builderhost-sdkhelpersPowerShell.ps1"
+
+    return @{}
+} -ArgumentList $SDK
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 23: `book-0-builder/host-sdk/modules/Verifications.ps1` - Thread Worker through Test and Run methods [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.worker-threading

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Thread Worker through Test and Run methods

#### Diff

```diff
         Test = {
-            param([string]$Fragment, [int]$Layer, [string]$Name)
+            param([string]$Fragment, [int]$Layer, [string]$Name, $Worker)
             $test = $mod.Tests[$Fragment][$Layer][$Name]
-            if ($test) { & $test }
+            if ($test) { & $test $Worker }
         }
...
                         foreach ($name in $mod.Tests[$frag][$l].Keys) {
-                            $this.Test($frag, $l, $name)
+                            $this.Test($frag, $l, $name, $Worker)
                         }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 6 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 24: `book-2-cloud/ui/tests/15/verifications.ps1` - Add UI layer tests (MOTD directory and scripts) [COMPLETE]

### book-2-cloud.ui.tests.15.verifications.ui-tests

> **File**: `book-2-cloud/ui/tests/15/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 0 for this file

#### Description

Add UI layer tests (MOTD directory and scripts)

#### Diff

```diff
-    $SDK.Testing.Verifications.Register("ui", 15, [ordered]@{})
+    $SDK.Testing.Verifications.Register("ui", 15, [ordered]@{
+        "MOTD directory exists" = {
+            param($Worker)
+            $result = $Worker.Exec("test -d /etc/update-motd.d")
+            $SDK.Testing.Record(@{
+                Test = "6.15.1"; Name = "MOTD directory exists"
+                Pass = $result.Success; Output = "/etc/update-motd.d"
+            })
+        }
+        "MOTD scripts present" = {
+            param($Worker)
+            $result = $Worker.Exec("ls /etc/update-motd.d/ | wc -l")
+            $SDK.Testing.Record(@{
+                Test = "6.15.2"; Name = "MOTD scripts present"
+                Pass = ([int]$result.Output -gt 0); Output = "$($result.Output) scripts"
+            })
+        }
+    })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 19 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 25: `book-2-cloud/pkg-security/tests/18/verifications.ps1` - Add NotificationFlush test (flush logged) [COMPLETE]

### book-2-cloud.pkg-security.tests.18.verifications.notification-flush-tests

> **File**: `book-2-cloud/pkg-security/tests/18/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add NotificationFlush test (flush logged)

#### Diff

```diff
-    $SDK.Testing.Verifications.Register("pkg-security", 18, [ordered]@{})
+    $SDK.Testing.Verifications.Register("pkg-security", 18, [ordered]@{
+        "apt-notify-flush logged" = {
+            param($Worker)
+            $result = $Worker.Exec("grep 'apt-notify-flush: complete' /var/lib/apt-notify/apt-notify.log")
+            $SDK.Testing.Record(@{
+                Test = "6.8.28"; Name = "apt-notify-flush logged"
+                Pass = ($result.Success -and $result.Output -match "apt-notify-flush")
+                Output = if ($result.Success) { "Flush logged" } else { "No flush log entry" }
+            })
+        }
+    })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 12 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 26a: `book-2-cloud/security-mon/tests/9/verifications.ps1` - Add SecurityMonitoring Register shape with first 2 tests [COMPLETE]

### book-2-cloud.security-mon.tests.9.verifications.secmon-shape

> **File**: `book-2-cloud/security-mon/tests/9/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 0 for this file

#### Description

Add SecurityMonitoring Register shape with first 2 tests

#### Diff

```diff
-    $SDK.Testing.Verifications.Register("security-mon", 9, [ordered]@{})
+    $SDK.Testing.Verifications.Register("security-mon", 9, [ordered]@{
+        "fail2ban installed" = {
+            param($Worker)
+            $result = $Worker.Exec("which fail2ban-client")
+            $SDK.Testing.Record(@{
+                Test = "6.9.1"; Name = "fail2ban installed"
+                Pass = ($result.Success -and $result.Output -match "fail2ban"); Output = $result.Output
+            })
+        }
+        "fail2ban service active" = {
+            param($Worker)
+            $result = $Worker.Exec("sudo systemctl is-active fail2ban")
+            $SDK.Testing.Record(@{
+                Test = "6.9.2"; Name = "fail2ban service active"
+                Pass = ($result.Output -match "^active$"); Output = $result.Output
+            })
+        }
+    })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 19 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 26b: `book-2-cloud/security-mon/tests/9/verifications.ps1` - Add SSH jail test to SecurityMonitoring [COMPLETE]

### book-2-cloud.security-mon.tests.9.verifications.secmon-ssh-jail

> **File**: `book-2-cloud/security-mon/tests/9/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add SSH jail test to SecurityMonitoring

#### Diff

```diff
+        "SSH jail configured" = {
+            param($Worker)
+            $result = $Worker.Exec("sudo fail2ban-client status")
+            $SDK.Testing.Record(@{
+                Test = "6.9.3"; Name = "SSH jail configured"
+                Pass = ($result.Output -match "sshd"); Output = "sshd jail"
+            })
+        }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 8 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 27: `book-2-cloud/system/tests/6/verifications.ps1` - Add System tests: timezone and locale [COMPLETE]

### book-2-cloud.system.tests.6.verifications.system-tests-a

> **File**: `book-2-cloud/system/tests/6/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add System tests: timezone and locale

#### Diff

```diff
-    $SDK.Testing.Verifications.Register("system", 6, [ordered]@{})
+    $SDK.Testing.Verifications.Register("system", 6, [ordered]@{
+        "Timezone configured" = {
+            param($Worker)
+            $result = $Worker.Exec("timedatectl show --property=Timezone --value")
+            $SDK.Testing.Record(@{
+                Test = "6.6.1"; Name = "Timezone configured"
+                Pass = ($result.Success -and $result.Output); Output = $result.Output
+            })
+        }
+        "Locale set" = {
+            param($Worker)
+            $result = $Worker.Exec("locale")
+            $SDK.Testing.Record(@{
+                Test = "6.6.2"; Name = "Locale set"
+                Pass = ($result.Output -match "LANG="); Output = ($result.Output | Select-Object -First 1)
+            })
+        }
+    })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 19 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 28: `book-2-cloud/system/tests/6/verifications.ps1` - Add NTP test to System layer [COMPLETE]

### book-2-cloud.system.tests.6.verifications.system-ntp

> **File**: `book-2-cloud/system/tests/6/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add NTP test to System layer

#### Diff

```diff
+        "NTP enabled" = {
+            param($Worker)
+            $result = $Worker.Exec("timedatectl show --property=NTP --value")
+            $SDK.Testing.Record(@{
+                Test = "6.6.3"; Name = "NTP enabled"
+                Pass = ($result.Output -match "yes"); Output = "NTP=$($result.Output)"
+            })
+        }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 8 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 29: `book-2-cloud/ufw/tests/5/verifications.ps1` - Add UFW tests: active status and SSH allowed [COMPLETE]

### book-2-cloud.ufw.tests.5.verifications.ufw-tests-a

> **File**: `book-2-cloud/ufw/tests/5/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add UFW tests: active status and SSH allowed

#### Diff

```diff
-    $SDK.Testing.Verifications.Register("ufw", 5, [ordered]@{})
+    $SDK.Testing.Verifications.Register("ufw", 5, [ordered]@{
+        "UFW is active" = {
+            param($Worker)
+            $result = $Worker.Exec("sudo ufw status")
+            $SDK.Testing.Record(@{
+                Test = "6.5.1"; Name = "UFW is active"
+                Pass = ($result.Output -match "Status: active"); Output = $result.Output | Select-Object -First 1
+            })
+        }
+        "SSH allowed in UFW" = {
+            param($Worker)
+            $result = $Worker.Exec("sudo ufw status")
+            $SDK.Testing.Record(@{
+                Test = "6.5.2"; Name = "SSH allowed in UFW"
+                Pass = ($result.Output -match "22.*ALLOW"); Output = "Port 22 rule checked"
+            })
+        }
+    })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 19 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 30: `book-2-cloud/ufw/tests/5/verifications.ps1` - Add default deny incoming test to UFW [COMPLETE]

### book-2-cloud.ufw.tests.5.verifications.ufw-deny

> **File**: `book-2-cloud/ufw/tests/5/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add default deny incoming test to UFW

#### Diff

```diff
+        "Default deny incoming" = {
+            param($Worker)
+            $verbose = $Worker.Exec("sudo ufw status verbose")
+            $SDK.Testing.Record(@{
+                Test = "6.5.3"; Name = "Default deny incoming"
+                Pass = ($verbose.Output -match "deny (incoming)"); Output = "Default incoming policy"
+            })
+        }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 8 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 31: `book-2-cloud/kernel/tests/2/verifications.ps1` - Add Kernel tests: sysctl config and reverse path filter [COMPLETE]

### book-2-cloud.kernel.tests.2.verifications.kernel-tests-a

> **File**: `book-2-cloud/kernel/tests/2/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Kernel tests: sysctl config and reverse path filter

#### Diff

```diff
-    $SDK.Testing.Verifications.Register("kernel", 2, [ordered]@{})
+    $SDK.Testing.Verifications.Register("kernel", 2, [ordered]@{
+        "Security sysctl config exists" = {
+            param($Worker)
+            $result = $Worker.Exec("test -f /etc/sysctl.d/99-security.conf")
+            $SDK.Testing.Record(@{
+                Test = "6.2.1"; Name = "Security sysctl config exists"
+                Pass = $result.Success; Output = "/etc/sysctl.d/99-security.conf"
+            })
+        }
+        "Reverse path filtering enabled" = {
+            param($Worker)
+            $result = $Worker.Exec("sysctl net.ipv4.conf.all.rp_filter")
+            $SDK.Testing.Record(@{
+                Test = "6.2.2"; Name = "Reverse path filtering enabled"
+                Pass = ($result.Output -match "= 1"); Output = $result.Output
+            })
+        }
+    })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 19 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 32: `book-2-cloud/kernel/tests/2/verifications.ps1` - Add Kernel tests: SYN cookies and ICMP redirects [COMPLETE]

### book-2-cloud.kernel.tests.2.verifications.kernel-tests-b

> **File**: `book-2-cloud/kernel/tests/2/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Kernel tests: SYN cookies and ICMP redirects

#### Diff

```diff
+        "SYN cookies enabled" = {
+            param($Worker)
+            $result = $Worker.Exec("sysctl net.ipv4.tcp_syncookies")
+            $SDK.Testing.Record(@{
+                Test = "6.2.2"; Name = "SYN cookies enabled"
+                Pass = ($result.Output -match "= 1"); Output = $result.Output
+            })
+        }
+        "ICMP redirects disabled" = {
+            param($Worker)
+            $result = $Worker.Exec("sysctl net.ipv4.conf.all.accept_redirects")
+            $SDK.Testing.Record(@{
+                Test = "6.2.2"; Name = "ICMP redirects disabled"
+                Pass = ($result.Output -match "= 0"); Output = $result.Output
+            })
+        }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 16 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 33: `book-2-cloud/users/tests/3/verifications.ps1` - Add Users Register shape (5 tests: user exists, shell, sudo, sudoers, root locked) [COMPLETE]

### book-2-cloud.users.tests.3.verifications.users-shape

> **File**: `book-2-cloud/users/tests/3/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Users Register shape (5 tests: user exists, shell, sudo, sudoers, root locked)

#### Diff

```diff
-    $SDK.Testing.Verifications.Register("users", 3, [ordered]@{})
+    $SDK.Testing.Verifications.Register("users", 3, [ordered]@{
+        "user exists" = { param($Worker) }
+        "user shell is bash" = { param($Worker) }
+        "user in sudo group" = { param($Worker) }
+        "Sudoers file exists" = { param($Worker) }
+        "Root account locked" = { param($Worker) }
+    })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 8 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 34: `book-2-cloud/ssh/tests/4/verifications.ps1` - Add SSH Register shape (5 tests: hardening config, settings, service, root rejected, key auth) [COMPLETE]

### book-2-cloud.ssh.tests.4.verifications.ssh-shape

> **File**: `book-2-cloud/ssh/tests/4/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add SSH Register shape (5 tests: hardening config, settings, service, root rejected, key auth)

#### Diff

```diff
-    $SDK.Testing.Verifications.Register("ssh", 4, [ordered]@{})
+    $SDK.Testing.Verifications.Register("ssh", 4, [ordered]@{
+        "SSH hardening config exists" = { param($Worker) }
+        "PermitRootLogin no" = { param($Worker) }
+        "MaxAuthTries set" = { param($Worker) }
+        "SSH service active" = { param($Worker) }
+        "Root SSH login rejected" = { param($Worker) }
+        "SSH key auth" = { param($Worker) }
+    })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 35: `book-2-cloud/network/tests/1/verifications.ps1` - Add Network Register shape (9 tests: hostname, hosts, netplan, IP, gateway, DNS, net-setup) [COMPLETE]

### book-2-cloud.network.tests.1.verifications.network-shape

> **File**: `book-2-cloud/network/tests/1/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Network Register shape (9 tests: hostname, hosts, netplan, IP, gateway, DNS, net-setup)

#### Diff

```diff
-    $SDK.Testing.Verifications.Register("network", 1, [ordered]@{})
+    $SDK.Testing.Verifications.Register("network", 1, [ordered]@{
+        "Short hostname set" = { param($Worker) }
+        "FQDN has domain" = { param($Worker) }
+        "Hostname in /etc/hosts" = { param($Worker) }
+        "Netplan config exists" = { param($Worker) }
+        "IP address assigned" = { param($Worker) }
+        "Default gateway configured" = { param($Worker) }
+        "DNS resolution works" = { param($Worker) }
+        "net-setup.log exists" = { param($Worker) }
+        "net-setup.sh executed" = { param($Worker) }
+    })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 12 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 36: `book-2-cloud/msmtp/tests/7/verifications.ps1` - Add MSMTP Register shape (11 tests: install, config, sendmail, SMTP settings, provider, auth, TLS, creds, alias, helper, send) [COMPLETE]

### book-2-cloud.msmtp.tests.7.verifications.msmtp-shape

> **File**: `book-2-cloud/msmtp/tests/7/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add MSMTP Register shape (11 tests: install, config, sendmail, SMTP settings, provider, auth, TLS, creds, alias, helper, send)

#### Diff

```diff
-    $SDK.Testing.Verifications.Register("msmtp", 7, [ordered]@{})
+    $SDK.Testing.Verifications.Register("msmtp", 7, [ordered]@{
+        "msmtp installed" = { param($Worker) }
+        "msmtp config exists" = { param($Worker) }
+        "sendmail alias exists" = { param($Worker) }
+        "SMTP host matches" = { param($Worker) }
+        "SMTP port matches" = { param($Worker) }
+        "SMTP from matches" = { param($Worker) }
+        "SMTP user matches" = { param($Worker) }
+        "Provider config valid" = { param($Worker) }
+        "Auth method valid" = { param($Worker) }
+        "TLS settings valid" = { param($Worker) }
+        "Credential config valid" = { param($Worker) }
+        "Root alias configured" = { param($Worker) }
+        "msmtp-config helper exists" = { param($Worker) }
+        "Test email sent" = { param($Worker) }
+    })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 17 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 37: `book-2-cloud/pkg-security/tests/8/verifications.ps1` - Add PackageSecurity Register shape (18 tests: unattended-upgrades, listchanges, apt-notify, update scripts, timer)

### book-2-cloud.pkg-security.tests.8.verifications.pkgsec-shape

> **File**: `book-2-cloud/pkg-security/tests/8/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add PackageSecurity Register shape (18 tests: unattended-upgrades, listchanges, apt-notify, update scripts, timer)

#### Diff

```diff
-    $SDK.Testing.Verifications.Register("pkg-security", 8, [ordered]@{})
+    $SDK.Testing.Verifications.Register("pkg-security", 8, [ordered]@{
+        "unattended-upgrades installed" = { param($Worker) }
+        "Unattended upgrades config" = { param($Worker) }
+        "Auto-upgrades configured" = { param($Worker) }
+        "Service enabled" = { param($Worker) }
+        "apt-listchanges installed" = { param($Worker) }
+        "apt-listchanges email config" = { param($Worker) }
+        "apt-notify script exists" = { param($Worker) }
+        "dpkg notification hooks" = { param($Worker) }
+        "Verbose upgrade reporting" = { param($Worker) }
+        "snap-update script" = { param($Worker) }
+        "snap refresh.hold configured" = { param($Worker) }
+        "brew-update script" = { param($Worker) }
+        "pip-global-update script" = { param($Worker) }
+        "npm-global-update script" = { param($Worker) }
+        "deno-update script" = { param($Worker) }
+        "pkg-managers-update timer" = { param($Worker) }
+        "apt-notify common library" = { param($Worker) }
+        "apt-notify-flush script" = { param($Worker) }
+    })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 21 lines | FAIL |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 38: `book-2-cloud/virtualization/tests/10/verifications.ps1` - Add Virtualization Register shape (9 tests: libvirt, QEMU, network, multipass, KVM, nested VM)

### book-2-cloud.virtualization.tests.10.verifications.virt-shape

> **File**: `book-2-cloud/virtualization/tests/10/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Virtualization Register shape (9 tests: libvirt, QEMU, network, multipass, KVM, nested VM)

#### Diff

```diff
-    $SDK.Testing.Verifications.Register("virtualization", 10, [ordered]@{})
+    $SDK.Testing.Verifications.Register("virtualization", 10, [ordered]@{
+        "libvirt installed" = { param($Worker) }
+        "libvirtd service active" = { param($Worker) }
+        "QEMU installed" = { param($Worker) }
+        "libvirt default network" = { param($Worker) }
+        "multipass installed" = { param($Worker) }
+        "multipassd service active" = { param($Worker) }
+        "KVM available for nesting" = { param($Worker) }
+        "Launch nested VM" = { param($Worker) }
+        "Exec in nested VM" = { param($Worker) }
+    })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 12 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 39: `book-2-cloud/cockpit/tests/11/verifications.ps1` - Add Cockpit Register shape (7 tests: install, socket, machines, port, web UI, login, localhost)

### book-2-cloud.cockpit.tests.11.verifications.cockpit-shape

> **File**: `book-2-cloud/cockpit/tests/11/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Cockpit Register shape (7 tests: install, socket, machines, port, web UI, login, localhost)

#### Diff

```diff
-    $SDK.Testing.Verifications.Register("cockpit", 11, [ordered]@{})
+    $SDK.Testing.Verifications.Register("cockpit", 11, [ordered]@{
+        "Cockpit installed" = { param($Worker) }
+        "Cockpit socket enabled" = { param($Worker) }
+        "cockpit-machines installed" = { param($Worker) }
+        "Cockpit listening" = { param($Worker) }
+        "Cockpit web UI responds" = { param($Worker) }
+        "Cockpit login page" = { param($Worker) }
+        "Cockpit restricted to localhost" = { param($Worker) }
+    })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 10 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 40: `book-2-cloud/claude-code/tests/12/verifications.ps1` - Add ClaudeCode Register shape (5 tests: install, config dir, settings, auth, AI response)

### book-2-cloud.claude-code.tests.12.verifications.claude-shape

> **File**: `book-2-cloud/claude-code/tests/12/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add ClaudeCode Register shape (5 tests: install, config dir, settings, auth, AI response)

#### Diff

```diff
-    $SDK.Testing.Verifications.Register("claude-code", 12, [ordered]@{})
+    $SDK.Testing.Verifications.Register("claude-code", 12, [ordered]@{
+        "Claude Code installed" = { param($Worker) }
+        "Claude Code config directory" = { param($Worker) }
+        "Claude Code settings file" = { param($Worker) }
+        "Claude Code auth configured" = { param($Worker) }
+        "Claude Code AI response" = { param($Worker) }
+    })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 8 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 41: `book-2-cloud/copilot-cli/tests/13/verifications.ps1` - Add CopilotCLI Register shape (5 tests: install, config dir, config file, auth, AI response)

### book-2-cloud.copilot-cli.tests.13.verifications.copilot-shape

> **File**: `book-2-cloud/copilot-cli/tests/13/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add CopilotCLI Register shape (5 tests: install, config dir, config file, auth, AI response)

#### Diff

```diff
-    $SDK.Testing.Verifications.Register("copilot-cli", 13, [ordered]@{})
+    $SDK.Testing.Verifications.Register("copilot-cli", 13, [ordered]@{
+        "Copilot CLI installed" = { param($Worker) }
+        "Copilot CLI config directory" = { param($Worker) }
+        "Copilot CLI config file" = { param($Worker) }
+        "Copilot CLI auth configured" = { param($Worker) }
+        "Copilot CLI AI response" = { param($Worker) }
+    })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 8 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 42: `book-2-cloud/opencode/tests/14/verifications.ps1` - Add OpenCode Register shape (7 tests: node, npm, install, config, auth, AI response, credential chain)

### book-2-cloud.opencode.tests.14.verifications.opencode-shape

> **File**: `book-2-cloud/opencode/tests/14/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add OpenCode Register shape (7 tests: node, npm, install, config, auth, AI response, credential chain)

#### Diff

```diff
-    $SDK.Testing.Verifications.Register("opencode", 14, [ordered]@{})
+    $SDK.Testing.Verifications.Register("opencode", 14, [ordered]@{
+        "Node.js installed" = { param($Worker) }
+        "npm installed" = { param($Worker) }
+        "OpenCode installed" = { param($Worker) }
+        "OpenCode config directory" = { param($Worker) }
+        "OpenCode auth file" = { param($Worker) }
+        "OpenCode AI response" = { param($Worker) }
+        "OpenCode credential chain" = { param($Worker) }
+    })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 10 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 43: `book-2-cloud/pkg-security/tests/16/verifications.ps1` - Add PackageManagerUpdates Register shape (6 tests: testing mode, snap, npm, pip, brew, deno)

### book-2-cloud.pkg-security.tests.16.verifications.pkgmgr-updates-shape

> **File**: `book-2-cloud/pkg-security/tests/16/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add PackageManagerUpdates Register shape (6 tests: testing mode, snap, npm, pip, brew, deno)

#### Diff

```diff
-    $SDK.Testing.Verifications.Register("pkg-security", 16, [ordered]@{})
+    $SDK.Testing.Verifications.Register("pkg-security", 16, [ordered]@{
+        "Testing mode enabled" = { param($Worker) }
+        "snap-update script" = { param($Worker) }
+        "npm-global-update script" = { param($Worker) }
+        "pip-global-update script" = { param($Worker) }
+        "brew-update script" = { param($Worker) }
+        "deno-update script" = { param($Worker) }
+    })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 44: `book-2-cloud/pkg-security/tests/17/verifications.ps1` - Add UpdateSummary Register shape (3 tests: report, content, AI model)

### book-2-cloud.pkg-security.tests.17.verifications.update-summary-shape

> **File**: `book-2-cloud/pkg-security/tests/17/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add UpdateSummary Register shape (3 tests: report, content, AI model)

#### Diff

```diff
-    $SDK.Testing.Verifications.Register("pkg-security", 17, [ordered]@{})
+    $SDK.Testing.Verifications.Register("pkg-security", 17, [ordered]@{
+        "Report generated" = { param($Worker) }
+        "Report contains npm section" = { param($Worker) }
+        "AI summary reports valid model" = { param($Worker) }
+    })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 6 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 45: `book-0-builder/host-sdk/helpers/Config.ps1` - Fix .Keys pipeline bug in Config.ps1 [COMPLETE]

### book-0-builder.host-sdk.helpers.Config.fix-keys-config

> **File**: `book-0-builder/host-sdk/helpers/Config.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Fix .Keys pipeline bug in Config.ps1

#### Diff

```diff
-foreach ($key in $Override.Keys) {
+foreach ($key in ($Override.Keys | ForEach-Object { $_ })) {

-$onlyKey = @($yaml.Keys)[0]
+$onlyKey = @(($yaml.Keys | ForEach-Object { $_ }))[0]

-foreach ($key in $testingConfig.Keys) {
+foreach ($key in ($testingConfig.Keys | ForEach-Object { $_ })) {
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 6 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 46: `book-0-builder/host-sdk/helpers/PowerShell.ps1` - Fix .Keys pipeline bug in PowerShell.ps1 and SDK.ps1 and Builder.ps1 [COMPLETE]

### book-0-builder.host-sdk.helpers.PowerShell.fix-keys-helpers

> **File**: `book-0-builder/host-sdk/helpers/PowerShell.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Fix .Keys pipeline bug in PowerShell.ps1 and SDK.ps1 and Builder.ps1

#### Diff

```diff
-foreach ($key in $InputObject.Keys) {
+foreach ($key in ($InputObject.Keys | ForEach-Object { $_ })) {

-foreach( $name in $EnvVars.Keys ){
+foreach( $name in ($EnvVars.Keys | ForEach-Object { $_ }) ){

-foreach ($name in $mod.Runners.Keys) {
+foreach ($name in ($mod.Runners.Keys | ForEach-Object { $_ })) {
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 6 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 47: `book-0-builder/host-sdk/modules/Autoinstall.ps1` - Fix .Keys pipeline bug in Autoinstall.ps1 and CloudInit.ps1 [COMPLETE]

### book-0-builder.host-sdk.modules.Autoinstall.fix-keys-cloud-init

> **File**: `book-0-builder/host-sdk/modules/Autoinstall.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Fix .Keys pipeline bug in Autoinstall.ps1 and CloudInit.ps1

#### Diff

```diff
-foreach ($k in $baseConfig.Keys) {
+foreach ($k in ($baseConfig.Keys | ForEach-Object { $_ })) {

-foreach ($k in $Overrides.Keys) {
+foreach ($k in ($Overrides.Keys | ForEach-Object { $_ })) {
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 4 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 48: `book-0-builder/host-sdk/modules/Vbox.ps1` - Fix .Keys pipeline bug in Vbox.ps1 [COMPLETE]

### book-0-builder.host-sdk.modules.Vbox.fix-keys-vbox

> **File**: `book-0-builder/host-sdk/modules/Vbox.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Fix .Keys pipeline bug in Vbox.ps1

#### Diff

```diff
-foreach ($key in $defaults.Keys) {
+foreach ($key in ($defaults.Keys | ForEach-Object { $_ })) {

-foreach ($key in $config.Keys) {
+foreach ($key in ($config.Keys | ForEach-Object { $_ })) {

-foreach( $key in $Settings.Keys ){
+foreach( $key in ($Settings.Keys | ForEach-Object { $_ }) ){
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 6 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 49: `book-0-builder/host-sdk/modules/Verifications.ps1` - Refactor Discover to loop 1..Layer and load files [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.refactor-discover

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Refactor Discover to loop 1..Layer and load files

#### Diff

```diff
         Discover = {
             param([int]$Layer)
-            $results = @()
-            foreach ($book in @("book-1-foundation", "book-2-cloud")) {
-                $pattern = Join-Path $book "*/tests/$Layer/verifications.ps1"
-                Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | ForEach-Object {
-                    $fragDir = $_.Directory.Parent.Parent
-                    $results += @{ Fragment = $fragDir.Name; Path = $_.FullName; Layer = $Layer }
+            foreach ($l in 1..$Layer) {
+                foreach ($book in @("book-1-foundation", "book-2-cloud")) {
+                    $pattern = Join-Path $book "*/tests/$l/verifications.ps1"
+                    Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | ForEach-Object {
+                        $this.Load($_.FullName)
+                    }
                 }
             }
-            return $results
         }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 13 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 50: `book-0-builder/host-sdk/modules/Verifications.ps1` - Simplify Run to iterate registered tests and fix .Keys [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.simplify-run

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Simplify Run to iterate registered tests and fix .Keys

#### Diff

```diff
         Run = {
             param($Worker, [int]$Layer)
             foreach ($l in 1..$Layer) {
                 $layerName = $mod.SDK.Fragments.LayerName($l)
-                $testFiles = $this.Discover($l)
-                foreach ($entry in $testFiles) {
-                    $mod.SDK.Log.Write("`n--- $layerName - $($entry.Fragment) ---", "Cyan")
-                    $this.Load($entry.Path)
-                    $frag = $entry.Fragment
-                    if ($mod.Tests[$frag] -and $mod.Tests[$frag][$l]) {
-                        foreach ($name in $mod.Tests[$frag][$l].Keys) {
-                            $this.Test($frag, $l, $name, $Worker)
-                        }
+                foreach ($frag in ($mod.Tests.Keys | ForEach-Object { $_ })) {
+                    if (-not $mod.Tests[$frag][$l]) { continue }
+                    $mod.SDK.Log.Write("`n--- $layerName - $frag ---", "Cyan")
+                    foreach ($name in ($mod.Tests[$frag][$l].Keys | ForEach-Object { $_ })) {
+                        $this.Test($frag, $l, $name, $Worker)
                     }
                 }
             }
         }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 14 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 51: `book-0-builder/host-sdk/modules/Verifications.ps1` - Fix .Keys pipeline bug in Register method [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.fix-keys-register

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Fix .Keys pipeline bug in Register method

#### Diff

```diff
-            foreach ($key in $Tests.Keys) {
+            foreach ($key in ($Tests.Keys | ForEach-Object { $_ })) {
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 52: `book-0-builder/host-sdk/modules/Logger.ps1` - Add $mod declaration to Logger.ps1 and fix $SDK. to $mod.SDK. in base/0, kernel/2, pkg-sec/18

### book-0-builder.host-sdk.modules.Logger.add-logger-mod

> **File**: `book-0-builder/host-sdk/modules/Logger.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add $mod declaration to Logger.ps1 and fix $SDK. to $mod.SDK. in base/0, kernel/2, pkg-sec/18

#### Diff

```diff
 New-Module -Name SDK.Logger -ScriptBlock {
     param([Parameter(Mandatory = $true)] $SDK)
+    $mod = @{ SDK = $SDK }
     . "$PSScriptRoot..helpersPowerShell.ps1"
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 1 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 53: `book-2-cloud/ufw/tests/5/verifications.ps1` - Replace $SDK. with $mod.SDK. in ufw/5 and system/6 verification files

### book-2-cloud.ufw.tests.5.verifications.fix-sdk-ufw-system

> **File**: `book-2-cloud/ufw/tests/5/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace $SDK. with $mod.SDK. in ufw/5 and system/6 verification files

#### Diff

```diff
-    $SDK.Testing.Verifications.Register("ufw", 5, [ordered]@{
+    $mod.SDK.Testing.Verifications.Register("ufw", 5, [ordered]@{
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 54: `book-2-cloud/security-mon/tests/9/verifications.ps1` - Replace $SDK. with $mod.SDK. in security-mon/9 and ui/15 verification files

### book-2-cloud.security-mon.tests.9.verifications.fix-sdk-secmon-ui

> **File**: `book-2-cloud/security-mon/tests/9/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace $SDK. with $mod.SDK. in security-mon/9 and ui/15 verification files

#### Diff

```diff
-            $SDK.Testing.Record(@{
+            $mod.SDK.Testing.Record(@{
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 55: `book-2-cloud/users/tests/3/verifications.ps1` - Replace $SDK. with $mod.SDK. in users/3 verification file

### book-2-cloud.users.tests.3.verifications.fix-sdk-users

> **File**: `book-2-cloud/users/tests/3/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace $SDK. with $mod.SDK. in users/3 verification file

#### Diff

```diff
-    $username = $SDK.Settings.Identity.username
+    $username = $mod.SDK.Settings.Identity.username
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 56: `book-2-cloud/ssh/tests/4/verifications.ps1` - Replace $SDK. with $mod.SDK. in ssh/4 verification file

### book-2-cloud.ssh.tests.4.verifications.fix-sdk-ssh

> **File**: `book-2-cloud/ssh/tests/4/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace $SDK. with $mod.SDK. in ssh/4 verification file

#### Diff

```diff
-    $username = $SDK.Settings.Identity.username
+    $username = $mod.SDK.Settings.Identity.username
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 57: `book-2-cloud/pkg-security/tests/17/verifications.ps1` - Replace $SDK. with $mod.SDK. in pkg-security/17 verification file

### book-2-cloud.pkg-security.tests.17.verifications.fix-sdk-pkgsec17

> **File**: `book-2-cloud/pkg-security/tests/17/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace $SDK. with $mod.SDK. in pkg-security/17 verification file

#### Diff

```diff
-            $SDK.Testing.Record(@{
+            $mod.SDK.Testing.Record(@{
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 58: `book-2-cloud/network/tests/1/verifications.ps1` - Replace $SDK. with $mod.SDK. in network/1 verification file (10 replacements)

### book-2-cloud.network.tests.1.verifications.fix-sdk-network

> **File**: `book-2-cloud/network/tests/1/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace $SDK. with $mod.SDK. in network/1 verification file (10 replacements)

#### Diff

```diff
-    $SDK.Testing.Verifications.Register("network", 1, [ordered]@{
+    $mod.SDK.Testing.Verifications.Register("network", 1, [ordered]@{
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 59: `book-2-cloud/cockpit/tests/11/verifications.ps1` - Replace \. with \.SDK. in cockpit/11 verification file

### book-2-cloud.cockpit.tests.11.verifications.fix-sdk-cockpit

> **File**: `book-2-cloud/cockpit/tests/11/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace . with .SDK. in cockpit/11 verification file

#### Diff

```diff
-    .Testing.Record(@{
+    .SDK.Testing.Record(@{
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 60: `book-2-cloud/claude-code/tests/12/verifications.ps1` - Replace \. with \.SDK. in claude-code/12 verification file

### book-2-cloud.claude-code.tests.12.verifications.fix-sdk-claude

> **File**: `book-2-cloud/claude-code/tests/12/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace . with .SDK. in claude-code/12 verification file

#### Diff

```diff
-    .Testing.Record(@{
+    .SDK.Testing.Record(@{
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 61: `book-2-cloud/copilot-cli/tests/13/verifications.ps1` - Replace \. with \.SDK. in copilot-cli/13 verification file

### book-2-cloud.copilot-cli.tests.13.verifications.fix-sdk-copilot

> **File**: `book-2-cloud/copilot-cli/tests/13/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace . with .SDK. in copilot-cli/13 verification file

#### Diff

```diff
-    .Testing.Record(@{
+    .SDK.Testing.Record(@{
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 62: `book-2-cloud/virtualization/tests/10/verifications.ps1` - Replace $SDK. with $mod.SDK. in virtualization/10 tests 1-5 (first half)

### book-2-cloud.virtualization.tests.10.verifications.fix-sdk-virt-p1

> **File**: `book-2-cloud/virtualization/tests/10/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace $SDK. with $mod.SDK. in virtualization/10 tests 1-5 (first half)

#### Diff

```diff
-    $SDK.Testing.Verifications.Register("virtualization", 10, [ordered]@{
+    $mod.SDK.Testing.Verifications.Register("virtualization", 10, [ordered]@{
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 63: `book-2-cloud/virtualization/tests/10/verifications.ps1` - Replace $SDK. with $mod.SDK. in virtualization/10 tests 6-9 (second half)

### book-2-cloud.virtualization.tests.10.verifications.fix-sdk-virt-p2

> **File**: `book-2-cloud/virtualization/tests/10/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace $SDK. with $mod.SDK. in virtualization/10 tests 6-9 (second half)

#### Diff

```diff
-            $SDK.Testing.Record(@{
+            $mod.SDK.Testing.Record(@{
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 64: `book-2-cloud/opencode/tests/14/verifications.ps1` - Replace \. with \.SDK. in opencode/14 tests 1-4 (first half)

### book-2-cloud.opencode.tests.14.verifications.fix-sdk-opencode-p1

> **File**: `book-2-cloud/opencode/tests/14/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace . with .SDK. in opencode/14 tests 1-4 (first half)

#### Diff

```diff
-    .Testing.Record(@{
+    .SDK.Testing.Record(@{
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 65: `book-2-cloud/opencode/tests/14/verifications.ps1` - Replace \. with \.SDK. in opencode/14 tests 5-7 (second half)

### book-2-cloud.opencode.tests.14.verifications.fix-sdk-opencode-p2

> **File**: `book-2-cloud/opencode/tests/14/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace . with .SDK. in opencode/14 tests 5-7 (second half)

#### Diff

```diff
-    .Testing.Record(@{
+    .SDK.Testing.Record(@{
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 66: `book-2-cloud/pkg-security/tests/8/verifications.ps1` - Replace \. with \.SDK. in pkg-security/8 tests 1-9 (first half)

### book-2-cloud.pkg-security.tests.8.verifications.fix-sdk-pkgsec8-p1

> **File**: `book-2-cloud/pkg-security/tests/8/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace . with .SDK. in pkg-security/8 tests 1-9 (first half)

#### Diff

```diff
-    .Testing.Record(@{
+    .SDK.Testing.Record(@{
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 67: `book-2-cloud/pkg-security/tests/8/verifications.ps1` - Replace \. with \.SDK. in pkg-security/8 tests 10-18 (second half)

### book-2-cloud.pkg-security.tests.8.verifications.fix-sdk-pkgsec8-p2

> **File**: `book-2-cloud/pkg-security/tests/8/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace . with .SDK. in pkg-security/8 tests 10-18 (second half)

#### Diff

```diff
-    .Testing.Record(@{
+    .SDK.Testing.Record(@{
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 68: `book-2-cloud/pkg-security/tests/16/verifications.ps1` - Replace \. with \.SDK. in pkg-security/16 tests 1-3 (first half)

### book-2-cloud.pkg-security.tests.16.verifications.fix-sdk-pkgsec16-p1

> **File**: `book-2-cloud/pkg-security/tests/16/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace . with .SDK. in pkg-security/16 tests 1-3 (first half)

#### Diff

```diff
-    .Testing.Record(@{
+    .SDK.Testing.Record(@{
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 69: `book-2-cloud/pkg-security/tests/16/verifications.ps1` - Replace \. with \.SDK. in pkg-security/16 tests 4-6 (second half)

### book-2-cloud.pkg-security.tests.16.verifications.fix-sdk-pkgsec16-p2

> **File**: `book-2-cloud/pkg-security/tests/16/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace . with .SDK. in pkg-security/16 tests 4-6 (second half)

#### Diff

```diff
-    .Testing.Record(@{
+    .SDK.Testing.Record(@{
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 70: `book-2-cloud/msmtp/tests/7/verifications.ps1` - Replace \. with \.SDK. in msmtp/7 tests 1-5 (first third)

### book-2-cloud.msmtp.tests.7.verifications.fix-sdk-msmtp-p1

> **File**: `book-2-cloud/msmtp/tests/7/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace . with .SDK. in msmtp/7 tests 1-5 (first third)

#### Diff

```diff
-    .Testing.Record(@{
+    .SDK.Testing.Record(@{
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 71: `book-2-cloud/msmtp/tests/7/verifications.ps1` - Replace \. with \.SDK. in msmtp/7 tests 6-10 (second third)

### book-2-cloud.msmtp.tests.7.verifications.fix-sdk-msmtp-p2

> **File**: `book-2-cloud/msmtp/tests/7/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace . with .SDK. in msmtp/7 tests 6-10 (second third)

#### Diff

```diff
-    .Testing.Record(@{
+    .SDK.Testing.Record(@{
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 72: `book-2-cloud/msmtp/tests/7/verifications.ps1` - Replace \. with \.SDK. in msmtp/7 tests 11-14 (final third)

### book-2-cloud.msmtp.tests.7.verifications.fix-sdk-msmtp-p3

> **File**: `book-2-cloud/msmtp/tests/7/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace . with .SDK. in msmtp/7 tests 11-14 (final third)

#### Diff

```diff
-    .Testing.Record(@{
+    .SDK.Testing.Record(@{
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |
