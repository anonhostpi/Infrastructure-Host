param(
    [Parameter(Mandatory = $true)]
    $SDK
)

New-Module -Name SDK.Builder -ScriptBlock {
    param(
        [Parameter(Mandatory = $true)]
        $SDK
    )

    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $mod = @{ SDK = $SDK }
    $mod.Runners = @{}

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
        Artifacts = {
            $path = Join-Path $mod.SDK.Root() "output/artifacts.yaml"
            if (Test-Path $path) {
                return Get-Content $path -Raw | ConvertFrom-Yaml
            }
            return $null
        }
    }
    $Builder = $SDK.Multipass.Worker($Builder)

    Add-ScriptMethods $Builder @{
        Clean = {
            $make = @("cd /home/ubuntu/infra-host", "make clean") -join " && "
            return $this.Exec($make).Success
        }
        Flush = {
            foreach ($name in ($mod.Runners.Keys | ForEach-Object { $_ })) {
                $runner = $mod.Runners[$name]
                if ($runner -and $runner.Exists()) {
                    $runner.Destroy()
                }
            }
            $mod.Runners = @{}
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
        Register = {
            param([string]$Name, $Worker)
            $mod.Runners[$Name] = $Worker
            return $Worker
        }
        Runner = {
            param([hashtable]$Config, [string]$Backend = "Multipass", [int]$Layer = 0)
            $config = @{}
            foreach ($k in ($Config.Keys | ForEach-Object { $_ })) { $config[$k] = $Config[$k] }
            $artifacts = $this.Artifacts
            $artifactKey = if ($Backend -eq "Multipass") { "cloud_init" } else { "iso" }
            if (-not $artifacts -or -not $artifacts.$artifactKey) {
                $this.Build($Layer)
                $artifacts = $this.Artifacts
                if (-not $artifacts -or -not $artifacts.$artifactKey) {
                    throw "No $artifactKey artifact found after build"
                }
            }
            if ($Backend -eq "Multipass") {
                $remote = $artifacts.cloud_init
                $local = Join-Path $mod.SDK.Root() "output" (Split-Path $remote -Leaf)
                $this.Pull($remote, $local)
                $config.CloudInit = $local
            } else {
                $remote = $artifacts.iso
                $local = Join-Path $mod.SDK.Root() "output" (Split-Path $remote -Leaf)
                $this.Pull($remote, $local)
                $config.IsoPath = $local
            }
            $worker = $mod.SDK."$Backend".Worker(@{ Config = $config })
            $this.Register($config.Name, $worker)
            return $worker
        }
    }

    $SDK.Extend("Builder", $Builder)

    # Export nothing. This module only modifies the SDK object.
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force