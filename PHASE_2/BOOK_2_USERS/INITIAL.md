# Phase 2: Users Fragment

**Book:** 2
**Path:** book-2-cloud/users/
**Type:** [ ] SDK (Book 0) | [x] Fragment (Book 1/2)
**Status:** [ ] Not Started | [ ] In Progress | [ ] Complete

---

## 1. Current State (Post-Phase 1)

### Files Present

```
book-2-cloud/users/
├── config/
│   ├── identity.config.yaml
│   └── identity.config.yaml.example
│
├── docs/
│   └── FRAGMENT.md
│
├── scripts/
│   └── user-setup.sh.tpl
│
├── tests/
│   └── TEST_USERS.md
│
└── fragment.yaml.tpl
```

### Dependencies

- **Depends on:** Book 0 (SDKs), Book 1 base, network
- **Depended on by:** ssh (needs users to exist)

---

## 2. Required Changes

### 2.1 Metadata (Fragments only - skip for Book 0)

- [ ] Create `build.yaml` with:
  ```yaml
  name: users
  description: User account creation and sudo configuration
  iso_required: true
  build_order: 20
  build_layer: 3
  ```

### 2.2 Config Restructure (Fragments only - skip for Book 0)

Current config files:

- `identity.config.yaml` / `identity.config.yaml.example`

Changes needed:

- [ ] Rename `identity.config.yaml` to `production.yaml`
- [ ] Rename `identity.config.yaml.example` to `production.yaml.example`
- [ ] Create `testing.yaml` if testing overlay needed
- [ ] Update `.gitignore` if needed

### 2.3 Import/Path Updates (Book 0 SDKs)

N/A - This is a fragment, not an SDK.

### 2.4 Template Updates (Fragments)

- [ ] Review `fragment.yaml.tpl` for hardcoded paths
- [ ] Review `scripts/user-setup.sh.tpl` for hardcoded paths
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

- Users is `iso_required: true` - bare metal needs a login user
- Config contains sensitive data (passwords, SSH keys) - ensure gitignored
- Has user-setup.sh.tpl script that needs review

---

## 5. Completion Sign-off

- [ ] All changes implemented
- [ ] Validation checklist passed
- [ ] Ready for Phase 3 testing
