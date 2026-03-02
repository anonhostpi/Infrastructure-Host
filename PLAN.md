# Plan


### Commit 1: `book-2-cloud/claude-code/docs/FRAGMENT.md` - Update three stale path references from old src/ layout: template path, full template ref, and config path [COMPLETE]

### book-2-cloud.claude-code.docs.FRAGMENT.fix-stale-paths

> **File**: `book-2-cloud/claude-code/docs/FRAGMENT.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update three stale path references from old src/ layout: template path, full template ref, and config path

#### Diff

```diff
-**Template:** `src/autoinstall/cloud-init/75-claude-code.yaml.tpl`
+**Template:** `book-2-cloud/claude-code/fragment.yaml.tpl`

-See the full template at `src/autoinstall/cloud-init/75-claude-code.yaml.tpl`.
+See the full template at `book-2-cloud/claude-code/fragment.yaml.tpl`.

-Create `src/config/claude_code.config.yaml`:
+Create `config/claude_code.config.yaml`:
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 6 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 2: `book-2-cloud/claude-code/tests/TEST_CLAUDE_CODE.md` - Update stale template path and broken fragment docs link in test documentation [COMPLETE]

### book-2-cloud.claude-code.tests.TEST_CLAUDE_CODE.fix-test-stale-paths

> **File**: `book-2-cloud/claude-code/tests/TEST_CLAUDE_CODE.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Update stale template path and broken fragment docs link in test documentation

#### Diff

```diff
-**Template:** `src/autoinstall/cloud-init/75-claude-code.yaml.tpl`
+**Template:** `book-2-cloud/claude-code/fragment.yaml.tpl`
-**Fragment Docs:** [6.12 Claude Code Fragment](../../CLOUD_INIT_CONFIGURATION/CLAUDE_CODE_FRAGMENT.md)
+**Fragment Docs:** [6.12 Claude Code Fragment](../docs/FRAGMENT.md)
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 4 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |
