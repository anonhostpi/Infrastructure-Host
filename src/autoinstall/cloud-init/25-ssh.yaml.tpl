write_files:
  - path: /etc/ssh/sshd_config.d/99-hardening.conf
    permissions: '644'
    content: |
      # SSH Hardening - managed by cloud-init

      # Authentication
      PermitRootLogin no
      MaxAuthTries 3
      LoginGraceTime 20
      PermitEmptyPasswords no
      ChallengeResponseAuthentication no

      # Forwarding
      X11Forwarding no
      AllowTcpForwarding yes

      # Session timeout
      ClientAliveInterval 300
      ClientAliveCountMax 2

runcmd:
  - systemctl restart ssh
