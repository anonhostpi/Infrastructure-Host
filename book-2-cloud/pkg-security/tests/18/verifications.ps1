param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.NotificationFlush" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $mod.Tests = [ordered]@{
        "apt-notify-flush logged" = {
            param($Worker)
            $result = $Worker.Exec("grep 'apt-notify-flush: complete' /var/lib/apt-notify/apt-notify.log")
            $mod.SDK.Testing.Record(@{
                Test = "6.8.28"; Name = "apt-notify-flush logged"
                Pass = ($result.Success -and $result.Output -match "apt-notify-flush")
                Output = if ($result.Success) { "Flush logged" } else { "No flush log entry" }
            })
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
