# Test 6.13: Copilot CLI Fragment

**Template:** `book-2-cloud/copilot-cli/fragment.yaml.tpl`
**Fragment Docs:** [6.13 Copilot CLI Fragment](../../CLOUD_INIT_CONFIGURATION/COPILOT_CLI_FRAGMENT.md)

Tests GitHub Copilot CLI installation and configuration.

**Note:** These tests only apply if `copilot_cli.config.yaml` has `enabled: true`.

---

## Test 6.13.1: Copilot CLI Installation

```bash
# On VM: Verify copilot installed (via npm)
which copilot
# Expected: /usr/bin/copilot or /usr/local/bin/copilot

copilot --version
# Expected: Shows version number
```

| Check | Command | Expected |
|-------|---------|----------|
| copilot binary | `which copilot` | Path shown |
| copilot version | `copilot --version` | Shows version |

---

## Test 6.13.2: Configuration Directory

```bash
# On VM: Verify config directory exists with correct ownership
ls -la /home/<admin_user>/.copilot/
# Expected: Directory owned by admin user

stat -c "%U:%G" /home/<admin_user>/.copilot/
# Expected: <admin_user>:<admin_user>
```

| Check | Command | Expected |
|-------|---------|----------|
| Config dir exists | `test -d ~/.copilot` | Directory exists |
| Correct ownership | `stat -c "%U:%G" ~/.copilot` | admin:admin |

---

## Test 6.13.3: Configuration File

```bash
# On VM: Verify config.json exists
ls -la /home/<admin_user>/.copilot/config.json
# Expected: File exists with correct permissions

cat /home/<admin_user>/.copilot/config.json | jq '.'
# Expected: Valid JSON
```

| Check | Command | Expected |
|-------|---------|----------|
| Config file exists | `test -f ~/.copilot/config.json` | File exists |
| Valid JSON | `jq '.' ~/.copilot/config.json` | No errors |

---

## Test 6.13.4: Authentication Configuration

Copilot CLI supports two authentication methods:

1. **OAuth tokens:** `copilot_tokens` in config.json (from GitHub OAuth flow)
2. **GitHub Token:** `GH_TOKEN` environment variable

```bash
# On VM: Check for OAuth tokens in config
grep -q 'copilot_tokens' /home/<admin_user>/.copilot/config.json && echo "OAuth tokens found"

# Check for GH_TOKEN environment variable (fallback)
grep -q 'GH_TOKEN' /etc/environment && echo "GH_TOKEN configured"
```

| Check | Command | Expected |
|-------|---------|----------|
| OAuth tokens | `grep 'copilot_tokens' ~/.copilot/config.json` | Found (if OAuth) |
| GH_TOKEN | `grep 'GH_TOKEN' /etc/environment` | Found (if token auth) |

---

## Test 6.13.5: AI Response Test

```bash
# On VM: Test Copilot CLI can respond (requires valid auth)
echo "Say 'hello' and nothing else" | copilot
# Expected: Response containing "hello" (case-insensitive)
```

| Check | Command | Expected |
|-------|---------|----------|
| AI response | `echo "Say hello" \| copilot` | Contains "hello" |

---

## PowerShell Test Commands

```powershell
# Run from host with multipass VM
$VMName = "cloud-init-runner"
$AdminUser = "admin"  # Replace with configured username

multipass exec $VMName -- which copilot
multipass exec $VMName -- copilot --version
multipass exec $VMName -- ls -la /home/$AdminUser/.copilot/
multipass exec $VMName -- sudo test -f /home/$AdminUser/.copilot/config.json
multipass exec $VMName -- sudo cat /home/$AdminUser/.copilot/config.json
multipass exec $VMName -- sudo grep 'copilot_tokens' /home/$AdminUser/.copilot/config.json
```

---

## Skip Conditions

These tests should be **skipped** if:

1. `copilot_cli.enabled` is `false` or not set in configuration
2. The `copilot_cli.config.yaml` file does not exist

```bash
# On VM: Check if Copilot CLI was configured
which copilot && echo "Copilot CLI configured" || echo "Copilot CLI not configured - SKIP TESTS"
```
