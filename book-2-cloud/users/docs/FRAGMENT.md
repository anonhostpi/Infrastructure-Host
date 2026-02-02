# 6.3 Users Fragment

**Template:** `book-2-cloud/users/fragment.yaml.tpl`

Configures user accounts from `identity.config.yaml`.

## Template

```yaml
bootcmd:
  # user-setup.sh is base64 encoded to avoid YAML multiline string parsing issues
  # (multipass/cloud-init can mangle multi-line bootcmd scripts)
  # Directory structure: /var/lib/cloud/scripts/user-setup/
  #   - user-setup.sh.b64  (base64 encoded script)
  #   - user-setup.sh      (decoded executable)
  #   - user-setup.log     (execution output)
  - mkdir -p /var/lib/cloud/scripts/user-setup
  - echo '{{ scripts["user-setup.sh"] | to_base64 }}' > /var/lib/cloud/scripts/user-setup/user-setup.sh.b64
  - base64 -d /var/lib/cloud/scripts/user-setup/user-setup.sh.b64 > /var/lib/cloud/scripts/user-setup/user-setup.sh
  - chmod +x /var/lib/cloud/scripts/user-setup/user-setup.sh
  - /var/lib/cloud/scripts/user-setup/user-setup.sh >> /var/lib/cloud/scripts/user-setup/user-setup.log 2>&1 || true

ssh_pwauth: true
```

## Why bootcmd Instead of users Directive?

This fragment uses `bootcmd` with a base64-encoded helper script instead of cloud-init's `users:` directive because:

1. **Early execution** - `bootcmd` runs before `write_files` with `defer: true`, ensuring the user exists when deferred files need to set ownership
2. **Cloud provider compatibility** - The `users:` directive can conflict with cloud providers' default user setup (e.g., multipass creates an `ubuntu` user)
3. **Idempotent** - The `if id -u` guard in `user-setup.sh` ensures the script only creates the user once, even though `bootcmd` runs on every boot
4. **YAML safety** - The script is base64-encoded to avoid multiline string parsing issues with multipass/cloud-init

## Configuration Source

Create `book-2-cloud/users/config/identity.config.yaml`:

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
