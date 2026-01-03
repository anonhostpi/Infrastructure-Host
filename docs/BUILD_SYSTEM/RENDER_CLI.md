# 3.3 Render CLI

The builder module provides a command-line interface for rendering templates.

## Usage

```bash
python -m builder render <target> [input] -o <output>
```

## Targets

| Target | Input | Description |
|--------|-------|-------------|
| `script` | Required | Render a single script template |
| `cloud-init` | Optional | Render and merge cloud-init fragments |
| `autoinstall` | Optional | Render autoinstall user-data |

## Examples

```bash
# Render a script template
python -m builder render script src/scripts/early-net.sh.tpl -o output/scripts/early-net.sh

# Render cloud-init (merges all fragments)
python -m builder render cloud-init -o output/cloud-init.yaml

# Render autoinstall user-data
python -m builder render autoinstall -o output/user-data
```

## Implementation

```python
# builder/__main__.py
import argparse
from .context import BuildContext
from .renderer import render_script, render_cloud_init_to_file, render_autoinstall_to_file

def main():
    parser = argparse.ArgumentParser(prog='builder')
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
        render_cloud_init_to_file(ctx, args.output)
    elif args.target == 'autoinstall':
        render_autoinstall_to_file(ctx, args.output)

if __name__ == '__main__':
    main()
```

## Render Functions

```python
# builder/renderer.py
from pathlib import Path
import yaml
from .filters import create_environment
from .composer import deep_merge

# Global Jinja2 environment
env = create_environment('src')
```

### render_text

Base function that renders any template and returns the result as a string:

```python
def render_text(ctx, template_path, **extra_context):
    """Render a template, return as string."""
    template = env.get_template(template_path)
    return template.render(**ctx.to_dict(), **extra_context)
```

### render_scripts

Renders all script templates and returns a dict mapping filename to content:

```python
def render_scripts(ctx):
    """Render all script templates, return as dict."""
    scripts_dir = Path('src/scripts')
    scripts = {}
    for tpl_path in scripts_dir.glob('*.tpl'):
        # Keep original filename (e.g., "early-net.sh")
        filename = tpl_path.name.removesuffix('.tpl')
        rendered = render_text(ctx, str(tpl_path.relative_to('src')))
        scripts[filename] = rendered
    return scripts
```

### render_script

Renders a single `.sh.tpl` template and writes to a file:

```python
def render_script(ctx, input_path, output_path):
    """Render a script template to output file."""
    result = render_text(ctx, input_path)

    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w') as f:
        f.write(result)
```

### render_cloud_init

Renders and merges all cloud-init fragments, returns the merged dict:

```python
def render_cloud_init(ctx):
    """Render and merge cloud-init fragments, return as dict."""
    fragments_dir = Path('src/autoinstall/cloud-init')
    scripts = render_scripts(ctx)

    merged = {}
    for tpl_path in sorted(fragments_dir.glob('*.yaml.tpl')):
        rendered = render_text(ctx, str(tpl_path.relative_to('src')), scripts=scripts)
        fragment = yaml.safe_load(rendered)
        merged = deep_merge(merged, fragment)

    return merged
```

### render_cloud_init_to_file

Renders cloud-init and writes to a file:

```python
def render_cloud_init_to_file(ctx, output_path):
    """Render cloud-init to output file."""
    merged = render_cloud_init(ctx)

    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w') as f:
        f.write('#cloud-config\n')
        yaml.dump(merged, f, default_flow_style=False)
```

### render_autoinstall

Renders the autoinstall user-data, returns as string:

```python
def render_autoinstall(ctx):
    """Render autoinstall user-data, return as string."""
    scripts = render_scripts(ctx)
    cloud_init = render_cloud_init(ctx)

    return render_text(
        ctx,
        'autoinstall/base.yaml.tpl',
        scripts=scripts,
        cloud_init=cloud_init,
    )
```

### render_autoinstall_to_file

Renders autoinstall and writes to a file:

```python
def render_autoinstall_to_file(ctx, output_path):
    """Render autoinstall to output file."""
    result = render_autoinstall(ctx)

    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w') as f:
        f.write(result)
```

## Fragment Merging

Cloud-init fragments are merged using `deep_merge` from `builder/composer.py`. This allows splitting configuration across multiple files (e.g., `base.yaml.tpl`, `10-security.yaml.tpl`, `20-packages.yaml.tpl`) that get combined into a single cloud-init document.

### deep_merge

```python
# builder/composer.py

def deep_merge(base, override):
    """
    Deep merge override into base.
    - Dicts are recursively merged
    - Lists are extended (override appended to base)
    - Scalars are replaced by override
    """
    if not isinstance(base, dict) or not isinstance(override, dict):
        return override

    result = base.copy()
    for key, value in override.items():
        if key in result:
            if isinstance(result[key], dict) and isinstance(value, dict):
                result[key] = deep_merge(result[key], value)
            elif isinstance(result[key], list) and isinstance(value, list):
                result[key] = result[key] + value
            else:
                result[key] = value
        else:
            result[key] = value

    return result
```

### Merge Behavior

| Type | Behavior |
|------|----------|
| Dicts | Recursively merged (keys combined) |
| Lists | Extended (fragment items appended) |
| Scalars | Replaced by fragment value |

### Examples

#### Scalars (replaced)

**base.yaml.tpl:**
```yaml
hostname: default-host
timezone: UTC
```

**10-identity.yaml.tpl:**
```yaml
hostname: kvm-host
```

**Merged result:**
```yaml
hostname: kvm-host
timezone: UTC
```

Later fragments replace scalar values from earlier fragments.

#### Dicts (recursively merged)

**base.yaml.tpl:**
```yaml
users:
  - name: admin
    groups: sudo
    shell: /bin/bash
```

**10-security.yaml.tpl:**
```yaml
users:
  - name: admin
    ssh_authorized_keys:
      - ssh-ed25519 AAAA...
```

**Merged result:**
```yaml
users:
  - name: admin
    groups: sudo
    shell: /bin/bash
  - name: admin
    ssh_authorized_keys:
      - ssh-ed25519 AAAA...
```

Note: `users` is a list, so items are appended (not merged by `name`). For true dict merging:

**base.yaml.tpl:**
```yaml
write_files:
  sshd_config:
    path: /etc/ssh/sshd_config.d/hardening.conf
    permissions: '0644'
```

**10-security.yaml.tpl:**
```yaml
write_files:
  sshd_config:
    content: |
      PermitRootLogin no
```

**Merged result:**
```yaml
write_files:
  sshd_config:
    path: /etc/ssh/sshd_config.d/hardening.conf
    permissions: '0644'
    content: |
      PermitRootLogin no
```

Dict keys are combined recursively, preserving values from both fragments.

#### Lists (extended)

**base.yaml.tpl:**
```yaml
packages:
  - qemu-kvm
  - libvirt-daemon-system

runcmd:
  - systemctl enable libvirtd
```

**10-security.yaml.tpl:**
```yaml
packages:
  - fail2ban
  - ufw

runcmd:
  - ufw enable
```

**Merged result:**
```yaml
packages:
  - qemu-kvm
  - libvirt-daemon-system
  - fail2ban
  - ufw

runcmd:
  - systemctl enable libvirtd
  - ufw enable
```

Lists are concatenated in fragment order.

---

Fragments are processed in sorted order by filename, so numeric prefixes control merge order.
