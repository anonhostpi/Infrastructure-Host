# Test 6.14: OpenCode Fragment

**Template:** `src/autoinstall/cloud-init/77-opencode.yaml.tpl`
**Fragment Docs:** [6.14 OpenCode Fragment](../../CLOUD_INIT_CONFIGURATION/OPENCODE_FRAGMENT.md)

Tests OpenCode AI coding agent installation and configuration.

**Note:** These tests only apply if `opencode.config.yaml` has `enabled: true`.

---

## Test 6.14.1: Node.js Installation (npm method)

```bash
# On VM: Verify Node.js installed
node --version
# Expected: v18.x or higher (LTS)

npm --version
# Expected: Shows version
```

| Check | Command | Expected |
|-------|---------|----------|
| Node.js | `node --version` | v18+ |
| npm | `npm --version` | Shows version |

---

## Test 6.14.2: OpenCode Installation

```bash
# On VM: Verify opencode installed globally
which opencode
# Expected: /usr/bin/opencode or /usr/local/bin/opencode

opencode --version
# Expected: Shows version number
```

| Check | Command | Expected |
|-------|---------|----------|
| opencode binary | `which opencode` | Path shown |
| opencode version | `opencode --version` | Shows version |

---

## Test 6.14.3: Configuration Directory

```bash
# On VM: Verify config directory exists with correct ownership
ls -la /home/<admin_user>/.config/opencode/
# Expected: Directory owned by admin user

stat -c "%U:%G" /home/<admin_user>/.config/opencode/
# Expected: <admin_user>:<admin_user>
```

| Check | Command | Expected |
|-------|---------|----------|
| Config dir exists | `test -d ~/.config/opencode` | Directory exists |
| Correct ownership | `stat -c "%U:%G" ~/.config/opencode` | admin:admin |

---

## Test 6.14.4: Configuration File

```bash
# On VM: Verify opencode.json exists with correct permissions
ls -la /home/<admin_user>/.config/opencode/opencode.json
# Expected: -rw------- (600)

stat -c "%a" /home/<admin_user>/.config/opencode/opencode.json
# Expected: 600
```

| Check | Command | Expected |
|-------|---------|----------|
| Config file exists | `test -f ~/.config/opencode/opencode.json` | File exists |
| Permissions | `stat -c "%a" ~/.config/opencode/opencode.json` | 600 |

---

## Test 6.14.5: Configuration Content

```bash
# On VM: Verify config contains expected fields
cat /home/<admin_user>/.config/opencode/opencode.json | jq '.model'
# Expected: Configured model (e.g., "anthropic/claude-sonnet-4-5")

cat /home/<admin_user>/.config/opencode/opencode.json | jq '.theme'
# Expected: Configured theme (e.g., "dark")
```

| Check | Command | Expected |
|-------|---------|----------|
| model field | `jq '.model' ~/.config/opencode/opencode.json` | Configured value |
| theme field | `jq '.theme' ~/.config/opencode/opencode.json` | Configured value |
| Valid JSON | `jq '.' ~/.config/opencode/opencode.json` | No errors |

---

## Test 6.14.6: Provider Configuration

```bash
# On VM: Verify provider configured (if set)
cat /home/<admin_user>/.config/opencode/opencode.json | jq '.provider'
# Expected: Shows configured providers object

# Example for Anthropic provider:
cat /home/<admin_user>/.config/opencode/opencode.json | jq '.provider.anthropic'
# Expected: Shows anthropic provider config
```

---

## Test 6.14.7: Environment Variable Reference

```bash
# On VM: Check if API key uses environment variable reference
cat /home/<admin_user>/.config/opencode/opencode.json | jq '.provider.anthropic.options.apiKey'
# Expected: "{env:ANTHROPIC_API_KEY}" (if using env reference)
```

---

## Test 6.14.8: OpenCode Launch (Manual)

```bash
# On VM: Test opencode can launch
opencode --help
# Expected: Shows help output

# Interactive test (requires API key):
# export ANTHROPIC_API_KEY="sk-ant-..."
# opencode
# /help
# Expected: Opens interface, shows help
```

---

## PowerShell Test Commands

```powershell
# Run from host with multipass VM
$VMName = "cloud-init-test"
$AdminUser = "admin"  # Replace with configured username

multipass exec $VMName -- node --version
multipass exec $VMName -- npm --version
multipass exec $VMName -- which opencode
multipass exec $VMName -- opencode --version
multipass exec $VMName -- ls -la /home/$AdminUser/.config/opencode/
multipass exec $VMName -- stat -c "%a %U:%G" /home/$AdminUser/.config/opencode/opencode.json
multipass exec $VMName -- cat /home/$AdminUser/.config/opencode/opencode.json
multipass exec $VMName -- jq '.' /home/$AdminUser/.config/opencode/opencode.json
```

---

## Skip Conditions

These tests should be **skipped** if:

1. `opencode.enabled` is `false` or not set in configuration
2. The `opencode.config.yaml` file does not exist

```bash
# On VM: Check if opencode was configured
test -f /home/<admin_user>/.config/opencode/opencode.json && echo "OpenCode configured" || echo "OpenCode not configured - SKIP TESTS"
```
