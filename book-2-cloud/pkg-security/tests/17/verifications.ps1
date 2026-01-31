param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.UpdateSummary" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $SDK.Testing.Verifications.Register("pkg-security", 17, [ordered]@{
        "Report generated" = { param($Worker) }
        "Report contains npm section" = { param($Worker) }
        "AI summary reports valid model" = { param($Worker) }
    })
} -ArgumentList $SDK
