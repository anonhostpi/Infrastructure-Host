param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.CopilotCLI" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $username = $SDK.Settings.Identity.username

    $SDK.Testing.Verifications.Register("copilot-cli", 13, [ordered]@{
        "Copilot CLI installed" = { param($Worker) }
        "Copilot CLI config directory" = { param($Worker) }
        "Copilot CLI config file" = { param($Worker) }
        "Copilot CLI auth configured" = { param($Worker) }
        "Copilot CLI AI response" = { param($Worker) }
    })
} -ArgumentList $SDK
