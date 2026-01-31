param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.CopilotCLI" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $username = $SDK.Settings.Identity.username

    $SDK.Testing.Verifications.Register("copilot-cli", 13, [ordered]@{
        "Copilot CLI installed" = {
            param($Worker)
            $result = $Worker.Exec("which copilot")
            $SDK.Testing.Record(@{
                Test = "6.13.1"; Name = "Copilot CLI installed"
                Pass = ($result.Success -and $result.Output -match "copilot"); Output = $result.Output
            })
        }
        "Copilot CLI config directory" = {
            param($Worker)
            $result = $Worker.Exec("sudo test -d /home/$username/.copilot && echo exists")
            $SDK.Testing.Record(@{
                Test = "6.13.2"; Name = "Copilot CLI config directory"
                Pass = ($result.Output -match "exists"); Output = "/home/$username/.copilot"
            })
        }
        "Copilot CLI config file" = { param($Worker) }
        "Copilot CLI auth configured" = { param($Worker) }
        "Copilot CLI AI response" = { param($Worker) }
    })
} -ArgumentList $SDK
