param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.CopilotCLI" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $username = $mod.SDK.Settings.Identity.username

    $mod.Tests = [ordered]@{
        "Copilot CLI installed" = {
            param($Worker)
            $Worker.Test("6.13.1", "Copilot CLI installed", "which copilot", "copilot")
        }
        "Copilot CLI config directory" = {
            param($Worker)
            $Worker.Test("6.13.2", "Copilot CLI config directory", "sudo test -d /home/$username/.copilot && echo exists", "exists")
        }
        "Copilot CLI config file" = {
            param($Worker)
            $Worker.Test("6.13.3", "Copilot CLI config file", "sudo test -f /home/$username/.copilot/config.json && echo exists", "exists")
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
            $mod.SDK.Testing.Record(@{
                Test = "6.13.4"; Name = "Copilot CLI auth configured"
                Pass = $hasAuth; Output = $authOutput
            })
        }
        "Copilot CLI AI response" = {
            param($Worker)
            $tokens = $Worker.Exec("sudo grep -q 'copilot_tokens' /home/$username/.copilot/config.json 2>/dev/null && echo configured")
            $env = $Worker.Exec("grep -q 'GH_TOKEN' /etc/environment && echo configured")
            $hasAuth = ($tokens.Output -match "configured") -or ($env.Output -match "configured")
            if (-not $hasAuth) { $mod.SDK.Testing.Verifications.Fork("6.13.5", "SKIP", "No auth configured"); return }
            $result = $Worker.Exec("sudo -u $username env HOME=/home/$username timeout 30 copilot --model gpt-4.1 -p test 2>&1")
            $clean = $result.Output -replace '\x1b\[[0-9;]*[a-zA-Z]', ''
            $hasResponse = ($clean -and $clean.Length -gt 0 -and $clean -notmatch "^error|failed|timeout")
            $mod.SDK.Testing.Record(@{
                Test = "6.13.5"; Name = "Copilot CLI AI response"
                Pass = $hasResponse
                Output = if ($hasResponse) { "Response received" } else { "Failed: $clean" }
            })
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
