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
        }
    }

    $SDK.Testing | Add-Member -MemberType NoteProperty -Name Verifications -Value $Verifications
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
