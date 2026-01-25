# Config.ps1 Refactoring Plan

## Current State

There are two Config.ps1 files with different purposes:

### `helpers/Config.ps1`
- **Purpose**: YAML config loading and deep merge utilities
- **Functions**: `Build-TestConfig`, `Merge-DeepHashtable`
- **Status**: Good - provides config loading infrastructure

### `modules/Config.ps1`
- **Purpose**: Fragment-to-test-level mapping
- **Problem**: Hardcoded PowerShell hashtable with fragment names
- **Status**: Should be refactored

Current hardcoded mapping:
```powershell
$cache = @{
    Map = [ordered]@{
        "6.1"  = @{ Fragments = @("network"); Name = "Network" }
        "6.2"  = @{ Fragments = @("kernel"); Name = "Kernel Hardening" }
        # ... 15+ entries
    }
}
```

---

## Proposed Refactoring

### Split modules/Config.ps1 into 2 Files

1. **`modules/TestLevels.ps1`** - Test level query functions
   - `Get-TestLevels`
   - `Get-FragmentsForLevel`
   - `Get-TestName`
   - `Get-LevelsUpTo`
   - `Get-IncludeArgs`

2. **`config/test-levels.yaml`** - Data file (NEW)
   - Move the hardcoded mapping to YAML
   - Loaded at module init via `ConvertFrom-Yaml`

### YAML Schema for test-levels.yaml

```yaml
# Test level definitions for incremental testing
# Each level includes all fragments from previous levels

levels:
  "6.1":
    name: Network
    fragments:
      - network

  "6.2":
    name: Kernel Hardening
    fragments:
      - kernel

  "6.3":
    name: Users
    fragments:
      - users

  "6.4":
    name: SSH Hardening
    fragments:
      - ssh

  "6.5":
    name: UFW Firewall
    fragments:
      - ufw

  "6.6":
    name: System Settings
    fragments:
      - system

  "6.7":
    name: MSMTP Mail
    fragments:
      - msmtp

  "6.8":
    name: Package Security
    fragments:
      - packages
      - pkg-security
      - pkg-upgrade

  "6.9":
    name: Security Monitoring
    fragments:
      - security-mon

  "6.10":
    name: Virtualization
    fragments:
      - virtualization

  "6.11":
    name: Cockpit
    fragments:
      - cockpit

  "6.12":
    name: Claude Code
    fragments:
      - claude-code

  "6.13":
    name: Copilot CLI
    fragments:
      - copilot-cli

  "6.14":
    name: OpenCode
    fragments:
      - opencode

  "6.15":
    name: UI Touches
    fragments:
      - ui

# Special levels for package operations
special:
  "6.8-updates":
    name: Package Manager Updates
    fragments:
      - packages
      - pkg-security
      - pkg-upgrade

  "6.8-summary":
    name: Update Summary
    fragments:
      - packages
      - pkg-security
      - pkg-upgrade

  "6.8-flush":
    name: Notification Flush
    fragments:
      - packages
      - pkg-security
      - pkg-upgrade
```

---

## Implementation Approach

### New modules/TestLevels.ps1

```powershell
param([Parameter(Mandatory = $true)] $SDK)

New-Module -Name SDK.TestLevels -ScriptBlock {
    param([Parameter(Mandatory = $true)] $SDK)
    $mod = @{ SDK = $SDK }
    . "$PSScriptRoot\..\helpers\PowerShell.ps1"

    # Load test levels from YAML
    $yamlPath = "$PSScriptRoot\..\config\test-levels.yaml"
    $yaml = Get-Content $yamlPath -Raw | ConvertFrom-Yaml
    $levels = ConvertTo-OrderedHashtable $yaml.levels
    $special = ConvertTo-OrderedHashtable $yaml.special

    # Merge levels and special into ordered map
    $cache = @{
        Map = [ordered]@{}
    }
    foreach ($key in $levels.Keys) {
        $cache.Map[$key] = @{
            Name = $levels[$key].name
            Fragments = $levels[$key].fragments
        }
    }
    foreach ($key in $special.Keys) {
        $cache.Map[$key] = @{
            Name = $special[$key].name
            Fragments = $special[$key].fragments
        }
    }

    $TestLevels = New-Object PSObject

    Add-ScriptMethods $TestLevels @{
        All = { return $cache.Map.Keys }
        FragmentsFor = {
            param([string]$Level)
            $fragments = @()
            foreach ($key in $cache.Map.Keys) {
                $fragments += $cache.Map[$key].Fragments
                if ($key -eq $Level) { break }
            }
            return $fragments | Select-Object -Unique
        }
        NameOf = {
            param([string]$Level)
            return $cache.Map[$Level].Name
        }
        UpTo = {
            param([string]$Level)
            $result = @()
            foreach ($key in $cache.Map.Keys) {
                $result += $key
                if ($key -eq $Level) { break }
            }
            return $result
        }
        IncludeArgs = {
            param([string]$Level)
            $fragments = $this.FragmentsFor($Level)
            return ($fragments | ForEach-Object { "-i $_" }) -join " "
        }
    }

    $SDK.Extend("TestLevels", $TestLevels)
    Export-ModuleMember -Function @()
} -ArgumentList $SDK | Import-Module -Force
```

---

## Benefits

1. **Data-Driven**: Fragment mappings in YAML are easier to maintain than PowerShell code
2. **Consistent with build.yaml**: Same YAML format used elsewhere in the project
3. **Separation of Concerns**: Logic in PowerShell, data in YAML
4. **Uses Existing Infrastructure**: `ConvertFrom-Yaml` and `ConvertTo-OrderedHashtable` already available in `helpers/PowerShell.ps1`

---

## Migration Steps

1. Create `config/test-levels.yaml` with the mapping data
2. Create `modules/TestLevels.ps1` that loads from YAML
3. Update SDK.ps1 to load TestLevels module
4. Update any code that uses `Get-TestLevels`, etc. to use `$SDK.TestLevels.*`
5. Delete old `modules/Config.ps1`

---

## Relationship to Fragments.ps1

Note: `Fragments.ps1` discovers fragments from `build.yaml` files (layer, test command, expected pattern).

`TestLevels.ps1` defines the *test progression* - which fragments to include at each test level.

These are complementary:
- `Fragments.ps1` = What fragments exist and how to test them
- `TestLevels.ps1` = The order/grouping for incremental testing

Consider whether TestLevels can be derived from Fragments layer information instead of maintaining a separate mapping.
