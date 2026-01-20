hostname: {{ network.hostname }}
fqdn: {{ network.hostname }}.{{ network.dns_search }}
manage_etc_hosts: true

bootcmd:
  # net-setup.sh is base64 encoded to avoid YAML multiline string parsing issues
  # Directory structure: /var/lib/cloud/scripts/net-setup/
  #   - net-setup.sh.b64  (base64 encoded script)
  #   - net-setup.sh      (decoded executable)
  #   - net-setup.log     (execution output)
  - mkdir -p /var/lib/cloud/scripts/net-setup
  - echo '{{ scripts["net-setup.sh"] | to_base64 }}' > /var/lib/cloud/scripts/net-setup/net-setup.sh.b64
  - base64 -d /var/lib/cloud/scripts/net-setup/net-setup.sh.b64 > /var/lib/cloud/scripts/net-setup/net-setup.sh
  - chmod +x /var/lib/cloud/scripts/net-setup/net-setup.sh
  - /var/lib/cloud/scripts/net-setup/net-setup.sh >> /var/lib/cloud/scripts/net-setup/net-setup.log 2>&1 || true
