# RESEARCH.BOOK.2.SSH

## Purpose

The `ssh` fragment (`book-2-cloud/ssh/`) hardens the SSH server configuration. It is `iso_required: true` because bare-metal installations need SSH for headless remote access.

**Build metadata:** layer 4, order 25, `iso_required: true`

## Current State

### Completed

- `build.yaml` exists with correct metadata
- `fragment.yaml.tpl` renders SSH hardening configuration
- `tests/4/verifications.ps1` exists for layer 4 testing
- Documentation in `docs/FRAGMENT.md`

### Files

```
book-2-cloud/ssh/
├── build.yaml
├── fragment.yaml.tpl
├── docs/FRAGMENT.md
└── tests/4/verifications.ps1
```

## Remaining Work

Minimal. This is a template-only fragment with no config files. SSH hardening parameters are defined in the template.

### Template Review

- Verify SSH hardening settings align with current CIS benchmarks for Ubuntu 24.04
- SSH config may reference user authorized_keys from the users fragment -- verify cross-fragment template variable resolution

## Dependencies

- **Depends on:** base (Book 1), network, users (for authorized_keys)
- **Depended on by:** ufw (should allow SSH port 22)
- **Book 0 interaction:** Rendered by Builder SDK. Host SDK's Worker module uses SSH to connect to test VMs, so SSH hardening must not lock out the test user. Testing mode config may need to relax certain settings.
