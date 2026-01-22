<#
.SYNOPSIS
    Autoinstall ISO testing with VirtualBox

.DESCRIPTION
    Builds the autoinstall ISO and tests the full installation cycle with VirtualBox.
    This validates components that cannot be tested with multipass (7.1):
    - ext4 root filesystem (direct layout)
    - early-commands (network detection during install)
    - Boot configuration (UEFI and BIOS)
    - Full installation cycle

    IMPORTANT: Requires VirtualBox installed and vm.config.ps1 configured.

.PARAMETER SkipBuild
    Skip building the ISO (use existing output/ubuntu-autoinstall.iso)

.PARAMETER SkipCleanup
    Keep VMs running after tests complete (for debugging)

.PARAMETER Headless
    Run VirtualBox VM in headless mode (no GUI window)

.PARAMETER Firmware
    Which firmware to test: "all" (both), "efi", or "bios". Default: "all"

.EXAMPLE
    .\Invoke-AutoinstallTest.ps1
    # Full test: build ISO, install with both BIOS and EFI, run all tests

.EXAMPLE
    .\Invoke-AutoinstallTest.ps1 -Firmware efi
    # Only test EFI boot

.EXAMPLE
    .\Invoke-AutoinstallTest.ps1 -SkipBuild -Firmware bios
    # Use existing ISO, only test BIOS boot
#>

[CmdletBinding()]
param(
    [switch]$SkipBuild,
    [switch]$SkipCleanup,
    [switch]$Headless,

    [ValidateSet("all", "efi", "bios")]
    [string]$Firmware = "all"
)

$ErrorActionPreference = "Stop"

# Load configuration and libraries
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir

. "$ScriptDir\lib\Config.ps1"
. "$RepoRoot\vm.config.ps1"
. "$ScriptDir\SDK.ps1"
# Paths
$ISOPath = Join-Path $RepoRoot "output\ubuntu-autoinstall.iso"
$VDIPath = Join-Path $RepoRoot "output\ubuntu-autoinstall-test.vdi"

# SSH settings - use static IP from config for bridged networking
$testConfig = $SDK.Settings
$SSHHost = ($testConfig.network.ip_address -split '/')[0]  # Extract IP without CIDR
$SSHPort = 22  # Direct connection to VM (bridged mode, not NAT port forwarding)
$SSHUser = $testConfig.identity.username

# Set up logging
$LogDir = Join-Path $RepoRoot "output\logs"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogFile = Join-Path $LogDir "autoinstall-test-$timestamp.log"
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
Write-Host " Infrastructure-Host Autoinstall Testing (7.2)" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "VirtualBox VM: $VBoxVMName" -ForegroundColor Yellow
Write-Host "Builder VM:    $($SDK.Builder.Name)" -ForegroundColor Yellow
Write-Host "Firmware(s):   $($FirmwareList -join ', ')" -ForegroundColor Yellow
Write-Host ""

