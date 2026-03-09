param([int]$Layer, [switch]$SkipCleanup)

. "$PSScriptRoot\..\book-0-builder\host-sdk\SDK.ps1"

# Run cloud-init tests (renders host-side, then tests)
$result = $SDK.CloudInit.Test.Run($Layer)

# Cleanup
if (-not $SkipCleanup) {
    $SDK.CloudInit.Cleanup()
}

exit $(if ($result.Success) { 0 } else { 1 })
