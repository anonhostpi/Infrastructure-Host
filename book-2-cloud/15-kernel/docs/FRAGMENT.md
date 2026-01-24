# 6.2 Kernel Hardening Fragment

**Template:** `src/autoinstall/cloud-init/15-kernel.yaml.tpl`

Configures kernel security parameters via sysctl.

## Template

```yaml
write_files:
  - path: /etc/sysctl.d/99-security.conf
    permissions: '0644'
    content: |
      # Reverse path filtering (prevents IP spoofing)
      net.ipv4.conf.all.rp_filter = 1
      net.ipv4.conf.default.rp_filter = 1

      # Disable source routing
      net.ipv4.conf.all.accept_source_route = 0
      net.ipv4.conf.default.accept_source_route = 0
      net.ipv6.conf.all.accept_source_route = 0
      net.ipv6.conf.default.accept_source_route = 0

      # Disable ICMP redirects
      net.ipv4.conf.all.accept_redirects = 0
      net.ipv4.conf.default.accept_redirects = 0
      net.ipv6.conf.all.accept_redirects = 0
      net.ipv6.conf.default.accept_redirects = 0
      net.ipv4.conf.all.send_redirects = 0
      net.ipv4.conf.default.send_redirects = 0

      # SYN flood protection
      net.ipv4.tcp_syncookies = 1

      # Log martian packets (suspicious sources)
      net.ipv4.conf.all.log_martians = 1
      net.ipv4.conf.default.log_martians = 1

      # Ignore ICMP echo broadcasts (ping amplification)
      net.ipv4.icmp_echo_ignore_broadcasts = 1

      # Ignore bogus ICMP error responses
      net.ipv4.icmp_ignore_bogus_error_responses = 1

      # Restrict kernel debug messages
      kernel.dmesg_restrict = 1

      # Hide kernel pointers (KASLR support)
      kernel.kptr_restrict = 2

runcmd:
  - sysctl --system
```

## Security Parameters

### Network Hardening

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `rp_filter` | 1 | Reverse path filtering - prevents IP spoofing |
| `accept_source_route` | 0 | Disable source routing - prevents routing manipulation |
| `accept_redirects` | 0 | Ignore ICMP redirects - prevents route hijacking |
| `send_redirects` | 0 | Don't send ICMP redirects |
| `tcp_syncookies` | 1 | SYN flood protection |
| `log_martians` | 1 | Log packets with suspicious source addresses |
| `icmp_echo_ignore_broadcasts` | 1 | Prevent ping amplification attacks |
| `icmp_ignore_bogus_error_responses` | 1 | Ignore malformed ICMP errors |

### Kernel Hardening

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `dmesg_restrict` | 1 | Restrict kernel log access to root |
| `kptr_restrict` | 2 | Hide kernel pointers (KASLR support) |

## Why Early?

This fragment uses the `15-` prefix to ensure kernel hardening is applied early:

1. **Before network configuration** - Hardening in place before network is fully configured
2. **Before services start** - Protection active before SSH, Cockpit, etc.
3. **Foundational security** - Forms the base layer for all other security measures

## Applying Changes

The `sysctl --system` command in `runcmd` loads all configuration from:
- `/etc/sysctl.d/*.conf`
- `/usr/lib/sysctl.d/*.conf`
- `/lib/sysctl.d/*.conf`

## Verification

After deployment, verify settings are applied:

```bash
# Check all security settings
sysctl -a | grep -E "(rp_filter|accept_source_route|accept_redirects|syncookies|martians|dmesg_restrict|kptr_restrict)"

# Check specific setting
sysctl net.ipv4.conf.all.rp_filter
```

## KVM Host Considerations

These settings are safe for KVM hosts:

- **Bridge networking** - `rp_filter` may need adjustment if using complex bridge setups
- **VM traffic** - Settings apply to host, not VMs (VMs have their own kernel)

If using bridged networking with VMs that need asymmetric routing:

```conf
# Loosen rp_filter for bridge interface only
net.ipv4.conf.virbr0.rp_filter = 0
```

## Future Considerations

Additional hardening that could be added:

```conf
# Disable IPv6 if not needed
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1

# Restrict ptrace (process tracing)
kernel.yama.ptrace_scope = 2

# Restrict unprivileged user namespaces
kernel.unprivileged_userns_clone = 0
```

**Note:** Test these carefully as they may affect virtualization.
