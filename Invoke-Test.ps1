param([int]$Layer, [switch]$SkipCleanup, [switch]$SkipSDK, [switch]$SkipCloudInit, [switch]$SkipAutoinstall)

$ErrorActionPreference = "Stop"
$repoRoot = $PSScriptRoot

if (-not $SkipSDK) { }
if (-not $SkipCloudInit) { }
if (-not $SkipAutoinstall) { }

exit 0
