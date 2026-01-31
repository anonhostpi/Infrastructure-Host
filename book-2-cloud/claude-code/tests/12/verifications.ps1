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
        "Claude Code auth configured" = { param($Worker) }
        "Claude Code AI response" = { param($Worker) }
    })
} -ArgumentList $SDK
