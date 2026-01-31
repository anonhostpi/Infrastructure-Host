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
        "snap-update" = { param($Worker) }
        "npm-global-update" = { param($Worker) }
        "pip-global-update" = { param($Worker) }
        "brew-update" = { param($Worker) }
        "deno-update" = { param($Worker) }
    })
} -ArgumentList $SDK
