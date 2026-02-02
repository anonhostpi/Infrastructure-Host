# RESEARCH.BOOK.2.KERNEL

## Purpose

The `kernel` fragment (`book-2-cloud/kernel/`) applies kernel hardening via sysctl configuration. Template-only fragment with no external configuration.

**Build metadata:** layer 2, order 15, `iso_required: false`

## Current State

### Completed

- `build.yaml` exists with correct metadata
- `fragment.yaml.tpl` renders sysctl hardening rules
- `tests/2/verifications.ps1` exists for layer 2 testing
- Documentation in `docs/FRAGMENT.md`

### Files

```
book-2-cloud/kernel/
├── build.yaml
├── fragment.yaml.tpl
├── docs/FRAGMENT.md
└── tests/2/verifications.ps1
```

## Remaining Work

Minimal. This is a self-contained template fragment with no config files. All sysctl values are hardcoded in the template.

### Template Review

Verify that sysctl parameters in `fragment.yaml.tpl` are current with Ubuntu 24.04 LTS kernel defaults and security best practices.

## Dependencies

- **Depends on:** base (Book 1), network
- **Depended on by:** None directly -- kernel hardening is independent
- **Book 0 interaction:** Rendered by Builder SDK, tested at layer 2 by CloudInitTest.
