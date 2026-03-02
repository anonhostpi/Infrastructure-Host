param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.Testing -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $Testing = New-Object PSObject -Property @{ Trackers = @() }

    Add-ScriptProperties $Testing @{
        All = {
            return $mod.SDK.Fragments.Layers | ForEach-Object { $_.Layer } | Sort-Object -Unique
        }
    }

    Add-ScriptMethods $Testing @{
        Methods = {
            param($Target)
            $Target | Add-Member -MemberType NoteProperty -Name Results   -Value @() -Force
            $Target | Add-Member -MemberType NoteProperty -Name PassCount -Value 0   -Force
            $Target | Add-Member -MemberType NoteProperty -Name FailCount -Value 0   -Force
            Add-ScriptMethods $Target @{
                Record  = {
                    param([hashtable]$Result)
                    $this.Results += $Result
                    if ($Result.Pass) { $this.PassCount++ } else { $this.FailCount++ }
                }
                Reset   = {
                    $this.Results   = @()
                    $this.PassCount = 0
                    $this.FailCount = 0
                }
                Summary = {
                    $mod.SDK.Log.Write("")
                    $mod.SDK.Log.Write("--- $($this.Book) / $($this.Layer) / $($this.Fragment) ---", "Cyan")
                    $mod.SDK.Log.Write("  Total:  $($this.PassCount + $this.FailCount)")
                    $mod.SDK.Log.Write("  Passed: $($this.PassCount)", "Green")
                    $failColor = if ($this.FailCount -gt 0) { "Red" } else { "Green" }
                    $mod.SDK.Log.Write("  Failed: $($this.FailCount)", $failColor)
                }
            }
            $this.Trackers += $Target
        }
        Summary = {
            $totalPass = ($this.Trackers | Measure-Object -Property PassCount -Sum).Sum
            $totalFail = ($this.Trackers | Measure-Object -Property FailCount -Sum).Sum
            $mod.SDK.Log.Write("")
            $mod.SDK.Log.Write("========================================", "Cyan")
            $mod.SDK.Log.Write(" Test Summary", "Cyan")
            $mod.SDK.Log.Write("========================================", "Cyan")
            foreach ($tracker in $this.Trackers) {
                if ($tracker.Results.Count -gt 0) { $tracker.Summary() }
            }
            $mod.SDK.Log.Write("----------------------------------------", "Cyan")
            $mod.SDK.Log.Write("  Total:  $($totalPass + $totalFail)")
            $mod.SDK.Log.Write("  Passed: $totalPass", "Green")
            $failColor = if ($totalFail -gt 0) { "Red" } else { "Green" }
            $mod.SDK.Log.Write("  Failed: $totalFail", $failColor)
            $mod.SDK.Log.Write("========================================", "Cyan")
        }
        Reset = {
            foreach ($tracker in $this.Trackers) { $tracker.Reset() }
            $this.Trackers = @()
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
