# VirtualBox Helper Functions for Autoinstall Testing
# Provides VM lifecycle management via VBoxManage CLI

New-Module -Name VBox-Helpers -ScriptBlock {

    . "$PSScriptRoot\SDK.ps1"

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
            [string[]]$Arguments
        )

        return $SDK.Vbox.Invoke($Arguments)
    }

    # Check if VM exists
    function Test-VMExists {
        param([string]$VMName)

        return $SDK.Vbox.Exists($VMName)
    }

    # Check if VM is running
    function Test-VMRunning {
        param([string]$VMName)

        return $SDK.Vbox.Running($VMName)
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
            [string]$Firmware = "efi",

            # Network mode: "nat" for isolated testing, "bridged" for real network access
            [ValidateSet("nat", "bridged")]
            [string]$NetworkMode = "bridged",

            # Host network adapter for bridged mode (e.g., "Ethernet", "Wi-Fi")
            [string]$BridgeAdapter = "Ethernet"
        )

        Write-Host "  Creating VM: $VMName (firmware: $Firmware)"

        # Cleanup existing VM if present
        if (Test-VMExists -VMName $VMName) {
            Remove-AutoinstallVM -VMName $VMName
        }

        # Remove existing VDI (close from media registry first, then delete file)
        if (Test-Path $VDIPath) {
            Try {
                $SDK.Vbox.Delete($VDIPath)
            } Catch {
                Write-Warning "  Failed to delete existing VDI: $VDIPath"
            }
        }

        $SDK.Vbox.Create(
            $VMName,
            $VDIPath,
            $ISOPath,
            $BridgeAdapter,
            "Ubuntu_64",
            $Firmware,
            "SATA", $DiskSizeMB,
            $MemoryMB, $CPUs,
            $true,
            $true
        )

        Write-Host "  VM created successfully"
        return $true
    }

    # Remove VM and associated files
    function Remove-AutoinstallVM {
        param(
            [Parameter(Mandatory = $true)]
            [string]$VMName
        )

        Write-Host "  Removing VM: $VMName"

        $SDK.Vbox.Destroy($VMName)
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
        return $SDK.Vbox.Start($VMName, $Type)
    }

    # Stop VM
    function Stop-AutoinstallVM {
        param(
            [Parameter(Mandatory = $true)]
            [string]$VMName,
            [switch]$Force
        )

        if ($Force) {
            Write-Host "  Force stopping VM: $VMName"
            $SDK.Vbox.Shutdown($VMName, $true) | Out-Null
        } else {
            Write-Host "  Gracefully stopping VM: $VMName"
            $SDK.Vbox.Shutdown($VMName, $false) | Out-Null
        }

        # Wait for VM to stop
        $timeout = 60

        return (-not ($SDK.Vbox.UntilShutdown($VMName, $timeout)))
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
        Try {
            $SDK.Vbox.Eject($VMName) | Out-Null
            return $true
        } Catch {
            Write-Warning "  Failed to eject ISO from VM: $VMName"
            return $false
        }
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
