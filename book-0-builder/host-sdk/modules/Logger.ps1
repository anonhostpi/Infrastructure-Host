param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.Logger -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $Logger = New-Object PSObject -Property @{ Level = "Info"; Path = $null }

    # Methods added in following commits

    $SDK.Extend("Log", $Logger)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
