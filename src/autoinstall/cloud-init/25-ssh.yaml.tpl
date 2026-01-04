write_files:
  - path: /etc/ssh/sshd_config.d/hardening.conf
    permissions: '0644'
    content: |
      PermitRootLogin no
      PasswordAuthentication no
      MaxAuthTries 3
      LoginGraceTime 20
      X11Forwarding no
      AllowTcpForwarding yes
      ClientAliveInterval 300
      ClientAliveCountMax 2

runcmd:
  - systemctl restart ssh
