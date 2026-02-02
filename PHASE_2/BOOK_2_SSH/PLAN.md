# Plan: Book 2 SSH - Fragment Setup

> **WARNING**: Reference `PHASE_2/RULES.md` at time of implementation. All commits must comply with microcommit rules (5-20 lines of code per commit).

**References:**
- Rules: `PHASE_2/RULES.md`
- Initial: `PHASE_2/BOOK_2_SSH/INITIAL.md`

---

## Overview

Create metadata for the SSH fragment. This is an `iso_required` template-only fragment.

---

## Files to Create

### Commit 1: Create `book-2-cloud/ssh/build.yaml`

```yaml
name: ssh
description: SSH server configuration and hardening
iso_required: true
build_order: 25
build_layer: 4
```

Reason: Fragment metadata required for SDK discovery. `iso_required: true` because bare metal needs SSH for headless access.

---

## Template Review

No template changes required - SSH config is hardcoded in template.

---

## Dependencies

This plan depends on:
- BOOK_0 plan (SDK must discover fragments via `build.yaml`)
- BOOK_2_USERS plan (SSH may reference user authorized_keys)

---

## Validation

After all commits:

**Host (file checks):**
- [ ] `build.yaml` exists and is valid YAML

**Builder VM** (via `$SDK.Builder.Stage()` then `$SDK.Builder.Exec()`):
- [ ] `python -m builder render cloud-init --include ssh -o /dev/null` succeeds
- [ ] `make cloud-init INCLUDE=ssh` succeeds
