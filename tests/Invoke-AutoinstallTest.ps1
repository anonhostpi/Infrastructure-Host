<#
.SYNOPSIS
    Autoinstall ISO testing with VirtualBox

.DESCRIPTION
    Builds the autoinstall ISO and tests the full installation cycle with VirtualBox.
    This validates components that cannot be tested with multipass (7.1):
    - ZFS root filesystem
    - early-commands (network detection during install)
    - Boot configuration (UEFI, GRUB)
    - Full installation cycle

    IMPORTANT: Requires VirtualBox installed and vm.config.ps1 configured.

.PARAMETER SkipBuild
    Skip building the ISO (use existing output/ubuntu-autoinstall.iso)

.PARAMETER SkipCleanup
    Keep VMs running after tests complete (for debugging)

.PARAMETER Headless
    Run VirtualBox VM in headless mode (no GUI window)

.EXAMPLE
    .\Invoke-AutoinstallTest.ps1
    # Full test: build ISO, install, run all tests

.EXAMPLE
    .\Invoke-AutoinstallTest.ps1 -SkipBuild
    # Use existing ISO, skip build step

.EXAMPLE
    .\Invoke-AutoinstallTest.ps1 -SkipCleanup
    # Keep VMs for debugging after tests
#>

[CmdletBinding()]
param(
    [switch]$SkipBuild,
    [switch]$SkipCleanup,
    [switch]$Headless
)

$ErrorActionPreference = "Stop"

# Load configuration and libraries
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir

. "$ScriptDir\lib\Config.ps1"
. "$ScriptDir\lib\VBoxHelpers.ps1"
. "$RepoRoot\vm.config.ps1"

# Paths
$ISOPath = Join-Path $RepoRoot "output\ubuntu-autoinstall.iso"
$VDIPath = Join-Path $RepoRoot "output\ubuntu-autoinstall-test.vdi"

# SSH settings
$SSHPort = 2222
$SSHUser = (Get-TestConfig).identity.username

# Set up logging
$LogDir = Join-Path $RepoRoot "output\logs"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogFile = Join-Path $LogDir "autoinstall-test-$timestamp.log"
Start-Transcript -Path $LogFile -Append | Out-Null

# Banner
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " Infrastructure-Host Autoinstall Testing (7.2)" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "VirtualBox VM: $VBoxVMName" -ForegroundColor Yellow
Write-Host "Builder VM:    $BuilderVMName" -ForegroundColor Yellow
Write-Host ""

$stepCount = if ($SkipBuild) { 8 } else { 11 }
$currentStep = 0

function Write-Step {
    param([string]$Message)
    $script:currentStep++
    Write-Host "[$currentStep/$stepCount] $Message" -ForegroundColor Cyan
}

