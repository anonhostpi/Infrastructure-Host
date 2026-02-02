# Plan


### Commit 1: `book-2-cloud/cockpit/docs/FRAGMENT.md` - Update three stale src/ paths to current fragment-relative paths

### book-2-cloud.cockpit.docs.FRAGMENT.fix-stale-paths

> **File**: `book-2-cloud/cockpit/docs/FRAGMENT.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update three stale src/ paths to current fragment-relative paths

#### Diff

```diff
-**Template:** `src/autoinstall/cloud-init/70-cockpit.yaml.tpl`
+**Template:** `book-2-cloud/cockpit/fragment.yaml.tpl`
...
-Create `src/config/cockpit.config.yaml`:
+Create `config/cockpit.config.yaml` (copy from `cockpit.config.yaml.example`):
...
-Login with the admin credentials from `src/config/identity.config.yaml`.
+Login with the admin credentials from `identity.config.yaml` (in the users fragment).
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 6 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 2: `book-2-cloud/cockpit/tests/TEST_COCKPIT.md` - Update stale template path and broken cross-link to FRAGMENT.md

### book-2-cloud.cockpit.tests.TEST_COCKPIT.fix-test-doc-paths

> **File**: `book-2-cloud/cockpit/tests/TEST_COCKPIT.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update stale template path and broken cross-link to FRAGMENT.md

#### Diff

```diff
-**Template:** `src/autoinstall/cloud-init/70-cockpit.yaml.tpl`
-**Fragment Docs:** [6.11 Cockpit Fragment](../../CLOUD_INIT_CONFIGURATION/COCKPIT_FRAGMENT.md)
+**Template:** `book-2-cloud/cockpit/fragment.yaml.tpl`
+**Fragment Docs:** [6.11 Cockpit Fragment](../docs/FRAGMENT.md)
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 4 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |
