param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.SystemSettings" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $mod.Tests = [ordered]@{
        "Timezone configured" = {
            param($Worker)
            $result = $Worker.Exec("timedatectl show --property=Timezone --value")
            $mod.SDK.Testing.Record(@{
                Test = "6.6.1"; Name = "Timezone configured"
                Pass = ($result.Success -and $result.Output); Output = $result.Output
            })
        }
        "Locale set" = {
            param($Worker)
            $result = $Worker.Exec("locale")
            $mod.SDK.Testing.Record(@{
                Test = "6.6.2"; Name = "Locale set"
                Pass = ($result.Output -match "LANG="); Output = ($result.Output | Select-Object -First 1)
            })
        }
        "NTP enabled" = {
            param($Worker)
            $result = $Worker.Exec("timedatectl show --property=NTP --value")
            $mod.SDK.Testing.Record(@{
                Test = "6.6.3"; Name = "NTP enabled"
                Pass = ($result.Output -match "yes"); Output = "NTP=$($result.Output)"
            })
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