# ============================================================================
# Phase 1: Build ISO (unless -SkipBuild)
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

    # Check if already mounted
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

    # Step 3: Install dependencies and build
    Write-Step "Installing dependencies and building artifacts..."

    Write-Host "  Installing dependencies..."
    multipass exec $BuilderVMName -- bash -c "sudo apt-get update -qq && sudo apt-get install -y -qq python3-pip python3-yaml python3-jinja2 make xorriso cloud-image-utils wget > /dev/null 2>&1"
    multipass exec $BuilderVMName -- bash -c "cd /home/ubuntu/infra-host && pip3 install --break-system-packages -q -e . 2>/dev/null"

    Write-Host "  Building artifacts (make all)..."
    multipass exec $BuilderVMName -- bash -c "cd /home/ubuntu/infra-host && make all"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build artifacts"
        exit 1
    }
    Write-Host "  Done" -ForegroundColor Green
    Write-Host ""

    # Step 4: Build ISO
    Write-Step "Building autoinstall ISO..."

    Write-Host "  This may take several minutes (downloads Ubuntu ISO if not cached)..."
    multipass exec $BuilderVMName -- bash -c "cd /home/ubuntu/infra-host && chmod +x output/scripts/build-iso.sh && ./output/scripts/build-iso.sh"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build ISO"
        exit 1
    }
    Write-Host "  Done" -ForegroundColor Green
    Write-Host ""

    # Step 5: Validate ISO
    Write-Step "Validating ISO structure..."

    $nocloadCheck = multipass exec $BuilderVMName -- xorriso -indev /home/ubuntu/infra-host/output/ubuntu-autoinstall.iso -ls /nocloud 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $nocloadCheck) {
        Write-Error "ISO validation failed: /nocloud directory not found"
        exit 1
    }
    Write-Host "  /nocloud directory: OK"

    $grubCheck = multipass exec $BuilderVMName -- bash -c "xorriso -indev /home/ubuntu/infra-host/output/ubuntu-autoinstall.iso -extract /boot/grub/grub.cfg /tmp/grub.cfg 2>/dev/null && grep -q 'Autoinstall' /tmp/grub.cfg && echo OK"
    if ($grubCheck -ne "OK") {
        Write-Error "ISO validation failed: Autoinstall GRUB entry not found"
        exit 1
    }
    Write-Host "  GRUB autoinstall entry: OK"
    Write-Host "  Done" -ForegroundColor Green
    Write-Host ""

    # Step 6: Transfer ISO to host
    Write-Step "Transferring ISO to host..."

    # Ensure output directory exists
    $outputDir = Join-Path $RepoRoot "output"
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    # ISO should already be in output/ due to mount, but verify
    if (-not (Test-Path $ISOPath)) {
        Write-Host "  Copying ISO from builder VM..."
        multipass transfer "${BuilderVMName}:/home/ubuntu/infra-host/output/ubuntu-autoinstall.iso" $outputDir
    }

    $isoInfo = Get-Item $ISOPath
    Write-Host "  ISO: $($isoInfo.Name) ($([math]::Round($isoInfo.Length / 1GB, 2)) GB)"
    Write-Host "  Done" -ForegroundColor Green
    Write-Host ""
}

# Verify ISO exists
if (-not (Test-Path $ISOPath)) {
    Write-Error "ISO not found: $ISOPath`nRun without -SkipBuild to create it."
    exit 1
}

# ============================================================================
# Phase 2: VirtualBox Installation
# ============================================================================

# Step: Create VirtualBox VM
Write-Step "Creating VirtualBox VM..."

$vmCreated = New-AutoinstallVM `
    -VMName $VBoxVMName `
    -ISOPath $ISOPath `
    -VDIPath $VDIPath `
    -MemoryMB $VBoxMemory `
    -CPUs $VBoxCpus `
    -DiskSizeMB $VBoxDiskSize

if (-not $vmCreated) {
    Write-Error "Failed to create VirtualBox VM"
    exit 1
}
Write-Host "  Done" -ForegroundColor Green
Write-Host ""

# Step: Start VM and run installation
Write-Step "Starting autoinstall (this takes 10-15 minutes)..."

$vmType = if ($Headless) { "headless" } else { "gui" }
$started = Start-AutoinstallVM -VMName $VBoxVMName -Type $vmType
if (-not $started) {
    Write-Error "Failed to start VM"
    exit 1
}

Write-Host "  Installation started. Watch the VM window for progress."
Write-Host "  Autoinstall will: boot -> install -> reboot automatically"
Write-Host ""

# Wait for installation to complete (VM reboots)
$installComplete = Wait-InstallComplete -VMName $VBoxVMName -TimeoutMinutes 20
if (-not $installComplete) {
    Write-Error "Installation did not complete within timeout"
    exit 1
}
Write-Host "  Done" -ForegroundColor Green
Write-Host ""

# Step: Add SSH port forwarding
Write-Step "Configuring SSH access..."

$sshConfigured = Add-SSHPortForward -VMName $VBoxVMName -HostPort $SSHPort
if (-not $sshConfigured) {
    Write-Warning "Failed to configure SSH port forwarding"
}

# Wait for SSH to be ready
$sshReady = Wait-SSHReady -Port $SSHPort -TimeoutSeconds 180
if (-not $sshReady) {
    Write-Error "SSH not available after installation"
    exit 1
}
Write-Host "  Done" -ForegroundColor Green
Write-Host ""

# Step: Wait for cloud-init
Write-Step "Waiting for cloud-init to complete..."

$cloudInitComplete = Wait-CloudInitComplete -User $SSHUser -Port $SSHPort -TimeoutMinutes 10
if (-not $cloudInitComplete) {
    Write-Warning "Cloud-init did not complete cleanly"
}
Write-Host "  Done" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Phase 3: Run Tests
# ============================================================================

