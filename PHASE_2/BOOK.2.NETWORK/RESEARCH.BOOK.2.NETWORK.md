# RESEARCH.BOOK.2.NETWORK

## Purpose

The `network` fragment (`book-2-cloud/network/`) configures static IP addressing via arping-based interface detection. It is `iso_required: true` because bare-metal installations need network connectivity for remote access.

**Build metadata:** layer 1, order 10, `iso_required: true`

## Current State

### Completed

- `build.yaml` exists with correct metadata
- `fragment.yaml.tpl` renders network cloud-init configuration
- `scripts/net-setup.sh.tpl` exists for network setup
- `tests/1/verifications.ps1` exists for layer 1 testing
- Documentation exists in `docs/` (5 files: OVERVIEW, FRAGMENT, INFORMATION_GATHERING, SCRIPTS, TOPOLOGY)

### Files

```
book-2-cloud/network/
├── build.yaml
├── fragment.yaml.tpl
├── config/
│   ├── network.config.yaml          (gitignored)
│   └── network.config.yaml.example
├── docs/ (5 files)
├── scripts/net-setup.sh.tpl
└── tests/1/verifications.ps1
```

## Remaining Work

### Config Naming Convention

The old plan proposed renaming `network.config.yaml` to `production.yaml`. This would break both SDKs' `*.config.yaml` glob patterns (see RESEARCH.BOOK.1.BASE for detailed analysis).

**Recommendation:** Keep `network.config.yaml` as-is. The name is descriptive, follows the glob convention, and both SDKs load it correctly today.

### Template Review

No template changes expected. Config keys (`network.*`) are independent of filename.

## Dependencies

- **Depends on:** base (Book 1)
- **Depended on by:** Most Book 2 fragments rely on network being configured first
- **Book 0 interaction:** Builder SDK renders this as the first cloud-init fragment (order 10). Host SDK's CloudInitTest creates a runner VM and runs layer 1 verifications.

## Open Questions

- Should the testing overlay for network be in `testing.config.yaml` alongside base, or should network have its own testing override file?
