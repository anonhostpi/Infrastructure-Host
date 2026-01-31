param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.SSHHardening" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $username = $SDK.Settings.Identity.username

    $SDK.Testing.Verifications.Register("ssh", 4, [ordered]@{
        "SSH hardening config exists" = { param($Worker) }
        "PermitRootLogin no" = { param($Worker) }
        "MaxAuthTries set" = { param($Worker) }
        "SSH service active" = { param($Worker) }
        "Root SSH login rejected" = { param($Worker) }
        "SSH key auth" = { param($Worker) }
    })
} -ArgumentList $SDK
