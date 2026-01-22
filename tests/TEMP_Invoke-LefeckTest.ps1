<#
.SYNOPSIS
    Modified ISO (lefeck method) autoinstall testing (TEMP)

.DESCRIPTION
    Builds and tests a self-contained autoinstall ISO using the lefeck/ubuntu-autoinstall-generator-tools approach.

    Key differences from CIDATA method:
    - Single ISO (no separate CIDATA disk)
    - user-data embedded in /nocloud/ directory
    - GRUB configured with ds=nocloud;s=/cdrom/nocloud/

    This method is ideal for:
    - Air-gapped/offline deployments
    - Single self-contained boot media
    - DD to USB or burn to DVD

.PARAMETER SkipBuild
    Skip building the ISO (use existing output/ubuntu-autoinstall-modified.iso)

.PARAMETER SkipCleanup
    Keep VMs running after tests complete (for debugging)

.PARAMETER Headless
    Run VirtualBox VM in headless mode (no GUI window)

.PARAMETER Firmware
    Which firmware to test: "all" (both), "efi", or "bios". Default: "efi"

.PARAMETER UbuntuRelease
    Ubuntu release codename: noble, jammy, focal. Default: "noble"

.EXAMPLE
    .\TEMP_Invoke-LefeckTest.ps1
    # Full test: build modified ISO, install, run all tests

.EXAMPLE
    .\TEMP_Invoke-LefeckTest.ps1 -SkipBuild
    # Use existing modified ISO

.EXAMPLE
    .\TEMP_Invoke-LefeckTest.ps1 -UbuntuRelease jammy
    # Build and test with Ubuntu 22.04
#>

[CmdletBinding()]
param(
    [switch]$SkipBuild,
    [switch]$SkipCleanup,
    [switch]$Headless,

    [ValidateSet("all", "efi", "bios")]
    [string]$Firmware = "efi",

    [ValidateSet("noble", "jammy", "focal")]
    [string]$UbuntuRelease = "noble"
)

$ErrorActionPreference = "Stop"

# Load configuration and libraries
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir

. "$ScriptDir\lib\Config.ps1"
. "$ScriptDir\lib\VBoxHelpers.ps1"
. "$RepoRoot\vm.config.ps1"

# Paths
$ModifiedISOPath = Join-Path $RepoRoot "output\ubuntu-autoinstall-modified.iso"
$UserDataPath = Join-Path $RepoRoot "output\user-data"
$LefeckToolDir = Join-Path $RepoRoot "tools\ubuntu-autoinstall-generator-tools"
$VDIPath = Join-Path $RepoRoot "output\ubuntu-lefeck-test.vdi"

# SSH settings
$SSHPort = 2224  # Different port to avoid conflict with other tests
$SSHUser = $SDK.Settings.identity.username

# Set up logging
$LogDir = Join-Path $RepoRoot "output\logs"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogFile = Join-Path $LogDir "lefeck-test-$timestamp.log"
Start-Transcript -Path $LogFile -Append | Out-Null

# Determine which firmwares to test
$FirmwareList = switch ($Firmware) {
    "all"  { @("bios", "efi") }
    "bios" { @("bios") }
    "efi"  { @("efi") }
}

# Banner
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " Modified ISO (Lefeck) Autoinstall Testing (TEMP)" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "VirtualBox VM: ${VBoxVMName}-lefeck" -ForegroundColor Yellow
Write-Host "Builder VM:    $BuilderVMName" -ForegroundColor Yellow
Write-Host "Ubuntu:        $UbuntuRelease" -ForegroundColor Yellow
Write-Host "Firmware(s):   $($FirmwareList -join ', ')" -ForegroundColor Yellow
Write-Host ""
Write-Host "Key difference: Single ISO with embedded user-data (no CIDATA)" -ForegroundColor Magenta
Write-Host ""

$stepCount = if ($SkipBuild) { 6 } else { 10 }
$currentStep = 0

function Write-Step {
    param([string]$Message)
    $script:currentStep++
    Write-Host "[$currentStep/$stepCount] $Message" -ForegroundColor Cyan
}

