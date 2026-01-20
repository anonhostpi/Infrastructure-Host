# VirtualBox Helper Functions for Autoinstall Testing
# Provides VM lifecycle management via VBoxManage CLI

New-Module -Name VBox-Helpers -ScriptBlock {

    # Get VBoxManage path from config or default
    function Get-VBoxManagePath {
        if ($script:VBoxManage) { return $script:VBoxManage }
        if ($global:VBoxManage) { return $global:VBoxManage }
        return "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
    }

    # Convert Windows network adapter name (e.g., "Ethernet 3") to VirtualBox bridge adapter name
    # VirtualBox uses the InterfaceDescription from Windows, sometimes with a #N suffix
    # Also handles Hyper-V virtual switches - if the adapter has an associated vEthernet, use that instead
    function Get-VBoxBridgeAdapter {
        param(
            [Parameter(Mandatory = $true)]
            [string]$WindowsAdapterName
        )

        # Get the InterfaceDescription from Windows
        $adapter = Get-NetAdapter -Name $WindowsAdapterName -ErrorAction SilentlyContinue
        if (-not $adapter) {
            Write-Warning "Windows adapter '$WindowsAdapterName' not found"
            return $null
        }

        # Check if there's a Hyper-V virtual switch for this adapter
        # Pattern: vEthernet (*Switch*($WindowsAdapterName))
        $vSwitchAdapter = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -match "^vEthernet\s*\(.*$([regex]::Escape($WindowsAdapterName)).*\)$"
        } | Select-Object -First 1

        if ($vSwitchAdapter) {
            # Use the Hyper-V virtual switch adapter instead
            $description = $vSwitchAdapter.InterfaceDescription
            Write-Host "  Detected Hyper-V virtual switch: $($vSwitchAdapter.Name)"
        } else {
            $description = $adapter.InterfaceDescription
        }

        # Get list of VirtualBox bridge adapters
        $vboxmanage = Get-VBoxManagePath
        $bridgedifs = & $vboxmanage list bridgedifs 2>&1

        # Find matching adapter (exact match or with #N suffix)
        $vboxAdapter = $bridgedifs | Where-Object { $_ -match "^Name:\s+(.+)$" } | ForEach-Object {
            if ($_ -match "^Name:\s+(.+)$") { $matches[1].Trim() }
        } | Where-Object {
            $_ -eq $description -or $_ -match "^$([regex]::Escape($description))(\s+#\d+)?$"
        } | Select-Object -First 1

        if (-not $vboxAdapter) {
            Write-Warning "No VirtualBox bridge adapter found matching '$description'"
            return $null
        }

        return $vboxAdapter
    }

    # Run VBoxManage command and return output
    function Invoke-VBoxManage {
        param(
            [Parameter(Mandatory = $true)]
            [string[]]$Arguments,
            [switch]$SuppressError
        )

        $vboxmanage = Get-VBoxManagePath
        if (-not (Test-Path $vboxmanage)) {
            throw "VBoxManage not found at: $vboxmanage"
        }

        # VBoxManage outputs progress (0%...10%...) to stderr which triggers
        # PowerShell errors when ErrorActionPreference is set to Stop
        # Temporarily set to Continue to prevent this
        $savedEAP = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'

        try {
            $result = & $vboxmanage @Arguments 2>&1
            $exitCode = $LASTEXITCODE
        } finally {
            $ErrorActionPreference = $savedEAP
        }

        # Filter out progress lines from output
        $filteredResult = $result | Where-Object {
            $_ -notmatch '^\d+%\.{3}'
        }

        return @{
            Output = $filteredResult
            ExitCode = $exitCode
        }
    }

    # Check if VM exists
    function Test-VMExists {
        param([string]$VMName)

        $result = Invoke-VBoxManage -Arguments @("list", "vms") -SuppressError
        return ($result.Output | Select-String -Pattern "^`"$VMName`"" -Quiet)
    }

    # Check if VM is running
    function Test-VMRunning {
        param([string]$VMName)

        $result = Invoke-VBoxManage -Arguments @("list", "runningvms") -SuppressError
        return ($result.Output | Select-String -Pattern "^`"$VMName`"" -Quiet)
    }

    # Create new VM for autoinstall testing
    function New-AutoinstallVM {
        param(
            [Parameter(Mandatory = $true)]
            [string]$VMName,

            [Parameter(Mandatory = $true)]
            [string]$ISOPath,

            [Parameter(Mandatory = $true)]
            [string]$VDIPath,

            [string]$CIDATAPath,

            [int]$MemoryMB = 4096,
            [int]$CPUs = 1,  # Use 1 CPU to avoid kernel soft lockup in VirtualBox
            [int]$DiskSizeMB = 40960,

            [ValidateSet("efi", "bios")]
            [string]$Firmware = "efi"
        )

        Write-Host "  Creating VM: $VMName (firmware: $Firmware)"

        # Cleanup existing VM if present
        if (Test-VMExists -VMName $VMName) {
            Remove-AutoinstallVM -VMName $VMName
        }

        # Remove existing VDI
        if (Test-Path $VDIPath) {
            Remove-Item $VDIPath -Force
        }

        # Create VM with specified firmware (efi or bios)
        Invoke-VBoxManage -Arguments @("createvm", "--name", $VMName, "--ostype", "Ubuntu_64", "--register") | Out-Null
        Invoke-VBoxManage -Arguments @("modifyvm", $VMName, "--memory", $MemoryMB, "--cpus", $CPUs, "--nic1", "nat", "--firmware", $Firmware) | Out-Null

        # Additional VM settings for stability (avoid kernel soft lockups)
        Invoke-VBoxManage -Arguments @("modifyvm", $VMName, "--pae", "on", "--nestedpaging", "on", "--hwvirtex", "on", "--largepages", "on") | Out-Null
        Invoke-VBoxManage -Arguments @("modifyvm", $VMName, "--graphicscontroller", "vmsvga", "--vram", "16") | Out-Null

        # Add storage controller
        Invoke-VBoxManage -Arguments @("storagectl", $VMName, "--name", "SATA", "--add", "sata", "--controller", "IntelAhci") | Out-Null

        # Create and attach disk
        Invoke-VBoxManage -Arguments @("createmedium", "disk", "--filename", $VDIPath, "--size", $DiskSizeMB, "--format", "VDI") | Out-Null
        Invoke-VBoxManage -Arguments @("storageattach", $VMName, "--storagectl", "SATA", "--port", "0", "--device", "0", "--type", "hdd", "--medium", $VDIPath) | Out-Null

        # Attach ISO
        Invoke-VBoxManage -Arguments @("storageattach", $VMName, "--storagectl", "SATA", "--port", "1", "--device", "0", "--type", "dvddrive", "--medium", $ISOPath) | Out-Null

        # Attach CIDATA for cloud-init nocloud datasource (Ubuntu 24.04 requires this)
        if ($CIDATAPath -and (Test-Path $CIDATAPath)) {
            # Use VDI format for SATA attachment, ISO for DVD, or floppy for raw img
            if ($CIDATAPath -match '\.vdi$') {
                Write-Host "  Attaching CIDATA VDI for cloud-init: $CIDATAPath"
                Invoke-VBoxManage -Arguments @("storageattach", $VMName, "--storagectl", "SATA", "--port", "2", "--device", "0", "--type", "hdd", "--medium", $CIDATAPath) | Out-Null
            } elseif ($CIDATAPath -match '\.iso$') {
                Write-Host "  Attaching CIDATA ISO for cloud-init: $CIDATAPath"
                Invoke-VBoxManage -Arguments @("storageattach", $VMName, "--storagectl", "SATA", "--port", "2", "--device", "0", "--type", "dvddrive", "--medium", $CIDATAPath) | Out-Null
            } else {
                Write-Host "  Attaching CIDATA floppy for cloud-init: $CIDATAPath"
                Invoke-VBoxManage -Arguments @("storagectl", $VMName, "--name", "Floppy", "--add", "floppy") | Out-Null
                Invoke-VBoxManage -Arguments @("storageattach", $VMName, "--storagectl", "Floppy", "--port", "0", "--device", "0", "--type", "fdd", "--medium", $CIDATAPath) | Out-Null
            }
        }

        Write-Host "  VM created successfully"
        return $true
    }

    # Remove VM and associated files
    function Remove-AutoinstallVM {
        param(
            [Parameter(Mandatory = $true)]
            [string]$VMName,
            [string]$VDIPath
        )

        Write-Host "  Removing VM: $VMName"

        # Stop if running
        if (Test-VMRunning -VMName $VMName) {
            Invoke-VBoxManage -Arguments @("controlvm", $VMName, "poweroff") -SuppressError | Out-Null
            Start-Sleep -Seconds 3
        }

        # Unregister and delete
        if (Test-VMExists -VMName $VMName) {
            Invoke-VBoxManage -Arguments @("unregistervm", $VMName, "--delete") -SuppressError | Out-Null
        }

        # Remove VDI if specified and exists
        if ($VDIPath -and (Test-Path $VDIPath)) {
            Remove-Item $VDIPath -Force -ErrorAction SilentlyContinue
        }

        return $true
    }

    # Start VM
    function Start-AutoinstallVM {
        param(
            [Parameter(Mandatory = $true)]
            [string]$VMName,
            [ValidateSet("gui", "headless")]
            [string]$Type = "gui"
        )

        Write-Host "  Starting VM: $VMName ($Type)"
        $result = Invoke-VBoxManage -Arguments @("startvm", $VMName, "--type", $Type)
        return ($result.ExitCode -eq 0)
    }

    # Stop VM
    function Stop-AutoinstallVM {
        param(
            [Parameter(Mandatory = $true)]
            [string]$VMName,
            [switch]$Force
        )

        if (-not (Test-VMRunning -VMName $VMName)) {
            return $true
        }

        if ($Force) {
            Write-Host "  Force stopping VM: $VMName"
            Invoke-VBoxManage -Arguments @("controlvm", $VMName, "poweroff") -SuppressError | Out-Null
        } else {
            Write-Host "  Gracefully stopping VM: $VMName"
            Invoke-VBoxManage -Arguments @("controlvm", $VMName, "acpipowerbutton") -SuppressError | Out-Null
        }

        # Wait for VM to stop
        $timeout = 60
        $elapsed = 0
        while ((Test-VMRunning -VMName $VMName) -and ($elapsed -lt $timeout)) {
            Start-Sleep -Seconds 2
            $elapsed += 2
        }

        return (-not (Test-VMRunning -VMName $VMName))
    }

    # Add SSH port forwarding
    function Add-SSHPortForward {
        param(
            [Parameter(Mandatory = $true)]
            [string]$VMName,
            [int]$HostPort = 2222,
            [int]$GuestPort = 22
        )

        Write-Host "  Adding SSH port forward: localhost:$HostPort -> VM:$GuestPort"

        # Remove existing rule if present
        Invoke-VBoxManage -Arguments @("controlvm", $VMName, "natpf1", "delete", "ssh") -SuppressError | Out-Null

        # Add new rule
        $result = Invoke-VBoxManage -Arguments @("controlvm", $VMName, "natpf1", "ssh,tcp,,$HostPort,,$GuestPort")
        return ($result.ExitCode -eq 0)
    }

    # Wait for SSH to be available
    function Wait-SSHReady {
        param(
            [string]$Host = "localhost",
            [int]$Port = 2222,
            [int]$TimeoutSeconds = 300,
            [int]$RetryIntervalSeconds = 10
        )

        Write-Host "  Waiting for SSH to be ready (timeout: ${TimeoutSeconds}s)..."

        $elapsed = 0
        while ($elapsed -lt $TimeoutSeconds) {
            # Try to connect with a short timeout
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            try {
                $asyncResult = $tcpClient.BeginConnect($Host, $Port, $null, $null)
                $waitResult = $asyncResult.AsyncWaitHandle.WaitOne(5000, $false)

                if ($waitResult -and $tcpClient.Connected) {
                    $tcpClient.Close()
                    Write-Host "  SSH is ready!"
                    return $true
                }
            } catch {
                # Connection failed, continue waiting
            } finally {
                $tcpClient.Dispose()
            }

            Start-Sleep -Seconds $RetryIntervalSeconds
            $elapsed += $RetryIntervalSeconds
            Write-Host "  Still waiting... (${elapsed}s / ${TimeoutSeconds}s)"
        }

        Write-Host "  SSH timeout after ${TimeoutSeconds}s" -ForegroundColor Yellow
        return $false
    }

    # Run command via SSH
    function Invoke-SSHCommand {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Command,

            [string]$User = "admin",
            [string]$Host = "localhost",
            [int]$Port = 2222,
            [int]$TimeoutSeconds = 60
        )

        $sshArgs = @(
            "-o", "BatchMode=yes",
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "-o", "ConnectTimeout=10",
            "-p", $Port,
            "${User}@${Host}",
            $Command
        )

        try {
            $output = & ssh @sshArgs 2>&1
            return @{
                Output = $output
                ExitCode = $LASTEXITCODE
                Success = ($LASTEXITCODE -eq 0)
            }
        } catch {
            return @{
                Output = $_.Exception.Message
                ExitCode = -1
                Success = $false
            }
        }
    }

    # Wait for installation to complete (VM reboots after install)
    function Wait-InstallComplete {
        param(
            [Parameter(Mandatory = $true)]
            [string]$VMName,
            [int]$TimeoutMinutes = 30,  # Full install with packages can take longer
            [ValidateSet("gui", "headless")]
            [string]$StartType = "gui"
        )

        Write-Host "  Waiting for autoinstall to complete (timeout: ${TimeoutMinutes}m)..."
        Write-Host "  (VM will stop/reboot when installation finishes)"

        $timeoutSeconds = $TimeoutMinutes * 60
        $elapsed = 0
        $checkInterval = 30
        $installComplete = $false

        # Phase 1: Wait for VM to stop (installation complete triggers shutdown/reboot)
        while ($elapsed -lt $timeoutSeconds) {
            if (-not (Test-VMRunning -VMName $VMName)) {
                # VM stopped - installation is complete
                Write-Host "  VM stopped - installation complete"
                $installComplete = $true
                break
            }

            Start-Sleep -Seconds $checkInterval
            $elapsed += $checkInterval
            $mins = [math]::Floor($elapsed / 60)
            $secs = $elapsed % 60
            Write-Host "  Installing... (${mins}m ${secs}s / ${TimeoutMinutes}m)"
        }

        if (-not $installComplete) {
            # VM still running after timeout - installation may be stuck
            Write-Host "  WARNING: Installation timeout - VM still running" -ForegroundColor Yellow
            return $false
        }

        # Phase 2: Eject ISO and start VM to boot from disk
        Write-Host "  Ejecting ISO to boot from installed disk..."
        Remove-DVDISO -VMName $VMName

        Write-Host "  Starting VM to boot installed system ($StartType)..."
        $result = Invoke-VBoxManage -Arguments @("startvm", $VMName, "--type", $StartType)
        if ($result.ExitCode -ne 0) {
            Write-Host "  WARNING: Failed to start VM after installation" -ForegroundColor Yellow
            return $false
        }

        # Wait for VM to fully boot
        Write-Host "  Waiting for post-install boot (30s)..."
        Start-Sleep -Seconds 30

        return (Test-VMRunning -VMName $VMName)
    }

    # Wait for cloud-init to complete
    function Wait-CloudInitComplete {
        param(
            [string]$User = "admin",
            [string]$Host = "localhost",
            [int]$Port = 2222,
            [int]$TimeoutMinutes = 10
        )

        Write-Host "  Waiting for cloud-init to complete (timeout: ${TimeoutMinutes}m)..."

        $timeoutSeconds = $TimeoutMinutes * 60
        $elapsed = 0
        $checkInterval = 15

        while ($elapsed -lt $timeoutSeconds) {
            $result = Invoke-SSHCommand -Command "cloud-init status" -User $User -Host $Host -Port $Port

            if ($result.Success) {
                $status = $result.Output -join " "
                if ($status -match "status: done") {
                    Write-Host "  Cloud-init complete!"
                    return $true
                } elseif ($status -match "status: error" -or $status -match "status: degraded") {
                    Write-Host "  Cloud-init finished with errors" -ForegroundColor Yellow
                    return $true  # Still continue with tests
                }
            }

            Start-Sleep -Seconds $checkInterval
            $elapsed += $checkInterval
            $mins = [math]::Floor($elapsed / 60)
            $secs = $elapsed % 60
            Write-Host "  Waiting... (${mins}m ${secs}s / ${TimeoutMinutes}m)"
        }

        Write-Host "  Cloud-init timeout" -ForegroundColor Yellow
        return $false
    }

    # Create snapshot
    function New-VMSnapshot {
        param(
            [Parameter(Mandatory = $true)]
            [string]$VMName,
            [Parameter(Mandatory = $true)]
            [string]$SnapshotName,
            [string]$Description = ""
        )

        Write-Host "  Creating snapshot: $SnapshotName"
        $args = @("snapshot", $VMName, "take", $SnapshotName)
        if ($Description) {
            $args += @("--description", $Description)
        }

        $result = Invoke-VBoxManage -Arguments $args
        return ($result.ExitCode -eq 0)
    }

    # Restore snapshot
    function Restore-VMSnapshot {
        param(
            [Parameter(Mandatory = $true)]
            [string]$VMName,
            [Parameter(Mandatory = $true)]
            [string]$SnapshotName
        )

        # Stop VM first if running
        if (Test-VMRunning -VMName $VMName) {
            Stop-AutoinstallVM -VMName $VMName -Force
        }

        Write-Host "  Restoring snapshot: $SnapshotName"
        $result = Invoke-VBoxManage -Arguments @("snapshot", $VMName, "restore", $SnapshotName)
        return ($result.ExitCode -eq 0)
    }

    # Eject ISO after installation
    function Remove-DVDISO {
        param(
            [Parameter(Mandatory = $true)]
            [string]$VMName
        )

        Write-Host "  Ejecting ISO from VM"
        $result = Invoke-VBoxManage -Arguments @("storageattach", $VMName, "--storagectl", "SATA", "--port", "1", "--device", "0", "--type", "dvddrive", "--medium", "emptydrive")
        return ($result.ExitCode -eq 0)
    }

    Export-ModuleMember -Function @(
        "Get-VBoxManagePath",
        "Invoke-VBoxManage",
        "Test-VMExists",
        "Test-VMRunning",
        "New-AutoinstallVM",
        "Remove-AutoinstallVM",
        "Start-AutoinstallVM",
        "Stop-AutoinstallVM",
        "Add-SSHPortForward",
        "Wait-SSHReady",
        "Invoke-SSHCommand",
        "Wait-InstallComplete",
        "Wait-CloudInitComplete",
        "New-VMSnapshot",
        "Restore-VMSnapshot",
        "Remove-DVDISO"
    )
} | Import-Module -Force
