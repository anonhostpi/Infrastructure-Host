param(
    [Parameter(Mandatory = $true)]
    $SDK
)

New-Module -Name SDK.Builder -ScriptBlock {
    param(
        [Parameter(Mandatory = $true)]
        $SDK
    )

    . "$PSScriptRoot\helpers\PowerShell.ps1"

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

    Add-ScriptMethods $Builder @{
        Clean = {
            $make = @("cd /home/ubuntu/infra-host", "make clean") -join " && "
            return $this.Exec($make).Success
        }
        Flush = {
            return $this.Destroy()
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

            $apt_result = $this.Exec($apt)
            $pip_result = $this.Exec($pip)

            return $apt_result.Success -and $pip_result.Success
        }
        Build = {
            param([int]$Layer)
            $this.Clean()  # Always clean before build
            $target = if ($Layer) { "make cloud-init LAYER=$Layer" } else { "make all" }
            $make = @("cd /home/ubuntu/infra-host", $target) -join " && "
            return $this.Exec($make).Success
        }
        Stage = {
            $setup_success = $this.Setup($true)
            if( -not $setup_success ) {
                throw "Failed to initialize builder VM"
            }

            $mounted = if( $null -eq $this.Mounted($mod.SDK.Root()) ) {
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
        LayerName = {
            param([int]$Layer)
            if ($mod.AgentDependent -and $mod.AgentDependent.ContainsKey($Layer)) {
                return $mod.AgentDependent[$Layer].name
            }
            if ($mod.LayerNames -and $mod.LayerNames.ContainsKey($Layer)) {
                return $mod.LayerNames[$Layer]
            }
            return "Layer $Layer"
        }
        LayerFragments = {
            param([int]$Layer)
            # Agent-dependent levels use override fragments
            if ($mod.AgentDependent -and $mod.AgentDependent.ContainsKey($Layer)) {
                return $mod.AgentDependent[$Layer].fragments
            }
            # Normal levels derive from build_layer via Fragments module
            return $mod.SDK.Fragments.UpTo($Layer) | ForEach-Object { $_.Name }
        }
    }

    $SDK.Extend("Builder", $Builder)

    # Export nothing. This module only modifies the SDK object.
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force