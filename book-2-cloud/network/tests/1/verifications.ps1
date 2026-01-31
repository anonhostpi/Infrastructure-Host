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
        "Hostname in /etc/hosts" = { param($Worker) }
        "Netplan config exists" = { param($Worker) }
        "IP address assigned" = { param($Worker) }
        "Default gateway configured" = { param($Worker) }
        "DNS resolution works" = { param($Worker) }
        "net-setup.log exists" = { param($Worker) }
        "net-setup.sh executed" = { param($Worker) }
    })
} -ArgumentList $SDK
