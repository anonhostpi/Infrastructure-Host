# 6.11 Cockpit Fragment

**Template:** `src/autoinstall/cloud-init/70-cockpit.yaml.tpl`

Configures Cockpit web-based management console with localhost-only access via SSH tunneling.

## Configuration

Create `src/config/cockpit.config.yaml`:

```yaml
cockpit:
  # Set to false to completely disable Cockpit installation
  enabled: true

  # Listen address - 127.0.0.1 for localhost-only (SSH tunnel access)
  listen_address: 127.0.0.1

  # Listen port (443 allows https://localhost without port suffix)
  listen_port: 443

  # Cockpit packages to install
  packages:
    - cockpit
    - cockpit-machines

  # Require HTTPS (should always be true)
  require_https: true

  # Session idle timeout in minutes (0 = no timeout)
  idle_timeout: 15
```

| Field | Default | Description |
|-------|---------|-------------|
| `enabled` | `true` | Set to `false` to omit Cockpit from build entirely |
| `listen_address` | `127.0.0.1` | Bind address (`0.0.0.0` for network access) |
| `listen_port` | `443` | Listen port |
| `packages` | `[cockpit, cockpit-machines]` | Packages to install |
| `require_https` | `true` | Require HTTPS connections |
| `idle_timeout` | `0` | Session timeout in minutes (0 = disabled) |
| `origins` | `[]` | Additional allowed origins for cross-origin access |

## Template

```yaml
{% if cockpit.enabled | default(true) %}
packages:
{% for pkg in cockpit.packages | default(['cockpit', 'cockpit-machines']) %}
  - {{ pkg }}
{% endfor %}

write_files:
  - path: /etc/cockpit/cockpit.conf
    permissions: '0644'
    content: |
      [WebService]
      AllowUnencrypted = {{ 'true' if not cockpit.require_https | default(true) else 'false' }}
{% if cockpit.idle_timeout | default(0) > 0 %}
      IdleTimeout = {{ cockpit.idle_timeout }}
{% endif %}
{% if cockpit.origins is defined and cockpit.origins %}
      Origins = {{ cockpit.origins | join(' ') }}
{% endif %}

  - path: /etc/systemd/system/cockpit.socket.d/listen.conf
    permissions: '0644'
    content: |
      [Socket]
      ListenStream=
      ListenStream={{ cockpit.listen_address | default('127.0.0.1') }}:{{ cockpit.listen_port | default(443) }}

runcmd:
  - systemctl daemon-reload
  - systemctl enable cockpit.socket
  - systemctl start cockpit.socket
{% endif %}
```

## Disabling Cockpit

To completely omit Cockpit from the build:

```yaml
cockpit:
  enabled: false
```

The fragment produces no output when disabled.

## Packages

| Package | Purpose |
|---------|---------|
| `cockpit` | Core Cockpit web console |
| `cockpit-machines` | VM management integration |

Additional packages can be added:
- `cockpit-storaged` - Storage management
- `cockpit-networkmanager` - Network configuration
- `cockpit-podman` - Container management

## Socket Configuration

The systemd drop-in binds Cockpit to the configured address:

```ini
[Socket]
ListenStream=
ListenStream=127.0.0.1:443
```

- First `ListenStream=` clears the default (0.0.0.0:9090)
- Second `ListenStream=` binds to configured address/port

Default configuration ensures Cockpit is **not accessible from the network** - only via SSH tunnel.

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

Login with the admin credentials from `src/config/identity.config.yaml`.

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
