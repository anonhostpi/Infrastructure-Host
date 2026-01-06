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