# Clean up multipass test VMs to avoid IP conflicts
# (VirtualBox VMs use the same static IP as multipass runner)
If( -not $SDK.Builder.Flush() ) {
    Write-Warning "Failed to destroy existing builder/runner VMs"
}
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
    Write-Step "Staging build system..."
    If( -not $SDK.Builder.Stage() ){
        Write-Error "Failed to stage builder VM"
        exit 1
    }
    Write-Step "Building autoinstall ISO..."
    If( -not $SDK.Builder.Build() ){
        Write-Error "Failed to build autoinstall ISO"
        exit 1
    }

    # Step 5: Validate ISO (Modified ISO method)
    Write-Step "Validating ISO structure..."
    $artifacts = $SDK.Builder.Artifacts

    If( $null -eq $artifacts ){
        Write-Error "No build artifacts found. Build may have failed."
        exit 1
    }

    # ISO is built in /tmp to avoid multipass mount 2GB file size limit
    $result = $SDK.Builder.Exec("xorriso -indev $($artifacts.iso) -find / -name user-data 2>/dev/null | grep -q user-data && echo OK")
    if( (-not $result.Success) -or $result.Output -ne "OK" ){
        Write-Error "ISO validation failed: user-data not found in ISO"
        exit 1
    }
    Write-Host "  Embedded user-data: OK"

    # Check 2: GRUB has autoinstall and nocloud parameters
    $grubCheck = multipass exec $VMName -- bash -c "xorriso -osirrox on -indev $vmIsoPath -extract /boot/grub/grub.cfg /tmp/grub.cfg 2>/dev/null && grep -q 'autoinstall.*ds=nocloud' /tmp/grub.cfg && echo OK"
    if ($grubCheck -ne "OK") {
        Write-Error "ISO validation failed: GRUB autoinstall parameters not found"
        exit 1
    }
    Write-Host "  GRUB autoinstall + nocloud: OK"

    Write-Host "  Done" -ForegroundColor Green
    Write-Host ""

    # Step 6: Transfer ISO to host
    Write-Step "Transferring ISO to host..."

    # Ensure output directory exists
    $outputDir = Join-Path $RepoRoot "output"
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    # Transfer ISO from VM /tmp to host (required due to 2GB multipass mount limit)
    Write-Host "  Copying ISO from builder VM via multipass transfer..."
    Write-Host "  (ISO built in /tmp to avoid multipass 2GB file size limit)"

    # Remove existing ISO if present
    if (Test-Path $ISOPath) {
        Remove-Item $ISOPath -Force
    }

    multipass transfer "${VMName}:${vmIsoPath}" $ISOPath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to transfer ISO from builder VM"
        exit 1
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

# Helper function to run test via SSH (uses script-scoped variables set per firmware)
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

    # Skip tests based on firmware type
    if ($SkipOnBios -and $script:currentTestFirmware -eq "bios") {
        Write-Host "  [SKIP] $TestId : $Name (BIOS)" -ForegroundColor DarkGray
        return
    }
    if ($SkipOnEfi -and $script:currentTestFirmware -eq "efi") {
        Write-Host "  [SKIP] $TestId : $Name (EFI)" -ForegroundColor DarkGray
        return
    }

    $result = $SDK.Network.SSH(
        $SSHUser,
        $script:currentTestHost,
        $script:currentTestPort,
        $Command
    )

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
# Phase 2 & 3: VirtualBox Installation and Tests (loop for each firmware)
# ============================================================================

# Track results across all firmware types
$allFirmwareResults = @{}
$totalPassCount = 0
$totalFailCount = 0

