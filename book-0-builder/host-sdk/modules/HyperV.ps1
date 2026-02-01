param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.HyperV -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"
    Import-Module Hyper-V

    $mod.Configurator = @{
        Defaults = @{
            CPUs = 2
            MemoryMB = 4096
            DiskGB = 40
            SSHUser = $null
            SSHHost = $null
            SSHPort = 22
            Generation = 2
        }
    }

    $HyperV = New-Object PSObject

    $SDK.Extend("HyperV", $HyperV)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
