# Phase 2: MSMTP Fragment

**Book:** 2
**Path:** book-2-cloud/msmtp/
**Type:** [ ] SDK (Book 0) | [x] Fragment (Book 1/2)
**Status:** [ ] Not Started | [ ] In Progress | [ ] Complete

---

## 1. Current State (Post-Phase 1)

### Files Present

```
book-2-cloud/msmtp/
├── config/
│   ├── smtp.config.yaml
│   └── smtp.config.yaml.example
│
├── docs/
│   └── FRAGMENT.md
│
├── tests/
│   └── TEST_MSMTP.md
│
└── fragment.yaml.tpl
```

### Dependencies

- **Depends on:** Book 0 (SDKs), Book 1 base, network
- **Depended on by:** None directly

---

## 2. Required Changes

### 2.1 Metadata (Fragments only - skip for Book 0)

- [ ] Create `build.yaml` with:
  ```yaml
  name: msmtp
  description: SMTP relay configuration for system mail
  iso_required: false
  build_order: 45
  build_layer: 7
  ```

### 2.2 Config Restructure (Fragments only - skip for Book 0)

Current config files:

- `smtp.config.yaml` / `smtp.config.yaml.example`

Changes needed:

- [ ] Rename `smtp.config.yaml` to `production.yaml`
- [ ] Rename `smtp.config.yaml.example` to `production.yaml.example`
- [ ] Create `testing.yaml` if testing overlay needed
- [ ] Update `.gitignore` if needed

### 2.3 Import/Path Updates (Book 0 SDKs)

N/A - This is a fragment, not an SDK.

### 2.4 Template Updates (Fragments)

- [ ] Review `fragment.yaml.tpl` for hardcoded paths
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
- [ ] Scripts in `scripts/` render without error (N/A - no scripts)

### For SDKs (Book 0):

N/A - This is a fragment, not an SDK.

### General:

- [ ] No broken imports/references
- [ ] `make cloud-init` succeeds with this fragment

---

## 4. Notes

- Config contains SMTP credentials - ensure gitignored
- Single config file rename to production.yaml

---

## 5. Completion Sign-off

- [ ] All changes implemented
- [ ] Validation checklist passed
- [ ] Ready for Phase 3 testing