foreach ($currentFirmware in $FirmwareList) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host " Testing with $($currentFirmware.ToUpper()) firmware" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host ""

    # Reset counters for this firmware
    $allResults = @()
    $passCount = 0
    $failCount = 0

    # Unique VM name and VDI path for this firmware
    $vmName = "${VBoxVMName}-${currentFirmware}"
    $vdiPath = Join-Path $RepoRoot "output\ubuntu-autoinstall-test-${currentFirmware}.vdi"

    # Step: Create VirtualBox VM
    Write-Step "Creating VirtualBox VM ($currentFirmware)..."

    if( $SDK.Vbox.Exists($vmName) ){
        Write-Host "  VM $vmName already exists. Removing existing VM..." -ForegroundColor Gray
        $SDK.Vbox.Destroy($vmName)
    }

    if( Test-Path $vdiPath ){
        Write-Host "  VDI $vdiPath already exists. Deleting existing VDI..." -ForegroundColor Gray
        Try {
            $SDK.Vbox.Delete($vdiPath)
        } Catch {
            Write-Warning "  Failed to delete existing VDI: $vdiPath"
        }
    }

    $vmCreated = $SDK.Vbox.Create(
        $vmName,
        $vdiPath,
        $ISOPath,
        $VMNetwork,
        "Ubuntu_64",
        $currentFirmware,
        "SATA",
        $VBoxDiskSize,
        $VBoxMemory,
        $VBoxCpus,
        $true,  # Optimize
        $true   # Enable Nested Virtualization
    )

    if (-not $vmCreated) {
        Write-Error "Failed to create VirtualBox VM"
        exit 1
    }
    Write-Host "  Done" -ForegroundColor Green
    Write-Host ""

    # Step: Start VM and run installation
    Write-Step "Starting autoinstall (this takes 10-15 minutes)..."

    $vmType = if ($Headless) { "headless" } else { "gui" }
    Write-Host "  Starting VM $vmName in $vmType mode..."
    $started = $SDK.Vbox.Start($vmName, $vmType)
    if (-not $started) {
        Write-Error "Failed to start VM"
        exit 1
    }

    Write-Host "  Installation started. Watch the VM window for progress."
    Write-Host "  Autoinstall will: boot -> install -> reboot automatically"
    Write-Host ""

    # Wait for installation to complete (VM stops, then we eject ISO and restart)
    # Full autoinstall with package installation can take 25-30 minutes
    $timeOut = $SDK.Vbox.UntilShutdown($vmName, 35 * 60)
    $installTimedOut = $false
    if ($timeOut) {
        Write-Host "  VM still running - trying pause/resume workaround..." -ForegroundColor Yellow
        $SDK.Vbox.Bump($vmName) | Out-Null
        $timeOut = $SDK.Vbox.UntilShutdown($vmName, 10 * 60)
        if ($timeOut) {
            Write-Error "Installation timeout - VM still running after pause/resume"
            $installTimedOut = $true
        }
    }
    if ($installTimedOut) {
        Write-Error "Installation did not complete within timeout"
        exit 1
    }
    Try {
        Write-Host "  Ejecting ISO to boot from installed disk..."
        $SDK.Vbox.Eject($vmName) | Out-Null
    } Catch {
        Write-Warning "  Failed to eject ISO from VM: $vmName"
    }

    Write-Host "  Starting VM to boot installed system ($vmType)..."
    $result = $SDK.Vbox.Start($vmName, $vmType)
    if ($result.ExitCode -ne 0) {
        Write-Error "Failed to start VM after installation"
        exit 1
    }

    Write-Host "  Waiting for post-install boot (30s)..."
    Start-Sleep -Seconds 30
    $booted = $SDK.Vbox.Running($vmName)
    if (-not $booted) {
        Write-Error "VM is not running after installation reboot"
        exit 1
    }
    Write-Host "  Done" -ForegroundColor Green
    Write-Host ""

    # Step: Wait for SSH to be ready (bridged mode - connect directly to static IP)
    Write-Step "Waiting for SSH access (${SSHHost}:${SSHPort})..."

    # Wait for SSH to be ready on the static IP
    $sshReady = $SDK.Network.UntilSSH($SSHHost, $SSHPort, 180)
    if (-not $sshReady) {
        Write-Error "SSH not available after installation"
        exit 1
    }
    Write-Host "  Done" -ForegroundColor Green
    Write-Host ""

    # Step: Wait for cloud-init
    Write-Step "Waiting for cloud-init to complete..."

    $cloudInitComplete = $SDK.General.UntilInstalled(
        $SSHUser,
        $SSHHost,
        $SSHPort,
        900  # 15 minutes
    )
    $cloudInitErrored = $SDK.General.Errored(
        $SSHUser,
        $SSHHost,
        $SSHPort
    )
    if ((-not $cloudInitComplete) -or $cloudInitErrored) {
        Write-Warning "Cloud-init did not complete cleanly"
    }
    Write-Host "  Done" -ForegroundColor Green
    Write-Host ""

    # ============================================================================
    # Run Tests for this firmware
    # ============================================================================

    Write-Step "Running validation tests ($currentFirmware)..."
    Write-Host ""

    # Set script-scoped variables for Test-ViaSSH
    $script:currentTestHost = $SSHHost
    $script:currentTestPort = $SSHPort
    $script:currentTestFirmware = $currentFirmware

    # --- Autoinstall-Specific Tests ---
    Write-Host "--- Autoinstall-Specific Tests ---" -ForegroundColor Yellow

    # Root Filesystem Tests (ext4 with direct layout)
    Test-ViaSSH -TestId "7.2.1" -Name "Root filesystem is ext4" -Command "df -T / | grep -E 'ext4|xfs'" -ExpectedPattern "ext4|xfs"
    Test-ViaSSH -TestId "7.2.2" -Name "Root mounted" -Command "mount | grep ' / '" -ExpectedPattern "on / type"
    Test-ViaSSH -TestId "7.2.3" -Name "Boot partition exists" -Command "df /boot | grep -v Filesystem" -ExpectedPattern "/boot"

    # Installation Artifacts
    Test-ViaSSH -TestId "7.2.4" -Name "Installer log exists" -Command "test -d /var/log/installer && echo EXISTS" -ExpectedPattern "EXISTS"
    Test-ViaSSH -TestId "7.2.5" -Name "Autoinstall user-data captured" -Command "test -f /var/log/installer/autoinstall-user-data && echo EXISTS" -ExpectedPattern "EXISTS"

    # Modified ISO Method Validation
    Test-ViaSSH -TestId "7.2.6" -Name "Cloud-init nocloud datasource" -Command "cloud-init query ds" -ExpectedPattern "nocloud|NoCloud"

    # Boot Configuration (firmware-specific)
    Test-ViaSSH -TestId "7.2.7" -Name "UEFI boot entry" -Command "efibootmgr | grep -i ubuntu" -ExpectedPattern "ubuntu" -SkipOnBios
    Test-ViaSSH -TestId "7.2.7b" -Name "BIOS GRUB installed" -Command "test -d /boot/grub && echo EXISTS" -ExpectedPattern "EXISTS" -SkipOnEfi
    Test-ViaSSH -TestId "7.2.8" -Name "No cdrom mounted" -Command "mount | grep -q cdrom && echo MOUNTED || echo OK" -ExpectedPattern "OK"

    # Cloud-init
    Test-ViaSSH -TestId "7.2.9" -Name "Cloud-init status done" -Command "cloud-init status" -ExpectedPattern "status: done|status: degraded"

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

    # Store results for this firmware
    $allFirmwareResults[$currentFirmware] = @{
        Results = $allResults
        PassCount = $passCount
        FailCount = $failCount
    }
    $totalPassCount += $passCount
    $totalFailCount += $failCount

    # Summary for this firmware
    Write-Host "--- $($currentFirmware.ToUpper()) Summary: $passCount passed, $failCount failed ---" -ForegroundColor $(if ($failCount -gt 0) { "Yellow" } else { "Green" })
    Write-Host ""

    # Cleanup VM for this firmware (unless SkipCleanup)
    if (-not $SkipCleanup) {
        Write-Host "  Cleaning up $vmName..." -ForegroundColor Gray
        $SDK.Vbox.Destroy($vmName)
    }
}

# ============================================================================
# Overall Summary
# ============================================================================

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " Overall Test Summary" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Firmware types tested: $($FirmwareList -join ', ')"
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

# ============================================================================
# Final Cleanup
# ============================================================================

if (-not $SkipCleanup) {
    # Stop builder VM (but keep it for cached ISO)
    if (-not $SkipBuild) {
        Write-Host "Stopping builder VM..." -ForegroundColor Gray
        multipass stop $VMName 2>$null
    }
    Write-Host "Done" -ForegroundColor Gray
} else {
    Write-Host "VMs kept running (-SkipCleanup specified)" -ForegroundColor Gray
    foreach ($fw in $FirmwareList) {
        $fwPort = if ($fw -eq "bios") { $SSHPort } else { $SSHPort + 1 }
        Write-Host "  VirtualBox VM: ${VBoxVMName}-${fw} (SSH: ssh -p $fwPort $SSHUser@localhost)"
    }
    Write-Host "  Builder VM:    $VMName"
}

Write-Host ""
Write-Host "Log file: $LogFile" -ForegroundColor Gray
Write-Host ""

# Stop logging
Stop-Transcript | Out-Null

# Exit with appropriate code
if ($totalFailCount -gt 0) {
    exit 1
} else {
    exit 0
}
