# 6.13 Copilot CLI Fragment

**Template:** `book-2-cloud/copilot-cli/fragment.yaml.tpl`

Installs and configures GitHub Copilot CLI, GitHub's official AI coding agent for terminal use.

## Overview

[GitHub Copilot CLI](https://docs.github.com/en/copilot/github-copilot-in-the-cli) is GitHub's AI-powered coding assistant available as a terminal interface. It provides code suggestions, explanations, and assistance with shell commands.

## Authentication

Copilot CLI supports multiple authentication methods:

| Method | Description |
|--------|-------------|
| **OAuth Copy** | Copy credentials from an already authenticated Copilot CLI instance |
| **GH_TOKEN** | Environment variable with OAuth token (fallback) |
| **Interactive** | Run `copilot` then `/login` command |

### Credential Flow

The VM host (build machine) is the **source of truth** for credentials:

```
VM Host (Windows)                    Builder VM (Ubuntu)              Final Image
─────────────────                    ──────────────────               ───────────
1. Extract from                      2. Receive credentials           3. Embed in
   Credential Manager  ──────────►      as JSON config    ──────────►    cloud-init
   or config.json                       (BuildContext)                    output
```

The builder VM is temporal/ephemeral - it cannot be the source of truth.

### Extracting OAuth from Secure Storage (VM Host)

Copilot CLI stores tokens in the OS secure credential store by default (Windows Credential Manager, macOS Keychain, Linux libsecret). Use the extraction methods below to retrieve tokens for the build process.

#### Credential Storage Details

| Platform | Storage Location |
|----------|------------------|
| Windows | Credential Manager → Generic Credentials → `copilot-cli` |
| macOS | Keychain → `copilot-cli` |
| Linux | libsecret/GNOME Keyring → `copilot-cli` |

- **Keytar Service Name:** `copilot-cli`
- **Account Format:** `{host}:{login}` (e.g., `https://github.com:username`)
- **Config Fallback Key:** `copilot_tokens` in `~/.copilot/config.json`

#### Extraction Script (Python)

Save as `get-copilot-token.py` on the VM host:

```python
#!/usr/bin/env python3
"""Extract Copilot CLI OAuth token from OS secure storage."""
import json
import sys
from pathlib import Path

# pip install keyring
import keyring

SERVICE = 'copilot-cli'
COPILOT_DIR = Path.home() / '.copilot'
CONFIG_FILE = COPILOT_DIR / 'config.json'


def get_accounts_from_config():
    """Get account names from config.json logged_in_users."""
    if not CONFIG_FILE.exists():
        return []
    config = json.loads(CONFIG_FILE.read_text())
    accounts = []
    for user in config.get('logged_in_users', []):
        host = user.get('host', 'https://github.com')
        login = user.get('login')
        if login:
            accounts.append(f"{host}:{login}")
    return accounts


def main():
    accounts = get_accounts_from_config()
    if not accounts:
        print("No logged_in_users found in config.json. Run /login first.", file=sys.stderr)
        sys.exit(1)

    tokens = {}
    for account in accounts:
        token = keyring.get_password(SERVICE, account)
        if token:
            tokens[account] = token

    if tokens:
        print(json.dumps(tokens, indent=2))
    else:
        print("No credentials found in secure storage.", file=sys.stderr)
        print("Tokens may already be in config.json, or run /login first.", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
```

**Requirements:** `pip install keyring`

Run with: `python get-copilot-token.py`

#### Alternative: Migrate to config.json

For easier extraction, migrate tokens from secure storage to `config.json`:

```python
#!/usr/bin/env python3
"""Migrate Copilot CLI tokens from secure storage to config.json."""
import json
from pathlib import Path
import keyring

SERVICE = 'copilot-cli'
CONFIG_FILE = Path.home() / '.copilot' / 'config.json'

# Read current config
config = json.loads(CONFIG_FILE.read_text())
config.setdefault('copilot_tokens', {})

# Migrate each logged-in user's token
for user in config.get('logged_in_users', []):
    account = f"{user['host']}:{user['login']}"
    token = keyring.get_password(SERVICE, account)
    if token:
        config['copilot_tokens'][account] = token
        keyring.delete_password(SERVICE, account)
        print(f"Migrated: {account}")

# Write updated config
CONFIG_FILE.write_text(json.dumps(config, indent=2))
print("Done! Tokens moved to config.json")
```

After migration, tokens are in `~/.copilot/config.json`:

```json
{
  "copilot_tokens": {
    "https://github.com:your-username": "gho_..."
  },
  "logged_in_users": [
    { "host": "https://github.com", "login": "your-username" }
  ],
  "last_logged_in_user": {
    "host": "https://github.com",
    "login": "your-username"
  }
}
```

#### Environment Variable Alternative

Bypass all storage by setting environment variables on the VM host:

```powershell
# In order of precedence:
$env:COPILOT_GITHUB_TOKEN = "gho_xxxxx"
# or
$env:GH_TOKEN = "gho_xxxxx"
# or
$env:GITHUB_TOKEN = "gho_xxxxx"
```

**Security Warning:** Storing tokens in `config.json` means they are unencrypted on disk. Only use this in controlled environments.

### GH_TOKEN Environment Variable (Fallback)

You can also authenticate via environment variable:

```bash
export GH_TOKEN=gho_...
```

**Requirements:** Active GitHub Copilot subscription (Individual, Business, or Enterprise)

## Template

```yaml
{% if copilot_cli.enabled | default(false) %}
runcmd:
  # Install Node.js LTS via apt (NodeSource repo for unattended-upgrades support)
  - command -v node || (curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && apt-get install -y nodejs)
  # Install GitHub Copilot CLI globally via npm (updated by unattended-upgrades Post-Invoke hook)
  - npm install -g @github/copilot

  # Create config directory for admin user
  - mkdir -p /home/{{ identity.username }}/.copilot

  # Write config.json via heredoc
  - |
    cat > /home/{{ identity.username }}/.copilot/config.json << 'COPILOT_CONFIG_EOF'
    {
      "$schema": "https://copilot.github.com/config.json"
      ...
    }
    COPILOT_CONFIG_EOF

{% if copilot_cli.auth.gh_token is defined %}
  # Set GH_TOKEN environment variable system-wide (fallback auth method)
  - echo 'GH_TOKEN={{ copilot_cli.auth.gh_token }}' >> /etc/environment
{% endif %}

  # Set ownership of .copilot directory after all files are written
  - chown -R {{ identity.username }}:{{ identity.username }} /home/{{ identity.username }}/.copilot
{% endif %}
```

See the full template at `book-2-cloud/copilot-cli/fragment.yaml.tpl`.

**Installation notes:**
- Node.js is installed from NodeSource repository for unattended-upgrades support
- Copilot CLI is installed via npm for automatic updates via npm-global-update

---

## Configuration

Create `src/config/copilot_cli.config.yaml`:

```yaml
copilot_cli:
  enabled: true

  auth:
    # Option 1: OAuth (recommended)
    oauth:
      github_username: "your-username"
      oauth_token: "gho_..."

    # Option 2: GH_TOKEN environment variable (fallback)
    # gh_token: "gho_..."

  settings:
    allow_all_paths: false
    allow_all_urls: false
```

| Field | Description | Default |
|-------|-------------|---------|
| `enabled` | Install Copilot CLI during cloud-init | `false` |
| `auth.oauth.*` | OAuth credentials for config.json | - |
| `auth.gh_token` | GH_TOKEN environment variable (fallback) | - |
| `settings.allow_all_paths` | Allow all paths without prompting | `false` |
| `settings.allow_all_urls` | Allow all URLs without prompting | `false` |

---

## Authentication Configuration

### OAuth in config.json (Recommended)

```yaml
copilot_cli:
  enabled: true
  auth:
    oauth:
      github_username: "your-username"
      oauth_token: "gho_..."
```

This creates `~/.copilot/config.json` with `copilot_tokens` for authentication.

### GH_TOKEN Environment Variable (Fallback)

```yaml
copilot_cli:
  enabled: true
  auth:
    gh_token: "gho_..."
```

### Build-Time Environment Variable

Override at build time on the builder VM without modifying config files:

```bash
AUTOINSTALL_COPILOT_CLI_AUTH_GH_TOKEN="gho_..." make render
```

### Post-Deployment Interactive Setup

If no auth is configured, authenticate interactively after deployment:

```bash
copilot
/login
# Follow the prompts
```

---

## Generated Configuration

### OAuth Method: `~/.copilot/config.json`

```json
{
  "$schema": "https://copilot.github.com/config.json",
  "allowAllPaths": false,
  "allowAllUrls": false,
  "copilot_tokens": {
    "https://github.com:your-username": "gho_..."
  },
  "logged_in_users": [
    { "host": "https://github.com", "login": "your-username" }
  ],
  "last_logged_in_user": {
    "host": "https://github.com",
    "login": "your-username"
  }
}
```

### GH_TOKEN Method: Environment Variable

The token is set in `/etc/environment`:

```
GH_TOKEN=gho_...
```

And in `~/.bashrc.d/copilot-cli.sh` for interactive sessions.

---

## Post-Deployment Setup

### Verify Installation

```bash
# Check installation
copilot --version

# Check authentication
copilot
/usage
```

### Interactive Authentication (if needed)

```bash
copilot
/login
# Follow the device flow prompts
```

---

## Key Commands

| Command | Description |
|---------|-------------|
| `/login` | Authenticate to GitHub |
| `/usage` | View session statistics and token usage |
| `/cwd [path]` | Switch working directory |
| `/add-dir [path]` | Add trusted directory |
| `/delegate [task]` | Hand off work to coding agent |
| `/mcp add` | Configure MCP servers |
| `/feedback` | Submit feedback |
| `?` | Show all commands |

---

## System Requirements

- curl (for installation)
- Active GitHub Copilot subscription (Individual, Business, or Enterprise)
- OAuth token in config.json OR GH_TOKEN environment variable
- Modern terminal emulator

---

## Fragment Ordering

This fragment uses the `76-` prefix to run after Claude Code (75-).

---

## References

- [GitHub Copilot CLI Documentation](https://docs.github.com/en/copilot/github-copilot-in-the-cli)
- [GitHub Copilot Subscription](https://github.com/features/copilot)
