# Plan


### Commit 1: `book-2-cloud/msmtp/docs/FRAGMENT.md` - Update stale template path and config path from old src/ layout to current fragment paths [COMPLETE]

### book-2-cloud.msmtp.docs.FRAGMENT.fix-stale-paths

> **File**: `book-2-cloud/msmtp/docs/FRAGMENT.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update stale template path and config path from old src/ layout to current fragment paths

#### Diff

```diff
-**Template:** `src/autoinstall/cloud-init/45-msmtp.yaml.tpl`
+**Template:** `book-2-cloud/msmtp/fragment.yaml.tpl`
...
-Create `src/config/smtp.config.yaml`:
+Create `book-2-cloud/msmtp/config/smtp.config.yaml`:
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 4 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 2: `book-2-cloud/msmtp/tests/TEST_MSMTP.md` - Update stale template path and broken cross-link to FRAGMENT.md [COMPLETE]

### book-2-cloud.msmtp.tests.TEST_MSMTP.fix-test-doc-paths

> **File**: `book-2-cloud/msmtp/tests/TEST_MSMTP.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update stale template path and broken cross-link to FRAGMENT.md

#### Diff

```diff
-**Template:** `src/autoinstall/cloud-init/45-msmtp.yaml.tpl`
-**Fragment Docs:** [6.7 MSMTP Fragment](../../CLOUD_INIT_CONFIGURATION/MSMTP_FRAGMENT.md)
+**Template:** `book-2-cloud/msmtp/fragment.yaml.tpl`
+**Fragment Docs:** [6.7 MSMTP Fragment](../docs/FRAGMENT.md)
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 4 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |
