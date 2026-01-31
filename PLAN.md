# Plan


### Commit 1: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add MSMTP method shape with test 6.7.1 (msmtp installed) [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.msmtp-shape

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add MSMTP method shape with test 6.7.1 (msmtp installed)

#### Diff

```diff
+    Add-ScriptMethods $Verifications @{
+        MSMTP = {
+            param($Worker)
+            # 6.7.1: msmtp installed
+            $result = $Worker.Exec("which msmtp")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.7.1"; Name = "msmtp installed"
+                Pass = ($result.Success -and $result.Output -match "msmtp")
+                Output = $result.Output
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

### Commit 2: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add MSMTP tests 6.7.2-6.7.3: config exists, sendmail alias [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.msmtp-basic

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add MSMTP tests 6.7.2-6.7.3: config exists, sendmail alias

#### Diff

```diff
+            # 6.7.2: msmtp config exists
+            $result = $Worker.Exec("test -f /etc/msmtprc")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.7.2"; Name = "msmtp config exists"
+                Pass = $result.Success
+                Output = "/etc/msmtprc"
+            })
+            # 6.7.3: sendmail alias
+            $result = $Worker.Exec("test -L /usr/sbin/sendmail")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.7.3"; Name = "sendmail alias exists"
+                Pass = $result.Success
+                Output = "/usr/sbin/sendmail"
+            })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 14 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 3: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add SMTP config gate + read msmtprc + 6.7.4 host/port checks [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.msmtp-config-gate

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add SMTP config gate + read msmtprc + 6.7.4 host/port checks

#### Diff

```diff
+            # SMTP config gate
+            $smtp = $mod.SDK.Settings.SMTP
+            if (-not $smtp -or -not $smtp.host) {
+                $this.Fork("6.7.4-6.7.11", "SKIP", "No SMTP configured")
+                return
+            }
+            $msmtprc = $Worker.Exec("sudo cat /etc/msmtprc").Output
+            # 6.7.4: Config values match SDK.Settings.SMTP
+            $mod.SDK.Testing.Record(@{
+                Test = "6.7.4"; Name = "SMTP host matches"
+                Pass = ($msmtprc -match "hosts+$([regex]::Escape($smtp.host))")
+                Output = "Expected: $($smtp.host)"
+            })
+            $mod.SDK.Testing.Record(@{
+                Test = "6.7.4"; Name = "SMTP port matches"
+                Pass = ($msmtprc -match "ports+$($smtp.port)")
+                Output = "Expected: $($smtp.port)"
+            })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 18 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 4: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add MSMTP 6.7.4 from_email/user config checks [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.msmtp-config-from-user

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add MSMTP 6.7.4 from_email/user config checks

#### Diff

```diff
+            $mod.SDK.Testing.Record(@{
+                Test = "6.7.4"; Name = "SMTP from matches"
+                Pass = ($msmtprc -match "froms+$([regex]::Escape($smtp.from_email))")
+                Output = "Expected: $($smtp.from_email)"
+            })
+            $mod.SDK.Testing.Record(@{
+                Test = "6.7.4"; Name = "SMTP user matches"
+                Pass = ($msmtprc -match "users+$([regex]::Escape($smtp.user))")
+                Output = "Expected: $($smtp.user)"
+            })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 10 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 5: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add MSMTP 6.7.5 provider name resolution + test shape with placeholder [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.msmtp-provider-shape

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add MSMTP 6.7.5 provider name resolution + test shape with placeholder

#### Diff

```diff
+            # 6.7.5: Provider-specific validation
+            $providerName = switch -Regex ($smtp.host) {
+                'smtp.sendgrid.net' { 'SendGrid'; break }
+                'email-smtp..+.amazonaws.com' { 'AWS SES'; break }
+                'smtp.gmail.com' { 'Gmail'; break }
+                '^localhost$|^127.' { 'Proton Bridge'; break }
+                'smtp.office365.com' { 'M365'; break }
+                default { 'Generic' }
+            }
+            $providerPass = $true # WIP
+            $mod.SDK.Testing.Record(@{
+                Test = "6.7.5"; Name = "Provider config valid ($providerName)"
+                Pass = $providerPass
+                Output = "Provider: $providerName"
+            })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 15 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 6: `book-0-builder/host-sdk/modules/Verifications.ps1` - Implement MSMTP 6.7.5 provider validation switch [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.msmtp-provider-impl

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Implement MSMTP 6.7.5 provider validation switch

#### Diff

```diff
-            $providerPass = $true # WIP
+            $providerPass = switch ($providerName) {
+                'SendGrid' { $msmtprc -match 'users+apikey' }
+                'AWS SES' { $smtp.port -in @(587, 465) }
+                'Gmail' { $msmtprc -match 'passwordeval' }
+                'Proton Bridge' { $msmtprc -match 'tls_certchecks+off' }
+                'M365' { $smtp.port -eq 587 }
+                default { $true }
+            }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 9 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 7: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add MSMTP 6.7.6 auth method validation [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.msmtp-auth

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add MSMTP 6.7.6 auth method validation

#### Diff

```diff
+            # 6.7.6: Auth method validation
+            $authMethod = if ($msmtprc -match 'auths+(S+)') { $matches[1] } else { 'on' }
+            $validAuth = @('on', 'plain', 'login', 'xoauth2', 'oauthbearer', 'external')
+            $authPass = $authMethod -in $validAuth
+            if ($authMethod -in @('xoauth2', 'oauthbearer')) {
+                $authPass = $authPass -and ($msmtprc -match 'passwordeval')
+            }
+            $mod.SDK.Testing.Record(@{
+                Test = "6.7.6"; Name = "Auth method valid"
+                Pass = $authPass
+                Output = "auth=$authMethod"
+            })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 12 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 8: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add MSMTP 6.7.7-6.7.8 TLS settings and credential config checks [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.msmtp-tls-creds

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add MSMTP 6.7.7-6.7.8 TLS settings and credential config checks

#### Diff

```diff
+            # 6.7.7: TLS settings valid
+            $tlsOn = ($msmtprc -match 'tlss+on')
+            $implicitTls = ($smtp.port -eq 465 -and ($msmtprc -match 'tls_starttlss+off'))
+            $mod.SDK.Testing.Record(@{
+                Test = "6.7.7"; Name = "TLS settings valid"
+                Pass = ($tlsOn -or $implicitTls)
+                Output = "tls=on, implicit=$implicitTls"
+            })
+            # 6.7.8: Credential config valid
+            $hasCreds = ($msmtprc -match 'passwords') -or ($msmtprc -match 'passwordeval')
+            if (-not $hasCreds) {
+                $hasCreds = $Worker.Exec("sudo test -f /etc/msmtp-password").Success
+            }
+            $mod.SDK.Testing.Record(@{
+                Test = "6.7.8"; Name = "Credential config valid"
+                Pass = $hasCreds
+                Output = if ($hasCreds) { "Credentials configured" } else { "No credentials found" }
+            })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 18 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 9: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add MSMTP 6.7.9-6.7.10 root alias and msmtp-config helper [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.msmtp-alias-helper

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add MSMTP 6.7.9-6.7.10 root alias and msmtp-config helper

#### Diff

```diff
+            # 6.7.9: Root alias configured
+            $aliases = $Worker.Exec("cat /etc/aliases").Output
+            $aliasPass = ($aliases -match "root:")
+            if ($smtp.recipient) { $aliasPass = $aliasPass -and ($aliases -match [regex]::Escape($smtp.recipient)) }
+            $mod.SDK.Testing.Record(@{
+                Test = "6.7.9"; Name = "Root alias configured"
+                Pass = $aliasPass
+                Output = "Root alias in /etc/aliases"
+            })
+            # 6.7.10: msmtp-config helper
+            $result = $Worker.Exec("test -x /usr/local/bin/msmtp-config")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.7.10"; Name = "msmtp-config helper exists"
+                Pass = $result.Success
+                Output = "/usr/local/bin/msmtp-config"
+            })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 16 lines | BORDERLINE |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 10: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add MSMTP 6.7.11 conditional test email send [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.msmtp-test-email

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add MSMTP 6.7.11 conditional test email send

#### Diff

```diff
+            # 6.7.11: Send test email (conditional)
+            $hasInline = ($msmtprc -match 'passwords+S' -and $msmtprc -notmatch 'passwordeval')
+            if (-not $hasInline -or -not $smtp.recipient) {
+                $this.Fork("6.7.11", "SKIP", "No inline password or recipient")
+            } else {
+                $subject = "Infrastructure-Host Verification Test"
+                $result = $Worker.Exec("echo -e 'Subject: $subject

Automated test.' | sudo msmtp '$($smtp.recipient)'")
+                $logCheck = $Worker.Exec("sudo tail -1 /var/log/msmtp.log")
+                $mod.SDK.Testing.Record(@{
+                    Test = "6.7.11"; Name = "Test email sent"
+                    Pass = ($result.Success -and $logCheck.Output -match $smtp.recipient)
+                    Output = if ($result.Success) { "Email sent" } else { $result.Output }
+                })
+            }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 14 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 11: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add PackageSecurity method shape with test 6.8.1 (unattended-upgrades) [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.pkgsec-shape

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add PackageSecurity method shape with test 6.8.1 (unattended-upgrades)

#### Diff

```diff
+    Add-ScriptMethods $Verifications @{
+        PackageSecurity = {
+            param($Worker)
+            # 6.8.1: unattended-upgrades installed
+            $result = $Worker.Exec("dpkg -l unattended-upgrades")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.8.1"; Name = "unattended-upgrades installed"
+                Pass = ($result.Output -match "ii.*unattended-upgrades")
+                Output = "Package installed"
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

### Commit 12a: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add PackageSecurity 6.8.2-6.8.3: config exists, auto-upgrades [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.pkgsec-config-auto

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 0 for this file

#### Description

Add PackageSecurity 6.8.2-6.8.3: config exists, auto-upgrades

#### Diff

```diff
+            # 6.8.2: Config exists
+            $result = $Worker.Exec("test -f /etc/apt/apt.conf.d/50unattended-upgrades")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.8.2"; Name = "Unattended upgrades config"
+                Pass = $result.Success
+                Output = "/etc/apt/apt.conf.d/50unattended-upgrades"
+            })
+            # 6.8.3: Auto-upgrades enabled
+            $result = $Worker.Exec("cat /etc/apt/apt.conf.d/20auto-upgrades")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.8.3"; Name = "Auto-upgrades configured"
+                Pass = ($result.Output -match 'Unattended-Upgrade.*"1"')
+                Output = "Auto-upgrade enabled"
+            })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 14 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 12b: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add PackageSecurity 6.8.4-6.8.5: service enabled, apt-listchanges [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.pkgsec-service-listchanges

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 0 for this file

#### Description

Add PackageSecurity 6.8.4-6.8.5: service enabled, apt-listchanges

#### Diff

```diff
+            # 6.8.4: Service enabled
+            $result = $Worker.Exec("systemctl is-enabled unattended-upgrades")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.8.4"; Name = "Service enabled"
+                Pass = ($result.Output -match "enabled")
+                Output = $result.Output
+            })
+            # 6.8.5: apt-listchanges installed
+            $result = $Worker.Exec("dpkg -l apt-listchanges")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.8.5"; Name = "apt-listchanges installed"
+                Pass = ($result.Output -match "ii.*apt-listchanges")
+                Output = "Package installed"
+            })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 14 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 12c: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add PackageSecurity 6.8.6-6.8.7: listchanges email config, apt-notify script [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.pkgsec-listchanges-notify

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add PackageSecurity 6.8.6-6.8.7: listchanges email config, apt-notify script

#### Diff

```diff
+            # 6.8.6: apt-listchanges email config
+            $result = $Worker.Exec("cat /etc/apt/listchanges.conf")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.8.6"; Name = "apt-listchanges email config"
+                Pass = ($result.Output -match "frontend=mail")
+                Output = "Changelogs sent via email"
+            })
+            # 6.8.7: apt-notify script exists
+            $result = $Worker.Exec("test -x /usr/local/bin/apt-notify")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.8.7"; Name = "apt-notify script exists"
+                Pass = $result.Success
+                Output = "/usr/local/bin/apt-notify"
+            })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 14 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 13: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add PackageSecurity 6.8.8-6.8.9: dpkg hooks, verbose reporting [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.pkgsec-hooks-verbose

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add PackageSecurity 6.8.8-6.8.9: dpkg hooks, verbose reporting

#### Diff

```diff
+            # 6.8.8: dpkg hooks configured
+            $result = $Worker.Exec("cat /etc/apt/apt.conf.d/90pkg-notify")
+            $hookOk = ($result.Output -match "DPkg::Pre-Invoke" -and $result.Output -match "DPkg::Post-Invoke")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.8.8"; Name = "dpkg notification hooks"
+                Pass = $hookOk
+                Output = "Pre/Post-Invoke hooks configured"
+            })
+            # 6.8.9: Verbose unattended-upgrades reporting
+            $uuConf = $Worker.Exec("cat /etc/apt/apt.conf.d/50unattended-upgrades").Output
+            $mod.SDK.Testing.Record(@{
+                Test = "6.8.9"; Name = "Verbose upgrade reporting"
+                Pass = (($uuConf -match 'Verbose.*"true"') -and ($uuConf -match 'MailReport.*"always"'))
+                Output = "Verbose=true, MailReport=always"
+            })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 15 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 14a: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add PackageSecurity 6.8.10-6.8.11: snap-update, snap refresh.hold [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.pkgsec-snap

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 0 for this file

#### Description

Add PackageSecurity 6.8.10-6.8.11: snap-update, snap refresh.hold

#### Diff

```diff
+            # 6.8.10: snap-update script
+            $result = $Worker.Exec("test -x /usr/local/bin/snap-update && echo exists")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.8.10"; Name = "snap-update script"
+                Pass = ($result.Output -match "exists")
+                Output = "/usr/local/bin/snap-update"
+            })
+            # 6.8.11: snap refresh.hold configured
+            $result = $Worker.Exec("sudo snap get system refresh.hold 2>/dev/null || echo not-set")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.8.11"; Name = "snap refresh.hold configured"
+                Pass = ($result.Output -match "forever" -or $result.Output -match "20[0-9]{2}")
+                Output = "refresh.hold=$($result.Output)"
+            })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 14 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 14b: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add PackageSecurity 6.8.12-6.8.13: brew-update, pip-global-update [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.pkgsec-brew-pip

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 0 for this file

#### Description

Add PackageSecurity 6.8.12-6.8.13: brew-update, pip-global-update

#### Diff

```diff
+            # 6.8.12: brew-update script
+            $result = $Worker.Exec("test -x /usr/local/bin/brew-update && echo exists")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.8.12"; Name = "brew-update script"
+                Pass = ($result.Output -match "exists")
+                Output = "/usr/local/bin/brew-update"
+            })
+            # 6.8.13: pip-global-update script
+            $result = $Worker.Exec("test -x /usr/local/bin/pip-global-update && echo exists")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.8.13"; Name = "pip-global-update script"
+                Pass = ($result.Output -match "exists")
+                Output = "/usr/local/bin/pip-global-update"
+            })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 14 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 14c: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add PackageSecurity 6.8.14-6.8.15: npm-global-update, deno-update [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.pkgsec-npm-deno

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add PackageSecurity 6.8.14-6.8.15: npm-global-update, deno-update

#### Diff

```diff
+            # 6.8.14: npm-global-update script
+            $result = $Worker.Exec("test -x /usr/local/bin/npm-global-update && echo exists")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.8.14"; Name = "npm-global-update script"
+                Pass = ($result.Output -match "exists")
+                Output = "/usr/local/bin/npm-global-update"
+            })
+            # 6.8.15: deno-update script
+            $result = $Worker.Exec("test -x /usr/local/bin/deno-update && echo exists")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.8.15"; Name = "deno-update script"
+                Pass = ($result.Output -match "exists")
+                Output = "/usr/local/bin/deno-update"
+            })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 14 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 15: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add PackageSecurity 6.8.16-6.8.17: systemd timer, common library [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.pkgsec-timer-common

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add PackageSecurity 6.8.16-6.8.17: systemd timer, common library

#### Diff

```diff
+            # 6.8.16: pkg-managers-update timer
+            $enabled = $Worker.Exec("systemctl is-enabled pkg-managers-update.timer 2>/dev/null")
+            $active = $Worker.Exec("systemctl is-active pkg-managers-update.timer 2>/dev/null")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.8.16"; Name = "pkg-managers-update timer"
+                Pass = ($enabled.Output -match "enabled") -and ($active.Output -match "active")
+                Output = "enabled=$($enabled.Output), active=$($active.Output)"
+            })
+            # 6.8.17: apt-notify common library
+            $result = $Worker.Exec("test -f /usr/local/lib/apt-notify/common.sh && echo exists")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.8.17"; Name = "apt-notify common library"
+                Pass = ($result.Output -match "exists")
+                Output = "/usr/local/lib/apt-notify/common.sh"
+            })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 15 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 16: `book-0-builder/host-sdk/modules/Verifications.ps1` - Add PackageSecurity 6.8.18: apt-notify-flush script [COMPLETE]

### book-0-builder.host-sdk.modules.Verifications.pkgsec-flush

> **File**: `book-0-builder/host-sdk/modules/Verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add PackageSecurity 6.8.18: apt-notify-flush script

#### Diff

```diff
+            # 6.8.18: apt-notify-flush script
+            $result = $Worker.Exec("test -x /usr/local/bin/apt-notify-flush && echo exists")
+            $mod.SDK.Testing.Record(@{
+                Test = "6.8.18"; Name = "apt-notify-flush script"
+                Pass = ($result.Output -match "exists")
+                Output = "/usr/local/bin/apt-notify-flush"
+            })
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 7 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |
