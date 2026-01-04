#cloud-config
autoinstall:
  version: 1

  locale: en_US.UTF-8
  keyboard:
    layout: us

  # Network: disabled during install - configured via early-commands
  network:
    version: 2
    renderer: networkd

  # Early commands: run network detection script
  early-commands:
    - |
{{ scripts["early-net.sh"] | indent(6) }}

  # Storage configuration
  storage:
    layout:
      name: {{ storage.layout }}
      sizing-policy: {{ storage.sizing_policy }}
      match:
        size: {{ storage.match.size }}

  # SSH server
  ssh:
    install-server: true
    allow-pw: true

  # Late commands
  late-commands:
    - curtin in-target --target=/target -- systemctl enable ssh

  # Reboot after installation
  shutdown: reboot

  # Embedded cloud-init configuration (direct YAML, not a string)
  user-data:
{{ cloud_init | to_yaml | indent(4) }}
