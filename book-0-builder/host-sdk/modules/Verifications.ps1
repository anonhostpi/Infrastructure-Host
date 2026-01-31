param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.Testing.Verifications -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $Verifications = New-Object PSObject

    $SDK.Extend("Verifications", $Verifications, $SDK.Testing)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
