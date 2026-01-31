param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.PackageSecurity" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $SDK.Testing.Verifications.Register("pkg-security", 8, [ordered]@{
        "unattended-upgrades installed" = {
            param($Worker)
            $result = $Worker.Exec("dpkg -l unattended-upgrades")
            $SDK.Testing.Record(@{
                Test = "6.8.1"; Name = "unattended-upgrades installed"
                Pass = ($result.Output -match "ii.*unattended-upgrades"); Output = "Package installed"
            })
        }
        "Unattended upgrades config" = {
            param($Worker)
            $result = $Worker.Exec("test -f /etc/apt/apt.conf.d/50unattended-upgrades")
            $SDK.Testing.Record(@{
                Test = "6.8.2"; Name = "Unattended upgrades config"
                Pass = $result.Success; Output = "/etc/apt/apt.conf.d/50unattended-upgrades"
            })
        }
        "Auto-upgrades configured" = {
            param($Worker)
            $result = $Worker.Exec("cat /etc/apt/apt.conf.d/20auto-upgrades")
            $SDK.Testing.Record(@{
                Test = "6.8.3"; Name = "Auto-upgrades configured"
                Pass = ($result.Output -match 'Unattended-Upgrade.*"1"'); Output = "Auto-upgrade enabled"
            })
        }
        "Service enabled" = {
            param($Worker)
            $result = $Worker.Exec("systemctl is-enabled unattended-upgrades")
            $SDK.Testing.Record(@{
                Test = "6.8.4"; Name = "Service enabled"
                Pass = ($result.Output -match "enabled"); Output = $result.Output
            })
        }
        "apt-listchanges installed" = { param($Worker) }
        "apt-listchanges email config" = { param($Worker) }
        "apt-notify script exists" = { param($Worker) }
        "dpkg notification hooks" = { param($Worker) }
        "Verbose upgrade reporting" = { param($Worker) }
        "snap-update script" = { param($Worker) }
        "snap refresh.hold configured" = { param($Worker) }
        "brew-update script" = { param($Worker) }
        "pip-global-update script" = { param($Worker) }
        "npm-global-update script" = { param($Worker) }
        "deno-update script" = { param($Worker) }
        "pkg-managers-update timer" = { param($Worker) }
        "apt-notify common library" = { param($Worker) }
        "apt-notify-flush script" = { param($Worker) }
    })
} -ArgumentList $SDK
