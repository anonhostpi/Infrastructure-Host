param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.UITouches" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $mod.Tests = [ordered]@{
        "CLI packages installed" = {
            param($Worker)
            $Worker.Test("6.15.1", "CLI packages installed",
                "dpkg -l bat fd-find jq tree htop ncdu fastfetch 2>&1 | grep -c '^ii'",
                { param($out) [int]$out -ge 7 })
        }
        "MOTD news disabled" = {
            param($Worker)
            $Worker.Test("6.15.2", "MOTD news disabled",
                "grep ENABLED /etc/default/motd-news",
                "ENABLED=0")
        }
        "Custom MOTD scripts present" = {
            param($Worker)
            $Worker.Test("6.15.3", "Custom MOTD scripts present",
                "test -x /etc/update-motd.d/00-header && test -x /etc/update-motd.d/10-sysinfo && test -x /etc/update-motd.d/90-updates && echo ok",
                "ok")
        }
        "Ubuntu default MOTD disabled" = {
            param($Worker)
            $Worker.Test("6.15.4", "Ubuntu default MOTD disabled",
                "test ! -x /etc/update-motd.d/10-help-text && test ! -x /etc/update-motd.d/50-motd-news && echo ok",
                "ok")
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
