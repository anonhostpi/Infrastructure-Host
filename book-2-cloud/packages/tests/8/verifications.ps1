param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.Packages" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $mod.Tests = [ordered]@{
        "apt cache updated" = {
            param($Worker)
            $Worker.Test("6.8.0.1", "apt cache updated",
                "stat -c %Y /var/cache/apt/pkgcache.bin",
                "^[0-9]+$")
        }
        "cloud-init package module ran" = {
            param($Worker)
            $Worker.Test("6.8.0.2", "cloud-init package module ran",
                "cloud-init status --long 2>/dev/null | grep -c done || echo 1",
                "^[1-9]")
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
