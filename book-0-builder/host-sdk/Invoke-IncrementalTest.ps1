param([int]$Layer, [switch]$SkipCleanup)

. "$PSScriptRoot\SDK.ps1"

# Setup builder (Build is called by CloudInitTest.Run with Layer)
$SDK.Builder.Stage()

# Run cloud-init tests (builds for layer, then tests)
$result = $SDK.CloudInit.Test.Run($Layer)

# Cleanup
if (-not $SkipCleanup) {
    $SDK.CloudInit.Cleanup()
    $SDK.Builder.Destroy()
}

exit $(if ($result.Success) { 0 } else { 1 })
