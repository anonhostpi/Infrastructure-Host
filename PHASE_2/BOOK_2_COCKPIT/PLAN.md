# Plan: Book 2 Cockpit - Fragment Setup

> **WARNING**: Reference `PHASE_2/RULES.md` at time of implementation. All commits must comply with microcommit rules (5-20 lines of code per commit).

**References:**
- Rules: `PHASE_2/RULES.md`
- Initial: `PHASE_2/BOOK_2_COCKPIT/INITIAL.md`

---

## Overview

Create metadata and restructure config files for the Cockpit fragment. This fragment provides web-based server management.

---

## Files to Create

### Commit 1: Create `book-2-cloud/cockpit/build.yaml`

```yaml
name: cockpit
description: Cockpit web-based server management interface
iso_required: false
build_order: 70
build_layer: 7
```

Reason: Fragment metadata required for SDK discovery.

---

## Files to Rename

### Commit 2: Rename config file

**Rename:** `book-2-cloud/cockpit/config/cockpit.config.yaml` → `book-2-cloud/cockpit/config/production.yaml`

Reason: Follow new naming convention.

---

### Commit 3: Rename config example file

**Rename:** `book-2-cloud/cockpit/config/cockpit.config.yaml.example` → `book-2-cloud/cockpit/config/production.yaml.example`

Reason: Follow new naming convention.

---

## Files to Modify

### Commit 4: Update `.gitignore` for cockpit config

```diff
-book-2-cloud/cockpit/config/*.config.yaml
-!book-2-cloud/cockpit/config/*.config.yaml.example
+book-2-cloud/cockpit/config/production.yaml
```

Reason: Gitignore the specific production file.

---

## Template Review

No template changes required - config keys remain the same, only filenames change.

---

## Dependencies

This plan depends on:
- BOOK_0 plan (SDK must discover fragments via `build.yaml`)
- BOOK_2_USERS plan (Cockpit may reference user accounts)

---

## Validation

After all commits:

**Host (file checks):**
- [ ] `build.yaml` exists and is valid YAML
- [ ] `production.yaml` exists (renamed from `cockpit.config.yaml`)

**Builder VM** (via `$SDK.Builder.Stage()` then `$SDK.Builder.Exec()`):
- [ ] `python -m builder render cloud-init --include cockpit -o /dev/null` succeeds
- [ ] `make cloud-init INCLUDE=cockpit` succeeds
