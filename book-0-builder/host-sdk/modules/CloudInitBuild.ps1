param(
    [Parameter(Mandatory = $true)]
    $SDK
)

New-Module -Name SDK.CloudInitBuild -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }

    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $CloudInitBuild = New-Object PSObject

    # Methods added in following commits

    $SDK.Extend("CloudInitBuild", $CloudInitBuild)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
