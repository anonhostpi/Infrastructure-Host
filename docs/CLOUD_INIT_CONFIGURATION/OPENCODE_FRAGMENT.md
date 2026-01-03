# 6.12 OpenCode Fragment

**Template:** `src/autoinstall/cloud-init/75-opencode.yaml.tpl`

Installs and configures OpenCode, an open-source AI coding agent for terminal use.

## Overview

[OpenCode](https://github.com/anomalyco/opencode) is an AI-powered coding assistant available as a terminal interface. It helps with code navigation, feature implementation, and codebase understanding.

## Template

```yaml
{% if opencode.enabled | default(false) %}
runcmd:
{% if opencode.install_method | default('npm') == 'npm' %}
  # Install Node.js via NodeSource (LTS)
  - curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
  - apt-get install -y nodejs
  # Install opencode globally
  - npm install -g opencode-ai
{% elif opencode.install_method == 'script' %}
  # Install via official script
  - curl -fsSL https://opencode.ai/install | bash
{% endif %}
{% endif %}
```

## Configuration

Create `src/config/opencode.config.yaml`:

```yaml
opencode:
  enabled: true
  install_method: npm    # npm, script
```

| Field | Description | Default |
|-------|-------------|---------|
| `enabled` | Install opencode during cloud-init | `false` |
| `install_method` | Installation method | `npm` |

### Installation Methods

| Method | Description |
|--------|-------------|
| `npm` | Install via npm (requires Node.js, installed automatically) |
| `script` | Install via official install script |

## Post-Deployment Setup

After deployment, configure OpenCode with your API keys:

```bash
# Launch opencode
opencode

# Inside the TUI, connect to a provider
/connect
```

### Provider Setup

1. Select a provider (Anthropic, OpenAI, etc.)
2. Authenticate or enter API key
3. Select default model via `/models`

API keys are stored in `~/.local/share/opencode/auth.json` (not in cloud-init config).

## OpenCode Configuration

OpenCode uses JSON configuration files:

| Location | Scope |
|----------|-------|
| `~/.config/opencode/opencode.json` | Global settings |
| `./opencode.json` | Project-specific settings |

### Example Global Configuration

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-sonnet-4-5",
  "theme": "dark",
  "autoupdate": "notify"
}
```

### Example Project Configuration

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-sonnet-4-5",
  "instructions": ["AGENTS.md"]
}
```

Run `/init` in a project to generate an `AGENTS.md` file with project context.

## Provider Examples

### Anthropic (Claude)

```bash
# In opencode TUI
/connect
# Select "Anthropic"
# Choose authentication method
```

### OpenAI

```bash
/connect
# Search for "OpenAI"
# Enter API key from platform.openai.com
```

### Local Models (Ollama)

Add to `~/.config/opencode/opencode.json`:

```json
{
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (local)",
      "options": {
        "baseURL": "http://localhost:11434/v1"
      },
      "models": {
        "llama2": {"name": "Llama 2"},
        "codellama": {"name": "Code Llama"}
      }
    }
  }
}
```

## Key Commands

| Command | Description |
|---------|-------------|
| `/connect` | Add API key for provider |
| `/models` | Select model |
| `/init` | Generate AGENTS.md for project |
| `/help` | Show all commands |

## Verification

```bash
# Check installation
opencode --version

# List configured providers
opencode auth list
```

## System Requirements

- Node.js 18+ (installed automatically with npm method)
- Modern terminal emulator (WezTerm, Alacritty, Ghostty, Kitty)
- API keys for desired LLM providers

## Fragment Ordering

This fragment uses the `75-` prefix to run after Cockpit (70-) but before UI Touches (90-).

---

## Alternative: User-Level Installation

If you prefer user-level installation instead of system-wide:

```bash
# As the admin user
npm install -g opencode-ai

# Or via install script
curl -fsSL https://opencode.ai/install | bash
```

This installs to `~/.local/bin` or `~/.npm-global/bin` instead of system paths.

---

## References

- [OpenCode Documentation](https://opencode.ai/docs)
- [OpenCode GitHub](https://github.com/anomalyco/opencode)
- [Configuration Schema](https://opencode.ai/config.json)
