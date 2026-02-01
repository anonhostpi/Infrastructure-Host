param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.HyperV -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"
    Import-Module Hyper-V

    $HyperV = New-Object PSObject

    $SDK.Extend("HyperV", $HyperV)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
