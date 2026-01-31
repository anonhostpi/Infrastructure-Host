param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.Network" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $SDK.Testing.Verifications.Register("network", 1, [ordered]@{
        "Short hostname set" = {
            param($Worker)
            $result = $Worker.Exec("hostname -s")
            $SDK.Testing.Record(@{
                Test = "6.1.1"; Name = "Short hostname set"
                Pass = ($result.Success -and $result.Output -and $result.Output -ne "localhost"); Output = $result.Output
            })
        }
        "FQDN has domain" = {
            param($Worker)
            $result = $Worker.Exec("hostname -f")
            $SDK.Testing.Record(@{
                Test = "6.1.1"; Name = "FQDN has domain"
                Pass = ($result.Output -match "\."); Output = $result.Output
            })
        }
        "Hostname in /etc/hosts" = {
            param($Worker)
            $result = $Worker.Exec("grep '127.0.1.1' /etc/hosts")
            $SDK.Testing.Record(@{
                Test = "6.1.2"; Name = "Hostname in /etc/hosts"
                Pass = ($result.Success -and $result.Output); Output = $result.Output
            })
        }
        "Netplan config exists" = {
            param($Worker)
            $result = $Worker.Exec("ls /etc/netplan/*.yaml 2>/dev/null")
            $SDK.Testing.Record(@{
                Test = "6.1.3"; Name = "Netplan config exists"
                Pass = ($result.Success -and $result.Output); Output = $result.Output
            })
        }
        "IP address assigned" = {
            param($Worker)
            $result = $Worker.Exec("ip -4 addr show scope global | grep 'inet '")
            $SDK.Testing.Record(@{
                Test = "6.1.4"; Name = "IP address assigned"
                Pass = ($result.Output -match "inet "); Output = $result.Output
            })
        }
        "Default gateway configured" = {
            param($Worker)
            $result = $Worker.Exec("ip route | grep '^default'")
            $SDK.Testing.Record(@{
                Test = "6.1.4"; Name = "Default gateway configured"
                Pass = ($result.Output -match "default via"); Output = $result.Output
            })
        }
        "DNS resolution works" = {
            param($Worker)
            $result = $Worker.Exec("host -W 2 ubuntu.com")
            $SDK.Testing.Record(@{
                Test = "6.1.4"; Name = "DNS resolution works"
                Pass = ($result.Output -match "has address" -or $result.Output -match "has IPv"); Output = $result.Output
            })
        }
        "net-setup.log exists" = { param($Worker) }
        "net-setup.sh executed" = { param($Worker) }
    })
} -ArgumentList $SDK
