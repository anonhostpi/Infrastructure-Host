param(
    [Parameter(Mandatory = $true)]
    $SDK
)

New-Module -Name SDK.Vbox -ScriptBlock {
    param(
        [Parameter(Mandatory = $true)]
        $SDK
    )

    $mod = @{ SDK = $SDK }

    . "$PSScriptRoot\helpers\PowerShell.ps1"

    $mod.Configurator = @{
        Defaults = @{
            CPUs = 2
            Memory = 4096
            Disk = 40960
            SSHUser = "ubuntu"
            SSHHost = "localhost"
            SSHPort = 2222
        }
    }

    $mod.Worker = @{
        Properties = @{
            Rendered = {
                $config = $this.Config
                $defaults = if ($this.Defaults) { $this.Defaults } else { $mod.Configurator.Defaults }
                $rendered = @{}
                foreach ($key in $defaults.Keys) { $rendered[$key] = $defaults[$key] }
                foreach ($key in $config.Keys) { $rendered[$key] = $config[$key] }
                if (-not $rendered.MediumPath) {
                    $rendered.MediumPath = "$env:TEMP\$($rendered.Name).vdi"
                }
                $this | Add-Member -MemberType NoteProperty -Name Rendered -Value $rendered -Force
                return $rendered
            }
            Name = { return $this.Rendered.Name }
            CPUs = { return $this.Rendered.CPUs }
            Memory = { return $this.Rendered.Memory }
            Disk = { return $this.Rendered.Disk }
            Network = { return $this.Rendered.Network }
            IsoPath = { return $this.Rendered.IsoPath }
            MediumPath = { return $this.Rendered.MediumPath }
            SSHUser = { return $this.Rendered.SSHUser }
            SSHHost = { return $this.Rendered.SSHHost }
            SSHPort = { return $this.Rendered.SSHPort }
        }
        Methods = @{
            Exists = { return $mod.SDK.Vbox.Exists($this.Name) }
            Running = { return $mod.SDK.Vbox.Running($this.Name) }
            Start = {
                param([string]$Type = "headless")
                return $mod.SDK.Vbox.Start($this.Name, $Type)
            }
            Shutdown = {
                param([bool]$Force)
                return $mod.SDK.Vbox.Shutdown($this.Name, $Force)
            }
            UntilShutdown = {
                param([int]$TimeoutSeconds)
                return $mod.SDK.Vbox.UntilShutdown($this.Name, $TimeoutSeconds)
            }
            Destroy = { return $mod.SDK.Vbox.Destroy($this.Name) }
            Create = {
                return $mod.SDK.Vbox.Create(
                    $this.Name,
                    $this.MediumPath,
                    $this.IsoPath,
                    $this.Network,
                    "Ubuntu_64",
                    "efi",
                    "SATA",
                    $this.Disk,
                    $this.Memory,
                    $this.CPUs
                )
            }
            Exec = {
                param([string]$Command)
                return $mod.SDK.Network.SSH($this.SSHUser, $this.SSHHost, $this.SSHPort, $Command)
            }
        }
    }

    $Vbox = New-Object PSObject

    #region: Main utilities
    Add-ScriptProperty $Vbox @{
        Path = {
            if ( -not [string]::IsNullOrWhiteSpace($script:VBoxManage) ) { return $script:VBoxManage }
            if ( -not [string]::IsNullOrWhiteSpace($global:VBoxManage) ) { return $global:VBoxManage }
            return "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
        }
    }
    Add-ScriptMethods $Vbox @{
        Invoke = {
            $path = $this.Path

            if (-not (Test-Path $path)) {
                throw "VBoxManage not found at: $path"
            }

            $EAP = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'

            try {
                $result = & $path @args 2>&1
                $exitCode = $LASTEXITCODE
            } finally {
                $ErrorActionPreference = $EAP
            }

            # Filter out progress lines from output
            $filteredResult = $result | Where-Object {
                $_ -notmatch '^\d+%\.{3}'
            }

            return @{
                Output = $filteredResult
                ExitCode = $exitCode
                Success = ($exitCode -eq 0)
            }
        }
    }

    #region: Network related methods
    Add-ScriptMethods $Vbox @{
        GetGuestAdapter = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$AdapterName
            )

            $adapter = $mod.SDK.Network.GetGuestAdapter($AdapterName)

            $bridgedifs = $this.Invoke("list", "bridgedifs").Output

            $description = $adapter.InterfaceDescription

            $vbox_adapter = $bridgedifs | ForEach-Object {
                if( $_ -match "^Name:\s+(.+)$" ){
                    return $matches[1].Trim()
                }

                return $null
            } | Where-Object {
                If( -not $_ ){ return $false }
                If( $_ -eq $description ){ return $true }
                If( $_ -match "^$([regex]::Escape($description))(\s+#\d+)?$" ){ return $true }
                return $false
            } | Select-Object -First 1

            If( -not $vbox_adapter ) {
                Write-Warning "VBox adapter for '$AdapterName' not found."
                return $null
            }

            return $vbox_adapter
        }
    }

    #region: Medium helpers
    Add-ScriptMethods $Vbox @{
        Drives = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName
            )
            
            $result = $this.Invoke("showvminfo", $VMName, "--machinereadable").Output
            
            # Match storage controller entries like "SATA-0-0"="/path/to/disk.vdi"
            # or "IDE-1-0"="/path/to/iso" - excludes "none" entries
            $drives = $result | ForEach-Object {
                if ($_ -match '^"(SATA|IDE|SCSI|SAS|NVMe|VirtIO)-(\d+)-(\d+)"=(".+")$') {
                    $ctl = $matches[1]
                    $port = $matches[2]
                    $device = $matches[3]
                    $path = $matches[4].Trim('"')

                    # One the following lines starting with "<type>-...", but not "<type>-<\d+>-<\d+>",
                    #   there will be a line like "<type>-IsEjected-<port>-<device>"="true" or "false" if it is a CD/DVD drive
                    $is_dvd = ($result | Where-Object {
                        $_ -match "^`"$ctl-IsEjected-$port-$device`"=`"(true|false)`"$"
                    }).Count -gt 0

                    return @{
                        Controller = $ctl
                        Port = [int]$port
                        Device = [int]$device
                        Path = $path
                        IsDVD = $is_dvd
                    }
                }
                return $null
            } | Where-Object { $null -ne $_ }
            
            return $drives
        }
    }

    #region: Hard drive methods
    Add-ScriptMethods $Vbox @{
        Attach = {
            param(
                [Parameter(Mandatory = $true)]
                [string] $VMName,
                [Parameter(Mandatory = $true)]
                [string] $ControllerName,
                [Parameter(Mandatory = $true)]
                [string] $MediumPath,
                [string] $Type = "hdd",
                [int] $Port,
                [int] $Device
            )

            return $this.Invoke(
                "storageattach", $VMName,
                "--storagectl", $ControllerName,
                "--port", $Port,
                "--device", $Device,
                "--type", $Type,
                "--medium", $MediumPath
            ).Success
        }
        Give = {
            param(
                [Parameter(Mandatory = $true)]
                [string] $VMName,
                [Parameter(Mandatory = $true)]
                [string] $ControllerName,
                [Parameter(Mandatory = $true)]
                [string] $MediumPath,
                [int] $Size
            )

            $result = $this.Invoke(
                "createmedium", "disk",
                "--filename", $MediumPath,
                "--size", $Size
            )
            if( -not $result.Success ){
                $msg = @(
                    "Failed to create disk medium at '$MediumPath'.",
                    "VBoxManage output:",
                    ""
                    $result.Output
                ) -join "`n"
                throw $msg
            }

            $existing = $this.Drives($VMName) | Where-Object {
                $_.Controller -eq $ControllerName
            }

            $port = 0
            $device = 0

            if( $existing.Count -gt 0 ){
                $used_ports = $existing | ForEach-Object { $_.Port }
                while( $used_ports -contains $port ){
                    $port += 1
                }
            }

            $attached = $this.Attach(
                $VMName,
                $ControllerName,
                $MediumPath,
                "hdd",
                $port,
                $device
            )
            if (-not $attached) {
                throw "Failed to attach disk medium at '$MediumPath' to VM: $VMName"
            }
        }
        Delete = {
            param(
                [Parameter(Mandatory = $true)]
                [string] $MediumPath
            )
            $this.Invoke("closemedium", "disk", $MediumPath, "--delete") | Out-Null
            If( Test-Path $MediumPath ){
                Remove-Item $MediumPath -Force
            }
        }
    }

    #region: DVD drive methods
    Add-ScriptMethods $Vbox @{
        Eject = {
            # Ejects all CD/DVD drives from the VM
            param(
                [Parameter(Mandatory = $true)]
                [string] $VMName
            )
            $dvds = $this.Drives($VMName) | Where-Object { $_.IsDVD }
            foreach( $dvd in $dvds ){
                $attached = $this.Attach(
                    $VMName,
                    $dvd.Controller,

                    "emptydrive",
                    "dvddrive",

                    $dvd.Port,
                    $dvd.Device
                )
                if (-not $attached) {
                    throw "Failed to eject DVD drive at Controller: $($dvd.Controller), Port: $($dvd.Port), Device: $($dvd.Device) from VM: $VMName"
                }
            }
        }
        Insert = {
            # Inserts the specified ISO into the primary CD/DVD drive of the VM
            param(
                [Parameter(Mandatory = $true)]
                [string] $VMName,
                [Parameter(Mandatory = $true)]
                [string] $ISOPath
            )
            $dvds = $this.Drives($VMName) | Where-Object { $_.IsDVD }
            if( $dvds.Count -eq 0 ){
                $this.Invoke(
                    "storagectl", $VMName,
                    "--name", "IDE",
                    "--add", "ide"
                ) | Out-Null
                return $this.Attach(
                    $VMName,
                    "IDE",

                    $ISOPath,
                    "dvddrive",

                    0,
                    0
                )
            }
            $dvd = $dvds | Select-Object -First 1
            $this.Attach(
                $VMName,
                $dvd.Controller,

                $ISOPath,
                "dvddrive",

                $dvd.Port,
                $dvd.Device
            )
        }
    }

    #region: VM lifecycle methods
    Add-ScriptMethods $Vbox @{
        Exists = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName
            )
            $result = $this.Invoke("list", "vms").Output
            return $result | Select-String -Pattern "^`"$VMName`"" -Quiet
        }
        Running = {
            param(
                [Parameter(Mandatory = $true)]
                [string]$VMName
            )
            If( -not $this.Exists($VMName) ){
                return $false
            }
            $result = $this.Invoke("list", "runningvms").Output
            return $result | Select-String -Pattern "^`"$VMName`"" -Quiet
        }
        Pause = {
            param(
                [Parameter(Mandatory = $true)]
                [string] $VMName
            )
            return $this.Invoke("controlvm", $VMName, "pause").Success
        }
        Resume = {
            param(
                [Parameter(Mandatory = $true)]
                [string] $VMName
            )
            return $this.Invoke("controlvm", $VMName, "resume").Success
        }
        Bump = {
            param(
                [Parameter(Mandatory = $true)]
                [string] $VMName
            )
            $paused = $this.Pause($VMName)
            if( -not $paused ){
                throw "Failed to pause VM '$VMName' for bump."
            }
            Start-Sleep -Seconds 5
            $resumed = $this.Resume($VMName)
            if( -not $resumed ){
                throw "Failed to resume VM '$VMName' after bump."
            }
            return $true
        }
        Start = {
            param(
                [Parameter(Mandatory = $true)]
                [string] $VMName,
                [ValidateSet("gui", "headless")]
                [string] $Type = "gui"
            )

            return $this.Invoke("startvm", $VMName, "--type", $Type).Success
        }
        Shutdown = {
            param(
                [Parameter(Mandatory = $true)]
                [string] $VMName,
                [bool] $Force
            )
            If ( -not $this.Running($VMName) ){
                return $true
            }
            if ($Force) {
                return $this.Invoke("controlvm", $VMName, "poweroff").Success
            } else {
                return $this.Invoke("controlvm", $VMName, "acpipowerbutton").Success
            }
        }
        UntilShutdown = {
            param(
                [Parameter(Mandatory = $true)]
                [string] $VMName,
                [int] $TimeoutSeconds
            )
            If ( -not $this.Running($VMName) ){
                return $false
            }
            # returns true if timeout reached
            return $mod.SDK.Job({
                while ( $SDK.Vbox.Running($VMName) ) {
                    Start-Sleep -Seconds 1
                }
            }, $TimeoutSeconds, @{
                VMName = $VMName
            })
        }
    }

    #region: VM configuration methods
    Add-ScriptMethods $Vbox @{
        Configure = {
            param(
                [Parameter(Mandatory = $true)]
                [string] $VMName,
                [Parameter(Mandatory = $true)]
                [System.Collections.IDictionary] $Settings
            )

            $params = @("modifyvm", $VMName)

            foreach( $key in $Settings.Keys ){
                $value = $Settings[$key]
                $params += "--$key"
                $params += "$value"
            }

            return $this.Invoke($params).Success
        }
        Optimize = {
            param(
                [Parameter(Mandatory = $true)]
                [string] $VMName
            )

            return $this.Configure($VMName, @{
                "pae" = "on"
                "nestedpaging" = "on"
                "hwvirtex" = "on"
                "largepages" = "on"
            }) -and $this.Configure($VMName, @{
                "graphicscontroller" = "vmsvga"
                "vram" = "16"
            })
        }
        Hypervisor = {
            param(
                [Parameter(Mandatory = $true)]
                [string] $VMName
            )

            return $this.Configure($VMName, @{
                "nested-hw-virt" = "on"
            })
        }
    }

    #region: VM destruction and creation methods
    Add-ScriptMethods $Vbox @{
        Destroy = {
            param(
                [Parameter(Mandatory = $true)]
                [string] $VMName
            )
            If( $this.Running($VMName) ){
                $this.Shutdown($VMName, $true) | Out-Null
                $this.UntilShutdown($VMName, 60) | Out-Null
            }
            If( $this.Exists($VMName) ){
                $drives = $this.Drives($VMName)
                $this.Invoke("unregistervm", $VMName, "--delete") | Out-Null
                foreach( $drive in $drives ){
                    $this.Delete($drive.Path) | Out-Null
                }
            }
        }
        Create = {
            param(
                [Parameter(Mandatory = $true)]
                [string] $VMName,
                [Parameter(Mandatory = $true)]
                [string] $MediumPath,
                [string] $DVDPath,
                [string] $AdapterName,
                [string] $OSType = "Ubuntu_64",
                [ValidateSet("efi", "bios")]
                [string] $Firmware = "efi",
                [string] $ControllerName = "SATA",
                [int] $Size = 40960,
                [int] $RAM = 4096,
                [int] $CPU = 2,
                [bool] $Optimize = $true,
                [bool] $Hypervisor = $true
            )
            try {
                $result = $this.Invoke(
                    "createvm",
                    "--name", $VMName,
                    "--ostype", $OSType,
                    "--register"
                )

                if( -not $result.Success ){
                    $msg = @(
                        "Failed to create VM '$VMName'.",
                        "VBoxManage output:",
                        ""
                        $result.Output
                    ) -join "`n"
                    throw $msg
                }

                $configured = $this.Configure($VMName, @{
                    "memory" = $RAM
                    "cpus" = $CPU
                    "firmware" = $Firmware
                })
                if( -not $configured ){
                    throw "Failed to configure VM '$VMName' after creation."
                }

                $adapter = $this.GetGuestAdapter($AdapterName)
                if( $adapter ){
                    $configured = $this.Configure($VMName, @{
                        "nic1" = "bridged"
                        "bridgeadapter1" = $adapter
                    })
                    if( -not $configured ){
                        throw "Failed to configure network adapter for VM '$VMName'."
                    }
                } else {
                    If( -not [string]::IsNullOrWhiteSpace($AdapterName) ){
                        Write-Warning "Could not find adapter '$AdapterName' for VM '$VMName'. Using NAT instead."
                    }
                    $configured = $this.Configure($VMName, @{
                        "nic1" = "nat"
                    })
                    if( -not $configured ){
                        throw "Failed to configure network adapter for VM '$VMName'."
                    }
                }

                $result = $this.Invoke(
                    "storagectl", $VMName,
                    "--name", $ControllerName,
                    "--add", "sata",
                    "--controller", "IntelAhci"
                )
                if( -not $result.Success ){
                    $msg = @(
                        "Failed to create storage controller '$ControllerName' for VM '$VMName'.",
                        "VBoxManage output:",
                        ""
                        $result.Output
                    ) -join "`n"
                    throw $msg
                }

                $this.Give(
                    $VMName,
                    $ControllerName,
                    $MediumPath,
                    $Size
                )

                if ($Optimize) {
                    $configured = $this.Optimize($VMName) | Out-Null
                    if (-not $configured) {
                        throw "Failed to optimize VM '$VMName' after creation."
                    }
                }
                if ($Hypervisor) {
                    $configured = $this.Hypervisor($VMName) | Out-Null
                    if (-not $configured) {
                        throw "Failed to enable nested virtualization for VM '$VMName' after creation."
                    }
                }

                if( Test-Path $DVDPath ){
                    $inserted = $this.Insert(
                        $VMName,
                        $DVDPath
                    )
                    if( -not $inserted ){
                        throw "Failed to insert DVD '$DVDPath' into VM '$VMName'."
                    }
                }
            } catch {
                Write-Error "Error creating VM '$VMName': $_"
                return $false
            }
        }
    }

    $SDK.Extend("Vbox", $Vbox)
    
    # Export nothing. This module only modifies the SDK object.
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force