param(
    [Parameter(Mandatory = $true)]
    $SDK
)

New-Module -Name SDK.Renderer -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK; Engine = $null }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $Renderer = New-Object PSObject

    Add-ScriptMethods $Renderer @{
        Init = {
            if ($null -eq $mod.Engine) {
                $ipy_dir = Join-Path $mod.SDK.Root() "book-0-builder/ipy"
                $mod.Engine = & "$ipy_dir/engine.ps1" -SDK $mod.SDK
            }
            return $mod.Engine
        }
        Render = {
            param([hashtable]$ExtraCtx = @{})
            $engine = $this.Init()
            $book_dir = Join-Path $mod.SDK.Root() "book-0-builder"
            $repo_root = $mod.SDK.Root()

            # Add ipy/ parent to search paths so engine can find the package
            $paths = $engine.GetSearchPaths()
            if (-not $paths.Contains($book_dir)) {
                $paths.Add($book_dir)
                $engine.SetSearchPaths($paths)
            }

            # Import the renderer module
            $scope = [IronPython.Hosting.Python]::ImportModule($engine, "ipy.renderer")

            # Build context and call the rendering pipeline
            $ctx = $mod.SDK.Settings.BuildConfig.Clone()
            foreach ($k in ($ExtraCtx.Keys | ForEach-Object { $_ })) {
                $ctx[$k] = $ExtraCtx[$k]
            }

            $discover = $scope.GetVariable("discover_fragments")
            $create_env = $scope.GetVariable("create_environment")
            $render = $scope.GetVariable("render_cloud_init")

            $env = $engine.Operations.Invoke($create_env, $repo_root)
            $frags = $engine.Operations.Invoke($discover, $repo_root)
            $merged = $engine.Operations.Invoke($render, $ctx, $env, $frags)

            return $merged
        }
    }

    $SDK.Extend("Renderer", $Renderer)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
