# 10.1 Templating Strategy

For deploying multiple servers, use a template-based approach.

## Directory Structure

```
templates/
├── user-data.template       # Base cloud-init config with variables
├── meta-data.template       # Instance metadata template
└── generate-config.sh       # Script to generate per-host configs
```

## Example generate-config.sh

```bash
#!/bin/bash

# Host-specific variables
HOSTNAME=$1
IP_ADDRESS=$2
INSTANCE_ID=$3

# Generate user-data
sed -e "s/{{HOSTNAME}}/${HOSTNAME}/g" \
    -e "s/{{IP_ADDRESS}}/${IP_ADDRESS}/g" \
    templates/user-data.template > configs/${HOSTNAME}/user-data

# Generate meta-data
sed -e "s/{{INSTANCE_ID}}/${INSTANCE_ID}/g" \
    -e "s/{{HOSTNAME}}/${HOSTNAME}/g" \
    templates/meta-data.template > configs/${HOSTNAME}/meta-data

# Create ISO
genisoimage -output configs/${HOSTNAME}/cloud-init.iso \
  -volid cidata -joliet -rock \
  configs/${HOSTNAME}/user-data \
  configs/${HOSTNAME}/meta-data

echo "Generated configuration for ${HOSTNAME}"
```

## Usage

```bash
./generate-config.sh ubuntu-host-01 <HOST_IP_1> host-01
./generate-config.sh ubuntu-host-02 <HOST_IP_2> host-02
./generate-config.sh ubuntu-host-03 <HOST_IP_3> host-03
```

## Template Variables

Common variables to template:

| Variable | Description |
|----------|-------------|
| `{{HOSTNAME}}` | Server hostname |
| `{{IP_ADDRESS}}` | Static IP address |
| `{{INSTANCE_ID}}` | Unique instance identifier |
| `{{GATEWAY}}` | Default gateway |
| `{{DNS_SERVERS}}` | DNS server addresses |
| `{{SSH_KEY}}` | SSH public key |

## Inventory File

Maintain an inventory file for all servers:

```yaml
# inventory.yaml
servers:
  - hostname: ubuntu-host-01
    ip: <HOST_IP_1>
    role: compute
  - hostname: ubuntu-host-02
    ip: <HOST_IP_2>
    role: compute
  - hostname: ubuntu-host-03
    ip: <HOST_IP_3>
    role: storage
```
