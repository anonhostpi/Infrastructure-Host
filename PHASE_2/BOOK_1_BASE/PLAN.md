# Plan: Book 1 Base - Foundation Fragment Setup

> **WARNING**: Reference `PHASE_2/RULES.md` at time of implementation. All commits must comply with microcommit rules (5-20 lines of code per commit).

**References:**
- Rules: `PHASE_2/RULES.md`
- Initial: `PHASE_2/BOOK_1_BASE/INITIAL.md`

---

## Overview

Create metadata and restructure config files for the base foundation fragment. This fragment defines the core autoinstall configuration.

---

## Files to Create

### Commit 1: Create `book-1-foundation/base/build.yaml`

```yaml
name: base
description: Core autoinstall configuration for Ubuntu installation
iso_required: true
build_order: 0
build_layer: 0
```

Reason: Fragment metadata required for SDK discovery. `build_order: 0` ensures this renders first.

---

## Files to Rename/Merge

### Commit 2: Merge config files into `production.yaml`

**Delete:** `book-1-foundation/base/config/image.config.yaml`
**Delete:** `book-1-foundation/base/config/storage.config.yaml`
**Create:** `book-1-foundation/base/config/production.yaml`

```yaml
# Production Configuration
# Copy to production.yaml and fill in your values

image:
  release: noble        # Ubuntu codename (noble=24.04, jammy=22.04)
  type: live-server     # Image type
  arch: amd64           # Architecture

storage:
  # direct = ext4, simplest option for disposable root filesystem
  # VM storage with redundancy should use a separate ZFS pool on additional drives
  layout: direct
  sizing_policy: all
  match:
    size: largest
    # Future: target specific NVMe slot via id_path
    # id_path: pci-0000:01:00.0-nvme-1
```

Reason: Consolidate image and storage config into single production config per REFACTOR.md.

---

### Commit 3: Merge example config files into `production.yaml.example`

**Delete:** `book-1-foundation/base/config/image.config.yaml.example`
**Delete:** `book-1-foundation/base/config/storage.config.yaml.example`
**Create:** `book-1-foundation/base/config/production.yaml.example`

Content: Same as production.yaml (examples contain sample values)

Reason: Consolidate example files to match new naming convention.

---

### Commit 4: Rename testing config

**Rename:** `book-1-foundation/base/config/testing.config.yaml` → `book-1-foundation/base/config/testing.yaml`

Reason: Follow new naming convention.

---

### Commit 5: Rename testing config example

**Rename:** `book-1-foundation/base/config/testing.config.yaml.example` → `book-1-foundation/base/config/testing.yaml.example`

Reason: Follow new naming convention.

---

## Files to Modify

### Commit 6: Update `.gitignore` for new config pattern

```diff
-book-1-foundation/base/config/*.config.yaml
-!book-1-foundation/base/config/*.config.yaml.example
+book-1-foundation/base/config/production.yaml
+book-1-foundation/base/config/testing.yaml
```

Reason: Gitignore should track the new specific filenames, not wildcard patterns.

---

## Template Review

The `fragment.yaml.tpl` template uses these config references:
- `{{ storage.layout }}` - from `storage:` section (now in production.yaml)
- `{{ storage.sizing_policy }}` - from `storage:` section
- `{{ storage.match.size }}` - from `storage:` section
- `{{ testing.testing }}` - from `testing:` section (now in testing.yaml)

**No template changes required** - the config keys remain the same, only filenames change.

---

## Dependencies

This plan depends on:
- BOOK_0 plan (SDK must discover fragments via `build.yaml`)

This plan blocks:
- All BOOK_2 plans (they depend on base fragment existing)

---

## Validation

After all commits:

**Host (file checks):**
- [ ] `build.yaml` exists and is valid YAML
- [ ] `production.yaml` contains `image:` and `storage:` sections
- [ ] `testing.yaml` contains `testing: true`

**Builder VM** (via `$SDK.Builder.Stage()` then `$SDK.Builder.Exec()`):
- [ ] `python -m builder render autoinstall -o /dev/null` succeeds
- [ ] `make autoinstall` succeeds
