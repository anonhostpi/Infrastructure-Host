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
            $result = $Worker.Exec("sysctl net.ipv4.tcp_syncookies")
            $mod.SDK.Testing.Record(@{
                Test = "6.2.2"; Name = "SYN cookies enabled"
                Pass = ($result.Output -match "= 1"); Output = $result.Output
            })
        }
        "ICMP redirects disabled" = {
            param($Worker)
            $result = $Worker.Exec("sysctl net.ipv4.conf.all.accept_redirects")
            $mod.SDK.Testing.Record(@{
                Test = "6.2.2"; Name = "ICMP redirects disabled"
                Pass = ($result.Output -match "= 0"); Output = $result.Output
            })
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
