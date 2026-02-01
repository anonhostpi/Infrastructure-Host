param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.SecurityMonitoring" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $mod.Tests = [ordered]@{
        "fail2ban installed" = {
            param($Worker)
            $result = $Worker.Exec("which fail2ban-client")
            $mod.SDK.Testing.Record(@{
                Test = "6.9.1"; Name = "fail2ban installed"
                Pass = ($result.Success -and $result.Output -match "fail2ban"); Output = $result.Output
            })
        }
        "fail2ban service active" = {
            param($Worker)
            $result = $Worker.Exec("sudo systemctl is-active fail2ban")
            $mod.SDK.Testing.Record(@{
                Test = "6.9.2"; Name = "fail2ban service active"
                Pass = ($result.Output -match "^active$"); Output = $result.Output
            })
        }
        "SSH jail configured" = {
            param($Worker)
            $result = $Worker.Exec("sudo fail2ban-client status")
            $mod.SDK.Testing.Record(@{
                Test = "6.9.3"; Name = "SSH jail configured"
                Pass = ($result.Output -match "sshd"); Output = "sshd jail"
            })
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
