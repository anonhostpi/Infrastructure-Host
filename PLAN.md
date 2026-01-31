# Plan


### Commit 1: `book-0-builder/host-sdk/modules/Vbox.ps1` - Fix VBox worker SSH defaults: load network.config.yaml for SSHHost, remove SSHPort hardcode [COMPLETE]

### book-0-builder.host-sdk.modules.Vbox.fix-ssh-defaults

> **File**: `book-0-builder/host-sdk/modules/Vbox.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Fix VBox worker SSH defaults: load network.config.yaml for SSHHost, remove SSHPort hardcode

#### Diff

```diff
-                if (-not $rendered.SSHUser -or -not $rendered.SSHHost -or -not $rendered.SSHPort) {
+                if (-not $rendered.SSHUser -or -not $rendered.SSHHost) {
                     $identity = $mod.SDK.Settings.Load("book-2-cloud/users/config/identity.config.yaml")
+                    $network = $mod.SDK.Settings.Load("book-2-cloud/network/config/network.config.yaml")
                     if (-not $rendered.SSHUser) { $rendered.SSHUser = $identity.identity.username }
-                    if (-not $rendered.SSHHost) { $rendered.SSHHost = "localhost" }
-                    if (-not $rendered.SSHPort) { $rendered.SSHPort = 2222 }
+                    if (-not $rendered.SSHHost) {
+                        $ip = $network.network.ip_address -replace '/d+$', ''
+                        $rendered.SSHHost = $ip
+                    }
                 }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 2: `book-0-builder/host-sdk/modules/Vbox.ps1` - Remove SSHPort from Configurator.Defaults, let SDK.Network.SSH default to port 22 [COMPLETE]

### book-0-builder.host-sdk.modules.Vbox.remove-sshport-default

> **File**: `book-0-builder/host-sdk/modules/Vbox.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Remove SSHPort from Configurator.Defaults, let SDK.Network.SSH default to port 22

#### Diff

```diff
     $mod.Configurator = @{
         Defaults = @{
             CPUs = 2
             Memory = 4096
             Disk = 40960
             SSHUser = $null
             SSHHost = $null
-            SSHPort = $null
         }
     }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 1 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 3: `book-0-builder/config/build_layers.yaml` - Add layers 16-18 for Package Security testing extensions (6.8-updates, 6.8-summary, 6.8-flush) [COMPLETE]

### book-0-builder.config.build_layers.add-testing-layers

> **File**: `book-0-builder/config/build_layers.yaml`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add layers 16-18 for Package Security testing extensions (6.8-updates, 6.8-summary, 6.8-flush)

#### Diff

```diff
   14: OpenCode
   15: UI Touches
+  16: Package Manager Updates
+  17: Update Summary
+  18: Notification Flush
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 3 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 4a: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add SSH verification method shape with test 6.4.1 (hardening config exists) [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.ssh-shape

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 0 for this file

#### Description

Add SSH verification method shape with test 6.4.1 (hardening config exists)

#### Diff

```diff
+    Add-ScriptMethods $Verifications @{
+        SSH = {
+            param($Worker)
+            # 6.4.1: SSH Hardening Config
+            $result = $Worker.Exec("test -f /etc/ssh/sshd_config.d/99-hardening.conf")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.4.1"; Name = "SSH hardening config exists"
+                Pass = $result.Success
+                Output = "/etc/ssh/sshd_config.d/99-hardening.conf"
+            })
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

### Commit 4b: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add SSH tests 6.4.2-6.4.3: key settings verification, service active check [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.ssh-settings

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add SSH tests 6.4.2-6.4.3: key settings verification, service active check

#### Diff

```diff
+            # 6.4.2: Key Settings
+            $result = $Worker.Exec("sudo grep -r 'PermitRootLogin' /etc/ssh/sshd_config.d/")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.4.2"; Name = "PermitRootLogin no"
+                Pass = ($result.Output -match "PermitRootLogin no")
+                Output = $result.Output
+            })
+            $result = $Worker.Exec("sudo grep -r 'MaxAuthTries' /etc/ssh/sshd_config.d/")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.4.2"; Name = "MaxAuthTries set"
+                Pass = ($result.Output -match "MaxAuthTries")
+                Output = $result.Output
+            })
+            # 6.4.3: SSH Service Running
+            $result = $Worker.Exec("systemctl is-active ssh")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.4.3"; Name = "SSH service active"
+                Pass = ($result.Output -match "^active$")
+                Output = $result.Output
+            })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 20 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 4c: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add SSH test 6.4.4-6.4.5: root login rejected and key auth via Worker.Exec internal SSH [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.ssh-root-login

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add SSH test 6.4.4-6.4.5: root login rejected and key auth via Worker.Exec internal SSH

#### Diff

```diff
+            # 6.4.4: Verify root SSH login rejected (internal test)
+            $result = $Worker.Exec("ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@localhost exit 2>&1; echo exit_code:$?")
+            $rootBlocked = ($result.Output -match "Permission denied" -or $result.Output -match "publickey")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.4.4"; Name = "Root SSH login rejected"
+                Pass = $rootBlocked
+                Output = if ($rootBlocked) { "Root login correctly rejected" } else { $result.Output }
+            })
+            # 6.4.5: Verify SSH key auth works (internal loopback)
+            $identity = $mod.SDK.Settings.Identity
+            $username = $identity.username
+            $result = $Worker.Exec("ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no ${username}@localhost echo OK")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.4.5"; Name = "SSH key auth for $username"
+                Pass = ($result.Success -and $result.Output -match "OK")
+                Output = if ($result.Success) { "Key authentication successful" } else { $result.Output }
+            })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 17 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 5a: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add UFW verification method shape with test 6.5.1 (UFW active) [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.ufw-shape

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 0 for this file

#### Description

Add UFW verification method shape with test 6.5.1 (UFW active)

#### Diff

```diff
+    Add-ScriptMethods $Verifications @{
+        UFW = {
+            param($Worker)
+            $result = $Worker.Exec("sudo ufw status")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.5.1"; Name = "UFW is active"
+                Pass = ($result.Output -match "Status: active")
+                Output = $result.Output | Select-Object -First 1
+            })
+        }
+    }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 11 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 5b: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add UFW tests 6.5.2-6.5.3: SSH allowed, default deny incoming [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.ufw-rules

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add UFW tests 6.5.2-6.5.3: SSH allowed, default deny incoming

#### Diff

```diff
+            $mod.SDK.Testing.Record(@{
+                Test = "6.5.2"; Name = "SSH allowed in UFW"
+                Pass = ($result.Output -match "22.*ALLOW")
+                Output = "Port 22 rule checked"
+            })
+            $verbose = $Worker.Exec("sudo ufw status verbose")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.5.3"; Name = "Default deny incoming"
+                Pass = ($verbose.Output -match "deny (incoming)")
+                Output = "Default incoming policy"
+            })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 11 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 6a: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add System verification method shape with test 6.6.1 (timezone) [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.system-shape

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 0 for this file

#### Description

Add System verification method shape with test 6.6.1 (timezone)

#### Diff

```diff
+    Add-ScriptMethods $Verifications @{
+        System = {
+            param($Worker)
+            $result = $Worker.Exec("timedatectl show --property=Timezone --value")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.6.1"; Name = "Timezone configured"
+                Pass = ($result.Success -and $result.Output)
+                Output = $result.Output
+            })
+        }
+    }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 11 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 6b: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add System tests 6.6.2-6.6.3: locale set, NTP enabled [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.system-locale-ntp

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add System tests 6.6.2-6.6.3: locale set, NTP enabled

#### Diff

```diff
+            $result = $Worker.Exec("locale")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.6.2"; Name = "Locale set"
+                Pass = ($result.Output -match "LANG=")
+                Output = ($result.Output | Select-Object -First 1)
+            })
+            $result = $Worker.Exec("timedatectl show --property=NTP --value")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.6.3"; Name = "NTP enabled"
+                Pass = ($result.Output -match "yes")
+                Output = "NTP=$($result.Output)"
+            })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 12 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 7a: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add SecurityMonitoring method shape with test 6.9.1 (fail2ban installed) [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.secmon-shape

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 0 for this file

#### Description

Add SecurityMonitoring method shape with test 6.9.1 (fail2ban installed)

#### Diff

```diff
+    Add-ScriptMethods $Verifications @{
+        SecurityMonitoring = {
+            param($Worker)
+            $result = $Worker.Exec("which fail2ban-client")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.9.1"; Name = "fail2ban installed"
+                Pass = ($result.Success -and $result.Output -match "fail2ban")
+                Output = $result.Output
+            })
+        }
+    }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 11 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 7b: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add SecurityMonitoring tests 6.9.2-6.9.3: service active, SSH jail [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.secmon-service-jail

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add SecurityMonitoring tests 6.9.2-6.9.3: service active, SSH jail

#### Diff

```diff
+            $result = $Worker.Exec("sudo systemctl is-active fail2ban")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.9.2"; Name = "fail2ban service active"
+                Pass = ($result.Output -match "^active$")
+                Output = $result.Output
+            })
+            $result = $Worker.Exec("sudo fail2ban-client status")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.9.3"; Name = "SSH jail configured"
+                Pass = ($result.Output -match "sshd")
+                Output = "sshd jail"
+            })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 12 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 8: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add UI verification method (6.15.1-6.15.2): MOTD directory exists, scripts present [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.add-ui-method

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add UI verification method (6.15.1-6.15.2): MOTD directory exists, scripts present

#### Diff

```diff
+    Add-ScriptMethods $Verifications @{
+        UI = {
+            param($Worker)
+            $result = $Worker.Exec("test -d /etc/update-motd.d")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.15.1"; Name = "MOTD directory exists"
+                Pass = $result.Success
+                Output = "/etc/update-motd.d"
+            })
+            $result = $Worker.Exec("ls /etc/update-motd.d/ | wc -l")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.15.2"; Name = "MOTD scripts present"
+                Pass = ([int]$result.Output -gt 0)
+                Output = "$($result.Output) scripts"
+            })
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

