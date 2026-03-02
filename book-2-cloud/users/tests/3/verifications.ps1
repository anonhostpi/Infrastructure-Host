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
        "user has home directory" = {
            param($Worker)
            $Worker.Test("6.3.2", "$username has home directory", "test -d /home/$username && echo exists", "exists")
        }
        "Sudoers file exists" = {
            param($Worker)
            $Worker.Test("6.3.3", "Sudoers file exists", "sudo test -f /etc/sudoers.d/$username", { $true })
        }
        "Root account locked" = {
            param($Worker)
            $Worker.Test("6.3.4", "Root account locked", "sudo passwd -S root", "root L")
        }
        "user-setup.log exists" = {
            param($Worker)
            $Worker.Test("6.3.5", "user-setup.log exists", "test -f /var/lib/cloud/scripts/user-setup/user-setup.log", { $true })
        }
        "user-setup.sh executed" = {
            param($Worker)
            $Worker.Test("6.3.5", "user-setup.sh executed", "cat /var/lib/cloud/scripts/user-setup/user-setup.log", "user-setup:")
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
