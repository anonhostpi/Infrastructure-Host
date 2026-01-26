# Plan: Book 2 System - Fragment Setup

> **WARNING**: Reference `PHASE_2/RULES.md` at time of implementation. All commits must comply with microcommit rules (5-20 lines of code per commit).

**References:**
- Rules: `PHASE_2/RULES.md`
- Initial: `PHASE_2/BOOK_2_SYSTEM/INITIAL.md`

---

## Overview

Create metadata for the system fragment. This is a template-only fragment for timezone, locale, and hostname configuration.

---

## Files to Create

### Commit 1: Create `book-2-cloud/system/build.yaml`

```yaml
name: system
description: System configuration (timezone, locale, hostname)
iso_required: false
build_order: 40
build_layer: 6
```

Reason: Fragment metadata required for SDK discovery.

---

## Template Review

No template changes required - system settings are hardcoded in template.

---

## Dependencies

This plan depends on:
- BOOK_0 plan (SDK must discover fragments via `build.yaml`)

---

## Validation

After all commits:

**Host (file checks):**
- [ ] `build.yaml` exists and is valid YAML

**Builder VM** (via `$SDK.Builder.Stage()` then `$SDK.Builder.Exec()`):
- [ ] `python -m builder render cloud-init --include system -o /dev/null` succeeds
- [ ] `make cloud-init INCLUDE=system` succeeds
