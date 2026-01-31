param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.Testing.Verifications -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $Verifications = New-Object PSObject

    Add-ScriptMethods $Verifications @{
        Fork = {
            param([string]$Test, [string]$Decision, [string]$Reason = "")
            $msg = "[FORK] $Test : $Decision"
            if ($Reason) { $msg += " ($Reason)" }
            $mod.SDK.Log.Debug($msg)
        }
    }

    Add-ScriptMethods $Verifications @{
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
    }

    Add-ScriptMethods $Verifications @{
        Network = {
            param($Worker)
            # 6.1.1: Hostname Configuration
            $result = $Worker.Exec("hostname -s")
            $mod.SDK.Testing.Record(@{
                Test = "6.1.1"; Name = "Short hostname set"
                Pass = ($result.Success -and $result.Output -and $result.Output -ne "localhost")
                Output = $result.Output
            })

            $result = $Worker.Exec("hostname -f")
            $mod.SDK.Testing.Record(@{
                Test = "6.1.1"; Name = "FQDN has domain"
                Pass = ($result.Output -match "\.")
                Output = $result.Output
            })

            # 6.1.2: /etc/hosts Management
            $result = $Worker.Exec("grep '127.0.1.1' /etc/hosts")
            $mod.SDK.Testing.Record(@{
                Test = "6.1.2"; Name = "Hostname in /etc/hosts"
                Pass = ($result.Success -and $result.Output)
                Output = $result.Output
            })

            # 6.1.3: Netplan Configuration
            $result = $Worker.Exec("ls /etc/netplan/*.yaml 2>/dev/null")
            $mod.SDK.Testing.Record(@{
                Test = "6.1.3"; Name = "Netplan config exists"
                Pass = ($result.Success -and $result.Output)
                Output = $result.Output
            })

            # 6.1.4: Network Connectivity
            $result = $Worker.Exec("ip -4 addr show scope global | grep 'inet '")
            $mod.SDK.Testing.Record(@{
                Test = "6.1.4"; Name = "IP address assigned"
                Pass = ($result.Output -match "inet ")
                Output = $result.Output
            })

            $result = $Worker.Exec("ip route | grep '^default'")
            $mod.SDK.Testing.Record(@{
                Test = "6.1.4"; Name = "Default gateway configured"
                Pass = ($result.Output -match "default via")
                Output = $result.Output
            })

            $result = $Worker.Exec("host -W 2 ubuntu.com")
            $mod.SDK.Testing.Record(@{
                Test = "6.1.4"; Name = "DNS resolution works"
                Pass = ($result.Output -match "has address" -or $result.Output -match "has IPv")
                Output = $result.Output
            })

            # 6.1.5: net-setup.sh execution log
            $result = $Worker.Exec("test -f /var/lib/cloud/scripts/net-setup/net-setup.log")
            $mod.SDK.Testing.Record(@{
                Test = "6.1.5"; Name = "net-setup.log exists"
                Pass = $result.Success
                Output = "/var/lib/cloud/scripts/net-setup/net-setup.log"
            })

            $result = $Worker.Exec("cat /var/lib/cloud/scripts/net-setup/net-setup.log")
            $mod.SDK.Testing.Record(@{
                Test = "6.1.5"; Name = "net-setup.sh executed"
                Pass = ($result.Output -match "net-setup:")
                Output = if ($result.Output) { ($result.Output | Select-Object -First 3) -join "; " } else { "(empty)" }
            })
        }
    }

    Add-ScriptMethods $Verifications @{
        Kernel = {
            param($Worker)
            # 6.2.1: Sysctl Security Config
            $result = $Worker.Exec("test -f /etc/sysctl.d/99-security.conf")
            $mod.SDK.Testing.Record(@{
                Test = "6.2.1"; Name = "Security sysctl config exists"
                Pass = $result.Success
                Output = "/etc/sysctl.d/99-security.conf"
            })

            # 6.2.2: Key security settings applied
            $result = $Worker.Exec("sysctl net.ipv4.conf.all.rp_filter")
            $mod.SDK.Testing.Record(@{
                Test = "6.2.2"; Name = "Reverse path filtering enabled"
                Pass = ($result.Output -match "= 1")
                Output = $result.Output
            })

            $result = $Worker.Exec("sysctl net.ipv4.tcp_syncookies")
            $mod.SDK.Testing.Record(@{
                Test = "6.2.2"; Name = "SYN cookies enabled"
                Pass = ($result.Output -match "= 1")
                Output = $result.Output
            })

            $result = $Worker.Exec("sysctl net.ipv4.conf.all.accept_redirects")
            $mod.SDK.Testing.Record(@{
                Test = "6.2.2"; Name = "ICMP redirects disabled"
                Pass = ($result.Output -match "= 0")
                Output = $result.Output
            })
        }
    }

    Add-ScriptMethods $Verifications @{
        Users = {
            param($Worker)
            $identity = $mod.SDK.Settings.Identity
            $username = $identity.username

            # 6.3.1: User Exists
            $result = $Worker.Exec("id $username")
            $mod.SDK.Testing.Record(@{
                Test = "6.3.1"; Name = "$username user exists"
                Pass = ($result.Success -and $result.Output -match "uid=")
                Output = $result.Output
            })

            $result = $Worker.Exec("getent passwd $username | cut -d: -f7")
            $mod.SDK.Testing.Record(@{
                Test = "6.3.1"; Name = "$username shell is bash"
                Pass = ($result.Output -match "/bin/bash")
                Output = $result.Output
            })

            # 6.3.2: Group Membership
            $result = $Worker.Exec("groups $username")
            $mod.SDK.Testing.Record(@{
                Test = "6.3.2"; Name = "$username in sudo group"
                Pass = ($result.Output -match "\bsudo\b")
                Output = $result.Output
            })

            # 6.3.3: Sudo Configuration
            $result = $Worker.Exec("sudo test -f /etc/sudoers.d/$username")
            $mod.SDK.Testing.Record(@{
                Test = "6.3.3"; Name = "Sudoers file exists"
                Pass = $result.Success
                Output = "/etc/sudoers.d/$username"
            })

            # 6.3.4: Root Disabled
            $result = $Worker.Exec("sudo passwd -S root")
            $mod.SDK.Testing.Record(@{
                Test = "6.3.4"; Name = "Root account locked"
                Pass = ($result.Output -match "root L" -or $result.Output -match "root LK")
                Output = $result.Output
            })
        }
    }

    Add-ScriptMethods $Verifications @{
        SSH = {
            param($Worker)
            # 6.4.1: SSH Hardening Config
            $result = $Worker.Exec("test -f /etc/ssh/sshd_config.d/99-hardening.conf")
            $mod.SDK.Testing.Record(@{
                Test = "6.4.1"; Name = "SSH hardening config exists"
                Pass = $result.Success
                Output = "/etc/ssh/sshd_config.d/99-hardening.conf"
            })
            # 6.4.2: Key Settings
            $result = $Worker.Exec("sudo grep -r 'PermitRootLogin' /etc/ssh/sshd_config.d/")
            $mod.SDK.Testing.Record(@{
                Test = "6.4.2"; Name = "PermitRootLogin no"
                Pass = ($result.Output -match "PermitRootLogin no")
                Output = $result.Output
            })
            $result = $Worker.Exec("sudo grep -r 'MaxAuthTries' /etc/ssh/sshd_config.d/")
            $mod.SDK.Testing.Record(@{
                Test = "6.4.2"; Name = "MaxAuthTries set"
                Pass = ($result.Output -match "MaxAuthTries")
                Output = $result.Output
            })
            # 6.4.3: SSH Service Running
            $result = $Worker.Exec("systemctl is-active ssh")
            $mod.SDK.Testing.Record(@{
                Test = "6.4.3"; Name = "SSH service active"
                Pass = ($result.Output -match "^active$")
                Output = $result.Output
            })
            # 6.4.4: Verify root SSH login rejected (internal test)
            $result = $Worker.Exec("ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@localhost exit 2>&1; echo exit_code:`$?")
            $rootBlocked = ($result.Output -match "Permission denied" -or $result.Output -match "publickey")
            $mod.SDK.Testing.Record(@{
                Test = "6.4.4"; Name = "Root SSH login rejected"
                Pass = $rootBlocked
                Output = if ($rootBlocked) { "Root login correctly rejected" } else { $result.Output }
            })
            # 6.4.5: Verify SSH key auth works (internal loopback)
            $identity = $mod.SDK.Settings.Identity
            $username = $identity.username
            $result = $Worker.Exec("ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no ${username}@localhost echo OK")
            $mod.SDK.Testing.Record(@{
                Test = "6.4.5"; Name = "SSH key auth for $username"
                Pass = ($result.Success -and $result.Output -match "OK")
                Output = if ($result.Success) { "Key authentication successful" } else { $result.Output }
            })
        }
    }

    Add-ScriptMethods $Verifications @{
        UFW = {
            param($Worker)
            $result = $Worker.Exec("sudo ufw status")
            $mod.SDK.Testing.Record(@{
                Test = "6.5.1"; Name = "UFW is active"
                Pass = ($result.Output -match "Status: active")
                Output = $result.Output | Select-Object -First 1
            })
            $mod.SDK.Testing.Record(@{
                Test = "6.5.2"; Name = "SSH allowed in UFW"
                Pass = ($result.Output -match "22.*ALLOW")
                Output = "Port 22 rule checked"
            })
            $verbose = $Worker.Exec("sudo ufw status verbose")
            $mod.SDK.Testing.Record(@{
                Test = "6.5.3"; Name = "Default deny incoming"
                Pass = ($verbose.Output -match "deny \(incoming\)")
                Output = "Default incoming policy"
            })
        }
    }

    Add-ScriptMethods $Verifications @{
        System = {
            param($Worker)
            $result = $Worker.Exec("timedatectl show --property=Timezone --value")
            $mod.SDK.Testing.Record(@{
                Test = "6.6.1"; Name = "Timezone configured"
                Pass = ($result.Success -and $result.Output)
                Output = $result.Output
            })
            $result = $Worker.Exec("locale")
            $mod.SDK.Testing.Record(@{
                Test = "6.6.2"; Name = "Locale set"
                Pass = ($result.Output -match "LANG=")
                Output = ($result.Output | Select-Object -First 1)
            })
            $result = $Worker.Exec("timedatectl show --property=NTP --value")
            $mod.SDK.Testing.Record(@{
                Test = "6.6.3"; Name = "NTP enabled"
                Pass = ($result.Output -match "yes")
                Output = "NTP=$($result.Output)"
            })
        }
    }

    Add-ScriptMethods $Verifications @{
        SecurityMonitoring = {
            param($Worker)
            $result = $Worker.Exec("which fail2ban-client")
            $mod.SDK.Testing.Record(@{
                Test = "6.9.1"; Name = "fail2ban installed"
                Pass = ($result.Success -and $result.Output -match "fail2ban")
                Output = $result.Output
            })
            $result = $Worker.Exec("sudo systemctl is-active fail2ban")
            $mod.SDK.Testing.Record(@{
                Test = "6.9.2"; Name = "fail2ban service active"
                Pass = ($result.Output -match "^active$")
                Output = $result.Output
            })
            $result = $Worker.Exec("sudo fail2ban-client status")
            $mod.SDK.Testing.Record(@{
                Test = "6.9.3"; Name = "SSH jail configured"
                Pass = ($result.Output -match "sshd")
                Output = "sshd jail"
            })
        }
    }

    Add-ScriptMethods $Verifications @{
        MSMTP = {
            param($Worker)
            # 6.7.1: msmtp installed
            $result = $Worker.Exec("which msmtp")
            $mod.SDK.Testing.Record(@{
                Test = "6.7.1"; Name = "msmtp installed"
                Pass = ($result.Success -and $result.Output -match "msmtp")
                Output = $result.Output
            })
            # 6.7.2: msmtp config exists
            $result = $Worker.Exec("test -f /etc/msmtprc")
            $mod.SDK.Testing.Record(@{
                Test = "6.7.2"; Name = "msmtp config exists"
                Pass = $result.Success
                Output = "/etc/msmtprc"
            })
            # 6.7.3: sendmail alias
            $result = $Worker.Exec("test -L /usr/sbin/sendmail")
            $mod.SDK.Testing.Record(@{
                Test = "6.7.3"; Name = "sendmail alias exists"
                Pass = $result.Success
                Output = "/usr/sbin/sendmail"
            })
            # SMTP config gate
            $smtp = $mod.SDK.Settings.SMTP
            if (-not $smtp -or -not $smtp.host) {
                $this.Fork("6.7.4-6.7.11", "SKIP", "No SMTP configured")
                return
            }
            $msmtprc = $Worker.Exec("sudo cat /etc/msmtprc").Output
            # 6.7.4: Config values match SDK.Settings.SMTP
            $mod.SDK.Testing.Record(@{
                Test = "6.7.4"; Name = "SMTP host matches"
                Pass = ($msmtprc -match "host\s+$([regex]::Escape($smtp.host))")
                Output = "Expected: $($smtp.host)"
            })
            $mod.SDK.Testing.Record(@{
                Test = "6.7.4"; Name = "SMTP port matches"
                Pass = ($msmtprc -match "port\s+$($smtp.port)")
                Output = "Expected: $($smtp.port)"
            })
            $mod.SDK.Testing.Record(@{
                Test = "6.7.4"; Name = "SMTP from matches"
                Pass = ($msmtprc -match "from\s+$([regex]::Escape($smtp.from_email))")
                Output = "Expected: $($smtp.from_email)"
            })
            $mod.SDK.Testing.Record(@{
                Test = "6.7.4"; Name = "SMTP user matches"
                Pass = ($msmtprc -match "user\s+$([regex]::Escape($smtp.user))")
                Output = "Expected: $($smtp.user)"
            })
            # 6.7.5: Provider-specific validation
            $providerName = switch -Regex ($smtp.host) {
                'smtp\.sendgrid\.net' { 'SendGrid'; break }
                'email-smtp\..+\.amazonaws\.com' { 'AWS SES'; break }
                'smtp\.gmail\.com' { 'Gmail'; break }
                '^localhost$|^127\.' { 'Proton Bridge'; break }
                'smtp\.office365\.com' { 'M365'; break }
                default { 'Generic' }
            }
            $providerPass = switch ($providerName) {
                'SendGrid' { $msmtprc -match 'user\s+apikey' }
                'AWS SES' { $smtp.port -in @(587, 465) }
                'Gmail' { $msmtprc -match 'passwordeval' }
                'Proton Bridge' { $msmtprc -match 'tls_certcheck\s+off' }
                'M365' { $smtp.port -eq 587 }
                default { $true }
            }
            $mod.SDK.Testing.Record(@{
                Test = "6.7.5"; Name = "Provider config valid ($providerName)"
                Pass = $providerPass
                Output = "Provider: $providerName"
            })
            # 6.7.6: Auth method validation
            $authMethod = if ($msmtprc -match 'auth\s+(\S+)') { $matches[1] } else { 'on' }
            $validAuth = @('on', 'plain', 'login', 'xoauth2', 'oauthbearer', 'external')
            $authPass = $authMethod -in $validAuth
            if ($authMethod -in @('xoauth2', 'oauthbearer')) {
                $authPass = $authPass -and ($msmtprc -match 'passwordeval')
            }
            $mod.SDK.Testing.Record(@{
                Test = "6.7.6"; Name = "Auth method valid"
                Pass = $authPass
                Output = "auth=$authMethod"
            })
            # 6.7.7: TLS settings valid
            $tlsOn = ($msmtprc -match 'tls\s+on')
            $implicitTls = ($smtp.port -eq 465 -and ($msmtprc -match 'tls_starttls\s+off'))
            $mod.SDK.Testing.Record(@{
                Test = "6.7.7"; Name = "TLS settings valid"
                Pass = ($tlsOn -or $implicitTls)
                Output = "tls=on, implicit=$implicitTls"
            })
            # 6.7.8: Credential config valid
            $hasCreds = ($msmtprc -match 'password\s') -or ($msmtprc -match 'passwordeval')
            if (-not $hasCreds) {
                $hasCreds = $Worker.Exec("sudo test -f /etc/msmtp-password").Success
            }
            $mod.SDK.Testing.Record(@{
                Test = "6.7.8"; Name = "Credential config valid"
                Pass = $hasCreds
                Output = if ($hasCreds) { "Credentials configured" } else { "No credentials found" }
            })
            # 6.7.9: Root alias configured
            $aliases = $Worker.Exec("cat /etc/aliases").Output
            $aliasPass = ($aliases -match "root:")
            if ($smtp.recipient) { $aliasPass = $aliasPass -and ($aliases -match [regex]::Escape($smtp.recipient)) }
            $mod.SDK.Testing.Record(@{
                Test = "6.7.9"; Name = "Root alias configured"
                Pass = $aliasPass
                Output = "Root alias in /etc/aliases"
            })
            # 6.7.10: msmtp-config helper
            $result = $Worker.Exec("test -x /usr/local/bin/msmtp-config")
            $mod.SDK.Testing.Record(@{
                Test = "6.7.10"; Name = "msmtp-config helper exists"
                Pass = $result.Success
                Output = "/usr/local/bin/msmtp-config"
            })
            # 6.7.11: Send test email (conditional)
            $hasInline = ($msmtprc -match 'password\s+\S' -and $msmtprc -notmatch 'passwordeval')
            if (-not $hasInline -or -not $smtp.recipient) {
                $this.Fork("6.7.11", "SKIP", "No inline password or recipient")
            } else {
                $subject = "Infrastructure-Host Verification Test"
                $result = $Worker.Exec("echo -e 'Subject: $subject\n\nAutomated test.' | sudo msmtp '$($smtp.recipient)'")
                $logCheck = $Worker.Exec("sudo tail -1 /var/log/msmtp.log")
                $mod.SDK.Testing.Record(@{
                    Test = "6.7.11"; Name = "Test email sent"
                    Pass = ($result.Success -and $logCheck.Output -match $smtp.recipient)
                    Output = if ($result.Success) { "Email sent" } else { $result.Output }
                })
            }
        }
    }

    Add-ScriptMethods $Verifications @{
        PackageSecurity = {
            param($Worker)
            # 6.8.1: unattended-upgrades installed
            $result = $Worker.Exec("dpkg -l unattended-upgrades")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.1"; Name = "unattended-upgrades installed"
                Pass = ($result.Output -match "ii.*unattended-upgrades")
                Output = "Package installed"
            })
            # 6.8.2: Config exists
            $result = $Worker.Exec("test -f /etc/apt/apt.conf.d/50unattended-upgrades")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.2"; Name = "Unattended upgrades config"
                Pass = $result.Success
                Output = "/etc/apt/apt.conf.d/50unattended-upgrades"
            })
            # 6.8.3: Auto-upgrades enabled
            $result = $Worker.Exec("cat /etc/apt/apt.conf.d/20auto-upgrades")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.3"; Name = "Auto-upgrades configured"
                Pass = ($result.Output -match 'Unattended-Upgrade.*"1"')
                Output = "Auto-upgrade enabled"
            })
            # 6.8.4: Service enabled
            $result = $Worker.Exec("systemctl is-enabled unattended-upgrades")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.4"; Name = "Service enabled"
                Pass = ($result.Output -match "enabled")
                Output = $result.Output
            })
            # 6.8.5: apt-listchanges installed
            $result = $Worker.Exec("dpkg -l apt-listchanges")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.5"; Name = "apt-listchanges installed"
                Pass = ($result.Output -match "ii.*apt-listchanges")
                Output = "Package installed"
            })
            # 6.8.6: apt-listchanges email config
            $result = $Worker.Exec("cat /etc/apt/listchanges.conf")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.6"; Name = "apt-listchanges email config"
                Pass = ($result.Output -match "frontend=mail")
                Output = "Changelogs sent via email"
            })
            # 6.8.7: apt-notify script exists
            $result = $Worker.Exec("test -x /usr/local/bin/apt-notify")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.7"; Name = "apt-notify script exists"
                Pass = $result.Success
                Output = "/usr/local/bin/apt-notify"
            })
            # 6.8.8: dpkg hooks configured
            $result = $Worker.Exec("cat /etc/apt/apt.conf.d/90pkg-notify")
            $hookOk = ($result.Output -match "DPkg::Pre-Invoke" -and $result.Output -match "DPkg::Post-Invoke")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.8"; Name = "dpkg notification hooks"
                Pass = $hookOk
                Output = "Pre/Post-Invoke hooks configured"
            })
            # 6.8.9: Verbose unattended-upgrades reporting
            $uuConf = $Worker.Exec("cat /etc/apt/apt.conf.d/50unattended-upgrades").Output
            $mod.SDK.Testing.Record(@{
                Test = "6.8.9"; Name = "Verbose upgrade reporting"
                Pass = (($uuConf -match 'Verbose.*"true"') -and ($uuConf -match 'MailReport.*"always"'))
                Output = "Verbose=true, MailReport=always"
            })
            # 6.8.10: snap-update script
            $result = $Worker.Exec("test -x /usr/local/bin/snap-update && echo exists")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.10"; Name = "snap-update script"
                Pass = ($result.Output -match "exists")
                Output = "/usr/local/bin/snap-update"
            })
            # 6.8.11: snap refresh.hold configured
            $result = $Worker.Exec("sudo snap get system refresh.hold 2>/dev/null || echo not-set")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.11"; Name = "snap refresh.hold configured"
                Pass = ($result.Output -match "forever" -or $result.Output -match "20[0-9]{2}")
                Output = "refresh.hold=$($result.Output)"
            })
            # 6.8.12: brew-update script
            $result = $Worker.Exec("test -x /usr/local/bin/brew-update && echo exists")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.12"; Name = "brew-update script"
                Pass = ($result.Output -match "exists")
                Output = "/usr/local/bin/brew-update"
            })
            # 6.8.13: pip-global-update script
            $result = $Worker.Exec("test -x /usr/local/bin/pip-global-update && echo exists")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.13"; Name = "pip-global-update script"
                Pass = ($result.Output -match "exists")
                Output = "/usr/local/bin/pip-global-update"
            })
            # 6.8.14: npm-global-update script
            $result = $Worker.Exec("test -x /usr/local/bin/npm-global-update && echo exists")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.14"; Name = "npm-global-update script"
                Pass = ($result.Output -match "exists")
                Output = "/usr/local/bin/npm-global-update"
            })
            # 6.8.15: deno-update script
            $result = $Worker.Exec("test -x /usr/local/bin/deno-update && echo exists")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.15"; Name = "deno-update script"
                Pass = ($result.Output -match "exists")
                Output = "/usr/local/bin/deno-update"
            })
            # 6.8.16: pkg-managers-update timer
            $enabled = $Worker.Exec("systemctl is-enabled pkg-managers-update.timer 2>/dev/null")
            $active = $Worker.Exec("systemctl is-active pkg-managers-update.timer 2>/dev/null")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.16"; Name = "pkg-managers-update timer"
                Pass = ($enabled.Output -match "enabled") -and ($active.Output -match "active")
                Output = "enabled=$($enabled.Output), active=$($active.Output)"
            })
            # 6.8.17: apt-notify common library
            $result = $Worker.Exec("test -f /usr/local/lib/apt-notify/common.sh && echo exists")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.17"; Name = "apt-notify common library"
                Pass = ($result.Output -match "exists")
                Output = "/usr/local/lib/apt-notify/common.sh"
            })
            # 6.8.18: apt-notify-flush script
            $result = $Worker.Exec("test -x /usr/local/bin/apt-notify-flush && echo exists")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.18"; Name = "apt-notify-flush script"
                Pass = ($result.Output -match "exists")
                Output = "/usr/local/bin/apt-notify-flush"
            })
        }
    }

    Add-ScriptMethods $Verifications @{
        Virtualization = {
            param($Worker)
            # 6.10.1: libvirt installed
            $result = $Worker.Exec("which virsh")
            $mod.SDK.Testing.Record(@{
                Test = "6.10.1"; Name = "libvirt installed"
                Pass = ($result.Success -and $result.Output -match "virsh")
                Output = $result.Output
            })
            # 6.10.2: libvirtd service active
            $result = $Worker.Exec("systemctl is-active libvirtd")
            $mod.SDK.Testing.Record(@{
                Test = "6.10.2"; Name = "libvirtd service active"
                Pass = ($result.Output -match "^active$")
                Output = $result.Output
            })
            # 6.10.3: QEMU installed
            $result = $Worker.Exec("which qemu-system-x86_64")
            $mod.SDK.Testing.Record(@{
                Test = "6.10.3"; Name = "QEMU installed"
                Pass = ($result.Success -and $result.Output -match "qemu")
                Output = $result.Output
            })
            # 6.10.4: libvirt default network
            $result = $Worker.Exec("sudo virsh net-list --all")
            $mod.SDK.Testing.Record(@{
                Test = "6.10.4"; Name = "libvirt default network"
                Pass = ($result.Output -match "default")
                Output = $result.Output
            })
            # 6.10.5: multipass installed (nested)
            $result = $Worker.Exec("which multipass")
            $mod.SDK.Testing.Record(@{
                Test = "6.10.5"; Name = "multipass installed"
                Pass = ($result.Success -and $result.Output -match "multipass")
                Output = $result.Output
            })
            # 6.10.6: multipassd service active
            $result = $Worker.Exec("systemctl is-active snap.multipass.multipassd.service")
            $mod.SDK.Testing.Record(@{
                Test = "6.10.6"; Name = "multipassd service active"
                Pass = ($result.Output -match "^active$")
                Output = $result.Output
            })
            # 6.10.7: KVM available
            $result = $Worker.Exec("test -e /dev/kvm && echo available")
            $kvmAvailable = ($result.Output -match "available")
            $mod.SDK.Testing.Record(@{
                Test = "6.10.7"; Name = "KVM available for nesting"
                Pass = $kvmAvailable
                Output = if ($kvmAvailable) { "/dev/kvm present" } else { "KVM not available" }
            })
            # 6.10.8-6.10.9: Nested VM test (conditional on KVM)
            if (-not $kvmAvailable) {
                $this.Fork("6.10.8-6.10.9", "SKIP", "KVM not available")
            } else {
                $launch = $Worker.Exec("multipass launch --name nested-test-vm --cpus 1 --memory 512M --disk 2G 2>&1; echo exit_code:`$?")
                $mod.SDK.Testing.Record(@{
                    Test = "6.10.8"; Name = "Launch nested VM"
                    Pass = ($launch.Output -match "exit_code:0")
                    Output = if ($launch.Output -match "exit_code:0") { "nested-test-vm launched" } else { $launch.Output }
                })
                $exec = $Worker.Exec("multipass exec nested-test-vm -- echo nested-ok")
                $mod.SDK.Testing.Record(@{
                    Test = "6.10.9"; Name = "Exec in nested VM"
                    Pass = ($exec.Output -match "nested-ok")
                    Output = $exec.Output
                })
                $Worker.Exec("multipass delete nested-test-vm --purge") | Out-Null
            }
        }
    }

    Add-ScriptMethods $Verifications @{
        Cockpit = {
            param($Worker)
            # 6.11.1: cockpit-bridge installed
            $result = $Worker.Exec("which cockpit-bridge")
            $mod.SDK.Testing.Record(@{
                Test = "6.11.1"; Name = "Cockpit installed"
                Pass = ($result.Success -and $result.Output -match "cockpit")
                Output = $result.Output
            })
            # 6.11.2: cockpit.socket enabled
            $result = $Worker.Exec("systemctl is-enabled cockpit.socket")
            $mod.SDK.Testing.Record(@{
                Test = "6.11.2"; Name = "Cockpit socket enabled"
                Pass = ($result.Output -match "enabled")
                Output = $result.Output
            })
            # 6.11.3: cockpit-machines installed
            $result = $Worker.Exec("dpkg -l cockpit-machines")
            $mod.SDK.Testing.Record(@{
                Test = "6.11.3"; Name = "cockpit-machines installed"
                Pass = ($result.Output -match "ii.*cockpit-machines")
                Output = "Package installed"
            })
            # 6.11.4: Cockpit socket listening
            $portConf = $Worker.Exec("cat /etc/systemd/system/cockpit.socket.d/listen.conf 2>/dev/null").Output
            $port = if ($portConf -match 'ListenStream=(\d+)') { $matches[1] } else { "9090" }
            $Worker.Exec("curl -sk https://localhost:$port/ > /dev/null 2>&1") | Out-Null
            $result = $Worker.Exec("ss -tlnp | grep :$port")
            $mod.SDK.Testing.Record(@{
                Test = "6.11.4"; Name = "Cockpit listening on port $port"
                Pass = ($result.Output -match ":$port")
                Output = $result.Output
            })
            # 6.11.5: Cockpit web UI responds
            $result = $Worker.Exec("curl -sk -o /dev/null -w '%{http_code}' https://localhost:$port/")
            $mod.SDK.Testing.Record(@{
                Test = "6.11.5"; Name = "Cockpit web UI responds"
                Pass = ($result.Output -match "200")
                Output = "HTTP $($result.Output)"
            })
            # 6.11.6: Cockpit login page content
            $result = $Worker.Exec("curl -sk https://localhost:$port/ | grep -E 'login.js|login.css'")
            $mod.SDK.Testing.Record(@{
                Test = "6.11.6"; Name = "Cockpit login page"
                Pass = ($result.Success -and $result.Output)
                Output = "Login page served"
            })
            # 6.11.7: Cockpit listen address restricted
            $restricted = ($portConf -match "127\.0\.0\.1" -or $portConf -match "::1" -or $portConf -match "localhost")
            $mod.SDK.Testing.Record(@{
                Test = "6.11.7"; Name = "Cockpit restricted to localhost"
                Pass = $restricted
                Output = if ($restricted) { "Listen restricted" } else { "Warning: may be externally accessible" }
            })
        }
    }

    Add-ScriptMethods $Verifications @{
        ClaudeCode = {
            param($Worker)
            $username = $mod.SDK.Settings.Identity.username
            # 6.12.1: Claude Code installed
            $result = $Worker.Exec("which claude")
            $mod.SDK.Testing.Record(@{
                Test = "6.12.1"; Name = "Claude Code installed"
                Pass = ($result.Success -and $result.Output -match "claude")
                Output = $result.Output
            })
            # 6.12.2: config directory
            $result = $Worker.Exec("sudo test -d /home/$username/.claude && echo exists")
            $mod.SDK.Testing.Record(@{
                Test = "6.12.2"; Name = "Claude Code config directory"
                Pass = ($result.Output -match "exists")
                Output = "/home/$username/.claude"
            })
            # 6.12.3: settings file
            $result = $Worker.Exec("sudo test -f /home/$username/.claude/settings.json && echo exists")
            $mod.SDK.Testing.Record(@{
                Test = "6.12.3"; Name = "Claude Code settings file"
                Pass = ($result.Output -match "exists")
                Output = "/home/$username/.claude/settings.json"
            })
            # 6.12.4: Auth configuration (fail if no auth)
            $hasAuth = $false; $authOutput = "No auth found"
            $cred = $Worker.Exec("sudo test -f /home/$username/.claude/.credentials.json && echo exists")
            $state = $Worker.Exec("sudo grep -q 'hasCompletedOnboarding' /home/$username/.claude.json 2>/dev/null && echo exists")
            if ($cred.Output -match "exists" -and $state.Output -match "exists") {
                $hasAuth = $true; $authOutput = "OAuth credentials configured"
            } else {
                $env = $Worker.Exec("grep -q 'ANTHROPIC_API_KEY' /etc/environment && echo configured")
                if ($env.Output -match "configured") { $hasAuth = $true; $authOutput = "API Key configured" }
            }
            $mod.SDK.Testing.Record(@{
                Test = "6.12.4"; Name = "Claude Code auth configured"
                Pass = $hasAuth; Output = $authOutput
            })
            # 6.12.5: AI response test (conditional on auth)
            if (-not $hasAuth) {
                $this.Fork("6.12.5", "SKIP", "No auth configured")
            } else {
                $result = $Worker.Exec("sudo -u $username env HOME=/home/$username timeout 30 claude -p test 2>&1")
                $clean = $result.Output -replace '\x1b\[[0-9;]*[a-zA-Z]', ''
                $hasResponse = ($clean -and $clean.Length -gt 0 -and $clean -notmatch "^error|failed|timeout")
                $mod.SDK.Testing.Record(@{
                    Test = "6.12.5"; Name = "Claude Code AI response"
                    Pass = $hasResponse
                    Output = if ($hasResponse) { "Response received" } else { "Failed: $clean" }
                })
            }
        }
    }

    Add-ScriptMethods $Verifications @{
        CopilotCLI = {
            param($Worker)
            $username = $mod.SDK.Settings.Identity.username
            # 6.13.1: Copilot CLI installed
            $result = $Worker.Exec("which copilot")
            $mod.SDK.Testing.Record(@{
                Test = "6.13.1"; Name = "Copilot CLI installed"
                Pass = ($result.Success -and $result.Output -match "copilot")
                Output = $result.Output
            })
            # 6.13.2: config directory
            $result = $Worker.Exec("sudo test -d /home/$username/.copilot && echo exists")
            $mod.SDK.Testing.Record(@{
                Test = "6.13.2"; Name = "Copilot CLI config directory"
                Pass = ($result.Output -match "exists")
                Output = "/home/$username/.copilot"
            })
            # 6.13.3: config file
            $result = $Worker.Exec("sudo test -f /home/$username/.copilot/config.json && echo exists")
            $mod.SDK.Testing.Record(@{
                Test = "6.13.3"; Name = "Copilot CLI config file"
                Pass = ($result.Output -match "exists")
                Output = "/home/$username/.copilot/config.json"
            })
            # 6.13.4: Auth configuration (fail if no auth)
            $hasAuth = $false; $authOutput = "No auth found"
            $tokens = $Worker.Exec("sudo grep -q 'copilot_tokens' /home/$username/.copilot/config.json 2>/dev/null && echo configured")
            if ($tokens.Output -match "configured") {
                $hasAuth = $true; $authOutput = "OAuth tokens in config.json"
            } else {
                $env = $Worker.Exec("grep -q 'GH_TOKEN' /etc/environment && echo configured")
                if ($env.Output -match "configured") { $hasAuth = $true; $authOutput = "GH_TOKEN configured" }
            }
            $mod.SDK.Testing.Record(@{
                Test = "6.13.4"; Name = "Copilot CLI auth configured"
                Pass = $hasAuth; Output = $authOutput
            })
            # 6.13.5: AI response test (conditional on auth)
            if (-not $hasAuth) {
                $this.Fork("6.13.5", "SKIP", "No auth configured")
            } else {
                $result = $Worker.Exec("sudo -u $username env HOME=/home/$username timeout 30 copilot --model gpt-4.1 -p test 2>&1")
                $clean = $result.Output -replace '\x1b\[[0-9;]*[a-zA-Z]', ''
                $hasResponse = ($clean -and $clean.Length -gt 0 -and $clean -notmatch "^error|failed|timeout")
                $mod.SDK.Testing.Record(@{
                    Test = "6.13.5"; Name = "Copilot CLI AI response"
                    Pass = $hasResponse
                    Output = if ($hasResponse) { "Response received" } else { "Failed: $clean" }
                })
            }
        }
    }

    Add-ScriptMethods $Verifications @{
        OpenCode = {
            param($Worker)
            $username = $mod.SDK.Settings.Identity.username
            # 6.14.1: node installed
            $result = $Worker.Exec("which node")
            $mod.SDK.Testing.Record(@{
                Test = "6.14.1"; Name = "Node.js installed"
                Pass = ($result.Success -and $result.Output -match "node")
                Output = $result.Output
            })
        }
    }

    Add-ScriptMethods $Verifications @{
        UI = {
            param($Worker)
            $result = $Worker.Exec("test -d /etc/update-motd.d")
            $mod.SDK.Testing.Record(@{
                Test = "6.15.1"; Name = "MOTD directory exists"
                Pass = $result.Success
                Output = "/etc/update-motd.d"
            })
            $result = $Worker.Exec("ls /etc/update-motd.d/ | wc -l")
            $mod.SDK.Testing.Record(@{
                Test = "6.15.2"; Name = "MOTD scripts present"
                Pass = ([int]$result.Output -gt 0)
                Output = "$($result.Output) scripts"
            })
        }
    }

    $mod.SDK.Extend("Verifications", $Verifications, $mod.SDK.Testing)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
