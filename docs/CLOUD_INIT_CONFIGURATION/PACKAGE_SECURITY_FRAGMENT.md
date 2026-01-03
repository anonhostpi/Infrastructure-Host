# 6.6 Package Security Fragment

**Template:** `src/autoinstall/cloud-init/50-pkg-security.yaml.tpl`

Configures automatic package updates.

## Template

```yaml
package_update: true
package_upgrade: true
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

## Future: Unattended Upgrades

For ongoing automatic security updates, consider adding `unattended-upgrades`:

```yaml
packages:
  - unattended-upgrades

runcmd:
  - dpkg-reconfigure -plow unattended-upgrades
```

### Configuration

The default Ubuntu configuration enables security updates. To customize, use `write_files`:

```yaml
write_files:
  - path: /etc/apt/apt.conf.d/50unattended-upgrades
    content: |
      Unattended-Upgrade::Allowed-Origins {
        "${distro_id}:${distro_codename}-security";
      };
      Unattended-Upgrade::AutoFixInterruptedDpkg "true";
      Unattended-Upgrade::MinimalSteps "true";
      Unattended-Upgrade::Remove-Unused-Dependencies "true";
```

## Future: Email Notifications

For upgrade notifications via email, consider `msmtp`:

```yaml
packages:
  - msmtp
  - msmtp-mta

write_files:
  - path: /etc/msmtprc
    permissions: '0600'
    content: |
      account default
      host smtp.example.com
      port 587
      auth on
      user alerts@example.com
      password <SMTP_PASSWORD>
      from alerts@example.com
      tls on
```

Then configure unattended-upgrades to send mail:

```
Unattended-Upgrade::Mail "admin@example.com";
Unattended-Upgrade::MailReport "on-change";
```

**Note:** This is a future enhancement. Current implementation only does first-boot updates.
