# 6.12 Claude Code Fragment

**Template:** `src/autoinstall/cloud-init/75-claude-code.yaml.tpl`

Installs and configures Claude Code, Anthropic's official AI coding agent for terminal use.

## Overview

[Claude Code](https://claude.ai/code) is Anthropic's AI-powered coding assistant available as a terminal interface. It provides code navigation, feature implementation, debugging assistance, and codebase understanding.

## Authentication

Claude Code supports multiple authentication methods:

| Method | Description |
|--------|-------------|
| **OAuth Copy** | Copy credentials from an already authenticated Claude Code instance |
| **API Key** | Key from Anthropic Console (works with all subscriptions) |
| **Interactive** | Run `claude` and follow OAuth flow (Claude Max/Pro) |

### Copying OAuth from Authenticated Instance (Recommended)

If you have Claude Code authenticated on your build host, you can copy the OAuth credentials:

**Source files on authenticated machine:**
- `~/.claude/.credentials.json` - OAuth tokens
- `~/.claude.json` - Must set `hasCompletedOnboarding: true`

**Credentials file format (`~/.claude/.credentials.json`):**
```json
{
  "claudeAiOauth": {
    "accessToken": "sk-ant-oat01-...",
    "refreshToken": "sk-ant-ort01-...",
    "expiresAt": 1767957851524,
    "scopes": ["user:inference", "user:profile", "user:sessions:claude_code"],
    "subscriptionType": "max"
  }
}
```

**Required state (`~/.claude.json`):**
```json
{
  "hasCompletedOnboarding": true,
  "lastOnboardingVersion": "2.0.55"
}
```

### Getting an API Key

1. Go to [Anthropic Console](https://console.anthropic.com/settings/keys)
2. Create a new API key
3. Add to your config or set as environment variable

## Template

```yaml
{% if claude_code.enabled | default(false) %}
runcmd:
  # Install Claude Code via official script
  - curl -fsSL https://claude.ai/install.sh | bash

  # Create config directory for admin user
  - mkdir -p /home/{{ identity.username }}/.claude
  - chown -R {{ identity.username }}:{{ identity.username }} /home/{{ identity.username }}/.claude

{% if claude_code.auth.api_key is defined %}
  # Set ANTHROPIC_API_KEY environment variable system-wide
  - echo 'ANTHROPIC_API_KEY={{ claude_code.auth.api_key }}' >> /etc/environment
{% endif %}

write_files:
  # Claude Code settings configuration
  - path: /home/{{ identity.username }}/.claude/settings.json
    owner: {{ identity.username }}:{{ identity.username }}
    permissions: '600'
    content: |
      {
        "model": "{{ claude_code.model | default('claude-sonnet-4-5-20250514') }}"
        ...
      }
{% endif %}
```

See the full template at `src/autoinstall/cloud-init/75-claude-code.yaml.tpl`.

---

## Configuration

Create `src/config/claude_code.config.yaml`:

```yaml
claude_code:
  enabled: true
  model: claude-sonnet-4-5-20250514

  auth:
    # Option 1: OAuth (recommended for Max/Pro)
    oauth:
      access_token: "sk-ant-oat01-..."
      refresh_token: "sk-ant-ort01-..."
      subscription_type: "max"

    # Option 2: API Key
    # api_key: "sk-ant-api03-..."

  settings:
    auto_update: false
```

| Field | Description | Default |
|-------|-------------|---------|
| `enabled` | Install Claude Code during cloud-init | `false` |
| `model` | Default model ID | `claude-sonnet-4-5-20250514` |
| `auth.oauth.*` | OAuth credentials from authenticated instance | - |
| `auth.api_key` | Anthropic API key (alternative to OAuth) | - |
| `settings.auto_update` | Enable auto-updates | `true` |

---

## Authentication Configuration

### OAuth from Authenticated Instance (Recommended)

```yaml
claude_code:
  enabled: true
  auth:
    oauth:
      access_token: "sk-ant-oat01-..."
      refresh_token: "sk-ant-ort01-..."
      expires_at: 1767957851524
      subscription_type: "max"
```

This creates `~/.claude/.credentials.json` and sets `hasCompletedOnboarding: true` in `~/.claude.json`.

### API Key

```yaml
claude_code:
  enabled: true
  auth:
    api_key: "sk-ant-api03-..."
```

### Build-Time Environment Variable

Override at build time on the builder VM without modifying config files:

```bash
AUTOINSTALL_CLAUDE_CODE_AUTH_API_KEY="sk-ant-api03-..." make render
```

### Post-Deployment Interactive Setup

If no auth is configured, authenticate interactively after deployment:

```bash
claude
# Follow the OAuth flow in your browser
```

---

## Generated Configuration

### `~/.claude/settings.json`

```json
{
  "model": "claude-sonnet-4-5-20250514",
  "autoUpdater": {
    "disabled": true
  }
}
```

### OAuth Method: `~/.claude/.credentials.json`

```json
{
  "claudeAiOauth": {
    "accessToken": "sk-ant-oat01-...",
    "refreshToken": "sk-ant-ort01-...",
    "expiresAt": 1767957851524,
    "scopes": ["user:inference", "user:profile", "user:sessions:claude_code"],
    "subscriptionType": "max"
  }
}
```

### OAuth Method: `~/.claude.json`

```json
{
  "hasCompletedOnboarding": true,
  "lastOnboardingVersion": "2.0.55",
  "autoUpdates": false
}
```

### API Key Method: Environment Variable

The API key is set in `/etc/environment`:

```
ANTHROPIC_API_KEY=sk-ant-api03-...
```

And in `~/.bashrc.d/claude-code.sh` for interactive sessions.

---

## Post-Deployment Setup

### Verify Installation

```bash
# Check installation
claude --version

# Test authentication
claude -p "Hello"
```

### Interactive Authentication (if needed)

```bash
claude
# Follow OAuth flow if prompted
```

---

## Available Models

| Model ID | Description |
|----------|-------------|
| `claude-opus-4-5-20250514` | Most capable model |
| `claude-sonnet-4-5-20250514` | Balanced performance (default) |

---

## System Requirements

- curl (for installation)
- Active Anthropic API key or Claude Max/Pro subscription
- Modern terminal emulator

---

## Fragment Ordering

This fragment uses the `75-` prefix to run after Cockpit (70-).

---

## References

- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Anthropic Console](https://console.anthropic.com/)
- [Claude Code Installation](https://claude.ai/code)
