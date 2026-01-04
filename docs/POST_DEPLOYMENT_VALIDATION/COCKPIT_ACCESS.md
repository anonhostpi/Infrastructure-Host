# 9.3 Cockpit Access and Configuration

## Security Model

Cockpit binds to **localhost only** (127.0.0.1:443) for security. Access is via SSH tunnel, which:
- Requires SSH authentication before accessing Cockpit
- Eliminates need for firewall port exposure
- Encrypts all traffic through existing SSH connection

## Accessing Cockpit

### Step 1: Create SSH Tunnel

```bash
# From your workstation
ssh -L 9090:127.0.0.1:443 admin@<host-ip>
```

This forwards local port 9090 to the server's localhost:443.

### Step 2: Open Browser

Navigate to: `https://localhost:9090`

Accept the self-signed certificate warning and login with admin credentials.

### Persistent Tunnel (SSH Config)

Add to `~/.ssh/config`:

```
Host infra-host
    HostName <host-ip>
    User admin
    LocalForward 9090 127.0.0.1:443
```

Then connect with:
```bash
ssh infra-host
# Cockpit available at https://localhost:9090
```

## Cockpit Features

- **Overview** - System resources, performance graphs
- **Machines** - Virtual machine management (create, start, stop VMs)
- **Networking** - Network interface configuration
- **Storage** - Disk and filesystem management
- **Services** - Systemd service management
- **Terminal** - Web-based terminal access

## Verification

```bash
# Verify Cockpit is running
systemctl status cockpit.socket

# Verify listening on localhost only
ss -tlnp | grep 443
# Expected: 127.0.0.1:443

# Verify NOT listening on public interface
# (this should return nothing)
ss -tlnp | grep 443 | grep -v 127.0.0.1
```

## Troubleshooting

```bash
# Check service status
systemctl status cockpit.socket

# View logs
journalctl -u cockpit

# Restart service
sudo systemctl restart cockpit.socket

# Verify socket override is applied
cat /etc/systemd/system/cockpit.socket.d/listen.conf
```

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Connection refused on tunnel | Cockpit not running | `sudo systemctl start cockpit.socket` |
| Certificate warning | Self-signed cert | Accept warning or configure custom cert |
| Can't access https://host-ip | Correct behavior | Cockpit is localhost only; use SSH tunnel |
