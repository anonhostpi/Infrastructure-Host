# 8.3 Cockpit Access and Configuration

## Accessing Cockpit

1. Open web browser
2. Navigate to: `https://<host-ip>:9090`
3. Accept self-signed certificate (or configure proper TLS)
4. Login with `admin` user and password

## Cockpit Features Available

- **Overview** - System resources, performance graphs
- **Machines** - Virtual machine management (create, start, stop VMs)
- **Podman** - Container management
- **Networking** - Network interface configuration, firewall rules
- **Storage** - Disk and filesystem management
- **Services** - Systemd service management
- **Terminal** - Web-based terminal access

## Configure TLS Certificate (Optional)

### Self-Signed Certificate

```bash
# Generate self-signed certificate (or use Let's Encrypt)
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/cockpit/ws-certs.d/cockpit.key \
  -out /etc/cockpit/ws-certs.d/cockpit.cert

# Combine into single file
sudo cat /etc/cockpit/ws-certs.d/cockpit.cert \
  /etc/cockpit/ws-certs.d/cockpit.key | \
  sudo tee /etc/cockpit/ws-certs.d/0-self-signed.cert

# Restart cockpit
sudo systemctl restart cockpit.socket
```

### Let's Encrypt Certificate

```bash
# Install certbot
sudo apt install certbot

# Obtain certificate
sudo certbot certonly --standalone -d server.example.com

# Link certificates
sudo ln -s /etc/letsencrypt/live/server.example.com/fullchain.pem \
  /etc/cockpit/ws-certs.d/server.cert
sudo ln -s /etc/letsencrypt/live/server.example.com/privkey.pem \
  /etc/cockpit/ws-certs.d/server.key

# Restart cockpit
sudo systemctl restart cockpit.socket
```

## Cockpit Configuration

Edit `/etc/cockpit/cockpit.conf`:

```ini
[WebService]
AllowUnencrypted = false
UrlRoot = /cockpit

[Session]
IdleTimeout = 15
```

## Troubleshooting Cockpit

```bash
# Check service status
systemctl status cockpit.socket

# Check listening port
ss -tlnp | grep 9090

# Check firewall
ufw status | grep 9090

# View logs
journalctl -u cockpit
```
