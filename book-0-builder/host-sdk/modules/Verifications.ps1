param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.Testing.Verifications -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK; Tests = @{} }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $Verifications = New-Object PSObject

    Add-ScriptMethods $Verifications @{
        Fork = {
            param([string]$Test, [string]$Decision, [string]$Reason = "")
            $msg = "[FORK] $Test : $Decision"
            if ($Reason) { $msg += " ($Reason)" }
            $mod.SDK.Log.Debug($msg)
        }
        Discover = {
            param([int]$Layer)
            foreach ($l in 0..$Layer) {
                foreach ($bookDir in @("book-1-foundation", "book-2-cloud")) {
                    $bookNum = if ($bookDir -match 'book-(\d+)') { [int]$matches[1] } else { 0 }
                    $pattern = Join-Path $bookDir "*/tests/$l/verifications.ps1"
                    Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | ForEach-Object {
                        $this.Load($_.FullName, $l, $bookNum)
                    }
                }
            }
        }
        Load = {
            param([string]$Path, [int]$Layer, [int]$Book)
            $module = & $Path -SDK $mod.SDK
            $tests = & $module { $mod.Tests }
            if (-not $tests) { return }
            $fragDir = Split-Path (Split-Path (Split-Path $Path))
            $buildYaml = Join-Path $fragDir "build.yaml"
            $meta = Get-Content $buildYaml -Raw | ConvertFrom-Yaml
            $order = $meta.build_order
            if (-not $mod.Tests[$Layer]) { $mod.Tests[$Layer] = @{} }
            if (-not $mod.Tests[$Layer][$Book]) { $mod.Tests[$Layer][$Book] = @{} }
            $mod.Tests[$Layer][$Book][$order] = $tests
        }
        Run = {
            param($Worker, [int]$Layer)
            $this.Discover($Layer)
            foreach ($l in 1..$Layer) {
                $layerName = $mod.SDK.Fragments.LayerName($l)
                foreach ($frag in ($mod.Tests.Keys | ForEach-Object { $_ })) {
                    if (-not $mod.Tests[$frag][$l]) { continue }
                    $mod.SDK.Log.Write("`n--- $layerName - $frag ---", "Cyan")
                    foreach ($name in ($mod.Tests[$frag][$l].Keys | ForEach-Object { $_ })) {
                        $this.Test($frag, $l, $name, $Worker)
                    }
                }
            }
        }
    }

    $SDK.Extend("Verifications", $Verifications, $SDK.Testing)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
