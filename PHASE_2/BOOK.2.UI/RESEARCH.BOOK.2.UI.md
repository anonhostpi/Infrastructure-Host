# RESEARCH.BOOK.2.UI

## Purpose

The `ui` fragment (`book-2-cloud/ui/`) installs optional desktop UI packages for GUI-based server management.

**Build metadata:** layer 15, order 90, `iso_required: false`

## Current State

### Completed

- `build.yaml` exists with correct metadata
- `fragment.yaml.tpl` renders desktop package installation
- `tests/15/verifications.ps1` exists for layer 15 testing
- Documentation in `docs/FRAGMENT.md`

### Files

```
book-2-cloud/ui/
├── build.yaml
├── fragment.yaml.tpl
├── docs/FRAGMENT.md
└── tests/15/verifications.ps1
```

## Remaining Work

Minimal. Template-only fragment with no config files. Package list is hardcoded in the template.

### Template Review

- Verify desktop environment packages are current for Ubuntu 24.04
- This is an optional fragment -- verify it doesn't introduce hard dependencies that affect headless deployments

## Dependencies

- **Depends on:** base (Book 1), network, users
- **Depended on by:** None directly
- **Book 0 interaction:** Rendered by Builder SDK, tested at layer 15 by CloudInitTest.
