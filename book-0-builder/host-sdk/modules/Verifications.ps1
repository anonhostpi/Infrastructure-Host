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
            $results = @()
            foreach ($book in @("book-1-foundation", "book-2-cloud")) {
                $pattern = Join-Path $book "*/tests/$Layer/verifications.ps1"
                Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | ForEach-Object {
                    $fragDir = $_.Directory.Parent.Parent
                    $results += @{ Fragment = $fragDir.Name; Path = $_.FullName; Layer = $Layer }
                }
            }
            return $results
        }
        Register = {
            param([string]$Fragment, [int]$Layer, [System.Collections.Specialized.OrderedDictionary]$Tests)
            if (-not $mod.Tests[$Fragment]) { $mod.Tests[$Fragment] = @{} }
            if (-not $mod.Tests[$Fragment][$Layer]) { $mod.Tests[$Fragment][$Layer] = [ordered]@{} }
            foreach ($key in $Tests.Keys) {
                $mod.Tests[$Fragment][$Layer][$key] = $Tests[$key]
            }
        }
        Test = {
            param([string]$Fragment, [int]$Layer, [string]$Name, $Worker)
            $test = $mod.Tests[$Fragment][$Layer][$Name]
            if ($test) { & $test $Worker }
        }
        Load = {
            param([string]$Path)
            & $Path -SDK $mod.SDK
        }
        Run = {
            param($Worker, [int]$Layer)
            foreach ($l in 1..$Layer) {
                $layerName = $mod.SDK.Fragments.LayerName($l)
                $testFiles = $this.Discover($l)
                foreach ($entry in $testFiles) {
                    $mod.SDK.Log.Write("`n--- $layerName - $($entry.Fragment) ---", "Cyan")
                    $this.Load($entry.Path)
                    $frag = $entry.Fragment
                    if ($mod.Tests[$frag] -and $mod.Tests[$frag][$l]) {
                        foreach ($name in $mod.Tests[$frag][$l].Keys) {
                            $this.Test($frag, $l, $name, $Worker)
                        }
                    }
                }
            }
        }
    }

    $SDK.Extend("Verifications", $Verifications, $SDK.Testing)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
