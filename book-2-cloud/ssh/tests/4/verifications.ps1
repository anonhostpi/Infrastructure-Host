param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.SSHHardening" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $username = $mod.SDK.Settings.Identity.username

    $mod.Tests = [ordered]@{
        "SSH hardening config exists" = {
            param($Worker)
            $Worker.Test("6.4.1", "SSH hardening config exists", "test -f /etc/ssh/sshd_config.d/99-hardening.conf", { $true })
        }
        "PermitRootLogin no" = {
            param($Worker)
            $Worker.Test("6.4.2", "PermitRootLogin no", "sudo grep -r 'PermitRootLogin' /etc/ssh/sshd_config.d/", "PermitRootLogin no")
        }
        "MaxAuthTries set" = {
            param($Worker)
            $Worker.Test("6.4.2", "MaxAuthTries set", "sudo grep -r 'MaxAuthTries' /etc/ssh/sshd_config.d/", "MaxAuthTries")
        }
        "SSH service active" = {
            param($Worker)
            $result = $Worker.Exec("systemctl is-active ssh")
            $mod.SDK.Testing.Record(@{
                Test = "6.4.3"; Name = "SSH service active"
                Pass = ($result.Output -match "^active$"); Output = $result.Output
            })
        }
        "Root SSH login rejected" = {
            param($Worker)
            $result = $Worker.Exec("ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@localhost exit 2>&1; echo exit_code:`$?")
            $rootBlocked = ($result.Output -match "Permission denied" -or $result.Output -match "publickey")
            $mod.SDK.Testing.Record(@{
                Test = "6.4.4"; Name = "Root SSH login rejected"
                Pass = $rootBlocked
                Output = if ($rootBlocked) { "Root login correctly rejected" } else { $result.Output }
            })
        }
        "SSH key auth" = {
            param($Worker)
            $result = $Worker.Exec("ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no ${username}@localhost echo OK")
            $mod.SDK.Testing.Record(@{
                Test = "6.4.5"; Name = "SSH key auth for $username"
                Pass = ($result.Success -and $result.Output -match "OK")
                Output = if ($result.Success) { "Key authentication successful" } else { $result.Output }
            })
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
