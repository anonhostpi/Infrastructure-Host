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
            $Worker.Test("6.14.4", "OpenCode config directory", "sudo test -d /home/$username/.config/opencode && echo exists", "exists")
        }
        "OpenCode auth file" = {
            param($Worker)
            $Worker.Test("6.14.5", "OpenCode auth file", "sudo test -f /home/$username/.local/share/opencode/auth.json && echo exists", "exists")
        }
        "OpenCode AI response" = {
            param($Worker)
            $Worker.Test("6.14.6", "OpenCode AI response", "sudo -u $username env HOME=/home/$username timeout 30 opencode run test 2>&1", { param($out)
            $clean = $out -replace '\x1b\[[0-9;]*[a-zA-Z]', ''
            $clean -and $clean.Length -gt 0 -and $clean -notmatch "^error|failed|timeout"
            })
        }
        "OpenCode credential chain" = {
            param($Worker)
            $settings = $mod.SDK.Settings
            if (-not ($settings.opencode.enabled -and $settings.claude_code.enabled)) {
                $mod.SDK.Testing.Verifications.Fork("6.14.7", "SKIP", "OpenCode + Claude Code not both enabled"); return
            }
            $hostCreds = Get-Content "$env:USERPROFILE\.claude\.credentials.json" -Raw 2>$null | ConvertFrom-Json
            $Worker.Test("6.14.7", "OpenCode credential chain", "sudo cat /home/$username/.local/share/opencode/auth.json", { param($out)
            $vmCreds = $out | ConvertFrom-Json
            $tokensMatch = ($hostCreds -and $vmCreds -and $hostCreds.accessToken -eq $vmCreds.anthropic.accessToken)
            $models = $Worker.Exec("sudo su - $username -c 'opencode models' 2>/dev/null")
            $tokensMatch -and $models.Output -match "anthropic"
            })
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
