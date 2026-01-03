# 6.7 MSMTP Fragment

**Template:** `src/autoinstall/cloud-init/45-msmtp.yaml.tpl`

Configures msmtp as a lightweight SMTP client for sending system notifications (fail2ban alerts, unattended-upgrade reports, etc.).

## Overview

msmtp is a simple SMTP client that acts as a sendmail replacement. It forwards emails to an external SMTP server, enabling system notifications without running a full mail server.

## Template

```yaml
packages:
  - msmtp
  - msmtp-mta

write_files:
  - path: /etc/msmtprc
    permissions: '0600'
    content: |
      defaults
      auth           on
      tls            on
      tls_trust_file /etc/ssl/certs/ca-certificates.crt
      logfile        /var/log/msmtp.log

      account        default
      host           {{ smtp.host }}
      port           {{ smtp.port }}
      from           {{ smtp.from_email }}
      user           {{ smtp.user }}
      passwordeval   "cat /etc/msmtp-password"

  - path: /etc/aliases
    permissions: '0644'
    content: |
      root: {{ smtp.recipient }}
      default: {{ smtp.recipient }}

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

## Configuration

Create `src/config/smtp.config.yaml`:

```yaml
smtp:
  host: smtp.example.com
  port: 587
  from_email: alerts@example.com
  user: alerts@example.com
  recipient: admin@example.com
```

| Field | Description |
|-------|-------------|
| `host` | SMTP server hostname |
| `port` | SMTP port (usually 587 for STARTTLS) |
| `from_email` | Sender email address |
| `user` | SMTP authentication username |
| `recipient` | Where to send system emails |

---

## Provider Configurations

### Proton Mail

Proton Mail requires the Proton Mail Bridge application for SMTP access. The Bridge runs locally and provides SMTP on localhost.

**Setup Steps:**

1. Install Proton Mail Bridge on a machine with GUI access
2. Sign in and note the Bridge SMTP credentials
3. For headless servers, use Bridge CLI mode or configure on another host

**Bridge SMTP Settings:**

```yaml
smtp:
  host: 127.0.0.1        # Bridge runs locally
  port: 1025             # Default Bridge SMTP port
  from_email: your-email@proton.me
  user: your-email@proton.me
  recipient: admin@example.com
```

**msmtprc for Proton Bridge:**

```conf
account        proton
host           127.0.0.1
port           1025
from           your-email@proton.me
user           your-email@proton.me
passwordeval   "cat /etc/msmtp-password"
tls            on
tls_starttls   on
tls_certcheck  off       # Bridge uses self-signed cert

account default : proton
```

**Note:** The password is the Bridge-generated password, not your Proton account password. Find it in Bridge under Settings > SMTP.

**Alternative - Proton SMTP (Business accounts):**

Business/Visionary accounts can use direct SMTP:

```yaml
smtp:
  host: smtp.protonmail.ch
  port: 587
  from_email: your-email@proton.me
  user: your-email@proton.me
  recipient: admin@example.com
```

---

### Microsoft 365 / Outlook

Requires an App Password when MFA is enabled.

**Creating an App Password:**

1. Go to: https://mysignins.microsoft.com/security-info
2. Click "Add sign-in method" → "App password"
3. Name it (e.g., "KVM Host Alerts")
4. Copy the generated password

**smtp.config.yaml:**

```yaml
smtp:
  host: smtp.office365.com
  port: 587
  from_email: alerts@yourdomain.com
  user: alerts@yourdomain.com
  recipient: admin@yourdomain.com
```

**msmtprc:**

```conf
account        m365
host           smtp.office365.com
port           587
from           alerts@yourdomain.com
user           alerts@yourdomain.com
passwordeval   "cat /etc/msmtp-password"

account default : m365
```

---

### Gmail

Requires an App Password (2FA must be enabled).

**Creating an App Password:**

1. Go to: https://myaccount.google.com/apppasswords
2. Select "Mail" and your device
3. Click "Generate"
4. Copy the 16-character password

**smtp.config.yaml:**

```yaml
smtp:
  host: smtp.gmail.com
  port: 587
  from_email: your-email@gmail.com
  user: your-email@gmail.com
  recipient: admin@example.com
```

**msmtprc:**

```conf
account        gmail
host           smtp.gmail.com
port           587
from           your-email@gmail.com
user           your-email@gmail.com
passwordeval   "cat /etc/msmtp-password"

account default : gmail
```

---

### SendGrid

Uses API key for authentication.

**Creating an API Key:**

1. Go to: https://app.sendgrid.com/settings/api_keys
2. Click "Create API Key"
3. Select "Restricted Access" → enable "Mail Send"
4. Copy the API key

**smtp.config.yaml:**

```yaml
smtp:
  host: smtp.sendgrid.net
  port: 587
  from_email: alerts@your-verified-domain.com
  user: apikey                    # Literal string "apikey"
  recipient: admin@example.com
```

**msmtprc:**

```conf
account        sendgrid
host           smtp.sendgrid.net
port           587
from           alerts@your-verified-domain.com
user           apikey
passwordeval   "cat /etc/msmtp-password"

account default : sendgrid
```

**Note:** The username is literally `apikey`. The password is your SendGrid API key.

---

### AWS SES

**smtp.config.yaml:**

```yaml
smtp:
  host: email-smtp.us-east-1.amazonaws.com   # Use your region
  port: 587
  from_email: alerts@your-verified-domain.com
  user: YOUR_SMTP_USERNAME
  recipient: admin@example.com
```

**Note:** SMTP credentials are different from AWS access keys. Generate them in SES console under "SMTP settings".

---

## Post-Deployment Setup

Since the SMTP password should not be stored in cloud-init, configure it after deployment:

```bash
sudo msmtp-config
```

This script:
1. Prompts for your SMTP password/App Password
2. Saves it securely to `/etc/msmtp-password`
3. Optionally sends a test email

---

## Testing

### Send Test Email

```bash
echo -e "Subject: Test\n\nTest message from $(hostname)" | msmtp recipient@example.com
```

### Check Logs

```bash
cat /var/log/msmtp.log
```

### Verify Configuration Syntax

```bash
msmtp --pretend recipient@example.com < /dev/null
```

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| "authentication failed" | Wrong password | Regenerate App Password |
| "certificate verify failed" | Missing CA certs | `apt install ca-certificates` |
| "connection refused" | Wrong port/host | Verify SMTP settings |
| No emails received | Aliases not set | Check `/etc/aliases` |
| Emails in spam | SPF/DKIM issues | Use verified sender domain |
| Proton "connection refused" | Bridge not running | Start Proton Bridge |

---

## Security Considerations

1. **Password file permissions**: `/etc/msmtp-password` must be `600`, owned by root
2. **msmtprc permissions**: `/etc/msmtprc` must be `600`, owned by root
3. **App Passwords**: Always use App Passwords, never main account passwords
4. **Dedicated account**: Consider a dedicated email account for system alerts
5. **Log rotation**: Ensure `/var/log/msmtp.log` is rotated

### Log Rotation

Add to cloud-init `write_files`:

```yaml
  - path: /etc/logrotate.d/msmtp
    permissions: '0644'
    content: |
      /var/log/msmtp.log {
        rotate 4
        weekly
        compress
        missingok
        notifempty
      }
```
