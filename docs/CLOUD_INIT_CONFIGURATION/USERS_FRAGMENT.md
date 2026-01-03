# 6.3 Users Fragment

**Template:** `src/autoinstall/cloud-init/20-users.yaml.tpl`

Configures user accounts from `identity.config.yaml`.

## Template

```yaml
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

disable_root: true
ssh_pwauth: true
```

## Configuration Source

Create `src/config/identity.config.yaml`:

```yaml
identity:
  username: admin
  password: changeme
  ssh_authorized_keys:
    - ssh-ed25519 AAAA... user@host
```

**Note:** The `identity:` top-level key matches the filename, so BuildContext auto-unwraps it. Templates access values as `{{ identity.username }}`.

## User Configuration

| Field | Value | Description |
|-------|-------|-------------|
| `groups` | sudo, libvirt, kvm | Admin and virtualization access |
| `shell` | /bin/bash | Default shell |
| `sudo` | NOPASSWD:ALL | Passwordless sudo |
| `lock_passwd` | false | Allow password login |
| `passwd` | (hashed) | SHA-512 password hash |

## Password Hashing

The `sha512_hash` filter generates a secure password hash at build time:

```jinja
passwd: {{ identity.password | sha512_hash }}
```

See [3.2 Jinja2 Filters](../BUILD_SYSTEM/JINJA2_FILTERS.md) for filter details.

## SSH Keys

SSH authorized keys are optional. If provided in `identity.config.yaml`, they are added to the user's `~/.ssh/authorized_keys`.

## Security Settings

| Setting | Value | Purpose |
|---------|-------|---------|
| `disable_root` | true | Prevent direct root login |
| `ssh_pwauth` | true | Allow SSH password authentication |

**Note:** SSH password authentication is enabled here but can be hardened in [6.4 SSH Hardening](./SSH_HARDENING_FRAGMENT.md).
