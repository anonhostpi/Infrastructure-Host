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
                $builder_dir = Join-Path $mod.SDK.Root() "book-0-builder/builder"
                $mod.Engine = & "$builder_dir/engine.ps1" -SDK $mod.SDK
            }
            return $mod.Engine
        }
        Render = {
            param([int]$Layer = 0, [bool]$ForIso = $false)
            $engine = $this.Init()
            $book_dir = Join-Path $mod.SDK.Root() "book-0-builder"

            $paths = $engine.GetSearchPaths()
            if (-not $paths.Contains($book_dir)) {
                $paths.Add($book_dir)
                $engine.SetSearchPaths($paths)
            }

            $pkgScope = [IronPython.Hosting.Python]::ImportModule($engine, "builder.renderer")
            $scope = $pkgScope.GetVariable("renderer")

            # GetMember works on Python module objects; GetVariable only works on ScriptScope
            $discover = $engine.Operations.GetMember($scope, "discover_fragments")
            $create_env = $engine.Operations.GetMember($scope, "create_environment")
            $render = $engine.Operations.GetMember($scope, "render_cloud_init")

            $env = $engine.Operations.Invoke($create_env, $repo_root)
            $frags = $engine.Operations.Invoke($discover, $repo_root)
            $merged = $engine.Operations.Invoke($render, $ctx, $env, $frags)

            return $merged
        }
    }

    $SDK.Extend("Renderer", $Renderer)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
