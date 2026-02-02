# RESEARCH.BOOK.2.PKG.UPGRADE

## Purpose

The `pkg-upgrade` fragment (`book-2-cloud/pkg-upgrade/`) runs `apt upgrade` as the final step after all other packages are installed. It uses `build_order: 999` to ensure it always merges last.

**Build metadata:** layer 8, order 999, `iso_required: false`

## Current State

### Completed

- `build.yaml` exists with correct metadata
- `fragment.yaml.tpl` renders the apt upgrade command

### Files

```
book-2-cloud/pkg-upgrade/
├── build.yaml
└── fragment.yaml.tpl
```

## Remaining Work

This is the most minimal fragment alongside `packages`. It has no config, no docs, no scripts, and no tests.

### Gaps

- **No tests:** No verification script exists. The old notes suggested creating a `tests/` directory. Since this fragment runs at layer 8 (same as packages/pkg-security), testing could verify that `apt upgrade` completed successfully.
- **No documentation:** No `docs/FRAGMENT.md` exists.

### Build Layer vs. Build Order

Note the distinction: `build_layer: 8` means this fragment is included starting at layer 8, but `build_order: 999` ensures it merges last in the cloud-init output. This guarantees all other apt package installations happen before the upgrade runs.

### Template Review

Verify the template uses appropriate `apt upgrade` flags (e.g., `-y` for non-interactive mode) and handles held packages correctly.

## Dependencies

- **Depends on:** All other package fragments (conceptually runs after everything)
- **Depended on by:** None -- this is the final package operation
- **Book 0 interaction:** Rendered by Builder SDK at order 999 (always last). No dedicated test layer.
