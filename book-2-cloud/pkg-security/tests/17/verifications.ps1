param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.UpdateSummary" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $SDK.Testing.Verifications.Register("pkg-security", 17, [ordered]@{
        "Report generated" = {
            param($Worker)
            $Worker.Exec("sudo rm -f /var/lib/apt-notify/test-report.txt /var/lib/apt-notify/test-ai-summary.txt /var/lib/apt-notify/apt-notify.log") | Out-Null
            $queueLines = @("INSTALLED:testpkg:1.0.0", "UPGRADED:curl:7.81.0:7.82.0", "SNAP_UPGRADED:lxd:5.20:5.21",
                "BREW_UPGRADED:jq:1.6:1.7", "PIP_UPGRADED:requests:2.28.0:2.31.0", "NPM_UPGRADED:opencode:1.0.0:1.1.0", "DENO_UPGRADED:deno:1.40.0:1.41.0")
            $Worker.Exec("sudo rm -f /var/lib/apt-notify/apt-notify.queue") | Out-Null
            foreach ($line in $queueLines) { $Worker.Exec("sudo bash -c `"echo '$line' >> /var/lib/apt-notify/apt-notify.queue`"") | Out-Null }
            $Worker.Exec("sudo timeout 30 /usr/local/bin/apt-notify-flush") | Out-Null
            $reportExists = $Worker.Exec("sudo test -s /var/lib/apt-notify/test-report.txt && echo exists")
            $SDK.Testing.Record(@{
                Test = "6.8.25"; Name = "Report generated"
                Pass = ($reportExists.Output -match "exists")
                Output = if ($reportExists.Output -match "exists") { "Report created" } else { "Report not created" }
            })
        }
        "Report contains npm section" = { param($Worker) }
        "AI summary reports valid model" = { param($Worker) }
    })
} -ArgumentList $SDK
