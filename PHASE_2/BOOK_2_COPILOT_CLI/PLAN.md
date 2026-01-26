# Plan: Book 2 Copilot CLI - Fragment Setup

> **WARNING**: Reference `PHASE_2/RULES.md` at time of implementation. All commits must comply with microcommit rules (5-20 lines of code per commit).

**References:**
- Rules: `PHASE_2/RULES.md`
- Initial: `PHASE_2/BOOK_2_COPILOT_CLI/INITIAL.md`

---

## Overview

Create metadata and restructure config files for the Copilot CLI fragment. This fragment installs the GitHub Copilot CLI.

---

## Files to Create

### Commit 1: Create `book-2-cloud/copilot-cli/build.yaml`

```yaml
name: copilot-cli
description: GitHub Copilot CLI installation
iso_required: false
build_order: 76
build_layer: 13
```

Reason: Fragment metadata required for SDK discovery.

---

## Files to Rename

### Commit 2: Rename config file

**Rename:** `book-2-cloud/copilot-cli/config/copilot_cli.config.yaml` → `book-2-cloud/copilot-cli/config/production.yaml`

Reason: Follow new naming convention.

---

### Commit 3: Rename config example file

**Rename:** `book-2-cloud/copilot-cli/config/copilot_cli.config.yaml.example` → `book-2-cloud/copilot-cli/config/production.yaml.example`

Reason: Follow new naming convention.

---

## Files to Modify

### Commit 4: Update `.gitignore` for copilot-cli config

```diff
-book-2-cloud/copilot-cli/config/*.config.yaml
-!book-2-cloud/copilot-cli/config/*.config.yaml.example
+book-2-cloud/copilot-cli/config/production.yaml
```

Reason: Gitignore the specific production file containing API keys/tokens.

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
- [ ] `production.yaml` exists (renamed from `copilot_cli.config.yaml`)
- [ ] `production.yaml` is gitignored (may contain API keys/tokens)

**Builder VM** (via `$SDK.Builder.Stage()` then `$SDK.Builder.Exec()`):
- [ ] `python -m builder render cloud-init --include copilot-cli -o /dev/null` succeeds
- [ ] `make cloud-init INCLUDE=copilot-cli` succeeds
