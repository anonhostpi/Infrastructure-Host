param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.PackageUpgrade" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $mod.Tests = [ordered]@{
        "apt cache cleaned" = {
            param($Worker)
            $Worker.Test("pkg-upgrade.1", "apt cache cleaned",
                "ls /var/cache/apt/archives/*.deb 2>/dev/null | wc -l",
                "^0$")
        }
        "upgrade logged" = {
            param($Worker)
            $Worker.Test("pkg-upgrade.2", "upgrade logged",
                "grep -c 'System upgrade complete' /var/log/cloud-init-output.log",
                "^[1-9]")
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
