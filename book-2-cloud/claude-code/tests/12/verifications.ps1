param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.ClaudeCode" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $SDK.Testing.Verifications.Register(@{})
} -ArgumentList $SDK
