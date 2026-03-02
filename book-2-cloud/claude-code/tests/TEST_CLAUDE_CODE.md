# Test 6.12: Claude Code Fragment

**Template:** `book-2-cloud/claude-code/fragment.yaml.tpl`
**Fragment Docs:** [6.12 Claude Code Fragment](../docs/FRAGMENT.md)

Tests Anthropic's Claude Code CLI installation and configuration.

**Note:** These tests only apply if `claude_code.config.yaml` has `enabled: true`.

---

## Test 6.12.1: Claude Code Installation

```bash
# On VM: Verify claude installed
which claude
# Expected: /home/<admin_user>/.claude/local/bin/claude or similar

claude --version
# Expected: Shows version number
```

| Check | Command | Expected |
|-------|---------|----------|
| claude binary | `which claude` | Path shown |
| claude version | `claude --version` | Shows version |

---

## Test 6.12.2: Configuration Directory

```bash
# On VM: Verify config directory exists with correct ownership
ls -la /home/<admin_user>/.claude/
# Expected: Directory owned by admin user

stat -c "%U:%G" /home/<admin_user>/.claude/
# Expected: <admin_user>:<admin_user>
```

| Check | Command | Expected |
|-------|---------|----------|
| Config dir exists | `test -d ~/.claude` | Directory exists |
| Correct ownership | `stat -c "%U:%G" ~/.claude` | admin:admin |

---

## Test 6.12.3: Settings File

```bash
# On VM: Verify settings.json exists
ls -la /home/<admin_user>/.claude/settings.json
# Expected: File exists with correct permissions

cat /home/<admin_user>/.claude/settings.json | jq '.'
# Expected: Valid JSON
```

| Check | Command | Expected |
|-------|---------|----------|
| Settings file exists | `test -f ~/.claude/settings.json` | File exists |
| Valid JSON | `jq '.' ~/.claude/settings.json` | No errors |

---

## Test 6.12.4: Authentication Configuration

Claude Code supports two authentication methods:

1. **OAuth (Claude Pro/Max subscription):** `.credentials.json` + `hasCompletedOnboarding` in state
2. **API Key:** `ANTHROPIC_API_KEY` environment variable

```bash
# On VM: Check for OAuth credentials
test -f /home/<admin_user>/.claude/.credentials.json && echo "OAuth credentials found"

# Check for completed onboarding
grep -q 'hasCompletedOnboarding' /home/<admin_user>/.claude.json && echo "Onboarding complete"

# Check for API key (fallback)
grep -q 'ANTHROPIC_API_KEY' /etc/environment && echo "API key configured"
```

| Check | Command | Expected |
|-------|---------|----------|
| OAuth creds | `test -f ~/.claude/.credentials.json` | File exists (if OAuth) |
| Onboarding | `grep 'hasCompletedOnboarding' ~/.claude.json` | Found (if OAuth) |
| API key | `grep 'ANTHROPIC_API_KEY' /etc/environment` | Found (if API key auth) |

---

## Test 6.12.5: AI Response Test

```bash
# On VM: Test Claude Code can respond (requires valid auth)
echo "Say 'hello' and nothing else" | claude --print
# Expected: Response containing "hello" (case-insensitive)
```

| Check | Command | Expected |
|-------|---------|----------|
| AI response | `echo "Say hello" \| claude --print` | Contains "hello" |

---

## PowerShell Test Commands

```powershell
# Run from host with multipass VM
$VMName = "cloud-init-runner"
$AdminUser = "admin"  # Replace with configured username

multipass exec $VMName -- which claude
multipass exec $VMName -- claude --version
multipass exec $VMName -- ls -la /home/$AdminUser/.claude/
multipass exec $VMName -- sudo test -f /home/$AdminUser/.claude/settings.json
multipass exec $VMName -- sudo cat /home/$AdminUser/.claude/settings.json
multipass exec $VMName -- sudo test -f /home/$AdminUser/.claude/.credentials.json
```

---

## Skip Conditions

These tests should be **skipped** if:

1. `claude_code.enabled` is `false` or not set in configuration
2. The `claude_code.config.yaml` file does not exist

```bash
# On VM: Check if Claude Code was configured
which claude && echo "Claude Code configured" || echo "Claude Code not configured - SKIP TESTS"
```
