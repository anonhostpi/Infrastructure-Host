# Test Configuration - Fragment to Test Mapping
# This file defines the incremental test structure

# Fragment order for incremental testing
# Each test level includes all fragments from previous levels
#
# testing.config.yaml enables multipass-specific network protection (skip NAT interface).
# The users fragment uses runcmd to avoid interfering with cloud provider's default user.

New-Module -Name Test-Fragments -ScriptBlock {
    $cache = @{
        Map = [ordered]@{
            "6.1"  = @{ Fragments = @("network"); Name = "Network" }
            "6.2"  = @{ Fragments = @("kernel"); Name = "Kernel Hardening" }
            "6.3"  = @{ Fragments = @("users"); Name = "Users" }
            "6.4"  = @{ Fragments = @("ssh"); Name = "SSH Hardening" }
            "6.5"  = @{ Fragments = @("ufw"); Name = "UFW Firewall" }
            "6.6"  = @{ Fragments = @("system"); Name = "System Settings" }
            "6.7"  = @{ Fragments = @("msmtp"); Name = "MSMTP Mail" }
            "6.8"  = @{ Fragments = @("packages", "pkg-security", "pkg-upgrade"); Name = "Package Security" }
            "6.9"  = @{ Fragments = @("security-mon"); Name = "Security Monitoring" }
            "6.10" = @{ Fragments = @("virtualization"); Name = "Virtualization" }
            "6.11" = @{ Fragments = @("cockpit"); Name = "Cockpit" }
            "6.12" = @{ Fragments = @("claude-code"); Name = "Claude Code" }
            "6.13" = @{ Fragments = @("copilot-cli"); Name = "Copilot CLI" }
            "6.14" = @{ Fragments = @("opencode"); Name = "OpenCode" }
            "6.15" = @{ Fragments = @("ui"); Name = "UI Touches" }
            "6.8-updates" = @{ Fragments = @("packages", "pkg-security", "pkg-upgrade"); Name = "Package Manager Updates" }
            "6.8-summary" = @{ Fragments = @("packages", "pkg-security", "pkg-upgrade"); Name = "Update Summary" }
            "6.8-flush" = @{ Fragments = @("packages", "pkg-security", "pkg-upgrade"); Name = "Notification Flush" }
        }
    }

    function Get-TestLevels {
        return $cache.Map.Keys | ForEach-Object { $_ }
    }

    function Get-FragmentsForLevel {
        param([string]$Level)

        $fragments = @()
        foreach ($key in $cache.Map.Keys) {
            $fragments += $cache.Map[$key].Fragments
            if ($key -eq $Level) { break }
        }
        # Return unique fragments (preserving order)
        return $fragments | Select-Object -Unique
    }

    function Get-TestName {
        param([string]$Level)
        return $cache.Map[$Level].Name
    }

    function Get-LevelsUpTo {
        param([string]$Level)

        $levels = @()
        foreach ($key in $cache.Map.Keys) {
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

    Export-ModuleMember -Function Get-TestLevels, Get-FragmentsForLevel, Get-TestName, Get-LevelsUpTo, Get-IncludeArgs
} | Import-Module -Force