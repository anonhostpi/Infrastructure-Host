# RESEARCH.BOOK.2.VIRTUALIZATION

## Purpose

The `virtualization` fragment (`book-2-cloud/virtualization/`) installs KVM/QEMU virtualization packages and configures the host for nested virtualization.

**Build metadata:** layer 10, order 60, `iso_required: false`

## Current State

### Completed

- `build.yaml` exists with correct metadata
- `fragment.yaml.tpl` renders virtualization package installation
- `tests/10/verifications.ps1` exists for layer 10 testing
- Documentation in `docs/FRAGMENT.md`

### Files

```
book-2-cloud/virtualization/
├── build.yaml
├── fragment.yaml.tpl
├── docs/FRAGMENT.md
└── tests/10/verifications.ps1
```

## Remaining Work

Minimal. Template-only fragment with no config files.

### Template Review

- Verify KVM/QEMU package names are current for Ubuntu 24.04
- Check that nested virtualization requirements are correctly documented

### Testing Considerations

Testing virtualization inside VMs (Multipass/VBox/HyperV) requires nested virtualization support. The Host SDK's `Multipass.Hypervisor()` method enables nested virtualization by calling into the Vbox or HyperV module, depending on the active Multipass backend.

## Dependencies

- **Depends on:** base (Book 1), network
- **Depended on by:** None directly
- **Book 0 interaction:** Rendered by Builder SDK. Testing requires nested virtualization, which the HyperV module (`HyperV.ps1`) or Vbox module (`Vbox.ps1`) enables via the `Hypervisor()` method called from `Multipass.Create()`.
