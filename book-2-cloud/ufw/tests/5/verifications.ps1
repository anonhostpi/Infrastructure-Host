param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.UFWFirewall" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $mod.Tests = [ordered]@{
        "UFW is active" = {
            param($Worker)
            $Worker.Test("6.5.1", "UFW is active", "sudo ufw status", "Status: active")
        }
        "SSH allowed in UFW" = {
            param($Worker)
            $Worker.Test("6.5.2", "SSH allowed in UFW", "sudo ufw status", "22.*ALLOW")
        }
        "Default deny incoming" = {
            param($Worker)
            $Worker.Test("6.5.3", "Default deny incoming", "sudo ufw status verbose", "deny \(incoming\)")
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
