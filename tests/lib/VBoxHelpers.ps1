# VirtualBox Helper Functions for Autoinstall Testing
# Provides VM lifecycle management via VBoxManage CLI

New-Module -Name VBox-Helpers -ScriptBlock {

    . "$PSScriptRoot\SDK.ps1"

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
        Try {
            $SDK.Vbox.Eject($VMName) | Out-Null
            return $true
        } Catch {
            Write-Warning "  Failed to eject ISO from VM: $VMName"
            return $false
        }

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
        "Wait-InstallComplete",
        "Remove-MultipassTestVMs"
    )
} | Import-Module -Force
