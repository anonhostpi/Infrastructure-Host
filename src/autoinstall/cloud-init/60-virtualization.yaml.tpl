runcmd:
  - systemctl enable libvirtd
  - systemctl start libvirtd
  - usermod -aG libvirt {{ identity.username }}
  - usermod -aG kvm {{ identity.username }}
  - virsh net-autostart default
  - virsh net-start default || true
