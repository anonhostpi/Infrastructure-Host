param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.PackageManagerUpdates" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $SDK.Testing.Verifications.Register("pkg-security", 16, [ordered]@{
        "Testing mode enabled" = { param($Worker) }
        "snap-update" = { param($Worker) }
        "npm-global-update" = { param($Worker) }
        "pip-global-update" = { param($Worker) }
        "brew-update" = { param($Worker) }
        "deno-update" = { param($Worker) }
    })
} -ArgumentList $SDK
