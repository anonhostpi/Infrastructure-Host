param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.CloudInit.Test -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $CloudInitTest = New-Object PSObject

    Add-ScriptMethods $CloudInitTest @{
        Run = {
            param([int]$Layer, [hashtable]$Overrides = @{})
            $worker = $mod.SDK.CloudInit.CreateWorker($Layer, $Overrides)
            $mod.SDK.Log.Info("Setting up cloud-init test worker: $($worker.Name)")
            $worker.Setup($true)
            $mod.SDK.Testing.Reset()
            foreach ($l in 1..$Layer) {
                foreach ($f in $mod.SDK.Fragments.At($l)) {
                    $worker.Test($f.Name, "Test $($f.Name)", $f.TestCommand, $f.ExpectedPattern)
                }
            }
            $mod.SDK.Testing.Summary()
            return @{ Success = ($mod.SDK.Testing.FailCount -eq 0); Results = $mod.SDK.Testing.Results; WorkerName = $worker.Name }
        }
    }

    $SDK.CloudInit | Add-Member -MemberType NoteProperty -Name Test -Value $CloudInitTest
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
