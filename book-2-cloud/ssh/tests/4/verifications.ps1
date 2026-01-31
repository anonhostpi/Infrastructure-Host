param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.SSHHardening" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $username = $SDK.Settings.Identity.username

    $SDK.Testing.Verifications.Register("ssh", 4, [ordered]@{
        "SSH hardening config exists" = {
            param($Worker)
            $result = $Worker.Exec("test -f /etc/ssh/sshd_config.d/99-hardening.conf")
            $SDK.Testing.Record(@{
                Test = "6.4.1"; Name = "SSH hardening config exists"
                Pass = $result.Success; Output = "/etc/ssh/sshd_config.d/99-hardening.conf"
            })
        }
        "PermitRootLogin no" = {
            param($Worker)
            $result = $Worker.Exec("sudo grep -r 'PermitRootLogin' /etc/ssh/sshd_config.d/")
            $SDK.Testing.Record(@{
                Test = "6.4.2"; Name = "PermitRootLogin no"
                Pass = ($result.Output -match "PermitRootLogin no"); Output = $result.Output
            })
        }
        "MaxAuthTries set" = {
            param($Worker)
            $result = $Worker.Exec("sudo grep -r 'MaxAuthTries' /etc/ssh/sshd_config.d/")
            $SDK.Testing.Record(@{
                Test = "6.4.2"; Name = "MaxAuthTries set"
                Pass = ($result.Output -match "MaxAuthTries"); Output = $result.Output
            })
        }
        "SSH service active" = {
            param($Worker)
            $result = $Worker.Exec("systemctl is-active ssh")
            $SDK.Testing.Record(@{
                Test = "6.4.3"; Name = "SSH service active"
                Pass = ($result.Output -match "^active$"); Output = $result.Output
            })
        }
        "Root SSH login rejected" = { param($Worker) }
        "SSH key auth" = { param($Worker) }
    })
} -ArgumentList $SDK
