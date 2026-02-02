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
            $Worker.Test("6.4.3", "SSH service active", "systemctl is-active ssh", "active")
        }
        "Root SSH login rejected" = {
            param($Worker)
            $Worker.Test("6.4.4", "Root SSH login rejected", "ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@localhost exit 2>&1; echo exit_code:`$?", "Permission denied|publickey")
        }
        "SSH key auth" = {
            param($Worker)
            $Worker.Test("6.4.5", "SSH key auth for $username", "ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no ${username}@localhost echo OK", "OK")
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
