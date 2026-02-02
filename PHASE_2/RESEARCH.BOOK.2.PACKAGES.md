# RESEARCH.BOOK.2.PACKAGES

## Purpose

The `packages` fragment (`book-2-cloud/packages/`) installs base system packages via apt. This is one of the most minimal fragments -- template-only with a hardcoded package list.

**Build metadata:** layer 8, order 50, `iso_required: false`

## Current State

### Completed

- `build.yaml` exists with correct metadata
- `fragment.yaml.tpl` renders package installation list

### Files

```
book-2-cloud/packages/
├── build.yaml
└── fragment.yaml.tpl
```

## Remaining Work

This is the most minimal fragment in the system. It has no config, no docs, no scripts, and no tests directory. The old Phase 2 notes suggested creating `docs/` and `tests/` directories.

### Gaps

- **No tests:** No `tests/8/verifications.ps1` exists. However, `pkg-security` (same layer 8) does have tests at `tests/8/verifications.ps1`. If packages should have its own verification (e.g., checking that base packages are installed), a test file would need to be created.
- **No documentation:** No `docs/FRAGMENT.md` exists. Consider adding minimal documentation describing what packages are installed and why.

### Template Review

Verify the package list in `fragment.yaml.tpl` is current and doesn't include deprecated packages for Ubuntu 24.04.

## Dependencies

- **Depends on:** base (Book 1), network
- **Depended on by:** pkg-security (shares layer 8), pkg-upgrade (runs after all packages)
- **Book 0 interaction:** Rendered by Builder SDK at order 50, tested at layer 8 alongside pkg-security.
