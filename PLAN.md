# Plan


### Commit 1: `book-2-cloud/ufw/docs/FRAGMENT.md` - Fix stale template path reference from old directory structure to current fragment location

### book-2-cloud.ufw.docs.FRAGMENT.fix-template-path

> **File**: `book-2-cloud/ufw/docs/FRAGMENT.md`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Fix stale template path reference from old directory structure to current fragment location

#### Diff

```diff
 # 6.5 UFW Fragment
 
-**Template:** `src/autoinstall/cloud-init/30-ufw.yaml.tpl`
+**Template:** `book-2-cloud/ufw/fragment.yaml.tpl`
 
 Configures base firewall policy. Other fragments add their own rules.
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |
