# Code Review #2 - BOOK_0

**Date**: 2026-01-25
**Reviewer**: User
**Status**: Pending

---

## Review Items

### R2-1: build_layers.yaml - build_layer as optional array

**File**: `book-0-builder/config/build_layers.yaml`

**Issue**: The `agent_dependent` section is unnecessary. Instead, `build_layer` in each fragment's `build.yaml` should optionally be an array, allowing a fragment to belong to multiple layers.

**Required Changes**:
- Remove `agent_dependent` section from `build_layers.yaml`
- Update Python renderer to handle `build_layer` as int or list
- Update PowerShell Fragments module to handle `build_layer` as int or list

---

### R2-2: Config.ps1 - OrderedHashtable.Keys bug

**File**: `book-0-builder/host-sdk/helpers/Config.ps1`

**Issue**: `$yaml.Keys | Measure-Object` is incorrect due to a bug in how `OrderedHashtable.Keys` works with pipeline.

**Fix**: Change to `$yaml.Keys | ForEach-Object { $_ } | Measure-Object`

---

### R2-3: Worker.ps1 - Scoping problem

**File**: `book-0-builder/host-sdk/helpers/Worker.ps1`

**Issue**: `$SDK` is short-lived due to PowerShell's scoping rules. The variable will be garbage collected before it can be used in the helper.

**Fix**: Convert Worker.ps1 to a module pattern where SDK is available as `$mod.SDK`, making the variable long-lived.

---

### R2-4: Rename AutoinstallBuild/AutoinstallTest

**Files**:
- `book-0-builder/host-sdk/modules/AutoinstallBuild.ps1`
- `book-0-builder/host-sdk/modules/AutoinstallTest.ps1`

**Issue**: Module naming should be `SDK.Autoinstall` with `Test` as a submodule.

**Fix**:
- Rename `AutoinstallBuild` to `Autoinstall` (accessible at `$SDK.Autoinstall`)
- Make `AutoinstallTest` a submodule (accessible at `$SDK.Autoinstall.Test`)
- Use `Add-Member -MemberType NoteProperty` on `$SDK.Autoinstall` instead of `$SDK.Extend`

---

### R2-5: Rename CloudInitBuild/CloudInitTest

**Files**:
- `book-0-builder/host-sdk/modules/CloudInitBuild.ps1`
- `book-0-builder/host-sdk/modules/CloudInitTest.ps1`

**Issue**: Same pattern as R2-4.

**Fix**:
- Rename `CloudInitBuild` to `CloudInit` (accessible at `$SDK.CloudInit`)
- Make `CloudInitTest` a submodule (accessible at `$SDK.CloudInit.Test`)
- Use `Add-Member -MemberType NoteProperty` on `$SDK.CloudInit` instead of `$SDK.Extend`

---

### R2-6: Builder.ps1 - Layer logic location and runner tracking

**File**: `book-0-builder/host-sdk/modules/Builder.ps1`

**Issue**:
1. Layer logic (LayerName, LayerFragments) should be in `Fragments.ps1` instead
2. Builder should spawn and track runners so `Flush()` can destroy them

**Fix**:
- Move LayerName and LayerFragments methods to Fragments.ps1
- Add runner tracking in Builder ($mod.Runners = @{})
- Update Flush() to iterate and destroy tracked runners

---

### R2-7: AutoinstallBuild/CloudInitBuild - Build improvements

**Files**:
- `book-0-builder/host-sdk/modules/AutoinstallBuild.ps1`
- `book-0-builder/host-sdk/modules/CloudInitBuild.ps1`

**Issues**:
1. Build should be idempotent (skip if artifact exists)
2. Need Clean function that proxies to builder's clean
3. GetArtifact is useless on AutoinstallBuild - should have Build function like CloudInit
4. Layer logic should affect ISO builds
5. `iso_required` fragments must be present in all ISO builds regardless of layer/include flags
   - Non-ISO cloud-init builds don't care about iso_required
   - Builder SDK needs to accommodate this distinction

**Fix**:
- Add artifact existence check in Build
- Add Clean method that calls Builder.Clean()
- Add Build method to AutoinstallBuild
- Pass layer to ISO build process
- Add iso_required enforcement for ISO builds (verify or implement)

---

### R2-8: CloudInitTest/AutoinstallTest - Return entire worker

**Files**:
- `book-0-builder/host-sdk/modules/CloudInitTest.ps1`
- `book-0-builder/host-sdk/modules/AutoinstallTest.ps1`

**Issue**: Run method returns `WorkerName` but should return the entire worker object so external logic can clean up if needed.

**Fix**: Change return to include `Worker = $worker` instead of `WorkerName = $worker.Name`

---

### R2-9: Settings.ps1 - Variable name in scriptblock body

**File**: `book-0-builder/host-sdk/modules/Settings.ps1`

**Issue**: Changed `$key` to `$propertyName` but didn't update it inside `$src` (the body of `$sb`).

**Fix**: Update the scriptblock body to use `$propertyName` consistently, or keep `$key` in the inner scope.

---

### R2-10: Testing.ps1 - Unclear Verifications method

**File**: `book-0-builder/host-sdk/modules/Testing.ps1`

**Issue**: `SDK.Testing.Verifications` method purpose is unclear.

**Fix**: Either document/clarify the purpose or remove if unnecessary.

---

## Summary

| ID | File | Priority | Complexity |
|----|------|----------|------------|
| R2-1 | build_layers.yaml, renderer.py, Fragments.ps1 | High | Medium |
| R2-2 | Config.ps1 | High | Low |
| R2-3 | Worker.ps1 | High | Medium |
| R2-4 | AutoinstallBuild.ps1, AutoinstallTest.ps1 | High | Medium |
| R2-5 | CloudInitBuild.ps1, CloudInitTest.ps1 | High | Medium |
| R2-6 | Builder.ps1, Fragments.ps1 | High | Medium |
| R2-7 | AutoinstallBuild.ps1, CloudInitBuild.ps1 | High | High |
| R2-8 | CloudInitTest.ps1, AutoinstallTest.ps1 | Medium | Low |
| R2-9 | Settings.ps1 | High | Low |
| R2-10 | Testing.ps1 | Low | Low |

---

## Next Steps

Per Rule 6: Return to Rule 0 - treat review feedback as a new discovery/design task. Update PLAN.md with new commits addressing each review item.
