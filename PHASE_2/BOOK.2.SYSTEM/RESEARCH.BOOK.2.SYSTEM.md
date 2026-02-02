# RESEARCH.BOOK.2.SYSTEM

## Purpose

The `system` fragment (`book-2-cloud/system/`) configures system-level settings: timezone, locale, and hostname.

**Build metadata:** layer 6, order 40, `iso_required: false`

## Current State

### Completed

- `build.yaml` exists with correct metadata
- `fragment.yaml.tpl` renders system configuration
- `tests/6/verifications.ps1` exists for layer 6 testing
- Documentation in `docs/FRAGMENT.md`

### Files

```
book-2-cloud/system/
├── build.yaml
├── fragment.yaml.tpl
├── docs/FRAGMENT.md
└── tests/6/verifications.ps1
```

## Remaining Work

Minimal. Template-only fragment with no config files. All system settings (timezone, locale, hostname) are hardcoded in the template.

### Template Review

Verify system settings in template are appropriate for the target deployment environment.

## Dependencies

- **Depends on:** base (Book 1), network
- **Depended on by:** None directly
- **Book 0 interaction:** Rendered by Builder SDK, tested at layer 6 by CloudInitTest.
