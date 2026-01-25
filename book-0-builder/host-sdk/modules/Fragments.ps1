param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.Fragments -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $Fragments = New-Object PSObject

    # Layers property and methods added in following commits

    $SDK.Extend("Fragments", $Fragments)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
