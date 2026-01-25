# Plan: Book 2 Package Upgrade - Fragment Setup

> **WARNING**: Reference `PHASE_2/RULES.md` at time of implementation. All commits must comply with microcommit rules (5-20 lines of code per commit).

**References:**
- Rules: `PHASE_2/RULES.md`
- Initial: `PHASE_2/BOOK_2_PKG_UPGRADE/INITIAL.md`

---

## Overview

Create metadata for the package upgrade fragment. This is a template-only fragment that runs `apt upgrade` as the final step.

---

## Files to Create

### Commit 1: Create `book-2-cloud/pkg-upgrade/build.yaml`

```yaml
name: pkg-upgrade
description: Final package upgrade (apt upgrade)
iso_required: false
build_order: 999
build_layer: 8
```

Reason: Fragment metadata required for SDK discovery. `build_order: 999` ensures this runs LAST after all other packages are installed.

---

## Template Review

No template changes required - runs apt upgrade command.

---

## Dependencies

This plan depends on:
- BOOK_0 plan (SDK must discover fragments via `build.yaml`)
- All other package fragments (this runs last)

---

## Validation

After all commits:

**Host (file checks):**
- [ ] `build.yaml` exists and is valid YAML

**Builder VM** (via `$SDK.Builder.Stage()` then `$SDK.Builder.Exec()`):
- [ ] `python -m builder render cloud-init --include pkg-upgrade -o /dev/null` succeeds
- [ ] `make cloud-init INCLUDE=pkg-upgrade` succeeds
