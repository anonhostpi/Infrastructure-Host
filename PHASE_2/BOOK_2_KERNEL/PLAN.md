# Plan: Book 2 Kernel - Fragment Setup

> **WARNING**: Reference `PHASE_2/RULES.md` at time of implementation. All commits must comply with microcommit rules (5-20 lines of code per commit).

**References:**
- Rules: `PHASE_2/RULES.md`
- Initial: `PHASE_2/BOOK_2_KERNEL/INITIAL.md`

---

## Overview

Create metadata for the kernel fragment. This is a template-only fragment with no config files.

---

## Files to Create

### Commit 1: Create `book-2-cloud/kernel/build.yaml`

```yaml
name: kernel
description: Kernel hardening and sysctl configuration
iso_required: false
build_order: 15
build_layer: 2
```

Reason: Fragment metadata required for SDK discovery.

---

## Template Review

No template changes required - this is a self-contained fragment with hardcoded sysctl values.

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
- [ ] `python -m builder render cloud-init --include kernel -o /dev/null` succeeds
- [ ] `make cloud-init INCLUDE=kernel` succeeds
