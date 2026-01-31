param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.SecurityMonitoring" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $SDK.Testing.Verifications.Register("security-mon", 9, [ordered]@{
        "fail2ban installed" = {
            param($Worker)
            $result = $Worker.Exec("which fail2ban-client")
            $SDK.Testing.Record(@{
                Test = "6.9.1"; Name = "fail2ban installed"
                Pass = ($result.Success -and $result.Output -match "fail2ban"); Output = $result.Output
            })
        }
        "fail2ban service active" = {
            param($Worker)
            $result = $Worker.Exec("sudo systemctl is-active fail2ban")
            $SDK.Testing.Record(@{
                Test = "6.9.2"; Name = "fail2ban service active"
                Pass = ($result.Output -match "^active$"); Output = $result.Output
            })
        }
    })
} -ArgumentList $SDK
