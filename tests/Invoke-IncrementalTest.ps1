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

# Step 2b: Copy OAuth credentials from host to builder VM
Write-Host "[2b/6] Setting up AI CLI credentials..." -ForegroundColor Cyan

# Claude Code credentials
$claudeCredsPath = "$env:USERPROFILE\.claude\.credentials.json"
$claudeStatePath = "$env:USERPROFILE\.claude.json"
$claudeCredsExist = (Test-Path $claudeCredsPath) -and (Test-Path $claudeStatePath)

if ($claudeCredsExist) {
    Write-Host "  Found Claude Code credentials on host"
    multipass exec $VMName -- bash -c "mkdir -p /home/ubuntu/.claude"

    # Copy credentials.json
    $credsContent = Get-Content $claudeCredsPath -Raw
    $credsContent = $credsContent -replace '"', '\"'
    multipass exec $VMName -- bash -c "cat > /home/ubuntu/.claude/.credentials.json << 'EOFCREDS'
$(Get-Content $claudeCredsPath -Raw)
EOFCREDS"

    # Copy state file
    multipass exec $VMName -- bash -c "cat > /home/ubuntu/.claude.json << 'EOFSTATE'
$(Get-Content $claudeStatePath -Raw)
EOFSTATE"

    Write-Host "  Copied Claude Code credentials to builder VM" -ForegroundColor Green
} else {
    Write-Host "  Claude Code credentials not found on host" -ForegroundColor Yellow
    Write-Host "  Please authenticate Claude Code on this machine:" -ForegroundColor Yellow
    Write-Host "    1. Run 'claude' in a terminal" -ForegroundColor Gray
    Write-Host "    2. Complete the OAuth flow" -ForegroundColor Gray
    Write-Host "    3. Re-run this test script" -ForegroundColor Gray
    Write-Host ""
    $response = Read-Host "  Continue without Claude Code auth? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "  Aborting. Please authenticate Claude Code first." -ForegroundColor Red
        exit 1
    }
}

# Copilot CLI credentials
$copilotConfigPath = "$env:USERPROFILE\.copilot\config.json"
$copilotCredsExist = $false

if (Test-Path $copilotConfigPath) {
    $copilotConfig = Get-Content $copilotConfigPath -Raw | ConvertFrom-Json
    if ($copilotConfig.copilot_tokens -and ($copilotConfig.copilot_tokens.PSObject.Properties.Count -gt 0)) {
        $copilotCredsExist = $true
    }
}

if ($copilotCredsExist) {
    Write-Host "  Found Copilot CLI credentials in config.json"
    multipass exec $VMName -- bash -c "mkdir -p /home/ubuntu/.copilot"

    # Copy config.json (contains copilot_tokens)
    multipass exec $VMName -- bash -c "cat > /home/ubuntu/.copilot/config.json << 'EOFCOPILOT'
$(Get-Content $copilotConfigPath -Raw)
EOFCOPILOT"

    Write-Host "  Copied Copilot CLI credentials to builder VM" -ForegroundColor Green
} else {
    # Try to extract from Windows Credential Manager using Node.js
    $extractedToken = $false
    $copilotDir = "$env:USERPROFILE\.copilot"

    if (Test-Path $copilotDir) {
        Write-Host "  Attempting to extract Copilot token from credential store..."

        # Create extraction script
        $extractScript = @'
const path = require('path');
const fs = require('fs');
const os = require('os');

const COPILOT_DIR = path.join(os.homedir(), '.copilot');
const CONFIG_PATH = path.join(COPILOT_DIR, 'config.json');

function findKeytar() {
  const pkgDir = path.join(COPILOT_DIR, 'pkg');
  const platforms = ['win32-x64', 'darwin-arm64', 'darwin-x64', 'linux-x64'];
  for (const platform of platforms) {
    const platformPath = path.join(pkgDir, platform);
    if (fs.existsSync(platformPath)) {
      const versions = fs.readdirSync(platformPath);
      for (const version of versions) {
        const nodePath = path.join(platformPath, version, 'prebuilds', platform, 'keytar.node');
        if (fs.existsSync(nodePath)) return require(nodePath);
      }
    }
  }
  return null;
}

async function main() {
  const keytar = findKeytar();
  if (!keytar) { console.log('NO_KEYTAR'); return; }

  const creds = await keytar.findCredentials('copilot-cli');
  if (creds.length === 0) { console.log('NO_CREDS'); return; }

  const config = fs.existsSync(CONFIG_PATH)
    ? JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'))
    : {};

  config.copilot_tokens = config.copilot_tokens || {};
  config.logged_in_users = config.logged_in_users || [];

  for (const cred of creds) {
    config.copilot_tokens[cred.account] = cred.password;
    const [host, login] = cred.account.split(':');
    if (!config.logged_in_users.find(u => u.host === host && u.login === login)) {
      config.logged_in_users.push({ host, login });
    }
    if (!config.last_logged_in_user) {
      config.last_logged_in_user = { host, login };
    }
  }

  fs.writeFileSync(CONFIG_PATH, JSON.stringify(config, null, 2));
  console.log('EXTRACTED');
}

main().catch(() => console.log('ERROR'));
'@
        $scriptPath = Join-Path $env:TEMP "extract-copilot-token.js"
        $extractScript | Out-File -FilePath $scriptPath -Encoding utf8

        try {
            $result = node $scriptPath 2>&1
            if ($result -eq "EXTRACTED") {
                Write-Host "  Extracted token from credential store" -ForegroundColor Green
                $extractedToken = $true

                # Re-read and copy the updated config
                multipass exec $VMName -- bash -c "mkdir -p /home/ubuntu/.copilot"
                multipass exec $VMName -- bash -c "cat > /home/ubuntu/.copilot/config.json << 'EOFCOPILOT'
$(Get-Content $copilotConfigPath -Raw)
EOFCOPILOT"
                Write-Host "  Copied Copilot CLI credentials to builder VM" -ForegroundColor Green
            }
        } catch {
            # Node.js extraction failed
        } finally {
            Remove-Item $scriptPath -ErrorAction SilentlyContinue
        }
    }

    if (-not $extractedToken) {
        # Try environment variables (in order of precedence)
        $envToken = $env:COPILOT_GITHUB_TOKEN
        if (-not $envToken) { $envToken = $env:GH_TOKEN }
        if (-not $envToken) { $envToken = $env:GITHUB_TOKEN }

        if ($envToken) {
            Write-Host "  Found Copilot token in environment variable"

            # Create config.json with token
            multipass exec $VMName -- bash -c "mkdir -p /home/ubuntu/.copilot"
            multipass exec $VMName -- bash -c "cat > /home/ubuntu/.copilot/config.json << 'EOFCOPILOT'
{
  `"copilot_tokens`": {
    `"https://github.com:env-user`": `"$envToken`"
  },
  `"logged_in_users`": [
    { `"host`": `"https://github.com`", `"login`": `"env-user`" }
  ],
  `"last_logged_in_user`": {
    `"host`": `"https://github.com`",
    `"login`": `"env-user`"
  }
}
EOFCOPILOT"
            Write-Host "  Copied Copilot CLI token from env to builder VM" -ForegroundColor Green
            $extractedToken = $true
        }
    }

    if (-not $extractedToken) {
        Write-Host "  Copilot CLI credentials not found" -ForegroundColor Yellow
        Write-Host "  Please authenticate Copilot CLI on this machine:" -ForegroundColor Yellow
        Write-Host "    1. Run 'copilot' in a terminal" -ForegroundColor Gray
        Write-Host "    2. Use '/login' command to authenticate" -ForegroundColor Gray
        Write-Host "    3. Or set COPILOT_GITHUB_TOKEN environment variable" -ForegroundColor Gray
        Write-Host ""
        $response = Read-Host "  Continue without Copilot CLI auth? (y/N)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            Write-Host "  Aborting. Please authenticate Copilot CLI first." -ForegroundColor Red
            exit 1
        }
    }
}

Write-Host "  Done" -ForegroundColor Green
Write-Host ""

# Step 2c: Verify AI CLI authentication on builder VM
Write-Host "[2c/6] Verifying AI CLI authentication..." -ForegroundColor Cyan

# Install the CLIs on builder VM for verification
Write-Host "  Installing Node.js and AI CLIs on builder VM..."
multipass exec $VMName -- bash -c "command -v node || (curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo bash - && sudo apt-get install -y nodejs) > /dev/null 2>&1"

# Verify Claude Code auth if credentials were provided
if ($claudeCredsExist) {
    Write-Host "  Verifying Claude Code authentication..."
    multipass exec $VMName -- bash -c "npm install -g @anthropic-ai/claude-code > /dev/null 2>&1"
    $claudeVerify = multipass exec $VMName -- bash -c "HOME=/home/ubuntu claude --version 2>&1"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Claude Code verification failed: $claudeVerify"
        Write-Host "  Auth credentials may be invalid or expired" -ForegroundColor Red
        exit 1
    }
    Write-Host "  Claude Code: OK" -ForegroundColor Green
}

# Verify Copilot CLI auth if credentials were provided
if ($copilotCredsExist -or $extractedToken) {
    Write-Host "  Verifying Copilot CLI authentication..."
    multipass exec $VMName -- bash -c "npm install -g @githubnext/github-copilot-cli > /dev/null 2>&1"
    $copilotVerify = multipass exec $VMName -- bash -c "HOME=/home/ubuntu copilot --version 2>&1"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Copilot CLI verification failed: $copilotVerify"
        Write-Host "  Auth credentials may be invalid or expired" -ForegroundColor Red
        exit 1
    }
    Write-Host "  Copilot CLI: OK" -ForegroundColor Green
}

Write-Host "  Done" -ForegroundColor Green
Write-Host ""

# Step 3: Build cloud-init with selected fragments
Write-Host "[3/6] Building cloud-init..." -ForegroundColor Cyan

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
Write-Host "[4/6] Launching runner VM..." -ForegroundColor Cyan

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
Write-Host "[5/6] Enabling nested virtualization..." -ForegroundColor Cyan

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
Write-Host "[6/6] Running tests..." -ForegroundColor Cyan
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

# Exit with appropriate code
if ($failCount -gt 0) {
    exit 1
} else {
    exit 0
}
