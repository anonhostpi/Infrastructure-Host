param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.UITouches" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $mod.Tests = [ordered]@{
        "MOTD directory exists" = {
            param($Worker)
            $Worker.Test("6.15.1", "MOTD directory exists", "test -d /etc/update-motd.d", { $true })
        }
        "MOTD scripts present" = {
            param($Worker)
            $Worker.Test("6.15.2", "MOTD scripts present", "ls /etc/update-motd.d/ | wc -l", { param($out) [int]$out -gt 0 })
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
