packages:
  - fastfetch
  - bat
  - fd-find
  - jq
  - tree
  - htop
  - ncdu

write_files:
  # Disable default Ubuntu MOTD components
  - path: /etc/default/motd-news
    permissions: '0644'
    content: |
      ENABLED=0

  # Dynamic MOTD: System header
  - path: /etc/update-motd.d/00-header
    permissions: '0755'
    content: |
      #!/bin/bash
      echo ""
      echo "  Ubuntu Infrastructure Host"
      echo "  $(hostname -f)"
      echo ""

  # Dynamic MOTD: System status
  - path: /etc/update-motd.d/10-sysinfo
    permissions: '0755'
    content: |
      #!/bin/bash
      UPTIME=$(uptime -p | sed 's/up //')
      LOAD=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
      MEMORY=$(free -h | awk '/^Mem:/ {printf "%s / %s (%.0f%%)", $3, $2, $3/$2*100}')
      DISK=$(df -h / | awk 'NR==2 {printf "%s / %s (%s)", $3, $2, $5}')

      printf "  %-12s %s\n" "Uptime:" "$UPTIME"
      printf "  %-12s %s\n" "Load:" "$LOAD"
      printf "  %-12s %s\n" "Memory:" "$MEMORY"
      printf "  %-12s %s\n" "Disk:" "$DISK"
      echo ""

  # Dynamic MOTD: VM status
  - path: /etc/update-motd.d/20-vms
    permissions: '0755'
    content: |
      #!/bin/bash
      if command -v virsh &> /dev/null; then
        RUNNING=$(virsh list --state-running 2>/dev/null | grep -c running || echo 0)
        TOTAL=$(virsh list --all 2>/dev/null | tail -n +3 | grep -c . || echo 0)
        if [ "$TOTAL" -gt 0 ]; then
          printf "  %-12s %s running / %s total\n" "VMs:" "$RUNNING" "$TOTAL"
          echo ""
        fi
      fi

  # Dynamic MOTD: SSH config snippet for Cockpit access
  - path: /etc/update-motd.d/30-ssh-config
    permissions: '0755'
    content: |
      #!/bin/bash
      IP=$(hostname -I | awk '{print $1}')
      USER=$(getent passwd 1000 | cut -d: -f1)
      HOSTNAME_SHORT=$(hostname -s)

      echo "  Cockpit: https://localhost (via SSH tunnel)"
      echo ""
      echo "  Add to ~/.ssh/config:"
      echo "  ----------------------------------------"
      echo "  Host ${HOSTNAME_SHORT}"
      echo "      HostName ${IP}"
      echo "      User ${USER}"
      echo "      LocalForward 443 localhost:443"
      echo "  ----------------------------------------"
      echo ""

  # Dynamic MOTD: Updates available
  - path: /etc/update-motd.d/90-updates
    permissions: '0755'
    content: |
      #!/bin/bash
      if [ -f /var/run/reboot-required ]; then
        echo "  ** System restart required **"
        echo ""
      fi
      UPDATES=$(/usr/lib/update-notifier/apt-check 2>&1 | cut -d';' -f1)
      SECURITY=$(/usr/lib/update-notifier/apt-check 2>&1 | cut -d';' -f2)
      if [ "$UPDATES" -gt 0 ]; then
        echo "  Updates: $UPDATES packages ($SECURITY security)"
        echo ""
      fi

  # Shell aliases
  - path: /etc/profile.d/aliases.sh
    permissions: '0644'
    content: |
      # Modern CLI tool aliases
      alias cat='batcat --paging=never'
      alias catp='batcat'
      alias fd='fdfind'

      # System shortcuts
      alias ll='ls -alh'
      alias la='ls -A'
      alias l='ls -CF'
      alias df='df -h'
      alias du='du -h'
      alias free='free -h'

      # Virtualization shortcuts
      alias vms='virsh list --all'
      alias vmstart='virsh start'
      alias vmstop='virsh shutdown'
      alias vmkill='virsh destroy'
      alias vmconsole='virsh console'

  # Neofetch on interactive login (optional)
  - path: /etc/profile.d/neofetch.sh
    permissions: '0644'
    content: |
      # Run neofetch on interactive login
      # Uncomment to enable:
      # if [ -t 0 ] && command -v neofetch &> /dev/null; then
      #   neofetch
      # fi

runcmd:
  # Remove default Ubuntu MOTD scripts we're replacing
  - chmod -x /etc/update-motd.d/10-help-text 2>/dev/null || true
  - chmod -x /etc/update-motd.d/50-motd-news 2>/dev/null || true
  - chmod -x /etc/update-motd.d/88-esm-announce 2>/dev/null || true
  - chmod -x /etc/update-motd.d/91-contract-ua-esm-status 2>/dev/null || true

final_message: |
  Cloud-init complete!

  Cockpit access via SSH tunnel:
    ssh -L 443:localhost:443 {{ identity.username }}@{{ network.ip_address | ip_only }}
    Then open: https://localhost

  System ready for use.
