# RESEARCH.BOOK.2.OPENCODE

## Purpose

The `opencode` fragment (`book-2-cloud/opencode/`) installs the OpenCode AI assistant. One of three AI coding assistant fragments (alongside claude-code and copilot-cli).

**Build metadata:** layer 14, order 77, `iso_required: false`

## Current State

### Completed

- `build.yaml` exists with correct metadata
- `fragment.yaml.tpl` renders OpenCode installation
- `tests/14/verifications.ps1` exists for layer 14 testing
- Documentation in `docs/FRAGMENT.md`

### Files

```
book-2-cloud/opencode/
├── build.yaml
├── fragment.yaml.tpl
├── config/
│   ├── opencode.config.yaml          (gitignored, may contain API keys)
│   └── opencode.config.yaml.example
├── docs/FRAGMENT.md
└── tests/14/verifications.ps1
```

## Remaining Work

### Config Naming Convention

The old plan proposed renaming `opencode.config.yaml` to `production.yaml`. Same concern as other fragments.

**Recommendation:** Keep `opencode.config.yaml` as-is.

### Credential Handling

The Builder SDK's `BuildContext` (context.py) derives OpenCode credentials from the other AI assistant configs:
- Anthropic auth from claude-code config
- GitHub Copilot requires separate auth (incompatible token formats between Anthropic and GitHub OAuth)

This means OpenCode's config may partially overlap with claude-code's. The template should handle the case where some credentials come from BuildContext fallbacks rather than explicit config.

### Template Review

- Verify OpenCode installation method is current
- Check that credential derivation from other AI assistant configs works correctly

## Dependencies

- **Depends on:** base (Book 1), network, users, claude-code (credential derivation), copilot-cli (credential derivation)
- **Depended on by:** pkg-security tests (layers 16-18 may use OpenCode for AI summaries)
- **Book 0 interaction:** Builder SDK renders with BuildContext credential derivation. Tests at layer 14 verify installation.
