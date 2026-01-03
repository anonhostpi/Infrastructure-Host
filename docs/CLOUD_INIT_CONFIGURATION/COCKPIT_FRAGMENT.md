# 6.11 Cockpit Fragment

**Template:** `src/autoinstall/cloud-init/70-cockpit.yaml.tpl`

Configures Cockpit web-based management console with localhost-only access via SSH tunneling.

## Template

```yaml
packages:
  - cockpit
  - cockpit-machines

write_files:
  - path: /etc/cockpit/cockpit.conf
    permissions: '0644'
    content: |
      [WebService]
      AllowUnencrypted = false

  - path: /etc/systemd/system/cockpit.socket.d/listen.conf
    permissions: '0644'
    content: |
      [Socket]
      ListenStream=
      ListenStream=127.0.0.1:443

runcmd:
  - systemctl daemon-reload
  - systemctl enable cockpit.socket
  - systemctl start cockpit.socket
```

## Packages

| Package | Purpose |
|---------|---------|
| `cockpit` | Core Cockpit web console |
| `cockpit-machines` | VM management integration |

## Configuration

### Web Service

The `/etc/cockpit/cockpit.conf` file configures the web service:

| Setting | Value | Purpose |
|---------|-------|---------|
| `AllowUnencrypted` | false | Require HTTPS |

### Socket Override

The systemd drop-in `/etc/systemd/system/cockpit.socket.d/listen.conf` binds Cockpit to localhost only:

```ini
[Socket]
ListenStream=
ListenStream=127.0.0.1:443
```

- First `ListenStream=` clears the default (0.0.0.0:9090)
- Second `ListenStream=127.0.0.1:443` binds to localhost port 443

This ensures Cockpit is **not accessible from the network** - only via SSH tunnel.

## Access via SSH Tunnel

Since Cockpit only listens on localhost, access requires SSH local port forwarding:

```bash
# From your workstation
ssh -L 443:localhost:443 user@kvm-host
```

Then open in browser:

```
https://localhost
```

Login with the admin credentials from `identity.config.yaml`.

### SSH Config Snippet

The system MOTD (see [6.12 UI Touches](./UI_TOUCHES_FRAGMENT.md)) displays an SSH config snippet on login that you can copy to your workstation's `~/.ssh/config`:

```
Host kvm-host
    HostName 192.168.1.100
    User admin
    LocalForward 443 localhost:443
```

Then simply `ssh kvm-host` and access `https://localhost`.

This snippet is dynamically generated with the correct IP address and username from the deployment configuration.

## Security Benefits

| Benefit | Description |
|---------|-------------|
| No network exposure | Cockpit not reachable from network |
| SSH authentication | Only SSH-authorized users can access |
| Double encryption | SSH tunnel + HTTPS |
| No firewall rules | No ports to open for Cockpit |
| No reverse proxy | No additional services to maintain |
| No certificate management | Self-signed cert is fine for localhost |

## cockpit-machines

The `cockpit-machines` package integrates with libvirt to provide:

- VM creation and management
- Console access
- Storage and network configuration

This complements the CLI tools from [6.10 Virtualization Fragment](./VIRTUALIZATION_FRAGMENT.md).

## HTTPS Certificate

Cockpit generates a self-signed certificate on first access. Since access is via localhost through an SSH tunnel, the self-signed certificate is acceptable - the connection is already authenticated and encrypted by SSH.

Browser warnings for `localhost` can be safely bypassed in this configuration.

## Verification

After deployment and SSH tunnel setup:

```bash
# On the host - verify socket is listening on localhost only
ss -tlnp | grep 443
# Expected: 127.0.0.1:443

# From workstation with tunnel active
curl -k https://localhost
# Should return Cockpit HTML
```
