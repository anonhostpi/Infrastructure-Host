# Plan: Book 2 OpenCode - Fragment Setup

> **WARNING**: Reference `PHASE_2/RULES.md` at time of implementation. All commits must comply with microcommit rules (5-20 lines of code per commit).

**References:**
- Rules: `PHASE_2/RULES.md`
- Initial: `PHASE_2/BOOK_2_OPENCODE/INITIAL.md`

---

## Overview

Create metadata and restructure config files for the OpenCode fragment. This fragment installs the OpenCode AI assistant.

---

## Files to Create

### Commit 1: Create `book-2-cloud/opencode/build.yaml`

```yaml
name: opencode
description: OpenCode AI assistant installation
iso_required: false
build_order: 77
build_layer: 14
```

Reason: Fragment metadata required for SDK discovery.

---

## Files to Rename

### Commit 2: Rename config file

**Rename:** `book-2-cloud/opencode/config/opencode.config.yaml` → `book-2-cloud/opencode/config/production.yaml`

Reason: Follow new naming convention.

---

### Commit 3: Rename config example file

**Rename:** `book-2-cloud/opencode/config/opencode.config.yaml.example` → `book-2-cloud/opencode/config/production.yaml.example`

Reason: Follow new naming convention.

---

## Files to Modify

### Commit 4: Update `.gitignore` for opencode config

```diff
-book-2-cloud/opencode/config/*.config.yaml
-!book-2-cloud/opencode/config/*.config.yaml.example
+book-2-cloud/opencode/config/production.yaml
```

Reason: Gitignore the specific production file containing API keys.

---

## Template Review

No template changes required - config keys remain the same, only filenames change.

---

## Dependencies

This plan depends on:
- BOOK_0 plan (SDK must discover fragments via `build.yaml`)

---

## Validation

After all commits:

**Host (file checks):**
- [ ] `build.yaml` exists and is valid YAML
- [ ] `production.yaml` exists (renamed from `opencode.config.yaml`)
- [ ] `production.yaml` is gitignored (may contain API keys)

**Builder VM** (via `$SDK.Builder.Stage()` then `$SDK.Builder.Exec()`):
- [ ] `python -m builder render cloud-init --include opencode -o /dev/null` succeeds
- [ ] `make cloud-init INCLUDE=opencode` succeeds
