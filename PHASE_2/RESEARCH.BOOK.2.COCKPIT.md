# RESEARCH.BOOK.2.COCKPIT

## Purpose

The `cockpit` fragment (`book-2-cloud/cockpit/`) installs and configures Cockpit, a web-based server management interface accessible on port 9090.

**Build metadata:** layer 11, order 70, `iso_required: false`

## Current State

### Completed

- `build.yaml` exists with correct metadata
- `fragment.yaml.tpl` renders Cockpit installation and configuration
- `tests/11/verifications.ps1` exists for layer 11 testing
- Documentation in `docs/FRAGMENT.md`

### Files

```
book-2-cloud/cockpit/
├── build.yaml
├── fragment.yaml.tpl
├── config/
│   ├── cockpit.config.yaml          (gitignored)
│   └── cockpit.config.yaml.example
├── docs/FRAGMENT.md
└── tests/11/verifications.ps1
```

## Remaining Work

### Config Naming Convention

The old plan proposed renaming `cockpit.config.yaml` to `production.yaml`. Same concern as other fragments: breaks `*.config.yaml` glob in both SDKs.

**Recommendation:** Keep `cockpit.config.yaml` as-is.

### Template Review

- Verify Cockpit package names are current for Ubuntu 24.04
- Check that web UI port (9090) is opened in UFW if UFW fragment is active
- Verify template variables resolve correctly from `cockpit.*` config keys

## Dependencies

- **Depends on:** base (Book 1), network, users
- **Depended on by:** None directly
- **Book 0 interaction:** Builder SDK renders this template with BuildContext loading cockpit config. Testing at layer 11 verifies Cockpit is installed and accessible.
