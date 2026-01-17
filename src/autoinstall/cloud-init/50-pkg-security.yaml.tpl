package_update: true
package_upgrade: false

packages:
  - unattended-upgrades
  - apt-listchanges

runcmd:
  # Hold snap auto-refreshes - we'll refresh via pkg-managers-update timer instead
  - snap set system refresh.hold="forever"
  # Set snap refresh timer to metered to prevent background refreshes
  - snap set system refresh.metered=hold
  # Enable the package managers update timer
  - systemctl daemon-reload
  - systemctl enable --now pkg-managers-update.timer

write_files:
  - path: /etc/apt/apt.conf.d/50unattended-upgrades
    permissions: '0644'
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

  - path: /etc/apt/apt.conf.d/20auto-upgrades
    permissions: '0644'
    content: |
      APT::Periodic::Update-Package-Lists "1";
      APT::Periodic::Unattended-Upgrade "1";
      APT::Periodic::AutocleanInterval "7";

  # apt-listchanges config for changelog notifications
  - path: /etc/apt/listchanges.conf
    permissions: '0644'
    content: |
      [apt]
      frontend=mail
      email_address=root
      confirm=false
      save_seen=/var/lib/apt/listchanges.db
      which=both

  # dpkg hook to notify on any package install/upgrade/remove
  - path: /etc/apt/apt.conf.d/90pkg-notify
    permissions: '0644'
    content: |
      // Email notifications for all package operations
      DPkg::Pre-Invoke { "/usr/local/bin/apt-notify pre"; };
      DPkg::Post-Invoke { "/usr/local/bin/apt-notify post"; };

  # Shared library for apt-notify scripts
  - path: /usr/local/lib/apt-notify/common.sh
    permissions: '0644'
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
{% if testing | default(false) %}
      TESTING_MODE=true
      TEST_REPORT_FILE="$STATE_DIR/test-report.txt"
      TEST_AI_SUMMARY_FILE="$STATE_DIR/test-ai-summary.txt"
{% else %}
      TESTING_MODE=false
{% endif %}

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
      # Parameters: installed upgraded removed snap_upgraded brew_upgraded pip_upgraded npm_upgraded deno_upgraded
      build_report() {
        local installed="$1" upgraded="$2" removed="$3"
        local snap_upgraded="$4" brew_upgraded="$5" pip_upgraded="$6" npm_upgraded="$7" deno_upgraded="$8"
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

        if [ -n "$snap_upgraded" ]; then
          report+="=== SNAP: PACKAGES UPGRADED ===${NL}"
          while IFS=: read -r pkg old new; do
            report+="  * $pkg: $old -> $new${NL}"
          done <<< "$snap_upgraded"
          report+="${NL}"
        fi

        if [ -n "$brew_upgraded" ]; then
          report+="=== BREW: PACKAGES UPGRADED ===${NL}"
          while IFS=: read -r pkg old new; do
            report+="  * $pkg: $old -> $new${NL}"
          done <<< "$brew_upgraded"
          report+="${NL}"
        fi

        if [ -n "$pip_upgraded" ]; then
          report+="=== PIP: PACKAGES UPGRADED ===${NL}"
          while IFS=: read -r pkg old new; do
            report+="  * $pkg: $old -> $new${NL}"
          done <<< "$pip_upgraded"
          report+="${NL}"
        fi

        if [ -n "$npm_upgraded" ]; then
          report+="=== NPM: GLOBAL PACKAGES UPGRADED ===${NL}"
          while IFS=: read -r pkg old new; do
            report+="  * $pkg: $old -> $new${NL}"
          done <<< "$npm_upgraded"
          report+="${NL}"
        fi

        if [ -n "$deno_upgraded" ]; then
          report+="=== DENO: PACKAGES UPGRADED ===${NL}"
          while IFS=: read -r pkg old new; do
            report+="  * $pkg: $old -> $new${NL}"
          done <<< "$deno_upgraded"
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

        # Write to test file if in testing mode
        if [ "$TESTING_MODE" = "true" ]; then
          log "Testing mode: writing report to $TEST_REPORT_FILE"
          echo "$report" > "$TEST_REPORT_FILE"
        fi

        echo "$report"
      }

      # Normalize model name for comparison (replace . with - for fuzzy matching)
      normalize_model() {
        echo "$1" | tr '.' '-'
      }

      # Find matching model in opencode models list with fuzzy matching on . vs -
      # Usage: find_opencode_model "provider/model" "provider-filter"
      # Outputs the matched model name (from the list) if found, empty if not
      find_opencode_model() {
        local model="$1"
        local filter="${2:-}"
        local models_list=$(HOME="$OPENCODE_HOME" opencode models 2>/dev/null)
        local normalized_model=$(normalize_model "$model")

        if [ -n "$filter" ]; then
          models_list=$(echo "$models_list" | grep "^${filter}/")
        fi

        # First try exact match
        local exact=$(echo "$models_list" | grep -x "$model")
        if [ -n "$exact" ]; then
          echo "$exact"
          return 0
        fi

        # Try normalized match (. vs -)
        while IFS= read -r candidate; do
          local normalized_candidate=$(normalize_model "$candidate")
          if [ "$normalized_model" = "$normalized_candidate" ]; then
            echo "$candidate"
            return 0
          fi
        done <<< "$models_list"

        return 1
      }

      # Get validated Copilot CLI models from error output
      # Note: copilot --model fakemodel returns non-zero, but we only need the stderr output
      get_copilot_models() {
        { copilot --model fakemodel 2>&1 || true; } | grep -o "Allowed choices are.*" | sed 's/Allowed choices are //' | tr ',' '\n' | tr -d ' '
      }

      # Find matching model in Copilot CLI models with fuzzy matching
      # Outputs the matched model name if found, empty if not
      find_copilot_model() {
        local model="$1"
        local models_list=$(get_copilot_models)
        local normalized_model=$(normalize_model "$model")

        # First try exact match
        local exact=$(echo "$models_list" | grep -x "$model")
        if [ -n "$exact" ]; then
          echo "$exact"
          return 0
        fi

        # Try normalized match (. vs -)
        while IFS= read -r candidate; do
          local normalized_candidate=$(normalize_model "$candidate")
          if [ "$normalized_model" = "$normalized_candidate" ]; then
            echo "$candidate"
            return 0
          fi
        done <<< "$models_list"

        return 1
      }

      # Generate AI summary using configured AI CLI (preference: opencode > claude > copilot)
      # If a CLI produces output but returns non-zero, include output but try next CLI
      generate_ai_summary() {
        local report="$1"
        local NL=$'\n'
        local prompt="Analyze these package changes and provide a brief changelog summary with bullet points covering: security fixes, improvements, optimizations, and notable changes. Format for quick reading by sysadmins/DevOps. Be concise but informative:${NL}${NL}${report}"
        local ai_output=""
        local ai_status=0
{% if opencode.enabled | default(false) %}
        log "Using OpenCode for AI summary"
        # Validate model exists before using (with fallback chain)
        # Priority: opencode.model > claude_code.model > copilot_cli.model > fallback
        local oc_model=""
        local oc_desired=""
{% if opencode.model is defined %}
        oc_desired="{{ opencode.model }}"
        log "Configured OpenCode model: $oc_desired"
{% elif claude_code.model is defined %}
{% if "/" in claude_code.model %}
        oc_desired="{{ claude_code.model }}"
{% else %}
        oc_desired="anthropic/{{ claude_code.model }}"
{% endif %}
        log "Derived model from Claude Code: $oc_desired"
{% elif copilot_cli.model is defined %}
{% if "/" in copilot_cli.model %}
        oc_desired="{{ copilot_cli.model }}"
{% else %}
        oc_desired="github-copilot/{{ copilot_cli.model }}"
{% endif %}
        log "Derived model from Copilot CLI: $oc_desired"
{% else %}
        oc_desired="opencode/gpt-5-nano"
        log "Using default model: $oc_desired"
{% endif %}
        # Validate the model exists
        oc_model=$(HOME="$OPENCODE_HOME" find_opencode_model "$oc_desired")
        if [ -z "$oc_model" ]; then
          log "Model $oc_desired not found, trying fallbacks..."
          # Try anthropic fallback models
          for fallback in "anthropic/claude-sonnet-4-5-latest" "anthropic/claude-haiku-4-5" "opencode/gpt-5-nano"; do
            oc_model=$(HOME="$OPENCODE_HOME" find_opencode_model "$fallback")
            if [ -n "$oc_model" ]; then
              log "Using fallback model: $oc_model"
              break
            fi
          done
        fi
        if [ -z "$oc_model" ]; then
          log "No valid OpenCode model found, skipping"
        else
          log "Using validated model: $oc_model"
          # Use script -q -c to allocate PTY (opencode requires it for output)
          # Use timeout to prevent hanging (60s should be enough for AI response)
          ai_output=$(HOME="$OPENCODE_HOME" script -q -c "timeout 60 opencode --model '$oc_model' run '$prompt'" /dev/null 2>/dev/null)
          ai_status=$?
          # Fix ownership of any files created by opencode (may run as root via systemd)
          chown -R {{ identity.username }}:{{ identity.username }} "$OPENCODE_HOME/.local/share/opencode" 2>/dev/null || true
          if [ $ai_status -eq 124 ]; then
            log "OpenCode timed out after 60s"
          fi
          if [ -n "$ai_output" ]; then
            if [ $ai_status -eq 0 ]; then
              echo "[Generated by OpenCode (provider: ${oc_model%%/*}, model: ${oc_model#*/})]"
              echo ""
              echo "$ai_output"
              return 0
            else
              log "OpenCode returned output but exit code $ai_status, trying next CLI"
              echo "[OpenCode (exit $ai_status)]"
              echo ""
              echo "$ai_output"
              echo ""
            fi
          fi
        fi
{% endif %}
{% if claude_code.enabled | default(false) %}
        log "Using Claude Code for AI summary"
        # Use configured model directly (Claude Code handles validation)
{% if claude_code.model is defined %}
        local cc_model="{{ claude_code.model }}"
        log "Using configured model: $cc_model"
{% else %}
        local cc_model="claude-haiku-4-5"
        log "Using fallback model: $cc_model"
{% endif %}

        ai_output=$(HOME="$OPENCODE_HOME" claude --model "$cc_model" -p "$prompt" 2>/dev/null)
        ai_status=$?
        if [ -n "$ai_output" ]; then
          if [ $ai_status -eq 0 ]; then
            echo "[Generated by Claude Code (model: $cc_model)]"
            echo ""
            echo "$ai_output"
            return 0
          else
            log "Claude Code returned output but exit code $ai_status, trying next CLI"
            echo "[Claude Code (exit $ai_status)]"
            echo ""
            echo "$ai_output"
            echo ""
          fi
        fi
{% endif %}
{% if copilot_cli.enabled | default(false) %}
        log "Using Copilot CLI for AI summary"
        # Validate model exists before using
        local cp_model=""
        local cp_desired=""
{% if copilot_cli.model is defined %}
        cp_desired="{{ copilot_cli.model }}"
        log "Configured Copilot model: $cp_desired"
{% else %}
        cp_desired="gpt-4"
        log "Using default model: $cp_desired"
{% endif %}
        # Validate the model exists
        cp_model=$(find_copilot_model "$cp_desired")
        if [ -z "$cp_model" ]; then
          log "Model $cp_desired not found, trying fallbacks..."
          for fallback in "gpt-4" "gpt-4o" "gpt-3.5-turbo"; do
            cp_model=$(find_copilot_model "$fallback")
            if [ -n "$cp_model" ]; then
              log "Using fallback model: $cp_model"
              break
            fi
          done
        fi
        if [ -z "$cp_model" ]; then
          log "No valid Copilot model found, skipping"
        else
          log "Using validated model: $cp_model"
          ai_output=$(HOME="$OPENCODE_HOME" copilot --model "$cp_model" -p "$prompt" -s --allow-all-tools 2>/dev/null)
          ai_status=$?
          if [ -n "$ai_output" ]; then
            if [ $ai_status -eq 0 ]; then
              echo "[Generated by Copilot CLI (model: $cp_model)]"
              echo ""
              echo "$ai_output"
              return 0
            else
              log "Copilot CLI returned output but exit code $ai_status"
              echo "[Copilot CLI (exit $ai_status)]"
              echo ""
              echo "$ai_output"
              echo ""
            fi
          fi
        fi
{% endif %}
{% if not (opencode.enabled | default(false) or claude_code.enabled | default(false) or copilot_cli.enabled | default(false)) %}
        log "No AI CLI configured"
{% endif %}
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
          # Write AI summary to test file if in testing mode
          if [ "$TESTING_MODE" = "true" ]; then
            log "Testing mode: writing AI summary to $TEST_AI_SUMMARY_FILE"
            echo "$ai_summary" > "$TEST_AI_SUMMARY_FILE"
          fi
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
    permissions: '0755'
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
    permissions: '0755'
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
      declare -A pkg_installed pkg_upgraded pkg_removed
      declare -A pkg_snap_upgraded pkg_brew_upgraded pkg_pip_upgraded pkg_npm_upgraded pkg_deno_upgraded

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
          SNAP_UPGRADED)
            pkg_snap_upgraded["$pkg"]="$rest"
            ;;
          BREW_UPGRADED)
            pkg_brew_upgraded["$pkg"]="$rest"
            ;;
          PIP_UPGRADED)
            pkg_pip_upgraded["$pkg"]="$rest"
            ;;
          NPM_UPGRADED)
            pkg_npm_upgraded["$pkg"]="$rest"
            ;;
          DENO_UPGRADED)
            pkg_deno_upgraded["$pkg"]="$rest"
            ;;
        esac
      done < "$QUEUE_FILE"

      # Build deduplicated lists
      NL=$'\n'
      INSTALLED="" UPGRADED="" REMOVED=""
      SNAP_UPGRADED="" BREW_UPGRADED="" PIP_UPGRADED="" NPM_UPGRADED="" DENO_UPGRADED=""

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

      for pkg in "${!pkg_snap_upgraded[@]}"; do
        [ -n "$SNAP_UPGRADED" ] && SNAP_UPGRADED+="$NL"
        IFS=: read -r old new <<< "${pkg_snap_upgraded[$pkg]}"
        SNAP_UPGRADED+="$pkg:$old:$new"
      done

      for pkg in "${!pkg_brew_upgraded[@]}"; do
        [ -n "$BREW_UPGRADED" ] && BREW_UPGRADED+="$NL"
        IFS=: read -r old new <<< "${pkg_brew_upgraded[$pkg]}"
        BREW_UPGRADED+="$pkg:$old:$new"
      done

      for pkg in "${!pkg_pip_upgraded[@]}"; do
        [ -n "$PIP_UPGRADED" ] && PIP_UPGRADED+="$NL"
        IFS=: read -r old new <<< "${pkg_pip_upgraded[$pkg]}"
        PIP_UPGRADED+="$pkg:$old:$new"
      done

      for pkg in "${!pkg_npm_upgraded[@]}"; do
        [ -n "$NPM_UPGRADED" ] && NPM_UPGRADED+="$NL"
        IFS=: read -r old new <<< "${pkg_npm_upgraded[$pkg]}"
        NPM_UPGRADED+="$pkg:$old:$new"
      done

      for pkg in "${!pkg_deno_upgraded[@]}"; do
        [ -n "$DENO_UPGRADED" ] && DENO_UPGRADED+="$NL"
        IFS=: read -r old new <<< "${pkg_deno_upgraded[$pkg]}"
        DENO_UPGRADED+="$pkg:$old:$new"
      done

      # Clear queue
      rm -f "$QUEUE_FILE"

      # Count after dedup
      n_installed=$(echo "${!pkg_installed[@]}" | wc -w)
      n_upgraded=$(echo "${!pkg_upgraded[@]}" | wc -w)
      n_removed=$(echo "${!pkg_removed[@]}" | wc -w)
      n_snap_upgraded=$(echo "${!pkg_snap_upgraded[@]}" | wc -w)
      n_brew_upgraded=$(echo "${!pkg_brew_upgraded[@]}" | wc -w)
      n_pip_upgraded=$(echo "${!pkg_pip_upgraded[@]}" | wc -w)
      n_npm_upgraded=$(echo "${!pkg_npm_upgraded[@]}" | wc -w)
      n_deno_upgraded=$(echo "${!pkg_deno_upgraded[@]}" | wc -w)
      log "apt-notify-flush: after dedup: $n_installed apt installed, $n_upgraded apt upgraded, $n_removed apt removed"
      log "apt-notify-flush: $n_snap_upgraded snap, $n_brew_upgraded brew, $n_pip_upgraded pip, $n_npm_upgraded npm, $n_deno_upgraded deno upgraded"

      # Build and send report if there are changes after dedup
      if [ -n "$INSTALLED" ] || [ -n "$UPGRADED" ] || [ -n "$REMOVED" ] || \
         [ -n "$SNAP_UPGRADED" ] || [ -n "$BREW_UPGRADED" ] || [ -n "$PIP_UPGRADED" ] || [ -n "$NPM_UPGRADED" ] || [ -n "$DENO_UPGRADED" ]; then
        log "apt-notify-flush: building and sending report"
        REPORT=$(build_report "$INSTALLED" "$UPGRADED" "$REMOVED" "$SNAP_UPGRADED" "$BREW_UPGRADED" "$PIP_UPGRADED" "$NPM_UPGRADED" "$DENO_UPGRADED")
        send_notification "$REPORT"
        log "apt-notify-flush: complete"
      else
        log "apt-notify-flush: no changes after dedup, nothing to send"
      fi

  # Snap package update script (called by unattended-upgrades Post-Invoke)
  # Snaps are held from auto-refresh; we refresh them here at unattended-upgrade time
  # Output is appended to apt-notify queue for inclusion in the unified notification
  - path: /usr/local/bin/snap-update
    permissions: '0755'
    content: |
      #!/bin/bash
      # Update snap packages (held from auto-refresh via refresh.hold=forever)
      # Called by unattended-upgrades Post-Invoke hook after apt upgrades
      # Results are written to apt-notify queue for unified email notification

      source /usr/local/lib/apt-notify/common.sh

      log "snap-update: starting"

      if ! command -v snap &>/dev/null; then
        log "snap-update: snap not installed, skipping"
        exit 0
      fi

      # Check for available snap updates
      REFRESH_LIST=$(snap refresh --list 2>/dev/null)

      if [ -z "$REFRESH_LIST" ] || echo "$REFRESH_LIST" | grep -q "All snaps up to date"; then
        log "snap-update: all snaps up to date"
        exit 0
      fi

      # Parse refresh list and capture current versions before upgrade
      # Format: "Name  Version  Rev  Publisher  Notes"
      SNAP_UPDATES=""
      declare -A snap_current_versions

      # Get current versions of snaps that will be updated
      while read -r line; do
        # Skip header line
        [[ "$line" =~ ^Name ]] && continue
        [ -z "$line" ] && continue

        snap_name=$(echo "$line" | awk '{print $1}')
        new_version=$(echo "$line" | awk '{print $2}')

        if [ -n "$snap_name" ]; then
          # Get current installed version
          current_version=$(snap list "$snap_name" 2>/dev/null | tail -1 | awk '{print $2}')
          snap_current_versions["$snap_name"]="$current_version:$new_version"
          log "snap-update: $snap_name will update from $current_version to $new_version"
        fi
      done <<< "$REFRESH_LIST"

      if [ ${{ '{#' }}snap_current_versions[@]} -eq 0 ]; then
        log "snap-update: no snap updates parsed"
        exit 0
      fi

      # Perform the refresh
      log "snap-update: refreshing ${{ '{#' }}snap_current_versions[@]} snaps"
      snap refresh 2>&1 | while read line; do log "snap refresh: $line"; done

      # Build queue entries
      for snap_name in "${!snap_current_versions[@]}"; do
        IFS=: read -r old new <<< "${snap_current_versions[$snap_name]}"
        [ -n "$SNAP_UPDATES" ] && SNAP_UPDATES+=$'\n'
        SNAP_UPDATES+="SNAP_UPGRADED:$snap_name:$old:$new"
      done

      # Append to apt-notify queue for unified notification
      echo "$SNAP_UPDATES" >> "$QUEUE_FILE"
      log "snap-update: queued ${{ '{#' }}snap_current_versions[@]} snap package updates"

      # Schedule flush timer if not already active
      if ! timer_active; then
        log "snap-update: scheduling flush timer"
        schedule_flush_timer
      fi

      log "snap-update: complete"

  # Homebrew package update script (called by unattended-upgrades Post-Invoke)
  # Output is appended to apt-notify queue for inclusion in the unified notification
  - path: /usr/local/bin/brew-update
    permissions: '0755'
    content: |
      #!/bin/bash
      # Update Homebrew packages
      # Called by unattended-upgrades Post-Invoke hook after apt upgrades
      # Results are written to apt-notify queue for unified email notification

      source /usr/local/lib/apt-notify/common.sh

      log "brew-update: starting"

      # Check if brew is installed (Linuxbrew)
      BREW_CMD=""
      if command -v brew &>/dev/null; then
        BREW_CMD="brew"
      elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
        BREW_CMD="/home/linuxbrew/.linuxbrew/bin/brew"
      elif [ -x "$OPENCODE_HOME/.linuxbrew/bin/brew" ]; then
        BREW_CMD="$OPENCODE_HOME/.linuxbrew/bin/brew"
      fi

      if [ -z "$BREW_CMD" ]; then
        log "brew-update: brew not installed, skipping"
        exit 0
      fi

      log "brew-update: using $BREW_CMD"

      # Update brew itself and get outdated packages
      $BREW_CMD update 2>&1 | while read line; do log "brew update: $line"; done

      # Get list of outdated packages (format: package (old) < new)
      OUTDATED=$($BREW_CMD outdated --verbose 2>/dev/null)

      if [ -z "$OUTDATED" ]; then
        log "brew-update: all packages up to date"
        exit 0
      fi

      # Parse outdated packages
      BREW_UPDATES=""
      while IFS= read -r line; do
        # Format: "package (1.0.0) < 1.1.0" or "package (1.0.0) != 1.1.0"
        pkg=$(echo "$line" | awk '{print $1}')
        current=$(echo "$line" | sed -n 's/.*(\([^)]*\)).*/\1/p')
        latest=$(echo "$line" | awk '{print $NF}')
        if [ -n "$pkg" ] && [ -n "$current" ] && [ -n "$latest" ]; then
          [ -n "$BREW_UPDATES" ] && BREW_UPDATES+=$'\n'
          BREW_UPDATES+="BREW_UPGRADED:$pkg:$current:$latest"
        fi
      done <<< "$OUTDATED"

      if [ -z "$BREW_UPDATES" ]; then
        log "brew-update: no brew updates parsed"
        exit 0
      fi

      log "brew-update: upgrading packages"
      $BREW_CMD upgrade 2>&1 | while read line; do log "brew upgrade: $line"; done

      # Append to apt-notify queue for unified notification
      echo "$BREW_UPDATES" >> "$QUEUE_FILE"
      log "brew-update: queued $(echo "$BREW_UPDATES" | wc -l) brew package updates"

      # Schedule flush timer if not already active
      if ! timer_active; then
        log "brew-update: scheduling flush timer"
        schedule_flush_timer
      fi

      log "brew-update: complete"

  # pip global package update script (called by unattended-upgrades Post-Invoke)
  # Output is appended to apt-notify queue for inclusion in the unified notification
  - path: /usr/local/bin/pip-global-update
    permissions: '0755'
    content: |
      #!/bin/bash
      # Update pip and globally installed Python packages
      # Called by unattended-upgrades Post-Invoke hook after apt upgrades
      # Results are written to apt-notify queue for unified email notification

      source /usr/local/lib/apt-notify/common.sh

      log "pip-global-update: starting"

      # Find pip command (prefer pip3)
      PIP_CMD=""
      if command -v pip3 &>/dev/null; then
        PIP_CMD="pip3"
      elif command -v pip &>/dev/null; then
        PIP_CMD="pip"
      fi

      if [ -z "$PIP_CMD" ]; then
        log "pip-global-update: pip not installed, skipping"
        exit 0
      fi

      log "pip-global-update: using $PIP_CMD"

      # Get list of outdated packages (JSON format)
      OUTDATED=$($PIP_CMD list --outdated --format=json 2>/dev/null || echo "[]")

      if [ "$OUTDATED" = "[]" ] || [ -z "$OUTDATED" ]; then
        log "pip-global-update: all packages up to date"
        exit 0
      fi

      # Parse outdated packages
      PIP_UPDATES=""
      while IFS= read -r line; do
        pkg=$(echo "$line" | jq -r '.name')
        current=$(echo "$line" | jq -r '.version')
        latest=$(echo "$line" | jq -r '.latest_version')
        if [ -n "$pkg" ] && [ "$pkg" != "null" ]; then
          [ -n "$PIP_UPDATES" ] && PIP_UPDATES+=$'\n'
          PIP_UPDATES+="PIP_UPGRADED:$pkg:$current:$latest"
        fi
      done < <(echo "$OUTDATED" | jq -c '.[]' 2>/dev/null)

      if [ -z "$PIP_UPDATES" ]; then
        log "pip-global-update: no pip updates parsed"
        exit 0
      fi

      # Upgrade pip itself first
      log "pip-global-update: upgrading pip"
      $PIP_CMD install --upgrade pip 2>&1 | while read line; do log "pip: $line"; done

      # Upgrade outdated packages
      log "pip-global-update: upgrading packages"
      while IFS=: read -r action pkg current latest; do
        log "pip-global-update: upgrading $pkg from $current to $latest"
        $PIP_CMD install --upgrade "$pkg" 2>&1 | while read line; do log "pip: $line"; done
      done <<< "$PIP_UPDATES"

      # Append to apt-notify queue for unified notification
      echo "$PIP_UPDATES" >> "$QUEUE_FILE"
      log "pip-global-update: queued $(echo "$PIP_UPDATES" | wc -l) pip package updates"

      # Schedule flush timer if not already active
      if ! timer_active; then
        log "pip-global-update: scheduling flush timer"
        schedule_flush_timer
      fi

      log "pip-global-update: complete"

  # npm global package update script (called by unattended-upgrades Post-Invoke)
  # Output is appended to apt-notify queue for inclusion in the unified notification
  - path: /usr/local/bin/npm-global-update
    permissions: '0755'
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

  # Deno package update script (called by unattended-upgrades Post-Invoke)
  # Output is appended to apt-notify queue for inclusion in the unified notification
  - path: /usr/local/bin/deno-update
    permissions: '0755'
    content: |
      #!/bin/bash
      # Update Deno and installed Deno packages
      # Called by unattended-upgrades Post-Invoke hook after apt upgrades
      # Results are written to apt-notify queue for unified email notification

      source /usr/local/lib/apt-notify/common.sh

      log "deno-update: starting"

      # Check if deno is installed
      DENO_CMD=""
      if command -v deno &>/dev/null; then
        DENO_CMD="deno"
      elif [ -x "$OPENCODE_HOME/.deno/bin/deno" ]; then
        DENO_CMD="$OPENCODE_HOME/.deno/bin/deno"
        export DENO_INSTALL="$OPENCODE_HOME/.deno"
      fi

      if [ -z "$DENO_CMD" ]; then
        log "deno-update: deno not installed, skipping"
        exit 0
      fi

      log "deno-update: using $DENO_CMD"

      # Get current deno version
      CURRENT_VERSION=$($DENO_CMD --version 2>/dev/null | head -1 | awk '{print $2}')

      # Check for deno upgrade
      UPGRADE_INFO=$($DENO_CMD upgrade --dry-run 2>&1 || echo "")
      DENO_UPDATES=""

      if echo "$UPGRADE_INFO" | grep -q "Found latest version"; then
        log "deno-update: deno is up to date"
      elif echo "$UPGRADE_INFO" | grep -q "New version available"; then
        NEW_VERSION=$(echo "$UPGRADE_INFO" | grep -oP 'version \K[0-9.]+' | head -1)
        if [ -n "$NEW_VERSION" ] && [ "$NEW_VERSION" != "$CURRENT_VERSION" ]; then
          log "deno-update: upgrading deno from $CURRENT_VERSION to $NEW_VERSION"
          $DENO_CMD upgrade 2>&1 | while read line; do log "deno upgrade: $line"; done
          DENO_UPDATES="DENO_UPGRADED:deno:$CURRENT_VERSION:$NEW_VERSION"
        fi
      fi

      # Check for outdated cached dependencies (deno doesn't have a global install like npm)
      # Deno caches dependencies per-project, so we only track deno itself
      # Future: could scan for deno.json files and check their dependencies

      if [ -z "$DENO_UPDATES" ]; then
        log "deno-update: no deno updates"
        exit 0
      fi

      # Append to apt-notify queue for unified notification
      echo "$DENO_UPDATES" >> "$QUEUE_FILE"
      log "deno-update: queued deno update"

      # Schedule flush timer if not already active
      if ! timer_active; then
        log "deno-update: scheduling flush timer"
        schedule_flush_timer
      fi

      log "deno-update: complete"

  # Systemd service to update non-apt package managers
  - path: /etc/systemd/system/pkg-managers-update.service
    permissions: '0644'
    content: |
      [Unit]
      Description=Update non-apt package managers (snap, brew, pip, npm, deno)
      After=network-online.target
      Wants=network-online.target

      [Service]
      Type=oneshot
      ExecStart=/usr/local/bin/snap-update
      ExecStart=/usr/local/bin/brew-update
      ExecStart=/usr/local/bin/pip-global-update
      ExecStart=/usr/local/bin/npm-global-update
      ExecStart=/usr/local/bin/deno-update

  # Systemd timer for daily package manager updates
  - path: /etc/systemd/system/pkg-managers-update.timer
    permissions: '0644'
    content: |
      [Unit]
      Description=Daily update of non-apt package managers

      [Timer]
      OnCalendar=daily
      RandomizedDelaySec=1h
      Persistent=true

      [Install]
      WantedBy=timers.target
