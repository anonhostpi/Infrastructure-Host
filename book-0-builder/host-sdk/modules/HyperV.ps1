param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.HyperV -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"
    Import-Module Hyper-V

    $mod.Configurator = @{
        Defaults = @{
            CPUs = 2
            Memory = 4096
            Disk = 40960
            IsoPath = $null
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
            Name = { return $this.Rendered.Name }
            CPUs = { return $this.Rendered.CPUs }
            Memory = { return $this.Rendered.Memory }
            Disk = { return $this.Rendered.Disk }
            IsoPath = { return $this.Rendered.IsoPath }
            Network = { return $this.Rendered.Network }
            MediumPath = { return $this.Rendered.MediumPath }
            SSHUser = { return $this.Rendered.SSHUser }
            SSHHost = { return $this.Rendered.SSHHost }
            SSHPort = { return $this.Rendered.SSHPort }
            Generation = { return $this.Rendered.Generation }
        }
        Methods = @{
            Exists = { return $mod.SDK.HyperV.Exists($this.Name) }
            Running = { return $mod.SDK.HyperV.Running($this.Name) }
            Start = { return $mod.SDK.HyperV.Start($this.Name) }
            Shutdown = {
                param([bool]$Force)
                return $mod.SDK.HyperV.Shutdown($this.Name, $Force)
            }
            UntilShutdown = {
                param([int]$TimeoutSeconds)
                return $mod.SDK.HyperV.UntilShutdown($this.Name, $TimeoutSeconds)
            }
            Destroy = { return $mod.SDK.HyperV.Destroy($this.Name) }
            Create = {
                return $mod.SDK.HyperV.Create(
                    $this.Name,
                    $this.MediumPath,
                    $this.IsoPath,
                    $this.Network,
                    $this.Generation,
                    "efi",
                    $this.Disk,
                    $this.Memory,
                    $this.CPUs
                )
            }
        }
    }

    $HyperV = New-Object PSObject

    Add-ScriptMethods $HyperV @{
        Worker = {
            param(
                [Parameter(Mandatory = $true)]
                [ValidateScript({ $null -ne $_.Config })]
                $Base
            )
            $worker = If ($Base -is [System.Collections.IDictionary]) {
                New-Object PSObject -Property $Base
            } Else { $Base }
            Add-ScriptProperties $worker $mod.Worker.Properties
            Add-ScriptMethods $worker $mod.Worker.Methods
            $mod.SDK.Worker.Methods($worker)
            return $worker
        }
    }

    Add-ScriptMethods $HyperV @{
        Elevated = {
            $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
            $principal = New-Object Security.Principal.WindowsPrincipal($identity)
            return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        }
    }

    Add-ScriptMethods $HyperV @{
        GetGuestAdapter = {
            param([Parameter(Mandatory = $true)] [string]$AdapterName)
            $adapter = $mod.SDK.Network.GetGuestAdapter($AdapterName)
            if (-not $adapter) { return $null }
            $physical = Get-NetAdapter -Name $AdapterName -ErrorAction SilentlyContinue
            $description = if ($physical) { $physical.InterfaceDescription } else { $adapter.InterfaceDescription }
            $switches = Get-VMSwitch -SwitchType External -ErrorAction SilentlyContinue
            $match = $switches | Where-Object {
                $_.NetAdapterInterfaceDescription -eq $description -or
                $_.NetAdapterInterfaceDescription -match "^$([regex]::Escape($description))(\s+#\d+)?$"
            } | Select-Object -First 1
            if (-not $match) {
                Write-Warning "VMSwitch for adapter '$AdapterName' not found."
                return $null
            }
            return $match.Name
        }
        Drives = {
            param([string]$VMName)
            $all = @()
            foreach ($d in (Get-VMHardDiskDrive -VMName $VMName)) {
                $all += @{ Controller = $d.ControllerType; Port = $d.ControllerNumber; Path = $d.Path; IsDVD = $false }
            }
            foreach ($d in (Get-VMDvdDrive -VMName $VMName)) {
                $all += @{ Controller = $d.ControllerType; Port = $d.ControllerNumber; Path = $d.Path; IsDVD = $true }
            }
            return $all
        }
        Attach = {
            param([string]$VMName, [string]$Path, [string]$ControllerType = "SCSI")
            try {
                Add-VMHardDiskDrive -VMName $VMName -Path $Path -ControllerType $ControllerType -ErrorAction Stop
                return $true
            } catch { return $false }
        }
        Delete = {
            param([string]$VMName, [string]$Path)
            $drive = Get-VMHardDiskDrive -VMName $VMName | Where-Object { $_.Path -eq $Path }
            if ($drive) { Remove-VMHardDiskDrive -VMHardDiskDrive $drive }
            if (Test-Path $Path) { Remove-Item $Path -Force }
        }
        Give = {
            param([string]$VMName, [string]$Path, [int]$Size, [string]$ControllerType = "SCSI")
            try {
                New-VHD -Path $Path -SizeBytes ($Size * 1MB) -Dynamic -ErrorAction Stop | Out-Null
            } catch {
                throw "Failed to create VHD at '$Path': $_"
            }
            $attached = $this.Attach($VMName, $Path, $ControllerType)
            if (-not $attached) {
                throw "Failed to attach VHD '$Path' to VM: $VMName"
            }
        }
        Eject = {
            param([string]$VMName)
            foreach ($dvd in (Get-VMDvdDrive -VMName $VMName)) {
                Set-VMDvdDrive -VMDvdDrive $dvd -Path $null
            }
        }
        Insert = {
            param([string]$VMName, [string]$ISOPath)
            $dvds = Get-VMDvdDrive -VMName $VMName
            if ($dvds.Count -eq 0) {
                Add-VMDvdDrive -VMName $VMName -Path $ISOPath
            } else {
                Set-VMDvdDrive -VMDvdDrive ($dvds | Select-Object -First 1) -Path $ISOPath
            }
        }
        Exists = {
            param([string]$VMName)
            return $null -ne (Get-VM -Name $VMName -ErrorAction SilentlyContinue)
        }
        Running = {
            param([string]$VMName)
            if (-not $this.Exists($VMName)) { return $false }
            return (Get-VM -Name $VMName).State -eq 'Running'
        }
        Pause = {
            param([string]$VMName)
            try { Suspend-VM -Name $VMName -ErrorAction Stop; return $true } catch { return $false }
        }
        Resume = {
            param([string]$VMName)
            try { Resume-VM -Name $VMName -ErrorAction Stop; return $true } catch { return $false }
        }
        Bump = {
            param([string]$VMName)
            $paused = $this.Pause($VMName)
            if (-not $paused) { throw "Failed to pause VM '$VMName' for bump." }
            Start-Sleep -Seconds 5
            $resumed = $this.Resume($VMName)
            if (-not $resumed) { throw "Failed to resume VM '$VMName' after bump." }
            return $true
        }
        Start = {
            param([string]$VMName)
            try { Start-VM -Name $VMName -ErrorAction Stop; return $true } catch { return $false }
        }
        Shutdown = {
            param([string]$VMName, [bool]$Force)
            if (-not $this.Running($VMName)) { return $true }
            try {
                if ($Force) { Stop-VM -Name $VMName -TurnOff -Force -ErrorAction Stop }
                else { Stop-VM -Name $VMName -Force -ErrorAction Stop }
                return $true
            } catch { return $false }
        }
        UntilShutdown = {
            param([string]$VMName, [int]$TimeoutSeconds)
            if (-not $this.Running($VMName)) { return $false }
            return $mod.SDK.Job({
                while ($SDK.HyperV.Running($VMName)) {
                    Start-Sleep -Seconds 1
                }
            }, $TimeoutSeconds, @{
                VMName = $VMName
            })
        }
        SetProcessor = {
            param([string]$VMName, [hashtable]$Settings)
            $s = @{ VMName = $VMName }
            foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) {
                switch ($key) {
                    "cpus" { $s.Count = $Settings[$key] }
                    "nested-hw-virt" {
                        $s.ExposeVirtualizationExtensions = $Settings[$key] -eq "on"
                    }
                    { $_ -in @("Count","ExposeVirtualizationExtensions") } {
                        $s[$key] = $Settings[$key]
                    }
                    { $_ -in @("pae","nestedpaging","hwvirtex","largepages","graphicscontroller","vram") } {} # VBox only
                }
            }
            try { Set-VMProcessor @s -ErrorAction Stop; return $true } catch { return $false }
        }
        SetMemory = {
            param([string]$VMName, [hashtable]$Settings)
            $s = @{ VMName = $VMName }
            foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) {
                switch ($key) {
                    "MemoryMB" { $s.StartupBytes = $Settings[$key] * 1MB }
                    "MemoryGB" { $s.StartupBytes = $Settings[$key] * 1GB }
                    "memory" { $s.StartupBytes = $Settings[$key] * 1MB }
                    { $_ -in @("DynamicMemoryEnabled","StartupBytes") } { $s[$key] = $Settings[$key] }
                }
            }
            try { Set-VMMemory @s -ErrorAction Stop; return $true } catch { return $false }
        }
        SetNetworkAdapter = {
            param([string]$VMName, [hashtable]$Settings)
            $s = @{ VMName = $VMName }
            foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) {
                switch ($key) {
                    { $_ -in @("MacAddressSpoofing") } { $s[$key] = $Settings[$key] }
                    { $_ -in @("nic1","bridgeadapter1") } {} # VBox only
                }
            }
            try { Set-VMNetworkAdapter @s -ErrorAction Stop; return $true } catch { return $false }
        }
        SetFirmware = {
            param([string]$VMName, [hashtable]$Settings)
            $s = @{ VMName = $VMName }
            foreach ($key in ($Settings.Keys | ForEach-Object { $_ })) {
                switch ($key) {
                    { $_ -in @("EnableSecureBoot","SecureBootTemplate") } { $s[$key] = $Settings[$key] }
                    { $_ -in @("Firmware","firmware") } {
                        if ($Settings[$key] -eq "efi") {
                            $s.EnableSecureBoot = "On"
                        } else {
                            Write-Warning "HyperV Gen2 does not support BIOS firmware"
                        }
                    }
                }
            }
            try { Set-VMFirmware @s -ErrorAction Stop; return $true } catch { return $false }
        }
        Optimize = {
            param([string]$VMName)
            return $this.SetProcessor($VMName, @{
                ExposeVirtualizationExtensions = $false
            })
        }
        Hypervisor = {
            param([string]$VMName)
            return $this.SetProcessor($VMName, @{
                ExposeVirtualizationExtensions = $true
            }) -and $this.SetMemory($VMName, @{
                DynamicMemoryEnabled = $false
            }) -and $this.SetNetworkAdapter($VMName, @{
                MacAddressSpoofing = "On"
            })
        }
        Destroy = {
            param([string]$VMName)
            if ($this.Running($VMName)) {
                $this.Shutdown($VMName, $true) | Out-Null
                $this.UntilShutdown($VMName, 60) | Out-Null
            }
            if ($this.Exists($VMName)) {
                $drives = $this.Drives($VMName)
                Remove-VM -Name $VMName -Force
                foreach ($d in $drives) {
                    if ($d.Path -and (Test-Path $d.Path)) { Remove-Item $d.Path -Force }
                }
            }
        }
        Create = {
            param(
                [string]$VMName, [string]$MediumPath, [string]$DVDPath,
                [string]$AdapterName, [int]$Generation = 2,
                [string]$Firmware = "efi",
                [int]$Size = 40960, [int]$RAM = 4096, [int]$CPU = 2,
                [bool]$Optimize = $true, [bool]$Hypervisor = $true
            )
            try {
                $memBytes = $RAM * 1MB
                $diskBytes = $Size * 1MB
                New-VM -Name $VMName -MemoryStartupBytes $memBytes -Generation $Generation -NewVHDPath $MediumPath -NewVHDSizeBytes $diskBytes -ErrorAction Stop | Out-Null
                $configured = $this.SetProcessor($VMName, @{ Count = $CPU })
                if (-not $configured) { throw "Failed to configure processor for VM '$VMName'." }
                if ($Firmware) {
                    $configured = $this.SetFirmware($VMName, @{ Firmware = $Firmware })
                    if (-not $configured) { throw "Failed to configure firmware for VM '$VMName'." }
                }
                $switch = $this.GetGuestAdapter($AdapterName)
                if ($switch) {
                    Connect-VMNetworkAdapter -VMName $VMName -SwitchName $switch
                }
                if ($Optimize) {
                    $configured = $this.Optimize($VMName)
                    if (-not $configured) { throw "Failed to optimize VM '$VMName'." }
                }
                if ($Hypervisor) {
                    $configured = $this.Hypervisor($VMName)
                    if (-not $configured) { throw "Failed to enable nested virtualization for VM '$VMName'." }
                }
                if ($DVDPath -and (Test-Path $DVDPath)) {
                    Add-VMDvdDrive -VMName $VMName -Path $DVDPath
                }
            } catch {
                Write-Error "Error creating VM '$VMName': $_"
                return $false
            }
        }
    }

    $SDK.Extend("HyperV", $HyperV)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
