param(
    [Parameter(Mandatory = $true)]
    $SDK
)

New-Module -Name SDK.Multipass -ScriptBlock {
    param(
        [Parameter(Mandatory = $true)]
        $SDK
    )

    $mod = @{ SDK = $SDK }

    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    $mod.Configurator = @{
        Defaulter = {
            param(
                $Table = @{},
                $Defaults = @{}
            )

            $converted = @{
                table = (ConvertTo-OrderedHashtable $Table)
                defaults = (ConvertTo-OrderedHashtable $Defaults)
            }

            $result = [ordered]@{}
            $keys = (& {
                $converted.defaults.Keys | ForEach-Object { $_ }
                $converted.table.Keys | ForEach-Object { $_ }
            }) | Sort-Object -Unique
            foreach( $key in $keys ) {
                $tVal = $converted.table[$key]
                $dVal = $converted.defaults[$key]

                $result[$key] = if ($tVal -is [System.Collections.IDictionary] -and $dVal -is [System.Collections.IDictionary]) {
                    & $mod.Configurator.Defaulter $tVal $dVal
                } elseif ($null -ne $tVal) {
                    $tVal
                } else {
                    $dVal
                }
            }
            return $result
        }
        Defaults = @{
            CPUs = 2
            Memory = "4G"
            Disk = "40G"
        }
    }
    $mod.Worker = @{
        Properties = @{
            #region: Worker COnfiguration
            Rendered = {
                $config = $this.Config
                $defaults = $this.Defaults
                if( $null -eq $defaults ){
                    $defaults = $mod.Configurator.Defaults
                }
                $rendered = & $mod.Configurator.Defaulter $config $defaults
                $this | Add-Member -MemberType NoteProperty -Name Rendered -Value $rendered -Force
                return $rendered
            }
            Name = {
                return $this.Rendered.Name
            }
            CPUs = {
                return $this.Rendered.CPUs
            }
            Memory = {
                return $this.Rendered.Memory
            }
            Disk = {
                return $this.Rendered.Disk
            }
            Network = {
                return $this.Rendered.Network
            }
            CloudInit = {
                return $this.Rendered.CloudInit
            }
        }
        Methods = @{
            #region: Worker VM Info
            Info = {
                return $mod.SDK.Multipass.Info($this.Name)
            }
            Addresses = {
                return $mod.SDK.Multipass.Addresses($this.Name)
            }
            Address = {
                return $mod.SDK.Multipass.Address($this.Name)
            }

            #region: Worker VM Lifecycle
            Exists = {
                return $mod.SDK.Multipass.Exists($this.Name)
            }
            Running = {
                return $mod.SDK.Multipass.Running($this.Name)
            }
            Create = {
                $config = $this.Rendered
                return $mod.SDK.Multipass.Create(
                    $this.Name,
                    $config.CloudInit,
                    $config.Network,
                    $config.CPUs,
                    $config.Memory,
                    $config.Disk
                )
            }
            Destroy = {
                if( -not $this.Exists() ) { return $true }

                $name = $this.Name
                $shutdown_called_successfully = $this.Shutdown($true)
                if( -not $shutdown_called_successfully ) {
                    throw "Failed to shutdown VM '$name'"
                }
                $timed_out = $this.UntilShutdown(60)
                if( $timed_out ) {
                    throw "Timed out waiting for VM '$name' to shutdown"
                }
                return $mod.SDK.Multipass.Destroy($name)
            }
            Start = {
                return $mod.SDK.Multipass.Start($this.Name)
            }
            Shutdown = {
                param( [bool]$Force )
                return $mod.SDK.Multipass.Shutdown($this.Name, $Force)
            }
            UntilShutdown = {
                param( [int] $TimeoutSeconds )
                return $mod.SDK.Multipass.UntilShutdown($this.Name, $TimeoutSeconds)
            }
            
            #region: Worker Cloud-Init
            Status = {
                return $mod.SDK.Multipass.Status($this.Name)
            }
            UntilInstalled = {
                return $mod.SDK.Multipass.UntilInstalled($this.Name)
            }
            Setup = {
                param( [bool]$FailOnNotInitialized )
                $created = $this.Ensure()
                if( -not $created ) {
                    throw "Failed to create VM '$($this.Name)'"
                }
                $initialized = $this.UntilInstalled()
                if( -not $initialized -and $FailOnNotInitialized ) {
                    throw "Cloud-init failed for VM '$($this.Name)'"
                }
                return $initialized
            }

            #region: Worker File Sharing
            Mount = {
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$SourcePath,
                    [Parameter(Mandatory = $true)]
                    [string]$TargetPath
                )
                return $mod.SDK.Multipass.Mount($this.Name, $SourcePath, $TargetPath)
            }
            Unmount = {
                param(
                    [string]$TargetPath
                )
                return $mod.SDK.Multipass.Unmount($this.Name, $TargetPath)
            }
            Mounts = {
                return $mod.SDK.Multipass.Mounts($this.Name)
            }
            Mounted = {
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$HostPath
                )
                return $mod.SDK.Multipass.Mounted($this.Name, $HostPath)
            }
            Pull = {
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$Source,
                    [Parameter(Mandatory = $true)]
                    [string]$Destination
                )
                return $mod.SDK.Multipass.Transfer("$(this.Name):$($Source)", $Destination)
            }
            Push = {
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$Source,
                    [Parameter(Mandatory = $true)]
                    [string]$Destination
                )
                return $mod.SDK.Multipass.Transfer($Source, "$(this.Name):$($Destination)")
            }

            #region: Worker Command Execution
            Exec = {
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$Command,
                    [string]$WorkingDir
                )
                return $mod.SDK.Multipass.Exec($this.Name, $Command, $WorkingDir)
            }
            Shell = {
                return $mod.SDK.Multipass.Shell($this.Name)
            }
        }
    }

    $Multipass = New-Object PSObject

    #region: Main utility methods
    Add-ScriptMethods $Multipass @{
        Invoke = {

            $output = & multipass @args 2>&1
            return @{
                Output = $output
                ExitCode = $LASTEXITCODE
                Success = $LASTEXITCODE -eq 0
            }
        }
        Worker = {
            param(
                [Parameter(Mandatory = $true)]
                [ValidateScript({ $null -ne $_.Config })]
                $Base
            )

            $worker = If( $Base -is [System.Collections.IDictionary] ){
                New-Object PSObject -Property $Base
            } Else {
                $Base
            }

            Add-ScriptProperties $worker $mod.Worker.Properties
            Add-ScriptMethods $worker $mod.Worker.Methods

            Add-CommonWorkerMethods $worker

            return $worker
        }
    }

    #region: VM info methods
    Add-ScriptMethods $Multipass @{
        Info = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName,
                [string]$Format = "json"
            )
            $result = $this.Invoke("info", $VMName, "--format", $Format)
            if ($Format -eq "json" -and $result.Success) {
                return $result.Output | ConvertFrom-Json
            }
            return $result
        }
        Addresses = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName
            )
            $info = $this.Info($VMName, "json")
            if ($info -and $info.$VMName -and $info.$VMName.ipv4) {
                return $info.$VMName.ipv4
            }
            return @()
        }
        Address = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName
            )
            return ($this.Addresses($VMName) | Select-Object -First 1)
        }
        List = {
            $result = $this.Invoke("list", "--format", "csv")

            if (-not $result.Success) {
                return @()
            }
            return $result.Output | ConvertFrom-Csv
        }
        Status = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName
            )
            $result = $this.Exec($VMName, "cloud-init status")
            return $result.Output
        }
        Mounts = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName
            )
            $info = $this.Info($VMName, "json")
            if ($info -and $info.$VMName -and $info.$VMName.mounts) {
                return $info.$VMName.mounts
            }
            return @()
        }
        Mounted = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName,
                [Parameter(Mandatory = $true)]
                [string]$HostPath
            )
            $mounts = $this.Mounts($VMName)
            return $mounts.PSObject.Properties | Where-Object { $_.Value.source_path -eq $HostPath }
        }
    }

    #region: VM lifecycle methods
    Add-ScriptMethods $Multipass @{
        Exists = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName
            )
            $list = $this.List()
            return ($list | Where-Object { $_.Name -eq $VMName }).Count -gt 0
        }
        Running = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName
            )
            if (-not $this.Exists($VMName)) {
                return $false
            }
            $list = $this.List()
            $vm = $list | Where-Object { $_.Name -eq $VMName }
            return "Running" -eq $vm.State
        }
        Start = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName
            )
            return $this.Invoke("start", $VMName).Success
        }
        UntilInstalled = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName
            )
            $result = $this.Exec($VMName, "cloud-init status --wait")
            return $result.Success
        }
        Shutdown = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName,
                [bool]$Force = $false
            )
            if ($Force) {
                return $this.Invoke("stop", "--force", $VMName).Success
            } else {
                return $this.Invoke("stop", $VMName).Success
            }
        }
        UntilShutdown = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName,
                [int]$TimeoutSeconds = 60
            )
            if (-not $this.Running($VMName)) {
                return $false
            }
            # Returns true if timeout reached
            return $mod.SDK.Job({
                while ($SDK.Multipass.Running($VMName)) {
                    Start-Sleep -Seconds 1
                }
            }, $TimeoutSeconds, @{
                VMName = $VMName
            })
        }
    }

    #region: VM creation and destruction
    Add-ScriptMethods $Multipass @{
        Create = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName,
                [string]$CloudInitPath,
                [string]$Network,
                [int]$CPUs = 2,
                [string]$Memory = "4G",
                [string]$Disk = "40G",
                [string]$Image = ""  # Empty uses default Ubuntu LTS
            )

            $launchArgs = @("launch", "--name", $VMName, "--cpus", $CPUs, "--memory", $Memory, "--disk", $Disk)

            if (-not [string]::IsNullOrWhiteSpace($Network)) {
                $launchArgs += @("--network", $Network)
            }

            if (-not [string]::IsNullOrWhiteSpace($CloudInitPath) -and (Test-Path $CloudInitPath)) {
                $launchArgs += @("--cloud-init", $CloudInitPath)
            }

            if (-not [string]::IsNullOrWhiteSpace($Image)) {
                $launchArgs += $Image
            }

            $result = $this.Invoke($launchArgs)
            return $result.Success
        }
        Destroy = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName
            )
            if ($this.Exists($VMName)) {
                $this.Invoke("delete", "--purge", $VMName) | Out-Null
            }
        }
        Purge = {
            return $this.Invoke("purge").Success
        }
    }

    #region: VM file sharing methods
    Add-ScriptMethods $Multipass @{
        Mount = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName,
                [Parameter(Mandatory = $true)]
                [string]$HostPath,
                [Parameter(Mandatory = $true)]
                [string]$GuestPath
            )
            return $this.Invoke("mount", $HostPath, "${VMName}:${GuestPath}").Success
        }
        Unmount = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName,
                [string]$GuestPath
            )
            if ([string]::IsNullOrWhiteSpace($GuestPath)) {
                return $this.Invoke("unmount", $VMName).Success
            } else {
                return $this.Invoke("unmount", "${VMName}:${GuestPath}").Success
            }
        }
        Transfer = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$Source,
                [Parameter(Mandatory = $true)]
                [string]$Destination
            )
            return $this.Invoke("transfer", $Source, $Destination).Success
        }
    }

    #region: Command execution
    Add-ScriptMethods $Multipass @{
        Exec = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName,
                [Parameter(Mandatory = $true)]
                [string]$Command,
                [string]$WorkingDir
            )
            $execArgs = @("exec", $VMName)
            if (-not [string]::IsNullOrWhiteSpace($WorkingDir)) {
                $execArgs += @("--working-directory", $WorkingDir)
            }
            $execArgs += @("--", "bash", "-c", $Command)
            return $this.Invoke($execArgs)
        }
        Shell = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName
            )
            # This starts an interactive shell - mainly for manual use
            & multipass shell $VMName
        }
    }

    $SDK.Extend("Multipass", $Multipass)

    # Export nothing. This module only modifies the SDK object.
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
