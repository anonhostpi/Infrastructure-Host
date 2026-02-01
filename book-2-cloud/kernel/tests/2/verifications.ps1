param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.KernelHardening" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $mod.SDK.Testing.Verifications.Register("kernel", 2, [ordered]@{
        "Security sysctl config exists" = {
            param($Worker)
            $result = $Worker.Exec("test -f /etc/sysctl.d/99-security.conf")
            $mod.SDK.Testing.Record(@{
                Test = "6.2.1"; Name = "Security sysctl config exists"
                Pass = $result.Success; Output = "/etc/sysctl.d/99-security.conf"
            })
        }
        "Reverse path filtering enabled" = {
            param($Worker)
            $result = $Worker.Exec("sysctl net.ipv4.conf.all.rp_filter")
            $mod.SDK.Testing.Record(@{
                Test = "6.2.2"; Name = "Reverse path filtering enabled"
                Pass = ($result.Output -match "= 1"); Output = $result.Output
            })
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
    })
} -ArgumentList $SDK
