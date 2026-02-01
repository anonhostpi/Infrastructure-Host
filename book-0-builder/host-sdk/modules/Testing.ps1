param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.Testing -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $Testing = New-Object PSObject -Property @{ Results = @(); PassCount = 0; FailCount = 0 }

    Add-ScriptProperties $Testing @{
        All = {
            return $mod.SDK.Fragments.Layers | ForEach-Object { $_.Layer } | Sort-Object -Unique
        }
    }

    Add-ScriptMethods $Testing @{
        Reset = {
            $this.Results = @()
            $this.PassCount = 0
            $this.FailCount = 0
        }
        Record = {
            param([hashtable]$Result)
            $this.Results += $Result
            if ($Result.Pass) { $this.PassCount++ } else { $this.FailCount++ }
        }
        Summary = {
            $mod.SDK.Log.Write("")
            $mod.SDK.Log.Write("========================================", "Cyan")
            $mod.SDK.Log.Write(" Test Summary", "Cyan")
            $mod.SDK.Log.Write("========================================", "Cyan")
            $mod.SDK.Log.Write("  Total:  $($this.PassCount + $this.FailCount)")
            $mod.SDK.Log.Write("  Passed: $($this.PassCount)", "Green")
            $failColor = if ($this.FailCount -gt 0) { "Red" } else { "Green" }
            $mod.SDK.Log.Write("  Failed: $($this.FailCount)", $failColor)
        }
        Fragments = {
            param([int]$Layer)
            return $mod.SDK.Fragments.UpTo($Layer) | ForEach-Object { $_.Name }
        }
        LevelName = {
            param([int]$Layer)
            return $mod.SDK.Fragments.LayerName($Layer)
        }
        LevelFragments = {
            param([int]$Layer)
            return $mod.SDK.Fragments.UpTo($Layer) | ForEach-Object { $_.Name }
        }
        IncludeArgs = {
            param([int]$Layer)
            $fragments = $this.LevelFragments($Layer)
            return ($fragments | ForEach-Object { "-i $_" }) -join " "
        }
    }

    $SDK.Extend("Testing", $Testing)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
