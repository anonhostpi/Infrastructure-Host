# 6.8 Base Packages Fragment

**Build metadata:** layer 8, order 50, `iso_required: false`

Provides the base package list for cloud-init. This fragment renders an
empty `packages: []` directive that seeds the cloud-init packages array.
Other fragments at the same or later layers append their own packages.

## Template

```yaml
packages: []
```

## Relationship to Other Fragments

| Fragment | Layer | Adds |
|----------|-------|------|
| packages (this) | 8 | Empty base list |
| pkg-security | 8 | unattended-upgrades, apt-listchanges |
| Other fragments | various | Their own packages |

The builder SDK deep-merges all fragment outputs. Arrays concatenate,
so packages from later fragments append to this base list.

## Testing

Verification tests confirm cloud-init package module executed and
the apt cache was updated during first boot.
