param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.Testing.Verifications -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $Verifications = New-Object PSObject

    Add-ScriptMethods $Verifications @{
        Fork = {
            param([string]$Test, [string]$Decision, [string]$Reason = "")
            $msg = "[FORK] $Test : $Decision"
            if ($Reason) { $msg += " ($Reason)" }
            $mod.SDK.Log.Debug($msg)
        }
    }

    Add-ScriptMethods $Verifications @{
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
    }

    $SDK.Extend("Verifications", $Verifications, $SDK.Testing)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
