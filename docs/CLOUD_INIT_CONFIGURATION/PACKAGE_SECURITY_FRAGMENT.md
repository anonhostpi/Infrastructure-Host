# 6.8 Package Security Fragment

**Template:** `src/autoinstall/cloud-init/50-pkg-security.yaml.tpl`

Configures automatic package updates, unattended security upgrades, and unified package notification system with AI-powered summaries.

## Overview

This fragment provides:
1. **First boot updates** - Update package lists on initial boot
2. **Unattended upgrades** - Automatic security updates for apt packages
3. **Multi-package manager updates** - Daily updates for snap, brew, pip, npm, deno
4. **Unified notifications** - Batched email reports with AI-generated summaries

## Template Structure

```yaml
package_update: true
package_upgrade: false

packages:
  - unattended-upgrades
  - apt-listchanges

runcmd:
  # Hold snap auto-refreshes - we'll refresh via pkg-managers-update timer instead
  - snap set system refresh.hold="forever"
  - snap set system refresh.metered=hold
  # Enable the package managers update timer
  - systemctl daemon-reload
  - systemctl enable --now pkg-managers-update.timer

write_files:
  - path: /etc/apt/apt.conf.d/50unattended-upgrades
  - path: /etc/apt/apt.conf.d/20auto-upgrades
  - path: /etc/apt/listchanges.conf
  - path: /etc/apt/apt.conf.d/90pkg-notify
  - path: /usr/local/lib/apt-notify/common.sh
  - path: /usr/local/bin/apt-notify
  - path: /usr/local/bin/apt-notify-flush
  - path: /usr/local/bin/snap-update
  - path: /usr/local/bin/brew-update
  - path: /usr/local/bin/pip-global-update
  - path: /usr/local/bin/npm-global-update
  - path: /usr/local/bin/deno-update
  - path: /etc/systemd/system/pkg-managers-update.service
  - path: /etc/systemd/system/pkg-managers-update.timer
```

## Configuration Fields

| Field | Value | Description |
|-------|-------|-------------|
| `package_update` | true | Run `apt update` on first boot |
| `package_upgrade` | false | Don't run full upgrade (handled by unattended-upgrades) |

## First Boot Behavior

On first boot, cloud-init will:

1. Update package lists (`apt update`)
2. Install `unattended-upgrades` and `apt-listchanges`
3. Hold snap auto-refreshes (controlled by pkg-managers-update timer instead)
4. Enable the daily package managers update timer

---

## Unattended Upgrades

### Configuration Options

| Setting | Value | Purpose |
|---------|-------|---------|
| `Allowed-Origins` | security repos + NodeSource | Install security updates and Node.js LTS |
| `Remove-Unused-Kernel-Packages` | true | Clean up old kernels |
| `Remove-Unused-Dependencies` | true | Remove orphaned packages |
| `Automatic-Reboot` | false | Don't auto-reboot (VMs may be running) |
| `Mail` | root | Send notifications to root (via aliases) |
| `MailReport` | always | Email on every run |
| `Verbose` | true | Detailed logging |

### Allowed Origins

```conf
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
    "nodistro:nodistro";  // NodeSource for Node.js LTS
};
```

### APT Periodic Settings

| Setting | Value | Description |
|---------|-------|-------------|
| `Update-Package-Lists` | 1 | Update package lists daily |
| `Unattended-Upgrade` | 1 | Run upgrades daily |
| `AutocleanInterval` | 7 | Clean cache weekly |

---

## Package Notification System

The notification system provides batched, deduplicated reports for all package changes with AI-generated summaries.

### Architecture

```
┌─────────────┐      ┌─────────────┐      ┌─────────────────┐
│  apt/dpkg   │─────▶│  apt-notify │─────▶│  Queue File     │
│  operation  │      │  (pre/post) │      │ /var/lib/apt-   │
└─────────────┘      └─────────────┘      │ notify/queue    │
                                          └────────┬────────┘
┌─────────────┐      ┌─────────────┐              │
│ snap/brew/  │─────▶│  *-update   │──────────────┤
│ pip/npm/deno│      │  scripts    │              │
└─────────────┘      └─────────────┘              │
                                                  ▼
                     ┌─────────────────────────────────────┐
                     │        apt-notify-flush             │
                     │  - Deduplicates changes             │
                     │  - Generates AI summary             │
                     │  - Sends unified email              │
                     └─────────────────────────────────────┘
```

