param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.AutoinstallTest -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $AutoinstallTest = New-Object PSObject

    # Methods added in following commits

    $SDK.Extend("AutoinstallTest", $AutoinstallTest)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
