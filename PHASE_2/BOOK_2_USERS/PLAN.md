# Plan: Book 2 Users - Fragment Setup

> **WARNING**: Reference `PHASE_2/RULES.md` at time of implementation. All commits must comply with microcommit rules (5-20 lines of code per commit).

**References:**
- Rules: `PHASE_2/RULES.md`
- Initial: `PHASE_2/BOOK_2_USERS/INITIAL.md`

---

## Overview

Create metadata and restructure config files for the users fragment. This is an `iso_required` fragment for user account creation.

---

## Files to Create

### Commit 1: Create `book-2-cloud/users/build.yaml`

```yaml
name: users
description: User account creation and sudo configuration
iso_required: true
build_order: 20
build_layer: 3
```

Reason: Fragment metadata required for SDK discovery. `iso_required: true` because bare metal needs a login user.

---

## Files to Rename

### Commit 2: Rename config file

**Rename:** `book-2-cloud/users/config/identity.config.yaml` → `book-2-cloud/users/config/production.yaml`

Reason: Follow new naming convention.

---

### Commit 3: Rename config example file

**Rename:** `book-2-cloud/users/config/identity.config.yaml.example` → `book-2-cloud/users/config/production.yaml.example`

Reason: Follow new naming convention.

---

## Files to Modify

### Commit 4: Update `.gitignore` for users config

```diff
-book-2-cloud/users/config/*.config.yaml
-!book-2-cloud/users/config/*.config.yaml.example
+book-2-cloud/users/config/production.yaml
```

Reason: Gitignore the specific production file containing sensitive user credentials.

---

## Template Review

No template changes required - config keys (`identity.*`) remain the same, only filenames change.

---

## Dependencies

This plan depends on:
- BOOK_0 plan (SDK must discover fragments via `build.yaml`)
- BOOK_2_NETWORK plan (network configured first)

This plan blocks:
- BOOK_2_SSH plan (SSH may reference user authorized_keys)

---

## Validation

After all commits:

**Host (file checks):**
- [ ] `build.yaml` exists and is valid YAML
- [ ] `production.yaml` exists (renamed from `identity.config.yaml`)
- [ ] `production.yaml` is gitignored (contains passwords/keys)

**Builder VM** (via `$SDK.Builder.Stage()` then `$SDK.Builder.Exec()`):
- [ ] `python -m builder render cloud-init --include users -o /dev/null` succeeds
- [ ] `make cloud-init INCLUDE=users` succeeds
