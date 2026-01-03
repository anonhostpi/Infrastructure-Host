# 6.4 SSH Hardening Fragment

**Template:** `src/autoinstall/cloud-init/25-ssh.yaml.tpl`

Hardens SSH server configuration.

## Template

```yaml
write_files:
  - path: /etc/ssh/sshd_config.d/99-hardening.conf
    permissions: '0644'
    content: |
      # SSH Hardening - managed by cloud-init

      # Authentication
      MaxAuthTries 3
      LoginGraceTime 20
      PermitEmptyPasswords no
      ChallengeResponseAuthentication no

      # Forwarding
      X11Forwarding no
      AllowTcpForwarding no

      # Session timeout
      ClientAliveInterval 300
      ClientAliveCountMax 2

      # Root access
      PermitRootLogin prohibit-password
```

## Hardening Options

| Setting | Value | Purpose |
|---------|-------|---------|
| `MaxAuthTries` | 3 | Limit authentication attempts |
| `LoginGraceTime` | 20 | Seconds to authenticate before disconnect |
| `PermitEmptyPasswords` | no | Require passwords |
| `ChallengeResponseAuthentication` | no | Disable keyboard-interactive auth |
| `X11Forwarding` | no | Disable X11 forwarding |
| `AllowTcpForwarding` | no | Disable TCP forwarding |
| `ClientAliveInterval` | 300 | Timeout inactive sessions (5 min) |
| `ClientAliveCountMax` | 2 | Disconnect after 2 missed keepalives |
| `PermitRootLogin` | prohibit-password | Allow root only with key auth |

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

- **fail2ban integration** - See [6.8 Security Monitoring](./SECURITY_MONITORING_FRAGMENT.md)
- **SSH key rotation** - Manual process post-deployment
- **Certificate-based auth** - For enterprise environments
