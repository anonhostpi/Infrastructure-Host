# RESEARCH.BOOK.2.CLAUDE.CODE

## Purpose

The `claude-code` fragment (`book-2-cloud/claude-code/`) installs the Claude Code AI assistant CLI. One of three AI coding assistant fragments (alongside copilot-cli and opencode).

**Build metadata:** layer 12, order 75, `iso_required: false`

## Current State

### Completed

- `build.yaml` exists with correct metadata
- `fragment.yaml.tpl` renders Claude Code installation
- `tests/12/verifications.ps1` exists for layer 12 testing
- Documentation in `docs/FRAGMENT.md`

### Files

```
book-2-cloud/claude-code/
├── build.yaml
├── fragment.yaml.tpl
├── config/
│   ├── claude_code.config.yaml          (gitignored, may contain API keys)
│   └── claude_code.config.yaml.example
├── docs/FRAGMENT.md
└── tests/12/verifications.ps1
```

## Remaining Work

### Config Naming Convention

The old plan proposed renaming `claude_code.config.yaml` to `production.yaml`. Same concern as other fragments.

**Recommendation:** Keep `claude_code.config.yaml` as-is.

### Credential Handling

The Builder SDK's `BuildContext` (context.py) has special credential fallback logic for Claude Code:
- Loads OAuth tokens from `~/.claude/.credentials.json` on the host
- Extracts `claudeAiOauth.accessToken`, `refreshToken`, `expiresAt`
- Stores as `claude_code.auth.oauth` in the build context

This means the config file may not need to contain credentials if the host machine has Claude Code already authenticated. The template should handle both cases (explicit config vs. host credential fallback).

### Template Review

- Verify installation method is current (npm global install, direct download, etc.)
- Check that OAuth credential injection works correctly with the BuildContext fallback

## Dependencies

- **Depends on:** base (Book 1), network, users
- **Depended on by:** pkg-security tests (layers 16-18 may use Claude Code for AI summaries)
- **Book 0 interaction:** Builder SDK renders with BuildContext credential fallback. Tests at layer 12 verify installation. The pkg-security notification system can use Claude Code for AI-powered update summaries.
