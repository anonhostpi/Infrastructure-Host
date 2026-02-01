param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.NotificationFlush" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $mod.Tests = [ordered]@{
        "apt-notify-flush logged" = {
            param($Worker)
            $Worker.Test("6.8.28", "apt-notify-flush logged", "grep 'apt-notify-flush: complete' /var/lib/apt-notify/apt-notify.log", "apt-notify-flush")
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
