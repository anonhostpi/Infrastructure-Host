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

    $mod.Worker = @{
        Properties = @{
            Rendered = {
                $config = $this.Config
                $defaults = if ($this.Defaults) { $this.Defaults } else { $mod.Configurator.Defaults }
                $rendered = @{}
                foreach ($key in ($defaults.Keys | ForEach-Object { $_ })) { $rendered[$key] = $defaults[$key] }
                foreach ($key in ($config.Keys | ForEach-Object { $_ })) { $rendered[$key] = $config[$key] }
                if (-not $rendered.SSHUser -or -not $rendered.SSHHost) {
                    $identity = $mod.SDK.Settings.Load("book-2-cloud/users/config/identity.config.yaml")
                    $network = $mod.SDK.Settings.Load("book-2-cloud/network/config/network.config.yaml")
                    if (-not $rendered.SSHUser) { $rendered.SSHUser = $identity.identity.username }
                    if (-not $rendered.SSHHost) {
                        $ip = $network.network.ip_address -replace '/\d+$', ''
                        $rendered.SSHHost = $ip
                    }
                }
                if (-not $rendered.MediumPath) {
                    $rendered.MediumPath = "$env:TEMP\$($rendered.Name).vhdx"
                }
                $this | Add-Member -MemberType NoteProperty -Name Rendered -Value $rendered -Force
                return $rendered
            }
        }
    }

    $HyperV = New-Object PSObject

    $SDK.Extend("HyperV", $HyperV)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
