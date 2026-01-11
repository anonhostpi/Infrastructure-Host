<#
.SYNOPSIS
    Incremental cloud-init fragment testing

.DESCRIPTION
    Runs incremental tests for cloud-init fragments. Each test level includes
    all previous fragments, providing cumulative validation.

    IMPORTANT: Every test run starts fresh - destroys existing VMs, rebuilds
    cloud-init, and runs ALL tests from 6.1 up to the specified level.

    NOTE: This script requires an ELEVATED (Administrator) PowerShell session
    to enable nested virtualization for the runner VM. Tests at level 6.10+
    verify nested VM functionality which requires Hyper-V nested virtualization.

.PARAMETER Level
    Test level to run (6.1 through 6.13). Runs all tests up to and including
    this level. Use "all" for full integration test (7.2).

.PARAMETER SkipCleanup
    Keep VMs running after tests complete (for debugging).

.EXAMPLE
    .\Invoke-IncrementalTest.ps1 -Level 6.1
    # Tests only the network fragment

.EXAMPLE
    .\Invoke-IncrementalTest.ps1 -Level 6.5
    # Tests fragments 6.1 through 6.5 (network, kernel, users, ssh, ufw)

.EXAMPLE
    .\Invoke-IncrementalTest.ps1 -Level all
    # Full integration test with all fragments (7.2)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("6.1", "6.2", "6.3", "6.4", "6.5", "6.6", "6.7", "6.8", "6.9", "6.10", "6.11", "6.12", "6.13", "6.14", "6.15", "all")]
    [string]$Level,

    [switch]$SkipCleanup
)

$ErrorActionPreference = "Stop"

# Load configuration and libraries
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir

. "$ScriptDir\lib\Config.ps1"
. "$ScriptDir\lib\Verifications.ps1"
. "$RepoRoot\vm.config.ps1"

# Determine actual test level
$TestLevel = if ($Level -eq "all") { "6.15" } else { $Level }

# Set up logging to output/logs directory
$LogDir = Join-Path $RepoRoot "output\logs"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogFile = Join-Path $LogDir "test-$Level-$timestamp.log"
Start-Transcript -Path $LogFile -Append | Out-Null

# Banner
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Infrastructure-Host Incremental Tests" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Test Level: $Level" -ForegroundColor Yellow
Write-Host "Levels to test: $(Get-LevelsUpTo -Level $TestLevel)" -ForegroundColor Gray
Write-Host ""

# Step 1: Clean up any existing VMs
Write-Host "[1/6] Cleaning up existing VMs..." -ForegroundColor Cyan

$existingRunner = multipass list --format csv 2>$null | Select-String "^$RunnerVMName,"
if ($existingRunner) {
    Write-Host "  Deleting runner VM: $RunnerVMName"
    multipass delete $RunnerVMName --purge 2>$null
}

$existingBuilder = multipass list --format csv 2>$null | Select-String "^$VMName,"
if ($existingBuilder) {
    Write-Host "  Deleting builder VM: $VMName"
    multipass delete $VMName --purge 2>$null
}

Write-Host "  Done" -ForegroundColor Green
Write-Host ""

# Step 2: Set up builder VM
Write-Host "[2/6] Setting up builder VM..." -ForegroundColor Cyan

Write-Host "  Launching: $VMName"
multipass launch --name $VMName --cpus $VMCpus --memory $VMMemory --disk $VMDisk
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to launch builder VM"
    exit 1
}

Write-Host "  Waiting for cloud-init..."
multipass exec $VMName -- cloud-init status --wait 2>$null

Write-Host "  Mounting repository..."
multipass mount $RepoRoot ${VMName}:/home/ubuntu/infra-host
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to mount repository"
    exit 1
}

