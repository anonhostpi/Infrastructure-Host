param([switch]$SkipCleanup)

. "$PSScriptRoot\SDK.ps1"

# Assumes ISO was already built (artifacts.iso populated)
# Run autoinstall tests (ISO path queried from artifacts automatically)
$result = $SDK.Autoinstall.Test.Run(@{
    Network = "Ethernet"  # optional overrides
})

# Cleanup
if (-not $SkipCleanup) {
    $SDK.Autoinstall.Cleanup()
}

exit $(if ($result.Success) { 0 } else { 1 })
