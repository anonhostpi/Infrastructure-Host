param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.Cockpit" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $mod.Tests = [ordered]@{
        "Cockpit installed" = {
            param($Worker)
            $result = $Worker.Exec("which cockpit-bridge")
            $mod.SDK.Testing.Record(@{
                Test = "6.11.1"; Name = "Cockpit installed"
                Pass = ($result.Success -and $result.Output -match "cockpit"); Output = $result.Output
            })
        }
        "Cockpit socket enabled" = {
            param($Worker)
            $result = $Worker.Exec("systemctl is-enabled cockpit.socket")
            $mod.SDK.Testing.Record(@{
                Test = "6.11.2"; Name = "Cockpit socket enabled"
                Pass = ($result.Output -match "enabled"); Output = $result.Output
            })
        }
        "cockpit-machines installed" = {
            param($Worker)
            $result = $Worker.Exec("dpkg -l cockpit-machines")
            $mod.SDK.Testing.Record(@{
                Test = "6.11.3"; Name = "cockpit-machines installed"
                Pass = ($result.Output -match "ii.*cockpit-machines"); Output = "Package installed"
            })
        }
        "Cockpit listening on port" = {
            param($Worker)
            $portConf = $Worker.Exec("cat /etc/systemd/system/cockpit.socket.d/listen.conf 2>/dev/null").Output
            $port = if ($portConf -match 'ListenStream=(\d+)') { $matches[1] } else { "9090" }
            $Worker.Exec("curl -sk https://localhost:$port/ > /dev/null 2>&1") | Out-Null
            $result = $Worker.Exec("ss -tlnp | grep :$port")
            $mod.SDK.Testing.Record(@{
                Test = "6.11.4"; Name = "Cockpit listening on port $port"
                Pass = ($result.Output -match ":$port"); Output = $result.Output
            })
        }
        "Cockpit web UI responds" = {
            param($Worker)
            $portConf = $Worker.Exec("cat /etc/systemd/system/cockpit.socket.d/listen.conf 2>/dev/null").Output
            $port = if ($portConf -match 'ListenStream=(\d+)') { $matches[1] } else { "9090" }
            $result = $Worker.Exec("curl -sk -o /dev/null -w '%{http_code}' https://localhost:$port/")
            $mod.SDK.Testing.Record(@{
                Test = "6.11.5"; Name = "Cockpit web UI responds"
                Pass = ($result.Output -match "200"); Output = "HTTP $($result.Output)"
            })
        }
        "Cockpit login page" = {
            param($Worker)
            $portConf = $Worker.Exec("cat /etc/systemd/system/cockpit.socket.d/listen.conf 2>/dev/null").Output
            $port = if ($portConf -match 'ListenStream=(\d+)') { $matches[1] } else { "9090" }
            $result = $Worker.Exec("curl -sk https://localhost:$port/ | grep -E 'login.js|login.css'")
            $mod.SDK.Testing.Record(@{
                Test = "6.11.6"; Name = "Cockpit login page"
                Pass = ($result.Success -and $result.Output); Output = "Login page served"
            })
        }
        "Cockpit restricted to localhost" = {
            param($Worker)
            $portConf = $Worker.Exec("cat /etc/systemd/system/cockpit.socket.d/listen.conf 2>/dev/null").Output
            $restricted = ($portConf -match "127\.0\.0\.1" -or $portConf -match "::1" -or $portConf -match "localhost")
            $mod.SDK.Testing.Record(@{
                Test = "6.11.7"; Name = "Cockpit restricted to localhost"
                Pass = $restricted
                Output = if ($restricted) { "Listen restricted" } else { "Warning: may be externally accessible" }
            })
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
