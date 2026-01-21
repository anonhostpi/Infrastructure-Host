param(
    [Parameter(Mandatory = $true)]
    $SDK
)

New-Module -Name SDK.Builder -ScriptBlock {
    param(
        [Parameter(Mandatory = $true)]
        $SDK
    )

    Import-Module powershell-yaml -ErrorAction Stop
    . "$PSScriptRoot\helpers\PowerShell.ps1"
    . "$PSScriptRoot\helpers\Config.ps1"

    $mod = @{ SDK = $SDK }

    $Builder = New-Object PSObject -Property @{
        Packages = @(
            "python3-pip"
            "python3-yaml"
            "python3-jinja2"
            "make"
            "xorriso"
            "cloud-image-utils"
            "wget"
        )
    }
    Add-ScriptProperties $Builder @{
        Config = {
            return $mod.SDK.Settings.Virtualization.Builder
        }
        Defaults = {
            return @{
                CPUs = 2
                Memory = "4G"
                Disk = "40G"
                Network = "Ethernet"
            }
        }
    }
    $Builder = $SDK.Multipass.Worker($Builder)

    $Runner = New-Object PSObject -Property @{}
    Add-ScriptProperties $Runner @{
        Config = {
            return $mod.SDK.Settings.Virtualization.Runner
        }
        Defaults = {
            return @{
                CPUs = 2
                Memory = "4G"
                Disk = "15G"
                Network = "Ethernet"
            }
        }
    }
    $Runner = $SDK.Multipass.Worker($Runner)

    Add-ScriptMethods $Builder @{
        Flush = {
            $builder_destroyed = $mod.SDK.Builder.Destroy()
            $runner_destroyed = $mod.SDK.Runner.Destroy()
            return $builder_destroyed -and $runner_destroyed
        }
        InstallDependencies = {
            $apt = @(
                "sudo apt-get update -qq"
                "sudo apt-get install -y -qq $($this.Packages -join ' ') > /dev/null 2>&1"
            ) -join " && "
            $pip = @(
                "cd /home/ubuntu/infra-host"
                "pip3 install --break-system-packages -q -e . 2>/dev/null"
            ) -join " && "

            return $this.Exec($apt) -and $this.Exec($pip)
        }
        Build = {
            $make = @(
                "cd /home/ubuntu/infra-host"
                "make all"
            ) -join " && "

            return $this.Exec($make)
        }
        Stage = {
            $this.Setup()

            $mounted = if( -not $this.Mounted($mod.SDK.Root()) ) {
                $this.Mount($mod.SDK.Root(), "/home/ubuntu/infra-host")
            } else {
                $true
            }
            if( -not $mounted ) {
                throw "Failed to mount repository to builder VM"
            }
            $deps_installed = $this.InstallDependencies()
            if( -not $deps_installed ) {
                throw "Failed to install dependencies in builder VM"
            }
            return $true
        }
    }

    $SDK.Extend("Builder", $Builder)
    $SDK.Extend("Runner", $Runner)

    # Export nothing. This module only modifies the SDK object.
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force