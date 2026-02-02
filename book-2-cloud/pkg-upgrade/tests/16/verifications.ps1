param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.PackageUpgrade" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $mod.Tests = [ordered]@{
        # WIP
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
