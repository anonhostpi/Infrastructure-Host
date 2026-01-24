# Phase 2: Foundation Base

**Book:** 1
**Path:** book-1-foundation/base/
**Type:** [ ] SDK (Book 0) | [x] Fragment (Book 1/2)
**Status:** [ ] Not Started | [ ] In Progress | [ ] Complete

---

## 1. Current State (Post-Phase 1)

### Files Present

```
book-1-foundation/base/
├── config/
│   ├── image.config.yaml
│   ├── image.config.yaml.example
│   ├── storage.config.yaml
│   ├── storage.config.yaml.example
│   ├── testing.config.yaml
│   └── testing.config.yaml.example
│
├── docs/
│   ├── OVERVIEW.md
│   ├── AUTOINSTALL_CONFIGURATION.md
│   ├── BOOTABLE_MEDIA_CREATION.md
│   ├── DOWNLOAD_UBUNTU_ISO.md
│   └── MODIFIED_ISO_METHOD.md
│
├── scripts/
│   ├── build-iso.sh.tpl
│   └── early-net.sh.tpl
│
└── fragment.yaml.tpl
```

### Dependencies

- **Depends on:** Book 0 (SDKs process this fragment)
- **Depended on by:** All Book 2 fragments (base autoinstall is foundation for cloud-init)

---

## 2. Required Changes

### 2.1 Metadata (Fragments only - skip for Book 0)

- [ ] Create `build.yaml` with:
  ```yaml
  name: base
  description: Core autoinstall configuration for Ubuntu installation
  iso_required: true
  build_order: 0
  build_layer: 0
  ```

### 2.2 Config Restructure (Fragments only - skip for Book 0)

Current config files:

- `image.config.yaml` / `image.config.yaml.example`
- `storage.config.yaml` / `storage.config.yaml.example`
- `testing.config.yaml` / `testing.config.yaml.example`

Changes needed:

- [ ] Merge `image.config.yaml` and `storage.config.yaml` into `production.yaml`
- [ ] Merge `image.config.yaml.example` and `storage.config.yaml.example` into `production.yaml.example`
- [ ] Rename `testing.config.yaml` to `testing.yaml`
- [ ] Rename `testing.config.yaml.example` to `testing.yaml.example`
- [ ] Update `.gitignore` if needed (currently covers `*.config.yaml`)

### 2.3 Import/Path Updates (Book 0 SDKs)

N/A - This is a fragment, not an SDK.

### 2.4 Template Updates (Fragments)

- [ ] Review `fragment.yaml.tpl` for hardcoded paths
- [ ] Review `scripts/build-iso.sh.tpl` for hardcoded paths
- [ ] Review `scripts/early-net.sh.tpl` for hardcoded paths
- [ ] Verify template variables still resolve with new config structure

### 2.5 Documentation Updates

- [ ] Update any path references in docs
- [ ] Update code examples if config names changed

---

## 3. Validation Checklist

### For Fragments (Book 1/2):

- [ ] `build.yaml` exists and is valid YAML
- [ ] Config files follow `production.yaml`/`testing.yaml` pattern
- [ ] `fragment.yaml.tpl` renders without error
- [ ] Scripts in `scripts/` render without error

### For SDKs (Book 0):

N/A - This is a fragment, not an SDK.

### General:

- [ ] No broken imports/references
- [ ] `make autoinstall` succeeds

---

## 4. Notes

- Book 1 base has multiple config files (image, storage, testing) that need consolidation
- This is the only fragment in Book 1 - it defines the core autoinstall
- The `testing.config.yaml` is different from other fragments - it's a mode flag, not an overlay
- Consider whether image + storage should remain separate or merge into production.yaml
- No tests/ directory exists yet - may need to create one

---

## 5. Completion Sign-off

- [ ] All changes implemented
- [ ] Validation checklist passed
- [ ] Ready for Phase 3 testing
