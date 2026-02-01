param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.OpenCode" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $username = $mod.SDK.Settings.Identity.username

    $mod.Tests = [ordered]@{
        "Node.js installed" = {
            param($Worker)
            $Worker.Test("6.14.1", "Node.js installed", "which node", "node")
        }
        "npm installed" = {
            param($Worker)
            $Worker.Test("6.14.2", "npm installed", "which npm", "npm")
        }
        "OpenCode installed" = {
            param($Worker)
            $Worker.Test("6.14.3", "OpenCode installed", "which opencode", "opencode")
        }
        "OpenCode config directory" = {
            param($Worker)
            $result = $Worker.Exec("sudo test -d /home/$username/.config/opencode && echo exists")
            $mod.SDK.Testing.Record(@{
                Test = "6.14.4"; Name = "OpenCode config directory"
                Pass = ($result.Output -match "exists"); Output = "/home/$username/.config/opencode"
            })
        }
        "OpenCode auth file" = {
            param($Worker)
            $result = $Worker.Exec("sudo test -f /home/$username/.local/share/opencode/auth.json && echo exists")
            $mod.SDK.Testing.Record(@{
                Test = "6.14.5"; Name = "OpenCode auth file"
                Pass = ($result.Output -match "exists"); Output = "/home/$username/.local/share/opencode/auth.json"
            })
        }
        "OpenCode AI response" = {
            param($Worker)
            $result = $Worker.Exec("sudo -u $username env HOME=/home/$username timeout 30 opencode run test 2>&1")
            $clean = $result.Output -replace '\x1b\[[0-9;]*[a-zA-Z]', ''
            $hasResponse = ($clean -and $clean.Length -gt 0 -and $clean -notmatch "^error|failed|timeout")
            $mod.SDK.Testing.Record(@{
                Test = "6.14.6"; Name = "OpenCode AI response"
                Pass = $hasResponse
                Output = if ($hasResponse) { "Response received" } else { "Failed: $clean" }
            })
        }
        "OpenCode credential chain" = {
            param($Worker)
            $settings = $mod.SDK.Settings
            if (-not ($settings.opencode.enabled -and $settings.claude_code.enabled)) {
                $mod.SDK.Testing.Verifications.Fork("6.14.7", "SKIP", "OpenCode + Claude Code not both enabled"); return
            }
            $hostCreds = Get-Content "$env:USERPROFILE\.claude\.credentials.json" -Raw 2>$null | ConvertFrom-Json
            $vmCreds = $Worker.Exec("sudo cat /home/$username/.local/share/opencode/auth.json").Output | ConvertFrom-Json
            $tokensMatch = ($hostCreds -and $vmCreds -and $hostCreds.accessToken -eq $vmCreds.anthropic.accessToken)
            $models = $Worker.Exec("sudo su - $username -c 'opencode models' 2>/dev/null")
            $mod.SDK.Testing.Record(@{
                Test = "6.14.7"; Name = "OpenCode credential chain"
                Pass = ($tokensMatch -and $models.Output -match "anthropic")
                Output = if ($tokensMatch) { "Tokens match, provider: anthropic" } else { "Token mismatch" }
            })
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
