param(
    [Parameter(Mandatory = $true)]
    $SDK
)

New-Module -Name SDK.Renderer -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK; Engine = $null; RendererMod = $null; BuildContextClass = $null }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $Renderer = New-Object PSObject

    Add-ScriptMethods $Renderer @{
        Init = {
            if ($null -eq $mod.Engine) {
                $builder_dir = Join-Path $mod.SDK.Root() "book-0-builder/builder"
                $mod.Engine = & "$builder_dir/engine.ps1" -SDK $mod.SDK
                $book_dir = Join-Path $mod.SDK.Root() "book-0-builder"
                $paths = $mod.Engine.GetSearchPaths()
                if (-not $paths.Contains($book_dir)) {
                    $paths.Add($book_dir)
                    $mod.Engine.SetSearchPaths($paths)
                }
                $rPkg = [IronPython.Hosting.Python]::ImportModule($mod.Engine, "builder.renderer")
                $mod.RendererMod = $rPkg.GetVariable("renderer")
                $cPkg = [IronPython.Hosting.Python]::ImportModule($mod.Engine, "builder.context")
                $cMod = $cPkg.GetVariable("context")
                $mod.BuildContextClass = $mod.Engine.Operations.GetMember($cMod, "BuildContext")
            }
            return $mod.Engine
        }
        Render = {
            param([int]$Layer = 0, [bool]$ForIso = $false)
            $this.Init()
            $ctx = $mod.Engine.Operations.Invoke($mod.BuildContextClass)
            $render = $mod.Engine.Operations.GetMember($mod.RendererMod, "render_cloud_init")
            $pyLayer = if ($Layer -gt 0) { $Layer } else { $null }
            return $mod.Engine.Operations.Invoke($render, $ctx, $null, $null, $pyLayer, $ForIso)
        }
        RenderToFile = {
            param([string]$OutputPath, [int]$Layer = 0)
            $this.Init()
            $ctx = $mod.Engine.Operations.Invoke($mod.BuildContextClass)
            $renderFn = $mod.Engine.Operations.GetMember($mod.RendererMod, "render_cloud_init_to_file")
            $pyLayer = if ($Layer -gt 0) { $Layer } else { $null }
            $mod.Engine.Operations.Invoke($renderFn, $ctx, $OutputPath, $null, $null, $pyLayer)
        }
    }

    $SDK.Extend("Renderer", $Renderer)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
