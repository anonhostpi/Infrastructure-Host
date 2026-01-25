# Settings.ps1 Refactoring Plan

## Naming Conventions

PowerShell is case-insensitive, so property access works regardless of stored key case:
- `$SDK.Settings.Identity` works even if key is `identity`
- `$SDK.Settings.Identity.Username` works even if nested key is `username`

**Factory should generate PascalCase property names** and strip special characters:
- `identity.config.yaml` → `$SDK.Settings.Identity`
- `test-levels.yaml` → `$SDK.Settings.TestLevels` (hyphen stripped)
- `claude_code.config.yaml` → `$SDK.Settings.ClaudeCode` (underscore stripped)

**File naming**: Keep existing lowercase/hyphenated names. Factory transforms them.

---

## Current State

### helpers/Config.ps1 - `Build-TestConfig`

```powershell
function Build-TestConfig {
    param(
        [string]$ConfigDir = "src/config"  # <-- STALE PATH
    )
    # ...
    $configFiles = Get-ChildItem -Path $ConfigDir -Filter "*.config.yaml"
    foreach ($file in $configFiles) {
        $key = $file.Name -replace '\.config\.yaml$', ''
        # Auto-unwrap and load...
        $config[$key] = $yaml
    }
    # Apply testing overrides...
    return $config
}
```

**Problem**: `src/config` no longer exists. Configs are now in fragment directories:
- `book-1-foundation/base/config/*.config.yaml`
- `book-2-cloud/*/config/*.config.yaml`

**Bug**: Malformed count check:
```powershell
# Current (broken):
if ($yaml -is [hashtable] -and $yaml.Count -eq 1)

# Fixed:
if ($yaml -is [hashtable] -and ($yaml.Keys | ForEach-Object { $_ }).Count -eq 1)
```

### modules/Settings.ps1 - Factory Pattern

```powershell
$mod.BuildConfig = Build-TestConfig  # Loads configs

# Factory: creates $SDK.Settings.<Key> for each config key
$keys = $mod.BuildConfig.Keys | ForEach-Object { $_ }
$methods = @{}
foreach( $key in $keys ) {
    $src = @(
        "",
        "`$key = '$key'",
        { return $mod.BuildConfig[$key] }.ToString(),
        ""
    ) -join "`n"
    $sb = iex "{ $src }"
    $methods[$key] = $sb
}
Add-ScriptProperties $Settings $methods
```

**This factory already exists** - once `Build-TestConfig` loads the configs, properties are auto-created.

**Needed**: Transform keys to PascalCase and strip special chars:
```powershell
# Convert "identity" → "Identity", "test-levels" → "TestLevels"
function ConvertTo-PascalCase {
    param([string]$Name)
    # Split on special chars, capitalize each part, join
    return ($Name -split '[-_]' | ForEach-Object {
        $_.Substring(0,1).ToUpper() + $_.Substring(1)
    }) -join ''
}

foreach ($key in $keys) {
    $propertyName = ConvertTo-PascalCase $key
    # ... create property with $propertyName
}
```

---

## Fragment Config Locations

| Config | Fragment Path |
|--------|---------------|
| identity | `book-2-cloud/users/config/identity.config.yaml` |
| network | `book-2-cloud/network/config/network.config.yaml` |
| testing | `book-1-foundation/base/config/testing.config.yaml` |
| image | `book-1-foundation/base/config/image.config.yaml` |
| storage | `book-1-foundation/base/config/storage.config.yaml` |
| smtp | `book-2-cloud/msmtp/config/smtp.config.yaml` |
| cockpit | `book-2-cloud/cockpit/config/cockpit.config.yaml` |
| claude_code | `book-2-cloud/claude-code/config/claude_code.config.yaml` |
| copilot_cli | `book-2-cloud/copilot-cli/config/copilot_cli.config.yaml` |
| opencode | `book-2-cloud/opencode/config/opencode.config.yaml` |

---

## Proposed Refactoring

### Option 1: Update `Build-TestConfig` to scan fragment directories

```powershell
function Build-TestConfig {
    param(
        [string[]]$ConfigDirs = @("book-1-foundation", "book-2-cloud")
    )

    $config = @{}
    $git_root = git rev-parse --show-toplevel 2>$null

    # Scan for all *.config.yaml in fragment config directories
    foreach ($baseDir in $ConfigDirs) {
        $searchPath = Join-Path $git_root $baseDir
        $configFiles = Get-ChildItem -Path $searchPath -Recurse -Filter "*.config.yaml" -ErrorAction SilentlyContinue
        foreach ($file in $configFiles) {
            $key = $file.Name -replace '\.config\.yaml$', ''
            # ... existing auto-unwrap and load logic
            $config[$key] = $yaml
        }
    }

    # Apply testing overrides (unchanged)
    # ...

    return $config
}
```

**Result**: `$SDK.Settings.identity`, `$SDK.Settings.network`, etc. auto-populated via existing factory.

### Option 2: Load test-levels.yaml in Settings

Add test levels loading alongside virtualization config:

```powershell
$mod.VirtConfig = $Settings.Load("vm.config.yaml")
$mod.TestLevels = $Settings.Load("book-0-builder/host-sdk/config/test-levels.yaml")

Add-ScriptProperties $Settings @{
    Virtualization = { return $mod.VirtConfig }
    TestLevels = { return $mod.TestLevels }
}
```

Then Testing.ps1 can use `$mod.SDK.Settings.TestLevels` instead of loading YAML directly.

---

## Integration with Testing.ps1

Current plan has Testing.ps1 loading test-levels.yaml directly:

```powershell
$levelsPath = "$PSScriptRoot\..\config\test-levels.yaml"
$levelsYaml = Get-Content $levelsPath -Raw | ConvertFrom-Yaml
```

**Alternative**: Use Settings to centralize all config loading:

```powershell
$mod.Levels = $mod.SDK.Settings.TestLevels.Levels
```

---

## Integration with Vbox.ps1

Current plan has Vbox.ps1 calling `$mod.SDK.Settings.Load()`:

```powershell
$identity = $mod.SDK.Settings.Load("book-2-cloud/users/config/identity.config.yaml")
$rendered.SSHUser = $identity.identity.username
```

**With refactored Settings**: Already loaded and available:

```powershell
$rendered.SSHUser = $mod.SDK.Settings.Identity.Username
```

---

## Benefits

1. **Single source of truth**: All configs loaded once in Settings.ps1
2. **Auto-discovery**: Factory pattern creates properties for all loaded configs
3. **Consistent access**: `$SDK.Settings.<Config>` pattern everywhere (PascalCase)
4. **Testing overrides**: Already handled by `Build-TestConfig`

---

## Implementation Order

1. Update `helpers/Config.ps1` - `Build-TestConfig` to scan fragment directories
2. Add `TestLevels` property to Settings.ps1
3. Update Testing.ps1 to use `$SDK.Settings.TestLevels`
4. Update Vbox.ps1 to use `$SDK.Settings.identity` instead of `Load()`
5. Verify `$SDK.Settings.identity`, `$SDK.Settings.network`, etc. are populated

---

## Relationship to Existing Plan

This refactoring affects:
- **Commit 63** (Testing.ps1 YAML loading) - use Settings instead
- **Commit 71** (Vbox.ps1 SSH derivation) - use Settings.identity instead of Load()

May require additional commits before those to refactor Settings.ps1 first.
