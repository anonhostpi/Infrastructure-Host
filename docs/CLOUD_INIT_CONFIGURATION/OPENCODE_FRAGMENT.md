# 6.14 OpenCode Fragment

**Template:** `src/autoinstall/cloud-init/77-opencode.yaml.tpl`

Installs and configures OpenCode, an open-source AI coding agent for terminal use.

## Overview

[OpenCode](https://github.com/anomalyco/opencode) is an AI-powered coding assistant available as a terminal interface. It helps with code navigation, feature implementation, and codebase understanding.

## Authentication

OpenCode supports multiple authentication methods. The most streamlined approach is **automatic credential derivation** from Claude Code.

### Automatic Auth Derivation (Recommended)

When Claude Code (6.12) is configured with OAuth credentials, OpenCode's `auth.json` is automatically generated from those credentials:

| OpenCode Provider | Source |
|-------------------|--------|
| `anthropic` | Claude Code OAuth credentials (`claude_code.auth.oauth`) |

**Note:** GitHub Copilot auth cannot be derived from Copilot CLI (incompatible token types).

**How it works:**

1. Configure Claude Code with OAuth credentials
2. The builder automatically derives OpenCode's auth from those credentials
3. At render time, `auth.json` is generated with the Anthropic tokens

**Generated auth.json structure:**

```json
{
  "anthropic": {
    "type": "oauth",
    "access": "<access_token>",
    "refresh": "<refresh_token>",
    "expires": 1736500000000
  }
}
```

### Manual Auth Configuration

You can also configure OpenCode auth directly in the config file or use environment variables for API keys.

## Template

```yaml
{% if opencode.enabled | default(false) %}
runcmd:
  # Install Node.js LTS via apt (NodeSource repo for unattended-upgrades support)
  - command -v node || (curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && apt-get install -y nodejs)
  # Install opencode globally via npm (updated by unattended-upgrades Post-Invoke hook)
  - npm install -g opencode-ai

  # Create config directories with proper ownership
  - install -d -o {{ identity.username }} -g {{ identity.username }} /home/{{ identity.username }}/.config/opencode
  - install -d -o {{ identity.username }} -g {{ identity.username }} /home/{{ identity.username }}/.local/share/opencode
  # Create runtime directories (log, bin, storage)
  - install -d -o {{ identity.username }} -g {{ identity.username }} /home/{{ identity.username }}/.local/share/opencode/log
  - install -d -o {{ identity.username }} -g {{ identity.username }} /home/{{ identity.username }}/.local/share/opencode/bin
  - install -d -o {{ identity.username }} -g {{ identity.username }} /home/{{ identity.username }}/.local/share/opencode/storage

  # Write OpenCode config via heredoc
  - |
    cat > /home/{{ identity.username }}/.config/opencode/opencode.json << 'OPENCODE_CONFIG_EOF'
    {
      "$schema": "https://opencode.ai/config.json",
      "model": "{{ opencode.model | default('anthropic/claude-sonnet-4-5-latest') }}",
      ...
    }
    OPENCODE_CONFIG_EOF

{% if opencode.auth.anthropic is defined %}
  # Write auth.json (derived from Claude Code credentials)
  - |
    cat > /home/{{ identity.username }}/.local/share/opencode/auth.json << 'OPENCODE_AUTH_EOF'
    {
      "anthropic": { ... }
    }
    OPENCODE_AUTH_EOF
{% endif %}

  # Set ownership after all files are written
  - chown -R {{ identity.username }}:{{ identity.username }} /home/{{ identity.username }}/.config/opencode
  - chown -R {{ identity.username }}:{{ identity.username }} /home/{{ identity.username }}/.local/share/opencode
{% endif %}
```

See the full template at `src/autoinstall/cloud-init/77-opencode.yaml.tpl`.

**Installation notes:**
- Node.js is installed from NodeSource repository for unattended-upgrades support
- OpenCode is installed via npm for automatic updates via npm-global-update

## Configuration

Create `src/config/opencode.config.yaml`:

```yaml
opencode:
  enabled: true
  model: anthropic/claude-sonnet-4-5-latest
  theme: dark

  providers:
    anthropic:
      api_key: "{env:ANTHROPIC_API_KEY}"
```

| Field | Description | Default |
|-------|-------------|---------|
| `enabled` | Install opencode during cloud-init | `false` |
| `model` | Default model (provider/model-id) | `anthropic/claude-sonnet-4-5-latest` |
| `theme` | UI theme | `dark` |
| `autoupdate` | Enable auto-updates | `false` |
| `providers` | Provider configurations | - |
| `auth` | OAuth credentials (auto-derived from Claude Code) | - |
| `auth.anthropic` | Anthropic OAuth (from Claude Code) | - |

---

## Provider Configuration

Providers are configured under `opencode.providers`. Each provider can have:

| Field | Description |
|-------|-------------|
| `api_key` | API key or env reference `{env:VAR_NAME}` |
| `base_url` | Custom API endpoint (optional) |
| `name` | Display name (for custom providers) |
| `models` | Model definitions (for custom/local providers) |

### API Key Options

1. **Environment variable reference** (recommended):
   ```yaml
   api_key: "{env:ANTHROPIC_API_KEY}"
   ```
   Set the environment variable post-deployment.

2. **Post-deployment configuration**:
   ```bash
   opencode
   /connect
   ```

3. **Direct value** (not recommended for cloud-init):
   ```yaml
   api_key: "sk-ant-api03-..."
   ```

---

## Provider Examples

### Anthropic (Claude)

```yaml
opencode:
  enabled: true
  model: anthropic/claude-sonnet-4-5
  providers:
    anthropic:
      api_key: "{env:ANTHROPIC_API_KEY}"
```

### OpenAI

```yaml
opencode:
  enabled: true
  model: openai/gpt-4o
  providers:
    openai:
      api_key: "{env:OPENAI_API_KEY}"
```

### Multiple Providers

```yaml
opencode:
  enabled: true
  model: anthropic/claude-sonnet-4-5
  providers:
    anthropic:
      api_key: "{env:ANTHROPIC_API_KEY}"
    openai:
      api_key: "{env:OPENAI_API_KEY}"
```

### Local Ollama

```yaml
opencode:
  enabled: true
  model: ollama/llama3
  providers:
    ollama:
      base_url: http://localhost:11434/v1
      models:
        llama3:
          name: Llama 3
          context: 8192
        codellama:
          name: Code Llama
          context: 16384
```

### Custom OpenAI-Compatible Provider

```yaml
opencode:
  enabled: true
  model: custom/my-model
  providers:
    custom:
      name: My Provider
      base_url: https://api.example.com/v1
      api_key: "{env:CUSTOM_API_KEY}"
      models:
        my-model:
          name: My Model
          context: 128000
          output: 8192
```

---

## Generated Configuration

The template generates two files:

### Config: `~/.config/opencode/opencode.json`

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-sonnet-4-5-latest",
  "theme": "dark",
  "autoupdate": false,
  "provider": {
    "anthropic": {
      "options": {
        "apiKey": "{env:ANTHROPIC_API_KEY}"
      }
    }
  }
}
```

### Auth: `~/.local/share/opencode/auth.json`

When Claude Code is configured with OAuth credentials:

```json
{
  "anthropic": {
    "type": "oauth",
    "access": "<access_token>",
    "refresh": "<refresh_token>",
    "expires": 1736500000000
  }
}
```

This file is automatically derived from `claude_code.auth.oauth` for the `anthropic` provider.

---

## Post-Deployment Setup

### Set API Key Environment Variable

```bash
# Add to ~/.bashrc or /etc/environment
export ANTHROPIC_API_KEY="sk-ant-api03-..."
```

### Or Use Interactive Setup

```bash
opencode
/connect
# Select provider and authenticate
```

### Verify Configuration

```bash
# Check installation
opencode --version

# List configured providers
opencode auth list

# View config
cat ~/.config/opencode/opencode.json
```

---

## Key Commands

| Command | Description |
|---------|-------------|
| `/connect` | Add/update API key for provider |
| `/models` | Select model |
| `/init` | Generate AGENTS.md for project |
| `/config` | View/edit configuration |
| `/help` | Show all commands |

---

## System Requirements

- Node.js 18+ (installed automatically with npm method)
- Modern terminal emulator (WezTerm, Alacritty, Ghostty, Kitty, Windows Terminal)
- API keys for desired LLM providers

---

## Fragment Ordering

This fragment uses the `77-` prefix to run after Claude Code (75-) and Copilot CLI (76-), since OpenCode can derive its auth from those CLI credentials.

| Fragment | Prefix | Section |
|----------|--------|---------|
| Claude Code | 75- | 6.12 |
| Copilot CLI | 76- | 6.13 |
| OpenCode | 77- | 6.14 |
| UI Touches | 90- | 6.15 |

---

## References

- [OpenCode Documentation](https://opencode.ai/docs)
- [OpenCode Providers](https://opencode.ai/docs/providers)
- [OpenCode GitHub](https://github.com/anomalyco/opencode)
- [Configuration Schema](https://opencode.ai/config.json)
