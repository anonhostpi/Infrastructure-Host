# 6.1 Test Procedures

Testing occurs in two phases: cloud-init validation with multipass, then full autoinstall testing with VirtualBox.

## Phase 1: Cloud-init Testing

Test cloud-init configuration before embedding in autoinstall.

### Step 1: Start Builder VM

```powershell
# Create or start the builder VM
multipass launch --name iso-builder --cpus 2 --memory 4G --disk 20G

# Or if it already exists
multipass start iso-builder
```

### Step 2: Transfer Build Scripts

```powershell
# Transfer config files
multipass transfer network.config.yaml iso-builder:/home/ubuntu/
multipass transfer identity.config.yaml iso-builder:/home/ubuntu/

# Transfer build scripts
multipass transfer build_network.py iso-builder:/home/ubuntu/
multipass transfer build_cloud_init.py iso-builder:/home/ubuntu/

# Transfer templates
multipass transfer cloud-init.yml iso-builder:/home/ubuntu/
multipass transfer net-setup.sh iso-builder:/home/ubuntu/
```

### Step 3: Build cloud-init.yml

```powershell
# Install dependencies
multipass exec iso-builder -- sudo apt-get update -qq
multipass exec iso-builder -- sudo apt-get install -y -qq python3-yaml

# Build cloud-init configuration
multipass exec iso-builder -- python3 build_cloud_init.py

# Retrieve built config
multipass transfer iso-builder:/home/ubuntu/cloud-init-built.yaml ./cloud-init-test.yaml
```

### Step 4: Test with Multipass

```powershell
# Launch test VM with cloud-init config (may timeout - that's OK)
multipass launch --name cloud-init-test --cloud-init cloud-init-test.yaml 2>$null

# Wait for cloud-init to complete (THIS is the true success indicator)
multipass exec cloud-init-test -- cloud-init status --wait

# Verify configuration applied
multipass exec cloud-init-test -- cat /etc/motd
multipass exec cloud-init-test -- systemctl status cockpit.socket
multipass exec cloud-init-test -- cat /etc/netplan/90-static.yaml
```

### Step 5: Cleanup Test VM

```powershell
multipass delete cloud-init-test
multipass purge
```

If cloud-init test passes, proceed to Phase 2.

## Phase 2: Autoinstall Testing

Build and test the full autoinstall ISO.

### Step 1: Build user-data

```powershell
# Transfer additional files to builder VM
multipass transfer autoinstall.yml iso-builder:/home/ubuntu/
multipass transfer early-net.sh iso-builder:/home/ubuntu/
multipass transfer build_autoinstall.py iso-builder:/home/ubuntu/

# Build final user-data
multipass exec iso-builder -- python3 build_autoinstall.py
```

### Step 2: Build ISO

Transfer the ISO build script and execute:

```powershell
multipass transfer build-iso.sh iso-builder:/home/ubuntu/
multipass exec iso-builder -- chmod +x build-iso.sh
multipass exec iso-builder -- ./build-iso.sh
```

### build-iso.sh

```bash
#!/bin/bash
# Build autoinstall ISO using xorriso in-place modification
set -e

UBUNTU_VERSION="24.04.2"
ISO_URL="https://releases.ubuntu.com/24.04/ubuntu-${UBUNTU_VERSION}-live-server-amd64.iso"
ORIGINAL_ISO="ubuntu-${UBUNTU_VERSION}-live-server-amd64.iso"
OUTPUT_ISO="$HOME/ubuntu-autoinstall.iso"

echo "=== Installing dependencies ==="
sudo apt-get update -qq
sudo apt-get install -y -qq xorriso wget

echo "=== Downloading Ubuntu ISO (if not cached) ==="
if [ ! -f "$HOME/$ORIGINAL_ISO" ]; then
    wget -q --show-progress "$ISO_URL" -O "$HOME/$ORIGINAL_ISO"
else
    echo "Using cached ISO"
fi

echo "=== Copying ISO for modification ==="
cp "$HOME/$ORIGINAL_ISO" "$OUTPUT_ISO"

echo "=== Creating config directories ==="
mkdir -p "$HOME/nocloud_add" "$HOME/grub_mod"

# user-data is the autoinstall config (includes embedded cloud-init)
cp "$HOME/user-data" "$HOME/nocloud_add/"

# meta-data is minimal
cat > "$HOME/nocloud_add/meta-data" << 'EOF'
instance-id: autoinstall-001
EOF

echo "=== Creating GRUB config ==="
cat > "$HOME/grub_mod/grub.cfg" << 'GRUBEOF'
set timeout=5
set default=0
loadfont unicode
set menu_color_normal=white/black
set menu_color_highlight=black/light-gray

menuentry "Autoinstall Ubuntu Server" {
    set gfxpayload=keep
    linux /casper/vmlinuz autoinstall ds=nocloud\;s=/cdrom/nocloud/ consoleblank=0 ---
    initrd /casper/initrd
}

menuentry "Ubuntu Server (Manual Install)" {
    set gfxpayload=keep
    linux /casper/vmlinuz ---
    initrd /casper/initrd
}
GRUBEOF

echo "=== Modifying ISO in-place with xorriso ==="
xorriso -indev "$OUTPUT_ISO" \
    -outdev "$OUTPUT_ISO" \
    -boot_image any replay \
    -map "$HOME/nocloud_add" /nocloud \
    -map "$HOME/grub_mod/grub.cfg" /boot/grub/grub.cfg \
    -commit

echo "=== Verifying ISO ==="
xorriso -indev "$OUTPUT_ISO" -ls /nocloud 2>/dev/null || true

echo "=== ISO built successfully ==="
ls -lh "$OUTPUT_ISO"
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

### Step 5: Monitor Installation

Watch the VM window. Installation typically takes 5-10 minutes.

After reboot, query for IP:

```powershell
# Wait for guest utils to report IP
& $vbox guestproperty enumerate $vmName | Select-String 'Net'

# Add SSH port forwarding
& $vbox controlvm $vmName natpf1 'ssh,tcp,,2222,,22'

# Connect via SSH
ssh -p 2222 admin@localhost
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

For convenience, a PowerShell script can automate the full test cycle:

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

## Key Differences from tests/autoinstall

| Aspect | tests/autoinstall (old) | Current approach |
|--------|------------------------|------------------|
| Cloud-init location | Separate on ISO (`/nocloud/`) | Embedded in autoinstall `user-data` field |
| Network config | DHCP | Static via arping detection |
| Storage | LVM | ZFS |
| Pre-testing | None | Cloud-init tested with multipass first |
| Build scripts | Manual | Python-based YAML composition |
