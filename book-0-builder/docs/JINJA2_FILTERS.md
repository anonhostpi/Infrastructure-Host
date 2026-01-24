# 3.2 Jinja2 Filters

Custom Jinja2 filters provide safe value transformation for shell scripts and YAML configurations.

## Implementation

```python
# builder/filters.py
import crypt
import yaml

def shell_quote(value):
    """Escape for shell single quotes."""
    return "'" + str(value).replace("'", "'\\''") + "'"

def shell_array(items):
    """Convert list to bash array literal."""
    return '(' + ' '.join(shell_quote(i) for i in items) + ')'

def sha512_hash(password):
    """Generate SHA-512 password hash for /etc/shadow."""
    salt = crypt.mksalt(crypt.METHOD_SHA512)
    return crypt.crypt(password, salt)

def ip_only(cidr_notation):
    """Extract IP from CIDR notation: 192.168.1.1/24 -> 192.168.1.1"""
    return str(cidr_notation).split('/')[0]

def cidr_only(cidr_notation):
    """Extract prefix from CIDR notation: 192.168.1.1/24 -> 24"""
    return str(cidr_notation).split('/')[1]

def to_yaml(value):
    """Convert dict/list to YAML string."""
    return yaml.dump(value, default_flow_style=False, allow_unicode=True).rstrip()
```

## Filter Reference

### shell_quote

Safely quote a value for shell single-quote context. Handles embedded single quotes.

**Usage:**
```jinja
GATEWAY={{ network.gateway | shell_quote }}
```

**Input:** `192.168.1.1`
**Output:** `'192.168.1.1'`

**Input:** `it's a test`
**Output:** `'it'\''s a test'`

### shell_array

Convert a Python list to a Bash array literal with proper quoting.

**Usage:**
```jinja
DNS_SERVERS={{ network.dns_servers | shell_array }}
```

**Input:** `['8.8.8.8', '8.8.4.4']`
**Output:** `('8.8.8.8' '8.8.4.4')`

### sha512_hash

Generate a SHA-512 password hash suitable for `/etc/shadow` or cloud-init `passwd` field.

**Usage:**
```jinja
passwd: {{ identity.password | sha512_hash }}
```

**Input:** `mysecretpassword`
**Output:** `$6$rounds=5000$randomsalt$hashedvalue...`

**Note:** Each invocation generates a new random salt, so output differs between runs.

### ip_only

Extract the IP address portion from CIDR notation.

**Usage:**
```jinja
STATIC_IP={{ network.ip_address | ip_only | shell_quote }}
```

**Input:** `192.168.1.100/24`
**Output:** `192.168.1.100`

### cidr_only

Extract the prefix length from CIDR notation.

**Usage:**
```jinja
CIDR={{ network.ip_address | cidr_only | shell_quote }}
```

**Input:** `192.168.1.100/24`
**Output:** `24`

### to_yaml

Convert a dict or list to a YAML string.

**Usage:**
```jinja
{{ cloud_init | to_yaml }}
```

**Input:**
```python
{'hostname': 'server1', 'users': [{'name': 'admin'}]}
```

**Output:**
```yaml
hostname: server1
users:
- name: admin
```

**With Jinja2's built-in `indent` filter:**

For embedding YAML with proper indentation, chain with the built-in `indent` filter:

```jinja
autoinstall:
  version: 1
  user-data: |
{{ cloud_init | to_yaml | indent(4) }}
```

The `indent(width, first=False)` filter adds `width` spaces to each line. Set `first=True` to also indent the first line.

## Registering Filters

Filters are registered with the Jinja2 environment in `builder/renderer.py`:

```python
# builder/renderer.py
from jinja2 import Environment, FileSystemLoader
from . import filters

def create_environment(template_dir='src'):
    env = Environment(
        loader=FileSystemLoader(template_dir),
        keep_trailing_newline=True,
    )

    # Register custom filters
    env.filters['shell_quote'] = filters.shell_quote
    env.filters['shell_array'] = filters.shell_array
    env.filters['sha512_hash'] = filters.sha512_hash
    env.filters['ip_only'] = filters.ip_only
    env.filters['cidr_only'] = filters.cidr_only
    env.filters['to_yaml'] = filters.to_yaml

    return env
```

## Template Examples

### Shell Script Template

```bash
#!/bin/bash
# Auto-generated network detection script

GATEWAY={{ network.gateway | shell_quote }}
DNS_SERVERS={{ network.dns_servers | shell_array }}
STATIC_IP={{ network.ip_address | ip_only | shell_quote }}
CIDR={{ network.ip_address | cidr_only | shell_quote }}

# Use the variables
ip addr add ${STATIC_IP}/${CIDR} dev eth0
ip route add default via ${GATEWAY}
```

### Cloud-init Template

```yaml
#cloud-config
hostname: {{ network.hostname }}

users:
  - name: {{ identity.username }}
    passwd: {{ identity.password | sha512_hash }}
    lock_passwd: false
```

## Adding New Filters

1. Add the filter function to `builder/filters.py`
2. Register it in `builder/renderer.py`
3. Document it in this file

```python
# Example: Add a filter to uppercase values
def to_upper(value):
    """Convert value to uppercase."""
    return str(value).upper()

# Register in renderer.py
env.filters['to_upper'] = filters.to_upper
```
