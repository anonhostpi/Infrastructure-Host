# RESEARCH.BOOK.1.BASE

## Purpose

The `base` fragment (`book-1-foundation/base/`) is the core autoinstall configuration for Ubuntu installation. It is the only fragment in Book 1 and defines the foundation that all Book 2 cloud-init fragments build upon: locale, keyboard, network bootstrap, storage layout, and the autoinstall user-data wrapper.

**Build metadata:** layer 0, order 0, `iso_required: true`

## Current State

### Completed

- `build.yaml` exists with correct metadata
- `fragment.yaml.tpl` renders the autoinstall configuration
- `scripts/build-iso.sh.tpl` and `scripts/early-net.sh.tpl` exist
- `tests/0/verifications.ps1` exists for layer 0 testing
- Documentation exists in `docs/` (5 files)

### Files

```
book-1-foundation/base/
├── build.yaml
├── fragment.yaml.tpl
├── config/
│   ├── image.config.yaml          (gitignored)
│   ├── image.config.yaml.example
│   ├── storage.config.yaml        (gitignored)
│   ├── storage.config.yaml.example
│   ├── testing.config.yaml        (gitignored)
│   └── testing.config.yaml.example
├── docs/ (5 files)
├── scripts/ (2 .sh.tpl files)
└── tests/0/verifications.ps1
```

## Remaining Work

### Config Naming Convention

The old Phase 2 plan proposed merging `image.config.yaml` and `storage.config.yaml` into a single `production.yaml`, and renaming `testing.config.yaml` to `testing.yaml`.

This is **no longer straightforward**. Both the Python `BuildContext` (context.py) and the PowerShell `Build-TestConfig` (Config.ps1) discover config files by globbing for `*.config.yaml`. Renaming to `production.yaml` would break both loaders unless they are updated simultaneously.

**Options:**
1. Keep `*.config.yaml` naming as-is (zero risk, both SDKs work today)
2. Rename to `production.yaml` and update both SDKs' glob patterns
3. Merge image + storage into a single `base.config.yaml` (preserves glob compatibility)

Option 3 may be the best compromise: consolidate two files into one while preserving the naming convention that both SDKs expect.

### Template Review

The `fragment.yaml.tpl` references `storage.layout`, `storage.sizing_policy`, `storage.match.size`, and `testing.testing`. These template variables resolve from the config files regardless of filename, so a merge (option 3) would not require template changes.

## Dependencies

- **Depended on by:** All Book 2 fragments (base autoinstall is the foundation)
- **Book 0 interaction:** Builder SDK renders this template via `render_autoinstall()`. Host SDK's AutoinstallTest module tests it via VBox/HyperV workers.

## Open Questions

- Should image + storage configs remain separate or merge into a single file?
- Is the `testing.config.yaml` pattern (boolean flag) still the right approach, or should testing mode be handled via environment variables (`AUTOINSTALL_TESTING=true`)?
