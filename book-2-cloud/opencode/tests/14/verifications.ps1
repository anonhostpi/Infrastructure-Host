param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.OpenCode" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $username = $SDK.Settings.Identity.username

    $SDK.Testing.Verifications.Register("opencode", 14, [ordered]@{
        "Node.js installed" = {
            param($Worker)
            $result = $Worker.Exec("which node")
            $SDK.Testing.Record(@{
                Test = "6.14.1"; Name = "Node.js installed"
                Pass = ($result.Success -and $result.Output -match "node"); Output = $result.Output
            })
        }
        "npm installed" = {
            param($Worker)
            $result = $Worker.Exec("which npm")
            $SDK.Testing.Record(@{
                Test = "6.14.2"; Name = "npm installed"
                Pass = ($result.Success -and $result.Output -match "npm"); Output = $result.Output
            })
        }
        "OpenCode installed" = {
            param($Worker)
            $result = $Worker.Exec("which opencode")
            $SDK.Testing.Record(@{
                Test = "6.14.3"; Name = "OpenCode installed"
                Pass = ($result.Success -and $result.Output -match "opencode"); Output = $result.Output
            })
        }
        "OpenCode config directory" = {
            param($Worker)
            $result = $Worker.Exec("sudo test -d /home/$username/.config/opencode && echo exists")
            $SDK.Testing.Record(@{
                Test = "6.14.4"; Name = "OpenCode config directory"
                Pass = ($result.Output -match "exists"); Output = "/home/$username/.config/opencode"
            })
        }
        "OpenCode auth file" = {
            param($Worker)
            $result = $Worker.Exec("sudo test -f /home/$username/.local/share/opencode/auth.json && echo exists")
            $SDK.Testing.Record(@{
                Test = "6.14.5"; Name = "OpenCode auth file"
                Pass = ($result.Output -match "exists"); Output = "/home/$username/.local/share/opencode/auth.json"
            })
        }
        "OpenCode AI response" = {
            param($Worker)
            $result = $Worker.Exec("sudo -u $username env HOME=/home/$username timeout 30 opencode run test 2>&1")
            $clean = $result.Output -replace '\x1b\[[0-9;]*[a-zA-Z]', ''
            $hasResponse = ($clean -and $clean.Length -gt 0 -and $clean -notmatch "^error|failed|timeout")
            $SDK.Testing.Record(@{
                Test = "6.14.6"; Name = "OpenCode AI response"
                Pass = $hasResponse
                Output = if ($hasResponse) { "Response received" } else { "Failed: $clean" }
            })
        }
        "OpenCode credential chain" = {
            param($Worker)
            $settings = $SDK.Settings
            if (-not ($settings.opencode.enabled -and $settings.claude_code.enabled)) {
                $SDK.Testing.Verifications.Fork("6.14.7", "SKIP", "OpenCode + Claude Code not both enabled"); return
            }
            $hostCreds = Get-Content "$env:USERPROFILE\.claude\.credentials.json" -Raw 2>$null | ConvertFrom-Json
            $vmCreds = $Worker.Exec("sudo cat /home/$username/.local/share/opencode/auth.json").Output | ConvertFrom-Json
            $tokensMatch = ($hostCreds -and $vmCreds -and $hostCreds.accessToken -eq $vmCreds.anthropic.accessToken)
            $models = $Worker.Exec("sudo su - $username -c 'opencode models' 2>/dev/null")
            $SDK.Testing.Record(@{
                Test = "6.14.7"; Name = "OpenCode credential chain"
                Pass = ($tokensMatch -and $models.Output -match "anthropic")
                Output = if ($tokensMatch) { "Tokens match, provider: anthropic" } else { "Token mismatch" }
            })
        }
    })
} -ArgumentList $SDK
