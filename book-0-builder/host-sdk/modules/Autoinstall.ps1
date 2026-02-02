param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.Autoinstall -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $Autoinstall = New-Object PSObject

    $SDK.Extend("Autoinstall", $Autoinstall)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
