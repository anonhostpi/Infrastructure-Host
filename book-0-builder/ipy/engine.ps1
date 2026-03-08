param(
    [Parameter(Mandatory = $true)]
    $SDK
)

#region MARK: Bootstrap IronPython
$ipy_loader = Invoke-WebRequest 'https://raw.githubusercontent.com/anonhostpi/IronPythonEmbedded/main/IronPythonEmbedded.ps1' -UseBasicParsing
$ipy_engine = & ([scriptblock]::Create($ipy_loader.Content))
#endregion

#region MARK: Load ipy.Yaml
$ipy_yaml_loader = Invoke-WebRequest 'https://raw.githubusercontent.com/anonhostpi/ipy.Yaml/main/ipy.Yaml.ps1' -UseBasicParsing
& ([scriptblock]::Create($ipy_yaml_loader.Content)) -Engine $ipy_engine
#endregion

#region MARK: Load ipy.Jinja
$ipy_jinja_loader = Invoke-WebRequest 'https://raw.githubusercontent.com/anonhostpi/ipy.Jinja/main/ipy.Jinja.ps1' -UseBasicParsing
& ([scriptblock]::Create($ipy_jinja_loader.Content)) -Engine $ipy_engine
#endregion

return $ipy_engine
