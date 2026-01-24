<#
.ARCHIVE
    This file is archived for reference. It documents an alternate build approach
    using Ventoy USB auto_install plugin for bare-metal deployment.

    Archived: 2026-01-24
    Reason: Refactor to fragment-based architecture. Ventoy approach may be
            revisited for physical deployment tooling in the future.
#>

<#
.SYNOPSIS
    Ventoy USB autoinstall testing

.DESCRIPTION
    Tests the Ventoy auto_install plugin method for Ubuntu autoinstall.

    IMPORTANT: Ventoy auto_install does NOT work in VirtualBox or VMs!
    The auto_install plugin relies on USB device enumeration that VMs
    don't properly emulate. VM testing shows interactive installer instead
    of automated installation.

    For VM testing, use the CIDATA method or lefeck Modified ISO method.
    See: docs/TESTING_AND_VALIDATION/TEMP_7_2_LEFECK_TESTING.md

    This script is for USB bare-metal deployment only. It provides:
    - USB preparation automation
    - Manual test guidance
    - Post-install validation (if target is network accessible)

    The Ventoy method uses:
    - Unmodified Ubuntu ISO
    - ventoy.json configuration
    - user-data in ventoy/autoinstall/ directory

.PARAMETER USBDrive
    Drive letter of the Ventoy USB drive (e.g., "E:")

.PARAMETER SkipUSBPrep
    Skip USB preparation (assume Ventoy already configured)

.PARAMETER TargetIP
    IP address of the target machine after installation (for validation)

.PARAMETER SkipValidation
    Skip post-install validation tests

.EXAMPLE
    .\TEMP_Invoke-VentoyTest.ps1 -USBDrive E:
    # Prepare USB and provide manual test instructions

.EXAMPLE
    .\TEMP_Invoke-VentoyTest.ps1 -USBDrive E: -TargetIP 192.168.1.100
    # Prepare USB and run validation after manual install
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$USBDrive,

    [switch]$SkipUSBPrep,
    [switch]$SkipValidation,

    [string]$TargetIP,
    [string]$TargetUser = "admin",
    [int]$SSHPort = 22
)

$ErrorActionPreference = "Stop"

# Load configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir

. "$ScriptDir\lib\Config.ps1"
. "$RepoRoot\vm.config.ps1"

# Paths
$UserDataPath = Join-Path $RepoRoot "output\user-data"
$UbuntuISOPattern = "ubuntu-*-live-server-*.iso"

# Banner
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " Ventoy USB Autoinstall Testing (TEMP)" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "USB Drive:     $USBDrive" -ForegroundColor Yellow
Write-Host "Target IP:     $(if ($TargetIP) { $TargetIP } else { '(manual)' })" -ForegroundColor Yellow
Write-Host ""

# ============================================================================
# Phase 1: Verify Prerequisites
# ============================================================================

Write-Host "[1/5] Verifying prerequisites..." -ForegroundColor Cyan

# Check USB drive exists
if (-not (Test-Path $USBDrive)) {
    Write-Error "USB drive not found: $USBDrive"
    exit 1
}

# Check if Ventoy is installed on USB
$ventoyDir = Join-Path $USBDrive "ventoy"
if (-not (Test-Path $ventoyDir)) {
    Write-Warning "Ventoy directory not found on $USBDrive"
    Write-Host "  Please install Ventoy on the USB drive first:"
    Write-Host "  1. Download from https://www.ventoy.net/en/download.html"
    Write-Host "  2. Run Ventoy2Disk.exe"
    Write-Host "  3. Select $USBDrive and click Install"
    Write-Host ""

    if (-not $SkipUSBPrep) {
        $response = Read-Host "Continue anyway? (y/n)"
        if ($response -ne 'y') {
            exit 1
        }
        # Create ventoy directory
        New-Item -ItemType Directory -Path $ventoyDir -Force | Out-Null
    }
}

# Check user-data exists
if (-not (Test-Path $UserDataPath)) {
    Write-Host "  user-data not found. Building..." -ForegroundColor Yellow
    Push-Location $RepoRoot
    & make autoinstall
    Pop-Location

    if (-not (Test-Path $UserDataPath)) {
        Write-Error "Failed to build user-data"
        exit 1
    }
}

Write-Host "  Done" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Phase 2: Prepare USB Drive
# ============================================================================

