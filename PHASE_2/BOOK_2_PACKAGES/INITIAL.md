# Phase 2: Packages Fragment

**Book:** 2
**Path:** book-2-cloud/packages/
**Type:** [ ] SDK (Book 0) | [x] Fragment (Book 1/2)
**Status:** [ ] Not Started | [ ] In Progress | [ ] Complete

---

## 1. Current State (Post-Phase 1)

### Files Present

```
book-2-cloud/packages/
└── fragment.yaml.tpl
```

### Dependencies

- **Depends on:** Book 0 (SDKs), Book 1 base, network
- **Depended on by:** pkg-security, pkg-upgrade (package-related fragments)

---

## 2. Required Changes

### 2.1 Metadata (Fragments only - skip for Book 0)

- [ ] Create `build.yaml` with:
  ```yaml
  name: packages
  description: Base package installation
  iso_required: false
  build_order: 50
  build_layer: 8
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

- N/A - No docs directory exists

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

- Extremely minimal fragment - only has fragment.yaml.tpl
- No config, no docs, no scripts, no tests
- May need docs/ and tests/ directories created
- Template-only fragment (package list is hardcoded in template)

---

## 5. Completion Sign-off

- [ ] All changes implemented
- [ ] Validation checklist passed
- [ ] Ready for Phase 3 testing
