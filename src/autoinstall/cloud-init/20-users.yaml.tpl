bootcmd:
  # user-setup.sh is base64 encoded to avoid YAML multiline string parsing issues
  # (multipass/cloud-init can mangle multi-line bootcmd scripts)
  # Directory structure: /var/lib/cloud/scripts/user-setup/
  #   - user-setup.sh.b64  (base64 encoded script)
  #   - user-setup.sh      (decoded executable)
  #   - user-setup.log     (execution output)
  - mkdir -p /var/lib/cloud/scripts/user-setup
  - echo '{{ scripts["user-setup.sh"] | to_base64 }}' > /var/lib/cloud/scripts/user-setup/user-setup.sh.b64
  - base64 -d /var/lib/cloud/scripts/user-setup/user-setup.sh.b64 > /var/lib/cloud/scripts/user-setup/user-setup.sh
  - chmod +x /var/lib/cloud/scripts/user-setup/user-setup.sh
  - /var/lib/cloud/scripts/user-setup/user-setup.sh >> /var/lib/cloud/scripts/user-setup/user-setup.log 2>&1 || true

ssh_pwauth: true