if (-not $SkipUSBPrep) {
    Write-Host "[2/5] Preparing Ventoy USB..." -ForegroundColor Cyan

    # Create autoinstall directory structure
    $autoinstallDir = Join-Path $ventoyDir "autoinstall\ubuntu-server"
    if (-not (Test-Path $autoinstallDir)) {
        New-Item -ItemType Directory -Path $autoinstallDir -Force | Out-Null
    }

    # Copy user-data
    Write-Host "  Copying user-data..."
    Copy-Item $UserDataPath (Join-Path $autoinstallDir "user-data") -Force

    # Create meta-data
    Write-Host "  Creating meta-data..."
    Set-Content (Join-Path $autoinstallDir "meta-data") "instance-id: autoinstall-ventoy-001"

    # Create ventoy.json
    Write-Host "  Creating ventoy.json..."
    $ventoyJson = @{
        auto_install = @(
            @{
                image = "/ubuntu-*.iso"
                template = @("/ventoy/autoinstall/ubuntu-server")
            }
        )
    } | ConvertTo-Json -Depth 4

    Set-Content (Join-Path $ventoyDir "ventoy.json") $ventoyJson

    # Check for Ubuntu ISO on USB
    $existingISO = Get-ChildItem -Path $USBDrive -Filter $UbuntuISOPattern -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $existingISO) {
        Write-Host ""
        Write-Warning "No Ubuntu ISO found on USB drive!"
        Write-Host "  Please download and copy Ubuntu Server ISO to $USBDrive"
        Write-Host "  Example: ubuntu-24.04.3-live-server-amd64.iso"
        Write-Host ""
    } else {
        Write-Host "  Found ISO: $($existingISO.Name)"
    }

    Write-Host "  Done" -ForegroundColor Green
    Write-Host ""

    # Show USB structure
    Write-Host "  USB Structure:" -ForegroundColor Yellow
    Write-Host "  $USBDrive"
    Get-ChildItem $USBDrive -Filter "*.iso" | ForEach-Object { Write-Host "  ├── $($_.Name)" }
    Write-Host "  └── ventoy\"
    Write-Host "      ├── ventoy.json"
    Write-Host "      └── autoinstall\"
    Write-Host "          └── ubuntu-server\"
    Write-Host "              ├── user-data"
    Write-Host "              └── meta-data"
    Write-Host ""
} else {
    Write-Host "[2/5] Skipping USB preparation (-SkipUSBPrep)" -ForegroundColor Gray
    Write-Host ""
}

# ============================================================================
# Phase 3: Display Manual Test Instructions
# ============================================================================

Write-Host "[3/5] Manual Installation Steps" -ForegroundColor Cyan
Write-Host ""
Write-Host "  IMPORTANT: Ventoy testing requires physical hardware or a separate VM host." -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Insert USB drive into target machine"
Write-Host "  2. Boot from USB (select in BIOS boot menu)"
Write-Host "  3. Ventoy menu appears - select Ubuntu ISO"
Write-Host "  4. Installation should start automatically (no prompts)"
Write-Host "  5. Wait for installation to complete (~15 minutes)"
Write-Host "  6. System reboots to installed OS"
Write-Host ""
Write-Host "  Known Issue: dm-0 device crash" -ForegroundColor Yellow
Write-Host "  If installation fails at storage partitioning, you need explicit storage config."
Write-Host "  See: docs/AUTOINSTALL_MEDIA_CREATION/TEMP_CHAPTER_5.md"
Write-Host ""

if (-not $TargetIP) {
    Write-Host "  No -TargetIP specified. Skipping automated validation." -ForegroundColor Gray
    Write-Host "  To run validation after install:"
    Write-Host "    .\TEMP_Invoke-VentoyTest.ps1 -USBDrive $USBDrive -TargetIP <IP> -SkipUSBPrep"
    Write-Host ""

    Write-Host "[4/5] Skipping (no target IP)" -ForegroundColor Gray
    Write-Host "[5/5] Skipping (no target IP)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "USB preparation complete. Proceed with manual installation." -ForegroundColor Green
    exit 0
}

# ============================================================================
# Phase 4: Wait for Installation (if TargetIP provided)
# ============================================================================

Write-Host "[4/5] Waiting for target to be available..." -ForegroundColor Cyan
Write-Host "  Target: $TargetIP"
Write-Host "  Press Ctrl+C to cancel and run validation later"
Write-Host ""

$timeout = 30 * 60  # 30 minutes
$elapsed = 0
$interval = 30

