# 6.12 UI Touches Fragment

**Template:** `src/autoinstall/cloud-init/90-ui.yaml.tpl`

Configures user-facing messages and terminal experience.

## Template

```yaml
write_files:
  - path: /etc/motd
    permissions: '0644'
    content: |
      ========================================
        Ubuntu Infrastructure Host
        Managed by cloud-init
      ========================================

final_message: |
  Cloud-init complete!

  Cockpit access via SSH tunnel:
    ssh -L 443:localhost:443 {{ identity.username }}@{{ network.ip_address | ip_only }}
    Then open: https://localhost

  System ready for use.
```

## Message of the Day (motd)

The `/etc/motd` file is displayed after login:

```
========================================
  Ubuntu Infrastructure Host
  Managed by cloud-init
========================================
```

This provides immediate context about the system's purpose.

## Final Message

The `final_message` is logged and displayed at the end of cloud-init:

```
Cloud-init complete!

Cockpit access via SSH tunnel:
  ssh -L 443:localhost:443 admin@192.168.1.100
  Then open: https://localhost

System ready for use.
```

This message appears in:
- `/var/log/cloud-init-output.log`
- Console output (if watching)

## Dynamic Content

The final message uses template variables for the SSH command:

```jinja
ssh -L 443:localhost:443 {{ identity.username }}@{{ network.ip_address | ip_only }}
```

- `identity.username` - Admin username from config
- `ip_only` filter extracts IP from CIDR notation (e.g., `192.168.1.100/24` → `192.168.1.100`)

## Future: Terminal Improvements

Consider adding:

```yaml
packages:
  - neofetch
  - bat
  - fd-find

write_files:
  - path: /etc/profile.d/custom-prompt.sh
    permissions: '0644'
    content: |
      # Custom bash prompt
      PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '
```

These are optional enhancements for terminal experience:

| Tool | Purpose |
|------|---------|
| `neofetch` | System info display |
| `bat` | Syntax-highlighted `cat` |
| `fd-find` | Fast file finder |

## Fragment Ordering

This fragment uses the `90-` prefix to ensure it runs last:

- All services are configured
- Network is available
- Final message has correct information
