# Phase 2: Builder Layer

**Book:** 0
**Path:** book-0-builder/
**Type:** [x] SDK (Book 0) | [ ] Fragment (Book 1/2)
**Status:** [ ] Not Started | [ ] In Progress | [ ] Complete

---

## 1. Current State (Post-Phase 1)

### Files Present

```
book-0-builder/
├── config/
│   ├── vm.config.yaml           # Gitignored
│   └── vm.config.yaml.example
│
├── builder-sdk/
│   ├── __init__.py
│   ├── __main__.py              # CLI entry point
│   ├── artifacts.py
│   ├── composer.py
│   ├── context.py
│   ├── filters.py
│   └── renderer.py
│
├── host-sdk/
│   ├── SDK.ps1                  # Entry point
│   ├── Invoke-AutoinstallTest.ps1
│   ├── Invoke-IncrementalTest.ps1
│   ├── helpers/
│   │   ├── Config.ps1
│   │   └── PowerShell.ps1
│   └── modules/
│       ├── Builder.ps1
│       ├── Config.ps1
│       ├── General.ps1
│       ├── Multipass.ps1
│       ├── Network.ps1
│       ├── Settings.ps1
│       ├── Vbox.ps1
│       └── Verifications.ps1
│
└── docs/
    ├── OVERVIEW.md
    ├── ARCHITECTURE_OVERVIEW.md
    ├── ARCHITECTURE_BENEFITS.md
    ├── KEY_COMPONENTS.md
    ├── BUILD_SYSTEM_OVERVIEW.md
    ├── BUILD_CONTEXT.md
    ├── MAKEFILE_INTERFACE.md
    ├── RENDER_CLI.md
    ├── JINJA2_FILTERS.md
    ├── TESTING_OVERVIEW.md
    ├── AUTOINSTALL_TESTING.md
    ├── CLOUD_INIT_TESTING.md
    ├── CLOUD_INIT_TESTS_README.md
    ├── TROUBLESHOOTING_OVERVIEW.md
    ├── TROUBLESHOOTING_COMMON_ISSUES.md
    ├── TROUBLESHOOTING_LOGS.md
    ├── USEFUL_COMMANDS.md
    ├── APPENDIX_OVERVIEW.md
    ├── REFERENCE_FILES.md
    └── ADDITIONAL_RESOURCES.md
```

### Dependencies

- **Depends on:** None (foundational)
- **Depended on by:** All fragments (Book 1, Book 2) - SDKs discover and process fragments

---

## 2. Required Changes

### 2.1 Metadata (Fragments only - skip for Book 0)

N/A - Book 0 is an SDK, not a fragment.

### 2.2 Config Restructure (Fragments only - skip for Book 0)

N/A - Book 0 is an SDK, not a fragment.

### 2.3 Import/Path Updates (Book 0 SDKs)

Python (builder-sdk):

- [ ] Update hardcoded `src/` paths in renderer.py to new `book-*/` paths
- [ ] Update template discovery to find `fragment.yaml.tpl` in new locations
- [ ] Update config discovery to find `production.yaml`/`testing.yaml` pattern
- [ ] Update script discovery to find `scripts/*.sh.tpl` in fragment directories

PowerShell (host-sdk):

- [ ] Update `modules/Config.ps1` fragment mapping (currently uses `10-network`, `15-kernel`, etc.)
- [ ] Update config file path references to new `book-*/` structure
- [ ] Update fragment discovery to scan for `build.yaml` files
- [ ] Update test scripts to use new paths

### 2.4 Template Updates (Fragments)

N/A - Book 0 is an SDK, not a fragment.

### 2.5 Documentation Updates

- [ ] Update path references in docs (currently reference `src/` paths)
- [ ] Update code examples to reflect new structure
- [ ] Consolidate/organize docs (currently 20 files - may need restructuring)

---

## 3. Validation Checklist

### For Fragments (Book 1/2):

N/A - Book 0 is an SDK, not a fragment.

### For SDKs (Book 0):

- [ ] All Python imports resolve correctly
- [ ] All PowerShell dot-source paths resolve correctly
- [ ] Fragment discovery finds `book-1-foundation/` and `book-2-cloud/` fragments
- [ ] Config loading works with `production.yaml`/`testing.yaml` pattern
- [ ] CLI commands (`python -m builder`) work end-to-end
- [ ] Host SDK test commands work end-to-end

### General:

- [ ] No broken imports/references
- [ ] `make all` succeeds
- [ ] `make clean && make all` succeeds

---

## 4. Notes

- Book 0 contains both SDKs - changes here affect all fragment processing
- The `modules/Config.ps1` file contains hardcoded fragment paths that need updating
- Consider whether `build.yaml` discovery should replace hardcoded mappings
- Docs may need consolidation - 20 files is a lot for SDK documentation

---

## 5. Completion Sign-off

- [ ] All changes implemented
- [ ] Validation checklist passed
- [ ] Ready for Phase 3 testing
