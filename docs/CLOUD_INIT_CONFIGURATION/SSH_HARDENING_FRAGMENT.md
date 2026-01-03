# 6.3 SSH Hardening Fragment

**Template:** `src/autoinstall/cloud-init/25-ssh.yaml.tpl`

Hardens SSH server configuration.

## Template

```yaml
write_files:
  - path: /etc/ssh/sshd_config.d/99-hardening.conf
    permissions: '0644'
    content: |
      # SSH Hardening - managed by cloud-init
      MaxAuthTries 3
      X11Forwarding no
      AllowTcpForwarding no
      PermitEmptyPasswords no
      ClientAliveInterval 300
      ClientAliveCountMax 2
```

## Hardening Options

| Setting | Value | Purpose |
|---------|-------|---------|
| `MaxAuthTries` | 3 | Limit authentication attempts |
| `X11Forwarding` | no | Disable X11 forwarding |
| `AllowTcpForwarding` | no | Disable TCP forwarding |
| `PermitEmptyPasswords` | no | Require passwords |
| `ClientAliveInterval` | 300 | Timeout inactive sessions (5 min) |
| `ClientAliveCountMax` | 2 | Disconnect after 2 missed keepalives |

## Password vs Key Authentication

This fragment does **not** disable password authentication by default because:

1. Initial setup may require password access
2. SSH keys are optional in `identity.config.yaml`
3. Console access may not be available

To disable password authentication after adding SSH keys:

```yaml
write_files:
  - path: /etc/ssh/sshd_config.d/99-hardening.conf
    permissions: '0644'
    content: |
      PasswordAuthentication no
      # ... other settings
```

## Drop-in Configuration

The `/etc/ssh/sshd_config.d/` directory is for drop-in configuration files. Files are processed in alphabetical order, with later files overriding earlier ones.

The `99-` prefix ensures this file is processed last, giving it final authority over SSH settings.

## Future Considerations

- **fail2ban integration** - See [6.7 Security Monitoring](./SECURITY_MONITORING_FRAGMENT.md)
- **SSH key rotation** - Manual process post-deployment
- **Certificate-based auth** - For enterprise environments
