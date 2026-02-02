# 6.8 Package Upgrade Fragment

**Build metadata:** layer 8, order 999, `iso_required: false`

Runs `apt upgrade` as the final cloud-init step. Uses `build_order: 999` to ensure all other package installations complete first.

## Overview

This fragment triggers a full system upgrade after all other fragments have rendered their package installations and configurations:

1. **Update package lists** - `apt-get update` to refresh available versions
2. **Unattended upgrade** - `unattended-upgrade -v` to apply pending security updates
3. **Package manager service** - Triggers `pkg-managers-update.service` for snap, brew, pip, npm, deno
4. **Cache cleanup** - `apt-get clean` to free disk space

## Template Structure

```yaml
runcmd:
  - apt-get update -q
  - unattended-upgrade -v
  - systemctl start pkg-managers-update.service || true
  - apt-get clean
```

## Ordering

| Field | Value | Purpose |
|-------|-------|---------|
| `build_layer` | 8 | Included starting at layer 8 (Package Security) |
| `build_order` | 999 | Merges last in cloud-init output |

The high `build_order` ensures this fragment's `runcmd` entries appear after all other fragments, so every package is installed before the upgrade runs.

## Dependencies

- **Requires:** `pkg-security` (provides unattended-upgrades, pkg-managers-update service/timer)
- **Required by:** None (this is the final package operation)
