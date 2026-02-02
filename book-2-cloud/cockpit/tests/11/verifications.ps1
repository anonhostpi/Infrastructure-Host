param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.Cockpit" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $mod.Tests = [ordered]@{
        "Cockpit installed" = {
            param($Worker)
            $Worker.Test("6.11.1", "Cockpit installed", "which cockpit-bridge", "cockpit")
        }
        "Cockpit socket enabled" = {
            param($Worker)
            $Worker.Test("6.11.2", "Cockpit socket enabled", "systemctl is-enabled cockpit.socket", "enabled")
        }
        "cockpit-machines installed" = {
            param($Worker)
            $Worker.Test("6.11.3", "cockpit-machines installed", "dpkg -l cockpit-machines", "ii.*cockpit-machines")
        }
        "Cockpit listening on port" = {
            param($Worker)
            $portConf = $Worker.Exec("cat /etc/systemd/system/cockpit.socket.d/listen.conf 2>/dev/null").Output
            $port = if ($portConf -match 'ListenStream=(\d+)') { $matches[1] } else { "9090" }
            $Worker.Exec("curl -sk https://localhost:$port/ > /dev/null 2>&1") | Out-Null
            $Worker.Test("6.11.4", "Cockpit listening on port $port", "ss -tlnp | grep :$port", ":$port")
        }
        "Cockpit web UI responds" = {
            param($Worker)
            $portConf = $Worker.Exec("cat /etc/systemd/system/cockpit.socket.d/listen.conf 2>/dev/null").Output
            $port = if ($portConf -match 'ListenStream=(\d+)') { $matches[1] } else { "9090" }
            $Worker.Test("6.11.5", "Cockpit web UI responds", "curl -sk -o /dev/null -w '%{http_code}' https://localhost:$port/", "200")
        }
        "Cockpit login page" = {
            param($Worker)
            $portConf = $Worker.Exec("cat /etc/systemd/system/cockpit.socket.d/listen.conf 2>/dev/null").Output
            $port = if ($portConf -match 'ListenStream=(\d+)') { $matches[1] } else { "9090" }
            $Worker.Test("6.11.6", "Cockpit login page", "curl -sk https://localhost:$port/ | grep -E 'login.js|login.css'", ".")
        }
        "Cockpit restricted to localhost" = {
            param($Worker)
            $Worker.Test("6.11.7", "Cockpit restricted to localhost", "cat /etc/systemd/system/cockpit.socket.d/listen.conf 2>/dev/null", "127\.0\.0\.1|::1|localhost")
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
