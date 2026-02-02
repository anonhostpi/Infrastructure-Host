param(
    [Parameter(Mandatory = $true)]
    $SDK
)

New-Module -Name SDK.CloudInit -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }

    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $CloudInit = New-Object PSObject

    $SDK.Extend("CloudInit", $CloudInit)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
