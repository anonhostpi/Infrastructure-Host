# RESEARCH.BOOK.2.COPILOT.CLI

## Purpose

The `copilot-cli` fragment (`book-2-cloud/copilot-cli/`) installs the GitHub Copilot CLI. One of three AI coding assistant fragments (alongside claude-code and opencode).

**Build metadata:** layer 13, order 76, `iso_required: false`

## Current State

### Completed

- `build.yaml` exists with correct metadata
- `fragment.yaml.tpl` renders Copilot CLI installation
- `tests/13/verifications.ps1` exists for layer 13 testing
- Documentation in `docs/FRAGMENT.md`

### Files

```
book-2-cloud/copilot-cli/
├── build.yaml
├── fragment.yaml.tpl
├── config/
│   ├── copilot_cli.config.yaml          (gitignored, may contain tokens)
│   └── copilot_cli.config.yaml.example
├── docs/FRAGMENT.md
└── tests/13/verifications.ps1
```

## Remaining Work

### Config Naming Convention

The old plan proposed renaming `copilot_cli.config.yaml` to `production.yaml`. Same concern as other fragments.

**Recommendation:** Keep `copilot_cli.config.yaml` as-is.

### Credential Handling

The Builder SDK's `BuildContext` (context.py) has credential fallback logic for Copilot CLI:
- Loads OAuth tokens from `~/.copilot/config.json` on the host
- Extracts `copilot_tokens` (first entry)
- Stores as `copilot_cli.auth.oauth` in the build context

Note: Copilot CLI uses GitHub OAuth which is incompatible with Anthropic tokens. The OpenCode fragment cannot reuse Copilot's GitHub auth directly.

### Template Review

- Verify installation method is current for GitHub Copilot CLI
- Check that credential injection works with BuildContext fallback

## Dependencies

- **Depends on:** base (Book 1), network, users
- **Depended on by:** pkg-security tests (layers 16-18 may use Copilot CLI for AI summaries)
- **Book 0 interaction:** Builder SDK renders with BuildContext credential fallback. Tests at layer 13 verify installation.
