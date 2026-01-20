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

    . "$PSScriptRoot\helpers\VBox.ps1"
    . "$PSScriptRoot\helpers\PowerShell.ps1"

    $Vbox = New-Object PSObject

    #region: Main utility method
    Add-ScriptMethods $Vbox @{
        Invoke = {
            return Invoke-VBoxManage -Arguments $args
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
            ).ExitCode -eq 0
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

            $this.Invoke(
                "createmedium", "disk",
                "--filename", $MediumPath,
                "--size", $Size
            ) | Out-Null

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

            $this.Attach(
                $VMName,
                $ControllerName,
                $MediumPath,
                "hdd",
                $port,
                $device
            ) | Out-Null
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
            return $this.Invoke("controlvm", $VMName, "pause").ExitCode -eq 0
        }
        Resume = {
            param(
                [Parameter(Mandatory = $true)]
                [string] $VMName
            )
            return $this.Invoke("controlvm", $VMName, "resume").ExitCode -eq 0
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

            return $this.Invoke("startvm", $VMName, "--type", $Type).ExitCode -eq 0
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
                return $this.Invoke("controlvm", $VMName, "poweroff").ExitCode -eq 0
            } else {
                return $this.Invoke("controlvm", $VMName, "acpipowerbutton").ExitCode -eq 0
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

            return $this.Invoke($params).ExitCode -eq 0
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
            $this.Invoke(
                "createvm",
                "--name", $VMName,
                "--ostype", $OSType,
                "--register"
            ) | Out-Null

            $this.Configure($VMName, @{
                "memory" = $RAM
                "cpus" = $CPU
                "firmware" = $Firmware
            }) | Out-Null

            $adapter = $this.GetGuestAdapter($AdapterName)
            if( $adapter ){
                $this.Configure($VMName, @{
                    "nic1" = "bridged"
                    "bridgeadapter1" = $adapter
                }) | Out-Null
            } else {
                If( -not [string]::IsNullOrWhiteSpace($AdapterName) ){
                    Write-Warning "Could not find adapter '$AdapterName' for VM '$VMName'. Using NAT instead."
                }
                $this.Configure($VMName, @{
                    "nic1" = "nat"
                }) | Out-Null
            }

            $this.Invoke(
                "storagectl", $VMName,
                "--name", $ControllerName,
                "--add", "sata",
                "--controller", "IntelAhci"
            ) | Out-Null

            $this.Give(
                $VMName,
                $ControllerName,
                $MediumPath,
                $Size
            )

            if ($Optimize) {
                $this.Optimize($VMName) | Out-Null
            }
            if ($Hypervisor) {
                $this.Hypervisor($VMName) | Out-Null
            }

            if( Test-Path $DVDPath ){
                $this.Insert(
                    $VMName,
                    $DVDPath
                ) | Out-Null
            }
        }
    }

    $SDK.Extend("Vbox", $Vbox)
    
    # Export nothing. This module only modifies the SDK object.
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force