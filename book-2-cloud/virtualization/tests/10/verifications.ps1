param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.Virtualization" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $mod.Tests = [ordered]@{
        "libvirt installed" = {
            param($Worker)
            $Worker.Test("6.10.1", "libvirt installed", "which virsh", "virsh")
        }
        "libvirtd service active" = {
            param($Worker)
            $Worker.Test("6.10.2", "libvirtd service active", "systemctl is-active libvirtd", "active")
        }
        "QEMU installed" = {
            param($Worker)
            $Worker.Test("6.10.3", "QEMU installed", "which qemu-system-x86_64", "qemu")
        }
        "libvirt default network" = {
            param($Worker)
            $Worker.Test("6.10.4", "libvirt default network", "sudo virsh net-list --all", "default")
        }
        "multipass installed" = {
            param($Worker)
            $Worker.Test("6.10.5", "multipass installed", "which multipass", "multipass")
        }
        "multipassd service active" = {
            param($Worker)
            $Worker.Test("6.10.6", "multipassd service active", "systemctl is-active snap.multipass.multipassd.service", "active")
        }
        "KVM available for nesting" = {
            param($Worker)
            $Worker.Test("6.10.7", "KVM available for nesting", "test -e /dev/kvm && echo available", "available")
        }
        "Launch nested VM" = {
            param($Worker)
            if (-not ($Worker.Exec("test -e /dev/kvm").Success)) { $mod.SDK.Testing.Verifications.Fork("6.10.8", "SKIP", "KVM not available"); return }
            $Worker.Test("6.10.8", "Launch nested VM", "multipass launch --name nested-test-vm --cpus 1 --memory 512M --disk 2G 2>&1; echo exit_code:`$?", "exit_code:0")
        }
        "Exec in nested VM" = {
            param($Worker)
            if (-not ($Worker.Exec("test -e /dev/kvm").Success)) { $mod.SDK.Testing.Verifications.Fork("6.10.9", "SKIP", "KVM not available"); return }
            $Worker.Test("6.10.9", "Exec in nested VM", "multipass exec nested-test-vm -- echo nested-ok", "nested-ok")
            $Worker.Exec("multipass delete nested-test-vm --purge") | Out-Null
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
