# Plan


### Commit 1: `book-2-cloud/copilot-cli/docs/FRAGMENT.md` - Update stale template path reference from src/autoinstall/cloud-init/ to fragment-relative path

### book-2-cloud.copilot-cli.docs.FRAGMENT.fix-template-path

> **File**: `book-2-cloud/copilot-cli/docs/FRAGMENT.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update stale template path reference from src/autoinstall/cloud-init/ to fragment-relative path

#### Diff

```diff
-**Template:** `src/autoinstall/cloud-init/76-copilot-cli.yaml.tpl`
+**Template:** `book-2-cloud/copilot-cli/fragment.yaml.tpl`
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 2: `book-2-cloud/copilot-cli/docs/FRAGMENT.md` - Update second stale template path in template section

### book-2-cloud.copilot-cli.docs.FRAGMENT.fix-see-full-template

> **File**: `book-2-cloud/copilot-cli/docs/FRAGMENT.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update second stale template path in template section

#### Diff

```diff
-See the full template at `src/autoinstall/cloud-init/76-copilot-cli.yaml.tpl`.
+See the full template at `book-2-cloud/copilot-cli/fragment.yaml.tpl`.
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 3: `book-2-cloud/copilot-cli/docs/FRAGMENT.md` - Update stale config path reference from src/config/ to fragment-relative path

### book-2-cloud.copilot-cli.docs.FRAGMENT.fix-config-path

> **File**: `book-2-cloud/copilot-cli/docs/FRAGMENT.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update stale config path reference from src/config/ to fragment-relative path

#### Diff

```diff
-Create `src/config/copilot_cli.config.yaml`:
+Create `book-2-cloud/copilot-cli/config/copilot_cli.config.yaml`:
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 4: `book-2-cloud/copilot-cli/tests/TEST_COPILOT_CLI.md` - Update stale template path reference in test documentation

### book-2-cloud.copilot-cli.tests.TEST_COPILOT_CLI.fix-test-template-path

> **File**: `book-2-cloud/copilot-cli/tests/TEST_COPILOT_CLI.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update stale template path reference in test documentation

#### Diff

```diff
-**Template:** `src/autoinstall/cloud-init/76-copilot-cli.yaml.tpl`
+**Template:** `book-2-cloud/copilot-cli/fragment.yaml.tpl`
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 5: `book-2-cloud/copilot-cli/tests/TEST_COPILOT_CLI.md` - Fix broken fragment docs link from old CLOUD_INIT_CONFIGURATION path to current docs location

### book-2-cloud.copilot-cli.tests.TEST_COPILOT_CLI.fix-fragment-docs-link

> **File**: `book-2-cloud/copilot-cli/tests/TEST_COPILOT_CLI.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Fix broken fragment docs link from old CLOUD_INIT_CONFIGURATION path to current docs location

#### Diff

```diff
-**Fragment Docs:** [6.13 Copilot CLI Fragment](../../CLOUD_INIT_CONFIGURATION/COPILOT_CLI_FRAGMENT.md)
+**Fragment Docs:** [6.13 Copilot CLI Fragment](../docs/FRAGMENT.md)
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |
