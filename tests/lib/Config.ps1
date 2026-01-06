# Test Configuration - Fragment to Test Mapping
# This file defines the incremental test structure

# Fragment order for incremental testing
# Each test level includes all fragments from previous levels
#
# testing.config.yaml enables multipass-specific network protection (skip NAT interface).
# The users fragment uses runcmd to avoid interfering with cloud provider's default user.
$Script:FragmentMap = [ordered]@{
    "6.1"  = @{ Fragments = @("10-network"); Name = "Network" }
    "6.2"  = @{ Fragments = @("15-kernel"); Name = "Kernel Hardening" }
    "6.3"  = @{ Fragments = @("20-users"); Name = "Users" }
    "6.4"  = @{ Fragments = @("25-ssh"); Name = "SSH Hardening" }
    "6.5"  = @{ Fragments = @("30-ufw"); Name = "UFW Firewall" }
    "6.6"  = @{ Fragments = @("40-system"); Name = "System Settings" }
    "6.7"  = @{ Fragments = @("45-msmtp"); Name = "MSMTP Mail" }
    "6.8"  = @{ Fragments = @("50-packages", "50-pkg-security"); Name = "Package Security" }
    "6.9"  = @{ Fragments = @("55-security-mon"); Name = "Security Monitoring" }
    "6.10" = @{ Fragments = @("60-virtualization"); Name = "Virtualization" }
    "6.11" = @{ Fragments = @("70-cockpit"); Name = "Cockpit" }
    "6.12" = @{ Fragments = @("75-opencode"); Name = "OpenCode" }
    "6.13" = @{ Fragments = @("90-ui"); Name = "UI Touches" }
}

# Get all test levels in order
function Get-TestLevels {
    return $Script:FragmentMap.Keys | ForEach-Object { $_ }
}

# Get fragments needed for a given test level (cumulative)
function Get-FragmentsForLevel {
    param([string]$Level)

    $fragments = @()
    foreach ($key in $Script:FragmentMap.Keys) {
        $fragments += $Script:FragmentMap[$key].Fragments
        if ($key -eq $Level) { break }
    }
    return $fragments
}

# Get test name for a level
function Get-TestName {
    param([string]$Level)
    return $Script:FragmentMap[$Level].Name
}

# Get all levels up to and including the given level
function Get-LevelsUpTo {
    param([string]$Level)

    $levels = @()
    foreach ($key in $Script:FragmentMap.Keys) {
        $levels += $key
        if ($key -eq $Level) { break }
    }
    return $levels
}

# Build the -i include arguments for the builder
function Get-IncludeArgs {
    param([string]$Level)

    $fragments = Get-FragmentsForLevel -Level $Level
    $args = ($fragments | ForEach-Object { "-i $_" }) -join " "
    return $args
}

# Deep merge override into base (mirrors Python composer.deep_merge)
function Merge-DeepHashtable {
    param(
        [hashtable]$Base,
        [hashtable]$Override
    )

    $result = $Base.Clone()
    foreach ($key in $Override.Keys) {
        if ($result.ContainsKey($key)) {
            if ($result[$key] -is [hashtable] -and $Override[$key] -is [hashtable]) {
                $result[$key] = Merge-DeepHashtable -Base $result[$key] -Override $Override[$key]
            } elseif ($result[$key] -is [array] -and $Override[$key] -is [array]) {
                $result[$key] = $result[$key] + $Override[$key]
            } else {
                $result[$key] = $Override[$key]
            }
        } else {
            $result[$key] = $Override[$key]
        }
    }
    return $result
}

# Load configuration from YAML files
# Mirrors Python BuildContext: loads all *.config.yaml, auto-unwraps, applies testing overrides
function Get-TestConfig {
    param(
        [string]$ConfigDir = "src/config"
    )

    Import-Module powershell-yaml -ErrorAction SilentlyContinue

    $config = @{}

    # Load all *.config.yaml files (mirrors BuildContext.__init__)
    $configFiles = Get-ChildItem -Path $ConfigDir -Filter "*.config.yaml" -ErrorAction SilentlyContinue
    foreach ($file in $configFiles) {
        $key = $file.Name -replace '\.config\.yaml$', ''
        $content = Get-Content $file.FullName -Raw
        $yaml = ConvertFrom-Yaml $content

        # Auto-unwrap: if single key matches filename, unwrap it
        if ($yaml -is [hashtable] -and $yaml.Count -eq 1) {
            $onlyKey = @($yaml.Keys)[0]
            if ($onlyKey -eq $key) {
                $yaml = $yaml[$onlyKey]
            }
        }

        $config[$key] = $yaml
    }

    # Apply testing config overrides (mirrors BuildContext._apply_testing_overrides)
    $testingConfig = $config['testing']
    if ($testingConfig -is [hashtable] -and $testingConfig['testing'] -eq $true) {
        foreach ($key in $testingConfig.Keys) {
            if ($key -eq 'testing') { continue }

            if ($config.ContainsKey($key) -and $testingConfig[$key] -is [hashtable]) {
                # Deep merge testing override into main config
                $config[$key] = Merge-DeepHashtable -Base $config[$key] -Override $testingConfig[$key]
            } elseif ($testingConfig[$key] -is [hashtable]) {
                # New config section from testing
                $config[$key] = $testingConfig[$key]
            }
        }
    }

    return $config
}

New-Module -ScriptBlock {
    $scope = @{
        Config = $null
    }

    function Get-CachedTestConfig {
        If ($null -eq $scope.Config) {
            $scope.Config = Get-TestConfig
        }
        return $scope.Config
    }

    Export-ModuleMember -Function Get-CachedTestConfig
} -Name Test-Config | Import-Module -Force