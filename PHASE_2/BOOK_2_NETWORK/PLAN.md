# Plan: Book 2 Network - Fragment Setup

> **WARNING**: Reference `PHASE_2/RULES.md` at time of implementation. All commits must comply with microcommit rules (5-20 lines of code per commit).

**References:**
- Rules: `PHASE_2/RULES.md`
- Initial: `PHASE_2/BOOK_2_NETWORK/INITIAL.md`

---

## Overview

Create metadata and restructure config files for the network fragment. This is an `iso_required` fragment that provides static IP configuration.

---

## Files to Create

### Commit 1: Create `book-2-cloud/network/build.yaml`

```yaml
name: network
description: Static IP configuration via arping detection
iso_required: true
build_order: 10
build_layer: 1
```

Reason: Fragment metadata required for SDK discovery. First cloud-init fragment (`build_order: 10`).

---

## Files to Rename

### Commit 2: Rename config file

**Rename:** `book-2-cloud/network/config/network.config.yaml` → `book-2-cloud/network/config/production.yaml`

Reason: Follow new naming convention.

---

### Commit 3: Rename config example file

**Rename:** `book-2-cloud/network/config/network.config.yaml.example` → `book-2-cloud/network/config/production.yaml.example`

Reason: Follow new naming convention.

---

## Files to Modify

### Commit 4: Update `.gitignore` for network config

```diff
-book-2-cloud/network/config/*.config.yaml
-!book-2-cloud/network/config/*.config.yaml.example
+book-2-cloud/network/config/production.yaml
```

Reason: Gitignore the specific production file, not wildcards.

---

## Template Review

No template changes required - config keys remain the same, only filenames change.

---

## Dependencies

This plan depends on:
- BOOK_0 plan (SDK must discover fragments via `build.yaml`)
- BOOK_1_BASE plan (base fragment must exist)

This plan blocks:
- Most other BOOK_2 plans (network is typically configured first)

---

## Validation

After all commits:

**Host (file checks):**
- [ ] `build.yaml` exists and is valid YAML
- [ ] `production.yaml` exists (renamed from `network.config.yaml`)

**Builder VM** (via `$SDK.Builder.Stage()` then `$SDK.Builder.Exec()`):
- [ ] `python -m builder render cloud-init --include network -o /dev/null` succeeds
- [ ] `make cloud-init INCLUDE=network` succeeds
