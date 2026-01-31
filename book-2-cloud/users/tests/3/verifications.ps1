param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.Users" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $username = $SDK.Settings.Identity.username

    $SDK.Testing.Verifications.Register("users", 3, [ordered]@{
        "user exists" = { param($Worker) }
        "user shell is bash" = { param($Worker) }
        "user in sudo group" = { param($Worker) }
        "Sudoers file exists" = { param($Worker) }
        "Root account locked" = { param($Worker) }
    })
} -ArgumentList $SDK
