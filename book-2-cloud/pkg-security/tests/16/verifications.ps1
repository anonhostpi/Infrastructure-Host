param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.PackageManagerUpdates" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $mod.Tests = [ordered]@{
        "Testing mode enabled" = {
            param($Worker)
            $Worker.Test("6.8.19", "Testing mode enabled", "source /usr/local/lib/apt-notify/common.sh && echo `$TESTING_MODE", "true")
            $Worker.Exec("sudo rm -f /var/lib/apt-notify/queue /var/lib/apt-notify/test-report.txt /var/lib/apt-notify/test-ai-summary.txt") | Out-Null
        }
        "snap-update" = {
            param($Worker)
            $testingMode = $Worker.Exec("source /usr/local/lib/apt-notify/common.sh && echo `$TESTING_MODE").Output
            if ($testingMode -notmatch "true") { $mod.SDK.Testing.Verifications.Fork("6.8.20", "SKIP", "Testing mode disabled"); return }
            if (-not ($Worker.Exec("which snap")).Success) {
                $Worker.Test("6.8.20", "snap-update", "echo skipped", { $true }); return
            }
            $Worker.Test("6.8.20", "snap-update script", "sudo /usr/local/bin/snap-update 2>&1; echo exit_code:`$?", "exit_code:0")
        }
        "npm-global-update" = {
            param($Worker)
            $tm = $Worker.Exec("source /usr/local/lib/apt-notify/common.sh && echo `$TESTING_MODE").Output
            if ($tm -notmatch "true") { $mod.SDK.Testing.Verifications.Fork("6.8.21", "SKIP", "Testing mode disabled"); return }
            if (-not ($Worker.Exec("which npm")).Success) {
                $Worker.Test("6.8.21", "npm-global-update", "echo skipped", { $true }); return
            }
            $Worker.Exec("sudo npm install -g is-odd@2.0.0 2>/dev/null") | Out-Null
            $Worker.Exec("sudo rm -f /var/lib/apt-notify/queue") | Out-Null
            $Worker.Test("6.8.21", "npm-global-update script", "sudo /usr/local/bin/npm-global-update 2>&1; echo exit_code:`$?", { param($out)
            $queue = $Worker.Exec("cat /var/lib/apt-notify/queue 2>/dev/null").Output
            ($out -match "exit_code:0") -and ($queue -match "NPM_UPGRADED")
            })
            $Worker.Exec("sudo npm uninstall -g is-odd 2>/dev/null") | Out-Null
        }
        "pip-global-update" = {
            param($Worker)
            $tm = $Worker.Exec("source /usr/local/lib/apt-notify/common.sh && echo `$TESTING_MODE").Output
            if ($tm -notmatch "true") { $mod.SDK.Testing.Verifications.Fork("6.8.22", "SKIP", "Testing mode disabled"); return }
            if (-not ($Worker.Exec("which pip3")).Success) {
                $Worker.Test("6.8.22", "pip-global-update", "echo skipped", { $true }); return
            }
            $Worker.Exec("sudo pip3 install six==1.15.0 2>/dev/null") | Out-Null
            $Worker.Exec("sudo rm -f /var/lib/apt-notify/queue") | Out-Null
            $Worker.Test("6.8.22", "pip-global-update script", "sudo /usr/local/bin/pip-global-update 2>&1; echo exit_code:`$?", { param($out)
            $queue = $Worker.Exec("cat /var/lib/apt-notify/queue 2>/dev/null").Output
            ($out -match "exit_code:0") -and ($queue -match "PIP_UPGRADED")
            })
        }
        "brew-update" = {
            param($Worker)
            $tm = $Worker.Exec("source /usr/local/lib/apt-notify/common.sh && echo `$TESTING_MODE").Output
            if ($tm -notmatch "true") { $mod.SDK.Testing.Verifications.Fork("6.8.23", "SKIP", "Testing mode disabled"); return }
            if (-not ($Worker.Exec("command -v brew || test -x /home/linuxbrew/.linuxbrew/bin/brew")).Success) {
                $Worker.Test("6.8.23", "brew-update", "echo skipped", { $true }); return
            }
            $Worker.Test("6.8.23", "brew-update script", "sudo /usr/local/bin/brew-update 2>&1; echo exit_code:`$?", "exit_code:0")
        }
        "deno-update" = {
            param($Worker)
            $tm = $Worker.Exec("source /usr/local/lib/apt-notify/common.sh && echo `$TESTING_MODE").Output
            if ($tm -notmatch "true") { $mod.SDK.Testing.Verifications.Fork("6.8.24", "SKIP", "Testing mode disabled"); return }
            if (-not ($Worker.Exec("which deno")).Success) {
                $Worker.Test("6.8.24", "deno-update", "echo skipped", { $true }); return
            }
            $Worker.Test("6.8.24", "deno-update script", "sudo /usr/local/bin/deno-update 2>&1; echo exit_code:`$?", "exit_code:0")
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
