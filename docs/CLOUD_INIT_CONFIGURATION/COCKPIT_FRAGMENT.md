# 6.9 Cockpit Fragment

**Template:** `src/autoinstall/cloud-init/70-cockpit.yaml.tpl`

Configures Cockpit web-based management console.

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

runcmd:
  # Enable and start Cockpit
  - systemctl enable cockpit.socket
  - systemctl start cockpit.socket
  # Open firewall
  - ufw allow 9090/tcp
```

## Packages

| Package | Purpose |
|---------|---------|
| `cockpit` | Core Cockpit web console |
| `cockpit-machines` | VM management integration |

## Configuration

The `/etc/cockpit/cockpit.conf` file configures the web service:

| Setting | Value | Purpose |
|---------|-------|---------|
| `AllowUnencrypted` | false | Require HTTPS |

## Service

Cockpit uses socket activation:

```bash
systemctl enable cockpit.socket
systemctl start cockpit.socket
```

The service only starts when a connection is received on port 9090.

## Firewall

This fragment adds its own UFW rule:

```bash
ufw allow 9090/tcp
```

This works with the base UFW policy from [6.4 UFW Fragment](./UFW_FRAGMENT.md).

## Access

After deployment, access Cockpit at:

```
https://<HOST_IP>:9090
```

Login with the admin credentials from `identity.config.yaml`.

## cockpit-machines

The `cockpit-machines` package integrates with libvirt to provide:

- VM creation and management
- Console access
- Storage and network configuration

This complements the CLI tools from [6.8 Virtualization Fragment](./VIRTUALIZATION_FRAGMENT.md).

## HTTPS Certificate

Cockpit generates a self-signed certificate on first access. For production, consider:

- Let's Encrypt certificate
- Custom CA-signed certificate

Place certificates at:
- `/etc/cockpit/ws-certs.d/<name>.cert`
- `/etc/cockpit/ws-certs.d/<name>.key`
