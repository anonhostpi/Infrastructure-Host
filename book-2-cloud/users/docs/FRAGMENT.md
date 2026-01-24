# 6.3 Users Fragment

**Template:** `src/autoinstall/cloud-init/20-users.yaml.tpl`

Configures user accounts from `identity.config.yaml`.

## Template

```yaml
bootcmd:
  # Create admin user in bootcmd (runs early, before write_files with defer:true)
  # This ensures the user exists when deferred write_files need to set ownership
  # Wrapped in subshell so exit doesn't terminate the combined bootcmd script
  # Conditional ensures this only runs once (bootcmd runs on every boot)
  - |
    (
    if ! id -u {{ identity.username }} >/dev/null 2>&1; then
      # Create user - only add to sudo group here; virtualization groups added by 60-virtualization
      useradd -m -s /bin/bash -N -G sudo {{ identity.username }}
      echo '{{ identity.username }}:{{ identity.password | sha512_hash }}' | chpasswd -e
      echo '{{ identity.username }} ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/{{ identity.username }}
      chmod 440 /etc/sudoers.d/{{ identity.username }}
{%- if identity.ssh_authorized_keys is defined and identity.ssh_authorized_keys %}
      mkdir -p /home/{{ identity.username }}/.ssh
      chmod 700 /home/{{ identity.username }}/.ssh
      : > /home/{{ identity.username }}/.ssh/authorized_keys
{%- for key in identity.ssh_authorized_keys %}
      echo '{{ key }}' >> /home/{{ identity.username }}/.ssh/authorized_keys
{%- endfor %}
      chmod 600 /home/{{ identity.username }}/.ssh/authorized_keys
      chown -R {{ identity.username }}:{{ identity.username }} /home/{{ identity.username }}/.ssh
{%- endif %}
      # Lock root account
      passwd -l root
    fi
    )

ssh_pwauth: true
```

## Why bootcmd Instead of users Directive?

This fragment uses `bootcmd` instead of cloud-init's `users:` directive because:

1. **Early execution** - `bootcmd` runs before `write_files` with `defer: true`, ensuring the user exists when deferred files need to set ownership
2. **Cloud provider compatibility** - The `users:` directive can conflict with cloud providers' default user setup (e.g., multipass creates an `ubuntu` user)
3. **Idempotent** - The `if ! id -u` guard ensures the script only creates the user once, even though `bootcmd` runs on every boot

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

| Setting | Value | Description |
|---------|-------|-------------|
| Shell | /bin/bash | Default shell |
| Groups | sudo | Admin access (virtualization groups added by 60-virtualization) |
| Sudo | NOPASSWD:ALL | Passwordless sudo via `/etc/sudoers.d/` |
| Password | SHA-512 hash | Secure password set via `chpasswd -e` |

## Password Hashing

The `sha512_hash` filter generates a secure password hash at build time:

```jinja
{{ identity.password | sha512_hash }}
```

See [3.2 Jinja2 Filters](../BUILD_SYSTEM/JINJA2_FILTERS.md) for filter details.

## SSH Keys

SSH authorized keys are optional. If provided in `identity.config.yaml`, they are:

1. Directory created with mode 700
2. Keys written to `~/.ssh/authorized_keys`
3. File permissions set to 600
4. Ownership set to the admin user

## Security Settings

| Setting | Value | Purpose |
|---------|-------|---------|
| `passwd -l root` | Lock root | Prevent direct root login |
| `ssh_pwauth` | true | Allow SSH password authentication |

**Note:** SSH password authentication is enabled here but can be hardened in [6.4 SSH Hardening](./SSH_HARDENING_FRAGMENT.md).

## Group Membership

The user is initially added only to the `sudo` group. Additional groups are added by other fragments:

- `libvirt`, `kvm` - Added by [6.10 Virtualization](./VIRTUALIZATION_FRAGMENT.md)
