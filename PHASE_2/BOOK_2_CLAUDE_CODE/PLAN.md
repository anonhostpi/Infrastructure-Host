# Plan: Book 2 Claude Code - Fragment Setup

> **WARNING**: Reference `PHASE_2/RULES.md` at time of implementation. All commits must comply with microcommit rules (5-20 lines of code per commit).

**References:**
- Rules: `PHASE_2/RULES.md`
- Initial: `PHASE_2/BOOK_2_CLAUDE_CODE/INITIAL.md`

---

## Overview

Create metadata and restructure config files for the Claude Code fragment. This fragment installs the Claude Code AI assistant CLI.

---

## Files to Create

### Commit 1: Create `book-2-cloud/claude-code/build.yaml`

```yaml
name: claude-code
description: Claude Code AI assistant CLI installation
iso_required: false
build_order: 75
build_layer: 7
```

Reason: Fragment metadata required for SDK discovery.

---

## Files to Rename

### Commit 2: Rename config file

**Rename:** `book-2-cloud/claude-code/config/claude_code.config.yaml` → `book-2-cloud/claude-code/config/production.yaml`

Reason: Follow new naming convention.

---

### Commit 3: Rename config example file

**Rename:** `book-2-cloud/claude-code/config/claude_code.config.yaml.example` → `book-2-cloud/claude-code/config/production.yaml.example`

Reason: Follow new naming convention.

---

## Files to Modify

### Commit 4: Update `.gitignore` for claude-code config

```diff
-book-2-cloud/claude-code/config/*.config.yaml
-!book-2-cloud/claude-code/config/*.config.yaml.example
+book-2-cloud/claude-code/config/production.yaml
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
- [ ] `production.yaml` exists (renamed from `claude_code.config.yaml`)
- [ ] `production.yaml` is gitignored (may contain API keys)

**Builder VM** (via `$SDK.Builder.Stage()` then `$SDK.Builder.Exec()`):
- [ ] `python -m builder render cloud-init --include claude-code -o /dev/null` succeeds
- [ ] `make cloud-init INCLUDE=claude-code` succeeds