# ============================================================================
# Phase 1: Build Modified ISO (unless -SkipBuild)
# ============================================================================

if (-not $SkipBuild) {
    # Step 1: Launch builder VM
    Write-Step "Launching builder VM..."

    $existingBuilder = multipass list --format csv 2>$null | Select-String "^$BuilderVMName,"
    if (-not $existingBuilder) {
        Write-Host "  Creating new builder VM..."
        multipass launch --name $BuilderVMName --cpus $BuilderCpus --memory $BuilderMemory --disk $BuilderDisk
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to launch builder VM"
            exit 1
        }
    } else {
        Write-Host "  Starting existing builder VM..."
        multipass start $BuilderVMName 2>$null
    }

    Write-Host "  Waiting for cloud-init..."
    multipass exec $BuilderVMName -- cloud-init status --wait 2>$null
    Write-Host "  Done" -ForegroundColor Green
    Write-Host ""

    # Step 2: Mount repository
    Write-Step "Mounting repository to builder VM..."

    $mounts = multipass info $BuilderVMName --format json 2>$null | ConvertFrom-Json
    $alreadyMounted = $mounts.info.$BuilderVMName.mounts.PSObject.Properties | Where-Object { $_.Value.source_path -eq $RepoRoot }

    if (-not $alreadyMounted) {
        multipass mount $RepoRoot ${BuilderVMName}:/home/ubuntu/infra-host
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to mount repository"
            exit 1
        }
    }
    Write-Host "  Done" -ForegroundColor Green
    Write-Host ""

    # Step 3: Install dependencies
    Write-Step "Installing dependencies..."

    Write-Host "  Installing build dependencies..."
    multipass exec $BuilderVMName -- bash -c "sudo apt-get update -qq && sudo apt-get install -y -qq python3-pip python3-yaml python3-jinja2 make xorriso isolinux p7zip-full dpkg-dev aptitude curl gpg > /dev/null 2>&1"
    multipass exec $BuilderVMName -- bash -c "cd /home/ubuntu/infra-host && pip3 install --break-system-packages -q -e . 2>/dev/null"
    Write-Host "  Done" -ForegroundColor Green
    Write-Host ""

    # Step 4: Build user-data
    Write-Step "Building user-data (make autoinstall)..."

    multipass exec $BuilderVMName -- bash -c "cd /home/ubuntu/infra-host && make autoinstall"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build user-data"
        exit 1
    }
    Write-Host "  Done" -ForegroundColor Green
    Write-Host ""

    # Step 5: Clone/update lefeck tool
    Write-Step "Setting up lefeck tool..."

    $lefeckExists = multipass exec $BuilderVMName -- bash -c "test -d /home/ubuntu/infra-host/tools/ubuntu-autoinstall-generator-tools && echo EXISTS" 2>$null
    if ($lefeckExists -ne "EXISTS") {
        Write-Host "  Cloning lefeck/ubuntu-autoinstall-generator-tools..."
        multipass exec $BuilderVMName -- bash -c "mkdir -p /home/ubuntu/infra-host/tools && cd /home/ubuntu/infra-host/tools && git clone https://github.com/lefeck/ubuntu-autoinstall-generator-tools.git"
    } else {
        Write-Host "  Updating existing lefeck tool..."
        multipass exec $BuilderVMName -- bash -c "cd /home/ubuntu/infra-host/tools/ubuntu-autoinstall-generator-tools && git pull"
    }
    Write-Host "  Done" -ForegroundColor Green
    Write-Host ""

    # Step 6: Build modified ISO
    Write-Step "Building modified ISO with lefeck tool..."

    Write-Host "  This may take several minutes (downloads Ubuntu ISO if not cached)..."
    Write-Host "  Release: $UbuntuRelease"

    $buildCmd = @"
cd /home/ubuntu/infra-host/tools/ubuntu-autoinstall-generator-tools && \
chmod +x ubuntu-autoinstall-generator-tools.sh && \
./ubuntu-autoinstall-generator-tools.sh \
    -a \
    -u /home/ubuntu/infra-host/output/user-data \
    -n $UbuntuRelease \
    -k \
    -d /home/ubuntu/infra-host/output/ubuntu-autoinstall-modified.iso
"@

    multipass exec $BuilderVMName -- bash -c $buildCmd
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build modified ISO"
        exit 1
    }
    Write-Host "  Done" -ForegroundColor Green
    Write-Host ""

    # Step 7: Validate ISO structure
    Write-Step "Validating modified ISO structure..."

    $vmIsoPath = "/home/ubuntu/infra-host/output/ubuntu-autoinstall-modified.iso"

    # Check /nocloud/ directory exists
    $nocloudCheck = multipass exec $BuilderVMName -- bash -c "xorriso -osirrox on -indev $vmIsoPath -ls /nocloud/ 2>/dev/null | grep -q user-data && echo OK"
    if ($nocloudCheck -ne "OK") {
        Write-Error "ISO validation failed: /nocloud/user-data not found"
        exit 1
    }
    Write-Host "  /nocloud/user-data: OK"

    # Check GRUB has autoinstall with nocloud
    $grubCheck = multipass exec $BuilderVMName -- bash -c "xorriso -osirrox on -indev $vmIsoPath -extract /boot/grub/grub.cfg /tmp/grub.cfg 2>/dev/null && grep -q 'nocloud' /tmp/grub.cfg && echo OK"
    if ($grubCheck -ne "OK") {
        Write-Error "ISO validation failed: GRUB nocloud entry not found"
        exit 1
    }
    Write-Host "  GRUB nocloud config: OK"

    Write-Host "  Done" -ForegroundColor Green
    Write-Host ""

    # Step 8: Show ISO info
    Write-Step "ISO ready..."

    $isoSize = multipass exec $BuilderVMName -- bash -c "ls -lh $vmIsoPath | awk '{print \$5}'"
    Write-Host "  Path: output/ubuntu-autoinstall-modified.iso"
    Write-Host "  Size: $isoSize"
    Write-Host "  Done" -ForegroundColor Green
    Write-Host ""
}

# Verify ISO exists
if (-not (Test-Path $ModifiedISOPath)) {
    Write-Error "Modified ISO not found: $ModifiedISOPath`nRun without -SkipBuild to create it."
    exit 1
}

# Helper function for SSH tests
function Test-ViaSSH {
    param(
        [string]$TestId,
        [string]$Name,
        [string]$Command,
        [string]$ExpectedPattern = $null,
        [switch]$ExpectFailure,
        [switch]$SkipOnBios,
        [switch]$SkipOnEfi
    )

    if ($SkipOnBios -and $script:currentTestFirmware -eq "bios") {
        Write-Host "  [SKIP] $TestId : $Name (BIOS)" -ForegroundColor DarkGray
        return
    }
    if ($SkipOnEfi -and $script:currentTestFirmware -eq "efi") {
        Write-Host "  [SKIP] $TestId : $Name (EFI)" -ForegroundColor DarkGray
        return
    }

    $result = Invoke-SSHCommand -Command $Command -User $SSHUser -Port $script:currentTestPort

    $pass = $false
    if ($ExpectFailure) {
        $pass = (-not $result.Success)
    } elseif ($ExpectedPattern) {
        $pass = ($result.Success -and ($result.Output -join "`n") -match $ExpectedPattern)
    } else {
        $pass = $result.Success
    }

    $status = if ($pass) { "[PASS]" } else { "[FAIL]" }
    $color = if ($pass) { "Green" } else { "Red" }

    Write-Host "  $status $TestId : $Name" -ForegroundColor $color
    if (-not $pass) {
        Write-Host "         Output: $($result.Output | Select-Object -First 3)" -ForegroundColor Gray
    }

    if ($pass) { $script:passCount++ } else { $script:failCount++ }

    $script:allResults += @{
        Test = $TestId
        Name = $Name
        Pass = $pass
        Output = $result.Output
        Firmware = $script:currentTestFirmware
    }
}

# ============================================================================
# Phase 2 & 3: VirtualBox Installation and Tests
# ============================================================================

$allFirmwareResults = @{}
$totalPassCount = 0
$totalFailCount = 0

foreach ($currentFirmware in $FirmwareList) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host " Testing with $($currentFirmware.ToUpper()) firmware" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host ""

    $allResults = @()
    $passCount = 0
    $failCount = 0

    $vmName = "${VBoxVMName}-lefeck-${currentFirmware}"
    $vdiPath = Join-Path $RepoRoot "output\ubuntu-lefeck-test-${currentFirmware}.vdi"

    # Create VM - NOTE: No CIDATAPath! Single ISO only.
    Write-Step "Creating VirtualBox VM ($currentFirmware)..."

    # Cleanup existing
    if (Test-VMExists -VMName $vmName) {
        Remove-AutoinstallVM -VMName $vmName -VDIPath $vdiPath
    }
    if (Test-Path $vdiPath) {
        Remove-Item $vdiPath -Force
    }

    # Create VM
    Write-Host "  Creating VM: $vmName (firmware: $currentFirmware)"
    Invoke-VBoxManage -Arguments @("createvm", "--name", $vmName, "--ostype", "Ubuntu_64", "--register") | Out-Null
    Invoke-VBoxManage -Arguments @("modifyvm", $vmName, "--memory", $VBoxMemory, "--cpus", $VBoxCpus, "--nic1", "nat", "--firmware", $currentFirmware) | Out-Null
    Invoke-VBoxManage -Arguments @("modifyvm", $vmName, "--pae", "on", "--nestedpaging", "on", "--hwvirtex", "on", "--largepages", "on") | Out-Null
    Invoke-VBoxManage -Arguments @("modifyvm", $vmName, "--graphicscontroller", "vmsvga", "--vram", "16") | Out-Null

    # Storage
    Invoke-VBoxManage -Arguments @("storagectl", $vmName, "--name", "SATA", "--add", "sata", "--controller", "IntelAhci") | Out-Null
    Invoke-VBoxManage -Arguments @("createmedium", "disk", "--filename", $vdiPath, "--size", $VBoxDiskSize, "--format", "VDI") | Out-Null
    Invoke-VBoxManage -Arguments @("storageattach", $vmName, "--storagectl", "SATA", "--port", "0", "--device", "0", "--type", "hdd", "--medium", $vdiPath) | Out-Null

    # Attach SINGLE ISO (key difference - no CIDATA!)
    Write-Host "  Attaching modified ISO (single ISO, no CIDATA)"
    Invoke-VBoxManage -Arguments @("storageattach", $vmName, "--storagectl", "SATA", "--port", "1", "--device", "0", "--type", "dvddrive", "--medium", $ModifiedISOPath) | Out-Null

    Write-Host "  VM created successfully"
    Write-Host "  Done" -ForegroundColor Green
    Write-Host ""

    # Start VM
    Write-Step "Starting autoinstall (this takes 10-15 minutes)..."

    $vmType = if ($Headless) { "headless" } else { "gui" }
    $result = Invoke-VBoxManage -Arguments @("startvm", $vmName, "--type", $vmType)
    if ($result.ExitCode -ne 0) {
        Write-Error "Failed to start VM"
        exit 1
    }

    Write-Host "  Installation started. Watch the VM window for progress."
    Write-Host "  Modified ISO autoinstall: boot -> detect /nocloud/ -> install -> shutdown"
    Write-Host ""

    # Wait for installation
    $installComplete = Wait-InstallComplete -VMName $vmName -TimeoutMinutes 20 -StartType $vmType
    if (-not $installComplete) {
        Write-Error "Installation did not complete within timeout"
        exit 1
    }
    Write-Host "  Done" -ForegroundColor Green
    Write-Host ""

    # SSH setup
    $fwSSHPort = $SSHPort + ($FirmwareList.IndexOf($currentFirmware))
    Write-Step "Configuring SSH access (port $fwSSHPort)..."

    Add-SSHPortForward -VMName $vmName -HostPort $fwSSHPort | Out-Null
    $sshReady = Wait-SSHReady -Port $fwSSHPort -TimeoutSeconds 180
    if (-not $sshReady) {
        Write-Error "SSH not available after installation"
        exit 1
    }
    Write-Host "  Done" -ForegroundColor Green
    Write-Host ""

    # Wait for cloud-init
    Write-Step "Waiting for cloud-init to complete..."
    Wait-CloudInitComplete -User $SSHUser -Port $fwSSHPort -TimeoutMinutes 10 | Out-Null
    Write-Host "  Done" -ForegroundColor Green
    Write-Host ""

    # ============================================================================
    # Run Tests
    # ============================================================================

    Write-Step "Running validation tests ($currentFirmware)..."
    Write-Host ""

    $script:currentTestPort = $fwSSHPort
    $script:currentTestFirmware = $currentFirmware

    # Modified ISO Specific Tests
    Write-Host "--- Modified ISO (Lefeck) Specific Tests ---" -ForegroundColor Yellow

    Test-ViaSSH -TestId "L.1" -Name "Nocloud datasource used" -Command "cloud-init query ds" -ExpectedPattern "NoCloud"
    Test-ViaSSH -TestId "L.2" -Name "user-data from /cdrom/nocloud" -Command "grep -l nocloud /var/log/installer/autoinstall-user-data 2>/dev/null || cat /var/log/cloud-init.log | grep -q cdrom && echo OK" -ExpectedPattern "OK|nocloud"

    Write-Host ""

    # Standard Autoinstall Tests
    Write-Host "--- Autoinstall Tests ---" -ForegroundColor Yellow

    Test-ViaSSH -TestId "7.2.1" -Name "Root filesystem is ext4" -Command "df -T / | grep -E 'ext4|xfs'" -ExpectedPattern "ext4|xfs"
    Test-ViaSSH -TestId "7.2.2" -Name "Root mounted" -Command "mount | grep ' / '" -ExpectedPattern "on / type"
    Test-ViaSSH -TestId "7.2.3" -Name "Boot partition exists" -Command "df /boot | grep -v Filesystem" -ExpectedPattern "/boot"
    Test-ViaSSH -TestId "7.2.4" -Name "Installer log exists" -Command "test -d /var/log/installer && echo EXISTS" -ExpectedPattern "EXISTS"
    Test-ViaSSH -TestId "7.2.5" -Name "Autoinstall user-data captured" -Command "test -f /var/log/installer/autoinstall-user-data && echo EXISTS" -ExpectedPattern "EXISTS"
    Test-ViaSSH -TestId "7.2.6" -Name "UEFI boot entry" -Command "efibootmgr | grep -i ubuntu" -ExpectedPattern "ubuntu" -SkipOnBios
    Test-ViaSSH -TestId "7.2.6b" -Name "BIOS GRUB installed" -Command "test -d /boot/grub && echo EXISTS" -ExpectedPattern "EXISTS" -SkipOnEfi
    Test-ViaSSH -TestId "7.2.7" -Name "No cdrom mounted" -Command "mount | grep -q cdrom && echo MOUNTED || echo OK" -ExpectedPattern "OK"
    Test-ViaSSH -TestId "7.2.8" -Name "Cloud-init status done" -Command "cloud-init status" -ExpectedPattern "status: done|status: degraded"

    Write-Host ""

    # Cloud-init Fragment Tests
    Write-Host "--- Cloud-init Fragment Tests ---" -ForegroundColor Yellow

    Test-ViaSSH -TestId "6.1.1" -Name "Hostname set" -Command "hostname -f" -ExpectedPattern "\."
    Test-ViaSSH -TestId "6.1.2" -Name "Network connectivity" -Command "ping -c1 -W5 8.8.8.8 >/dev/null && echo OK" -ExpectedPattern "OK"
    Test-ViaSSH -TestId "6.3.1" -Name "Admin user exists" -Command "id $SSHUser" -ExpectedPattern "uid="
    Test-ViaSSH -TestId "6.3.2" -Name "Admin in sudo group" -Command "groups $SSHUser" -ExpectedPattern "\bsudo\b"
    Test-ViaSSH -TestId "6.4.1" -Name "SSH hardening config" -Command "test -f /etc/ssh/sshd_config.d/99-hardening.conf && echo EXISTS" -ExpectedPattern "EXISTS"
    Test-ViaSSH -TestId "6.5.1" -Name "UFW active" -Command "sudo ufw status" -ExpectedPattern "Status: active"
    Test-ViaSSH -TestId "6.9.1" -Name "fail2ban running" -Command "systemctl is-active fail2ban" -ExpectedPattern "^active$"
    Test-ViaSSH -TestId "6.10.1" -Name "libvirtd running" -Command "systemctl is-active libvirtd" -ExpectedPattern "^active$"
    Test-ViaSSH -TestId "6.11.1" -Name "Cockpit socket enabled" -Command "systemctl is-enabled cockpit.socket" -ExpectedPattern "enabled"

    Write-Host ""

    # Store results
    $allFirmwareResults[$currentFirmware] = @{
        Results = $allResults
        PassCount = $passCount
        FailCount = $failCount
    }
    $totalPassCount += $passCount
    $totalFailCount += $failCount

    Write-Host "--- $($currentFirmware.ToUpper()) Summary: $passCount passed, $failCount failed ---" -ForegroundColor $(if ($failCount -gt 0) { "Yellow" } else { "Green" })
    Write-Host ""

    # Cleanup
    if (-not $SkipCleanup) {
        Write-Host "  Cleaning up $vmName..." -ForegroundColor Gray
        Remove-AutoinstallVM -VMName $vmName -VDIPath $vdiPath
    }
}

