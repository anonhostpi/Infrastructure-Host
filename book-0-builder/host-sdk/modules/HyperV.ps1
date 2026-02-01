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
            Name = { return $this.Rendered.Name }
            CPUs = { return $this.Rendered.CPUs }
            MemoryMB = { return $this.Rendered.MemoryMB }
            DiskGB = { return $this.Rendered.DiskGB }
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
                    $null,
                    $this.Network,
                    $this.Generation,
                    $this.DiskGB,
                    $this.MemoryMB,
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
        GetSwitch = {
            param([string]$SwitchName)
            if ($SwitchName) {
                $sw = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
                if ($sw) { return $sw.Name }
            }
            $ext = Get-VMSwitch -SwitchType External -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($ext) { return $ext.Name }
            return $null
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
            param([string]$VMName, [string]$Path, [int]$SizeGB, [string]$ControllerType = "SCSI")
            try {
                New-VHD -Path $Path -SizeBytes ($SizeGB * 1GB) -Dynamic -ErrorAction Stop | Out-Null
            } catch {
                throw "Failed to create VHD at '$Path': $_"
            }
            $attached = $this.Attach($VMName, $Path, $ControllerType)
            if (-not $attached) {
                throw "Failed to attach VHD '$Path' to VM: $VMName"
            }
        }
    }

    $SDK.Extend("HyperV", $HyperV)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
