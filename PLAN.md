
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

### Commit 52: `book-0-builder/host-sdk/modules/Logger.ps1` - Add $mod declaration to Logger.ps1 and fix $SDK. to $mod.SDK. in base/0, kernel/2, pkg-sec/18 [COMPLETE]

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

### Commit 53: `book-2-cloud/ufw/tests/5/verifications.ps1` - Replace $SDK. with $mod.SDK. in ufw/5 and system/6 verification files [COMPLETE]

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

### Commit 54: `book-2-cloud/security-mon/tests/9/verifications.ps1` - Replace $SDK. with $mod.SDK. in security-mon/9 and ui/15 verification files [COMPLETE]

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

### Commit 55: `book-2-cloud/users/tests/3/verifications.ps1` - Replace $SDK. with $mod.SDK. in users/3 verification file [COMPLETE]

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

### Commit 56: `book-2-cloud/ssh/tests/4/verifications.ps1` - Replace $SDK. with $mod.SDK. in ssh/4 verification file [COMPLETE]

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

### Commit 57: `book-2-cloud/pkg-security/tests/17/verifications.ps1` - Replace $SDK. with $mod.SDK. in pkg-security/17 verification file [COMPLETE]

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

### Commit 58: `book-2-cloud/network/tests/1/verifications.ps1` - Replace $SDK. with $mod.SDK. in network/1 verification file (10 replacements) [COMPLETE]

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

### Commit 59: `book-2-cloud/cockpit/tests/11/verifications.ps1` - Replace \. with \.SDK. in cockpit/11 verification file [COMPLETE]

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

### Commit 60: `book-2-cloud/claude-code/tests/12/verifications.ps1` - Replace \. with \.SDK. in claude-code/12 verification file [COMPLETE]

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

### Commit 61: `book-2-cloud/copilot-cli/tests/13/verifications.ps1` - Replace \. with \.SDK. in copilot-cli/13 verification file [COMPLETE]

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

### Commit 62: `book-2-cloud/virtualization/tests/10/verifications.ps1` - Replace $SDK. with $mod.SDK. in virtualization/10 tests 1-5 (first half) [COMPLETE]

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

### Commit 63: `book-2-cloud/virtualization/tests/10/verifications.ps1` - Replace $SDK. with $mod.SDK. in virtualization/10 tests 6-9 (second half) [COMPLETE]

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

### Commit 64: `book-2-cloud/opencode/tests/14/verifications.ps1` - Replace \. with \.SDK. in opencode/14 tests 1-4 (first half) [COMPLETE]

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

### Commit 65: `book-2-cloud/opencode/tests/14/verifications.ps1` - Replace \. with \.SDK. in opencode/14 tests 5-7 (second half) [COMPLETE]

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

### Commit 66: `book-2-cloud/pkg-security/tests/8/verifications.ps1` - Replace \. with \.SDK. in pkg-security/8 tests 1-9 (first half) [COMPLETE]

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

### Commit 67: `book-2-cloud/pkg-security/tests/8/verifications.ps1` - Replace \. with \.SDK. in pkg-security/8 tests 10-18 (second half) [COMPLETE]

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

### Commit 68: `book-2-cloud/pkg-security/tests/16/verifications.ps1` - Replace \. with \.SDK. in pkg-security/16 tests 1-3 (first half) [COMPLETE]

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

### Commit 69: `book-2-cloud/pkg-security/tests/16/verifications.ps1` - Replace \. with \.SDK. in pkg-security/16 tests 4-6 (second half) [COMPLETE]

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

### Commit 70: `book-2-cloud/msmtp/tests/7/verifications.ps1` - Replace \. with \.SDK. in msmtp/7 tests 1-5 (first third) [COMPLETE]

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

### Commit 71: `book-2-cloud/msmtp/tests/7/verifications.ps1` - Replace \. with \.SDK. in msmtp/7 tests 6-10 (second third) [COMPLETE]

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

### Commit 72: `book-2-cloud/msmtp/tests/7/verifications.ps1` - Replace \. with \.SDK. in msmtp/7 tests 11-14 (final third) [COMPLETE]

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

### Commit 73: `book-0-builder/host-sdk/modules/Logger.ps1` - Consolidate 2 Add-ScriptMethods calls into 1 [COMPLETE]

### book-0-builder.host-sdk.modules.Logger.consolidate-logger

> **File**: `book-0-builder/host-sdk/modules/Logger.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Consolidate 2 Add-ScriptMethods calls into 1

#### Diff

```diff
         Step  = { param([string]$Message, [int]$Current, [int]$Total) $this.Write("[$Current/$Total] $Message", "Cyan") }
-    }
-
-    Add-ScriptMethods $Logger @{
         Start = {
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 3 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 74: `book-0-builder/host-sdk/modules/Fragments.ps1` - Consolidate 2 Add-ScriptMethods calls into 1 [COMPLETE]

### book-0-builder.host-sdk.modules.Fragments.consolidate-fragments

> **File**: `book-0-builder/host-sdk/modules/Fragments.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Consolidate 2 Add-ScriptMethods calls into 1

#### Diff

```diff
         }
-    }
-
-    Add-ScriptMethods $Fragments @{
         LayerName = {
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 3 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 75: `book-0-builder/host-sdk/modules/Builder.ps1` - Consolidate 2 Add-ScriptMethods calls into 1, rename RegisterRunner to Register [COMPLETE]

### book-0-builder.host-sdk.modules.Builder.consolidate-builder

> **File**: `book-0-builder/host-sdk/modules/Builder.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Consolidate 2 Add-ScriptMethods calls into 1, rename RegisterRunner to Register

#### Diff

```diff
         }
-    }
-
-    Add-ScriptMethods $Builder @{
-        RegisterRunner = {
+        Register = {
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 5 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 76: `book-0-builder/host-sdk/modules/CloudInit.ps1` - Consolidate 3 Add-ScriptMethods calls into 1 [COMPLETE]

### book-0-builder.host-sdk.modules.CloudInit.consolidate-cloudinit

> **File**: `book-0-builder/host-sdk/modules/CloudInit.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Consolidate 3 Add-ScriptMethods calls into 1

#### Diff

```diff
         }
-    }
-
-    Add-ScriptMethods $CloudInit @{
         Cleanup = {
             ...
         }
-    }
-
-    Add-ScriptMethods $CloudInit @{
         Clean = {
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 6 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 77: `book-0-builder/host-sdk/modules/Autoinstall.ps1` - Consolidate 4 Add-ScriptMethods calls into 1 [COMPLETE]

### book-0-builder.host-sdk.modules.Autoinstall.consolidate-autoinstall

> **File**: `book-0-builder/host-sdk/modules/Autoinstall.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Consolidate 4 Add-ScriptMethods calls into 1

#### Diff

```diff
         }
-    }
-
-    Add-ScriptMethods $Autoinstall @{
         Build = {
             ...
         }
-    }
-
-    Add-ScriptMethods $Autoinstall @{
         Cleanup = {
             ...
         }
-    }
-
-    Add-ScriptMethods $Autoinstall @{
         Clean = {
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 78: `book-0-builder/host-sdk/modules/Testing.ps1` - Consolidate 5 Add-ScriptMethods calls into 1 [COMPLETE]

### book-0-builder.host-sdk.modules.Testing.consolidate-testing

> **File**: `book-0-builder/host-sdk/modules/Testing.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Consolidate 5 Add-ScriptMethods calls into 1

#### Diff

```diff
         }
-    }
-
-    Add-ScriptMethods $Testing @{
         Summary = {
             ...
         }
-    }
-
-    Add-ScriptMethods $Testing @{
         Fragments = {
             ...
         }
-    }
-
-    Add-ScriptMethods $Testing @{
         LevelName = {
             ...
         }
-    }
-
-    Add-ScriptMethods $Testing @{
         LevelFragments = {
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 12 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 79: `book-0-builder/host-sdk/modules/Vbox.ps1` - Add SetProcessor and SetMemory methods [COMPLETE]

### book-0-builder.host-sdk.modules.Vbox.vbox-set-processor-memory

> **File**: `book-0-builder/host-sdk/modules/Vbox.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add SetProcessor and SetMemory methods

#### Diff

```diff
         })
+        SetProcessor = {
+            param([string]$VMName, [hashtable]$Settings)
+            return $this.Configure($VMName, $Settings)
+        }
+        SetMemory = {
+            param([string]$VMName, [hashtable]$Settings)
+            return $this.Configure($VMName, $Settings)
+        }
     }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 8 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 80: `book-0-builder/host-sdk/modules/Vbox.ps1` - Add SetNetworkAdapter and SetFirmware methods [COMPLETE]

### book-0-builder.host-sdk.modules.Vbox.vbox-set-network-firmware

> **File**: `book-0-builder/host-sdk/modules/Vbox.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add SetNetworkAdapter and SetFirmware methods

#### Diff

```diff
         }
+        SetNetworkAdapter = {
+            param([string]$VMName, [hashtable]$Settings)
+            return $this.Configure($VMName, $Settings)
+        }
+        SetFirmware = {
+            param([string]$VMName, [hashtable]$Settings)
+            return $this.Configure($VMName, $Settings)
+        }
     }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 8 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 81: `book-0-builder/host-sdk/modules/Vbox.ps1` - Refactor Optimize and Hypervisor to use Set* methods [COMPLETE]

### book-0-builder.host-sdk.modules.Vbox.vbox-refactor-optimize-hypervisor

