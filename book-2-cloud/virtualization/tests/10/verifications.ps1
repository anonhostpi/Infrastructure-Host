param([Parameter(Mandatory = $true)] $SDK)

return (New-Module -Name "Verify.Virtualization" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $mod.Tests = [ordered]@{
        "libvirt installed" = {
            param($Worker)
            $result = $Worker.Exec("which virsh")
            $mod.SDK.Testing.Record(@{
                Test = "6.10.1"; Name = "libvirt installed"
                Pass = ($result.Success -and $result.Output -match "virsh"); Output = $result.Output
            })
        }
        "libvirtd service active" = {
            param($Worker)
            $result = $Worker.Exec("systemctl is-active libvirtd")
            $mod.SDK.Testing.Record(@{
                Test = "6.10.2"; Name = "libvirtd service active"
                Pass = ($result.Output -match "^active$"); Output = $result.Output
            })
        }
        "QEMU installed" = {
            param($Worker)
            $result = $Worker.Exec("which qemu-system-x86_64")
            $mod.SDK.Testing.Record(@{
                Test = "6.10.3"; Name = "QEMU installed"
                Pass = ($result.Success -and $result.Output -match "qemu"); Output = $result.Output
            })
        }
        "libvirt default network" = {
            param($Worker)
            $result = $Worker.Exec("sudo virsh net-list --all")
            $mod.SDK.Testing.Record(@{
                Test = "6.10.4"; Name = "libvirt default network"
                Pass = ($result.Output -match "default"); Output = $result.Output
            })
        }
        "multipass installed" = {
            param($Worker)
            $result = $Worker.Exec("which multipass")
            $mod.SDK.Testing.Record(@{
                Test = "6.10.5"; Name = "multipass installed"
                Pass = ($result.Success -and $result.Output -match "multipass"); Output = $result.Output
            })
        }
        "multipassd service active" = {
            param($Worker)
            $result = $Worker.Exec("systemctl is-active snap.multipass.multipassd.service")
            $mod.SDK.Testing.Record(@{
                Test = "6.10.6"; Name = "multipassd service active"
                Pass = ($result.Output -match "^active$"); Output = $result.Output
            })
        }
        "KVM available for nesting" = {
            param($Worker)
            $result = $Worker.Exec("test -e /dev/kvm && echo available")
            $mod.SDK.Testing.Record(@{
                Test = "6.10.7"; Name = "KVM available for nesting"
                Pass = ($result.Output -match "available")
                Output = if ($result.Output -match "available") { "/dev/kvm present" } else { "KVM not available" }
            })
        }
        "Launch nested VM" = {
            param($Worker)
            if (-not ($Worker.Exec("test -e /dev/kvm").Success)) { $mod.SDK.Testing.Verifications.Fork("6.10.8", "SKIP", "KVM not available"); return }
            $launch = $Worker.Exec("multipass launch --name nested-test-vm --cpus 1 --memory 512M --disk 2G 2>&1; echo exit_code:`$?")
            $mod.SDK.Testing.Record(@{
                Test = "6.10.8"; Name = "Launch nested VM"
                Pass = ($launch.Output -match "exit_code:0")
                Output = if ($launch.Output -match "exit_code:0") { "nested-test-vm launched" } else { $launch.Output }
            })
        }
        "Exec in nested VM" = {
            param($Worker)
            if (-not ($Worker.Exec("test -e /dev/kvm").Success)) { $mod.SDK.Testing.Verifications.Fork("6.10.9", "SKIP", "KVM not available"); return }
            $exec = $Worker.Exec("multipass exec nested-test-vm -- echo nested-ok")
            $mod.SDK.Testing.Record(@{
                Test = "6.10.9"; Name = "Exec in nested VM"
                Pass = ($exec.Output -match "nested-ok"); Output = $exec.Output
            })
            $Worker.Exec("multipass delete nested-test-vm --purge") | Out-Null
        }
    }

    Export-ModuleMember -Function @()
} -ArgumentList $SDK)
