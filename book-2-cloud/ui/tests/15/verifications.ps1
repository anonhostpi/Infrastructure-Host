param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.UITouches" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $SDK.Testing.Verifications.Register("ui", 15, [ordered]@{
        "MOTD directory exists" = {
            param($Worker)
            $result = $Worker.Exec("test -d /etc/update-motd.d")
            $SDK.Testing.Record(@{
                Test = "6.15.1"; Name = "MOTD directory exists"
                Pass = $result.Success; Output = "/etc/update-motd.d"
            })
        }
        "MOTD scripts present" = {
            param($Worker)
            $result = $Worker.Exec("ls /etc/update-motd.d/ | wc -l")
            $SDK.Testing.Record(@{
                Test = "6.15.2"; Name = "MOTD scripts present"
                Pass = ([int]$result.Output -gt 0); Output = "$($result.Output) scripts"
            })
        }
    })
} -ArgumentList $SDK
