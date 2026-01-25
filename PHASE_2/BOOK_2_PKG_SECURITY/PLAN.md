# Plan: Book 2 Package Security - Fragment Setup

> **WARNING**: Reference `PHASE_2/RULES.md` at time of implementation. All commits must comply with microcommit rules (5-20 lines of code per commit).

**References:**
- Rules: `PHASE_2/RULES.md`
- Initial: `PHASE_2/BOOK_2_PKG_SECURITY/INITIAL.md`

---

## Overview

Create metadata for the package security fragment. This is a template-only fragment for security-related packages (fail2ban, etc.).

---

## Files to Create

### Commit 1: Create `book-2-cloud/pkg-security/build.yaml`

```yaml
name: pkg-security
description: Security-related package installation (fail2ban, etc.)
iso_required: false
build_order: 50
build_layer: 8
```

Reason: Fragment metadata required for SDK discovery. Shares `build_order: 50` with packages fragment.

---

## Template Review

No template changes required - package list is hardcoded in template.

---

## Dependencies

This plan depends on:
- BOOK_0 plan (SDK must discover fragments via `build.yaml`)
- BOOK_2_PACKAGES plan (runs in same layer)

---

## Validation

After all commits:

**Host (file checks):**
- [ ] `build.yaml` exists and is valid YAML

**Builder VM** (via `$SDK.Builder.Stage()` then `$SDK.Builder.Exec()`):
- [ ] `python -m builder render cloud-init --include pkg-security -o /dev/null` succeeds
- [ ] `make cloud-init INCLUDE=pkg-security` succeeds
