param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.SecurityMonitoring" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $mod.Tests = [ordered]@{
        "fail2ban installed" = {
            param($Worker)
            $Worker.Test("6.9.1", "fail2ban installed", "which fail2ban-client", "fail2ban")
        }
        "fail2ban service active" = {
            param($Worker)
            $Worker.Test("6.9.2", "fail2ban service active", "sudo systemctl is-active fail2ban", "active")
        }
        "SSH jail configured" = {
            param($Worker)
            $Worker.Test("6.9.3", "SSH jail configured", "sudo fail2ban-client status", "sshd")
        }
        "SSHD-DDoS jail configured" = {
            param($Worker)
            $Worker.Test("6.9.4", "SSHD-DDoS jail configured", "test -f /etc/fail2ban/jail.d/sshd-ddos.conf && echo exists", "exists")
        }
        "Sudo jail configured" = {
            param($Worker)
            $Worker.Test("6.9.5", "Sudo jail configured", "test -f /etc/fail2ban/jail.d/sudo.conf && echo exists", "exists")
        }
        "Recidive jail configured" = {
            param($Worker)
            $Worker.Test("6.9.6", "Recidive jail configured", "sudo fail2ban-client status recidive 2>/dev/null && echo active || echo inactive", "active")
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
