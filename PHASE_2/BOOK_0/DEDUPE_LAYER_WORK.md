# DEDUPE_LAYER_WORK: build_layers Architecture

**Discovery Date:** 2024-01-25
**Type:** Rule 0 Discovery Document
**Updated:** Renamed to build_layers, Builder module ownership, Makefile updates, Runner removal

---

## Final Architecture

### build_layers.yaml (Builder Module Feature)

Location: `book-0-builder/host-sdk/config/build_layers.yaml`

```yaml
# Build layer definitions
# Shared by build logic (Makefile LAYER=) and testing (layer names)

layers:
  0: Base
  1: Network
  2: Kernel Hardening
  3: Users
  4: SSH Hardening
  5: UFW Firewall
  6: System Settings
  7: MSMTP Mail
  8: Package Security
  9: Security Monitoring
  10: Virtualization
  11: Cockpit
  12: Claude Code
  13: Copilot CLI
  14: OpenCode
  15: UI Touches

# Agent-dependent test levels (higher layers, reuse layer 8 fragments)
agent_dependent:
  16:
    name: Package Manager Updates
    fragments: [packages, pkg-security, pkg-upgrade]
  17:
    name: Update Summary
    fragments: [packages, pkg-security, pkg-upgrade]
  18:
    name: Notification Flush
    fragments: [packages, pkg-security, pkg-upgrade]
```

### build_layer in build.yaml (Single Source of Truth)

Each fragment's `build.yaml`:
```yaml
name: network
build_order: 10
build_layer: 1
```

### Ownership

- **Builder module** owns build_layers.yaml
- **Builder module** provides `LayerName(layer)` and `LayerFragments(layer)`
- **Testing module** delegates to Builder for layer info
- **Makefile** uses `LAYER=` parameter that maps to build_layer

---

## Changes Required

### 1. Rename: test-levels.yaml → build_layers.yaml

Move from Testing to Builder concept.

### 2. Builder Module: Add layer methods

```powershell
$SDK.Builder.LayerName(3)        # → "Users"
$SDK.Builder.LayerFragments(3)   # → [base, network, kernel, users]
$SDK.Builder.Layers              # → All layer info from build_layers.yaml
```

### 3. Testing Module: Delegate to Builder

```powershell
$SDK.Testing.LevelName(layer)    # → $SDK.Builder.LayerName(layer)
$SDK.Testing.LevelFragments(layer) # → $SDK.Builder.LayerFragments(layer)
```

### 4. Remove SDK.Runner Singleton

Current (Builder.ps1):
```powershell
$SDK.Extend("Runner", $Runner)  # Singleton - REMOVE THIS
```

**Keep:** `$SDK.Settings.Virtualization.Runner` as config source
**Remove:** `$SDK.Runner` singleton object

CloudInitBuild.CreateWorker() still uses `$SDK.Settings.Virtualization.Runner` for base config, but creates workers on-demand rather than using a pre-created singleton.

### 5. Makefile Updates

Current issues:
- `CONFIGS := $(wildcard src/config/*.config.yaml)` - wrong path
- `SCRIPTS := $(wildcard src/scripts/*.tpl)` - wrong path
- `CLOUD_INIT_FRAGMENTS := $(wildcard src/autoinstall/cloud-init/*.yaml.tpl)` - wrong path
- Examples use `-i 20-users` - old fragment names
- No `LAYER=` parameter support

Required changes:
```makefile
# Update paths
CONFIGS := $(wildcard book-0-builder/config/*.yaml) $(wildcard book-*/*/config/production.yaml)
SCRIPTS := $(wildcard book-*/*/scripts/*.sh.tpl)
FRAGMENTS := $(wildcard book-*/*/fragment.yaml.tpl)

# Add LAYER parameter
LAYER ?=

# Update cloud-init target
cloud-init: output/cloud-init.yaml

output/cloud-init.yaml: $(FRAGMENTS) $(SCRIPTS) $(CONFIGS)
ifdef LAYER
	python3 -m builder render cloud-init -o $@ --layer $(LAYER)
else
	python3 -m builder render cloud-init -o $@ $(INCLUDE) $(EXCLUDE)
endif
```

### 6. Python builder-sdk: Add --layer support

renderer.py needs `--layer` CLI argument that filters to `build_layer <= LAYER`.

---

## Implementation Plan (PLAN.md Commits)

### Makefile Commits (after commit 56)

- **Commit N**: Update Makefile source dependencies to book-* paths
- **Commit N+1**: Update Makefile help examples with new fragment names
- **Commit N+2**: Add LAYER parameter to Makefile cloud-init target

### Builder Module Commits

- **Commit N**: Create build_layers.yaml (renamed from test-levels.yaml)
- **Commit N+1**: Builder.ps1 - Load build_layers.yaml
- **Commit N+2**: Builder.ps1 - Add LayerName method
- **Commit N+3**: Builder.ps1 - Add LayerFragments method

### Remove SDK.Runner Singleton

- **Commit N**: Remove $SDK.Extend("Runner", $Runner) from Builder.ps1
- (CloudInitBuild.ps1 still uses $SDK.Settings.Virtualization.Runner for config - no change needed)

### Python --layer Support

- **Commit N**: renderer.py - Add --layer CLI argument
- **Commit N+1**: renderer.py - Filter fragments by build_layer

### Testing Module (Delegate)

- **Commit N**: Testing.ps1 - Delegate LevelName to Builder.LayerName
- **Commit N+1**: Testing.ps1 - Delegate LevelFragments to Builder.LayerFragments

---

## Summary

| Component | Current | Target |
|-----------|---------|--------|
| Config file | test-levels.yaml | build_layers.yaml |
| Owner | Testing module | Builder module |
| SDK.Runner | Singleton | Removed |
| Makefile paths | src/* | book-*/* |
| Makefile LAYER | Not supported | Supported |
| Python --layer | Not supported | Supported |
