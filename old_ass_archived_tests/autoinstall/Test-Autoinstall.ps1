<#
.SYNOPSIS
    End-to-end test for Ubuntu autoinstall ISO.

.DESCRIPTION
    Builds autoinstall ISO via multipass and tests in VirtualBox or Hyper-V.

.PARAMETER Hypervisor
    VirtualBox (default) or HyperV

.PARAMETER SkipBuild
    Use existing ISO instead of rebuilding

.PARAMETER Cleanup
    Remove test resources

.EXAMPLE
    .\Test-Autoinstall.ps1
    .\Test-Autoinstall.ps1 -Hypervisor HyperV
    .\Test-Autoinstall.ps1 -Cleanup
#>
param(
    [ValidateSet("VirtualBox", "HyperV")]
    [string]$Hypervisor = "VirtualBox",
    [string]$BuilderVMName = "iso-builder",
    [string]$TestVMName = "ubuntu-autoinstall-test",
    [string]$OutputPath = "$PSScriptRoot\output",
    [switch]$SkipBuild,
    [switch]$Cleanup
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
$IsoPath = Join-Path $OutputPath "ubuntu-autoinstall.iso"
$VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

function Write-Status {
    param([string]$Message, [string]$Type = "Info")
    $colors = @{ Info = "Cyan"; Success = "Green"; Warning = "Yellow"; Error = "Red" }
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))][$Type] $Message" -ForegroundColor $colors[$Type]
}

function Build-ISO {
    Write-Status "Checking multipass builder VM..."
    $vmList = multipass list --format csv 2>$null | ConvertFrom-Csv
    $vm = $vmList | Where-Object { $_.Name -eq $BuilderVMName }

    if (-not $vm) {
        Write-Status "Creating builder VM (first run takes a while)..."
        multipass launch --name $BuilderVMName --cpus 2 --memory 4G --disk 20G
    } elseif ($vm.State -ne "Running") {
        multipass start $BuilderVMName
    }

    Write-Status "Transferring config files..."
    multipass transfer "$ScriptDir\user-data" "${BuilderVMName}:/home/ubuntu/user-data"
    multipass transfer "$ScriptDir\meta-data" "${BuilderVMName}:/home/ubuntu/meta-data"

    Write-Status "Building ISO (downloads 3GB on first run)..."
    multipass exec $BuilderVMName -- bash -c "chmod +x ~/build-iso.sh 2>/dev/null; ~/build-iso.sh"

    Write-Status "Transferring ISO to host..."
    New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null
    multipass transfer "${BuilderVMName}:/home/ubuntu/ubuntu-autoinstall.iso" $IsoPath

    if (Test-Path $IsoPath) {
        $size = [math]::Round((Get-Item $IsoPath).Length / 1GB, 2)
        Write-Status "ISO ready: $IsoPath (${size} GB)" -Type "Success"
    } else {
        throw "ISO build failed"
    }
}

function Test-VirtualBox {
    if (-not (Test-Path $VBoxManage)) {
        throw "VirtualBox not found at $VBoxManage"
    }

    $vdiPath = Join-Path $OutputPath "ubuntu-test.vdi"

    # Cleanup existing VM
    $existingVM = & $VBoxManage list vms 2>$null | Select-String $TestVMName
    if ($existingVM) {
        Write-Status "Removing existing VM..." -Type "Warning"
        & $VBoxManage controlvm $TestVMName poweroff 2>$null
        Start-Sleep 2
        & $VBoxManage unregistervm $TestVMName --delete 2>$null
    }
    if (Test-Path $vdiPath) { Remove-Item $vdiPath -Force }

    Write-Status "Creating VirtualBox VM..."
    & $VBoxManage createvm --name $TestVMName --ostype Ubuntu_64 --register
    & $VBoxManage modifyvm $TestVMName --memory 4096 --cpus 2 --nic1 nat
    & $VBoxManage storagectl $TestVMName --name 'SATA' --add sata --controller IntelAhci
    & $VBoxManage createmedium disk --filename $vdiPath --size 20480 --format VDI
    & $VBoxManage storageattach $TestVMName --storagectl 'SATA' --port 0 --device 0 --type hdd --medium $vdiPath
    & $VBoxManage storageattach $TestVMName --storagectl 'SATA' --port 1 --device 0 --type dvddrive --medium $IsoPath

    Write-Status "Starting VM..."
    & $VBoxManage startvm $TestVMName --type gui
    Write-Status "VM started - autoinstall running" -Type "Success"

    Write-Status "Waiting for installation (watch VM window)..."
    Write-Status "Installation typically takes 5-10 minutes"

    # Poll for guest properties (indicates guest utils loaded = install complete)
    $timeout = 900  # 15 minutes
    $start = Get-Date
    while (((Get-Date) - $start).TotalSeconds -lt $timeout) {
        $props = & $VBoxManage guestproperty enumerate $TestVMName 2>$null
        if ($props -match "Net/0/V4/IP") {
            $ip = ($props | Select-String "Net/0/V4/IP\s+=\s+'([^']+)'" | ForEach-Object { $_.Matches.Groups[1].Value })
            Write-Status "Installation complete! VM IP: $ip" -Type "Success"

            # Add SSH port forwarding
            & $VBoxManage controlvm $TestVMName natpf1 "ssh,tcp,,2222,,22" 2>$null
            Write-Status "SSH available: ssh -p 2222 test@localhost (password: test)"
            return
        }
        Start-Sleep 10
    }
    Write-Status "Timeout waiting for guest properties" -Type "Warning"
}

