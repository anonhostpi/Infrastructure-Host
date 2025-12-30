# 5.2 Variables and Templating

Configuration uses two approaches at build time:
1. **YAML composition** - Network scripts are composed by prefixing shell env vars to shell scripts
2. **Placeholder substitution** - Identity and hostname values are replaced in templates

## Configuration Files

| File | Purpose |
|------|---------|
| `network.config.yaml` | Network settings (hostname, IPs, DNS) |
| `identity.config.yaml` | Credentials (username, password, SSH keys) |

These files are gitignored - create them from the `.example` templates.

## Build Scripts

The build chain composes the final `user-data`:

| Script | Chapter | Purpose |
|--------|---------|---------|
| `build_network.py` | 3.3 | Generates network env vars from `network.config.yaml` |
| `build_cloud_init.py` | 5.1 | Composes `bootcmd` with network detection script |
| `build_autoinstall.py` | 4.2 | Composes `early-commands`, embeds cloud-init |

## Network Variables (YAML Composition)

Network values are generated as shell environment variables by `build_network.py`:

```python
from build_network import load_network_config, generate_net_env

net_config = load_network_config()
net_setup_env = generate_net_env(net_config)
# Returns:
# GATEWAY="..."
# DNS_PRIMARY="..."
# DNS_SECONDARY="..."
# DNS_TERTIARY="..."
# DNS_SEARCH="..."
# STATIC_IP="..."
# CIDR="..."
```

These are prefixed to shell scripts (`early-net.sh`, `net-setup.sh`) to create composed scripts for `early-commands` and `bootcmd`.

## Placeholders (String Substitution)

These placeholders in templates are replaced with actual values:

### From network.config.yaml

| Placeholder | Description |
|-------------|-------------|
| `<HOSTNAME>` | System hostname |
| `<HOST_IP>` | Static IP address (for display in messages) |
| `<DNS_SEARCH>` | DNS search domain (for FQDN) |

### From identity.config.yaml

| Placeholder | Description |
|-------------|-------------|
| `<USERNAME>` | Admin account username |
| `<PASSWORD_HASH>` | SHA-512 password hash (generated at build) |
| `<SSH_AUTHORIZED_KEY>` | SSH public key (optional) |

## Password Hashing

The build script generates the password hash from plaintext:

```bash
PASSWORD_HASH=$(openssl passwd -6 "$PASSWORD")
```

Store plaintext password in `identity.config.yaml` - the build handles hashing.

## Validation

After building, validate the generated user-data:

```bash
# Check YAML syntax
python3 -c "import yaml; yaml.safe_load(open('user-data'))"

# Validate cloud-init syntax (on Ubuntu)
cloud-init schema --config-file user-data
```
