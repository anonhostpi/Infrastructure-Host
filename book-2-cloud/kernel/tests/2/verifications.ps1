param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.KernelHardening" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $mod.Tests = [ordered]@{
        "Security sysctl config exists" = {
            param($Worker)
            $Worker.Test("6.2.1", "Security sysctl config exists", "test -f /etc/sysctl.d/99-security.conf", { $true })
        }
        "Reverse path filtering enabled" = {
            param($Worker)
            $Worker.Test("6.2.2", "Reverse path filtering enabled", "sysctl net.ipv4.conf.all.rp_filter", "= 1")
        }
        "SYN cookies enabled" = {
            param($Worker)
            $Worker.Test("6.2.2", "SYN cookies enabled", "sysctl net.ipv4.tcp_syncookies", "= 1")
        }
        "ICMP redirects disabled" = {
            param($Worker)
            $Worker.Test("6.2.2", "ICMP redirects disabled", "sysctl net.ipv4.conf.all.accept_redirects", "= 0")
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
