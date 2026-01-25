param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.AutoinstallBuild -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $AutoinstallBuild = New-Object PSObject

    # Methods added in following commits

    $SDK.Extend("AutoinstallBuild", $AutoinstallBuild)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
