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
        Render = { }  # WIP
    }

    $SDK.Extend("Renderer", $Renderer)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
