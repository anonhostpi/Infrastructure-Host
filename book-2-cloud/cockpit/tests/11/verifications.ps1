param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.Cockpit" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $SDK.Testing.Verifications.Register("cockpit", 11, [ordered]@{
        "Cockpit installed" = {
            param($Worker)
            $result = $Worker.Exec("which cockpit-bridge")
            $SDK.Testing.Record(@{
                Test = "6.11.1"; Name = "Cockpit installed"
                Pass = ($result.Success -and $result.Output -match "cockpit"); Output = $result.Output
            })
        }
        "Cockpit socket enabled" = {
            param($Worker)
            $result = $Worker.Exec("systemctl is-enabled cockpit.socket")
            $SDK.Testing.Record(@{
                Test = "6.11.2"; Name = "Cockpit socket enabled"
                Pass = ($result.Output -match "enabled"); Output = $result.Output
            })
        }
        "cockpit-machines installed" = { param($Worker) }
        "Cockpit listening on port" = { param($Worker) }
        "Cockpit web UI responds" = { param($Worker) }
        "Cockpit login page" = { param($Worker) }
        "Cockpit restricted to localhost" = { param($Worker) }
    })
} -ArgumentList $SDK
