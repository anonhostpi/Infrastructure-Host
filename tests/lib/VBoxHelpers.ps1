# VirtualBox Helper Functions for Autoinstall Testing
# Provides VM lifecycle management via VBoxManage CLI

New-Module -Name VBox-Helpers -ScriptBlock {

    . "$PSScriptRoot\SDK.ps1"

    # Create new VM for autoinstall testing
    function New-AutoinstallVM {
        param(
            [Parameter(Mandatory = $true)]
            [string]$VMName,

            [Parameter(Mandatory = $true)]
            [string]$ISOPath,

            [Parameter(Mandatory = $true)]
            [string]$VDIPath,

            [int]$MemoryMB = 4096,
            [int]$CPUs = 1,  # Use 1 CPU to avoid kernel soft lockup in VirtualBox
            [int]$DiskSizeMB = 40960,

            [ValidateSet("efi", "bios")]
            [string]$Firmware = "efi",

            # Host network adapter for bridged mode (e.g., "Ethernet", "Wi-Fi")
            [string]$BridgeAdapter = "Ethernet"
        )

        Write-Host "  Creating VM: $VMName (firmware: $Firmware)"

        # Cleanup existing VM if present
        if ($SDK.Vbox.Exists($VMName)) {
            $SDK.Vbox.Destroy($VMName)
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

    # Wait for SSH to be available
    function Wait-SSHReady {
        param(
            [string]$Address = "localhost",
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
                $asyncResult = $tcpClient.BeginConnect($Address, $Port, $null, $null)
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
            [string]$Address = "localhost",
            [int]$Port = 2222,
            [int]$TimeoutSeconds = 60
        )

        # Use default SSH key if available
        $sshKeyPath = Join-Path $env:USERPROFILE ".ssh\id_ed25519"
        $sshArgs = @(
            "-o", "BatchMode=yes",
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "-o", "ConnectTimeout=10"
        )
        if (Test-Path $sshKeyPath) {
            $sshArgs += @("-i", $sshKeyPath)
        }
        $sshArgs += @("-p", $Port, "${User}@${Address}", $Command)

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
            if (-not ($SDK.Vbox.Running($VMName))) {
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
            # VM still running after timeout - try pause/resume trick
            # VirtualBox sometimes gets stuck on "Loading essential drivers..."
            # Pausing and resuming kicks it out of the stuck state
            Write-Host "  VM still running - trying pause/resume workaround..." -ForegroundColor Yellow
            $SDK.Vbox.Bump($VMName) | Out-Null
            Write-Host "  Resumed VM, waiting additional 10 minutes..."

            # Wait additional 10 minutes after pause/resume
            $additionalTimeout = 600
            $additionalElapsed = 0
            while ($additionalElapsed -lt $additionalTimeout) {
                if (-not ($SDK.Vbox.Running($VMName))) {
                    Write-Host "  VM stopped - installation complete (after pause/resume)"
                    $installComplete = $true
                    break
                }

                Start-Sleep -Seconds $checkInterval
                $additionalElapsed += $checkInterval
                $mins = [math]::Floor($additionalElapsed / 60)
                $secs = $additionalElapsed % 60
                Write-Host "  Installing... (${mins}m ${secs}s / 10m after resume)"
            }

            if (-not $installComplete) {
                Write-Host "  WARNING: Installation timeout - VM still running after pause/resume" -ForegroundColor Yellow
                return $false
            }
        }

        # Phase 2: Eject ISO and start VM to boot from disk
        Write-Host "  Ejecting ISO to boot from installed disk..."
        Remove-DVDISO -VMName $VMName

        Write-Host "  Starting VM to boot installed system ($StartType)..."
        $result = $SDK.Vbox.Start($VMName, $StartType)
        if ($result.ExitCode -ne 0) {
            Write-Host "  WARNING: Failed to start VM after installation" -ForegroundColor Yellow
            return $false
        }

        # Wait for VM to fully boot
        Write-Host "  Waiting for post-install boot (30s)..."
        Start-Sleep -Seconds 30

        return ($SDK.Vbox.Running($VMName))
    }

    # Wait for cloud-init to complete
    function Wait-CloudInitComplete {
        param(
            [string]$User = "admin",
            [string]$Address = "localhost",
            [int]$Port = 2222,
            [int]$TimeoutMinutes = 10
        )

        Write-Host "  Waiting for cloud-init to complete (timeout: ${TimeoutMinutes}m)..."

        $timeoutSeconds = $TimeoutMinutes * 60
        $elapsed = 0
        $checkInterval = 15

        while ($elapsed -lt $timeoutSeconds) {
            $result = Invoke-SSHCommand -Command "cloud-init status" -User $User -Host $Address -Port $Port

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

    # Clean up multipass VMs to avoid IP conflicts with VirtualBox VMs
    # Idempotent - no-op if VMs don't exist
    function Remove-MultipassTestVMs {
        param(
            [string[]]$VMNames = @("cloud-init-runner", "cloud-init-test")
        )

        Write-Host "Cleaning up multipass test VMs..." -ForegroundColor Gray

        foreach ($vmName in $VMNames) {
            # Check if VM exists
            $vmList = multipass list --format csv 2>$null
            if ($vmList | Select-String "^$vmName,") {
                Write-Host "  Deleting: $vmName"
                multipass delete $vmName --purge 2>$null
            }
        }

        Write-Host "  Done" -ForegroundColor Green
    }

    Export-ModuleMember -Function @(
        "New-AutoinstallVM",
        "Start-AutoinstallVM",
        "Stop-AutoinstallVM",
        "Wait-SSHReady",
        "Invoke-SSHCommand",
        "Wait-InstallComplete",
        "Wait-CloudInitComplete",
        "Remove-DVDISO",
        "Remove-MultipassTestVMs"
    )
} | Import-Module -Force
