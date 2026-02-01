param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.Network" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $mod.Tests = [ordered]@{
        "Short hostname set" = {
            param($Worker)
            $Worker.Test("6.1.1", "Short hostname set", "hostname -s", { param($out) $out -and $out -ne "localhost" })
        }
        "FQDN has domain" = {
            param($Worker)
            $Worker.Test("6.1.1", "FQDN has domain", "hostname -f", "\.")
        }
        "Hostname in /etc/hosts" = {
            param($Worker)
            $Worker.Test("6.1.2", "Hostname in /etc/hosts", "grep '127.0.1.1' /etc/hosts", ".")
        }
        "Netplan config exists" = {
            param($Worker)
            $Worker.Test("6.1.3", "Netplan config exists", "ls /etc/netplan/*.yaml 2>/dev/null", ".")
        }
        "IP address assigned" = {
            param($Worker)
            $Worker.Test("6.1.4", "IP address assigned", "ip -4 addr show scope global | grep 'inet '", "inet ")
        }
        "Default gateway configured" = {
            param($Worker)
            $Worker.Test("6.1.4", "Default gateway configured", "ip route | grep '^default'", "default via")
        }
        "DNS resolution works" = {
            param($Worker)
            $result = $Worker.Exec("host -W 2 ubuntu.com")
            $mod.SDK.Testing.Record(@{
                Test = "6.1.4"; Name = "DNS resolution works"
                Pass = ($result.Output -match "has address" -or $result.Output -match "has IPv"); Output = $result.Output
            })
        }
        "net-setup.log exists" = {
            param($Worker)
            $result = $Worker.Exec("test -f /var/lib/cloud/scripts/net-setup/net-setup.log")
            $mod.SDK.Testing.Record(@{
                Test = "6.1.5"; Name = "net-setup.log exists"
                Pass = $result.Success; Output = "/var/lib/cloud/scripts/net-setup/net-setup.log"
            })
        }
        "net-setup.sh executed" = {
            param($Worker)
            $result = $Worker.Exec("cat /var/lib/cloud/scripts/net-setup/net-setup.log")
            $mod.SDK.Testing.Record(@{
                Test = "6.1.5"; Name = "net-setup.sh executed"
                Pass = ($result.Output -match "net-setup:")
                Output = if ($result.Output) { ($result.Output | Select-Object -First 3) -join "; " } else { "(empty)" }
            })
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
