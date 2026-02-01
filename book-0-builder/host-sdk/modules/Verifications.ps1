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
            foreach ($l in 1..$Layer) {
                foreach ($book in @("book-1-foundation", "book-2-cloud")) {
                    $pattern = Join-Path $book "*/tests/$l/verifications.ps1"
                    Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | ForEach-Object {
                        $this.Load($_.FullName)
                    }
                }
            }
        }
        Load = {
            param([string]$Path)
            & $Path -SDK $mod.SDK
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
