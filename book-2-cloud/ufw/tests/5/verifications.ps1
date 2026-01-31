param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.UFWFirewall" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $SDK.Testing.Verifications.Register("ufw", 5, [ordered]@{
        "UFW is active" = {
            param($Worker)
            $result = $Worker.Exec("sudo ufw status")
            $SDK.Testing.Record(@{
                Test = "6.5.1"; Name = "UFW is active"
                Pass = ($result.Output -match "Status: active"); Output = $result.Output | Select-Object -First 1
            })
        }
        "SSH allowed in UFW" = {
            param($Worker)
            $result = $Worker.Exec("sudo ufw status")
            $SDK.Testing.Record(@{
                Test = "6.5.2"; Name = "SSH allowed in UFW"
                Pass = ($result.Output -match "22.*ALLOW"); Output = "Port 22 rule checked"
            })
        }
        "Default deny incoming" = {
            param($Worker)
            $verbose = $Worker.Exec("sudo ufw status verbose")
            $SDK.Testing.Record(@{
                Test = "6.5.3"; Name = "Default deny incoming"
                Pass = ($verbose.Output -match "deny \(incoming\)"); Output = "Default incoming policy"
            })
        }
    })
} -ArgumentList $SDK
