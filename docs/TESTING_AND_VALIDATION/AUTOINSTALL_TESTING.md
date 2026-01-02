# 7.2 Autoinstall Testing

Build and test the full autoinstall ISO with VirtualBox.

**Prerequisite:** Complete [6.1 Cloud-init Testing](./CLOUD_INIT_TESTING.md) first.

## Phase 2: Autoinstall Testing

### Step 1: Build and Validate user-data

```powershell
# Transfer additional files to builder VM
multipass transfer autoinstall.yml iso-builder:/home/ubuntu/
multipass transfer early-net.sh iso-builder:/home/ubuntu/
multipass transfer build_autoinstall.py iso-builder:/home/ubuntu/

# Validate YAML syntax before build
multipass exec iso-builder -- python3 -c "import yaml; yaml.safe_load(open('autoinstall.yml'))"

# Build final user-data
multipass exec iso-builder -- python3 build_autoinstall.py

# Validate user-data structure (check printed output manually)
multipass exec iso-builder -- python3 -c "
import yaml
with open('user-data') as f:
    data = yaml.safe_load(f)
ai = data.get('autoinstall', {})
print('autoinstall version:', ai.get('version'))
print('has early-commands:', 'early-commands' in ai)
print('has user-data:', 'user-data' in ai)
ud = ai.get('user-data', {})
print('user-data has bootcmd:', 'bootcmd' in ud)
print('user-data has users:', 'users' in ud)
"
```

### Step 2: Build and Validate ISO

Transfer and execute the ISO build script. See [4.3 Bootable Media Creation](../AUTOINSTALL_MEDIA_CREATION/TESTED_BOOTABLE_MEDIA_CREATION.md) for the full script.

```powershell
multipass transfer build-iso.sh iso-builder:/home/ubuntu/
multipass exec iso-builder -- chmod +x build-iso.sh
multipass exec iso-builder -- ./build-iso.sh
```

**ISO Validation** - Run inside builder VM:

```powershell
# List nocloud directory contents
multipass exec iso-builder -- xorriso -indev ubuntu-autoinstall.iso -ls /nocloud

# Verify GRUB config has autoinstall entry
multipass exec iso-builder -- bash -c "xorriso -indev ubuntu-autoinstall.iso -extract /boot/grub/grub.cfg /tmp/grub.cfg 2>/dev/null && grep -A5 'Autoinstall' /tmp/grub.cfg"
```

### Step 3: Transfer ISO to Host

```powershell
# Create output directory
New-Item -ItemType Directory -Force -Path .\output | Out-Null

# Transfer ISO
multipass transfer iso-builder:/home/ubuntu/ubuntu-autoinstall.iso .\output\

# Verify
Get-Item .\output\ubuntu-autoinstall.iso
```

### Step 4: Test with VirtualBox

```powershell
$vbox = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
$vmName = 'ubuntu-autoinstall-test'
$isoPath = '.\output\ubuntu-autoinstall.iso'
$vdiPath = '.\output\ubuntu-test.vdi'

# Cleanup existing VM if present
$existingVM = & $vbox list vms 2>$null | Select-String $vmName
if ($existingVM) {
    & $vbox controlvm $vmName poweroff 2>$null
    Start-Sleep 2
    & $vbox unregistervm $vmName --delete 2>$null
}
if (Test-Path $vdiPath) { Remove-Item $vdiPath -Force }

# Create VM
& $vbox createvm --name $vmName --ostype Ubuntu_64 --register
& $vbox modifyvm $vmName --memory 4096 --cpus 2 --nic1 nat

# Add storage controller
& $vbox storagectl $vmName --name 'SATA' --add sata --controller IntelAhci

# Create and attach disk
& $vbox createmedium disk --filename $vdiPath --size 20480 --format VDI
& $vbox storageattach $vmName --storagectl 'SATA' --port 0 --device 0 --type hdd --medium $vdiPath

# Attach ISO
& $vbox storageattach $vmName --storagectl 'SATA' --port 1 --device 0 --type dvddrive --medium $isoPath

# Start VM
& $vbox startvm $vmName --type gui
```

### Step 5: Validate Autoinstall

Watch the VM window. Installation typically takes 5-10 minutes.

After reboot, query for IP and SSH in:

```powershell
# Wait for guest utils to report IP
& $vbox guestproperty enumerate $vmName | Select-String 'Net'

# Add SSH port forwarding
& $vbox controlvm $vmName natpf1 'ssh,tcp,,2222,,22'

# Connect via SSH
ssh -p 2222 admin@localhost
```

**Validation** - Run these commands inside the VM:

```bash
# Verify autoinstall completed
cat /var/log/installer/autoinstall-user-data

# Verify cloud-init completed
cloud-init status

# Verify ZFS root
zfs list

# Verify network
ip addr show
cat /etc/netplan/90-static.yaml

# Verify services
systemctl status cockpit.socket
systemctl status libvirtd
systemctl status ssh

# Verify packages
dpkg -l | grep -E "qemu-kvm|libvirt|cockpit"

# Verify user and groups
id admin
groups admin

# Verify firewall
ufw status
```

### Step 6: Cleanup

```powershell
# Stop and remove VirtualBox VM
& $vbox controlvm $vmName poweroff 2>$null
Start-Sleep 2
& $vbox unregistervm $vmName --delete

# Remove output files
Remove-Item .\output\* -Force

# Optionally stop builder VM (keeps cached ISO)
multipass stop iso-builder
```

## Automated Test Script

For convenience, a PowerShell script can automate the full test cycle (both phases).

**Prerequisites:** Transfer build scripts to the builder VM before running:
- `build_network.py`, `build_cloud_init.py`, `build_autoinstall.py`
- `build-iso.sh` (see [4.3 Bootable Media Creation](../AUTOINSTALL_MEDIA_CREATION/TESTED_BOOTABLE_MEDIA_CREATION.md))
- Template files and config files

### Test-Autoinstall.ps1

