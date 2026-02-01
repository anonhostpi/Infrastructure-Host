param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.PackageSecurity" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $mod.Tests = [ordered]@{
        "unattended-upgrades installed" = {
            param($Worker)
            $Worker.Test("6.8.1", "unattended-upgrades installed", "dpkg -l unattended-upgrades", "ii.*unattended-upgrades")
        }
        "Unattended upgrades config" = {
            param($Worker)
            $Worker.Test("6.8.2", "Unattended upgrades config", "test -f /etc/apt/apt.conf.d/50unattended-upgrades", { $true })
        }
        "Auto-upgrades configured" = {
            param($Worker)
            $Worker.Test("6.8.3", "Auto-upgrades configured", "cat /etc/apt/apt.conf.d/20auto-upgrades", 'Unattended-Upgrade.*"1"')
        }
        "Service enabled" = {
            param($Worker)
            $Worker.Test("6.8.4", "Service enabled", "systemctl is-enabled unattended-upgrades", "enabled")
        }
        "apt-listchanges installed" = {
            param($Worker)
            $Worker.Test("6.8.5", "apt-listchanges installed", "dpkg -l apt-listchanges", "ii.*apt-listchanges")
        }
        "apt-listchanges email config" = {
            param($Worker)
            $Worker.Test("6.8.6", "apt-listchanges email config", "cat /etc/apt/listchanges.conf", "frontend=mail")
        }
        "apt-notify script exists" = {
            param($Worker)
            $result = $Worker.Exec("test -x /usr/local/bin/apt-notify")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.7"; Name = "apt-notify script exists"
                Pass = $result.Success; Output = "/usr/local/bin/apt-notify"
            })
        }
        "dpkg notification hooks" = {
            param($Worker)
            $result = $Worker.Exec("cat /etc/apt/apt.conf.d/90pkg-notify")
            $hookOk = ($result.Output -match "DPkg::Pre-Invoke" -and $result.Output -match "DPkg::Post-Invoke")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.8"; Name = "dpkg notification hooks"
                Pass = $hookOk; Output = "Pre/Post-Invoke hooks configured"
            })
        }
        "Verbose upgrade reporting" = {
            param($Worker)
            $uuConf = $Worker.Exec("cat /etc/apt/apt.conf.d/50unattended-upgrades").Output
            $mod.SDK.Testing.Record(@{
                Test = "6.8.9"; Name = "Verbose upgrade reporting"
                Pass = (($uuConf -match 'Verbose.*"true"') -and ($uuConf -match 'MailReport.*"always"'))
                Output = "Verbose=true, MailReport=always"
            })
        }
        "snap-update script" = {
            param($Worker)
            $result = $Worker.Exec("test -x /usr/local/bin/snap-update && echo exists")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.10"; Name = "snap-update script"
                Pass = ($result.Output -match "exists"); Output = "/usr/local/bin/snap-update"
            })
        }
        "snap refresh.hold configured" = {
            param($Worker)
            $result = $Worker.Exec("sudo snap get system refresh.hold 2>/dev/null || echo not-set")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.11"; Name = "snap refresh.hold configured"
                Pass = ($result.Output -match "forever" -or $result.Output -match "20[0-9]{2}")
                Output = "refresh.hold=$($result.Output)"
            })
        }
        "brew-update script" = {
            param($Worker)
            $result = $Worker.Exec("test -x /usr/local/bin/brew-update && echo exists")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.12"; Name = "brew-update script"
                Pass = ($result.Output -match "exists"); Output = "/usr/local/bin/brew-update"
            })
        }
        "pip-global-update script" = {
            param($Worker)
            $result = $Worker.Exec("test -x /usr/local/bin/pip-global-update && echo exists")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.13"; Name = "pip-global-update script"
                Pass = ($result.Output -match "exists"); Output = "/usr/local/bin/pip-global-update"
            })
        }
        "npm-global-update script" = {
            param($Worker)
            $result = $Worker.Exec("test -x /usr/local/bin/npm-global-update && echo exists")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.14"; Name = "npm-global-update script"
                Pass = ($result.Output -match "exists"); Output = "/usr/local/bin/npm-global-update"
            })
        }
        "deno-update script" = {
            param($Worker)
            $result = $Worker.Exec("test -x /usr/local/bin/deno-update && echo exists")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.15"; Name = "deno-update script"
                Pass = ($result.Output -match "exists"); Output = "/usr/local/bin/deno-update"
            })
        }
        "pkg-managers-update timer" = {
            param($Worker)
            $enabled = $Worker.Exec("systemctl is-enabled pkg-managers-update.timer 2>/dev/null")
            $active = $Worker.Exec("systemctl is-active pkg-managers-update.timer 2>/dev/null")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.16"; Name = "pkg-managers-update timer"
                Pass = ($enabled.Output -match "enabled") -and ($active.Output -match "active")
                Output = "enabled=$($enabled.Output), active=$($active.Output)"
            })
        }
        "apt-notify common library" = {
            param($Worker)
            $result = $Worker.Exec("test -f /usr/local/lib/apt-notify/common.sh && echo exists")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.17"; Name = "apt-notify common library"
                Pass = ($result.Output -match "exists"); Output = "/usr/local/lib/apt-notify/common.sh"
            })
        }
        "apt-notify-flush script" = {
            param($Worker)
            $result = $Worker.Exec("test -x /usr/local/bin/apt-notify-flush && echo exists")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.18"; Name = "apt-notify-flush script"
                Pass = ($result.Output -match "exists"); Output = "/usr/local/bin/apt-notify-flush"
            })
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
