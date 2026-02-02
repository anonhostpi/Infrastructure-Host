# RESEARCH.BOOK.2.USERS

## Purpose

The `users` fragment (`book-2-cloud/users/`) creates user accounts, configures sudo, and sets up SSH authorized keys. It is `iso_required: true` because bare-metal installations need a login user.

**Build metadata:** layer 3, order 20, `iso_required: true`

## Current State

### Completed

- `build.yaml` exists with correct metadata
- `fragment.yaml.tpl` renders user creation cloud-init configuration
- `scripts/user-setup.sh.tpl` exists for post-install user setup
- `tests/3/verifications.ps1` exists for layer 3 testing
- Documentation in `docs/FRAGMENT.md`

### Files

```
book-2-cloud/users/
├── build.yaml
├── fragment.yaml.tpl
├── config/
│   ├── identity.config.yaml          (gitignored, contains passwords/keys)
│   └── identity.config.yaml.example
├── docs/FRAGMENT.md
├── scripts/user-setup.sh.tpl
└── tests/3/verifications.ps1
```

## Remaining Work

### Config Naming Convention

The old plan proposed renaming `identity.config.yaml` to `production.yaml`. Same concern as other fragments: breaks `*.config.yaml` glob pattern in both SDKs.

**Recommendation:** Keep `identity.config.yaml` as-is. The name clearly communicates that this file contains identity/credential data (passwords, SSH keys). This is more descriptive than a generic `production.yaml`.

### Template Review

- `fragment.yaml.tpl` uses `identity.*` template variables -- these resolve from config keys, not filenames
- `scripts/user-setup.sh.tpl` should be reviewed for any hardcoded paths

### Security Note

Config contains sensitive data (passwords, SSH keys). The gitignore pattern `*.config.yaml` with `!*.config.yaml.example` exception correctly protects this file.

## Dependencies

- **Depends on:** base (Book 1), network
- **Depended on by:** ssh (needs users to exist for authorized_keys)
- **Book 0 interaction:** Builder SDK renders this template with BuildContext loading identity config. Password hashing uses `sha512_hash` Jinja2 filter from filters.py.
