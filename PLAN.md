# Plan


### Commit 1: `book-2-cloud/virtualization/docs/FRAGMENT.md` - Fix stale old-repo template path and sync template section with actual fragment.yaml.tpl content

### book-2-cloud.virtualization.docs.FRAGMENT.fix-stale-path-and-template

> **File**: `book-2-cloud/virtualization/docs/FRAGMENT.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Fix stale old-repo template path and sync template section with actual fragment.yaml.tpl content

#### Diff

```diff
-# 6.10 Virtualization Fragment
-
-**Template:** `src/autoinstall/cloud-init/60-virtualization.yaml.tpl`
+# Virtualization Fragment
+
+**Template:** `book-2-cloud/virtualization/fragment.yaml.tpl`
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 6 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 2: `book-2-cloud/virtualization/tests/TEST_VIRTUALIZATION.md` - Fix stale template path and fragment docs link in test documentation

### book-2-cloud.virtualization.tests.TEST_VIRTUALIZATION.fix-stale-test-doc-refs

> **File**: `book-2-cloud/virtualization/tests/TEST_VIRTUALIZATION.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Fix stale template path and fragment docs link in test documentation

#### Diff

```diff
-**Template:** `src/autoinstall/cloud-init/60-virtualization.yaml.tpl`
-**Fragment Docs:** [6.10 Virtualization Fragment](../../CLOUD_INIT_CONFIGURATION/VIRTUALIZATION_FRAGMENT.md)
+**Template:** `book-2-cloud/virtualization/fragment.yaml.tpl`
+**Fragment Docs:** [Virtualization Fragment](../../docs/FRAGMENT.md)
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 4 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |
