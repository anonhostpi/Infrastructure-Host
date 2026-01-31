param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.Testing.Verifications -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK; Tests = [ordered]@{} }
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
            param([System.Collections.Specialized.OrderedDictionary]$Tests)
            foreach ($key in $Tests.Keys) {
                $mod.Tests[$key] = $Tests[$key]
            }
        }
        Test = {
            param([string]$Name)
            $test = $mod.Tests[$Name]
            if ($test) { & $test }
        }
        Load = {
            param([string]$Path)
            $mod.Pending = @{}
            & $Path -SDK $mod.SDK
            return $mod.Pending
        }
        Run = {
            param($Worker, [int]$Layer)
            foreach ($l in 1..$Layer) {
                $layerName = $mod.SDK.Fragments.LayerName($l)
                $testFiles = $this.Discover($l)
                foreach ($entry in $testFiles) {
                    $mod.SDK.Log.Write("`n--- $layerName - $($entry.Fragment) ---", "Cyan")
                    $tests = $this.Load($entry.Path)
                    foreach ($id in $tests.Keys | Sort-Object) {
                        $test = $tests[$id]
                        $Worker.Test($id, $test.Name, $test.Command, $test.Pattern)
                    }
                }
            }
        }
    }

    $SDK.Extend("Verifications", $Verifications, $SDK.Testing)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