### Batching Behavior

1. **First change**: Queued and timer scheduled (default: 2 minutes)
2. **Subsequent changes**: Added to queue, timer continues
3. **Timer expires**: Flush script runs, deduplicates, generates AI summary, sends email

### Notification Interval

Configurable via `smtp.notification_interval` (default: `2m`):

```yaml
smtp:
  notification_interval: 5m  # 5 minutes
```

Supports: `s` (seconds), `m` (minutes), `h` (hours), `d` (days)

### AI Summary Generation

The notification system can generate AI summaries using (in order of preference):
1. **OpenCode** - if `opencode.enabled: true`
2. **Claude Code** - if `claude_code.enabled: true`
3. **Copilot CLI** - if `copilot_cli.enabled: true`

Model configuration falls back through the chain if primary isn't available.

---

## Package Manager Update Scripts

### Daily Timer

The `pkg-managers-update.timer` runs daily with 1-hour random delay:

```ini
[Timer]
OnCalendar=daily
RandomizedDelaySec=1h
Persistent=true
```

### Update Scripts

| Script | Purpose |
|--------|---------|
| `/usr/local/bin/snap-update` | Refresh held snaps |
| `/usr/local/bin/brew-update` | Update Homebrew packages |
| `/usr/local/bin/pip-global-update` | Update pip global packages |
| `/usr/local/bin/npm-global-update` | Update npm global packages |
| `/usr/local/bin/deno-update` | Update Deno runtime |

### Snap Handling

Snap auto-refresh is disabled via:
```bash
snap set system refresh.hold="forever"
snap set system refresh.metered=hold
```

Snaps are instead refreshed by the daily `pkg-managers-update` timer, with updates included in the unified notification.

---

## Testing

### Dry Run

```bash
# Shows what would be upgraded
sudo unattended-upgrade --dry-run --debug
```

### Force Run

```bash
# Actually installs updates
sudo unattended-upgrade --debug
```

### Test Notification System

```bash
# Install a package to trigger notification
sudo apt install cowsay

# Check queue
cat /var/lib/apt-notify/queue

# View log
cat /var/lib/apt-notify/apt-notify.log

# Force flush (sends notification immediately)
sudo /usr/local/bin/apt-notify-flush
```

### Test Package Manager Updates

```bash
# Run all package manager updates
sudo systemctl start pkg-managers-update.service

# Check timer status
systemctl status pkg-managers-update.timer
```

---

## Log Files

```bash
# apt-notify log (batching and notification system)
cat /var/lib/apt-notify/apt-notify.log

# Unattended-upgrades log
cat /var/log/unattended-upgrades/unattended-upgrades.log

# APT history
cat /var/log/apt/history.log
```

---

## Testing Mode

When `testing: true` is set, the notification system writes reports to files instead of (in addition to) sending emails:

| File | Contents |
|------|----------|
| `/var/lib/apt-notify/test-report.txt` | Package change report |
| `/var/lib/apt-notify/test-ai-summary.txt` | AI-generated summary |

---

## Security Considerations

1. **Security-only updates**: Only security repositories are enabled to minimize risk
2. **No auto-reboot**: Disabled because VMs may be running on the host
3. **Kernel cleanup**: Old kernels are removed to free disk space
4. **Monitoring**: Email notifications alert you to applied updates
5. **Controlled snap updates**: Snaps held from auto-refresh, updated on schedule

### Manual Reboot Planning

Since auto-reboot is disabled, schedule manual reboots for kernel updates:

```bash
# Check if reboot is required
cat /var/run/reboot-required

# List packages requiring reboot
cat /var/run/reboot-required.pkgs
```
