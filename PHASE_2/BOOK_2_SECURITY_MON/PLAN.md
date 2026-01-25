# Plan: Book 2 Security Monitoring - Fragment Setup

> **WARNING**: Reference `PHASE_2/RULES.md` at time of implementation. All commits must comply with microcommit rules (5-20 lines of code per commit).

**References:**
- Rules: `PHASE_2/RULES.md`
- Initial: `PHASE_2/BOOK_2_SECURITY_MON/INITIAL.md`

---

## Overview

Create metadata for the security monitoring fragment. This is a template-only fragment for security monitoring tools (auditd, AIDE, etc.).

---

## Files to Create

### Commit 1: Create `book-2-cloud/security-mon/build.yaml`

```yaml
name: security-mon
description: Security monitoring configuration (auditd, AIDE, etc.)
iso_required: false
build_order: 55
build_layer: 8
```

Reason: Fragment metadata required for SDK discovery.

---

## Template Review

No template changes required - configuration is hardcoded in template.

---

## Dependencies

This plan depends on:
- BOOK_0 plan (SDK must discover fragments via `build.yaml`)
- BOOK_2_PKG_SECURITY plan (security packages installed first)

---

## Validation

After all commits:

**Host (file checks):**
- [ ] `build.yaml` exists and is valid YAML

**Builder VM** (via `$SDK.Builder.Stage()` then `$SDK.Builder.Exec()`):
- [ ] `python -m builder render cloud-init --include security-mon -o /dev/null` succeeds
- [ ] `make cloud-init INCLUDE=security-mon` succeeds
