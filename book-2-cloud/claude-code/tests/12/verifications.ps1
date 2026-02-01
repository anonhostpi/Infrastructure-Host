param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.ClaudeCode" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $username = $mod.SDK.Settings.Identity.username

    $mod.Tests = [ordered]@{
        "Claude Code installed" = {
            param($Worker)
            $Worker.Test("6.12.1", "Claude Code installed", "which claude", "claude")
        }
        "Claude Code config directory" = {
            param($Worker)
            $Worker.Test("6.12.2", "Claude Code config directory", "sudo test -d /home/$username/.claude && echo exists", "exists")
        }
        "Claude Code settings file" = {
            param($Worker)
            $Worker.Test("6.12.3", "Claude Code settings file", "sudo test -f /home/$username/.claude/settings.json && echo exists", "exists")
        }
        "Claude Code auth configured" = {
            param($Worker)
            $Worker.Test("6.12.4", "Claude Code auth configured", "sudo test -f /home/$username/.claude/.credentials.json && echo exists", { param($out)
            $cred = $out -match "exists"
            $state = $Worker.Exec("sudo grep -q 'hasCompletedOnboarding' /home/$username/.claude.json 2>/dev/null && echo exists")
            if ($cred -and $state.Output -match "exists") { return $true }
            $env = $Worker.Exec("grep -q 'ANTHROPIC_API_KEY' /etc/environment && echo configured")
            $env.Output -match "configured"
            })
        }
        "Claude Code AI response" = {
            param($Worker)
            $cred = $Worker.Exec("sudo test -f /home/$username/.claude/.credentials.json && echo exists")
            $state = $Worker.Exec("sudo grep -q 'hasCompletedOnboarding' /home/$username/.claude.json 2>/dev/null && echo exists")
            $env = $Worker.Exec("grep -q 'ANTHROPIC_API_KEY' /etc/environment && echo configured")
            $hasAuth = ($cred.Output -match "exists" -and $state.Output -match "exists") -or ($env.Output -match "configured")
            if (-not $hasAuth) { $mod.SDK.Testing.Verifications.Fork("6.12.5", "SKIP", "No auth configured"); return }
            $result = $Worker.Exec("sudo -u $username env HOME=/home/$username timeout 30 claude -p test 2>&1")
            $clean = $result.Output -replace '\x1b\[[0-9;]*[a-zA-Z]', ''
            $hasResponse = ($clean -and $clean.Length -gt 0 -and $clean -notmatch "^error|failed|timeout")
            $mod.SDK.Testing.Record(@{
                Test = "6.12.5"; Name = "Claude Code AI response"
                Pass = $hasResponse
                Output = if ($hasResponse) { "Response received" } else { "Failed: $clean" }
            })
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
