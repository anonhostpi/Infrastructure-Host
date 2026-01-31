param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.PackageSecurity" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $SDK.Testing.Verifications.Register("pkg-security", 8, [ordered]@{
        "unattended-upgrades installed" = { param($Worker) }
        "Unattended upgrades config" = { param($Worker) }
        "Auto-upgrades configured" = { param($Worker) }
        "Service enabled" = { param($Worker) }
        "apt-listchanges installed" = { param($Worker) }
        "apt-listchanges email config" = { param($Worker) }
        "apt-notify script exists" = { param($Worker) }
        "dpkg notification hooks" = { param($Worker) }
        "Verbose upgrade reporting" = { param($Worker) }
    })
} -ArgumentList $SDK
