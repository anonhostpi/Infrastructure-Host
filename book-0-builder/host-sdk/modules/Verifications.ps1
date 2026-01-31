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
        }
    }

    $mod.SDK.Extend("Verifications", $Verifications, $mod.SDK.Testing)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
