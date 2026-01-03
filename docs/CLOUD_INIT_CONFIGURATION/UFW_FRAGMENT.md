# 6.5 UFW Fragment

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
  # Rate-limit SSH (prevents brute force)
  - ufw limit ssh
  # Enable logging
  - ufw logging medium
  # Enable firewall
  - ufw --force enable
```

## Default Policy

| Direction | Policy | Purpose |
|-----------|--------|---------|
| Incoming | deny | Block all unsolicited connections |
| Outgoing | allow | Permit outbound connections |

## Base Rules

| Rule | Purpose |
|------|---------|
| `ufw limit ssh` | Rate-limited SSH access (prevents brute force) |
| `ufw logging medium` | Log blocked and rate-limited connections |

### Rate Limiting

`ufw limit ssh` allows SSH connections but rate-limits them:
- Allows 6 connections per 30 seconds from a single IP
- Additional connections are blocked temporarily
- Works alongside fail2ban for defense in depth

### Logging Levels

| Level | Logs |
|-------|------|
| `off` | Nothing |
| `low` | Blocked packets |
| `medium` | Blocked + rate-limited + invalid packets |
| `high` | All of above + unmatched packets |
| `full` | Everything |

## Distributed Rules

Other fragments can add their own firewall rules. Each fragment is responsible for opening ports it requires.

Currently, no fragments add UFW rules:
- **Cockpit** ([6.10](./COCKPIT_FRAGMENT.md)) binds to localhost only, accessed via SSH tunnel - no firewall rule needed

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
Logging: on (medium)
Default: deny (incoming), allow (outgoing), disabled (routed)

To                         Action      From
--                         ------      ----
22/tcp                     LIMIT IN    Anywhere
```

Note: SSH shows `LIMIT IN` instead of `ALLOW IN` due to rate limiting.
