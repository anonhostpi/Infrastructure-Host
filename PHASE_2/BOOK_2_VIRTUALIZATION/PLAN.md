# Plan: Book 2 Virtualization - Fragment Setup

> **WARNING**: Reference `PHASE_2/RULES.md` at time of implementation. All commits must comply with microcommit rules (5-20 lines of code per commit).

**References:**
- Rules: `PHASE_2/RULES.md`
- Initial: `PHASE_2/BOOK_2_VIRTUALIZATION/INITIAL.md`

---

## Overview

Create metadata for the virtualization fragment. This is a template-only fragment for KVM/QEMU packages and configuration.

---

## Files to Create

### Commit 1: Create `book-2-cloud/virtualization/build.yaml`

```yaml
name: virtualization
description: KVM/QEMU virtualization packages and configuration
iso_required: false
build_order: 60
build_layer: 10
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
- [ ] `python -m builder render cloud-init --include virtualization -o /dev/null` succeeds
- [ ] `make cloud-init INCLUDE=virtualization` succeeds
