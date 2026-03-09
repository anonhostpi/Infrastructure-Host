## Test IronPython embedded route (canonical SetSearchPaths + ImportModule pattern)
##
## Usage:
##    cd <repo-root>
##    pwsh tests/ipy.embedded.ps1
##
## Requires:
##    - PowerShell 7+ (pwsh) — IronPython 3.4.2 DLLs are .NET 6+
##    - IronPython 3.4.2 DLLs in $env:USERPROFILE
##    - ruamel.yaml + Jinja2 in ~/ipyenv/v3.4.2/lib/site-packages (or equivalent)

$ErrorActionPreference = 'Stop'
$ipyDir = $env:USERPROFILE

# Load assemblies in dependency order
$dlls = @(
    'Microsoft.Dynamic.dll',
    'Microsoft.Scripting.dll',
    'IronPython.dll',
    'IronPython.Modules.dll'
)
foreach ($dll in $dlls) {
    try {
        [System.Reflection.Assembly]::LoadFrom("$ipyDir\$dll") | Out-Null
        Write-Host "  Loaded: $dll"
    } catch {
        Write-Host "  FAIL loading ${dll}: $_"
        exit 1
    }
}

# Create engine
$engine = [IronPython.Hosting.Python]::CreateEngine()

Write-Host "=== IronPython Embedded Test ==="
Write-Host "  Engine: $($engine.LanguageVersion)"

# Set search paths: ipy lib + site-packages + book-0-builder (parent of ipy/)
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$paths = $engine.GetSearchPaths()
$paths.Add("$ipyDir\lib")
$paths.Add("$ipyDir\lib\site-packages")
$paths.Add("$repoRoot\book-0-builder")
$engine.SetSearchPaths($paths)

Write-Host "  Search paths:"
foreach ($p in $engine.GetSearchPaths()) {
    Write-Host "    - $p"
}

# Level 1: Import
Write-Host ''
Write-Host "=== Level 1: Import Test ==="
try {
    # ImportModule("builder.renderer") returns the top-level ipy package scope.
    # We need to get the renderer submodule from it.
    $pkgScope = [IronPython.Hosting.Python]::ImportModule($engine, "builder.renderer")
    Write-Host "  ImportModule('builder.renderer'): OK"

    # Get the renderer submodule from the package scope
    $scope = $pkgScope.GetVariable("renderer")
    Write-Host "  GetVariable('renderer'): OK"
} catch {
    Write-Host "  builder.renderer: FAIL - $_"
    exit 1
}

# Level 2: Discover fragments
Write-Host ''
Write-Host "=== Level 2: Discover Fragments ==="
try {
    $discover = $engine.Operations.GetMember($scope, "discover_fragments")
    $frags = $engine.Operations.Invoke($discover, $repoRoot)
    Write-Host "  Found $($frags.__len__()) fragments"
    foreach ($f in $frags) {
        $name = $f['name']
        $order = $f['build_order']
        Write-Host "    - $name (order: $order)"
    }
} catch {
    Write-Host "  FAIL: $_"
}

# Level 3: Create environment
Write-Host ''
Write-Host "=== Level 3: Create Environment ==="
try {
    $createEnv = $engine.Operations.GetMember($scope, "create_environment")
    $env = $engine.Operations.Invoke($createEnv, $repoRoot)
    Write-Host "  Jinja2 env created"

    # Check custom filters exist
    $customFilters = @('shell_quote', 'shell_array', 'sha512_hash', 'ip_only', 'cidr_only', 'to_yaml', 'to_base64')
    $missing = @()
    foreach ($f in $customFilters) {
        if (-not $env.filters.ContainsKey($f)) {
            $missing += $f
        }
    }
    if ($missing.Count -gt 0) {
        Write-Host "  FAIL: Missing filters: $($missing -join ', ')"
    } else {
        Write-Host "  All custom filters registered"
    }
} catch {
    Write-Host "  FAIL: $_"
}

Write-Host ''
Write-Host "ALL TESTS COMPLETE"
