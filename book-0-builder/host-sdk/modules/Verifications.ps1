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
            $fragment = $mod.SDK.Fragments.Layers | Where-Object { $_.Path -eq $fragDir }
            if (-not $fragment) { throw "No fragment found for path: $fragDir" }
            $order = $fragment.Order
            if (-not $mod.Tests[$Layer]) { $mod.Tests[$Layer] = @{} }
            if (-not $mod.Tests[$Layer][$Book]) { $mod.Tests[$Layer][$Book] = @{} }
            $layerName = $mod.SDK.Fragments.LayerName($Layer)
            $tracker = New-Object PSObject -Property @{
                Book     = $Book
                Layer    = $layerName
                Fragment = $fragment.Name
            }
            $mod.SDK.Testing.Methods($tracker)
            $mod.Tests[$Layer][$Book][$order] = @{
                Tests   = $tests
                Tracker = $tracker
            }
        }
        Run = {
            param($Runner, [int]$Layer, $Book = $null)
            $this.Discover($Layer)
            $bookOrder = if ($null -ne $Book) { @($Book) } else { @(1, 2) }
            foreach ($l in 0..$Layer) {
                if (-not $mod.Tests[$l]) { continue }
                foreach ($b in $bookOrder) {
                    if (-not $mod.Tests[$l][$b]) { continue }
                    foreach ($order in ($mod.Tests[$l][$b].Keys | ForEach-Object { $_ } | Sort-Object)) {
                        $batch = $mod.Tests[$l][$b][$order]
                        $tests = $batch.Tests
                        foreach ($name in ($tests.Keys | ForEach-Object { $_ })) {
                            & $tests[$name] $Runner $batch.Tracker
                        }
                    }
                }
            }
        }
    }

    $SDK.Extend("Verifications", $Verifications, $SDK.Testing)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
