# Refactor Plan: Jinja2-based Build System for Chapters 3-6

## Decisions

- **Templates**: Use `*.<ext>.tpl` extension (e.g., `early-net.sh.tpl`, `base.yaml.tpl`)
- **Configs**: Use `*.config.yaml` extension (e.g., `network.config.yaml`)
- **CLI**: Makefile-style with targets

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      BuildContext                           │
│  - loads src/config/*.config.yaml                           │
│  - exposes as namespaced dict (auto-unwrap single keys)    │
└─────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┴───────────────────┐
          ▼                                       ▼
   ┌─────────────┐                        ┌─────────────┐
   │ Script Gen  │                        │ YAML Gen    │
   │ (.sh.tpl)   │                        │ (.yaml.tpl) │
   └─────────────┘                        └─────────────┘
          │                                       │
          ▼                                       ▼
   Shell scripts                          YAML documents
   (early-net.sh)                         (cloud-init, autoinstall)
```

All `.tpl` files are Jinja2 templates. Configs in `src/config/` are plain YAML.

---

## Directory Structure

```
docs/~INSTALLATION_MEDIA/
├── Makefile                    # Build orchestration
│
├── builder/
│   ├── __init__.py
│   ├── context.py              # BuildContext class
│   ├── renderer.py             # Jinja2 environment setup
│   ├── filters.py              # Custom Jinja2 filters
│   └── composer.py             # YAML deep merge logic
│
├── src/
│   ├── config/                 # Plain YAML configs (NOT templates)
│   │   ├── network.config.yaml
│   │   └── identity.config.yaml
│   │
│   ├── scripts/                # Script templates (.sh.tpl)
│   │   ├── early-net.sh.tpl
│   │   └── net-setup.sh.tpl
│   │
│   └── autoinstall/            # Autoinstall templates
│       ├── base.yaml.tpl       # Main autoinstall template
│       │
│       └── cloud-init/         # Cloud-init fragments (.yaml.tpl)
│           ├── base.yaml.tpl
│           ├── 10-security.yaml.tpl
│           └── 20-packages.yaml.tpl
│
└── output/                     # Generated artifacts
    ├── scripts/
    │   ├── early-net.sh
    │   └── net-setup.sh
    ├── cloud-init.yaml
    └── user-data
```

---

## Core Components

### 1. BuildContext

Generic config loader - exposes all YAML files in `configs/` as nested dicts:

```python
class BuildContext:
    """
    Loads all *.config.yaml files from src/config/ directory.
    Each file becomes a top-level key (filename before .config.yaml).

    Auto-unwrap: If a config has only one top-level key, unwrap it.
    This avoids redundant access like identity.identity.username.

    src/config/network.config.yaml  (has 'host:')     -> ctx.network.hostname
    src/config/identity.config.yaml (has 'identity:') -> ctx.identity.username
    """

    def __init__(self, configs_dir='src/config'):
        self._data = {}
        for path in Path(configs_dir).glob('*.config.yaml'):
            # Extract name: network.config.yaml -> network
            key = path.name.replace('.config.yaml', '')
            with open(path) as f:
                content = yaml.safe_load(f)
                # Auto-unwrap single top-level key
                if isinstance(content, dict) and len(content) == 1:
                    content = next(iter(content.values()))
                self._data[key] = content

    def __getattr__(self, name):
        if name.startswith('_'):
            raise AttributeError(name)
        return self._data.get(name, {})

    def __getitem__(self, key):
        return self._data[key]

    def to_dict(self):
        """Export as dict for Jinja2 context (namespaced)"""
        return dict(self._data)
```

**Usage in templates** - namespaced by config filename (auto-unwrapped):
```jinja
{# src/config/network.config.yaml (contains 'host:') -> network.* #}
hostname: {{ network.hostname }}
gateway: {{ network.gateway }}

{# src/config/identity.config.yaml (contains 'identity:') -> identity.* #}
username: {{ identity.username }}
```

### 2. Custom Jinja2 Filters

```python
# filters.py
def shell_quote(value):
    """Escape for shell single quotes"""
    return "'" + str(value).replace("'", "'\\''") + "'"

def shell_array(items):
    """Convert list to bash array literal"""
    return '(' + ' '.join(shell_quote(i) for i in items) + ')'

def sha512_hash(password):
    """Generate SHA-512 password hash"""
    salt = crypt.mksalt(crypt.METHOD_SHA512)
    return crypt.crypt(password, salt)

def ip_only(cidr_notation):
    """Extract IP from CIDR notation: 192.168.1.1/24 -> 192.168.1.1"""
    return str(cidr_notation).split('/')[0]

def cidr_only(cidr_notation):
    """Extract prefix from CIDR notation: 192.168.1.1/24 -> 24"""
    return str(cidr_notation).split('/')[1]
```

### 3. Template Examples

**src/scripts/early-net.sh.tpl:**
```jinja
#!/bin/bash
# Auto-generated network detection script

GATEWAY={{ network.gateway | shell_quote }}
DNS_SERVERS={{ network.dns_servers | shell_array }}
STATIC_IP={{ network.ip_address | ip_only | shell_quote }}
CIDR={{ network.ip_address | cidr_only | shell_quote }}

# ARP detection logic here...
```

**src/autoinstall/cloud-init/base.yaml.tpl:**
```jinja
#cloud-config
hostname: {{ network.hostname }}
fqdn: {{ network.hostname }}.{{ network.dns_search }}

users:
  - name: {{ identity.username }}
    groups: [sudo, libvirt, kvm]
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    lock_passwd: false
    passwd: {{ identity.password | sha512_hash }}
{% if identity.ssh_authorized_keys %}
    ssh_authorized_keys:
{% for key in identity.ssh_authorized_keys %}
      - {{ key }}
{% endfor %}
{% endif %}

packages:
  - qemu-kvm
  - libvirt-daemon-system
```

---

## Makefile Interface

```makefile
.PHONY: all clean scripts cloud-init autoinstall iso

# Default: build everything
all: scripts cloud-init autoinstall

# Generate shell scripts
scripts: output/scripts/early-net.sh output/scripts/net-setup.sh

output/scripts/%.sh: src/scripts/%.sh.tpl src/config/*.config.yaml
	python -m builder render script $< -o $@

# Generate cloud-init config (base + fragments merged)
cloud-init: output/cloud-init.yaml

output/cloud-init.yaml: src/autoinstall/cloud-init/*.yaml.tpl src/config/*.config.yaml
	python -m builder render cloud-init -o $@

# Generate autoinstall user-data (embeds cloud-init + scripts)
autoinstall: output/user-data

output/user-data: output/cloud-init.yaml output/scripts/*.sh src/autoinstall/*.yaml.tpl
	python -m builder render autoinstall -o $@

# Build ISO (runs in multipass VM)
iso: output/user-data
	./build-iso.sh

clean:
	rm -rf output/*
```

---

## Builder Module Entry Points

```python
# builder/__main__.py
# Usage: python -m builder render <target> [args]

def main():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest='command')

    render_parser = subparsers.add_parser('render')
    render_parser.add_argument('target', choices=['script', 'cloud-init', 'autoinstall'])
    render_parser.add_argument('input', nargs='?')
    render_parser.add_argument('-o', '--output', required=True)

    args = parser.parse_args()
    ctx = BuildContext('src/config')

    if args.target == 'script':
        render_script(ctx, args.input, args.output)
    elif args.target == 'cloud-init':
        render_cloud_init(ctx, args.output)
    elif args.target == 'autoinstall':
        render_autoinstall(ctx, args.output)
```

---

## Next Steps

1. Create `docs/~INSTALLATION_MEDIA/builder/` module structure
2. Implement `BuildContext` class with `*.config.yaml` loading
3. Set up Jinja2 environment with custom filters
4. Implement YAML fragment rendering and merging
5. Create Makefile with targets
6. Port existing templates to `.tpl` format in `src/`
7. Test with existing configs
8. Update documentation (Chapters 3-6)
