write_files:
  - path: /etc/cockpit/cockpit.conf
    permissions: '0644'
    content: |
      [WebService]
      AllowUnencrypted = false

  - path: /etc/systemd/system/cockpit.socket.d/listen.conf
    permissions: '0644'
    content: |
      [Socket]
      ListenStream=
      ListenStream=127.0.0.1:443

runcmd:
  - systemctl daemon-reload
  - systemctl enable cockpit.socket