# ============================================================================
# Overall Summary
# ============================================================================

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " Overall Test Summary (Modified ISO Method)" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Method:        lefeck/ubuntu-autoinstall-generator-tools"
Write-Host "  Ubuntu:        $UbuntuRelease"
Write-Host "  Firmware(s):   $($FirmwareList -join ', ')"
Write-Host "  Total tests:   $($totalPassCount + $totalFailCount)"
Write-Host "  Passed:        $totalPassCount" -ForegroundColor Green
Write-Host "  Failed:        $totalFailCount" -ForegroundColor $(if ($totalFailCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

foreach ($fw in $FirmwareList) {
    $fwResults = $allFirmwareResults[$fw]
    Write-Host "  $($fw.ToUpper()): $($fwResults.PassCount) passed, $($fwResults.FailCount) failed" -ForegroundColor $(if ($fwResults.FailCount -gt 0) { "Yellow" } else { "Green" })
}
Write-Host ""

if ($totalFailCount -gt 0) {
    Write-Host "Failed tests:" -ForegroundColor Red
    foreach ($fw in $FirmwareList) {
        foreach ($result in $allFirmwareResults[$fw].Results) {
            if (-not $result.Pass) {
                Write-Host "  - [$fw] $($result.Test): $($result.Name)" -ForegroundColor Red
            }
        }
    }
    Write-Host ""
}

# Cleanup
if (-not $SkipCleanup) {
    if (-not $SkipBuild) {
        Write-Host "Stopping builder VM..." -ForegroundColor Gray
        multipass stop $BuilderVMName 2>$null
    }
    Write-Host "Done" -ForegroundColor Gray
} else {
    Write-Host "VMs kept running (-SkipCleanup specified)" -ForegroundColor Gray
    foreach ($fw in $FirmwareList) {
        $fwPort = $SSHPort + ($FirmwareList.IndexOf($fw))
        Write-Host "  VirtualBox VM: ${VBoxVMName}-lefeck-${fw} (SSH: ssh -p $fwPort $SSHUser@localhost)"
    }
    Write-Host "  Builder VM:    $BuilderVMName"
}

Write-Host ""
Write-Host "Log file: $LogFile" -ForegroundColor Gray
Write-Host ""

Stop-Transcript | Out-Null

if ($totalFailCount -gt 0) {
    exit 1
} else {
    exit 0
}