Write-Host "  Installing dependencies..."
multipass exec $VMName -- bash -c "sudo apt-get update -qq && sudo apt-get install -y -qq python3-pip python3-yaml python3-jinja2 make > /dev/null"
multipass exec $VMName -- bash -c "cd /home/ubuntu/infra-host && pip3 install --break-system-packages -q -e . 2>/dev/null"

Write-Host "  Done" -ForegroundColor Green
Write-Host ""

# Copy AI CLI credentials to builder VM if testing AI CLI fragments (6.12+)
# Check if test level is 6.12 or higher (AI CLI fragments start at 6.12)
# Note: Version comparison must compare major.minor as integers, not decimals
# (6.2 as decimal = 6.20 > 6.12, but as version 6.2 < 6.12)
$levelParts = $TestLevel -split '\.'
$testMajor = [int]$levelParts[0]
$testMinor = [int]$levelParts[1]
$needsAICreds = (($testMajor -gt 6) -or ($testMajor -eq 6 -and $testMinor -ge 12)) -or ($Level -eq "all")

if ($needsAICreds) {
    Write-Host "Setting up AI CLI credentials for builder..." -ForegroundColor Cyan

    # Claude Code credentials (for 6.12+)
    $claudeCredsPath = "$env:USERPROFILE\.claude\.credentials.json"
    $claudeStatePath = "$env:USERPROFILE\.claude.json"
    if ((Test-Path $claudeCredsPath) -and (Test-Path $claudeStatePath)) {
        multipass exec $VMName -- bash -c "mkdir -p /home/ubuntu/.claude"
        multipass transfer $claudeCredsPath ${VMName}:/home/ubuntu/.claude/.credentials.json
        multipass transfer $claudeStatePath ${VMName}:/home/ubuntu/.claude.json
        Write-Host "  Claude Code credentials copied" -ForegroundColor Green
    } else {
        Write-Host "  Claude Code credentials not found (optional)" -ForegroundColor Yellow
    }

    # Copilot CLI credentials (for 6.13+)
    $copilotConfigPath = "$env:USERPROFILE\.copilot\config.json"
    if (Test-Path $copilotConfigPath) {
        multipass exec $VMName -- bash -c "mkdir -p /home/ubuntu/.copilot"
        multipass transfer $copilotConfigPath ${VMName}:/home/ubuntu/.copilot/config.json
        Write-Host "  Copilot CLI credentials copied" -ForegroundColor Green
    } else {
        Write-Host "  Copilot CLI credentials not found (optional)" -ForegroundColor Yellow
    }

    Write-Host ""
}

# Step 3: Build cloud-init with selected fragments
Write-Host "[3/4] Building cloud-init..." -ForegroundColor Cyan

$fragments = Get-FragmentsForLevel -Level $TestLevel
$includeArgs = Get-IncludeArgs -Level $TestLevel

Write-Host "  Fragments: $($fragments -join ', ')"
Write-Host "  Builder args: $includeArgs"

$buildCmd = "cd /home/ubuntu/infra-host && python3 -m builder render cloud-init -o output/cloud-init.yaml $includeArgs"
multipass exec $VMName -- bash -c $buildCmd
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to build cloud-init"
    exit 1
}

# Copy cloud-init to host for runner VM
$cloudInitPath = Join-Path $RepoRoot "output\cloud-init.yaml"
Write-Host "  Output: $cloudInitPath"
Write-Host "  Done" -ForegroundColor Green
Write-Host ""

# Step 4: Launch runner VM with generated cloud-init
Write-Host "[4/4] Launching runner VM..." -ForegroundColor Cyan

Write-Host "  Name: $RunnerVMName"
Write-Host "  Network: $RunnerNetwork"

multipass launch `
    --name $RunnerVMName `
    --cpus $RunnerCpus `
    --memory $RunnerMemory `
    --disk $RunnerDisk `
    --network $RunnerNetwork `
    --cloud-init $cloudInitPath

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to launch runner VM"
    exit 1
}

# Step 5: Enable nested virtualization (requires elevated shell)
Write-Host "Enabling nested virtualization..." -ForegroundColor Cyan

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    Write-Host "  Stopping VM for reconfiguration..."
    multipass stop $RunnerVMName
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to stop VM for nested virt configuration"
    } else {
        Write-Host "  Enabling ExposeVirtualizationExtensions..."
        try {
            Set-VMProcessor -VMName $RunnerVMName -ExposeVirtualizationExtensions $true
            Write-Host "  Nested virtualization enabled" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to enable nested virtualization: $_"
        }

        Write-Host "  Starting VM..."
        multipass start $RunnerVMName
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to restart runner VM after nested virt configuration"
            exit 1
        }
    }
} else {
    Write-Host "  WARNING: Not running as Administrator" -ForegroundColor Yellow
    Write-Host "  Nested virtualization will NOT be enabled." -ForegroundColor Yellow
    Write-Host "  Run this script in an elevated PowerShell to enable nested VM tests." -ForegroundColor Yellow
}

Write-Host "  Done" -ForegroundColor Green
Write-Host ""

Write-Host "  Waiting for cloud-init to complete..."
multipass exec $RunnerVMName -- cloud-init status --wait

# Check cloud-init status
$ciStatus = multipass exec $RunnerVMName -- cloud-init status 2>&1
if ($ciStatus -match "error" -or $ciStatus -match "degraded") {
    Write-Host "  WARNING: Cloud-init reported issues" -ForegroundColor Yellow
    Write-Host "  Status: $ciStatus"
}

# Brief delay to let services stabilize
Write-Host "  Waiting for services to stabilize..."
Start-Sleep -Seconds 5

Write-Host "  Done" -ForegroundColor Green
Write-Host ""

# Step 6: Run all tests up to the specified level
Write-Host "Running tests..." -ForegroundColor Cyan
Write-Host ""

$allResults = @()
$passCount = 0
$failCount = 0

$levelsToTest = Get-LevelsUpTo -Level $TestLevel

foreach ($testLevel in $levelsToTest) {
    $testName = Get-TestName -Level $testLevel
    Write-Host "--- Test $testLevel : $testName ---" -ForegroundColor Yellow

    $results = Invoke-TestForLevel -Level $testLevel -VMName $RunnerVMName

    foreach ($result in $results) {
        $status = if ($result.Pass) { "[PASS]" } else { "[FAIL]" }
        $color = if ($result.Pass) { "Green" } else { "Red" }

        Write-Host "  $status $($result.Test): $($result.Name)" -ForegroundColor $color

        if ($result.Pass) {
            $passCount++
        } else {
            $failCount++
            Write-Host "         Output: $($result.Output)" -ForegroundColor Gray
        }

        $allResults += @{
            Level = $testLevel
            Test = $result.Test
            Name = $result.Name
            Pass = $result.Pass
            Output = $result.Output
        }
    }
    Write-Host ""
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Levels tested: $($levelsToTest -join ', ')"
Write-Host "  Total tests:   $($passCount + $failCount)"
Write-Host "  Passed:        $passCount" -ForegroundColor Green
Write-Host "  Failed:        $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($failCount -gt 0) {
    Write-Host "Failed tests:" -ForegroundColor Red
    foreach ($result in $allResults) {
        if (-not $result.Pass) {
            Write-Host "  - $($result.Level) / $($result.Test): $($result.Name)" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# Cleanup
if (-not $SkipCleanup) {
    Write-Host "Cleaning up VMs..." -ForegroundColor Gray
    multipass delete $RunnerVMName --purge 2>$null
    multipass delete $VMName --purge 2>$null
    Write-Host "Done" -ForegroundColor Gray
} else {
    Write-Host "VMs kept running (use -SkipCleanup:$false to clean up)" -ForegroundColor Gray
    Write-Host "  Builder: $VMName"
    Write-Host "  Runner:  $RunnerVMName"
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
