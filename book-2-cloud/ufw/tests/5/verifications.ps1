param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.UFWFirewall" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    return @{}
} -ArgumentList $SDK