while ($elapsed -lt $timeout) {
    # Try SSH connection
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    try {
        $asyncResult = $tcpClient.BeginConnect($TargetIP, $SSHPort, $null, $null)
        $waitResult = $asyncResult.AsyncWaitHandle.WaitOne(5000, $false)

        if ($waitResult -and $tcpClient.Connected) {
            $tcpClient.Close()
            Write-Host "  Target is reachable!" -ForegroundColor Green
            break
        }
    } catch {
        # Connection failed
    } finally {
        $tcpClient.Dispose()
    }

    Start-Sleep -Seconds $interval
    $elapsed += $interval
    $mins = [math]::Floor($elapsed / 60)
    Write-Host "  Waiting... (${mins}m / 30m)"
}

if ($elapsed -ge $timeout) {
    Write-Warning "Timeout waiting for target. Run validation manually later."
    exit 1
}

# Wait for SSH to be fully ready
Write-Host "  Waiting for SSH service..."
Start-Sleep -Seconds 30

Write-Host "  Done" -ForegroundColor Green
Write-Host ""

# ============================================================================
# Phase 5: Run Validation Tests
# ============================================================================

if ($SkipValidation) {
    Write-Host "[5/5] Skipping validation (-SkipValidation)" -ForegroundColor Gray
    exit 0
}

Write-Host "[5/5] Running validation tests..." -ForegroundColor Cyan
Write-Host ""

# Helper function for SSH tests
function Test-ViaSSH {
    param(
        [string]$TestId,
        [string]$Name,
        [string]$Command,
        [string]$ExpectedPattern = $null
    )

    $sshArgs = @(
        "-o", "BatchMode=yes",
        "-o", "StrictHostKeyChecking=no",
        "-o", "UserKnownHostsFile=/dev/null",
        "-o", "ConnectTimeout=10",
        "-p", $SSHPort,
        "${TargetUser}@${TargetIP}",
        $Command
    )

    try {
        $output = & ssh @sshArgs 2>&1
        $success = ($LASTEXITCODE -eq 0)

        $pass = $false
        if ($ExpectedPattern) {
            $pass = ($success -and ($output -join "`n") -match $ExpectedPattern)
        } else {
            $pass = $success
        }

        $status = if ($pass) { "[PASS]" } else { "[FAIL]" }
        $color = if ($pass) { "Green" } else { "Red" }

        Write-Host "  $status $TestId : $Name" -ForegroundColor $color

        if ($pass) { $script:passCount++ } else { $script:failCount++ }
    } catch {
        Write-Host "  [FAIL] $TestId : $Name (SSH error)" -ForegroundColor Red
        $script:failCount++
    }
}

$passCount = 0
$failCount = 0

# Ventoy-specific tests
Write-Host "--- Ventoy-Specific Tests ---" -ForegroundColor Yellow

Test-ViaSSH -TestId "V.1" -Name "Cloud-init datasource" -Command "cloud-init query ds" -ExpectedPattern "NoCloud"
Test-ViaSSH -TestId "V.2" -Name "Root filesystem" -Command "df -T / | grep -E 'ext4|xfs'" -ExpectedPattern "ext4|xfs"
Test-ViaSSH -TestId "V.3" -Name "Installation complete" -Command "test -d /var/log/installer && echo OK" -ExpectedPattern "OK"

Write-Host ""

# Standard cloud-init tests
Write-Host "--- Cloud-init Fragment Tests ---" -ForegroundColor Yellow

Test-ViaSSH -TestId "6.1.1" -Name "Hostname set" -Command "hostname -f" -ExpectedPattern "\."
Test-ViaSSH -TestId "6.3.1" -Name "Admin user exists" -Command "id $TargetUser" -ExpectedPattern "uid="
Test-ViaSSH -TestId "6.4.1" -Name "SSH hardening config" -Command "test -f /etc/ssh/sshd_config.d/99-hardening.conf && echo EXISTS" -ExpectedPattern "EXISTS"
Test-ViaSSH -TestId "6.5.1" -Name "UFW active" -Command "sudo ufw status" -ExpectedPattern "Status: active"
Test-ViaSSH -TestId "6.9.1" -Name "fail2ban running" -Command "systemctl is-active fail2ban" -ExpectedPattern "^active$"
Test-ViaSSH -TestId "6.10.1" -Name "libvirtd running" -Command "systemctl is-active libvirtd" -ExpectedPattern "^active$"

Write-Host ""

# Summary
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " Test Summary" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Total:  $($passCount + $failCount)"
Write-Host "  Passed: $passCount" -ForegroundColor Green
Write-Host "  Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($failCount -gt 0) {
    exit 1
} else {
    exit 0
}
