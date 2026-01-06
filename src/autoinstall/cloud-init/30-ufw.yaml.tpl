packages:
  - ufw

runcmd:
  - ufw default deny incoming
  - ufw default allow outgoing
{% if testing is defined and testing %}
  # TESTING MODE: Use allow instead of limit to avoid rate-limiting multipass connections
  - ufw allow ssh
{% else %}
  # PRODUCTION: Rate-limit SSH to protect against brute force (6 connections per 30 seconds)
  - ufw limit ssh
{% endif %}
  - ufw logging medium
  - ufw --force enable
