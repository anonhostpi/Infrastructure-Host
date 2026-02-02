# RESEARCH.BOOK.2.PKG.SECURITY

## Purpose

The `pkg-security` fragment (`book-2-cloud/pkg-security/`) installs security-related packages (fail2ban, etc.) and configures package update notification infrastructure including multi-manager update scripts, report generation, and AI-powered update summaries.

**Build metadata:** layer 8, order 50, `iso_required: false`

## Current State

### Completed

- `build.yaml` exists with correct metadata
- `fragment.yaml.tpl` renders security package installation and notification infrastructure
- Tests exist across multiple layers:
  - `tests/8/verifications.ps1` -- core package security tests
  - `tests/16/verifications.ps1` -- package manager update scripts (snap, npm, pip, brew, deno)
  - `tests/17/verifications.ps1` -- update summary and AI report generation
  - `tests/18/verifications.ps1` -- notification flush
- Documentation in `docs/FRAGMENT.md`

### Files

```
book-2-cloud/pkg-security/
├── build.yaml
├── fragment.yaml.tpl
├── docs/FRAGMENT.md
└── tests/
    ├── 8/verifications.ps1
    ├── 16/verifications.ps1
    ├── 17/verifications.ps1
    └── 18/verifications.ps1
```

## Remaining Work

Minimal. This fragment has no config files to restructure. It is template-only with hardcoded package lists and script content.

### Template Review

This is a substantial fragment -- it installs packages AND sets up a multi-component notification system with:
- apt-notify framework (queue-based update tracking)
- Per-manager update scripts (snap, npm, pip, brew, deno)
- Report generation with optional AI summarization
- Integration with Claude Code, Copilot CLI, or OpenCode for AI summaries

Verify that all embedded scripts in the template are current and compatible with Ubuntu 24.04.

### Test Coverage

This fragment has the most comprehensive test coverage of any fragment, spanning layers 8, 16, 17, and 18. The multi-layer testing validates the full notification pipeline from package installation through AI summary generation.

## Dependencies

- **Depends on:** base (Book 1), network, packages (same layer)
- **Depended on by:** security-mon (may use fail2ban), pkg-upgrade (runs apt upgrade last)
- **Book 0 interaction:** Rendered by Builder SDK at order 50. Tests at layers 16-18 verify the notification infrastructure using the host SDK's `$Worker.Test()` method and `$Worker.Exec()` for setup/teardown.
