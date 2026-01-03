# Cloud-init Configuration

This section documents the cloud-init fragments that compose the final cloud-init configuration.

## Contents

- [6.1 Network Fragment](./NETWORK_FRAGMENT.md)
- [6.2 Users Fragment](./USERS_FRAGMENT.md)
- [6.3 SSH Hardening Fragment](./SSH_HARDENING_FRAGMENT.md)
- [6.4 UFW Fragment](./UFW_FRAGMENT.md)
- [6.5 System Settings Fragment](./SYSTEM_SETTINGS_FRAGMENT.md)
- [6.6 Package Security Fragment](./PACKAGE_SECURITY_FRAGMENT.md)
- [6.7 Security Monitoring Fragment](./SECURITY_MONITORING_FRAGMENT.md)
- [6.8 Virtualization Fragment](./VIRTUALIZATION_FRAGMENT.md)
- [6.9 Cockpit Fragment](./COCKPIT_FRAGMENT.md)
- [6.10 UI Touches Fragment](./UI_TOUCHES_FRAGMENT.md)

## Fragment Composition

Cloud-init configuration is built from multiple fragment templates in `src/autoinstall/cloud-init/`. The build system (see [Chapter 3](../BUILD_SYSTEM/OVERVIEW.md)) merges these fragments using `deep_merge`:

| Type | Merge Behavior |
|------|----------------|
| **Arrays** | Extended (fragment items appended) |
| **Objects** | Recursively merged (keys combined) |
| **Scalars** | Replaced by later fragment |

### Array Fields

These cloud-init fields are arrays that get extended across fragments:

- `packages` - APT packages to install
- `runcmd` - Commands to run at final stage
- `bootcmd` - Commands to run early (every boot)
- `write_files` - Files to create
- `snap.commands` - Snap packages to install

Each fragment can contribute to these arrays without overwriting others.

### Fragment Ordering

Fragments are processed in alphabetical order. Use numeric prefixes to control merge order:

```
src/autoinstall/cloud-init/
├── 10-network.yaml.tpl      # Core infrastructure
├── 20-users.yaml.tpl        # Identity/access
├── 25-ssh.yaml.tpl          # SSH hardening
├── 30-ufw.yaml.tpl          # Firewall base
├── 40-system.yaml.tpl       # System settings
├── 50-pkg-security.yaml.tpl # Package security
├── 55-security-mon.yaml.tpl # Security monitoring
├── 60-virtualization.yaml.tpl
├── 70-cockpit.yaml.tpl
└── 90-ui.yaml.tpl           # Final touches
```

Later fragments can override scalar values from earlier ones, and append to arrays.

## Security Architecture

| Layer | Fragment | Purpose |
|-------|----------|---------|
| Access Control | [6.2 Users](./USERS_FRAGMENT.md) | User accounts, disable root |
| Network Auth | [6.3 SSH](./SSH_HARDENING_FRAGMENT.md) | sshd hardening |
| Firewall | [6.4 UFW](./UFW_FRAGMENT.md) | Base policy, distributed rules |
| Updates | [6.6 Package Security](./PACKAGE_SECURITY_FRAGMENT.md) | Auto-update, auto-upgrade |
| Monitoring | [6.7 Security Monitoring](./SECURITY_MONITORING_FRAGMENT.md) | fail2ban, auditd (future) |

## Build Output

```bash
make cloud-init
```

Generates `output/cloud-init.yaml` - all fragments merged into a single cloud-init config.

This merged config is then embedded into autoinstall `user-data` via `make autoinstall`.
