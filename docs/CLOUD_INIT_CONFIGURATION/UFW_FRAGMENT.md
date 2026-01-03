# 6.4 UFW Fragment

**Template:** `src/autoinstall/cloud-init/30-ufw.yaml.tpl`

Configures base firewall policy. Other fragments add their own rules.

## Template

```yaml
packages:
  - ufw

runcmd:
  # Set default policies
  - ufw default deny incoming
  - ufw default allow outgoing
  # Allow SSH (required for remote access)
  - ufw allow 22/tcp
  # Enable firewall
  - ufw --force enable
```

## Default Policy

| Direction | Policy | Purpose |
|-----------|--------|---------|
| Incoming | deny | Block all unsolicited connections |
| Outgoing | allow | Permit outbound connections |

## Base Rules

| Port | Protocol | Purpose |
|------|----------|---------|
| 22 | TCP | SSH access |

SSH is allowed by default to prevent lockout.

## Distributed Rules

Other fragments add their own firewall rules:

| Fragment | Rule | Purpose |
|----------|------|---------|
| [6.9 Cockpit](./COCKPIT_FRAGMENT.md) | `ufw allow 9090/tcp` | Cockpit web UI |

Each fragment is responsible for opening ports it requires.

## Rule Order

UFW rules are processed in order of addition. The base policy (deny incoming) applies to any traffic not matching a rule.

Since fragments are merged in alphabetical order:
1. UFW base (30-*) sets up defaults
2. Later fragments (60-*, 70-*) add service-specific rules

## Enabling UFW

The `--force` flag enables UFW non-interactively:

```bash
ufw --force enable
```

Without `--force`, UFW prompts for confirmation which would hang cloud-init.

## Verification

After deployment, verify firewall status:

```bash
sudo ufw status verbose
```

Expected output:
```
Status: active
Default: deny (incoming), allow (outgoing), disabled (routed)

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere
9090/tcp                   ALLOW IN    Anywhere
```