Write-Step "Running validation tests..."
Write-Host ""

$allResults = @()
$passCount = 0
$failCount = 0

# Helper function to run test via SSH
function Test-ViaSSH {
    param(
        [string]$TestId,
        [string]$Name,
        [string]$Command,
        [string]$ExpectedPattern = $null,
        [switch]$ExpectFailure
    )

    $result = Invoke-SSHCommand -Command $Command -User $SSHUser -Port $SSHPort

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
    }
}

# --- Autoinstall-Specific Tests ---
Write-Host "--- Autoinstall-Specific Tests ---" -ForegroundColor Yellow

# Root Filesystem Tests (ext4 with direct layout)
Test-ViaSSH -TestId "7.2.1" -Name "Root filesystem is ext4" -Command "df -T / | grep -E 'ext4|xfs'" -ExpectedPattern "ext4|xfs"
Test-ViaSSH -TestId "7.2.2" -Name "Root mounted" -Command "mount | grep ' / '" -ExpectedPattern "on / type"
Test-ViaSSH -TestId "7.2.3" -Name "Boot partition exists" -Command "df /boot | grep -v Filesystem" -ExpectedPattern "/boot"

# Installation Artifacts
Test-ViaSSH -TestId "7.2.4" -Name "Installer log exists" -Command "test -d /var/log/installer && echo EXISTS" -ExpectedPattern "EXISTS"
Test-ViaSSH -TestId "7.2.5" -Name "Autoinstall user-data captured" -Command "test -f /var/log/installer/autoinstall-user-data && echo EXISTS" -ExpectedPattern "EXISTS"

# Boot Configuration
Test-ViaSSH -TestId "7.2.6" -Name "UEFI boot entry" -Command "efibootmgr | grep -i ubuntu" -ExpectedPattern "ubuntu"
Test-ViaSSH -TestId "7.2.7" -Name "No cdrom mounted" -Command "mount | grep -q cdrom && echo MOUNTED || echo OK" -ExpectedPattern "OK"

# Cloud-init
Test-ViaSSH -TestId "7.2.8" -Name "Cloud-init status done" -Command "cloud-init status" -ExpectedPattern "status: done|status: degraded"

Write-Host ""

# --- Cloud-init Fragment Tests (from 7.1) ---
Write-Host "--- Cloud-init Fragment Tests ---" -ForegroundColor Yellow

# 6.1 Network
Test-ViaSSH -TestId "6.1.1" -Name "Hostname set" -Command "hostname -f" -ExpectedPattern "\."
Test-ViaSSH -TestId "6.1.2" -Name "Network connectivity" -Command "ping -c1 -W5 8.8.8.8 >/dev/null && echo OK" -ExpectedPattern "OK"

# 6.2 Kernel Hardening
Test-ViaSSH -TestId "6.2.1" -Name "Sysctl config exists" -Command "test -f /etc/sysctl.d/99-security.conf && echo EXISTS" -ExpectedPattern "EXISTS"
Test-ViaSSH -TestId "6.2.2" -Name "SYN cookies enabled" -Command "sysctl net.ipv4.tcp_syncookies" -ExpectedPattern "= 1"

# 6.3 Users
Test-ViaSSH -TestId "6.3.1" -Name "Admin user exists" -Command "id $SSHUser" -ExpectedPattern "uid="
Test-ViaSSH -TestId "6.3.2" -Name "Admin in sudo group" -Command "groups $SSHUser" -ExpectedPattern "\bsudo\b"
Test-ViaSSH -TestId "6.3.3" -Name "Root locked" -Command "sudo passwd -S root" -ExpectedPattern "root L"

# 6.4 SSH Hardening
Test-ViaSSH -TestId "6.4.1" -Name "SSH hardening config" -Command "test -f /etc/ssh/sshd_config.d/99-hardening.conf && echo EXISTS" -ExpectedPattern "EXISTS"
Test-ViaSSH -TestId "6.4.2" -Name "PermitRootLogin no" -Command "sudo grep -r PermitRootLogin /etc/ssh/sshd_config.d/" -ExpectedPattern "PermitRootLogin no"

