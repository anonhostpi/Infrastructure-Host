param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.Base" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $mod.Tests = [ordered]@{
        "SSH reachable" = {
            param($Worker)
            $result = $Worker.Exec("echo ok")
            $mod.SDK.Testing.Record(@{
                Test = "0.1"; Name = "SSH reachable"
                Pass = $result.Success; Output = $result.Output
            })
        }
        "OS version correct" = {
            param($Worker)
            $result = $Worker.Exec("lsb_release -cs")
            $mod.SDK.Testing.Record(@{
                Test = "0.2"; Name = "OS version correct"
                Pass = ($result.Success -and $result.Output); Output = $result.Output
            })
        }
        "Root filesystem is ext4" = {
            param($Worker)
            $result = $Worker.Exec("findmnt -n -o FSTYPE /")
            $mod.SDK.Testing.Record(@{
                Test = "0.3"; Name = "Root filesystem is ext4"
                Pass = ($result.Output -match "ext4"); Output = $result.Output
            })
        }
        "Default user exists" = {
            param($Worker)
            $result = $Worker.Exec("id -un")
            $mod.SDK.Testing.Record(@{
                Test = "0.4"; Name = "Default user exists"
                Pass = ($result.Success -and $result.Output); Output = $result.Output
            })
        }
        "Hostname set" = {
            param($Worker)
            $result = $Worker.Exec("hostname -s")
            $mod.SDK.Testing.Record(@{
                Test = "0.5"; Name = "Hostname set"
                Pass = ($result.Success -and $result.Output -and $result.Output -ne "localhost")
                Output = $result.Output
            })
        }
        "SSH service active" = {
            param($Worker)
            $result = $Worker.Exec("systemctl is-active ssh")
            $mod.SDK.Testing.Record(@{
                Test = "0.6"; Name = "SSH service active"
                Pass = ($result.Output -match "active"); Output = $result.Output
            })
        }
        "Cloud-init finished" = {
            param($Worker)
            $result = $Worker.Exec("cloud-init status")
            $mod.SDK.Testing.Record(@{
                Test = "0.7"; Name = "Cloud-init finished"
                Pass = ($result.Output -match "done"); Output = $result.Output
            })
        }
        "No cloud-init errors" = {
            param($Worker)
            $result = $Worker.Exec("cloud-init status")
            $mod.SDK.Testing.Record(@{
                Test = "0.8"; Name = "No cloud-init errors"
                Pass = ($result.Output -notmatch "error|degraded"); Output = $result.Output
            })
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
