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

    $mod = @{ SDK = $SDK; Engine = $null }
    $mod.Runners = @{}

    $Builder = New-Object PSObject -Property @{
        Packages = @(
            "python3-pip"
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
            $path = "$($mod.SDK.Root())/output/artifacts.yaml"
            if (Test-Path $path) {
                return Get-Content $path -Raw | ConvertFrom-Yaml
            }
            return $null
        }
    }
    $Builder = $SDK.Multipass.Worker($Builder)

    Add-ScriptMethods $Builder @{
        Engine = {
            if ($null -eq $mod.Engine) {
                # Bootstrap IronPython + packages
                $nuget = "$($mod.SDK.Root())/book-0-builder/host-sdk/helpers/NuGet.ps1"
                . $nuget
                $mod.Engine = Install-IronPython

                # Install required packages
                Install-IpyPackage $mod.Engine "ruamel.yaml"
                Install-IpyPackage $mod.Engine "jinja2"

                # Add builder package to search paths
                $book_dir = "$($mod.SDK.Root())/book-0-builder"
                $paths = $mod.Engine.GetSearchPaths()
                if (-not $paths.Contains($book_dir)) {
                    $paths.Add($book_dir)
                    $mod.Engine.SetSearchPaths($paths)
                }
            }
            return $mod.Engine
        }
        Render = {
            param(
                [string]$OutputPath,
                [int]$Layer = 0,
                [bool]$ForIso = $false
            )
            $engine = $this.Engine()

            $rPkg = [IronPython.Hosting.Python]::ImportModule($engine, "builder.renderer")
            $renderer = $rPkg.GetVariable("renderer")
            $cPkg = [IronPython.Hosting.Python]::ImportModule($engine, "builder.context")
            $context = $cPkg.GetVariable("context")
            $BuildContext = $engine.Operations.GetMember($context, "BuildContext")
            $ctx = $engine.Operations.Invoke($BuildContext)

            $pyLayer = if ($Layer -gt 0) { $Layer } else { $null }

            if ($OutputPath) {
                $renderFn = $engine.Operations.GetMember($renderer, "render_cloud_init_to_file")
                $engine.Operations.Invoke($renderFn, $ctx, $OutputPath, $null, $null, $pyLayer)
            } else {
                $renderFn = $engine.Operations.GetMember($renderer, "render_cloud_init")
                return $engine.Operations.Invoke($renderFn, $ctx, $null, $null, $pyLayer, $ForIso)
            }
        }
        RenderAutoinstallToFile = {
            param(
                [string]$OutputPath
            )
            $engine = $this.Engine()

            $rPkg = [IronPython.Hosting.Python]::ImportModule($engine, "builder.renderer")
            $renderer = $rPkg.GetVariable("renderer")
            $cPkg = [IronPython.Hosting.Python]::ImportModule($engine, "builder.context")
            $context = $cPkg.GetVariable("context")
            $BuildContext = $engine.Operations.GetMember($context, "BuildContext")
            $ctx = $engine.Operations.Invoke($BuildContext)

            $renderFn = $engine.Operations.GetMember($renderer, "render_autoinstall_to_file")
            $engine.Operations.Invoke($renderFn, $ctx, $OutputPath)
        }
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
            $outputDir = "$($mod.SDK.Root())/output"
            if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir | Out-Null }
            if ($Layer) {
                $output = "$outputDir/cloud-init.yaml"
                $this.Render($output, $Layer)
                return $true
            }
            # Full build (make all) still requires VM
            $this.Clean()
            $make = @("cd /home/ubuntu/infra-host", "make all") -join " && "
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
            param(
                [hashtable]$Config,
                [string]$Backend = "Multipass",
                [int]$Layer = 0
            )
            $config = @{}
            foreach ($k in ($Config.Keys | ForEach-Object { $_ })) { $config[$k] = $Config[$k] }
            $artifacts = $this.Artifacts
            $artifactKey = if ($Backend -eq "Multipass") { "cloud_init" } else { "iso" }
            if (-not $artifacts -or -not $artifacts."$artifactKey") {
                $this.Build($Layer)
                $artifacts = $this.Artifacts
            }
            $configKey = if ($Backend -eq "Multipass") { "CloudInit" } else { "IsoPath" }
            if ($Backend -eq "Multipass") {
                $local = $artifacts."$artifactKey"
            } else {
                $remote = $artifacts."$artifactKey"
                $local = "$($mod.SDK.Root())/output/$(Split-Path $remote -Leaf)"
                $this.Pull($remote, $local)
            }
            $config."$configKey" = $local
            $worker = $mod.SDK."$Backend".Worker(@{ Config = $config })
            $this.Register($config.Name, $worker)
            $worker.Setup($true)
            return $worker
        }
    }

    $SDK.Extend("Builder", $Builder)

    # Export nothing. This module only modifies the SDK object.
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
