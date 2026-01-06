packages:
  - qemu-kvm
  - libvirt-daemon-system
  - libvirt-clients
  - virtinst

snap:
  commands:
    - snap install multipass

write_files:
  - path: /etc/libvirt/hooks/qemu
    permissions: '755'
    content: |
      #!/bin/bash
      # libvirt QEMU hook for VM lifecycle notifications
      # Arguments: $1=VM name, $2=operation, $3=sub-operation

      VM_NAME="$1"
      OPERATION="$2"
      SUB_OPERATION="$3"
      HOSTNAME=$(hostname)
      TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
      RECIPIENT=$(grep "^root:" /etc/aliases 2>/dev/null | cut -d: -f2 | tr -d ' ')

      # Only notify on these events
      case "$OPERATION/$SUB_OPERATION" in
        start/begin)
          SUBJECT="[${HOSTNAME}] VM Started: ${VM_NAME}"
          BODY="Virtual machine '${VM_NAME}' has started.\n\nTimestamp: ${TIMESTAMP}\nHost: ${HOSTNAME}"
          ;;
        stopped/end)
          SUBJECT="[${HOSTNAME}] VM Stopped: ${VM_NAME}"
          BODY="Virtual machine '${VM_NAME}' has stopped.\n\nTimestamp: ${TIMESTAMP}\nHost: ${HOSTNAME}"
          ;;
        reconnect/begin)
          SUBJECT="[${HOSTNAME}] VM Reconnected: ${VM_NAME}"
          BODY="Virtual machine '${VM_NAME}' reconnected after libvirtd restart.\n\nTimestamp: ${TIMESTAMP}\nHost: ${HOSTNAME}"
          ;;
        *)
          # Don't notify for other events (prepare, release, migrate, etc.)
          exit 0
          ;;
      esac

      # Send notification if msmtp is configured
      if [ -n "$RECIPIENT" ] && [ -f /etc/msmtp-password ]; then
        echo -e "Subject: ${SUBJECT}\n\n${BODY}" | msmtp "$RECIPIENT" 2>/dev/null || true
      fi

      exit 0

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