function Test-HyperV {
    $vhdPath = Join-Path $OutputPath "$TestVMName.vhdx"

    # Cleanup existing VM
    $existingVM = Get-VM -Name $TestVMName -ErrorAction SilentlyContinue
    if ($existingVM) {
        Write-Status "Removing existing VM..." -Type "Warning"
        Stop-VM -Name $TestVMName -Force -ErrorAction SilentlyContinue
        Remove-VM -Name $TestVMName -Force
    }
    if (Test-Path $vhdPath) { Remove-Item $vhdPath -Force }

    $switchName = (Get-VMSwitch | Where-Object { $_.Name -eq "Default Switch" } | Select-Object -First 1).Name
    if (-not $switchName) { $switchName = (Get-VMSwitch | Select-Object -First 1).Name }

    Write-Status "Creating Hyper-V VM (Gen 1 for BIOS boot)..."
    New-VM -Name $TestVMName -MemoryStartupBytes 2GB -Generation 1 -NewVHDPath $vhdPath -NewVHDSizeBytes 20GB -SwitchName $switchName
    Set-VM -Name $TestVMName -ProcessorCount 2
    Set-VMDvdDrive -VMName $TestVMName -Path $IsoPath

    Write-Status "Starting VM..."
    Start-VM -Name $TestVMName
    Write-Status "VM started - use vmconnect to view" -Type "Success"

    # Monitor for IP
    $timeout = 900
    $start = Get-Date
    while (((Get-Date) - $start).TotalSeconds -lt $timeout) {
        $adapters = Get-VMNetworkAdapter -VMName $TestVMName
        $ip = $adapters.IPAddresses | Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+$' } | Select-Object -First 1
        if ($ip) {
            Write-Status "VM IP: $ip" -Type "Success"
            Write-Status "SSH: ssh test@$ip (password: test)"
            return
        }
        Start-Sleep 10
    }
    Write-Status "Timeout waiting for VM IP" -Type "Warning"
}

function Remove-TestResources {
    Write-Status "Cleaning up..." -Type "Warning"

    # VirtualBox
    if (Test-Path $VBoxManage) {
        $existingVM = & $VBoxManage list vms 2>$null | Select-String $TestVMName
        if ($existingVM) {
            & $VBoxManage controlvm $TestVMName poweroff 2>&1 | Out-Null
            Start-Sleep 2
            & $VBoxManage unregistervm $TestVMName --delete 2>&1 | Out-Null
            Write-Status "Removed VirtualBox VM"
        }
    }

    # Hyper-V
    $hvVM = Get-VM -Name $TestVMName -ErrorAction SilentlyContinue
    if ($hvVM) {
        Stop-VM -Name $TestVMName -TurnOff -Force -ErrorAction SilentlyContinue
        Remove-VM -Name $TestVMName -Force
        Write-Status "Removed Hyper-V VM"
    }

    # Output files
    if (Test-Path $OutputPath) {
        Remove-Item "$OutputPath\*" -Force -ErrorAction SilentlyContinue
        Write-Status "Cleaned output directory"
    }

    Write-Status "Cleanup complete" -Type "Success"
}

# Main
try {
    Write-Host "`n=== Autoinstall Test ($Hypervisor) ===" -ForegroundColor Magenta

    if ($Cleanup) {
        Remove-TestResources
        exit 0
    }

    if (-not $SkipBuild) {
        Build-ISO
    } elseif (-not (Test-Path $IsoPath)) {
        throw "ISO not found. Run without -SkipBuild first."
    } else {
        Write-Status "Using existing ISO: $IsoPath"
    }

    if ($Hypervisor -eq "VirtualBox") {
        Test-VirtualBox
    } else {
        Test-HyperV
    }

    Write-Host "`n=== Test Complete ===" -ForegroundColor Green
} catch {
    Write-Status $_.Exception.Message -Type "Error"
    exit 1
}