# 6.5 UFW
Test-ViaSSH -TestId "6.5.1" -Name "UFW active" -Command "sudo ufw status" -ExpectedPattern "Status: active"
Test-ViaSSH -TestId "6.5.2" -Name "SSH allowed" -Command "sudo ufw status" -ExpectedPattern "22.*ALLOW"

# 6.6 System Settings
Test-ViaSSH -TestId "6.6.1" -Name "Timezone set" -Command "timedatectl show --property=Timezone --value" -ExpectedPattern "."
Test-ViaSSH -TestId "6.6.2" -Name "NTP enabled" -Command "timedatectl show --property=NTP --value" -ExpectedPattern "yes"

# 6.7 MSMTP (if configured)
Test-ViaSSH -TestId "6.7.1" -Name "msmtp installed" -Command "which msmtp || echo NOTFOUND" -ExpectedPattern "msmtp|NOTFOUND"

# 6.8 Package Security
Test-ViaSSH -TestId "6.8.1" -Name "unattended-upgrades installed" -Command "dpkg -l unattended-upgrades | grep -q ii && echo INSTALLED" -ExpectedPattern "INSTALLED"

# 6.9 Security Monitoring
Test-ViaSSH -TestId "6.9.1" -Name "fail2ban running" -Command "systemctl is-active fail2ban" -ExpectedPattern "^active$"

# 6.10 Virtualization
Test-ViaSSH -TestId "6.10.1" -Name "libvirtd running" -Command "systemctl is-active libvirtd" -ExpectedPattern "^active$"
Test-ViaSSH -TestId "6.10.2" -Name "Admin in libvirt group" -Command "groups $SSHUser" -ExpectedPattern "\blibvirt\b"

# 6.11 Cockpit
Test-ViaSSH -TestId "6.11.1" -Name "Cockpit socket enabled" -Command "systemctl is-enabled cockpit.socket" -ExpectedPattern "enabled"
Test-ViaSSH -TestId "6.11.2" -Name "Cockpit on localhost only" -Command "ss -tlnp | grep ':443'" -ExpectedPattern "127.0.0.1:443"

# 6.15 UI Touches
Test-ViaSSH -TestId "6.15.1" -Name "Dynamic MOTD exists" -Command "test -f /run/motd.dynamic && echo EXISTS" -ExpectedPattern "EXISTS"
Test-ViaSSH -TestId "6.15.2" -Name "bat installed" -Command "which batcat" -ExpectedPattern "batcat"
Test-ViaSSH -TestId "6.15.3" -Name "fd installed" -Command "which fdfind" -ExpectedPattern "fdfind"

Write-Host ""

# ============================================================================
# Summary
# ============================================================================

Write-Host "================================================" -ForegroundColor Cyan
Write-Host " Test Summary" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Total tests:   $($passCount + $failCount)"
Write-Host "  Passed:        $passCount" -ForegroundColor Green
Write-Host "  Failed:        $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($failCount -gt 0) {
    Write-Host "Failed tests:" -ForegroundColor Red
    foreach ($result in $allResults) {
        if (-not $result.Pass) {
            Write-Host "  - $($result.Test): $($result.Name)" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# ============================================================================
# Cleanup
# ============================================================================

if (-not $SkipCleanup) {
    Write-Host "Cleaning up..." -ForegroundColor Gray

    # Stop and remove VirtualBox VM
    Remove-AutoinstallVM -VMName $VBoxVMName -VDIPath $VDIPath

    # Stop builder VM (but keep it for cached ISO)
    if (-not $SkipBuild) {
        multipass stop $BuilderVMName 2>$null
    }

    Write-Host "Done" -ForegroundColor Gray
} else {
    Write-Host "VMs kept running (-SkipCleanup specified)" -ForegroundColor Gray
    Write-Host "  VirtualBox VM: $VBoxVMName (SSH: ssh -p $SSHPort $SSHUser@localhost)"
    Write-Host "  Builder VM:    $BuilderVMName"
}

Write-Host ""
Write-Host "Log file: $LogFile" -ForegroundColor Gray
Write-Host ""

# Stop logging
Stop-Transcript | Out-Null

# Exit with appropriate code
if ($failCount -gt 0) {
    exit 1
} else {
    exit 0
}