> **File**: `book-0-builder/host-sdk/modules/Vbox.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Refactor Optimize and Hypervisor to use Set* methods

#### Diff

```diff
-            return $this.Configure($VMName, @{
+            return $this.SetProcessor($VMName, @{
                 "pae" = "on"
-            }) -and $this.Configure($VMName, @{
+            }) -and $this.SetProcessor($VMName, @{
-            return $this.Configure($VMName, @{
+            return $this.SetProcessor($VMName, @{
                 "nested-hw-virt" = "on"
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 6 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 82: `book-0-builder/host-sdk/modules/HyperV.ps1` - Module shell with param, New-Module, Import-Module Hyper-V, empty object, Extend [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-module-shell

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Module shell with param, New-Module, Import-Module Hyper-V, empty object, Extend

#### Diff

```diff
+param([Parameter(Mandatory = $true)] $SDK)
+
+New-Module -Name SDK.HyperV -ScriptBlock {
+    param([Parameter(Mandatory = $true)] $SDK)
+    $mod = @{ SDK = $SDK }
+    . "$PSScriptRoot..helpersPowerShell.ps1"
+    Import-Module Hyper-V
+
+    $HyperV = New-Object PSObject
+
+    $SDK.Extend("HyperV", $HyperV)
+    Export-ModuleMember -Function @()
+} -ArgumentList $SDK | Import-Module -Force
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 13 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 83: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add Configurator defaults [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-configurator

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Configurator defaults

#### Diff

```diff
     Import-Module Hyper-V
+
+    $mod.Configurator = @{
+        Defaults = @{
+            CPUs = 2
+            MemoryMB = 4096
+            DiskGB = 40
+            SSHUser = $null
+            SSHHost = $null
+            SSHPort = 22
+            Generation = 2
+        }
+    }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 12 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 84a: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add Worker Properties shell with Rendered config merge [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-worker-props-shell

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 0 for this file

#### Description

Add Worker Properties shell with Rendered config merge

#### Diff

```diff
+    $mod.Worker = @{
+        Properties = @{
+            Rendered = {
+                $config = $this.Config
+                $defaults = if ($this.Defaults) { $this.Defaults } else { $mod.Configurator.Defaults }
+                $rendered = @{}
+                foreach ($key in ($defaults.Keys | ForEach-Object { $_ })) { $rendered[$key] = $defaults[$key] }
+                foreach ($key in ($config.Keys | ForEach-Object { $_ })) { $rendered[$key] = $config[$key] }
+                # WIP: SSH derivation, MediumPath, caching
+                return $rendered
+            }
+        }
+    }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 13 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 84b: `book-0-builder/host-sdk/modules/HyperV.ps1` - Fill Rendered SSH derivation, MediumPath, and caching [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-worker-rendered-ssh

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Fill Rendered SSH derivation, MediumPath, and caching

#### Diff

```diff
-                # WIP: SSH derivation, MediumPath, caching
-                return $rendered
+                if (-not $rendered.SSHUser -or -not $rendered.SSHHost) {
+                    $identity = $mod.SDK.Settings.Load("book-2-cloud/users/config/identity.config.yaml")
+                    $network = $mod.SDK.Settings.Load("book-2-cloud/network/config/network.config.yaml")
+                    if (-not $rendered.SSHUser) { $rendered.SSHUser = $identity.identity.username }
+                    if (-not $rendered.SSHHost) {
+                        $ip = $network.network.ip_address -replace '/d+$', ''
+                        $rendered.SSHHost = $ip
+                    }
+                }
+                if (-not $rendered.MediumPath) {
+                    $rendered.MediumPath = "$env:TEMP$($rendered.Name).vhdx"
+                }
+                $this | Add-Member -MemberType NoteProperty -Name Rendered -Value $rendered -Force
+                return $rendered
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 16 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 85: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add Worker Property accessors (Name, CPUs, MemoryMB, DiskGB, etc.) [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-worker-accessors

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Worker Property accessors (Name, CPUs, MemoryMB, DiskGB, etc.)

#### Diff

```diff
+            Name = { return $this.Rendered.Name }
+            CPUs = { return $this.Rendered.CPUs }
+            MemoryMB = { return $this.Rendered.MemoryMB }
+            DiskGB = { return $this.Rendered.DiskGB }
+            Network = { return $this.Rendered.Network }
+            MediumPath = { return $this.Rendered.MediumPath }
+            SSHUser = { return $this.Rendered.SSHUser }
+            SSHHost = { return $this.Rendered.SSHHost }
+            SSHPort = { return $this.Rendered.SSHPort }
+            Generation = { return $this.Rendered.Generation }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 10 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 86: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add Worker Methods (lifecycle: Exists through Destroy) [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-worker-methods

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Worker Methods (lifecycle: Exists through Destroy)

#### Diff

```diff
+        Methods = @{
+            Exists = { return $mod.SDK.HyperV.Exists($this.Name) }
+            Running = { return $mod.SDK.HyperV.Running($this.Name) }
+            Start = { return $mod.SDK.HyperV.Start($this.Name) }
+            Shutdown = {
+                param([bool]$Force)
+                return $mod.SDK.HyperV.Shutdown($this.Name, $Force)
+            }
+            UntilShutdown = {
+                param([int]$TimeoutSeconds)
+                return $mod.SDK.HyperV.UntilShutdown($this.Name, $TimeoutSeconds)
+            }
+            Destroy = { return $mod.SDK.HyperV.Destroy($this.Name) }
+        }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 14 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 87: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add Worker Methods — Create delegation [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-worker-create

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Worker Methods — Create delegation

#### Diff

```diff
+            Create = {
+                return $mod.SDK.HyperV.Create(
+                    $this.Name,
+                    $this.MediumPath,
+                    $null,
+                    $this.Network,
+                    $this.Generation,
+                    $this.DiskGB,
+                    $this.MemoryMB,
+                    $this.CPUs
+                )
+            }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 12 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 88: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add Worker factory method [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-worker-factory

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Worker factory method

#### Diff

```diff
+    Add-ScriptMethods $HyperV @{
+        Worker = {
+            param(
+                [Parameter(Mandatory = $true)]
+                [ValidateScript({ $null -ne $_.Config })]
+                $Base
+            )
+            $worker = If ($Base -is [System.Collections.IDictionary]) {
+                New-Object PSObject -Property $Base
+            } Else { $Base }
+            Add-ScriptProperties $worker $mod.Worker.Properties
+            Add-ScriptMethods $worker $mod.Worker.Methods
+            $mod.SDK.Worker.Methods($worker)
+            return $worker
+        }
+    }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 16 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 89: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add GetSwitch method [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-getswitch

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add GetSwitch method

#### Diff

```diff
+    Add-ScriptMethods $HyperV @{
+        GetSwitch = {
+            param([string]$SwitchName)
+            if ($SwitchName) {
+                $sw = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
+                if ($sw) { return $sw.Name }
+            }
+            $ext = Get-VMSwitch -SwitchType External -ErrorAction SilentlyContinue | Select-Object -First 1
+            if ($ext) { return $ext.Name }
+            return $null
+        }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 11 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 90: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add Drives method (Get-VMHardDiskDrive + Get-VMDvdDrive) [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-drives

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Drives method (Get-VMHardDiskDrive + Get-VMDvdDrive)

#### Diff

```diff
+        Drives = {
+            param([string]$VMName)
+            $hdds = Get-VMHardDiskDrive -VMName $VMName
+            $dvds = Get-VMDvdDrive -VMName $VMName
+            $all = @()
+            foreach ($d in $hdds) {
+                $all += @{ Controller = $d.ControllerType; Port = $d.ControllerNumber; Path = $d.Path; IsDVD = $false }
+            }
+            foreach ($d in $dvds) {
+                $all += @{ Controller = $d.ControllerType; Port = $d.ControllerNumber; Path = $d.Path; IsDVD = $true }
+            }
+            return $all
+        }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 13 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 91: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add Attach and Delete methods [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-attach-delete

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Attach and Delete methods

#### Diff

```diff
+        Attach = {
+            param([string]$VMName, [string]$Path, [string]$ControllerType = "SCSI")
+            try {
+                Add-VMHardDiskDrive -VMName $VMName -Path $Path -ControllerType $ControllerType -ErrorAction Stop
+                return $true
+            } catch { return $false }
+        }
+        Delete = {
+            param([string]$VMName, [string]$Path)
+            $drive = Get-VMHardDiskDrive -VMName $VMName | Where-Object { $_.Path -eq $Path }
+            if ($drive) { Remove-VMHardDiskDrive -VMHardDiskDrive $drive }
+            if (Test-Path $Path) { Remove-Item $Path -Force }
+        }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 13 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 92: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add Give method (New-VHD + Attach) [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-give

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Give method (New-VHD + Attach)

#### Diff

```diff
+        Give = {
+            param([string]$VMName, [string]$Path, [int]$SizeGB, [string]$ControllerType = "SCSI")
+            try {
+                New-VHD -Path $Path -SizeBytes ($SizeGB * 1GB) -Dynamic -ErrorAction Stop | Out-Null
+            } catch {
+                throw "Failed to create VHD at '$Path': $_"
+            }
+            $attached = $this.Attach($VMName, $Path, $ControllerType)
+            if (-not $attached) {
+                throw "Failed to attach VHD '$Path' to VM: $VMName"
+            }
+        }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 12 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 93: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add Eject and Insert methods [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-eject-insert

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Eject and Insert methods

#### Diff

```diff
+        Eject = {
+            param([string]$VMName)
+            $dvds = Get-VMDvdDrive -VMName $VMName
+            foreach ($dvd in $dvds) {
+                Set-VMDvdDrive -VMDvdDrive $dvd -Path $null
+            }
+        }
+        Insert = {
+            param([string]$VMName, [string]$ISOPath)
+            $dvds = Get-VMDvdDrive -VMName $VMName
+            if ($dvds.Count -eq 0) {
+                Add-VMDvdDrive -VMName $VMName -Path $ISOPath
+            } else {
+                Set-VMDvdDrive -VMDvdDrive ($dvds | Select-Object -First 1) -Path $ISOPath
+            }
+        }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 16 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 94: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add Exists and Running methods [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-exists-running

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Exists and Running methods

#### Diff

```diff
+        Exists = {
+            param([string]$VMName)
+            return $null -ne (Get-VM -Name $VMName -ErrorAction SilentlyContinue)
+        }
+        Running = {
+            param([string]$VMName)
+            if (-not $this.Exists($VMName)) { return $false }
+            return (Get-VM -Name $VMName).State -eq 'Running'
+        }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 95: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add Pause, Resume, and Bump methods [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-pause-resume-bump

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Pause, Resume, and Bump methods

#### Diff

```diff
+        Pause = {
+            param([string]$VMName)
+            try { Suspend-VM -Name $VMName -ErrorAction Stop; return $true } catch { return $false }
+        }
+        Resume = {
+            param([string]$VMName)
+            try { Resume-VM -Name $VMName -ErrorAction Stop; return $true } catch { return $false }
+        }
+        Bump = {
+            param([string]$VMName)
+            $paused = $this.Pause($VMName)
+            if (-not $paused) { throw "Failed to pause VM '$VMName' for bump." }
+            Start-Sleep -Seconds 5
+            $resumed = $this.Resume($VMName)
+            if (-not $resumed) { throw "Failed to resume VM '$VMName' after bump." }
+            return $true
+        }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 17 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 96: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add Start and Shutdown methods [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-start-shutdown

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Start and Shutdown methods

#### Diff

```diff
+        Start = {
+            param([string]$VMName)
+            try { Start-VM -Name $VMName -ErrorAction Stop; return $true } catch { return $false }
+        }
+        Shutdown = {
+            param([string]$VMName, [bool]$Force)
+            if (-not $this.Running($VMName)) { return $true }
+            try {
+                if ($Force) { Stop-VM -Name $VMName -TurnOff -Force -ErrorAction Stop }
+                else { Stop-VM -Name $VMName -Force -ErrorAction Stop }
+                return $true
+            } catch { return $false }
+        }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 13 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 97: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add UntilShutdown method with Job timeout [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-untilshutdown

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add UntilShutdown method with Job timeout

#### Diff

```diff
+        UntilShutdown = {
+            param([string]$VMName, [int]$TimeoutSeconds)
+            if (-not $this.Running($VMName)) { return $false }
+            return $mod.SDK.Job({
+                while ($SDK.HyperV.Running($VMName)) {
+                    Start-Sleep -Seconds 1
+                }
+            }, $TimeoutSeconds, @{
+                VMName = $VMName
+            })
+        }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 11 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 98: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add SetProcessor and SetMemory methods [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-set-processor-memory

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add SetProcessor and SetMemory methods

#### Diff

```diff
+        SetProcessor = {
+            param([string]$VMName, [hashtable]$Settings)
+            $Settings.VMName = $VMName
+            try { Set-VMProcessor @Settings -ErrorAction Stop; return $true } catch { return $false }
+        }
+        SetMemory = {
+            param([string]$VMName, [hashtable]$Settings)
+            $Settings.VMName = $VMName
+            try { Set-VMMemory @Settings -ErrorAction Stop; return $true } catch { return $false }
+        }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 10 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 99: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add SetNetworkAdapter and SetFirmware methods [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-set-network-firmware

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add SetNetworkAdapter and SetFirmware methods

#### Diff

```diff
+        SetNetworkAdapter = {
+            param([string]$VMName, [hashtable]$Settings)
+            $Settings.VMName = $VMName
+            try { Set-VMNetworkAdapter @Settings -ErrorAction Stop; return $true } catch { return $false }
+        }
+        SetFirmware = {
+            param([string]$VMName, [hashtable]$Settings)
+            $Settings.VMName = $VMName
+            try { Set-VMFirmware @Settings -ErrorAction Stop; return $true } catch { return $false }
+        }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 10 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 100: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add Optimize and Hypervisor methods composing Set* methods [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-optimize-hypervisor

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Optimize and Hypervisor methods composing Set* methods

#### Diff

```diff
+        Optimize = {
+            param([string]$VMName)
+            return $this.SetProcessor($VMName, @{
+                ExposeVirtualizationExtensions = $false
+            })
+        }
+        Hypervisor = {
+            param([string]$VMName)
+            return $this.SetProcessor($VMName, @{
+                ExposeVirtualizationExtensions = $true
+            }) -and $this.SetMemory($VMName, @{
+                DynamicMemoryEnabled = $false
+            }) -and $this.SetNetworkAdapter($VMName, @{
+                MacAddressSpoofing = "On"
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

### Commit 101: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add Destroy method [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-destroy

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Destroy method

#### Diff

```diff
+        Destroy = {
+            param([string]$VMName)
+            if ($this.Running($VMName)) {
+                $this.Shutdown($VMName, $true) | Out-Null
+                $this.UntilShutdown($VMName, 60) | Out-Null
+            }
+            if ($this.Exists($VMName)) {
+                $drives = $this.Drives($VMName)
+                Remove-VM -Name $VMName -Force
+                foreach ($d in $drives) {
+                    if ($d.Path -and (Test-Path $d.Path)) { Remove-Item $d.Path -Force }
+                }
+            }
+        }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 14 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 102: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add Create method — outer shape with WIP body [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-create-shape

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Create method — outer shape with WIP body

#### Diff

```diff
+        Create = {
+            param(
+                [string]$VMName, [string]$MediumPath, [string]$DVDPath,
+                [string]$SwitchName, [int]$Generation = 2,
+                [int]$DiskGB = 40, [int]$MemoryMB = 4096, [int]$CPUs = 2,
+                [bool]$Optimize = $true, [bool]$Hypervisor = $true
+            )
+            try {
+                # WIP: VM creation, storage, network, optimization
+                pass
+            } catch {
+                Write-Error "Error creating VM '$VMName': $_"
+                return $false
+            }
+        }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 15 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 103: `book-0-builder/host-sdk/modules/HyperV.ps1` - Fill Create — New-VM + processor + switch [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-create-impl-1

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Fill Create — New-VM + processor + switch

#### Diff

```diff
-                # WIP: VM creation, storage, network, optimization
-                pass
+                $memBytes = $MemoryMB * 1MB
+                $diskBytes = $DiskGB * 1GB
+                New-VM -Name $VMName -MemoryStartupBytes $memBytes -Generation $Generation -NewVHDPath $MediumPath -NewVHDSizeBytes $diskBytes -ErrorAction Stop | Out-Null
+                $this.SetProcessor($VMName, @{ Count = $CPUs })
+                $switch = $this.GetSwitch($SwitchName)
+                if ($switch) {
+                    Connect-VMNetworkAdapter -VMName $VMName -SwitchName $switch
+                }
+                # WIP: optimize, hypervisor, DVD
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 11 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 104: `book-0-builder/host-sdk/modules/HyperV.ps1` - Fill Create — optimize, hypervisor, DVD insertion [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-create-impl-2

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Fill Create — optimize, hypervisor, DVD insertion

#### Diff

```diff
-                # WIP: optimize, hypervisor, DVD
+                if ($Optimize) { $this.Optimize($VMName) }
+                if ($Hypervisor) { $this.Hypervisor($VMName) }
+                if ($DVDPath -and (Test-Path $DVDPath)) {
+                    Add-VMDvdDrive -VMName $VMName -Path $DVDPath
+                }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 6 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 105: `book-0-builder/host-sdk/SDK.ps1` - Load HyperV.ps1 in SDK module loading sequence [COMPLETE]

### book-0-builder.host-sdk.SDK.sdk-load-hyperv

> **File**: `book-0-builder/host-sdk/SDK.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Load HyperV.ps1 in SDK module loading sequence

#### Diff

```diff
     & "$PSScriptRoot/modules/Vbox.ps1" -SDK $SDK
+    & "$PSScriptRoot/modules/HyperV.ps1" -SDK $SDK
     & "$PSScriptRoot/modules/Multipass.ps1" -SDK $SDK
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 1 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 106: `book-0-builder/host-sdk/modules/Vbox.ps1` - Fix Out-Null blocking throws in Create [COMPLETE]

### book-0-builder.host-sdk.modules.Vbox.vbox-fix-out-null-create

> **File**: `book-0-builder/host-sdk/modules/Vbox.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Fix Out-Null blocking throws in Create

#### Diff

```diff

```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 0 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |


### Commit 107: `book-0-builder/host-sdk/modules/Vbox.ps1` - Rewrite SetProcessor with key translation [COMPLETE]

### book-0-builder.host-sdk.modules.Vbox.vbox-set-processor

> **File**: `book-0-builder/host-sdk/modules/Vbox.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Rewrite SetProcessor with key translation

#### Diff

```diff
 SetProcessor = {
-    param([string]$VMName, [hashtable]$Settings)
-    return $this.Configure($VMName, $Settings)
+    param([string]$VMName, [hashtable]$Settings)
+    $s = @{}
+    foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) {
+        switch ($key) {
+            "Count" { $s["cpus"] = $Settings[$key] }
+            default { $s[$key] = $Settings[$key] }
+        }
+    }
+    return $this.Configure($VMName, $s)
 }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 11 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 108: `book-0-builder/host-sdk/modules/Vbox.ps1` - Rewrite SetMemory, SetNetworkAdapter, SetFirmware [COMPLETE]

### book-0-builder.host-sdk.modules.Vbox.vbox-set-memory-net-firmware

> **File**: `book-0-builder/host-sdk/modules/Vbox.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Rewrite SetMemory, SetNetworkAdapter, SetFirmware

#### Diff

```diff
 SetMemory = {
-    param([string]$VMName, [hashtable]$Settings)
-    return $this.Configure($VMName, $Settings)
+    param([string]$VMName, [hashtable]$Settings)
+    $s = @{}
+    foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) { $s[$key] = $Settings[$key] }
+    return $this.Configure($VMName, $s)
 }
 SetNetworkAdapter = {
-    param([string]$VMName, [hashtable]$Settings)
-    return $this.Configure($VMName, $Settings)
+    param([string]$VMName, [hashtable]$Settings)
+    $s = @{}
+    foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) { $s[$key] = $Settings[$key] }
+    return $this.Configure($VMName, $s)
 }
 SetFirmware = {
-    param([string]$VMName, [hashtable]$Settings)
-    return $this.Configure($VMName, $Settings)
+    param([string]$VMName, [hashtable]$Settings)
+    $s = @{}
+    foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) { $s[$key] = $Settings[$key] }
+    return $this.Configure($VMName, $s)
 }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 18 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 109: `book-0-builder/host-sdk/modules/HyperV.ps1` - Rename MemoryMB/DiskGB to Memory/Disk, add IsoPath [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-defaults-rename

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Rename MemoryMB/DiskGB to Memory/Disk, add IsoPath

#### Diff

```diff
-    MemoryMB = 4096
-    DiskGB = 40
+    Memory = 4096
+    Disk = 40960
+    IsoPath = $null
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 5 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 110: `book-0-builder/host-sdk/modules/HyperV.ps1` - Rename Worker Property accessors, add IsoPath [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-worker-props-rename

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Rename Worker Property accessors, add IsoPath

#### Diff

```diff
-            MemoryMB = { return $this.Rendered.MemoryMB }
-            DiskGB = { return $this.Rendered.DiskGB }
+            Memory = { return $this.Rendered.Memory }
+            Disk = { return $this.Rendered.Disk }
+            IsoPath = { return $this.Rendered.IsoPath }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 5 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 112: `book-0-builder/host-sdk/modules/HyperV.ps1` - Replace GetSwitch with GetGuestAdapter shape [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-get-guest-adapter-shape

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Replace GetSwitch with GetGuestAdapter shape

#### Diff

```diff
-        GetSwitch = {
-            param([string]$SwitchName)
-            if ($SwitchName) {
-                $sw = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
-                if ($sw) { return $sw.Name }
-            }
-            $ext = Get-VMSwitch -SwitchType External -ErrorAction SilentlyContinue | Select-Object -First 1
-            if ($ext) { return $ext.Name }
-            return $null
+        GetGuestAdapter = {
+            param([Parameter(Mandatory = $true)] [string]$AdapterName)
+            $adapter = $mod.SDK.Network.GetGuestAdapter($AdapterName)
+            if (-not $adapter) { return $null }
+            return $null # WIP
         }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 14 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 113: `book-0-builder/host-sdk/modules/HyperV.ps1` - Fill GetGuestAdapter VMSwitch lookup [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-get-guest-adapter-impl

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Fill GetGuestAdapter VMSwitch lookup

#### Diff

```diff
-            if (-not $adapter) { return $null }
-            return $null # WIP
+            if (-not $adapter) { return $null }
+            $physical = Get-NetAdapter -Name $AdapterName -ErrorAction SilentlyContinue
+            $description = if ($physical) { $physical.InterfaceDescription } else { $adapter.InterfaceDescription }
+            $switches = Get-VMSwitch -SwitchType External -ErrorAction SilentlyContinue
+            $match = $switches | Where-Object {
+                $_.NetAdapterInterfaceDescription -eq $description -or
+                $_.NetAdapterInterfaceDescription -match "^$([regex]::Escape($description))(s+#d+)?$"
+            } | Select-Object -First 1
+            if (-not $match) {
+                Write-Warning "VMSwitch for adapter '$AdapterName' not found."
+                return $null
+            }
+            return $match.Name
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 15 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 114: `book-0-builder/host-sdk/modules/HyperV.ps1` - Rename Give SizeGB to Size in MB [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-give-size-rename

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Rename Give SizeGB to Size in MB

#### Diff

```diff
-        Give = {
-            param([string]$VMName, [string]$Path, [int]$SizeGB, [string]$ControllerType = "SCSI")
+        Give = {
+            param([string]$VMName, [string]$Path, [int]$Size, [string]$ControllerType = "SCSI")
             try {
-                New-VHD -Path $Path -SizeBytes ($SizeGB * 1GB) -Dynamic -ErrorAction Stop | Out-Null
+                New-VHD -Path $Path -SizeBytes ($Size * 1MB) -Dynamic -ErrorAction Stop | Out-Null
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 6 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 115: `book-0-builder/host-sdk/modules/HyperV.ps1` - Rewrite SetProcessor with key copy and Count handling [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-set-processor

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Rewrite SetProcessor with key copy and Count handling

#### Diff

```diff
         SetProcessor = {
-            param([string]$VMName, [hashtable]$Settings)
-            $Settings.VMName = $VMName
-            try { Set-VMProcessor @Settings -ErrorAction Stop; return $true } catch { return $false }
+            param([string]$VMName, [hashtable]$Settings)
+            $s = @{ VMName = $VMName }
+            foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) {
+                switch ($key) {
+                    "Count" { $s["Count"] = $Settings[$key] }
+                    default { $s[$key] = $Settings[$key] }
+                }
+            }
+            try { Set-VMProcessor @s -ErrorAction Stop; return $true } catch { return $false }
         }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 12 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |


### Commit 116: `book-0-builder/host-sdk/modules/HyperV.ps1` - Rewrite SetMemory and SetNetworkAdapter with key copy [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-set-memory-net

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Rewrite SetMemory and SetNetworkAdapter with key copy

#### Diff

```diff
         SetMemory = {
-            param([string]$VMName, [hashtable]$Settings)
-            $Settings.VMName = $VMName
-            try { Set-VMMemory @Settings -ErrorAction Stop; return $true } catch { return $false }
+            param([string]$VMName, [hashtable]$Settings)
+            $s = @{ VMName = $VMName }
+            foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) { $s[$key] = $Settings[$key] }
+            try { Set-VMMemory @s -ErrorAction Stop; return $true } catch { return $false }
         }
         SetNetworkAdapter = {
-            param([string]$VMName, [hashtable]$Settings)
-            $Settings.VMName = $VMName
-            try { Set-VMNetworkAdapter @Settings -ErrorAction Stop; return $true } catch { return $false }
+            param([string]$VMName, [hashtable]$Settings)
+            $s = @{ VMName = $VMName }
+            foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) { $s[$key] = $Settings[$key] }
+            try { Set-VMNetworkAdapter @s -ErrorAction Stop; return $true } catch { return $false }
         }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 14 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 117: `book-0-builder/host-sdk/modules/HyperV.ps1` - Rewrite SetFirmware with key copy [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-set-firmware

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Rewrite SetFirmware with key copy

#### Diff

```diff
         SetFirmware = {
-            param([string]$VMName, [hashtable]$Settings)
-            $Settings.VMName = $VMName
-            try { Set-VMFirmware @Settings -ErrorAction Stop; return $true } catch { return $false }
+            param([string]$VMName, [hashtable]$Settings)
+            $s = @{ VMName = $VMName }
+            foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) { $s[$key] = $Settings[$key] }
+            try { Set-VMFirmware @s -ErrorAction Stop; return $true } catch { return $false }
         }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 7 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 118: `book-0-builder/host-sdk/modules/HyperV.ps1` - Rename Create params to match Vbox, add Firmware [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-create-params

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Rename Create params to match Vbox, add Firmware

#### Diff

```diff
         Create = {
             param(
-                [string]$VMName, [string]$MediumPath, [string]$DVDPath,
-                [string]$SwitchName, [int]$Generation = 2,
-                [int]$DiskGB = 40, [int]$MemoryMB = 4096, [int]$CPUs = 2,
-                [bool]$Optimize = $true, [bool]$Hypervisor = $true
+                [string]$VMName, [string]$MediumPath, [string]$DVDPath,
+                [string]$AdapterName, [int]$Generation = 2,
+                [hashtable]$Firmware = @{},
+                [int]$Size = 40960, [int]$RAM = 4096, [int]$CPU = 2,
+                [bool]$Optimize = $true, [bool]$Hypervisor = $true
             )
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 119: `book-0-builder/host-sdk/modules/HyperV.ps1` - Rewrite Create core: VM creation, processor, firmware [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-create-core

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Rewrite Create core: VM creation, processor, firmware

#### Diff

```diff
             try {
-                $memBytes = $MemoryMB * 1MB
-                $diskBytes = $DiskGB * 1GB
-                New-VM -Name $VMName -MemoryStartupBytes $memBytes -Generation $Generation -NewVHDPath $MediumPath -NewVHDSizeBytes $diskBytes -ErrorAction Stop | Out-Null
-                $this.SetProcessor($VMName, @{ Count = $CPUs })
-                $switch = $this.GetSwitch($SwitchName)
-                if ($switch) {
-                    Connect-VMNetworkAdapter -VMName $VMName -SwitchName $switch
+                $memBytes = $RAM * 1MB
+                $diskBytes = $Size * 1MB
+                New-VM -Name $VMName -MemoryStartupBytes $memBytes -Generation $Generation -NewVHDPath $MediumPath -NewVHDSizeBytes $diskBytes -ErrorAction Stop | Out-Null
+                $configured = $this.SetProcessor($VMName, @{ Count = $CPU })
+                if (-not $configured) { throw "Failed to configure processor for VM '$VMName'." }
+                if ($Firmware.Count -gt 0) {
+                    $configured = $this.SetFirmware($VMName, $Firmware)
+                    if (-not $configured) { throw "Failed to configure firmware for VM '$VMName'." }
                 }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 15 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 120: `book-0-builder/host-sdk/modules/HyperV.ps1` - Fill Create network, optimize, hypervisor with throws [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-create-network-opts

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Fill Create network, optimize, hypervisor with throws

#### Diff

```diff
+                $switch = $this.GetGuestAdapter($AdapterName)
+                if ($switch) {
+                    Connect-VMNetworkAdapter -VMName $VMName -SwitchName $switch
+                }
                 if ($Optimize) {
-                    $this.Optimize($VMName)
+                    $configured = $this.Optimize($VMName)
+                    if (-not $configured) { throw "Failed to optimize VM '$VMName'." }
                 }
                 if ($Hypervisor) {
-                    $this.Hypervisor($VMName)
+                    $configured = $this.Hypervisor($VMName)
+                    if (-not $configured) { throw "Failed to enable nested virtualization for VM '$VMName'." }
                 }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 10 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |


### Commit 121: `book-0-builder/host-sdk/modules/HyperV.ps1` - Update Worker Create delegation for renamed params [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-worker-create-delegation

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update Worker Create delegation for renamed params

#### Diff

```diff
             Create = {
                 return $mod.SDK.HyperV.Create(
                     $this.Name,
                     $this.MediumPath,
-                    $null,
+                    $this.IsoPath,
                     $this.Network,
                     $this.Generation,
-                    $this.DiskGB,
-                    $this.MemoryMB,
+                    @{},
+                    $this.Disk,
+                    $this.Memory,
                     $this.CPUs
                 )
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 7 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 122: `book-0-builder/host-sdk/modules/HyperV.ps1` - Change Create Firmware from hashtable to string [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-create-firmware-string

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Change Create Firmware from hashtable to string

#### Diff

```diff
-                [hashtable]$Firmware = @{},
+                [string]$Firmware = "efi",
...
-                if ($Firmware.Count -gt 0) {
-                    $configured = $this.SetFirmware($VMName, $Firmware)
+                if ($Firmware) {
+                    $configured = $this.SetFirmware($VMName, @{ Firmware = $Firmware })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 6 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 123: `book-0-builder/host-sdk/modules/HyperV.ps1` - Update Worker Create delegation to pass firmware string [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-worker-create-firmware-string

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update Worker Create delegation to pass firmware string

#### Diff

```diff
-                    @{},
+                    "efi",
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 124: `book-0-builder/host-sdk/modules/Vbox.ps1` - Add unified key map to SetProcessor [COMPLETE]

### book-0-builder.host-sdk.modules.Vbox.vbox-set-processor-unified

> **File**: `book-0-builder/host-sdk/modules/Vbox.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add unified key map to SetProcessor

#### Diff

```diff
 SetProcessor = {
     param([string]$VMName, [hashtable]$Settings)
     $s = @{}
-    foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) {
+    foreach ($key in $Settings.Keys) {
         switch ($key) {
             "Count" { $s["cpus"] = $Settings[$key] }
-            default { $s[$key] = $Settings[$key] }
+            "ExposeVirtualizationExtensions" {
+                $s["nested-hw-virt"] = if ($Settings[$key]) { "on" } else { "off" }
+            }
+            { $_ -in @("cpus","pae","nestedpaging","hwvirtex","largepages","nested-hw-virt","graphicscontroller","vram") } {
+                $s[$key] = $Settings[$key]
+            }
         }
     }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 125: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add unified key map to SetProcessor [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-set-processor-unified

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add unified key map to SetProcessor

#### Diff

```diff
 SetProcessor = {
     param([string]$VMName, [hashtable]$Settings)
     $s = @{ VMName = $VMName }
-    foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) {
+    foreach ($key in $Settings.Keys) {
         switch ($key) {
-            "Count" { $s["Count"] = $Settings[$key] }
-            default { $s[$key] = $Settings[$key] }
+            "cpus" { $s.Count = $Settings[$key] }
+            "nested-hw-virt" {
+                $s.ExposeVirtualizationExtensions = $Settings[$key] -eq "on"
+            }
+            { $_ -in @("Count","ExposeVirtualizationExtensions") } {
+                $s[$key] = $Settings[$key]
+            }
         }
     }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 11 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 126: `book-0-builder/host-sdk/modules/Vbox.ps1` - Add unified key map to SetMemory [COMPLETE]

### book-0-builder.host-sdk.modules.Vbox.vbox-set-memory-unified

> **File**: `book-0-builder/host-sdk/modules/Vbox.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add unified key map to SetMemory

#### Diff

```diff
 SetMemory = {
     param([string]$VMName, [hashtable]$Settings)
     $s = @{}
-    foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) { $s[$key] = $Settings[$key] }
+    foreach ($key in $Settings.Keys) {
+        switch ($key) {
+            "MemoryMB" { $s["memory"] = $Settings[$key] }
+            "MemoryGB" { $s["memory"] = $Settings[$key] * 1024 }
+            "StartupBytes" { $s["memory"] = [math]::Floor($Settings[$key] / 1MB) }
+            { $_ -in @("memory") } { $s[$key] = $Settings[$key] }
+        }
+    }
     return $this.Configure($VMName, $s)
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 127: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add unified key map to SetMemory [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-set-memory-unified

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add unified key map to SetMemory

#### Diff

```diff
 SetMemory = {
     param([string]$VMName, [hashtable]$Settings)
     $s = @{ VMName = $VMName }
-    foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) { $s[$key] = $Settings[$key] }
+    foreach ($key in $Settings.Keys) {
+        switch ($key) {
+            "MemoryMB" { $s.StartupBytes = $Settings[$key] * 1MB }
+            "MemoryGB" { $s.StartupBytes = $Settings[$key] * 1GB }
+            "memory" { $s.StartupBytes = $Settings[$key] * 1MB }
+            { $_ -in @("DynamicMemoryEnabled","StartupBytes") } { $s[$key] = $Settings[$key] }
+        }
+    }
     try { Set-VMMemory @s -ErrorAction Stop; return $true } catch { return $false }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 128: `book-0-builder/host-sdk/modules/Vbox.ps1` - Add key filtering to SetNetworkAdapter and SetFirmware [COMPLETE]

### book-0-builder.host-sdk.modules.Vbox.vbox-set-net-firmware-filter

> **File**: `book-0-builder/host-sdk/modules/Vbox.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add key filtering to SetNetworkAdapter and SetFirmware

#### Diff

```diff
 SetNetworkAdapter = {
     param([string]$VMName, [hashtable]$Settings)
     $s = @{}
-    foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) { $s[$key] = $Settings[$key] }
+    foreach ($key in $Settings.Keys) {
+        switch ($key) {
+            { $_ -in @("nic1","bridgeadapter1") } { $s[$key] = $Settings[$key] }
+        }
+    }
     return $this.Configure($VMName, $s)
 }
 SetFirmware = {
     param([string]$VMName, [hashtable]$Settings)
     $s = @{}
-    foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) { $s[$key] = $Settings[$key] }
+    foreach ($key in $Settings.Keys) {
+        switch ($key) {
+            "Firmware" { $s["firmware"] = $Settings[$key] }
+            { $_ -in @("firmware") } { $s[$key] = $Settings[$key] }
+        }
+    }
     return $this.Configure($VMName, $s)
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 13 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 129: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add key filtering to SetNetworkAdapter and SetFirmware [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-set-net-firmware-filter

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add key filtering to SetNetworkAdapter and SetFirmware

#### Diff

```diff
 SetNetworkAdapter = {
     param([string]$VMName, [hashtable]$Settings)
     $s = @{ VMName = $VMName }
-    foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) { $s[$key] = $Settings[$key] }
+    foreach ($key in $Settings.Keys) {
+        switch ($key) {
+            { $_ -in @("MacAddressSpoofing") } { $s[$key] = $Settings[$key] }
+        }
+    }
     try { Set-VMNetworkAdapter @s -ErrorAction Stop; return $true } catch { return $false }
 }
 SetFirmware = {
     param([string]$VMName, [hashtable]$Settings)
     $s = @{ VMName = $VMName }
-    foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) { $s[$key] = $Settings[$key] }
+    foreach ($key in $Settings.Keys) {
+        switch ($key) {
+            { $_ -in @("EnableSecureBoot","SecureBootTemplate") } { $s[$key] = $Settings[$key] }
+        }
+    }
     try { Set-VMFirmware @s -ErrorAction Stop; return $true } catch { return $false }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 12 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |


### Commit 130: `book-0-builder/host-sdk/modules/Vbox.ps1` - Restore .Keys pipeline in Vbox Set* methods to fix OrderedDictionary enumeration bug [COMPLETE]

### book-0-builder.host-sdk.modules.Vbox.vbox-keys-pipeline-restore

> **File**: `book-0-builder/host-sdk/modules/Vbox.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Restore .Keys pipeline in Vbox Set* methods to fix OrderedDictionary enumeration bug

#### Diff

```diff
 SetProcessor = {
     param([string]$VMName, [hashtable]$Settings)
     $s = @{}
-    foreach ($key in $Settings.Keys) {
+    foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) {
         switch ($key) {
...
 SetMemory = {
     param([string]$VMName, [hashtable]$Settings)
     $s = @{}
-    foreach ($key in $Settings.Keys) {
+    foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) {
         switch ($key) {
...
 SetNetworkAdapter = {
     param([string]$VMName, [hashtable]$Settings)
     $s = @{}
-    foreach ($key in $Settings.Keys) {
+    foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) {
         switch ($key) {
...
 SetFirmware = {
     param([string]$VMName, [hashtable]$Settings)
     $s = @{}
-    foreach ($key in $Settings.Keys) {
+    foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) {
         switch ($key) {
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 8 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 131: `book-0-builder/host-sdk/modules/HyperV.ps1` - Restore .Keys pipeline in HyperV Set* methods to fix OrderedDictionary enumeration bug [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-keys-pipeline-restore

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Restore .Keys pipeline in HyperV Set* methods to fix OrderedDictionary enumeration bug

#### Diff

```diff
 SetProcessor = {
     param([string]$VMName, [hashtable]$Settings)
     $s = @{ VMName = $VMName }
-    foreach ($key in $Settings.Keys) {
+    foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) {
         switch ($key) {
...
 SetMemory = {
     param([string]$VMName, [hashtable]$Settings)
     $s = @{ VMName = $VMName }
-    foreach ($key in $Settings.Keys) {
+    foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) {
         switch ($key) {
...
 SetNetworkAdapter = {
     param([string]$VMName, [hashtable]$Settings)
     $s = @{ VMName = $VMName }
-    foreach ($key in $Settings.Keys) {
+    foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) {
         switch ($key) {
...
 SetFirmware = {
     param([string]$VMName, [hashtable]$Settings)
     $s = @{ VMName = $VMName }
-    foreach ($key in $Settings.Keys) {
+    foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) {
         switch ($key) {
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 8 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 132: `book-0-builder/host-sdk/modules/Vbox.ps1` - Add cross-platform key skips to Vbox SetMemory, SetNetworkAdapter, SetFirmware [COMPLETE]

### book-0-builder.host-sdk.modules.Vbox.vbox-cross-platform-skips

> **File**: `book-0-builder/host-sdk/modules/Vbox.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add cross-platform key skips to Vbox SetMemory, SetNetworkAdapter, SetFirmware

#### Diff

```diff
 SetMemory = {
     ...
     foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) {
         switch ($key) {
             "MemoryMB" { $s["memory"] = $Settings[$key] }
             "MemoryGB" { $s["memory"] = $Settings[$key] * 1024 }
             "StartupBytes" { $s["memory"] = [math]::Floor($Settings[$key] / 1MB) }
             { $_ -in @("memory") } { $s[$key] = $Settings[$key] }
+            "DynamicMemoryEnabled" {} # HyperV only
         }
     }
...
 SetNetworkAdapter = {
     ...
     foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) {
         switch ($key) {
             { $_ -in @("nic1","bridgeadapter1") } { $s[$key] = $Settings[$key] }
+            "MacAddressSpoofing" {} # HyperV only
         }
     }
...
 SetFirmware = {
     ...
     foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) {
         switch ($key) {
             "Firmware" { $s["firmware"] = $Settings[$key] }
             { $_ -in @("firmware") } { $s[$key] = $Settings[$key] }
+            { $_ -in @("EnableSecureBoot","SecureBootTemplate") } {} # HyperV only
         }
     }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 3 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 133: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add cross-platform key skips to HyperV SetProcessor, SetNetworkAdapter, SetFirmware [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-cross-platform-skips

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add cross-platform key skips to HyperV SetProcessor, SetNetworkAdapter, SetFirmware

#### Diff

```diff
 SetProcessor = {
     ...
     foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) {
         switch ($key) {
             "cpus" { $s.Count = $Settings[$key] }
             "nested-hw-virt" {
                 $s.ExposeVirtualizationExtensions = $Settings[$key] -eq "on"
             }
             { $_ -in @("Count","ExposeVirtualizationExtensions") } {
                 $s[$key] = $Settings[$key]
             }
+            { $_ -in @("pae","nestedpaging","hwvirtex","largepages","graphicscontroller","vram") } {} # VBox only
         }
     }
...
 SetNetworkAdapter = {
     ...
     foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) {
         switch ($key) {
             { $_ -in @("MacAddressSpoofing") } { $s[$key] = $Settings[$key] }
+            { $_ -in @("nic1","bridgeadapter1") } {} # VBox only
         }
     }
...
 SetFirmware = {
     ...
     foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) {
         switch ($key) {
             { $_ -in @("EnableSecureBoot","SecureBootTemplate") } { $s[$key] = $Settings[$key] }
+            { $_ -in @("Firmware","firmware") } {} # VBox only
         }
     }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 3 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 134: `book-0-builder/host-sdk/modules/HyperV.ps1` - Add Elevated method to check if PowerShell session has Administrator privileges [COMPLETE]

### book-0-builder.host-sdk.modules.HyperV.hyperv-elevated-check

> **File**: `book-0-builder/host-sdk/modules/HyperV.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Elevated method to check if PowerShell session has Administrator privileges

#### Diff

```diff
 Add-ScriptMethods $HyperV @{
+    Elevated = {
+        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
+        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
+        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
+    }
+}
+
+Add-ScriptMethods $HyperV @{
     GetGuestAdapter = {
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 8 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 135: `book-0-builder/host-sdk/modules/Multipass.ps1` - Add Backend method to detect hypervisor backend via multipass get local.driver [COMPLETE]

### book-0-builder.host-sdk.modules.Multipass.multipass-backend

> **File**: `book-0-builder/host-sdk/modules/Multipass.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Backend method to detect hypervisor backend via multipass get local.driver

#### Diff

```diff
 Add-ScriptMethods $Multipass @{
     Invoke = {
         $output = & multipass @args 2>&1
         ...
     }
+    Backend = {
+        $result = $this.Invoke("get", "local.driver")
+        if ($result.Success) { return ($result.Output | Out-String).Trim() }
+        return $null
+    }
     Worker = {
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 5 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 136: `book-0-builder/host-sdk/modules/Multipass.ps1` - Add Hypervisor method to delegate nested virt to the correct SDK backend module [COMPLETE]

### book-0-builder.host-sdk.modules.Multipass.multipass-hypervisor

> **File**: `book-0-builder/host-sdk/modules/Multipass.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add Hypervisor method to delegate nested virt to the correct SDK backend module

#### Diff

```diff
+    Hypervisor = {
+        param([string]$VMName)
+        $backend = $this.Backend()
+        $map = @{ "hyperv" = "HyperV"; "virtualbox" = "Vbox" }
+        $sdkModule = $map[$backend]
+        if (-not $sdkModule) {
+            Write-Warning "Nested virtualization not supported for backend '$backend'"
+            return $false
+        }
+        return $mod.SDK."$sdkModule".Hypervisor($VMName)
+    }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 11 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 137: `book-0-builder/config/vm.config.yaml` - Add hyperv section to vm.config.yaml for HyperV test VM configuration [COMPLETE]

### book-0-builder.config.vm.config.config-hyperv-section

> **File**: `book-0-builder/config/vm.config.yaml`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add hyperv section to vm.config.yaml for HyperV test VM configuration

#### Diff

```diff
 vbox:
   name: "ubuntu-autoinstall-test"
   memory: 4096
   cpus: 2
   disk_size: 40960  # MB (40GB for ZFS)
+
+# Hyper-V VM settings (for autoinstall ISO testing)
+hyperv:
+  name: "ubuntu-autoinstall-test-hv"
+  memory: 4096
+  cpus: 2
+  disk: 40960
+  network: "Ethernet 3"
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 8 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 138: `book-1-foundation/Invoke-AutoinstallTest.ps1` - Move Invoke-AutoinstallTest.ps1 to book-1-foundation and update SDK path [COMPLETE]

### book-1-foundation.Invoke-AutoinstallTest.move-invoke-autoinstall

> **File**: `book-0-builder/host-sdk/Invoke-AutoinstallTest.ps1 -> book-1-foundation/Invoke-AutoinstallTest.ps1`
> **Type**: MOVED
> **Commit**: 1 of 1 for this file

#### Description

Move Invoke-AutoinstallTest.ps1 to book-1-foundation and update SDK path

#### Diff

```diff
 param([switch]$SkipCleanup)
 
-. "$PSScriptRootSDK.ps1"
+. "$PSScriptRoot..ook-0-builderhost-sdkSDK.ps1"
 
 # Assumes ISO was already built (artifacts.iso populated)
 # Run autoinstall tests (ISO path queried from artifacts automatically)
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | move | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 139: `book-2-cloud/Invoke-IncrementalTest.ps1` - Move Invoke-IncrementalTest.ps1 to book-2-cloud and update SDK path [COMPLETE]

### book-2-cloud.Invoke-IncrementalTest.move-invoke-incremental

> **File**: `book-0-builder/host-sdk/Invoke-IncrementalTest.ps1 -> book-2-cloud/Invoke-IncrementalTest.ps1`
> **Type**: MOVED
> **Commit**: 1 of 1 for this file

#### Description

Move Invoke-IncrementalTest.ps1 to book-2-cloud and update SDK path

#### Diff

```diff
 param([int]$Layer, [switch]$SkipCleanup)
 
-. "$PSScriptRootSDK.ps1"
+. "$PSScriptRoot..ook-0-builderhost-sdkSDK.ps1"
 
 # Setup builder (Build is called by CloudInitTest.Run with Layer)
 $SDK.Builder.Stage()
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | move | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 140: `book-0-builder/host-sdk/modules/Verifications.ps1` - Remove Register method from Verifications.ps1 (fragments will declare tests on mod.Tests instead) [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.verifications-remove-register

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Remove Register method from Verifications.ps1 (fragments will declare tests on mod.Tests instead)

#### Diff

```diff
-    Register = {
-        param([string]$Fragment, [int]$Layer, [System.Collections.Specialized.OrderedDictionary]$Tests)
-        if (-not $mod.Tests[$Fragment]) { $mod.Tests[$Fragment] = @{} }
-        if (-not $mod.Tests[$Fragment][$Layer]) { $mod.Tests[$Fragment][$Layer] = [ordered]@{} }
-        foreach ($key in ($Tests.Keys | ForEach-Object { $_ })) {
-            $mod.Tests[$Fragment][$Layer][$key] = $Tests[$key]
-        }
-    }
-    Test = {
-        param([string]$Fragment, [int]$Layer, [string]$Name, $Worker)
-        $test = $mod.Tests[$Fragment][$Layer][$Name]
-        if ($test) { & $test $Worker }
-    }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 13 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 141: `book-0-builder/host-sdk/modules/Verifications.ps1` - Refactor Load to accept Path/Layer/Book, invoke module, extract mod.Tests, register in multi-dimensional hashtable [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.verifications-refactor-load

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Refactor Load to accept Path/Layer/Book, invoke module, extract mod.Tests, register in multi-dimensional hashtable

#### Diff

```diff
     Load = {
-        param([string]$Path)
-        & $Path -SDK $mod.SDK
+        param([string]$Path, [int]$Layer, [int]$Book)
+        $module = & $Path -SDK $mod.SDK
+        $tests = & $module { $mod.Tests }
+        if (-not $tests) { return }
+        $fragDir = Split-Path (Split-Path (Split-Path $Path))
+        $buildYaml = Join-Path $fragDir "build.yaml"
+        $meta = Get-Content $buildYaml -Raw | ConvertFrom-Yaml
+        $order = $meta.build_order
+        if (-not $mod.Tests[$Layer]) { $mod.Tests[$Layer] = @{} }
+        if (-not $mod.Tests[$Layer][$Book]) { $mod.Tests[$Layer][$Book] = @{} }
+        $mod.Tests[$Layer][$Book][$order] = $tests
     }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 13 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 142: `book-0-builder/host-sdk/modules/Verifications.ps1` - Refactor Discover to iterate layers and books, passing layer and book number to Load [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.verifications-refactor-discover

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Refactor Discover to iterate layers and books, passing layer and book number to Load

#### Diff

```diff
     Discover = {
         param([int]$Layer)
-        foreach ($l in 1..$Layer) {
+        foreach ($l in 0..$Layer) {
             foreach ($book in @("book-1-foundation", "book-2-cloud")) {
-                $pattern = Join-Path $book "*/tests/$l/verifications.ps1"
+                $bookNum = if ($book -match 'book-(d+)') { [int]$matches[1] } else { 0 }
+                $pattern = Join-Path $book "*/tests/$l/verifications.ps1"
                 Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | ForEach-Object {
-                    $this.Load($_.FullName)
+                    $this.Load($_.FullName, $l, $bookNum)
                 }
             }
         }
     }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 7 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 143: `book-0-builder/host-sdk/modules/Verifications.ps1` - Refactor Run to accept Runner/Layer/Book, iterate layer->book->build_order with optional book filtering [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.verifications-refactor-run

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Refactor Run to accept Runner/Layer/Book, iterate layer->book->build_order with optional book filtering

#### Diff

```diff
     Run = {
-        param($Worker, [int]$Layer)
+        param($Runner, [int]$Layer, $Book = $null)
         $this.Discover($Layer)
-        foreach ($l in 1..$Layer) {
-            $layerName = $mod.SDK.Fragments.LayerName($l)
-            foreach ($frag in ($mod.Tests.Keys | ForEach-Object { $_ })) {
-                if (-not $mod.Tests[$frag][$l]) { continue }
-                $mod.SDK.Log.Write("`n--- $layerName - $frag ---", "Cyan")
-                foreach ($name in ($mod.Tests[$frag][$l].Keys | ForEach-Object { $_ })) {
-                    $this.Test($frag, $l, $name, $Worker)
+        $bookOrder = if ($null -ne $Book) { @($Book) } else { @(2, 1) }
+        foreach ($l in 0..$Layer) {
+            if (-not $mod.Tests[$l]) { continue }
+            $layerName = $mod.SDK.Fragments.LayerName($l)
+            foreach ($b in $bookOrder) {
+                if (-not $mod.Tests[$l][$b]) { continue }
+                foreach ($order in ($mod.Tests[$l][$b].Keys | ForEach-Object { $_ } | Sort-Object)) {
+                    $tests = $mod.Tests[$l][$b][$order]
+                    foreach ($name in ($tests.Keys | ForEach-Object { $_ })) {
+                        & $tests[$name] $Runner
+                    }
                 }
             }
         }
     }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 20 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 144: `book-1-foundation/base/tests/0/verifications.ps1` - Convert book-1 base verifications to return-module pattern with mod.Tests declaration [COMPLETE]

### book-1-foundation.base.tests.0.verifications.fragment-decl-book1

> **File**: `book-1-foundation/base/tests/0/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Convert book-1 base verifications to return-module pattern with mod.Tests declaration

#### Diff

```diff
 param([Parameter(Mandatory = $true)] $SDK)
 
-New-Module -Name "Verify.Base" -ScriptBlock {
+return (New-Module -Name "Verify.Base" -ScriptBlock {
     param([Parameter(Mandatory = $true)] $SDK)
     $mod = @{ SDK = $SDK }
     . "$PSScriptRoot........ook-0-builderhost-sdkhelpersPowerShell.ps1"
 
-    $mod.SDK.Testing.Verifications.Register("base", 0, [ordered]@{})
-} -ArgumentList $SDK
+    $mod.Tests = [ordered]@{}
+
+    Export-ModuleMember -Function @()
+} -ArgumentList $SDK)
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 8 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 145: `book-2-cloud/network/tests/1/verifications.ps1` - Convert book-2 layers 1-5 verifications (network, kernel, users, ssh, ufw) to return-module pattern [COMPLETE]

### book-2-cloud.network.tests.1.verifications.fragment-decl-book2-l1-5

> **File**: `book-2-cloud/network/tests/1/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Convert book-2 layers 1-5 verifications (network, kernel, users, ssh, ufw) to return-module pattern

#### Diff

```diff
 # Pattern applied to each of 5 files:
 # network/tests/1, kernel/tests/2, users/tests/3, ssh/tests/4, ufw/tests/5
 param([Parameter(Mandatory = $true)] $SDK)
 
-New-Module -Name "Verify.<Name>" -ScriptBlock {
+return (New-Module -Name "Verify.<Name>" -ScriptBlock {
     param([Parameter(Mandatory = $true)] $SDK)
     $mod = @{ SDK = $SDK }
     ...
-    $mod.SDK.Testing.Verifications.Register("<name>", <N>, [ordered]@{
+    $mod.Tests = [ordered]@{
         ...
-    })
-} -ArgumentList $SDK
+    }
+    Export-ModuleMember -Function @()
+} -ArgumentList $SDK)
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 146: `book-2-cloud/system/tests/6/verifications.ps1` - Convert book-2 layers 6-10 verifications (system, msmtp, pkg-security/8, security-mon, virtualization) to return-module pattern [COMPLETE]

### book-2-cloud.system.tests.6.verifications.fragment-decl-book2-l6-10

> **File**: `book-2-cloud/system/tests/6/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Convert book-2 layers 6-10 verifications (system, msmtp, pkg-security/8, security-mon, virtualization) to return-module pattern

#### Diff

```diff
 # Pattern applied to each of 5 files:
 # system/tests/6, msmtp/tests/7, pkg-security/tests/8, security-mon/tests/9, virtualization/tests/10
 param([Parameter(Mandatory = $true)] $SDK)
 
-New-Module -Name "Verify.<Name>" -ScriptBlock {
+return (New-Module -Name "Verify.<Name>" -ScriptBlock {
     param([Parameter(Mandatory = $true)] $SDK)
     $mod = @{ SDK = $SDK }
     ...
-    $mod.SDK.Testing.Verifications.Register("<name>", <N>, [ordered]@{
+    $mod.Tests = [ordered]@{
         ...
-    })
-} -ArgumentList $SDK
+    }
+    Export-ModuleMember -Function @()
+} -ArgumentList $SDK)
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 147: `book-2-cloud/cockpit/tests/11/verifications.ps1` - Convert book-2 layers 11-15 verifications (cockpit, claude-code, copilot-cli, opencode, ui) to return-module pattern [COMPLETE]

### book-2-cloud.cockpit.tests.11.verifications.fragment-decl-book2-l11-15

> **File**: `book-2-cloud/cockpit/tests/11/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Convert book-2 layers 11-15 verifications (cockpit, claude-code, copilot-cli, opencode, ui) to return-module pattern

#### Diff

```diff
 # Pattern applied to each of 5 files:
 # cockpit/tests/11, claude-code/tests/12, copilot-cli/tests/13, opencode/tests/14, ui/tests/15
 param([Parameter(Mandatory = $true)] $SDK)
 
-New-Module -Name "Verify.<Name>" -ScriptBlock {
+return (New-Module -Name "Verify.<Name>" -ScriptBlock {
     param([Parameter(Mandatory = $true)] $SDK)
     $mod = @{ SDK = $SDK }
     ...
-    $mod.SDK.Testing.Verifications.Register("<name>", <N>, [ordered]@{
+    $mod.Tests = [ordered]@{
         ...
-    })
-} -ArgumentList $SDK
+    }
+    Export-ModuleMember -Function @()
+} -ArgumentList $SDK)
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 148: `book-2-cloud/pkg-security/tests/16/verifications.ps1` - Convert book-2 layers 16-18 verifications (pkg-security/16, pkg-security/17, pkg-security/18) to return-module pattern [COMPLETE]

### book-2-cloud.pkg-security.tests.16.verifications.fragment-decl-book2-l16-18

> **File**: `book-2-cloud/pkg-security/tests/16/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Convert book-2 layers 16-18 verifications (pkg-security/16, pkg-security/17, pkg-security/18) to return-module pattern

#### Diff

```diff
 # Pattern applied to each of 3 files:
 # pkg-security/tests/16, pkg-security/tests/17, pkg-security/tests/18
 param([Parameter(Mandatory = $true)] $SDK)
 
-New-Module -Name "Verify.<Name>" -ScriptBlock {
+return (New-Module -Name "Verify.<Name>" -ScriptBlock {
     param([Parameter(Mandatory = $true)] $SDK)
     $mod = @{ SDK = $SDK }
     ...
-    $mod.SDK.Testing.Verifications.Register("<name>", <N>, [ordered]@{
+    $mod.Tests = [ordered]@{
         ...
-    })
-} -ArgumentList $SDK
+    }
+    Export-ModuleMember -Function @()
+} -ArgumentList $SDK)
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 149: `book-0-builder/host-sdk/modules/CloudInitTest.ps1` - Accept Runner argument, delegate to Verifications.Run with Book=2 instead of iterating fragments directly [COMPLETE]

### book-0-builder.host-sdk.modules.CloudInitTest.cloudinittest-runner-arg

> **File**: `book-0-builder/host-sdk/modules/CloudInitTest.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Accept Runner argument, delegate to Verifications.Run with Book=2 instead of iterating fragments directly

#### Diff

```diff
     Run = {
-        param([int]$Layer, [hashtable]$Overrides = @{})
-        $worker = $mod.SDK.CloudInit.Worker($Layer, $Overrides)
-        $mod.SDK.Log.Info("Setting up cloud-init test worker: $($worker.Name)")
-        $worker.Setup($true)
+        param([int]$Layer, [hashtable]$Overrides = @{}, $Runner = $null)
+        if (-not $Runner) {
+            $Runner = $mod.SDK.CloudInit.Worker($Layer, $Overrides)
+            $mod.SDK.Log.Info("Setting up cloud-init test worker: $($Runner.Name)")
+            $Runner.Setup($true)
+        }
         $mod.SDK.Testing.Reset()
-        foreach ($l in 1..$Layer) {
-            foreach ($f in $mod.SDK.Fragments.At($l)) {
-                $worker.Test($f.Name, "Test $($f.Name)", $f.TestCommand, $f.ExpectedPattern)
-            }
-        }
+        $mod.SDK.Testing.Verifications.Run($Runner, $Layer, 2)
         $mod.SDK.Testing.Summary()
-        return @{ Success = ($mod.SDK.Testing.FailCount -eq 0); Results = $mod.SDK.Testing.Results; Worker = $worker }
+        return @{ Success = ($mod.SDK.Testing.FailCount -eq 0); Results = $mod.SDK.Testing.Results; Worker = $Runner }
     }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 18 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 150a: `book-0-builder/host-sdk/modules/AutoinstallTest.ps1` - Replace AutoinstallTest.Run signature and remove old body, add placeholder [COMPLETE]

### book-0-builder.host-sdk.modules.AutoinstallTest.autoinstalltest-new-signature

> **File**: `book-0-builder/host-sdk/modules/AutoinstallTest.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 0 for this file

#### Description

Replace AutoinstallTest.Run signature and remove old body, add placeholder

#### Diff

```diff
     Run = {
-        param([hashtable]$Overrides = @{})
-        $worker = $mod.SDK.Autoinstall.Worker($Overrides)
-        $mod.SDK.Log.Info("Setting up autoinstall test worker: $($worker.Name)")
-        $worker.Ensure(); $worker.Start()
-        $mod.SDK.Log.Info("Waiting for SSH availability...")
-        $mod.SDK.Network.WaitForSSH($worker.SSHHost, $worker.SSHPort, 600)
-        $mod.SDK.Testing.Reset()
-        foreach ($f in $mod.SDK.Fragments.IsoRequired()) {
-            $worker.Test($f.Name, "Test $($f.Name)", $f.TestCommand, $f.ExpectedPattern)
-        }
-        $mod.SDK.Testing.Summary()
-        return @{ Success = ($mod.SDK.Testing.FailCount -eq 0); Results = $mod.SDK.Testing.Results; Worker = $worker }
+        param(
+            [int]$Layer,
+            [string[]]$Hypervisors = @("Vbox", "HyperV"),
+            [hashtable]$Overrides = @{}
+        )
+        # WIP: orchestrate book 2 then book 1
     }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 18 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 150b: `book-0-builder/host-sdk/modules/AutoinstallTest.ps1` - Implement AutoinstallTest.Run body: CloudInitTest for book 2, then loop hypervisors for book 1

### book-0-builder.host-sdk.modules.AutoinstallTest.autoinstalltest-impl-body

> **File**: `book-0-builder/host-sdk/modules/AutoinstallTest.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Implement AutoinstallTest.Run body: CloudInitTest for book 2, then loop hypervisors for book 1

#### Diff

```diff
         param(
             [int]$Layer,
             [string[]]$Hypervisors = @("Vbox", "HyperV"),
             [hashtable]$Overrides = @{}
         )
-        # WIP: orchestrate book 2 then book 1
+        $mod.SDK.CloudInit.Test.Run($Layer, $Overrides)
+        foreach ($hypervisor in $Hypervisors) {
+            $config = $mod.SDK.Settings.Virtualization."$hypervisor"
+            if (-not $config) { continue }
+            $worker = $mod.SDK."$hypervisor".Worker(@{ Config = $config })
+            $worker.Ensure(); $worker.Start()
+            $mod.SDK.Network.WaitForSSH($worker.SSHHost, $worker.SSHPort, 600)
+            $mod.SDK.Testing.Verifications.Run($worker, $Layer, 1)
+        }
     }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 10 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 151a: `book-1-foundation/base/tests/0/verifications.ps1` - Add verification tests shape with SSH reachable and OS version tests

### book-1-foundation.base.tests.0.verifications.book1-verif-shape

> **File**: `book-1-foundation/base/tests/0/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 0 for this file

#### Description

Add verification tests shape with SSH reachable and OS version tests

#### Diff

```diff
-    $mod.Tests = [ordered]@{}
+    $mod.Tests = [ordered]@{
+        "SSH reachable" = {
+            param($Worker)
+            $result = $Worker.Exec("echo ok")
+            $mod.SDK.Testing.Record(@{
+                Test = "0.1"; Name = "SSH reachable"
+                Pass = $result.Success; Output = $result.Output
+            })
+        }
+        "OS version correct" = {
+            param($Worker)
+            $result = $Worker.Exec("lsb_release -cs")
+            $mod.SDK.Testing.Record(@{
+                Test = "0.2"; Name = "OS version correct"
+                Pass = ($result.Success -and $result.Output); Output = $result.Output
+            })
+        }
+    }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 19 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 151b: `book-1-foundation/base/tests/0/verifications.ps1` - Add root filesystem ext4 and default user verification tests

### book-1-foundation.base.tests.0.verifications.book1-verif-storage

> **File**: `book-1-foundation/base/tests/0/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 0 for this file

#### Description

Add root filesystem ext4 and default user verification tests

#### Diff

```diff
         "OS version correct" = {
             ...
         }
+        "Root filesystem is ext4" = {
+            param($Worker)
+            $result = $Worker.Exec("findmnt -n -o FSTYPE /")
+            $mod.SDK.Testing.Record(@{
+                Test = "0.3"; Name = "Root filesystem is ext4"
+                Pass = ($result.Output -match "ext4"); Output = $result.Output
+            })
+        }
+        "Default user exists" = {
+            param($Worker)
+            $result = $Worker.Exec("id -un")
+            $mod.SDK.Testing.Record(@{
+                Test = "0.4"; Name = "Default user exists"
+                Pass = ($result.Success -and $result.Output); Output = $result.Output
+            })
+        }
     }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 16 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 151c: `book-1-foundation/base/tests/0/verifications.ps1` - Add hostname set and SSH service active verification tests

### book-1-foundation.base.tests.0.verifications.book1-verif-hostname-ssh

> **File**: `book-1-foundation/base/tests/0/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add hostname set and SSH service active verification tests

#### Diff

```diff
         "Default user exists" = {
             ...
         }
+        "Hostname set" = {
+            param($Worker)
+            $result = $Worker.Exec("hostname -s")
+            $mod.SDK.Testing.Record(@{
+                Test = "0.5"; Name = "Hostname set"
+                Pass = ($result.Success -and $result.Output -and $result.Output -ne "localhost")
+                Output = $result.Output
+            })
+        }
+        "SSH service active" = {
+            param($Worker)
+            $result = $Worker.Exec("systemctl is-active ssh")
+            $mod.SDK.Testing.Record(@{
+                Test = "0.6"; Name = "SSH service active"
+                Pass = ($result.Output -match "active"); Output = $result.Output
+            })
+        }
     }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 17 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 151d: `book-1-foundation/base/tests/0/verifications.ps1` - Add cloud-init finished and no cloud-init errors verification tests

### book-1-foundation.base.tests.0.verifications.book1-verif-cloudinit

> **File**: `book-1-foundation/base/tests/0/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add cloud-init finished and no cloud-init errors verification tests

#### Diff

```diff
         "SSH service active" = {
             ...
         }
+        "Cloud-init finished" = {
+            param($Worker)
+            $result = $Worker.Exec("cloud-init status")
+            $mod.SDK.Testing.Record(@{
+                Test = "0.7"; Name = "Cloud-init finished"
+                Pass = ($result.Output -match "done"); Output = $result.Output
+            })
+        }
+        "No cloud-init errors" = {
+            param($Worker)
+            $result = $Worker.Exec("cloud-init status")
+            $mod.SDK.Testing.Record(@{
+                Test = "0.8"; Name = "No cloud-init errors"
+                Pass = ($result.Output -notmatch "error|degraded"); Output = $result.Output
+            })
+        }
     }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 16 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |
