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
