param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.Users" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $username = $SDK.Settings.Identity.username

    $SDK.Testing.Verifications.Register("users", 3, [ordered]@{
        "user exists" = {
            param($Worker)
            $result = $Worker.Exec("id $username")
            $SDK.Testing.Record(@{
                Test = "6.3.1"; Name = "$username user exists"
                Pass = ($result.Success -and $result.Output -match "uid="); Output = $result.Output
            })
        }
        "user shell is bash" = {
            param($Worker)
            $result = $Worker.Exec("getent passwd $username | cut -d: -f7")
            $SDK.Testing.Record(@{
                Test = "6.3.1"; Name = "$username shell is bash"
                Pass = ($result.Output -match "/bin/bash"); Output = $result.Output
            })
        }
        "user in sudo group" = { param($Worker) }
        "Sudoers file exists" = { param($Worker) }
        "Root account locked" = { param($Worker) }
    })
} -ArgumentList $SDK
