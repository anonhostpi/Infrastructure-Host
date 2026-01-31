param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.CopilotCLI" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $SDK.Testing.Verifications.Register("copilot-cli", 13, [ordered]@{})
} -ArgumentList $SDK
