# Phase 2: [SECTION_NAME]

**Book:** [BOOK_NUMBER]
**Path:** [RELATIVE_PATH]
**Type:** [ ] SDK (Book 0) | [ ] Fragment (Book 1/2)
**Status:** [ ] Not Started | [ ] In Progress | [ ] Complete

---

## 1. Current State (Post-Phase 1)

### Files Present

```
[List files that exist after Phase 1]
```

### Dependencies

- **Depends on:** [List sections this depends on, if any]
- **Depended on by:** [List sections that depend on this, if any]

---

## 2. Required Changes

### 2.1 Metadata (Fragments only - skip for Book 0)

- [ ] Create `build.yaml` with:
  ```yaml
  name: [fragment_name]
  description: [brief description]
  iso_required: [true/false]  # Required for ISO builds (not cloud-init)
  build_order: [numeric]      # Merge order in output (e.g., 10, 20, 999)
  build_layer: [numeric]      # Incremental build layer (1=foundation, higher=later)
  ```

### 2.2 Config Restructure (Fragments only - skip for Book 0)

Current config files:
- [List current *.config.yaml files]

Changes needed:
- [ ] Rename `[old_name].config.yaml` to `production.yaml`
- [ ] Rename `[old_name].config.yaml.example` to `production.yaml.example`
- [ ] Create/update `testing.yaml` (if testing overlay needed)
- [ ] Update `.gitignore` patterns if needed

### 2.3 Import/Path Updates (Book 0 SDKs)

Python (builder-sdk):
- [ ] Update `from builder import ...` paths
- [ ] Update hardcoded `src/` paths in renderer.py
- [ ] Update template discovery paths

PowerShell (host-sdk):
- [ ] Update `. "$ScriptDir\..."` dot-source paths
- [ ] Update config file path references
- [ ] Update fragment discovery paths

### 2.4 Template Updates (Fragments)

- [ ] Update any hardcoded paths in `.tpl` files
- [ ] Update any cross-fragment references
- [ ] Verify template variables still resolve

### 2.5 Documentation Updates

- [ ] Update internal doc links
- [ ] Update any path references in docs
- [ ] Update code examples if paths changed

---

## 3. Validation Checklist

### For Fragments (Book 1/2):
- [ ] `build.yaml` exists and is valid YAML
- [ ] Config files follow `production.yaml`/`testing.yaml` pattern
- [ ] `fragment.yaml.tpl` renders without error
- [ ] Scripts in `scripts/` render without error

### For SDKs (Book 0):
- [ ] All imports resolve correctly
- [ ] Fragment discovery finds new paths
- [ ] Config loading works with new structure
- [ ] CLI commands work end-to-end

### General:
- [ ] No broken imports/references
- [ ] Tests pass (if applicable)

---

## 4. Notes

[Any section-specific notes, edge cases, or decisions]

---

## 5. Completion Sign-off

- [ ] All changes implemented
- [ ] Validation checklist passed
- [ ] Ready for Phase 3 testing
