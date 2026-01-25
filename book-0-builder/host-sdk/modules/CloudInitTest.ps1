param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.CloudInitTest -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $CloudInitTest = New-Object PSObject

    # Methods added in following commit

    $SDK.Extend("CloudInitTest", $CloudInitTest)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
