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
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
