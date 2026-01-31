param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name "Verify.Virtualization" -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\..\..\..\book-0-builder\host-sdk\helpers\PowerShell.ps1"

    $SDK.Testing.Verifications.Register("virtualization", 10, [ordered]@{
        "libvirt installed" = { param($Worker) }
        "libvirtd service active" = { param($Worker) }
        "QEMU installed" = { param($Worker) }
        "libvirt default network" = { param($Worker) }
        "multipass installed" = { param($Worker) }
        "multipassd service active" = { param($Worker) }
        "KVM available for nesting" = { param($Worker) }
        "Launch nested VM" = { param($Worker) }
        "Exec in nested VM" = { param($Worker) }
    })
} -ArgumentList $SDK
