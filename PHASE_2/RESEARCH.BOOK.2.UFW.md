# RESEARCH.BOOK.2.UFW

## Purpose

The `ufw` fragment (`book-2-cloud/ufw/`) configures the Uncomplicated Firewall with default deny policies and selective allow rules.

**Build metadata:** layer 5, order 30, `iso_required: false`

## Current State

### Completed

- `build.yaml` exists with correct metadata
- `fragment.yaml.tpl` renders UFW firewall rules
- `tests/5/verifications.ps1` exists for layer 5 testing
- Documentation in `docs/FRAGMENT.md`

### Files

```
book-2-cloud/ufw/
├── build.yaml
├── fragment.yaml.tpl
├── docs/FRAGMENT.md
└── tests/5/verifications.ps1
```

## Remaining Work

Minimal. Template-only fragment with no config files.

### Template Review

- Verify UFW rules allow SSH (port 22) so Host SDK can still reach test VMs
- Verify rules align with other fragments' port requirements (Cockpit on 9090, etc.)

## Dependencies

- **Depends on:** base (Book 1), network, ssh
- **Depended on by:** None directly
- **Book 0 interaction:** Rendered by Builder SDK, tested at layer 5. Host SDK connects to VMs via SSH -- UFW rules must not block SSH during testing.
