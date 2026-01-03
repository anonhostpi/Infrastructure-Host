# 6.7 Package Security Fragment

**Template:** `src/autoinstall/cloud-init/50-pkg-security.yaml.tpl`

Configures automatic package updates and optional email notifications.

## Template (Basic)

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

---

## Unattended Upgrades

For ongoing automatic security updates, extend the template:

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

      // Syslog logging
      Unattended-Upgrade::SyslogEnable "true";

  - path: /etc/apt/apt.conf.d/20auto-upgrades
    permissions: '0644'
    content: |
      APT::Periodic::Update-Package-Lists "1";
      APT::Periodic::Unattended-Upgrade "1";
      APT::Periodic::AutocleanInterval "7";
```

### Configuration Options

| Setting | Value | Purpose |
|---------|-------|---------|
| `Allowed-Origins` | security repos | Only install security updates |
| `Remove-Unused-Kernel-Packages` | true | Clean up old kernels |
| `Remove-Unused-Dependencies` | true | Remove orphaned packages |
| `Automatic-Reboot` | false | Don't auto-reboot (VMs may be running) |

---

## Email Notifications

For upgrade notifications via email, add msmtp configuration.

### Prerequisites

- An SMTP relay account (M365, Gmail, SendGrid, etc.)
- For M365 with MFA: An App Password

#### Creating an M365 App Password

1. Go to: https://mysignins.microsoft.com/security-info
2. Click "Add sign-in method" → "App password"
3. Name it (e.g., "KVM Host Alerts")
4. Copy the generated password

### Template (With Email)

```yaml
package_update: true
package_upgrade: true

packages:
  - unattended-upgrades
  - apt-listchanges
  - msmtp
  - msmtp-mta

write_files:
  # msmtp configuration
  - path: /etc/msmtprc
    permissions: '0600'
    content: |
      defaults
      auth           on
      tls            on
      tls_trust_file /etc/ssl/certs/ca-certificates.crt
      logfile        /var/log/msmtp.log

      account        m365
      host           smtp.office365.com
      port           587
      from           {{ smtp.from_email }}
      user           {{ smtp.user_email }}
      passwordeval   "cat /etc/msmtp-password"

      account default : m365

  # Mail aliases
  - path: /etc/aliases
    permissions: '0644'
    content: |
      root: {{ smtp.recipient_email }}
      default: {{ smtp.recipient_email }}

  # Unattended upgrades with email
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
      Unattended-Upgrade::Automatic-Reboot "false";

      // Email notification
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

### Configuration Source

If using email notifications, create `src/config/smtp.config.yaml`:

```yaml
smtp:
  from_email: alerts@example.com
  user_email: alerts@example.com
  recipient_email: admin@example.com
```

**Note:** The SMTP password should be configured post-deployment for security.

### MailReport Options

| Value | Behavior |
|-------|----------|
| `"always"` | Send email for every run |
| `"only-on-error"` | Only send on errors |
| `"on-change"` | Send when updates installed or errors occur |

---

## Post-Deployment: SMTP Password

Since the SMTP password should not be stored in cloud-init, configure it after deployment.

### Configuration Script

Add to cloud-init `write_files`:

```yaml
  - path: /usr/local/bin/msmtp-config
    permissions: '0755'
    content: |
      #!/bin/bash
      set -e

      PASSWORD_FILE="/etc/msmtp-password"

      echo "=== msmtp Email Configuration ==="
      echo ""
      echo -n "SMTP password or App Password: "
      read -s SMTP_PASSWORD
      echo ""

      echo -n "$SMTP_PASSWORD" > "$PASSWORD_FILE"
      chmod 600 "$PASSWORD_FILE"
      echo "Password saved to $PASSWORD_FILE"

      # Test email
      echo ""
      read -p "Send test email? [Y/n] " SEND_TEST
      if [[ ! "$SEND_TEST" =~ ^[Nn]$ ]]; then
        HOSTNAME=$(hostname)
        RECIPIENT=$(grep "^root:" /etc/aliases | cut -d: -f2 | tr -d ' ')
        echo -e "Subject: KVM Host - Email Test\n\nTest email from $HOSTNAME.\n\nTimestamp: $(date)" | msmtp "$RECIPIENT"
        if [ $? -eq 0 ]; then
          echo "Test email sent to $RECIPIENT"
        else
          echo "Failed - check /var/log/msmtp.log"
        fi
      fi

      echo ""
      echo "Email configuration complete!"
```

### Usage

```bash
# After deployment, run:
sudo msmtp-config

# Follow prompts to configure SMTP password
```

---

## Alternative SMTP Providers

### Gmail

```conf
account        gmail
host           smtp.gmail.com
port           587
from           your-email@gmail.com
user           your-email@gmail.com
passwordeval   "cat /etc/msmtp-password"
```

**Note:** Requires App Password (2FA must be enabled)

### SendGrid

```conf
account        sendgrid
host           smtp.sendgrid.net
port           587
from           your-verified-sender@example.com
user           apikey
passwordeval   "cat /etc/msmtp-password"
```

**Note:** Password is your SendGrid API key

---

## Testing

### Test msmtp

```bash
# Send test email
echo -e "Subject: Test\n\nTest message" | msmtp recipient@example.com

# Check log for errors
cat /var/log/msmtp.log
```

### Test Unattended-Upgrades

```bash
# Dry run (shows what would be upgraded)
sudo unattended-upgrade --dry-run --debug

# Force run (actually installs updates)
sudo unattended-upgrade --debug
```

### Verify Configuration

```bash
# Check msmtp config syntax
msmtp --pretend recipient@example.com < /dev/null

# Check unattended-upgrades config
apt-config dump | grep -i unattended
```

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| "authentication failed" | Wrong password | Regenerate App Password |
| "certificate verify failed" | Missing CA certs | `apt install ca-certificates` |
| "connection refused" | Wrong port/host | Verify SMTP settings with provider |
| No emails received | Aliases not configured | Check `/etc/aliases` |
| Emails in spam | SPF/DKIM issues | Use verified sender domain |

### Log Files

```bash
# msmtp log
cat /var/log/msmtp.log

# Unattended-upgrades log
cat /var/log/unattended-upgrades/unattended-upgrades.log
```

---

## Security Considerations

1. **Password file permissions**: Always 600, owned by root
2. **msmtprc permissions**: Always 600, owned by root
3. **App Passwords**: Use App Passwords instead of main account password
4. **Dedicated account**: Consider using a dedicated email account for alerts
5. **Log rotation**: Ensure msmtp.log is rotated to prevent credential exposure
