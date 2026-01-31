param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.OpenCode" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $username = $SDK.Settings.Identity.username

    $SDK.Testing.Verifications.Register("opencode", 14, [ordered]@{
        "Node.js installed" = { param($Worker) }
        "npm installed" = { param($Worker) }
        "OpenCode installed" = { param($Worker) }
        "OpenCode config directory" = { param($Worker) }
        "OpenCode auth file" = { param($Worker) }
        "OpenCode AI response" = { param($Worker) }
        "OpenCode credential chain" = { param($Worker) }
    })
} -ArgumentList $SDK
