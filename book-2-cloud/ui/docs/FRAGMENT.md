# 6.15 UI Touches Fragment

**Template:** `book-2-cloud/ui/fragment.yaml.tpl`

Configures terminal experience, dynamic MOTD, and CLI productivity tools.

## Template

```yaml
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

  # Fastfetch on interactive login (optional)
  - path: /etc/profile.d/fastfetch.sh
    permissions: '0644'
    content: |
      # Run fastfetch on interactive login
      # Uncomment to enable:
      # if [ -t 0 ] && command -v fastfetch &> /dev/null; then
      #   fastfetch
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
```

## Dynamic MOTD

Ubuntu uses `/etc/update-motd.d/` scripts to generate the MOTD dynamically on each login. Scripts are executed in alphabetical order.

### MOTD Components

| Script | Content |
|--------|---------|
| `00-header` | System hostname banner |
| `10-sysinfo` | Uptime, load, memory, disk usage |
| `20-vms` | Running/total VM count |
| `30-ssh-config` | Copyable SSH config for Cockpit tunnel |
| `90-updates` | Pending updates, reboot required |

### Disabled Ubuntu Defaults

These default Ubuntu MOTD scripts are disabled:

| Script | Reason |
|--------|--------|
| `10-help-text` | Generic Ubuntu help links |
| `50-motd-news` | Canonical news/ads |
| `88-esm-announce` | Ubuntu Pro advertising |
| `91-contract-ua-esm-status` | Ubuntu Pro status |

### Example Output

```
  Ubuntu Infrastructure Host
  kvm-host.local

  Uptime:      3 days, 4 hours
  Load:        0.15 0.10 0.05
  Memory:      4.2G / 16G (26%)
  Disk:        45G / 200G (23%)

  VMs:         2 running / 5 total

  Cockpit: https://localhost (via SSH tunnel)

  Add to ~/.ssh/config:
  ----------------------------------------
  Host kvm-host
      HostName 192.168.1.100
      User admin
      LocalForward 443 localhost:443
  ----------------------------------------

  Updates: 12 packages (3 security)
```

---

## CLI Productivity Tools

| Package | Command | Purpose |
|---------|---------|---------|
| `bat` | `batcat` / `cat` | Syntax-highlighted file viewer |
| `fd-find` | `fdfind` / `fd` | Fast, user-friendly `find` alternative |
| `jq` | `jq` | JSON processor |
| `tree` | `tree` | Directory tree visualization |
| `htop` | `htop` | Interactive process viewer |
| `ncdu` | `ncdu` | NCurses disk usage analyzer |
| `fastfetch` | `fastfetch` | System info display |

### Shell Aliases

Aliases are defined in `/etc/profile.d/aliases.sh`:

```bash
# Modern tools
alias cat='batcat --paging=never'   # bat replaces cat
alias fd='fdfind'                    # Debian naming quirk

# Virtualization
alias vms='virsh list --all'
alias vmstart='virsh start'
alias vmstop='virsh shutdown'
```

---

## Final Message

The `final_message` is logged at the end of cloud-init:

```
Cloud-init complete!

Cockpit access via SSH tunnel:
  ssh -L 443:localhost:443 admin@192.168.1.100
  Then open: https://localhost

System ready for use.
```

This appears in `/var/log/cloud-init-output.log` and console output.

---

## Suggested Enhancements

Consider these additional improvements:

### Terminal Experience

| Enhancement | Package/Config | Purpose |
|-------------|----------------|---------|
| `ripgrep` | `ripgrep` | Faster grep with better defaults |
| `fzf` | `fzf` | Fuzzy finder for files and history |
| `tldr` | `tldr` | Simplified man pages |
| `eza` | snap | Modern `ls` replacement with git integration |
| `zoxide` | `zoxide` | Smarter `cd` that learns your habits |

### Shell Improvements

| Enhancement | Config | Purpose |
|-------------|--------|---------|
| Starship prompt | Install script | Cross-shell customizable prompt |
| bash-completion | `bash-completion` | Tab completion for commands |
| History tweaks | `.bashrc` | Larger history, ignore duplicates |

### Monitoring

| Enhancement | Package | Purpose |
|-------------|---------|---------|
| `btop` | snap | Modern resource monitor (replaces htop) |
| `duf` | `duf` | Modern `df` replacement |
| `gdu` | snap | Fast disk usage analyzer |

### Security

| Enhancement | Package | Purpose |
|-------------|---------|---------|
| Login notifications | PAM + msmtp | Email on SSH login |
| Session recording | `asciinema` | Record terminal sessions |

### Example: FZF Integration

```yaml
packages:
  - fzf

write_files:
  - path: /etc/profile.d/fzf.sh
    permissions: '0644'
    content: |
      # FZF key bindings and completion
      if [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
        source /usr/share/doc/fzf/examples/key-bindings.bash
      fi
      # Ctrl+R: fuzzy history search
      # Ctrl+T: fuzzy file search
      # Alt+C: fuzzy cd
```

### Example: Login Notifications

```yaml
write_files:
  - path: /etc/pam.d/sshd-notify
    permissions: '0644'
    content: |
      session optional pam_exec.so /usr/local/bin/login-notify

  - path: /usr/local/bin/login-notify
    permissions: '0755'
    content: |
      #!/bin/bash
      RECIPIENT=$(grep "^root:" /etc/aliases | cut -d: -f2 | tr -d ' ')
      if [ -n "$RECIPIENT" ] && [ -f /etc/msmtp-password ]; then
        SUBJECT="[$(hostname)] SSH Login: ${PAM_USER} from ${PAM_RHOST}"
        BODY="User: ${PAM_USER}\nFrom: ${PAM_RHOST}\nTime: $(date)"
        echo -e "Subject: ${SUBJECT}\n\n${BODY}" | msmtp "$RECIPIENT" 2>/dev/null
      fi
```

---

## Fragment Ordering

This fragment uses the `90-` prefix to ensure it runs last:

- All services are configured
- Network is available
- Dynamic MOTD has correct information
