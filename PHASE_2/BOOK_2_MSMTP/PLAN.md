# Plan: Book 2 MSMTP - Fragment Setup

> **WARNING**: Reference `PHASE_2/RULES.md` at time of implementation. All commits must comply with microcommit rules (5-20 lines of code per commit).

**References:**
- Rules: `PHASE_2/RULES.md`
- Initial: `PHASE_2/BOOK_2_MSMTP/INITIAL.md`

---

## Overview

Create metadata and restructure config files for the MSMTP fragment. This fragment configures SMTP relay for system mail.

---

## Files to Create

### Commit 1: Create `book-2-cloud/msmtp/build.yaml`

```yaml
name: msmtp
description: SMTP relay configuration for system mail
iso_required: false
build_order: 45
build_layer: 5
```

Reason: Fragment metadata required for SDK discovery.

---

## Files to Rename

### Commit 2: Rename config file

**Rename:** `book-2-cloud/msmtp/config/smtp.config.yaml` → `book-2-cloud/msmtp/config/production.yaml`

Reason: Follow new naming convention.

---

### Commit 3: Rename config example file

**Rename:** `book-2-cloud/msmtp/config/smtp.config.yaml.example` → `book-2-cloud/msmtp/config/production.yaml.example`

Reason: Follow new naming convention.

---

## Files to Modify

### Commit 4: Update `.gitignore` for msmtp config

```diff
-book-2-cloud/msmtp/config/*.config.yaml
-!book-2-cloud/msmtp/config/*.config.yaml.example
+book-2-cloud/msmtp/config/production.yaml
```

Reason: Gitignore the specific production file containing SMTP credentials.

---

## Template Review

No template changes required - config keys (`smtp.*`) remain the same, only filenames change.

---

## Dependencies

This plan depends on:
- BOOK_0 plan (SDK must discover fragments via `build.yaml`)
- BOOK_2_NETWORK plan (network must be configured for SMTP)

---

## Validation

After all commits:

**Host (file checks):**
- [ ] `build.yaml` exists and is valid YAML
- [ ] `production.yaml` exists (renamed from `smtp.config.yaml`)
- [ ] `production.yaml` is gitignored (contains SMTP credentials)

**Builder VM** (via `$SDK.Builder.Stage()` then `$SDK.Builder.Exec()`):
- [ ] `python -m builder render cloud-init --include msmtp -o /dev/null` succeeds
- [ ] `make cloud-init INCLUDE=msmtp` succeeds
