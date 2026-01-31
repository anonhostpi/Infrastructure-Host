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
        "Copilot CLI config file" = {
            param($Worker)
            $result = $Worker.Exec("sudo test -f /home/$username/.copilot/config.json && echo exists")
            $SDK.Testing.Record(@{
                Test = "6.13.3"; Name = "Copilot CLI config file"
                Pass = ($result.Output -match "exists"); Output = "/home/$username/.copilot/config.json"
            })
        }
        "Copilot CLI auth configured" = {
            param($Worker)
            $hasAuth = $false; $authOutput = "No auth found"
            $tokens = $Worker.Exec("sudo grep -q 'copilot_tokens' /home/$username/.copilot/config.json 2>/dev/null && echo configured")
            if ($tokens.Output -match "configured") {
                $hasAuth = $true; $authOutput = "OAuth tokens in config.json"
            } else {
                $env = $Worker.Exec("grep -q 'GH_TOKEN' /etc/environment && echo configured")
                if ($env.Output -match "configured") { $hasAuth = $true; $authOutput = "GH_TOKEN configured" }
            }
            $SDK.Testing.Record(@{
                Test = "6.13.4"; Name = "Copilot CLI auth configured"
                Pass = $hasAuth; Output = $authOutput
            })
        }
        "Copilot CLI AI response" = { param($Worker) }
    })
} -ArgumentList $SDK
