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

# Book 2: Cloud-init fragment tests (requires multipass)
if (-not $SkipCloudInit) {
    Write-Host "`n--- Book 2: Cloud-Init Tests ---" -ForegroundColor Cyan
    $cloudInitArgs = @{ SkipCleanup = $SkipCleanup }
    if ($PSBoundParameters.ContainsKey('Layer')) { $cloudInitArgs.Layer = $Layer }
    & "$repoRoot\book-2-cloud\Invoke-IncrementalCloudInitTest.ps1" @cloudInitArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Book 2 cloud-init tests failed" -ForegroundColor Red
        exit 1
    }
}
if (-not $SkipAutoinstall) { }

exit 0
