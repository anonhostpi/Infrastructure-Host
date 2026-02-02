param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.Autoinstall.Test -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $AutoinstallTest = New-Object PSObject

    Add-ScriptMethods $AutoinstallTest @{
        Run = {
            param(
                [int]$Layer,
                [string[]]$Hypervisors = @("Vbox", "HyperV"),
                [hashtable]$Overrides = @{}
            )
            $mod.SDK.CloudInit.Test.Run($Layer, $Overrides)
            foreach ($hypervisor in $Hypervisors) {
                $config = $mod.SDK.Settings.Virtualization."$hypervisor"
                if (-not $config) { continue }
                $worker = $mod.SDK.Builder.Runner($config, $hypervisor, $Layer)
                $mod.SDK.Testing.Verifications.Run($worker, $Layer, 1)
            }
        }
    }

    $mod.SDK.Extend("Test", $AutoinstallTest, $mod.SDK.Autoinstall)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
