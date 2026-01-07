package_update: true
package_upgrade: false

packages:
  - unattended-upgrades
  - apt-listchanges

write_files:
  - path: /etc/apt/apt.conf.d/50unattended-upgrades
    permissions: '644'
    content: |
      Unattended-Upgrade::Allowed-Origins {
          "${distro_id}:${distro_codename}-security";
          "${distro_id}ESMApps:${distro_codename}-apps-security";
          "${distro_id}ESM:${distro_codename}-infra-security";
      };

      Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
      Unattended-Upgrade::Remove-Unused-Dependencies "true";

      // Disable auto-reboot for KVM host (VMs may be running)
      Unattended-Upgrade::Automatic-Reboot "false";

      // Email notification (requires msmtp - see 6.7)
      Unattended-Upgrade::Mail "root";
      Unattended-Upgrade::MailReport "always";

      // Verbose logging for detailed reports
      Unattended-Upgrade::Verbose "true";
      Unattended-Upgrade::SyslogEnable "true";

  - path: /etc/apt/apt.conf.d/20auto-upgrades
    permissions: '644'
    content: |
      APT::Periodic::Update-Package-Lists "1";
      APT::Periodic::Unattended-Upgrade "1";
      APT::Periodic::AutocleanInterval "7";

  # apt-listchanges config for changelog notifications
  - path: /etc/apt/listchanges.conf
    permissions: '644'
    content: |
      [apt]
      frontend=mail
      email_address=root
      confirm=false
      save_seen=/var/lib/apt/listchanges.db
      which=both

  # dpkg hook to notify on any package install/upgrade/remove
  - path: /etc/apt/apt.conf.d/90pkg-notify
    permissions: '644'
    content: |
      // Email notifications for all package operations
      DPkg::Pre-Invoke { "/usr/local/bin/apt-notify pre"; };
      DPkg::Post-Invoke { "/usr/local/bin/apt-notify post"; };

  # Package notification script
  - path: /usr/local/bin/apt-notify
    permissions: '755'
    content: |
      #!/bin/bash
      # Notify on package install/upgrade/remove operations

      STATE_FILE="/var/run/apt-notify.state"
      # Resolve root alias from /etc/aliases (msmtp doesn't do this automatically)
      MAIL_TO=$(grep "^root:" /etc/aliases 2>/dev/null | cut -d: -f2 | tr -d ' ' || echo "root")
      HOSTNAME=$(hostname -f)

      case "$1" in
        pre)
          # Capture package state before operation
          dpkg-query -W -f='${Package} ${Version} ${Status}\n' 2>/dev/null | \
            grep ' installed$' | cut -d' ' -f1,2 > "$STATE_FILE.before"
          ;;
        post)
          # Skip if no state file (first run or error)
          [ ! -f "$STATE_FILE.before" ] && exit 0

          # Capture package state after operation
          dpkg-query -W -f='${Package} ${Version} ${Status}\n' 2>/dev/null | \
            grep ' installed$' | cut -d' ' -f1,2 > "$STATE_FILE.after"

          # Compute differences
          INSTALLED=$(comm -13 <(cut -d' ' -f1 "$STATE_FILE.before" | sort) \
                               <(cut -d' ' -f1 "$STATE_FILE.after" | sort))
          REMOVED=$(comm -23 <(cut -d' ' -f1 "$STATE_FILE.before" | sort) \
                             <(cut -d' ' -f1 "$STATE_FILE.after" | sort))
          UPGRADED=$(join -j1 <(sort "$STATE_FILE.before") <(sort "$STATE_FILE.after") | \
                     awk '$2 != $3 {print $1 ": " $2 " -> " $3}')

          # Only send email if there were changes
          if [ -n "$INSTALLED" ] || [ -n "$REMOVED" ] || [ -n "$UPGRADED" ]; then
            {
              echo "Subject: [$HOSTNAME] Package Changes - $(date '+%Y-%m-%d %H:%M')"
              echo ""
              echo "Package changes on $HOSTNAME at $(date)"
              echo ""

              if [ -n "$INSTALLED" ]; then
                echo "=== NEW PACKAGES INSTALLED ==="
                for pkg in $INSTALLED; do
                  ver=$(grep "^$pkg " "$STATE_FILE.after" | cut -d' ' -f2)
                  echo "  + $pkg ($ver)"
                done
                echo ""
              fi

              if [ -n "$UPGRADED" ]; then
                echo "=== PACKAGES UPGRADED ==="
                echo "$UPGRADED" | while read line; do
                  echo "  * $line"
                done
                echo ""
              fi

              if [ -n "$REMOVED" ]; then
                echo "=== PACKAGES REMOVED ==="
                for pkg in $REMOVED; do
                  echo "  - $pkg"
                done
                echo ""
              fi

              # Show held packages (skipped by upgrade)
              HELD=$(apt-mark showhold 2>/dev/null)
              if [ -n "$HELD" ]; then
                echo "=== PACKAGES ON HOLD (skipped) ==="
                echo "$HELD" | while read pkg; do
                  echo "  ~ $pkg (manually held)"
                done
                echo ""
              fi

              # Show packages kept back by apt upgrade
              KEPT_BACK=$(apt-get -s upgrade 2>/dev/null | grep "kept back" | sed 's/.*: //')
              if [ -n "$KEPT_BACK" ]; then
                echo "=== PACKAGES KEPT BACK (would require new deps or removals) ==="
                for pkg in $KEPT_BACK; do
                  echo "  ~ $pkg"
                done
                echo ""
              fi

            } | msmtp "$MAIL_TO" 2>/dev/null || true
          fi

          # Cleanup
          rm -f "$STATE_FILE.before" "$STATE_FILE.after"
          ;;
      esac
