param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.Cockpit" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $SDK.Testing.Verifications.Register("cockpit", 11, [ordered]@{
        "Cockpit installed" = { param($Worker) }
        "Cockpit socket enabled" = { param($Worker) }
        "cockpit-machines installed" = { param($Worker) }
        "Cockpit listening on port" = { param($Worker) }
        "Cockpit web UI responds" = { param($Worker) }
        "Cockpit login page" = { param($Worker) }
        "Cockpit restricted to localhost" = { param($Worker) }
    })
} -ArgumentList $SDK
