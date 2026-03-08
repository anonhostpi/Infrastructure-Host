param(
    [Parameter(Mandatory = $true)]
    $SDK
)

$ipy_dir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Bootstrap IronPython + packages via IronPythonEmbedded
$nuget = Join-Path $SDK.Root() "book-0-builder/host-sdk/helpers/NuGet.ps1"
. $nuget

$engine = Install-IronPython

# Install required packages
Install-IpyPackage $engine "ruamel.yaml"
Install-IpyPackage $engine "jinja2"

return $engine
