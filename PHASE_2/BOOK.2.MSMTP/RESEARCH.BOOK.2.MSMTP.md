# RESEARCH.BOOK.2.MSMTP

## Purpose

The `msmtp` fragment (`book-2-cloud/msmtp/`) configures MSMTP as a lightweight SMTP relay for system mail. This allows the server to send email notifications (cron job failures, security alerts, etc.) through an external SMTP server.

**Build metadata:** layer 7, order 45, `iso_required: false`

## Current State

### Completed

- `build.yaml` exists with correct metadata
- `fragment.yaml.tpl` renders MSMTP configuration
- `tests/7/verifications.ps1` exists for layer 7 testing
- Documentation in `docs/FRAGMENT.md`

### Files

```
book-2-cloud/msmtp/
├── build.yaml
├── fragment.yaml.tpl
├── config/
│   ├── smtp.config.yaml          (gitignored, contains SMTP credentials)
│   └── smtp.config.yaml.example
├── docs/FRAGMENT.md
└── tests/7/verifications.ps1
```

## Remaining Work

### Config Naming Convention

The old plan proposed renaming `smtp.config.yaml` to `production.yaml`. Same concern as other fragments: breaks `*.config.yaml` glob in both SDKs.

**Recommendation:** Keep `smtp.config.yaml` as-is. The name clearly identifies the content (SMTP credentials), and both SDKs load it correctly via the `*.config.yaml` glob.

### Security Note

Config contains SMTP credentials (server, username, password). The gitignore pattern protects this file. Verify the example file does not contain real credentials.

## Dependencies

- **Depends on:** base (Book 1), network (needs outbound connectivity)
- **Depended on by:** None directly, but other fragments may rely on system mail being configured for notifications
- **Book 0 interaction:** Builder SDK renders this template with BuildContext loading SMTP config. Template variables use `smtp.*` keys.
