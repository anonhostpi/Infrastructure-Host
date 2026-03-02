param([int]$Layer, [switch]$SkipCleanup, [switch]$SkipSDK, [switch]$SkipCloudInit, [switch]$SkipAutoinstall)

$ErrorActionPreference = "Stop"
$repoRoot = $PSScriptRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Infrastructure-Host Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if (-not $SkipSDK) {
    Write-Host "`n--- Book 0: SDK Tests ---" -ForegroundColor Cyan
    & "$repoRoot\book-0-builder\Invoke-SDKTest.ps1" -SkipCleanup:$SkipCleanup
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Book 0 SDK tests failed" -ForegroundColor Red
        exit 1
    }
}
if (-not $SkipCloudInit) { }
if (-not $SkipAutoinstall) { }

exit 0
