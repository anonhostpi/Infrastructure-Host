# Phase 2: Kernel Fragment

**Book:** 2
**Path:** book-2-cloud/kernel/
**Type:** [ ] SDK (Book 0) | [x] Fragment (Book 1/2)
**Status:** [ ] Not Started | [ ] In Progress | [ ] Complete

---

## 1. Current State (Post-Phase 1)

### Files Present

```
book-2-cloud/kernel/
├── docs/
│   └── FRAGMENT.md
│
├── tests/
│   └── TEST_KERNEL.md
│
└── fragment.yaml.tpl
```

### Dependencies

- **Depends on:** Book 0 (SDKs), Book 1 base, network
- **Depended on by:** None directly - kernel hardening is independent

---

## 2. Required Changes

### 2.1 Metadata (Fragments only - skip for Book 0)

- [ ] Create `build.yaml` with:
  ```yaml
  name: kernel
  description: Kernel hardening and sysctl configuration
  iso_required: false
  build_order: 15
  build_layer: 2
  ```

### 2.2 Config Restructure (Fragments only - skip for Book 0)

Current config files:

- None

Changes needed:

- N/A - No config files to restructure

### 2.3 Import/Path Updates (Book 0 SDKs)

N/A - This is a fragment, not an SDK.

### 2.4 Template Updates (Fragments)

- [ ] Review `fragment.yaml.tpl` for hardcoded paths
- [ ] Verify template variables still resolve

### 2.5 Documentation Updates

- [ ] Update any path references in docs

---

## 3. Validation Checklist

### For Fragments (Book 1/2):

- [ ] `build.yaml` exists and is valid YAML
- [ ] Config files follow `production.yaml`/`testing.yaml` pattern (N/A - no config)
- [ ] `fragment.yaml.tpl` renders without error
- [ ] Scripts in `scripts/` render without error (N/A - no scripts)

### For SDKs (Book 0):

N/A - This is a fragment, not an SDK.

### General:

- [ ] No broken imports/references
- [ ] `make cloud-init` succeeds with this fragment

---

## 4. Notes

- Minimal fragment - no config files, no scripts
- Only needs build.yaml creation
- Template-only fragment (all config is hardcoded in template)

---

## 5. Completion Sign-off

- [ ] All changes implemented
- [ ] Validation checklist passed
- [ ] Ready for Phase 3 testing
