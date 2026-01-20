# VirtualBox Helper Functions for Autoinstall Testing
# Provides VM lifecycle management via VBoxManage CLI

New-Module -Name VBox-Helpers -ScriptBlock {

    . "$PSScriptRoot\SDK.ps1"

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
        "Remove-MultipassTestVMs"
    )
} | Import-Module -Force
