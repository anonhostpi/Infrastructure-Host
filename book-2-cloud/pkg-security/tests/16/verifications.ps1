param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.PackageManagerUpdates" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $SDK.Testing.Verifications.Register("pkg-security", 16, [ordered]@{
        "Testing mode enabled" = {
            param($Worker)
            $testingMode = $Worker.Exec("source /usr/local/lib/apt-notify/common.sh && echo `$TESTING_MODE").Output
            $SDK.Testing.Record(@{
                Test = "6.8.19"; Name = "Testing mode enabled"
                Pass = ($testingMode -match "true")
                Output = if ($testingMode -match "true") { "TESTING_MODE=true" } else { "Rebuild with testing=true" }
            })
            if ($testingMode -match "true") {
                $Worker.Exec("sudo rm -f /var/lib/apt-notify/queue /var/lib/apt-notify/test-report.txt /var/lib/apt-notify/test-ai-summary.txt") | Out-Null
            }
        }
        "snap-update" = {
            param($Worker)
            $testingMode = $Worker.Exec("source /usr/local/lib/apt-notify/common.sh && echo `$TESTING_MODE").Output
            if ($testingMode -notmatch "true") { $SDK.Testing.Verifications.Fork("6.8.20", "SKIP", "Testing mode disabled"); return }
            $snapInstalled = $Worker.Exec("which snap")
            if (-not $snapInstalled.Success) {
                $SDK.Testing.Record(@{ Test = "6.8.20"; Name = "snap-update"; Pass = $true; Output = "Skipped - snap not installed" }); return
            }
            $result = $Worker.Exec("sudo /usr/local/bin/snap-update 2>&1; echo exit_code:`$?")
            $SDK.Testing.Record(@{
                Test = "6.8.20"; Name = "snap-update script"
                Pass = ($result.Output -match "exit_code:0")
                Output = if ($result.Output -match "exit_code:0") { "Ran successfully" } else { $result.Output }
            })
        }
        "npm-global-update" = {
            param($Worker)
            $tm = $Worker.Exec("source /usr/local/lib/apt-notify/common.sh && echo `$TESTING_MODE").Output
            if ($tm -notmatch "true") { $SDK.Testing.Verifications.Fork("6.8.21", "SKIP", "Testing mode disabled"); return }
            if (-not ($Worker.Exec("which npm")).Success) {
                $SDK.Testing.Record(@{ Test = "6.8.21"; Name = "npm-global-update"; Pass = $true; Output = "Skipped - npm not installed" }); return
            }
            $Worker.Exec("sudo npm install -g is-odd@2.0.0 2>/dev/null") | Out-Null
            $Worker.Exec("sudo rm -f /var/lib/apt-notify/queue") | Out-Null
            $result = $Worker.Exec("sudo /usr/local/bin/npm-global-update 2>&1; echo exit_code:`$?")
            $queue = $Worker.Exec("cat /var/lib/apt-notify/queue 2>/dev/null").Output
            $npmDetected = ($queue -match "NPM_UPGRADED")
            $SDK.Testing.Record(@{
                Test = "6.8.21"; Name = "npm-global-update script"
                Pass = ($result.Output -match "exit_code:0" -and $npmDetected)
                Output = if ($npmDetected) { "Detected npm update" } else { "No NPM_UPGRADED in queue" }
            })
            $Worker.Exec("sudo npm uninstall -g is-odd 2>/dev/null") | Out-Null
        }
        "pip-global-update" = { param($Worker) }
        "brew-update" = { param($Worker) }
        "deno-update" = { param($Worker) }
    })
} -ArgumentList $SDK
