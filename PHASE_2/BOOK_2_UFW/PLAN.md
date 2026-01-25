# Plan: Book 2 UFW - Fragment Setup

> **WARNING**: Reference `PHASE_2/RULES.md` at time of implementation. All commits must comply with microcommit rules (5-20 lines of code per commit).

**References:**
- Rules: `PHASE_2/RULES.md`
- Initial: `PHASE_2/BOOK_2_UFW/INITIAL.md`

---

## Overview

Create metadata for the UFW (Uncomplicated Firewall) fragment. This is a template-only fragment.

---

## Files to Create

### Commit 1: Create `book-2-cloud/ufw/build.yaml`

```yaml
name: ufw
description: Uncomplicated Firewall configuration
iso_required: false
build_order: 30
build_layer: 4
```

Reason: Fragment metadata required for SDK discovery.

---

## Template Review

No template changes required - firewall rules are hardcoded in template.

---

## Dependencies

This plan depends on:
- BOOK_0 plan (SDK must discover fragments via `build.yaml`)
- BOOK_2_SSH plan (UFW should allow SSH port 22)

---

## Validation

After all commits:

**Host (file checks):**
- [ ] `build.yaml` exists and is valid YAML

**Builder VM** (via `$SDK.Builder.Stage()` then `$SDK.Builder.Exec()`):
- [ ] `python -m builder render cloud-init --include ufw -o /dev/null` succeeds
- [ ] `make cloud-init INCLUDE=ufw` succeeds
