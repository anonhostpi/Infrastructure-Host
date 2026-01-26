# Review: Build Layers Configuration

## SDK.Settings.BuildLayers

**Request**: Add hashtable for `build_layers.yaml` values, similar to `Virtualization`.

---

### Current State

Fragments.ps1 loads `build_layers.yaml` directly:

```powershell
$layersPath = "$PSScriptRoot\..\..\config\build_layers.yaml"
$mod.LayersConfig = Get-Content $layersPath -Raw | ConvertFrom-Yaml
$mod.LayerNames = $mod.LayersConfig.layers
```

---

### Proposed Change

Settings.ps1 should expose:
```powershell
$SDK.Settings.BuildLayers  # From build_layers.yaml
```

Then Fragments.ps1 would reference:
```powershell
$mod.LayerNames = $mod.SDK.Settings.BuildLayers.layers
```

---

### Benefits

1. Centralized configuration loading in Settings module
2. Consistent pattern with `$SDK.Settings.Virtualization`
3. Single source of truth for build layer definitions
