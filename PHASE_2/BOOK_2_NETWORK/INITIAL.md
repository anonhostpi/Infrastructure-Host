# Phase 2: Network Fragment

**Book:** 2
**Path:** book-2-cloud/network/
**Type:** [ ] SDK (Book 0) | [x] Fragment (Book 1/2)
**Status:** [ ] Not Started | [ ] In Progress | [ ] Complete

---

## 1. Current State (Post-Phase 1)

### Files Present

```
book-2-cloud/network/
├── config/
│   ├── network.config.yaml
│   └── network.config.yaml.example
│
├── docs/
│   ├── OVERVIEW.md
│   ├── FRAGMENT.md
│   ├── INFORMATION_GATHERING.md
│   ├── SCRIPTS.md
│   └── TOPOLOGY.md
│
├── scripts/
│   └── net-setup.sh.tpl
│
├── tests/
│   └── TEST_NETWORK.md
│
└── fragment.yaml.tpl
```

### Dependencies

- **Depends on:** Book 0 (SDKs), Book 1 base (autoinstall foundation)
- **Depended on by:** Most other fragments rely on network being configured first

---

## 2. Required Changes

### 2.1 Metadata (Fragments only - skip for Book 0)

- [ ] Create `build.yaml` with:
  ```yaml
  name: network
  description: Static IP configuration via arping detection
  iso_required: true
  build_order: 10
  build_layer: 1
  ```

### 2.2 Config Restructure (Fragments only - skip for Book 0)

Current config files:

- `network.config.yaml` / `network.config.yaml.example`

Changes needed:

- [ ] Rename `network.config.yaml` to `production.yaml`
- [ ] Rename `network.config.yaml.example` to `production.yaml.example`
- [ ] Create `testing.yaml` if testing overlay needed
- [ ] Update `.gitignore` if needed (currently covers `*.config.yaml`)

### 2.3 Import/Path Updates (Book 0 SDKs)

N/A - This is a fragment, not an SDK.

### 2.4 Template Updates (Fragments)

- [ ] Review `fragment.yaml.tpl` for hardcoded paths
- [ ] Review `scripts/net-setup.sh.tpl` for hardcoded paths
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
- [ ] `make cloud-init` succeeds with this fragment

---

## 4. Notes

- Network is `iso_required: true` - bare metal needs static IP for remote access
- This is build_layer 1 (foundation) and build_order 10 (first cloud-init fragment)
- Has existing tests/ directory with TEST_NETWORK.md
- Config is straightforward - single file rename to production.yaml

---

## 5. Completion Sign-off

- [ ] All changes implemented
- [ ] Validation checklist passed
- [ ] Ready for Phase 3 testing
