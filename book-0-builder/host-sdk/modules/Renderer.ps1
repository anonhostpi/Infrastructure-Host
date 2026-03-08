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
            $ipy_dir = Join-Path $mod.SDK.Root() "book-0-builder/ipy"
            $ctx = $mod.SDK.Settings.BuildConfig.Clone()
            $ctx['__repo_root__'] = $mod.SDK.Root()
            foreach ($k in ($ExtraCtx.Keys | ForEach-Object { $_ })) {
                $ctx[$k] = $ExtraCtx[$k]
            }
            $json_ctx = $ctx | ConvertTo-Json -Depth 20
            $result = $engine.Execute("
import sys, os
sys.path.insert(0, r'$ipy_dir')
sys.stdin = __import__('io').StringIO($($json_ctx | ConvertTo-Json))
exec(open(r'$ipy_dir/renderer.py').read())
")
            return $result
        }
    }

    $SDK.Extend("Renderer", $Renderer)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
