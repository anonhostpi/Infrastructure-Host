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
            $Worker.Test("6.8.7", "apt-notify script exists", "test -x /usr/local/bin/apt-notify", { $true })
        }
        "dpkg notification hooks" = {
            param($Worker)
            $Worker.Test("6.8.8", "dpkg notification hooks", "cat /etc/apt/apt.conf.d/90pkg-notify", { param($out)
            ($out -match "DPkg::Pre-Invoke") -and ($out -match "DPkg::Post-Invoke")
            })
        }
        "Verbose upgrade reporting" = {
            param($Worker)
            $Worker.Test("6.8.9", "Verbose upgrade reporting", "cat /etc/apt/apt.conf.d/50unattended-upgrades", { param($out)
            ($out -match 'Verbose.*"true"') -and ($out -match 'MailReport.*"always"')
            })
        }
        "snap-update script" = {
            param($Worker)
            $Worker.Test("6.8.10", "snap-update script", "test -x /usr/local/bin/snap-update && echo exists", "exists")
        }
        "snap refresh.hold configured" = {
            param($Worker)
            $Worker.Test("6.8.11", "snap refresh.hold configured", "sudo snap get system refresh.hold 2>/dev/null || echo not-set", "forever|20[0-9]{2}")
        }
        "brew-update script" = {
            param($Worker)
            $Worker.Test("6.8.12", "brew-update script", "test -x /usr/local/bin/brew-update && echo exists", "exists")
        }
        "pip-global-update script" = {
            param($Worker)
            $Worker.Test("6.8.13", "pip-global-update script", "test -x /usr/local/bin/pip-global-update && echo exists", "exists")
        }
        "npm-global-update script" = {
            param($Worker)
            $Worker.Test("6.8.14", "npm-global-update script", "test -x /usr/local/bin/npm-global-update && echo exists", "exists")
        }
        "deno-update script" = {
            param($Worker)
            $Worker.Test("6.8.15", "deno-update script", "test -x /usr/local/bin/deno-update && echo exists", "exists")
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
