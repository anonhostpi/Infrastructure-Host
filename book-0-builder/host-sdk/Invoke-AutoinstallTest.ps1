param([switch]$SkipCleanup)

. "$PSScriptRoot\SDK.ps1"

# Assumes ISO was already built (artifacts.iso populated)
# Run autoinstall tests (ISO path queried from artifacts automatically)
$result = $SDK.AutoinstallTest.Run(@{
    Network = "Ethernet"  # optional overrides
})

# Cleanup
if (-not $SkipCleanup) {
    $SDK.AutoinstallTest.Cleanup()
}

exit $(if ($result.Success) { 0 } else { 1 })
