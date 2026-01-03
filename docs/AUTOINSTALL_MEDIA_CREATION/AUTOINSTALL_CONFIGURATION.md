# 5.2 Autoinstall Configuration

Autoinstall configuration is generated from Jinja2 templates in `src/autoinstall/`.

## Template Structure

```
src/autoinstall/
├── base.yaml.tpl           # Main autoinstall template
└── cloud-init/             # Cloud-init fragments (see Chapter 6)
    ├── base.yaml.tpl
    ├── 10-security.yaml.tpl
    └── 20-packages.yaml.tpl
```

## Configuration Files

Before building, create the required config files in `src/config/`:

### identity.config.yaml

```yaml
identity:
  username: admin
  password: changeme
  ssh_authorized_keys:
    - ssh-ed25519 AAAA... user@host
```

**Note:** The `identity:` top-level key matches the filename, so BuildContext auto-unwraps it. Templates access values as `{{ identity.username }}`.

See [4.1 Network Information Gathering](../NETWORK_PLANNING/NETWORK_INFORMATION_GATHERING.md) for `network.config.yaml`.

## Autoinstall Template

**src/autoinstall/base.yaml.tpl:**

```yaml
#cloud-config
autoinstall:
  version: 1

  locale: en_US.UTF-8
  keyboard:
    layout: us

  # Network: disabled during install - configured via early-commands
  network:
    version: 2
    renderer: networkd

  # Early commands: run network detection script
  early-commands:
    - |
{{ scripts["early-net.sh"] | indent(6) }}

  # Storage configuration - use largest disk
  storage:
    layout:
      name: zfs
      sizing-policy: all
      match:
        size: largest

  # SSH server
  ssh:
    install-server: true
    allow-pw: true

  # Late commands
  late-commands:
    - curtin in-target --target=/target -- systemctl enable ssh

  # Reboot after installation
  shutdown: reboot

  # Embedded cloud-init configuration (direct YAML, not a string)
  user-data:
{{ cloud_init | to_yaml | indent(4) }}
```

## Template Context

The autoinstall template has access to:

| Context | Source | Description |
|---------|--------|-------------|
| `network.*` | `network.config.yaml` | Network configuration |
| `identity.*` | `identity.config.yaml` | User identity settings |
| `scripts` | `render_scripts()` | Dict of rendered script contents |
| `cloud_init` | `render_cloud_init()` | Dict of merged cloud-init configuration |

## Build Command

```bash
make autoinstall
```

Or directly:

```bash
python -m builder render autoinstall -o output/user-data
```

This generates `output/user-data` with:
- Rendered network detection script in `early-commands`
- Merged cloud-init configuration in `user-data` field

See [3.3 Render CLI](../BUILD_SYSTEM/RENDER_CLI.md) for render function details.

## Storage Layout Options

| Layout | Description |
|--------|-------------|
| `zfs` | ZFS root filesystem (recommended for virtualization hosts) |
| `lvm` | LVM with single volume group |
| `direct` | Direct partitioning without LVM |

### Disk Selection

The `match` block controls which disk is selected for installation:

```yaml
storage:
  layout:
    name: zfs
    match:
      size: largest    # Use the largest available disk
```

| Match Option | Description |
|--------------|-------------|
| `size: largest` | Select the largest disk (current default) |
| `size: smallest` | Select the smallest disk |
| `path: /dev/nvme0n1` | Match specific device path |
| `serial: Samsung*` | Match by serial number pattern |
| `id: nvme-*` | Match by disk ID pattern |

**Future refinement:** When additional NVMe drives are added via PCI or Thunderbolt, the match criteria will need refinement to specifically target the motherboard's M.2 slot and exclude external/expansion drives.

### Recovery Strategy

This deployment does **not** use RAID. System recovery is achieved by rebuilding from the documented configuration:

1. Boot from autoinstall media
2. Automated installation proceeds using Chapters 3-6 configuration
3. VMs are restored from backup

This approach treats the infrastructure host as immutable - configuration changes go through the documented build process, not ad-hoc modifications.

## YAML Formatting Notes

**Critical:** Avoid inline comments within list items:

```yaml
# WRONG - causes "Malformed autoinstall" error
late-commands:
  - echo 'done'  # This comment breaks it

# CORRECT
late-commands:
  - echo 'done'
```

## Output Structure

The generated `user-data` contains:

1. **Autoinstall directives** - Installation settings (locale, storage, ssh)
2. **early-commands** - Network detection script from `early-net.sh.tpl`
3. **user-data** - Embedded cloud-init config from merged fragments

```yaml
#cloud-config
autoinstall:
  version: 1
  locale: en_US.UTF-8
  # ... autoinstall settings ...

  early-commands:
    - |
      #!/bin/bash
      # Rendered early-net.sh content
      GATEWAY='192.168.1.1'
      # ... network detection logic ...

  user-data:
    hostname: kvm-host
    users:
      - name: admin
        # ... user config ...
    # ... merged cloud-init config ...
```

## Filters Used

| Filter | Purpose | Example |
|--------|---------|---------|
| `to_yaml` | Convert dict to YAML | `{{ cloud_init \| to_yaml }}` |
| `indent` | Indent for YAML embedding | `{{ scripts["early-net.sh"] \| indent(6) }}` |

See [3.2 Jinja2 Filters](../BUILD_SYSTEM/JINJA2_FILTERS.md) for full filter documentation.
