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

        $timedOut = $SDK.Vbox.UntilShutdown($VMName, $TimeoutMinutes * 60)
        if ($timedOut) {
            Write-Host "  VM still running - trying pause/resume workaround..." -ForegroundColor Yellow
            $SDK.Vbox.Bump($VMName) | Out-Null
            $timedOut = $SDK.Vbox.UntilShutdown($VMName, 600)
            if ($timedOut) {
                Write-Host "  WARNING: Installation timeout - VM still running after pause/resume" -ForegroundColor Yellow
                return $false
            }
        }
        Write-Host "  VM stopped - installation complete"

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
