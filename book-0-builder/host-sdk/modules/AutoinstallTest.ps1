param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.Autoinstall.Test -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $AutoinstallTest = New-Object PSObject

    Add-ScriptMethods $AutoinstallTest @{
        Run = {
            param([hashtable]$Overrides = @{})
            $worker = $mod.SDK.Autoinstall.CreateWorker($Overrides)
            $mod.SDK.Log.Info("Setting up autoinstall test worker: $($worker.Name)")
            $worker.Ensure(); $worker.Start()
            $mod.SDK.Log.Info("Waiting for SSH availability...")
            $mod.SDK.Network.WaitForSSH($worker.SSHHost, $worker.SSHPort, 600)
            $mod.SDK.Testing.Reset()
            foreach ($f in $mod.SDK.Fragments.IsoRequired()) {
                $worker.Test($f.Name, "Test $($f.Name)", $f.TestCommand, $f.ExpectedPattern)
            }
            $mod.SDK.Testing.Summary()
            return @{ Success = ($mod.SDK.Testing.FailCount -eq 0); Results = $mod.SDK.Testing.Results; WorkerName = $worker.Name }
        }
    }

    $SDK.Autoinstall | Add-Member -MemberType NoteProperty -Name Test -Value $AutoinstallTest
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
