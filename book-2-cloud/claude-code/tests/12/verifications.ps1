param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.ClaudeCode" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $username = $SDK.Settings.Identity.username

    $SDK.Testing.Verifications.Register("claude-code", 12, [ordered]@{
        "Claude Code installed" = {
            param($Worker)
            $result = $Worker.Exec("which claude")
            $SDK.Testing.Record(@{
                Test = "6.12.1"; Name = "Claude Code installed"
                Pass = ($result.Success -and $result.Output -match "claude"); Output = $result.Output
            })
        }
        "Claude Code config directory" = {
            param($Worker)
            $result = $Worker.Exec("sudo test -d /home/$username/.claude && echo exists")
            $SDK.Testing.Record(@{
                Test = "6.12.2"; Name = "Claude Code config directory"
                Pass = ($result.Output -match "exists"); Output = "/home/$username/.claude"
            })
        }
        "Claude Code settings file" = {
            param($Worker)
            $result = $Worker.Exec("sudo test -f /home/$username/.claude/settings.json && echo exists")
            $SDK.Testing.Record(@{
                Test = "6.12.3"; Name = "Claude Code settings file"
                Pass = ($result.Output -match "exists"); Output = "/home/$username/.claude/settings.json"
            })
        }
        "Claude Code auth configured" = {
            param($Worker)
            $hasAuth = $false; $authOutput = "No auth found"
            $cred = $Worker.Exec("sudo test -f /home/$username/.claude/.credentials.json && echo exists")
            $state = $Worker.Exec("sudo grep -q 'hasCompletedOnboarding' /home/$username/.claude.json 2>/dev/null && echo exists")
            if ($cred.Output -match "exists" -and $state.Output -match "exists") {
                $hasAuth = $true; $authOutput = "OAuth credentials configured"
            } else {
                $env = $Worker.Exec("grep -q 'ANTHROPIC_API_KEY' /etc/environment && echo configured")
                if ($env.Output -match "configured") { $hasAuth = $true; $authOutput = "API Key configured" }
            }
            $SDK.Testing.Record(@{
                Test = "6.12.4"; Name = "Claude Code auth configured"
                Pass = $hasAuth; Output = $authOutput
            })
        }
        "Claude Code AI response" = { param($Worker) }
    })
} -ArgumentList $SDK
