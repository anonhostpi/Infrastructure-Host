# 6.8 Package Security Fragment

**Template:** `src/autoinstall/cloud-init/50-pkg-security.yaml.tpl`

Configures automatic package updates and unattended security upgrades.

## Template

```yaml
package_update: true
package_upgrade: true

packages:
  - unattended-upgrades
  - apt-listchanges

write_files:
  - path: /etc/apt/apt.conf.d/50unattended-upgrades
    permissions: '0644'
    content: |
      Unattended-Upgrade::Allowed-Origins {
          "${distro_id}:${distro_codename}-security";
          "${distro_id}ESMApps:${distro_codename}-apps-security";
          "${distro_id}ESM:${distro_codename}-infra-security";
      };

      Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
      Unattended-Upgrade::Remove-Unused-Dependencies "true";

      // Disable auto-reboot for KVM host (VMs may be running)
      Unattended-Upgrade::Automatic-Reboot "false";

      // Email notification (requires msmtp - see 6.7)
      Unattended-Upgrade::Mail "root";
      Unattended-Upgrade::MailReport "on-change";

      Unattended-Upgrade::SyslogEnable "true";

  - path: /etc/apt/apt.conf.d/20auto-upgrades
    permissions: '0644'
    content: |
      APT::Periodic::Update-Package-Lists "1";
      APT::Periodic::Unattended-Upgrade "1";
      APT::Periodic::AutocleanInterval "7";
```

## Configuration Fields

| Field | Value | Description |
|-------|-------|-------------|
| `package_update` | true | Run `apt update` on first boot |
| `package_upgrade` | true | Run `apt upgrade` on first boot |

## First Boot Behavior

On first boot, cloud-init will:

1. Update package lists (`apt update`)
2. Upgrade all installed packages (`apt upgrade`)

This ensures the system starts with the latest security patches.

---

## Unattended Upgrades

The `unattended-upgrades` package provides ongoing automatic security updates.

### Configuration Options

| Setting | Value | Purpose |
|---------|-------|---------|
| `Allowed-Origins` | security repos | Only install security updates |
| `Remove-Unused-Kernel-Packages` | true | Clean up old kernels |
| `Remove-Unused-Dependencies` | true | Remove orphaned packages |
| `Automatic-Reboot` | false | Don't auto-reboot (VMs may be running) |
| `Mail` | root | Send notifications to root (via aliases) |
| `MailReport` | on-change | Email when updates installed or errors |

### MailReport Options

| Value | Behavior |
|-------|----------|
| `"always"` | Send email for every run |
| `"only-on-error"` | Only send on errors |
| `"on-change"` | Send when updates installed or errors occur |

**Note:** Email notifications require msmtp configuration. See [6.7 MSMTP Fragment](./MSMTP_FRAGMENT.md).

---

## APT Periodic Settings

The `20auto-upgrades` file controls scheduling:

| Setting | Value | Description |
|---------|-------|-------------|
| `Update-Package-Lists` | 1 | Update package lists daily |
| `Unattended-Upgrade` | 1 | Run upgrades daily |
| `AutocleanInterval` | 7 | Clean cache weekly |

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

### Verify Configuration

```bash
# Check unattended-upgrades config
apt-config dump | grep -i unattended
```

---

## Log Files

```bash
# Unattended-upgrades log
cat /var/log/unattended-upgrades/unattended-upgrades.log

# APT history
cat /var/log/apt/history.log
```

---

## Security Considerations

1. **Security-only updates**: Only security repositories are enabled to minimize risk
2. **No auto-reboot**: Disabled because VMs may be running on the host
3. **Kernel cleanup**: Old kernels are removed to free disk space
4. **Monitoring**: Email notifications alert you to applied updates

### Manual Reboot Planning

Since auto-reboot is disabled, schedule manual reboots for kernel updates:

```bash
# Check if reboot is required
cat /var/run/reboot-required

# List packages requiring reboot
cat /var/run/reboot-required.pkgs
```
