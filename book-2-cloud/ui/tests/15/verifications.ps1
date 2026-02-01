param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.UITouches" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $mod.Tests = [ordered]@{
        "MOTD directory exists" = {
            param($Worker)
            $result = $Worker.Exec("test -d /etc/update-motd.d")
            $mod.SDK.Testing.Record(@{
                Test = "6.15.1"; Name = "MOTD directory exists"
                Pass = $result.Success; Output = "/etc/update-motd.d"
            })
        }
        "MOTD scripts present" = {
            param($Worker)
            $result = $Worker.Exec("ls /etc/update-motd.d/ | wc -l")
            $mod.SDK.Testing.Record(@{
                Test = "6.15.2"; Name = "MOTD scripts present"
                Pass = ([int]$result.Output -gt 0); Output = "$($result.Output) scripts"
            })
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
