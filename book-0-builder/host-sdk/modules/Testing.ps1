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
    }

    $SDK.Extend("Testing", $Testing)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
