param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.Users" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $username = $mod.SDK.Settings.Identity.username

    $mod.Tests = [ordered]@{
        "user exists" = {
            param($Worker)
            $Worker.Test("6.3.1", "$username user exists", "id $username", "uid=")
        }
        "user shell is bash" = {
            param($Worker)
            $Worker.Test("6.3.1", "$username shell is bash", "getent passwd $username | cut -d: -f7", "/bin/bash")
        }
        "user in sudo group" = {
            param($Worker)
            $Worker.Test("6.3.2", "$username in sudo group", "groups $username", "\bsudo\b")
        }
        "Sudoers file exists" = {
            param($Worker)
            $Worker.Test("6.3.3", "Sudoers file exists", "sudo test -f /etc/sudoers.d/$username", { $true })
        }
        "Root account locked" = {
            param($Worker)
            $Worker.Test("6.3.4", "Root account locked", "sudo passwd -S root", "root L")
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
