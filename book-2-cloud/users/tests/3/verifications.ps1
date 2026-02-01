param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.Users" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $username = $mod.SDK.Settings.Identity.username

    $mod.Tests = [ordered]@{
        "user exists" = {
            param($Worker)
            $result = $Worker.Exec("id $username")
            $mod.SDK.Testing.Record(@{
                Test = "6.3.1"; Name = "$username user exists"
                Pass = ($result.Success -and $result.Output -match "uid="); Output = $result.Output
            })
        }
        "user shell is bash" = {
            param($Worker)
            $result = $Worker.Exec("getent passwd $username | cut -d: -f7")
            $mod.SDK.Testing.Record(@{
                Test = "6.3.1"; Name = "$username shell is bash"
                Pass = ($result.Output -match "/bin/bash"); Output = $result.Output
            })
        }
        "user in sudo group" = {
            param($Worker)
            $result = $Worker.Exec("groups $username")
            $mod.SDK.Testing.Record(@{
                Test = "6.3.2"; Name = "$username in sudo group"
                Pass = ($result.Output -match "\bsudo\b"); Output = $result.Output
            })
        }
        "Sudoers file exists" = {
            param($Worker)
            $result = $Worker.Exec("sudo test -f /etc/sudoers.d/$username")
            $mod.SDK.Testing.Record(@{
                Test = "6.3.3"; Name = "Sudoers file exists"
                Pass = $result.Success; Output = "/etc/sudoers.d/$username"
            })
        }
        "Root account locked" = {
            param($Worker)
            $result = $Worker.Exec("sudo passwd -S root")
            $mod.SDK.Testing.Record(@{
                Test = "6.3.4"; Name = "Root account locked"
                Pass = ($result.Output -match "root L" -or $result.Output -match "root LK"); Output = $result.Output
            })
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
