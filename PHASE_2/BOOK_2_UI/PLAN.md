# Plan: Book 2 UI - Fragment Setup

> **WARNING**: Reference `PHASE_2/RULES.md` at time of implementation. All commits must comply with microcommit rules (5-20 lines of code per commit).

**References:**
- Rules: `PHASE_2/RULES.md`
- Initial: `PHASE_2/BOOK_2_UI/INITIAL.md`

---

## Overview

Create metadata for the UI fragment. This is a template-only fragment for desktop environment packages.

---

## Files to Create

### Commit 1: Create `book-2-cloud/ui/build.yaml`

```yaml
name: ui
description: Desktop UI packages (optional GUI environment)
iso_required: false
build_order: 90
build_layer: 7
```

Reason: Fragment metadata required for SDK discovery.

---

## Template Review

No template changes required - package list is hardcoded in template.

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
- [ ] `python -m builder render cloud-init --include ui -o /dev/null` succeeds
- [ ] `make cloud-init INCLUDE=ui` succeeds
