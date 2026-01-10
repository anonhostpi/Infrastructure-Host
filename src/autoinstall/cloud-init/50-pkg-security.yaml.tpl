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
          // NodeSource repository for Node.js LTS updates
          "nodistro:nodistro";
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

      // Post-upgrade hook to update npm global packages (AI CLIs)
      Unattended-Upgrade::Post-Invoke {
          "/usr/local/bin/npm-global-update";
      };

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

  # Shared library for apt-notify scripts
  - path: /usr/local/lib/apt-notify/common.sh
    permissions: '644'
    content: |
      #!/bin/bash
      # Shared functions for apt-notify and apt-notify-flush

      # Configuration
      STATE_DIR="/var/lib/apt-notify"
      STATE_FILE="/var/run/apt-notify.state"
      QUEUE_FILE="$STATE_DIR/queue"
      TIMER_FILE="$STATE_DIR/timer"
      LOG_FILE="$STATE_DIR/apt-notify.log"
      BATCH_INTERVAL="{{ smtp.notification_interval | default('2m') }}"
      OPENCODE_HOME="/home/{{ identity.username }}"

      mkdir -p "$STATE_DIR"

      # Logging function
      log() {
        local msg="$1"
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "[$timestamp] $msg" >> "$LOG_FILE"
        logger -t apt-notify "$msg"
      }

      # Resolve root alias from /etc/aliases (msmtp doesn't do this automatically)
      get_mail_recipient() {
        grep "^root:" /etc/aliases 2>/dev/null | cut -d: -f2 | tr -d ' ' || echo "root"
      }

      # Convert interval like "5m" to seconds
      interval_to_seconds() {
        local val="${1%[smhd]}"
        local unit="${1: -1}"
        case "$unit" in
          s) echo "$val" ;;
          m) echo $((val * 60)) ;;
          h) echo $((val * 3600)) ;;
          d) echo $((val * 86400)) ;;
          *) echo "$((val * 60))" ;;
        esac
      }

      # Build report from changes (format: pkg:ver for installed, pkg:old:new for upgraded)
      build_report() {
        local installed="$1" upgraded="$2" removed="$3" npm_upgraded="$4"
        local NL=$'\n'
        local report=""

        if [ -n "$installed" ]; then
          report+="=== APT: NEW PACKAGES INSTALLED ===${NL}"
          while IFS=: read -r pkg ver; do
            report+="  + $pkg ($ver)${NL}"
          done <<< "$installed"
          report+="${NL}"
        fi

        if [ -n "$upgraded" ]; then
          report+="=== APT: PACKAGES UPGRADED ===${NL}"
          while IFS=: read -r pkg old new; do
            report+="  * $pkg: $old -> $new${NL}"
          done <<< "$upgraded"
          report+="${NL}"
        fi

        if [ -n "$removed" ]; then
          report+="=== APT: PACKAGES REMOVED ===${NL}"
          while read -r pkg; do
            report+="  - $pkg${NL}"
          done <<< "$removed"
          report+="${NL}"
        fi

        if [ -n "$npm_upgraded" ]; then
          report+="=== NPM: GLOBAL PACKAGES UPGRADED ===${NL}"
          while IFS=: read -r pkg old new; do
            report+="  * $pkg: $old -> $new${NL}"
          done <<< "$npm_upgraded"
          report+="${NL}"
        fi

        # Show held packages
        local held=$(apt-mark showhold 2>/dev/null)
        if [ -n "$held" ]; then
          report+="=== APT: PACKAGES ON HOLD (skipped) ===${NL}"
          while read -r pkg; do
            report+="  ~ $pkg (manually held)${NL}"
          done <<< "$held"
          report+="${NL}"
        fi

        # Show packages kept back
        local kept_back=$(apt-get -s upgrade 2>/dev/null | grep "kept back" | sed 's/.*: //')
        if [ -n "$kept_back" ]; then
          report+="=== APT: PACKAGES KEPT BACK (would require new deps or removals) ===${NL}"
          for pkg in $kept_back; do
            report+="  ~ $pkg${NL}"
          done
          report+="${NL}"
        fi

        echo "$report"
      }

      # Generate AI summary using configured AI CLI (preference: opencode > claude > copilot)
      # If a CLI produces output but returns non-zero, include output but try next CLI
      generate_ai_summary() {
        local report="$1"
        local NL=$'\n'
        local prompt="Analyze these package changes and provide a brief changelog summary with bullet points covering: security fixes, improvements, optimizations, and notable changes. Format for quick reading by sysadmins/DevOps. Be concise but informative:${NL}${NL}${report}"
        local ai_output=""
        local ai_status=0
        local partial_outputs=""
{% if opencode.enabled | default(false) %}
        log "Using OpenCode for AI summary"
        ai_output=$(HOME="$OPENCODE_HOME" opencode run "$prompt" 2>/dev/null)
        ai_status=$?
        if [ -n "$ai_output" ]; then
          if [ $ai_status -eq 0 ]; then
            echo "[Generated by OpenCode]"
            echo ""
            echo "$ai_output"
            return 0
          else
            log "OpenCode returned output but exit code $ai_status, trying next CLI"
            partial_outputs+="[OpenCode (exit $ai_status)]${NL}${ai_output}${NL}${NL}"
          fi
        fi
{% endif %}
{% if claude_code.enabled | default(false) %}
        log "Using Claude Code for AI summary"
        ai_output=$(HOME="$OPENCODE_HOME" claude -p "$prompt" 2>/dev/null)
        ai_status=$?
        if [ -n "$ai_output" ]; then
          if [ $ai_status -eq 0 ]; then
            echo "[Generated by Claude Code]"
            echo ""
            echo "$ai_output"
            return 0
          else
            log "Claude Code returned output but exit code $ai_status, trying next CLI"
            partial_outputs+="[Claude Code (exit $ai_status)]${NL}${ai_output}${NL}${NL}"
          fi
        fi
{% endif %}
{% if copilot_cli.enabled | default(false) %}
        log "Using Copilot CLI for AI summary"
        ai_output=$(HOME="$OPENCODE_HOME" copilot explain "$prompt" 2>/dev/null)
        ai_status=$?
        if [ -n "$ai_output" ]; then
          if [ $ai_status -eq 0 ]; then
            echo "[Generated by GitHub Copilot CLI]"
            echo ""
            echo "$ai_output"
            return 0
          else
            log "Copilot CLI returned output but exit code $ai_status"
            partial_outputs+="[GitHub Copilot CLI (exit $ai_status)]${NL}${ai_output}${NL}${NL}"
          fi
        fi
{% endif %}
{% if not (opencode.enabled | default(false) or claude_code.enabled | default(false) or copilot_cli.enabled | default(false)) %}
        log "No AI CLI configured"
{% endif %}
        # If we got partial outputs but no successful completion, include them
        if [ -n "$partial_outputs" ]; then
          log "No AI CLI succeeded, including partial outputs"
          echo "[AI Summary - Partial (all CLIs returned errors)]"
          echo ""
          echo "$partial_outputs"
        fi
        return 1
      }

      # Send notification email
      # Usage: send_notification "report" ["subject_suffix"]
      send_notification() {
        local report="$1"
        local suffix="${2:-}"
        local mail_to=$(get_mail_recipient)
        local hostname=$(hostname -f)
        local subject="[$hostname] Package Changes${suffix} - $(date '+%Y-%m-%d %H:%M')"

        log "Sending notification to $mail_to"
        log "Generating AI summary..."
        local ai_summary=$(generate_ai_summary "$report")
        if [ -n "$ai_summary" ]; then
          local summary_len=$(echo -n "$ai_summary" | wc -c)
          log "AI summary generated ($summary_len chars)"
        else
          log "No AI summary (opencode not available or failed)"
        fi

        {
          echo "Subject: $subject"
          echo ""
          if [ -n "$ai_summary" ]; then
            echo "=== AI SUMMARY ==="
            echo "$ai_summary"
            echo ""
            echo "---"
            echo ""
          fi
          echo "Package changes on $hostname at $(date)"
          echo ""
          echo "$report"
        } | msmtp "$mail_to" 2>&1 | while read line; do log "msmtp: $line"; done
        local status=${PIPESTATUS[1]}
        if [ $status -eq 0 ]; then
          log "Email sent successfully"
        else
          log "ERROR: msmtp failed with exit code $status"
        fi
      }

      # Schedule the flush timer using systemd-run
      schedule_flush_timer() {
        local interval_secs=$(interval_to_seconds "$BATCH_INTERVAL")
        log "Scheduling flush timer for ${interval_secs}s (interval: $BATCH_INTERVAL)"
        systemctl stop apt-notify-flush.timer 2>/dev/null || true
        local result=$(systemd-run --unit=apt-notify-flush --on-active="${interval_secs}s" /usr/local/bin/apt-notify-flush 2>&1)
        local status=$?
        if [ $status -eq 0 ]; then
          log "Timer scheduled successfully: $result"
          echo "$(date +%s)" > "$TIMER_FILE"
        else
          log "ERROR: Failed to schedule timer (exit $status): $result"
        fi
      }

      # Check if timer is currently active
      timer_active() {
        if [ -f "$TIMER_FILE" ]; then
          if systemctl is-active apt-notify-flush.timer &>/dev/null; then
            return 0
          else
            log "Timer file exists but timer not active, cleaning up"
            rm -f "$TIMER_FILE"
            return 1
          fi
        fi
        return 1
      }

      # Queue changes for later sending
      queue_changes() {
        local installed="$1" upgraded="$2" removed="$3"
        local count=0
        {
          [ -n "$installed" ] && while IFS=: read -r pkg ver; do
            echo "INSTALLED:$pkg:$ver"
            ((count++))
          done <<< "$installed"
          [ -n "$upgraded" ] && while IFS=: read -r pkg old new; do
            echo "UPGRADED:$pkg:$old:$new"
            ((count++))
          done <<< "$upgraded"
          [ -n "$removed" ] && while read -r pkg; do
            echo "REMOVED:$pkg"
            ((count++))
          done <<< "$removed"
        } >> "$QUEUE_FILE"
        log "Queued $count package changes"
      }

  # Package notification script with batching support
  - path: /usr/local/bin/apt-notify
    permissions: '755'
    content: |
      #!/bin/bash
      # Notify on package install/upgrade/remove operations
      # Supports batching: first notification immediate, subsequent queued until timer expires

      source /usr/local/lib/apt-notify/common.sh

      case "$1" in
        pre)
          log "apt-notify pre: capturing package state"
          # Capture package state before operation
          dpkg-query -W -f='${Package} ${Version} ${Status}\n' 2>/dev/null | \
            grep ' installed$' | cut -d' ' -f1,2 > "$STATE_FILE.before"
          log "apt-notify pre: captured $(wc -l < "$STATE_FILE.before") packages"
          ;;

        post)
          log "apt-notify post: processing changes"
          # Skip if no state file (first run or error)
          if [ ! -f "$STATE_FILE.before" ]; then
            log "apt-notify post: no state file, skipping"
            exit 0
          fi

          # Capture package state after operation
          dpkg-query -W -f='${Package} ${Version} ${Status}\n' 2>/dev/null | \
            grep ' installed$' | cut -d' ' -f1,2 > "$STATE_FILE.after"
          log "apt-notify post: captured $(wc -l < "$STATE_FILE.after") packages after"

          # Compute differences (format: pkg:version or pkg:old:new)
          INSTALLED=""
          for pkg in $(comm -13 <(cut -d' ' -f1 "$STATE_FILE.before" | sort) \
                                <(cut -d' ' -f1 "$STATE_FILE.after" | sort)); do
            ver=$(grep "^$pkg " "$STATE_FILE.after" | cut -d' ' -f2)
            [ -n "$INSTALLED" ] && INSTALLED+=$'\n'
            INSTALLED+="$pkg:$ver"
          done

          REMOVED=$(comm -23 <(cut -d' ' -f1 "$STATE_FILE.before" | sort) \
                             <(cut -d' ' -f1 "$STATE_FILE.after" | sort))

          UPGRADED=""
          while read -r pkg old new; do
            [ -n "$UPGRADED" ] && UPGRADED+=$'\n'
            UPGRADED+="$pkg:$old:$new"
          done < <(join -j1 <(sort "$STATE_FILE.before") <(sort "$STATE_FILE.after") | \
                   awk '$2 != $3 {print $1, $2, $3}')

          # Count changes
          n_installed=$([ -n "$INSTALLED" ] && echo "$INSTALLED" | wc -l || echo 0)
          n_removed=$([ -n "$REMOVED" ] && echo "$REMOVED" | wc -l || echo 0)
          n_upgraded=$([ -n "$UPGRADED" ] && echo "$UPGRADED" | wc -l || echo 0)
          log "apt-notify post: found $n_installed installed, $n_upgraded upgraded, $n_removed removed"

          # Only process if there were changes
          if [ -n "$INSTALLED" ] || [ -n "$REMOVED" ] || [ -n "$UPGRADED" ]; then
            # Always queue changes
            queue_changes "$INSTALLED" "$UPGRADED" "$REMOVED"
            # Start timer if not already running
            if ! timer_active; then
              log "apt-notify post: timer not active, scheduling"
              schedule_flush_timer
            else
              log "apt-notify post: timer already active, changes queued"
            fi
          else
            log "apt-notify post: no changes detected"
          fi

          # Cleanup state files
          rm -f "$STATE_FILE.before" "$STATE_FILE.after"
          ;;
      esac

  # Flush script for batched notifications
  - path: /usr/local/bin/apt-notify-flush
    permissions: '755'
    content: |
      #!/bin/bash
      # Flush queued package notifications with deduplication

      source /usr/local/lib/apt-notify/common.sh

      log "apt-notify-flush: starting flush"

      # Clear timer state
      rm -f "$TIMER_FILE"

      # Check if queue has content
      if [ ! -s "$QUEUE_FILE" ]; then
        log "apt-notify-flush: queue empty, going dormant"
        rm -f "$QUEUE_FILE"
        exit 0
      fi

      queue_lines=$(wc -l < "$QUEUE_FILE")
      log "apt-notify-flush: processing queue with $queue_lines entries"

      # Deduplicate queue: keep final state for each package
      declare -A pkg_installed pkg_upgraded pkg_removed pkg_npm_upgraded

      while IFS=: read -r action pkg rest; do
        case "$action" in
          INSTALLED)
            unset pkg_removed["$pkg"]
            pkg_installed["$pkg"]="$rest"
            ;;
          UPGRADED)
            pkg_upgraded["$pkg"]="$rest"
            ;;
          REMOVED)
            unset pkg_installed["$pkg"]
            unset pkg_upgraded["$pkg"]
            pkg_removed["$pkg"]=1
            ;;
          NPM_UPGRADED)
            pkg_npm_upgraded["$pkg"]="$rest"
            ;;
        esac
      done < "$QUEUE_FILE"

      # Build deduplicated lists
      NL=$'\n'
      INSTALLED="" UPGRADED="" REMOVED="" NPM_UPGRADED=""

      for pkg in "${!pkg_installed[@]}"; do
        [ -n "$INSTALLED" ] && INSTALLED+="$NL"
        INSTALLED+="$pkg:${pkg_installed[$pkg]}"
      done

      for pkg in "${!pkg_upgraded[@]}"; do
        [ -n "$UPGRADED" ] && UPGRADED+="$NL"
        IFS=: read -r old new <<< "${pkg_upgraded[$pkg]}"
        UPGRADED+="$pkg:$old:$new"
      done

      for pkg in "${!pkg_removed[@]}"; do
        [ -n "$REMOVED" ] && REMOVED+="$NL"
        REMOVED+="$pkg"
      done

      for pkg in "${!pkg_npm_upgraded[@]}"; do
        [ -n "$NPM_UPGRADED" ] && NPM_UPGRADED+="$NL"
        IFS=: read -r old new <<< "${pkg_npm_upgraded[$pkg]}"
        NPM_UPGRADED+="$pkg:$old:$new"
      done

      # Clear queue
      rm -f "$QUEUE_FILE"

      # Count after dedup
      n_installed=$(echo "${!pkg_installed[@]}" | wc -w)
      n_upgraded=$(echo "${!pkg_upgraded[@]}" | wc -w)
      n_removed=$(echo "${!pkg_removed[@]}" | wc -w)
      n_npm_upgraded=$(echo "${!pkg_npm_upgraded[@]}" | wc -w)
      log "apt-notify-flush: after dedup: $n_installed installed, $n_upgraded upgraded, $n_removed removed, $n_npm_upgraded npm upgraded"

      # Build and send report if there are changes after dedup
      if [ -n "$INSTALLED" ] || [ -n "$UPGRADED" ] || [ -n "$REMOVED" ] || [ -n "$NPM_UPGRADED" ]; then
        log "apt-notify-flush: building and sending report"
        REPORT=$(build_report "$INSTALLED" "$UPGRADED" "$REMOVED" "$NPM_UPGRADED")
        send_notification "$REPORT"
        log "apt-notify-flush: complete"
      else
        log "apt-notify-flush: no changes after dedup, nothing to send"
      fi

  # npm global package update script (called by unattended-upgrades Post-Invoke)
  # Output is appended to apt-notify queue for inclusion in the unified notification
  - path: /usr/local/bin/npm-global-update
    permissions: '755'
    content: |
      #!/bin/bash
      # Update Node.js and npm global packages (opencode, claude-code, copilot-cli)
      # Called by unattended-upgrades Post-Invoke hook after apt upgrades
      # Results are written to apt-notify queue for unified email notification

      source /usr/local/lib/apt-notify/common.sh

      log "npm-global-update: starting"

      # Update Node.js via apt first
      if command -v apt-get &>/dev/null; then
        log "npm-global-update: checking for Node.js updates"
        apt-get update -qq 2>/dev/null
        NODE_UPGRADABLE=$(apt-get -s upgrade nodejs 2>/dev/null | grep -c "^Inst nodejs")
        if [ "$NODE_UPGRADABLE" -gt 0 ]; then
          log "npm-global-update: upgrading Node.js"
          apt-get install -y nodejs 2>&1 | while read line; do log "apt: $line"; done
        fi
      fi

      if ! command -v npm &>/dev/null; then
        log "npm-global-update: npm not installed, skipping"
        exit 0
      fi

      # Get list of outdated global packages
      OUTDATED=$(npm outdated -g --json 2>/dev/null || echo "{}")

      if [ "$OUTDATED" = "{}" ] || [ "$OUTDATED" = "" ]; then
        log "npm-global-update: all global packages up to date"
        exit 0
      fi

      # Parse outdated packages
      NPM_UPDATES=""
      while IFS= read -r line; do
        pkg=$(echo "$line" | jq -r '.key')
        current=$(echo "$line" | jq -r '.value.current')
        latest=$(echo "$line" | jq -r '.value.latest')
        [ -n "$NPM_UPDATES" ] && NPM_UPDATES+=$'\n'
        NPM_UPDATES+="NPM_UPGRADED:$pkg:$current:$latest"
      done < <(echo "$OUTDATED" | jq -c 'to_entries[]' 2>/dev/null)

      if [ -z "$NPM_UPDATES" ]; then
        log "npm-global-update: no npm updates parsed"
        exit 0
      fi

      log "npm-global-update: updating global packages"
      npm update -g 2>&1 | while read line; do log "npm: $line"; done

      # Append to apt-notify queue for unified notification
      echo "$NPM_UPDATES" >> "$QUEUE_FILE"
      log "npm-global-update: queued $(echo "$NPM_UPDATES" | wc -l) npm package updates"

      # Schedule flush timer if not already active
      if ! timer_active; then
        log "npm-global-update: scheduling flush timer"
        schedule_flush_timer
      fi

      log "npm-global-update: complete"
