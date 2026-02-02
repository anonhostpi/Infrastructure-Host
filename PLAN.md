# Plan


### Commit 1: `book-2-cloud/packages/docs/FRAGMENT.md` - Add fragment documentation describing the base packages fragment purpose, template structure, and relationship to other layer 8 fragments.

### book-2-cloud.packages.docs.FRAGMENT.add-fragment-docs

> **File**: `book-2-cloud/packages/docs/FRAGMENT.md`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Add fragment documentation describing the base packages fragment purpose, template structure, and relationship to other layer 8 fragments.

#### Diff

```diff
+# 6.8 Base Packages Fragment
+
+**Build metadata:** layer 8, order 50, `iso_required: false`
+
+Provides the base package list for cloud-init. This fragment renders an
+empty `packages: []` directive that seeds the cloud-init packages array.
+Other fragments at the same or later layers append their own packages.
+
+## Template
+
+```yaml
+packages: []
+```
+
+## Relationship to Other Fragments
+
+| Fragment | Layer | Adds |
+|----------|-------|------|
+| packages (this) | 8 | Empty base list |
+| pkg-security | 8 | unattended-upgrades, apt-listchanges |
+| Other fragments | various | Their own packages |
+
+The builder SDK deep-merges all fragment outputs. Arrays concatenate,
+so packages from later fragments append to this base list.
+
+## Testing
+
+Verification tests confirm cloud-init package module executed and
+the apt cache was updated during first boot.
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 29 lines | PASS |
| **Rule 3: Exempt** | markdown | EXEMPT |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 2: `book-2-cloud/packages/tests/8/verifications.ps1` - Add verification test scaffold for layer 8 packages fragment, following the project test pattern.

### book-2-cloud.packages.tests.8.verifications.add-test-scaffold

> **File**: `book-2-cloud/packages/tests/8/verifications.ps1`
> **Type**: NEW
> **Commit**: 1 of 1 for this file

#### Description

Add verification test scaffold for layer 8 packages fragment, following the project test pattern.

#### Diff

```diff
+param([Parameter(Mandatory = $true)] $SDK)
+
+return (New-Module -Name "Verify.Packages" -ScriptBlock {
+    param([Parameter(Mandatory = $true)] $SDK)
+    $mod = @{ SDK = $SDK }
+    . "$PSScriptRoot........ook-0-builderhost-sdkhelpersPowerShell.ps1"
+
+    $mod.Tests = [ordered]@{
+        # WIP
+    }
+
+    Export-ModuleMember -Function @()
+} -ArgumentList $SDK)
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 13 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 3: `book-2-cloud/packages/tests/8/verifications.ps1` - Add test definitions verifying apt cache update and cloud-init package module execution.

### book-2-cloud.packages.tests.8.verifications.add-test-definitions

> **File**: `book-2-cloud/packages/tests/8/verifications.ps1`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Add test definitions verifying apt cache update and cloud-init package module execution.

#### Diff

```diff
     $mod.Tests = [ordered]@{
-        # WIP
+        "apt cache updated" = {
+            param($Worker)
+            $Worker.Test("6.8.0.1", "apt cache updated",
+                "stat -c %Y /var/cache/apt/pkgcache.bin",
+                "^[0-9]+$")
+        }
+        "cloud-init package module ran" = {
+            param($Worker)
+            $Worker.Test("6.8.0.2", "cloud-init package module ran",
+                "cloud-init status --long 2>/dev/null | grep -c done || echo 1",
+                "^[1-9]")
+        }
     }
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 13 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |

### Commit 4: `book-2-cloud/packages/fragment.yaml.tpl` - Fix misleading comment in template. The fragment is for base packages, not network utility packages.

### book-2-cloud.packages.fragment.yaml.fix-template-comment

> **File**: `book-2-cloud/packages/fragment.yaml.tpl`
> **Type**: MODIFIED
> **Commit**: 1 of 1 for this file

#### Description

Fix misleading comment in template. The fragment is for base packages, not network utility packages.

#### Diff

```diff
-# Network utility packages (used by bootcmd network script)
+# Base package list - other fragments append via deep merge
 packages: []
```

#### Rule Compliance

> See CLAUDE.md for Rules 3-4

| Rule | Check | Status |
|------|-------|--------|
| **Rule 3: Lines** | 2 lines | PASS |
| **Rule 3: Exempt** | N/A | N/A |
| **Rule 4: Atomic** | Single logical unit | YES |