```powershell
<#
.SYNOPSIS
    End-to-end test for Ubuntu autoinstall ISO.

.PARAMETER SkipCloudInitTest
    Skip Phase 1 cloud-init testing

.PARAMETER SkipBuild
    Use existing ISO instead of rebuilding

.PARAMETER Cleanup
    Remove test resources

.EXAMPLE
    .\Test-Autoinstall.ps1
    .\Test-Autoinstall.ps1 -SkipCloudInitTest
    .\Test-Autoinstall.ps1 -Cleanup
#>
param(
    [string]$BuilderVMName = "iso-builder",
    [string]$TestVMName = "ubuntu-autoinstall-test",
    [string]$OutputPath = "$PSScriptRoot\output",
    [switch]$SkipCloudInitTest,
    [switch]$SkipBuild,
    [switch]$Cleanup
)

$ErrorActionPreference = "Stop"
$VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$IsoPath = Join-Path $OutputPath "ubuntu-autoinstall.iso"

function Write-Status {
    param([string]$Message, [string]$Type = "Info")
    $colors = @{ Info = "Cyan"; Success = "Green"; Warning = "Yellow"; Error = "Red" }
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))][$Type] $Message" -ForegroundColor $colors[$Type]
}

function Test-CloudInit {
    Write-Status "=== Phase 1: Cloud-init Testing ==="

    # Build cloud-init config
    Write-Status "Building cloud-init configuration..."
    multipass exec $BuilderVMName -- python3 build_cloud_init.py

    # Retrieve and test
    $testConfig = Join-Path $OutputPath "cloud-init-test.yaml"
    New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null
    multipass transfer "${BuilderVMName}:/home/ubuntu/cloud-init-built.yaml" $testConfig

    Write-Status "Launching test VM..."
    multipass launch --name cloud-init-test --cloud-init $testConfig 2>$null

    Write-Status "Waiting for cloud-init to complete..."
    multipass exec cloud-init-test -- cloud-init status --wait

    Write-Status "Verifying configuration..."
    multipass exec cloud-init-test -- cat /etc/motd

    Write-Status "Cloud-init test passed!" -Type "Success"

    # Cleanup
    multipass delete cloud-init-test
    multipass purge
}

function Build-ISO {
    Write-Status "=== Phase 2: Building Autoinstall ISO ==="

    Write-Status "Building user-data..."
    multipass exec $BuilderVMName -- python3 build_autoinstall.py

    Write-Status "Building ISO (downloads ~3GB on first run)..."
    multipass exec $BuilderVMName -- ./build-iso.sh

    Write-Status "Transferring ISO to host..."
    New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null
    multipass transfer "${BuilderVMName}:/home/ubuntu/ubuntu-autoinstall.iso" $IsoPath

    $size = [math]::Round((Get-Item $IsoPath).Length / 1GB, 2)
    Write-Status "ISO ready: $IsoPath (${size} GB)" -Type "Success"
}

function Test-VirtualBox {
    Write-Status "=== Testing with VirtualBox ==="

    $vdiPath = Join-Path $OutputPath "ubuntu-test.vdi"

    # Cleanup existing
    $existingVM = & $VBoxManage list vms 2>$null | Select-String $TestVMName
    if ($existingVM) {
        Write-Status "Removing existing VM..." -Type "Warning"
        & $VBoxManage controlvm $TestVMName poweroff 2>$null
        Start-Sleep 2
        & $VBoxManage unregistervm $TestVMName --delete 2>$null
    }
    if (Test-Path $vdiPath) { Remove-Item $vdiPath -Force }

    # Create VM
    Write-Status "Creating VirtualBox VM..."
    & $VBoxManage createvm --name $TestVMName --ostype Ubuntu_64 --register
    & $VBoxManage modifyvm $TestVMName --memory 4096 --cpus 2 --nic1 nat
    & $VBoxManage storagectl $TestVMName --name 'SATA' --add sata --controller IntelAhci
    & $VBoxManage createmedium disk --filename $vdiPath --size 20480 --format VDI
    & $VBoxManage storageattach $TestVMName --storagectl 'SATA' --port 0 --device 0 --type hdd --medium $vdiPath
    & $VBoxManage storageattach $TestVMName --storagectl 'SATA' --port 1 --device 0 --type dvddrive --medium $IsoPath

    Write-Status "Starting VM..."
    & $VBoxManage startvm $TestVMName --type gui

    Write-Status "Waiting for installation (watch VM window)..."

    # Poll for guest properties
    $timeout = 900  # 15 minutes
    $start = Get-Date
    while (((Get-Date) - $start).TotalSeconds -lt $timeout) {
        $props = & $VBoxManage guestproperty enumerate $TestVMName 2>$null
        if ($props -match "Net/0/V4/IP") {
            Write-Status "Installation complete!" -Type "Success"
            & $VBoxManage controlvm $TestVMName natpf1 "ssh,tcp,,2222,,22" 2>$null
            Write-Status "SSH available: ssh -p 2222 admin@localhost"
            return
        }
        Start-Sleep 10
    }
    Write-Status "Timeout waiting for guest properties" -Type "Warning"
}

function Remove-TestResources {
    Write-Status "Cleaning up..." -Type "Warning"

    # Multipass test VM
    multipass delete cloud-init-test 2>$null
    multipass purge 2>$null

    # VirtualBox VM
    if (Test-Path $VBoxManage) {
        $existingVM = & $VBoxManage list vms 2>$null | Select-String $TestVMName
        if ($existingVM) {
            & $VBoxManage controlvm $TestVMName poweroff 2>&1 | Out-Null
            Start-Sleep 2
            & $VBoxManage unregistervm $TestVMName --delete 2>&1 | Out-Null
        }
    }

    # Output files
    if (Test-Path $OutputPath) {
        Remove-Item "$OutputPath\*" -Force -ErrorAction SilentlyContinue
    }

    Write-Status "Cleanup complete" -Type "Success"
}

# Main
try {
    if ($Cleanup) {
        Remove-TestResources
        exit 0
    }

    # Ensure builder VM is running
    $vmList = multipass list --format csv 2>$null | ConvertFrom-Csv
    $vm = $vmList | Where-Object { $_.Name -eq $BuilderVMName }
    if (-not $vm) {
        Write-Status "Creating builder VM..."
        multipass launch --name $BuilderVMName --cpus 2 --memory 4G --disk 20G
    } elseif ($vm.State -ne "Running") {
        multipass start $BuilderVMName
    }

    if (-not $SkipCloudInitTest) {
        Test-CloudInit
    }

    if (-not $SkipBuild) {
        Build-ISO
    } elseif (-not (Test-Path $IsoPath)) {
        throw "ISO not found. Run without -SkipBuild first."
    }

    Test-VirtualBox

    Write-Host "`n=== Test Complete ===" -ForegroundColor Green
} catch {
    Write-Status $_.Exception.Message -Type "Error"
    exit 1
}
```

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Malformed YAML` | Inline comments in list items | Remove comments from list items |
| `Invalid user-data` | Missing `#cloud-config` header | Ensure first line is `#cloud-config` |
| `Schema validation failed` | Invalid cloud-init keys | Check cloud-init documentation |
| `No autoinstall config found` | Missing datasource parameter | Add `ds=nocloud;s=/cdrom/nocloud/` to GRUB |
| `Network not configured` | arping failed to find interface | Check gateway/DNS IPs are reachable |

## Key Differences from tests/autoinstall (old experiment)

| Aspect | tests/autoinstall (old) | Current approach |
|--------|------------------------|------------------|
| Cloud-init location | Separate on ISO (`/nocloud/`) | Embedded in autoinstall `user-data` field |
| Network config | DHCP | Static via arping detection |
| Storage | LVM | ZFS |
| Pre-testing | None | Cloud-init tested with multipass first |
| Build scripts | Manual | Python-based YAML composition |
