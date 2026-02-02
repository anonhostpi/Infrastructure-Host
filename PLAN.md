# Plan


### Commit 1: `book-2-cloud/system/docs/FRAGMENT.md` - Fix stale path references in FRAGMENT.md: update template path from old src/autoinstall layout to current book-2-cloud/system/fragment.yaml.tpl, and remove broken BuildContext link

### book-2-cloud.system.docs.FRAGMENT.fix-fragment-doc-paths

> **File**: `book-2-cloud/system/docs/FRAGMENT.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Fix stale path references in FRAGMENT.md: update template path from old src/autoinstall layout to current book-2-cloud/system/fragment.yaml.tpl, and remove broken BuildContext link

#### Diff

```diff
-**Template:** `src/autoinstall/cloud-init/40-system.yaml.tpl`
+**Template:** `book-2-cloud/system/fragment.yaml.tpl`
...
-See [3.1 BuildContext](../BUILD_SYSTEM/BUILD_CONTEXT.md) for environment variable overrides.
+See ARCHITECTURE.md for environment variable override details (`AUTOINSTALL_` prefix).
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 4 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 2: `book-2-cloud/system/tests/TEST_SYSTEM.md` - Fix stale path references in TEST_SYSTEM.md: update template path and fix broken fragment docs link to point to ../docs/FRAGMENT.md

### book-2-cloud.system.tests.TEST_SYSTEM.fix-test-doc-paths

> **File**: `book-2-cloud/system/tests/TEST_SYSTEM.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Fix stale path references in TEST_SYSTEM.md: update template path and fix broken fragment docs link to point to ../docs/FRAGMENT.md

#### Diff

```diff
-**Template:** `src/autoinstall/cloud-init/40-system.yaml.tpl`
-**Fragment Docs:** [6.6 System Settings Fragment](../../CLOUD_INIT_CONFIGURATION/SYSTEM_SETTINGS_FRAGMENT.md)
+**Template:** `book-2-cloud/system/fragment.yaml.tpl`
+**Fragment Docs:** [6.6 System Settings Fragment](../docs/FRAGMENT.md)
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 4 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |
