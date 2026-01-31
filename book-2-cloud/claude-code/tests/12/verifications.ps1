param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.ClaudeCode" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $username = $SDK.Settings.Identity.username

    $SDK.Testing.Verifications.Register("claude-code", 12, [ordered]@{
        "Claude Code installed" = { param($Worker) }
        "Claude Code config directory" = { param($Worker) }
        "Claude Code settings file" = { param($Worker) }
        "Claude Code auth configured" = { param($Worker) }
        "Claude Code AI response" = { param($Worker) }
    })
} -ArgumentList $SDK
