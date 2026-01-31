param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.SystemSettings" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $SDK.Testing.Verifications.Register("system", 6, [ordered]@{})
} -ArgumentList $SDK
