param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.SystemSettings" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $mod.Tests = [ordered]@{
        "Timezone configured" = {
            param($Worker)
            $Worker.Test("6.6.1", "Timezone configured", "timedatectl show --property=Timezone --value", ".")
        }
        "Locale set" = {
            param($Worker)
            $Worker.Test("6.6.2", "Locale set", "locale", "LANG=")
        }
        "NTP enabled" = {
            param($Worker)
            $Worker.Test("6.6.3", "NTP enabled", "timedatectl show --property=NTP --value", "yes")
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
