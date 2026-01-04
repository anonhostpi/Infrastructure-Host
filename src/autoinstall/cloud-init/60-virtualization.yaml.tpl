packages:
  - qemu-kvm
  - libvirt-daemon-system
  - libvirt-clients
  - virtinst

snap:
  commands:
    - snap install multipass

runcmd:
  # Enable and start libvirtd
  - systemctl enable libvirtd
  - systemctl start libvirtd
  # Add user to virtualization groups
  - usermod -aG libvirt {{ identity.username }}
  - usermod -aG kvm {{ identity.username }}
  # Configure default network
  - virsh net-autostart default
  - virsh net-start default || true
