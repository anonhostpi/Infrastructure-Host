# Plan


### Commit 1: `book-2-cloud/pkg-security/docs/FRAGMENT.md` - Fix stale template path reference from old src/autoinstall location to current fragment location

### book-2-cloud.pkg-security.docs.FRAGMENT.fix-template-path

> **File**: `book-2-cloud/pkg-security/docs/FRAGMENT.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Fix stale template path reference from old src/autoinstall location to current fragment location

#### Diff

```diff
-**Template:** `src/autoinstall/cloud-init/50-pkg-security.yaml.tpl`
+**Template:** `book-2-cloud/pkg-security/fragment.yaml.tpl`
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 2: `book-2-cloud/pkg-security/tests/TEST_PKG_SECURITY.md` - Fix stale template path and fragment docs link in test documentation

### book-2-cloud.pkg-security.tests.TEST_PKG_SECURITY.fix-test-template-path

> **File**: `book-2-cloud/pkg-security/tests/TEST_PKG_SECURITY.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Fix stale template path and fragment docs link in test documentation

#### Diff

```diff
-**Template:** `src/autoinstall/cloud-init/50-pkg-security.yaml.tpl`
-**Fragment Docs:** [6.8 Package Security Fragment](../../CLOUD_INIT_CONFIGURATION/PACKAGE_SECURITY_FRAGMENT.md)
+**Template:** `book-2-cloud/pkg-security/fragment.yaml.tpl`
+**Fragment Docs:** [6.8 Package Security Fragment](../../docs/FRAGMENT.md)
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 4 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |
