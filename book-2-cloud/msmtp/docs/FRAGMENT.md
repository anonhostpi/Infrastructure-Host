# 6.7 MSMTP Fragment

**Template:** `book-2-cloud/msmtp/fragment.yaml.tpl`

Configures msmtp as a lightweight SMTP client for sending system notifications (fail2ban alerts, unattended-upgrade reports, etc.).

## Overview

msmtp is a simple SMTP client that acts as a sendmail replacement. It forwards emails to an external SMTP server, enabling system notifications without running a full mail server.

## Template

The template is wrapped in a conditional - if `smtp.host` is not defined, no SMTP configuration is generated.

```yaml
{% if smtp is defined and smtp.host is defined %}
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
{% if smtp.tls_trust_file is defined %}
      tls_trust_file {{ smtp.tls_trust_file }}
{% else %}
      tls_trust_file /etc/ssl/certs/ca-certificates.crt
{% endif %}
      logfile        /var/log/msmtp.log

      account        default
      host           {{ smtp.host }}
      port           {{ smtp.port | default(587) }}
      from           {{ smtp.from_email }}
      user           {{ smtp.user }}
{% if smtp.password is defined %}
      password       {{ smtp.password }}
{% else %}
      passwordeval   "cat /etc/msmtp-password"
{% endif %}
{% if smtp.tls_starttls is defined %}
      tls_starttls   {{ 'on' if smtp.tls_starttls else 'off' }}
{% endif %}
{% if smtp.tls_certcheck is defined and not smtp.tls_certcheck %}
      tls_certcheck  off
{% endif %}
{% if smtp.tls_on_connect is defined and smtp.tls_on_connect %}
      tls_starttls   off
{% endif %}
{% if smtp.tls_key_file is defined %}
      tls_key_file   {{ smtp.tls_key_file }}
{% endif %}
{% if smtp.tls_cert_file is defined %}
      tls_cert_file  {{ smtp.tls_cert_file }}
{% endif %}
{% if smtp.auth_method is defined %}
      auth           {{ smtp.auth_method }}
{% endif %}
{% if smtp.passwordeval is defined %}
      passwordeval   {{ smtp.passwordeval }}
{% endif %}

  - path: /etc/aliases
    permissions: '0644'
    content: |
      root: {{ smtp.recipient }}
      default: {{ smtp.recipient }}

  - path: /usr/local/bin/msmtp-config
    permissions: '0755'
    content: |
      #!/bin/bash
      # ... (password setup script - see source)

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
{% endif %}
```

## Configuration

Create `book-2-cloud/msmtp/config/smtp.config.yaml`:

```yaml
smtp:
  host: smtp.example.com
  port: 587
  from_email: alerts@example.com
  user: alerts@example.com
  recipient: admin@example.com
  # Optional settings for special providers:
  # tls_certcheck: false     # For self-signed certs (Proton Bridge)
  # tls_on_connect: true     # For port 465 (SMTPS)
  # auth_method: plain       # Override auth method if needed
```

### Required Fields

| Field | Description |
|-------|-------------|
| `host` | SMTP server hostname |
| `port` | SMTP port (587 for STARTTLS, 465 for SMTPS) |
| `from_email` | Sender email address (From header) |
| `user` | SMTP authentication username |
| `recipient` | Where to send system emails |

### Authentication

| Field | Default | Description |
|-------|---------|-------------|
| `password` | (none) | SMTP password/App Password/API key. If omitted, run `msmtp-config` post-deploy |
| `passwordeval` | (none) | Shell command to retrieve password (for OAuth2 token helpers) |

### TLS Options

| Field | Default | Description |
|-------|---------|-------------|
| `tls_certcheck` | `true` | Verify server certificate. Set `false` for Proton Bridge |
| `tls_on_connect` | `false` | Immediate TLS (port 465). Set `true` for SMTPS |
| `tls_starttls` | `true` | Use STARTTLS. Usually auto-detected |
| `tls_trust_file` | system CAs | Path to CA certificate bundle |

### Client Certificate Options (Self-hosted servers only)

| Field | Default | Description |
|-------|---------|-------------|
| `tls_cert_file` | (none) | Path to client certificate (for mutual TLS) |
| `tls_key_file` | (none) | Path to client certificate key |

> **Note:** Cloud providers (Gmail, M365, SendGrid, AWS SES, etc.) do NOT support client certificate authentication. These options are only for self-hosted mail servers.

### Advanced Options

| Field | Default | Description |
|-------|---------|-------------|
| `auth_method` | auto | Auth method: `plain`, `login`, `cram-md5`, `oauthbearer`, `xoauth2`, `external` |

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
5. **Log rotation**: Automatically configured via `/etc/logrotate.d/msmtp` (included in template)
