# Documentation Updates Discovery

**Type:** Rule 0 Discovery Document

---

## Problem Statement

The documentation in `book-0-builder/docs/` contains stale references to:
1. Old `src/` paths (now `book-*/`)
2. Old numeric-prefixed fragment names (`10-network`, `20-users`, etc.)
3. Old config patterns (`*.config.yaml` in `src/config/`)

---

## Files Requiring Updates

### High Priority (Core Docs)

| File | Issues |
|------|--------|
| `MAKEFILE_INTERFACE.md` | `src/config/`, `src/scripts/`, `src/autoinstall/` paths |
| `RENDER_CLI.md` | `src/config`, `src/scripts/`, `10-network`, `20-users` fragment names |
| `BUILD_CONTEXT.md` | `src/config/` paths, code examples |
| `TESTING_OVERVIEW.md` | `src/config/` paths, config copy examples |
| `CLOUD_INIT_TESTING.md` | `src/config/`, old fragment names (`10-network`, `15-kernel`, etc.) |

### Medium Priority (Test Docs)

| File | Issues |
|------|--------|
| `CLOUD_INIT_TESTS_README.md` | Old fragment names in table (`10-network.yaml.tpl`, etc.) |
| `AUTOINSTALL_TESTING.md` | `src/config/identity.config.yaml` reference |

### Low Priority (Conceptual)

| File | Issues |
|------|--------|
| `ARCHITECTURE_BENEFITS.md` | Mentions numeric prefixes as feature |

---

## Path Mappings

### Directory Structure

| Old Path | New Path |
|----------|----------|
| `src/config/` | `book-0-builder/config/` (vm.config.yaml) |
| `src/config/*.config.yaml` | `book-*/*/config/production.yaml` |
| `src/scripts/` | `book-*/*/scripts/` |
| `src/autoinstall/cloud-init/` | `book-*/*/fragment.yaml.tpl` |
| `src/autoinstall/base.yaml.tpl` | `book-1-foundation/base/autoinstall.yaml.tpl` |

### Fragment Names

| Old Name | New Name |
|----------|----------|
| `10-network` | `network` |
| `15-kernel` | `kernel` |
| `20-users` | `users` |
| `25-ssh` | `ssh` |
| `30-ufw` | `ufw` |
| `40-system` | `system` |
| `45-msmtp` | `msmtp` |
| `50-packages` | `packages` |
| `50-pkg-security` | `pkg-security` |
| `999-pkg-upgrade` | `pkg-upgrade` |
| `55-security-mon` | `security-mon` |
| `60-virtualization` | `virtualization` |
| `70-cockpit` | `cockpit` |
| `75-claude-code` | `claude-code` |
| `76-copilot-cli` | `copilot-cli` |
| `77-opencode` | `opencode` |
| `90-ui` | `ui` |

### Config Files

| Old Path | New Path |
|----------|----------|
| `src/config/network.config.yaml` | `book-2-cloud/network/config/production.yaml` |
| `src/config/identity.config.yaml` | `book-2-cloud/users/config/production.yaml` |
| `src/config/storage.config.yaml` | `book-1-foundation/base/config/production.yaml` |
| `src/config/image.config.yaml` | `book-1-foundation/base/config/production.yaml` |
| `src/config/smtp.config.yaml` | `book-2-cloud/msmtp/config/production.yaml` |

---

## Implementation Approach

### Option A: Update In-Place

Update each doc file individually with new paths and names.

**Pros:** Preserves existing structure
**Cons:** 20 files to update, may still be disorganized

### Option B: Consolidate + Update

Reduce 20 files to fewer, better-organized docs:

```
book-0-builder/docs/
├── README.md              # Overview (merge OVERVIEW.md)
├── ARCHITECTURE.md        # Merge ARCHITECTURE_*.md, KEY_COMPONENTS.md
├── BUILD_SYSTEM.md        # Merge BUILD_*.md, MAKEFILE_INTERFACE.md, RENDER_CLI.md
├── TESTING.md             # Merge TESTING_*.md, CLOUD_INIT_*.md, AUTOINSTALL_TESTING.md
├── TROUBLESHOOTING.md     # Merge TROUBLESHOOTING_*.md
└── REFERENCE.md           # Merge APPENDIX_*.md, REFERENCE_FILES.md, USEFUL_COMMANDS.md
```

**Pros:** Cleaner structure, easier to maintain
**Cons:** More work, may break external links

### Recommendation: Option A (Update In-Place)

Keep existing structure for Phase 2. Consolidation can be a future cleanup task.

---

## Commits Required

### Commit Group: MAKEFILE_INTERFACE.md

```diff
-CONFIGS := $(wildcard src/config/*.config.yaml)
-SCRIPTS := $(wildcard src/scripts/*.tpl)
-CLOUD_INIT_FRAGMENTS := $(wildcard src/autoinstall/cloud-init/*.yaml.tpl)
+CONFIGS := $(wildcard book-0-builder/config/*.yaml) $(wildcard book-*/*/config/production.yaml)
+SCRIPTS := $(wildcard book-*/*/scripts/*.sh.tpl)
+FRAGMENTS := $(wildcard book-*/*/fragment.yaml.tpl)
```

### Commit Group: RENDER_CLI.md

- Update `src/config` → fragment config paths
- Update `src/scripts/` → `book-*/*/scripts/`
- Update fragment name examples (`10-network` → `network`)

### Commit Group: BUILD_CONTEXT.md

- Update `src/config/` references
- Update code examples

### Commit Group: TESTING_OVERVIEW.md

- Update config copy examples to new paths
- Update fragment references

### Commit Group: CLOUD_INIT_TESTING.md

- Update test level table with new fragment names
- Update `src/config/` path references

### Commit Group: CLOUD_INIT_TESTS_README.md

- Update fragment table (`10-network.yaml.tpl` → `network/fragment.yaml.tpl`)

### Commit Group: AUTOINSTALL_TESTING.md

- Update `src/config/identity.config.yaml` reference

### Commit Group: ARCHITECTURE_BENEFITS.md

- Update or remove mention of numeric prefixes

---

## Validation

After updates:

- [ ] `grep -r "src/" book-0-builder/docs/` returns no matches
- [ ] `grep -r "\d\d-[a-z]" book-0-builder/docs/` returns no fragment name matches
- [ ] All code examples in docs are accurate for new structure

---

## Notes

- Some docs may reference external files that also need updating
- Test-specific docs (TEST_6.1_*, etc.) may exist outside book-0-builder/docs/
- Consider adding a "Structure" section to docs explaining book-* organization
